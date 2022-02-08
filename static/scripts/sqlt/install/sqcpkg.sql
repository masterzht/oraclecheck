SET ECHO ON TERM OFF VER OFF;
COL yymmddhh24miss NEW_V yymmddhh24miss NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYMMDDHH24MISS') yymmddhh24miss FROM DUAL;
SPO &&yymmddhh24miss._08_sqcpkg.log;
REM
REM $Header: 215187.1 sqcpkg.sql 11.4.5.8 2013/05/10 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/install/sqcpkg.sql
REM
REM DESCRIPTION
REM   Creates all SQLT packages owned by user SQLTXADMIN
REM   SQLT$I Invoker rights APIs (AUTHID CURRENT_USER)
REM   SQLT$D Diagnostics data collection
REM   SQLT$A Auxiliary APIs
REM   SQLT$S CBO Statistics APIs
REM   SQLT$T Transformation of diagnostics data
REM   SQLT$H Health-Checks
REM   SQLT$M Main report
REM   SQLT$R Reports and APIs for reporting
REM   SQLT$C Compare report
REM   SQLT$E External APIs
REM
REM PRE-REQUISITES
REM   1. To install SQLT you must connect INTERNAL(SYS) as SYSDBA.
REM
REM PARAMETERS
REM   1. None
REM
REM EXECUTION
REM   1. Navigate to sqlt/install directory
REM   2. Start SQL*Plus connecting INTERNAL(SYS) as SYSDBA
REM   3. Execute this script sqcpkg.sql
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqcpkg.sql
REM
REM NOTES
REM   1. This script is executed automatically by sqcreate.sql
REM   2. For possible errors see sqcpkg.log file
REM
@@sqcommon1.sql
--
/* - sqlt packages - */
WHENEVER SQLERROR CONTINUE;
SET TERM ON ECHO OFF;
PRO ... dropping packages for SQLT
SET TERM OFF ECHO ON;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$a;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$c;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$d;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$e;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$h;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$i;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$m;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$s;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$r;
DROP PACKAGE BODY &&tool_administer_schema..sqlt$t;
DROP PACKAGE      &&tool_administer_schema..sqlt$a;
DROP PACKAGE      &&tool_administer_schema..sqlt$c;
DROP PACKAGE      &&tool_administer_schema..sqlt$d;
DROP PACKAGE      &&tool_administer_schema..sqlt$e;
DROP PACKAGE      &&tool_administer_schema..sqlt$h;
DROP PACKAGE      &&tool_administer_schema..sqlt$i;
DROP PACKAGE      &&tool_administer_schema..sqlt$m;
DROP PACKAGE      &&tool_administer_schema..sqlt$r;
DROP PACKAGE      &&tool_administer_schema..sqlt$s;
DROP PACKAGE      &&tool_administer_schema..sqlt$t;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
--
SET TERM ON ECHO OFF;
PRO ... creating package specs for SQLT$A
SET TERM OFF ECHO ON;
@@sqcpkga.pks
--
SET TERM ON ECHO OFF;
PRO ... creating package specs for SQLT$C
SET TERM OFF ECHO ON;
@@sqcpkgc.pks
--
SET TERM ON ECHO OFF;
PRO ... creating package specs for SQLT$D
SET TERM OFF ECHO ON;
@@sqcpkgd.pks
--
SET TERM ON ECHO OFF;
PRO ... creating package specs for SQLT$E
SET TERM OFF ECHO ON;
@@sqcpkge.pks
--
SET TERM ON ECHO OFF;
PRO ... creating package specs for SQLT$H
SET TERM OFF ECHO ON;
@@sqcpkgh.pks
--
SET TERM ON ECHO OFF;
PRO ... creating package specs for SQLT$I
SET TERM OFF ECHO ON;
@@sqcpkgi.pks
--
SET TERM ON ECHO OFF;
PRO ... creating package specs for SQLT$M
SET TERM OFF ECHO ON;
@@sqcpkgm.pks
--
SET TERM ON ECHO OFF;
PRO ... creating package specs for SQLT$R
SET TERM OFF ECHO ON;
@@sqcpkgr.pks
--
SET TERM ON ECHO OFF;
PRO ... creating package specs for SQLT$S
SET TERM OFF ECHO ON;
@@sqcpkgs.pks
--
SET TERM ON ECHO OFF;
PRO ... creating package specs for SQLT$T
SET TERM OFF ECHO ON;
@@sqcpkgt.pks
--
SET TERM ON ECHO OFF;
PRO ... creating views
SET TERM OFF ECHO ON;
WHENEVER SQLERROR CONTINUE;
@@sqcvw.sql
WHENEVER SQLERROR EXIT SQL.SQLCODE;
--
SET TERM ON ECHO OFF;
PRO ... creating package body for SQLT$A
SET TERM OFF ECHO ON;
@@sqcpkga.pkb
--
SET TERM ON ECHO OFF;
PRO ... creating package body for SQLT$C
SET TERM OFF ECHO ON;
@@sqcpkgc.pkb
--
SET TERM ON ECHO OFF;
PRO ... creating package body for SQLT$D
SET TERM OFF ECHO ON;
@@sqcpkgd.pkb
--
SET TERM ON ECHO OFF;
PRO ... creating package body for SQLT$E
SET TERM OFF ECHO ON;
@@sqcpkge.pkb
--
SET TERM ON ECHO OFF;
PRO ... creating package body for SQLT$H
SET TERM OFF ECHO ON;
@@sqcpkgh.pkb
--
SET TERM ON ECHO OFF;
PRO ... creating package body for SQLT$I
SET TERM OFF ECHO ON;
@@sqcpkgi.pkb
--
SET TERM ON ECHO OFF;
PRO ... creating package body for SQLT$M
SET TERM OFF ECHO ON;
@@sqcpkgm.pkb
--
SET TERM ON ECHO OFF;
PRO ... creating package body for SQLT$R
SET TERM OFF ECHO ON;
@@sqcpkgr.pkb
--
SET TERM ON ECHO OFF;
PRO ... creating package body for SQLT$S
SET TERM OFF ECHO ON;
@@sqcpkgs.pkb
--
SET TERM ON ECHO OFF;
PRO ... creating package body for SQLT$T
SET TERM OFF ECHO ON;
@@sqcpkgt.pkb
--
SET TERM ON ECHO OFF;
PRO
PRO Creating Grants on Packages ...
PRO
SET TERM OFF ECHO ON;
--
GRANT EXECUTE ON &&tool_administer_schema..sqlt$a TO &&role_name.;
GRANT EXECUTE ON &&tool_administer_schema..sqlt$c TO &&role_name.;
GRANT EXECUTE ON &&tool_administer_schema..sqlt$d TO &&role_name.;
GRANT EXECUTE ON &&tool_administer_schema..sqlt$e TO &&role_name.;
GRANT EXECUTE ON &&tool_administer_schema..sqlt$h TO &&role_name.;
GRANT EXECUTE ON &&tool_administer_schema..sqlt$i TO &&role_name.;
GRANT EXECUTE ON &&tool_administer_schema..sqlt$m TO &&role_name.;
GRANT EXECUTE ON &&tool_administer_schema..sqlt$r TO &&role_name.;
GRANT EXECUTE ON &&tool_administer_schema..sqlt$s TO &&role_name.;
GRANT EXECUTE ON &&tool_administer_schema..sqlt$t TO &&role_name.;
--
-- these synonyms are created so versions of SQLT TC prior to 11.4.5 can be implemented into a post 11.4.5 version of SQLT (restore script).
-- also needed to set SQLT parameters using old syntax
CREATE OR REPLACE SYNONYM &&tool_repository_schema..sqlt$a FOR &&tool_administer_schema..sqlt$a;
CREATE OR REPLACE SYNONYM &&tool_repository_schema..sqlt$c FOR &&tool_administer_schema..sqlt$c;
CREATE OR REPLACE SYNONYM &&tool_repository_schema..sqlt$d FOR &&tool_administer_schema..sqlt$d;
CREATE OR REPLACE SYNONYM &&tool_repository_schema..sqlt$e FOR &&tool_administer_schema..sqlt$e;
CREATE OR REPLACE SYNONYM &&tool_repository_schema..sqlt$h FOR &&tool_administer_schema..sqlt$h;
CREATE OR REPLACE SYNONYM &&tool_repository_schema..sqlt$i FOR &&tool_administer_schema..sqlt$i;
CREATE OR REPLACE SYNONYM &&tool_repository_schema..sqlt$m FOR &&tool_administer_schema..sqlt$m;
CREATE OR REPLACE SYNONYM &&tool_repository_schema..sqlt$r FOR &&tool_administer_schema..sqlt$r;
CREATE OR REPLACE SYNONYM &&tool_repository_schema..sqlt$s FOR &&tool_administer_schema..sqlt$s;
CREATE OR REPLACE SYNONYM &&tool_repository_schema..sqlt$t FOR &&tool_administer_schema..sqlt$t;
--
SET ECHO OFF PAGES 24;
COL libraries FOR A75;
SET TERM ON FEED OFF;
SELECT column_value libraries FROM TABLE(&&tool_administer_schema..sqlt$r.libraries_versions);
DECLARE
  my_count INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO my_count
    FROM dba_objects
   WHERE owner = '&&tool_administer_schema.'
     AND object_type IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION')
     AND status = 'INVALID';
  IF my_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20110, 'Invalid libraries: '||my_count||'. Review sqcpkg.log.');
  END IF;
END;
/
SET FEED 6;
SET ECHO OFF;
--
PRO
PRO  Deleting CBO statistics for SQLTXPLAIN objects ...
PRO
EXEC &&tool_administer_schema..sqlt$a.delete_sqltxplain_stats;
--
WHENEVER SQLERROR CONTINUE;
PRO
PRO SQCPKG completed.
