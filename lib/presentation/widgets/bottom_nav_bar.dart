import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBar extends StatelessWidget {
  final String currentPath;

  const BottomNavBar({
    super.key,
    required this.currentPath,
  });

  int _getCurrentIndex() {
    if (currentPath.startsWith('/timeline')) return 0;
    if (currentPath.startsWith('/search')) return 1;
    if (currentPath.startsWith('/notebook')) return 2;
    if (currentPath.startsWith('/notifications')) return 3;
    if (currentPath.startsWith('/profile') || currentPath.startsWith('/settings')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        if (!currentPath.startsWith('/timeline')) {
          context.go('/timeline');
        }
        break;
      case 1:
        if (!currentPath.startsWith('/search')) {
          context.go('/search');
        }
        break;
      case 2:
        context.go('/notebook'); // Changed to notebook scanner
        break;
      case 3:
        if (!currentPath.startsWith('/notifications')) {
          context.go('/notifications');
        }
        break;
      case 4:
        if (!currentPath.startsWith('/profile') && !currentPath.startsWith('/settings')) {
          context.go('/profile');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _getCurrentIndex(),
      onDestinationSelected: (index) => _onTap(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Timeline',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book),
          label: 'Notebook',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

