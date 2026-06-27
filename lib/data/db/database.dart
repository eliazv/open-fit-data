import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';

part 'database.g.dart';

/// Record grezzi importati da Health Connect / HealthKit.
/// `hashDedup` è unique → l'insert con `InsertMode.insertOrIgnore` scarta
/// automaticamente i duplicati identici.
@DataClassName('HealthRawRecord')
class HealthRawRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourcePlatform => text()();
  TextColumn get sourceApp => text().nullable()();
  TextColumn get type => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  RealColumn get value => real()();
  TextColumn get unit => text()();
  TextColumn get metadataJson => text().nullable()();
  TextColumn get hashDedup => text().unique()();
  DateTimeColumn get importedAt => dateTime()();
}

/// Aggregati giornalieri derivati dai record grezzi.
/// `date` in formato `yyyy-MM-dd` (chiave primaria).
@DataClassName('DailySummary')
class DailySummaries extends Table {
  TextColumn get date => text()();
  IntColumn get steps => integer().nullable()();
  RealColumn get distanceM => real().nullable()();
  RealColumn get activeCalories => real().nullable()();
  IntColumn get sleepMinutes => integer().nullable()();
  RealColumn get restingHr => real().nullable()();
  RealColumn get avgHr => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get vo2max => real().nullable()();
  RealColumn get hrvMs => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
}

/// Allenamenti importati (definita ora, popolata da Fase 1/4).
@DataClassName('Workout')
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workoutType => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  IntColumn get durationSec => integer().nullable()();
  RealColumn get distanceM => real().nullable()();
  IntColumn get avgPaceSecKm => integer().nullable()();
  RealColumn get avgHr => real().nullable()();
  RealColumn get maxHr => real().nullable()();
  RealColumn get avgSpeed => real().nullable()();
  TextColumn get sourceApp => text().nullable()();
  TextColumn get rawJson => text().nullable()();
  TextColumn get hashDedup => text().unique()();
  DateTimeColumn get importedAt => dateTime()();
}

/// Key-value store locale (ultimo sync, contatori, preferenze leggere).
@DataClassName('SyncLog')
class SyncLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get trigger => text()();
  TextColumn get status => text()();
  IntColumn get rawRecords => integer().withDefault(const Constant(0))();
  IntColumn get workouts => integer().withDefault(const Constant(0))();
  IntColumn get insertedRaw => integer().withDefault(const Constant(0))();
  IntColumn get insertedWorkouts => integer().withDefault(const Constant(0))();
  TextColumn get message => text().nullable()();
}

class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Note manuali giornaliere: i dati automatici non spiegano tutto (dolore,
/// stanchezza, stress). Una nota per giorno, alimenta i briefing AI.
@DataClassName('UserNote')
class UserNotes extends Table {
  TextColumn get date => text()(); // yyyy-MM-dd
  IntColumn get energyLevel => integer().nullable()(); // 1..5
  IntColumn get fatigueLevel => integer().nullable()(); // 1..5
  TextColumn get painNotes => text().nullable()();
  TextColumn get freeNote => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
}

@DriftDatabase(
  tables: [
    HealthRawRecords,
    DailySummaries,
    Workouts,
    SyncLogs,
    AppMeta,
    UserNotes,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  // Migrazioni versionate dal giorno 1 (vedi ANALISI_ROADMAP §4): lo schema
  // crescerà con le metriche avanzate di Fase 4.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(userNotes);
          }
          if (from < 3) {
            await m.addColumn(dailySummaries, dailySummaries.hrvMs);
            await m.createTable(syncLogs);
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, AppConstants.dbFileName));
    return NativeDatabase.createInBackground(file);
  });
}
