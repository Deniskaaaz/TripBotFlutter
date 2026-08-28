import 'package:flutter/material.dart';
import '../user_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userIdController = TextEditingController();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final id = await UserSettings.getUserId();
    setState(() {
      _currentUserId = id;
      _userIdController.text = id.toString();
    });
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _saveUserId() async {
    final text = _userIdController.text.trim();
    if (text.isEmpty) return;
    final id = int.tryParse(text);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректное число')),
      );
      return;
    }
    await UserSettings.setUserId(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID сохранён')),
      );
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
              controller: _userIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ваш User ID'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveUserId,
              child: const Text('Сохранить'),
            ),
            if (_currentUserId != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Текущий ID: $_currentUserId'),
              ),
          ],
        ),
      ),
    );
  }
}