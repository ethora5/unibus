import 'package:flutter/material.dart';

import '../features/role/role_selection_screen.dart';

// Student
import '../features/student/student_home_screen.dart';
import '../features/student/notification_settings_screen.dart';
import '../features/student/feedback_screen.dart';

// Driver
import '../features/driver/driver_login_screen.dart';
import '../features/driver/driver_dashboard_screen.dart';
import '../features/driver/driver_tracking_active_screen.dart';
import '../features/driver/tracking_session_end_screen.dart';

// Admin
import '../features/admin/admin_login_screen.dart';
import '../features/admin/feedback_center_screen.dart';

class AppRoutes {
  static const String roleSelection = '/role-selection';

  // Student
  static const String studentHome = '/student-home';
  static const String studentNotifications = '/student-notifications';
  static const String studentFeedback = '/student-feedback';
  static const String studentMap = '/student-map';

  // Driver
  static const String driverLogin = '/driver-login';
  static const String driverDashboard = '/driver-dashboard';
  static const String driverTrackingActive = '/driver-tracking-active';
  static const String trackingSessionEnd = '/tracking-session-end';

  // Admin
  static const String adminLogin = '/admin-login';
  static const String feedbackCenter = '/feedback-center';
  static const String driverPerformance = '/driver-performance';

  static Map<String, WidgetBuilder> get routes => {
    roleSelection: (_) => const RoleSelectionScreen(),

    // Student
    studentHome: (_) => const StudentHomeScreen(),
    studentNotifications: (_) => const NotificationSettingsScreen(),
    studentFeedback: (_) => const FeedbackScreen(),

    // Driver
    driverLogin: (_) => const DriverLoginScreen(),
    driverDashboard: (_) => const DriverDashboardScreen(),
    driverTrackingActive: (_) => const DriverTrackingActiveScreen(),
    trackingSessionEnd: (_) => const TrackingSessionEndScreen(),

    // Admin
    adminLogin: (_) => const AdminLoginScreen(),
    feedbackCenter: (_) => const FeedbackCenterScreen(),
  };
}
