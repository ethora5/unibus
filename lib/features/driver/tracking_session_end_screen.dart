import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';

class TrackingSessionEndScreen extends StatelessWidget {
  const TrackingSessionEndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ علامة صح خضراء مثل التقرير
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EE),
                    borderRadius: BorderRadius.circular(35),
                    border: Border.all(color: const Color(0xFFBFE6C9)),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF1F9D55),
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Tracking Stopped',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Session ended successfully',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Duration: 00:00:03',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
                const SizedBox(height: 18),

                // ✅ زر يرجع للداشبورد (اختياري)
                TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.driverDashboard,
                    (_) => false,
                  ),
                  child: const Text('Back to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
