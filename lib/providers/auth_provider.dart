import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

// ─── Auth Provider ────────────────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      _user = UserModel(
        id: prefs.getString('userId') ?? 'user_001',
        name: prefs.getString('userName') ?? 'IELTS Student',
        email: prefs.getString('userEmail') ?? 'student@example.com',
        joinedAt: DateTime(2024, 1, 15),
        targetBandScore: prefs.getDouble('targetScore') ?? 7.0,
        totalTestsTaken: prefs.getInt('totalTests') ?? 12,
        averageBandScore: prefs.getDouble('avgScore') ?? 6.2,
        totalStudyMinutes: prefs.getInt('studyMinutes') ?? 1440,
      );
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Simulate API call

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userEmail', email);
    await prefs.setString('userName', email.split('@')[0]);
    await prefs.setString('userId', 'user_${DateTime.now().millisecondsSinceEpoch}');

    _user = UserModel(
      id: 'user_001',
      name: email.split('@')[0],
      email: email,
      joinedAt: DateTime.now(),
      targetBandScore: 7.0,
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);

    _user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      joinedAt: DateTime.now(),
      targetBandScore: 7.0,
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    _user = null;
    notifyListeners();
  }

  Future<void> updateTargetScore(double score) async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('targetScore', score);
    _user = UserModel(
      id: _user!.id, name: _user!.name, email: _user!.email,
      joinedAt: _user!.joinedAt, targetBandScore: score,
      totalTestsTaken: _user!.totalTestsTaken,
      averageBandScore: _user!.averageBandScore,
      totalStudyMinutes: _user!.totalStudyMinutes,
    );
    notifyListeners();
  }
}

// ─── Test Provider ────────────────────────────────────────────────────────────
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

    await Future.delayed(const Duration(milliseconds: 500));
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
    _results.add(result);
    notifyListeners();
  }

  List<TestResult> getResultsForSkill(TestSkill skill) =>
      _results.where((r) => r.skill == skill).toList();
}

// ─── Progress Provider ────────────────────────────────────────────────────────
class ProgressProvider extends ChangeNotifier {
  List<WeeklyProgress> _weeklyProgress = [];
  List<SkillProgress> _skillProgress = [];

  List<WeeklyProgress> get weeklyProgress => _weeklyProgress;
  List<SkillProgress> get skillProgress => _skillProgress;

  ProgressProvider() {
    _loadProgress();
  }

  void _loadProgress() {
    _weeklyProgress = MockDataService.getProgressHistory();
    _skillProgress = MockDataService.getSkillProgress();
    notifyListeners();
  }

  double get overallBandScore {
    if (_skillProgress.isEmpty) return 0;
    final total = _skillProgress.fold(0.0, (sum, s) => sum + s.currentBandScore);
    return (total / _skillProgress.length * 2).round() / 2;
  }

  int get totalStudyMinutes {
    return _weeklyProgress.fold(0, (sum, w) => sum + w.studyMinutes);
  }

  int get totalTestsTaken {
    return _weeklyProgress.fold(0, (sum, w) => sum + w.testsTaken);
  }
}


