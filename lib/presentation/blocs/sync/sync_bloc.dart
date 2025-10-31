import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/services/sync_service.dart';
import '../../../core/utils/connectivity.dart';
import 'dart:async';

// Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class EnqueueOperation extends SyncEvent {
  final SyncEntity entity;
  final SyncOperation operation;
  final Map<String, dynamic> payload;
  const EnqueueOperation({
    required this.entity,
    required this.operation,
    required this.payload,
  });
  @override
  List<Object?> get props => [entity, operation, payload];
}

class FlushQueue extends SyncEvent {
  const FlushQueue();
}

class CheckSyncStatus extends SyncEvent {
  const CheckSyncStatus();
}

// States
abstract class SyncState extends Equatable {
  const SyncState();
  @override
  List<Object?> get props => [];
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncInProgress extends SyncState {
  final int processed;
  final int total;
  const SyncInProgress({
    required this.processed,
    required this.total,
  });
  @override
  List<Object?> get props => [processed, total];
}

class SyncPending extends SyncState {
  final int count;
  const SyncPending(this.count);
  @override
  List<Object?> get props => [count];
}

class SyncComplete extends SyncState {
  final int synced;
  const SyncComplete(this.synced);
  @override
  List<Object?> get props => [synced];
}

class SyncError extends SyncState {
  final String message;
  const SyncError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncService _syncService;
  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _connectivitySubscription;

  SyncBloc({
    SyncService? syncService,
    ConnectivityService? connectivityService,
  })  : _syncService = syncService ?? SyncService(),
        _connectivityService = connectivityService ?? ConnectivityService(),
        super(const SyncIdle()) {
    on<EnqueueOperation>(_onEnqueueOperation);
    on<FlushQueue>(_onFlushQueue);
    on<CheckSyncStatus>(_onCheckSyncStatus);

    // Monitor connectivity
    _connectivityService.startMonitoring();
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(
      (isConnected) {
        if (isConnected) {
          add(const FlushQueue());
        }
      },
    );
  }

  Future<void> _onEnqueueOperation(
    EnqueueOperation event,
    Emitter<SyncState> emit,
  ) async {
    try {
      await _syncService.enqueue(
        entity: event.entity,
        operation: event.operation,
        payload: event.payload,
      );
      add(const CheckSyncStatus());
    } catch (e) {
      emit(SyncError(e.toString()));
    }
  }

  Future<void> _onFlushQueue(
    FlushQueue event,
    Emitter<SyncState> emit,
  ) async {
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      emit(const SyncError('No internet connection'));
      return;
    }

    try {
      final pendingCount = await _syncService.getPendingCount();
      if (pendingCount == 0) {
        emit(const SyncIdle());
        return;
      }

      emit(SyncInProgress(processed: 0, total: pendingCount));
      await _syncService.flush();

      final remainingCount = await _syncService.getPendingCount();
      if (remainingCount == 0) {
        emit(SyncComplete(pendingCount));
      } else {
        emit(SyncPending(remainingCount));
      }
    } catch (e) {
      emit(SyncError(e.toString()));
    }
  }

  Future<void> _onCheckSyncStatus(
    CheckSyncStatus event,
    Emitter<SyncState> emit,
  ) async {
    try {
      final pendingCount = await _syncService.getPendingCount();
      if (pendingCount == 0) {
        emit(const SyncIdle());
      } else {
        emit(SyncPending(pendingCount));
      }
    } catch (e) {
      emit(SyncError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    _connectivityService.stopMonitoring();
    return super.close();
  }
}

