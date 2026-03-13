import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class DriverLocationFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateDriverBusLocation({
    required String sessionId,
    required String driverName,
    required String busId,
    required String routeName,
    required Position position,
    required bool isActive,
  }) async {
    await _firestore.collection('active_buses').doc(sessionId).set({
      'sessionId': sessionId,
      'driverName': driverName,
      'busId': busId,
      'routeName': routeName,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'speed': position.speed,
      'heading': position.heading,
      'timestamp': FieldValue.serverTimestamp(),
      'isActive': isActive,
    }, SetOptions(merge: true));
  }

  Future<void> endSession({required String sessionId}) async {
    await _firestore.collection('active_buses').doc(sessionId).set({
      'isActive': false,
      'endedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
