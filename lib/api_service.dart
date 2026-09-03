import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/trip.dart';

class ApiService {
  static const String baseUrl = 'http://31.130.128.105:8888';

  static Future<List<Trip>> getTrips(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/trips/$userId'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Trip.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('шибка загрузки поездок: ');
    }
  }

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
      throw Exception('шибка расчёта маршрута: ');
    }
  }

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
      throw Exception('шибка расчёта маршрута: ');
    }
  }

  static Future<Map<String, dynamic>> geocodeAddress(String address, {String? city}) async {
    final uri = Uri.parse('$baseUrl/geocode').replace(queryParameters: {
      'address': address,
      if (city != null && city.isNotEmpty) 'city': city,
    });
    final response = await http.post(uri);
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('шибка геокодирования: ');
    }
  }

  static Future<String?> reverseGeocode(double lat, double lon) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reverse_geocode?lat=$lat&lon=$lon'),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['address'] as String?;
    } else {
      return null;
    }
  }

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
    List<String> waypointCoords = const [],
    List<String> waypointLabels = const [],
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
        'waypoint_coords': waypointCoords,
        'waypoint_labels': waypointLabels,
        'username': username,
      }),
    );
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('шибка сохранения поездки: ');
    }
  }

  static Future<Map<String, dynamic>> getStats(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/stats/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('шибка загрузки статистики: ');
    }
  }

  static Future<bool> adminLogin(String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/login?password=$password'),
    );
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> adminUsers(String password) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users?password='),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else {
      throw Exception('шибка доступа: ');
    }
  }

  static Future<bool> adminDeleteTrip(int tripId, String password) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/trip/='),
    );
    return response.statusCode == 200;
  }

  static Future<int?> resolveUsername(String username) async {
    final response = await http.get(
      Uri.parse('$baseUrl/resolve_username?username='),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['user_id'] as int?;
    } else {
      return null;
    }
  }

  static Future<String?> getUserPhotoUrl(int userId, String password) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/user_photo?user_id=&password='),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['photo_url'] as String?;
    }
    return null;
  }
}

