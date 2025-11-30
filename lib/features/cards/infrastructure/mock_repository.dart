import 'package:uuid/uuid.dart';
import '../domain/card_model.dart';
import '../domain/fixed_cost_model.dart';
import '../domain/repositories/card_repository.dart';
import '../domain/repositories/fixed_cost_repository.dart';
import '../domain/repositories/transaction_repository.dart';

class MockRepository
    implements CardRepository, TransactionRepository, FixedCostRepository {
  final List<CreditCard> _cards = [];
  final List<Transaction> _transactions = [];
  final List<FixedCost> _fixedCosts = [];
  final Map<String, Map<String, int>> _cardBudgets = {};
  final Map<String, int> _totalBudgets = {};

  MockRepository() {
    _initDummyData();
  }

  void _initDummyData() {
    // Dummy Cards
    final card1 = CreditCard(
      id: 'card_1',
      name: 'メインカード (Mock)',
      type: 'Visa',
      closingDay: 15,
      paymentDay: 10,
      color: '#1A237E', // Indigo 900
    );
    final card2 = CreditCard(
      id: 'card_2',
      name: 'サブカード (Mock)',
      type: 'Mastercard',
      closingDay: 20,
      paymentDay: 25,
      color: '#B71C1C', // Red 900
    );
    _cards.addAll([card1, card2]);

    // Dummy Fixed Costs
    _fixedCosts.add(
      FixedCost(
        id: const Uuid().v4(),
        title: '家賃 (Mock)',
        amount: 85000,
        paymentDay: 27,
        cardId: card1.id,
      ),
    );
    _fixedCosts.add(
      FixedCost(
        id: const Uuid().v4(),
        title: 'インターネット (Mock)',
        amount: 4500,
        paymentDay: 27,
        cardId: card1.id,
      ),
    );
    _fixedCosts.add(
      FixedCost(
        id: const Uuid().v4(),
        title: 'サブスク (Mock)',
        amount: 980,
        paymentDay: 10,
        cardId: card2.id,
      ),
    );
    _fixedCosts.add(
      FixedCost(
        id: const Uuid().v4(),
        title: '水道代 (Mock)',
        amount: 3200,
        paymentDay: 25,
        cardId: card1.id,
      ),
    );
    _fixedCosts.add(
      FixedCost(
        id: const Uuid().v4(),
        title: '電気代 (Mock)',
        amount: 5400,
        paymentDay: 25,
        cardId: card1.id,
      ),
    );
    _fixedCosts.add(
      FixedCost(
        id: const Uuid().v4(),
        title: 'ガス代 (Mock)',
        amount: 4100,
        paymentDay: 25,
        cardId: card1.id,
      ),
    );

    // Dummy Transactions (Current Month)
    final now = DateTime.now();
    _transactions.add(
      Transaction(
        id: const Uuid().v4(),
        title: 'スーパー (Mock)',
        amount: 3500,
        year: now.year,
        month: now.month,
        cardId: card1.id,
      ),
    );
    _transactions.add(
      Transaction(
        id: const Uuid().v4(),
        title: 'コンビニ (Mock)',
        amount: 850,
        year: now.year,
        month: now.month,
        cardId: card1.id,
      ),
    );
    _transactions.add(
      Transaction(
        id: const Uuid().v4(),
        title: '書籍 (Mock)',
        amount: 2400,
        year: now.year,
        month: now.month,
        cardId: card2.id,
      ),
    );
  }

  // ---- CardRepository ----
  @override
  Future<List<CreditCard>> getAllCards() async => _cards;

  @override
  Future<void> addCard(CreditCard card) async => _cards.add(card);

  @override
  Future<void> updateCard(CreditCard card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index != -1) _cards[index] = card;
  }

  @override
  Future<void> upsertCard(CreditCard card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index != -1) {
      _cards[index] = card;
    } else {
      _cards.add(card);
    }
  }

  @override
  Future<void> deleteCard(String cardId) async {
    _cards.removeWhere((c) => c.id == cardId);
    _transactions.removeWhere((t) => t.cardId == cardId);
    // Note: Fixed costs might need update too, but keeping simple for mock
  }

  @override
  Future<void> setCardBudget(
    String cardId,
    int year,
    int month,
    int amount,
  ) async {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    if (!_cardBudgets.containsKey(cardId)) {
      _cardBudgets[cardId] = {};
    }
    _cardBudgets[cardId]![monthKey] = amount;
  }

  @override
  Future<int?> getCardBudget(String cardId, int year, int month) async {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    return _cardBudgets[cardId]?[monthKey];
  }

  // ---- TransactionRepository ----
  @override
  Future<List<Transaction>> getAllTransactions() async => _transactions;

  @override
  Future<void> addTransaction(Transaction transaction) async =>
      _transactions.add(transaction);

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) _transactions[index] = transaction;
  }

  @override
  Future<void> upsertTransaction(Transaction transaction) async {
    final index = _transactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _transactions[index] = transaction;
    } else {
      _transactions.add(transaction);
    }
  }

  @override
  Future<void> deleteTransaction(String transactionId) async =>
      _transactions.removeWhere((t) => t.id == transactionId);

  @override
  Future<void> setTotalBudget(int year, int month, int amount) async {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    _totalBudgets[monthKey] = amount;
  }

  @override
  Future<int?> getTotalBudget(int year, int month) async {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    return _totalBudgets[monthKey];
  }

  // ---- FixedCostRepository ----
  @override
  Future<List<FixedCost>> getFixedCosts() async => _fixedCosts;

  @override
  Future<void> addFixedCost(FixedCost fixedCost) async =>
      _fixedCosts.add(fixedCost);

  @override
  Future<void> updateFixedCost(FixedCost fixedCost) async {
    final index = _fixedCosts.indexWhere((fc) => fc.id == fixedCost.id);
    if (index != -1) _fixedCosts[index] = fixedCost;
  }

  @override
  Future<void> updateAllFixedCosts(List<FixedCost> fixedCosts) async {
    _fixedCosts.clear();
    _fixedCosts.addAll(fixedCosts);
  }

  @override
  Future<void> deleteFixedCost(String id) async =>
      _fixedCosts.removeWhere((fc) => fc.id == id);
}
