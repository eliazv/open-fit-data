import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/period.dart';
import '../archive/archive_controller.dart';
import '../home/home_controller.dart';
import '../home/home_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _silentSync());
  }

  Future<void> _silentSync() async {
    try {
      await ref.read(syncServiceProvider).sync(
            interactive: false,
            trigger: 'startup',
          );
      ref
        ..invalidate(homeControllerProvider)
        ..invalidate(archiveSummariesProvider)
        ..invalidate(exportBundleProvider)
        ..invalidate(exportPreviewProvider);
    } catch (_) {
      // Permessi assenti o errore: c'e' il sync manuale nella Home.
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(archivePeriodProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenFitData'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Period>(
                value: period,
                borderRadius: BorderRadius.circular(16),
                selectedItemBuilder: (context) => [
                  for (final p in Period.values)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text(p.label),
                      ],
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(archivePeriodProvider.notifier).state = value;
                },
                items: [
                  for (final p in Period.values)
                    DropdownMenuItem(
                      value: p,
                      child: Text(p.menuLabel),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: const HomeScreen(),
    );
  }
}
