-- Triggers for Quota Management and Other Automated Tasks

-- Trigger to check quota before page insert
DROP TRIGGER IF EXISTS check_page_quota_trigger ON public.pages;
CREATE TRIGGER check_page_quota_trigger
  BEFORE INSERT ON public.pages
  FOR EACH ROW
  EXECUTE FUNCTION public.check_page_quota();

-- Trigger to increment quota after page insert
DROP TRIGGER IF EXISTS increment_quota_on_page_insert_trigger ON public.pages;
CREATE TRIGGER increment_quota_on_page_insert_trigger
  AFTER INSERT ON public.pages
  FOR EACH ROW
  EXECUTE FUNCTION public.increment_quota_on_page_insert();

-- Trigger to decrement quota after page delete
DROP TRIGGER IF EXISTS decrement_quota_on_page_delete_trigger ON public.pages;
CREATE TRIGGER decrement_quota_on_page_delete_trigger
  AFTER DELETE ON public.pages
  FOR EACH ROW
  EXECUTE FUNCTION public.decrement_quota_on_page_delete();

-- Trigger to initialize quota reset date
DROP TRIGGER IF EXISTS initialize_quota_reset_date_trigger ON public.user_quotas;
CREATE TRIGGER initialize_quota_reset_date_trigger
  BEFORE INSERT ON public.user_quotas
  FOR EACH ROW
  EXECUTE FUNCTION public.initialize_quota_reset_date();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers to auto-update updated_at
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_notebooks_updated_at
  BEFORE UPDATE ON public.notebooks
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_notes_updated_at
  BEFORE UPDATE ON public.notes
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_pages_updated_at
  BEFORE UPDATE ON public.pages
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_assignments_updated_at
  BEFORE UPDATE ON public.assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_quotas_updated_at
  BEFORE UPDATE ON public.user_quotas
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_api_keys_updated_at
  BEFORE UPDATE ON public.api_keys
  FOR EACH ROW
  EXECUTE FUNCTION public.update_updated_at_column();

