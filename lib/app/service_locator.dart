import 'package:get_it/get_it.dart';
import '../features/cards/domain/repositories/card_repository.dart';
import '../features/cards/domain/repositories/transaction_repository.dart';
import '../features/cards/domain/repositories/fixed_cost_repository.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../features/settings/domain/repositories/backup_repository.dart';
import '../features/cards/infrastructure/local_storage.dart';
import '../features/cards/infrastructure/repositories/card_repository_impl.dart';
import '../features/cards/infrastructure/repositories/transaction_repository_impl.dart';
import '../features/cards/infrastructure/repositories/fixed_cost_repository_impl.dart';
import '../features/settings/infrastructure/repositories/settings_repository_impl.dart';
import '../features/settings/infrastructure/repositories/backup_repository_impl.dart';
import '../features/cards/infrastructure/mock_repository.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

  if (useMock) {
    final mockRepository = MockRepository();
    getIt.registerSingleton<CardRepository>(mockRepository);
    getIt.registerSingleton<TransactionRepository>(mockRepository);
    getIt.registerSingleton<FixedCostRepository>(mockRepository);
    // Mock implementation for Settings/Backup if needed, or use real impl for now
    getIt.registerSingleton<SettingsRepository>(SettingsRepositoryImpl());
    getIt.registerSingleton<BackupRepository>(BackupRepositoryImpl());
  } else {
    final dataSource = SharedPreferencesDataSource();
    getIt.registerSingleton<CardRepository>(CardRepositoryImpl(dataSource));
    getIt.registerSingleton<TransactionRepository>(
      TransactionRepositoryImpl(dataSource),
    );
    getIt.registerSingleton<FixedCostRepository>(
      FixedCostRepositoryImpl(dataSource),
    );
    getIt.registerSingleton<SettingsRepository>(SettingsRepositoryImpl());
    getIt.registerSingleton<BackupRepository>(BackupRepositoryImpl());
  }
}
