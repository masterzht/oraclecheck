

select    sql_id,
    plan_hash_value,
    executions_delta,
    elp_time_per_exec,
    cpu_time_per_exec,
    rows_per_exec,
    lio_per_exec,
    disk_per_exec
from
(   select
    base.*,
    count(*) over (partition by sql_id) cnt,
    max(elp_time_per_exec) over (partition by sql_id) max_elp_time_per_exec
from
(   select
        x.sql_id,
        x.plan_hash_value,
        sum(x.executions_delta) executions_delta,
        round(sum(x.elapsed_time_delta)/decode(sum(x.executions_delta),0,1,sum(x.executions_delta))/1000000, 1) elp_time_per_exec,
        round(sum(x.cpu_time_delta)/decode(sum(x.executions_delta),0,1,sum(x.executions_delta))/1000000, 1) cpu_time_per_exec,
        round(sum(x.rows_processed_delta)/decode(sum(x.executions_delta),0,1,sum(x.executions_delta)), 1) rows_per_exec,
        trunc(sum(x.buffer_gets_delta)/decode(sum(x.executions_delta),0,1,sum(x.executions_delta))) lio_per_exec,
        trunc(sum(x.disk_reads_delta)/decode(sum(x.executions_delta),0,1,sum(x.executions_delta))) disk_per_exec,
        x.PARSING_SCHEMA_NAME
    from
        dba_hist_sqlstat x,
        dba_hist_snapshot s
    where
        s.instance_number=x.instance_number
    and s.snap_id = x.snap_id
    --and s.begin_interval_time >
    group by x.sql_id, x.plan_hash_value,x.PARSING_SCHEMA_NAME
    ) base )
where PARSING_SCHEMA_NAME = '&username'
and max_elp_time_per_exec > 1
and cnt > 1
order by max_elp_time_per_exec, elp_time_per_exec
/

prompt Plan Changed

/* I-AM-YUNQU-BUILTIN-SQL */
select sql_id,
       round(max(elapsed_time/decode(executions,0,1,executions))/min(elapsed_time/decode(executions,0,1,executions))) DIFF,
      min(inst_id) INST_ID
from
  gv$sql
where elapsed_time > 0 
  and parsing_schema_name not in ('SYS', 'YUNQU')
group by sql_id
having count(distinct plan_hash_value) > 1
   and round(max(elapsed_time/decode(executions,0,1,executions))/min(elapsed_time/decode(executions,0,1,executions))) > 100;
