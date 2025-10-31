import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../blocs/notes/notes_bloc.dart';
import '../blocs/pages/pages_bloc.dart';
import '../blocs/ai/ai_bloc.dart';
import '../blocs/quota/quota_bloc.dart';
import '../widgets/ai_utilities_panel.dart';
import '../widgets/rough_work_attachment_button.dart';
import '../../data/models/page.dart' as models;
import '../../data/services/storage_service.dart';
import '../../core/utils/image_compressor.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.noteId});

  final String? noteId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;
  bool _isSaving = false;
  String? _currentNoteId;
  List<String> _latexBlocks = [];
  String? _selectedPageIdForOCR;
  String? _selectedPageIdForSummary;

  @override
  void initState() {
    super.initState();
    _loadNote();
    _checkQuota();
  }

  Future<void> _loadNote() async {
    if (widget.noteId != null) {
      setState(() => _currentNoteId = widget.noteId);
      
      // Load note details
      try {
        final noteId = widget.noteId!;
        final response = await Supabase.instance.client
            .from('notes')
            .select()
            .eq('id', noteId)
            .single();
        
        _titleController.text = (response['title'] as String?) ?? '';
        final metadata = response['metadata'] as Map<String, dynamic>?;
        if (metadata != null) {
          _contentController.text = (metadata['content'] as String?) ?? '';
          _latexBlocks = List<String>.from((metadata['latex_blocks'] as List?) ?? []);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading note: $e')),
          );
        }
      }

      // Load pages
      context.read<PagesBloc>().add(LoadPages(widget.noteId!));
    }
  }

  void _checkQuota() {
    context.read<QuotaBloc>().add(const RefreshQuota());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _audioPlayer.dispose();
    try {
      _recorder.dispose();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Not authenticated');
      }

      if (_currentNoteId == null) {
        // Create new note
        context.read<NotesBloc>().add(
          CreateNote(
            title: _titleController.text.trim().isEmpty 
                ? null 
                : _titleController.text.trim(),
          ),
        );
        
        // Wait a bit for note creation
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Get the created note ID from the bloc state
        final notesState = context.read<NotesBloc>().state;
        if (notesState is NotesLoaded && notesState.notes.isNotEmpty) {
          _currentNoteId = notesState.notes.first.id;
        }
      } else {
        // Update existing note
        context.read<NotesBloc>().add(
          UpdateNote(
            id: _currentNoteId!,
            updates: {
              'title': _titleController.text.trim(),
              'metadata': {
                'content': _contentController.text,
                'latex_blocks': _latexBlocks,
              },
            },
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note saved')),
        );
        if (_currentNoteId != null) {
          context.go('/note/$_currentNoteId');
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving note: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickAndUploadImage({bool isRoughWork = false}) async {
    if (_currentNoteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please save the note first')),
      );
      return;
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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    
    // Compress image
    final compressed = await ImageCompressor.compressImage(
      imageBytes: bytes,
      maxWidth: 1600,
      maxHeight: 1600,
      quality: 80,
    );

    // Add page via BLoC
    context.read<PagesBloc>().add(
      AddPage(
        noteId: _currentNoteId!,
        imageBytes: compressed,
        isRoughWork: isRoughWork,
      ),
    );
  }

  Future<void> _addLatexBlock() async {
    final controller = TextEditingController();
    final latex = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insert LaTeX'),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: r"e.g. E=mc^2 or \int_0^1 x^2 dx",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (latex != null && latex.isNotEmpty) {
      setState(() => _latexBlocks.add(latex));
    }
  }

  Future<void> _toggleRecord() async {
    if (!_recording) {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );
        setState(() => _recording = true);
      }
    } else {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null) return;
      
      // TODO: Upload audio - implement via PagesBloc if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio recording saved')),
        );
      }
    }
  }

  Future<void> _processOCRForPage(models.Page page) async {
    if (_currentNoteId == null) return;
    
    setState(() => _selectedPageIdForOCR = page.id);
    
    try {
      // Download image bytes from URL
      final storageService = StorageService();
      final imageBytes = await storageService.downloadImageBytes(page.imageUrl);
      
      // Trigger OCR
      context.read<AIBloc>().add(
        RequestOCR(
          pageId: page.id,
          imageBytes: imageBytes,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading image: $e')),
        );
      }
      setState(() => _selectedPageIdForOCR = null);
    }
  }

  void _generateSummaryForPage(models.Page page) {
    if (page.ocrText == null || page.ocrText!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No OCR text available. Process image first.')),
      );
      return;
    }
    
    setState(() => _selectedPageIdForSummary = page.id);
    context.read<AIBloc>().add(
      GenerateSummary(
        text: page.ocrText!,
        maxLength: 200,
      ),
    );
  }

  void _generateFlashcards() {
    final text = _contentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content first')),
      );
      return;
    }
    
    context.read<AIBloc>().add(GenerateFlashcards(content: text));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _currentNoteId != null;
    
    return BlocListener<PagesBloc, PagesState>(
      listener: (context, state) {
        if (state is PagesError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is PageUploaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Page uploaded successfully')),
          );
        }
      },
      child: BlocListener<AIBloc, AIState>(
        listener: (context, state) {
          if (state is AIError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state is OCRSuccess && _selectedPageIdForOCR != null) {
            // Update page with OCR text
            context.read<PagesBloc>().add(
              UpdatePageMeta(
                pageId: _selectedPageIdForOCR!,
                updates: {'ocr_text': state.result.text},
              ),
            );
            setState(() => _selectedPageIdForOCR = null);
          } else if (state is SummarySuccess && _selectedPageIdForSummary != null) {
            // Update page with summary
            context.read<PagesBloc>().add(
              UpdatePageMeta(
                pageId: _selectedPageIdForSummary!,
                updates: {'ai_summary': state.result.summary},
              ),
            );
            setState(() => _selectedPageIdForSummary = null);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(isEditing ? 'Edit Note' : 'New Note'),
            actions: [
              if (isEditing)
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  tooltip: 'AI Features',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => BlocBuilder<PagesBloc, PagesState>(
                        builder: (context, pagesState) {
                          if (pagesState is PagesLoaded && pagesState.pages.isNotEmpty) {
                            final page = pagesState.pages.firstWhere(
                              (p) => p.ocrText != null,
                              orElse: () => pagesState.pages.first,
                            );
                            return AIUtilitiesPanel(
                              ocrText: page.ocrText,
                              aiSummary: page.aiSummary,
                              flashcards: null,
                            );
                          }
                          return const AIUtilitiesPanel();
                        },
                      ),
                    );
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Note title',
                        border: OutlineInputBorder(),
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: 'Start writing... (Markdown supported)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                        expands: true,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                    if (_latexBlocks.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('LaTeX blocks', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              for (final l in _latexBlocks)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Math.tex(l, textStyle: const TextStyle(fontSize: 16)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isEditing) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Pages', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      BlocBuilder<PagesBloc, PagesState>(
                        builder: (context, state) {
                          if (state is PagesLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (state is PageUploading) {
                            return LinearProgressIndicator(value: state.progress);
                          }
                          
                          if (state is PagesLoaded) {
                            final mainPages = state.pages.where((p) => !p.isRoughWork).toList();
                            final roughWorkPages = state.pages.where((p) => p.isRoughWork).toList();
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (state.pages.isEmpty)
                                  const Text('No pages yet. Add images below.')
                                else ...[
                                  // Main pages
                                  if (mainPages.isNotEmpty) ...[
                                    const Text('Main Pages', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 150,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: mainPages.length,
                                        itemBuilder: (context, index) {
                                          final page = mainPages[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 12),
                                            child: _PageThumbnail(
                                              page: page,
                                              onOCR: () => _processOCRForPage(page),
                                              onSummary: () => _generateSummaryForPage(page),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  // Rough work section
                                  if (roughWorkPages.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    const Text('Rough Work', style: TextStyle(fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 150,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: roughWorkPages.length,
                                        itemBuilder: (context, index) {
                                          final page = roughWorkPages[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(right: 12),
                                            child: _PageThumbnail(
                                              page: page,
                                              onOCR: () => _processOCRForPage(page),
                                              onSummary: () => _generateSummaryForPage(page),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  // Rough work attachment button
                                  RoughWorkAttachmentButton(
                                    existingRoughWorkCount: roughWorkPages.length,
                                    onPressed: () => _pickAndUploadImage(isRoughWork: true),
                                  ),
                                ],
                              ],
                            );
                          }
                          
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _pickAndUploadImage,
                    icon: const Icon(Icons.image),
                    tooltip: 'Add image',
                  ),
                  IconButton(
                    onPressed: _addLatexBlock,
                    icon: const Icon(Icons.functions),
                    tooltip: 'Insert LaTeX',
                  ),
                  IconButton(
                    onPressed: _toggleRecord,
                    icon: Icon(_recording ? Icons.stop : Icons.mic),
                    tooltip: _recording ? 'Stop recording' : 'Record audio',
                    color: _recording ? Colors.red : null,
                  ),
                  if (isEditing)
                    IconButton(
                      onPressed: _generateFlashcards,
                      icon: const Icon(Icons.auto_awesome),
                      tooltip: 'Generate flashcards',
                    ),
                  const Spacer(),
                  BlocBuilder<NotesBloc, NotesState>(
                    builder: (context, notesState) {
                      final isLoading = notesState is NotesLoading || _isSaving;
                      return FilledButton.icon(
                        onPressed: isLoading ? null : _saveNote,
                        icon: isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Save'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageThumbnail extends StatelessWidget {
  final models.Page page;
  final VoidCallback onOCR;
  final VoidCallback onSummary;

  const _PageThumbnail({
    required this.page,
    required this.onOCR,
    required this.onSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: page.imageUrl,
              width: 120,
              height: 150,
              fit: BoxFit.cover,
              placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
              errorWidget: (_, __, ___) => const Icon(Icons.error),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.text_fields, size: 16, color: Colors.white),
                    tooltip: 'OCR',
                    onPressed: onOCR,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.summarize, size: 16, color: Colors.white),
                    tooltip: 'Summary',
                    onPressed: page.ocrText != null ? onSummary : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          if (page.isRoughWork)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Rough',
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
