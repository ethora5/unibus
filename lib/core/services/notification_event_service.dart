import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationEventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> createNewBusTrackingEvent({
    required String sessionId,
    required String busName,
    required String routeName,
  }) async {
    final docId = '${sessionId}_new_bus_tracking';

    await _firestore.collection('notification_events').doc(docId).set({
      'type': 'new_bus_tracking',
      'sessionId': sessionId,
      'busName': busName,
      'routeName': routeName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createNextStopArrivalEvent({
    required String sessionId,
    required String busName,
    required String routeName,
    required String stopName,
    required int stopOrder,
  }) async {
    final docId = '${sessionId}_next_stop_arrival_$stopOrder';

    await _firestore.collection('notification_events').doc(docId).set({
      'type': 'next_stop_arrival',
      'sessionId': sessionId,
      'busName': busName,
      'routeName': routeName,
      'stopName': stopName,
      'stopOrder': stopOrder,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createBusApproachingEvent({
    required String sessionId,
    required String busName,
    required String routeName,
    required String stopName,
    required int stopOrder,
    required int etaMinutes,
  }) async {
    final docId = '${sessionId}_bus_approaching_$stopOrder';

    await _firestore.collection('notification_events').doc(docId).set({
      'type': 'bus_approaching',
      'sessionId': sessionId,
      'busName': busName,
      'routeName': routeName,
      'stopName': stopName,
      'stopOrder': stopOrder,
      'etaMinutes': etaMinutes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
