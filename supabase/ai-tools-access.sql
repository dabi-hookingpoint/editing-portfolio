-- AI 도구(회의 녹음/저장, 시나리오 구조 분석, 레퍼런스 추천, 컨셉 이미지 생성) 접근 권한
-- 관리자가 개별 회원에게 부여하는 별도 권한입니다 (role='admin'과는 별개).

alter table profiles
  add column if not exists ai_tools_access boolean not null default false;

-- 주의: 기존 "Users can update own profile" 정책은 UPDATE 문에 WITH CHECK 절이 없어서
-- Postgres RLS 규칙상 USING 절이 WITH CHECK로도 그대로 적용됩니다. 즉 일반 회원이 본인
-- 프로필을 수정할 때 role/ai_tools_access 컬럼까지 자유롭게 바꿔서 스스로 관리자 권한이나
-- AI 도구 권한을 부여할 수 있는 상태였습니다. 아래 트리거로 "본인이 관리자가 아니면
-- role/ai_tools_access는 기존 값으로 강제 고정"해 이 구멍을 막습니다.
create or replace function public.protect_privileged_profile_columns()
returns trigger as $$
begin
  if not exists (
    select 1 from profiles where id = auth.uid() and role = 'admin'
  ) then
    new.role := old.role;
    new.ai_tools_access := old.ai_tools_access;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists protect_privileged_profile_columns on profiles;
create trigger protect_privileged_profile_columns
  before update on profiles
  for each row execute function public.protect_privileged_profile_columns();


-- 기획PD 회의 녹음/저장 (AI 도구 - 녹음 탭). project_id는 ip_projects와 연결되어
-- IP 프로젝트별로 녹음을 구분합니다 (현재 코드는 아직 이 테이블 대신 브라우저
-- localStorage를 프로젝트별 키로 써서 임시 저장 중 — 로그인 정상화 후 전환 예정).
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

create policy "Users can read own transcripts" on pd_meeting_transcripts
  for select using (auth.uid() = user_id);

create policy "AI tools users can insert own transcripts" on pd_meeting_transcripts
  for insert with check (
    auth.uid() = user_id
    and exists (
      select 1 from profiles
      where id = auth.uid() and (role = 'admin' or ai_tools_access = true)
    )
  );

create policy "Users can delete own transcripts" on pd_meeting_transcripts
  for delete using (auth.uid() = user_id);
