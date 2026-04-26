-- HABBIT.CLI — Supabase schema
-- Run this in the Supabase SQL editor (Project → SQL → New query) one time.
-- Auth: enable "Anonymous sign-ins" under Authentication → Providers before connecting.

create table if not exists public.habits (
  id          bigint primary key generated always as identity,
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  done        date[] not null default '{}',
  created_at  timestamptz not null default now()
);

create index if not exists habits_user_idx on public.habits(user_id);

create table if not exists public.logs (
  id       bigint primary key generated always as identity,
  user_id  uuid not null references auth.users(id) on delete cascade,
  ts       timestamptz not null default now(),
  kind     text not null,
  msg      text not null,
  name     text not null default ''
);

create index if not exists logs_user_ts_idx on public.logs(user_id, ts desc);

-- RLS: shared dataset — every signed-in (including anonymous) session sees
-- and edits all rows. This makes habits sync across devices/browsers even
-- when each browser has its own anonymous user_id. Trade-off: anyone with
-- the anon key can read/write everything in this table — only acceptable
-- for single-user personal projects.
alter table public.habits enable row level security;
alter table public.logs   enable row level security;

drop policy if exists "habits owner all" on public.habits;
drop policy if exists "habits shared"    on public.habits;
create policy "habits shared" on public.habits
  for all
  using  (true)
  with check (true);

drop policy if exists "logs owner all" on public.logs;
drop policy if exists "logs shared"    on public.logs;
create policy "logs shared" on public.logs
  for all
  using  (true)
  with check (true);

-- Default user_id to the caller so inserts don't have to set it explicitly.
alter table public.habits alter column user_id set default auth.uid();
alter table public.logs   alter column user_id set default auth.uid();

-- Realtime: broadcast row changes to subscribed clients so the UI updates
-- live when habits are edited from another tab/device or the table editor.
alter publication supabase_realtime add table public.habits;
alter publication supabase_realtime add table public.logs;
