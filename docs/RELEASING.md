# Come pubblicare una nuova release

La CI (`.github/workflows/release.yml`) builda e pubblica da sola l'APK
firmato quando viene pushato un tag `vX.Y.Z`. Non serve buildare a mano.

## Procedura

1. Aggiorna la versione in `pubspec.yaml` (campo `version:`), commit.
2. Crea il tag e pushalo:

   ```bash
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

3. La CI parte automaticamente: build APK release, firma con il keystore
   (secret GitHub, vedi sotto), crea la GitHub Release con l'APK come asset.
   Segui l'avanzamento in **Actions** sul repo.
4. Chi usa [Obtainium](https://github.com/ImranR98/Obtainium) riceve
   l'aggiornamento in automatico (rileva le nuove release GitHub).

## Versionamento

`vMAJOR.MINOR.PATCH` (semver). Il numero di build Android
(`pubspec.yaml` → `version: X.Y.Z+N`) va incrementato ad ogni release
(`+N`), anche a parità di X.Y.Z, perché Android non reinstalla un APK con
lo stesso `versionCode`.

## Keystore di firma — dove sta, come si rigenera

Il keystore (`android/upload-keystore.jks`) e le sue password
(`android/key.properties`) **non sono nel repo** (sono in `.gitignore`).
Vivono come secret GitHub Actions sul repo:

- `ANDROID_KEYSTORE_BASE64` — il file `.jks` codificato in base64
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

La CI li decodifica a runtime, builda, e li scarta a fine job (nessuna
persistenza). Sono visibili/modificabili solo da **Settings → Secrets and
variables → Actions** sul repo, mai in chiaro nei log.

**Importante**: il file `.jks` originale e `key.properties` esistono *solo*
in locale su questo PC più nei secret GitHub. Se li perdi entrambi, non
puoi più pubblicare update che si installino sopra le versioni esistenti
(Android richiede la stessa firma per ogni update) — gli utenti dovrebbero
disinstallare e reinstallare da zero. **Fanne un backup** (es. allegato in
un password manager) fuori da questo PC.

## Build locale manuale (se serve, senza CI)

```bash
flutter build apk --release
```

Richiede `android/key.properties` + `android/upload-keystore.jks` presenti
in locale (vedi sopra). Senza, ricade sulla firma debug (non installabile
come update sopra una versione già firmata in release).
