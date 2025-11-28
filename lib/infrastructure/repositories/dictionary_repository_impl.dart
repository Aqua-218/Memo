import 'package:drift/drift.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/dictionary_entry.dart' as domain;
import '../../domain/repositories/dictionary_repository.dart';
import '../database/database.dart' as db;

/// Implementation of DictionaryRepository using Drift database.
/// 
/// Spec: docs/design/data-model/entities.md - DictionaryEntry operations
/// Spec: FR-007 - Personal dictionary management
class DictionaryRepositoryImpl implements DictionaryRepository {
  DictionaryRepositoryImpl(this._database);

  final db.AppDatabase _database;

  @override
  Future<domain.DictionaryEntry> create(domain.DictionaryEntry entry) async {
    await _database.into(_database.dictionaryEntries).insert(
      db.DictionaryEntriesCompanion.insert(
        id: entry.id,
        keyword: entry.keyword,
        description: entry.description,
        category: entry.category.toStorageString(),
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        embedding: Value(entry.embedding),
      ),
    );
    return entry;
  }

  @override
  Future<domain.DictionaryEntry?> findById(String id) async {
    final query = _database.select(_database.dictionaryEntries)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntry(row) : null;
  }

  @override
  Future<domain.DictionaryEntry?> findByKeyword(String keyword) async {
    final query = _database.select(_database.dictionaryEntries)
      ..where((t) => t.keyword.equals(keyword));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntry(row) : null;
  }

  @override
  Future<List<domain.DictionaryEntry>> findAll() async {
    final query = _database.select(_database.dictionaryEntries)
      ..orderBy([(t) => OrderingTerm.asc(t.keyword)]);
    final rows = await query.get();
    return rows.map<domain.DictionaryEntry>(_mapToEntry).toList();
  }

  @override
  Future<List<domain.DictionaryEntry>> findByCategory(Category category) async {
    final query = _database.select(_database.dictionaryEntries)
      ..where((t) => t.category.equals(category.toStorageString()))
      ..orderBy([(t) => OrderingTerm.asc(t.keyword)]);
    final rows = await query.get();
    return rows.map<domain.DictionaryEntry>(_mapToEntry).toList();
  }

  @override
  Future<List<domain.DictionaryEntry>> search(String keyword) async {
    final query = _database.select(_database.dictionaryEntries)
      ..where((t) => t.keyword.contains(keyword) | t.description.contains(keyword))
      ..orderBy([(t) => OrderingTerm.asc(t.keyword)]);
    final rows = await query.get();
    return rows.map<domain.DictionaryEntry>(_mapToEntry).toList();
  }

  @override
  Future<domain.DictionaryEntry> update(domain.DictionaryEntry entry) async {
    await (_database.update(_database.dictionaryEntries)
      ..where((t) => t.id.equals(entry.id)))
      .write(
        db.DictionaryEntriesCompanion(
          keyword: Value(entry.keyword),
          description: Value(entry.description),
          category: Value(entry.category.toStorageString()),
          updatedAt: Value(entry.updatedAt),
          embedding: Value(entry.embedding),
        ),
      );
    return entry;
  }

  @override
  Future<void> delete(String id) async {
    await (_database.delete(_database.dictionaryEntries)
      ..where((t) => t.id.equals(id)))
      .go();
  }

  @override
  Future<List<domain.DictionaryEntry>> findWithEmbeddings() async {
    final query = _database.select(_database.dictionaryEntries)
      ..where((t) => t.embedding.isNotNull())
      ..orderBy([(t) => OrderingTerm.asc(t.keyword)]);
    final rows = await query.get();
    return rows.map<domain.DictionaryEntry>(_mapToEntry).toList();
  }

  @override
  Future<int> count() async {
    final query = _database.selectOnly(_database.dictionaryEntries)
      ..addColumns([_database.dictionaryEntries.id.count()]);
    final result = await query.getSingle();
    return result.read(_database.dictionaryEntries.id.count()) ?? 0;
  }

  domain.DictionaryEntry _mapToEntry(db.DictionaryEntry row) {
    return domain.DictionaryEntry(
      id: row.id,
      keyword: row.keyword,
      description: row.description,
      category: CategoryExtension.fromStorageString(row.category),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      embedding: row.embedding,
    );
  }
}
