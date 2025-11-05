# Widgetbook使い方ガイド

## 基本的な使い方

### 開発中に確認（`flutter run`）

```bash
# Widgetbookを起動
flutter run -d chrome lib/main_widgetbook.dart
```

**メリット:**
- ホットリロードが使える
- 開発中の画面をすぐに確認できる
- 特定の画面だけを確認したい場合に便利

**デメリット:**
- 通常のデバッグ実行と手順が似ている
- アプリ全体を起動する必要がある

### より効果的な使い方：Webビルドして静的にホスト

```bash
# WidgetbookをWebビルド
flutter build web --target lib/main_widgetbook.dart --release

# ビルドされたファイルをホスト
cd build/web
python -m http.server 8000
# または
npx serve build/web
```

**メリット:**
- ブラウザで直接アクセス可能（`http://localhost:8000`）
- デザイナーや非エンジニアも確認しやすい
- 本番環境に近い状態で確認できる
- 複数デバイスからアクセス可能
- 常に起動しておける（開発サーバー不要）

## Widgetbookの真のメリット

### 1. 開発効率の向上
- **特定画面の確認**: ボトムナビで遷移する必要がない
- **複数状態の確認**: UseCaseを切り替えるだけで異なる状態を確認
- **UI集中**: 機能実装に集中せず、UI確認に専念できる

### 2. デザインシステムの構築
- **コンポーネント一覧**: すべての画面を一覧で確認
- **デザインガイドライン**: テーマやスタイルの一貫性を確認
- **再利用性**: コンポーネントの再利用性を確認

### 3. チーム共有
- **デザイナーとの連携**: デザイナーが直接確認可能（Webビルド時）
- **ドキュメント化**: 画面の一覧が自動的にドキュメント化
- **レビュー**: デザインレビューが容易

## 実際の使用シーン

### 開発中（`flutter run`）
```bash
# 特定の画面だけを確認したい場合
flutter run -d chrome lib/main_widgetbook.dart
# → サイドバーから目的の画面を選択
```

### デザインレビュー（Webビルド）
```bash
# デザイナーに共有する場合
flutter build web --target lib/main_widgetbook.dart --release
# → ビルドファイルを共有
```

### CI/CDでの自動化
```bash
# GitHub Actionsなどで自動ビルド
flutter build web --target lib/main_widgetbook.dart --release
# → GitHub Pagesにデプロイ
```

## 結論

**`flutter run`でのWidgetbook:**
- 通常のデバッグ実行と確かに似ている
- ただし、特定画面の確認やUseCase切り替えには便利
- 開発中のUI確認に特化した使い方

**WebビルドでのWidgetbook:**
- 真のメリットが活きる
- デザイナーや非エンジニアとの共有が容易
- 本番環境に近い状態で確認可能
- デザインシステムとしての価値が高い

**推奨:**
- 開発中: `flutter run`で手軽に確認
- デザインレビュー/共有: Webビルドして静的にホスト

