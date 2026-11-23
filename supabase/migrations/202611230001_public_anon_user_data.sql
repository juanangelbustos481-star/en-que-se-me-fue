-- Additive migration: preserves all existing rows and existing policies.
-- Anonymous Supabase Auth users receive the "authenticated" Postgres role.
create table if not exists public.user_app_data (
  user_id uuid primary key references auth.users(id) on delete cascade,
  app_data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.user_app_data enable row level security;
revoke all on public.user_app_data from anon;
grant select, insert, update, delete on public.user_app_data to authenticated;

do $$
begin
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_data' and policyname='anon_session_select_own_data') then
    execute 'create policy anon_session_select_own_data on public.user_app_data for select to authenticated using (auth.uid() = user_id)';
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_data' and policyname='anon_session_insert_own_data') then
    execute 'create policy anon_session_insert_own_data on public.user_app_data for insert to authenticated with check (auth.uid() = user_id)';
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_data' and policyname='anon_session_update_own_data') then
    execute 'create policy anon_session_update_own_data on public.user_app_data for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)';
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_data' and policyname='anon_session_delete_own_data') then
    execute 'create policy anon_session_delete_own_data on public.user_app_data for delete to authenticated using (auth.uid() = user_id)';
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_data' and policyname='anon_session_select_own_data_restrictive') then
    execute 'create policy anon_session_select_own_data_restrictive on public.user_app_data as restrictive for select to authenticated using (auth.uid() = user_id)';
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_data' and policyname='anon_session_insert_own_data_restrictive') then
    execute 'create policy anon_session_insert_own_data_restrictive on public.user_app_data as restrictive for insert to authenticated with check (auth.uid() = user_id)';
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_data' and policyname='anon_session_update_own_data_restrictive') then
    execute 'create policy anon_session_update_own_data_restrictive on public.user_app_data as restrictive for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)';
  end if;
  if not exists (select 1 from pg_policies where schemaname='public' and tablename='user_app_data' and policyname='anon_session_delete_own_data_restrictive') then
    execute 'create policy anon_session_delete_own_data_restrictive on public.user_app_data as restrictive for delete to authenticated using (auth.uid() = user_id)';
  end if;
end $$;
