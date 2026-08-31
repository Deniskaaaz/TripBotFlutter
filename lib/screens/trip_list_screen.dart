import 'package:flutter/material.dart';
import '../api_service.dart';
import '../models/trip.dart';
import '../user_settings.dart';
import '../active_trip_storage.dart';
import '../notifications.dart';
import 'create_trip_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';
import 'trip_detail_screen.dart';
import 'admin_login_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({Key? key}) : super(key: key);

  @override
  _TripListScreenState createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  List<Trip> _trips = [];
  bool _isLoading = true;
  String? _error;

  int _tripsCount = 0;
  double _totalKm = 0.0;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _checkActiveTripAndNotify();
  }

  Future<void> _checkActiveTripAndNotify() async {
    final activeTrip = await ActiveTripStorage.loadActiveTrip();
    if (activeTrip != null) {
      await showActiveTripNotification();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final userId = await UserSettings.getUserId();
      final tripsFuture = ApiService.getTrips(userId);
      final statsFuture = ApiService.getStats(userId);

      final results = await Future.wait([tripsFuture, statsFuture]);

      setState(() {
        _trips = results[0] as List<Trip>;
        final stats = results[1] as Map<String, dynamic>;
        _tripsCount = stats['trips_count'] as int? ?? 0;
        _totalKm = (stats['total_km'] as num?)?.toDouble() ?? 0.0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Trip> get _filteredTrips {
    if (_searchQuery.isEmpty) return _trips;
    final query = _searchQuery.toLowerCase();
    return _trips.where((trip) {
      return trip.city.toLowerCase().contains(query) ||
          trip.startPoint.toLowerCase().contains(query) ||
          trip.endPoint.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Ошибка: $_error'),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 180,
                      pinned: true,
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      flexibleSpace: FlexibleSpaceBar(
                        title: const Text('Мои поездки'),
                        centerTitle: true,
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.deepPurple, Colors.purple.shade800],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.route_rounded, color: Colors.white70, size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_totalKm.toStringAsFixed(1)} км · $_tripsCount поездок',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.bar_chart_rounded),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const StatsScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.admin_panel_settings_rounded),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminLoginScreen()),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_rounded),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsScreen()),
                            );
                            _loadData();
                          },
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Поиск по городу или адресу',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(8),
                      sliver: _filteredTrips.isEmpty
                          ? const SliverFillRemaining(
                              child: Center(child: Text('Ничего не найдено')),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final trip = _filteredTrips[index];
                                  return _TripCard(
                                    trip: trip,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TripDetailScreen(trip: trip),
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: _filteredTrips.length,
                              ),
                            ),
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
            _loadData();
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.route_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${trip.city}: ${trip.startPoint} → ${trip.endPoint}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.totalKm.toStringAsFixed(1)} км · ${(trip.totalDurationSec / 60).round()} мин',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.deepPurple),
            ],
          ),
        ),
      ),
    );
  }
}