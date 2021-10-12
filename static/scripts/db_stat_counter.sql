
select inst_id, name, value
from
    (
        select ss.inst_id
        ,      sn.name
        ,      ss.value
        from   v$statname sn
        ,      gv$sysstat  ss
        where  sn.statistic# = ss.statistic#
        and    sn.name in (
        'execute count', 'logons cumulative','user logons cumulative','user logouts cumulative',
        'parse count (hard)', 'parse count (total)', 'parse count (failures)',
        'physical read total IO requests', 'physical read total bytes',
        'physical write total IO requests', 'physical write total bytes',
        'redo size', --'session cursor cache hits',
        'session logical reads', 'user calls', 'user commits', 'user rollbacks',
        'gc cr blocks received','gc current blocks received',
        'gc cr block receive time', 'gc current block receive time')
        union all
        select 
              inst_id, stat_name, round(value/1e6,2)
        from GV$SYS_TIME_MODEL where stat_name in ('DB time', 'DB CPU', 'background cpu time', 'RMAN cpu time (backup/restore)')
        union all
        select inst_id
        ,      STAT_NAME
        ,      VALUE
        from gv$osstat
        where STAT_NAME in ('BUSY_TIME','IDLE_TIME','LOAD')
        union all
        select
          (select min(INSTANCE_NUMBER) from gv$instance),
          'SCN GAP Per Minute',
          current_scn
        from v$database
    )
order by 1,2;
