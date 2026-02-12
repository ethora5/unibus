import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController controller = TextEditingController();

  // ✅ قائمة أنواع الشكاوي مثل dropdown بالصورة
  final List<String> complaintTypes = const [
    'Bus Delay',
    'Driver Behavior',
    'Crowded Bus',
    'Bus Condition',
    'Other',
  ];

  String? selectedType;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  int get charCount => controller.text.length;

  @override
  Widget build(BuildContext context) {
    final bool canSubmit =
        (selectedType != null) && controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Complaints'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          children: [
            const SizedBox(height: 6),
            const Center(
              child: Icon(
                Icons.chat_bubble_outline,
                size: 44,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                'Share Your Feedback',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Help us improve our bus service',
                style: TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Complaint Type',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 8),

            // ✅ Dropdown بنفس الشكل العام
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedType,
                  hint: const Text('Select type...'),
                  isExpanded: true,
                  items: complaintTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => selectedType = v),
                ),
              ),
            ),

            const SizedBox(height: 14),
            const Text(
              'Write Your Complaint / Feedback',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 8),

            // ✅ Text area مثل الصورة
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: TextField(
                controller: controller,
                maxLines: 6,
                maxLength: 500,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      'Write the details of your complaint\nor feedback here...',
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$charCount/500 characters',
                style: const TextStyle(color: Colors.black45, fontSize: 11),
              ),
            ),
            const SizedBox(height: 14),

            // ✅ زر Submit رمادي إذا ما في بيانات (مثل الصورة تقريباً)
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: canSubmit
                    ? () {
                        // ✅ حالياً رسالة نجاح (لاحقاً تربطينه بفايرستور)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Submitted')),
                        );
                        setState(() {
                          selectedType = null;
                          controller.clear();
                        });
                      }
                    : null,
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Submit'),
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
