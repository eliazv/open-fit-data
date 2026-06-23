import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/constants.dart';
import '../../services/health_sync_service.dart';

/// Stato della Home: snapshot dell'archivio + metriche rapide.
class HomeData {
  const HomeData({
    required this.lastSync,
    required this.archivedDays,
    required this.recordCount,
    required this.avgSteps7,
    required this.avgSteps30,
    required this.avgDistanceKm7,
    required this.permissionGranted,
    required this.availability,
  });

  final DateTime? lastSync;
  final int archivedDays;
  final int recordCount;
  final int? avgSteps7;
  final int? avgSteps30;
  final double? avgDistanceKm7;
  final bool permissionGranted;
  final HealthAvailability availability;

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

    return HomeData(
      lastSync: lastSyncRaw == null ? null : DateTime.tryParse(lastSyncRaw),
      archivedDays: await repo.archivedDaysCount(),
      recordCount: await repo.totalRecordCount(),
      avgSteps7: avg(steps7),
      avgSteps30: avg(steps30),
      avgDistanceKm7: dist7.isEmpty
          ? null
          : dist7.reduce((a, b) => a + b) / dist7.length / 1000,
      permissionGranted: await health.hasPermissions(),
      availability: await health.availability(),
    );
  }

  Future<List> _range(int days) async {
    final repo = ref.read(archiveRepositoryProvider);
    final now = DateTime.now();
    final from = _dayFmt.format(now.subtract(Duration(days: days - 1)));
    final to = _dayFmt.format(now);
    return repo.summariesInRange(from, to);
  }

  /// Sincronizzazione manuale (interattiva).
  Future<void> sync() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(syncServiceProvider).sync();
      return _load();
    });
  }

  /// Refresh dopo un sync avvenuto altrove (es. all'avvio).
  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}
