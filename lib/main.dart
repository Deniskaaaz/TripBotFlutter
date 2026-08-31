import 'package:flutter/material.dart';
import 'screens/trip_list_screen.dart';
import 'screens/create_trip_screen.dart';
import 'updater.dart';
import 'notifications.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications(onTap: (payload) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const CreateTripScreen()),
    );
  });
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
      builder: (context, child) {
        // Уменьшаем масштаб текста во всём приложении
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(0.9),
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.compact, // уплотняем элементы
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
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), // меньше отступы
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
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
        listTileTheme: const ListTileThemeData(
          iconColor: Colors.deepPurple,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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