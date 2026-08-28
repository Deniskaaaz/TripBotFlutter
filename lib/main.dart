import 'package:flutter/material.dart';
import 'screens/trip_list_screen.dart';
import 'updater.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Bot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) {
          // Проверяем обновления при запуске
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Updater.checkForUpdate(context);
          });
          return TripListScreen();
        },
      ),
    );
  }
}