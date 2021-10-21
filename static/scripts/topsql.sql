set linesize 1000
set pages 1000
col username for a30
col FIRST_LOAD_TIME for a25
SELECT * FROM (SELECT 
 A.PARSING_SCHEMA_NAME as username,
 A.SQL_ID,
 A.PLAN_HASH_VALUE AS PLAN_HASH_VALUE,
 ROUND(A.BUFFER_GETS / EXECUTIONS) AS LOGICAL_READ,
 A.BUFFER_GETS,
 A.EXECUTIONS,
 (round(to_number(a.last_active_time-to_date(a.FIRST_LOAD_TIME,'yyyy-mm-dd/hh24:mi:ss')),0)+ 1) AS last_day,
  round(a.EXECUTIONS / (round(to_number(a.last_active_time-to_date(a.FIRST_LOAD_TIME,'yyyy-mm-dd/hh24:mi:ss')),0)+ 1)) AS exe_per_day,
-- A.SQL_FULLTEXT AS SQL,
 A.FIRST_LOAD_TIME,
 A.LAST_LOAD_TIME,
 A.LAST_ACTIVE_TIME
  FROM V$SQLAREA A,
       (SELECT DISTINCT SQL_ID, SQL_PLAN_HASH_VALUE
          FROM V$ACTIVE_SESSION_HISTORY
         WHERE SAMPLE_TIME > sysdate-30
           AND SAMPLE_TIME <  SYSDATE) B
 WHERE A.SQL_ID = B.SQL_ID
   AND A.PLAN_HASH_VALUE = B.SQL_PLAN_HASH_VALUE
   AND A.BUFFER_GETS > 10000 
   AND round(a.EXECUTIONS / (round(to_number(a.last_active_time-to_date(a.FIRST_LOAD_TIME,'yyyy-mm-dd/hh24:mi:ss')),0)+ 1)) > 1 
   AND ROUND(A.BUFFER_GETS / EXECUTIONS) > &PER_BUFFER_GETS
 ORDER BY ROUND(A.BUFFER_GETS / EXECUTIONS) DESC, 
	  round(a.EXECUTIONS / (round(to_number(a.last_active_time-to_date(a.FIRST_LOAD_TIME,'yyyy-mm-dd/hh24:mi:ss')),0)+ 1)) DESC
) WHERE EXE_PER_DAY > 24 * 6;