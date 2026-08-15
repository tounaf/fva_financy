import 'package:flutter/material.dart';
import 'package:fva_financy/models/offering_data.dart';
import 'package:fva_financy/screens/dashboard/offering_chart_screen.dart';
import 'package:fva_financy/screens/fiangonana_selection_screen.dart';
import 'package:fva_financy/screens/offering_counter_screen.dart';
import 'package:fva_financy/screens/sabbat_averser_screen.dart';
import 'package:fva_financy/screens/sync_screen.dart';
import 'package:fva_financy/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Coque principale Stitch : Daholobe / Synchro / Famintinana.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late final OfferingData offeringData;
  int _index = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    offeringData = OfferingData();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _confirmReset() async {
    final ok = await FvaConfirm.show(
      context,
      title: 'Réinitialiser ?',
      message: 'Toutes les saisies locales du sabbat seront effacées.',
      confirmLabel: 'Réinitialiser',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await offeringData.resetData();
    _onDataChanged();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fiangonana_id');
    await prefs.remove('fiangonana_nom');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const FiangonanaSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      OfferingCounterScreen(
        offeringData: offeringData,
        embedded: true,
        onDataChanged: _onDataChanged,
      ),
      SyncScreen(
        offeringData: offeringData,
        embedded: true,
        section: SyncSection.syncOnly,
        onDataChanged: _onDataChanged,
      ),
      SyncScreen(
        offeringData: offeringData,
        embedded: true,
        section: SyncSection.finalizeOnly,
        onDataChanged: _onDataChanged,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: FvaBrandHeader(
                actions: [
                  if (_index == 0)
                    IconButton(
                      tooltip: 'Réinitialiser',
                      onPressed: _confirmReset,
                      icon: const Icon(Icons.refresh, color: AppColors.primary),
                    ),
                  IconButton(
                    tooltip: 'Menu',
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    icon: const Icon(Icons.menu, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            Expanded(child: pages[_index]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.outline.withValues(alpha: 0.5))),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Daholobe',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sync),
              label: 'Synchro',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fact_check_outlined),
              activeIcon: Icon(Icons.fact_check),
              label: 'Famintinana',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet, color: AppColors.success),
            title: const Text('Faire un Versement'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SabbatAverserScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Compte'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OfferingChartScreen()),
              );
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.expense),
            title: const Text('Déconnexion'),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmation'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirmer'),
                    ),
                  ],
                ),
              );
              if (confirm == true) await _logout();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
