import '../utils/constants.dart';
import 'expense.dart';

class OfferingData {
  Map<String, Map<int, int>> quantities = {};
  Map<String, bool> completionStatus = {}; // Nouvelle map pour l’état "terminé"
  final ExpenseData expenseData = ExpenseData();

  OfferingData() {
    for (var offering in offeringTypes) {
      quantities[offering] = {for (var bill in billTypes) bill: 0};
      completionStatus[offering] = false; // Par défaut, non terminé
    }
  }

  void updateQuantity(String offering, int bill, int count) {
    quantities[offering]![bill] = count;
  }

  void toggleCompletion(String offering) {
    completionStatus[offering] = !(completionStatus[offering] ?? false);
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
    ;
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
}
