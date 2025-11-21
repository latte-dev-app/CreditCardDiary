class FixedCost {
  final String id;
  final String title;
  final int amount;
  final int paymentDay; // 1-31
  final String? cardId; // Optional: Link to a specific card
  final String category; // e.g., "Rent", "Subscription", "Utility"

  FixedCost({
    required this.id,
    required this.title,
    required this.amount,
    required this.paymentDay,
    this.cardId,
    this.category = 'Fixed Cost',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'paymentDay': paymentDay,
    'cardId': cardId,
    'category': category,
  };

  factory FixedCost.fromJson(Map<String, dynamic> json) => FixedCost(
    id: json['id'],
    title: json['title'],
    amount: json['amount'],
    paymentDay: json['paymentDay'],
    cardId: json['cardId'],
    category: json['category'] ?? 'Fixed Cost',
  );

  FixedCost copyWith({
    String? id,
    String? title,
    int? amount,
    int? paymentDay,
    String? cardId,
    String? category,
  }) {
    return FixedCost(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paymentDay: paymentDay ?? this.paymentDay,
      cardId: cardId ?? this.cardId,
      category: category ?? this.category,
    );
  }
}
