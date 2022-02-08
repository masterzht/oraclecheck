CREATE OR REPLACE PACKAGE xplore AUTHID DEFINER AS
/* $Header: xplore/xplore.pks 11.4.3.7 2011/10/10 carlos.sierra $ */

  /* -------------------------
   *
   * public types
   *
   * ------------------------- */
  TYPE varchar2_table IS TABLE OF VARCHAR2(2000);

  /* -------------------------
   *
   * set_baseline
   *
   * executed by the script created by the
   * create_xplore_script, this api is executed
   * just before each test. it restores the cbo
   * env as captured by the create_xplore_script
   * into baseline_parameter_cbo.
   *
   * ------------------------- */
  PROCEDURE set_baseline (
    p_baseline_id IN INTEGER );

  /* -------------------------
   *
   * create_xplore_script
   *
   * in one hand this script generates another
   * which is used to discover plans. in the
   * other hand it takes a snapshot of the cbo
   * enviornment and stores it as a baseline.
   * the snaphot includes cbo parameters, fix
   * control and metadata parameters. this
   * baseline is restored just before each test.
   * the content of the baseline is restriced
   * by execution parameters: cbo, fix_ctrl and
   * exadata.
   *
   * ------------------------- */
  PROCEDURE create_xplore_script (
    p_xplore_method      IN VARCHAR2 DEFAULT 'XECUTE',
    p_cbo_parameters     IN VARCHAR2 DEFAULT 'Y',
    p_exadata_parameters IN VARCHAR2 DEFAULT 'Y',
    p_fix_control        IN VARCHAR2 DEFAULT 'Y',
    p_sql_monitor        IN VARCHAR2 DEFAULT 'N' );

  /* -------------------------
   *
   * create_monitor_script
   *
   * called by the xplore_script, this api
   * produces a script that generates the
   * sql monitor reports for each sql
   * in the test set.
   *
   * ------------------------- */
  PROCEDURE create_monitor_script (
    p_baseline_id IN NUMBER );

  /* -------------------------
   *
   * snapshot_plan
   *
   * executed by the xplore script created by
   * create_xplore_script, this api takes a
   * snapshot of the plan for each test and into
   * discovered_plan and sql_plan_statistics_all.
   * the former is used by the xplore_report,
   * while the latter is used in case a more
   * detailed query is needed for example in
   * predicates. it also creates the results
   * of the test into xplore_test for each run.
   *
   * ------------------------- */
  PROCEDURE snapshot_plan (
    p_unique_id     IN VARCHAR2,
    p_xplore_method IN VARCHAR2 DEFAULT 'XECUTE',
    p_sql_monitor   IN VARCHAR2 DEFAULT 'N' );

  /* -------------------------
   *
   * generate_xplore_report
   *
   * it simply generates the xplore report
   * out of the data on xplore_test and
   * discovered_plan.
   *
   * ------------------------- */
  FUNCTION generate_xplore_report (
    p_baseline_id IN NUMBER,
    p_run_id      IN NUMBER )
  RETURN varchar2_table PIPELINED;

END xplore;
/

SHOW ERRORS;
