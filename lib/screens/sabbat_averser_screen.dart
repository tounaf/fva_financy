import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'versement_screen.dart';

class SabbatAverserScreen extends StatefulWidget {
  const SabbatAverserScreen({super.key});

  @override
  _SabbatAverserScreenState createState() => _SabbatAverserScreenState();
}

class _SabbatAverserScreenState extends State<SabbatAverserScreen> {
  List<dynamic> _sabbatsPendants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSabbatsSansVersement();
  }

  Future<void> _fetchSabbatsSansVersement() async {

    final prefs = await SharedPreferences.getInstance();
    final fiangonanaId = prefs.getInt('fiangonana_id');

    final url = Uri.parse(
        'https://fva-vitaonyasany.mg/admin-api/public/index.php/api/sabbat_validations'
        '?exists[versement]=false'
        '&fiangonana=$fiangonanaId'
      );
    
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        setState(() {
          // On s'assure que c'est une liste, sinon on met une liste vide
          final decoded = jsonDecode(response.body);
          _sabbatsPendants = (decoded is List) ? decoded : [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur Fetch: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sélectionner un Sabbat")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _sabbatsPendants.isEmpty 
          ? const Center(child: Text("Tous les versements sont à jour."))
          : ListView.builder(
              itemCount: _sabbatsPendants.length,
              itemBuilder: (context, index) {
                final sabbat = _sabbatsPendants[index];
                
                // 1. Sécurisation de la date
                final dateRaw = sabbat['dateSabbat']?.toString() ?? "";
                final dateStr = dateRaw.contains('T') ? dateRaw.split('T')[0] : dateRaw;
                
                // 2. Sécurisation du montant (C'est ici que ça crashait)
                // On utilise double.tryParse ou une vérification de type
                final dynamic rawMontant = sabbat['volaSisaEoAntanana'];
                final double montantValide = _parseAmount(rawMontant);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.event, color: Colors.deepPurple),
                    title: Text("Sabbat du $dateStr"),
                    // Utilisation de la valeur sécurisée pour l'affichage
                    subtitle: Text("Reste en main : ${montantValide.toStringAsFixed(0)} Ar"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VersementScreen(
                            sabbatValidationId: sabbat['id'],
                            montantSisa: montantValide,
                          ),
                        ),
                      ).then((_) => _fetchSabbatsSansVersement());
                    },
                  ),
                );
              },
            ),
    );
  }

  // Fonction utilitaire pour éviter les erreurs de type
  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}