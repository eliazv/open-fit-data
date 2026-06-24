import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';

final recentNotesProvider = FutureProvider<List<UserNote>>((ref) {
  return ref.watch(archiveRepositoryProvider).recentNotes();
});

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  static final DateFormat _fmt = DateFormat('yyyy-MM-dd');

  int? _energy;
  int? _fatigue;
  final _painCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _loading = true;

  String get _today => _fmt.format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final note = await ref.read(archiveRepositoryProvider).noteForDate(_today);
    if (note != null) {
      _energy = note.energyLevel;
      _fatigue = note.fatigueLevel;
      _painCtrl.text = note.painNotes ?? '';
      _noteCtrl.text = note.freeNote ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await ref.read(archiveRepositoryProvider).upsertNote(
          date: _today,
          energyLevel: _energy,
          fatigueLevel: _fatigue,
          painNotes: _painCtrl.text.trim().isEmpty ? null : _painCtrl.text.trim(),
          freeNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
    ref.invalidate(recentNotesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota salvata')),
      );
    }
  }

  @override
  void dispose() {
    _painCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = ref.watch(recentNotesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Note del giorno')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Come ti senti oggi?',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 16),
                _ScaleRow(
                  label: 'Energia',
                  value: _energy,
                  onChanged: (v) => setState(() => _energy = v),
                ),
                const SizedBox(height: 12),
                _ScaleRow(
                  label: 'Fatica',
                  value: _fatigue,
                  onChanged: (v) => setState(() => _fatigue = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _painCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dolori / fastidi',
                    hintText: 'es. fastidio al tallone dopo la corsa',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nota libera',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Salva nota'),
                  onPressed: _save,
                ),
                const SizedBox(height: 24),
                Text('Note recenti', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                recent.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (notes) => Column(
                    children: [
                      for (final n in notes.where((x) => x.date != _today))
                        Card(
                          child: ListTile(
                            title: Text(n.date),
                            subtitle: Text(_summary(n)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _summary(UserNote n) {
    final parts = <String>[
      if (n.energyLevel != null) 'energia ${n.energyLevel}/5',
      if (n.fatigueLevel != null) 'fatica ${n.fatigueLevel}/5',
      if (n.painNotes != null) n.painNotes!,
      if (n.freeNote != null) n.freeNote!,
    ];
    return parts.isEmpty ? '—' : parts.join(' · ');
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Wrap(
          spacing: 6,
          children: [
            for (var i = 1; i <= 5; i++)
              ChoiceChip(
                label: Text('$i'),
                selected: value == i,
                onSelected: (sel) => onChanged(sel ? i : null),
              ),
          ],
        ),
      ],
    );
  }
}
