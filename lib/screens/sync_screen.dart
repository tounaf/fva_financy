import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/offering_data.dart';
import '../utils/constants.dart';
import 'dart:convert';

class SyncScreen extends StatefulWidget {
  final OfferingData offeringData;

  const SyncScreen({super.key, required this.offeringData});

  @override
  _SyncScreenState createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final String apiUrl = 'http://your-api-url/api/offerings'; // Replace with your Symfony API URL
  Map<String, bool> syncStatus = {}; // Track sync status for each offering

  @override
  void initState() {
    super.initState();
    // Initialize sync status for each offering
    for (var offering in offeringTypes) {
      syncStatus[offering] = false;
    }
  }

  Future<void> sendOfferingToApi(String offering) async {
    final quantities = widget.offeringData.quantities[offering]!;
    final total = widget.offeringData.calculateTotalForOffering(offering);

    final data = {
      'type': offering,
      'quantities': quantities.map((bill, count) => MapEntry(bill.toString(), count)),
      'total': total,
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          syncStatus[offering] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$offering synchronisé avec succès')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la synchronisation de $offering')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau : $e')),
      );
    }
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(156, 24, 196, 1),
        title: const Text(
          'Synchronisation des Offrandes',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: offeringTypes.length,
        itemBuilder: (context, index) {
          final offering = offeringTypes[index];
          final quantities = widget.offeringData.quantities[offering]!;
          final total = widget.offeringData.calculateTotalForOffering(offering);
          final isSynced = syncStatus[offering] ?? false;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        offering,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        formatAmount(total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(156, 24, 196, 1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...quantities.entries
                      .where((entry) => entry.value > 0)
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${formatAmount(entry.key.toDouble())}:'),
                                Text('${entry.value} unité(s)'),
                              ],
                            ),
                          ))
                      .toList(),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: isSynced
                        ? null
                        : () async {
                            await sendOfferingToApi(offering);
                          },
                    icon: Icon(isSynced ? Icons.check_circle : Icons.sync),
                    label: Text(isSynced ? 'Synchronisé' : 'Synchroniser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSynced
                          ? Colors.grey
                          : const Color.fromRGBO(156, 24, 196, 1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}