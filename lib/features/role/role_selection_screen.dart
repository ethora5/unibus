import 'package:flutter/material.dart';
import '../../app/app_routes.dart';
import '../../app/app_theme.dart';

// صفحة اختيار الدور + زر About
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

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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

// زر About
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
            size: 18,
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
            children: [
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_bus_rounded,
                      size: 42,
                      color: AppTheme.primaryBlue,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'UniBus',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Smarter Rides for Students',
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              _AboutSection(
                title: 'Project Mission',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _InfoLabel(
                      label: 'Application Name',
                      value: 'UniBus (Smarter Rides for Students)',
                    ),
                    SizedBox(height: 12),
                    _InfoLabel(
                      label: 'Description',
                      value:
                          'UniBus is a real-time bus tracking mobile application designed to support university transportation. It enables students to track buses live, view routes, and access estimated arrival times to improve their daily commuting experience.',
                    ),
                    SizedBox(height: 12),
                    _InfoLabel(
                      label: 'Objective',
                      value:
                          'To reduce waiting time and enhance smart transportation efficiency for students.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _AboutSection(
                title: 'Development Team',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'This application is developed as a Final Year Project.',
                      style: TextStyle(height: 1.6),
                    ),
                    SizedBox(height: 12),
                    _InfoLabel(
                      label: 'Developer',
                      value: 'Ethar Mukhtar Mohamed Omer Ramadan',
                    ),
                    SizedBox(height: 12),
                    _InfoLabel(
                      label: 'Institution',
                      value:
                          'Universiti Tenaga Nasional (UNITEN)\nCollege of Computing and Informatics',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _AboutSection(
                title: 'Privacy & Legal',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _InfoLabel(
                      label: 'Privacy Policy',
                      value:
                          'This application uses location data only for tracking buses and improving user experience. No personal data is shared with third parties.',
                    ),
                    SizedBox(height: 12),
                    _InfoLabel(
                      label: 'Disclaimer',
                      value:
                          'This application is a prototype developed for academic purposes. Data accuracy may vary depending on GPS signal and network stability.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _AboutSection(
                title: 'Contact & Support',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'For feedback or technical issues, please contact:',
                        style: TextStyle(height: 1.6),
                      ),
                      SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 18,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'etharmukh05@gmail.com',
                              style: TextStyle(height: 1.6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '+60 10-599 9160',
                              style: TextStyle(height: 1.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Center(
                child: Text(
                  'Version: v1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _AboutSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoLabel extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLabel({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(height: 1.6, color: Colors.black87)),
      ],
    );
  }
}
