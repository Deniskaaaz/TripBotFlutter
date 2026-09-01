import 'package:flutter/material.dart';
import '../cached_tile_provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
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
  List<Trip> _trips = [];
  bool _isLoading = true;
  String? _error;
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadTripsAndBuildMap();
  }

  Future<void> _loadTripsAndBuildMap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = await UserSettings.getUserId();
      final trips = await ApiService.getTrips(userId);
      _trips = trips;
      _buildMapLayers();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _buildMapLayers() {
    final List<Polyline> polylines = [];
    final List<Marker> markers = [];
    final List<Color> colors = [
      Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.indigo, Colors.pink, Colors.brown, Colors.cyan,
    ];
    int colorIndex = 0;
    for (final trip in _trips) {
      final points = _parsePoints(trip.points);
      if (points.length >= 2) {
        polylines.add(Polyline(
          points: points,
          strokeWidth: 3,
          color: colors[colorIndex % colors.length],
        ));
        markers.add(Marker(
          point: points.first,
          width: 20,
          height: 20,
          child: const Icon(Icons.circle, color: Colors.green, size: 20),
        ));
        markers.add(Marker(
          point: points.last,
          width: 20,
          height: 20,
          child: const Icon(Icons.circle, color: Colors.red, size: 20),
        ));
        colorIndex++;
      }
    }
    _polylines = polylines;
    _markers = markers;
  }

  List<LatLng> _parsePoints(List<String> points) {
    final result = <LatLng>[];
    for (final p in points) {
      final parts = p.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lon = double.tryParse(parts[1]);
        if (lat != null && lon != null) {
          result.add(LatLng(lat, lon));
        }
      }
    }
    return result;
  }

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
                    initialCenter: _polylines.isNotEmpty
                        ? _polylines.first.points.first
                        : const LatLng(56.3269, 44.0075),
                    initialZoom: 10,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      tileProvider: CachedTileProvider(),
                      userAgentPackageName: 'com.tripbot.trip_bot_app',
                    ),
                    PolylineLayer(polylines: _polylines),
                    MarkerLayer(markers: _markers),
                  ],
                ),
    );
  }
}



