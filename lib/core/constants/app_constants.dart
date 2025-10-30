/// Application-wide constants
class AppConstants {
  // User Tiers
  static const String tierFree = 'free';
  static const String tierPremium = 'premium';
  
  // Note Types
  static const String noteTypeRegular = 'regular';
  static const String noteTypeRoughWork = 'rough_work';
  
  // Collaboration Roles
  static const String roleOwner = 'owner';
  static const String roleEditor = 'editor';
  static const String roleCommenter = 'commenter';
  static const String roleViewer = 'viewer';
  
  // AI Content Types
  static const String aiContentFlashcard = 'flashcard';
  static const String aiContentQuiz = 'quiz';
  static const String aiContentConceptMap = 'concept_map';
  static const String aiContentSummary = 'summary';
  
  // Operation Types
  static const String operationInsert = 'insert';
  static const String operationUpdate = 'update';
  static const String operationDelete = 'delete';
  
  // Entity Types
  static const String entityNote = 'note';
  static const String entityPage = 'page';
  static const String entityCollaboration = 'collaboration';
  
  // Quota Alert Thresholds
  static const double quotaWarning80Percent = 0.80;
  static const double quotaWarning100Percent = 1.0;
  
  // API Providers
  static const String apiProviderGemini = 'gemini';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache Keys
  static const String cacheUserProfile = 'user_profile';
  static const String cacheQuotas = 'user_quotas';
  static const String cacheTimeline = 'timeline_notes';
  
  // Storage Keys
  static const String storageAPIKey = 'encrypted_api_key';
  static const String storageThemeMode = 'theme_mode';
  static const String storageNotificationPrefs = 'notification_preferences';
  
  // Date Formats
  static const String dateFormatDisplay = 'MMM dd, yyyy';
  static const String dateFormatISO = 'yyyy-MM-dd';
  static const String dateTimeFormatDisplay = 'MMM dd, yyyy HH:mm';
  
  // File Extensions
  static const String imageExtensionJPEG = 'jpg';
  static const String imageExtensionPNG = 'png';
  static const String pdfExtension = 'pdf';
  
  // Notification Channels
  static const String notificationChannelQuota = 'quota_alerts';
  static const String notificationChannelCollaboration = 'collaboration';
  static const String notificationChannelSync = 'sync_status';
  
  // Error Messages
  static const String errorNetworkConnection = 'No internet connection';
  static const String errorQuotaExceeded = 'Monthly quota exceeded';
  static const String errorAPIKeyMissing = 'Gemini API key not configured';
  static const String errorAPIQuotaExceeded = 'API quota exceeded. Please check your credits.';
  static const String errorGeneric = 'An error occurred. Please try again.';
}

