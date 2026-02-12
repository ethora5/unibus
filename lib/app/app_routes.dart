import 'package:flutter/material.dart';

import '../features/role/role_selection_screen.dart';
import '../features/student/student_home_screen.dart';
import '../features/student/notification_settings_screen.dart';
import '../features/student/feedback_screen.dart';

class AppRoutes {
  // ✅ أسماء الروتس ثابتة عشان ما تغلطين بالكتابة
  static const String roleSelection = '/role-selection';
  static const String studentHome = '/student-home';
  static const String studentNotifications = '/student-notifications';
  static const String studentFeedback = '/student-feedback';

  static Map<String, WidgetBuilder> get routes => {
    roleSelection: (_) => const RoleSelectionScreen(),
    studentHome: (_) => const StudentHomeScreen(),
    studentNotifications: (_) => const NotificationSettingsScreen(),
    studentFeedback: (_) => const FeedbackScreen(),
  };
}
