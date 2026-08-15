import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fva_financy/services/api_service.dart';
import 'package:fva_financy/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/offering_tab.dart';
import '../models/offering_data.dart';
import '../utils/constants.dart';
import 'expense_screen.dart';
import 'vola_sisa_screen.dart';

// Alias conservés pour les écrans qui importent encore ces constantes.
const Color vibrantPurple = AppColors.primary;
const Color neonGreen = AppColors.income;
const Color deepOrange = Color(0xFFE65100);
const Color backgroundColor = AppColors.background;
const Color expenseRed = AppColors.expense;
const Color cardColor = AppColors.surface;
const double cardElevation = 0;

class OfferingCounterScreen extends StatefulWidget {
  final OfferingData? offeringData;
  final bool embedded;
  final VoidCallback? onDataChanged;

  const OfferingCounterScreen({
    super.key,
    this.offeringData,
    this.embedded = false,
    this.onDataChanged,
  });

  @override
  State<OfferingCounterScreen> createState() => _OfferingCounterScreenState();
}

class _OfferingCounterScreenState extends State<OfferingCounterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OfferingData offeringData;
  bool _isLoading = true;
  bool _isLoadingDate = false;
  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: offeringTypes.length + 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    offeringData = widget.offeringData ?? OfferingData();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await offeringData.loadData();
    await _fetchAmbimbolaTeoAloha();
    if (mounted) {
      setState(() => _isLoading = false);
      widget.onDataChanged?.call();
    }
  }

  Future<void> _fetchAmbimbolaTeoAloha() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fiangonanaId = prefs.getInt('fiangonana_id');
      if (fiangonanaId == null) return;

      final response =
          await ApiService().fetchLastSabbatValidation(fiangonanaId);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final members = json['member'] as List;
        if (members.isNotEmpty) {
          final lastValidation = members.first;
          final apiValue =
              (lastValidation['volaSisaEoAntanana'] as num?)?.toDouble() ?? 0.0;
          if (apiValue != 0.0) {
            offeringData.updateAmbimbolaTeoAloha(apiValue);
          }
        }
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération de l'ambimbola : $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _notify() {
    setState(() {});
    widget.onDataChanged?.call();
  }

  double calculateGrandTotal() {
    return offeringData.calculateGrandTotal() + offeringData.getTotalExpenses();
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' Ar').format(amount);
  }

  Future<void> _confirmReset() async {
    final ok = await FvaConfirm.show(
      context,
      title: 'Réinitialiser ?',
      message: 'Toutes les saisies locales du sabbat seront effacées.',
      confirmLabel: 'Réinitialiser',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await offeringData.resetData();
    _notify();
  }

  Future<void> _pickDateSabbat() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: offeringData.dateSabbat,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Date du sabbat',
    );
    if (picked == null || !mounted) return;

    setState(() => _isLoadingDate = true);
    try {
      final found = await offeringData.loadFromServerForDate(picked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: found ? AppColors.warning : AppColors.success,
          content: Text(
            found
                ? 'Données existantes chargées — mode modification'
                : 'Aucune donnée pour cette date — nouvelle saisie',
          ),
        ),
      );
      _notify();
    } catch (e) {
      if (!mounted) return;
      await offeringData.updateDateSabbat(picked);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les données : $e')),
      );
      _notify();
    } finally {
      if (mounted) setState(() => _isLoadingDate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final categoryTotals = offeringData.calculateTotalsByCategory();
    final content = _buildContent(categoryTotals);

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('FVA Financy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _confirmReset,
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildContent(Map<String, double> categoryTotals) {
    final miditra = (categoryTotals['Vola miditra F'] ?? 0) +
        (categoryTotals['Vola miditra A'] ?? 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DATY ANKEHITRINY',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          _buildDateSabbatPicker(),
          if (_isLoadingDate) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(color: AppColors.primary),
          ],
          if (offeringData.isModificationMode) ...[
            const SizedBox(height: 10),
            const FvaModificationBanner(),
          ],
          const SizedBox(height: 10),
          FvaCompactSummary(
            miditraLabel: 'Miditra',
            miditraValue: formatAmount(miditra),
            expenseLabel: 'Fandaniana',
            expenseValue: formatAmount(offeringData.getTotalExpenses()),
            netLabel: 'Net',
            netValue: formatAmount(calculateGrandTotal()),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildTabs(context)),
        ],
      ),
    );
  }

  Widget _buildDateSabbatPicker() {
    final formatted = DateFormat('dd/MM/yyyy').format(offeringData.dateSabbat);
    return FvaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: InkWell(
        onTap: _isLoadingDate ? null : _pickDateSabbat,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formatted,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: AppColors.outline),
              ),
              child: const Icon(Icons.calendar_today,
                  color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: offeringTypes.length + 2,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final selected = _tabController.index == index;
              String label;
              bool completed = false;
              if (index < offeringTypes.length) {
                label = offeringTypes[index];
                completed =
                    offeringData.completionStatus[offeringTypes[index]] ?? false;
              } else if (index == offeringTypes.length) {
                label = 'Dépenses';
              } else {
                label = 'Vola Sisa';
              }
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (completed) ...[
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: selected ? Colors.white : AppColors.success,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(label),
                  ],
                ),
                selected: selected,
                onSelected: (_) {
                  _tabController.animateTo(index);
                  setState(() {});
                },
                selectedColor: AppColors.primary,
                labelStyle: GoogleFonts.poppins(
                  color: selected ? Colors.white : AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                backgroundColor: const Color(0xFFEDEEEF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide.none,
                ),
                showCheckmark: false,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ...offeringTypes.map((type) => OfferingTab(
                    offering: type,
                    billTypes: billTypes,
                    quantities: offeringData.quantities[type]!,
                    onQuantityChanged: (bill, count) {
                      offeringData.updateQuantity(type, bill, count);
                      _notify();
                    },
                    isCompleted: offeringData.completionStatus[type]!,
                    onToggleCompletion: () {
                      offeringData.toggleCompletion(type);
                      _notify();
                    },
                  )),
              ExpenseScreen(
                offeringData: offeringData,
                onDataUpdated: _notify,
                embedded: true,
              ),
              VolaSisaScreen(offeringData: offeringData),
            ],
          ),
        ),
      ],
    );
  }
}
