import 'package:flutter/material.dart';
import 'package:fva_financy/screens/fiangonana_selection_screen.dart';
import 'package:fva_financy/screens/sync_screen.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/offering_tab.dart';
import '../models/offering_data.dart';
import '../utils/constants.dart';
import 'expense_screen.dart';
import 'vola_sisa_screen.dart';

const Color vibrantPurple = Color.fromARGB(255, 15, 27, 197);
const Color neonGreen = Color(0xFF39FF14);
const Color deepOrange = Color(0xFFFF5722);
const Color backgroundColor = Color(0xFFF0F2F5);
const Color expenseRed = Color(0xFFFF3366);
const Color cardColor = Colors.white;
const double cardElevation = 4.0;

class OfferingCounterScreen extends StatefulWidget {
  const OfferingCounterScreen({super.key});

  @override
  _OfferingCounterScreenState createState() => _OfferingCounterScreenState();
}

class _OfferingCounterScreenState extends State<OfferingCounterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OfferingData offeringData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: offeringTypes.length + 2, vsync: this);
    offeringData = OfferingData();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await offeringData.loadData();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  double calculateGrandTotal() {
    return offeringData.calculateGrandTotal() + offeringData.getTotalExpenses();
  }

  String formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: ' Ar').format(amount);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fiangonana_id');
    await prefs.remove('fiangonana_nom');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FiangonanaSelectionScreen()), // Assurez-vous que cet écran existe
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    Map<String, double> categoryTotals =
        offeringData.calculateTotalsByCategory();

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blueAccent,),
            onPressed: () async {
              await offeringData.resetData();
              setState(() {});
            },
            tooltip: 'Réinitialiser',
          )
        ]
      ),
      body: Column(
        children: [
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 160,
              width: double.infinity,
              color: vibrantPurple,
              alignment: Alignment.center,
              child: Text(
                'Fanisam-bola sy depanse isan-tsabata',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildSummaryCard('Vola miditra F', formatAmount(categoryTotals['Vola miditra F']!), neonGreen),
                  const SizedBox(height: 10),
                  _buildSummaryCard('Vola miditra A', formatAmount(categoryTotals['Vola miditra A']!), deepOrange),
                  const SizedBox(height: 10),
                  _buildSummaryCard('Total Dépenses', formatAmount(offeringData.getTotalExpenses()), expenseRed),
                  const SizedBox(height: 16),
                  _buildTotalCard('Total Général', formatAmount(calculateGrandTotal())),
                  const SizedBox(height: 16),
                  _buildTabs(context)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: vibrantPurple),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Menu',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Synchronisation'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SyncScreen(offeringData: offeringData))),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Déconnexion'),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmation'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Confirmer'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _logout();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Card(
      elevation: cardElevation,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: color)),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16))
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard(String label, String amount) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: vibrantPurple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return DefaultTabController(
      length: offeringTypes.length + 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: vibrantPurple,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              tabs: [
                ...offeringTypes.map((type) {
                  double total = offeringData.calculateTotalForOffering(type);
                  return   Tab(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  children: [
                                    Text(type),
                                    Text(
                                      formatAmount(total),
                                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                                    ),
                                  ],
                                ),
                                if (offeringData.completionStatus[type]!) 
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Icon(Icons.check_circle, size: 16, color: Colors.white),
                                  ),
                              ],
                            ),
                          );
                }).toList(),
                const Tab(child: Text('Dépenses')),
                const Tab(child: Text('Vola Sisa')),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: TabBarView(
              controller: _tabController,
              children: [
                ...offeringTypes.map((type) => OfferingTab(
                      offering: type,
                      billTypes: billTypes,
                      quantities: offeringData.quantities[type]!,
                      onQuantityChanged: (bill, count) {
                        setState(() => offeringData.updateQuantity(type, bill, count));
                      },
                      isCompleted: offeringData.completionStatus[type]!,
                      onToggleCompletion: () {
                        setState(() => offeringData.toggleCompletion(type));
                      },
                    )),
                ExpenseScreen(offeringData: offeringData),
                VolaSisaScreen(offeringData: offeringData),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}