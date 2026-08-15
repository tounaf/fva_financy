import 'package:flutter/material.dart';
import 'package:fva_financy/services/api_service.dart';
import 'package:fva_financy/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/offering_data.dart';
import '../utils/constants.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

enum SyncSection { all, syncOnly, finalizeOnly }

class SyncScreen extends StatefulWidget {
  final OfferingData offeringData;
  final bool embedded;
  final SyncSection section;
  final VoidCallback? onDataChanged;

  const SyncScreen({
    super.key,
    required this.offeringData,
    this.embedded = false,
    this.section = SyncSection.all,
    this.onDataChanged,
  });

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final Map<String, bool> _isLoading = {};
  File? _bordereauImage;
  bool _isFinalizing = false;
  double _caution = 10000.0;
  double _rar = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCaution();
    _loadRar();
  }

  Future<void> _loadCaution() async {
    final val = await getFiangonanaCaution();
    setState(() => _caution = val);
  }

  Future<void> _loadRar() async {
    final val = await getFiangonanaRar();
    setState(() => _rar = val);
  }

  Future<double> getFiangonanaCaution() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('fiangonana_caution') ?? 10000.0;
  }

  Future<double> getFiangonanaRar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('fiangonana_rar') ?? 0.0;
  }

  void _notify() => widget.onDataChanged?.call();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _bordereauImage = File(pickedFile.path));
    }
  }

  Future<void> finalizeSabbat() async {
    if (_bordereauImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez prendre une photo du bordereau signé')),
      );
      return;
    }

    setState(() => _isFinalizing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final fiangonanaId = prefs.getInt('fiangonana_id');
      if (fiangonanaId == null) throw Exception('ID Fiangonana manquant');

      List<int> imageBytes = await _bordereauImage!.readAsBytes();
      String base64Image =
          "data:image/jpeg;base64,${base64Encode(imageBytes)}";

      final data = {
        'imageName': base64Image,
        'dateSabbat':
            DateFormat('yyyy-MM-dd').format(widget.offeringData.dateSabbat),
        'fiangonana': "/api/fiangonanas/$fiangonanaId",
        'ambimbolaTeoAloha': widget.offeringData.ambimbolaTeoAloha,
        'volaMiditraAndroany': widget.offeringData.getFitambaranIreo(),
        'volaNivoaka': widget.offeringData.getTotalExpenses(),
        'volaSisaEoAntanana': widget.offeringData.getVolaSisaEoAntanana(),
        'volaMiditraA': widget.offeringData.calculateVolaMiditraA(),
        'caution': _caution,
        'rar': _rar,
      };

      final response = await ApiService().finalizeSabbat(data);
      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              backgroundColor: AppColors.success,
              content: Text('Sabbat finalisé et envoyé pour contrôle !')),
        );
        setState(() => _bordereauImage = null);
      } else {
        throw Exception('Erreur serveur (${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la finalisation : $e')),
      );
    } finally {
      if (mounted) setState(() => _isFinalizing = false);
    }
  }

  Future<void> sendOfferingToApi(String offering) async {
    setState(() => _isLoading[offering] = true);

    final quantities = widget.offeringData.quantities[offering]!;
    final total = widget.offeringData.calculateTotalForOffering(offering);
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final fiangonanaId = prefs.getInt('fiangonana_id');
    final remoteId = widget.offeringData.remoteOfferingIds[offering];
    final isUpdate = remoteId != null;

    if (fiangonanaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur ID Fiangonana')));
      setState(() => _isLoading[offering] = false);
      return;
    }

    final data = {
      'type': offering,
      'quantities':
          quantities.map((bill, count) => MapEntry(bill.toString(), count)),
      'total': total,
      'date': DateFormat('yyyy-MM-dd').format(widget.offeringData.dateSabbat),
      'fiangonana': "/api/fiangonanas/$fiangonanaId"
    };

    final confirm = await _showConfirmDialog(
      isUpdate
          ? 'Mettre à jour l\'offrande "$offering" (écarts avec la base) ?'
          : 'Voulez-vous synchroniser l\'offrande "$offering" ?',
    );
    if (!mounted) return;
    if (confirm != true) {
      setState(() => _isLoading[offering] = false);
      return;
    }

    try {
      final api = ApiService();
      final response = isUpdate
          ? await api.updateOffering(remoteId, data)
          : await api.syncOffering(data);
      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        int? savedId = remoteId;
        try {
          final body = jsonDecode(response.body);
          if (body is Map) {
            if (body['id'] is int) {
              savedId = body['id'] as int;
            } else {
              final iri = body['@id']?.toString();
              final match =
                  iri == null ? null : RegExp(r'/(\d+)$').firstMatch(iri);
              if (match != null) savedId = int.tryParse(match.group(1)!);
            }
          }
        } catch (_) {}

        setState(() {
          widget.offeringData.rememberSyncedOffering(offering, savedId);
          _isLoading[offering] = false;
        });
        _notify();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  isUpdate ? '$offering mis à jour' : '$offering synchronisé')),
        );
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading[offering] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de synchronisation : $e')),
      );
    }
  }

  Future<void> sendExpensesToApi() async {
    setState(() => _isLoading['expenses'] = true);

    final expenses = widget.offeringData.expenseData.expenses;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final fiangonanaId = prefs.getInt('fiangonana_id');
    final remoteIds = List<int>.from(widget.offeringData.remoteExpenseIds);
    final isUpdate = remoteIds.isNotEmpty;

    if (fiangonanaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur ID Fiangonana')));
      setState(() => _isLoading['expenses'] = false);
      return;
    }

    final confirm = await _showConfirmDialog(
      isUpdate
          ? 'Mettre à jour les dépenses (remplacer en base) ?'
          : 'Synchroniser les dépenses ?',
    );
    if (!mounted) return;
    if (confirm != true) {
      setState(() => _isLoading['expenses'] = false);
      return;
    }

    try {
      final api = ApiService();

      for (final id in remoteIds) {
        final del = await api.deleteExpense(id);
        if (del.statusCode != 204 && del.statusCode != 200) {
          throw Exception('Suppression dépense #$id (${del.statusCode})');
        }
      }
      if (!mounted) return;

      if (expenses.isEmpty) {
        setState(() {
          widget.offeringData.rememberSyncedExpenses([]);
          _isLoading['expenses'] = false;
        });
        _notify();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dépenses mises à jour (vide)')),
        );
        return;
      }

      final data = {
        'expenses': expenses
            .map((e) => {
                  'description': e.label,
                  'amount': e.amount,
                  'date': DateFormat('yyyy-MM-dd')
                      .format(widget.offeringData.dateSabbat),
                  'fiangonana': "/api/fiangonanas/$fiangonanaId"
                })
            .toList()
      };

      final response = await api.syncExpenses(data);
      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final created = <Expense>[];
        try {
          final body = jsonDecode(response.body);
          final list = body is List
              ? body
              : (body is Map
                  ? (body['member'] ?? body['hydra:member'])
                  : null);
          if (list is List) {
            for (final item in list) {
              if (item is Map) {
                created.add(Expense.fromApi(Map<String, dynamic>.from(item)));
              }
            }
          }
        } catch (_) {}

        if (created.isEmpty) {
          created.addAll(expenses.map((e) => Expense(
                label: e.label,
                amount: e.amount,
                date: widget.offeringData.dateSabbat,
              )));
        }

        setState(() {
          widget.offeringData.rememberSyncedExpenses(created);
          _isLoading['expenses'] = false;
        });
        _notify();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isUpdate
                  ? 'Dépenses mises à jour'
                  : 'Dépenses synchronisées')),
        );
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading['expenses'] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur dépenses : $e')),
      );
    }
  }

  Future<bool?> _showConfirmDialog(String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer')),
        ],
      ),
    );
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' AR').format(amount);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.offeringData.dateSabbat,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Date du sabbat',
    );
    if (picked == null) return;
    try {
      final found = await widget.offeringData.loadFromServerForDate(picked);
      if (!mounted) return;
      setState(() {});
      _notify();
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
    } catch (e) {
      await widget.offeringData.updateDateSabbat(picked);
      if (!mounted) return;
      setState(() {});
      _notify();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les données : $e')),
      );
    }
  }

  Widget _syncDoneBar(String label) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.success,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('dd/MM/yyyy').format(widget.offeringData.dateSabbat);
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (widget.section != SyncSection.finalizeOnly) ...[
          Text(
            widget.section == SyncSection.syncOnly
                ? 'Fampitoviana / Synchronisation'
                : 'Synchronisation',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jereo ary alefaso ny angona eo an-toerana',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          if (widget.offeringData.isModificationMode) ...[
            const FvaModificationBanner(),
            const SizedBox(height: 12),
          ],
          FvaCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
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
              title: Text(
                'Date du sabbat',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              subtitle: Text(
                widget.offeringData.isModificationMode
                    ? '$dateLabel · mode modification'
                    : dateLabel,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              trailing: const Icon(Icons.edit_outlined, size: 20),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 12),
          ...offeringTypes.map(_buildOfferingCard),
          _buildExpenseCard(),
        ],
        if (widget.section != SyncSection.syncOnly) _buildFinalizeSection(),
      ],
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Synchronisation'),
      ),
      body: body,
    );
  }

  Widget _buildOfferingCard(String offering) {
    final total = widget.offeringData.calculateTotalForOffering(offering);
    final needsSync = widget.offeringData.needsOfferingSync(offering);
    final isSynced = !needsSync && total > 0;
    final isLoading = _isLoading[offering] ?? false;
    final isUpdate =
        widget.offeringData.remoteOfferingIds.containsKey(offering);
    final canSync = needsSync && !isLoading && (total > 0 || isUpdate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FvaCard(
        accent: needsSync && isUpdate
            ? AppColors.warning
            : (isSynced ? AppColors.success : null),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(offering,
                      style: GoogleFonts.poppins(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                if (isSynced)
                  const FvaStatusChip(
                    label: 'Synchronisé',
                    kind: FvaStatusKind.synced,
                  )
                else if (needsSync && isUpdate)
                  const FvaStatusChip(
                    label: 'À resync',
                    kind: FvaStatusKind.pending,
                  )
                else if (total > 0)
                  const FvaStatusChip(
                    label: 'À sync',
                    kind: FvaStatusKind.pending,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(formatAmount(total),
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
            if (needsSync && isUpdate)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Fanavaozana — à resynchroniser',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.warning),
                ),
              ),
            const SizedBox(height: 12),
            if (isSynced)
              _syncDoneBar('Synchronisé')
            else
              FvaPrimaryButton(
                label: isLoading
                    ? 'En cours...'
                    : (isUpdate ? 'Resynchroniser' : 'Synchroniser'),
                icon: isUpdate ? Icons.sync_problem : Icons.sync,
                color: AppColors.success,
                loading: isLoading,
                onPressed: canSync ? () => sendOfferingToApi(offering) : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard() {
    final totalExpenses = widget.offeringData.getTotalExpenses();
    final needsSync = widget.offeringData.needsExpensesSync();
    final isSynced = !needsSync &&
        (totalExpenses > 0 || widget.offeringData.remoteExpenseIds.isNotEmpty);
    final isLoading = _isLoading['expenses'] ?? false;
    final isUpdate = widget.offeringData.remoteExpenseIds.isNotEmpty;
    final canSync = needsSync && !isLoading;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FvaCard(
        accent: needsSync && isUpdate
            ? AppColors.warning
            : (isSynced ? AppColors.success : AppColors.expense),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Dépenses',
                      style: GoogleFonts.poppins(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                ),
                if (isSynced)
                  const FvaStatusChip(
                    label: 'Synchronisé',
                    kind: FvaStatusKind.synced,
                  )
                else if (needsSync)
                  const FvaStatusChip(
                    label: 'À sync',
                    kind: FvaStatusKind.pending,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(formatAmount(totalExpenses),
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.expense)),
            if (needsSync && isUpdate)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Modifié localement — à resynchroniser',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.warning),
                ),
              ),
            const SizedBox(height: 12),
            if (isSynced)
              _syncDoneBar('Synchronisé')
            else
              FvaPrimaryButton(
                label: isLoading
                    ? 'En cours...'
                    : (isUpdate ? 'Resynchroniser' : 'Synchroniser'),
                icon: isUpdate ? Icons.sync_problem : Icons.sync,
                color: AppColors.success,
                loading: isLoading,
                onPressed: canSync ? sendExpensesToApi : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalizeSection() {
    final dateLabel =
        DateFormat('dd/MM/yyyy').format(widget.offeringData.dateSabbat);
    final collectes = offeringTypes
        .where((t) => widget.offeringData.calculateTotalForOffering(t) > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Famintinana',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text(
          'Récapitulatif final — sabbat du $dateLabel',
          style: GoogleFonts.poppins(
              fontSize: 13, color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        FvaCard(
          accent: AppColors.income,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Entrées',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: AppColors.income)),
              const SizedBox(height: 8),
              if (collectes.isEmpty)
                Text(
                  'Tsy misy collecte',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: AppColors.onSurfaceVariant),
                )
              else
                ...collectes.map(
                  (t) => _buildSummaryRow(
                    t,
                    widget.offeringData.calculateTotalForOffering(t),
                  ),
                ),
              _buildSummaryRow(
                  'Ambimbola teo aloha', widget.offeringData.ambimbolaTeoAloha),
              _buildSummaryRow('Vola miditra androany',
                  widget.offeringData.getFitambaranIreo()),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FvaCard(
          accent: AppColors.expense,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sorties & solde',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: AppColors.expense)),
              const SizedBox(height: 8),
              _buildSummaryRow('Vola nivoaka',
                  widget.offeringData.getTotalExpenses(),
                  isExpense: true),
              const Divider(),
              _buildSummaryRow(
                  'Vola sisa eo an-tanana',
                  widget.offeringData.getVolaSisaEoAntanana(),
                  isTotal: true),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FvaCard(
          accent: AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Net à verser',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const SizedBox(height: 8),
              _buildSummaryRow('Caution', _caution),
              _buildSummaryRow('Rad', _rar),
              _buildSummaryRow(
                  'Vola miditra A', widget.offeringData.calculateVolaMiditraA()),
              const Divider(),
              _buildSummaryRow(
                'A verser',
                widget.offeringData.calculateVolaMiditraA() + _caution + _rar,
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FvaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Sarin\'ny taratasy sonia',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              Text(
                'Photo du bordereau signé',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: AppColors.outline,
                    radius: AppRadii.md,
                  ),
                  child: Container(
                    height: _bordereauImage == null ? 140 : 180,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(12),
                    child: _bordereauImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_camera_outlined,
                                  size: 36,
                                  color: AppColors.primary.withValues(alpha: 0.8)),
                              const SizedBox(height: 8),
                              Text(
                                'Tapéo mba maka sary',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                'Appareil photo uniquement',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                            child: Image.file(
                              _bordereauImage!,
                              height: 156,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
              ),
              if (_bordereauImage != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Changer la photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        FvaPrimaryButton(
          label: 'Hamita ny Sabata',
          icon: Icons.check_circle,
          color: AppColors.primary,
          loading: _isFinalizing,
          onPressed: _isFinalizing ? null : finalizeSabbat,
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount,
      {bool isExpense = false, bool isTotal = false}) {
    final color = isTotal
        ? AppColors.primary
        : isExpense
            ? AppColors.expense
            : AppColors.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            formatAmount(amount),
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 14 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
