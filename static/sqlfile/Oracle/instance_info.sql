select
'db_check_instance_info' as "db_check_instance_info",
instance_number inst_id,
instance_name,
host_name,
to_char(startup_time,'yyyy-mm-dd hh24:mi:ss') startup_time,
status
from gv$instance order by instance_number;