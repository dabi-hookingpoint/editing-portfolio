insert into works (
  id, image, title, release_year, genre, editing_approach, type, synopsis,
  release_date, air_start, air_end, director, writer, cast_members, watch_label, watch_url, sort_order
) values (
  'between-the-two-of-us', '/images/works/between-the-two-of-us.png', '우리 둘 사이에', 2025, '소셜 성장 드라마',
  '(편집 포인트 작성 예정 — 알려주시면 반영할게요)',
  '영화',
  '비장애인으로 18년, 장애인으로 17년, 이제는 꿈에서도 휠체어를 타는 ''은진''은 다정한 ''호선''과 함께 평온한 신혼을 누리고 있다. 그러던 어느 날 예기치 않게 둘 사이에 찾아온 미지의 존재 ''쪼꼬''. ''은진''은 아이를 낳겠다고 굳게 다짐하지만 출산이 다가올수록 불안감은 점점 더 커진다.',
  '2025.07.30', null, null, '성지혜', '성지혜', array['김시은','설정환','오지후','강말금'],
  '씨네21에서 보기', 'https://cine21.com/movie/info/?movie_id=62402', 4
)
on conflict (id) do nothing;
