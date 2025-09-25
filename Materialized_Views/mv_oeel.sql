-- First drop the indexes on the materialized view if they exist
DROP INDEX IF EXISTS dev.idx_mv_oeel_dctransdate;
DROP INDEX IF EXISTS dev.idx_mv_oeel_invoicedt;
DROP INDEX IF EXISTS dev.idx_mv_oeel_uniq;

-- Then drop the materialized view itself
DROP MATERIALIZED VIEW IF EXISTS dev.mv_oeel;

-- dev.mv_oeel source

CREATE MATERIALIZED VIEW dev.mv_oeel
TABLESPACE pg_default
AS SELECT COALESCE(oeel.invoicedt, '1990-01-01'::date) AS invoicedt,
    oeel.enterdt,
    oeel.orderno::character varying(12) AS orderno,
    oeel.ordersuf::smallint AS ordersuf,
    oeel.lineno::smallint AS lineno,
    oeel.custno,
    oeel.whse::character varying(4) AS whse,
    icsd.city::character varying(32) AS whsecity,
    upper(oeel.slsrepout::text)::character(4) AS slsrepout,
    upper(oeel.transtype::text)::character(2) AS transtype,
    upper(oeel.prodcat::text)::character(4) AS prodcat,
    upper(oeel.shipprod::text)::character varying(24) AS shipprod,
    oeel.price::numeric(12,4) AS price,
        CASE
            WHEN oeel.priceoverfl = 1 THEN true
            ELSE false
        END AS priceoverfl,
    round(oeel.qtyship *
        CASE
            WHEN oeel.returnfl = 1 THEN '-1'::integer
            ELSE 1
        END::numeric, 4)::numeric(12,4) AS qtyship,
    round(oeel.stkqtyship *
        CASE
            WHEN oeel.returnfl = 1 THEN '-1'::integer
            ELSE 1
        END::numeric, 4)::numeric(12,4) AS stkqtyship,
    upper(oeel.unit::text)::character varying(4) AS unit,
    oeel.unitconv,
    round(oeel.netamt *
        CASE
            WHEN oeel.returnfl = 1 THEN '-1'::integer
            ELSE 1
        END::numeric, 4)::numeric(12,4) AS netamt,
    round(oeel.prodcost * oeel.qtyship *
        CASE
            WHEN oeel.returnfl = 1 THEN '-1'::integer
            ELSE 1
        END::numeric, 4)::numeric(12,4) AS prodcost,
    upper(oeel.prodline::text)::character(6) AS prodline,
    oeel.vendno,
    COALESCE(( SELECT "SXFamilyGroup"."Short"
           FROM "SXFamilyGroup"
          WHERE SUBSTRING(oeel.prodline FROM 1 FOR 2) = "SXFamilyGroup"."Prefix"::text AND SUBSTRING(oeel.prodline FROM 4 FOR 3)::integer >= "SXFamilyGroup"."Low" AND SUBSTRING(oeel.prodline FROM 4 FOR 3)::integer <= "SXFamilyGroup"."High"
         LIMIT 1), 'UK'::bpchar)::character(2) AS famgrp,
    oeel.dctransdate::timestamp with time zone AS dctransdate,
    CURRENT_TIMESTAMP AS lastupdated
   FROM oeel
     LEFT JOIN icsd ON oeel.whse = icsd.whse
  WHERE oeel.cono = 1 AND (oeel.invoicedt >= (CURRENT_TIMESTAMP - '3 years'::interval) OR oeel.invoicedt IS NULL AND oeel.enterdt >= (CURRENT_TIMESTAMP - '3 years'::interval)) AND oeel.canceldt IS NULL AND icsd.salesfl = 1
  ORDER BY (oeel.orderno::character varying(12)), (oeel.ordersuf::smallint), (oeel.lineno::smallint)
WITH DATA;

-- View indexes:
CREATE INDEX idx_mv_oeel_dctransdate ON dev.mv_oeel USING btree (dctransdate DESC);
CREATE INDEX idx_mv_oeel_invoicedt ON dev.mv_oeel USING btree (invoicedt DESC);
CREATE UNIQUE INDEX idx_mv_oeel_uniq ON dev.mv_oeel USING btree (orderno, ordersuf, lineno);