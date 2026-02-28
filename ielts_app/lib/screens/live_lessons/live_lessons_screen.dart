import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../services/mock_data_service.dart';
import 'package:intl/intl.dart';

class LiveLessonsScreen extends StatefulWidget {
  const LiveLessonsScreen({super.key});
  @override
  State<LiveLessonsScreen> createState() => _LiveLessonsScreenState();
}

class _LiveLessonsScreenState extends State<LiveLessonsScreen> {
  String _filter = 'all'; // all, upcoming, live, recorded
  TestSkill? _skillFilter;

  @override
  Widget build(BuildContext context) {
    final lessons = MockDataService.getLiveLessons();
    final filtered = lessons.where((l) {
      if (_filter == 'upcoming' && l.status != LessonStatus.upcoming) return false;
      if (_filter == 'live' && l.status != LessonStatus.live) return false;
      if (_filter == 'recorded' && l.status != LessonStatus.recorded) return false;
      if (_skillFilter != null && l.skill != _skillFilter) return false;
      return true;
    }).toList();

    final liveNow = lessons.where((l) => l.status == LessonStatus.live).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Live Lessons')),
      body: CustomScrollView(
        slivers: [
          if (liveNow.isNotEmpty)
            SliverToBoxAdapter(child: _LiveNowBanner(lesson: liveNow.first)),
          SliverToBoxAdapter(child: _FilterRow(
            currentFilter: _filter,
            skillFilter: _skillFilter,
            onFilterChanged: (f) => setState(() => _filter = f),
            onSkillChanged: (s) => setState(() => _skillFilter = s),
          )),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _LessonCard(lesson: filtered[i]),
                childCount: filtered.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _LiveNowBanner extends StatelessWidget {
  final LiveLesson lesson;
  const _LiveNowBanner({required this.lesson});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.go('/home/live-lessons/${lesson.id}'),
    child: Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.red, Color(0xFFFF5252)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(6)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.circle, color: Colors.white, size: 8),
            SizedBox(width: 4),
            Text('LIVE NOW', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lesson.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('with ${lesson.instructorName} · ${lesson.attendeeCount}+ watching', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
        ])),
        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
      ]),
    ),
  );
}

class _FilterRow extends StatelessWidget {
  final String currentFilter;
  final TestSkill? skillFilter;
  final Function(String) onFilterChanged;
  final Function(TestSkill?) onSkillChanged;
  const _FilterRow({required this.currentFilter, required this.skillFilter, required this.onFilterChanged, required this.onSkillChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, children: [
          FilterChip(label: const Text('All'), selected: currentFilter == 'all', onSelected: (_) => onFilterChanged('all')),
          FilterChip(label: const Text('🔴 Live'), selected: currentFilter == 'live', onSelected: (_) => onFilterChanged('live')),
          FilterChip(label: const Text('📅 Upcoming'), selected: currentFilter == 'upcoming', onSelected: (_) => onFilterChanged('upcoming')),
          FilterChip(label: const Text('🎬 Recorded'), selected: currentFilter == 'recorded', onSelected: (_) => onFilterChanged('recorded')),
        ]),
      ]),
    );
  }
}

class _LessonCard extends StatelessWidget {
  final LiveLesson lesson;
  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final isLive = lesson.status == LessonStatus.live;
    final isUpcoming = lesson.status == LessonStatus.upcoming;
    final skillColor = _skillColor(lesson.skill);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.go('/home/live-lessons/${lesson.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLive ? Colors.red : isUpcoming ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLive ? '🔴 LIVE' : isUpcoming ? 'UPCOMING' : '🎬 RECORDED',
                  style: TextStyle(
                    color: isLive ? Colors.white : isUpcoming ? Colors.blue.shade700 : Colors.grey.shade700,
                    fontSize: 10, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: skillColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(_skillLabel(lesson.skill), style: TextStyle(color: skillColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              if (lesson.isFree)
                Text('FREE', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
            ]),
            const SizedBox(height: 10),
            Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 2),
            const SizedBox(height: 8),
            Text(lesson.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(children: [
              CircleAvatar(radius: 12, backgroundColor: skillColor.withOpacity(0.2), child: Text(lesson.instructorName[0], style: TextStyle(color: skillColor, fontSize: 12, fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lesson.instructorName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                if (isUpcoming)
                  Text(DateFormat('MMM d, h:mm a').format(lesson.scheduledAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ])),
              Icon(Icons.people_outline, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text('${lesson.attendeeCount}+', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ]),
          ]),
        ),
      ),
    );
  }

  Color _skillColor(TestSkill s) {
    switch (s) {
      case TestSkill.listening: return const Color(0xFF1A73E8);
      case TestSkill.reading: return const Color(0xFF34A853);
      case TestSkill.writing: return const Color(0xFFFF6B35);
      case TestSkill.speaking: return const Color(0xFF9C27B0);
    }
  }

  String _skillLabel(TestSkill s) {
    switch (s) {
      case TestSkill.listening: return '🎧 Listening';
      case TestSkill.reading: return '📖 Reading';
      case TestSkill.writing: return '✍️ Writing';
      case TestSkill.speaking: return '🎤 Speaking';
    }
  }
}
