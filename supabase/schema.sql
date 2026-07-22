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
  production_company text not null,
  writer text not null,
  cast_members text[] not null,
  watch_label text not null,
  watch_url text not null,
  sort_order integer not null default 0
);

alter table works enable row level security;

create policy "Public read access" on works
  for select using (true);

insert into works (
  id, image, title, release_year, genre, editing_approach, type, synopsis,
  release_date, air_start, air_end, director, production_company, writer, cast_members, watch_label, watch_url, sort_order
) values
(
  'merry-berry-love', '/images/works/merry-berry-love.png', '메리 베리 러브', 2026, '로맨스',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '드라마',
  '미지의 일본 섬을 배경으로, 새로운 삶을 찾아 떠난 한국인 공간 기획자와 그 섬에서 나고 자란 일본인 여성 농부가 서로에게 스며드는 한일 합작 청춘 로맨스.',
  null, '2026년 10월', '공개 예정', '김수정, 노영섭', 'CJ ENM · 닛폰 테레비', '이재윤', array['지창욱','이마다 미오','남윤수'],
  '디즈니+ · 닛폰 테레비 (공개 예정)', '#', 1
),
(
  'last-woman-on-earth', '/images/works/last-woman-on-earth.png', '지구 최후의 여자', 2026, '드라마, 코미디',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '영화',
  '할리우드식 장르 영화로 지원사업에 떨어진 마초남 ''송철''은 영화 교양 시나리오 수업에서 ''여성 서사 가산점''을 노리다 남자를 혐오하는 ''구한아''와 얼떨결에 팀이 된다. 산으로 가는 이야기를 만들어가며 점점 가까워지는 두 사람을 그린, SF와 메타영화, 블랙코미디, 로맨스가 뒤섞인 독립영화.',
  '2026.07.15', null, null, '염문경, 이종민', '호랑이연구소', '염문경, 이종민', array['염문경','이종민','윤상화'],
  '씨네21에서 보기', 'https://cine21.com/movie/info/?movie_id=63238', 2
),
(
  'between-the-two-of-us', '/images/works/between-the-two-of-us.png', '우리 둘 사이에', 2025, '소셜 성장 드라마',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '영화',
  '비장애인으로 18년, 장애인으로 17년, 이제는 꿈에서도 휠체어를 타는 ''은진''은 다정한 ''호선''과 함께 평온한 신혼을 누리고 있다. 그러던 어느 날 예기치 않게 둘 사이에 찾아온 미지의 존재 ''쪼꼬''. ''은진''은 아이를 낳겠다고 굳게 다짐하지만 출산이 다가올수록 불안감은 점점 더 커진다.',
  '2025.07.30', null, null, '성지혜', '영화사 진', '성지혜', array['김시은','설정환','오지후','강말금'],
  '씨네21에서 보기', 'https://cine21.com/movie/info/?movie_id=62402', 3
),
(
  'dirty-money', '/images/works/dirty-money.png', '더러운 돈에 손대지 마라', 2024, '범죄, 느와르',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '영화',
  '우연히 범죄 조직의 검은돈에 대한 정보를 입수한 형사 ''명득''과 ''동혁''은 인생 역전을 위해 신고도 추적도 불가능한 그 돈을 훔치기로 계획한다. 그러나 완벽하다고 믿었던 계획은 잠입 수사 중이던 형사의 죽음으로 꼬이기 시작하고, 조직과 경찰 양쪽으로부터 쫓기는 신세가 된다.',
  '2024.10.17', null, null, '김민수', '리양필름', '김민수', array['정우','김대명','박병은','조현철'],
  '티빙에서 보기', 'https://www.tving.com/contents/M000378117', 4
),
(
  'joseon-attorney', '/images/works/joseon-attorney.png', '조선변호사', 2023, '사극 법정극',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '드라마',
  '부모를 죽음으로 몰아넣은 원수에게 법으로 되갚아주는 조선시대 변호사 ''강한수''가, 백성을 위한 진짜 변호사로 성장해가는 이야기를 그린 유쾌·통쾌한 법정 리벤지 활극.',
  null, '2023.03.31', '2023.05.20', '김승호, 이한준', '원컨텐츠', '최진영', array['우도환','김지연','차학연'],
  '웨이브에서 보기', 'https://www.wavve.com', 5
),
(
  'ingan-siljyeok', '/images/works/ingan-siljyeok.png', '인간실격', 2021, '로맨스 멜로',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '드라마',
  '대필 작가를 꿈꿨지만 삶의 이유를 잃어버린 ''부정''과, 부자의 삶을 꿈꾸며 역할대행 서비스를 운영하지만 무엇 하나 이루지 못한 ''강재''가 서로 얽히게 되는 이야기. 빛을 향해 최선을 다해 걸어왔지만 문득 아무것도 되지 못했다는 것을 깨닫는 평범한 두 사람의 삶을 그린다.',
  null, '2021.09.04', '2021.10.24', '허진호, 박홍수', '씨제스엔터테인먼트, 드라마하우스스튜디오', '김지혜', array['전도연','류준열','박병은','김효진'],
  '티빙에서 보기', 'https://www.tving.com/contents/P001506481', 6
),
(
  'night-of-the-undead', '/images/works/night-of-the-undead.png', '죽지 않는 인간들의 밤', 2020, '코미디, 스릴러',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '영화',
  '신혼의 단꿈에 빠져있던 ''소희''는 하루 21시간 쉬지 않고 활동하는 남편 ''만길''이 자신을 죽이려 한다는 사실을 알게 된다. 고등학교 동창 ''세라'', 우연히 합류한 ''양선'', 미스터리 연구소장 ''닥터 장''과 함께 반격에 나서지만, 만길의 정체가 지구를 차지하러 온 외계인임이 밝혀지며 대결은 전대미문의 상황으로 커진다.',
  '2020.09.29', null, null, '신정원', 'TCO(주)더콘텐츠온, 브라더픽쳐스', '신정원, 장항준', array['이정현','김성오','서영희','양동근'],
  '씨네21에서 보기', 'https://cine21.com/movie/info/?movie_id=54194', 7
),
(
  'the-cursed', '/images/works/the-cursed.png', '방법', 2020, '미스터리 스릴러',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '드라마',
  '국내 최대 IT기업 ''포레스트''의 비밀을 파헤치려는 사회부 기자 ''임진희''가, 강력한 신기와 특별한 능력을 가진 소녀 ''백소진''을 만나면서 불의에 맞서 싸우게 되는 미스터리 스릴러.',
  null, '2020.02.10', '2020.03.17', '김용완', '레진 스튜디오', '연상호', array['엄지원','정지소','성동일','조민수'],
  '티빙에서 보기', 'https://www.tving.com/contents/P001153248', 8
)
on conflict (id) do nothing;
