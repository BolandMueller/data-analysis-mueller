SELECT pg_get_viewdef('public.mv_oeel', true);


create materialized view dev_mueller.mv_oeel as
select * from public.mv_oeel;