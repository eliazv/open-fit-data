# Open Fit Data - Roadmap

Aggiornata: 24 giugno 2026

## Visione

Open Fit Data vuole essere una **cassaforte personale local-first per dati salute e fitness**, collegata a Health Connect su Android e, in futuro, Apple Health su iOS.

L'obiettivo non è creare un clone di Strava, Garmin, Fitbit o Google Fit. L'obiettivo è dare all'utente un posto semplice dove:

- salvare i propri dati fisici in modo indipendente dalle app sorgente;
- non perdere storico quando servizi come Google Fit cambiano policy o vengono dismessi;
- esportare facilmente i dati in formati aperti;
- generare riepiloghi leggibili da ChatGPT, Claude, Gemini o altre AI;
- mantenere il controllo dei dati senza account obbligatorio e senza abbonamenti.

La promessa del prodotto è:

> I tuoi dati fitness, finalmente tuoi.

## Problema che vogliamo risolvere

Molte app salute e fitness leggono o scrivono dati su Health Connect, ma poi ogni piattaforma tende a tenere le funzioni più utili dentro il proprio ecosistema.

Problemi percepiti:

- Google Fit viene progressivamente sostituito e alcune tipologie di dati possono non essere più conservate come prima.
- Strava, Garmin, Fitbit e altre piattaforme spingono sempre più verso funzioni premium o abbonamenti.
- I dati sono sparsi tra telefono, smartwatch, app corsa, bilance, app sonno e servizi cloud.
- Health Connect è un ottimo hub tecnico, ma non è una vera app archivio con export comodo, dashboard storica e report AI-ready.
- I CSV esportati spesso sono scomodi, troppo grezzi o difficili da trasformare in una richiesta utile per AI.
- Gli utenti che vogliono privacy, portabilità e self-hosting non hanno una soluzione semplice e bella da usare.

Open Fit Data deve essere il livello sopra Health Connect:

```text
Health Connect / Apple Health
        ↓
Open Fit Data
        ↓
Archivio locale + export + riepiloghi AI
```

## Posizionamento

### Sì

Open Fit Data è:

- un archivio personale dei dati salute/fitness;
- un'app local-first;
- un ponte tra Health Connect/Apple Health e AI esterne;
- uno strumento di export e backup;
- un progetto potenzialmente open source;
- una base dati personale portabile tra app e dispositivi.

### No

Open Fit Data non deve essere, almeno all'inizio:

- un social network per sportivi;
- un clone di Strava;
- un coach medico;
- una piattaforma cloud obbligatoria;
- un'app basata su AI proprietaria a pagamento;
- un'app con abbonamento come requisito base;
- un progetto complesso con MCP/backend già nella prima versione.

## Principi di prodotto

1. **Local-first**  
   I dati devono vivere prima di tutto sul dispositivo dell'utente.

2. **No account obbligatorio**  
   L'app deve funzionare senza registrazione.

3. **Export-first**  
   Ogni dato importante deve poter essere esportato in formati aperti: CSV, JSON, Markdown, ZIP.

4. **AI-ready, non AI-locked**  
   L'app non deve obbligare l'utente a usare una API a pagamento. Deve preparare report e prompt da copiare o condividere con ChatGPT, Claude, Gemini o qualunque altra AI.

5. **Privacy e trasparenza**  
   Nessun tracciamento invasivo, nessun upload automatico, nessuna sincronizzazione cloud non richiesta.

6. **Deduplica e controllo sorgenti**  
   I dati possono arrivare da più fonti. L'app deve gestire duplicati, preferenze sorgente e trasparenza su cosa viene importato.

7. **Semplicità prima della dashboard perfetta**  
   La prima versione deve risolvere bene: leggo dati, salvo in locale, esporto, genero briefing AI.

## Utenti target

### Utente principale iniziale

Persona che vuole possedere i propri dati fitness e usarli con AI esterne per capire:

- come sta andando fisicamente;
- se sta recuperando bene;
- come iniziare o migliorare la corsa;
- se sta aumentando troppo il carico;
- se sonno, passi, peso e allenamenti sono coerenti con i suoi obiettivi.

### Nicchie interessanti

- Runner principianti.
- Utenti Android stufi della dismissione di Google Fit.
- Utenti Strava/Garmin/Fitbit stufi delle funzioni premium.
- Quantified-self users.
- Utenti privacy-first.
- Sviluppatori che vogliono una base dati personale esportabile.
- Persone che vogliono dare dati salute a ChatGPT/Claude senza pagare API integrate.

## Stack consigliato

### App

- Flutter
- Riverpod o altro state management semplice
- Material 3

### Health data

- Package Flutter `health` come connettore principale
- Android: Health Connect
- iOS futuro: Apple Health / HealthKit

### Storage locale

- Drift + SQLite
- Possibile cifratura locale in una fase successiva

### Export e condivisione

- `share_plus`
- `path_provider`
- `csv`
- `archive`
- generazione Markdown manuale

### Niente backend nella v1

La prima versione deve funzionare senza Supabase, Firebase o server custom.

## Progetti da usare come riferimento

### 1. Flutter `health` package

Da usare come base principale per leggere Health Connect e Apple Health.

Motivo:

- è cross-platform;
- permette di restare su Flutter;
- evita di costruire subito bridge nativi Kotlin/Swift;
- è allineato alla migrazione da Google Fit a Health Connect.

### 2. Health Data Export / healthexport

Da studiare come riferimento funzionale, non necessariamente da integrare direttamente.

Cose utili da copiare come idea:

- export CSV;
- scelta categorie;
- scelta intervalli date;
- export verso Google Sheets;
- attenzione a metriche come speed, distance, steps, sessions, sleep, heart rate, VO2max.

Nota: evitare copia diretta di codice se licenza/riutilizzo non sono chiari.

### 3. HealthConnectExports

Da studiare per:

- export JSON;
- struttura dati semplice;
- invio opzionale a server/webhook.

Possibile feature futura:

- `Export to webhook` per utenti avanzati o self-hosted.

### 4. Health Connect to Webhook

Da tenere come ispirazione per una futura modalità automation/self-hosted.

Non prioritario nella v1.

### 5. Open Wearables / open_wearables_health_sdk

Da valutare solo per una fase avanzata.

Potrebbe essere utile se il progetto diventa più ambizioso e serve:

- sync cloud;
- backend normalizzato;
- supporto più ampio a wearable;
- API per AI;
- integrazione con servizi come Garmin, Strava, Fitbit, Oura, Whoop, Polar, Suunto.

Per la prima versione è troppo complesso.

## MVP v1

Obiettivo: app Flutter Android-first che legge Health Connect, salva localmente e permette export/report AI.

### Funzioni obbligatorie

#### 1. Onboarding

- Spiegazione chiara del progetto.
- Collegamento Health Connect.
- Richiesta permessi essenziali.
- Richiesta accesso storico, se disponibile.
- Spiegazione del limite storico e della necessità di sincronizzare periodicamente.

#### 2. Sync manuale

- Bottone `Sincronizza ora`.
- Import dati Health Connect.
- Salvataggio locale.
- Deduplica.
- Stato ultimo sync.
- Numero record importati.

#### 3. Tipi di dati iniziali

Priorità alta:

- passi;
- distanza;
- sessioni esercizio;
- corsa;
- camminata;
- velocità/speed;
- durata allenamenti;
- battito medio e massimo, se disponibile;
- sonno;
- peso.

Priorità media:

- calorie attive;
- resting heart rate;
- HRV;
- VO2max;
- elevation gain;
- cadenza, se disponibile.

#### 4. Archivio locale

- Salvataggio raw dei record più importanti.
- Tabelle aggregate giornaliere.
- Tabelle dedicate per workout.
- Metadata JSON per mantenere dati non ancora normalizzati.

#### 5. Dashboard minima

Home con:

- ultimo sync;
- giorni archiviati;
- numero record;
- passi medi ultimi 7/30 giorni;
- distanza ultimi 7/30 giorni;
- numero allenamenti;
- sonno medio, se disponibile;
- peso ultimo, se disponibile.

Non serve una dashboard complessa nella prima versione.

#### 6. Export

Formati iniziali:

- CSV;
- JSON;
- Markdown;
- ZIP completo.

Range:

- ultimi 7 giorni;
- ultimi 30 giorni;
- ultimi 90 giorni;
- ultimo anno;
- tutto lo storico disponibile.

#### 7. AI briefing

Feature centrale della v1.

Bottoni:

- `Copia briefing ultimi 7 giorni`;
- `Copia briefing ultimi 30 giorni`;
- `Prepara piano corsa`;
- `Confronta mese corrente e mese precedente`;
- `Condividi con ChatGPT`;
- `Condividi con Claude`.

L'app deve generare testo sintetico, non solo allegare dati grezzi.

Esempio di briefing:

```text
Voglio analizzare i miei dati fitness e creare un piano corsa sicuro.

Obiettivo:
- iniziare a correre 3 volte a settimana
- migliorare resistenza
- evitare sovraccarico

Dati ultimi 30 giorni:
- passi medi: 7.850/giorno
- distanza media giornaliera: 5,4 km
- allenamenti corsa: 4
- distanza corsa totale: 16,2 km
- corsa più lunga: 5,1 km
- passo medio corsa: 6:35/km
- velocità media corsa: 9,1 km/h
- battito medio corsa: 151 bpm
- battito max corsa: 174 bpm
- sonno medio: 6h 42m
- peso: 72 kg
- note manuali: leggero fastidio al tallone dopo corsa lunga

Richiesta:
1. Analizza lo stato attuale.
2. Valuta rischio sovraccarico.
3. Crea un piano corsa per i prossimi 7 giorni.
4. Dimmi cosa monitorare.
5. Dimmi quando fermarmi o ridurre il carico.
```

## Data model iniziale

### `health_raw_records`

```text
id
source_platform
source_app
type
start_time
end_time
value
unit
metadata_json
hash_dedup
imported_at
```

### `daily_summaries`

```text
date
steps
distance_m
active_calories
sleep_minutes
resting_hr
avg_hr
weight_kg
vo2max
updated_at
```

### `workouts`

```text
id
workout_type
start_time
end_time
duration_sec
distance_m
avg_pace_sec_km
avg_hr
max_hr
avg_speed
source_app
raw_json
imported_at
```

### `ai_exports`

```text
id
period_start
period_end
type
markdown_text
json_text
created_at
```

### `user_notes`

```text
id
date
energy_level
fatigue_level
pain_notes
free_note
created_at
```

Le note manuali sono importanti perché i dati automatici non spiegano tutto. Per esempio: fastidio al tallone, stanchezza, mal di gambe, giornata stressante, corsa percepita pesante.

## Architettura app

```text
lib/
  app/
  core/
  data/
    db/
    models/
    repositories/
  features/
    onboarding/
    sync/
    dashboard/
    archive/
    export/
    ai_briefing/
    settings/
  services/
    health_sync_service.dart
    export_service.dart
    ai_briefing_service.dart
    deduplication_service.dart
    summary_service.dart
```

### Servizi principali

#### `HealthSyncService`

Responsabilità:

- leggere permessi;
- richiedere permessi;
- leggere dati da Health Connect/Apple Health;
- convertire in modelli interni;
- lanciare deduplica;
- salvare in database.

#### `DeduplicationService`

Responsabilità:

- generare hash record;
- evitare duplicati identici;
- gestire dati sovrapposti;
- permettere preferenze sorgente.

#### `SummaryService`

Responsabilità:

- generare aggregati giornalieri;
- calcolare medie settimanali/mensili;
- calcolare statistiche per corsa;
- preparare dati compatti per export.

#### `ExportService`

Responsabilità:

- generare CSV;
- generare JSON;
- generare ZIP;
- generare Markdown;
- condividere file con app esterne.

#### `AIBriefingService`

Responsabilità:

- trasformare dati grezzi in riepiloghi utili;
- generare prompt per ChatGPT/Claude;
- evitare output troppo lunghi;
- includere obiettivo utente e note manuali.

## Roadmap per fasi

### Fase 0 - Setup progetto

- Inizializzare app Flutter.
- Configurare Android Health Connect.
- Configurare permessi minimi.
- Aggiungere Drift/SQLite.
- Aggiungere struttura feature-first.
- Aggiungere README iniziale.
- Aggiungere licenza, preferibilmente MIT o AGPL da valutare.

### Fase 1 - Lettura dati base Android

- Collegare package `health`.
- Richiedere permessi Health Connect.
- Leggere passi, distanza e workout.
- Salvare record in SQLite.
- Mostrare ultimo sync.
- Mostrare riepilogo semplice.

### Fase 2 - Export base

- Export CSV per range data.
- Export JSON completo.
- Export Markdown semplice.
- Share sheet verso app esterne.
- Backup ZIP.

### Fase 3 - AI briefing

- Creare template briefing 7 giorni.
- Creare template briefing 30 giorni.
- Creare template piano corsa.
- Creare template confronto mese/mese.
- Aggiungere copia negli appunti.
- Aggiungere condivisione verso ChatGPT/Claude.

### Fase 4 - Dati fitness avanzati

- Battito medio e massimo.
- Sonno.
- Peso.
- VO2max.
- HRV.
- Resting heart rate.
- Speed/velocità.
- Elevation/cadenza se disponibili.

### Fase 5 - Deduplica e sorgenti

- Mostrare sorgente dati.
- Preferenza sorgente per categoria.
- Deduplica record sovrapposti.
- Warning dati potenzialmente duplicati.
- Scelta `preferisci Garmin/Strava/telefono` quando possibile.

### Fase 6 - iOS

- Collegare Apple Health/HealthKit.
- Riutilizzare lo stesso data model.
- Adattare permessi.
- Testare export e AI briefing su iOS.

### Fase 7 - Funzioni avanzate opzionali

Solo se la v1 viene usata davvero:

- backup cifrato su file/cloud scelto dall'utente;
- import da Google Takeout;
- import da ZIP Health Connect;
- export verso Google Sheets;
- webhook personale;
- dashboard web;
- sync self-hosted;
- MCP server read-only;
- integrazione diretta con Strava/Garmin solo se davvero necessaria.

## Import da Google Takeout

Potrebbe diventare una feature utile perché molti utenti hanno storico Google Fit precedente alla migrazione.

Possibile approccio:

- utente scarica Google Takeout;
- importa ZIP o cartella esportata;
- app prova a riconoscere file Fit/JSON/TCX/CSV;
- normalizza nel database locale;
- mostra cosa è stato importato;
- evita duplicati con dati già presenti da Health Connect.

Non è prioritaria per la primissima versione, ma è molto coerente con il problema originale: non perdere dati quando Google cambia gestione dello storico.

## Domande aperte

1. Quale licenza usare?
   - MIT è più semplice e permissiva.
   - AGPL protegge meglio se qualcuno trasforma il progetto in servizio cloud.

2. L'app deve essere pubblicata come progetto open source fin da subito?
   - Probabilmente sì, perché il tema è fiducia/privacy.

3. Serve cifratura locale già nella v1?
   - Utile, ma può rallentare lo sviluppo. Da valutare dopo MVP base.

4. Quali tipi di dato chiedere all'inizio?
   - Meglio pochi e ben spiegati, per evitare problemi di review Play Store e diffidenza utenti.

5. L'app deve avere tracking analytics?
   - Idealmente no nella prima versione.
   - Se proprio necessario, deve essere opzionale e privacy-friendly.

6. Come gestire dati sensibili e responsabilità salute?
   - Evitare consigli medici.
   - Parlare di fitness e benessere generale.
   - Inserire disclaimer chiaro.

## Cose da evitare

- Partire subito con backend.
- Integrare AI via API a pagamento.
- Creare piani allenamento aggressivi o medicalizzati.
- Copiare Strava/Garmin.
- Aggiungere social, classifiche, segmenti.
- Chiedere troppi permessi al primo avvio.
- Salvare dati in cloud senza necessità.
- Rendere obbligatorio un account.

## Prima milestone concreta

La prima milestone deve essere molto piccola:

> Apro l'app, collego Health Connect, sincronizzo passi/distanza/allenamenti, salvo in SQLite, genero un report Markdown degli ultimi 30 giorni e lo condivido con ChatGPT o Claude.

Quando questa funziona, il progetto ha già valore reale.

## Checklist iniziale sviluppo

- [ ] Creare progetto Flutter.
- [ ] Aggiungere package `health`.
- [ ] Configurare permessi Android Health Connect.
- [ ] Aggiungere Drift/SQLite.
- [ ] Creare tabella `health_raw_records`.
- [ ] Creare tabella `daily_summaries`.
- [ ] Creare tabella `workouts`.
- [ ] Implementare sync manuale.
- [ ] Salvare passi e distanza.
- [ ] Salvare sessioni workout.
- [ ] Mostrare home con ultimo sync.
- [ ] Generare CSV ultimi 30 giorni.
- [ ] Generare JSON ultimi 30 giorni.
- [ ] Generare Markdown AI briefing.
- [ ] Aggiungere share sheet.
- [ ] Testare con dati reali personali.

## Possibile README breve

```text
Open Fit Data is a local-first Flutter app to archive, export and analyze your Health Connect and Apple Health data.

It is not a Strava clone.
It is not an AI coach locked behind a subscription.
It is a personal health data vault designed to keep your fitness data portable, readable and AI-ready.
```

## Sintesi finale

Open Fit Data ha senso se resta focalizzata su tre parole:

> Archivio. Export. AI-ready.

Il progetto deve nascere per risolvere un bisogno personale concreto: conservare i dati salute/fitness in modo indipendente e portarli facilmente dentro strumenti AI esterni.

La v1 non deve essere perfetta. Deve solo dimostrare che l'utente può finalmente dire:

> Questi dati sono miei, li salvo io, li esporto io, li porto dove voglio.
