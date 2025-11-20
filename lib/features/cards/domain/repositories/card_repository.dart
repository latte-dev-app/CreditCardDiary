import '../card_model.dart';

abstract class CardRepository {
  Future<List<CreditCard>> getAllCards();
  Future<void> addCard(CreditCard card);
  Future<void> updateCard(CreditCard card);
  Future<void> upsertCard(CreditCard card);
  Future<void> deleteCard(String cardId);
  
  // Budget related
  Future<void> setCardBudget(String cardId, int year, int month, int amount);
  Future<int?> getCardBudget(String cardId, int year, int month);
}
