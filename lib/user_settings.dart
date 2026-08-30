import 'package:shared_preferences/shared_preferences.dart';

class UserSettings {
  static const String _keyUserId = 'user_id';
  static const String _keyFuelConsumption = 'fuel_consumption'; // л/100 км
  static const String _keyFuelPrice = 'fuel_price'; // руб/л

  // Загрузить user_id, по умолчанию 1
  static Future<int> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId) ?? 1;
  }

  // Сохранить user_id
  static Future<void> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  // Получить средний расход (л/100 км), по умолчанию 10.0
  static Future<double> getFuelConsumption() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFuelConsumption) ?? 10.0;
  }

  // Сохранить средний расход
  static Future<void> setFuelConsumption(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFuelConsumption, value);
  }

  // Получить цену топлива (₽/л), по умолчанию 70.0
  static Future<double> getFuelPrice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyFuelPrice) ?? 70.0;
  }

  // Сохранить цену топлива
  static Future<void> setFuelPrice(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyFuelPrice, value);
  }

  // Рассчитать стоимость поездки
  static Future<double> calculateTripCost(double distanceKm) async {
    final consumption = await getFuelConsumption();
    final price = await getFuelPrice();
    return (distanceKm / 100.0) * consumption * price;
  }
}