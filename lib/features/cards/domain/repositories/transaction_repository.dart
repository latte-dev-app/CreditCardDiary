import '../card_model.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getAllTransactions();
  Future<void> addTransaction(Transaction transaction);
  Future<void> updateTransaction(Transaction transaction);
  Future<void> upsertTransaction(Transaction transaction);
  Future<void> deleteTransaction(String transactionId);
  
  // Budget related
  Future<void> setTotalBudget(int year, int month, int amount);
  Future<int?> getTotalBudget(int year, int month);
}
