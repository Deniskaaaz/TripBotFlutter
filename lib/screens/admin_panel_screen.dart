import 'package:flutter/material.dart';
import '../api_service.dart';
import 'admin_user_detail_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  final String password;
  const AdminPanelScreen({Key? key, required this.password}) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final users = await ApiService.adminUsers(widget.password);
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Админ-панель')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error'))
              : _users.isEmpty
                  ? const Center(child: Text('Нет пользователей'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final duration = user['total_duration'] ?? 0;
                        final hours = duration ~/ 3600;
                        final minutes = (duration % 3600) ~/ 60;
                        final durationText = hours > 0
                            ? '$hours ч $minutes мин'
                            : '$minutes мин';

                        final username = user['username'] as String?;
                        final displayName = (username != null && username.isNotEmpty)
                            ? '$username (ID: ${user['user_id']})'
                            : 'User ID: ${user['user_id']}';

                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.deepPurple.withOpacity(0.2),
                              child: const Icon(
                                Icons.person,
                                color: Colors.deepPurple,
                              ),
                            ),
                            title: Text(displayName),
                            subtitle: Text(
                              'Поездок: ${user['trips_count']}\n'
                              'Км: ${(user['total_km'] ?? 0).toStringAsFixed(1)}\n'
                              'Время: $durationText\n'
                              'Стоимость: ${(user['total_cost'] ?? 0).toStringAsFixed(2)} ₽',
                            ),
                            isThreeLine: true,
                            onTap: () {
                              // Переход к подробностям пользователя
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminUserDetailScreen(
                                    userId: user['user_id'] as int,
                                    username: username,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}