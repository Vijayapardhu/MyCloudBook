import 'package:supabase_flutter/supabase_flutter.dart';

class PagesService {
  static const String table = 'pages';
  final SupabaseClient _client;
  PagesService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<Map<String, dynamic>> createPage({
    required String noteId,
    required int pageNumber,
    required String imageUrl,
    required String storagePath,
    bool isRoughWork = false,
    List<String>? tags,
    String? ocrText,
    String? aiSummary,
  }) async {
    final payload = {
      'note_id': noteId,
      'page_number': pageNumber,
      'is_rough_work': isRoughWork,
      'image_url': imageUrl,
      'storage_path': storagePath,
      'tags': tags,
      'ocr_text': ocrText,
      'ai_summary': aiSummary,
    };
    final inserted = await _client.from(table).insert(payload).select().single();
    return inserted;
  }

  Future<int> countPages(String noteId) async {
    final res = await _client
        .from(table)
        .select('page_number')
        .eq('note_id', noteId)
        .order('page_number', ascending: false)
        .limit(1);
    if (res.isNotEmpty) {
      return (res.first['page_number'] as int);
    }
    return 0;
  }

  Future<List<Map<String, dynamic>>> listByNote(String noteId) async {
    final res = await _client
        .from(table)
        .select('id,page_number,image_url,storage_path,ocr_text,ai_summary,tags,created_at')
        .eq('note_id', noteId)
        .order('page_number');
    final List data = res as List;
    return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> updatePage(String id, Map<String, dynamic> data) async {
    await _client.from(table).update(data).eq('id', id);
  }
}


