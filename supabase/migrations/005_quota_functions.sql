-- Quota Management Functions and Triggers

-- Function to check page quota before insert
CREATE OR REPLACE FUNCTION public.check_page_quota()
RETURNS TRIGGER AS $$
DECLARE
  user_tier TEXT;
  pages_used INTEGER;
  max_pages INTEGER;
BEGIN
  SELECT tier, pages_uploaded_this_month INTO user_tier, pages_used
  FROM public.user_quotas
  WHERE user_id = (
    SELECT user_id FROM public.notes WHERE id = NEW.note_id
  );
  
  -- Premium users have no limits
  IF user_tier = 'premium' THEN
    RETURN NEW;
  END IF;
  
  -- Free tier limit
  max_pages := 100;
  
  IF pages_used >= max_pages THEN
    RAISE EXCEPTION 'Monthly page quota exceeded. You have uploaded % pages this month (limit: %). Upgrade to premium for unlimited pages.', pages_used, max_pages;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment quota counters after page insert
CREATE OR REPLACE FUNCTION public.increment_quota_on_page_insert()
RETURNS TRIGGER AS $$
DECLARE
  note_user_id UUID;
  page_size_bytes BIGINT;
BEGIN
  -- Get note owner
  SELECT user_id INTO note_user_id
  FROM public.notes
  WHERE id = NEW.note_id;
  
  -- Estimate page size (can be improved by storing actual size)
  -- For now, estimate 2MB per page
  page_size_bytes := 2 * 1024 * 1024;
  
  -- Update quota counters
  UPDATE public.user_quotas
  SET 
    pages_uploaded_this_month = pages_uploaded_this_month + 1,
    storage_used_bytes = storage_used_bytes + page_size_bytes,
    updated_at = NOW()
  WHERE user_id = note_user_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement quota counters after page delete
CREATE OR REPLACE FUNCTION public.decrement_quota_on_page_delete()
RETURNS TRIGGER AS $$
DECLARE
  note_user_id UUID;
  page_size_bytes BIGINT;
BEGIN
  -- Get note owner
  SELECT user_id INTO note_user_id
  FROM public.notes
  WHERE id = OLD.note_id;
  
  -- Estimate page size
  page_size_bytes := 2 * 1024 * 1024;
  
  -- Update quota counters (don't go below 0)
  UPDATE public.user_quotas
  SET 
    pages_uploaded_this_month = GREATEST(0, pages_uploaded_this_month - 1),
    storage_used_bytes = GREATEST(0, storage_used_bytes - page_size_bytes),
    updated_at = NOW()
  WHERE user_id = note_user_id;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update quota reset date when quota is created
CREATE OR REPLACE FUNCTION public.initialize_quota_reset_date()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.quota_reset_date IS NULL THEN
    NEW.quota_reset_date := (DATE_TRUNC('month', CURRENT_DATE) + INTERVAL '1 month')::DATE;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

