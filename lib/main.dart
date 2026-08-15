import 'package:flutter/material.dart';
import 'package:fva_financy/screens/fiangonana_selection_screen.dart';
import 'package:fva_financy/theme/app_theme.dart';

void main() {
  runApp(const OfferingCounterApp());
}

class OfferingCounterApp extends StatelessWidget {
  const OfferingCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FVA Financy',
      theme: AppTheme.light(),
      home: const FiangonanaSelectionScreen(),
    );
  }
}
