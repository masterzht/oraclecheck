select cr_shared_pool_size,
sum_obj_size, sum_sql_size,
sum_user_size,
(sum_obj_size + sum_sql_size+sum_user_size)* 1.3 min_shared_pool
from (select sum(sharable_mem) sum_obj_size
from v$db_object_cache where type<> 'CURSOR'),
(select sum(sharable_mem) sum_sql_size from v$sqlarea),
(select sum(250*users_opening) sum_user_size from v$sqlarea),
(select to_Number(b.ksppstvl) cr_shared_pool_size
 from x$ksppi a, x$ksppcv b, x$ksppsv c
 where a.indx = b.indx and a.indx = c.indx
 and a.ksppinm ='__shared_pool_size' );
