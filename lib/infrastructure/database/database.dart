import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Memos table definition.
/// 
/// Spec: docs/design/data-model/entities.md - Memo
class Memos extends Table {
  TextColumn get id => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get embedding => text().nullable()();
  BoolColumn get isAnalyzed => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Dictionary entries table definition.
/// 
/// Spec: docs/design/data-model/entities.md - DictionaryEntry
class DictionaryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get keyword => text().unique()();
  TextColumn get description => text()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get embedding => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Similarity results table definition.
/// 
/// Spec: docs/design/data-model/entities.md - SimilarityResult
class SimilarityResults extends Table {
  TextColumn get id => text()();
  TextColumn get sourceId => text()();
  TextColumn get targetId => text()();
  TextColumn get targetType => text()();
  RealColumn get score => real()();
  DateTimeColumn get calculatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Application database using Drift.
/// 
/// Spec: ADR-003 - Changed from Isar to Drift due to dependency conflicts
@DriftDatabase(tables: [Memos, DictionaryEntries, SimilarityResults])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.e);

  static AppDatabase? _instance;

  /// Returns the singleton database instance.
  static Future<AppDatabase> getInstance() async {
    if (_instance != null) return _instance!;
    
    final dir = await getApplicationDocumentsDirectory();
    final executor = driftDatabase(
      name: 'personal_reminder',
      native: DriftNativeOptions(
        databaseDirectory: () async => dir,
      ),
    );
    _instance = AppDatabase._internal(executor);
    return _instance!;
  }

  /// Creates an in-memory database for testing.
  factory AppDatabase.forTesting(QueryExecutor executor) {
    return AppDatabase._internal(executor);
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }
}
