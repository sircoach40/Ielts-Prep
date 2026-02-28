import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/mock_data_service.dart';
import 'package:intl/intl.dart';

class LessonDetailScreen extends StatelessWidget {
  final String lessonId;
  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final lessons = MockDataService.getLiveLessons();
    LiveLesson? lesson;
    try { lesson = lessons.firstWhere((l) => l.id == lessonId); } catch (_) {}

    if (lesson == null) return const Scaffold(body: Center(child: Text('Lesson not found')));

    final isLive = lesson.status == LessonStatus.live;
    final color = _skillColor(lesson.skill);

    return Scaffold(
      appBar: AppBar(
        title: Text(isLive ? '🔴 Live Now' : 'Lesson Details'),
        backgroundColor: isLive ? Colors.red : color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Video/Stream placeholder
          Container(
            width: double.infinity, height: 220,
            color: Colors.black,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (isLive) ...[
                const Icon(Icons.live_tv, color: Colors.white, size: 64),
                const SizedBox(height: 12),
                const Text('Live Stream', style: TextStyle(color: Colors.white, fontSize: 18)),
                const Text('Connect your stream URL in production', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ] else if (lesson.recordingUrl != null) ...[
                const Icon(Icons.play_circle_filled, color: Colors.white, size: 72),
                const SizedBox(height: 12),
                const Text('Recorded Lesson', style: TextStyle(color: Colors.white, fontSize: 18)),
              ] else ...[
                const Icon(Icons.event, color: Colors.white54, size: 64),
                const SizedBox(height: 12),
                Text(DateFormat('EEEE, MMM d • h:mm a').format(lesson.scheduledAt),
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Skill + Status badges
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(_skillLabel(lesson.skill), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                if (lesson.isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Text('FREE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
              ]),
              const SizedBox(height: 12),
              Text(lesson.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.3)),
              const SizedBox(height: 16),

              // Instructor
              Row(children: [
                CircleAvatar(
                  radius: 22, backgroundColor: color.withOpacity(0.15),
                  child: Text(lesson.instructorName[0], style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(lesson.instructorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const Text('IELTS Expert Instructor', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
                const Spacer(),
                Icon(Icons.people, color: Colors.grey.shade400, size: 18),
                const SizedBox(width: 4),
                Text('${lesson.attendeeCount}+ students', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ]),
              const Divider(height: 32),

              const Text('About this lesson', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(lesson.description, style: const TextStyle(height: 1.6, fontSize: 15)),
              const SizedBox(height: 24),

              // Info row
              Row(children: [
                _InfoItem(Icons.timer_outlined, '${lesson.durationMinutes} min'),
                const SizedBox(width: 24),
                _InfoItem(Icons.language, lesson.language),
                const SizedBox(width: 24),
                if (isLive) _InfoItem(Icons.visibility, '${lesson.attendeeCount}+ watching')
                else _InfoItem(Icons.calendar_today, DateFormat('MMM d').format(lesson.scheduledAt)),
              ]),
              const SizedBox(height: 32),

              // CTA
              if (isLive)
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.live_tv),
                  label: const Text('Join Live Stream'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                )
              else if (lesson.status == LessonStatus.recorded)
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch Recording'),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Register & Get Reminded'),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                ),
            ]),
          ),
        ]),
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

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 16, color: Colors.grey),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
  ]);
}
