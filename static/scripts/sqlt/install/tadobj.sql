SET ECHO ON TERM OFF;
REM
REM $Header: 224270.1 tadobj.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   tadobj.sql
REM
REM DESCRIPTION
REM   This script drops existing TRCANLZR and TRCADMIN objects.
REM
REM PRE-REQUISITES
REM   1. This script must be executed connected as SYSDBA
REM
REM PARAMETERS
REM   1. None
REM
REM EXECUTION
REM   1. Navigate to trca/install directory
REM   2. Start SQL*Plus connecting as SYSDBA
REM   3. Execute script tadobj.sql
REM
REM EXAMPLE
REM   # cd trca/install
REM   # sqlplus / as sysdba
REM   SQL> start tadobj.sql
REM
REM NOTES
REM   1. This script is executed automatically by tadrop.sql
REM

WHENEVER SQLERROR CONTINUE;
SET ECHO ON TERM OFF;

-- package bodies
DROP PACKAGE BODY &&tool_administer_schema..trca$g;
DROP PACKAGE BODY &&tool_administer_schema..trca$i;
DROP PACKAGE BODY &&tool_administer_schema..trca$e;
DROP PACKAGE BODY &&tool_administer_schema..trca$p;
DROP PACKAGE BODY &&tool_administer_schema..trca$r;
DROP PACKAGE BODY &&tool_administer_schema..trca$t;
DROP PACKAGE BODY &&tool_administer_schema..trca$x;

-- views
DROP VIEW &&tool_administer_schema..trca$_call_vf;
DROP VIEW &&tool_administer_schema..trca$_dba_extents;
DROP VIEW &&tool_administer_schema..trca$_dba_extents_p;
DROP VIEW &&tool_administer_schema..trca$_error_vf;
DROP VIEW &&tool_administer_schema..trca$_exec_binds_vf;
DROP VIEW &&tool_administer_schema..trca$_exec_v;
DROP VIEW &&tool_administer_schema..trca$_exec_vf;
DROP VIEW &&tool_administer_schema..trca$_gap_call_vf;
DROP VIEW &&tool_administer_schema..trca$_gap_vf;
DROP VIEW &&tool_administer_schema..trca$_group_indexes_v;
DROP VIEW &&tool_administer_schema..trca$_group_tables_v;
DROP VIEW &&tool_administer_schema..trca$_group_v;
DROP VIEW &&tool_administer_schema..trca$_hot_block_segment_vf;
DROP VIEW &&tool_administer_schema..trca$_ind_columns_v;
DROP VIEW &&tool_administer_schema..trca$_non_recursive_v;
DROP VIEW &&tool_administer_schema..trca$_non_recursive_vf;
DROP VIEW &&tool_administer_schema..trca$_plan_table_vf;
DROP VIEW &&tool_administer_schema..trca$_progress_v;
DROP VIEW &&tool_administer_schema..trca$_purge_candidate_v;
DROP VIEW &&tool_administer_schema..trca$_response_time_summary_v;
DROP VIEW &&tool_administer_schema..trca$_response_time_summary_vf;
DROP VIEW &&tool_administer_schema..trca$_row_source_plan_sess_vf;
DROP VIEW &&tool_administer_schema..trca$_row_source_plan_vf;
DROP VIEW &&tool_administer_schema..trca$_session_vf;
DROP VIEW &&tool_administer_schema..trca$_sql_exec_time_v;
DROP VIEW &&tool_administer_schema..trca$_sql_exec_time_vf;
DROP VIEW &&tool_administer_schema..trca$_sql_exec_total_v;
DROP VIEW &&tool_administer_schema..trca$_sql_exec_wait_v;
DROP VIEW &&tool_administer_schema..trca$_sql_exec_wait_vf;
DROP VIEW &&tool_administer_schema..trca$_sql_genealogy_v;
DROP VIEW &&tool_administer_schema..trca$_sql_genealogy_vf;
DROP VIEW &&tool_administer_schema..trca$_sql_recu_time_v;
DROP VIEW &&tool_administer_schema..trca$_sql_recu_time_vf;
DROP VIEW &&tool_administer_schema..trca$_sql_recu_total_v;
DROP VIEW &&tool_administer_schema..trca$_sql_self_time_v;
DROP VIEW &&tool_administer_schema..trca$_sql_self_time_vf;
DROP VIEW &&tool_administer_schema..trca$_sql_self_total_v;
DROP VIEW &&tool_administer_schema..trca$_sql_self_wait_v;
DROP VIEW &&tool_administer_schema..trca$_sql_self_wait_vf;
DROP VIEW &&tool_administer_schema..trca$_sql_v;
DROP VIEW &&tool_administer_schema..trca$_sql_vf;
DROP VIEW &&tool_administer_schema..trca$_sql_wait_seg_cons_v;
DROP VIEW &&tool_administer_schema..trca$_sql_wait_seg_cons_vf;
DROP VIEW &&tool_administer_schema..trca$_sql_wait_segment_v;
DROP VIEW &&tool_administer_schema..trca$_sql_wait_segment_vf;
DROP VIEW &&tool_administer_schema..trca$_trc_non_recu_time_v;
DROP VIEW &&tool_administer_schema..trca$_trc_non_recu_time_vf;
DROP VIEW &&tool_administer_schema..trca$_trc_non_recu_total_v;
DROP VIEW &&tool_administer_schema..trca$_trc_non_recu_wait_v;
DROP VIEW &&tool_administer_schema..trca$_trc_non_recu_wait_vf;
DROP VIEW &&tool_administer_schema..trca$_trc_overall_time_v;
DROP VIEW &&tool_administer_schema..trca$_trc_overall_time_vf;
DROP VIEW &&tool_administer_schema..trca$_trc_overall_total_v;
DROP VIEW &&tool_administer_schema..trca$_trc_overall_wait_v;
DROP VIEW &&tool_administer_schema..trca$_trc_overall_wait_vf;
DROP VIEW &&tool_administer_schema..trca$_trc_recu_time_v;
DROP VIEW &&tool_administer_schema..trca$_trc_recu_time_vf;
DROP VIEW &&tool_administer_schema..trca$_trc_recu_total_v;
DROP VIEW &&tool_administer_schema..trca$_trc_recu_wait_v;
DROP VIEW &&tool_administer_schema..trca$_trc_recu_wait_vf;
DROP VIEW &&tool_administer_schema..trca$_trc_wait_segment_v;
DROP VIEW &&tool_administer_schema..trca$_trc_wait_segment_vf;
DROP VIEW sys.trca$_dba_segments;
DROP VIEW sys.trca$_dba_segments_p;
DROP VIEW sys.trca$_log_v;

-- package specs
DROP PACKAGE &&tool_administer_schema..trca$g;
DROP PACKAGE &&tool_administer_schema..trca$i;
DROP PACKAGE &&tool_administer_schema..trca$e;
DROP PACKAGE &&tool_administer_schema..trca$p;
DROP PACKAGE &&tool_administer_schema..trca$r;
DROP PACKAGE &&tool_administer_schema..trca$t;
DROP PACKAGE &&tool_administer_schema..trca$x;

-- sequences
DROP SEQUENCE &&tool_repository_schema..trca$_call_id_s;
DROP SEQUENCE &&tool_repository_schema..trca$_cursor_id_s;
DROP SEQUENCE &&tool_repository_schema..trca$_dep_id_s;
DROP SEQUENCE &&tool_repository_schema..trca$_exec_id_s;
DROP SEQUENCE &&tool_repository_schema..trca$_gap_id_s;
DROP SEQUENCE &&tool_repository_schema..trca$_header_id_s;
DROP SEQUENCE &&tool_repository_schema..trca$_session_id_s;
DROP SEQUENCE &&tool_repository_schema..trca$_statement_id_s;
DROP SEQUENCE &&tool_repository_schema..trca$_tool_execution_id_s;
DROP SEQUENCE &&tool_repository_schema..trca$_trace_id_s;

-- tables
DROP TABLE &&tool_repository_schema..trca$_audit_actions;
DROP TABLE &&tool_repository_schema..trca$_bind;
DROP TABLE &&tool_repository_schema..trca$_call;
DROP TABLE &&tool_repository_schema..trca$_call_tree;
DROP TABLE &&tool_repository_schema..trca$_cursor;
DROP TABLE &&tool_repository_schema..trca$_data_type;
DROP TABLE &&tool_repository_schema..trca$_error;
DROP TABLE &&tool_repository_schema..trca$_event_name;
DROP TABLE &&tool_repository_schema..trca$_exec;
DROP TABLE &&tool_repository_schema..trca$_exec_binds;
DROP TABLE &&tool_repository_schema..trca$_exec_tree;
DROP TABLE &&tool_repository_schema..trca$_extents;
DROP TABLE &&tool_repository_schema..trca$_extents_dm;
DROP TABLE &&tool_repository_schema..trca$_extents_lm;
DROP TABLE &&tool_repository_schema..trca$_file$;
DROP TABLE &&tool_repository_schema..trca$_file;
DROP TABLE &&tool_repository_schema..trca$_files;
DROP TABLE &&tool_repository_schema..trca$_gap;
DROP TABLE &&tool_repository_schema..trca$_gap_call;
DROP TABLE &&tool_repository_schema..trca$_genealogy;
DROP TABLE &&tool_repository_schema..trca$_genealogy_edge;
DROP TABLE &&tool_repository_schema..trca$_group;
DROP TABLE &&tool_repository_schema..trca$_group_call;
DROP TABLE &&tool_repository_schema..trca$_group_exec_call;
DROP TABLE &&tool_repository_schema..trca$_group_exec_wait;
DROP TABLE &&tool_repository_schema..trca$_group_exec_wait_segment;
DROP TABLE &&tool_repository_schema..trca$_group_indexes;
DROP TABLE &&tool_repository_schema..trca$_group_row_source_plan;
DROP TABLE &&tool_repository_schema..trca$_group_tables;
DROP TABLE &&tool_repository_schema..trca$_group_wait;
DROP TABLE &&tool_repository_schema..trca$_group_wait_segment;
DROP TABLE &&tool_repository_schema..trca$_hot_block;
DROP TABLE &&tool_repository_schema..trca$_hot_block_segment;
DROP TABLE &&tool_repository_schema..trca$_ind_columns$;
DROP TABLE &&tool_repository_schema..trca$_ind_columns;
DROP TABLE &&tool_repository_schema..trca$_indexes$;
DROP TABLE &&tool_repository_schema..trca$_indexes;
DROP TABLE &&tool_repository_schema..trca$_objects$;
DROP TABLE &&tool_repository_schema..trca$_objects;
DROP TABLE &&tool_repository_schema..trca$_parameter2$;
DROP TABLE &&tool_repository_schema..trca$_pivot;
DROP TABLE &&tool_repository_schema..trca$_plan_table;
DROP TABLE &&tool_repository_schema..trca$_row_source_plan;
DROP TABLE &&tool_repository_schema..trca$_row_source_plan_session;
DROP TABLE &&tool_repository_schema..trca$_segments;
DROP TABLE &&tool_repository_schema..trca$_session;
DROP TABLE &&tool_repository_schema..trca$_stat;
DROP TABLE &&tool_repository_schema..trca$_stat_exec;
DROP TABLE &&tool_repository_schema..trca$_statement;
DROP TABLE &&tool_repository_schema..trca$_tab_cols$;
DROP TABLE &&tool_repository_schema..trca$_tab_cols;
DROP TABLE &&tool_repository_schema..trca$_tables$;
DROP TABLE &&tool_repository_schema..trca$_tables;
DROP TABLE &&tool_repository_schema..trca$_tool_exec_call;
DROP TABLE &&tool_repository_schema..trca$_tool_execution;
DROP TABLE &&tool_repository_schema..trca$_tool_parameter;
DROP TABLE &&tool_repository_schema..trca$_tool_wait;
DROP TABLE &&tool_repository_schema..trca$_tool_wait_segment;
DROP TABLE &&tool_repository_schema..trca$_trace;
DROP TABLE &&tool_repository_schema..trca$_trace_header;
DROP TABLE &&tool_repository_schema..trca$_users;
DROP TABLE &&tool_repository_schema..trca$_wait;
DROP TABLE &&tool_repository_schema..trca$_wait_event_name;
DROP TABLE &&tool_repository_schema..trca_control;
DROP TABLE &&tool_repository_schema..trca_extents_dm;
DROP TABLE &&tool_repository_schema..trca_extents_lm;
DROP TABLE &&tool_repository_schema..trca_file;
DROP TABLE &&tool_repository_schema..trca_ind_columns;
DROP TABLE &&tool_repository_schema..trca_indexes;
DROP TABLE &&tool_repository_schema..trca_objects;
DROP TABLE &&tool_repository_schema..trca_parameter2;
DROP TABLE &&tool_repository_schema..trca_segments;
DROP TABLE &&tool_repository_schema..trca_tab_cols;
DROP TABLE &&tool_repository_schema..trca_tables;

SET ECHO OFF TERM ON;
PRO TADOBJ completed.
