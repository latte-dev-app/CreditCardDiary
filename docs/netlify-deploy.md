# Netlify デプロイ手順

Netlifyはプライベートリポジトリでも無料で使える、簡単なデプロイプラットフォームです。

## 📝 Netlifyでのデプロイ方法

Netlifyへのデプロイ方法は2つあります：

### 方法1: Netlify UIで自動デプロイ（推奨）

#### 1. Netlifyアカウント作成
1. https://www.netlify.com にアクセス
2. GitHubアカウントでサインアップ

#### 2. サイト作成
1. "Add new site" → "Import an existing project"
2. GitHubを選択
3. リポジトリを選択
4. ビルド設定が自動検出される

#### 3. デプロイ設定確認
Netlifyが自動検出する設定：
- Build command: `bash ./scripts/netlify_build.sh`
- Publish directory: `build/web`
- Build image: `focal` (Ubuntu 20.04ベースの安定版)

**重要**: 
- `scripts/netlify_build.sh` スクリプトが自動的にFlutter SDKをインストールしてからビルドします
- 安定版ビルド環境（focal）を使用してビルドエラーを回避します
- Node.js 18を使用して互換性を確保します

#### 4. デプロイ完了
数分でサイトが公開されます！

### 方法2: GitHub Actions経由でデプロイ（推奨）

**注意**: Netlifyのビルド環境に問題があるため、GitHub ActionsでビルドしてNetlifyにデプロイする方法を推奨します。

#### 1. Netlifyサイトを作成
1. https://www.netlify.com にアクセス
2. "Add new site" → "Import an existing project"
3. GitHubを選択
4. リポジトリを選択
5. **重要**: ビルド設定は無効化します（GitHub Actionsでビルドするため）

#### 2. Netlify認証情報を取得
1. https://app.netlify.com にアクセス
2. プロフィール画像 → "User settings" → "Applications"
3. "New access token" をクリックしてトークンを作成（名前: `creditcarddiary`）
4. トークンをコピー（安全に保管）

#### 3. Site IDを取得
1. https://app.netlify.com にアクセス
2. サイトを選択
3. "Site settings" → "General" → "Site details"
4. "Site ID" をコピー

#### 4. GitHub Secretsを設定
1. GitHubリポジトリページ → "Settings" → "Secrets and variables" → "Actions"
2. "New repository secret" をクリック
3. 以下の2つのシークレットを追加：

   **NETLIFY_AUTH_TOKEN**
   - Name: `NETLIFY_AUTH_TOKEN`
   - Value: 手順2で取得した認証トークン

   **NETLIFY_SITE_ID**
   - Name: `NETLIFY_SITE_ID`
   - Value: 手順3で取得したSite ID

#### 5. ワークフローの動作確認
- `main`ブランチにpushすると自動でデプロイされます
- Pull Requestを作成するとプレビューデプロイが作成されます
- GitHub Actionsでビルドが成功してからNetlifyにデプロイされます

## 🔗 公開URL
`https://your-app-name.netlify.app`

## 📊 GitHub Pagesとの比較

| 機能 | GitHub Pages | Netlify |
|------|-------------|---------|
| プライベート対応 | 有料プラン必要 | 無料 |
| HTTPS | 自動 | 自動 |
| カスタムドメイン | 可能 | 可能 |
| 自動デプロイ | Actionsが必要 | 組み込み + Actions対応 |
| CI/CD | Actionsが必要 | 組み込み + Actions対応 |
| フォーム機能 | 不可 | 無料 |
| プレビューデプロイ | 不可 | PR毎に作成 |

## 💡 おすすめ
**Netlifyを推奨します！**
- プライベートリポジトリで無料
- 設定が簡単
- デプロイが高速
- PR毎にプレビュー環境が自動生成される

## 🔧 技術的な詳細

### Netlifyでのビルドプロセス

1. **Flutter SDKのインストール**: `.netlify/build.sh` スクリプトが自動的にFlutter SDKをダウンロード・インストールします
2. **依存関係のインストール**: `flutter pub get` で依存パッケージを取得します
3. **Webビルド**: `flutter build web --release` でプロダクション用にビルドします
4. **デプロイ**: `build/web` ディレクトリが自動的にデプロイされます

### ビルド時間
- 初回ビルド: 5-10分（Flutter SDKのダウンロード含む）
- 2回目以降: 3-5分（キャッシュが効く場合）

### トラブルシューティング

**エラー: "flutter: command not found"**
- `scripts/netlify_build.sh` スクリプトが正しく実行されているか確認
- Netlifyのビルドログを確認してFlutter SDKがインストールされているか確認

**エラー: "mkdir: command not found" や "touch: command not found"**
- Netlifyの新しいビルド環境（noble）の問題です
- `netlify.toml`で安定版ビルド環境（focal）を指定しています
- キャッシュをクリアして再デプロイしてください

**ビルドが非常に遅い**
- Flutter SDKのダウンロードは初回のみ時間がかかります
- Netlifyのキャッシュを有効にすることを検討してください

**Node.js関連のエラー**
- `package.json`でNode.js 18を指定しています
- `netlify.toml`でもNODE_VERSION = "18"を設定しています
