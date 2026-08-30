import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/trip.dart';

class ApiService {
  static const String baseUrl = 'http://31.130.128.105:8888';

  // Получить список поездок пользователя
  static Future<List<Trip>> getTrips(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/trips/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Trip.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Ошибка загрузки поездок: ${response.statusCode}');
    }
  }

  // Рассчитать маршрут
  static Future<Map<String, dynamic>> calculateRoute({
    required String origin,
    required String destination,
    required String city,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/route'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'origin': origin,
        'destination': destination,
        'city': city,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Ошибка расчёта маршрута: ${response.statusCode}');
    }
  }

  // Сохранить поездку
  static Future<bool> saveTrip({
    required int userId,
    required String city,
    required String startPoint,
    required String endPoint,
    required double totalKm,
    required int totalDurationSec,
    int totalPauseSec = 0,
    double totalCost = 0.0,
    List<String> points = const [],
    String? username,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/save_trip'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'city': city,
        'start_point': startPoint,
        'end_point': endPoint,
        'total_km': totalKm,
        'total_duration_sec': totalDurationSec,
        'total_pause_sec': totalPauseSec,
        'total_cost': totalCost,
        'points': points,
        'username': username,
      }),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Ошибка сохранения поездки: ${response.statusCode}');
    }
  }

  // Получить статистику по пользователю
  static Future<Map<String, dynamic>> getStats(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/stats/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Ошибка загрузки статистики: ${response.statusCode}');
    }
  }
}