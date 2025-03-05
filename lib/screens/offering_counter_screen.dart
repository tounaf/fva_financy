import 'package:flutter/material.dart';
import '../widgets/offering_tab.dart';
import '../models/offering_data.dart';
import '../utils/constants.dart';

// Palette de couleurs personnalisée
const Color primaryColor = Color(0xFF4A90E2); // Bleu apaisant
const Color accentColor = Color(0xFF50C878); // Vert espoir
const Color backgroundColor = Color(0xFFF5F7FA); // Fond clair

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

  @override
  Widget build(BuildContext context) {
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
                    '${total.toStringAsFixed(0)} AR',
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
                'Grand Total: ${calculateGrandTotal().toStringAsFixed(0)} AR',
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
}
