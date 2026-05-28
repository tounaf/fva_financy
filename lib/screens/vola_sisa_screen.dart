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

  final _volaMiditraController = TextEditingController();
  final _volaNivoakaController = TextEditingController();

  bool _ambimbolaLocked = false;

  @override
  void initState() {
    super.initState();
    _refreshFields();
  }

  void _refreshFields() {
    _ambimbolaLocked = widget.offeringData.ambimbolaTeoAloha != 0.0;
    _ambimbolaController.text =
        widget.offeringData.ambimbolaTeoAloha.toString();
    _volaMiditraController.text =
        widget.offeringData.calculateVolaMiditraF().toString();
    _volaNivoakaController.text =
        widget.offeringData.getTotalExpenses().toString();
  }

  @override
  void didUpdateWidget(covariant VolaSisaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshFields();
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
              readOnly: _ambimbolaLocked,
              decoration: InputDecoration(
                labelText: 'Ambimbola teo aloha',
                border: const OutlineInputBorder(),
                fillColor: _ambimbolaLocked ? Colors.grey[100] : null,
                filled: _ambimbolaLocked,
                suffixIcon: _ambimbolaLocked
                    ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey)
                    : null,
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
              readOnly: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Vola miditra androany',
                fillColor: Colors.grey[100],
                filled: true,
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
              readOnly: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Vola nivoaka',
                fillColor: Colors.grey[100],
                filled: true,
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
