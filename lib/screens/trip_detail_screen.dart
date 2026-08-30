import 'package:flutter/material.dart';
import '../models/trip.dart';

class TripDetailScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailScreen({Key? key, required this.trip}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Преобразование секунд в часы и минуты
    final durationHours = trip.totalDurationSec ~/ 3600;
    final durationMinutes = (trip.totalDurationSec % 3600) ~/ 60;
    final durationText = durationHours > 0
        ? '${durationHours} ч ${durationMinutes} мин'
        : '${durationMinutes} мин';

    final pauseMinutes = trip.totalPauseSec ~/ 60;
    final pauseText = pauseMinutes > 0 ? '$pauseMinutes мин' : 'Нет';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали поездки'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок маршрута
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_city, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          trip.city,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.trip_origin,
                      label: 'Начальная точка',
                      value: trip.startPoint,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.place,
                      label: 'Конечная точка',
                      value: trip.endPoint,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Основные показатели
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.straighten,
                      label: 'Дистанция',
                      value: '${trip.totalKm.toStringAsFixed(1)} км',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.timer,
                      label: 'Время в пути',
                      value: durationText,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.pause_circle_outline,
                      label: 'Пауза',
                      value: pauseText,
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.attach_money,
                      label: 'Стоимость',
                      value: trip.totalCost > 0
                          ? '${trip.totalCost.toStringAsFixed(2)} ₽'
                          : 'Не указана',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Дата и время
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Дата и время',
                  value: trip.timestamp,
                ),
              ),
            ),

            // Точки маршрута (если есть)
            if (trip.points.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.alt_route, color: Colors.deepPurple),
                          const SizedBox(width: 8),
                          Text(
                            'Промежуточные точки (${trip.points.length})',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (final point in trip.points)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(point),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Виджет для строки с иконкой и текстом
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}