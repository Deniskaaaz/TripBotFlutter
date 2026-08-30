import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/trip.dart';
import '../user_settings.dart';
import 'create_trip_screen.dart';
import 'settings_screen.dart';
import 'trip_detail_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({Key? key}) : super(key: key);

  @override
  _TripListScreenState createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  List<Trip> _trips = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = await UserSettings.getUserId();
      final trips = await ApiService.getTrips(userId);
      setState(() {
        _trips = trips;
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
      appBar: AppBar(
        title: const Text('Мои поездки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _loadTrips();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTripScreen()),
          );
          if (created == true) {
            _loadTrips();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Ошибка: $_error'),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadTrips,
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTrips,
                  child: _trips.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 200,
                              child: Center(child: Text('Пока нет поездок')),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          itemCount: _trips.length,
                          itemBuilder: (context, index) {
                            final trip = _trips[index];
                            return Card(
                              child: ListTile(
                                title: Text('${trip.city}: ${trip.startPoint} → ${trip.endPoint}'),
                                subtitle: Text(
                                  '${trip.totalKm.toStringAsFixed(1)} км · ${(trip.totalDurationSec / 60).round()} мин',
                                ),
                                trailing: const Icon(Icons.chevron_right),
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
    );
  }
}