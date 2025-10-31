import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/sync/sync_bloc.dart';

/// Sync status banner showing offline/online status and pending operations
class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        if (state is SyncIdle) {
          return const SizedBox.shrink();
        }

        if (state is SyncError) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red.shade50,
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sync error: ${state.message}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<SyncBloc>().add(const FlushQueue());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is SyncPending) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${state.count} operation${state.count != 1 ? 's' : ''} pending sync',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.read<SyncBloc>().add(const FlushQueue());
                  },
                  child: const Text('Sync Now'),
                ),
              ],
            ),
          );
        }

        if (state is SyncInProgress) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Syncing ${state.processed}/${state.total}...',
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          );
        }

        if (state is SyncComplete) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.green.shade50,
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Sync complete',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

