alter table works add column if not exists production_company text not null default '';

update works set production_company = 'CJ ENM · 닛폰 테레비' where id = 'merry-berry-love';
update works set production_company = '영화사 진' where id = 'between-the-two-of-us';
update works set production_company = '(제작사 정보 확인 필요 — 알려주시면 반영할게요)' where id = 'last-woman-on-earth';
update works set production_company = '(제작사 정보 확인 필요 — 알려주시면 반영할게요)' where id = 'joseon-attorney';
