import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';

// هذه شاشة تسجيل دخول الأدمن
// الهدف منها:
// 1) إدخال البريد وكلمة المرور
// 2) تفعيل زر الدخول فقط عند إدخال القيم المطلوبة
// 3) توفير خيار إظهار/إخفاء كلمة المرور
// 4) حالياً يتم الانتقال مباشرة لصفحة مركز الملاحظات عند الضغط (بدون تحقق فعلي)
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  // متحكم حقل البريد الإلكتروني
  final TextEditingController emailController = TextEditingController();

  // متحكم حقل كلمة المرور
  final TextEditingController passwordController = TextEditingController();

  // يتحكم في إظهار أو إخفاء كلمة المرور
  bool obscurePassword = true;

  @override
  void dispose() {
    // إغلاق المتحكمات عند الخروج من الصفحة لتجنب تسريب الذاكرة
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // شرط تفعيل زر الدخول
    // البريد لا يكون فاضي بعد إزالة الفراغات
    // وكلمة المرور لا تكون فاضية
    final bool canSignIn =
        emailController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        // عنوان الصفحة
        title: const Text('Admin Login'),

        // زر رجوع للصفحة السابقة
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // حماية المحتوى من شريط الحالة
      body: SafeArea(
        // استخدام قائمة قابلة للتمرير لتجنب قص المحتوى عند صغر الشاشة أو ظهور لوحة المفاتيح
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          children: [
            const SizedBox(height: 8),

            // أيقونة أعلى الصفحة داخل دائرة للتصميم
            Center(
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // عنوان توضيحي للأدمن
            const Center(
              child: Text(
                'Admin Access',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
              ),
            ),

            const SizedBox(height: 6),

            // هذا عنصر فارغ في الكود الحالي ولا يضيف أي شيء للواجهة
            // يمكن حذفه بدون أن يتأثر التصميم
            const Center(),

            const SizedBox(height: 18),

            // عنوان حقل البريد
            const Text(
              'Email',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            // حقل إدخال البريد
            // عند تغيير النص نعيد بناء الصفحة لتحديث حالة زر الدخول
            TextField(
              controller: emailController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Colors.black45,
                ),
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
            ),

            const SizedBox(height: 14),

            // عنوان حقل كلمة المرور
            const Text(
              'Password',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            // حقل إدخال كلمة المرور
            // يحتوي على زر جانبي لتبديل الإخفاء والإظهار
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '',
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Colors.black45,
                ),

                // زر تبديل الإخفاء والإظهار
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
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
            ),

            const SizedBox(height: 16),

            // زر الدخول
            // يكون غير مفعل إذا لم تتحقق شروط الإدخال
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: canSignIn
                    ? () {
                        // حالياً يتم الانتقال مباشرة لصفحة مركز الملاحظات
                        // لاحقاً يتم ربطه بتسجيل دخول فعلي والتحقق من الحساب
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.feedbackCenter,
                        );
                      }
                    : null,
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Sign In'),
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
