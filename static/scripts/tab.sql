set timing off
set serveroutput on
set feedback off
set verify off
set linesize 500
undefine table_name
undefine owner
var table_name varchar2(100);
var owner varchar2(100);
alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
begin
  :owner :=upper('&owner');
  :table_name := upper('&table_name');
end;
/
declare
    v_cnt number;
    v_open_mode varchar2(100) :=null;
    v_protection_mode  varchar2(100) :=null;
    v_switchover  varchar2(100) :=null;
    v_force_logging varchar2(100) :=null;

    cursor c_seg is select sum(bytes/1024/1024/1024) G ,partition_name from dba_segments where segment_name = upper(:table_name) and owner = upper(:owner) 
group by partition_name order by partition_name;
    v_seg c_seg%rowtype;
    cursor c_stats is SELECT 
 A.COLUMN_NAME,
     decode(t.DATA_TYPE,
           'NUMBER',t.DATA_TYPE||'('||
           decode(t.DATA_PRECISION,
                  null,t.DATA_LENGTH||')',
                  t.DATA_PRECISION||','||t.DATA_SCALE||')'),
                  'DATE',t.DATA_TYPE,
                  'LONG',t.DATA_TYPE,
                  'LONG RAW',t.DATA_TYPE,
                  'ROWID',t.DATA_TYPE,
                  'MLSLABEL',t.DATA_TYPE,
                  t.DATA_TYPE||'('||t.DATA_LENGTH||')') ||' '||
    decode(t.nullable,
              'N','NOT NULL',
              'n','NOT NULL',
              NULL) col1,
 B.NUM_ROWS,  
 T.NUM_NULLS, 
 round(100 * T.DENSITY,2) as DENSITY,
 A.NUM_DISTINCT CARDINALITY,
 ROUND(A.NUM_DISTINCT / decode(B.NUM_ROWS,0,1,B.NUM_ROWS) * 100, 2) SELECTIVITY,
 A.HISTOGRAM,
 A.NUM_BUCKETS, 
 decode(T.SAMPLE_SIZE,null,0,T.SAMPLE_SIZE) as SAMPLE_SIZE,
 T.GLOBAL_STATS,
 T.USER_STATS,
 decode(to_char(T.last_analyzed,'YYYYMMDD HH24:MI'),null,'None',to_char(T.last_analyzed,'YYYYMMDD HH24:MI')) as last1
  FROM DBA_TAB_COL_STATISTICS A, DBA_TABLES B,dba_tab_columns T
 WHERE A.OWNER = B.OWNER and A.OWNER = T.OWNER 
   and A.TABLE_NAME = T.TABLE_NAME
   AND A.TABLE_NAME = B.TABLE_NAME
   AND T.COLUMN_NAME = A.COLUMN_NAME
   AND A.TABLE_NAME = upper(:table_name) and a.owner = upper(:owner) order by A.OWNER,A.COLUMN_NAME;
   v_stats c_stats%rowtype;

   cursor c_p_s is 
 SELECT
 A.PARTITION_NAME,
 A.COLUMN_NAME,
     decode(t.DATA_TYPE,
           'NUMBER',t.DATA_TYPE||'('||
           decode(t.DATA_PRECISION,
                  null,t.DATA_LENGTH||')',
                  t.DATA_PRECISION||','||t.DATA_SCALE||')'),
                  'DATE',t.DATA_TYPE,
                  'LONG',t.DATA_TYPE,
                  'LONG RAW',t.DATA_TYPE,
                  'ROWID',t.DATA_TYPE,
                  'MLSLABEL',t.DATA_TYPE,
                  t.DATA_TYPE||'('||t.DATA_LENGTH||')') ||' '||
    decode(t.nullable,
              'N','NOT NULL',
              'n','NOT NULL',
              NULL) col1,
 B.NUM_ROWS,
 A.NUM_NULLS,
 round(100 * A.DENSITY,2) as DENSITY,
 A.NUM_DISTINCT CARDINALITY,
 ROUND(A.NUM_DISTINCT / decode(B.NUM_ROWS,0,1,B.NUM_ROWS) * 100, 2) SELECTIVITY,
 A.HISTOGRAM,
 A.NUM_BUCKETS,
 decode(A.SAMPLE_SIZE,null,0,A.SAMPLE_SIZE) as SAMPLE_SIZE,
 A.GLOBAL_STATS,
 A.USER_STATS,
 decode(to_char(A.last_analyzed,'YYYYMMDD HH24:MI'),null,'None',to_char(A.last_analyzed,'YYYYMMDD HH24:MI')) as last1
  FROM dba_PART_COL_STATISTICS A, dba_tab_partitions B,dba_tab_columns T
 WHERE A.OWNER = B.TABLE_OWNER and A.OWNER = T.OWNER
   and A.TABLE_NAME = T.TABLE_NAME
   and A.TABLE_NAME = B.TABLE_NAME
   AND A.PARTITION_NAME = B.PARTITION_NAME
   AND T.COLUMN_NAME = A.COLUMN_NAME
   AND A.TABLE_NAME = upper('HASH_TABLE') 
   and a.owner = upper('SCOTT') order by A.PARTITION_NAME,A.OWNER,A.COLUMN_NAME;
   ips c_p_s%rowtype;


   cursor c_hwm is SELECT table_name,
                          ROUND((blocks * (select value from v$parameter where name='db_block_size'))/1024/1024, 2) "HWM",
                          ROUND ((num_rows * avg_row_len / 1024/ 1024 ), 2) as REAL_USED,
                          ROUND ((blocks * (select pct_free  from dba_tables where table_name = :table_name and rownum = 1) / 100) * 8 /1024, 2) "PCT_FREE",
   ROUND ( (blocks * 8 - (num_rows * avg_row_len / 1024) - blocks * 8 * 10 / 100) /1024, 2) "WASTE_SPACE"
   FROM dba_tables
   WHERE temporary = 'N' and table_name = :table_name
   ORDER BY 5 DESC;

   v_hwm c_hwm%rowtype;
   
   cursor c_sta is select 
    table_name,
    blocks,
    empty_blocks,
    avg_space,
    chain_cnt,
    avg_row_len,
      case when PARTITION_NAME is null then 'Current Table' else PARTITION_NAME end as PARTITION_NAME ,
      case when PARTITION_POSITION is null then 'Current Table' else to_char(PARTITION_POSITION) end as PARTITION_POSITION,
    stale_stats,
    last_analyzed
    from dba_tab_statistics where owner = upper(:owner) and table_name = upper(:table_name);
   v_sta c_sta%rowtype;
   
   cursor c_modi is select b.INSERTS,b.UPDATES,b.DELETES,b.TIMESTAMP
   from dba_tab_modifications b 
   where b.table_name = upper(:table_name) and b.table_owner = upper(:owner) order by b.timestamp;
   v_modi c_modi%rowtype; 
   
   cursor c_tab_partitions is select T.PARTITION_POSITION,T.PARTITION_NAME,
                               T.HIGH_VALUE ,
                               case when t.NUM_ROWS is null then 'None' else to_char(t.NUM_ROWS) end as NUM_ROWS,
                               case when T.SAMPLE_SIZE is null then 0 else t.SAMPLE_SIZE end as SAMPLE_SIZE,
                               case when to_char(t.last_analyzed,'YYYYMMDD') is null then 'None' else to_char(t.last_analyzed,'YYYYMMDD') end as last_analyzed,
                               round(S.G,2) as G,
                               t.subpartition_count as subpartition_cnt,t.COMPRESSION
   from dba_tab_partitions t, (select sum(bytes/1024/1024/1024) G ,partition_name from dba_segments where segment_name = upper(:table_name) and owner = upper(:owner) 
   group by partition_name) s 
   where s.partition_name = t.PARTITION_NAME
   and table_owner = upper(:owner)
   and table_name = upper(:table_name)
   order by t.partition_position;
   v_tab_pars c_tab_partitions%rowtype;
   cursor c_j is 
SELECT c.name                                                   as column_name,
       decode(to_char(cu.timestamp,'yyyymmdd hh24:mi:ss'),null,'None',to_char(cu.timestamp,'yyyymmdd hh24:mi:ss'))            as timestamp,
       decode(cu.equality_preds,null,0,cu.equality_preds)       as where_equal_search,
       decode(cu.equijoin_preds,null,0,cu.equijoin_preds)       as equal_join,
       decode(cu.nonequijoin_preds,null,0,cu.nonequijoin_preds) as none_equal_join,
       decode(cu.range_preds,null,0,cu.range_preds)             as where_range_search,
       decode(cu.like_preds,null,0,cu.like_preds)               as where_like_search,
       decode(cu.null_preds,null,0,cu.null_preds)               as where_null_search
FROM sys.col$ c, sys.col_usage$ cu, sys.obj$ o, sys.user$ u
WHERE c.obj# = cu.obj# (+)
AND c.intcol# = cu.intcol# (+)
AND c.obj# = o.obj#
AND o.owner# = u.user#
AND o.name = :table_name
AND u.name = :owner
ORDER BY c.col#;
    v_j c_j%rowtype;

    cursor c_his_t is 
    select 
    h.savtime, 
    h.rowcnt, h.blkcnt, h.avgrln, h.analyzetime from sys.wri$_optstat_tab_history h,dba_objects t 
where t.OBJECT_ID = h.obj# and t.object_name = :table_name;
    v_his_t c_his_t%rowtype;
    
begin
  dbms_output.enable(buffer_size=>NULL);
  select count(*) into v_cnt from dba_segments where segment_name = upper(:table_name) and owner = upper(:owner);
  
if v_cnt = 1 then


  dbms_output.put_line('
Non partitioned Table Segment Information');
  dbms_output.put_line('======================');
  open c_seg;
    loop fetch c_seg into v_seg;
    exit when c_seg%notfound;
    dbms_output.put_line('TABLE_NAME : '|| :TABLE_NAME  || '  |  ' || 'SEGMENT_SIZE : '|| round(v_seg.g,2));
    end loop;
  close c_seg;
  

  dbms_output.put_line('
Non partitioned Table HWM Information basic Statistics');
  dbms_output.put_line('======================');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------');
  dbms_output.put_line('| HWM(MB)            |' || ' REAL_USED(MB)      ' || '| PCT_FREE_NEED_SPACE(MB)  |' || ' WASTE_SPACE(MB)        ' || '|');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------');
  open c_hwm;
    loop fetch c_hwm into v_hwm;
    exit when c_hwm%notfound;
    dbms_output.put_line('| ' || lpad(v_hwm.HWM,18) ||' | '|| lpad(v_hwm.REAL_USED,18) || ' | '|| lpad(v_hwm.PCT_FREE,24) || ' | '|| lpad(v_hwm.WASTE_SPACE,22) || ' |');
    end loop;
    dbms_output.put_line('-----------------------------------------------------------------------------------------------');
  close c_hwm;


  dbms_output.put_line('
SELECT% Means SELECTIVITY
GST Means GLOBAL_STATS
UST Means USER_STATS
Non partitioned Table Statistics Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| COLUMN_NAME          |' || ' COLUMN_DETAIL        | ' ||' NUM_ROWS   |' || ' NUM_NULLS   |'|| ' DENSITY ' || '| CARDINALITY |' || ' SELECT% ' || '| HISTOGRAM |' || ' NUM_BUCKETS' || ' | SAMPLE_SIZE |'|| ' GST ' || '| UST ' ||'|');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_stats;
    loop fetch c_stats into v_stats;
    exit when c_stats%notfound;
    dbms_output.put_line('| ' || rpad(v_stats.COLUMN_NAME,20) ||' | '|| rpad(v_stats.COL1,20)  ||' | '|| lpad(v_stats.NUM_ROWS,11) || ' | '|| lpad(v_stats.NUM_NULLS,11) || ' | ' || lpad(v_stats.DENSITY,7) ||' | '|| lpad(v_stats.CARDINALITY,11) || ' | '|| lpad(v_stats.SELECTIVITY || '%',7) || ' | '|| lpad(v_stats.HISTOGRAM,9) || ' | '|| lpad(v_stats.NUM_BUCKETS,11) ||' | ' || lpad(v_stats.SAMPLE_SIZE,11) ||' | ' || lpad(v_stats.GLOBAL_STATS,3)|| ' | ' || lpad(v_stats.USER_STATS,3) || ' |');
    end loop;
    dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_stats;


  dbms_output.put_line('
Non partitioned Table Statistics STALE_STATS, Yes Means Expired');
  dbms_output.put_line('======================');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| TABLE_NAME           |' || ' STALE_STATS |' || ' LAST_ANALYZED       ' || '| BLOCKS     |' || ' EMPTY_BLOCKS ' || '| AVG_SPACE  |' || ' CHAIN_CNT    ' || '| AVG_ROW_LEN  ' || '|');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------');
  open c_sta;
    loop fetch c_sta into v_sta;
    exit when c_sta%notfound;
    dbms_output.put_line('| ' || rpad(v_sta.TABLE_NAME,20) || ' | ' || lpad(v_sta.STALE_STATS,11) ||' | '|| lpad(v_sta.LAST_ANALYZED,19) || ' | ' || lpad(v_sta.BLOCKS,10) || ' | ' || lpad(v_sta.EMPTY_BLOCKS,12) || ' | ' || lpad(v_sta.AVG_SPACE,10) || ' | ' || lpad(v_sta.CHAIN_CNT,12) || ' | ' || lpad(v_sta.AVG_ROW_LEN,12) ||  ' |');
    end loop;
    dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------');
  close c_sta;


  dbms_output.put_line('
Non partitioned Table Modification,Stats Expired Reason Information(dba_tab_modifications)');
  dbms_output.put_line('======================');
  dbms_output.put_line('-----------------------------------------------------------------------');
  dbms_output.put_line('|'  || ' INSERTS          |' || ' UPDATES      ' || '| DELETES      |' || ' TIMESTAMP          ' || '|');
  dbms_output.put_line('-----------------------------------------------------------------------');
  open c_modi;
    dbms_stats.flush_database_monitoring_info;
    loop fetch c_modi into v_modi;
    exit when c_modi%notfound;
    dbms_output.put_line('| ' || lpad(v_modi.INSERTS,16) ||' | '|| lpad(v_modi.UPDATES,12) || ' | '|| lpad(v_modi.DELETES,12) || ' | '|| v_modi.TIMESTAMP || '|');
    end loop;
    dbms_output.put_line('-----------------------------------------------------------------------');
  close c_modi;


  dbms_output.put_line('
Count the number of occurrences for Join or Where');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| COLUMN_NAME           |' || ' TIMESTAMP         |' || ' where = search ' || '| = join |' || ' <> join ' || '| where_range_search |' || ' where_like_search ' || '| where_null_search ' || '|');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_stats.flush_database_monitoring_info;
  open c_j;
    loop fetch c_j into v_j;
    exit when c_j%notfound;
    dbms_output.put_line('| ' || rpad(v_j.column_name,21) || ' | ' || rpad(v_j.timestamp,17) ||' | '|| lpad(v_j.where_equal_search,14) || ' | ' || lpad(v_j.equal_join,6) || ' | ' || lpad(v_j.none_equal_join,7) || ' | ' || lpad(v_j.where_range_search,18) || ' | ' || lpad(v_j.where_like_search,17) || ' | ' || lpad(v_j.where_null_search,17) ||  ' |');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------');
  close c_j;

  else 
  dbms_output.put_line('
Partition Table Segment Information');
  dbms_output.put_line('======================');
  
    open c_tab_partitions;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
    dbms_output.put_line('| POSITION |' || ' PARTITION_NAME    ' || '| HIGH_VALUE                                                   |' || ' NUM_ROWS    ' || '| SAMPLE_SIZE |' || ' PART_SIZE(G) '|| '| SUBPART_CNT |' || ' COMPRESSION ' ||'|');
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
    loop fetch c_tab_partitions into v_tab_pars;
    exit when c_tab_partitions%notfound;
    dbms_output.put_line('| '|| rpad(v_tab_pars.PARTITION_POSITION,8) || ' | ' || rpad(v_tab_pars.partition_name,17) || ' | ' || rpad(v_tab_pars.HIGH_VALUE ||'.',60) || ' | ' || lpad(v_tab_pars.NUM_ROWS,11) || ' | ' || lpad(v_tab_pars.SAMPLE_SIZE,11) || ' | ' || lpad(v_tab_pars.g,12) || ' | ' || lpad(v_tab_pars.subpartition_cnt,11) ||  ' | ' || lpad(v_tab_pars.compression,11) || ' |');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_tab_partitions;


  dbms_output.put_line('
Partition Table Statistics Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| PARTITION_NAME       ' || '| COLUMN_NAME          |' ||  ' COLUMN_TYPE             |'  || ' NUM_ROWS      ' || '| NUM_NULLS     ' || '| DENSITY ' || '| CARDINALITY |' || ' SELECTIVITY ' || '| HISTOGRAM      |' || ' NUM_BUCKETS ' || '| SAMPLE_SIZE |' || ' GLOBAL_STATS ' || '| USER_STATS |' || ' LAST_ANALYZED  ' || '|');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_p_s;
    loop fetch c_p_s into ips;
    exit when c_p_s%notfound;
    dbms_output.put_line('| ' || rpad(ips.PARTITION_NAME,20)||' | '|| rpad(ips.COLUMN_NAME,20) ||' | '|| rpad(ips.col1,23) ||' | '||lpad(ips.NUM_ROWS,13)|| ' | '||lpad(ips.NUM_NULLS,13)|| ' | '|| lpad(ips.DENSITY,7)|| ' | '|| lpad(ips.CARDINALITY,11) || ' | '|| lpad(ips.SELECTIVITY || '%',11) || ' | '|| rpad(ips.HISTOGRAM,14) || ' | '|| lpad(ips.NUM_BUCKETS,11) || ' | '||lpad(ips.SAMPLE_SIZE,11) || ' | '|| lpad(ips.GLOBAL_STATS,12) || ' | '|| lpad(ips.USER_STATS,10) || ' | '|| rpad(ips.last1,15) || '|');
    end loop;
    dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_p_s;

  dbms_output.put_line('
Partitioned Table Statistics STALE_STATS, Yes Means Expired from dba_tab_statistics');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------------------------------------');
  dbms_output.put_line('| PARTITION_NAME        |' || ' PARTITION_POSITION ' || '| STALE_STATS |' || ' LAST_ANALYZED       ' || '|');
  dbms_output.put_line('----------------------------------------------------------------------------------');
  open c_sta;
    loop fetch c_sta into v_sta;
    exit when c_sta%notfound;
    dbms_output.put_line('| ' || lpad(v_sta.partition_name,21)|| ' | ' || lpad(v_sta.partition_position,18) || ' | ' ||lpad(v_sta.STALE_STATS,11) ||' | '|| v_sta.LAST_ANALYZED || ' |');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------');
  close c_sta;


  dbms_output.put_line('
Partitione Table Modification Information(dba_tab_modifications)');
  dbms_output.put_line('======================');
  dbms_output.put_line('-----------------------------------------------------------------------');
  dbms_output.put_line('|'  || ' INSERTS          |' || ' UPDATES      ' || '| DELETES      |' || ' TIMESTAMP          ' || '|');
  dbms_output.put_line('-----------------------------------------------------------------------');
  open c_modi;
    loop fetch c_modi into v_modi;
    exit when c_modi%notfound;
    dbms_output.put_line('| ' || lpad(v_modi.INSERTS,16) ||' | '|| lpad(v_modi.UPDATES,12) || ' | '|| lpad(v_modi.DELETES,12) || ' | '|| v_modi.TIMESTAMP || '|');
    end loop;
    dbms_output.put_line('-----------------------------------------------------------------------');
  close c_modi;

  dbms_output.put_line('
Count the number of occurrences for Join or Where');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| COLUMN_NAME           |' || ' TIMESTAMP         |' || ' where = search ' || '| = join |' || ' <> join ' || '| where_range_search |' || ' where_like_search ' || '| where_null_search ' || '|');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_stats.flush_database_monitoring_info;
  open c_j;
    loop fetch c_j into v_j;
    exit when c_j%notfound;
    dbms_output.put_line('| ' || rpad(v_j.column_name,21) || ' | ' || rpad(v_j.timestamp,17) ||' | '|| lpad(v_j.where_equal_search,14) || ' | ' || lpad(v_j.equal_join,6) || ' | ' || lpad(v_j.none_equal_join,7) || ' | ' || lpad(v_j.where_range_search,18) || ' | ' || lpad(v_j.where_like_search,17) || ' | ' || lpad(v_j.where_null_search,17) ||  ' |');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------');
  close c_j;

  dbms_output.put_line('
HWM Information Rely on Table Statistics');
  dbms_output.put_line('======================');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| OWNER                 |' || ' TABLE_NAME                       |' || ' SEGMENT_TYPE   ' || '| SEGMENT_MB     |' || ' WASTER% ' || '|');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------');

end if;
end;
/


--Table stats
/**
prompt ***************
prompt SubPartition Level
prompt ***************
prompt dba_tab_subpartitions
select
 PARTITION_NAME,SUBPARTITION_NAME,NUM_ROWS,BLOCKS,EMPTY_BLOCKS,AVG_SPACE,CHAIN_CNT,
 AVG_ROW_LEN,GLOBAL_STATS,USER_STATS,SAMPLE_SIZE,to_char(t.last_analyzed,'MM-DD-YYYY')
from
    dba_tab_subpartitions t
where
    table_owner = upper(nvl(:owner,user))
and table_name = upper(:table_name)
order by SUBPARTITION_POSITION
/
break on partition_name

prompt dba_tab_subpartitions,dba_subpart_col_statistics
select
 p.PARTITION_NAME,t.SUBPARTITION_NAME,t.COLUMN_NAME,t.NUM_DISTINCT,t.DENSITY,
 t.NUM_BUCKETS,t.NUM_NULLS,t.GLOBAL_STATS,t.USER_STATS,t.SAMPLE_SIZE,to_char(t.last_analyzed,'MM-DD-YYYY')
from
    dba_SUBPART_COL_STATISTICS t,dba_tab_subpartitions p
where
    t.table_name = :table_name
and t.owner = upper(nvl(:owner,user))
and t.subpartition_name = p.subpartition_name
and t.owner = p.table_owner
and t.table_name=p.table_name
/

prompt dba_ind_subpartitions,dba_indexes
break on partition_name
select
  t.INDEX_NAME,t.PARTITION_NAME,t.SUBPARTITION_NAME,t.BLEVEL BLev,t.LEAF_BLOCKS,t.DISTINCT_KEYS,t.NUM_ROWS,t.AVG_LEAF_BLOCKS_PER_KEY,
 t.AVG_DATA_BLOCKS_PER_KEY,t.CLUSTERING_FACTOR,t.GLOBAL_STATS,t.USER_STATS,t.SAMPLE_SIZE,to_char(t.last_analyzed,'MM-DD-YYYY')
from
    dba_ind_subpartitions t,dba_indexes i
where
    i.table_name = :table_name
and i.table_owner = upper(nvl(:owner,user))
and i.owner = t.index_owner
and i.index_name=t.index_name
/
**/

