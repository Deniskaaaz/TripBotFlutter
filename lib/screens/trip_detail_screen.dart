import 'package:flutter/material.dart';

class TripDetailScreen extends StatelessWidget {
  final int tripId;

  const TripDetailScreen({Key? key, required this.tripId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали поездки'),
      ),
      body: Center(
        child: Text(
          'Детали поездки ID: $tripId',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}