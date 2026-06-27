import 'package:flutter/material.dart';

/// Tema dell'app: Material 3, seed verde/acqua, dark + light.
/// Look "data vault" sobrio: niente nero puro in dark, card morbide.
class AppTheme {
  // Accent verde/acqua (salute/benessere, distinto da Strava/Fitbit).
  static const Color _seed = Color(0xFF00BFA6);

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );

    // Nero "soft" in dark mode, non #000.
    final surface = brightness == Brightness.dark
        ? const Color(0xFF121417)
        : const Color(0xFFF7F8FA);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerHighest,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
