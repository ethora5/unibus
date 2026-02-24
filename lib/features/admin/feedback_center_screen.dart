import 'package:flutter/material.dart';
import '../../../app/app_routes.dart';
import '../../../app/app_theme.dart';

// هذه شاشة مركز الشكاوى والملاحظات للأدمن
// الهدف منها:
// 1) عرض قسم فلاتر قابل للفتح والإغلاق
// 2) السماح بتصفية النتائج حسب التاريخ والحافلة والسائق
// 3) (حالياً) تجهيز واجهة الفلاتر فقط بدون قائمة نتائج
class FeedbackCenterScreen extends StatefulWidget {
  const FeedbackCenterScreen({super.key});

  @override
  State<FeedbackCenterScreen> createState() => _FeedbackCenterScreenState();
}

class _FeedbackCenterScreenState extends State<FeedbackCenterScreen> {
  // هذا المتغير يتحكم في إظهار أو إخفاء قسم الفلاتر
  bool filtersExpanded = false;

  // هذا يخزن التاريخ الذي اختاره المستخدم كفلتر
  DateTime? selectedDate;

  // هذا يخزن الحافلة المختارة كفلتر
  String? selectedBus;

  // هذا يخزن اسم السائق المختار كفلتر
  String? selectedDriver;

  // قائمة الحافلات المتاحة للاختيار في الفلتر
  final List<String> buses = const [
    'Bus A',
    'Bus B',
    'Bus C',
    'Bus D',
    'Bus E',
  ];

  // قائمة السائقين المتاحة للاختيار في الفلتر (بيانات تجريبية)
  final List<String> drivers = const ['Driver 1', 'Driver 2', 'Driver 3'];

  // هذه الدالة تفتح نافذة اختيار التاريخ
  // وبعد الاختيار نحفظ التاريخ في المتغير ونحدث الواجهة
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,

      // إذا المستخدم سبق واختار تاريخ نبدأ منه، وإلا نبدأ بتاريخ اليوم
      initialDate: selectedDate ?? DateTime.now(),

      // أقل تاريخ مسموح اختياره
      firstDate: DateTime(2024),

      // أعلى تاريخ مسموح اختياره
      lastDate: DateTime(2030),
    );

    // إذا المستخدم اختار تاريخ فعلاً (ولم يغلق النافذة بدون اختيار)
    // نخزن التاريخ ونحدث الواجهة
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  // هذا يحول التاريخ المختار إلى نص جاهز للعرض داخل الواجهة
  // إذا لا يوجد تاريخ مختار نعرض نص افتراضي
  String get formattedDate {
    if (selectedDate == null) return 'Select Date';

    // تنسيق التاريخ بصيغة سنة-شهر-يوم مع ضمان رقمين للشهر واليوم
    return "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // عنوان الصفحة
        title: const Text('Feedback & Complaints Center'),

        // زر رجوع يرجع لصفحة اختيار الدور ويمنع الرجوع للخلف مرة ثانية
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
        // استخدام قائمة قابلة للتمرير حتى لو كبرت عناصر الفلاتر
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            const SizedBox(height: 12),

            // هذا هو رأس قسم الفلاتر
            // عند الضغط يفتح أو يقفل الفلاتر
            InkWell(
              onTap: () => setState(() => filtersExpanded = !filtersExpanded),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 18, color: Colors.black54),
                    const SizedBox(width: 10),

                    // عنوان "Filters" يأخذ المساحة المتبقية
                    const Expanded(
                      child: Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    // أيقونة تتغير حسب حالة الفتح أو الإغلاق
                    Icon(
                      filtersExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            ),

            // إذا الفلاتر مفتوحة نعرض عناصر الفلاتر الثلاثة تحت الرأس
            if (filtersExpanded) ...[
              const SizedBox(height: 12),

              // عنصر اختيار التاريخ
              // نستخدم عنصر يلتقط اللمس لفتح نافذة اختيار التاريخ
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 10),

                      // عرض التاريخ المختار أو النص الافتراضي
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // قائمة اختيار الحافلة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),

                // هذا يخفي الخط السفلي الافتراضي للقائمة المنسدلة
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    // القيمة الحالية المختارة
                    value: selectedBus,

                    // نص افتراضي يظهر إذا لم يتم اختيار حافلة
                    hint: const Text(
                      'Select Bus',
                      style: TextStyle(fontSize: 12),
                    ),

                    // يجعل القائمة تتمدد بعرض الحاوية
                    isExpanded: true,

                    // تحويل قائمة الحافلات إلى عناصر قابلة للاختيار
                    items: buses
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),

                    // عند تغيير الاختيار نخزن القيمة ونحدث الواجهة
                    onChanged: (v) => setState(() => selectedBus = v),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // قائمة اختيار السائق
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedDriver,
                    hint: const Text(
                      'Select Driver',
                      style: TextStyle(fontSize: 12),
                    ),
                    isExpanded: true,
                    items: drivers
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedDriver = v),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
