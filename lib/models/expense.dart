import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Expense {
  final String label;
  final double amount;
  final DateTime date;
  final int? serverId;

  Expense({
    required this.label,
    required this.amount,
    required this.date,
    this.serverId,
  });

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
        if (serverId != null) 'serverId': serverId,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        label: json['label'],
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.parse(json['date']),
        serverId: json['serverId'] as int?,
      );

  factory Expense.fromApi(Map<String, dynamic> json) {
    final dateRaw = json['dateSabbat'] ?? json['date'];
    return Expense(
      label: json['description']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: dateRaw != null
          ? DateTime.parse(dateRaw.toString())
          : DateTime.now(),
      serverId: _parseApiId(json),
    );
  }

  Expense copyWith({
    String? label,
    double? amount,
    DateTime? date,
    int? serverId,
  }) {
    return Expense(
      label: label ?? this.label,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      serverId: serverId ?? this.serverId,
    );
  }

  static int? _parseApiId(Map<String, dynamic> json) {
    if (json['id'] is int) return json['id'] as int;
    final iri = json['@id']?.toString();
    if (iri == null) return null;
    final match = RegExp(r'/(\d+)$').firstMatch(iri);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}

class ExpenseData {
  List<Expense> expenses = [];

  Future<void> addExpense(String label, double amount, DateTime date) async {
    expenses.add(Expense(label: label, amount: amount, date: date));
    await saveExpenses();
  }

  Future<void> deleteExpense(int index) async {
    if (index >= 0 && index < expenses.length) {
      expenses.removeAt(index);
      await saveExpenses();
    }
  }

  Future<void> replaceAll(List<Expense> next) async {
    expenses = List<Expense>.from(next);
    await saveExpenses();
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

  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expenseList = expenses.map((e) => e.toJson()).toList();
    await prefs.setString('expenses', jsonEncode(expenseList));
  }

  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesString = prefs.getString('expenses');
    if (expensesString != null && expensesString.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(expensesString);
      expenses = decoded.map((json) => Expense.fromJson(json)).toList();
    }
  }
}
