alter table works add column if not exists sort_order integer not null default 0;

update works set sort_order = 1 where id = 'merry-berry-love';
update works set sort_order = 2 where id = 'last-woman-on-earth';
update works set sort_order = 3 where id = 'joseon-attorney';
