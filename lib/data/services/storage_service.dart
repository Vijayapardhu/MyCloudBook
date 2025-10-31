import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';

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
    return uploadBytes(bytes: bytes, bucket: 'voice', path: path, contentType: contentType);
  }

  /// Download image bytes from URL using Dio
  Future<Uint8List> downloadImageBytes(String imageUrl) async {
    try {
      final dio = Dio();
      final response = await dio.get<Uint8List>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data!;
      } else {
        throw Exception('Failed to download image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error downloading image: $e');
    }
  }

  /// Download from storage path
  Future<Uint8List> downloadFromStorage({
    required String bucket,
    required String path,
  }) async {
    try {
      final storage = _client.storage.from(bucket);
      final bytes = await storage.download(path);
      return bytes;
    } catch (e) {
      throw Exception('Error downloading from storage: $e');
    }
  }
}


