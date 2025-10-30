import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <_Slide>[
      const _Slide(title: 'Welcome to MyCloudBook', subtitle: 'AI-powered digital notebook'),
      const _Slide(title: 'Capture & Organize', subtitle: 'Scan pages, auto OCR, clean structure'),
      const _Slide(title: 'Search & Study', subtitle: 'Instant search, LaTeX, audio & more'),
    ];
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Row(
                    children: List.generate(pages.length, (i) {
                      final active = i == _index;
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: active ? 14 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Skip'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (_index < pages.length - 1) {
                        _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                      } else {
                        context.go('/login');
                      }
                    },
                    child: Text(_index < pages.length - 1 ? 'Next' : 'Get started'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 140, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 28),
          Text(title, style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(subtitle, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}


