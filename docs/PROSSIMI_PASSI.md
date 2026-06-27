# Stato attuale e prossimi passi — Raccolta dati, organizzazione, export

> Resoconto onesto della v1 e piano d'azione per arrivare a una raccolta dati
> **completa e organizzata** con interfaccia e **export adatti**.
> Aggiornato: 24 giugno 2026

---

## 1. Resoconto onesto della v1

Valutazione basata sul codice realmente scritto, non sulle intenzioni.

| Area | Voto | Sintesi |
|---|---|---|
| Raccolta dati | 7/10 | Funziona e deduplica, ma finestra 30 giorni, niente storico, mancano VO2max/HRV, dedup base |
| Consultabilità / UX | 7/10 | Pulita e con icone, ma grafici parziali e senza sparkline/delta/badge sorgente |
| Export | 7/10 | 4 formati + range, ma nessuna scelta categorie e nessuna anteprima |

**Non è "completa e ottimale": è una v1 onesta e coerente, con basi giuste e
rifiniture mancanti.**

---

## 2. Raccolta dati — cosa manca per essere "completa e organizzata"

### 2.1 Cosa raccoglie oggi
Passi, distanza, calorie attive, battito, battito a riposo, sonno, peso,
allenamenti. Dedup nativo (`health.removeDuplicates`) + hash su record identici.

### 2.2 Gap e azioni

| Gap | Stato | Azione | Priorità |
|---|---|---|---|
| **Finestra 30 giorni** | Legge solo ultimi 30 gg | Permesso storico `READ_HEALTH_DATA_HISTORY` + `requestHealthDataHistoryAuthorization()`; sync iniziale "tutto lo storico disponibile" | 🔴 Alta |
| **Storico pre-Health Connect** | Non importabile | Import **Google Takeout** (ZIP/JSON/TCX/CSV) → normalizza in `health_raw_records` | 🟡 Media |
| **VO2max / HRV** | Campi presenti, non letti | Aggiungere i tipi in `health_sync_service` (già nel data model) | 🟡 Media |
| **Cadenza / elevation** | Non letti | Best-effort dai workout quando disponibili | 🟢 Bassa |
| **Dedup multi-sorgente** | Solo duplicati identici | Priorità sorgente per categoria (es. "preferisci Garmin per la corsa"); warning sovrapposizioni | 🔴 Alta |
| **Aggregazioni** | Media HR non pesata | HR media pesata sul tempo; sonno per stadi se disponibili | 🟢 Bassa |
| **Stato per-categoria del sync** | Solo conteggio totale | Mostrare per ogni metrica: ultimo dato, n° record, sorgente | 🟡 Media |

### 2.3 "Organizzata"
- Tabella **`sync_log`** (timestamp, tipo, record importati, esito) per
  trasparenza e debug.
- **Vista per sorgente**: quali app stanno scrivendo cosa (Strava, telefono…).
- **Indicatore di copertura**: quanti giorni hanno dati per ciascuna metrica
  (oggi sappiamo "giorni archiviati" totali, non per metrica).

---

## 3. Consultabilità / UX — cosa manca per "tutto a colpo d'occhio"

### 3.1 Cosa c'è
Material 3 pulito, navigazione a 4 tab, icone ovunque, selettore periodo,
grafico barre (passi) e linea (peso).

### 3.2 Gap e azioni

| Gap | Stato | Azione | Priorità |
|---|---|---|---|
| **Sparkline nelle MetricCard** | ❌ | Mini-grafico dentro ogni card (mini line/bars) | 🔴 Alta |
| **Delta vs periodo precedente** (`+12%`) | ❌ | Calcolo confronto e badge colorato su/giù | 🔴 Alta |
| **Badge sorgente sulle metriche** | Solo workout | `SourceBadge` su card e dettagli | 🟡 Media |
| **Grafici distanza / sonno / battito** | ❌ | Barre distanza, barre orizzontali sonno, linea HR/resting | 🔴 Alta |
| **Carico settimanale** | ❌ | Barre per settimana (passi/distanza/allenamenti) | 🟢 Bassa |
| **Dettaglio per metrica** | ❌ | Tap su card → schermata con grafico grande + storico tabellare | 🟡 Media |
| **Stati vuoti per metrica** | Parziale | `EmptyState` mirato quando una metrica non ha dati | 🟢 Bassa |
| **Pull-to-refresh ovunque** | Solo Home | Estendere ad Archivio/Workouts | 🟢 Bassa |

### 3.3 Riconoscibilità
- **Colore/iconografia coerente per metrica** (es. passi=verde-camminata,
  sonno=indaco-luna, peso=bilancia): una mappa `MetricType → (icona, colore)`
  centralizzata, così card, grafici e badge usano sempre lo stesso linguaggio.

---

## 4. Export — cosa manca per essere "adatto"

### 4.1 Cosa c'è
CSV / JSON / Markdown / ZIP, con selettore periodo, generazione locale +
share sheet. Nessun upload automatico.

### 4.2 Gap e azioni

| Gap | Stato | Azione | Priorità |
|---|---|---|---|
| **Scelta categorie** | ❌ (esporta tutto) | Checkbox per metrica/categoria prima dell'export | 🔴 Alta |
| **Anteprima export** | ❌ | Mostrare righe/dimensione stimata prima di condividere | 🟡 Media |
| **Export workout-specifico** | ❌ | Dal dettaglio workout: esporta singolo (CSV/GPX futuro) | 🟡 Media |
| **Granularità** | Solo daily | Opzione "dati grezzi" oltre agli aggregati | 🟢 Bassa |
| **Nome file parlante** | Timestamp | Includere range e categorie nel nome | 🟢 Bassa |
| **Export to webhook** | ❌ | Modalità avanzata self-hosted (da HealthConnectExports) | 🟢 Bassa |
| **Export incrementale** | ❌ | "Solo dati dopo l'ultimo export" per backup ricorrenti | 🟢 Bassa |

### 4.3 "Adatto"
- L'export deve rispecchiare **ciò che vedi**: le stesse categorie/icone della
  dashboard, così l'utente capisce cosa sta esportando.
- **Markdown export** allineato al briefing AI (stesso linguaggio leggibile),
  non solo tabelle grezze.

---

## 5. Piano operativo consigliato (ordine)

Ordinato per **valore percepito dall'utente / sforzo**.

### Step 1 — UX "a colpo d'occhio" (alta resa, basso rischio)
1. Mappa centralizzata `MetricType → (icona, colore, unità)`.
2. **Sparkline** + **delta vs periodo precedente** nelle `MetricCard`.
3. Grafici **distanza, sonno, battito** (riuso di `BarTrendChart` / linea).

### Step 2 — Export adatto
4. **Scelta categorie** nell'export + nome file parlante.
5. Anteprima (righe/dimensione) prima della condivisione.

### Step 3 — Raccolta completa
6. **Permesso storico** + sync "tutto lo storico disponibile".
7. **VO2max / HRV** in sync.
8. **Badge sorgente** su metriche + `sync_log` + copertura per metrica.

### Step 4 — Raccolta avanzata (quando la v1 è usata davvero)
9. **Dedup multi-sorgente** con priorità per categoria.
10. **Import Google Takeout** (recupero storico pre-Health Connect).

---

## 6. Definizione di "fatto" per ciascun obiettivo

- **Raccolta completa**: l'utente, alla prima sincronizzazione, vede *tutto lo
  storico disponibile* (non solo 30 giorni), con VO2max/HRV se presenti, senza
  doppi conteggi tra sorgenti, e capisce *da dove* arriva ogni dato.
- **Organizzata**: ogni metrica ha copertura, sorgente e ultimo aggiornamento
  visibili; un log di sync trasparente.
- **Interfaccia "a colpo d'occhio"**: ogni card mostra valore + tendenza
  (sparkline) + confronto + sorgente, con icona/colore coerenti per metrica.
- **Export adatto**: scegli *cosa* e *quando*, vedi un'anteprima, e ottieni un
  file che rispecchia ciò che vedi nella dashboard.

---

## 7. Cosa NON fare (per non rompere il posizionamento)

- Non aggiungere grafici "ricchi"/animati ovunque: sparkline e barre semplici
  bastano, il valore è la leggibilità.
- Non trasformare l'export in un wizard a 5 step: categorie + range + formato,
  massimo una schermata.
- Non introdurre sync cloud o account per "organizzare meglio": resta
  local-first.
- Non sommare mai dati multi-sorgente senza gestione duplicati: meglio un
  warning che un totale sbagliato.
