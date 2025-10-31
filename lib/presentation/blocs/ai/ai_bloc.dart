import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:typed_data';
import '../../../data/services/ai_service.dart';

// Events
abstract class AIEvent extends Equatable {
  const AIEvent();
  @override
  List<Object?> get props => [];
}

class RequestOCR extends AIEvent {
  final String pageId;
  final Uint8List imageBytes;

  const RequestOCR({
    required this.pageId,
    required this.imageBytes,
  });

  @override
  List<Object?> get props => [pageId, imageBytes];
}

class GenerateSummary extends AIEvent {
  final String text;
  final int? maxLength;

  const GenerateSummary({
    required this.text,
    this.maxLength,
  });

  @override
  List<Object?> get props => [text, maxLength];
}

class GenerateFlashcards extends AIEvent {
  final String content;

  const GenerateFlashcards({required this.content});

  @override
  List<Object?> get props => [content];
}

class StoreAPIKey extends AIEvent {
  final String apiKey;

  const StoreAPIKey({required this.apiKey});

  @override
  List<Object?> get props => [apiKey];
}

class CheckAPIKey extends AIEvent {
  const CheckAPIKey();
}

// States
abstract class AIState extends Equatable {
  const AIState();
  @override
  List<Object?> get props => [];
}

class AIInitial extends AIState {
  const AIInitial();
}

class AIInProgress extends AIState {
  final String operation;
  const AIInProgress(this.operation);

  @override
  List<Object?> get props => [operation];
}

class OCRSuccess extends AIState {
  final HandwritingResult result;
  const OCRSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class SummarySuccess extends AIState {
  final SummaryResult result;
  const SummarySuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class FlashcardsSuccess extends AIState {
  final List<Flashcard> flashcards;
  const FlashcardsSuccess(this.flashcards);

  @override
  List<Object?> get props => [flashcards];
}

class APIKeyStored extends AIState {
  const APIKeyStored();
}

class APIKeyChecked extends AIState {
  final bool hasKey;
  const APIKeyChecked(this.hasKey);

  @override
  List<Object?> get props => [hasKey];
}

class AIError extends AIState {
  final String message;
  final bool isQuotaExceeded;

  const AIError(this.message, {this.isQuotaExceeded = false});

  @override
  List<Object?> get props => [message, isQuotaExceeded];
}

// BLoC
class AIBloc extends Bloc<AIEvent, AIState> {
  final AIService _aiService;

  AIBloc({AIService? aiService})
      : _aiService = aiService ?? AIService(),
        super(const AIInitial()) {
    on<RequestOCR>(_onRequestOCR);
    on<GenerateSummary>(_onGenerateSummary);
    on<GenerateFlashcards>(_onGenerateFlashcards);
    on<StoreAPIKey>(_onStoreAPIKey);
    on<CheckAPIKey>(_onCheckAPIKey);
  }

  Future<void> _onRequestOCR(
    RequestOCR event,
    Emitter<AIState> emit,
  ) async {
    emit(const AIInProgress('OCR'));
    try {
      final result = await _aiService.recognizeHandwriting(
        imageBytes: event.imageBytes,
        pageId: event.pageId,
      );
      emit(OCRSuccess(result));
    } on QuotaExceededException catch (e) {
      emit(AIError(e.message, isQuotaExceeded: true));
    } catch (e) {
      emit(AIError(e.toString()));
    }
  }

  Future<void> _onGenerateSummary(
    GenerateSummary event,
    Emitter<AIState> emit,
  ) async {
    emit(const AIInProgress('Summary'));
    try {
      final result = await _aiService.generateSummary(
        text: event.text,
        maxLength: event.maxLength ?? 200,
      );
      emit(SummarySuccess(result));
    } catch (e) {
      emit(AIError(e.toString()));
    }
  }

  Future<void> _onGenerateFlashcards(
    GenerateFlashcards event,
    Emitter<AIState> emit,
  ) async {
    emit(const AIInProgress('Flashcards'));
    try {
      final flashcards = await _aiService.generateFlashcards(event.content);
      emit(FlashcardsSuccess(flashcards));
    } catch (e) {
      emit(AIError(e.toString()));
    }
  }

  Future<void> _onStoreAPIKey(
    StoreAPIKey event,
    Emitter<AIState> emit,
  ) async {
    emit(const AIInProgress('Storing API Key'));
    try {
      await _aiService.storeAPIKey(event.apiKey);
      emit(const APIKeyStored());
    } catch (e) {
      emit(AIError(e.toString()));
    }
  }

  Future<void> _onCheckAPIKey(
    CheckAPIKey event,
    Emitter<AIState> emit,
  ) async {
    try {
      final key = await _aiService.getAPIKey();
      emit(APIKeyChecked(key != null));
    } catch (e) {
      emit(AIError(e.toString()));
    }
  }
}

