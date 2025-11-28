import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/entities/memo.dart';
import '../../domain/entities/similarity_result.dart';
import '../../domain/entities/target_type.dart';
import '../../domain/repositories/memo_repository.dart';
import '../../domain/repositories/similarity_repository.dart';
import '../api/gemini_client.dart';

/// Use cases for memo operations.
/// 
/// Spec: FR-001 to FR-005 - Memo CRUD and duplicate detection
class MemoUseCases {
  MemoUseCases({
    required MemoRepository memoRepository,
    required SimilarityRepository similarityRepository,
    required GeminiClient geminiClient,
  })  : _memoRepository = memoRepository,
        _similarityRepository = similarityRepository,
        _geminiClient = geminiClient;

  final MemoRepository _memoRepository;
  final SimilarityRepository _similarityRepository;
  final GeminiClient _geminiClient;

  static const _uuid = Uuid();

  /// Creates a new memo.
  /// 
  /// Spec: FR-001 - Memo creation
  Future<Memo> createMemo(String content) async {
    final now = DateTime.now();
    final memo = Memo(
      id: _uuid.v4(),
      content: content.trim(),
      createdAt: now,
      updatedAt: now,
      embedding: null,
      isAnalyzed: false,
    );

    return _memoRepository.create(memo);
  }

  /// Creates a memo with embedding analysis.
  /// 
  /// Spec: FR-003 - AI semantic analysis
  Future<Memo> createMemoWithAnalysis(String content) async {
    final memo = await createMemo(content);
    return analyzeMemo(memo.id);
  }

  /// Gets all memos.
  Future<List<Memo>> getAllMemos() async {
    return _memoRepository.findAll();
  }

  /// Gets recent memos.
  /// 
  /// Spec: FR-005 - Display recent memos on home screen
  Future<List<Memo>> getRecentMemos(int count) async {
    return _memoRepository.findRecent(count);
  }

  /// Gets a memo by ID.
  Future<Memo?> getMemoById(String id) async {
    return _memoRepository.findById(id);
  }

  /// Searches memos by keyword.
  /// 
  /// Spec: FR-006 - Search functionality
  Future<List<Memo>> searchMemos(String keyword) async {
    return _memoRepository.search(keyword);
  }

  /// Updates a memo.
  /// 
  /// Spec: FR-002 - Memo editing
  Future<Memo> updateMemo(String id, String content) async {
    final existing = await _memoRepository.findById(id);
    if (existing == null) {
      throw Exception('Memo not found: $id');
    }

    final updated = existing.copyWith(
      content: content.trim(),
      updatedAt: DateTime.now(),
      isAnalyzed: false, // Mark for re-analysis
    );

    return _memoRepository.update(updated);
  }

  /// Updates a memo with re-analysis.
  Future<Memo> updateMemoWithAnalysis(String id, String content) async {
    await updateMemo(id, content);
    return analyzeMemo(id);
  }

  /// Deletes a memo.
  Future<void> deleteMemo(String id) async {
    // Delete associated similarity results
    await _similarityRepository.deleteBySourceId(id);
    await _similarityRepository.deleteByTargetId(id);
    await _memoRepository.delete(id);
  }

  /// Analyzes a memo and generates embedding.
  /// 
  /// Spec: FR-003 - AI semantic analysis
  Future<Memo> analyzeMemo(String memoId) async {
    final memo = await _memoRepository.findById(memoId);
    if (memo == null) {
      throw Exception('Memo not found: $memoId');
    }

    // Generate embedding
    final embeddingResult = await _geminiClient.generateEmbedding(memo.content);
    
    final updated = memo.copyWith(
      embedding: embeddingResult.toJsonString(),
      isAnalyzed: true,
      updatedAt: DateTime.now(),
    );

    return _memoRepository.update(updated);
  }

  /// Checks for duplicate memos based on content similarity.
  /// 
  /// Spec: FR-004 - Duplicate detection
  /// Spec: ADR-005 - 2-stage duplicate detection
  Future<List<SimilarityResult>> checkDuplicates(
    String memoId, {
    double threshold = 0.7,
  }) async {
    final memo = await _memoRepository.findById(memoId);
    if (memo == null || memo.embedding == null) {
      return [];
    }

    final sourceEmbedding = _parseEmbedding(memo.embedding!);
    final allMemos = await _memoRepository.findWithEmbeddings();
    final results = <SimilarityResult>[];

    for (final other in allMemos) {
      if (other.id == memoId || other.embedding == null) continue;

      final targetEmbedding = _parseEmbedding(other.embedding!);
      final score = GeminiClient.calculateCosineSimilarity(
        sourceEmbedding,
        targetEmbedding,
      );

      if (score >= threshold) {
        final result = SimilarityResult(
          id: _uuid.v4(),
          sourceId: memoId,
          targetId: other.id,
          targetType: TargetType.memo,
          score: score,
          calculatedAt: DateTime.now(),
        );

        // Save similarity result
        await _similarityRepository.create(result);
        results.add(result);
      }
    }

    return results..sort((a, b) => b.score.compareTo(a.score));
  }

  /// Performs quick keyword-based duplicate check during input.
  /// 
  /// Spec: ADR-005 - Stage 1: Local keyword matching
  Future<List<Memo>> quickDuplicateCheck(String content) async {
    final keywords = _extractKeywords(content);
    if (keywords.isEmpty) return [];

    final results = <Memo>[];
    for (final keyword in keywords) {
      final matches = await _memoRepository.search(keyword);
      for (final match in matches) {
        if (!results.any((m) => m.id == match.id)) {
          results.add(match);
        }
      }
    }

    return results.take(5).toList();
  }

  /// Analyzes duplicate with detailed LLM explanation.
  /// 
  /// Spec: FR-004 - User-friendly duplicate notification
  Future<DuplicateAnalysisResult> analyzeDuplicateWithLLM({
    required String newContent,
    required String existingMemoId,
  }) async {
    final existingMemo = await _memoRepository.findById(existingMemoId);
    if (existingMemo == null) {
      throw Exception('Existing memo not found: $existingMemoId');
    }

    return _geminiClient.analyzeDuplicate(
      newText: newContent,
      existingText: existingMemo.content,
    );
  }

  /// Gets similar memos for a given memo.
  Future<List<SimilarityResult>> getSimilarMemos(String memoId) async {
    return _similarityRepository.findBySourceIdAndType(memoId, TargetType.memo);
  }

  /// Analyzes all unanalyzed memos.
  /// 
  /// Spec: Background analysis for efficiency
  Future<int> analyzeUnanalyzedMemos() async {
    final unanalyzed = await _memoRepository.findUnanalyzed();
    var count = 0;

    for (final memo in unanalyzed) {
      try {
        await analyzeMemo(memo.id);
        count++;
      } on Exception {
        // Continue with other memos on failure
      }
    }

    return count;
  }

  List<double> _parseEmbedding(String json) {
    return (jsonDecode(json) as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
  }

  List<String> _extractKeywords(String content) {
    // Simple keyword extraction for quick matching
    final words = content
        .replaceAll(RegExp(r'[、。！？\s]+'), ' ')
        .split(' ')
        .where((w) => w.length >= 2)
        .toSet()
        .toList();
    
    return words.take(5).toList();
  }
}
