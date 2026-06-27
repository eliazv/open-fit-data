import 'package:intl/intl.dart';

import '../data/models/canonical_record.dart';
import '../data/models/metric_type.dart';
import 'source_priority_service.dart';

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

  double _hrWeightedSum = 0;
  double _hrWeight = 0;
  double _restingHrWeightedSum = 0;
  double _restingHrWeight = 0;
  double? lastWeight;
  double? lastVo2max;
  double? lastHrvMs;

  void addHr(double v, Duration duration) {
    final weight = _weight(duration);
    _hrWeightedSum += v * weight;
    _hrWeight += weight;
  }

  void addRestingHr(double v, Duration duration) {
    final weight = _weight(duration);
    _restingHrWeightedSum += v * weight;
    _restingHrWeight += weight;
  }

  double _weight(Duration duration) =>
      duration.inSeconds <= 0 ? 1 : duration.inSeconds.toDouble();

  int? get avgHr =>
      _hrWeight == 0 ? null : (_hrWeightedSum / _hrWeight).round();
  int? get restingHr => _restingHrWeight == 0
      ? null
      : (_restingHrWeightedSum / _restingHrWeight).round();
}

/// Trasforma i record grezzi in aggregati giornalieri.
class SummaryService {
  const SummaryService({
    SourcePriorityService sourcePriority = const SourcePriorityService(),
  }) : _sourcePriority = sourcePriority;

  final SourcePriorityService _sourcePriority;

  static final DateFormat _dayFmt = DateFormat('yyyy-MM-dd');

  String dayKey(DateTime t) => _dayFmt.format(t.toLocal());

  /// Aggrega tutti i record per giorno locale.
  Map<String, DailyAggregate> aggregate(Iterable<CanonicalRecord> records) {
    final out = <String, DailyAggregate>{};

    DailyAggregate forDay(DateTime t) =>
        out.putIfAbsent(dayKey(t), () => DailyAggregate(dayKey(t)));

    // Per "ultimo valore del giorno" (peso/vo2max/hrv) ordiniamo per tempo.
    final sorted = _deduplicateOverlapping(records.toList())
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
          agg.addHr(r.value, r.end.difference(r.start));
        case MetricType.restingHeartRate:
          agg.addRestingHr(r.value, r.end.difference(r.start));
        case MetricType.weight:
          agg.lastWeight = r.value;
        case MetricType.vo2max:
          agg.lastVo2max = r.value;
        case MetricType.hrv:
          agg.lastHrvMs = r.value;
        case MetricType.speed:
          break;
      }
    }
    return out;
  }

  List<CanonicalRecord> _deduplicateOverlapping(List<CanonicalRecord> records) {
    final additive = <CanonicalRecord>[];
    final passthrough = <CanonicalRecord>[];
    for (final r in records) {
      if (_needsOverlapDedup(r.type)) {
        additive.add(r);
      } else {
        passthrough.add(r);
      }
    }
    return [
      ...passthrough,
      ..._sourcePriority.withoutOverlaps(additive),
    ];
  }

  bool _needsOverlapDedup(MetricType type) => switch (type) {
        MetricType.steps ||
        MetricType.distance ||
        MetricType.activeCalories ||
        MetricType.sleep =>
          true,
        _ => false,
      };
}
