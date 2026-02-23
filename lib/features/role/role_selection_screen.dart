import 'package:flutter/material.dart';
import '../../app/app_routes.dart';
import '../../app/app_theme.dart';

// هذي صفحة اختيار الرول
// المستخدم يختار هل هو طالب او سايق او ادمن
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // هذا الهيكل الاساسي للصفحة
    return Scaffold(
      // هذا يمنع المحتوى يدخل تحت شريط الحالة
      body: SafeArea(
        child: Center(
          // هذا يحدد اقصى عرض للصفحة عشان الشكل يطلع مرتب بالشاشات الكبيرة
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              // مسافة من اليمين واليسار
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                // يخلي العناصر بالنص عمودي
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // مسافة فوق
                  const SizedBox(height: 12),

                  // عنوان الصفحة
                  const Text(
                    'Select Your Role',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),

                  // مسافة بين العنوان والازرار
                  const SizedBox(height: 22),

                  // زر الطالب يوديه لواجهة الطالب
                  _RoleButton(
                    label: 'Student',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.studentHome);
                    },
                  ),

                  const SizedBox(height: 14),

                  // زر السايق يوديه لتسجيل دخول السايق
                  _RoleButton(
                    label: 'Driver',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.driverLogin);
                    },
                  ),

                  const SizedBox(height: 14),

                  // زر الادمن يوديه لتسجيل دخول الادمن
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
          ),
        ),
      ),
    );
  }
}

// هذا ويدجت زر نستخدمه لكل الرولات
class _RoleButton extends StatelessWidget {
  // النص اللي يطلع داخل الزر
  final String label;

  // الدالة اللي تشتغل اذا ضغطنا الزر
  final VoidCallback onTap;

  const _RoleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // يعطي تأثير بسيط لما نضغط
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        // ارتفاع ثابت للزر
        height: 52,

        // ياخذ عرض الصفحة كامل
        width: double.infinity,

        // شكل الزر
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),

          // حدود الزر
          border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        ),

        // نخلي النص بالنص بالضبط
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
