import 'package:supabase_flutter/supabase_flutter.dart';

/// Collaboration service for managing note sharing and permissions
class CollaborationService {
  final SupabaseClient _client;

  CollaborationService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Get collaborators for a note
  Future<List<Map<String, dynamic>>> getCollaborators(String noteId) async {
    final response = await _client
        .from('collaborations')
        .select('''
          id,
          user_id,
          role,
          created_at,
          profiles:user_id (
            id,
            email,
            full_name,
            avatar_url
          )
        ''')
        .eq('note_id', noteId);

    final List data = response;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Invite user to collaborate on note
  Future<void> inviteCollaborator({
    required String noteId,
    required String userEmail,
    required String role, // 'viewer', 'commenter', 'editor'
  }) async {
    // First, find user by email
    final userResponse = await _client
        .from('profiles')
        .select('id')
        .eq('email', userEmail)
        .maybeSingle();

    if (userResponse == null) {
      throw Exception('User with email $userEmail not found');
    }

      final userId = (userResponse['id'] as String);

    // Check if user is already a collaborator
    final existing = await _client
        .from('collaborations')
        .select('id')
        .eq('note_id', noteId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('User is already a collaborator');
    }

    // Add collaboration
    await _client.from('collaborations').insert({
      'note_id': noteId,
      'user_id': userId,
      'role': role,
    });
  }

  /// Update collaborator role
  Future<void> updateCollaboratorRole({
    required String collaborationId,
    required String role,
  }) async {
    await _client
        .from('collaborations')
        .update({'role': role})
        .eq('id', collaborationId);
  }

  /// Remove collaborator
  Future<void> removeCollaborator(String collaborationId) async {
    await _client.from('collaborations').delete().eq('id', collaborationId);
  }

  /// Send chat message
  Future<void> sendChatMessage({
    required String noteId,
    required String message,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _client.from('chat_messages').insert({
      'note_id': noteId,
      'user_id': userId,
      'message': message,
    });
  }

  /// Check if user can edit note
  Future<bool> canEditNote(String noteId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    // Check if user is owner
    final noteResponse = await _client
        .from('notes')
        .select('user_id')
        .eq('id', noteId)
        .maybeSingle();

    if (noteResponse != null) {
      final noteOwner = (noteResponse['user_id'] as String);
      if (noteOwner == userId) return true;
    }

    // Check if user is editor or owner collaborator
    final collabResponse = await _client
        .from('collaborations')
        .select('role')
        .eq('note_id', noteId)
        .eq('user_id', userId)
        .maybeSingle();

    if (collabResponse != null) {
      final role = collabResponse['role'] as String;
      return role == 'editor' || role == 'owner';
    }

    return false;
  }

  /// Check if user can comment on note
  Future<bool> canCommentOnNote(String noteId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    // Owner can always comment
    if (await canEditNote(noteId)) return true;

    // Check if user is commenter or above
    final collabResponse = await _client
        .from('collaborations')
        .select('role')
        .eq('note_id', noteId)
        .eq('user_id', userId)
        .maybeSingle();

    if (collabResponse != null) {
      final role = collabResponse['role'] as String;
      return ['commenter', 'editor', 'owner'].contains(role);
    }

    return false;
  }
}

