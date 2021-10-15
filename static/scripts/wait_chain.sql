set serveroutput on
set linesize 500
set pages 0
declare
    v_wait_cnt number;

    cursor c_lock is select
    b.type || '-' || b.id1 ||'-'|| b.id2 || case when b.type = 'TM' then (select '(' || owner || '.' || object_name || ')' from dba_objects where object_id = b.id1) else '' end as b_res,
    s1.sid || ','|| s1.serial# || '@' || s1.inst_id as b_blocker,
    (select count(*) from gv$lock t where t.type=b.type and t.id1 = b.id1 and t.id2 = b.id2 and request > 0) b_blocked_cnt,
    b.request b_request,
    b.lmode b_lmode,
    s1.username b_username,
    case when s1.sql_id is null then 'None' else s1.sql_id end as  b_sql_id,
    s1.machine,
    s1.program,
    s1.module,
    s1.service_name,
    s1.prev_sql_id b_prev_sql_id,
    b.ctime as b_ctime,
    s2.sid || ','|| s2.serial# || '@' || s2.inst_id as w_waiter,
    w.request w_request,
    w.lmode w_lmode,
    s2.username w_username,
    s2.sql_id w_sql_id,
    s2.prev_sql_id w_prev_sql_id,
    w.ctime as w_ctime
from
    gv$lock b,
    gv$lock w,
    gv$session s1,
    gv$session s2
where
    b.block > 0
and w.request > 0
and b.id1 = w.id1
and b.id2 = w.id2
and b.type = w.type
and b.inst_id = s1.inst_id
and b.sid = s1.sid
and w.inst_id = s2.inst_id
and w.sid = s2.sid
and b.type in ('TM','TX')
order by
    b_res,
    w_ctime desc;
v_lock c_lock%rowtype;

begin
  select count(*) into v_wait_cnt from
    gv$lock b,
    gv$lock w,
    gv$session s1,
    gv$session s2
where
    b.block > 0
and w.request > 0
and b.id1 = w.id1
and b.id2 = w.id2
and b.type = w.type
and b.inst_id = s1.inst_id
and b.sid = s1.sid
and w.inst_id = s2.inst_id
and w.sid = s2.sid
and b.type in ('TM','TX');


  if v_wait_cnt > 0 then 

  dbms_output.put_line('
Lock Information:
BLOCKING_RESOURCE means the v$lock TYPE ID1 ID2 Information eg.TX id1 id2 v$transaction.XIDUSN  XIDSQN
BLOCKING_SESSION  means the blocking_session sid_and_serial#@inst_id
B_CNT             means the COUNT of waiting session
B_SQL_ID          means then blocking_session SQL_ID
B_PREV_SQL_ID     means the blocking_session PREV_SQL_ID
B_RUN(S)          means the blocking_sql running seconds');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| BLOCKING_RESOURCE |' || ' BLOCKING_SESSION ' || '| B_CNT |' || ' LMODE ' || '| B_USERNAME |' || ' B_SQL_ID      ' || '| BLOCKING_MACHINE |' || ' BLOCKING_PROGRAM ' || '| B_PREV_SQL_ID |'  || ' B_RUN(S) '|| '| WAITER         |'  || ' W_USERNAME '|| '| W_SQL_ID      |'  || ' W_PREV_SQL_ID ' || '| W_RUN(S)' ||  ' |');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_lock;
    loop fetch c_lock into v_lock;
    exit when c_lock%notfound;
    dbms_output.put_line('| ' || rpad(v_lock.b_res,17) ||' | '|| lpad(v_lock.b_blocker,16) || ' | '|| lpad(v_lock.b_blocked_cnt,5) || ' | '|| lpad(v_lock.b_lmode,5) || ' | '|| lpad(v_lock.b_username,10) || ' | '|| lpad(v_lock.b_sql_id,13) ||  ' | '|| lpad(v_lock.machine,16) || ' | '|| lpad(v_lock.program,16) || ' | '|| lpad(v_lock.b_prev_sql_id,13) || ' | '|| lpad(v_lock.b_ctime,8) || ' | '|| lpad(v_lock.w_waiter,14) || ' | '|| lpad(v_lock.w_username,10) || ' | ' || lpad(v_lock.w_sql_id,13) || ' | '|| lpad(v_lock.w_prev_sql_id,13) || ' | '|| lpad(v_lock.w_ctime,9) || '|');
    end loop;
    dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_lock;
 
 else 
  dbms_output.put_line('There is No Lock');
  dbms_output.put_line('======================');
 end if;
end;
/


--batch kill one user's session
set serveroutput on size 100000;
begin
for x in (select 'ALTER SYSTEM disconnect SESSION ''' || sid || ',' || s.SERIAL# || ''' immediate;' cmd from v$session s where event like 'latch: cache buffers chains')
loop
	begin
    execute immediate x.cmd;
	dbms_output.put_line(x.cmd);
	exception when others then null;
	end;
end loop;
end;
/

--rollback dead lock
SELECT 
'ROLLBACK FORCE "' || p.local_tran_id || '";' 
FROM dba_2pc_pending p WHERE p.state <> 'forced rollback';

