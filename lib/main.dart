import 'package:flutter/material.dart';
import 'package:fva_financy/screens/fiangonana_selection_screen.dart';
import 'package:fva_financy/widgets/auto_update_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

void main() {
  runApp(const OfferingCounterApp());
}

class OfferingCounterApp extends StatelessWidget {
  const OfferingCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fanisam-bola Fiangonana',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(156, 24, 196, 1),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      // On lance l'écran de sélection
      home: const FiangonanaSelectionScreen(),
    );
  }
}