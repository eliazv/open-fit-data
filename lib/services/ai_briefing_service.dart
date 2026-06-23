import '../data/db/database.dart';

enum BriefingKind { last7, last30, runningPlan, compareMonths }

extension BriefingKindX on BriefingKind {
  String get label => switch (this) {
        BriefingKind.last7 => 'Analizza ultimi 7 giorni',
        BriefingKind.last30 => 'Analizza ultimi 30 giorni',
        BriefingKind.runningPlan => 'Crea piano corsa',
        BriefingKind.compareMonths => 'Confronta mese corrente',
      };
}

/// Statistiche compatte calcolate da una lista di riepiloghi giornalieri.
class _Stats {
  _Stats(List<DailySummary> s) {
    final steps = s.where((x) => x.steps != null).toList();
    daysWithSteps = steps.length;
    if (steps.isNotEmpty) {
      totalSteps = steps.fold(0, (a, b) => a + (b.steps ?? 0));
      avgSteps = (totalSteps / steps.length).round();
    }
    final dist = s.where((x) => x.distanceM != null);
    totalDistanceKm =
        dist.fold(0.0, (a, b) => a + (b.distanceM ?? 0)) / 1000;
    final sleep = s.where((x) => x.sleepMinutes != null).toList();
    if (sleep.isNotEmpty) {
      avgSleepMin =
          (sleep.fold(0, (a, b) => a + (b.sleepMinutes ?? 0)) / sleep.length)
              .round();
    }
    final weights = s.where((x) => x.weightKg != null).toList();
    if (weights.isNotEmpty) lastWeight = weights.last.weightKg;
    final hr = s.where((x) => x.avgHr != null).toList();
    if (hr.isNotEmpty) {
      avgHr = (hr.fold(0.0, (a, b) => a + (b.avgHr ?? 0)) / hr.length).round();
    }
  }

  int daysWithSteps = 0;
  int totalSteps = 0;
  int? avgSteps;
  double totalDistanceKm = 0;
  int? avgSleepMin;
  double? lastWeight;
  int? avgHr;
}

/// Genera testo sintetico pronto da incollare in ChatGPT/Claude/Gemini.
/// Principio: riepilogo leggibile + richiesta chiara, NON dati grezzi.
class AiBriefingService {
  const AiBriefingService();

  String build({
    required BriefingKind kind,
    required List<DailySummary> primary,
    List<DailySummary> previous = const [],
  }) {
    switch (kind) {
      case BriefingKind.last7:
        return _period(primary, 7);
      case BriefingKind.last30:
        return _period(primary, 30);
      case BriefingKind.runningPlan:
        return _runningPlan(primary);
      case BriefingKind.compareMonths:
        return _compare(primary, previous);
    }
  }

  String _period(List<DailySummary> s, int days) {
    final st = _Stats(s);
    final b = StringBuffer()
      ..writeln('# Briefing fitness — ultimi $days giorni')
      ..writeln()
      ..writeln('## Dati')
      ..writeln('- Giorni con dati passi: ${st.daysWithSteps}')
      ..writeln('- Passi medi: ${_fmt(st.avgSteps)}/giorno')
      ..writeln('- Distanza totale: ${st.totalDistanceKm.toStringAsFixed(1)} km')
      ..writeln('- Sonno medio: ${_sleep(st.avgSleepMin)}')
      ..writeln('- Battito medio: ${_fmt(st.avgHr)} bpm')
      ..writeln('- Peso: ${st.lastWeight?.toStringAsFixed(1) ?? '—'} kg')
      ..writeln()
      ..writeln('## Richiesta')
      ..writeln('1. Analizza il mio stato attuale.')
      ..writeln('2. Valuta se il carico è equilibrato.')
      ..writeln('3. Suggerisci 3 azioni concrete per la prossima settimana.')
      ..writeln()
      ..writeln(_disclaimer);
    return b.toString();
  }

  String _runningPlan(List<DailySummary> s) {
    final st = _Stats(s);
    return (StringBuffer()
          ..writeln('Voglio analizzare i miei dati fitness e creare un piano '
              'corsa sicuro.')
          ..writeln()
          ..writeln('Obiettivo:')
          ..writeln('- iniziare/migliorare la corsa 3 volte a settimana')
          ..writeln('- aumentare resistenza')
          ..writeln('- evitare sovraccarico')
          ..writeln()
          ..writeln('Dati ultimi 30 giorni:')
          ..writeln('- passi medi: ${_fmt(st.avgSteps)}/giorno')
          ..writeln('- distanza totale: '
              '${st.totalDistanceKm.toStringAsFixed(1)} km')
          ..writeln('- sonno medio: ${_sleep(st.avgSleepMin)}')
          ..writeln('- battito medio: ${_fmt(st.avgHr)} bpm')
          ..writeln('- peso: ${st.lastWeight?.toStringAsFixed(1) ?? '—'} kg')
          ..writeln()
          ..writeln('Richiesta:')
          ..writeln('1. Analizza lo stato attuale.')
          ..writeln('2. Valuta il rischio di sovraccarico.')
          ..writeln('3. Crea un piano corsa per i prossimi 7 giorni.')
          ..writeln('4. Dimmi cosa monitorare e quando ridurre il carico.')
          ..writeln()
          ..writeln(_disclaimer))
        .toString();
  }

  String _compare(List<DailySummary> current, List<DailySummary> previous) {
    final c = _Stats(current);
    final p = _Stats(previous);
    return (StringBuffer()
          ..writeln('# Confronto mese corrente vs precedente')
          ..writeln()
          ..writeln('## Mese corrente')
          ..writeln('- passi medi: ${_fmt(c.avgSteps)}/giorno')
          ..writeln('- distanza: ${c.totalDistanceKm.toStringAsFixed(1)} km')
          ..writeln('- sonno medio: ${_sleep(c.avgSleepMin)}')
          ..writeln()
          ..writeln('## Mese precedente')
          ..writeln('- passi medi: ${_fmt(p.avgSteps)}/giorno')
          ..writeln('- distanza: ${p.totalDistanceKm.toStringAsFixed(1)} km')
          ..writeln('- sonno medio: ${_sleep(p.avgSleepMin)}')
          ..writeln()
          ..writeln('## Richiesta')
          ..writeln('1. Confronta i due periodi.')
          ..writeln('2. Dimmi se sto migliorando o peggiorando.')
          ..writeln('3. Suggerisci come progredire in sicurezza.')
          ..writeln()
          ..writeln(_disclaimer))
        .toString();
  }

  static const String _disclaimer =
      '_Nota: non sono consigli medici. Solo fitness/benessere generale._';

  String _sleep(int? minutes) {
    if (minutes == null) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String _fmt(int? n) {
    if (n == null) return '—';
    final s = n.toString();
    final out = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
      out.write(s[i]);
    }
    return out.toString();
  }
}
