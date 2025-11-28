import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category.dart';
import '../../domain/entities/dictionary_entry.dart';
import '../../providers/dictionary_provider.dart';
import '../widgets/widgets.dart';

/// Screen for managing personal dictionary.
/// 
/// Spec: FR-007 - Personal dictionary management
class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  final _searchController = TextEditingController();
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dictionaryListProvider.notifier).loadEntries();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dictState = ref.watch(dictionaryListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('個人辞書'),
        actions: [
          IconButton(
            onPressed: _showAddEntryDialog,
            icon: const Icon(Icons.add),
            tooltip: '新しい単語を追加',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '単語を検索...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          ref.read(dictionaryListProvider.notifier).loadEntries();
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  ref.read(dictionaryListProvider.notifier).loadEntries();
                } else {
                  ref.read(dictionaryListProvider.notifier).searchEntries(value);
                }
              },
            ),
          ),

          // Category filter
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildCategoryChip(null, 'すべて'),
                ...Category.values.map(
                  (category) => _buildCategoryChip(
                    category,
                    category.displayName,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Entry list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(dictionaryListProvider.notifier).loadEntries(),
              child: dictState.when(
                data: (state) {
                  if (state.isLoading) {
                    return const LoadingIndicator(message: '辞書を読み込んでいます...');
                  }

                  if (state.error != null) {
                    return ErrorMessage(
                      message: state.error!,
                      onRetry: () => ref.read(dictionaryListProvider.notifier).loadEntries(),
                    );
                  }

                  if (state.entries.isEmpty) {
                    return EmptyState(
                      icon: Icons.book_outlined,
                      title: '辞書が空です',
                      subtitle: '右上の＋ボタンから単語を追加してください',
                      action: LargeButton(
                        onPressed: _showAddEntryDialog,
                        label: '単語を追加',
                        icon: Icons.add,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: state.entries.length,
                    itemBuilder: (context, index) {
                      final entry = state.entries[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: DictionaryCard(
                          keyword: entry.keyword,
                          description: entry.description,
                          category: entry.category.displayName,
                          onTap: () => _showEditEntryDialog(entry),
                          onDelete: () => _deleteEntry(entry.id),
                        ),
                      );
                    },
                  );
                },
                loading: () => const LoadingIndicator(message: '辞書を読み込んでいます...'),
                error: (error, _) => ErrorMessage(
                  message: error.toString(),
                  onRetry: () => ref.read(dictionaryListProvider.notifier).loadEntries(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(Category? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
          if (category == null) {
            ref.read(dictionaryListProvider.notifier).loadEntries();
          } else {
            ref.read(dictionaryListProvider.notifier).loadEntriesByCategory(category);
          }
        },
      ),
    );
  }

  void _showAddEntryDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => _EntryDialog(
        onSave: (keyword, description, category) async {
          await ref.read(dictionaryListProvider.notifier).createEntry(
            keyword: keyword,
            description: description,
            category: category,
          );
        },
      ),
    );
  }

  void _showEditEntryDialog(DictionaryEntry entry) {
    showDialog<void>(
      context: context,
      builder: (_) => _EntryDialog(
        entry: entry,
        onSave: (keyword, description, category) async {
          await ref.read(dictionaryListProvider.notifier).updateEntry(
            id: entry.id,
            keyword: keyword,
            description: description,
            category: category,
          );
        },
      ),
    );
  }

  Future<void> _deleteEntry(String entryId) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: '削除確認',
      message: 'この単語を削除しますか？',
      confirmText: '削除',
      isDestructive: true,
    );

    if (confirmed) {
      await ref.read(dictionaryListProvider.notifier).deleteEntry(entryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('単語を削除しました')),
        );
      }
    }
  }
}

/// Dialog for adding/editing dictionary entries.
class _EntryDialog extends StatefulWidget {
  const _EntryDialog({
    this.entry,
    required this.onSave,
  });

  final DictionaryEntry? entry;
  final Future<void> Function(String keyword, String description, Category category) onSave;

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  final _keywordController = TextEditingController();
  final _descriptionController = TextEditingController();
  Category _selectedCategory = Category.other;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _keywordController.text = widget.entry!.keyword;
      _descriptionController.text = widget.entry!.description;
      _selectedCategory = widget.entry!.category;
    }
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.entry != null;

    return AlertDialog(
      title: Text(isEditing ? '単語を編集' : '新しい単語'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _keywordController,
              decoration: const InputDecoration(
                labelText: '単語',
                hintText: '例：田中さん',
              ),
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '説明',
                hintText: '例：近所に住んでいる友人',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Text('カテゴリ', style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Category.values.map((category) {
                return ChoiceChip(
                  label: Text(category.displayName),
                  selected: _selectedCategory == category,
                  onSelected: (_) {
                    setState(() => _selectedCategory = category);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? '保存中...' : '保存'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final keyword = _keywordController.text.trim();
    final description = _descriptionController.text.trim();

    if (keyword.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('単語と説明を入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(keyword, description, _selectedCategory);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.entry != null ? '単語を更新しました' : '単語を追加しました'),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
