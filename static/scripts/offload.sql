set linesize 500
col ksppinm for a35
col ksppstvl for a12
col ksppdesc for a70
select ksppinm,ksppstvl,ksppdesc from x$ksppi x, x$ksppcv y where x.indx = y.indx 
and ksppinm in ('_kcfis_storageidx_diag_mode',
'__db_cache_size',
'_small_table_threshold',
'_kcfis_storageidx_disabled',
'_serial_direct_read',
'_very_large_object_threshold');

prompt display the io save throught out smart scan
prompt IO_CELL_OFFLOAD_ELIGIBLE_GB means saved data GB
prompt IO_INTERCONNECT_GB means returned data GB
undefine sql_id
var sql_id varchar2(200);
begin
   :sql_id :='&sql_id';
end;
/

set linesize 500
col offload for a10
SELECT 
SQL_ID,
CHILD_NUMBER CHILD,
round(IO_CELL_OFFLOAD_ELIGIBLE_BYTES/1024/1024/1024,2) as  IO_CELL_OFFLOAD_ELIGIBLE_GB,
round(IO_INTERCONNECT_BYTES/1024/1024/1024,2) IO_INTERCONNECT_GB,
round(PHYSICAL_READ_BYTES/1024/1024/1024,2) PHYSICAL_READ_GB,
round(PHYSICAL_WRITE_BYTES/1024/1024/1024,2) PHYSICAL_WRITE_GB,
DECODE(IO_CELL_OFFLOAD_ELIGIBLE_BYTES, 0, 'No', 'Yes') OFFLOAD,
round(decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES,0,0,100 * (IO_CELL_OFFLOAD_ELIGIBLE_BYTES - IO_INTERCONNECT_BYTES) / decode(IO_CELL_OFFLOAD_ELIGIBLE_BYTES,0,1,IO_CELL_OFFLOAD_ELIGIBLE_BYTES))) "IO_SAVED_%",
(ELAPSED_TIME / 1000000) / DECODE(NVL(EXECUTIONS, 0), 0, 1, EXECUTIONS) AVG_ETIME
FROM V$SQL S WHERE SQL_ID =:sql_id
ORDER BY 1, 2, 3;

col event for a36
col NAME for a66
col username for a15
select c.username,
b.name,
round(a.value/1024/1024/1024,2) GB,
c.event 
FROM v$sesstat a,v$statname b,v$session c 
WHERE a.STATISTIC# = b.STATISTIC# 
AND c.sql_id = :sql_id
AND a.sid = c.sid
AND b.NAME IN
('cell physical IO bytes saved by storage index',
    'cell physical IO bytes eligible for predicate offload',
    'cell physical IO interconnect bytes',
    'cell physical IO interconnect bytes returned by smart scan');
