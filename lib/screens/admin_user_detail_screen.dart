import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/trip.dart';
import 'trip_detail_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final int userId;
  final String? username;
  final String password;
  const AdminUserDetailScreen({
    Key? key,
    required this.userId,
    this.username,
    required this.password,
  }) : super(key: key);

  @override
  _AdminUserDetailScreenState createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  List<Trip> _trips = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getTrips(widget.userId),
        ApiService.getStats(widget.userId),
      ]);
      setState(() {
        _trips = results[0] as List<Trip>;
        _stats = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDeleteTrip(int tripId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить поездку?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await ApiService.adminDeleteTrip(tripId, widget.password);
        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Поездка удалена')),
            );
          }
          _loadData(); // обновляем список
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка удаления: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = widget.username != null && widget.username!.isNotEmpty
        ? '${widget.username} (ID: ${widget.userId})'
        : 'User ID: ${widget.userId}';

    return Scaffold(
      appBar: AppBar(title: Text(displayTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error'))
              : Column(
                  children: [
                    if (_stats != null) _buildStatsSection(),
                    const Divider(height: 1),
                    Expanded(
                      child: _trips.isEmpty
                          ? const Center(child: Text('Нет поездок'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: _trips.length,
                              itemBuilder: (context, index) {
                                final trip = _trips[index];
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.deepPurple.withOpacity(0.2),
                                      child: const Icon(Icons.route, color: Colors.deepPurple),
                                    ),
                                    title: Text('${trip.city}: ${trip.startPoint} → ${trip.endPoint}'),
                                    subtitle: Text(
                                      '${trip.totalKm.toStringAsFixed(1)} км · ${(trip.totalDurationSec / 60).round()} мин',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _confirmDeleteTrip(trip.id),
                                        ),
                                        const Icon(Icons.chevron_right),
                                      ],
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TripDetailScreen(trip: trip),
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

  Widget _buildStatsSection() {
    final duration = _stats!['total_duration'] ?? 0;
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final durationText = hours > 0 ? '$hours ч $minutes мин' : '$minutes мин';

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Статистика', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _statRow('Всего поездок', '${_stats!['trips_count'] ?? 0}'),
          _statRow('Общий км', '${(_stats!['total_km'] ?? 0).toStringAsFixed(1)} км'),
          _statRow('Общее время', durationText),
          _statRow('Общая стоимость', '${(_stats!['total_cost'] ?? 0).toStringAsFixed(2)} ₽'),
          _statRow('Средняя дистанция', '${(_stats!['avg_km'] ?? 0).toStringAsFixed(1)} км'),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}