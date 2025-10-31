-- RLS Policies for Collaboration Features

-- Collaborations policies (note owners and collaborators can view)
CREATE POLICY "Users can view collaborations on accessible notes"
  ON public.collaborations FOR SELECT
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = collaborations.note_id AND notes.user_id = auth.uid()
    )
  );

CREATE POLICY "Note owners can insert collaborations"
  ON public.collaborations FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = collaborations.note_id AND notes.user_id = auth.uid()
    )
  );

CREATE POLICY "Note owners can update collaborations"
  ON public.collaborations FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = collaborations.note_id AND notes.user_id = auth.uid()
    )
  );

CREATE POLICY "Note owners can delete collaborations"
  ON public.collaborations FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = collaborations.note_id AND notes.user_id = auth.uid()
    )
  );

-- Chat Messages policies
CREATE POLICY "Users can view chat messages on accessible notes"
  ON public.chat_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = chat_messages.note_id 
        AND (
          notes.user_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.note_id = notes.id AND collaborations.user_id = auth.uid()
          )
        )
    )
  );

CREATE POLICY "Users can send chat messages on accessible notes"
  ON public.chat_messages FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = chat_messages.note_id 
        AND (
          notes.user_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.note_id = notes.id AND collaborations.user_id = auth.uid()
          )
        )
    )
  );

-- Comments policies
CREATE POLICY "Users can view comments on accessible notes"
  ON public.comments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = comments.note_id 
        AND (
          notes.user_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.note_id = notes.id AND collaborations.user_id = auth.uid()
          )
        )
    )
  );

CREATE POLICY "Users can comment on accessible notes"
  ON public.comments FOR INSERT
  WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = comments.note_id 
        AND (
          notes.user_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.note_id = notes.id AND collaborations.user_id = auth.uid()
            AND collaborations.role IN ('commenter', 'editor', 'owner')
          )
        )
    )
  );

-- Update notes policies to include collaborators
DROP POLICY IF EXISTS "Users can view own notes" ON public.notes;
CREATE POLICY "Users can view own and shared notes"
  ON public.notes FOR SELECT
  USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.collaborations
      WHERE note_id = notes.id AND user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update own notes" ON public.notes;
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

DROP POLICY IF EXISTS "Users can delete own notes" ON public.notes;
CREATE POLICY "Only owners can delete notes"
  ON public.notes FOR DELETE
  USING (user_id = auth.uid());

-- Update pages policies to include collaborators
DROP POLICY IF EXISTS "Users can view own pages" ON public.pages;
CREATE POLICY "Users can view pages on accessible notes"
  ON public.pages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = pages.note_id 
        AND (
          notes.user_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.note_id = notes.id AND collaborations.user_id = auth.uid()
          )
        )
    )
  );

DROP POLICY IF EXISTS "Users can insert own pages" ON public.pages;
CREATE POLICY "Owners and editors can insert pages"
  ON public.pages FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = pages.note_id 
        AND (
          notes.user_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.note_id = notes.id 
              AND collaborations.user_id = auth.uid() 
              AND collaborations.role IN ('owner', 'editor')
          )
        )
    )
  );

DROP POLICY IF EXISTS "Users can update own pages" ON public.pages;
CREATE POLICY "Owners and editors can update pages"
  ON public.pages FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = pages.note_id 
        AND (
          notes.user_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.note_id = notes.id 
              AND collaborations.user_id = auth.uid() 
              AND collaborations.role IN ('owner', 'editor')
          )
        )
    )
  );

DROP POLICY IF EXISTS "Users can delete own pages" ON public.pages;
CREATE POLICY "Owners and editors can delete pages"
  ON public.pages FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.notes
      WHERE notes.id = pages.note_id 
        AND (
          notes.user_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.note_id = notes.id 
              AND collaborations.user_id = auth.uid() 
              AND collaborations.role IN ('owner', 'editor')
          )
        )
    )
  );

-- AI Content policies
CREATE POLICY "Users can view AI content on accessible pages"
  ON public.ai_content FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.pages
      JOIN public.notes ON notes.id = pages.note_id
      WHERE pages.id = ai_content.page_id 
        AND (
          notes.user_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.note_id = notes.id AND collaborations.user_id = auth.uid()
          )
        )
    )
  );

CREATE POLICY "Owners and editors can insert AI content"
  ON public.ai_content FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.pages
      JOIN public.notes ON notes.id = pages.note_id
      WHERE pages.id = ai_content.page_id 
        AND (
          notes.user_id = auth.uid() OR
          EXISTS (
            SELECT 1 FROM public.collaborations
            WHERE collaborations.note_id = notes.id 
              AND collaborations.user_id = auth.uid() 
              AND collaborations.role IN ('owner', 'editor')
          )
        )
    )
  );

-- Assignments policies
CREATE POLICY "Users can view own assignments"
  ON public.assignments FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own assignments"
  ON public.assignments FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own assignments"
  ON public.assignments FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own assignments"
  ON public.assignments FOR DELETE
  USING (user_id = auth.uid());

-- Activity Log policies
CREATE POLICY "Users can view own activity"
  ON public.activity_log FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "System can insert activity logs"
  ON public.activity_log FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Sync Operations policies
CREATE POLICY "Users can view own sync operations"
  ON public.sync_operations FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own sync operations"
  ON public.sync_operations FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own sync operations"
  ON public.sync_operations FOR UPDATE
  USING (user_id = auth.uid());

