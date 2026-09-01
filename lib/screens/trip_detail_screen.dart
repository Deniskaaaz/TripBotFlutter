import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'; // добавлен
import 'package:latlong2/latlong.dart';
import '../models/trip.dart';

class TripDetailScreen extends StatelessWidget {
  final Trip trip;

  const TripDetailScreen({Key? key, required this.trip}) : super(key: key);

  LatLng? _parseLatLng(String? input) {
    // ... (без изменений)
  }

  String _formatTimestamp(String raw) {
    // ... (без изменений)
  }

  @override
  Widget build(BuildContext context) {
    // ... подготовка данных без изменений ...

    return Scaffold(
      appBar: AppBar(title: const Text('Детали поездки')),
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
                    options: MapOptions(center: points.first, zoom: 12),
                    children: [
                      CachedTileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                        userAgentPackageName: 'com.tripbot.trip_bot_app',
                        maxZoom: 19,
                      ),
                      // ... маркеры и полилинии без изменений ...
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // ... остальной UI без изменений ...
          ],
        ),
      ),
    );
  }
}