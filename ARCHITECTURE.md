# MyCloudBook - Technical Architecture Document

## Table of Contents
1. [System Architecture Overview](#1-system-architecture-overview)
2. [Frontend Architecture](#2-frontend-architecture)
3. [Backend Architecture](#3-backend-architecture)
4. [AI Integration Layer](#4-ai-integration-layer)
5. [Security Architecture](#5-security-architecture)
6. [Free Tier & Quota Management](#6-free-tier--quota-management)
7. [API Credit Monitoring](#7-api-credit-monitoring)
8. [Collaboration System](#8-collaboration-system)
9. [Offline-Online Sync](#9-offline-online-sync)
10. [API Design](#10-api-design)
11. [Deployment & Scalability](#11-deployment--scalability)
12. [Technology Stack Details](#12-technology-stack-details)
13. [Development Workflow](#13-development-workflow)
14. [Performance Optimization](#14-performance-optimization)
15. [Security Best Practices](#15-security-best-practices)
16. [Future Enhancements](#16-future-enhancements)
17. [Troubleshooting & Support](#17-troubleshooting--support)

---

## 1. System Architecture Overview

### 1.1 High-Level Architecture

MyCloudBook follows a client-server architecture with offline-first capabilities:

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter Client                           │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────────┐  │
│  │    UI Layer  │  │  State Mgmt  │  │  Local Storage      │  │
│  │              │  │              │  │  (Hive/SQLite)      │  │
│  │  - Screens   │  │  - BLoC/     │  │  - Offline Queue    │  │
│  │  - Widgets   │  │    Provider  │  │  - Cache Manager    │  │
│  └──────────────┘  └──────────────┘  └─────────────────────┘  │
│           │                │                   │                │
│           └────────────────┼───────────────────┘                │
│                            │                                    │
│              ┌─────────────▼──────────────┐                     │
│              │   Service Layer            │                     │
│              │  - API Clients             │                     │
│              │  - Sync Manager            │                     │
│              │  - AI Service              │                     │
│              └─────────────┬──────────────┘                     │
└────────────────────────────┼────────────────────────────────────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
     ┌──────────▼──────┐  ┌─▼──────────┐  ┌──────────────┐
     │   Supabase      │  │  Gemini    │  │   Cloud      │
     │   Backend       │  │  AI API    │  │   Storage    │
     │                 │  │            │  │              │
     │  - PostgreSQL   │  │  - Vision  │  │  - Images    │
     │  - Realtime     │  │  - Text    │  │  - PDFs      │
     │  - Auth         │  │  - Summarize│  │  - Docs      │
     │  - Storage      │  └────────────┘  └──────────────┘
     └─────────────────┘
```

### 1.2 Component Relationships

- **Flutter Client**: Cross-platform UI implementing offline-first patterns
- **Supabase Backend**: PostgreSQL database, real-time subscriptions, authentication, and object storage
- **Gemini AI**: External service for handwriting recognition, summarization, and content generation
- **Local Storage**: Client-side cache for offline functionality and fast access

### 1.3 Data Flow

**Note Upload Flow:**
1. User captures/selects image in Flutter app
2. Image stored locally with optimistic UI update
3. Image uploaded to Supabase Storage
4. Background job extracts metadata, creates database entries
5. User can trigger AI processing with Gemini API
6. AI results cached locally and synced to cloud

**Collaboration Flow:**
1. User changes broadcast via Supabase Realtime channels
2. Presence updates (typing, avatars) sent through dedicated channels
3. Chat messages stored in PostgreSQL, delivered in real-time
4. Permission checks performed via Row Level Security (RLS)

**Offline Sync Flow:**
1. Operations queued locally when offline
2. Sync manager monitors connectivity
3. Batch operations sent on reconnection
4. Conflict resolution UI presented for conflicts

---

## 2. Frontend Architecture

### 2.1 Flutter App Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── constants/                     # App-wide constants
│   ├── theme/                         # Theme configuration
│   ├── utils/                         # Utility functions
│   └── errors/                        # Error handling
├── data/
│   ├── models/                        # Domain models
│   │   ├── note.dart
│   │   ├── page.dart
│   │   ├── user.dart
│   │   └── collaboration.dart
│   ├── repositories/                  # Repository pattern
│   │   ├── note_repository.dart
│   │   ├── user_repository.dart
│   │   └── collaboration_repository.dart
│   ├── datasources/                   # API & local data sources
│   │   ├── local/                     # Hive/SQLite
│   │   └── remote/                    # Supabase clients
│   └── services/                      # External services
│       ├── ai_service.dart            # Gemini integration
│       ├── sync_service.dart
│       └── storage_service.dart
├── presentation/
│   ├── screens/                       # Full page views
│   │   ├── timeline/
│   │   ├── note_viewer/
│   │   ├── collaboration/
│   │   └── settings/
│   ├── widgets/                       # Reusable components
│   │   ├── timeline_widget.dart
│   │   ├── ai_utilities_panel.dart
│   │   └── rough_work_toggle.dart
│   └── providers/                     # State management
│       ├── notes_provider.dart
│       ├── collaboration_provider.dart
│       └── auth_provider.dart
└── config/
    └── app_config.dart                # Environment config
```

### 2.2 State Management Approach

**Recommended: Flutter BLoC Pattern**

```dart
// Example: Notes BLoC
abstract class NotesEvent {}
class LoadNotes extends NotesEvent {}
class AddNote extends NotesEvent { final Note note; }
class UpdateNote extends NotesEvent { final Note note; }
class DeleteNote extends NotesEvent { final String noteId; }

abstract class NotesState {}
class NotesInitial extends NotesState {}
class NotesLoading extends NotesState {}
class NotesLoaded extends NotesState { final List<Note> notes; }
class NotesError extends NotesState { final String message; }

class NotesBloc extends Bloc<NotesEvent, NotesState> {
  final NoteRepository repository;
  
  NotesBloc(this.repository) : super(NotesInitial()) {
    on<LoadNotes>(_onLoadNotes);
    on<AddNote>(_onAddNote);
    // ... other handlers
  }
}
```

**Alternative: Riverpod**
- Lightweight, compile-time safe
- Better for smaller teams
- Excellent for dependency injection

### 2.3 Routing

**Using `go_router` package:**

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const TimelineScreen(),
    ),
    GoRoute(
      path: '/note/:noteId',
      builder: (context, state) => NoteViewerScreen(
        noteId: state.pathParameters['noteId']!,
      ),
    ),
    GoRoute(
      path: '/collaboration/:noteId',
      builder: (context, state) => CollaborationScreen(
        noteId: state.pathParameters['noteId']!,
      ),
    ),
  ],
);
```

### 2.4 Offline-First Architecture

**Local Storage Strategy:**
1. **Primary**: Hive (NoSQL key-value store)
   - Fast, lightweight
   - Good for offline queue, cached data
   
2. **Secondary**: SQLite (via `sqflite`)
   - Complex queries
   - Note history, full-text search

**Offline Queue Implementation:**

```dart
class OfflineQueue {
  final HiveBox queueBox;
  
  Future<void> enqueue(QueuedOperation operation) async {
    await queueBox.add(operation.toJson());
  }
  
  Future<void> processQueue() async {
    if (!await ConnectivityService.isConnected()) return;
    
    final pending = queueBox.values.cast<Map>();
    for (var operation in pending) {
      try {
        await executeOperation(operation);
        await operation.delete();
      } catch (e) {
        // Retry logic or error handling
      }
    }
  }
}
```

---

## 3. Backend Architecture

### 3.1 Supabase Setup Overview

- **Database**: PostgreSQL 15+
- **Realtime**: WebSocket-based subscriptions
- **Auth**: Supabase Auth with social providers
- **Storage**: Object storage for images, PDFs
- **Functions**: Edge Functions (Deno) for background jobs

### 3.2 Database Schema

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  fcm_token TEXT, -- For push notifications
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notebooks/Collections
CREATE TABLE public.notebooks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notes
CREATE TABLE public.notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  notebook_id UUID REFERENCES public.notebooks(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT,
  date DATE NOT NULL,
  order_index INTEGER NOT NULL DEFAULT 0,
  has_rough_work BOOLEAN DEFAULT FALSE,
  is_password_protected BOOLEAN DEFAULT FALSE,
  password_hash TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Pages (individual images)
CREATE TABLE public.pages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID NOT NULL REFERENCES public.notes(id) ON DELETE CASCADE,
  page_number INTEGER NOT NULL,
  is_rough_work BOOLEAN DEFAULT FALSE,
  image_url TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  ocr_text TEXT,
  ai_summary TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(note_id, page_number)
);

-- AI Generated Content
CREATE TABLE public.ai_content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  page_id UUID NOT NULL REFERENCES public.pages(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL CHECK (content_type IN ('flashcard', 'quiz', 'concept_map')),
  content JSONB NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Collaborations
CREATE TABLE public.collaborations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID NOT NULL REFERENCES public.notes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('viewer', 'commenter', 'editor', 'owner')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(note_id, user_id)
);

-- Chat Messages
CREATE TABLE public.chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID NOT NULL REFERENCES public.notes(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Comments (on specific note sections)
CREATE TABLE public.comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID NOT NULL REFERENCES public.notes(id) ON DELETE CASCADE,
  page_id UUID REFERENCES public.pages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  coordinates JSONB, -- For positioning on image
  parent_comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Assignments/Tasks
CREATE TABLE public.assignments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  due_date DATE,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'overdue')),
  associated_note_id UUID REFERENCES public.notes(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activity Log
CREATE TABLE public.activity_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  activity_type TEXT NOT NULL,
  entity_type TEXT, -- 'note', 'page', 'collaboration'
  entity_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Encrypted API Keys
CREATE TABLE public.api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  provider TEXT NOT NULL DEFAULT 'gemini',
  encrypted_key TEXT NOT NULL, -- AES-256 encrypted
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Sync Queue (for conflict resolution tracking)
CREATE TABLE public.sync_operations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  operation_type TEXT NOT NULL,
  local_updated_at TIMESTAMPTZ NOT NULL,
  server_updated_at TIMESTAMPTZ NOT NULL,
  status TEXT DEFAULT 'pending',
  conflict_data JSONB,
  resolved_at TIMESTAMPTZ
);

-- User Quotas (free tier tracking)
CREATE TABLE public.user_quotas (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'premium')),
  pages_uploaded_this_month INTEGER NOT NULL DEFAULT 0,
  storage_used_bytes BIGINT NOT NULL DEFAULT 0,
  api_calls_this_month INTEGER NOT NULL DEFAULT 0,
  quota_reset_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- API Usage Tracking (for credit monitoring)
CREATE TABLE public.api_usage_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  api_provider TEXT NOT NULL DEFAULT 'gemini',
  operation_type TEXT NOT NULL, -- 'handwriting_recognition', 'summarization', 'flashcard', etc.
  tokens_used INTEGER,
  cost_estimate DECIMAL(10,4),
  success BOOLEAN NOT NULL,
  error_message TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);
```

### 3.3 Row Level Security Policies

```sql
-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
-- ... similar for all tables

-- Profiles policies
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Notes policies
CREATE POLICY "Users can view own notes"
  ON public.notes FOR SELECT
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.collaborations
      WHERE note_id = notes.id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own notes"
  ON public.notes FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Owners and editors can update notes"
  ON public.notes FOR UPDATE
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.collaborations
      WHERE note_id = notes.id 
        AND user_id = auth.uid() 
        AND role IN ('owner', 'editor')
    )
  );

CREATE POLICY "Owners can delete notes"
  ON public.notes FOR DELETE
  USING (user_id = auth.uid());

-- Collaborations policies
CREATE POLICY "Users can view collaborations"
  ON public.collaborations FOR SELECT
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE id = collaborations.note_id AND notes.user_id = auth.uid()
    )
  );
```

### 3.4 Real-time Subscriptions Design

```dart
// Example: Real-time note updates
class RealtimeService {
  final supabase = Supabase.instance.client;
  
  RealtimeChannel subscribeToNote(String noteId) {
    return supabase
      .channel('note:$noteId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: noteId,
        ),
        callback: (payload) {
          // Handle note updates
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'note_id',
          value: noteId,
        ),
        callback: (payload) {
          // Handle new chat messages
        },
      )
      .subscribe();
  }
}
```

### 3.5 Storage Buckets

**Bucket Structure:**

```
storage/
├── images/
│   ├── {user_id}/
│   │   ├── {note_id}/
│   │   │   ├── page_{page_number}.jpg
│   │   │   └── rough_work_{page_number}.jpg
├── pdfs/
│   ├── {user_id}/
│   │   ├── {note_id}_exported.pdf
├── voice/
│   ├── {user_id}/
│   │   ├── {note_id}_memo.m4a
```

**Storage Policies:**

```sql
CREATE POLICY "Users can upload own images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'images' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can view own and shared images"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'images' AND (
      (storage.foldername(name))[1] = auth.uid()::text OR
      EXISTS (
        SELECT 1 FROM public.collaborations
        JOIN public.notes ON notes.id = collaborations.note_id
        WHERE notes.user_id = (storage.foldername(name))[1]::uuid
          AND collaborations.user_id = auth.uid()
      )
    )
  );
```

---

## 4. AI Integration Layer

### 4.1 Gemini API Integration Patterns

**Service Architecture:**

```dart
class AIService {
  final http.Client httpClient;
  final EncryptionService encryption;
  final StorageService storage;
  
  Future<HandwritingResult> recognizeHandwriting(String imagePath) async {
    final apiKey = await encryption.getDecryptedAPIKey();
    
    // Convert image to base64
    final imageBytes = await storage.getLocalFile(imagePath);
    final base64Image = base64Encode(imageBytes);
    
    // Call Gemini Vision API
    final response = await httpClient.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro-vision:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [
              {'text': 'Convert this handwritten text to digital text. Maintain formatting and structure.'},
              {
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              }
            ]
          }
        ]
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return HandwritingResult.fromGeminiResponse(data);
    } else {
      throw AIException('Failed to recognize handwriting');
    }
  }
  
  Future<SummaryResult> generateSummary(String text, {int? maxLength}) async {
    final apiKey = await encryption.getDecryptedAPIKey();
    
    final response = await httpClient.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [{
              'text': 'Summarize the following content in a concise format. '
                  'Maximum ${maxLength ?? 200} words. '
                  'Focus on key concepts and main points:\n\n$text'
            }]
          }
        ]
      }),
    );
    
    return SummaryResult.fromGeminiResponse(json.decode(response.body));
  }
  
  Future<List<Flashcard>> generateFlashcards(String content) async {
    final apiKey = await encryption.getDecryptedAPIKey();
    
    final response = await httpClient.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [{
              'text': 'Generate study flashcards from this content. '
                  'Return only a JSON array with format: '
                  '[{"question": "...", "answer": "..."}]'
                  'Create 5-10 flashcards covering key concepts:\n\n$content'
            }]
          }
        ]
      }),
    );
    
    final result = json.decode(response.body);
    return Flashcard.fromGeminiResponse(result);
  }
  
  Future<List<String>> autoTag(String text) async {
    // Similar pattern for auto-tagging
  }
  
  Future<ConceptMap> generateConceptMap(String text) async {
    // Similar pattern for concept maps
  }
}
```

### 4.2 Encrypted API Key Storage

**Encryption Strategy:**

```dart
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  static const _keyString = 'YOUR_APP_ENCRYPTION_KEY'; // Store securely
  late final encrypt.Key _key;
  late final encrypt.IV _iv;
  
  EncryptionService() {
    _key = encrypt.Key.fromBase64(_keyString);
    _iv = encrypt.IV.fromLength(16);
  }
  
  Future<String> encryptAPIKey(String plainKey) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(plainKey, iv: _iv);
    return encrypted.base64;
  }
  
  Future<String> decryptAPIKey(String encryptedKey) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypt.Encrypted.fromBase64(encryptedKey);
    return encrypter.decrypt(encrypted, iv: _iv);
  }
  
  Future<void> storeEncryptedKey(String apiKey) async {
    final encrypted = await encryptAPIKey(apiKey);
    // Store in secure storage (e.g., flutter_secure_storage)
    // Also sync to Supabase
    await Supabase.instance.client
      .from('api_keys')
      .upsert({
        'user_id': getCurrentUserId(),
        'provider': 'gemini',
        'encrypted_key': encrypted,
        'updated_at': DateTime.now().toIso8601String(),
      });
  }
}
```

### 4.3 Handwriting Recognition Pipeline

**Processing Flow:**

1. User uploads image
2. Image pre-processed (resize, enhance contrast)
3. Base64 encoded and sent to Gemini Vision
4. OCR text extracted and cleaned
5. Cached locally and stored in database
6. Used for search, AI summaries, etc.

**Batch Processing:**

```dart
class BatchAIProcessor {
  final Queue<AIJob> pendingJobs = Queue();
  
  Future<void> processJobQueue() async {
    while (pendingJobs.isNotEmpty) {
      final job = pendingJobs.removeFirst();
      try {
        await processSingleJob(job);
      } catch (e) {
        // Retry logic with exponential backoff
        await retryJob(job);
      }
    }
  }
}
```

### 4.4 AI Feature Implementations

**Flashcards Generation:**

- Input: OCR text or user-provided content
- Model: Gemini 1.5 Pro
- Output: JSON array of question-answer pairs
- Caching: Store in `ai_content` table
- Editing: Users can modify generated flashcards

**Quiz Generation:**

- Input: Chapter or topic content
- Output: Multiple-choice questions with options and answers
- Types: MCQ, true/false, fill-in-the-blank
- Assessment: Track scores and mistakes

**Concept Map:**

- Input: Topic content
- Output: Node-link graph visualization
- Storage: Store as JSON in `ai_content` table
- Visualization: Use Flutter packages like `flutter_graphview`

---

## 5. Security Architecture

### 5.1 Authentication Flow

**Email/Password Authentication:**

```dart
class AuthService {
  final supabase = Supabase.instance.client;
  
  Future<AuthResponse> signUp(String email, String password) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'mycloudbook://auth-callback',
    );
    
    // Create profile
    if (response.user != null) {
      await supabase.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
      });
    }
    
    return response;
  }
  
  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
}
```

**Social Login (Google, Apple, GitHub):**

```dart
Future<void> signInWithGoogle() async {
  await supabase.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: 'mycloudbook://auth-callback',
  );
}
```

**Two-Factor Authentication:**

1. User enables 2FA in settings
2. QR code generated using OTP
3. User scans with authenticator app
4. Backup codes stored securely
5. Subsequent logins require 2FA code

### 5.2 Encryption Strategy

**Data at Rest:**
- API keys: AES-256 encryption
- Password-protected notes: Client-side encryption before upload
- Local storage: SQLite encrypted with SQLCipher

**Data in Transit:**
- All API calls via HTTPS/TLS
- WebSocket connections secured (WSS)
- Certificate pinning for mobile apps

### 5.3 Role-Based Access Control

**Permission Matrix:**

| Role | View | Comment | Edit | Share | Delete |
|------|------|---------|------|-------|--------|
| Owner | ✓ | ✓ | ✓ | ✓ | ✓ |
| Editor | ✓ | ✓ | ✓ | ✓ | ✗ |
| Commenter | ✓ | ✓ | ✗ | ✗ | ✗ |
| Viewer | ✓ | ✗ | ✗ | ✗ | ✗ |

**Implementation:**

```dart
class PermissionService {
  bool canEdit(String userId, String noteId, Collaborator? collaborator) {
    if (collaborator == null) return false;
    return collaborator.role == 'owner' || collaborator.role == 'editor';
  }
  
  bool canDelete(String userId, String noteId, Collaborator? collaborator) {
    return collaborator?.role == 'owner';
  }
}
```

### 5.4 Data Privacy Compliance

**GDPR Requirements:**

1. **Right to Access**: Export all user data on request
2. **Right to Deletion**: Cascade delete user data
3. **Data Minimization**: Store only necessary data
4. **Encryption**: Encrypt sensitive data
5. **Consent**: Clear privacy policy and consent

**Implementation:**

```dart
class DataExportService {
  Future<Map<String, dynamic>> exportAllUserData(String userId) async {
    final userData = {
      'profile': await fetchProfile(userId),
      'notes': await fetchAllNotes(userId),
      'collaborations': await fetchCollaborations(userId),
      'assignments': await fetchAssignments(userId),
      'activity': await fetchActivityLog(userId),
    };
    return userData;
  }
  
  Future<void> deleteAllUserData(String userId) async {
    // Cascade delete handled by database foreign keys
    await supabase.auth.admin.deleteUser(userId);
  }
}
```

---

## 6. Free Tier & Quota Management

### 6.1 Tier Model

**Free Tier:**
- 100 pages/month with AI processing
- 5GB storage per user
- User-provided Gemini API keys (no managed API key costs)
- Basic features: note upload, timeline, AI conversion, flashcards, basic collaboration
- Automated quota tracking and enforcement

**Premium Tier (Future):**
- Unlimited pages per month
- 50GB+ storage
- Priority customer support
- Advanced AI features: concept maps, adaptive quizzes, personalized recommendations
- Enhanced collaboration tools
- Ad-free experience

### 6.2 Quota Tracking Architecture

**Database Structure:**
```dart
// Quota model
class UserQuota {
  final String userId;
  final UserTier tier;
  final int pagesUploadedThisMonth;
  final int storageUsedBytes;
  final int apiCallsThisMonth;
  final DateTime quotaResetDate;
  final int maxPagesPerMonth;
  final int maxStorageBytes;
}

enum UserTier { free, premium }

// Free tier limits
class FreeTierLimits {
  static const int maxPagesPerMonth = 100;
  static const int maxStorageBytes = 5 * 1024 * 1024 * 1024; // 5GB
}

// Premium tier (unlimited or configurable)
class PremiumTierLimits {
  static const int? maxPagesPerMonth = null; // Unlimited
  static const int? maxStorageBytes = null; // Or 50GB
}
```

### 6.3 Quota Enforcement

**Client-Side Checks:**
```dart
class QuotaService {
  final SupabaseClient supabase;
  
  Future<bool> canUploadPage(String userId) async {
    final quota = await fetchUserQuota(userId);
    
    // Premium users have no limits
    if (quota.tier == UserTier.premium) return true;
    
    // Check page limit
    if (quota.pagesUploadedThisMonth >= FreeTierLimits.maxPagesPerMonth) {
      return false;
    }
    
    return true;
  }
  
  Future<bool> canStoreData(String userId, int additionalBytes) async {
    final quota = await fetchUserQuota(userId);
    
    if (quota.tier == UserTier.premium) return true;
    
    if (quota.storageUsedBytes + additionalBytes > FreeTierLimits.maxStorageBytes) {
      return false;
    }
    
    return true;
  }
  
  Future<void> incrementPageCount(String userId) async {
    await supabase
      .from('user_quotas')
      .update({
        'pages_uploaded_this_month': supabase.raw('pages_uploaded_this_month + 1'),
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('user_id', userId);
  }
  
  Future<void> incrementStorage(String userId, int bytes) async {
    await supabase
      .from('user_quotas')
      .update({
        'storage_used_bytes': supabase.raw('storage_used_bytes + ?', [bytes]),
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('user_id', userId);
  }
}
```

**Server-Side Enforcement:**
```sql
-- Database trigger to check quotas on insert
CREATE OR REPLACE FUNCTION check_page_quota()
RETURNS TRIGGER AS $$
DECLARE
  user_tier TEXT;
  pages_used INTEGER;
  max_pages INTEGER;
BEGIN
  SELECT tier, pages_uploaded_this_month INTO user_tier, pages_used
  FROM user_quotas
  WHERE user_id = NEW.user_id;
  
  IF user_tier = 'premium' THEN
    RETURN NEW; -- Premium users have no limits
  END IF;
  
  max_pages := 100; -- Free tier limit
  
  IF pages_used >= max_pages THEN
    RAISE EXCEPTION 'Monthly page quota exceeded. Upgrade to premium for unlimited pages.';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_page_quota_trigger
BEFORE INSERT ON pages
FOR EACH ROW
EXECUTE FUNCTION check_page_quota();
```

### 6.4 Monthly Quota Reset

```dart
class QuotaResetService {
  Future<void> resetMonthlyQuotas() async {
    await supabase.rpc('reset_monthly_quotas');
  }
}

// Database function
CREATE OR REPLACE FUNCTION reset_monthly_quotas()
RETURNS void AS $$
BEGIN
  UPDATE user_quotas
  SET 
    pages_uploaded_this_month = 0,
    api_calls_this_month = 0,
    quota_reset_date = (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month')::DATE,
    updated_at = NOW()
  WHERE quota_reset_date <= CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;
```

**Automated Reset:**
- Run daily via Supabase Edge Function or cron job
- Check if `quota_reset_date` <= current date
- Reset counters and update reset date to next month

---

## 7. API Credit Monitoring

### 7.1 Credit Monitoring Architecture

**User-Provided API Keys:**
- Users supply their own Gemini API keys
- Encrypted storage in `api_keys` table
- No cost burden on platform
- Users control their AI spending

**Credit Tracking:**
```dart
class APICreditMonitor {
  final SupabaseClient supabase;
  
  Future<void> logAPIUsage({
    required String userId,
    required String operationType,
    required int tokensUsed,
    required bool success,
    String? errorMessage,
  }) async {
    // Calculate estimated cost (approximate)
    final costEstimate = calculateCostEstimate(tokensUsed, operationType);
    
    await supabase.from('api_usage_log').insert({
      'user_id': userId,
      'api_provider': 'gemini',
      'operation_type': operationType,
      'tokens_used': tokensUsed,
      'cost_estimate': costEstimate,
      'success': success,
      'error_message': errorMessage,
    });
  }
  
  double calculateCostEstimate(int tokens, String operationType) {
    // Approximate Gemini pricing (adjust as needed)
    // $0.00025 per 1K input tokens, $0.0005 per 1K output tokens
    const double inputTokenCost = 0.00025 / 1000;
    const double outputTokenCost = 0.0005 / 1000;
    
    // Rough estimate: assume 50/50 input/output split
    return (tokens * 0.5 * inputTokenCost) + (tokens * 0.5 * outputTokenCost);
  }
  
  Future<Map<String, dynamic>> getUsageStats(String userId) async {
    final last30Days = DateTime.now().subtract(Duration(days: 30));
    
    final response = await supabase
      .from('api_usage_log')
      .select()
      .eq('user_id', userId)
      .gte('timestamp', last30Days.toIso8601String())
      .order('timestamp', ascending: false);
    
    final totalTokens = response.fold<int>(0, (sum, record) => sum + (record['tokens_used'] ?? 0));
    final totalCalls = response.length;
    final successCalls = response.where((r) => r['success'] == true).length;
    final totalCost = response.fold<double>(0.0, (sum, record) => sum + (record['cost_estimate'] ?? 0.0));
    
    return {
      'total_tokens': totalTokens,
      'total_calls': totalCalls,
      'success_calls': successCalls,
      'failure_calls': totalCalls - successCalls,
      'estimated_cost': totalCost,
      'success_rate': totalCalls > 0 ? successCalls / totalCalls : 0.0,
    };
  }
}
```

### 7.2 API Credit Alerts

**Alert Triggers:**
```dart
class APICreditAlert {
  static const double LOW_CREDIT_THRESHOLD = 0.20; // 20%
  static const double CRITICAL_CREDIT_THRESHOLD = 0.10; // 10%
  
  Future<void> checkAPIQuotaStatus(String userId) async {
    // Note: We cannot directly check Gemini API balance
    // Instead, we monitor for API quota exceeded errors
    
    final recentErrors = await fetchRecentAPIErrors(userId);
    
    if (recentErrors.any((error) => error.contains('quota'))) {
      await triggerLowCreditAlert(userId);
    }
  }
  
  Future<void> triggerLowCreditAlert(String userId) async {
    // Send in-app notification
    await showInAppAlert(userId);
    
    // Send email notification (optional)
    await sendEmailAlert(userId);
    
    // Display UI banner
    await updateUIBanner(userId, 'API credit running low');
  }
}
```

**Error Handling:**
```dart
class AIService {
  Future<HandwritingResult> recognizeHandwriting(String imagePath) async {
    try {
      final result = await callGeminiAPI(imagePath);
      
      // Log successful usage
      await apiCreditMonitor.logAPIUsage(
        userId: getCurrentUserId(),
        operationType: 'handwriting_recognition',
        tokensUsed: result.tokensUsed,
        success: true,
      );
      
      return result;
    } catch (e) {
      // Log failed usage
      await apiCreditMonitor.logAPIUsage(
        userId: getCurrentUserId(),
        operationType: 'handwriting_recognition',
        tokensUsed: 0,
        success: false,
        errorMessage: e.toString(),
      );
      
      // Handle quota exceeded error
      if (e.toString().contains('quota')) {
        throw QuotaExceededException(
          'Your Gemini API quota has been exceeded. Please check your API credits or add more credits to your Gemini account.',
        );
      }
      
      rethrow;
    }
  }
}
```

### 7.3 Usage Dashboard UI

**Components:**
```dart
class UsageDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: apiCreditMonitor.streamUsageStats(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final stats = snapshot.data!;
        
        return Column(
          children: [
            // Pages quota
            QuotaProgressBar(
              label: 'Pages Uploaded',
              used: quota.pagesUploadedThisMonth,
              limit: FreeTierLimits.maxPagesPerMonth,
              color: Colors.blue,
            ),
            
            // Storage quota
            QuotaProgressBar(
              label: 'Storage Used',
              used: _bytesToMB(quota.storageUsedBytes),
              limit: _bytesToMB(FreeTierLimits.maxStorageBytes),
              color: Colors.orange,
            ),
            
            // API usage stats
            APICreditCard(
              totalTokens: stats['total_tokens'],
              estimatedCost: stats['estimated_cost'],
              successRate: stats['success_rate'],
            ),
          ],
        );
      },
    );
  }
}
```

---

## 8. Collaboration System

### 8.1 Real-time Editing Architecture

**Supabase Realtime:**

- WebSocket-based bidirectional communication
- Presence tracking for active users
- Changes broadcast to all collaborators
- Optimistic UI updates for responsiveness

**Realtime Channels:**

```
Channel Structure:
- note:{noteId}           # Note updates
- presence:{noteId}       # Active users
- chat:{noteId}          # Chat messages
- comments:{noteId}      # Comments
```

### 8.2 Conflict Resolution Strategy

**Last-Write-Wins (Initial Approach):**

- Timestamp-based conflict resolution
- Server timestamp is authoritative
- Conflicts detected during sync

**Optimistic Locking (Future Enhancement):**

- Include version numbers
- Detect conflicts on write
- User chooses resolution

**Implementation:**

```dart
class ConflictResolver {
  Future<Note> resolveConflict(Note local, Note remote) async {
    // Detect if both were modified
    if (local.updatedAt != remote.updatedAt &&
        local.serverUpdatedAt == remote.serverUpdatedAt) {
      
      // Present UI for user to choose
      return await showConflictResolutionDialog(local, remote);
    }
    
    // Prefer server version
    return remote;
  }
}
```

### 8.3 Presence System

```dart
class PresenceService {
  RealtimeChannel? presenceChannel;
  
  Future<void> joinPresence(String noteId) async {
    presenceChannel = supabase
      .channel('presence:$noteId')
      .onPresenceSync(() {
        // Handle presence sync
      })
      .onPresence({presence: 'sync'}, (payload, [ref]) {
        // Handle presence updates
      })
      .onPresence({event: 'join'}, ({key, currentPresences, newPresences}) {
        // User joined
      })
      .onPresence({event: 'leave'}, ({key, currentPresences, leftPresences}) {
        // User left
      })
      .subscribe(async (status) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await presenceChannel!.track({
            'user': getCurrentUserId(),
            'online_at': DateTime.now().toIso8601String(),
          });
        }
      });
  }
  
  Future<void> updateTypingStatus(String noteId, bool isTyping) async {
    await presenceChannel?.track({
      'user': getCurrentUserId(),
      'typing': isTyping,
    });
  }
}
```

### 8.4 Chat Implementation

**Real-time Chat:**

- Messages stored in PostgreSQL
- Delivery via Supabase Realtime
- Support for emojis, mentions, attachments
- Read receipts (future)

```dart
class ChatService {
  Future<void> sendMessage(String noteId, String message) async {
    await supabase.from('chat_messages').insert({
      'note_id': noteId,
      'user_id': getCurrentUserId(),
      'message': message,
    });
    
    // Realtime broadcast handled automatically
  }
  
  Stream<List<ChatMessage>> streamMessages(String noteId) {
    return supabase
      .from('chat_messages')
      .stream(primaryKey: ['id'])
      .eq('note_id', noteId)
      .order('created_at', ascending: true);
  }
}
```

---

## 9. Offline-Online Sync

### 9.1 Sync Architecture

**Three-State Model:**
1. **Online**: Real-time sync with server
2. **Offline**: Operations queued locally
3. **Syncing**: Batch upload on reconnection

**Sync Manager:**

```dart
class SyncManager {
  final ConnectivityService connectivity;
  final OfflineQueue offlineQueue;
  final ConflictResolver conflictResolver;
  
  StreamSubscription? connectivitySubscription;
  
  void initialize() {
    connectivitySubscription = connectivity.stream.listen((isConnected) {
      if (isConnected) {
        processOfflineQueue();
      }
    });
  }
  
  Future<void> processOfflineQueue() async {
    final operations = await offlineQueue.getAllPending();
    
    for (var operation in operations) {
      try {
        await executeOperation(operation);
        await detectAndResolveConflicts(operation);
        await offlineQueue.remove(operation.id);
      } catch (e) {
        // Handle error, retry logic
      }
    }
  }
  
  Future<void> detectAndResolveConflicts(QueuedOperation operation) async {
    final local = operation.entity;
    final remote = await fetchFromServer(operation.entityId);
    
    if (local.updatedAt != remote.updatedAt) {
      final resolved = await conflictResolver.resolve(local, remote);
      await updateServer(resolved);
    }
  }
}
```

### 9.2 Queue Management

**Offline Queue Structure:**

```dart
class QueuedOperation {
  final String id;
  final String operationType; // 'insert', 'update', 'delete'
  final String entityType;    // 'note', 'page', etc.
  final String entityId;
  final Map<String, dynamic> payload;
  final DateTime queuedAt;
  
  Future<void> execute() async {
    switch (operationType) {
      case 'insert':
        await executeInsert();
        break;
      case 'update':
        await executeUpdate();
        break;
      case 'delete':
        await executeDelete();
        break;
    }
  }
}
```

### 9.3 Data Reconciliation Algorithms

**Timestamp-Based Reconciliation:**

1. Compare `local_updated_at` vs `server_updated_at`
2. If different, conflict detected
3. User chooses resolution or server wins

**Branch-Merge Strategy (Advanced):**

- Track operation history
- Merge non-conflicting changes
- Flag conflicts for manual resolution

---

## 10. API Design

### 10.1 Supabase Client Patterns

**CRUD Operations:**

```dart
// Create
await supabase.from('notes').insert({
  'user_id': userId,
  'title': 'New Note',
  'date': DateTime.now().toIso8601String().split('T')[0],
});

// Read
final notes = await supabase
  .from('notes')
  .select()
  .eq('user_id', userId)
  .order('date', ascending: false);

// Update
await supabase
  .from('notes')
  .update({'title': 'Updated Title'})
  .eq('id', noteId);

// Delete
await supabase
  .from('notes')
  .delete()
  .eq('id', noteId);
```

### 10.2 Real-time Subscription Channels

**Subscription Patterns:**

```dart
// Note changes
supabase
  .channel('note:$noteId')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'notes',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id',
      value: noteId,
    ),
    callback: (payload) {
      // Handle change
    },
  )
  .subscribe();

// Chat messages
supabase
  .channel('chat:$noteId')
  .onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'chat_messages',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'note_id',
      value: noteId,
    ),
    callback: (payload) {
      // Handle new message
    },
  )
  .subscribe();
```

### 10.3 Error Handling and Retry Logic

**Retry Strategy:**

```dart
class RetryableOperation {
  Future<T> execute<T>(Future<T> Function() operation) async {
    int attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        
        if (attempts >= maxAttempts) {
          throw e;
        }
        
        await Future.delayed(Duration(seconds: pow(2, attempts).toInt()));
      }
    }
    
    throw Exception('Max retry attempts reached');
  }
}
```

---

## 11. Deployment & Scalability

### 11.1 Multi-Platform Deployment Strategy

**iOS:**
- Build with Xcode
- App Store distribution
- TestFlight for beta
- Certificate management

**Android:**
- Build APK/AAB
- Google Play distribution
- Internal testing track
- Signing configuration

**Web:**
- Flutter Web build
- Deploy to Firebase Hosting or Cloudflare Pages
- Configure routing
- PWA support for offline

**Build Scripts:**

```bash
# Build all platforms
flutter build apk --release
flutter build ios --release
flutter build web --release

# Environment-specific builds
flutter build apk --release --dart-define=ENV=production
```

### 11.2 Scaling Considerations

**Database Scaling:**
- PostgreSQL vertical scaling (initial)
- Read replicas for heavy read loads
- Partition large tables (activity_log, chat_messages)
- Index optimization

**Storage Scaling:**
- Supabase Storage auto-scales
- Consider CDN for image delivery
- Implement image compression

**API Rate Limiting:**
- Implement per-user rate limits
- Queue AI processing
- Cache AI results

### 11.3 Performance Optimization Strategies

**Frontend:**
- Lazy loading of images
- Virtualized lists for large timelines
- Debouncing search inputs
- Image compression before upload

**Backend:**
- Database query optimization
- Implement pagination
- Cache frequently accessed data
- Use materialized views for analytics

**Network:**
- Implement request batching
- Reduce payload sizes
- Optimize image formats (WebP)
- Use HTTP/2 multiplexing

---

## 12. Technology Stack Details

### 12.1 Flutter Packages

**Core:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  
  # Routing
  go_router: ^13.0.0
  
  # Backend
  supabase_flutter: ^2.0.0
  
  # Firebase & Push Notifications
  firebase_core: ^2.24.0
  firebase_messaging: ^14.7.0
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  sqflite: ^2.3.0
  path_provider: ^2.1.1
  
  # State Persistence
  hydrated_bloc: ^9.1.2
  path_provider: ^2.1.1
  
  # Networking
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  
  # Image Processing
  image_picker: ^1.0.5
  image: ^4.1.3
  cached_network_image: ^3.3.1
  
  # PDF
  pdf: ^3.10.7
  printing: ^5.12.0
  syncfusion_flutter_pdfviewer: ^24.1.41
  
  # UI Components
  flutter_staggered_grid_view: ^0.7.0
  shimmer: ^3.0.0
  pull_to_refresh: ^2.0.0
  
  # Charts & Visualization
  fl_chart: ^0.66.0
  graphview: ^1.2.0
  
  # LaTeX
  flutter_math_fork: ^0.7.3
  
  # Voice Recording
  record: ^5.0.4
  audioplayers: ^5.2.1
  
  # Security
  flutter_secure_storage: ^9.0.0
  encrypt: ^5.0.3
  crypto: ^3.0.3
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.3.0
  timeago: ^3.6.0
  url_launcher: ^6.2.2
```

**Dev Dependencies:**
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1
  mockito: ^5.4.4
  build_runner: ^2.4.8
```

### 12.2 Supabase Features Utilized

**Database:**
- PostgreSQL 15+ with full-text search
- JSONB columns for flexible data
- Foreign keys with cascade operations
- Row Level Security (RLS)
- Database functions and triggers

**Authentication:**
- Email/password authentication
- OAuth providers (Google, Apple, GitHub)
- Two-factor authentication (TOTP)
- Magic links
- Social login

**Storage:**
- Object storage for images, PDFs, voice memos
- CDN integration
- Signed URLs for secure access
- Automatic image transformation

**Realtime:**
- WebSocket-based subscriptions
- Presence tracking
- Broadcast messages
- Database change notifications

**Edge Functions:**
- Background job processing
- Image processing pipelines
- Email notifications
- Scheduled tasks

### 12.3 Third-Party Integrations

**Google Gemini AI:**
- Gemini 1.5 Pro Vision for handwriting recognition
- Gemini 1.5 Pro for text generation (summaries, flashcards)
- Rate limiting and quota management
- Error handling and retries

**Analytics (Future):**
- Firebase Analytics or Mixpanel
- Crash reporting (Sentry)
- Performance monitoring

**Push Notifications:** ✅ FREE with Firebase Cloud Messaging (FCM)
- Firebase Cloud Messaging (FCM): FREE tier, unlimited notifications
- Apple Push Notification Service (APNs): FREE (via FCM integration)
- Package: `firebase_messaging: ^14.7.0`
- Setup cost: $0 (uses Google account)
- Ongoing cost: $0 for unlimited notifications

**Why NOT flutter_local_notifications:**
- Local notifications only work when app is open/installed
- Cannot trigger from server (quota alerts, API warnings)
- Not delivered via system notification service
- Cannot send to multiple devices simultaneously

**Notification Use Cases:**
1. Quota alerts: "You've used 80/100 pages this month"
2. API credit warnings: "Your Gemini API quota is running low"
3. Collaboration: "John commented on your note"
4. Sync status: "Offline changes synced successfully"
5. Monthly reset: "Your quotas have been reset!"

**FCM Setup (Free):**
1. Create Firebase project (free tier)
2. Add FCM to Flutter app with `firebase_messaging` package
3. Store device tokens in user profiles table
4. Trigger via Supabase Edge Functions (free tier)
5. No cost for small-scale deployment

**Implementation:**
```dart
// pubspec.yaml
dependencies:
  firebase_messaging: ^14.7.0
  firebase_core: ^2.24.0

// Store device token in database
Future<void> initializeFirebase() async {
  await Firebase.initializeApp();
  String? token = await FirebaseMessaging.instance.getToken();
  
  // Store in profiles table
  await supabase
    .from('profiles')
    .update({'fcm_token': token})
    .eq('id', currentUserId);
}

// Receive notifications
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  // Handle foreground notification
  showNotification(message);
});

FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
```

---

## 13. Development Workflow

### 13.1 Project Structure

```
MyCloudBook/
├── lib/                          # Flutter app source code
│   ├── main.dart                # Entry point
│   ├── app/                     # App-level configuration
│   ├── core/                    # Shared utilities
│   ├── data/                    # Data layer
│   ├── domain/                  # Business logic
│   └── presentation/            # UI layer
├── test/                        # Unit and widget tests
├── integration_test/            # Integration tests
├── supabase/                    # Supabase configuration
│   ├── migrations/              # Database migrations
│   ├── functions/               # Edge Functions
│   └── seed.sql                 # Seed data
├── docs/                        # Additional documentation
├── android/                     # Android-specific config
├── ios/                         # iOS-specific config
├── web/                         # Web-specific config
├── pubspec.yaml                 # Dependencies
└── README.md                    # Project documentation
```

### 13.2 Git Workflow

**Branch Strategy:**
- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: New features
- `bugfix/*`: Bug fixes
- `hotfix/*`: Critical production fixes

**Commit Messages:**
```
feat: Add AI handwriting recognition
fix: Resolve offline sync conflicts
docs: Update API documentation
refactor: Simplify state management
test: Add unit tests for auth service
```

### 13.3 CI/CD Pipeline

**Automated Testing:**
```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

**Build & Deployment:**
- Automatic builds on merge to main
- App Store and Google Play submissions
- Web deployment to production

---

## 14. Performance Optimization

### 14.1 Frontend Optimization

**Image Handling:**
- Lazy loading with `cached_network_image`
- Image compression before upload
- Progressive image loading
- Thumbnail generation

**State Management:**
- Efficient BLoC rebuilds
- Memoization for expensive computations
- Pagination for large lists

**Network:**
- Request debouncing
- API response caching
- Batch operations where possible

### 14.2 Backend Optimization

**Database:**
- Proper indexing strategy
- Query optimization
- Connection pooling
- Materialized views for analytics

**Storage:**
- Image optimization (WebP)
- CDN caching
- Compression for PDFs

**Realtime:**
- Limit subscription channels
- Efficient presence tracking
- Debounce frequent updates

### 14.3 Monitoring

**Key Metrics:**
- App startup time
- API response times
- Error rates
- User engagement
- AI processing times

**Tools:**
- Supabase Dashboard for backend metrics
- Firebase Performance Monitoring
- Custom analytics dashboard

---

## 15. Security Best Practices

### 15.1 Code Security

- Regular dependency updates
- Static code analysis
- Security audits
- Penetration testing

### 15.2 Data Security

- Encrypt sensitive data at rest
- Use HTTPS for all communications
- Secure API key storage
- Regular backups

### 15.3 Access Control

- Role-based permissions
- Principle of least privilege
- Regular access reviews
- Audit logging

---

## 16. Future Enhancements

### 16.1 Planned Features

**AI Enhancements:**
- Multi-language handwriting recognition
- Advanced concept mapping
- Personalized study recommendations
- Adaptive quiz difficulty

**Collaboration:**
- Video/audio calls within notes
- Shared whiteboard
- Collaborative mind maps
- Group assignments

**Productivity:**
- Calendar integration
- Reminder notifications
- Study analytics dashboard
- Gamification elements

### 16.2 Platform Expansion

- Desktop applications (Windows, macOS, Linux)
- Browser extensions
- API for third-party integrations
- Mobile widgets for quick access

---

## 17. Troubleshooting & Support

### 17.1 Common Issues

**Sync Conflicts:**
- Document conflict resolution process
- Provide clear error messages
- Offer manual merge tools

**AI Failures:**
- Handle API rate limits gracefully
- Provide fallback options
- Cache previous results

**Performance Issues:**
- Profile app for bottlenecks
- Optimize database queries
- Implement lazy loading

### 17.2 Support Channels

- In-app help and tutorials
- FAQ documentation
- Community forum
- Email support

---

## Appendix A: Database Schema Summary

### Core Tables

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `profiles` | User information | id, email, full_name |
| `notebooks` | Notebook collections | id, user_id, title |
| `notes` | Note documents | id, notebook_id, title, date |
| `pages` | Individual pages | id, note_id, image_url, ocr_text |
| `ai_content` | AI-generated content | id, page_id, content_type |
| `collaborations` | Sharing permissions | id, note_id, user_id, role |
| `chat_messages` | Real-time chat | id, note_id, user_id, message |
| `comments` | Note comments | id, note_id, page_id, content |
| `assignments` | Tasks/assignments | id, user_id, title, due_date |
| `api_keys` | Encrypted API keys | id, user_id, encrypted_key |
| `sync_operations` | Conflict tracking | id, entity_type, status |

### Storage Buckets

| Bucket | Purpose | Path Structure |
|--------|---------|----------------|
| `images` | Note page images | `{user_id}/{note_id}/page_*.jpg` |
| `pdfs` | Exported PDFs | `{user_id}/{note_id}_exported.pdf` |
| `voice` | Voice memos | `{user_id}/{note_id}_memo.m4a` |

---

## Appendix B: Environment Variables

```env
# Supabase Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

# App Configuration
APP_NAME=MyCloudBook
APP_VERSION=1.0.0
ENVIRONMENT=production

# Feature Flags
ENABLE_AI=true
ENABLE_COLLABORATION=true
ENABLE_OFFLINE_SYNC=true

# Limits
MAX_IMAGE_SIZE_MB=10
MAX_OFFLINE_QUEUE_SIZE=200
SYNC_INTERVAL_SECONDS=30
```

---

## Appendix C: Glossary

- **BLoC**: Business Logic Component (state management pattern)
- **CRDT**: Conflict-free Replicated Data Type
- **RLS**: Row Level Security
- **TOTP**: Time-based One-Time Password (for 2FA)
- **OCR**: Optical Character Recognition
- **PWA**: Progressive Web App
- **CDN**: Content Delivery Network

---

*Document Version: 1.1*  
*Last Updated: 2024*  
*Architecture Status: Complete - Implementation Ready*