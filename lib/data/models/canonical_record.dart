import 'metric_type.dart';

/// Record salute normalizzato e indipendente dalla piattaforma.
///
/// È il layer chiave per il supporto multi-piattaforma (vedi ANALISI_ROADMAP
/// §3.3): Android (Health Connect) e iOS (HealthKit) producono entrambi
/// `CanonicalRecord`, quindi archivio, dedup, summary ed export non
/// conoscono mai i tipi del package `health`.
class CanonicalRecord {
  const CanonicalRecord({
    required this.type,
    required this.start,
    required this.end,
    required this.value,
    required this.unit,
    required this.sourcePlatform,
    this.sourceApp,
    this.metadata = const {},
  });

  final MetricType type;
  final DateTime start;
  final DateTime end;
  final double value;
  final String unit;

  /// es. "health_connect" / "apple_health".
  final String sourcePlatform;

  /// App che ha generato il dato, se nota (es. "Strava", "Google Fit").
  final String? sourceApp;

  final Map<String, dynamic> metadata;

  CanonicalRecord copyWith({double? value, Map<String, dynamic>? metadata}) {
    return CanonicalRecord(
      type: type,
      start: start,
      end: end,
      value: value ?? this.value,
      unit: unit,
      sourcePlatform: sourcePlatform,
      sourceApp: sourceApp,
      metadata: metadata ?? this.metadata,
    );
  }
}
