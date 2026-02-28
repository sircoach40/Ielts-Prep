import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      emoji: '📝',
      title: 'Free Mock Tests',
      subtitle: 'Practice with 100+ real IELTS-style tests covering all 4 skills. Get instant band scores.',
      color: const Color(0xFF1A73E8),
    ),
    _OnboardingData(
      emoji: '🤖',
      title: 'AI Examiner Feedback',
      subtitle: 'Submit your writing and speaking responses for detailed AI-powered evaluation and scores.',
      color: const Color(0xFF34A853),
    ),
    _OnboardingData(
      emoji: '🎓',
      title: 'Live Expert Lessons',
      subtitle: 'Join free daily webinars with IELTS experts. Build skills in real time with thousands of students.',
      color: const Color(0xFFFF6B35),
    ),
    _OnboardingData(
      emoji: '📊',
      title: 'Track Your Progress',
      subtitle: 'Visualize your band score improvements, identify weaknesses, and stay on track for your goal.',
      color: const Color(0xFF9C27B0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8, height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? _pages[_currentPage].color : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 32),
                  if (_currentPage < _pages.length - 1)
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Skip'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _pages[_currentPage].color),
                          onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                          child: const Text('Next'),
                        ),
                      ),
                    ])
                  else
                    Column(children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _pages[_currentPage].color),
                        onPressed: () => context.go('/register'),
                        child: const Text('Get Started – It\'s Free'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Already have an account? Log in'),
                      ),
                    ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String emoji, title, subtitle;
  final Color color;
  const _OnboardingData({required this.emoji, required this.title, required this.subtitle, required this.color});
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [data.color.withOpacity(0.1), Colors.white],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 100, 32, 200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(child: Text(data.emoji, style: const TextStyle(fontSize: 56))),
            ),
            const SizedBox(height: 40),
            Text(data.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(data.subtitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
