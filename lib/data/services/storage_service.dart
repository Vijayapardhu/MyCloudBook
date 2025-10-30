import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client;
  StorageService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  Future<(String publicUrl, String storagePath)> uploadBytes({
    required Uint8List bytes,
    required String bucket,
    required String path,
    String contentType = 'application/octet-stream',
  }) async {
    final storage = _client.storage.from(bucket);
    await storage.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentType, upsert: true));
    final publicUrl = storage.getPublicUrl(path);
    return (publicUrl, path);
  }

  Future<(String publicUrl, String storagePath)> uploadAudio({
    required Uint8List bytes,
    required String path,
    String contentType = 'audio/m4a',
  }) async {
    return uploadBytes(bytes: bytes, bucket: 'pages', path: path, contentType: contentType);
  }
}


