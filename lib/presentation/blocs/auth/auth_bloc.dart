import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// AuthBloc is a minimal ChangeNotifier that listens to Supabase auth events
/// and notifies listeners so the router can react via refreshListenable.
class AuthBloc extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  AuthBloc() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      notifyListeners();
    });
  }

  bool get isLoggedIn => Supabase.instance.client.auth.currentSession != null;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// Intentionally no global singleton. Create this AFTER Supabase.initialize
// and pass it where needed (e.g., into the root app widget).
