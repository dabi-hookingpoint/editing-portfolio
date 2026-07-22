-- Adds the documentary category + festival credits. Safe to run even if an
-- earlier version of this file (which also added 2 short films) was already run --
-- the delete below cleans those up if present.
alter table works add column if not exists festivals text[];
alter table works drop constraint if exists works_type_check;
alter table works add constraint works_type_check check (type in ('영화', '드라마'));

-- Remove the 2 short films that were cancelled (no-op if never inserted)
delete from works where id in ('eomma-geukhyeom', 'yuksang-ui-jeonseol');

-- Make sure the remaining works have the correct newest-first sort order
update works set sort_order = 6 where id = 'ingan-siljyeok';
update works set sort_order = 7 where id = 'night-of-the-undead';
update works set sort_order = 8 where id = 'the-cursed';

insert into works (
  id, image, title, release_year, genre, editing_approach, type, synopsis,
  release_date, air_start, air_end, director, production_company, writer, cast_members, watch_label, watch_url, festivals, sort_order
) values
(
  'a-long-way-around', '/images/works/a-long-way-around.png', '에움길', 2019, '다큐멘터리',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '영화',
  '일본군 성노예제 피해자 이옥선 할머니의 내레이션으로 전하는 삶의 기록. 나눔의 집에서 2000년대 초반부터 20여 년간 촬영해온 영상 1600여 점 중에서 선별한 장면들로, 굽어굽어 멀리 돌아가는 ''에움길'' 같았던 할머니들의 시간을 담았다.',
  '2019.06.20', null, null, '이승현', '(정보 확인 필요 — 알려주시면 반영할게요)', '(정보 확인 필요 — 알려주시면 반영할게요)', array['이옥선','이용수','김순덕','강일출'],
  '씨네21에서 보기', 'https://cine21.com/movie/info/?movie_id=54799',
  array['제52회 월드페스트-휴스턴 국제영화제 레미상 수상 (2019)','캐나다 국제영화제 밴쿠버 로열리얼상 수상 (2019)','어콜레이드 글로벌 필름 컴페티션 수상 (2019)','인디페스트 필름 어워즈 수상 (2019)','제9회 유타 국제영화제 세미파이널리스트 (2019)'],
  9
)
on conflict (id) do update set
  image = excluded.image, title = excluded.title, release_year = excluded.release_year,
  genre = excluded.genre, type = excluded.type, synopsis = excluded.synopsis,
  release_date = excluded.release_date, director = excluded.director,
  production_company = excluded.production_company, writer = excluded.writer,
  cast_members = excluded.cast_members, watch_label = excluded.watch_label,
  watch_url = excluded.watch_url, festivals = excluded.festivals, sort_order = excluded.sort_order;
