-- Storage Bucket Policies
-- Create buckets first in Supabase Dashboard: Storage > Create bucket

-- Images bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'images',
  'images',
  true,
  10485760, -- 10MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- PDFs bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'pdfs',
  'pdfs',
  true,
  52428800, -- 50MB
  ARRAY['application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- Voice bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'voice',
  'voice',
  true,
  10485760, -- 10MB
  ARRAY['audio/m4a', 'audio/mpeg', 'audio/wav']
) ON CONFLICT (id) DO NOTHING;

-- Storage Policies for Images
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
        SELECT 1 FROM public.pages
        JOIN public.notes ON notes.id = pages.note_id
        WHERE pages.storage_path = name
          AND (
            notes.user_id = auth.uid() OR
            EXISTS (
              SELECT 1 FROM public.collaborations
              WHERE collaborations.note_id = notes.id AND collaborations.user_id = auth.uid()
            )
          )
      )
    )
  );

CREATE POLICY "Users can update own images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'images' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete own images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'images' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Storage Policies for PDFs
CREATE POLICY "Users can upload own PDFs"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'pdfs' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can view own PDFs"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'pdfs' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete own PDFs"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'pdfs' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Storage Policies for Voice
CREATE POLICY "Users can upload own voice files"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'voice' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can view own voice files"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'voice' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete own voice files"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'voice' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

