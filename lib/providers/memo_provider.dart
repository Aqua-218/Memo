import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/memo.dart';
import 'providers.dart';

/// State for memo list.
class MemoListState {
  const MemoListState({
    this.memos = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Memo> memos;
  final bool isLoading;
  final String? error;

  MemoListState copyWith({
    List<Memo>? memos,
    bool? isLoading,
    String? error,
  }) {
    return MemoListState(
      memos: memos ?? this.memos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Memo list notifier.
/// 
/// Spec: FR-005 - Display and manage memo list
class MemoListNotifier extends AsyncNotifier<MemoListState> {
  @override
  Future<MemoListState> build() async {
    return const MemoListState(isLoading: true);
  }

  Future<void> loadMemos() async {
    state = const AsyncData(MemoListState(isLoading: true));

    try {
      final memoRepo = await ref.read(memoRepositoryProvider.future);
      final memos = await memoRepo.findAll();
      
      state = AsyncData(MemoListState(memos: memos));
    } on Exception catch (e) {
      state = AsyncData(MemoListState(error: e.toString()));
    }
  }

  Future<void> loadRecentMemos(int count) async {
    state = const AsyncData(MemoListState(isLoading: true));

    try {
      final memoRepo = await ref.read(memoRepositoryProvider.future);
      final memos = await memoRepo.findRecent(count);
      
      state = AsyncData(MemoListState(memos: memos));
    } on Exception catch (e) {
      state = AsyncData(MemoListState(error: e.toString()));
    }
  }

  Future<void> searchMemos(String keyword) async {
    state = const AsyncData(MemoListState(isLoading: true));

    try {
      final memoRepo = await ref.read(memoRepositoryProvider.future);
      final memos = await memoRepo.search(keyword);
      
      state = AsyncData(MemoListState(memos: memos));
    } on Exception catch (e) {
      state = AsyncData(MemoListState(error: e.toString()));
    }
  }

  Future<Memo?> createMemo(String content) async {
    try {
      final useCases = await ref.read(memoUseCasesProvider.future);
      if (useCases == null) return null;

      final memo = await useCases.createMemoWithAnalysis(content);
      await loadMemos();
      return memo;
    } on Exception catch (e) {
      state = AsyncData(state.value!.copyWith(error: e.toString()));
      return null;
    }
  }

  Future<Memo?> updateMemo(String id, String content) async {
    try {
      final useCases = await ref.read(memoUseCasesProvider.future);
      if (useCases == null) return null;

      final memo = await useCases.updateMemoWithAnalysis(id, content);
      await loadMemos();
      return memo;
    } on Exception catch (e) {
      state = AsyncData(state.value!.copyWith(error: e.toString()));
      return null;
    }
  }

  Future<void> deleteMemo(String id) async {
    try {
      final useCases = await ref.read(memoUseCasesProvider.future);
      if (useCases == null) return;

      await useCases.deleteMemo(id);
      await loadMemos();
    } on Exception catch (e) {
      state = AsyncData(state.value!.copyWith(error: e.toString()));
    }
  }
}

final memoListProvider = AsyncNotifierProvider<MemoListNotifier, MemoListState>(
  MemoListNotifier.new,
);

/// Current memo being viewed/edited - using Notifier instead of StateProvider.
class CurrentMemoNotifier extends Notifier<Memo?> {
  @override
  Memo? build() => null;

  void set(Memo? memo) {
    state = memo;
  }
}

final currentMemoProvider = NotifierProvider<CurrentMemoNotifier, Memo?>(
  CurrentMemoNotifier.new,
);

/// Memo input text controller state - using Notifier instead of StateProvider.
class MemoInputNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String text) {
    state = text;
  }

  void clear() {
    state = '';
  }
}

final memoInputProvider = NotifierProvider<MemoInputNotifier, String>(
  MemoInputNotifier.new,
);

/// Quick duplicate check results during input.
/// 
/// Spec: ADR-005 - Stage 1 local keyword matching
final quickDuplicateCheckProvider = FutureProvider.family<List<Memo>, String>(
  (ref, content) async {
    if (content.length < 5) return [];

    final useCases = await ref.read(memoUseCasesProvider.future);
    if (useCases == null) return [];

    return useCases.quickDuplicateCheck(content);
  },
);
