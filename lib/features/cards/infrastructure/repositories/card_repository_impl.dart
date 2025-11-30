import '../../domain/card_model.dart';
import '../../domain/repositories/card_repository.dart';
import '../local_storage.dart';

class CardRepositoryImpl implements CardRepository {
  final SharedPreferencesDataSource _dataSource;

  CardRepositoryImpl(this._dataSource);

  @override
  Future<List<CreditCard>> getAllCards() async {
    final rawData = await _dataSource.getAllCards();
    return rawData
        .map((json) {
          try {
            return CreditCard.fromJson(json);
          } catch (e) {
            // Skip corrupted data
            return null;
          }
        })
        .whereType<CreditCard>()
        .toList();
  }

  @override
  Future<void> addCard(CreditCard card) async {
    return _dataSource.addCard(card.toJson());
  }

  @override
  Future<void> updateCard(CreditCard card) async {
    return _dataSource.updateCard(card.toJson());
  }

  @override
  Future<void> upsertCard(CreditCard card) async {
    return _dataSource.upsertCard(card.toJson());
  }

  @override
  Future<void> deleteCard(String cardId) async {
    return _dataSource.deleteCard(cardId);
  }

  @override
  Future<void> setCardBudget(
    String cardId,
    int year,
    int month,
    int amount,
  ) async {
    return _dataSource.setCardBudget(cardId, year, month, amount);
  }

  @override
  Future<int?> getCardBudget(String cardId, int year, int month) async {
    return _dataSource.getCardBudget(cardId, year, month);
  }
}
