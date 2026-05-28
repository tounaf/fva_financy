import 'dart:convert';
import 'package:fva_financy/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfferingDataChart {
  final String fiangonana;
  final double amount;
  final String date;

  OfferingDataChart({required this.fiangonana, required this.amount, required this.date});

  factory OfferingDataChart.fromJson(Map<String, dynamic> json) {
    return OfferingDataChart(
      fiangonana: json['fiangonanaName'],
      amount: json['totalOffering'].toDouble(),
      date: json['date'],
    );
  }
}

Future<List<OfferingDataChart>> fetchOfferingsChart() async {
  final shardPreference = await SharedPreferences.getInstance();
  final int? fiangonanaId = shardPreference.getInt('fiangonana_id');
  if (fiangonanaId != null) {
    final response = await ApiService().fetchOfferingsChart(fiangonanaId);
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => OfferingDataChart.fromJson(item)).toList();
    } else {
      throw Exception('Échec du chargement des données');
    }
  } else {
    throw Exception('Fiangonana ID non trouvé');
  } 
}