import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../widgets/bar_trend_chart.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/period_selector.dart';
import '../../widgets/weight_line_chart.dart';
import '../workouts/workouts_screen.dart';
import 'archive_controller.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(archivePeriodProvider);
    final asyncSummaries = ref.watch(archiveSummariesProvider);
    final theme = Theme.of(context);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(syncServiceProvider).sync(
              includeHistory: true,
              trigger: 'archive_refresh',
            );
        ref.invalidate(archiveSummariesProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: PeriodSelector(
            selected: period,
            onChanged: (p) =>
                ref.read(archivePeriodProvider.notifier).state = p,
          ),
        ),
        const SizedBox(height: 16),
        asyncSummaries.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('Errore: $e'),
          ),
          data: (summaries) => _content(context, theme, summaries),
        ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ThemeData theme,
    List<DailySummary> summaries,
  ) {
    if (summaries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: EmptyState(
          title: 'Archivio vuoto',
          message: 'Sincronizza dalla Home per popolare i trend.',
          icon: Icons.insights,
        ),
      );
    }

    final steps = summaries.map((s) => (s.steps ?? 0).toDouble()).toList();
    final weights = summaries
        .where((s) => s.weightKg != null)
        .map((s) => s.weightKg!)
        .toList();
    final totalSteps =
        summaries.fold<int>(0, (a, b) => a + (b.steps ?? 0));
    final avgSteps = (totalSteps / summaries.length).round();
    final totalKm =
        summaries.fold<double>(0, (a, b) => a + (b.distanceM ?? 0)) / 1000;
    final lastWeight = summaries.lastWhere(
      (s) => s.weightKg != null,
      orElse: () => summaries.last,
    );
    final sleepDays = summaries.where((s) => s.sleepMinutes != null).toList();
    final avgSleep = sleepDays.isEmpty
        ? null
        : (sleepDays.fold<int>(0, (a, b) => a + (b.sleepMinutes ?? 0)) /
                sleepDays.length)
            .round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Passi per giorno', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                BarTrendChart(values: steps),
              ],
            ),
          ),
        ),
        if (weights.length >= 2) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Peso', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  WeightLineChart(weights: weights),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 124,
          ),
          children: [
            MetricCard(
              label: 'Passi medi',
              value: Format.intDot(avgSteps),
              subtitle: 'al giorno',
              icon: Icons.directions_walk,
            ),
            MetricCard(
              label: 'Distanza totale',
              value: '${totalKm.toStringAsFixed(1)} km',
              icon: Icons.straighten,
            ),
            MetricCard(
              label: 'Sonno medio',
              value: Format.duration(avgSleep),
              icon: Icons.bedtime_outlined,
            ),
            MetricCard(
              label: 'Peso',
              value: lastWeight.weightKg == null
                  ? '—'
                  : '${lastWeight.weightKg!.toStringAsFixed(1)} kg',
              icon: Icons.monitor_weight_outlined,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Allenamenti'),
            subtitle: const Text('Vedi la lista degli allenamenti importati'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkoutsScreen()),
            ),
          ),
        ),
      ],
    );
  }
}
