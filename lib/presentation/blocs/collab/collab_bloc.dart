import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/services/collaboration_service.dart';

// Events
abstract class CollabEvent extends Equatable {
  const CollabEvent();
  @override
  List<Object?> get props => [];
}

class LoadCollaborators extends CollabEvent {
  final String noteId;
  const LoadCollaborators(this.noteId);
  @override
  List<Object?> get props => [noteId];
}

class InviteUser extends CollabEvent {
  final String noteId;
  final String userEmail;
  final String role;
  const InviteUser({
    required this.noteId,
    required this.userEmail,
    required this.role,
  });
  @override
  List<Object?> get props => [noteId, userEmail, role];
}

class UpdateRole extends CollabEvent {
  final String collaborationId;
  final String role;
  const UpdateRole({
    required this.collaborationId,
    required this.role,
  });
  @override
  List<Object?> get props => [collaborationId, role];
}

class RemoveCollaborator extends CollabEvent {
  final String collaborationId;
  const RemoveCollaborator(this.collaborationId);
  @override
  List<Object?> get props => [collaborationId];
}

// States
abstract class CollabState extends Equatable {
  const CollabState();
  @override
  List<Object?> get props => [];
}

class CollabInitial extends CollabState {
  const CollabInitial();
}

class CollabLoading extends CollabState {
  const CollabLoading();
}

class CollabLoaded extends CollabState {
  final List<Map<String, dynamic>> collaborators;
  const CollabLoaded(this.collaborators);
  @override
  List<Object?> get props => [collaborators];
}

class CollabError extends CollabState {
  final String message;
  const CollabError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class CollabBloc extends Bloc<CollabEvent, CollabState> {
  final CollaborationService _collabService;

  CollabBloc({CollaborationService? collabService})
      : _collabService = collabService ?? CollaborationService(),
        super(const CollabInitial()) {
    on<LoadCollaborators>(_onLoadCollaborators);
    on<InviteUser>(_onInviteUser);
    on<UpdateRole>(_onUpdateRole);
    on<RemoveCollaborator>(_onRemoveCollaborator);
  }

  Future<void> _onLoadCollaborators(
    LoadCollaborators event,
    Emitter<CollabState> emit,
  ) async {
    emit(const CollabLoading());
    try {
      final collaborators = await _collabService.getCollaborators(event.noteId);
      emit(CollabLoaded(collaborators));
    } catch (e) {
      emit(CollabError(e.toString()));
    }
  }

  Future<void> _onInviteUser(
    InviteUser event,
    Emitter<CollabState> emit,
  ) async {
    try {
      await _collabService.inviteCollaborator(
        noteId: event.noteId,
        userEmail: event.userEmail,
        role: event.role,
      );
      // Reload collaborators
      add(LoadCollaborators(event.noteId));
    } catch (e) {
      emit(CollabError(e.toString()));
    }
  }

  Future<void> _onUpdateRole(
    UpdateRole event,
    Emitter<CollabState> emit,
  ) async {
    try {
      await _collabService.updateCollaboratorRole(
        collaborationId: event.collaborationId,
        role: event.role,
      );
      // Reload if we have a noteId context
      if (state is CollabLoaded) {
        final currentState = state as CollabLoaded;
        // Find noteId from current collaborators
        if (currentState.collaborators.isNotEmpty) {
          final noteId = currentState.collaborators.first['note_id'] as String?;
          if (noteId != null) {
            add(LoadCollaborators(noteId));
          }
        }
      }
    } catch (e) {
      emit(CollabError(e.toString()));
    }
  }

  Future<void> _onRemoveCollaborator(
    RemoveCollaborator event,
    Emitter<CollabState> emit,
  ) async {
    try {
      await _collabService.removeCollaborator(event.collaborationId);
      // Reload if we have collaborators loaded
      if (state is CollabLoaded) {
        final currentState = state as CollabLoaded;
        if (currentState.collaborators.isNotEmpty) {
          final noteId = currentState.collaborators.first['note_id'] as String?;
          if (noteId != null) {
            add(LoadCollaborators(noteId));
          }
        }
      }
    } catch (e) {
      emit(CollabError(e.toString()));
    }
  }
}

