import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/progress_provider.dart';
import '../../providers/test_provider.dart';
import '../../models/models.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Progress'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Band Scores'),
          Tab(text: 'History'),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        _OverviewTab(),
        _BandScoreTab(),
        _HistoryTab(),
      ]),
    );
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }
}

class _OverviewTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Overall band score
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            const Text('Overall Band Score', style: TextStyle(color: Colors.white70, fontSize: 14)),
            Text(progress.overallBandScore.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold, height: 1)),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _StatPill('${progress.totalTestsTaken} tests', Icons.assignment),
              const SizedBox(width: 16),
              _StatPill('${(progress.totalStudyMinutes / 60).toStringAsFixed(0)}h study', Icons.timer),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // Per-skill breakdown
        const Align(alignment: Alignment.centerLeft, child: Text('Skills Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
          children: progress.skillProgress.map((sp) => _SkillScoreCard(sp)).toList(),
        ),
        const SizedBox(height: 20),

        // Weekly activity
        const Align(alignment: Alignment.centerLeft, child: Text('Weekly Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: _WeeklyChart(progress.weeklyProgress),
        ),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  const _StatPill(this.label, this.icon);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white, size: 14),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ]),
  );
}

class _SkillScoreCard extends StatelessWidget {
  final SkillProgress sp;
  const _SkillScoreCard(this.sp);

  @override
  Widget build(BuildContext context) {
    final color = _skillColor(sp.skill);
    final pct = sp.currentBandScore / sp.targetBandScore;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(_skillEmoji(sp.skill), style: const TextStyle(fontSize: 20)),
          const Spacer(),
          Text(sp.currentBandScore.toStringAsFixed(1), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 4),
        Text(_skillName(sp.skill), style: const TextStyle(fontWeight: FontWeight.w600)),
        Text('Target: ${sp.targetBandScore.toStringAsFixed(1)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(
          value: pct.clamp(0, 1), backgroundColor: color.withOpacity(0.15),
          valueColor: AlwaysStoppedAnimation(color), minHeight: 5,
        )),
      ]),
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
      case TestSkill.listening: return 'Listening';
      case TestSkill.reading: return 'Reading';
      case TestSkill.writing: return 'Writing';
      case TestSkill.speaking: return 'Speaking';
    }
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<WeeklyProgress> data;
  const _WeeklyChart(this.data);

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data yet'));
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.averageBandScore)).toList();

    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 1),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, reservedSize: 30)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      minY: 3, maxY: 9,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(0xFF1A73E8),
          barWidth: 3,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: const Color(0xFF1A73E8).withOpacity(0.1)),
        ),
      ],
    ));
  }
}

class _BandScoreTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: progress.skillProgress.map((sp) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(_skillEmoji(sp.skill), style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(_skillName(sp.skill), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${sp.currentBandScore.toStringAsFixed(1)} / ${sp.targetBandScore.toStringAsFixed(1)}',
                style: TextStyle(color: _skillColor(sp.skill), fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: _MiniChart(history: sp.bandScoreHistory, color: _skillColor(sp.skill)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Focus: ${sp.weakestArea}', style: const TextStyle(fontSize: 12))),
              ]),
            ),
          ]),
        ),
      )).toList(),
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
      case TestSkill.listening: return 'Listening';
      case TestSkill.reading: return 'Reading';
      case TestSkill.writing: return 'Writing';
      case TestSkill.speaking: return 'Speaking';
    }
  }
}

class _MiniChart extends StatelessWidget {
  final List<double> history;
  final Color color;
  const _MiniChart({required this.history, required this.color});

  @override
  Widget build(BuildContext context) {
    final spots = history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      minY: 3, maxY: 9,
      lineBarsData: [
        LineChartBarData(
          spots: spots, isCurved: true, color: color, barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: color.withOpacity(0.1)),
        ),
      ],
    ));
  }
}

class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final results = context.watch<TestProvider>().results;
    if (results.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('📝', style: TextStyle(fontSize: 48)),
        SizedBox(height: 12),
        Text('No tests taken yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        SizedBox(height: 6),
        Text('Complete a test to see your history here', style: TextStyle(color: Colors.grey)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (_, i) {
        final r = results[i];
        final color = _skillColor(r.skill);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(_skillEmoji(r.skill), style: const TextStyle(fontSize: 20))),
            ),
            title: Text(_skillName(r.skill), style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${r.completedAt.day}/${r.completedAt.month}/${r.completedAt.year}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(r.bandScore.toStringAsFixed(1), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        );
      },
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
      case TestSkill.listening: return 'Listening';
      case TestSkill.reading: return 'Reading';
      case TestSkill.writing: return 'Writing';
      case TestSkill.speaking: return 'Speaking';
    }
  }
}
