SPO sqltxtrsby.log;
@@sqltcommon1.sql
REM $Header: 215187.1 sqltxtrsby.sql 12.1.01 2013/08/19 carlos.sierra mauro.pagano $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqlt/run/sqltxtrsby.sql
REM
REM DESCRIPTION
REM   Collects SQL tuning diagnostics data and generates a set of
REM   diagnostics files. It inputs one SQL_ID or HASH_VALUE of a
REM   known SQL that is memory resident or pre-captured by AWR in
REM   a stand-by read-only database.
REM
REM PRE-REQUISITES
REM   1. Use a dedicated SQL*Plus connection (not a shared one).
REM   2. User has been granted SQLT_USER_ROLE.
REM   3. There exists a dblink connection into stand-by database.
REM
REM PARAMETERS
REM   1. SQL_ID or HASH_VALUE of the SQL to be extracted (required)
REM   2. Local SQLTXPLAIN password (required)
REM   3. DBLINK to stand-by database (required)
REM
REM EXECUTION
REM   1. Navigate to sqlt main directory.
REM   2. Start SQL*Plus connecting as a user that can access the
REM      dblink into stand-by read-only database.
REM   3. Execute script sqltxtrsby.sql passing first SQL_ID or
REM      HASH_VALUE of the one SQL. This SQL must be memory resident
REM      or pre-captured by AWR.
REM   4. Enter SQLTXPLAIN password when asked for it.
REM   5. Pass also the DBLINK to access the stand-by database.
REM
REM EXAMPLE
REM   # cd sqlt
REM   # sqlplus apps
REM   SQL> START [path]sqltxtrsby.sql [SQL_ID] [PWD] [DBLINK]
REM   SQL> START run/sqltxtrsby.sql 0w6uydn50g8cx mypwd V1123
REM
REM NOTES
REM   1. For possible errors see sqltxtrsby.log.
REM
@@sqltcommon2.sql
PRO Parameter 1:
PRO SQL_ID or HASH_VALUE of the SQL to be extracted (required)
PRO
DEF sql_id_or_hash_value_1 = '^1';
@@sqltcommon3.sql
PRO Parameter 3:
PRO DBLINK to stand-by database (required)
PRO
DEF db_link_1 = '^3';
PRO
SET TERM OFF;
COL sql_id_or_hash_value NEW_V sql_id_or_hash_value;
SELECT TRIM('^^sql_id_or_hash_value_1.') sql_id_or_hash_value FROM DUAL;
COL db_link NEW_V db_link;
SELECT '@'||REPLACE(REPLACE('^^db_link_1.', ' '), '@') db_link FROM DUAL;
SET TERM ON;
PRO
PRO Values passed to sqltxtrsby:
PRO SQL_ID_OR_HASH_VALUE: "^^sql_id_or_hash_value."
PRO DB_LINK             : "^^db_link."
PRO
EXEC DBMS_APPLICATION_INFO.SET_MODULE('sqltxtrsby', 'script');
PRO
@@sqltcommon4.sql
SET TERM ON;
PRO
PRO NOTE:
PRO You used the XTRSBY method connected as ^^connected_user..
PRO
PRO In case of a session disconnect please verify the following:
PRO 1. There are no errors in sqltxtrsby.log.
PRO 2. Your SQL ^^sql_id_or_hash_value. exists in memory or in AWR.
PRO 3. You connected as the application user that issued original SQL.
PRO 4. User ^^connected_user. has been granted SQLT_USER_ROLE.
PRO
PRO In case of errors ORA-03113, ORA-03114 or ORA-07445 please just
PRO re-try this SQLT method. This tool handles some of the errors behind
PRO a disconnect when executed a second time.
PRO
PRO To actually diagnose the problem behind the disconnect, read ALERT
PRO log and provide referenced traces to Support. After the root cause
PRO of the disconnect is fixed then reset SQLT corresponding parameter.
@@sqltcommon5.sql
EXEC ^^tool_administer_schema..sqlt$i.xtrsby(p_statement_id => :v_statement_id, p_sql_id_or_hash_value => '^^sql_id_or_hash_value.', p_stand_by_dblink => '^^db_link.', p_password => 'Y');
WHENEVER SQLERROR CONTINUE;
SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;
SET SERVEROUT ON SIZE UNL FOR TRU;
PRO No fatal errors!
COL column_value FOR A2000;
COL filename NEW_V filename FOR A256;
SPO OFF;
@@sqltcommon6.sql
@@sqltgetfile.sql TEST_CASE_SQL
@@sqltgetfile.sql Q
@@sqltgetfile.sql TEST_CASE_SCRIPT
SPO ^^unique_id._xtrsby.log;
GET sqltxtrsby.log
.
SPO OFF;
EXEC DBMS_APPLICATION_INFO.SET_MODULE('sqltxtrsby', '^^db_link.');
@@sqltcommon7.sql
HOS zip -m ^^unique_id._xtrsby_^^sql_id_or_hash_value. sqltxtrsby.log sqltxtrsby2.log missing_file.txt
HOS zip -d ^^unique_id._xtrsby_^^sql_id_or_hash_value. sqltxtrsby.log sqltxtrsby2.log missing_file.txt
@@sqltcommon8.sql
HOS zip -m ^^unique_id._log ^^unique_id._xtrsby.log sqltxhost.log
HOS zip -m ^^unique_id._xtrsby_^^sql_id_or_hash_value. ^^unique_id.*
SET TERM ON;
HOS unzip -l ^^unique_id._xtrsby_^^sql_id_or_hash_value.
PRO File ^^unique_id._xtrsby_^^sql_id_or_hash_value..zip for ^^sql_id_or_hash_value. has been created.
@@sqltcommon13.sql
HOS zip -m ^^unique_id._xtrsby_^^sql_id_or_hash_value. ^^unique_id.*
@@sqltcommon9.sql
UNDEF sql_id_or_hash_value
UNDEF sql_id_or_hash_value_1
UNDEF 2 3
UNDEF enter_tool_password
PRO SQLTXTRSBY completed.
