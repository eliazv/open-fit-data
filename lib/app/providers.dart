import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/repositories/archive_repository.dart';
import '../services/ai_briefing_service.dart';
import '../services/background_sync.dart';
import '../services/export_service.dart';
import '../services/health_sync_service.dart';
import '../services/sync_service.dart';

/// Database locale (chiuso quando il provider viene smaltito).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final archiveRepositoryProvider = Provider<ArchiveRepository>((ref) {
  return ArchiveRepository(ref.watch(appDatabaseProvider));
});

final healthSyncServiceProvider = Provider<HealthSyncService>((ref) {
  return HealthSyncService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(healthSyncServiceProvider),
    ref.watch(archiveRepositoryProvider),
  );
});

final aiBriefingServiceProvider = Provider<AiBriefingService>((ref) {
  return const AiBriefingService();
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return const ExportService();
});

final backgroundSyncManagerProvider = Provider<BackgroundSyncManager>((ref) {
  return const BackgroundSyncManager();
});
