-- 备忘录 · 个人云同步 schema
-- 在 Supabase Dashboard → SQL Editor 中整段执行。

create table if not exists public.ops_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  revision bigint not null default 0,
  updated_at timestamptz not null default now()
);

alter table public.ops_state enable row level security;

drop policy if exists "ops_state_owner_all" on public.ops_state;
create policy "ops_state_owner_all"
  on public.ops_state
  for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

revoke all on public.ops_state from anon;
grant select, insert, update, delete on public.ops_state to authenticated;

-- 原子保存：客户端带上上次看到的 revision，避免两台设备同时写入时静默覆盖。
create or replace function public.save_ops_state(payload jsonb, expected_revision bigint)
returns table (revision bigint, updated_at timestamptz)
language plpgsql
security invoker
set search_path = public
as $$
declare
  current_revision bigint;
  next_revision bigint;
  saved_at timestamptz := now();
begin
  select s.revision
    into current_revision
    from public.ops_state s
   where s.user_id = auth.uid()
     for update;

  if current_revision is null then
    insert into public.ops_state (user_id, data, revision, updated_at)
    values (auth.uid(), payload, 1, saved_at)
    on conflict (user_id) do nothing;

    return query
      select s.revision, s.updated_at
        from public.ops_state s
       where s.user_id = auth.uid();
  else
    if expected_revision is not null and current_revision <> expected_revision then
      raise exception 'revision_conflict'
        using errcode = '40001',
              hint = 'Fetch the latest state and merge before saving again.';
    end if;

    next_revision := current_revision + 1;

    update public.ops_state s
       set data = payload,
           revision = next_revision,
           updated_at = saved_at
     where s.user_id = auth.uid();

    return query select next_revision, saved_at;
  end if;
end;
$$;

revoke all on function public.save_ops_state(jsonb, bigint) from public;
grant execute on function public.save_ops_state(jsonb, bigint) to authenticated;
