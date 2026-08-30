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
  int? _currentUserId;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final id = await UserSettings.getUserId();
    setState(() {
      _currentUserId = id;
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _error = 'Введите username';
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Ваш Telegram username',
                hintText: 'например, deniskaaaz (без @)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveUsername,
              child: _isSaving
                  ? const CircularProgressIndicator()
                  : const Text('Сохранить'),
            ),
            if (_currentUserId != null) ...[
              const SizedBox(height: 10),
              Text('Текущий ID: $_currentUserId'),
            ],
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