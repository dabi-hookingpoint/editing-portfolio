-- IP Development 개편: 목록 카드용 필드 추가 + 상세 열람 권한을
-- "로그인만 하면 OK"에서 "관리자가 부여한 권한이 있어야 함"으로 강화.
-- ai-tools-access.sql, ip-synopsis-gating.sql 이후에 실행하세요.

-- 1. ip_projects: 목록 카드에 표시할 공개 필드 추가 (누구나 볼 수 있음)
alter table ip_projects add column if not exists main_writer text not null default '';
alter table ip_projects add column if not exists year integer;
alter table ip_projects add column if not exists award text not null default '';
alter table ip_projects add column if not exists concept text not null default '';
alter table ip_projects add column if not exists material text not null default '';

-- 2. profiles: IP 상세정보(시놉시스/기획의도/주요이미지) 열람 권한 — ai_tools_access와는
--    별도의 권한입니다. 관리자가 admin.astro에서 개별 부여/해제합니다.
alter table profiles add column if not exists ip_access boolean not null default false;

-- protect_privileged_profile_columns 트리거(ai-tools-access.sql)가 ip_access도 같이
-- 보호하도록 재정의 — 일반 회원이 본인 프로필 수정 시 스스로 권한을 올릴 수 없게 함.
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

-- 3. ip_project_synopses: 상세 열람 시 보여줄 기획의도/주요 이미지 컬럼 추가
alter table ip_project_synopses add column if not exists planning_intent text not null default '';
alter table ip_project_synopses add column if not exists key_images jsonb not null default '[]'::jsonb;

-- 4. 시놉시스 열람 정책을 "로그인만 하면 OK"에서 "ip_access 권한 있는 회원 또는
--    관리자만"으로 강화
drop policy if exists "Authenticated users can read synopses" on ip_project_synopses;

create policy "Permitted users can read synopses" on ip_project_synopses
  for select using (
    exists (
      select 1 from profiles
      where id = auth.uid() and (role = 'admin' or ip_access = true)
    )
  );
