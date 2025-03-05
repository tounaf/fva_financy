import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Assure-toi que ce package est bien importé

// Importer les constantes de couleur
import '../utils/constants.dart' as constants;
import '../screens/offering_counter_screen.dart' as screen;

class OfferingTab extends StatefulWidget {
  final String offering;
  final List<int> billTypes;
  final Map<int, int> quantities;
  final Function(int, int) onQuantityChanged;

  const OfferingTab({
    super.key,
    required this.offering,
    required this.billTypes,
    required this.quantities,
    required this.onQuantityChanged,
  });

  @override
  _OfferingTabState createState() => _OfferingTabState();
}

class _OfferingTabState extends State<OfferingTab> {
  late Map<int, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var bill in widget.billTypes)
        bill: TextEditingController(
          text: widget.quantities[bill]
              .toString(), // Toujours initialiser avec la valeur, même si 0
        )
    };

    // Synchroniser les contrôleurs avec les quantités initiales
    _syncControllersWithQuantities();
  }

  void _syncControllersWithQuantities() {
    widget.billTypes.forEach((bill) {
      _controllers[bill]!.text = widget.quantities[bill].toString();
    });
  }

  @override
  void didUpdateWidget(OfferingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantities != oldWidget.quantities) {
      _syncControllersWithQuantities(); // Mettre à jour les contrôleurs si les quantités changent
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  double calculateTotal() {
    double total = 0;
    widget.quantities.forEach((bill, count) {
      total += bill * count;
    });
    return total;
  }

  // Fonction pour formater les montants avec séparateurs de milliers
  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  // Couleurs personnalisées pour chaque offrande
  Color getOfferingColor(String offering) {
    switch (offering) {
      case 'R1':
        return const Color(0xFF4A90E2); // Bleu
      case 'R2':
        return const Color(0xFF50C878); // Vert
      case 'Manga':
        return const Color(0xFF1E90FF); // Bleu vif (famille de bleu)
      case 'Mena':
        return const Color(0xFFFF4040); // Rouge vif (famille de rouge)
      case 'Mavo':
        return const Color(0xFFFFD700); // Jaune doré (famille de jaune)
      case 'Maitso':
        return const Color(0xFF32CD32); // Vert lime (famille de vert)
      case 'ARIVA':
        return const Color(0xFFD4A017); // Or
      case 'Tapabolana':
        return const Color(0xFF50C878); // Vert (par défaut pour Vola miditra A)
      case 'Sabata Mpitandrina':
        return const Color(0xFF50C878); // Vert (par défaut pour Vola miditra A)
      default:
        return screen.primaryColor; // Bleu par défaut
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: screen.backgroundColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: getOfferingColor(widget.offering).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Total ${widget.offering}: ${formatAmount(calculateTotal())}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: getOfferingColor(widget.offering),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...widget.billTypes.map((bill) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          '$bill AR',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _controllers[bill],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            hintText: '0',
                            filled: true,
                            fillColor: Colors.grey[100],
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: getOfferingColor(widget.offering)),
                            ),
                          ),
                          style: const TextStyle(fontSize: 16),
                          onChanged: (value) {
                            int count = int.tryParse(value) ?? 0;
                            widget.onQuantityChanged(
                                bill, count); // Mettre à jour immédiatement
                            // S'assurer que le contrôleur reflète la valeur numérique
                            _controllers[bill]!.text = count.toString();
                          },
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '${formatAmount((bill * (widget.quantities[bill] ?? 0)).toDouble())}', // Conversion explicite en double
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
