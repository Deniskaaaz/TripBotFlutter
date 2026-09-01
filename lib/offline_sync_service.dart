import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';

class OfflineSyncService {
  static const String _queueKey = 'offline_trip_queue';

  static Future<void> addTripToQueue(Map<String, dynamic> tripData) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_queueKey);
    final List<dynamic> queue = existing != null ? jsonDecode(existing) : [];
    queue.add(tripData);
    await prefs.setString(_queueKey, jsonEncode(queue));
  }

  static Future<int> syncPendingTrips() async {
    // Проверяем интернет перед попыткой отправки
    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult.any((r) => r != ConnectivityResult.none);
    if (!hasInternet) {
      return 0; // нет сети, ничего не делаем
    }

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_queueKey);
    if (existing == null) return 0;

    final List<dynamic> queue = jsonDecode(existing);
    if (queue.isEmpty) return 0;

    int synced = 0;
    final List<dynamic> newQueue = [];

    for (final item in queue) {
      final tripData = item as Map<String, dynamic>;
      try {
        final success = await ApiService.saveTrip(
          userId: tripData['user_id'] as int,
          city: tripData['city'] as String,
          startPoint: tripData['start_point'] as String,
          endPoint: tripData['end_point'] as String,
          totalKm: (tripData['total_km'] as num).toDouble(),
          totalDurationSec: tripData['total_duration_sec'] as int,
          totalPauseSec: tripData['total_pause_sec'] as int? ?? 0,
          totalCost: (tripData['total_cost'] as num?)?.toDouble() ?? 0.0,
          points: List<String>.from(tripData['points'] as List? ?? []),
          username: tripData['username'] as String?,
        );
        if (success) {
          synced++;
        } else {
          newQueue.add(item);
        }
      } catch (e) {
        newQueue.add(item);
      }
    }

    await prefs.setString(_queueKey, jsonEncode(newQueue));
    return synced;
  }

  static void listenToConnectivity(void Function() onOnline) {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        onOnline();
      }
    });
  }
}