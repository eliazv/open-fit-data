import 'package:health/health.dart';

import '../data/models/canonical_record.dart';
import '../data/models/metric_type.dart';
import '../data/models/workout_record.dart';

/// Esito della disponibilità di Health Connect.
enum HealthAvailability { available, notInstalled, needsUpdate, unsupported }

/// Risultato di una sincronizzazione.
class SyncResult {
  const SyncResult({required this.records, required this.workouts});
  final List<CanonicalRecord> records;
  final List<WorkoutRecord> workouts;

  int get total => records.length + workouts.length;
}

/// Ponte verso il package `health`. Tutta la conoscenza dei tipi/units della
/// piattaforma vive qui: il resto dell'app riceve solo modelli canonici
/// (vedi ANALISI_ROADMAP §3.3), così l'aggiunta di iOS sarà un secondo
/// "source" senza toccare archivio/UI.
class HealthSyncService {
  HealthSyncService({Health? health}) : _health = health ?? Health();

  final Health _health;

  /// Metriche numeriche lette in v1, con il tipo Health Connect corrispondente.
  static const Map<MetricType, HealthDataType> _numericTypes = {
    MetricType.steps: HealthDataType.STEPS,
    MetricType.distance: HealthDataType.DISTANCE_DELTA,
    MetricType.activeCalories: HealthDataType.ACTIVE_ENERGY_BURNED,
    MetricType.heartRate: HealthDataType.HEART_RATE,
    MetricType.restingHeartRate: HealthDataType.RESTING_HEART_RATE,
    MetricType.sleep: HealthDataType.SLEEP_ASLEEP,
    MetricType.weight: HealthDataType.WEIGHT,
  };

  List<HealthDataType> get _allTypes => [
        ..._numericTypes.values,
        HealthDataType.WORKOUT,
      ];

  List<HealthDataAccess> get _access =>
      List.filled(_allTypes.length, HealthDataAccess.READ);

  Future<void> configure() => _health.configure();

  Future<HealthAvailability> availability() async {
    try {
      final status = await _health.getHealthConnectSdkStatus();
      switch (status) {
        case HealthConnectSdkStatus.sdkAvailable:
          return HealthAvailability.available;
        case HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired:
          return HealthAvailability.needsUpdate;
        case HealthConnectSdkStatus.sdkUnavailable:
          return HealthAvailability.notInstalled;
        default:
          return HealthAvailability.unsupported;
      }
    } catch (_) {
      return HealthAvailability.unsupported;
    }
  }

  Future<bool> hasPermissions() async {
    final granted =
        await _health.hasPermissions(_allTypes, permissions: _access);
    return granted ?? false;
  }

  Future<bool> requestPermissions() async {
    if (await hasPermissions()) return true;
    return _health.requestAuthorization(_allTypes, permissions: _access);
  }

  /// Legge tutte le metriche supportate nell'intervallo. Ogni tipo è isolato
  /// in try/catch: un tipo non disponibile non blocca gli altri.
  Future<SyncResult> read({
    required DateTime start,
    required DateTime end,
  }) async {
    final records = <CanonicalRecord>[];
    final workouts = <WorkoutRecord>[];

    for (final entry in _numericTypes.entries) {
      try {
        final points = await _health.getHealthDataFromTypes(
          types: [entry.value],
          startTime: start,
          endTime: end,
        );
        for (final p in _health.removeDuplicates(points)) {
          final r = _toCanonical(p, entry.key);
          if (r != null) records.add(r);
        }
      } catch (_) {
        // tipo non disponibile su questo dispositivo: si ignora.
      }
    }

    try {
      final points = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: start,
        endTime: end,
      );
      for (final p in _health.removeDuplicates(points)) {
        final w = _toWorkout(p);
        if (w != null) workouts.add(w);
      }
    } catch (_) {}

    return SyncResult(records: records, workouts: workouts);
  }

  CanonicalRecord? _toCanonical(HealthDataPoint p, MetricType type) {
    final value = p.value;
    if (value is! NumericHealthValue) return null;
    return CanonicalRecord(
      type: type,
      start: p.dateFrom,
      end: p.dateTo,
      value: value.numericValue.toDouble(),
      unit: p.unit.name,
      sourcePlatform: _mapPlatform(p.sourcePlatform),
      sourceApp: p.sourceName.isEmpty ? null : p.sourceName,
    );
  }

  WorkoutRecord? _toWorkout(HealthDataPoint p) {
    final value = p.value;
    if (value is! WorkoutHealthValue) return null;
    final durationSec = p.dateTo.difference(p.dateFrom).inSeconds;
    final distance = value.totalDistance?.toDouble();
    final energy = value.totalEnergyBurned?.toDouble();

    return WorkoutRecord(
      workoutType: value.workoutActivityType.name,
      start: p.dateFrom,
      end: p.dateTo,
      durationSec: durationSec <= 0 ? null : durationSec,
      distanceM: distance,
      activeCalories: energy,
      sourceApp: p.sourceName.isEmpty ? null : p.sourceName,
      sourcePlatform: _mapPlatform(p.sourcePlatform),
    );
  }

  String _mapPlatform(HealthPlatformType platform) {
    switch (platform) {
      case HealthPlatformType.appleHealth:
        return 'apple_health';
      case HealthPlatformType.googleHealthConnect:
        return 'health_connect';
      default:
        return 'unknown';
    }
  }
}
