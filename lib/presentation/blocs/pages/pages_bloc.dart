import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/pages_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/quota_service.dart';
import '../../../data/models/page.dart';
import '../../../core/utils/image_compressor.dart';

// Events
abstract class PagesEvent extends Equatable {
  const PagesEvent();
  @override
  List<Object?> get props => [];
}

class AddPage extends PagesEvent {
  final String noteId;
  final Uint8List imageBytes;
  final bool isRoughWork;

  const AddPage({
    required this.noteId,
    required this.imageBytes,
    this.isRoughWork = false,
  });

  @override
  List<Object?> get props => [noteId, imageBytes, isRoughWork];
}

class LoadPages extends PagesEvent {
  final String noteId;
  const LoadPages(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

class UpdatePageMeta extends PagesEvent {
  final String pageId;
  final Map<String, dynamic> updates;

  const UpdatePageMeta({
    required this.pageId,
    required this.updates,
  });

  @override
  List<Object?> get props => [pageId, updates];
}

class DeletePage extends PagesEvent {
  final String pageId;
  const DeletePage(this.pageId);

  @override
  List<Object?> get props => [pageId];
}

// States
abstract class PagesState extends Equatable {
  const PagesState();
  @override
  List<Object?> get props => [];
}

class PagesInitial extends PagesState {
  const PagesInitial();
}

class PagesLoading extends PagesState {
  const PagesLoading();
}

class PagesLoaded extends PagesState {
  final List<Page> pages;
  const PagesLoaded(this.pages);

  @override
  List<Object?> get props => [pages];
}

class PageUploading extends PagesState {
  final double progress;
  const PageUploading(this.progress);

  @override
  List<Object?> get props => [progress];
}

class PageUploaded extends PagesState {
  final Page page;
  const PageUploaded(this.page);

  @override
  List<Object?> get props => [page];
}

class PagesError extends PagesState {
  final String message;
  const PagesError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class PagesBloc extends Bloc<PagesEvent, PagesState> {
  final PagesService _pagesService;
  final StorageService _storageService;
  final QuotaService _quotaService;

  PagesBloc({
    PagesService? pagesService,
    StorageService? storageService,
    QuotaService? quotaService,
  })  : _pagesService = pagesService ?? PagesService(),
        _storageService = storageService ?? StorageService(),
        _quotaService = quotaService ?? QuotaService(),
        super(const PagesInitial()) {
    on<AddPage>(_onAddPage);
    on<LoadPages>(_onLoadPages);
    on<UpdatePageMeta>(_onUpdatePageMeta);
    on<DeletePage>(_onDeletePage);
  }

  Future<void> _onAddPage(
    AddPage event,
    Emitter<PagesState> emit,
  ) async {
    try {
      // Check quota first
      final canUpload = await _quotaService.canUploadPages();
      if (!canUpload) {
        emit(const PagesError(
          'Monthly page quota exceeded. Upgrade to premium for unlimited pages.',
        ));
        return;
      }

      emit(const PageUploading(0.1));

      // Compress image
      final compressed = await ImageCompressor.compressImage(
        imageBytes: event.imageBytes,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      emit(const PageUploading(0.3));

      // Get current page count
      final currentCount = await _pagesService.countPages(event.noteId);
      final nextPageNumber = currentCount + 1;

      // Upload to storage
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      final storagePath = 'images/${currentUser.id}/${event.noteId}/page_$nextPageNumber.webp';
      
      final (publicUrl, path) = await _storageService.uploadBytes(
        bytes: compressed,
        bucket: 'images',
        path: storagePath,
        contentType: 'image/webp',
      );

      emit(const PageUploading(0.7));

      // Create page record
      final pageData = await _pagesService.createPage(
        noteId: event.noteId,
        pageNumber: nextPageNumber,
        imageUrl: publicUrl,
        storagePath: path,
        isRoughWork: event.isRoughWork,
      );

      emit(const PageUploading(1.0));

      final page = Page.fromJson(pageData);
      emit(PageUploaded(page));

      // Reload pages
      add(LoadPages(event.noteId));
    } catch (e) {
      emit(PagesError(e.toString()));
    }
  }

  Future<void> _onLoadPages(
    LoadPages event,
    Emitter<PagesState> emit,
  ) async {
    emit(const PagesLoading());
    try {
      final pagesData = await _pagesService.listByNote(event.noteId);
      final pages = pagesData.map((e) => Page.fromJson(e)).toList();
      emit(PagesLoaded(pages));
    } catch (e) {
      emit(PagesError(e.toString()));
    }
  }

  Future<void> _onUpdatePageMeta(
    UpdatePageMeta event,
    Emitter<PagesState> emit,
  ) async {
    try {
      await _pagesService.updatePage(event.pageId, event.updates);
      // Reload if we have pages loaded
      if (state is PagesLoaded) {
        final currentState = state as PagesLoaded;
        final updatedPages = currentState.pages.map((page) {
          if (page.id == event.pageId) {
            return page.copyWith(
              ocrText: event.updates['ocr_text'] as String?,
              aiSummary: event.updates['ai_summary'] as String?,
              tags: event.updates['tags'] as List<String>?,
            );
          }
          return page;
        }).toList();
        emit(PagesLoaded(updatedPages));
      }
    } catch (e) {
      emit(PagesError(e.toString()));
    }
  }

  Future<void> _onDeletePage(
    DeletePage event,
    Emitter<PagesState> emit,
  ) async {
    try {
      // TODO: Delete from storage as well
      // For now, just delete from DB (trigger will handle quota)
      await _pagesService.updatePage(event.pageId, {'deleted': true});
      
      if (state is PagesLoaded) {
        final currentState = state as PagesLoaded;
        final updatedPages = currentState.pages
            .where((page) => page.id != event.pageId)
            .toList();
        emit(PagesLoaded(updatedPages));
      }
    } catch (e) {
      emit(PagesError(e.toString()));
    }
  }
}

