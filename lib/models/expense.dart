import 'package:intl/intl.dart';

class Expense {
  final String label; // Libellé de la dépense
  final double amount; // Montant
  final DateTime date; // Date

  Expense({required this.label, required this.amount, required this.date});

  // Méthode pour formater la date
  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Méthode pour formater le montant (réutiliser la fonction existante)
  String get formattedAmount {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }
}

class ExpenseData {
  List<Expense> expenses = [];

  void addExpense(String label, double amount, DateTime date) {
    expenses.add(Expense(label: label, amount: amount, date: date));
  }

  double calculateTotalExpenses() {
    return expenses.fold(0, (total, expense) => total + expense.amount);
  }

  // Optionnel : filtrer les dépenses par date ou libellé si besoin
  List<Expense> getExpensesByDate(DateTime date) {
    return expenses
        .where((expense) =>
            expense.date.year == date.year &&
            expense.date.month == date.month &&
            expense.date.day == date.day)
        .toList();
  }
}
