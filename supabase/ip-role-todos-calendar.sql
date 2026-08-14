-- IP DEVELOPMENT: 프로젝트별 캘린더 + 역할별(감독용/제작사용) to-do 리스트
-- 기존 ip_project_tasks(체크리스트)를 확장합니다 — 별도 테이블 없이 "구분(audience)"과
-- "기한(due_date)" 컬럼만 추가해서, 체크리스트 안에서 전체/감독용/제작사용으로 필터링하고
-- 기한이 있는 항목은 캘린더 탭에 모아서 보여줍니다.

alter table ip_project_tasks
  add column if not exists audience text not null default 'general'
  check (audience in ('general', 'director', 'production'));

alter table ip_project_tasks add column if not exists due_date date;
