# Setup Android — Health Connect

Configurazione nativa necessaria dopo `flutter create . --platforms=android`.
Il package `health` (v11) ha requisiti specifici su Android.

## 1. `minSdkVersion` e `compileSdk`

In `android/app/build.gradle` (o `build.gradle.kts`):

```gradle
android {
    compileSdk 34
    defaultConfig {
        minSdk 26          // Health Connect richiede almeno API 26
        targetSdk 34
    }
}
```

## 2. `MainActivity` deve estendere `FlutterFragmentActivity`

Il package `health` usa il contratto permessi di Health Connect, che richiede
una `FragmentActivity`. In
`android/app/src/main/kotlin/.../MainActivity.kt`:

```kotlin
package com.eliazavatta.open_fit_data

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

## 3. `AndroidManifest.xml`

In `android/app/src/main/AndroidManifest.xml`.

### Permessi salute (solo quelli letti dalla v1)

Subito sotto il tag `<manifest>`:

```xml
<uses-permission android:name="android.permission.health.READ_STEPS" />
<uses-permission android:name="android.permission.health.READ_DISTANCE" />
<uses-permission android:name="android.permission.health.READ_ACTIVE_CALORIES_BURNED" />
<uses-permission android:name="android.permission.health.READ_HEART_RATE" />
<uses-permission android:name="android.permission.health.READ_RESTING_HEART_RATE" />
<uses-permission android:name="android.permission.health.READ_SLEEP" />
<uses-permission android:name="android.permission.health.READ_WEIGHT" />
<uses-permission android:name="android.permission.health.READ_EXERCISE" />
```

> Aggiungere nuovi permessi SOLO quando si attiva la metrica relativa
> (permessi just-in-time → review Play Store più semplice).

### Visibilità del pacchetto Health Connect

Dentro `<manifest>`, a livello root:

```xml
<queries>
    <package android:name="com.google.android.apps.healthdata" />
    <intent>
        <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
    </intent>
</queries>
```

### Rationale dei permessi (richiesto da Health Connect)

Dentro `<application>`, accanto a `MainActivity`:

```xml
<!-- Android 14+ -->
<activity-alias
    android:name="ViewPermissionUsageActivity"
    android:exported="true"
    android:targetActivity=".MainActivity"
    android:permission="android.permission.START_VIEW_PERMISSION_USAGE">
    <intent-filter>
        <action android:name="android.intent.action.VIEW_PERMISSION_USAGE" />
        <category android:name="android.intent.category.HEALTH_PERMISSIONS" />
    </intent-filter>
</activity-alias>

<!-- Android 13 e precedenti -->
<activity
    android:name=".MainActivity"
    ...>
    <intent-filter>
        <action android:name="androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE" />
    </intent-filter>
</activity>
```

## 4. Storico oltre 30 giorni (opzionale, fase successiva)

Health Connect conserva di default ~30 giorni. Per leggere oltre serve il
permesso storico:

```xml
<uses-permission android:name="android.permission.health.READ_HEALTH_DATA_HISTORY" />
```

…e la chiamata `Health().requestHealthDataHistoryAuthorization()` prima di
leggere intervalli più ampi. La v1 resta dentro i 30 giorni (vedi
ANALISI_ROADMAP §5).

## 5. workmanager (auto-sync)

Il plugin `workmanager` non richiede configurazione manuale aggiuntiva oltre
all'inizializzazione già presente in `main.dart`. Su alcuni OEM con
restrizioni batteria aggressive il task periodico può essere rimandato: è
atteso e gestito (best-effort).

## 6. Privacy policy (richiesta per la pubblicazione)

Le app che leggono Health Connect rientrano nella **Health Apps policy** di
Google Play: serve un URL di privacy policy pubblico e la dichiarazione d'uso
dei dati nel Play Console prima della submission. Vedi ANALISI_ROADMAP §3.2.
