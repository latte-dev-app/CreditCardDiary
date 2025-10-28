# GitHub Pages デプロイ手順

## 📝 概要

このプロジェクトはGitHub Pagesを使用してFlutter Webアプリを公開しています。

## 🚀 デプロイまでの流れ

### 1. リポジトリをパブリックに変更
1. GitHubリポジトリページにアクセス
2. **Settings** → **General** → **Danger Zone**
3. **Change repository visibility** → **Make public**
4. リポジトリ名を入力して確認

### 2. GitHub Pagesを有効化
1. **Settings** → **Pages**
2. **Source**: **GitHub Actions** を選択
3. 設定完了

### 3. 自動デプロイ
- `main`ブランチにプッシュすると自動的にデプロイが開始されます
- GitHub ActionsでFlutter Webアプリをビルド
- ビルド完了後、GitHub Pagesに自動デプロイ

## 🔗 公開URL

```
https://latte-dev-app.github.io/CreditCardDiary
```

## 📊 デプロイフロー詳細

### GitHub Actions ワークフロー
1. **Checkout**: リポジトリのコードを取得
2. **Setup Flutter**: Flutter SDK 3.27.0をセットアップ
3. **Install dependencies**: `flutter pub get`で依存関係をインストール
4. **Build web**: `flutter build web --release`でプロダクションビルド
5. **Setup Pages**: GitHub Pagesの設定
6. **Upload artifact**: ビルド成果物をアップロード
7. **Deploy**: GitHub Pagesにデプロイ

### ビルド時間
- 初回ビルド: 3-5分
- 2回目以降: 2-3分（キャッシュが効く場合）

## 🔧 トラブルシューティング

### デプロイが失敗する場合
1. **Actions**タブでビルドログを確認
2. エラーの詳細を確認
3. 必要に応じてコードを修正して再プッシュ

### よくあるエラー
- **Flutter version mismatch**: `pubspec.yaml`のFlutterバージョンを確認
- **Dependencies error**: `flutter pub get`をローカルで実行して確認
- **Build error**: ローカルで`flutter build web --release`を実行して確認

## 📁 プロジェクト構造

```
creditcarddiary/
├── .github/workflows/
│   └── github-pages.yml    # GitHub Pages用デプロイワークフロー
├── lib/                     # Flutterアプリのソースコード
├── web/                     # Web用の設定ファイル
├── _config.yml              # GitHub Pages用設定
├── README.md                # プロジェクト説明
└── pubspec.yaml             # Flutter依存関係
```

## 🎯 開発ワークフロー

1. **ローカル開発**
   ```bash
   flutter pub get
   flutter run -d chrome
   ```

2. **変更をコミット・プッシュ**
   ```bash
   git add .
   git commit -m "feat: 新機能追加"
   git push origin main
   ```

3. **自動デプロイ**
   - GitHub Actionsが自動実行
   - 数分後にサイトが更新される

## 🔒 セキュリティ

- リポジトリはパブリックですが、個人情報は含まれていません
- データはすべてブラウザのlocalStorageに保存されます
- サーバーサイドの処理はありません

## 📈 パフォーマンス

- Flutter Webアプリは静的ファイルとして配信
- CDN経由で高速アクセス
- オフライン対応（PWA機能）

## 🆘 サポート

問題が発生した場合は、GitHubのIssuesで報告してください。
