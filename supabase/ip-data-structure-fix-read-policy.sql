-- ip-data-structure.sql 후속 수정: 체크리스트/레퍼런스는 "AI 도구 권한(ai_tools_access)"
-- 하나로 읽기/쓰기를 통일합니다. (ip_access는 고객에게 개별 부여하는 IP정보 상세 열람
-- 권한이라 별개 개념 — 체크리스트를 추가할 권한은 있는데 볼 권한은 없는 상황이 생기던 문제 수정)

drop policy if exists "Permitted users can read tasks" on ip_project_tasks;
create policy "AI tools users can read tasks" on ip_project_tasks
  for select using (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );

drop policy if exists "Permitted users can read references" on ip_project_references;
create policy "AI tools users can read references" on ip_project_references
  for select using (
    exists (select 1 from profiles where id = auth.uid() and (role = 'admin' or ai_tools_access = true))
  );
