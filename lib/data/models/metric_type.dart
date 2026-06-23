/// Tipi di metrica canonici, indipendenti dalla piattaforma sorgente.
///
/// Questo enum è il "vocabolario interno" dell'app: il mapping da/verso
/// Health Connect (Android) e HealthKit (iOS) avviene nei service, così il
/// resto dell'app non dipende mai dai tipi del package `health`.
enum MetricType {
  steps,
  distance,
  activeCalories,
  heartRate,
  restingHeartRate,
  sleep,
  weight,
  speed,
  vo2max;

  /// Identificatore stabile usato per persistenza e hash di deduplica.
  String get id => name;

  static MetricType? tryFromId(String id) {
    for (final t in MetricType.values) {
      if (t.name == id) return t;
    }
    return null;
  }

  /// Etichetta leggibile in italiano.
  String get label => switch (this) {
        MetricType.steps => 'Passi',
        MetricType.distance => 'Distanza',
        MetricType.activeCalories => 'Calorie attive',
        MetricType.heartRate => 'Battito',
        MetricType.restingHeartRate => 'Battito a riposo',
        MetricType.sleep => 'Sonno',
        MetricType.weight => 'Peso',
        MetricType.speed => 'Velocità',
        MetricType.vo2max => 'VO2max',
      };
}

extension MetricTypeX on MetricType {
  /// Variante non-null usata in persistenza (default sicuro: steps).
  static MetricType fromId(String id) =>
      MetricType.tryFromId(id) ?? MetricType.steps;
}
