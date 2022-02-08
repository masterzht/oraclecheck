SET ECHO ON TERM OFF NUMF "";
REM
REM $Header: 224270.1 tadrop.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   tadrop.sql
REM
REM DESCRIPTION
REM   This script uninstalls a prior version of the TRCANLZR tool
REM   droping first existing TRCANLZR objects, then the TRCANLZR
REM   user itself.
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
REM   3. Execute script tadrop.sql
REM
REM EXAMPLE
REM   # cd trca/install
REM   # sqlplus /nolog
REM   SQL> connect / as sysdba
REM   SQL> start tadrop.sql
REM
REM NOTES
REM   1. This script is executed automatically by tacreate.sql
REM
@@tacommon1.sql
SET ECHO OFF TERM OFF;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
BEGIN
  IF USER <> 'SYS' THEN
    RAISE_APPLICATION_ERROR(-20100, 'Drop script failed - tadrop.sql should be executed connected as SYS, not as '||USER);
  END IF;
END;
/
WHENEVER SQLERROR CONTINUE;
SET TERM ON;
PRO Uninstalling TRCA, please wait
SET TERM OFF;

@@tadobj.sql
@@tadusr.sql

PRO TADROP completed.
