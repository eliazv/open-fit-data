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

/// Genera file di export in formati aperti e li condivide via share sheet.
class ExportService {
  const ExportService();

  static final DateFormat _stamp = DateFormat('yyyyMMdd_HHmm');

  Future<void> exportAndShare({
    required ExportFormat format,
    required List<DailySummary> summaries,
    required List<Workout> workouts,
  }) async {
    final dir = await getTemporaryDirectory();
    final base = 'open_fit_data_${_stamp.format(DateTime.now())}';
    final files = <XFile>[];

    switch (format) {
      case ExportFormat.csv:
        final file = File(p.join(dir.path, '$base.csv'));
        await file.writeAsString(_summariesCsv(summaries));
        files.add(XFile(file.path));
      case ExportFormat.json:
        final file = File(p.join(dir.path, '$base.json'));
        await file.writeAsString(_json(summaries, workouts));
        files.add(XFile(file.path));
      case ExportFormat.markdown:
        final file = File(p.join(dir.path, '$base.md'));
        await file.writeAsString(_markdown(summaries, workouts));
        files.add(XFile(file.path));
      case ExportFormat.zip:
        final file = File(p.join(dir.path, '$base.zip'));
        await file.writeAsBytes(_zip(summaries, workouts));
        files.add(XFile(file.path));
    }

    await Share.shareXFiles(files, subject: 'Open Fit Data — export');
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

  String _json(List<DailySummary> s, List<Workout> w) {
    final data = {
      'app': 'Open Fit Data',
      'exported_at': DateTime.now().toIso8601String(),
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
              })
          .toList(),
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
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  String _markdown(List<DailySummary> s, List<Workout> w) {
    final b = StringBuffer()
      ..writeln('# Open Fit Data — export')
      ..writeln()
      ..writeln('Generato: ${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('## Riepiloghi giornalieri (${s.length})')
      ..writeln()
      ..writeln('| Data | Passi | Distanza (m) | Sonno (min) | Peso (kg) |')
      ..writeln('|---|---|---|---|---|');
    for (final d in s) {
      b.writeln(
        '| ${d.date} | ${d.steps ?? '-'} | ${d.distanceM?.round() ?? '-'} '
        '| ${d.sleepMinutes ?? '-'} | ${d.weightKg ?? '-'} |',
      );
    }
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
    return b.toString();
  }

  List<int> _zip(List<DailySummary> s, List<Workout> w) {
    final archive = Archive()
      ..addFile(_entry('daily_summaries.csv', _summariesCsv(s)))
      ..addFile(_entry('workouts.csv', _workoutsCsv(w)))
      ..addFile(_entry('data.json', _json(s, w)))
      ..addFile(_entry('report.md', _markdown(s, w)));
    return ZipEncoder().encode(archive) ?? <int>[];
  }

  ArchiveFile _entry(String name, String content) {
    final bytes = utf8.encode(content);
    return ArchiveFile(name, bytes.length, bytes);
  }
}
