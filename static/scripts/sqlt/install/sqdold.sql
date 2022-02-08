SET ECHO ON TERM OFF;
REM
REM $Header: 215187.1 sqdold.sql 11.4.5.5 2013/03/01 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/install/sqdold.sql
REM
REM DESCRIPTION
REM   Drops deprecated old SQLTXPLAIN schema objects from SQLT tool.
REM
REM PRE-REQUISITES
REM   1. To drop deprecated SQLTXPLAIN objects you must connect
REM      as SYSDBA.
REM
REM PARAMETERS
REM   1. None
REM
REM EXECUTION
REM   1. Navigate to sqlt/install directory
REM   2. Start SQL*Plus connecting as SYSDBA
REM   3. Execute script sqdold.sql
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqdold.sql
REM
REM NOTES
REM   1. This script is executed automatically by sqdrop.sql
REM      and sqcreate.sql
REM
@@sqcommon1.sql

WHENEVER SQLERROR CONTINUE;
SET ECHO ON TERM OFF;

/* - sqlt packages that used to belong to sqltxplain and now belong to sqltxadmin - */
DROP PACKAGE BODY &&tool_repository_schema..sqlt$a;
DROP PACKAGE BODY &&tool_repository_schema..sqlt$c;
DROP PACKAGE BODY &&tool_repository_schema..sqlt$d;
DROP PACKAGE BODY &&tool_repository_schema..sqlt$e;
DROP PACKAGE BODY &&tool_repository_schema..sqlt$h;
DROP PACKAGE BODY &&tool_repository_schema..sqlt$i;
DROP PACKAGE BODY &&tool_repository_schema..sqlt$m;
DROP PACKAGE BODY &&tool_repository_schema..sqlt$s;
DROP PACKAGE BODY &&tool_repository_schema..sqlt$r;
DROP PACKAGE BODY &&tool_repository_schema..sqlt$t;
DROP PACKAGE BODY &&tool_repository_schema..trca$e;
DROP PACKAGE BODY &&tool_repository_schema..trca$g;
DROP PACKAGE BODY &&tool_repository_schema..trca$i;
DROP PACKAGE BODY &&tool_repository_schema..trca$p;
DROP PACKAGE BODY &&tool_repository_schema..trca$r;
DROP PACKAGE BODY &&tool_repository_schema..trca$t;
DROP PACKAGE BODY &&tool_repository_schema..trca$x;
DROP PACKAGE      &&tool_repository_schema..sqlt$a;
DROP PACKAGE      &&tool_repository_schema..sqlt$c;
DROP PACKAGE      &&tool_repository_schema..sqlt$d;
DROP PACKAGE      &&tool_repository_schema..sqlt$e;
DROP PACKAGE      &&tool_repository_schema..sqlt$h;
DROP PACKAGE      &&tool_repository_schema..sqlt$i;
DROP PACKAGE      &&tool_repository_schema..sqlt$m;
DROP PACKAGE      &&tool_repository_schema..sqlt$r;
DROP PACKAGE      &&tool_repository_schema..sqlt$s;
DROP PACKAGE      &&tool_repository_schema..sqlt$t;
DROP PACKAGE      &&tool_repository_schema..trca$e;
DROP PACKAGE      &&tool_repository_schema..trca$g;
DROP PACKAGE      &&tool_repository_schema..trca$i;
DROP PACKAGE      &&tool_repository_schema..trca$p;
DROP PACKAGE      &&tool_repository_schema..trca$r;
DROP PACKAGE      &&tool_repository_schema..trca$t;
DROP PACKAGE      &&tool_repository_schema..trca$x;

/* - procedures that used to belong to sqltxplain and now are deprecated - */
DROP PROCEDURE &&tool_repository_schema..sqlt$migrate;

/* - sqlt views that used to belong to sqltxplain and now belong to sqltxadmin - */
DROP VIEW &&tool_repository_schema..sqlt$_captured_binds_sum_v;
DROP VIEW &&tool_repository_schema..sqlt$_captured_binds_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_act_sess_hist_p;
DROP VIEW &&tool_repository_schema..sqlt$_dba_act_sess_hist_pl;
DROP VIEW &&tool_repository_schema..sqlt$_dba_all_table_cols_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_all_tables_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_col_stats_versions_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_hist_sqlstat_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_ind_columns_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_ind_statistics_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_ind_stats_versions_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_indexes_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_stat_extensions_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_tab_col_statistics_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_tab_histograms_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_tab_statistics_v;
DROP VIEW &&tool_repository_schema..sqlt$_dba_tab_stats_versions_v;
DROP VIEW &&tool_repository_schema..sqlt$_dependencies_v;
DROP VIEW &&tool_repository_schema..sqlt$_gv$act_sess_hist_p;
DROP VIEW &&tool_repository_schema..sqlt$_gv$act_sess_hist_pl;
DROP VIEW &&tool_repository_schema..sqlt$_gv$cell_state_v;
DROP VIEW &&tool_repository_schema..sqlt$_gv$object_dependency_v;
DROP VIEW &&tool_repository_schema..sqlt$_gv$pq_sysstat_v;
DROP VIEW &&tool_repository_schema..sqlt$_gv$px_process_sysstat_v;
DROP VIEW &&tool_repository_schema..sqlt$_gv$px_sesstat_v;
DROP VIEW &&tool_repository_schema..sqlt$_gv$segment_statistics_v;
DROP VIEW &&tool_repository_schema..sqlt$_gv$session_event_v;
DROP VIEW &&tool_repository_schema..sqlt$_gv$sesstat_v;
DROP VIEW &&tool_repository_schema..sqlt$_log_v;
DROP VIEW &&tool_repository_schema..sqlt$_peeked_binds_sum_v;
DROP VIEW &&tool_repository_schema..sqlt$_peeked_binds_v;
DROP VIEW &&tool_repository_schema..sqlt$_plan_statistics_v;
DROP VIEW &&tool_repository_schema..sqlt$_plan_stats_v;
DROP VIEW &&tool_repository_schema..sqlt$_plan_summary_v2;
DROP VIEW &&tool_repository_schema..sqlt$_plan_summary_v;
DROP VIEW &&tool_repository_schema..sqlt$_sql_profile_hints_v;
DROP VIEW &&tool_repository_schema..sqlt$_sql_shared_cursor_v;
DROP VIEW &&tool_repository_schema..sqlt$_wri$_optstat_aux_hist_v;

/* - old synonyms created by very old versions of XPLORE - */
DROP PUBLIC SYNONYM v$parameter_exadata;
DROP PUBLIC SYNONYM v$parameter_cbo;
DROP PUBLIC SYNONYM v$parameter_lov;

/* - old views created by very old versions of XPLORE - */
DROP VIEW sys.v$parameter_exadata;
DROP VIEW sys.v$parameter_cbo;
DROP VIEW sys.v$parameter_lov;

/* - very old sqlt packages - */
DROP PACKAGE BODY &&tool_repository_schema..sqlt$p;
DROP PACKAGE      &&tool_repository_schema..sqlt$p;

/* - very old sqlt procedures - */
DROP PROCEDURE &&tool_repository_schema..sqlt$_execute_tuning_task;

/* - very old sys views created and used only by sqlt - */
DROP VIEW sys.dba_col_stats_versions;
DROP VIEW sys.dba_col_usage$;
DROP VIEW sys.dba_histgrm_stats_versions;
DROP VIEW sys.dba_ind_stats_versions;
DROP VIEW sys.dba_tab_stats_versions;
DROP VIEW sys.gv$parameter_cbo;
DROP VIEW sys.my_v$session;
DROP VIEW sys.sqlt$_gv$parameter_cbo;

/* - old deprecated sqlt views - */
DROP VIEW &&tool_repository_schema..log;
DROP VIEW &&tool_repository_schema..sqlg$_join_order_v1;
DROP VIEW &&tool_repository_schema..sqlg$_join_order_v2;
DROP VIEW &&tool_repository_schema..sqlt$_dba_ind_statistics;
DROP VIEW &&tool_repository_schema..sqlt$_dba_outline_hints;
DROP VIEW &&tool_repository_schema..sqlt$_dba_outline_nodes;
DROP VIEW &&tool_repository_schema..sqlt$_dba_outlines;
DROP VIEW &&tool_repository_schema..sqlt$_dba_part_col_stats;
DROP VIEW &&tool_repository_schema..sqlt$_dba_segments;
DROP VIEW &&tool_repository_schema..sqlt$_dba_subpart_col_stats;
DROP VIEW &&tool_repository_schema..sqlt$_dba_tab_col_statistics;
DROP VIEW &&tool_repository_schema..sqlt$_dba_tab_cols;
DROP VIEW &&tool_repository_schema..sqlt$_dba_tab_statistics;
DROP VIEW &&tool_repository_schema..sqlt$_gv$parameter2;
DROP VIEW &&tool_repository_schema..sqlt$_gv$sql;
DROP VIEW &&tool_repository_schema..sqlt$_gv$sql_plan;
DROP VIEW &&tool_repository_schema..sqlt$_gv$sql_plan_statistics;
DROP VIEW &&tool_repository_schema..sqlt$_gv$sql_workarea;
DROP VIEW &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines;
DROP VIEW &&tool_repository_schema..sqlt$_gv$system_parameter2;
DROP VIEW &&tool_repository_schema..sqlt$_sql_baseline_hints_v;
DROP VIEW &&tool_repository_schema..sqlt$_v$session;
DROP VIEW &&tool_repository_schema..sqlt$_v$sql;
DROP VIEW &&tool_repository_schema..sqlt$_v$sql_plan;
DROP VIEW &&tool_repository_schema..sqlt$_v$sql_plan_statistics;
DROP VIEW &&tool_repository_schema..sqlt$_v$sql_workarea;
DROP VIEW &&tool_repository_schema..sqlt$_v$sqltext_with_newlines;

/* - recently deprecated sqlt tables used by migarate - */
DROP TABLE &&tool_repository_schema..sqlt$_statement;
DROP TABLE &&tool_repository_schema..sqlt$_plan_table;
DROP TABLE &&tool_repository_schema..sqlt$_parameter2;
DROP TABLE &&tool_repository_schema..sqlt$_indexes;
DROP TABLE &&tool_repository_schema..sqlt$_ind_columns;
DROP TABLE &&tool_repository_schema..sqlt$_tab_columns;

/* - old deprecated sqlt tables - */
DROP TABLE &&tool_repository_schema..sqlg$_10053_parse;
DROP TABLE &&tool_repository_schema..sqlg$_adv_rationale;
DROP TABLE &&tool_repository_schema..sqlg$_dba_hist_snapshot;
DROP TABLE &&tool_repository_schema..sqlg$_dba_hist_sql_plan;
DROP TABLE &&tool_repository_schema..sqlg$_dba_hist_sqlstat;
DROP TABLE &&tool_repository_schema..sqlg$_dba_hist_sqltext;
DROP TABLE &&tool_repository_schema..sqlg$_dba_part_histograms;
DROP TABLE &&tool_repository_schema..sqlg$_dba_subpart_histograms;
DROP TABLE &&tool_repository_schema..sqlg$_dba_tab_histograms;
DROP TABLE &&tool_repository_schema..sqlg$_dbms_xplan;
DROP TABLE &&tool_repository_schema..sqlg$_error;
DROP TABLE &&tool_repository_schema..sqlg$_gv$sql_bind_capture;
DROP TABLE &&tool_repository_schema..sqlg$_gv$sql_shared_cursor;
DROP TABLE &&tool_repository_schema..sqlg$_histogram_cols;
DROP TABLE &&tool_repository_schema..sqlg$_join_order;
DROP TABLE &&tool_repository_schema..sqlg$_object_dependency;
DROP TABLE &&tool_repository_schema..sqlg$_objects;
DROP TABLE &&tool_repository_schema..sqlg$_optstat_aux_history;
DROP TABLE &&tool_repository_schema..sqlg$_optstat_histgrm_history;
DROP TABLE &&tool_repository_schema..sqlg$_optstat_histhead_history;
DROP TABLE &&tool_repository_schema..sqlg$_optstat_ind_history;
DROP TABLE &&tool_repository_schema..sqlg$_optstat_opr;
DROP TABLE &&tool_repository_schema..sqlg$_optstat_tab_history;
DROP TABLE &&tool_repository_schema..sqlg$_peeked_binds;
DROP TABLE &&tool_repository_schema..sqlg$_pivot;
DROP TABLE &&tool_repository_schema..sqlg$_sql;
DROP TABLE &&tool_repository_schema..sqlg$_sql_monitor;
DROP TABLE &&tool_repository_schema..sqlg$_sql_plan;
DROP TABLE &&tool_repository_schema..sqlg$_sql_plan_monitor;
DROP TABLE &&tool_repository_schema..sqlg$_sql_plan_statistics;
DROP TABLE &&tool_repository_schema..sqlg$_sql_workarea;
DROP TABLE &&tool_repository_schema..sqlg$_statement_tune;
DROP TABLE &&tool_repository_schema..sqlg$_tab_part_columns;
DROP TABLE &&tool_repository_schema..sqlg$_tab_subpart_columns;
DROP TABLE &&tool_repository_schema..sqlg$_tablespaces;
DROP TABLE &&tool_repository_schema..sqlg$_warning;
DROP TABLE &&tool_repository_schema..sqlg$_xplore_test;
DROP TABLE &&tool_repository_schema..sqli$_parameter_apps;
DROP TABLE &&tool_repository_schema..sqli$_segments;
DROP TABLE &&tool_repository_schema..sqli$_tool_parameter;
DROP TABLE &&tool_repository_schema..sqlt$_10053_parse;
DROP TABLE &&tool_repository_schema..sqlt$_adv_rationale;
DROP TABLE &&tool_repository_schema..sqlt$_constraints;
DROP TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter;
DROP TABLE &&tool_repository_schema..sqlt$_error;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture;
DROP TABLE &&tool_repository_schema..sqlt$_hist_files;
DROP TABLE &&tool_repository_schema..sqlt$_histogram_cols;
DROP TABLE &&tool_repository_schema..sqlt$_ind_partitions;
DROP TABLE &&tool_repository_schema..sqlt$_ind_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_ind_subpartitions;
DROP TABLE &&tool_repository_schema..sqlt$_object_dependency;
DROP TABLE &&tool_repository_schema..sqlt$_objects;
DROP TABLE &&tool_repository_schema..sqlt$_optstat_ind_history;
DROP TABLE &&tool_repository_schema..sqlt$_optstat_tab_history;
DROP TABLE &&tool_repository_schema..sqlt$_other_xml;
DROP TABLE &&tool_repository_schema..sqlt$_other_xml_hints;
DROP TABLE &&tool_repository_schema..sqlt$_outline_hints;
DROP TABLE &&tool_repository_schema..sqlt$_outlines;
DROP TABLE &&tool_repository_schema..sqlt$_parameter;
DROP TABLE &&tool_repository_schema..sqlt$_parameter_apps;
DROP TABLE &&tool_repository_schema..sqlt$_segment_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_segments;
DROP TABLE &&tool_repository_schema..sqlt$_session_event;
DROP TABLE &&tool_repository_schema..sqlt$_sesstat;
DROP TABLE &&tool_repository_schema..sqlt$_sql;
DROP TABLE &&tool_repository_schema..sqlt$_sql_monitor;
DROP TABLE &&tool_repository_schema..sqlt$_sql_plan;
DROP TABLE &&tool_repository_schema..sqlt$_sql_plan_monitor;
DROP TABLE &&tool_repository_schema..sqlt$_sql_plan_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_sql_profile_hints;
DROP TABLE &&tool_repository_schema..sqlt$_sql_profiles;
DROP TABLE &&tool_repository_schema..sqlt$_sql_workarea;
DROP TABLE &&tool_repository_schema..sqlt$_statement_tune;
DROP TABLE &&tool_repository_schema..sqlt$_stattab_temp;
DROP TABLE &&tool_repository_schema..sqlt$_tab_col_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_tab_part_columns;
DROP TABLE &&tool_repository_schema..sqlt$_tab_partitions;
DROP TABLE &&tool_repository_schema..sqlt$_tab_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_tab_subpart_columns;
DROP TABLE &&tool_repository_schema..sqlt$_tab_subpartitions;
DROP TABLE &&tool_repository_schema..sqlt$_tables;
DROP TABLE &&tool_repository_schema..sqlt$_tablespaces;
DROP TABLE &&tool_repository_schema..sqlt$_tool_parameter;
DROP TABLE &&tool_repository_schema..sqlt$_warning;

/* - old deprecated sqlt sequences - */
DROP SEQUENCE &&tool_repository_schema..sqlg$_error_id_s;
DROP SEQUENCE &&tool_repository_schema..sqlt$_error_id_s;
DROP SEQUENCE &&tool_repository_schema..sqlt$_line_id_s;
DROP SEQUENCE &&tool_repository_schema..sqlt$_pk_id_s;
DROP SEQUENCE &&tool_repository_schema..sqlt$_statement_id_s;

/* - old deprecated sqlt types */
DROP TYPE &&tool_repository_schema..bind_nt;
DROP TYPE &&tool_repository_schema..bind_t;
DROP TYPE &&tool_repository_schema..varchar2_table;

SET ECHO OFF TERM ON;
PRO
PRO SQDOLD completed. Ignore errors from this script
