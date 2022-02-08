SPO sqltimpfo.log;
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LIN 200 PAGES 100 TRIMS ON TI OFF TIMI OFF APPI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM $Header: 215187.1 sqltimpfo.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/sqltimpfo.sql
REM
REM DESCRIPTION
REM   Restores into the data dictionary the set of CBO statistics
REM   for all fixed objects.
REM
REM PRE-REQUISITES
REM   1. Import SQLT repository into test system as per readme.
REM
REM PARAMETERS
REM   1. Statement ID (required)
REM      A list of available statement_ids is presented.
REM
REM EXECUTION
REM   1. Navigate to sqlt/utl directory.
REM   2. Start SQL*Plus connecting as SYSDBA or application user.
REM   3. Execute script sqltimpfo.sql passing statement id
REM      (parameter can be passed inline or until requested).
REM
REM EXAMPLE
REM   # cd sqlt/utl
REM   # sqlplus / as sysdba
REM   SQL> START [path]sqltimpfo.sql [statement_id]
REM   SQL> START sqltimpfo.sql s99999
REM   SQL> START sqltimpfo.sql
REM
REM NOTES
REM   1. For possible errors see sqltimpfo.log
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
COL objects FOR A14 HEA 'Tables/Columns'
COL sqlt_date FOR A18 HEA 'SQLT Date'
SELECT g.statid,
       COUNT(*) "Stats Rows",
       (SELECT COUNT(*) FROM sqltxplain.sqlt$_stattab t WHERE t.statid = g.statid AND t.type = 'T' AND t.c2 IS NULL)||'/'||
       (SELECT COUNT(*) FROM sqltxplain.sqlt$_stattab c WHERE c.statid = g.statid AND c.type = 'C' AND c.c2 IS NULL) objects,
       (SELECT TO_CHAR(s.tool_start_date, 'DD-MON-YY HH24:MI:SS') FROM sqltxplain.sqlt$_sql_statement s WHERE s.statid = 's'||SUBSTR(g.statid, 2) AND ROWNUM = 1) sqlt_date
  FROM sqltxplain.sqlt$_stattab g
 WHERE g.statid LIKE 'f%'
 GROUP BY g.statid
 ORDER BY g.statid;
PRO
PRO Parameter 1:
PRO STATEMENT_ID (required)
PRO
DEF statement_id = '&1';
PRO
PRO Value passed to sqltimpfo:
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
PRO STATEMENT_ID: "&&statement_id."
PRO
PRO ... restoring fixed objects cbo stats ...
PRO
WHENEVER SQLERROR EXIT SQL.SQLCODE;
EXEC sqltxadmin.sqlt$a.validate_user(USER);
EXEC sqltxadmin.sqlt$a.import_cbo_stats_fixed_objects(p_statement_id => TRIM('&&statement_id.'), p_make_bk => 'Y');
WHENEVER SQLERROR CONTINUE;
SPO OFF;
CL COL;
UNDEFINE 1 2 statement_id;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON HEA ON LIN 80 PAGES 14 TRIMS OFF TI OFF TIMI OFF APPI OFF SERVEROUT OFF NUMF "" SQLP SQL>;
PRO
PRO SQLTIMPFO completed.
