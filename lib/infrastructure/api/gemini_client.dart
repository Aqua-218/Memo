import 'dart:async';
import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

/// Exception thrown when Gemini API operations fail.
class GeminiException implements Exception {
  const GeminiException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'GeminiException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Configuration for Gemini API client.
class GeminiConfig {
  const GeminiConfig({
    required this.apiKey,
    this.embeddingModel = 'models/text-embedding-004',
    this.generationModel = 'gemini-1.5-flash',
    this.embeddingDimensions = 768,
    this.maxRetries = 3,
    this.retryDelayMs = 1000,
  });

  final String apiKey;
  final String embeddingModel;
  final String generationModel;
  final int embeddingDimensions;
  final int maxRetries;
  final int retryDelayMs;
}

/// Result of embedding generation.
class EmbeddingResult {
  const EmbeddingResult({
    required this.embedding,
    required this.text,
  });

  final List<double> embedding;
  final String text;

  /// Converts embedding to JSON string for storage.
  String toJsonString() => jsonEncode(embedding);

  /// Creates from JSON string.
  static EmbeddingResult fromJsonString(String json, String text) {
    final embedding = (jsonDecode(json) as List<dynamic>)
        .map((e) => (e as num).toDouble())
        .toList();
    return EmbeddingResult(embedding: embedding, text: text);
  }
}

/// Result of duplicate analysis.
class DuplicateAnalysisResult {
  const DuplicateAnalysisResult({
    required this.isDuplicate,
    required this.confidence,
    required this.explanation,
    required this.suggestedAction,
  });

  final bool isDuplicate;
  final double confidence;
  final String explanation;
  final String suggestedAction;
}

/// Client for Gemini API operations.
/// 
/// Spec: ADR-004 - Gemini API Integration
/// Handles embedding generation and semantic analysis.
class GeminiClient {
  GeminiClient(this.config)
      : _embeddingModel = GenerativeModel(
          model: config.embeddingModel,
          apiKey: config.apiKey,
        ),
        _generationModel = GenerativeModel(
          model: config.generationModel,
          apiKey: config.apiKey,
        );

  final GeminiConfig config;
  final GenerativeModel _embeddingModel;
  final GenerativeModel _generationModel;

  /// Generates embedding for the given text.
  /// 
  /// Spec: FR-003 - AI semantic analysis using embeddings
  Future<EmbeddingResult> generateEmbedding(String text) async {
    if (text.trim().isEmpty) {
      throw const GeminiException('Text cannot be empty');
    }

    for (var attempt = 0; attempt < config.maxRetries; attempt++) {
      try {
        final content = Content.text(text);
        final response = await _embeddingModel.embedContent(content);
        
        return EmbeddingResult(
          embedding: response.embedding.values,
          text: text,
        );
      } on Exception catch (e) {
        if (attempt == config.maxRetries - 1) {
          throw GeminiException('Failed to generate embedding after ${config.maxRetries} attempts', cause: e);
        }
        await Future<void>.delayed(Duration(milliseconds: config.retryDelayMs * (attempt + 1)));
      }
    }

    throw const GeminiException('Unexpected error in generateEmbedding');
  }

  /// Generates embeddings for multiple texts in batch.
  /// 
  /// Spec: FR-003 - Batch processing for efficiency
  Future<List<EmbeddingResult>> generateEmbeddingsBatch(List<String> texts) async {
    final results = <EmbeddingResult>[];
    
    for (final text in texts) {
      final result = await generateEmbedding(text);
      results.add(result);
    }
    
    return results;
  }

  /// Analyzes two texts for duplicate content using LLM.
  /// 
  /// Spec: FR-004 - Duplicate detection with explanation
  Future<DuplicateAnalysisResult> analyzeDuplicate({
    required String newText,
    required String existingText,
  }) async {
    final prompt = '''
あなたは高齢者向けメモアプリのアシスタントです。
以下の2つのメモの内容を比較して、重複している可能性があるかどうかを判断してください。

【新しいメモ】
$newText

【既存のメモ】
$existingText

以下の形式でJSON形式で回答してください。説明は簡潔に、高齢者にもわかりやすい言葉で記述してください：
{
  "isDuplicate": true または false,
  "confidence": 0.0 から 1.0 の数値（重複の確信度）,
  "explanation": "重複の理由または違いの説明（100文字以内）",
  "suggestedAction": "保存する" または "確認する" または "統合する"
}
''';

    for (var attempt = 0; attempt < config.maxRetries; attempt++) {
      try {
        final response = await _generationModel.generateContent([
          Content.text(prompt),
        ]);

        final responseText = response.text;
        if (responseText == null || responseText.isEmpty) {
          throw const GeminiException('Empty response from Gemini');
        }

        return _parseDuplicateAnalysisResult(responseText);
      } on GeminiException {
        rethrow;
      } on Exception catch (e) {
        if (attempt == config.maxRetries - 1) {
          throw GeminiException('Failed to analyze duplicate after ${config.maxRetries} attempts', cause: e);
        }
        await Future<void>.delayed(Duration(milliseconds: config.retryDelayMs * (attempt + 1)));
      }
    }

    throw const GeminiException('Unexpected error in analyzeDuplicate');
  }

  /// Suggests category for a dictionary entry.
  /// 
  /// Spec: FR-007 - Personal dictionary with categories
  Future<String> suggestCategory(String keyword, String description) async {
    final prompt = '''
あなたは高齢者向けメモアプリのアシスタントです。
以下の単語と説明に最も適したカテゴリを1つだけ選んでください。

【単語】$keyword
【説明】$description

【カテゴリ一覧】
- 人物（家族、友人、知人など）
- 場所（住所、お店、施設など）
- 予定（イベント、約束など）
- 医療（薬、病院、症状など）
- その他

カテゴリ名のみを回答してください。
''';

    for (var attempt = 0; attempt < config.maxRetries; attempt++) {
      try {
        final response = await _generationModel.generateContent([
          Content.text(prompt),
        ]);

        final responseText = response.text?.trim();
        if (responseText == null || responseText.isEmpty) {
          return 'その他';
        }

        // Validate category
        const validCategories = ['人物', '場所', '予定', '医療', 'その他'];
        for (final category in validCategories) {
          if (responseText.contains(category)) {
            return category;
          }
        }

        return 'その他';
      } on Exception {
        if (attempt == config.maxRetries - 1) {
          // Return default category on failure
          return 'その他';
        }
        await Future<void>.delayed(Duration(milliseconds: config.retryDelayMs * (attempt + 1)));
      }
    }

    return 'その他';
  }

  DuplicateAnalysisResult _parseDuplicateAnalysisResult(String responseText) {
    try {
      // Extract JSON from response (may be wrapped in markdown code blocks)
      var jsonText = responseText;
      
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
      if (jsonMatch != null) {
        jsonText = jsonMatch.group(0)!;
      }

      final json = jsonDecode(jsonText) as Map<String, dynamic>;

      return DuplicateAnalysisResult(
        isDuplicate: json['isDuplicate'] as bool? ?? false,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
        explanation: json['explanation'] as String? ?? '分析できませんでした',
        suggestedAction: json['suggestedAction'] as String? ?? '保存する',
      );
    } on Exception catch (e) {
      throw GeminiException('Failed to parse duplicate analysis result', cause: e);
    }
  }

  /// Calculates cosine similarity between two embeddings.
  /// 
  /// Spec: ADR-004 - Local similarity calculation
  static double calculateCosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) {
      throw const GeminiException('Embedding dimensions must match');
    }

    var dotProduct = 0.0;
    var normA = 0.0;
    var normB = 0.0;

    for (var i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) {
      return 0.0;
    }

    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}

/// Square root function for similarity calculation.
double sqrt(double x) {
  if (x < 0) return double.nan;
  if (x == 0) return 0;
  
  var guess = x / 2;
  for (var i = 0; i < 20; i++) {
    guess = (guess + x / guess) / 2;
  }
  return guess;
}
