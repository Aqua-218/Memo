import '../entities/similarity_result.dart';
import '../entities/target_type.dart';

/// Repository interface for SimilarityResult operations.
/// 
/// Spec: docs/design/architecture.md - Domain Layer - Repositories
abstract class SimilarityRepository {
  /// Creates a new similarity result.
  /// 
  /// Returns the created result.
  Future<SimilarityResult> create(SimilarityResult result);

  /// Retrieves a similarity result by its ID.
  /// 
  /// Returns null if not found.
  Future<SimilarityResult?> findById(String id);

  /// Retrieves similarity results for a source memo.
  Future<List<SimilarityResult>> findBySourceId(String sourceId);

  /// Retrieves similarity results by source and target type.
  Future<List<SimilarityResult>> findBySourceIdAndType(
    String sourceId,
    TargetType targetType,
  );

  /// Retrieves similarity results above a threshold.
  Future<List<SimilarityResult>> findAboveThreshold(
    String sourceId,
    double threshold,
  );

  /// Finds a similarity result by source and target pair.
  Future<SimilarityResult?> findByPair(String sourceId, String targetId);

  /// Deletes all similarity results for a source memo.
  Future<void> deleteBySourceId(String sourceId);

  /// Deletes all similarity results for a target.
  Future<void> deleteByTargetId(String targetId);

  /// Deletes similarity results older than a date.
  Future<void> deleteOlderThan(DateTime date);

  /// Deletes all similarity results.
  Future<void> deleteAll();

  /// Returns the total count of similarity results.
  Future<int> count();
}
