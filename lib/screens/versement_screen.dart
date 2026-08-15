import 'package:flutter/material.dart';
import 'package:fva_financy/services/api_service.dart';
import 'package:fva_financy/theme/app_theme.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
      lastDate: DateTime.now(),
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

    final Map<String, dynamic> payload = {
      'type': _typeVersement,
      'montant': widget.montantSisa,
      'reference': _refController.text.trim(),
      'frais': double.tryParse(_fraisController.text) ?? 0.0,
      'sabbatValidation': '/api/sabbat_validations/${widget.sabbatValidationId}',
    };

    try {
      final response = await ApiService().postVersement(payload);

      if (response.statusCode == 201) {
        _showSuccessDialog();
      } else {
        final error = jsonDecode(response.body);
        _showSnackBar("Erreur : ${error['detail'] ?? 'Echec de l\'envoi'}",
            isError: true);
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md)),
        title: const Icon(Icons.check_circle, color: AppColors.success, size: 50),
        content: Text(
          "Le versement a été enregistré et lié au Sabbat avec succès.",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
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
        backgroundColor: isError ? AppColors.expense : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amountLabel = NumberFormat.currency(locale: 'fr_FR', symbol: ' Ar')
        .format(widget.montantSisa);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Détails du Versement", style: GoogleFonts.poppins()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FvaCard(
                accent: AppColors.primary,
                child: Column(
                  children: [
                    Text(
                      "MONTANT À VERSER",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      amountLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FvaCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today,
                      color: AppColors.primary),
                  title: Text(
                    "Date effective du versement",
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy').format(_dateVersement),
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  onTap: _choisirDate,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Mode de versement",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                      value: 'MOBILE_MONEY',
                      label: Text('M-Money'),
                      icon: Icon(Icons.smartphone)),
                  ButtonSegment(
                      value: 'CASH',
                      label: Text('Espèces'),
                      icon: Icon(Icons.money)),
                ],
                selected: {_typeVersement},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() => _typeVersement = newSelection.first);
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _refController,
                decoration: InputDecoration(
                  labelText: _typeVersement == 'MOBILE_MONEY'
                      ? 'Référence Transaction (ID)'
                      : 'Nom du porteur (Trésorier...)',
                  prefixIcon: Icon(_typeVersement == 'MOBILE_MONEY'
                      ? Icons.numbers
                      : Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Ce champ est obligatoire'
                    : null,
              ),
              const SizedBox(height: 16),
              if (_typeVersement == 'MOBILE_MONEY')
                TextFormField(
                  controller: _fraisController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Frais de transfert déduits (Ar)',
                    hintText: '0',
                    prefixIcon:
                        Icon(Icons.remove_circle_outline, color: AppColors.expense),
                  ),
                ),
              const SizedBox(height: 32),
              FvaPrimaryButton(
                label: 'Confirmer le versement',
                icon: Icons.check_circle,
                color: AppColors.success,
                loading: _isLoading,
                onPressed: _isLoading ? null : _soumettreVersement,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
