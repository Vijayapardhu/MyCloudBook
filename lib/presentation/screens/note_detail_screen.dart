import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/note.dart';
import '../../data/models/page.dart' as models;
import '../blocs/pages/pages_bloc.dart';
import '../../data/services/export_service.dart';
import '../../data/services/pages_service.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, required this.id});

  final String id;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final ExportService _exportService = ExportService();
  final PagesService _pagesService = PagesService();
  Note? _note;
  List<models.Page> _pages = [];
  bool _loading = true;
  bool _showRoughWork = false;
  int _currentPageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    try {
      final noteResponse = await Supabase.instance.client
          .from('notes')
          .select()
          .eq('id', widget.id)
          .single();

      final note = Note.fromJson(noteResponse);
      
      // Load pages via BLoC
      context.read<PagesBloc>().add(LoadPages(widget.id));
      
      final pagesData = await _pagesService.listByNote(widget.id);
      final pages = pagesData.map((e) => models.Page.fromJson(e)).toList();

      if (mounted) {
        setState(() {
          _note = note;
          _pages = pages;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading note: $e')),
        );
      }
    }
  }

  Future<void> _exportPDF() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final pdfBytes = await _exportService.exportNotesToPDF(
        noteIds: [widget.id],
        isDarkMode: isDarkMode,
        includeRoughWork: _showRoughWork,
      );
      
      if (mounted) {
        Navigator.pop(context);
        await _exportService.sharePDF(pdfBytes, 'note_${widget.id.substring(0, 8)}.pdf');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF exported successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_note == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note')),
        body: const Center(child: Text('Note not found')),
      );
    }

    final visiblePages = _showRoughWork
        ? _pages
        : _pages.where((p) => !p.isRoughWork).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _note!.title ?? 'Untitled',
              style: const TextStyle(fontSize: 18),
            ),
            if (visiblePages.isNotEmpty)
              Text(
                'Page ${_currentPageIndex + 1} of ${visiblePages.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
        actions: [
          if (visiblePages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Export PDF',
              onPressed: _exportPDF,
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => context.go('/note/${widget.id}/edit'),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Share'),
                onTap: () => context.push('/collab/${widget.id}'),
              ),
              if (_pages.any((p) => p.isRoughWork))
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Text('Show rough work'),
                      const Spacer(),
                      Switch(
                        value: _showRoughWork,
                        onChanged: (value) {
                          setState(() {
                            _showRoughWork = value;
                            _currentPageIndex = 0;
                          });
                          _pageController.jumpToPage(0);
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: visiblePages.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pages yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add images from the editor',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: visiblePages.length,
              onPageChanged: (index) {
                setState(() => _currentPageIndex = index);
              },
              itemBuilder: (context, index) {
                final page = visiblePages[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rough work badge
                      if (page.isRoughWork)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Colors.orange.shade800,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Rough Work',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (page.isRoughWork) const SizedBox(height: 16),

                      // Page image
                      Card(
                        elevation: 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: page.imageUrl,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => Container(
                              height: 400,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: 400,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.error_outline),
                            ),
                          ),
                        ),
                      ),

                      // Extracted text
                      if (page.ocrText != null && page.ocrText!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.text_fields,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Extracted Text',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            page.ocrText!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],

                      // AI Summary
                      if (page.aiSummary != null && page.aiSummary!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.summarize,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Summary',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            page.aiSummary!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: visiblePages.length > 1
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPageIndex > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                  Text(
                    '${_currentPageIndex + 1} / ${visiblePages.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPageIndex < visiblePages.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
