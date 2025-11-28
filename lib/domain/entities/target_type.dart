/// Target type for similarity results.
/// 
/// Spec: docs/design/data-model/entities.md - SimilarityResult.TargetType
enum TargetType {
  /// Target is a memo
  memo,

  /// Target is a dictionary entry
  dictionary,
}

/// Extension for TargetType enum.
extension TargetTypeExtension on TargetType {
  /// Converts target type to storage string.
  String toStorageString() {
    switch (this) {
      case TargetType.memo:
        return 'memo';
      case TargetType.dictionary:
        return 'dictionary';
    }
  }

  /// Converts storage string to target type.
  static TargetType fromStorageString(String value) {
    switch (value) {
      case 'memo':
        return TargetType.memo;
      case 'dictionary':
      default:
        return TargetType.dictionary;
    }
  }
}
