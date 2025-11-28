import '../entities/category.dart';
import '../entities/dictionary_entry.dart';

/// Repository interface for DictionaryEntry operations.
/// 
/// Spec: docs/design/architecture.md - Domain Layer - Repositories
abstract class DictionaryRepository {
  /// Creates a new dictionary entry.
  /// 
  /// Returns the created entry.
  Future<DictionaryEntry> create(DictionaryEntry entry);

  /// Retrieves a dictionary entry by its ID.
  /// 
  /// Returns null if not found.
  Future<DictionaryEntry?> findById(String id);

  /// Retrieves a dictionary entry by its keyword.
  /// 
  /// Returns null if not found.
  Future<DictionaryEntry?> findByKeyword(String keyword);

  /// Retrieves all dictionary entries ordered by keyword.
  Future<List<DictionaryEntry>> findAll();

  /// Retrieves dictionary entries by category.
  Future<List<DictionaryEntry>> findByCategory(Category category);

  /// Searches dictionary entries by keyword pattern.
  /// 
  /// Returns entries where keyword or description contains the pattern.
  Future<List<DictionaryEntry>> search(String pattern);

  /// Updates an existing dictionary entry.
  /// 
  /// Returns the updated entry.
  Future<DictionaryEntry> update(DictionaryEntry entry);

  /// Deletes a dictionary entry by its ID.
  Future<void> delete(String id);

  /// Retrieves dictionary entries that have embeddings.
  Future<List<DictionaryEntry>> findWithEmbeddings();

  /// Returns the total count of dictionary entries.
  Future<int> count();
}
