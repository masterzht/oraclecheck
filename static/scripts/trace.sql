--10046 trace 11g
--session
alter session/system set events 'sql_trace [sql:<sql_id>|<sql_id>] rest of event specification';
alter system set events 'sql_trace [sql:92vzptavsymv3] wait=true,bind=true,plan_stat=all_executions,level=12';
alter system set events 'sql_trace [sql:92vzptavsymv3] off';
--system
alter session/system set events 'sql_trace {process : pid = <pid1>, pname = <pname>, orapid = <orapid>} rest of event specification';
alter system set events 'sql_trace {process:28427|28227|27777} wait=true, bind=true,plan_stat=all_executions,level=12';

--dbms_monitor 10g
select 'exec DBMS_MONITOR.SESSION_TRACE_ENABLE( session_id =>' || sid || ' , serial_num =>' || serial# || ', waits=> true, binds => true, plan_stat => ''ALL_EXECUTIONS'');'
from
v$session s where username = 'TRADE_ZSDZ'
/
begin
DBMS_MONITOR.SESSION_TRACE_ENABLE(
    session_id   => ,
    serial_num   => ,
    waits		 => true,
    binds		 => true,
    plan_stat	 => 'ALL_EXECUTIONS');
end;
/

begin
DBMS_MONITOR.SESSION_TRACE_DISABLE(
   session_id      => ,
   serial_num      => );
end;
/

--dbms_monitor 10g
select 
'begin DBMS_MONITOR.SESSION_TRACE_ENABLE( session_id =>' || sid || ', serial_num => ' || serial# || ', waits=> true, binds => true, plan_stat => ''ALL_EXECUTIONS''); end;' || chr(10) || '/'
from v$session 
where username = 'DLSYS'
/
--dbms_monitor 10g
select 
'begin DBMS_MONITOR.SESSION_TRACE_DISABLE( session_id =>' || sid || ', serial_num => ' || serial# || '); end;' || chr(10) || '/'
from v$session 
where username = 'DLSYS'
/

select 'exec DBMS_MONITOR.SESSION_TRACE_DISABLE( session_id =>' || sid || ' , serial_num =>' || serial# || ');'
from
v$session s where username = 'TRADE_ZSDZ'
/

exec DBMS_MONITOR.SERV_MOD_ACT_TRACE_ENABLE('SYS$USERS', module_name=>'CCM',waits=>true, binds=>true);

exec DBMS_MONITOR.SERV_MOD_ACT_TRACE_DISABLE('SYS$USERS', module_name=>'CCM');






-- SPM tracing
alter session set events 'trace [SQL_PlanManagement.*]';

--treedump index object_id, not data_object_id
alter session set events 'immediate trace name treedump level &1';

-- systemstate/processstate/hanganalysis
oradebug dump systemstate 1
oradebug setospid 4005
oradebug dump processstate 10
oradebug tracefile_name
oradebug hanganalyze 4

-- control file
alter session set events 'immediate trace name controlf level 12';

-- redo log file header
ALTER SESSION SET EVENTS 'immediate trace name redohdr level 10';

-- data file head

-- trace 1031 error -- Security An attempt was made to change the current username or password without the appropriate privilege
alter system set events '1031 trace name errorstack level 3';
alter system set events '1031 trace name errorstack level 3; name library_cache level 10';

alter session set events '3120 trace name errorstack level 3, forever';
alter session set events '3120 trace name errorstack level 3, lifetime 42';

--trace 942 error
alter system set events '942 trace name errorstack level 1';
oradebug setmypid
oradebug event 942 trace name errorstack level 3;

-- errorstack
connect / as sysdba
oradebug setospid  <os pid>
oradebug unlimit
oradebug dump errorstack 3

1. 生成enable 语句
set line 1000 pagesize 1000 trims on
select 'exec DBMS_MONITOR.SESSION_TRACE_ENABLE( session_id =>' || sid || ' , serial_num =>' || serial# || ', waits=> true, binds => true, plan_stat => ''ALL_EXECUTIONS'');'
from
v$session s where username = 'TRADE_ZSDZ'
/

2. 跑第一步的输出

3. 触发两分钟报表

4. 在trace目录找到最新的trc文件打包发给我, 具体目录用以下语句查找
select value from v$diag_info where name='Default Trace File';

5. 等我确认找到2分钟的会话和语句

6. 生成关闭跟踪的语句

select 'exec DBMS_MONITOR.SESSION_TRACE_DISABLE( session_id =>' || sid || ' , serial_num =>' || serial# || ');'
from
v$session s where username = 'TRADE_ZSDZ'
/




col tracefile for A120

select value ||'/'||(select instance_name from v$instance) ||'_ora_'||
       (select spid||case when traceid is not null then '_'||traceid else null end
             from v$process where addr = (select paddr from v$session
                                         where sid = (select sid from v$mystat
                                                    where rownum = 1
                                               )
                                    )
       ) || '.trc' tracefile
from v$parameter where name = 'user_dump_dest';
col value for A100
select value from v$diag_info where name='Default Trace File';

--path
--select value from v$diag_info where name='Diag Trace';
