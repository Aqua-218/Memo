import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';
import '../../providers/memo_provider.dart';
import '../widgets/widgets.dart';
import 'memo_input_screen.dart';
import 'memo_list_screen.dart';
import 'dictionary_screen.dart';
import 'settings_screen.dart';

/// Home screen with bottom navigation.
/// 
/// Spec: FR-005 - Home screen with recent memos
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    _HomeTab(),
    MemoListScreen(),
    DictionaryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note_outlined),
            activeIcon: Icon(Icons.note),
            label: 'メモ一覧',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: '辞書',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMemoInput(context),
        icon: const Icon(Icons.add, size: 28),
        label: const Text('メモを書く'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _openMemoInput(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MemoInputScreen(),
      ),
    );
  }
}

/// Home tab content.
class _HomeTab extends ConsumerStatefulWidget {
  const _HomeTab();

  @override
  ConsumerState<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<_HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentMemos();
    });
  }

  Future<void> _loadRecentMemos() async {
    final settings = await ref.read(settingsProvider.future);
    await ref.read(memoListProvider.notifier).loadRecentMemos(
      settings.recentMemoCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memoListState = ref.watch(memoListProvider);
    final isApiKeySet = ref.watch(isApiKeySetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('おもいだし'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecentMemos,
        child: CustomScrollView(
          slivers: [
            // API key warning
            isApiKeySet.when(
              data: (isSet) => isSet
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'APIキーが設定されていません。\n設定画面でAPIキーを入力してください。',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Welcome message
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'こんにちは！',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '今日も元気にメモを取りましょう',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent memos header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '最近のメモ',
                      style: theme.textTheme.titleMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        // Switch to memo list tab
                      },
                      child: const Text('すべて見る'),
                    ),
                  ],
                ),
              ),
            ),

            // Memo list
            memoListState.when(
              data: (state) {
                if (state.isLoading) {
                  return const SliverFillRemaining(
                    child: LoadingIndicator(message: 'メモを読み込んでいます...'),
                  );
                }

                if (state.error != null) {
                  return SliverFillRemaining(
                    child: ErrorMessage(
                      message: state.error!,
                      onRetry: _loadRecentMemos,
                    ),
                  );
                }

                if (state.memos.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.note_add_outlined,
                      title: 'まだメモがありません',
                      subtitle: '下のボタンから最初のメモを書いてみましょう',
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final memo = state.memos[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: MemoCard(
                          content: memo.content,
                          date: memo.createdAt,
                          onTap: () => _openMemoDetail(memo.id),
                          onDelete: () => _deleteMemo(memo.id),
                        ),
                      );
                    },
                    childCount: state.memos.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: LoadingIndicator(message: 'メモを読み込んでいます...'),
              ),
              error: (error, _) => SliverFillRemaining(
                child: ErrorMessage(
                  message: error.toString(),
                  onRetry: _loadRecentMemos,
                ),
              ),
            ),

            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  void _openMemoDetail(String memoId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MemoInputScreen(memoId: memoId),
      ),
    );
  }

  Future<void> _deleteMemo(String memoId) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: '削除確認',
      message: 'このメモを削除しますか？\nこの操作は取り消せません。',
      confirmText: '削除',
      isDestructive: true,
    );

    if (confirmed) {
      await ref.read(memoListProvider.notifier).deleteMemo(memoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メモを削除しました')),
        );
      }
    }
  }
}
