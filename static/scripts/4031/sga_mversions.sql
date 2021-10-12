select sa.sql_text,sa.version_count,ss.*
from v$sqlarea sa,v$sql_shared_cursor ss 
where sa.address=ss.address 
and sa.version_count > 50 
order by sa.version_count;
