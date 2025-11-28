/// Memo entity representing a user's note.
/// 
/// Spec: docs/design/data-model/entities.md - Memo
class Memo {
  /// Creates a new Memo instance.
  const Memo({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.isAnalyzed,
    this.embedding,
  });

  /// Unique identifier (UUID v4)
  final String id;

  /// Memo content text
  /// MUST NOT be empty
  /// SHOULD be max 10,000 characters
  final String content;

  /// Creation timestamp (UTC)
  final DateTime createdAt;

  /// Last update timestamp (UTC)
  final DateTime updatedAt;

  /// Embedding vector stored as JSON string
  /// MAY be null if not yet analyzed
  final String? embedding;

  /// Whether this memo has been analyzed by API
  final bool isAnalyzed;

  /// Creates a copy with updated fields.
  Memo copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? embedding,
    bool? isAnalyzed,
  }) {
    return Memo(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      embedding: embedding ?? this.embedding,
      isAnalyzed: isAnalyzed ?? this.isAnalyzed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Memo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
