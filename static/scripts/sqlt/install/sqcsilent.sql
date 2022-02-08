SET ECHO ON TERM OFF;
HOS zip -m SQLT_installation_logs_archive *_sq*.log
HOS zip -m SQLT_installation_logs_archive *_ta*.log
CL SCR;
COL yymmddhh24miss NEW_V yymmddhh24miss NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYMMDDHH24MISS') yymmddhh24miss FROM DUAL;
SPO &&yymmddhh24miss._01_sqcsilent_sqlt.log;
REM
REM $Header: 215187.1 sqcsilent.sql 12.1.160429 2016/04/29 carlos.sierra abel.macias@oracle.com $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra
REM   abel.macias@oracle.com
REM
REM SCRIPT
REM   sqlt/install/sqcsilent.sql
REM
REM DESCRIPTION
REM   Installs the SQLT tool under its own schemas SQLTXPLAIN and
REM   SQLTXADMIN.
REM
REM PRE-REQUISITES
REM   1. Execute first a script like sqlt/install/sqdefparams.sql
REM   2. To install SQLT you must connect INTERNAL(SYS) as SYSDBA.
REM
REM PARAMETERS (from script like sqlt/install/sqdefparams.sql)
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
REM   1. Execute first a script like sqlt/install/sqdefparams.sql
REM   2. Navigate to sqlt/install directory.
REM   3. Start SQL*Plus and connect INTERNAL(SYS) as SYSDBA.
REM   4. Execute script sqcsilent.sql using parameters from
REM      script similar to sqlt/install/sqdefparams.sql.
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqdefparams.sql
REM   SQL> START sqcsilent.sql
REM
REM NOTES
REM   1. For silent installation using inline parameters use
REM      sqlt/install/sqcsilent2.sql
REM   2. For possible errors see all *.log generated files.
REM   3. Trace Analyzer TRCA 224270.1 is also installed.
REM
@@sqcommon1.sql
--160420 new
@@sqplcodetype.sql
SET ECHO OFF TERM OFF;
-- initial validation
@@sqcval0.sql
-- enter installation parameters
--@@sqcparameters.sql (sqcreate.sql)
-- validates all parameters
@@sqcval1.sql
@@sqcval2.sql
@@sqcval3.sql
@@sqcval4.sql
@@sqcval5.sql
@@sqcval6.sql
-- drops TRCA objects owned by SQLTXPLAIN
@@tadobj.sql
-- drops old objects not used by this version of SQLT
@@sqdold.sql
SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
-- creates or recreates user SQLTXPLAIN
@@sqcusr.sql
-- create SQLT and TRCA directories
@@tasqdirset.sql
SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
-- verifies that SQLTXPLAIN can actually read and write files (1st pass)
@@tautltest.sql
--SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
@@squtltest.sql
--SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
-- creates TRCA schema objects owned by SQLTXPLAIN
@@tacobj.sql
SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
-- creates TRCA set of packages owned by SQLTXPLAIN
@@tacpkg.sql
SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
-- creates SQLT schema objects
@@sqcobj.sql
SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
-- seeds configuration parameters and data
@@sqseed.sql
SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
-- creates SQLT set of packages
@@sqcpkg.sql
SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
-- verifies that SQLTXPLAIN can actually read and write files (2nd pass)
@@tautltest.sql
--SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
@@squtltest.sql
--SPO OFF;
HOS zip -m &&tool_name._installation_logs_archive &&yymmddhh24miss._*.log
SET TERM ON;
PRO
PRO SQLT users must be granted &&role_name. before using this tool.
UNDEFINE tool_repository_schema tool_administer_schema role_name temporary_or_permanent pack_license connect_identifier
PRO
PRO SQCSILENT completed. Installation completed successfully.
