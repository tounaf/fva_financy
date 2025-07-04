import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
        final fiangonanas = data['hydra:member'] as List<dynamic>;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner Fiangonana'),
        backgroundColor: const Color.fromRGBO(156, 24, 196, 1), // vibrantPurple
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Code Fiangonana',
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              onSubmitted: (_) => _validateFiangonanaCode(),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _validateFiangonanaCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(156, 24, 196, 1), // vibrantPurple
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Valider'),
                  ),
          ],
        ),
      ),
    );
  }
}