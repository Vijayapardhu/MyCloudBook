import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note Detail'),
        actions: [
          IconButton(
            onPressed: () => context.go('/note/$id/edit'),
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Note #$id', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text('Content preview goes here...'),
          ],
        ),
      ),
    );
  }
}


