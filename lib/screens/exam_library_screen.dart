import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/mock_data_service.dart';
import 'test_detail_screen.dart';

class ExamLibraryScreen extends StatefulWidget {
  final TestSkill? initialSkill;
  const ExamLibraryScreen({super.key, this.initialSkill});
  @override
  State<ExamLibraryScreen> createState() => _ExamLibraryScreenState();
}

class _ExamLibraryScreenState extends State<ExamLibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _skills = [null, TestSkill.listening, TestSkill.reading, TestSkill.writing, TestSkill.speaking];
  final _labels = ['All', 'Listening', 'Reading', 'Writing', 'Speaking'];
  TestType _filterType = TestType.academic;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.initialSkill != null ? _skills.indexOf(widget.initialSkill) : 0;
    _tabController = TabController(length: 5, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  List<IELTSTest> _getTests(TestSkill? skill) {
    var tests = skill == null ? MockDataService.getAllTests() :
      MockDataService.getAllTests().where((t) => t.skill == skill).toList();
    if (_searchQuery.isNotEmpty) {
      tests = tests.where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    return tests;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IELTS Exam Library'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _skills.map((skill) => _buildTestList(skill)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          hintText: 'Search tests...',
          prefixIcon: Icon(Icons.search),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildTestList(TestSkill? skill) {
    final tests = _getTests(skill);
    if (tests.isEmpty) {
      return const Center(child: Text('No tests found', style: TextStyle(color: AppTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tests.length,
      itemBuilder: (_, i) => _buildTestCard(tests[i]),
    );
  }

  Widget _buildTestCard(IELTSTest test) {
    final colors = {TestSkill.listening: AppTheme.listeningColor, TestSkill.reading: AppTheme.readingColor,
      TestSkill.writing: AppTheme.writingColor, TestSkill.speaking: AppTheme.speakingColor};
    final icons = {TestSkill.listening: Icons.headphones, TestSkill.reading: Icons.menu_book,
      TestSkill.writing: Icons.edit_note, TestSkill.speaking: Icons.mic};
    final color = colors[test.skill]!;
    final totalQuestions = test.sections.fold<int>(0, (sum, s) => sum + s.questions.length);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TestDetailScreen(test: test))),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(icons[test.skill], color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(test.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(test.type == TestType.academic ? 'Academic' : 'General Training',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('FREE', style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 12),
            Text(test.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            Row(children: [
              _buildChip(Icons.timer_outlined, '${test.durationMinutes} min'),
              const SizedBox(width: 8),
              _buildChip(Icons.quiz_outlined, '$totalQuestions questions'),
              const SizedBox(width: 8),
              _buildChip(Icons.star, '${test.rating}'),
              const Spacer(),
              Text('${(test.attempts / 1000).toStringAsFixed(1)}k attempts',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TestDetailScreen(test: test))),
              child: const Text('Start Test'),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ]),
    );
  }
}
