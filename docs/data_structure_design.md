### 💾 使用技術

- **データ保存**：SharedPreferences（ローカル保存）
- **状態管理**：Provider（小規模アプリ想定）
- **対象アプリ**：クレカ使用額記録アプリ（Flutter Webローカル版）

---

### 🗂️ データ構造概要

### 1. クレジットカード情報（CreditCard）

| 項目名 | 型 | 説明 | 例 |
| --- | --- | --- | --- |
| `id` | `String` | 一意のカードID（タイムスタンプ） | `"1698501234567"` |
| `name` | `String` | カード名 | `"楽天カード"` |
| `type` | `String` | カード種類（プルダウンから選択） | `"Visa"` |
| `color` | `String` | カード表示色（16進数） | `"#FF6B6B"` |

**主要なカード種類**：
- Visa
- Mastercard
- American Express
- JCB
- Diners Club
- Discover
- その他（自由入力）

**主要なカード名**：
- 楽天カード
- PayPayカード
- 三井住友カード
- JALカード
- UCSカード
- その他（自由入力）

---

### 2. 支出情報（Transaction）

| 項目名 | 型 | 説明 | 例 |
| --- | --- | --- | --- |
| `id` | `String` | 一意の支出ID | `"1698501234568"` |
| `cardId` | `String` | 紐づくカードのID | `"1698501234567"` |
| `title` | `String` | 支出タイトル（固定） | `"支出"` |
| `amount` | `int` | 金額 | `3500` |
| `year` | `int` | 年 | `2025` |
| `month` | `int` | 月 | `10` |

---

### 3. データ保存構造（SharedPreferences）

```json
{
  "cards": [
    {
      "id": "c1",
      "name": "楽天カード",
      "type": "Visa",
      "color": "#FF6B6B"
    }
  ],
  "transactions": [
    {
      "id": "t1",
      "cardId": "c1",
      "title": "支出",
      "amount": 3500,
      "year": 2025,
      "month": 10
    }
  ]
}
```

---

### 4. モデルクラス（Dart例）

```dart
class CreditCard {
  final String id;
  final String name;
  final String type;
  final String color;

  CreditCard({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'color': color,
      };

  factory CreditCard.fromJson(Map<String, dynamic> json) => CreditCard(
        id: json['id'],
        name: json['name'],
        type: json['type'] ?? 'その他',
        color: json['color'],
      );

  CreditCard copyWith({
    String? id,
    String? name,
    String? type,
    String? color,
  }) {
    return CreditCard(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
    );
  }
}

class Transaction {
  final String id;
  final String cardId;
  final String title;
  final int amount;
  final int year;
  final int month;

  Transaction({
    required this.id,
    required this.cardId,
    required this.title,
    required this.amount,
    required this.year,
    required this.month,
  });

  // 年月を文字列として取得（グラフ表示用）
  String get monthString => '$year-${month.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardId': cardId,
        'title': title,
        'amount': amount,
        'year': year,
        'month': month,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        cardId: json['cardId'],
        title: json['title'],
        amount: json['amount'],
        year: json['year'] ?? DateTime.now().year,
        month: json['month'] ?? DateTime.now().month,
      );

  Transaction copyWith({
    String? id,
    String? cardId,
    String? title,
    int? amount,
    int? year,
    int? month,
  }) {
    return Transaction(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}
```

---

### 5. 主要なデータ操作方法

#### CardProvider の主なメソッド

- `addCard(CreditCard card)` - カード追加
- `updateCard(CreditCard updatedCard)` - カード更新
- `deleteCard(String cardId)` - カード削除
- `addTransaction(Transaction transaction)` - 支出追加
- `deleteTransaction(String transactionId)` - 支出削除
- `getTransactionsByMonth(int year, int month)` - 指定月の支出取得
- `getTotalByMonth(int year, int month)` - 指定月の合計計算
- `getMonthlyTotalByCardId(String cardId)` - カード別月別合計
