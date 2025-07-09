import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    _checkStoredFiangonana();
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
        _errorMessage = 'Veuillez entrer un code';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/fiangonanas?code=$code'),
        headers: {'Content-Type': 'application/json'},
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
