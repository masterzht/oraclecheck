-- NAME: DRMDIAG.SQL
-- ------------------------------------------------------------------------
-- AUTHOR: Michael Polaski - Oracle Support Services
-- ------------------------------------------------------------------------
-- PURPOSE:
-- This script is intended to provide a user friendly guide to troubleshoot
-- drm (dynamic resource remastering) waits. The script will create a file
-- called drmdiag_<timestamp>.out in your local directory.

set echo off
set feedback off
column timecol new_value timestamp
column spool_extension new_value suffix
select to_char(sysdate,'Mondd_hh24mi') timecol,
'.out' spool_extension from sys.dual;
column output new_value dbname
select value || '_' output
from v$parameter where name = 'db_name';
spool drmdiag_&&dbname&&timestamp&&suffix
set trim on
set trims on
set lines 120
set pages 100
set verify off
alter session set optimizer_features_enable = '10.2.0.4';
set feedback on

PROMPT DRMDIAG DATA FOR &&dbname&&timestamp
PROMPT Important paramenters:
PROMPT 
PROMPT _gc_policy_minimum (default is 1500).  Increasing this would cause DRMs to happen less frequently.  
PROMPT Use the "OBJECT_POLICY_STATISTICS" section later in this report to see how active various objects are. 
PROMPT
PROMPT _gc_policy_time (default to 10 (minutes)).  Amount of time to evaluate policy stats.  Use the 
PROMPT "OBJECT_POLICY_STATISTICS" section later in this report to see how active various objects are for the
PROMPT _gc_policy_time.  Usually not necessary to change this parameter.  
PROMPT
PROMPT _gc_read_mostly_locking (default is TRUE).  Setting this to FALSE would disable read mostly related DRMs.
PROMPT
PROMPT gcs_server_processes (default is derived from CPU count/4).  May need to increase this above the 
PROMPT default to add LMS processes to complte the work during a DRM but the default is usually adequate.
PROMPT
PROMPT _gc_element_percent (default is 110).  May need to apply the fix for bug 14791477 and increase this to
PROMPT 140 if running out of lock elements.  Usually not necessary to change this parameter.  
PROMPT
PROMPT GC Related parameters set in this instance:
show parameter gc
PROMPT 
PROMPT CPU count on this instance:
show parameter cpu_count

PROMPT
PROMPT SGA INFO FOR &&dbname&&timestamp
PROMPT
PROMPT Larger buffer caches (above 100 gig) may increase the cost of DRMs significantly.
set lines 120
set pages 100
column component format a40 tru
column current_size format 99999999999999999
column min_size format 99999999999999999
column max_size format 99999999999999999
column user_specified_size format 99999999999999999
select component, current_size, min_size, max_size, user_specified_size
from v$sga_dynamic_components
where current_size > 0;

PROMPT
PROMPT ASH THRESHOLD...
PROMPT
PROMPT This will be the threshold in milliseconds for total drm freeze
PROMPT times. This will be used for the next queries to look for the worst
PROMPT 'drm freeze' minutes. Any minutes that have an average log file
PROMPT sync time greater than the threshold will be analyzed further.
column threshold_in_ms new_value threshold format 999999999.999
select decode(min(threshold_in_ms),null,0,min(threshold_in_ms)) threshold_in_ms
from (select inst_id, to_char(sample_time,'Mondd_hh24mi') minute,
sum(time_waited)/1000 threshold_in_ms
from gv$active_session_history
where event like '%drm freeze%'
group by inst_id,to_char(sample_time,'Mondd_hh24mi')
order by 3 desc)
where rownum <= 10;

PROMPT
PROMPT ASH WORST MINUTES FOR DRM FREEZE WAITS:
PROMPT
PROMPT APPROACH: These are the minutes where the avg drm freeze time
PROMPT was the highest (in milliseconds).
column event format a30 tru
column program format a35 tru
column total_wait_time format 999999999999.999
column avg_time_waited format 999999999999.999
select to_char(sample_time,'Mondd_hh24mi') minute, inst_id, event,
sum(time_waited)/1000 TOTAL_WAIT_TIME , count(*) WAITS,
avg(time_waited)/1000 AVG_TIME_WAITED
from gv$active_session_history
where event like '%drm freeze%'
group by to_char(sample_time,'Mondd_hh24mi'), inst_id, event
having sum(time_waited)/1000 > &&threshold
order by 1,2;

PROMPT
PROMPT ASH DRM BACKGROUND PROCESS WAITS DURING WORST MINUTES:
PROMPT
PROMPT APPROACH: What is LMS doing when 'drm freeze' waits
PROMPT are happening? LMD and LMON info may also be relevant
column inst format 999
column minute format a12 tru
column event format a50 tru
column program format a55 wra
select to_char(sample_time,'Mondd_hh24mi') minute, inst_id inst,
sum(time_waited)/1000 TOTAL_WAIT_TIME , count(*) WAITS,
avg(time_waited)/1000 AVG_TIME_WAITED,
program, event
from gv$active_session_history
where to_char(sample_time,'Mondd_hh24mi') in (select to_char(sample_time,'Mondd_hh24mi')
from gv$active_session_history
where event like '%drm freeze%'
group by to_char(sample_time,'Mondd_hh24mi'), inst_id
having sum(time_waited)/1000 > &&threshold and sum(time_waited)/1000 > 0.5)
and (program like '%LMS%' or program like '%LMD%' or
program like '%LMON%' or event like '%drm freeze%')
group by to_char(sample_time,'Mondd_hh24mi'), inst_id, program, event
order by 1,2,3,5 desc, 4;

PROMPT
PROMPT POLICY HISTORY INFO:
PROMPT See if you can correlate policy history events with minutes of high
PROMPT wait time.
select * from gv$policy_history
order by event_date;
PROMPT
PROMPT DYNAMIC_REMASTER_STATS
PROMPT This shows where time is spent during DRM operations.
set heading off
set lines 60
select 'Instance: '||inst_id inst, 'Remaster Ops: '||remaster_ops rops,
'Remaster Time: '||remaster_time rtime, 'Remastered Objects: '||remastered_objects robjs,
'Quiesce Time: '||quiesce_time qtime, 'Freeze Time: '||freeze_time ftime,
'Cleanup Time: '||cleanup_time ctime, 'Replay Time: '||replay_time rptime,
'Fixwrite Time: '||fixwrite_time fwtime, 'Sync Time: '||sync_time stime,
'Resources Cleaned: '||resources_cleaned rclean,
'Replayed Locks Sent: '||replayed_locks_sent rlockss,
'Replayed Locks Received: '||replayed_locks_received rlocksr,
'Current Objects: '||current_objects
from gv$dynamic_remaster_stats
order by 1;
set lines 120
set heading on

PROMPT
PROMPT OBJECT_POLICY_STATISTICS:
PROMPT The sum of the last 3 columns (sopens,xopens,xfers) decides whether the object
PROMPT will be considered for DRM (_gc_policy_minimum).  The duration of the stats 
PROMPT are controlled by _gc_policy_time (default is 10 minutes).
select object,node,sopens,xopens,xfers from x$object_policy_statistics;

PROMPT
PROMPT ACTIVE OBJECTS (OBJECT_POLICY_STATISTICS)
PROMPT These are the objects that are above the default _gc_policy_minimum (1500).
select object, node, sopens+xopens+xfers activity
from  x$object_policy_statistics
where sopens+xopens+xfers > 1500
order by 3 desc;

PROMPT LWM FOR LE FREELIST
PROMPT This number should never get near zero, if it does consider the fix for bug 14791477 
PROMPT and/or increasing _gc_element_percent.
select sum(lwm) from x$kclfx;

PROMPT
PROMPT GCSPFMASTER INFO WITH OBJECT NAMES
column objname format a120 tru
select o.name || ' - '|| o.subname objname, o.type#, h.*
from v$gcspfmaster_info h, obj$ o where h.data_object_id=o.dataobj#
order by data_object_id;

PROMPT
PROMPT ASH DETAILS FOR WORST MINUTES:
PROMPT
PROMPT APPROACH: If you cannot determine the problem from the data
PROMPT above, you may need to look at the details of what each session
PROMPT is doing during each 'bad' snap. Most likely you will want to
PROMPT note the times of the high drm freezewaits, look at what
PROMPT LMS, LMD0, LMON is doing at those times, and go from there...
set lines 140
column program format a45 wra
column sample_time format a25 tru
column event format a30 tru
column time_waited format 999999.999
column p1 format a40 tru
column p2 format a40 tru
column p3 format a40 tru
select sample_time, inst_id inst, session_id, program, event, time_waited/1000 TIME_WAITED,
p1text||': '||p1 p1,p2text||': '||p2 p2,p3text||': '||p3 p3
from gv$active_session_history
where to_char(sample_time,'Mondd_hh24mi') in (select
to_char(sample_time,'Mondd_hh24mi')
from gv$active_session_history
where event like '%drm freeze%'
group by to_char(sample_time,'Mondd_hh24mi'), inst_id
having sum(time_waited)/1000 > &&threshold)
and time_waited > 0.5
order by 1,2,3,4,5;

spool off

PROMPT
PROMPT OUTPUT FILE IS: drmdiag_&&dbname&&timestamp&&suffix
PROMPT
