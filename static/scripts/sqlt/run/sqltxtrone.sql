SPO sqltxtrone.log;
@@sqltcommon1.sql
REM $Header: 215187.1 sqltxtrone.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqlt/run/sqltxtrone.sql
REM
REM DESCRIPTION
REM   Called by parent scripts sqltxtrset and sqltrcaset.
REM   Do not use this script sqltxtrone.sql stand-alone.
REM
REM NOTES
REM   1. For possible errors see sqltxtrone.log.
REM
@@sqltcommon2.sql
PRO Parameter 1:
PRO SQL_ID or HASH_VALUE of the SQL to be extracted (required)
PRO
DEF sql_id_or_hash_value_1 = '^1';
PRO
SET TERM OFF;
COL sql_id_or_hash_value NEW_V sql_id_or_hash_value;
SELECT TRIM('^^sql_id_or_hash_value_1.') sql_id_or_hash_value FROM DUAL;
SET TERM ON;
PRO Value passed to sqltxtrone:
PRO SQL_ID_OR_HASH_VALUE: "^^sql_id_or_hash_value."
PRO
EXEC DBMS_APPLICATION_INFO.SET_MODULE('sqltxtrone', 'script');
@@sqltcommon4.sql
SET TERM ON;
PRO
PRO NOTE:
PRO You used the XTRONE method connected as ^^connected_user..
PRO
PRO In case of a session disconnect please verify the following:
PRO 1. There are no errors in sqltxtrone.log.
PRO 2. Your SQL ^^sql_id_or_hash_value. exists in memory or in AWR.
PRO 3. You connected as the application user that issued original SQL.
PRO
PRO In case of errors ORA-03113, ORA-03114 or ORA-07445 please just
PRO re-try this SQLT method. This tool handles some of the errors behind
PRO a disconnect when executed a second time.
PRO
PRO To actually diagnose the problem behind the disconnect, read ALERT
PRO log and provide referenced traces to Support. After the root cause
PRO of the disconnect is fixed then reset SQLT corresponding parameter.
@@sqltcommon5.sql
EXEC ^^tool_administer_schema..sqlt$i.xtract(p_statement_id => :v_statement_id, p_sql_id_or_hash_value => '^^sql_id_or_hash_value.', p_statement_set_id => :v_statement_set_id, p_password => 'Y');
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
-- consumed by xtrcxec.sql:
DEF tcscript = '^^filename.';
SPO ^^unique_id._xtrone.log;
GET sqltxtrone.log
.
SPO OFF;
@@sqltcommon7.sql
HOS zip -m ^^unique_id._xtrone_^^sql_id_or_hash_value. sqltxtrone.log sqltxtrone2.log missing_file.txt
HOS zip -d ^^unique_id._xtrone_^^sql_id_or_hash_value. sqltxtrone.log sqltxtrone2.log missing_file.txt
@@sqltcommon8.sql
HOS zip -m ^^unique_id._log ^^unique_id._xtrone.log sqltxhost.log
HOS zip -m ^^unique_id._xtrone_^^sql_id_or_hash_value. ^^unique_id.*
--
SET TERM ON;
HOS unzip -l ^^unique_id._xtrone_^^sql_id_or_hash_value.
PRO File ^^unique_id._xtrone_^^sql_id_or_hash_value..zip has been created.
HOS zip -m ^^set_id._set ^^unique_id._xtrone_^^sql_id_or_hash_value..zip
@@sqltcommon9.sql
UNDEF sql_id_or_hash_value
UNDEF sql_id_or_hash_value_1
PRO SQLTXTRONE completed.
