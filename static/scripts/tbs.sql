set linesize 500
set serveroutput on
set feedback off
set verify off


set linesize 500
set serveroutput on
set feedback off
set verify off
declare

    cursor c_recovery is SELECT decode(name,null,'None',name) as recovery_dest,
decode(space_limit,0,0,(space_used - SPACE_RECLAIMABLE) / space_limit * 100) as used_pct
FROM v$recovery_file_dest;
     v_recovery c_recovery%rowtype;

    cursor c_big_tab is select OWNER,SEGMENT_NAME,SIZE_MB,PARTITION_NAME from (select owner,nvl2(PARTITION_NAME,SEGMENT_NAME||'.'||PARTITION_NAME,SEGMENT_NAME) SEGMENT_NAME ,trunc(bytes/1024/1024) as SIZE_MB,decode(PARTITION_NAME,null,'None',PARTITION_NAME) as PARTITION_NAME
    from dba_segments where segment_type like 'TABLE%' and owner  not in ('OWBSYS','FLOWS_FILES','WMSYS','XDB','QMONITOR','OUTLN',
                            'ORDSYS','ORDDATA','OJVMSYS','MDSYS','LBACSYS','DVSYS','DBSNMP','APPQOSSYS','APEX_040200','AUDSYS',
                            'CTXSYS','APEX_030200','EXFSYS','OLAPSYS','SYSMAN','WH_SYNC','GSMADMIN_INTERNAL') order by bytes desc)
    where  rownum < 21;
    v_big_tab c_big_tab%rowtype;


    cursor c_big_lob is select OWNER,TABLE_NAME,COLUMN_NAME,SEGMENT_NAME,SIZE_MB from
    (select a.owner,b.table_name,b.column_name,a.SEGMENT_NAME ,trunc(a.bytes/1024/1024) as SIZE_MB from dba_segments a,dba_lobs b
    where a.segment_type like 'LOB%' and a.owner not in ('OWBSYS','FLOWS_FILES','WMSYS','XDB','QMONITOR','OUTLN',
                               'ORDSYS','ORDDATA','OJVMSYS','MDSYS','LBACSYS','DVSYS','DBSNMP','APPQOSSYS','APEX_040200','AUDSYS',
                               'CTXSYS','APEX_030200','EXFSYS','OLAPSYS','SYSMAN','WH_SYNC','GSMADMIN_INTERNAL') and a.SEGMENT_NAME=b.SEGMENT_NAME order by a.bytes desc) where  rownum < 11;
    v_big_lob c_big_lob%rowtype;

    cursor c_hwmall is SELECT OWNER,
       SEGMENT_NAME TABLE_NAME,
       SEGMENT_TYPE,
       round(BYTES/1024/1024,2) as SEGMENT_MB,
       GREATEST(ROUND(100 * (NVL(HWM - AVG_USED_BLOCKS, 0) /
                      GREATEST(NVL(HWM, 1), 1)),
                      2),
                0) WASTE_PER
  FROM (SELECT A.OWNER OWNER,
               A.SEGMENT_NAME,
               A.SEGMENT_TYPE,
               B.LAST_ANALYZED,
               A.BYTES,
               B.NUM_ROWS,
               A.BLOCKS BLOCKS,
               B.EMPTY_BLOCKS EMPTY_BLOCKS,
               A.BLOCKS - B.EMPTY_BLOCKS - 1 HWM,
               DECODE(ROUND((B.AVG_ROW_LEN * NUM_ROWS * (1 + (PCT_FREE / 100))) / C.BLOCKSIZE,0),0,1,
                      ROUND((B.AVG_ROW_LEN * NUM_ROWS * (1 + (PCT_FREE / 100))) / C.BLOCKSIZE,0)) + 2 AVG_USED_BLOCKS,
               ROUND(100 * (NVL(B.CHAIN_CNT, 0) / GREATEST(NVL(B.NUM_ROWS, 1), 1)), 2) CHAIN_PER,
               B.TABLESPACE_NAME O_TABLESPACE_NAME
          FROM SYS.DBA_SEGMENTS A, SYS.DBA_TABLES B, SYS.TS$ C
         WHERE A.OWNER = B.OWNER
           AND SEGMENT_NAME = TABLE_NAME
           AND SEGMENT_TYPE = 'TABLE'
           AND B.TABLESPACE_NAME = C.NAME)
 WHERE GREATEST(ROUND(100 * (NVL(HWM - AVG_USED_BLOCKS, 0) / GREATEST(NVL(HWM, 1), 1)), 2), 0) > 50
   AND OWNER  not in ('OWBSYS','SYS','FLOWS_FILES','WMSYS','XDB','QMONITOR','OUTLN',
                               'ORDSYS','ORDDATA','OJVMSYS','MDSYS','LBACSYS','DVSYS','DBSNMP','APPQOSSYS','APEX_040200','AUDSYS',
                               'CTXSYS','APEX_030200','EXFSYS','OLAPSYS','SYSMAN','WH_SYNC','GSMADMIN_INTERNAL')
   AND BLOCKS > 100
 ORDER BY WASTE_PER DESC;
    v_hwmall c_hwmall%rowtype;
   
begin

  dbms_output.put_line('
Fast Recovery Dest Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| RECOVERY_DEST                                                                                |' || ' Used_Pct% ' || '|'); 
  dbms_output.put_line('------------------------------------------------------------------------------------------------------------');
  open c_recovery;
    loop fetch c_recovery into v_recovery;
    exit when c_recovery%notfound;
    dbms_output.put_line('| ' || rpad(v_recovery.recovery_dest,92) ||' | '|| lpad(v_recovery.used_pct,10) || '|');
    end loop;
    dbms_output.put_line('------------------------------------------------------------------------------------------------------------');
  close c_recovery;

  dbms_output.put_line('
Top 20 Big Table Information in The Database');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| OWNER            |' || ' SEGMENT_NAME                     ' || '|   SIZE(MB) ' || '| PARTITION_NAME                ' ||'|');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------');
  open c_big_tab;
    loop fetch c_big_tab into v_big_tab;
    exit when c_big_tab%notfound;
    dbms_output.put_line('| ' || rpad(v_big_tab.OWNER,16) ||' | '|| rpad(v_big_tab.SEGMENT_NAME,32) || ' | '|| lpad(v_big_tab.SIZE_MB,10) || ' | ' || rpad(v_big_tab.PARTITION_NAME,30)|| '|');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------');
  close c_big_tab;


  dbms_output.put_line('
Top 20 Big LOB Information in The Database (When Migrating Database,<purge dba_recyclebin;> can purge unnecessary LOB)');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| OWNER            |' || ' TABLE_NAME                ' || '| COLUMN_NAME          |' || ' SEGMENT_NAME                   ' || '| SIZE(MB) ' || '|');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------');
  open c_big_lob;
    loop fetch c_big_lob into v_big_lob;
    exit when c_big_lob%notfound;
    dbms_output.put_line('| ' || rpad(v_big_lob.OWNER,16) ||' | '|| rpad(v_big_lob.TABLE_NAME,25) || ' | '|| rpad(v_big_lob.COLUMN_NAME,20) ||  ' | '|| rpad(v_big_lob.SEGMENT_NAME,30) ||  ' | '|| lpad(v_big_lob.SIZE_MB,9) ||'|');
    end loop;
    dbms_output.put_line('-------------------------------------------------------------------------------------------------------------------');
  close c_big_lob;

  dbms_output.put_line('
HWM Information Rely on Table Statistics');
  dbms_output.put_line('======================');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| OWNER                 |' || ' TABLE_NAME                       |' || ' SEGMENT_TYPE   ' || '| SEGMENT_MB     |' || ' WASTER% ' || '|');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------');
  open c_hwmall;
    loop fetch c_hwmall into v_hwmall;
    exit when c_hwmall%notfound;
    dbms_output.put_line('| ' || rpad(v_hwmall.owner,21) || ' | ' || rpad(v_hwmall.TABLE_NAME,32) ||' | '|| rpad(v_hwmall.SEGMENT_TYPE,14) || ' | ' || lpad(v_hwmall.SEGMENT_MB,14) || ' | ' || lpad(v_hwmall.WASTE_PER || '%',7) || ' |');
    end loop;
    dbms_output.put_line('--------------------------------------------------------------------------------------------------------');
  close c_hwmall;

end;
/