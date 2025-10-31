import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav_bar.dart';

class MainScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const MainScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final showBottomNav = _shouldShowBottomNav(currentPath);

    return Scaffold(
      appBar: title != null
          ? AppBar(
              title: Text(title!),
              actions: actions,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav
          ? SafeArea(
              child: BottomNavBar(currentPath: currentPath),
            )
          : null,
    );
  }

  bool _shouldShowBottomNav(String path) {
    // Don't show on auth screens, editor, detail, or collaboration screens
    if (path.startsWith('/login') ||
        path.startsWith('/signup') ||
        path.startsWith('/onboarding') ||
        path.startsWith('/note/') ||
        path.startsWith('/collab/') ||
        path.startsWith('/settings')) {
      return false;
    }
    // Show bottom nav on all other screens including /usage, /profile, /timeline, /search, /notebook, /notifications
    return true;
  }
}

