import 'package:flutter/material.dart';
import '../../app/app_routes.dart';
import '../../app/app_theme.dart';

// صفحة اختيار الدور + زر About (أيقونة فقط)
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
                children: [
                  const SizedBox(height: 10),

                  // زر About (أيقونة فقط)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _SmallAboutButton(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AboutAppScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // المحتوى الأساسي
                  Expanded(
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

                        _RoleButton(
                          label: 'Student',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.studentHome);
                          },
                        ),

                        const SizedBox(height: 14),

                        _RoleButton(
                          label: 'Driver',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.driverLogin);
                          },
                        ),

                        const SizedBox(height: 14),

                        _RoleButton(
                          label: 'Admin',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.adminLogin);
                          },
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// زر About (أيقونة فقط)
class _SmallAboutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SmallAboutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.cardBorder, width: 1.2),
          ),
          child: const Icon(
            Icons.info_outline,
            size: 18, // حجم صغير ومرتب
            color: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }
}

// زر الأدوار
class _RoleButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _RoleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

// صفحة About
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About UniBus')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'UniBus',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryBlue,
                ),
              ),
              SizedBox(height: 10),

              Text(
                'UniBus is a real-time bus tracking system designed for university students. It allows users to track buses live, view routes, and know estimated arrival times.',
                style: TextStyle(height: 1.6),
              ),

              SizedBox(height: 16),

              Text('Features', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),

              Text(
                '• Live bus tracking\n'
                '• View current and next stop\n'
                '• ETA and distance calculation\n'
                '• Student, Driver, Admin roles\n'
                '• Notifications and feedback',
                style: TextStyle(height: 1.6),
              ),

              SizedBox(height: 16),

              Text('Purpose', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 6),

              Text(
                'The system improves transportation efficiency and reduces waiting time for students.',
                style: TextStyle(height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
