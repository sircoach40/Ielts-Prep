import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome Back'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/onboarding')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: const Color(0xFF1A73E8).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: const Center(child: Text('IELTS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A73E8), fontSize: 18))),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Email', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), hintText: 'your@email.com'),
                validator: (v) => v!.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 16),
              const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v!.length < 6 ? 'Password too short' : null,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: auth.isLoading ? null : _login,
                child: auth.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Log In'),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text("Don't have an account? "),
                TextButton(onPressed: () => context.go('/register'), child: const Text('Sign Up')),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: TextStyle(color: Colors.grey.shade500))),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _loginDemo(),
                icon: const Text('🎭'),
                label: const Text('Continue as Demo User'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthProvider>().login(_emailCtrl.text, _passCtrl.text);
    if (success && mounted) context.go('/home');
  }

  Future<void> _loginDemo() async {
    await context.read<AuthProvider>().login('demo@ieltsprep.com', 'demo123');
    if (mounted) context.go('/home');
  }

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }
}
