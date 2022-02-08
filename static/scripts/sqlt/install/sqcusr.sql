COL yymmddhh24miss NEW_V yymmddhh24miss NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYMMDDHH24MISS') yymmddhh24miss FROM DUAL;
SPO &&yymmddhh24miss._02_sqcusr.log;
SET TERM OFF ECHO ON VER OFF SERVEROUT ON SIZE 1000000;
REM
REM $Header: 215187.1 sqcusr.sql 12.1.160429 2016/04/29 carlos.sierra abel.macias@oracle.com $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM   abel.macias@oracle.com
REM
REM SCRIPT
REM   sqlt/install/sqcusr.sql
REM
REM DESCRIPTION
REM   Creates users SQLTXPLAIN and SQLTXADMIN and the grants they need.
REM
REM PRE-REQUISITES
REM   1. To install SQLT you must connect as SYSDBA.
REM
REM PARAMETERS
REM   1. Connect Identifier. (optional).
REM      Some restricted-access systems may need to specify
REM      a connect identifier like "@PROD".
REM      This optional parameter allows to enter it. Else,
REM      enter nothing and just hit the "Enter" key.
REM   2. SQLTXPLAIN password (required).
REM      It may be case sensitive in some systems.
REM   3. Default tablespace for user SQLTXPLAIN (required).
REM      You will be presented with a list, then you will
REM      have to enter one tablespace name from that list.
REM   4. Temporary tablespace for user SQLTXPLAIN (required).
REM   5. Main application user of SQLT (optional).
REM      This is the user name that will later execute SQLT.
REM      You can add aditional SQLT users by granting them
REM      role SQLT_USER_ROLE after the tool is installed.
REM   6. Do you have a license for the Oracle Diagnostic or
REM      the Oracle Tuning Pack? (required).
REM      This enables or disables access to licensed
REM      features of the these packages. Defaults to Tuning.
REM
REM EXECUTION
REM   1. Navigate to sqlt/install directory.
REM   2. Start SQL*Plus and connect as SYSDBA.
REM   3. Execute script sqcusr.sql
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqcusr.sql
REM
REM NOTES
REM   1. This script is executed automatically by sqcreate.sql
REM   2. For possible errors see sqcusr.log file. Some are expected.
REM
SET ECHO ON TERM OFF;

/*------------------------------------------------------------------*/

REM
REM revoke grants from prior versions of SQLT
REM

-- SQLTXPLAIN no longer needs SQLT_USER_ROLE
REVOKE &&role_name. FROM &&tool_repository_schema.;

-- these roles are no longer needed by SQLT_USER_ROLE
REVOKE ADMINISTER SQL MANAGEMENT OBJECT FROM &&role_name.;
REVOKE CREATE ANY SQL PROFILE FROM &&role_name.;
REVOKE ALTER ANY SQL PROFILE FROM &&role_name.;
REVOKE DROP ANY SQL PROFILE FROM &&role_name.;

-- these privileges are no longer needed by SQLT_USER_ROLE
REVOKE EXECUTE ON sys.dbms_workload_repository FROM &&role_name.;

-- now SQLTXADMIN should have some grants but not SQLTXPLAIN
REVOKE ADMINISTER SQL MANAGEMENT OBJECT FROM &&tool_repository_schema.;
REVOKE ADMINISTER SQL TUNING SET        FROM &&tool_repository_schema.;
REVOKE ADVISOR                          FROM &&tool_repository_schema.;
REVOKE ALTER ANY SQL PROFILE            FROM &&tool_repository_schema.;
REVOKE ALTER SESSION                    FROM &&tool_repository_schema.;
REVOKE ANALYZE ANY                      FROM &&tool_repository_schema.;
REVOKE ANALYZE ANY DICTIONARY           FROM &&tool_repository_schema.;
REVOKE CREATE ANY SQL PROFILE           FROM &&tool_repository_schema.;
REVOKE CREATE JOB                       FROM &&tool_repository_schema.;
REVOKE CREATE PROCEDURE                 FROM &&tool_repository_schema.;
REVOKE CREATE SEQUENCE                  FROM &&tool_repository_schema.;
REVOKE CREATE TYPE                      FROM &&tool_repository_schema.;
REVOKE CREATE VIEW                      FROM &&tool_repository_schema.;
REVOKE DROP ANY SQL PROFILE             FROM &&tool_repository_schema.;
REVOKE EXECUTE_CATALOG_ROLE             FROM &&tool_repository_schema.;
REVOKE GATHER_SYSTEM_STATISTICS         FROM &&tool_repository_schema.;
REVOKE SELECT ANY DICTIONARY            FROM &&tool_repository_schema.;
REVOKE SELECT_CATALOG_ROLE              FROM &&tool_repository_schema.;

-- no longer needed
REVOKE EXECUTE ctxsys.ctx_report    FROM &&tool_repository_schema.;
REVOKE EXECUTE sys.dbms_outln       FROM &&tool_repository_schema.;
REVOKE EXECUTE sys.dbms_lob         FROM &&tool_repository_schema.;
REVOKE EXECUTE sys.dbms_random      FROM &&tool_repository_schema.;
REVOKE EXECUTE sys.dbms_space_admin FROM &&tool_repository_schema.;
REVOKE EXECUTE sys.dbms_stats       FROM &&tool_repository_schema.;
REVOKE EXECUTE sys.utl_raw          FROM &&tool_repository_schema.;
REVOKE EXECUTE sys.utl_file         FROM &&tool_repository_schema.;

-- wri$ view
REVOKE SELECT ON sys.wri$_optstat_aux_history      FROM &&tool_repository_schema.;
REVOKE SELECT ON sys.optstat_hist_control$      FROM &&tool_repository_schema.;

-- opstats
PRINT rdbms_release;
BEGIN
  IF :rdbms_release >= 11 THEN
    EXECUTE IMMEDIATE 'REVOKE SELECT ON sys.optstat_user_prefs$ FROM &&tool_repository_schema.';
  END IF;
END;
/

-- stored outlines
REVOKE SELECT ON outln.ol$      FROM &&tool_repository_schema.;
REVOKE SELECT ON outln.ol$hints FROM &&tool_repository_schema.;
REVOKE SELECT ON outln.ol$nodes FROM &&tool_repository_schema.;

-- x$ fixed objects
REVOKE SELECT ON sys.x_$ktfbue FROM &&tool_repository_schema.;

-- EBS
BEGIN
  EXECUTE IMMEDIATE 'REVOKE SELECT ON applsys.fnd_product_groups FROM &&tool_repository_schema.';
EXCEPTION
  WHEN OTHERS THEN
    SYS.DBMS_OUTPUT.PUT_LINE('Not an EBS system or grant missing '||SQLERRM);
END;
/

/*------------------------------------------------------------------*/

REM
REM Creating SQLTXPLAIN user
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

/*------------------------------------------------------------------*/

REM
REM Creating SQLTXADMIN user
REM

BEGIN
  --SYS.DBMS_RANDOM.SEED('&&enter_tool_password.');
  EXECUTE IMMEDIATE('CREATE USER &&tool_administer_schema. IDENTIFIED BY "&&enter_tool_password." PASSWORD EXPIRE ACCOUNT LOCK');
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

/*------------------------------------------------------------------*/

REM
REM Setup default tablespace for user SQLTXPLAIN
REM

ALTER USER &&tool_repository_schema. DEFAULT TABLESPACE "&&default_tablespace.";
ALTER USER &&tool_repository_schema. QUOTA UNLIMITED ON "&&default_tablespace.";

REM
REM Setup temporary tablespace for user SQLTXPLAIN
REM

ALTER USER &&tool_repository_schema. TEMPORARY TABLESPACE "&&temporary_tablespace.";

/*------------------------------------------------------------------*/

REM
REM Setup default tablespace for user SQLTXADMIN
REM

ALTER USER &&tool_administer_schema. DEFAULT TABLESPACE "&&default_tablespace.";
ALTER USER &&tool_administer_schema. QUOTA UNLIMITED ON "&&default_tablespace.";

REM
REM Setup temporary tablespace for user SQLTXPLAIN
REM

ALTER USER &&tool_administer_schema. TEMPORARY TABLESPACE "&&temporary_tablespace.";

/*------------------------------------------------------------------*/

REM
REM SQLT_USER_ROLE setup
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

-- needed to invoke sql tuning advisor and dbms_advisor.get_task_report
GRANT ADVISOR TO &&role_name.;

-- needed to invoke dbms_metadata from pl/sql and also by SYS.DBMS_SQLDIAG.EXPORT_SQL_TESTCASE
GRANT SELECT_CATALOG_ROLE TO &&role_name.;

-- application user executing sqlt must have this &&role_name.
GRANT &&role_name. TO &&application_schema.;

/*------------------------------------------------------------------*/

REM
REM Utilities privileges for SQLT_USER_ROLE
REM

GRANT EXECUTE ON sys.dbms_metadata TO &&role_name.;
GRANT EXECUTE ON ctxsys.ctx_report TO &&role_name.;

/*------------------------------------------------------------------*/

REM
REM System and Role privileges for SQLTXPLAIN
REM

GRANT CREATE SESSION                TO &&tool_repository_schema.;

-- needed by imp
GRANT CREATE TABLE                  TO &&tool_repository_schema.;

--GRANT &&role_name.                  TO &&tool_administer_schema.;

/*------------------------------------------------------------------*/

REM
REM System and Role privileges for SQLTXADMIN
REM

GRANT ADMINISTER SQL TUNING SET     TO &&tool_administer_schema.;
GRANT ADVISOR                       TO &&tool_administer_schema.;
GRANT ALTER SESSION                 TO &&tool_administer_schema.;
--GRANT CREATE SESSION                TO &&tool_administer_schema.;
GRANT SELECT ANY DICTIONARY         TO &&tool_administer_schema.;
GRANT SELECT_CATALOG_ROLE           TO &&tool_administer_schema.;

-- ANALYZE ANY needed to avoid: export table stats ORA-20000: TABLE "QTUNE"."CUSTOMER" does not exist or insufficient privileges
GRANT ANALYZE ANY                   TO &&tool_administer_schema.;

-- ANALYZE ANY DICTIONARY needed to avoid: export dictionary stats ORA-20000: Insufficient privileges to analyze an object within the database
GRANT ANALYZE ANY DICTIONARY        TO &&tool_administer_schema.;


PRINT rdbms_release;
BEGIN
  IF :rdbms_release >= 11 THEN
    -- needed to be able to pack baselines and avoid
    -- ORA-38171: Insufficient privileges for SQL management object operation
    -- d:BEGIN :plans := SYS.DBMS_SPM.PACK_STGTAB_BASELINE(table_name => :table_name, table_owner => :table_owner, sql_handle => :sql_handle); END;
    EXECUTE IMMEDIATE 'GRANT ADMINISTER SQL MANAGEMENT OBJECT TO &&tool_administer_schema.';
  END IF;
END;
/

--GRANT CREATE PROCEDURE              TO &&tool_administer_schema.;
--GRANT CREATE SEQUENCE               TO &&tool_administer_schema.;
--GRANT CREATE TABLE                  TO &&tool_administer_schema.;
--GRANT CREATE VIEW                   TO &&tool_administer_schema.;

/*------------------------------------------------------------------*/

REM
REM EBS
REM

BEGIN
  EXECUTE IMMEDIATE 'GRANT SELECT ON applsys.fnd_product_groups TO &&tool_administer_schema.';
EXCEPTION
  WHEN OTHERS THEN
    SYS.DBMS_OUTPUT.PUT_LINE('Not an EBS system '||SQLERRM);
END;
/

/*------------------------------------------------------------------*/

REM
REM Utilities privileges for SQLTXADMIN
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
  --grant_execute('sys', 'dbms_outln');
  grant_execute('sys', 'outln_pkg');
  grant_execute('sys', 'dbms_random');
  grant_execute('sys', 'dbms_space_admin');
  grant_execute('sys', 'dbms_stats');
  grant_execute('sys', 'dbms_workload_repository');
  grant_execute('sys', 'utl_file');
  grant_execute('sys', 'utl_raw');
  grant_execute('sys', 'dbms_perf'); -- 160403
END;
/

/*------------------------------------------------------------------*/

REM
REM WRI$ views
REM

GRANT SELECT ON sys.wri$_optstat_aux_history      TO   &&tool_administer_schema.;

/*------------------------------------------------------------------*/

REM
REM SEGS tables
REM

GRANT SELECT ON sys.sys_dba_segs   TO   &&tool_administer_schema.;

/*------------------------------------------------------------------*/

REM
REM OPTSTAT tables
REM

GRANT SELECT ON sys.optstat_hist_control$      TO   &&tool_administer_schema.;

PRINT rdbms_release;
BEGIN
  IF :rdbms_release >= 11 THEN
    EXECUTE IMMEDIATE 'GRANT SELECT ON sys.optstat_user_prefs$ TO &&tool_administer_schema.';
  END IF;
END;
/

/* ---------------------------------------------------------------------- */

REM
REM stored outlines tables
REM

GRANT SELECT ON outln.ol$      TO &&tool_administer_schema.;
GRANT SELECT ON outln.ol$hints TO &&tool_administer_schema.;
GRANT SELECT ON outln.ol$nodes TO &&tool_administer_schema.;

/*------------------------------------------------------------------*/

UNDEFINE main_application_schema application_schema
UNDEFINE default_tablespace temporary_tablespace
UNDEFINE prior_default_tablespace prior_temporary_tablespace
SET ECHO OFF TERM ON;
PRO
PRO SQCUSR completed. Some errors are expected.
