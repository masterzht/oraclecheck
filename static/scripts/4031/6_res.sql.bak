column initial_size format 999999999999999
column target_size format 999999999999999
column final_size format 999999999999999

select to_char(end_time, 'dd-Mon-yyyy hh24:mi') end, oper_type, initial_size,
 target_size, final_size from V$SGA_RESIZE_OPS
 where component='shared pool'
 order by end;
