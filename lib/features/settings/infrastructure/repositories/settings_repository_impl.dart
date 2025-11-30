import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const String _keyUseBillingMonth = 'use_billing_month';

  @override
  Future<bool> getAggregationMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseBillingMonth) ?? false;
  }

  @override
  Future<void> setAggregationMode(bool useBillingMonth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseBillingMonth, useBillingMonth);
  }
}
