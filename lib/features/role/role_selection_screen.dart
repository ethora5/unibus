import 'package:flutter/material.dart';
import '../../app/app_routes.dart';
import '../../app/app_theme.dart';

// هذه الصفحة مسؤولة عن اختيار نوع المستخدم قبل الدخول للتطبيق.
// المستخدم يحدد هل هو طالب أو سائق أو أدمن.
// بناءً على الاختيار يتم نقله إلى الصفحة المناسبة.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الهيكل الأساسي للصفحة.
    // يوفر لنا الخلفية العامة وتنظيم المحتوى.
    return Scaffold(
      // يمنع العناصر من الدخول تحت شريط الحالة أو الجزء العلوي للشاشة.
      body: SafeArea(
        // يجعل جميع محتويات الصفحة في المنتصف أفقيًا.
        child: Center(
          // يحدد أقصى عرض للواجهة حتى لا تتمدد العناصر في الشاشات الكبيرة.
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),

            // يضيف مسافة داخلية من اليمين واليسار لتحسين الشكل.
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),

              // يستخدم لترتيب العناصر فوق بعضها بشكل عمودي.
              child: Column(
                // يجعل العناصر في منتصف الشاشة عموديًا.
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // مسافة بسيطة في الأعلى لتحسين التوازن البصري.
                  const SizedBox(height: 12),

                  // عنوان الصفحة الذي يوضح للمستخدم ما المطلوب منه.
                  const Text(
                    'Select Your Role',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),

                  // مسافة بين العنوان والأزرار.
                  const SizedBox(height: 22),

                  // زر الطالب.
                  // عند الضغط يتم الانتقال إلى الصفحة الرئيسية الخاصة بالطالب.
                  _RoleButton(
                    label: 'Student',
                    onTap: () {
                      // تنفيذ عملية الانتقال باستخدام اسم المسار المحدد مسبقًا.
                      Navigator.pushNamed(context, AppRoutes.studentHome);
                    },
                  ),

                  const SizedBox(height: 14),

                  // زر السائق.
                  // ينقل المستخدم إلى صفحة تسجيل دخول السائق.
                  _RoleButton(
                    label: 'Driver',
                    onTap: () {
                      // الانتقال إلى صفحة تسجيل دخول السائق.
                      Navigator.pushNamed(context, AppRoutes.driverLogin);
                    },
                  ),

                  const SizedBox(height: 14),

                  // زر الأدمن.
                  // ينقل المستخدم إلى صفحة تسجيل دخول الأدمن.
                  _RoleButton(
                    label: 'Admin',
                    onTap: () {
                      // الانتقال إلى صفحة تسجيل دخول الأدمن.
                      Navigator.pushNamed(context, AppRoutes.adminLogin);
                    },
                  ),

                  // مسافة سفلية خفيفة لتحسين توزيع العناصر.
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

// هذا عنصر زر مخصص نستخدمه لتجنب تكرار نفس تصميم الزر.
// يتم تمرير النص والدالة الخاصة بالضغط لكل زر.
class _RoleButton extends StatelessWidget {
  // النص الذي يظهر داخل الزر.
  final String label;

  // الدالة التي يتم تنفيذها عند الضغط على الزر.
  final VoidCallback onTap;

  const _RoleButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // عنصر يعطي تأثير بصري عند الضغط على الزر.
    return InkWell(
      // عند الضغط يتم تنفيذ الدالة المرسلة.
      onTap: onTap,

      // يحدد انحناء الحواف لتتطابق مع شكل الزر.
      borderRadius: BorderRadius.circular(10),

      // يمثل جسم الزر الفعلي.
      child: Container(
        // ارتفاع ثابت للزر.
        height: 52,

        // يأخذ عرض المساحة المتاحة بالكامل.
        width: double.infinity,

        // خصائص تصميم الزر من لون وحدود وانحناء.
        decoration: BoxDecoration(
          // لون الخلفية أبيض.
          color: Colors.white,

          // انحناء الحواف.
          borderRadius: BorderRadius.circular(10),

          // رسم حدود للزر باستخدام لون من ملف التصميم العام.
          border: Border.all(color: AppTheme.cardBorder, width: 1.2),
        ),

        // يوسّط النص داخل الزر.
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
