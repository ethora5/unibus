import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // ✅ نخزن اختيار المستخدم للـ 체크 بوكس
  bool busApproaching = true;
  bool scheduleChange = true;
  bool nextStopArrival = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          children: [
            const SizedBox(height: 8),

            // ✅ أيقونة وشرح مثل الصورة
            const Center(
              child: Icon(
                Icons.notifications_none,
                size: 46,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Choose Your Notifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Select the types of notifications you\nwant to receive',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            _NotificationTile(
              title: 'Bus Approaching Alert',
              subtitle: 'Get notified when the bus is\napproaching your stop',
              value: busApproaching,
              onChanged: (v) => setState(() => busApproaching = v),
            ),
            const SizedBox(height: 12),
            _NotificationTile(
              title: 'Schedule Change Alert',
              subtitle:
                  'Get notified when there are\nschedule changes or delays',
              value: scheduleChange,
              onChanged: (v) => setState(() => scheduleChange = v),
            ),
            const SizedBox(height: 12),
            _NotificationTile(
              title: 'Next Stop Arrival Alert',
              subtitle: 'Get notified when the bus\nreaches the next stop',
              value: nextStopArrival,
              onChanged: (v) => setState(() => nextStopArrival = v),
            ),
            const SizedBox(height: 18),

            // ✅ زر Save الكبير مثل الصورة
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // ✅ حالياً بس رسالة نجاح (لاحقاً تربطينه بفايرستور)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Saved')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

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
      child: Row(
        children: [
          // ✅ checkbox يسار مثل الصورة
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
