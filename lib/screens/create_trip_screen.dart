import 'package:flutter/material.dart';
import '../cached_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
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
  final List<LatLng> _points = [];
  List<LatLng> _routeGeometry = [];
  bool _isTripActive = false;
  bool _isPaused = false;
  DateTime? _pauseStartTime;
  Duration _totalPauseDuration = Duration.zero;
  DateTime? _tripStartTime;
  bool _isSaving = false;
  bool _isAddingPoint = false;
  bool _isUpdatingGeometry = false;
  String _message = '';

  final _cityController = TextEditingController(text: 'РќРёР¶РЅРёР№ РќРѕРІРіРѕСЂРѕРґ');
  final _addressController = TextEditingController();
  List<String> _addressSuggestions = [];

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _restoreActiveTrip();
    _checkLocationPermission();
  }

  Future<void> _restoreActiveTrip() async {
    final saved = await ActiveTripStorage.loadActiveTrip();
    if (saved != null) {
      final pointStrings = saved['points'] as List<String>;
      final points = pointStrings.map((s) {
        final parts = s.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0]);
          final lon = double.tryParse(parts[1]);
          if (lat != null && lon != null) return LatLng(lat, lon);
        }
        return null;
      }).whereType<LatLng>().toList();

      setState(() {
        _points.addAll(points);
        _totalPauseDuration = Duration(seconds: saved['pauseSeconds'] as int? ?? 0);
        _isPaused = saved['isPaused'] as bool? ?? false;
        _pauseStartTime = saved['pauseStartTime'] as DateTime?;
        _tripStartTime = saved['tripStartTime'] as DateTime?;
        _isTripActive = _points.isNotEmpty;
        if (_points.isNotEmpty) {
          _mapController.move(_points.last, 16);
        }
      });

      if (_points.length >= 2) {
        await _updateRouteGeometry();
      }
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _message = 'РЎР»СѓР¶Р±С‹ РіРµРѕР»РѕРєР°С†РёРё РѕС‚РєР»СЋС‡РµРЅС‹');
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _message = 'Р Р°Р·СЂРµС€РµРЅРёРµ РЅР° РіРµРѕР»РѕРєР°С†РёСЋ РѕС‚РєР»РѕРЅРµРЅРѕ');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() => _message = 'Р Р°Р·СЂРµС€РµРЅРёРµ РЅР° РіРµРѕР»РѕРєР°С†РёСЋ РѕС‚РєР»СЋС‡РµРЅРѕ РЅР°РІСЃРµРіРґР°');
    }
  }

  Future<void> _saveActiveTrip() async {
    if (_points.isEmpty) {
      await ActiveTripStorage.clearActiveTrip();
      return;
    }
    final pointStrings = _points.map((p) => '${p.latitude},${p.longitude}').toList();
    await ActiveTripStorage.saveActiveTrip(
      points: pointStrings,
      pauseSeconds: _totalPauseDuration.inSeconds,
      isPaused: _isPaused,
      pauseStartTime: _pauseStartTime,
      tripStartTime: _tripStartTime,
    );
  }

  Future<void> _updateRouteGeometry() async {
    if (_isUpdatingGeometry) return;
    if (_points.length < 2) return;

    setState(() {
      _isUpdatingGeometry = true;
      _message = 'РћР±РЅРѕРІР»РµРЅРёРµ РјР°СЂС€СЂСѓС‚Р°...';
    });

    try {
      final pointStrings = _points.map((p) => '${p.latitude},${p.longitude}').toList();
      final result = await ApiService.calculateMultiRoute(
        points: pointStrings,
        city: _cityController.text.trim(),
      );
      final geometry = result['geometry'] as List<dynamic>?;
      if (geometry != null) {
        setState(() {
          _routeGeometry = geometry.map((coord) {
            if (coord is List && coord.length >= 2) {
              final lat = (coord[0] as num).toDouble();
              final lon = (coord[1] as num).toDouble();
              return LatLng(lat, lon);
            }
            return null;
          }).whereType<LatLng>().toList();
        });
      }
    } catch (e) {
      print('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РіРµРѕРјРµС‚СЂРёРё: $e');
    } finally {
      setState(() {
        _isUpdatingGeometry = false;
        if (_message == 'РћР±РЅРѕРІР»РµРЅРёРµ РјР°СЂС€СЂСѓС‚Р°...') _message = '';
      });
    }
  }

  Future<void> _addCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _points.add(latLng);
        if (!_isTripActive) _isTripActive = true;
        if (_points.length == 1) _tripStartTime = DateTime.now();
        _message = 'РўРѕС‡РєР° РґРѕР±Р°РІР»РµРЅР° (${_points.length})';
      });
      _mapController.move(latLng, 16);
      await _saveActiveTrip();
      if (_points.length >= 2) {
        await _updateRouteGeometry();
      }
    } catch (e) {
      setState(() => _message = 'РќРµ СѓРґР°Р»РѕСЃСЊ РїРѕР»СѓС‡РёС‚СЊ GPS: $e');
    }
  }

  Future<void> _addAddressFromSuggestion(String address) async {
    _addressController.text = address;
    setState(() => _addressSuggestions = []);
    setState(() {
      _isAddingPoint = true;
      _message = 'Р“РµРѕРєРѕРґРёСЂРѕРІР°РЅРёРµ...';
    });
    try {
      final result = await ApiService.geocodeAddress(
        address,
        city: _cityController.text.trim(),
      );
      final lat = result['lat'] as double?;
      final lon = result['lon'] as double?;
      if (lat == null || lon == null) {
        throw Exception('РљРѕРѕСЂРґРёРЅР°С‚С‹ РЅРµ РЅР°Р№РґРµРЅС‹');
      }
      final latLng = LatLng(lat, lon);
      setState(() {
        _points.add(latLng);
        if (!_isTripActive) _isTripActive = true;
        if (_points.length == 1) _tripStartTime = DateTime.now();
        _message = 'РђРґСЂРµСЃ РґРѕР±Р°РІР»РµРЅ (${_points.length})';
        _addressController.clear();
      });
      _mapController.move(latLng, 16);
      await _saveActiveTrip();
      if (_points.length >= 2) {
        await _updateRouteGeometry();
      }
    } catch (e) {
      setState(() => _message = 'РћС€РёР±РєР° РіРµРѕРєРѕРґРёСЂРѕРІР°РЅРёСЏ: $e');
    } finally {
      setState(() => _isAddingPoint = false);
    }
  }

  Future<void> _fetchAddressSuggestions(String query) async {
    if (query.length < 3) {
      setState(() => _addressSuggestions = []);
      return;
    }
    try {
      final suggestions = await ApiService.suggestAddresses(
        query,
        city: _cityController.text.trim(),
      );
      setState(() => _addressSuggestions = suggestions);
    } catch (e) {
      setState(() => _addressSuggestions = []);
    }
  }

  void _togglePause() {
    if (!_isTripActive) {
      setState(() => _message = 'РџРѕРµР·РґРєР° РЅРµ РЅР°С‡Р°С‚Р°');
      return;
    }
    if (_isPaused) {
      if (_pauseStartTime != null) {
        final pauseEnd = DateTime.now();
        _totalPauseDuration += pauseEnd.difference(_pauseStartTime!);
        setState(() {
          _isPaused = false;
          _pauseStartTime = null;
          _message = 'РџРѕРµР·РґРєР° РїСЂРѕРґРѕР»Р¶РµРЅР°';
        });
        _saveActiveTrip();
      }
    } else {
      setState(() {
        _isPaused = true;
        _pauseStartTime = DateTime.now();
        _message = 'РџР°СѓР·Р° РЅР°С‡Р°С‚Р°';
      });
      _saveActiveTrip();
    }
  }

  Future<void> _finishTrip() async {
    if (_points.length < 2) {
      setState(() => _message = 'РќСѓР¶РЅРѕ РјРёРЅРёРјСѓРј РґРІРµ С‚РѕС‡РєРё');
      return;
    }
    if (_isPaused) _togglePause();

    final connectivityResult = await Connectivity().checkConnectivity();
    final hasInternet = connectivityResult.any((r) => r != ConnectivityResult.none);

    setState(() {
      _isSaving = true;
      _message = hasInternet ? 'Р Р°СЃС‡С‘С‚ РјР°СЂС€СЂСѓС‚Р°...' : 'РќРµС‚ СЃРµС‚Рё. РџРѕРµР·РґРєР° Р±СѓРґРµС‚ СЃРѕС…СЂР°РЅРµРЅР° Р»РѕРєР°Р»СЊРЅРѕ.';
    });

    try {
      final pointStrings = _points.map((p) => '${p.latitude},${p.longitude}').toList();

      Duration actualTripDuration = Duration.zero;
      if (_tripStartTime != null) {
        actualTripDuration = DateTime.now().difference(_tripStartTime!) - _totalPauseDuration;
        if (actualTripDuration.isNegative) actualTripDuration = Duration.zero;
      }
      final actualDurationSec = actualTripDuration.inSeconds;

      if (!hasInternet) {
        final userId = await UserSettings.getUserId();
        final tripData = {
          'user_id': userId,
          'city': _cityController.text.trim(),
          'start_point': pointStrings.first,
          'end_point': pointStrings.last,
          'total_km': 0.0,
          'total_duration_sec': actualDurationSec,
          'total_pause_sec': _totalPauseDuration.inSeconds,
          'total_cost': 0.0,
          'points': pointStrings,
          'username': null,
        };
        await OfflineSyncService.addTripToQueue(tripData);
        await ActiveTripStorage.clearActiveTrip();
        setState(() {
          _isSaving = false;
          _message = 'РџРѕРµР·РґРєР° СЃРѕС…СЂР°РЅРµРЅР° Р»РѕРєР°Р»СЊРЅРѕ. РћРЅР° Р±СѓРґРµС‚ РѕС‚РїСЂР°РІР»РµРЅР° РїСЂРё РїРѕРґРєР»СЋС‡РµРЅРёРё Рє РёРЅС‚РµСЂРЅРµС‚Сѓ.';
        });
        Navigator.pop(context, true);
        return;
      }

      final routeResult = await ApiService.calculateMultiRoute(
        points: pointStrings,
        city: _cityController.text.trim(),
      );
      final distanceKm = routeResult['distance_km'] as double?;
      final durationSec = routeResult['duration_sec'] as int?;
      if (distanceKm == null || durationSec == null) {
        throw Exception('РќРµРєРѕСЂСЂРµРєС‚РЅС‹Р№ РѕС‚РІРµС‚ СЃРµСЂРІРµСЂР°');
      }

      final geometry = routeResult['geometry'] as List<dynamic>?;
      if (geometry != null) {
        _routeGeometry = geometry.map((coord) {
          if (coord is List && coord.length >= 2) {
            final lat = (coord[0] as num).toDouble();
            final lon = (coord[1] as num).toDouble();
            return LatLng(lat, lon);
          }
          return null;
        }).whereType<LatLng>().toList();
      } else {
        _routeGeometry = [];
      }

      String startAddress = pointStrings.first;
      String endAddress = pointStrings.last;
      try {
        final startLatLng = _points.first;
        final endLatLng = _points.last;
        final startAddr = await ApiService.reverseGeocode(startLatLng.latitude, startLatLng.longitude);
        if (startAddr != null && startAddr.isNotEmpty) startAddress = startAddr;
        final endAddr = await ApiService.reverseGeocode(endLatLng.latitude, endLatLng.longitude);
        if (endAddr != null && endAddr.isNotEmpty) endAddress = endAddr;
      } catch (_) {}

      final userId = await UserSettings.getUserId();
      final cost = await UserSettings.calculateTripCost(distanceKm);
      final pointsToSave = _routeGeometry.isNotEmpty
          ? _routeGeometry.map((p) => '${p.latitude},${p.longitude}').toList()
          : pointStrings;

      final success = await ApiService.saveTrip(
        userId: userId,
        city: _cityController.text.trim(),
        startPoint: startAddress,
        endPoint: endAddress,
        totalKm: distanceKm,
        totalDurationSec: actualDurationSec,
        totalPauseSec: _totalPauseDuration.inSeconds,
        totalCost: cost,
        points: pointsToSave,
      );
      if (success) {
        await ActiveTripStorage.clearActiveTrip();
        _showSummaryDialog(
          distanceKm,
          actualDurationSec,
          cost,
          _routeGeometry.isNotEmpty ? _routeGeometry : _points,
        );
      }
    } catch (e) {
      setState(() => _message = 'РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSummaryDialog(
      double distanceKm, int durationSec, double cost, List<LatLng> routePoints) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('РџРѕРµР·РґРєР° Р·Р°РІРµСЂС€РµРЅР°'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(initialCenter: routePoints.first, initialZoom: 12),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      tileProvider: CachedTileProvider(),
                      userAgentPackageName: 'com.tripbot.trip_bot_app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: routePoints.first,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.trip_origin, color: Colors.green, size: 40),
                        ),
                        if (routePoints.length > 1)
                          Marker(
                            point: routePoints.last,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.place, color: Colors.red, size: 40),
                          ),
                      ],
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 4,
                          color: Colors.deepPurple,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Р”РёСЃС‚Р°РЅС†РёСЏ: ${distanceKm.toStringAsFixed(1)} РєРј'),
              Text('Р’СЂРµРјСЏ: ${(durationSec / 60).round()} РјРёРЅ'),
              Text('РЎС‚РѕРёРјРѕСЃС‚СЊ: ${cost.toStringAsFixed(2)} в‚Ѕ'),
              if (_totalPauseDuration.inSeconds > 0)
                Text('РџР°СѓР·Р°: ${_totalPauseDuration.inMinutes} РјРёРЅ'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('Р“РѕС‚РѕРІРѕ'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedPoints = _routeGeometry.isNotEmpty ? _routeGeometry : _points;

    return Scaffold(
      appBar: AppBar(
        title: const Text('РђРєС‚РёРІРЅР°СЏ РїРѕРµР·РґРєР°'),
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
                _message = 'Р§РµСЂРЅРѕРІРёРє РїРѕРµР·РґРєРё СѓРґР°Р»С‘РЅ';
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
                initialCenter: _points.isNotEmpty
                    ? _points.last
                    : const LatLng(56.3269, 44.0075),
                initialZoom: _points.isNotEmpty ? 16 : 12,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  tileProvider: CachedTileProvider(),
                  userAgentPackageName: 'com.tripbot.trip_bot_app',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Р“РѕСЂРѕРґ'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'РђРґСЂРµСЃ (РЅР°С‡РЅРёС‚Рµ РІРІРѕРґРёС‚СЊ)'),
                    onChanged: _fetchAddressSuggestions,
                  ),
                  if (_addressSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _addressSuggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final suggestion = _addressSuggestions[index];
                          return ListTile(
                            dense: true,
                            title: Text(suggestion),
                            onTap: () => _addAddressFromSuggestion(suggestion),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTripActive ? null : _addCurrentLocation,
                          icon: const Icon(Icons.my_location_rounded),
                          label: const Text('РќР°С‡Р°С‚СЊ'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTripActive ? _addCurrentLocation : null,
                          icon: const Icon(Icons.gps_fixed_rounded),
                          label: const Text('РЇ РЅР° Р°РґСЂРµСЃРµ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTripActive ? _togglePause : null,
                          icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                          label: Text(_isPaused ? 'РџСЂРѕРґРѕР»Р¶РёС‚СЊ' : 'РџР°СѓР·Р°'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTripActive && !_isSaving ? _finishTrip : null,
                          icon: const Icon(Icons.check_rounded),
                          label: const Text('Р—Р°РІРµСЂС€РёС‚СЊ'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('РўРѕС‡РµРє: ${_points.length}', style: const TextStyle(fontSize: 16)),
                  if (_totalPauseDuration.inSeconds > 0)
                    Text('РџР°СѓР·Р°: ${_totalPauseDuration.inMinutes} РјРёРЅ'),
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _message,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}




