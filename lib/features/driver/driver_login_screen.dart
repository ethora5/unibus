import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';

// هذه شاشة تسجيل دخول السائق
// الهدف منها:
// 1) إدخال البريد
// 2) إدخال كلمة المرور مع خيار إظهار/إخفاء
// 3) تفعيل زر الدخول فقط عند إدخال القيم المطلوبة
// 4) حالياً عند نجاح الإدخال يتم الانتقال مباشرة للوحة السائق (بدون تحقق فعلي)
class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  // متحكم حقل البريد الإلكتروني
  // نستخدمه لقراءة النص ومعرفة هل الحقل فاضي أو لا
  final TextEditingController emailController = TextEditingController();

  // متحكم حقل كلمة المرور
  // نستخدمه لقراءة النص ومعرفة هل الحقل فاضي أو لا
  final TextEditingController passwordController = TextEditingController();

  // هذا المتغير يتحكم في إظهار أو إخفاء كلمة المرور
  // إذا كانت قيمته صحيحة يتم إخفاء النص
  bool obscurePassword = true;

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
    // لازم البريد بعد إزالة الفراغات يكون غير فاضي
    // ولازم كلمة المرور تكون غير فاضية
    final bool canSignIn =
        emailController.text.trim().isNotEmpty &&
        passwordController.text.isNotEmpty;

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
            // عند أي تغيير نعيد بناء الصفحة لتحديث حالة زر الدخول
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
            // يحتوي على زر جانبي للتبديل بين الإخفاء والإظهار
            _InputField(
              controller: passwordController,
              hintText: '   ',
              prefixIcon: Icons.lock_outline,

              // يطبق الإخفاء حسب قيمة المتغير
              obscureText: obscurePassword,

              // زر تبديل الإخفاء/الإظهار
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),

              // عند أي تغيير نعيد بناء الصفحة لتحديث حالة زر الدخول
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            // زر الدخول
            // يكون غير مفعل إذا لم تتحقق شروط الإدخال
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: canSignIn
                    ? () {
                        // حالياً يتم الانتقال للوحة السائق مباشرة
                        // لاحقاً يتم ربطه بتسجيل دخول فعلي والتحقق من البيانات
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.driverDashboard,
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

// هذا عنصر إدخال موحد لتقليل تكرار تصميم حقول النص
// نستخدمه للبريد وكلمة المرور بنفس الشكل مع اختلاف الأيقونات والخصائص
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
