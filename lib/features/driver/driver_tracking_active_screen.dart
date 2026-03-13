import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';

// هذه شاشة التتبع النشط للسائق
// الهدف منها:
// 1) إظهار أن التتبع شغال
// 2) عرض تفاصيل الجلسة الفعلية القادمة من الشاشة السابقة
// 3) إنشاء session فعلية وتغيير حالة الباص إلى in_use
// 4) بدء GPS updates الفعلية كل 5 ثواني وتخزين الموقع في Firestore
// 5) منع الخروج من الصفحة إلا عند الضغط على Stop Tracking
// 6) عند الإيقاف يتم إنهاء الجلسة وإرجاع الباص إلى available
class DriverTrackingActiveScreen extends StatefulWidget {
  const DriverTrackingActiveScreen({super.key});

  @override
  State<DriverTrackingActiveScreen> createState() =>
      _DriverTrackingActiveScreenState();
}

class _DriverTrackingActiveScreenState
    extends State<DriverTrackingActiveScreen> {
  // مؤقت لتحديث الوقت المنقضي كل ثانية
  Timer? timer;

  // مؤقت GPS كل 5 ثواني
  Timer? _gpsTimer;

  // عداد الثواني
  int seconds = 0;

  // بيانات الجلسة القادمة من الشاشة السابقة
  String driverName = 'Driver';
  String busId = 'Bus';
  String routeName = 'Route';
  String? busDocId;

  // حتى لا نعيد قراءة arguments أكثر من مرة
  bool _argsLoaded = false;

  // حتى لا نعيد بدء الجلسة أكثر من مرة
  bool _sessionStarted = false;

  // id الخاص بالجلسة الحالية في Firestore
  String? sessionDocId;

  // حالة بدء الجلسة / إيقافها
  bool isStartingSession = true;
  bool isStoppingSession = false;

  // رسالة خطأ إن وجدت
  String? sessionError;

  // آخر موقع فعلي
  Position? currentPosition;

  // حالة الجي بي اس
  bool gpsReady = false;

  @override
  void initState() {
    super.initState();

    // تشغيل المؤقت كل ثانية
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      // نعد الوقت فقط إذا الجلسة بدأت فعلاً وما زلنا لا نوقفها
      if (_sessionStarted && !isStoppingSession) {
        setState(() => seconds++);
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

      busDocId = args['busDocId'] as String?;
    }

    _argsLoaded = true;

    // بدء الجلسة الفعلية بعد استلام البيانات
    _startTrackingSession();
  }

  @override
  void dispose() {
    timer?.cancel();
    _stopGpsUpdates();
    super.dispose();
  }

  // تحويل عدد الثواني إلى HH:MM:SS
  String get elapsed {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int secs = seconds % 60;

    final String hh = hours.toString().padLeft(2, '0');
    final String mm = minutes.toString().padLeft(2, '0');
    final String ss = secs.toString().padLeft(2, '0');

    return '$hh:$mm:$ss';
  }

  // التحقق من خدمات الموقع والصلاحيات
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

  // بدء تحديثات GPS كل 5 ثواني
  Future<void> _startGpsUpdates() async {
    final bool allowed = await _checkAndRequestLocationPermission();
    if (!allowed) return;

    setState(() {
      gpsReady = true;
    });

    await _stopGpsUpdates();

    // أول قراءة مباشرة
    try {
      final Position firstPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        currentPosition = firstPosition;
      });

      await _updateLiveLocation(firstPosition);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        sessionError = 'Failed to get current location.';
      });
    }

    // بعدها يحدث كل 5 ثواني
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        if (!mounted) return;

        setState(() {
          currentPosition = position;
        });

        await _updateLiveLocation(position);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          sessionError = 'Failed to update GPS location.';
        });
      }
    });
  }

  // تحديث الموقع داخل Firestore
  Future<void> _updateLiveLocation(Position position) async {
    if (busDocId == null || busDocId!.trim().isEmpty) return;
    if (sessionDocId == null || sessionDocId!.trim().isEmpty) return;

    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final Timestamp now = Timestamp.now();

    try {
      await firestore.collection('driving_sessions').doc(sessionDocId).update({
        'currentLatitude': position.latitude,
        'currentLongitude': position.longitude,
        'currentSpeed': position.speed,
        'lastLocationUpdatedAt': now,
      });

      await firestore.collection('buses').doc(busDocId).update({
        'currentLatitude': position.latitude,
        'currentLongitude': position.longitude,
        'currentSpeed': position.speed,
        'gpsUpdatedAt': now,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        sessionError = 'Failed to update GPS location.';
      });
    }
  }

  // إيقاف gps
  Future<void> _stopGpsUpdates() async {
    _gpsTimer?.cancel();
    _gpsTimer = null;
  }

  // بدء session فعلية وتحديث حالة الباص
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

        // إنشاء session
        transaction.set(sessionRef, {
          'driverName': driverName,
          'busId': busId,
          'busDocId': busDocId,
          'routeName': routeName,
          'startTime': now,
          'endTime': null,
          'durationSeconds': 0,
          'status': 'active',
          'createdAt': now,
        });

        // تحديث الباص إلى in_use
        transaction.update(busRef, {
          'status': 'in_use',
          'assignedDriverName': driverName,
          'currentSessionId': sessionRef.id,
          'updatedAt': now,
        });
      });

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

  // إيقاف session وإرجاع الباص available
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

        // إنهاء الجلسة
        transaction.update(sessionRef, {
          'endTime': now,
          'durationSeconds': seconds,
          'status': 'completed',
          'updatedAt': now,
        });

        // إعادة الباص إلى available
        transaction.update(busRef, {
          'status': 'available',
          'assignedDriverName': null,
          'currentSessionId': null,
          'updatedAt': now,
        });
      });

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.trackingSessionEnd,
        arguments: {
          'driverName': driverName,
          'busId': busId,
          'busDocId': busDocId,
          'routeName': routeName,
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // منع الخروج بزر الرجوع
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
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFE6C9)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.wifi_tethering,
                      color: Color(0xFF1F9D55),
                      size: 34,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Tracking Activated',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isStartingSession
                          ? 'Starting tracking session...'
                          : 'GPS is actively tracking your\nlocation',
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
                      gpsReady ? 'Every 5 sec' : 'Starting',
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

// هذا عنصر بطاقة موحد لتقليل تكرار تصميم البطاقات
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

// هذا عنصر صف يعرض معلومة على اليسار وقيمتها على اليمين
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
