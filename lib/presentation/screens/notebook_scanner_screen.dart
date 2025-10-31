import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../blocs/pages/pages_bloc.dart';
import '../blocs/ai/ai_bloc.dart';
import '../blocs/quota/quota_bloc.dart';
import '../blocs/notes/notes_bloc.dart';
import '../widgets/main_scaffold.dart';
import '../../data/services/storage_service.dart';
import '../../data/services/export_service.dart';
import '../../data/models/page.dart' as models;
import '../../core/utils/image_compressor.dart';

class NotebookScannerScreen extends StatefulWidget {
  const NotebookScannerScreen({super.key});

  @override
  State<NotebookScannerScreen> createState() => _NotebookScannerScreenState();
}

class _NotebookScannerScreenState extends State<NotebookScannerScreen> {
  String? _selectedNoteId;
  List<models.Page> _notebookPages = [];
  final Map<String, TextEditingController> _pageControllers = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _createDailyNotebookNote();
  }

  @override
  void dispose() {
    for (var controller in _pageControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _createDailyNotebookNote() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        context.go('/login');
        return;
      }

      // Check if today's notebook already exists
      final today = DateTime.now().toIso8601String().split('T')[0];
      final existing = await Supabase.instance.client
          .from('notes')
          .select('id, title')
          .eq('user_id', userId)
          .eq('date', today)
          .like('title', '%Daily Notebook%')
          .maybeSingle();

      if (existing != null) {
        setState(() => _selectedNoteId = existing['id'] as String);
        await _loadPages();
        return;
      }

      // Create new daily notebook note
      context.read<NotesBloc>().add(
        CreateNote(
          title: 'Daily Notebook - ${_formatDate(DateTime.now())}',
          date: DateTime.now(),
        ),
      );

      // Wait for note creation
      await Future.delayed(const Duration(milliseconds: 500));
      final notesState = context.read<NotesBloc>().state;
      if (notesState is NotesLoaded && notesState.notes.isNotEmpty) {
        _selectedNoteId = notesState.notes.first.id;
        await _loadPages();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadPages() async {
    if (_selectedNoteId == null) return;

    setState(() => _loading = true);
    context.read<PagesBloc>().add(LoadPages(_selectedNoteId!));
    
    // Listen to pages state
    final pagesState = context.read<PagesBloc>().state;
    if (pagesState is PagesLoaded) {
      setState(() {
        _notebookPages = pagesState.pages;
        // Initialize controllers for each page
        for (var page in _notebookPages) {
          if (!_pageControllers.containsKey(page.id)) {
            _pageControllers[page.id] = TextEditingController(
              text: page.ocrText ?? '',
            );
          }
        }
        _loading = false;
      });
    }
  }

  Future<void> _scanPage() async {
    if (_selectedNoteId == null) {
      await _createDailyNotebookNote();
      if (_selectedNoteId == null) return;
    }

    // Check quota
    final quotaState = context.read<QuotaBloc>().state;
    if (quotaState is QuotaExceeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monthly quota exceeded. Please upgrade to premium.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final compressed = await ImageCompressor.compressImage(
      imageBytes: bytes,
      maxWidth: 1600,
      maxHeight: 1600,
      quality: 80,
    );

    // Add as rough work page
    context.read<PagesBloc>().add(
      AddPage(
        noteId: _selectedNoteId!,
        imageBytes: compressed,
        isRoughWork: true,
      ),
    );

    // Reload pages after upload
    Future.delayed(const Duration(seconds: 2), () => _loadPages());
  }

  Future<void> _processOCR(models.Page page) async {
    try {
      final storageService = StorageService();
      final imageBytes = await storageService.downloadImageBytes(page.imageUrl);
      
      context.read<AIBloc>().add(
        RequestOCR(
          pageId: page.id,
          imageBytes: imageBytes,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing OCR: $e')),
        );
      }
    }
  }

  void _updatePageText(models.Page page, String text) {
    context.read<PagesBloc>().add(
      UpdatePageMeta(
        pageId: page.id,
        updates: {'ocr_text': text},
      ),
    );
  }

  Future<void> _exportAsPDF() async {
    if (_notebookPages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pages to export')),
      );
      return;
    }

    try {
      setState(() => _loading = true);
      
      final exportService = ExportService();
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      
      // Create a temporary note ID list or use the selected note
      final noteIds = _selectedNoteId != null ? [_selectedNoteId!] : [];
      
      if (noteIds.isEmpty) {
        throw Exception('No note selected');
      }

      final pdfBytes = await exportService.exportNotesToPDF(
        noteIds: noteIds,
        isDarkMode: isDarkMode,
      );

      await exportService.sharePDF(
        pdfBytes,
        'notebook_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PagesBloc, PagesState>(
      listener: (context, state) {
        if (state is PagesLoaded) {
          setState(() {
            _notebookPages = state.pages;
            for (var page in _notebookPages) {
              if (!_pageControllers.containsKey(page.id)) {
                _pageControllers[page.id] = TextEditingController(
                  text: page.ocrText ?? '',
                );
              }
            }
          });
        } else if (state is PageUploaded) {
          _loadPages();
        }
      },
      child: BlocListener<AIBloc, AIState>(
        listener: (context, state) {
          if (state is OCRSuccess) {
            // Find the page by ID - we'll use the first page for now
            if (_notebookPages.isNotEmpty) {
              final page = _notebookPages.first;
            if (_pageControllers.containsKey(page.id)) {
              _pageControllers[page.id]!.text = state.result.text;
            }
            _updatePageText(page, state.result.text);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('OCR completed')),
            );
          } else if (state is AIError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('OCR error: ${state.message}')),
            );
          }
        },
        child: MainScaffold(
          title: 'Daily Notebook',
          actions: [
            if (_notebookPages.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: 'Export PDF',
                onPressed: _loading ? null : _exportAsPDF,
              ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _scanPage,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Page'),
          ),
          body: _loading && _notebookPages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _notebookPages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 72,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No pages scanned yet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text('Tap the camera button to scan a page'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notebookPages.length,
                      itemBuilder: (context, index) {
                        final page = _notebookPages[index];
                        final controller = _pageControllers[page.id] ?? TextEditingController();
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Page image
                              Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: page.imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Rough Note',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Editable text area
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Page ${page.pageNumber}',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.text_fields),
                                          tooltip: 'Process OCR',
                                          onPressed: () => _processOCR(page),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline),
                                          tooltip: 'Delete page',
                                          onPressed: () {
                                            context.read<PagesBloc>().add(
                                              DeletePage(page.id),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: controller,
                                      decoration: const InputDecoration(
                                        labelText: 'Edit extracted text',
                                        hintText: 'Text will be extracted via OCR or type manually',
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 8,
                                      onChanged: (text) {
                                        // Auto-save on change (debounced in production)
                                        Future.delayed(
                                          const Duration(seconds: 1),
                                          () => _updatePageText(page, text),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}

