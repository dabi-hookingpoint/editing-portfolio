alter table works add column if not exists production_company text not null default '';

update works set production_company = 'CJ ENM · 닛폰 테레비' where id = 'merry-berry-love';
update works set production_company = '영화사 진' where id = 'between-the-two-of-us';
update works set production_company = '호랑이연구소' where id = 'last-woman-on-earth';
update works set production_company = '원컨텐츠' where id = 'joseon-attorney';
