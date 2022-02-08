SPO sqltmain.log;
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LIN 200 PAGES 100 TRIMS ON TI OFF TIMI OFF APPI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM $Header: 215187.1 sqltmain.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/sqltmain.sql
REM
REM DESCRIPTION
REM   This script generates the main html report out of the SQLT
REM   repository.
REM   Since all details are captured in SQLT repository, this script
REM   can be used to quickly re-gerenate a main html report.
REM
REM PRE-REQUISITES
REM   1. Execute SQLT XPLORE, XECUTE or XPLAIN on SOURCE.
REM   2. Import SQLT repository into TARGET system as per readme.
REM
REM PARAMETERS
REM   1. Statement ID as per SQLT in SOURCEs system (required)
REM      A list of statement ids is presented.
REM
REM EXECUTION
REM   1. Navigate to sqlt/utl directory.
REM   2. Connect into SQL*Plus as SYSDBA or application user
REM      or SYSDBA.
REM   3. Execute script sqltmain.sql passing statement id
REM      (parameters can be passed inline or until requested).
REM
REM EXAMPLE
REM   # cd sqlt/run
REM   # sqlplus sqltxadmin
REM   SQL> START sqltmain.sql [statement id]
REM   SQL> START sqltmain.sql 32263
REM   SQL> START sqltmain.sql;
REM
REM NOTES
REM   1. For possible errors see sqltmain.log
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
SELECT LPAD(s.statement_id, 5, '0') staid,
       SUBSTR(s.method, 1, 3) method,
       SUBSTR(s.instance_name_short, 1, 8) instance,
       SUBSTR(s.sql_text, 1, 60) sql_text
  FROM sqltxadmin.sqlt$_sql_statement s
 WHERE USER IN ('SYS', 'SYSTEM', s.username)
 ORDER BY
       s.statement_id;
PRO
PRO Parameter 1:
PRO STATEMENT_ID (required)
PRO
DEF statement_id = '&1';
PRO
PRO
PRO Values passed to sqltmain:
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~
PRO STATEMENT_ID: "&&statement_id."
PRO
PRO ... please wait ...
PRO
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM OFF;
--
EXEC sqltxadmin.sqlt$t.column_in_predicates(TO_NUMBER(TRIM('&&statement_id.')));
EXEC sqltxadmin.sqlt$t.column_in_projection(TO_NUMBER(TRIM('&&statement_id.')));
EXEC sqltxadmin.sqlt$a.s_log_statement_id := TO_NUMBER(TRIM('&&statement_id.'));
EXEC sqltxadmin.sqlt$a.s_log_statid := sqltxadmin.sqlt$a.get_statid(sqltxadmin.sqlt$a.s_log_statement_id);
EXEC sqltxadmin.sqlt$m.main_report_root(TO_NUMBER(TRIM('&&statement_id.')));
WHENEVER SQLERROR CONTINUE;
SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;
SET SERVEROUT ON SIZE UNL FOR TRU;
COL column_value FOR A2000;
COL filename NEW_V filename FOR A256;
--
SELECT NVL(sqltxadmin.sqlt$e.get_filename_from_repo('MAIN_REPORT', TO_NUMBER(TRIM('&&statement_id.'))), 'missing_file.txt') filename FROM DUAL;
SET TERM ON;
PRO ... getting &&filename. out of sqlt repository ...
SET TERM OFF;
SPO &&filename.;
SELECT * FROM TABLE(sqltxadmin.sqlt$r.display_file('&&filename.', TO_NUMBER(TRIM('&&statement_id.'))));
SPO OFF;
--
CL COL;
UNDEFINE 1 statement_id;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NEWP 1 PAGES 14 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF;
PRO
PRO &&filename. has been generated
PRO
PRO SQLTMAIN completed.
