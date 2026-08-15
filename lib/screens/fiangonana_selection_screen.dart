import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fva_financy/services/api_service.dart';
import 'package:fva_financy/screens/main_shell_screen.dart';
import 'package:fva_financy/theme/app_theme.dart';
import 'package:fva_financy/widgets/auto_update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class FiangonanaSelectionScreen extends StatefulWidget {
  const FiangonanaSelectionScreen({super.key});

  @override
  State<FiangonanaSelectionScreen> createState() =>
      _FiangonanaSelectionScreenState();
}

class _FiangonanaSelectionScreenState extends State<FiangonanaSelectionScreen> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kDebugMode) {
        _checkUpdate();
      }
    });
    _checkStoredFiangonana();
  }

  Future<void> _checkUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await ApiService().checkGitHubRelease();
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String latestVersionTag = data['tag_name'];
        final String latestVersion = latestVersionTag.replaceAll('v', '');

        if (_canUpdate(currentVersion, latestVersion)) {
          final List assets = data['assets'];
          final apkAsset =
              assets.firstWhere((asset) => asset['name'].endsWith('.apk'));
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
    if (fiangonanaId != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainShellScreen()),
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
      final response = await ApiService().validateFiangonanaCode(code);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final fiangonanas = data as List<dynamic>;

        if (fiangonanas.isNotEmpty) {
          final fiangonana = fiangonanas[0];
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('fiangonana_id', fiangonana['id']);
          await prefs.setString('fiangonana_nom', fiangonana['nom']);
          await prefs.setDouble(
            'fiangonana_caution',
            (fiangonana['caution'] as num?)?.toDouble() ?? 10000.0,
          );
          await prefs.setDouble(
            'fiangonana_rar',
            (fiangonana['rar'] as num?)?.toDouble() ?? 0.0,
          );
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainShellScreen()),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.church, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                'FVA Financy',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 32),
              FvaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 3,
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'Fidirana / Connexion',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ampidiro ny kaodin\'ny fiangonana mba hahafahanao miditra ao amin\'ny rafitra.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Kaodin\'ny Fiangonana',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.left,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.pin_outlined),
                        hintText: 'Oh: 77777',
                        errorText: _errorMessage,
                        hintStyle: GoogleFonts.poppins(),
                      ),
                      onSubmitted: (_) => _validateFiangonanaCode(),
                    ),
                    const SizedBox(height: 20),
                    FvaPrimaryButton(
                      label: 'Hiditra',
                      icon: Icons.login,
                      loading: _isLoading,
                      onPressed: _isLoading ? null : _validateFiangonanaCode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Icon(Icons.public,
                  size: 18, color: AppColors.onSurfaceVariant.withValues(alpha: 0.6)),
              const SizedBox(height: 6),
              Text(
                'Fivondronan\'ny Fiangonana FVA Madagascar',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
