import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/category.dart';
import '../domain/entities/dictionary_entry.dart';
import 'providers.dart';

/// State for dictionary entry list.
class DictionaryListState {
  const DictionaryListState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
  });

  final List<DictionaryEntry> entries;
  final bool isLoading;
  final String? error;
  final Category? selectedCategory;

  DictionaryListState copyWith({
    List<DictionaryEntry>? entries,
    bool? isLoading,
    String? error,
    Category? selectedCategory,
  }) {
    return DictionaryListState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

/// Dictionary list notifier.
/// 
/// Spec: FR-007 - Personal dictionary management
class DictionaryListNotifier extends AsyncNotifier<DictionaryListState> {
  @override
  Future<DictionaryListState> build() async {
    return const DictionaryListState(isLoading: true);
  }

  Future<void> loadEntries() async {
    state = const AsyncData(DictionaryListState(isLoading: true));

    try {
      final dictRepo = await ref.read(dictionaryRepositoryProvider.future);
      final entries = await dictRepo.findAll();
      
      state = AsyncData(DictionaryListState(entries: entries));
    } on Exception catch (e) {
      state = AsyncData(DictionaryListState(error: e.toString()));
    }
  }

  Future<void> loadEntriesByCategory(Category category) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));

    try {
      final dictRepo = await ref.read(dictionaryRepositoryProvider.future);
      final entries = await dictRepo.findByCategory(category);
      
      state = AsyncData(DictionaryListState(
        entries: entries,
        selectedCategory: category,
      ));
    } on Exception catch (e) {
      state = AsyncData(state.value!.copyWith(error: e.toString()));
    }
  }

  Future<void> searchEntries(String query) async {
    state = AsyncData(state.value!.copyWith(isLoading: true));

    try {
      final dictRepo = await ref.read(dictionaryRepositoryProvider.future);
      final entries = await dictRepo.search(query);
      
      state = AsyncData(DictionaryListState(entries: entries));
    } on Exception catch (e) {
      state = AsyncData(state.value!.copyWith(error: e.toString()));
    }
  }

  Future<DictionaryEntry?> createEntry({
    required String keyword,
    required String description,
    Category? category,
  }) async {
    try {
      final useCases = await ref.read(dictionaryUseCasesProvider.future);
      if (useCases == null) return null;

      final entry = await useCases.createEntryWithEmbedding(
        keyword: keyword,
        description: description,
        category: category,
      );
      await loadEntries();
      return entry;
    } on Exception catch (e) {
      state = AsyncData(state.value!.copyWith(error: e.toString()));
      return null;
    }
  }

  Future<DictionaryEntry?> updateEntry({
    required String id,
    String? keyword,
    String? description,
    Category? category,
  }) async {
    try {
      final useCases = await ref.read(dictionaryUseCasesProvider.future);
      if (useCases == null) return null;

      final entry = await useCases.updateEntry(
        id: id,
        keyword: keyword,
        description: description,
        category: category,
      );
      await loadEntries();
      return entry;
    } on Exception catch (e) {
      state = AsyncData(state.value!.copyWith(error: e.toString()));
      return null;
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      final useCases = await ref.read(dictionaryUseCasesProvider.future);
      if (useCases == null) return;

      await useCases.deleteEntry(id);
      await loadEntries();
    } on Exception catch (e) {
      state = AsyncData(state.value!.copyWith(error: e.toString()));
    }
  }

  void clearCategoryFilter() {
    loadEntries();
  }
}

final dictionaryListProvider = AsyncNotifierProvider<DictionaryListNotifier, DictionaryListState>(
  DictionaryListNotifier.new,
);

/// Current dictionary entry being viewed/edited - using Notifier instead of StateProvider.
class CurrentDictionaryEntryNotifier extends Notifier<DictionaryEntry?> {
  @override
  DictionaryEntry? build() => null;

  void set(DictionaryEntry? entry) {
    state = entry;
  }
}

final currentDictionaryEntryProvider = NotifierProvider<CurrentDictionaryEntryNotifier, DictionaryEntry?>(
  CurrentDictionaryEntryNotifier.new,
);

/// Category statistics.
final categoryStatsProvider = FutureProvider<Map<Category, int>>((ref) async {
  final useCases = await ref.watch(dictionaryUseCasesProvider.future);
  if (useCases == null) return {};

  return useCases.getCategoryStats();
});
