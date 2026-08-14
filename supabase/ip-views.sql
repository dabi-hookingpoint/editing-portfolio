-- IP DEVELOPMENT: 노션형 기능 3단계 — 보기 전환
-- ip-collaboration.sql 이후에 실행하세요.
--
-- 캘린더/타임라인 보기에 쓸 "목표일" 필드 추가 (기존엔 연도만 있고 구체적인 날짜가 없었음)
alter table ip_projects add column if not exists target_date date;
