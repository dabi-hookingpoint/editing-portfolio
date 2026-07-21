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
  'night-door', '/images/works/night-door.jpg', '새벽의 문', 2023, '스릴러',
  '용의자 취조 장면과 과거 회상을 교차 편집해 긴장감을 누적시키고, 진실이 드러나는 순간에는 컷 리듬을 급격히 짧게 끊어 관객의 심박수를 끌어올리는 방식으로 접근했다.',
  '영화',
  '모든 걸 잃은 형사 ''한이현''은 5년 전 미제로 남은 실종 사건의 유일한 목격자가 스스로 목숨을 끊었다는 소식을 듣는다. 사건을 다시 파헤치기 시작한 그는, 마을 사람 전부가 침묵하고 있는 진실과 마주하게 되는데…',
  '2023.08.16', null, null, '한지수', '박서연', array['이한별','강태민','노유리'],
  '필름리버 바로가기', '#'
),
(
  'summer-letter', '/images/works/summer-letter.jpg', '여름의 편지', 2022, '로맨스 드라마',
  '대사 없는 리액션 숏을 길게 살려 감정의 여백을 만들고, 사운드 브릿지로 씬과 씬을 부드럽게 연결해 인물 간 정서적 거리감이 서서히 좁혀지는 흐름을 만들었다.',
  '드라마',
  '고등학교 시절 짝사랑했던 첫사랑과 우연히 다시 만난 ''윤아름''. 서로에게 하지 못했던 말들을 편지에 눌러 담으며, 어긋났던 그 여름의 기억을 다시 써 내려가기 시작한다.',
  null, '2022.06.03', '2022.07.23', '오승아', '정다인', array['윤서준','배지안','한소율'],
  '씬플로우 바로가기', '#'
),
(
  'last-signal', '/images/works/last-signal.jpg', '라스트 시그널', 2024, '액션',
  '멀티캠으로 촬영된 액션 시퀀스를 앵글별 정보량 기준으로 재배치하고, 타격감 있는 컷마다 프레임 단위로 사운드 이펙트를 맞춰 리듬을 설계했다.',
  '드라마',
  '국가정보국 소속 요원 ''차도경''은 도심 한복판에서 벌어진 정체불명의 통신 교란 사건에 투입된다. 마지막으로 수신된 시그널 하나를 쫓던 그는, 조직 내부에 숨긴 배신자의 존재를 감지하는데…',
  null, '2024.03.11', '2024.04.29', '문성현', '이현우', array['박준혁','서지은','차민경'],
  '컷라인 바로가기', '#'
)
on conflict (id) do nothing;
