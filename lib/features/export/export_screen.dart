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

      await ref.read(exportServiceProvider).exportAndShare(
            format: format,
            summaries: summaries,
            workouts: workouts,
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
                onTap: () => _export(f),
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
