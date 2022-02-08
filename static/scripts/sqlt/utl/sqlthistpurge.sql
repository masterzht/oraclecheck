SPO sqlthistpurge.log;
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LIN 200 PAGES 100 TRIMS ON TI OFF TIMI OFF APPI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM $Header: 215187.1 sqlthistpurge.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/sqlthistpurge.sql
REM
REM DESCRIPTION
REM   Purges a range of statements from the SQLT repository.
REM
REM PRE-REQUISITES
REM   1. Connect as SYS, SYSTEM, or the USER
REM      that created the statement(s) to be purged.
REM
REM PARAMETERS
REM   1. First Statement ID on range to be purged (required)
REM      A list of available statement_ids is presented.
REM   2. Last Statement ID on range to be purged (required)
REM
REM EXECUTION
REM   1. Navigate to sqlt main directory
REM   2. Start SQL*Plus connecting as as a qualified user.
REM   3. Execute script sqlthistpurge.sql passing range
REM      of statement_ids to be purged.
REM      Parameters can be passed inline or when requested.
REM
REM EXAMPLE
REM   # cd sqlt
REM   # sqlplus apps
REM   SQL> START [path]sqlthistpurge.sql [id from] [id to]
REM   SQL> START utl/sqlthistpurge.sql 11111 22222
REM   SQL> START utl/sqlthistpurge.sql
REM
REM NOTES
REM   1. For possible errors see sqlthistpurge.log
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
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM ON ECHO OFF;
PRO ... please wait ...
SET TERM OFF ECHO ON;
-- deprecated now: EXEC sqltxplain.sqlt$migrate;
WHENEVER SQLERROR CONTINUE;
SET TERM ON ECHO OFF;
SELECT LPAD(s.statement_id, 5, '0') staid,
       SUBSTR(s.method, 1, 3) method,
       SUBSTR(s.instance_name_short, 1, 8) instance,
       SUBSTR(s.sql_text, 1, 60) sql_text
  FROM sqltxplain.sqlt$_sql_statement s
 WHERE USER IN ('SYS', 'SYSTEM', s.username)
 ORDER BY
       s.statement_id;
PRO
PRO Purging a range of statement_ids.
PRO
PRO Parameter 1:
PRO STATEMENT_ID from (required)
PRO
DEF statement_id_from = '&1';
PRO
PRO Parameter 2:
PRO STATEMENT_ID to (required)
PRO
DEF statement_id_to = '&2';
PRO
PRO Values passed to sqlthistpurge:
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO STATEMENT_ID_FROM: "&&statement_id_from."
PRO STATEMENT_ID_TO  : "&&statement_id_to."
PRO
PRO ... purging statements from &&statement_id_from. to &&statement_id_to.
PRO
EXEC sqltxadmin.sqlt$a.purge_repository(TO_NUMBER(TRIM('&&statement_id_from.')), TO_NUMBER(TRIM('&&statement_id_to.')));
SPO OFF;
UNDEFINE 1 2 statement_id_from statement_id_to;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON HEA ON LIN 80 PAGES 14 TRIMS OFF TI OFF TIMI OFF NUMF "" SQLP SQL> APPI OFF SERVEROUT OFF;
PRO SQLTHISTPURGE completed.
