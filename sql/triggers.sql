create or replace function public.set_task_updated_at()
returns trigger language plpgsql security invoker as $$
begin new.updated_at = now(); return new; end; $$;

create or replace function public.audit_task_change()
returns trigger language plpgsql security definer set search_path = public as $$
declare audit_action text;
begin
  if tg_op = 'INSERT' then
    insert into task_history(task_id, user_id, action, new_value)
      values (new.id, new.user_id, 'created', to_jsonb(new));
    return new;
  elsif tg_op = 'DELETE' then
    insert into task_history(task_id, user_id, action, old_value)
      values (old.id, old.user_id, 'deleted', to_jsonb(old));
    return old;
  end if;
  audit_action := case when old.is_completed is distinct from new.is_completed then
    case when new.is_completed then 'completed' else 'uncompleted' end else 'edited' end;
  insert into task_history(task_id, user_id, action, old_value, new_value)
    values (new.id, new.user_id, audit_action, to_jsonb(old), to_jsonb(new));
  return new;
end; $$;

drop trigger if exists set_task_updated_at on public.tasks;
create trigger set_task_updated_at before update on public.tasks for each row execute function public.set_task_updated_at();
drop trigger if exists audit_task_changes on public.tasks;
create trigger audit_task_changes after insert or update or delete on public.tasks for each row execute function public.audit_task_change();

-- Enable database change broadcasting for the Flutter stream subscription.
alter publication supabase_realtime add table public.tasks;
