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
      appBar: AppBar(title: const Text('Статистика')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error'))
              : _stats == null
                  ? const Center(child: Text('Нет данных'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _StatCard(
                          icon: Icons.confirmation_number_rounded,
                          label: 'Всего поездок',
                          value: '${_stats!['trips_count'] ?? 0}',
                          color: Colors.blue,
                          gradient: [Colors.blue.shade400, Colors.blue.shade700],
                        ),
                        _StatCard(
                          icon: Icons.straighten_rounded,
                          label: 'Общий километраж',
                          value: '${(_stats!['total_km'] ?? 0.0).toStringAsFixed(1)} км',
                          color: Colors.green,
                          gradient: [Colors.green.shade400, Colors.green.shade700],
                        ),
                        _StatCard(
                          icon: Icons.timer_rounded,
                          label: 'Общее время',
                          value: _formatDuration(_stats!['total_duration'] ?? 0),
                          color: Colors.orange,
                          gradient: [Colors.orange.shade400, Colors.orange.shade700],
                        ),
                        _StatCard(
                          icon: Icons.attach_money_rounded,
                          label: 'Общая стоимость',
                          value: '${(_stats!['total_cost'] ?? 0.0).toStringAsFixed(2)} ₽',
                          color: Colors.deepPurple,
                          gradient: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
                        ),
                        _StatCard(
                          icon: Icons.speed_rounded,
                          label: 'Средняя дистанция',
                          value: '${(_stats!['avg_km'] ?? 0.0).toStringAsFixed(1)} км',
                          color: Colors.teal,
                          gradient: [Colors.teal.shade400, Colors.teal.shade700],
                        ),
                      ],
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
  final List<Color> gradient;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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