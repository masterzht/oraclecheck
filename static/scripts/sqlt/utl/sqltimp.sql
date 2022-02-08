SPO sqltimp.log;
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LIN 200 PAGES 100 TRIMS ON TI OFF TIMI OFF APPI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM $Header: 215187.1 sqltimp.sql 11.4.5.8 2013/05/10 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/sqltimp.sql
REM
REM DESCRIPTION
REM   Restores into the data dictionary the set of CBO schema object
REM   statistics related to one SQL statement.
REM
REM PRE-REQUISITES
REM   1. Import SQLT repository into test system as per readme.
REM
REM PARAMETERS
REM   1. Statement ID (required)
REM      A list of available statement_ids is presented.
REM   2. Schema Owner (required and case sensitive)
REM      Usually the Test Case user (TC99999) as per metadata script.
REM      If you do not want to remap the schema owner to a TC user,
REM      enter token NULL or hit "enter" key.
REM
REM EXECUTION
REM   1. Navigate to sqlt/utl directory.
REM   2. Start SQL*Plus connecting as SYSDBA or application user.
REM   3. Execute script sqltimp.sql passing statement id and schema
REM      owner (parameters can be passed inline or until requested).
REM
REM EXAMPLE
REM   # cd sqlt/utl
REM   # sqlplus / as sysdba
REM   SQL> START [path]sqltimp.sql [statement_id] [TC schema owner]
REM   SQL> START sqltimp.sql s99999 TC99999
REM   SQL> START sqltimp.sql 99999 NULL
REM   SQL> START sqltimp.sql
REM
REM NOTES
REM   1. For possible errors see sqltimp.log
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
COL statid FOR A30 HEA 'Statement id'
COL objects FOR A19 HEA 'Tables/Indexes/Cols'
COL sqlt_date FOR A18 HEA 'SQLT Date'
SELECT g.statid,
       COUNT(*) "Stats Rows",
       (SELECT COUNT(*) FROM sqltxplain.sqlt$_stattab t WHERE t.statid = g.statid AND t.type = 'T' AND t.c2 IS NULL)||'/'||
       (SELECT COUNT(*) FROM sqltxplain.sqlt$_stattab i WHERE i.statid = g.statid AND i.type = 'I' AND i.c2 IS NULL)||'/'||
       (SELECT COUNT(*) FROM sqltxplain.sqlt$_stattab c WHERE c.statid = g.statid AND c.type = 'C' AND c.c2 IS NULL) objects,
       (SELECT TO_CHAR(s.tool_start_date, 'DD-MON-YY HH24:MI:SS') FROM sqltxplain.sqlt$_sql_statement s WHERE s.statid = g.statid AND ROWNUM = 1) sqlt_date
  FROM sqltxplain.sqlt$_stattab g
 WHERE g.statid LIKE 's%'
 GROUP BY g.statid
 ORDER BY g.statid;
PRO
PRO Parameter 1:
PRO STATEMENT_ID (required)
PRO
DEF statement_id = '&1';
PRO
PRO Parameter 2:
PRO SCHEMA_OWNER (required and case sensitive)
PRO
PRO Usually the Test Case user (TC99999) as per metadata script.
PRO If you do not want to remap the schema owner to a TC user,
PRO enter token NULL or hit "enter" key.
PRO
DEF schema_owner = '&2';
PRO
PRO Values passed to sqltimp:
PRO ~~~~~~~~~~~~~~~~~~~~~~~~
PRO STATEMENT_ID: "&&statement_id."
PRO SCHEMA_OWNER: "&&schema_owner."
PRO
PRO ... restoring cbo stats ...
PRO
WHENEVER SQLERROR EXIT SQL.SQLCODE;
EXEC sqltxadmin.sqlt$a.validate_user(USER);
TRUNCATE TABLE SQLTXPLAIN.SQLI$_STATTAB_TEMP;
ALTER SESSION SET optimizer_dynamic_sampling = 0;
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 12';
-- if you need to upload stats history so you can use SQLT XHUME you need to pass p_load_hist as Y
EXEC sqltxadmin.sqlt$a.import_cbo_stats(p_statement_id => TRIM('&&statement_id.'), p_schema_owner => TRIM('&&schema_owner'), p_include_bk => 'N', p_make_bk => 'N', p_load_hist => 'N');
ALTER SESSION SET SQL_TRACE = FALSE;
ALTER SESSION SET optimizer_dynamic_sampling = 2;
WHENEVER SQLERROR CONTINUE;
SPO OFF;
CL COL;
UNDEFINE 1 2 statement_id schema_owner;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON HEA ON LIN 80 PAGES 14 TRIMS OFF TI OFF TIMI OFF APPI OFF SERVEROUT OFF NUMF "" SQLP SQL>;
PRO
PRO SQLTIMP completed.
