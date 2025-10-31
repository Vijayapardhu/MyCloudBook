import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/services/collaboration_service.dart';
import '../../../data/services/realtime_service.dart';
import 'dart:async';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();
  @override
  List<Object?> get props => [];
}

class SendMessage extends ChatEvent {
  final String noteId;
  final String message;
  const SendMessage({
    required this.noteId,
    required this.message,
  });
  @override
  List<Object?> get props => [noteId, message];
}

class StreamMessages extends ChatEvent {
  final String noteId;
  const StreamMessages(this.noteId);
  @override
  List<Object?> get props => [noteId];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();
  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<Map<String, dynamic>> messages;
  const ChatLoaded(this.messages);
  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final CollaborationService _collabService;
  final RealtimeService _realtimeService;
  StreamSubscription<List<Map<String, dynamic>>>? _messageSubscription;

  ChatBloc({
    CollaborationService? collabService,
    RealtimeService? realtimeService,
  })  : _collabService = collabService ?? CollaborationService(),
        _realtimeService = realtimeService ?? RealtimeService(),
        super(const ChatInitial()) {
    on<SendMessage>(_onSendMessage);
    on<StreamMessages>(_onStreamMessages);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _collabService.sendChatMessage(
        noteId: event.noteId,
        message: event.message,
      );
      // State will update automatically via stream
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  void _onStreamMessages(
    StreamMessages event,
    Emitter<ChatState> emit,
  ) {
    // Cancel existing subscription
    _messageSubscription?.cancel();

    // Subscribe to new stream
    _messageSubscription = _realtimeService.streamChatMessages(event.noteId).listen(
      (messages) {
        emit(ChatLoaded(messages));
      },
      onError: (error) {
        emit(ChatError(error.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}

