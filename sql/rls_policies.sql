alter table public.tasks enable row level security;
alter table public.task_history enable row level security;

create policy "Users manage their own tasks" on public.tasks for all
  using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "Users read their own task history" on public.task_history for select
  using (auth.uid() = user_id);
