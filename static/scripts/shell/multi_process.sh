#!/bin/bash
start=`date +%s`

for ((i=1;i<1000;i++))
do
 {
 	ltsql -p 10001 -d em -c """update lem_db_log set log_tsv= to_tsvector2(db_log_message||' instance_ip='||instance_ip||' instance_port='||instance_port||' timeline='||timeline||' db_log_type='||db_log_type||' db_log_level='||db_log_level
||' instance_ip=instance_port='||instance_ip||'='||instance_port||' application_name='||application_name||' database_name='||database_name||' backend_type='||replace(backend_type,' ','')) where id > 260000 * ($i -1) and id < 260000 * $i """
echo """ update lem_db_log set log_tsv= to_tsvector2(db_log_message||' instance_ip='||instance_ip||' instance_port='||instance_port||' timeline='||timeline||' db_log_type='||db_log_type||' db_log_level='||db_log_level
||' instance_ip=instance_port='||instance_ip||'='||instance_port||' application_name='||application_name||' database_name='||database_name||' backend_type='||replace(backend_type,' ','')) where id > 260000 * ($i -1) and id < 260000 * $i """
 } &
done
wait

end=`date "+%s"`
echo "Time: `expr $end - $start `"