import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/card_model.dart';
import '../domain/repositories/card_repository.dart';
import '../domain/repositories/transaction_repository.dart';

class SharedPreferencesRepository implements CardRepository, TransactionRepository {
  static const String _keyCards = 'cards_data';
  static const String _keyTransactions = 'transactions_data';
  static const String _keyCardBudgets = 'card_budgets_data';
  static const String _keyTotalBudgets = 'total_budgets_data';

  // SharedPreferencesインスタンスを取得（集計モード設定用）
  // Note: This is still static for now as it's used by CardProvider for aggregation mode
  // We should eventually move aggregation mode to a repository or service too.
  static Future<SharedPreferences> getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  // データを保存
  Future<void> _saveData(
      List<CreditCard> cards, List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    
    final cardsJson = cards.map((card) => card.toJson()).toList();
    final transactionsJson = transactions.map((t) => t.toJson()).toList();
    
    await prefs.setString(_keyCards, jsonEncode(cardsJson));
    await prefs.setString(_keyTransactions, jsonEncode(transactionsJson));
  }

  // データを読み込み
  Future<Map<String, dynamic>> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final cardsJsonString = prefs.getString(_keyCards);
    final transactionsJsonString = prefs.getString(_keyTransactions);
    
    List<CreditCard> cards = [];
    List<Transaction> transactions = [];
    
    if (cardsJsonString != null) {
      final cardsJson = jsonDecode(cardsJsonString) as List;
      cards = cardsJson.map((json) => CreditCard.fromJson(json)).toList();
    }
    
    if (transactionsJsonString != null) {
      final transactionsJson = jsonDecode(transactionsJsonString) as List;
      transactions = transactionsJson
          .map((json) => Transaction.fromJson(json))
          .toList();
    }
    
    return {
      'cards': cards,
      'transactions': transactions,
    };
  }

  // JSONエクスポート (Static helper)
  static String exportToJson(
      List<CreditCard> cards, List<Transaction> transactions) {
    final Map<String, dynamic> data = {
      'cards': cards.map((card) => card.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  // ---- CardRepository Implementation ----

  @override
  Future<List<CreditCard>> getAllCards() async {
    final prefsData = await _loadData();
    return (prefsData['cards'] as List<CreditCard>? ?? []).toList();
  }

  @override
  Future<void> addCard(CreditCard card) async {
    final prefsData = await _loadData();
    final cards = (prefsData['cards'] as List<CreditCard>? ?? []).toList();
    cards.add(card);
    final transactions = prefsData['transactions'] as List<Transaction>? ?? [];
    await _saveData(cards, transactions);
  }

  @override
  Future<void> updateCard(CreditCard card) async {
    final prefsData = await _loadData();
    final cards = (prefsData['cards'] as List<CreditCard>? ?? []).toList();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      cards[index] = card;
      final transactions = prefsData['transactions'] as List<Transaction>? ?? [];
      await _saveData(cards, transactions);
    }
  }

  @override
  Future<void> upsertCard(CreditCard card) async {
    final prefsData = await _loadData();
    final cards = (prefsData['cards'] as List<CreditCard>? ?? []).toList();
    final index = cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      cards[index] = card;
    } else {
      cards.add(card);
    }
    final transactions = prefsData['transactions'] as List<Transaction>? ?? [];
    await _saveData(cards, transactions);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    final prefsData = await _loadData();
    final cards = (prefsData['cards'] as List<CreditCard>? ?? [])
        .where((c) => c.id != cardId)
        .toList();
    final transactions = (prefsData['transactions'] as List<Transaction>? ?? [])
        .where((t) => t.cardId != cardId)
        .toList();
    await _saveData(cards, transactions);
  }

  // ---- TransactionRepository Implementation ----

  @override
  Future<List<Transaction>> getAllTransactions() async {
    final prefsData = await _loadData();
    return (prefsData['transactions'] as List<Transaction>? ?? []).toList();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards'] as List<CreditCard>? ?? [];
    final transactions = (prefsData['transactions'] as List<Transaction>? ?? []).toList();
    transactions.add(transaction);
    await _saveData(cards, transactions);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards'] as List<CreditCard>? ?? [];
    final transactions = (prefsData['transactions'] as List<Transaction>? ?? []).toList();
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
      await _saveData(cards, transactions);
    }
  }

  @override
  Future<void> upsertTransaction(Transaction transaction) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards'] as List<CreditCard>? ?? [];
    final transactions = (prefsData['transactions'] as List<Transaction>? ?? []).toList();
    final index = transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      transactions[index] = transaction;
    } else {
      transactions.add(transaction);
    }
    await _saveData(cards, transactions);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards'] as List<CreditCard>? ?? [];
    final transactions = (prefsData['transactions'] as List<Transaction>? ?? [])
        .where((t) => t.id != transactionId)
        .toList();
    await _saveData(cards, transactions);
  }

  // ---- Budget Implementation ----

  Future<void> _saveCardBudgets(Map<String, Map<String, int>> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCardBudgets, jsonEncode(budgets));
  }

  Future<Map<String, Map<String, int>>> _loadCardBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsJsonString = prefs.getString(_keyCardBudgets);
    if (budgetsJsonString == null) return {};
    
    final decoded = jsonDecode(budgetsJsonString) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(
      key,
      Map<String, int>.from((value as Map).map((k, v) => MapEntry(k.toString(), v as int))),
    ));
  }

  Future<void> _saveTotalBudgets(Map<String, int> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTotalBudgets, jsonEncode(budgets));
  }

  Future<Map<String, int>> _loadTotalBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsJsonString = prefs.getString(_keyTotalBudgets);
    if (budgetsJsonString == null) return {};
    
    final decoded = jsonDecode(budgetsJsonString) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  @override
  Future<void> setCardBudget(String cardId, int year, int month, int amount) async {
    final budgets = await _loadCardBudgets();
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    
    if (!budgets.containsKey(cardId)) {
      budgets[cardId] = {};
    }
    budgets[cardId]![monthKey] = amount;
    await _saveCardBudgets(budgets);
  }

  @override
  Future<int?> getCardBudget(String cardId, int year, int month) async {
    final budgets = await _loadCardBudgets();
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    return budgets[cardId]?[monthKey];
  }

  @override
  Future<void> setTotalBudget(int year, int month, int amount) async {
    final budgets = await _loadTotalBudgets();
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    budgets[monthKey] = amount;
    await _saveTotalBudgets(budgets);
  }

  @override
  Future<int?> getTotalBudget(int year, int month) async {
    final budgets = await _loadTotalBudgets();
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    return budgets[monthKey];
  }
}

