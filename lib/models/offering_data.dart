import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import 'expense.dart';

class OfferingData {
  Map<String, Map<int, int>> quantities = {};
  Map<String, bool> completionStatus = {};
  Map<String, bool> syncStatus = {};
  bool expensesSyncStatus = false;
  final ExpenseData expenseData = ExpenseData();
  double ambimbolaTeoAloha = 0.0;
  double volaMiditraAndroany = 0.0;
  double volaNivoaka = 0.0;
  DateTime dateSabbat = DateTime.now();

  /// IDs serveur des offrandes déjà présentes pour la date courante.
  Map<String, int> remoteOfferingIds = {};

  /// Snapshot serveur des quantités (pour détecter les diffs).
  Map<String, Map<int, int>> remoteQuantities = {};

  /// IDs des dépenses serveur liées à la date courante.
  List<int> remoteExpenseIds = [];

  /// True si la date choisie a déjà des données en base.
  bool isModificationMode = false;

  /// Status API du SabbatValidation pour la date courante (`PENDING` / `VALIDATED` / `REJECTED`).
  String? sabbatValidationStatus;

  /// True si l'admin a validé ce sabbat — plus aucune modification autorisée.
  bool get isReadOnly => sabbatValidationStatus == 'VALIDATED';

  OfferingData() {
    for (var offering in offeringTypes) {
      quantities[offering] = {for (var bill in billTypes) bill: 0};
      completionStatus[offering] = false;
      syncStatus[offering] = false;
    }
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    for (var offering in offeringTypes) {
      for (var bill in billTypes) {
        quantities[offering]![bill] = prefs.getInt('$offering-$bill') ?? 0;
      }
      completionStatus[offering] = prefs.getBool('$offering-completed') ?? false;
      syncStatus[offering] = prefs.getBool('$offering-synced') ?? false;
    }
    ambimbolaTeoAloha = prefs.getDouble('ambimbola_teo_aloha') ?? 0.0;
    volaMiditraAndroany = prefs.getDouble('vola_miditra_androany') ??
        calculateVolaMiditraF();
    volaNivoaka = prefs.getDouble('vola_nivoaka') ?? 0.0;
    expensesSyncStatus = prefs.getBool('expenses_synced') ?? false;
    final storedDate = prefs.getString('date_sabbat');
    if (storedDate != null) {
      dateSabbat = DateTime.tryParse(storedDate) ?? DateTime.now();
    }
    isModificationMode = prefs.getBool('is_modification_mode') ?? false;

    final remoteIdsRaw = prefs.getString('remote_offering_ids');
    if (remoteIdsRaw != null && remoteIdsRaw.isNotEmpty) {
      final decoded = jsonDecode(remoteIdsRaw) as Map<String, dynamic>;
      remoteOfferingIds = decoded.map((k, v) => MapEntry(k, v as int));
    }

    final remoteQtyRaw = prefs.getString('remote_quantities');
    if (remoteQtyRaw != null && remoteQtyRaw.isNotEmpty) {
      final decoded = jsonDecode(remoteQtyRaw) as Map<String, dynamic>;
      remoteQuantities = decoded.map((type, bills) {
        final billMap = (bills as Map<String, dynamic>).map(
          (bill, count) => MapEntry(int.parse(bill), count as int),
        );
        return MapEntry(type, billMap);
      });
    }

    final remoteExpenseRaw = prefs.getString('remote_expense_ids');
    if (remoteExpenseRaw != null && remoteExpenseRaw.isNotEmpty) {
      remoteExpenseIds = (jsonDecode(remoteExpenseRaw) as List)
          .map((e) => e as int)
          .toList();
    }

    await expenseData.loadExpenses();
    await refreshValidationStatus();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    for (var offering in offeringTypes) {
      for (var bill in billTypes) {
        await prefs.setInt('$offering-$bill', quantities[offering]![bill]!);
      }
      await prefs.setBool('$offering-completed', completionStatus[offering]!);
      await prefs.setBool('$offering-synced', syncStatus[offering]!);
    }
    await prefs.setDouble('ambimbola_teo_aloha', ambimbolaTeoAloha);
    await prefs.setDouble('vola_miditra_androany', volaMiditraAndroany);
    await prefs.setDouble('vola_nivoaka', volaNivoaka);
    await prefs.setBool('expenses_synced', expensesSyncStatus);
    await prefs.setString('date_sabbat', dateSabbat.toIso8601String());
    await prefs.setBool('is_modification_mode', isModificationMode);
    await prefs.setString('remote_offering_ids', jsonEncode(remoteOfferingIds));
    await prefs.setString(
      'remote_quantities',
      jsonEncode(
        remoteQuantities.map(
          (type, bills) => MapEntry(
            type,
            bills.map((bill, count) => MapEntry(bill.toString(), count)),
          ),
        ),
      ),
    );
    await prefs.setString('remote_expense_ids', jsonEncode(remoteExpenseIds));
    await expenseData.saveExpenses();
  }

  Future<void> updateDateSabbat(DateTime date) async {
    dateSabbat = DateTime(date.year, date.month, date.day);
    await refreshValidationStatus();
    await _saveData();
  }

  void updateQuantity(String offering, int bill, int count) {
    if (isReadOnly) return;
    quantities[offering]![bill] = count;
    syncStatus[offering] = !_isOfferingDifferentFromRemote(offering);
    _saveData();
  }

  void toggleCompletion(String offering) {
    if (isReadOnly) return;
    completionStatus[offering] = !(completionStatus[offering] ?? false);
    _saveData();
  }

  void updateSyncStatus(String offering, bool status) {
    syncStatus[offering] = status;
    _saveData();
  }

  void updateExpensesSyncStatus(bool status) {
    expensesSyncStatus = status;
    _saveData();
  }

  void updateAmbimbolaTeoAloha(double value) {
    if (isReadOnly) return;
    ambimbolaTeoAloha = value;
    _saveData();
  }

  void updateVolaMiditraAndroany(double value) {
    volaMiditraAndroany = value;
    _saveData();
  }

  void updateVolaNivoaka(double value) {
    volaNivoaka = value;
    _saveData();
  }

  void markExpensesDirty() {
    if (isReadOnly) return;
    expensesSyncStatus = false;
    _saveData();
  }

  /// Rafraîchit le statut de validation admin pour la date / église courantes.
  Future<void> refreshValidationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fiangonanaId = prefs.getInt('fiangonana_id');
      if (fiangonanaId == null) {
        sabbatValidationStatus = null;
        return;
      }

      final dateYmd = DateFormat('yyyy-MM-dd').format(dateSabbat);
      final api = ApiService();
      var response =
          await api.fetchSabbatValidationsByDate(fiangonanaId, dateYmd);

      // Fallback si le filtre date n'est pas encore dispo côté API.
      if (response.statusCode != 200) {
        response = await api.get(
          '/sabbat_validations?fiangonana=$fiangonanaId&itemsPerPage=50',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/ld+json',
          },
        );
      }

      if (response.statusCode != 200) {
        sabbatValidationStatus = null;
        return;
      }

      final members = _extractMembers(jsonDecode(response.body));
      String? status;
      for (final raw in members) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final rawDate = item['dateSabbat']?.toString() ?? '';
        final itemDate =
            rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
        if (itemDate != dateYmd) continue;
        final s = item['status']?.toString();
        // VALIDATED prioritaire s'il existe plusieurs lignes.
        if (s == 'VALIDATED') {
          status = 'VALIDATED';
          break;
        }
        status ??= s;
      }
      sabbatValidationStatus = status;
    } catch (e) {
      // Ne bloque pas l'UI si le check échoue.
      debugPrint('refreshValidationStatus: $e');
    }
  }

  bool needsOfferingSync(String offering) {
    final total = calculateTotalForOffering(offering);
    if (total <= 0 && !remoteOfferingIds.containsKey(offering)) return false;
    return !(syncStatus[offering] ?? false) ||
        _isOfferingDifferentFromRemote(offering);
  }

  bool needsExpensesSync() {
    if (expenseData.expenses.isEmpty && remoteExpenseIds.isEmpty) return false;
    return !expensesSyncStatus || _areExpensesDifferentFromRemote();
  }

  bool _isOfferingDifferentFromRemote(String offering) {
    final local = quantities[offering] ?? {};
    final remote = remoteQuantities[offering];
    if (remote == null) {
      // Pas encore en base : différent si total > 0
      return calculateTotalForOffering(offering) > 0;
    }
    for (final bill in billTypes) {
      if ((local[bill] ?? 0) != (remote[bill] ?? 0)) return true;
    }
    return false;
  }

  bool _areExpensesDifferentFromRemote() {
    final localIds = expenseData.expenses
        .map((e) => e.serverId)
        .whereType<int>()
        .toList()
      ..sort();
    final remote = List<int>.from(remoteExpenseIds)..sort();
    if (!_listEquals(localIds, remote)) return true;
    if (expenseData.expenses.any((e) => e.serverId == null)) return true;
    return false;
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  double calculateTotalForOffering(String offering) {
    double total = 0;
    quantities[offering]!.forEach((bill, count) {
      total += bill * count;
    });
    return total;
  }

  double calculateGrandTotal() {
    double grandTotal = 0;
    for (var offering in offeringTypes) {
      grandTotal += calculateTotalForOffering(offering);
    }
    return grandTotal;
  }

  Map<String, double> calculateTotalsByCategory() {
    Map<String, double> categoryTotals = {
      'Vola miditra F': 0.0,
      'Vola miditra A': 0.0,
      'Autre': 0.0,
    };

    for (var offering in offeringTypes) {
      String category = offeringCategories[offering]!;
      double offeringTotal = calculateTotalForOffering(offering);
      categoryTotals[category] = (categoryTotals[category] ?? 0) + offeringTotal;
    }

    return categoryTotals;
  }

  double getTotalExpenses() {
    return expenseData.calculateTotalExpenses();
  }

  double calculateVolaMiditraF() {
    Map<String, double> totals = calculateTotalsByCategory();
    return totals['Vola miditra F'] ?? 0.0;
  }

  double calculateVolaMiditraA() {
    Map<String, double> totals = calculateTotalsByCategory();
    return totals['Vola miditra A'] ?? 0.0;
  }

  double getVolaMiditraAndroany() {
    return volaMiditraAndroany;
  }

  double getFitambaranIreo() {
    return ambimbolaTeoAloha + calculateVolaMiditraF();
  }

  double getVolaNivoaka() {
    return volaNivoaka;
  }

  double getVolaSisaEoAntanana() {
    return getFitambaranIreo() - getTotalExpenses();
  }

  Future<void> _clearMovementsKeepDate() async {
    quantities = {
      for (var offering in offeringTypes)
        offering: {for (var bill in billTypes) bill: 0}
    };
    completionStatus = {for (var offering in offeringTypes) offering: false};
    syncStatus = {for (var offering in offeringTypes) offering: false};
    expensesSyncStatus = false;
    remoteOfferingIds = {};
    remoteQuantities = {};
    remoteExpenseIds = [];
    isModificationMode = false;
    expenseData.expenses = [];
    await _saveData();
  }

  /// Charge offrandes + dépenses pour [date]. Retourne true si données trouvées.
  Future<bool> loadFromServerForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final fiangonanaId = prefs.getInt('fiangonana_id');
    if (fiangonanaId == null) {
      throw Exception('ID Fiangonana manquant');
    }

    dateSabbat = DateTime(date.year, date.month, date.day);
    final dateYmd = DateFormat('yyyy-MM-dd').format(dateSabbat);
    final api = ApiService();

    final offeringsResp = await api.fetchOfferingsByDate(fiangonanaId, dateYmd);
    final expensesResp = await api.fetchExpensesByDate(fiangonanaId, dateYmd);

    if (offeringsResp.statusCode != 200) {
      throw Exception('Erreur offrandes (${offeringsResp.statusCode})');
    }
    if (expensesResp.statusCode != 200) {
      throw Exception('Erreur dépenses (${expensesResp.statusCode})');
    }

    final offeringMembers = _extractMembers(jsonDecode(offeringsResp.body));
    final expenseMembers = _extractMembers(jsonDecode(expensesResp.body));

    await _clearMovementsKeepDate();
    dateSabbat = DateTime(date.year, date.month, date.day);

    if (offeringMembers.isEmpty && expenseMembers.isEmpty) {
      isModificationMode = false;
      await refreshValidationStatus();
      await _saveData();
      return false;
    }

    // Dernière offrande par type (évite doublons historiques)
    final Map<String, Map<String, dynamic>> latestByType = {};
    for (final raw in offeringMembers) {
      final item = Map<String, dynamic>.from(raw as Map);
      final type = item['type']?.toString();
      if (type == null || !offeringTypes.contains(type)) continue;
      latestByType[type] = item;
    }

    for (final entry in latestByType.entries) {
      final type = entry.key;
      final item = entry.value;
      final id = _parseEntityId(item);
      final qtyRaw = item['quantities'];
      final Map<int, int> parsed = {for (var bill in billTypes) bill: 0};

      if (qtyRaw is Map) {
        qtyRaw.forEach((key, value) {
          final bill = int.tryParse(key.toString());
          final count = (value as num?)?.toInt() ?? 0;
          if (bill != null && parsed.containsKey(bill)) {
            parsed[bill] = count;
          }
        });
      }

      quantities[type] = parsed;
      remoteQuantities[type] = Map<int, int>.from(parsed);
      if (id != null) remoteOfferingIds[type] = id;
      syncStatus[type] = true;
      completionStatus[type] = calculateTotalForOffering(type) > 0;
    }

    final loadedExpenses =
        expenseMembers.map((e) => Expense.fromApi(Map<String, dynamic>.from(e as Map))).toList();
    await expenseData.replaceAll(loadedExpenses);
    remoteExpenseIds =
        loadedExpenses.map((e) => e.serverId).whereType<int>().toList();
    expensesSyncStatus = true;
    isModificationMode = true;
    await refreshValidationStatus();
    await _saveData();
    return true;
  }

  void rememberSyncedOffering(String offering, int? id) {
    if (id != null) {
      remoteOfferingIds[offering] = id;
    }
    remoteQuantities[offering] = Map<int, int>.from(quantities[offering] ?? {});
    syncStatus[offering] = true;
    isModificationMode = true;
    _saveData();
  }

  void rememberSyncedExpenses(List<Expense> synced) {
    expenseData.expenses = List<Expense>.from(synced);
    remoteExpenseIds =
        synced.map((e) => e.serverId).whereType<int>().toList();
    expensesSyncStatus = true;
    isModificationMode = true;
    _saveData();
  }

  static List<dynamic> _extractMembers(dynamic json) {
    if (json is! Map) return const [];
    final members = json['member'] ?? json['hydra:member'];
    if (members is List) return members;
    return const [];
  }

  static int? _parseEntityId(Map<String, dynamic> json) {
    if (json['id'] is int) return json['id'] as int;
    final iri = json['@id']?.toString();
    if (iri == null) return null;
    final match = RegExp(r'/(\d+)$').firstMatch(iri);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  Future<void> resetData() async {
    quantities = {
      for (var offering in offeringTypes)
        offering: {for (var bill in billTypes) bill: 0}
    };
    completionStatus = {for (var offering in offeringTypes) offering: false};
    syncStatus = {for (var offering in offeringTypes) offering: false};
    expensesSyncStatus = false;
    ambimbolaTeoAloha = 0.0;
    volaMiditraAndroany = calculateVolaMiditraF();
    volaNivoaka = 0.0;
    dateSabbat = DateTime.now();
    remoteOfferingIds = {};
    remoteQuantities = {};
    remoteExpenseIds = [];
    isModificationMode = false;
    sabbatValidationStatus = null;
    expenseData.expenses = [];
    await _saveData();
  }
}
