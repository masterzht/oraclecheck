SPO sqltrstobj.log;
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LIN 200 PAGES 100 TRIMS ON TI OFF TIMI OFF APPI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM $Header: 215187.1 sqltrstobj.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/xhume/sqltrstobj.sql
REM
REM DESCRIPTION
REM   Never use this script on a production environment.
REM   This script must only be used on an Oracle internal test
REM   system.
REM   Resets in the data dictionary the creation date of objects
REM   related to one statement and for which a test case requires to
REM   restore the schema object statistics to a point in time.
REM
REM PRE-REQUISITES
REM   1. Import SQLT repository into test system as per readme.
REM
REM PARAMETERS
REM   1. Source Statement ID (required)
REM      A list of available statement_ids is presented.
REM   2. Testcase User (required and case sensitive)
REM      Test Case user (TC99999sfx) as per metadata script.
REM
REM EXECUTION
REM   1. Navigate to sqlt/utl/xhume directory.
REM   2. Start SQL*Plus connecting as SYS.
REM   3. Execute script sqltrstobj.sql passing statement id and schema
REM      owner (parameters can be passed inline or until requested).
REM
REM EXAMPLE
REM   # cd sqlt/utl/xhume
REM   # sqlplus / as sysdba
REM   SQL> START [path]sqltrstobj.sql [statement_id] [TC schema owner]
REM   SQL> START sqltrstobj.sql s99999 TC99999
REM   SQL> START sqltrstobj.sql 99999 NULL
REM   SQL> START sqltrstobj.sql
REM
REM NOTES
REM   1. Never use this script on a production environment.
REM      This script must only be used on an Oracle internal test
REM      system.
REM   2. For possible errors see sqltrstobj.log
REM   3. After using this script you can restore table
REM      statistics to a point in time. Example:
REM      BEGIN
REM        DBMS_STATS.RESTORE_TABLE_STATS (
REM          ownname         => 'TC82227',
REM          tabname         => 'T1',
REM          as_of_timestamp => TO_TIMESTAMP_TZ('2011-03-01/17:38:10 -05:00', 'YYYY-MM-DD/HH24:MI:SS TZH:TZM'),
REM          force           => TRUE,
REM          no_invalidate   => FALSE );
REM      END;
REM      /
REM   4. If you need to include fractions of a second:
REM          as_of_timestamp => TO_TIMESTAMP_TZ('2011-03-01/17:38:10.366468 -05:00', 'YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM'),
REM   5. To restore stats for the whole TC user:
REM      BEGIN
REM        DBMS_STATS.RESTORE_SCHEMA_STATS (
REM          ownname         => 'TC51228',
REM          as_of_timestamp => TO_TIMESTAMP_TZ('2011-03-10/14:23:17 -04:00', 'YYYY-MM-DD/HH24:MI:SS TZH:TZM'),
REM          force           => TRUE,
REM          no_invalidate   => FALSE );
REM      END;
REM      /
REM
-- begin common
DEF _SQLPLUS_RELEASE
SELECT USER FROM DUAL;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') current_time FROM DUAL;
SELECT * FROM v$version;
SELECT * FROM v$instance;
SELECT name, value FROM v$parameter2 WHERE name LIKE '%dump_dest';
SELECT directory_name||' '||directory_path directories FROM dba_directories WHERE directory_name LIKE 'SQLT$%' OR directory_name LIKE 'TRCA$%' ORDER BY 1;
-- end common
SET TERM ON ECHO OFF;
PRO
PRO WARNING:
PRO ~~~~~~~
PRO You are about to update the data dictionary.
PRO
PRO Updating the data dictionary puts your database in
PRO a non-supported state.
PRO
PRO Use this method only on an Oracle internal system.
PRO
PRO If you want to proceed enter the keyword ACKNOWLEDGE
PRO when asked for "updating_data_dictionary".
PRO
PRO &&updating_data_dictionary.
PRO
SET TERM OFF;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
BEGIN
  IF UPPER(NVL(TRIM('&&updating_data_dictionary.'), 'NOTHING WAS ENTERED')) <> 'ACKNOWLEDGE' THEN
    RAISE_APPLICATION_ERROR(-20100, 'Updating data dictionary "&&updating_data_dictionary." was not ACKNOWLEDGE. Abort!');
  END IF;
END;
/
SET TERM ON;
SELECT LPAD(s.statement_id, 5, '0') staid,
       SUBSTR(s.method, 1, 3) method,
       SUBSTR(s.instance_name_short, 1, 8) instance,
       SUBSTR(s.sql_text, 1, 60) sql_text
  FROM sqltxplain.sqlt$_sql_statement s
 WHERE USER IN ('SYS', 'SYSTEM', s.username)
 ORDER BY
       s.statement_id;
PRO
PRO Parameter 1:
PRO STATEMENT_ID (required)
PRO
PRO Source to TC (from where the TC was created).
PRO
DEF statement_id = '&1';
PRO
PRO Parameter 2:
PRO TESTCASE_USER (required and case sensitive)
PRO
PRO Test Case user (TC99999) as per metadata script.
PRO Include TC user suffix if any.
PRO
DEF testcase_user = '&2';
PRO
PRO Values passed:
PRO ~~~~~~~~~~~~~
PRO STATEMENT_ID : "&&statement_id."
PRO TESTCASE_USER: "&&testcase_user."
PRO
PRO ... resetting object creation dates ...
PRO
EXEC sqltxadmin.sqlt$i.reset_object_creation_date(TRIM('&&statement_id.'), TRIM('&&testcase_user'));
SPO OFF;
CL COL;
WHENEVER SQLERROR CONTINUE;
UNDEFINE 1 2 statement_id testcase_user updating_data_dictionary;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON HEA ON LIN 80 PAGES 14 TRIMS OFF TI OFF TIMI OFF APPI OFF SERVEROUT OFF NUMF "" SQLP SQL>;
PRO
PRO SQLTRSTOBJ completed.
