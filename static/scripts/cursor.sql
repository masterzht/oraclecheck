select
  'session_cached_cursors'  parameter,
  lpad(value, 5)  value,
  decode(value, 0, '  n/a', to_char(100 * used / value, '990') || '%')  usage
from
  ( select
      max(s.value)  used
    from
      v$statname  n,
      v$sesstat  s
    where
      n.name = 'session cursor cache count' and
      s.statistic# = n.statistic#
  ),
  ( select value from v$parameter where name = 'session_cached_cursors')
union all
select
  'open_cursors',
  lpad(value, 5),
  to_char(100 * used / value,  '990') || '%'
from
  (select max(sum(s.value))  used
    from
      v$statname  n,
      v$sesstat  s
    where
      n.name in ('opened cursors current', 'session cursor cache count') and
      s.statistic# = n.statistic#
    group by s.sid
  ),
  (select value from v$parameter where name = 'open_cursors');


select
  to_char(100 * sess / calls, '999999999990.00') || '%' cursor_cache_hits,
  to_char(100 * (calls - sess - hard) / calls, '999990.00') || '%' soft_parses,
  to_char(100 * hard / calls, '999990.00') || '%' hard_parses
from
  ( select value calls from v$sysstat where name = 'parse count (total)'),
  ( select value hard  from v$sysstat where name = 'parse count (hard)'),
 ( select value sess  from v$sysstat where name = 'session cursor cache hits');

set linesize 400
set pages 50
set long 99999
set timing off
set verify off feedback off
var hash_value varchar2(20)
var sql_id varchar2(20)
var child_number number;

begin
  :sql_id := '&sql_id';
end;
/

col sql_id              new_value sql_id        noprint;
col child_number        new_value child_number  noprint ;

select distinct sql_id, child_number from v$sql_plan where sql_id = :sql_id;

begin
        :sql_id         := '&&sql_id';
        :child_number   := &&child_number;
end;
/

SELECT * FROM table(DBMS_XPLAN.DISPLAY_CURSOR(:sql_id, :child_number,'advanced -projection'));

col sql_id print
col child_number print 



prompt ##########################################################################
prompt Display current sql dba_his_sqlstat Information
prompt Seconds Per execution,such elapsed_time mean elapsed_time(s)/per execution
col sql_id for A15
col time for A22
col java for 9999
col plsql for 9999
col concurr for 9999
col cluster for 9999
col user_io for 9999
col gets for 99999999
col reads for 99999999
col app for 9999
col elapsed for 9999
col rows for 9999
col cpu for 9999
col exes for 99999
col inst# for 99
select  instance_number as inst#,
        (select max(to_char(begin_interval_time,'yyyy-mm-dd hh24:mi:ss')) time from dba_hist_snapshot where snap_id = x.snap_id) snap_time,
        sql_id,
        plan_hash_value plan,
        executions_delta exec_delta,
        trunc(ELAPSED_TIME_DELTA/decode(executions_delta,0,1,executions_delta)/1000000) "elapsed_time",
        trunc(CPU_TIME_DELTA/decode(executions_delta,0,1,executions_delta)/1000000) "cpu_time",
        trunc(rows_processed_delta/decode(executions_delta,0,1,executions_delta)) "rows",
        trunc(buffer_gets_delta/decode(executions_delta,0,1,executions_delta)) "gets",
        trunc(disk_reads_delta/decode(executions_delta,0,1,executions_delta)) "reads"
from
        dba_hist_sqlstat x
where x.sql_id = :sql_id 
order by x.snap_id;

prompt ##########################################################################
prompt Display current sql v$sqlstats Information
prompt Seconds Per execution,such elapsed_time mean elapsed_time(s)/per execution
col sql_id for A15
col time for A22
select  
	sql_id,
	plan_hash_value,
	executions,
	round(ELAPSED_TIME/decode(executions,0,1,executions)/1000000,2) "elapsed_time",
	round(CPU_TIME/decode(executions,0,1,executions)/1000000,2) "cpu_time",
        round(AVG_HARD_PARSE_TIME/decode(executions,0,1,executions)/1000000,2) "hard_parse",
        round(USER_IO_WAIT_TIME/decode(executions,0,1,executions)/1000000,2) "user_io",
	round(rows_processed/decode(executions,0,1,executions)) "rows",
	round(buffer_gets/decode(executions,0,1,executions)) "gets",
	round(disk_reads/decode(executions,0,1,executions)) "reads"
from
	gv$sqlstats x
where x.sql_id = :sql_id  
order by trunc(ELAPSED_TIME/decode(executions,0,1,executions)/1000000) desc
;
prompt ##########################################################################
prompt Display current sql v$sql Information
prompt Seconds Per execution,such elapsed_time mean elapsed_time(s)/per execution
col sql_id for a13
col sql_text for a10
col sql_child_number head CH# for 999
col LAST_LOAD_TIME for a14
col PARSING_SCHEMA for a18
col exes for 99999
col "ch#" for 99
select
    child_number ch#,
    plan_hash_value plan,
    PARSING_SCHEMA_NAME as PARSING_SCHEMA,
    executions exes,    
    substr(LAST_LOAD_TIME,6,14) as LAST_LOAD_TIME,
    round(rows_processed/decode(executions,0,1,executions)) "rows",
    round(elapsed_time/decode(executions,0,1,executions)/1000/1000,2) "elapsed",
    round(cpu_time/decode(executions,0,1,executions)/1000/1000,2) "cpu",
    round(USER_IO_WAIT_TIME/decode(executions,0,1,executions)/1000/1000,2) as "user_io",
    round(CLUSTER_WAIT_TIME/decode(executions,0,1,executions)/1000/1000,2) as "cluster",
    round(APPLICATION_WAIT_TIME/decode(executions,0,1,executions)/1000/1000,2) as "app",
    round(CONCURRENCY_WAIT_TIME/decode(executions,0,1,executions)/1000/1000,2) as "concurr",
    round(PLSQL_EXEC_TIME/decode(executions,0,1,executions)/1000/1000,2) as "plsql",
    round(JAVA_EXEC_TIME/decode(executions,0,1,executions)/1000/1000,2) as "java",
    round(buffer_gets/decode(executions,0,1,executions)) as "gets",
    round(disk_reads/decode(executions,0,1,executions)) "reads"
from
    v$sql
where
    sql_id = :sql_id
order by 6
/


prompt show sql_id and sql_text

set linesize 500
set pages 0
set head on
col flag for a20
col SQL_TEXT for a150
select /*yaochong123456abc78*/ PARSING_SCHEMA_NAME,'in gv$sql' as flag, sql_id ,sql_text 
from gv$sql 
where upper(sql_text) like upper('%&sql_text%') 
and sql_text not like '%yaochong123456abc78%' and sql_text not like '%dbms_output.put_line(:sql_text); end%'
union
select 'None','in dba_hist_sqltext' as flag, sql_id,to_char(substr(sql_text,0,2000)) as sql_text 
from dba_hist_sqltext 
where upper(sql_text) like upper('%&sql_text%') 
and sql_text not like '%yaochong123456abc78%' 
and sql_text not like '%dbms_output.put_line(:sql_text); end%';
