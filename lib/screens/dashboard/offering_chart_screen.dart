import 'package:flutter/material.dart';
import 'package:fva_financy/models/offering_data_chart.dart';
import 'package:fva_financy/screens/dashboard/offering_chart_page.dart';

class OfferingChartScreen extends StatefulWidget {
  @override
  _OfferingChartScreenState createState() => _OfferingChartScreenState();
}

class _OfferingChartScreenState extends State<OfferingChartScreen> {
  late Future<List<OfferingDataChart>> futureOfferings;

  @override
  void initState() {
    super.initState();
    futureOfferings = fetchOfferingsChart(); // Appel initial
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rapport des Offrandes")),
      body: FutureBuilder<List<OfferingDataChart>>(
        future: futureOfferings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Erreur: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Aucune donnée disponible"));
          }

          // Une fois les données reçues, on affiche le graphique paginé
          return OfferingChartPage(rawData: snapshot.data!);
        },
      ),
    );
  }
}