import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/period.dart';
import '../../services/export_service.dart';
import '../../widgets/period_selector.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');
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
          : await repo.summariesInRange(_fmt.format(from), _fmt.format(now));
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
              'Condividi export ${format.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Periodo: ${_period.label} · Categorie: '
              '${_categories.map((c) => c.label).join(', ')}',
            ),
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
    return ListView(
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
        Text('Categorie', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...ExportCategory.values.map(
          (c) => CheckboxListTile(
            value: _categories.contains(c),
            secondary: Icon(_categoryIconFor(c)),
            title: Text(c.label),
            subtitle: Text(_categoryDescFor(c)),
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
          ...ExportFormat.values.map(
            (f) => Card(
              child: ListTile(
                leading: Icon(_iconFor(f)),
                title: Text(f.label),
                subtitle: Text(_descFor(f)),
                trailing: const Icon(Icons.ios_share),
                onTap: () => _showExportSheet(f),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'I file vengono generati in locale e aperti nel menu di '
          'condivisione: nessun upload automatico.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  IconData _categoryIconFor(ExportCategory c) => switch (c) {
        ExportCategory.dailyMetrics => Icons.insights,
        ExportCategory.workouts => Icons.fitness_center,
        ExportCategory.rawRecords => Icons.storage,
      };

  String _categoryDescFor(ExportCategory c) => switch (c) {
        ExportCategory.dailyMetrics => 'Passi, distanza, sonno, peso, battito e VO2max',
        ExportCategory.workouts => 'Sessioni, durata, distanza, ritmo, frequenza e sorgente',
        ExportCategory.rawRecords => 'Record normalizzati e granulari per backup avanzato',
      };

  IconData _iconFor(ExportFormat f) => switch (f) {
        ExportFormat.csv => Icons.table_chart_outlined,
        ExportFormat.json => Icons.data_object,
        ExportFormat.markdown => Icons.description_outlined,
        ExportFormat.zip => Icons.folder_zip_outlined,
      };

  String _descFor(ExportFormat f) => switch (f) {
        ExportFormat.csv => 'Riepiloghi giornalieri in tabella',
        ExportFormat.json => 'Dati completi strutturati',
        ExportFormat.markdown => 'Report leggibile',
        ExportFormat.zip => 'CSV + JSON + Markdown insieme',
      };
}


class _ExportPreviewCard extends ConsumerWidget {
  const _ExportPreviewCard({required this.period, required this.categories});

  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  final Period period;
  final Set<ExportCategory> categories;

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
              'Condividi export ${format.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Periodo: ${_period.label} · Categorie: '
              '${_categories.map((c) => c.label).join(', ')}',
            ),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return FutureBuilder<ExportPreview>(
      future: _loadPreview(ref),
      builder: (context, snapshot) {
        final preview = snapshot.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.preview, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Anteprima export',
                        style: theme.textTheme.titleSmall),
                  ],
                ),
                const SizedBox(height: 8),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator()
                else if (snapshot.hasError)
                  Text('Anteprima non disponibile: ${snapshot.error}')
                else ...[
                  Text('${preview?.rows ?? 0} righe stimate · '
                      '${_formatBytes(preview?.estimatedBytes ?? 0)}'),
                  const SizedBox(height: 4),
                  Text(
                    '${preview?.fileStem ?? 'open_fit_data'}.<formato>',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<ExportPreview> _loadPreview(WidgetRef ref) async {
    final repo = ref.read(archiveRepositoryProvider);
    final now = DateTime.now();
    final from = period.days == null
        ? DateTime(2000)
        : now.subtract(Duration(days: period.days! - 1));
    final summaries = period.days == null
        ? await repo.allSummaries()
        : await repo.summariesInRange(_fmt.format(from), _fmt.format(now));
    final workouts = await repo.workoutsInRange(from, now);
    final rawRecords = await repo.rawInRange(from, now);
    return ref.read(exportServiceProvider).preview(
          format: ExportFormat.zip,
          summaries: summaries,
          workouts: workouts,
          rawRecords: rawRecords,
          categories: categories,
          periodLabel: period.label,
        );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
