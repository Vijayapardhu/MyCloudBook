import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/image_compressor.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

/// AI Service for Gemini API integration
class AIService {
  final SupabaseClient _client;
  final Dio _httpClient;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _encryptionKeyKey = 'app_encryption_key';

  AIService({SupabaseClient? client, Dio? httpClient})
      : _client = client ?? Supabase.instance.client,
        _httpClient = httpClient ?? Dio();

  /// Get or generate encryption key
  Future<String> _getEncryptionKey() async {
    String? keyString = await _secureStorage.read(key: _encryptionKeyKey);
    if (keyString == null) {
      // Generate new key
      final key = encrypt.Key.fromSecureRandom(32);
      keyString = key.base64;
      await _secureStorage.write(key: _encryptionKeyKey, value: keyString);
    }
    return keyString;
  }

  /// Encrypt API key
  Future<String> _encryptAPIKey(String plainKey) async {
    final keyString = await _getEncryptionKey();
    final key = encrypt.Key.fromBase64(keyString);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainKey, iv: iv);
    return encrypted.base64;
  }

  /// Decrypt API key
  Future<String?> _decryptAPIKey(String encryptedKey) async {
    try {
      final keyString = await _getEncryptionKey();
      final key = encrypt.Key.fromBase64(keyString);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypt.Encrypted.fromBase64(encryptedKey);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      return null;
    }
  }

  /// Store encrypted API key
  Future<void> storeAPIKey(String apiKey) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final encrypted = await _encryptAPIKey(apiKey);
    
    await _client.from('api_keys').upsert({
      'user_id': userId,
      'provider': 'gemini',
      'encrypted_key': encrypted,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get decrypted API key
  Future<String?> getAPIKey() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('api_keys')
        .select()
        .eq('user_id', userId)
        .eq('provider', 'gemini')
        .maybeSingle();

    if (response == null) return null;
    final encrypted = response['encrypted_key'] as String;
    return await _decryptAPIKey(encrypted);
  }

  /// Recognize handwriting from image
  Future<HandwritingResult> recognizeHandwriting({
    required Uint8List imageBytes,
    required String pageId,
  }) async {
    final apiKey = await getAPIKey();
    if (apiKey == null) {
      throw Exception('API key not configured. Please add your Gemini API key in settings.');
    }

    // Compress image
    final compressed = await ImageCompressor.compressImage(
      imageBytes: imageBytes,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    final base64Image = base64Encode(compressed);
    final mimeType = ImageCompressor.getImageFormat(compressed) ?? 'image/webp';

    final startTime = DateTime.now();
    try {
      final response = await _httpClient.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-vision:generateContent?key=$apiKey',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Convert this handwritten text to digital text. Maintain formatting, structure, and line breaks. Preserve mathematical equations and symbols. Return only the extracted text without any additional commentary.'
                },
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 8192,
          }
        },
      );

      final data = response.data;
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      final tokensUsed = _estimateTokens(data);

      if (text == null || text.isEmpty) {
        throw Exception('No text extracted from image');
      }

      final result = HandwritingResult(
        text: text,
        tokensUsed: tokensUsed,
        processingTime: DateTime.now().difference(startTime),
      );

      // Log usage
      await _logUsage(
        operationType: 'handwriting_recognition',
        tokensUsed: tokensUsed,
        success: true,
      );

      return result;
    } catch (e) {
      final errorMsg = e.toString();
      final isQuotaError = errorMsg.contains('quota') || 
                          errorMsg.contains('429') ||
                          errorMsg.contains('RESOURCE_EXHAUSTED');

      await _logUsage(
        operationType: 'handwriting_recognition',
        tokensUsed: 0,
        success: false,
        errorMessage: errorMsg,
      );

      if (isQuotaError) {
        throw QuotaExceededException(
          'Your Gemini API quota has been exceeded. Please check your API credits or add more credits to your Gemini account.',
        );
      }

      rethrow;
    }
  }

  /// Generate summary from text
  Future<SummaryResult> generateSummary({
    required String text,
    int maxLength = 200,
  }) async {
    final apiKey = await getAPIKey();
    if (apiKey == null) {
      throw Exception('API key not configured');
    }

    final startTime = DateTime.now();
    try {
      final response = await _httpClient.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Summarize the following content in a concise format. Maximum $maxLength words. Focus on key concepts and main points:\n\n$text'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 500,
          }
        },
      );

      final data = response.data;
      final summary = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      final tokensUsed = _estimateTokens(data);

      if (summary == null || summary.isEmpty) {
        throw Exception('Failed to generate summary');
      }

      await _logUsage(
        operationType: 'summarization',
        tokensUsed: tokensUsed,
        success: true,
      );

      return SummaryResult(
        summary: summary,
        tokensUsed: tokensUsed,
        processingTime: DateTime.now().difference(startTime),
      );
    } catch (e) {
      await _logUsage(
        operationType: 'summarization',
        tokensUsed: 0,
        success: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Generate flashcards from content
  Future<List<Flashcard>> generateFlashcards(String content) async {
    final apiKey = await getAPIKey();
    if (apiKey == null) {
      throw Exception('API key not configured');
    }

    try {
      final response = await _httpClient.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text': 'Generate study flashcards from this content. Return ONLY a valid JSON array with this exact format (no markdown, no code blocks):\n'
                      '[{"question": "question text", "answer": "answer text"}]\n'
                      'Create 5-10 flashcards covering key concepts:\n\n$content'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.5,
            'maxOutputTokens': 2000,
          }
        },
      );

      final data = response.data;
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      
      if (text == null || text.isEmpty) {
        throw Exception('Failed to generate flashcards');
      }

      // Clean JSON (remove markdown code blocks if present)
      String cleanedText = text.trim();
      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.replaceFirst(RegExp(r'^```\w*\n'), '');
        cleanedText = cleanedText.replaceFirst(RegExp(r'\n```$'), '');
      }
      cleanedText = cleanedText.trim();

      final jsonData = json.decode(cleanedText) as List;
      final flashcards = jsonData
          .map((item) => Flashcard(
                question: item['question'] as String,
                answer: item['answer'] as String,
              ))
          .toList();

      final tokensUsed = _estimateTokens(data);

      await _logUsage(
        operationType: 'flashcard_generation',
        tokensUsed: tokensUsed,
        success: true,
      );

      return flashcards;
    } catch (e) {
      await _logUsage(
        operationType: 'flashcard_generation',
        tokensUsed: 0,
        success: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Estimate tokens used (rough approximation)
  int _estimateTokens(Map<String, dynamic> response) {
    // Rough estimate: 1 token ≈ 4 characters
    final text = response.toString();
    return (text.length / 4).round();
  }

  /// Log API usage
  Future<void> _logUsage({
    required String operationType,
    required int tokensUsed,
    required bool success,
    String? errorMessage,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // Calculate estimated cost (approximate Gemini pricing)
    final double costEstimate = (tokensUsed * 0.00025 / 1000); // Rough estimate

    try {
      await _client.from('api_usage_log').insert({
        'user_id': userId,
        'api_provider': 'gemini',
        'operation_type': operationType,
        'tokens_used': tokensUsed,
        'cost_estimate': costEstimate,
        'success': success,
        'error_message': errorMessage,
      });

      // Increment API calls counter in quota
      if (success) {
        await _client.rpc('increment_api_calls', params: {'user_id': userId});
      }
    } catch (_) {
      // Fail silently for logging
    }
  }
}

/// Handwriting recognition result
class HandwritingResult {
  final String text;
  final int tokensUsed;
  final Duration processingTime;

  HandwritingResult({
    required this.text,
    required this.tokensUsed,
    required this.processingTime,
  });
}

/// Summary generation result
class SummaryResult {
  final String summary;
  final int tokensUsed;
  final Duration processingTime;

  SummaryResult({
    required this.summary,
    required this.tokensUsed,
    required this.processingTime,
  });
}

/// Flashcard model
class Flashcard {
  final String question;
  final String answer;

  Flashcard({required this.question, required this.answer});

  Map<String, dynamic> toJson() => {
        'question': question,
        'answer': answer,
      };

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
        question: json['question'] as String,
        answer: json['answer'] as String,
      );
}

/// Exception for quota exceeded
class QuotaExceededException implements Exception {
  final String message;
  QuotaExceededException(this.message);
  @override
  String toString() => message;
}

