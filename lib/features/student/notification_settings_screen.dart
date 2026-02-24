import 'package:flutter/material.dart';
import '../../app/app_theme.dart';

// شاشة إعدادات الإشعارات
// تسمح للمستخدم بتحديد أنواع التنبيهات التي يريد استلامها
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // متغيرات منطقية تخزن حالة كل خيار
  // إذا كانت القيمة صحيحة يعني الإشعار مفعل
  bool busApproaching = true;
  bool scheduleChange = true;
  bool nextStopArrival = false;

  @override
  Widget build(BuildContext context) {
    // الهيكل الأساسي للصفحة
    return Scaffold(
      appBar: AppBar(
        // عنوان الصفحة في الأعلى
        title: const Text('Notification Settings'),

        // زر رجوع يدوي
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // حماية المحتوى من شريط الحالة
      body: SafeArea(
        child: ListView(
          // مسافات داخلية عامة للصفحة
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          children: [
            const SizedBox(height: 8),

            // أيقونة توضيحية في الأعلى
            const Center(
              child: Icon(
                Icons.notifications_none,
                size: 46,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 10),

            // عنوان توضيحي للمستخدم
            const Center(
              child: Text(
                'Choose Your Notifications',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),

            const SizedBox(height: 6),

            // وصف قصير يشرح وظيفة الصفحة
            const Center(
              child: Text(
                'Select the types of notifications you\nwant to receive',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),

            const SizedBox(height: 16),

            // خيار تنبيه اقتراب الحافلة
            _NotificationTile(
              title: 'Bus Approaching Alert',
              subtitle: 'Get notified when the bus is\napproaching your stop',
              value: busApproaching,

              // عند تغيير الحالة يتم تحديث القيمة وإعادة بناء الواجهة
              onChanged: (v) => setState(() => busApproaching = v),
            ),

            const SizedBox(height: 12),

            // خيار تنبيه تغيير الجدول
            _NotificationTile(
              title: 'Schedule Change Alert',
              subtitle:
                  'Get notified when there are\nschedule changes or delays',
              value: scheduleChange,
              onChanged: (v) => setState(() => scheduleChange = v),
            ),

            const SizedBox(height: 12),

            // خيار تنبيه الوصول للمحطة التالية
            _NotificationTile(
              title: 'Next Stop Arrival Alert',
              subtitle: 'Get notified when the bus\nreaches the next stop',
              value: nextStopArrival,
              onChanged: (v) => setState(() => nextStopArrival = v),
            ),

            const SizedBox(height: 18),

            // زر الحفظ في الأسفل
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // حالياً فقط يعرض رسالة نجاح
                  // لاحقاً يمكن ربطه بقاعدة البيانات لحفظ الإعدادات
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Saved')));
                },

                // تنسيق الزر حسب ألوان التصميم
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

// عنصر مخصص يمثل بطاقة خيار إشعار واحدة
// الهدف منه: تجنب تكرار نفس التصميم ثلاث مرات
class _NotificationTile extends StatelessWidget {
  // عنوان الخيار
  final String title;

  // وصف الخيار
  final String subtitle;

  // القيمة الحالية لمربع الاختيار
  final bool value;

  // الدالة التي تنفذ عند تغيير حالة المربع
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

      // تصميم البطاقة من لون وحدود وظل
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),

        // ظل خفيف لإعطاء عمق بصري
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
          // مربع الاختيار
          Checkbox(
            value: value,

            // عند تغيير الحالة نمرر القيمة للدالة القادمة من الشاشة الرئيسية
            onChanged: (v) => onChanged(v ?? false),

            // لون التفعيل حسب الثيم
            activeColor: AppTheme.primaryBlue,
          ),

          const SizedBox(width: 6),

          // النصوص تأخذ باقي المساحة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // عنوان الخيار
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                // وصف الخيار
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
