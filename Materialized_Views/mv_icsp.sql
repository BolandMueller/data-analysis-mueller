-- First drop the indexes on the materialized view if they exist
DROP INDEX IF EXISTS dev.mv_icsp_prod_idx;

-- Then drop the materialized view itself
DROP MATERIALIZED VIEW IF EXISTS dev.mv_icsp;

-- dev.mv_icsp source

CREATE MATERIALIZED VIEW dev.mv_icsp
TABLESPACE pg_default
AS SELECT upper(icsp.prod::text)::character varying(24) AS prod,
    icsp.descrip_1::text::character varying(24) as descrip_1,
    icsp.descrip_2::text::character varying(24) as descrip_2,
    icsp.descrip3::text::character varying(256) as descrip3,
    icsp.lookupnm::text::character varying(15) as lookupnm,
    icsp.prodcat::text::character(4) as prodcat,
    upper(icsp.statustype::text)::character(1) as statustype,
    icsp.mfgprod::text::character varying(50) as mfgprod,
    upper(icsp.user4::character(1)::text) AS ecom,
    icsp.user10 AS ecdrilldown,
    icsp.user5 AS mfg,
    icsp.unitstock::character varying(12) AS unitstock,
    icsp.weight,
    icsp.height,
    icsp.length,
    icsp.width,
    icsp.user12 AS ecimg1,
    icsp.user13 AS ecimg2,
    ''::text AS ecimg3,
    icsp.user11 AS ecbuyline,
    upper(icsp.prodtier::character varying(8)::text) AS prodtier,
    upper(icsp.prodtiergrp::character varying(12)::text) AS prodtiergrp,
    icsp.user1 AS ecbuygroup,
    icsp.msdssheetno::character varying(16) AS msdssheetno,
    CURRENT_TIMESTAMP AS "lastUpdate"
   FROM icsp
  WHERE icsp.cono = 1
  ORDER BY (upper(icsp.prod::text)::character varying(24))
WITH DATA;

-- View indexes:
CREATE UNIQUE INDEX mv_icsp_prod_idx ON dev.mv_icsp USING btree (prod);