


set serveroutput on 
set verify off
set timing off
set linesize 500
set pages 0
--alter session set nls_date_format='yyyy-mm-dd hh24:mi:ss';
declare
    cursor c_sga is SELECT NAME, ROUND(TOTAL,2) TOTAL_MB, ROUND(TOTAL - FREE, 2) USED_MB, ROUND(FREE, 2) FREE_MB, ROUND((TOTAL - FREE) / TOTAL * 100, 2) pct_used
  FROM (SELECT 'SGA' NAME,
               (SELECT SUM(VALUE / 1024 / 1024) FROM V$SGA) TOTAL,
               (SELECT SUM(BYTES / 1024 / 1024)
                  FROM V$SGASTAT
                 WHERE NAME = 'free memory') FREE
          FROM DUAL)
UNION
SELECT NAME, ROUND(TOTAL,2) TOTAL_MB, ROUND(USED, 2) USED_MB, ROUND(TOTAL - USED, 2) FREE_MB, ROUND(USED / TOTAL * 100, 2) pct_used
  FROM (SELECT 'PGA' NAME,
               (SELECT VALUE / 1024 / 1024 TOTAL
                  FROM V$PGASTAT
                 WHERE NAME = 'aggregate PGA target parameter') TOTAL,
               (SELECT VALUE / 1024 / 1024 USED
                  FROM V$PGASTAT
                 WHERE NAME = 'total PGA allocated') USED
          FROM DUAL)
UNION
SELECT NAME, ROUND(TOTAL, 2) TOTAL_MB, ROUND((TOTAL - FREE), 2) USED_MB, ROUND(FREE, 2) FREE_MB, ROUND((TOTAL - FREE) / TOTAL * 100, 2) pct_used
  FROM (SELECT 'Shared pool' NAME,
               (SELECT SUM(BYTES / 1024 / 1024)
                  FROM V$SGASTAT
                 WHERE POOL = 'shared pool') TOTAL,
               (SELECT BYTES / 1024 / 1024
                  FROM V$SGASTAT
                 WHERE NAME = 'free memory'
                   AND POOL = 'shared pool') FREE
          FROM DUAL)
UNION
SELECT NAME, ROUND(TOTAL, 2) TOTAL_MB, ROUND(TOTAL - FREE, 2) USED_MB, ROUND(FREE, 2) FREE_MB, ROUND((TOTAL - FREE) / TOTAL * 100, 2) pct_used
  FROM (SELECT 'Default pool' NAME,
               (SELECT A.CNUM_REPL *
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size') / 1024 / 1024 TOTAL
                  FROM X$KCBWDS A, V$BUFFER_POOL P
                 WHERE A.SET_ID = P.LO_SETID
                   AND P.NAME = 'DEFAULT'
                   AND P.BLOCK_SIZE =
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size')) TOTAL,
               (SELECT A.ANUM_REPL *
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size') / 1024 / 1024 FREE
                  FROM X$KCBWDS A, V$BUFFER_POOL P
                 WHERE A.SET_ID = P.LO_SETID
                   AND P.NAME = 'DEFAULT'
                   AND P.BLOCK_SIZE =
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size')) FREE
          FROM DUAL)
UNION
SELECT NAME, NVL(ROUND(TOTAL, 2), 0) TOTAL_MB, NVL(ROUND(TOTAL - FREE, 2), 0) USED_MB, NVL(ROUND(FREE, 2), 0) FREE_MB, NVL(ROUND((TOTAL - FREE) / TOTAL, 2), 0) pct_used
  FROM (SELECT 'KEEP pool' NAME,
               (SELECT A.CNUM_REPL *
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size') / 1024 / 1024 TOTAL
                  FROM X$KCBWDS A, V$BUFFER_POOL P
                 WHERE A.SET_ID = P.LO_SETID
                   AND P.NAME = 'KEEP'
                   AND P.BLOCK_SIZE =
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size')) TOTAL,
               (SELECT A.ANUM_REPL *
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size') / 1024 / 1024 FREE
                  FROM X$KCBWDS A, V$BUFFER_POOL P
                 WHERE A.SET_ID = P.LO_SETID
                   AND P.NAME = 'KEEP'
                   AND P.BLOCK_SIZE =
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size')) FREE
          FROM DUAL)
UNION
SELECT NAME, NVL(ROUND(TOTAL, 2), 0) TOTAL_MB, NVL(ROUND(TOTAL - FREE, 2), 0) USED_MB, NVL(ROUND(FREE, 2), 0) FREE_MB, NVL(ROUND((TOTAL - FREE) / TOTAL, 2), 0) pct_used
  FROM (SELECT 'RECYCLE pool' NAME,
               (SELECT A.CNUM_REPL *
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size') / 1024 / 1024 TOTAL
                  FROM X$KCBWDS A, V$BUFFER_POOL P
                 WHERE A.SET_ID = P.LO_SETID
                   AND P.NAME = 'RECYCLE'
                   AND P.BLOCK_SIZE =
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size')) TOTAL,
               (SELECT A.ANUM_REPL *
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size') / 1024 / 1024 FREE
                  FROM X$KCBWDS A, V$BUFFER_POOL P
                 WHERE A.SET_ID = P.LO_SETID
                   AND P.NAME = 'RECYCLE'
                   AND P.BLOCK_SIZE =
                       (SELECT VALUE
                          FROM V$PARAMETER
                         WHERE NAME = 'db_block_size')) FREE
          FROM DUAL)
UNION
SELECT NAME, NVL(ROUND(TOTAL, 2), 0) TOTAL_MB, NVL(ROUND(TOTAL - FREE, 2), 0) USED_MB, NVL(ROUND(FREE, 2), 0) FREE_MB, NVL(ROUND((TOTAL - FREE) / TOTAL, 2), 0) pct_used
  FROM (SELECT 'DEFAULT 16K buffer cache' NAME,
               (SELECT A.CNUM_REPL * 16 / 1024 TOTAL
                  FROM X$KCBWDS A, V$BUFFER_POOL P
                 WHERE A.SET_ID = P.LO_SETID
                   AND P.NAME = 'DEFAULT'
                   AND P.BLOCK_SIZE = 16384) TOTAL,
               (SELECT A.ANUM_REPL * 16 / 1024 FREE
                  FROM X$KCBWDS A, V$BUFFER_POOL P
                 WHERE A.SET_ID = P.LO_SETID
                   AND P.NAME = 'DEFAULT'
                   AND P.BLOCK_SIZE = 16384) FREE
          FROM DUAL)
UNION
SELECT NAME, NVL(ROUND(TOTAL, 2), 0) TOTAL_MB, NVL(ROUND(TOTAL - FREE, 2), 0) USED_MB, NVL(ROUND(FREE, 2), 0) FREE_MB, NVL(ROUND((TOTAL - FREE) / TOTAL, 2), 0) pct_used
  FROM (SELECT 'DEFAULT 32K buffer cache' NAME,
               (SELECT A.CNUM_REPL * 32 / 1024 TOTAL
                  FROM X$KCBWDS A, V$BUFFER_POOL P
                 WHERE A.SET_ID = P.LO_SETID
                   AND P.NAME = 'DEFAULT'
                   AND P.BLOCK_SIZE = 32768) TOTAL,
               (SELECT A.ANUM_REPL * 32 / 1024 FREE
                  FROM X$KCBWDS A, V$BUFFER_POOL P
                 WHERE A.SET_ID = P.LO_SETID
                   AND P.NAME = 'DEFAULT'
                   AND P.BLOCK_SIZE = 32768) FREE
          FROM DUAL)
UNION
SELECT NAME, TOTAL as TOTAL_MB, TOTAL - FREE USED_MB, FREE as FREE_MB,
       (TOTAL - FREE) / TOTAL * 100 pct_used
  FROM (SELECT 'Java Pool' NAME,
               (SELECT SUM(BYTES / 1024 / 1024) TOTAL
                  FROM V$SGASTAT
                 WHERE POOL = 'java pool'
                 GROUP BY POOL) TOTAL,
               (SELECT BYTES / 1024 / 1024 FREE
                  FROM V$SGASTAT
                 WHERE POOL = 'java pool'
                   AND NAME = 'free memory') FREE
          FROM DUAL)
UNION
SELECT NAME, ROUND(TOTAL, 2) as TOTAL_MB, ROUND(TOTAL - FREE, 2) USED_MB, ROUND(FREE, 2) FREE_MB, ROUND((TOTAL - FREE) / TOTAL * 100, 2) pct_used
  FROM (SELECT 'Large Pool' NAME,
               (SELECT SUM(BYTES / 1024 / 1024) TOTAL
                  FROM V$SGASTAT
                 WHERE POOL = 'large pool'
                 GROUP BY POOL) TOTAL,
               (SELECT BYTES / 1024 / 1024 FREE
                  FROM V$SGASTAT
                 WHERE POOL = 'large pool'
                   AND NAME = 'free memory') FREE
          FROM DUAL)
 ORDER BY pct_used DESC;
    v_sga c_sga%rowtype;

    cursor c_com is select COMPONENT,
round(CURRENT_SIZE/1024/1024/1024,2) as CURRENT_G,
round(MIN_SIZE/1024/1024/1024,2) MIN_G,
round(MAX_SIZE/1024/1024/1024,2) as MAX_G,
round(USER_SPECIFIED_SIZE/1024/1024/1024,2) as USER_SPECIFIED_G,
OPER_COUNT,
LAST_OPER_TYPE,
decode(LAST_OPER_MODE,null,'None',LAST_OPER_MODE) as LAST_OPER_MODE,
decode(LAST_OPER_TIME,null,'None',LAST_OPER_TIME) as LAST_OPER_TIME,
round(GRANULE_SIZE/1024/1024) as GRANULE_SIZE_M
from v$sga_dynamic_components;
   v_com c_com%rowtype;

    cursor c_sub is SELECT
     'shared pool ('||NVL(DECODE(TO_CHAR(ksmdsidx),'0','0 - Unused',ksmdsidx), 'Total')||'):'  subpool
    , SUM(ksmsslen) bytes
    , ROUND(SUM(ksmsslen)/1048576,2) MB FROM x$ksmss WHERE ksmsslen > 0
   GROUP BY ROLLUP (ksmdsidx) ORDER BY
    subpool ASC;
    v_sub c_sub%rowtype;

    cursor c_subcom is select * from (
  SELECT 'shared pool ('||DECODE(TO_CHAR(ksmdsidx),'0','0 - Unused',ksmdsidx)||'):' subpool, 
    ksmssnam as name, 
    round(ksmsslen/1024/1024,2)  as MB,
    round(100 * ksmsslen/sum(ksmsslen) over(partition by ksmdsidx),2) as pct,
    rank() over(partition by ksmdsidx order by ksmsslen desc) as rank
  FROM  x$ksmss WHERE ksmsslen > 0
  ) where rank < 21;
    v_subcom c_subcom%rowtype;

    cursor c_row is select la.addr,
  dc.kqrstcid cache,
  dc.kqrsttxt parameter,
  decode(dc.kqrsttyp,1,'PARENT','SUBORDINATE') type,
  decode(decode(dc.kqrsttyp,2,kqrstsno,null),null,'None',decode(dc.kqrsttyp,2,kqrstsno,null)) subordinate,
  dc.kqrstgrq gets,
  dc.kqrstgmi misses,
  dc.kqrstmrq modifications,
  dc.kqrstmfl flushes,
  dc.kqrstcln child_no,
  la.gets as lagets,
  la.misses as lamisses,
  la.immediate_gets laimge
from
  x$kqrst dc,
  v$latch_children la
where
  dc.inst_id = userenv('instance')
  and la.child# = dc.kqrstcln
  and la.name = 'row cache objects'
  order by 2,3,4,5;
  v_r c_row%rowtype;
  
  cursor c_b is select
        /*+ ordered */
        bp.name as pool_name,
        u.username as username,
        ob.name as object_name,
        decode(ob.subname,null,'None',ob.subname) as sub_name,
        decode(ob.type#,
         0,'NEXT OBJECT',1,'INDEX',2,'TABLE',3, 'CLUSTER',4,'VIEW',5, 'SYNONYM',
         6,'SEQUENCE',7, 'PROCEDURE',8, 'FUNCTION',9, 'PACKAGE',11, 'PACKAGE BODY',12, 'TRIGGER',13, 'TYPE',
         14,'TYPE BODY',19, 'TABLE PARTITION', 20, 'INDEX PARTITION', 21, 'LOB',
         22,'LIBRARY', 23, 'DIRECTORY', 24, 'QUEUE',28, 'JAVA SOURCE', 29, 'JAVA CLASS', 30,'JAVA RESOURCE',
         32,'INDEXTYPE',33, 'OPERATOR',34,'TABLE SUBPARTITION',35,'INDEX SUBPARTITION',40,'LOB PARTITION', 41, 'LOB SUBPARTITION',
         43, 'DIMENSION',
         44, 'CONTEXT', 46, 'RULE SET', 47, 'RESOURCE PLAN',
         48, 'CONSUMER GROUP',
         51, 'SUBSCRIPTION', 52, 'LOCATION',
         55, 'XML SCHEMA', 56, 'JAVA DATA',
         57, 'SECURITY PROFILE', 59, 'RULE',
         60, 'CAPTURE', 61, 'APPLY',
         62, 'EVALUATION CONTEXT',
         66, 'JOB', 67, 'PROGRAM', 68, 'JOB CLASS', 69, 'WINDOW',
         72, 'WINDOW GROUP', 74, 'SCHEDULE', 79, 'CHAIN',
         81, 'FILE GROUP',
        'UNDEFINED') object_type,
        sum(bh.ct) as blocks,
        round((sum(bh.ct)*(select value from v$parameter where name = 'db_block_size' and rownum = 1))/1024/1024,2) as size_mb
from (
        select set_ds, obj, count(*) ct
        from x$bh group by set_ds, obj
        )                      bh,
        obj$                   ob,
        x$kcbwds               ws,
        v$buffer_pool          bp,
        dba_users              u
where
        ob.dataobj# = bh.obj
and     ob.owner#   = u.user_id
and     bh.set_ds   = ws.addr
and     ws.set_id in (bp.lo_setid,bp.hi_setid)  -- between bp.lo_setid and bp.hi_setid
and     bp.buffers != 0        --  Eliminate any pools not in use^M
and     u.username not in('SYS','SYSTEM','WMSYS','XDB',
                       'QMONITOR','OUTLN','ORDSYS','ORDDATA','OJVMSYS','MDSYS','LBACSYS','DVSYS',
                       'DBSNMP','APEX_040200','AUDSYS','CTXSYS','APEX_030200','EXFSYS','OLAPSYS','SYSMAN','WH_SYNC','GSMADMIN_INTERNAL')
group by u.username,bp.name, ob.name,ob.type#,ob.subname
order by bp.name, blocks desc, ob.name, ob.subname;
  v_b c_b%rowtype;
  v_dic_per varchar2(200);
  v_lib_per varchar2(200); 


begin
  DBMS_OUTPUT.ENABLE(buffer_size => null);

  select trunc(sum(gets-getmisses-usage-fixed)/sum(gets)*100,2) into v_dic_per from v$rowcache;
  select trunc(sum(pinhits)/sum(pins)*100,2) into v_lib_per from v$librarycache;
   dbms_output.put_line('
Dictionary Cache hit % and Library Cache hit%)');
  dbms_output.put_line('======================');
  dbms_output.put_line('----------------------------------------------');
  dbms_output.put_line('| Dictionary Cache hit% |' || ' Library Cache hit%' || ' |');
  dbms_output.put_line('----------------------------------------------');
  dbms_output.put_line('| ' || lpad(v_dic_per,21) ||' | '|| lpad(v_lib_per,18) || ' |');
  dbms_output.put_line('----------------------------------------------');


  dbms_output.put_line('
SGA and PGA Usage Size and Pct)');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| NAME                          |' || ' TOTAL_MB       ' || '| USED_MB        |' || ' FREE_MB         ' || '| PCT_USED%'|| ' |');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------');
  open c_sga;
    loop fetch c_sga into v_sga;
    exit when c_sga%notfound;
    dbms_output.put_line('| ' || rpad(v_sga.NAME,29) ||' | '|| lpad(v_sga.TOTAL_MB,14) || ' | '|| lpad(v_sga.USED_MB,14) || ' | '|| lpad(v_sga.FREE_MB,15) || ' | '|| lpad(v_sga.pct_used,9) || ' |');
    end loop;
    dbms_output.put_line('-------------------------------------------------------------------------------------------------');
  close c_sga;


    dbms_output.put_line('
SGA components Information from v$sga_dynamic_components');
  dbms_output.put_line('======================');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| COMPONENT                 |' || ' CURRENT_GB ' || '| MIN_GB |' || ' MAX_GB ' || '| USER_SPECIFIED_GB |' || ' OPER_COUNT ' || '| LAST_OPER_TYPE |' || ' LAST_OPER_MODE '  || '| LAST_OPER_TIME      |'|| ' GRANULE_SIZE_MB '|| '|');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_com;
    loop fetch c_com into v_com;
    exit when c_com%notfound;
    dbms_output.put_line('| ' || rpad(v_com.COMPONENT,25) ||' | '|| lpad(v_com.CURRENT_G,10) || ' | '|| lpad(v_com.MIN_G,6) || ' | '|| lpad(v_com.MAX_G,6) || ' | '|| lpad(v_com.USER_SPECIFIED_G,17) || ' | '|| lpad(v_com.OPER_COUNT,10) ||  ' | '|| rpad(v_com.LAST_OPER_TYPE,14) || ' | '|| rpad(v_com.LAST_OPER_MODE,14) || ' | '|| rpad(v_com.LAST_OPER_TIME,19) || ' | '|| lpad(v_com.GRANULE_SIZE_M,15)||' |');
    end loop;
    dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_com;


  dbms_output.put_line('
Shared Pool Sub Pool Size Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('---------------------------------------------------------------');
  dbms_output.put_line('| SUBPOOL                |' || ' SUBPOOL_BYTES         ' || '| SUBPOOL_MB ' || '|');
  dbms_output.put_line('---------------------------------------------------------------');
  open c_sub;
    loop fetch c_sub into v_sub;
    exit when c_sub%notfound;
    dbms_output.put_line('| ' || rpad(v_sub.subpool,22) ||' | '|| lpad(v_sub.bytes,21) || ' | '|| lpad(v_sub.MB,10) || ' |');
    end loop;
    dbms_output.put_line('---------------------------------------------------------------');
  close c_sub;

  dbms_output.put_line('
Shared Pool Sub Pool components Detail Information');
  dbms_output.put_line('======================');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| RANK |' || ' SUBPOOL                |' || ' COMPONENT_NAME                     ' || '| CURRENT_SIZE_MB |' || ' CURRENT_PCT% ' || '|');
  dbms_output.put_line('-------------------------------------------------------------------------------------------------------');
  open c_subcom;
    loop fetch c_subcom into v_subcom;
    exit when c_subcom%notfound;
    dbms_output.put_line('| ' || lpad(v_subcom.RANK,4)|| ' | ' || rpad(v_subcom.SUBPOOL,22) ||' | '|| rpad(v_subcom.NAME,34) || ' | '|| lpad(v_subcom.MB || ' M',15) || ' | '|| lpad(v_subcom.pct || '%',12) || ' |');
    end loop;
    dbms_output.put_line('-------------------------------------------------------------------------------------------------------');
  close c_subcom;



    dbms_output.put_line('
Latch: row cache objects On Dc_objects Information from x$kqrst
Doc ID 2359175.1');
  dbms_output.put_line('======================');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| ADDR             ' || '| c# |' || ' parameter                        ' || '| type        |' || ' s# ' || '| gets       |' || ' misses   ' || '| modi_s   |' || ' flushes '  || '| ch# |'|| ' lagets   '|| '| lamisses |' || ' laimge ' ||'|');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------');
  open c_row;
    loop fetch c_row into v_r;
    exit when c_row%notfound;
    dbms_output.put_line('| ' || lpad(v_r.addr,16) || ' | '|| lpad(v_r.cache,2) ||' | '|| rpad(v_r.parameter,32) || ' | '|| rpad(v_r.type,11) || ' | '|| lpad(v_r.subordinate,2) || ' | '|| lpad(v_r.gets,10) || ' | '|| lpad(v_r.misses,8) ||  ' | '|| lpad(v_r.modifications,8) || ' | '|| lpad(v_r.flushes,7) || ' | '|| lpad(v_r.child_no,3) || ' | '|| lpad(v_r.lagets,8) || ' | ' || lpad(v_r.lamisses,8) || ' | '|| lpad(v_r.laimge,6)|| ' |');
    end loop;
    dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------------------------------------------');
  close c_row;

  dbms_output.put_line('
Which Table or Index Objects in DB Buffer Cache(Defaul Pool,Keep Pool) ');
  dbms_output.put_line('======================');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------');
  dbms_output.put_line('| POOL_NAME  ' || '| USERNAME         |' || ' OBJECT_NAME           ' || '| SUB_NAME          |' || ' OBJECT_TYPE       ' || '| BLOCKS     |' || ' SIZE_MB      ' ||'|');
  dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------');
  open c_b;
    loop fetch c_b into v_b;
    exit when c_b%notfound;
    dbms_output.put_line('| ' || rpad(v_b.POOL_NAME,10) || ' | '|| rpad(v_b.USERNAME,16) ||' | '|| rpad(v_b.OBJECT_NAME,21) || ' | '|| rpad(v_b.SUB_NAME,17) || ' | '|| rpad(v_b.OBJECT_TYPE,17) || ' | '|| lpad(v_b.BLOCKS,10) || ' | '|| lpad(v_b.SIZE_MB,12) ||  ' |');
    end loop;
    dbms_output.put_line('-----------------------------------------------------------------------------------------------------------------------------');
  close c_b;


end;
/


--Library pool usage
-- library pool
set pages 1000
set lines 400
break on report 
compute sum of gets on report
compute sum of pins on report
compute avg of "gethitratio(%)" on report
compute avg of "pinhitratio(%)" on report
compute avg of "loadpinratio(%)" on report
compute avg of invalidations on report
col namespace for a40
prompt loadpinratio < 1%
prompt gethitratio > 95% 
prompt invalidations = 0
select namespace,gets,round(gethitratio*100,2) "gethitratio(%)",
       pins,round(pinhitratio*100,2) "pinhitratio(%)",
       round((reloads)/decode(pins,0,1,pins)*100,2) "loadpinratio(%)", invalidations
  from v$librarycache;

prompt Estimate library cache size = sum(sharable_mem from v$db_object_cache) 
prompt                               + 250 * total_opening_cursors
select sum(estimate_size) "estimate library cache size"
  from   (
    select sum(sharable_mem) estimate_size from v$db_object_cache
      where type in ('PACKAGE','PACKAGE BODY','FUNCTION','PROCEDURE')
    union all  
    select sum(sharable_mem) estimate_size from v$db_object_cache 
      where executions > 5  
    union all
    select 250 * sum(users_opening ) estimate_size from v$sql
  ) ;


-- dictionary pool
compute avg of "getmissratio(%)" on report
prompt getmisses/gets < 15%
select parameter, round(getmisses/decode(gets,0,1,gets)*100,2) "getmissratio(%)"
  from v$rowcache
  order by 2 desc;

-- shared_pool_reserved
prompt free_space > 1/2 shared_pool_reserved and request_misses = 0 ---- too large
prompt request_failures > 0  --- too small 
select free_space,avg_free_size,request_misses,request_failures,aborted_requests
  from v$shared_pool_reserved;

col object_name format a30    
col owner format a10
prompt object could be pin in the database
select 
  owner,
  name as object_name,
  sharable_mem,
  executions,
  type,
  loads
from v$db_object_cache 
where sharable_mem > 10000
  and kept = 'NO'
  and type in ('PACKAGE','PACKAGE BODY','FUNCTION','PROCEDURE','SEQUENCE','TYPE','TRIGGER','SYNONYM');
