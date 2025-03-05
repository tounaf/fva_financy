import 'package:flutter/material.dart';
import 'screens/offering_counter_screen.dart';

void main() {
  runApp(const OfferingCounterApp());
}

class OfferingCounterApp extends StatelessWidget {
  const OfferingCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offering Counter',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const OfferingCounterScreen(),
    );
  }
}
