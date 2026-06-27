import '../data/models/canonical_record.dart';
import '../data/models/metric_type.dart';

/// Regole locali e deterministiche per non sommare ciecamente dati sovrapposti
/// da telefono, smartwatch e app terze. Le preferenze utente arriveranno sopra
/// questa base; intanto evitiamo doppi conteggi evidenti.
class SourcePriorityService {
  const SourcePriorityService({this.preferences = const {}});

  /// Chiave: MetricType.id, valore: lista di frammenti nome sorgente in ordine.
  final Map<String, List<String>> preferences;

  List<CanonicalRecord> withoutOverlaps(List<CanonicalRecord> records) {
    final sorted = [...records]..sort((a, b) {
        final byPriority = _rank(a).compareTo(_rank(b));
        if (byPriority != 0) return byPriority;
        final byStart = a.start.compareTo(b.start);
        if (byStart != 0) return byStart;
        return b.end.difference(b.start).compareTo(a.end.difference(a.start));
      });

    final accepted = <CanonicalRecord>[];
    for (final record in sorted) {
      if (!accepted.any((existing) => _overlaps(existing, record))) {
        accepted.add(record);
      }
    }
    return accepted..sort((a, b) => a.start.compareTo(b.start));
  }

  int _rank(CanonicalRecord record) {
    final source = (record.sourceApp ?? record.sourcePlatform).toLowerCase();
    final configured = preferences[record.type.id] ?? const <String>[];
    for (var i = 0; i < configured.length; i++) {
      if (source.contains(configured[i].toLowerCase())) return i;
    }

    final defaults = _defaultOrder(record.type);
    for (var i = 0; i < defaults.length; i++) {
      if (source.contains(defaults[i])) return configured.length + i;
    }
    return configured.length + defaults.length + 1;
  }

  List<String> _defaultOrder(MetricType type) => switch (type) {
        MetricType.steps || MetricType.distance => const [
            'garmin',
            'fitbit',
            'samsung',
            'polar',
            'suunto',
            'health connect',
            'google fit',
            'phone',
          ],
        MetricType.sleep || MetricType.heartRate || MetricType.hrv => const [
            'garmin',
            'fitbit',
            'oura',
            'whoop',
            'samsung',
            'polar',
            'apple',
            'health connect',
          ],
        _ => const [
            'garmin',
            'fitbit',
            'samsung',
            'strava',
            'health connect',
            'apple',
          ],
      };

  bool _overlaps(CanonicalRecord a, CanonicalRecord b) {
    if (a.type != b.type) return false;
    return a.start.isBefore(b.end) && b.start.isBefore(a.end);
  }
}
