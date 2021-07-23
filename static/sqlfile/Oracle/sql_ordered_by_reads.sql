select * from (
select 'db_check_' as "db_check_",ss.*
  from (select e.DISK_READS_TOTAL - nvl(b.DISK_READS_TOTAL, 0) as "Physical Reads",
               e.EXECUTIONS_TOTAL - nvl(b.EXECUTIONS_TOTAL, 0) as "Executions",
               round((e.DISK_READS_TOTAL - nvl(b.DISK_READS_TOTAL, 0)) *100/ (( select  (t.value - o.value)
  from wrh$_sysstat   t,
       wrh$_stat_name n,
       wrh$_sysstat   o,
       wrm$_snapshot  e,
       wrm$_snapshot  b
 where t.stat_id = o.stat_id
   and t.stat_id = n.stat_id
   and e.snap_id = t.snap_id
   and t.snap_id = (select max(snap_id) as bid from dba_hist_snapshot)
   and o.snap_id = (select max(snap_id) -1 as bid from dba_hist_snapshot)
   and b.snap_id = o.snap_id
   and t.instance_number = o.instance_number
   and t.instance_number = e.instance_number
   and t.instance_number = b.instance_number
   and t.instance_number = (select instance_number from v$instance)
   and n.stat_name='physical reads')+1) ,2)as "%Total",
               round((e.ELAPSED_TIME_TOTAL - b.ELAPSED_TIME_TOTAL) / 1000 / 1000 ,
                     2) as "Elapsed Time (s)",
               e.sql_id as "SQL_ID",
               e.module as "Module",
               dbms_lob.substr(st.sql_text, 40, 1) as "SQL_TEXT"
          from wrh$_sqlstat e, wrh$_sqlstat b, wrh$_sqltext st
         where b.snap_id = (select max(snap_id) -1 as bid from dba_hist_snapshot)
           and b.instance_number = e.instance_number
           and b.sql_id = e.sql_id
           and e.snap_id = (select max(snap_id) as bid from dba_hist_snapshot)
           and e.instance_number = (select instance_number from v$instance)
           and e.sql_id = st.sql_id
           and e.DISK_READS_TOTAL > b.DISK_READS_TOTAL
           and e.executions_total > b.executions_total
        union all
        select e.DISK_READS_TOTAL,
               e.EXECUTIONS_TOTAL,
               round(e.ELAPSED_TIME_TOTAL / 1000000, 2),
               round(e.DISK_READS_TOTAL*100 / ( select  (t.value - o.value)
  from wrh$_sysstat   t,
       wrh$_stat_name n,
       wrh$_sysstat   o,
       wrm$_snapshot  e,
       wrm$_snapshot  b
 where t.stat_id = o.stat_id
   and t.stat_id = n.stat_id
   and e.snap_id = t.snap_id
   and t.snap_id = (select max(snap_id) as bid from dba_hist_snapshot)
   and o.snap_id = (select max(snap_id) -1 as bid from dba_hist_snapshot)
   and b.snap_id = o.snap_id
   and t.instance_number = o.instance_number
   and t.instance_number = e.instance_number
   and t.instance_number = b.instance_number
   and t.instance_number = (select instance_number from v$instance)
   and n.stat_name='physical reads'),2),
               e.sql_id,
               e.module,
               dbms_lob.substr(t.sql_text, 40, 1) as "SQL_TEXT"
          from wrh$_sqlstat e, wrh$_sqltext t
         where e.sql_id in
               (select sql_id
                  from wrh$_sqlstat
                 where snap_id = (select max(snap_id) as bid from dba_hist_snapshot)
                 and instance_number = (select instance_number from v$instance)
                minus
                select sql_id from wrh$_sqlstat where snap_id < (select max(snap_id) -1 as bid from dba_hist_snapshot)
                and instance_number = (select instance_number from v$instance))
           and e.sql_id = t.sql_id
           and e.instance_number = (select instance_number from v$instance)) ss
 order by 1 desc
 ) where rownum<=10;