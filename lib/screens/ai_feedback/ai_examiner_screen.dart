import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/ai_examiner_service.dart';

class AIExaminerScreen extends StatefulWidget {
  const AIExaminerScreen({super.key});
  @override
  State<AIExaminerScreen> createState() => _AIExaminerScreenState();
}

class _AIExaminerScreenState extends State<AIExaminerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _promptCtrl = TextEditingController();
  final _responseCtrl = TextEditingController();
  bool _isEvaluating = false;
  AIFeedback? _feedback;
  String _selectedTask = 'task2';

  final List<Map<String, String>> _samplePrompts = [
    {'title': 'Technology & Society (Task 2)', 'type': 'task2', 'text': 'Some people believe that technology is making us less sociable and more isolated. Others argue that technology helps us connect with people and is beneficial for society. Discuss both views and give your own opinion.'},
    {'title': 'Graph Description (Task 1)', 'type': 'task1', 'text': 'The bar chart shows the percentage of people who used different forms of transport to travel to work in four cities in 2005 and 2015. Summarise the information by selecting and reporting the main features.'},
    {'title': 'Education (Task 2)', 'type': 'task2', 'text': 'Some people think that university education should be free for all students, while others believe that students should pay for their own education. Discuss both views and give your own opinion.'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Examiner'),
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: '✍️ Writing'),
          Tab(text: '🎤 Speaking'),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        _buildWritingTab(),
        _buildSpeakingTab(),
      ]),
    );
  }

  Widget _buildWritingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6200EE), Color(0xFF9C27B0)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(children: [
            Text('🤖', style: TextStyle(fontSize: 32)),
            SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI Writing Examiner', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Instant band score + detailed feedback', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ])),
          ]),
        ),
        const SizedBox(height: 16),

        // Task type selector
        Row(children: [
          const Text('Task Type: ', style: TextStyle(fontWeight: FontWeight.w600)),
          ChoiceChip(label: const Text('Task 1'), selected: _selectedTask == 'task1', onSelected: (_) => setState(() => _selectedTask = 'task1')),
          const SizedBox(width: 8),
          ChoiceChip(label: const Text('Task 2'), selected: _selectedTask == 'task2', onSelected: (_) => setState(() => _selectedTask = 'task2')),
        ]),
        const SizedBox(height: 16),

        // Sample prompts
        const Text('Sample Prompts', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _samplePrompts.where((p) => p['type'] == _selectedTask).map((p) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(p['title']!, style: const TextStyle(fontSize: 12)),
              onPressed: () => setState(() { _promptCtrl.text = p['text']!; }),
            ),
          )).toList()),
        ),
        const SizedBox(height: 16),

        const Text('Task Prompt', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _promptCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Paste or type the task prompt here...', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),

        Text('Your Response (min ${_selectedTask == 'task1' ? '150' : '250'} words)', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: _responseCtrl,
          maxLines: 10,
          decoration: const InputDecoration(hintText: 'Write your essay response here...', border: OutlineInputBorder(), alignLabelWithHint: true),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        Text('${_wordCount(_responseCtrl.text)} words', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 16),

        ElevatedButton.icon(
          onPressed: _isEvaluating ? null : _evaluateWriting,
          icon: _isEvaluating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.psychology),
          label: Text(_isEvaluating ? 'Evaluating...' : 'Get AI Feedback & Band Score'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6200EE)),
        ),

        if (_feedback != null) ...[
          const SizedBox(height: 24),
          _FeedbackDisplay(feedback: _feedback!),
        ],
      ]),
    );
  }

  Widget _buildSpeakingTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('🎤', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('Speaking AI Evaluation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          SizedBox(height: 8),
          Text('Go to Tests > Speaking to take a full speaking test with AI evaluation.', style: TextStyle(color: Colors.grey, height: 1.5), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  int _wordCount(String text) => text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  Future<void> _evaluateWriting() async {
    if (_responseCtrl.text.trim().isEmpty) return;
    setState(() { _isEvaluating = true; _feedback = null; });

    try {
      final feedback = await AIExaminerService.evaluateWriting(
        prompt: _promptCtrl.text,
        response: _responseCtrl.text,
        taskType: _selectedTask,
      );
      setState(() => _feedback = feedback);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evaluation failed. Please try again.')));
    } finally {
      setState(() => _isEvaluating = false);
    }
  }

  @override
  void dispose() { _tabController.dispose(); _promptCtrl.dispose(); _responseCtrl.dispose(); super.dispose(); }
}

class _FeedbackDisplay extends StatelessWidget {
  final AIFeedback feedback;
  const _FeedbackDisplay({required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Overall score
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF6200EE), Color(0xFF9C27B0)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          const Text('Overall Band Score', style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text(feedback.overallScore.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.bold, height: 1)),
          Text(feedback.overallFeedback, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5), textAlign: TextAlign.center),
        ]),
      ),
      const SizedBox(height: 16),

      // Score breakdown
      Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Score Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _Bar('Grammar', feedback.grammarScore, Colors.blue),
          _Bar('Vocabulary', feedback.vocabularyScore, Colors.green),
          _Bar('Coherence', feedback.coherenceScore, Colors.orange),
        ]),
      )),
      const SizedBox(height: 12),

      // Strengths
      if (feedback.strengths.isNotEmpty) ...[
        const Text('💪 Strengths', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...feedback.strengths.map((p) => Card(
          child: ListTile(
            leading: const Text('✅', style: TextStyle(fontSize: 20)),
            title: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(p.description),
          ),
        )),
        const SizedBox(height: 12),
      ],

      // Improvements
      if (feedback.improvements.isNotEmpty) ...[
        const Text('📈 Areas to Improve', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...feedback.improvements.map((p) => Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('🔶', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 4),
              Text(p.description, style: const TextStyle(height: 1.4)),
              if (p.example != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                  child: Text(p.example!, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                ),
              ],
            ]),
          ),
        )),
      ],
    ]);
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double score;
  final Color color;
  const _Bar(this.label, this.score, this.color);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13))),
      Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
        value: score / 9.0, backgroundColor: color.withOpacity(0.15),
        valueColor: AlwaysStoppedAnimation(color), minHeight: 8,
      ))),
      const SizedBox(width: 8),
      Text(score.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
    ]),
  );
}
