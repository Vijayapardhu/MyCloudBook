import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/services/notes_service.dart';
import '../../data/services/pages_service.dart';
import '../../data/services/storage_service.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.noteId});

  final String? noteId;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _saving = false;
  final NotesService _notesService = NotesService();
  final PagesService _pagesService = PagesService();
  final StorageService _storageService = StorageService();
  final List<String> _latexBlocks = <String>[];
  final List<String> _imageUrls = <String>[];
  final List<Map<String, dynamic>> _pages = <Map<String, dynamic>>[];
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  bool _recording = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _audioPlayer.dispose();
    try { _recorder.dispose(); } catch (_) {}
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        if (widget.noteId == null) {
          final created = await _notesService.createNote(userId: userId, title: _titleController.text.trim());
          // persist latex blocks into note metadata
          if (_latexBlocks.isNotEmpty) {
            await _notesService.updateNoteMetadata(created.id, {
              'latex_blocks': _latexBlocks,
            });
          }
        } else {
          if (_latexBlocks.isNotEmpty) {
            await _notesService.updateNoteMetadata(widget.noteId!, {
              'latex_blocks': _latexBlocks,
            });
          }
        }
      }
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _saving = false);
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _addImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    await _uploadImage(bytes, picked.name);
  }

  Future<void> _uploadImage(Uint8List bytes, String name) async {
    final noteId = widget.noteId;
    if (noteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save note first before adding images.')));
      return;
    }
    final pageNumber = (await _pagesService.countPages(noteId)) + 1;
    final path = '$noteId/page_$pageNumber-$name';
    final (url, storagePath) = await _storageService.uploadBytes(
      bytes: bytes,
      bucket: 'pages',
      path: path,
      contentType: 'image/jpeg',
    );
    try {
      await _pagesService.createPage(
        noteId: noteId,
        pageNumber: pageNumber,
        imageUrl: url,
        storagePath: storagePath,
      );
    } catch (_) {
      // If offline, just add to UI; optional: enqueue to sync queue for pages insert
    }
    setState(() => _imageUrls.add(url));
    await _reloadPages();
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
          decoration: const InputDecoration(hintText: r"e.g. E=mc^2 or \\int_0^1 x^2 dx"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (latex == null || latex.isEmpty) return;
    setState(() => _latexBlocks.add(latex));
  }

  Future<void> _toggleRecord() async {
    if (!_recording) {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100), path: filePath);
        setState(() => _recording = true);
      }
    } else {
      final path = await _recorder.stop();
      setState(() => _recording = false);
      if (path == null) return;
      final bytes = await XFile(path).readAsBytes();
      await _uploadAudio(bytes, 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
    }
  }

  Future<void> _uploadAudio(Uint8List bytes, String name) async {
    final noteId = widget.noteId;
    if (noteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Save note first before adding audio.')));
      return;
    }
    final pageNumber = (await _pagesService.countPages(noteId)) + 1;
    final path = '$noteId/audio_$pageNumber-$name';
    final (url, storagePath) = await _storageService.uploadAudio(bytes: bytes, path: path);
    try {
      await _pagesService.createPage(
        noteId: noteId,
        pageNumber: pageNumber,
        imageUrl: url,
        storagePath: storagePath,
        tags: const ['audio'],
      );
    } catch (_) {
      // Optional: enqueue for sync
    }
    await _reloadPages();
  }

  Future<void> _reloadPages() async {
    final noteId = widget.noteId;
    if (noteId == null) return;
    final list = await _pagesService.listByNote(noteId);
    if (!mounted) return;
    setState(() {
      _pages
        ..clear()
        ..addAll(list);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteId != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'New Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: 'Start writing... (Markdown supported)',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Attachments', style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 112,
              child: FutureBuilder(
                future: widget.noteId != null && _pages.isEmpty ? _reloadPages() : Future.value(),
                builder: (_, __) {
                  final items = _pages;
                  if (items.isEmpty && _imageUrls.isEmpty && _latexBlocks.isEmpty) {
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('No attachments yet'),
                    );
                  }
                  return ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final p in items)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _attachmentTile(p),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (_latexBlocks.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LaTeX blocks'),
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
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              IconButton(onPressed: _addImage, icon: const Icon(Icons.image), tooltip: 'Add image'),
              IconButton(onPressed: _addLatexBlock, icon: const Icon(Icons.functions), tooltip: 'Insert LaTeX'),
              IconButton(onPressed: _toggleRecord, icon: Icon(_recording ? Icons.stop : Icons.mic), tooltip: 'Record audio'),
              const Spacer(),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachmentTile(Map page) {
    final url = page['image_url'] as String? ?? '';
    final isAudio = url.endsWith('.m4a') || url.endsWith('.aac') || url.contains('/audio_');
    if (isAudio) {
      return Container(
        width: 180,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _audioPlayer.play(UrlSource(url)),
              tooltip: 'Play',
            ),
            const SizedBox(width: 8),
            const Text('Audio clip'),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(url, height: 112, width: 112, fit: BoxFit.cover),
    );
  }
}


