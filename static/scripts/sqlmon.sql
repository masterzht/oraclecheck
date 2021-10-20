col comm format a300
set long 999999999
set linesize 500
set pages 1000
set timing off
set verify off
set feedback off
set time off
prompt Parallel SQL
prompt run 5 secondes
prompt /*+ monitor */
-- description:	display the sql statistics from v$sql_monitor and v$sql_plan_monitor
-- usage:		@sqlmon	
-- author:		chongzi
-- date:		2020-Aug-08

undefine sql_id
var sql_id varchar2(100);
begin
  :sql_id := '&sql_id';
end;
/

SET LONG 1000000
SET LONGCHUNKSIZE 1000000
SET LINESIZE 1000
SET PAGESIZE 0
SET TRIM ON
--SET TRIMSPOOL OFF
SET ECHO OFF
SET FEEDBACK OFF

SPOOL report_sql_monitor_active.html
SELECT DBMS_SQLTUNE.report_sql_monitor(
  sql_id       => :sql_id,
  type         => 'ACTIVE', 
  report_level => 'ALL'
  ) AS report
FROM dual;

!echo -e "\033[32m The file 'report_sql_monitor.html' locations 'current folder' \033[0m"
SET TRIM ON

col comm format a300
set long 999999999
set linesize 500
set pages 1000
col BUFFER_GETS for a12
SET FEEDBACK ON
COL key for 999999999999999
COL "elapsed_time(s)" for 99999
COL "cpu_time(s)" for 99999
SELECT
SQL_EXEC_START,
status, 
sql_exec_id, 
KEY, 
SID, 
round(elapsed_time/1000) as "elapsed_time(ms)",
round(cpu_time/1000) as "cpu_time(ms)",
round(USER_IO_WAIT_TIME/1000) as "USER_IO(ms)",
round(CLUSTER_WAIT_TIME/1000) as "CLUSTER(ms)",
fetches, 
round(buffer_gets/1024/1024)||'M' as buffer_gets, 
disk_reads
FROM v$sql_monitor where sql_id = :sql_id order by SQL_EXEC_START;

select sum(TM_DELTA_TIME)/1000/1000 as "TM_DELTA_TIME(S)",
       SQL_EXEC_ID
from v$active_session_history where sql_id = :sql_id group by SQL_EXEC_ID ORDER BY SQL_EXEC_ID;

SELECT dbms_sqltune.report_sql_monitor(
sql_id => :sql_id,
report_level => 'ALL',
type=>'text'
) comm
FROM dual
/



/**yunqu


select a.*,dbms_sqltune.report_sql_monitor(type=>'HTML', sql_id=>a.sql_id, sql_exec_id=>a.sql_exec_id, report_level=>'ALL') SQLMON
 from (select
 STATUS,SQL_ID,round((LAST_REFRESH_TIME-SQL_EXEC_START)*24*3600) ELAPSED_TIME,
 round(ELAPSED_TIME/1e6) DB_TIME,round(CPU_TIME/1e6) DB_CPU,
 SQL_EXEC_ID,to_char(sql_exec_start,'YYYY-MM-DD HH24:MI:SS') SQL_EXEC_START,
 SQL_PLAN_HASH_VALUE,INST_ID, USERNAME,
 '' as SQL_TEXT
 from Gv$sql_Monitor
 where
 sql_plan_hash_value >0 and
 status like 'DONE%'
 and LAST_REFRESH_TIME>=sysdate - 600/3600/24
 and LAST_REFRESH_TIME<=sysdate
 and sql_text is not null
 order by elapsed_time desc
 ) a where rownum<= 2;
**/
