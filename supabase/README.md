# Supabase Setup Guide

This directory contains all Supabase-related configuration and migrations for MyCloudBook.

## Quick Start

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Go to SQL Editor in your Supabase dashboard
3. Copy and paste the contents of `migrations/001_initial_schema.sql`
4. Click "Run" to execute the schema
5. Go to Storage and create three buckets: `images`, `pdfs`, `voice`
6. Copy your Project URL and Anon Key from Settings > API
7. Update `lib/core/config/app_config.dart` with your credentials

## Database Schema

The schema includes:

- **profiles**: User profiles extending Supabase auth
- **notebooks**: Collection of notes
- **notes**: Note documents with metadata
- **pages**: Individual page images
- **ai_content**: AI-generated content (flashcards, quizzes, summaries)
- **collaborations**: Sharing permissions
- **chat_messages**: Real-time chat
- **comments**: Note comments
- **assignments**: Task tracking
- **activity_log**: User activity tracking
- **api_keys**: Encrypted API keys
- **sync_operations**: Offline sync queue
- **user_quotas**: Free tier quota tracking
- **api_usage_log**: AI API usage and credit monitoring

## Row Level Security

All tables have RLS enabled with policies ensuring users can only access their own data.

## Automatic Functions

- **handle_new_user()**: Automatically creates profile and quota records on user signup
- **reset_monthly_quotas()**: Resets quotas on the 1st of each month

## Storage Buckets

### images
- Store all page images
- Path: `{user_id}/{note_id}/page_{number}.jpg`
- Private access (requires authentication)

### pdfs
- Store exported PDFs
- Path: `{user_id}/{note_id}_exported.pdf`
- Private access

### voice
- Store voice memos
- Path: `{user_id}/{note_id}_memo.m4a`
- Private access

## API Endpoints

Access Supabase via the Flutter client:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;
```

## Environment Variables

Set these in `lib/core/config/app_config.dart`:

```dart
static const String supabaseUrl = 'https://xxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGci...';
```

## Free Tier Limits

- 500MB database storage
- 1GB file storage
- 2GB bandwidth/month
- 50,000 monthly active users

## Support

For Supabase-specific issues, refer to:
- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Flutter Guide](https://supabase.com/docs/reference/dart/introduction)


