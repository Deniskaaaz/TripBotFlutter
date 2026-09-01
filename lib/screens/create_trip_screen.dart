import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'; // добавлен
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../api_service.dart';
import '../user_settings.dart';
import '../active_trip_storage.dart';
import '../offline_sync_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({Key? key}) : super(key: key);

  @override
  _CreateTripScreenState createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  // ... все переменные состояния без изменений ...

  @override
  void initState() {
    super.initState();
    _restoreActiveTrip();
    _checkLocationPermission();
  }

  // ... все методы (без изменений) ...

  @override
  Widget build(BuildContext context) {
    final displayedPoints = _routeGeometry.isNotEmpty ? _routeGeometry : _points;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Активная поездка'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await ActiveTripStorage.clearActiveTrip();
              setState(() {
                _points.clear();
                _routeGeometry.clear();
                _totalPauseDuration = Duration.zero;
                _isTripActive = false;
                _isPaused = false;
                _pauseStartTime = null;
                _tripStartTime = null;
                _message = 'Черновик поездки удалён';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _points.isNotEmpty
                    ? _points.last
                    : const LatLng(56.3269, 44.0075),
                zoom: _points.isNotEmpty ? 16 : 12,
              ),
              children: [
                CachedTileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.tripbot.trip_bot_app',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: _points.map((p) {
                    return Marker(
                      point: p,
                      width: 20,
                      height: 20,
                      child: const Icon(Icons.circle, color: Colors.blue, size: 20),
                    );
                  }).toList(),
                ),
                if (displayedPoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: displayedPoints,
                        strokeWidth: 4,
                        color: Colors.deepPurple,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // ... остальная часть UI без изменений ...
        ],
      ),
    );
  }
}