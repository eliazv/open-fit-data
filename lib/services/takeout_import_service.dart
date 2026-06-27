import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../data/models/canonical_record.dart';
import '../data/models/metric_type.dart';
import '../data/models/workout_record.dart';
import '../data/repositories/archive_repository.dart';

class TakeoutImportResult {
  const TakeoutImportResult({
    required this.filesSeen,
    required this.recordsParsed,
    required this.workoutsParsed,
    required this.recordsInserted,
    required this.workoutsInserted,
    required this.warnings,
  });

  final int filesSeen;
  final int recordsParsed;
  final int workoutsParsed;
  final int recordsInserted;
  final int workoutsInserted;
  final List<String> warnings;

  int get insertedTotal => recordsInserted + workoutsInserted;
}

/// Import best-effort per Google Takeout/Google Fit: ZIP, cartelle, JSON, CSV e
/// TCX. Tutto viene normalizzato negli stessi modelli usati da Health Connect.
class TakeoutImportService {
  TakeoutImportService(this._repo);

  final ArchiveRepository _repo;
  static final _dayFmt = DateFormat('yyyy-MM-dd');

  Future<TakeoutImportResult> importPath(String path) async {
    final startedAt = DateTime.now();
    final warnings = <String>[];
    final records = <CanonicalRecord>[];
    final workouts = <WorkoutRecord>[];
    var filesSeen = 0;

    try {
      final entity = FileSystemEntity.typeSync(path);
      if (entity == FileSystemEntityType.directory) {
        final dir = Directory(path);
        await for (final file in dir.list(recursive: true)) {
          if (file is! File) continue;
          filesSeen++;
          await _parseFile(file.path, await file.readAsBytes(), records,
              workouts, warnings);
        }
      } else {
        final file = File(path);
        filesSeen++;
        final bytes = await file.readAsBytes();
        if (path.toLowerCase().endsWith('.zip')) {
          final archive = ZipDecoder().decodeBytes(bytes);
          for (final entry in archive.files.where((f) => f.isFile)) {
            filesSeen++;
            await _parseFile(entry.name, List<int>.from(entry.content as List), records,
                workouts, warnings);
          }
        } else {
          await _parseFile(path, bytes, records, workouts, warnings);
        }
      }

      final insertedRaw = await _repo.insertRaw(records);
      final insertedWorkouts = await _repo.insertWorkouts(workouts);
      await _repo.recomputeDailySummaries();
      await _repo.addSyncLog(
        startedAt: startedAt,
        endedAt: DateTime.now(),
        trigger: 'google_takeout',
        status: 'success',
        rawRecords: records.length,
        workouts: workouts.length,
        insertedRaw: insertedRaw,
        insertedWorkouts: insertedWorkouts,
        message: 'files=$filesSeen warnings=${warnings.length}',
      );

      return TakeoutImportResult(
        filesSeen: filesSeen,
        recordsParsed: records.length,
        workoutsParsed: workouts.length,
        recordsInserted: insertedRaw,
        workoutsInserted: insertedWorkouts,
        warnings: warnings,
      );
    } catch (e) {
      await _repo.addSyncLog(
        startedAt: startedAt,
        endedAt: DateTime.now(),
        trigger: 'google_takeout',
        status: 'error',
        rawRecords: records.length,
        workouts: workouts.length,
        insertedRaw: 0,
        insertedWorkouts: 0,
        message: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> _parseFile(
    String name,
    List<int> bytes,
    List<CanonicalRecord> records,
    List<WorkoutRecord> workouts,
    List<String> warnings,
  ) async {
    final lower = name.toLowerCase();
    try {
      if (lower.endsWith('.csv')) {
        _parseCsv(name, utf8.decode(bytes, allowMalformed: true), records,
            workouts, warnings);
      } else if (lower.endsWith('.json')) {
        _parseJson(name, utf8.decode(bytes, allowMalformed: true), records,
            workouts, warnings);
      } else if (lower.endsWith('.tcx')) {
        _parseTcx(name, utf8.decode(bytes, allowMalformed: true), workouts,
            warnings);
      } else if (lower.endsWith('.fit')) {
        warnings.add('$name: file FIT riconosciuto ma non ancora parsato');
      }
    } catch (e) {
      warnings.add('$name: $e');
    }
  }

  void _parseCsv(
    String name,
    String content,
    List<CanonicalRecord> records,
    List<WorkoutRecord> workouts,
    List<String> warnings,
  ) {
    final rows = const CsvToListConverter(shouldParseNumbers: false)
        .convert(content, eol: '\n');
    if (rows.length < 2) return;
    final headers = rows.first.map((e) => e.toString().toLowerCase()).toList();
    for (final row in rows.skip(1)) {
      final values = <String, String>{};
      for (var i = 0; i < headers.length && i < row.length; i++) {
        values[headers[i]] = row[i].toString();
      }
      final start = _dateFrom(values) ?? _dateFromFileName(name);
      if (start == null) continue;
      _addIfPresent(records, values, start, MetricType.steps,
          const ['steps', 'step count', 'passi'], 'COUNT');
      _addIfPresent(records, values, start, MetricType.distance,
          const ['distance', 'distance_m', 'distanza'], 'METER');
      _addIfPresent(records, values, start, MetricType.weight,
          const ['weight', 'weight_kg', 'peso'], 'KILOGRAM');
      _addIfPresent(records, values, start, MetricType.heartRate,
          const ['heart rate', 'heart_rate', 'bpm'], 'BEATS_PER_MINUTE');
      _addIfPresent(records, values, start, MetricType.hrv,
          const ['hrv', 'rmssd', 'heart rate variability'], 'MILLISECOND');
      _addIfPresent(records, values, start, MetricType.vo2max,
          const ['vo2max', 'vo2 max', 'vo2_max'], 'VO2MAX');
    }
  }

  void _parseJson(
    String name,
    String content,
    List<CanonicalRecord> records,
    List<WorkoutRecord> workouts,
    List<String> warnings,
  ) {
    final decoded = jsonDecode(content);
    final items = decoded is List ? decoded : [decoded];
    for (final item in items.whereType<Map>()) {
      final flat = item.map((k, v) => MapEntry(k.toString().toLowerCase(), v));
      final start = _dateFromDynamic(flat) ?? _dateFromFileName(name);
      if (start == null) continue;
      for (final entry in flat.entries) {
        final metric = _metricFromKey(entry.key);
        final value = _num(entry.value);
        if (metric == null || value == null) continue;
        records.add(CanonicalRecord(
          type: metric,
          start: start,
          end: start.add(const Duration(minutes: 1)),
          value: value,
          unit: metric.styleUnitFallback,
          sourcePlatform: 'google_takeout',
          sourceApp: 'Google Takeout',
          metadata: {'file': name},
        ));
      }
    }
  }

  void _parseTcx(
    String name,
    String content,
    List<WorkoutRecord> workouts,
    List<String> warnings,
  ) {
    final timeMatches = RegExp(r'<Time>([^<]+)</Time>').allMatches(content);
    final times = timeMatches
        .map((m) => DateTime.tryParse(m.group(1) ?? ''))
        .whereType<DateTime>()
        .toList();
    if (times.isEmpty) return;
    final distanceMatches = RegExp(r'<DistanceMeters>([^<]+)</DistanceMeters>')
        .allMatches(content)
        .map((m) => double.tryParse(m.group(1) ?? ''))
        .whereType<double>()
        .toList();
    final hrMatches = RegExp(r'<HeartRateBpm>\s*<Value>([^<]+)</Value>')
        .allMatches(content)
        .map((m) => double.tryParse(m.group(1) ?? ''))
        .whereType<double>()
        .toList();
    final start = times.reduce((a, b) => a.isBefore(b) ? a : b);
    final end = times.reduce((a, b) => a.isAfter(b) ? a : b);
    final distance = distanceMatches.isEmpty
        ? null
        : distanceMatches.reduce((a, b) => a > b ? a : b);
    final avgHr = hrMatches.isEmpty
        ? null
        : hrMatches.reduce((a, b) => a + b) / hrMatches.length;
    final maxHr = hrMatches.isEmpty
        ? null
        : hrMatches.reduce((a, b) => a > b ? a : b);
    workouts.add(WorkoutRecord(
      workoutType: _activityType(content) ?? 'UNKNOWN',
      start: start,
      end: end,
      durationSec: end.difference(start).inSeconds,
      distanceM: distance,
      avgHr: avgHr,
      maxHr: maxHr,
      sourcePlatform: 'google_takeout',
      sourceApp: 'Google Takeout',
    ));
  }

  void _addIfPresent(
    List<CanonicalRecord> records,
    Map<String, String> values,
    DateTime start,
    MetricType type,
    List<String> keys,
    String unit,
  ) {
    for (final key in keys) {
      final raw = values[key];
      final value = _num(raw);
      if (value == null) continue;
      records.add(CanonicalRecord(
        type: type,
        start: start,
        end: start.add(const Duration(days: 1)),
        value: value,
        unit: unit,
        sourcePlatform: 'google_takeout',
        sourceApp: 'Google Takeout',
      ));
      return;
    }
  }

  DateTime? _dateFrom(Map<String, String> values) {
    for (final key in const ['date', 'start time', 'start_time', 'time']) {
      final parsed = DateTime.tryParse(values[key] ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  DateTime? _dateFromDynamic(Map<String, dynamic> values) {
    for (final key in const ['date', 'starttime', 'start_time', 'time']) {
      final parsed = DateTime.tryParse(values[key]?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  DateTime? _dateFromFileName(String name) {
    final match = RegExp(r'(20\d{2}-\d{2}-\d{2})').firstMatch(name);
    if (match == null) return null;
    return _dayFmt.parse(match.group(1)!);
  }

  MetricType? _metricFromKey(String key) {
    if (key.contains('step')) return MetricType.steps;
    if (key.contains('distance')) return MetricType.distance;
    if (key.contains('weight')) return MetricType.weight;
    if (key.contains('heart') && key.contains('variability')) return MetricType.hrv;
    if (key.contains('hrv') || key.contains('rmssd')) return MetricType.hrv;
    if (key.contains('heart') || key.contains('bpm')) return MetricType.heartRate;
    if (key.contains('vo2')) return MetricType.vo2max;
    if (key.contains('calorie')) return MetricType.activeCalories;
    return null;
  }

  double? _num(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().replaceAll(',', '.'));
  }

  String? _activityType(String content) {
    return RegExp(r'<Activity Sport="([^"]+)"')
        .firstMatch(content)
        ?.group(1)
        ?.toUpperCase();
  }
}

extension on MetricType {
  String get styleUnitFallback => switch (this) {
        MetricType.steps => 'COUNT',
        MetricType.distance => 'METER',
        MetricType.activeCalories => 'KILOCALORIE',
        MetricType.heartRate || MetricType.restingHeartRate =>
          'BEATS_PER_MINUTE',
        MetricType.sleep => 'MINUTE',
        MetricType.weight => 'KILOGRAM',
        MetricType.speed => 'KILOMETER_PER_HOUR',
        MetricType.vo2max => 'VO2MAX',
        MetricType.hrv => 'MILLISECOND',
      };
}
