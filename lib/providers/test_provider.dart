import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';

class TestProvider extends ChangeNotifier {
  List<IELTSTest> _tests = [];
  List<TestResult> _results = [];
  bool _isLoading = false;
  TestSkill? _selectedSkillFilter;

  List<IELTSTest> get tests => _tests;
  List<TestResult> get results => _results;
  bool get isLoading => _isLoading;
  TestSkill? get selectedSkillFilter => _selectedSkillFilter;

  List<IELTSTest> get filteredTests {
    if (_selectedSkillFilter == null) return _tests;
    return _tests.where((t) => t.skill == _selectedSkillFilter).toList();
  }

  TestProvider() {
    loadTests();
  }

  Future<void> loadTests() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    _tests = MockDataService.getMockTests();
    _isLoading = false;
    notifyListeners();
  }

  void setSkillFilter(TestSkill? skill) {
    _selectedSkillFilter = skill;
    notifyListeners();
  }

  IELTSTest? getTestById(String id) {
    try { return _tests.firstWhere((t) => t.id == id); } catch (_) { return null; }
  }

  void addResult(TestResult result) {
    _results.insert(0, result);
    notifyListeners();
  }

  List<TestResult> getResultsForSkill(TestSkill skill) =>
      _results.where((r) => r.skill == skill).toList();
}
