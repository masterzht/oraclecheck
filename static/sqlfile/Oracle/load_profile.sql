-- 6.2 load profile
select
'db_check_' as "db_check_",
decode(n.stat_name,'redo size','Redo Size:',
                          'physical reads','Physical reads:',
                          'physical writes','Physical writes:',
                          'db block changes','Block changes:',
                          'user calls','User Call:',
                          'session logical reads','Logical reads:',
                          'parse count (hard)','Hard parses:',
                          'parse count (total)','Parses:',
                          'sorts (disk)', 'Sorts (disk):',
                          'sorts (memory)','Sorts (memory):',
                          'logons cumulative','Logon:',
                          'user commits','Commits:',
                          'user rollbacks','Rollbacks:',
                          'execute count','Executes:'
                           ) as "Load",
       round((t.value - o.value) /
       (to_date(to_char(e.end_interval_time, 'yyyymmdd hh24:mi:ss'),
                'yyyymmdd hh24:mi:ss') -
       to_date(to_char(b.end_interval_time, 'yyyymmdd hh24:mi:ss'),
                'yyyymmdd hh24:mi:ss')) / 24 / 60 / 60,2) as " Per Second",
       round((t.value - o.value) / (  select (e.vv - b.vv)
    from (select sum(value) as vv
            from Wrh$_Sysstat
           where stat_id in
                 (select stat_id
                    from wrh$_stat_name
                   where stat_name in ('user rollbacks', 'user commits'))
             and instance_number = (select instance_number from v$instance)
             and snap_id = (select max(snap_id) as bid from dba_hist_snapshot)) e,
         (select sum(value) as vv
            from Wrh$_Sysstat
           where stat_id in
                 (select stat_id
                    from wrh$_stat_name
                   where stat_name in ('user rollbacks', 'user commits'))
             and instance_number = (select instance_number from v$instance)
             and snap_id = (select max(snap_id) -1 as bid from dba_hist_snapshot)) b),2) as " Per Trans"
  from wrh$_sysstat   t,
       wrh$_stat_name n,
       wrh$_sysstat   o,
       wrm$_snapshot  e,
       wrm$_snapshot  b
 where t.stat_id = o.stat_id
   and t.stat_id = n.stat_id
   and e.snap_id = t.snap_id
   and t.snap_id = (select max(snap_id) as bid from dba_hist_snapshot)
   and o.snap_id = (select max(snap_id) -1 as bid from dba_hist_snapshot)
   and b.snap_id = o.snap_id
   and t.instance_number = o.instance_number
   and t.instance_number = e.instance_number
   and t.instance_number = b.instance_number
   and t.instance_number = (select instance_number from v$instance)
   and n.stat_name in
       ('redo size', 'physical reads', 'physical writes', 'db block changes',
        'user calls', 'session logical reads', 'parse count (hard)',
        'parse count (total)', 'sorts (disk)', 'sorts (memory)',
        'execute count', 'logons cumulative','user commits', 'user rollbacks')
  order by 3 desc;

