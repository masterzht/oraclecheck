
set linesize 500

set arraysize 100
set long 20000 longchunksize 100000000
set serveroutput on size 100000

declare
    v_cnt number;
    v_open_mode varchar2(100) :=null;

    cursor c_io is select snap_time,
    decode(lfs,null,'None',lfs) as lfs,
    decode(lfpw,null,'None',lfpw) as lfpw, 
    decode(dpr,null,'None',dpr) as dpr,
    decode(cfpw,null,'None',cfpw) as cfpw,
    decode(dfsr,null,'None',dfsr) as dfsr,
    decode(dfscr,null,'None',dfscr) as dfscr,
    decode(dpw,null,'None',dpw) as dpw,
    decode(dpwt,null,'None',dpw) as dpwt,
    decode(dprt,null,'None',dprt) as dprt
    from (
select 'inst 1@' || stat.snap_time as snap_time,
max(decode(stat.event_name,'log file sync', stat.Avg_wait_Time)) lfs,
max(decode(stat.event_name,'log file parallel write', stat.Avg_wait_Time)) lfpw,
max(decode(stat.event_name,'direct path read', stat.Avg_wait_Time)) dpr,
max(decode(stat.event_name,'control file parallel write', stat.Avg_wait_Time)) cfpw,
max(decode(stat.event_name,'db file sequential read', stat.Avg_wait_Time)) dfsr,
max(decode(stat.event_name,'db file scattered read', stat.Avg_wait_Time)) dfscr,
max(decode(stat.event_name,'direct path write', stat.Avg_wait_Time)) dpw,
max(decode(stat.event_name,'direct path write temp', stat.Avg_wait_Time)) dpwt,
max(decode(stat.event_name,'direct path read temp', stat.Avg_wait_Time)) dprt
from
(
select to_char(b.begin_interval_time,'yyyymmdd hh24:mi:ss') snap_time, event_name, TOTAL_WAITS-lag(TOTAL_WAITS) over (partition by event_name order by event_name, a.snap_id) waits, TIME_WAITED_MICRO-lag(TIME_WAITED_MICRO) over (partition by event_name order by event_name, a.snap_id) wait_time,
round((TIME_WAITED_MICRO-lag(TIME_WAITED_MICRO) over (partition by event_name order by event_name, a.snap_id)) / decode((TOTAL_WAITS-lag(TOTAL_WAITS) over (partition by event_name order by event_name, a.snap_id)),0,1,(TOTAL_WAITS-lag(TOTAL_WAITS) over (partition by event_name order by event_name, a.snap_id))) / 1000) Avg_wait_Time
from dba_hist_system_event a, dba_hist_snapshot b
where event_name in ('log file sync','log file parallel write','direct path read','direct path read temp','direct path write temp',
  'control file parallel write','db file sequential read','db file scattered read','direct path write')
and a.instance_number= 1
and a.instance_number = b.instance_number
and a.snap_id = b.snap_id
) stat group by snap_time
union all
select 'inst 2@' || stat.snap_time as snap_time,
max(decode(stat.event_name,'log file sync', stat.Avg_wait_Time)) lfs,
max(decode(stat.event_name,'log file parallel write', stat.Avg_wait_Time)) lfpw,
max(decode(stat.event_name,'direct path read', stat.Avg_wait_Time)) dpr,
max(decode(stat.event_name,'control file parallel write', stat.Avg_wait_Time)) cfpw,
max(decode(stat.event_name,'db file sequential read', stat.Avg_wait_Time)) dfsr,
max(decode(stat.event_name,'db file scattered read', stat.Avg_wait_Time)) dfscr,
max(decode(stat.event_name,'direct path write', stat.Avg_wait_Time)) dpw,
max(decode(stat.event_name,'direct path write temp', stat.Avg_wait_Time)) dpwt,
max(decode(stat.event_name,'direct path read temp', stat.Avg_wait_Time)) dprt
from
(
select to_char(b.begin_interval_time,'yyyymmdd hh24:mi:ss') snap_time, event_name, TOTAL_WAITS-lag(TOTAL_WAITS) over (partition by event_name order by event_name, a.snap_id) waits, TIME_WAITED_MICRO-lag(TIME_WAITED_MICRO) over (partition by event_name order by event_name, a.snap_id) wait_time,
round((TIME_WAITED_MICRO-lag(TIME_WAITED_MICRO) over (partition by event_name order by event_name, a.snap_id)) / decode((TOTAL_WAITS-lag(TOTAL_WAITS) over (partition by event_name order by event_name, a.snap_id)),0,1,(TOTAL_WAITS-lag(TOTAL_WAITS) over (partition by event_name order by event_name, a.snap_id))) / 1000) Avg_wait_Time
from dba_hist_system_event a, dba_hist_snapshot b
where event_name in ('log file sync','log file parallel write','direct path read','direct path read temp','direct path write temp',
  'control file parallel write','db file sequential read','db file scattered read','direct path write')
and a.instance_number= 2
and a.instance_number = b.instance_number
and a.snap_id = b.snap_id
) stat
group by snap_time
union all
select 'inst 3@' || stat.snap_time as snap_time,
max(decode(stat.event_name,'log file sync', stat.Avg_wait_Time)) lfs,
max(decode(stat.event_name,'log file parallel write', stat.Avg_wait_Time)) lfpw,
max(decode(stat.event_name,'direct path read', stat.Avg_wait_Time)) dpr,
max(decode(stat.event_name,'control file parallel write', stat.Avg_wait_Time)) cfpw,
max(decode(stat.event_name,'db file sequential read', stat.Avg_wait_Time)) dfsr,
max(decode(stat.event_name,'db file scattered read', stat.Avg_wait_Time)) dfscr,
max(decode(stat.event_name,'direct path write', stat.Avg_wait_Time)) dpw,
max(decode(stat.event_name,'direct path write temp', stat.Avg_wait_Time)) dpwt,
max(decode(stat.event_name,'direct path read temp', stat.Avg_wait_Time)) dprt
from
(
select to_char(b.begin_interval_time,'yyyymmdd hh24:mi:ss') snap_time, event_name, TOTAL_WAITS-lag(TOTAL_WAITS) over (partition by event_name order by event_name, a.snap_id) waits, TIME_WAITED_MICRO-lag(TIME_WAITED_MICRO) over (partition by event_name order by event_name, a.snap_id) wait_time,
round((TIME_WAITED_MICRO-lag(TIME_WAITED_MICRO) over (partition by event_name order by event_name, a.snap_id)) / decode((TOTAL_WAITS-lag(TOTAL_WAITS) over (partition by event_name order by event_name, a.snap_id)),0,1,(TOTAL_WAITS-lag(TOTAL_WAITS) over (partition by event_name order by event_name, a.snap_id))) / 1000) Avg_wait_Time
from dba_hist_system_event a, dba_hist_snapshot b
where event_name in ('log file sync','log file parallel write','direct path read','direct path read temp','direct path write temp',
  'control file parallel write','db file sequential read','db file scattered read','direct path write')
and a.instance_number= 3
and a.instance_number = b.instance_number
and a.snap_id = b.snap_id
) stat group by snap_time) order by snap_time;

v_io c_io%rowtype;

begin
  
  dbms_output.put_line('
LF_SYNC    Means Log File Sync
LFP_WRITE  Means Log File Parallel Write
DP_READ    Means Direct Path Read
DP_WRITE   Means Direct Path Write
sequential Means db file sequential read
scattered  Means db file scattered read
IO Event Latency(ms) Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| instance_number@snap_time |' || ' LF_SYNC |'|| ' LFP_WRITE |' || ' DP_READ |' || ' DP_WRITE ' || '| CFP_WRITE |' || ' sequential |'|| ' scattered ' || '| DP_READ_TEMP ' || '| DP_WRITE_TEMP |');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_io;
    loop fetch c_io into v_io;
    exit when c_io%notfound;
    dbms_output.put_line('| ' || lpad(v_io.snap_time,25) ||' | '|| lpad(v_io.lfs,7) || ' | '|| lpad(v_io.lfpw,9) || ' | '|| lpad(v_io.dpr,8) || ' | ' || lpad(v_io.dpw,7) || ' | ' || lpad(v_io.cfpw,9) || ' | ' || lpad(v_io.dfsr,10) || ' | ' || lpad(v_io.dfscr,10) || '|' || lpad(v_io.dprt,13) || ' | ' || lpad(v_io.dpwt,13) || ' |');
    end loop;
    dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_io;

end;
/ 
