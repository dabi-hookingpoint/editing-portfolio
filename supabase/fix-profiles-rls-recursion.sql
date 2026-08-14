-- 중요 버그 수정: profiles 테이블의 "Admins can read all profiles" 정책이 profiles 자신을
-- 다시 조회하는 구조라서(하위쿼리로 exists (select 1 from profiles ...)), Postgres가 이를
-- "infinite recursion detected in policy for relation \"profiles\""로 감지해 에러를 냅니다.
--
-- 이 정책은 auth-tables.sql 최초 작성 때부터 있었던 구조적 버그로, profiles를 참조하는
-- 모든 정책(다른 테이블 포함)에서 로그인 사용자가 실제로 걸릴 수 있습니다. 직접 확인해보니
-- profiles, ip_project_synopses(=IP정보 상세보기 기능), 그리고 오늘 만든 체크리스트/댓글/
-- 활동기록/레퍼런스 테이블 전부 이 문제로 막혀 있었습니다.
--
-- 해결: "관리자인가/AI 도구 권한이 있는가/IP 열람 권한이 있는가"를 확인하는 걸 SECURITY
-- DEFINER 함수로 빼서, 정책 안에서 profiles를 직접 하위쿼리하지 않게 바꿉니다. (이 세션에서
-- 이미 만든 list_team_members()/create_project_comment() 같은 SECURITY DEFINER 함수들은
-- 이 문제 없이 정상 작동하는 걸 확인했습니다 — 같은 방식을 정책에도 적용하는 것입니다.)

-- 0. 헬퍼 함수
create or replace function public.is_admin()
returns boolean as $$
  select exists (
    select 1 from profiles where profiles.id = auth.uid() and profiles.role = 'admin'
  );
$$ language sql security definer stable;

create or replace function public.is_team_member()
returns boolean as $$
  select exists (
    select 1 from profiles
    where profiles.id = auth.uid() and (profiles.role = 'admin' or profiles.ai_tools_access = true)
  );
$$ language sql security definer stable;

create or replace function public.has_ip_access()
returns boolean as $$
  select exists (
    select 1 from profiles
    where profiles.id = auth.uid() and (profiles.role = 'admin' or profiles.ip_access = true)
  );
$$ language sql security definer stable;

grant execute on function public.is_admin() to authenticated, anon;
grant execute on function public.is_team_member() to authenticated, anon;
grant execute on function public.has_ip_access() to authenticated, anon;

-- 0-1. list_team_members()도 같은 계열의 버그(모호한 컬럼 참조)가 있어 같이 고칩니다.
create or replace function public.list_team_members()
returns table (id uuid, name text, username text) as $$
begin
  if not exists (
    select 1 from profiles where profiles.id = auth.uid() and (profiles.role = 'admin' or profiles.ai_tools_access = true)
  ) then
    return;
  end if;
  return query
    select p.id, p.name, p.username
    from profiles p
    where p.role = 'admin' or p.ai_tools_access = true;
end;
$$ language plpgsql security definer;

-- 1. profiles
drop policy if exists "Admins can read all profiles" on profiles;
create policy "Admins can read all profiles" on profiles
  for select using (public.is_admin());

drop policy if exists "Admins can insert profiles" on profiles;
create policy "Admins can insert profiles" on profiles
  for insert with check (public.is_admin());

drop policy if exists "Admins can update profiles" on profiles;
create policy "Admins can update profiles" on profiles
  for update using (public.is_admin());

drop policy if exists "Admins can delete profiles" on profiles;
create policy "Admins can delete profiles" on profiles
  for delete using (public.is_admin());

-- 2. ip_projects
drop policy if exists "Admins can insert ip_projects" on ip_projects;
create policy "Admins can insert ip_projects" on ip_projects
  for insert with check (public.is_admin());

drop policy if exists "Admins can update ip_projects" on ip_projects;
create policy "Admins can update ip_projects" on ip_projects
  for update using (public.is_admin());

drop policy if exists "Admins can delete ip_projects" on ip_projects;
create policy "Admins can delete ip_projects" on ip_projects
  for delete using (public.is_admin());

-- 3. works
drop policy if exists "Admins can insert works" on works;
create policy "Admins can insert works" on works
  for insert with check (public.is_admin());

drop policy if exists "Admins can update works" on works;
create policy "Admins can update works" on works
  for update using (public.is_admin());

drop policy if exists "Admins can delete works" on works;
create policy "Admins can delete works" on works
  for delete using (public.is_admin());

-- 4. ip_project_synopses (IP정보 상세보기 — 지금까지 실제로 막혀 있었을 가능성이 높은 부분)
drop policy if exists "Permitted users can read synopses" on ip_project_synopses;
create policy "Permitted users can read synopses" on ip_project_synopses
  for select using (public.has_ip_access());

drop policy if exists "Admins can insert synopses" on ip_project_synopses;
create policy "Admins can insert synopses" on ip_project_synopses
  for insert with check (public.is_admin());

drop policy if exists "Admins can update synopses" on ip_project_synopses;
create policy "Admins can update synopses" on ip_project_synopses
  for update using (public.is_admin());

drop policy if exists "Admins can delete synopses" on ip_project_synopses;
create policy "Admins can delete synopses" on ip_project_synopses
  for delete using (public.is_admin());

-- 5. pd_meeting_transcripts
drop policy if exists "AI tools users can insert own transcripts" on pd_meeting_transcripts;
create policy "AI tools users can insert own transcripts" on pd_meeting_transcripts
  for insert with check (auth.uid() = user_id and public.is_team_member());

-- 6. ip_project_tasks
drop policy if exists "AI tools users can read tasks" on ip_project_tasks;
create policy "AI tools users can read tasks" on ip_project_tasks
  for select using (public.is_team_member());

drop policy if exists "AI tools users can insert tasks" on ip_project_tasks;
create policy "AI tools users can insert tasks" on ip_project_tasks
  for insert with check (public.is_team_member());

drop policy if exists "AI tools users can update tasks" on ip_project_tasks;
create policy "AI tools users can update tasks" on ip_project_tasks
  for update using (public.is_team_member());

drop policy if exists "AI tools users can delete tasks" on ip_project_tasks;
create policy "AI tools users can delete tasks" on ip_project_tasks
  for delete using (public.is_team_member());

-- 7. ip_project_references
drop policy if exists "AI tools users can read references" on ip_project_references;
create policy "AI tools users can read references" on ip_project_references
  for select using (public.is_team_member());

drop policy if exists "AI tools users can insert references" on ip_project_references;
create policy "AI tools users can insert references" on ip_project_references
  for insert with check (public.is_team_member());

drop policy if exists "AI tools users can delete references" on ip_project_references;
create policy "AI tools users can delete references" on ip_project_references
  for delete using (public.is_team_member());

-- 8. ip_project_comments
drop policy if exists "AI tools users can read comments" on ip_project_comments;
create policy "AI tools users can read comments" on ip_project_comments
  for select using (public.is_team_member());

drop policy if exists "Users can delete own comments" on ip_project_comments;
create policy "Users can delete own comments" on ip_project_comments
  for delete using (auth.uid() = user_id or public.is_admin());

-- 9. ip_project_activity_log
drop policy if exists "AI tools users can read activity log" on ip_project_activity_log;
create policy "AI tools users can read activity log" on ip_project_activity_log
  for select using (public.is_team_member());
