import 'package:flutter/material.dart';
import 'package:fva_financy/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/offering_data.dart';

class ExpenseScreen extends StatefulWidget {
  final OfferingData offeringData;
  final VoidCallback? onDataUpdated;
  final bool embedded;

  const ExpenseScreen({
    super.key,
    required this.offeringData,
    this.onDataUpdated,
    this.embedded = false,
  });

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
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
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitExpense() async {
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
    final ok = await FvaConfirm.show(
      context,
      title: 'Supprimer ?',
      message: 'Ity dépense ity dia hofafana.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!ok) return;
    await widget.offeringData.expenseData.deleteExpense(index);
    widget.offeringData.markExpensesDirty();
    widget.onDataUpdated?.call();
    if (mounted) setState(() {});
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
    final expenses = widget.offeringData.expenseData.expenses;
    final dateLabel = _selectedDate == null
        ? '—'
        : DateFormat('dd/MM/yyyy').format(_selectedDate!);

    final body = ListView(
      padding: EdgeInsets.fromLTRB(widget.embedded ? 0 : 16, 0, widget.embedded ? 0 : 16, 16),
      children: [
        FvaCard(
          accent: AppColors.expense,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter une dépense',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Dépense',
                    prefixIcon: Icon(Icons.receipt_long_outlined, size: 20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Azafady, ampidiro ny anton\'ny dépense';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (AR)',
                    prefixIcon: Icon(Icons.payments_outlined, size: 20),
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
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _selectDate(context),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today, size: 20),
                    ),
                    child: Text(
                      dateLabel,
                      style: GoogleFonts.poppins(fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FvaPrimaryButton(
                  label: 'Valider dépenses',
                  icon: Icons.check,
                  color: AppColors.expense,
                  onPressed: _submitExpense,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (expenses.isEmpty)
          const FvaEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Tsy misy dépense',
            subtitle: 'Ampidiro ny fandaniana etsy ambony',
          )
        else
          ...List.generate(expenses.length, (index) {
            final expense = expenses[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FvaCard(
                accent: AppColors.expense,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(expense.label,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600)),
                          Text(
                            expense.formattedDate,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(expense.formattedAmount,
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.expense),
                      onPressed: () => _deleteExpense(index),
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 8),
        FvaSummaryTile(
          title: 'Total Dépenses',
          value: formatAmount(widget.offeringData.getTotalExpenses()),
          accent: AppColors.expense,
          emphasized: true,
        ),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dépenses')),
      body: body,
    );
  }
}
