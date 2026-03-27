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

  Stream<QuerySnapshot<Map<String, dynamic>>> _activeSessionStream() {
    return FirebaseFirestore.instance
        .collection('driving_sessions')
        .where('status', isEqualTo: 'active')
        .orderBy('startTime', descending: true)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _stopsStream() {
    return FirebaseFirestore.instance
        .collection('stops')
        .orderBy('order')
        .snapshots();
  }

  // حساب المسافة بين نقطتين بالمتر
  double _distanceMeters(LatLng a, LatLng b) {
    const Distance distance = Distance();
    return distance(a, b);
  }

  // تنسيق ETA بناءً على الثواني
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

  // إيجاد أقرب موقف + الموقف التالي + المسافة + ETA
  Map<String, String> _findCurrentNextEtaAndDistance({
    required LatLng busPos,
    required double speedMps,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> stopsDocs,
  }) {
    if (stopsDocs.isEmpty) {
      return {'current': '___', 'next': '--', 'distance': '--', 'eta': '--'};
    }

    final stops =
        stopsDocs.map((doc) {
            final d = doc.data();

            return {
              'name': (d['name'] ?? '--').toString(),
              'order': ((d['order'] ?? 0) as num).toInt(),
              'pos': LatLng(
                (d['latitude'] as num).toDouble(),
                (d['longitude'] as num).toDouble(),
              ),
            };
          }).toList()
          ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

    double bestDistance = double.infinity;
    int bestIndex = 0;

    for (int i = 0; i < stops.length; i++) {
      final LatLng stopPos = stops[i]['pos'] as LatLng;
      final double d = _distanceMeters(busPos, stopPos);

      if (d < bestDistance) {
        bestDistance = d;
        bestIndex = i;
      }
    }

    final String currentName = stops[bestIndex]['name'] as String;

    // إذا ما فيه موقف بعده
    if (bestIndex + 1 >= stops.length) {
      return {
        'current': currentName,
        'next': '--',
        'distance': '--',
        'eta': '--',
      };
    }

    final String nextName = stops[bestIndex + 1]['name'] as String;
    final LatLng nextPos = stops[bestIndex + 1]['pos'] as LatLng;

    final double distanceToNext = _distanceMeters(busPos, nextPos);
    final String distanceText = '${distanceToNext.round()} m';

    // إذا السرعة ضعيفة جدًا أو صفر، ما نحسب ETA
    String etaText = '--';
    if (speedMps > 0.5) {
      final double etaSeconds = distanceToNext / speedMps;
      etaText = _formatEtaFromSeconds(etaSeconds);
    }

    return {
      'current': currentName,
      'next': nextName,
      'distance': distanceText,
      'eta': etaText,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _activeSessionStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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
                'في مشكلة بالاتصال: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final bool loading =
            snapshot.connectionState == ConnectionState.waiting;

        final bool hasSessionDoc =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        Map<String, dynamic>? sessionData;
        if (hasSessionDoc) {
          sessionData = snapshot.data!.docs.first.data();
        }

        bool hasActiveSession = false;
        LatLng? busPosition;
        double currentSpeed = 0.0;

        if (sessionData != null) {
          final dynamic latRaw = sessionData['currentLatitude'];
          final dynamic lngRaw = sessionData['currentLongitude'];
          final dynamic speedRaw = sessionData['currentSpeed'];
          final String status =
              (sessionData['status'] as String?)?.trim().toLowerCase() ?? '';

          final bool hasValidLocation = latRaw is num && lngRaw is num;
          final bool isActive = status == 'active';

          if (speedRaw is num) {
            currentSpeed = speedRaw.toDouble();
          }

          if (isActive && hasValidLocation) {
            hasActiveSession = true;
            busPosition = LatLng(latRaw.toDouble(), lngRaw.toDouble());
          }
        }

        String busName = '__';
        String routeName = '__';

        if (sessionData != null) {
          final String? bn = sessionData['busId'] as String?;
          final String? rn = sessionData['routeName'] as String?;

          if (bn != null && bn.trim().isNotEmpty) busName = bn.trim();
          if (rn != null && rn.trim().isNotEmpty) routeName = rn.trim();
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
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _stopsStream(),
                  builder: (context, stopsSnapshot) {
                    String currentStopName = '___';
                    String nextStopName = '--';
                    String etaText = '--';
                    String distanceText = '--';

                    if (stopsSnapshot.hasData) {
                      final stopsDocs = stopsSnapshot.data!.docs;

                      if (hasActiveSession && busPosition != null) {
                        final result = _findCurrentNextEtaAndDistance(
                          busPos: busPosition,
                          speedMps: currentSpeed,
                          stopsDocs: stopsDocs,
                        );

                        currentStopName = result['current'] ?? '___';
                        nextStopName = result['next'] ?? '--';
                        etaText = result['eta'] ?? '--';
                        distanceText = result['distance'] ?? '--';
                      }
                    }

                    return Stack(
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

                            // الباص النشط فقط
                            MarkerLayer(
                              markers: [
                                if (hasActiveSession && busPosition != null)
                                  Marker(
                                    point: busPosition,
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
                              busName: busName,
                              routeName: routeName,
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
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.studentFeedback,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              if (loading)
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

              if (!hasActiveSession && !_bannerDismissed && !loading)
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
      },
    );
  }
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
