/// Helper di formattazione condivisi (numeri, durate).
class Format {
  const Format._();

  /// Intero con separatore delle migliaia (.), o "—" se null.
  static String intDot(int? n) {
    if (n == null) return '—';
    final s = n.abs().toString();
    final out = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) out.write('.');
      out.write(s[i]);
    }
    return out.toString();
  }

  /// Minuti → "Nh MMm".
  static String duration(int? minutes) {
    if (minutes == null) return '—';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  /// Secondi → passo "M:SS/km".
  static String pace(int? secPerKm) {
    if (secPerKm == null) return '—';
    final m = secPerKm ~/ 60;
    final s = secPerKm % 60;
    return '$m:${s.toString().padLeft(2, '0')}/km';
  }
}
