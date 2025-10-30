import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, String>> _events = <Map<String, String>>[];
  RealtimeChannel? _notesChannel;
  RealtimeChannel? _pagesChannel;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    final client = Supabase.instance.client;
    _notesChannel = client
        .channel('public:notes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notes',
          callback: (payload) {
            final data = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
            setState(() {
              _events.insert(0, {
                'title': 'Note ${payload.eventType.name}',
                'subtitle': data.toString(),
              });
            });
          },
        )
        .subscribe();

    _pagesChannel = client
        .channel('public:pages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pages',
          callback: (payload) {
            final data = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
            setState(() {
              _events.insert(0, {
                'title': 'Page ${payload.eventType.name}',
                'subtitle': data.toString(),
              });
            });
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _notesChannel?.unsubscribe();
    _pagesChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _events.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    const Text('No notifications yet'),
                  ],
                ),
              )
            : ListView.separated(
                itemCount: _events.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final e = _events[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(e['title'] ?? ''),
                      subtitle: Text(e['subtitle'] ?? ''),
                    ),
                  );
                },
              ),
      ),
    );
  }
}


