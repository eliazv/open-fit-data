import '../data/models/canonical_record.dart';
import '../data/models/workout_record.dart';

/// Genera un hash deterministico per ogni record, usato come chiave di
/// deduplica (colonna unique in `health_raw_records`).
///
/// Milestone 0: cattura i duplicati *identici*. La deduplica delle
/// sovrapposizioni multi-sorgente (telefono vs smartwatch sullo stesso
/// intervallo) è un lavoro a sé previsto in Fase 5 (vedi ANALISI_ROADMAP §3.4).
class DeduplicationService {
  const DeduplicationService();

  String hashFor(CanonicalRecord r) {
    final canonical = [
      r.type.id,
      r.start.toUtc().toIso8601String(),
      r.end.toUtc().toIso8601String(),
      r.sourceApp ?? '',
      r.value.toStringAsFixed(4),
    ].join('|');
    return _fnv1a(canonical);
  }

  String hashForWorkout(WorkoutRecord w) {
    final canonical = [
      w.workoutType,
      w.start.toUtc().toIso8601String(),
      w.end.toUtc().toIso8601String(),
      w.sourceApp ?? '',
      (w.distanceM ?? 0).toStringAsFixed(2),
    ].join('|');
    return _fnv1a(canonical);
  }

  /// FNV-1a 64-bit in esadecimale: deterministico tra esecuzioni, compatto,
  /// senza dipendenze esterne.
  String _fnv1a(String input) {
    const int offset = 0xcbf29ce484222325;
    const int prime = 0x100000001b3;
    int hash = offset;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
