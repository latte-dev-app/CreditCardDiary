import 'package:flutter/foundation.dart';
import '../domain/card_model.dart';
import '../infrastructure/local_storage.dart';

class CardProvider with ChangeNotifier {
  List<CreditCard> _cards = [];
  List<Transaction> _transactions = [];

  List<CreditCard> get cards => _cards;
  List<Transaction> get transactions => _transactions;

  // 初期化：データを読み込む
  Future<void> init() async {
    await loadData();
  }

  // カード追加
  Future<void> addCard(CreditCard card) async {
    _cards.add(card);
    await saveData();
    notifyListeners();
  }

  // カード更新（支出は保持する）
  Future<void> updateCard(CreditCard updatedCard) async {
    final index = _cards.indexWhere((card) => card.id == updatedCard.id);
    if (index != -1) {
      _cards[index] = updatedCard;
      await saveData();
      notifyListeners();
    }
  }

  // カード削除
  Future<void> deleteCard(String cardId) async {
    _cards.removeWhere((card) => card.id == cardId);
    _transactions.removeWhere((transaction) => transaction.cardId == cardId);
    await saveData();
    notifyListeners();
  }

  // 全データ削除
  Future<void> deleteAllData() async {
    _cards.clear();
    _transactions.clear();
    await saveData();
    notifyListeners();
  }

  // 支出追加
  Future<void> addTransaction(Transaction transaction) async {
    _transactions.add(transaction);
    await saveData();
    notifyListeners();
  }

  // 支出削除
  Future<void> deleteTransaction(String transactionId) async {
    _transactions.removeWhere((t) => t.id == transactionId);
    await saveData();
    notifyListeners();
  }

  // カードIDでフィルタリング
  List<Transaction> getTransactionsByCardId(String cardId) {
    return _transactions.where((t) => t.cardId == cardId).toList();
  }

  // カード別の合計金額を計算
  int getTotalByCardId(String cardId) {
    return _transactions
        .where((t) => t.cardId == cardId)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // カードの月別合計を計算
  Map<String, int> getMonthlyTotalByCardId(String cardId) {
    final Map<String, int> monthlyTotal = {};
    for (final transaction in _transactions.where((t) => t.cardId == cardId)) {
      final monthKey = '${transaction.year}-${transaction.month.toString().padLeft(2, '0')}';
      monthlyTotal[monthKey] = (monthlyTotal[monthKey] ?? 0) + transaction.amount;
    }
    return monthlyTotal;
  }

  // 指定月の支出を取得
  List<Transaction> getTransactionsByMonth(int year, int month) {
    return _transactions.where((t) => 
      t.year == year && t.month == month
    ).toList();
  }

  // 指定月の合計金額を計算
  int getTotalByMonth(int year, int month) {
    return _transactions
        .where((t) => t.year == year && t.month == month)
        .fold(0, (sum, t) => sum + t.amount);
  }

  // 全体の合計金額
  int getTotalAmount() {
    return _transactions.fold(0, (sum, t) => sum + t.amount);
  }

  // 全体の平均金額
  double getAverageAmount() {
    if (_transactions.isEmpty) return 0;
    return getTotalAmount() / _transactions.length;
  }

  // データ保存
  Future<void> saveData() async {
    await LocalStorage.saveData(_cards, _transactions);
  }

  // データ読み込み
  Future<void> loadData() async {
    final data = await LocalStorage.loadData();
    _cards = data['cards'] ?? [];
    _transactions = data['transactions'] ?? [];
    notifyListeners();
  }

  // データエクスポート（JSON文字列）
  String exportToJson() {
    return LocalStorage.exportToJson(_cards, _transactions);
  }

  // データインポート（JSON文字列から）
  Future<void> importFromJson(String jsonString) async {
    final data = LocalStorage.importFromJson(jsonString);
    _cards = data['cards'] ?? [];
    _transactions = data['transactions'] ?? [];
    await saveData();
    notifyListeners();
  }
}

