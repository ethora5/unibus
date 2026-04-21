import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/app_routes.dart';
import '../../app/app_theme.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  static final LatLng unitenCenter = LatLng(2.9766, 101.7331);

  bool _bannerDismissed = false;
  bool _loadingSession = true;
  bool _loadingStops = true;
  bool _loadingRoutePoints = true;
  String? _sessionError;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _stopsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _routePointsSub;

  Timer? _movementTimer;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _stopsDocs = [];
  List<LatLng> _routePoints = [];
  List<double> _routeCumulativeMeters = [];
  List<_StopProgress> _orderedStopProgress = [];

  bool _hasActiveSession = false;
  String _busName = '__';
  String _routeName = '__';
  String? _routeId;
  double _currentSpeed = 0.0;
  double _routeProgressMeters = 0.0;

  LatLng? _latestServerPosition;
  LatLng? _displayedBusPosition;

  Stream<QuerySnapshot<Map<String, dynamic>>> _activeSessionStream() {
    return FirebaseFirestore.instance
        .collection('driving_sessions')
        .where('status', isEqualTo: 'active')
        .orderBy('startTime', descending: true)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _stopsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'stops',
    );

    if (_routeId != null && _routeId!.isNotEmpty) {
      query = query.where('routeId', isEqualTo: _routeId);
    }

    return query.orderBy('order').snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _routePointsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'route_points',
    );

    return query.orderBy('order').snapshots();
  }

  @override
  void initState() {
    super.initState();
    _listenToActiveSession();
    _listenToStops();
    _listenToRoutePoints();
  }

  @override
  void dispose() {
    _sessionSub?.cancel();
    _stopsSub?.cancel();
    _routePointsSub?.cancel();
    _movementTimer?.cancel();
    super.dispose();
  }

  void _restartStopsListener() {
    _stopsSub?.cancel();
    _listenToStops();
  }

  void _restartRoutePointsListener() {
    _routePointsSub?.cancel();
    _listenToRoutePoints();
  }

  void _listenToStops() {
    _stopsSub = _stopsStream().listen(
      (snapshot) {
        if (!mounted) return;
        setState(() {
          _stopsDocs = snapshot.docs;
          _loadingStops = false;
          _rebuildStopProgress();
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _loadingStops = false;
        });
      },
    );
  }

  void _listenToRoutePoints() {
    _routePointsSub = _routePointsStream().listen(
      (snapshot) {
        if (!mounted) return;

        List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = snapshot.docs;

        if (_routeId != null && _routeId!.isNotEmpty) {
          final filtered = docs.where((doc) {
            final data = doc.data();
            return data['routeId'] == _routeId;
          }).toList();

          if (filtered.isNotEmpty) {
            docs = filtered;
          }
        }

        final List<LatLng> points = docs
            .map((doc) {
              final data = doc.data();
              final lat = data['latitude'];
              final lng = data['longitude'];

              if (lat is num && lng is num) {
                return LatLng(lat.toDouble(), lng.toDouble());
              }
              return null;
            })
            .whereType<LatLng>()
            .toList();

        setState(() {
          _routePoints = points;
          _loadingRoutePoints = false;
          _rebuildRouteCumulativeDistances();
          _rebuildStopProgress();
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _loadingRoutePoints = false;
        });
      },
    );
  }

  void _listenToActiveSession() {
    _sessionSub = _activeSessionStream().listen(
      (snapshot) {
        if (!mounted) return;

        if (snapshot.docs.isEmpty) {
          _movementTimer?.cancel();

          setState(() {
            _loadingSession = false;
            _hasActiveSession = false;
            _latestServerPosition = null;
            _displayedBusPosition = null;
            _currentSpeed = 0.0;
            _routeProgressMeters = 0.0;
            _busName = '__';
            _routeName = '__';
            _routeId = null;
          });
          return;
        }

        final sessionData = snapshot.docs.first.data();

        final dynamic latRaw = sessionData['currentLatitude'];
        final dynamic lngRaw = sessionData['currentLongitude'];
        final dynamic speedRaw = sessionData['currentSpeed'];
        final dynamic progressRaw = sessionData['routeProgressMeters'];

        final String status =
            (sessionData['status'] as String?)?.trim().toLowerCase() ?? '';

        final bool hasValidLocation = latRaw is num && lngRaw is num;
        final bool isActive = status == 'active';

        final String busName =
            ((sessionData['busId'] as String?)?.trim().isNotEmpty == true)
            ? (sessionData['busId'] as String).trim()
            : '__';

        final String routeName =
            ((sessionData['routeName'] as String?)?.trim().isNotEmpty == true)
            ? (sessionData['routeName'] as String).trim()
            : '__';

        final String? newRouteId = (sessionData['routeId'] as String?)?.trim();

        double speed = 0.0;
        if (speedRaw is num) {
          speed = speedRaw.toDouble();
        }

        double progressMeters = 0.0;
        if (progressRaw is num) {
          progressMeters = progressRaw.toDouble();
        }

        if (!isActive || !hasValidLocation) {
          _movementTimer?.cancel();

          setState(() {
            _loadingSession = false;
            _hasActiveSession = false;
            _latestServerPosition = null;
            _displayedBusPosition = null;
            _currentSpeed = 0.0;
            _routeProgressMeters = 0.0;
            _busName = busName;
            _routeName = routeName;
          });
          return;
        }

        final LatLng newServerPosition = LatLng(
          latRaw.toDouble(),
          lngRaw.toDouble(),
        );

        final bool routeChanged = newRouteId != _routeId;

        if (routeChanged) {
          _routeId = newRouteId;
          _loadingStops = true;
          _loadingRoutePoints = true;
          _restartStopsListener();
          _restartRoutePointsListener();
        }

        final bool firstPoint = _displayedBusPosition == null;

        setState(() {
          _loadingSession = false;
          _hasActiveSession = true;
          _busName = busName;
          _routeName = routeName;
          _currentSpeed = speed;
          _routeProgressMeters = progressMeters;
        });

        if (firstPoint) {
          setState(() {
            _latestServerPosition = newServerPosition;
            _displayedBusPosition = newServerPosition;
          });
          return;
        }

        if (_latestServerPosition != null &&
            _latestServerPosition!.latitude == newServerPosition.latitude &&
            _latestServerPosition!.longitude == newServerPosition.longitude) {
          return;
        }

        _latestServerPosition = newServerPosition;
        _animateBusTo(newServerPosition);
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _loadingSession = false;
          _sessionError = error.toString();
        });
      },
    );
  }

  void _rebuildRouteCumulativeDistances() {
    _routeCumulativeMeters = [];

    if (_routePoints.isEmpty) return;

    double total = 0.0;
    _routeCumulativeMeters.add(0.0);

    for (int i = 1; i < _routePoints.length; i++) {
      total += _distanceMeters(_routePoints[i - 1], _routePoints[i]);
      _routeCumulativeMeters.add(total);
    }
  }

  void _rebuildStopProgress() {
    _orderedStopProgress = [];

    if (_stopsDocs.isEmpty ||
        _routePoints.length < 2 ||
        _routeCumulativeMeters.isEmpty) {
      return;
    }

    final stops =
        _stopsDocs
            .map((doc) {
              final d = doc.data();
              final lat = d['latitude'];
              final lng = d['longitude'];

              if (lat is! num || lng is! num) return null;

              return {
                'name': (d['name'] ?? '--').toString(),
                'order': ((d['order'] ?? 0) as num).toInt(),
                'pos': LatLng(lat.toDouble(), lng.toDouble()),
              };
            })
            .whereType<Map<String, dynamic>>()
            .toList()
          ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

    double previousProgress = 0.0;

    for (final stop in stops) {
      final LatLng pos = stop['pos'] as LatLng;
      final double progress = _findStopProgressRespectingOrder(
        pos,
        previousProgress,
      );

      _orderedStopProgress.add(
        _StopProgress(
          name: stop['name'] as String,
          order: stop['order'] as int,
          position: pos,
          progressMeters: progress,
        ),
      );

      previousProgress = progress;
    }
  }

  double _findStopProgressRespectingOrder(
    LatLng stopPos,
    double previousProgress,
  ) {
    if (_routePoints.length < 2) return 0.0;

    final int startSegment = _segmentIndexForProgress(previousProgress);
    final int endSegment = _routePoints.length - 2;

    LatLng? bestPoint;
    double bestDistance = double.infinity;
    double bestProgress = previousProgress;

    for (int i = startSegment; i <= endSegment; i++) {
      final _ProjectedPoint projected = _projectPointOnSegmentWithT(
        stopPos,
        _routePoints[i],
        _routePoints[i + 1],
      );

      final double d = _distanceMeters(stopPos, projected.point);
      if (d < bestDistance) {
        bestDistance = d;
        bestPoint = projected.point;

        final double segmentLength = _distanceMeters(
          _routePoints[i],
          _routePoints[i + 1],
        );

        bestProgress =
            _routeCumulativeMeters[i] +
            (segmentLength * projected.t.clamp(0.0, 1.0));
      }
    }

    if (bestPoint == null) {
      return previousProgress;
    }

    if (bestProgress < previousProgress) {
      return previousProgress;
    }

    return bestProgress;
  }

  int _segmentIndexForProgress(double progressMeters) {
    if (_routePoints.length < 2 || _routeCumulativeMeters.isEmpty) return 0;

    for (int i = 0; i < _routeCumulativeMeters.length - 1; i++) {
      final double start = _routeCumulativeMeters[i];
      final double end = _routeCumulativeMeters[i + 1];

      if (progressMeters >= start && progressMeters <= end) {
        return i;
      }
    }

    return _routePoints.length - 2;
  }

  void _animateBusTo(LatLng newTarget) {
    final LatLng? start = _displayedBusPosition;
    if (start == null) {
      setState(() {
        _displayedBusPosition = newTarget;
      });
      return;
    }

    _movementTimer?.cancel();

    const int steps = 20;
    const Duration totalDuration = Duration(milliseconds: 1300);
    final int stepMs = (totalDuration.inMilliseconds / steps).round();

    int currentStep = 0;

    _movementTimer = Timer.periodic(Duration(milliseconds: stepMs), (timer) {
      currentStep++;

      final double t = currentStep / steps;

      final double lat =
          start.latitude + ((newTarget.latitude - start.latitude) * t);
      final double lng =
          start.longitude + ((newTarget.longitude - start.longitude) * t);

      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _displayedBusPosition = LatLng(lat, lng);
      });

      if (currentStep >= steps) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _displayedBusPosition = newTarget;
        });
      }
    });
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const Distance distance = Distance();
    return distance(a, b);
  }

  String _formatEtaFromSeconds(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds <= 0) {
      return '--';
    }

    if (seconds < 60) {
      return '${seconds.round()} sec';
    }

    final int minutes = (seconds / 60).ceil();
    return '$minutes min';
  }

  _ProjectedPoint _projectPointOnSegmentWithT(LatLng p, LatLng a, LatLng b) {
    final double ax = a.longitude;
    final double ay = a.latitude;
    final double bx = b.longitude;
    final double by = b.latitude;
    final double px = p.longitude;
    final double py = p.latitude;

    final double abx = bx - ax;
    final double aby = by - ay;
    final double apx = px - ax;
    final double apy = py - ay;

    final double abSquared = (abx * abx) + (aby * aby);
    if (abSquared == 0) {
      return _ProjectedPoint(a, 0.0);
    }

    double t = ((apx * abx) + (apy * aby)) / abSquared;
    t = t.clamp(0.0, 1.0);

    return _ProjectedPoint(LatLng(ay + (aby * t), ax + (abx * t)), t);
  }

  Map<String, String> _findCurrentNextEtaAndDistance({
    required double progressMeters,
    required double speedMps,
  }) {
    if (_orderedStopProgress.isEmpty) {
      return {'current': '___', 'next': '--', 'distance': '--', 'eta': '--'};
    }

    // إذا الباص قبل أول محطة
    if (progressMeters < _orderedStopProgress.first.progressMeters - 5) {
      final firstStop = _orderedStopProgress.first;
      final double remainingMeters = (firstStop.progressMeters - progressMeters)
          .clamp(0.0, double.infinity);

      final double effectiveSpeed = speedMps > 0.5 ? speedMps : 4.0;

      return {
        'current': '__',
        'next': firstStop.name,
        'distance': '${remainingMeters.round()} m',
        'eta': _formatEtaFromSeconds(remainingMeters / effectiveSpeed),
      };
    }

    int currentStopIndex = 0;

    for (int i = 0; i < _orderedStopProgress.length; i++) {
      if (_orderedStopProgress[i].progressMeters <= progressMeters + 5) {
        currentStopIndex = i;
      } else {
        break;
      }
    }

    final String currentName = _orderedStopProgress[currentStopIndex].name;

    if (currentStopIndex + 1 >= _orderedStopProgress.length) {
      return {
        'current': currentName,
        'next': '--',
        'distance': '--',
        'eta': '--',
      };
    }

    final _StopProgress nextStop = _orderedStopProgress[currentStopIndex + 1];
    final double remainingMeters = (nextStop.progressMeters - progressMeters)
        .clamp(0.0, double.infinity);

    final String distanceText = '${remainingMeters.round()} m';
    final double effectiveSpeed = speedMps > 0.5 ? speedMps : 4.0;
    final double etaSeconds = remainingMeters / effectiveSpeed;

    return {
      'current': currentName,
      'next': nextStop.name,
      'distance': distanceText,
      'eta': _formatEtaFromSeconds(etaSeconds),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Bus Tracking'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'في مشكلة بالاتصال: $_sessionError',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    String currentStopName = '___';
    String nextStopName = '--';
    String etaText = '--';
    String distanceText = '--';

    if (_hasActiveSession &&
        _displayedBusPosition != null &&
        _orderedStopProgress.isNotEmpty) {
      final result = _findCurrentNextEtaAndDistance(
        progressMeters: _routeProgressMeters,
        speedMps: _currentSpeed,
      );

      currentStopName = result['current'] ?? '___';
      nextStopName = result['next'] ?? '--';
      etaText = result['eta'] ?? '--';
      distanceText = result['distance'] ?? '--';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Bus Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: unitenCenter,
                    initialZoom: 15.8,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.unibus',
                    ),

                    if (_routePoints.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints,
                            strokeWidth: 4,
                            color: AppTheme.primaryBlue.withOpacity(0.55),
                          ),
                        ],
                      ),

                    MarkerLayer(
                      markers: [
                        ..._orderedStopProgress.map((stop) {
                          return Marker(
                            point: stop.position,
                            width: 22,
                            height: 22,
                            child: const Icon(
                              Icons.location_on,
                              size: 20,
                              color: AppTheme.primaryBlue,
                            ),
                          );
                        }),

                        if (_hasActiveSession && _displayedBusPosition != null)
                          Marker(
                            point: _displayedBusPosition!,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.directions_bus,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: _BottomInfoCard(
                      busName: _busName,
                      routeName: _routeName,
                      currentLocation: currentStopName,
                      nextStop: nextStopName,
                      etaText: etaText,
                      distanceText: distanceText,
                      onNotificationsTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.studentNotifications,
                        );
                      },
                      onFeedbackTap: () {
                        Navigator.pushNamed(context, AppRoutes.studentFeedback);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_loadingSession || _loadingStops || _loadingRoutePoints)
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Text(
                  'Loading database...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),

          if (!_hasActiveSession &&
              !_bannerDismissed &&
              !_loadingSession &&
              !_loadingStops &&
              !_loadingRoutePoints)
            Positioned(
              left: 14,
              right: 14,
              top: 14,
              child: _NoBusBanner(
                onClose: () {
                  setState(() {
                    _bannerDismissed = true;
                  });
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProjectedPoint {
  final LatLng point;
  final double t;

  const _ProjectedPoint(this.point, this.t);
}

class _StopProgress {
  final String name;
  final int order;
  final LatLng position;
  final double progressMeters;

  const _StopProgress({
    required this.name,
    required this.order,
    required this.position,
    required this.progressMeters,
  });
}

class _NoBusBanner extends StatelessWidget {
  final VoidCallback onClose;

  const _NoBusBanner({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'No active buses right now',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, size: 18, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomInfoCard extends StatelessWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onFeedbackTap;

  final String busName;
  final String routeName;
  final String currentLocation;
  final String nextStop;
  final String etaText;
  final String distanceText;

  const _BottomInfoCard({
    required this.onNotificationsTap,
    required this.onFeedbackTap,
    required this.busName,
    required this.routeName,
    required this.currentLocation,
    required this.nextStop,
    required this.etaText,
    required this.distanceText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            spreadRadius: 0,
            offset: Offset(0, 6),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.navigation_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      busName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Route: $routeName',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _LabelValue(
                    label: 'Current Location',
                    value: currentLocation,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LabelValue(label: 'Next Stop', value: nextStop),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  title: 'ETA to Next\nStop',
                  value: etaText,
                  isGreen: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStatCard(
                  title: 'Distance',
                  value: distanceText,
                  isGreen: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onNotificationsTap,
                  icon: const Icon(Icons.notifications_none, size: 18),
                  label: const Text('Notifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onFeedbackTap,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Feedback'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: const BorderSide(color: AppTheme.cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;

  const _LabelValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryBlue,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isGreen;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.isGreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGreen ? const Color(0xFFEAF7EE) : const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
