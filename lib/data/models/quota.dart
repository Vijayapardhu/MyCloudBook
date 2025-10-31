import 'package:equatable/equatable.dart';

/// User tier enum
enum UserTier {
  free,
  premium,
}

/// User quota model for free tier tracking
class UserQuota extends Equatable {
  final String userId;
  final UserTier tier;
  final int pagesUploadedThisMonth;
  final int storageUsedBytes;
  final int apiCallsThisMonth;
  final DateTime quotaResetDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserQuota({
    required this.userId,
    this.tier = UserTier.free,
    this.pagesUploadedThisMonth = 0,
    this.storageUsedBytes = 0,
    this.apiCallsThisMonth = 0,
    required this.quotaResetDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserQuota.fromJson(Map<String, dynamic> json) {
    final tierStr = json['tier'] as String? ?? 'free';
    final tier = tierStr == 'premium' ? UserTier.premium : UserTier.free;
    return UserQuota(
      userId: json['user_id'] as String,
      tier: tier,
      pagesUploadedThisMonth: json['pages_uploaded_this_month'] as int? ?? 0,
      storageUsedBytes: json['storage_used_bytes'] as int? ?? 0,
      apiCallsThisMonth: json['api_calls_this_month'] as int? ?? 0,
      quotaResetDate: DateTime.parse(json['quota_reset_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'tier': tier == UserTier.premium ? 'premium' : 'free',
      'pages_uploaded_this_month': pagesUploadedThisMonth,
      'storage_used_bytes': storageUsedBytes,
      'api_calls_this_month': apiCallsThisMonth,
      'quota_reset_date': quotaResetDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserQuota copyWith({
    String? userId,
    UserTier? tier,
    int? pagesUploadedThisMonth,
    int? storageUsedBytes,
    int? apiCallsThisMonth,
    DateTime? quotaResetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserQuota(
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      pagesUploadedThisMonth: pagesUploadedThisMonth ?? this.pagesUploadedThisMonth,
      storageUsedBytes: storageUsedBytes ?? this.storageUsedBytes,
      apiCallsThisMonth: apiCallsThisMonth ?? this.apiCallsThisMonth,
      quotaResetDate: quotaResetDate ?? this.quotaResetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isPremium => tier == UserTier.premium;
  bool get isFree => tier == UserTier.free;
  
  double get pagesUsagePercentage {
    if (isPremium) return 0.0;
    return pagesUploadedThisMonth / 100; // Free tier: 100 pages/month
  }
  
  double get storageUsagePercentage {
    if (isPremium) return 0.0;
    const maxStorageBytes = 5 * 1024 * 1024 * 1024; // 5GB
    return storageUsedBytes / maxStorageBytes;
  }
  
  bool get canUploadPages {
    if (isPremium) return true;
    return pagesUploadedThisMonth < 100;
  }
  
  int get remainingPages {
    if (isPremium) return 999999; // Unlimited
    return (100 - pagesUploadedThisMonth).clamp(0, 100);
  }

  @override
  List<Object?> get props => [
        userId,
        tier,
        pagesUploadedThisMonth,
        storageUsedBytes,
        apiCallsThisMonth,
        quotaResetDate,
        createdAt,
        updatedAt,
      ];
}


