import '../../domain/fixed_cost_model.dart';
import '../../domain/repositories/fixed_cost_repository.dart';
import '../local_storage.dart';

class FixedCostRepositoryImpl implements FixedCostRepository {
  final SharedPreferencesDataSource _dataSource;

  FixedCostRepositoryImpl(this._dataSource);

  @override
  Future<List<FixedCost>> getFixedCosts() async {
    final rawData = await _dataSource.getFixedCosts();
    return rawData.map((json) => FixedCost.fromJson(json)).toList();
  }

  @override
  Future<void> addFixedCost(FixedCost fixedCost) async {
    return _dataSource.addFixedCost(fixedCost.toJson());
  }

  @override
  Future<void> updateFixedCost(FixedCost fixedCost) async {
    return _dataSource.updateFixedCost(fixedCost.toJson());
  }

  @override
  Future<void> updateAllFixedCosts(List<FixedCost> fixedCosts) async {
    final rawList = fixedCosts.map((fc) => fc.toJson()).toList();
    return _dataSource.updateAllFixedCosts(rawList);
  }

  @override
  Future<void> deleteFixedCost(String id) async {
    return _dataSource.deleteFixedCost(id);
  }
}
