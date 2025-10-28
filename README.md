# クレジットカード使用額トラッカー

[![GitHub Pages](https://img.shields.io/badge/GitHub%20Pages-Live-brightgreen)](https://latte-dev-app.github.io/CreditCardDiary)
[![Flutter](https://img.shields.io/badge/Flutter-3.27.0-blue)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Flutter Webで動作するクレジットカードの使用額記録アプリです。

## 🌐 ライブデモ

**👉 [https://latte-dev-app.github.io/CreditCardDiary](https://latte-dev-app.github.io/CreditCardDiary)**

本アプリはGitHub Pagesでホストされており、ブラウザで直接アクセスできます。データは全てブラウザ内（localStorage）に保存されます。

## 概要

複数のクレジットカードの使用額を統合管理し、月ごとに確認できるWebアプリ。
オフラインでも動作し、データはすべてローカルに保存されます。

## 主な機能

- カード登録：クレジットカード情報の登録（名前、種類、カラー設定）
- 支出記録：年・月・金額で記録
- 月別表示：ホーム画面で月を移動して確認
- カード別表示：カード詳細で個別の支出リストを確認
- データ管理：JSON形式でのデータエクスポート/インポート機能
- ローカル保存：SharedPreferencesを使用したブラウザ内データ保存

## 使い方

### ローカル実行

```bash
# 依存関係のインストール
flutter pub get

# 開発サーバー起動
flutter run -d chrome

# またはビルドして静的ファイルを起動
flutter build web
cd build/web
python -m http.server 8000
```

### 🚀 デプロイ方法

#### GitHub Pages（現在のデプロイ方法）

**自動デプロイ:**
1. リポジトリをパブリックに変更
2. Settings → Pages → Source: GitHub Actions
3. `main`ブランチにプッシュすると自動デプロイ
4. `https://latte-dev-app.github.io/CreditCardDiary` でアクセス

**詳細な手順:**
- [docs/github-pages-deploy.md](docs/github-pages-deploy.md) を参照してください

#### ローカル開発

```bash
# 依存関係のインストール
flutter pub get

# 開発サーバー起動
flutter run -d chrome

# プロダクションビルド
flutter build web --release
```

## セットアップ

### 必要な環境

- Flutter SDK（最新版推奨）
- Chrome ブラウザ（開発用）

### インストール

```bash
# パッケージのインストール
flutter pub get

# Webアプリを起動
flutter run -d chrome
```

## 📁 プロジェクト構成

```
creditcarddiary/
├── .github/workflows/
│   └── github-pages.yml    # GitHub Pages用デプロイワークフロー
├── lib/                    # Flutterアプリのソースコード
│   ├── main.dart           # アプリケーションのエントリーポイント
│   ├── models/
│   │   └── card_model.dart # カードと支出のデータモデル
│   ├── providers/
│   │   └── card_provider.dart # 状態管理とデータ操作
│   ├── screens/
│   │   ├── main_screen.dart   # メイン画面（ナビゲーション）
│   │   ├── home_screen.dart   # ホーム画面（月別表示）
│   │   ├── card_detail_screen.dart # カード詳細画面
│   │   └── settings_screen.dart   # 設定画面
│   ├── utils/
│   │   └── local_storage.dart # ローカルストレージ操作ユーティリティ
│   └── widgets/
│       ├── monthly_chart.dart # 月別グラフウィジェット
│       └── summary_card.dart  # サマリーカードウィジェット
├── web/                    # Web用の設定ファイル
├── docs/                   # ドキュメント
│   └── github-pages-deploy.md # GitHub Pagesデプロイ手順
├── _config.yml             # GitHub Pages用設定
├── README.md               # プロジェクト説明
└── pubspec.yaml            # Flutter依存関係
```

## 使い方

1. **カード追加**：ホーム画面の「＋」ボタンからカードを追加
2. **支出記録**：カードをタップして詳細画面で支出を追加
3. **月別確認**：AppBarの矢印で月を移動して確認
4. **バックアップ**：設定画面からJSON形式でデータをエクスポート/インポート

## 技術スタック

- **フレームワーク**: Flutter（Web対応）
- **言語**: Dart
- **状態管理**: Provider
- **データ保存**: shared_preferences
- **グラフ描画**: fl_chart
- **UI**: Material Design 3

## 主な画面

### ホーム画面
- 選択月の全体合計金額表示
- カード別の月間使用額
- 左右の矢印で月を移動
- 年度プルダウンで年を選択

### カード詳細画面
- カード情報
- 最新月の合計額
- 支出一覧（削除可能）

### 設定画面
- データエクスポート（JSON形式）
- データインポート
- 全データ削除

## データ管理

データはブラウザのlocalStorageに保存されます。
- ブラウザをクリアするとデータも削除されます
- データのバックアップは設定画面からJSONでエクスポートできます
- インポート機能でデータを復元できます

## ライセンス

MIT License - 詳細は[LICENSE](LICENSE)ファイルを参照してください。

このプロジェクトは個人利用・学習目的として開発されています。

## 開発経緯

Flutter Webを使用して、ローカルで動作するクレジットカード使用額トラッカーとして開発。
