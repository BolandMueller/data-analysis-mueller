SELECT pg_get_viewdef('public.mv_oeel', true);


create materialized view dev_mueller.test1 as
select * from public.mv_oeel;


SELECT current_database() AS db, current_user AS who, session_user AS session_who;



SELECT schema_name, schema_owner
FROM information_schema.schemata
WHERE schema_name = 'dev_mueller';

SELECT schemaname, matviewname
FROM pg_matviews
WHERE matviewname = 'test1';

SELECT has_schema_privilege(current_user, 'dev_mueller', 'CREATE') AS can_create_in_schema;
