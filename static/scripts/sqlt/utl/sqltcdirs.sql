SPOOL sqltcdirs.log;
SET TERM OFF ECHO ON;
REM $Header: 215187.1 sqltcdirs.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqltcdirs.sql
REM
REM DESCRIPTION
REM   Creates an alias pointer to the SQLT stage server directory.
REM
REM PRE-REQUISITES
REM   1. This script must be executed connected INTERNAL (SYS) as
REM      SYSDBA.
REM   2. ORACLE must have read/write access to directory specified.
REM
REM PARAMETERS
REM   1. Full path of existing staging directory (required)
REM      This value is case sensitive, and actual directory must
REM      exists in server prior to the execution of this script.
REM      Path should not end with / or \
REM
REM EXECUTION
REM   1. Navigate to sqlt/utl directory.
REM   2. Start SQL*Plus connecting INTERNAL (SYS) as SYSDBA.
REM   3. Execute script sqltcdirs.sql passing valid path.
REM
REM EXAMPLE
REM   # cd sqlt/utl
REM   # sqlplus / as sysdba
REM   SQL> START sqltcdirs.sql [full stage directory path]
REM   SQL> START sqltcdirs.sql /home/csierra
REM
REM NOTES
REM   1. For possible errors see sqltcdirs.log file
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
WHENEVER SQLERROR EXIT SQL.SQLCODE;
BEGIN
  IF USER <> 'SYS' THEN
    RAISE_APPLICATION_ERROR(-20100, 'Directory alias should be created connected as SYS, not as '||USER);
  END IF;
END;
/

/* ---------------------------------------------------------------------- */

PRO ... Creating SQLT$ STAGE Directory
PRO
PRO Parameter 1:
PRO Full path of existing staging directory (required)
PRO
DEF directory_path = '&1';

BEGIN
  IF '&&directory_path' LIKE '%?%' OR '&&directory_path' LIKE '%*%' THEN
    RAISE_APPLICATION_ERROR(-20101, 'Directory &&directory_path cannot contain "?" or "*" symbols');
  END IF;
  IF SUBSTR('&&directory_path', LENGTH('&&directory_path'), 1) IN (' ', '/', '\') THEN
    RAISE_APPLICATION_ERROR(-20102, 'Directory &&directory_path cannot end with " ", "/" or "\" symbols');
  END IF;
END;
/

CREATE OR REPLACE DIRECTORY SQLT$STAGE AS '&&directory_path';

GRANT READ,WRITE ON DIRECTORY SQLT$STAGE TO sqltxadmin;

DECLARE
  my_count INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO my_count
    FROM dba_users
   WHERE username = 'TRCADMIN';
  IF my_count > 0 THEN
    EXECUTE IMMEDIATE 'GRANT READ,WRITE ON DIRECTORY SQLT$STAGE TO trcadmin';
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE;
SPOOL OFF;
UNDEFINE 1 directory_path
