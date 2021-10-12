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
         WHERE SAMPLE_TIME > &BEGIN_SAMPLE_TIME
           AND SAMPLE_TIME <  SYSDATE) B
 WHERE A.SQL_ID = B.SQL_ID
   AND A.PLAN_HASH_VALUE = B.SQL_PLAN_HASH_VALUE
   AND A.BUFFER_GETS > 10000 
   AND round(a.EXECUTIONS / (round(to_number(a.last_active_time-to_date(a.FIRST_LOAD_TIME,'yyyy-mm-dd/hh24:mi:ss')),0)+ 1)) > 1 
   AND ROUND(A.BUFFER_GETS / EXECUTIONS) > &PER_BUFFER_GETS
 ORDER BY ROUND(A.BUFFER_GETS / EXECUTIONS) DESC, 
	  round(a.EXECUTIONS / (round(to_number(a.last_active_time-to_date(a.FIRST_LOAD_TIME,'yyyy-mm-dd/hh24:mi:ss')),0)+ 1)) DESC
) WHERE EXE_PER_DAY > 24 * 6;

/*检查数据库中逻辑读，物理读过高的SQL */ 

col start_time for a30
SELECT sql_id,round(buff_exec) * exec_times gets_total,round( buff_exec ) gets_exec,round(disk_exec) disk_exec,exec_times,start_time,end_time FROM
(
SELECT
	sql_id,
	avg( buffer_gets_exec ) buff_exec,
	avg( disk_reads_exec ) disk_exec,
	sum( executions_total ) exec_times,
	min( begin_interval_time ) start_time,
	max( begin_interval_time ) end_time 
FROM
	(
	SELECT
		begin_interval_time,
		sql_id,
		buffer_gets_total,
		disk_reads_total,
		executions_total,
		round(
		buffer_gets_total / nvl( executions_total, 1 )) buffer_gets_exec,
		round(
		disk_reads_total / nvl( executions_total, 1 )) disk_reads_exec 
	FROM
		dba_hist_sqlstat s,
		dba_hist_snapshot n 
	WHERE
		s.snap_id = n.snap_id 
		AND executions_total > 0 
		AND parsing_schema_name NOT IN (
			'ANONYMOUS','APEX_030200','APEX_040000','APEX_SSO',
			'APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES',
			'MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS',
			'ORDSYS','OUTLN','OWBSYS','SI_INFORMTN_SCHEMA','SQLTXADMIN',
			'SQLTXPLAIN','SYS','SYSMAN','SYSTEM','TRCANLZR','WMSYS','XDB',
			'XS$NULL','PERFSTAT',
			'STDBYPERF') 
		AND ( round( buffer_gets_total / nvl( executions_total, 1 ) ) > 99999 OR round( disk_reads_total / nvl( executions_total, 1 )) > 9999 ) 
			AND executions_total > 9 
		) 
	GROUP BY
	sql_id 
	);
set long 10000
set feedback off
var USERNAME varchar2(60)
BEGIN
  :USERNAME := TRIM(UPPER('&USERNAME'));
END;
/
col username for a30
select :USERNAME as username from dual;


set linesize 500
set pages 200
col OBJECT_NAME for a20
col sql_id for a15
col SQL_TEXT for a60
col FTEXT for a60
col FILTER_PREDICATES for a10
col PARSING_SCHEMA_NAME for a20
WITH FSQL AS
 (SELECT /*+ materialize */
   SQL_ID, TO_CLOB(UPPER(SQL_FULLTEXT)) AS FTEXT
    FROM V$SQL
   WHERE PARSING_SCHEMA_NAME = :USERNAME),
SQLID AS
 (SELECT /*+ materialize */
   PARSING_SCHEMA_NAME, SQL_ID, SQL_TEXT
    FROM V$SQL
   WHERE PARSING_SCHEMA_NAME = :USERNAME
   GROUP BY PARSING_SCHEMA_NAME, SQL_ID, SQL_TEXT),
SQL AS
 (SELECT PARSING_SCHEMA_NAME,
         SQL_ID,
         SQL_TEXT,
         (SELECT FTEXT
            FROM FSQL
           WHERE SQL_ID = A.SQL_ID
             AND ROWNUM <= 1) FTEXT
    FROM SQLID A),
COL AS
 (SELECT /*+ materialize */
   A.SQL_ID,
   A.OBJECT_OWNER,
   A.OBJECT_NAME,
   NVL(A.FILTER_PREDICATES, 'NULL') FILTER_PREDICATES,
   A.COLUMN_CNT,
   B.COLUMN_CNTTOTAL,
   B.SIZE_MB
    FROM (SELECT SQL_ID,
                 OBJECT_OWNER,
                 OBJECT_NAME,
                 OBJECT_TYPE,
                 FILTER_PREDICATES,
                 ACCESS_PREDICATES,
                 PROJECTION,
                 LENGTH(PROJECTION) -
                 LENGTH(REPLACE(PROJECTION, '], ', '] ')) + 1 COLUMN_CNT
            FROM V$SQL_PLAN
           WHERE OBJECT_OWNER = :USERNAME
             AND OPERATION = 'TABLE ACCESS'
             AND OPTIONS = 'FULL'
             AND OBJECT_TYPE = 'TABLE') A,
         (SELECT /*+ USE_HASH(A,B) */
           A.OWNER, A.TABLE_NAME, A.COLUMN_CNTTOTAL, B.SIZE_MB
            FROM (SELECT OWNER, TABLE_NAME, COUNT(*) COLUMN_CNTTOTAL
                    FROM DBA_TAB_COLUMNS
                   WHERE OWNER = :USERNAME
                   GROUP BY OWNER, TABLE_NAME) A,
                 (SELECT OWNER, SEGMENT_NAME, SUM(BYTES / 1024 / 1024) SIZE_MB
                    FROM DBA_SEGMENTS
                   WHERE OWNER = :USERNAME
                   GROUP BY OWNER, SEGMENT_NAME) B
           WHERE A.OWNER = B.OWNER
             AND A.TABLE_NAME = B.SEGMENT_NAME) B
   WHERE A.OBJECT_OWNER = B.OWNER
     AND A.OBJECT_NAME = B.TABLE_NAME)
SELECT A.PARSING_SCHEMA_NAME,
       A.SQL_ID,
       A.SQL_TEXT,
       B.OBJECT_NAME,
       B.SIZE_MB,
       B.COLUMN_CNT,
       B.COLUMN_CNTTOTAL,
       B.FILTER_PREDICATES
  FROM SQL A, COL B
 WHERE A.SQL_ID = B.SQL_ID
 ORDER BY B.SIZE_MB DESC, B.COLUMN_CNT ASC;
/*检查数据库中逻辑读，物理读过高的SQL */ 

col start_time for a30
SELECT sql_id,round(buff_exec) * exec_times gets_total,round( buff_exec ) gets_exec,round(disk_exec) disk_exec,exec_times,start_time,end_time FROM
(
SELECT
	sql_id,
	avg( buffer_gets_exec ) buff_exec,
	avg( disk_reads_exec ) disk_exec,
	sum( executions_total ) exec_times,
	min( begin_interval_time ) start_time,
	max( begin_interval_time ) end_time 
FROM
	(
	SELECT
		begin_interval_time,
		sql_id,
		buffer_gets_total,
		disk_reads_total,
		executions_total,
		round(
		buffer_gets_total / nvl( executions_total, 1 )) buffer_gets_exec,
		round(
		disk_reads_total / nvl( executions_total, 1 )) disk_reads_exec 
	FROM
		dba_hist_sqlstat s,
		dba_hist_snapshot n 
	WHERE
		s.snap_id = n.snap_id 
		AND executions_total > 0 
		AND parsing_schema_name NOT IN (
			'ANONYMOUS',
			'APEX_030200',
			'APEX_040000',
			'APEX_SSO',
			'APPQOSSYS',
			'CTXSYS',
			'DBSNMP',
			'DIP',
			'EXFSYS',
			'FLOWS_FILES',
			'MDSYS',
			'OLAPSYS',
			'ORACLE_OCM',
			'ORDDATA',
			'ORDPLUGINS',
			'ORDSYS',
			'OUTLN',
			'OWBSYS',
			'SI_INFORMTN_SCHEMA',
			'SQLTXADMIN',
			'SQLTXPLAIN',
			'SYS',
			'SYSMAN',
			'SYSTEM',
			'TRCANLZR',
			'WMSYS',
			'XDB',
			'XS$NULL',
			'PERFSTAT',
			'STDBYPERF') 
		AND ( round( buffer_gets_total / nvl( executions_total, 1 ) ) > 99999 OR round( disk_reads_total / nvl( executions_total, 1 )) > 9999 ) 
			AND executions_total > 9 
		) 
	GROUP BY
	sql_id 
	);
