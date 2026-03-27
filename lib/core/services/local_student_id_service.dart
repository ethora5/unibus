import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class LocalStudentIdService {
  static const String _key = 'local_student_id';

  static Future<String> getOrCreateId() async {
    final prefs = await SharedPreferences.getInstance();
    final existingId = prefs.getString(_key);

    if (existingId != null && existingId.isNotEmpty) {
      return existingId;
    }

    final newId = const Uuid().v4();
    await prefs.setString(_key, newId);
    return newId;
  }
}
