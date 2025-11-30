import 'package:get_it/get_it.dart';
import '../features/cards/domain/repositories/card_repository.dart';
import '../features/cards/domain/repositories/transaction_repository.dart';
import '../features/cards/domain/repositories/fixed_cost_repository.dart';
import '../features/cards/infrastructure/local_storage.dart';
import '../features/cards/infrastructure/mock_repository.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

  if (useMock) {
    final mockRepository = MockRepository();
    getIt.registerSingleton<CardRepository>(mockRepository);
    getIt.registerSingleton<TransactionRepository>(mockRepository);
    getIt.registerSingleton<FixedCostRepository>(mockRepository);
  } else {
    final localStorage = SharedPreferencesRepository();
    getIt.registerSingleton<CardRepository>(localStorage);
    getIt.registerSingleton<TransactionRepository>(localStorage);
    getIt.registerSingleton<FixedCostRepository>(localStorage);
  }
}
