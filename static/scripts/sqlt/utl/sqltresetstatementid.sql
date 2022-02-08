SPO sqltresetstatementid.log;
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LIN 200 PAGES 100 TRIMS ON TI OFF TIMI OFF APPI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM $Header: 215187.1 sqltresetstatementid.sql 12.1.03 2013/10/10 mauro.pagano $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/sqltresetstatementid.sql
REM
REM DESCRIPTION
REM   Reset the Statement ID in the SQLT repository.
REM
REM PRE-REQUISITES
REM   1. Connect as SYS user.
REM
REM EXECUTION
REM   1. Navigate to sqlt main directory.
REM   2. Start SQL*Plus connecting as SYS user.
REM   3. Execute script sqltresetstatementid.sql .
REM
REM EXAMPLE
REM   # cd sqlt
REM   # sqlplus system
REM   SQL> START [path]sqltresetstatementid.sql 
REM   SQL> START utl/sqltresetstatementid.sql
REM
REM NOTES
REM   1. For possible errors see sqltresetstatementid.log
REM
@@install/sqcommon1.sql
DEF _SQLPLUS_RELEASE

SET TERM ON ECHO OFF;

PRO Dropping sequence sqlt$_sql_statement_id_s
DROP SEQUENCE &&tool_repository_schema..sqlt$_sql_statement_id_s;

SET NUMF "";
COL start_with NEW_V start_with;
SET TERM OFF
SELECT (NVL(MOD(TRUNC(ABS(SYS.DBMS_RANDOM.RANDOM)), 89000), 0) + 10000) start_with FROM DUAL;
SET TERM ON
PRO Recreating sequence sqlt$_sql_statement_id_s starting with &&start_with.

CREATE SEQUENCE &&tool_repository_schema..sqlt$_sql_statement_id_s START WITH &&start_with. NOCACHE;
ALTER SEQUENCE &&tool_repository_schema..sqlt$_sql_statement_id_s NOCACHE;

PRO No fatal errors!
SPO OFF;
PRO SQLTRESETSTATEMENTID completed.
