import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/test_provider.dart';
import '../../services/ai_examiner_service.dart';

class SpeakingTestScreen extends StatefulWidget {
  final String testId;
  const SpeakingTestScreen({super.key, required this.testId});
  @override
  State<SpeakingTestScreen> createState() => _SpeakingTestScreenState();
}

class _SpeakingTestScreenState extends State<SpeakingTestScreen>
    with SingleTickerProviderStateMixin {
  IELTSTest? _test;
  int _currentPart = 0;
  int _currentQuestion = 0;
  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isSubmitting = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  final Map<String, String> _transcripts = {};
  final _transcriptCtrl = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _test = context.read<TestProvider>().getTestById(widget.testId);
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseAnim = Tween<double>(begin: 1, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  List<Question> get _currentPartQuestions {
    if (_test == null || _test!.sections.length <= _currentPart) return [];
    return _test!.sections[_currentPart].questions;
  }

  Question? get _currentQuestionData {
    if (_currentQuestion >= _currentPartQuestions.length) return null;
    return _currentPartQuestions[_currentQuestion];
  }

  void _toggleRecording() {
    if (_isRecording) {
      _recordingTimer?.cancel();
      _pulseController.stop();
      setState(() { _isRecording = false; _hasRecorded = true; });
    } else {
      setState(() { _isRecording = true; _hasRecorded = false; _recordingSeconds = 0; });
      _pulseController.repeat(reverse: true);
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= 120) _toggleRecording();
      });
    }
  }

  void _saveAndNext() {
    final q = _currentQuestionData;
    if (q != null) {
      _transcripts[q.id] = _transcriptCtrl.text.isEmpty
          ? '[Voice recording – ${_recordingSeconds}s]'
          : _transcriptCtrl.text;
    }
    _transcriptCtrl.clear();
    setState(() { _hasRecorded = false; _recordingSeconds = 0; });

    final partQuestions = _currentPartQuestions;
    if (_currentQuestion < partQuestions.length - 1) {
      setState(() => _currentQuestion++);
    } else if (_test != null && _currentPart < _test!.sections.length - 1) {
      setState(() { _currentPart++; _currentQuestion = 0; });
    } else {
      _submitTest();
    }
  }

  Future<void> _submitTest() async {
    setState(() => _isSubmitting = true);
    final q = _currentQuestionData;
    final transcript = _transcripts.values.join(' ');

    AIFeedback? feedback;
    if (transcript.trim().length > 10) {
      try {
        feedback = await AIExaminerService.evaluateSpeaking(
          questionText: q?.text ?? '',
          transcribedResponse: transcript,
        );
      } catch (_) {}
    }

    final result = TestResult(
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
      testId: widget.testId, userId: 'user_001',
      skill: TestSkill.speaking,
      bandScore: feedback?.overallScore ?? 6.5,
      correctAnswers: 0, totalQuestions: _transcripts.length,
      timeTakenSeconds: 0, completedAt: DateTime.now(),
      answers: _transcripts, aiFeedback: feedback,
    );

    if (mounted) {
      context.read<TestProvider>().addResult(result);
      context.go('/home/results/${result.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_test == null) return const Scaffold(body: Center(child: Text('Test not found')));
    final q = _currentQuestionData;

    return Scaffold(
      appBar: AppBar(
        title: Text('Speaking – Part ${_currentPart + 1}'),
        backgroundColor: const Color(0xFF9C27B0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Part indicators
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_test!.sections.length, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: i == _currentPart ? const Color(0xFF9C27B0) : i < _currentPart ? Colors.green : Colors.grey.shade200,
                  child: Text('${i + 1}', style: TextStyle(color: i < _currentPart ? Colors.white : i == _currentPart ? Colors.white : Colors.grey, fontSize: 12)),
                ),
                const SizedBox(height: 4),
                Text('Part ${i + 1}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ]),
            )),
          ),
          const SizedBox(height: 24),

          // Question card
          if (q != null) Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                Card(
                  color: const Color(0xFF9C27B0).withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: const Color(0xFF9C27B0).withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Question ${_currentQuestion + 1}/${_currentPartQuestions.length}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text(q.text, style: const TextStyle(fontSize: 16, height: 1.6)),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Recording button
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _isRecording ? _pulseAnim.value : 1,
                    child: child,
                  ),
                  child: GestureDetector(
                    onTap: _toggleRecording,
                    child: Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isRecording ? Colors.red : const Color(0xFF9C27B0),
                        boxShadow: [BoxShadow(color: (_isRecording ? Colors.red : const Color(0xFF9C27B0)).withOpacity(0.3), blurRadius: 20, spreadRadius: 4)],
                      ),
                      child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRecording ? 'Recording... ${_recordingSeconds}s (tap to stop)' : _hasRecorded ? '✅ Recorded ${_recordingSeconds}s' : 'Tap to start recording',
                  style: TextStyle(color: _isRecording ? Colors.red : Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Transcript (optional)
                TextField(
                  controller: _transcriptCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Type your answer (optional)',
                    hintText: 'You can type your response here for AI feedback...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ]),
            ),
          ),

          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: (!_hasRecorded && _transcriptCtrl.text.isEmpty) ? null : (_isSubmitting ? null : _saveAndNext),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C27B0)),
            child: _isSubmitting
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _currentPart == _test!.sections.length - 1 && _currentQuestion == _currentPartQuestions.length - 1
                        ? 'Submit & Get AI Score'
                        : 'Next Question →',
                  ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _pulseController.dispose();
    _transcriptCtrl.dispose();
    super.dispose();
  }
}
