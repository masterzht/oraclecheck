SELECT
       'db_check_' as "db_check_",
       decode(name,null,'None',name) as recovery_dest,
       trunc(space_limit/1024/1024) || 'MB' TOTAL_MB,
       trunc(space_used/1024/1024) || 'MB'USED_MB,
       decode(space_limit,0,0,(space_used - SPACE_RECLAIMABLE) / space_limit * 100) || '%' as used_pct
FROM v$recovery_file_dest;