import 'package:drift/drift.dart';

import '../../domain/entities/memo.dart' as domain;
import '../../domain/repositories/memo_repository.dart';
import '../database/database.dart';

/// Implementation of MemoRepository using Drift database.
/// 
/// Spec: docs/design/data-model/entities.md - Memo operations
class MemoRepositoryImpl implements MemoRepository {
  MemoRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<domain.Memo> create(domain.Memo memo) async {
    await _database.into(_database.memos).insert(
      MemosCompanion.insert(
        id: memo.id,
        content: memo.content,
        createdAt: memo.createdAt,
        updatedAt: memo.updatedAt,
        embedding: Value(memo.embedding),
        isAnalyzed: Value(memo.isAnalyzed),
      ),
    );
    return memo;
  }

  @override
  Future<domain.Memo?> findById(String id) async {
    final query = _database.select(_database.memos)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToMemo(row) : null;
  }

  @override
  Future<List<domain.Memo>> findAll() async {
    final query = _database.select(_database.memos)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_mapToMemo).toList();
  }

  @override
  Future<List<domain.Memo>> findRecent(int count) async {
    final query = _database.select(_database.memos)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(count);
    final rows = await query.get();
    return rows.map(_mapToMemo).toList();
  }

  @override
  Future<List<domain.Memo>> search(String keyword) async {
    final query = _database.select(_database.memos)
      ..where((t) => t.content.contains(keyword))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_mapToMemo).toList();
  }

  @override
  Future<domain.Memo> update(domain.Memo memo) async {
    await (_database.update(_database.memos)
      ..where((t) => t.id.equals(memo.id)))
      .write(
        MemosCompanion(
          content: Value(memo.content),
          updatedAt: Value(memo.updatedAt),
          embedding: Value(memo.embedding),
          isAnalyzed: Value(memo.isAnalyzed),
        ),
      );
    return memo;
  }

  @override
  Future<void> delete(String id) async {
    await (_database.delete(_database.memos)
      ..where((t) => t.id.equals(id)))
      .go();
  }

  @override
  Future<List<domain.Memo>> findUnanalyzed() async {
    final query = _database.select(_database.memos)
      ..where((t) => t.isAnalyzed.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_mapToMemo).toList();
  }

  @override
  Future<List<domain.Memo>> findWithEmbeddings() async {
    final query = _database.select(_database.memos)
      ..where((t) => t.embedding.isNotNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    final rows = await query.get();
    return rows.map(_mapToMemo).toList();
  }

  @override
  Future<int> count() async {
    final query = _database.selectOnly(_database.memos)
      ..addColumns([_database.memos.id.count()]);
    final result = await query.getSingle();
    return result.read(_database.memos.id.count()) ?? 0;
  }

  domain.Memo _mapToMemo(Memo row) {
    return domain.Memo(
      id: row.id,
      content: row.content,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      embedding: row.embedding,
      isAnalyzed: row.isAnalyzed,
    );
  }
}
