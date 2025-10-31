import 'package:flutter/foundation.dart';
import '../domain/card_model.dart' as dm;
import '../infrastructure/local_storage.dart';
import '../infrastructure/repositories/card_repository.dart';

class CardProvider with ChangeNotifier {
  late final CardRepository _cardRepo = SharedPreferencesCardRepository();
  late final TransactionRepository _txRepo = SharedPreferencesTransactionRepository();

  List<dm.CreditCard> _cards = [];
  List<dm.Transaction> _transactions = [];
  bool _useBillingMonth = false; // 請求月ベース集計フラグ

  List<dm.CreditCard> get cards => _cards;
  List<dm.Transaction> get transactions => _transactions;
  bool get useBillingMonth => _useBillingMonth;

  // 初期化：データ読み込み
  Future<void> init() async {
    await _loadAggregationMode();
    await _loadFromDb();
  }

  // 集計モードの読み込み
  Future<void> _loadAggregationMode() async {
    final prefs = await LocalStorage.getSharedPreferences();
    _useBillingMonth = prefs.getBool('use_billing_month') ?? false;
  }

  // 集計モードの保存
  Future<void> _saveAggregationMode() async {
    final prefs = await LocalStorage.getSharedPreferences();
    await prefs.setBool('use_billing_month', _useBillingMonth);
  }

  // 集計モードの切替
  Future<void> toggleAggregationMode() async {
    _useBillingMonth = !_useBillingMonth;
    await _saveAggregationMode();
    notifyListeners();
  }

  Future<void> _loadFromDb() async {
    final c = await _cardRepo.getAllCards();
    final t = await _txRepo.getAllTransactions();
    _cards = c;
    _transactions = t;
    notifyListeners();
  }

  Future<void> _saveData() async {
    await LocalStorage.saveData(_cards, _transactions);
  }

  // カード追加/更新/削除
  Future<void> addCard(dm.CreditCard card) async {
    await _cardRepo.upsertCard(card);
    await _loadFromDb();
  }

  Future<void> updateCard(dm.CreditCard updatedCard) async {
    await _cardRepo.upsertCard(updatedCard);
    await _loadFromDb();
  }

  Future<void> deleteCard(String cardId) async {
    await _cardRepo.deleteCard(cardId);
    await _loadFromDb();
  }

  // 全データ削除
  Future<void> deleteAllData() async {
    _cards.clear();
    _transactions.clear();
    await _saveData();
    notifyListeners();
  }

  // 支出追加/更新/削除
  Future<void> addTransaction(dm.Transaction transaction) async {
    await _txRepo.upsertTransaction(transaction);
    await _loadFromDb();
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _txRepo.deleteTransaction(transactionId);
    await _loadFromDb();
  }

  Future<void> updateTransaction(dm.Transaction updatedTransaction) async {
    await _txRepo.upsertTransaction(updatedTransaction);
    await _loadFromDb();
  }

  // カードIDでフィルタリング
  List<dm.Transaction> getTransactionsByCardId(String cardId) {
    return _transactions.where((t) => t.cardId == cardId).toList();
  }

  // カード別の合計金額を計算（カレンダー月）
  int getTotalByCardId(String cardId) {
    return _transactions
        .where((t) => t.cardId == cardId)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  // カードの月別合計（カレンダー月）
  Map<String, int> getMonthlyTotalByCardId(String cardId) {
    final Map<String, int> monthlyTotal = {};
    for (final transaction in _transactions.where((t) => t.cardId == cardId)) {
      final monthKey = '${transaction.year}-${transaction.month.toString().padLeft(2, '0')}';
      monthlyTotal[monthKey] = (monthlyTotal[monthKey] ?? 0) + transaction.amount;
    }
    return monthlyTotal;
  }

  // 指定月の支出（カレンダー月）
  List<dm.Transaction> getTransactionsByMonth(int year, int month) {
    return _transactions.where((t) => 
      t.year == year && t.month == month
    ).toList();
  }

  // 指定月の合計金額（カレンダー月）
  int getTotalByMonth(int year, int month) {
    return _transactions
        .where((t) => t.year == year && t.month == month)
        .fold<int>(0, (sum, t) => sum + t.amount);
  }

  // 指定月のカード別合計を取得
  Map<String, int> getCardTotalsByMonth(int year, int month) {
    final Map<String, int> cardTotals = {};
    final monthTransactions = getTransactionsByMonth(year, month);
    
    for (final transaction in monthTransactions) {
      cardTotals[transaction.cardId] = 
          (cardTotals[transaction.cardId] ?? 0) + transaction.amount;
    }
    
    return cardTotals;
  }

  // ---- 請求月（締め日）ベース集計（簡易近似） ----
  // 近似: closingDayが設定されているカードの取引は、丸ごと翌月の請求月として扱う。
  // （取引日に日付が無いための近似。closingDay未設定/31日はカレンダー月のまま）
  Map<String, int> getBillingMonthlyTotalByCardId(String cardId) {
    final Map<String, int> monthlyTotal = {};
    final card = _cards.firstWhere((c) => c.id == cardId, orElse: () => dm.CreditCard(id: '', name: '', type: '', color: '#000000'));
    for (final t in _transactions.where((x) => x.cardId == cardId)) {
      final shifted = _shiftByClosing(card, t.year, t.month);
      final key = '${shifted.$1}-${shifted.$2.toString().padLeft(2, '0')}';
      monthlyTotal[key] = (monthlyTotal[key] ?? 0) + t.amount;
    }
    return monthlyTotal;
  }

  int getBillingTotalByMonth(int year, int month) {
    int sum = 0;
    for (final t in _transactions) {
      final card = _cards.firstWhere((c) => c.id == t.cardId, orElse: () => dm.CreditCard(id: '', name: '', type: '', color: '#000000'));
      final shifted = _shiftByClosing(card, t.year, t.month);
      if (shifted.$1 == year && shifted.$2 == month) {
        sum += t.amount;
      }
    }
    return sum;
  }

  List<dm.Transaction> getTransactionsByBillingMonth(int year, int month) {
    final List<dm.Transaction> list = [];
    for (final t in _transactions) {
      final card = _cards.firstWhere((c) => c.id == t.cardId, orElse: () => dm.CreditCard(id: '', name: '', type: '', color: '#000000'));
      final shifted = _shiftByClosing(card, t.year, t.month);
      if (shifted.$1 == year && shifted.$2 == month) {
        list.add(t);
      }
    }
    return list;
  }

  (int, int) _shiftByClosing(dm.CreditCard card, int year, int month) {
    if (card.closingDay == null || card.closingDay == 31) {
      return (year, month);
    }
    // 近似として、当月の取引は全て翌月の請求月に寄せる
    final newMonth = month == 12 ? 1 : month + 1;
    final newYear = month == 12 ? year + 1 : year;
    return (newYear, newMonth);
  }

  // 全体の合計金額
  int getTotalAmount() {
    return _transactions.fold<int>(0, (sum, t) => sum + t.amount);
  }

  // 全体の平均金額
  double getAverageAmount() {
    if (_transactions.isEmpty) return 0;
    return getTotalAmount() / _transactions.length;
  }

  // 互換: 既存エクスポートはそのまま
  String exportToJson() {
    return LocalStorage.exportToJson(_cards, _transactions);
  }

  // 予算関連操作
  // カード別予算を設定
  Future<void> setCardBudget(String cardId, int year, int month, int amount) async {
    await LocalStorage.setCardBudget(cardId, year, month, amount);
    notifyListeners();
  }

  // カード別予算を取得
  Future<int?> getCardBudget(String cardId, int year, int month) async {
    return await LocalStorage.getCardBudget(cardId, year, month);
  }

  // 全体予算を設定
  Future<void> setTotalBudget(int year, int month, int amount) async {
    await LocalStorage.setTotalBudget(year, month, amount);
    notifyListeners();
  }

  // 全体予算を取得
  Future<int?> getTotalBudget(int year, int month) async {
    return await LocalStorage.getTotalBudget(year, month);
  }

  // カード別予算の進捗率を計算（0.0-1.0、超過時は1.0を超える）
  Future<double> getCardBudgetProgress(String cardId, int year, int month) async {
    final budget = await getCardBudget(cardId, year, month);
    if (budget == null || budget == 0) return 0.0;
    
    final total = getCardTotalsByMonth(year, month)[cardId] ?? 0;
    return (total / budget).clamp(0.0, double.infinity);
  }

  // 全体予算の進捗率を計算（0.0-1.0、超過時は1.0を超える）
  Future<double> getTotalBudgetProgress(int year, int month) async {
    final budget = await getTotalBudget(year, month);
    if (budget == null || budget == 0) return 0.0;
    
    final total = getTotalByMonth(year, month);
    return (total / budget).clamp(0.0, double.infinity);
  }
}

