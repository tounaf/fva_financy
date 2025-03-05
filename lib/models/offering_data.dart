import '../utils/constants.dart';

class OfferingData {
  Map<String, Map<int, int>> quantities = {};

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
}
