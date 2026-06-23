import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../data/db/database.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format.dart';

final recentWorkoutsProvider = FutureProvider<List<Workout>>((ref) {
  return ref.watch(archiveRepositoryProvider).recentWorkouts();
});

class WorkoutsScreen extends ConsumerWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentWorkoutsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Allenamenti')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Errore: $e')),
        data: (workouts) {
          if (workouts.isEmpty) {
            return const EmptyState(
              title: 'Nessun allenamento',
              message: 'Gli allenamenti importati da Health Connect '
                  'appariranno qui.',
              icon: Icons.fitness_center,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: workouts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _WorkoutTile(workout: workouts[i]),
          );
        },
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy HH:mm').format(workout.startTime);
    final km = workout.distanceM == null
        ? null
        : (workout.distanceM! / 1000).toStringAsFixed(2);
    final min = workout.durationSec == null
        ? null
        : (workout.durationSec! / 60).round();

    final parts = <String>[
      if (km != null) '$km km',
      if (min != null) '$min min',
      Format.pace(workout.avgPaceSecKm),
    ];

    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.directions_run)),
        title: Text(workout.workoutType),
        subtitle: Text('$date\n${parts.join(' · ')}'),
        isThreeLine: true,
        trailing: workout.sourceApp == null
            ? null
            : Chip(label: Text(workout.sourceApp!)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => _WorkoutDetail(workout: workout)),
        ),
      ),
    );
  }
}

class _WorkoutDetail extends StatelessWidget {
  const _WorkoutDetail({required this.workout});
  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Tipo', workout.workoutType),
      (
        'Inizio',
        DateFormat('dd/MM/yyyy HH:mm').format(workout.startTime),
      ),
      (
        'Durata',
        workout.durationSec == null
            ? '—'
            : '${(workout.durationSec! / 60).round()} min',
      ),
      (
        'Distanza',
        workout.distanceM == null
            ? '—'
            : '${(workout.distanceM! / 1000).toStringAsFixed(2)} km',
      ),
      ('Passo medio', Format.pace(workout.avgPaceSecKm)),
      (
        'Velocità media',
        workout.avgSpeed == null
            ? '—'
            : '${workout.avgSpeed!.toStringAsFixed(1)} km/h',
      ),
      ('FC media', workout.avgHr?.round().toString() ?? '—'),
      ('FC massima', workout.maxHr?.round().toString() ?? '—'),
      ('Sorgente', workout.sourceApp ?? '—'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(workout.workoutType)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final r in rows)
            ListTile(
              dense: true,
              title: Text(r.$1),
              trailing: Text(r.$2,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
