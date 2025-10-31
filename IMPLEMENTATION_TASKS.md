# MyCloudBook - Detailed Implementation Tasks

## Task Breakdown by Priority

### 🔴 CRITICAL: Daily Note Continuation & Templates

#### Task 1.1: Daily Note Service
- [ ] Create `lib/data/services/daily_note_service.dart`
- [ ] Implement `createOrGetDailyNote(DateTime date)` method
- [ ] Auto-link to previous day's note for continuity
- [ ] Handle edge cases (first note, gaps in dates)
- [ ] Add unit tests

#### Task 1.2: Daily Template Auto-Creation
- [ ] Add BLoC event: `CreateDailyNote(DateTime date)`
- [ ] Add BLoC event: `GetDailyNote(DateTime date)`
- [ ] Update NotesBloc to handle daily note creation
- [ ] Add auto-creation on app start if today's note doesn't exist

#### Task 1.3: Timeline Date Grouping
- [ ] Update TimelineScreen to group notes by date
- [ ] Add date header widgets with visual separators
- [ ] Implement date-based pagination
- [ ] Add "Today", "Yesterday", date format labels

#### Task 1.4: Continuation Indicators
- [ ] Create `ContinuationArrow` widget
- [ ] Add logic to detect consecutive dates
- [ ] Display arrows between consecutive notes
- [ ] Add smooth animations

**Files to Create/Modify**:
- `lib/data/services/daily_note_service.dart` (NEW)
- `lib/presentation/blocs/notes/notes_bloc.dart` (MODIFY)
- `lib/presentation/screens/timeline_screen.dart` (MODIFY)
- `lib/presentation/widgets/continuation_arrow.dart` (NEW)
- `lib/presentation/widgets/date_group_header.dart` (NEW)

---

### 🔴 CRITICAL: Rough Work Pages - Full Integration

#### Task 2.1: Rough Work Attachment Flow
- [ ] Create `RoughWorkAttachmentWidget` for note editor
- [ ] Add "Attach Rough Work" button in NoteEditorScreen
- [ ] Implement image picker for rough work pages
- [ ] Store rough work pages with `is_rough_work = true` flag
- [ ] Update PagesService to handle rough work pages

#### Task 2.2: Rough Work Toggle UI
- [ ] Create `RoughWorkToggle` widget
- [ ] Add toggle switch to NoteDetailScreen
- [ ] Implement show/hide logic for rough work pages
- [ ] Add visual distinction (different border/background)
- [ ] Update note model's `hasRoughWork` flag when rough work added

#### Task 2.3: Rough Work Display
- [ ] Update NoteDetailScreen to display rough work separately
- [ ] Add "Rough Work" section header
- [ ] Implement collapsible section for rough work
- [ ] Add visual separator between main and rough work

**Files to Create/Modify**:
- `lib/presentation/widgets/rough_work_toggle.dart` (NEW)
- `lib/presentation/widgets/rough_work_attachment.dart` (NEW)
- `lib/presentation/screens/note_editor_screen.dart` (MODIFY)
- `lib/presentation/screens/note_detail_screen.dart` (MODIFY)
- `lib/data/services/pages_service.dart` (MODIFY)

---

### 🔴 CRITICAL: Handwriting Recognition (OCR)

#### Task 3.1: Complete Gemini Vision Integration
- [ ] Complete `AIService.recognizeHandwriting()` method
- [ ] Implement image preprocessing (resize, enhance)
- [ ] Convert image to base64 for Gemini API
- [ ] Parse Gemini Vision API response
- [ ] Handle API errors (quota exceeded, rate limits)
- [ ] Add retry logic with exponential backoff

#### Task 3.2: OCR Text Storage
- [ ] Update Page model to store OCR text
- [ ] Save OCR results to `pages.ocr_text` column
- [ ] Cache OCR results locally
- [ ] Handle OCR processing status (pending, processing, complete, failed)

#### Task 3.3: OCR Display in UI
- [ ] Add OCR text display in NoteDetailScreen
- [ ] Create "View Text" toggle for OCR text
- [ ] Add copy-to-clipboard functionality
- [ ] Show processing status indicator

#### Task 3.4: OCR Search Indexing
- [ ] Create full-text search index on `pages.ocr_text`
- [ ] Update SearchService to search OCR text
- [ ] Add OCR search filters in SearchScreen
- [ ] Highlight search matches in OCR text

**Files to Create/Modify**:
- `lib/data/services/ai_service.dart` (MODIFY)
- `lib/data/models/page.dart` (MODIFY - add OCR status)
- `lib/presentation/screens/note_detail_screen.dart` (MODIFY)
- `lib/presentation/widgets/ocr_text_viewer.dart` (NEW)
- `lib/data/services/search_service.dart` (MODIFY)
- `supabase/migrations/YYYYMMDD_add_ocr_index.sql` (NEW)

---

### 🔴 CRITICAL: AI Summarization

#### Task 4.1: Complete Summarization Service
- [ ] Complete `AIService.generateSummary()` method
- [ ] Implement prompt engineering for summaries
- [ ] Handle OCR text + note metadata for context
- [ ] Add configurable summary length (short, medium, long)
- [ ] Cache summaries to avoid re-generation

#### Task 4.2: AI Utilities Panel
- [ ] Create `AIUtilitiesPanel` widget
- [ ] Add panel to NoteDetailScreen (slide-out or bottom sheet)
- [ ] Display summary with edit capability
- [ ] Add "Regenerate Summary" button
- [ ] Show processing status

#### Task 4.3: Editable Summary Storage
- [ ] Store summaries in `pages.ai_summary` column
- [ ] Track if summary is AI-generated or user-edited
- [ ] Allow users to edit and save summaries
- [ ] Add "Original" vs "Edited" indicator

**Files to Create/Modify**:
- `lib/data/services/ai_service.dart` (MODIFY)
- `lib/presentation/widgets/ai_utilities_panel.dart` (NEW)
- `lib/presentation/screens/note_detail_screen.dart` (MODIFY)
- `lib/data/models/page.dart` (MODIFY - add summary fields)

---

### 🟡 HIGH: Timeline Enhancements

#### Task 5.1: Drag-Drop Reordering
- [ ] Add `reorderable_list_view` or similar package
- [ ] Implement drag-drop handlers in TimelineScreen
- [ ] Update note `order_index` on reorder
- [ ] Sync order changes to server
- [ ] Add visual feedback during drag

#### Task 5.2: Timeline Visualization Mode
- [ ] Create `TimelineVisualizationView` widget
- [ ] Add timeline mode toggle (list/grid/timeline)
- [ ] Implement vertical timeline with dates
- [ ] Add zoom controls for timeline view
- [ ] Persist view preference

**Files to Create/Modify**:
- `lib/presentation/screens/timeline_screen.dart` (MODIFY)
- `lib/presentation/widgets/timeline_visualization.dart` (NEW)
- `pubspec.yaml` (ADD reorderable_list_view or similar)

---

### 🟡 HIGH: Collaboration Enhancements

#### Task 6.1: Presence Tracking
- [ ] Implement presence channel in RealtimeService
- [ ] Track active users per note
- [ ] Display user avatars in NoteDetailScreen
- [ ] Show "X users viewing" indicator
- [ ] Add user cursors (future enhancement)

#### Task 6.2: Typing Indicators
- [ ] Add typing status to presence tracking
- [ ] Display "User is typing..." in chat
- [ ] Debounce typing events
- [ ] Clear typing indicator after timeout

#### Task 6.3: Real-time Chat UI
- [ ] Complete ChatBloc integration
- [ ] Build chat message list widget
- [ ] Add message input with send button
- [ ] Implement real-time message updates
- [ ] Add message timestamps and user info

**Files to Create/Modify**:
- `lib/data/services/realtime_service.dart` (MODIFY)
- `lib/presentation/blocs/chat/chat_bloc.dart` (MODIFY/COMPLETE)
- `lib/presentation/screens/collaboration_screen.dart` (MODIFY)
- `lib/presentation/widgets/presence_avatars.dart` (NEW)
- `lib/presentation/widgets/chat_message_list.dart` (NEW)

---

### 🟡 HIGH: Flashcard Generation

#### Task 7.1: Flashcard Generation Service
- [ ] Add `AIService.generateFlashcards()` method
- [ ] Design prompt for flashcard generation
- [ ] Parse JSON response into Flashcard models
- [ ] Store flashcards in `ai_content` table
- [ ] Handle generation errors gracefully

#### Task 7.2: Flashcard Models
- [ ] Create `Flashcard` model class
- [ ] Add to `ai_content` table relationship
- [ ] Support question/answer pairs
- [ ] Add difficulty/priority fields

#### Task 7.3: Flashcard Viewer UI
- [ ] Create `FlashcardViewer` widget
- [ ] Implement card flip animation
- [ ] Add "Next" / "Previous" navigation
- [ ] Add "Mark as Known" functionality
- [ ] Integrate into NoteDetailScreen or separate screen

**Files to Create/Modify**:
- `lib/data/services/ai_service.dart` (MODIFY)
- `lib/data/models/flashcard.dart` (NEW)
- `lib/presentation/widgets/flashcard_viewer.dart` (NEW)
- `lib/presentation/screens/flashcard_screen.dart` (NEW - optional)

---

### 🟡 MEDIUM: Advanced Organization

#### Task 8.1: Nested Folders
- [ ] Update Notebook model to support `parent_id`
- [ ] Create migration for nested structure
- [ ] Update NotebookService to handle hierarchy
- [ ] Implement recursive folder loading
- [ ] Add breadcrumb navigation

#### Task 8.2: Color Coding
- [ ] Add `color` field to Notebook model (already exists, verify)
- [ ] Create color picker widget
- [ ] Add color selection in notebook creation/editing
- [ ] Display color indicators in UI
- [ ] Update folder icons with colors

#### Task 8.3: Smart Folders
- [ ] Create `SmartFolder` model
- [ ] Design rule engine for smart folders
- [ ] Implement auto-population based on rules
- [ ] Add smart folder creation UI
- [ ] Update folder list to show smart folders

**Files to Create/Modify**:
- `lib/data/models/notebook.dart` (MODIFY)
- `lib/data/services/notebooks_service.dart` (MODIFY/NEW)
- `lib/presentation/widgets/color_picker.dart` (NEW)
- `supabase/migrations/YYYYMMDD_nested_folders.sql` (NEW)

---

### 🟡 MEDIUM: Auto-Tagging & Linking

#### Task 9.1: Tag System
- [ ] Create `Tag` model
- [ ] Create `tags` table migration
- [ ] Create many-to-many relationship (note_tags table)
- [ ] Add tag input widget (chip-based)
- [ ] Implement tag autocomplete

#### Task 9.2: Auto-Tagging Service
- [ ] Add `AIService.autoTag()` method
- [ ] Design prompt for tag extraction
- [ ] Parse tags from AI response
- [ ] Save tags to database
- [ ] Allow user to edit/remove auto-generated tags

#### Task 9.3: Related Notes Algorithm
- [ ] Create similarity algorithm (tag overlap, OCR similarity)
- [ ] Implement `getRelatedNotes(noteId)` service method
- [ ] Create "Related Notes" widget
- [ ] Add to NoteDetailScreen
- [ ] Cache related notes for performance

**Files to Create/Modify**:
- `lib/data/models/tag.dart` (NEW)
- `lib/data/services/tags_service.dart` (NEW)
- `lib/data/services/ai_service.dart` (MODIFY)
- `lib/presentation/widgets/tag_input.dart` (NEW)
- `lib/presentation/widgets/related_notes.dart` (NEW)
- `supabase/migrations/YYYYMMDD_tags.sql` (NEW)

---

## Database Migrations Needed

1. **OCR Search Index**
   ```sql
   CREATE INDEX idx_pages_ocr_text_search ON pages USING gin(to_tsvector('english', ocr_text));
   ```

2. **Tags System**
   ```sql
   CREATE TABLE tags (...);
   CREATE TABLE note_tags (...);
   ```

3. **Nested Folders** (if not already supported)
   ```sql
   ALTER TABLE notebooks ADD COLUMN parent_id UUID REFERENCES notebooks(id);
   ```

4. **Daily Note Tracking**
   ```sql
   -- Add index on date for faster daily note queries
   CREATE INDEX idx_notes_date ON notes(date);
   ```

---

## Testing Requirements

### Unit Tests Needed
- [ ] DailyNoteService tests
- [ ] AIService OCR tests (with mocks)
- [ ] AIService summarization tests
- [ ] Flashcard generation tests
- [ ] Tag service tests

### Integration Tests Needed
- [ ] Daily note creation flow
- [ ] Rough work attachment flow
- [ ] OCR processing end-to-end
- [ ] Summary generation and editing
- [ ] Flashcard generation and viewing

### Widget Tests Needed
- [ ] TimelineScreen with date grouping
- [ ] RoughWorkToggle widget
- [ ] AIUtilitiesPanel widget
- [ ] FlashcardViewer widget

---

## Dependencies to Add

Check if these are needed and add to `pubspec.yaml`:
- [ ] `reorderable_list_view` or `flutter_reorderable_list` (for drag-drop)
- [ ] `flutter_colorpicker` or similar (for color picking)
- [ ] `flutter_chips_input` or `flutter_tags` (for tag input)

---

## Estimated Effort

- **Daily Note Continuation**: 3-4 days
- **Rough Work Pages**: 2-3 days
- **Handwriting Recognition**: 4-5 days
- **AI Summarization**: 3-4 days
- **Timeline Enhancements**: 2-3 days
- **Collaboration Enhancements**: 4-5 days
- **Flashcards**: 3-4 days
- **Advanced Organization**: 5-6 days
- **Auto-Tagging**: 3-4 days

**Total Critical + High Priority**: ~29-38 days (6-8 weeks)

---

## Quick Wins (Can Implement First)

1. **Rough Work Toggle UI** - Simple widget, quick to implement
2. **Timeline Date Grouping** - Mostly UI changes
3. **OCR Text Display** - Once OCR service is complete, display is straightforward
4. **Color Coding for Notebooks** - Model already has color field, just need UI

---

**Last Updated**: 2024  
**Status**: Ready for Implementation