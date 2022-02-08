/* $Header: 224270.1 tacvw.sql 11.4.5.4 2013/02/04 carlos.sierra $ */

/* ------------------------------------------------------------------------- */
REM
REM System views (extensions)
REM
/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW sys.trca$_x$ktfbue AS
SELECT * FROM sys.x$ktfbue;

GRANT SELECT ON sys.trca$_x$ktfbue TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_x$ktfbue FOR sys.trca$_x$ktfbue;

/* ------------------------------------------------------------------------- */

-- only used by trca$t.refresh_trca$_extents to populate trca$_segments
CREATE OR REPLACE VIEW sys.trca$_dba_segments (
  uid#,
  owner,
  segment_name,
  partition_name,
  segment_type,
  tablespace_id,
  header_block,
  relative_fno,
  managed
) AS
SELECT
  o.owner#                   uid#,
  NVL(u.name, 'SYS')         owner,
  o.name                     segment_name,
  o.subname                  partition_name,
  so.object_type             segment_type,
  s.ts#                      tablespace_id,
  s.block#                   header_block,
  s.file#                    relative_fno,
  bitand(NVL(s.spare1,0), 1) managed
FROM
  sys.seg$        s,
  sys.sys_objects so,
  sys.obj$        o,
  sys.user$       u
WHERE bitand(NVL(s.spare1,0), 65536) = 0
  AND s.file#           = so.header_file
  AND s.block#          = so.header_block
  AND s.ts#             = so.ts_number
  AND s.type#           = so.segment_type_id
  AND s.ts#             = so.ts_number
  AND so.object_id      = o.obj#
  AND so.object_type_id = o.type#
  AND o.owner#          = u.user#(+);

GRANT SELECT ON sys.trca$_dba_segments TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_dba_segments FOR sys.trca$_dba_segments;

/* ------------------------------------------------------------------------- */

-- only used by trca$t.refresh_trca$_extents to populate trca$_segments
CREATE OR REPLACE VIEW sys.trca$_dba_segments_p (
  uid#,
  owner,
  segment_name,
  partition_name,
  segment_type,
  tablespace_id,
  header_block,
  relative_fno,
  managed
) AS
SELECT
  /*+
  FULL(s)  PARALLEL(s 2)
  FULL(so) PARALLEL(so 2)
  FULL(o)  PARALLEL(o 2)
  FULL(u)  PARALLEL(u 2)
  */
  o.owner#                   uid#,
  NVL(u.name, 'SYS')         owner,
  o.name                     segment_name,
  o.subname                  partition_name,
  so.object_type             segment_type,
  s.ts#                      tablespace_id,
  s.block#                   header_block,
  s.file#                    relative_fno,
  bitand(NVL(s.spare1,0), 1) managed
FROM
  sys.seg$        s,
  sys.sys_objects so,
  sys.obj$        o,
  sys.user$       u
WHERE bitand(NVL(s.spare1,0), 65536) = 0
  AND s.file#           = so.header_file
  AND s.block#          = so.header_block
  AND s.ts#             = so.ts_number
  AND s.type#           = so.segment_type_id
  AND s.ts#             = so.ts_number
  AND so.object_id      = o.obj#
  AND so.object_type_id = o.type#
  AND o.owner#          = u.user#(+);

GRANT SELECT ON sys.trca$_dba_segments_p TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_dba_segments_p FOR sys.trca$_dba_segments_p;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW sys.trca$_log_v AS
SELECT LPAD(target, 5, '0') exec_id,
       TO_CHAR(start_time, 'DD-MON-YY HH24:MI:SS') oper_start,
       TO_CHAR(last_update_time, 'DD-MON-YY HH24:MI:SS') oper_last_update,
       opname operation_name,
       target_desc file_or_operation,
       sofar,
       totalwork,
       units,
       context percent
  FROM v$session_longops
 WHERE opname LIKE LOWER(TRIM('&&tool_repository_schema.'))||'%'
 ORDER BY
       target,
       start_time;

GRANT SELECT ON sys.trca$_log_v TO &&role_name.;
GRANT SELECT ON sys.trca$_log_v TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_log_v FOR sys.trca$_log_v;

/* ------------------------------------------------------------------------- */
REM
REM Tool views
REM
/* ------------------------------------------------------------------------- */

-- only used by trca$t.refresh_trca$_extents to populate trca$_extents
CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_dba_extents (
  owner,
  segment_name,
  partition_name,
  segment_type,
  file_id,
  block_id,
  blocks
) AS
SELECT
  ds.owner,
  ds.segment_name,
  ds.partition_name,
  ds.segment_type,
  f.file# file_id,
  e.block_id,
  e.blocks
FROM
  &&tool_repository_schema..trca$_extents_dm e,  -- gtt
  &&tool_repository_schema..trca$_segments   ds, -- gtt
  &&tool_repository_schema..trca$_file$      f   -- gtt
WHERE e.relative_fno  = ds.relative_fno
  AND e.header_block  = ds.header_block
  AND e.tablespace_id = ds.tablespace_id
  AND ds.managed      = 0
  AND e.tablespace_id = f.ts#
  AND e.relfile#      = f.relfile#
UNION ALL
SELECT
  ds.owner,
  ds.segment_name,
  ds.partition_name,
  ds.segment_type,
  f.file# file_id,
  e.block_id,
  e.blocks
FROM
  &&tool_repository_schema..trca$_extents_lm e,  -- gtt
  &&tool_repository_schema..trca$_segments   ds, -- gtt
  &&tool_repository_schema..trca$_file$      f   -- gtt
WHERE e.relative_fno  = ds.relative_fno
  AND e.header_block  = ds.header_block
  AND e.tablespace_id = ds.tablespace_id
  AND ds.managed      = 1
  AND e.tablespace_id = f.ts#
  AND e.relfile#      = f.relfile#;

/* ------------------------------------------------------------------------- */

-- only used by trca$t.refresh_trca$_extents to populate trca$_extents
CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_dba_extents_p (
  owner,
  segment_name,
  partition_name,
  segment_type,
  file_id,
  block_id,
  blocks
) AS
SELECT
  /*+
  FULL(e)  PARALLEL(e 4)
  FULL(ds) PARALLEL(ds 4)
  FULL(f)  PARALLEL(f 4)
  */
  ds.owner,
  ds.segment_name,
  ds.partition_name,
  ds.segment_type,
  f.file# file_id,
  e.block_id,
  e.blocks
FROM
  &&tool_repository_schema..trca$_extents_dm e,  -- gtt
  &&tool_repository_schema..trca$_segments   ds, -- gtt
  &&tool_repository_schema..trca$_file$      f   -- gtt
WHERE e.relative_fno  = ds.relative_fno
  AND e.header_block  = ds.header_block
  AND e.tablespace_id = ds.tablespace_id
  AND ds.managed      = 0
  AND e.tablespace_id = f.ts#
  AND e.relfile#      = f.relfile#
UNION ALL
SELECT
  /*+
  FULL(e)  PARALLEL(e 4)
  FULL(ds) PARALLEL(ds 4)
  FULL(f)  PARALLEL(f 4)
  */
  ds.owner,
  ds.segment_name,
  ds.partition_name,
  ds.segment_type,
  f.file# file_id,
  e.block_id,
  e.blocks
FROM
  &&tool_repository_schema..trca$_extents_lm e,  -- gtt
  &&tool_repository_schema..trca$_segments   ds, -- gtt
  &&tool_repository_schema..trca$_file$      f   -- gtt
WHERE e.relative_fno  = ds.relative_fno
  AND e.header_block  = ds.header_block
  AND e.tablespace_id = ds.tablespace_id
  AND ds.managed      = 1
  AND e.tablespace_id = f.ts#
  AND e.relfile#      = f.relfile#;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_progress_v AS
SELECT id,
       file_name,
       status,
       ROUND((SYSDATE - parse_start) * 24 * 60 * 60) seconds,
       ROUND(parsed_bytes * 100 / file_len, 1)||'%' parsing_progress
  FROM &&tool_repository_schema..trca$_trace
 WHERE parse_end IS NULL
   AND file_len > 0;

GRANT SELECT ON &&tool_repository_schema..trca$_trace TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_administer_schema..trca$_progress_v TO &&role_name.;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_purge_candidate_v AS
SELECT id,
       parse_start,
       file_name
  FROM &&tool_repository_schema..trca$_tool_execution exec
 WHERE EXISTS (
SELECT NULL
  FROM &&tool_repository_schema..trca$_cursor cur
 WHERE cur.tool_execution_id = exec.id );

GRANT SELECT ON &&tool_repository_schema..trca$_tool_execution TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_repository_schema..trca$_cursor TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_administer_schema..trca$_purge_candidate_v TO &&role_name.;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_non_recu_time_v AS
SELECT tool_execution_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       ((e - recu_e) + self_wait_ela_idle) accounted_response,
       (e - recu_e) elapsed,
       (c - recu_c) cpu,
       self_wait_ela_non_idle non_idle_wait,
       ((e - recu_e) - (c - recu_c) - self_wait_ela_non_idle) elapsed_unaccounted_for,
       self_wait_ela_idle idle_wait
  FROM &&tool_repository_schema..trca$_tool_exec_call
 WHERE recursive = 'N';

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_non_recu_time_vf AS
SELECT tool_execution_id,
       call,
       call_type,
       &&tool_administer_schema..trca$g.format_tim3(accounted_response) accounted_response,
       &&tool_administer_schema..trca$g.format_tim3(elapsed) elapsed,
       &&tool_administer_schema..trca$g.format_tim3(cpu) cpu,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(elapsed_unaccounted_for) elapsed_unaccounted_for,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait
  FROM &&tool_administer_schema..trca$_trc_non_recu_time_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_recu_time_v AS
SELECT tool_execution_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       (e  + self_wait_ela_idle) accounted_response,
       e elapsed,
       c cpu,
       self_wait_ela_non_idle non_idle_wait,
       (e - c - self_wait_ela_non_idle) elapsed_unaccounted_for,
       self_wait_ela_idle idle_wait
  FROM &&tool_repository_schema..trca$_tool_exec_call
 WHERE recursive = 'Y';

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_recu_time_vf AS
SELECT tool_execution_id,
       call,
       call_type,
       &&tool_administer_schema..trca$g.format_tim3(accounted_response) accounted_response,
       &&tool_administer_schema..trca$g.format_tim3(elapsed) elapsed,
       &&tool_administer_schema..trca$g.format_tim3(cpu) cpu,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(elapsed_unaccounted_for) elapsed_unaccounted_for,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait
  FROM &&tool_administer_schema..trca$_trc_recu_time_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_overall_time_v AS
SELECT non_recu.tool_execution_id,
       non_recu.call,
       non_recu.call_type,
       CASE WHEN non_recu.call = &&tool_administer_schema..trca$g.call_type_total THEN (tool_exec.end_tim - tool_exec.start_tim) END response,
       (non_recu.accounted_response + recu.accounted_response) accounted_response,
       (non_recu.elapsed + recu.elapsed) elapsed,
       (non_recu.cpu + recu.cpu) cpu,
       (non_recu.non_idle_wait + recu.non_idle_wait) non_idle_wait,
       --(non_recu.elapsed_unaccounted_for + recu.elapsed_unaccounted_for) elapsed_unaccounted_for,
       ((non_recu.elapsed + recu.elapsed) - (non_recu.cpu + recu.cpu) - (non_recu.non_idle_wait + recu.non_idle_wait)) elapsed_unaccounted_for,
       (non_recu.idle_wait + recu.idle_wait) idle_wait,
       CASE WHEN non_recu.call = &&tool_administer_schema..trca$g.call_type_total THEN ((tool_exec.end_tim - tool_exec.start_tim) - (non_recu.elapsed + recu.elapsed) - (non_recu.idle_wait + recu.idle_wait)) END response_unaccounted_for,
       tool_exec.start_tim,
       tool_exec.end_tim,
       ((non_recu.elapsed + recu.elapsed) + (non_recu.idle_wait + recu.idle_wait)) accounted_for_response_time
  FROM &&tool_administer_schema..trca$_trc_non_recu_time_v non_recu,
       &&tool_administer_schema..trca$_trc_recu_time_v     recu,
       &&tool_administer_schema..trca$_tool_execution tool_exec
 WHERE non_recu.tool_execution_id = recu.tool_execution_id
   AND non_recu.call              = recu.call
   AND non_recu.tool_execution_id = tool_exec.id
   AND recu.tool_execution_id     = tool_exec.id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_overall_time_vf AS
SELECT tool_execution_id,
       call,
       call_type,
       &&tool_administer_schema..trca$g.format_tim3(response) response,
       &&tool_administer_schema..trca$g.format_tim3(accounted_response) accounted_response,
       &&tool_administer_schema..trca$g.format_tim3(elapsed) elapsed,
       &&tool_administer_schema..trca$g.format_tim3(cpu) cpu,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(elapsed_unaccounted_for) elapsed_unaccounted_for,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(response_unaccounted_for) response_unaccounted_for,
       &&tool_administer_schema..trca$g.format_tim3(accounted_for_response_time) accounted_for_response_time
  FROM &&tool_administer_schema..trca$_trc_overall_time_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_response_time_summary_v AS
SELECT tool_execution_id,
       elapsed, cpu, non_idle_wait, idle_wait,
       elapsed_unaccounted_for, response_unaccounted_for,
       --(response - cpu - non_idle_wait - idle_wait) total_unaccounted_for,
       (elapsed_unaccounted_for + response_unaccounted_for) total_unaccounted_for,
       accounted_for_response_time,
       response total_response_time,
       start_tim, end_tim,
       &&tool_administer_schema..trca$g.to_timestamp(tool_execution_id, start_tim) start_timestamp,
       &&tool_administer_schema..trca$g.to_timestamp(tool_execution_id, end_tim) end_timestamp,
       CASE WHEN response > 0 THEN ROUND(elapsed * 100 / response, 6) END elapsed_perc,
       CASE WHEN response > 0 THEN ROUND(cpu * 100 / response, 6) END cpu_perc,
       CASE WHEN response > 0 THEN ROUND(non_idle_wait * 100 / response, 6) END non_idle_wait_perc,
       CASE WHEN response > 0 THEN ROUND(idle_wait * 100 / response, 6) END idle_wait_perc,
       CASE WHEN response > 0 THEN ROUND(elapsed_unaccounted_for * 100 / response, 6) END elapsed_unaccounted_for_perc,
       CASE WHEN response > 0 THEN ROUND(response_unaccounted_for * 100 / response, 6) END response_unaccounted_for_perc,
       --CASE WHEN response > 0 THEN ROUND((response - cpu - non_idle_wait - idle_wait) * 100 / response, 6) END total_unaccounted_for_perc,
       CASE WHEN response > 0 THEN ROUND((elapsed_unaccounted_for + response_unaccounted_for) * 100 / response, 6) END total_unaccounted_for_perc,
       CASE WHEN response > 0 THEN ROUND(accounted_for_response_time * 100 / response, 6) END accounted_for_perc,
       CASE WHEN response > 0 THEN 100 END total_response_time_perc
  FROM &&tool_administer_schema..trca$_trc_overall_time_v
 WHERE call = &&tool_administer_schema..trca$g.call_type_total;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_response_time_summary_vf AS
SELECT tool_execution_id,
       start_tim, end_tim,
       &&tool_administer_schema..trca$g.format_timestamp3(start_timestamp) start_timestamp,
       &&tool_administer_schema..trca$g.format_timestamp3(end_timestamp) end_timestamp,
       &&tool_administer_schema..trca$g.format_tim3(cpu) cpu,
       &&tool_administer_schema..trca$g.format_perc1(cpu_perc) cpu_perc,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       &&tool_administer_schema..trca$g.format_perc1(non_idle_wait_perc) non_idle_wait_perc,
       &&tool_administer_schema..trca$g.format_tim3(elapsed_unaccounted_for) elapsed_unaccounted_for,
       &&tool_administer_schema..trca$g.format_perc1(elapsed_unaccounted_for_perc) elapsed_unaccounted_for_perc,
       &&tool_administer_schema..trca$g.format_tim3(elapsed) elapsed,
       &&tool_administer_schema..trca$g.format_perc1(elapsed_perc) elapsed_perc,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait,
       &&tool_administer_schema..trca$g.format_perc1(idle_wait_perc) idle_wait_perc,
       &&tool_administer_schema..trca$g.format_tim3(response_unaccounted_for) response_unaccounted_for,
       &&tool_administer_schema..trca$g.format_perc1(response_unaccounted_for_perc) response_unaccounted_for_perc,
       &&tool_administer_schema..trca$g.format_tim3(total_unaccounted_for) total_unaccounted_for,
       &&tool_administer_schema..trca$g.format_perc1(total_unaccounted_for_perc) total_unaccounted_for_perc,
       &&tool_administer_schema..trca$g.format_tim3(accounted_for_response_time) accounted_for_response_time,
       &&tool_administer_schema..trca$g.format_perc1(accounted_for_perc) accounted_for_perc,
       &&tool_administer_schema..trca$g.format_tim3(total_response_time) total_response_time,
       &&tool_administer_schema..trca$g.format_perc1(total_response_time_perc) total_response_time_perc
  FROM &&tool_administer_schema..trca$_response_time_summary_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_non_recu_total_v AS
SELECT tool_execution_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       call_count,
       (p - recu_p) p_disk_os,
       (cr - recu_cr) cr_query_consistent,
       (cu - recu_cu) cu_current,
       r r_rows,
       mis mis_library_cache_misses,
       self_wait_count_non_idle wait_count_non_idle,
       self_wait_count_idle wait_count_idle
  FROM &&tool_repository_schema..trca$_tool_exec_call
 WHERE recursive = 'N';

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_recu_total_v AS
SELECT tool_execution_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       call_count,
       p p_disk_os,
       cr cr_query_consistent,
       cu cu_current,
       r r_rows,
       mis mis_library_cache_misses,
       self_wait_count_non_idle wait_count_non_idle,
       self_wait_count_idle wait_count_idle
  FROM &&tool_repository_schema..trca$_tool_exec_call
 WHERE recursive = 'Y';

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_overall_total_v AS
SELECT nr_call.tool_execution_id tool_execution_id,
       nr_call.call,
       &&tool_administer_schema..trca$g.call_type(nr_call.call) call_type,
       (nr_call.call_count + r_call.call_count) call_count,
       nr_call.p p_disk_os,
       nr_call.cr cr_query_consistent,
       nr_call.cu cu_current,
       (nr_call.r + r_call.r) r_rows,
       (nr_call.mis + r_call.mis) mis_library_cache_misses,
       (nr_call.self_wait_count_non_idle + r_call.self_wait_count_non_idle) wait_count_non_idle,
       (nr_call.self_wait_count_idle + r_call.self_wait_count_idle) wait_count_idle
  FROM &&tool_repository_schema..trca$_tool_exec_call nr_call,
       &&tool_repository_schema..trca$_tool_exec_call r_call
 WHERE nr_call.recursive         = 'N'
   AND r_call.recursive          = 'Y'
   AND nr_call.tool_execution_id = r_call.tool_execution_id
   AND nr_call.call              = r_call.call;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_overall_wait_v AS
SELECT wait.tool_execution_id,
       'D' row_type,
       event.name event_name,
       event.wait_class,
       event.idle,
       SUM(wait.ela) wait,
       SUM(CASE WHEN event.idle = 'N' THEN wait.ela END) non_idle_wait,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.ela END) idle_wait,
       SUM(wait.wait_count) wait_count,
       SUM(CASE WHEN event.idle = 'N' THEN wait.wait_count END) wait_count_non_idle,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.wait_count END) wait_count_idle,
       CASE WHEN SUM(wait.ela) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(wait.ela)/SUM(wait_count)) END avg_wait,
       MAX(max_ela) max_wait,
       SUM(blocks) blocks,
       CASE WHEN SUM(blocks) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(blocks)/SUM(wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_tool_wait       wait,
       &&tool_repository_schema..trca$_wait_event_name event
 WHERE wait.tool_execution_id = event.tool_execution_id
   AND wait.event#            = event.event#
 GROUP BY
       wait.tool_execution_id,
       event.name,
       event.wait_class,
       event.idle
 UNION ALL
SELECT wait.tool_execution_id,
       'T' row_type,
       'Total' event_name,
       NULL wait_class,
       NULL idle,
       SUM(wait.ela) wait,
       SUM(CASE WHEN event.idle = 'N' THEN wait.ela END) non_idle_wait,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.ela END) idle_wait,
       SUM(wait.wait_count) wait_count,
       SUM(CASE WHEN event.idle = 'N' THEN wait.wait_count END) wait_count_non_idle,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.wait_count END) wait_count_idle,
       CASE WHEN SUM(wait.ela) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(wait.ela)/SUM(wait_count)) END avg_wait,
       MAX(max_ela) max_wait,
       SUM(blocks) blocks,
       CASE WHEN SUM(blocks) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(blocks)/SUM(wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_tool_wait       wait,
       &&tool_repository_schema..trca$_wait_event_name event
 WHERE wait.tool_execution_id = event.tool_execution_id
   AND wait.event#            = event.event#
 GROUP BY
       wait.tool_execution_id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_overall_wait_vf AS
SELECT tool_execution_id,
       row_type,
       wait,
       wait_count,
       event_name,
       wait_class,
       idle,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       wait_count_non_idle,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait,
       wait_count_idle,
       CASE WHEN row_type = 'D' THEN &&tool_administer_schema..trca$g.format_tim6(avg_wait) END avg_wait,
       CASE WHEN row_type = 'D' THEN &&tool_administer_schema..trca$g.format_tim6(max_wait) END max_wait,
       CASE WHEN row_type = 'D' THEN blocks END blocks,
       CASE WHEN row_type = 'D' THEN ROUND(avg_blocks, 1) END avg_blocks
  FROM &&tool_administer_schema..trca$_trc_overall_wait_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_non_recu_wait_v AS
SELECT wait.tool_execution_id,
       'D' row_type,
       event.name event_name,
       event.wait_class,
       event.idle,
       SUM(wait.ela) wait,
       SUM(CASE WHEN event.idle = 'N' THEN wait.ela END) non_idle_wait,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.ela END) idle_wait,
       SUM(wait.wait_count) wait_count,
       SUM(CASE WHEN event.idle = 'N' THEN wait.wait_count END) wait_count_non_idle,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.wait_count END) wait_count_idle,
       CASE WHEN SUM(wait.ela) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(wait.ela)/SUM(wait_count)) END avg_wait,
       MAX(max_ela) max_wait,
       SUM(blocks) blocks,
       CASE WHEN SUM(blocks) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(blocks)/SUM(wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_tool_wait       wait,
       &&tool_repository_schema..trca$_wait_event_name event
 WHERE wait.dep               = 0
   AND wait.tool_execution_id = event.tool_execution_id
   AND wait.event#            = event.event#
 GROUP BY
       wait.tool_execution_id,
       event.name,
       event.wait_class,
       event.idle
 UNION ALL
SELECT wait.tool_execution_id,
       'T' row_type,
       'Total' event_name,
       NULL wait_class,
       NULL idle,
       SUM(wait.ela) wait,
       SUM(CASE WHEN event.idle = 'N' THEN wait.ela END) non_idle_wait,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.ela END) idle_wait,
       SUM(wait.wait_count) wait_count,
       SUM(CASE WHEN event.idle = 'N' THEN wait.wait_count END) wait_count_non_idle,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.wait_count END) wait_count_idle,
       CASE WHEN SUM(wait.ela) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(wait.ela)/SUM(wait_count)) END avg_wait,
       MAX(max_ela) max_wait,
       SUM(blocks) blocks,
       CASE WHEN SUM(blocks) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(blocks)/SUM(wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_tool_wait       wait,
       &&tool_repository_schema..trca$_wait_event_name event
 WHERE wait.dep               = 0
   AND wait.tool_execution_id = event.tool_execution_id
   AND wait.event#            = event.event#
 GROUP BY
       wait.tool_execution_id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_non_recu_wait_vf AS
SELECT tool_execution_id,
       row_type,
       wait,
       wait_count,
       event_name,
       wait_class,
       idle,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       wait_count_non_idle,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait,
       wait_count_idle,
       CASE WHEN row_type = 'D' THEN &&tool_administer_schema..trca$g.format_tim6(avg_wait) END avg_wait,
       CASE WHEN row_type = 'D' THEN &&tool_administer_schema..trca$g.format_tim6(max_wait) END max_wait,
       CASE WHEN row_type = 'D' THEN blocks END blocks,
       CASE WHEN row_type = 'D' THEN ROUND(avg_blocks, 1) END avg_blocks
  FROM &&tool_administer_schema..trca$_trc_non_recu_wait_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_recu_wait_v AS
SELECT wait.tool_execution_id,
       'D' row_type,
       event.name event_name,
       event.wait_class,
       event.idle,
       SUM(wait.ela) wait,
       SUM(CASE WHEN event.idle = 'N' THEN wait.ela END) non_idle_wait,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.ela END) idle_wait,
       SUM(wait.wait_count) wait_count,
       SUM(CASE WHEN event.idle = 'N' THEN wait.wait_count END) wait_count_non_idle,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.wait_count END) wait_count_idle,
       CASE WHEN SUM(wait.ela) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(wait.ela)/SUM(wait_count)) END avg_wait,
       MAX(max_ela) max_wait,
       SUM(blocks) blocks,
       CASE WHEN SUM(blocks) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(blocks)/SUM(wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_tool_wait       wait,
       &&tool_repository_schema..trca$_wait_event_name event
 WHERE wait.dep               <> 0
   AND wait.tool_execution_id = event.tool_execution_id
   AND wait.event#            = event.event#
 GROUP BY
       wait.tool_execution_id,
       event.name,
       event.wait_class,
       event.idle
 UNION ALL
SELECT wait.tool_execution_id,
       'T' row_type,
       'Total' event_name,
       NULL wait_class,
       NULL idle,
       SUM(wait.ela) wait,
       SUM(CASE WHEN event.idle = 'N' THEN wait.ela END) non_idle_wait,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.ela END) idle_wait,
       SUM(wait.wait_count) wait_count,
       SUM(CASE WHEN event.idle = 'N' THEN wait.wait_count END) wait_count_non_idle,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.wait_count END) wait_count_idle,
       CASE WHEN SUM(wait.ela) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(wait.ela)/SUM(wait_count)) END avg_wait,
       MAX(max_ela) max_wait,
       SUM(blocks) blocks,
       CASE WHEN SUM(blocks) > 0 AND SUM(wait_count) > 0 THEN ROUND(SUM(blocks)/SUM(wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_tool_wait       wait,
       &&tool_repository_schema..trca$_wait_event_name event
 WHERE wait.dep               <> 0
   AND wait.tool_execution_id = event.tool_execution_id
   AND wait.event#            = event.event#
 GROUP BY
       wait.tool_execution_id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_recu_wait_vf AS
SELECT tool_execution_id,
       row_type,
       wait,
       wait_count,
       event_name,
       wait_class,
       idle,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       wait_count_non_idle,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait,
       wait_count_idle,
       CASE WHEN row_type = 'D' THEN &&tool_administer_schema..trca$g.format_tim6(avg_wait) END avg_wait,
       CASE WHEN row_type = 'D' THEN &&tool_administer_schema..trca$g.format_tim6(max_wait) END max_wait,
       CASE WHEN row_type = 'D' THEN blocks END blocks,
       CASE WHEN row_type = 'D' THEN ROUND(avg_blocks, 1) END avg_blocks
  FROM &&tool_administer_schema..trca$_trc_recu_wait_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_v AS
SELECT grp.tool_execution_id,
       grp.id group_id,
       grp.top_sql,
       grp.rank,
       grp.contribution,
       grp.top_sql_et,
       grp.rank_et,
       grp.contribution_et,
       grp.top_sql_ct,
       grp.rank_ct,
       grp.contribution_ct,
       grp.response_time_self,
       grp.response_time_progeny,
       grp.elapsed_time_self,
       grp.elapsed_time_progeny,
       grp.cpu_time_self,
       grp.cpu_time_progeny,
       call_tot.self_wait_ela_non_idle non_idle_wait,
       call_tot.self_wait_ela_idle idle_wait,
       grp.exec_count,
       grp.uid#,
       stm.hv,
       stm.sqlid,
       grp.dep,
       grp.plh,
       grp.include_details,
       &&tool_administer_schema..trca$g.flatten_text(stm.sql_text) sql_text,
       grp.first_cursor_id,
       &&tool_administer_schema..trca$g.to_timestamp(cur.tool_execution_id, cur.tim) first_cursor_timestamp
  FROM &&tool_repository_schema..trca$_group      grp,
       &&tool_repository_schema..trca$_statement  stm,
       &&tool_repository_schema..trca$_group_call call_tot,
       &&tool_repository_schema..trca$_cursor     cur
 WHERE grp.statement_id      = stm.id
   AND grp.tool_execution_id = call_tot.tool_execution_id
   AND grp.id                = call_tot.group_id
   AND call_tot.call         = &&tool_administer_schema..trca$g.call_type_total
   AND grp.first_cursor_id   = cur.id
   AND grp.tool_execution_id = cur.tool_execution_id;

GRANT SELECT ON &&tool_repository_schema..trca$_group TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_repository_schema..trca$_statement TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_repository_schema..trca$_group_call TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_repository_schema..trca$_cursor TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_administer_schema..trca$_sql_v TO &&role_name.;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_vf AS
SELECT tool_execution_id,
       group_id,
       top_sql,
       rank,
       &&tool_administer_schema..trca$g.format_perc1(100 * contribution) contribution,
       top_sql_et,
       rank_et,
       &&tool_administer_schema..trca$g.format_perc1(100 * contribution_et) contribution_et,
       top_sql_ct,
       rank_ct,
       &&tool_administer_schema..trca$g.format_perc1(100 * contribution_ct) contribution_ct,
       &&tool_administer_schema..trca$g.format_tim3(response_time_self) response_time_self,
       &&tool_administer_schema..trca$g.format_tim3(response_time_progeny) response_time_progeny,
       &&tool_administer_schema..trca$g.format_tim3(elapsed_time_self) elapsed_time_self,
       &&tool_administer_schema..trca$g.format_tim3(elapsed_time_progeny) elapsed_time_progeny,
       &&tool_administer_schema..trca$g.format_tim3(cpu_time_self) cpu_time_self,
       &&tool_administer_schema..trca$g.format_tim3(cpu_time_progeny) cpu_time_progeny,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait,
       exec_count,
       uid#,
       hv,
       sqlid,
       dep,
       plh,
       include_details,
       SUBSTR(sql_text, 1, 100) sql_text,
       sql_text sql_text_1000,
       first_cursor_id,
       &&tool_administer_schema..trca$g.format_timestamp3h(first_cursor_timestamp) first_cursor_timestamp
  FROM &&tool_administer_schema..trca$_sql_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_genealogy_v AS
SELECT gen.tool_execution_id,
       gen.root_group_id,
       gen.id,
       gen.group_id,
       gen.parent_group_id,
       gen.response_time_self,
       gen.response_time_progeny,
       gen.first_exec_id,
       gen.exec_count,
       gen.dep,
       ROUND(gen.response_time_self / tool_exec.accounted_for_response_time, 6) contribution,
       grp.uid#,
       stm.hv,
       stm.sqlid,
       grp.plh,
       &&tool_administer_schema..trca$g.flatten_text(stm.sql_text) sql_text,
       grp.top_sql,
       grp.top_sql_et,
       grp.top_sql_ct,
       grp.include_details
  FROM &&tool_repository_schema..trca$_genealogy      gen,
       &&tool_repository_schema..trca$_tool_execution tool_exec,
       &&tool_repository_schema..trca$_group          grp,
       &&tool_repository_schema..trca$_statement      stm
 WHERE gen.tool_execution_id = tool_exec.id
   AND gen.group_id          = grp.id
   AND gen.tool_execution_id = grp.tool_execution_id
   AND grp.statement_id      = stm.id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_genealogy_vf AS
SELECT tool_execution_id,
       root_group_id,
       id,
       group_id,
       parent_group_id,
       &&tool_administer_schema..trca$g.format_tim3(response_time_self) response_time_self,
       &&tool_administer_schema..trca$g.format_tim3(response_time_progeny) response_time_progeny,
       first_exec_id,
       exec_count,
       dep,
       plh,
       &&tool_administer_schema..trca$g.format_perc1(100 * contribution) contribution,
       uid#,
       hv,
       sqlid,
       CASE WHEN dep > 0 THEN LPAD(' ', dep * 2, '....+') END sql_text_prefix,
       SUBSTR(sql_text, 1, 100) sql_text,
       sql_text sql_text_1000,
       top_sql,
       top_sql_et,
       top_sql_ct,
       include_details
  FROM &&tool_administer_schema..trca$_sql_genealogy_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_non_recursive_v AS
SELECT exe.id exec_id,
       exe.group_id,
       exe.tool_execution_id,
       exe.start_tim,
       exe.end_tim,
       &&tool_administer_schema..trca$g.to_timestamp(exe.tool_execution_id, exe.start_tim) start_timestamp,
       &&tool_administer_schema..trca$g.to_timestamp(exe.tool_execution_id, exe.end_tim) end_timestamp,
       (exe.end_tim - exe.start_tim) response_time_total,
       exe.response_time_self,
       exe.response_time_progeny,
       ROUND(exe.response_time_self / tool_exec.accounted_for_response_time, 6) contribution,
       grp.uid#,
       stm.hv,
       stm.sqlid,
       exe.plh,
       &&tool_administer_schema..trca$g.flatten_text(stm.sql_text) sql_text,
       grp.top_sql,
       grp.top_sql_et,
       grp.top_sql_ct,
       grp.include_details
  FROM &&tool_repository_schema..trca$_exec           exe,
       &&tool_repository_schema..trca$_tool_execution tool_exec,
       &&tool_repository_schema..trca$_group          grp,
       &&tool_repository_schema..trca$_statement      stm
 WHERE exe.dep               = 0
   AND exe.tool_execution_id = tool_exec.id
   AND exe.group_id          = grp.id
   AND exe.tool_execution_id = grp.tool_execution_id
   AND grp.statement_id      = stm.id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_non_recursive_vf AS
SELECT exec_id,
       group_id,
       tool_execution_id,
       start_tim, end_tim,
       &&tool_administer_schema..trca$g.format_timestamp3m(start_timestamp) start_timestamp,
       &&tool_administer_schema..trca$g.format_timestamp3m(end_timestamp) end_timestamp,
       &&tool_administer_schema..trca$g.format_tim3(response_time_total) response_time_total,
       &&tool_administer_schema..trca$g.format_tim3(response_time_self) response_time_self,
       &&tool_administer_schema..trca$g.format_tim3(response_time_progeny) response_time_progeny,
       &&tool_administer_schema..trca$g.format_perc1(100 * contribution) contribution,
       uid#,
       hv,
       sqlid,
       plh,
       SUBSTR(sql_text, 1, 100) sql_text,
       sql_text sql_text_1000,
       top_sql,
       top_sql_et,
       top_sql_ct,
       include_details
  FROM &&tool_administer_schema..trca$_non_recursive_v
 WHERE ROUND(response_time_total/TO_NUMBER(&&tool_administer_schema..trca$g.get_param('time_granularity')), 3) >=
       TO_NUMBER(&&tool_administer_schema..trca$g.get_param('response_time_th'));

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_self_time_v AS
SELECT tool_execution_id,
       group_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       ((e - recu_e) + self_wait_ela_idle) accounted_response,
       (e - recu_e) elapsed,
       (c - recu_c) cpu,
       self_wait_ela_non_idle non_idle_wait,
       ((e - recu_e) - (c - recu_c) - self_wait_ela_non_idle) elapsed_unaccounted_for,
       self_wait_ela_idle idle_wait
  FROM &&tool_repository_schema..trca$_group_call;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_self_time_vf AS
SELECT tool_execution_id,
       group_id,
       call,
       call_type,
       &&tool_administer_schema..trca$g.format_tim3(accounted_response) accounted_response,
       &&tool_administer_schema..trca$g.format_tim3(elapsed) elapsed,
       &&tool_administer_schema..trca$g.format_tim3(cpu) cpu,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(elapsed_unaccounted_for) elapsed_unaccounted_for,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait
  FROM &&tool_administer_schema..trca$_sql_self_time_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_self_total_v AS
SELECT tool_execution_id,
       group_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       call_count,
       (p - recu_p) p_disk_os,
       (cr - recu_cr) cr_query_consistent,
       (cu - recu_cu) cu_current,
       r r_rows,
       mis mis_library_cache_misses,
       self_wait_count_non_idle wait_count_non_idle,
       self_wait_count_idle wait_count_idle
  FROM &&tool_repository_schema..trca$_group_call;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_self_wait_v AS
SELECT wait.tool_execution_id,
       wait.group_id,
       'D' row_type,
       event.name event_name,
       event.wait_class,
       event.idle,
       SUM(wait.ela) wait,
       SUM(CASE WHEN event.idle = 'N' THEN wait.ela END) non_idle_wait,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.ela END) idle_wait,
       SUM(wait.wait_count) wait_count,
       SUM(CASE WHEN event.idle = 'N' THEN wait.wait_count END) wait_count_non_idle,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.wait_count END) wait_count_idle,
       CASE WHEN SUM(wait.ela) > 0 AND SUM(wait.wait_count) > 0 THEN ROUND(SUM(wait.ela)/SUM(wait.wait_count)) END avg_wait,
       MAX(wait.max_ela) max_wait,
       SUM(wait.blocks) blocks,
       CASE WHEN SUM(wait.blocks) > 0 AND SUM(wait.wait_count) > 0 THEN ROUND(SUM(wait.blocks)/SUM(wait.wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_group_wait      wait,
       &&tool_repository_schema..trca$_wait_event_name event
 WHERE wait.tool_execution_id = event.tool_execution_id
   AND wait.event#            = event.event#
 GROUP BY
       wait.tool_execution_id,
       wait.group_id,
       event.name,
       event.wait_class,
       event.idle
 UNION ALL
SELECT wait.tool_execution_id,
       wait.group_id,
       'T' row_type,
       'Total' event_name,
       NULL wait_class,
       NULL idle,
       SUM(wait.ela) wait,
       SUM(CASE WHEN event.idle = 'N' THEN wait.ela END) non_idle_wait,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.ela END) idle_wait,
       SUM(wait.wait_count) wait_count,
       SUM(CASE WHEN event.idle = 'N' THEN wait.wait_count END) wait_count_non_idle,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.wait_count END) wait_count_idle,
       CASE WHEN SUM(wait.ela) > 0 AND SUM(wait.wait_count) > 0 THEN ROUND(SUM(wait.ela)/SUM(wait.wait_count)) END avg_wait,
       MAX(wait.max_ela) max_wait,
       SUM(wait.blocks) blocks,
       CASE WHEN SUM(wait.blocks) > 0 AND SUM(wait.wait_count) > 0 THEN ROUND(SUM(wait.blocks)/SUM(wait.wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_group_wait      wait,
       &&tool_repository_schema..trca$_wait_event_name event
 WHERE wait.tool_execution_id = event.tool_execution_id
   AND wait.event#            = event.event#
 GROUP BY
       wait.tool_execution_id,
       wait.group_id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_self_wait_vf AS
SELECT tool_execution_id,
       group_id,
       row_type,
       wait,
       wait_count,
       event_name,
       wait_class,
       idle,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       wait_count_non_idle,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait,
       wait_count_idle,
       CASE WHEN row_type = 'D' THEN &&tool_administer_schema..trca$g.format_tim6(avg_wait) END avg_wait,
       CASE WHEN row_type = 'D' THEN &&tool_administer_schema..trca$g.format_tim6(max_wait) END max_wait,
       CASE WHEN row_type = 'D' THEN blocks END blocks,
       CASE WHEN row_type = 'D' THEN ROUND(avg_blocks, 1) END avg_blocks
  FROM &&tool_administer_schema..trca$_sql_self_wait_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_recu_time_v AS
SELECT tool_execution_id,
       group_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       (recu_e  + recu_wait_ela_idle) accounted_response,
       recu_e elapsed,
       recu_c cpu,
       recu_wait_ela_non_idle non_idle_wait,
       (recu_e - recu_c - recu_wait_ela_non_idle) elapsed_unaccounted_for,
       recu_wait_ela_idle idle_wait
  FROM &&tool_repository_schema..trca$_group_call;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_recu_time_vf AS
SELECT tool_execution_id,
       group_id,
       call,
       call_type,
       &&tool_administer_schema..trca$g.format_tim3(accounted_response) accounted_response,
       &&tool_administer_schema..trca$g.format_tim3(elapsed) elapsed,
       &&tool_administer_schema..trca$g.format_tim3(cpu) cpu,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(elapsed_unaccounted_for) elapsed_unaccounted_for,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait
  FROM &&tool_administer_schema..trca$_sql_recu_time_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_recu_total_v AS
SELECT tool_execution_id,
       group_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       recu_call_count call_count,
       recu_p p_disk_os,
       recu_cr cr_query_consistent,
       recu_cu cu_current,
       recu_r r_rows,
       recu_mis mis_library_cache_misses,
       recu_wait_count_non_idle wait_count_non_idle,
       recu_wait_count_idle wait_count_idle
  FROM &&tool_repository_schema..trca$_group_call;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_wait_segment_v AS
SELECT segm.tool_execution_id,
       segm.group_id,
       segm.obj#,
       segm.segment_type,
       segm.owner,
       segm.segment_name,
       segm.partition_name,
       segm.event#,
       event.name event_name,
       segm.ela wait_time,
       segm.wait_count times_waited,
       CASE WHEN segm.wait_count > 0 THEN ROUND(segm.ela/segm.wait_count) END avg_wait_time,
       segm.max_ela max_wait_time,
       segm.blocks,
       CASE WHEN segm.wait_count > 0 THEN ROUND(segm.blocks/segm.wait_count, 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_group_wait_segment segm,
       &&tool_repository_schema..trca$_wait_event_name    event
 WHERE segm.tool_execution_id = event.tool_execution_id
   AND segm.event#            = event.event#
   AND ROUND(segm.ela/TO_NUMBER(&&tool_administer_schema..trca$g.get_param('time_granularity')), 4) >=
       TO_NUMBER(&&tool_administer_schema..trca$g.get_param('wait_time_th'));

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_wait_segment_vf AS
SELECT tool_execution_id,
       group_id,
       obj#,
       segment_type,
       DECODE(owner||segment_name, NULL, NULL, owner||'.'||segment_name)||DECODE(partition_name, NULL, NULL, '.'||partition_name) segment_name,
       event#,
       event_name,
       wait_time wait,
       &&tool_administer_schema..trca$g.format_tim3(wait_time) wait_time,
       times_waited,
       &&tool_administer_schema..trca$g.format_tim6(avg_wait_time) avg_wait_time,
       &&tool_administer_schema..trca$g.format_tim6(max_wait_time) max_wait_time,
       blocks,
       ROUND(avg_blocks, 1) avg_blocks
  FROM &&tool_administer_schema..trca$_sql_wait_segment_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_wait_seg_cons_v AS
SELECT tool_execution_id,
       group_id,
       obj#,
       segment_type,
       owner,
       segment_name,
       partition_name,
       MIN(start_tim) start_tim,
       MAX(end_tim) end_tim,
       &&tool_administer_schema..trca$g.to_timestamp(tool_execution_id, MIN(start_tim)) start_timestamp,
       &&tool_administer_schema..trca$g.to_timestamp(tool_execution_id, MAX(end_tim)) end_timestamp,
       (MAX(end_tim) - MIN(start_tim)) response_time,
       SUM(ela) wait_time,
       SUM(blocks) blocks
  FROM &&tool_repository_schema..trca$_group_wait_segment
 WHERE start_tim > 0
   AND end_tim > 0
HAVING ROUND(SUM(ela)/TO_NUMBER(&&tool_administer_schema..trca$g.get_param('time_granularity')), 4) >=
       TO_NUMBER(&&tool_administer_schema..trca$g.get_param('wait_time_th'))
 GROUP BY
       tool_execution_id,
       group_id,
       obj#,
       segment_type,
       owner,
       segment_name,
       partition_name;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_wait_seg_cons_vf AS
SELECT tool_execution_id,
       group_id,
       obj#,
       segment_type,
       DECODE(owner||segment_name, NULL, NULL, owner||'.'||segment_name)||DECODE(partition_name, NULL, NULL, '.'||partition_name) segment_name,
       start_tim,
       end_tim,
       &&tool_administer_schema..trca$g.format_timestamp3m(start_timestamp) start_timestamp,
       &&tool_administer_schema..trca$g.format_timestamp3m(end_timestamp) end_timestamp,
       response_time response,
       &&tool_administer_schema..trca$g.format_tim3(response_time) response_time,
       wait_time wait,
       &&tool_administer_schema..trca$g.format_tim3(wait_time) wait_time,
       blocks
  FROM &&tool_administer_schema..trca$_sql_wait_seg_cons_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_wait_segment_v AS
SELECT segm.tool_execution_id,
       segm.obj#,
       segm.segment_type,
       segm.owner,
       segm.segment_name,
       segm.partition_name,
       segm.event#,
       event.name event_name,
       SUM(segm.ela) wait_time,
       SUM(segm.wait_count) times_waited,
       CASE WHEN SUM(segm.ela) > 0 AND SUM(segm.wait_count) > 0 THEN ROUND(SUM(segm.ela)/SUM(segm.wait_count)) END avg_wait_time,
       MAX(segm.max_ela) max_wait_time,
       SUM(segm.blocks) blocks,
       CASE WHEN SUM(segm.blocks) > 0 AND SUM(segm.wait_count) > 0 THEN ROUND(SUM(segm.blocks)/SUM(segm.wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_tool_wait_segment segm,
       &&tool_repository_schema..trca$_wait_event_name   event
 WHERE segm.tool_execution_id = event.tool_execution_id
   AND segm.event#            = event.event#
 GROUP BY
       segm.tool_execution_id,
       segm.obj#,
       segm.segment_type,
       segm.owner,
       segm.segment_name,
       segm.partition_name,
       segm.event#,
       event.name
HAVING ROUND(SUM(segm.ela)/TO_NUMBER(&&tool_administer_schema..trca$g.get_param('time_granularity')), 4) >=
       TO_NUMBER(&&tool_administer_schema..trca$g.get_param('wait_time_th'));

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_trc_wait_segment_vf AS
SELECT tool_execution_id,
       obj#,
       segment_type,
       DECODE(owner||segment_name, NULL, NULL, owner||'.'||segment_name)||DECODE(partition_name, NULL, NULL, '.'||partition_name) segment_name,
       event#,
       event_name,
       wait_time wait,
       &&tool_administer_schema..trca$g.format_tim3(wait_time) wait_time,
       times_waited,
       &&tool_administer_schema..trca$g.format_tim6(avg_wait_time) avg_wait_time,
       &&tool_administer_schema..trca$g.format_tim6(max_wait_time) max_wait_time,
       blocks,
       ROUND(avg_blocks, 1) avg_blocks
  FROM &&tool_administer_schema..trca$_trc_wait_segment_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_hot_block_segment_vf AS
SELECT tool_execution_id,
       p1 file#,
       p2 block,
       obj#,
       segment_type,
       DECODE(owner||segment_name, NULL, NULL, owner||'.'||segment_name)||DECODE(partition_name, NULL, NULL, '.'||partition_name) segment_name,
       ela wait,
       &&tool_administer_schema..trca$g.format_tim3(ela) wait_time,
       wait_count times_waited,
       &&tool_administer_schema..trca$g.format_tim6(max_ela) max_wait_time
  FROM &&tool_repository_schema..trca$_hot_block_segment;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_row_source_plan_vf AS
SELECT tool_execution_id,
       group_id,
       trca_plan_hash_value,
       id,
       pid,
       depth,
       cnt,
       pos,
       obj,
       CASE WHEN depth > 0 THEN LPAD(' ', depth, '....+') END op_prefix,
       op,
       cr,
       pr,
       pw,
       &&tool_administer_schema..trca$g.format_tim3(time) time,
       cost,
       siz,
       card,
       sessions
  FROM &&tool_repository_schema..trca$_row_source_plan;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_row_source_plan_sess_vf AS
SELECT r.tool_execution_id,
       r.group_id,
       r.trca_plan_hash_value,
       r.session_id,
       s.sid,
       s.serial#,
       t.file_name,
       r.id,
       r.pid,
       r.depth,
       r.cnt,
       r.pos,
       r.obj,
       CASE WHEN r.depth > 0 THEN LPAD(' ', r.depth, '....+') END op_prefix,
       r.op,
       r.cr,
       r.pr,
       r.pw,
       &&tool_administer_schema..trca$g.format_tim3(r.time) time,
       r.cost,
       r.siz,
       r.card
  FROM &&tool_repository_schema..trca$_row_source_plan_session r,
       &&tool_repository_schema..trca$_session s,
       &&tool_repository_schema..trca$_trace t
 WHERE r.tool_execution_id = s.tool_execution_id
   AND r.session_id = s.id
   AND s.tool_execution_id = t.tool_execution_id
   AND s.trace_id = t.id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_exec_binds_vf AS
SELECT tool_execution_id,
       group_id,
       exec_id,
       bind,
       data_type_code,
       data_type_name,
       actual_value_length,
       CASE WHEN oacdef = 'N' THEN '(No oacdef for this bind)' WHEN value IS NULL THEN '(null)' ELSE value END value
  FROM &&tool_repository_schema..trca$_exec_binds;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_exec_v AS
SELECT exe.tool_execution_id,
       exe.group_id,
       exe.id exec_id,
       exe.dep,
       exe.plh,
       exe.top_exec,
       exe.first_exec,
       exe.last_exec,
       exe.rank,
       exe.grp_contribution,
       exe.trc_contribution,
       exe.response_time_self,
       exe.response_time_progeny,
       (call_tot.e - call_tot.recu_e) elapsed,
       (call_tot.c - call_tot.recu_c) cpu,
       call_tot.self_wait_ela_non_idle non_idle_wait,
       call_tot.self_wait_ela_idle idle_wait,
       (exe.end_tim - exe.start_tim) response_time,
       exe.start_tim,
       exe.end_tim,
       &&tool_administer_schema..trca$g.to_timestamp(exe.tool_execution_id, exe.start_tim) start_timestamp,
       &&tool_administer_schema..trca$g.to_timestamp(exe.tool_execution_id, exe.end_tim) end_timestamp
  FROM &&tool_repository_schema..trca$_exec            exe,
       &&tool_repository_schema..trca$_group_exec_call call_tot
 WHERE exe.tool_execution_id = call_tot.tool_execution_id
   AND exe.group_id          = call_tot.group_id
   AND exe.id                = call_tot.exec_id
   AND call_tot.call         = &&tool_administer_schema..trca$g.call_type_total;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_exec_vf AS
SELECT tool_execution_id,
       group_id,
       exec_id,
       dep,
       plh,
       top_exec,
       first_exec,
       last_exec,
       CASE WHEN first_exec = 'Y' THEN 'First' WHEN last_exec = 'Y' THEN 'Last' END first_last,
       rank,
       &&tool_administer_schema..trca$g.format_perc1(100 * grp_contribution) grp_contribution,
       &&tool_administer_schema..trca$g.format_perc1(100 * trc_contribution) trc_contribution,
       &&tool_administer_schema..trca$g.format_tim3(response_time_self) response_time_self,
       &&tool_administer_schema..trca$g.format_tim3(response_time_progeny) response_time_progeny,
       &&tool_administer_schema..trca$g.format_tim3(elapsed) elapsed,
       &&tool_administer_schema..trca$g.format_tim3(cpu) cpu,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait,
       response_time response,
       &&tool_administer_schema..trca$g.format_tim3(response_time) response_time,
       start_tim,
       end_tim,
       &&tool_administer_schema..trca$g.format_timestamp3m(start_timestamp) start_timestamp,
       &&tool_administer_schema..trca$g.format_timestamp3m(end_timestamp) end_timestamp
  FROM &&tool_administer_schema..trca$_exec_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_call_vf AS
SELECT tool_execution_id,
       id,
       exec_id,
       group_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       &&tool_administer_schema..trca$g.format_tim3(c) cpu,
       &&tool_administer_schema..trca$g.format_tim3(e) elapsed,
       p p_disk_os,
       cr cr_query_consistent,
       cu cu_current,
       mis mis_library_cache_misses,
       r r_rows,
       dep,
       plh,
       &&tool_administer_schema..trca$g.format_timestamp3m(&&tool_administer_schema..trca$g.to_timestamp(tool_execution_id, tim)) call_timestamp,
       dep_id,
       parent_dep_id,
       &&tool_administer_schema..trca$g.format_tim3(recu_c) recu_cpu,
       &&tool_administer_schema..trca$g.format_tim3(recu_e) recu_elapsed,
       recu_p recu_p_disk_os,
       recu_cr recu_cr_query_consistent,
       recu_cu recu_cu_current,
       recu_call_count,
       recu_mis recu_mis_library_cache_misses,
       recu_r recu_r_rows,
       self_wait_count_idle,
       self_wait_count_non_idle,
       &&tool_administer_schema..trca$g.format_tim3(self_wait_ela_idle) self_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(self_wait_ela_non_idle) self_non_idle_wait,
       recu_wait_count_idle,
       recu_wait_count_non_idle,
       &&tool_administer_schema..trca$g.format_tim3(recu_wait_ela_idle) recu_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(recu_wait_ela_non_idle) recu_non_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(((e - recu_e) + self_wait_ela_idle)) accounted_response,
       &&tool_administer_schema..trca$g.format_tim3(((e - recu_e) - (c - recu_c) - self_wait_ela_non_idle)) elapsed_unaccounted_for
  FROM &&tool_repository_schema..trca$_call;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_exec_time_v AS
SELECT tool_execution_id,
       group_id,
       exec_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       ((e - recu_e) + self_wait_ela_idle) accounted_response,
       (e - recu_e) elapsed,
       (c - recu_c) cpu,
       self_wait_ela_non_idle non_idle_wait,
       ((e - recu_e) - (c - recu_c) - self_wait_ela_non_idle) elapsed_unaccounted_for,
       self_wait_ela_idle idle_wait
  FROM &&tool_repository_schema..trca$_group_exec_call;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_exec_time_vf AS
SELECT tool_execution_id,
       group_id,
       exec_id,
       call,
       call_type,
       &&tool_administer_schema..trca$g.format_tim3(accounted_response) accounted_response,
       &&tool_administer_schema..trca$g.format_tim3(elapsed) elapsed,
       &&tool_administer_schema..trca$g.format_tim3(cpu) cpu,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       &&tool_administer_schema..trca$g.format_tim3(elapsed_unaccounted_for) elapsed_unaccounted_for,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait
  FROM &&tool_administer_schema..trca$_sql_exec_time_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_exec_total_v AS
SELECT tool_execution_id,
       group_id,
       exec_id,
       call,
       &&tool_administer_schema..trca$g.call_type(call) call_type,
       call_count,
       (p - recu_p) p_disk_os,
       (cr - recu_cr) cr_query_consistent,
       (cu - recu_cu) cu_current,
       r r_rows,
       mis mis_library_cache_misses,
       self_wait_count_non_idle wait_count_non_idle,
       self_wait_count_idle wait_count_idle
  FROM &&tool_repository_schema..trca$_group_exec_call;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_exec_wait_v AS
SELECT wait.tool_execution_id,
       wait.group_id,
       wait.exec_id,
       'D' row_type,
       event.name event_name,
       event.wait_class,
       event.idle,
       SUM(wait.ela) wait,
       SUM(CASE WHEN event.idle = 'N' THEN wait.ela END) non_idle_wait,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.ela END) idle_wait,
       SUM(wait.wait_count) wait_count,
       SUM(CASE WHEN event.idle = 'N' THEN wait.wait_count END) wait_count_non_idle,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.wait_count END) wait_count_idle,
       CASE WHEN SUM(wait.ela) > 0 AND SUM(wait.wait_count) > 0 THEN ROUND(SUM(wait.ela)/SUM(wait.wait_count)) END avg_wait,
       MAX(wait.max_ela) max_wait,
       SUM(wait.blocks) blocks,
       CASE WHEN SUM(wait.blocks) > 0 AND SUM(wait.wait_count) > 0 THEN ROUND(SUM(wait.blocks)/SUM(wait.wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_group_exec_wait wait,
       &&tool_repository_schema..trca$_wait_event_name event
 WHERE wait.tool_execution_id = event.tool_execution_id
   AND wait.event#            = event.event#
 GROUP BY
       wait.tool_execution_id,
       wait.group_id,
       wait.exec_id,
       event.name,
       event.wait_class,
       event.idle
 UNION ALL
SELECT wait.tool_execution_id,
       wait.group_id,
       wait.exec_id,
       'T' row_type,
       'Total' event_name,
       NULL wait_class,
       NULL idle,
       SUM(wait.ela) wait,
       SUM(CASE WHEN event.idle = 'N' THEN wait.ela END) non_idle_wait,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.ela END) idle_wait,
       SUM(wait.wait_count) wait_count,
       SUM(CASE WHEN event.idle = 'N' THEN wait.wait_count END) wait_count_non_idle,
       SUM(CASE WHEN event.idle = 'Y' THEN wait.wait_count END) wait_count_idle,
       CASE WHEN SUM(wait.ela) > 0 AND SUM(wait.wait_count) > 0 THEN ROUND(SUM(wait.ela)/SUM(wait.wait_count)) END avg_wait,
       MAX(wait.max_ela) max_wait,
       SUM(wait.blocks) blocks,
       CASE WHEN SUM(wait.blocks) > 0 AND SUM(wait.wait_count) > 0 THEN ROUND(SUM(wait.blocks)/SUM(wait.wait_count), 6) END avg_blocks
  FROM &&tool_repository_schema..trca$_group_exec_wait wait,
       &&tool_repository_schema..trca$_wait_event_name event
 WHERE wait.tool_execution_id = event.tool_execution_id
   AND wait.event#            = event.event#
 GROUP BY
       wait.tool_execution_id,
       wait.group_id,
       wait.exec_id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_sql_exec_wait_vf AS
SELECT tool_execution_id,
       group_id,
       exec_id,
       row_type,
       wait,
       wait_count,
       event_name,
       wait_class,
       idle,
       &&tool_administer_schema..trca$g.format_tim3(non_idle_wait) non_idle_wait,
       wait_count_non_idle,
       &&tool_administer_schema..trca$g.format_tim3(idle_wait) idle_wait,
       wait_count_idle,
       CASE WHEN row_type = 'D' THEN &&tool_administer_schema..trca$g.format_tim6(avg_wait) END avg_wait,
       CASE WHEN row_type = 'D' THEN &&tool_administer_schema..trca$g.format_tim6(max_wait) END max_wait,
       CASE WHEN row_type = 'D' THEN blocks END blocks,
       CASE WHEN row_type = 'D' THEN ROUND(avg_blocks, 1) END avg_blocks
  FROM &&tool_administer_schema..trca$_sql_exec_wait_v;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_group_v AS
SELECT grp.id group_id,
       grp.tool_execution_id,
       grp.first_cursor_id,
       grp.uid#,
       grp.lid,
       grp.dep,
       grp.plh,
       grp.err,
       grp.first_exec_id,
       grp.last_exec_id,
       grp.response_time_self,
       grp.response_time_progeny,
       grp.contribution,
       grp.rank,
       grp.top_sql,
       grp.include_details,
       grp.trca_plan_hash_value,
       grp.exec_count,
       grp.statement_id,
       stm.len,
       stm.hv,
       stm.sqlid,
       stm.oct,
       oct.name command_type_name,
       stm.sql_text,
       stm.sql_fulltext
  FROM &&tool_repository_schema..trca$_group         grp,
       &&tool_repository_schema..trca$_statement     stm,
       &&tool_repository_schema..trca$_audit_actions oct
 WHERE grp.statement_id      = stm.id
   AND stm.oct               = oct.action(+);

GRANT SELECT ON &&tool_repository_schema..trca$_group TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_repository_schema..trca$_statement TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_repository_schema..trca$_audit_actions TO &&tool_administer_schema. WITH GRANT OPTION;
GRANT SELECT ON &&tool_administer_schema..trca$_group_v TO &&role_name.;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_group_tables_v AS
SELECT gtb.tool_execution_id,
       gtb.group_id,
       gtb.owner,
       gtb.table_name,
       gtb.in_row_source_plan,
       gtb.in_explain_plan,
       tbl.num_rows,
       tbl.blocks,
       tbl.empty_blocks,
       tbl.avg_space,
       tbl.chain_cnt,
       tbl.avg_row_len,
       tbl.sample_size,
       tbl.last_analyzed,
       tbl.partitioned,
       tbl.temporary,
       tbl.global_stats,
       tbl.actual_rows||tbl.actual_rows_suffix actual_rows
  FROM &&tool_repository_schema..trca$_group_tables gtb,
       &&tool_repository_schema..trca$_tables       tbl
 WHERE gtb.tool_execution_id = tbl.tool_execution_id
   AND gtb.owner             = tbl.owner
   AND gtb.table_name        = tbl.table_name;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_group_indexes_v AS
SELECT gix.tool_execution_id,
       gix.group_id,
       gix.owner,
       gix.index_name,
       gix.table_owner,
       gix.table_name,
       gix.in_row_source_plan,
       gix.in_explain_plan,
       idx.index_type,
       idx.uniqueness,
       idx.blevel,
       idx.leaf_blocks,
       idx.distinct_keys,
       idx.avg_leaf_blocks_per_key,
       idx.avg_data_blocks_per_key,
       idx.clustering_factor,
       idx.num_rows,
       idx.sample_size,
       idx.last_analyzed,
       idx.partitioned,
       idx.temporary,
       idx.global_stats,
       idx.indexed_columns,
       idx.columns_count
  FROM &&tool_repository_schema..trca$_group_indexes gix,
       &&tool_repository_schema..trca$_indexes       idx
 WHERE gix.tool_execution_id = idx.tool_execution_id
   AND gix.owner             = idx.owner
   AND gix.index_name        = idx.index_name
   AND gix.table_owner       = idx.table_owner
   AND gix.table_name        = idx.table_name;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_plan_table_vf AS
SELECT pln.tool_execution_id,
       pln.group_id,
       pln.operation,
       pln.options,
       pln.object_node,
       pln.object_owner,
       pln.object_name,
       pln.operation||
       (CASE WHEN pln.options IS NOT NULL THEN ' '||pln.options END)||
       (CASE WHEN pln.object_name IS NOT NULL THEN ' '||pln.object_name END)||
       (CASE WHEN pln.object_node IS NOT NULL THEN '@'||pln.object_node END)||
       (CASE WHEN pln.partition_start IS NOT NULL THEN ' PARTITION: '||pln.partition_start||' '||pln.partition_stop END)
       op,
       pln.search_columns,
       pln.id,
       pln.parent_id,
       pln.depth,
       CASE WHEN pln.depth > 0 THEN LPAD(' ', pln.depth, '....+') END op_prefix,
       ROUND(pln.cost) cost,
       pln.cardinality,
       pln.bytes,
       pln.other_tag,
       pln.partition_start,
       pln.partition_stop,
       pln.partition_id,
       pln.distribution,
       ROUND(pln.cpu_cost) cpu_cost,
       ROUND(pln.io_cost) io_cost,
       pln.temp_space,
       &&tool_administer_schema..trca$g.flatten_text(pln.access_predicates) access_predicates,
       &&tool_administer_schema..trca$g.flatten_text(pln.filter_predicates) filter_predicates,
       &&tool_administer_schema..trca$g.flatten_text(pln.projection) projection,
       pln.time,
       pln.qblock_name,
       pln.actual_rows,
       CASE
       WHEN pln.operation||pln.object_type LIKE '%INDEX%'
       THEN
         (SELECT idx.indexed_columns
            FROM &&tool_repository_schema..trca$_indexes idx
           WHERE idx.tool_execution_id = pln.tool_execution_id
             AND idx.owner             = pln.object_owner
             AND idx.index_name        = pln.object_name)
       END indexed_columns,
       CASE
       WHEN pln.operation||pln.object_type LIKE '%INDEX%'
       THEN
         (SELECT idx.columns_count
            FROM &&tool_repository_schema..trca$_indexes idx
           WHERE idx.tool_execution_id = pln.tool_execution_id
             AND idx.owner             = pln.object_owner
             AND idx.index_name        = pln.object_name)
       END columns_count
  FROM &&tool_repository_schema..trca$_plan_table pln;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_ind_columns_v AS
SELECT idx.tool_execution_id,
       idx.group_id,
       idx.owner,
       idx.index_name,
       idx.table_owner,
       idx.table_name,
       icl.column_position,
       icl.column_name,
       icl.descend,
       tcl.column_id,
       tbl.num_rows,
       tcl.sample_size,
       tcl.last_analyzed,
       tcl.num_nulls,
       tcl.num_distinct,
       tcl.density,
       tcl.num_buckets
  FROM &&tool_repository_schema..trca$_group_indexes idx,
       &&tool_repository_schema..trca$_ind_columns   icl,
       &&tool_repository_schema..trca$_tab_cols      tcl,
       &&tool_repository_schema..trca$_tables        tbl
 WHERE idx.tool_execution_id = icl.tool_execution_id
   AND idx.owner             = icl.index_owner
   AND idx.index_name        = icl.index_name
   AND idx.table_owner       = icl.table_owner
   AND idx.table_name        = icl.table_name
   AND icl.tool_execution_id = tcl.tool_execution_id
   AND icl.table_owner       = tcl.owner
   AND icl.table_name        = tcl.table_name
   AND icl.column_name       = tcl.column_name
   AND idx.tool_execution_id = tbl.tool_execution_id
   AND idx.table_owner       = tbl.owner
   AND idx.table_name        = tbl.table_name;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_gap_vf AS
SELECT gap.tool_execution_id,
       &&tool_administer_schema..trca$g.format_timestamp3m(gap.gap_timestamp) gap_timestamp,
       CASE
       WHEN (gap.tim_after - gap.ela_after - gap.tim_before) > 0
       THEN &&tool_administer_schema..trca$g.format_tim3(gap.tim_after - gap.ela_after - gap.tim_before)
       END gap_duration,
       gap.id gap_id,
       gap.trace_id,
       trc.file_name,
       gap.tim_before,
       gap.tim_after,
       gap.ela_after,
       gap.wait_call_after,
       gap.call_id_after
  FROM &&tool_repository_schema..trca$_gap gap,
       &&tool_repository_schema..trca$_trace trc
 WHERE gap.tim_before IS NOT NULL
   AND gap.trace_id = trc.id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_gap_call_vf AS
SELECT call.tool_execution_id,
       &&tool_administer_schema..trca$g.format_timestamp3m(gap.gap_timestamp) gap_timestamp,
       call.dep,
       &&tool_administer_schema..trca$g.call_type(call.call) call_type,
       &&tool_administer_schema..trca$g.format_tim3(call.c) cpu,
       &&tool_administer_schema..trca$g.format_tim3(call.e) elapsed,
       &&tool_administer_schema..trca$g.format_timestamp3m(&&tool_administer_schema..trca$g.to_timestamp(call.tool_execution_id, call.tim)) call_timestamp,
       grp.include_details,
       grp.top_sql,
       grp.top_sql_et,
       grp.top_sql_ct,
       stm.hv,
       stm.sqlid,
       --grp.plh,
       &&tool_administer_schema..trca$g.flatten_text(stm.sql_text) sql_text,
       call.call,
       call.gap_id,
       call.call_id,
       call.group_id,
       call.c,
       call.e,
       call.tim,
       call.parent_dep_id
  FROM &&tool_repository_schema..trca$_gap_call  call,
       &&tool_repository_schema..trca$_gap       gap,
       &&tool_repository_schema..trca$_group     grp,
       &&tool_repository_schema..trca$_statement stm
 WHERE call.gap_id            = gap.id
   AND call.tool_execution_id = gap.tool_execution_id
   AND gap.tim_before         IS NOT NULL
   AND call.group_id          = grp.id
   AND call.tool_execution_id = grp.tool_execution_id
   AND grp.statement_id       = stm.id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_session_vf AS
SELECT ses.id session_id,
       ses.tool_execution_id,
       ses.trace_id,
       trc.file_name,
       ses.sid,
       ses.serial#,
       &&tool_administer_schema..trca$g.format_timestamp3m(ses.session_timestamp) session_timestamp,
       ses.session_tim,
       ses.read_only_committed,
       ses.read_only_rollbacked,
       ses.update_committed,
       ses.update_rollbacked
  FROM &&tool_repository_schema..trca$_session ses,
       &&tool_repository_schema..trca$_trace trc
 WHERE ses.trace_id = trc.id;

/* ------------------------------------------------------------------------- */

CREATE OR REPLACE VIEW &&tool_administer_schema..trca$_error_vf AS
SELECT err.tool_execution_id,
       err.group_id,
       'ORA-'||LPAD(err.err, 5, '0') ora_error,
       err.tim,
       &&tool_administer_schema..trca$g.format_timestamp3m(&&tool_administer_schema..trca$g.to_timestamp(err.tool_execution_id, err.tim)) error_timestamp,
       grp.include_details,
       grp.top_sql,
       grp.top_sql_et,
       grp.top_sql_ct,
       stm.hv,
       stm.sqlid,
       --grp.plh,
       &&tool_administer_schema..trca$g.flatten_text(stm.sql_text) sql_text
  FROM &&tool_repository_schema..trca$_error     err,
       &&tool_repository_schema..trca$_group     grp,
       &&tool_repository_schema..trca$_statement stm
 WHERE err.group_id          = grp.id
   AND err.tool_execution_id = grp.tool_execution_id
   AND grp.statement_id      = stm.id;

/* ------------------------------------------------------------------------- */

PRO TACVW completed.
