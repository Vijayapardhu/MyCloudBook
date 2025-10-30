import 'package:equatable/equatable.dart';

/// Note model
class Note extends Equatable {
  final String id;
  final String? notebookId;
  final String userId;
  final String? title;
  final DateTime date;
  final int orderIndex;
  final bool hasRoughWork;
  final bool isPasswordProtected;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Note({
    required this.id,
    this.notebookId,
    required this.userId,
    this.title,
    required this.date,
    this.orderIndex = 0,
    this.hasRoughWork = false,
    this.isPasswordProtected = false,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      notebookId: json['notebook_id'] as String?,
      userId: json['user_id'] as String,
      title: json['title'] as String?,
      date: DateTime.parse(json['date'] as String),
      orderIndex: json['order_index'] as int? ?? 0,
      hasRoughWork: json['has_rough_work'] as bool? ?? false,
      isPasswordProtected: json['is_password_protected'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notebook_id': notebookId,
      'user_id': userId,
      'title': title,
      'date': date.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'order_index': orderIndex,
      'has_rough_work': hasRoughWork,
      'is_password_protected': isPasswordProtected,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Note copyWith({
    String? id,
    String? notebookId,
    String? userId,
    String? title,
    DateTime? date,
    int? orderIndex,
    bool? hasRoughWork,
    bool? isPasswordProtected,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      notebookId: notebookId ?? this.notebookId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      date: date ?? this.date,
      orderIndex: orderIndex ?? this.orderIndex,
      hasRoughWork: hasRoughWork ?? this.hasRoughWork,
      isPasswordProtected: isPasswordProtected ?? this.isPasswordProtected,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        notebookId,
        userId,
        title,
        date,
        orderIndex,
        hasRoughWork,
        isPasswordProtected,
        metadata,
        createdAt,
        updatedAt,
      ];
}

