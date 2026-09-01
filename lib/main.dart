import 'package:flutter/material.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'screens/trip_list_screen.dart';
import 'screens/create_trip_screen.dart';
import 'updater.dart';
import 'notifications.dart';
import 'offline_sync_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications(onTap: (payload) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const CreateTripScreen()),
    );
  });

  final backend = FMTCObjectBoxBackend();
  await backend.initialise();

  OfflineSyncService.listenToConnectivity(() async {
    final synced = await OfflineSyncService.syncPendingTrips();
    if (synced > 0) debugPrint('Синхронизировано поездок: $synced');
  });
  await OfflineSyncService.syncPendingTrips();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Bot',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          secondary: Colors.orangeAccent,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.deepPurple,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
      themeMode: ThemeMode.system,
      home: Builder(
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Updater.checkForUpdate(context);
          });
          return const TripListScreen();
        },
      ),
    );
  }
}