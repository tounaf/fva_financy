import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offering_data.dart';
import '../utils/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SyncScreen extends StatefulWidget {
  final OfferingData offeringData;

  const SyncScreen({super.key, required this.offeringData});

  @override
  _SyncScreenState createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final String offeringApiUrl = 'https://fva-vitaonyasany.mg/admin-api/public/index.php/api/offerings';
  final String expenseApiUrl = 'https://fva-vitaonyasany.mg/admin-api/public/index.php/api/expenses/batch';
  final String validationApiUrl = 'https://fva-vitaonyasany.mg/admin-api/public/index.php/api/sabbat-validations';
  
  // final String offeringApiUrl = 'http://192.168.1.68:8000/api/offerings';
  // final String expenseApiUrl = 'http://192.168.1.68:8000/api/expenses/batch';
  // final String validationApiUrl = 'http://192.168.1.68:8000/api/sabbat-validations';
  

  final Map<String, bool> _isLoading = {};
  File? _bordereauImage;
  bool _isFinalizing = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _bordereauImage = File(pickedFile.path);
      });
    }
  }

  Future<void> finalizeSabbat() async {
    if (_bordereauImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez prendre une photo du bordereau signé')),
      );
      return;
    }

    setState(() => _isFinalizing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final fiangonanaId = prefs.getInt('fiangonana_id');
      
      if (fiangonanaId == null) throw Exception('ID Fiangonana manquant');

      List<int> imageBytes = await _bordereauImage!.readAsBytes();
      String base64Image = "data:image/jpeg;base64,${base64Encode(imageBytes)}";

      final data = {
        'imageName': base64Image,
        'dateSabbat': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'fiangonana': "/api/fiangonanas/$fiangonanaId"
      };

      final response = await http.post(
        Uri.parse(validationApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Sabbat finalisé et envoyé pour contrôle !')),
        );
        setState(() => _bordereauImage = null);
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la finalisation : $e')),
      );
    } finally {
      setState(() => _isFinalizing = false);
    }
  }

  Future<void> sendOfferingToApi(String offering) async {
    setState(() => _isLoading[offering] = true);

    final quantities = widget.offeringData.quantities[offering]!;
    final total = widget.offeringData.calculateTotalForOffering(offering);
    final prefs = await SharedPreferences.getInstance();
    final fiangonanaId = prefs.getInt('fiangonana_id');

    if (fiangonanaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur ID Fiangonana')));
      setState(() => _isLoading[offering] = false);
      return;
    }

    final data = {
      'type': offering,
      'quantities': quantities.map((bill, count) => MapEntry(bill.toString(), count)),
      'total': total,
      'fiangonana': "/api/fiangonanas/$fiangonanaId"
    };

    final confirm = await _showConfirmDialog('Voulez-vous synchroniser l\'offrande "$offering" ?');
    if (confirm != true) {
      setState(() => _isLoading[offering] = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(offeringApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          widget.offeringData.updateSyncStatus(offering, true);
          _isLoading[offering] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$offering synchronisé')));
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading[offering] = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur de synchronisation')));
    }
  }

  Future<void> sendExpensesToApi() async {
    setState(() => _isLoading['expenses'] = true);

    final expenses = widget.offeringData.expenseData.expenses;
    final prefs = await SharedPreferences.getInstance();
    final fiangonanaId = prefs.getInt('fiangonana_id');

    final data = {
      'expenses': expenses.map((e) => {
        'description': e.label,
        'amount': e.amount,
        'date': DateFormat('yyyy-MM-dd').format(e.date),
        'fiangonana': "/api/fiangonanas/$fiangonanaId"
      }).toList()
    };

    final confirm = await _showConfirmDialog('Synchroniser les dépenses ?');
    if (confirm != true) {
      setState(() => _isLoading['expenses'] = false);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(expenseApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        setState(() {
          widget.offeringData.updateExpensesSyncStatus(true);
          _isLoading['expenses'] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dépenses synchronisées')));
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() => _isLoading['expenses'] = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur dépenses')));
    }
  }

  Future<bool?> _showConfirmDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(156, 24, 196, 1),
        title: const Text('Synchronisation global', style: TextStyle(color: Colors.white)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: offeringTypes.length + 2, // +1 pour Dépenses, +1 pour Finalisation
        itemBuilder: (context, index) {
          if (index < offeringTypes.length) {
            return _buildOfferingCard(offeringTypes[index]);
          } else if (index == offeringTypes.length) {
            return _buildExpenseCard();
          } else {
            return _buildFinalizeSection();
          }
        },
      ),
    );
  }

  Widget _buildOfferingCard(String offering) {
    final total = widget.offeringData.calculateTotalForOffering(offering);
    final isSynced = widget.offeringData.syncStatus[offering] ?? false;
    final isLoading = _isLoading[offering] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(offering, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(formatAmount(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(156, 24, 196, 1))),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: isSynced || isLoading ? null : () => sendOfferingToApi(offering),
              icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(isSynced ? Icons.check_circle : Icons.sync),
              label: Text(isSynced ? 'Synchronisé' : 'Synchroniser'),
              style: ElevatedButton.styleFrom(backgroundColor: isSynced ? Colors.grey : const Color.fromRGBO(156, 24, 196, 1), foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard() {
    final totalExpenses = widget.offeringData.getTotalExpenses();
    final isSynced = widget.offeringData.expensesSyncStatus;
    final isLoading = _isLoading['expenses'] ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dépenses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(formatAmount(totalExpenses), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(156, 24, 196, 1))),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: isSynced || isLoading ? null : () => sendExpensesToApi(),
              icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(isSynced ? Icons.check_circle : Icons.sync),
              label: Text(isSynced ? 'Synchronisé' : 'Synchroniser'),
              style: ElevatedButton.styleFrom(backgroundColor: isSynced ? Colors.grey : const Color.fromRGBO(156, 24, 196, 1), foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalizeSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        children: [
          const Text("FINALISATION DU SABBAT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          if (_bordereauImage != null) 
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Image.file(_bordereauImage!, height: 150),
            ),
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.camera_alt),
            label: Text(_bordereauImage == null ? "Prendre photo Bordereau" : "Changer la photo"),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: _isFinalizing ? null : finalizeSabbat,
              child: _isFinalizing 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text("VALIDER ET FERMER LE SABBAT", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}