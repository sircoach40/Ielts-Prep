import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';
import 'package:intl/intl.dart';

class LiveLessonsScreen extends StatefulWidget {
  const LiveLessonsScreen({super.key});
  @override
  State<LiveLessonsScreen> createState() => _LiveLessonsScreenState();
}

class _LiveLessonsScreenState extends State<LiveLessonsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _lessons = MockDataService.getLiveLessons();

  @override
  void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final live = _lessons.where((l) => l.isLive).toList();
    final upcoming = _lessons.where((l) => l.isUpcoming).toList();
    final recorded = _lessons.where((l) => !l.isLive && !l.isUpcoming).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Lessons'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Live${live.isNotEmpty ? " (${live.length})" : ""}'),
            const Tab(text: 'Upcoming'),
            const Tab(text: 'Recorded'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLessonList(live, isLive: true),
          _buildLessonList(upcoming),
          _buildLessonList(recorded, isRecorded: true),
        ],
      ),
    );
  }

  Widget _buildLessonList(List<LiveLesson> lessons, {bool isLive = false, bool isRecorded = false}) {
    if (lessons.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isLive ? Icons.live_tv_outlined : Icons.event_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(isLive ? 'No live lessons right now' : 'No lessons available',
          style: const TextStyle(color: AppTheme.textSecondary)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (_, i) => _buildLessonCard(lessons[i], isRecorded: isRecorded),
    );
  }

  Widget _buildLessonCard(LiveLesson lesson, {bool isRecorded = false}) {
    final colors = {TestSkill.listening: AppTheme.listeningColor, TestSkill.reading: AppTheme.readingColor,
      TestSkill.writing: AppTheme.writingColor, TestSkill.speaking: AppTheme.speakingColor};
    final icons = {TestSkill.listening: Icons.headphones, TestSkill.reading: Icons.menu_book,
      TestSkill.writing: Icons.edit_note, TestSkill.speaking: Icons.mic};
    final color = colors[lesson.skill]!;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            height: 140, width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(children: [
              Center(child: Icon(icons[lesson.skill], size: 56, color: Colors.white.withOpacity(0.4))),
              if (lesson.isLive) Positioned(top: 12, left: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                child: const Row(children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
              )),
              if (isRecorded) Positioned(top: 12, left: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                child: const Row(children: [
                  Icon(Icons.play_circle_outline, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('RECORDED', style: TextStyle(color: Colors.white, fontSize: 11)),
                ]),
              )),
              Positioned(top: 12, right: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: lesson.isFree ? AppTheme.success : AppTheme.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(lesson.isFree ? 'FREE' : 'PREMIUM',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
              )),
              if (isRecorded) Center(child: Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
              )),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(lesson.skill.name.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10)),
                ),
                const Spacer(),
                Row(children: [
                  const Icon(Icons.people_outline, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${lesson.attendees}+ attending', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ]),
              ]),
              const SizedBox(height: 8),
              Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 4),
              Text(lesson.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Row(children: [
                CircleAvatar(radius: 16, backgroundColor: color.withOpacity(0.2),
                  child: Text(lesson.instructor[0], style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lesson.instructor, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(lesson.instructorTitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Row(children: [
                    const Icon(Icons.access_time, size: 12, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text('${lesson.durationMinutes} min', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
                  if (!isRecorded) Text(
                    lesson.isLive ? 'Happening now!' : DateFormat('MMM d, h:mm a').format(lesson.scheduledAt),
                    style: TextStyle(fontSize: 11, color: lesson.isLive ? AppTheme.error : AppTheme.textSecondary, fontWeight: lesson.isLive ? FontWeight.bold : FontWeight.normal),
                  ),
                ]),
              ]),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: lesson.isFree ? () => _joinLesson(lesson) : () => _upgradeToPremium(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lesson.isLive ? Colors.red : color,
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(lesson.isLive ? Icons.live_tv : isRecorded ? Icons.play_arrow : Icons.notifications_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text(lesson.isLive ? 'Join Now' : isRecorded ? 'Watch Recording' : 'Register'),
                ]),
              )),
            ]),
          ),
        ],
      ),
    );
  }

  void _joinLesson(LiveLesson lesson) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(lesson.isLive ? 'Join Live Lesson' : 'Register for Lesson'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.video_call, size: 48, color: AppTheme.primary),
        const SizedBox(height: 12),
        Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(lesson.isLive ? 'This lesson is currently live. Click Join to enter.' : 'You will be registered and notified before the lesson starts.',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), textAlign: TextAlign.center),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lesson.isLive ? 'Join' : 'Register'),
        ),
      ],
    ));
  }

  void _upgradeToPremium() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Premium Content'),
      content: const Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lock_outline, size: 48, color: AppTheme.accent),
        SizedBox(height: 12),
        Text('This lesson requires a Premium subscription to access.', textAlign: TextAlign.center),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
          child: const Text('Upgrade to Premium'),
        ),
      ],
    ));
  }
}
