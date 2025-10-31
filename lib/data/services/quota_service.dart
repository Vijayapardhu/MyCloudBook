import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quota.dart';

extension UserTierExtension on UserTier {
  String get value => toString().split('.').last;
}

/// Quota service for managing user quotas
class QuotaService {
  final SupabaseClient _client;
  
  QuotaService({SupabaseClient? client}) 
      : _client = client ?? Supabase.instance.client;

  /// Get user quota
  Future<UserQuota> getUserQuota() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('user_quotas')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // Create quota if it doesn't exist
      return await _createQuota(userId);
    }

    return UserQuota.fromJson(response);
  }

  /// Create quota for user
  Future<UserQuota> _createQuota(String userId) async {
    final now = DateTime.now();
    final resetDate = DateTime(now.year, now.month + 1, 1);

    final response = await _client.from('user_quotas').insert({
      'user_id': userId,
      'tier': 'free',
      'pages_uploaded_this_month': 0,
      'storage_used_bytes': 0,
      'api_calls_this_month': 0,
      'quota_reset_date': resetDate.toIso8601String().split('T')[0],
    }).select().single();

    return UserQuota.fromJson(response);
  }

  /// Check if user can upload pages
  Future<bool> canUploadPages({int count = 1}) async {
    final quota = await getUserQuota();
    
    // Premium users have no limits
    if (quota.tier == UserTier.premium) return true;
    
    return (quota.pagesUploadedThisMonth + count) <= 100;
  }

  /// Check if user can store additional bytes
  Future<bool> canStoreBytes(int additionalBytes) async {
    final quota = await getUserQuota();
    
    // Premium users have no limits
    if (quota.tier == UserTier.premium) return true;
    
    const maxStorageBytes = 5 * 1024 * 1024 * 1024; // 5GB
    return (quota.storageUsedBytes + additionalBytes) <= maxStorageBytes;
  }

  /// Get quota usage percentage (0.0 to 1.0)
  Future<Map<String, double>> getUsagePercentages() async {
    final quota = await getUserQuota();
    
    if (quota.tier == UserTier.premium) {
      return {
        'pages': 0.0,
        'storage': 0.0,
        'api': 0.0,
      };
    }

    const maxPages = 100;
    const maxStorageBytes = 5 * 1024 * 1024 * 1024; // 5GB
    const maxApiCalls = 10000; // Placeholder, adjust as needed

    return {
      'pages': (quota.pagesUploadedThisMonth / maxPages).clamp(0.0, 1.0),
      'storage': (quota.storageUsedBytes / maxStorageBytes).clamp(0.0, 1.0),
      'api': (quota.apiCallsThisMonth / maxApiCalls).clamp(0.0, 1.0),
    };
  }

  /// Get quota statistics for dashboard
  Future<Map<String, dynamic>> getUsageStats() async {
    final quota = await getUserQuota();
    final percentages = await getUsagePercentages();

    const maxPages = 100;
    const maxStorageBytes = 5 * 1024 * 1024 * 1024; // 5GB

    return {
      'quota': quota,
      'percentages': percentages,
      'pagesRemaining': maxPages - quota.pagesUploadedThisMonth,
      'storageRemainingMB': ((maxStorageBytes - quota.storageUsedBytes) / (1024 * 1024)).round(),
      'isNearLimit': percentages['pages']! >= 0.8 || percentages['storage']! >= 0.8,
      'isExceeded': percentages['pages']! >= 1.0 || percentages['storage']! >= 1.0,
    };
  }

  /// Stream quota changes (for real-time updates)
  Stream<UserQuota> streamQuota() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _client
        .from('user_quotas')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((data) {
          if (data.isEmpty) {
            throw Exception('Quota not found');
          }
          return UserQuota.fromJson(data.first);
        });
  }

  /// Manually trigger quota reset (admin only, normally done via scheduled job)
  Future<void> resetMonthlyQuotas() async {
    await _client.rpc('reset_monthly_quotas');
  }
}

