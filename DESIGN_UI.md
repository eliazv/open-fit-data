# Design & UI — Open Fit Data

> Considerazioni su look, schermate, design system e librerie grafiche.
> Direzione: **personal data vault moderno**, non app fitness/coach.
> Aggiornato: 23 giugno 2026

---

## 1. Direzione di design (verdetto)

**Concordo in pieno con l'impostazione "data vault, non gym app".** È la scelta giusta e coerente al 100% col posizionamento della roadmap ("Archivio. Export. AI-ready."). Una UI con trainer, sfide, calorie, foto di gente che corre tradirebbe il prodotto.

La formula di riferimento è corretta:

> **Semplicità di Google Fit + pulizia di Apple Health + dashboard quantified-self + sezione AI/Export tua (il differenziante).**

Principi visivi:

- sfondo molto pulito (grigio chiarissimo in light, nero soft in dark — **non** nero puro #000);
- card grandi, arrotondate, con numeri grandi;
- grafici piccoli e *poco rumorosi* dentro le card;
- **un solo colore accent**;
- icone lineari, niente fotografie, niente illustrazioni fitness aggressive;
- molto spazio bianco;
- la sezione **AI/Export sempre visibile e centrale** — è ciò che vende l'app.

### Cosa NON fare (design)
- ❌ Niente template fitness generico copiato 1:1 da Dribbble (belli ma senza logica reale).
- ❌ Niente look "gym app" (trainer, challenge, social, calorie, segmenti).
- ❌ Niente asset/layout copiati identici da progetti esistenti (reference visiva sì, copia no).
- ❌ Niente grafici "ricchi" in v1: sparkline e barre semplici bastano.

---

## 2. Navigazione

**Bottom navigation a 4 tab** (scelta raccomandata, meno è meglio):

```
Home  |  Archivio  |  AI  |  Export
```

> Variante a 5 tab (Home / Archivio / Trend / AI / Impostazioni) valutabile più avanti.
> In v1 le impostazioni stanno dentro un'icona in Home; i Trend possono vivere dentro Archivio.

---

## 3. Schermate

### 3.1 Home — *non deve sembrare Strava*
La schermata principale è uno "stato dell'archivio + azioni rapide".

```
Open Fit Data
Ultimo sync: oggi 09:42
Dati archiviati: 214 giorni · Record: 18.420
[ Sincronizza ora ]

Ultimi 7 giorni
[ Passi medi ] [ Distanza ]
[ Allenamenti ] [ Sonno ]

[ ✨ Genera briefing AI ]   [ ⬇ Esporta dati ]
```

### 3.2 Archivio / Dashboard dati
Griglia di card metrica, ognuna con:
- valore attuale;
- confronto col periodo precedente (es. `+12%`);
- mini-sparkline;
- **badge sorgente** (Health Connect / Strava / telefono).

```
Passi
7.842 / giorno   +12% vs settimana scorsa
▁▂▃▅▂▆▇  · Fonte: Health Connect
```

Metriche: passi, distanza, corsa, sonno, peso, battito, velocità, VO2max (se disponibile).

### 3.3 Trends (dentro Archivio in v1)
Filtro periodo: `7G | 30G | 90G | 1A | Tutto`. Grafici: passi/distanza (barre), peso/resting HR (linea), sonno (barre orizzontali), carico settimanale (barre).

### 3.4 Workouts
Lista allenamenti + dettaglio (distanza, durata, passo, velocità, FC, grafico, sorgente, **export singolo workout**).

### 3.5 AI Briefing — *il vero differenziante*
Tab dedicata. Azioni + anteprima del testo generato:

```
[ Analizza ultimi 7 giorni ]
[ Analizza ultimi 30 giorni ]
[ Crea piano corsa ]
[ Confronta mese corrente ]
[ Esporta report completo ]

— Anteprima —
Report fitness ultimi 30 giorni...
[ Copia ]  [ Condividi con ChatGPT ]  [ Condividi con Claude ]
```

---

## 4. Design system (componenti da costruire subito)

Invece di cercare un template completo, si costruisce una **mini design system** riusabile. Questo evita debito visivo e rende le schermate "moltiplicazione" dello stesso mattone:

| Componente | Ruolo |
|---|---|
| `MetricCard` | valore + delta + sparkline + sorgente |
| `TrendCard` | grafico per una metrica con selettore periodo |
| `WorkoutCard` | riga allenamento in lista |
| `SourceBadge` | etichetta sorgente dati |
| `SyncStatusCard` | ultimo sync + record + bottone sincronizza |
| `ExportFormatCard` | scelta formato/range export |
| `AIBriefingPreview` | anteprima testo + copia/condividi |
| `PeriodSegmentedControl` | `7G/30G/90G/1A/Tutto` |
| `MiniSparkline` | micro-grafico dentro le card |
| `EmptyState` | stato vuoto (nessun dato/sync) |
| `PermissionExplainerCard` | spiega permessi prima di chiederli |

Struttura Home (esempio):

```
Home
├── SyncStatusCard
├── QuickActionCard: Genera briefing AI
├── MetricGrid (StepsCard · DistanceCard · WorkoutsCard · SleepCard)
└── ExportCard
```

> `PermissionExplainerCard` non è cosmetico: i permessi *just-in-time* con spiegazione riducono l'attrito di review Play Store e la diffidenza utente (vedi ANALISI_ROADMAP §3.2).

---

## 5. Librerie grafiche

| Libreria | Licenza | Verdetto |
|---|---|---|
| **`fl_chart`** | MIT | ✅ **Scelta v1.** Linee, barre, pie, scatter, radar. Personalizzabile, molto usato, sufficiente per dashboard fitness. |
| `graphic` | MIT | Valutabile in seguito per data-viz più raffinata (grammar of graphics, interazioni/animazioni). Non in v1. |
| Syncfusion charts | Commerciale / Community License | ❌ Evitare: licenza commerciale, over-kill per la v1. Solo se servissero chart molto avanzati. |

**Sparkline:** spesso bastano `CustomPainter` semplici o `fl_chart` minimale — niente di pesante dentro le card.

---

## 6. Tema

- **Material 3**, dark + light (entrambi dal giorno 1: ColorScheme da seed).
- Accent unico (verde/acqua/blu — direzione "salute/benessere sobrio", da confermare).
- Card morbide (`rounded`, elevazione bassa), tipografia con numeri grandi e leggibili.
- Niente nero puro in dark mode (nero soft → meno affaticamento, look premium).

---

## 7. Reference: dove guardare (NON copiare)

**Estetica** (solo reference visiva — Dribbble / Mobbin / Figma Community):
`health dashboard mobile app`, `quantified self app`, `health data visualization`, `wellness dashboard mobile`, `wearable app dashboard`.

Elementi ricorrenti delle UI moderne migliori: card grandi arrotondate · grafici piccoli dentro le card · tab 7g/mese/anno · bottom nav semplice · "today summary" in alto · accent unico · molto spazio bianco · numeri grandi · grafici poco rumorosi.

**UX/filosofia** (open source — guardare la *logica*, non l'estetica, spesso datata):
- **OpenTracks / RunnerUp / FitoTrack** → tracking, statistiche, export GPX/FIT/CSV. Funzionali, non moderni.
- App open source/local-first per leggere dati Whoop senza abbonamento → filosofia molto vicina a Open Fit Data ("i tuoi dati su un dispositivo che controlli tu, senza cloud obbligatorio").
- **Esempio del package `health`** → usarlo SOLO per la logica Health Connect/HealthKit (permessi, lettura, dedup), **mai** come UI finale.

---

## 8. Differenze tra questa proposta e l'impostazione iniziale

Concordo con quasi tutto. Le mie poche precisazioni:

1. **Costruire la design system PRIMA delle schermate complete.** I componenti di §4 vanno fatti nella Milestone 0 (anche brutti): poi ogni schermata è composizione, non lavoro da zero.
2. **Trend dentro Archivio in v1**, non tab separata → tiene la bottom nav a 4 e rimanda i grafici "veri" (che sono un buco di tempo) a quando l'archivio funziona davvero.
3. **`PermissionExplainerCard` e `EmptyState` non sono opzionali**: sono i due schermi che l'utente vede *prima* di avere dati. Trascurarli = prima impressione pessima.
4. **Sparkline ≠ grafici full.** Nelle card servono micro-grafici, non `fl_chart` completo: più leggeri e più puliti.
