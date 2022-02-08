REM $Header: 215187.1 sqcvw.sql 12.1.12 2015/09/11 carlos.sierra mauro.pagano abel.macias@oracle.com $ 
REM
REM Copyright (c) 2000-2015, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra
REM   mauro.pagano
REM   abel.macias@oracle.com
REM
REM SCRIPT
REM   sqlt/install/sqcvw.sql
REM
REM DESCRIPTION
REM   Creates SQLT views owned by its user SQLTXPLAIN.
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
REM   3. Execute script sqcvw.sql
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqcvw.sql
REM
REM NOTES
REM   1. This script is executed automatically by sqcpkg.sql
REM   2. For possible errors see sqcpkg.log file
REM
@@sqcommon1.sql
SET ECHO ON;

WHENEVER SQLERROR CONTINUE;

/* ---------------------------------------------------------------- */
REM
REM System views (extensions)
REM
/* ---------------------------------------------------------------- */

-- extension to gv$parameter2 but only for cbo parameters and including all cbo hidden parameters
CREATE OR REPLACE VIEW sys.sqlt$_gv$parameter_cbo_v AS
WITH cbo_param AS (
SELECT /*+ materialize */
       pname_qksceserow name
  FROM sys.x$qksceses
 WHERE sid_qksceserow = SYS_CONTEXT('USERENV', 'SID')
)
SELECT x.inst_id,
       x.indx+1 num,
       x.ksppinm name,
       x.ksppity type,
       y.ksppstvl value,
       y.ksppstdvl display_value,
       y.ksppstdf isdefault,
       DECODE(BITAND(x.ksppiflg/256, 1), 1, 'TRUE', 'FALSE') isses_modifiable,
       DECODE(BITAND(x.ksppiflg/65536, 3), 1, 'IMMEDIATE', 2, 'DEFERRED', 3, 'IMMEDIATE', 'FALSE') issys_modifiable,
       DECODE(BITAND(x.ksppiflg, 4), 4, 'FALSE', DECODE(BITAND(x.ksppiflg/65536, 3), 0, 'FALSE', 'TRUE')) isinstance_modifiable,
       DECODE(BITAND(y.ksppstvf, 7), 1, 'MODIFIED', 4,'SYSTEM_MOD', 'FALSE') ismodified,
       DECODE(BITAND(y.ksppstvf, 2), 2, 'TRUE', 'FALSE') isadjusted,
       DECODE(BITAND(x.ksppilrmflg/64, 1), 1, 'TRUE', 'FALSE') isdeprecated,
       DECODE(BITAND(x.ksppilrmflg/268435456, 1), 1, 'TRUE', 'FALSE') isbasic,
       x.ksppdesc description,
       y.ksppstcmnt update_comment,
       x.ksppihash hash
  FROM sys.x$ksppi x,
       sys.x$ksppcv y,
       cbo_param
 WHERE x.indx = y.indx
   AND BITAND(x.ksppiflg, 268435456) = 0
   AND TRANSLATE(x.ksppinm, '_', '#') NOT LIKE '##%'
   AND x.ksppinm = cbo_param.name;

REVOKE SELECT ON sys.sqlt$_gv$parameter_cbo_v FROM &&tool_repository_schema.;
GRANT SELECT ON sys.sqlt$_gv$parameter_cbo_v TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_gv$parameter_cbo_v FOR sys.sqlt$_gv$parameter_cbo_v;

/*------------------------------------------------------------------*/

-- superset of col$ needed to get property
CREATE OR REPLACE VIEW sys.sqlt$_col$_v
AS
SELECT u.user# owner_id,
       u.name owner,
       o.name table_name,
       c.name column_name,
       c.obj#,
       c.col#,
       c.segcol#,
       c.segcollength,
       c.offset,
       c.type#,
       c.length,
       c.fixedstorage,
       c.precision#,
       c.scale,
       c.null$,
       c.deflength,
       c.default$,
       c.intcol#,
       c.property,
       c.charsetid,
       c.charsetform,
       c.spare1,
       c.spare2,
       c.spare3,
       c.spare4,
       c.spare5,
       c.spare6
  FROM sys.col$ c,
       sys.obj$ o,
       sys.user$ u
 WHERE o.obj# = c.obj#
   AND o.owner# = u.user#
   AND o.type# IN (2, 3, 4);

REVOKE SELECT ON sys.sqlt$_col$_v FROM &&tool_repository_schema.;
GRANT SELECT ON sys.sqlt$_col$_v TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_col$_v FOR sys.sqlt$_col$_v;

/*------------------------------------------------------------------*/

-- extension to col_usage$ table (Column Usage)
CREATE OR REPLACE VIEW sys.sqlt$_dba_col_usage_v AS
SELECT u.name owner,
       o.name table_name,
       c.name column_name,
       cu.equality_preds,
       cu.equijoin_preds,
       cu.nonequijoin_preds,
       cu.range_preds,
       cu.like_preds,
       cu.null_preds,
       cu.timestamp,
       DECODE(c.col#, 0, TO_NUMBER(NULL), c.col#) column_id,
       cu.obj# object_id
  FROM sys.col_usage$ cu,
       sys.col$ c,
       sys.obj$ o,
       sys.user$ u
 WHERE cu.obj# = c.obj#
   AND cu.intcol# = c.intcol#
   AND cu.obj# = o.obj#
   AND o.type# = 2
   AND o.owner# = u.user#;

REVOKE SELECT ON sys.sqlt$_dba_col_usage_v FROM &&tool_repository_schema.;
GRANT SELECT ON sys.sqlt$_dba_col_usage_v TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_col_usage_v FOR sys.sqlt$_dba_col_usage_v;

/*------------------------------------------------------------------*/

-- extension to DBA_POLICIES (Column Usage)
CREATE OR REPLACE VIEW sys.sqlt$_dba_policies_v AS
SELECT p.obj# object_id,
       p.gname group_name,
       p.pname policy_name,
       p.stmt_type statement_type,
       p.pfschma policy_func_schema,
       p.pfname policy_func_name,
       pc.intcol# column_id,
       CASE WHEN bitand(p.stmt_type,4096) = 4096 THEN 'ALL_ROWS' ELSE NULL END relevant_cols_opt
  FROM sys.rls$ p,
       sys.rls_sc$ pc
 WHERE p.obj# = pc.obj#(+);

REVOKE SELECT ON sys.sqlt$_dba_policies_v FROM &&tool_repository_schema.;
GRANT SELECT ON sys.sqlt$_dba_policies_v TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_policies_v FOR sys.sqlt$_dba_policies_v;

/*------------------------------------------------------------------*/

-- this is where statistics history is controlled
REVOKE SELECT, UPDATE ON sys.optstat_hist_control$ FROM &&tool_repository_schema.;
GRANT SELECT, UPDATE ON sys.optstat_hist_control$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..optstat_hist_control$ FOR sys.optstat_hist_control$;

/*------------------------------------------------------------------*/

-- extension to an hybrid between sys.dba_tab_stats_history, sys.dba_tab_pending_stats and wri$_optstat_tab_history
CREATE OR REPLACE VIEW sys.sqlt$_dba_tab_stats_vers_v AS
SELECT u.name owner,
       o.name table_name,
       NULL partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'TABLE' object_type,
       h.rowcnt num_rows,
       h.blkcnt blocks,
       h.avgrln avg_row_len,
       h.samplesize sample_size,
       h.analyzetime last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_tab_history h,
       sys.obj$ o,
       sys.user$ u
 WHERE h.obj# = o.obj#
   AND o.type# = 2
   AND o.owner# = u.user#
 UNION ALL
SELECT u.name owner,
       o.name table_name,
       o.subname partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'PARTITION' object_type,
       h.rowcnt num_rows,
       h.blkcnt blocks,
       h.avgrln avg_row_len,
       h.samplesize sample_size,
       h.analyzetime last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_tab_history h,
       sys.obj$ o,
       sys.user$ u
 WHERE h.obj# = o.obj#
   AND o.type# = 19
   AND o.owner# = u.user#
 UNION ALL
SELECT u.name owner,
       osp.name table_name,
       ocp.subname partition_name,
       osp.subname subpartition_name,
       h.obj# object_id,
       'SUBPARTITION' object_type,
       h.rowcnt num_rows,
       h.blkcnt blocks,
       h.avgrln avg_row_len,
       h.samplesize sample_size,
       h.analyzetime last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_tab_history h,
       sys.obj$ osp,
       sys.tabsubpart$ tsp,
       sys.obj$ ocp,
       sys.user$ u
 WHERE h.obj# = osp.obj#
   AND osp.type# = 34
   AND osp.obj# = tsp.obj#
   AND tsp.pobj# = ocp.obj#
   AND osp.owner# = u.user#;

REVOKE SELECT ON sys.sqlt$_dba_tab_stats_vers_v FROM &&tool_repository_schema.;
GRANT SELECT ON sys.sqlt$_dba_tab_stats_vers_v TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_tab_stats_vers_v FOR sys.sqlt$_dba_tab_stats_vers_v;

/*------------------------------------------------------------------*/

REVOKE SELECT, INSERT, DELETE ON sys.wri$_optstat_tab_history FROM &&tool_repository_schema.;
GRANT SELECT, INSERT, DELETE ON sys.wri$_optstat_tab_history TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..wri$_optstat_tab_history FOR sys.wri$_optstat_tab_history;

/*------------------------------------------------------------------*/

-- extension to sys.dba_ind_pending_stats and wri$_optstat_ind_history
CREATE OR REPLACE VIEW sys.sqlt$_dba_ind_stats_vers_v AS
SELECT ui.name owner,
       oi.name index_name,
       ut.name table_owner,
       ot.name table_name,
       NULL partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'INDEX' object_type,
       h.leafcnt leaf_blocks,
       h.distkey distinct_keys,
       h.lblkkey avg_leaf_blocks_per_key,
       h.dblkkey avg_data_blocks_per_key,
       h.clufac clustering_factor,
       h.rowcnt num_rows,
       h.samplesize sample_size,
       h.analyzetime last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_ind_history h,
       sys.ind$ i,
       sys.obj$ oi,
       sys.user$ ui,
       sys.obj$ ot,
       sys.user$ ut
 WHERE h.obj# = i.obj#
   AND i.type# IN (1, 2, 3, 4, 6, 7, 8)
   AND BITAND(i.flags, 4096) = 0
   AND i.obj# = oi.obj#
   AND oi.namespace = 4
   AND oi.remoteowner IS NULL
   AND oi.linkname IS NULL
   AND oi.owner# = ui.user#
   AND i.bo# = ot.obj#
   AND ot.owner# = ut.user#
 UNION ALL
SELECT ui.name owner,
       oi.name index_name,
       ut.name table_owner,
       ot.name table_name,
       oi.subname partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'PARTITION' object_type,
       h.leafcnt leaf_blocks,
       h.distkey distinct_keys,
       h.lblkkey avg_leaf_blocks_per_key,
       h.dblkkey avg_data_blocks_per_key,
       h.clufac clustering_factor,
       h.rowcnt num_rows,
       h.samplesize sample_size,
       h.analyzetime last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_ind_history h,
       sys.indpart$ ip,
       sys.ind$ i,
       sys.obj$ oi,
       sys.user$ ui,
       sys.obj$ ot,
       sys.user$ ut
 WHERE h.obj# = ip.obj#
   AND ip.bo# = i.obj#
   AND i.type# IN (1, 2, 3, 4, 6, 7, 8)
   AND BITAND(i.flags, 4096) = 0
   AND ip.obj# = oi.obj#
   AND oi.namespace = 4
   AND oi.remoteowner IS NULL
   AND oi.linkname IS NULL
   AND oi.owner# = ui.user#
   AND i.bo# = ot.obj#
   AND ot.owner# = ut.user#
 UNION ALL
SELECT ui.name owner,
       oi.name index_name,
       ut.name table_owner,
       ot.name table_name,
       oi.subname partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'PARTITION' object_type,
       h.leafcnt leaf_blocks,
       h.distkey distinct_keys,
       h.lblkkey avg_leaf_blocks_per_key,
       h.dblkkey avg_data_blocks_per_key,
       h.clufac clustering_factor,
       h.rowcnt num_rows,
       h.samplesize sample_size,
       h.analyzetime last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_ind_history h,
       sys.indcompart$ ip,
       sys.ind$ i,
       sys.obj$ oi,
       sys.user$ ui,
       sys.obj$ ot,
       sys.user$ ut
 WHERE h.obj# = ip.obj#
   AND ip.bo# = i.obj#
   AND i.type# IN (1, 2, 3, 4, 6, 7, 8)
   AND BITAND(i.flags, 4096) = 0
   AND ip.obj# = oi.obj#
   AND oi.namespace = 4
   AND oi.remoteowner IS NULL
   AND oi.linkname IS NULL
   AND oi.owner# = ui.user#
   AND i.bo# = ot.obj#
   AND ot.owner# = ut.user#
 UNION ALL
SELECT ui.name owner,
       oi.name index_name,
       ut.name table_owner,
       ot.name table_name,
       os.name partition_name,
       os.subname subpartition_name,
       h.obj# object_id,
       'SUBPARTITION' object_type,
       h.leafcnt leaf_blocks,
       h.distkey distinct_keys,
       h.lblkkey avg_leaf_blocks_per_key,
       h.dblkkey avg_data_blocks_per_key,
       h.clufac clustering_factor,
       h.rowcnt num_rows,
       h.samplesize sample_size,
       h.analyzetime last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_ind_history h,
       sys.indsubpart$ isp,
       sys.indcompart$ icp,
       sys.ind$ i,
       sys.obj$ os,
       sys.obj$ oi,
       sys.user$ ui,
       sys.obj$ ot,
       sys.user$ ut
 WHERE h.obj# = isp.obj#
   AND isp.pobj# = icp.obj#
   AND icp.bo# = i.obj#
   AND i.type# IN (1, 2, 3, 4, 6, 7, 8)
   AND BITAND(i.flags, 4096) = 0
   AND isp.obj# = os.obj#
   AND os.type# = 35
   AND os.namespace = 4
   AND os.remoteowner IS NULL
   AND os.linkname IS NULL
   AND i.obj# = oi.obj#
   AND oi.type# = 1
   AND oi.owner# = ui.user#
   AND i.bo# = ot.obj#
   AND ot.type# = 2
   AND ot.owner# = ut.user#;

REVOKE SELECT ON sys.sqlt$_dba_ind_stats_vers_v FROM &&tool_repository_schema.;
GRANT SELECT ON sys.sqlt$_dba_ind_stats_vers_v TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_ind_stats_vers_v FOR sys.sqlt$_dba_ind_stats_vers_v;

/*------------------------------------------------------------------*/

REVOKE SELECT, INSERT, DELETE ON sys.wri$_optstat_ind_history FROM &&tool_repository_schema.;
GRANT SELECT, INSERT, DELETE ON sys.wri$_optstat_ind_history TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..wri$_optstat_ind_history FOR sys.wri$_optstat_ind_history;

/*------------------------------------------------------------------*/

-- extension to sys.dba_col_pending_stats and wri$_optstat_histhead_history
CREATE OR REPLACE VIEW sys.sqlt$_dba_col_stats_vers_v AS
SELECT u.name owner,
       o.name table_name,
       NULL partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'TABLE' object_type,
       c.name column_name,
       DECODE(c.col#, 0, TO_NUMBER(NULL), c.col#) column_id,
       h.distcnt num_distinct,
       h.lowval low_value,
       h.hival high_value,
       h.null_cnt num_nulls,
       h.avgcln avg_col_len,
       h.timestamp# last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_histhead_history h,
       sys.col$ c,
       sys.obj$ o,
       sys.user$ u
 WHERE h.obj# = c.obj#
   AND h.intcol# = c.intcol#
   AND h.obj# = o.obj#
   AND o.type# = 2
   AND o.owner# = u.user#
 UNION ALL
SELECT u.name owner,
       o.name table_name,
       o.subname partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'PARTITION' object_type,
       c.name column_name,
       DECODE(c.col#, 0, TO_NUMBER(NULL), c.col#) column_id,
       h.distcnt num_distinct,
       h.lowval low_value,
       h.hival high_value,
       h.null_cnt num_nulls,
       h.avgcln avg_col_len,
       h.timestamp# last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_histhead_history h,
       sys.tabpart$ t,
       sys.col$ c,
       sys.obj$ o,
       sys.user$ u
 WHERE h.obj# = t.obj#
   AND t.bo# = c.obj#
   AND h.intcol# = c.intcol#
   AND h.obj# = o.obj#
   AND o.type# = 19
   AND o.owner# = u.user#
 UNION ALL
SELECT u.name owner,
       o.name table_name,
       o.subname partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'PARTITION' object_type,
       c.name column_name,
       DECODE(c.col#, 0, TO_NUMBER(NULL), c.col#) column_id,
       h.distcnt num_distinct,
       h.lowval low_value,
       h.hival high_value,
       h.null_cnt num_nulls,
       h.avgcln avg_col_len,
       h.timestamp# last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_histhead_history h,
       sys.tabcompart$ t,
       sys.col$ c,
       sys.obj$ o,
       sys.user$ u
 WHERE h.obj# = t.obj#
   AND t.bo# = c.obj#
   AND h.intcol# = c.intcol#
   AND h.obj# = o.obj#
   AND o.type# = 19
   AND o.owner# = u.user#
 UNION ALL
SELECT us.name owner,
       op.name table_name,
       op.subname partition_name,
       os.subname subpartition_name,
       h.obj# object_id,
       'SUBPARTITION' object_type,
       c.name column_name,
       DECODE(c.col#, 0, TO_NUMBER(NULL), c.col#) column_id,
       h.distcnt num_distinct,
       h.lowval low_value,
       h.hival high_value,
       h.null_cnt num_nulls,
       h.avgcln avg_col_len,
       h.timestamp# last_analyzed,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_histhead_history h,
       sys.tabsubpart$ tsp,
       sys.tabcompart$ tcp,
       sys.col$ c,
       sys.obj$ os,
       sys.user$ us,
       sys.obj$ op
 WHERE h.obj# = tsp.obj#
   AND tsp.pobj# = tcp.obj#
   AND tcp.bo# = c.obj#
   AND h.intcol# = c.intcol#
   AND tsp.obj# = os.obj#
   AND os.type# = 34
   AND os.owner# = us.user#
   AND tcp.obj# = op.obj#
   AND op.type# = 19;

REVOKE SELECT ON sys.sqlt$_dba_col_stats_vers_v FROM &&tool_repository_schema.;
GRANT SELECT ON sys.sqlt$_dba_col_stats_vers_v TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_col_stats_vers_v FOR sys.sqlt$_dba_col_stats_vers_v;

/*------------------------------------------------------------------*/

REVOKE SELECT, INSERT, DELETE ON sys.wri$_optstat_histhead_history FROM &&tool_repository_schema.;
GRANT SELECT, INSERT, DELETE ON sys.wri$_optstat_histhead_history TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..wri$_optstat_histhead_history FOR sys.wri$_optstat_histhead_history;

/*------------------------------------------------------------------*/

-- extension to sys.dba_tab_histgrm_pending_stats and wri$_optstat_histgrm_history
CREATE OR REPLACE VIEW sys.sqlt$_dba_hgrm_stats_vers_v AS
SELECT u.name owner,
       o.name table_name,
       NULL partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'TABLE' object_type,
       c.name column_name,
       DECODE(c.col#, 0, TO_NUMBER(NULL), c.col#) column_id,
       h.bucket endpoint_number,
       h.endpoint endpoint_value,
       h.epvalue endpoint_actual_value,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_histgrm_history h,
       sys.col$ c,
       sys.obj$ o,
       sys.user$ u
 WHERE h.obj# = c.obj#
   AND h.intcol# = c.intcol#
   AND h.obj# = o.obj#
   AND o.type# = 2
   AND o.owner# = u.user#
 UNION ALL
SELECT u.name owner,
       o.name table_name,
       o.subname partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'PARTITION' object_type,
       c.name column_name,
       DECODE(c.col#, 0, TO_NUMBER(NULL), c.col#) column_id,
       h.bucket endpoint_number,
       h.endpoint endpoint_value,
       h.epvalue endpoint_actual_value,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_histgrm_history h,
       sys.tabpart$ t,
       sys.col$ c,
       sys.obj$ o,
       sys.user$ u
 WHERE h.obj# = t.obj#
   AND t.bo# = c.obj#
   AND h.intcol# = c.intcol#
   AND h.obj# = o.obj#
   AND o.type# = 19
   AND o.owner# = u.user#
 UNION ALL
SELECT u.name owner,
       o.name table_name,
       o.subname partition_name,
       NULL subpartition_name,
       h.obj# object_id,
       'PARTITION' object_type,
       c.name column_name,
       DECODE(c.col#, 0, TO_NUMBER(NULL), c.col#) column_id,
       h.bucket endpoint_number,
       h.endpoint endpoint_value,
       h.epvalue endpoint_actual_value,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_histgrm_history h,
       sys.tabcompart$ t,
       sys.col$ c,
       sys.obj$ o,
       sys.user$ u
 WHERE h.obj# = t.obj#
   AND t.bo# = c.obj#
   AND h.intcol# = c.intcol#
   AND h.obj# = o.obj#
   AND o.type# = 19
   AND o.owner# = u.user#
 UNION ALL
SELECT us.name owner,
       op.name table_name,
       op.subname partition_name,
       os.subname subpartition_name,
       h.obj# object_id,
       'SUBPARTITION' object_type,
       c.name column_name,
       DECODE(c.col#, 0, TO_NUMBER(NULL), c.col#) column_id,
       h.bucket endpoint_number,
       h.endpoint endpoint_value,
       h.epvalue endpoint_actual_value,
       CASE WHEN h.savtime < SYSTIMESTAMP THEN h.savtime END save_time,
       CASE WHEN h.savtime > SYSTIMESTAMP THEN 'PENDING' ELSE 'HISTORY' END version_type,
       h.*
  FROM sys.wri$_optstat_histgrm_history h,
       sys.tabsubpart$ tsp,
       sys.tabcompart$ tcp,
       sys.col$ c,
       sys.obj$ os,
       sys.user$ us,
       sys.obj$ op
 WHERE h.obj# = tsp.obj#
   AND tsp.pobj# = tcp.obj#
   AND tcp.bo# = c.obj#
   AND h.intcol# = c.intcol#
   AND tsp.obj# = os.obj#
   AND os.type# = 34
   AND os.owner# = us.user#
   AND tcp.obj# = op.obj#
   AND op.type# = 19;

REVOKE SELECT ON sys.sqlt$_dba_hgrm_stats_vers_v FROM &&tool_repository_schema.;
GRANT SELECT ON sys.sqlt$_dba_hgrm_stats_vers_v TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_dba_hgrm_stats_vers_v FOR sys.sqlt$_dba_hgrm_stats_vers_v;

/*------------------------------------------------------------------*/

REVOKE SELECT, INSERT, DELETE ON sys.wri$_optstat_histgrm_history FROM &&tool_repository_schema.;
GRANT SELECT, INSERT, DELETE ON sys.wri$_optstat_histgrm_history TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..wri$_optstat_histgrm_history FOR sys.wri$_optstat_histgrm_history;

/*------------------------------------------------------------------*/

-- used by sqltxecute.sql and sqltxplain.sql
CREATE OR REPLACE VIEW sys.sqlt$_my_v$session AS
SELECT sid, prev_hash_value, prev_sql_id, prev_child_number, 
       CASE WHEN SYS_CONTEXT('USERENV','IP_ADDRESS') IS NULL THEN 0 ELSE 1 END port
  FROM v$session
 WHERE sid = SYS_CONTEXT('USERENV', 'SID')
   AND status = 'ACTIVE';

GRANT SELECT ON sys.sqlt$_my_v$session TO &&role_name.;
GRANT SELECT ON sys.sqlt$_my_v$session TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_my_v$session FOR sys.sqlt$_my_v$session;


/*------------------------------------------------------------------*/

-- used by sqltxecute.sql and sqltxplain.sql
CREATE OR REPLACE VIEW sys.sqlt$_my_v$sql AS
SELECT sql_id, child_number, sql_text FROM v$sql;

GRANT SELECT ON sys.sqlt$_my_v$sql TO &&role_name.;
GRANT SELECT ON sys.sqlt$_my_v$sql TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..sqlt$_my_v$sql FOR sys.sqlt$_my_v$sql;

/* ---------------------------------------------------------------- */
REM
REM Tool views
REM
/* ---------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_sql_shared_cursor_v AS
SELECT s.statement_id,
       s.statid,
       s.inst_id,
       s.child_number,
       s.child_address,
       s.plan_hash_value,
       ROUND(s.elapsed_time/1e6, 3) elapsed_time_secs,
       ROUND(s.cpu_time/1e6, 3) cpu_time_secs,
       ROUND(s.user_io_wait_time/1e6, 3) user_io_time_secs,
       ROUND(s.cluster_wait_time/1e6, 3) cluster_time_secs,
       ROUND(s.concurrency_wait_time/1e6, 3) concurrency_time_secs,
       ROUND(s.application_wait_time/1e6, 3) application_time_secs,
       s.buffer_gets,
       s.disk_reads,
       s.direct_writes,
       s.rows_processed,
       s.executions,
       p.timestamp plan_timestamp,
       s.last_active_time,
       ROUND(NVL(s.elapsed_time, 0)/GREATEST(1, NVL(s.executions, 0))/1e6, 3) avg_elapsed_time_secs,
       ROUND(NVL(s.cpu_time, 0)/GREATEST(1, NVL(s.executions, 0))/1e6, 3) avg_cpu_time_secs,
       ROUND(NVL(s.user_io_wait_time, 0)/GREATEST(1, NVL(s.executions, 0))/1e6, 3) avg_io_time_secs,
       ROUND(NVL(s.cluster_wait_time, 0)/GREATEST(1, NVL(s.executions, 0))/1e6, 3) avg_cluster_time_secs,
       ROUND(NVL(s.concurrency_wait_time, 0)/GREATEST(1, NVL(s.executions, 0))/1e6, 3) avg_conc_time_secs,
       ROUND(NVL(s.application_wait_time, 0)/GREATEST(1, NVL(s.executions, 0))/1e6, 3) avg_appl_time_secs,
       ROUND(NVL(s.buffer_gets, 0)/GREATEST(1, NVL(s.executions, 0))) avg_buffer_gets,
       ROUND(NVL(s.disk_reads, 0)/GREATEST(1, NVL(s.executions, 0))) avg_disk_reads,
       ROUND(NVL(s.direct_writes, 0)/GREATEST(1, NVL(s.executions, 0))) avg_direct_writes,
       ROUND(NVL(s.rows_processed, 0)/GREATEST(1, NVL(s.executions, 0))) avg_rows_processed,
       CASE
       WHEN s.is_obsolete = 'Y' THEN 'TRUE'
       WHEN s.is_obsolete = 'N' THEN 'FALSE'
       ELSE 'FALSE' END
       is_obsolete,
       CASE
       WHEN s.is_shareable = 'Y' THEN 'TRUE'
       WHEN s.is_shareable = 'N' THEN 'FALSE'
       WHEN c.not_shared_reason IS NULL THEN 'TRUE'
       ELSE 'FALSE' END
       is_shareable,
       CASE
       WHEN s.is_shareable = 'Y' THEN 1
       WHEN s.is_shareable = 'N' THEN 0
       WHEN c.not_shared_reason IS NULL THEN 1
       ELSE 0 END
       shared,
       CASE
       WHEN s.is_shareable = 'Y' THEN 0
       WHEN s.is_shareable = 'N' THEN 1
       WHEN c.not_shared_reason IS NULL THEN 0
       ELSE 1 END
       not_shared,
       CASE
       WHEN c.not_shared_reason IS NOT NULL THEN c.not_shared_reason
       WHEN s.is_shareable = 'N' THEN 'UNKNOWN' END
       not_shared_reason,
       b.reason,
       b.sanitized_reason
  FROM &&tool_repository_schema..sqlt$_gv$sql s,
       &&tool_repository_schema..sqlt$_sql_shared_cursor_d c,
       &&tool_repository_schema..sqlt$_gv$sql_shared_cursor b,
       &&tool_repository_schema..sqlt$_gv$sql_plan p
 WHERE s.statement_id = c.statement_id(+)
   AND s.inst_id = c.inst_id(+)
   AND s.child_number = c.child_number(+)
   AND s.child_address = c.child_address(+)
   AND s.plan_hash_value = c.plan_hash_value(+)
   AND s.statement_id = b.statement_id(+)
   AND s.inst_id = b.inst_id(+)
   AND s.child_number = b.child_number(+)
   AND s.child_address = b.child_address(+)
   AND s.statement_id = p.statement_id(+)
   AND s.inst_id = p.inst_id(+)
   AND s.child_number = p.child_number(+)
   AND s.child_address = p.child_address(+)
   AND s.plan_hash_value = p.plan_hash_value(+)
   AND 0 = p.id(+);

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_gv$object_dependency_v AS
SELECT statement_id,
       statid,
       inst_id,
       from_address,
       from_hash,
       to_owner,
       to_name,
       to_address,
       to_hash,
       to_type,
       DECODE(to_type,
       0, 'NEXT OBJECT',
       1, 'INDEX',
       2, 'TABLE',
       3, 'CLUSTER',
       4, 'VIEW',
       5, 'SYNONYM',
       6, 'SEQUENCE',
       7, 'PROCEDURE',
       8, 'FUNCTION',
       9, 'PACKAGE',
       10, 'NON-EXISTENT',
       11, 'PACKAGE BODY',
       12, 'TRIGGER',
       13, 'TYPE',
       14, 'TYPE BODY',
       22, 'LIBRARY',
       28, 'JAVA SOURCE',
       29, 'JAVA CLASS',
       32, 'INDEXTYPE',
       33, 'OPERATOR',
       42, 'MATERIALIZED VIEW',
       43, 'DIMENSION',
       46, 'RULE SET',
       55, 'XML SCHEMA',
       56, 'JAVA DATA',
       59, 'RULE',
       62, 'EVALUATION CONTXT',
       92, 'CUBE DIMENSION',
       93, 'CUBE',
       94, 'MEASURE FOLDER',
       95, 'CUBE BUILD PROCESS',
       'UNDEFINED') type,
       depth
  FROM &&tool_repository_schema..sqlt$_gv$object_dependency;  

/*------------------------------------------------------------------*/

/* CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dependencies_v AS
SELECT statement_id,
       statid,
       owner,
       name,
       type
  FROM &&tool_repository_schema..sqlt$_dba_dependencies
 UNION
SELECT statement_id,
       statid,
       referenced_owner owner,
       referenced_name name,
       referenced_type type
  FROM &&tool_repository_schema..sqlt$_dba_dependencies
 UNION
SELECT statement_id,
       statid,
       to_owner owner,
       to_name name,
       type
  FROM &&tool_administer_schema..sqlt$_gv$object_dependency_v
 WHERE type NOT IN ('UNDEFINED', 'NON-EXISTENT'); */

-- 12.1.08
CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dependencies_v AS
SELECT statement_id,
       statid,
       owner,
       name,
       type,
       referenced_owner to_owner,
       referenced_name to_name,
       referenced_type to_type,
       'Dictionary' source
  FROM &&tool_repository_schema..sqlt$_dba_dependencies
UNION ALL
SELECT statement_id,
       statid,
       NULL,
       NULL,
       NULL,
       to_owner,
       to_name,
       type,
       'Cursor'
  FROM &&tool_administer_schema..sqlt$_gv$object_dependency_v
 WHERE type NOT IN ('UNDEFINED', 'NON-EXISTENT','NEXT OBJECT')
   AND (statement_id, to_owner, to_name, type) NOT IN 
         (SELECT statement_id, referenced_owner, referenced_name, referenced_type
            FROM &&tool_administer_schema..sqlt$_dba_dependencies);

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_all_tables_v AS
SELECT 'DBA_TABLES' source,
       statement_id,
       statid,
       owner,
       table_name,
       tablespace_name,
       cluster_name,
       iot_name,
       status,
       pct_free,
       pct_used,
       ini_trans,
       max_trans,
       initial_extent,
       next_extent,
       min_extents,
       max_extents,
       pct_increase,
       freelists,
       freelist_groups,
       logging,
       backed_up,
       num_rows,
       blocks,
       empty_blocks,
       avg_space,
       chain_cnt,
       avg_row_len,
       avg_space_freelist_blocks,
       num_freelist_blocks,
       degree,
       instances,
       cache,
       table_lock,
       sample_size,
       last_analyzed,
       partitioned,
       iot_type,
       temporary,
       secondary,
       nested,
       buffer_pool,
       flash_cache,
       cell_flash_cache,
       row_movement,
       global_stats,
       user_stats,
       duration,
       skip_corrupt,
       monitoring,
       cluster_owner,
       dependencies,
       compression,
       compress_for,
       dropped,
       read_only,
       segment_created,
       result_cache,
       count_star,
       object_id,
       full_table_scan_cost,
       new_11g_ndv_algorithm_used,
       total_segment_blocks,
       dbms_space_used_bytes,
       dbms_space_alloc_bytes,
       dbms_space_used_blocks,
       dbms_space_alloc_blocks,
       dv_censored,
       inmemory,
       inmemory_priority,
       inmemory_compression,
       inmemory_distribute,
       inmemory_duplicate
  FROM &&tool_repository_schema..sqlt$_dba_tables
 UNION ALL
SELECT 'DBA_OBJECT_TABLES' source,
       statement_id,
       statid,
       owner,
       table_name,
       tablespace_name,
       cluster_name,
       iot_name,
       status,
       pct_free,
       pct_used,
       ini_trans,
       max_trans,
       initial_extent,
       next_extent,
       min_extents,
       max_extents,
       pct_increase,
       freelists,
       freelist_groups,
       logging,
       backed_up,
       num_rows,
       blocks,
       empty_blocks,
       avg_space,
       chain_cnt,
       avg_row_len,
       avg_space_freelist_blocks,
       num_freelist_blocks,
       degree,
       instances,
       cache,
       table_lock,
       sample_size,
       last_analyzed,
       partitioned,
       iot_type,
       temporary,
       secondary,
       nested,
       buffer_pool,
       flash_cache,
       cell_flash_cache,
       row_movement,
       global_stats,
       user_stats,
       duration,
       skip_corrupt,
       monitoring,
       cluster_owner,
       dependencies,
       compression,
       compress_for,
       dropped,
       read_only,
       segment_created,
       result_cache,
       count_star,
       object_id,
       full_table_scan_cost,
       'NO' new_11g_ndv_algorithm_used,
       TO_NUMBER(NULL) total_segment_blocks,
       TO_NUMBER(NULL) dbms_space_used_bytes,
       TO_NUMBER(NULL) dbms_space_alloc_bytes,
       TO_NUMBER(NULL) dbms_space_used_blocks,
       TO_NUMBER(NULL) dbms_space_alloc_blocks,
       NULL,
       inmemory,
       inmemory_priority,
       inmemory_compression,
       inmemory_distribute,
       inmemory_duplicate
  FROM &&tool_repository_schema..sqlt$_dba_object_tables;

GRANT SELECT ON &&tool_repository_schema..sqlt$_dba_tables TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_repository_schema..sqlt$_dba_object_tables TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_administer_schema..sqlt$_dba_all_tables_v TO &&role_name.;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_all_table_cols_v AS
SELECT 'DBA_TAB_COLS' source,
       statement_id,
       statid,
       owner,
       table_name,
       column_name,
       data_type,
       data_type_mod,
       data_type_owner,
       data_length,
       data_precision,
       data_scale,
       nullable,
       column_id,
       default_length,
       data_default,
       add_column_default,
       num_distinct,
       mutating_ndv,
       low_value,
       high_value,
       density,
       num_nulls,
       num_buckets,
       last_analyzed,
       sample_size,
       character_set_name,
       char_col_decl_length,
       global_stats,
       user_stats,
       avg_col_len,
       char_length,
       char_used,
       v80_fmt_image,
       data_upgraded,
       hidden_column,
       virtual_column,
       segment_column_id,
       internal_column_id,
       histogram,
       qualified_col_name,
       in_predicates,
       in_projection,
       in_indexes,
       low_value_cooked,
       high_value_cooked,
       popular_values,
       buckets_pop_vals,
       new_density,
       endpoints_count,
       mutating_endpoints,
       inmemory_compression
  FROM &&tool_repository_schema..sqlt$_dba_tab_cols
 UNION ALL
SELECT 'DBA_NESTED_TABLE_COLS' source,
       statement_id,
       statid,
       owner,
       table_name,
       column_name,
       data_type,
       data_type_mod,
       data_type_owner,
       data_length,
       data_precision,
       data_scale,
       nullable,
       column_id,
       default_length,
       data_default,
       NULL add_column_default,
       num_distinct,
       mutating_ndv,
       low_value,
       high_value,
       density,
       num_nulls,
       num_buckets,
       last_analyzed,
       sample_size,
       character_set_name,
       char_col_decl_length,
       global_stats,
       user_stats,
       avg_col_len,
       char_length,
       char_used,
       v80_fmt_image,
       data_upgraded,
       hidden_column,
       virtual_column,
       segment_column_id,
       internal_column_id,
       histogram,
       qualified_col_name,
       in_predicates,
       in_projection,
       in_indexes,
       low_value_cooked,
       high_value_cooked,
       popular_values,
       buckets_pop_vals,
       new_density,
       endpoints_count,
       mutating_endpoints,
       NULL
  FROM &&tool_repository_schema..sqlt$_dba_nested_table_cols;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_indexes_v AS
SELECT x.statement_id,
       x.table_owner,
       x.table_name,
       x.owner index_owner,
       x.index_name,
       x.object_id,
       x.in_plan,
       COUNT(*) columns,
       MAX(tc.in_predicates) in_predicates,
       MAX(tc.in_projection) in_projection,
       MIN(tc.column_id) leading_column_id,
       CASE WHEN COUNT(*) = 1 THEN MAX(ic.column_name) END column_name,
       CASE WHEN COUNT(*) = 1 THEN MAX(ic.descend) END descend
  FROM &&tool_repository_schema..sqlt$_dba_indexes x,
       &&tool_repository_schema..sqlt$_dba_ind_columns ic,
       &&tool_repository_schema..sqlt$_dba_tab_cols tc
 WHERE x.statement_id = ic.statement_id
   AND x.owner = ic.index_owner
   AND x.index_name = ic.index_name
   AND ic.statement_id = tc.statement_id
   AND ic.table_owner = tc.owner
   AND ic.table_name = tc.table_name
   AND ic.column_name = tc.column_name
 GROUP BY
       x.statement_id,
       x.table_owner,
       x.table_name,
       x.owner,
       x.index_name,
       x.object_id,
       x.in_plan;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_ind_columns_v AS
SELECT ic.statement_id,
       tc.in_predicates,
       tc.in_projection,
       ic.table_owner,
       ic.table_name,
       tc.column_id,
       ic.column_name,
       MIN(column_position) min_column_position,
       MAX(column_position) max_column_position,
       COUNT(*) indexes,
       CASE WHEN COUNT(*) = 1 THEN MAX(ic.index_owner) END index_owner,
       CASE WHEN COUNT(*) = 1 THEN MAX(ic.index_name) END index_name,
       CASE WHEN COUNT(*) = 1 THEN MAX(ic.descend) END descend
  FROM &&tool_repository_schema..sqlt$_dba_ind_columns ic,
       &&tool_repository_schema..sqlt$_dba_tab_cols tc
 WHERE ic.statement_id = tc.statement_id
   AND ic.table_owner = tc.owner
   AND ic.table_name = tc.table_name
   AND ic.column_name = tc.column_name
 GROUP BY
       ic.statement_id,
       tc.in_predicates,
       tc.in_projection,
       ic.table_owner,
       ic.table_name,
       tc.column_id,
       ic.column_name;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_tab_stats_versions_v AS
SELECT statement_id,
       statid,
       owner,
       table_name,
       partition_name,
       subpartition_name,
       object_type,
       num_rows,
       blocks,
       avg_row_len,
       sample_size,
       last_analyzed,
       CASE
       WHEN object_type = 'TABLE' THEN DECODE(BITAND(flags, 512), 0, 'NO', 'YES')
       WHEN object_type IN ('PARTITION', 'SUBPARTITION') THEN DECODE(BITAND(flags, 16), 0, 'NO', 'YES')
       END global_stats,
       CASE
       WHEN object_type = 'TABLE' THEN DECODE(BITAND(flags, 256), 0, 'NO', 'YES')
       WHEN object_type IN ('PARTITION', 'SUBPARTITION') THEN DECODE(BITAND(flags, 8), 0, 'NO', 'YES')
       END user_stats,
       save_time,
       version_type
  FROM &&tool_repository_schema..sqlt$_dba_tab_stats_versions
 UNION ALL
SELECT statement_id,
       statid,
       owner,
       table_name,
       partition_name,
       subpartition_name,
       object_type,
       num_rows,
       blocks,
       avg_row_len,
       sample_size,
       last_analyzed,
       global_stats,
       user_stats,
       TO_TIMESTAMP_TZ(NULL) save_time,
       'CURRENT' version_type
  FROM &&tool_repository_schema..sqlt$_dba_tab_statistics;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_ind_stats_versions_v AS
SELECT statement_id,
       statid,
       owner,
       index_name,
       table_owner,
       table_name,
       partition_name,
       subpartition_name,
       object_type,
       blevel,
       leaf_blocks,
       distinct_keys,
       avg_leaf_blocks_per_key,
       avg_data_blocks_per_key,
       clustering_factor,
       num_rows,
       sample_size,
       last_analyzed,
       CASE
       WHEN object_type = 'INDEX' THEN DECODE(BITAND(flags, 2048), 0, 'NO', 'YES')
       WHEN object_type IN ('PARTITION', 'SUBPARTITION') THEN DECODE(BITAND(flags, 16), 0, 'NO', 'YES')
       END global_stats,
       CASE
       WHEN object_type = 'INDEX' THEN DECODE(BITAND(flags, 64), 0, 'NO', 'YES')
       WHEN object_type IN ('PARTITION', 'SUBPARTITION') THEN DECODE(BITAND(flags, 8), 0, 'NO', 'YES')
       END user_stats,
       save_time,
       version_type
  FROM &&tool_repository_schema..sqlt$_dba_ind_stats_versions
 UNION ALL
SELECT statement_id,
       statid,
       owner,
       index_name,
       table_owner,
       table_name,
       partition_name,
       subpartition_name,
       object_type,
       blevel,
       leaf_blocks,
       distinct_keys,
       avg_leaf_blocks_per_key,
       avg_data_blocks_per_key,
       clustering_factor,
       num_rows,
       sample_size,
       last_analyzed,
       global_stats,
       user_stats,
       TO_TIMESTAMP_TZ(NULL) save_time,
       'CURRENT' version_type
  FROM &&tool_repository_schema..sqlt$_dba_ind_statistics;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_col_stats_versions_v AS
SELECT statement_id,
       statid,
       owner,
       table_name,
       partition_name,
       subpartition_name,
       object_id,
       object_type,
       column_name,
       column_id,
       num_distinct,
       low_value,
       high_value,
       density,
       num_nulls,
       avg_col_len,
       sample_size,
       last_analyzed,
       save_time,
       version_type,
       low_value_cooked,
       high_value_cooked,
       endpoints_count
  FROM &&tool_repository_schema..sqlt$_dba_col_stats_versions
 UNION ALL
SELECT statement_id,
       statid,
       owner,
       table_name,
       TO_CHAR(NULL) partition_name,
       TO_CHAR(NULL) subpartition_name,
       TO_NUMBER(NULL) object_id,
       'TABLE' object_type,
       column_name,
       column_id,
       num_distinct,
       low_value,
       high_value,
       density,
       num_nulls,
       avg_col_len,
       sample_size,
       last_analyzed,
       TO_TIMESTAMP_TZ(NULL) save_time,
       'CURRENT' version_type,
       low_value_cooked,
       high_value_cooked,
       endpoints_count
  FROM &&tool_repository_schema..sqlt$_dba_tab_cols
 UNION ALL
SELECT statement_id,
       statid,
       owner,
       table_name,
       partition_name,
       TO_CHAR(NULL) subpartition_name,
       TO_NUMBER(NULL) object_id,
       'PARTITION' object_type,
       column_name,
       TO_NUMBER(NULL) column_id,
       num_distinct,
       low_value,
       high_value,
       density,
       num_nulls,
       avg_col_len,
       sample_size,
       last_analyzed,
       TO_TIMESTAMP_TZ(NULL) save_time,
       'CURRENT' version_type,
       low_value_cooked,
       high_value_cooked,
       endpoints_count
  FROM &&tool_repository_schema..sqlt$_dba_part_col_statistics
 UNION ALL
SELECT statement_id,
       statid,
       owner,
       table_name,
       TO_CHAR(NULL) partition_name,
       subpartition_name,
       TO_NUMBER(NULL) object_id,
       'SUBPARTITION' object_type,
       column_name,
       TO_NUMBER(NULL) column_id,
       num_distinct,
       low_value,
       high_value,
       density,
       num_nulls,
       avg_col_len,
       sample_size,
       last_analyzed,
       TO_TIMESTAMP_TZ(NULL) save_time,
       'CURRENT' version_type,
       low_value_cooked,
       high_value_cooked,
       endpoints_count
  FROM &&tool_repository_schema..sqlt$_dba_subpart_col_stats;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_histgrm_stats_vers_v AS
SELECT statement_id,
       statid,
       owner,
       table_name,
       partition_name,
       subpartition_name,
       object_id,
       object_type,
       column_name,
       column_id,
       endpoint_number,
       endpoint_value,
       endpoint_actual_value,
       save_time,
       version_type
  FROM &&tool_repository_schema..sqlt$_dba_histgrm_stats_versn
 UNION ALL
SELECT statement_id,
       statid,
       owner,
       table_name,
       TO_CHAR(NULL) partition_name,
       TO_CHAR(NULL) subpartition_name,
       TO_NUMBER(NULL) object_id,
       'TABLE' object_type,
       column_name,
       TO_NUMBER(NULL) column_id,
       endpoint_number,
       endpoint_value,
       endpoint_actual_value,
       TO_TIMESTAMP_TZ(NULL) save_time,
       'CURRENT' version_type
  FROM &&tool_repository_schema..sqlt$_dba_tab_histograms
 UNION ALL
SELECT statement_id,
       statid,
       owner,
       table_name,
       partition_name,
       TO_CHAR(NULL) subpartition_name,
       TO_NUMBER(NULL) object_id,
       'PARTITION' object_type,
       column_name,
       TO_NUMBER(NULL) column_id,
       bucket_number endpoint_number,
       endpoint_value,
       endpoint_actual_value,
       TO_TIMESTAMP_TZ(NULL) save_time,
       'CURRENT' version_type
  FROM &&tool_repository_schema..sqlt$_dba_part_histograms
 UNION ALL
SELECT statement_id,
       statid,
       owner,
       table_name,
       TO_CHAR(NULL) partition_name,
       subpartition_name,
       TO_NUMBER(NULL) object_id,
       'SUBPARTITION' object_type,
       column_name,
       TO_NUMBER(NULL) column_id,
       bucket_number endpoint_number,
       endpoint_value,
       endpoint_actual_value,
       TO_TIMESTAMP_TZ(NULL) save_time,
       'CURRENT' version_type
  FROM &&tool_repository_schema..sqlt$_dba_subpart_histograms;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_wri$_optstat_aux_hist_v AS
SELECT
  statement_id,
  statid,
  savtime,
  SUM(cpuspeednw) cpuspeednw,
  SUM(ioseektim)  ioseektim,
  SUM(iotfrspeed) iotfrspeed,
  SUM(cpuspeed)   cpuspeed,
  SUM(mbrc)       mbrc,
  SUM(sreadtim)   sreadtim,
  SUM(mreadtim)   mreadtim,
  SUM(maxthr)     maxthr,
  SUM(slavethr)   slavethr
FROM (
SELECT
  statement_id,
  statid,
  savtime,
  DECODE(pname, 'CPUSPEEDNW', pval1) cpuspeednw,
  DECODE(pname, 'IOSEEKTIM',  pval1) ioseektim,
  DECODE(pname, 'IOTFRSPEED', pval1) iotfrspeed,
  DECODE(pname, 'CPUSPEED',   pval1) cpuspeed,
  DECODE(pname, 'MBRC',       pval1) mbrc,
  DECODE(pname, 'SREADTIM',   pval1) sreadtim,
  DECODE(pname, 'MREADTIM',   pval1) mreadtim,
  DECODE(pname, 'MAXTHR',     pval1) maxthr,
  DECODE(pname, 'SLAVETHR',   pval1) slavethr
FROM &&tool_repository_schema..sqlt$_wri$_optstat_aux_history
WHERE sname = 'SYSSTATS_MAIN') v
GROUP BY
  statement_id,
  statid,
  savtime;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_gv$segment_statistics_v AS
SELECT e.statement_id,
       e.statid,
       ( NVL(e.value, 0) - NVL(b.value, 0)) value,
       e.statistic_name,
       e.object_name,
       e.subobject_name,
       e.owner,
       e.object_type,
       e.inst_id,
       e.tablespace_name,
       e.obj#,
       e.dataobj#,
       e.statistic#,
       b.value begin_value,
       e.value end_value
  FROM &&tool_repository_schema..sqlt$_gv$segment_statistics b,
       &&tool_repository_schema..sqlt$_gv$segment_statistics e
 WHERE e.begin_end_flag = 'E'
   AND EXISTS (
SELECT NULL
  FROM &&tool_repository_schema..sqlt$_dba_segments s
 WHERE s.statement_id = e.statement_id
   AND s.owner = e.owner
   AND s.segment_name = e.object_name
   AND NVL(s.partition_name, '-666') = NVL(e.subobject_name, '-666'))
   AND e.statement_id = b.statement_id(+)
   AND 'B' = b.begin_end_flag(+)
   AND e.inst_id = b.inst_id(+)
   AND e.owner = b.owner(+)
   AND e.object_name = b.object_name(+)
   AND NVL(e.subobject_name, '-666') = NVL(b.subobject_name(+), '-666')
   AND e.statistic_name = b.statistic_name(+)
   AND NVL(e.value, 0) > NVL(b.value(+), 0);

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_gv$cell_state_v AS
SELECT e.statement_id,
       e.statid,
       e.inst_id,
       e.cell_name,
       e.statistics_type,
       e.object_name,
       b.statistics_value statistics_value_b,
       e.statistics_value statistics_value_e
  FROM &&tool_repository_schema..sqlt$_gv$cell_state b,
       &&tool_repository_schema..sqlt$_gv$cell_state e
 WHERE e.begin_end_flag = 'E'
   AND e.statement_id = b.statement_id(+)
   AND 'B' = b.begin_end_flag(+)
   AND e.inst_id = b.inst_id(+)
   AND e.cell_name = b.cell_name(+)
   AND e.statistics_type = b.statistics_type(+)
   AND e.object_name = b.object_name(+);

GRANT SELECT ON &&tool_administer_schema..sqlt$_gv$cell_state_v TO &&role_name.;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_gv$session_event_v AS
SELECT e.statement_id,
       e.statid,
       ROUND((NVL(e.time_waited_micro, 0) - NVL(b.time_waited_micro, 0))/1e6, 6) time_waited_secs,
       e.event,
       e.inst_id,
       (NVL(e.total_waits, 0) - NVL(b.total_waits, 0)) total_waits,
       ROUND((NVL(e.time_waited_micro, 0) - NVL(b.time_waited_micro, 0))/GREATEST(1, NVL(e.total_waits, 0) - NVL(b.total_waits, 0))/1e6, 6) avg_wait_secs,
       (NVL(e.total_timeouts, 0) - NVL(b.total_timeouts, 0)) total_timeouts
  FROM &&tool_repository_schema..sqlt$_gv$session_event b,
       &&tool_repository_schema..sqlt$_gv$session_event e
 WHERE e.begin_end_flag = 'E'
   AND e.statement_id = b.statement_id(+)
   AND 'B' = b.begin_end_flag(+)
   AND e.inst_id = b.inst_id(+)
   AND e.event = b.event(+)
   AND NVL(e.time_waited_micro, 0) > NVL(b.time_waited_micro(+), 0);

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_gv$sesstat_v AS
SELECT e.statement_id,
       e.statid,
       TRIM (',' FROM
       TRIM (' ' FROM
       DECODE(BITAND(n.class,   1),   1, 'User, ')||
       DECODE(BITAND(n.class,   2),   2, 'Redo, ')||
       DECODE(BITAND(n.class,   4),   4, 'Enqueue, ')||
       DECODE(BITAND(n.class,   8),   8, 'Cache, ')||
       DECODE(BITAND(n.class,  16),  16, 'OS, ')||
       DECODE(BITAND(n.class,  32),  32, 'RAC, ')||
       DECODE(BITAND(n.class,  64),  64, 'SQL, ')||
       DECODE(BITAND(n.class, 128), 128, 'Debug, ')
       )) class_name,
       n.class,
       n.name,
       e.inst_id,
	   e.sid,
	   e.serial#,
       (NVL(e.value, 0) - NVL(b.value, 0)) value,
       e.statistic#,
       b.value begin_value,
       e.value end_value,
	   NULL value_per_sec
  FROM &&tool_repository_schema..sqlt$_gv$sesstat b,
       &&tool_repository_schema..sqlt$_gv$sesstat e,
       &&tool_repository_schema..sqlt$_gv$statname n
 WHERE e.begin_end_flag = 'E'
   AND e.statement_id = b.statement_id(+)
   AND 'B' = b.begin_end_flag(+)
   AND e.statistic# = b.statistic#(+)
   AND e.inst_id = b.inst_id(+)
   AND NVL(e.value, 0) >= NVL(b.value(+), 0)
   AND e.statement_id = n.statement_id
   AND e.statistic# = n.statistic#
   AND e.inst_id = n.inst_id
  /* This section belongs to V$SESSTAT in XTRACT project, on-hold for now   
   AND e.sequence IS NULL  -- it means this is from XECUTE
   AND b.sequence(+) IS NULL   -- it means this is from XECUTE
UNION ALL
SELECT e.statement_id,
       e.statid,
       TRIM (',' FROM
       TRIM (' ' FROM
       DECODE(BITAND(n.class,   1),   1, 'User, ')||
       DECODE(BITAND(n.class,   2),   2, 'Redo, ')||
       DECODE(BITAND(n.class,   4),   4, 'Enqueue, ')||
       DECODE(BITAND(n.class,   8),   8, 'Cache, ')||
       DECODE(BITAND(n.class,  16),  16, 'OS, ')||
       DECODE(BITAND(n.class,  32),  32, 'RAC, ')||
       DECODE(BITAND(n.class,  64),  64, 'SQL, ')||
       DECODE(BITAND(n.class, 128), 128, 'Debug, ')
       )) class_name,
       n.class,
       n.name,
       e.inst_id,
	   e.sid,
	   e.serial#,
       (NVL(e.value, 0) - NVL(b.value, 0)) value,
       e.statistic#,
       b.value begin_value,
       e.value end_value,
	   (NVL(e.value, 0) - NVL(b.value, 0))/v.num_seq value_per_sec
  FROM (SELECT  statement_id, inst_id, sid, begin_end_flag, MIN(sequence) min_seq, MAX(sequence) max_seq, (MAX(sequence)-MIN(sequence))+1 num_seq
          FROM (SELECT statement_id, inst_id, sid, begin_end_flag, sequence, 
                       sequence-LAG(sequence, 1,sequence) OVER (PARTITION BY statement_id,inst_id, sid, begin_end_flag ORDER BY sequence) seq_before,
         	           LEAD(sequence, 1,sequence) OVER (PARTITION BY statement_id,inst_id, sid, begin_end_flag ORDER BY sequence)-sequence seq_after
                 FROM (SELECT DISTINCT statement_id, inst_id, sid, begin_end_flag, sequence 
         		         FROM &&tool_repository_schema..sqlt$_gv$sesstat 
         				WHERE sequence IS NOT NULL)  -- it means this is from XTRACT 
         		)
         WHERE seq_before = 1 OR seq_after = 1
         GROUP BY statement_id, inst_id, sid, begin_end_flag) v,
       &&tool_repository_schema..sqlt$_gv$sesstat b,
       &&tool_repository_schema..sqlt$_gv$sesstat e,
       &&tool_repository_schema..sqlt$_gv$statname n
 WHERE v.statement_id = b.statement_id
   AND v.inst_id = b.inst_id
   AND v.sid = b.sid
   AND v.begin_end_flag = b.begin_end_flag
   AND v.min_seq = b.sequence
   AND v.statement_id = e.statement_id
   AND v.inst_id = e.inst_id
   AND v.sid = e.sid
   AND v.begin_end_flag = e.begin_end_flag
   AND v.max_seq = e.sequence
   AND e.statistic# = b.statistic#
   AND NVL(e.value, 0) >= NVL(b.value, 0)
   AND e.statement_id = n.statement_id
   AND e.statistic# = n.statistic#
   AND e.inst_id = n.inst_id */
   ;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_gv$px_sesstat_v AS
SELECT e.statement_id,
       e.statid,
       TRIM (',' FROM
       TRIM (' ' FROM
       DECODE(BITAND(n.class,   1),   1, 'User, ')||
       DECODE(BITAND(n.class,   2),   2, 'Redo, ')||
       DECODE(BITAND(n.class,   4),   4, 'Enqueue, ')||
       DECODE(BITAND(n.class,   8),   8, 'Cache, ')||
       DECODE(BITAND(n.class,  16),  16, 'OS, ')||
       DECODE(BITAND(n.class,  32),  32, 'RAC, ')||
       DECODE(BITAND(n.class,  64),  64, 'SQL, ')||
       DECODE(BITAND(n.class, 128), 128, 'Debug, ')
       )) class_name,
       n.class,
       n.name,
       e.qcsid,
       e.qcserial#,
       e.qcinst_id,
       e.server_group,
       e.server_set,
       e.server#,
       e.degree,
       e.req_degree,
       e.inst_id,
       e.saddr,
       e.sid,
       e.serial#,
       (NVL(e.value, 0) - NVL(b.value, 0)) value,
       e.statistic#,
       b.value begin_value,
       e.value end_value
  FROM &&tool_repository_schema..sqlt$_gv$px_sesstat b,
       &&tool_repository_schema..sqlt$_gv$px_sesstat e,
       &&tool_repository_schema..sqlt$_gv$statname n
 WHERE e.begin_end_flag = 'E'
   AND e.statement_id = b.statement_id(+)
   AND 'B' = b.begin_end_flag(+)
   AND e.statistic# = b.statistic#(+)
   AND e.inst_id = b.inst_id(+)
   AND e.saddr = b.saddr(+)
   AND e.sid = b.sid(+)
   AND e.serial# = b.serial#(+)
   AND e.qcsid = b.qcsid(+)
   AND NVL(e.value, 0) >= NVL(b.value(+), 0)
   AND e.statement_id = n.statement_id
   AND e.statistic# = n.statistic#
   AND e.inst_id = n.inst_id;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_gv$pq_sysstat_v AS
SELECT b.statement_id,
       b.statistic,
       b.inst_id,
       b.value value_before,
       e.value value_after,
       (e.value - b.value) difference
  FROM &&tool_repository_schema..sqlt$_gv$pq_sysstat b,
       &&tool_repository_schema..sqlt$_gv$pq_sysstat e
 WHERE b.begin_end_flag = 'B'
   AND b.statement_id = e.statement_id
   AND b.inst_id = e.inst_id
   AND b.statistic = e.statistic
   AND e.begin_end_flag = 'E'
 ORDER BY
       b.inst_id,
       b.ROWID;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_gv$px_process_sysstat_v AS
SELECT b.statement_id,
       b.statistic,
       b.inst_id,
       b.value value_before,
       e.value value_after,
       (e.value - b.value) difference
  FROM &&tool_repository_schema..sqlt$_gv$px_process_sysstat b,
       &&tool_repository_schema..sqlt$_gv$px_process_sysstat e
 WHERE b.begin_end_flag = 'B'
   AND b.statement_id = e.statement_id
   AND b.inst_id = e.inst_id
   AND b.statistic = e.statistic
   AND e.begin_end_flag = 'E'
 ORDER BY
       b.inst_id,
       b.ROWID;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_hist_sqlstat_v AS
SELECT h.statement_id,
       h.snap_id,
       h.dbid,
       h.instance_number,
       t.begin_interval_time,
       t.end_interval_time,
       t.startup_time,
       h.sql_id,
       h.plan_hash_value,
       CASE WHEN h.plan_hash_value = s.best_plan_hash_value THEN '[<b><font class="green">B</font></b>]' END best_plan,
       CASE WHEN h.plan_hash_value = s.worst_plan_hash_value THEN '[<b><font class="crimson">W</font></b>]' END worst_plan,
       CASE WHEN h.plan_hash_value = s.xecute_plan_hash_value THEN '[<b><font class="darkblue">X</font></b>]' END xecute_plan,
       h.optimizer_env_hash_value,
       h.optimizer_cost,
       h.optimizer_mode,
       h.version_count,
       h.sharable_mem,
       h.loaded_versions,
       h.sql_profile,
       h.force_matching_signature,
       h.parsing_schema_id,
       h.parsing_schema_name,
       h.parsing_user_id,
       h.executions_delta,
       h.elapsed_time_delta,
       h.cpu_time_delta,
       h.iowait_delta,
       (h.apwait_delta + h.ccwait_delta + h.clwait_delta + h.plsexec_time_delta + h.javexec_time_delta) other_wait_delta,
       h.apwait_delta,
       h.ccwait_delta,
       h.clwait_delta,
       h.plsexec_time_delta,
       h.javexec_time_delta,
       h.buffer_gets_delta,
       h.disk_reads_delta,
       h.direct_writes_delta,
       h.rows_processed_delta,
       h.parse_calls_delta,
       h.fetches_delta,
       h.end_of_fetch_count_delta,
       h.px_servers_execs_delta,
       h.loads_delta,
       h.invalidations_delta,
       h.sorts_delta,
       h.physical_read_requests_delta,
       h.physical_read_bytes_delta,
       h.physical_write_requests_delta,
       h.physical_write_bytes_delta,
       h.optimized_physical_reads_delta,
       h.cell_uncompressed_bytes_delta,
       h.io_offload_elig_bytes_delta,
       h.io_offload_return_bytes_delta,
       h.io_interconnect_bytes_delta,
       h.executions_total,
       h.elapsed_time_total,
       h.cpu_time_total,
       h.iowait_total,
       (h.apwait_total + h.ccwait_total + h.clwait_total + h.plsexec_time_total + h.javexec_time_total) other_wait_total,
       h.apwait_total,
       h.ccwait_total,
       h.clwait_total,
       h.plsexec_time_total,
       h.javexec_time_total,
       h.buffer_gets_total,
       h.disk_reads_total,
       h.direct_writes_total,
       h.rows_processed_total,
       h.parse_calls_total,
       h.fetches_total,
       h.end_of_fetch_count_total,
       h.px_servers_execs_total,
       h.loads_total,
       h.invalidations_total,
       h.sorts_total,
       h.physical_read_requests_total,
       h.physical_read_bytes_total,
       h.physical_write_requests_total,
       h.physical_write_bytes_total,
       h.optimized_physical_reads_total,
       h.cell_uncompressed_bytes_total,
       h.io_offload_elig_bytes_total,
       h.io_offload_return_bytes_total,
       h.io_interconnect_bytes_total
  FROM &&tool_repository_schema..sqlt$_dba_hist_sqlstat h,
       &&tool_repository_schema..sqlt$_dba_hist_snapshot t,
       &&tool_repository_schema..sqlt$_sql_statement s
 WHERE h.statement_id = t.statement_id
   AND h.snap_id = t.snap_id
   AND h.dbid = t.dbid
   AND h.instance_number = t.instance_number
   AND h.statement_id = s.statement_id;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_plan_stats_v AS
SELECT a.statement_id,
       a.statid,
       'MEM' src,
       1 src_order,
       'GV$SQLAREA_PLAN_HASH' source,
       a.plan_hash_value,
       CASE WHEN a.plan_hash_value = s.best_plan_hash_value THEN '[<b><font class="green">B</font></b>]' END best_plan,
       CASE WHEN a.plan_hash_value = s.worst_plan_hash_value THEN '[<b><font class="crimson">W</font></b>]' END worst_plan,
       CASE WHEN a.plan_hash_value = s.xecute_plan_hash_value THEN '[<b><font class="darkblue">X</font></b>]' END xecute_plan,
       a.in_plan_extension,
       CASE WHEN a.in_plan_extension = 'Y' THEN plan_hash_value||'_1' END link_id,
       a.inst_id,
       a.version_count,
       a.executions,
       a.elapsed_time,
       a.cpu_time,
       a.user_io_wait_time,
       (a.application_wait_time + a.concurrency_wait_time + a.cluster_wait_time + a.plsql_exec_time + a.java_exec_time) other_wait_time,
       a.application_wait_time,
       a.concurrency_wait_time,
       a.cluster_wait_time,
       a.plsql_exec_time,
       a.java_exec_time,
       a.buffer_gets,
       a.disk_reads,
       a.direct_writes,
       a.rows_processed,
       a.parse_calls,
       a.fetches,
       a.end_of_fetch_count,
       a.px_servers_executions,
       a.loaded_versions,
       a.loads,
       a.invalidations,
       a.open_versions,
       a.kept_versions,
       a.users_executing,
       a.users_opening,
       a.first_load_time,
       a.last_load_time,
       a.last_active_time,
       TO_NUMBER(NULL) snap_id,
       TO_DATE(NULL) snap_begin_date,
       TO_DATE(NULL) snap_end_date,
       (SELECT MIN(timestamp)
          FROM &&tool_repository_schema..sqlt$_gv$sql_plan p
         WHERE a.statement_id = p.statement_id
           AND a.inst_id = p.inst_id
           AND a.plan_hash_value = p.plan_hash_value
           AND p.id = 0) plan_timestamp,
       a.sharable_mem,
       a.persistent_mem,
       a.runtime_mem,
       a.sorts,
       a.serializable_aborts,
       a.command_type,
       a.optimizer_mode,
       a.optimizer_env_hash_value,
       (SELECT MIN(optimizer_env_hash_value) min_optimizer_env_hash_value
          FROM &&tool_repository_schema..sqlt$_gv$sql s
         WHERE a.statement_id = s.statement_id
           AND a.inst_id = s.inst_id
           AND a.plan_hash_value = s.plan_hash_value) min_optimizer_env_hash_value,
       (SELECT MAX(optimizer_env_hash_value) max_optimizer_env_hash_value
          FROM &&tool_repository_schema..sqlt$_gv$sql s
         WHERE a.statement_id = s.statement_id
           AND a.inst_id = s.inst_id
           AND a.plan_hash_value = s.plan_hash_value) max_optimizer_env_hash_value,
       (SELECT COUNT(DISTINCT optimizer_env_hash_value) cnt_optimizer_env_hash_value
          FROM &&tool_repository_schema..sqlt$_gv$sql s
         WHERE a.statement_id = s.statement_id
           AND a.inst_id = s.inst_id
           AND a.plan_hash_value = s.plan_hash_value) cnt_optimizer_env_hash_value,
       a.optimizer_cost,
       (SELECT ROUND(AVG(cardinality))
          FROM &&tool_repository_schema..sqlt$_plan_extension p
         WHERE a.statement_id = p.statement_id
           AND a.inst_id = p.inst_id
           AND a.plan_hash_value = p.plan_hash_value
           AND p.source = 'GV$SQL_PLAN'
           AND p.id = 0) cardinality,
       a.parsing_user_id,
       a.parsing_schema_id,
       a.parsing_schema_name,
       a.module,
       a.action,
       a.sql_profile,
       a.exact_matching_signature,
       a.force_matching_signature,
       a.outline_category,
       a.remote,
       a.object_status,
       a.program_id,
       a.program_line#,
       a.typecheck_mem,
       a.io_interconnect_bytes,
       a.physical_read_requests,
       a.physical_read_bytes,
       a.physical_write_requests,
       a.physical_write_bytes,
       a.optimized_phy_read_requests,
       a.io_cell_uncompressed_bytes,
       a.io_cell_offload_eligible_bytes,
       a.io_cell_offload_returned_bytes,
       (SELECT DECODE(COUNT(*), 0, 'N', 'Y') is_bind_sensitive
          FROM &&tool_repository_schema..sqlt$_gv$sql s
         WHERE a.statement_id = s.statement_id
           AND a.inst_id = s.inst_id
           AND a.plan_hash_value = s.plan_hash_value
           AND s.is_bind_sensitive = 'Y') is_bind_sensitive,
	   DECODE(a.io_cell_offload_eligible_bytes,0,'No',NULL,NULL,'Yes') is_offloadable,
	   DECODE(a.io_cell_offload_eligible_bytes,0,0,100*(a.io_cell_offload_eligible_bytes-a.io_interconnect_bytes)
	        /DECODE(a.io_cell_offload_eligible_bytes,0,1,a.io_cell_offload_eligible_bytes)) io_saved_percentage
  FROM &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash a,
       &&tool_repository_schema..sqlt$_sql_statement s
 WHERE a.statement_id = s.statement_id
 UNION ALL
SELECT h.statement_id,
       h.statid,
       'AWR' src,
       2 src_order,
       'DBA_HIST_SQLSTAT' source,
       h.plan_hash_value,
       CASE WHEN h.plan_hash_value = s.best_plan_hash_value THEN '[<b><font class="green">B</font></b>]' END best_plan,
       CASE WHEN h.plan_hash_value = s.worst_plan_hash_value THEN '[<b><font class="crimson">W</font></b>]' END worst_plan,
       CASE WHEN h.plan_hash_value = s.xecute_plan_hash_value THEN '[<b><font class="darkblue">X</font></b>]' END xecute_plan,
       h.in_plan_extension,
       CASE WHEN h.in_plan_extension = 'Y' THEN (
       SELECT CASE
              WHEN x.source = 'GV$SQL_PLAN' THEN plan_hash_value||'_1'
              WHEN x.source = 'DBA_HIST_SQL_PLAN' THEN plan_hash_value||'_2'
              END link_id
         FROM &&tool_repository_schema..sqlt$_plan_extension x
        WHERE h.statement_id = x.statement_id
          AND h.plan_hash_value = x.plan_hash_value
          AND x.source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN')
          AND x.id = 0
          AND ROWNUM = 1 )
       END link_id,
       h.instance_number,
       h.version_count,
       h.executions_total,
       h.elapsed_time_total,
       h.cpu_time_total,
       h.iowait_total,
       (h.apwait_total + h.ccwait_total + h.clwait_total + h.plsexec_time_total + h.javexec_time_total) other_wait_total,
       h.apwait_total,
       h.ccwait_total,
       h.clwait_total,
       h.plsexec_time_total,
       h.javexec_time_total,
       h.buffer_gets_total,
       h.disk_reads_total,
       h.direct_writes_total,
       h.rows_processed_total,
       h.parse_calls_total,
       h.fetches_total,
       h.end_of_fetch_count_total,
       h.px_servers_execs_total,
       h.loaded_versions,
       h.loads_total,
       h.invalidations_total,
       TO_NUMBER(NULL) open_versions,
       TO_NUMBER(NULL) kept_versions,
       TO_NUMBER(NULL) users_executing,
       TO_NUMBER(NULL) users_opening,
       h.first_load_time,
       h.last_load_time,
       TO_DATE(NULL) last_active_time,
       h.snap_id,
       t.begin_interval_time,
       t.end_interval_time,
       (SELECT MIN(timestamp)
          FROM &&tool_repository_schema..sqlt$_dba_hist_sql_plan p
         WHERE h.statement_id = p.statement_id
           AND h.dbid = p.dbid
           AND h.plan_hash_value = p.plan_hash_value
           AND p.id = 0) plan_timestamp,
       h.sharable_mem,
       TO_NUMBER(NULL) persistent_mem,
       TO_NUMBER(NULL) runtime_mem,
       h.sorts_total,
       TO_NUMBER(NULL) serializable_aborts,
       TO_NUMBER(NULL) command_type,
       h.optimizer_mode,
       h.optimizer_env_hash_value,
       h.optimizer_env_hash_value min_optimizer_env_hash_value,
       h.optimizer_env_hash_value max_optimizer_env_hash_value,
       1 cnt_optimizer_env_hash_value,
       h.optimizer_cost,
       (SELECT ROUND(AVG(cardinality))
          FROM &&tool_repository_schema..sqlt$_plan_extension p
         WHERE h.statement_id = p.statement_id
           AND h.plan_hash_value = p.plan_hash_value
           AND p.source = 'DBA_HIST_SQL_PLAN'
           AND p.id = 0) cardinality,
       h.parsing_user_id,
       h.parsing_schema_id,
       h.parsing_schema_name,
       h.module,
       h.action,
       h.sql_profile,
       TO_NUMBER(NULL) exact_matching_signature,
       h.force_matching_signature,
       TO_CHAR(NULL) outline_category,
       TO_CHAR(NULL) remote,
       TO_CHAR(NULL) object_status,
       TO_NUMBER(NULL) program_id,
       TO_NUMBER(NULL) program_line#,
       TO_NUMBER(NULL) typecheck_mem,
       h.io_interconnect_bytes_total,
       h.physical_read_requests_total,
       h.physical_read_bytes_total,
       h.physical_write_requests_total,
       h.physical_write_bytes_total,
       h.optimized_physical_reads_total,
       h.cell_uncompressed_bytes_total,
       h.io_offload_elig_bytes_total,
       h.io_offload_return_bytes_total,
       TO_CHAR(NULL) is_bind_sensitive,
	   DECODE(h.io_offload_elig_bytes_total,0,'No',NULL,NULL,'Yes') is_offloadable,
	   DECODE(h.io_offload_elig_bytes_total,0,0,100*(h.io_offload_elig_bytes_total-h.io_interconnect_bytes_total)
	        /DECODE(h.io_offload_elig_bytes_total,0,1,h.io_offload_elig_bytes_total)) io_saved_percentage
  FROM &&tool_repository_schema..sqlt$_dba_hist_sqlstat h,
       &&tool_repository_schema..sqlt$_dba_hist_snapshot t,
       &&tool_repository_schema..sqlt$_sql_statement s
 WHERE NVL(h.in_plan_summary_v, 'Y') = 'Y'
   AND h.statement_id = t.statement_id
   AND h.snap_id = t.snap_id
   AND h.dbid = t.dbid
   AND h.instance_number = t.instance_number
   AND h.statement_id = s.statement_id;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_plan_summary_v AS
SELECT v.statement_id,
       v.statid,
       v.best_plan,
       v.worst_plan,
       v.xecute_plan,
       v.plan_hash_value,
       v.in_plan_extension,
       MIN(v.link_id) link_id,
       MIN(v.min_optimizer_env_hash_value) min_optimizer_env_hash_value,
       MAX(v.max_optimizer_env_hash_value) max_optimizer_env_hash_value,
       MIN(v.optimizer_env_hash_value) optimizer_env_hash_value,
       ROUND(AVG(v.optimizer_cost)) optimizer_cost,
       ROUND(AVG(v.cardinality)) cardinality,
       ROUND(AVG(v.optimizer_cost * s.sreadtim * 1000)) estimated_time,
       ROUND(SUM(NVL(v.elapsed_time, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) elapsed_time,
       ROUND(SUM(NVL(v.cpu_time, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) cpu_time,
       ROUND(SUM(NVL(v.user_io_wait_time, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) user_io_wait_time,
       ROUND(SUM(NVL(v.other_wait_time, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) other_wait_time,
       ROUND(SUM(NVL(v.buffer_gets, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) buffer_gets,
       ROUND(SUM(NVL(v.disk_reads, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) disk_reads,
       ROUND(SUM(NVL(v.direct_writes, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) direct_writes,
       ROUND(SUM(NVL(v.rows_processed, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) rows_processed,
       --(SELECT ROUND(MAX(s.elapsed_time/GREATEST(1, NVL(s.executions, 0))))
       --   FROM &&tool_repository_schema..sqlt$_gv$sql s
       --  WHERE v.statement_id = s.statement_id
       --    AND v.plan_hash_value = s.plan_hash_value) max_elapsed_time,
       --(SELECT ROUND(MIN(s.elapsed_time/GREATEST(1, NVL(s.executions, 0))))
       --   FROM &&tool_repository_schema..sqlt$_gv$sql s
       --  WHERE v.statement_id = s.statement_id
       --    AND v.plan_hash_value = s.plan_hash_value) min_elapsed_time,
       SUM(NVL(v.executions, 0)) executions,
       SUM(NVL(v.fetches, 0)) fetches,
       SUM(NVL(v.version_count, 0)) version_count,
       SUM(NVL(v.loads, 0)) loads,
       SUM(NVL(v.invalidations, 0)) invalidations,
       MIN(v.plan_timestamp) plan_timestamp,
       MIN(v.first_load_time) first_load_time,
       MAX(v.last_load_time) last_load_time,
       'MEM' src,
       1 src_order,
       'GV$SQLAREA_PLAN_HASH' source,
       MAX(v.is_bind_sensitive) is_bind_sensitive
  FROM &&tool_administer_schema..sqlt$_plan_stats_v v,
       &&tool_repository_schema..sqlt$_sql_statement s
 WHERE v.source = 'GV$SQLAREA_PLAN_HASH'
   AND v.statement_id = s.statement_id
 GROUP BY
       v.statement_id,
       v.statid,
       v.best_plan,
       v.worst_plan,
       v.xecute_plan,
       v.plan_hash_value,
       v.in_plan_extension,
       s.best_plan_hash_value,
       s.worst_plan_hash_value,
       s.xecute_plan_hash_value
 UNION ALL
SELECT v.statement_id,
       v.statid,
       v.best_plan,
       v.worst_plan,
       v.xecute_plan,
       v.plan_hash_value,
       v.in_plan_extension,
       MIN(v.link_id) link_id,
       MIN(v.min_optimizer_env_hash_value) min_optimizer_env_hash_value,
       MAX(v.max_optimizer_env_hash_value) max_optimizer_env_hash_value,
       MIN(v.optimizer_env_hash_value) optimizer_env_hash_value,
       ROUND(AVG(v.optimizer_cost)) optimizer_cost,
       ROUND(AVG(v.cardinality)) cardinality,
       ROUND(AVG(v.optimizer_cost * s.sreadtim * 1000)) estimated_time,
       ROUND(SUM(NVL(v.elapsed_time, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) elapsed_time,
       ROUND(SUM(NVL(v.cpu_time, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) cpu_time,
       ROUND(SUM(NVL(v.user_io_wait_time, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) user_io_wait_time,
       ROUND(SUM(NVL(v.other_wait_time, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) other_wait_time,
       ROUND(SUM(NVL(v.buffer_gets, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) buffer_gets,
       ROUND(SUM(NVL(v.disk_reads, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) disk_reads,
       ROUND(SUM(NVL(v.direct_writes, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) direct_writes,
       ROUND(SUM(NVL(v.rows_processed, 0)) / GREATEST(1, SUM(NVL(v.executions, 0)))) rows_processed,
       --TO_NUMBER(NULL) max_elapsed_time,
       --TO_NUMBER(NULL) min_elapsed_time,
       SUM(NVL(v.executions, 0)) executions,
       SUM(NVL(v.fetches, 0)) fetches,
       SUM(NVL(v.version_count, 0)) version_count,
       SUM(NVL(v.loads, 0)) loads,
       SUM(NVL(v.invalidations, 0)) invalidations,
       MIN(v.plan_timestamp) plan_timestamp,
       MIN(v.first_load_time) first_load_time,
       MAX(v.last_load_time) last_load_time,
       'AWR' src,
       2 src_order,
       'DBA_HIST_SQLSTAT' source,
       MAX(v.is_bind_sensitive) is_bind_sensitive
  FROM &&tool_administer_schema..sqlt$_plan_stats_v v,
       &&tool_repository_schema..sqlt$_sql_statement s
 WHERE v.source = 'DBA_HIST_SQLSTAT'
   AND v.statement_id = s.statement_id
   AND NOT EXISTS (
SELECT NULL
  FROM &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash m
 WHERE v.statement_id = m.statement_id
   AND v.plan_hash_value = m.plan_hash_value )
 GROUP BY
       v.statement_id,
       v.statid,
       v.best_plan,
       v.worst_plan,
       v.xecute_plan,
       v.plan_hash_value,
       v.in_plan_extension,
       s.best_plan_hash_value,
       s.worst_plan_hash_value
 UNION ALL
SELECT s.statement_id,
       s.statid,
       CASE WHEN s.xplain_plan_hash_value = s.best_plan_hash_value THEN '[<b><font class="green">B</font></b>]' END best_plan,
       CASE WHEN s.xplain_plan_hash_value = s.worst_plan_hash_value THEN '[<b><font class="crimson">W</font></b>]' END worst_plan,
       CASE WHEN s.xplain_plan_hash_value = s.xecute_plan_hash_value THEN '[<b><font class="crimson">W</font></b>]' END xecute_plan,
       s.xplain_plan_hash_value,
       'Y' in_plan_extension,
       s.xplain_plan_hash_value||'_3_'||p.plan_id link_id,
       TO_NUMBER(NULL) min_optimizer_env_hash_value,
       TO_NUMBER(NULL) max_optimizer_env_hash_value,
       TO_NUMBER(NULL) optimizer_env_hash_value,
       p.cost,
       p.cardinality,
       ROUND(p.cost * s.sreadtim * 1000) estimated_time,
       TO_NUMBER(NULL) elapsed_time,
       TO_NUMBER(NULL) cpu_time,
       TO_NUMBER(NULL) user_io_wait_time,
       TO_NUMBER(NULL) other_wait_time,
       TO_NUMBER(NULL) buffer_gets,
       TO_NUMBER(NULL) disk_reads,
       TO_NUMBER(NULL) direct_writes,
       TO_NUMBER(NULL) rows_processed,
       --TO_NUMBER(NULL) max_elapsed_time,
       --TO_NUMBER(NULL) min_elapsed_time,
       TO_NUMBER(NULL) executions,
       TO_NUMBER(NULL) fetches,
       TO_NUMBER(NULL) version_count,
       TO_NUMBER(NULL) loads,
       TO_NUMBER(NULL) invalidations,
       p.timestamp plan_timestamp,
       TO_DATE(NULL) first_load_time,
       TO_DATE(NULL) last_load_time,
       'XPL' src,
       3 src_order,
       'EXPLAIN PLAN FOR' source,
       TO_CHAR(NULL) is_bind_sensitive
  FROM &&tool_repository_schema..sqlt$_sql_plan_table p,
       &&tool_repository_schema..sqlt$_sql_statement s
 WHERE p.id = 0
   AND p.statement_id = &&tool_administer_schema..sqlt$a.get_statement_id_c(s.statement_id)
   AND NOT EXISTS (
SELECT NULL
  FROM &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash m
 WHERE s.statement_id = m.statement_id
   AND s.xplain_plan_hash_value = m.plan_hash_value )
   AND NOT EXISTS (
SELECT NULL
  FROM &&tool_repository_schema..sqlt$_dba_hist_sqlstat a
 WHERE s.statement_id = a.statement_id
   AND s.xplain_plan_hash_value = a.plan_hash_value )
 UNION ALL
SELECT t.statement_id,
       t.statid,
       CASE WHEN t.plan_hash_value = s.best_plan_hash_value THEN '[<b><font class="green">B</font></b>]' END best_plan,
       CASE WHEN t.plan_hash_value = s.worst_plan_hash_value THEN '[<b><font class="crimson">W</font></b>]' END worst_plan,
       CASE WHEN t.plan_hash_value = s.xecute_plan_hash_value THEN '[<b><font class="crimson">W</font></b>]' END xecute_plan,
       t.plan_hash_value,
       'Y' in_plan_extension,
       t.plan_hash_value||'_4_'||MIN(t.plan_id) link_id,
       TO_NUMBER(NULL) min_optimizer_env_hash_value,
       TO_NUMBER(NULL) max_optimizer_env_hash_value,
       TO_NUMBER(NULL) optimizer_env_hash_value,
       ROUND(AVG(t.cost)) optimizer_cost,
       ROUND(AVG(t.cardinality)) cardinality,
       ROUND(AVG(t.cost * s.sreadtim * 1000)) estimated_time,
       TO_NUMBER(NULL) elapsed_time,
       TO_NUMBER(NULL) cpu_time,
       TO_NUMBER(NULL) user_io_wait_time,
       TO_NUMBER(NULL) other_wait_time,
       TO_NUMBER(NULL) buffer_gets,
       TO_NUMBER(NULL) disk_reads,
       TO_NUMBER(NULL) direct_writes,
       TO_NUMBER(NULL) rows_processed,
       --TO_NUMBER(NULL) max_elapsed_time,
       --TO_NUMBER(NULL) min_elapsed_time,
       TO_NUMBER(NULL) executions,
       TO_NUMBER(NULL) fetches,
       TO_NUMBER(NULL) version_count,
       TO_NUMBER(NULL) loads,
       TO_NUMBER(NULL) invalidations,
       --MAX(t.timestamp) plan_timestamp, -- MIN errors with ORA-01801: date format is too long for internal buffer. MAX with GDK-05041: A full year must be between -4713 and +9999, and not be 0.
       TO_DATE(NULL) plan_timestamp,
       TO_DATE(NULL) first_load_time,
       TO_DATE(NULL) last_load_time,
       'STA' src,
       4 src_order,
       'DBA_SQLTUNE_PLANS' source,
       TO_CHAR(NULL) is_bind_sensitive
  FROM &&tool_repository_schema..sqlt$_dba_sqltune_plans t,
       &&tool_repository_schema..sqlt$_sql_statement s
 WHERE t.in_plan_extension = 'Y'
   AND t.id = 0
   AND t.statement_id = s.statement_id
   AND t.plan_hash_value <> s.xplain_plan_hash_value
   AND NOT EXISTS (
SELECT NULL
  FROM &&tool_repository_schema..sqlt$_gv$sqlarea_plan_hash m
 WHERE t.statement_id = m.statement_id
   AND t.plan_hash_value = m.plan_hash_value )
   AND NOT EXISTS (
SELECT NULL
  FROM &&tool_repository_schema..sqlt$_dba_hist_sqlstat a
 WHERE t.statement_id = a.statement_id
   AND t.plan_hash_value = a.plan_hash_value )
 GROUP BY
       t.statement_id,
       t.statid,
       t.plan_hash_value,
       s.best_plan_hash_value,
       s.worst_plan_hash_value,
       s.xecute_plan_hash_value;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_plan_summary_v2 AS
SELECT statement_id,
       statid,
       best_plan,
       worst_plan,
       xecute_plan,
       plan_hash_value,
       in_plan_extension,
       link_id,
       min_optimizer_env_hash_value,
       max_optimizer_env_hash_value,
       optimizer_env_hash_value,
       optimizer_cost,
       cardinality,
       estimated_time,
       TO_CHAR(ROUND(estimated_time / 1e6, 3), '999999999999990D990') estimated_time_secs,
       elapsed_time,
       TO_CHAR(ROUND(elapsed_time / 1e6, 3), '999999999999990D990') elapsed_time_secs,
       cpu_time,
       TO_CHAR(ROUND(cpu_time / 1e6, 3), '999999999999990D990') cpu_time_secs,
       user_io_wait_time,
       TO_CHAR(ROUND(user_io_wait_time / 1e6, 3), '999999999999990D990') user_io_wait_time_secs,
       other_wait_time,
       TO_CHAR(ROUND(other_wait_time / 1e6, 3), '999999999999990D990') other_wait_time_secs,
       buffer_gets,
       disk_reads,
       direct_writes,
       rows_processed,
       --max_elapsed_time,
       --TO_CHAR(ROUND(max_elapsed_time / 1e6, 3), '999999999999990D990') max_elapsed_time_secs,
       --min_elapsed_time,
       --TO_CHAR(ROUND(min_elapsed_time / 1e6, 3), '999999999999990D990') min_elapsed_time_secs,
       executions,
       fetches,
       version_count,
       loads,
       invalidations,
       plan_timestamp,
       first_load_time,
       last_load_time,
       src,
       src_order,
       source,
       is_bind_sensitive
  FROM &&tool_administer_schema..sqlt$_plan_summary_v;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_plan_header_v AS
SELECT x.statement_id,
       x.statid,
       x.plan_hash_value,
       x.sqlt_plan_hash_value,
       x.sqlt_plan_hash_value2,
       x.plan_id,
       x.task_id,
       x.inst_id,
       x.child_number,
       x.child_address,
       x.timestamp,
       x.optimizer,
       x.cost,
       x.cardinality,
       CASE
       WHEN x.source = 'GV$SQL_PLAN' THEN
       (
       SELECT ROUND(SUM(NVL(v1.rows_processed, 0)) / GREATEST(1, SUM(NVL(v1.executions, 0)))) rows_processed
         FROM &&tool_administer_schema..sqlt$_plan_stats_v v1
        WHERE x.statement_id = v1.statement_id
          AND x.plan_hash_value = v1.plan_hash_value
          AND v1.source = 'GV$SQLAREA_PLAN_HASH' )
       WHEN x.source = 'DBA_HIST_SQL_PLAN' THEN
       (
       SELECT ROUND(SUM(NVL(v2.rows_processed, 0)) / GREATEST(1, SUM(NVL(v2.executions, 0)))) rows_processed
         FROM &&tool_administer_schema..sqlt$_plan_stats_v v2
        WHERE x.statement_id = v2.statement_id
          AND x.plan_hash_value = v2.plan_hash_value
          AND v2.source = 'DBA_HIST_SQLSTAT' )
       END rows_processed,
       x.attribute,
       CASE
       WHEN x.source = 'GV$SQL_PLAN' THEN 'MEM'
       WHEN x.source = 'DBA_HIST_SQL_PLAN' THEN 'AWR'
       WHEN x.source = 'PLAN_TABLE' THEN 'XPL'
       WHEN x.source = 'DBA_SQLTUNE_PLANS' THEN 'STA'
       END src,
       CASE
       WHEN x.source = 'GV$SQL_PLAN' THEN 1
       WHEN x.source = 'DBA_HIST_SQL_PLAN' THEN 2
       WHEN x.source = 'PLAN_TABLE' THEN 3
       WHEN x.source = 'DBA_SQLTUNE_PLANS' THEN 4
       END src_order,
       x.source,
       CASE
       WHEN x.source = 'GV$SQL_PLAN' THEN
       (
       SELECT DECODE(COUNT(*), 0, 'N', 'Y') is_bind_sensitive
         FROM &&tool_administer_schema..sqlt$_plan_stats_v v3
        WHERE x.statement_id = v3.statement_id
          AND x.plan_hash_value = v3.plan_hash_value
          AND v3.source = 'GV$SQLAREA_PLAN_HASH'
          AND v3.is_bind_sensitive = 'Y' )
       END is_bind_sensitive,
       CASE
       WHEN x.source = 'GV$SQL_PLAN' THEN x.plan_hash_value||'_1'
       WHEN x.source = 'DBA_HIST_SQL_PLAN' THEN x.plan_hash_value||'_2'
       WHEN x.source = 'PLAN_TABLE' THEN x.plan_hash_value||'_3_'||x.plan_id
       WHEN x.source = 'DBA_SQLTUNE_PLANS' THEN x.plan_hash_value||'_4_'||x.plan_id
       END link_id,
       CASE
       WHEN x.source = 'GV$SQL_PLAN' THEN (
       SELECT COUNT(DISTINCT p.inst_id||'.'||p.child_number)
         FROM &&tool_repository_schema..sqlt$_gv$sql_plan p
        WHERE x.statement_id = p.statement_id
          AND x.plan_hash_value = p.plan_hash_value
          AND p.id = 1)
       END child_plans,
       CASE
       WHEN x.plan_hash_value = s.best_plan_hash_value AND x.plan_hash_value = s.worst_plan_hash_value AND x.plan_hash_value = s.xecute_plan_hash_value THEN
       ' [<b><font class="green">B</font></b>] [<b><font class="crimson">W</font></b>] [<b><font class="darkblue">X</font></b>]'
       WHEN x.plan_hash_value = s.best_plan_hash_value AND x.plan_hash_value = s.worst_plan_hash_value THEN
       ' [<b><font class="green">B</font></b>] [<b><font class="crimson">W</font></b>]'
       WHEN x.plan_hash_value = s.best_plan_hash_value AND x.plan_hash_value = s.xecute_plan_hash_value THEN
       ' [<b><font class="green">B</font></b>] [<b><font class="darkblue">X</font></b>]'
       WHEN x.plan_hash_value = s.worst_plan_hash_value AND x.plan_hash_value = s.xecute_plan_hash_value THEN
       ' [<b><font class="crimson">W</font></b>] [<b><font class="darkblue">X</font></b>]'
       WHEN x.plan_hash_value = s.best_plan_hash_value THEN
       ' [<b><font class="green">B</font></b>]'
       WHEN x.plan_hash_value = s.worst_plan_hash_value THEN
       ' [<b><font class="crimson">W</font></b>]'
       WHEN x.plan_hash_value = s.xecute_plan_hash_value THEN
       ' [<b><font class="darkblue">X</font></b>]'
       END plan_flags
  FROM &&tool_repository_schema..sqlt$_plan_extension x,
       &&tool_repository_schema..sqlt$_sql_statement s
 WHERE x.id = 0
   AND x.statement_id = s.statement_id;

/*------------------------------------------------------------------*/

-- used by dbms_xplan
CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_plan_statistics_v AS
SELECT p.statement_id,
       p.statid,
       'GV$SQL_PLAN' source,
       TO_NUMBER(NULL) plan_id,
       p.inst_id,
       p.address,
       p.hash_value,
       p.sql_id,
       p.plan_hash_value,
       p.child_address,
       p.child_number,
       p.timestamp,
       p.operation,
       p.options,
       p.object_node,
       p.object#,
       p.object_owner,
       p.object_name,
       p.object_alias,
       p.object_type,
       p.optimizer,
       p.id,
       p.parent_id,
       p.depth,
       p.position,
       p.search_columns,
       p.cost,
       p.cardinality,
       p.bytes,
       p.other_tag,
       p.partition_start,
       p.partition_stop,
       p.partition_id,
       p.other,
       p.distribution,
       p.cpu_cost,
       p.io_cost,
       p.temp_space,
       p.access_predicates,
       p.filter_predicates,
       p.projection,
       p.time,
       p.qblock_name,
       p.remarks,
       p.other_xml,
       s.executions,
       s.last_starts,
       s.starts,
       s.last_output_rows,
       s.output_rows,
       s.last_cr_buffer_gets,
       s.cr_buffer_gets,
       s.last_cu_buffer_gets,
       s.cu_buffer_gets,
       s.last_disk_reads,
       s.disk_reads,
       s.last_disk_writes,
       s.disk_writes,
       s.last_elapsed_time,
       s.elapsed_time,
       w.policy,
       w.estimated_optimal_size,
       w.estimated_onepass_size,
       w.last_memory_used,
       w.last_execution,
       w.last_degree,
       w.total_executions,
       w.optimal_executions,
       w.onepass_executions,
       w.multipasses_executions,
       w.active_time,
       w.max_tempseg_size,
       w.last_tempseg_size
  FROM &&tool_repository_schema..sqlt$_gv$sql_plan p,
       &&tool_repository_schema..sqlt$_gv$sql_plan_statistics s,
       &&tool_repository_schema..sqlt$_gv$sql_workarea w
 WHERE p.statement_id = s.statement_id(+)
   AND p.statid = s.statid(+)
   AND p.inst_id = s.inst_id(+)
   AND p.address = s.address(+)
   AND p.hash_value = s.hash_value(+)
   AND p.sql_id = s.sql_id(+)
   AND p.plan_hash_value = s.plan_hash_value(+)
   AND p.child_address = s.child_address(+)
   AND p.child_number = s.child_number(+)
   AND p.id = s.operation_id(+)
   AND p.statement_id = w.statement_id(+)
   AND p.statid = w.statid(+)
   AND p.inst_id = w.inst_id(+)
   AND p.address = w.address(+)
   AND p.hash_value = w.hash_value(+)
   AND p.sql_id = w.sql_id(+)
   AND p.child_number = w.child_number(+)
   AND p.id = w.operation_id(+)
 UNION ALL
SELECT x.statement_id,
       x.statid,
       x.source,
       x.plan_id,
       x.inst_id,
       x.address,
       x.hash_value,
       x.sql_id,
       x.plan_hash_value,
       x.child_address,
       x.child_number,
       x.timestamp,
       x.operation,
       x.options,
       x.object_node,
       x.object#,
       x.object_owner,
       x.object_name,
       x.object_alias,
       x.object_type,
       x.optimizer,
       x.id,
       x.parent_id,
       x.depth,
       x.position,
       x.search_columns,
       x.cost,
       x.cardinality,
       x.bytes,
       x.other_tag,
       x.partition_start,
       x.partition_stop,
       x.partition_id,
       x.other,
       x.distribution,
       x.cpu_cost,
       x.io_cost,
       x.temp_space,
       x.access_predicates,
       x.filter_predicates,
       x.projection,
       x.time,
       x.qblock_name,
       x.remarks,
       x.other_xml,
       TO_NUMBER(NULL) executions,
       TO_NUMBER(NULL) last_starts,
       TO_NUMBER(NULL) starts,
       TO_NUMBER(NULL) last_output_rows,
       TO_NUMBER(NULL) output_rows,
       TO_NUMBER(NULL) last_cr_buffer_gets,
       TO_NUMBER(NULL) cr_buffer_gets,
       TO_NUMBER(NULL) last_cu_buffer_gets,
       TO_NUMBER(NULL) cu_buffer_gets,
       TO_NUMBER(NULL) last_disk_reads,
       TO_NUMBER(NULL) disk_reads,
       TO_NUMBER(NULL) last_disk_writes,
       TO_NUMBER(NULL) disk_writes,
       TO_NUMBER(NULL) last_elapsed_time,
       TO_NUMBER(NULL) elapsed_time,
       TO_CHAR(NULL) policy,
       TO_NUMBER(NULL) estimated_optimal_size,
       TO_NUMBER(NULL) estimated_onepass_size,
       TO_NUMBER(NULL) last_memory_used,
       TO_CHAR(NULL) last_execution,
       TO_NUMBER(NULL) last_degree,
       TO_NUMBER(NULL) total_executions,
       TO_NUMBER(NULL) optimal_executions,
       TO_NUMBER(NULL) onepass_executions,
       TO_NUMBER(NULL) multipasses_executions,
       TO_NUMBER(NULL) active_time,
       TO_NUMBER(NULL) max_tempseg_size,
       TO_NUMBER(NULL) last_tempseg_size
  FROM &&tool_repository_schema..sqlt$_plan_extension x
 WHERE x.source <> 'GV$SQL_PLAN';

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_gv$act_sess_hist_pl_v AS
SELECT ash.statement_id,
       ash.statid,
       ash.sql_plan_hash_value,
       ash.sql_plan_line_id,
       ash.sql_plan_operation,
       ash.sql_plan_options,
       ash.object_owner,
       ash.object_name,
       ash.current_obj#,
       CASE
         WHEN ash.current_obj# IS NOT NULL THEN
           (SELECT obj.owner||'.'||obj.object_name||NVL2(obj.subobject_name, '.'||obj.subobject_name, NULL)
              FROM &&tool_repository_schema..sqlt$_dba_objects obj
             WHERE obj.statement_id = ash.statement_id
               AND obj.statid = ash.statid
               AND obj.object_id = ash.current_obj#)
       END current_obj_name,
       ash.session_state,
       ash.wait_class,
       ash.event,
       COUNT(*) snaps_count
  FROM (
SELECT /*+ NO_MERGE */
       sh.statement_id,
       sh.statid,
       sh.sql_plan_hash_value,
       sh.sql_plan_line_id,
       sh.sql_plan_operation,
       sh.sql_plan_options,
       CASE
         WHEN sh.wait_class IN ('Application', 'Cluster', 'Concurrency', 'User I/O') THEN
           sh.current_obj#
       END current_obj#,
       sh.session_state,
       sh.wait_class,
       sh.event,
       sp.object_owner,
       sp.object_name
  FROM &&tool_repository_schema..sqlt$_gv$active_session_histor sh,
       &&tool_repository_schema..sqlt$_gv$sql_plan sp
 WHERE sp.statement_id(+) = sh.statement_id
   AND sp.statid(+) = sh.statid
   AND sp.inst_id(+) = sh.inst_id
   AND sp.sql_id(+) = sh.sql_id
   AND sp.child_number(+) = sh.sql_child_number
   AND sp.plan_hash_value(+) = sh.sql_plan_hash_value
   AND sp.id(+) = sh.sql_plan_line_id ) ash
 GROUP BY
       ash.statement_id,
       ash.statid,
       ash.sql_plan_hash_value,
       ash.sql_plan_line_id,
       ash.sql_plan_operation,
       ash.sql_plan_options,
       ash.object_owner,
       ash.object_name,
       ash.current_obj#,
       ash.session_state,
       ash.wait_class,
       ash.event;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_gv$act_sess_hist_p_v AS
SELECT statement_id,
       statid,
       sql_plan_hash_value,
       session_state,
       wait_class,
       event,
       SUM(snaps_count) snaps_count
  FROM &&tool_administer_schema..sqlt$_gv$act_sess_hist_pl_v
 GROUP BY
       statement_id,
       statid,
       sql_plan_hash_value,
       session_state,
       wait_class,
       event;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_act_sess_hist_pl_v AS
SELECT ash.statement_id,
       ash.statid,
       ash.sql_plan_hash_value,
       ash.sql_plan_line_id,
       ash.sql_plan_operation,
       ash.sql_plan_options,
       ash.object_owner,
       ash.object_name,
       ash.current_obj#,
       CASE
         WHEN ash.current_obj# IS NOT NULL THEN
           (SELECT obj.owner||'.'||obj.object_name||NVL2(obj.subobject_name, '.'||obj.subobject_name, NULL)
              FROM &&tool_repository_schema..sqlt$_dba_hist_seg_stat_obj obj
             WHERE obj.statement_id = ash.statement_id
               AND obj.statid = ash.statid
               AND obj.obj# = ash.current_obj#
               AND ROWNUM = 1)
       END current_obj_name,
       ash.session_state,
       ash.wait_class,
       ash.event,
       COUNT(*) snaps_count
  FROM (
SELECT /*+ NO_MERGE */
       sh.statement_id,
       sh.statid,
       sh.sql_plan_hash_value,
       sh.sql_plan_line_id,
       sh.sql_plan_operation,
       sh.sql_plan_options,
       CASE
         WHEN sh.wait_class IN ('Application', 'Cluster', 'Concurrency', 'User I/O') THEN
           sh.current_obj#
       END current_obj#,
       sh.session_state,
       sh.wait_class,
       sh.event,
       sp.object_owner,
       sp.object_name
  FROM &&tool_repository_schema..sqlt$_dba_hist_active_sess_his sh,
       &&tool_repository_schema..sqlt$_dba_hist_sql_plan sp
 WHERE sp.statement_id(+) = sh.statement_id
   AND sp.statid(+) = sh.statid
   AND sp.dbid(+) = sh.dbid
   AND sp.sql_id(+) = sh.sql_id
   AND sp.plan_hash_value(+) = sh.sql_plan_hash_value
   AND sp.id(+) = sh.sql_plan_line_id ) ash
 GROUP BY
       ash.statement_id,
       ash.statid,
       ash.sql_plan_hash_value,
       ash.sql_plan_line_id,
       ash.sql_plan_operation,
       ash.sql_plan_options,
       ash.object_owner,
       ash.object_name,
       ash.session_state,
       ash.wait_class,
       ash.current_obj#,
       ash.event;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_act_sess_hist_p_v AS
SELECT statement_id,
       statid,
       sql_plan_hash_value,
       session_state,
       wait_class,
       event,
       SUM(snaps_count) snaps_count
  FROM &&tool_administer_schema..sqlt$_dba_act_sess_hist_pl_v
 GROUP BY
       statement_id,
       statid,
       sql_plan_hash_value,
       session_state,
       wait_class,
       event;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_peeked_binds_v AS
SELECT statement_id,
       statid,
       source, -- GV$SQL_PLAN, DBA_HIST_SQL_PLAN, DBA_SQLTUNE_PLANS, PLAN_EXTENSION
       plan_hash_value,
       plan_timestamp,
       plan_id,
       inst_id,
       child_number,
       child_address,
       position,
       name,
	   CASE
         WHEN NVL(datatype_string, datatype) like 'TIMESTAMP%' and scale is not null
           THEN 'TIMESTAMP('||scale||')'||substr(NVL(datatype_string, datatype), 10)
         ELSE NVL(datatype_string, datatype)
       END as type,
       '"'||NVL(value_string_date, NVL(value_string, value_raw))||'"' value,
       --DECODE(datatype_string, 'NUMBER', TO_NUMBER(value_string)) number_value,
       DECODE(datatype_string, 'NUMBER', DECODE(value_string, 'NULL', TO_NUMBER(NULL), TO_NUMBER(value_string))) number_value,
       DECODE(NVL(value_string_date, NVL(value_string, value_raw)), NULL, 0, 'NULL', 0, 1) non_null
  FROM &&tool_repository_schema..sqlt$_peeked_binds
 WHERE dup_position IS NULL;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_peeked_binds_sum_v AS
SELECT statement_id,
       plan_hash_value,
       name,
       type,
       COUNT(*) values_peeked,
       SUM(non_null) non_null_values,
       COUNT(DISTINCT DECODE(non_null, 1, value)) distinct_values,
       DECODE(MIN(number_value), NULL, MIN(DECODE(non_null, 1, value)), '"'||MIN(number_value)||'"') minimum_value,
       DECODE(MAX(number_value), NULL, MAX(DECODE(non_null, 1, value)), '"'||MAX(number_value)||'"') maximum_value
  FROM &&tool_administer_schema..sqlt$_peeked_binds_v
 GROUP BY
       statement_id,
       plan_hash_value,
       name,
       type;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_captured_binds_v AS
SELECT statement_id,
       statid,
       'GV$SQL_PLAN' source,
       plan_hash_value,
       last_captured,
       inst_id,
       child_number,
       child_address,
       position,
       name,
       CASE
         WHEN datatype_string like 'TIMESTAMP%' and scale is not null
           THEN 'TIMESTAMP('||scale||')'||substr(datatype_string, 10)
         ELSE datatype_string
       END as type,
       '"'||NVL(value_string_date, value_string)||'"' value,
       --DECODE(datatype_string, 'NUMBER', TO_NUMBER(value_string)) number_value,
       DECODE(datatype_string, 'NUMBER', DECODE(value_string, 'NULL', TO_NUMBER(NULL), TO_NUMBER(value_string))) number_value,
       DECODE(NVL(value_string_date, value_string), NULL, 0, 'NULL', 0, 1) non_null
  FROM &&tool_repository_schema..sqlt$_gv$sql_bind_capture
 WHERE plan_hash_value IS NOT NULL
   AND dup_position IS NULL
   AND last_captured IS NOT NULL
 UNION
SELECT statement_id,
       statid,
       'DBA_HIST_SQL_PLAN' source,
       plan_hash_value,
       last_captured,
       -1 instance_number,
       -1 child_number,
       '-666' child_address,
       position,
       name,
       CASE
         WHEN datatype_string like 'TIMESTAMP%' and scale is not null
           THEN 'TIMESTAMP('||scale||')'||substr(datatype_string, 10)
         ELSE datatype_string
       END as type,
       '"'||NVL(value_string_date, value_string)||'"' value,
       --DECODE(datatype_string, 'NUMBER', TO_NUMBER(value_string)) number_value,
       DECODE(datatype_string, 'NUMBER', DECODE(value_string, 'NULL', TO_NUMBER(NULL), TO_NUMBER(value_string))) number_value,
       DECODE(NVL(value_string_date, value_string), NULL, 0, 'NULL', 0, 1) non_null
  FROM &&tool_repository_schema..sqlt$_dba_hist_sqlbind
 WHERE plan_hash_value IS NOT NULL
   AND dup_position IS NULL
   AND last_captured IS NOT NULL;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_captured_binds_sum_v AS
SELECT statement_id,
       plan_hash_value,
       name,
       type,
       COUNT(*) values_captured,
       SUM(non_null) non_null_values,
       COUNT(DISTINCT DECODE(non_null, 1, value)) distinct_values,
       DECODE(MIN(number_value), NULL, MIN(DECODE(non_null, 1, value)), '"'||MIN(number_value)||'"') minimum_value,
       DECODE(MAX(number_value), NULL, MAX(DECODE(non_null, 1, value)), '"'||MAX(number_value)||'"') maximum_value
  FROM &&tool_administer_schema..sqlt$_captured_binds_v
 GROUP BY
       statement_id,
       plan_hash_value,
       name,
       type;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_sql_profile_hints_v AS
SELECT /*+ NO_MERGE(v) */ * FROM (
SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
       od.statement_id,
       od.statid,
       od.plan_id id,
       (
       SELECT o.name
         FROM &&tool_repository_schema..sqlt$_sqlobj$ o
        WHERE od.statement_id = o.statement_id
          AND od.signature = o.signature
          AND od.category = o.category
          AND od.obj_type = o.obj_type
          AND od.plan_id = o.plan_id
          AND od.obj_type = o.obj_type ) name,
       od.signature,
       od.category,
       ROWNUM hint#,
       SUBSTR(EXTRACTVALUE(VALUE(d), '/hint'), 1, 4000) hint
  FROM &&tool_repository_schema..sqlt$_sqlobj$data od,
       TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(od.comp_data), '/outline_data/hint'))) d
 WHERE od.obj_type = 1
 UNION ALL
SELECT a.statement_id,
       a.statid,
       TO_NUMBER(NULL) id,
       (
       SELECT p.sp_name
         FROM &&tool_repository_schema..sqlt$_sqlprof$ p
        WHERE a.statement_id = p.statement_id
          AND a.signature = p.signature
          AND a.category = p.category ) name,
       a.signature,
       a.category,
       a.attr# hint#,
       a.attr_val hint
  FROM &&tool_repository_schema..sqlt$_sqlprof$attr a
 UNION ALL
SELECT r.statement_id,
       r.statid,
       r.task_id id,
       t.name,
       TO_NUMBER(NULL) signature,
       t.advisor_name category,
       r.id hint#,
       CASE
       WHEN SYS.DBMS_LOB.GETLENGTH(r.attr5) > 1 THEN SUBSTR(DBMS_LOB.SUBSTR(r.attr5), 1, 4000)
       ELSE r.attr1
       END hint
  FROM &&tool_repository_schema..sqlt$_wri$_adv_rationale r,
       &&tool_repository_schema..sqlt$_wri$_adv_tasks t
 WHERE r.statement_id = t.statement_id
   AND r.task_id = t.id
   AND (DBMS_LOB.GETLENGTH(r.attr5) > 1 OR r.attr1 IS NOT NULL)) v;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_log_v AS
WITH last_line AS (
SELECT MAX(l.time_stamp) time_stamp
  FROM &&tool_repository_schema..sqlt$_log l,
       &&tool_repository_schema..sqlt$_sql_statement s
 WHERE l.statement_id = s.statement_id
   AND s.tool_start_date > SYSDATE - 1
   AND s.tool_end_date IS NULL),
last_statement AS (
SELECT MAX(lo.statement_id) statement_id
  FROM &&tool_repository_schema..sqlt$_log lo,
       last_line
 WHERE lo.time_stamp = last_line.time_stamp)
SELECT TO_CHAR(log.time_stamp, 'HH24:MI:SS') time,
       SUBSTR(line_text, 1, 60) line
  FROM &&tool_repository_schema..sqlt$_log log,
       last_statement
 WHERE NVL(log.line_type, 'L') <> 'S'
   AND log.statement_id = last_statement.statement_id
 ORDER BY
       log.time_stamp;

GRANT SELECT ON &&tool_repository_schema..sqlt$_log TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_repository_schema..sqlt$_sql_statement TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_administer_schema..sqlt$_log_v TO &&role_name.;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_tab_statistics_v AS
SELECT TO_NUMBER(SUBSTR(statid, 2, INSTR(statid, CHR(95)) - 2)) statement_id,
       statid,
       c5 owner,
       c1 table_name,
       c2 partition_name,
       c3 subpartition_name,
       CASE
       WHEN SUBSTR(statid, 1, 1) = 'f' THEN 'FIXED TABLE'
       WHEN c2 IS NULL THEN 'TABLE'
       WHEN c3 IS NULL THEN 'PARTITION'
       ELSE 'SUBPARTITION'
       END object_type,
       n1 num_rows,
       n2 blocks,
       n3 avg_row_len,
       n4 sample_size,
       d1 last_analyzed,
       DECODE(BITAND(flags, 2), 0, 'NO', 'YES') global_stats,
       DECODE(BITAND(flags, 1), 0, 'NO', 'YES') user_stats
  FROM &&tool_repository_schema..sqlt$_stattab
 WHERE type = 'T'
   AND SUBSTR(statid, 1, 1) IN ('s', 'f');

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_ind_statistics_v AS
SELECT TO_NUMBER(SUBSTR(s.statid, 2, INSTR(s.statid, CHR(95)) - 2)) statement_id,
       s.statid,
       --&&tool_administer_schema..sqlt$a.get_index_column_names(TO_NUMBER(SUBSTR(s.statid, 2, INSTR(s.statid, CHR(95)) - 2)), c5, c1, 'YES', ', ', 'YES', 'YES') compare_key,
       i.index_column_names compare_key,
       s.c5 owner,
       s.c1 index_name,
       s.c2 partition_name,
       s.c3 subpartition_name,
       CASE
       WHEN s.c2 IS NULL THEN 'INDEX'
       WHEN s.c3 IS NULL THEN 'PARTITION'
       ELSE 'SUBPARTITION'
       END object_type,
       s.n7 blevel,
       s.n2 leaf_blocks,
       s.n3 distinct_keys,
       s.n4 avg_leaf_blocks_per_key,
       s.n5 avg_data_blocks_per_key,
       s.n6 clustering_factor,
       s.n1 num_rows,
       s.n8 sample_size,
       s.d1 last_analyzed,
       DECODE(BITAND(s.flags, 2), 0, 'NO', 'YES') global_stats,
       DECODE(BITAND(s.flags, 1), 0, 'NO', 'YES') user_stats
  FROM &&tool_repository_schema..sqlt$_stattab s,
       &&tool_repository_schema..sqlt$_dba_indexes i
 WHERE s.type = 'I'
   AND SUBSTR(s.statid, 1, 1) = 's'
   AND i.statement_id = TO_NUMBER(SUBSTR(s.statid, 2, INSTR(s.statid, CHR(95)) - 2))
   AND i.statid = s.statid
   AND i.owner = s.c5
   AND i.index_name = s.c1;

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_tab_col_statistics_v AS
SELECT TO_NUMBER(SUBSTR(c.statid, 2, INSTR(c.statid, CHR(95)) - 2)) statement_id,
       c.statid,
       c.type,
       c.c5 owner,
       c.c1 table_name,
       c.c2 partition_name,
       c.c3 subpartition_name,
       c.c4 column_name,
       DECODE(SUBSTR(c.statid, 1, 1), 'f', 'FIXED TABLE',
       DECODE(c.c2, NULL, 'TABLE',
       DECODE(c.c3, NULL, 'PARTITION', 'SUBPARTITION'))) object_type,
       c.n1 num_distinct,
       c.r1 low_value, -- needs to be passed trough sqlt$t.cook_raw, but data_type is unknown
       c.r2 high_value, -- needs to be passed trough sqlt$t.cook_raw, but data_type is unknown
       tc.data_type,
       &&tool_administer_schema..sqlt$t.cook_raw(c.r1, tc.data_type) low_value_from_raw,
       &&tool_administer_schema..sqlt$t.cook_raw(c.r2, tc.data_type) high_value_from_raw,
       c.n6 internal_low_value, -- First Endpoint_Value (needs to be passed trough sqlt$s.get_external_value)
       c.n7 internal_high_value, -- Last Endpoint_Value (needs to be passed trough sqlt$s.get_external_value)
       &&tool_administer_schema..sqlt$s.get_external_value(c.n6) external_low_value,
       &&tool_administer_schema..sqlt$s.get_external_value(c.n7) external_high_value,
       c.n2 density,
       t.num_rows,
       c.n5 num_nulls,
       DECODE(c.n9, 1, 'YES', 'NO') histogram,
       COUNT(*) endpoints_count,
       c.d1 last_analyzed,
       c.n4 sample_size,
       DECODE(BITAND(c.flags, 2), 0, 'NO', 'YES') global_stats,
       DECODE(BITAND(c.flags, 1), 0, 'NO', 'YES') user_stats,
       c.n8 avg_col_len,
	   tc.virtual_column,
	   DBMS_LOB.SUBSTR(tc.data_default,4000,1) data_default
  FROM &&tool_repository_schema..sqlt$_stattab c,
       &&tool_administer_schema..sqlt$_dba_tab_statistics_v t,
       sqlt$_dba_tab_cols tc
 WHERE c.type IN ('C', 'E')
   AND SUBSTR(c.statid, 1, 1) IN ('s', 'f')
   AND c.statid = t.statid
   AND c.c5 = t.owner
   AND c.c1 = t.table_name
   AND NVL(c.c2, '-666') = NVL(t.partition_name, '-666')
   AND NVL(c.c3, '-666') = NVL(t.subpartition_name, '-666')
   AND DECODE(SUBSTR(c.statid, 1, 1), 'f', 'FIXED TABLE',
       DECODE(c.c2, NULL, 'TABLE',
       DECODE(c.c3, NULL, 'PARTITION', 'SUBPARTITION'))) = t.object_type
   AND c.statid = tc.statid(+)
   AND c.c5 = tc.owner(+)
   AND c.c1 = tc.table_name(+)
   AND c.c4 = tc.column_name(+)
 GROUP BY
       c.statid,
       c.type,
       c.c5,
       c.c1,
       c.c2,
       c.c3,
       c.c4,
       c.n1,
       c.r1,
       c.r2,
       c.n6,
       c.n7,
       c.n2,
       t.num_rows,
       c.n5,
       c.n9,
       c.d1,
       c.n4,
       c.flags,
       c.n8,
       tc.data_type,
	   tc.virtual_column,
	   DBMS_LOB.SUBSTR(tc.data_default,4000,1);

/*------------------------------------------------------------------*/

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_tab_histograms_v AS
SELECT TO_NUMBER(SUBSTR(statid, 2, 5)) statement_id,
       statid,
       c5 owner,
       c1 table_name,
       c2 partition_name,
       c3 subpartition_name,
       c4 column_name,
       CASE
       WHEN SUBSTR(statid, 1, 1) = 'f' THEN 'FIXED TABLE'
       WHEN c2 IS NULL THEN 'TABLE'
       WHEN c3 IS NULL THEN 'PARTITION'
       ELSE 'SUBPARTITION'
       END object_type,
       n10 endpoint_number,
       n11 endpoint_value,
       ch1 endpoint_actual_value
  FROM &&tool_repository_schema..sqlt$_stattab
 WHERE type = 'C'
   AND n9 = 1
   AND SUBSTR(statid, 1, 1) IN ('s', 'f');

/*------------------------------------------------------------------*/

-- values for resource_manager_plan change like: SCHEDULER[0x3108]:DEFAULT_MAINTENANCE_PLAN, SCHEDULER[0x3109]:DEFAULT_MAINTENANCE_PLAN
-- remove double-underscore parameters like: __db_cache_size and __shared_pool_size

CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_hist_parameter_v AS
SELECT p.*,s.end_interval_time
  FROM &&tool_repository_schema..sqlt$_dba_hist_parameter_m p,
       &&tool_repository_schema..sqlt$_dba_hist_snapshot s
 WHERE p.statement_id = s.statement_id
   AND p.snap_id = s.snap_id
   AND p.dbid = s.dbid
   AND p.instance_number = s.instance_number
   AND p.parameter_name NOT IN (
       '_shared_pool_reserved_pct',
       'archive_lag_target',
       'audit_trail',
       'cluster_database_instances',
       'control_file_record_keep_time',
       'db_cache_size',
       'db_keep_cache_size',
       'db_recovery_file_dest_size',
       'db_writer_processes',
       'job_queue_processes',
       'log_archive_dest_state_2',
       'log_archive_format',
       'log_archive_max_processes',
       'log_buffer',
       'memory_max_target',
       'memory_target',
       'parallel_server_instances',
       'processes',
       'resource_manager_cpu_allocation',
       'resource_manager_plan',
       'service_names',
       'sessions',
       'sga_max_size',
       'sga_target',
       'shadow_core_dump',
       'shared_pool_reserved_size',
       'shared_pool_size',
       'streams_pool_size',
       'transactions'
       )
   AND TRANSLATE(p.parameter_name, '_', '#') NOT LIKE '##%' ;

/*------------------------------------------------------------------*/

BEGIN
  IF :rdbms_version > '11' THEN
    EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_stat_extensions_v AS SELECT * FROM sys.dba_stat_extensions';
  ELSE
    EXECUTE IMMEDIATE 'CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_stat_extensions_v AS SELECT TO_CHAR(NULL) owner, TO_CHAR(NULL) table_name, TO_CHAR(NULL) extension_name, TO_CLOB(NULL) extension FROM dual';
  END IF;
END;
/

/*------------------------------------------------------------------*/

-- 150828 New View sqlt$_dba_spd_v
DECLARE 
 l_sql varchar2(32767);
BEGIN
  IF :rdbms_version > '12' THEN
  l_sql:=q'[ CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_spd_v AS
  SELECT
    d.dir_id directive_id,
    d.type,
    d.enabled,
    (case when d.internal_state = 'HAS_STATS' or d.redundant = 'YES'
           then 'SUPERSEDED'
         when d.internal_state in ('NEW', 'MISSING_STATS', 'PERMANENT')
           then 'USABLE'
         else 'UNKNOWN' end) state, 
    d.auto_drop,
    f.reason,
    d.created,
    d.last_modified,
    d.last_used,
    d.internal_state,	
    d.redundant	
FROM
    sys."_BASE_OPT_DIRECTIVE" d,
    sys."_BASE_OPT_FINDING" f
WHERE d.f_id = f.f_id ]';
  ELSE 
   l_sql:=q'[CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_spd_v AS
   SELECT TO_NUMBER(NULL) DIRECTIVE_ID,TO_CHAR(NULL) TYPE,TO_CHAR(NULL) ENABLED
         ,TO_CHAR(NULL)  STATE ,TO_CHAR(NULL)  AUTO_DROP ,TO_CHAR(NULL) REASON 
		 , TO_TIMESTAMP(NULL) CREATED , TO_TIMESTAMP(NULL) LAST_MODIFIED ,TO_TIMESTAMP(NULL) LAST_USED 
		 , TO_CHAR(NULL) INTERNAL_STATE, TO_CHAR(NULL) REDUNDANT
     FROM DUAL ]';
  END IF;
 EXECUTE IMMEDIATE l_sql;
END;
/

/*------------------------------------------------------------------*/

-- 150828 New View sqlt$_dba_spdo_v
DECLARE 
 l_sql varchar2(32767);
BEGIN
  IF :rdbms_version > '12' THEN
  l_sql:=q'[ CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_spdo_v AS
  SELECT  
  o.directive_id  
 ,o.owner         
 ,o.object_name   
 ,o.subobject_name
 ,o.object_type   
 ,substr(o.notes,instr(o.notes,'<equality_predicates_only>')+26,1) equality_predicates_only
 ,substr(o.notes,instr(o.notes,'<simple_column_predicates_only>')+31,1) simple_column_predicates_only
 ,substr(o.notes,instr(o.notes,'<index_access_by_join_predicates>')+33,1) index_access_by_join_preds
 ,substr(o.notes,instr(o.notes,'<filter_on_joining_object>')+26,1) filter_on_joining_object
from sys.dba_sql_plan_dir_objects o ]';
  ELSE 
   l_sql:=q'[CREATE OR REPLACE VIEW &&tool_administer_schema..sqlt$_dba_spdo_v AS
   SELECT TO_NUMBER(NULL) DIRECTIVE_ID,TO_CHAR(NULL) OWNER,TO_CHAR(NULL) OBJECT_NAME
         ,TO_CHAR(NULL)  SUBOBJECT_NAME ,TO_CHAR(NULL)  OBJECT_TYPE 
		 ,TO_CHAR(NULL) EQUALITY_PREDICATES_ONLY , TO_CHAR(NULL) SIMPLE_COLUMN_PREDICATES_ONLY
		 ,TO_CHAR(NULL) INDEX_ACCESS_BY_JOIN_PREDS , TO_CHAR(NULL) FILTER_ON_JOINING_OBJECT
     FROM DUAL ]';
  END IF;
 EXECUTE IMMEDIATE l_sql;
END;
/
/*------------------------------------------------------------------*/

PRO
PRO SQCVW completed.
