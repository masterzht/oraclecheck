SPO sqltcompare.log;
@@sqltcommon1.sql
REM
REM $Header: 215187.1 sqltcompare.sql 12.2.170914 2017/09/14 carlos.sierra abel.macias@oracle.com $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqlt/run/sqltcompare.sql
REM
REM DESCRIPTION
REM   This script compares two prior executions of SQLT and
REM   identifies differences in execution plans, CBO statistics,
REM   metadata, CBO initialization parameters and bug fix control.
REM
REM PRE-REQUISITES
REM   1. Execute any standard method of SQLT in both SOURCES.
REM   2. Import SQLT repository into test system as per readme.
REM
REM PARAMETERS
REM   1. Statement IDs as per SQLT in SOURCEs system (required)
REM      A list of statement ids is presented.
REM   2. Plan Hash Value for both statement ids (required).
REM      A list of known plans is presented.
REM
REM EXECUTION
REM   1. Navigate to sqlt/run directory.
REM   2. Connect to SQL*Plus as application user with SQLT_USER_ROLE
REM      or SYSDBA.
REM   3. Execute script sqltcompare.sql passing statement ids and
REM      plan hash values (parameters can be passed inline or until
REM      requested).
REM
REM EXAMPLE
REM   # cd sqlt/run
REM   # sqlplus / as sysdba
REM   SQL> START sqltcompare.sql [statement id1] [statement id2] [plan hash value1] [plan hash value2];
REM   SQL> START sqltcompare.sql 32263 92366 8673881838 1452771383;
REM   SQL> START sqltcompare.sql 32263 92366;
REM   SQL> START sqltcompare.sql;
REM
REM NOTES
REM   1. For possible errors see sqltcompare.log
REM
@@sqltcommon2.sql
@@sqltcommon4.sql
PRO ... please wait ...
SET TERM OFF ECHO ON;
WHENEVER SQLERROR CONTINUE;
SET TERM ON ECHO OFF;
SELECT LPAD(s.statement_id, 5, '0') staid,
       SUBSTR(s.method, 1, 3) method,
       SUBSTR(s.instance_name_short, 1, 8) instance,
       SUBSTR(s.sql_text, 1, 60) sql_text
  FROM ^^tool_repository_schema..sqlt$_sql_statement s
 ORDER BY
       s.statement_id;
PRO
PRO Parameter 1:
PRO STATEMENT_ID1 (required)
PRO
DEF statement_id1 = '^1';
PRO
PRO Parameter 2:
PRO STATEMENT_ID2 (required)
PRO
DEF statement_id2 = '^2';
PRO
PRO
COL statement_id FOR 99999999999;
COL attribute FOR A9;
SELECT p.plan_hash_value, p.sqlt_plan_hash_value, p.statement_id,
       DECODE(p.plan_hash_value, s.best_plan_hash_value, '[B]')||
       DECODE(p.plan_hash_value, s.worst_plan_hash_value, '[W]')||
       DECODE(p.plan_hash_value, s.xecute_plan_hash_value, '[X]') attribute
  FROM (
SELECT DISTINCT plan_hash_value, sqlt_plan_hash_value, statement_id
  FROM ^^tool_repository_schema..sqlt$_plan_extension
 WHERE statement_id = TO_NUMBER(TRIM('^^statement_id1.'))) p,
       ^^tool_repository_schema..sqlt$_sql_statement s
 WHERE p.statement_id = s.statement_id
 ORDER BY
       p.plan_hash_value;
PRO
PRO Parameter 3:
PRO PLAN_HASH_VALUE1 (required if more than one)
PRO
DEF plan_hash_value1 = '^3';
PRO
SELECT p.plan_hash_value, p.sqlt_plan_hash_value, p.statement_id,
       DECODE(p.plan_hash_value, s.best_plan_hash_value, '[B]')||
       DECODE(p.plan_hash_value, s.worst_plan_hash_value, '[W]')||
       DECODE(p.plan_hash_value, s.xecute_plan_hash_value, '[X]') attribute
  FROM (
SELECT DISTINCT plan_hash_value, sqlt_plan_hash_value, statement_id
  FROM ^^tool_repository_schema..sqlt$_plan_extension
 WHERE statement_id = TO_NUMBER(TRIM('^^statement_id2.'))) p,
       ^^tool_repository_schema..sqlt$_sql_statement s
 WHERE p.statement_id = s.statement_id
 ORDER BY
       p.plan_hash_value;
PRO
PRO Parameter 4:
PRO PLAN_HASH_VALUE2 (required if more than one)
PRO
DEF plan_hash_value2 = '^4';
PRO
PRO
PRO Values passed to sqltcompare:
PRO STATEMENT_ID1   : "^^statement_id1."
PRO STATEMENT_ID2   : "^^statement_id2."
PRO PLAN_HASH_VALUE1: "^^plan_hash_value1."
PRO PLAN_HASH_VALUE2: "^^plan_hash_value2."
PRO
EXEC DBMS_APPLICATION_INFO.SET_MODULE('sqltcompare', 'script');
PRO
PRO ... please wait ...
PRO
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM ON ECHO OFF VER OFF;
EXEC ^^tool_administer_schema..sqlt$c.compare_report(TO_NUMBER(TRIM('^^statement_id1.')), TO_NUMBER(TRIM('^^statement_id2.')), TO_NUMBER(TRIM('^^plan_hash_value1.')), TO_NUMBER(TRIM('^^plan_hash_value2.')));
WHENEVER SQLERROR CONTINUE;
SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;
SET SERVEROUT ON SIZE UNL FOR TRU;
PRO No fatal errors!
COL filename NEW_V filename FOR A256;
SPO OFF;
DEF filename = 'sqlt_s^^statement_id1._s^^statement_id2._compare.html';
SPO ^^filename.;
SELECT * FROM TABLE(^^tool_administer_schema..sqlt$r.display_file('^^filename.', TO_NUMBER(TRIM('^^statement_id1.')), TO_NUMBER(TRIM('^^statement_id2.'))));
SPO OFF;
SET TERM ON;
PRO
PRO ^^filename. has been generated
-- 22759168 the purge file is not relevant for compare
--@@sqltcommon9.sql
UNDEF 2 3 4 filename
UNDEF statement_id1 statement_id2 plan_hash_value1 plan_hash_value2
PRO SQLTCOMPARE completed.

