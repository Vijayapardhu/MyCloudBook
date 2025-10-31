import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/services/quota_service.dart';
import '../../../data/models/quota.dart';

// Events
abstract class QuotaEvent extends Equatable {
  const QuotaEvent();
  @override
  List<Object?> get props => [];
}

class RefreshQuota extends QuotaEvent {
  const RefreshQuota();
}

class QuotaAlertSeen extends QuotaEvent {
  const QuotaAlertSeen();
}

// States
abstract class QuotaState extends Equatable {
  const QuotaState();
  @override
  List<Object?> get props => [];
}

class QuotaInitial extends QuotaState {
  const QuotaInitial();
}

class QuotaLoading extends QuotaState {
  const QuotaLoading();
}

class QuotaOk extends QuotaState {
  final UserQuota quota;
  final Map<String, double> percentages;
  final Map<String, dynamic> stats;

  const QuotaOk({
    required this.quota,
    required this.percentages,
    required this.stats,
  });

  @override
  List<Object?> get props => [quota, percentages, stats];
}

class QuotaNearLimit extends QuotaState {
  final UserQuota quota;
  final Map<String, double> percentages;
  final Map<String, dynamic> stats;

  const QuotaNearLimit({
    required this.quota,
    required this.percentages,
    required this.stats,
  });

  @override
  List<Object?> get props => [quota, percentages, stats];
}

class QuotaExceeded extends QuotaState {
  final UserQuota quota;
  final Map<String, double> percentages;
  final Map<String, dynamic> stats;

  const QuotaExceeded({
    required this.quota,
    required this.percentages,
    required this.stats,
  });

  @override
  List<Object?> get props => [quota, percentages, stats];
}

class QuotaError extends QuotaState {
  final String message;

  const QuotaError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class QuotaBloc extends Bloc<QuotaEvent, QuotaState> {
  final QuotaService _quotaService;

  QuotaBloc({QuotaService? quotaService})
      : _quotaService = quotaService ?? QuotaService(),
        super(const QuotaInitial()) {
    on<RefreshQuota>(_onRefreshQuota);
    on<QuotaAlertSeen>(_onQuotaAlertSeen);
  }

  Future<void> _onRefreshQuota(
    RefreshQuota event,
    Emitter<QuotaState> emit,
  ) async {
    emit(const QuotaLoading());
    try {
      final quota = await _quotaService.getUserQuota();
      final percentages = await _quotaService.getUsagePercentages();
      final stats = await _quotaService.getUsageStats();

      final isExceeded = stats['isExceeded'] as bool;
      final isNearLimit = stats['isNearLimit'] as bool;

      if (isExceeded) {
        emit(QuotaExceeded(
          quota: quota,
          percentages: percentages,
          stats: stats,
        ));
      } else if (isNearLimit) {
        emit(QuotaNearLimit(
          quota: quota,
          percentages: percentages,
          stats: stats,
        ));
      } else {
        emit(QuotaOk(
          quota: quota,
          percentages: percentages,
          stats: stats,
        ));
      }
    } catch (e) {
      emit(QuotaError(e.toString()));
    }
  }

  void _onQuotaAlertSeen(
    QuotaAlertSeen event,
    Emitter<QuotaState> emit,
  ) {
    // For now, just refresh; could store "seen" state in Hive if needed
    add(const RefreshQuota());
  }
}

