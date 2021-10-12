
set   serveroutput   on   size   1000000

--desc:   query the undo infomation
--usage:  @undo <chongzi>
--author: chong yao
--date:   Nov/30/2021

prompt Shows undo usage every 10 minutes since 24 hours ago...

col undo_used_mb for a20
col name for a30
col END_TIME for a24
col con_id for 9999
set linesize 500
set pages 100
SELECT INST_ID,
       BEGIN_TIME,
       END_TIME,
       lpad(TRUNC(UNDOBLKS * (SELECT VALUE FROM V$PARAMETER WHERE NAME = 'db_block_size' AND ROWNUM = 1) / 1024 / 1024,
             2) || ' MB',12) AS undo_used_mb
  FROM GV$UNDOSTAT
 WHERE BEGIN_TIME > SYSDATE - 1
 ORDER BY BEGIN_TIME;

set serveroutput on

declare 
  l_start    number;
  l_end      number;
  v_KTUXEUSN number;
  v_KTUXESLT number;
  v_value    number;
  v_value1   varchar2(20); 
  v_cnt      number;
  v_roll_cnt number;

  cursor c_roll is select vs.sid || ',' || vs.serial# as sid, vs.username, rn.name roll_name, vt.start_time, vt.log_io, vt.phy_io, vt.used_ublk,
        round(vt.used_ublk * (select value/1024/1024 from v$parameter where name='db_block_size' and ROWNUM = 1),2) as used_usize, vt.used_urec, vt.recursive
  from
  v$transaction vt,
  v$session vs,
  v$rollname rn
  where vt.addr = vs.taddr
  and vt.xidusn = rn.usn order by used_urec desc;
  v_roll c_roll%rowtype;
  
  cursor c_seg is select
  dba_segments.owner,
  dba_segments.tablespace_name,
  dba_rollback_segs.file_id,
  dba_rollback_segs.segment_id,
  dba_segments.segment_type,
  dba_segments.segment_name,
  round(dba_segments.bytes/1024/1024,2) as mb,
  dba_segments.extents,
  dba_rollback_segs.status
from
  sys.dba_segments, 
  sys.dba_rollback_segs
where 
  dba_segments.bytes/1024/1024 > 10 and -- only show > 10M 
  dba_segments.segment_name = dba_rollback_segs.segment_name 
order by sys.dba_rollback_segs.segment_id;
  v_seg c_seg%rowtype;
  cursor c_t_stat is select KTUXECFL,count(*) as cnt from x$ktuxe group by KTUXECFL;
  v_t_stat c_t_stat%rowtype;
  
  cursor c_trx is select 
       r.usn as USN,
       r.name rollback_name,
       q.sql_id,
       case when s.sid is null then 'None' else s.sid || ',' || s.serial# end as sid_and_serial,
       round(seg.bytes/1024/1024,2) as mb ,
       seg.TABLESPACE_NAME,
       l.addr as TADDR,
        substr(q.sql_text,0,40) as sql_text
  from v$lock l,
     v$session s,
     v$rollname r,
     dba_segments seg,
     v$sql q
  where   l.addr = s.taddr(+)
  and     trunc(l.id1(+)/65536)=r.usn
  and     l.type(+) = 'TX'
  and     l.lmode(+) = 6
  and     r.name = seg.segment_name
  and     s.sql_hash_value = q.hash_value
  and     s.sql_address = q.address
  and     seg.bytes > 1*1024*1024*1024
  order by bytes desc;
  v_trx c_trx%rowtype;

  cursor c_ktu is SELECT KTUXEUSN USN,
  KTUXESIZ,
  KTUXESLT,
  KTUXESQN,
  KTUXESTA,
  KTUXERDBF FILE_ID,
  KTUXERDBB BLOCK_ID
  FROM sys.x$KTUXE WHERE KTUXECFL = 'DEAD';

  v_ktu c_ktu%rowtype;

begin
  dbms_output.enable(buffer_size => NULL);
  select ksppstvl into v_value from x$ksppi x, x$ksppcv y where x.indx = y.indx and ksppinm = '_rollback_segment_count';
  select count(*) into v_cnt from v$rollname;
  select value into v_value1 from v$parameter where name = 'fast_start_parallel_rollback';
  dbms_output.put_line('
_rollback_segment_count and Current Node rollback segments Count(From v$rollname)
If RAC System Node Count > 3 be carefull!!! Oracle Max Rollback Segments is 32760');
  dbms_output.put_line('======================');
  dbms_output.put_line('fast_start_parallel_rollback        ' || ' : ' || v_value1);
  dbms_output.put_line('_rollback_segment_count             ' || ' : ' || v_value);
  dbms_output.put_line('Current Node rollback segments Count' || ' : ' || v_cnt );
  
  
  select count(*) into v_roll_cnt from
  v$transaction vt,
  v$session vs,
  v$rollname rn
  where vt.addr = vs.taddr
  and vt.xidusn = rn.usn;
  if v_roll_cnt > 0 then
  dbms_output.put_line('
Active transaction,rollback segments Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('|     sid_and_serial# |' || ' USERNAME      ' || '| ROLL_SEGMENT_NAME         |' || ' START_TIME        ' || '| LOGICAL_IO |' || ' PHYSICAL IO ' || '| USED_UBLK |' || ' USED_UNDO(MB) ' || '| used_urec |' || ' recursive ' || '|');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_roll;
    loop fetch c_roll into v_roll;
    exit when c_roll%notfound;
    dbms_output.put_line('| ' || lpad(v_roll.sid,19) ||' | '|| rpad(v_roll.username,13) || ' | ' || rpad(v_roll.roll_name,25) || ' | '|| rpad(v_roll.start_time,17) || ' | '|| lpad(v_roll.log_io,10) || ' | '|| lpad(v_roll.phy_io,11) || ' | '|| lpad(v_roll.used_ublk,9) || ' | '|| lpad(v_roll.used_usize,13) || ' | '|| lpad(v_roll.used_urec,9) || ' | '|| lpad(v_roll.recursive,10) || '|');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_roll;
  else 
    dbms_output.put_line('
These is no Transaction Use rollback segments,No Transaction');
  dbms_output.put_line('======================');
  end if;

   dbms_output.put_line('
Rollback Segments Basic Status Information(only Show the Rollback Segment Size > 10M)
USN means Rollback Segments number');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| OWNER |' || ' TABLESPACE_NAME  ' || '| FILE# |' || ' USN        ' || '| SEGMENT_TYPE |' || ' ROLLBACK_SEGMENT_NAME                             ' || '| ROLLBACK_SEGMENT_SIZE(MB) |' || ' EXTENTS ' || '| STATUS    ' || '|');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_seg;
    loop fetch c_seg into v_seg;
    exit when c_seg%notfound;
    dbms_output.put_line('| ' || rpad(v_seg.owner,5) ||' | '|| rpad(v_seg.tablespace_name,16) || ' | ' || lpad(v_seg.file_id,5) || ' | '|| lpad(v_seg.segment_id,10) || ' | '|| rpad(v_seg.segment_type,12) || ' | '|| rpad(v_seg.segment_name,49) || ' | '|| lpad(v_seg.mb,25) || ' | '|| lpad(v_seg.extents,7) || ' | ' || rpad(v_seg.status,10) || '|');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_seg;

    dbms_output.put_line('
Active Transaction Rollback Segments Information(Only Show Rollback segment > 1G per transaction desc)');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| USN |' || ' ROLLBACK_NAME   ' || '| SQL_ID        |' || '    SID_AND_SERIAL# ' || '| TRX_SIZE(MB) |' || ' TABLESPACE_NAME     ' || '| TADDR(v$session) |' || ' SQL_TEXT                                     ' || ' |');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_trx;
    loop fetch c_trx into v_trx;
    exit when c_trx%notfound;
    dbms_output.put_line('| ' || lpad(v_trx.USN,3) ||' | '|| rpad(v_trx.rollback_name,15) || ' | ' || lpad(v_trx.sql_id,13) || ' | '|| lpad(v_trx.sid_and_serial,18) || ' | '|| lpad(v_trx.mb,12) || ' | '|| rpad(v_trx.TABLESPACE_NAME,19) || ' | '|| lpad(v_trx.TADDR,16) || ' | ' || rpad(v_trx.SQL_TEXT,45) || ' |');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_trx;
   dbms_output.put_line('
Transaction Status CNT Information(x$ktuxe)
The ktuxecfl column means the Flag of Status, such as DEAD transaction');
  dbms_output.put_line('======================');
  dbms_output.put_line('------------------------------------------');
  dbms_output.put_line('| KTUXECFL             |' || '           COUNT ' || '|');
  dbms_output.put_line('------------------------------------------');
  open c_t_stat;
    loop fetch c_t_stat into v_t_stat;
    exit when c_t_stat%notfound;
    dbms_output.put_line('| ' || rpad(v_t_stat.KTUXECFL,20) ||' | '|| lpad(v_t_stat.CNT,16) || '|');
    end loop;
    dbms_output.put_line('------------------------------------------');
  close c_t_stat;


   dbms_output.put_line('
Dead Transaction Information(x$ktuxe)
USN means Rollback Segments number
KUTXESIZ means the remaining number of undo blocks required for rollback
KTUXESLT means the transaction slot number
KTUXESQN means the xid Sequence number
KTUXESTA means the transaction status
');
  dbms_output.put_line('======================');
  dbms_output.put_line('------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('|   USN |' || ' KTUXESIZ(BLOCK) ' || '| KTUXESLT   |' || ' KTUXESQN     ' || '| KTUXESTA(STATUS) |' || ' FILE_ID ' || '|        BLOCK_ID ' || '|');
  dbms_output.put_line('------------------------------------------------------------------------------------------------------');
  open c_ktu;
    loop fetch c_ktu into v_ktu;
    exit when c_ktu%notfound;
    dbms_output.put_line('| ' || lpad(v_ktu.USN,5) ||' | '|| lpad(v_ktu.KTUXESIZ,15) || ' | ' || lpad(v_ktu.KTUXESLT,10) || ' | '|| lpad(v_ktu.KTUXESQN,12) || ' | '|| rpad(v_ktu.KTUXESTA,16) || ' | '|| lpad(v_ktu.FILE_ID,7) || ' | ' || lpad(v_ktu.BLOCK_ID,15) || ' |');
    end loop;
    dbms_output.put_line('------------------------------------------------------------------------------------------------------');
  close c_ktu;

  dbms_output.put_line('
How long does it take to roll back(Minutes)');
  dbms_output.put_line('======================');
  select KTUXEUSN,KTUXESLT into v_KTUXEUSN,v_KTUXESLT from x$ktuxe where KTUXESIZ <>0 and ktuxecfl ='DEAD';
  select ktuxesiz into l_start from x$ktuxe where KTUXEUSN = v_KTUXEUSN and KTUXESLT = v_KTUXESLT;
  dbms_lock.sleep(60);
  select ktuxesiz into l_end from x$ktuxe where KTUXEUSN = v_KTUXEUSN and KTUXESLT = v_KTUXESLT;
    dbms_output.put_line('------------------------------------------------------------------------------------------------------');
    dbms_output.put_line('| Estimated remaining Minutes: '|| round(l_end/(l_start -l_end)) || ' min' || '                    |'         );
    dbms_output.put_line('------------------------------------------------------------------------------------------------------');
  -- exception
  -- when others then
  --  dbms_output.put_line('------------------------------------------------------------------------------------------------------');
  --  dbms_output.put_line('| There are no transactions that need to be rolled back at the moment.  ' || substr(SQLERRM,1,80) || '     |');
  --  dbms_output.put_line('------------------------------------------------------------------------------------------------------');
end;
/




prompt Show undo statistics from V$UNDOSTAT....
col uds_mb head MB format 999999.99
col uds_maxquerylen head "MAX|QRYLEN" format 999999
col uds_maxqueryid  head "MAX|QRY_ID" format a13 
col uds_ssolderrcnt head "ORA-|1555" format 999
col uds_nospaceerrcnt head "SPC|ERR" format 99999
col uds_unxpstealcnt head "UNEXP|STEAL" format 9999999
col uds_expstealcnt head "EXP|STEAL" format 9999999
col end_time for a12
select * from (
    select 
        begin_time, 
        to_char(end_time, 'HH24:MI:SS') end_time, 
        txncount, 
        undoblks * (select block_size from dba_tablespaces where upper(tablespace_name) = 
                        (select upper(value) from v$parameter where name = 'undo_tablespace')
                   ) / 1048576 uds_MB ,
        maxquerylen uds_maxquerylen,
        maxqueryid  uds_maxqueryid,
        ssolderrcnt uds_ssolderrcnt,
        nospaceerrcnt uds_nospaceerrcnt,
 	unxpstealcnt uds_unxpstealcnt,
	expstealcnt uds_expstealcnt
    from 
        v$undostat
    order by
        begin_time desc
) where rownum <= 30;

