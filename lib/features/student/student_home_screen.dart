import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../app/app_theme.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ✅ نفس عنوان الصورة
        title: const Text('Live Bus Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // ✅ مكان الخريطة (Placeholder)
          Positioned.fill(
            child: Container(
              color: const Color(0xFFEFF3FA),
              child: const Center(
                // 🔵 لاحقاً نستبدله بـ GoogleMap widget
                child: Icon(
                  Icons.map_outlined,
                  size: 80,
                  color: Colors.black26,
                ),
              ),
            ),
          ),

          // ✅ البطاقة البيضاء اللي تحت فوق الخريطة
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: _BottomInfoCard(
                  onNotificationsTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.studentNotifications,
                  ),
                  onFeedbackTap: () =>
                      Navigator.pushNamed(context, AppRoutes.studentFeedback),
                ),
              ),
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

  const _BottomInfoCard({
    required this.onNotificationsTap,
    required this.onFeedbackTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // ✅ Bus title + route
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bus A',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Route: Main Campus Loop',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ صف معلومات: Current / Next stop
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Column(
              children: [
                _InfoRow(
                  leftLabel: 'Current Location',
                  leftValue: 'Library Stop',
                  rightLabel: 'Next Stop',
                  rightValue: 'Science Building',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ✅ بطاقتين صغيرات: ETA + Distance
          const Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  title: 'ETA to Next\nStop',
                  value: '3 mins',
                  isGreen: true,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MiniStatCard(
                  title: 'Distance',
                  value: '0.8 km',
                  isGreen: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ✅ أزرار تحت: Notifications + Feedback
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

class _InfoRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  const _InfoRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LabelValue(label: leftLabel, value: leftValue),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _LabelValue(label: rightLabel, value: rightValue),
        ),
      ],
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
