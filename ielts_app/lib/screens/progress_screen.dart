import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/progress_service.dart';
import 'package:intl/intl.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  UserProgress? _progress;
  List<TestResult> _results = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final p = await ProgressService.getProgress();
    final r = await ProgressService.getResults();
    if (mounted) setState(() { _progress = p; _results = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _buildOverviewCards(),
                const SizedBox(height: 24),
                _buildBandChart(),
                const SizedBox(height: 24),
                _buildSkillBreakdown(),
                const SizedBox(height: 24),
                _buildTestHistory(),
              ]),
            ),
          ),
    );
  }

  Widget _buildOverviewCards() {
    final p = _progress!;
    final hours = p.totalStudyMinutes ~/ 60;
    final mins = p.totalStudyMinutes % 60;
    final overall = p.averageBands.values.where((v) => v > 0).isEmpty ? 0.0 :
      p.averageBands.values.where((v) => v > 0).reduce((a, b) => a + b) /
      p.averageBands.values.where((v) => v > 0).length;

    return Row(children: [
      _buildOverviewCard('Overall Band', overall > 0 ? overall.toStringAsFixed(1) : '-',
        Icons.stars, AppTheme.primary, 'Average'),
      const SizedBox(width: 8),
      _buildOverviewCard('Tests Taken', '${p.totalTestsTaken}', Icons.quiz, AppTheme.secondary, 'Completed'),
      const SizedBox(width: 8),
      _buildOverviewCard('Study Time', '${hours}h ${mins}m', Icons.timer, AppTheme.success, 'Total'),
      const SizedBox(width: 8),
      _buildOverviewCard('Streak', '${p.currentStreak}🔥', Icons.local_fire_department, AppTheme.accent, 'Days'),
    ]);
  }

  Widget _buildOverviewCard(String label, String value, IconData icon, Color color, String sub) {
    return Expanded(child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    ));
  }

  Widget _buildBandChart() {
    if (_results.isEmpty) return const SizedBox();
    final chartData = _results.take(10).toList().reversed.toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Band Score History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Your last 10 test scores', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
                  getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)))),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 0, maxY: 9,
              lineBarsData: [
                LineChartBarData(
                  spots: chartData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.bandScore)).toList(),
                  isCurved: true, color: AppTheme.primary, barWidth: 3,
                  belowBarData: BarAreaData(show: true, color: AppTheme.primary.withOpacity(0.1)),
                  dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                    FlDotCirclePainter(radius: 4, color: AppTheme.primary, strokeColor: Colors.white, strokeWidth: 2)),
                ),
              ],
            )),
          ),
        ]),
      ),
    );
  }

  Widget _buildSkillBreakdown() {
    final p = _progress!;
    final skills = [
      {'skill': TestSkill.listening, 'color': AppTheme.listeningColor, 'icon': Icons.headphones, 'label': 'Listening'},
      {'skill': TestSkill.reading, 'color': AppTheme.readingColor, 'icon': Icons.menu_book, 'label': 'Reading'},
      {'skill': TestSkill.writing, 'color': AppTheme.writingColor, 'icon': Icons.edit_note, 'label': 'Writing'},
      {'skill': TestSkill.speaking, 'color': AppTheme.speakingColor, 'icon': Icons.mic, 'label': 'Speaking'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Skill Performance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          ...skills.map((s) {
            final skill = s['skill'] as TestSkill;
            final band = p.averageBands[skill] ?? 0;
            final color = s['color'] as Color;
            final history = p.bandHistory[skill] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(children: [
                CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.1),
                  child: Icon(s['icon'] as IconData, color: color, size: 18)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(s['label'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Row(children: [
                      Text(band > 0 ? 'Band ${band.toStringAsFixed(1)}' : 'Not tested',
                        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
                      if (history.length >= 2) ...[
                        const SizedBox(width: 4),
                        Icon(history.last > history[history.length - 2] ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 14, color: history.last > history[history.length - 2] ? AppTheme.success : AppTheme.error),
                      ],
                    ]),
                  ]),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: band / 9, backgroundColor: Colors.grey.shade100, color: color, minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text('${history.length} tests taken', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                ])),
              ]),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildTestHistory() {
    if (_results.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Recent Tests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 12),
      ..._results.take(10).map((r) {
        final colors = {TestSkill.listening: AppTheme.listeningColor, TestSkill.reading: AppTheme.readingColor,
          TestSkill.writing: AppTheme.writingColor, TestSkill.speaking: AppTheme.speakingColor};
        final icons = {TestSkill.listening: Icons.headphones, TestSkill.reading: Icons.menu_book,
          TestSkill.writing: Icons.edit_note, TestSkill.speaking: Icons.mic};
        final color = colors[r.skill]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icons[r.skill], color: color, size: 20)),
            title: Text(r.testTitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text(DateFormat('MMM d, yyyy').format(r.completedAt),
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Band ${r.bandScore.toStringAsFixed(1)}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14)),
              Text('${r.accuracy.toStringAsFixed(0)}% accuracy',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ]),
          ),
        );
      }),
    ]);
  }
}
