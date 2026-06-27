import 'dart:io' show Platform;

import 'package:workmanager/workmanager.dart';

import '../data/db/database.dart';
import '../data/repositories/archive_repository.dart';
import 'health_sync_service.dart';
import 'sync_service.dart';

/// Nomi dei task background.
class BackgroundTasks {
  static const String periodicSync = 'open_fit_data.periodic_sync';
  static const String uniqueName = 'open_fit_data.periodic_sync.unique';
}

/// Entry-point isolato eseguito da workmanager (deve essere top-level).
/// Gira in un isolate separato: ricrea le proprie dipendenze, niente UI.
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != BackgroundTasks.periodicSync) return true;

    final db = AppDatabase();
    try {
      final repo = ArchiveRepository(db);
      final sync = SyncService(HealthSyncService(), repo);
      // Non interattivo: se i permessi non ci sono, fallisce in silenzio.
      await sync.sync(interactive: false, trigger: 'background');
      return true;
    } catch (_) {
      // Riproveremo al prossimo ciclo; non bloccare lo scheduler.
      return true;
    } finally {
      await db.close();
    }
  });
}

/// Configura auto-sync periodico (~1×/giorno). Best-effort: il sistema può
/// rimandare per Doze/batteria, ma resta dentro la finestra dei 30 giorni di
/// Health Connect (vedi ANALISI_ROADMAP §5).
///
/// Periodico solo su Android: su iOS il background è molto più limitato
/// (BGTaskScheduler) e ci affidiamo al sync all'avvio. Vedi docs/IOS_SETUP.md.
class BackgroundSyncManager {
  const BackgroundSyncManager();

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    await Workmanager().initialize(
      backgroundCallbackDispatcher,
      isInDebugMode: false,
    );
  }

  Future<void> enablePeriodicSync() async {
    if (!Platform.isAndroid) return;
    await Workmanager().registerPeriodicTask(
      BackgroundTasks.uniqueName,
      BackgroundTasks.periodicSync,
      frequency: const Duration(hours: 12),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.notRequired),
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 30),
    );
  }

  Future<void> disablePeriodicSync() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelByUniqueName(BackgroundTasks.uniqueName);
  }
}
