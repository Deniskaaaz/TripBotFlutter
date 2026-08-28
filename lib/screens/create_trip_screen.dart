import 'package:flutter/material.dart';
import '../api_service.dart';
import '../user_settings.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({Key? key}) : super(key: key);

  @override
  _CreateTripScreenState createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _cityController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  double? _distanceKm;
  int? _durationSec;
  bool _isCalculating = false;
  bool _isSaving = false;
  String _message = '';

  @override
  void dispose() {
    _cityController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _calculateRoute() async {
    final city = _cityController.text.trim();
    final origin = _startController.text.trim();
    final destination = _endController.text.trim();

    if (city.isEmpty || origin.isEmpty || destination.isEmpty) {
      setState(() {
        _message = 'Заполните все поля';
      });
      return;
    }

    setState(() {
      _isCalculating = true;
      _message = '';
    });

    try {
      final result = await ApiService.calculateRoute(
        origin: origin,
        destination: destination,
        city: city,
      );
      setState(() {
        _distanceKm = result['distance_km'] as double?;
        _durationSec = result['duration_sec'] as int?;
        _message = 'Маршрут: ${_distanceKm?.toStringAsFixed(1)} км, '
            '${(_durationSec! / 60).round()} мин';
      });
    } catch (e) {
      setState(() {
        _message = 'Ошибка расчёта: $e';
      });
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  Future<void> _saveTrip() async {
    if (_distanceKm == null || _durationSec == null) {
      setState(() {
        _message = 'Сначала рассчитайте маршрут';
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final userId = await UserSettings.getUserId();
      final success = await ApiService.saveTrip(
        userId: userId,
        city: _cityController.text.trim(),
        startPoint: _startController.text.trim(),
        endPoint: _endController.text.trim(),
        totalKm: _distanceKm!,
        totalDurationSec: _durationSec!,
      );
      if (success) {
        Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая поездка'),
      ),
      body: Padding(
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
              controller: _startController,
              decoration: const InputDecoration(labelText: 'Начальная точка (адрес)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _endController,
              decoration: const InputDecoration(labelText: 'Конечная точка (адрес)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isCalculating ? null : _calculateRoute,
              child: _isCalculating
                  ? const CircularProgressIndicator()
                  : const Text('Рассчитать маршрут'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: (_isSaving || _distanceKm == null) ? null : _saveTrip,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Сохранить поездку'),
            ),
            const SizedBox(height: 20),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}