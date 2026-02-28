import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/test_provider.dart';

class ReadingTestScreen extends StatefulWidget {
  final String testId;
  const ReadingTestScreen({super.key, required this.testId});
  @override
  State<ReadingTestScreen> createState() => _ReadingTestScreenState();
}

class _ReadingTestScreenState extends State<ReadingTestScreen> {
  final Map<String, dynamic> _answers = {};
  int _currentSection = 0;
  late Timer _timer;
  int _remainingSeconds = 3600;
  IELTSTest? _test;
  bool _showPassage = true;

  @override
  void initState() {
    super.initState();
    _test = context.read<TestProvider>().getTestById(widget.testId);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) setState(() => _remainingSeconds--);
      else { _timer.cancel(); _submit(); }
    });
  }

  String get _timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_test == null) return const Scaffold(body: Center(child: Text('Test not found')));
    final sections = _test!.sections;
    final section = sections[_currentSection];

    return Scaffold(
      appBar: AppBar(
        title: Text('Section ${_currentSection + 1}/${sections.length}'),
        backgroundColor: const Color(0xFF34A853),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showPassage ? Icons.question_answer : Icons.article),
            tooltip: _showPassage ? 'Show Questions' : 'Show Passage',
            onPressed: () => setState(() => _showPassage = !_showPassage),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(_timeDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(children: [
        // Section nav
        if (sections.length > 1)
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(sections.length, (i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('Section ${i + 1}'),
                  selected: _currentSection == i,
                  onSelected: (_) => setState(() => _currentSection = i),
                ),
              )),
            ),
          ),
        Expanded(
          child: _showPassage ? _buildPassage(section) : _buildQuestions(section),
        ),
        _BottomControls(
          onToggle: () => setState(() => _showPassage = !_showPassage),
          showPassage: _showPassage,
          onSubmit: _submit,
          answeredCount: _answers.length,
          totalQuestions: sections.fold(0, (sum, s) => sum + s.questions.length),
        ),
      ]),
    );
  }

  Widget _buildPassage(TestSection section) => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(section.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      if (section.passage != null)
        Text(section.passage!, style: const TextStyle(fontSize: 15, height: 1.8))
      else
        const Text('No passage for this section.'),
    ]),
  );

  Widget _buildQuestions(TestSection section) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: section.questions.length,
    itemBuilder: (_, i) => _buildQuestion(section.questions[i], i),
  );

  Widget _buildQuestion(Question q, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Question ${index + 1}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          Text(q.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5)),
          const SizedBox(height: 12),
          if (q.type == QuestionType.multipleChoice && q.options != null)
            ...q.options!.map((opt) => RadioListTile<String>(
              value: opt, groupValue: _answers[q.id],
              onChanged: (v) => setState(() => _answers[q.id] = v),
              title: Text(opt),
              dense: true,
            ))
          else if (q.type == QuestionType.trueFalseNotGiven)
            Wrap(spacing: 8, children: ['TRUE', 'FALSE', 'NOT GIVEN'].map((opt) => ChoiceChip(
              label: Text(opt, style: const TextStyle(fontSize: 12)),
              selected: _answers[q.id] == opt,
              onSelected: (_) => setState(() => _answers[q.id] = opt),
            )).toList())
          else
            TextField(
              decoration: const InputDecoration(hintText: 'Your answer...', isDense: true),
              onChanged: (v) => _answers[q.id] = v,
            ),
        ]),
      ),
    );
  }

  void _submit() {
    _timer.cancel();
    if (_test == null) return;

    // Calculate score
    int correct = 0;
    int total = 0;
    for (final section in _test!.sections) {
      for (final q in section.questions) {
        total++;
        if (_answers[q.id]?.toString().toUpperCase() == q.correctAnswer?.toString().toUpperCase()) {
          correct++;
        }
      }
    }

    final bandScore = _calculateBandScore(correct, total);
    final result = TestResult(
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
      testId: widget.testId,
      userId: 'user_001',
      skill: TestSkill.reading,
      bandScore: bandScore,
      correctAnswers: correct,
      totalQuestions: total,
      timeTakenSeconds: 3600 - _remainingSeconds,
      completedAt: DateTime.now(),
      answers: _answers,
    );

    context.read<TestProvider>().addResult(result);
    context.go('/home/results/${result.id}');
  }

  double _calculateBandScore(int correct, int total) {
    if (total == 0) return 0;
    final pct = correct / total;
    if (pct >= 0.9) return 9.0;
    if (pct >= 0.8) return 8.0;
    if (pct >= 0.7) return 7.0;
    if (pct >= 0.6) return 6.0;
    if (pct >= 0.5) return 5.5;
    if (pct >= 0.4) return 5.0;
    return 4.0;
  }

  @override
  void dispose() { _timer.cancel(); super.dispose(); }
}

class _BottomControls extends StatelessWidget {
  final VoidCallback onToggle, onSubmit;
  final bool showPassage;
  final int answeredCount, totalQuestions;

  const _BottomControls({
    required this.onToggle, required this.onSubmit,
    required this.showPassage, required this.answeredCount, required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        OutlinedButton.icon(
          onPressed: onToggle,
          icon: Icon(showPassage ? Icons.list : Icons.article, size: 16),
          label: Text(showPassage ? 'Questions' : 'Passage'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
        ),
        const Spacer(),
        Text('$answeredCount/$totalQuestions answered', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onSubmit,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34A853), minimumSize: const Size(0, 40)),
          child: const Text('Submit'),
        ),
      ]),
    );
  }
}
