-- 7天内 日志切换频率
select 'db_check_log_frequency' as "db_check_log_frequency",
       a.INST_ID,
       trunc(min(((a.FIRST_TIME-b.FIRST_TIME)*24)*60)) as min_frequency_sec,
       trunc(avg(((a.FIRST_TIME-b.FIRST_TIME)*24)*60)) as avg_frequency_sec
from gv$log_history a, gv$log_history b
where a.INST_ID = b.INST_ID
  and a.SEQUENCE# = b.SEQUENCE#+1
  and a.FIRST_TIME > sysdate -7
group by a.INST_ID;