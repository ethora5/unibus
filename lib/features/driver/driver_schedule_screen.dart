import 'package:flutter/material.dart';

// هذه شاشة عرض جدول الحافلة
// الهدف منها عرض صورة جدول الرحلات
// مع إمكانية التكبير والتصغير والتحريك داخل الصورة
class DriverScheduleScreen extends StatelessWidget {
  const DriverScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // شريط علوي يحتوي على اسم المسار
      appBar: AppBar(title: const Text('UNITEN Internal Shuttle Bus')),

      // جسم الصفحة
      body: InteractiveViewer(
        // أقل مستوى تكبير مسموح
        // 1 يعني الحجم الطبيعي للصورة
        minScale: 1,

        // أعلى مستوى تكبير مسموح
        // يسمح للمستخدم بتكبير الصورة حتى أربع مرات
        maxScale: 4,

        // نضع الصورة في المنتصف
        child: Center(
          child: Image.asset(
            // مسار صورة الجدول داخل مجلد الأصول
            'assets/images/bus_schedule.png',

            // يجعل الصورة تتناسب داخل الشاشة بدون قص
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
