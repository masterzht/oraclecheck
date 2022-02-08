SPO sqltxprexc.log;
@@sqltcommon1.sql
REM $Header: 215187.1 sqltxprexc.sql 12.1.06 2014/01/30 carlos.sierra mauro.pagano $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqlt/run/sqltxprexc.sql
REM
REM DESCRIPTION
REM   Collects SQL tuning diagnostics data and generates a set of
REM   diagnostics files. It inputs one SCRIPT which contains one SQL
REM   statement. If the SQL contains binds, the SCRIPT should also
REM   include binds declaration and assignment. For an example of
REM   its format see sqlt/input/sample/script1.sql provided.
REM
REM PRE-REQUISITES
REM   1. Use a dedicated SQL*Plus connection (not a shared one).
REM   2. User has been granted SQLT_USER_ROLE.
REM
REM PARAMETERS
REM   1. SCRIPT name which contains SQL and its binds (required)
REM   2. SQLTXPLAIN password (required).
REM
REM EXECUTION
REM   1. Place your SCRIPT with one SQL into sqlt/input directory
REM   2. Navigate to sqlt main directory.
REM   3. Start SQL*Plus connecting as the application user of the SQL.
REM   4. Execute script sqltxprexc.sql passing directory path and
REM      name of SCRIPT with one SQL and its bind variables.
REM   5. Enter SQLTXPLAIN password when asked for it.
REM
REM EXAMPLE
REM   # cd sqlt
REM   # sqlplus apps
REM   SQL> START [path]sqltxprexc.sql [path]scriptname
REM   SQL> START run/sqltxprexc.sql input/sample/script1.sql
REM
REM NOTES
REM   1. For possible errors see sqltxprexc.log and sqltxprexc2.log.
REM   2. For better output execute this script connected as the
REM      application user who issued the SQL.
REM
@@sqltcommon2.sql
PRO Parameter 1:
PRO SCRIPT name which contains SQL and its binds (required)
PRO
DEF script_with_sql = '^1';
@@sqltcommon3.sql
PRO Value passed to sqltxprexc:
PRO SCRIPT_WITH_SQL: "^^script_with_sql."
PRO
EXEC DBMS_APPLICATION_INFO.SET_MODULE('sqltxecute', 'script');
@@sqltcommon4.sql
COL file_with_output NEW_V file_with_output;
SELECT ^^tool_administer_schema..sqlt$a.get_filename_with_output(:v_statement_id, '^^script_with_sql.') file_with_output FROM DUAL;
COL prev_sql_id NEW_V prev_sql_id;
COL prev_child_number NEW_V prev_child_number;
SELECT prev_sql_id, prev_child_number FROM sys.sqlt$_my_v$session;
@@sqltcommon11.sql
EXEC ^^tool_administer_schema..sqlt$i.xecute_begin(p_statement_id => :v_statement_id);
SET TERM ON;
PRO
PRO NOTE:
PRO You used the XPREXC method connected as ^^connected_user..
PRO
PRO In case of a session disconnect please verify the following:
PRO 1. There are no errors in sqltxprexc.log or sqltxprexc2.log.
PRO 2. Your SQL contains token "~^~^unique_id" within a comment.
PRO 3. Your SQL ends with a semi-colon ";".
PRO 4. You connected as the application user that issued original SQL.
PRO 5. Script ^^script_with_sql. can execute stand-alone connected as ^^connected_user.
PRO 6. User ^^connected_user. has been granted SQLT_USER_ROLE.
PRO
PRO In case of errors ORA-03113, ORA-03114 or ORA-07445 please just
PRO re-try this SQLT method. This tool handles some of the errors behind
PRO a disconnect when executed a second time.
PRO
PRO To actually diagnose the problem behind the disconnect, read ALERT
PRO log and provide referenced traces to Support. After the root cause
PRO of the disconnect is fixed then reset SQLT corresponding parameter.
PRO
PRO ... executing ^^script_with_sql. ...
PRO
PRO In case of a disconnect review sqltxprexc2.log and ^^file_with_output.
PRO
SET TERM OFF ECHO ON HEA ON LIN 2000 PAGES 1000 TRIMS ON TI OFF TIMI ON SERVEROUT OFF;
SPO ^^file_with_output.;
-- This file ^^file_with_output. contains the output of ^^script_with_sql.
--
-- If you want to include this spool file with output of your script into zip file,
-- or delete it automatically, use SQLT parameter xecute_script_output.
--
-- To permanently set this tool parameter connect as SQLTXPLAIN and issue:
-- SQL> EXEC sqlt$a.set_param('xecute_script_output', 'ZIP');
-- To temporarily set this tool parameter for a session connect as the application user and issue:
-- SQL> EXEC SQLTXPLAIN.sqlt$a.set_sess_param('xecute_script_output', 'ZIP');
--
-- Valid values are these 3 below. Default is KEEP.
-- ZIP (to include in zip file),
-- KEEP (to generate spool file and leave it in local directory without including it in zip file),
-- DELETE (to delete this spool file without including it in zip file).
--
SAVEPOINT sqlt_xprexc_savepoint;
@^^script_with_sql.
SPO sqltxprexc2.log;
SET TERM ON ECHO OFF;
@@sqltcommon5.sql
L
SELECT prev_sql_id, prev_child_number FROM sys.sqlt$_my_v$session;
ROLLBACK TO SAVEPOINT sqlt_xprexc_savepoint;
SELECT sql_text FROM sys.sqlt$_my_v$sql WHERE sql_id = '^^prev_sql_id.' AND child_number = TO_NUMBER('^^prev_child_number.');
SET SERVEROUT ON SIZE 1000000;
SET SERVEROUT ON SIZE UNL;
SET TERM ON;
EXEC ^^tool_administer_schema..sqlt$i.xecute_end(p_statement_id => :v_statement_id, p_string => 'sqlt_s'||:v_statement_id, p_sql_id => '^^prev_sql_id.', p_child_number => '^^prev_child_number.', p_input_filename => '^^script_with_sql.', p_password => 'Y');
WHENEVER SQLERROR CONTINUE;
SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;
SET SERVEROUT ON SIZE UNL FOR TRU;
PRO No fatal errors!
COL column_value FOR A2000;
COL filename NEW_V filename FOR A256;
SPO OFF;
@@sqltcommon6.sql
COL file_10046_10053_udump NEW_V file_10046_10053_udump FOR A256;
SELECT NVL(file_10046_10053_udump, 'missing_file.txt') file_10046_10053_udump FROM ^^tool_repository_schema..sqlt$_sql_statement WHERE statement_id = :v_statement_id;
@@sqltgetfile.sql 10046_10053_EXECUTE
@@sqltgetfile.sql TRACE_10046
@@sqltgetfile.sql TRACE_10053
@@sqltgetfile.sql TRCA_HTML
@@sqltgetfile.sql TRCA_TXT
@@sqltgetfile.sql TRCA_LOG
@@sqltgetfile.sql TRCA_PX_HTML
@@sqltgetfile.sql TRCA_PX_TXT
@@sqltgetfile.sql TRCA_PX_LOG
@@sqltgetfile.sql TKPROF_PX_DRIVER
@^^filename.
@@sqltgetfile.sql SCRIPT_OUTPUT_DRIVER
@^^filename.
SPO ^^unique_id._xprexc.log;
GET sqltxprexc.log
.
GET sqltxprexc2.log
.
SPO OFF;
SET TERM ON;
PRO ### copy command below will error out on windows. disregard error.
SET TERM OFF;
HOS cp ^^script_with_sql. q.sql
SET TERM ON;
PRO ### copy command below will error out on linux and unix. disregard error.
SET TERM OFF;
HOS copy ^^script_with_sql. q.sql
@@sqltcommon7.sql
SET TERM ON;
PRO ### tkprof commands below may error out with "could not open trace file". disregard error.
SET TERM OFF;
HOS tkprof ^^udump_path.^^file_10046_10053_udump. ^^unique_id._tkprof_nosort.txt
HOS tkprof ^^udump_path.^^file_10046_10053_udump. ^^unique_id._tkprof_sort.txt sort=prsela exeela fchela
-- unix/linux: in cases where local udump_path is not pointing to database server udump
-- set dircetory path for traces and be sure to include / at the end of it.
-- example: EXEC sqltxadmin.sqlt$a.set_param('traces_directory_path', '/u04/oraout_db/gsiav/gsi1av/trace/');
SET TERM ON;
PRO ### tkprof commands below may error out with "could not open trace file". disregard error.
SET TERM OFF;
HOS tkprof ^^traces_directory_path.^^file_10046_10053_udump. ^^unique_id._tkprof_nosort.txt
HOS tkprof ^^traces_directory_path.^^file_10046_10053_udump. ^^unique_id._tkprof_sort.txt sort=prsela exeela fchela
--
HOS zip -j ^^unique_id._xprexc ^^script_with_sql.
HOS zip -m ^^unique_id._xprexc sqltxprexc.log sqltxprexc2.log missing_file.txt
HOS zip -d ^^unique_id._xprexc sqltxprexc.log sqltxprexc2.log missing_file.txt
@@sqltcommon8.sql
@@sqltcommon10.sql
HOS zip -m ^^unique_id._log ^^unique_id._xprexc.log sqltxhost.log
HOS zip -m ^^unique_id._xprexc ^^unique_id.*
--
SET TERM ON;
HOS unzip -l ^^unique_id._xprexc
PRO File ^^unique_id._xprexc.zip for ^^script_with_sql. has been created.
@@sqltcommon13.sql
HOS zip -m ^^unique_id._xprexc ^^unique_id.*
@@sqltcommon12.sql
@@sqltcommon9.sql
UNDEF 2
UNDEF enter_tool_password
PRO SQLTXPREXC completed.
