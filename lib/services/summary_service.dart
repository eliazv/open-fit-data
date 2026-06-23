import 'package:intl/intl.dart';

import '../data/models/canonical_record.dart';
import '../data/models/metric_type.dart';

/// Aggregato giornaliero calcolato dai record grezzi (tutti i campi nullable).
class DailyAggregate {
  DailyAggregate(this.date);

  final String date;
  double steps = 0;
  bool hasSteps = false;
  double distanceM = 0;
  bool hasDistance = false;
  double activeCalories = 0;
  bool hasCalories = false;
  double sleepMinutes = 0;
  bool hasSleep = false;

  final List<double> _hr = [];
  final List<double> _restingHr = [];
  double? lastWeight;
  double? lastVo2max;

  void addHr(double v) => _hr.add(v);
  void addRestingHr(double v) => _restingHr.add(v);

  int? get avgHr =>
      _hr.isEmpty ? null : (_hr.reduce((a, b) => a + b) / _hr.length).round();
  int? get restingHr => _restingHr.isEmpty
      ? null
      : (_restingHr.reduce((a, b) => a + b) / _restingHr.length).round();
}

/// Trasforma i record grezzi in aggregati giornalieri.
class SummaryService {
  const SummaryService();

  static final DateFormat _dayFmt = DateFormat('yyyy-MM-dd');

  String dayKey(DateTime t) => _dayFmt.format(t.toLocal());

  /// Aggrega tutti i record per giorno locale.
  Map<String, DailyAggregate> aggregate(Iterable<CanonicalRecord> records) {
    final out = <String, DailyAggregate>{};

    DailyAggregate forDay(DateTime t) =>
        out.putIfAbsent(dayKey(t), () => DailyAggregate(dayKey(t)));

    // Per "ultimo valore del giorno" (peso/vo2max) ordiniamo per tempo.
    final sorted = records.toList()
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final r in sorted) {
      final agg = forDay(r.start);
      switch (r.type) {
        case MetricType.steps:
          agg.steps += r.value;
          agg.hasSteps = true;
        case MetricType.distance:
          agg.distanceM += r.value;
          agg.hasDistance = true;
        case MetricType.activeCalories:
          agg.activeCalories += r.value;
          agg.hasCalories = true;
        case MetricType.sleep:
          agg.sleepMinutes += r.value;
          agg.hasSleep = true;
        case MetricType.heartRate:
          agg.addHr(r.value);
        case MetricType.restingHeartRate:
          agg.addRestingHr(r.value);
        case MetricType.weight:
          agg.lastWeight = r.value;
        case MetricType.vo2max:
          agg.lastVo2max = r.value;
        case MetricType.speed:
          break;
      }
    }
    return out;
  }
}
