import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offering_data.dart';
import '../screens/offering_counter_screen.dart' as screen;
import 'package:http/http.dart' as http;

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

  bool _ambimbolaLocked = false;

  @override
  void initState() {
    super.initState();

    _ambimbolaLocked = widget.offeringData.ambimbolaTeoAloha != 0.0;

    _ambimbolaController.text =
        widget.offeringData.ambimbolaTeoAloha.toString();
    _volaMiditraController.text =
        widget.offeringData.calculateVolaMiditraF().toString();
    _volaNivoakaController.text = widget.offeringData.getTotalExpenses().toString();
    offeringData = OfferingData();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await offeringData.loadData();
    await _fetchAmbimbolaTeoAloha();

    setState(() {
      _isLoading = false;
    });

  }

  @override
  void dispose() {
    _ambimbolaController.dispose();
    _volaMiditraController.dispose();
    _volaNivoakaController.dispose();
    super.dispose();
  }

  Future<void> _fetchAmbimbolaTeoAloha() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fiangonanaId = prefs.getInt('fiangonana_id');

      if (fiangonanaId == null) return;

      final uri = Uri.parse(
        'https://fva-vitaonyasany.mg/admin-api/public/index.php/api/sabbat_validations'
        '?fiangonana=$fiangonanaId&order[dateSabbat]=desc&itemsPerPage=1',
      );

      final response = await http.get(uri, headers: {'Accept': 'application/ld+json'});

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final members = json['member'] as List;

        if (members.isNotEmpty) {
          final lastValidation = members.first;
          final apiValue = (lastValidation['volaSisaEoAntanana'] as num?)?.toDouble() ?? 0.0;

          if (apiValue != 0.0) {
            // Priorité à la valeur API
            widget.offeringData.updateAmbimbolaTeoAloha(apiValue);
            _ambimbolaController.text = apiValue.toString();
            _ambimbolaLocked = true;
          } else {
            // Fallback sur la valeur locale
            _ambimbolaLocked = widget.offeringData.ambimbolaTeoAloha != 0.0;
          }
        } else {
          _ambimbolaLocked = widget.offeringData.ambimbolaTeoAloha != 0.0;
        }
      }
    } catch (e) {
      // En cas d'erreur réseau, fallback sur la valeur locale
      _ambimbolaLocked = widget.offeringData.ambimbolaTeoAloha != 0.0;
    }

    setState(() {});
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
