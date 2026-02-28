import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/test_provider.dart';

class TestLibraryScreen extends StatelessWidget {
  const TestLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Library')),
      body: Column(children: [
        _SkillFilterBar(),
        Expanded(child: _TestListBody()),
      ]),
    );
  }
}

class _SkillFilterBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestProvider>();
    final filters = [null, TestSkill.listening, TestSkill.reading, TestSkill.writing, TestSkill.speaking];
    final labels = ['All', '🎧 Listening', '📖 Reading', '✍️ Writing', '🎤 Speaking'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(filters.length, (i) {
          final selected = provider.selectedSkillFilter == filters[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(label: Text(labels[i]), selected: selected, onSelected: (_) => provider.setSkillFilter(filters[i])),
          );
        }),
      ),
    );
  }
}

class _TestListBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TestProvider>();
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    final tests = provider.filteredTests;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tests.length,
      itemBuilder: (_, i) => _TestCard(test: tests[i]),
    );
  }
}

class _TestCard extends StatelessWidget {
  final IELTSTest test;
  const _TestCard({required this.test});

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

  @override
  Widget build(BuildContext context) {
    final color = _skillColor(test.skill);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/home/tests/${test.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(_skillEmoji(test.skill), style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(test.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (test.isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text('FREE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 4),
              Text('${test.durationMinutes} min · ${_difficultyLabel(test.difficulty)} · ${_formatCount(test.attemptCount)} attempts',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                const SizedBox(width: 2),
                Text(test.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ])),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}
