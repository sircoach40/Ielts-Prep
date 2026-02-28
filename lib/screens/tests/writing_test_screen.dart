import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/test_provider.dart';
import '../../services/ai_examiner_service.dart';

class WritingTestScreen extends StatefulWidget {
  final String testId;
  const WritingTestScreen({super.key, required this.testId});
  @override
  State<WritingTestScreen> createState() => _WritingTestScreenState();
}

class _WritingTestScreenState extends State<WritingTestScreen> {
  final _task1Controller = TextEditingController();
  final _task2Controller = TextEditingController();
  int _currentTask = 0;
  late Timer _timer;
  int _remainingSeconds = 3600; // 60 minutes
  bool _isSubmitting = false;
  IELTSTest? _test;

  @override
  void initState() {
    super.initState();
    _test = context.read<TestProvider>().getTestById(widget.testId);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer.cancel();
        _submitTest();
      }
    });
  }

  String get _timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get _isLowTime => _remainingSeconds < 300;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Writing Test'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _isLowTime ? Colors.red : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Icons.timer, color: _isLowTime ? Colors.white : Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(_timeDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        // Task Tabs
        Container(
          color: Colors.grey.shade100,
          child: Row(children: [
            _TaskTab('Task 1', 0, '150+ words'),
            _TaskTab('Task 2', 1, '250+ words'),
          ]),
        ),
        Expanded(
          child: IndexedStack(
            index: _currentTask,
            children: [
              _buildTaskPanel(0, _task1Controller),
              _buildTaskPanel(1, _task2Controller),
            ],
          ),
        ),
        _BottomBar(
          wordCount: _currentTask == 0 ? _wordCount(_task1Controller.text) : _wordCount(_task2Controller.text),
          minWords: _currentTask == 0 ? 150 : 250,
          onSubmit: _isSubmitting ? null : _submitTest,
          isSubmitting: _isSubmitting,
        ),
      ]),
    );
  }

  Widget _buildTaskPanel(int taskIndex, TextEditingController controller) {
    if (_test == null || _test!.sections.length <= taskIndex) {
      return const Center(child: Text('Task not found'));
    }

    final section = _test!.sections[taskIndex];
    final question = section.questions.isNotEmpty ? section.questions[0].text : '';

    return Column(children: [
      Expanded(
        flex: 2,
        child: Container(
          color: Colors.amber.shade50,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.help_outline, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Text('Task ${taskIndex + 1} Question', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
              ]),
              const SizedBox(height: 8),
              Text(question, style: const TextStyle(fontSize: 14, height: 1.6)),
            ]),
          ),
        ),
      ),
      Expanded(
        flex: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              hintText: 'Start writing your response here...',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ),
    ]);
  }

  Widget _TaskTab(String label, int index, String wordReq) {
    final selected = _currentTask == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTask = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: selected ? const Color(0xFFFF6B35) : Colors.transparent, width: 2)),
          ),
          child: Column(children: [
            Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal, color: selected ? const Color(0xFFFF6B35) : Colors.grey)),
            Text(wordReq, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ]),
        ),
      ),
    );
  }

  int _wordCount(String text) => text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  Future<void> _submitTest() async {
    _timer.cancel();
    setState(() => _isSubmitting = true);

    // Get AI feedback for task 2 essay
    final section = _test?.sections.isNotEmpty == true ? _test!.sections[1] : null;
    final prompt = section?.questions.isNotEmpty == true ? section!.questions[0].text : '';
    final response = _task2Controller.text;

    AIFeedback? aiFeedback;
    if (response.trim().length > 20) {
      try {
        aiFeedback = await AIExaminerService.evaluateWriting(
          prompt: prompt, response: response, taskType: 'task2',
        );
      } catch (_) {}
    }

    final result = TestResult(
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
      testId: widget.testId,
      userId: 'user_001',
      skill: TestSkill.writing,
      bandScore: aiFeedback?.overallScore ?? 6.0,
      correctAnswers: 0,
      totalQuestions: 2,
      timeTakenSeconds: 3600 - _remainingSeconds,
      completedAt: DateTime.now(),
      answers: {'task1': _task1Controller.text, 'task2': _task2Controller.text},
      aiFeedback: aiFeedback,
    );

    if (mounted) {
      context.read<TestProvider>().addResult(result);
      setState(() => _isSubmitting = false);
      context.go('/home/results/${result.id}');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _task1Controller.dispose();
    _task2Controller.dispose();
    super.dispose();
  }
}

class _BottomBar extends StatelessWidget {
  final int wordCount, minWords;
  final VoidCallback? onSubmit;
  final bool isSubmitting;

  const _BottomBar({required this.wordCount, required this.minWords, required this.onSubmit, required this.isSubmitting});

  @override
  Widget build(BuildContext context) {
    final meetsMin = wordCount >= minWords;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$wordCount words', style: TextStyle(fontWeight: FontWeight.bold, color: meetsMin ? Colors.green : Colors.orange)),
          Text('Minimum: $minWords', style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
        const Spacer(),
        SizedBox(
          width: 140,
          child: ElevatedButton(
            onPressed: onSubmit,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), minimumSize: const Size(0, 42)),
            child: isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit & Score'),
          ),
        ),
      ]),
    );
  }
}
