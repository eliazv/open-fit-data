import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/format.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/sync_status_card.dart';
import '../notes/notes_screen.dart';
import 'home_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final isSyncing = asyncData.isLoading;
    final data = asyncData.valueOrNull;
    final error = asyncData.hasError ? asyncData.error.toString() : null;

    return RefreshIndicator(
      onRefresh: controller.sync,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SyncStatusCard(
            lastSync: data?.lastSync,
            archivedDays: data?.archivedDays ?? 0,
            recordCount: data?.recordCount ?? 0,
            isStale: data?.isStale ?? false,
            isSyncing: isSyncing,
            onSync: controller.sync,
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: error),
          ],
          const SizedBox(height: 20),
          Text('Ultimi giorni',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (data == null || data.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                title: 'Nessun dato ancora',
                message: 'Premi "Sincronizza ora" per importare i tuoi dati '
                    'da Health Connect e iniziare l\'archivio.',
                icon: Icons.directions_walk,
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                MetricCard(
                  label: 'Passi medi · 7g',
                  value: Format.intDot(data.avgSteps7),
                  subtitle: 'al giorno',
                  icon: Icons.directions_walk,
                ),
                MetricCard(
                  label: 'Passi medi · 30g',
                  value: Format.intDot(data.avgSteps30),
                  subtitle: 'al giorno',
                  icon: Icons.calendar_month,
                ),
                MetricCard(
                  label: 'Distanza media · 7g',
                  value: data.avgDistanceKm7 == null
                      ? '—'
                      : '${data.avgDistanceKm7!.toStringAsFixed(1)} km',
                  subtitle: 'al giorno',
                  icon: Icons.straighten,
                ),
                MetricCard(
                  label: 'Giorni archiviati',
                  value: '${data.archivedDays}',
                  subtitle: 'in totale',
                  icon: Icons.storage,
                ),
              ],
            ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_note),
              title: const Text('Come ti senti oggi?'),
              subtitle: const Text(
                  'Aggiungi una nota: energia, fatica, dolori. Migliora i '
                  'briefing AI.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotesScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message,
                  style:
                      TextStyle(color: theme.colorScheme.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }
}
