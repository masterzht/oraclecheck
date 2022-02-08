REM $Header: 215187.1 sqltcommon6.sql 12.1.160429 2016/04/29 carlos.sierra mauro.pagano abel.macias@oracle.com$
-- begin common
HOS echo "vmstat 5 5" >> sqltxhost.log
HOS vmstat 5 5 >> sqltxhost.log
HOS echo "sar -u 5 5" >> sqltxhost.log
HOS sar -u 5 5 >> sqltxhost.log
HOS echo "pwd" >> sqltxhost.log
HOS pwd >> sqltxhost.log
HOS echo %cd% >> sqltxhost.log
@@sqltgetfile.sql SQL_MONITOR_DRIVER
@^^filename.
@@sqltgetfile.sql REMOTE_DRIVER
@^^filename.
-- 160403 relocated all SQL Monitor and perfhub to earliest
@@sqltgetfile.sql SQL_MONITOR_ACTIVE
@@sqltgetfile.sql SQL_MONITOR_HTML
@@sqltgetfile.sql SQL_MONITOR_TEXT
@@sqltgetfile.sql PERFHUB_DRIVER
@^^filename.
@@sqltgetfile.sql MAIN_REPORT
@@sqltgetfile.sql LITE_REPORT
@@sqltgetfile.sql README_REPORT_HTML
@@sqltgetfile.sql README_REPORT_TXT
@@sqltgetfile.sql METADATA_SCRIPT
@@sqltgetfile.sql METADATA_SCRIPT1
@@sqltgetfile.sql METADATA_SCRIPT2
@@sqltgetfile.sql SYSTEM_STATS_SCRIPT
@@sqltgetfile.sql SCHEMA_STATS_SCRIPT
@@sqltgetfile.sql SET_CBO_ENV_SCRIPT
@@sqltgetfile.sql CUSTOM_SQL_PROFILE
@@sqltgetfile.sql STA_REPORT_MEM
@@sqltgetfile.sql STA_SCRIPT_MEM
@@sqltgetfile.sql STA_REPORT_TXT
@@sqltgetfile.sql STA_SCRIPT_TXT
@@sqltgetfile.sql STA_REPORT_AWR
@@sqltgetfile.sql STA_SCRIPT_AWR
@@sqltgetfile.sql SQL_DETAIL_ACTIVE
@@sqltgetfile.sql 10053_EXPLAIN
@@sqltgetfile.sql 10053_EXTRACT
@@sqltgetfile.sql BDE_CHK_CBO_REPORT
@@sqltgetfile.sql IMPORT_SCRIPT
@@sqltgetfile.sql EXPORT_PARFILE
@@sqltgetfile.sql EXPORT_PARFILE2
@@sqltgetfile.sql PLAN
@@sqltgetfile.sql 10053
@@sqltgetfile.sql FLUSH
@@sqltgetfile.sql PURGE
@@sqltgetfile.sql RESTORE
@@sqltgetfile.sql DEL_HGRM
@@sqltgetfile.sql TC_SQL
@@sqltgetfile.sql XPRESS_SH
@@sqltgetfile.sql XPRESS_SQL
@@sqltgetfile.sql SETUP
@@sqltgetfile.sql README
@@sqltgetfile.sql TC_PKG
@@sqltgetfile.sql SEL
@@sqltgetfile.sql SEL_AUX
@@sqltgetfile.sql INSTALL_SH
@@sqltgetfile.sql INSTALL_SQL
@@sqltgetfile.sql TCX_PKG
@@sqltgetfile.sql AWRRPT_DRIVER
@^^filename.
@@sqltgetfile.sql ADDMRPT_DRIVER
@^^filename.
@@sqltgetfile.sql ASHRPT_DRIVER
@^^filename.
@@sqltgetfile.sql TCB_DRIVER
@^^filename.
@@sqltgetfile.sql XPAND_SQL_DRIVER
@^^filename.
@@sqltgetfile.sql EXPORT_DRIVER
@^^filename.
-- end common
