-- ============================================================
-- 전체 초기 셋업 (한 번에 실행) — auth-tables.sql + ip-synopsis-gating.sql
-- + ai-tools-access.sql + ip-detail-access.sql + 프로젝트 5개 시드를
-- 순서대로 합친 파일입니다. Supabase SQL Editor에 그대로 붙여넣고
-- Run 하시면 됩니다. (전부 idempotent — 이미 일부가 적용돼 있어도 안전합니다)
-- ============================================================

-- ---------- 1. auth-tables.sql ----------

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  username text unique not null default '',
  name text not null default '',
  phone text not null default '',
  affiliation text not null default '',
  role text not null default 'user' check (role in ('admin', 'user')),
  created_at timestamptz default now()
);

alter table profiles enable row level security;

drop policy if exists "Users can read own profile" on profiles;
create policy "Users can read own profile" on profiles
  for select using (auth.uid() = id);

drop policy if exists "Admins can read all profiles" on profiles;
create policy "Admins can read all profiles" on profiles
  for select using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Admins can insert profiles" on profiles;
create policy "Admins can insert profiles" on profiles
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Admins can update profiles" on profiles;
create policy "Admins can update profiles" on profiles
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Users can update own profile" on profiles;
create policy "Users can update own profile" on profiles
  for update using (auth.uid() = id);

drop policy if exists "Admins can delete profiles" on profiles;
create policy "Admins can delete profiles" on profiles
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, username, name, phone, affiliation, role)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'username', ''),
    coalesce(new.raw_user_meta_data ->> 'name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', ''),
    coalesce(new.raw_user_meta_data ->> 'affiliation', ''),
    'user'
  );
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create table if not exists ip_projects (
  id text primary key,
  title text not null,
  genre text not null,
  stage text not null,
  logline text not null,
  sort_order integer not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

alter table ip_projects enable row level security;

drop policy if exists "Anyone can read ip_projects" on ip_projects;
create policy "Anyone can read ip_projects" on ip_projects
  for select using (true);

drop policy if exists "Admins can insert ip_projects" on ip_projects;
create policy "Admins can insert ip_projects" on ip_projects
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Admins can update ip_projects" on ip_projects;
create policy "Admins can update ip_projects" on ip_projects
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Admins can delete ip_projects" on ip_projects;
create policy "Admins can delete ip_projects" on ip_projects
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Public read access" on works;
drop policy if exists "Anyone can read works" on works;
create policy "Anyone can read works" on works
  for select using (true);

drop policy if exists "Admins can insert works" on works;
create policy "Admins can insert works" on works
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Admins can update works" on works;
create policy "Admins can update works" on works
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Admins can delete works" on works;
create policy "Admins can delete works" on works
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- ---------- 2. ip-synopsis-gating.sql ----------

drop policy if exists "Authenticated users can read ip_projects" on ip_projects;

create table if not exists ip_project_synopses (
  project_id text primary key references ip_projects(id) on delete cascade,
  synopsis text not null default '',
  updated_at timestamptz default now()
);

alter table ip_project_synopses enable row level security;

drop policy if exists "Admins can insert synopses" on ip_project_synopses;
create policy "Admins can insert synopses" on ip_project_synopses
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Admins can update synopses" on ip_project_synopses;
create policy "Admins can update synopses" on ip_project_synopses
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

drop policy if exists "Admins can delete synopses" on ip_project_synopses;
create policy "Admins can delete synopses" on ip_project_synopses
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- ---------- 3. ai-tools-access.sql ----------

alter table profiles
  add column if not exists ai_tools_access boolean not null default false;

create table if not exists pd_meeting_transcripts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  project_id text references ip_projects(id) on delete set null,
  director text not null default '미지정',
  content text not null,
  char_count integer not null default 0,
  created_at timestamptz not null default now()
);

alter table pd_meeting_transcripts
  add column if not exists project_id text references ip_projects(id) on delete set null;

alter table pd_meeting_transcripts enable row level security;

drop policy if exists "Users can read own transcripts" on pd_meeting_transcripts;
create policy "Users can read own transcripts" on pd_meeting_transcripts
  for select using (auth.uid() = user_id);

drop policy if exists "AI tools users can insert own transcripts" on pd_meeting_transcripts;
create policy "AI tools users can insert own transcripts" on pd_meeting_transcripts
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from profiles
      where id = auth.uid() and (role = 'admin' or ai_tools_access = true)
    )
  );

drop policy if exists "Users can delete own transcripts" on pd_meeting_transcripts;
create policy "Users can delete own transcripts" on pd_meeting_transcripts
  for delete using (auth.uid() = user_id);

-- ---------- 4. ip-detail-access.sql ----------

alter table ip_projects add column if not exists main_writer text not null default '';
alter table ip_projects add column if not exists year integer;
alter table ip_projects add column if not exists award text not null default '';
alter table ip_projects add column if not exists concept text not null default '';
alter table ip_projects add column if not exists material text not null default '';

alter table profiles add column if not exists ip_access boolean not null default false;

create or replace function public.protect_privileged_profile_columns()
returns trigger as $$
begin
  if not exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  ) then
    new.role := old.role;
    new.ai_tools_access := old.ai_tools_access;
    new.ip_access := old.ip_access;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists protect_privileged_profile_columns on profiles;
create trigger protect_privileged_profile_columns
  before update on profiles
  for each row execute function public.protect_privileged_profile_columns();

alter table ip_project_synopses add column if not exists planning_intent text not null default '';
alter table ip_project_synopses add column if not exists key_images jsonb not null default '[]'::jsonb;

drop policy if exists "Authenticated users can read synopses" on ip_project_synopses;
drop policy if exists "Permitted users can read synopses" on ip_project_synopses;
create policy "Permitted users can read synopses" on ip_project_synopses
  for select using (
    exists (
      select 1 from profiles
      where id = auth.uid() and (role = 'admin' or ip_access = true)
    )
  );

-- ---------- 5. 현재 사이트에 있는 5개 프로젝트를 실제 행으로 시드 ----------
-- (admin 대시보드에서 이 프로젝트들을 바로 편집할 수 있도록 id를 site의
--  정적 라우트와 동일하게 맞춰둡니다: project-a ~ project-e)

insert into ip_projects (id, title, genre, stage, logline, sort_order) values
('project-a', '(프로젝트 A 제목 작성 예정)', '(장르 미정)', '기획', '(한 줄 로그라인 작성 예정 — 알려주시면 반영할게요)', 1),
('project-b', '(프로젝트 B 제목 작성 예정)', '(장르 미정)', '트리트먼트', '(한 줄 로그라인 작성 예정 — 알려주시면 반영할게요)', 2),
('project-c', '(프로젝트 C 제목 작성 예정)', '(장르 미정)', '대본', '(한 줄 로그라인 작성 예정 — 알려주시면 반영할게요)', 3),
('project-d', '(프로젝트 D 제목 작성 예정)', '(장르 미정)', '개발', '(한 줄 로그라인 작성 예정 — 알려주시면 반영할게요)', 4),
('project-e', '(프로젝트 E 제목 작성 예정)', '(장르 미정)', '피칭', '(한 줄 로그라인 작성 예정 — 알려주시면 반영할게요)', 5)
on conflict (id) do nothing;
