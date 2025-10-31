import 'package:equatable/equatable.dart';

/// AI Content model for generated flashcards, quizzes, concept maps
class AIContent extends Equatable {
  final String id;
  final String pageId;
  final AIContentType contentType;
  final Map<String, dynamic> content;
  final DateTime createdAt;

  const AIContent({
    required this.id,
    required this.pageId,
    required this.contentType,
    required this.content,
    required this.createdAt,
  });

  factory AIContent.fromJson(Map<String, dynamic> json) {
    final contentTypeStr = json['content_type'] as String;
    AIContentType contentType;
    switch (contentTypeStr) {
      case 'flashcard':
        contentType = AIContentType.flashcard;
        break;
      case 'quiz':
        contentType = AIContentType.quiz;
        break;
      case 'concept_map':
        contentType = AIContentType.conceptMap;
        break;
      case 'summary':
        contentType = AIContentType.summary;
        break;
      default:
        contentType = AIContentType.flashcard;
    }

    return AIContent(
      id: json['id'] as String,
      pageId: json['page_id'] as String,
      contentType: contentType,
      content: json['content'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    String contentTypeStr;
    switch (contentType) {
      case AIContentType.flashcard:
        contentTypeStr = 'flashcard';
        break;
      case AIContentType.quiz:
        contentTypeStr = 'quiz';
        break;
      case AIContentType.conceptMap:
        contentTypeStr = 'concept_map';
        break;
      case AIContentType.summary:
        contentTypeStr = 'summary';
        break;
    }

    return {
      'id': id,
      'page_id': pageId,
      'content_type': contentTypeStr,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, pageId, contentType, content, createdAt];
}

enum AIContentType {
  flashcard,
  quiz,
  conceptMap,
  summary,
}

