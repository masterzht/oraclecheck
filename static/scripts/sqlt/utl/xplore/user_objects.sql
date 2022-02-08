REM $Header: xplore/user_objects.sql 11.4.3.5 2011/08/10 carlos.sierra $

-- 171004 Extensive replacement of variables to varchar2(257)

DROP SEQUENCE xplore_line_id;
CREATE SEQUENCE xplore_line_id;

/* -------------------------
 *
 * baseline_parameter_cbo
 *
 * contains a restricted set of cbo parameters,
 * fix control and exadata parameters captured
 * from the session at the time create_xplore_script
 * is executed. this set becomes the baseline which
 * is restored just before ecah test takes place.
 * its content is restricted as per execution
 * parameters: cbo, fix_ctrl and exadata.
 *
 * ------------------------- */
DROP TABLE baseline_parameter_cbo;
CREATE TABLE baseline_parameter_cbo
(
  baseline_id                NUMBER,
  name                       VARCHAR2(80),
  type                       NUMBER,
  value                      VARCHAR2(4000),
  display_value              VARCHAR2(4000),
  isdefault                  VARCHAR2(9),
  isses_modifiable           VARCHAR2(5),
  issys_modifiable           VARCHAR2(9),
  ismodified                 VARCHAR2(10)
);

/* -------------------------
 *
 * xplore_test
 *
 * when inserted by the create_xplore_script
 * this table contains a template of the tests
 * that will be performed. then when snapshot_plan
 * takes place an instance of each test is also
 * inserted and identified by run_id (plus test_id
 * and baseline_id). this new instance for each
 * test captures details about the actual test,
 * which are later reported.
 *
 * ------------------------- */
DROP TABLE xplore_test;
CREATE TABLE xplore_test (
  baseline_id                NUMBER,
  run_id                     NUMBER,
  test_id                    NUMBER,
  unique_id                  VARCHAR2(32),
  name                       VARCHAR2(80),
  test                       VARCHAR2(512),
  baseline_value             VARCHAR2(512),
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
 * discovered_plan
 *
 * snapshot_plan inserts into this table
 * storing a plan for each test on every
 * execution of the script created by the
 * create_xplore_script.
 *
 * ------------------------- */
DROP TABLE discovered_plan;
CREATE TABLE discovered_plan (
  baseline_id                NUMBER,
  run_id                     NUMBER,
  test_id                    NUMBER,
  line_id                    NUMBER, -- xplore_line_id
  plan_table_output          VARCHAR2(300)
);

/* -------------------------
 *
 * sql_plan_statistics_all
 *
 * snapshot_plan inserts into this table
 * storing a plan for each test on every
 * execution of the script created by the
 * create_xplore_script. XECUTE method.
 *
 * ------------------------- */
DROP TABLE sql_plan_statistics_all;
CREATE TABLE sql_plan_statistics_all AS
SELECT * FROM v$sql_plan_statistics_all
WHERE 1 = 2;
ALTER TABLE sql_plan_statistics_all ADD (
  baseline_id                NUMBER,
  run_id                     NUMBER,
  test_id                    NUMBER,
  sqlt_plan_hash_value       NUMBER,
  sqlt_plan_hash_value2      NUMBER
);

DROP INDEX sql_plan_statistics_all_n1;
CREATE INDEX sql_plan_statistics_all_n1 ON sql_plan_statistics_all
(baseline_id, run_id, test_id);

/* -------------------------
 *
 * plan_table_all
 *
 * snapshot_plan inserts into this table
 * storing a plan for each test on every
 * execution of the script created by the
 * create_xplore_script. XPLAIN method.
 *
 * ------------------------- */
DROP TABLE plan_table_all;
CREATE TABLE plan_table_all (
statement_id VARCHAR2(30) NOT NULL
);
ALTER TABLE plan_table_all ADD (plan_id                  NUMBER);
ALTER TABLE plan_table_all ADD (timestamp                DATE);
ALTER TABLE plan_table_all ADD (remarks                  VARCHAR2(4000));
ALTER TABLE plan_table_all ADD (operation                VARCHAR2(30));
ALTER TABLE plan_table_all ADD (options                  VARCHAR2(255));
ALTER TABLE plan_table_all ADD (object_node              VARCHAR2(128));
ALTER TABLE plan_table_all ADD (object_owner             VARCHAR2(257));
ALTER TABLE plan_table_all ADD (object_name              VARCHAR2(257));
ALTER TABLE plan_table_all ADD (object_alias             VARCHAR2(65));
ALTER TABLE plan_table_all ADD (object_instance          NUMBER);
ALTER TABLE plan_table_all ADD (object_type              VARCHAR2(30));
ALTER TABLE plan_table_all ADD (optimizer                VARCHAR2(255));
ALTER TABLE plan_table_all ADD (search_columns           NUMBER);
ALTER TABLE plan_table_all ADD (id                       NUMBER);
ALTER TABLE plan_table_all ADD (parent_id                NUMBER);
ALTER TABLE plan_table_all ADD (depth                    NUMBER);
ALTER TABLE plan_table_all ADD (position                 NUMBER);
ALTER TABLE plan_table_all ADD (cost                     NUMBER);
ALTER TABLE plan_table_all ADD (cardinality              NUMBER);
ALTER TABLE plan_table_all ADD (bytes                    NUMBER);
ALTER TABLE plan_table_all ADD (other_tag                VARCHAR2(255));
ALTER TABLE plan_table_all ADD (partition_start          VARCHAR2(255));
ALTER TABLE plan_table_all ADD (partition_stop           VARCHAR2(255));
ALTER TABLE plan_table_all ADD (partition_id             NUMBER);
ALTER TABLE plan_table_all ADD (other                    CLOB);
ALTER TABLE plan_table_all ADD (other_xml                CLOB);
ALTER TABLE plan_table_all ADD (distribution             VARCHAR2(30));
ALTER TABLE plan_table_all ADD (cpu_cost                 NUMBER);
ALTER TABLE plan_table_all ADD (io_cost                  NUMBER);
ALTER TABLE plan_table_all ADD (temp_space               NUMBER);
ALTER TABLE plan_table_all ADD (access_predicates        VARCHAR2(4000));
ALTER TABLE plan_table_all ADD (filter_predicates        VARCHAR2(4000));
ALTER TABLE plan_table_all ADD (projection               VARCHAR2(4000));
ALTER TABLE plan_table_all ADD (time                     NUMBER);
ALTER TABLE plan_table_all ADD (qblock_name              VARCHAR2(30));

DROP INDEX plan_table_all_n1;
CREATE INDEX plan_table_all_n1 ON plan_table_all
(statement_id);

/* -------------------------
 *
 * sql_monitor
 *
 * snapshot_plan inserts into this table
 * storing a sql_monitor report for each
 * test on every execution of the script
 * created by the create_xplore_script.
 *
 * ------------------------- */
DROP TABLE sql_monitor;
CREATE TABLE sql_monitor (
  baseline_id                NUMBER,
  run_id                     NUMBER,
  test_id                    NUMBER,
  active_report              CLOB
);
