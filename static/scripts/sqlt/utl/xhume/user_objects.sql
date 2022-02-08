REM $Header: xhume/user_objects.sql 12.2.171004 October 4th, 2017 carlos.sierra abel.macias@oracle.com $

-- 171004 Extensive replacement of variables to varchar2(257)

DROP SEQUENCE xhume_line_id;
CREATE SEQUENCE xhume_line_id;

/* -------------------------
 *
 * xhume_table
 *
 * tc tables that are having their stats
 * exhumated to discover plans that may
 * had been possible.
 *
 * ------------------------- */
DROP TABLE xhume_table;
CREATE TABLE xhume_table (
  owner      VARCHAR2(257),
  table_name VARCHAR2(257),
  created_st DATE, -- object creation as per the oldest set of stats (timestamp of oldest stats rec)
  created_tc DATE, -- object creation at the test case system and under tc user
  obj#       NUMBER );

/* -------------------------
 *
 * xhume_test
 *
 * when inserted by the create_xhume_script
 * this table contains a template of the tests
 * that will be performed. then when snapshot_plan
 * takes place an instance of each test is also
 * inserted and identified by run_id (plus test_id
 * and baseline_id). this new instance for each
 * test captures details about the actual test,
 * which are later reported.
 *
 * ------------------------- */
DROP TABLE xhume_test;
CREATE TABLE xhume_test (
  run_id                     NUMBER,
  test_id                    NUMBER,
  unique_id                  VARCHAR2(32),
  xhume_time                 TIMESTAMP(9) WITH TIME ZONE,
  xhume_table_name           VARCHAR2(257),
  xhume_command              VARCHAR2(4000),
  restore_ok                 CHAR(1), -- Y/N
  tables_with_stats          NUMBER,
  plan_hash_value            NUMBER,
  plan_cost                  NUMBER,
  buffer_gets                NUMBER,
  cpu_time                   NUMBER,
  disk_reads                 NUMBER,
  elapsed_time               NUMBER,
  rows_processed             NUMBER,
  sql_id                     VARCHAR2(13),
  child_number               NUMBER,
  cardinality                NUMBER,
  sqlt_plan_hash_value       NUMBER,
  sqlt_plan_hash_value2      NUMBER
);

/* -------------------------
 *
 * xhume_discovered_plan
 *
 * snapshot_plan inserts into this table
 * storing a plan for each test on every
 * execution of the script created by the
 * create_xhume_script.
 *
 * ------------------------- */
DROP TABLE xhume_discovered_plan;
CREATE TABLE xhume_discovered_plan (
  run_id                     NUMBER,
  test_id                    NUMBER,
  line_id                    NUMBER, -- xhume_line_id
  plan_table_output          VARCHAR2(300)
);

/* -------------------------
 *
 * xhume_sql_plan_statistics_all
 *
 * snapshot_plan inserts into this table
 * storing a plan for each test on every
 * execution of the script created by the
 * create_xhume_script.
 *
 * ------------------------- */
DROP TABLE xhume_sql_plan_statistics_all;
CREATE TABLE xhume_sql_plan_statistics_all AS
SELECT * FROM v$sql_plan_statistics_all
WHERE 1 = 2;
ALTER TABLE xhume_sql_plan_statistics_all ADD (
  run_id                     NUMBER,
  test_id                    NUMBER,
  sqlt_plan_hash_value       NUMBER,
  sqlt_plan_hash_value2      NUMBER
);
