import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../domain/entities/similarity_result.dart';
import '../../domain/entities/target_type.dart';
import '../../domain/repositories/memo_repository.dart';
import '../../domain/repositories/dictionary_repository.dart';
import '../../domain/repositories/similarity_repository.dart';
import '../api/gemini_client.dart';

/// Use cases for similarity calculations.
/// 
/// Spec: FR-003, FR-004 - Semantic similarity and duplicate detection
class SimilarityUseCases {
  SimilarityUseCases({
    required MemoRepository memoRepository,
    required DictionaryRepository dictionaryRepository,
    required SimilarityRepository similarityRepository,
    required GeminiClient geminiClient,
  })  : _memoRepository = memoRepository,
        _dictionaryRepository = dictionaryRepository,
        _similarityRepository = similarityRepository,
        _geminiClient = geminiClient;

  final MemoRepository _memoRepository;
  final DictionaryRepository _dictionaryRepository;
  final SimilarityRepository _similarityRepository;
  // ignore: unused_field - Reserved for future Gemini API embedding operations
  final GeminiClient _geminiClient;

  static const _uuid = Uuid();

  /// Default similarity threshold for duplicate detection.
  static const double defaultThreshold = 0.7;

  /// High similarity threshold for definite duplicates.
  static const double highThreshold = 0.9;

  /// Calculates similarity between a memo and all other memos.
  /// 
  /// Spec: FR-003 - Semantic analysis
  Future<List<SimilarityResult>> calculateMemoSimilarities(
    String memoId, {
    double threshold = defaultThreshold,
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
        results.add(result);
      }
    }

    // Sort by score descending
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Calculates similarity between a memo and dictionary entries.
  /// 
  /// Spec: FR-008 - Link memos to dictionary
  Future<List<SimilarityResult>> calculateDictionarySimilarities(
    String memoId, {
    double threshold = 0.5,
  }) async {
    final memo = await _memoRepository.findById(memoId);
    if (memo == null || memo.embedding == null) {
      return [];
    }

    final sourceEmbedding = _parseEmbedding(memo.embedding!);
    final allEntries = await _dictionaryRepository.findWithEmbeddings();
    final results = <SimilarityResult>[];

    for (final entry in allEntries) {
      if (entry.embedding == null) continue;

      final targetEmbedding = _parseEmbedding(entry.embedding!);
      final score = GeminiClient.calculateCosineSimilarity(
        sourceEmbedding,
        targetEmbedding,
      );

      if (score >= threshold) {
        final result = SimilarityResult(
          id: _uuid.v4(),
          sourceId: memoId,
          targetId: entry.id,
          targetType: TargetType.dictionary,
          score: score,
          calculatedAt: DateTime.now(),
        );
        results.add(result);
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  /// Saves similarity results to repository.
  Future<void> saveSimilarityResults(List<SimilarityResult> results) async {
    for (final result in results) {
      // Check if already exists
      final existing = await _similarityRepository.findByPair(
        result.sourceId,
        result.targetId,
      );

      if (existing == null) {
        await _similarityRepository.create(result);
      }
    }
  }

  /// Gets cached similarity results for a memo.
  Future<List<SimilarityResult>> getCachedSimilarities(String memoId) async {
    return _similarityRepository.findBySourceId(memoId);
  }

  /// Gets high-similarity results (potential duplicates).
  Future<List<SimilarityResult>> getPotentialDuplicates(
    String memoId, {
    double threshold = highThreshold,
  }) async {
    return _similarityRepository.findAboveThreshold(memoId, threshold);
  }

  /// Performs full similarity analysis for a memo.
  /// 
  /// This includes:
  /// 1. Calculate similarities with all memos
  /// 2. Calculate similarities with dictionary entries
  /// 3. Save results to cache
  Future<Map<String, List<SimilarityResult>>> analyzeMemoFully(
    String memoId,
  ) async {
    final memoSimilarities = await calculateMemoSimilarities(memoId);
    final dictSimilarities = await calculateDictionarySimilarities(memoId);

    await saveSimilarityResults(memoSimilarities);
    await saveSimilarityResults(dictSimilarities);

    return {
      'memos': memoSimilarities,
      'dictionary': dictSimilarities,
    };
  }

  /// Cleans up old similarity results.
  /// 
  /// Spec: Performance optimization
  Future<void> cleanupOldResults({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    await _similarityRepository.deleteOlderThan(cutoffDate);
  }

  /// Recalculates all similarities for the database.
  /// 
  /// Use sparingly as this can be expensive.
  Future<int> recalculateAllSimilarities() async {
    // Clear existing results
    await _similarityRepository.deleteAll();

    final memos = await _memoRepository.findWithEmbeddings();
    var totalResults = 0;

    for (final memo in memos) {
      final results = await calculateMemoSimilarities(memo.id);
      await saveSimilarityResults(results);
      totalResults += results.length;
    }

    return totalResults;
  }

  /// Gets similarity statistics.
  Future<Map<String, dynamic>> getStatistics() async {
    final totalResults = await _similarityRepository.count();
    final memos = await _memoRepository.findWithEmbeddings();

    return {
      'totalResults': totalResults,
      'analyzedMemos': memos.length,
      'averageResultsPerMemo': memos.isEmpty ? 0 : totalResults / memos.length,
    };
  }

  List<double> _parseEmbedding(String json) {
    return (jsonDecode(json) as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
  }
}
