REM $Header: 215187.1 sqltcommon5.sql 12.1.05 2013/12/11 carlos.sierra mauro.pagano $
-- begin common
PRO
PRO To monitor progress, login into another session and execute:
PRO SQL> SELECT * FROM ^^tool_administer_schema..sqlt$_log_v;;
PRO
PRO ... collecting diagnostics details, please wait ...
PRO
PRO In case of a disconnect review log file in current directory
PRO If running as SYS in 12c make sure to review sqlt_instructions.html first
PRO
SET TERM OFF;
-- end common
