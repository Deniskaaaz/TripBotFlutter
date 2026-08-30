import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../api_service.dart';
import '../user_settings.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({Key? key}) : super(key: key);

  @override
  _CreateTripScreenState createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final List<LatLng> _points = [];
  bool _isTripActive = false;
  bool _isPaused = false;
  DateTime? _pauseStartTime;
  Duration _totalPauseDuration = Duration.zero;
  bool _isSaving = false;
  String _message = '';

  final _cityController = TextEditingController(text: 'Нижний Новгород');
  final _manualAddressController = TextEditingController();

  // Для карты
  LatLng? _mapCenter;
  double _mapZoom = 12;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _message = 'Службы геолокации отключены');
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _message = 'Разрешение на геолокацию отклонено');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _message = 'Разрешение на геолокацию отключено навсегда');
    }
  }

  Future<void> _addCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _points.add(latLng);
        if (!_isTripActive) _isTripActive = true;
        _mapCenter = latLng;
        _message = 'Точка добавлена (${_points.length})';
      });
    } catch (e) {
      setState(() => _message = 'Не удалось получить GPS: $e');
    }
  }

  Future<void> _addManualAddress() async {
    final address = _manualAddressController.text.trim();
    if (address.isEmpty) {
      setState(() => _message = 'Введите адрес');
      return;
    }
    // Для простоты добавляем адрес как координаты? Нет, адрес не является координатой.
    // Предположим, что пользователь вводит координаты? Лучше не будем добавлять в карту,
    // а просто в список точек-строк? Мы сейчас используем LatLng, поэтому ручной ввод не подходит.
    // Можно заменить на геокодирование, но пока оставим как заглушку с сообщением.
    setState(() {
      _message = 'Ручной ввод адреса пока не поддержан, используйте GPS';
    });
  }

  void _togglePause() {
    if (!_isTripActive) {
      setState(() => _message = 'Поездка не начата');
      return;
    }
    if (_isPaused) {
      if (_pauseStartTime != null) {
        final pauseEnd = DateTime.now();
        _totalPauseDuration += pauseEnd.difference(_pauseStartTime!);
        setState(() {
          _isPaused = false;
          _pauseStartTime = null;
          _message = 'Поездка продолжена';
        });
      }
    } else {
      setState(() {
        _isPaused = true;
        _pauseStartTime = DateTime.now();
        _message = 'Пауза начата';
      });
    }
  }

  Future<void> _finishTrip() async {
    if (_points.length < 2) {
      setState(() => _message = 'Нужно минимум две точки');
      return;
    }
    if (_isPaused) {
      _togglePause();
    }
    setState(() {
      _isSaving = true;
      _message = 'Расчёт маршрута...';
    });

    try {
      // Преобразуем LatLng в строки "lat,lon"
      final pointStrings = _points.map((p) => '${p.latitude},${p.longitude}').toList();
      final routeResult = await ApiService.calculateMultiRoute(
        points: pointStrings,
        city: _cityController.text.trim(),
      );
      final distanceKm = routeResult['distance_km'] as double?;
      final durationSec = routeResult['duration_sec'] as int?;
      if (distanceKm == null || durationSec == null) {
        throw Exception('Некорректный ответ сервера');
      }

      final userId = await UserSettings.getUserId();
      final cost = await UserSettings.calculateTripCost(distanceKm);
      final success = await ApiService.saveTrip(
        userId: userId,
        city: _cityController.text.trim(),
        startPoint: pointStrings.first,
        endPoint: pointStrings.last,
        totalKm: distanceKm,
        totalDurationSec: durationSec,
        totalPauseSec: _totalPauseDuration.inSeconds,
        totalCost: cost,
        points: pointStrings,
      );
      if (success) {
        // Показать итоговый диалог с картой и статистикой
        _showSummaryDialog(distanceKm, durationSec, cost);
      }
    } catch (e) {
      setState(() {
        _message = 'Ошибка сохранения: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSummaryDialog(double distanceKm, int durationSec, double cost) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Поездка завершена'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Мини-карта с маршрутом
              SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    center: _points.first,
                    zoom: 12,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.tripbot.trip_bot_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _points.first,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.trip_origin, color: Colors.green, size: 40),
                        ),
                        if (_points.length > 1)
                          Marker(
                            point: _points.last,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.place, color: Colors.red, size: 40),
                          ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _points,
                          strokeWidth: 4,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Дистанция: ${distanceKm.toStringAsFixed(1)} км'),
              Text('Время: ${(durationSec / 60).round()} мин'),
              Text('Стоимость: ${cost.toStringAsFixed(2)} ₽'),
              if (_totalPauseDuration.inSeconds > 0)
                Text('Пауза: ${_totalPauseDuration.inMinutes} мин'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(true); // возврат к списку
            },
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _manualAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Активная поездка'),
      ),
      body: Column(
        children: [
          // Карта
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: MapOptions(
                center: _mapCenter ?? LatLng(56.3269, 44.0075), // Нижний Новгород
                zoom: _mapZoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.tripbot.trip_bot_app',
                ),
                MarkerLayer(
                  markers: _points.map((p) {
                    return Marker(
                      point: p,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.circle, color: Colors.blue, size: 20),
                    );
                  }).toList(),
                ),
                if (_points.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _points,
                        strokeWidth: 4,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Панель управления
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Город'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTripActive ? null : _addCurrentLocation,
                          icon: const Icon(Icons.my_location_rounded),
                          label: const Text('Начать'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTripActive ? _addCurrentLocation : null,
                          icon: const Icon(Icons.gps_fixed_rounded),
                          label: const Text('Я на адресе'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTripActive ? _togglePause : null,
                          icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                          label: Text(_isPaused ? 'Продолжить' : 'Пауза'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTripActive && !_isSaving ? _finishTrip : null,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Завершить'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Точек: ${_points.length}', style: const TextStyle(fontSize: 16)),
                  if (_totalPauseDuration.inSeconds > 0)
                    Text('Пауза: ${_totalPauseDuration.inMinutes} мин'),
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _message,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}