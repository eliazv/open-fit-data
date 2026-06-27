import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../services/health_sync_service.dart';
import '../../services/sync_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _connect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final health = ref.read(healthSyncServiceProvider);
      await health.configure();

      final availability = await health.availability();
      if (availability == HealthAvailability.notInstalled) {
        throw Exception(
          'Health Connect non è installato. Installalo dal Play Store e riprova.',
        );
      }
      if (availability == HealthAvailability.needsUpdate) {
        throw Exception('Aggiorna Health Connect dal Play Store e riprova.');
      }

      final granted = await health.requestPermissions();
      if (!granted) throw const HealthPermissionDenied();

      // Primo sync + abilita auto-sync in background.
      await ref.read(syncServiceProvider).sync();
      await ref.read(backgroundSyncManagerProvider).enablePeriodicSync();

      final repo = ref.read(archiveRepositoryProvider);
      await repo.setMeta(MetaKeys.onboardingDone, 'true');
      await repo.setMeta(MetaKeys.autoSyncEnabled, 'true');

      ref.invalidate(onboardingDoneProvider);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 56, color: theme.colorScheme.primary),
                      const SizedBox(height: 24),
                      Text('I tuoi dati fitness,\nfinalmente tuoi.',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      Text(
                        'Open Fit Data archivia in locale i tuoi dati di Health '
                        'Connect. Niente account, niente cloud obbligatorio. '
                        'Esporti e generi briefing AI quando vuoi.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const _Bullet(
                          icon: Icons.sync, text: 'Sync automatico e manuale'),
                      const _Bullet(
                          icon: Icons.storage,
                          text: 'Archivio locale (SQLite)'),
                      const _Bullet(
                          icon: Icons.ios_share,
                          text: 'Export CSV / JSON / Markdown'),
                      const _Bullet(
                          icon: Icons.auto_awesome,
                          text: 'Briefing pronti per ChatGPT/Claude'),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(_error!,
                            style: TextStyle(color: theme.colorScheme.error)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _connect,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.health_and_safety),
                label: Text(_busy ? 'Collego…' : 'Collega Health Connect'),
              ),
              const SizedBox(height: 12),
              Text(
                'Chiediamo solo i permessi essenziali. Non sono consigli '
                'medici: solo fitness e benessere generale.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
