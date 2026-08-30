import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActiveTripStorage {
  static const String _keyPoints = 'active_trip_points';
  static const String _keyPauseSeconds = 'active_trip_pause_seconds';
  static const String _keyIsPaused = 'active_trip_is_paused';
  static const String _keyPauseStartMillis = 'active_trip_pause_start_millis';

  // Сохранить состояние активной поездки
  static Future<void> saveActiveTrip({
    required List<String> points,
    required int pauseSeconds,
    required bool isPaused,
    DateTime? pauseStartTime,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPoints, jsonEncode(points));
    await prefs.setInt(_keyPauseSeconds, pauseSeconds);
    await prefs.setBool(_keyIsPaused, isPaused);
    if (pauseStartTime != null) {
      await prefs.setInt(_keyPauseStartMillis, pauseStartTime.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyPauseStartMillis);
    }
  }

  // Загрузить состояние активной поездки
  static Future<Map<String, dynamic>?> loadActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final pointsJson = prefs.getString(_keyPoints);
    if (pointsJson == null) return null;
    final points = List<String>.from(jsonDecode(pointsJson));
    final pauseSeconds = prefs.getInt(_keyPauseSeconds) ?? 0;
    final isPaused = prefs.getBool(_keyIsPaused) ?? false;
    final pauseStartMillis = prefs.getInt(_keyPauseStartMillis);
    DateTime? pauseStartTime;
    if (pauseStartMillis != null) {
      pauseStartTime = DateTime.fromMillisecondsSinceEpoch(pauseStartMillis);
    }
    return {
      'points': points,
      'pauseSeconds': pauseSeconds,
      'isPaused': isPaused,
      'pauseStartTime': pauseStartTime,
    };
  }

  // Очистить сохранённое состояние (после завершения или отмены)
  static Future<void> clearActiveTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPoints);
    await prefs.remove(_keyPauseSeconds);
    await prefs.remove(_keyIsPaused);
    await prefs.remove(_keyPauseStartMillis);
  }
}