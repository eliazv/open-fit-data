import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/metric_style.dart';
import '../../data/models/metric_type.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/source_pie_chart.dart';
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
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: 168,
              ),
              children: [
                MetricCard(
                  label: 'Passi medi · 7g',
                  value: Format.intDot(data.avgSteps7),
                  subtitle: 'al giorno',
                  icon: MetricType.steps.style.icon,
                  color: MetricType.steps.style.color,
                  trendValues: data.stepsTrend7,
                  deltaPercent: data.stepsDeltaPercent,
                  trendAsBars: true,
                ),
                MetricCard(
                  label: 'Sonno medio · 7g',
                  value: _averageSleep(data.sleepTrend7),
                  subtitle: 'per notte',
                  icon: MetricType.sleep.style.icon,
                  color: MetricType.sleep.style.color,
                  trendValues: data.sleepTrend7,
                  deltaPercent: data.sleepDeltaPercent,
                  trendAsBars: true,
                ),
                MetricCard(
                  label: 'Distanza media · 7g',
                  value: data.avgDistanceKm7 == null
                      ? '—'
                      : '${data.avgDistanceKm7!.toStringAsFixed(1)} km',
                  subtitle: 'al giorno',
                  icon: MetricType.distance.style.icon,
                  color: MetricType.distance.style.color,
                  trendValues: data.distanceTrend7,
                  deltaPercent: data.distanceDeltaPercent,
                  trendAsBars: true,
                ),
                MetricCard(
                  label: 'Battito medio · 7g',
                  value: _averageHeartRate(data.heartRateTrend7),
                  subtitle: 'bpm',
                  icon: MetricType.heartRate.style.icon,
                  color: MetricType.heartRate.style.color,
                  trendValues: data.heartRateTrend7,
                  deltaPercent: data.heartRateDeltaPercent,
                ),
              ],
            ),
          if (data != null && data.metricStatuses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Copertura metriche',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  if (data.sourceDistribution.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sorgenti dati',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SourcePieChart(values: data.sourceDistribution),
                    ),
                  ],
                  for (final status in data.metricStatuses.take(6))
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.dataset_outlined),
                      title: Text(status.label),
                      subtitle: Text(
                        '${status.records} record · ${status.sources} sorgenti',
                      ),
                      trailing: Text(
                        status.latest == null
                            ? '—'
                            : '${status.latest!.day}/${status.latest!.month}',
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          OpenContainer(
            closedElevation: 0,
            openBuilder: (_, __) => const NotesScreen(),
            closedBuilder: (context, open) => Card(
              child: ListTile(
                leading: const Icon(Icons.edit_note),
                title: const Text('Come ti senti oggi?'),
                subtitle: const Text(
                    'Aggiungi una nota: energia, fatica, dolori. Migliora i '
                    'briefing AI.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: open,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _averageSleep(List<double> hours) {
  final nonZero = hours.where((v) => v > 0).toList();
  if (nonZero.isEmpty) return '—';
  final avg = nonZero.reduce((a, b) => a + b) / nonZero.length;
  return '${avg.toStringAsFixed(1)} h';
}

String _averageHeartRate(List<double> bpm) {
  final nonZero = bpm.where((v) => v > 0).toList();
  if (nonZero.isEmpty) return '—';
  final avg = nonZero.reduce((a, b) => a + b) / nonZero.length;
  return avg.round().toString();
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
