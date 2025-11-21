import 'package:get_it/get_it.dart';
import '../features/cards/domain/repositories/card_repository.dart';
import '../features/cards/domain/repositories/transaction_repository.dart';
import '../features/cards/infrastructure/local_storage.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Repositories
  // Note: We will register the implementation as a singleton
  // For now, we are using the refactored LocalStorage which will implement both interfaces
  final localStorage = SharedPreferencesRepository();

  getIt.registerSingleton<CardRepository>(localStorage);
  getIt.registerSingleton<TransactionRepository>(localStorage);
}
