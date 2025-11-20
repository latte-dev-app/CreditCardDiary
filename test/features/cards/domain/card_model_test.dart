import 'package:flutter_test/flutter_test.dart';
import 'package:creditcarddiary/features/cards/domain/card_model.dart';

void main() {
  group('Transaction', () {
    test('monthString returns correct format', () {
      final transaction = Transaction(
        id: '1',
        cardId: 'card1',
        title: 'Test',
        amount: 1000,
        year: 2023,
        month: 5,
      );
      expect(transaction.monthString, '2023-05');
    });

    test('monthString pads single digit month', () {
      final transaction = Transaction(
        id: '1',
        cardId: 'card1',
        title: 'Test',
        amount: 1000,
        year: 2023,
        month: 11,
      );
      expect(transaction.monthString, '2023-11');
    });

    test('fromJson parses date string correctly', () {
      final json = {
        'id': '1',
        'cardId': 'card1',
        'title': 'Test',
        'amount': 1000,
        'date': '2023-05-20',
      };
      final transaction = Transaction.fromJson(json);
      expect(transaction.year, 2023);
      expect(transaction.month, 5);
    });

    test('fromJson uses explicit year/month if provided', () {
      final json = {
        'id': '1',
        'cardId': 'card1',
        'title': 'Test',
        'amount': 1000,
        'year': 2024,
        'month': 1,
      };
      final transaction = Transaction.fromJson(json);
      expect(transaction.year, 2024);
      expect(transaction.month, 1);
    });
  });
}
