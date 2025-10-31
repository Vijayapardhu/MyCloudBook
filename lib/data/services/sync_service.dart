import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum SyncEntity { note, page }
enum SyncOperation { insert, update, delete }

class SyncService {
  static const String _boxName = 'sync_queue';

  Future<Box> _box() => Hive.openBox(_boxName);

  Future<void> enqueue({
    required SyncEntity entity,
    required SyncOperation operation,
    required Map<String, dynamic> payload,
  }) async {
    final box = await _box();
    final list = (box.get('queue') as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    list.add({
      'entity': entity.name,
      'operation': operation.name,
      'payload': payload,
    });
    await box.put('queue', list);
  }

  Future<int> getPendingCount() async {
    final box = await _box();
    final queue = (box.get('queue') as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    return queue.length;
  }

  Future<void> flush() async {
    final client = Supabase.instance.client;
    final box = await _box();
    final List<Map<String, dynamic>> queue = ((box.get('queue') as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    if (queue.isEmpty) return;
    final remaining = <Map<String, dynamic>>[];
    for (final job in queue) {
      final entity = job['entity'] as String;
      final op = job['operation'] as String;
      final payload = Map<String, dynamic>.from(job['payload'] as Map);
      try {
        if (entity == SyncEntity.note.name) {
          if (op == SyncOperation.insert.name) {
            await client.from('notes').insert(payload);
          } else if (op == SyncOperation.update.name) {
            await client.from('notes').update(payload['data']).eq('id', payload['id']);
          } else if (op == SyncOperation.delete.name) {
            await client.from('notes').delete().eq('id', payload['id']);
          }
        } else if (entity == SyncEntity.page.name) {
          if (op == SyncOperation.insert.name) {
            await client.from('pages').insert(payload);
          } else if (op == SyncOperation.update.name) {
            await client.from('pages').update(payload['data']).eq('id', payload['id']);
          } else if (op == SyncOperation.delete.name) {
            await client.from('pages').delete().eq('id', payload['id']);
          }
        }
      } catch (_) {
        remaining.add(job);
      }
    }
    await box.put('queue', remaining);
  }

  Future<int> queueSize() async {
    final box = await _box();
    final List list = (box.get('queue') as List?) ?? <dynamic>[];
    return list.length;
  }

  Future<bool> hasPending() async => (await queueSize()) > 0;
}


