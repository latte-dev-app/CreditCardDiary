import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/card_model.dart';

class LocalStorage {
  static const String _keyCards = 'cards_data';
  static const String _keyTransactions = 'transactions_data';

  // データを保存
  static Future<void> saveData(
      List<CreditCard> cards, List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    
    final cardsJson = cards.map((card) => card.toJson()).toList();
    final transactionsJson = transactions.map((t) => t.toJson()).toList();
    
    await prefs.setString(_keyCards, jsonEncode(cardsJson));
    await prefs.setString(_keyTransactions, jsonEncode(transactionsJson));
  }

  // データを読み込み
  static Future<Map<String, dynamic>> loadData() async {
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

  // JSONエクスポート
  static String exportToJson(
      List<CreditCard> cards, List<Transaction> transactions) {
    final Map<String, dynamic> data = {
      'cards': cards.map((card) => card.toJson()).toList(),
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  // JSONインポート
  static Map<String, dynamic> importFromJson(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    
    final cardsJson = data['cards'] as List;
    final transactionsJson = data['transactions'] as List;
    
    final List<CreditCard> cards =
        cardsJson.map((json) => CreditCard.fromJson(json)).toList();
    final List<Transaction> transactions =
        transactionsJson.map((json) => Transaction.fromJson(json)).toList();
    
    return {
      'cards': cards,
      'transactions': transactions,
    };
  }
}

