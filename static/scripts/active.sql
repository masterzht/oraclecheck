--当前数据库中的session信息与session中正在执行的SQL语句
set linesize 3000
set pages 1000
col username for a10
col spid for a6
col sid_and_serial# for a15
col terminal for a15
col event for a26
col machine for a25
col program for a20
col sql_text for a30
col sql_id for a13
prompt Display Avg and Max Connections of All Nodes since Instance Startup

col RESOURCE_NAME for a13
col INITIAL_ALLOCATION for a18
col LIMIT_VALUE for a11

select RESOURCE_NAME,
       CURRENT_UTILIZATION,
       MAX_UTILIZATION,
       INITIAL_ALLOCATION,
       LIMIT_VALUE
from v$resource_limit
where RESOURCE_NAME in ('processes', 'sessions');

select /*+use_nl(a,b,c)*/distinct a.sid || ',' || a.serial# as sid_and_serial#,
                                  a.username,
                                  a.terminal,
                                  a.machine,
                                  a.program,
                                  b.spid,
                                  c.sql_id,
                                  substr(c.sql_text, 0, 30) as sql_text
from v$session a,
     v$process b,
     v$sql c
where a.paddr = b.addr(+)
  and a.sql_hash_value = c.hash_value
  and a.sql_address = c.address
  and a.status = 'ACTIVE'
  and a.type = 'USER'
  and a.sid not in (select sid from v$mystat where rownum = 1)
/


--正在执行的SQL语句的等待事件信息
prompt display the active sessions and events in current node...
col SECONDS for a7
col KILL_SQL for a56
col "P1 P2 P3" for a18
select /*+ ordered use_nl(a,b) */
    trim(to_char(a.sql_id))                                                              as sql_id,
    b.spid                                                                               as spid,
    substr(c.event, 1, 25)                                                               as event,
    c.p1 || ',' || c.p2 || ',' || c.p3                                                   as "P1 P2 P3",
    to_char(LAST_CALL_ET)                                                                as seconds,
    to_char(a.logon_time, 'mmdd hh24:mi')                                                as logon_time,
    'alter system disconnect session ''' || a.sid || ',' || a.SERIAL# || ''' immediate;' as kill_sql
from v$session a,
     v$process b,
     v$session_wait c
where a.type = 'USER'
  and a.status = 'ACTIVE'
  and a.paddr = b.addr
  and a.sid = c.sid
  and a.wait_class <> 'Idle'
  and a.sid not in (select sid from v$mystat where rownum = 1)
order by LAST_CALL_ET desc
/
prompt display all status of all sessions...
select inst_id, status, count(*) from gv$session group by inst_id,status order by inst_id,status;
prompt display the session status that not active in current node...
col SECONDS for a10
select /*+ ordered use_nl(a,b) */
    trim(to_char(a.sql_id))            as sql_id,
    a.sid                              as sid,
    b.spid                             as spid,
    substr(c.event, 1, 25)             as event,
    c.p1 || ',' || c.p2 || ',' || c.p3 as "P1 P2 P3",
    to_char(LAST_CALL_ET)              as seconds,
    a.logon_time
from v$session a,
     v$process b,
     v$session_wait c
where a.type = 'USER'
  and a.status <> 'ACTIVE'
  and a.paddr = b.addr
  and a.sid = c.sid
  and a.wait_class <> 'Idle'
  and a.sid not in (select sid from v$mystat where rownum = 1)
order by LAST_CALL_ET desc
/
