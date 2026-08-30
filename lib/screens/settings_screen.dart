import 'package:flutter/material.dart';
import '../api_service.dart';
import '../user_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _usernameController = TextEditingController();
  final _fuelConsumptionController = TextEditingController();
  final _fuelPriceController = TextEditingController();

  int? _currentUserId;
  double? _currentFuelConsumption;
  double? _currentFuelPrice;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final id = await UserSettings.getUserId();
    final consumption = await UserSettings.getFuelConsumption();
    final price = await UserSettings.getFuelPrice();
    setState(() {
      _currentUserId = id;
      _currentFuelConsumption = consumption;
      _currentFuelPrice = price;
      _fuelConsumptionController.text = consumption.toStringAsFixed(1);
      _fuelPriceController.text = price.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _fuelConsumptionController.dispose();
    _fuelPriceController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _error = 'Введите username');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final userId = await ApiService.resolveUsername(username);
      if (userId == null) {
        setState(() {
          _isSaving = false;
          _error = 'Пользователь не найден';
        });
        return;
      }
      await UserSettings.setUserId(userId);
      setState(() {
        _currentUserId = userId;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User ID сохранён: $userId')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Ошибка: $e';
      });
    }
  }

  Future<void> _saveFuelSettings() async {
    final consumptionText = _fuelConsumptionController.text.trim().replaceAll(',', '.');
    final priceText = _fuelPriceController.text.trim().replaceAll(',', '.');

    final consumption = double.tryParse(consumptionText);
    final price = double.tryParse(priceText);

    if (consumption == null || consumption <= 0) {
      setState(() => _error = 'Введите корректный расход (> 0)');
      return;
    }
    if (price == null || price <= 0) {
      setState(() => _error = 'Введите корректную цену (> 0)');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await UserSettings.setFuelConsumption(consumption);
      await UserSettings.setFuelPrice(price);
      setState(() {
        _currentFuelConsumption = consumption;
        _currentFuelPrice = price;
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Параметры топлива сохранены')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _error = 'Ошибка сохранения: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Настройки пользователя ----
            Text('Профиль', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Ваш Telegram username',
                hintText: 'например, deniskaaaz (без @)',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveUsername,
              child: const Text('Сохранить username'),
            ),
            if (_currentUserId != null)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text('Текущий ID: $_currentUserId'),
              ),

            const Divider(height: 32),

            // ---- Параметры топлива ----
            Text('Топливо', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            TextField(
              controller: _fuelConsumptionController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Средний расход (л/100 км)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fuelPriceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Цена топлива (₽/л)',
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveFuelSettings,
              child: const Text('Сохранить топливо'),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}