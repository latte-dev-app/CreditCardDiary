import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesDataSource {
  static const String _keyCards = 'cards_data';
  static const String _keyTransactions = 'transactions_data';
  static const String _keyCardBudgets = 'card_budgets_data';
  static const String _keyTotalBudgets = 'total_budgets_data';
  static const String _keyFixedCosts = 'fixed_costs_data';

  // SharedPreferencesインスタンスを取得（集計モード設定用）
  // Note: This is still static for now as it's used by CardProvider for aggregation mode
  // We should eventually move aggregation mode to a repository or service too.
  static Future<SharedPreferences> getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  // データを保存
  Future<void> _saveData(
    List<Map<String, dynamic>> cards,
    List<Map<String, dynamic>> transactions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCards, jsonEncode(cards));
    await prefs.setString(_keyTransactions, jsonEncode(transactions));
  }

  // データを読み込み
  Future<Map<String, List<Map<String, dynamic>>>> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final cardsJsonString = prefs.getString(_keyCards);
    final transactionsJsonString = prefs.getString(_keyTransactions);

    List<Map<String, dynamic>> cards = [];
    List<Map<String, dynamic>> transactions = [];

    try {
      if (cardsJsonString != null) {
        final cardsJson = jsonDecode(cardsJsonString) as List;
        cards = cardsJson.cast<Map<String, dynamic>>().toList();
      }

      if (transactionsJsonString != null) {
        final transactionsJson = jsonDecode(transactionsJsonString) as List;
        transactions = transactionsJson.cast<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      // JSONパースエラー時は空のデータを返してアプリのクラッシュを防ぐ
      // 将来的にはエラーログ送信やバックアップ復元への誘導を検討
      debugPrint('Error loading data: $e');
      cards = [];
      transactions = [];
    }

    return {'cards': cards, 'transactions': transactions};
  }

  // JSONエクスポート (Static helper)
  static String exportToJson(
    List<Map<String, dynamic>> cards,
    List<Map<String, dynamic>> transactions,
  ) {
    final Map<String, dynamic> data = {
      'cards': cards,
      'transactions': transactions,
    };
    return jsonEncode(data);
  }

  // ---- Card Data Operations ----

  Future<List<Map<String, dynamic>>> getAllCards() async {
    final prefsData = await _loadData();
    return prefsData['cards']!;
  }

  Future<void> addCard(Map<String, dynamic> card) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards']!;
    cards.add(card);
    final transactions = prefsData['transactions']!;
    await _saveData(cards, transactions);
  }

  Future<void> updateCard(Map<String, dynamic> card) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards']!;
    final index = cards.indexWhere((c) => c['id'] == card['id']);
    if (index != -1) {
      cards[index] = card;
      final transactions = prefsData['transactions']!;
      await _saveData(cards, transactions);
    }
  }

  Future<void> upsertCard(Map<String, dynamic> card) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards']!;
    final index = cards.indexWhere((c) => c['id'] == card['id']);
    if (index != -1) {
      cards[index] = card;
    } else {
      cards.add(card);
    }
    final transactions = prefsData['transactions']!;
    await _saveData(cards, transactions);
  }

  Future<void> deleteCard(String cardId) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards']!.where((c) => c['id'] != cardId).toList();
    final transactions =
        prefsData['transactions']!.where((t) => t['cardId'] != cardId).toList();
    await _saveData(cards, transactions);
  }

  // ---- Transaction Data Operations ----

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final prefsData = await _loadData();
    return prefsData['transactions']!;
  }

  Future<void> addTransaction(Map<String, dynamic> transaction) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards']!;
    final transactions = prefsData['transactions']!;
    transactions.add(transaction);
    await _saveData(cards, transactions);
  }

  Future<void> updateTransaction(Map<String, dynamic> transaction) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards']!;
    final transactions = prefsData['transactions']!;
    final index = transactions.indexWhere((t) => t['id'] == transaction['id']);
    if (index != -1) {
      transactions[index] = transaction;
      await _saveData(cards, transactions);
    }
  }

  Future<void> upsertTransaction(Map<String, dynamic> transaction) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards']!;
    final transactions = prefsData['transactions']!;
    final index = transactions.indexWhere((t) => t['id'] == transaction['id']);
    if (index != -1) {
      transactions[index] = transaction;
    } else {
      transactions.add(transaction);
    }
    await _saveData(cards, transactions);
  }

  Future<void> deleteTransaction(String transactionId) async {
    final prefsData = await _loadData();
    final cards = prefsData['cards']!;
    final transactions =
        prefsData['transactions']!
            .where((t) => t['id'] != transactionId)
            .toList();
    await _saveData(cards, transactions);
  }

  // ---- Budget Data Operations ----

  Future<void> _saveCardBudgets(Map<String, Map<String, int>> budgets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCardBudgets, jsonEncode(budgets));
  }

  Future<Map<String, Map<String, int>>> _loadCardBudgets() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetsJsonString = prefs.getString(_keyCardBudgets);
    if (budgetsJsonString == null) return {};

    final decoded = jsonDecode(budgetsJsonString) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        key,
        Map<String, int>.from(
          (value as Map).map((k, v) => MapEntry(k.toString(), v as int)),
        ),
      ),
    );
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

  Future<void> setCardBudget(
    String cardId,
    int year,
    int month,
    int amount,
  ) async {
    final budgets = await _loadCardBudgets();
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    if (!budgets.containsKey(cardId)) {
      budgets[cardId] = {};
    }
    budgets[cardId]![monthKey] = amount;
    await _saveCardBudgets(budgets);
  }

  Future<int?> getCardBudget(String cardId, int year, int month) async {
    final budgets = await _loadCardBudgets();
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    return budgets[cardId]?[monthKey];
  }

  Future<void> setTotalBudget(int year, int month, int amount) async {
    final budgets = await _loadTotalBudgets();
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    budgets[monthKey] = amount;
    await _saveTotalBudgets(budgets);
  }

  Future<int?> getTotalBudget(int year, int month) async {
    final budgets = await _loadTotalBudgets();
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    return budgets[monthKey];
  }

  // ---- FixedCost Data Operations ----

  Future<void> _saveFixedCosts(List<Map<String, dynamic>> fixedCosts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFixedCosts, jsonEncode(fixedCosts));
  }

  Future<List<Map<String, dynamic>>> getFixedCosts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyFixedCosts);
    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.cast<Map<String, dynamic>>().toList();
  }

  Future<void> addFixedCost(Map<String, dynamic> fixedCost) async {
    final list = await getFixedCosts();
    list.add(fixedCost);
    await _saveFixedCosts(list);
  }

  Future<void> updateFixedCost(Map<String, dynamic> fixedCost) async {
    final list = await getFixedCosts();
    final index = list.indexWhere((fc) => fc['id'] == fixedCost['id']);
    if (index != -1) {
      list[index] = fixedCost;
      await _saveFixedCosts(list);
    }
  }

  Future<void> updateAllFixedCosts(
    List<Map<String, dynamic>> fixedCosts,
  ) async {
    await _saveFixedCosts(fixedCosts);
  }

  Future<void> deleteFixedCost(String id) async {
    final list = await getFixedCosts();
    list.removeWhere((fc) => fc['id'] == id);
    await _saveFixedCosts(list);
  }

  // ---- Import/Export ----

  static Future<String> exportAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final cards = prefs.getString(_keyCards) ?? '[]';
    final transactions = prefs.getString(_keyTransactions) ?? '[]';
    final fixedCosts = prefs.getString(_keyFixedCosts) ?? '[]';
    final cardBudgets = prefs.getString(_keyCardBudgets) ?? '{}';
    final totalBudgets = prefs.getString(_keyTotalBudgets) ?? '{}';

    final data = {
      'cards': jsonDecode(cards),
      'transactions': jsonDecode(transactions),
      'fixedCosts': jsonDecode(fixedCosts),
      'cardBudgets': jsonDecode(cardBudgets),
      'totalBudgets': jsonDecode(totalBudgets),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(data);
  }

  static Future<void> importAllData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      if (data.containsKey('cards')) {
        await prefs.setString(_keyCards, jsonEncode(data['cards']));
      }
      if (data.containsKey('transactions')) {
        await prefs.setString(
          _keyTransactions,
          jsonEncode(data['transactions']),
        );
      }
      if (data.containsKey('fixedCosts')) {
        await prefs.setString(_keyFixedCosts, jsonEncode(data['fixedCosts']));
      }
      if (data.containsKey('cardBudgets')) {
        await prefs.setString(_keyCardBudgets, jsonEncode(data['cardBudgets']));
      }
      if (data.containsKey('totalBudgets')) {
        await prefs.setString(
          _keyTotalBudgets,
          jsonEncode(data['totalBudgets']),
        );
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }
}
