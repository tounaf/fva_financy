import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class VersementScreen extends StatefulWidget {
  final int sabbatValidationId;
  final double montantSisa; // Récupéré automatiquement du Sabbat sélectionné

  const VersementScreen({
    super.key,
    required this.sabbatValidationId,
    required this.montantSisa,
  });

  @override
  State<VersementScreen> createState() => _VersementScreenState();
}

class _VersementScreenState extends State<VersementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();
  final _fraisController = TextEditingController(text: '0');
  
  String _typeVersement = 'MOBILE_MONEY';
  DateTime _dateVersement = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _refController.dispose();
    _fraisController.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateVersement,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(), // On ne peut pas verser dans le futur
      locale: const Locale("fr", "FR"),
    );
    if (picked != null && picked != _dateVersement) {
      setState(() {
        _dateVersement = picked;
      });
    }
  }

  Future<void> _soumettreVersement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    const String apiUrl = 'https://fva-vitaonyasany.mg/admin-api/public/index.php/api/versements';
    
    // Structure exacte pour API Platform (Symfony)
    final Map<String, dynamic> payload = {
      'type': _typeVersement,
      'montant': widget.montantSisa,
      'reference': _refController.text.trim(),
      'frais': double.tryParse(_fraisController.text) ?? 0.0,
      'sabbatValidation': '/api/sabbat_validations/${widget.sabbatValidationId}',
      // Optionnel : ajouter la date effective si vous l'avez ajoutée à l'entité
      // 'dateVersement': _dateVersement.toIso8601String(), 
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar("Erreur : ${error['detail'] ?? 'Echec de l\'envoi'}", isError: true);
      }
    } catch (e) {
      _showSnackBar("Erreur réseau : $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: const Text(
          "Le versement a été enregistré et lié au Sabbat avec succès.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Ferme le dialogue
                Navigator.of(context).pop(); // Retourne à la liste des Sabbats à verser
              },
              child: const Text("TERMINER"),
            ),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Détails du Versement", style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF673AB7), // Vibrant Purple
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Récapitulatif du montant
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Text("MONTANT À VERSER", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 5),
                    Text(
                      "${widget.montantSisa.toStringAsFixed(0)} Ar",
                      style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Sélecteur de Date
              ListTile(
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                leading: const Icon(Icons.calendar_today, color: Colors.deepPurple),
                title: const Text("Date effective du versement"),
                subtitle: Text("${_dateVersement.day}/${_dateVersement.month}/${_dateVersement.year}"),
                onTap: _choisirDate,
              ),
              const SizedBox(height: 25),

              // Mode de versement
              const Text("Mode de versement", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'MOBILE_MONEY', label: Text('M-Money'), icon: Icon(Icons.smartphone)),
                  ButtonSegment(value: 'CASH', label: Text('Espèces'), icon: Icon(Icons.money)),
                ],
                selected: {_typeVersement},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _typeVersement = newSelection.first);
                },
              ),
              const SizedBox(height: 25),

              // Référence ou Porteur
              TextFormField(
                controller: _refController,
                decoration: InputDecoration(
                  labelText: _typeVersement == 'MOBILE_MONEY' ? 'Référence Transaction (ID)' : 'Nom du porteur (Trésorier...)',
                  border: const OutlineInputBorder(),
                  prefixIcon: Icon(_typeVersement == 'MOBILE_MONEY' ? Icons.numbers : Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Ce champ est obligatoire' : null,
              ),
              const SizedBox(height: 20),

              // Frais (Seulement pour Mobile Money)
              if (_typeVersement == 'MOBILE_MONEY')
                TextFormField(
                  controller: _fraisController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Frais de transfert déduits (Ar)',
                    hintText: '0',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.remove_circle_outline, color: Colors.red),
                  ),
                ),

              const SizedBox(height: 40),

              // Bouton de validation
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _soumettreVersement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("CONFIRMER LE VERSEMENT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}