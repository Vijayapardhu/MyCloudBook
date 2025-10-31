import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/notes_service.dart';
import '../../../data/models/note.dart';
import '../../../data/services/sync_service.dart';

// Events
abstract class NotesEvent extends Equatable {
  const NotesEvent();
  @override
  List<Object?> get props => [];
}

class LoadNotes extends NotesEvent {
  final int page;
  const LoadNotes({this.page = 0});
  @override
  List<Object?> get props => [page];
}

class CreateNote extends NotesEvent {
  final String? title;
  final DateTime? date;
  const CreateNote({this.title, this.date});
}

class UpdateNote extends NotesEvent {
  final String id;
  final Map<String, dynamic> updates;
  const UpdateNote({required this.id, required this.updates});
  @override
  List<Object?> get props => [id, updates];
}

class DeleteNote extends NotesEvent {
  final String id;
  const DeleteNote(this.id);
  @override
  List<Object?> get props => [id];
}

// States
abstract class NotesState extends Equatable {
  const NotesState();
  @override
  List<Object?> get props => [];
}

class NotesInitial extends NotesState {
  const NotesInitial();
}

class NotesLoading extends NotesState {
  const NotesLoading();
}

class NotesLoaded extends NotesState {
  final List<Note> notes;
  final bool hasMore;
  const NotesLoaded(this.notes, {this.hasMore = true});
  @override
  List<Object?> get props => [notes, hasMore];
}

class NotesError extends NotesState {
  final String message;
  const NotesError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NotesService _notesService;
  final SyncService _syncService;
  final List<Note> _allNotes = [];

  NotesBloc({
    NotesService? notesService,
    SyncService? syncService,
  })  : _notesService = notesService ?? NotesService(),
        _syncService = syncService ?? SyncService(),
        super(const NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<CreateNote>(_onCreateNote);
    on<UpdateNote>(_onUpdateNote);
    on<DeleteNote>(_onDeleteNote);
  }

  Future<void> _onLoadNotes(LoadNotes event, Emitter<NotesState> emit) async {
    try {
      if (event.page == 0) {
        emit(const NotesLoading());
        _allNotes.clear();
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        emit(const NotesError('Not authenticated'));
        return;
      }

      final notes = await _notesService.fetchNotes(
        offset: event.page * 20,
        limit: 20,
      );

      if (event.page == 0) {
        _allNotes.clear();
      }
      _allNotes.addAll(notes);

      emit(NotesLoaded(
        List.from(_allNotes),
        hasMore: notes.length == 20,
      ));
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onCreateNote(CreateNote event, Emitter<NotesState> emit) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        emit(const NotesError('Not authenticated'));
        return;
      }

      final note = await _notesService.createNote(
        userId: userId,
        title: event.title,
        date: event.date,
      );

      _allNotes.insert(0, note);
      emit(NotesLoaded(List.from(_allNotes), hasMore: state is NotesLoaded ? (state as NotesLoaded).hasMore : true));
    } catch (e) {
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onUpdateNote(UpdateNote event, Emitter<NotesState> emit) async {
    try {
      await _notesService.updateNoteMetadata(event.id, event.updates);

      final index = _allNotes.indexWhere((n) => n.id == event.id);
      if (index != -1) {
        _allNotes[index] = _allNotes[index].copyWith(
          title: event.updates['title'] as String?,
          metadata: event.updates['metadata'] as Map<String, dynamic>?,
        );
      }

      emit(NotesLoaded(List.from(_allNotes), hasMore: state is NotesLoaded ? (state as NotesLoaded).hasMore : true));
    } catch (e) {
      // If online update fails, enqueue for sync
      await _syncService.enqueue(
        entity: SyncEntity.note,
        operation: SyncOperation.update,
        payload: {'id': event.id, 'data': event.updates},
      );
      emit(NotesError(e.toString()));
    }
  }

  Future<void> _onDeleteNote(DeleteNote event, Emitter<NotesState> emit) async {
    try {
      await _notesService.deleteNote(event.id);
      _allNotes.removeWhere((n) => n.id == event.id);
      emit(NotesLoaded(List.from(_allNotes), hasMore: state is NotesLoaded ? (state as NotesLoaded).hasMore : true));
    } catch (e) {
      // If online delete fails, enqueue for sync
      await _syncService.enqueue(
        entity: SyncEntity.note,
        operation: SyncOperation.delete,
        payload: {'id': event.id},
      );
      emit(NotesError(e.toString()));
    }
  }
}
