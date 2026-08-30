import 'package:flutter/material.dart';
import '../api_service.dart';
import 'admin_panel_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);

  @override
  _AdminLoginScreenState createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _passwordController = TextEditingController();
  bool _isChecking = false;
  String? _error;

  Future<void> _login() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    setState(() {
      _isChecking = true;
      _error = null;
    });

    try {
      final success = await ApiService.adminLogin(password);
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AdminPanelScreen(password: password),
          ),
        );
      } else {
        setState(() {
          _error = 'Неверный пароль';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход в админ-панель')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Пароль'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isChecking ? null : _login,
              child: _isChecking
                  ? const CircularProgressIndicator()
                  : const Text('Войти'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
    );
  }
}