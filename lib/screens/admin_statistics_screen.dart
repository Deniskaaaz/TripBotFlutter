import 'package:flutter/material.dart';

class AdminStatisticsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> users;

  const AdminStatisticsScreen({Key? key, required this.users}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Вычисляем общую статистику
    int totalTrips = 0;
    double totalKm = 0;
    int totalDuration = 0;
    double totalCost = 0;

    for (final user in users) {
      totalTrips += user['trips_count'] as int? ?? 0;
      totalKm += (user['total_km'] as num?)?.toDouble() ?? 0;
      totalDuration += user['total_duration'] as int? ?? 0;
      totalCost += (user['total_cost'] as num?)?.toDouble() ?? 0;
    }

    final avgTrips = users.isEmpty ? 0 : totalTrips / users.length;
    final avgKm = users.isEmpty ? 0 : totalKm / users.length;
    final avgCost = users.isEmpty ? 0 : totalCost / users.length;

    // Топ пользователей по километражу
    final sortedByKm = List<Map<String, dynamic>>.from(users)
      ..sort((a, b) => ((b['total_km'] as num?)?.toDouble() ?? 0)
          .compareTo((a['total_km'] as num?)?.toDouble() ?? 0));
    final topUsers = sortedByKm.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Общая статистика')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(
            icon: Icons.confirmation_number_rounded,
            label: 'Всего поездок',
            value: '$totalTrips',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            icon: Icons.straighten_rounded,
            label: 'Общий километраж',
            value: '${totalKm.toStringAsFixed(1)} км',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            icon: Icons.timer_rounded,
            label: 'Общее время',
            value: _formatDuration(totalDuration),
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            icon: Icons.attach_money_rounded,
            label: 'Общая стоимость',
            value: '${totalCost.toStringAsFixed(2)} ₽',
            color: Colors.deepPurple,
          ),
          const SizedBox(height: 24),
          Text('Средние показатели на пользователя',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildSummaryCard(
            icon: Icons.calculate_rounded,
            label: 'Среднее поездок',
            value: avgTrips.toStringAsFixed(1),
            color: Colors.teal,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            icon: Icons.speed_rounded,
            label: 'Средний километраж',
            value: '${avgKm.toStringAsFixed(1)} км',
            color: Colors.indigo,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            icon: Icons.payments_rounded,
            label: 'Средняя стоимость',
            value: '${avgCost.toStringAsFixed(2)} ₽',
            color: Colors.pink,
          ),
          const SizedBox(height: 24),
          Text('Топ пользователей по километражу',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (topUsers.isEmpty)
            const Text('Нет данных')
          else
            ...topUsers.map((user) {
              final username = user['username'] as String?;
              final displayName = (username != null && username.isNotEmpty)
                  ? username
                  : 'User ID: ${user['user_id']}';
              final km = (user['total_km'] as num?)?.toDouble() ?? 0;
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepPurple.withOpacity(0.2),
                    child: const Icon(Icons.person, color: Colors.deepPurple),
                  ),
                  title: Text(displayName),
                  trailing: Text('${km.toStringAsFixed(1)} км'),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '$hours ч $minutes мин';
    return '$minutes мин';
  }
}