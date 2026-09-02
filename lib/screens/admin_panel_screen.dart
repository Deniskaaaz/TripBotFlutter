import 'package:flutter/material.dart';
import '../api_service.dart';
import 'admin_user_detail_screen.dart';
import 'admin_statistics_screen.dart';

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
  String _searchQuery = '';

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

  List<Map<String, dynamic>> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final query = _searchQuery.toLowerCase();
    return _users.where((user) {
      final username = (user['username'] as String? ?? '').toLowerCase();
      final userId = user['user_id'].toString();
      return username.contains(query) || userId.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_rounded),
            tooltip: 'Общая статистика',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminStatisticsScreen(users: _users),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Поиск по нику или ID',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Ошибка: $_error'))
                    : _filteredUsers.isEmpty
                        ? const Center(child: Text('Пользователи не найдены'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
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
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdminUserDetailScreen(
                                          userId: user['user_id'] as int,
                                          username: username,
                                          password: widget.password,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}