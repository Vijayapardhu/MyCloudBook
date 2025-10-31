-- MyCloudBook Database Schema
-- Run this in Supabase SQL Editor after creating your project

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
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

-- AI Generated Content
CREATE TABLE public.ai_content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  page_id UUID NOT NULL REFERENCES public.pages(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL CHECK (content_type IN ('flashcard', 'quiz', 'concept_map', 'summary')),
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
  coordinates JSONB,
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
  entity_type TEXT,
  entity_id UUID,
  details JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Encrypted API Keys
CREATE TABLE public.api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  provider TEXT NOT NULL DEFAULT 'gemini',
  encrypted_key TEXT NOT NULL,
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
  operation_type TEXT NOT NULL,
  tokens_used INTEGER,
  cost_estimate DECIMAL(10,4),
  success BOOLEAN NOT NULL,
  error_message TEXT,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collaborations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_operations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_quotas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.api_usage_log ENABLE ROW LEVEL SECURITY;

-- Row Level Security Policies

-- Profiles policies
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Notebooks policies
CREATE POLICY "Users can view own notebooks"
  ON public.notebooks FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own notebooks"
  ON public.notebooks FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own notebooks"
  ON public.notebooks FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own notebooks"
  ON public.notebooks FOR DELETE
  USING (user_id = auth.uid());

-- Notes policies
CREATE POLICY "Users can view own notes"
  ON public.notes FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own notes"
  ON public.notes FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own notes"
  ON public.notes FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own notes"
  ON public.notes FOR DELETE
  USING (user_id = auth.uid());

-- Pages policies
CREATE POLICY "Users can view own pages"
  ON public.pages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = pages.note_id AND notes.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert own pages"
  ON public.pages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = pages.note_id AND notes.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own pages"
  ON public.pages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = pages.note_id AND notes.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own pages"
  ON public.pages FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = pages.note_id AND notes.user_id = auth.uid()
    )
  );

-- User Quotas policies
CREATE POLICY "Users can view own quotas"
  ON public.user_quotas FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own quotas"
  ON public.user_quotas FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own quotas"
  ON public.user_quotas FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- API Usage Log policies
CREATE POLICY "Users can view own API usage"
  ON public.api_usage_log FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own API usage"
  ON public.api_usage_log FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- API Keys policies
CREATE POLICY "Users can view own API keys"
  ON public.api_keys FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update own API keys"
  ON public.api_keys FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own API keys"
  ON public.api_keys FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Create indexes for performance
CREATE INDEX idx_notes_user_id ON public.notes(user_id);
CREATE INDEX idx_notes_date ON public.notes(date DESC);
CREATE INDEX idx_pages_note_id ON public.pages(note_id);
CREATE INDEX idx_collaborations_note_id ON public.collaborations(note_id);
CREATE INDEX idx_chat_messages_note_id ON public.chat_messages(note_id, created_at DESC);
CREATE INDEX idx_api_usage_log_user_id ON public.api_usage_log(user_id, timestamp DESC);

-- Function to automatically create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');
  
  -- Initialize user quota
  INSERT INTO public.user_quotas (user_id, quota_reset_date)
  VALUES (
    NEW.id,
    (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month')::DATE
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to reset monthly quotas
CREATE OR REPLACE FUNCTION public.reset_monthly_quotas()
RETURNS void AS $$
BEGIN
  UPDATE public.user_quotas
  SET 
    pages_uploaded_this_month = 0,
    api_calls_this_month = 0,
    quota_reset_date = (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month')::DATE,
    updated_at = NOW()
  WHERE quota_reset_date <= CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- Function to increment API calls counter
CREATE OR REPLACE FUNCTION public.increment_api_calls(user_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.user_quotas
  SET 
    api_calls_this_month = api_calls_this_month + 1,
    updated_at = NOW()
  WHERE user_quotas.user_id = increment_api_calls.user_id;
END;
$$ LANGUAGE plpgsql;

-- Grant access to public schema
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;


