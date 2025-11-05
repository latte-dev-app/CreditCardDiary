# PWA 404エラー修正ガイド

## 問題の原因

iOSでPWAをホーム画面に追加した後、404エラーが発生する主な原因：

1. **manifest.jsonのstart_urlの問題**
   - `start_url: "/"`が絶対パスになっている
   - サブディレクトリにデプロイされている場合に問題が発生

2. **Service Workerのキャッシュ**
   - 古いService Workerがキャッシュされている

3. **base hrefの不一致**
   - HTMLのbase hrefとmanifest.jsonのstart_urlが一致していない

## 修正内容

### 1. manifest.jsonの修正

```json
{
  "start_url": "./",  // "/" → "./" に変更
  "scope": "./",      // スコープを追加
  "icons": [
    {
      "src": "./icons/Icon-192.png",  // 相対パスに変更
      ...
    }
  ]
}
```

### 2. 修正後の反映方法

#### ステップ1: アプリを再ビルド

```bash
flutter clean
flutter build web --release
```

#### ステップ2: ホーム画面からアプリを削除

1. ホーム画面でアプリアイコンを**長押し**
2. **「Appを削除」**をタップ

#### ステップ3: SafariのキャッシュとService Workerをクリア

1. **設定** → **Safari** → **「履歴とWebサイトデータを消去」**
2. **設定** → **Safari** → **「Webサイトデータを消去」**（より強力）

#### ステップ4: 再追加

1. SafariでPWAのURLを開く
2. **共有ボタン** → **「ホーム画面に追加」**

## 確認方法

### 1. manifest.jsonが正しく読み込まれているか確認

SafariでPWAを開き、開発者ツール（Mac経由）で確認：

```javascript
// コンソールで実行
navigator.serviceWorker.getRegistrations().then(registrations => {
  console.log('Service Workers:', registrations);
});
```

### 2. start_urlが正しいか確認

Safariで以下のURLを直接開いてみる：
- `https://your-domain.com/`（ルート）
- `https://your-domain.com/index.html`（明示的）

### 3. ネットワークタブで確認

- `manifest.json`が正しく読み込まれているか
- `main.dart.js`が読み込まれているか
- エラーが発生していないか

## 追加のトラブルシューティング

### 方法1: 絶対パスで試す

もし相対パスで解決しない場合：

```json
{
  "start_url": "/",
  "scope": "/",
  "icons": [
    {
      "src": "/icons/Icon-192.png",
      ...
    }
  ]
}
```

### 方法2: 完全なURLで指定

```json
{
  "start_url": "https://your-domain.com/",
  "scope": "https://your-domain.com/",
  ...
}
```

### 方法3: base-hrefを指定してビルド

GitHub Pagesなどのサブディレクトリにデプロイする場合：

```bash
flutter build web --release --base-href=/CreditCardDiary/
```

この場合、`manifest.json`も：

```json
{
  "start_url": "/CreditCardDiary/",
  "scope": "/CreditCardDiary/",
  ...
}
```

## デプロイ環境別の設定

### ローカル開発サーバー（flutter run -d chrome）

```json
{
  "start_url": "./",
  "scope": "./",
  ...
}
```

### GitHub Pages（/CreditCardDiary/ サブディレクトリ）

```json
{
  "start_url": "/CreditCardDiary/",
  "scope": "/CreditCardDiary/",
  ...
}
```

ビルドコマンド：
```bash
flutter build web --release --base-href=/CreditCardDiary/
```

### ルートドメイン（/）

```json
{
  "start_url": "/",
  "scope": "/",
  ...
}
```

ビルドコマンド：
```bash
flutter build web --release
```

## よくあるエラーと解決方法

### エラー1: "Failed to register a ServiceWorker"

**原因**: Service Workerの登録に失敗

**解決方法**:
1. HTTPSでアクセスしているか確認（localhostは除く）
2. Service Workerのスコープが正しいか確認
3. ブラウザのキャッシュをクリア

### エラー2: "404 Not Found" が表示される

**原因**: start_urlが正しく解決されていない

**解決方法**:
1. `manifest.json`の`start_url`を確認
2. `index.html`の`<base href>`を確認
3. デプロイ環境に合わせて設定を調整

### エラー3: アプリは開くが白い画面

**原因**: JavaScriptファイルが読み込まれていない

**解決方法**:
1. ネットワークタブで`main.dart.js`が読み込まれているか確認
2. コンソールでエラーを確認
3. Service Workerのキャッシュをクリア

## 確認チェックリスト

- [ ] `manifest.json`の`start_url`が正しい
- [ ] `manifest.json`の`scope`が正しい
- [ ] アイコンのパスが正しい（相対パスまたは絶対パス）
- [ ] `index.html`の`<base href>`が正しい
- [ ] Service Workerが正しく登録されている
- [ ] すべてのファイルが正しく読み込まれている
- [ ] ホーム画面から削除して再追加した

## 参考リンク

- [MDN: Web App Manifest](https://developer.mozilla.org/ja/docs/Web/Manifest)
- [PWA Builder: Manifest](https://docs.pwabuilder.com/#/builder/manifest)
- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)

