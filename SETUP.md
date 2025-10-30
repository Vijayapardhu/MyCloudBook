# MyCloudBook Setup Guide

This guide will help you set up the MyCloudBook application with all required services.

## Prerequisites

- Flutter SDK 3.8.1 or higher
- Dart SDK 3.8.1 or higher
- Git
- A code editor (VS Code recommended)

## 1. Supabase Setup (FREE)

### Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign up for a free account
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - Name: `mycloudbook`
   - Database Password: (choose a strong password)
   - Region: Choose closest to you
   - Pricing Plan: FREE
6. Click "Create new project"

### Step 2: Get API Keys

1. In your Supabase project dashboard, go to Settings > API
2. Copy the following:
   - Project URL: `https://xxxxxxxx.supabase.co`
   - Anon/Public Key: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### Step 3: Update Configuration

Edit `lib/core/config/app_config.dart`:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';
```

### Step 4: Create Database Schema

In your Supabase project, go to SQL Editor and create the schema:

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  fcm_token TEXT,
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

-- API Usage Tracking
CREATE TABLE public.api_usage_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  api_provider TEXT NOT NULL DEFAULT 'gemini',
  operation_type TEXT NOT NULL,
  tokens_used INTEGER,
  cost_estimate DECIMAL(10,4),
  success BOOLEAN NOT NULL,
  error_message TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_quotas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_usage_log ENABLE ROW LEVEL SECURITY;

-- Basic RLS Policies
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can view own notes"
  ON public.notes FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own notes"
  ON public.notes FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- More policies to be added as needed
```

### Step 5: Create Storage Buckets

1. Go to Storage in Supabase dashboard
2. Create buckets:
   - `images` (public: false)
   - `pdfs` (public: false)
   - `voice` (public: false)

## 2. Firebase Setup (FREE)

### Step 1: Create Firebase Project

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com)
2. Click "Add project"
3. Enter project name: `mycloudbook`
4. Follow setup wizard (default settings are fine)
5. Click "Create project"

### Step 2: Add Flutter App

1. In Firebase console, click "Add app" > Flutter
2. Enter package name: `com.mycloudbook`
3. Follow instructions to download config files

### Step 3: Configure Firebase for Flutter

**Android:**
1. Download `google-services.json`
2. Place in `android/app/`

**iOS:**
1. Download `GoogleService-Info.plist`
2. Place in `ios/Runner/`

**Web:**
1. Run: `flutterfire configure`
2. Follow prompts

### Step 4: Enable Cloud Messaging

1. In Firebase Console > Project Settings > Cloud Messaging
2. Enable "Cloud Messaging API (V1)"
3. Note: iOS requires Apple Developer account for push certificates

## 3. Google Gemini API Setup

### Step 1: Get API Key

1. Go to [https://ai.google.dev](https://ai.google.dev)
2. Click "Get API Key"
3. Sign in with Google account
4. Create API key for a new project
5. Copy the API key

**Note:** This API key will be user-provided in the app settings. Users need to get their own Gemini API key to use AI features.

## 4. Local Development Setup

### Step 1: Install Dependencies

```bash
flutter pub get
```

### Step 2: Run the App

```bash
flutter run
```

### Step 3: Test on Different Platforms

**Android:**
```bash
flutter run -d android
```

**iOS (Mac only):**
```bash
flutter run -d ios
```

**Web:**
```bash
flutter run -d chrome
```

## 5. Environment Variables (Optional)

Create `lib/core/config/app_config.dart` with your specific values for production.

## 6. Testing Checklist

- [ ] Supabase connection working
- [ ] Firebase connection working
- [ ] User authentication flow
- [ ] Database schema created
- [ ] Storage buckets configured
- [ ] Push notifications enabled
- [ ] App runs on target platform

## Troubleshooting

### Supabase Connection Issues

- Verify URL and anon key in `app_config.dart`
- Check network connectivity
- Review Supabase project status

### Firebase Issues

- Ensure config files are in correct directories
- Run `flutter clean && flutter pub get`
- Check Firebase project settings

### Build Issues

- Run `flutter doctor` to check setup
- Install Android Studio / Xcode for platform builds
- Update Flutter: `flutter upgrade`

## Support

For more help:
- Check `ARCHITECTURE.md` for technical details
- Review `SRS.md` for requirements
- See `SRS_REVIEW.md` for implementation guidance

## Cost Summary (FREE Tier)

✅ **Supabase**: FREE (up to 500MB database, 1GB storage, 2GB bandwidth)  
✅ **Firebase**: FREE (unlimited notifications)  
✅ **Gemini API**: User-provided keys (users control their own costs)  
✅ **Total Platform Cost**: $0

