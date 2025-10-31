import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';

class NotesService {
  static const String table = 'notes';
  final SupabaseClient _client;

  NotesService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<List<Note>> fetchNotes({int offset = 0, int limit = 20}) async {
    final response = await _client
        .from(table)
        .select()
        .order('date', ascending: false)
        .order('updated_at', ascending: false)
        .range(offset, offset + limit - 1);
    final List data = response;
    return data.map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Note> createNote({required String userId, String? title, DateTime? date}) async {
    final now = DateTime.now();
    final payload = {
      'user_id': userId,
      'title': title,
      'date': (date ?? now).toIso8601String().split('T')[0],
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
    final inserted = await _client.from(table).insert(payload).select().single();
    return Note.fromJson(inserted);
  }

  Future<void> deleteNote(String id) async {
    await _client.from(table).delete().eq('id', id);
  }

  Future<void> updateNoteMetadata(String id, Map<String, dynamic> metadata) async {
    await _client.from(table).update({'metadata': metadata, 'updated_at': DateTime.now().toIso8601String()}).eq('id', id);
  }
}


