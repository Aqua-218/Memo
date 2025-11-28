import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/entities/font_size.dart';
import 'providers/providers.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: PersonalReminderApp(),
    ),
  );
}

/// Main application widget.
/// 
/// Spec: Personal Reminder - AI Memory Support Memo App
class PersonalReminderApp extends ConsumerWidget {
  const PersonalReminderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) => MaterialApp(
        title: 'おもいだし',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(settings.fontSize),
        home: const HomeScreen(),
        builder: (context, child) {
          // Apply font scale based on settings
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(settings.fontSize.scaleFactor),
            ),
            child: child!,
          );
        },
      ),
      loading: () => MaterialApp(
        title: 'おもいだし',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(FontSize.medium),
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => MaterialApp(
        title: 'おもいだし',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(FontSize.medium),
        home: Scaffold(
          body: Center(
            child: Text('エラーが発生しました: $error'),
          ),
        ),
      ),
    );
  }
}
