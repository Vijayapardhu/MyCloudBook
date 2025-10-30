-- FTS indexes for notes and pages
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_notes_title_fts ON public.notes USING GIN (to_tsvector('english', coalesce(title,'')));
CREATE INDEX IF NOT EXISTS idx_pages_ocr_fts  ON public.pages USING GIN (to_tsvector('english', coalesce(ocr_text,'')));


