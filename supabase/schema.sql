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

-- Per-login-password scoping. The app SHA-256 hashes a password the user
-- types into the LOGIN modal and stores the hex digest as user_key. All
-- queries filter by this column so two passwords map to two datasets.
alter table public.habits add column if not exists user_key text not null default '';
alter table public.logs   add column if not exists user_key text not null default '';
create index if not exists habits_user_key_idx on public.habits(user_key);
create index if not exists logs_user_key_ts_idx on public.logs(user_key, ts desc);

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
-- Wrapped in DO blocks because `alter publication add table` errors if the
-- table is already a member, which prevents safe re-runs of this file.
do $$ begin
  alter publication supabase_realtime add table public.habits;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table public.logs;
exception when duplicate_object then null;
end $$;

-- ─── Trips & expenses ────────────────────────────────────────
-- Friends share a ledger by joining the same trip_code. Scoping is purely
-- query-side (RLS is permissive, like habits/logs above). The trip_code is
-- the shared secret — share it like a Google Doc link.

create table if not exists public.trips (
  id          bigint primary key generated always as identity,
  trip_code   text   not null unique,
  name        text   not null,
  members     text[] not null default '{}',
  created_at  timestamptz not null default now()
);

create table if not exists public.expenses (
  id          bigint primary key generated always as identity,
  trip_code   text not null,
  amount      numeric(12,2) not null,
  currency    text not null default 'USD',
  description text not null,
  paid_by     text not null,
  created_at  timestamptz not null default now()
);

create index if not exists expenses_trip_idx on public.expenses(trip_code, created_at desc);

alter table public.trips    enable row level security;
alter table public.expenses enable row level security;

drop policy if exists "trips shared"    on public.trips;
drop policy if exists "expenses shared" on public.expenses;
create policy "trips shared"    on public.trips    for all using (true) with check (true);
create policy "expenses shared" on public.expenses for all using (true) with check (true);

do $$ begin
  alter publication supabase_realtime add table public.trips;
exception when duplicate_object then null;
end $$;

do $$ begin
  alter publication supabase_realtime add table public.expenses;
exception when duplicate_object then null;
end $$;
