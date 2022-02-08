COL yymmddhh24miss NEW_V yymmddhh24miss NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYMMDDHH24MISS') yymmddhh24miss FROM DUAL;
SPO &&yymmddhh24miss._00_sqdrop.log;
SET TERM OFF ECHO ON;
REM
REM $Header: 215187.1 sqdrop.sql 11.4.5.7 2013/04/05 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/install/sqdrop.sql
REM
REM DESCRIPTION
REM   Uninstalls the SQLT tool and drops its schema owner SQLTXPLAIN.
REM
REM PRE-REQUISITES
REM   1. To uninstall SQLT you must connect as SYSDBA.
REM
REM PARAMETERS
REM   1. None
REM
REM EXECUTION
REM   1. Navigate to sqlt/install directory.
REM   2. Start SQL*Plus connecting as SYSDBA.
REM   3. Execute script sqdrop.sql.
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqdrop.sql
REM
REM NOTES
REM   1. You can reinstall SQLT after this script completes.
REM
@@sqcommon1.sql
SET ECHO OFF TERM ON;
PRO ... uninstalling SQLT, please wait
SET TERM OFF;
-- drops TRCA objects owned by SQLT
@@tadobj.sql
-- drops old objects not used by this version of SQLT
@@sqdold.sql
-- drops objects used by this version of SQLT
@@sqdobj.sql
-- drops SQLT role and user
@@sqdusr.sql
SET ECHO OFF;
UNDEFINE tool_repository_schema
PRO
PRO SQDROP completed.
