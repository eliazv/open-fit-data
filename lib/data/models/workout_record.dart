/// Allenamento normalizzato, indipendente dalla piattaforma.
class WorkoutRecord {
  const WorkoutRecord({
    required this.workoutType,
    required this.start,
    required this.end,
    required this.sourcePlatform,
    this.durationSec,
    this.distanceM,
    this.activeCalories,
    this.avgHr,
    this.maxHr,
    this.sourceApp,
  });

  final String workoutType;
  final DateTime start;
  final DateTime end;
  final String sourcePlatform;
  final int? durationSec;
  final double? distanceM;
  final double? activeCalories;
  final double? avgHr;
  final double? maxHr;
  final String? sourceApp;

  /// Passo medio in secondi/km, se distanza e durata note.
  int? get avgPaceSecKm {
    if (durationSec == null || distanceM == null || distanceM! <= 0) {
      return null;
    }
    return (durationSec! / (distanceM! / 1000)).round();
  }

  /// Velocità media in km/h, se distanza e durata note.
  double? get avgSpeedKmh {
    if (durationSec == null || durationSec! <= 0 || distanceM == null) {
      return null;
    }
    return (distanceM! / 1000) / (durationSec! / 3600);
  }
}
