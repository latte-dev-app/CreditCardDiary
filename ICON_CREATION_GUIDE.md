# PWAアイコン作成ガイド

## 作成済みファイル

`web/icons/icon-base.svg` - ベースとなるSVGアイコンファイルを作成しました。

## アイコン生成手順

### 方法1: オンラインツールを使用（推奨）

#### ステップ1: SVGからPNGに変換

以下のオンラインツールを使用して、SVGをPNGに変換できます：

1. **CloudConvert** (https://cloudconvert.com/svg-to-png)
   - `icon-base.svg`をアップロード
   - サイズを指定して変換（192x192、512x512など）
   - PNG形式でダウンロード

2. **Convertio** (https://convertio.co/svg-png/)
   - SVGをアップロード
   - 解像度を指定（192x192、512x512）
   - 変換してダウンロード

#### ステップ2: PWAアイコン生成ツールを使用

以下のツールで、1つの画像から必要なサイズを自動生成：

1. **PWA Asset Generator** (https://github.com/elegantapp/pwa-asset-generator)
   - オンライン版: https://www.pwabuilder.com/imageGenerator
   - または、Node.jsでインストール:
     ```bash
     npx pwa-asset-generator icon-base.svg ./web/icons --icon-only --path-override icons
     ```

2. **RealFaviconGenerator** (https://realfavicongenerator.net/)
   - 512x512のPNG画像をアップロード
   - 必要なサイズを自動生成
   - ダウンロードして配置

### 方法2: 手動でサイズ変更

1. **GIMP** (無料) または **Photoshop** を使用
   - `icon-base.svg`を開く
   - 各サイズにリサイズ（192x192、512x512）
   - PNG形式でエクスポート

2. **オンライン画像リサイザー**を使用
   - https://www.iloveimg.com/resize-image
   - https://www.resizepixel.com/
   - SVGをPNGに変換後、各サイズにリサイズ

### 必要なファイル

以下のファイルを `web/icons/` ディレクトリに配置してください：

- `Icon-192.png` (192x192px)
- `Icon-512.png` (512x512px)
- `Icon-maskable-192.png` (192x192px、周囲に20%余白)
- `Icon-maskable-512.png` (512x512px、周囲に20%余白)
- `favicon.png` (32x32px または 64x64px)

### Maskableアイコンの作成

Maskableアイコンは、周囲に約20%の余白（セーフゾーン）が必要です。

1. 512x512pxの画像を作成
2. 中央の80%（約410x410px）に主要デザインを配置
3. 周囲に余白を確保

### 推奨オンラインツール一覧

1. **PWA Builder Image Generator**
   - URL: https://www.pwabuilder.com/imageGenerator
   - 特徴: PWA専用、自動生成、無料

2. **Canva**
   - URL: https://www.canva.com/
   - 特徴: デザイン編集、テンプレート豊富

3. **Figma**
   - URL: https://www.figma.com/
   - 特徴: プロフェッショナルデザインツール、無料プランあり

4. **CloudConvert**
   - URL: https://cloudconvert.com/
   - 特徴: ファイル形式変換、高品質

## アイコン配置後の確認

1. ファイルを `web/icons/` に配置
2. `flutter clean`
3. `flutter build web`
4. ブラウザで確認

## デザインのカスタマイズ

`icon-base.svg` を編集することで、以下の変更が可能です：

- 色の変更（グラデーション）
- カードデザインの調整
- 背景の変更
- 追加要素の追加

SVGエディタ（Inkscape、Adobe Illustrator等）で編集してください。

