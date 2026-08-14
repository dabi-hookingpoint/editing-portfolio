-- IP DEVELOPMENT: 노션형 기능 2단계 — 협업
-- ip-data-structure.sql, ip-data-structure-fix-read-policy.sql 이후에 실행하세요.
--
-- (1) 담당자 지정: 체크리스트 항목에 담당자(팀원) 지정
-- (2) 프로젝트별 댓글 스레드 (@아이디 로 멘션 가능)
-- (3) 알림: 담당자로 지정되거나 댓글에서 멘션되면 알림이 쌓입니다 (실시간 푸시/이메일이 아닌
--     사이트 내 알림함 — 로그인 후 벨 아이콘에서 확인)

-- 0. 팀원 목록 조회용 함수 — profiles 테이블은 본인 행만 읽을 수 있어서(RLS), 담당자 지정/
--    멘션 자동완성을 위해 "AI 도구 권한이 있는 팀원" 목록만 최소 정보(id/이름/아이디)로
--    안전하게 조회하는 함수를 별도로 둡니다. 호출자 본인도 AI 도구 권한이 있어야 결과를 줍니다.
create or replace function public.list_team_members()
returns table (id uuid, name text, username text) as $$
begin
  if not exists (
    select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true)
  ) then
    return;
  end if;
  return query
    select p.id, p.name, p.username
    from profiles p
    where p.role = 'admin' or p.ai_tools_access = true;
end;
$$ language plpgsql security definer;

grant execute on function public.list_team_members() to authenticated;

-- 1. 담당자 지정
alter table ip_project_tasks add column if not exists assignee_id uuid references auth.users(id) on delete set null;

-- 2. 댓글 스레드
create table if not exists ip_project_comments (
  id uuid primary key default gen_random_uuid(),
  project_id text not null references ip_projects(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade default auth.uid(),
  content text not null,
  created_at timestamptz not null default now()
);

alter table ip_project_comments enable row level security;

create policy "AI tools users can read comments" on ip_project_comments
  for select using (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );

create policy "Users can delete own comments" on ip_project_comments
  for delete using (
    auth.uid() = user_id
    or exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- 댓글 작성은 아래 create_project_comment() 함수로만 합니다 (멘션 파싱 + 알림 생성을 한번에
-- 처리하기 위함) — 그래서 이 테이블에는 별도 insert 정책을 두지 않습니다.

-- 3. 알림함
create table if not exists ip_project_notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references auth.users(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  project_id text references ip_projects(id) on delete cascade,
  comment_id uuid references ip_project_comments(id) on delete cascade,
  task_id uuid references ip_project_tasks(id) on delete cascade,
  type text not null check (type in ('mention', 'assignment')),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

alter table ip_project_notifications enable row level security;

create policy "Users can read own notifications" on ip_project_notifications
  for select using (auth.uid() = recipient_id);

create policy "Users can mark own notifications read" on ip_project_notifications
  for update using (auth.uid() = recipient_id) with check (auth.uid() = recipient_id);

-- 알림 생성도 아래 함수/트리거로만 합니다 (클라이언트가 직접 insert를 못 하게 해서 다른
-- 사람에게 가짜 알림을 만드는 걸 막습니다) — 그래서 insert 정책이 없습니다.

-- 4. 담당자 지정 시 알림 자동 생성 (본인을 본인에게 배정한 경우는 제외)
create or replace function public.notify_task_assignment()
returns trigger as $$
declare
  changed boolean;
begin
  if tg_op = 'INSERT' then
    changed := new.assignee_id is not null;
  else
    changed := new.assignee_id is not null and new.assignee_id is distinct from old.assignee_id;
  end if;

  if changed and new.assignee_id <> auth.uid() then
    insert into ip_project_notifications (recipient_id, actor_id, project_id, task_id, type)
    values (new.assignee_id, auth.uid(), new.project_id, new.id, 'assignment');
  end if;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists trg_notify_task_assignment on ip_project_tasks;
create trigger trg_notify_task_assignment
  after insert or update of assignee_id on ip_project_tasks
  for each row execute function public.notify_task_assignment();

-- 5. 댓글 작성 + @아이디 멘션 감지 + 알림 생성을 한번에 처리하는 함수
create or replace function public.create_project_comment(p_project_id text, p_content text)
returns ip_project_comments as $$
declare
  v_comment ip_project_comments;
  v_username text;
begin
  if not exists (
    select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true)
  ) then
    raise exception 'not permitted';
  end if;

  insert into ip_project_comments (project_id, user_id, content)
  values (p_project_id, auth.uid(), p_content)
  returning * into v_comment;

  for v_username in
    select m[1] from regexp_matches(p_content, '@([a-zA-Z0-9_]+)', 'g') as m
  loop
    insert into ip_project_notifications (recipient_id, actor_id, project_id, comment_id, type)
    select p.id, auth.uid(), p_project_id, v_comment.id, 'mention'
    from profiles p
    where p.username = v_username and p.id <> auth.uid();
  end loop;

  return v_comment;
end;
$$ language plpgsql security definer;

grant execute on function public.create_project_comment(text, text) to authenticated;
