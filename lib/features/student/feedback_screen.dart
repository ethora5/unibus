import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/app_theme.dart';

// هذه شاشة إرسال الملاحظات والشكاوى
// الهدف منها: الطالب يختار نوع الشكوى ثم يكتب رسالة، وبعدها يتم حفظها في قاعدة البيانات
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // هذا المتحكم بمربع النص، نستخدمه لقراءة النص المكتوب والتحكم فيه (تفريغه، مراقبته)
  final TextEditingController controller = TextEditingController();

  // هذه قائمة أنواع الشكاوى التي تظهر للمستخدم للاختيار
  final List<String> complaintTypes = const [
    'Bus Delay',
    'Driver Behavior',
    'Crowded Bus',
    'Bus Condition',
    'Other',
  ];

  // هذا يخزن النوع الذي اختاره المستخدم من القائمة
  String? selectedType;

  // هذا يدل هل نحن حاليًا في مرحلة الإرسال أم لا
  // إذا كان الإرسال شغال، نقفل التفاعل ونمنع ضغطات متعددة
  bool _isSubmitting = false;

  // هذا يحسب عدد الأحرف بدون ما نستخدم إعادة بناء الصفحة لكل حرف
  final ValueNotifier<int> _charCount = ValueNotifier<int>(0);

  // هذا يحدد هل زر الإرسال مسموح أم لا (حسب الشروط)
  final ValueNotifier<bool> _canSubmit = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();

    // نضيف مستمع على مربع النص
    // أي تغيير في النص يشغّل إعادة حساب الشروط والعداد
    controller.addListener(_recompute);

    // أول تشغيل نحسب الحالة حتى قبل ما يكتب المستخدم
    _recompute();
  }

  // هذه الدالة مسؤولة عن تحديث:
  // 1) عدد الأحرف
  // 2) هل زر الإرسال يشتغل أو لا بناءً على الشروط
  void _recompute() {
    // نأخذ النص ونشيل الفراغات من البداية والنهاية
    final text = controller.text.trim();

    // نحدث عدد الأحرف الحالي
    _charCount.value = controller.text.length;

    // شروط تفعيل زر الإرسال:
    // - لازم المستخدم يختار نوع
    // - لازم النص ما يكون فاضي
    // - لازم ما نكون في حالة إرسال
    _canSubmit.value =
        (selectedType != null) && text.isNotEmpty && !_isSubmitting;
  }

  @override
  void dispose() {
    // نشيل المستمع قبل الإغلاق لتجنب مشاكل وتسريب ذاكرة
    controller.removeListener(_recompute);

    // نغلق المتحكمات لتفريغ الموارد
    controller.dispose();
    _charCount.dispose();
    _canSubmit.dispose();

    super.dispose();
  }

  // هذه نافذة منبثقة لعرض رسالة للمستخدم (نجاح أو خطأ)
  // نستخدمها بدل الرسائل الصغيرة حتى تكون واضحة وتأكد للمستخدم أن العملية تمت
  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) async {
    // نتأكد أن الصفحة ما زالت موجودة قبل عرض نافذة
    if (!mounted) return;

    await showDialog<void>(
      context: context,

      // يمنع المستخدم من إغلاق النافذة بالضغط خارجها
      barrierDismissible: false,

      // بناء تصميم النافذة
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),

        // زر إغلاق النافذة
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // هذه الدالة ترسل البيانات إلى قاعدة البيانات
  Future<void> _submitToFirestore() async {
    // إذا ما تحقق شرط الإرسال، ما نسوي شيء
    if (!_canSubmit.value) return;

    // نفعّل حالة الإرسال حتى نقفل التفاعل
    setState(() => _isSubmitting = true);

    // نعيد حساب حالة الزر والعداد بعد تغيير حالة الإرسال
    _recompute();

    try {
      // نضيف سجل جديد داخل مجموعة الشكاوى
      await FirebaseFirestore.instance.collection('feedbacks').add({
        // نوع الشكوى الذي اختاره المستخدم
        'type': selectedType,

        // نص الرسالة بعد إزالة الفراغات الزائدة
        'message': controller.text.trim(),

        // وقت الإرسال من السيرفر لضمان وقت موحّد
        'createdAt': FieldValue.serverTimestamp(),

        // بما أن الطالب بدون تسجيل دخول، نخليه مجهول
        'studentId': 'anonymous',

        // حقول اختيارية للمستقبل لو ربطنا الشكوى بجلسة أو خط أو رحلة
        'busSessionId': null,
        'routeName': null,
      });

      // نعرض رسالة نجاح للمستخدم
      await _showMessageDialog(title: 'Success', message: 'Sent successfully');

      // نرجع الاختيار إلى لا شيء بعد الإرسال
      setState(() => selectedType = null);

      // نمسح النص المكتوب بعد الإرسال
      controller.clear();

      // نعيد حساب حالة الزر بعد التصفير
      _recompute();
    } catch (_) {
      // في حال صار خطأ (انترنت/صلاحيات/أي مشكلة)، نعرض رسالة خطأ
      await _showMessageDialog(
        title: 'Error',
        message: 'An error occurred. Please try again.',
      );
    } finally {
      // في كل الأحوال، نطفي حالة الإرسال ونرجع الواجهة لوضعها الطبيعي
      if (mounted) {
        setState(() => _isSubmitting = false);
        _recompute();
      }
    }
  }

  // هذه الدالة تفتح قائمة من الأسفل لاختيار نوع الشكوى
  Future<void> _openTypePicker() async {
    // نفتح نافذة سفلية ونعيد منها النص الذي اختاره المستخدم
    final selected = await showModalBottomSheet<String>(
      context: context,

      // يظهر مقبض سحب في أعلى القائمة لتحسين تجربة المستخدم
      showDragHandle: true,

      builder: (_) => SafeArea(
        // قائمة بأنواع الشكاوى
        child: ListView(
          children: complaintTypes
              .map(
                (t) => ListTile(
                  // عرض اسم النوع
                  title: Text(t),

                  // عند الضغط نغلق النافذة ونرجع القيمة المختارة
                  onTap: () => Navigator.pop(context, t),
                ),
              )
              .toList(),
        ),
      ),
    );

    // إذا المستخدم اختار نوع فعلاً، نخزنه
    if (selected != null) {
      setState(() => selectedType = selected);

      // نعيد حساب حالة زر الإرسال بعد اختيار النوع
      _recompute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // شريط أعلى الصفحة
      appBar: AppBar(
        title: const Text('Feedback & Complaints'),

        // زر رجوع يدوي
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // حماية المحتوى من شريط الحالة
      body: SafeArea(
        // قائمة قابلة للتمرير عشان ما يصير قص عند الشاشات الصغيرة أو مع الكيبورد
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          children: [
            const SizedBox(height: 6),

            // أيقونة توضيحية أعلى الصفحة
            const Center(
              child: Icon(
                Icons.chat_bubble_outline,
                size: 44,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 10),

            // عنوان توضيحي للمستخدم
            const Center(
              child: Text(
                'Share Your Feedback',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),

            const SizedBox(height: 6),

            // وصف بسيط تحت العنوان
            const Center(
              child: Text(
                'Help us improve our bus service',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),

            const SizedBox(height: 16),

            // عنوان قسم اختيار النوع
            const Text(
              'Complaint Type',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),

            const SizedBox(height: 8),

            // منطقة اختيار النوع (تفتح القائمة السفلية)
            InkWell(
              // إذا الإرسال شغال نمنع فتح القائمة
              onTap: _isSubmitting ? null : _openTypePicker,

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
                    // نمدد النص حتى يأخذ المساحة المتاحة
                    Expanded(
                      child: Text(
                        // إذا ما اختار المستخدم نوع نعرض نص افتراضي
                        selectedType ?? 'Select type...',
                        style: TextStyle(
                          // تغيير لون النص حسب إذا كان فيه اختيار أو لا
                          color: selectedType == null
                              ? Colors.black54
                              : Colors.black87,
                        ),
                      ),
                    ),

                    // سهم يدل أن فيه قائمة منسدلة
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // عنوان قسم كتابة الرسالة
            const Text(
              'Write Your Complaint / Feedback',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),

            const SizedBox(height: 8),

            // صندوق إدخال النص
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),

              child: TextField(
                // ربط مربع النص بالمتحكم
                controller: controller,

                // عدد الأسطر الظاهرة
                maxLines: 6,

                // الحد الأعلى لعدد الأحرف
                maxLength: 500,

                decoration: const InputDecoration(
                  // إزالة حدود الإدخال الداخلية لأننا عاملين حدود للحاوية
                  border: InputBorder.none,

                  // نص إرشادي داخل مربع النص
                  hintText:
                      'Write the details of your complaint\nor feedback here...',

                  // إخفاء العداد الافتراضي لأننا بنعرض عدادنا الخاص
                  counterText: '',
                ),
              ),
            ),

            const SizedBox(height: 6),

            // عرض عداد الأحرف باستخدام مراقب
            Align(
              alignment: Alignment.centerLeft,
              child: ValueListenableBuilder<int>(
                valueListenable: _charCount,
                builder: (_, count, __) => Text(
                  '$count/500 characters',
                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // زر الإرسال
            SizedBox(
              height: 48,
              child: ValueListenableBuilder<bool>(
                valueListenable: _canSubmit,
                builder: (_, canSubmit, __) => ElevatedButton.icon(
                  // تشغيل الإرسال فقط إذا الشروط متحققة وما فيه إرسال شغال
                  onPressed: (canSubmit && !_isSubmitting)
                      ? _submitToFirestore
                      : null,

                  icon: const Icon(Icons.send_outlined, size: 18),

                  // تغيير نص الزر حسب حالة الإرسال
                  label: Text(_isSubmitting ? 'Sending...' : 'Submit'),

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
            ),
          ],
        ),
      ),
    );
  }
}
