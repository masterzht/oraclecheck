select
       'db_check_redo' as "db_check_redo",
       a.thread# as thread,
       a.group# as groups,
       round(a.bytes/1024/1024/1024,2) as bytes_gb,
       b.member
from v$log a,gv$Logfile b
where a.thread#=b.inst_id
and b.group#=a.group#;