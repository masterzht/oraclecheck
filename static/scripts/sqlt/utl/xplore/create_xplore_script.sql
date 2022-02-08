REM $Header: create_xplore_script.sql 12.1.06 2014/01/30 carlos.sierra mauro.pagano $
PRO
PRO Parameter 1:
PRO XPLORE Method: XECUTE (default) or XPLAIN
PRO "XECUTE" requires /* ^^unique_id */ token in SQL
PRO "XPLAIN" uses "EXPLAIN PLAN FOR" command 
PRO Remember EXPLAIN PLAN FOR does not perform bind peeking
PRO Remember CREATE TABLE AS SELECT statements are not supported (See Note 1963444.1)
ACC xplore_method PROMPT 'Enter "XPLORE Method" [XECUTE]: ';
PRO
PRO Parameter 2:
PRO Include CBO Parameters: Y (default) or N
ACC include_cbo_parameters PROMPT 'Enter "CBO Parameters" [Y]: ';
PRO
PRO Parameter 3:
PRO Include Exadata Parameters: Y (default) or N
ACC include_exadata_parameters PROMPT 'Enter "EXADATA Parameters" [Y]: ';
PRO
PRO Parameter 4:
PRO Include Fix Control: Y (default) or N
ACC include_fix_control PROMPT 'Enter "Fix Control" [Y]: ';
PRO
PRO Parameter 5:
PRO Generate SQL Monitor Reports: N (default) or Y
PRO Only applicable when XPLORE Method is XECUTE
ACC generate_sql_monitor_reports PROMPT 'Enter "SQL Monitor" [N]: ';
PRO
SET DEF ON TERM OFF ECHO OFF FEED OFF FLU OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SHOW OFF SQLC MIX TAB OFF TRIMS ON VER OFF TI OFF TIMI OFF ARRAY 100 SQLP SQL> BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;
SET SERVEROUT ON SIZE UNL FOR TRU;
COL script_suffix NEW_V script_suffix;
SELECT (NVL(MAX(baseline_id), 0) + 1)||'.sql' script_suffix FROM xplore_test;
SPO xplore_script_&&script_suffix.
EXEC xplore.create_xplore_script('&&xplore_method.', '&&include_cbo_parameters.','&&include_exadata_parameters.','&&include_fix_control.','&&generate_sql_monitor_reports.');
SPO OFF;
SET TERM ON;
PRO
PRO Review and execute @xplore_script_&&script_suffix
PRO
UNDEFINE script_suffix xplore_method include_cbo_parameters include_exadata_parameters include_fix_control generate_sql_monitor_reports;
