import 'target_type.dart';

/// Similarity result entity for duplicate detection.
/// 
/// Spec: docs/design/data-model/entities.md - SimilarityResult
class SimilarityResult {
  /// Creates a new SimilarityResult instance.
  const SimilarityResult({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.targetType,
    required this.score,
    required this.calculatedAt,
  }) : assert(score >= 0.0 && score <= 1.0, 'Score must be between 0.0 and 1.0');

  /// Unique identifier (UUID v4)
  final String id;

  /// Source memo ID
  final String sourceId;

  /// Target memo or dictionary entry ID
  final String targetId;

  /// Type of the target (memo or dictionary)
  final TargetType targetType;

  /// Similarity score (0.0 - 1.0)
  /// 0.0 = completely different
  /// 1.0 = identical
  final double score;

  /// Calculation timestamp (UTC)
  final DateTime calculatedAt;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimilarityResult && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
