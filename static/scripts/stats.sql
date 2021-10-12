


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

    cursor c_sys is select client_name,status from DBA_AUTOTASK_CLIENT;
    v_sys c_sys%rowtype;
 
    cursor c_lock0 is select owner,table_name,stattype_locked
    from dba_tab_statistics
    where owner not in ('SYSTEM','OWBSYS','FLOWS_FILES','WMSYS','XDB','QMONITOR','OUTLN','ORDSYS','ORDDATA','OJVMSYS','MDSYS','LBACSYS','DVSYS',
                    'DBSNMP','APPQOSSYS','APEX_040200','AUDSYS','CTXSYS','APEX_030200','EXFSYS','OLAPSYS','SYSMAN','WH_SYNC','GSMADMIN_INTERNAL')
    and stattype_locked is not null;
    v_lock0 c_lock0%rowtype;

    cursor c_lock is select q'[exec DBMS_STATS.UNLOCK_TABLE_STATS(OWNNAME=> ']' || OWNER || q'[',TABNAME=> ']' || SEGMENT_NAME  || q'[');]' as sql_command
  from (SELECT OWNER,
                     SEGMENT_NAME,
                     SUM(BYTES / 1024 / 1024 / 1024) SIZE_GB
                FROM DBA_SEGMENTS a
               WHERE (owner,SEGMENT_NAME) IN
                     (SELECT /*+ UNNEST */
                      DISTINCT owner,TABLE_NAME
                        FROM DBA_TAB_STATISTICS
                       WHERE  OWNER = :owner
    and stattype_locked is not null)
               GROUP BY OWNER, SEGMENT_NAME);
    v_lock c_lock%rowtype;

    cursor c_expire is SELECT OWNER,
    SEGMENT_NAME,
    CASE 
    WHEN SIZE_GB < 0.5 THEN 100 WHEN SIZE_GB >= 0.5 AND SIZE_GB < 1 THEN 80 
    WHEN SIZE_GB >= 1 AND SIZE_GB < 5 THEN 50 
    WHEN SIZE_GB >= 5 AND SIZE_GB < 10 THEN 30 
    WHEN SIZE_GB >= 10 THEN 10 END AS PERCENT, 
    1 AS DEGREE
FROM (SELECT OWNER,SEGMENT_NAME,SUM(BYTES / 1024 / 1024 / 1024) SIZE_GB 
      FROM DBA_SEGMENTS a 
      WHERE (owner,SEGMENT_NAME) 
      IN (SELECT /*+ UNNEST */ DISTINCT owner,TABLE_NAME  FROM DBA_TAB_STATISTICS 
           WHERE (LAST_ANALYZED IS NULL OR STALE_STATS = 'YES' 
--       OR last_analyzed < sysdate -7
) 
           AND OWNER not in('SYSTEM','WMSYS','XDB','QMONITOR','OUTLN','ORDSYS','ORDDATA','OJVMSYS','MDSYS','LBACSYS','DVSYS',
                            'DBSNMP','APEX_040200','AUDSYS','CTXSYS','APEX_030200','EXFSYS','OLAPSYS','SYSMAN','WH_SYNC','GSMADMIN_INTERNAL','HZMCDBAGENT')            and TABLE_NAME not in ('PCASE','VTE_PADUA_INFO','VTE_CAPRINI_INFO','DOC_TYPE_DICT') 
           AND stattype_locked is null
) and not exists (select null from dba_tables b where b.iot_type = 'IOT_OVERFLOW' and a.segment_name = b.table_name) 
GROUP BY OWNER, SEGMENT_NAME);
    v_expire c_expire%rowtype;

    cursor c_expire0 is select q'[exec DBMS_STATS.GATHER_TABLE_STATS(OWNNAME=> ']' || OWNER || q'[',TABNAME=> ']' || SEGMENT_NAME || q'[',ESTIMATE_PERCENT =>]' || PERCENT || q'[,METHOD_OPT=> 'for all columns size auto',DEGREE=> 50,CASCADE => TRUE);]' as sql_command
  from (
  SELECT OWNER,
        SEGMENT_NAME,
             CASE
               WHEN SIZE_GB < 0.5 THEN
                30
               WHEN SIZE_GB >= 0.5 AND SIZE_GB < 1 THEN
                20
               WHEN SIZE_GB >= 1 AND SIZE_GB < 5 THEN
                10
               WHEN SIZE_GB >= 5 AND SIZE_GB < 10 THEN
                5
               WHEN SIZE_GB >= 10 THEN
                1
             END AS PERCENT,
             8 AS DEGREE
        FROM (SELECT OWNER,
                     SEGMENT_NAME,
                     SUM(BYTES / 1024 / 1024 / 1024) SIZE_GB
                FROM DBA_SEGMENTS a
               WHERE (owner,SEGMENT_NAME) IN
                     (SELECT /*+ UNNEST */
                      DISTINCT owner,TABLE_NAME
                        FROM DBA_TAB_STATISTICS
                       WHERE  OWNER =:owner
    and stattype_locked is null and last_analyzed < sysdate -1)
               GROUP BY OWNER, SEGMENT_NAME)
  order BY PERCENT);
    v_expire0 c_expire0%rowtype; 

    cursor c_temp is SELECT /*+ NO_MERGE */
       s.owner, s.table_name
  FROM dba_tab_statistics s,
       dba_tables t
 WHERE s.object_type = 'TABLE'
   AND s.owner NOT IN ('ANONYMOUS','APEX_030200','APEX_040000','APEX_SSO','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS','SI_INFORMTN_SCHEMA','SQLTXADMIN','SQLTXPLAIN','SYS','SYSMAN','SYSTEM','TRCANLZR','WMSYS','XDB','XS$NULL','PERFSTAT','STDBYPERF')
   AND s.last_analyzed IS NOT NULL
   /*AND s.stale_stats = 'YES'*/
   AND t.temporary = 'Y'
   AND t.owner = s.owner
   AND t.table_name = s.table_name
   AND NOT EXISTS (
SELECT NULL
  FROM dba_external_tables e
 WHERE e.owner = s.owner
   AND e.table_name = s.table_name
)
 ORDER BY
       s.owner, s.table_name;
   v_temp c_temp%rowtype;
begin
  dbms_output.enable(buffer_size => NULL);
  dbms_output.put_line('
Create Gather Statistics Procedure and Log Tables');
  dbms_output.put_line('======================');
  dbms_output.put_line('create table gather_stat_log(id number,owner varchar2(32),table_name varchar2(32),percent number,degree number,gmt_create date,log_type varchar2(10),content varchar2(100));');
  dbms_output.put_line('alter table gather_stat_log add constraint pk_gather_stat_log primary key(id);');
  dbms_output.put_line('create index i_gather_stat_log_gc_tn on gather_stat_log(gmt_create,table_name);');
  dbms_output.put_line('create sequence seq_gather_stat_log MINVALUE 1 MAXVALUE 999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE;
    ');

  dbms_output.put_line('    create or replace procedure gather_statistics as');
  dbms_output.put_line('v_err varchar2(100);');
  dbms_output.put_line('  CURSOR STALE_TABLE IS');
  dbms_output.put_line('    SELECT OWNER,');
  dbms_output.put_line('           SEGMENT_NAME,');
  dbms_output.put_line('           CASE');
  dbms_output.put_line('             WHEN SIZE_GB < 0.5 THEN');
  dbms_output.put_line('              30');
  dbms_output.put_line('             WHEN SIZE_GB >= 0.5 AND SIZE_GB < 1 THEN');
  dbms_output.put_line('              20');
  dbms_output.put_line('             WHEN SIZE_GB >= 1 AND SIZE_GB < 5 THEN');
  dbms_output.put_line('              10');
  dbms_output.put_line('             WHEN SIZE_GB >= 5 AND SIZE_GB < 10 THEN');
  dbms_output.put_line('              5');
  dbms_output.put_line('             WHEN SIZE_GB >= 10 THEN');
  dbms_output.put_line('              1');
  dbms_output.put_line('           END AS PERCENT,');
  dbms_output.put_line('           8 AS DEGREE');
  dbms_output.put_line('      FROM (SELECT OWNER,');
  dbms_output.put_line('                   SEGMENT_NAME,');
  dbms_output.put_line('                   SUM(BYTES / 1024 / 1024 / 1024) SIZE_GB');
  dbms_output.put_line('              FROM DBA_SEGMENTS a');
  dbms_output.put_line('             WHERE (owner,SEGMENT_NAME) IN');
  dbms_output.put_line('                   (SELECT /*+ UNNEST */');
  dbms_output.put_line('                    DISTINCT owner,TABLE_NAME');
  dbms_output.put_line('                      FROM DBA_TAB_STATISTICS');
  dbms_output.put_line('                     WHERE (LAST_ANALYZED IS NULL OR STALE_STATS = ''YES'')');
  dbms_output.put_line('                       AND OWNER not in(''SYSTEM'',');
  dbms_output.put_line('                       ''WMSYS'',');
  dbms_output.put_line('                       ''XDB'',');
  dbms_output.put_line('                       ''SYS'',');
  dbms_output.put_line('                       ''SCOTT'',');
  dbms_output.put_line('                       ''QMONITOR'',');
  dbms_output.put_line('                       ''OUTLN'',');
  dbms_output.put_line('                       ''ORDSYS'',');
  dbms_output.put_line('                       ''ORDDATA'',');
  dbms_output.put_line('                       ''OJVMSYS'',');
  dbms_output.put_line('                       ''MDSYS'',');
  dbms_output.put_line('                       ''LBACSYS'',');
  dbms_output.put_line('                       ''DVSYS'',');
  dbms_output.put_line('                       ''DBSNMP'',''APEX_040200'',''AUDSYS'',''CTXSYS'',''APEX_030200'',''EXFSYS'',''OLAPSYS'',''SYSMAN'',''WH_SYNC'',''GSMADMIN_INTERNAL'')');
  dbms_output.put_line('                       and stattype_locked is null');
  dbms_output.put_line('                       and table_name not like ''SYS%'' and table_name not like ''SCH%'' and table_name not like ''BIN%'')');
  dbms_output.put_line('               and not exists');
  dbms_output.put_line('             (select null');
  dbms_output.put_line('                      from dba_tables b');
  dbms_output.put_line('                     where b.iot_type = ''IOT_OVERFLOW''');
  dbms_output.put_line('                       and a.segment_name = b.table_name)');
  dbms_output.put_line('             GROUP BY OWNER, SEGMENT_NAME);');
  dbms_output.put_line('BEGIN');
  dbms_output.put_line('  DBMS_STATS.FLUSH_DATABASE_MONITORING_INFO;');
  dbms_output.put_line('  FOR STALE IN STALE_TABLE LOOP');
  dbms_output.put_line('  begin');
  dbms_output.put_line('    DBMS_STATS.GATHER_TABLE_STATS(OWNNAME          => STALE.OWNER,');
  dbms_output.put_line('                                  TABNAME          => STALE.SEGMENT_NAME,');
  dbms_output.put_line('                                  ESTIMATE_PERCENT => STALE.PERCENT,');
  dbms_output.put_line('                                  METHOD_OPT       => ''for all columns size repeat'',');
  dbms_output.put_line('                                  DEGREE           => 1,');
  dbms_output.put_line('                                  CASCADE          => TRUE);');
  dbms_output.put_line('    insert into gather_stat_log(id,owner,table_name,percent,degree,gmt_create,log_type) values(seq_gather_stat_log.nextval,STALE.OWNER,STALE.SEGMENT_NAME,STALE.PERCENT,8,sysdate,''info'');');
  dbms_output.put_line('    commit;');
  dbms_output.put_line('    exception');
  dbms_output.put_line('        when others then');
  dbms_output.put_line('        v_err:=substr(SQLERRM,1,80);');
  dbms_output.put_line('        insert into gather_stat_log(id,owner,table_name,percent,degree,gmt_create,log_type,content)values(seq_gather_stat_log.nextval,STALE.OWNER,STALE.SEGMENT_NAME,STALE.PERCENT,8,sysdate,''error'',v_err);');
  dbms_output.put_line('        commit;');
  dbms_output.put_line('    end;');
  dbms_output.put_line('  END LOOP;');
  dbms_output.put_line('END;');
  dbms_output.put_line('/
    ');       
  dbms_output.put_line('BEGIN');
  dbms_output.put_line('DBMS_SCHEDULER.CREATE_JOB(JOB_NAME        => ''GATHER_STATIC_JOB'',');
  dbms_output.put_line('                          JOB_TYPE        => ''STORED_PROCEDURE'',');
  dbms_output.put_line('                          JOB_ACTION      => ''GATHER_STATISTICS'',');
  dbms_output.put_line('                          START_DATE      => to_date(''2019-11-04 00:10:00'',''yyyy-mm-dd hh24:mi:ss''),');
  dbms_output.put_line('                          REPEAT_INTERVAL => ''FREQ=WEEKLY'',');
  dbms_output.put_line('                          AUTO_DROP       => FALSE,');
  dbms_output.put_line('                          COMMENTS        => ''GATHER STATISTICS'');');
  dbms_output.put_line('END;');
  dbms_output.put_line('/');

  dbms_output.put_line('begin');
  dbms_output.put_line('       DBMS_SCHEDULER.ENABLE(''GATHER_STATIC_JOB'');');
  dbms_output.put_line('end;');
  dbms_output.put_line('/'
    );

  dbms_output.put_line('
Auto Statistics Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------------');
  dbms_output.put_line('| CLIENT_NAME                         |' || ' STATUS     ' || '|');
  dbms_output.put_line('----------------------------------------------------');
  open c_sys;
    loop fetch c_sys into v_sys;
    exit when c_sys%notfound;
    dbms_output.put_line('| ' || rpad(v_sys.CLIENT_NAME,35) ||' | '|| rpad(v_sys.STATUS,10) || ' |');
    end loop;
    dbms_output.put_line('----------------------------------------------------');
  close c_sys;


  dbms_output.put_line('
The Table Statistics are Expired ');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------');
  dbms_output.put_line('| TABLE_OWNER      |' || ' TABLE_NAME                       |' || ' DEGREE          ' || '|');
  dbms_output.put_line('-------------------------------------------------------------------------');
  open c_expire;
    loop fetch c_expire into v_expire;
    exit when c_expire%notfound;
    dbms_output.put_line('| ' || rpad(v_expire.owner,16) || ' | ' || rpad(v_expire.SEGMENT_NAME,32) ||' | '|| rpad(v_expire.DEGREE,15) ||  ' |');
    end loop;
    dbms_output.put_line('-------------------------------------------------------------------------');
  close c_expire;


   dbms_output.put_line('
Gather table statistics using dbms_stats.gather_table_stats Based on the username entered');
  dbms_output.put_line('======================');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| Gather Table Statistics Command                                                                                                                                                                |');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_expire0;
    loop fetch c_expire0 into v_expire0;
    exit when c_expire0%notfound;
    dbms_output.put_line('| ' || rpad(v_expire0.sql_command,190) || ' |');
    end loop;
    dbms_output.put_line('--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_expire0; 



  dbms_output.put_line('
The Table Statistics are Locked Include sys,scott and business users');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------');
  dbms_output.put_line('| TABLE_OWNER      |' || ' TABLE_NAME                       |' || ' stattype_locked ' || '|');
  dbms_output.put_line('-------------------------------------------------------------------------');
  open c_lock0;
    loop fetch c_lock0 into v_lock0;
    exit when c_lock0%notfound;
    dbms_output.put_line('| ' || rpad(v_lock0.owner,16) || ' | ' || rpad(v_lock0.table_name,32) ||' | '|| rpad(v_lock0.stattype_locked,15) ||  ' |');
    end loop;
    dbms_output.put_line('-------------------------------------------------------------------------');
  close c_lock0;


  dbms_output.put_line('
unlock table statistics using dbms_stats.unlock_table_stats Based on the username entered');
  dbms_output.put_line('======================');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| UNLOCK TABLE Statistics Command                                                                      ' ||'|');
  dbms_output.put_line('--------------------------------------------------------------------------------------------------------');
  open c_lock;
    loop fetch c_lock into v_lock;
    exit when c_lock%notfound;
    dbms_output.put_line('| ' || rpad(v_lock.sql_command,100)    || ' |');
    end loop;
    dbms_output.put_line('--------------------------------------------------------------------------------------------------------');
  close c_lock;

  dbms_output.put_line('
Temporary Table That has been Gathered Statistics');
  dbms_output.put_line('======================');
  dbms_output.put_line('======================');
  dbms_output.put_line('---------------------------------------------------------------------');
  dbms_output.put_line('| TABLE_OWNER      |' || ' TABLE_NAME                       ' || '|');
  dbms_output.put_line('---------------------------------------------------------------------');
  open c_temp;
    loop fetch c_temp into v_temp;
    exit when c_temp%notfound;
    dbms_output.put_line('| ' || rpad(v_temp.owner,16) || ' | ' || rpad(v_temp.table_name,32) || ' |');
    end loop;
    dbms_output.put_line('------------------------------------------------------------------');  
  close c_temp;

end;
/

/**
--查询下次执行时间
col enabled for a10
col job_name for a17
col start_date for a20
col end_date for a20
col last_start_date for a20
col NEXT_RUN_DATE for a20
select JOB_NAME,
to_char(LAST_START_DATE,'yyyy-mm-dd hh24:mi:ss') as last_start_date,
to_char(NEXT_RUN_DATE,'yyyy-mm-dd hh24:mi:ss') as NEXT_RUN_DATE,
to_char(START_DATE,'yyyy-mm-dd hh24:mi:ss') as start_date,
to_char(END_DATE,'yyyy-mm-dd hh24:mi:ss') as end_date,
ENABLED 
from dba_scheduler_jobs where job_name like '%GATHER_STATIC_JOB%';
/
prompt **************************
prompt Gather Extended statistics
prompt **************************

select DBMS_STATS.REPORT_COL_USAGE(user, 'T_GAME_XYDC') from dual;
begin
    DBMS_STATS.SEED_COL_USAGE(null, null, 300);
end;
/
select dbms_stats.create_extended_stats(user,'T_GAME_XYDC') from dual;
begin
    dbms_stats.gather_table_stats(user,'T_GAME_XYDC',method_opt=>'for all hidden columns size 1024');
end;
/

select dbms_stats.create_extended_stats('BANK','FBBALANCE','(HDATE,BANKID)') from dual;
begin
    dbms_stats.gather_table_stats('BANK','FBBALANCE',method_opt=>'for all hidden columns size 254');
end;
/
**/
-- 检查无统计信息/统计信息过期/统计信息过旧的表

prompt last_analyzed < 7 and last_analyzed is null and stale_stats = 'YES' 
set linesize 600
SELECT /*+ NO_MERGE */
       s.owner, s.table_name, s.stale_stats , to_char(s.last_analyzed,'YYYY/MM/DD HH24:MI:SS') as last_analyzed_time
  FROM dba_tab_statistics s,
       dba_tables t
 WHERE s.object_type = 'TABLE'
   AND s.owner NOT IN ('ANONYMOUS','APEX_030200','FLOWS_FILES','APEX_040000','APEX_SSO','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS','SI_INFORMTN_SCHEMA','SQLTXADMIN','SQLTXPLAIN','SYS','SYSMAN','SYSTEM','TRCANLZR','WMSYS','XDB','XS$NULL','PERFSTAT','STDBYPERF')
   AND (s.last_analyzed IS NULL or  s.stale_stats = 'YES' or s.last_analyzed < sysdate -7)
   AND t.owner = s.owner
   AND t.table_name = s.table_name
   AND t.temporary = 'N'
   AND NOT EXISTS (
SELECT NULL
  FROM dba_external_tables e
 WHERE e.owner = s.owner
   AND e.table_name = s.table_name
)
 ORDER BY
       s.owner, s.table_name;

prompt 

col partition_name for A20
col SUBPARTITION_NAME for a20
SELECT *
  FROM (SELECT *
          FROM (SELECT *
                  FROM (SELECT U.NAME OWNER,
                               O.NAME TABLE_NAME,
                               NULL PARTITION_NAME,
                               NULL SUBPARTITION_NAME,
                               M.INSERTS,
                               M.UPDATES,
                               M.DELETES,
                               M.TIMESTAMP,
                               DECODE(BITAND(M.FLAGS, 1), 1, 'YES', 'NO') TRUNCATED,
                               M.DROP_SEGMENTS
                          FROM SYS.MON_MODS_ALL$ M,
                               SYS.OBJ$          O,
                               SYS.TAB$          T,
                               SYS.USER$         U
                         WHERE O.OBJ# = M.OBJ#
                           AND O.OBJ# = T.OBJ#
                           AND O.OWNER# = U.USER#
                        UNION ALL
                        SELECT U.NAME,
                               O.NAME,
                               O.SUBNAME,
                               NULL,
                               M.INSERTS,
                               M.UPDATES,
                               M.DELETES,
                               M.TIMESTAMP,
                               DECODE(BITAND(M.FLAGS, 1), 1, 'YES', 'NO'),
                               M.DROP_SEGMENTS
                          FROM SYS.MON_MODS_ALL$ M, SYS.OBJ$ O, SYS.USER$ U
                         WHERE O.OWNER# = U.USER#
                           AND O.OBJ# = M.OBJ#
                           AND O.TYPE# = 19
                        UNION ALL
                        SELECT U.NAME,
                               O.NAME,
                               O2.SUBNAME,
                               O.SUBNAME,
                               M.INSERTS,
                               M.UPDATES,
                               M.DELETES,
                               M.TIMESTAMP,
                               DECODE(BITAND(M.FLAGS, 1), 1, 'YES', 'NO'),
                               M.DROP_SEGMENTS
                          FROM SYS.MON_MODS_ALL$ M,
                               SYS.OBJ$          O,
                               SYS.TABSUBPART$   TSP,
                               SYS.OBJ$          O2,
                               SYS.USER$         U
                         WHERE O.OBJ# = M.OBJ#
                           AND O.OWNER# = U.USER#
                           AND O.OBJ# = TSP.OBJ#
                           AND O2.OBJ# = TSP.POBJ#)
                 WHERE OWNER NOT IN ('ANONYMOUS','APEX_030200','APEX_040000','APEX_SSO','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS','SI_INFORMTN_SCHEMA','SQLTXADMIN','SQLTXPLAIN','SYS','SYSMAN','SYSTEM','TRCANLZR','WMSYS','XDB','XS$NULL','PERFSTAT','STDBYPERF') 
                UNION ALL
                SELECT *
                  FROM (SELECT U.NAME OWNER,
                               O.NAME TABLE_NAME,
                               NULL PARTITION_NAME,
                               NULL SUBPARTITION_NAME,
                               M.INSERTS,
                               M.UPDATES,
                               M.DELETES,
                               M.TIMESTAMP,
                               DECODE(BITAND(M.FLAGS, 1), 1, 'YES', 'NO') TRUNCATED,
                               M.DROP_SEGMENTS
                          FROM SYS.MON_MODS$ M,
                               SYS.OBJ$      O,
                               SYS.TAB$      T,
                               SYS.USER$     U
                         WHERE O.OBJ# = M.OBJ#
                           AND O.OBJ# = T.OBJ#
                           AND O.OWNER# = U.USER#
                        UNION ALL
                        SELECT U.NAME,
                               O.NAME,
                               O.SUBNAME,
                               NULL,
                               M.INSERTS,
                               M.UPDATES,
                               M.DELETES,
                               M.TIMESTAMP,
                               DECODE(BITAND(M.FLAGS, 1), 1, 'YES', 'NO'),
                               M.DROP_SEGMENTS
                          FROM SYS.MON_MODS$ M, SYS.OBJ$ O, SYS.USER$ U
                         WHERE O.OWNER# = U.USER#
                           AND O.OBJ# = M.OBJ#
                           AND O.TYPE# = 19
                        UNION ALL
                        SELECT U.NAME,
                               O.NAME,
                               O2.SUBNAME,
                               O.SUBNAME,
                               M.INSERTS,
                               M.UPDATES,
                               M.DELETES,
                               M.TIMESTAMP,
                               DECODE(BITAND(M.FLAGS, 1), 1, 'YES', 'NO'),
                               M.DROP_SEGMENTS
                          FROM SYS.MON_MODS$   M,
                               SYS.OBJ$        O,
                               SYS.TABSUBPART$ TSP,
                               SYS.OBJ$        O2,
                               SYS.USER$       U
                         WHERE O.OBJ# = M.OBJ#
                           AND O.OWNER# = U.USER#
                           AND O.OBJ# = TSP.OBJ#
                           AND O2.OBJ# = TSP.POBJ#)
                 WHERE OWNER NOT IN ('ANONYMOUS','APEX_030200','APEX_040000','APEX_SSO','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS','SI_INFORMTN_SCHEMA','SQLTXADMIN','SQLTXPLAIN','SYS','SYSMAN','SYSTEM','TRCANLZR','WMSYS','XDB','XS$NULL','PERFSTAT','STDBYPERF'))
         ORDER BY INSERTS DESC)
 WHERE ROWNUM <= 50;


prompt expired Index Statistics
-- 检查无统计信息/统计信息过期/统计信息过旧的索引
-- 数据库存在无统计信息/统计信息过期/统计信息过旧的索引，SQL解析时CBO无法生成正确的执行计划，极大影响数据库性能
SELECT /*+ NO_MERGE */
       s.owner, s.table_name, s.index_name, s.stale_stats, to_char(s.last_analyzed,'YYYY/MM/DD HH24:MI:SS') as last_analyzed_time
  FROM dba_ind_statistics s,
       dba_indexes t
 WHERE s.OBJECT_TYPE = 'INDEX'
   AND s.owner NOT IN ('ANONYMOUS','APEX_030200','APEX_040000','APEX_SSO','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FIL
ES','FLOWS_FILES','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS','SI_INFORMTN_SCHEMA','SQLTXADMIN','SQLTXPLAIN
','SYS','SYSMAN','SYSTEM','TRCANLZR','WMSYS','XDB','XS$NULL','PERFSTAT','STDBYPERF')
   AND (s.last_analyzed IS NULL or  s.stale_stats = 'YES' or s.last_analyzed < sysdate -7)
   AND s.table_name NOT LIKE 'BIN%'
   AND NOT (s.table_name LIKE '%TEMP' OR s.table_name LIKE '%_TEMP_%' )
   AND t.owner = s.owner
   AND t.index_name = s.INDEX_NAME
   AND t.table_name = s.table_name
   AND t.temporary = 'N'
   and t.index_type != 'LOB'
   AND NOT EXISTS (
SELECT NULL
  FROM dba_external_tables e
 WHERE e.owner = s.owner
   AND e.table_name = s.table_name
)
 ORDER BY
       s.owner, s.table_name;

/**
exec DBMS_STATS.IMPORT_TABLE_STATS(ownname => :owner,tabname => :table_name,stattab => '',cascade => TRUE,statown => 'OPS$ADMIN');
**/
