import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fva_financy/models/offering_data_chart.dart';
import 'package:intl/intl.dart';

class OfferingChartPage extends StatefulWidget {
  final List<OfferingDataChart> rawData;

  const OfferingChartPage({super.key, required this.rawData});

  @override
  State<OfferingChartPage> createState() => _OfferingChartPageState();
}

class _OfferingChartPageState extends State<OfferingChartPage> {
  int _currentPage = 0;
  final int _itemsPerPage = 8; // Ajusté pour que les barres soient larges

  @override
  Widget build(BuildContext context) {
    int totalPages = (widget.rawData.length / _itemsPerPage).ceil();
    int startIndex = _currentPage * _itemsPerPage;
    int endIndex = (startIndex + _itemsPerPage > widget.rawData.length)
        ? widget.rawData.length
        : startIndex + _itemsPerPage;

    List<OfferingDataChart> currentData = widget.rawData.sublist(startIndex, endIndex);

    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildLegend(currentData.isNotEmpty ? currentData[0].fiangonana : ""),
            const SizedBox(height: 20),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxY(currentData), // Calcule le plafond auto
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: _buildTitles(currentData),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(bottom: BorderSide(color: const Color.fromARGB(255, 163, 12, 12))),
                  ),
                  barGroups: _generateBarGroups(currentData),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildPaginationControls(totalPages),
          ],
        ),
    );
  }

  List<BarChartGroupData> _generateBarGroups(List<OfferingDataChart> data) {
    return List.generate(data.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index].amount.toDouble(),
            color: const Color.fromARGB(255, 31, 170, 34), // Bleu indigo de votre image
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  FlTitlesData _buildTitles(List<OfferingDataChart> data) {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60, // Plus d'espace pour le texte incliné
          getTitlesWidget: (value, meta) {
            int index = value.toInt();
            if (index >= 0 && index < data.length) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 10,
                child: Transform.rotate(
                  angle: -0.5, // Inclinaison des dates (en radians)
                  child: Text(
                    data[index].date,
                    style: const TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 60,
          getTitlesWidget: (value, meta) {
            return Text(
              NumberFormat.compact().format(value), // Formate 1000000 en 1M
              style: const TextStyle(fontSize: 10),
            );
          },
        ),
      ),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  double _getMaxY(List<OfferingDataChart> data) {
    if (data.isEmpty) return 100;
    double max = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b).toDouble();
    return max * 1.2; // Ajoute 20% de marge en haut
  }

  // --- UI COMPONENTS ---

  Widget _buildLegend(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 40, height: 15, color: const Color.fromARGB(255, 249, 249, 249)),
        const SizedBox(width: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        const SizedBox(width: 20),
        Text("Période ${_currentPage + 1} / $totalPages"),
        const SizedBox(width: 20),
        IconButton(
          onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}