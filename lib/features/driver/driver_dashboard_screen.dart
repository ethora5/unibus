import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';
import 'driver_schedule_screen.dart';

// هذه شاشة لوحة تحكم السائق
// الهدف منها:
// 1) إدخال اسم السائق
// 2) عرض المسار الثابت وإتاحة فتح صورة الجدول
// 3) اختيار الحافلة من قائمة جاهزة
// 4) تفعيل زر البدء فقط عند اكتمال البيانات
// 5) عند البدء يتم الانتقال لصفحة التتبع مع تمرير بيانات السائق والحافلة والمسار
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  // متحكم حقل النص الخاص باسم السائق
  // نستخدمه لقراءة الاسم المكتوب والتحقق منه
  final TextEditingController nameController = TextEditingController();

  // هذا يخزن الحافلة التي اختارها السائق
  // إذا كانت فارغة يعني السائق لم يحدد حافلة بعد
  String? selectedBus;

  // اسم المسار ثابت ومحدد مسبقًا
  // تم جعله ثابت لأن النظام حالياً يستخدم مسار واحد فقط
  static const String routeName = 'UNITEN Internal Shuttle Bus';

  // قائمة الحافلات المعروضة للسائق (قائمة تجريبية)
  // كل عنصر فيها يحتوي معرف الحافلة وحالتها
  final List<_BusItem> buses = const [
    _BusItem(id: 'Bus A', status: 'Available'),
    _BusItem(id: 'Bus B', status: 'Available'),
    _BusItem(id: 'Bus C', status: 'In Use'),
    _BusItem(id: 'Bus D', status: 'Available'),
    _BusItem(id: 'Bus E', status: 'Maintenance'),
  ];

  @override
  void initState() {
    super.initState();

    // نضيف مستمع لحقل الاسم
    // الهدف: تحديث الواجهة مباشرة إذا تغير النص حتى يتفعل/يتعطل زر البدء
    nameController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    // إغلاق المتحكم لتجنب تسريب الذاكرة
    nameController.dispose();
    super.dispose();
  }

  // هذا شرط تفعيل زر البدء
  // لازم الاسم يكون غير فارغ بعد إزالة الفراغات
  // ولازم السائق يكون مختار حافلة
  bool get canStart =>
      nameController.text.trim().isNotEmpty && selectedBus != null;

  // هذه الدالة تفتح صفحة جدول السائق داخل التطبيق
  // حالياً الجدول موجود كصورة في صفحة منفصلة
  void _openScheduleImage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DriverScheduleScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // عنوان الصفحة
        title: const Text('Driver Dashboard'),

        // زر الرجوع هنا يرجع المستخدم لصفحة اختيار الدور ويمنع الرجوع للخلف مرة ثانية
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.roleSelection,
            (_) => false,
          ),
        ),
      ),

      // حماية المحتوى من شريط الحالة
      body: SafeArea(
        child: ListView(
          // مسافات داخلية للصفحة
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          children: [
            const SizedBox(height: 8),

            // أيقونة رئيسية في أعلى الصفحة
            Center(
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FF),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.navigation_outlined,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // عنوان ترحيبي
            const Center(
              child: Text(
                'Welcome',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),

            const SizedBox(height: 6),

            // وصف بسيط لتوضيح المطلوب من السائق
            const Center(
              child: Text(
                'Select your bus to start tracking',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),

            const SizedBox(height: 18),

            // عنوان حقل اسم السائق
            const Text(
              'Driver Name',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            // حقل إدخال اسم السائق
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Enter driver name',
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

            // عنوان قسم المسار
            const Text(
              'Route',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 8),

            // بطاقة تعرض اسم المسار الثابت مع زر لعرض الجدول
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.alt_route,
                    color: AppTheme.primaryBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 10),

                  // نص المسار يأخذ المساحة المتبقية
                  Expanded(
                    child: Text(
                      routeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),

                  // زر يفتح صفحة جدول السائق
                  TextButton(
                    onPressed: _openScheduleImage,
                    child: const Text('View Schedule'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // عنوان قسم اختيار الحافلة
            const Text(
              'Select Bus',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 10),

            // توليد عناصر قائمة الحافلات من القائمة الثابتة
            ...buses.map((b) {
              // نحدد هل هذه الحافلة هي المختارة حالياً
              final bool isSelected = selectedBus == b.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),

                // عنصر واحد يمثل حافلة واحدة قابلة للاختيار
                child: _BusTile(
                  bus: b,
                  selected: isSelected,

                  // عند الضغط نخزن معرف الحافلة المختارة
                  onTap: () => setState(() => selectedBus = b.id),
                ),
              );
            }),

            const SizedBox(height: 18),

            // زر البدء في التتبع
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                // إذا لم تتحقق الشروط يكون الزر غير مفعل
                onPressed: canStart
                    ? () {
                        // عند البدء ننتقل لصفحة التتبع النشط
                        // ونمرر اسم السائق ومعرف الحافلة واسم المسار
                        Navigator.pushNamed(
                          context,
                          AppRoutes.driverTrackingActive,
                          arguments: {
                            'driverName': nameController.text.trim(),
                            'busId': selectedBus,
                            'routeName': routeName,
                          },
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Tracking'),
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
          ],
        ),
      ),
    );
  }
}

// هذا نموذج بيانات بسيط يمثل الحافلة
// يحتوي معرف الحافلة وحالتها الحالية
class _BusItem {
  final String id;
  final String status;

  const _BusItem({required this.id, required this.status});
}

// هذا عنصر واجهة يمثل بطاقة اختيار حافلة واحدة
// عند الضغط عليها يتم اختيارها وتغيير شكلها لتوضيح أنها مختارة
class _BusTile extends StatelessWidget {
  final _BusItem bus;
  final bool selected;
  final VoidCallback onTap;

  const _BusTile({
    required this.bus,
    required this.selected,
    required this.onTap,
  });

  // هذه الدالة ترجع لون مناسب حسب حالة الحافلة
  // الهدف: توصيل معنى الحالة للمستخدم بصريًا
  Color _statusColor(String status) {
    switch (status) {
      case 'Available':
        return const Color(0xFF1F9D55);
      case 'In Use':
        return const Color(0xFF6B7280);
      case 'Maintenance':
        return const Color(0xFFF59E0B);
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    // نحدد لون الحالة بناءً على النص الموجود في بيانات الحافلة
    final Color statusColor = _statusColor(bus.status);

    return InkWell(
      // عند الضغط يتم تنفيذ الدالة القادمة من الشاشة الرئيسية
      onTap: onTap,

      // يحدد انحناء الحواف لتتطابق مع شكل البطاقة
      borderRadius: BorderRadius.circular(14),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),

        // تصميم البطاقة: لون، حدود، ظل
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),

          // إذا كانت مختارة نغير لون وسمك الحد للتأكيد
          border: Border.all(
            color: selected ? AppTheme.primaryBlue : AppTheme.cardBorder,
            width: selected ? 1.4 : 1.0,
          ),

          // ظل بسيط لعمق بصري
          boxShadow: const [
            BoxShadow(
              blurRadius: 10,
              offset: Offset(0, 5),
              color: Color(0x0F000000),
            ),
          ],
        ),

        child: Row(
          children: [
            // أيقونة توضح هل البطاقة مختارة أم لا
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppTheme.primaryBlue : Colors.black26,
              size: 18,
            ),

            const SizedBox(width: 10),

            // أيقونة الحافلة
            const Icon(
              Icons.directions_bus,
              color: AppTheme.primaryBlue,
              size: 18,
            ),

            const SizedBox(width: 8),

            // اسم الحافلة يأخذ المساحة المتبقية
            Expanded(
              child: Text(
                bus.id,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),

            // حالة الحافلة مع لون مناسب
            Text(
              bus.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
