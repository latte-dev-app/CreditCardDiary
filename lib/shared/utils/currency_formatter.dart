import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _currencyFormat = NumberFormat('#,###');

  static String format(int amount) {
    return _currencyFormat.format(amount);
  }
}
