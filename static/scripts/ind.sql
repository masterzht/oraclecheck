
set serveroutput on 
set verify off
set timing off
set linesize 500
set pages 0

undefine table_name
undefine owner
var table_name varchar2(100);
var owner varchar2(100);

begin
  :owner :=upper('&owner');
  :table_name := upper('&table_name');
end;
/

--alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
declare
    v_part_cnt number;
  cursor c_constraints is select 
   a.owner,
   a.table_name,
   a.constraint_name,
   b.column_name,
   lpad(a.constraint_type,10) as constraint_type,
   decode(a.index_name,null,'nil',a.index_name) as index_name,
   a.status 
  from all_constraints a,all_cons_columns b
  where a.owner = b.owner
    and a.constraint_name = b.constraint_name
    and a.table_name = :table_name;
  v_constraints c_constraints%rowtype;


    cursor c_i is SELECT 
       A.INDEX_NAME,
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
                  NULL) col_type,
       A.COLUMN_POSITION,decode(b.TABLESPACE_NAME,null,'None',B.TABLESPACE_NAME) as TABLESPACE_NAME,B.INDEX_TYPE,B.DEGREE,
       round(C.BYTES / 1024 / 1024) AS INDEX_MB,
       A.DESCEND,
       case when B.STATUS = 'UNUSABLE' then 'NO' else 'YES' end USABLE,
       decode(to_char(B.last_analyzed,'yymmdd hh24:mi'),null,'None',
       to_char(b.last_analyzed,'yymmdd hh24:mi')) as last_analyzed,
       case when b.visibility = 'VISIBLE' then 'YES' else 'NO ' end visibility,
       case when uniqueness = 'UNIQUE' then 'YES' else 'NO ' end UNIQUENESS,
       B.CLUSTERING_FACTOR
  FROM DBA_IND_COLUMNS A, DBA_INDEXES B, DBA_SEGMENTS C ,DBA_TAB_COLUMNS T
 WHERE A.INDEX_NAME = B.INDEX_NAME
   AND T.TABLE_NAME = A.TABLE_NAME
   AND A.COLUMN_NAME = T.COLUMN_NAME 
   AND A.TABLE_NAME = :table_name
   AND a.INDEX_OWNER = :owner
   AND C.SEGMENT_NAME = A.INDEX_NAME
 ORDER BY INDEX_NAME, COLUMN_POSITION;
    v_i c_i%rowtype;

    cursor c_foreign_key_without_index is select owner,
                                                 table_name,
                                                 constraint_name,
                                                 substr(cname1 || nvl2(cname2,','||cname2,null) || nvl2(cname3,','||cname3,null) || nvl2(cname4,','||cname4,null) || nvl2(cname5,','||cname5,null) || nvl2(cname6,','||cname6,null) || nvl2(cname7,','||cname7,null) || nvl2(cname8,','||cname8,null),0,400) as cols
  from ( select b.owner,
                b.table_name,
                b.constraint_name,
                max(decode( position, 1, column_name, null )) cname1,
                max(decode( position, 2, column_name, null )) cname2,
                max(decode( position, 3, column_name, null )) cname3,
                max(decode( position, 4, column_name, null )) cname4,
                max(decode( position, 5, column_name, null )) cname5,
                max(decode( position, 6, column_name, null )) cname6,
                max(decode( position, 7, column_name, null )) cname7,
                max(decode( position, 8, column_name, null )) cname8,
                count(*) col_cnt
           from (select owner,
                        constraint_name,
                        column_name,
                        position
                   from dba_cons_columns where owner not in ('SYSTEM','OWBSYS','XS$NULL','FLOWS_FILES','WMSYS','DIP','XDB','SYS','ANONYMOUS','QMONITOR','ORDPLUGINS','OUTLN','ORDSYS','SI_INFORMTN_SCHEMA',
                    'ORDDATA','OJVMSYS','SPATIAL_WFS_ADMIN_USR','MDSYS','LBACSYS','SPATIAL_CSW_ADMIN_USR','DVSYS','DBSNMP','APEX_PUBLIC_USER',
                    'APPQOSSYS','APEX_040200','ORACLE_OCM','AUDSYS','CTXSYS','MDDATA','APEX_030200','EXFSYS','MGMT_VIEW','OLAPSYS','SYSMAN','OWBSYS_AUDIT',
'WH_SYNC','GSMADMIN_INTERNAL')) a,
                dba_constraints b
          where a.constraint_name = b.constraint_name
            and b.constraint_type = 'R'
            and a.owner = b.owner
          group by b.owner, b.table_name, b.constraint_name
       ) cons
 where col_cnt > ALL
         ( select count(*)
             from dba_ind_columns i
            where i.table_name = cons.table_name
              and i.column_name in (cname1, cname2, cname3, cname4,
                                    cname5, cname6, cname7, cname8 )
              and i.column_position <= cons.col_cnt
              and i.INDEX_OWNER = cons.owner
            group by i.index_name
         );
         v_f c_foreign_key_without_index%rowtype;
         cursor c_par_ind is select index_name, PARTITION_POSITION as PART_POSITION, PARTITION_NAME, BLEVEL, LEAF_BLOCKS, NUM_ROWS, DISTINCT_KEYS,
                             CLUSTERING_FACTOR,
                             case when STATUS = 'UNUSABLE' then 'NO' else 'YES' end USABLE,
                             high_value
                             from dba_ind_partitions
                             where index_name in 
                            (
                            select index_name from dba_indexes where table_name = UPPER(:table_name)
                            and INDEX_OWNER = upper(:owner)
                            and partitioned = 'YES') order by index_name, partition_position;

         v_part c_par_ind%rowtype;

         cursor c_not is SELECT X.OWNER,
       X.TABLE_NAME,
       X.INDEX_NAME,
       to_char(SS.CREATED,'yyyy-mm-dd hh24:mi:ss') as created,
       C.COLUMN_POSITION,
       C.COLUMN_NAME,
       S.BYTES / 1024 / 1024 M
    --   q'[select count(*),count(distinct ]' || C.COLUMN_NAME ||
    --   q'[) from ]' || X.OWNER || '.' || X.TABLE_NAME || q'[;]' AS QUERY_Q
  FROM (SELECT A.OWNER, A.TABLE_NAME, A.INDEX_NAME
          FROM DBA_INDEXES A
         WHERE A.OWNER IN (SELECT USERNAME
                             FROM DBA_USERS
                            WHERE USERNAME not in('SYSTEM','WMSYS','XDB','SYS','SCOTT','QMONITOR','OUTLN','ORDSYS','ORDDATA','OJVMSYS','MDSYS','LBACSYS','DVSYS',
                       'DBSNMP','APEX_040200','AUDSYS','CTXSYS','APEX_030200','EXFSYS','OLAPSYS','SYSMAN','WH_SYNC','GSMADMIN_INTERNAL'))
           AND (A.OWNER, A.INDEX_NAME) NOT IN
               (SELECT /*+unnest*/
                 B.OBJECT_OWNER, B.OBJECT_NAME
                  FROM GV$SQL A, GV$SQL_PLAN B
                 WHERE A.SQL_ID = B.SQL_ID
                   AND A.CHILD_NUMBER = B.CHILD_NUMBER
                   AND B.OBJECT_OWNER IN
                       (SELECT USERNAME
                          FROM DBA_USERS
                         WHERE USERNAME not in ('SYSTEM','WMSYS','XDB','SYS','SCOTT','QMONITOR','OUTLN','ORDSYS','ORDDATA','OJVMSYS','MDSYS','LBACSYS','DVSYS',
                       'DBSNMP','APEX_040200','AUDSYS','CTXSYS','APEX_030200','EXFSYS','OLAPSYS','SYSMAN','WH_SYNC','GSMADMIN_INTERNAL'))
                   AND B.OBJECT_TYPE LIKE '%INDEX%'
                   AND B.TIMESTAMP > (select min(startup_time) from gv$instance))
           AND A.TABLE_NAME NOT LIKE 'SYS%'
           AND A.UNIQUENESS <> 'UNIQUE') X
 INNER JOIN DBA_IND_COLUMNS C
    ON C.INDEX_OWNER = X.OWNER
   AND C.INDEX_NAME = X.INDEX_NAME
   AND C.TABLE_NAME = X.TABLE_NAME
 INNER JOIN DBA_SEGMENTS S
    ON S.SEGMENT_NAME = C.TABLE_NAME
   AND S.OWNER = C.INDEX_OWNER
   -- AND S.BYTES   > 10
 INNER JOIN DBA_OBJECTS SS ON SS.OBJECT_NAME = X.INDEX_NAME
 ORDER BY BYTES desc,OWNER,TABLE_NAME,INDEX_NAME,CREATED;
         v_not c_not%rowtype;

   
   cursor c_ind_monitor is select
    u.name owner,
    io.name index_name,
    t.name table_name,
    decode(bitand(i.flags, 65536), 0, 'NO', 'YES') monitoring,
    decode(bitand(ou.flags, 1), 0, 'NO', 'YES') used,
    ou.start_monitoring,
    decode(ou.end_monitoring,null,'nil',ou.end_monitoring) as end_monitoring
from sys.user$ u, sys.obj$ io, sys.obj$ t, sys.ind$ i, sys.object_usage ou
where
    i.obj# = ou.obj#
    and io.obj# = ou.obj#
    and t.obj# = i.bo#
    and u.user# = io.owner#
    and upper(u.name) = upper(:owner);
   v_ind_monitor c_ind_monitor%rowtype;

begin
  dbms_output.enable(buffer_size => NULL);
  dbms_output.put_line('
COL# Means COLUMN_POSITION
VIS? Means VISIABLE
UNI? Means UNIQUE
USA? Means USABLE
Index Information(contains Global and Local index)');
  dbms_output.put_line('======================');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| INDEX_NAME             |' || ' COLUMN_NAME    ' || '| COLUMN_TYPE          ' || '| COL# |' || ' TABLESPACE_NAME ' || '| INDEX_TYPE |' || ' DEGREE ' || '| INDEX_MB |' || ' DESCEND ' || '| USA? |'  || ' LAST_ANALYZED '|| '| VIS? |'  || ' UNI? ' || '| CLUSTER FACTOR '|| '|');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_i;
    loop fetch c_i into v_i;
    exit when c_i%notfound;
    dbms_output.put_line('| ' || rpad(v_i.INDEX_NAME,22) ||' | '|| rpad(v_i.COLUMN_NAME,14) || ' | ' ||rpad(v_i.col_type,20) ||' | '|| lpad(v_i.COLUMN_POSITION,4) || ' | '|| lpad(v_i.TABLESPACE_NAME,15) || ' | '|| lpad(v_i.INDEX_TYPE,10) || ' | '|| lpad(v_i.DEGREE,6) ||  ' | '|| lpad(v_i.INDEX_MB,8) || ' | '|| lpad(v_i.DESCEND,7) || ' | '|| lpad(v_i.USABLE,4) || ' | '|| lpad(v_i.LAST_ANALYZED,13) || ' | '|| lpad(v_i.visibility,4) || ' | '|| lpad(v_i.UNIQUENESS,4)|| ' | '|| lpad(v_i.CLUSTERING_FACTOR,14) ||' |');
    end loop;
    dbms_output.put_line('--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_i;

   select count(*) into v_part_cnt from dba_ind_partitions where index_name in (select index_name from dba_indexes where table_name = UPPER(:table_name) and INDEX_OWNER = upper(:owner) and partitioned = 'YES') order by index_name, partition_position;
if v_part_cnt > 0 then
    dbms_output.put_line('
Partition Index Information(if index is Local Index)');
  dbms_output.put_line('======================');
  dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| INDEX_NAME         |' || ' PART_POSITION ' || '| PARTITION_NAME |' || ' BLEVEL ' || '| LEAF_BLOCKS |' || ' NUM_ROWS ' || '| DISTINCT_KEYS |' || ' CLUSTERING_FACTOR '  || '| USABLE |'|| ' HIGH_VALUE                         '|| '|');
  dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_par_ind;
    loop fetch c_par_ind into v_part;
    exit when c_par_ind%notfound;
    dbms_output.put_line('| ' || rpad(v_part.INDEX_NAME,18) ||' | '|| lpad(v_part.PART_POSITION,13) || ' | '|| lpad(v_part.PARTITION_NAME,14) || ' | '|| lpad(v_part.BLEVEL,6) || ' | '|| lpad(v_part.LEAF_BLOCKS,11) || ' | '|| lpad(v_part.NUM_ROWS,8) ||  ' | '|| lpad(v_part.DISTINCT_KEYS,13) || ' | '|| lpad(v_part.CLUSTERING_FACTOR,17) || ' | '|| lpad(v_part.USABLE,6) || ' | '|| lpad(v_part.HIGH_VALUE,35)||'|');
    end loop;
    dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_par_ind;
end if;
  dbms_output.put_line('
Foreign Key Without Index Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| OWNER                |' || ' TABLE_NAME            ' || '| CONSTRAINT_NAME         |' || ' COLUMNS                                                                                        ' || '|');
  dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_foreign_key_without_index;
    loop fetch c_foreign_key_without_index into v_f;
    exit when c_foreign_key_without_index%notfound;
    dbms_output.put_line('| ' || rpad(v_f.OWNER,20) ||' | '|| rpad(v_f.TABLE_NAME,21) || ' | '|| rpad(v_f.CONSTRAINT_NAME,23) || ' | ' || rpad(v_f.cols,95) || '|');
    end loop;
    dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_foreign_key_without_index;


  dbms_output.put_line('
Index Not Used Since Instance Startup');
  dbms_output.put_line('======================');
  dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| OWNER                |' || ' TABLE_NAME            ' || '| INDEX_NAME                     |' || ' CREATED             ' || '| COLUMN_POSITION |' || ' COLUMN_NAME                  ' || '| INDEX_MB         ' || '|');
  dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_not;
    loop fetch c_not into v_not;
    exit when c_not%notfound;
    dbms_output.put_line('| ' || rpad(v_not.owner,20) ||' | '|| rpad(v_not.table_name,21) || ' | '|| rpad(v_not.index_name,30) || ' | '|| lpad(v_not.created,19) || ' | '|| lpad(v_not.COLUMN_POSITION,15) || ' | '|| rpad(v_not.COLUMN_NAME,28) ||  ' | '|| lpad(v_not.m,16) || ' |');
    end loop;
    dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_not;


  dbms_output.put_line('
Index MOnitoring Usage');
  dbms_output.put_line('======================');
  dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| OWNER                |' || ' TABLE_NAME            ' || '| INDEX_NAME                     |' || ' monitoring ' || '| used |' || ' start_monitoring    ' || '| end_monitoring ' || '|');
  dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------');
  open c_ind_monitor;
    loop fetch c_ind_monitor into v_ind_monitor;
    exit when c_ind_monitor%notfound;
    dbms_output.put_line('| ' || rpad(v_ind_monitor.owner,20) ||' | '|| rpad(v_ind_monitor.table_name,21) || ' | '|| rpad(v_ind_monitor.index_name,30) || ' | '|| lpad(v_ind_monitor.monitoring,10) || ' | '|| lpad(v_ind_monitor.used,4) || ' | '|| rpad(v_ind_monitor.start_monitoring,19) ||  ' | '|| lpad(v_ind_monitor.end_monitoring,14) || ' |');
    end loop;
    dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------');
  close c_ind_monitor;


  dbms_output.put_line('
Show The Table Constraints');
  dbms_output.put_line('======================');
  dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| OWNER                |' || ' TABLE_NAME            ' || '| INDEX_NAME                  |' || ' constraint_name |' || ' column_name    ' || '| constraint_type |' || ' STATUS  ' || '|');
  dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------');
  open c_constraints;
    loop fetch c_constraints into v_constraints;
    exit when c_constraints%notfound;
    dbms_output.put_line('| ' || rpad(v_constraints.owner,20) ||' | '|| rpad(v_constraints.table_name,21) || ' | '|| rpad(v_constraints.index_name,27) || ' | '|| rpad(v_constraints.constraint_name,15) || ' | '|| rpad(v_constraints.column_name,14) || ' | '|| rpad(v_constraints.constraint_type,15) ||  ' | '|| rpad(v_constraints.status,7) || ' |');
    end loop;
    dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------------------------');
  close c_constraints;


end;
/









undefine index_name
undefine owner
var index_name varchar2(100);
var owner varchar2(100);

begin
  :owner :=upper('&owner');
  :index_name := upper('&index_name');
end;
/

alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
declare
    sql_analyze varchar2(500);
    cursor c_valid is select name as index_name,
       del_lf_rows,
       lf_rows,
       round(del_lf_rows / decode(lf_rows, 0, 1, lf_rows) * 100, 0) frag_pct
  from index_stats;
    v_valid c_valid%rowtype;
begin

  sql_analyze:='analyze index '|| :owner || '.'|| :index_name ||' validate structure';
  execute immediate sql_analyze;

  dbms_output.put_line('
Index Fragment Information(analyze index to get the index frag Information)');
  dbms_output.put_line('======================');
  dbms_output.put_line('---------------------------------------------------------------------------');
  dbms_output.put_line('| INDEX_NAME             |' || ' TOTAL_LEAF_ROWS ' || '| DELETE_LEAF_ROWS |' || ' FRAG_PCT% ' || '|');
  dbms_output.put_line('---------------------------------------------------------------------------');
  open c_valid;
    loop fetch c_valid into v_valid;
    exit when c_valid%notfound;
    dbms_output.put_line('| ' || rpad(v_valid.index_name,22) ||' | '|| rpad(v_valid.lf_rows,15) || ' | '|| rpad(v_valid.del_lf_rows,16) || ' | '|| lpad(v_valid.frag_pct || '%',9) || ' |');
    end loop;
    dbms_output.put_line('---------------------------------------------------------------------------');
  close c_valid;
  if v_valid.frag_pct > 20 then
    dbms_output.put_line('
Current Index: ' || :owner ||'.' ||:index_name || ' Index Frag is '|| v_valid.frag_pct || '%');
    dbms_output.put_line('======================');
    dbms_output.put_line('Please Execute: alter index ' ||:owner ||'.' ||:index_name ||' rebuild online;');
    dbms_output.put_line('---------------------------------------------------------------------------------------------------------------------------');

  end if;  
end;
/



col owner for a20
col index_name for a30

prompt Invalid indexes
prompt ================================================
select owner, index_name, 'N/A' partition_name, table_name 
from dba_indexes
where status <> 'VALID' and PARTITIONED<>'YES' and owner <> 'SYSTEM'
union all
select a.index_owner owner,a.index_name index_name,a.partition_name partition_name,b.table_name
from dba_ind_partitions a,dba_indexes b
where a.index_name=b.index_name and a.index_owner=b.owner and b.owner<>'SYSTEM' and a.status<>'USABLE'
order by owner,index_name,partition_name;





prompt **********************************************************************************************
prompt show Constraint(constraint_type <> 'R') such as Primary Key/Check/Unique Key for the table ...
prompt **********************************************************************************************
select
'select dbms_metadata.get_ddl(''CONSTRAINT'','''|| co.constraint_name || ''',''' || co.owner || ''') from dual;' cons_ddl
from
     dba_constraints co,
     dba_cons_columns cc
where
    co.owner              = cc.owner
and co.table_name         = cc.table_name
and co.constraint_name    = cc.constraint_name
and co.constraint_type    <> 'R'
and co.table_name = :table_name
AND co.owner = :owner
order by
     co.owner,
     co.table_name,
     co.constraint_type,
     co.constraint_name
/

select
        dbms_metadata.get_ddl('CONSTRAINT',co.constraint_name,co.owner) cons_ddl
from
     dba_constraints co,
     dba_cons_columns cc
where
    co.owner              = cc.owner
and co.table_name         = cc.table_name
and co.constraint_name    = cc.constraint_name
and co.constraint_type    <> 'R'
and co.table_name = :table_name
AND co.owner = :owner
order by
     co.owner,
     co.table_name,
     co.constraint_type,
     co.constraint_name
/

prompt ******************************************************************
prompt show Constraint(constraint_type='R') Foreign key for the table ...
prompt ******************************************************************
select
        dbms_metadata.get_ddl('REF_CONSTRAINT',co.constraint_name,co.owner) cons_ddl
from
     dba_constraints co,
     dba_cons_columns cc
where
    co.owner              = cc.owner
and co.table_name         = cc.table_name
and co.constraint_name    = cc.constraint_name
and co.constraint_type    = 'R'
and co.table_name = :table_name
AND co.owner = :owner
order by
     co.owner,
     co.table_name,
     co.constraint_type,
     co.constraint_name
/


