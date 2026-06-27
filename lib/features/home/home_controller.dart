import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../data/db/database.dart';
import '../../data/models/metric_type.dart';
import '../../services/health_sync_service.dart';

/// Stato della Home: snapshot dell'archivio + metriche rapide.
class MetricStatus {
  const MetricStatus({
    required this.label,
    required this.records,
    required this.sources,
    this.latest,
  });

  final String label;
  final int records;
  final int sources;
  final DateTime? latest;
}

class HomeData {
  const HomeData({
    required this.lastSync,
    required this.archivedDays,
    required this.recordCount,
    required this.avgSteps7,
    required this.avgSteps30,
    required this.avgDistanceKm7,
    required this.stepsTrend7,
    required this.distanceTrend7,
    required this.sleepTrend7,
    required this.heartRateTrend7,
    required this.stepsDeltaPercent,
    required this.distanceDeltaPercent,
    required this.sleepDeltaPercent,
    required this.heartRateDeltaPercent,
    required this.permissionGranted,
    required this.availability,
    required this.metricStatuses,
    required this.sourceDistribution,
  });

  final DateTime? lastSync;
  final int archivedDays;
  final int recordCount;
  final int? avgSteps7;
  final int? avgSteps30;
  final double? avgDistanceKm7;
  final List<double> stepsTrend7;
  final List<double> distanceTrend7;
  final List<double> sleepTrend7;
  final List<double> heartRateTrend7;
  final double? stepsDeltaPercent;
  final double? distanceDeltaPercent;
  final double? sleepDeltaPercent;
  final double? heartRateDeltaPercent;
  final bool permissionGranted;
  final HealthAvailability availability;
  final List<MetricStatus> metricStatuses;
  final Map<String, int> sourceDistribution;

  bool get isStale {
    if (lastSync == null) return false;
    return DateTime.now().difference(lastSync!).inDays >=
        AppConstants.staleSyncWarningDays;
  }

  bool get isEmpty => archivedDays == 0;
}

final homeControllerProvider =
    AsyncNotifierProvider<HomeController, HomeData>(HomeController.new);

class HomeController extends AsyncNotifier<HomeData> {
  static final DateFormat _dayFmt = DateFormat('yyyy-MM-dd');

  @override
  Future<HomeData> build() => _load();

  Future<HomeData> _load() async {
    final repo = ref.read(archiveRepositoryProvider);
    final health = ref.read(healthSyncServiceProvider);

    final lastSyncRaw = await repo.getMeta(MetaKeys.lastSyncAt);
    final last7 = await _range(7);
    final last30 = await _range(30);
    final previous7 = await _previousRange(days: 7);

    int? avg(List values) => values.isEmpty
        ? null
        : (values.cast<int>().reduce((a, b) => a + b) / values.length).round();

    final steps7 = last7
        .where((s) => s.steps != null)
        .map((s) => s.steps!)
        .toList();
    final steps30 = last30
        .where((s) => s.steps != null)
        .map((s) => s.steps!)
        .toList();
    final dist7 =
        last7.where((s) => s.distanceM != null).map((s) => s.distanceM!);
    final sleep7 = last7
        .where((s) => s.sleepMinutes != null)
        .map((s) => s.sleepMinutes!)
        .toList();
    final hr7 = last7
        .where((s) => s.avgHr != null)
        .map((s) => s.avgHr!.round())
        .toList();

    final counts = await repo.recordCountByMetric();
    final latest = await repo.latestRecordByMetric();
    final sources = await repo.sourcesByMetric();
    final sourceDistribution = await repo.sourceRecordCounts();

    return HomeData(
      lastSync: lastSyncRaw == null ? null : DateTime.tryParse(lastSyncRaw),
      archivedDays: await repo.archivedDaysCount(),
      recordCount: await repo.totalRecordCount(),
      avgSteps7: avg(steps7),
      avgSteps30: avg(steps30),
      avgDistanceKm7: dist7.isEmpty
          ? null
          : dist7.reduce((a, b) => a + b) / dist7.length / 1000,
      stepsTrend7: last7.map((s) => (s.steps ?? 0).toDouble()).toList(),
      distanceTrend7:
          last7.map((s) => (s.distanceM ?? 0) / 1000).toList(),
      sleepTrend7:
          last7.map((s) => (s.sleepMinutes ?? 0) / 60).toList(),
      heartRateTrend7:
          last7.map((s) => s.avgHr ?? s.restingHr ?? 0).toList(),
      stepsDeltaPercent: _delta(avg(steps7), _avgInt(previous7
          .where((s) => s.steps != null)
          .map((s) => s.steps!)
          .toList())),
      distanceDeltaPercent: _delta(
        dist7.isEmpty ? null : dist7.reduce((a, b) => a + b) / dist7.length,
        _avgDouble(previous7
            .where((s) => s.distanceM != null)
            .map((s) => s.distanceM!)
            .toList()),
      ),
      sleepDeltaPercent: _delta(avg(sleep7), _avgInt(previous7
          .where((s) => s.sleepMinutes != null)
          .map((s) => s.sleepMinutes!)
          .toList())),
      heartRateDeltaPercent: _delta(avg(hr7), _avgDouble(previous7
          .where((s) => s.avgHr != null)
          .map((s) => s.avgHr!)
          .toList())),
      permissionGranted: await health.hasPermissions(),
      availability: await health.availability(),
      sourceDistribution: sourceDistribution,
      metricStatuses: [
        for (final type in MetricType.values)
          if ((counts[type.id] ?? 0) > 0)
            MetricStatus(
              label: type.label,
              records: counts[type.id] ?? 0,
              sources: sources[type.id]?.length ?? 0,
              latest: latest[type.id],
            ),
      ],
    );
  }

  double? _delta(num? current, num? previous) {
    if (current == null || previous == null || previous == 0) return null;
    return ((current - previous) / previous) * 100;
  }

  int? _avgInt(List<int> values) => values.isEmpty
      ? null
      : (values.reduce((a, b) => a + b) / values.length).round();

  double? _avgDouble(List<double> values) => values.isEmpty
      ? null
      : values.reduce((a, b) => a + b) / values.length;

  Future<List<DailySummary>> _range(int days) async {
    final repo = ref.read(archiveRepositoryProvider);
    final now = DateTime.now();
    final from = _dayFmt.format(now.subtract(Duration(days: days - 1)));
    final to = _dayFmt.format(now);
    return repo.summariesInRange(from, to);
  }

  Future<List<DailySummary>> _previousRange({required int days}) async {
    final repo = ref.read(archiveRepositoryProvider);
    final now = DateTime.now();
    final to = now.subtract(Duration(days: days));
    final from = to.subtract(Duration(days: days - 1));
    return repo.summariesInRange(_dayFmt.format(from), _dayFmt.format(to));
  }

  /// Sincronizzazione manuale (interattiva).
  Future<void> sync() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(syncServiceProvider).sync(
        includeHistory: true,
        trigger: 'manual',
      );
      return _load();
    });
  }

  /// Refresh dopo un sync avvenuto altrove (es. all'avvio).
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}
