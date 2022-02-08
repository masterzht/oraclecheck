CONN &&user./&&user.

SPO test_small.log;

SET PAGES 1000 LINES 300 TRIMS ON;
SET DEF ON ECHO ON VER ON;

ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 12';
ALTER SYSTEM SET "_cursor_bind_capture_interval" = 10;

VAR b1 VARCHAR2(1);
EXEC :b1 := '4';

SELECT /*+ gather_plan_statistics monitor bind_aware */
       v.customer_name,
       v.orders_total,
       v.credit_limit,
       (orders_total - credit_limit) over_limit
  FROM customer_v v
 WHERE orders_total > credit_limit
   AND customer_type = :b1
 ORDER BY
       over_limit DESC;

SAVE t.sql REPLACE

SELECT sql_id, sql_text FROM v$sql WHERE sql_text LIKE 'SELECT /*+ gather_plan_statistics monitor bind_aware */%';

-- f995z9antmhxn
-- @run/sqltxtract f995z9antmhxn sqltxplain
-- @run/sqlhc T f995z9antmhxn
-- @run/sqldx T B f995z9antmhxn

EXEC dbms_workload_repository.create_snapshot;

-- baseline

EXEC :b1 := '1';
@t.sql
@t.sql

EXEC :b1 := '3';
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
@t.sql

EXEC :b1 := '7';
@t.sql
@t.sql

EXEC dbms_workload_repository.create_snapshot;

-- optimizer_index_cost_adjustment

ALTER SESSION SET optimizer_index_cost_adj = 1;

EXEC :b1 := '3';
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
@t.sql

ALTER SESSION SET optimizer_index_cost_adj = 10000;

EXEC :b1 := '6';
@t.sql
@t.sql

EXEC :b1 := '4';
@t.sql
@t.sql

ALTER SESSION SET optimizer_index_cost_adj = 100;

EXEC :b1 := '1';
@t.sql
@t.sql

EXEC :b1 := '2';
@t.sql
@t.sql

EXEC dbms_workload_repository.create_snapshot;

-- end

ALTER SYSTEM SET "_cursor_bind_capture_interval" = 900;
ALTER SESSION SET SQL_TRACE = FALSE;

SET PAGES 14 LINES 80 TRIMS OFF;
SET DEF ON ECHO OFF VER OFF;

SPO OFF;

PRO sqlplus qtune/qtune @run/sqltxtract f995z9antmhxn sqltxplain
