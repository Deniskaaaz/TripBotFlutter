import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  static const String _keyUserId = 'user_id';

  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId) ?? 1;
  }

  static Future<void> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }
}