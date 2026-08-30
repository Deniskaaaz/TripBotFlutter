import 'package:flutter/material.dart';
import '../api_service.dart';
import '../user_settings.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = await UserSettings.getUserId();
      final stats = await ApiService.getStats(userId);
      setState(() {
        _stats = stats;
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
      appBar: AppBar(
        title: const Text('Статистика'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: $_error'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadStats,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : _stats == null
                  ? const Center(child: Text('Нет данных'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatCard(
                            icon: Icons.confirmation_number,
                            label: 'Всего поездок',
                            value: '${_stats!['trips_count'] ?? 0}',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            icon: Icons.straighten,
                            label: 'Общий километраж',
                            value: '${_stats!['total_km'] ?? 0.0} км',
                            color: Colors.green,
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            icon: Icons.timer,
                            label: 'Общее время',
                            value: _formatDuration(_stats!['total_duration'] ?? 0),
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            icon: Icons.attach_money,
                            label: 'Общая стоимость',
                            value: '${_stats!['total_cost'] ?? 0.0} ₽',
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 12),
                          _StatCard(
                            icon: Icons.speed,
                            label: 'Средняя дистанция',
                            value: '${_stats!['avg_km'] ?? 0.0} км',
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours ч $minutes мин';
    } else {
      return '$minutes мин';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}