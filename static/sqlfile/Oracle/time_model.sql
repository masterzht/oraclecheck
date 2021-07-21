-- 6.3 time_model
select * from (
select 'db_check_' as "db_check_",
       n.stat_name as "Statistic Name",
       round((e.value - b.value) / 1000 / 1000, 2) as "Time (s)",
       round(((e.value - b.value) *100 / 1000 / 1000) / (select (new.value-old.value)/1000/1000  from wrh$_sys_time_model new,
wrh$_sys_time_model old,wrh$_stat_name n
where new.snap_id = (select max(snap_id) as bid from dba_hist_snapshot)
and   old.snap_id = (select max(snap_id) -1 as bid from dba_hist_snapshot)
and  new.stat_id= n.stat_id
and new.stat_id=old.stat_id
and n.stat_name='DB time'
and new.instance_number = old.instance_number
and new.instance_number = (select instance_number from v$instance)) ,2) as "%DB_Time"
  from wrh$_sys_time_model e, wrh$_sys_time_model b, wrh$_stat_name n
 where e.stat_id = n.stat_id
   and b.stat_id = n.stat_id
   and e.snap_id = (select max(snap_id)  as bid from dba_hist_snapshot)
   and b.snap_id = (select max(snap_id) -1 as bid from dba_hist_snapshot)
   and e.instance_number = b.instance_number
   and n.stat_name not in ('background elapsed time','DB time','background cpu time')
   and e.instance_number = (select instance_number from v$instance)
   and e.value > b.value
 order by 3 desc
)
union all
 select 'db_check_' as "db_check_",
        n.stat_name ,
        round((e.value - b.value) / 1000 / 1000, 2) ,
        to_number(null)
  from wrh$_sys_time_model e, wrh$_sys_time_model b, wrh$_stat_name n
 where e.stat_id = n.stat_id
   and b.stat_id = n.stat_id
   and e.snap_id = (select max(snap_id)  as bid from dba_hist_snapshot)
   and b.snap_id = (select max(snap_id) -1 as bid from dba_hist_snapshot)
   and e.instance_number = b.instance_number
   and e.instance_number = (select instance_number from v$instance)
   and n.stat_name  in ('background elapsed time','DB time','background cpu time')
/




