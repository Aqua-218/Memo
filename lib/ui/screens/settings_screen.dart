import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/font_size.dart';
import '../../providers/providers.dart';
import '../widgets/widgets.dart';

/// Settings screen.
/// 
/// Spec: FR-010, FR-011 - Settings management
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(settingsProvider);
    final isApiKeySet = ref.watch(isApiKeySetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // API Key Section
            _buildSectionHeader(theme, 'API設定'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isApiKeySet.value == true
                              ? Icons.check_circle
                              : Icons.warning,
                          color: isApiKeySet.value == true
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Gemini APIキー',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isApiKeySet.value == true
                          ? 'APIキーが設定されています'
                          : 'APIキーが設定されていません',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _showApiKeyDialog(context, ref),
                            child: Text(
                              isApiKeySet.value == true
                                  ? 'キーを変更'
                                  : 'キーを設定',
                            ),
                          ),
                        ),
                        if (isApiKeySet.value == true) ...[
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => _deleteApiKey(context, ref),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                              side: BorderSide(color: theme.colorScheme.error),
                            ),
                            child: const Text('削除'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Display Section
            _buildSectionHeader(theme, '表示設定'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.text_fields),
                    title: const Text('文字サイズ'),
                    subtitle: Text(settings.fontSize.displayName),
                    onTap: () => _showFontSizeDialog(context, ref, settings.fontSize),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.format_list_numbered),
                    title: const Text('ホームに表示するメモ数'),
                    subtitle: Text('${settings.recentMemoCount}件'),
                    onTap: () => _showRecentMemoCountDialog(
                      context,
                      ref,
                      settings.recentMemoCount,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Notification Section
            _buildSectionHeader(theme, '通知設定'),
            Card(
              child: SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('重複メモの通知'),
                subtitle: const Text('似たメモがある場合に通知します'),
                value: settings.notificationEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).updateNotificationEnabled(value);
                },
              ),
            ),

            const SizedBox(height: 24),

            // About Section
            _buildSectionHeader(theme, 'アプリ情報'),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('バージョン'),
                    subtitle: const Text('1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('使い方'),
                    onTap: () => _showHelpDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorMessage(message: error.toString()),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showApiKeyDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('APIキーを入力'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google AI StudioでGemini APIキーを取得してください。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'APIキー',
                hintText: 'AIza...',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await saveApiKey(ref, result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('APIキーを保存しました')),
        );
      }
    }
  }

  Future<void> _deleteApiKey(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'APIキーの削除',
      message: 'APIキーを削除しますか？\nAI機能が使用できなくなります。',
      confirmText: '削除',
      isDestructive: true,
    );

    if (confirmed) {
      await deleteApiKey(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('APIキーを削除しました')),
        );
      }
    }
  }

  Future<void> _showFontSizeDialog(
    BuildContext context,
    WidgetRef ref,
    FontSize currentSize,
  ) async {
    final result = await showDialog<FontSize>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('文字サイズを選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: FontSize.values.map((size) {
            return RadioListTile<FontSize>(
              title: Text(
                size.displayName,
                style: TextStyle(fontSize: 16 * size.scaleFactor),
              ),
              value: size,
              groupValue: currentSize,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(settingsProvider.notifier).updateFontSize(result);
    }
  }

  Future<void> _showRecentMemoCountDialog(
    BuildContext context,
    WidgetRef ref,
    int currentCount,
  ) async {
    final counts = [3, 5, 10, 15, 20];
    
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('表示するメモ数'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: counts.map((count) {
            return RadioListTile<int>(
              title: Text('$count件'),
              value: count,
              groupValue: currentCount,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(settingsProvider.notifier).updateRecentMemoCount(result);
    }
  }

  Future<void> _showHelpDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使い方'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📝 メモを書く',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('画面下の「メモを書く」ボタンをタップして、新しいメモを作成できます。'),
              SizedBox(height: 16),
              Text(
                '🎤 音声入力',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('マイクボタンを押して話すと、音声でメモを入力できます。'),
              SizedBox(height: 16),
              Text(
                '🔍 重複検出',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('似たようなメモがある場合、自動的にお知らせします。'),
              SizedBox(height: 16),
              Text(
                '📚 個人辞書',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('よく使う言葉や人の名前を登録しておくと、メモの理解に役立ちます。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
