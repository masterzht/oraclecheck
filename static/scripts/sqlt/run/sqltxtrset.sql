SPO sqltxtrset.log;
@@sqltcommon1.sql
REM $Header: 215187.1 sqltxtrset.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqlt/run/sqltxtrset.sql
REM
REM DESCRIPTION
REM   Collects SQL tuning diagnostics data and generates a set of
REM   diagnostics files. It inputs a set of SQL_IDs or HASH_VALUEs
REM   of known SQL that are memory resident or pre-captured by AWR.
REM
REM PRE-REQUISITES
REM   1. Execute directly from the sqlt/run directory and not
REM      from some other directory passing path and script name.
REM   2. Use a dedicated SQL*Plus connection (not a shared one).
REM   3. User has been granted SQLT_USER_ROLE.
REM
REM PARAMETERS
REM   1. Comma-separated list of SQL_IDs or HASH_VALUEs of the SQLs
REM      to be extracted (required)
REM   2. SQLTXPLAIN password (required).
REM
REM EXECUTION
REM   1. Execute directly from the sqlt/run directory and not
REM      from some other directory passing path and script name.
REM   2. Start SQL*Plus connecting as the application user of the SQL.
REM   3. Execute script sqltxtrset.sql passing parameter values when
REM      asked.
REM
REM EXAMPLE
REM   # cd sqlt/run
REM   # sqlplus apps
REM   SQL> START sqltxtrset.sql
REM
REM NOTES
REM   1. For possible errors see sqltxtrset.log.
REM   2. For better output execute this script connected as the
REM      application user who issued the SQL.
REM
@@sqltcommon2.sql
PRO WARNING:
PRO Execute sqltxtrset.sql connecting directly from the
PRO sqlt/run directory and not from some other directory.
PRO
PRO You are in this directory:
HOS pwd
HOS dir sqltxtrset.sql
PRO If directory above ends with sqlt/run please enter
PRO keyword RUN when asked for "directory".
PRO
PRO ^^directory.
PRO
WHENEVER SQLERROR EXIT SQL.SQLCODE;
BEGIN
  IF UPPER(NVL(TRIM('^^directory.'), 'NULL')) <> 'RUN' THEN
    RAISE_APPLICATION_ERROR(-20100, 'Directory verification keyword "^^directory." was not RUN. Abort!');
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
PRO
PRO Parameter 1:
PRO Comma-separated list of SQL_IDs or HASH_VALUEs (required)
PRO
DEF list_of_ids = '^1';
@@sqltcommon3.sql
PRO Value passed to sqltxtrset:
PRO LIST_OF_IDS: "^^list_of_ids."
PRO
EXEC DBMS_APPLICATION_INFO.SET_MODULE('sqltxtrset', 'script');
PRO
@@sqltcommon4.sql
DEF set_id = '^^unique_id.';
VAR v_statement_set_id NUMBER;
EXEC :v_statement_set_id := TO_NUMBER(:v_statement_id);
SET SERVEROUT ON SIZE UNL FOR TRU;
VAR v_list_of_ids VARCHAR2(4000);
BEGIN
  :v_list_of_ids := TRIM(TRANSLATE('^^list_of_ids.',
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789, ''`~!@#$%^*()-_=+[]{}\|;:".<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
  'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz0123456789  '));
END;
/
PRINT v_list_of_ids;
SET TERM ON;
PRO
PRO NOTE:
PRO You used the XTRSET method connected as ^^connected_user..
PRO
PRO WARNING:
PRO Execute sqltxtrset.sql connecting directly from the
PRO sqlt/run directory and not from some other directory.
PRO
PRO You are in this directory:
HOS pwd
HOS dir sqltxtrset.sql
PRO
PRO
PRO In case of a session disconnect please verify the following:
PRO 1. There are no errors in sqltxtrset.log.
PRO 2. Your SQLs ^^list_of_ids. exists in memory or in AWR.
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
SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;
SPO ^^set_id._driver.sql
DECLARE
  l_first_space INTEGER;
BEGIN
  WHILE :v_list_of_ids IS NOT NULL
  LOOP
    l_first_space := INSTR(:v_list_of_ids||' ', ' ');
    DBMS_OUTPUT.PUT_LINE('@@sqltxtrone.sql '||SUBSTR(:v_list_of_ids, 1, l_first_space - 1));
    :v_list_of_ids := TRIM(SUBSTR(:v_list_of_ids, l_first_space));
  END LOOP;
END;
/
SPO sqltxtrset2.log;
WHENEVER SQLERROR CONTINUE;
SET TERM ON;
PRO Dynamic script ^^set_id._driver.sql must be on same directory than sqltxtrset.sql, sqltxtrone.sql and sqltgetfile.sql.
PRO Execute sqltxtrset.sql directly from the sqlt/run directory and not from some other directory passing path and script name.
PRO Example
PRO # cd sqlt/run
PRO # sqlplus apps
PRO SQL> START sqltxtrset.sql
@@^^set_id._driver.sql
@@sqltcommon1.sql
--
SET TERM OFF;
SPO ^^set_id._xtrset.log;
GET sqltxtrset.log
.
GET sqltxtrset2.log
.
SPO OFF;
--
HOS zip -m ^^set_id._set sqltxtrset.log sqltxtrset2.log
HOS zip -d ^^set_id._set sqltxtrset.log sqltxtrset2.log
HOS zip -m ^^set_id._set ^^set_id._driver.sql ^^set_id._xtrset.log
--
SET TERM ON;
--HOS unzip -l ^^set_id._set
PRO File ^^set_id._set.zip has been created. Review ^^set_id._xtrset.log.
@@sqltcommon9.sql
UNDEF 2
UNDEF enter_tool_password
PRO SQLTXTRSET completed.
