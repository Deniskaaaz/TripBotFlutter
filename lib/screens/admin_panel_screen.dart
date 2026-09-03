import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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
                        : MasonryGridView.count(
                            padding: const EdgeInsets.all(8),
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return _UserCard(
                                user: user,
                                password: widget.password,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminUserDetailScreen(
                                        userId: user['user_id'] as int,
                                        username: user['username'] as String?,
                                        password: widget.password,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final String password;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.password,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final username = user['username'] as String?;
    final displayName = (username != null && username.isNotEmpty)
        ? username
        : 'ID: ${user['user_id']}';
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';

    final tripsCount = user['trips_count'] ?? 0;
    final totalKm = (user['total_km'] as num?)?.toDouble() ?? 0;
    final totalDuration = user['total_duration'] ?? 0;
    final totalCost = (user['total_cost'] as num?)?.toDouble() ?? 0;

    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    final durationText = hours > 0 ? '$hours ч $minutes мин' : '$minutes мин';

    final gradientColors = [
      Colors.deepPurple.shade400,
      Colors.purple.shade300,
      Colors.blue.shade300,
    ];

    final photoUrl = ApiService.getUserPhotoUrl(user['user_id'] as int, password);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    backgroundImage: NetworkImage(photoUrl),
                    child: initials.isEmpty
                        ? null
                        : Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _statLine(Icons.confirmation_number_rounded, '$tripsCount'),
              _statLine(Icons.straighten_rounded, '${totalKm.toStringAsFixed(1)} км'),
              _statLine(Icons.timer_rounded, durationText),
              _statLine(Icons.attach_money_rounded, '${totalCost.toStringAsFixed(2)} ₽'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
