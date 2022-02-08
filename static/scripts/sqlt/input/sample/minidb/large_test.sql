CONN &&user./&&user.

SPO test_large.log;

SET PAGES 1000 LINES 300 TRIMS ON;
SET DEF ON ECHO ON VER ON;

ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 12';
ALTER SYSTEM SET "_cursor_bind_capture_interval" = 10;

VAR b1 VARCHAR2(1);

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

EXEC dbms_workload_repository.create_snapshot;

-- baseline

EXEC :b1 := '0';
@t.sql

EXEC :b1 := '2';
@t.sql

EXEC :b1 := '3';
@t.sql

EXEC :b1 := '4';
@t.sql

EXEC :b1 := '5';
@t.sql

EXEC :b1 := '6';
@t.sql

EXEC :b1 := '7';
@t.sql

EXEC dbms_workload_repository.create_snapshot;

-- gather statistics

EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'customer');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'part');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'sales_order');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'order_line');

-- new baseline

EXEC :b1 := '0';
@t.sql

EXEC :b1 := '2';
@t.sql

EXEC :b1 := '3';
@t.sql

EXEC :b1 := '4';
@t.sql

EXEC :b1 := '5';
@t.sql

EXEC :b1 := '6';
@t.sql

EXEC :b1 := '7';
@t.sql

EXEC dbms_workload_repository.create_snapshot;

-- bind variable graduation: 1-32, 33-128, 129-2000, 2001+

VAR b1 VARCHAR2(33);

EXEC :b1 := '3';
@t.sql

EXEC :b1 := '4';
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
@t.sql
@t.sql

VAR b1 VARCHAR2(129);

EXEC :b1 := '6';
@t.sql
@t.sql
@t.sql
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
@t.sql
@t.sql
@t.sql

EXEC :b1 := '4';
@t.sql
@t.sql
@t.sql

VAR b1 VARCHAR2(2001);

EXEC :b1 := '1';
@t.sql

EXEC :b1 := '2';
@t.sql

EXEC :b1 := '3';
@t.sql

VAR b1 VARCHAR2(1);

EXEC dbms_workload_repository.create_snapshot;

-- optimizer_index_cost_adjustment

ALTER SESSION SET optimizer_index_cost_adj = 1;

EXEC :b1 := '3';
@t.sql

EXEC :b1 := '4';
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
@t.sql
@t.sql

ALTER SESSION SET optimizer_index_cost_adj = 10000;

EXEC :b1 := '6';
@t.sql
@t.sql
@t.sql
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
@t.sql
@t.sql
@t.sql

EXEC :b1 := '4';
@t.sql
@t.sql
@t.sql

ALTER SESSION SET optimizer_index_cost_adj = 100;

EXEC :b1 := '1';
@t.sql

EXEC :b1 := '2';
@t.sql

EXEC :b1 := '3';
@t.sql

EXEC dbms_workload_repository.create_snapshot;

-- complex view merging

ALTER SESSION SET "_complex_view_merging" = FALSE;

EXEC :b1 := '3';
@t.sql

EXEC :b1 := '4';
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
@t.sql
@t.sql

ALTER SESSION SET "_complex_view_merging" = TRUE;

EXEC dbms_workload_repository.create_snapshot;

-- unnest subquery

ALTER SESSION SET "_unnest_subquery" = FALSE;

EXEC :b1 := '3';
@t.sql

EXEC :b1 := '4';
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
@t.sql
@t.sql

ALTER SESSION SET "_unnest_subquery" = TRUE;

EXEC dbms_workload_repository.create_snapshot;

-- first rows mode

ALTER SESSION SET optimizer_mode = FIRST_ROWS_1;

EXEC :b1 := '3';
@t.sql

EXEC :b1 := '4';
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
@t.sql
@t.sql

ALTER SESSION SET optimizer_mode = ALL_ROWS;

EXEC dbms_workload_repository.create_snapshot;

-- parallel execution

ALTER SESSION FORCE PARALLEL QUERY;

EXEC :b1 := '2';
@t.sql

EXEC :b1 := '1';
@t.sql
@t.sql

EXEC :b1 := '3';
@t.sql
@t.sql
@t.sql

ALTER SESSION DISABLE PARALLEL QUERY;

EXEC dbms_workload_repository.create_snapshot;

-- ofe 10.2.0.5

ALTER SESSION SET optimizer_features_enable = '10.2.0.5';

EXEC :b1 := '3';
@t.sql

EXEC :b1 := '4';
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
@t.sql
@t.sql

EXEC dbms_workload_repository.create_snapshot;

-- ofe 9.2.0.8

ALTER SESSION SET optimizer_features_enable = '9.2.0.8';

EXEC :b1 := '3';
@t.sql

EXEC :b1 := '4';
@t.sql
@t.sql

EXEC :b1 := '5';
@t.sql
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
