-- First drop the indexes on the materialized view if they exist
DROP INDEX IF EXISTS dev.mv_icsw_prod_whse_idx;

-- Then drop the materialized view itself
DROP MATERIALIZED VIEW IF EXISTS dev.mv_icsw;

-- dev.mv_icsw source

CREATE MATERIALIZED VIEW dev.mv_icsw
TABLESPACE pg_default
AS SELECT upper(icsw.prod::text)::character varying(24) AS prod,
    icsw.whse::character(4) AS whse,
    upper(icsw.binloc1::text)::character varying(10) AS binloc1,
    upper(icsw.binloc2::text)::character varying(10) AS binloc2,
    icsw.avgcost,
    icsw.lastcost,
    icsw.replcost,
    icsw.countfl,
    icsw.lastcntdt,
    icsw.nonstockty,
    icsw.ordcalcty,
    icsw.orderpt,
    upper(icsw.pricetype::text)::character(4) AS pricetype,
    icsw.prodline::character varying AS prodline,
    icsw.qtybo,
    icsw.qtycommit,
    icsw.qtydemand,
    icsw.qtyonhand,
    icsw.qtyonorder,
    icsw.listprice::numeric(12,4) AS listprice,
    icsw.seasbegmm,
    icsw.seasendmm,
    upper(icsw.statustype::text)::character(1) AS statustype,
    icsw.usgmths,
    icsw.minhits,
    CURRENT_TIMESTAMP AS "lastUpdate"
   FROM icsw
  WHERE icsw.cono = 1
  ORDER BY (upper(icsw.prod::text)::character varying(24)), (icsw.whse::character(4))
WITH DATA;

-- View indexes:
CREATE UNIQUE INDEX mv_icsw_prod_whse_idx ON dev.mv_icsw USING btree (prod, whse);