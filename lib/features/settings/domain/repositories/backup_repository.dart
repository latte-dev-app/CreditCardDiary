abstract class BackupRepository {
  Future<String> exportAllData();
  Future<void> importAllData(String jsonString);
}
