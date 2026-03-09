import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';

// هذه شاشة تسجيل دخول السائق
// الهدف منها:
// 1) إدخال البريد
// 2) إدخال كلمة المرور مع خيار إظهار/إخفاء
// 3) تفعيل زر الدخول فقط عند إدخال القيم المطلوبة
// 4) عند نجاح تسجيل الدخول يتم التحقق من Firebase Auth
// 5) ثم يتم جلب بيانات السائق من Firestore
class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  // متحكم حقل البريد الإلكتروني
  final TextEditingController emailController = TextEditingController();

  // متحكم حقل كلمة المرور
  final TextEditingController passwordController = TextEditingController();

  // هذا المتغير يتحكم في إظهار أو إخفاء كلمة المرور
  bool obscurePassword = true;

  // هذا المتغير يوضح هل زر الدخول في حالة تحميل أم لا
  bool isLoading = false;

  // هذا النص يظهر للمستخدم إذا صار خطأ
  String? errorText;

  // دالة تسجيل دخول السائق
  Future<void> _signInDriver() async {
    // تنظيف أي رسالة خطأ سابقة
    setState(() {
      isLoading = true;
      errorText = null;
    });

    try {
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();

      // التحقق من Firebase Authentication
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final String? loggedInEmail = userCredential.user?.email;

      if (loggedInEmail == null) {
        throw Exception('No user email found.');
      }

      // بعد نجاح تسجيل الدخول نبحث عن بيانات السائق داخل Firestore
      final QuerySnapshot<Map<String, dynamic>> driverQuery =
          await FirebaseFirestore.instance
              .collection('drivers')
              .where('email', isEqualTo: loggedInEmail)
              .limit(1)
              .get();

      // إذا لم نجد السائق في قاعدة البيانات
      if (driverQuery.docs.isEmpty) {
        throw Exception('Driver data not found in database.');
      }

      if (!mounted) return;

      // الانتقال إلى لوحة السائق بدون أي SnackBar
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
    // إغلاق المتحكمات عند خروج الصفحة لتجنب تسريب الذاكرة
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // شرط تفعيل زر الدخول
    final bool canSignIn =
        emailController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty &&
        !isLoading;

    return Scaffold(
      appBar: AppBar(
        // عنوان الصفحة
        title: const Text('Driver Login'),

        // زر رجوع للصفحة السابقة
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // حماية المحتوى من شريط الحالة
      body: SafeArea(
        // قائمة قابلة للتمرير حتى لا يصير قص عند صغر الشاشة أو عند ظهور لوحة المفاتيح
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          children: [
            const SizedBox(height: 8),

            // أيقونة داخل دائرة للتصميم
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

            // عنوان توضيحي
            const Center(
              child: Text(
                'Driver Access',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),

            const SizedBox(height: 6),

            // وصف بسيط تحت العنوان
            const Center(
              child: Text(
                'Sign in to start tracking',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),

            const SizedBox(height: 18),

            // عنوان حقل البريد
            const Text(
              'Email',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            // حقل إدخال البريد
            _InputField(
              controller: emailController,
              hintText: '',
              prefixIcon: Icons.email_outlined,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 14),

            // عنوان حقل كلمة المرور
            const Text(
              'Password',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            // حقل إدخال كلمة المرور
            _InputField(
              controller: passwordController,
              hintText: '   ',
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

            // إذا في خطأ نظهره هنا
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

            // زر الدخول
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

// هذا عنصر إدخال موحد لتقليل تكرار تصميم حقول النص
class _InputField extends StatelessWidget {
  // المتحكم المرتبط بحقل الإدخال
  final TextEditingController controller;

  // النص الإرشادي داخل الحقل
  final String hintText;

  // الأيقونة التي تظهر في بداية الحقل
  final IconData prefixIcon;

  // هل يتم إخفاء النص أم لا
  final bool obscureText;

  // عنصر اختياري يظهر في نهاية الحقل مثل زر إظهار كلمة المرور
  final Widget? suffixIcon;

  // دالة اختيارية تنفذ عند تغيير النص داخل الحقل
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
      // ربط الحقل بالمتحكم
      controller: controller,

      // تطبيق الإخفاء إذا كان مطلوب
      obscureText: obscureText,

      // تمرير التغيير للدالة القادمة من الصفحة الرئيسية
      onChanged: onChanged,

      decoration: InputDecoration(
        hintText: hintText,

        // أيقونة بداية الحقل
        prefixIcon: Icon(prefixIcon, color: Colors.black45),

        // عنصر نهاية الحقل (إن وجد)
        suffixIcon: suffixIcon,

        // جعل الخلفية بيضاء
        filled: true,
        fillColor: Colors.white,

        // مسافات داخلية للحقل
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),

        // شكل الحقل قبل التركيز
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.cardBorder),
        ),

        // شكل الحقل عند التركيز
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.4),
        ),
      ),
    );
  }
}
