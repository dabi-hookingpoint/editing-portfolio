-- "고백을 못하고" 작품 추가 + 이후 작품들 sort_order 한 칸씩 밀기
-- (연도순: 더러운 돈에 손대지 마라(2024.10) 다음, 조선변호사(2023) 이전)

update works set sort_order = 6 where id = 'joseon-attorney';
update works set sort_order = 7 where id = 'ingan-siljyeok';
update works set sort_order = 8 where id = 'night-of-the-undead';
update works set sort_order = 9 where id = 'the-cursed';
update works set sort_order = 10 where id = 'a-long-way-around';

insert into works (
  id, image, title, release_year, genre, editing_approach, type, synopsis,
  air_start, air_end, director, production_company, writer, cast_members, watch_label, watch_url, sort_order
) values (
  'boys-be-brave',
  '/images/works/boys-be-brave.png',
  '고백을 못하고',
  2024,
  'BL 로맨틱 코미디',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '드라마',
  '단짝친구이자 짝사랑 상대인 ''기섭''이 며칠만 신세 지겠다며 들어와 살게 되면서, 마음을 들킬까 조마조마해하는 ''진우''. 소꿉친구 ''밝음''과 ''인호''까지 얽히며, 좋아하지만 고백하지 못하고 애태우는 두 커플의 밀당을 그린 청춘 BL 로맨틱 코미디. 웹툰 작가 석영의 동명 웹툰(미스터블루)이 원작이다.',
  '2024.04.25',
  '2024.05.16',
  '임현희',
  '페이지원필름, 뉴블랙스튜디오, 와이원엔터테인먼트',
  '이신원',
  array['김성현','남시안','정여준','안세민'],
  '티빙에서 보기',
  'https://www.tving.com/contents/P001757559',
  5
)
on conflict (id) do update set
  image = excluded.image,
  title = excluded.title,
  release_year = excluded.release_year,
  genre = excluded.genre,
  type = excluded.type,
  synopsis = excluded.synopsis,
  air_start = excluded.air_start,
  air_end = excluded.air_end,
  director = excluded.director,
  production_company = excluded.production_company,
  writer = excluded.writer,
  cast_members = excluded.cast_members,
  watch_label = excluded.watch_label,
  watch_url = excluded.watch_url,
  sort_order = excluded.sort_order;
