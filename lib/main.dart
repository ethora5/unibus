import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app_routes.dart';
import 'app/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
