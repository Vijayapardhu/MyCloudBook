import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/note.dart';
import '../../data/services/notes_service.dart';
import '../../data/services/sync_service.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  static const String _notesBoxName = 'notes_box';
  late final Box _notesBox;
  bool _isReady = false;
  final NotesService _notesService = NotesService();
  final SyncService _syncService = SyncService();
  List<Note> _notes = <Note>[];
  bool _online = true;
  bool _loading = true;
  bool _loadingMore = false;
  static const int _pageSize = 20;
  int _offset = 0;
  int _pendingSync = 0;

  @override
  void initState() {
    super.initState();
    _openBox();
    _watchConnectivity();
  }

  Future<void> _openBox() async {
    _notesBox = await Hive.openBox(_notesBoxName);
    await _loadNotes(reset: true);
    await _updatePending();
    if (mounted) {
      setState(() {
        _isReady = true;
        _loading = false;
      });
    }
  }

  void _watchConnectivity() {
    Connectivity().onConnectivityChanged.listen((event) async {
      final online = event != ConnectivityResult.none;
      if (online && !_online) {
        await _syncLocalToRemote();
        await _syncService.flush();
        await _loadNotes();
        await _updatePending();
      }
      if (mounted) setState(() => _online = online);
    });
  }

  Future<void> _loadNotes({bool reset = false}) async {
    try {
      if (Supabase.instance.client.auth.currentSession != null) {
        if (reset) {
          _offset = 0;
          _notes = <Note>[];
        }
        final remote = await _notesService.fetchNotes();
        // naive pagination client-side; replace with range() if needed
        final slice = remote.skip(_offset).take(_pageSize).toList();
        _offset += slice.length;
        _notes = [..._notes, ...slice];
        // cache
        await _notesBox.put('list', remote.map((n) => n.toJson()).toList());
      } else {
        _notes = <Note>[];
      }
    } catch (_) {
      final cached = (_notesBox.get('list') as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
      _notes = cached.map(Note.fromJson).toList();
    }
    if (mounted) setState(() {});
  }

  Future<void> _addNote() async {
    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Note'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Title',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (title == null || title.isEmpty) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // optimistic local append
    final temp = Note(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      date: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      orderIndex: 0,
    );
    _notes = [temp, ..._notes];
    setState(() {});

    try {
      final created = await _notesService.createNote(userId: userId, title: title);
      _notes = [created, ..._notes.where((n) => n.id != temp.id).toList()];
      await _notesBox.put('list', _notes.map((n) => n.toJson()).toList());
    } catch (_) {
      // enqueue for sync
      await _syncService.enqueue(
        entity: SyncEntity.note,
        operation: SyncOperation.insert,
        payload: temp.toJson(),
      );
      await _updatePending();
    }
    if (mounted) setState(() {});
  }

  Future<void> _deleteNote(String id) async {
    // optimistic remove
    final prev = _notes;
    _notes = _notes.where((n) => n.id != id).toList();
    setState(() {});
    try {
      await _notesService.deleteNote(id);
      await _notesBox.put('list', _notes.map((n) => n.toJson()).toList());
    } catch (_) {
      _notes = prev;
      if (mounted) setState(() {});
    }
  }

  Future<void> _syncLocalToRemote() async {
    // Kept for backward compatibility if any legacy items exist
    final pending = (_notesBox.get('pending_inserts') as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || pending.isEmpty) return;
    for (final item in pending) {
      try {
        await _notesService.createNote(userId: userId, title: item['title'] as String?);
      } catch (_) {}
    }
    await _notesBox.delete('pending_inserts');
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final notes = _notes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timeline'),
        actions: [
          IconButton(
            tooltip: 'Retry sync',
            onPressed: () async {
              await _syncService.flush();
              await _loadNotes(reset: true);
              await _updatePending();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync attempt finished')));
            },
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      body: _loading
          ? const _ShimmerList()
          : Column(
              children: [
                if (!_online || _pendingSync > 0)
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(_online ? Icons.sync_problem : Icons.wifi_off, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _online
                                ? 'Pending sync: $_pendingSync item(s)'
                                : 'Offline. Changes will sync when online',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _syncService.flush();
                            await _loadNotes(reset: true);
                            await _updatePending();
                          },
                          child: const Text('Retry'),
                        )
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onTap: () => Navigator.of(context).pushNamed('/search'),
                    readOnly: true,
                  ),
                ),
                Expanded(
                  child: notes.isEmpty
          ? const _EmptyState()
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (!_loadingMore && n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                  _loadingMore = true;
                  _loadNotes().whenComplete(() => setState(() => _loadingMore = false));
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() => _loading = true);
                  await _loadNotes(reset: true);
                  setState(() => _loading = false);
                },
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final isGrid = width >= 800; // simple breakpoint for grid
                    if (!isGrid) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: notes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _noteTile(notes[index]),
                      );
                    }
                    final crossAxisCount = width >= 1200 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 5 / 2,
                      ),
                      itemCount: notes.length,
                      itemBuilder: (_, i) => _noteCard(notes[i]),
                    );
                  },
                ),
              ),
                ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _updatePending() async {
    final size = await _syncService.queueSize();
    if (mounted) setState(() => _pendingSync = size);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No notes yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first note.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  const _ShimmerList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, __) => Container(
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: 8,
    );
  }
}

// Helpers for adaptive list/grid tiles
Widget _noteTile(Note note) {
  return Dismissible(
    key: ValueKey(note.id),
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) async => true,
    child: Builder(builder: (context) {
      final title = note.title ?? 'Untitled';
      final updatedAt = (note.updatedAt ?? note.createdAt).toLocal();
      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        title: Text(title),
        subtitle: Text('Updated: $updatedAt'),
        leading: const Icon(Icons.note_outlined),
        onTap: () {},
      );
    }),
  );
}

Widget _noteCard(Note note) {
  return Builder(builder: (context) {
    final title = note.title ?? 'Untitled';
    final updatedAt = (note.updatedAt ?? note.createdAt).toLocal();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const Spacer(),
            Text('Updated: $updatedAt', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  });
}


