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
  final String offeringApiUrl = 'https://fva-vitaonyasany.mg/admin-api/public/index.php/api/offerings';
  //final String offeringApiUrl = 'http://localhost:8000/api/offerings';
  final String expenseApiUrl = 'https://fva-vitaonyasany.mg/admin-api/public/index.php/api/expenses/batch';
  //final String expenseApiUrl = 'http://localhost:8000/api/expenses/batch';
  final Map<String, bool> _isLoading = {};

  Future<void> sendOfferingToApi(String offering) async {
    setState(() {
      _isLoading[offering] = true;
    });

    final quantities = widget.offeringData.quantities[offering]!;
    final total = widget.offeringData.calculateTotalForOffering(offering);
    final prefs = await SharedPreferences.getInstance();
    final fiangonanaId = prefs.getInt('fiangonana_id');

    if (fiangonanaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : ID de fiangonana non trouvé')),
      );
      setState(() {
        _isLoading[offering] = false;
      });
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
      setState(() {
        _isLoading[offering] = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(offeringApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          widget.offeringData.updateSyncStatus(offering, true);
          _isLoading[offering] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$offering synchronisé avec succès')),
        );
      } else {
        setState(() {
          _isLoading[offering] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la synchronisation de $offering')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading[offering] = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau : $e')),
      );
    }
  }

  Future<void> sendExpensesToApi() async {
    setState(() {
      _isLoading['expenses'] = true;
    });

    final expenses = widget.offeringData.expenseData.expenses;
    final prefs = await SharedPreferences.getInstance();
    final fiangonanaId = prefs.getInt('fiangonana_id');

    if (fiangonanaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur : ID de fiangonana non trouvé')),
      );
      setState(() {
        _isLoading['expenses'] = false;
      });
      return;
    }

    final data = {
          'expenses': expenses.map((expense) => {
            'description': expense.label,
            'amount': expense.amount,
            'date': DateFormat('yyyy-MM-dd').format(expense.date),
            'fiangonana': "/api/fiangonanas/$fiangonanaId"
          }).toList()
        };


    print(data);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment synchroniser les dépenses ?'),
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
      setState(() {
        _isLoading['expenses'] = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(expenseApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          widget.offeringData.updateExpensesSyncStatus(true);
          _isLoading['expenses'] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dépenses synchronisées avec succès')),
        );
      } else {
        setState(() {
          _isLoading['expenses'] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la synchronisation des dépenses')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading['expenses'] = false;
      });
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
          'Synchronisation des Offrandes et Dépenses',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: offeringTypes.length + 1,
        itemBuilder: (context, index) {
          if (index < offeringTypes.length) {
            final offering = offeringTypes[index];
            final quantities = widget.offeringData.quantities[offering]!;
            final total = widget.offeringData.calculateTotalForOffering(offering);
            final isSynced = widget.offeringData.syncStatus[offering] ?? false;
            final isLoading = _isLoading[offering] ?? false;

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
                      onPressed: isSynced || isLoading
                          ? null
                          : () async {
                              await sendOfferingToApi(offering);
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(isSynced ? Icons.check_circle : Icons.sync),
                      label: Text(isSynced ? 'Synchronisé' : isLoading ? 'Synchronisation...' : 'Synchroniser'),
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
          } else {
            final totalExpenses = widget.offeringData.getTotalExpenses();
            final isSynced = widget.offeringData.expensesSyncStatus;
            final isLoading = _isLoading['expenses'] ?? false;

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
                        const Text(
                          'Dépenses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          formatAmount(totalExpenses),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(156, 24, 196, 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...widget.offeringData.expenseData.expenses
                        .map((expense) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(expense.label),
                                  Text(formatAmount(expense.amount)),
                                ],
                              ),
                            ))
                        .toList(),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: isSynced || isLoading
                          ? null
                          : () async {
                              await sendExpensesToApi();
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(isSynced ? Icons.check_circle : Icons.sync),
                      label: Text(isSynced ? 'Synchronisé' : isLoading ? 'Synchronisation...' : 'Synchroniser'),
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
          }
        },
      ),
    );
  }
}