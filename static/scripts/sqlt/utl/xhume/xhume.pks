CREATE OR REPLACE PACKAGE xhume AUTHID DEFINER AS
/* $Header: xhume/xhume.pks 11.4.3.7 2011/10/10 carlos.sierra $ */

  /* -------------------------
   *
   * public types
   *
   * ------------------------- */
  TYPE varchar2_table IS TABLE OF VARCHAR2(2000);

  /* -------------------------
   *
   * create_xhume_script
   *
   * generates another which is used to discover
   * plans by exhumating TC schema objects stats.
   *
   * ------------------------- */
  PROCEDURE create_xhume_script;

  /* -------------------------
   *
   * snapshot_plan
   *
   * executed by the xhume script created by
   * create_xhume_script, this api takes a
   * snapshot of the plan for each test and
   * stores it into xhume_discovered_plan and
   * xhume_sql_plan_statistics_all.
   * the former is used by the xhume_report,
   * while the latter is used in case a more
   * detailed query is needed for example in
   * predicates. it also creates the results
   * of the test into xhume_test for each run.
   *
   * ------------------------- */
  PROCEDURE snapshot_plan (p_unique_id IN VARCHAR2);

  /* -------------------------
   *
   * generate_xhume_report
   *
   * it simply generates the xhume report
   * out of the data on xhume_test and
   * xhume_discovered_plan.
   *
   * ------------------------- */
  FUNCTION generate_xhume_report (p_run_id IN NUMBER)
  RETURN varchar2_table PIPELINED;

END xhume;
/

SHOW ERRORS;
