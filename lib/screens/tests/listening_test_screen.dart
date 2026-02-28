import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/test_provider.dart';

class ListeningTestScreen extends StatefulWidget {
  final String testId;
  const ListeningTestScreen({super.key, required this.testId});
  @override
  State<ListeningTestScreen> createState() => _ListeningTestScreenState();
}

class _ListeningTestScreenState extends State<ListeningTestScreen> {
  final Map<String, dynamic> _answers = {};
  bool _audioPlaying = false;
  bool _audioDone = false;
  int _audioPositionSeconds = 0;
  int _audioDurationSeconds = 240; // 4 min simulated
  Timer? _audioTimer;
  IELTSTest? _test;
  int _currentSection = 0;

  @override
  void initState() {
    super.initState();
    _test = context.read<TestProvider>().getTestById(widget.testId);
  }

  void _toggleAudio() {
    if (_audioPlaying) {
      _audioTimer?.cancel();
      setState(() => _audioPlaying = false);
    } else {
      setState(() => _audioPlaying = true);
      _audioTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_audioPositionSeconds < _audioDurationSeconds) {
          setState(() => _audioPositionSeconds++);
        } else {
          _audioTimer?.cancel();
          setState(() { _audioPlaying = false; _audioDone = true; });
        }
      });
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_test == null) return const Scaffold(body: Center(child: Text('Test not found')));
    final sections = _test!.sections;
    final section = sections[_currentSection];

    return Scaffold(
      appBar: AppBar(
        title: Text('Listening – Section ${_currentSection + 1}'),
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        // Audio Player
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF1565C0)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.headphones, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(section.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderThemeData(trackHeight: 4, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8)),
              child: Slider(
                value: _audioPositionSeconds.toDouble(),
                max: _audioDurationSeconds.toDouble(),
                activeColor: Colors.white,
                inactiveColor: Colors.white.withOpacity(0.3),
                onChanged: (v) => setState(() => _audioPositionSeconds = v.toInt()),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_formatTime(_audioPositionSeconds), style: const TextStyle(color: Colors.white, fontSize: 12)),
              GestureDetector(
                onTap: _toggleAudio,
                child: Container(
                  width: 44, height: 44,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: Icon(_audioPlaying ? Icons.pause : Icons.play_arrow, color: const Color(0xFF1A73E8)),
                ),
              ),
              Text(_formatTime(_audioDurationSeconds), style: const TextStyle(color: Colors.white, fontSize: 12)),
            ]),
            if (!_audioDone && !_audioPlaying)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Press play to start the audio', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
              ),
          ]),
        ),

        // Section navigation
        if (sections.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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

        // Questions
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: section.questions.length,
            itemBuilder: (_, i) => _buildQuestion(section.questions[i], i),
          ),
        ),

        // Submit
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A73E8)),
            child: const Text('Submit Answers'),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuestion(Question q, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Q${index + 1}', style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(q.text, style: const TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 10),
          if (q.type == QuestionType.multipleChoice && q.options != null)
            ...q.options!.map((opt) => RadioListTile<String>(
              dense: true, value: opt,
              groupValue: _answers[q.id],
              onChanged: (v) => setState(() => _answers[q.id] = v),
              title: Text(opt, style: const TextStyle(fontSize: 14)),
            ))
          else
            TextField(
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => _answers[q.id] = v,
            ),
        ]),
      ),
    );
  }

  void _submit() {
    _audioTimer?.cancel();
    if (_test == null) return;

    int correct = 0, total = 0;
    for (final section in _test!.sections) {
      for (final q in section.questions) {
        total++;
        if (_answers[q.id]?.toString().toUpperCase() == q.correctAnswer?.toString().toUpperCase()) correct++;
      }
    }

    final bandScore = _calculateBandScore(correct, total);
    final result = TestResult(
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
      testId: widget.testId, userId: 'user_001',
      skill: TestSkill.listening,
      bandScore: bandScore, correctAnswers: correct, totalQuestions: total,
      timeTakenSeconds: 0, completedAt: DateTime.now(), answers: _answers,
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
    return 5.0;
  }

  @override
  void dispose() { _audioTimer?.cancel(); super.dispose(); }
}
