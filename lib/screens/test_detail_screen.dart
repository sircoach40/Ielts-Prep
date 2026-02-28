import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import 'test_taking_screen.dart';

class TestDetailScreen extends StatelessWidget {
  final IELTSTest test;
  const TestDetailScreen({super.key, required this.test});

  static const _skillColors = {
    TestSkill.listening: AppTheme.listeningColor,
    TestSkill.reading: AppTheme.readingColor,
    TestSkill.writing: AppTheme.writingColor,
    TestSkill.speaking: AppTheme.speakingColor,
  };

  static const _skillIcons = {
    TestSkill.listening: Icons.headphones,
    TestSkill.reading: Icons.menu_book,
    TestSkill.writing: Icons.edit_note,
    TestSkill.speaking: Icons.mic,
  };

  @override
  Widget build(BuildContext context) {
    final color = _skillColors[test.skill]!;
    final totalQ = test.sections.fold<int>(0, (s, e) => s + e.questions.length);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 60),
                  Icon(_skillIcons[test.skill], color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  Text(test.skill.name[0].toUpperCase() + test.skill.name.substring(1),
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ]),
              ),
              title: Text(test.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _buildStat('Duration', '${test.durationMinutes} min', Icons.timer_outlined),
                  _buildStat('Questions', '$totalQ', Icons.quiz_outlined),
                  _buildStat('Sections', '${test.sections.length}', Icons.layers_outlined),
                  _buildStat('Rating', '${test.rating}', Icons.star_outline),
                ]),
                const SizedBox(height: 24),
                const Text('About This Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(test.description, style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                const SizedBox(height: 24),
                const Text('Test Sections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...test.sections.asMap().entries.map((entry) {
                  final i = entry.key;
                  final section = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.1),
                        child: Text('${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(section.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text('${section.questions.length} questions',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ])),
                      if (test.skill == TestSkill.listening || test.skill == TestSkill.reading)
                        Icon(section.audioUrl != null ? Icons.headphones : Icons.article_outlined,
                          color: AppTheme.textSecondary, size: 18),
                    ]),
                  );
                }),
                const SizedBox(height: 24),
                if (test.skill == TestSkill.writing || test.skill == TestSkill.speaking)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppTheme.accent.withOpacity(0.1), AppTheme.accent.withOpacity(0.05)]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('AI Examiner Feedback Available', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accent)),
                        const Text('Get detailed band score and feedback powered by AI after completing this test.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ])),
                    ]),
                  ),
                const SizedBox(height: 32),
                SizedBox(width: double.infinity, child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => TestTakingScreen(test: test))),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Test Now', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: color,
                  ),
                )),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: AppTheme.primary, size: 22),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    ]);
  }
}
