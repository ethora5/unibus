import 'dart:async';
import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';

// هذه شاشة التتبع النشط للسائق
// الهدف منها:
// 1) إظهار أن التتبع شغال
// 2) عرض تفاصيل الجلسة
// 3) عرض الوقت المنقضي منذ بدء التتبع
// 4) توفير زر لإيقاف التتبع والانتقال لشاشة إنهاء الجلسة
class DriverTrackingActiveScreen extends StatefulWidget {
  const DriverTrackingActiveScreen({super.key});

  @override
  State<DriverTrackingActiveScreen> createState() =>
      _DriverTrackingActiveScreenState();
}

class _DriverTrackingActiveScreenState
    extends State<DriverTrackingActiveScreen> {
  // مؤقت يتم تشغيله لتحديث الوقت المنقضي كل ثانية
  late Timer timer;

  // عدّاد الثواني منذ فتح الصفحة (يمثل مدة التتبع بشكل مبسط)
  int seconds = 0;

  @override
  void initState() {
    super.initState();

    // تشغيل مؤقت يتكرر كل ثانية
    // كل ثانية نزيد العداد ونبني الواجهة من جديد لتحديث الوقت المعروض
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => seconds++);
    });
  }

  @override
  void dispose() {
    // إيقاف المؤقت عند الخروج من الصفحة لتجنب استمرار عمله بالخلفية
    timer.cancel();
    super.dispose();
  }

  // تحويل عدد الثواني إلى صيغة وقت جاهزة للعرض
  // هنا يتم عرضها بصيغة ساعات ثابتة مع دقائق وثواني
  String get elapsed {
    // حساب الدقائق من إجمالي الثواني
    final int m = seconds ~/ 60;

    // حساب الثواني المتبقية بعد استخراج الدقائق
    final int s = seconds % 60;

    // تنسيق الدقائق ليكون دائماً رقمين
    final String mm = m.toString().padLeft(2, '0');

    // تنسيق الثواني ليكون دائماً رقمين
    final String ss = s.toString().padLeft(2, '0');

    // إرجاع النص النهائي للعرض
    return '00:$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // عنوان الصفحة
        title: const Text('Tracking Active'),

        // زر رجوع للصفحة السابقة
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // حماية المحتوى من شريط الحالة
      body: SafeArea(
        // قائمة قابلة للتمرير لتجنب قص المحتوى في الشاشات الصغيرة
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          children: [
            // بطاقة خضراء توضح أن التتبع مفعل
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EE),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFE6C9)),
              ),
              child: Column(
                // عناصر البطاقة ثابتة ولا تحتاج إعادة بناء منفصلة
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

            // بطاقة تفاصيل الجلسة
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Session Details',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  SizedBox(height: 12),

                  // صفوف معلومات ثابتة حالياً (تجريبية)
                  _KeyValueRow(left: 'Driver Name', right: 'Bouq'),
                  _KeyValueRow(left: 'Bus Number', right: 'Bus A'),
                  _KeyValueRow(left: 'Route', right: 'Main Campus Loop'),

                  // هذا السطر فيه نقطة خضراء لتمييز أن الحالة فعالة
                  _KeyValueRow(
                    left: 'Tracking Status',
                    right: 'GPS Active',
                    rightGreenDot: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // بطاقة الوقت المنقضي
            _Card(
              child: Column(
                children: [
                  const Text(
                    'Elapsed Time',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // هذا النص يتغير كل ثانية لأن قيمة elapsed تتغير
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

            // بطاقة توضح حالة تحديثات الموقع
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

            // زر إيقاف التتبع
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // عند الضغط ننهي التتبع من ناحية الواجهة
                  // ثم ننتقل لشاشة نهاية الجلسة مع استبدال الصفحة الحالية
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

// هذا عنصر بطاقة موحد لتقليل تكرار تصميم البطاقات
// نستخدمه لأي جزء نريد له نفس الشكل (خلفية + حدود + ظل)
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
// ويوفر خيار إضافة نقطة خضراء قبل القيمة لتوضيح أن الحالة فعّالة
class _KeyValueRow extends StatelessWidget {
  final String left;
  final String right;

  // إذا كانت صحيحة يتم عرض نقطة خضراء قبل القيمة
  final bool rightGreenDot;

  const _KeyValueRow({
    required this.left,
    required this.right,
    this.rightGreenDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      // مسافة أسفل كل صف حتى لا تلتصق الصفوف ببعض
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // نص العنوان يأخذ المساحة المتاحة
          Expanded(
            child: Text(
              left,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),

          // إذا الخيار مفعل نضيف نقطة خضراء قبل القيمة
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

          // نص القيمة
          Text(
            right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
