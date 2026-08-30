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

  // Рассчитать маршрут (одиночный)
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

  // Рассчитать маршрут по нескольким точкам
  static Future<Map<String, dynamic>> calculateMultiRoute({
    required List<String> points,
    String city = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/route_multi'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'points': points,
        'city': city,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Ошибка расчёта маршрута: ${response.statusCode}');
    }
  }

  // Геокодирование адреса
  static Future<Map<String, dynamic>> geocodeAddress(String address, {String? city}) async {
    final uri = Uri.parse('$baseUrl/geocode').replace(queryParameters: {
      'address': address,
      if (city != null && city.isNotEmpty) 'city': city,
    });
    final response = await http.post(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Ошибка геокодирования: ${response.statusCode}');
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

  // Проверка пароля администратора
  static Future<bool> adminLogin(String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/login?password=$password'),
    );
    return response.statusCode == 200;
  }

  // Получить список пользователей для админки
  static Future<List<Map<String, dynamic>>> adminUsers(String password) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users?password=$password'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('Ошибка доступа: ${response.statusCode}');
    }
  }

  // Удалить поездку по ID
  static Future<bool> adminDeleteTrip(int tripId, String password) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/trip/$tripId?password=$password'),
    );
    return response.statusCode == 200;
  }

  // Получить user_id по нику Telegram
  static Future<int?> resolveUsername(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/resolve_username?username=${Uri.encodeComponent(username)}'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['user_id'] as int?;
    } else {
      return null;
    }
  }
}