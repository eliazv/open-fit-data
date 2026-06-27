import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/period.dart';
import '../../services/export_service.dart';
import '../../widgets/period_selector.dart';

class ExportPreviewQuery {
  ExportPreviewQuery({
    required this.period,
    required Set<ExportCategory> categories,
  }) : categories =
            (categories.toList()..sort((a, b) => a.index.compareTo(b.index)));

  final Period period;
  final List<ExportCategory> categories;

  Set<ExportCategory> get categorySet => categories.toSet();

  @override
  bool operator ==(Object other) {
    if (other is! ExportPreviewQuery) return false;
    if (period != other.period ||
        categories.length != other.categories.length) {
      return false;
    }
    for (var i = 0; i < categories.length; i++) {
      if (categories[i] != other.categories[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(period, Object.hashAll(categories));
}

final exportPreviewProvider =
    FutureProvider.family<ExportPreview, ExportPreviewQuery>(
        (ref, query) async {
  final repo = ref.read(archiveRepositoryProvider);
  final now = DateTime.now();
  final from = query.period.days == null
      ? DateTime(2000)
      : now.subtract(Duration(days: query.period.days! - 1));
  final summaries = query.period.days == null
      ? await repo.allSummaries()
      : await repo.summariesInRange(
          ExportScreenState.dayFormat.format(from),
          ExportScreenState.dayFormat.format(now),
        );
  final workouts = await repo.workoutsInRange(from, now);
  final rawRecords = await repo.rawInRange(from, now);
  return ref.read(exportServiceProvider).preview(
        format: ExportFormat.zip,
        summaries: summaries,
        workouts: workouts,
        rawRecords: rawRecords,
        categories: query.categorySet,
        periodLabel: query.period.label,
      );
});

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => ExportScreenState();
}

class ExportScreenState extends ConsumerState<ExportScreen> {
  static final DateFormat dayFormat = DateFormat('yyyy-MM-dd');
  Period _period = Period.d30;
  bool _busy = false;
  Set<ExportCategory> _categories = {...ExportCategory.values};

  Future<void> _export(ExportFormat format) async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(archiveRepositoryProvider);
      final now = DateTime.now();
      final from = _period.days == null
          ? DateTime(2000)
          : now.subtract(Duration(days: _period.days! - 1));

      final summaries = _period.days == null
          ? await repo.allSummaries()
          : await repo.summariesInRange(
              dayFormat.format(from),
              dayFormat.format(now),
            );
      final workouts = await repo.workoutsInRange(from, now);
      final rawRecords = await repo.rawInRange(from, now);

      await ref.read(exportServiceProvider).exportAndShare(
            format: format,
            summaries: summaries,
            workouts: workouts,
            rawRecords: rawRecords,
            categories: _categories,
            periodLabel: _period.label,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export fallito: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showExportSheet(ExportFormat format) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Condividi ${format.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('${_period.label} - ${_categories.length} contenuti'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Condividi'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _export(format);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Export')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Periodo', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: PeriodSelector(
              selected: _period,
              onChanged: (p) => setState(() => _period = p),
            ),
          ),
          const SizedBox(height: 24),
          Text('Contenuto', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final c in ExportCategory.values)
                  CheckboxListTile(
                    value: _categories.contains(c),
                    secondary: Icon(_categoryIconFor(c)),
                    title: Text(c.label),
                    onChanged: _busy
                        ? null
                        : (selected) => setState(() {
                              final next = {..._categories};
                              if (selected ?? false) {
                                next.add(c);
                              } else if (next.length > 1) {
                                next.remove(c);
                              }
                              _categories = next;
                            }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _ExportPreviewCard(period: _period, categories: _categories),
          const SizedBox(height: 24),
          Text('Formato', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_busy)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in ExportFormat.values)
                  ActionChip(
                    avatar: Icon(_iconFor(f), size: 18),
                    label: Text(f.label),
                    onPressed: () => _showExportSheet(f),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          Text(
            'Generazione locale. Nessun upload automatico.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  IconData _categoryIconFor(ExportCategory c) => switch (c) {
        ExportCategory.dailyMetrics => Icons.insights,
        ExportCategory.workouts => Icons.fitness_center,
        ExportCategory.rawRecords => Icons.storage,
      };

  IconData _iconFor(ExportFormat f) => switch (f) {
        ExportFormat.csv => Icons.table_chart_outlined,
        ExportFormat.json => Icons.data_object,
        ExportFormat.markdown => Icons.description_outlined,
        ExportFormat.zip => Icons.folder_zip_outlined,
      };
}

class _ExportPreviewCard extends ConsumerWidget {
  const _ExportPreviewCard({required this.period, required this.categories});

  final Period period;
  final Set<ExportCategory> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final query = ExportPreviewQuery(period: period, categories: categories);
    final asyncPreview = ref.watch(exportPreviewProvider(query));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.preview, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: asyncPreview.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Anteprima non disponibile: $e'),
                data: (preview) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Anteprima export', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${preview.rows} righe - '
                      '${_formatBytes(preview.estimatedBytes)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
