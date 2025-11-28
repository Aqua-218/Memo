import '../entities/memo.dart';

/// Repository interface for Memo operations.
/// 
/// Spec: docs/design/architecture.md - Domain Layer - Repositories
abstract class MemoRepository {
  /// Creates a new memo.
  /// 
  /// Returns the created memo.
  Future<Memo> create(Memo memo);

  /// Retrieves a memo by its ID.
  /// 
  /// Returns null if not found.
  Future<Memo?> findById(String id);

  /// Retrieves all memos ordered by createdAt descending.
  Future<List<Memo>> findAll();

  /// Retrieves the most recent memos.
  /// 
  /// [count] specifies the maximum number of memos to return.
  Future<List<Memo>> findRecent(int count);

  /// Searches memos by keyword in content.
  /// 
  /// Returns memos containing the keyword.
  Future<List<Memo>> search(String keyword);

  /// Updates an existing memo.
  /// 
  /// Returns the updated memo.
  Future<Memo> update(Memo memo);

  /// Deletes a memo by its ID.
  Future<void> delete(String id);

  /// Retrieves memos that have not been analyzed yet.
  Future<List<Memo>> findUnanalyzed();

  /// Retrieves memos that have embeddings.
  Future<List<Memo>> findWithEmbeddings();

  /// Returns the total count of memos.
  Future<int> count();
}
