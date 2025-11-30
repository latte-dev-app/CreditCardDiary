abstract class SettingsRepository {
  Future<bool> getAggregationMode();
  Future<void> setAggregationMode(bool useBillingMonth);
}
