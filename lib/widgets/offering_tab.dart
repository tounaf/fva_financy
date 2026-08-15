import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fva_financy/theme/app_theme.dart';

class OfferingTab extends StatefulWidget {
  final String offering;
  final List<int> billTypes;
  final Map<int, int> quantities;
  final Function(int, int) onQuantityChanged;
  final bool isCompleted;
  final VoidCallback onToggleCompletion;

  const OfferingTab({
    super.key,
    required this.offering,
    required this.billTypes,
    required this.quantities,
    required this.onQuantityChanged,
    required this.isCompleted,
    required this.onToggleCompletion,
  });

  @override
  State<OfferingTab> createState() => _OfferingTabState();
}

class _OfferingTabState extends State<OfferingTab> {
  double calculateTotal() {
    double total = 0;
    widget.quantities.forEach((bill, count) {
      total += bill * count;
    });
    return total;
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  void _setCount(int bill, int count) {
    if (widget.isCompleted) return;
    final next = count < 0 ? 0 : count;
    widget.onQuantityChanged(bill, next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FvaCard(
          accent: widget.isCompleted ? AppColors.warning : AppColors.success,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fandatsahana ${widget.offering}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatAmount(calculateTotal()),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              FvaStatusChip(
                label: widget.isCompleted ? 'Voatokana' : 'Azo ovaina',
                kind: widget.isCompleted
                    ? FvaStatusKind.completed
                    : FvaStatusKind.synced,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: widget.billTypes.length,
            itemBuilder: (context, index) {
              final bill = widget.billTypes[index];
              final count = widget.quantities[bill] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Opacity(
                  opacity: widget.isCompleted ? 0.72 : 1,
                  child: FvaCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${NumberFormat.decimalPattern('fr_FR').format(bill)} Ar',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                formatAmount((bill * count).toDouble()),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FvaQuantityStepper(
                          value: count,
                          enabled: !widget.isCompleted,
                          onChanged: (n) => _setCount(bill, n),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: FvaPrimaryButton(
            label: widget.isCompleted ? 'Rééditer' : 'Valider',
            icon: widget.isCompleted ? Icons.lock_open : Icons.check_circle,
            color: widget.isCompleted ? AppColors.warning : AppColors.success,
            onPressed: widget.onToggleCompletion,
          ),
        ),
      ],
    );
  }
}
