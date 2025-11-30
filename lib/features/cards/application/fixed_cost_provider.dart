import 'package:flutter/material.dart';
import '../domain/fixed_cost_model.dart';
import '../domain/repositories/fixed_cost_repository.dart';

class FixedCostProvider with ChangeNotifier {
  final FixedCostRepository _repository;

  List<FixedCost> _fixedCosts = [];
  List<FixedCost> get fixedCosts => _fixedCosts;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  FixedCostProvider(this._repository);

  Future<void> loadFixedCosts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _fixedCosts = await _repository.getFixedCosts();
    } catch (e) {
      debugPrint('Error loading fixed costs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addFixedCost(FixedCost fixedCost) async {
    await _repository.addFixedCost(fixedCost);
    await loadFixedCosts();
  }

  Future<void> updateFixedCost(FixedCost fixedCost) async {
    await _repository.updateFixedCost(fixedCost);
    await loadFixedCosts();
  }

  Future<void> deleteFixedCost(String id) async {
    await _repository.deleteFixedCost(id);
    await loadFixedCosts();
  }

  int get totalMonthlyFixedCost {
    return _fixedCosts.fold(0, (sum, item) => sum + item.amount);
  }
}
