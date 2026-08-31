import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../api_service.dart';
import '../user_settings.dart';
import '../active_trip_storage.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({Key? key}) : super(key: key);

  @override
  _CreateTripScreenState createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final List<LatLng> _points = [];
  List<LatLng> _routeGeometry = []; // реальная геометрия маршрута по дорогам
  bool _isTripActive = false;
  bool _isPaused = false;
  DateTime? _pauseStartTime;
  Duration _totalPauseDuration = Duration.zero;
  bool _isSaving = false;
  bool _isAddingPoint = false;
  String _message = '';

  final _cityController = TextEditingController(text: 'Нижний Новгород');
  final _manualAddressController = TextEditingController();

  LatLng? _mapCenter;
  double _mapZoom = 12;

  @override
  void initState() {
    super.initState();
    _restoreActiveTrip();
    _checkLocationPermission();
  }

  Future<void> _restoreActiveTrip() async {
    final saved = await ActiveTripStorage.loadActiveTrip();
    if (saved != null) {
      final pointStrings = saved['points'] as List<String>;
      final points = pointStrings.map((s) {
        final parts = s.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0]);
          final lon = double.tryParse(parts[1]);
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
        return null;
      }).whereType<LatLng>().toList();

      setState(() {
        _points.addAll(points);
        _totalPauseDuration = Duration(seconds: saved['pauseSeconds'] as int? ?? 0);
        _isPaused = saved['isPaused'] as bool? ?? false;
        _pauseStartTime = saved['pauseStartTime'] as DateTime?;
        _isTripActive = _points.isNotEmpty;
        if (_points.isNotEmpty) _mapCenter = _points.last;
      });
    }
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

  Future<void> _saveActiveTrip() async {
    if (_points.isEmpty) {
      await ActiveTripStorage.clearActiveTrip();
      return;
    }
    final pointStrings = _points.map((p) => '${p.latitude},${p.longitude}').toList();
    await ActiveTripStorage.saveActiveTrip(
      points: pointStrings,
      pauseSeconds: _totalPauseDuration.inSeconds,
      isPaused: _isPaused,
      pauseStartTime: _pauseStartTime,
    );
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
      await _saveActiveTrip();
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
    setState(() {
      _isAddingPoint = true;
      _message = 'Геокодирование...';
    });
    try {
      final result = await ApiService.geocodeAddress(
        address,
        city: _cityController.text.trim(),
      );
      final lat = result['lat'] as double?;
      final lon = result['lon'] as double?;
      if (lat == null || lon == null) {
        throw Exception('Координаты не найдены');
      }
      final latLng = LatLng(lat, lon);
      setState(() {
        _points.add(latLng);
        if (!_isTripActive) _isTripActive = true;
        _mapCenter = latLng;
        _message = 'Адрес добавлен (${_points.length})';
        _manualAddressController.clear();
      });
      await _saveActiveTrip();
    } catch (e) {
      setState(() => _message = 'Ошибка геокодирования: $e');
    } finally {
      setState(() => _isAddingPoint = false);
    }
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
        _saveActiveTrip();
      }
    } else {
      setState(() {
        _isPaused = true;
        _pauseStartTime = DateTime.now();
        _message = 'Пауза начата';
      });
      _saveActiveTrip();
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

      // Получаем геометрию маршрута, если сервер её вернул
      final geometry = routeResult['geometry'] as List<dynamic>?;
      if (geometry != null) {
        _routeGeometry = geometry.map((coord) {
          if (coord is List && coord.length >= 2) {
            final lat = (coord[0] as num).toDouble();
            final lon = (coord[1] as num).toDouble();
            return LatLng(lat, lon);
          }
          return null;
        }).whereType<LatLng>().toList();
      } else {
        _routeGeometry = [];
      }

      // Обратное геокодирование начальной и конечной точек
      String startAddress = pointStrings.first;
      String endAddress = pointStrings.last;
      try {
        final startLatLng = _points.first;
        final endLatLng = _points.last;
        final startAddr = await ApiService.reverseGeocode(startLatLng.latitude, startLatLng.longitude);
        if (startAddr != null && startAddr.isNotEmpty) startAddress = startAddr;
        final endAddr = await ApiService.reverseGeocode(endLatLng.latitude, endLatLng.longitude);
        if (endAddr != null && endAddr.isNotEmpty) endAddress = endAddr;
      } catch (_) {}

      final userId = await UserSettings.getUserId();
      final cost = await UserSettings.calculateTripCost(distanceKm);

      // При сохранении используем геометрию маршрута, если она есть, иначе исходные точки
      final pointsToSave = _routeGeometry.isNotEmpty
          ? _routeGeometry.map((p) => '${p.latitude},${p.longitude}').toList()
          : pointStrings;

      final success = await ApiService.saveTrip(
        userId: userId,
        city: _cityController.text.trim(),
        startPoint: startAddress,
        endPoint: endAddress,
        totalKm: distanceKm,
        totalDurationSec: durationSec,
        totalPauseSec: _totalPauseDuration.inSeconds,
        totalCost: cost,
        points: pointsToSave,
      );
      if (success) {
        await ActiveTripStorage.clearActiveTrip();
        _showSummaryDialog(
          distanceKm,
          durationSec,
          cost,
          _routeGeometry.isNotEmpty ? _routeGeometry : _points,
        );
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

  void _showSummaryDialog(
      double distanceKm, int durationSec, double cost, List<LatLng> routePoints) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Поездка завершена'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    center: routePoints.first,
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
                          point: routePoints.first,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.trip_origin, color: Colors.green, size: 40),
                        ),
                        if (routePoints.length > 1)
                          Marker(
                            point: routePoints.last,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.place, color: Colors.red, size: 40),
                          ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
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
              Navigator.of(context).pop(true);
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ActiveTripStorage.clearActiveTrip();
              setState(() {
                _points.clear();
                _routeGeometry.clear();
                _totalPauseDuration = Duration.zero;
                _isTripActive = false;
                _isPaused = false;
                _pauseStartTime = null;
                _message = 'Черновик поездки удалён';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                center: _mapCenter ?? const LatLng(56.3269, 44.0075),
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
                      width: 20,
                      height: 20,
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Город'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _manualAddressController,
                    decoration: const InputDecoration(labelText: 'Адрес вручную'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isAddingPoint ? null : _addManualAddress,
                    icon: const Icon(Icons.edit_location_alt_rounded),
                    label: const Text('Добавить адрес'),
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