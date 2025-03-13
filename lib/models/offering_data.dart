import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'expense.dart';

class OfferingData {
  Map<String, Map<int, int>> quantities = {};
  Map<String, bool> completionStatus = {};
  final ExpenseData expenseData = ExpenseData();

  OfferingData() {
    for (var offering in offeringTypes) {
      quantities[offering] = {for (var bill in billTypes) bill: 0};
      completionStatus[offering] = false;
    }
    loadData(); // Charger les données au démarrage
  }

  // Charger les données depuis SharedPreferences
  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    for (var offering in offeringTypes) {
      for (var bill in billTypes) {
        quantities[offering]![bill] = prefs.getInt('$offering-$bill') ?? 0;
      }
      completionStatus[offering] =
          prefs.getBool('$offering-completed') ?? false;
    }
    await expenseData.loadExpenses(); // Charger les dépenses
  }

  // Sauvegarder les données dans SharedPreferences (uniquement les offrandes)
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    for (var offering in offeringTypes) {
      for (var bill in billTypes) {
        await prefs.setInt('$offering-$bill', quantities[offering]![bill]!);
      }
      await prefs.setBool('$offering-completed', completionStatus[offering]!);
    }
    // Pas besoin d'appeler _saveExpenses ici, car les dépenses sont gérées séparément
  }

  void updateQuantity(String offering, int bill, int count) {
    quantities[offering]![bill] = count;
    _saveData(); // Sauvegarder après mise à jour
  }

  void toggleCompletion(String offering) {
    completionStatus[offering] = !(completionStatus[offering] ?? false);
    _saveData(); // Sauvegarder après bascule
  }

  double calculateTotalForOffering(String offering) {
    double total = 0;
    quantities[offering]!.forEach((bill, count) {
      total += bill * count;
    });
    return total;
  }

  double calculateGrandTotal() {
    double grandTotal = 0;
    for (var offering in offeringTypes) {
      grandTotal += calculateTotalForOffering(offering);
    }
    return grandTotal;
  }

  Map<String, double> calculateTotalsByCategory() {
    Map<String, double> categoryTotals = {
      'Vola miditra F': 0.0,
      'Vola miditra A': 0.0,
    };

    for (var offering in offeringTypes) {
      String category = offeringCategories[offering]!;
      double offeringTotal = calculateTotalForOffering(offering);
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + offeringTotal;
    }

    return categoryTotals;
  }

  double getTotalExpenses() {
    return expenseData.calculateTotalExpenses();
  }

  // Réinitialiser toutes les données
  Future<void> resetData() async {
    quantities = {
      for (var offering in offeringTypes)
        offering: {for (var bill in billTypes) bill: 0}
    };
    completionStatus = {for (var offering in offeringTypes) offering: false};
    expenseData.expenses = [];
    await _saveData();
    await expenseData
        .saveExpenses(); // Sauvegarder les dépenses après réinitialisation
  }
}
