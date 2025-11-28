// Personal Reminder App - Widget Tests
//
// 高齢者向けAI記憶サポートメモアプリのテスト

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:personal_reminder/main.dart';

void main() {
  testWidgets('App smoke test - アプリが正常に起動する', (WidgetTester tester) async {
    // ProviderScope でラップしてアプリをビルド
    await tester.pumpWidget(
      const ProviderScope(
        child: PersonalReminderApp(),
      ),
    );

    // アプリが起動し、ホーム画面が表示されることを確認
    await tester.pumpAndSettle();
    
    // 基本的なUIが存在することを確認
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
