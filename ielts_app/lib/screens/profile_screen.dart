import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../services/progress_service.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _user = AppUser(
    id: 'u1', name: 'Alex Johnson', email: 'alex@example.com',
    targetBandScore: 7.0, examDate: DateTime.now().add(const Duration(days: 45)), totalPoints: 1250,
  );
  UserProgress? _progress;

  @override
  void initState() { super.initState(); _loadProgress(); }

  Future<void> _loadProgress() async {
    final p = await ProgressService.getProgress();
    if (mounted) setState(() => _progress = p);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildProfileHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _buildExamCountdown(),
                const SizedBox(height: 16),
                _buildStatsCard(),
                const SizedBox(height: 16),
                _buildSettingsSection(),
                const SizedBox(height: 16),
                _buildAboutSection(),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 40),
            Stack(children: [
              CircleAvatar(radius: 44, backgroundColor: Colors.white24,
                child: Text(_user.name[0], style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold))),
              Positioned(bottom: 0, right: 0, child: CircleAvatar(
                radius: 14, backgroundColor: AppTheme.success,
                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
              )),
            ]),
            const SizedBox(height: 12),
            Text(_user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 4),
            Text(_user.email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.stars, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${_user.totalPoints} points', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildExamCountdown() {
    if (_user.examDate == null) return const SizedBox();
    final daysLeft = _user.examDate!.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.accent.withOpacity(0.9), AppTheme.accent],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('IELTS Exam Countdown', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$daysLeft', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 40)),
            const Padding(padding: EdgeInsets.only(bottom: 6, left: 4),
              child: Text('days', style: TextStyle(color: Colors.white70, fontSize: 16))),
          ]),
          Text('Exam: ${DateFormat('MMMM d, yyyy').format(_user.examDate!)}',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
        ]),
        const Spacer(),
        const Icon(Icons.event_available, color: Colors.white, size: 56),
      ]),
    );
  }

  Widget _buildStatsCard() {
    final p = _progress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Stats', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(children: [
            _buildStat('Tests Taken', '${p?.totalTestsTaken ?? 0}', Icons.quiz_outlined, AppTheme.primary),
            _buildStat('Study Hours', '${(p?.totalStudyMinutes ?? 0) ~/ 60}h', Icons.timer_outlined, AppTheme.secondary),
            _buildStat('Day Streak', '${p?.currentStreak ?? 0}🔥', Icons.local_fire_department, AppTheme.accent),
          ]),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Target Band Score', style: TextStyle(fontWeight: FontWeight.w500)),
            Row(children: [
              Text('${_user.targetBandScore.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showEditTargetDialog(),
                child: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.textSecondary),
              ),
            ]),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Expanded(child: Column(children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 6),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11), textAlign: TextAlign.center),
    ]));
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Column(children: [
        _buildSettingTile('Notifications', Icons.notifications_outlined, AppTheme.primary, () {}),
        const Divider(height: 1, indent: 56),
        _buildSettingTile('Study Reminders', Icons.alarm_outlined, AppTheme.secondary, () {}),
        const Divider(height: 1, indent: 56),
        _buildSettingTile('API Key (for AI)', Icons.key_outlined, AppTheme.accent, () => _showAPIKeyDialog()),
        const Divider(height: 1, indent: 56),
        _buildSettingTile('Language', Icons.language_outlined, AppTheme.success, () {}),
        const Divider(height: 1, indent: 56),
        _buildSettingTile('Dark Mode', Icons.dark_mode_outlined, AppTheme.textSecondary, () {}),
      ]),
    );
  }

  Widget _buildSettingTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 18)),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(children: [
        _buildSettingTile('About IELTS Online Tests', Icons.info_outlined, AppTheme.primary, () {}),
        const Divider(height: 1, indent: 56),
        _buildSettingTile('Privacy Policy', Icons.privacy_tip_outlined, AppTheme.textSecondary, () {}),
        const Divider(height: 1, indent: 56),
        _buildSettingTile('Sign Out', Icons.logout, AppTheme.error, () {}),
      ]),
    );
  }

  void _showEditTargetDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Set Target Band Score'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [5.0, 5.5, 6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0].map((band) =>
        ListTile(
          title: Text('Band ${band.toStringAsFixed(1)}'),
          trailing: _user.targetBandScore == band ? const Icon(Icons.check, color: AppTheme.primary) : null,
          onTap: () => Navigator.pop(context),
        ),
      ).toList()),
    ));
  }

  void _showAPIKeyDialog() {
    final controller = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Anthropic API Key'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Enter your Anthropic API key to enable AI examiner feedback for Writing and Speaking tests.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        const SizedBox(height: 16),
        TextField(controller: controller, obscureText: true,
          decoration: const InputDecoration(labelText: 'API Key', hintText: 'sk-ant-...')),
        const SizedBox(height: 8),
        const Text('Get your key at console.anthropic.com',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Save')),
      ],
    ));
  }
}
