import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fva_financy/models/offering_data_chart.dart';
import 'package:intl/intl.dart';

// Assurez-vous que l'import de votre modèle est correct ici
// import 'package:votre_projet/models/offering_data_chart.dart'; 

class OfferingChartPage extends StatefulWidget {
  // Correction du type : on utilise la classe d'objet au lieu de Map
  final List<OfferingDataChart> rawData;

  const OfferingChartPage({super.key, required this.rawData});

  @override
  State<OfferingChartPage> createState() => _OfferingChartPageState();
}

class _OfferingChartPageState extends State<OfferingChartPage> {
  int _currentPage = 0;
  final int _itemsPerPage = 7; 

  @override
  Widget build(BuildContext context) {
    // Calcul de la pagination
    int totalPages = (widget.rawData.length / _itemsPerPage).ceil();
    int startIndex = _currentPage * _itemsPerPage;
    int endIndex = (startIndex + _itemsPerPage > widget.rawData.length)
        ? widget.rawData.length
        : startIndex + _itemsPerPage;

    // Extraction des données de la page actuelle
    List<OfferingDataChart> currentData = widget.rawData.sublist(startIndex, endIndex);

    return Scaffold(
      appBar: AppBar(title: const Text("Évolution des Offrandes")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: _buildTitles(currentData),
                  borderData: FlBorderData(
                    show: true, 
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      // Utilisation des données filtrées
                      spots: _generateSpots(currentData),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true, 
                        color: Colors.blue.withOpacity(0.1)
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildPaginationControls(totalPages),
          ],
        ),
      ),
    );
  }

  // Correction : Accès via .totalOffering au lieu de ['totalOffering']
  List<FlSpot> _generateSpots(List<OfferingDataChart> data) {
    return List.generate(data.length, (index) {
      return FlSpot(
        index.toDouble(), 
        data[index].amount.toDouble(), // Utilisation de l'objet
      );
    });
  }

  // Correction : Accès via .date au lieu de ['date']
  FlTitlesData _buildTitles(List<OfferingDataChart> data) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          getTitlesWidget: (value, meta) {
            int index = value.toInt();
            if (index >= 0 && index < data.length) {
              DateTime date = DateTime.parse(data[index].date); // Utilisation de l'objet
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  DateFormat('dd/MM').format(date), 
                  style: const TextStyle(fontSize: 10)
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _currentPage > 0 
              ? () => setState(() => _currentPage--) 
              : null,
          icon: const Icon(Icons.arrow_back_ios),
        ),
        Text(
          "Page ${_currentPage + 1} sur $totalPages",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: _currentPage < totalPages - 1 
              ? () => setState(() => _currentPage++) 
              : null,
          icon: const Icon(Icons.arrow_forward_ios),
        ),
      ],
    );
  }
}