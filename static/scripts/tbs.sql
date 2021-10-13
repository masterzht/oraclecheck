set linesize 500
set serveroutput on
set feedback off
set verify off


set linesize 500
set serveroutput on
set feedback off
set verify off
declare
    v_cnt number;

     cursor c_tmp is SELECT C.SQL_ID,
       A.USERNAME,
       A.SID||','||A.SERIAL# as sid_and_serial,
       A.OSUSER,
       A.MACHINE,
       A.LAST_CALL_ET as elapse_time,
       B.TABLESPACE as TABLESPACE_NAME,
       (B.BLOCKS * (select value from v$parameter where name='db_block_size')/1024/1024) as USED_MB,
       C.SQL_TEXT
  FROM V$SESSION A, V$TEMPSEG_USAGE B, V$SQLAREA C
 WHERE A.SADDR = B.SESSION_ADDR
   AND C.ADDRESS = A.SQL_ADDRESS
   AND C.HASH_VALUE = A.SQL_HASH_VALUE
order by b.blocks;
    v_tmp c_tmp%rowtype;

    cursor c_pga is select /*+ ordered leading(d) */ 
    c.sql_id,
    a.username,
    a.sid||','||a.serial# as sid_and_serial,
    a.machine,
    a.LAST_CALL_ET as elapse_time,
    to_char(a.logon_time,'yyyymmdd hh24:mi:ss') as LOGON_TIME,
    round(d.PGA_USED_MEM / 1024 / 1024,2) as PGA_USED_MB,
    c.sql_text
    from v$process d,v$session a,v$sqlarea c
    where a.sql_id = c.sql_id
    and a.paddr = d.addr
    and d.PGA_USED_MEM >= 1024 * 1024 * 10
    order by d.PGA_USED_MEM; 
    v_pga c_pga%rowtype;
    

    v_pga_cnt number;
    v_tmp_cnt number;
 
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

  select count(*) into v_tmp_cnt FROM V$SESSION A, V$TEMPSEG_USAGE B, V$SQLAREA C
 WHERE A.SADDR = B.SESSION_ADDR
   AND C.ADDRESS = A.SQL_ADDRESS
   AND C.HASH_VALUE = A.SQL_HASH_VALUE
order by b.blocks;
  if v_tmp_cnt > 0 then 
  dbms_output.put_line('
Current Usage Information of Temp Tablespace Per Session');
  dbms_output.put_line('======================');
  dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| SQL_ID        |'  || ' USERNAME     |' || ' sid_and_serial# ' || '|      MACHINE |' || ' ELAPSE_TIME(S) |'|| ' TABLESPACE_NAME ' || '| USED_MB |' || '                                          SQL_TEXT ' || '|'); 
  dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_tmp;
    loop fetch c_tmp into v_tmp;
    exit when c_tmp%notfound;
    dbms_output.put_line('| ' || lpad(v_tmp.SQL_ID,13) || ' | '||rpad(v_tmp.USERNAME,12) ||' | '|| lpad(v_tmp.sid_and_serial,15) || ' | '|| lpad(v_tmp.MACHINE,12) || ' | '|| lpad(v_tmp.elapse_time,14) || ' | ' ||lpad(v_tmp.TABLESPACE_NAME,15) || ' | '|| lpad(v_tmp.USED_MB,7) || ' | '|| rpad(v_tmp.SQL_TEXT,50)  || '|');
    end loop;
    dbms_output.put_line('------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_tmp;
  else 
  dbms_output.put_line('
There is no Session that Use Temp Tablespace Disk Space');
  dbms_output.put_line('======================');
  end if;  

 select count(*) into v_pga_cnt
 from v$process d,v$session a,v$sqlarea c
    where a.sql_id = c.sql_id
    and a.paddr = d.addr
    and d.PGA_USED_MEM >= 1024 * 1024 * 10
    order by d.PGA_USED_MEM;
  if v_pga_cnt > 0 then 
 
  dbms_output.put_line('
Current Usage Information of PGA Memory(>10M) Per Session');
  dbms_output.put_line('======================');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| SQL_ID        |'  || ' USERNAME     |' || ' sid_and_serial# ' || '|      MACHINE |' || ' ELAPSE_TIME(S) |'|| '        LOGON_TIME ' || '| PGA_USED_MB |' || '                                      SQL_TEXT ' || '|'); 
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_pga;
    loop fetch c_pga into v_pga;
    exit when c_pga%notfound;
    dbms_output.put_line('| ' || lpad(v_pga.SQL_ID,13) || ' | '||rpad(v_pga.USERNAME,12) ||' | '|| lpad(v_pga.sid_and_serial,15) || ' | '|| lpad(v_pga.MACHINE,12) || ' | '|| lpad(v_pga.elapse_time,14) || ' | ' ||lpad(v_pga.LOGON_TIME,17) || ' | '|| lpad(v_pga.PGA_USED_MB,11) || ' | '|| rpad(v_pga.SQL_TEXT,46)  || '|');
    end loop;
    dbms_output.put_line('--------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_pga;
  else 
  dbms_output.put_line('
There is no Session that PGA Memory Usage > 10M for Per Session');
  dbms_output.put_line('======================');
  end if;


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






declare
  v_cnt number;
  cursor c_group is SELECT
    GROUP_NUMBER,
    NAME as DISKGROUP_NAME,
    lpad(round(ALLOCATION_UNIT_SIZE/1024/1024) || 'M',7) as "AU_SIZE",
    STATE,
    TYPE,
    round(TOTAL_MB/1024) as TOTAL_GB,
    round(FREE_MB/1024) as FREE_GB,
    lpad(round((TOTAL_MB-FREE_MB)/TOTAL_MB*100) || '%',9) as Used_Pct,
    round(USABLE_FILE_MB/1024) as "USABLE_FILE_GB" ,
    REQUIRED_MIRROR_FREE_MB
from
    V$ASM_DISKGROUP;
  v_group c_group%rowtype;
  cursor c_disk is select b.GROUP_NUMBER as GROUP_NUMBER,
  b.name as DISKGROUP_NAME,
  a.path,
  a.FAILGROUP,a.name as DISK_NAME,a.STATE,a.MODE_STATUS,a.HEADER_STATUS,a.MOUNT_STATUS,a.REPAIR_TIMER
from v$asm_disk a,v$asm_diskgroup b where a.GROUP_NUMBER = b.GROUP_NUMBER order by b.GROUP_NUMBER,a.path;
  v_disk c_disk%rowtype;

  cursor c_client is select GROUP_NUMBER,INSTANCE_NAME,DB_NAME,STATUS,SOFTWARE_VERSION,COMPATIBLE_VERSION from v$asm_client order by GROUP_NUMBER;
  v_client c_client%rowtype;
  
begin
  select count(*) into v_cnt from v$ASM_DISKGROUP;
if v_cnt = 0 then
  dbms_output.put_line('
ASM Diskgroup is not in Useage');
  dbms_output.put_line('======================');
else
  dbms_output.put_line('
ASM Diskgroup Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| GROUP# |' || ' DISKGROUP_NAME ' || '| AU_SIZE |' || '     STATE ' || '|   TYPE |' || ' TOTAL_GB ' || '| FREE_GB |' || ' "Used_Pct%" ' || '| USABLE_FILE_GB |' || ' REQUIRED_MIRROR_FREE_MB ' || '|'); 
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------');
  open c_group;
    loop fetch c_group into v_group;
    exit when c_group%notfound;
    dbms_output.put_line('| ' || rpad(v_group.GROUP_NUMBER,6) ||' | '|| rpad(v_group.DISKGROUP_NAME,14) || ' | '|| lpad(v_group.AU_SIZE,7) || ' | '|| lpad(v_group.STATE,9) || ' | '|| lpad(v_group.TYPE,6) || ' | '|| lpad(v_group.TOTAL_GB,8) || ' | '|| lpad(v_group.FREE_GB,7) || ' | '|| lpad(v_group.Used_Pct,11) || ' | '|| lpad(v_group.USABLE_FILE_GB,14) || ' | '|| lpad(v_group.REQUIRED_MIRROR_FREE_MB,24) || '|');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------');
  close c_group;
  dbms_output.put_line('
ASM Disk Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| GROUP# |' || ' DISKGROUP_NAME ' || '|                                            PATH |' || '      FAILGROUP ' || '|      DISK_NAME |' || '   STATE ' || '| MODE_STATS |' || ' HEADER_STATS ' || '| MOUNT_STATS |' || ' REPAIR_TIMER ' || '|'); 
  dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_disk;
    loop fetch c_disk into v_disk;
    exit when c_disk%notfound;
    dbms_output.put_line('| ' || rpad(v_disk.GROUP_NUMBER,6) ||' | '|| rpad(v_disk.DISKGROUP_NAME,14) || ' | '|| lpad(v_disk.path,47) || ' | '|| lpad(v_disk.FAILGROUP,14) || ' | '|| lpad(v_disk.DISK_NAME,14) || ' | '|| lpad(v_disk.STATE,7) || ' | '|| lpad(v_disk.MODE_STATUS,10) || ' | '|| lpad(v_disk.HEADER_STATUS,12) || ' | '|| lpad(v_disk.MOUNT_STATUS,11) || ' | '|| lpad(v_disk.REPAIR_TIMER,13) || '|');
    end loop;
    dbms_output.put_line('----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_disk;

dbms_output.put_line('
ASM Client Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------------------------');
  dbms_output.put_line('| GROUP# |' || ' INSTANCE_NAME ' || '|  DB_NAME |' || '      STATUS |' || ' SOFTWARE_VERSION ' || '| COMPATIBLE_VERSION ' || '|'); 
  dbms_output.put_line('-------------------------------------------------------------------------------------------');
  open c_client;
    loop fetch c_client into v_client;
    exit when c_client%notfound;
    dbms_output.put_line('| ' || rpad(v_client.GROUP_NUMBER,6) ||' | '|| lpad(v_client.INSTANCE_NAME,13) || ' | '|| lpad(v_client.DB_NAME,8) || ' | '|| lpad(v_client.STATUS,11) || ' | '|| lpad(v_client.SOFTWARE_VERSION,16) || ' | '|| lpad(v_client.COMPATIBLE_VERSION,19) || '|');
    end loop;
    dbms_output.put_line('-------------------------------------------------------------------------------------------');
  close c_client;
  end if;
end;
/




prompt asm_rebalance_file

SELECT
    file_num,
    MAX(extent_count) max_disk_extents,
    MIN(extent_count) min_disk_extents,
    MAX(extent_count) - MIN(extent_count) disk_extents_imbalance
FROM (
    SELECT
    number_kffxp file_num,
    disk_kffxp disk_num,
    COUNT(xnum_kffxp) extent_count
    FROM
        x$kffxp
    WHERE
        group_kffxp = 1
        AND disk_kffxp != 65534
        GROUP BY number_kffxp, disk_kffxp
        ORDER BY number_kffxp, disk_kffxp)
GROUP BY file_num
HAVING MAX(extent_count) - MIN(extent_count) > 5
ORDER BY disk_extents_imbalance DESC;


