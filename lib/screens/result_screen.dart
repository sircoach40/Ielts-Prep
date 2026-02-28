import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/ai_service.dart';
import '../services/progress_service.dart';

class ResultScreen extends StatefulWidget {
  final TestResult result;
  final IELTSTest test;
  final Map<String, String> userAnswers;
  const ResultScreen({super.key, required this.result, required this.test, required this.userAnswers});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnimation;
  AIFeedback? _aiFeedback;
  bool _isLoadingAI = false;
  bool _showAnswerReview = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _scoreAnimation = Tween<double>(begin: 0, end: widget.result.bandScore)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    if (widget.test.skill == TestSkill.writing || widget.test.skill == TestSkill.speaking) {
      _fetchAIFeedback();
    }
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _fetchAIFeedback() async {
    setState(() => _isLoadingAI = true);
    final allQuestions = widget.test.sections.expand((s) => s.questions).toList();
    final essayQ = allQuestions.firstWhere((q) => q.type == QuestionType.essay, orElse: () => allQuestions.first);
    final userEssay = widget.userAnswers[essayQ.id] ?? 'No response provided.';

    AIFeedback feedback;
    if (widget.test.skill == TestSkill.writing) {
      feedback = await AIService.evaluateWriting(
        essay: userEssay, taskPrompt: essayQ.text,
        isTask1: essayQ.number == 1,
      );
    } else {
      feedback = await AIService.evaluateSpeaking(
        transcription: userEssay, questionText: essayQ.text, partType: 'Part 2',
      );
    }

    // Update result with AI feedback
    widget.result.aiFeedback = feedback;
    await ProgressService.saveResult(widget.result);
    if (mounted) setState(() { _aiFeedback = feedback; _isLoadingAI = false; });
  }

  Color get _bandColor {
    final band = widget.result.bandScore;
    if (band >= 8) return AppTheme.success;
    if (band >= 7) return AppTheme.primary;
    if (band >= 6) return AppTheme.secondary;
    if (band >= 5) return AppTheme.warning;
    return AppTheme.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.home), onPressed: () =>
            Navigator.popUntil(context, (r) => r.isFirst)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildScoreHeader(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _buildStatsRow(),
                const SizedBox(height: 24),
                if (widget.test.skill == TestSkill.writing || widget.test.skill == TestSkill.speaking)
                  _buildAIFeedbackSection(),
                if (widget.test.skill != TestSkill.writing && widget.test.skill != TestSkill.speaking)
                  _buildAnswerReview(),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 32),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_bandColor, _bandColor.withOpacity(0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Column(children: [
        const Text('Your Band Score', style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _scoreAnimation,
          builder: (_, __) => Text(_scoreAnimation.value.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: Text(_getBandDescription(widget.result.bandScore),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 16),
        Text(widget.test.title, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
      ]),
    );
  }

  String _getBandDescription(double band) {
    if (band >= 8.5) return 'Expert';
    if (band >= 8.0) return 'Very Good';
    if (band >= 7.0) return 'Good';
    if (band >= 6.0) return 'Competent';
    if (band >= 5.0) return 'Modest';
    return 'Limited';
  }

  Widget _buildStatsRow() {
    final mins = widget.result.timeTakenSeconds ~/ 60;
    final secs = widget.result.timeTakenSeconds % 60;
    return Row(children: [
      _buildStatCard('Correct', '${widget.result.correctAnswers}/${widget.result.totalQuestions}', Icons.check_circle_outline, AppTheme.success),
      const SizedBox(width: 8),
      _buildStatCard('Accuracy', '${widget.result.accuracy.toStringAsFixed(0)}%', Icons.percent, AppTheme.primary),
      const SizedBox(width: 8),
      _buildStatCard('Time', '${mins}m ${secs}s', Icons.timer_outlined, AppTheme.secondary),
    ]);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ]),
      ),
    ));
  }

  Widget _buildAIFeedbackSection() {
    if (_isLoadingAI) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('AI Examiner is analyzing your response...', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('This may take a moment', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
        ),
      );
    }
    if (_aiFeedback == null) return const SizedBox();

    final f = _aiFeedback!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 20),
        const SizedBox(width: 8),
        const Text('AI Examiner Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ]),
      const SizedBox(height: 12),
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Criteria Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          _buildCriteriaRow('Task Achievement', f.taskAchievementScore),
          _buildCriteriaRow('Coherence & Cohesion', f.coherenceCohesionScore),
          _buildCriteriaRow('Lexical Resource', f.lexicalResourceScore),
          _buildCriteriaRow('Grammatical Range', f.grammaticalRangeScore),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Overall Band', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(f.overallBand.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _bandColor)),
          ]),
        ]),
      )),
      const SizedBox(height: 12),
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Overall Feedback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(f.overallFeedback, style: const TextStyle(height: 1.5, color: AppTheme.textSecondary)),
        ]),
      )),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Card(
          color: AppTheme.success.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.thumb_up_outlined, color: AppTheme.success, size: 16),
                SizedBox(width: 6), Text('Strengths', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.success, fontSize: 13))]),
              const SizedBox(height: 8),
              ...f.strengths.map((s) => Padding(padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('• ', style: TextStyle(color: AppTheme.success)),
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 12))),
                ]))),
            ]),
          ),
        )),
        const SizedBox(width: 8),
        Expanded(child: Card(
          color: AppTheme.warning.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [Icon(Icons.trending_up, color: AppTheme.warning, size: 16),
                SizedBox(width: 6), Text('Improve', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning, fontSize: 13))]),
              const SizedBox(height: 8),
              ...f.improvements.map((s) => Padding(padding: const EdgeInsets.only(bottom: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('• ', style: TextStyle(color: AppTheme.warning)),
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 12))),
                ]))),
            ]),
          ),
        )),
      ]),
    ]);
  }

  Widget _buildCriteriaRow(String label, double score) {
    final color = score >= 7 ? AppTheme.success : score >= 6 ? AppTheme.primary : AppTheme.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        const SizedBox(width: 8),
        SizedBox(width: 120, child: LinearProgressIndicator(
          value: score / 9, backgroundColor: Colors.grey.shade200, color: color, minHeight: 6)),
        const SizedBox(width: 8),
        Text(score.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }

  Widget _buildAnswerReview() {
    final allSections = widget.test.sections;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Answer Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        TextButton(
          onPressed: () => setState(() => _showAnswerReview = !_showAnswerReview),
          child: Text(_showAnswerReview ? 'Hide' : 'Show All'),
        ),
      ]),
      if (_showAnswerReview)
        ...allSections.expand((section) => section.questions).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final q = entry.value;
          if (q.type == QuestionType.essay) return const SizedBox();
          final userAns = widget.userAnswers[q.id] ?? 'Not answered';
          final isCorrect = userAns == q.correctAnswer;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(radius: 12, backgroundColor: isCorrect ? AppTheme.success : AppTheme.error,
                    child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 10))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(q.text, style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  const SizedBox(width: 32),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Your answer: $userAns', style: TextStyle(fontSize: 12, color: isCorrect ? AppTheme.success : AppTheme.error)),
                    if (!isCorrect) Text('Correct: ${q.correctAnswer}', style: const TextStyle(fontSize: 12, color: AppTheme.success)),
                  ]),
                ]),
                if (!isCorrect && q.explanation != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text('💡 ${q.explanation}', style: const TextStyle(fontSize: 11, color: AppTheme.primary)),
                  ),
                ],
              ]),
            ),
          );
        }),
    ]);
  }

  Widget _buildActionButtons() {
    return Column(children: [
      SizedBox(width: double.infinity, child: ElevatedButton.icon(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        icon: const Icon(Icons.replay),
        label: const Text('Try Another Test'),
      )),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
        icon: const Icon(Icons.home_outlined),
        label: const Text('Back to Home'),
      )),
    ]);
  }
}
