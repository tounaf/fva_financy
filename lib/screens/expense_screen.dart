import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/offering_data.dart'; // Importer OfferingData
import '../screens/offering_counter_screen.dart' as screen;

class ExpenseScreen extends StatefulWidget {
  final OfferingData offeringData; // Ajouter un paramètre pour OfferingData

  const ExpenseScreen({super.key, required this.offeringData});

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitExpense() {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final double amount = double.tryParse(_amountController.text) ?? 0.0;
      widget.offeringData.expenseData.addExpense(
        _labelController.text,
        amount,
        _selectedDate!,
      );
      _labelController.clear();
      _amountController.clear();
      _selectedDate = null;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screen.backgroundColor,
      appBar: AppBar(
        backgroundColor: screen.primaryColor,
        title: const Text(
          'Fitanisana Vola mivoaka',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Antony',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ampidiro ny antony';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Vola (AR)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ampidiro ny vola';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Azafady, tarehimarika ampidirina';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Safidio ny daty'
                              : 'Daty: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        ElevatedButton(
                          onPressed: () => _selectDate(context),
                          child: const Text('Tsindrio ny daty'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: screen.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitExpense,
                      child: const Text('Hanampy vola mivoaka'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: screen.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ListView.builder(
                shrinkWrap: true, // Corrige le problème d'affichage
                physics:
                    const NeverScrollableScrollPhysics(), // Désactive le scroll pour éviter les conflits
                itemCount: widget.offeringData.expenseData.expenses.length,
                itemBuilder: (context, index) {
                  final expense =
                      widget.offeringData.expenseData.expenses[index];
                  return ListTile(
                    title: Text(expense.label),
                    subtitle: Text('Date: ${expense.formattedDate}'),
                    trailing: Text(expense.formattedAmount),
                  );
                },
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
                    'Total vola nivoaka: ${formatAmount(widget.offeringData.getTotalExpenses())}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: screen.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
