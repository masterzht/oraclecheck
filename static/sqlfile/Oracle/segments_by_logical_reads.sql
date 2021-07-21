-- 6.6 segments by logical reads
select
       'db_check_' as "db_check_",
       n.owner
     , n.tablespace_name
     , n.object_name
     , case when length(n.subobject_name) < 11 then
              n.subobject_name
            else
              substr(n.subobject_name,length(n.subobject_name)-9)
       end subobject_name
     , n.object_type
     , r.logical_reads
     , substr(to_char(r.ratio * 100,'999.9MI'), 1, 5) ratio
  from wrh$_seg_stat_obj n
     , (select *
          from (select e.dataobj#
                     , e.obj#
                     , e.ts#
                     , e.dbid
                     , e.LOGICAL_READS_TOTAL - nvl(b.LOGICAL_READS_TOTAL, 0) logical_reads
                     , ratio_to_report(e.LOGICAL_READS_TOTAL - nvl(b.LOGICAL_READS_TOTAL, 0)) over () ratio
                  from wrh$_seg_stat e
                     , wrh$_seg_stat b
                 where b.snap_id                                 = (select max(snap_id) -1 as bid from dba_hist_snapshot)
                   and e.snap_id                                 = (select max(snap_id) as bid from dba_hist_snapshot)
                   and b.instance_number                         = (select instance_number from v$instance)
                   and e.instance_number                         = (select instance_number from v$instance)
                   and b.ts#(+)                                  = e.ts#
                   and b.obj#(+)                                 = e.obj#
                   and b.dataobj#(+)                             = e.dataobj#
                   and e.LOGICAL_READS_TOTAL - nvl(b.LOGICAL_READS_TOTAL, 0) > 0
                 order by logical_reads desc) d
          where rownum <= 10) r
 where n.dataobj# = r.dataobj#
   and n.obj#     = r.obj#
   and n.ts#      = r.ts#
   order by logical_reads desc;