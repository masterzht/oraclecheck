CREATE OR REPLACE PACKAGE &&tool_administer_schema..sqlt$d AUTHID DEFINER AS
/* $Header: 215187.1 sqcpkgd.pks 12.1.11 2014/30/10 carlos.sierra mauro.pagano abel.macias@oracle.com $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * public constants
   *
   * ------------------------- */
  TOOL_REPOSITORY_SCHEMA CONSTANT VARCHAR2(32)    := '&&tool_repository_schema.';
  TOOL_ADMINISTER_SCHEMA CONSTANT VARCHAR2(32)    := '&&tool_administer_schema.';
  PLAN_FORMAT_A          CONSTANT VARCHAR2(128)   := 'ADVANCED ALLSTATS';
  PLAN_FORMAT_A12        CONSTANT VARCHAR2(128)   := 'ADVANCED ALLSTATS REPORT ADAPTIVE';
  PLAN_FORMAT_V          CONSTANT VARCHAR2(128)   := 'ADVANCED';
  PLAN_FORMAT_V12        CONSTANT VARCHAR2(128)   := 'ADVANCED REPORT ADAPTIVE';
  --PLAN_FORMAT_L          CONSTANT VARCHAR2(128)   := 'TYPICAL ALLSTATS LAST -PREDICATE -NOTE';
  PLAN_FORMAT_L          CONSTANT VARCHAR2(128)   := 'ADVANCED ALLSTATS LAST';
  PLAN_FORMAT_L12        CONSTANT VARCHAR2(128)   := 'ADVANCED ALLSTATS LAST REPORT ADAPTIVE';

  /*************************************************************************************/

  /* -------------------------
   *
   * static variables
   *
   * ------------------------- */

-- 142810 relocates pq_tqstat insert and select variables to private

  /*************************************************************************************/

  /* -------------------------
   *
   * public apis
   *
   * ------------------------- */

  PROCEDURE capture_sqltext (
    p_statement_id         IN NUMBER,
    p_string               IN VARCHAR2,
    p_sql_id_or_hash_value IN VARCHAR2,
    p_child_number         IN VARCHAR2 DEFAULT NULL,
    p_input_filename       IN VARCHAR2 DEFAULT NULL );

  PROCEDURE capture_xplain_plan_hash_value (
    p_statement_id IN NUMBER,
    p_string       IN VARCHAR2 );

  PROCEDURE collect_dba_hist_sql_plan (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 );

  PROCEDURE collect_dba_hist_sqlbind (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 );

  PROCEDURE collect_dba_hist_sqlstat (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 );

  PROCEDURE collect_dba_hist_sqltext (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 );

  PROCEDURE collect_cellstate_xtract (p_statement_id IN NUMBER);

  PROCEDURE collect_gv$parameter_cbo (p_statement_id IN NUMBER);

-- 141028 removed p_insert_list and p_select_list
  PROCEDURE collect_gv$pq_tqstat (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2);

  PROCEDURE collect_gv$sql_bind_capture (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER );

  PROCEDURE collect_gv$sql_optimizer_env (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER );

  PROCEDURE collect_gv$sqlarea_plan_hash (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 );

  PROCEDURE collect_gv$sqlstats_plan_hash (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 );

  PROCEDURE collect_gv$sql (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER );

  PROCEDURE collect_gv$sqlarea (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER );

  PROCEDURE collect_gv$sql_plan (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER );

  PROCEDURE collect_gv$sql_plan_statistics (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER );

  PROCEDURE collect_plan_extensions (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 );	

  PROCEDURE collect_perf_stats_begin (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sid          IN NUMBER );

  PROCEDURE collect_perf_stats_end (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sid          IN NUMBER );

  PROCEDURE collect_perf_stats_post (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 );

  PROCEDURE collect_perf_stats_pre;

  PROCEDURE collect_px_perf_stats (p_statement_id IN NUMBER);

  PROCEDURE collect_sesstat_xtract (
    p_statement_id            IN NUMBER,
    p_begin_end_flag          IN VARCHAR2 );

  PROCEDURE diagnostics_data_collection_1 (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE diagnostics_data_collection_2 (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER DEFAULT NULL );

  PROCEDURE get_list_of_columns (
    p_source_owner      IN  VARCHAR2 DEFAULT 'SYS',
    p_source_table      IN  VARCHAR2,
    p_source_alias      IN  VARCHAR2 DEFAULT NULL,
    p_destination_owner IN  VARCHAR2 DEFAULT TOOL_REPOSITORY_SCHEMA,
    p_destination_table IN  VARCHAR2,
    x_insert_list       OUT VARCHAR2,
    x_select_list       OUT VARCHAR2 );

  PROCEDURE list_of_indexes (p_statement_id IN NUMBER);

  FUNCTION max_plan_elapsed_time_secs (p_statement_id IN NUMBER)
  RETURN NUMBER;

  PROCEDURE one_plan_per_hv_mem (p_statement_id IN NUMBER);

  PROCEDURE search_sql_by_sqltext (p_statement_id IN NUMBER);

  /*************************************************************************************/

END sqlt$d;
/

SET TERM ON;
SHOW ERRORS PACKAGE &&tool_administer_schema..sqlt$d;
