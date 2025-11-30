import '../../../../features/cards/infrastructure/local_storage.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  @override
  Future<String> exportAllData() async {
    return await SharedPreferencesDataSource.exportAllData();
  }

  @override
  Future<void> importAllData(String jsonString) async {
    await SharedPreferencesDataSource.importAllData(jsonString);
  }
}
