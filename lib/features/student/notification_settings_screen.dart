import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../app/app_theme.dart';
import '../../core/services/local_student_id_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool busApproachingAlert = true;
  bool newBusTrackingAlert = true;
  bool nextStopArrivalAlert = true;

  bool isLoading = true;
  bool isSaving = false;

  String? _localStudentId;
  String? _fcmToken;

  DocumentReference<Map<String, dynamic>>? _settingsRef;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _localStudentId = await LocalStudentIdService.getOrCreateId();
      _fcmToken = await FirebaseMessaging.instance.getToken();

      _settingsRef = FirebaseFirestore.instance
          .collection('user_notification_settings')
          .doc(_localStudentId);

      await _loadOrCreateSettings();
    } catch (e) {
      debugPrint('Notification settings init error: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadOrCreateSettings() async {
    if (_settingsRef == null || _localStudentId == null) return;

    try {
      final doc = await _settingsRef!.get();

      if (doc.exists) {
        final data = doc.data()!;

        setState(() {
          busApproachingAlert = data['busApproachingAlert'] ?? true;
          newBusTrackingAlert = data['newBusTrackingAlert'] ?? true;
          nextStopArrivalAlert = data['nextStopArrivalAlert'] ?? true;
        });
      } else {
        await _settingsRef!.set({
          'studentLocalId': _localStudentId,
          'token': _fcmToken,
          'busApproachingAlert': true,
          'newBusTrackingAlert': true,
          'nextStopArrivalAlert': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          busApproachingAlert = true;
          newBusTrackingAlert = true;
          nextStopArrivalAlert = true;
        });
      }
    } catch (e) {
      debugPrint('Load notification settings failed: $e');
    }
  }

  Future<void> _saveSettings() async {
    if (_settingsRef == null || _localStudentId == null) return;

    setState(() => isSaving = true);

    try {
      _fcmToken = await FirebaseMessaging.instance.getToken();

      // نستخدم set بدون merge حتى نحذف أي حقول قديمة غير مرغوبة
      await _settingsRef!.set({
        'studentLocalId': _localStudentId,
        'token': _fcmToken,
        'busApproachingAlert': busApproachingAlert,
        'newBusTrackingAlert': newBusTrackingAlert,
        'nextStopArrivalAlert': nextStopArrivalAlert,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                children: [
                  const SizedBox(height: 8),
                  const Center(
                    child: Icon(
                      Icons.notifications_none,
                      size: 46,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'Choose Your Notifications',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Select the types of notifications you\nwant to receive',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _NotificationTile(
                    title: 'Bus Approaching Alert',
                    subtitle:
                        'Get notified when any bus is about\n1 minute away from a stop',
                    value: busApproachingAlert,
                    onChanged: (v) => setState(() => busApproachingAlert = v),
                  ),
                  const SizedBox(height: 12),
                  _NotificationTile(
                    title: 'New Bus Tracking Alert',
                    subtitle:
                        'Get notified whenever a new bus\nstarts tracking',
                    value: newBusTrackingAlert,
                    onChanged: (v) => setState(() => newBusTrackingAlert = v),
                  ),
                  const SizedBox(height: 12),
                  _NotificationTile(
                    title: 'Next Stop Arrival Alert',
                    subtitle:
                        'Get notified when the bus reaches\nthe next stop',
                    value: nextStopArrivalAlert,
                    onChanged: (v) => setState(() => nextStopArrivalAlert = v),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(isSaving ? 'Saving...' : 'Save'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
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
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppTheme.primaryBlue,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
