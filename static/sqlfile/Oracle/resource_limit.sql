select
     'db_check_' as "db_check_",
       INST_ID,
       RESOURCE_NAME ,
       CURRENT_UTILIZATION ,
       MAX_UTILIZATION ,
       INITIAL_ALLOCATION ,
       LIMIT_VALUE
 from
     gv$resource_limit
where
     (resource_name in ('processes','sessions','max_rollback_segments','max_shared_servers','parallel_max_servers')
         or resource_name like 'ges%'
         or resource_name like 'gcs%') order by RESOURCE_NAME,INST_ID;