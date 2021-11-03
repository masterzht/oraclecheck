--------------------------------------------------------------------------------
--
-- File name:   px.sql
-- Purpose:     Report Pararallel Execution SQL globally in a RAC instance
--
--------------------------------------------------------------------------------

SET LINES 999 PAGES 50000 TRIMSPOOL ON TRIMOUT ON TAB OFF 

COL px_qcsid HEAD QC_SID FOR A13
COL px_instances FOR A100

PROMPT Show current Parallel Execution sessions in RAC cluster...

SELECT 
    pxs.qcsid||','||pxs.qcserial# px_qcsid
  , pxs.qcinst_id
  , ses.username
  , ses.sql_id
  , pxs.degree
  , pxs.req_degree
  , COUNT(*) slaves
  , COUNT(DISTINCT pxs.inst_id) inst_cnt
  , MIN(pxs.inst_id) min_inst
  , MAX(pxs.inst_id) max_inst 
  --, LISTAGG ( TO_CHAR(pxs.inst_id) , ' ' ) WITHIN GROUP (ORDER BY pxs.inst_id) px_instances
FROM 
    gv$px_session pxs
  , gv$session    ses
  , gv$px_process p
WHERE
    ses.sid     = pxs.sid
AND ses.serial# = pxs.serial#
AND p.sid     = pxs.sid
AND pxs.inst_id = ses.inst_id
AND ses.inst_id = p.inst_id
--
AND pxs.req_degree IS NOT NULL -- qc
GROUP BY
    pxs.qcsid||','||pxs.qcserial#
  , pxs.qcinst_id
  , ses.username
  , ses.sql_id
  , pxs.degree
  , pxs.req_degree
ORDER BY
    pxs.qcinst_id
  , slaves DESC
/

select a.sid, a.program, b.start_time, b.used_ublk,
       b.xidusn ||'.'|| b.xidslot || '.' || b.xidsqn trans_id
  from v$session a, v$transaction b
 where a.taddr = b.addr
   and a.sid in ( select sid
                    from v$px_session
                   where qcsid = &qcsid )
 order by sid
/
prompt Display Parallel Execution QC and slave sessions for QC &1....

col pxs_degr head "Degree (Req)" for a12
col pxs_username head "USERNAME" for a20

select 
    s.username          pxs_username
  , pxs.qcsid
  , s.sql_id
  , pxs.server_group    dfo_tree
  , pxs.server_set
  , pxs.qcinst_id       qc_inst
  , pxs.server#
  , lpad(to_char(pxs.degree)||' ('||to_char(pxs.req_degree)||')',12,' ') pxs_degr
  , pxs.inst_id         sl_inst
  , pxs.sid             slave_sid
  , p.server_name
  , p.spid
  , CASE WHEN state != 'WAITING' THEN 'WORKING'
         ELSE 'WAITING'
    END AS state
  , CASE WHEN state != 'WAITING' THEN 'On CPU / runqueue'
         ELSE event
    END AS sw_event  
--  , CASE WHEN state != 'WAITING' THEN 'On CPU / runqueue'
--         ELSE CASE
--              WHEN event = 'PX Deq: Execution Msg'    THEN 'Waiting for consumer: next command'
--              WHEN event = 'PX Deq Credit: send blkd' THEN 'Waiting for consumer: to consume more data'
--              WHEN event = 'PX qref latch'            THEN 'Waiting for access to table queue buffer'
--              ELSE null    
--              END 
--    END AS human_readble_event
  , s.blocking_session_status
  , s.blocking_instance
  , s.blocking_session
  , s.seq#
  , s.seconds_in_wait
  , s.p1text
  , s.p1raw
  , s.p2text
  , s.p2raw
  , s.p3text
  , s.p3raw
from 
    gv$px_session pxs 
  , gv$session    s
  , gv$px_process p
where 
    pxs.qcsid in (&1)
--and s.sid     = pxs.qcsid
and s.sid     = pxs.sid
and s.serial# = pxs.serial#
--and s.serial# = pxs.qcserial# -- null
and p.sid     = pxs.sid
and pxs.inst_id = s.inst_id
and s.inst_id = p.inst_id
order by
    pxs.qcsid
  , pxs.server_group
  , pxs.server_set
  , pxs.qcinst_id
  , pxs.server#
/

COL px_qcsid HEAD QC_SID FOR A13

PROMPT Show current Parallel Execution sessions in RAC cluster...

WITH sq AS (
    SELECT 
        pxs.qcsid||','||pxs.qcserial# px_qcsid
      , pxs.qcinst_id
      , ses.username
      , ses.sql_id
      , pxs.degree
      , pxs.req_degree
      , COUNT(*) slaves
      , COUNT(DISTINCT pxs.inst_id) inst_cnt
      , CASE WHEN pxs.inst_id =  1 THEN 1 ELSE NULL END i01
      , CASE WHEN pxs.inst_id =  2 THEN 1 ELSE NULL END i02
      , CASE WHEN pxs.inst_id =  3 THEN 1 ELSE NULL END i03
      , CASE WHEN pxs.inst_id =  4 THEN 1 ELSE NULL END i04
      , CASE WHEN pxs.inst_id =  5 THEN 1 ELSE NULL END i05
      , CASE WHEN pxs.inst_id =  6 THEN 1 ELSE NULL END i06
      , CASE WHEN pxs.inst_id =  7 THEN 1 ELSE NULL END i07
      , CASE WHEN pxs.inst_id =  8 THEN 1 ELSE NULL END i08
      , CASE WHEN pxs.inst_id =  9 THEN 1 ELSE NULL END i09
      , CASE WHEN pxs.inst_id = 10 THEN 1 ELSE NULL END i10
      , CASE WHEN pxs.inst_id = 11 THEN 1 ELSE NULL END i11
      , CASE WHEN pxs.inst_id = 12 THEN 1 ELSE NULL END i12
      , CASE WHEN pxs.inst_id = 13 THEN 1 ELSE NULL END i13
      , CASE WHEN pxs.inst_id = 14 THEN 1 ELSE NULL END i14
      , CASE WHEN pxs.inst_id = 15 THEN 1 ELSE NULL END i15
      , CASE WHEN pxs.inst_id = 16 THEN 1 ELSE NULL END i16 
    --  , LISTAGG ( TO_CHAR(pxs.inst_id) , ' ' ) WITHIN GROUP (ORDER BY pxs.inst_id) instances
    FROM 
        gv$px_session pxs
      , gv$session    ses
      , gv$px_process p
    WHERE
        ses.sid     = pxs.sid
    AND ses.serial# = pxs.serial#
    AND p.sid     = pxs.sid
    AND pxs.inst_id = ses.inst_id
    AND ses.inst_id = p.inst_id
    --
    AND pxs.req_degree IS NOT NULL -- qc
    GROUP BY
        pxs.qcsid||','||pxs.qcserial#
      , pxs.qcinst_id
      , ses.username
      , ses.sql_id
      --, pxs.inst_id 
      , pxs.degree
      , pxs.req_degree
      , CASE WHEN pxs.inst_id =  1 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id =  2 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id =  3 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id =  4 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id =  5 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id =  6 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id =  7 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id =  8 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id =  9 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id = 10 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id = 11 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id = 12 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id = 13 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id = 14 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id = 15 THEN 1 ELSE NULL END 
      , CASE WHEN pxs.inst_id = 16 THEN 1 ELSE NULL END  
)
select * from sq
/

break on dfo_number nodup on tq_id nodup on server_type skip 1 nodup on instance nodup

compute sum label Total of num_rows on server_type

select
        /*dfo_number
      , */tq_id
      , cast(server_type as varchar2(10)) as server_type
      , instance
      , cast(process as varchar2(8)) as process
      , num_rows
      , round(ratio_to_report(num_rows) over (partition by dfo_number, tq_id, server_type) * 100) as "%"
      , cast(rpad('#', round(num_rows * 10 / nullif(max(num_rows) over (partition by dfo_number, tq_id, server_type), 0)), '#') as varchar2(10)) as graph
      , round(bytes / 1024 / 1024) as mb
      , round(bytes / nullif(num_rows, 0)) as "bytes/row"
from
        v$pq_tqstat
order by
        dfo_number
      , tq_id
      , server_type desc
      , instance
      , process
;
select sid,pq_QUEUED,PQ_STATUS,PQ_ACTIVE,dop,pq_servers from v$rsrc_session_info where pq_queued>0;
col server_type for A13
col process for A10

SELECT
    dfo_number, tq_id, server_type, instance, process, num_rows
FROM
    V$PQ_TQSTAT
ORDER BY
    dfo_number DESC, tq_id, server_type desc, instance, process;
