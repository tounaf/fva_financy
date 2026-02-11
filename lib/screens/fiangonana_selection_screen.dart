import 'package:flutter/material.dart';
import 'package:fva_financy/widgets/auto_update_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'offering_counter_screen.dart';

class FiangonanaSelectionScreen extends StatefulWidget {
  const FiangonanaSelectionScreen({super.key});

  @override
  _FiangonanaSelectionScreenState createState() => _FiangonanaSelectionScreenState();
}

class _FiangonanaSelectionScreenState extends State<FiangonanaSelectionScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUpdate(); 
    });

    _checkStoredFiangonana();
  }

  Future<void> _checkUpdate() async {
  try {
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

      if (_canUpdate(currentVersion, latestVersion)) {
        final List assets = data['assets'];
        final apkAsset = assets.firstWhere((asset) => asset['name'].endsWith('.apk'));
        final String downloadUrl = apkAsset['browser_download_url'];

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

bool _canUpdate(String current, String latest) {
  List<int> currentParts = current.split('.').map(int.parse).toList();
  List<int> latestParts = latest.split('.').map(int.parse).toList();

  for (int i = 0; i < latestParts.length; i++) {
    if (latestParts[i] > currentParts[i]) return true;
    if (latestParts[i] < currentParts[i]) return false;
  }
  return false;
}


  Future<void> _checkStoredFiangonana() async {
    final prefs = await SharedPreferences.getInstance();
    final fiangonanaId = prefs.getInt('fiangonana_id');
    if (fiangonanaId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OfferingCounterScreen()),
      );
    }
  }

  Future<void> _validateFiangonanaCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer code';
        _isLoading = false;
      });
      return;
    }

    try {
      //var url = Uri.parse('http://localhost:8000/api/fiangonanas?code=$code');
      final response = await http.get(
        Uri.parse('https://fva-vitaonyasany.mg/admin-api/public/index.php/api/fiangonanas?code=$code'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fiangonanas = data as List<dynamic>;
        
        if (fiangonanas.isNotEmpty) {
          final fiangonana = fiangonanas[0];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('fiangonana_id', fiangonana['id']);
          await prefs.setString('fiangonana_nom', fiangonana['nom']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OfferingCounterScreen()),
          );
        } else {
          setState(() {
            _errorMessage = 'Code invalide';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Erreur serveur: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF3F51B5); // Indigo

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with wave
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 250,
                color: primaryColor,
                alignment: Alignment.center,
                child: Text(
                  'Connexion Fiangonana',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Code input
                  TextField(
                    controller: _codeController,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.vpn_key_outlined),
                      hintText: 'Code Fiangonana',
                      errorText: _errorMessage,
                      hintStyle: GoogleFonts.poppins(),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _validateFiangonanaCode(),
                  ),
                  const SizedBox(height: 24),

                  // Validate Button
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _validateFiangonanaCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Valider',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Wavy header clipper
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2, size.height,
      size.width, size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
