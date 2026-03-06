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

  Stream<QuerySnapshot<Map<String, dynamic>>> _latestSessionStream() {
    return FirebaseFirestore.instance
        .collection('drivingSessions')
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _latestSessionStream(),
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

        if (sessionData != null) {
          final dynamic endTime = sessionData['endTime'];
          final GeoPoint? gp = sessionData['lastLocation'] as GeoPoint?;

          final bool sessionNotEnded = endTime == null;
          final bool hasLocation = gp != null;

          if (sessionNotEnded && hasLocation) {
            hasActiveSession = true;
            busPosition = LatLng(gp.latitude, gp.longitude);
          }
        }

        String busName = '__';
        String routeName = '__';
        String currentStop = '__';
        String nextStop = '__';
        String etaText = '__';
        String distanceText = '__';

        if (sessionData != null) {
          final String? bn = sessionData['busName'] as String?;
          final String? rn = sessionData['routeName'] as String?;
          final String? cs = sessionData['currentStopName'] as String?;
          final String? ns = sessionData['nextStopName'] as String?;

          if (bn != null && bn.trim().isNotEmpty) busName = bn.trim();
          if (rn != null && rn.trim().isNotEmpty) routeName = rn.trim();
          if (cs != null && cs.trim().isNotEmpty) currentStop = cs.trim();
          if (ns != null && ns.trim().isNotEmpty) nextStop = ns.trim();

          final dynamic etaRaw = sessionData['etaMinutes'];
          if (etaRaw is int) {
            etaText = '$etaRaw mins';
          } else if (etaRaw is num) {
            etaText = '${etaRaw.toInt()} mins';
          }

          final dynamic distRaw = sessionData['distanceKm'];
          if (distRaw is num) {
            distanceText = '${distRaw.toStringAsFixed(1)} km';
          }
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
                    final List<Marker> stopMarkers = [];
                    final List<LatLng> routePoints = [];

                    if (stopsSnapshot.hasData) {
                      final stopsDocs = stopsSnapshot.data!.docs;

                      for (final doc in stopsDocs) {
                        final data = doc.data();

                        final dynamic latRaw = data['latitude'];
                        final dynamic lngRaw = data['longitude'];

                        if (latRaw is! num || lngRaw is! num) {
                          continue;
                        }

                        final LatLng stopPoint = LatLng(
                          latRaw.toDouble(),
                          lngRaw.toDouble(),
                        );

                        routePoints.add(stopPoint);

                        stopMarkers.add(
                          Marker(
                            point: stopPoint,
                            width: 20,
                            height: 20,
                            child: const Icon(
                              Icons.trip_origin,
                              size: 18,
                              color: Colors.blue,
                            ),
                          ),
                        );
                      }
                    }

                    return FlutterMap(
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

                        // المسار يظهر فقط إذا فيه باص شغال
                        if (hasActiveSession && routePoints.isNotEmpty)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                strokeWidth: 4,
                                color: AppTheme.primaryBlue,
                              ),
                            ],
                          ),

                        // المواقف
                        MarkerLayer(markers: stopMarkers),

                        // الباص
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

              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: _BottomInfoCard(
                    busName: busName,
                    routeName: routeName,
                    currentLocation: currentStop,
                    nextStop: nextStop,
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
