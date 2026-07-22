-- profiles 테이블: 사용자 정보 관리
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

-- 본인 프로필만 읽기 가능
create policy "Users can read own profile" on profiles
  for select using (auth.uid() = id);

-- 관리자만 모든 프로필 읽기 가능
create policy "Admins can read all profiles" on profiles
  for select using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- 관리자만 프로필 삽입/수정 가능
create policy "Admins can insert profiles" on profiles
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

create policy "Admins can update profiles" on profiles
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- 본인 프로필 수정 가능 (가입 시 정보 입력용)
create policy "Users can update own profile" on profiles
  for update using (auth.uid() = id);

-- 관리자만 프로필 삭제 가능 (회원 탈퇴 처리)
create policy "Admins can delete profiles" on profiles
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- 신규 가입 시 자동으로 profiles 레코드 생성 (trigger)
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

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();


-- ip_projects 테이블: IP 기획 데이터
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

-- 공개 정보(제목/장르/단계/로그라인)는 누구나 읽기 가능. 상세 시놉시스는
-- 별도 테이블(ip_project_synopses, ip-synopsis-gating.sql)에서 로그인한
-- 사용자에게만 공개합니다.
create policy "Anyone can read ip_projects" on ip_projects
  for select using (true);

-- 관리자만 ip_projects 쓰기 가능
create policy "Admins can insert ip_projects" on ip_projects
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

create policy "Admins can update ip_projects" on ip_projects
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

create policy "Admins can delete ip_projects" on ip_projects
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );


-- works 테이블 RLS 업데이트

-- 기존 정책 삭제
drop policy if exists "Public read access" on works;

-- 모든 사용자 읽기 허용
create policy "Anyone can read works" on works
  for select using (true);

-- 관리자만 쓰기 가능
create policy "Admins can insert works" on works
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

create policy "Admins can update works" on works
  for update using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

create policy "Admins can delete works" on works
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );
