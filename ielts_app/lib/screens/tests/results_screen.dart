import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/test_provider.dart';

class ResultsScreen extends StatelessWidget {
  final String resultId;
  const ResultsScreen({super.key, required this.resultId});

  @override
  Widget build(BuildContext context) {
    final results = context.read<TestProvider>().results;
    TestResult? result;
    try { result = results.firstWhere((r) => r.id == resultId); } catch (_) {}

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Results')),
        body: const Center(child: Text('Result not found')),
      );
    }

    final color = _skillColor(result.skill);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Results'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Band Score Hero
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
            ),
            child: Column(children: [
              const Text('Band Score', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 8),
              Text(result.bandScore.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold, height: 1)),
              const SizedBox(height: 4),
              Text(result.grade,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              if (result.skill != TestSkill.writing && result.skill != TestSkill.speaking)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _StatBadge('${result.correctAnswers}/${result.totalQuestions}', 'Correct'),
                  const SizedBox(width: 24),
                  _StatBadge('${(result.accuracy * 100).toStringAsFixed(0)}%', 'Accuracy'),
                  const SizedBox(width: 24),
                  _StatBadge(_formatTime(result.timeTakenSeconds), 'Time Taken'),
                ]),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // AI Feedback section
              if (result.aiFeedback != null) ...[
                _AIFeedbackCard(feedback: result.aiFeedback!),
                const SizedBox(height: 20),
              ],

              // Score breakdown
              if (result.aiFeedback != null) ...[
                const Text('Score Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _ScoreBar('Grammar', result.aiFeedback!.grammarScore, Colors.blue),
                _ScoreBar('Vocabulary', result.aiFeedback!.vocabularyScore, Colors.green),
                _ScoreBar('Coherence', result.aiFeedback!.coherenceScore, Colors.orange),
                if (result.aiFeedback!.pronunciationScore != null)
                  _ScoreBar('Pronunciation', result.aiFeedback!.pronunciationScore!, Colors.purple),
                const SizedBox(height: 20),
              ],

              // Action buttons
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () => context.go('/home/tests'),
                  icon: const Icon(Icons.replay),
                  label: const Text('Take Another Test'),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () => context.go('/home/ai-feedback'),
                  icon: const Icon(Icons.psychology),
                  label: const Text('AI Examiner'),
                )),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _StatBadge(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
  ]);

  Color _skillColor(TestSkill s) {
    switch (s) {
      case TestSkill.listening: return const Color(0xFF1A73E8);
      case TestSkill.reading: return const Color(0xFF34A853);
      case TestSkill.writing: return const Color(0xFFFF6B35);
      case TestSkill.speaking: return const Color(0xFF9C27B0);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}

class _AIFeedbackCard extends StatelessWidget {
  final AIFeedback feedback;
  const _AIFeedbackCard({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6200EE), Color(0xFF9C27B0)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Text('🤖', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text('AI Examiner Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
        const SizedBox(height: 12),
        Text(feedback.overallFeedback, style: TextStyle(color: Colors.white.withOpacity(0.9), height: 1.5, fontSize: 14)),
        const SizedBox(height: 16),
        _FeedbackSection('💪 Strengths', feedback.strengths, Colors.greenAccent),
        const SizedBox(height: 12),
        _FeedbackSection('📈 Areas to Improve', feedback.improvements, Colors.yellowAccent),
        if (feedback.improvedVersion != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('✨ Improved Opening', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Text(feedback.improvedVersion!, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontStyle: FontStyle.italic, height: 1.5)),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _FeedbackSection extends StatelessWidget {
  final String title;
  final List<FeedbackPoint> points;
  final Color accentColor;
  const _FeedbackSection(this.title, this.points, this.accentColor);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 13)),
      const SizedBox(height: 6),
      ...points.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 4, height: 4, margin: const EdgeInsets.only(top: 7, right: 8), decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            Text(p.description, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, height: 1.4)),
            if (p.example != null) ...[
              const SizedBox(height: 3),
              Text('e.g. ${p.example}', style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ])),
        ]),
      )),
    ]);
  }
}

class _ScoreBar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  const _ScoreBar(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13))),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score / 9.0,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(score.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
    ]),
  );
}
