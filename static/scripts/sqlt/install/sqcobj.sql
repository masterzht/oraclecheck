COL yymmddhh24miss NEW_V yymmddhh24miss NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYMMDDHH24MISS') yymmddhh24miss FROM DUAL;
SPO &&yymmddhh24miss._05_sqcobj.log;
SET TERM OFF ECHO ON VER OFF SERVEROUT ON;
REM
REM $Header: 215187.1 sqcobj.sql 12.2.171004  October 4th, 2017 carlos.sierra mauro.pagano abel.macias@oracle.com $ 
REM
REM Copyright (c) 2000-2014, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra
REM   mauro.pagano
REM   abel.macias@oracle.com
REM   stelios.charalambides@oracle.com
REM
REM SCRIPT
REM   sqlt/install/sqcobj.sql
REM
REM DESCRIPTION
REM   Creates SQLT schema objects owned by SQLTXPLAIN.
REM
REM PRE-REQUISITES
REM   1. Connect connect INTERNAL(SYS) as SYSDBA
REM
REM PARAMETERS
REM   1. None
REM
REM EXECUTION
REM   1. Navigate to sqlt/install directory
REM   2. Start SQL*Plus connecting INTERNAL(SYS) as SYSDBA
REM   3. Execute script sqcobj.sql
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqcobj.sql
REM
REM NOTES
REM   1. This script is executed automatically by sqcreate.sql
REM   2. For possible errors see sqcobj.log file
REM

@@sqcommon1.sql

PRO
PRO ... creating SQLT schema objects, please wait

SET ECHO ON TERM OFF;
WHENEVER SQLERROR CONTINUE;

/* ------------------------------------------------------------------------- */

SET NUMF "";
COL start_with NEW_V start_with;
SELECT (NVL(MOD(TRUNC(ABS(SYS.DBMS_RANDOM.RANDOM)), 89000), 0) + 10000) start_with FROM DUAL;

CREATE SEQUENCE &&tool_repository_schema..sqlt$_sql_statement_id_s START WITH &&start_with. NOCACHE;
ALTER SEQUENCE &&tool_repository_schema..sqlt$_sql_statement_id_s NOCACHE;

CREATE SEQUENCE &&tool_repository_schema..sqlt$_line_id_s;

GRANT ALL ON &&tool_repository_schema..sqlt$_sql_statement_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_sql_statement_id_s FOR &&tool_repository_schema..sqlt$_sql_statement_id_s;

GRANT ALL ON &&tool_repository_schema..sqlt$_line_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_line_id_s FOR &&tool_repository_schema..sqlt$_line_id_s;

/* ------------------------------------------------------------------------- */

/* 
171004 Extensive modification of columns to varchar2(257) 
       FBIs need to be dropped to avoid ORA-30556 when modifying the columns 
*/
begin
for d in (select 'drop index &&tool_repository_schema..'||index_name drop_fbi
            from dba_indexes
           where owner='&&tool_repository_schema.'
             and index_type='FUNCTION-BASED NORMAL') loop
 execute immediate d.drop_fbi;
end loop;
end;
/

ALTER TABLE &&tool_repository_schema..sqli$_file MODIFY (username      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement  MODIFY  (siebel_schema                  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement  MODIFY  (siebel_app_ver                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement  MODIFY  (psft_schema                    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement  MODIFY  (psft_tools_rel                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement  MODIFY  (username                       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table  MODIFY  (object_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table  MODIFY  (object_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table  MODIFY  (qblock_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea  MODIFY  (parsing_schema_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea  MODIFY  (sql_patch                      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea  MODIFY  (sql_plan_baseline              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash  MODIFY  (parsing_schema_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql  MODIFY  (parsing_schema_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql  MODIFY  (sql_patch                      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql  MODIFY  (sql_plan_baseline              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan  MODIFY  (object_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan  MODIFY  (object_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan  MODIFY  (qblock_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture  MODIFY  (name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlg$_sql_shared_cursor_n  MODIFY  (column_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_nls_database_parameters  MODIFY  (parameter VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_nls_database_parameters  MODIFY  (value     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor  MODIFY  (username                  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor  MODIFY  (plan_object_owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor  MODIFY  (plan_object_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments  MODIFY  (owner                     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments  MODIFY  (segment_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments  MODIFY  (partition_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments  MODIFY  (tablespace_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_column_level  MODIFY  (owner                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_column_level  MODIFY  (table_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_column_level  MODIFY  (column_name             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj  MODIFY  (owner           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj  MODIFY  (object_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj  MODIFY  (subobject_name  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj  MODIFY  (tablespace_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat  MODIFY  (parsing_schema_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan  MODIFY  (object_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan  MODIFY  (object_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan  MODIFY  (qblock_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind  MODIFY  (name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies  MODIFY  (owner                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies  MODIFY  (name                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies  MODIFY  (referenced_owner     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies  MODIFY  (referenced_name      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies  MODIFY  (referenced_link_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables  MODIFY  (owner                      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables  MODIFY  (table_name                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables  MODIFY  (tablespace_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables  MODIFY  (cluster_name               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables  MODIFY  (iot_name                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables  MODIFY  (cluster_owner              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables  MODIFY  (owner                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables  MODIFY  (table_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables  MODIFY  (table_type_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables  MODIFY  (table_type_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables  MODIFY  (parent_table_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables  MODIFY  (storage_spec          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables  MODIFY  (owner                     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables  MODIFY  (table_name                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables  MODIFY  (tablespace_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables  MODIFY  (cluster_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables  MODIFY  (iot_name                  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables  MODIFY  (table_type_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables  MODIFY  (table_type                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables  MODIFY  (cluster_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics  MODIFY  (owner                     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics  MODIFY  (table_name                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics  MODIFY  (partition_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics  MODIFY  (subpartition_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions  MODIFY  (owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions  MODIFY  (table_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions  MODIFY  (extension_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications MODIFY (table_owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications MODIFY (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications MODIFY (partition_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications MODIFY (subpartition_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols MODIFY (owner                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols MODIFY (table_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols MODIFY (column_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols MODIFY (data_type_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols MODIFY (owner                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols MODIFY (table_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols MODIFY (column_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols MODIFY (data_type_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics MODIFY (owner         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics MODIFY (table_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics MODIFY (column_name   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes MODIFY (owner                     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes MODIFY (index_name                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes MODIFY (table_owner               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes MODIFY (table_name                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes MODIFY (tablespace_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes MODIFY (ityp_owner                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes MODIFY (ityp_name                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics MODIFY (owner                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics MODIFY (index_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics MODIFY (table_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics MODIFY (table_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics MODIFY (partition_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics MODIFY (subpartition_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns MODIFY (index_owner     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns MODIFY (index_name      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns MODIFY (table_owner     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns MODIFY (table_name      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions MODIFY (index_owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions MODIFY (index_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions MODIFY (table_owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions MODIFY (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms MODIFY (owner                    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms MODIFY (table_name               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_key_columns MODIFY (owner           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_key_columns MODIFY (name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions MODIFY (table_owner            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions MODIFY (table_name             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions MODIFY (partition_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions MODIFY (tablespace_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions MODIFY (parent_table_partition VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions MODIFY (index_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions MODIFY (index_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions MODIFY (partition_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions MODIFY (tablespace_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics MODIFY (owner              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics MODIFY (table_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics MODIFY (partition_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms MODIFY (owner                    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms MODIFY (table_name               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms MODIFY (partition_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions MODIFY (table_owner           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions MODIFY (table_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions MODIFY (partition_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions MODIFY (subpartition_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions MODIFY (tablespace_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions MODIFY (index_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions MODIFY (index_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions MODIFY (partition_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions MODIFY (subpartition_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions MODIFY (tablespace_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats MODIFY (owner              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats MODIFY (table_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats MODIFY (subpartition_name  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms MODIFY (owner                    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms MODIFY (table_name               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms MODIFY (subpartition_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints MODIFY (owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints MODIFY (constraint_name   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints MODIFY (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints MODIFY (r_owner           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints MODIFY (r_constraint_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints MODIFY (index_owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints MODIFY (index_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments MODIFY (owner            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments MODIFY (segment_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments MODIFY (partition_name   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments MODIFY (tablespace_name  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces MODIFY (tablespace_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects MODIFY (owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects MODIFY (object_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects MODIFY (subobject_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects MODIFY (edition_name   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_source MODIFY (owner VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_source MODIFY (name  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs MODIFY (owner                         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs MODIFY (job_name                      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs MODIFY (job_subname                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs MODIFY (job_creator                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs MODIFY (event_queue_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs MODIFY (event_queue_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs MODIFY (job_class                     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs MODIFY (credential_owner              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs MODIFY (credential_name               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client MODIFY (consumer_group               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ MODIFY (owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ MODIFY (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ MODIFY (column_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy MODIFY (object_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy MODIFY (object_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy MODIFY (policy_group          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy MODIFY (policy                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy MODIFY (policy_function_owner VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies MODIFY (object_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies MODIFY (object_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies MODIFY (policy_group      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies MODIFY (policy_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies MODIFY (pf_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies MODIFY (package           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies MODIFY (function          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies MODIFY (object_schema         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies MODIFY (object_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies MODIFY (policy_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies MODIFY (policy_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies MODIFY (policy_column         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies MODIFY (pf_schema             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies MODIFY (pf_package            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies MODIFY (pf_function           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions MODIFY (owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions MODIFY (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions MODIFY (partition_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions MODIFY (subpartition_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions MODIFY (owner                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions MODIFY (index_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions MODIFY (table_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions MODIFY (table_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions MODIFY (partition_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions MODIFY (subpartition_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions MODIFY (owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions MODIFY (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions MODIFY (partition_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions MODIFY (subpartition_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions MODIFY (column_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions MODIFY (colname           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn MODIFY (owner                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn MODIFY (table_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn MODIFY (partition_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn MODIFY (subpartition_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn MODIFY (column_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn MODIFY (colname               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_aux_stats$ MODIFY (sname       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_aux_stats$ MODIFY (pname       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history MODIFY (sname   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history MODIFY (pname   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics MODIFY (owner           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics MODIFY (object_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics MODIFY (subobject_name  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics MODIFY (tablespace_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sysstat MODIFY (statistic      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process_sysstat MODIFY (statistic      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sesstat MODIFY (statistic      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan MODIFY (sql_handle        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan MODIFY (plan_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks MODIFY (owner_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks MODIFY (name                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks MODIFY (advisor_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks MODIFY (last_exec_name      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks MODIFY (how_created         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks MODIFY (source              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale MODIFY (exec_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale MODIFY (type          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans MODIFY (execution_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans MODIFY (operation         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans MODIFY (object_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans MODIFY (object_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans MODIFY (object_type       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans MODIFY (distribution      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans MODIFY (qblock_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension MODIFY (source                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension MODIFY (operation             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension MODIFY (options               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension MODIFY (object_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension MODIFY (object_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension MODIFY (qblock_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches MODIFY (name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches MODIFY (category       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches MODIFY (task_exec_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles MODIFY (name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles MODIFY (category       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles MODIFY (task_exec_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines MODIFY (sql_handle          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines MODIFY (plan_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines MODIFY (creator             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines MODIFY (parsing_schema_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs MODIFY (owner            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs MODIFY (object_name      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs MODIFY (subobject_name   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$data MODIFY (category  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ MODIFY (category      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ MODIFY (name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$attr MODIFY (category  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ MODIFY (sp_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ MODIFY (category      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines MODIFY (name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines MODIFY (owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines MODIFY (category   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outline_hints MODIFY (name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outline_hints MODIFY (owner    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_metadata MODIFY (owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_metadata MODIFY (object_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_metadata MODIFY (object_type VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols MODIFY (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols MODIFY (column_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols MODIFY (partition         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols MODIFY (owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds MODIFY (source              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info MODIFY (source              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data MODIFY (source              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_display_map MODIFY (source          VARCHAR2(257));


/* ------------------------------------------------------------------------- */



CREATE TABLE &&tool_repository_schema..sqli$_parameter (
name VARCHAR2(32) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqli$_parameter TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqli$_parameter FOR &&tool_repository_schema..sqli$_parameter;

-- C = Char, N = Number
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (type CHAR(1));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (value VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (description VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (is_hidden CHAR(1));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (is_usr_modifiable CHAR(1));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (is_default CHAR(1));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (default_value VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (instructions VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (low_value NUMBER);
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (high_value NUMBER);
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (value1 VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (value2 VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (value3 VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (value4 VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_parameter ADD (value5 VARCHAR2(128));

CREATE UNIQUE INDEX &&tool_repository_schema..sqli$_parameter_u1 ON &&tool_repository_schema..sqli$_parameter (name);

/* ------------------------------------------------------------------------- */

DROP TABLE &&tool_repository_schema..sqli$_sess_parameter;
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..sqli$_sess_parameter (
name VARCHAR2(32) NOT NULL
) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..sqli$_sess_parameter TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqli$_sess_parameter FOR &&tool_repository_schema..sqli$_sess_parameter;

-- C = Char, N = Number
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (type CHAR(1));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (value VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (description VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (is_hidden CHAR(1));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (is_usr_modifiable CHAR(1));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (is_default CHAR(1));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (default_value VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (instructions VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (low_value NUMBER);
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (high_value NUMBER);
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (value1 VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (value2 VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (value3 VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (value4 VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_sess_parameter ADD (value5 VARCHAR2(128));

CREATE UNIQUE INDEX &&tool_repository_schema..sqli$_sess_parameter_u1 ON &&tool_repository_schema..sqli$_sess_parameter (name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqli$_file (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT, INSERT ON &&tool_repository_schema..sqli$_file TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqli$_file TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqli$_file FOR &&tool_repository_schema..sqli$_file;

ALTER TABLE &&tool_repository_schema..sqli$_file ADD (statement_id2 NUMBER);
ALTER TABLE &&tool_repository_schema..sqli$_file ADD (file_type     VARCHAR2(24));
ALTER TABLE &&tool_repository_schema..sqli$_file ADD (filename      VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqli$_file MODIFY (filename   VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqli$_file ADD (file_date     DATE);
ALTER TABLE &&tool_repository_schema..sqli$_file ADD (file_size     NUMBER);
ALTER TABLE &&tool_repository_schema..sqli$_file ADD (username      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqli$_file ADD (db_link       VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_file ADD (file_text     CLOB);


/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqli$_clob (
clob_id   VARCHAR2(32),
clob_text CLOB
);

GRANT ALL ON &&tool_repository_schema..sqli$_clob TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqli$_clob FOR &&tool_repository_schema..sqli$_clob;

/* ------------------------------------------------------------------------- */

DROP TABLE &&tool_repository_schema..sqlg$_clob;
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..sqlg$_clob (
clob_text CLOB
) ON COMMIT DELETE ROWS;

GRANT ALL ON &&tool_repository_schema..sqlg$_clob TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlg$_clob FOR &&tool_repository_schema..sqlg$_clob;

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqli$_db_link (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT, INSERT, DELETE, UPDATE ON &&tool_repository_schema..sqli$_db_link TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqli$_db_link TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqli$_db_link FOR &&tool_repository_schema..sqli$_db_link;

ALTER TABLE &&tool_repository_schema..sqli$_db_link ADD (db_link                VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqli$_db_link ADD (event_10046            CHAR(1));
ALTER TABLE &&tool_repository_schema..sqli$_db_link ADD (error_flag             CHAR(1));
ALTER TABLE &&tool_repository_schema..sqli$_db_link ADD (file_10046_10053_udump VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqli$_db_link ADD (file_10046_10053       VARCHAR2(256));

/* ------------------------------------------------------------------------- */

-- for 12c
BEGIN
  IF :rdbms_version >= '12' THEN
      EXECUTE IMMEDIATE 'BEGIN SYS.DBMS_SPD.CREATE_STGTAB_DIRECTIVE(:table_name, :table_owner); END;'
      USING IN 'SQLT$_STGTAB_DIRECTIVE', IN '&&tool_repository_schema.';

      SYS.DBMS_OUTPUT.PUT_LINE('DBMS_SPM.CREATE_STGTAB_DIRECTIVE');  
  ELSE
      EXECUTE IMMEDIATE 'CREATE TABLE &&tool_repository_schema..SQLT$_STGTAB_DIRECTIVE(STATID VARCHAR2(128), C5 VARCHAR2(128))';
   
  END If;

EXCEPTION
  WHEN OTHERS THEN
    SYS.DBMS_OUTPUT.PUT_LINE('DBMS_SPM.CREATE_STGTAB_DIRECTIVE: '||SQLERRM);
END;
/

GRANT ALL ON &&tool_repository_schema..sqlt$_stgtab_directive TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_stgtab_directive FOR &&tool_repository_schema..sqlt$_stgtab_directive;

/* ------------------------------------------------------------------------- */

-- for 11g
DECLARE
  l_count NUMBER;
BEGIN
  IF :rdbms_version >= '11' THEN
    SELECT COUNT(*)
      INTO l_count
      FROM dba_tab_cols
     WHERE owner = '&&tool_repository_schema.'
       AND table_name = 'SQLT$_STGTAB_BASELINE';

    IF l_count = 3 THEN -- SQLT$_STGTAB_BASELINE was created like if it had been 10g
      EXECUTE IMMEDIATE 'DROP TABLE &&tool_repository_schema..SQLT$_STGTAB_BASELINE';
    END IF;

    IF l_count IN (0, 3) THEN -- never created or just dropped
      EXECUTE IMMEDIATE 'BEGIN SYS.DBMS_SPM.CREATE_STGTAB_BASELINE(:table_name, :table_owner); END;'
      USING IN 'SQLT$_STGTAB_BASELINE', IN '&&tool_repository_schema.';

      SYS.DBMS_OUTPUT.PUT_LINE('DBMS_SPM.CREATE_STGTAB_BASELINE');
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    SYS.DBMS_OUTPUT.PUT_LINE('DBMS_SPM.CREATE_STGTAB_BASELINE: '||SQLERRM);
END;
/

-- for 10g
BEGIN
  IF :rdbms_version < '11' THEN
    EXECUTE IMMEDIATE 'CREATE TABLE &&tool_repository_schema..SQLT$_STGTAB_BASELINE (action VARCHAR2(64))';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    SYS.DBMS_OUTPUT.PUT_LINE('CREATE TABLE &&tool_repository_schema..STGTAB_BASELINE: '||SQLERRM);
END;
/

GRANT ALL ON &&tool_repository_schema..sqlt$_stgtab_baseline TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_stgtab_baseline FOR &&tool_repository_schema..sqlt$_stgtab_baseline;

ALTER TABLE &&tool_repository_schema..sqlt$_stgtab_baseline ADD (statid VARCHAR2(30));
--11.2.0.1.0 version 2
--11.2.0.2.0 version 3
ALTER TABLE &&tool_repository_schema..sqlt$_stgtab_baseline ADD (version NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_sql_statement (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT, UPDATE ON &&tool_repository_schema..sqlt$_sql_statement TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_sql_statement TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_sql_statement FOR &&tool_repository_schema..sqlt$_sql_statement;

-- environment
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (statement_set_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (group_id                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (method                         VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (input_filename                 VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (host_name_short                VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (cpu_count                      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (num_cpus                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (num_cpu_cores                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (num_cpu_sockets                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (rac                            VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (exadata                        VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (inmemory_option                VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (optim_peek_user_binds          VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (database_id                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (database_name_short            VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sid                            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (instance_number                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (instance_name_short            VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (platform                       VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (product_version                VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (rdbms_version                  VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (rdbms_version_short            VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (rdbms_release                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (language                       VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (apps_release                   VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (apps_system_name               VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (siebel                         VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (siebel_schema                  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (siebel_app_ver                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (psft                           VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (psft_schema                    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (psft_tools_rel                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_tuning_advisor             VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_monitoring                 VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (automatic_workload_repository  VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (stand_by_dblink                VARCHAR2(128));
-- database_properties
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (nls_characterset               VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (dbtimezone                     VARCHAR2(4000));
-- dba_data_files
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (total_bytes                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (total_blocks                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (total_user_bytes               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (total_user_blocks              NUMBER);
-- dba_segments
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (segments_total_bytes           NUMBER);
-- sql identification
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (in_memory                      CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (in_awr                         CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (string                         VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sta_task_name_mem              VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sta_task_name_awr              VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sta_task_name_txt              VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (command_type                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (command_type_name              VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_handle                     VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_id_found_using_sqltext     CHAR(1));
-- sql identification for stripped sql_text
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_id                         VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (hash_value                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (signature_so                   VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (signature_sta                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (signature_sta_force_match      NUMBER);
-- sql identification for unstripped sql_text
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (xplain_sql_id                  VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_id_unstripped              VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (hash_value_unstripped          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (signature_so_unstripped        VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (signature_sta_unstripped       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (signature_sta_fm_unstripped    NUMBER);
-- stripped sql_text
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_length                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_text_clob_stripped         CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_text                       VARCHAR2(4000));
-- unstripped sql_text
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_text_clob                  CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_length_unstripped          NUMBER);
-- sql_text for sqlt_profile
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_text_in_pieces             CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sql_length_in_pieces           NUMBER);
-- audit trail
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (user_id                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (username                       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sqlt_user_role                 VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (tool_start_timestamp           TIMESTAMP(6) WITH TIME ZONE);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (tool_start_date                DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (tool_end_date                  DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (statement_response_time        INTERVAL DAY(2) TO SECOND(6));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (restore_date                   DATE);
-- counts
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (mat_view_rewrite_enabled_count NUMBER);
-- dbms_stats parameters
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_autostats_target         VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_publish                  VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_incremental              VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_stale_percent            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_estimate_percent         VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_degree                   VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_cascade                  VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_no_invalidate            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_method_opt               VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_granularity              VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_stats_retention          VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_approximate_ndv          VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_incr_internal_control    VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (param_concurrent               VARCHAR2(256));
-- important cbo init.ora params
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (optimizer_features_enable      VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (db_block_size                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (db_file_multiblock_read_count  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (udb_file_optimizer_read_count  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (udb_file_exec_read_count       NUMBER);
-- important init.ora params
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (nls_sort                       VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (nls_sort_session               VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (nls_sort_instance              VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (nls_sort_global                VARCHAR2(40));
-- system statistics
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (cpuspeednw                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (cpuspeed                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (ioseektim                      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (iotfrspeed                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (mbrc                           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (sreadtim                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (mreadtim                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (maxthr                         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (slavethr                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (cpu_cost_scaling_factor        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (synthetized_mbrc_and_readtim   CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (actual_sreadtim                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (actual_mreadtim                NUMBER);
-- io calibration (dba_rsrc_io_calibrate and v$io_calibration_status)
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (ioc_start_time                 TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (ioc_end_time                   TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (ioc_max_iops                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (ioc_max_mbps                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (ioc_max_pmbps                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (ioc_latency                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (ioc_num_physical_disks         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (ioc_status                     VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (ioc_calibration_time           TIMESTAMP(3));
-- plans
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (best_plan_hash_value           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (worst_plan_hash_value          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (xplain_plan_hash_value         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (xecute_plan_hash_value         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (xecute_child_number            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (px_servers_executions          NUMBER);
-- file names
-- file_tc_sh xpress.sh
-- file_tc_sqltc xpress.sql
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_main                 VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_metadata             VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_metadata1            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_metadata2            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_system_stats         VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_schema_stats         VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_set_cbo_env          VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_lite                 VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_readme               VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_readme_text          VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_10053_xtract_udump        VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_10053_xtract              VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_10053_udump               VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_10053                     VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_10046_10053_udump         VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_10046_10053               VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_10046_split               VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_10053_split               VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_tcscript             VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_tcsql                VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_tcbuilder            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_exp_params           VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_exp_params2          VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_exp_driver           VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_imp_script           VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sqlt_profile              VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sta_report_mem            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sta_script_mem            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sta_report_txt            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sta_script_txt            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sta_report_awr            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sta_script_awr            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_mon_report_active         VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_mon_report_html           VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_mon_report_text           VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_mon_report_driver         VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_sql_detail_active         VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_awrrpt_driver             VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_addmrpt_driver            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_ashrpt_driver             VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_trcanlzr_html             VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_trcanlzr_txt              VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_trcanlzr_log              VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_remote_driver             VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tkprof_px_driver          VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_trcanlzr_px_html          VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_trcanlzr_px_txt           VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_trcanlzr_px_log           VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_script_output_driver      VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_bde_chk_cbo               VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_process_log               VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_purge                  VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_restore                VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_del_hgrm               VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_plan                   VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_10053                  VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_flush                  VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_q                      VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_sql                    VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_sh                     VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_sqltc                  VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_setup                  VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_readme                 VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_pkg                    VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_selectivity            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tc_selectivity_aux        VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tcx_install_sql           VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tcx_install_sh            VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_tcx_pkg                   VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_statement ADD (file_perfhub_driver            VARCHAR2(256));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_sql_plan_table (
statement_id VARCHAR2(30) NOT NULL,
statid       VARCHAR2(30)
);

GRANT SELECT, INSERT, DELETE ON &&tool_repository_schema..sqlt$_sql_plan_table TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_sql_plan_table TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_sql_plan_table FOR &&tool_repository_schema..sqlt$_sql_plan_table;

ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (plan_id                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (timestamp                DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (remarks                  VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (operation                VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (options                  VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (object_node              VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (object_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (object_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (object_alias             VARCHAR2(65));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (object_instance          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (object_type              VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (optimizer                VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (search_columns           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (id                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (parent_id                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (depth                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (position                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (cost                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (cardinality              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (bytes                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (other_tag                VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (partition_start          VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (partition_stop           VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (partition_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (other                    CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (other_xml                CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (distribution             VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (cpu_cost                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (io_cost                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (temp_space               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (access_predicates        VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (filter_predicates        VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (projection               VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (time                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_plan_table ADD (qblock_name              VARCHAR2(257));

DROP INDEX &&tool_repository_schema..sqlt$_sql_plan_table_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_sql_plan_table_n1 ON &&tool_repository_schema..sqlt$_sql_plan_table
(statement_id, id);

DROP INDEX &&tool_repository_schema..sqlt$_sql_plan_table_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_sql_plan_table_n2 ON &&tool_repository_schema..sqlt$_sql_plan_table
(statement_id, parent_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sqltext_with_newlines FOR &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines ADD (inst_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines ADD (address      VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines ADD (hash_value   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines ADD (sql_id       VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines ADD (command_type NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines ADD (piece        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqltext_with_newlines ADD (sql_text     VARCHAR2(64));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sqlarea (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sqlarea TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sqlarea FOR &&tool_repository_schema..sqlt$_gv$sqlarea;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (inst_id                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (sql_text                       VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (sql_fulltext                   CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (sql_id                         VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (sharable_mem                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (persistent_mem                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (runtime_mem                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (sorts                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (version_count                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (loaded_versions                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (open_versions                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (users_opening                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (fetches                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (executions                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (px_servers_executions          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (end_of_fetch_count             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (users_executing                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (loads                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (first_load_time                VARCHAR2(19));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (invalidations                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (parse_calls                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (disk_reads                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (direct_writes                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (buffer_gets                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (application_wait_time          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (concurrency_wait_time          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (cluster_wait_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (user_io_wait_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (plsql_exec_time                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (java_exec_time                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (rows_processed                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (command_type                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (optimizer_mode                 VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (optimizer_cost                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (optimizer_env_hash_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (parsing_user_id                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (parsing_schema_id              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (parsing_schema_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (kept_versions                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (address                        VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (hash_value                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (old_hash_value                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (plan_hash_value                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (module                         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (module_hash                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (action                         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (action_hash                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (serializable_aborts            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (outline_category               VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (cpu_time                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (elapsed_time                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (outline_sid                    VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (last_active_child_address      VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (remote                         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (object_status                  VARCHAR2(19));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (literal_hash_value             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (last_load_time                 DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (is_obsolete                    VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (is_bind_sensitive              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (is_bind_aware                  VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (child_latch                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (sql_profile                    VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (sql_patch                      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (sql_plan_baseline              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (program_id                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (program_line#                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (exact_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (force_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (last_active_time               DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (typecheck_mem                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (io_cell_offload_eligible_bytes NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (io_interconnect_bytes          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (io_disk_bytes                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (physical_read_requests         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (physical_read_bytes            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (physical_write_requests        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (physical_write_bytes           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (optimized_phy_read_requests    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (locked_total                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (pinned_total                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (io_cell_uncompressed_bytes     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (io_cell_offload_returned_bytes NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (is_reoptimizable               VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea ADD (is_resolved_adaptive_plan      VARCHAR2(1));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sqlstats (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sqlstats TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sqlstats FOR &&tool_repository_schema..sqlt$_gv$sqlstats;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (inst_id                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (sql_text                       VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (sql_fulltext                   CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (sql_id                         VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (last_active_time               DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (last_active_child_address      VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (plan_hash_value                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (parse_calls                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (disk_reads                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (direct_writes                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (buffer_gets                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (rows_processed                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (serializable_aborts            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (fetches                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (executions                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (end_of_fetch_count             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (loads                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (version_count                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (invalidations                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (px_servers_executions          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (cpu_time                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (elapsed_time                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (avg_hard_parse_time            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (application_wait_time          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (concurrency_wait_time          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (cluster_wait_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (user_io_wait_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (plsql_exec_time                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (java_exec_time                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (sorts                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (sharable_mem                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (total_sharable_mem             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (typecheck_mem                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (io_cell_offload_eligible_bytes NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (io_interconnect_bytes          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (physical_read_requests         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (physical_read_bytes            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (physical_write_requests        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (physical_write_bytes           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (exact_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (force_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (io_cell_uncompressed_bytes     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD (io_cell_offload_returned_bytes NUMBER);
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_PARSE_CALLS             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_DISK_READS              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_DIRECT_WRITES           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_BUFFER_GETS             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_ROWS_PROCESSED          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_FETCH_COUNT             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_EXECUTION_COUNT         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_PX_SERVERS_EXECUTIONS   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_END_OF_FETCH_COUNT      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_CPU_TIME                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_ELAPSED_TIME            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_APPLICATION_WAIT_TIME   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_CONCURRENCY_TIME        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_CLUSTER_WAIT_TIME       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_USER_IO_WAIT_TIME       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_PLSQL_EXEC_TIME         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_JAVA_EXEC_TIME          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_SORTS                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_LOADS                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_INVALIDATIONS           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_PHYSICAL_READ_REQUESTS  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_PHYSICAL_READ_BYTES     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_PHYSICAL_WRITE_REQUESTS NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_PHYSICAL_WRITE_BYTES    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_IO_INTERCONNECT_BYTES   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_CELL_OFFLOAD_ELIG_BYTES NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( DELTA_CELL_UNCOMPRESSED_BYTES NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats ADD ( OBSOLETE_COUNT                NUMBER);


/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sqlarea_plan_hash FOR &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (inst_id                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (sql_text                       VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (sql_fulltext                   CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (address                        VARCHAR2(16));
-- gv$sqlarea_plan_hash.hash_value = gv$sql.old_hash_value
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (hash_value                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (sql_id                         VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (plan_hash_value                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (version_count                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (last_active_child_address      VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (sharable_mem                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (persistent_mem                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (runtime_mem                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (sorts                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (loaded_versions                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (open_versions                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (users_opening                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (users_executing                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (fetches                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (executions                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (px_servers_executions          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (end_of_fetch_count             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (loads                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (first_load_time                DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (last_load_time                 DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (last_active_time               DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (invalidations                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (parse_calls                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (disk_reads                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (direct_writes                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (buffer_gets                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (cpu_time                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (elapsed_time                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (application_wait_time          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (concurrency_wait_time          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (cluster_wait_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (user_io_wait_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (plsql_exec_time                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (java_exec_time                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (rows_processed                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (command_type                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (optimizer_mode                 VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (optimizer_cost                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (optimizer_env_hash_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (parsing_user_id                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (parsing_schema_id              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (parsing_schema_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (kept_versions                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (module                         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (module_hash                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (action                         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (action_hash                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (serializable_aborts            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (outline_category               VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (outline_sid                    VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (remote                         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (object_status                  VARCHAR2(19));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (literal_hash_value             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (sql_profile                    VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (program_id                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (program_line#                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (exact_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (force_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (typecheck_mem                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (io_cell_offload_eligible_bytes NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (io_interconnect_bytes          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (physical_read_requests         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (physical_read_bytes            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (physical_write_requests        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (physical_write_bytes           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (optimized_phy_read_requests    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (io_cell_uncompressed_bytes     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (io_cell_offload_returned_bytes NUMBER);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash ADD (in_plan_extension              CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash_n1 ON &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash
(statement_id, plan_hash_value);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sqlstats_plan_hash FOR &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (inst_id                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (sql_text                       VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (sql_fulltext                   CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (sql_id                         VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (last_active_time               DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (last_active_child_address      VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (plan_hash_value                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (parse_calls                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (disk_reads                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (direct_writes                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (buffer_gets                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (rows_processed                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (serializable_aborts            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (fetches                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (executions                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (end_of_fetch_count             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (loads                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (version_count                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (invalidations                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (px_servers_executions          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (cpu_time                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (elapsed_time                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (avg_hard_parse_time            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (application_wait_time          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (concurrency_wait_time          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (cluster_wait_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (user_io_wait_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (plsql_exec_time                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (java_exec_time                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (sorts                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (sharable_mem                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (total_sharable_mem             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (typecheck_mem                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (io_cell_offload_eligible_bytes NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (io_interconnect_bytes          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (physical_read_requests         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (physical_read_bytes            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (physical_write_requests        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (physical_write_bytes           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (exact_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (force_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (io_cell_uncompressed_bytes     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD (io_cell_offload_returned_bytes NUMBER);
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_PARSE_CALLS             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_DISK_READS              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_DIRECT_WRITES           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_BUFFER_GETS             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_ROWS_PROCESSED          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_FETCH_COUNT             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_EXECUTION_COUNT         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_PX_SERVERS_EXECUTIONS   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_END_OF_FETCH_COUNT      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_CPU_TIME                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_ELAPSED_TIME            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_APPLICATION_WAIT_TIME   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_CONCURRENCY_TIME        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_CLUSTER_WAIT_TIME       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_USER_IO_WAIT_TIME       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_PLSQL_EXEC_TIME         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_JAVA_EXEC_TIME          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_SORTS                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_LOADS                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_INVALIDATIONS           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_PHYSICAL_READ_REQUESTS  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_PHYSICAL_READ_BYTES     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_PHYSICAL_WRITE_REQUESTS NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_PHYSICAL_WRITE_BYTES    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_IO_INTERCONNECT_BYTES   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_CELL_OFFLOAD_ELIG_BYTES NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sqlstats_plan_hash ADD ( DELTA_CELL_UNCOMPRESSED_BYTES NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql FOR &&tool_repository_schema..sqlt$_gv$sql;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (inst_id                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (sql_text                       VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (sql_fulltext                   CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (sql_id                         VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (sharable_mem                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (persistent_mem                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (runtime_mem                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (sorts                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (loaded_versions                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (open_versions                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (users_opening                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (fetches                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (executions                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (px_servers_executions          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (end_of_fetch_count             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (users_executing                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (loads                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (first_load_time                VARCHAR2(19));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (invalidations                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (parse_calls                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (disk_reads                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (direct_writes                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (buffer_gets                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (application_wait_time          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (concurrency_wait_time          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (cluster_wait_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (user_io_wait_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (plsql_exec_time                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (java_exec_time                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (rows_processed                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (command_type                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (optimizer_mode                 VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (optimizer_cost                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (optimizer_env_hash_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (parsing_user_id                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (parsing_schema_id              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (parsing_schema_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (kept_versions                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (address                        VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (type_chk_heap                  VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (hash_value                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (old_hash_value                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (plan_hash_value                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (child_number                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (service                        VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (service_hash                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (module                         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (module_hash                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (action                         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (action_hash                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (serializable_aborts            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (outline_category               VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (cpu_time                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (elapsed_time                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (outline_sid                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (child_address                  VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (sqltype                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (remote                         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (object_status                  VARCHAR2(19));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (literal_hash_value             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (last_load_time                 VARCHAR2(19));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (is_obsolete                    VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (is_bind_sensitive              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (is_bind_aware                  VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (is_shareable                   VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (child_latch                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (sql_profile                    VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (sql_patch                      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (sql_plan_baseline              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (program_id                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (program_line#                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (exact_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (force_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (last_active_time               DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (typecheck_mem                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (io_cell_offload_eligible_bytes NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (io_interconnect_bytes          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (io_disk_bytes                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (physical_read_requests         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (physical_read_bytes            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (physical_write_requests        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (physical_write_bytes           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (optimized_phy_read_requests    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (locked_total                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (pinned_total                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (io_cell_uncompressed_bytes     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (io_cell_offload_returned_bytes NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (is_reoptimizable               VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (is_resolved_adaptive_plan      VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (im_scans                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (im_scan_bytes_uncompressed     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (im_scan_bytes_inmemory         NUMBER);
-- 171002
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (DDL_NO_INVALIDATE              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (IS_ROLLING_INVALID             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (IS_ROLLING_REFRESH_INVALID     VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (RESULT_CACHE                   VARCHAR2(1));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql ADD (in_plan_extension              CHAR(1));


/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_plan (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_plan TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_plan FOR &&tool_repository_schema..sqlt$_gv$sql_plan;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (inst_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (address               VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (hash_value            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (sql_id                VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (plan_hash_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (child_address         VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (child_number          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (timestamp             DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (operation             VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (options               VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (object_node           VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (object#               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (object_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (object_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (object_alias          VARCHAR2(65));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (object_type           VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (optimizer             VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (id                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (parent_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (depth                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (position              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (search_columns        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (cost                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (cardinality           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (bytes                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (other_tag             VARCHAR2(35));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (partition_start       VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (partition_stop        VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (partition_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (other                 VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (distribution          VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (cpu_cost              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (io_cost               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (temp_space            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (access_predicates     VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (filter_predicates     VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (projection            VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (time                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (qblock_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (remarks               VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (other_xml             CLOB);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (in_plan_extension     CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (real_depth            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (plan_operation        VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (operation_caption     VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (sanitized_other_xml   CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (binds_html_table      CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan ADD (binds_html_table_capt CLOB);

DROP INDEX &&tool_repository_schema..sqlt$_gv$sql_plan_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$sql_plan_n1 ON &&tool_repository_schema..sqlt$_gv$sql_plan
(statement_id, plan_hash_value, inst_id, child_number, id);

DROP INDEX &&tool_repository_schema..sqlt$_gv$sql_plan_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$sql_plan_n2 ON &&tool_repository_schema..sqlt$_gv$sql_plan
(statement_id, plan_hash_value, inst_id, child_number, parent_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_plan_statistics TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_plan_statistics FOR &&tool_repository_schema..sqlt$_gv$sql_plan_statistics;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (inst_id                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (address                 VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (hash_value              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (sql_id                  VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (plan_hash_value         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (child_address           VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (child_number            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (operation_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (executions              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (last_starts             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (starts                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (last_output_rows        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (output_rows             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (last_cr_buffer_gets     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (cr_buffer_gets          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (last_cu_buffer_gets     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (cu_buffer_gets          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (last_disk_reads         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (disk_reads              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (last_disk_writes        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (disk_writes             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (last_elapsed_time       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (elapsed_time            NUMBER);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (top_last_cr_buffer_gets NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (top_cr_buffer_gets      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (top_last_cu_buffer_gets NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (top_cu_buffer_gets      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (top_last_disk_reads     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (top_disk_reads          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (top_last_disk_writes    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (top_disk_writes         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (top_last_elapsed_time   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_statistics ADD (top_elapsed_time        NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_gv$sql_plan_stats_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$sql_plan_stats_n1 ON &&tool_repository_schema..sqlt$_gv$sql_plan_statistics
(statement_id, plan_hash_value, inst_id, child_number, operation_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_workarea TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_workarea FOR &&tool_repository_schema..sqlt$_gv$sql_workarea;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (inst_id                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (address                VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (hash_value             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (sql_id                 VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (child_number           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (workarea_address       VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (operation_type         VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (operation_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (policy                 VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (estimated_optimal_size NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (estimated_onepass_size NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (last_memory_used       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (last_execution         VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (last_degree            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (total_executions       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (optimal_executions     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (onepass_executions     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (multipasses_executions NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (active_time            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (max_tempseg_size       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (last_tempseg_size      NUMBER);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_workarea ADD (workarea_html_table    CLOB);

DROP INDEX &&tool_repository_schema..sqlt$_gv$sql_workarea_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$sql_workarea_n1 ON &&tool_repository_schema..sqlt$_gv$sql_workarea
(statement_id, inst_id, child_number, operation_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_optimizer_env TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_optimizer_env FOR &&tool_repository_schema..sqlt$_gv$sql_optimizer_env;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (inst_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (address         VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (hash_value      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (sql_id          VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (child_address   VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (child_number    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (id              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (name            VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (isdefault       VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (value           VARCHAR2(25));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_optimizer_env ADD (plan_hash_value NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_gv$sql_opt_env_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$sql_opt_env_n1 ON &&tool_repository_schema..sqlt$_gv$sql_optimizer_env
(statement_id, inst_id, child_number);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_bind_capture TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_bind_capture FOR &&tool_repository_schema..sqlt$_gv$sql_bind_capture;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (inst_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (address           VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (hash_value        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (sql_id            VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (child_address     VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (child_number      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (position          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (dup_position      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (datatype          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (datatype_string   VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (character_sid     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (precision         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (scale             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (max_length        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (was_captured      VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (last_captured     DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (value_string      VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (value_anydata     SYS.ANYDATA);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (plan_hash_value   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_bind_capture ADD (value_string_date VARCHAR2(4000));

DROP INDEX &&tool_repository_schema..sqlt$_gv$sql_bind_capture_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$sql_bind_capture_n1 ON &&tool_repository_schema..sqlt$_gv$sql_bind_capture
(statement_id, plan_hash_value, inst_id, child_number);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_shared_cursor TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_shared_cursor FOR &&tool_repository_schema..sqlt$_gv$sql_shared_cursor;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (inst_id                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (sql_id                        VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (address                       VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (child_address                 VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (child_number                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (unbound_cursor                VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (sql_type_mismatch             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (optimizer_mismatch            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (outline_mismatch              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (stats_row_mismatch            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (literal_mismatch              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (sec_depth_mismatch            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (force_hard_parse              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (explain_plan_cursor           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (buffered_dml_mismatch         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (pdml_env_mismatch             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (inst_drtld_mismatch           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (slave_qc_mismatch             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (typecheck_mismatch            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (auth_check_mismatch           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (bind_mismatch                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (describe_mismatch             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (language_mismatch             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (translation_mismatch          VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (row_level_sec_mismatch        VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (bind_equiv_failure            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (insuff_privs                  VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (insuff_privs_rem              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (remote_trans_mismatch         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (logminer_session_mismatch     VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (incomp_ltrl_mismatch          VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (overlap_time_mismatch         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (sql_redirect_mismatch         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (edition_mismatch              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (mv_query_gen_mismatch         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (user_bind_peek_mismatch       VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (typchk_dep_mismatch           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (no_trigger_mismatch           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (flashback_cursor              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (anydata_transformation        VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (incomplete_cursor             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (pddl_env_mismatch             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (top_level_rpi_cursor          VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (different_long_length         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (logical_standby_apply         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (diff_call_durn                VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (bind_uacs_diff                VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (plsql_cmp_switchs_diff        VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (cursor_parts_mismatch         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (stb_object_mismatch           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (row_ship_mismatch             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (crossedition_trigger_mismatch VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (pq_slave_mismatch             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (top_level_ddl_mismatch        VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (multi_px_mismatch             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (bind_peeked_pq_mismatch       VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (mv_rewrite_mismatch           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (roll_invalid_mismatch         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (optimizer_mode_mismatch       VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (px_mismatch                   VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (mv_staleobj_mismatch          VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (flashback_table_mismatch      VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (litrep_comp_mismatch          VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (plsql_debug                   VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (load_optimizer_stats          VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (acl_mismatch                  VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (flashback_archive_mismatch    VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (lock_user_schema_failed       VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (remote_mapping_mismatch       VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (load_runtime_heap_failed      VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (hash_match_failed             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (purged_cursor                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (bind_length_upgradeable       VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (use_feedback_stats            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (reason                        CLOB);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_shared_cursor ADD (sanitized_reason              CLOB);

/* ------------------------------------------------------------------------- */

DROP TABLE &&tool_repository_schema..sqlg$_sql_shared_cursor_n;
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..sqlg$_sql_shared_cursor_n (
statement_id NUMBER NOT NULL
) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..sqlg$_sql_shared_cursor_n TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlg$_sql_shared_cursor_n FOR &&tool_repository_schema..sqlg$_sql_shared_cursor_n;

ALTER TABLE &&tool_repository_schema..sqlg$_sql_shared_cursor_n ADD (inst_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlg$_sql_shared_cursor_n ADD (child_number    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlg$_sql_shared_cursor_n ADD (child_address   VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlg$_sql_shared_cursor_n ADD (plan_hash_value NUMBER);
ALTER TABLE &&tool_repository_schema..sqlg$_sql_shared_cursor_n ADD (column_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlg$_sql_shared_cursor_n ADD (column_name     VARCHAR2(257));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_sql_shared_cursor_d (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_sql_shared_cursor_d TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_sql_shared_cursor_d FOR &&tool_repository_schema..sqlt$_sql_shared_cursor_d;

ALTER TABLE &&tool_repository_schema..sqlt$_sql_shared_cursor_d ADD (inst_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_shared_cursor_d ADD (child_number       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_shared_cursor_d ADD (child_address      VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_sql_shared_cursor_d ADD (plan_hash_value    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sql_shared_cursor_d ADD (not_shared_reason  VARCHAR2(4000));

DROP INDEX &&tool_repository_schema..sqlt$_sql_shared_cursor_d_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_sql_shared_cursor_d_n1 ON &&tool_repository_schema..sqlt$_sql_shared_cursor_d
(statement_id, inst_id, child_number, plan_hash_value);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_histogram (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_cs_histogram TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_cs_histogram FOR &&tool_repository_schema..sqlt$_gv$sql_cs_histogram;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_histogram ADD (inst_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_histogram ADD (address      VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_histogram ADD (hash_value   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_histogram ADD (sql_id       VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_histogram ADD (child_number NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_histogram ADD (bucket_id    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_histogram ADD (count        NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_cs_selectivity FOR &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity ADD (inst_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity ADD (address      VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity ADD (hash_value   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity ADD (sql_id       VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity ADD (child_number NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity ADD (predicate    VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity ADD (range_id     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity ADD (low          VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_selectivity ADD (high         VARCHAR2(10));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_cs_statistics TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_cs_statistics FOR &&tool_repository_schema..sqlt$_gv$sql_cs_statistics;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (inst_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (address             VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (hash_value          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (sql_id              VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (child_number        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (bind_set_hash_value NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (peeked              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (executions          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (rows_processed      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (buffer_gets         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_cs_statistics ADD (cpu_time            NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$object_dependency (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$object_dependency TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$object_dependency FOR &&tool_repository_schema..sqlt$_gv$object_dependency;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$object_dependency ADD (inst_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$object_dependency ADD (from_address VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$object_dependency ADD (from_hash    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$object_dependency ADD (to_owner     VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$object_dependency ADD (to_name      VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$object_dependency ADD (to_address   VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$object_dependency ADD (to_hash      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$object_dependency ADD (to_type      NUMBER);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_gv$object_dependency ADD (depth        NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$parameter2 (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$parameter2 TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$parameter2 FOR &&tool_repository_schema..sqlt$_gv$parameter2;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (inst_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (num                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (name                  VARCHAR2(80));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (type                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (value                 VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (display_value         VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (isdefault             VARCHAR2(6));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (isses_modifiable      VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (issys_modifiable      VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (isinstance_modifiable VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (ismodified            VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (isadjusted            VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (isdeprecated          VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (isbasic               VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (description           VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (ordinal               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter2 ADD (update_comment        VARCHAR2(255));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$nls_parameters (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$nls_parameters TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$nls_parameters FOR &&tool_repository_schema..sqlt$_gv$nls_parameters;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$nls_parameters ADD (inst_id   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$nls_parameters ADD (parameter VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$nls_parameters ADD (value     VARCHAR2(64));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$system_parameter (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$system_parameter TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$system_parameter FOR &&tool_repository_schema..sqlt$_gv$system_parameter;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (inst_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (num                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (name                  VARCHAR2(80));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (type                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (value                 VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (display_value         VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (isdefault             VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (isses_modifiable      VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (issys_modifiable      VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (isinstance_modifiable VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (ismodified            VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (isadjusted            VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (isdeprecated          VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (isbasic               VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (description           VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (update_comment        VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$system_parameter ADD (hash                  NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_nls_database_parameters (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_nls_database_parameters TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_nls_database_parameters FOR &&tool_repository_schema..sqlt$_nls_database_parameters;

ALTER TABLE &&tool_repository_schema..sqlt$_nls_database_parameters ADD (parameter VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_nls_database_parameters ADD (value     VARCHAR2(257));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_v$session_fix_control (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_v$session_fix_control TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_v$session_fix_control FOR &&tool_repository_schema..sqlt$_v$session_fix_control;

ALTER TABLE &&tool_repository_schema..sqlt$_v$session_fix_control ADD (session_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_v$session_fix_control ADD (bugno                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_v$session_fix_control ADD (value                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_v$session_fix_control ADD (sql_feature              VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_v$session_fix_control ADD (description              VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_v$session_fix_control ADD (optimizer_feature_enable VARCHAR2(25));
ALTER TABLE &&tool_repository_schema..sqlt$_v$session_fix_control ADD (event                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_v$session_fix_control ADD (is_default               NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$parameter_cbo TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$parameter_cbo FOR &&tool_repository_schema..sqlt$_gv$parameter_cbo;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (inst_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (num                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (name                  VARCHAR2(80));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (type                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (value                 VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (display_value         VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (isdefault             VARCHAR2(6));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (isses_modifiable      VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (issys_modifiable      VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (isinstance_modifiable VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (ismodified            VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (isadjusted            VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (isdeprecated          VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (isbasic               VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (description           VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$parameter_cbo ADD (update_comment        VARCHAR2(255));

DROP INDEX &&tool_repository_schema..sqlt$_gv$parameter_cbo_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$parameter_cbo_n1 ON &&tool_repository_schema..sqlt$_gv$parameter_cbo
(statement_id, inst_id, name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_monitor TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_monitor FOR &&tool_repository_schema..sqlt$_gv$sql_monitor;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (inst_id                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (key                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (status                    VARCHAR2(19));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (user#                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (username                  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (module                    VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor MODIFY (module                 VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (action                    VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor MODIFY (action                 VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (service_name              VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (client_identifier         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (client_info               VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (program                   VARCHAR2(48));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (plsql_entry_object_id     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (plsql_entry_subprogram_id NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (plsql_object_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (plsql_subprogram_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (first_refresh_time        DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (last_refresh_time         DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (refresh_count             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (sid                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (process_name              VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (sql_id                    VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (sql_text                  VARCHAR2(2000));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (is_full_sqltext           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (sql_exec_start            DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (sql_exec_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (sql_plan_hash_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (exact_matching_signature  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (force_matching_signature  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (sql_child_address         VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (session_serial#           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (px_is_cross_instance      VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (px_maxdop                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (px_maxdop_instances       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (px_servers_requested      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (px_servers_allocated      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (px_server#                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (px_server_group           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (px_server_set             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (px_qcinst_id              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (px_qcsid                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (error_number              VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (error_facility            VARCHAR2(4));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (error_message             VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (binds_xml                 CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (other_xml                 CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (elapsed_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (queuing_time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (cpu_time                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (fetches                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (buffer_gets               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (disk_reads                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (direct_writes             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (io_interconnect_bytes     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (physical_read_requests    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (physical_read_bytes       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (physical_write_requests   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (physical_write_bytes      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (application_wait_time     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (concurrency_wait_time     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (cluster_wait_time         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (user_io_wait_time         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (plsql_exec_time           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (java_exec_time            NUMBER);
-- 171002
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( RM_LAST_ACTION                  VARCHAR2(48));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( RM_LAST_ACTION_REASON           VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( RM_LAST_ACTION_TIME             DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( RM_CONSUMER_GROUP               VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( IS_ADAPTIVE_PLAN                VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( IS_FINAL_PLAN                   VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( IN_DBOP_NAME                    VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( IN_DBOP_EXEC_ID                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( IO_CELL_UNCOMPRESSED_BYTES      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( IO_CELL_OFFLOAD_ELIGIBLE_BYTES  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD ( IO_CELL_OFFLOAD_RETURNED_BYTES  NUMBER);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_monitor ADD (sql_child_number          NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_gv$sql_monitor_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$sql_monitor_n1 ON &&tool_repository_schema..sqlt$_gv$sql_monitor
(statement_id, sql_plan_hash_value, sql_exec_start, sql_exec_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sql_plan_monitor TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sql_plan_monitor FOR &&tool_repository_schema..sqlt$_gv$sql_plan_monitor;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (inst_id                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (key                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (status                  VARCHAR2(19));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (first_refresh_time      DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (last_refresh_time       DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (first_change_time       DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (last_change_time        DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (refresh_count           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (sid                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (process_name            VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (sql_id                  VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (sql_exec_start          DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (sql_exec_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (sql_plan_hash_value     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (sql_child_address       VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_parent_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_line_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_operation          VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_options            VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_object_owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_object_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_object_type        VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_depth              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_position           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_cost               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_cardinality        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_bytes              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_time               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_partition_start    VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_partition_stop     VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_cpu_cost           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_io_cost            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_temp_space         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (starts                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (output_rows             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (io_interconnect_bytes   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (physical_read_requests  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (physical_read_bytes     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (physical_write_requests NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (physical_write_bytes    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (workarea_mem            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (workarea_max_mem        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (workarea_tempseg        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (workarea_max_tempseg    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_group_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_1_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_1_type        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_1_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_2_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_2_type        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_2_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_3_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_3_type        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_3_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_4_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_4_type        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_4_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_5_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_5_type        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_5_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_6_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_6_type        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_6_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_7_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_7_type        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_7_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_8_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_8_type        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_8_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_9_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_9_type        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_9_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_10_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_10_type       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (otherstat_10_value      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (other_xml               CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sql_plan_monitor ADD (plan_operation_inactive NUMBER);




DROP INDEX &&tool_repository_schema..sqlt$_gv$sql_plan_monitor_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$sql_plan_monitor_n1 ON &&tool_repository_schema..sqlt$_gv$sql_plan_monitor
(statement_id, sql_plan_hash_value, sql_exec_start, sql_exec_id, plan_line_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$active_session_histor TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$active_session_histor FOR &&tool_repository_schema..sqlt$_gv$active_session_histor;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (inst_id                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sample_id                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sample_time                 TIMESTAMP(3));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (is_awr_sample               VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (session_id                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (session_serial#             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (session_type                VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (flags                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (user_id                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sql_id                      VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (is_sqlid_current            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sql_child_number            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sql_opcode                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (force_matching_signature    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (top_level_sql_id            VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (top_level_sql_opcode        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sql_opname                  VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sql_plan_hash_value         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sql_plan_line_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sql_plan_operation          VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sql_plan_options            VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sql_exec_id                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (sql_exec_start              DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (plsql_entry_object_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (plsql_entry_subprogram_id   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (plsql_object_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (plsql_subprogram_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (qc_instance_id              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (qc_session_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (qc_session_serial#          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (px_flags                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (event                       VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (event_id                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (event#                      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (seq#                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (p1text                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (p1                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (p2text                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (p2                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (p3text                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (p3                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (wait_class                  VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (wait_class_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (wait_time                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (session_state               VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (time_waited                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (blocking_session_status     VARCHAR2(11));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (blocking_session            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (blocking_session_serial#    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (blocking_inst_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (blocking_hangchain_info     VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (current_obj#                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (current_file#               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (current_block#              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (current_row#                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (top_level_call#             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (top_level_call_name         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (consumer_group_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (xid                         RAW(8));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (remote_instance#            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (time_model                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_connection_mgmt          VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_parse                    VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_hard_parse               VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_sql_execution            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_plsql_execution          VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_plsql_rpc                VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_plsql_compilation        VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_java_execution           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_bind                     VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_cursor_close             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_sequence_load            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (capture_overhead            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (replay_overhead             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (is_captured                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (is_replayed                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (service_hash                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (program                     VARCHAR2(48));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (module                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (action                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (client_id                   VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (machine                     VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (port                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (ecid                        VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (dbreplay_file_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (dbreplay_call_counter       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (tm_delta_time               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (tm_delta_cpu_time           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (tm_delta_db_time            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (delta_time                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (delta_read_io_requests      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (delta_write_io_requests     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (delta_read_io_bytes         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (delta_write_io_bytes        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (delta_interconnect_io_bytes NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (pga_allocated               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (temp_space_allocated        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_inmemory_populate           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_inmemory_prepopulate        VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_inmemory_query              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_inmemory_repopulate         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (in_inmemory_trepopulate        VARCHAR2(1));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (DBOP_NAME                   VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$active_session_histor ADD (DBOP_EXEC_ID                NUMBER);
/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$im_segments (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$im_segments TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$im_segments FOR &&tool_repository_schema..sqlt$_gv$im_segments;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (owner                     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (segment_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (partition_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (segment_type              VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (tablespace_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (inmemory_size             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (bytes                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (bytes_not_populated       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (populate_status           VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (inmemory_priority         VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (inmemory_distribute       VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (inmemory_compression      VARCHAR2(17));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (inmemory_duplicate      VARCHAR2(17));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (INMEMORY_SERVICE        VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (INMEMORY_SERVICE_NAME   VARCHAR2(129));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_segments ADD (IS_EXTERNAL             VARCHAR2(5));



/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$im_column_level (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$im_column_level TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$im_column_level FOR &&tool_repository_schema..sqlt$_gv$im_column_level;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_column_level ADD (inst_id                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_column_level ADD (owner                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_column_level ADD (obj_num                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_column_level ADD (table_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_column_level ADD (segment_column_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_column_level ADD (column_name             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$im_column_level ADD (inmemory_compression    VARCHAR2(26));

/* ------------------------------------------------------------------------- */

-- partition DBA_HIST_ASH only in 11g, by HASH
DECLARE
 part_type VARCHAR2(10);
 already_partitioned EXCEPTION;
BEGIN
 IF :rdbms_version >= '11' AND :rdbms_edition = 'E' AND :partitioning = 'Y' AND :compatible >= '11' THEN
   BEGIN
     SELECT partitioning_type
       INTO part_type
       FROM dba_part_tables
      WHERE table_name = 'SQLT$_DBA_HIST_ACTIVE_SESS_HIS'
        AND owner = '&&tool_repository_schema.';
   EXCEPTION WHEN NO_DATA_FOUND THEN
    part_type := 'NO_PART';
   END;

   IF part_type = 'NO_PART' THEN  --table is not partitioned (requires manual execution of sqltupgdbahistash.sql) or does not exists, try to create partitioned 
        EXECUTE IMMEDIATE 'CREATE TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his (statement_id NUMBER NOT NULL,statid VARCHAR2(30) NOT NULL) '||
                     'PARTITION BY HASH(statement_id) PARTITIONS 32';
   ELSIF part_type = 'RANGE' THEN  -- table is partitioned by INTERVAL (SQLT 12.1.07/12.1.08) so move to HASH
        EXECUTE IMMEDIATE 'ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his RENAME TO sqlt$_dba_hist_ash_old';
        EXECUTE IMMEDIATE 'CREATE TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his PARTITION BY HASH(statement_id) PARTITIONS 32 AS '|| 
                          'SELECT * FROM &&tool_repository_schema..sqlt$_dba_hist_ash_old';
        EXECUTE IMMEDIATE 'DROP TABLE &&tool_repository_schema..sqlt$_dba_hist_ash_old';
   END IF;
 ELSE  -- no license or 10g so create not partitioned (rdbms_version and compatible is mandatory, keeping them to limit partitioning on a smaller installation base)
   EXECUTE IMMEDIATE 'CREATE TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his (statement_id NUMBER NOT NULL,statid VARCHAR2(30) NOT NULL)'; 
 END IF;
END;
/

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_hist_active_sess_his TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_hist_active_sess_his FOR &&tool_repository_schema..sqlt$_dba_hist_active_sess_his;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (snap_id                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (dbid                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (instance_number             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sample_id                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sample_time                 TIMESTAMP(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (session_id                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (session_serial#             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (session_type                VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (flags                       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (user_id                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sql_id                      VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (is_sqlid_current            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sql_child_number            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sql_opcode                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sql_opname                  VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (force_matching_signature    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (top_level_sql_id            VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (top_level_sql_opcode        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sql_plan_hash_value         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sql_plan_line_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sql_plan_operation          VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sql_plan_options            VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sql_exec_id                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (sql_exec_start              DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (plsql_entry_object_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (plsql_entry_subprogram_id   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (plsql_object_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (plsql_subprogram_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (qc_instance_id              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (qc_session_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (qc_session_serial#          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (px_flags                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (event                       VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (event_id                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (seq#                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (p1text                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (p1                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (p2text                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (p2                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (p3text                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (p3                          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (wait_class                  VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (wait_class_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (wait_time                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (session_state               VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (time_waited                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (blocking_session_status     VARCHAR2(11));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (blocking_session            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (blocking_session_serial#    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (blocking_inst_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (blocking_hangchain_info     VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (current_obj#                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (current_file#               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (current_block#              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (current_row#                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (top_level_call#             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (top_level_call_name         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (consumer_group_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (xid                         RAW(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (remote_instance#            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (time_model                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_connection_mgmt          VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_parse                    VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_hard_parse               VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_sql_execution            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_plsql_execution          VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_plsql_rpc                VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_plsql_compilation        VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_java_execution           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_bind                     VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_cursor_close             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_sequence_load            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (capture_overhead            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (replay_overhead             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (is_captured                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (is_replayed                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (service_hash                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (program                     VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (module                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (action                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (client_id                   VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (machine                     VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (port                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (ecid                        VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (dbreplay_file_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (dbreplay_call_counter       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (tm_delta_time               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (tm_delta_cpu_time           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (tm_delta_db_time            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (delta_time                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (delta_read_io_requests      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (delta_write_io_requests     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (delta_read_io_bytes         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (delta_write_io_bytes        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (delta_interconnect_io_bytes NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (pga_allocated               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (temp_space_allocated        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_inmemory_populate           VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_inmemory_prepopulate        VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_inmemory_query              VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_inmemory_repopulate         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (in_inmemory_trepopulate        VARCHAR2(1));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (DBOP_NAME                      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_active_sess_his ADD (DBOP_EXEC_ID                   NUMBER);


/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_hist_seg_stat_obj FOR &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj ADD (dbid            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj ADD (ts#             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj ADD (obj#            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj ADD (dataobj#        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj ADD (owner           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj ADD (object_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj ADD (subobject_name  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj ADD (tablespace_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj ADD (object_type     VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj ADD (partition_type  VARCHAR2(8));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_hist_sqltext (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_hist_sqltext TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_hist_sqltext FOR &&tool_repository_schema..sqlt$_dba_hist_sqltext;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqltext ADD (dbid         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqltext ADD (sql_id       VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqltext ADD (sql_text     CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqltext ADD (command_type NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT ON &&tool_repository_schema..sqlt$_dba_hist_sqlstat TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_dba_hist_sqlstat TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_hist_sqlstat FOR &&tool_repository_schema..sqlt$_dba_hist_sqlstat;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (snap_id                        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (dbid                           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (instance_number                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (sql_id                         VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (plan_hash_value                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (optimizer_cost                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (optimizer_mode                 VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (optimizer_env_hash_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (sharable_mem                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (loaded_versions                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (version_count                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (module                         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (action                         VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (sql_profile                    VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (force_matching_signature       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (parsing_schema_id              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (parsing_schema_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (parsing_user_id                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (fetches_total                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (fetches_delta                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (end_of_fetch_count_total       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (end_of_fetch_count_delta       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (sorts_total                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (sorts_delta                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (executions_total               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (executions_delta               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (px_servers_execs_total         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (px_servers_execs_delta         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (loads_total                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (loads_delta                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (invalidations_total            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (invalidations_delta            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (parse_calls_total              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (parse_calls_delta              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (disk_reads_total               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (disk_reads_delta               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (buffer_gets_total              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (buffer_gets_delta              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (rows_processed_total           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (rows_processed_delta           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (cpu_time_total                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (cpu_time_delta                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (elapsed_time_total             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (elapsed_time_delta             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (iowait_total                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (iowait_delta                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (clwait_total                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (clwait_delta                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (apwait_total                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (apwait_delta                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (ccwait_total                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (ccwait_delta                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (direct_writes_total            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (direct_writes_delta            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (plsexec_time_total             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (plsexec_time_delta             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (javexec_time_total             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (javexec_time_delta             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (io_offload_elig_bytes_total    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (io_offload_elig_bytes_delta    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (io_interconnect_bytes_total    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (io_interconnect_bytes_delta    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (physical_read_requests_total   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (physical_read_requests_delta   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (physical_read_bytes_total      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (physical_read_bytes_delta      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (physical_write_requests_total  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (physical_write_requests_delta  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (physical_write_bytes_total     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (physical_write_bytes_delta     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (optimized_physical_reads_total NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (optimized_physical_reads_delta NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (cell_uncompressed_bytes_total  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (cell_uncompressed_bytes_delta  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (io_offload_return_bytes_total  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (io_offload_return_bytes_delta  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (flag                           NUMBER);
-- 171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (OBSOLETE_COUNT                 NUMBER);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (first_load_time                DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (last_load_time                 DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (in_plan_extension              CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlstat ADD (in_plan_summary_v              CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_dba_hist_sqlstat_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_hist_sqlstat_n1 ON &&tool_repository_schema..sqlt$_dba_hist_sqlstat
(statement_id, plan_hash_value, first_load_time);


/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_hist_sql_plan TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_hist_sql_plan FOR &&tool_repository_schema..sqlt$_dba_hist_sql_plan;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (dbid              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (sql_id            VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (plan_hash_value   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (id                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (operation         VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (options           VARCHAR2(30));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (object_node       VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (object#           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (object_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (object_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (object_alias      VARCHAR2(65));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (object_type       VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (optimizer         VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (parent_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (depth             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (position          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (search_columns    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (cost              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (cardinality       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (bytes             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (other_tag         VARCHAR2(35));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (partition_start   VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (partition_stop    VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (partition_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (other             VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (distribution      VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (cpu_cost          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (io_cost           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (temp_space        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (access_predicates VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (filter_predicates VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (projection        VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (qblock_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (remarks           VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (timestamp         DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sql_plan ADD (other_xml         CLOB);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_hist_sqlbind TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_hist_sqlbind FOR &&tool_repository_schema..sqlt$_dba_hist_sqlbind;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (snap_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (dbid              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (instance_number   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (sql_id            VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (position          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (dup_position      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (datatype          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (datatype_string   VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (character_sid     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (precision         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (scale             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (max_length        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (was_captured      VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (last_captured     DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (value_string      VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (value_anydata     SYS.ANYDATA);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (plan_hash_value   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_sqlbind ADD (value_string_date VARCHAR2(4000));

DROP INDEX &&tool_repository_schema..sqlt$_dba_hist_sqlbind_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_hist_sqlbind_n1 ON &&tool_repository_schema..sqlt$_dba_hist_sqlbind
(statement_id, plan_hash_value, instance_number);

DROP INDEX &&tool_repository_schema..sqlt$_dba_hist_sqlbind_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_hist_sqlbind_n2 ON &&tool_repository_schema..sqlt$_dba_hist_sqlbind
(statement_id, snap_id, instance_number, dbid, sql_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_hist_snapshot TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_hist_snapshot FOR &&tool_repository_schema..sqlt$_dba_hist_snapshot;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (snap_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (dbid                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (instance_number     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (startup_time        TIMESTAMP(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (begin_interval_time TIMESTAMP(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (end_interval_time   TIMESTAMP(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (flush_elapsed       INTERVAL DAY(5) TO SECOND(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (snap_level          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (error_count         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (snap_flag           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_snapshot ADD (snap_timezone       INTERVAL DAY(0) TO SECOND(0));

/* ------------------------------------------------------------------------- */

DROP TABLE &&tool_repository_schema..sqli$_dba_hist_parameter;
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..sqli$_dba_hist_parameter (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..sqli$_dba_hist_parameter TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqli$_dba_hist_parameter FOR &&tool_repository_schema..sqli$_dba_hist_parameter;

ALTER TABLE &&tool_repository_schema..sqli$_dba_hist_parameter ADD (snap_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqli$_dba_hist_parameter ADD (dbid            NUMBER);
ALTER TABLE &&tool_repository_schema..sqli$_dba_hist_parameter ADD (instance_number NUMBER);
ALTER TABLE &&tool_repository_schema..sqli$_dba_hist_parameter ADD (parameter_hash  NUMBER);
ALTER TABLE &&tool_repository_schema..sqli$_dba_hist_parameter ADD (parameter_name  VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqli$_dba_hist_parameter ADD (value           VARCHAR2(512));
ALTER TABLE &&tool_repository_schema..sqli$_dba_hist_parameter ADD (isdefault       VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqli$_dba_hist_parameter ADD (ismodified      VARCHAR2(10));

DROP INDEX &&tool_repository_schema..sqli$_dba_hist_parameter_n1;
CREATE INDEX &&tool_repository_schema..sqli$_dba_hist_parameter_n1 ON &&tool_repository_schema..sqli$_dba_hist_parameter
(statement_id, dbid, instance_number, parameter_hash);

/* ------------------------------------------------------------------------- */

-- modified parameters only
CREATE TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_hist_parameter_m TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_hist_parameter_m FOR &&tool_repository_schema..sqlt$_dba_hist_parameter_m;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m ADD (snap_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m ADD (dbid                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m ADD (instance_number     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m ADD (parameter_hash      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m ADD (parameter_name      VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m ADD (value               VARCHAR2(512));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m ADD (isdefault           VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m ADD (ismodified          VARCHAR2(10));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m ADD (oldest_value_on_awr VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_hist_parameter_m ADD (newest_value_on_awr VARCHAR2(1));


/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_dependencies (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_dependencies TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_dependencies FOR &&tool_repository_schema..sqlt$_dba_dependencies;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies ADD (owner                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies ADD (name                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies ADD (type                 VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies ADD (referenced_owner     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies ADD (referenced_name      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies ADD (referenced_type      VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies ADD (referenced_link_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies ADD (dependency_type      VARCHAR2(4));


-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_dependencies ADD (depth                NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_tables (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT, UPDATE ON &&tool_repository_schema..sqlt$_dba_tables TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_dba_tables TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tables FOR &&tool_repository_schema..sqlt$_dba_tables;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (owner                      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (table_name                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (tablespace_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (cluster_name               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (iot_name                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (status                     VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (pct_free                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (pct_used                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (ini_trans                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (max_trans                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (initial_extent             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (next_extent                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (min_extents                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (max_extents                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (pct_increase               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (freelists                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (freelist_groups            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (logging                    VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (backed_up                  VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (num_rows                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (blocks                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (empty_blocks               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (avg_space                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (chain_cnt                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (avg_row_len                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (avg_space_freelist_blocks  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (num_freelist_blocks        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (degree                     VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (instances                  VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (cache                      VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (table_lock                 VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (sample_size                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (last_analyzed              DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (partitioned                VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (iot_type                   VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (temporary                  VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (secondary                  VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (nested                     VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (buffer_pool                VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (flash_cache                VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (cell_flash_cache           VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (row_movement               VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (global_stats               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (user_stats                 VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (duration                   VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (skip_corrupt               VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (monitoring                 VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (cluster_owner              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (dependencies               VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (compression                VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (compress_for               VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables MODIFY (compress_for            VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (dropped                    VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (read_only                  VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (segment_created            VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (result_cache               VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (inmemory                   VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (inmemory_compression       VARCHAR2(17));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (inmemory_distribute        VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (inmemory_priority          VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (inmemory_duplicate         VARCHAR2(13));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (CLUSTERING                 VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (ACTIVITY_TRACKING          VARCHAR2(23));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (DML_TIMESTAMP              VARCHAR2(25));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (HAS_IDENTITY               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (CONTAINER_DATA             VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (DEFAULT_COLLATION          VARCHAR2(100));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (DUPLICATED                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (SHARDED                    VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (EXTERNAL                   VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (CELLMEMORY                 VARCHAR2(24));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (CONTAINERS_DEFAULT         VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (CONTAINER_MAP              VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (EXTENDED_DATA_LINK         VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (EXTENDED_DATA_LINK_MAP     VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (INMEMORY_SERVICE           VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (INMEMORY_SERVICE_NAME      VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (CONTAINER_MAP_OBJECT       VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (MEMOPTIMIZE_READ           VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (MEMOPTIMIZE_WRITE          VARCHAR2(8));

-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (count_star                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (object_id                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (full_table_scan_cost       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (new_11g_ndv_algorithm_used VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (total_segment_blocks       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (dbms_space_used_bytes      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (dbms_space_alloc_bytes     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (dbms_space_used_blocks     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (dbms_space_alloc_blocks    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (col_group_usage_report     CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (owner_id                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tables ADD (dv_censored                VARCHAR2(1));

DROP INDEX &&tool_repository_schema..sqlt$_dba_tables_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tables_n1 ON &&tool_repository_schema..sqlt$_dba_tables
(statement_id, owner, table_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_nested_tables (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_nested_tables TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_nested_tables FOR &&tool_repository_schema..sqlt$_dba_nested_tables;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables ADD (owner                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables ADD (table_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables ADD (table_type_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables ADD (table_type_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables ADD (parent_table_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables ADD (parent_table_column   VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables ADD (storage_spec          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables ADD (return_type           VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_tables ADD (element_substitutable VARCHAR2(25));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_object_tables (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT, UPDATE ON &&tool_repository_schema..sqlt$_dba_object_tables TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_dba_object_tables TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_object_tables FOR &&tool_repository_schema..sqlt$_dba_object_tables;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (owner                     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (table_name                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (tablespace_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (cluster_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (iot_name                  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (status                    VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (pct_free                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (pct_used                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (ini_trans                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (max_trans                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (initial_extent            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (next_extent               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (min_extents               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (max_extents               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (pct_increase              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (freelists                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (freelist_groups           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (logging                   VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (backed_up                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (num_rows                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (blocks                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (empty_blocks              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (avg_space                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (chain_cnt                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (avg_row_len               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (avg_space_freelist_blocks NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (num_freelist_blocks       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (degree                    VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (instances                 VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (cache                     VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (table_lock                VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (sample_size               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (last_analyzed             DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (partitioned               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (iot_type                  VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (object_id_type            VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (table_type_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (table_type                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (temporary                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (secondary                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (nested                    VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (buffer_pool               VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (flash_cache               VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (cell_flash_cache          VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (row_movement              VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (global_stats              VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (user_stats                VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (duration                  VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (skip_corrupt              VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (monitoring                VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (cluster_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (dependencies              VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (compression               VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (compress_for              VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (dropped                   VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (read_only                 VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (segment_created           VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (result_cache              VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (inmemory                  VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (inmemory_compression      VARCHAR2(17));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (inmemory_distribute       VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (inmemory_priority         VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (inmemory_duplicate        VARCHAR2(13));
-- 171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (EXTERNAL                  VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (CELLMEMORY                VARCHAR2(24));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (INMEMORY_SERVICE          VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (INMEMORY_SERVICE_NAME     VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (MEMOPTIMIZE_READ          VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (MEMOPTIMIZE_WRITE         VARCHAR2(8));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (count_star                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (object_id                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (full_table_scan_cost      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_object_tables ADD (owner_id                  NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_dba_object_tables_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_object_tables_n1 ON &&tool_repository_schema..sqlt$_dba_object_tables
(statement_id, owner, table_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_tab_statistics TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tab_statistics FOR &&tool_repository_schema..sqlt$_dba_tab_statistics;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (owner                     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (table_name                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (partition_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (partition_position        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (subpartition_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (subpartition_position     NUMBER);

-- TABLE, PARTITION, SUBPARTITION, FIXED TABLE
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (object_type               VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (num_rows                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (blocks                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (empty_blocks              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (avg_space                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (chain_cnt                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (avg_row_len               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (avg_space_freelist_blocks NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (num_freelist_blocks       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (avg_cached_blocks         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (avg_cache_hit_ratio       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (sample_size               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (last_analyzed             DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (global_stats              VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (user_stats                VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (stattype_locked           VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (stale_stats               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (scope                     VARCHAR2(7));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_statistics ADD (mutating_num_rows         VARCHAR2(5));

DROP INDEX &&tool_repository_schema..sqlt$_dba_tab_stats_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tab_stats_n1 ON &&tool_repository_schema..sqlt$_dba_tab_statistics
(statement_id, object_type, owner, table_name, partition_name, subpartition_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_stat_extensions TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_stat_extensions FOR &&tool_repository_schema..sqlt$_dba_stat_extensions;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions ADD (owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions ADD (table_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions ADD (extension_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions ADD (extension      CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions ADD (creator        VARCHAR2(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_stat_extensions ADD (droppable      VARCHAR2(3));

DROP INDEX &&tool_repository_schema..sqlt$_dba_stat_extensions_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_stat_extensions_n1 ON &&tool_repository_schema..sqlt$_dba_stat_extensions
(statement_id, owner, table_name, extension_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_tab_modifications TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tab_modifications FOR &&tool_repository_schema..sqlt$_dba_tab_modifications;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications ADD (table_owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications ADD (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications ADD (partition_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications ADD (subpartition_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications ADD (inserts           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications ADD (updates           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications ADD (deletes           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications ADD (timestamp         DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications ADD (truncated         VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_modifications ADD (drop_segments     NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_dba_tab_modif_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tab_modif_n1 ON &&tool_repository_schema..sqlt$_dba_tab_modifications
(statement_id, table_owner, table_name, partition_name, subpartition_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_tab_cols (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_tab_cols TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tab_cols FOR &&tool_repository_schema..sqlt$_dba_tab_cols;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (owner                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (table_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (column_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (data_type            VARCHAR2(106));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (data_type_mod        VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (data_type_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (data_length          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (data_precision       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (data_scale           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (nullable             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (column_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (default_length       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (data_default         CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (num_distinct         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (low_value            RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols MODIFY (low_value         RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (high_value           RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols MODIFY (high_value        RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (density              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (num_nulls            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (num_buckets          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (last_analyzed        DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (sample_size          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (character_set_name   VARCHAR2(44));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (char_col_decl_length NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (global_stats         VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (user_stats           VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (avg_col_len          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (char_length          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (char_used            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (v80_fmt_image        VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (data_upgraded        VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (hidden_column        VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (virtual_column       VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (segment_column_id    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (internal_column_id   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (histogram            VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (qualified_col_name   VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (inmemory_compression VARCHAR2(26));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (USER_GENERATED       VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (DEFAULT_ON_NULL      VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (IDENTITY_COLUMN      VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (SENSITIVE_COLUMN     VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (EVALUATION_EDITION   VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (UNUSABLE_BEFORE      VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (UNUSABLE_BEGINNING   VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (COLLATION            VARCHAR2(100));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (COLLATED_COLUMN_ID   NUMBER);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (in_predicates        VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (in_projection        VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (in_indexes           VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (low_value_cooked     VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (high_value_cooked    VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (popular_values       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (buckets_pop_vals     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (new_density          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (endpoints_count      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (mutating_endpoints   VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (add_column_default   VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_cols ADD (mutating_ndv         VARCHAR2(5));

DROP INDEX &&tool_repository_schema..sqlt$_dba_tab_cols_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tab_cols_n1 ON &&tool_repository_schema..sqlt$_dba_tab_cols
(statement_id, owner, table_name, column_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_tab_cols_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tab_cols_n2 ON &&tool_repository_schema..sqlt$_dba_tab_cols
(statement_id, column_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_nested_table_cols TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_nested_table_cols FOR &&tool_repository_schema..sqlt$_dba_nested_table_cols;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (owner                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (table_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (column_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (data_type            VARCHAR2(106));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (data_type_mod        VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (data_type_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (data_length          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (data_precision       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (data_scale           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (nullable             VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (column_id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (default_length       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (data_default         CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (num_distinct         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (low_value            RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols MODIFY (low_value         RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (high_value           RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols MODIFY (high_value        RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (density              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (num_nulls            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (num_buckets          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (last_analyzed        DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (sample_size          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (character_set_name   VARCHAR2(44));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (char_col_decl_length NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (global_stats         VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (user_stats           VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (avg_col_len          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (char_length          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (char_used            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (v80_fmt_image        VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (data_upgraded        VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (hidden_column        VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (virtual_column       VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (segment_column_id    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (internal_column_id   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (histogram            VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (qualified_col_name   VARCHAR2(4000));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (in_predicates        VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (in_projection        VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (in_indexes           VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (low_value_cooked     VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (high_value_cooked    VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (popular_values       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (buckets_pop_vals     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (new_density          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (endpoints_count      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (mutating_endpoints   VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_nested_table_cols ADD (mutating_ndv         VARCHAR2(5));

DROP INDEX &&tool_repository_schema..sqlt$_dba_nested_table_cols_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_nested_table_cols_n1 ON &&tool_repository_schema..sqlt$_dba_nested_table_cols
(statement_id, owner, table_name, column_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_nested_table_cols_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_nested_table_cols_n2 ON &&tool_repository_schema..sqlt$_dba_nested_table_cols
(statement_id, column_name);

/* ------------------------------------------------------------------------- */

-- only for fixed objects
CREATE TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_tab_col_statistics TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tab_col_statistics FOR &&tool_repository_schema..sqlt$_dba_tab_col_statistics;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (owner         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (table_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (column_name   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (num_distinct  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (low_value     RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics MODIFY (low_value  RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (high_value    RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics MODIFY (high_value RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (density       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (num_nulls     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (num_buckets   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (last_analyzed DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (sample_size   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (global_stats  VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (user_stats    VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (avg_col_len   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (histogram     VARCHAR2(15));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_col_statistics ADD (SCOPE         VARCHAR2(7));

DROP INDEX &&tool_repository_schema..sqlt$_dba_tab_col_stats_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tab_col_stats_n1 ON &&tool_repository_schema..sqlt$_dba_tab_col_statistics
(statement_id, owner, table_name, column_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_indexes (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT, UPDATE ON &&tool_repository_schema..sqlt$_dba_indexes TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_dba_indexes TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_indexes FOR &&tool_repository_schema..sqlt$_dba_indexes;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (owner                     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (index_name                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (index_type                VARCHAR2(27));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (table_owner               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (table_name                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (table_type                VARCHAR2(11));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (uniqueness                VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (compression               VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (prefix_length             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (tablespace_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (ini_trans                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (max_trans                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (initial_extent            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (next_extent               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (min_extents               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (max_extents               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (pct_increase              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (pct_threshold             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (include_column            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (freelists                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (freelist_groups           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (pct_free                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (logging                   VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (blevel                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (leaf_blocks               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (distinct_keys             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (avg_leaf_blocks_per_key   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (avg_data_blocks_per_key   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (clustering_factor         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (status                    VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (num_rows                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (sample_size               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (last_analyzed             DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (degree                    VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (instances                 VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (partitioned               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (temporary                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (generated                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (secondary                 VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (buffer_pool               VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (flash_cache               VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (cell_flash_cache          VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (user_stats                VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (duration                  VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (pct_direct_access         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (ityp_owner                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (ityp_name                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (parameters                VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (global_stats              VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (domidx_status             VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (domidx_opstatus           VARCHAR2(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (funcidx_status            VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (join_index                VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (iot_redundant_pkey_elim   VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (dropped                   VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (visibility                VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (domidx_management         VARCHAR2(14));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (segment_created           VARCHAR2(3));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (ORPHANED_ENTRIES          VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (INDEXING                  VARCHAR2(7));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (object_id                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (in_plan                   VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (index_column_names        VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (index_range_scan_cost     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (leaf_estimate_target_size NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (at_least_1_notnull_col    CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (total_segment_blocks      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (dbms_space_used_bytes     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (dbms_space_alloc_bytes    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (dbms_space_used_blocks    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (dbms_space_alloc_blocks   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_indexes ADD (estim_size_if_rebuilt     NUMBER);


DROP INDEX &&tool_repository_schema..sqlt$_dba_indexes_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_indexes_n1 ON &&tool_repository_schema..sqlt$_dba_indexes
(statement_id, owner, index_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_indexes_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_indexes_n2 ON &&tool_repository_schema..sqlt$_dba_indexes
(statement_id, table_owner, table_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_ind_statistics TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_ind_statistics FOR &&tool_repository_schema..sqlt$_dba_ind_statistics;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (owner                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (index_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (table_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (table_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (partition_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (partition_position      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (subpartition_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (subpartition_position   NUMBER);
-- INDEX, PARTITION, SUBPARTITION
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (object_type             VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (blevel                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (leaf_blocks             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (distinct_keys           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (avg_leaf_blocks_per_key NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (avg_data_blocks_per_key NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (clustering_factor       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (num_rows                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (avg_cached_blocks       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (avg_cache_hit_ratio     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (sample_size             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (last_analyzed           DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (global_stats            VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (user_stats              VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (stattype_locked         VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (stale_stats             VARCHAR2(3));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (scope                   VARCHAR2(7));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_statistics ADD (mutating_blevel         VARCHAR2(5));

DROP INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_n1 ON &&tool_repository_schema..sqlt$_dba_ind_statistics
(statement_id, owner, index_name, partition_name, subpartition_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_n2 ON &&tool_repository_schema..sqlt$_dba_ind_statistics
(statement_id, table_owner, table_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_ind_columns (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_ind_columns TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_ind_columns FOR &&tool_repository_schema..sqlt$_dba_ind_columns;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns ADD (index_owner     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns ADD (index_name      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns ADD (table_owner     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns ADD (table_name      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns ADD (column_name     VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns ADD (column_position NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns ADD (column_length   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns ADD (char_length     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns ADD (descend         VARCHAR2(4));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_columns ADD (COLLATED_COLUMN_ID NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_dba_ind_cols_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_ind_cols_n1 ON &&tool_repository_schema..sqlt$_dba_ind_columns
(statement_id, index_owner, index_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_ind_cols_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_ind_cols_n2 ON &&tool_repository_schema..sqlt$_dba_ind_columns
(statement_id, table_owner, table_name, column_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_ind_expressions TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_ind_expressions FOR &&tool_repository_schema..sqlt$_dba_ind_expressions;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions ADD (index_owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions ADD (index_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions ADD (table_owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions ADD (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions ADD (column_expression CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_expressions ADD (column_position   NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_dba_ind_expressions_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_ind_expressions_n1 ON &&tool_repository_schema..sqlt$_dba_ind_expressions
(statement_id, index_owner, index_name, column_position);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_tab_histograms TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tab_histograms FOR &&tool_repository_schema..sqlt$_dba_tab_histograms;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (owner                    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (table_name               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (column_name              VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (endpoint_number          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (endpoint_value           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (endpoint_actual_value    VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (endpoint_repeat_count    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (scope                    VARCHAR2(7));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (endpoint_estimated_value VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (endpoint_popular_value   VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (estimated_cardinality    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_histograms ADD (estimated_selectivity    NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_dba_tab_histograms_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tab_histograms_n1 ON &&tool_repository_schema..sqlt$_dba_tab_histograms
(statement_id, owner, table_name, column_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_part_key_columns (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_part_key_columns TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_part_key_columns FOR &&tool_repository_schema..sqlt$_dba_part_key_columns;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_key_columns ADD (owner           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_key_columns ADD (name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_key_columns ADD (object_type     CHAR(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_key_columns ADD (column_name     VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_key_columns ADD (column_position NUMBER);
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_key_columns ADD (COLLATED_COLUMN_ID NUMBER);
/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_tab_partitions TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tab_partitions FOR &&tool_repository_schema..sqlt$_dba_tab_partitions;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (table_owner            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (table_name             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (composite              VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (partition_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (subpartition_count     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (high_value             CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (high_value_length      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (partition_position     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (tablespace_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (pct_free               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (pct_used               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (ini_trans              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (max_trans              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (initial_extent         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (next_extent            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (min_extent             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (max_extent             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (max_size               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (pct_increase           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (freelists              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (freelist_groups        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (logging                VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (compression            VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (compress_for           VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions MODIFY (compress_for        VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (num_rows               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (blocks                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (empty_blocks           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (avg_space              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (chain_cnt              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (avg_row_len            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (sample_size            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (last_analyzed          DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (buffer_pool            VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (flash_cache            VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (cell_flash_cache       VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (global_stats           VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (user_stats             VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (is_nested              VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (parent_table_partition VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (interval               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (segment_created        VARCHAR2(4));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions MODIFY (segment_created     VARCHAR2(4));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (inmemory               VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (inmemory_compression   VARCHAR2(17));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (inmemory_distribute    VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (inmemory_priority      VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (inmemory_duplicate     VARCHAR2(13));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (CELLMEMORY             VARCHAR2(24));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (INMEMORY_SERVICE       VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (INMEMORY_SERVICE_NAME  VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (MEMOPTIMIZE_READ       VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_partitions ADD (MEMOPTIMIZE_WRITE      VARCHAR2(8));

DROP INDEX &&tool_repository_schema..sqlt$_dba_tab_partitions_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tab_partitions_n1 ON &&tool_repository_schema..sqlt$_dba_tab_partitions
(statement_id, table_owner, table_name, partition_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_ind_partitions TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_ind_partitions FOR &&tool_repository_schema..sqlt$_dba_ind_partitions;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (index_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (index_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (composite               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (partition_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (subpartition_count      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (high_value              CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (high_value_length       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (partition_position      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (status                  VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (tablespace_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (pct_free                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (ini_trans               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (max_trans               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (initial_extent          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (next_extent             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (min_extent              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (max_extent              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (max_size                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (pct_increase            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (freelists               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (freelist_groups         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (logging                 VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (compression             VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (blevel                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (leaf_blocks             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (distinct_keys           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (avg_leaf_blocks_per_key NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (avg_data_blocks_per_key NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (clustering_factor       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (num_rows                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (sample_size             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (last_analyzed           DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (buffer_pool             VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (flash_cache             VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (cell_flash_cache        VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (user_stats              VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (pct_direct_access       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (global_stats            VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (domidx_opstatus         VARCHAR2(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (parameters              VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (interval                VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (segment_created         VARCHAR2(3));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_partitions ADD (ORPHANED_ENTRIES        VARCHAR2(3));


DROP INDEX &&tool_repository_schema..sqlt$_dba_ind_partitions_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_ind_partitions_n1 ON &&tool_repository_schema..sqlt$_dba_ind_partitions
(statement_id, index_owner, index_name, partition_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_part_col_statistics TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_part_col_statistics FOR &&tool_repository_schema..sqlt$_dba_part_col_statistics;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (owner              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (table_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (partition_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (column_name        VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (num_distinct       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (low_value          RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics MODIFY (low_value       RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (high_value         RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics MODIFY (high_value      RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (density            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (num_nulls          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (num_buckets        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (sample_size        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (last_analyzed      DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (global_stats       VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (user_stats         VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (avg_col_len        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (histogram          VARCHAR2(15));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (low_value_cooked   VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (high_value_cooked  VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (popular_values     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (buckets_pop_vals   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (new_density        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (endpoints_count    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (mutating_endpoints VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_col_statistics ADD (mutating_ndv       VARCHAR2(5));

DROP INDEX &&tool_repository_schema..sqlt$_dba_part_col_stats_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_part_col_stats_n1 ON &&tool_repository_schema..sqlt$_dba_part_col_statistics
(statement_id, owner, table_name, partition_name, column_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_part_histograms (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_part_histograms TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_part_histograms FOR &&tool_repository_schema..sqlt$_dba_part_histograms;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (owner                    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (table_name               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (partition_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (column_name              VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (bucket_number            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (endpoint_value           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (endpoint_actual_value    VARCHAR2(1000));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (ENDPOINT_REPEAT_COUNT    NUMBER);

-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (endpoint_estimated_value VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (endpoint_popular_value   VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (estimated_cardinality    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_part_histograms ADD (estimated_selectivity    NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_dba_part_histograms_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_part_histograms_n1 ON &&tool_repository_schema..sqlt$_dba_part_histograms
(statement_id, owner, table_name, partition_name, column_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_tab_subpartitions TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tab_subpartitions FOR &&tool_repository_schema..sqlt$_dba_tab_subpartitions;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (table_owner           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (table_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (partition_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (subpartition_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (high_value            CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (high_value_length     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (subpartition_position NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (tablespace_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (pct_free              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (pct_used              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (ini_trans             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (max_trans             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (initial_extent        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (next_extent           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (min_extent            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (max_extent            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (max_size              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (pct_increase          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (freelists             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (freelist_groups       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (logging               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (compression           VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (compress_for          VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions MODIFY (compress_for       VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (num_rows              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (blocks                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (empty_blocks          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (avg_space             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (chain_cnt             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (avg_row_len           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (sample_size           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (last_analyzed         DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (buffer_pool           VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (flash_cache           VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (cell_flash_cache      VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (global_stats          VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (user_stats            VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (interval              VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (segment_created       VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (inmemory              VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (inmemory_compression  VARCHAR2(17));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (inmemory_distribute   VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (inmemory_priority     VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (inmemory_duplicate    VARCHAR2(13));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (CELLMEMORY            VARCHAR2(24));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (MEMOPTIMIZE_READ      VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_subpartitions ADD (MEMOPTIMIZE_WRITE     VARCHAR2(8));
/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_ind_subpartitions TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_ind_subpartitions FOR &&tool_repository_schema..sqlt$_dba_ind_subpartitions;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (index_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (index_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (partition_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (subpartition_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (high_value              CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (high_value_length       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (subpartition_position   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (status                  VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (tablespace_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (pct_free                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (ini_trans               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (max_trans               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (initial_extent          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (next_extent             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (min_extent              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (max_extent              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (max_size                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (pct_increase            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (freelists               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (freelist_groups         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (logging                 VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (compression             VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (blevel                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (leaf_blocks             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (distinct_keys           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (avg_leaf_blocks_per_key NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (avg_data_blocks_per_key NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (clustering_factor       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (num_rows                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (sample_size             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (last_analyzed           DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (buffer_pool             VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (flash_cache             VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (cell_flash_cache        VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (user_stats              VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (global_stats            VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (interval                VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (segment_created         VARCHAR2(3));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (DOMIDX_OPSTATUS         VARCHAR2(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_subpartitions ADD (PARAMETERS              VARCHAR2(1000));
/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_subpart_col_stats TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_subpart_col_stats FOR &&tool_repository_schema..sqlt$_dba_subpart_col_stats;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (owner              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (table_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (subpartition_name  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (column_name        VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (num_distinct       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (low_value          RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats MODIFY (low_value       RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (high_value         RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats MODIFY (high_value      RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (density            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (num_nulls          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (num_buckets        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (sample_size        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (last_analyzed      DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (global_stats       VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (user_stats         VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (avg_col_len        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (histogram          VARCHAR2(15));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (NOTES              VARCHAR2(63));

-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (low_value_cooked   VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (high_value_cooked  VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (popular_values     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (buckets_pop_vals   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (new_density        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (endpoints_count    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (mutating_endpoints VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_col_stats ADD (mutating_ndv       VARCHAR2(5));

DROP INDEX &&tool_repository_schema..sqlt$_dba_subpart_col_stats_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_subpart_col_stats_n1 ON &&tool_repository_schema..sqlt$_dba_subpart_col_stats
(statement_id, owner, table_name, subpartition_name, column_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_subpart_histograms TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_subpart_histograms FOR &&tool_repository_schema..sqlt$_dba_subpart_histograms;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (owner                    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (table_name               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (subpartition_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (column_name              VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (bucket_number            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (endpoint_value           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (endpoint_actual_value    VARCHAR2(1000));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (ENDPOINT_REPEAT_COUNT    NUMBER);

-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (endpoint_estimated_value VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (endpoint_popular_value   VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (estimated_cardinality    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_subpart_histograms ADD (estimated_selectivity    NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_dba_subpart_histogram_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_subpart_histogram_n1 ON &&tool_repository_schema..sqlt$_dba_subpart_histograms
(statement_id, owner, table_name, subpartition_name, column_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_constraints (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT ON &&tool_repository_schema..sqlt$_dba_constraints TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_dba_constraints TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_constraints FOR &&tool_repository_schema..sqlt$_dba_constraints;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (constraint_name   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (constraint_type   VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (search_condition  CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (r_owner           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (r_constraint_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (delete_rule       VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (status            VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (deferrable        VARCHAR2(14));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (deferred          VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (validated         VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (generated         VARCHAR2(14));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (bad               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (rely              VARCHAR2(4));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (last_change       DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (index_owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (index_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (invalid           VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_constraints ADD (view_related      VARCHAR2(14));

DROP INDEX &&tool_repository_schema..sqlt$_dba_constraints_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_constraints_n1 ON &&tool_repository_schema..sqlt$_dba_constraints
(statement_id, owner, table_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_segments (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_segments TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_segments FOR &&tool_repository_schema..sqlt$_dba_segments;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (owner            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (segment_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (partition_name   VARCHAR2(257));
-- TABLE, INDEX, TABLE PARTITION, INDEX PARTITION, TABLE SUBPARTITION, INDEX SUBPARTITION
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (segment_type     VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (segment_subtype  VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (tablespace_name  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (header_file      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (header_block     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (bytes            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (blocks           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (extents          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (initial_extent   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (next_extent      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (min_extents      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (max_extents      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (max_size         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (retention        VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (minretention     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (pct_increase     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (freelists        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (freelist_groups  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (relative_fno     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (buffer_pool      VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (flash_cache      VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (cell_flash_cache VARCHAR2(7));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (INMEMORY              VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (INMEMORY_PRIORITY     VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (INMEMORY_DISTRIBUTE   VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (INMEMORY_DUPLICATE    VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (INMEMORY_COMPRESSION  VARCHAR2(17));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (CELLMEMORY            VARCHAR2(24));

DROP INDEX &&tool_repository_schema..sqlt$_dba_segments_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_segments_n1 ON &&tool_repository_schema..sqlt$_dba_segments
(statement_id, segment_type, owner, segment_name, partition_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_segments_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_segments_n2 ON &&tool_repository_schema..sqlt$_dba_segments
(statement_id, owner, segment_name, partition_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_tablespaces (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT ON &&tool_repository_schema..sqlt$_dba_tablespaces TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_dba_tablespaces TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tablespaces FOR &&tool_repository_schema..sqlt$_dba_tablespaces;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (tablespace_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (block_size               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (initial_extent           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (next_extent              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (min_extents              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (max_extents              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (max_size                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (pct_increase             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (min_extlen               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (status                   VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (contents                 VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (logging                  VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (force_logging            VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (extent_management        VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (allocation_type          VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (plugged_in               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (segment_space_management VARCHAR2(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (def_tab_compression      VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (retention                VARCHAR2(11));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (bigfile                  VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (predicate_evaluation     VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (encrypted                VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (compress_for             VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces MODIFY (compress_for          VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (def_inmemory             VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (def_inmemory_compression VARCHAR2(17));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (def_inmemory_distribute  VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (def_inmemory_priority    VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (def_inmemory_duplicate   VARCHAR2(13));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (SHARED                      VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (DEF_INDEX_COMPRESSION       VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (INDEX_COMPRESS_FOR          VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (DEF_CELLMEMORY              VARCHAR2(14));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (DEF_INMEMORY_SERVICE        VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (DEF_INMEMORY_SERVICE_NAME   VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (LOST_WRITE_PROTECT          VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_segments ADD (CHUNK_TABLESPACE            VARCHAR2(1));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (total_bytes              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (total_blocks             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (total_user_bytes         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tablespaces ADD (total_user_blocks        NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_objects (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT, UPDATE ON &&tool_repository_schema..sqlt$_dba_objects TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_dba_objects TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_objects FOR &&tool_repository_schema..sqlt$_dba_objects;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (object_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (subobject_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (object_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (data_object_id NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (object_type    VARCHAR2(19));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (created        DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (last_ddl_time  DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (timestamp      VARCHAR2(19));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (status         VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (temporary      VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (generated      VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (secondary      VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (namespace      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (edition_name   VARCHAR2(257));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (SHARING            VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (EDITIONABLE        VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (ORACLE_MAINTAINED  VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (APPLICATION        VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (DEFAULT_COLLATION  VARCHAR2(100));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (DUPLICATED         VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (SHARDED            VARCHAR2(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (CREATED_APPID      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (CREATED_VSNID      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (MODIFIED_APPID     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (MODIFIED_VSNID     NUMBER);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_objects ADD (metadata_error VARCHAR2(4000));

DROP INDEX &&tool_repository_schema..sqlt$_dba_objects_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_objects_n1 ON &&tool_repository_schema..sqlt$_dba_objects
(statement_id, object_type, owner, object_name, subobject_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_objects_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_objects_n2 ON &&tool_repository_schema..sqlt$_dba_objects
(statement_id, owner, object_name, subobject_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_source (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_source TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_source FOR &&tool_repository_schema..sqlt$_dba_source;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_source ADD (owner VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_source ADD (name  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_source ADD (type  VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_source ADD (line  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_source ADD (text  VARCHAR2(4000));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_optstat_operations (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_optstat_operations TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_optstat_operations FOR &&tool_repository_schema..sqlt$_dba_optstat_operations;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_optstat_operations ADD (operation  VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_optstat_operations ADD (target     VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_optstat_operations ADD (start_time TIMESTAMP(6) WITH TIME ZONE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_optstat_operations ADD (end_time   TIMESTAMP(6) WITH TIME ZONE);
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_optstat_operations ADD (NOTES      VARCHAR2(4000));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_scheduler_jobs TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_scheduler_jobs FOR &&tool_repository_schema..sqlt$_dba_scheduler_jobs;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (owner                         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (job_name                      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (job_subname                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (job_style                     VARCHAR2(11));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (job_creator                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (client_id                     VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (global_uid                    VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (program_owner                 VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (program_name                  VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (job_type                      VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (job_action                    VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (number_of_arguments           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (schedule_owner                VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (schedule_name                 VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (schedule_type                 VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (start_date                    TIMESTAMP(6) WITH TIME ZONE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (repeat_interval               VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (event_queue_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (event_queue_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (event_queue_agent             VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (event_condition               VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (event_rule                    VARCHAR2(65));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (file_watcher_owner            VARCHAR2(65));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (file_watcher_name             VARCHAR2(65));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (end_date                      TIMESTAMP(6) WITH TIME ZONE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (job_class                     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (enabled                       VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (auto_drop                     VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (restartable                   VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (state                         VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (job_priority                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (run_count                     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (max_runs                      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (failure_count                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (max_failures                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (retry_count                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (last_start_date               TIMESTAMP(6) WITH TIME ZONE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (last_run_duration             INTERVAL DAY(9) TO SECOND(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (next_run_date                 TIMESTAMP(6) WITH TIME ZONE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (schedule_limit                INTERVAL DAY(3) TO SECOND(0));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (max_run_duration              INTERVAL DAY(3) TO SECOND(0));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (logging_level                 VARCHAR2(11));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (stop_on_window_close          VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (instance_stickiness           VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (raise_events                  VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (system                        VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (job_weight                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (nls_env                       VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (source                        VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (number_of_destinations        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (destination_owner             VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (destination                   VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (credential_owner              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (credential_name               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (instance_id                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (deferred_drop                 VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (allow_runs_in_restricted_mode VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (comments                      VARCHAR2(240));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_scheduler_jobs ADD (flags                         NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_autotask_client (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_autotask_client TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_autotask_client FOR &&tool_repository_schema..sqlt$_dba_autotask_client;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (client_name                  VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (status                       VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (consumer_group               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (client_tag                   VARCHAR2(2));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (priority_override            VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (attributes                   VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (window_group                 VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (service_name                 VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (resource_percentage          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (use_resource_estimates       VARCHAR2(5));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (mean_job_duration            INTERVAL DAY(9) TO SECOND(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (mean_job_cpu                 INTERVAL DAY(9) TO SECOND(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (mean_job_attempts            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (mean_incoming_tasks_7_days   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (mean_incoming_tasks_30_days  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (total_cpu_last_7_days        INTERVAL DAY(9) TO SECOND(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (total_cpu_last_30_days       INTERVAL DAY(9) TO SECOND(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (max_duration_last_7_days     INTERVAL DAY(3) TO SECOND(0));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (max_duration_last_30_days    INTERVAL DAY(3) TO SECOND(0));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (window_duration_last_7_days  INTERVAL DAY(9) TO SECOND(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client ADD (window_duration_last_30_days INTERVAL DAY(9) TO SECOND(9));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_autotask_client_hst (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_autotask_client_hst TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_autotask_client_hst FOR &&tool_repository_schema..sqlt$_dba_autotask_client_hst;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client_hst ADD (client_name        VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client_hst ADD (window_name        VARCHAR2(65));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client_hst ADD (window_start_time  TIMESTAMP(6) WITH TIME ZONE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client_hst ADD (window_duration    INTERVAL DAY(9) TO SECOND(9));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client_hst ADD (jobs_created       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client_hst ADD (jobs_started       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client_hst ADD (jobs_completed     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_autotask_client_hst ADD (window_end_time    TIMESTAMP(6) WITH TIME ZONE);


/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_col_usage$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_col_usage$ FOR &&tool_repository_schema..sqlt$_dba_col_usage$;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (column_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (equality_preds    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (equijoin_preds    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (nonequijoin_preds NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (range_preds       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (like_preds        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (null_preds        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (timestamp         DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (column_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_usage$ ADD (object_id         NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_dba_col_usage$_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_col_usage$_n1 ON &&tool_repository_schema..sqlt$_dba_col_usage$
(statement_id, owner, table_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$vpd_policy TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$vpd_policy FOR &&tool_repository_schema..sqlt$_gv$vpd_policy;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (inst_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (address               VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (paraddr               VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (sql_hash              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (sql_id                VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (child_number          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (object_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (object_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (policy_group          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (policy                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (policy_function_owner VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$vpd_policy ADD (predicate             VARCHAR2(4000));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_policies (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_policies TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_policies FOR &&tool_repository_schema..sqlt$_dba_policies;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (object_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (object_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (policy_group      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (policy_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (pf_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (package           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (function          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (sel               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (ins               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (upd               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (del               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (idx               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (chk_option        VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (enable            VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (static_policy     VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (policy_type       VARCHAR2(24));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (long_predicate    VARCHAR2(3));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (INHERITED         VARCHAR2(3));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (column_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_policies ADD (relevant_cols_opt VARCHAR2(10));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_audit_policies (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_audit_policies TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_audit_policies FOR &&tool_repository_schema..sqlt$_dba_audit_policies;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (object_schema         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (object_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (policy_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (policy_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (policy_text           VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (policy_column         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (pf_schema             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (pf_package            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (pf_function           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (enabled               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (sel                   VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (ins                   VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (upd                   VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (del                   VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (audit_trail           VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (policy_column_options VARCHAR2(11));
--171002
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (COMMON                VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_audit_policies ADD (INHERITED             VARCHAR2(3));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_optstat_user_prefs$ (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_optstat_user_prefs$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_optstat_user_prefs$ FOR &&tool_repository_schema..sqlt$_optstat_user_prefs$;

ALTER TABLE &&tool_repository_schema..sqlt$_optstat_user_prefs$ ADD (obj#    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_optstat_user_prefs$ ADD (pname   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_optstat_user_prefs$ ADD (valnum  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_optstat_user_prefs$ ADD (valchar VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_optstat_user_prefs$ ADD (chgtime TIMESTAMP(6) WITH TIME ZONE);
ALTER TABLE &&tool_repository_schema..sqlt$_optstat_user_prefs$ ADD (spare1  NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT ON &&tool_repository_schema..sqlt$_dba_tab_stats_versions TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_dba_tab_stats_versions TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tab_stats_versions FOR &&tool_repository_schema..sqlt$_dba_tab_stats_versions;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (partition_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (subpartition_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (object_id         NUMBER);
-- TABLE, PARTITION and SUBPARTITION
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (object_type       VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (num_rows          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (blocks            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (avg_row_len       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (sample_size       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (last_analyzed     DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (save_time         TIMESTAMP(6) WITH TIME ZONE);
-- PENDING and HISTORY
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (version_type      CHAR(7));
-- WRI$_OPTSTAT_TAB_HISTORY
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (flags             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (cachedblk         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (cachehit          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (logicalread       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (spare1            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (spare2            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (spare3            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (spare4            VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (spare5            VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_tab_stats_versions ADD (spare6            TIMESTAMP(6) WITH TIME ZONE);

DROP INDEX &&tool_repository_schema..sqlt$_dba_tab_stats_versn_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tab_stats_versn_n1 ON &&tool_repository_schema..sqlt$_dba_tab_stats_versions
(statement_id, object_type, owner, table_name, partition_name, subpartition_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_tab_stats_versn_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tab_stats_versn_n2 ON &&tool_repository_schema..sqlt$_dba_tab_stats_versions
(statement_id, object_type, owner, table_name, save_time);

DROP INDEX &&tool_repository_schema..sqlt$_dba_tab_stats_versn_n3;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_tab_stats_versn_n3 ON &&tool_repository_schema..sqlt$_dba_tab_stats_versions
(statid, version_type);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT ON &&tool_repository_schema..sqlt$_dba_ind_stats_versions TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_dba_ind_stats_versions TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_ind_stats_versions FOR &&tool_repository_schema..sqlt$_dba_ind_stats_versions;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (owner                   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (index_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (table_owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (table_name              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (partition_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (subpartition_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (object_id               NUMBER);
-- INDEX, PARTITION and SUBPARTITION
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (object_type             VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (blevel                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (leaf_blocks             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (distinct_keys           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (avg_leaf_blocks_per_key NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (avg_data_blocks_per_key NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (clustering_factor       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (num_rows                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (sample_size             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (last_analyzed           DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (save_time               TIMESTAMP(6) WITH TIME ZONE);
-- PENDING and HISTORY
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (version_type            CHAR(7));
-- WRI$_OPTSTAT_IND_HISTORY
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (flags                   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (guessq                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (cachedblk               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (cachehit                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (logicalread             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (spare1                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (spare2                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (spare3                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (spare4                  VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (spare5                  VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_ind_stats_versions ADD (spare6                  TIMESTAMP(6) WITH TIME ZONE);

DROP INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_versn_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_versn_n1 ON &&tool_repository_schema..sqlt$_dba_ind_stats_versions
(statement_id, object_type, owner, index_name, partition_name, subpartition_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_versn_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_versn_n2 ON &&tool_repository_schema..sqlt$_dba_ind_stats_versions
(statement_id, object_type, owner, index_name, save_time);

DROP INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_versn_n3;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_versn_n3 ON &&tool_repository_schema..sqlt$_dba_ind_stats_versions
(statement_id, object_type, table_owner, table_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_versn_n4;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_ind_stats_versn_n4 ON &&tool_repository_schema..sqlt$_dba_ind_stats_versions
(statid, version_type);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_col_stats_versions TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_col_stats_versions FOR &&tool_repository_schema..sqlt$_dba_col_stats_versions;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (owner             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (partition_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (subpartition_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (object_id         NUMBER);
-- TABLE, PARTITION and SUBPARTITION
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (object_type       VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (column_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (column_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (num_distinct      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (low_value         RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions MODIFY (low_value      RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (high_value        RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions MODIFY (high_value     RAW(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (density           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (num_nulls         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (avg_col_len       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (sample_size       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (sample_distcnt    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (last_analyzed     DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (save_time         TIMESTAMP(6) WITH TIME ZONE);
-- PENDING and HISTORY
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (version_type      CHAR(7));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (low_value_cooked  VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (high_value_cooked VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (endpoints_count   NUMBER);
-- WRI$_OPTSTAT_HISTHEAD_HISTORY
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (intcol#           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (flags             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (minimum           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (maximum           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (expression        CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (colname           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (spare1            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (spare2            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (spare3            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (spare4            VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (spare5            VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_col_stats_versions ADD (spare6            TIMESTAMP(6) WITH TIME ZONE);

DROP INDEX &&tool_repository_schema..sqlt$_dba_col_stats_versn_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_col_stats_versn_n1 ON &&tool_repository_schema..sqlt$_dba_col_stats_versions
(statement_id, object_type, owner, table_name, column_name, partition_name, subpartition_name, save_time);

DROP INDEX &&tool_repository_schema..sqlt$_dba_col_stats_versn_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_col_stats_versn_n2 ON &&tool_repository_schema..sqlt$_dba_col_stats_versions
(statid, version_type);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_histgrm_stats_versn FOR &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (owner                 VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (table_name            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (partition_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (subpartition_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (object_id             NUMBER);
-- TABLE, PARTITION and SUBPARTITION
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (object_type           VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (column_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (column_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (endpoint_number       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (endpoint_value        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (endpoint_actual_value VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (save_time             TIMESTAMP(6) WITH TIME ZONE);
-- PENDING and HISTORY
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (version_type          CHAR(7));
-- WRI$_OPTSTAT_HISTGRM_HISTORY
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (intcol#               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (colname               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (spare1                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (spare2                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (spare3                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (spare4                VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (spare5                VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn ADD (spare6                TIMESTAMP(6) WITH TIME ZONE);

DROP INDEX &&tool_repository_schema..sqlt$_dba_hist_stats_versn_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_hist_stats_versn_n1 ON &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn
(statement_id, object_type, owner, table_name, column_name, partition_name, subpartition_name);

DROP INDEX &&tool_repository_schema..sqlt$_dba_hist_stats_versn_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_hist_stats_versn_n2 ON &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn
(statid, version_type);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_aux_stats$ (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_aux_stats$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_aux_stats$ FOR &&tool_repository_schema..sqlt$_aux_stats$;

ALTER TABLE &&tool_repository_schema..sqlt$_aux_stats$ ADD (sname       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_aux_stats$ ADD (pname       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_aux_stats$ ADD (pval1       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_aux_stats$ ADD (pval2       VARCHAR2(255));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_aux_stats$ ADD (description VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_aux_stats$ ADD (order_by    NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_wri$_optstat_aux_history TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_wri$_optstat_aux_history FOR &&tool_repository_schema..sqlt$_wri$_optstat_aux_history;

ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (savtime TIMESTAMP(6) WITH TIME ZONE);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (sname   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (pname   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (pval1   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (pval2   VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (spare1  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (spare2  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (spare3  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (spare4  VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (spare5  VARCHAR2(1000));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_optstat_aux_history ADD (spare6  TIMESTAMP(6) WITH TIME ZONE);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$segment_statistics TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$segment_statistics FOR &&tool_repository_schema..sqlt$_gv$segment_statistics;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (inst_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (owner           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (object_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (subobject_name  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (tablespace_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (ts#             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (obj#            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (dataobj#        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (object_type     VARCHAR2(18));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (statistic_name  VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (statistic#      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (value           NUMBER);
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$segment_statistics ADD (begin_end_flag  CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$segment_stats_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$segment_stats_n1 ON &&tool_repository_schema..sqlt$_gv$segment_statistics
(statement_id, begin_end_flag, inst_id, statistic_name, owner, object_name, subobject_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$cell_state (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT ON &&tool_repository_schema..sqlt$_gv$cell_state TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_gv$cell_state TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$cell_state FOR &&tool_repository_schema..sqlt$_gv$cell_state;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$cell_state ADD (inst_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$cell_state ADD (cell_name         VARCHAR2(1024));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$cell_state ADD (statistics_type   VARCHAR2(15));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$cell_state ADD (object_name       VARCHAR2(1024));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$cell_state ADD (statistics_value  CLOB);
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$cell_state ADD (begin_end_flag    CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$cell_state_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$cell_state_n1 ON &&tool_repository_schema..sqlt$_gv$cell_state
(statement_id, begin_end_flag, inst_id, cell_name, statistics_type, object_name);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$session_event (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$session_event TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$session_event FOR &&tool_repository_schema..sqlt$_gv$session_event;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (inst_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (sid               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (event             VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (total_waits       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (total_timeouts    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (time_waited       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (average_wait      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (max_wait          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (time_waited_micro NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (event_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (wait_class_id     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (wait_class#       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (wait_class        VARCHAR2(64));
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$session_event ADD (begin_end_flag    CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$session_event_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$session_event_n1 ON &&tool_repository_schema..sqlt$_gv$session_event
(statement_id, begin_end_flag, inst_id, event);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$sesstat (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$sesstat TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$sesstat FOR &&tool_repository_schema..sqlt$_gv$sesstat;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$sesstat ADD (inst_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sesstat ADD (sid            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sesstat ADD (statistic#     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sesstat ADD (value          NUMBER);
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sesstat ADD (begin_end_flag CHAR(1));
-- Serial# from V$SESSION, used by XTRACT
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sesstat ADD (serial#        NUMBER);
-- Sequence number, used by XTRACT
ALTER TABLE &&tool_repository_schema..sqlt$_gv$sesstat ADD (sequence       NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_gv$sesstat_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$sesstat_n1 ON &&tool_repository_schema..sqlt$_gv$sesstat
(statement_id, begin_end_flag, inst_id, statistic#);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$statname (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$statname TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$statname FOR &&tool_repository_schema..sqlt$_gv$statname;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$statname ADD (inst_id    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$statname ADD (statistic# NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$statname ADD (name       VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$statname ADD (class      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$statname ADD (stat_id    NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_gv$statname_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$statname_n1 ON &&tool_repository_schema..sqlt$_gv$statname
(statement_id, inst_id, statistic#);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$pq_tqstat TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$pq_tqstat FOR &&tool_repository_schema..sqlt$_gv$pq_tqstat;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (inst_id     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (dfo_number  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (tq_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (server_type VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (num_rows    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (bytes       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (open_time   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (avg_latency NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (waits       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (timeouts    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (process     VARCHAR2(10));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_tqstat ADD (instance    NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_gv$pq_tqstat_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$pq_tqstat_n1 ON &&tool_repository_schema..sqlt$_gv$pq_tqstat
(statement_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$pq_slave (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$pq_slave TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$pq_slave FOR &&tool_repository_schema..sqlt$_gv$pq_slave;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (inst_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (slave_name      VARCHAR2(4));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (status          VARCHAR2(4));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (sessions        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (idle_time_cur   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (busy_time_cur   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (cpu_secs_cur    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (msgs_sent_cur   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (msgs_rcvd_cur   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (idle_time_total NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (busy_time_total NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (cpu_secs_total  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (msgs_sent_total NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (msgs_rcvd_total NUMBER);
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_slave ADD (begin_end_flag  CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$pq_slave_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$pq_slave_n1 ON &&tool_repository_schema..sqlt$_gv$pq_slave
(statement_id, begin_end_flag);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$pq_sysstat (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$pq_sysstat TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$pq_sysstat FOR &&tool_repository_schema..sqlt$_gv$pq_sysstat;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sysstat ADD (inst_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sysstat ADD (statistic      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sysstat ADD (value          NUMBER);
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sysstat ADD (begin_end_flag CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$pq_sysstat_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$pq_sysstat_n1 ON &&tool_repository_schema..sqlt$_gv$pq_sysstat
(statement_id, begin_end_flag, inst_id, statistic);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$px_process_sysstat (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$px_process_sysstat TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$px_process_sysstat FOR &&tool_repository_schema..sqlt$_gv$px_process_sysstat;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process_sysstat ADD (inst_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process_sysstat ADD (statistic      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process_sysstat ADD (value          NUMBER);
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process_sysstat ADD (begin_end_flag CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$px_process_sysstat_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$px_process_sysstat_n1 ON &&tool_repository_schema..sqlt$_gv$px_process_sysstat
(statement_id, begin_end_flag, inst_id, statistic);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$px_process (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$px_process TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$px_process FOR &&tool_repository_schema..sqlt$_gv$px_process;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process ADD (inst_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process ADD (server_name    VARCHAR2(4));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process ADD (status         VARCHAR2(9));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process ADD (pid            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process ADD (spid           VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process ADD (sid            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process ADD (serial#        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process ADD (IS_GV          VARCHAR2(5));
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_process ADD (begin_end_flag CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$px_process_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$px_process_n1 ON &&tool_repository_schema..sqlt$_gv$px_process
(statement_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$px_session (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$px_session TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$px_session FOR &&tool_repository_schema..sqlt$_gv$px_session;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (inst_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (saddr          VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (sid            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (serial#        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (qcsid          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (qcserial#      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (qcinst_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (server_group   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (server_set     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (server#        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (degree         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (req_degree     NUMBER);
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_session ADD (begin_end_flag CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$px_session_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$px_session_n1 ON &&tool_repository_schema..sqlt$_gv$px_session
(statement_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$pq_sesstat (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$pq_sesstat TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$pq_sesstat FOR &&tool_repository_schema..sqlt$_gv$pq_sesstat;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sesstat ADD (inst_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sesstat ADD (statistic      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sesstat ADD (last_query     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sesstat ADD (session_total  NUMBER);
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$pq_sesstat ADD (begin_end_flag CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$pq_sesstat_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$pq_sesstat_n1 ON &&tool_repository_schema..sqlt$_gv$pq_sesstat
(statement_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$px_sesstat TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$px_sesstat FOR &&tool_repository_schema..sqlt$_gv$px_sesstat;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (inst_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (saddr          VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (sid            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (serial#        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (qcsid          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (qcserial#      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (qcinst_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (server_group   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (server_set     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (server#        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (degree         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (req_degree     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (statistic#     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (value          NUMBER);
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_sesstat ADD (begin_end_flag CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$px_sesstat_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$px_sesstat_n1 ON &&tool_repository_schema..sqlt$_gv$px_sesstat
(statement_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_gv$px_instance_group (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_gv$px_instance_group TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$px_instance_group FOR &&tool_repository_schema..sqlt$_gv$px_instance_group;

ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_instance_group ADD (inst_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_instance_group ADD (qc_instance_group VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_instance_group ADD (why               VARCHAR2(23));
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_instance_group ADD (instance_number   NUMBER);
-- B=Begin, E=End
ALTER TABLE &&tool_repository_schema..sqlt$_gv$px_instance_group ADD (begin_end_flag    CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_gv$px_instance_group_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_gv$px_instance_group_n1 ON &&tool_repository_schema..sqlt$_gv$px_instance_group
(statement_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dbms_xplan (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dbms_xplan TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dbms_xplan FOR &&tool_repository_schema..sqlt$_dbms_xplan;

-- D = DISPLAY, C = DISPLAY_CURSOR, A = DISPLAY_AWR, B = DISPLAY_SQL_PLAN_BASELINE
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan ADD (api               CHAR(1));
-- A = ADVANCED ALLSTATS, V = ADVANCED, L = TYPICAL ALLSTATS LAST -PREDICATE -NOTE
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan ADD (format            CHAR(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan MODIFY (format            CHAR(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan ADD (plan_hash_value   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan ADD (sql_handle        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan ADD (plan_name         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan ADD (inst_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan ADD (child_number      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan ADD (executions        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan ADD (line_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dbms_xplan ADD (plan_table_output VARCHAR2(300));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_wri$_adv_tasks TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_wri$_adv_tasks FOR &&tool_repository_schema..sqlt$_wri$_adv_tasks;

ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (id                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (owner#              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (owner_name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (name                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (description         VARCHAR2(256));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (advisor_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (advisor_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (ctime               DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (mtime               DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (parent_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (parent_rec_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (property            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (version             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (last_exec_name      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (exec_start          DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (exec_end            DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (status              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (status_msg_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (pct_completion_time NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (progress_metric     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (metric_units        VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (activity_counter    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (rec_count           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (error_msg#          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (cleanup             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (how_created         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_tasks ADD (source              VARCHAR2(257));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_wri$_adv_rationale TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_wri$_adv_rationale FOR &&tool_repository_schema..sqlt$_wri$_adv_rationale;

ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (id            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (task_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (exec_name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (type          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (rec_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (impact_msg_id NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (impact_val    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (obj_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (msg_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (attr1         VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (attr2         VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (attr3         VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (attr4         VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_wri$_adv_rationale ADD (attr5         CLOB);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_sqltune_plans TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_sqltune_plans FOR &&tool_repository_schema..sqlt$_dba_sqltune_plans;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (task_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (execution_name    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (object_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (attribute         VARCHAR2(34));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (plan_hash_value   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (plan_id           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (timestamp         DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (remarks           VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (operation         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (options           VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (object_node       VARCHAR2(128));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (object_owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (object_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (object_alias      VARCHAR2(65));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (object_instance   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (object_type       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (optimizer         VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (search_columns    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (id                NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (parent_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (depth             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (position          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (cost              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (cardinality       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (bytes             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (other_tag         VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (partition_start   VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (partition_stop    VARCHAR2(255));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (partition_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (other             CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (distribution      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (cpu_cost          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (io_cost           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (temp_space        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (access_predicates VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (filter_predicates VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (projection        VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (time              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (qblock_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (other_xml         CLOB);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sqltune_plans ADD (in_plan_extension CHAR(1));

DROP INDEX &&tool_repository_schema..sqlt$_dba_sqltune_plans_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_sqltune_plans_n1 ON &&tool_repository_schema..sqlt$_dba_sqltune_plans
(statement_id, plan_hash_value, id);

DROP INDEX &&tool_repository_schema..sqlt$_dba_sqltune_plans_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_dba_sqltune_plans_n2 ON &&tool_repository_schema..sqlt$_dba_sqltune_plans
(statement_id, plan_hash_value, parent_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_plan_extension (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT ON &&tool_repository_schema..sqlt$_plan_extension TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_plan_extension TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_plan_extension FOR &&tool_repository_schema..sqlt$_plan_extension;

-- GV$SQL_PLAN, DBA_HIST_SQL_PLAN, PLAN_TABLE, DBA_SQLTUNE_PLANS
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (source                VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (inst_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (address               VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (hash_value            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (sql_id                VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (plan_hash_value       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (plan_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (task_id               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (child_address         VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (child_number          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (timestamp             DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (operation             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (options               VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (object_node           VARCHAR2(40));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (object#               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (object_owner          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (object_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (object_alias          VARCHAR2(65));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (object_type           VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (optimizer             VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (id                    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (parent_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (depth                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (position              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (search_columns        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (cost                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (cardinality           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (bytes                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (other_tag             VARCHAR2(35));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (partition_start       VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (partition_stop        VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (partition_id          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (other                 VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (distribution          VARCHAR2(20));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (cpu_cost              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (io_cost               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (temp_space            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (access_predicates     VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (filter_predicates     VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (projection            VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (time                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (qblock_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (remarks               VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (other_xml             CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (attribute             VARCHAR2(34));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (sqlt_plan_hash_value  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (sqlt_plan_hash_value2 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (real_depth            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (exec_order            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (top_cost              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (plan_operation        VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (operation_caption     VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (more_html_table       CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (sanitized_other_xml   CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (binds_html_table      CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (binds_html_table_capt CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_extension ADD (goto_html_table       CLOB);

DROP INDEX &&tool_repository_schema..sqlt$_plan_extension_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_plan_extension_n1 ON &&tool_repository_schema..sqlt$_plan_extension
(statement_id, source, plan_hash_value, plan_id, inst_id, child_number, id);

DROP INDEX &&tool_repository_schema..sqlt$_plan_extension_n2;
CREATE INDEX &&tool_repository_schema..sqlt$_plan_extension_n2 ON &&tool_repository_schema..sqlt$_plan_extension
(statement_id, source, plan_hash_value, plan_id, inst_id, child_number, parent_id);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_sql_patches (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_sql_patches TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_sql_patches FOR &&tool_repository_schema..sqlt$_dba_sql_patches;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (category       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (signature      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (sql_text       CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (created        TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (last_modified  TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (description    VARCHAR2(500));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (status         VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (force_matching VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (task_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (task_exec_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (task_obj_id    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (task_fnd_id    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_patches ADD (task_rec_id    NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_sql_profiles TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_sql_profiles FOR &&tool_repository_schema..sqlt$_dba_sql_profiles;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (category       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (signature      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (sql_text       CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (created        TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (last_modified  TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (description    VARCHAR2(500));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (type           VARCHAR2(7));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (status         VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (force_matching VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (task_id        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (task_exec_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (task_obj_id    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (task_fnd_id    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_profiles ADD (task_rec_id    NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_sql_plan_baselines TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_sql_plan_baselines FOR &&tool_repository_schema..sqlt$_dba_sql_plan_baselines;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (signature           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (sql_handle          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (sql_text            CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (plan_name           VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (creator             VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (origin              VARCHAR2(14));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (parsing_schema_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (description         VARCHAR2(500));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (version             VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (created             TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (last_modified       TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (last_executed       TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (last_verified       TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (enabled             VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (accepted            VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (fixed               VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (reproduced          VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (autopurge           VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (optimizer_cost      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (module              VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines MODIFY (module           VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (action              VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines MODIFY (action           VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (executions          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (elapsed_time        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (cpu_time            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (buffer_gets         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (disk_reads          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (direct_writes       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (rows_processed      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (fetches             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (end_of_fetch_count  NUMBER);
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_baselines ADD (plan_hash_value     NUMBER);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_sql_plan_dir_objs FOR &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs ADD (directive_id     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs ADD (owner            VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs ADD (object_name      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs ADD (subobject_name   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs ADD (object_type      VARCHAR2(6));
-- 150828 NOTES no longer updates, kept for legacy. added columns to decode "NOTES"
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs add (notes clob);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs ADD (sanitized_notes CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs ADD (equality_predicates_only CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs ADD (simple_column_predicates_only CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs ADD (index_access_by_join_preds CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs ADD (filter_on_joining_object CHAR(1));
-- 150828 decode "NOTES" 
UPDATE  &&tool_repository_schema..sqlt$_dba_sql_plan_dir_objs o SET
  equality_predicates_only     =substr(o.notes,instr(o.notes,'<equality_predicates_only>')+26,1) 
 ,simple_column_predicates_only=substr(o.notes,instr(o.notes,'<simple_column_predicates_only>')+31,1) 
 ,index_access_by_join_preds   =substr(o.notes,instr(o.notes,'<index_access_by_join_predicates>')+33,1) 
 ,filter_on_joining_object     =substr(o.notes,instr(o.notes,'<filter_on_joining_object>')+26,1);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_sql_plan_directives TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_sql_plan_directives FOR &&tool_repository_schema..sqlt$_dba_sql_plan_directives;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives ADD (directive_id   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives ADD (type           VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives ADD (state          VARCHAR2(13));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives ADD (auto_drop      VARCHAR2(3));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives ADD (reason         VARCHAR2(36));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives ADD (created        TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives ADD (last_modified  TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives ADD (last_used      TIMESTAMP(6));
--150828 New in 12.1.0.2
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives ADD (internal_state VARCHAR2(13));  
ALTER TABLE &&tool_repository_schema..sqlt$_dba_sql_plan_directives ADD (redundant      VARCHAR2(3)); 

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_sqlobj$data (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_sqlobj$data TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_sqlobj$data FOR &&tool_repository_schema..sqlt$_sqlobj$data;

-- 11g
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$data ADD (signature NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$data ADD (category  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$data ADD (obj_type  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$data ADD (plan_id   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$data ADD (comp_data CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$data ADD (spare1    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$data ADD (spare2    CLOB);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_sqlobj$ (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_sqlobj$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_sqlobj$ FOR &&tool_repository_schema..sqlt$_sqlobj$;

-- 11g
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ ADD (signature     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ ADD (category      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ ADD (obj_type      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ ADD (plan_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ ADD (name          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ ADD (flags         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ ADD (last_executed TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ ADD (spare1        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlobj$ ADD (spare2        CLOB);

/* ------------------------------------------------------------------------- */

-- 10g
CREATE TABLE &&tool_repository_schema..sqlt$_sqlprof$attr (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_sqlprof$attr TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_sqlprof$attr FOR &&tool_repository_schema..sqlt$_sqlprof$attr;

ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$attr ADD (signature NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$attr ADD (category  VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$attr ADD (attr#     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$attr ADD (attr_val  VARCHAR2(500));

/* ------------------------------------------------------------------------- */

-- 10g
CREATE TABLE &&tool_repository_schema..sqlt$_sqlprof$ (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_sqlprof$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_sqlprof$ FOR &&tool_repository_schema..sqlt$_sqlprof$;

ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (sp_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (signature     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (category      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (nhash         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (created       DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (last_modified DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (type          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (status        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (flags         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (spare1        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_sqlprof$ ADD (spare2        VARCHAR2(1000));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_outlines (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_outlines TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_outlines FOR &&tool_repository_schema..sqlt$_dba_outlines;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (owner      VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (category   VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (used       VARCHAR2(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (timestamp  DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (version    VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (sql_text   CLOB);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (signature  VARCHAR2(64));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (compatible VARCHAR2(12));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (enabled    VARCHAR2(8));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (format     VARCHAR2(6));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outlines ADD (migrated   VARCHAR2(12));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_dba_outline_hints (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_dba_outline_hints TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_outline_hints FOR &&tool_repository_schema..sqlt$_dba_outline_hints;

ALTER TABLE &&tool_repository_schema..sqlt$_dba_outline_hints ADD (name     VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outline_hints ADD (owner    VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outline_hints ADD (node     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outline_hints ADD (stage    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outline_hints ADD (join_pos NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_dba_outline_hints ADD (hint     CLOB);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_log (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT ON &&tool_repository_schema..sqlt$_log TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_log TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_log FOR &&tool_repository_schema..sqlt$_log;

TRUNCATE TABLE &&tool_repository_schema..sqlt$_log;

-- environment
ALTER TABLE &&tool_repository_schema..sqlt$_log ADD (time_stamp TIMESTAMP(6));
ALTER TABLE &&tool_repository_schema..sqlt$_log ADD (line_id    NUMBER);
-- L=Log, E=Error, S=Silent
ALTER TABLE &&tool_repository_schema..sqlt$_log ADD (line_type  CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_log ADD (line_text  VARCHAR2(4000));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_metadata (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT, INSERT ON &&tool_repository_schema..sqlt$_metadata TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_metadata TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_metadata FOR &&tool_repository_schema..sqlt$_metadata;

ALTER TABLE &&tool_repository_schema..sqlt$_metadata ADD (owner       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_metadata ADD (object_name VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_metadata ADD (object_type VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_metadata ADD (object_id   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_metadata ADD (transformed CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_metadata ADD (remapped    CHAR(1));
ALTER TABLE &&tool_repository_schema..sqlt$_metadata ADD (depth       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_metadata ADD (metadata    CLOB);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT SELECT ON applsys.fnd_histogram_cols TO &&role_name.;
GRANT SELECT, INSERT ON &&tool_repository_schema..sqlt$_fnd_histogram_cols TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_fnd_histogram_cols TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_fnd_histogram_cols FOR &&tool_repository_schema..sqlt$_fnd_histogram_cols;

ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (application_id    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (table_name        VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (column_name       VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (partition         VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (hsize             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (creation_date     DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (created_by        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (last_update_date  DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (last_updated_by   NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (last_update_login NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_fnd_histogram_cols ADD (owner             VARCHAR2(257));

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_peeked_binds (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_peeked_binds TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_peeked_binds FOR &&tool_repository_schema..sqlt$_peeked_binds;

-- GV$SQL_PLAN, DBA_HIST_SQL_PLAN, DBA_SQLTUNE_PLANS, PLAN_EXTENSION
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (source              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (plan_hash_value     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (plan_timestamp      DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (plan_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (inst_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (child_number        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (child_address       VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (id                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (line_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (name                VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (position            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (dup_position        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (datatype            NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (character_sid       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (frm                 NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (precision           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (scale               NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (max_length          NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (was_captured        VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (value_raw           VARCHAR2(4000));
-- extension
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (datatype_string     VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (value_string        VARCHAR2(4000));
ALTER TABLE &&tool_repository_schema..sqlt$_peeked_binds ADD (value_string_date   VARCHAR2(4000));

DROP INDEX &&tool_repository_schema..sqlt$_peeked_binds_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_peeked_binds_n1 ON &&tool_repository_schema..sqlt$_peeked_binds
(statement_id, source, plan_hash_value);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_plan_info (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_plan_info TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_plan_info FOR &&tool_repository_schema..sqlt$_plan_info;

-- GV$SQL_PLAN, DBA_HIST_SQL_PLAN, DBA_SQLTUNE_PLANS
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (source              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (plan_hash_value     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (plan_timestamp      DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (plan_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (inst_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (child_number        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (child_address       VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (id                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (line_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (info_type           VARCHAR2(32));
ALTER TABLE &&tool_repository_schema..sqlt$_plan_info ADD (info_value          VARCHAR2(4000));

DROP INDEX &&tool_repository_schema..sqlt$_plan_info_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_plan_info_n1 ON &&tool_repository_schema..sqlt$_plan_info
(statement_id, source, plan_hash_value);

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_outline_data (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_outline_data TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_outline_data FOR &&tool_repository_schema..sqlt$_outline_data;

-- GV$SQL_PLAN, DBA_HIST_SQL_PLAN, DBA_SQLTUNE_PLANS
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data ADD (source              VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data ADD (plan_hash_value     NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data ADD (plan_timestamp      DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data ADD (plan_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data ADD (inst_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data ADD (child_number        NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data ADD (child_address       VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data ADD (id                  NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data ADD (line_id             NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_outline_data ADD (hint                VARCHAR2(4000));

DROP INDEX &&tool_repository_schema..sqlt$_outline_data_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_outline_data_n1 ON &&tool_repository_schema..sqlt$_outline_data
(statement_id, source, plan_hash_value);


/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..sqlt$_display_map (
statement_id NUMBER NOT NULL,
statid VARCHAR2(30) NOT NULL
);

GRANT ALL ON &&tool_repository_schema..sqlt$_display_map TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_display_map FOR &&tool_repository_schema..sqlt$_display_map;

-- GV$SQL_PLAN, DBA_HIST_SQL_PLAN, DBA_SQLTUNE_PLANS
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (source          VARCHAR2(257));
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (plan_hash_value NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (plan_timestamp  DATE);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (plan_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (inst_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (child_number    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (child_address   VARCHAR2(16));
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (id              NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (line_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (operation_id    NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (display_id      NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (parent_id       NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (part_id         NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (depth           NUMBER);
ALTER TABLE &&tool_repository_schema..sqlt$_display_map ADD (skipped         NUMBER);

DROP INDEX &&tool_repository_schema..sqlt$_display_map_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_display_map_n1 ON &&tool_repository_schema..sqlt$_display_map
(statement_id, source, plan_hash_value);

/* ------------------------------------------------------------------------- */

DROP TABLE &&tool_repository_schema..sqlg$_column_predicate;
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..sqlg$_column_predicate (
  column_name                VARCHAR2(257),
  plan_hash_value            NUMBER,
  plan_line_id               NUMBER,
  predicate_type             VARCHAR2(2),
  predicate                  VARCHAR2(4000),
  binds_html_table           CLOB,
  binds_html_table_capt      CLOB
) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..sqlg$_column_predicate TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlg$_column_predicate FOR &&tool_repository_schema..sqlg$_column_predicate;

/* ------------------------------------------------------------------------- */

DROP TABLE &&tool_repository_schema..sqlg$_column_html_table;
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..sqlg$_column_html_table (
  owner                      VARCHAR2(257),
  table_name                 VARCHAR2(257),
  column_name                VARCHAR2(257),
  -- (P)redicates, (I)ndexes
  type                       CHAR(1),
  html_table                 CLOB
) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..sqlg$_column_html_table TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlg$_column_html_table FOR &&tool_repository_schema..sqlg$_column_html_table;

/* ------------------------------------------------------------------------- */

DROP TABLE &&tool_repository_schema..sqlg$_pivot;
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..sqlg$_pivot (
  object_type                VARCHAR2(257),
  object_name                VARCHAR2(257),
  object_owner               VARCHAR2(257),
  partitioned                VARCHAR2(3),
  subobject_name             VARCHAR2(257),
  -- 160421 parent table of index
  parent_table_name          VARCHAR2(257),
  parent_table_owner         VARCHAR2(257),
  obj#                       NUMBER,
  dataobj#                   NUMBER
) ON COMMIT PRESERVE ROWS;

GRANT SELECT ON &&tool_repository_schema..sqlg$_pivot TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlg$_pivot TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlg$_pivot FOR &&tool_repository_schema..sqlg$_pivot;

/* ------------------------------------------------------------------------- */

DROP TABLE &&tool_repository_schema..sqlg$_temp;
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..sqlg$_temp (
  c1 VARCHAR2(4000),
  n1 NUMBER -- 1:exists on dba_links, 2:associated to sql as per v$sql_plan
) ON COMMIT PRESERVE ROWS;

GRANT SELECT, INSERT, DELETE ON &&tool_repository_schema..sqlg$_temp TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlg$_temp TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlg$_temp FOR &&tool_repository_schema..sqlg$_temp;

/* ------------------------------------------------------------------------- */

DROP TABLE &&tool_repository_schema..sqlg$_observation;
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..sqlg$_observation (
  priority                   NUMBER,
  type_id                    NUMBER,
  line_id                    NUMBER,
  object_type                VARCHAR2(32),
  object_name                VARCHAR2(257),
  observation                VARCHAR2(4000),
  more                       CLOB
) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..sqlg$_observation TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlg$_observation FOR &&tool_repository_schema..sqlg$_observation;

/* ------------------------------------------------------------------------- */

CREATE TABLE &&tool_repository_schema..chk$cbo$parameter_apps (
  release                    VARCHAR2(64) NOT NULL,
  version                    VARCHAR2(32) NOT NULL,
  id                         INTEGER NOT NULL,
  name                       VARCHAR2(128) NOT NULL,
  set_flag                   CHAR(1) NOT NULL,
  mp_flag                    CHAR(1) NOT NULL,
  sz_flag                    CHAR(1) NOT NULL,
  cbo_flag                   CHAR(1) NOT NULL,
  value                      VARCHAR2(512)
);

GRANT ALL ON &&tool_repository_schema..chk$cbo$parameter_apps TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..chk$cbo$parameter_apps FOR &&tool_repository_schema..chk$cbo$parameter_apps;

/* ------------------------------------------------------------------------- */

-- the following staging tables should be created with ALTER SESSION SET NLS_LENGTH_SEMANTICS = BYTE;

ALTER SESSION SET NLS_LENGTH_SEMANTICS = BYTE;

DROP TABLE &&tool_repository_schema..SQLT$_STATTAB;

BEGIN
  SYS.DBMS_STATS.CREATE_STAT_TABLE (
    ownname => '&&tool_repository_schema.',
    stattab => 'SQLT$_STATTAB' );
END;
/

BEGIN
  SYS.DBMS_STATS.UPGRADE_STAT_TABLE (
    ownname => '&&tool_repository_schema.',
    stattab => 'SQLT$_STATTAB' );
END;
/

GRANT SELECT, INSERT ON &&tool_repository_schema..sqlt$_stattab TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_stattab TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_stattab FOR &&tool_repository_schema..sqlt$_stattab;

DROP INDEX &&tool_repository_schema..sqlt$_stattab_n1;
CREATE INDEX &&tool_repository_schema..sqlt$_stattab_n1 ON &&tool_repository_schema..sqlt$_stattab (statid, type, c5, c1, c4);

BEGIN
  SYS.DBMS_STATS.CREATE_STAT_TABLE (
    ownname => '&&tool_repository_schema.',
    stattab => 'SQLI$_STATTAB_TEMP' );
END;
/

BEGIN
  SYS.DBMS_STATS.UPGRADE_STAT_TABLE (
    ownname => '&&tool_repository_schema.',
    stattab => 'SQLI$_STATTAB_TEMP' );
END;
/

GRANT ALL ON &&tool_repository_schema..sqli$_stattab_temp TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqli$_stattab_temp FOR &&tool_repository_schema..sqli$_stattab_temp;

DROP INDEX &&tool_repository_schema..sqli$_stattab_temp_n1;
CREATE INDEX &&tool_repository_schema..sqli$_stattab_temp_n1 ON &&tool_repository_schema..sqli$_stattab_temp (statid, type, c5, c1, c4);

/* ------------------------------------------------------------------------- */

BEGIN
  SYS.DBMS_SQLTUNE.CREATE_STGTAB_SQLPROF (
    table_name  => 'SQLI$_STGTAB_SQLPROF',
    schema_name => '&&tool_repository_schema.' );
END;
/

GRANT ALL ON &&tool_repository_schema..sqli$_stgtab_sqlprof TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqli$_stgtab_sqlprof FOR &&tool_repository_schema..sqli$_stgtab_sqlprof;

BEGIN
  SYS.DBMS_SQLTUNE.CREATE_STGTAB_SQLPROF (
   table_name  => 'SQLT$_STGTAB_SQLPROF',
   schema_name => '&&tool_repository_schema.' );
END;
/

GRANT SELECT ON &&tool_repository_schema..sqlt$_stgtab_sqlprof TO &&role_name.;
GRANT ALL ON &&tool_repository_schema..sqlt$_stgtab_sqlprof TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_stgtab_sqlprof FOR &&tool_repository_schema..sqlt$_stgtab_sqlprof;

ALTER TABLE &&tool_repository_schema..sqlt$_stgtab_sqlprof ADD (statid VARCHAR2(257));

/* ------------------------------------------------------------------------- */

BEGIN
  SYS.DBMS_SQLTUNE.CREATE_STGTAB_SQLSET (
    table_name  => 'TEMP_STGTAB_SQLSET',
    schema_name => '&&tool_repository_schema.');
END;
/

DECLARE
  l_count_old NUMBER;
  l_count_new NUMBER;
BEGIN

    SELECT COUNT(*)
      INTO l_count_old
      FROM dba_tab_cols
     WHERE owner = '&&tool_repository_schema.'
       AND table_name = 'SQLT$_STGTAB_SQLSET';

    SELECT COUNT(*)
      INTO l_count_new
      FROM dba_tab_cols
     WHERE owner = '&&tool_repository_schema.'
       AND table_name = 'TEMP_STGTAB_SQLSET';

    IF l_count_old > 0 AND l_count_old <> l_count_new THEN -- SQLT$_STGTAB_SQLSET is old
      EXECUTE IMMEDIATE 'DROP TABLE &&tool_repository_schema..SQLT$_STGTAB_SQLSET';
      EXECUTE IMMEDIATE 'DROP TABLE &&tool_repository_schema..SQLI$_STGTAB_SQLSET';
    END IF;

    EXECUTE IMMEDIATE 'DROP TABLE &&tool_repository_schema..TEMP_STGTAB_SQLSET';

EXCEPTION
  WHEN OTHERS THEN
    SYS.DBMS_OUTPUT.PUT_LINE('DBMS_SPM.CREATE_STGTAB_SQLSET: '||SQLERRM);
END;
/

BEGIN
  SYS.DBMS_SQLTUNE.CREATE_STGTAB_SQLSET (
    table_name  => 'SQLI$_STGTAB_SQLSET',
    schema_name => '&&tool_repository_schema.');
END;
/

GRANT ALL ON &&tool_repository_schema..sqli$_stgtab_sqlset TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqli$_stgtab_sqlset FOR &&tool_repository_schema..sqli$_stgtab_sqlset;

BEGIN
  SYS.DBMS_SQLTUNE.CREATE_STGTAB_SQLSET (
    table_name  => 'SQLT$_STGTAB_SQLSET',
    schema_name => '&&tool_repository_schema.');
END;
/

GRANT ALL ON &&tool_repository_schema..sqlt$_stgtab_sqlset TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_stgtab_sqlset FOR &&tool_repository_schema..sqlt$_stgtab_sqlset;

ALTER TABLE &&tool_repository_schema..sqlt$_stgtab_sqlset ADD (statid VARCHAR2(30));

/* ------------------------------------------------------------------------- */

EXEC SYS.DBMS_STATS.DELETE_SCHEMA_STATS('&&tool_repository_schema.');

/* ------------------------------------------------------------------------- */

ALTER SESSION SET NLS_LENGTH_SEMANTICS = CHAR;

SET ECHO OFF TERM ON;
PRO
PRO SQCOBJ completed. Some errors are expected.
