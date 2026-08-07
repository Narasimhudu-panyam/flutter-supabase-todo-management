-- Run in the Supabase SQL editor. UUID generation is available by default.
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(trim(title)) > 0),
  description text,
  due_date timestamptz,
  priority text not null default 'medium' check (priority in ('low', 'medium', 'high')),
  status text not null default 'pending' check (status in ('pending', 'in_progress', 'completed')),
  category text not null default 'General',
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.task_history (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  action text not null check (action in ('created', 'edited', 'completed', 'uncompleted', 'deleted')),
  old_value jsonb,
  new_value jsonb,
  created_at timestamptz not null default now()
);

create index if not exists tasks_user_created_idx on public.tasks(user_id, created_at desc);
create index if not exists tasks_user_completion_idx on public.tasks(user_id, is_completed);
create index if not exists tasks_user_due_idx on public.tasks(user_id, due_date);
create index if not exists task_history_task_created_idx on public.task_history(task_id, created_at desc);
