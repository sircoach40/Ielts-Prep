import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';
import '../services/progress_service.dart';
import 'test_detail_screen.dart';
import 'live_lessons_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProgress? _progress;
  final _user = AppUser(id: 'u1', name: 'Alex Johnson', email: 'alex@example.com',
    targetBandScore: 7.0, examDate: DateTime.now().add(const Duration(days: 45)), totalPoints: 1250);

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    await ProgressService.seedDemoData();
    final p = await ProgressService.getProgress();
    if (mounted) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeBanner(),
                  const SizedBox(height: 24),
                  if (_progress != null) _buildProgressSummary(),
                  const SizedBox(height: 24),
                  _buildSkillCards(),
                  const SizedBox(height: 24),
                  _buildRecentTests(),
                  const SizedBox(height: 24),
                  _buildUpcomingLessons(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppTheme.primary,
      title: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 32, errorBuilder: (_, __, ___) =>
            const Icon(Icons.school, color: Colors.white, size: 28)),
          const SizedBox(width: 8),
          const Text('IELTS Online Tests', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () {}),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white24,
            child: Text(_user.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    final daysToExam = _user.examDate?.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              Text(_user.name.split(' ')[0] + '! 👋', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const Icon(Icons.stars, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${_user.totalPoints} pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _buildBannerStat('Target', 'Band ${_user.targetBandScore.toStringAsFixed(1)}', Icons.flag_outlined),
            const SizedBox(width: 16),
            if (daysToExam != null)
              _buildBannerStat('Exam in', '$daysToExam days', Icons.calendar_today_outlined),
            const SizedBox(width: 16),
            _buildBannerStat('Streak', '${_progress?.currentStreak ?? 0} days', Icons.local_fire_department_outlined),
          ]),
        ],
      ),
    );
  }

  Widget _buildBannerStat(String label, String value, IconData icon) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      ]),
    ));
  }

  Widget _buildProgressSummary() {
    final p = _progress!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Your Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          Text('${p.totalTestsTaken} tests taken', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _buildSkillProgress(TestSkill.listening, p.averageBands[TestSkill.listening] ?? 0),
          const SizedBox(width: 8),
          _buildSkillProgress(TestSkill.reading, p.averageBands[TestSkill.reading] ?? 0),
          const SizedBox(width: 8),
          _buildSkillProgress(TestSkill.writing, p.averageBands[TestSkill.writing] ?? 0),
          const SizedBox(width: 8),
          _buildSkillProgress(TestSkill.speaking, p.averageBands[TestSkill.speaking] ?? 0),
        ]),
      ],
    );
  }

  Widget _buildSkillProgress(TestSkill skill, double band) {
    final colors = {
      TestSkill.listening: AppTheme.listeningColor,
      TestSkill.reading: AppTheme.readingColor,
      TestSkill.writing: AppTheme.writingColor,
      TestSkill.speaking: AppTheme.speakingColor,
    };
    final labels = {TestSkill.listening: 'L', TestSkill.reading: 'R', TestSkill.writing: 'W', TestSkill.speaking: 'S'};
    final color = colors[skill]!;
    return Expanded(child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.1),
            child: Text(labels[skill]!, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Text(band > 0 ? band.toStringAsFixed(1) : '-',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          Text(skill.name.substring(0, 1).toUpperCase() + skill.name.substring(1),
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ]),
      ),
    ));
  }

  Widget _buildSkillCards() {
    final skills = [
      {'skill': TestSkill.listening, 'icon': Icons.headphones, 'color': AppTheme.listeningColor, 'desc': '4 Sections • 40 Qs'},
      {'skill': TestSkill.reading, 'icon': Icons.menu_book, 'color': AppTheme.readingColor, 'desc': '3 Passages • 40 Qs'},
      {'skill': TestSkill.writing, 'icon': Icons.edit_note, 'color': AppTheme.writingColor, 'desc': 'Task 1 + 2 • AI Feedback'},
      {'skill': TestSkill.speaking, 'icon': Icons.mic, 'color': AppTheme.speakingColor, 'desc': 'Parts 1-3 • AI Scoring'},
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Practice by Skill', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.4,
          children: skills.map((s) {
            final skill = s['skill'] as TestSkill;
            final color = s['color'] as Color;
            return InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ExamLibraryScreenFiltered(skill: skill))),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Icon(s['icon'] as IconData, color: Colors.white, size: 28),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(skill.name[0].toUpperCase() + skill.name.substring(1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(s['desc'] as String, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                  ]),
                ]),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecentTests() {
    final tests = MockDataService.getAllTests().take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Popular Tests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ...tests.map((t) => _buildTestTile(t)),
      ],
    );
  }

  Widget _buildTestTile(IELTSTest test) {
    final colors = {TestSkill.listening: AppTheme.listeningColor, TestSkill.reading: AppTheme.readingColor,
      TestSkill.writing: AppTheme.writingColor, TestSkill.speaking: AppTheme.speakingColor};
    final icons = {TestSkill.listening: Icons.headphones, TestSkill.reading: Icons.menu_book,
      TestSkill.writing: Icons.edit_note, TestSkill.speaking: Icons.mic};
    final color = colors[test.skill]!;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1),
          child: Icon(icons[test.skill], color: color)),
        title: Text(test.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Row(children: [
          const Icon(Icons.timer_outlined, size: 12, color: AppTheme.textSecondary),
          Text(' ${test.durationMinutes} min  •  ', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          Text(' ${test.rating}  •  ${(test.attempts / 1000).toStringAsFixed(1)}k attempts',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ]),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Text('FREE', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TestDetailScreen(test: test))),
      ),
    );
  }

  Widget _buildUpcomingLessons() {
    final lessons = MockDataService.getLiveLessons().where((l) => l.isUpcoming || l.isLive).take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Upcoming Live Lessons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          TextButton(onPressed: () {}, child: const Text('See all')),
        ]),
        const SizedBox(height: 8),
        ...lessons.map((l) => _buildLessonCard(l)),
      ],
    );
  }

  Widget _buildLessonCard(LiveLesson lesson) {
    final colors = {TestSkill.listening: AppTheme.listeningColor, TestSkill.reading: AppTheme.readingColor,
      TestSkill.writing: AppTheme.writingColor, TestSkill.speaking: AppTheme.speakingColor};
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(width: 4, height: 60, decoration: BoxDecoration(
            color: colors[lesson.skill], borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (lesson.isLive) Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                child: const Row(children: [
                  Icon(Icons.circle, color: Colors.white, size: 6),
                  SizedBox(width: 4),
                  Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
              if (!lesson.isLive) const SizedBox(),
              const SizedBox(width: 6),
              Text(lesson.isFree ? 'FREE' : 'PREMIUM',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                  color: lesson.isFree ? AppTheme.success : AppTheme.accent)),
            ]),
            const SizedBox(height: 4),
            Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('${lesson.instructor} • ${lesson.attendees}+ attending',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          Icon(Icons.chevron_right, color: AppTheme.textSecondary),
        ]),
      ),
    );
  }
}

// Wrapper to filter by skill
class ExamLibraryScreenFiltered extends StatelessWidget {
  final TestSkill skill;
  const ExamLibraryScreenFiltered({super.key, required this.skill});
  @override
  Widget build(BuildContext context) => ExamLibraryScreen(initialSkill: skill);
}
