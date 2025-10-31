import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity service to monitor network status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  final _controller = StreamController<bool>.broadcast();

  /// Stream of connectivity status (true = connected, false = disconnected)
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Check current connectivity status
  Future<bool> isConnected() async {
    final results = await _connectivity.checkConnectivity();
    return results != ConnectivityResult.none;
  }

  /// Start monitoring connectivity changes
  void startMonitoring() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      _controller.add(isConnected);
    });
  }

  /// Stop monitoring connectivity changes
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}

/// Singleton instance (optional, can be managed via dependency injection)
final connectivityService = ConnectivityService();

