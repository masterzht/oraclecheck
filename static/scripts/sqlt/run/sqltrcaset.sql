SPO sqltrcaset.log;
@@sqltcommon1.sql
REM $Header: 215187.1 sqltrcaset.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqlt/run/sqltrcaset.sql
REM
REM DESCRIPTION
REM   Collects SQL tuning diagnostics data and generates a set of
REM   diagnostics files. It inputs the tool execution id from TRCA
REM   and produces SQLT XTRACT for Top SQL as per TRCA.
REM
REM PRE-REQUISITES
REM   1. Execute directly from the sqlt/run directory and not
REM      from some other directory passing path and script name.
REM   2. Use a dedicated SQL*Plus connection (not a shared one).
REM
REM PARAMETERS
REM   1. TRCA tool execution id (required)
REM   2. SQLTXPLAIN password (required).
REM
REM EXECUTION
REM   1. Execute directly from the sqlt/run directory and not
REM      from some other directory passing path and script name.
REM   2. Start SQL*Plus connecting as the application user of the SQL.
REM   3. Execute script sqltrcaset.sql passing parameter values when
REM      asked.
REM
REM EXAMPLE
REM   # cd sqlt/run
REM   # sqlplus apps
REM   SQL> START sqltrcaset.sql
REM
REM NOTES
REM   1. For possible errors see sqltrcaset.log.
REM   2. For better output execute this script connected as the
REM      application user who issued the SQL.
REM
@@sqltcommon2.sql
PRO WARNING:
PRO Execute sqltrcaset.sql connecting directly from the
PRO sqlt/run directory and not from some other directory.
PRO
PRO You are in this directory:
HOS pwd
HOS dir sqltrcaset.sql
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
PRO ... please wait ...
SELECT LPAD(id, 5, '0') id,
       SUBSTR(file_name, 1, 74) file_name
  FROM ^^tool_repository_schema..trca$_tool_execution
 ORDER BY
       id;
PRO
PRO Parameter 1:
PRO TRCA Tool Execution ID (required)
PRO
DEF tool_execution_id = '^1';
PRO
SELECT NVL(sqlid, TO_CHAR(hv)) trca_top_sql
  FROM ^^tool_administer_schema..trca$_sql_v
 WHERE tool_execution_id = TO_NUMBER('^^tool_execution_id.')
   AND (top_sql = 'Y' OR top_sql_et = 'Y' OR top_sql_ct = 'Y')
   AND hv > 0
 ORDER BY
       NVL(rank, 0) + NVL(rank_et, 0) + NVL(rank_ct, 0);
PRO
PRO Proceeding now with XTRACT for Top SQL
@@sqltcommon3.sql
PRO Value passed to sqltrcaset:
PRO TOOL_EXECUTION_ID: "^^tool_execution_id."
PRO
EXEC DBMS_APPLICATION_INFO.SET_MODULE('sqltrcaset', 'script');
PRO
@@sqltcommon4.sql
DEF set_id = '^^unique_id.';
VAR v_statement_set_id NUMBER;
EXEC :v_statement_set_id := TO_NUMBER(:v_statement_id);
SET SERVEROUT ON SIZE UNL FOR TRU;
VAR v_tool_execution_id NUMBER;
EXEC :v_tool_execution_id := TO_NUMBER(TRIM('^^tool_execution_id.'));
SELECT NVL(sqlid, TO_CHAR(hv)) trca_top_sql
  FROM ^^tool_administer_schema..trca$_sql_v
 WHERE tool_execution_id = :v_tool_execution_id
   AND (top_sql = 'Y' OR top_sql_et = 'Y' OR top_sql_ct = 'Y')
 ORDER BY
       NVL(rank, 0) + NVL(rank_et, 0) + NVL(rank_ct, 0);
SET TERM ON;
PRO
PRO WARNING:
PRO Execute sqltrcaset.sql connecting directly from the
PRO sqlt/run directory and not from some other directory.
PRO
PRO You are in this directory:
HOS pwd
HOS dir sqltrcaset.sql
PRO
PRO
PRO NOTE:
PRO You used the XTRSET method connected as ^^connected_user..
PRO
PRO In case of a session disconnect please verify the following:
PRO 1. There are no errors in sqltrcaset.log.
PRO 2. Your TRCA execution id ^^tool_execution_id. exists.
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
SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;
SPO ^^set_id._driver.sql
BEGIN
  FOR i IN (SELECT NVL(sqlid, TO_CHAR(hv)) sql_id_or_hash_value
              FROM ^^tool_administer_schema..trca$_sql_v
             WHERE tool_execution_id = :v_tool_execution_id
               AND (top_sql = 'Y' OR top_sql_et = 'Y' OR top_sql_ct = 'Y')
               AND hv > 0
             ORDER BY
                   NVL(rank, 0) + NVL(rank_et, 0) + NVL(rank_ct, 0))
  LOOP
    DBMS_OUTPUT.PUT_LINE('@@sqltxtrone.sql '||i.sql_id_or_hash_value);
  END LOOP;
END;
/
SPO sqltrcaset2.log;
WHENEVER SQLERROR CONTINUE;
SET TERM ON;
PRO Dynamic script ^^set_id._driver.sql must be on same directory than sqltrcaset.sql, sqltxtrone.sql and sqltgetfile.sql.
PRO Execute sqltrcanlzr.sql and sqltrcaset.sql directly from the sqlt/run directory and not from any other directory.
@@^^set_id._driver.sql
@@sqltcommon1.sql
--
SET TERM OFF;
SPO ^^set_id._xtrset.log;
GET sqltrcaset.log
.
GET sqltrcaset2.log
.
SPO OFF;
--
HOS zip -m ^^set_id._set sqltrcaset.log sqltrcaset2.log
HOS zip -d ^^set_id._set sqltrcaset.log sqltrcaset2.log
HOS zip -m ^^set_id._set ^^set_id._driver.sql ^^set_id._xtrset.log
--
SET TERM OFF ECHO OFF FEED OFF FLU OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SHOW OFF SQLC MIX TAB OFF TRIMS ON VER OFF TI OFF TIMI OFF ARRAY 100 SQLP SQL> BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;
COL column_value FOR A2000;
SPO trca_e^^tool_execution_id..txt;
SELECT column_value FROM TABLE(^^tool_administer_schema..trca$g.display_file(:v_tool_execution_id, 'TEXT'));
SPO trca_e^^tool_execution_id..html;
SELECT column_value FROM TABLE(^^tool_administer_schema..trca$g.display_file(:v_tool_execution_id, 'HTML'));
SPO trca_e^^tool_execution_id..log;
SELECT column_value FROM TABLE(^^tool_administer_schema..trca$g.display_file(:v_tool_execution_id, 'LOG'));
SPO OFF;
HOS zip -m trca_e^^tool_execution_id. trca_e^^tool_execution_id.*
--
SET TERM ON;
--HOS unzip -l ^^set_id._set
PRO File ^^set_id._set.zip has been created. Review ^^set_id._xtrset.log.
HOS zip -m trca_e^^tool_execution_id. ^^set_id._set.zip
--HOS unzip -l trca_e^^tool_execution_id.
PRO File trca_e^^tool_execution_id..zip has been updated.
@@sqltcommon9.sql
UNDEF 2 tool_execution_id set_id;
PRO SQLTRCASET completed.
