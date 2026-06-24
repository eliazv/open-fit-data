# Setup iOS — Apple HealthKit

Grazie al layer `CanonicalRecord`, iOS riusa tutta la logica di archivio,
dedup, summary, export e briefing: cambia solo la sorgente (HealthKit via il
package `health`). Configurazione nativa necessaria dopo aver generato la
cartella `ios/`.

## 1. Genera lo shell iOS

```bash
flutter create . --org com.eliazavatta --project-name open_fit_data --platforms=android,ios
```

## 2. Abilita la capability HealthKit

In Xcode: apri `ios/Runner.xcworkspace` → target **Runner** →
**Signing & Capabilities** → **+ Capability** → **HealthKit**.
Questo aggiunge l'entitlement `com.apple.developer.healthkit`.

## 3. `Info.plist`

In `ios/Runner/Info.plist` aggiungi le descrizioni d'uso (obbligatorie, senza
l'app crasha alla richiesta permessi):

```xml
<key>NSHealthShareUsageDescription</key>
<string>Open Fit Data legge i tuoi dati di salute per archiviarli in locale ed esportarli.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Open Fit Data non modifica i tuoi dati di salute.</string>
```

## 4. Deployment target

In `ios/Podfile` assicurati `platform :ios, '12.0'` (o superiore: il package
`health` richiede iOS 12+).

## 5. Permessi

La richiesta avviene a runtime via `Health().requestAuthorization(...)`, già
gestita dall'app nell'onboarding. iOS mostra il foglio nativo HealthKit con i
tipi richiesti (passi, distanza, calorie, battito, sonno, peso, allenamenti).

## 6. Auto-sync su iOS

Il background su iOS è molto più limitato che su Android: niente
`workmanager` periodico affidabile. L'app si affida al **sync all'avvio**
(non interattivo) ogni volta che viene aperta. Una futura integrazione con
`BGTaskScheduler` / HealthKit background delivery è possibile ma non
prioritaria per la v1.

## Note

- HealthKit non è disponibile su iPad senza app Salute: gestire il caso
  "non disponibile" come su Android.
- I tipi/units possono differire da Health Connect (es. sonno come sessioni):
  il mapping in `health_sync_service.dart` è il punto unico dove affinare.
