import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smooth_charts/smooth_charts.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../core/period.dart';
import '../../data/db/database.dart';
import '../../services/export_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format.dart';
import '../../widgets/metric_card.dart';
import '../archive/archive_controller.dart';
import '../settings/settings_screen.dart';
import '../workouts/workouts_screen.dart';
import 'home_controller.dart';

final periodWorkoutsProvider = FutureProvider<List<Workout>>((ref) {
  final period = ref.watch(archivePeriodProvider);
  final repo = ref.watch(archiveRepositoryProvider);
  final now = DateTime.now();
  final from = period.days == null
      ? DateTime(2000)
      : now.subtract(Duration(days: period.days! - 1));
  return repo.workoutsInRange(from, now);
});

final exportBundleProvider =
    FutureProvider.family<_ExportBundle, Period>((ref, period) async {
  final repo = ref.watch(archiveRepositoryProvider);
  final now = DateTime.now();
  final from = period.days == null
      ? DateTime(2000)
      : now.subtract(Duration(days: period.days! - 1));
  final summaries = period.days == null
      ? await repo.allSummaries()
      : await repo.summariesInRange(
          _dayFormat.format(from),
          _dayFormat.format(now),
        );
  final workouts = await repo.workoutsInRange(from, now);
  final rawRecords = await repo.rawInRange(from, now);
  final profile = _ProfileData(
    weightKg: await repo.getMeta(MetaKeys.profileWeightKg),
    heightCm: await repo.getMeta(MetaKeys.profileHeightCm),
    birthDate: await repo.getMeta(MetaKeys.profileBirthDate),
  );
  return _ExportBundle(summaries, workouts, rawRecords, profile);
});

final exportPreviewProvider =
    FutureProvider.family<ExportPreview, Period>((ref, period) async {
  final bundle = await ref.watch(exportBundleProvider(period).future);
  return ref.read(exportServiceProvider).preview(
        format: ExportFormat.zip,
        summaries: bundle.summaries,
        workouts: bundle.workouts,
        rawRecords: bundle.rawRecords,
        categories: {...ExportCategory.values},
        periodLabel: period.label,
      );
});

final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');

final profileProvider = FutureProvider<_ProfileData>((ref) async {
  final repo = ref.watch(archiveRepositoryProvider);
  return _ProfileData(
    weightKg: await repo.getMeta(MetaKeys.profileWeightKg),
    heightCm: await repo.getMeta(MetaKeys.profileHeightCm),
    birthDate: await repo.getMeta(MetaKeys.profileBirthDate),
  );
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeControllerProvider);
    final summaries = ref.watch(archiveSummariesProvider);
    final workouts = ref.watch(periodWorkoutsProvider);
    final profile = ref.watch(profileProvider);
    final period = ref.watch(archivePeriodProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final data = home.valueOrNull;
    final error = home.hasError ? home.error.toString() : null;

    return RefreshIndicator(
      onRefresh: () async {
        await _syncNow(controller);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          summaries.when(
            loading: () => const _LoadingBlock(),
            error: (e, _) =>
                _ErrorBanner(message: 'Archivio non disponibile: $e'),
            data: (items) => _StepsOverview(
              summaries: items,
              period: period,
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: error),
          ],
          summaries.maybeWhen(
            data: (items) => _MetricGrid(summaries: items),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 18),
          _ProfileRow(profile: profile),
          const SizedBox(height: 18),
          workouts.when(
            loading: () => const _LoadingBlock(height: 88),
            error: (e, _) =>
                _ErrorBanner(message: 'Allenamenti non disponibili: $e'),
            data: (items) => Column(
              children: [
                if (items.isNotEmpty) ...[
                  _RecentWorkoutCards(workouts: items.take(3).toList()),
                  const SizedBox(height: 14),
                ],
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    mainAxisExtent: 112,
                  ),
                  children: [
                    OpenContainer(
                      closedElevation: 0,
                      closedColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      closedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      openBuilder: (_, __) => const WorkoutsScreen(),
                      closedBuilder: (context, open) => _CompactActionTile(
                        icon: Icons.fitness_center,
                        title: 'Allenamenti',
                        onTap: open,
                      ),
                    ),
                    _QuickTile(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Briefing AI',
                      subtitle: period.label,
                      onTap: () => _showBriefingSheet(context, period),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
              _QuickTile(
                icon: Icons.sync,
                title: home.isLoading ? 'Sincronizzo' : 'Sincronizza',
                subtitle: _syncSubtitle(data),
                onTap: home.isLoading
                    ? null
                    : () {
                        _syncNow(controller);
                      },
                spinning: home.isLoading,
              ),
              _QuickTile(
                icon: Icons.ios_share_outlined,
                title: 'Export',
                subtitle: period.label,
                onTap: () => _showExportSheet(context, period),
              ),
              OpenContainer(
                closedElevation: 0,
                closedColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                closedShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                openBuilder: (_, __) => const SettingsScreen(),
                closedBuilder: (context, open) => _QuickTile(
                  icon: Icons.tune_outlined,
                  title: 'Impostazioni',
                  subtitle: 'Import e privacy',
                  onTap: open,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _syncSubtitle(HomeData? data) {
    if (data?.lastSync == null) return 'Mai eseguita';
    return DateFormat('dd/MM HH:mm').format(data!.lastSync!);
  }

  Future<void> _syncNow(HomeController controller) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.sync();
      ref
        ..invalidate(archiveSummariesProvider)
        ..invalidate(periodWorkoutsProvider)
        ..invalidate(exportBundleProvider)
        ..invalidate(exportPreviewProvider);
      if (!mounted) return;
      final data = ref.read(homeControllerProvider).valueOrNull;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            data == null
                ? 'Sincronizzazione completata'
                : 'Sincronizzati ${Format.intDot(data.recordCount)} record',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Sync fallito: $e')));
    }
  }

  Future<void> _showBriefingSheet(BuildContext context, Period period) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _BriefingSheet(period: period),
    );
  }

  Future<void> _showExportSheet(BuildContext context, Period period) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => _ExportSheet(period: period),
    );
  }
}

class _StepsOverview extends StatelessWidget {
  const _StepsOverview({
    required this.summaries,
    required this.period,
  });

  final List<DailySummary> summaries;
  final Period period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (summaries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: EmptyState(
          title: 'Nessun dato ancora',
          message: 'Sincronizza per importare i dati da Health Connect.',
          icon: Icons.directions_walk,
        ),
      );
    }

    final steps = summaries.map((s) => (s.steps ?? 0).toDouble()).toList();
    final totalSteps = summaries.fold<int>(0, (a, b) => a + (b.steps ?? 0));
    final daysWithSteps = summaries.where((s) => s.steps != null).length;
    final avgSteps =
        daysWithSteps == 0 ? 0 : (totalSteps / daysWithSteps).round();
    final totalKm =
        summaries.fold<double>(0, (a, b) => a + (b.distanceM ?? 0)) / 1000;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              period == Period.today ? 'Passi di oggi' : 'Passi per giorno',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (period == Period.today)
              _TodayStepsRing(steps: totalSteps)
            else
              _StepsLineChart(values: steps, height: 180),
            const Divider(height: 24),
            _StatRow(label: 'Passi medi', value: Format.intDot(avgSteps)),
            _StatRow(
              label: 'Distanza totale',
              value: '${totalKm.toStringAsFixed(1)} km',
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.summaries});

  final List<DailySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final metrics = _metricsFrom(summaries).take(4).toList();
    if (metrics.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          mainAxisExtent: 136,
        ),
        children: [
          for (final m in metrics)
            MetricCard(
              label: m.label,
              value: m.value,
              subtitle: m.subtitle,
              icon: m.icon,
            ),
        ],
      ),
    );
  }

  List<_MetricItem> _metricsFrom(List<DailySummary> s) {
    final sleepDays = s.where((x) => x.sleepMinutes != null).toList();
    final hrDays = s.where((x) => x.avgHr != null).toList();
    final calories = s.fold<double>(0, (a, b) => a + (b.activeCalories ?? 0));
    final weights = s.where((x) => x.weightKg != null).toList();
    final vo2 = s.where((x) => x.vo2max != null).toList();
    final hrv = s.where((x) => x.hrvMs != null).toList();

    return [
      if (sleepDays.isNotEmpty)
        _MetricItem(
          label: 'Sonno medio',
          value: Format.duration(
            (sleepDays.fold<int>(0, (a, b) => a + (b.sleepMinutes ?? 0)) /
                    sleepDays.length)
                .round(),
          ),
          subtitle: 'per notte',
          icon: Icons.bedtime_outlined,
        ),
      if (hrDays.isNotEmpty)
        _MetricItem(
          label: 'Battito medio',
          value: (hrDays.fold<double>(0, (a, b) => a + (b.avgHr ?? 0)) /
                  hrDays.length)
              .round()
              .toString(),
          subtitle: 'bpm',
          icon: Icons.favorite_outline,
        ),
      if (calories > 0)
        _MetricItem(
          label: 'Calorie attive',
          value: Format.intDot(calories.round()),
          subtitle: 'totali',
          icon: Icons.local_fire_department_outlined,
        ),
      if (weights.isNotEmpty)
        _MetricItem(
          label: 'Peso',
          value: '${weights.last.weightKg!.toStringAsFixed(1)} kg',
          subtitle: 'ultimo dato',
          icon: Icons.monitor_weight_outlined,
        ),
      if (vo2.isNotEmpty)
        _MetricItem(
          label: 'VO2max',
          value: vo2.last.vo2max!.toStringAsFixed(1),
          subtitle: 'ultimo dato',
          icon: Icons.speed_outlined,
        ),
      if (hrv.isNotEmpty)
        _MetricItem(
          label: 'HRV',
          value: '${hrv.last.hrvMs!.round()} ms',
          subtitle: 'ultimo dato',
          icon: Icons.show_chart,
        ),
    ];
  }
}

class _ProfileRow extends ConsumerWidget {
  const _ProfileRow({required this.profile});

  final AsyncValue<_ProfileData> profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = profile.valueOrNull ?? const _ProfileData();
    return SizedBox(
      height: 96,
      child: Row(
        children: [
          Expanded(
            child: _ProfileTile(
              label: 'Peso',
              value: data.weightKg == null ? '--' : '${data.weightKg} kg',
              icon: Icons.monitor_weight_outlined,
              onTap: () => _editProfileValue(
                context,
                ref,
                key: MetaKeys.profileWeightKg,
                title: 'Peso',
                suffix: 'kg',
                initialValue: data.weightKg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ProfileTile(
              label: 'Altezza',
              value: data.heightCm == null ? '--' : '${data.heightCm} cm',
              icon: Icons.height,
              onTap: () => _editProfileValue(
                context,
                ref,
                key: MetaKeys.profileHeightCm,
                title: 'Altezza',
                suffix: 'cm',
                initialValue: data.heightCm,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ProfileTile(
              label: 'Nascita',
              value: data.birthDate ?? '--',
              icon: Icons.cake_outlined,
              onTap: () => _editProfileValue(
                context,
                ref,
                key: MetaKeys.profileBirthDate,
                title: 'Data di nascita',
                hint: 'YYYY-MM-DD',
                initialValue: data.birthDate,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfileValue(
    BuildContext context,
    WidgetRef ref, {
    required String key,
    required String title,
    String? suffix,
    String? hint,
    String? initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
          ),
          keyboardType: suffix == null
              ? TextInputType.datetime
              : const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
    if (value == null) return;
    await ref.read(archiveRepositoryProvider).setMeta(key, value);
    ref
      ..invalidate(profileProvider)
      ..invalidate(exportBundleProvider)
      ..invalidate(exportPreviewProvider);
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayStepsRing extends StatelessWidget {
  const _TodayStepsRing({required this.steps});

  static const int goal = 10000;

  final int steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = (steps / goal).clamp(0.0, 1.0);
    return SizedBox(
      height: 180,
      child: Center(
        child: SizedBox(
          width: 148,
          height: 148,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 16,
                  strokeCap: StrokeCap.round,
                  backgroundColor: theme.colorScheme.surface,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Format.intDot(steps),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'di ${Format.intDot(goal)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepsLineChart extends StatelessWidget {
  const _StepsLineChart({
    required this.values,
    required this.height,
  });

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleaned = values.where((v) => v.isFinite && v >= 0).toList();
    if (cleaned.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Servono almeno 2 giorni',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: SmoothLineChart(
        points: [
          [
            for (var i = 0; i < cleaned.length; i++)
              ChartPair(i.toDouble(), cleaned[i]),
          ],
        ],
        color: theme.colorScheme.primary,
        isCurved: true,
        yLabelFormatter: (v) => v.round().toString(),
      ),
    );
  }
}

class _RecentWorkoutCards extends StatelessWidget {
  const _RecentWorkoutCards({required this.workouts});

  final List<Workout> workouts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: workouts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _WorkoutMiniCard(workout: workouts[i]),
      ),
    );
  }
}

class _WorkoutMiniCard extends StatelessWidget {
  const _WorkoutMiniCard({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateFormat('dd/MM').format(workout.startTime);
    final minutes = workout.durationSec == null
        ? null
        : '${(workout.durationSec! / 60).round()} min';
    final km = workout.distanceM == null
        ? null
        : '${(workout.distanceM! / 1000).toStringAsFixed(1)} km';

    return SizedBox(
      width: 156,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.directions_run, color: theme.colorScheme.primary),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.workoutType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [date, minutes, km].whereType<String>().join(' - '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExportSheet extends ConsumerStatefulWidget {
  const _ExportSheet({required this.period});

  final Period period;

  @override
  ConsumerState<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<_ExportSheet> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = {...ExportCategory.values};
    final preview = ref.watch(exportPreviewProvider(widget.period));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.46,
      minChildSize: 0.32,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Export', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          preview.maybeWhen(
            data: (data) => Text(
              '${widget.period.longLabel} - ${data.rows} righe',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            orElse: () => Text(
              widget.period.longLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          preview.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Anteprima non disponibile: $e'),
            data: (_) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in ExportFormat.values)
                  ActionChip(
                    avatar: Icon(_iconFor(f), size: 18),
                    label: Text(f.label),
                    onPressed: _busy ? null : () => _export(f, categories),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(
    ExportFormat format,
    Set<ExportCategory> categories,
  ) async {
    setState(() => _busy = true);
    try {
      final bundle = await ref.read(exportBundleProvider(widget.period).future);
      await ref.read(exportServiceProvider).exportAndShare(
            format: format,
            summaries: bundle.summaries,
            workouts: bundle.workouts,
            rawRecords: bundle.rawRecords,
            categories: categories,
            periodLabel: widget.period.label,
            profile: bundle.profile.toMap(),
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  IconData _iconFor(ExportFormat f) => switch (f) {
        ExportFormat.csv => Icons.table_chart_outlined,
        ExportFormat.json => Icons.data_object,
        ExportFormat.markdown => Icons.description_outlined,
        ExportFormat.zip => Icons.folder_zip_outlined,
      };
}

class _BriefingSheet extends ConsumerWidget {
  const _BriefingSheet({required this.period});

  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  final Period period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.42,
      maxChildSize: 0.92,
      builder: (context, controller) => FutureBuilder<String>(
        future: _buildBriefing(ref),
        builder: (context, snapshot) {
          final text = snapshot.data;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: [
                    Text('Briefing AI', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      period.longLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const LinearProgressIndicator()
                    else if (snapshot.hasError)
                      Text('Briefing non disponibile: ${snapshot.error}')
                    else
                      SelectableText(
                        text ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.copy),
                          label: const Text('Copia'),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: text ?? ''),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Briefing copiato'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Condividi'),
                          onPressed: () => SharePlus.instance.share(
                            ShareParams(text: text ?? ''),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String> _buildBriefing(WidgetRef ref) async {
    final repo = ref.read(archiveRepositoryProvider);
    final now = DateTime.now();
    final from = period.days == null
        ? DateTime(2000)
        : now.subtract(Duration(days: period.days! - 1));
    final summaries = period.days == null
        ? await repo.allSummaries()
        : await repo.summariesInRange(_fmt.format(from), _fmt.format(now));
    final note = await repo.latestNote();
    final noteText = note == null ? null : _formatNote(note);
    final profile = _ProfileData(
      weightKg: await repo.getMeta(MetaKeys.profileWeightKg),
      heightCm: await repo.getMeta(MetaKeys.profileHeightCm),
      birthDate: await repo.getMeta(MetaKeys.profileBirthDate),
    );
    return ref.read(aiBriefingServiceProvider).buildForPeriod(
          primary: summaries,
          periodLabel: period.longLabel.toLowerCase(),
          userNote: noteText,
          profile: profile.briefingText,
        );
  }

  String _formatNote(UserNote n) {
    final parts = <String>[
      if (n.energyLevel != null) 'energia ${n.energyLevel}/5',
      if (n.fatigueLevel != null) 'fatica ${n.fatigueLevel}/5',
      if (n.painNotes != null) 'dolori: ${n.painNotes}',
      if (n.freeNote != null) n.freeNote!,
    ];
    return parts.isEmpty ? '' : '(${n.date}) ${parts.join('; ')}';
  }
}

class _CompactActionTile extends StatelessWidget {
  const _CompactActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall),
                  ),
                  const Icon(Icons.chevron_right, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.spinning = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: spinning ? 1 : 0),
                duration: const Duration(milliseconds: 700),
                builder: (context, turns, child) => Transform.rotate(
                  angle: turns * 6.28318,
                  child: child,
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  const _MetricItem({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
}

class _ExportBundle {
  const _ExportBundle(
    this.summaries,
    this.workouts,
    this.rawRecords,
    this.profile,
  );

  final List<DailySummary> summaries;
  final List<Workout> workouts;
  final List<HealthRawRecord> rawRecords;
  final _ProfileData profile;
}

class _ProfileData {
  const _ProfileData({
    this.weightKg,
    this.heightCm,
    this.birthDate,
  });

  final String? weightKg;
  final String? heightCm;
  final String? birthDate;

  Map<String, String> toMap() {
    return {
      if (weightKg != null && weightKg!.isNotEmpty) 'weight_kg': weightKg!,
      if (heightCm != null && heightCm!.isNotEmpty) 'height_cm': heightCm!,
      if (birthDate != null && birthDate!.isNotEmpty) 'birth_date': birthDate!,
    };
  }

  String get briefingText {
    final parts = <String>[
      if (weightKg != null && weightKg!.isNotEmpty) 'peso $weightKg kg',
      if (heightCm != null && heightCm!.isNotEmpty) 'altezza $heightCm cm',
      if (birthDate != null && birthDate!.isNotEmpty) 'nascita $birthDate',
    ];
    return parts.join('; ');
  }
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock({this.height = 220});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(child: CircularProgressIndicator()),
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
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
