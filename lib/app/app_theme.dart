import 'package:flutter/material.dart';

// هذا الملف مسؤول عن تعريف ألوان وتصميم التطبيق العام
// الهدف منه توحيد الهوية البصرية في كل الصفحات
// بحيث نتحكم في الألوان الرئيسية من مكان واحد فقط
class AppTheme {
  // اللون الأزرق الأساسي المستخدم في الأزرار وشريط العنوان والعناصر المهمة
  static const Color primaryBlue = Color(0xFF1E66F5);

  // لون الحدود المستخدمة في البطاقات والعناصر البيضاء
  static const Color cardBorder = Color(0xFFE6EAF2);

  // هذا يعيد إعدادات التصميم الفاتح للتطبيق
  // يتم تمريره للتطبيق عند الإنشاء
  static ThemeData get lightTheme {
    return ThemeData(
      // تفعيل نظام التصميم الحديث
      useMaterial3: true,

      // لون الخلفية الافتراضي لكل الصفحات
      scaffoldBackgroundColor: Colors.white,

      // إعداد مخطط الألوان العام للتطبيق
      colorScheme: ColorScheme.fromSeed(
        // اللون الأساسي الذي تُبنى عليه بقية الألوان
        seedColor: primaryBlue,

        // تحديد اللون الأساسي صراحة
        primary: primaryBlue,
      ),

      // تخصيص شكل شريط العنوان في جميع الصفحات
      appBarTheme: const AppBarTheme(
        // لون خلفية شريط العنوان
        backgroundColor: primaryBlue,

        // لون النص والأيقونات داخل شريط العنوان
        foregroundColor: Colors.white,

        // جعل العنوان بمحاذاة اليسار
        centerTitle: false,

        // إزالة الظل الافتراضي أسفل شريط العنوان
        elevation: 0,
      ),
    );
  }
}
