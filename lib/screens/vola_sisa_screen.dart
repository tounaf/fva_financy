import 'package:flutter/material.dart';
import 'package:fva_financy/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/offering_data.dart';

class VolaSisaScreen extends StatefulWidget {
  final OfferingData offeringData;

  const VolaSisaScreen({super.key, required this.offeringData});

  @override
  State<VolaSisaScreen> createState() => _VolaSisaScreenState();
}

class _VolaSisaScreenState extends State<VolaSisaScreen> {
  final _ambimbolaController = TextEditingController();
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
  }

  @override
  void didUpdateWidget(covariant VolaSisaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshFields();
  }

  @override
  void dispose() {
    _ambimbolaController.dispose();
    super.dispose();
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  Widget _derivedRow(String label, String hint, String value) {
    return FvaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: const Color(0xFFF3F4F5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  hint,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        FvaCard(
          accent: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ambimbola teo aloha',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (_ambimbolaLocked)
                    const FvaStatusChip(
                      label: 'Voatokana',
                      kind: FvaStatusKind.completed,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _ambimbolaLocked
                    ? 'Valeur provenant du serveur'
                    : 'Saisie manuelle — mise à jour immédiate',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ambimbolaController,
                keyboardType: TextInputType.number,
                readOnly: _ambimbolaLocked,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
                decoration: InputDecoration(
                  hintText: '0',
                  fillColor: _ambimbolaLocked
                      ? Colors.grey[100]
                      : const Color(0xFFF3F4F5),
                  filled: true,
                  suffixIcon: _ambimbolaLocked
                      ? const Icon(Icons.lock_outline,
                          size: 18, color: Colors.grey)
                      : null,
                ),
                onChanged: (value) {
                  double amount = double.tryParse(value) ?? 0.0;
                  widget.offeringData.updateAmbimbolaTeoAloha(amount);
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _derivedRow(
          'Vola miditra androany',
          'Kajy automatique',
          formatAmount(widget.offeringData.calculateVolaMiditraF()),
        ),
        const SizedBox(height: 8),
        FvaSummaryTile(
          title: 'Fitambaran\'ireo',
          value: formatAmount(widget.offeringData.getFitambaranIreo()),
          accent: AppColors.warning,
        ),
        const SizedBox(height: 8),
        _derivedRow(
          'Vola nivoaka',
          'Total des dépenses',
          formatAmount(widget.offeringData.getTotalExpenses()),
        ),
        const SizedBox(height: 12),
        FvaSummaryTile(
          title: 'Vola sisa eo an-tanana',
          value: formatAmount(widget.offeringData.getVolaSisaEoAntanana()),
          accent: AppColors.primary,
          emphasized: true,
        ),
      ],
    );
  }
}
