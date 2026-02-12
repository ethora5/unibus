import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../app/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Select Your Role',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ✅ زر الطالب: ينقل لواجهة الطالب
                  _RoleButton(
                    icon: Icons.school_outlined,
                    label: 'Student',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.studentHome),
                  ),
                  const SizedBox(height: 14),

                  // ✅ زر السايق: ينقل لواجهة تسجيل دخول السايق
                  _RoleButton(
                    icon: Icons.badge_outlined,
                    label: 'Driver',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.driverLogin),
                  ),
                  const SizedBox(height: 14),

                  // ✅ زر الأدمن: ينقل لواجهة تسجيل دخول الأدمن
                  _RoleButton(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.adminLogin),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.primaryBlue),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
