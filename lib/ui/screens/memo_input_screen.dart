import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../domain/entities/memo.dart';
import '../../providers/providers.dart';
import '../../providers/memo_provider.dart';
import '../widgets/widgets.dart';

/// Screen for creating or editing a memo.
/// 
/// Spec: FR-001, FR-002, FR-009 - Memo input with voice support
class MemoInputScreen extends ConsumerStatefulWidget {
  const MemoInputScreen({
    super.key,
    this.memoId,
  });

  final String? memoId;

  bool get isEditing => memoId != null;

  @override
  ConsumerState<MemoInputScreen> createState() => _MemoInputScreenState();
}

class _MemoInputScreenState extends ConsumerState<MemoInputScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _speechToText = SpeechToText();
  
  bool _isListening = false;
  bool _isSaving = false;
  bool _speechAvailable = false;
  Timer? _duplicateCheckTimer;
  List<Memo> _potentialDuplicates = [];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.isEditing) {
      _loadMemo();
    }
    _controller.addListener(_onTextChanged);
  }

  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speechToText.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('音声認識エラー: ${error.errorMsg}')),
          );
        },
      );
      setState(() {});
    } on Exception catch (e) {
      debugPrint('Speech init error: $e');
    }
  }

  Future<void> _loadMemo() async {
    final memoRepo = await ref.read(memoRepositoryProvider.future);
    final memo = await memoRepo.findById(widget.memoId!);
    if (memo != null && mounted) {
      _controller.text = memo.content;
    }
  }

  void _onTextChanged() {
    // Debounce duplicate check
    _duplicateCheckTimer?.cancel();
    _duplicateCheckTimer = Timer(
      const Duration(milliseconds: 500),
      _checkDuplicates,
    );
  }

  Future<void> _checkDuplicates() async {
    final content = _controller.text.trim();
    if (content.length < 5) {
      setState(() => _potentialDuplicates = []);
      return;
    }

    final duplicates = await ref.read(
      quickDuplicateCheckProvider(content).future,
    );

    if (mounted) {
      setState(() => _potentialDuplicates = duplicates);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _duplicateCheckTimer?.cancel();
    _speechToText.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'メモを編集' : '新しいメモ'),
        actions: [
          if (_controller.text.isNotEmpty)
            TextButton(
              onPressed: _isSaving ? null : _saveMemo,
              child: Text(
                '保存',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: theme.textTheme.titleMedium?.fontSize,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Duplicate warning
            if (_potentialDuplicates.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.warningContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '似たようなメモが${_potentialDuplicates.length}件あります',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '「${_potentialDuplicates.first.content.substring(0, _potentialDuplicates.first.content.length.clamp(0, 50))}...」',
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

            // Text input
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'ここにメモを入力してください...\n\n例：\n・明日は病院の予約があります\n・田中さんの電話番号は090-xxxx-xxxx\n・薬は朝食後に飲む',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            // Voice input button
            if (_speechAvailable)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isListening
                            ? '聞いています... 話してください'
                            : 'マイクボタンを押して話しかけてください',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    LargeIconButton(
                      onPressed: _toggleListening,
                      icon: _isListening ? Icons.stop : Icons.mic,
                      color: _isListening
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      tooltip: _isListening ? '停止' : '音声入力',
                    ),
                  ],
                ),
              ),

            // Save button
            Padding(
              padding: const EdgeInsets.all(16),
              child: LargeButton(
                onPressed: _controller.text.isEmpty || _isSaving
                    ? null
                    : _saveMemo,
                label: _isSaving ? '保存中...' : '保存する',
                icon: Icons.save,
                isLoading: _isSaving,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            final currentText = _controller.text;
            final newText = currentText.isEmpty
                ? result.recognizedWords
                : '$currentText\n${result.recognizedWords}';
            _controller.text = newText;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: newText.length),
            );
          }
        },
        localeId: 'ja_JP',
        listenMode: ListenMode.dictation,
      );
    }
  }

  Future<void> _saveMemo() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(memoListProvider.notifier);
      
      if (widget.isEditing) {
        await notifier.updateMemo(widget.memoId!, content);
      } else {
        await notifier.createMemo(content);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing ? 'メモを更新しました' : 'メモを保存しました',
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラー: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

extension on ColorScheme {
  Color get warningContainer => Colors.orange.shade100;
}
