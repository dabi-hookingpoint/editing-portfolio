-- IP DEVELOPMENT: 노션형 기능 1단계 — 데이터 구조
-- ai-tools-access.sql, ip-detail-access.sql 이후에 실행하세요.
--
-- (1) 커스텀 속성: 정해진 필드(메인작가/연도/수상/컨셉/소재) 외에 PD가 프로젝트마다
--     자유롭게 추가하는 임의 속성을 담는 여유 공간 (예: {"타겟플랫폼": "OTT"})
-- (2) 체크리스트 / 서브태스크
-- (3) 프로젝트 ↔ 회의록(이미 있음, pd_meeting_transcripts.project_id) ↔ 레퍼런스 관계

-- 1. 커스텀 속성
alter table ip_projects add column if not exists custom_fields jsonb not null default '{}'::jsonb;

-- 2. 체크리스트 / 서브태스크
create table if not exists ip_project_tasks (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references ip_projects(id) on delete cascade,
  title text not null,
  is_done boolean not null default false,
  sort_order integer not null default 0,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now()
);

alter table ip_project_tasks enable row level security;

-- 읽기/쓰기 모두 AI 도구 권한(ai_tools_access)이 있거나 관리자 — 회의 녹음과 같은 팀 작업용 권한
-- (ip_access는 고객에게 개별 부여하는 별개의 IP정보 상세 열람 권한이라 여기엔 쓰지 않습니다.
-- 최초 배포 시 read 정책을 ip_access로 잘못 썼던 버그는 ip-data-structure-fix-read-policy.sql 참고)
create policy "AI tools users can read tasks" on ip_project_tasks
  for select using (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );

-- 쓰기: AI 도구 권한(팀 작업용 권한)이 있거나 관리자
create policy "AI tools users can insert tasks" on ip_project_tasks
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );

create policy "AI tools users can update tasks" on ip_project_tasks
  for update using (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );

create policy "AI tools users can delete tasks" on ip_project_tasks
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );

-- 3. 레퍼런스 저장 (AI 추천 결과를 프로젝트에 저장하거나, 직접 추가한 참고작)
create table if not exists ip_project_references (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references ip_projects(id) on delete cascade,
  work_title text not null,
  reason text not null default '',
  source_url text,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now()
);

alter table ip_project_references enable row level security;

create policy "AI tools users can read references" on ip_project_references
  for select using (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );

create policy "AI tools users can insert references" on ip_project_references
  for insert with check (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );

create policy "AI tools users can delete references" on ip_project_references
  for delete using (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );
