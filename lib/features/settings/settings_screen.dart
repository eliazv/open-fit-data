import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoSync = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(archiveRepositoryProvider);
    final v = await repo.getMeta(MetaKeys.autoSyncEnabled);
    setState(() {
      _autoSync = v != 'false';
      _loading = false;
    });
  }

  Future<void> _toggleAutoSync(bool value) async {
    setState(() => _autoSync = value);
    final repo = ref.read(archiveRepositoryProvider);
    final bg = ref.read(backgroundSyncManagerProvider);
    await repo.setMeta(MetaKeys.autoSyncEnabled, value ? 'true' : 'false');
    if (value) {
      await bg.enablePeriodicSync();
    } else {
      await bg.disablePeriodicSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Sincronizzazione automatica'),
                  subtitle: const Text(
                    'Importa i dati in background ~2 volte al giorno per non '
                    'superare la finestra di 30 giorni di Health Connect.',
                  ),
                  value: _autoSync,
                  onChanged: _toggleAutoSync,
                ),
                const Divider(),
                const ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Privacy'),
                  subtitle: Text(
                    'Local-first: i dati restano sul dispositivo. Nessun '
                    'account, nessun upload automatico, nessun tracciamento.',
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.health_and_safety_outlined),
                  title: Text('Disclaimer'),
                  subtitle: Text(
                    'Open Fit Data non fornisce consigli medici. I contenuti '
                    'riguardano fitness e benessere generale.',
                  ),
                ),
                const AboutListTile(
                  icon: Icon(Icons.info_outline),
                  applicationName: AppConstants.appName,
                  applicationVersion: '0.1.0',
                  applicationLegalese: 'Licenza AGPL-3.0',
                  child: Text('Informazioni'),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Archivio. Export. AI-ready.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
