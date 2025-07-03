import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/offering_tab.dart';
import '../models/offering_data.dart';
import '../utils/constants.dart';
import 'expense_screen.dart';
import 'vola_sisa_screen.dart';

const Color vibrantPurple = Color.fromRGBO(156, 24, 196, 1);
const Color neonGreen = Color.fromRGBO(57, 255, 20, 1);
const Color deepOrange = Color.fromRGBO(255, 87, 34, 1);
const Color backgroundColor = Color(0xFFF5F7FA);
const Color expenseRed = Color.fromRGBO(255, 51, 102, 1);

class OfferingCounterScreen extends StatefulWidget {
  const OfferingCounterScreen({super.key});

  @override
  _OfferingCounterScreenState createState() => _OfferingCounterScreenState();
}

class _OfferingCounterScreenState extends State<OfferingCounterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OfferingData offeringData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: offeringTypes.length + 2, vsync: this);
    offeringData = OfferingData();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await offeringData.loadData();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double calculateGrandTotal() {
    return offeringData.calculateGrandTotal() + offeringData.getTotalExpenses();
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, double> categoryTotals =
        offeringData.calculateTotalsByCategory();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: vibrantPurple,
        title: const Text(
          'Fanisam-bola sy depanse isan-tsabata',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent,),
            onPressed: () async {
              await offeringData.resetData();
              setState(() {});
            },
            tooltip: 'Réinitialiser',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
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
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Totals by Category:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: vibrantPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryTile(
                      'Vola miditra F',
                      formatAmount(categoryTotals['Vola miditra F']!),
                      neonGreen,
                    ),
                    const SizedBox(height: 6),
                    _buildCategoryTile(
                      'Vola miditra A',
                      formatAmount(categoryTotals['Vola miditra A']!),
                      deepOrange,
                    ),
                    const SizedBox(height: 6),
                    _buildCategoryTile(
                      'Total Expenses',
                      formatAmount(offeringData.getTotalExpenses()),
                      expenseRed,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Text(
                'Grand Total: ${formatAmount(calculateGrandTotal())}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: vibrantPurple,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: vibrantPurple,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    tabs: [
                      ...offeringTypes.map((offering) {
                        double total =
                            offeringData.calculateTotalForOffering(offering);
                        bool isCompleted =
                            offeringData.completionStatus[offering]!;
                        return Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
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
                              if (isCompleted) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Expenses',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formatAmount(offeringData.getTotalExpenses()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Vola Sisa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              formatAmount(
                                  offeringData.getVolaSisaEoAntanana()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height - 300,
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      ...offeringTypes.map((offering) {
                        return OfferingTab(
                          offering: offering,
                          billTypes: billTypes,
                          quantities: offeringData.quantities[offering]!,
                          onQuantityChanged: (bill, count) {
                            setState(() {
                              offeringData.updateQuantity(
                                  offering, bill, count);
                            });
                          },
                          isCompleted: offeringData.completionStatus[offering]!,
                          onToggleCompletion: () {
                            setState(() {
                              offeringData.toggleCompletion(offering);
                            });
                          },
                        );
                      }).toList(),
                      ExpenseScreen(offeringData: offeringData),
                      VolaSisaScreen(offeringData: offeringData),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(String category, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            category,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
