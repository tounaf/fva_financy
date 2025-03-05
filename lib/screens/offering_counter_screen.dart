import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ajouter cet import ici

import '../widgets/offering_tab.dart';
import '../models/offering_data.dart';
import '../utils/constants.dart';

const Color primaryColor = Color(0xFF4A90E2); // Bleu apaisant
const Color accentColor = Color(0xFF50C878); // Vert espoir
const Color backgroundColor = Color(0xFFF5F7FA); // Fond clair
const Color categoryFColor = Color(0xFF4A90E2); // Bleu pour Vola miditra F
const Color categoryAColor = Color(0xFF50C878); // Vert pour Vola miditra A

class OfferingCounterScreen extends StatefulWidget {
  const OfferingCounterScreen({super.key});

  @override
  _OfferingCounterScreenState createState() => _OfferingCounterScreenState();
}

class _OfferingCounterScreenState extends State<OfferingCounterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OfferingData offeringData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: offeringTypes.length, vsync: this);
    offeringData = OfferingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double calculateGrandTotal() {
    return offeringData.calculateGrandTotal();
  }

  // Fonction pour formater les montants avec séparateurs de milliers
  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    // Calculer les totaux par catégorie
    Map<String, double> categoryTotals =
        offeringData.calculateTotalsByCategory();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text(
          'Offering Counter',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: offeringTypes.map((offering) {
            double total = offeringData.calculateTotalForOffering(offering);
            return Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    offering,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatAmount(total),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: offeringTypes.map((offering) {
                return OfferingTab(
                  offering: offering,
                  billTypes: billTypes,
                  quantities: offeringData.quantities[offering]!,
                  onQuantityChanged: (bill, count) {
                    setState(() {
                      offeringData.updateQuantity(offering, bill, count);
                    });
                  },
                );
              }).toList(),
            ),
          ),
          // Afficher les totaux par catégorie avec un design amélioré
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Totals by Category:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryTile(
                      'Vola miditra F',
                      formatAmount(categoryTotals['Vola miditra F']!),
                      categoryFColor,
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryTile(
                      'Vola miditra A',
                      formatAmount(categoryTotals['Vola miditra A']!),
                      categoryAColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Grand total
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                'Grand Total: ${formatAmount(calculateGrandTotal())}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget réutilisable pour chaque catégorie
  Widget _buildCategoryTile(String category, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
