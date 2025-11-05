# GitHub Pages PWA設定ガイド

## 現在の設定

GitHub Pagesでは`/CreditCardDiary/`サブディレクトリにデプロイされています。

### ビルド設定

`.github/workflows/github-pages.yml`で以下のようにビルドされています：

```yaml
flutter build web --release --base-href="/CreditCardDiary/"
```

### manifest.jsonの設定

```json
{
  "start_url": "/CreditCardDiary/",
  "scope": "/CreditCardDiary/",
  "icons": [
    {
      "src": "/CreditCardDiary/icons/Icon-192.png",
      ...
    }
  ]
}
```

### index.htmlの設定

`$FLUTTER_BASE_HREF`プレースホルダーが使用されています。ビルド時に`/CreditCardDiary/`に置換されます。

## 404エラーの解決方法

### ステップ1: ホーム画面からアプリを削除

1. ホーム画面でアプリアイコンを**長押し**
2. **「Appを削除」**をタップ

### ステップ2: SafariのキャッシュとService Workerを完全にクリア

1. **設定** → **Safari** → **「履歴とWebサイトデータを消去」**
2. **設定** → **Safari** → **「Webサイトデータを消去」**（より強力）

### ステップ3: GitHub Actionsで再ビルド・デプロイ

コードをプッシュすると、自動的にGitHub Actionsが実行されます：

```bash
git add .
git commit -m "PWA manifest.jsonとindex.htmlをGitHub Pages用に修正"
git push origin main
```

### ステップ4: デプロイ完了を待つ

1. GitHubリポジトリの**Actions**タブでビルド完了を確認
2. 通常、数分で完了します

### ステップ5: PWAを再追加

1. Safariで`https://latte-dev-app.github.io/CreditCardDiary/`を開く
2. **共有ボタン** → **「ホーム画面に追加」**
3. 新しいアイコンが表示されることを確認

## 確認方法

### 1. manifest.jsonが正しく読み込まれているか

Safariで以下のURLを開いて確認：
- `https://latte-dev-app.github.io/CreditCardDiary/manifest.json`

以下の内容が表示されるはずです：
```json
{
  "start_url": "/CreditCardDiary/",
  "scope": "/CreditCardDiary/",
  ...
}
```

### 2. アイコンが正しく読み込まれているか

以下のURLが404エラーにならないことを確認：
- `https://latte-dev-app.github.io/CreditCardDiary/icons/Icon-192.png`
- `https://latte-dev-app.github.io/CreditCardDiary/icons/apple-icon-180.png`

### 3. アプリが正しく動作するか

1. `https://latte-dev-app.github.io/CreditCardDiary/`を開く
2. アプリが正しく表示されることを確認
3. ホーム画面に追加
4. ホーム画面からアプリを開いて、404エラーが出ないことを確認

## トラブルシューティング

### まだ404エラーが出る場合

1. **Service Workerの登録を確認**
   - Safariの開発者ツール（Mac経由）で確認
   - Service Workerが正しく登録されているか

2. **キャッシュを完全にクリア**
   - 設定 → Safari → 「Webサイトデータを消去」
   - iPhoneを再起動（念のため）

3. **manifest.jsonのパスを確認**
   - `https://latte-dev-app.github.io/CreditCardDiary/manifest.json`が正しく読み込まれるか

4. **ビルド結果を確認**
   - GitHub Actionsのログで、ビルドが成功しているか確認
   - `build/web/manifest.json`の内容を確認

### アイコンが表示されない場合

1. **アイコンファイルのパスを確認**
   - `https://latte-dev-app.github.io/CreditCardDiary/icons/Icon-192.png`が正しく読み込まれるか

2. **GitHub Pagesの設定を確認**
   - リポジトリのSettings → Pagesで、GitHub Actionsが有効になっているか

## ローカル開発時の注意

ローカルで開発する場合（`flutter run -d chrome`）は、`manifest.json`を一時的に変更する必要はありません。ビルド時に自動的に調整されます。

ただし、ローカルでテストする場合：

```bash
flutter build web --release --base-href="/CreditCardDiary/"
```

その後、`build/web`ディレクトリをローカルサーバーで開いて確認できます。

## まとめ

- ✅ `manifest.json`の`start_url`と`scope`を`/CreditCardDiary/`に設定
- ✅ アイコンのパスを`/CreditCardDiary/icons/...`に設定
- ✅ `index.html`で`$FLUTTER_BASE_HREF`を使用（ビルド時に自動置換）
- ✅ GitHub Actionsで`--base-href="/CreditCardDiary/"`でビルド

これで、GitHub Pagesで正しく動作するはずです。

