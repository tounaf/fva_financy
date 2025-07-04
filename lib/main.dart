import 'package:flutter/material.dart';
import 'package:fva_financy/screens/fiangonana_selection_screen.dart';

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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(156, 24, 196, 1), // vibrantPurple
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const FiangonanaSelectionScreen(),
    );
  }
}