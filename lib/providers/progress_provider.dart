import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';

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

  void updateSkillScore(TestSkill skill, double newScore) {
    final idx = _skillProgress.indexWhere((s) => s.skill == skill);
    if (idx >= 0) {
      final old = _skillProgress[idx];
      _skillProgress[idx] = SkillProgress(
        skill: old.skill,
        bandScoreHistory: [...old.bandScoreHistory, newScore],
        currentBandScore: newScore,
        targetBandScore: old.targetBandScore,
        weakestArea: old.weakestArea,
      );
      notifyListeners();
    }
  }
}
