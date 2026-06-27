# Open Fit Data

> I tuoi dati fitness, finalmente tuoi.

App Flutter **local-first** per archiviare, esportare e analizzare i dati di
**Health Connect** (Android) e **Apple Health** (iOS). Non è un clone di Strava
né un coach AI a pagamento: è una **cassaforte personale** per i tuoi dati
salute/fitness, portabili e pronti per ChatGPT/Claude/Gemini.

**Archivio. Export. AI-ready.**

## Funzioni (v1 Android)

- 🔄 **Sync automatico** in background (~2×/giorno) + sync all'avvio + manuale
- 🗄️ **Archivio locale** SQLite (Drift) con deduplica
- 📊 **Dashboard + Trends** (passi, distanza, sonno, peso, battito) con grafici
- 🏃 **Allenamenti** importati con dettaglio (passo, velocità, FC)
- 📝 **Note manuali** giornaliere (energia, fatica, dolori) → arricchiscono i briefing
- 🤖 **Briefing AI** pronti da incollare (7g / 30g / piano corsa / confronto mesi)
- ⬇️ **Export** CSV / JSON / Markdown / ZIP per periodo
- 🍎 **iOS** via Apple Health (stesso archivio/UI; vedi `docs/IOS_SETUP.md`)
- 🔒 **Privacy**: nessun account, nessun cloud obbligatorio, nessun tracking

## Installazione

Niente Play Store: APK firmato pubblicato nelle [GitHub Releases](https://github.com/eliazv/open-fit-data/releases).

- **Manuale**: scarica l'ultimo `OpenFitData-vX.Y.Z.apk` dalla pagina Releases e installalo (serve consentire "sorgenti sconosciute").
- **Aggiornamenti automatici**: usa [Obtainium](https://github.com/ImranR98/Obtainium) → "Add App" → URL del repo `https://github.com/eliazv/open-fit-data` → Obtainium rileva le release GitHub e ti avvisa/aggiorna ad ogni nuova versione, senza Play Store.

## Stack

Flutter · Riverpod · Drift (SQLite) · `health` · workmanager · fl_chart ·
animations · share_plus · csv · archive

## Setup

Questo repository contiene il codice `lib/` e la configurazione del progetto.
Le cartelle native (`android/`) si generano con Flutter:

```bash
# 1. Genera gli shell nativi senza toccare lib/ (android + ios)
flutter create . --org com.eliazavatta --project-name open_fit_data --platforms=android,ios

# 2. Dipendenze
flutter pub get

# 3. Codegen Drift (genera lib/data/db/database.g.dart)
dart run build_runner build --delete-conflicting-outputs

# 4. Applica la configurazione Health Connect
#    Vedi: docs/ANDROID_SETUP.md  (manifest, permessi, MainActivity)

# 5. Avvia
flutter run
```

> ⚠️ **Importante:** Health Connect richiede modifiche al manifest Android, la
> dichiarazione dei permessi salute e `MainActivity` che estende
> `FlutterFragmentActivity`. Tutti i dettagli in **`docs/ANDROID_SETUP.md`**.

## Architettura

```
lib/
  app/        — App, tema, providers (DI Riverpod), gate onboarding
  core/       — costanti, enum periodo
  data/
    db/       — database Drift (tabelle raw, daily_summaries, workouts, meta)
    models/   — CanonicalRecord / WorkoutRecord (layer cross-platform)
    repositories/ — ArchiveRepository
  services/   — health_sync, sync, background_sync, summary,
                deduplication, export, ai_briefing
  features/   — onboarding, shell, home, archive, workouts,
                ai_briefing, export, settings
  widgets/    — design system (MetricCard, SyncStatusCard, charts, ...)
```

Il layer `CanonicalRecord` disaccoppia l'app dai tipi del package `health`:
l'aggiunta di iOS (HealthKit) sarà un secondo "source" senza toccare
archivio/UI. Vedi `ANALISI_ROADMAP.md` §3.3.

## Documenti

- [`docs/ROADMAP.md`](docs/ROADMAP.md) — visione e piano per fasi
- [`docs/ANALISI_ROADMAP.md`](docs/ANALISI_ROADMAP.md) — analisi tecnica/di prodotto
- [`docs/DESIGN_UI.md`](docs/DESIGN_UI.md) — design system e direzione UI
- [`docs/ANDROID_SETUP.md`](docs/ANDROID_SETUP.md) — configurazione Android
- [`docs/IOS_SETUP.md`](docs/IOS_SETUP.md) — configurazione iOS (HealthKit)
- [`docs/IMPLEMENTAZIONE.md`](docs/IMPLEMENTAZIONE.md) — stato della v1 e note
- [`docs/RELEASING.md`](docs/RELEASING.md) — come pubblicare una nuova release

## Licenza

[AGPL-3.0](LICENSE).
