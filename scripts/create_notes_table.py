"""
Create a notes table in Supabase Postgres with RLS and policies.

Usage:
  - Set env var DATABASE_URL to your Supabase Postgres connection string, e.g.:
      Windows PowerShell:
        $env:DATABASE_URL = "postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres"
      macOS/Linux:
        export DATABASE_URL="postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres"
  - Install dependency and run:
        python -m pip install psycopg[binary]
        python scripts/create_notes_table.py
"""

import os
import sys
import psycopg

DATABASE_URL = os.getenv("DATABASE_URL") or (sys.argv[1] if len(sys.argv) > 1 else None)

DDL = """
-- Ensure required extension for gen_random_uuid
create extension if not exists pgcrypto;

-- 1) Create table
create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  content text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2) Helpful index
create index if not exists notes_user_id_created_at_idx
  on public.notes (user_id, created_at desc);

-- 3) Enable Row Level Security
alter table public.notes enable row level security;

-- 4) Policies
drop policy if exists "Select own notes" on public.notes;
create policy "Select own notes"
  on public.notes for select
  using (auth.uid() = user_id);

drop policy if exists "Insert own notes" on public.notes;
create policy "Insert own notes"
  on public.notes for insert
  with check (auth.uid() = user_id);

drop policy if exists "Update own notes" on public.notes;
create policy "Update own notes"
  on public.notes for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Delete own notes" on public.notes;
create policy "Delete own notes"
  on public.notes for delete
  using (auth.uid() = user_id);
"""


def main() -> None:
  if not DATABASE_URL:
    print("Error: DATABASE_URL not provided. Set env var DATABASE_URL or pass it as argv[1].", file=sys.stderr)
    sys.exit(1)

  # autocommit so DDL executes without explicit transactions
  with psycopg.connect(DATABASE_URL, autocommit=True) as conn:
    with conn.cursor() as cur:
      cur.execute(DDL)

  print("notes table created/ensured, RLS enabled, policies applied.")


if __name__ == "__main__":
  main()


