import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_config.dart';
import 'app.dart';
import 'core/utils/web_url.dart';
import 'presentation/blocs/auth/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local storage (Hive)
  await Hive.initFlutter();
  
  // Initialize Supabase
  // NOTE: Add your Supabase credentials in app_config.dart
  try {
    if (!AppConfig.supabaseUrl.contains('YOUR_SUPABASE_URL') &&
        !AppConfig.supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY')) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: AppConfig.debugMode,
      );
      // Process OAuth redirect hash on web so the session becomes available immediately
      if (kIsWeb) {
        try {
          await Supabase.instance.client.auth.getSessionFromUrl(Uri.base);
          // Clean up the URL so the app isn't stuck on /?code=...
          replaceUrlPath('/');
        } catch (_) {}
      }
    }
  } catch (_) {
    // Continue without Supabase if configuration is missing during local runs
  }
  
  // Initialize Firebase
  // NOTE: Add your Firebase configuration files to platform folders
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyCDO7PgSeKyTuJvgspGi_9ezQpbq5Qlg0U',
          authDomain: 'mycloud-book.firebaseapp.com',
          databaseURL: 'https://mycloud-book-default-rtdb.asia-southeast1.firebasedatabase.app',
          projectId: 'mycloud-book',
          storageBucket: 'mycloud-book.firebasestorage.app',
          messagingSenderId: '675109149421',
          appId: '1:675109149421:web:110133aaa3727ef72ecae4',
          measurementId: 'G-7G1N6VMZWP',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (_) {
    // Continue without Firebase if not configured
  }
  
  final authBloc = AuthBloc();
  runApp(MyCloudBookApp(authBloc: authBloc));
}
