/// App configuration and environment variables
class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://pvhbthrjstqrzsasfzjc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2aGJ0aHJqc3RxcnpzYXNmempjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE4NDQxOTIsImV4cCI6MjA3NzQyMDE5Mn0.1uYND0inAjJOuT9-rKpUiaUOSzqjtD-PGJS_x4_ZTWc';
  
  // App Information
  static const String appName = 'MyCloudBook';
  static const String appVersion = '1.0.0';
  
  // Quota Limits
  static const int freeTierMaxPagesPerMonth = 500;
  static const int freeTierMaxStorageBytes = 5 * 1024 * 1024 * 1024; // 5GB
  
  // Feature Flags
  static const bool enableAI = true;
  static const bool enableCollaboration = true;
  static const bool enableOfflineSync = true;
  
  // Limits
  static const int maxImageSizeMB = 10;
  static const int maxOfflineQueueSize = 200;
  static const int syncIntervalSeconds = 30;
  
  // API Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  
  // Database Configuration
  static const String databaseName = 'mycloudbook.db';
  static const int databaseVersion = 1;
  
  // Storage Buckets
  static const String imagesBucket = 'images';
  static const String pdfsBucket = 'pdfs';
  static const String voiceBucket = 'voice';
  
  // Debug Mode
  static const bool debugMode = true;
}

