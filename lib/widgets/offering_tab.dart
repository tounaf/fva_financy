import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart' as constants;
import '../screens/offering_counter_screen.dart' as screen;

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
  _OfferingTabState createState() => _OfferingTabState();
}

class _OfferingTabState extends State<OfferingTab> {
  late Map<int, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var bill in widget.billTypes)
        bill: TextEditingController(text: widget.quantities[bill].toString())
    };
    _syncControllersWithQuantities();
  }

  void _syncControllersWithQuantities() {
    widget.billTypes.forEach((bill) {
      _controllers[bill]!.text = widget.quantities[bill].toString();
    });
  }

  @override
  void didUpdateWidget(OfferingTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantities != oldWidget.quantities) {
      _syncControllersWithQuantities();
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

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

  Color getOfferingColor(String offering) {
    switch (offering) {
      case 'R1':
        return const Color(0xFF4A90E2);
      case 'R2':
        return const Color(0xFF50C878);
      case 'Manga':
        return const Color(0xFF1E90FF);
      case 'Mena':
        return const Color(0xFFFF4040);
      case 'Mavo':
        return const Color(0xFFFFD700);
      case 'Maitso':
        return const Color(0xFF32CD32);
      case 'ARIVA':
        return const Color(0xFFD4A017);
      case 'Tapabolana':
        return const Color(0xFF50C878);
      case 'Sabata Mpitandrina':
        return const Color(0xFF50C878);
      default:
        return screen.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: getOfferingColor(widget.offering).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total ${widget.offering}: ${formatAmount(calculateTotal())}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: getOfferingColor(widget.offering),
                      ),
                    ),
                    if (widget.isCompleted)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...widget.billTypes.map((bill) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text(
                            '$bill AR',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _controllers[bill],
                            keyboardType: TextInputType.number,
                            enabled: !widget.isCompleted,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: '0',
                              filled: true,
                              fillColor: widget.isCompleted
                                  ? Colors.grey[300]
                                  : Colors.grey[100],
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: getOfferingColor(widget.offering),
                                ),
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                            onTap: () {
                              if (_controllers[bill]!.text == '0') {
                                _controllers[bill]!.selection = TextSelection(
                                  baseOffset: 0,
                                  extentOffset: _controllers[bill]!.text.length,
                                );
                              }
                            },
                            onChanged: (value) {
                              int count = int.tryParse(value) ?? 0;
                              widget.onQuantityChanged(bill, count);
                              if (_controllers[bill]!.text !=
                                  count.toString()) {
                                _controllers[bill]!.text = count.toString();
                              }
                            },
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            formatAmount((bill * (widget.quantities[bill] ?? 0))
                                .toDouble()),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(
                  height:
                      56), // Espace pour éviter que le contenu ne soit masqué par le bouton flottant
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: widget.isCompleted
              ? IconButton(
                  onPressed: widget.onToggleCompletion,
                  icon: const Icon(Icons.edit),
                  color: Colors.orange,
                  tooltip: 'Rééditer',
                )
              : IconButton(
                  onPressed: widget.onToggleCompletion,
                  icon: const Icon(Icons.check),
                  color: Colors.green,
                  tooltip: 'Terminer',
                ),
        ),
      ],
    );
  }
}
