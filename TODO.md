# TODO

Version: 0.1.0
Last Updated: 2025-11-28

---

### High Priority

- [ ] Flutterプロジェクト初期化
  - `flutter create` でプロジェクト作成
  - 依存パッケージの追加
  - プロジェクト構造の設定
  - Depends on: 設計承認
  - Estimate: 2h

- [ ] データモデル実装
  - Memo, DictionaryEntry, SimilarityResult エンティティ
  - Isar スキーマ定義
  - Depends on: Flutterプロジェクト初期化
  - Estimate: 3h

- [ ] Gemini API クライアント実装
  - API接続の基本実装
  - Embedding 生成機能
  - テキスト生成機能（類似分析用）
  - エラーハンドリング
  - Depends on: Flutterプロジェクト初期化
  - Estimate: 4h

- [ ] リポジトリ層実装
  - MemoRepository
  - DictionaryRepository
  - Depends on: データモデル実装
  - Estimate: 4h

- [ ] ユースケース層実装
  - メモCRUD
  - 辞書CRUD
  - 類似度検索
  - Depends on: リポジトリ層実装, Gemini APIクライアント実装
  - Estimate: 6h

### Medium Priority

- [ ] ホーム画面UI
  - 直近メモ表示
  - ナビゲーション
  - Depends on: ユースケース層実装
  - Estimate: 4h

- [ ] メモ入力画面UI
  - テキスト入力
  - 音声入力
  - 入力中の簡易検知表示
  - Depends on: ホーム画面UI
  - Estimate: 6h

- [ ] メモ一覧・詳細画面UI
  - 一覧表示
  - 詳細表示
  - 編集機能
  - Depends on: ホーム画面UI
  - Estimate: 4h

- [ ] 辞書画面UI
  - エントリ一覧
  - 登録・編集・削除
  - Depends on: ホーム画面UI
  - Estimate: 4h

- [ ] 設定画面UI
  - フォントサイズ設定
  - 通知設定
  - APIキー設定
  - Depends on: ホーム画面UI
  - Estimate: 3h

- [ ] 類似検知通知UI
  - 保存時の通知ダイアログ
  - 類似メモへのナビゲーション
  - Depends on: メモ入力画面UI
  - Estimate: 3h

### Low Priority

- [ ] アクセシビリティ対応
  - スクリーンリーダー対応
  - セマンティクスラベル設定
  - 動的フォントサイズ対応
  - Depends on: 全UI実装完了
  - Estimate: 4h

- [ ] ユニットテスト
  - ユースケースのテスト
  - リポジトリのテスト
  - Depends on: ユースケース層実装
  - Estimate: 6h

- [ ] 統合テスト
  - E2Eテスト
  - Depends on: 全UI実装完了
  - Estimate: 4h

- [ ] ドキュメント整備
  - READMEの充実
  - セットアップガイド
  - Estimate: 2h

---

## Completed

- [x] 要件定義 - 2025-11-28
- [x] リサーチ（既存アプリ、Gemini API、UI/UX） - 2025-11-28
- [x] アーキテクチャ設計 - 2025-11-28
- [x] ADR作成 - 2025-11-28
- [x] 仕様書フォルダ構造作成 - 2025-11-28
