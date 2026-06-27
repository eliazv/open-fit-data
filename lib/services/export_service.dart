import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/db/database.dart';

enum ExportFormat { csv, json, markdown, zip }

extension ExportFormatX on ExportFormat {
  String get label => switch (this) {
        ExportFormat.csv => 'CSV',
        ExportFormat.json => 'JSON',
        ExportFormat.markdown => 'Markdown',
        ExportFormat.zip => 'ZIP completo',
      };
  String get ext => switch (this) {
        ExportFormat.csv => 'csv',
        ExportFormat.json => 'json',
        ExportFormat.markdown => 'md',
        ExportFormat.zip => 'zip',
      };
}

enum ExportCategory { dailyMetrics, workouts, rawRecords }

extension ExportCategoryX on ExportCategory {
  String get label => switch (this) {
        ExportCategory.dailyMetrics => 'Metriche giornaliere',
        ExportCategory.workouts => 'Allenamenti',
        ExportCategory.rawRecords => 'Dati grezzi',
      };

  String get slug => switch (this) {
        ExportCategory.dailyMetrics => 'daily',
        ExportCategory.workouts => 'workouts',
        ExportCategory.rawRecords => 'raw',
      };
}

class ExportPreview {
  const ExportPreview({
    required this.rows,
    required this.estimatedBytes,
    required this.fileStem,
  });

  final int rows;
  final int estimatedBytes;
  final String fileStem;
}

/// Genera file di export in formati aperti e li condivide via share sheet.
class ExportService {
  const ExportService();

  static final DateFormat _stamp = DateFormat('yyyyMMdd_HHmm');

  ExportPreview preview({
    required ExportFormat format,
    required List<DailySummary> summaries,
    required List<Workout> workouts,
    List<HealthRawRecord> rawRecords = const [],
    required Set<ExportCategory> categories,
    required String periodLabel,
  }) {
    final content = _contentFor(
      format,
      summaries,
      workouts,
      rawRecords,
      categories,
      const {},
    );
    final bytes = format == ExportFormat.zip
        ? _zip(summaries, workouts, rawRecords, categories, const {}).length
        : utf8.encode(content).length;
    return ExportPreview(
      rows: (categories.contains(ExportCategory.dailyMetrics)
              ? summaries.length
              : 0) +
          (categories.contains(ExportCategory.workouts) ? workouts.length : 0) +
          (categories.contains(ExportCategory.rawRecords)
              ? rawRecords.length
              : 0),
      estimatedBytes: bytes,
      fileStem: _fileStem(periodLabel, categories),
    );
  }

  Future<void> exportAndShare({
    required ExportFormat format,
    required List<DailySummary> summaries,
    required List<Workout> workouts,
    List<HealthRawRecord> rawRecords = const [],
    Map<String, String> profile = const {},
    Set<ExportCategory> categories = const {
      ExportCategory.dailyMetrics,
      ExportCategory.workouts,
    },
    String periodLabel = 'periodo',
  }) async {
    final dir = await getTemporaryDirectory();
    final base = _fileStem(periodLabel, categories);
    final files = <XFile>[];

    switch (format) {
      case ExportFormat.csv:
        final file = File(p.join(dir.path, '$base.csv'));
        await file.writeAsString(
          _contentFor(
            format,
            summaries,
            workouts,
            rawRecords,
            categories,
            profile,
          ),
        );
        files.add(XFile(file.path));
      case ExportFormat.json:
        final file = File(p.join(dir.path, '$base.json'));
        await file.writeAsString(
          _json(summaries, workouts, rawRecords, categories, profile),
        );
        files.add(XFile(file.path));
      case ExportFormat.markdown:
        final file = File(p.join(dir.path, '$base.md'));
        await file.writeAsString(
          _markdown(summaries, workouts, rawRecords, categories, profile),
        );
        files.add(XFile(file.path));
      case ExportFormat.zip:
        final file = File(p.join(dir.path, '$base.zip'));
        await file.writeAsBytes(
          _zip(summaries, workouts, rawRecords, categories, profile),
        );
        files.add(XFile(file.path));
    }

    await SharePlus.instance.share(
      ShareParams(
        files: files,
        subject: 'Open Fit Data — export',
      ),
    );
  }

  String _contentFor(
    ExportFormat format,
    List<DailySummary> s,
    List<Workout> w,
    List<HealthRawRecord> r,
    Set<ExportCategory> categories,
    Map<String, String> profile,
  ) =>
      switch (format) {
        ExportFormat.csv => categories.contains(ExportCategory.dailyMetrics)
            ? _summariesCsv(s)
            : categories.contains(ExportCategory.workouts)
                ? _workoutsCsv(w)
                : _rawCsv(r),
        ExportFormat.json => _json(s, w, r, categories, profile),
        ExportFormat.markdown => _markdown(s, w, r, categories, profile),
        ExportFormat.zip => '',
      };

  String _fileStem(String periodLabel, Set<ExportCategory> categories) {
    final cats = categories.map((c) => c.slug).join('_');
    final period =
        periodLabel.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'open_fit_data_${period}_${cats}_${_stamp.format(DateTime.now())}';
  }

  String _summariesCsv(List<DailySummary> s) {
    final rows = <List<dynamic>>[
      [
        'date',
        'steps',
        'distance_m',
        'active_calories',
        'sleep_minutes',
        'resting_hr',
        'avg_hr',
        'weight_kg',
        'vo2max',
        'hrv_ms',
      ],
      ...s.map((d) => [
            d.date,
            d.steps,
            d.distanceM,
            d.activeCalories,
            d.sleepMinutes,
            d.restingHr,
            d.avgHr,
            d.weightKg,
            d.vo2max,
            d.hrvMs,
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _workoutsCsv(List<Workout> w) {
    final rows = <List<dynamic>>[
      [
        'type',
        'start',
        'end',
        'duration_sec',
        'distance_m',
        'avg_pace_sec_km',
        'avg_speed',
        'avg_hr',
        'max_hr',
        'source',
      ],
      ...w.map((x) => [
            x.workoutType,
            x.startTime.toIso8601String(),
            x.endTime.toIso8601String(),
            x.durationSec,
            x.distanceM,
            x.avgPaceSecKm,
            x.avgSpeed,
            x.avgHr,
            x.maxHr,
            x.sourceApp,
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  String _json(
    List<DailySummary> s,
    List<Workout> w,
    List<HealthRawRecord> r,
    Set<ExportCategory> categories,
    Map<String, String> profile,
  ) {
    final data = {
      'app': 'Open Fit Data',
      'exported_at': DateTime.now().toIso8601String(),
      if (profile.isNotEmpty) 'profile': profile,
      if (categories.contains(ExportCategory.dailyMetrics))
        'daily_summaries': s
            .map((d) => {
                  'date': d.date,
                  'steps': d.steps,
                  'distance_m': d.distanceM,
                  'active_calories': d.activeCalories,
                  'sleep_minutes': d.sleepMinutes,
                  'resting_hr': d.restingHr,
                  'avg_hr': d.avgHr,
                  'weight_kg': d.weightKg,
                  'vo2max': d.vo2max,
                  'hrv_ms': d.hrvMs,
                })
            .toList(),
      if (categories.contains(ExportCategory.workouts))
        'workouts': w
            .map((x) => {
                  'type': x.workoutType,
                  'start': x.startTime.toIso8601String(),
                  'end': x.endTime.toIso8601String(),
                  'duration_sec': x.durationSec,
                  'distance_m': x.distanceM,
                  'avg_pace_sec_km': x.avgPaceSecKm,
                  'avg_speed': x.avgSpeed,
                  'avg_hr': x.avgHr,
                  'max_hr': x.maxHr,
                  'source': x.sourceApp,
                })
            .toList(),
      if (categories.contains(ExportCategory.rawRecords))
        'raw_records': r
            .map((x) => {
                  'type': x.type,
                  'start': x.startTime.toIso8601String(),
                  'end': x.endTime.toIso8601String(),
                  'value': x.value,
                  'unit': x.unit,
                  'source_platform': x.sourcePlatform,
                  'source_app': x.sourceApp,
                })
            .toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  String _markdown(
    List<DailySummary> s,
    List<Workout> w,
    List<HealthRawRecord> r,
    Set<ExportCategory> categories,
    Map<String, String> profile,
  ) {
    final b = StringBuffer()
      ..writeln('# Open Fit Data — export')
      ..writeln()
      ..writeln('Generato: ${DateTime.now().toIso8601String()}')
      ..writeln();
    if (profile.isNotEmpty) {
      b
        ..writeln('## Profilo')
        ..writeln()
        ..writeln('- Peso: ${profile['weight_kg'] ?? '-'} kg')
        ..writeln('- Altezza: ${profile['height_cm'] ?? '-'} cm')
        ..writeln('- Data di nascita: ${profile['birth_date'] ?? '-'}')
        ..writeln();
    }
    if (categories.contains(ExportCategory.dailyMetrics)) {
      b
        ..writeln('## Riepiloghi giornalieri (${s.length})')
        ..writeln()
        ..writeln(
            '| Data | Passi | Distanza (m) | Sonno (min) | Peso (kg) | HRV (ms) |')
        ..writeln('|---|---|---|---|---|---|');
      for (final d in s) {
        b.writeln(
          '| ${d.date} | ${d.steps ?? '-'} | ${d.distanceM?.round() ?? '-'} '
          '| ${d.sleepMinutes ?? '-'} | ${d.weightKg ?? '-'} | ${d.hrvMs ?? '-'} |',
        );
      }
    }
    if (categories.contains(ExportCategory.workouts)) {
      b
        ..writeln()
        ..writeln('## Allenamenti (${w.length})')
        ..writeln();
      for (final x in w) {
        b.writeln(
          '- ${x.workoutType} · ${x.distanceM?.round() ?? '-'} m · '
          '${x.durationSec ?? '-'} s',
        );
      }
    }
    if (categories.contains(ExportCategory.rawRecords)) {
      b
        ..writeln()
        ..writeln('## Dati grezzi (${r.length})')
        ..writeln()
        ..writeln('Record normalizzati importati da Health Connect/Takeout.');
    }
    return b.toString();
  }

  String _rawCsv(List<HealthRawRecord> r) {
    final rows = <List<dynamic>>[
      [
        'type',
        'start',
        'end',
        'value',
        'unit',
        'source_platform',
        'source_app',
      ],
      ...r.map((x) => [
            x.type,
            x.startTime.toIso8601String(),
            x.endTime.toIso8601String(),
            x.value,
            x.unit,
            x.sourcePlatform,
            x.sourceApp,
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  List<int> _zip(
    List<DailySummary> s,
    List<Workout> w,
    List<HealthRawRecord> r,
    Set<ExportCategory> categories,
    Map<String, String> profile,
  ) {
    final archive = Archive();
    if (categories.contains(ExportCategory.dailyMetrics)) {
      archive.addFile(_entry('daily_summaries.csv', _summariesCsv(s)));
    }
    if (categories.contains(ExportCategory.workouts)) {
      archive.addFile(_entry('workouts.csv', _workoutsCsv(w)));
    }
    if (categories.contains(ExportCategory.rawRecords)) {
      archive.addFile(_entry('raw_records.csv', _rawCsv(r)));
    }
    archive
      ..addFile(_entry('data.json', _json(s, w, r, categories, profile)))
      ..addFile(_entry('report.md', _markdown(s, w, r, categories, profile)));
    return ZipEncoder().encode(archive) ?? <int>[];
  }

  ArchiveFile _entry(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }
}
