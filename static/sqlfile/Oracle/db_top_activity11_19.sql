with tmp as
    (select 1 value,
	a.inst_id as instance_id,
	a.SESSION_ID || ',' || a.SESSION_SERIAL# || '@'|| a.inst_id SESSION_ID,
round((cast(a.sample_time as date)-a.sql_exec_start)*24*3600) SQL_ELAPSED_TIME,
	(select username from dba_users u where u.user_id = a.user_id) username,
	a.machine,
	a.program,
	--status,
	case a.SQL_OPCODE
	when 1 then 'CREATE TABLE'
	when 2 then 'INSERT'
	when 3 then 'SELECT'
	when 6 then 'UPDATE'
	when 7 then 'DELETE'
	when 9 then 'CREATE INDEX'
	when 11 then 'ALTER INDEX'
	when 15 then 'ALTER INDEX' else 'Others' end command,
	case when a.SQL_ID is null then 'Null' when a.SQL_ID is not null then a.sql_id end as SQL_ID,
	a.SQL_PLAN_HASH_VALUE,
	nvl(a.event, 'ON CPU') event,
	nvl(a.wait_class, 'ON CPU') wait_class,
	a.module,
	a.action,
        top_level_sql_id,
	(select name from V$ACTIVE_SERVICES s where s.NAME_HASH = a.SERVICE_HASH) SERVICE_NAME,
(select sql_text from gv$sql s where s.sql_id = a.sql_id and rownum = 1) sql_text
   from gv$active_session_history a
where a.SAMPLE_TIME between (sysdate - 1) and sysdate)

select * from (
SELECT
sql_id,
CAST (round( 100.0 * COUNT(*) / (select count(*) from tmp) , 2 ) AS REAL ) ratio,
CAST (round( 10.0 * COUNT(*) / (select count(*) from tmp) , 2 ) AS REAL ) average_active_session,
ROUND(100.0 * sum(case when WAIT_CLASS = 'ON CPU' then 1 else 0 end)/count(*), 2) as "ON CPU",
ROUND(100.0 * sum(case when WAIT_CLASS = 'Other' then 1 else 0 end)/count(*), 2) as "Other",
ROUND(100.0 * sum(case when WAIT_CLASS = 'Application' then 1 else 0 end)/count(*), 2) as "Application",
ROUND(100.0 * sum(case when WAIT_CLASS = 'Configuration' then 1 else 0 end)/count(*), 2) as "Configuration",
ROUND(100.0 * sum(case when WAIT_CLASS = 'Cluster' then 1 else 0 end)/count(*), 2) as "Cluster",
ROUND(100.0 * sum(case when WAIT_CLASS = 'Administrative' then 1 else 0 end)/count(*), 2) as "Administrative",
ROUND(100.0 * sum(case when WAIT_CLASS = 'Concurrency' then 1 else 0 end)/count(*), 2) as "Concurrency",
ROUND(100.0 * sum(case when WAIT_CLASS = 'Commit' then 1 else 0 end)/count(*), 2) as "Commit",
ROUND(100.0 * sum(case when WAIT_CLASS = 'Network' then 1 else 0 end)/count(*), 2) as "Network",
ROUND(100.0 * sum(case when WAIT_CLASS = 'User I/O' then 1 else 0 end)/count(*), 2) as "User I/O",
ROUND(100.0 * sum(case when WAIT_CLASS = 'System I/O' then 1 else 0 end)/count(*), 2) as "System I/O",
ROUND(100.0 * sum(case when WAIT_CLASS = 'Scheduler' then 1 else 0 end)/count(*), 2) as "Scheduler",
ROUND(100.0 * sum(case when WAIT_CLASS = 'Queueing' then 1 else 0 end)/count(*), 2) as "Queueing",
ROUND(100.0 * sum(case when WAIT_CLASS not in ('ON CPU','Other','Application','Configuration','Cluster','Administrative','Concurrency','Commit','Networ
k','User I/O','System I/O','Scheduler','Queueing') then 1 else 0 end)/count(*), 2) as "Others",
substr(max(sql_text),0,500) as sql_text
FROM tmp GROUP BY sql_id ORDER BY COUNT (*) DESC
) where rownum <  10;

