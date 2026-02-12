import 'package:flutter/material.dart';

import 'app/app_routes.dart';
import 'app/app_theme.dart';

void main() {
  runApp(const UniBusApp());
}

class UniBusApp extends StatelessWidget {
  const UniBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UniBus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.roleSelection,
      routes: AppRoutes.routes,
    );
  }
}
