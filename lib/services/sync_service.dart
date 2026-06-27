import '../core/constants.dart';
import '../data/repositories/archive_repository.dart';
import 'health_sync_service.dart';

class HealthPermissionDenied implements Exception {
  const HealthPermissionDenied();
  @override
  String toString() => 'Permessi Health Connect non concessi.';
}

class SyncOutcome {
  const SyncOutcome({required this.imported, required this.at});
  final int imported;
  final DateTime at;
}

/// Orchestratore della sincronizzazione, condiviso tra UI e background.
/// Flusso: permessi → lettura multi-metrica → archivio → ricalcolo aggregati.
class SyncService {
  SyncService(this._health, this._repo);

  final HealthSyncService _health;
  final ArchiveRepository _repo;

  /// [interactive] = true mostra il prompt permessi (solo da UI in foreground).
  /// In background usiamo i permessi già concessi senza chiedere.
  Future<SyncOutcome> sync({
    int windowDays = AppConstants.defaultSyncWindowDays,
    bool interactive = true,
    bool includeHistory = false,
    String trigger = 'manual',
  }) async {
    final startedAt = DateTime.now();
    var rawRecords = 0;
    var workouts = 0;
    var insertedRaw = 0;
    var insertedWorkouts = 0;

    try {
      await _health.configure();

      final granted = interactive
          ? await _health.requestPermissions()
          : await _health.hasPermissions();
      if (!granted) throw const HealthPermissionDenied();

      final historyGranted = includeHistory && interactive
          ? await _health.requestHistoryAuthorization()
          : await _health.hasHistoryAuthorization();

      final now = DateTime.now();
      final start = historyGranted
          ? DateTime(2000)
          : now.subtract(Duration(days: windowDays));
      final result = await _health.read(start: start, end: now);
      rawRecords = result.records.length;
      workouts = result.workouts.length;

      insertedRaw = await _repo.insertRaw(result.records);
      insertedWorkouts = await _repo.insertWorkouts(result.workouts);
      await _repo.recomputeDailySummaries();
      await _repo.setMeta(MetaKeys.lastSyncAt, now.toIso8601String());

      await _repo.addSyncLog(
        startedAt: startedAt,
        endedAt: DateTime.now(),
        trigger: trigger,
        status: 'success',
        rawRecords: rawRecords,
        workouts: workouts,
        insertedRaw: insertedRaw,
        insertedWorkouts: insertedWorkouts,
        message: historyGranted ? 'history' : 'rolling_$windowDays',
      );

      return SyncOutcome(imported: insertedRaw + insertedWorkouts, at: now);
    } catch (e) {
      await _repo.addSyncLog(
        startedAt: startedAt,
        endedAt: DateTime.now(),
        trigger: trigger,
        status: 'error',
        rawRecords: rawRecords,
        workouts: workouts,
        insertedRaw: insertedRaw,
        insertedWorkouts: insertedWorkouts,
        message: e.toString(),
      );
      rethrow;
    }
  }
}
