import '../../domain/fixed_cost_model.dart';
import '../../domain/repositories/fixed_cost_repository.dart';
import '../local_storage.dart';

class FixedCostRepositoryImpl implements FixedCostRepository {
  final SharedPreferencesDataSource _dataSource;

  FixedCostRepositoryImpl(this._dataSource);

  @override
  Future<List<FixedCost>> getFixedCosts() async {
    return _dataSource.getFixedCosts();
  }

  @override
  Future<void> addFixedCost(FixedCost fixedCost) async {
    return _dataSource.addFixedCost(fixedCost);
  }

  @override
  Future<void> updateFixedCost(FixedCost fixedCost) async {
    return _dataSource.updateFixedCost(fixedCost);
  }

  @override
  Future<void> updateAllFixedCosts(List<FixedCost> fixedCosts) async {
    return _dataSource.updateAllFixedCosts(fixedCosts);
  }

  @override
  Future<void> deleteFixedCost(String id) async {
    return _dataSource.deleteFixedCost(id);
  }
}
