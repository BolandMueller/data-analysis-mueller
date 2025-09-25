-- First drop the indexes on the materialized view if they exist
DROP INDEX IF EXISTS dev.idx_mv_oeeh_enterdt;
DROP INDEX IF EXISTS dev.idx_mv_oeeh_invoicedt;
DROP INDEX IF EXISTS dev.unq_mv_oeel_orderno;
DROP INDEX IF EXISTS dev.unq_mv_oetax_orderno;

-- Then drop the materialized view itself
DROP MATERIALIZED VIEW IF EXISTS dev.mv_oeeh;

-- dev.mv_oeeh source

CREATE MATERIALIZED VIEW dev.mv_oeeh
TABLESPACE pg_default
AS SELECT oeeh.orderno::character varying(12) AS orderno,
    oeeh.ordersuf::smallint AS ordersuf,
    upper(oeeh.takenby::text)::character(4) AS takenby,
    upper(oeeh.placedby::text)::character varying(10) AS placedby,
    oeeh.enterdt,
    oeeh.entertm,
    oeeh.promisedt,
    oeeh.shipdt,
    oeeh.invoicedt,
    oeeh.paiddt,
    oeeh.whse::character varying(4) AS whse,
    round(oeeh.specdiscamt *
        CASE
            WHEN upper(oeeh.transtype::text) = 'RM'::text THEN '-1'::integer
            ELSE 1
        END::numeric, 2)::numeric(9,2) AS specdiscamt,
    round(oeeh.wodiscamt *
        CASE
            WHEN upper(oeeh.transtype::text) = 'RM'::text THEN '-1'::integer
            ELSE 1
        END::numeric, 2)::numeric(9,2) AS wodiscamt,
    upper(oeeh.transtype::text)::character(2) AS transtype,
    upper(oeeh.shipviaty::text)::character varying(4) AS shipvia,
    upper(oeeh.slsrepout::text)::character(4) AS slsrepout,
    upper(oeeh.slsrepin::text)::character(4) AS slsrepin,
    oeeh.custno,
    upper(oeeh.shiptonm::text)::character varying(32) AS shiptonm,
    upper(oeeh.shiptoaddr_1::text)::character varying(32) AS shipto1,
    upper(oeeh.shiptocity::text)::character varying(32) AS shiptocity,
    upper(oeeh.shiptost::text)::character varying(32) AS shiptost,
    oeeh.shiptozip::character varying(32) AS shiptozip,
    oeeh.custpo::character varying(32) AS custpo,
    oeeh.stagecd::smallint AS stagecd,
        CASE
            WHEN oeeh.stagecd = 0 THEN 'ENTER'::text
            WHEN oeeh.stagecd = 1 THEN 'ORDER'::text
            WHEN oeeh.stagecd = 2 THEN 'PICK'::text
            WHEN oeeh.stagecd = 3 THEN 'SHIP'::text
            WHEN oeeh.stagecd = 4 THEN 'INVOICE'::text
            WHEN oeeh.stagecd = 5 THEN 'PAID'::text
            WHEN oeeh.stagecd = 9 THEN 'CANCEL'::text
            ELSE 'NOSTAGE'::text
        END AS stage,
    oeeh.nolineitem::smallint AS nolineitem,
    round(oeeh.totinvord *
        CASE
            WHEN upper(oeeh.transtype::text) = 'RM'::text THEN '-1'::integer
            ELSE 1
        END::numeric, 2)::numeric(9,2) AS totinvord,
    round(oeeh.totprice *
        CASE
            WHEN upper(oeeh.transtype::text) = 'RM'::text THEN '-1'::integer
            ELSE 1
        END::numeric, 2)::numeric(9,2) AS totprice,
    round(oeeh.totcost *
        CASE
            WHEN upper(oeeh.transtype::text) = 'RM'::text THEN '-1'::integer
            ELSE 1
        END::numeric, 2)::numeric(9,2) AS totcost,
    CURRENT_TIMESTAMP AS "lastUpdate"
   FROM oeeh
     LEFT JOIN icsd ON icsd.whse = oeeh.whse
  WHERE oeeh.cono = 1 AND oeeh.enterdt >= (CURRENT_TIMESTAMP - '3 years'::interval) AND icsd.salesfl = 1 AND upper(oeeh.transtype::text) <> 'QU'::text AND oeeh.stagecd <> 9
  ORDER BY (oeeh.orderno::character varying(12)), (oeeh.ordersuf::smallint)
WITH DATA;

-- View indexes:
CREATE INDEX idx_mv_oeeh_enterdt ON dev.mv_oeeh USING btree (enterdt DESC);
CREATE INDEX idx_mv_oeeh_invoicedt ON dev.mv_oeeh USING btree (invoicedt DESC);
CREATE UNIQUE INDEX unq_mv_oeel_orderno ON dev.mv_oeeh USING btree (orderno, ordersuf);
CREATE UNIQUE INDEX unq_mv_oetax_orderno ON dev.mv_oeeh USING btree (orderno, ordersuf);