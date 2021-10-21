-- 检查数据库是否存在没有配置缓存的序列
SELECT
s.SEQUENCE_OWNER,SEQUENCE_NAME,CACHE_SIZE
from dba_sequences s
where
s.sequence_owner not in ('ANONYMOUS','APEX_030200','APEX_040000','APEX_040200','DVSYS','LBACSYS','OJVMSYS','APEX_SSO','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS','SI_INFORMTN_SCHEMA','SQLTXADMIN','SQLTXPLAIN','SYS','SYSMAN','SYSTEM','TRCANLZR','WMSYS','XDB','XS$NULL','PERFSTAT','STDBYPERF')
and s.max_value > 0
and s.CACHE_SIZE < 100;
--Show the procedures that are cached in the library cache
col owner for a15
col name for a30
col type for a20
select owner,name,type,executions,pins,locks from v$db_object_cache where locks > 0 and pins > 0 and type='PROCEDURE';



with t1 as(
select time_dp , 24*60*60*(time_dp - lag(time_dp) over (order by time_dp)) timediff,
  scn - lag(scn) over(order by time_dp) scndiff
from smon_scn_time
)
select time_dp , timediff, scndiff,
       trunc(scndiff/timediff) rate_per_sec
from t1
order by 1
/

prompt scn rate
set pages 200
col first_change# format 99999999999999999999
col next_change# format 99999999999999999999
select  thread#,  first_time, next_time, first_change# ,next_change#, sequence#,
   next_change#-first_change# diff, round ((next_change#-first_change#)/(next_time-first_time)/24/60/60) rt
from (
select thread#, first_time, first_change#,next_time,  next_change#, sequence#,dest_id from v$archived_log
where next_time > sysdate-30 and dest_id=1
order by next_time
)
where first_time != next_time
order by first_time, thread#
/



/**

　　本视图提供对象在library cache(shared pool)中对象统计，提供比v$librarycache更多的细节，并且常用于找出shared pool中的活动对象。

v$db_object_cache中的常用列：

         OWNER：对象拥有者
         NAME：对象名称
         TYPE：对象类型(如，sequence,procedure,function,package,package body,trigger)
         KEPT：告知是否对象常驻shared pool(yes/no)，有赖于这个对象是否已经利用PL/SQL 过程DBMS_SHARED_POOL.KEEP“保持”（永久固定在内存中）
         SHARABLE_MEM：共享内存占用
         PINS：当前执行对象的session数
         LOCKS：当前锁定对象的session数

瞬间状态列：
下列列保持对象自初次加载起的统计信息：

l         LOADS：对象被加载次数。

示例：

 1.shared pool执行以及内存使用总计

下列查询显示出shared pool内存对不同类别的对象

--同时也显示是否有对象通过DBMS_SHARED_POOL.KEEP()过程常驻shared pool。

SELECT type, kept, COUNT(*), SUM(sharable_mem)
 FROM V$DB_OBJECT_CACHE
 GROUP BY type, kept;

2.通过载入次数找出对象
col owner for a13
col name for a51
SELECT owner, substr(name,0,50) as name , sharable_mem, kept, loads
 FROM V$DB_OBJECT_CACHE
 WHERE loads > 1 ORDER BY loads DESC;

3.找出使用的内存超过10M并且不在常驻内存的对象。

SELECT owner, name, sharable_mem, kept
 FROM V$DB_OBJECT_CACHE
 WHERE sharable_mem > 102400 AND kept = 'NO'
 ORDER BY sharable_mem DESC;


**/
