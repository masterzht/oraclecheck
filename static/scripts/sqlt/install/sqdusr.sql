SET ECHO ON TERM OFF SERVEROUT ON SIZE 1000000;
REM
REM $Header: 215187.1 sqdusr.sql 11.4.5.2 2012/12/12 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/install/sqdusr.sql
REM
REM DESCRIPTION
REM   This script drops the SQLTXPLAIN user
REM
REM PRE-REQUISITES
REM   1. To drop SQLTXPLAIN user you must connect as SYSDBA.
REM
REM PARAMETERS
REM   1. None
REM
REM EXECUTION
REM   1. Navigate to sqlt/install directory.
REM   2. Start SQL*Plus and connect as SYSDBA.
REM   3. Execute script sqdusr.sql.
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqdusr.sql
REM
REM NOTES
REM   1. This script is executed automatically by sqdrop.sql
REM
@@sqcommon1.sql

SET ECHO ON TERM ON;

DECLARE
  my_count INTEGER;

BEGIN
  SELECT COUNT(*)
    INTO my_count
    FROM sys.dba_users
   WHERE username = 'TRCADMIN';

  IF my_count = 0 THEN
    BEGIN
      EXECUTE IMMEDIATE 'DROP PROCEDURE sys.sqlt$_trca$_dir_set';
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Cannot drop procedure sys.sqlt$_trca$_dir_set. '||SQLERRM);
    END;

    FOR i IN (SELECT directory_name
                FROM sys.dba_directories
               WHERE directory_name IN ('SQLT$UDUMP', 'SQLT$BDUMP', 'SQLT$STAGE', 'TRCA$INPUT1', 'TRCA$INPUT2', 'TRCA$STAGE'))
    LOOP
      BEGIN
        EXECUTE IMMEDIATE 'DROP DIRECTORY '||i.directory_name;
        DBMS_OUTPUT.PUT_LINE('Dropped directory '||i.directory_name||'.');
      EXCEPTION
        WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('Cannot drop directory '||i.directory_name||'. '||SQLERRM);
      END;
    END LOOP;
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE;

PAU About to DROP users &&tool_repository_schema. and &&tool_administer_schema.. Press RETURN to continue.

DROP USER &&tool_administer_schema. CASCADE;
DROP USER &&tool_repository_schema. CASCADE;
DROP ROLE &&role_name.;

SET ECHO OFF;
PRO
PRO SQDUSR completed.
