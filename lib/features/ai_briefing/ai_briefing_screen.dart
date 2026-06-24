import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../services/ai_briefing_service.dart';

class AiBriefingScreen extends ConsumerStatefulWidget {
  const AiBriefingScreen({super.key});

  @override
  ConsumerState<AiBriefingScreen> createState() => _AiBriefingScreenState();
}

class _AiBriefingScreenState extends ConsumerState<AiBriefingScreen> {
  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');
  String? _text;
  bool _busy = false;

  Future<void> _generate(BriefingKind kind) async {
    setState(() => _busy = true);
    final repo = ref.read(archiveRepositoryProvider);
    final service = ref.read(aiBriefingServiceProvider);
    final now = DateTime.now();

    final note = await repo.latestNote();
    final noteText = note == null ? null : _formatNote(note);

    Future<List> range(int days) {
      final from = _fmt.format(now.subtract(Duration(days: days - 1)));
      return repo.summariesInRange(from, _fmt.format(now));
    }

    String text;
    switch (kind) {
      case BriefingKind.last7:
        text = service.build(
            kind: kind, primary: await _cast(range(7)), userNote: noteText);
      case BriefingKind.last30:
      case BriefingKind.runningPlan:
        text = service.build(
            kind: kind, primary: await _cast(range(30)), userNote: noteText);
      case BriefingKind.compareMonths:
        final startCurrent = DateTime(now.year, now.month, 1);
        final startPrev = DateTime(now.year, now.month - 1, 1);
        final current = await repo.summariesInRange(
            _fmt.format(startCurrent), _fmt.format(now));
        final previous = await repo.summariesInRange(
            _fmt.format(startPrev),
            _fmt.format(startCurrent.subtract(const Duration(days: 1))));
        text = service.build(
            kind: kind,
            primary: current,
            previous: previous,
            userNote: noteText);
    }

    setState(() {
      _text = text;
      _busy = false;
    });
  }

  Future<List<T>> _cast<T>(Future<List> f) async => (await f).cast<T>();

  String _formatNote(UserNote n) {
    final parts = <String>[
      if (n.energyLevel != null) 'energia ${n.energyLevel}/5',
      if (n.fatigueLevel != null) 'fatica ${n.fatigueLevel}/5',
      if (n.painNotes != null) 'dolori: ${n.painNotes}',
      if (n.freeNote != null) n.freeNote!,
    ];
    return parts.isEmpty ? '' : '(${n.date}) ${parts.join('; ')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Genera un briefing pronto da incollare nella tua AI.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in BriefingKind.values)
              ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 18),
                label: Text(kind.label),
                onPressed: _busy ? null : () => _generate(kind),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (_busy)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_text != null)
          _Preview(text: _text!),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copia'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Briefing copiato')),
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
                    onPressed: () => Share.share(text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
