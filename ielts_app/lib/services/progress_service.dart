import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ProgressService {
  static const String _resultsKey = 'test_results';
  static const String _userKey = 'app_user';

  static Future<void> saveResult(TestResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getResults();
    existing.insert(0, result);
    // Keep last 100 results
    final limited = existing.take(100).toList();
    final encoded = limited.map((r) => _encodeResult(r)).toList();
    await prefs.setString(_resultsKey, jsonEncode(encoded));
  }

  static Future<List<TestResult>> getResults() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_resultsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => _decodeResult(e)).toList();
    } catch (_) { return []; }
  }

  static Future<UserProgress> getProgress() async {
    final results = await getResults();
    final Map<TestSkill, List<double>> bandHistory = {
      TestSkill.listening: [],
      TestSkill.reading: [],
      TestSkill.writing: [],
      TestSkill.speaking: [],
    };
    for (final r in results) {
      bandHistory[r.skill]!.add(r.bandScore);
    }
    final Map<TestSkill, double> averages = {};
    for (final skill in TestSkill.values) {
      final list = bandHistory[skill]!;
      averages[skill] = list.isEmpty ? 0.0 : list.reduce((a, b) => a + b) / list.length;
    }
    final totalMinutes = results.fold<int>(0, (sum, r) => sum + (r.timeTakenSeconds ~/ 60));
    return UserProgress(
      bandHistory: bandHistory,
      totalTestsTaken: results.length,
      totalStudyMinutes: totalMinutes,
      averageBands: averages,
      currentStreak: _calculateStreak(results),
      lastStudyDate: results.isNotEmpty ? results.first.completedAt : DateTime.now(),
    );
  }

  static int _calculateStreak(List<TestResult> results) {
    if (results.isEmpty) return 0;
    int streak = 1;
    final sorted = results..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i - 1].completedAt.difference(sorted[i].completedAt).inDays;
      if (diff <= 1) streak++; else break;
    }
    return streak;
  }

  static Map<String, dynamic> _encodeResult(TestResult r) => {
    'id': r.id, 'testId': r.testId, 'testTitle': r.testTitle,
    'skill': r.skill.index, 'bandScore': r.bandScore,
    'correctAnswers': r.correctAnswers, 'totalQuestions': r.totalQuestions,
    'timeTakenSeconds': r.timeTakenSeconds,
    'completedAt': r.completedAt.toIso8601String(),
    'userAnswers': r.userAnswers,
  };

  static TestResult _decodeResult(Map<String, dynamic> m) => TestResult(
    id: m['id'], testId: m['testId'], testTitle: m['testTitle'] ?? '',
    skill: TestSkill.values[m['skill'] ?? 0],
    bandScore: (m['bandScore'] ?? 0).toDouble(),
    correctAnswers: m['correctAnswers'] ?? 0, totalQuestions: m['totalQuestions'] ?? 0,
    timeTakenSeconds: m['timeTakenSeconds'] ?? 0,
    completedAt: DateTime.parse(m['completedAt']),
    userAnswers: Map<String, String>.from(m['userAnswers'] ?? {}),
  );

  // Demo data for first launch
  static Future<void> seedDemoData() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('seeded') == true) return;
    final now = DateTime.now();
    final demoResults = [
      TestResult(id: 'd1', testId: 'l001', testTitle: 'Listening Mock Test 1',
        skill: TestSkill.listening, bandScore: 6.5, correctAnswers: 31, totalQuestions: 40,
        timeTakenSeconds: 1800, completedAt: now.subtract(const Duration(days: 6)),
        userAnswers: {}),
      TestResult(id: 'd2', testId: 'r001', testTitle: 'Academic Reading Test 1',
        skill: TestSkill.reading, bandScore: 7.0, correctAnswers: 33, totalQuestions: 40,
        timeTakenSeconds: 3600, completedAt: now.subtract(const Duration(days: 5)),
        userAnswers: {}),
      TestResult(id: 'd3', testId: 'w001', testTitle: 'Academic Writing Test 1',
        skill: TestSkill.writing, bandScore: 6.0, correctAnswers: 1, totalQuestions: 2,
        timeTakenSeconds: 3600, completedAt: now.subtract(const Duration(days: 4)),
        userAnswers: {}),
      TestResult(id: 'd4', testId: 'l001', testTitle: 'Listening Mock Test 1',
        skill: TestSkill.listening, bandScore: 7.0, correctAnswers: 34, totalQuestions: 40,
        timeTakenSeconds: 1750, completedAt: now.subtract(const Duration(days: 3)),
        userAnswers: {}),
      TestResult(id: 'd5', testId: 'r002', testTitle: 'General Training Reading Test 1',
        skill: TestSkill.reading, bandScore: 7.5, correctAnswers: 37, totalQuestions: 40,
        timeTakenSeconds: 3400, completedAt: now.subtract(const Duration(days: 2)),
        userAnswers: {}),
      TestResult(id: 'd6', testId: 's001', testTitle: 'Speaking Mock Test 1',
        skill: TestSkill.speaking, bandScore: 6.5, correctAnswers: 1, totalQuestions: 3,
        timeTakenSeconds: 900, completedAt: now.subtract(const Duration(days: 1)),
        userAnswers: {}),
    ];
    for (final r in demoResults) { await saveResult(r); }
    await prefs.setBool('seeded', true);
  }
}
