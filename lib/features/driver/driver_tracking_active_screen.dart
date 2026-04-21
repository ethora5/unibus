import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../app/app_routes.dart';
import '../../app/app_theme.dart';
import '../../core/services/driver_active_session_service.dart';
import '../../core/services/notification_event_service.dart';

class DriverTrackingActiveScreen extends StatefulWidget {
  const DriverTrackingActiveScreen({super.key});

  @override
  State<DriverTrackingActiveScreen> createState() =>
      _DriverTrackingActiveScreenState();
}

class _DriverTrackingActiveScreenState
    extends State<DriverTrackingActiveScreen> {
  Timer? timer;
  Timer? _gpsTimer;

  int seconds = 0;
  int startSeconds = 0;

  String driverName = 'Driver';
  String busId = 'Bus';
  String routeName = 'Route';
  String? routeId;
  String? busDocId;

  bool _argsLoaded = false;
  bool _sessionStarted = false;
  bool _resumeSession = false;

  String? sessionDocId;

  bool isStartingSession = true;
  bool isStoppingSession = false;

  String? sessionError;
  Position? currentPosition;
  bool gpsReady = false;

  List<LatLng> _routePoints = [];
  List<double> _cumulativeRouteMeters = [];

  LatLng? _lastAcceptedPoint;
  double? _lastAcceptedProgressMeters;

  bool _isProcessingLocation = false;

  static const double _maxAccuracyMeters = 80.0;
  static const double _snapThresholdMeters = 35.0;
  static const double _maxBackwardJumpMeters = 12.0;
  static const double _minMeaningfulMovementMeters = 0.5;

  static const double _forwardSearchWindowMeters = 180.0;
  static const double _backwardSearchWindowMeters = 25.0;

  static const Duration _gpsUpdateInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      if (_sessionStarted && !isStoppingSession) {
        final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        setState(() {
          seconds = nowSeconds - startSeconds;
          if (seconds < 0) seconds = 0;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_argsLoaded) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      driverName = (args['driverName'] as String?)?.trim().isNotEmpty == true
          ? (args['driverName'] as String).trim()
          : 'Driver';

      busId = (args['busId'] as String?)?.trim().isNotEmpty == true
          ? (args['busId'] as String).trim()
          : 'Bus';

      routeName = (args['routeName'] as String?)?.trim().isNotEmpty == true
          ? (args['routeName'] as String).trim()
          : 'Route';

      routeId = (args['routeId'] as String?)?.trim();

      busDocId = args['busDocId'] as String?;
      sessionDocId = args['sessionDocId'] as String?;
      _resumeSession = (args['resumeSession'] as bool?) ?? false;
      startSeconds =
          (args['startSeconds'] as int?) ??
          (DateTime.now().millisecondsSinceEpoch ~/ 1000);
    }

    _argsLoaded = true;

    if (_resumeSession && sessionDocId != null) {
      _resumeExistingSession();
    } else {
      _startTrackingSession();
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _stopGpsUpdates();
    super.dispose();
  }

  String get elapsed {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;

    final String hh = hours.toString().padLeft(2, '0');
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = secs.toString().padLeft(2, '0');

    return '$hh:$mm:$ss';
  }

  Future<void> _resumeExistingSession() async {
    try {
      if (sessionDocId == null || sessionDocId!.trim().isEmpty) {
        throw Exception('Session ID is missing.');
      }

      final doc = await FirebaseFirestore.instance
          .collection('driving_sessions')
          .doc(sessionDocId)
          .get();

      if (!doc.exists) {
        throw Exception('Session not found.');
      }

      final data = doc.data()!;
      final status = (data['status'] as String?)?.trim().toLowerCase() ?? '';

      if (status != 'active') {
        throw Exception('This session is no longer active.');
      }

      final dynamic savedProgress = data['routeProgressMeters'];
      if (savedProgress is num) {
        _lastAcceptedProgressMeters = savedProgress.toDouble();
      }

      final dynamic lat = data['currentLatitude'];
      final dynamic lng = data['currentLongitude'];
      if (lat is num && lng is num) {
        _lastAcceptedPoint = LatLng(lat.toDouble(), lng.toDouble());
      }

      setState(() {
        _sessionStarted = true;
        isStartingSession = false;
        sessionError = null;
      });

      await _startGpsUpdates();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isStartingSession = false;
        sessionError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<bool> _checkAndRequestLocationPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        sessionError = 'Location service is disabled.';
      });
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        sessionError = 'Location permission was denied.';
      });
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        sessionError =
            'Location permission is permanently denied. Please enable it from settings.';
      });
      return false;
    }

    return true;
  }

  Future<void> _loadRoutePoints() async {
    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
        'route_points',
      );

      // إذا عندك routeId بنجرب نفلتر
      if (routeId != null && routeId!.isNotEmpty) {
        final filtered = await query
            .where('routeId', isEqualTo: routeId)
            .orderBy('order')
            .get();

        if (filtered.docs.isNotEmpty) {
          _routePoints = filtered.docs
              .map((doc) {
                final data = doc.data();
                final latRaw = data['latitude'];
                final lngRaw = data['longitude'];

                if (latRaw is num && lngRaw is num) {
                  return LatLng(latRaw.toDouble(), lngRaw.toDouble());
                }
                return null;
              })
              .whereType<LatLng>()
              .toList();

          _rebuildRouteCumulativeDistances();
          return;
        }
      }

      // fallback: لو routeId مو موجود داخل route_points
      final snapshot = await FirebaseFirestore.instance
          .collection('route_points')
          .orderBy('order')
          .get();

      _routePoints = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final latRaw = data['latitude'];
            final lngRaw = data['longitude'];

            if (latRaw is num && lngRaw is num) {
              return LatLng(latRaw.toDouble(), lngRaw.toDouble());
            }
            return null;
          })
          .whereType<LatLng>()
          .toList();

      _rebuildRouteCumulativeDistances();
    } catch (_) {
      _routePoints = [];
      _cumulativeRouteMeters = [];
    }
  }

  void _rebuildRouteCumulativeDistances() {
    _cumulativeRouteMeters = [];

    if (_routePoints.isEmpty) return;

    double total = 0.0;
    _cumulativeRouteMeters.add(0.0);

    for (int i = 1; i < _routePoints.length; i++) {
      total += _distanceMeters(_routePoints[i - 1], _routePoints[i]);
      _cumulativeRouteMeters.add(total);
    }
  }

  Future<void> _startGpsUpdates() async {
    final bool allowed = await _checkAndRequestLocationPermission();
    if (!allowed) return;

    await _loadRoutePoints();
    await _stopGpsUpdates();

    try {
      // أول نقطة مباشرة من أول ما تبدأ الجلسة
      final Position firstPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );

      await _handlePosition(firstPosition);

      _gpsTimer = Timer.periodic(_gpsUpdateInterval, (_) async {
        if (_isProcessingLocation) return;

        try {
          final Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
            ),
          );

          await _handlePosition(position);
        } catch (_) {
          if (!mounted) return;
          setState(() {
            gpsReady = false;
            sessionError = 'Failed to update GPS location.';
          });
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        gpsReady = false;
        sessionError = 'Failed to get current location.';
      });
    }
  }

  Future<void> _handlePosition(Position position) async {
    if (_isProcessingLocation) return;

    _isProcessingLocation = true;
    try {
      final bool saved = await _updateLiveLocation(position);

      if (!mounted) return;

      if (saved) {
        setState(() {
          gpsReady = true;
          sessionError = null;
        });
      }
    } finally {
      _isProcessingLocation = false;
    }
  }

  Future<bool> _updateLiveLocation(Position rawPosition) async {
    if (busDocId == null || busDocId!.trim().isEmpty) return false;
    if (sessionDocId == null || sessionDocId!.trim().isEmpty) return false;

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final Timestamp now = Timestamp.now();

    final LatLng rawLatLng = LatLng(
      rawPosition.latitude,
      rawPosition.longitude,
    );

    double moveDistance = double.infinity;
    if (_lastAcceptedPoint != null) {
      moveDistance = _distanceMeters(_lastAcceptedPoint!, rawLatLng);
    }

    final bool veryPoorAccuracy = rawPosition.accuracy > _maxAccuracyMeters;
    final bool almostNoMovement = moveDistance < _minMeaningfulMovementMeters;
    final bool almostStopped = rawPosition.speed <= 0.2;

    if (veryPoorAccuracy && almostNoMovement && almostStopped) {
      return false;
    }

    final _SnapResult snapResult = _matchPointToRoute(rawLatLng);

    LatLng finalLatLng = rawLatLng;
    double finalProgressMeters = _lastAcceptedProgressMeters ?? 0.0;
    bool gpsCorrectionApplied = false;

    if (snapResult.found &&
        snapResult.deviationMeters <= _snapThresholdMeters &&
        snapResult.progressMeters >=
            ((_lastAcceptedProgressMeters ?? 0.0) - _maxBackwardJumpMeters)) {
      finalLatLng = snapResult.snappedPoint!;
      finalProgressMeters = snapResult.progressMeters;
      gpsCorrectionApplied = true;
    } else if (_lastAcceptedProgressMeters != null &&
        _routePoints.length >= 2) {
      finalProgressMeters = _lastAcceptedProgressMeters!;
    } else if (_routePoints.length >= 2) {
      finalProgressMeters = _fallbackNearestProgress(rawLatLng);
    }

    // لا نسمح للباص يرجع للخلف
    if (_lastAcceptedProgressMeters != null &&
        finalProgressMeters < _lastAcceptedProgressMeters!) {
      finalProgressMeters = _lastAcceptedProgressMeters!;
      if (_lastAcceptedPoint != null) {
        finalLatLng = _lastAcceptedPoint!;
      }
    }

    final Position correctedPosition = Position(
      longitude: finalLatLng.longitude,
      latitude: finalLatLng.latitude,
      timestamp: rawPosition.timestamp,
      accuracy: rawPosition.accuracy,
      altitude: rawPosition.altitude,
      altitudeAccuracy: rawPosition.altitudeAccuracy,
      heading: rawPosition.heading,
      headingAccuracy: rawPosition.headingAccuracy,
      speed: rawPosition.speed,
      speedAccuracy: rawPosition.speedAccuracy,
    );

    try {
      await firestore.collection('driving_sessions').doc(sessionDocId).update({
        'currentLatitude': correctedPosition.latitude,
        'currentLongitude': correctedPosition.longitude,
        'currentSpeed': correctedPosition.speed,
        'currentAccuracy': correctedPosition.accuracy,
        'lastLocationUpdatedAt': now,
        'rawLatitude': rawPosition.latitude,
        'rawLongitude': rawPosition.longitude,
        'snappedLatitude': correctedPosition.latitude,
        'snappedLongitude': correctedPosition.longitude,
        'distanceFromRouteMeters': snapResult.deviationMeters,
        'gpsCorrectionApplied': gpsCorrectionApplied,
        'routeProgressMeters': finalProgressMeters,
        'routeProgressFraction': _routeLengthMeters <= 0
            ? 0.0
            : (finalProgressMeters / _routeLengthMeters).clamp(0.0, 1.0),
      });

      await firestore.collection('buses').doc(busDocId).update({
        'currentLatitude': correctedPosition.latitude,
        'currentLongitude': correctedPosition.longitude,
        'currentSpeed': correctedPosition.speed,
        'currentAccuracy': correctedPosition.accuracy,
        'gpsUpdatedAt': now,
        'rawLatitude': rawPosition.latitude,
        'rawLongitude': rawPosition.longitude,
        'snappedLatitude': correctedPosition.latitude,
        'snappedLongitude': correctedPosition.longitude,
        'distanceFromRouteMeters': snapResult.deviationMeters,
        'gpsCorrectionApplied': gpsCorrectionApplied,
        'routeProgressMeters': finalProgressMeters,
        'routeProgressFraction': _routeLengthMeters <= 0
            ? 0.0
            : (finalProgressMeters / _routeLengthMeters).clamp(0.0, 1.0),
      });

      _lastAcceptedPoint = finalLatLng;
      _lastAcceptedProgressMeters = finalProgressMeters;

      if (!mounted) return true;

      setState(() {
        currentPosition = correctedPosition;
      });

      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        gpsReady = false;
        sessionError = 'Failed to update GPS location.';
      });
      return false;
    }
  }

  Future<void> _stopGpsUpdates() async {
    _gpsTimer?.cancel();
    _gpsTimer = null;
  }

  Future<void> _startTrackingSession() async {
    if (_sessionStarted) return;

    if (busDocId == null || busDocId!.trim().isEmpty) {
      setState(() {
        isStartingSession = false;
        sessionError = 'Bus document ID is missing.';
      });
      return;
    }

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final DocumentReference<Map<String, dynamic>> busRef = firestore
          .collection('buses')
          .doc(busDocId);

      final DocumentReference<Map<String, dynamic>> sessionRef = firestore
          .collection('driving_sessions')
          .doc();

      final Timestamp now = Timestamp.now();
      final currentUser = FirebaseAuth.instance.currentUser;
      final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      startSeconds = nowSeconds;

      await firestore.runTransaction((transaction) async {
        final busSnapshot = await transaction.get(busRef);

        if (!busSnapshot.exists) {
          throw Exception('Selected bus was not found.');
        }

        final busData = busSnapshot.data();
        final currentStatus =
            (busData?['status'] as String?)?.trim().toLowerCase() ?? '';

        if (currentStatus != 'available') {
          throw Exception('This bus is no longer available.');
        }

        transaction.set(sessionRef, {
          'driverName': driverName,
          'driverEmail': currentUser?.email,
          'busId': busId,
          'busDocId': busDocId,
          'routeName': routeName,
          'routeId': routeId,
          'startTime': now,
          'endTime': null,
          'durationSeconds': 0,
          'status': 'active',
          'createdAt': now,
          'routeProgressMeters': 0.0,
          'routeProgressFraction': 0.0,
        });

        transaction.update(busRef, {
          'status': 'in_use',
          'assignedDriverName': driverName,
          'currentSessionId': sessionRef.id,
          'updatedAt': now,
          'routeName': routeName,
          'routeId': routeId,
        });
      });

      await DriverActiveSessionService.saveActiveSession(
        sessionId: sessionRef.id,
        busDocId: busDocId!,
        busId: busId,
        routeName: routeName,
        driverName: driverName,
        driverEmail: currentUser?.email ?? '',
        startSeconds: startSeconds,
      );

      await NotificationEventService.createNewBusTrackingEvent(
        sessionId: sessionRef.id,
        busName: busId,
        routeName: routeName,
      );

      if (!mounted) return;

      setState(() {
        sessionDocId = sessionRef.id;
        _sessionStarted = true;
        isStartingSession = false;
        sessionError = null;
      });

      await _startGpsUpdates();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isStartingSession = false;
        sessionError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _stopTracking() async {
    if (isStoppingSession) return;

    if (busDocId == null || busDocId!.trim().isEmpty) {
      setState(() {
        sessionError = 'Bus document ID is missing.';
      });
      return;
    }

    if (sessionDocId == null || sessionDocId!.trim().isEmpty) {
      setState(() {
        sessionError = 'Session ID is missing.';
      });
      return;
    }

    setState(() {
      isStoppingSession = true;
      sessionError = null;
    });

    try {
      await _stopGpsUpdates();

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final DocumentReference<Map<String, dynamic>> busRef = firestore
          .collection('buses')
          .doc(busDocId);

      final DocumentReference<Map<String, dynamic>> sessionRef = firestore
          .collection('driving_sessions')
          .doc(sessionDocId);

      final Timestamp now = Timestamp.now();

      await firestore.runTransaction((transaction) async {
        final busSnapshot = await transaction.get(busRef);
        final sessionSnapshot = await transaction.get(sessionRef);

        if (!busSnapshot.exists) {
          throw Exception('Bus not found.');
        }

        if (!sessionSnapshot.exists) {
          throw Exception('Session not found.');
        }

        transaction.update(sessionRef, {
          'endTime': now,
          'durationSeconds': seconds,
          'status': 'completed',
          'updatedAt': now,
        });

        transaction.update(busRef, {
          'status': 'available',
          'assignedDriverName': null,
          'currentSessionId': null,
          'updatedAt': now,
        });
      });

      await DriverActiveSessionService.clearActiveSession();

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.trackingSessionEnd,
        arguments: {
          'driverName': driverName,
          'busId': busId,
          'busDocId': busDocId,
          'routeName': routeName,
          'routeId': routeId,
          'elapsedSeconds': seconds,
          'sessionDocId': sessionDocId,
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isStoppingSession = false;
        sessionError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double get _routeLengthMeters {
    if (_cumulativeRouteMeters.isEmpty) return 0.0;
    return _cumulativeRouteMeters.last;
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const Distance distance = Distance();
    return distance(a, b);
  }

  double _fallbackNearestProgress(LatLng point) {
    if (_routePoints.length < 2) return 0.0;

    double bestDistance = double.infinity;
    double bestProgress = 0.0;

    for (int i = 0; i < _routePoints.length - 1; i++) {
      final _ProjectedPoint projected = _projectPointOnSegmentWithT(
        point,
        _routePoints[i],
        _routePoints[i + 1],
      );

      final double d = _distanceMeters(point, projected.point);
      if (d < bestDistance) {
        bestDistance = d;

        final double segmentLength = _distanceMeters(
          _routePoints[i],
          _routePoints[i + 1],
        );

        bestProgress =
            _cumulativeRouteMeters[i] +
            (segmentLength * projected.t.clamp(0.0, 1.0));
      }
    }

    return bestProgress;
  }

  _SnapResult _matchPointToRoute(LatLng rawPoint) {
    if (_routePoints.length < 2) {
      return const _SnapResult.notFound();
    }

    int startSegment = 0;
    int endSegment = _routePoints.length - 2;

    if (_lastAcceptedProgressMeters != null) {
      final double minMeters =
          (_lastAcceptedProgressMeters! - _backwardSearchWindowMeters).clamp(
            0.0,
            _routeLengthMeters,
          );
      final double maxMeters =
          (_lastAcceptedProgressMeters! + _forwardSearchWindowMeters).clamp(
            0.0,
            _routeLengthMeters,
          );

      startSegment = _segmentIndexForProgress(minMeters);
      endSegment = _segmentIndexForProgress(maxMeters);

      if (startSegment > endSegment) {
        startSegment = 0;
        endSegment = _routePoints.length - 2;
      }
    }

    LatLng? bestPoint;
    double bestDistance = double.infinity;
    double bestProgress = 0.0;

    for (int i = startSegment; i <= endSegment; i++) {
      final LatLng a = _routePoints[i];
      final LatLng b = _routePoints[i + 1];

      final _ProjectedPoint projected = _projectPointOnSegmentWithT(
        rawPoint,
        a,
        b,
      );
      final double distance = _distanceMeters(rawPoint, projected.point);

      if (distance < bestDistance) {
        bestDistance = distance;
        bestPoint = projected.point;

        final double segmentLength = _distanceMeters(a, b);
        bestProgress =
            _cumulativeRouteMeters[i] +
            (segmentLength * projected.t.clamp(0.0, 1.0));
      }
    }

    if (bestPoint == null) {
      return const _SnapResult.notFound();
    }

    return _SnapResult(
      found: true,
      snappedPoint: bestPoint,
      deviationMeters: bestDistance,
      progressMeters: bestProgress,
    );
  }

  int _segmentIndexForProgress(double progressMeters) {
    if (_routePoints.length < 2) return 0;
    if (_cumulativeRouteMeters.isEmpty) return 0;

    for (int i = 0; i < _cumulativeRouteMeters.length - 1; i++) {
      final double start = _cumulativeRouteMeters[i];
      final double end = _cumulativeRouteMeters[i + 1];

      if (progressMeters >= start && progressMeters <= end) {
        return i;
      }
    }

    return _routePoints.length - 2;
  }

  _ProjectedPoint _projectPointOnSegmentWithT(LatLng p, LatLng a, LatLng b) {
    final _XY pxy = _toXY(p, p.latitude);
    final _XY axy = _toXY(a, p.latitude);
    final _XY bxy = _toXY(b, p.latitude);

    final double abx = bxy.x - axy.x;
    final double aby = bxy.y - axy.y;
    final double apx = pxy.x - axy.x;
    final double apy = pxy.y - axy.y;

    final double abSquared = (abx * abx) + (aby * aby);
    if (abSquared == 0) {
      return _ProjectedPoint(a, 0.0);
    }

    double t = ((apx * abx) + (apy * aby)) / abSquared;
    t = t.clamp(0.0, 1.0);

    final double projX = axy.x + (abx * t);
    final double projY = axy.y + (aby * t);

    return _ProjectedPoint(_fromXY(_XY(projX, projY), p.latitude), t);
  }

  _XY _toXY(LatLng point, double referenceLat) {
    const double metersPerDegreeLat = 111320.0;
    final double metersPerDegreeLng =
        111320.0 * math.cos(referenceLat * math.pi / 180.0);

    return _XY(
      point.longitude * metersPerDegreeLng,
      point.latitude * metersPerDegreeLat,
    );
  }

  LatLng _fromXY(_XY xy, double referenceLat) {
    const double metersPerDegreeLat = 111320.0;
    final double metersPerDegreeLng =
        111320.0 * math.cos(referenceLat * math.pi / 180.0);

    return LatLng(xy.y / metersPerDegreeLat, xy.x / metersPerDegreeLng);
  }

  @override
  Widget build(BuildContext context) {
    final bool showTrackingError = sessionError != null;
    final bool showTrackingActive = gpsReady && currentPosition != null;

    final Color statusBgColor = showTrackingError
        ? const Color(0xFFFFF1F1)
        : showTrackingActive
        ? const Color(0xFFEAF7EE)
        : const Color(0xFFF4F6F8);

    final Color statusBorderColor = showTrackingError
        ? const Color(0xFFFFD6D6)
        : showTrackingActive
        ? const Color(0xFFBFE6C9)
        : const Color(0xFFD9E1E7);

    final Color statusIconColor = showTrackingError
        ? const Color(0xFFE11D48)
        : showTrackingActive
        ? const Color(0xFF1F9D55)
        : Colors.grey;

    final String statusTitle = showTrackingError
        ? 'Tracking Problem'
        : showTrackingActive
        ? 'Tracking Activated'
        : 'Starting Tracking';

    final String statusSubtitle = showTrackingError
        ? sessionError!
        : showTrackingActive
        ? 'GPS is actively tracking your\nlocation'
        : 'Waiting for first GPS coordinate...';

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Tracking Active'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusBorderColor),
                ),
                child: Column(
                  children: [
                    Icon(
                      showTrackingError
                          ? Icons.error_outline
                          : Icons.wifi_tethering,
                      color: statusIconColor,
                      size: 34,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (sessionError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD6D6)),
                  ),
                  child: Text(
                    sessionError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Details',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _KeyValueRow(left: 'Driver Name', right: driverName),
                    _KeyValueRow(left: 'Bus Number', right: busId),
                    _KeyValueRow(left: 'Route', right: routeName),
                    _KeyValueRow(
                      left: 'Tracking Status',
                      right: gpsReady ? 'GPS Active' : 'Starting...',
                      rightGreenDot: gpsReady,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  children: [
                    const Text(
                      'Elapsed Time',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      elapsed,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Row(
                  children: [
                    const Icon(
                      Icons.gps_fixed,
                      color: Colors.black54,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'GPS Updates',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      gpsReady ? 'Every 2 sec' : 'Starting',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live GPS Coordinates',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentPosition == null
                          ? 'Waiting for location...'
                          : 'Latitude: ${currentPosition!.latitude}\nLongitude: ${currentPosition!.longitude}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: (isStartingSession || isStoppingSession)
                      ? null
                      : _stopTracking,
                  icon: isStoppingSession
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.stop_circle_outlined),
                  label: Text(
                    isStoppingSession ? 'Stopping...' : 'Stop Tracking',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE3E7EF),
                    disabledForegroundColor: Colors.black38,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _XY {
  final double x;
  final double y;

  const _XY(this.x, this.y);
}

class _ProjectedPoint {
  final LatLng point;
  final double t;

  const _ProjectedPoint(this.point, this.t);
}

class _SnapResult {
  final bool found;
  final LatLng? snappedPoint;
  final double deviationMeters;
  final double progressMeters;

  const _SnapResult({
    required this.found,
    required this.snappedPoint,
    required this.deviationMeters,
    required this.progressMeters,
  });

  const _SnapResult.notFound()
    : found = false,
      snappedPoint = null,
      deviationMeters = double.infinity,
      progressMeters = 0.0;
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 5),
            color: Color(0x0F000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String left;
  final String right;
  final bool rightGreenDot;

  const _KeyValueRow({
    required this.left,
    required this.right,
    this.rightGreenDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              left,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          if (rightGreenDot) ...[
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF1F9D55),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
