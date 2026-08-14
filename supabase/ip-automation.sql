-- IP DEVELOPMENT: 노션형 기능 4단계 — 자동화·기록
-- ip-views.sql 이후에 실행하세요.
--
-- (1) 활동 기록: 프로젝트별로 단계 변경/할 일 생성·완료·삭제/댓글/레퍼런스 저장이
--     자동으로 로그에 쌓입니다 (누가 직접 기록할 필요 없음)
-- (2) 상태 변경 알림: 프로젝트 단계가 바뀌면 팀원 전체에게 알림
-- (3) 신규 프로젝트 생성 시 기본 체크리스트 자동 생성

-- 0. 알림 타입에 'status_change' 추가
alter table ip_project_notifications drop constraint if exists ip_project_notifications_type_check;
alter table ip_project_notifications add constraint ip_project_notifications_type_check
  check (type in ('mention', 'assignment', 'status_change'));

-- 1. 활동 기록 테이블
create table if not exists ip_project_activity_log (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references ip_projects(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  detail text not null default '',
  created_at timestamptz not null default now()
);

alter table ip_project_activity_log enable row level security;

create policy "AI tools users can read activity log" on ip_project_activity_log
  for select using (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );

-- 기록은 아래 트리거들이 자동으로 남깁니다 — 그래서 insert 정책이 없습니다.

-- 2. 단계 변경 → 기록 + 팀원 전체 알림
create or replace function public.log_and_notify_stage_change()
returns trigger as $$
declare
  v_member record;
begin
  if new.stage is distinct from old.stage then
    insert into ip_project_activity_log (project_id, actor_id, action, detail)
    values (new.id, auth.uid(), 'stage_changed', old.stage || ' → ' || new.stage);

    for v_member in
      select p.id from profiles p
      where (p.role = 'admin' or p.ai_tools_access = true) and p.id <> auth.uid()
    loop
      insert into ip_project_notifications (recipient_id, actor_id, project_id, type)
      values (v_member.id, auth.uid(), new.id, 'status_change');
    end loop;
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_log_and_notify_stage_change on ip_projects;
create trigger trg_log_and_notify_stage_change
  after update of stage on ip_projects
  for each row execute function public.log_and_notify_stage_change();

-- 3. 체크리스트 항목 생성/완료·재오픈/삭제 → 기록
create or replace function public.log_task_activity()
returns trigger as $$
begin
  if tg_op = 'INSERT' then
    insert into ip_project_activity_log (project_id, actor_id, action, detail)
    values (new.project_id, auth.uid(), 'task_created', new.title);
  elsif tg_op = 'UPDATE' and new.is_done is distinct from old.is_done then
    insert into ip_project_activity_log (project_id, actor_id, action, detail)
    values (new.project_id, auth.uid(), case when new.is_done then 'task_completed' else 'task_reopened' end, new.title);
  elsif tg_op = 'DELETE' then
    insert into ip_project_activity_log (project_id, actor_id, action, detail)
    values (old.project_id, auth.uid(), 'task_deleted', old.title);
  end if;
  return coalesce(new, old);
end;
$$ language plpgsql security definer;

drop trigger if exists trg_log_task_activity on ip_project_tasks;
create trigger trg_log_task_activity
  after insert or update of is_done or delete on ip_project_tasks
  for each row execute function public.log_task_activity();

-- 4. 댓글 작성 → 기록
create or replace function public.log_comment_activity()
returns trigger as $$
begin
  insert into ip_project_activity_log (project_id, actor_id, action, detail)
  values (new.project_id, new.user_id, 'comment_added', left(new.content, 80));
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_log_comment_activity on ip_project_comments;
create trigger trg_log_comment_activity
  after insert on ip_project_comments
  for each row execute function public.log_comment_activity();

-- 5. 레퍼런스 저장 → 기록
create or replace function public.log_reference_activity()
returns trigger as $$
begin
  insert into ip_project_activity_log (project_id, actor_id, action, detail)
  values (new.project_id, new.created_by, 'reference_saved', new.work_title);
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_log_reference_activity on ip_project_references;
create trigger trg_log_reference_activity
  after insert on ip_project_references
  for each row execute function public.log_reference_activity();

-- 6. 신규 프로젝트 생성 시 기본 체크리스트 자동 생성
create or replace function public.seed_default_tasks()
returns trigger as $$
begin
  insert into ip_project_tasks (project_id, title, sort_order)
  values
    (new.id, '로그라인 확정', 1),
    (new.id, '레퍼런스 조사', 2),
    (new.id, '트리트먼트 작성', 3),
    (new.id, '피칭 자료 준비', 4);
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_seed_default_tasks on ip_projects;
create trigger trg_seed_default_tasks
  after insert on ip_projects
  for each row execute function public.seed_default_tasks();
