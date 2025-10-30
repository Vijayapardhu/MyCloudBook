import 'package:supabase_flutter/supabase_flutter.dart';

class SearchService {
  final SupabaseClient _client;
  SearchService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return <Map<String, dynamic>>[];

    final notesFuture = _client
        .from('notes')
        .select('id,title,updated_at')
        .textSearch('title', q, config: 'english')
        .limit(20);

    final pagesFuture = _client
        .from('pages')
        .select('id,note_id,ocr_text')
        .textSearch('ocr_text', q, config: 'english')
        .limit(20);

    final results = await Future.wait([notesFuture, pagesFuture]);
    final List notes = results[0] as List? ?? <dynamic>[];
    final List pages = results[1] as List? ?? <dynamic>[];

    final mapped = <Map<String, dynamic>>[];
    mapped.addAll(notes.map((e) => {
          'type': 'note',
          'id': (e as Map)['id'],
          'title': (e)['title'] ?? 'Untitled',
          'snippet': 'Note title match',
        }));
    mapped.addAll(pages.map((e) {
      final text = (e as Map)['ocr_text'] as String?;
      final snippet = text == null
          ? ''
          : text.substring(0, text.length > 80 ? 80 : text.length);
      return {
        'type': 'page',
        'id': (e)['id'],
        'note_id': (e)['note_id'],
        'title': 'Page match',
        'snippet': snippet,
      };
    }));
    return mapped;
  }
}


