import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../blocs/notes/notes_bloc.dart';
import '../blocs/sync/sync_bloc.dart';
import '../widgets/sync_status_banner.dart';
import '../widgets/main_scaffold.dart';
import '../widgets/date_group_header.dart';
import '../widgets/continuation_arrow.dart';
import '../../data/models/note.dart';
import '../../data/services/daily_note_service.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<NotesBloc>()..add(const LoadNotes(page: 0)),
      child: MainScaffold(
        title: 'My Notes',
        actions: [
          IconButton(
            tooltip: 'Retry sync',
            onPressed: () {
              context.read<SyncBloc>().add(const FlushQueue());
            },
            icon: const Icon(Icons.sync),
          ),
        ],
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddNoteDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('New Note'),
        ),
        body: Column(
          children: [
            const SyncStatusBanner(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onTap: () => context.go('/search'),
                readOnly: true,
              ),
            ),
            Expanded(
              child: BlocBuilder<NotesBloc, NotesState>(
                builder: (context, state) {
                  if (state is NotesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is NotesError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              context.read<NotesBloc>().add(const LoadNotes(page: 0));
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is NotesLoaded) {
                    if (state.notes.isEmpty) {
                      return _EmptyState();
                    }

                    // Group notes by date
                    final dailyNoteService = DailyNoteService();
                    final groupedNotes = dailyNoteService.groupNotesByDate(state.notes);
                    final sortedDates = groupedNotes.keys.toList()..sort((a, b) => b.compareTo(a));

                    return NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (state.hasMore &&
                            !(state is NotesLoading) &&
                            n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                          context.read<NotesBloc>().add(
                            LoadNotes(page: (state.notes.length / 20).floor()),
                          );
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: () async {
                          context.read<NotesBloc>().add(const LoadNotes(page: 0));
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final isGrid = width >= 800;
                            
                            if (!isGrid) {
                              // List view with date grouping
                              final items = <Widget>[];
                              
                              for (var i = 0; i < sortedDates.length; i++) {
                                final date = sortedDates[i];
                                final dateNotes = groupedNotes[date]!;
                                
                                // Check if this date continues from previous
                                final previousDate = i < sortedDates.length - 1
                                    ? sortedDates[i + 1]
                                    : null;
                                final showContinuation = previousDate != null &&
                                    date.difference(previousDate).inDays == 1;
                                
                                // Add date header
                                items.add(
                                  DateGroupHeader(
                                    date: date,
                                    noteCount: dateNotes.length,
                                    showContinuation: showContinuation,
                                  ),
                                );
                                
                                // Add notes for this date
                                for (var j = 0; j < dateNotes.length; j++) {
                                  items.add(
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      child: _NoteTile(note: dateNotes[j]),
                                    ),
                                  );
                                  
                                  // Add continuation arrow between consecutive notes on same day
                                  if (j < dateNotes.length - 1) {
                                    items.add(
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        child: ContinuationArrow(isVisible: true),
                                      ),
                                    );
                                  }
                                }
                              }
                              
                              return ListView.builder(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: items.length,
                                itemBuilder: (context, index) => items[index],
                              );
                            }
                            
                            // Grid view (simpler, no date grouping for now)
                            final crossAxisCount = width >= 1200 ? 3 : 2;
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: state.notes.length,
                              itemBuilder: (_, i) => _NoteCard(note: state.notes[i]),
                            );
                          },
                        ),
                      ),
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Note'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Note title',
              hintText: 'Enter note title...',
            ),
            autofocus: true,
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title = controller.text.trim();
                Navigator.of(context).pop(title.isEmpty ? null : title);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    ).then((title) {
      if (title != null && title.isNotEmpty) {
        context.read<NotesBloc>().add(CreateNote(title: title));
        // Navigate to editor after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          final notesState = context.read<NotesBloc>().state;
          if (notesState is NotesLoaded && notesState.notes.isNotEmpty) {
            context.go('/note/${notesState.notes.first.id}/edit');
          }
        });
      }
    });
  }
}

class _NoteTile extends StatelessWidget {
  final Note note;
  const _NoteTile({required this.note});

  @override
  Widget build(BuildContext context) {
    final title = note.title ?? 'Untitled';
    final updatedAt = (note.updatedAt ?? note.createdAt).toLocal();
    final dateStr = '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';

    return Dismissible(
      key: ValueKey(note.id),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Note?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) {
        context.read<NotesBloc>().add(DeleteNote(note.id));
      },
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => context.go('/note/${note.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.note,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final title = note.title ?? 'Untitled';
    final updatedAt = (note.updatedAt ?? note.createdAt).toLocal();
    final dateStr = '${updatedAt.day}/${updatedAt.month}/${updatedAt.year}';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/note/${note.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.note,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No notes yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start organizing your thoughts by creating your first note',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                // Trigger the add note dialog via the parent
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Note'),
            ),
          ],
        ),
      ),
    );
  }
}
