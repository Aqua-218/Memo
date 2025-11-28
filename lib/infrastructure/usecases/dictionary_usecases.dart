import 'package:uuid/uuid.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../../domain/repositories/similarity_repository.dart';
import '../api/gemini_client.dart';

/// Use cases for dictionary operations.
/// 
/// Spec: FR-007 - Personal dictionary management
class DictionaryUseCases {
  DictionaryUseCases({
    required DictionaryRepository dictionaryRepository,
    required SimilarityRepository similarityRepository,
    required GeminiClient geminiClient,
  })  : _dictionaryRepository = dictionaryRepository,
        _similarityRepository = similarityRepository,
        _geminiClient = geminiClient;

  final DictionaryRepository _dictionaryRepository;
  // ignore: unused_field - Reserved for future similarity comparison operations
  final SimilarityRepository _similarityRepository;
  final GeminiClient _geminiClient;

  static const _uuid = Uuid();

  /// Creates a new dictionary entry.
  /// 
  /// Spec: FR-007 - Register personal terms
  Future<DictionaryEntry> createEntry({
    required String keyword,
    required String description,
    Category? category,
  }) async {
    // Check for existing entry
    final existing = await _dictionaryRepository.findByKeyword(keyword);
    if (existing != null) {
      throw Exception('キーワード「$keyword」は既に登録されています');
    }

    // Suggest category if not provided
    final actualCategory = category ?? 
        await _suggestCategory(keyword, description);

    final now = DateTime.now();
    final entry = DictionaryEntry(
      id: _uuid.v4(),
      keyword: keyword.trim(),
      description: description.trim(),
      category: actualCategory,
      createdAt: now,
      updatedAt: now,
      embedding: null,
    );

    return _dictionaryRepository.create(entry);
  }

  /// Creates a dictionary entry with embedding.
  Future<DictionaryEntry> createEntryWithEmbedding({
    required String keyword,
    required String description,
    Category? category,
  }) async {
    final entry = await createEntry(
      keyword: keyword,
      description: description,
      category: category,
    );
    return analyzeEntry(entry.id);
  }

  /// Gets all dictionary entries.
  Future<List<DictionaryEntry>> getAllEntries() async {
    return _dictionaryRepository.findAll();
  }

  /// Gets entries by category.
  Future<List<DictionaryEntry>> getEntriesByCategory(Category category) async {
    return _dictionaryRepository.findByCategory(category);
  }

  /// Gets an entry by ID.
  Future<DictionaryEntry?> getEntryById(String id) async {
    return _dictionaryRepository.findById(id);
  }

  /// Gets an entry by keyword.
  Future<DictionaryEntry?> getEntryByKeyword(String keyword) async {
    return _dictionaryRepository.findByKeyword(keyword);
  }

  /// Searches entries by keyword or description.
  Future<List<DictionaryEntry>> searchEntries(String query) async {
    return _dictionaryRepository.search(query);
  }

  /// Updates a dictionary entry.
  Future<DictionaryEntry> updateEntry({
    required String id,
    String? keyword,
    String? description,
    Category? category,
  }) async {
    final existing = await _dictionaryRepository.findById(id);
    if (existing == null) {
      throw Exception('辞書エントリが見つかりません: $id');
    }

    // Check for duplicate keyword if changing
    if (keyword != null && keyword != existing.keyword) {
      final duplicate = await _dictionaryRepository.findByKeyword(keyword);
      if (duplicate != null) {
        throw Exception('キーワード「$keyword」は既に登録されています');
      }
    }

    final updated = existing.copyWith(
      keyword: keyword?.trim() ?? existing.keyword,
      description: description?.trim() ?? existing.description,
      category: category ?? existing.category,
      updatedAt: DateTime.now(),
      embedding: null, // Mark for re-analysis if content changed
    );

    return _dictionaryRepository.update(updated);
  }

  /// Deletes a dictionary entry.
  Future<void> deleteEntry(String id) async {
    // Delete associated similarity results
    await _similarityRepository.deleteBySourceId(id);
    await _similarityRepository.deleteByTargetId(id);
    await _dictionaryRepository.delete(id);
  }

  /// Analyzes an entry and generates embedding.
  Future<DictionaryEntry> analyzeEntry(String entryId) async {
    final entry = await _dictionaryRepository.findById(entryId);
    if (entry == null) {
      throw Exception('辞書エントリが見つかりません: $entryId');
    }

    // Create combined text for embedding
    final combinedText = '${entry.keyword}: ${entry.description}';
    final embeddingResult = await _geminiClient.generateEmbedding(combinedText);

    final updated = entry.copyWith(
      embedding: embeddingResult.toJsonString(),
      updatedAt: DateTime.now(),
    );

    return _dictionaryRepository.update(updated);
  }

  /// Finds related dictionary entries for a memo content.
  /// 
  /// Spec: FR-008 - Link memos to dictionary entries
  Future<List<DictionaryEntry>> findRelatedEntries(String content) async {
    final entries = await _dictionaryRepository.findAll();
    final relatedEntries = <DictionaryEntry>[];

    for (final entry in entries) {
      if (content.contains(entry.keyword)) {
        relatedEntries.add(entry);
      }
    }

    return relatedEntries;
  }

  /// Gets category statistics.
  Future<Map<Category, int>> getCategoryStats() async {
    final stats = <Category, int>{};
    
    for (final category in Category.values) {
      final entries = await _dictionaryRepository.findByCategory(category);
      stats[category] = entries.length;
    }

    return stats;
  }

  /// Gets total entry count.
  Future<int> getEntryCount() async {
    return _dictionaryRepository.count();
  }

  Future<Category> _suggestCategory(String keyword, String description) async {
    try {
      final categoryName = await _geminiClient.suggestCategory(
        keyword,
        description,
      );
      return CategoryExtension.fromDisplayName(categoryName);
    } on Exception {
      return Category.other;
    }
  }
}
