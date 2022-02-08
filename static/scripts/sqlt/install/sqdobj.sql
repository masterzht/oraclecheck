SET ECHO ON TERM OFF;
REM
REM $Header: 215187.1 sqdobj.sql 12.1.08 2014/04/18 carlos.sierra mauro.pagano $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqlt/install/sqdobj.sql
REM
REM DESCRIPTION
REM   Drops current SQLTXPLAIN schema objects from SQLT tool.
REM
REM PRE-REQUISITES
REM   1. To drop current SQLTXPLAIN objects you must connect
REM      as SYSDBA.
REM
REM PARAMETERS
REM   1. None
REM
REM EXECUTION
REM   1. Navigate to sqlt/install directory
REM   2. Start SQL*Plus connecting as SYSDBA
REM   3. Execute this script sqdobj.sql
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqdobj.sql
REM
REM NOTES
REM   1. This script is executed automatically by sqdrop.sql
REM
@@sqcommon1.sql

WHENEVER SQLERROR CONTINUE;
SET ECHO ON TERM OFF;

/* - sqlt packages - */
DROP PROCEDURE &&tool_repository_schema..purge_trca$_dict_gtt;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$a;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$c;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$d;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$e;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$h;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$i;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$m;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$s;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$r;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$t;
DROP PACKAGE      &&tool_administer_schema..sqlt$a;
DROP PACKAGE      &&tool_administer_schema..sqlt$c;
DROP PACKAGE      &&tool_administer_schema..sqlt$d;
DROP PACKAGE      &&tool_administer_schema..sqlt$e;
DROP PACKAGE      &&tool_administer_schema..sqlt$h;
DROP PACKAGE      &&tool_administer_schema..sqlt$i;
DROP PACKAGE      &&tool_administer_schema..sqlt$m;
DROP PACKAGE      &&tool_administer_schema..sqlt$r;
DROP PACKAGE      &&tool_administer_schema..sqlt$s;
DROP PACKAGE      &&tool_administer_schema..sqlt$t;

/* - sys views created and used by sqlt - */
DROP VIEW sys.sqlt$_col$_v;
DROP VIEW sys.sqlt$_dba_col_stats_vers_v;
DROP VIEW sys.sqlt$_dba_col_usage_v;
DROP VIEW sys.sqlt$_dba_hgrm_stats_vers_v;
DROP VIEW sys.sqlt$_dba_ind_stats_vers_v;
DROP VIEW sys.sqlt$_dba_tab_stats_vers_v;
DROP VIEW sys.sqlt$_gv$parameter_cbo_v;
DROP VIEW sys.sqlt$_my_v$session;
DROP VIEW sys.sqlt$_my_v$sql;

/* - sqlt views - */
DROP VIEW &&tool_administer_schema..sqlt$_captured_binds_sum_v;
DROP VIEW &&tool_administer_schema..sqlt$_captured_binds_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_act_sess_hist_p_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_act_sess_hist_pl_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_all_table_cols_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_all_tables_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_col_stats_versions_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_hist_sqlstat_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_ind_columns_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_ind_statistics_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_ind_stats_versions_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_indexes_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_stat_extensions_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_tab_col_statistics_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_tab_histograms_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_tab_statistics_v;
DROP VIEW &&tool_administer_schema..sqlt$_dba_tab_stats_versions_v;
DROP VIEW &&tool_administer_schema..sqlt$_dependencies_v;
DROP VIEW &&tool_administer_schema..sqlt$_gv$act_sess_hist_p_v;
DROP VIEW &&tool_administer_schema..sqlt$_gv$act_sess_hist_pl_v;
DROP VIEW &&tool_administer_schema..sqlt$_gv$cell_state_v;
DROP VIEW &&tool_administer_schema..sqlt$_gv$object_dependency_v;
DROP VIEW &&tool_administer_schema..sqlt$_gv$pq_sysstat_v;
DROP VIEW &&tool_administer_schema..sqlt$_gv$px_process_sysstat_v;
DROP VIEW &&tool_administer_schema..sqlt$_gv$px_sesstat_v;
DROP VIEW &&tool_administer_schema..sqlt$_gv$segment_statistics_v;
DROP VIEW &&tool_administer_schema..sqlt$_gv$session_event_v;
DROP VIEW &&tool_administer_schema..sqlt$_gv$sesstat_v;
DROP VIEW &&tool_administer_schema..sqlt$_log_v;
DROP VIEW &&tool_administer_schema..sqlt$_peeked_binds_sum_v;
DROP VIEW &&tool_administer_schema..sqlt$_peeked_binds_v;
DROP VIEW &&tool_administer_schema..sqlt$_plan_statistics_v;
DROP VIEW &&tool_administer_schema..sqlt$_plan_stats_v;
DROP VIEW &&tool_administer_schema..sqlt$_plan_summary_v2;
DROP VIEW &&tool_administer_schema..sqlt$_plan_summary_v;
DROP VIEW &&tool_administer_schema..sqlt$_sql_profile_hints_v;
DROP VIEW &&tool_administer_schema..sqlt$_sql_shared_cursor_v;
DROP VIEW &&tool_administer_schema..sqlt$_wri$_optstat_aux_hist_v;

/* - sqlt tables - */
DROP TABLE &&tool_repository_schema..chk$cbo$parameter_apps;
DROP TABLE &&tool_repository_schema..sqlg$_clob;
DROP TABLE &&tool_repository_schema..sqlg$_column_html_table;
DROP TABLE &&tool_repository_schema..sqlg$_column_predicate;
DROP TABLE &&tool_repository_schema..sqlg$_observation;
DROP TABLE &&tool_repository_schema..sqlg$_sql_shared_cursor_n;
DROP TABLE &&tool_repository_schema..sqlg$_temp;
DROP TABLE &&tool_repository_schema..sqli$_clob;
DROP TABLE &&tool_repository_schema..sqli$_db_link;
DROP TABLE &&tool_repository_schema..sqli$_dba_hist_parameter;
DROP TABLE &&tool_repository_schema..sqli$_file;
DROP TABLE &&tool_repository_schema..sqli$_parameter;
DROP TABLE &&tool_repository_schema..sqli$_sess_parameter;
DROP TABLE &&tool_repository_schema..sqli$_stattab_temp;
DROP TABLE &&tool_repository_schema..sqli$_stgtab_sqlprof;
DROP TABLE &&tool_repository_schema..sqli$_stgtab_sqlset;
DROP TABLE &&tool_repository_schema..sqlt$_aux_stats$;
DROP TABLE &&tool_repository_schema..sqlt$_dba_audit_policies;
DROP TABLE &&tool_repository_schema..sqlt$_dba_autotask_client;
DROP TABLE &&tool_repository_schema..sqlt$_dba_autotask_client_hst;
DROP TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions;
DROP TABLE &&tool_repository_schema..sqlt$_dba_col_usage$;
DROP TABLE &&tool_repository_schema..sqlt$_dba_constraints;
DROP TABLE &&tool_repository_schema..sqlt$_dba_dependencies;
DROP TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his;
DROP TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m;
DROP TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj;
DROP TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot;
DROP TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan;
DROP TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind;
DROP TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat;
DROP TABLE &&tool_repository_schema..sqlt$_dba_hist_sqltext;
DROP TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn;
DROP TABLE &&tool_repository_schema..sqlt$_dba_ind_columns;
DROP TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions;
DROP TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions;
DROP TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions;
DROP TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions;
DROP TABLE &&tool_repository_schema..sqlt$_dba_indexes;
DROP TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols;
DROP TABLE &&tool_repository_schema..sqlt$_dba_nested_tables;
DROP TABLE &&tool_repository_schema..sqlt$_dba_object_tables;
DROP TABLE &&tool_repository_schema..sqlt$_dba_objects;
DROP TABLE &&tool_repository_schema..sqlt$_dba_optstat_operations;
DROP TABLE &&tool_repository_schema..sqlt$_dba_outline_hints;
DROP TABLE &&tool_repository_schema..sqlt$_dba_outlines;
DROP TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_dba_part_histograms;
DROP TABLE &&tool_repository_schema..sqlt$_dba_part_key_columns;
DROP TABLE &&tool_repository_schema..sqlt$_dba_policies;
DROP TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs;
DROP TABLE &&tool_repository_schema..sqlt$_dba_segments;
DROP TABLE &&tool_repository_schema..sqlt$_dba_source;
DROP TABLE &&tool_repository_schema..sqlt$_dba_sql_patches;
DROP TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines;
DROP TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles;
DROP TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans;
DROP TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions;
DROP TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats;
DROP TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms;
DROP TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_dba_tab_cols;
DROP TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms;
DROP TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications;
DROP TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions;
DROP TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions;
DROP TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions;
DROP TABLE &&tool_repository_schema..sqlt$_dba_tables;
DROP TABLE &&tool_repository_schema..sqlt$_dba_tablespaces;
DROP TABLE &&tool_repository_schema..sqlt$_dbms_xplan;
DROP TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor;
DROP TABLE &&tool_repository_schema..sqlt$_gv$cell_state;
DROP TABLE &&tool_repository_schema..sqlt$_gv$im_segments;
DROP TABLE &&tool_repository_schema..sqlt$_gv$im_column_level;
DROP TABLE &&tool_repository_schema..sqlt$_gv$nls_parameters;
DROP TABLE &&tool_repository_schema..sqlt$_gv$object_dependency;
DROP TABLE &&tool_repository_schema..sqlt$_gv$parameter2;
DROP TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo;
DROP TABLE &&tool_repository_schema..sqlt$_gv$pq_sesstat;
DROP TABLE &&tool_repository_schema..sqlt$_gv$pq_slave;
DROP TABLE &&tool_repository_schema..sqlt$_gv$pq_sysstat;
DROP TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat;
DROP TABLE &&tool_repository_schema..sqlt$_gv$px_instance_group;
DROP TABLE &&tool_repository_schema..sqlt$_gv$px_process;
DROP TABLE &&tool_repository_schema..sqlt$_gv$px_process_sysstat;
DROP TABLE &&tool_repository_schema..sqlt$_gv$px_session;
DROP TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat;
DROP TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_gv$session_event;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sesstat;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_histogram;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_plan;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sqlarea;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sqlstats;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash;
DROP TABLE &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines;
DROP TABLE &&tool_repository_schema..sqlt$_gv$statname;
DROP TABLE &&tool_repository_schema..sqlt$_gv$system_parameter;
DROP TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy;
DROP TABLE &&tool_repository_schema..sqlt$_log;
DROP TABLE &&tool_repository_schema..sqlt$_metadata;
DROP TABLE &&tool_repository_schema..sqlt$_nls_database_parameters;
DROP TABLE &&tool_repository_schema..sqlt$_optstat_user_prefs$;
DROP TABLE &&tool_repository_schema..sqlt$_outline_data;
DROP TABLE &&tool_repository_schema..sqlt$_display_map;
DROP TABLE &&tool_repository_schema..sqlt$_peeked_binds;
DROP TABLE &&tool_repository_schema..sqlt$_plan_extension;
DROP TABLE &&tool_repository_schema..sqlt$_plan_info;
DROP TABLE &&tool_repository_schema..sqlt$_sql_plan_table;
DROP TABLE &&tool_repository_schema..sqlt$_sql_shared_cursor_d;
DROP TABLE &&tool_repository_schema..sqlt$_sql_statement;
DROP TABLE &&tool_repository_schema..sqlt$_sqlobj$;
DROP TABLE &&tool_repository_schema..sqlt$_sqlobj$data;
DROP TABLE &&tool_repository_schema..sqlt$_sqlprof$;
DROP TABLE &&tool_repository_schema..sqlt$_sqlprof$attr;
DROP TABLE &&tool_repository_schema..sqlt$_stattab;
DROP TABLE &&tool_repository_schema..sqlt$_stgtab_baseline;
DROP TABLE &&tool_repository_schema..sqlt$_stgtab_sqlprof;
DROP TABLE &&tool_repository_schema..sqlt$_stgtab_sqlset;
DROP TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives
DROP TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs
DROP TABLE &&tool_repository_schema..sqlt$_v$session_fix_control;
DROP TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale;
DROP TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks;
DROP TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history;

/* - sqlt sequences - */
DROP SEQUENCE &&tool_repository_schema..sqlt$_sql_statement_id_s;

SET ECHO OFF TERM ON;
PRO
PRO SQDOBJ completed. Ignore errors from this script

