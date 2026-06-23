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
  }) async {
    await _health.configure();

    final granted = interactive
        ? await _health.requestPermissions()
        : await _health.hasPermissions();
    if (!granted) throw const HealthPermissionDenied();

    final now = DateTime.now();
    final start = now.subtract(Duration(days: windowDays));
    final result = await _health.read(start: start, end: now);

    await _repo.insertRaw(result.records);
    await _repo.insertWorkouts(result.workouts);
    await _repo.recomputeDailySummaries();
    await _repo.setMeta(MetaKeys.lastSyncAt, now.toIso8601String());

    return SyncOutcome(imported: result.total, at: now);
  }
}
