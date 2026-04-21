import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverActiveSessionService {
  static const String _keyIsTracking = 'driver_is_tracking';
  static const String _keySessionId = 'driver_active_session_id';
  static const String _keyBusDocId = 'driver_active_bus_doc_id';
  static const String _keyBusId = 'driver_active_bus_id';
  static const String _keyRouteName = 'driver_active_route_name';
  static const String _keyDriverName = 'driver_active_driver_name';
  static const String _keyDriverEmail = 'driver_active_driver_email';
  static const String _keyStartSeconds = 'driver_active_start_seconds';

  static Future<void> saveActiveSession({
    required String sessionId,
    required String busDocId,
    required String busId,
    required String routeName,
    required String driverName,
    required String driverEmail,
    required int startSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyIsTracking, true);
    await prefs.setString(_keySessionId, sessionId);
    await prefs.setString(_keyBusDocId, busDocId);
    await prefs.setString(_keyBusId, busId);
    await prefs.setString(_keyRouteName, routeName);
    await prefs.setString(_keyDriverName, driverName);
    await prefs.setString(_keyDriverEmail, driverEmail);
    await prefs.setInt(_keyStartSeconds, startSeconds);
  }

  static Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyIsTracking);
    await prefs.remove(_keySessionId);
    await prefs.remove(_keyBusDocId);
    await prefs.remove(_keyBusId);
    await prefs.remove(_keyRouteName);
    await prefs.remove(_keyDriverName);
    await prefs.remove(_keyDriverEmail);
    await prefs.remove(_keyStartSeconds);
  }

  static Future<Map<String, dynamic>?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isTracking = prefs.getBool(_keyIsTracking) ?? false;

    if (!isTracking) return null;

    final sessionId = prefs.getString(_keySessionId);
    final busDocId = prefs.getString(_keyBusDocId);
    final busId = prefs.getString(_keyBusId);
    final routeName = prefs.getString(_keyRouteName);
    final driverName = prefs.getString(_keyDriverName);
    final driverEmail = prefs.getString(_keyDriverEmail);
    final startSeconds = prefs.getInt(_keyStartSeconds);

    if (sessionId == null ||
        busDocId == null ||
        busId == null ||
        routeName == null ||
        driverName == null ||
        driverEmail == null ||
        startSeconds == null) {
      return null;
    }

    return {
      'sessionId': sessionId,
      'busDocId': busDocId,
      'busId': busId,
      'routeName': routeName,
      'driverName': driverName,
      'driverEmail': driverEmail,
      'startSeconds': startSeconds,
    };
  }

  static Future<Map<String, dynamic>?> getValidActiveSessionForDriver({
    required String driverEmail,
  }) async {
    final saved = await getSavedSession();

    if (saved == null) return null;

    final savedEmail = (saved['driverEmail'] as String).trim().toLowerCase();
    final currentEmail = driverEmail.trim().toLowerCase();

    if (savedEmail != currentEmail) {
      return null;
    }

    final String sessionId = saved['sessionId'] as String;

    final doc = await FirebaseFirestore.instance
        .collection('driving_sessions')
        .doc(sessionId)
        .get();

    if (!doc.exists) {
      await clearActiveSession();
      return null;
    }

    final data = doc.data()!;
    final String status =
        (data['status'] as String?)?.trim().toLowerCase() ?? '';

    if (status != 'active') {
      await clearActiveSession();
      return null;
    }

    return saved;
  }
}
