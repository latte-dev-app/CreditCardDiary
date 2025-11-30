import '../../domain/card_model.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../local_storage.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final SharedPreferencesDataSource _dataSource;

  TransactionRepositoryImpl(this._dataSource);

  @override
  Future<List<Transaction>> getAllTransactions() async {
    return _dataSource.getAllTransactions();
  }

  @override
  Future<void> addTransaction(Transaction transaction) async {
    return _dataSource.addTransaction(transaction);
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    return _dataSource.updateTransaction(transaction);
  }

  @override
  Future<void> upsertTransaction(Transaction transaction) async {
    return _dataSource.upsertTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    return _dataSource.deleteTransaction(transactionId);
  }

  @override
  Future<void> setTotalBudget(int year, int month, int amount) async {
    return _dataSource.setTotalBudget(year, month, amount);
  }

  @override
  Future<int?> getTotalBudget(int year, int month) async {
    return _dataSource.getTotalBudget(year, month);
  }
}
