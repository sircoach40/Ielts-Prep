import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/test_provider.dart';

class TestDetailScreen extends StatelessWidget {
  final String testId;
  const TestDetailScreen({super.key, required this.testId});

  @override
  Widget build(BuildContext context) {
    final test = context.read<TestProvider>().getTestById(testId);
    if (test == null) return const Scaffold(body: Center(child: Text('Test not found')));

    final color = _skillColor(test.skill);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)])),
                child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 40),
                  Text(_skillEmoji(test.skill), style: const TextStyle(fontSize: 60)),
                  const SizedBox(height: 8),
                  Text(_skillName(test.skill), style: const TextStyle(color: Colors.white, fontSize: 16)),
                ])),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(delegate: SliverChildListDelegate([
              Text(test.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                _InfoChip(Icons.timer_outlined, '${test.durationMinutes} min'),
                const SizedBox(width: 8),
                _InfoChip(Icons.signal_cellular_alt, _difficultyLabel(test.difficulty)),
                const SizedBox(width: 8),
                _InfoChip(Icons.people_outline, '${_formatCount(test.attemptCount)} attempts'),
              ]),
              const SizedBox(height: 16),
              Text(test.description, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Text('Test Sections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...List.generate(test.sections.length, (i) => ListTile(
                leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Text('${i + 1}', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                title: Text(test.sections[i].title),
                subtitle: Text('${test.sections[i].questions.length} questions'),
              )),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: color),
                onPressed: () => _startTest(context, test),
                child: Text('Start Test – ${test.durationMinutes} min'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {},
                child: const Text('View Sample Answers'),
              ),
            ])),
          ),
        ],
      ),
    );
  }

  void _startTest(BuildContext context, IELTSTest test) {
    switch (test.skill) {
      case TestSkill.listening:
        context.go('/home/tests/listening/${test.id}');
      case TestSkill.reading:
        context.go('/home/tests/reading/${test.id}');
      case TestSkill.writing:
        context.go('/home/tests/writing/${test.id}');
      case TestSkill.speaking:
        context.go('/home/tests/speaking/${test.id}');
    }
  }

  Color _skillColor(TestSkill s) {
    switch (s) {
      case TestSkill.listening: return const Color(0xFF1A73E8);
      case TestSkill.reading: return const Color(0xFF34A853);
      case TestSkill.writing: return const Color(0xFFFF6B35);
      case TestSkill.speaking: return const Color(0xFF9C27B0);
    }
  }

  String _skillEmoji(TestSkill s) {
    switch (s) {
      case TestSkill.listening: return '🎧';
      case TestSkill.reading: return '📖';
      case TestSkill.writing: return '✍️';
      case TestSkill.speaking: return '🎤';
    }
  }

  String _skillName(TestSkill s) {
    switch (s) {
      case TestSkill.listening: return 'Listening Test';
      case TestSkill.reading: return 'Reading Test';
      case TestSkill.writing: return 'Writing Test';
      case TestSkill.speaking: return 'Speaking Test';
    }
  }

  String _difficultyLabel(Difficulty d) {
    switch (d) {
      case Difficulty.beginner: return 'Beginner';
      case Difficulty.intermediate: return 'Intermediate';
      case Difficulty.advanced: return 'Advanced';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: Colors.grey.shade600),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
    ]),
  );
}
