SET ECHO ON TERM OFF SERVEROUT ON SIZE 1000000;
REM
REM $Header: 224270.1 tadusr.sql 12.1.12 2015/09/11 carlos.sierra abel.macias@oracle.com $ 
REM
REM Copyright (c) 2000-2015, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   tadusr.sql
REM
REM DESCRIPTION
REM   This script drops the TRCANLZR user
REM
REM PRE-REQUISITES
REM   1. This script must be executed connected INTERNAL (SYS) as
REM      SYSDBA
REM
REM PARAMETERS
REM   1. None
REM
REM EXECUTION
REM   1. Navigate to trca/install directory
REM   2. Start SQL*Plus connecting INTERNAL (SYS) as SYSDBA
REM   3. Execute script tadusr.sql
REM
REM EXAMPLE
REM   # cd trca/install
REM   # sqlplus /nolog
REM   SQL> connect / as sysdba
REM   SQL> start tadusr.sql
REM
REM NOTES
REM   1. This script is executed automatically by tadrop.sql
REM
SET ECHO OFF TERM OFF;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
BEGIN
  IF USER <> 'SYS' THEN
    RAISE_APPLICATION_ERROR(-20100, 'Drop script failed - tadusr.sql should be executed connected as SYS, not as '||USER);
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
SET ECHO ON;

PRO
PRO  Drop TRCA$ directories
PRO

-- old directories
DROP DIRECTORY TRCA$OUTPUT;
DROP DIRECTORY TRCA$INPUT;
DROP DIRECTORY TRCA$BDUMP;

-- current directories
DECLARE
  my_count INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO my_count
    FROM sys.dba_users
   WHERE username IN ('SQLTXPLAIN', 'SQLTXADMIN');

  IF my_count = 0 THEN
    BEGIN
      EXECUTE IMMEDIATE 'DROP PROCEDURE sys.sqlt$_trca$_dir_set';
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Cannot drop procedure sys.sqlt$_trca$_dir_set. '||SQLERRM);
    END;

	-- 150826 drop SQLT$DIAG too
    FOR i IN (SELECT directory_name
                FROM sys.dba_directories
               WHERE directory_name IN ('SQLT$UDUMP', 'SQLT$BDUMP', 'SQLT$STAGE', 'SQLT$DIAG', 'TRCA$INPUT1', 'TRCA$INPUT2', 'TRCA$STAGE'))
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

PRO
PRO  Drop users TRCANLZR and TRCADMIN
PRO

COL prior_default_tablespace NEW_VALUE prior_default_tablespace FOR A30;
COL prior_temporary_tablespace NEW_VALUE prior_temporary_tablespace FOR A30;
SELECT 'UNKNOWN' prior_default_tablespace,
       'UNKNOWN' prior_temporary_tablespace
  FROM dual;

SELECT default_tablespace prior_default_tablespace,
       temporary_tablespace prior_temporary_tablespace
  FROM sys.dba_users
 WHERE username = 'TRCANLZR';

PRO
PRO PRIOR_DEFAULT_TABLESPACE: &&prior_default_tablespace.
PRO PRIOR_TEMPORARY_TABLESPACE: &&prior_temporary_tablespace.
PRO

REM This CREATE USER command may fail and that is OK.
COL random_number NOPRI NEW_VALUE random_number FORMAT A10;
SELECT TO_CHAR(NVL(ABS(MOD(TRUNC(SYS.DBMS_RANDOM.RANDOM), 100000)), 0)) random_number FROM DUAL;

CREATE USER &&tool_repository_schema. IDENTIFIED BY "Dummy_Password:&&random_number.";
CREATE USER &&tool_administer_schema. IDENTIFIED BY "Dummy_Password:&&random_number.";

WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM ON;

PAU About to DROP users &&tool_repository_schema. and &&tool_administer_schema.. Press RETURN to continue.

REM If DROP USER command fails then a session is currently connected.
PRO
DROP USER &&tool_repository_schema. CASCADE;
DROP USER &&tool_administer_schema. CASCADE;

WHENEVER SQLERROR CONTINUE;

DROP ROLE &&role_name.;

SET ECHO OFF;

PRO TADUSR completed.
