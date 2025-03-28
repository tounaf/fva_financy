import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'expense.dart';

class OfferingData {
  Map<String, Map<int, int>> quantities = {};
  Map<String, bool> completionStatus = {};
  final ExpenseData expenseData = ExpenseData();
  double ambimbolaTeoAloha = 0.0;
  double volaMiditraAndroany = 0.0; // Nouveau champ modifiable
  double volaNivoaka = 0.0; // Nouveau champ modifiable

  OfferingData() {
    for (var offering in offeringTypes) {
      quantities[offering] = {for (var bill in billTypes) bill: 0};
      completionStatus[offering] = false;
    }
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    for (var offering in offeringTypes) {
      for (var bill in billTypes) {
        quantities[offering]![bill] = prefs.getInt('$offering-$bill') ?? 0;
      }
      completionStatus[offering] =
          prefs.getBool('$offering-completed') ?? false;
    }
    ambimbolaTeoAloha = prefs.getDouble('ambimbola_teo_aloha') ?? 0.0;
    volaMiditraAndroany = prefs.getDouble('vola_miditra_androany') ??
        calculateVolaMiditraF(); // Valeur initiale
    volaNivoaka = prefs.getDouble('vola_nivoaka') ?? 0.0;
    await expenseData.loadExpenses();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    for (var offering in offeringTypes) {
      for (var bill in billTypes) {
        await prefs.setInt('$offering-$bill', quantities[offering]![bill]!);
      }
      await prefs.setBool('$offering-completed', completionStatus[offering]!);
    }
    await prefs.setDouble('ambimbola_teo_aloha', ambimbolaTeoAloha);
    await prefs.setDouble('vola_miditra_androany', volaMiditraAndroany);
    await prefs.setDouble('vola_nivoaka', volaNivoaka);
    await expenseData.saveExpenses();
  }

  void updateQuantity(String offering, int bill, int count) {
    quantities[offering]![bill] = count;
    _saveData();
  }

  void toggleCompletion(String offering) {
    completionStatus[offering] = !(completionStatus[offering] ?? false);
    _saveData();
  }

  void updateAmbimbolaTeoAloha(double value) {
    ambimbolaTeoAloha = value;
    _saveData();
  }

  void updateVolaMiditraAndroany(double value) {
    volaMiditraAndroany = value;
    _saveData();
  }

  void updateVolaNivoaka(double value) {
    volaNivoaka = value;
    _saveData();
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

  // Nouvelle méthode pour "Vola miditra F"
  double calculateVolaMiditraF() {
    Map<String, double> totals = calculateTotalsByCategory();
    return totals['Vola miditra F'] ?? 0.0;
  }

  double getVolaMiditraAndroany() {
    return volaMiditraAndroany; // Valeur modifiable
  }

  double getFitambaranIreo() {
    return ambimbolaTeoAloha + getVolaMiditraAndroany();
  }

  double getVolaNivoaka() {
    return volaNivoaka; // Valeur modifiable
  }

  double getVolaSisaEoAntanana() {
    return getFitambaranIreo() - getVolaNivoaka();
  }

  Future<void> resetData() async {
    quantities = {
      for (var offering in offeringTypes)
        offering: {for (var bill in billTypes) bill: 0}
    };
    completionStatus = {for (var offering in offeringTypes) offering: false};
    ambimbolaTeoAloha = 0.0;
    volaMiditraAndroany =
        calculateVolaMiditraF(); // Réinitialise à Vola miditra F
    volaNivoaka = 0.0;
    expenseData.expenses = [];
    await _saveData();
  }
}
