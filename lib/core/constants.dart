/// Costanti globali dell'app.
class AppConstants {
  static const String appName = 'OpenFitData';
  static const String dbFileName = 'open_fit_data.sqlite';

  /// Health Connect conserva di default ~30 giorni di storico:
  /// la finestra di sync iniziale resta dentro questo limite per non
  /// richiedere il permesso storico esteso nella Milestone 0.
  static const int defaultSyncWindowDays = 30;

  /// Soglia oltre la quale avvisare l'utente che rischia di perdere dati
  /// (Health Connect potrebbe non conservare oltre i 30 giorni).
  static const int staleSyncWarningDays = 20;
}

/// Chiavi del key-value store locale (tabella app_meta).
class MetaKeys {
  static const String lastSyncAt = 'last_sync_at';
  static const String onboardingDone = 'onboarding_done';
  static const String autoSyncEnabled = 'auto_sync_enabled';
}
