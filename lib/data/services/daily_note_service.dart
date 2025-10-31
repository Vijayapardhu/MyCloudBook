import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import 'notes_service.dart';

/// Service for managing daily note templates and continuity
class DailyNoteService {
  final SupabaseClient _client;
  final NotesService _notesService;

  DailyNoteService({
    SupabaseClient? client,
    NotesService? notesService,
  })  : _client = client ?? Supabase.instance.client,
        _notesService = notesService ?? NotesService();

  /// Get or create a daily note for the specified date
  /// Returns the note and whether it was newly created
  Future<({Note note, bool wasCreated})> getOrCreateDailyNote(
    DateTime date, {
    required String userId,
  }) async {
    final dateStr = _formatDate(date);
    
    // Try to find existing note for this date
    final existing = await _client
        .from('notes')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();

    if (existing != null) {
      return (note: Note.fromJson(existing), wasCreated: false);
    }

    // Create new daily note
    final title = _generateDailyTitle(date);
    final note = await _notesService.createNote(
      userId: userId,
      title: title,
      date: date,
    );

    // Link to previous day's note if it exists
    final previousDate = date.subtract(const Duration(days: 1));
    final previousNote = await _getNoteForDate(previousDate, userId);
    
    if (previousNote != null) {
      // Store reference to previous note in metadata
      await _notesService.updateNoteMetadata(
        note.id,
        {
          'previous_note_id': previousNote.id,
          'is_daily_note': true,
          'day_of_year': date.difference(DateTime(date.year, 1, 1)).inDays + 1,
        },
      );
    } else {
      // First note or gap in dates
      await _notesService.updateNoteMetadata(
        note.id,
        {
          'is_daily_note': true,
          'day_of_year': date.difference(DateTime(date.year, 1, 1)).inDays + 1,
        },
      );
    }

    return (note: note, wasCreated: true);
  }

  /// Get today's note, creating it if it doesn't exist
  Future<Note> getTodayNote({required String userId}) async {
    final today = DateTime.now();
    final result = await getOrCreateDailyNote(today, userId: userId);
    return result.note;
  }

  /// Get note for a specific date (returns null if not found)
  Future<Note?> _getNoteForDate(DateTime date, String userId) async {
    final dateStr = _formatDate(date);
    final result = await _client
        .from('notes')
        .select()
        .eq('user_id', userId)
        .eq('date', dateStr)
        .order('created_at', ascending: true)
        .limit(1)
        .maybeSingle();
    
    return result != null ? Note.fromJson(result) : null;
  }

  /// Get the previous day's note
  Future<Note?> getPreviousDayNote(String noteId) async {
    final noteResult = await _client
        .from('notes')
        .select()
        .eq('id', noteId)
        .single();
    
    if (noteResult == null) return null;
    
    final note = Note.fromJson(noteResult);
    final previousDate = note.date.subtract(const Duration(days: 1));
    final userId = note.userId;
    
    return await _getNoteForDate(previousDate, userId);
  }

  /// Get the next day's note
  Future<Note?> getNextDayNote(String noteId) async {
    final noteResult = await _client
        .from('notes')
        .select()
        .eq('id', noteId)
        .single();
    
    if (noteResult == null) return null;
    
    final note = Note.fromJson(noteResult);
    final nextDate = note.date.add(const Duration(days: 1));
    final userId = note.userId;
    
    return await _getNoteForDate(nextDate, userId);
  }

  /// Check if a note has a continuation (next day's note exists)
  Future<bool> hasContinuation(String noteId) async {
    final nextNote = await getNextDayNote(noteId);
    return nextNote != null;
  }

  /// Check if a note continues from previous day
  Future<bool> continuesFromPrevious(String noteId) async {
    final previousNote = await getPreviousDayNote(noteId);
    return previousNote != null;
  }

  /// Get all notes for a date range (for timeline view)
  Future<List<Note>> getNotesForDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final startStr = _formatDate(startDate);
    final endStr = _formatDate(endDate);
    
    final response = await _client
        .from('notes')
        .select()
        .eq('user_id', userId)
        .gte('date', startStr)
        .lte('date', endStr)
        .order('date', ascending: false)
        .order('created_at', ascending: false);
    
    final List data = response;
    return data
        .map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Group notes by date
  Map<DateTime, List<Note>> groupNotesByDate(List<Note> notes) {
    final grouped = <DateTime, List<Note>>{};
    
    for (final note in notes) {
      // Normalize date to start of day for grouping
      final dateKey = DateTime(note.date.year, note.date.month, note.date.day);
      grouped.putIfAbsent(dateKey, () => []).add(note);
    }
    
    // Sort notes within each date group
    for (final entry in grouped.entries) {
      entry.value.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    
    return grouped;
  }

  /// Format date as YYYY-MM-DD string
  String _formatDate(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  /// Generate a title for daily note
  String _generateDailyTitle(DateTime date) {
    final weekday = _getWeekdayName(date.weekday);
    final month = _getMonthName(date.month);
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  String _getWeekdayName(int weekday) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
