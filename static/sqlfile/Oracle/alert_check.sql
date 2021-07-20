-- 检查数据库一个月内告警日志中的ORA告警 p4
SELECT
       'db_check_alert_check' as "db_check_alert_check",
       INST_ID,
       to_char( ORIGINATING_TIMESTAMP, 'yyyy-mm-dd HH24:mi:ss' ) time,
       substr(message_text,0,1000) message,
       (select count(*) from v$diag_alert_ext where ORIGINATING_TIMESTAMP > ( SYSDATE - 30 )
       AND message_text LIKE '%ORA-%' AND trim(component_id) = 'rdbms') as error_cnt
FROM
	v$diag_alert_ext
WHERE
	ORIGINATING_TIMESTAMP > ( SYSDATE - 30 )
	AND message_text LIKE '%ORA-%'
	AND trim(component_id) = 'rdbms';