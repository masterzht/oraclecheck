WITH
per_instance AS (
SELECT /*+ MATERIALIZE NO_MERGE DYNAMIC_SAMPLING(4) */
       snap_id,
       instance_number,
       TRUNC(begin_time, 'HH') begin_time_hh,
       maxval,
       ROW_NUMBER () OVER (PARTITION BY dbid, instance_number, group_id, metric_id, TRUNC(begin_time, 'HH') ORDER BY maxval DESC NULLS LAST, begin_time DESC) rn
  FROM dba_hist_sysmetric_summary
 WHERE
   group_id = 2 /* 1 minute intervals */
   AND metric_name = 'Parse Failure Count Per Sec'
)
SELECT /*+ NO_MERGE */
       MIN(snap_id) snap_id,
       TO_CHAR(begin_time_hh, 'YYYY-MM-DD HH24:MI') begin_time,
       TO_CHAR(begin_time_hh + (1/24), 'YYYY-MM-DD HH24:MI') end_time,
       ROUND(SUM(maxval), 1) "Max Value"
  FROM per_instance
 WHERE rn = 1
 having ROUND(SUM(maxval), 1)  > 2
 GROUP BY
       begin_time_hh
 ORDER BY
       begin_time_hh;