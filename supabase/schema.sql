create table if not exists works (
  id text primary key,
  image text not null,
  title text not null,
  release_year integer not null,
  genre text not null,
  editing_approach text not null,
  type text not null check (type in ('영화', '드라마')),
  synopsis text not null,
  release_date text,
  air_start text,
  air_end text,
  director text not null,
  writer text not null,
  cast_members text[] not null,
  watch_label text not null,
  watch_url text not null
);

alter table works enable row level security;

create policy "Public read access" on works
  for select using (true);

insert into works (
  id, image, title, release_year, genre, editing_approach, type, synopsis,
  release_date, air_start, air_end, director, writer, cast_members, watch_label, watch_url
) values
(
  'merry-berry-love', '/images/works/merry-berry-love.png', '메리 베리 러브', 2026, '로맨스',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '드라마',
  '미지의 일본 섬을 배경으로, 새로운 삶을 찾아 떠난 한국인 공간 기획자와 그 섬에서 나고 자란 일본인 여성 농부가 서로에게 스며드는 한일 합작 청춘 로맨스.',
  null, '2026년 10월', '공개 예정', '김수정, 노영섭', '이재윤', array['지창욱','이마다 미오','남윤수'],
  '디즈니+ (공개 예정)', '#'
),
(
  'joseon-attorney', '/images/works/joseon-attorney.png', '조선변호사', 2023, '사극 법정극',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '드라마',
  '부모를 죽음으로 몰아넣은 원수에게 법으로 되갚아주는 조선시대 변호사 ''강한수''가, 백성을 위한 진짜 변호사로 성장해가는 이야기를 그린 유쾌·통쾌한 법정 리벤지 활극.',
  null, '2023.03.31', '2023.05.20', '김승호, 이한준', '최진영', array['우도환','김지연','차학연'],
  '웨이브에서 보기', 'https://www.wavve.com'
),
(
  'last-woman-on-earth', '/images/works/last-woman-on-earth.png', '지구 최후의 여자', 2026, '드라마, 코미디',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '영화',
  '할리우드식 장르 영화로 지원사업에 떨어진 마초남 ''송철''은 영화 교양 시나리오 수업에서 ''여성 서사 가산점''을 노리다 남자를 혐오하는 ''구한아''와 얼떨결에 팀이 된다. 산으로 가는 이야기를 만들어가며 점점 가까워지는 두 사람을 그린, SF와 메타영화, 블랙코미디, 로맨스가 뒤섞인 독립영화.',
  '2026.07.15', null, null, '염문경, 이종민', '염문경, 이종민', array['염문경','이종민','윤상화'],
  '씨네21에서 보기', 'https://cine21.com/movie/info/?movie_id=63238'
)
on conflict (id) do nothing;
