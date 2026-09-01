import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart'; // добавлен
import 'package:latlong2/latlong.dart';
import '../api_service.dart';
import '../models/trip.dart';
import '../user_settings.dart';

class AllTripsMapScreen extends StatefulWidget {
  const AllTripsMapScreen({Key? key}) : super(key: key);

  @override
  _AllTripsMapScreenState createState() => _AllTripsMapScreenState();
}

class _AllTripsMapScreenState extends State<AllTripsMapScreen> {
  // ... переменные состояния ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Все поездки на карте')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Ошибка: $_error'))
              : FlutterMap(
                  options: MapOptions(
                    center: _polylines.isNotEmpty
                        ? _polylines.first.points.first
                        : const LatLng(56.3269, 44.0075),
                    zoom: 10,
                  ),
                  children: [
                    CachedTileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.tripbot.trip_bot_app',
                      maxZoom: 19,
                    ),
                    PolylineLayer(polylines: _polylines),
                    MarkerLayer(markers: _markers),
                  ],
                ),
    );
  }
}