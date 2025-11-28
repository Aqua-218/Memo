import 'package:drift/drift.dart';

import '../../domain/entities/similarity_result.dart' as domain;
import '../../domain/entities/target_type.dart';
import '../../domain/repositories/similarity_repository.dart';
import '../database/database.dart';

/// Implementation of SimilarityRepository using Drift database.
/// 
/// Spec: docs/design/data-model/entities.md - SimilarityResult operations
/// Spec: FR-003 - Similarity calculation and caching
class SimilarityRepositoryImpl implements SimilarityRepository {
  SimilarityRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<domain.SimilarityResult> create(domain.SimilarityResult result) async {
    await _database.into(_database.similarityResults).insert(
      SimilarityResultsCompanion.insert(
        id: result.id,
        sourceId: result.sourceId,
        targetId: result.targetId,
        targetType: result.targetType.toStorageString(),
        score: result.score,
        calculatedAt: result.calculatedAt,
      ),
    );
    return result;
  }

  @override
  Future<domain.SimilarityResult?> findById(String id) async {
    final query = _database.select(_database.similarityResults)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToResult(row) : null;
  }

  @override
  Future<List<domain.SimilarityResult>> findBySourceId(String sourceId) async {
    final query = _database.select(_database.similarityResults)
      ..where((t) => t.sourceId.equals(sourceId))
      ..orderBy([(t) => OrderingTerm.desc(t.score)]);
    final rows = await query.get();
    return rows.map(_mapToResult).toList();
  }

  @override
  Future<List<domain.SimilarityResult>> findBySourceIdAndType(
    String sourceId,
    TargetType targetType,
  ) async {
    final query = _database.select(_database.similarityResults)
      ..where((t) =>
          t.sourceId.equals(sourceId) &
          t.targetType.equals(targetType.toStorageString()))
      ..orderBy([(t) => OrderingTerm.desc(t.score)]);
    final rows = await query.get();
    return rows.map(_mapToResult).toList();
  }

  @override
  Future<List<domain.SimilarityResult>> findAboveThreshold(
    String sourceId,
    double threshold,
  ) async {
    final query = _database.select(_database.similarityResults)
      ..where((t) =>
          t.sourceId.equals(sourceId) &
          t.score.isBiggerOrEqualValue(threshold))
      ..orderBy([(t) => OrderingTerm.desc(t.score)]);
    final rows = await query.get();
    return rows.map(_mapToResult).toList();
  }

  @override
  Future<domain.SimilarityResult?> findByPair(String sourceId, String targetId) async {
    final query = _database.select(_database.similarityResults)
      ..where((t) =>
          t.sourceId.equals(sourceId) &
          t.targetId.equals(targetId));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToResult(row) : null;
  }

  @override
  Future<void> deleteBySourceId(String sourceId) async {
    await (_database.delete(_database.similarityResults)
      ..where((t) => t.sourceId.equals(sourceId)))
      .go();
  }

  @override
  Future<void> deleteByTargetId(String targetId) async {
    await (_database.delete(_database.similarityResults)
      ..where((t) => t.targetId.equals(targetId)))
      .go();
  }

  @override
  Future<void> deleteOlderThan(DateTime date) async {
    await (_database.delete(_database.similarityResults)
      ..where((t) => t.calculatedAt.isSmallerThanValue(date)))
      .go();
  }

  @override
  Future<void> deleteAll() async {
    await _database.delete(_database.similarityResults).go();
  }

  @override
  Future<int> count() async {
    final query = _database.selectOnly(_database.similarityResults)
      ..addColumns([_database.similarityResults.id.count()]);
    final result = await query.getSingle();
    return result.read(_database.similarityResults.id.count()) ?? 0;
  }

  domain.SimilarityResult _mapToResult(SimilarityResult row) {
    return domain.SimilarityResult(
      id: row.id,
      sourceId: row.sourceId,
      targetId: row.targetId,
      targetType: TargetTypeExtension.fromStorageString(row.targetType),
      score: row.score,
      calculatedAt: row.calculatedAt,
    );
  }
}
