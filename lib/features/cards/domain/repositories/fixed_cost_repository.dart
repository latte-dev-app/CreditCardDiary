import '../../domain/fixed_cost_model.dart';

abstract class FixedCostRepository {
  Future<List<FixedCost>> getFixedCosts();
  Future<void> addFixedCost(FixedCost fixedCost);
  Future<void> updateFixedCost(FixedCost fixedCost);
  Future<void> updateAllFixedCosts(List<FixedCost> fixedCosts);
  Future<void> deleteFixedCost(String id);
}
