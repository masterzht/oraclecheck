 select
 'db_check_memory_info' as "db_check_memory_info",
 gi.instance_number inst_id,
 (select round(bytes/1073741824,1) from gv$sgainfo where inst_id = gi.instance_number and NAME='Maximum SGA Size') Maximum_SGA,
 (select round(bytes/1073741824,1) from gv$sgainfo where inst_id = gi.instance_number and NAME='Free SGA Memory Available') FREE_SGA,
 (select round(bytes/1073741824,1) from gv$sgainfo where inst_id = gi.instance_number and NAME='Redo Buffers') REDO_BUFFER,
 (select round(bytes/1073741824,1) from gv$sgainfo where inst_id = gi.instance_number and NAME='Buffer Cache Size') BUFFER_CACHE,
 (select round(bytes/1073741824,1) from gv$sgainfo where inst_id = gi.instance_number and NAME='Shared Pool Size') SHARED_POOL
 from gv$instance gi;