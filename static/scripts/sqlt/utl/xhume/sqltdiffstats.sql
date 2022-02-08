SPO sqltdiffstats.log;
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LONG 800000 LONGC 160 LIN 200 PAGES 100 TRIMS ON TI OFF TIMI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM
REM $Header: 215187.1 sqltdiffstats.sql 11.4.3.5 2011/08/10 carlos.sierra $
REM
REM Copyright (c) 2000-2011, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/xhume/sqltdiffstats.sql
REM
REM DESCRIPTION
REM   Generates a report with differences in TC schema object
REM   statistics after SQLT XHUME has been used.
REM
REM PRE-REQUISITES
REM   1. SQLT XHUME on a SQLT TC.
REM
REM PARAMETERS
REM   1. Test ID1 (required)
REM      Valid range is from a SQLT XHUME report.
REM   2. Test ID2 (required)
REM      Valid range is from a SQLT XHUME report.
REM   3. Threshold Percent (optional)
REM      Default 10
REM
REM EXECUTION
REM   1. Navigate to sqlt/utl/xhume directory.
REM   2. Start SQL*Plus connecting as TC user.
REM   3. Execute script sqltdiffstats.sql passing test ids
REM      (parameters can be passed inline or until requested).
REM
REM EXAMPLE
REM   # cd sqlt/utl/xhume
REM   # sqlplus / as TC99999
REM   SQL> START [path]sqltdiffstats.sql [test_id1] [test_id2]
REM   SQL> START sqltdiffstats.sql 12 13
REM   SQL> START sqltdiffstats.sql
REM
REM NOTES
REM   1. For possible errors see sqltdiffstats.log
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
PRO Parameter 1:
PRO TEST_ID1 (required)
PRO
PRO As per SQLT XHUME report.
PRO
DEF test_id1 = '&1';
PRO
PRO Parameter 2:
PRO TEST_ID2 (required)
PRO
PRO As per SQLT XHUME report.
PRO
DEF test_id2 = '&2';
PRO
PRO Parameter 3:
PRO THRESHOLD_PERCENT (default 10)
PRO
PRO Report statistics differences greater than this threshold percent.
PRO
DEF threshold_percent = '&3';
PRO
PRO Values passed:
PRO ~~~~~~~~~~~~~
PRO TEST_ID1          : "&&test_id1."
PRO TEST_ID2          : "&&test_id2."
PRO THRESHOLD_PERCENT : "&&threshold_percent."
PRO
PRO ... generating schema object stats diff ...
PRO
SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF SERVEROUT ON SIZE 1000000 FOR TRU;
SET SERVEROUT ON SIZE UNL FOR TRU;
SPO sqltdiffstats_&&test_id1._&&test_id2..txt;
SELECT d.report
  FROM xhume_test t1,
       xhume_test t2,
       xhume_table tbl,
       TABLE(DBMS_STATS.DIFF_TABLE_STATS_IN_HISTORY(tbl.owner, tbl.table_name, t1.xhume_time, t2.xhume_time, TO_NUMBER(NVL('&&threshold_percent.', '10')))) d
 WHERE t1.test_id = &&test_id1.
   AND t1.run_id IS NULL
   AND t2.test_id = &&test_id2.
   AND t2.run_id IS NULL;
SPO OFF;
UNDEFINE 1 2 test_id1 test_id2;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON HEA ON LONG 80 LONGC 80 LIN 80 PAGES 14 TRIMS OFF TI OFF TIMI OFF SERVEROUT OFF NUMF "" SQLP SQL>;
PRO
PRO SQLTDIFFSTATS completed.
