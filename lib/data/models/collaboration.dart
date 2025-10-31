import 'package:equatable/equatable.dart';
import 'user.dart';

/// Collaboration model for note sharing
class Collaboration extends Equatable {
  final String id;
  final String noteId;
  final String userId;
  final CollaborationRole role;
  final DateTime createdAt;
  final User? user; // Joined from profiles

  const Collaboration({
    required this.id,
    required this.noteId,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.user,
  });

  factory Collaboration.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String;
    CollaborationRole role;
    switch (roleStr) {
      case 'owner':
        role = CollaborationRole.owner;
        break;
      case 'editor':
        role = CollaborationRole.editor;
        break;
      case 'commenter':
        role = CollaborationRole.commenter;
        break;
      case 'viewer':
        role = CollaborationRole.viewer;
        break;
      default:
        role = CollaborationRole.viewer;
    }

    User? user;
    if (json['profiles'] != null) {
      final profilesData = json['profiles'];
      if (profilesData is Map<String, dynamic>) {
        user = User.fromJson({
          'id': profilesData['id'] ?? json['user_id'],
          'email': profilesData['email'] ?? '',
          'full_name': profilesData['full_name'],
          'avatar_url': profilesData['avatar_url'],
          'created_at': profilesData['created_at'] ?? DateTime.now().toIso8601String(),
          'updated_at': profilesData['updated_at'],
        });
      }
    }

    return Collaboration(
      id: json['id'] as String,
      noteId: json['note_id'] as String,
      userId: json['user_id'] as String,
      role: role,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: user,
    );
  }

  Map<String, dynamic> toJson() {
    String roleStr;
    switch (role) {
      case CollaborationRole.owner:
        roleStr = 'owner';
        break;
      case CollaborationRole.editor:
        roleStr = 'editor';
        break;
      case CollaborationRole.commenter:
        roleStr = 'commenter';
        break;
      case CollaborationRole.viewer:
        roleStr = 'viewer';
        break;
    }

    return {
      'id': id,
      'note_id': noteId,
      'user_id': userId,
      'role': roleStr,
      'created_at': createdAt.toIso8601String(),
      if (user != null) 'profiles': user!.toJson(),
    };
  }

  bool get canEdit => role == CollaborationRole.owner || role == CollaborationRole.editor;
  bool get canComment => canEdit || role == CollaborationRole.commenter;
  bool get canView => true; // All roles can view

  @override
  List<Object?> get props => [id, noteId, userId, role, createdAt, user];
}

enum CollaborationRole {
  owner,
  editor,
  commenter,
  viewer,
}

