import 'package:flutter_dotenv/flutter_dotenv.dart';

/// アプリケーション環境設定を管理するクラス
class EnvConfig {
  EnvConfig._();

  /// 環境変数を読み込む
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // -------------------------------------------
  // Gemini API Configuration
  // -------------------------------------------

  /// Gemini API キー
  static String get geminiApiKey =>
      dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Gemini テキスト生成モデル
  static String get geminiTextModel =>
      dotenv.env['GEMINI_TEXT_MODEL'] ?? 'gemini-2.0-flash';

  /// Gemini 埋め込みモデル
  static String get geminiEmbeddingModel =>
      dotenv.env['GEMINI_EMBEDDING_MODEL'] ?? 'text-embedding-004';

  // -------------------------------------------
  // API Settings
  // -------------------------------------------

  /// API タイムアウト秒数
  static int get apiTimeoutSeconds =>
      int.tryParse(dotenv.env['API_TIMEOUT_SECONDS'] ?? '30') ?? 30;

  /// API 最大リトライ回数
  static int get apiMaxRetries =>
      int.tryParse(dotenv.env['API_MAX_RETRIES'] ?? '3') ?? 3;

  // -------------------------------------------
  // Similarity Detection Settings
  // -------------------------------------------

  /// 類似度判定の閾値
  static double get similarityThreshold =>
      double.tryParse(dotenv.env['SIMILARITY_THRESHOLD'] ?? '0.85') ?? 0.85;

  /// 類似結果の最大件数
  static int get similarityMaxResults =>
      int.tryParse(dotenv.env['SIMILARITY_MAX_RESULTS'] ?? '5') ?? 5;

  // -------------------------------------------
  // Debug Settings
  // -------------------------------------------

  /// デバッグモードが有効か
  static bool get debugMode =>
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  /// 詳細ログが有効か
  static bool get verboseLogging =>
      dotenv.env['VERBOSE_LOGGING']?.toLowerCase() == 'true';

  /// API キーが設定されているか確認
  static bool get hasApiKey =>
      geminiApiKey.isNotEmpty && geminiApiKey != 'your_gemini_api_key_here';
}
