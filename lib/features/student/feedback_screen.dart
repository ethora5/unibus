import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../app/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController controller = TextEditingController();

  final List<String> complaintTypes = const [
    'Bus Delay',
    'Driver Behavior',
    'Crowded Bus',
    'Bus Condition',
    'Other',
  ];

  String? selectedType;
  bool _isSubmitting = false;

  // ✅ بدل setState لكل حرف
  final ValueNotifier<int> _charCount = ValueNotifier<int>(0);
  final ValueNotifier<bool> _canSubmit = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    controller.addListener(_recompute);
    _recompute();
  }

  void _recompute() {
    final text = controller.text.trim();
    _charCount.value = controller.text.length;
    _canSubmit.value =
        (selectedType != null) && text.isNotEmpty && !_isSubmitting;
  }

  @override
  void dispose() {
    controller.removeListener(_recompute);
    controller.dispose();
    _charCount.dispose();
    _canSubmit.dispose();
    super.dispose();
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitToFirestore() async {
    if (!_canSubmit.value) return;

    setState(() => _isSubmitting = true);
    _recompute();

    try {
      await FirebaseFirestore.instance.collection('feedbacks').add({
        'type': selectedType,
        'message': controller.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'studentId': 'anonymous',
        'busSessionId': null,
        'routeName': null,
      });

      await _showMessageDialog(title: 'Success', message: 'Sent successfully');

      setState(() => selectedType = null);
      controller.clear();
      _recompute();
    } catch (_) {
      await _showMessageDialog(
        title: 'Error',
        message: 'An error occurred. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _recompute();
      }
    }
  }

  Future<void> _openTypePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: ListView(
          children: complaintTypes
              .map(
                (t) => ListTile(
                  title: Text(t),
                  onTap: () => Navigator.pop(context, t),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected != null) {
      setState(() => selectedType = selected);
      _recompute();
    }
  }

  @override
  Widget build(BuildContext context) {
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

            InkWell(
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
                    Expanded(
                      child: Text(
                        selectedType ?? 'Select type...',
                        style: TextStyle(
                          color: selectedType == null
                              ? Colors.black54
                              : Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            const Text(
              'Write Your Complaint / Feedback',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
            const SizedBox(height: 8),

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
                // ✅ لا onChanged => setState
              ),
            ),

            const SizedBox(height: 6),
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

            SizedBox(
              height: 48,
              child: ValueListenableBuilder<bool>(
                valueListenable: _canSubmit,
                builder: (_, canSubmit, __) => ElevatedButton.icon(
                  onPressed: (canSubmit && !_isSubmitting)
                      ? _submitToFirestore
                      : null,
                  icon: const Icon(Icons.send_outlined, size: 18),
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
