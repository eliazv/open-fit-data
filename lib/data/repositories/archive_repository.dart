import 'dart:convert';

import 'package:drift/drift.dart';

import '../../services/deduplication_service.dart';
import '../../services/summary_service.dart';
import '../db/database.dart';
import '../models/canonical_record.dart';
import '../models/metric_type.dart';
import '../models/workout_record.dart';

/// Unico punto d'accesso all'archivio locale: scrive record grezzi e workout,
/// ricalcola gli aggregati giornalieri e legge i dati per dashboard/export.
class ArchiveRepository {
  ArchiveRepository(
    this._db, {
    DeduplicationService dedup = const DeduplicationService(),
    SummaryService summary = const SummaryService(),
  })  : _dedup = dedup,
        _summary = summary;

  final AppDatabase _db;
  final DeduplicationService _dedup;
  final SummaryService _summary;

  // --- scrittura ---

  /// Inserisce record grezzi scartando i duplicati identici (hash unique).
  Future<void> insertRaw(List<CanonicalRecord> records) async {
    if (records.isEmpty) return;
    final now = DateTime.now();
    await _db.batch((b) {
      for (final r in records) {
        b.insert(
          _db.healthRawRecords,
          HealthRawRecordsCompanion.insert(
            sourcePlatform: r.sourcePlatform,
            sourceApp: Value(r.sourceApp),
            type: r.type.id,
            startTime: r.start,
            endTime: r.end,
            value: r.value,
            unit: r.unit,
            metadataJson: Value(
              r.metadata.isEmpty ? null : jsonEncode(r.metadata),
            ),
            hashDedup: _dedup.hashFor(r),
            importedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  Future<void> insertWorkouts(List<WorkoutRecord> workouts) async {
    if (workouts.isEmpty) return;
    final now = DateTime.now();
    await _db.batch((b) {
      for (final w in workouts) {
        b.insert(
          _db.workouts,
          WorkoutsCompanion.insert(
            workoutType: w.workoutType,
            startTime: w.start,
            endTime: w.end,
            durationSec: Value(w.durationSec),
            distanceM: Value(w.distanceM),
            avgPaceSecKm: Value(w.avgPaceSecKm),
            avgHr: Value(w.avgHr),
            maxHr: Value(w.maxHr),
            avgSpeed: Value(w.avgSpeedKmh),
            sourceApp: Value(w.sourceApp),
            hashDedup: _dedup.hashForWorkout(w),
            importedAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
    });
  }

  /// Ricalcola gli aggregati giornalieri da tutti i record grezzi (upsert).
  Future<void> recomputeDailySummaries() async {
    final rows = await _db.select(_db.healthRawRecords).get();
    final canonical = rows.map(_rowToCanonical);
    final aggregates = _summary.aggregate(canonical);
    final now = DateTime.now();

    await _db.batch((b) {
      for (final agg in aggregates.values) {
        b.insert(
          _db.dailySummaries,
          DailySummariesCompanion.insert(
            date: agg.date,
            steps: Value(agg.hasSteps ? agg.steps.round() : null),
            distanceM: Value(agg.hasDistance ? agg.distanceM : null),
            activeCalories: Value(agg.hasCalories ? agg.activeCalories : null),
            sleepMinutes: Value(agg.hasSleep ? agg.sleepMinutes.round() : null),
            restingHr: Value(agg.restingHr?.toDouble()),
            avgHr: Value(agg.avgHr?.toDouble()),
            weightKg: Value(agg.lastWeight),
            vo2max: Value(agg.lastVo2max),
            updatedAt: now,
          ),
          onConflict: DoUpdate(
            (_) => DailySummariesCompanion(
              steps: Value(agg.hasSteps ? agg.steps.round() : null),
              distanceM: Value(agg.hasDistance ? agg.distanceM : null),
              activeCalories:
                  Value(agg.hasCalories ? agg.activeCalories : null),
              sleepMinutes:
                  Value(agg.hasSleep ? agg.sleepMinutes.round() : null),
              restingHr: Value(agg.restingHr?.toDouble()),
              avgHr: Value(agg.avgHr?.toDouble()),
              weightKg: Value(agg.lastWeight),
              vo2max: Value(agg.lastVo2max),
              updatedAt: Value(now),
            ),
            target: [_db.dailySummaries.date],
          ),
        );
      }
    });
  }

  // --- lettura ---

  Future<List<DailySummary>> summariesInRange(String fromDay, String toDay) {
    return (_db.select(_db.dailySummaries)
          ..where((t) => t.date.isBiggerOrEqualValue(fromDay))
          ..where((t) => t.date.isSmallerOrEqualValue(toDay))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<List<DailySummary>> allSummaries() {
    return (_db.select(_db.dailySummaries)
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
  }

  Future<List<Workout>> workoutsInRange(DateTime from, DateTime to) {
    return (_db.select(_db.workouts)
          ..where((t) => t.startTime.isBiggerOrEqualValue(from))
          ..where((t) => t.startTime.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)]))
        .get();
  }

  Future<List<Workout>> recentWorkouts({int limit = 50}) {
    return (_db.select(_db.workouts)
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
          ..limit(limit))
        .get();
  }

  Future<List<HealthRawRecord>> rawInRange(DateTime from, DateTime to) {
    return (_db.select(_db.healthRawRecords)
          ..where((t) => t.startTime.isBiggerOrEqualValue(from))
          ..where((t) => t.startTime.isSmallerOrEqualValue(to))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  Future<int> totalRecordCount() async {
    final count = _db.healthRawRecords.id.count();
    final row = await (_db.selectOnly(_db.healthRawRecords)..addColumns([count]))
        .getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> archivedDaysCount() async {
    final count = _db.dailySummaries.date.count();
    final row = await (_db.selectOnly(_db.dailySummaries)..addColumns([count]))
        .getSingle();
    return row.read(count) ?? 0;
  }

  // --- note manuali ---

  Future<UserNote?> noteForDate(String date) {
    return (_db.select(_db.userNotes)..where((t) => t.date.equals(date)))
        .getSingleOrNull();
  }

  Future<UserNote?> latestNote() {
    return (_db.select(_db.userNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<List<UserNote>> recentNotes({int limit = 30}) {
    return (_db.select(_db.userNotes)
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(limit))
        .get();
  }

  Future<void> upsertNote({
    required String date,
    int? energyLevel,
    int? fatigueLevel,
    String? painNotes,
    String? freeNote,
  }) {
    return _db.into(_db.userNotes).insertOnConflictUpdate(
          UserNotesCompanion.insert(
            date: date,
            energyLevel: Value(energyLevel),
            fatigueLevel: Value(fatigueLevel),
            painNotes: Value(painNotes),
            freeNote: Value(freeNote),
            createdAt: DateTime.now(),
          ),
        );
  }

  // --- meta key/value ---

  Future<String?> getMeta(String key) async {
    final row = await (_db.select(_db.appMeta)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) {
    return _db.into(_db.appMeta).insertOnConflictUpdate(
          AppMetaCompanion.insert(key: key, value: Value(value)),
        );
  }

  CanonicalRecord _rowToCanonical(HealthRawRecord row) {
    return CanonicalRecord(
      type: MetricTypeX.fromId(row.type),
      start: row.startTime,
      end: row.endTime,
      value: row.value,
      unit: row.unit,
      sourcePlatform: row.sourcePlatform,
      sourceApp: row.sourceApp,
    );
  }
}
