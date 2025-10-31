import 'package:equatable/equatable.dart';

/// Page model (individual image in a note)
class Page extends Equatable {
  final String id;
  final String noteId;
  final int pageNumber;
  final bool isRoughWork;
  final String imageUrl;
  final String storagePath;
  final String? ocrText;
  final String? aiSummary;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Page({
    required this.id,
    required this.noteId,
    required this.pageNumber,
    this.isRoughWork = false,
    required this.imageUrl,
    required this.storagePath,
    this.ocrText,
    this.aiSummary,
    this.tags,
    required this.createdAt,
    this.updatedAt,
  });

  factory Page.fromJson(Map<String, dynamic> json) {
    return Page(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      pageNumber: json['page_number'] as int,
      isRoughWork: json['is_rough_work'] as bool? ?? false,
      imageUrl: json['image_url'] as String,
      storagePath: json['storage_path'] as String,
      ocrText: json['ocr_text'] as String?,
      aiSummary: json['ai_summary'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'note_id': noteId,
      'page_number': pageNumber,
      'is_rough_work': isRoughWork,
      'image_url': imageUrl,
      'storage_path': storagePath,
      'ocr_text': ocrText,
      'ai_summary': aiSummary,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Page copyWith({
    String? id,
    String? noteId,
    int? pageNumber,
    bool? isRoughWork,
    String? imageUrl,
    String? storagePath,
    String? ocrText,
    String? aiSummary,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Page(
      id: id ?? this.id,
      noteId: noteId ?? this.noteId,
      pageNumber: pageNumber ?? this.pageNumber,
      isRoughWork: isRoughWork ?? this.isRoughWork,
      imageUrl: imageUrl ?? this.imageUrl,
      storagePath: storagePath ?? this.storagePath,
      ocrText: ocrText ?? this.ocrText,
      aiSummary: aiSummary ?? this.aiSummary,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        noteId,
        pageNumber,
        isRoughWork,
        imageUrl,
        storagePath,
        ocrText,
        aiSummary,
        tags,
        createdAt,
        updatedAt,
      ];
}


