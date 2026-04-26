-- HABBIT.CLI — Supabase schema
-- Run once in Supabase SQL editor.

create extension if not exists "pgcrypto";

create table if not exists public.habits (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  short_id    int  not null,
  created_at  timestamptz not null default now()
);

create unique index if not exists habits_user_short_id_idx
  on public.habits(user_id, short_id);

create table if not exists public.checkins (
  id          uuid primary key default gen_random_uuid(),
  habit_id    uuid not null references public.habits(id) on delete cascade,
  user_id     uuid not null references auth.users(id) on delete cascade,
  day         date not null,
  created_at  timestamptz not null default now(),
  unique (habit_id, day)
);

create index if not exists checkins_user_day_idx on public.checkins(user_id, day);
create index if not exists checkins_habit_idx    on public.checkins(habit_id);

-- ── RLS ───────────────────────────────────────────────────────────────────
alter table public.habits   enable row level security;
alter table public.checkins enable row level security;

drop policy if exists "habits owner all" on public.habits;
create policy "habits owner all"
  on public.habits
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "checkins owner all" on public.checkins;
create policy "checkins owner all"
  on public.checkins
  for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ── helper: assign next short_id per user ─────────────────────────────────
create or replace function public.next_short_id(p_user uuid)
returns int
language sql
stable
as $$
  select coalesce(max(short_id), 0) + 1
  from public.habits
  where user_id = p_user;
$$;
