SET ECHO ON TERM OFF VER OFF NUMF "";
COL yymmddhh24miss NEW_V yymmddhh24miss NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYMMDDHH24MISS') yymmddhh24miss FROM DUAL;
SPO &&yymmddhh24miss._02_tacusr.log;
REM $Header: 224270.1 tacusr.sql 12.1.03 2013/10/10 carlos.sierra trcanlzr $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   tacusr.sql
REM
REM DESCRIPTION
REM   This script creates user TRCANLZR and the grants it needs
REM
REM PRE-REQUISITES
REM   1. To install SQLT you must connect as SYSDBA.
REM
REM PARAMETERS
REM   1. TRCANLZR password - Required and it has no default
REM   2. TRCANLZR default tablespace - You will be presented
REM      with a list, then you will have to enter one tablespace
REM      name from that list
REM   3. TRCANLZR temporary tablespace - Similar as above
REM   4. Main application user of TRCA (optional).
REM      This is the user name that will later execute TRCA.
REM      You can add aditional TRCA users by granting them
REM      role TRCA_USER_ROLE after the tool is installed.
REM   5. Type of object for large staging tables - Enter "T" is
REM      you want large tables to be created as PERMANENT, or
REM      "N" if you prefer GLOBAL TEMPORARY (recommended)
REM
REM PARAMETERS
REM   1. None inline. During the installation you will be asked for
REM      the values of the parameters described under pre-requisites
REM      section above
REM
REM EXECUTION
REM   1. Navigate to trca/install directory
REM   2. Start SQL*Plus connect as SYSDBA
REM   3. Execute script tacusr.sql
REM
REM EXAMPLE
REM   # cd trca/install
REM   # sqlplus / as sysdba
REM   SQL> START tacusr.sql
REM
REM NOTES
REM   1. This script is executed automatically by tacreate.sql
REM   2. For possible errors see tacusr.log file
REM
SET ECHO OFF TERM ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";
DECLARE
  rdbms_release NUMBER;
BEGIN
  IF USER <> 'SYS' THEN
    RAISE_APPLICATION_ERROR(-20100, 'Install failed - &&tool_repository_schema. should be installed connected as SYS, not as '||USER);
  END IF;
  SELECT TO_NUMBER(SUBSTR(version, 1, INSTR(version, '.', 1, 2) - 1))
    INTO rdbms_release
    FROM v$instance;
  IF rdbms_release < 9.2 THEN
    RAISE_APPLICATION_ERROR(-20200, 'Install failed - &&tool_repository_schema. should be installed in 9i(9.2) or higher, not in '||rdbms_release);
  END IF;
END;
/

SET ECHO OFF TERM OFF;

COL prior_default_tablespace NEW_VALUE prior_default_tablespace FOR A30;
COL prior_temporary_tablespace NEW_VALUE prior_temporary_tablespace FOR A30;
COL tablespace_name FOR A30 HEA "TABLESPACE";
COL default_tablespace NEW_VALUE default_tablespace FOR A30;
COL temporary_tablespace NEW_VALUE temporary_tablespace FOR A30;
COL application_schema NEW_VALUE application_schema FOR A30;

SELECT 'UNKNOWN' prior_default_tablespace,
       'UNKNOWN' prior_temporary_tablespace
  FROM dual;

SELECT default_tablespace prior_default_tablespace,
       temporary_tablespace prior_temporary_tablespace
  FROM sys.dba_users
 WHERE username = '&&tool_repository_schema.';

/* ---------------------------------------------------------------------- */

SET ECHO OFF TERM ON;

PRO
PRO Define the TRCANLZR user password (hidden and case sensitive).
PRO
ACC enter_tool_password PROMPT 'Specify TRCANLZR password: ' HIDE;
ACC re_enter_password PROMPT 'Re-enter password: ' HIDE;
PRO

BEGIN
  IF '&&enter_tool_password.' IS NULL THEN
    RAISE_APPLICATION_ERROR(-20102, 'Install failed - No password specified for &&tool_repository_schema. user');
  END IF;
  IF NVL('&&enter_tool_password.', '-666') LIKE '% %' THEN
    RAISE_APPLICATION_ERROR(-20104, 'Install failed - Password for &&tool_repository_schema. user cannot contain spaces');
  END IF;
  IF NVL('&&enter_tool_password.', '-666') <> NVL('&&re_enter_password.', '-999') THEN
    RAISE_APPLICATION_ERROR(-20106, 'Re-entered password did not match');
  END IF;
END;
/

/* ---------------------------------------------------------------------- */

REM
REM Creating TRCANLZR user
REM

BEGIN
  EXECUTE IMMEDIATE('CREATE USER &&tool_repository_schema. IDENTIFIED BY "&&enter_tool_password."');
  SYS.DBMS_OUTPUT.PUT_LINE('User &&tool_repository_schema. created');
EXCEPTION
  WHEN OTHERS THEN
    SYS.DBMS_OUTPUT.PUT_LINE('User &&tool_repository_schema. could not be created. '||SQLERRM);
END;
/

BEGIN
  EXECUTE IMMEDIATE('ALTER USER &&tool_repository_schema. IDENTIFIED BY "&&enter_tool_password."');
  SYS.DBMS_OUTPUT.PUT_LINE('User &&tool_repository_schema. altered');
EXCEPTION
  WHEN OTHERS THEN
    SYS.DBMS_OUTPUT.PUT_LINE('User &&tool_repository_schema. could not be altered. '||SQLERRM);
END;
/

/* ---------------------------------------------------------------------- */

REM
REM Creating TRCADMIN user
REM

BEGIN
  --SYS.DBMS_RANDOM.SEED('&&enter_tool_password.');
  EXECUTE IMMEDIATE('CREATE USER &&tool_administer_schema. IDENTIFIED BY "&&enter_tool_password.'||SYS.DBMS_RANDOM.RANDOM||'" PASSWORD EXPIRE ACCOUNT LOCK');
  SYS.DBMS_OUTPUT.PUT_LINE('User &&tool_administer_schema. created');
EXCEPTION
  WHEN OTHERS THEN
    SYS.DBMS_OUTPUT.PUT_LINE('User &&tool_administer_schema. could not be created. '||SQLERRM);
END;
/

BEGIN
  --SYS.DBMS_RANDOM.SEED('&&enter_tool_password.');
  EXECUTE IMMEDIATE('ALTER USER &&tool_administer_schema. IDENTIFIED BY "&&enter_tool_password.'||SYS.DBMS_RANDOM.RANDOM||'" PASSWORD EXPIRE ACCOUNT LOCK');
  SYS.DBMS_OUTPUT.PUT_LINE('User &&tool_administer_schema. altered');
EXCEPTION
  WHEN OTHERS THEN
    SYS.DBMS_OUTPUT.PUT_LINE('User &&tool_administer_schema. could not be altered. '||SQLERRM);
END;
/

UNDEFINE enter_tool_password re_enter_password
SET ECHO ON TERM OFF;

/* ---------------------------------------------------------------------- */

REM
REM TRCA_USER_ROLE setup
REM

DECLARE
  my_count INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO my_count
    FROM sys.dba_roles
   WHERE role = '&&role_name.';
  IF my_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE ROLE &&role_name.';
  END IF;
END;
/

/* ---------------------------------------------------------------------- */

REM
REM System and Role privileges for TRCANLZR
REM

GRANT CREATE SESSION        TO &&tool_repository_schema.;
GRANT &&role_name.          TO &&tool_repository_schema.;

/* ---------------------------------------------------------------------- */

REM
REM System and Role privileges for TRCADMIN
REM

GRANT ALTER  SESSION        TO &&tool_administer_schema.;
GRANT CREATE SESSION        TO &&tool_administer_schema.;
GRANT SELECT ANY DICTIONARY TO &&tool_administer_schema.;
GRANT SELECT_CATALOG_ROLE   TO &&tool_administer_schema.;

-- ANALYZE ANY needed to avoid: gather_table_stats: trca$_tool_execution ORA-20000: Unable to analyze TABLE "TRCANLZR"."TRCA$_TOOL_EXECUTION", insufficient privileges or does not exist
GRANT ANALYZE ANY           TO &&tool_administer_schema.;

--GRANT CREATE PROCEDURE      TO &&tool_administer_schema.;
--GRANT CREATE SEQUENCE       TO &&tool_administer_schema.;
--GRANT CREATE TABLE          TO &&tool_administer_schema.;
--GRANT CREATE VIEW           TO &&tool_administer_schema.;

/* ---------------------------------------------------------------------- */

REM
REM Utilities privileges for TRCADMIN
REM

DECLARE
  PROCEDURE grant_execute (
    p_owner   IN VARCHAR2,
    p_package IN VARCHAR2 )
  IS
    my_count INTEGER;

  BEGIN
    SELECT COUNT(*)
      INTO my_count
      FROM sys.dba_tab_privs
     WHERE owner      = UPPER(p_owner)
       AND table_name = UPPER(p_package)
       AND privilege  = 'EXECUTE'
       AND grantee   IN ('PUBLIC', '&&tool_administer_schema.');

     IF my_count = 0 THEN
       EXECUTE IMMEDIATE 'GRANT EXECUTE ON '||p_owner||'.'||p_package||' TO &&tool_administer_schema.';
       SYS.DBMS_OUTPUT.PUT_LINE('GRANT EXECUTE ON '||p_owner||'.'||p_package||' SUCCEEDED.');
     ELSE
       SYS.DBMS_OUTPUT.PUT_LINE('GRANT EXECUTE ON '||p_owner||'.'||p_package||' SKIPPED.');
     END IF;
  EXCEPTION
    WHEN OTHERS THEN
      SYS.DBMS_OUTPUT.PUT_LINE('GRANT EXECUTE ON '||p_owner||'.'||p_package||' FAILED: '||SQLERRM);
  END grant_execute;
BEGIN
  grant_execute('sys', 'dbms_lob');
  grant_execute('sys', 'dbms_random');
  grant_execute('sys', 'dbms_space_admin');
  grant_execute('sys', 'dbms_stats');
  grant_execute('sys', 'utl_file');
  grant_execute('sys', 'utl_raw');
END;
/

/* ---------------------------------------------------------------------- */

SET ECHO OFF TERM ON;
PRO
PRO Set up TRCANLZR temporary and default tablespaces;
PRO
PRO Below are the list of online tablespaces in this database.
PRO Decide which tablespace you wish to create the TRCANLZR tables
PRO and indexes.  This will also be the TRCANLZR user default tablespace.
PRO
PRO Specifying the SYSTEM tablespace will result in the installation
PRO FAILING, as using SYSTEM for tools data is not supported.
PRO
PRO Wait...
PRO

WITH f AS (
        SELECT tablespace_name, NVL(ROUND(SUM(bytes)/1024/1024), 0) free_space_mb
          FROM (SELECT tablespace_name, SUM( bytes ) bytes 
		          FROM sys.dba_free_space 
				 GROUP BY tablespace_name
                UNION ALL
                select tablespace_name , sum ( maxbytes - bytes ) bytes from dba_data_files where  maxbytes - bytes > 0 group by tablespace_name )
        group by tablespace_name)
SELECT t.tablespace_name, f.free_space_mb
  FROM sys.dba_tablespaces t, f
WHERE t.tablespace_name NOT IN ('SYSTEM', 'SYSAUX')
   AND t.status = 'ONLINE'
   AND t.contents = 'PERMANENT'
   AND t.tablespace_name = f.tablespace_name
   AND f.free_space_mb > 50
ORDER BY f.free_space_mb;

PRO
PRO Above is the list of online tablespaces in this database.
PRO Decide which tablespace you wish to create the TRCANLZR tables
PRO and indexes.  This will also be the TRCANLZR user default tablespace.
PRO
PRO Specifying the SYSTEM tablespace will result in the installation
PRO FAILING, as using SYSTEM for tools data is not supported.
PRO
PRO Tablespace name is case sensitive.
PRO

ACC default_tablespace PROMPT 'Default tablespace [&&prior_default_tablespace.]: ';

SET TERM OFF;
SELECT TRIM(NVL('&&default_tablespace.', '&&prior_default_tablespace.')) default_tablespace FROM DUAL;
SET TERM ON;

BEGIN
  IF UPPER('&&default_tablespace.') IN ('SYSTEM', 'SYSAUX') THEN
    RAISE_APPLICATION_ERROR(-20104, 'Install failed - SYSTEM/SYSAUX tablespace specified for DEFAULT tablespace');
  END IF;
END;
/

PRO
PRO Choose the TRCANLZR user temporary tablespace.
PRO
PRO Specifying the SYSTEM tablespace will result in the installation
PRO FAILING, as using SYSTEM for the temporary tablespace is not recommended.
PRO
PRO Wait...
PRO

SET SERVEROUT ON SIZE 1000000
DECLARE
  TYPE cursor_type IS REF CURSOR;
  c_temp_table_spaces cursor_type;
  rdbms_release NUMBER;
  my_tablespace VARCHAR2(32767);
  my_sql VARCHAR2(32767);
BEGIN
  SELECT TO_NUMBER(SUBSTR(version, 1, INSTR(version, '.', 1, 2) - 1))
    INTO rdbms_release
    FROM v$instance;

  IF rdbms_release < 10 THEN
    my_sql := 'SELECT tablespace_name '||
              '  FROM sys.dba_tablespaces '||
              ' WHERE tablespace_name NOT IN (''SYSTEM'', ''SYSAUX'') '||
              '   AND status = ''ONLINE'' '||
              '   AND contents = ''TEMPORARY'' '||
              ' ORDER BY tablespace_name ';
  ELSE
    my_sql := 'SELECT t.tablespace_name '||
              '  FROM sys.dba_tablespaces t '||
              ' WHERE t.tablespace_name NOT IN (''SYSTEM'', ''SYSAUX'') '||
              '   AND t.status = ''ONLINE'' '||
              '   AND t.contents = ''TEMPORARY'' '||
              '   AND NOT EXISTS ( '||
              'SELECT NULL '||
              '  FROM sys.dba_tablespace_groups tg '||
              ' WHERE t.tablespace_name = tg.tablespace_name ) '||
              ' UNION '||
              'SELECT tg.group_name '||
              '  FROM sys.dba_tablespaces t, '||
              '       sys.dba_tablespace_groups tg '||
              ' WHERE t.tablespace_name NOT IN (''SYSTEM'', ''SYSAUX'') '||
              '   AND t.status = ''ONLINE'' '||
              '   AND t.contents = ''TEMPORARY'' '||
              '   AND t.tablespace_name = tg.tablespace_name ';
  END IF;

  SYS.DBMS_OUTPUT.PUT_LINE('TABLESPACE_NAME');
  SYS.DBMS_OUTPUT.PUT_LINE('------------------------------');

  OPEN c_temp_table_spaces FOR my_sql;
  LOOP
    FETCH c_temp_table_spaces INTO my_tablespace;
    EXIT WHEN c_temp_table_spaces%NOTFOUND;
    SYS.DBMS_OUTPUT.PUT_LINE(my_tablespace);
  END LOOP;
END;
/

PRO
PRO Tablespace name is case sensitive.
PRO

ACC temporary_tablespace PROMPT 'Temporary tablespace [&&prior_temporary_tablespace.]: ';

SET TERM OFF;
SELECT TRIM(NVL('&&temporary_tablespace.', '&&prior_temporary_tablespace.')) temporary_tablespace FROM DUAL;
SET TERM ON;

BEGIN
  IF UPPER('&&temporary_tablespace.') IN ('SYSTEM', 'SYSAUX') THEN
    RAISE_APPLICATION_ERROR(-20105, 'Install failed - SYSTEM/SYSAUX tablespace specified for TEMPORARY tablespace');
  END IF;
END;
/

DECLARE
  x NUMBER;
BEGIN
  IF UPPER('&&temporary_tablespace.') IN ('SYSTEM', 'SYSAUX') THEN
    RAISE_APPLICATION_ERROR(-20106, 'TRCA installation failed. SYSTEM/SYSAUX tablespace cannot be specified for TEMPORARY tablespace');
  END IF;
  IF UPPER('&&temporary_tablespace.') = 'UNKNOWN' THEN
    RAISE_APPLICATION_ERROR(-20107, 'TRCA installation failed. TEMPORARY tablespace for user &&tool_repository_schema. must be specified');
  END IF;
  SELECT COUNT(*) INTO x FROM sys.dba_tablespaces WHERE tablespace_name = '&&temporary_tablespace.';
  IF x = 0 THEN
    SELECT COUNT(*) INTO x FROM sys.dba_tablespace_groups WHERE group_name = '&&temporary_tablespace.';
    IF x = 0 THEN
      RAISE_APPLICATION_ERROR(-20108, 'TRCA installation failed. TEMPORARY tablespace does not exist');
    END IF;
  END IF;
END;
/

SET ECHO ON TERM OFF;

/* ---------------------------------------------------------------------- */

REM
REM Setup default tablespace for user SQLTXPLAIN
REM

ALTER USER &&tool_repository_schema. DEFAULT TABLESPACE "&&default_tablespace.";
ALTER USER &&tool_repository_schema. QUOTA UNLIMITED ON "&&default_tablespace.";

REM
REM Setup temporary tablespace for user SQLTXPLAIN
REM

ALTER USER &&tool_repository_schema. TEMPORARY TABLESPACE "&&temporary_tablespace.";

/* ---------------------------------------------------------------------- */

REM
REM Setup default tablespace for user SQLTXADMIN
REM

ALTER USER &&tool_administer_schema. DEFAULT TABLESPACE "&&default_tablespace.";
ALTER USER &&tool_administer_schema. QUOTA UNLIMITED ON "&&default_tablespace.";

REM
REM Setup temporary tablespace for user SQLTXPLAIN
REM

ALTER USER &&tool_administer_schema. TEMPORARY TABLESPACE "&&temporary_tablespace.";

/* ---------------------------------------------------------------------- */

SET ECHO OFF TERM ON;

PRO
PRO The main application user of TRCA is the schema
PRO owner that generated the SQL Trace to be analyzed.
PRO For example, on an EBS application you would
PRO enter APPS.
PRO You will not be asked to enter its password.
PRO To add more TRCA users after this installation
PRO is completed simply grant them the TRCA_USER_ROLE
PRO role.
PRO

ACC main_application_schema PROMPT 'Main application user of TRCA: ';

REM Main application user
BEGIN
  IF '&&main_application_schema.' IS NULL THEN
    RAISE_APPLICATION_ERROR(-20110, 'TRCA installation failed. Main application user of TRCA "'||UPPER(TRIM('&&main_application_schema.'))||'" was not specified');
  END IF;
END;
/

SET TERM OFF;
SELECT username application_schema FROM sys.dba_users
WHERE username = NVL(UPPER(TRIM('&&main_application_schema.')), 'SYSTEM');

-- application user executing trca must have this &&role_name.
GRANT &&role_name. TO &&application_schema.;
SET TERM ON;

/* ---------------------------------------------------------------------- */

PRO
PRO Type of TRCA repository
PRO
PRO Create TRCA repository as Temporary or Permanent objects?
PRO Enter T for Temporary or P for Permanent.
PRO T is recommended and default value.
PRO

ACC temporary_or_permanent PROMPT 'Type of TRCA repository [T]: ';
PRO

/* ---------------------------------------------------------------------- */

UNDEFINE default_tablespace temporary_tablespace
UNDEFINE prior_default_tablespace prior_temporary_tablespace

SET ECHO OFF TERM ON;
PRO
PRO TACUSR completed.
