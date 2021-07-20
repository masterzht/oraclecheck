-- 单词逻辑读
-- 单词物理读

SELECT
	sql_id,
	round( buff_exec ) * exec_times gets_total,
	round( buff_exec ) gets_exec,
	round( disk_exec ) disk_exec,
	exec_times,
	start_time,
	end_time
FROM
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
				'STDBYPERF',
				'YUNQU'
			)
			AND ( round( buffer_gets_total / nvl( executions_total, 1 ) ) > 99999 OR round( disk_reads_total / nvl( executions_total, 1 )) > 9999 )
			AND executions_total > 9
		)
	GROUP BY
	sql_id
	);