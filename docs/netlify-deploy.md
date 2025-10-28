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
以下の設定を確認：
- Build command: `flutter build web`
- Publish directory: `build/web`

#### 4. デプロイ完了
数分でサイトが公開されます！

### 方法2: GitHub Actions経由でデプロイ

#### 1. Netlifyサイトを作成
上記の「方法1」の手順でNetlifyにサイトを作成します。

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
