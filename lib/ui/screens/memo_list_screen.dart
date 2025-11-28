import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/memo_provider.dart';
import '../widgets/widgets.dart';
import 'memo_input_screen.dart';

/// Screen displaying all memos.
/// 
/// Spec: FR-005, FR-006 - Memo list with search
class MemoListScreen extends ConsumerStatefulWidget {
  const MemoListScreen({super.key});

  @override
  ConsumerState<MemoListScreen> createState() => _MemoListScreenState();
}

class _MemoListScreenState extends ConsumerState<MemoListScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoListProvider.notifier).loadMemos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memoListState = ref.watch(memoListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'メモを検索...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  if (value.isEmpty) {
                    ref.read(memoListProvider.notifier).loadMemos();
                  } else {
                    ref.read(memoListProvider.notifier).searchMemos(value);
                  }
                },
              )
            : const Text('メモ一覧'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(memoListProvider.notifier).loadMemos();
                }
              });
            },
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            tooltip: _isSearching ? '検索を閉じる' : '検索',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(memoListProvider.notifier).loadMemos(),
        child: memoListState.when(
          data: (state) {
            if (state.isLoading) {
              return const LoadingIndicator(message: 'メモを読み込んでいます...');
            }

            if (state.error != null) {
              return ErrorMessage(
                message: state.error!,
                onRetry: () => ref.read(memoListProvider.notifier).loadMemos(),
              );
            }

            if (state.memos.isEmpty) {
              return EmptyState(
                icon: Icons.note_outlined,
                title: _isSearching && _searchController.text.isNotEmpty
                    ? '検索結果がありません'
                    : 'メモがありません',
                subtitle: _isSearching
                    ? '他のキーワードで検索してみてください'
                    : '新しいメモを作成してください',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: state.memos.length,
              itemBuilder: (context, index) {
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
            );
          },
          loading: () => const LoadingIndicator(message: 'メモを読み込んでいます...'),
          error: (error, _) => ErrorMessage(
            message: error.toString(),
            onRetry: () => ref.read(memoListProvider.notifier).loadMemos(),
          ),
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
    ).then((_) {
      // Reload memos after returning from edit screen
      ref.read(memoListProvider.notifier).loadMemos();
    });
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
