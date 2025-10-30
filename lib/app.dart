import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/timeline_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'presentation/screens/note_detail_screen.dart';
import 'presentation/screens/note_editor_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/notifications_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MyCloudBookApp extends StatelessWidget {
  final AuthBloc authBloc;
  const MyCloudBookApp({super.key, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      initialLocation: '/',
      refreshListenable: authBloc,
      redirect: (context, state) {
        final bool loggedIn = Supabase.instance.client.auth.currentSession != null;
        final bool onAuth = state.uri.path == '/login' || state.uri.path == '/signup';
        final bool onRoot = state.uri.path == '/';
        if (!loggedIn && !onAuth) return '/login';
        if (loggedIn && (onAuth || onRoot)) return '/timeline';
        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
        GoRoute(path: '/timeline', builder: (_, __) => const TimelineScreen()),
        GoRoute(path: '/note/new', builder: (_, __) => const NoteEditorScreen()),
        GoRoute(
          path: '/note/:id',
          builder: (_, s) => NoteDetailScreen(id: s.pathParameters['id']!),
        ),
        GoRoute(
          path: '/note/:id/edit',
          builder: (_, s) => NoteEditorScreen(noteId: s.pathParameters['id']!),
        ),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      ],
    );

    _ensureFcmToken();

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }

  Future<void> _ensureFcmToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return;
      await Supabase.instance.client.from('profiles').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (_) {}
  }
}

