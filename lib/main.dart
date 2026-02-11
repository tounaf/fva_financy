import 'package:flutter/material.dart';
import 'package:fva_financy/screens/fiangonana_selection_screen.dart';
import 'package:fva_financy/widgets/auto_update_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';

void main() {
  runApp(const OfferingCounterApp());
}

class OfferingCounterApp extends StatefulWidget {
  const OfferingCounterApp({super.key});

  @override
  State<OfferingCounterApp> createState() => _OfferingCounterAppState();
}

class _OfferingCounterAppState extends State<OfferingCounterApp> {
  
  @override
  void initState() {
    super.initState();
    // On attend que le premier frame soit dessiné avant de vérifier
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdate();
    });
  }

Future<void> _checkUpdate() async {
  try {
    // 1. Récupérer les infos de la version actuelle de l'APK installé
    final packageInfo = await PackageInfo.fromPlatform();
    // Sur GitHub Actions on a mis v1.0.${github.run_number}
    // currentVersion sera par exemple "1.0.3"
    final currentVersion = packageInfo.version; 

    // 2. Interroger l'API GitHub pour la dernière Release
    const String githubUser = "tounaf";
    const String githubRepo = "fva_financy";
    const String apiUrl = "https://api.github.com/repos/$githubUser/$githubRepo/releases/latest";

    final response = await http.get(Uri.parse(apiUrl));
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String latestVersionTag = data['tag_name']; // ex: "v1.0.5"
      final String latestVersion = latestVersionTag.replaceAll('v', ''); // devient "1.0.5"

      // 3. Comparer les versions
      if (_canUpdate(currentVersion, latestVersion)) {
        // Trouver l'URL de l'APK dans les "assets" de la release
        final List assets = data['assets'];
        final apkAsset = assets.firstWhere((asset) => asset['name'].endsWith('.apk'));
        final String downloadUrl = apkAsset['browser_download_url'];

        // 4. Afficher le dialogue de mise à jour
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AutoUpdateDialog(
            url: downloadUrl,
            version: latestVersion,
          ),
        );
      }
    }
  } catch (e) {
    debugPrint("Erreur lors de la vérification de mise à jour: $e");
  }
}

// Logique de comparaison simple (1.0.3 vs 1.0.5)
bool _canUpdate(String current, String latest) {
  List<int> currentParts = current.split('.').map(int.parse).toList();
  List<int> latestParts = latest.split('.').map(int.parse).toList();

  for (int i = 0; i < latestParts.length; i++) {
    if (latestParts[i] > currentParts[i]) return true;
    if (latestParts[i] < currentParts[i]) return false;
  }
  return false;
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offering Counter',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(156, 24, 196, 1),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const FiangonanaSelectionScreen(),
    );
  }
}