import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';

// هذه شاشة نهاية جلسة التتبع
// الهدف منها إظهار رسالة نجاح بعد إيقاف التتبع
// وتوفير زر يرجع المستخدم للوحة السائق
class TrackingSessionEndScreen extends StatelessWidget {
  const TrackingSessionEndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // لا يوجد شريط علوي لأن التصميم يعتمد على رسالة في وسط الصفحة
      body: SafeArea(
        // حماية المحتوى من شريط الحالة
        child: Center(
          // توسيط المحتوى في منتصف الشاشة
          child: Padding(
            // مسافة داخلية من اليمين واليسار لتحسين شكل العناصر
            padding: const EdgeInsets.symmetric(horizontal: 24),

            // ترتيب العناصر عموديًا في منتصف الشاشة
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // دائرة خضراء بداخلها علامة صح للدلالة على نجاح الإيقاف
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

                // عنوان رئيسي يوضح أن التتبع توقف
                const Text(
                  'Tracking Stopped',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 6),

                // وصف بسيط يوضح أن الجلسة انتهت بنجاح
                const Text(
                  'Session ended successfully',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),

                const SizedBox(height: 6),

                // مدة الجلسة المعروضة حالياً ثابتة للتجربة
                // لاحقاً يمكن تمرير المدة الحقيقية من صفحة التتبع أو حسابها من قاعدة البيانات
                const Text(
                  'Duration: 00:00:03',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),

                const SizedBox(height: 18),

                // زر يرجع المستخدم للوحة السائق
                // يتم مسح الصفحات السابقة حتى لا يرجع المستخدم للخلف إلى شاشة التتبع
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
