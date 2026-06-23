# Stato implementazione — v1 Android

Riepilogo di cosa è stato costruito nella prima versione e note operative.

## Cosa c'è

| Area | Stato | File principali |
|---|---|---|
| Onboarding | ✅ | `features/onboarding/` |
| Disponibilità Health Connect + permessi | ✅ | `services/health_sync_service.dart` |
| Sync **automatico** background (~2×/giorno) | ✅ | `services/background_sync.dart` |
| Sync all'avvio (silenzioso) + manuale | ✅ | `features/shell/`, `features/home/` |
| Lettura multi-metrica + workout | ✅ | `services/health_sync_service.dart` |
| Deduplica (hash) | ✅ | `services/deduplication_service.dart` |
| Archivio locale (Drift/SQLite) | ✅ | `data/db/`, `data/repositories/` |
| Aggregati giornalieri | ✅ | `services/summary_service.dart` |
| Dashboard Home | ✅ | `features/home/` |
| Archivio + Trends (fl_chart) | ✅ | `features/archive/` |
| Allenamenti (lista + dettaglio) | ✅ | `features/workouts/` |
| Briefing AI (7g/30g/piano/confronto) | ✅ | `features/ai_briefing/` |
| Export CSV/JSON/Markdown/ZIP | ✅ | `services/export_service.dart`, `features/export/` |
| Impostazioni (toggle auto-sync, disclaimer) | ✅ | `features/settings/` |
| UI Material 3 + animazioni (`animations`) | ✅ | `features/shell/app_shell.dart`, `app/theme.dart` |

## Metriche sincronizzate in v1

Passi, distanza, calorie attive, battito, battito a riposo, sonno, peso,
allenamenti (con passo/velocità derivati). VO2max/HRV/cadenza: campi già
presenti nel data model, attivabili senza migrazioni distruttive.

## Auto-sync: come funziona

1. **Onboarding** → primo sync + registrazione task periodico `workmanager`.
2. **All'avvio app** → sync silenzioso non interattivo (se permessi concessi).
3. **Background** → `workmanager` ~ogni 12h, best-effort.
4. **Manuale** → pull-to-refresh / bottone in Home.

La finestra di lettura resta a 30 giorni per non superare la retention di
Health Connect senza permesso storico (vedi ANALISI_ROADMAP §5).

## Come eseguire

⚠️ Le cartelle native non sono nel repo: vanno generate (il container di
sviluppo non aveva la toolchain Flutter, quindi `lib/` è stato scritto a mano).

```bash
flutter create . --org com.eliazavatta --project-name open_fit_data --platforms=android
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # genera database.g.dart
# Applica docs/ANDROID_SETUP.md (manifest, permessi, MainActivity)
flutter run
```

## Note / cose da verificare in locale

- **Codegen Drift**: `database.g.dart` è generato da build_runner (gitignored).
- **API package `health` v11**: i nomi di tipi/campi possono variare di poco
  tra minor version. Se `flutter pub get` risolve una versione diversa,
  verificare `getHealthDataFromTypes`, `WorkoutHealthValue`,
  `HealthPlatformType` in `health_sync_service.dart`.
- **MainActivity** deve estendere `FlutterFragmentActivity` (vedi setup).
- **Sleep**: la mappatura usa `SLEEP_ASLEEP`; alcune sorgenti espongono il
  sonno come sessioni/stadi → da affinare con dati reali (ANALISI_ROADMAP §3.3).
- **Deduplica multi-sorgente**: in v1 è solo per duplicati identici; la
  priorità sorgente (telefono vs smartwatch) è Fase 5 (ANALISI_ROADMAP §3.4).

## Prossimi passi suggeriti

1. Test con dati reali e rifinitura mappatura sonno/distanza.
2. Sparkline dentro le `MetricCard` (oggi numeri; grafici nei Trends).
3. Permesso storico esteso + import Google Takeout (recupero storico pre-HC).
4. Fase 6 iOS: aggiungere un `HealthKitSource` che produce gli stessi
   `CanonicalRecord` — archivio/UI restano invariati.
