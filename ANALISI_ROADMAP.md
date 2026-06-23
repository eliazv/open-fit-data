# Analisi della Roadmap — Open Fit Data

> Documento di considerazioni tecniche e di prodotto sulla `ROADMAP.md`.
> Focus: come realizzare l'obiettivo dell'app con **Flutter Android-first**, poi **iOS**.
> Aggiornato: 23 giugno 2026

---

## 1. Giudizio sintetico

La roadmap è **molto buona**. È rara da trovare in un progetto early-stage perché parte dal *problema* e non dalla *tecnologia*, e soprattutto definisce con chiarezza cosa l'app **non** deve essere. Questo è il 70% del lavoro di prodotto fatto bene.

I tre punti più forti:

1. **Scope chirurgico.** "Archivio. Export. AI-ready." è un posizionamento difendibile e non sovrapposto a Strava/Garmin. La sezione "No" e "Cose da evitare" valgono oro: la maggior parte dei progetti muore per *feature creep*, non per mancanza di feature.
2. **Local-first + no account.** È coerente con il valore promesso (privacy/portabilità) ed elimina nella v1 tutta la complessità di backend, auth, sync, GDPR su server. Enorme risparmio di tempo.
3. **AI-ready, non AI-locked.** La scelta di generare *testo/prompt da copiare* invece di integrare un'API a pagamento è la decisione tecnica più intelligente del documento: zero costi ricorrenti, zero gestione chiavi, zero lock-in, e funziona con qualsiasi modello.

Il mio contributo qui sotto non riscrive la roadmap: la **stress-testa**, segnala i punti dove rischia di rompersi nella realtà, e propone un ordine di esecuzione.

---

## 2. Cosa funziona bene (e va protetto)

| Scelta | Perché è giusta |
|---|---|
| **Flutter + package `health`** | Una sola codebase per Android+iOS, e `health` astrae già Health Connect e HealthKit. Evita di scrivere bridge nativi Kotlin/Swift nella v1. |
| **Drift + SQLite** | Type-safe, reattivo (stream → UI), migrazioni gestite. Perfetto per un archivio locale che crescerà di schema nel tempo. |
| **Tabella raw + tabelle aggregate** | Pattern corretto: conservi il grezzo (verità) e derivi gli aggregati (velocità UI). Se sbagli un'aggregazione, ricalcoli senza riperdere i dati. |
| **`metadata_json` / `raw_json`** | Salva ciò che non sai ancora normalizzare. Evita perdita di dati e migrazioni dolorose. Ottima mossa difensiva. |
| **Sync manuale nella v1** | Niente background workers, niente battaglie con Doze/battery optimization. Si parte semplici e si misura. |
| **`hash_dedup`** | La deduplica è IL problema vero dei dati salute multi-sorgente. Averla nello schema dal giorno zero è lungimirante. |
| **`user_notes`** | I dati automatici non spiegano il "perché". Le note manuali (dolore, fatica, stress) sono ciò che rende un briefing AI davvero utile. Spesso dimenticate: qui ci sono. |

---

## 3. I punti dove la roadmap rischia di rompersi nella realtà

Questi sono i rischi concreti emersi dalla mia esperienza con Health Connect e con il package `health`. Non sono critiche: sono i punti dove vorrei essere stato avvisato prima.

### 3.1 Health Connect è più ostico di quanto sembri ⚠️ (rischio alto)

- **Non è preinstallato ovunque.** Su Android < 14 è un'app separata dal Play Store; su Android 14+ è di sistema ma va comunque abilitata. L'onboarding deve gestire "Health Connect non installato / non disponibile / disabilitato" come **primo cittadino**, non come edge case.
- **Lo storico è limitato e per-permesso.** Health Connect conserva di default **30 giorni** di dati, e l'accesso allo storico oltre i 30 giorni richiede il permesso speciale `PERMISSION_READ_HEALTH_DATA_HISTORY`. Questo impatta direttamente i range "ultimo anno / tutto lo storico" dell'export: **non puoi promettere dati che la piattaforma non ti dà.** Va comunicato nell'UI, non scoperto dall'utente.
- **Sync periodico ≠ opzionale, è la sostanza del prodotto.** Se Health Connect tiene 30 giorni e l'utente sincronizza ogni 40, *perde dati per sempre*. Questo trasforma il "sync manuale" da feature comoda a **rischio per la promessa core** ("non perdere storico"). → Vedi §5.

### 3.2 Permessi e review del Play Store ⚠️ (rischio alto)

Le app che leggono Health Connect rientrano nella **Health Apps policy** di Google. Servono:
- una **privacy policy pubblica** (URL raggiungibile) già alla prima submission;
- una **dichiarazione d'uso dei dati health** nel Play Console;
- giustificazione di *ogni* tipo di permesso richiesto.

Implicazione pratica: la Domanda Aperta #4 ("quali tipi di dato chiedere all'inizio") **non è secondaria, è bloccante per la pubblicazione**. La risposta giusta è *pochi tipi, ben giustificati* (passi, distanza, workout). HRV/VO2max/sonno aumentano l'attrito di review → tenerli in Fase 4 è corretto, ma il codice deve chiedere i permessi **incrementalmente**, solo quando la feature serve.

### 3.3 Il package `health` ha asimmetrie tra piattaforme ⚠️ (rischio medio)

- I tipi di dato e le unità **non sono 1:1** tra Health Connect e HealthKit. Esempio classico: sonno (stadi vs sessioni), distanza (per-workout vs aggregata), pace/speed (a volte derivati). Il `health_sync_service` avrà inevitabilmente rami `if (Platform.isAndroid)`.
- Alcuni tipi richiamati in roadmap (cadenza, elevation gain, alcune metriche corsa) **possono non essere esposti** dal package o variare per versione. Vanno trattati come *best-effort*: se ci sono li prendo, altrimenti `null`. Lo schema già lo permette (campi nullable) — bene.
- **Conseguenza di design:** introdurre presto un layer di **normalizzazione** (un `CanonicalRecord` interno disaccoppiato dai tipi del package) ripaga moltissimo quando arriva iOS in Fase 6. È l'unico pezzo di architettura che aggiungerei *prima* di quanto suggerito.

### 3.4 La deduplica è più dura di un hash ⚠️ (rischio medio)

`hash_dedup` cattura i duplicati *identici*, ma il problema reale dei dati salute è la **sovrapposizione**: il telefono conta 6.000 passi, lo smartwatch ne conta 6.300 per lo stesso intervallo. Sommarli = dato gonfiato del doppio. Health Connect ha un concetto di *priorità delle sorgenti*, ma il package `health` lo espone in modo limitato.
→ Nella v1 va bene un hash su `(type, start, end, source_app, value)`. Ma va messo a budget che la **vera** deduplica per-sorgente (Fase 5) è un progetto a sé, non un rifinitura. Non sottostimarla.

### 3.5 "Briefing sintetico" è un mini-problema di prodotto, non una formattazione

Il briefing è la feature centrale (lo dice la roadmap). Il rischio è generare un muro di numeri. Le decisioni difficili sono:
- **Cosa omettere** quando un dato manca (non scrivere "sonno: null").
- **Quanto compattare** (un mese di dati grezzi sfora la finestra di contesto e annacqua il prompt → servono aggregati, non righe giornaliere).
- **Quale obiettivo utente** iniettare nel prompt (corsa? recupero? peso?).
Questo significa che `AIBriefingService` merita test con dati reali sin da subito. È il pezzo che *vende* l'app: va trattato come tale.

---

## 4. Cosa NON fare / evitare (oltre alla lista già presente)

La roadmap ha già un'ottima sezione "Cose da evitare". Aggiungo i passi falsi tecnici tipici di questo tipo di app:

1. **Non costruire una dashboard con grafici nella v1.** È un buco nero di tempo e *non* è il valore promesso. Numeri in card bastano. I grafici (`fl_chart`) sono Fase 4+.
2. **Non sommare ciecamente i dati multi-sorgente.** Vedi §3.4. Meglio mostrare "potenziale duplicato" che dare un totale sbagliato — un archivio che mente perde tutta la sua credibilità.
3. **Non promettere "tutto lo storico" finché non gestisci il permesso storico + sync periodico.** È una promessa che la piattaforma può smentire. Comunica il limite.
4. **Non chiedere tutti i permessi all'avvio.** Oltre al fastidio utente, è un red flag per la review. Permessi *just-in-time*, per feature.
5. **Non legare l'AI briefing a un SDK/API a pagamento "tanto per".** Distruggerebbe il posizionamento. La condivisione via testo/clipboard/share-sheet è già la scelta giusta — tenerla.
6. **Non rendere Drift/SQLite "puro raw" senza versioning delle migrazioni dal giorno 1.** Lo schema cambierà (Fase 4 aggiunge metriche). Migrazioni Drift impostate subito = nessun dolore dopo.
7. **Non introdurre Riverpod + Drift + GoRouter + freezed + ecc. tutti insieme prima di avere un flusso che funziona.** Partire minimale, aggiungere quando serve. Over-engineering early = morte lenta.
8. **Non scrivere codice copiato da `healthexport`/`HealthConnectExports` senza verificarne la licenza.** La roadmap lo nota già: usarli come *idee*, non come *sorgente*.

---

## 5. La mia modifica più importante: ripensare il "sync manuale"

È l'unico punto dove diverge in modo sostanziale dalla roadmap, ed è motivato dal rischio §3.1.

**Problema:** la promessa "non perdere storico" è incompatibile con un sync solo-manuale + storico Health Connect di 30 giorni. Se l'utente dimentica di sincronizzare, il dato evapora.

**Proposta (cambia poco al lavoro v1, salva la promessa core):**
- v1: **sync manuale** come previsto, MA con un **promemoria/avviso** se l'ultimo sync è > N giorni ("Sincronizza per non perdere dati: Health Connect conserva ~30 giorni").
- Subito dopo (non Fase 7): un **sync periodico best-effort** con `workmanager` (1×/giorno è sufficiente, niente real-time). Non serve background continuo, serve solo non superare la finestra dei 30 giorni.

Questo è ciò che trasforma "ennesima app di export" in "la cassaforte che davvero non perde i tuoi dati".

---

## 6. Come ordinerei l'esecuzione (Walking Skeleton)

Concordo con la "Prima milestone concreta" della roadmap. La declino in un percorso end-to-end *sottilissimo* — un'unica colonna verticale che attraversa tutta l'app — prima di allargare. Meglio un flusso completo e brutto che cinque feature belle e scollegate.

**Milestone 0 — Lo scheletro che cammina (1 sola metrica, end-to-end):**
1. App Flutter + Drift + 1 schermata.
2. Permessi Health Connect (con gestione "non disponibile").
3. Leggo **solo i passi** ultimi 30 giorni.
4. Salvo in `health_raw_records` + `daily_summaries` con dedup.
5. Mostro "ultimo sync + passi medi 7gg" in una card.
6. Genero un **Markdown** dei passi e lo passo allo **share sheet**.

Quando *questo* funziona con i tuoi dati reali, hai dimostrato l'intera tesi del prodotto (leggo → archivio → export → AI) su una metrica. Poi è solo **moltiplicazione**: aggiungere distanza, workout, sonno, peso è ripetere lo stesso pattern già validato.

**Da lì in poi, l'ordine della roadmap è corretto:** export multi-formato → briefing AI con template → metriche avanzate → deduplica seria → iOS.

> Nota su iOS (Fase 6): se il layer `CanonicalRecord` (§3.3) viene introdotto in Milestone 0, l'aggiunta di HealthKit diventa "scrivo un secondo `HealthSource` che produce gli stessi `CanonicalRecord`". Senza quel layer, iOS diventa un refactor doloroso. Questo è l'unico investimento architetturale che anticiperei.

---

## 7. Risposte concrete alle "Domande aperte" della roadmap

| # | Domanda | Mia raccomandazione |
|---|---|---|
| 1 | Licenza | **AGPL-3.0.** Il valore è fiducia/privacy: AGPL impedisce a terzi di trasformarlo in un servizio cloud chiuso senza restituire il codice. Coerente con il manifesto. Se l'obiettivo fosse massima adozione/libreria, MIT — ma qui l'anima è "i dati sono tuoi". |
| 2 | Open source da subito | **Sì.** Il tema è fiducia; il codice aperto *è* parte del prodotto. Repo pubblico dal primo commit. |
| 3 | Cifratura locale in v1 | **No, ma documentare il rischio.** SQLCipher rallenta lo sviluppo e aggiunge complessità (gestione chiave). I dati sono già protetti dalla sandbox dell'app + crittografia del dispositivo. Cifratura DB → Fase 7, quando si tocca il backup. |
| 4 | Quali dati all'inizio | **Pochi e giustificati: passi, distanza, workout.** È anche un requisito di review (§3.2). Il resto incrementale, per feature. |
| 5 | Analytics | **No nella v1.** Contraddirebbe il posizionamento privacy. Se mai servirà, opt-in esplicito + locale/anonimo (es. niente SDK terzi). |
| 6 | Dati sensibili / responsabilità | **Disclaimer chiaro + linguaggio "fitness/benessere", mai medico.** Nei prompt AI, includere un framing tipo "non sono consigli medici". Evitare qualunque output che somigli a diagnosi. |

---

## 8. Stack: cosa confermo e cosa preciserei

Confermo lo stack della roadmap. Preciserei solo le versioni/scelte operative:

- **State management:** Riverpod va benissimo. Tenerlo minimale (provider semplici). Non serve Bloc per un'app di questa natura.
- **Routing:** per poche schermate, anche solo `Navigator`; `go_router` solo se il flusso cresce.
- **DB:** Drift + `sqlite3_flutter_libs`. **Migrazioni versionate dal giorno 1.**
- **Health:** package `health` come connettore unico. Aggiungere un **adapter interno** (`CanonicalRecord`) per disaccoppiare l'app dai suoi tipi (§3.3).
- **Export:** `share_plus`, `path_provider`, `csv`, `archive` — come da roadmap, corretto.
- **Background (post-v1):** `workmanager` per il sync periodico best-effort (§5).
- **Niente backend in v1** — pienamente d'accordo.

---

## 9. Conclusione

La roadmap **non va riscritta, va eseguita** — ed è già abbastanza matura per farlo. I miei tre suggerimenti operativi, in ordine di importanza:

1. **Tratta lo storico di 30 giorni di Health Connect come un vincolo di prodotto, non un dettaglio** → aggiungi promemoria sync in v1 e sync periodico subito dopo (§5). È ciò che mantiene la promessa core.
2. **Introduci il layer `CanonicalRecord` nella Milestone 0** → rende iOS (Fase 6) un'aggiunta e non un refactor (§3.3).
3. **Costruisci uno scheletro end-to-end su una sola metrica prima di allargare** (§6) → valida l'intera tesi del prodotto in pochi giorni, poi moltiplica.

Tutto il resto del documento — posizionamento, principi, data model, sezioni "No"/"Da evitare" — è solido e va **difeso dalla tentazione di aggiungere feature**. La disciplina sullo scope è qui il vero vantaggio competitivo.

> Archivio. Export. AI-ready. Tre parole. Tutto ciò che non le serve, è rumore.
