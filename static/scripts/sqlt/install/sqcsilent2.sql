SET ECHO ON TERM OFF;
REM
REM $Header: 215187.1 sqcsilent2.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/install/sqcsilent2.sql
REM
REM DESCRIPTION
REM   Installs the SQLT tool under its own schemas SQLTXPLAIN and
REM   SQLTXADMIN.
REM
REM PRE-REQUISITES
REM   1. To install SQLT you must connect INTERNAL(SYS) as SYSDBA.
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
REM   1. Navigate to sqlt/install directory.
REM   2. Start SQL*Plus and connect INTERNAL(SYS) as SYSDBA.
REM   3. Execute script sqcsilent2.sql passing inline parameters
REM      as shown in example below..
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqcsilent2.sql '' sqltxplain USERS TEMP '' T
REM
REM NOTES
REM   1. For possible errors see all *.log generated files.
REM   2. Trace Analyzer TRCA 224270.1 is also installed.
REM
DEF connect_identifier      = '&1';
DEF enter_tool_password     = '&2';
DEF re_enter_password       = '&2';
DEF default_tablespace      = '&3';
DEF temporary_tablespace    = '&4';
DEF main_application_schema = '&5';
DEF pack_license            = '&6';
PRO
@@sqcsilent.sql
PRO
PRO SQCSILENT2 completed. Installation completed successfully.
