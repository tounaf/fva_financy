import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/offering_data.dart';
import '../screens/offering_counter_screen.dart' as screen;

class ExpenseScreen extends StatefulWidget {
  final OfferingData offeringData;
  final VoidCallback? onDataUpdated;

  const ExpenseScreen({super.key, required this.offeringData, this.onDataUpdated});

  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.offeringData.dateSabbat;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? widget.offeringData.dateSabbat,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitExpense() async {
    if (widget.offeringData.isReadOnly) return;
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final double amount = double.tryParse(_amountController.text) ?? 0.0;
      await widget.offeringData.expenseData.addExpense(
        _labelController.text,
        amount,
        _selectedDate!,
      );
      widget.offeringData.markExpensesDirty();

      widget.onDataUpdated?.call();

      setState(() {
        _labelController.clear();
        _amountController.clear();
        _selectedDate = widget.offeringData.dateSabbat;
      });
    }
  }

  Future<void> _deleteExpense(int index) async {
    if (widget.offeringData.isReadOnly) return;
    await widget.offeringData.expenseData.deleteExpense(index);
    widget.offeringData.markExpensesDirty();

    widget.onDataUpdated?.call();

    if (mounted) {
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
        backgroundColor: screen.vibrantPurple, // Remplacement ici
        title: const Text(
          'Dépenses',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.offeringData.isReadOnly) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueGrey.shade300),
                ),
                child: const Text(
                  'Sabbat déjà validé — dépenses en lecture seule.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
            if (!widget.offeringData.isReadOnly)
            Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Dépense',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Azafady, ampidiro ny anton\'ny dépense';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant   (AR)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Azafady, ampidiro ny montant';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Azafady, ampidiro montant';
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
                            ? 'Date'
                            : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      ElevatedButton(
                        onPressed: () => _selectDate(context),
                        child: const Text('Selectionner date'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              screen.vibrantPurple, // Remplacement ici
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitExpense,
                    child: const Text('Valider dépenses'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: screen.vibrantPurple, // Remplacement ici
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.offeringData.isReadOnly) const SizedBox(height: 24),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.offeringData.expenseData.expenses.length,
              itemBuilder: (context, index) {
                final expense = widget.offeringData.expenseData.expenses[index];
                return ListTile(
                  title: Text(expense.label),
                  subtitle: Text('Date: ${expense.formattedDate}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min, // Important pour que la Row ne prenne pas toute la largeur
                    children: [
                      Text(expense.formattedAmount),
                      if (!widget.offeringData.isReadOnly)
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteExpense(index),
                        ),
                    ],
                  ),
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
                  'Total Dépenses: ${formatAmount(widget.offeringData.getTotalExpenses())}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: screen.vibrantPurple, // Remplacement ici
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
