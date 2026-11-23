-- Professional upgrade: shared savings goals with private membership and contribution records.
-- Existing user_app_data and all current transactions remain untouched.
create table if not exists public.shared_savings_goals (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  target numeric(14,2) not null check (target > 0),
  due date,
  invite_code text not null unique default upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10)),
  created_at timestamptz not null default now()
);
create table if not exists public.shared_savings_members (
  goal_id uuid not null references public.shared_savings_goals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null default 'Participante',
  joined_at timestamptz not null default now(),
  primary key (goal_id, user_id)
);
create table if not exists public.shared_savings_contributions (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.shared_savings_goals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric(14,2) not null check (amount > 0),
  note text not null default '',
  created_at timestamptz not null default now()
);

alter table public.shared_savings_goals enable row level security;
alter table public.shared_savings_members enable row level security;
alter table public.shared_savings_contributions enable row level security;
revoke all on public.shared_savings_goals, public.shared_savings_members, public.shared_savings_contributions from anon, authenticated;
grant select on public.shared_savings_goals, public.shared_savings_members, public.shared_savings_contributions to authenticated;

drop policy if exists shared_goals_member_read on public.shared_savings_goals;
create policy shared_goals_member_read on public.shared_savings_goals for select to authenticated
using (exists (select 1 from public.shared_savings_members m where m.goal_id = id and m.user_id = auth.uid()));
drop policy if exists shared_members_member_read on public.shared_savings_members;
create policy shared_members_member_read on public.shared_savings_members for select to authenticated
using (user_id = auth.uid());
drop policy if exists shared_contributions_member_read on public.shared_savings_contributions;
create policy shared_contributions_member_read on public.shared_savings_contributions for select to authenticated
using (exists (select 1 from public.shared_savings_members m where m.goal_id = shared_savings_contributions.goal_id and m.user_id = auth.uid()));

create or replace function public.create_shared_savings_goal(p_name text, p_target numeric, p_due date default null)
returns table(id uuid, invite_code text)
language plpgsql security definer set search_path = public
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_name is null or char_length(trim(p_name)) not between 1 and 80 or p_target is null or p_target <= 0 then
    raise exception 'Invalid goal details';
  end if;
  insert into public.shared_savings_goals(owner_id, name, target, due)
  values (auth.uid(), trim(p_name), p_target, p_due)
  returning shared_savings_goals.id into v_id;
  insert into public.shared_savings_members(goal_id, user_id, display_name)
  values (v_id, auth.uid(), 'Creador');
  return query select g.id, g.invite_code from public.shared_savings_goals g where g.id = v_id;
end;
$$;

create or replace function public.join_shared_savings_goal(p_code text, p_name text)
returns uuid
language plpgsql security definer set search_path = public
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_code is null or p_name is null or char_length(trim(p_name)) not between 1 and 40 then
    raise exception 'Invalid invitation details';
  end if;
  select g.id into v_id from public.shared_savings_goals g
  where upper(g.invite_code) = upper(trim(p_code));
  if v_id is null then raise exception 'Invitation code not found'; end if;
  insert into public.shared_savings_members(goal_id, user_id, display_name)
  values (v_id, auth.uid(), trim(p_name))
  on conflict (goal_id, user_id) do update set display_name = excluded.display_name;
  return v_id;
end;
$$;

create or replace function public.list_shared_savings_goals()
returns table(id uuid, name text, target numeric, due date, invite_code text, total_saved numeric)
language sql stable security definer set search_path = public
as $$
  select g.id, g.name, g.target, g.due,
         case when g.owner_id = auth.uid() then g.invite_code else null end,
         coalesce(sum(c.amount), 0)::numeric
  from public.shared_savings_goals g
  join public.shared_savings_members m on m.goal_id = g.id and m.user_id = auth.uid()
  left join public.shared_savings_contributions c on c.goal_id = g.id
  group by g.id, g.name, g.target, g.due, g.invite_code, g.owner_id
  order by g.created_at desc;
$$;

create or replace function public.contribute_to_shared_savings_goal(p_goal_id uuid, p_amount numeric, p_note text default '')
returns uuid
language plpgsql security definer set search_path = public
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_amount is null or p_amount <= 0 then raise exception 'Contribution must be positive'; end if;
  if not exists (select 1 from public.shared_savings_members m where m.goal_id = p_goal_id and m.user_id = auth.uid()) then
    raise exception 'You are not a member of this goal';
  end if;
  insert into public.shared_savings_contributions(goal_id, user_id, amount, note)
  values (p_goal_id, auth.uid(), p_amount, left(coalesce(p_note, ''), 160))
  returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.create_shared_savings_goal(text,numeric,date) from public, anon;
revoke all on function public.join_shared_savings_goal(text,text) from public, anon;
revoke all on function public.list_shared_savings_goals() from public, anon;
revoke all on function public.contribute_to_shared_savings_goal(uuid,numeric,text) from public, anon;
grant execute on function public.create_shared_savings_goal(text,numeric,date) to authenticated;
grant execute on function public.join_shared_savings_goal(text,text) to authenticated;
grant execute on function public.list_shared_savings_goals() to authenticated;
grant execute on function public.contribute_to_shared_savings_goal(uuid,numeric,text) to authenticated;
