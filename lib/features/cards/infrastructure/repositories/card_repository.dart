import '../../domain/card_model.dart' as domain;
import '../local_storage.dart';

abstract class CardRepository {
  Future<List<domain.CreditCard>> getAllCards();
  Future<void> upsertCard(domain.CreditCard card);
  Future<void> deleteCard(String cardId);
}

abstract class TransactionRepository {
  Future<List<domain.Transaction>> getAllTransactions();
  Future<void> upsertTransaction(domain.Transaction tx);
  Future<void> deleteTransaction(String txId);
}

class SharedPreferencesCardRepository implements CardRepository {
  @override
  Future<List<domain.CreditCard>> getAllCards() async {
    return await LocalStorage.getAllCards();
  }

  @override
  Future<void> upsertCard(domain.CreditCard card) async {
    await LocalStorage.upsertCard(card);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    await LocalStorage.deleteCard(cardId);
  }
}

class SharedPreferencesTransactionRepository implements TransactionRepository {
  @override
  Future<List<domain.Transaction>> getAllTransactions() async {
    return await LocalStorage.getAllTransactions();
  }

  @override
  Future<void> upsertTransaction(domain.Transaction tx) async {
    await LocalStorage.upsertTransaction(tx);
  }

  @override
  Future<void> deleteTransaction(String txId) async {
    await LocalStorage.deleteTransaction(txId);
  }
}
