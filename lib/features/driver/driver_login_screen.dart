import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../app/app_routes.dart';
import '../../app/app_theme.dart';
import '../../core/services/driver_active_session_service.dart';

class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  String? errorText;

  Future<void> _signInDriver() async {
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final String? loggedInEmail = userCredential.user?.email;
      if (loggedInEmail == null) {
        throw Exception('No user email found.');
      }

      final QuerySnapshot<Map<String, dynamic>> driverQuery =
          await FirebaseFirestore.instance
              .collection('drivers')
              .where('email', isEqualTo: loggedInEmail)
              .limit(1)
              .get();

      if (driverQuery.docs.isEmpty) {
        throw Exception('Driver data not found in database.');
      }

      final activeSession =
          await DriverActiveSessionService.getValidActiveSessionForDriver(
            driverEmail: loggedInEmail,
          );

      if (!mounted) return;

      if (activeSession != null) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.driverTrackingActive,
          (_) => false,
          arguments: {
            'driverName': activeSession['driverName'],
            'busId': activeSession['busId'],
            'busDocId': activeSession['busDocId'],
            'routeName': activeSession['routeName'],
            'sessionDocId': activeSession['sessionId'],
            'resumeSession': true,
            'startSeconds': activeSession['startSeconds'],
          },
        );
        return;
      }

      Navigator.pushReplacementNamed(context, AppRoutes.driverDashboard);
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed. Please try again.';

      if (e.code == 'user-not-found') {
        message = 'No user found for this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password.';
      } else if (e.code == 'invalid-credential') {
        message = 'Wrong email or password.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      }

      setState(() {
        errorText = message;
      });
    } catch (e) {
      setState(() {
        errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool canSignIn =
        emailController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty &&
        !isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.login, color: AppTheme.primaryBlue),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Driver Access',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Sign in to start tracking',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Email',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _InputField(
              controller: emailController,
              hintText: '',
              prefixIcon: Icons.email_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            const Text(
              'Password',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _InputField(
              controller: passwordController,
              hintText: '',
              prefixIcon: Icons.lock_outline,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (errorText != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD6D6)),
                ),
                child: Text(
                  errorText!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (errorText != null) const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: canSignIn ? _signInDriver : null,
                icon: isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login, size: 18),
                label: Text(isLoading ? 'Signing In...' : 'Sign In'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE3E7EF),
                  disabledForegroundColor: Colors.black38,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon, color: Colors.black45),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppTheme.primaryBlue,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}