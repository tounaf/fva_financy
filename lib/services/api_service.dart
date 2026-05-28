import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<http.Response> get(String endpoint, {Map<String, String>? headers}) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    return await http.get(url, headers: headers ?? _headers);
  }

  Future<http.Response> post(String endpoint, dynamic body, {Map<String, String>? headers}) async {
    final url = Uri.parse('${AppConfig.baseUrl}$endpoint');
    return await http.post(
      url,
      headers: headers ?? _headers,
      body: jsonEncode(body),
    );
  }

  // GitHub Update Check
  Future<http.Response> checkGitHubRelease() async {
    const String apiUrl = "https://api.github.com/repos/${AppConfig.githubUser}/${AppConfig.githubRepo}/releases/latest";
    return await http.get(Uri.parse(apiUrl));
  }

  // Fiangonana
  Future<http.Response> validateFiangonanaCode(String code) async {
    return await get('/fiangonanas?code=$code');
  }

  // Offerings
  Future<http.Response> syncOffering(Map<String, dynamic> data) async {
    return await post('/offerings', data);
  }

  // Expenses
  Future<http.Response> syncExpenses(Map<String, dynamic> data) async {
    return await post('/expenses/batch', data);
  }

  // Sabbat Validations
  Future<http.Response> finalizeSabbat(Map<String, dynamic> data) async {
    return await post('/sabbat-validations', data);
  }

  Future<http.Response> fetchSabbatsSansVersement(int fiangonanaId) async {
    return await get('/sabbat_validations?exists[versement]=false&fiangonana=$fiangonanaId');
  }

  Future<http.Response> fetchLastSabbatValidation(int fiangonanaId) async {
    final url = '/sabbat_validations?fiangonana=$fiangonanaId&order[dateSabbat]=desc&itemsPerPage=1';
    return await http.get(
      Uri.parse('${AppConfig.baseUrl}$url'),
      headers: {'Accept': 'application/ld+json'},
    );
  }

  // Versements
  Future<http.Response> postVersement(Map<String, dynamic> data) async {
    return await post('/versements', data);
  }

  // Charts
  Future<http.Response> fetchOfferingsChart(int fiangonanaId) async {
    return await get('/offering_total_by_fiangonanas?fiangonana_id=$fiangonanaId');
  }
}
