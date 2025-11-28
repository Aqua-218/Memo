import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/font_size.dart';
import '../domain/entities/settings.dart';
import '../infrastructure/config/env_config.dart';
import '../infrastructure/database/database.dart';
import '../infrastructure/api/gemini_client.dart';
import '../infrastructure/repositories/memo_repository_impl.dart';
import '../infrastructure/repositories/dictionary_repository_impl.dart';
import '../infrastructure/repositories/similarity_repository_impl.dart';
import '../infrastructure/usecases/memo_usecases.dart';
import '../infrastructure/usecases/dictionary_usecases.dart';
import '../infrastructure/usecases/similarity_usecases.dart';
import '../domain/repositories/memo_repository.dart';
import '../domain/repositories/dictionary_repository.dart';
import '../domain/repositories/similarity_repository.dart';

/// Database provider.
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  return AppDatabase.getInstance();
});

/// Secure storage provider for API keys.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
});

/// SharedPreferences provider.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Gemini API key provider.
/// 環境変数 (.env) から優先的にAPIキーを読み込み、
/// なければSecure Storageから読み込む
final geminiApiKeyProvider = FutureProvider<String?>((ref) async {
  // 1. まず環境変数から読み込み
  if (EnvConfig.hasApiKey) {
    return EnvConfig.geminiApiKey;
  }
  
  // 2. 環境変数になければSecure Storageから読み込み
  final storage = ref.watch(secureStorageProvider);
  return storage.read(key: 'gemini_api_key');
});

/// Gemini client provider.
/// 環境変数が設定されていればそこから設定を読み込む
final geminiClientProvider = FutureProvider<GeminiClient?>((ref) async {
  final apiKey = await ref.watch(geminiApiKeyProvider.future);
  if (apiKey == null || apiKey.isEmpty) {
    return null;
  }
  
  // 環境変数からAPIキーが設定されている場合は、環境変数の設定を使用
  if (EnvConfig.hasApiKey) {
    return GeminiClient(GeminiConfig.fromEnv());
  }
  
  // そうでなければ、Secure StorageのAPIキーを使用
  return GeminiClient(GeminiConfig(apiKey: apiKey));
});

/// Memo repository provider.
final memoRepositoryProvider = FutureProvider<MemoRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return MemoRepositoryImpl(database);
});

/// Dictionary repository provider.
final dictionaryRepositoryProvider = FutureProvider<DictionaryRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return DictionaryRepositoryImpl(database);
});

/// Similarity repository provider.
final similarityRepositoryProvider = FutureProvider<SimilarityRepository>((ref) async {
  final database = await ref.watch(databaseProvider.future);
  return SimilarityRepositoryImpl(database);
});

/// Memo use cases provider.
final memoUseCasesProvider = FutureProvider<MemoUseCases?>((ref) async {
  final geminiClient = await ref.watch(geminiClientProvider.future);
  if (geminiClient == null) return null;

  final memoRepo = await ref.watch(memoRepositoryProvider.future);
  final similarityRepo = await ref.watch(similarityRepositoryProvider.future);

  return MemoUseCases(
    memoRepository: memoRepo,
    similarityRepository: similarityRepo,
    geminiClient: geminiClient,
  );
});

/// Dictionary use cases provider.
final dictionaryUseCasesProvider = FutureProvider<DictionaryUseCases?>((ref) async {
  final geminiClient = await ref.watch(geminiClientProvider.future);
  if (geminiClient == null) return null;

  final dictRepo = await ref.watch(dictionaryRepositoryProvider.future);
  final similarityRepo = await ref.watch(similarityRepositoryProvider.future);

  return DictionaryUseCases(
    dictionaryRepository: dictRepo,
    similarityRepository: similarityRepo,
    geminiClient: geminiClient,
  );
});

/// Similarity use cases provider.
final similarityUseCasesProvider = FutureProvider<SimilarityUseCases?>((ref) async {
  final geminiClient = await ref.watch(geminiClientProvider.future);
  if (geminiClient == null) return null;

  final memoRepo = await ref.watch(memoRepositoryProvider.future);
  final dictRepo = await ref.watch(dictionaryRepositoryProvider.future);
  final similarityRepo = await ref.watch(similarityRepositoryProvider.future);

  return SimilarityUseCases(
    memoRepository: memoRepo,
    dictionaryRepository: dictRepo,
    similarityRepository: similarityRepo,
    geminiClient: geminiClient,
  );
});

/// Settings provider with persistence.
/// 
/// Spec: FR-010, FR-011 - Settings management
class SettingsNotifier extends AsyncNotifier<Settings> {
  static const _fontSizeKey = 'font_size';
  static const _notificationEnabledKey = 'notification_enabled';
  static const _recentMemoCountKey = 'recent_memo_count';

  @override
  Future<Settings> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    
    final fontSizeIndex = prefs.getInt(_fontSizeKey) ?? 1;
    final notificationEnabled = prefs.getBool(_notificationEnabledKey) ?? true;
    final recentMemoCount = prefs.getInt(_recentMemoCountKey) ?? 5;

    return Settings(
      fontSize: FontSize.values[fontSizeIndex],
      notificationEnabled: notificationEnabled,
      recentMemoCount: recentMemoCount,
    );
  }

  Future<void> updateFontSize(FontSize fontSize) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(_fontSizeKey, fontSize.index);
    
    state = AsyncData(state.value!.copyWith(fontSize: fontSize));
  }

  Future<void> updateNotificationEnabled(bool enabled) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setBool(_notificationEnabledKey, enabled);
    
    state = AsyncData(state.value!.copyWith(notificationEnabled: enabled));
  }

  Future<void> updateRecentMemoCount(int count) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(_recentMemoCountKey, count);
    
    state = AsyncData(state.value!.copyWith(recentMemoCount: count));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);

/// API key setup state.
/// 環境変数またはSecure StorageにAPIキーが設定されているかチェック
final isApiKeySetProvider = FutureProvider<bool>((ref) async {
  // 環境変数にAPIキーがあればtrue
  if (EnvConfig.hasApiKey) {
    return true;
  }
  
  // なければSecure Storageをチェック
  final apiKey = await ref.watch(geminiApiKeyProvider.future);
  return apiKey != null && apiKey.isNotEmpty;
});

/// APIキーのソースを示すプロバイダー
enum ApiKeySource { none, env, secureStorage }

final apiKeySourceProvider = FutureProvider<ApiKeySource>((ref) async {
  if (EnvConfig.hasApiKey) {
    return ApiKeySource.env;
  }
  
  final storage = ref.watch(secureStorageProvider);
  final apiKey = await storage.read(key: 'gemini_api_key');
  if (apiKey != null && apiKey.isNotEmpty) {
    return ApiKeySource.secureStorage;
  }
  
  return ApiKeySource.none;
});

/// Save API key action.
Future<void> saveApiKey(WidgetRef ref, String apiKey) async {
  final storage = ref.read(secureStorageProvider);
  await storage.write(key: 'gemini_api_key', value: apiKey);
  ref.invalidate(geminiApiKeyProvider);
}

/// Delete API key action.
Future<void> deleteApiKey(WidgetRef ref) async {
  final storage = ref.read(secureStorageProvider);
  await storage.delete(key: 'gemini_api_key');
  ref.invalidate(geminiApiKeyProvider);
}
