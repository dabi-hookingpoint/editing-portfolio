-- Shift 조선변호사 to make room, then insert the 4 new works in chronological order.
update works set sort_order = 5 where id = 'joseon-attorney';

insert into works (
  id, image, title, release_year, genre, editing_approach, type, synopsis,
  release_date, air_start, air_end, director, production_company, writer, cast_members, watch_label, watch_url, sort_order
) values
(
  'dirty-money', '/images/works/dirty-money.png', '더러운 돈에 손대지 마라', 2024, '범죄, 느와르',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '영화',
  '우연히 범죄 조직의 검은돈에 대한 정보를 입수한 형사 ''명득''과 ''동혁''은 인생 역전을 위해 신고도 추적도 불가능한 그 돈을 훔치기로 계획한다. 그러나 완벽하다고 믿었던 계획은 잠입 수사 중이던 형사의 죽음으로 꼬이기 시작하고, 조직과 경찰 양쪽으로부터 쫓기는 신세가 된다.',
  '2024.10.17', null, null, '김민수', '리양필름', '김민수', array['정우','김대명','박병은','조현철'],
  '티빙에서 보기', 'https://www.tving.com/contents/M000378117', 4
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
