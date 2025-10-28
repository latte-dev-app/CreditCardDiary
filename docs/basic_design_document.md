# クレカ使用額記録アプリ 基本設計書（ドラフト）

### 🧱 1. システム構成図（簡易）

```
┌─────────────────────────────┐
│             Flutter Webアプリ（PWA対応）             │
│─────────────────────────────│
│  プレゼンテーション層：UI（Flutter Widgets）        │
│  ロジック層：Provider or Riverpod（状態管理）       │
│  データ層：SharedPreferences（ローカル保存）         │
│  グラフ描画：fl_chartパッケージ                     │
└─────────────────────────────┘

```

---

### 📦 2. データ構造設計

### ① モデル構造（Dartクラス）

```dart
// クレジットカード情報
class CreditCard {
  final String id;         // UUID
  final String name;       // カード名
  final String type;       // 種類（Visa, Masterなど）
  final String imagePath;  // 画像パス（ローカル or asset）
  final List<UsageRecord> records;

  CreditCard({
    required this.id,
    required this.name,
    required this.type,
    required this.imagePath,
    this.records = const [],
  });
}

// 使用額記録
class UsageRecord {
  final String month;   // "2025-10" など
  final double amount;  // 使用額

  UsageRecord({
    required this.month,
    required this.amount,
  });
}

```

### ② 保存形式（SharedPreferences）

- 保存キー：`"cards_data"`
- 保存内容：JSON文字列（`List<CreditCard>`をjsonEncodeして保存）

```json
[
  {
    "id": "uuid-1",
    "name": "楽天カード",
    "type": "Visa",
    "imagePath": "assets/cards/rakuten.png",
    "records": [
      {"month": "2025-10", "amount": 50000},
      {"month": "2025-09", "amount": 45000}
    ]
  }
]

```

---

### 📲 3. UI遷移図（画面構成）

```
┌─── ホーム画面 ───┐
│ 各カードの月別金額概要   │
│ 合計／平均／グラフ概要   │
└────┬────────────┘
      │
      ▼
┌── カード詳細画面 ──┐
│ カード情報／過去記録表示 │
│ 月別推移グラフ           │
│ 「使用額を追加」ボタン   │
└────┬────────────┘
      │
      ▼
┌── 使用額入力画面 ──┐
│ 月・金額の入力        │
│ 登録・キャンセル      │
└────────────────┘

▼（ボトムナビ）
[ホーム] [カード一覧] [設定]

```

---

### 🎨 4. 画面レイアウト案（概要）

### 🏠 ホーム画面

- AppBar：「クレカ使用額トラッカー」
- 各カードをカードUIで表示（カード画像 + 合計使用額）
- 「＋カード追加」ボタン（FloatingActionButton）
- 全体の合計金額と平均を上部に表示
- 簡易グラフ（fl_chartで棒グラフ）

### 💳 カード一覧画面

- 登録済みカードのリスト表示
- 各カードをタップ → 詳細画面へ遷移

### 📈 カード詳細画面

- グラフ（fl_chart）で月ごとの推移
- 「使用額を追加」ボタン（Dialogで入力）

### ⚙️ 設定画面

- データバックアップ（JSONエクスポート）
- データインポート（ファイル選択）

---

### ⚙️ 5. 状態管理設計（簡易）

- 状態管理ライブラリ：`provider`
- ViewModel層で `CardRepository` を管理
    - `addCard()`, `updateUsage()`, `saveToPrefs()` などを担当

---

### 🧮 6. 非機能要件（再掲＋Flutter向け）