import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationEventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createNewBusTrackingEvent({
    required String sessionId,
    required String busName,
    required String routeName,
  }) async {
    await _firestore.collection('notification_events').add({
      'type': 'new_bus_tracking',
      'sessionId': sessionId,
      'busName': busName,
      'routeName': routeName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
