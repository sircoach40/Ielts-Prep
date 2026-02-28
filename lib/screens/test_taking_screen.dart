import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/progress_service.dart';
import 'package:uuid/uuid.dart';
import 'result_screen.dart';

class TestTakingScreen extends StatefulWidget {
  final IELTSTest test;
  const TestTakingScreen({super.key, required this.test});
  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  int _currentSectionIndex = 0;
  int _currentQuestionIndex = 0;
  final Map<String, String> _answers = {};
  int _elapsedSeconds = 0;
  Timer? _timer;
  late int _totalSeconds;
  bool _isWritingMode = false;
  final _writingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.test.durationMinutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
      if (_elapsedSeconds >= _totalSeconds) _submitTest();
    });
    _isWritingMode = widget.test.skill == TestSkill.writing || widget.test.skill == TestSkill.speaking;
  }

  @override
  void dispose() { _timer?.cancel(); _writingController.dispose(); super.dispose(); }

  TestSection get _currentSection => widget.test.sections[_currentSectionIndex];
  Question get _currentQuestion => _currentSection.questions[_currentQuestionIndex];
  int get _remainingSeconds => _totalSeconds - _elapsedSeconds;
  bool get _isLastQuestion {
    final isLastSection = _currentSectionIndex == widget.test.sections.length - 1;
    final isLastInSection = _currentQuestionIndex == _currentSection.questions.length - 1;
    return isLastSection && isLastInSection;
  }

  void _nextQuestion() {
    if (_currentSectionIndex < widget.test.sections.length - 1 &&
        _currentQuestionIndex == _currentSection.questions.length - 1) {
      setState(() { _currentSectionIndex++; _currentQuestionIndex = 0; });
    } else if (_currentQuestionIndex < _currentSection.questions.length - 1) {
      setState(() => _currentQuestionIndex++);
    }
    if (_isWritingMode) {
      _writingController.text = _answers[_currentQuestion.id] ?? '';
    }
  }

  void _prevQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() => _currentQuestionIndex--);
    } else if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
        _currentQuestionIndex = widget.test.sections[_currentSectionIndex].questions.length - 1;
      });
    }
    if (_isWritingMode) {
      _writingController.text = _answers[_currentQuestion.id] ?? '';
    }
  }

  Future<void> _submitTest() async {
    _timer?.cancel();
    if (_isWritingMode && _writingController.text.isNotEmpty) {
      _answers[_currentQuestion.id] = _writingController.text;
    }
    // Calculate score
    int correct = 0;
    final allQuestions = widget.test.sections.expand((s) => s.questions).toList();
    for (final q in allQuestions) {
      if (q.type != QuestionType.essay && q.type != QuestionType.shortAnswer) {
        if (_answers[q.id] == q.correctAnswer) correct++;
      }
    }
    final totalQ = allQuestions.length;
    // Calculate band score (simplified formula)
    double band;
    if (widget.test.skill == TestSkill.writing || widget.test.skill == TestSkill.speaking) {
      band = 6.0; // Will be replaced by AI
    } else {
      final pct = totalQ > 0 ? correct / totalQ : 0;
      if (pct >= 0.9) band = 8.5;
      else if (pct >= 0.8) band = 7.5;
      else if (pct >= 0.7) band = 7.0;
      else if (pct >= 0.6) band = 6.5;
      else if (pct >= 0.5) band = 6.0;
      else if (pct >= 0.4) band = 5.5;
      else band = 5.0;
    }

    final result = TestResult(
      id: const Uuid().v4(), testId: widget.test.id, testTitle: widget.test.title,
      skill: widget.test.skill, bandScore: band, correctAnswers: correct,
      totalQuestions: totalQ, timeTakenSeconds: _elapsedSeconds,
      completedAt: DateTime.now(), userAnswers: Map.from(_answers),
    );
    await ProgressService.saveResult(result);

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => ResultScreen(result: result, test: widget.test, userAnswers: _answers)));
  }

  @override
  Widget build(BuildContext context) {
    final mins = _remainingSeconds ~/ 60;
    final secs = _remainingSeconds % 60;
    final isLowTime = _remainingSeconds < 300;
    final allQuestions = widget.test.sections.expand((s) => s.questions).toList();
    final currentGlobalIndex = widget.test.sections.take(_currentSectionIndex)
        .fold<int>(0, (s, e) => s + e.questions.length) + _currentQuestionIndex;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.test.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(_currentSection.title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ]),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isLowTime ? AppTheme.error.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Icon(Icons.timer, size: 14, color: isLowTime ? AppTheme.error : AppTheme.success),
              const SizedBox(width: 4),
              Text('${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                style: TextStyle(fontWeight: FontWeight.bold, color: isLowTime ? AppTheme.error : AppTheme.success)),
            ]),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: allQuestions.isEmpty ? 0 : (currentGlobalIndex + 1) / allQuestions.length,
            backgroundColor: Colors.grey.shade200,
            color: AppTheme.primary,
            minHeight: 4,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Question ${currentGlobalIndex + 1} of ${allQuestions.length}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              TextButton.icon(
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Submit', style: TextStyle(fontSize: 13)),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Submit Test?'),
                    content: Text('You have answered ${_answers.length} of ${allQuestions.length} questions.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      ElevatedButton(onPressed: () { Navigator.pop(context); _submitTest(); }, child: const Text('Submit')),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          Expanded(
            child: _isWritingMode ? _buildWritingInterface() : _buildMCQInterface(),
          ),
          _buildNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildMCQInterface() {
    final q = _currentQuestion;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentSection.passage != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.article, size: 16, color: AppTheme.primary),
                  SizedBox(width: 6),
                  Text('Reading Passage', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 13)),
                ]),
                const SizedBox(height: 8),
                Text(_currentSection.passage!, style: const TextStyle(fontSize: 13, height: 1.6), maxLines: 6, overflow: TextOverflow.ellipsis),
                TextButton(onPressed: () => _showFullPassage(), child: const Text('Read full passage')),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
            child: Text(q.text, style: const TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(height: 20),
          if (q.type == QuestionType.multipleChoice || q.type == QuestionType.trueFalseNotGiven || q.type == QuestionType.matchingHeadings)
            ...(q.options ?? []).map((option) {
              final isSelected = _answers[q.id] == option.substring(0, option.indexOf('.') > 0 ? option.indexOf('.') : 1).trim();
              return GestureDetector(
                onTap: () => setState(() => _answers[q.id] = option.substring(0, option.indexOf('.') > 0 ? option.indexOf('.') : 1).trim()),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : Colors.white,
                    border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Container(width: 24, height: 24, decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? Colors.white : Colors.transparent,
                      border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey.shade400),
                    ), child: isSelected ? const Icon(Icons.check, size: 14, color: AppTheme.primary) : null),
                    const SizedBox(width: 12),
                    Expanded(child: Text(option, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 14))),
                  ]),
                ),
              );
            })
          else ...[
            TextField(
              onChanged: (v) => _answers[q.id] = v,
              decoration: const InputDecoration(hintText: 'Type your answer here...'),
              controller: TextEditingController(text: _answers[q.id] ?? ''),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWritingInterface() {
    final q = _currentQuestion;
    final wordCount = _writingController.text.trim().isEmpty ? 0 : _writingController.text.trim().split(RegExp(r'\s+')).length;
    final minWords = q.number == 1 ? 150 : 250;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200)),
            child: SingleChildScrollView(
              child: Text(q.text, style: const TextStyle(fontSize: 13, height: 1.5)),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: _writingController,
              maxLines: null, expands: true,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (v) { _answers[q.id] = v; setState(() {}); },
              decoration: const InputDecoration(
                hintText: 'Write your response here...',
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Words: $wordCount / $minWords min',
              style: TextStyle(color: wordCount >= minWords ? AppTheme.success : AppTheme.textSecondary, fontSize: 13)),
            Row(children: [
              const Icon(Icons.auto_awesome, size: 14, color: AppTheme.accent),
              const SizedBox(width: 4),
              const Text('AI feedback after submission', style: TextStyle(color: AppTheme.accent, fontSize: 12)),
            ]),
          ]),
        ],
      ),
    );
  }

  void _showFullPassage() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8, maxChildSize: 0.95, minChildSize: 0.5,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(_currentSection.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            Expanded(child: SingleChildScrollView(controller: controller,
              child: Text(_currentSection.passage ?? '', style: const TextStyle(fontSize: 14, height: 1.7)))),
          ]),
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: _currentSectionIndex == 0 && _currentQuestionIndex == 0 ? null : _prevQuestion,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Previous'),
        )),
        const SizedBox(width: 12),
        Expanded(child: ElevatedButton.icon(
          onPressed: _isLastQuestion ? _submitTest : _nextQuestion,
          icon: Icon(_isLastQuestion ? Icons.check : Icons.chevron_right),
          label: Text(_isLastQuestion ? 'Submit' : 'Next'),
        )),
      ]),
    );
  }
}
