import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/trip.dart';

class TripDetailScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailScreen({Key? key, required this.trip}) : super(key: key);

  LatLng? _parseLatLng(String? input) {
    if (input == null || input.isEmpty) return null;
    final parts = input.split(',');
    if (parts.length != 2) return null;
    final lat = double.tryParse(parts[0].trim());
    final lon = double.tryParse(parts[1].trim());
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  @override
  Widget build(BuildContext context) {
    final points = trip.points.map((p) => _parseLatLng(p)).whereType<LatLng>().toList();
    final hasMap = points.isNotEmpty;

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
            if (hasMap) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 250,
                  child: FlutterMap(
                    options: MapOptions(
                      center: points.first,
                      zoom: 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.tripbot.trip_bot_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: points.first,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.trip_origin,
                              color: Colors.green,
                              size: 40,
                            ),
                          ),
                          if (points.length > 1)
                            Marker(
                              point: points.last,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.place,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                        ],
                      ),
                      if (points.length > 1)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: points,
                              strokeWidth: 4,
                              color: Colors.deepPurple,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

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
          ],
        ),
      ),
    );
  }
}

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