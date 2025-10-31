// クレジットカード情報と支出情報のモデルクラス

class CreditCard {
  final String id;
  final String name;
  final String type; // カード種類（Visa, Mastercard, その他）
  final String color;
  final String? imagePath; // カード画像のパス
  final int? closingDay; // 締め日（1-31）
  final int? paymentDay; // 支払日（1-31）

  CreditCard({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    this.imagePath,
    this.closingDay,
    this.paymentDay,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'color': color,
        'imagePath': imagePath,
        'closingDay': closingDay,
        'paymentDay': paymentDay,
      };

  factory CreditCard.fromJson(Map<String, dynamic> json) => CreditCard(
        id: json['id'],
        name: json['name'],
        type: json['type'] ?? 'その他',
        color: json['color'],
        imagePath: json['imagePath'],
        closingDay: json['closingDay'],
        paymentDay: json['paymentDay'],
      );

  CreditCard copyWith({
    String? id,
    String? name,
    String? type,
    String? color,
    String? imagePath,
    int? closingDay,
    int? paymentDay,
  }) {
    return CreditCard(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      closingDay: closingDay ?? this.closingDay,
      paymentDay: paymentDay ?? this.paymentDay,
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

  factory Transaction.fromJson(Map<String, dynamic> json) {
    int year;
    int month;
    
    if (json['year'] != null) {
      year = json['year'];
    } else if (json['date'] != null) {
      year = int.parse(json['date'].toString().split('-')[0]);
    } else {
      year = DateTime.now().year;
    }
    
    if (json['month'] != null) {
      month = json['month'];
    } else if (json['date'] != null) {
      month = int.parse(json['date'].toString().split('-')[1]);
    } else {
      month = DateTime.now().month;
    }
    
    return Transaction(
      id: json['id'],
      cardId: json['cardId'],
      title: json['title'],
      amount: json['amount'],
      year: year,
      month: month,
    );
  }

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
