import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../ai_briefing/ai_briefing_screen.dart';
import '../archive/archive_screen.dart';
import '../export/export_screen.dart';
import '../home/home_controller.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _titles = ['Open Fit Data', 'Archivio', 'AI', 'Export'];
  static const _pages = [
    HomeScreen(),
    ArchiveScreen(),
    AiBriefingScreen(),
    ExportScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Sync silenzioso all'avvio (non interattivo): aggiorna i dati se i
    // permessi sono già concessi, senza disturbare l'utente.
    WidgetsBinding.instance.addPostFrameCallback((_) => _silentSync());
  }

  Future<void> _silentSync() async {
    try {
      await ref.read(syncServiceProvider).sync(
        interactive: false,
        trigger: 'startup',
      );
      ref.invalidate(homeControllerProvider);
    } catch (_) {
      // permessi assenti o errore: si ignora, c'è il sync manuale.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Impostazioni',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: PageTransitionSwitcher(
        transitionBuilder: (child, primary, secondary) => FadeThroughTransition(
          animation: primary,
          secondaryAnimation: secondary,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_index),
          child: _pages[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Archivio',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.ios_share_outlined),
            selectedIcon: Icon(Icons.ios_share),
            label: 'Export',
          ),
        ],
      ),
    );
  }
}
