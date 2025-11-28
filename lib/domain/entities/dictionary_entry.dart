import 'category.dart';

/// Dictionary entry entity for personal keywords.
/// 
/// Spec: docs/design/data-model/entities.md - DictionaryEntry
class DictionaryEntry {
  /// Creates a new DictionaryEntry instance.
  const DictionaryEntry({
    required this.id,
    required this.keyword,
    required this.description,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.embedding,
  });

  /// Unique identifier (UUID v4)
  final String id;

  /// Keyword text
  /// MUST NOT be empty
  /// MUST be unique
  /// SHOULD be max 100 characters
  final String keyword;

  /// Description or supplementary information
  /// SHOULD be max 1,000 characters
  final String description;

  /// Category of the entry
  final Category category;

  /// Creation timestamp (UTC)
  final DateTime createdAt;

  /// Last update timestamp (UTC)
  final DateTime updatedAt;

  /// Embedding vector stored as JSON string
  /// MAY be null if not yet analyzed
  final String? embedding;

  /// Creates a copy with updated fields.
  DictionaryEntry copyWith({
    String? id,
    String? keyword,
    String? description,
    Category? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? embedding,
  }) {
    return DictionaryEntry(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      description: description ?? this.description,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      embedding: embedding ?? this.embedding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DictionaryEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
