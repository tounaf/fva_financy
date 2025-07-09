import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final String apiUrl = 'http://localhost:8000/api/offerings'; // Replace with your Symfony API URL

  Future<void> sendOfferingToApi(String offering) async {
    final quantities = widget.offeringData.quantities[offering]!;
    final total = widget.offeringData.calculateTotalForOffering(offering);
    final prefs = await SharedPreferences.getInstance();
    final fiangonanaId = prefs.getInt('fiangonana_id');

    if (fiangonanaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : ID de fiangonana non trouvé')),
      );
      return;
    }

    final data = {
      'type': offering,
      'quantities': quantities.map((bill, count) => MapEntry(bill.toString(), count)),
      'total': total,
      'fiangonana': "/api/fiangonanas/$fiangonanaId"
    };

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Voulez-vous vraiment synchroniser l\'offrande "$offering" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          widget.offeringData.updateSyncStatus(offering, true); // Persist sync status
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
          final isSynced = widget.offeringData.syncStatus[offering] ?? false;

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