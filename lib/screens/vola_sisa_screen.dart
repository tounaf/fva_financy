import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/offering_data.dart';
import '../screens/offering_counter_screen.dart' as screen;

class VolaSisaScreen extends StatefulWidget {
  final OfferingData offeringData;

  const VolaSisaScreen({super.key, required this.offeringData});

  @override
  _VolaSisaScreenState createState() => _VolaSisaScreenState();
}

class _VolaSisaScreenState extends State<VolaSisaScreen> {
  final _ambimbolaController = TextEditingController();
  bool _isLoading = true;
  late OfferingData offeringData;

  final _volaMiditraController = TextEditingController();
  final _volaNivoakaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ambimbolaController.text =
        widget.offeringData.ambimbolaTeoAloha.toString();
    _volaMiditraController.text =
        widget.offeringData.volaMiditraAndroany.toString();
    _volaNivoakaController.text = widget.offeringData.volaNivoaka.toString();
    offeringData = OfferingData();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await offeringData.loadData();
    setState(() {
      _isLoading = false;
    });

    _volaMiditraController.text = offeringData.calculateGrandTotal().toString();
  }

  @override
  void dispose() {
    _ambimbolaController.dispose();
    _volaMiditraController.dispose();
    _volaNivoakaController.dispose();
    super.dispose();
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: screen.backgroundColor,
      appBar: AppBar(
        backgroundColor: screen.vibrantPurple,
        title: const Text(
          'Vola Sisa',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ambimbolaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ambimbola teo aloha',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                double amount = double.tryParse(value) ?? 0.0;
                widget.offeringData.updateAmbimbolaTeoAloha(amount);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _volaMiditraController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Vola miditra androany',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                double amount = double.tryParse(value) ?? 0.0;
                widget.offeringData.updateVolaMiditraAndroany(amount);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            _buildSummaryTile('Fitambaran’ireo',
                widget.offeringData.getFitambaranIreo(), screen.deepOrange),
            const SizedBox(height: 8),
            TextField(
              controller: _volaNivoakaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Vola nivoaka',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                double amount = double.tryParse(value) ?? 0.0;
                widget.offeringData.updateVolaNivoaka(amount);
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            _buildSummaryTile(
                'Vola sisa eo an-tanana',
                widget.offeringData.getVolaSisaEoAntanana(),
                screen.vibrantPurple),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTile(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        color: color.withOpacity(0.1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            formatAmount(amount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
