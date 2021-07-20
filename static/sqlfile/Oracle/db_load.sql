select
       'db_check_db_top' as "db_check_db_top",
       inst_id,
       status ,
       count(*)
from gv$session
group by inst_id,status
order by inst_id,status;