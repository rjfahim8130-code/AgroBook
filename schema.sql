-- ============================================================
-- Fariha Chat Mini App — Full Schema (idempotent)
-- Run in Supabase SQL Editor. Safe to re-run.
-- ============================================================

-- 1) MESSAGES
create table if not exists public.messages (
  id bigserial primary key,
  user_id bigint not null,
  user_name text,
  message text not null,
  sender_type text not null default 'user' check (sender_type in ('user', 'admin')),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists messages_user_id_idx on public.messages (user_id);
create index if not exists messages_created_at_idx on public.messages (created_at);
create index if not exists messages_user_sender_idx on public.messages (user_id, sender_type);

-- 2) GIFTS
create table if not exists public.gifts (
  id bigserial primary key,
  user_id bigint not null,
  user_name text,
  amount integer not null check (amount > 0),
  created_at timestamptz not null default now()
);

create index if not exists gifts_user_id_idx on public.gifts (user_id);
create index if not exists gifts_created_at_idx on public.gifts (created_at);

-- 3) USERS (referral + activity)
create table if not exists public.users (
  user_id bigint primary key,
  user_name text,
  username text,
  referrer_id bigint,
  last_active timestamptz default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists users_referrer_id_idx on public.users (referrer_id);
create index if not exists users_last_active_idx on public.users (last_active);

-- Add columns if table already existed without them
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'last_active'
  ) then
    alter table public.users add column last_active timestamptz default now();
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'referrer_id'
  ) then
    alter table public.users add column referrer_id bigint;
  end if;
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'username'
  ) then
    alter table public.users add column username text;
  end if;
end $$;

-- 4) APP SETTINGS (admin remote config)
create table if not exists public.app_settings (
  key text primary key,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- 5) TASK COMPLETIONS
create table if not exists public.task_completions (
  user_id bigint not null,
  task_id text not null,
  completed_at timestamptz not null default now(),
  primary key (user_id, task_id)
);

create index if not exists task_completions_user_id_idx on public.task_completions (user_id);

-- 6) RLS
alter table public.messages enable row level security;
alter table public.gifts enable row level security;
alter table public.users enable row level security;
alter table public.app_settings enable row level security;
alter table public.task_completions enable row level security;

-- Policies (drop if exists then create — safe re-run)
do $$
begin
  -- messages
  if not exists (select 1 from pg_policies where tablename = 'messages' and policyname = 'messages_all') then
    create policy messages_all on public.messages for all using (true) with check (true);
  end if;
  -- gifts
  if not exists (select 1 from pg_policies where tablename = 'gifts' and policyname = 'gifts_all') then
    create policy gifts_all on public.gifts for all using (true) with check (true);
  end if;
  -- users
  if not exists (select 1 from pg_policies where tablename = 'users' and policyname = 'users_all') then
    create policy users_all on public.users for all using (true) with check (true);
  end if;
  -- app_settings
  if not exists (select 1 from pg_policies where tablename = 'app_settings' and policyname = 'settings_all') then
    create policy settings_all on public.app_settings for all using (true) with check (true);
  end if;
  -- task_completions
  if not exists (select 1 from pg_policies where tablename = 'task_completions' and policyname = 'tasks_all') then
    create policy tasks_all on public.task_completions for all using (true) with check (true);
  end if;
end $$;

-- 7) REALTIME (for chat)
-- Enable replication for messages if not already
do $$
begin
  -- Add to supabase_realtime publication if missing
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.messages;
    exception when duplicate_object then
      null;
    end;
  end if;
end $$;

-- Done
select 'Schema ready' as status;

-- photo_url on users (safe add)
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'users' and column_name = 'photo_url'
  ) then
    alter table public.users add column photo_url text;
  end if;
end $$;


-- is_read column if table already existed
alter table public.messages add column if not exists is_read boolean not null default false;

-- Realtime: enable replication for messages (run in SQL editor if needed)
-- Dashboard → Database → Replication → messages → enable
do $$
begin
  begin
    alter publication supabase_realtime add table public.messages;
  exception when duplicate_object then null;
  when others then null;
  end;
end $$;


-- Reply + soft delete
alter table public.messages add column if not exists reply_to_id bigint;
alter table public.messages add column if not exists deleted_at timestamptz;
create index if not exists messages_reply_to_idx on public.messages (reply_to_id);
