import '../utils/constants.dart';
import 'expense.dart'; // Importer le modèle Expense

class OfferingData {
  Map<String, Map<int, int>> quantities = {};
  final ExpenseData expenseData =
      ExpenseData(); // Ajouter une instance d’ExpenseData

  OfferingData() {
    for (var offering in offeringTypes) {
      quantities[offering] = {for (var bill in billTypes) bill: 0};
    }
  }

  void updateQuantity(String offering, int bill, int count) {
    quantities[offering]![bill] = count;
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

  // Calculer le total par catégorie
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

  // Obtenir le total des dépenses
  double getTotalExpenses() {
    return expenseData.calculateTotalExpenses();
  }
}
