import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';

class DriverTrackingActiveScreen extends StatefulWidget {
  const DriverTrackingActiveScreen({super.key});

  @override
  State<DriverTrackingActiveScreen> createState() =>
      _DriverTrackingActiveScreenState();
}

class _DriverTrackingActiveScreenState
    extends State<DriverTrackingActiveScreen> {
  late Timer timer;
  int seconds = 0;

  @override
  void initState() {
    super.initState();
    // ✅ مؤقت بسيط عشان يطلع elapsed time مثل التقرير
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => seconds++);
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  String get elapsed {
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    final String mm = m.toString().padLeft(2, '0');
    final String ss = s.toString().padLeft(2, '0');
    return '00:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking Active'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          children: [
            // ✅ كارد أخضر Tracking Activated
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFE6C9)),
              ),
              child: Column(
                children: const [
                  Icon(
                    Icons.wifi_tethering,
                    color: Color(0xFF1F9D55),
                    size: 34,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Tracking Activated',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'GPS is actively tracking your\nlocation',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ✅ Session Details
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Session Details',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  SizedBox(height: 12),
                  _KeyValueRow(left: 'Driver Name', right: 'Bouq'),
                  _KeyValueRow(left: 'Bus Number', right: 'Bus A'),
                  _KeyValueRow(left: 'Route', right: 'Main Campus Loop'),
                  _KeyValueRow(
                    left: 'Tracking Status',
                    right: 'GPS Active',
                    rightGreenDot: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ✅ Elapsed Time
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

            // ✅ GPS Updates row
            _Card(
              child: Row(
                children: const [
                  Icon(Icons.gps_fixed, color: Colors.black54, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'GPS Updates',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    'Active',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ✅ Stop Tracking red button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // ✅ ننهي التتبع ونوديه لشاشة النهاية
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.trackingSessionEnd,
                  );
                },
                icon: const Icon(Icons.stop_circle_outlined),
                label: const Text('Stop Tracking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
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
    );
  }
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
