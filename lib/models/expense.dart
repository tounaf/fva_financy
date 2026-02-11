import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Expense {
  final String label;
  final double amount;
  final DateTime date;

  Expense({required this.label, required this.amount, required this.date});

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String get formattedAmount {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        label: json['label'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
      );
}

class ExpenseData {
  List<Expense> expenses = [];

  Future<void> addExpense(String label, double amount, DateTime date) async {
    expenses.add(Expense(label: label, amount: amount, date: date));
    await saveExpenses(); // Sauvegarder après ajout
  }

  Future<void> deleteExpense(int index) async {
    if (index >= 0 && index < expenses.length) {
      expenses.removeAt(index);
      await saveExpenses(); // Sauvegarder après suppression
    }
  }

  double calculateTotalExpenses() {
    return expenses.fold(0, (total, expense) => total + expense.amount);
  }

  List<Expense> getExpensesByDate(DateTime date) {
    return expenses
        .where((expense) =>
            expense.date.year == date.year &&
            expense.date.month == date.month &&
            expense.date.day == date.day)
        .toList();
  }

  // Sauvegarder les dépenses dans SharedPreferences
  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expenseList = expenses.map((e) => e.toJson()).toList();
    await prefs.setString('expenses', jsonEncode(expenseList));
  }

  // Charger les dépenses depuis SharedPreferences
  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesString = prefs.getString('expenses');
    if (expensesString != null && expensesString.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(expensesString);
      expenses = decoded.map((json) => Expense.fromJson(json)).toList();
    }
  }
}
