import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

/// Realtime service for collaboration features
class RealtimeService {
  final SupabaseClient _client;
  final Map<String, RealtimeChannel> _channels = {};

  RealtimeService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Subscribe to note changes
  RealtimeChannel subscribeToNote(
    String noteId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    final channel = _client.channel('note:$noteId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'notes',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: noteId,
      ),
      callback: (payload) {
        onUpdate(payload.newRecord);
      },
    ).subscribe();

    _channels['note:$noteId'] = channel;
    return channel;
  }

  /// Subscribe to chat messages for a note
  Stream<List<Map<String, dynamic>>> streamChatMessages(String noteId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('note_id', noteId)
        .order('created_at', ascending: true)
        .map((data) => data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
  }

  /// Subscribe to presence for a note
  Future<RealtimeChannel> subscribeToPresence(
    String noteId,
    void Function(Map<String, dynamic>) onPresenceUpdate,
  ) async {
    final channel = _client.channel('presence:$noteId');

    channel
        .onPresenceSync((payload) {
          onPresenceUpdate({'event': 'sync', 'presences': payload});
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            final userId = _client.auth.currentUser?.id;
            if (userId != null) {
              await channel.track({
                'user_id': userId,
                'online_at': DateTime.now().toIso8601String(),
              });
            }
          }
        });

    _channels['presence:$noteId'] = channel;
    return channel;
  }

  /// Update typing status
  Future<void> updateTypingStatus(String noteId, bool isTyping) async {
    final channel = _channels['presence:$noteId'];
    if (channel == null) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await channel.track({
      'user_id': userId,
      'typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(String channelKey) async {
    final channel = _channels[channelKey];
    if (channel != null) {
      await channel.unsubscribe();
      _channels.remove(channelKey);
    }
  }

  /// Unsubscribe from all channels
  Future<void> unsubscribeAll() async {
    for (final channel in _channels.values) {
      await channel.unsubscribe();
    }
    _channels.clear();
  }
}

