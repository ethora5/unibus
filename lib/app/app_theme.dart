import 'package:flutter/material.dart';

class AppTheme {
  // ✅ نفس إحساس اللون الأزرق في التقرير
  static const Color primaryBlue = Color(0xFF1E66F5);
  static const Color cardBorder = Color(0xFFE6EAF2);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
    );
  }
}
