import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final progress = context.watch<ProgressProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        child: Column(children: [
          // Profile header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF1A73E8), Color(0xFF0D47A1)]),
            ),
            child: Column(children: [
              CircleAvatar(
                radius: 40, backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Text(user?.name ?? 'Student', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _Stat('${progress.totalTestsTaken}', 'Tests'),
                Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
                _Stat(progress.overallBandScore.toStringAsFixed(1), 'Band Score'),
                Container(width: 1, height: 30, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
                _Stat('${(progress.totalStudyMinutes / 60).toStringAsFixed(0)}h', 'Study Time'),
              ]),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Target score
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Target Band Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Text(user?.targetBandScore.toStringAsFixed(1) ?? '7.0',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _editTargetScore(context, user?.targetBandScore ?? 7.0),
                      child: const Text('Change'),
                    ),
                  ]),
                  LinearProgressIndicator(
                    value: (progress.overallBandScore / (user?.targetBandScore ?? 7.0)).clamp(0, 1),
                    backgroundColor: const Color(0xFF1A73E8).withOpacity(0.15),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF1A73E8)),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  Text('${(progress.overallBandScore / (user?.targetBandScore ?? 7.0) * 100).toStringAsFixed(0)}% to your goal',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ]),
              )),
              const SizedBox(height: 12),

              // Settings list
              Card(child: Column(children: [
                _SettingsTile(Icons.notifications_outlined, 'Notifications', onTap: () {}),
                const Divider(height: 1),
                _SettingsTile(Icons.bookmark_border, 'Saved Tests', onTap: () {}),
                const Divider(height: 1),
                _SettingsTile(Icons.help_outline, 'Help & Support', onTap: () {}),
                const Divider(height: 1),
                _SettingsTile(Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () {}),
              ])),
              const SizedBox(height: 12),

              Card(child: Column(children: [
                _SettingsTile(Icons.logout, 'Log Out', color: Colors.red, onTap: () => _logout(context)),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _editTargetScore(BuildContext context, double current) async {
    double selected = current;
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Set Target Band Score'),
      content: StatefulBuilder(builder: (_, setState) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(selected.toStringAsFixed(1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8))),
        Slider(value: selected, min: 4.0, max: 9.0, divisions: 10, onChanged: (v) => setState(() => selected = v)),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () { context.read<AuthProvider>().updateTargetScore(selected); Navigator.pop(context); }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Log Out')),
      ],
    ));
    if (confirm == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      context.go('/login');
    }
  }
}

class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat(this.value, this.label);

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
  ]);
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;
  const _SettingsTile(this.icon, this.title, {this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color),
    title: Text(title, style: TextStyle(color: color)),
    trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    onTap: onTap,
  );
}
