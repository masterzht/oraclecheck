SET ECHO ON ESC OFF TERM OFF SERVEROUT ON SIZE 1000000;
COL yymmddhh24miss NEW_V yymmddhh24miss NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYMMDDHH24MISS') yymmddhh24miss FROM DUAL;
SPO &&yymmddhh24miss._07_sqseed.log;
REM
REM $Header: 215187.1 sqseed.sql 19.1.200226 2020/02/26 Stelios.Charalambides Carlos Sierrs Mauro Pagano Abel Macias $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   Stelios Charalambides
REM   Carlos Sierra
REM   Mauro Pagano
REM   Abel Macias
REM
REM SCRIPT
REM   sqlt/install/sqseed.sql
REM
REM DESCRIPTION
REM   Seeds configuration parameters and values.
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
REM   3. Execute this script sqseed.sql
REM
REM EXAMPLE
REM   # cd sqlt/install
REM   # sqlplus / as sysdba
REM   SQL> START sqseed.sql
REM
REM NOTES
REM   1. This script is executed automatically by sqcreate.sql
REM   2. For possible errors see sqseed.log file
REM
@@sqcommon1.sql

SET DEF ON ECHO OFF;
SET DEF ~;

DECLARE
  par_rec ~~tool_repository_schema..sqli$_parameter%ROWTYPE;

  PROCEDURE ins
  IS
    l_count INTEGER;
  BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM ~~tool_repository_schema..sqli$_parameter
     WHERE name = par_rec.name;

    IF l_count = 0 THEN
      INSERT INTO ~~tool_repository_schema..sqli$_parameter VALUES par_rec;
      DBMS_OUTPUT.PUT_LINE('Parameter '||par_rec.name||' inserted.');
    ELSE
      DBMS_OUTPUT.PUT_LINE('Parameter '||par_rec.name||' already exists.');
    END IF;
    par_rec := NULL;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Parameter '||par_rec.name||' already exists.');
      par_rec := NULL;
  END ins;

  PROCEDURE del
  IS
  BEGIN
    DELETE ~~tool_repository_schema..sqli$_parameter WHERE name = par_rec.name;
    DBMS_OUTPUT.PUT_LINE('Parameter '||par_rec.name||' deleted.');
  END del;
BEGIN
  par_rec.name              := 'tool_version';
  par_rec.type              := 'C';
  par_rec.value             := '~~tool_version.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'N';
  del; ins;

  par_rec.name              := 'tool_date';
  par_rec.type              := 'C';
  par_rec.value             := '~~tool_date.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'N';
  del; ins;

  par_rec.name              := 'install_date';
  par_rec.type              := 'C';
  par_rec.value             := TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS');
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'N';
  del; ins;

  par_rec.name              := 'connect_identifier';
  par_rec.type              := 'C';
  par_rec.description       := 'Optional Connect Identifier (as per Oracle Net). This is used during export of SQLT repository. Include "@" symbol, ie. @PROD.<br>You can also set this parameter to NULL.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.instructions      := 'Null, or @connect_identifier';
  del; ins;

  par_rec.name              := 'skip_metadata_for_object';
  par_rec.type              := 'C';
  par_rec.description       := 'This case-sensitive parameter allows to specify an object name to be skipped from metadata extraction. It is used in cases where SYS.DBMS_METADATA errors with ORA-7445.<br>You can specify a full or a partial object name to be skipped (examples: "CUSTOMERS" or "CUSTOMER%" or "CUST%" or "%").<br>To find object name where metadata errored out you can use: SELECT * FROM sqlt$_log WHERE statement_id = 99999 ORDER BY line_id;<br>You have to replace 99999 with correct statement_id.<br>To actually fix error behind ORA-7445, you can use alert.log and trace referenced by it.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.instructions      := 'Null, or full/partial object name';
  del; ins;

  par_rec.name              := 'traces_directory_path';
  par_rec.type              := 'C';
  par_rec.description       := 'This case-sensitive parameter allows to specify the directory path for trace files, other than the one specified by initialization parameter user_dump_dest.<br>You can specify any valid directory path and SQLT will use this as a source to TKPROF commands executed automatically withing SQLT.<br>For example: /u01/app/oracle/diag/rdbms/v1123/V1123/trace/';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.instructions      := 'Null, valid directory path on server';
  ins;

  par_rec.name              := 'predicates_in_plan';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Predicates in plan can be eliminated as a workaround to bug 6356566.<br>SQLT detects an ORA-07445 and disables predicates in next execution.<br>If this parameter has a value of E or N, then you may have bug 6356566 in your system. <br>You may want to apply a fix for bug 6356566, then reset this parameter to its default value.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'N, Y, E';
  par_rec.value1            := 'N';
  par_rec.value2            := 'Y';
  par_rec.value3            := 'E';
  del; ins;

  par_rec.name              := 'generate_10053_xtract';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Generation of 10053 using DBMS_SQLDIAG.DUMP_TRACE on XTRACT can be eliminated as a workaround to a disconnect ORA-07445 on SYS.DBMS_SQLTUNE_INTERNAL.<br>SQLT detects an ORA-07445 and disables the call to DBMS_SQLDIAG.DUMP_TRACE (and SYS.DBMS_SQLTUNE_INTERNAL) in next execution.<br>If this parameter has a value of E or N, then you may have a low-impact bug in your system.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'N, Y, E';
  par_rec.value1            := 'N';
  par_rec.value2            := 'Y';
  par_rec.value3            := 'E';
  del; ins;

  par_rec.name              := 'automatic_workload_repository';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Access to the Automatic Workload Repository (AWR) requires a license for the Oracle Diagnostic Pack.<br>If you don''t have it you can set this parameter to ''N''.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'sql_tuning_advisor';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Be aware that using SQL Tuning Advisor (STA) DBMS_SQLTUNE requires a license for the Oracle Tuning Pack.<br>If you don''t have it you can set this parameter to ''N''.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'custom_sql_profile';
  par_rec.type              := 'C';
  par_rec.value             := 'N';
  par_rec.description       := 'Controls if a script with a Custom SQL Profile is generated with every execution of SQLT main methods.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'N';
  par_rec.instructions      := 'N, Y';
  par_rec.value1            := 'N';
  par_rec.value2            := 'Y';
  del; ins;

  par_rec.name              := 'sql_tuning_set';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Generates a SQL Tuning Set for each plan when using XTRACT.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'sql_monitoring';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Be aware that using SQL Monitoring (V$SQL_MONITOR and V$SQL_PLAN_MONITOR) requires a license for the Oracle Tuning Pack.<br>If you don''t have it you can set this parameter to ''N''.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'sql_monitor_reports';
  par_rec.type              := 'N';
  par_rec.value             := '12';
  par_rec.description       := 'Maximum number of SQL Monitor Active reports to generate.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '12';
  par_rec.instructions      := '1-9999';
  par_rec.low_value         := '1';
  par_rec.high_value        := '9999';
  del; ins;

  par_rec.name              := 'awr_reports';
  par_rec.type              := 'N';
  par_rec.value             := '6';
  par_rec.description       := 'Maximum number of AWR reports to generate.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '6';
  par_rec.instructions      := '0-9999';
  par_rec.low_value         := '0';
  par_rec.high_value        := '9999';
  del; ins;

  par_rec.name              := 'addm_reports';
  par_rec.type              := 'N';
  par_rec.value             := '6';
  par_rec.description       := 'Maximum number of ADDM reports to generate.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '6';
  par_rec.instructions      := '0-9999';
  par_rec.low_value         := '0';
  par_rec.high_value        := '9999';
  del; ins;
  
  par_rec.name              := 'ash_reports';
  par_rec.type              := 'N';
  par_rec.value             := '6';
  par_rec.description       := 'Maximum number of ASH reports to generate.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '6';
  par_rec.instructions      := '0-9999';
  par_rec.low_value         := '0';
  par_rec.high_value        := '9999';
  del; ins;  

  par_rec.name              := 'ash_reports_source';
  par_rec.type              := 'C';
  par_rec.value             := 'BOTH';
  par_rec.description       := 'Generate ASH reports from memory (MEM) and/or from active workload repository (AWR).';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'BOTH';
  par_rec.instructions      := 'BOTH, MEM, AWR, NONE';
  par_rec.value1            := 'BOTH';
  par_rec.value2            := 'MEM';
  par_rec.value3            := 'AWR';
  par_rec.value4            := 'NONE';
  del; ins;

  par_rec.name              := 'sqldx_reports_format';
  par_rec.type              := 'C';
  par_rec.value             := 'CSV';
  par_rec.description       := 'SQL Dynamic eXtract (SQLDX) report format.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'BOTH';
  par_rec.instructions      := 'HTML, CSV, BOTH, NONE';
  par_rec.value1            := 'HTML';
  par_rec.value2            := 'CSV';
  par_rec.value3            := 'BOTH';
  par_rec.value4            := 'NONE';
  del; ins;

  par_rec.name              := 'sta_time_limit_secs';
  par_rec.type              := 'N';
  par_rec.value             := '900';
  par_rec.description       := 'STA time limit in seconds. See sql_tuning_advisor.<br>Be aware that using SQL Tuning Advisor (STA) DBMS_SQLTUNE requires a license for the Oracle Tuning Pack.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '900';
  par_rec.instructions      := '15-86400';
  par_rec.low_value         := '15';
  par_rec.high_value        := '86400';
  del; ins;

  par_rec.name              := 'test_case_builder';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := '11g offers the capability to build a test case for a SQL. TCB is implemented using the API DBMS_SQLDIAG.EXPORT_SQL_TESTCASE.<br>SQLT invokes this API whenever possible. When TCB is invoked by SQLT, the parameter exportData gets passed a value of TRUE or FALSE, as per SQLT parameter tcb_export_data.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'tcb_export_data';
  par_rec.type              := 'C';
  par_rec.value             := 'FALSE';
  par_rec.description       := 'Value for parameter exportData on API DBMS_SQLDIAG.EXPORT_SQL_TESTCASE.<br>If value TRUE is passed then TCB creates the Test Case with application data (of the objects referenced in the SQL should be exported).';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'FALSE';
  par_rec.instructions      := 'FALSE, TRUE';
  par_rec.value1            := 'FALSE';
  par_rec.value2            := 'TRUE';
  del; ins;
  
  par_rec.name              := 'tcb_sampling_percent';
  par_rec.type              := 'N';
  par_rec.value             := '100';
  par_rec.description       := 'Value for parameter samplingPercent on API DBMS_SQLDIAG.EXPORT_SQL_TESTCASE.<br>The value is used to determine the percentage of application data TCB creates the Test Case with (of the objects referenced in the SQL should be exported).';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '100';
  par_rec.instructions      := '0-100';
  par_rec.low_value         := '0';
  par_rec.high_value        := '100';
  del; ins;  

  par_rec.name              := 'tcb_export_pkg_body';
  par_rec.type              := 'C';
  par_rec.value             := 'FALSE';
  par_rec.description       := 'Value for parameter exportPkgbody on API DBMS_SQLDIAG.EXPORT_SQL_TESTCASE.<br>If value TRUE is passed then TCB creates the Test Case with package bodies (of the packages referenced in the SQL are exported).';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'FALSE';
  par_rec.instructions      := 'FALSE, TRUE';
  par_rec.value1            := 'FALSE';
  par_rec.value2            := 'TRUE';
  del; ins;

  par_rec.name              := 'tcb_time_limit_secs';
  par_rec.type              := 'N';
  par_rec.value             := '1800';
  par_rec.description       := 'TCB (test case builder) time limit in seconds. See test_case_builder.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '1800';
  par_rec.instructions      := '30-86400';
  par_rec.low_value         := '30';
  par_rec.high_value        := '86400';
  del; ins;

  par_rec.name              := 'c_dba_hist_parameter';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Collects relevant entries out of DBA_HIST_PARAMETER.<br>If "automatic_workload_repository" and "c_dba_hist_parameter" are both set to ''Y'' then SQLT collects relevant rows out of view DBA_HIST_PARAMETER.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'c_inmemory';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Collects information about In-Memory Option';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'c_sesstat_xtract';
  par_rec.type              := 'C';
  par_rec.value             := 'N';
  par_rec.description       := 'Collects GV$SESSTAT information during XTRACT execution looking for other sessions running the same SQL ID.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'N';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;  
  
  par_rec.name              := 'c_cbo_stats_vers_days';
  par_rec.type              := 'N';
  par_rec.value             := '31';
  par_rec.description       := 'Days of CBO statistics versions to be collected. If set to 0 no statistics versions are collected. If set to a value larger than actual stored days, then SQLT collects the whole history. A value of 7 means collect the past 7 days of CBO statistics versions for the schema objects related to given SQL. It includes tables, indexes, partitions, columns and histograms.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '31';
  par_rec.instructions      := '0-999';
  par_rec.low_value         := '0';
  par_rec.high_value        := '999';
  del; ins;

  par_rec.name              := 'c_awr_hist_days';
  par_rec.type              := 'N';
  par_rec.value             := '31';
  par_rec.description       := 'Days of AWR history to be collected. If set to 0 no AWR history is collected. If set to a value larger than actual stored days, then SQLT collects the whole history. A value of 7 means collect the past 7 days of AWR history..';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '31';
  par_rec.instructions      := '0-999';
  par_rec.low_value         := '0';
  par_rec.high_value        := '999';
  del; ins;
  
  par_rec.name              := 'c_ash_hist_days';
  par_rec.type              := 'N';
  par_rec.value             := '31';
  par_rec.description       := 'Days of ASH history to be collected. If set to 0 no ASH history is collected. If set to a value larger than actual stored days, then SQLT collects the whole history. A value of 7 means collect the past 7 days of ASH history..';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '31';
  par_rec.instructions      := '0-999';
  par_rec.low_value         := '0';
  par_rec.high_value        := '999';
  del; ins;

  par_rec.name              := 'trace_analyzer';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'SQLT XECUTE invokes Trace Analyzer - TRCA (Note:224270.1).<br>TRCA analyzes the 10046_10053 trace created by SQLT. It also splits the trace into two stand-alone files 10046 and 10053.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'healthcheck_ndv';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Review if number of distinct values for columns change more than 10% from one statistics gathering to the next.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'healthcheck_endpoints';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Compute histogram endpoints count and check if they change more than 10% from one statistics gathering to the next.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'healthcheck_num_rows';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Review table/partition/subpartition number of rows and check if they change more than 10% from one statistics gathering to the next.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'healthcheck_blevel';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Compute index/partition/subpartition blevel and check if they change more than 10% from one statistics gathering to the next.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'collect_perf_stats';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Collects performance statistics on XECUTE method.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'search_sql_by_sqltext';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'XPLAIN method uses the SQL text to search in memory and AWR for known executions of SQL being analyzed. If prior executions of this SQL text are found, corresponding plans are extracted and reported.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'upload_trace_size_mb';
  par_rec.type              := 'N';
  par_rec.value             := '100';
  par_rec.description       := 'SQLT uploads to its repository traces generated by events 10046 and 10053. This parameter controls the maximum amount of megabytes to upload per trace.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '100';
  par_rec.instructions      := '1-1024';
  par_rec.low_value         := '1';
  par_rec.high_value        := '1024';
  del; ins;

  par_rec.name              := 'sqlt_max_file_size_mb';
  par_rec.type              := 'N';
  par_rec.value             := '200';
  par_rec.description       := 'Maximum size of individual SQLT files in megabytes.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '200';
  par_rec.instructions      := '1-1024';
  par_rec.low_value         := '1';
  par_rec.high_value        := '1024';
  del; ins;

  par_rec.name              := 'distributed_queries';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'SQLT can use DB links referenced by the SQL being aanalyzed. It connects to those remote systems to get 10053 and 10046 traces for the SQL being distrubuted.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'xpand_sql';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'SQLT will expand the views SQL text.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;


  par_rec.name              := 'export_repository';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Methods XTRACT, XECUTE and XPLAIN automatically perform an export of corresponding entries in the SQLT repository.<br>This parameter controls this automatic repository export.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'export_dict_stats';
  par_rec.type              := 'C';
  par_rec.value             := 'N';
  par_rec.description       := 'SQLT export dictionary stats into the repository.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'N';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'export_utility';
  par_rec.type              := 'C';
  par_rec.value             := 'EXP';
  par_rec.description       := 'SQLT repository can be exported automatically using one of two available utilities: traditional export "exp" or data pump "expdp".<br>With this parameter you can specify which of the two should be used by SQLT.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'EXP';
  par_rec.instructions      := 'EXP, EXPDP';
  par_rec.value1            := 'EXP';
  par_rec.value2            := 'EXPDP';
  del; ins;

  par_rec.name              := 'bde_chk_cbo';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'On EBS applications SQLT automatically executes bde_chk_cbo.sql from Note:174605.1.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'validate_user';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Validates that user of main methods has been granted the ~~role_name. or DBA roles; or that user is ~~tool_administer_schema. or SYS.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'refresh_directories';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Controls if SQLT and TRCA directories for UDUMP/BDUMP should be reviewed and refreshed every time SQLT is executed.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'domain_index_metadata';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'This parameter controls if domain index metadata is included in main report and metadata script.<br>If you get an ORA-07445, and alert.log shows error is caused by CTXSYS.CTX_REPORT.CREATE_INDEX_SCRIPT, then you want to set this parameter to ''N''.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N, E';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  par_rec.value3            := 'E';
  del; ins;

  par_rec.name              := 'count_star_threshold';
  par_rec.type              := 'N';
  par_rec.value             := '10000';
  par_rec.description       := 'Limits the number or rows to count while doing a "SELECT COUNT(*)" in set of tables accessed by SQL passed.<br>If you want to disable this functionality set this parameter to ''0''.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '10000';
  par_rec.instructions      := '0-1000000000';
  par_rec.low_value         := '0';
  par_rec.high_value        := '1000000000';
  del; ins;

  par_rec.name              := 'mask_for_values';
  par_rec.type              := 'C';
  par_rec.value             := 'CLEAR';
  par_rec.description       := 'Endpoint values for table columns are part of the CBO statistics. They include column low/high values as well as histograms.<br>If for privacy reasons these endpoints must be removed from SQLT reports, you can set this parameter to SECURE or COMPLETE.<br>SECURE displays only the year for dates, and one character for strings and numbers.<br>COMPLETE blocks completely the display of endpoints and it also disables the automatic export of the SQLT repository.<br>The default is CLEAR, which shows the values of endpoints.<br>If considering changing to a non-default value, bear in mind that Selectivity and Cardinality verification requires some knowledge of the values of these column endpoints.<br>Be also aware that 10053 traces also contain some low/high values which are not affected by this parameter.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'CLEAR';
  par_rec.instructions      := 'CLEAR, SECURE, COMPLETE';
  par_rec.value1            := 'CLEAR';
  par_rec.value2            := 'SECURE';
  par_rec.value3            := 'COMPLETE';
  del; ins;

  par_rec.name              := 'keyword_font_color';
  par_rec.type              := 'C';
  par_rec.value             := 'crimson';
  par_rec.description       := 'Sets font color for following keywords in SQL text: SELECT, INSERT, UPDATE, DELETE, MERGE, FROM, WHERE.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'crimson';
  par_rec.instructions      := 'crimson, red, orange, green, none';
  par_rec.value1            := 'crimson';
  par_rec.value2            := 'red';
  par_rec.value3            := 'orange';
  par_rec.value4            := 'green';
  par_rec.value5            := 'none';
  del; ins;

  par_rec.name              := 'plan_stats';
  par_rec.type              := 'C';
  par_rec.value             := 'BOTH';
  par_rec.description       := 'Execution plans from GV$SQL_PLAN may contain statistics for the last execution of a cursor and for all executions of it (if parameter statistics_level was set to ALL when the cursor was hard-parsed).<br>This parameter controls the display of the statistics of both (last execution as well as all executions).';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'BOTH';
  par_rec.instructions      := 'BOTH, LAST, ALL';
  par_rec.value1            := 'BOTH';
  par_rec.value2            := 'LAST';
  par_rec.value3            := 'ALL';
  del; ins;

  par_rec.name              := 'xecute_script_output';
  par_rec.type              := 'C';
  par_rec.value             := 'KEEP';
  par_rec.description       := 'SQLT XECUTE generates a spool file with the output of the SQL being analyzed (passed within input script).<br>This file can be kept in the local directory, or included in the zip file, or simply removed.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'KEEP';
  par_rec.instructions      := 'KEEP, ZIP, DELETE';
  par_rec.value1            := 'KEEP';
  par_rec.value2            := 'ZIP';
  par_rec.value3            := 'DELETE';
  del; ins;

  par_rec.name              := 'c_gran_segm';
  par_rec.type              := 'C';
  par_rec.value             := 'SUBPARTITION';
  par_rec.description       := 'Collection Granularity for Segments (Tables and Indexes).<br>Default value of "SUBPARTITION" allows SQLT to collect into its repository CBO statistics for tables, indexes, partitions and subpartitions. All related to the one SQL being analyzed.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'SUBPARTITION';
  par_rec.instructions      := 'SUBPARTITION, PARTITION, GLOBAL';
  par_rec.value1            := 'SUBPARTITION';
  par_rec.value2            := 'PARTITION';
  par_rec.value3            := 'GLOBAL';
  del; ins;

  par_rec.name              := 'c_gran_cols';
  par_rec.type              := 'C';
  par_rec.value             := 'SUBPARTITION';
  par_rec.description       := 'Collection Granularity for Columns.<br>Default value of "SUBPARTITION" allows SQLT to collect into its repository CBO statistics for columns at all levels: table, partitions and subpartitions. All related to the one SQL being analyzed.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'SUBPARTITION';
  par_rec.instructions      := 'SUBPARTITION, PARTITION, GLOBAL';
  par_rec.value1            := 'SUBPARTITION';
  par_rec.value2            := 'PARTITION';
  par_rec.value3            := 'GLOBAL';
  del; ins;

  par_rec.name              := 'c_gran_hgrm';
  par_rec.type              := 'C';
  par_rec.value             := 'SUBPARTITION';
  par_rec.description       := 'Collection Granularity for Histograms.<br>Default value of "SUBPARTITION" allows SQLT to collect into its repository CBO statistics for histograms at all levels: table, partitions and subpartitions. All related to the one SQL being analyzed.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'SUBPARTITION';
  par_rec.instructions      := 'SUBPARTITION, PARTITION, GLOBAL';
  par_rec.value1            := 'SUBPARTITION';
  par_rec.value2            := 'PARTITION';
  par_rec.value3            := 'GLOBAL';
  del; ins;

  par_rec.name              := 'r_gran_segm';
  par_rec.type              := 'C';
  par_rec.value             := 'PARTITION';
  par_rec.description       := 'Report Granularity for Segments (Tables and Indexes).<br>Default value of "PARTITION" reports tables, indexes, and partitions. All related to the one SQL being analyzed.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'PARTITION';
  par_rec.instructions      := 'PARTITION, GLOBAL';
  par_rec.value1            := 'PARTITION';
  par_rec.value2            := 'GLOBAL';
  del; ins;

  par_rec.name              := 'r_gran_cols';
  par_rec.type              := 'C';
  par_rec.value             := 'PARTITION';
  par_rec.description       := 'Report Granularity for Columns.<br>Default value of "PARTITION" reports table partition columns. All related to the one SQL being analyzed.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'PARTITION';
  par_rec.instructions      := 'PARTITION, GLOBAL';
  par_rec.value1            := 'PARTITION';
  par_rec.value2            := 'GLOBAL';
  del; ins;

  par_rec.name              := 'r_gran_hgrm';
  par_rec.type              := 'C';
  par_rec.value             := 'PARTITION';
  par_rec.description       := 'Report Granularity for Table Histograms.<br>Default value of "PARTITION" reports table and partition histograms. All related to the one SQL being analyzed.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'PARTITION';
  par_rec.instructions      := 'PARTITION, GLOBAL';
  par_rec.value1            := 'PARTITION';
  par_rec.value2            := 'GLOBAL';
  del; ins;

  par_rec.name              := 'r_gran_vers';
  par_rec.type              := 'C';
  par_rec.value             := 'COLUMN';
  par_rec.description       := 'Report CBO Statistics Version Granularity for Tables.<br>Default value of "COLUMN" reports statistics versions for segments and their columns. All related to the one SQL being analyzed.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'COLUMN';
  par_rec.instructions      := 'COLUMN, SEGMENT, HISTOGRAM';
  par_rec.value1            := 'COLUMN';
  par_rec.value2            := 'SEGMENT';
  par_rec.value3            := 'HISTOGRAM';
  del; ins;

  par_rec.name              := 'r_rows_table_xs';
  par_rec.type              := 'N';
  par_rec.value             := '10';
  par_rec.description       := 'Restricts number of elements for extra-small html tables or lists.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '10';
  par_rec.instructions      := '1-100';
  par_rec.low_value         := '1';
  par_rec.high_value        := '100';
  del; ins;

  par_rec.name              := 'r_rows_table_s';
  par_rec.type              := 'N';
  par_rec.value             := '100';
  par_rec.description       := 'Restricts number of elements for small html tables or lists.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '100';
  par_rec.instructions      := '10-1000';
  par_rec.low_value         := '10';
  par_rec.high_value        := '1000';
  del; ins;

  par_rec.name              := 'r_rows_table_m';
  par_rec.type              := 'N';
  par_rec.value             := '300';
  par_rec.description       := 'Restricts number of elements for medium html tables or lists.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '300';
  par_rec.instructions      := '30-3000';
  par_rec.low_value         := '30';
  par_rec.high_value        := '3000';
  del; ins;

  par_rec.name              := 'r_rows_table_l';
  par_rec.type              := 'N';
  par_rec.value             := '1000';
  par_rec.description       := 'Restricts number of elements for large html tables or lists.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '1000';
  par_rec.instructions      := '100-10000';
  par_rec.low_value         := '100';
  par_rec.high_value        := '10000';
  del; ins;

  par_rec.name              := 'rollback_or_commit';
  par_rec.type              := 'C';
  par_rec.value             := 'ROLLBACK';
  par_rec.description       := 'SQLT XECUTE uses this parameter to perform an automatic ROLLBACK or COMMIT right after the execution of the script provided.<br>Set to COMMIT when analyzing a parallel DML if you want to capture the content of GV$PQ_TQSTAT.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'ROLLBACK';
  par_rec.instructions      := 'ROLLBACK, COMMIT';
  par_rec.value1            := 'ROLLBACK';
  par_rec.value2            := 'COMMIT';
  del; -- deprecated
  
  par_rec.name              := 'colgroup_seed_secs';
  par_rec.type              := 'N';
  par_rec.value             := '0';
  par_rec.description       := 'Controls if SQLT will enable DBMS_STATS.SEED_COL_USAGE for the specified number of seconds during 10053 trace capture, requires param event_10053_level enabled.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '0';
  par_rec.instructions      := '0-3600';
  par_rec.low_value         := '0';
  par_rec.high_value        := '3600';
  del; ins;  

  par_rec.name              := 'event_10046_level';
  par_rec.type              := 'C';
  par_rec.value             := '12';
  par_rec.description       := 'SQLT XECUTE turns event 10046 level 12 by default. You can set a different level or turn this event 10046 off using this parameter. It only affects the execution of the script passed to SQLT XECUTE.<br>Level 0 means no trace, level 1 is standard SQL Trace, level 4 includes bind variable values, level 8 includes waits and level 12 both binds and waits.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '12';
  par_rec.instructions      := '12, 8, 4, 1, 0';
  par_rec.value1            := '12';
  par_rec.value2            := '8';
  par_rec.value3            := '4';
  par_rec.value4            := '1';
  par_rec.value5            := '0';
  del; ins;

  par_rec.name              := 'event_10053_level';
  par_rec.type              := 'C';
  par_rec.value             := '1';
  par_rec.description       := 'SQLT XECUTE, XTRACT and XPLAIN turn event 10053 level 1 by default. You can turn this event 10053 off using this parameter. It only affects the SQL passed to SQLT.<br>Level 0 means no trace, level 1 traces the CBO.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '1';
  par_rec.instructions      := '1, 0';
  par_rec.value1            := '1';
  par_rec.value2            := '0';
  del; ins;

  par_rec.name              := 'event_10507_level';
  par_rec.type              := 'N';
  par_rec.value             := '1023';
  par_rec.description       := 'SQLT XECUTE uses this event on 11g to trace Cardinality Feedback CFB. You can turn this event 10507 off using this parameter. It only affects the SQL passed to SQLT.<br>Level 0 means no trace, for meaning of other levels see 740052.1.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '1023';
  par_rec.instructions      := '0-1023';
  par_rec.low_value         := '0';
  par_rec.high_value        := '1023';
  del; ins;

  par_rec.name              := 'event_others';
  par_rec.type              := 'C';
  par_rec.value             := 'N';
  par_rec.description       := 'This parameter controls the use of events 10241, 10032, 10033, 10104, 10730, 46049, but only if 10046 is turned on (any level but 0). It only affects the execution of the script passed to SQLT XECUTE.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'N';
  par_rec.instructions      := 'N, Y';
  par_rec.value1            := 'N';
  par_rec.value2            := 'Y';
  del; ins;

  par_rec.name              := 'keep_trace_10046_open';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'If you need to trace an execution of SQLT XECUTE, XTRACT or XPLAIN, this parameter allows to keep trace 10046 active even after custom SCRIPT completes.<br>It is used by XECUTE, XTRACT and XPLAIN.<br>When set to its default value of "N", event 10046 is turned off right after the execution of the custom SCRIPT or when 10053 is turned off.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  par_rec.name              := 'show_binds_in_predicates';
  par_rec.type              := 'C';
  par_rec.value             := 'Y';
  par_rec.description       := 'Display Peeked and Captured Binds associated to Predicates on Column Statistics section of MAIN report.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'Y';
  par_rec.instructions      := 'Y, N';
  par_rec.value1            := 'Y';
  par_rec.value2            := 'N';
  del; ins;

  /* 19332407 Separate Exadata specific data for rare cases */

  par_rec.name              := 'collect_exadata_stats';
  par_rec.type              := 'C';
  par_rec.value             := 'N';
  par_rec.description       := 'Collects Exadata-Specific performance statistics on XECUTE method.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := 'N';
  par_rec.instructions      := 'N,Y';
  par_rec.value1            := 'N';
  par_rec.value2            := 'Y';
  del; ins;
  
  par_rec.name              := 'perfhub_reports';
  par_rec.type              := 'N';
  par_rec.value             := '1';
  par_rec.description       := 'Maximum number of PerfHUb reports to generate.';
  par_rec.is_hidden         := 'N';
  par_rec.is_usr_modifiable := 'Y';
  par_rec.is_default        := 'Y';
  par_rec.default_value     := '1';
  par_rec.instructions      := '0-9999';
  par_rec.low_value         := '0';
  par_rec.high_value        := '9999';
  del; ins;

  
END;
/

SET TERM ON;

PRO
PRO SQLT can make extensive use of licensed features
PRO provided by the Oracle Diagnostic and the Oracle
PRO Tuning Packs, including SQL Tuning Advisor (STA),
PRO SQL Monitoring, Automatic Workload Repository
PRO (AWR) and SQL Tuning Sets (STS).
PRO To enable or disable access to these features
PRO from the SQLT tool enter one of the following
PRO values when asked:
PRO
PRO "T" if you have license for Diagnostic and Tuning
PRO "D" if you have license only for Oracle Diagnostic
PRO "N" if you do not have these two licenses
PRO
BEGIN
  DBMS_OUTPUT.PUT_LINE('pack_license: "~~pack_license."');
  IF NVL(SUBSTR(UPPER(TRIM('~~pack_license.')), 1, 1), 'T') = 'T' THEN
    UPDATE ~~tool_repository_schema..sqli$_parameter
       SET value = 'Y',
           is_default = 'Y'
     WHERE name IN ('sql_tuning_advisor', 'sql_tuning_set', 'sql_monitoring', 'automatic_workload_repository');
    DBMS_OUTPUT.PUT_LINE('enable_tuning_pack_access');
  ELSIF SUBSTR(UPPER(TRIM('~~pack_license.')), 1, 1) = 'D' THEN
    UPDATE ~~tool_repository_schema..sqli$_parameter
       SET value = 'N',
           is_default = 'N'
     WHERE name IN ('sql_tuning_advisor', 'sql_tuning_set', 'sql_monitoring');
    UPDATE ~~tool_repository_schema..sqli$_parameter
       SET value = 'Y',
           is_default = 'Y'
     WHERE name = 'automatic_workload_repository';
    DBMS_OUTPUT.PUT_LINE('enable_diagnostic_pack_access');
  ELSE -- N
    UPDATE ~~tool_repository_schema..sqli$_parameter
       SET value = 'N',
           is_default = 'N'
     WHERE name IN ('sql_tuning_advisor', 'sql_tuning_set', 'sql_monitoring', 'automatic_workload_repository');
    DBMS_OUTPUT.PUT_LINE('disable_pack_access');
  END IF;
END;
/

PRO
PRO Specify optional Connect Identifier (as per Oracle Net)
PRO Include "@" symbol, ie. @PROD
PRO If not applicable, enter nothing and hit the "Enter" key
PRO
BEGIN
  DBMS_OUTPUT.PUT_LINE('connect_identifier: "~~connect_identifier."');
  IF '~~connect_identifier.' IS NOT NULL AND '~~connect_identifier.' LIKE '@%' THEN
    UPDATE ~~tool_repository_schema..sqli$_parameter
       SET value = UPPER('~~connect_identifier.'),
           is_default = 'N'
     WHERE name = 'connect_identifier';
  END IF;
END;
/

--SET TERM OFF;

/*------------------------------------------------------------------*/

TRUNCATE TABLE ~~tool_repository_schema..sqli$_clob;

DECLARE
clob_text CLOB;
BEGIN -- 716
  clob_text := q'[

<style type="text/css">
body {font:10pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}
a {font-weight:bold; color:#663300;}
a.l {font-weight:bold; color:#663300;} /* line in brownish */
a.nl {text-decoration:none; color:#336699;} /* no line in blue */
a.nlb {font-weight:normal; text-decoration:none; color:black;} /* no line in black */
a.nlr {font-weight:normal; text-decoration:none; color:crimson;} /* no line in red */
a.op {font-weight:normal; font:8pt Courier New; text-decoration:none; color:black;} /* no line in black and fixed font */
pre {font:8pt Monaco,"Courier New",Courier,monospace;} /* for code */
h1 {font-size:16pt; font-weight:bold; color:#336699;}
h2 {font-size:14pt; font-weight:bold; color:#336699;}
h3 {font-size:12pt; font-weight:bold; color:#336699;}
h4 {font-size:10pt; font-weight:bold; color:#336699;}
li {font-size:10pt; font-weight:bold; color:#336699; padding:0.1em 0 0 0;}
table {font-size:8pt; color:black; background:white;}
th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
th.vt {writing-mode:tb-rl; filter:flipV flipH; text-align:center; padding-left:1pt; padding-right:1pt; padding-top:3pt; padding-bottom:3pt;}
td {text-align:left; background:#fcfcd0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
td.c {text-align:center; background:#fcfcf0;} /* center */
td.l {text-align:left; background:#fcfcf0;} /* left (default) */
td.r {text-align:right; background:#fcfcf0;} /* right */
td.rr {text-align:right; color:crimson; background:#fcfcf0;} /* right and red */
td.rrr {text-align:right; background:crimson;} /* right and super red  */
td.t {text-align:center; font-weight:bold; color:#336699; background:#cccc99;} /* center title */
td.rt {text-align:right; font-weight:bold; color:#336699; background:#cccc99;} /* right title */
td.lt {text-align:left; font-weight:bold; color:#336699; background:#cccc99;} /* left title */
td.ltm {text-align:left; vertical-align:middle; font-weight:bold; color:#336699; background:#cccc99;} /* left title middle */
td.w {background:white;} /* white */
td.lw {text-align:left; background:white;} /* left and white */
td.vt {background:#fcfcf0; writing-mode:tb-rl; filter:flipV flipH; text-align:center; padding-left:1pt; padding-right:1pt; padding-top:3pt; padding-bottom:3pt;}
td.op {font:8pt Courier New; color:black; background:#fcfcf0;} /* black and fixed font */
font.n {font-size:8pt; font-style:italic; color:#336699;} /* table footnote in blue */
font.nr {font-size:8pt; font-style:italic; color:crimson;} /* table footnote in red */
font.crimson {color:crimson;}
font.red {color:red;}
font.darkred {color:darkred;}
font.orange {color:orange;}
font.darkorange {color:darkorange;}
font.green {color:green;}
font.darkblue {color:#0000CC;}
font.f {font-size:8pt; color:#999999;} /* footnote in gray */
font.c {font:8pt Courier New;} /* fixed font */
font.b {font-weight:bold;} /* bold */
font.br {font-weight:bold; color:crimson;} /* bold and red */
</style>

]';
  INSERT INTO ~~tool_repository_schema..sqli$_clob VALUES ('CSS', clob_text);

  clob_text := q'[

<script type="text/javascript">
//<!-- show and hide

function snh(id_control, id_text) {

   var v_control = document.getElementById(id_control);
   var v_text = document.getElementById(id_text);

   if(v_control.innerHTML == '-')
     v_control.innerHTML = '+';
   else
     v_control.innerHTML = '-';

   if(v_text.style.display == 'block')
      v_text.style.display = 'none';
   else
      v_text.style.display = 'block';

   }

//-->
</script>

]';
  INSERT INTO ~~tool_repository_schema..sqli$_clob VALUES ('SHOW_HIDE', clob_text);

  clob_text := q'[

<script type="text/javascript">
//<!-- overLIB (c) Erik Bosrup

var ol_capcolor="#336699";
var ol_closecolor="#663300";
var ol_width="300";
var ol_hauto=1;
var ol_vauto=1;

var ol_texts = new Array(
 "Estimated number of rows that an equality predicate in this column would return on a particular value."
,"Estimated fraction of rows that an equality predicate in this column would return on a particular value."
,"Index is referenced by at least one known plan"
,"Column name is referenced by at least one predicate (access or filter) of an operation from a known plan."
,"Column is referenced by at least one index."
,"Column name is referenced by the column projection of an operation from a known plan."
,"6"
);

var ol_caps = new Array(
 "0"
,"1"
,"2"
,"3"
);

// overLIB (c) Erik Bosrup -->
</script>

]';
  INSERT INTO ~~tool_repository_schema..sqli$_clob VALUES ('OVERLIB1', clob_text);

  clob_text := q'[

<script type="text/javascript">
//<!-- overLIB (c) Erik Bosrup
//\/////
//\  overLIB 4.21 - You may not remove or change this notice.
//\  Copyright Erik Bosrup 1998-2004. All rights reserved.
//\
//\  Contributors are listed on the homepage.
//\  This file might be old, always check for the latest version at:
//\  http://www.bosrup.com/web/overlib/
//\
//\  Please read the license agreement (available through the link above)
//\  before using overLIB. Direct any licensing questions to erik@bosrup.com.
//\
//\  Do not sell this as your own work or remove this copyright notice.
//\  For full details on copying or changing this script please read the
//\  license agreement at the link above. Please give credit on sites that
//\  use overLIB and submit changes of the script so other people can use
//\  them as well.
//   $Revision: 1.119 $                $Date: 2005/07/02 23:41:44 $
//\/////
//\mini

////////
// PRE-INIT
// Ignore these lines, configuration is below.
////////
var olLoaded = 0;var pmStart = 10000000; var pmUpper = 10001000; var pmCount = pmStart+1; var pmt=''; var pms = new Array(); var olInfo = new Info('4.21', 1);
var FREPLACE = 0; var FBEFORE = 1; var FAFTER = 2; var FALTERNATE = 3; var FCHAIN=4;
var olHideForm=0;  // parameter for hiding SELECT and ActiveX elements in IE5.5+
var olHautoFlag = 0;  // flags for over-riding VAUTO and HAUTO if corresponding
var olVautoFlag = 0;  // positioning commands are used on the command line
var hookPts = new Array(), postParse = new Array(), cmdLine = new Array(), runTime = new Array();
// for plugins
registerCommands('donothing,inarray,caparray,sticky,background,noclose,caption,left,right,center,offsetx,offsety,fgcolor,bgcolor,textcolor,capcolor,closecolor,width,border,cellpad,status,autostatus,autostatuscap,height,closetext,snapx,snapy,fixx,fixy,relx,rely,fgbackground,bgbackground,padx,pady,fullhtml,above,below,capicon,textfont,captionfont,closefont,textsize,captionsize,closesize,timeout,function,delay,hauto,vauto,closeclick,wrap,followmouse,mouseoff,closetitle,cssoff,compatmode,cssclass,fgclass,bgclass,textfontclass,captionfontclass,closefontclass');

////////
// DEFAULT CONFIGURATION
// Settings you want everywhere are set here. All of this can also be
// changed on your html page or through an overLIB call.
////////
if (typeof ol_fgcolor=='undefined') var ol_fgcolor="#CCCCFF";
if (typeof ol_bgcolor=='undefined') var ol_bgcolor="#333399";
if (typeof ol_textcolor=='undefined') var ol_textcolor="#000000";
if (typeof ol_capcolor=='undefined') var ol_capcolor="#FFFFFF";
if (typeof ol_closecolor=='undefined') var ol_closecolor="#9999FF";
if (typeof ol_textfont=='undefined') var ol_textfont="Verdana,Arial,Helvetica";
if (typeof ol_captionfont=='undefined') var ol_captionfont="Verdana,Arial,Helvetica";
if (typeof ol_closefont=='undefined') var ol_closefont="Verdana,Arial,Helvetica";
if (typeof ol_textsize=='undefined') var ol_textsize="1";
if (typeof ol_captionsize=='undefined') var ol_captionsize="1";
if (typeof ol_closesize=='undefined') var ol_closesize="1";
if (typeof ol_width=='undefined') var ol_width="200";
if (typeof ol_border=='undefined') var ol_border="1";
if (typeof ol_cellpad=='undefined') var ol_cellpad=2;
if (typeof ol_offsetx=='undefined') var ol_offsetx=10;
if (typeof ol_offsety=='undefined') var ol_offsety=10;
if (typeof ol_text=='undefined') var ol_text="Default Text";
if (typeof ol_cap=='undefined') var ol_cap="";
if (typeof ol_sticky=='undefined') var ol_sticky=0;
if (typeof ol_background=='undefined') var ol_background="";
if (typeof ol_close=='undefined') var ol_close="Close";
if (typeof ol_hpos=='undefined') var ol_hpos=RIGHT;
if (typeof ol_status=='undefined') var ol_status="";
if (typeof ol_autostatus=='undefined') var ol_autostatus=0;
if (typeof ol_height=='undefined') var ol_height=-1;
if (typeof ol_snapx=='undefined') var ol_snapx=0;
if (typeof ol_snapy=='undefined') var ol_snapy=0;
if (typeof ol_fixx=='undefined') var ol_fixx=-1;
if (typeof ol_fixy=='undefined') var ol_fixy=-1;
if (typeof ol_relx=='undefined') var ol_relx=null;
if (typeof ol_rely=='undefined') var ol_rely=null;
if (typeof ol_fgbackground=='undefined') var ol_fgbackground="";
if (typeof ol_bgbackground=='undefined') var ol_bgbackground="";
if (typeof ol_padxl=='undefined') var ol_padxl=1;
if (typeof ol_padxr=='undefined') var ol_padxr=1;
if (typeof ol_padyt=='undefined') var ol_padyt=1;
if (typeof ol_padyb=='undefined') var ol_padyb=1;
if (typeof ol_fullhtml=='undefined') var ol_fullhtml=0;
if (typeof ol_vpos=='undefined') var ol_vpos=BELOW;
if (typeof ol_aboveheight=='undefined') var ol_aboveheight=0;
if (typeof ol_capicon=='undefined') var ol_capicon="";
if (typeof ol_frame=='undefined') var ol_frame=self;
if (typeof ol_timeout=='undefined') var ol_timeout=0;
if (typeof ol_function=='undefined') var ol_function=null;
if (typeof ol_delay=='undefined') var ol_delay=0;
if (typeof ol_hauto=='undefined') var ol_hauto=0;
if (typeof ol_vauto=='undefined') var ol_vauto=0;
if (typeof ol_closeclick=='undefined') var ol_closeclick=0;
if (typeof ol_wrap=='undefined') var ol_wrap=0;
if (typeof ol_followmouse=='undefined') var ol_followmouse=1;
if (typeof ol_mouseoff=='undefined') var ol_mouseoff=0;
if (typeof ol_closetitle=='undefined') var ol_closetitle='Close';
if (typeof ol_compatmode=='undefined') var ol_compatmode=0;
if (typeof ol_css=='undefined') var ol_css=CSSOFF;
if (typeof ol_fgclass=='undefined') var ol_fgclass="";
if (typeof ol_bgclass=='undefined') var ol_bgclass="";
if (typeof ol_textfontclass=='undefined') var ol_textfontclass="";
if (typeof ol_captionfontclass=='undefined') var ol_captionfontclass="";
if (typeof ol_closefontclass=='undefined') var ol_closefontclass="";

////////
// ARRAY CONFIGURATION
////////

// You can use these arrays to store popup text here instead of in the html.
if (typeof ol_texts=='undefined') var ol_texts = new Array("Text 0", "Text 1");
if (typeof ol_caps=='undefined') var ol_caps = new Array("Caption 0", "Caption 1");

////////
// END OF CONFIGURATION
// Don't change anything below this line, all configuration is above.
////////





////////
// INIT
////////
// Runtime variables init. Don't change for config!
var o3_text="";
var o3_cap="";
var o3_sticky=0;
var o3_background="";
var o3_close="Close";
var o3_hpos=RIGHT;
var o3_offsetx=2;
var o3_offsety=2;
var o3_fgcolor="";
var o3_bgcolor="";
var o3_textcolor="";
var o3_capcolor="";
var o3_closecolor="";
var o3_width=100;
var o3_border=1;
var o3_cellpad=2;
var o3_status="";
var o3_autostatus=0;
var o3_height=-1;
var o3_snapx=0;
var o3_snapy=0;
var o3_fixx=-1;
var o3_fixy=-1;
var o3_relx=null;
var o3_rely=null;
var o3_fgbackground="";
var o3_bgbackground="";
var o3_padxl=0;
var o3_padxr=0;
var o3_padyt=0;
var o3_padyb=0;
var o3_fullhtml=0;
var o3_vpos=BELOW;
var o3_aboveheight=0;
var o3_capicon="";
var o3_textfont="Verdana,Arial,Helvetica";
var o3_captionfont="Verdana,Arial,Helvetica";
var o3_closefont="Verdana,Arial,Helvetica";
var o3_textsize="1";
var o3_captionsize="1";
var o3_closesize="1";
var o3_frame=self;
var o3_timeout=0;
var o3_timerid=0;
var o3_allowmove=0;
var o3_function=null;
var o3_delay=0;
var o3_delayid=0;
var o3_hauto=0;
var o3_vauto=0;
var o3_closeclick=0;
var o3_wrap=0;
var o3_followmouse=1;
var o3_mouseoff=0;
var o3_closetitle='';
var o3_compatmode=0;
var o3_css=CSSOFF;
var o3_fgclass="";
var o3_bgclass="";
var o3_textfontclass="";
var o3_captionfontclass="";
var o3_closefontclass="";

// Display state variables
var o3_x = 0;
var o3_y = 0;
var o3_showingsticky = 0;
var o3_removecounter = 0;

// Our layer
var over = null;
var fnRef, hoveringSwitch = false;
var olHideDelay;

// Decide browser version
var isMac = (navigator.userAgent.indexOf("Mac") != -1);
var olOp = (navigator.userAgent.toLowerCase().indexOf('opera') > -1 && document.createTextNode);  // Opera 7
var olNs4 = (navigator.appName=='Netscape' && parseInt(navigator.appVersion) == 4);
var olNs6 = (document.getElementById) ? true : false;
var olKq = (olNs6 && /konqueror/i.test(navigator.userAgent));
var olIe4 = (document.all) ? true : false;
var olIe5 = false;
var olIe55 = false; // Added additional variable to identify IE5.5+
var docRoot = 'document.body';

// Resize fix for NS4.x to keep track of layer
if (olNs4) {
        var oW = window.innerWidth;
        var oH = window.innerHeight;
        window.onresize = function() { if (oW != window.innerWidth || oH != window.innerHeight) location.reload(); }
}

// Microsoft Stupidity Check(tm).
if (olIe4) {
        var agent = navigator.userAgent;
        if (/MSIE/.test(agent)) {
                var versNum = parseFloat(agent.match(/MSIE[ ](\d\.\d+)\.*/i)[1]);
                if (versNum >= 5){
                        olIe5=true;
                        olIe55=(versNum>=5.5&&!olOp) ? true : false;
                        if (olNs6) olNs6=false;
                }
        }
        if (olNs6) olIe4 = false;
}

// Check for compatability mode.
if (document.compatMode && document.compatMode == 'CSS1Compat') {
        docRoot= ((olIe4 && !olOp) ? 'document.documentElement' : docRoot);
}

// Add window onload handlers to indicate when all modules have been loaded
// For Netscape 6+ and Mozilla, uses addEventListener method on the window object
// For IE it uses the attachEvent method of the window object and for Netscape 4.x
// it sets the window.onload handler to the OLonload_handler function for Bubbling
if(window.addEventListener) window.addEventListener("load",OLonLoad_handler,false);
else if (window.attachEvent) window.attachEvent("onload",OLonLoad_handler);

var capExtent;

]';
  INSERT INTO ~~tool_repository_schema..sqli$_clob VALUES ('OVERLIB2', clob_text);

  clob_text := q'[

////////
// PUBLIC FUNCTIONS
////////

// overlib(arg0,...,argN)
// Loads parameters into global runtime variables.
function overlib() {
        if (!olLoaded || isExclusive(overlib.arguments)) return true;
        if (olCheckMouseCapture) olMouseCapture();
        if (over) {
                over = (typeof over.id != 'string') ? o3_frame.document.all['overDiv'] : over;
                cClick();
        }

        // Load defaults to runtime.
  olHideDelay=0;
        o3_text=ol_text;
        o3_cap=ol_cap;
        o3_sticky=ol_sticky;
        o3_background=ol_background;
        o3_close=ol_close;
        o3_hpos=ol_hpos;
        o3_offsetx=ol_offsetx;
        o3_offsety=ol_offsety;
        o3_fgcolor=ol_fgcolor;
        o3_bgcolor=ol_bgcolor;
        o3_textcolor=ol_textcolor;
        o3_capcolor=ol_capcolor;
        o3_closecolor=ol_closecolor;
        o3_width=ol_width;
        o3_border=ol_border;
        o3_cellpad=ol_cellpad;
        o3_status=ol_status;
        o3_autostatus=ol_autostatus;
        o3_height=ol_height;
        o3_snapx=ol_snapx;
        o3_snapy=ol_snapy;
        o3_fixx=ol_fixx;
        o3_fixy=ol_fixy;
        o3_relx=ol_relx;
        o3_rely=ol_rely;
        o3_fgbackground=ol_fgbackground;
        o3_bgbackground=ol_bgbackground;
        o3_padxl=ol_padxl;
        o3_padxr=ol_padxr;
        o3_padyt=ol_padyt;
        o3_padyb=ol_padyb;
        o3_fullhtml=ol_fullhtml;
        o3_vpos=ol_vpos;
        o3_aboveheight=ol_aboveheight;
        o3_capicon=ol_capicon;
        o3_textfont=ol_textfont;
        o3_captionfont=ol_captionfont;
        o3_closefont=ol_closefont;
        o3_textsize=ol_textsize;
        o3_captionsize=ol_captionsize;
        o3_closesize=ol_closesize;
        o3_timeout=ol_timeout;
        o3_function=ol_function;
        o3_delay=ol_delay;
        o3_hauto=ol_hauto;
        o3_vauto=ol_vauto;
        o3_closeclick=ol_closeclick;
        o3_wrap=ol_wrap;
        o3_followmouse=ol_followmouse;
        o3_mouseoff=ol_mouseoff;
        o3_closetitle=ol_closetitle;
        o3_css=ol_css;
        o3_compatmode=ol_compatmode;
        o3_fgclass=ol_fgclass;
        o3_bgclass=ol_bgclass;
        o3_textfontclass=ol_textfontclass;
        o3_captionfontclass=ol_captionfontclass;
        o3_closefontclass=ol_closefontclass;

        setRunTimeVariables();

        fnRef = '';

        // Special for frame support, over must be reset...
        o3_frame = ol_frame;

        if(!(over=createDivContainer())) return false;

        parseTokens('o3_', overlib.arguments);
        if (!postParseChecks()) return false;

        if (o3_delay == 0) {
                return runHook("olMain", FREPLACE);
        } else {
                o3_delayid = setTimeout("runHook('olMain', FREPLACE)", o3_delay);
                return false;
        }
}

// Clears popups if appropriate
function nd(time) {
        if (olLoaded && !isExclusive()) {
                hideDelay(time);  // delay popup close if time specified

                if (o3_removecounter >= 1) { o3_showingsticky = 0 };

                if (o3_showingsticky == 0) {
                        o3_allowmove = 0;
                        if (over != null && o3_timerid == 0) runHook("hideObject", FREPLACE, over);
                } else {
                        o3_removecounter++;
                }
        }

        return true;
}

// The Close onMouseOver function for stickies
function cClick() {
        if (olLoaded) {
                runHook("hideObject", FREPLACE, over);
                o3_showingsticky = 0;
        }
        return false;
}

// Method for setting page specific defaults.
function overlib_pagedefaults() {
        parseTokens('ol_', overlib_pagedefaults.arguments);
}


////////
// OVERLIB MAIN FUNCTION
////////

// This function decides what it is we want to display and how we want it done.
function olMain() {
        var layerhtml, styleType;
        runHook("olMain", FBEFORE);

        if (o3_background!="" || o3_fullhtml) {
                // Use background instead of box.
                layerhtml = runHook('ol_content_background', FALTERNATE, o3_css, o3_text, o3_background, o3_fullhtml);
        } else {
                // They want a popup box.
                styleType = (pms[o3_css-1-pmStart] == "cssoff" || pms[o3_css-1-pmStart] == "cssclass");

                // Prepare popup background
                if (o3_fgbackground != "") o3_fgbackground = "background=\""+o3_fgbackground+"\"";
                if (o3_bgbackground != "") o3_bgbackground = (styleType ? "background=\""+o3_bgbackground+"\"" : o3_bgbackground);

                // Prepare popup colors
                if (o3_fgcolor != "") o3_fgcolor = (styleType ? "bgcolor=\""+o3_fgcolor+"\"" : o3_fgcolor);
                if (o3_bgcolor != "") o3_bgcolor = (styleType ? "bgcolor=\""+o3_bgcolor+"\"" : o3_bgcolor);

                // Prepare popup height
                if (o3_height > 0) o3_height = (styleType ? "height=\""+o3_height+"\"" : o3_height);
                else o3_height = "";

                // Decide which kinda box.
                if (o3_cap=="") {
                        // Plain
                        layerhtml = runHook('ol_content_simple', FALTERNATE, o3_css, o3_text);
                } else {
                        // With caption
                        if (o3_sticky) {
                                // Show close text
                                layerhtml = runHook('ol_content_caption', FALTERNATE, o3_css, o3_text, o3_cap, o3_close);
                        } else {
                                // No close text
                                layerhtml = runHook('ol_content_caption', FALTERNATE, o3_css, o3_text, o3_cap, "");
                        }
                }
        }

        // We want it to stick!
        if (o3_sticky) {
                if (o3_timerid > 0) {
                        clearTimeout(o3_timerid);
                        o3_timerid = 0;
                }
                o3_showingsticky = 1;
                o3_removecounter = 0;
        }

        // Created a separate routine to generate the popup to make it easier
        // to implement a plugin capability
        if (!runHook("createPopup", FREPLACE, layerhtml)) return false;

        // Prepare status bar
        if (o3_autostatus > 0) {
                o3_status = o3_text;
                if (o3_autostatus > 1) o3_status = o3_cap;
        }

        // When placing the layer the first time, even stickies may be moved.
        o3_allowmove = 0;

        // Initiate a timer for timeout
        if (o3_timeout > 0) {
                if (o3_timerid > 0) clearTimeout(o3_timerid);
                o3_timerid = setTimeout("cClick()", o3_timeout);
        }

        // Show layer
        runHook("disp", FREPLACE, o3_status);
        runHook("olMain", FAFTER);

        return (olOp && event && event.type == 'mouseover' && !o3_status) ? '' : (o3_status != '');
}

////////
// LAYER GENERATION FUNCTIONS
////////
// These functions just handle popup content with tags that should adhere to the W3C standards specification.

// Makes simple table without caption
function ol_content_simple(text) {
        var cpIsMultiple = /,/.test(o3_cellpad);
        var txt = '<table width="'+o3_width+ '" border="0" cellpadding="'+o3_border+'" cellspacing="0" '+(o3_bgclass ? 'class="'+o3_bgclass+'"' : o3_bgcolor+' '+o3_height)+'><tr><td><table width="100%" border="0" '+((olNs4||!cpIsMultiple) ? 'cellpadding="'+o3_cellpad+'" ' : '')+'cellspacing="0" '+(o3_fgclass ? 'class="'+o3_fgclass+'"' : o3_fgcolor+' '+o3_fgbackground+' '+o3_height)+'><tr><td valign="TOP"'+(o3_textfontclass ? ' class="'+o3_textfontclass+'">' : ((!olNs4&&cpIsMultiple) ? ' style="'+setCellPadStr(o3_cellpad)+'">' : '>'))+(o3_textfontclass ? '' : wrapStr(0,o3_textsize,'text'))+text+(o3_textfontclass ? '' : wrapStr(1,o3_textsize))+'</td></tr></table></td></tr></table>';

        set_background("");
        return txt;
}

// Makes table with caption and optional close link
function ol_content_caption(text,title,close) {
        var nameId, txt, cpIsMultiple = /,/.test(o3_cellpad);
        var closing, closeevent;

        closing = "";
        closeevent = "onmouseover";
        if (o3_closeclick == 1) closeevent = (o3_closetitle ? "title='" + o3_closetitle +"'" : "") + " onclick";
        if (o3_capicon != "") {
          nameId = ' hspace = \"5\"'+' align = \"middle\" alt = \"\"';
          if (typeof o3_dragimg != 'undefined' && o3_dragimg) nameId =' hspace=\"5\"'+' name=\"'+o3_dragimg+'\" id=\"'+o3_dragimg+'\" align=\"middle\" alt=\"Drag Enabled\" title=\"Drag Enabled\"';
          o3_capicon = '<img src=\"'+o3_capicon+'\"'+nameId+' />';
        }

        if (close != "")
                closing = '<td '+(!o3_compatmode && o3_closefontclass ? 'class="'+o3_closefontclass : 'align="RIGHT')+'"><a href="javascript:return '+fnRef+'cClick();"'+((o3_compatmode && o3_closefontclass) ? ' class="' + o3_closefontclass + '" ' : ' ')+closeevent+'="return '+fnRef+'cClick();">'+(o3_closefontclass ? '' : wrapStr(0,o3_closesize,'close'))+close+(o3_closefontclass ? '' : wrapStr(1,o3_closesize,'close'))+'</a></td>';
        txt = '<table width="'+o3_width+ '" border="0" cellpadding="'+o3_border+'" cellspacing="0" '+(o3_bgclass ? 'class="'+o3_bgclass+'"' : o3_bgcolor+' '+o3_bgbackground+' '+o3_height)+'><tr><td><table width="100%" border="0" cellpadding="2" cellspacing="0"><tr><td'+(o3_captionfontclass ? ' class="'+o3_captionfontclass+'">' : '>')+(o3_captionfontclass ? '' : '<b>'+wrapStr(0,o3_captionsize,'caption'))+o3_capicon+title+(o3_captionfontclass ? '' : wrapStr(1,o3_captionsize)+'</b>')+'</td>'+closing+'</tr></table><table width="100%" border="0" '+((olNs4||!cpIsMultiple) ? 'cellpadding="'+o3_cellpad+'" ' : '')+'cellspacing="0" '+(o3_fgclass ? 'class="'+o3_fgclass+'"' : o3_fgcolor+' '+o3_fgbackground+' '+o3_height)+'><tr><td valign="TOP"'+(o3_textfontclass ? ' class="'+o3_textfontclass+'">' :((!olNs4&&cpIsMultiple) ? ' style="'+setCellPadStr(o3_cellpad)+'">' : '>'))+(o3_textfontclass ? '' : wrapStr(0,o3_textsize,'text'))+text+(o3_textfontclass ? '' : wrapStr(1,o3_textsize)) + '</td></tr></table></td></tr></table>';

        set_background("");
        return txt;
}

// Sets the background picture,padding and lots more. :)
function ol_content_background(text,picture,hasfullhtml) {
        if (hasfullhtml) {
                txt=text;
        } else {
                txt='<table width="'+o3_width+'" border="0" cellpadding="0" cellspacing="0" height="'+o3_height+'"><tr><td colspan="3" height="'+o3_padyt+'"></td></tr><tr><td width="'+o3_padxl+'"></td><td valign="TOP" width="'+(o3_width-o3_padxl-o3_padxr)+(o3_textfontclass ? '" class="'+o3_textfontclass : '')+'">'+(o3_textfontclass ? '' : wrapStr(0,o3_textsize,'text'))+text+(o3_textfontclass ? '' : wrapStr(1,o3_textsize))+'</td><td width="'+o3_padxr+'"></td></tr><tr><td colspan="3" height="'+o3_padyb+'"></td></tr></table>';
        }

        set_background(picture);
        return txt;
}

// Loads a picture into the div.
function set_background(pic) {
        if (pic == "") {
                if (olNs4) {
                        over.background.src = null;
                } else if (over.style) {
                        over.style.backgroundImage = "none";
                }
        } else {
                if (olNs4) {
                        over.background.src = pic;
                } else if (over.style) {
                        over.style.width=o3_width + 'px';
                        over.style.backgroundImage = "url("+pic+")";
                }
        }
}

////////
// HANDLING FUNCTIONS
////////
var olShowId=-1;

// Displays the popup
function disp(statustext) {
        runHook("disp", FBEFORE);

        if (o3_allowmove == 0) {
                runHook("placeLayer", FREPLACE);
                (olNs6&&olShowId<0) ? olShowId=setTimeout("runHook('showObject', FREPLACE, over)", 1) : runHook("showObject", FREPLACE, over);
                o3_allowmove = (o3_sticky || o3_followmouse==0) ? 0 : 1;
        }

        runHook("disp", FAFTER);

        if (statustext != "") self.status = statustext;
}

// Creates the actual popup structure
function createPopup(lyrContent){
        runHook("createPopup", FBEFORE);

        if (o3_wrap) {
                var wd,ww,theObj = (olNs4 ? over : over.style);
                theObj.top = theObj.left = ((olIe4&&!olOp) ? 0 : -10000) + (!olNs4 ? 'px' : 0);
                layerWrite(lyrContent);
                wd = (olNs4 ? over.clip.width : over.offsetWidth);
                if (wd > (ww=windowWidth())) {
                        lyrContent=lyrContent.replace(/\&nbsp;/g, ' ');
                        o3_width=ww;
                        o3_wrap=0;
                }
        }

        layerWrite(lyrContent);

        // Have to set o3_width for placeLayer() routine if o3_wrap is turned on
        if (o3_wrap) o3_width=(olNs4 ? over.clip.width : over.offsetWidth);

        runHook("createPopup", FAFTER, lyrContent);

        return true;
}

// Decides where we want the popup.
function placeLayer() {
        var placeX, placeY, widthFix = 0;

        // HORIZONTAL PLACEMENT, re-arranged to work in Safari
        if (o3_frame.innerWidth) widthFix=18;
        iwidth = windowWidth();

        // Horizontal scroll offset
        winoffset=(olIe4) ? eval('o3_frame.'+docRoot+'.scrollLeft') : o3_frame.pageXOffset;

        placeX = runHook('horizontalPlacement',FCHAIN,iwidth,winoffset,widthFix);

        // VERTICAL PLACEMENT, re-arranged to work in Safari
        if (o3_frame.innerHeight) {
                iheight=o3_frame.innerHeight;
        } else if (eval('o3_frame.'+docRoot)&&eval("typeof o3_frame."+docRoot+".clientHeight=='number'")&&eval('o3_frame.'+docRoot+'.clientHeight')) {
                iheight=eval('o3_frame.'+docRoot+'.clientHeight');
        }

        // Vertical scroll offset
        scrolloffset=(olIe4) ? eval('o3_frame.'+docRoot+'.scrollTop') : o3_frame.pageYOffset;
        placeY = runHook('verticalPlacement',FCHAIN,iheight,scrolloffset);

        // Actually move the object.
        repositionTo(over, placeX, placeY);
}

// Moves the layer
function olMouseMove(e) {
        var e = (e) ? e : event;

        if (e.pageX) {
                o3_x = e.pageX;
                o3_y = e.pageY;
        } else if (e.clientX) {
                o3_x = eval('e.clientX+o3_frame.'+docRoot+'.scrollLeft');
                o3_y = eval('e.clientY+o3_frame.'+docRoot+'.scrollTop');
        }

        if (o3_allowmove == 1) runHook("placeLayer", FREPLACE);

        // MouseOut handler
        if (hoveringSwitch && !olNs4 && runHook("cursorOff", FREPLACE)) {
                (olHideDelay ? hideDelay(olHideDelay) : cClick());
                hoveringSwitch = !hoveringSwitch;
        }
}

// Fake function for 3.0 users.
function no_overlib() { return ver3fix; }

// Capture the mouse and chain other scripts.
function olMouseCapture() {
        capExtent = document;
        var fN, str = '', l, k, f, wMv, sS, mseHandler = olMouseMove;
        var re = /function[ ]*(\w*)\(/;

        wMv = (!olIe4 && window.onmousemove);
        if (document.onmousemove || wMv) {
                if (wMv) capExtent = window;
                f = capExtent.onmousemove.toString();
                fN = f.match(re);
                if (fN == null) {
                        str = f+'(e); ';
                } else if (fN[1] == 'anonymous' || fN[1] == 'olMouseMove' || (wMv && fN[1] == 'onmousemove')) {
                        if (!olOp && wMv) {
                                l = f.indexOf('{')+1;
                                k = f.lastIndexOf('}');
                                sS = f.substring(l,k);
                                if ((l = sS.indexOf('(')) != -1) {
                                        sS = sS.substring(0,l).replace(/^\s+/,'').replace(/\s+$/,'');
                                        if (eval("typeof " + sS + " == 'undefined'")) window.onmousemove = null;
                                        else str = sS + '(e);';
                                }
                        }
                        if (!str) {
                                olCheckMouseCapture = false;
                                return;
                        }
                } else {
                        if (fN[1]) str = fN[1]+'(e); ';
                        else {
                                l = f.indexOf('{')+1;
                                k = f.lastIndexOf('}');
                                str = f.substring(l,k) + '\n';
                        }
                }
                str += 'olMouseMove(e); ';
                mseHandler = new Function('e', str);
        }

        capExtent.onmousemove = mseHandler;
        if (olNs4) capExtent.captureEvents(Event.MOUSEMOVE);
}

////////
// PARSING FUNCTIONS
////////

// Does the actual command parsing.
function parseTokens(pf, ar) {
        // What the next argument is expected to be.
        var v, i, mode=-1, par = (pf != 'ol_');
        var fnMark = (par && !ar.length ? 1 : 0);

        for (i = 0; i < ar.length; i++) {
                if (mode < 0) {
                        // Arg is maintext,unless its a number between pmStart and pmUpper
                        // then its a command.
                        if (typeof ar[i] == 'number' && ar[i] > pmStart && ar[i] < pmUpper) {
                                fnMark = (par ? 1 : 0);
                                i--;   // backup one so that the next block can parse it
                        } else {
                                switch(pf) {
                                        case 'ol_':
                                                ol_text = ar[i].toString();
                                                break;
                                        default:
                                                o3_text=ar[i].toString();
                                }
                        }
                        mode = 0;
                } else {
                        // Note: NS4 doesn't like switch cases with vars.
                        if (ar[i] >= pmCount || ar[i]==DONOTHING) { continue; }
                        if (ar[i]==INARRAY) { fnMark = 0; eval(pf+'text=ol_texts['+ar[++i]+'].toString()'); continue; }
                        if (ar[i]==CAPARRAY) { eval(pf+'cap=ol_caps['+ar[++i]+'].toString()'); continue; }
                        if (ar[i]==STICKY) { if (pf!='ol_') eval(pf+'sticky=1'); continue; }
                        if (ar[i]==BACKGROUND) { eval(pf+'background="'+ar[++i]+'"'); continue; }
                        if (ar[i]==NOCLOSE) { if (pf!='ol_') opt_NOCLOSE(); continue; }
                        if (ar[i]==CAPTION) { eval(pf+"cap='"+escSglQuote(ar[++i])+"'"); continue; }
                        if (ar[i]==CENTER || ar[i]==LEFT || ar[i]==RIGHT) { eval(pf+'hpos='+ar[i]); if(pf!='ol_') olHautoFlag=1; continue; }
                        if (ar[i]==OFFSETX) { eval(pf+'offsetx='+ar[++i]); continue; }
                        if (ar[i]==OFFSETY) { eval(pf+'offsety='+ar[++i]); continue; }
                        if (ar[i]==FGCOLOR) { eval(pf+'fgcolor="'+ar[++i]+'"'); continue; }
                        if (ar[i]==BGCOLOR) { eval(pf+'bgcolor="'+ar[++i]+'"'); continue; }
                        if (ar[i]==TEXTCOLOR) { eval(pf+'textcolor="'+ar[++i]+'"'); continue; }
                        if (ar[i]==CAPCOLOR) { eval(pf+'capcolor="'+ar[++i]+'"'); continue; }
                        if (ar[i]==CLOSECOLOR) { eval(pf+'closecolor="'+ar[++i]+'"'); continue; }
                        if (ar[i]==WIDTH) { eval(pf+'width='+ar[++i]); continue; }
                        if (ar[i]==BORDER) { eval(pf+'border='+ar[++i]); continue; }
                        if (ar[i]==CELLPAD) { i=opt_MULTIPLEARGS(++i,ar,(pf+'cellpad')); continue; }
                        if (ar[i]==STATUS) { eval(pf+"status='"+escSglQuote(ar[++i])+"'"); continue; }
                        if (ar[i]==AUTOSTATUS) { eval(pf +'autostatus=('+pf+'autostatus == 1) ? 0 : 1'); continue; }
                        if (ar[i]==AUTOSTATUSCAP) { eval(pf +'autostatus=('+pf+'autostatus == 2) ? 0 : 2'); continue; }
                        if (ar[i]==HEIGHT) { eval(pf+'height='+pf+'aboveheight='+ar[++i]); continue; } // Same param again.
                        if (ar[i]==CLOSETEXT) { eval(pf+"close='"+escSglQuote(ar[++i])+"'"); continue; }
                        if (ar[i]==SNAPX) { eval(pf+'snapx='+ar[++i]); continue; }
                        if (ar[i]==SNAPY) { eval(pf+'snapy='+ar[++i]); continue; }
                        if (ar[i]==FIXX) { eval(pf+'fixx='+ar[++i]); continue; }
                        if (ar[i]==FIXY) { eval(pf+'fixy='+ar[++i]); continue; }
                        if (ar[i]==RELX) { eval(pf+'relx='+ar[++i]); continue; }
                        if (ar[i]==RELY) { eval(pf+'rely='+ar[++i]); continue; }
                        if (ar[i]==FGBACKGROUND) { eval(pf+'fgbackground="'+ar[++i]+'"'); continue; }
                        if (ar[i]==BGBACKGROUND) { eval(pf+'bgbackground="'+ar[++i]+'"'); continue; }
                        if (ar[i]==PADX) { eval(pf+'padxl='+ar[++i]); eval(pf+'padxr='+ar[++i]); continue; }
                        if (ar[i]==PADY) { eval(pf+'padyt='+ar[++i]); eval(pf+'padyb='+ar[++i]); continue; }
                        if (ar[i]==FULLHTML) { if (pf!='ol_') eval(pf+'fullhtml=1'); continue; }
                        if (ar[i]==BELOW || ar[i]==ABOVE) { eval(pf+'vpos='+ar[i]); if (pf!='ol_') olVautoFlag=1; continue; }
                        if (ar[i]==CAPICON) { eval(pf+'capicon="'+ar[++i]+'"'); continue; }
                        if (ar[i]==TEXTFONT) { eval(pf+"textfont='"+escSglQuote(ar[++i])+"'"); continue; }
                        if (ar[i]==CAPTIONFONT) { eval(pf+"captionfont='"+escSglQuote(ar[++i])+"'"); continue; }
                        if (ar[i]==CLOSEFONT) { eval(pf+"closefont='"+escSglQuote(ar[++i])+"'"); continue; }
                        if (ar[i]==TEXTSIZE) { eval(pf+'textsize="'+ar[++i]+'"'); continue; }
                        if (ar[i]==CAPTIONSIZE) { eval(pf+'captionsize="'+ar[++i]+'"'); continue; }
                        if (ar[i]==CLOSESIZE) { eval(pf+'closesize="'+ar[++i]+'"'); continue; }
                        if (ar[i]==TIMEOUT) { eval(pf+'timeout='+ar[++i]); continue; }
                        if (ar[i]==FUNCTION) { if (pf=='ol_') { if (typeof ar[i+1]!='number') { v=ar[++i]; ol_function=(typeof v=='function' ? v : null); }} else {fnMark = 0; v = null; if (typeof ar[i+1]!='number') v = ar[++i];  opt_FUNCTION(v); } continue; }
                        if (ar[i]==DELAY) { eval(pf+'delay='+ar[++i]); continue; }
                        if (ar[i]==HAUTO) { eval(pf+'hauto=('+pf+'hauto == 0) ? 1 : 0'); continue; }
                        if (ar[i]==VAUTO) { eval(pf+'vauto=('+pf+'vauto == 0) ? 1 : 0'); continue; }
                        if (ar[i]==CLOSECLICK) { eval(pf +'closeclick=('+pf+'closeclick == 0) ? 1 : 0'); continue; }
                        if (ar[i]==WRAP) { eval(pf +'wrap=('+pf+'wrap == 0) ? 1 : 0'); continue; }
                        if (ar[i]==FOLLOWMOUSE) { eval(pf +'followmouse=('+pf+'followmouse == 1) ? 0 : 1'); continue; }
                        if (ar[i]==MOUSEOFF) { eval(pf +'mouseoff=('+pf+'mouseoff==0) ? 1 : 0'); v=ar[i+1]; if (pf != 'ol_' && eval(pf+'mouseoff') && typeof v == 'number' && (v < pmStart || v > pmUpper)) olHideDelay=ar[++i]; continue; }
                        if (ar[i]==CLOSETITLE) { eval(pf+"closetitle='"+escSglQuote(ar[++i])+"'"); continue; }
                        if (ar[i]==CSSOFF||ar[i]==CSSCLASS) { eval(pf+'css='+ar[i]); continue; }
                        if (ar[i]==COMPATMODE) { eval(pf+'compatmode=('+pf+'compatmode==0) ? 1 : 0'); continue; }
                        if (ar[i]==FGCLASS) { eval(pf+'fgclass="'+ar[++i]+'"'); continue; }
                        if (ar[i]==BGCLASS) { eval(pf+'bgclass="'+ar[++i]+'"'); continue; }
                        if (ar[i]==TEXTFONTCLASS) { eval(pf+'textfontclass="'+ar[++i]+'"'); continue; }
                        if (ar[i]==CAPTIONFONTCLASS) { eval(pf+'captionfontclass="'+ar[++i]+'"'); continue; }
                        if (ar[i]==CLOSEFONTCLASS) { eval(pf+'closefontclass="'+ar[++i]+'"'); continue; }
                        i = parseCmdLine(pf, i, ar);
                }
        }

        if (fnMark && o3_function) o3_text = o3_function();

        if ((pf == 'o3_') && o3_wrap) {
                o3_width = 0;

                var tReg=/<.*\n*>/ig;
                if (!tReg.test(o3_text)) o3_text = o3_text.replace(/[ ]+/g, '&nbsp;');
                if (!tReg.test(o3_cap))o3_cap = o3_cap.replace(/[ ]+/g, '&nbsp;');
        }
        if ((pf == 'o3_') && o3_sticky) {
                if (!o3_close && (o3_frame != ol_frame)) o3_close = ol_close;
                if (o3_mouseoff && (o3_frame == ol_frame)) opt_NOCLOSE(' ');
        }
}


]';
  INSERT INTO ~~tool_repository_schema..sqli$_clob VALUES ('OVERLIB3', clob_text);

  clob_text := q'[

////////
// LAYER FUNCTIONS
////////

// Writes to a layer
function layerWrite(txt) {
        txt += "\n";
        if (olNs4) {
                var lyr = o3_frame.document.layers['overDiv'].document
                lyr.write(txt)
                lyr.close()
        } else if (typeof over.innerHTML != 'undefined') {
                if (olIe5 && isMac) over.innerHTML = '';
                over.innerHTML = txt;
        } else {
                range = o3_frame.document.createRange();
                range.setStartAfter(over);
                domfrag = range.createContextualFragment(txt);

                while (over.hasChildNodes()) {
                        over.removeChild(over.lastChild);
                }

                over.appendChild(domfrag);
        }
}

// Make an object visible
function showObject(obj) {
        runHook("showObject", FBEFORE);

        var theObj=(olNs4 ? obj : obj.style);
        theObj.visibility = 'visible';

        runHook("showObject", FAFTER);
}

// Hides an object
function hideObject(obj) {
        runHook("hideObject", FBEFORE);

        var theObj=(olNs4 ? obj : obj.style);
        if (olNs6 && olShowId>0) { clearTimeout(olShowId); olShowId=0; }
        theObj.visibility = 'hidden';
        theObj.top = theObj.left = ((olIe4&&!olOp) ? 0 : -10000) + (!olNs4 ? 'px' : 0);

        if (o3_timerid > 0) clearTimeout(o3_timerid);
        if (o3_delayid > 0) clearTimeout(o3_delayid);

        o3_timerid = 0;
        o3_delayid = 0;
        self.status = "";

        if (obj.onmouseout||obj.onmouseover) {
                if (olNs4) obj.releaseEvents(Event.MOUSEOUT || Event.MOUSEOVER);
                obj.onmouseout = obj.onmouseover = null;
        }

        runHook("hideObject", FAFTER);
}

// Move a layer
function repositionTo(obj, xL, yL) {
        var theObj=(olNs4 ? obj : obj.style);
        theObj.left = xL + (!olNs4 ? 'px' : 0);
        theObj.top = yL + (!olNs4 ? 'px' : 0);
}

// Check position of cursor relative to overDiv DIVision; mouseOut function
function cursorOff() {
        var left = parseInt(over.style.left);
        var top = parseInt(over.style.top);
        var right = left + (over.offsetWidth >= parseInt(o3_width) ? over.offsetWidth : parseInt(o3_width));
        var bottom = top + (over.offsetHeight >= o3_aboveheight ? over.offsetHeight : o3_aboveheight);

        if (o3_x < left || o3_x > right || o3_y < top || o3_y > bottom) return true;

        return false;
}


////////
// COMMAND FUNCTIONS
////////

// Calls callme or the default function.
function opt_FUNCTION(callme) {
        o3_text = (callme ? (typeof callme=='string' ? (/.+\(.*\)/.test(callme) ? eval(callme) : callme) : callme()) : (o3_function ? o3_function() : 'No Function'));

        return 0;
}

// Handle hovering
function opt_NOCLOSE(unused) {
        if (!unused) o3_close = "";

        if (olNs4) {
                over.captureEvents(Event.MOUSEOUT || Event.MOUSEOVER);
                over.onmouseover = function () { if (o3_timerid > 0) { clearTimeout(o3_timerid); o3_timerid = 0; } }
                over.onmouseout = function (e) { if (olHideDelay) hideDelay(olHideDelay); else cClick(e); }
        } else {
                over.onmouseover = function () {hoveringSwitch = true; if (o3_timerid > 0) { clearTimeout(o3_timerid); o3_timerid =0; } }
        }

        return 0;
}

// Function to scan command line arguments for multiples
function opt_MULTIPLEARGS(i, args, parameter) {
  var k=i, re, pV, str='';

  for(k=i; k<args.length; k++) {
                if(typeof args[k] == 'number' && args[k]>pmStart) break;
                str += args[k] + ',';
        }
        if (str) str = str.substring(0,--str.length);

        k--;  // reduce by one so the for loop this is in works correctly
        pV=(olNs4 && /cellpad/i.test(parameter)) ? str.split(',')[0] : str;
        eval(parameter + '="' + pV + '"');

        return k;
}

// Remove &nbsp; in texts when done.
function nbspCleanup() {
        if (o3_wrap) {
                o3_text = o3_text.replace(/\&nbsp;/g, ' ');
                o3_cap = o3_cap.replace(/\&nbsp;/g, ' ');
        }
}

// Escape embedded single quotes in text strings
function escSglQuote(str) {
  return str.toString().replace(/'/g,"\\'");
}

// Onload handler for window onload event
function OLonLoad_handler(e) {
        var re = /\w+\(.*\)[;\s]+/g, olre = /overlib\(|nd\(|cClick\(/, fn, l, i;

        if(!olLoaded) olLoaded=1;

  // Remove it for Gecko based browsers
        if(window.removeEventListener && e.eventPhase == 3) window.removeEventListener("load",OLonLoad_handler,false);
        else if(window.detachEvent) { // and for IE and Opera 4.x but execute calls to overlib, nd, or cClick()
                window.detachEvent("onload",OLonLoad_handler);
                var fN = document.body.getAttribute('onload');
                if (fN) {
                        fN=fN.toString().match(re);
                        if (fN && fN.length) {
                                for (i=0; i<fN.length; i++) {
                                        if (/anonymous/.test(fN[i])) continue;
                                        while((l=fN[i].search(/\)[;\s]+/)) != -1) {
                                                fn=fN[i].substring(0,l+1);
                                                fN[i] = fN[i].substring(l+2);
                                                if (olre.test(fn)) eval(fn);
                                        }
                                }
                        }
                }
        }
}

// Wraps strings in Layer Generation Functions with the correct tags
//    endWrap true(if end tag) or false if start tag
//    fontSizeStr - font size string such as '1' or '10px'
//    whichString is being wrapped -- 'text', 'caption', or 'close'
function wrapStr(endWrap,fontSizeStr,whichString) {
        var fontStr, fontColor, isClose=((whichString=='close') ? 1 : 0), hasDims=/[%\-a-z]+$/.test(fontSizeStr);
        fontSizeStr = (olNs4) ? (!hasDims ? fontSizeStr : '1') : fontSizeStr;
        if (endWrap) return (hasDims&&!olNs4) ? (isClose ? '</span>' : '</div>') : '</font>';
        else {
                fontStr='o3_'+whichString+'font';
                fontColor='o3_'+((whichString=='caption')? 'cap' : whichString)+'color';
                return (hasDims&&!olNs4) ? (isClose ? '<span style="font-family: '+quoteMultiNameFonts(eval(fontStr))+'; color: '+eval(fontColor)+'; font-size: '+fontSizeStr+';">' : '<div style="font-family: '+quoteMultiNameFonts(eval(fontStr))+'; color: '+eval(fontColor)+'; font-size: '+fontSizeStr+';">') : '<font face="'+eval(fontStr)+'" color="'+eval(fontColor)+'" size="'+(parseInt(fontSizeStr)>7 ? '7' : fontSizeStr)+'">';
        }
}

// Quotes Multi word font names; needed for CSS Standards adherence in font-family
function quoteMultiNameFonts(theFont) {
        var v, pM=theFont.split(',');
        for (var i=0; i<pM.length; i++) {
                v=pM[i];
                v=v.replace(/^\s+/,'').replace(/\s+$/,'');
                if(/\s/.test(v) && !/['"]/.test(v)) {
                        v="\'"+v+"\'";
                        pM[i]=v;
                }
        }
        return pM.join();
}

// dummy function which will be overridden
function isExclusive(args) {
        return false;
}

// Sets cellpadding style string value
function setCellPadStr(parameter) {
        var Str='', j=0, ary = new Array(), top, bottom, left, right;

        Str+='padding: ';
        ary=parameter.replace(/\s+/g,'').split(',');

        switch(ary.length) {
                case 2:
                        top=bottom=ary[j];
                        left=right=ary[++j];
                        break;
                case 3:
                        top=ary[j];
                        left=right=ary[++j];
                        bottom=ary[++j];
                        break;
                case 4:
                        top=ary[j];
                        right=ary[++j];
                        bottom=ary[++j];
                        left=ary[++j];
                        break;
        }

        Str+= ((ary.length==1) ? ary[0] + 'px;' : top + 'px ' + right + 'px ' + bottom + 'px ' + left + 'px;');

        return Str;
}

// function will delay close by time milliseconds
function hideDelay(time) {
        if (time&&!o3_delay) {
                if (o3_timerid > 0) clearTimeout(o3_timerid);

                o3_timerid=setTimeout("cClick()",(o3_timeout=time));
        }
}

// Was originally in the placeLayer() routine; separated out for future ease
function horizontalPlacement(browserWidth, horizontalScrollAmount, widthFix) {
        var placeX, iwidth=browserWidth, winoffset=horizontalScrollAmount;
        var parsedWidth = parseInt(o3_width);

        if (o3_fixx > -1 || o3_relx != null) {
                // Fixed position
                placeX=(o3_relx != null ? ( o3_relx < 0 ? winoffset +o3_relx+ iwidth - parsedWidth - widthFix : winoffset+o3_relx) : o3_fixx);
        } else {
                // If HAUTO, decide what to use.
                if (o3_hauto == 1) {
                        if ((o3_x - winoffset) > (iwidth / 2)) {
                                o3_hpos = LEFT;
                        } else {
                                o3_hpos = RIGHT;
                        }
                }

                // From mouse
                if (o3_hpos == CENTER) { // Center
                        placeX = o3_x+o3_offsetx-(parsedWidth/2);

                        if (placeX < winoffset) placeX = winoffset;
                }

                if (o3_hpos == RIGHT) { // Right
                        placeX = o3_x+o3_offsetx;

                        if ((placeX+parsedWidth) > (winoffset+iwidth - widthFix)) {
                                placeX = iwidth+winoffset - parsedWidth - widthFix;
                                if (placeX < 0) placeX = 0;
                        }
                }
                if (o3_hpos == LEFT) { // Left
                        placeX = o3_x-o3_offsetx-parsedWidth;
                        if (placeX < winoffset) placeX = winoffset;
                }

                // Snapping!
                if (o3_snapx > 1) {
                        var snapping = placeX % o3_snapx;

                        if (o3_hpos == LEFT) {
                                placeX = placeX - (o3_snapx+snapping);
                        } else {
                                // CENTER and RIGHT
                                placeX = placeX+(o3_snapx - snapping);
                        }

                        if (placeX < winoffset) placeX = winoffset;
                }
        }

        return placeX;
}

// was originally in the placeLayer() routine; separated out for future ease
function verticalPlacement(browserHeight,verticalScrollAmount) {
        var placeY, iheight=browserHeight, scrolloffset=verticalScrollAmount;
        var parsedHeight=(o3_aboveheight ? parseInt(o3_aboveheight) : (olNs4 ? over.clip.height : over.offsetHeight));

        if (o3_fixy > -1 || o3_rely != null) {
                // Fixed position
                placeY=(o3_rely != null ? (o3_rely < 0 ? scrolloffset+o3_rely+iheight - parsedHeight : scrolloffset+o3_rely) : o3_fixy);
        } else {
                // If VAUTO, decide what to use.
                if (o3_vauto == 1) {
                        if ((o3_y - scrolloffset) > (iheight / 2) && o3_vpos == BELOW && (o3_y + parsedHeight + o3_offsety - (scrolloffset + iheight) > 0)) {
                                o3_vpos = ABOVE;
                        } else if (o3_vpos == ABOVE && (o3_y - (parsedHeight + o3_offsety) - scrolloffset < 0)) {
                                o3_vpos = BELOW;
                        }
                }

                // From mouse
                if (o3_vpos == ABOVE) {
                        if (o3_aboveheight == 0) o3_aboveheight = parsedHeight;

                        placeY = o3_y - (o3_aboveheight+o3_offsety);
                        if (placeY < scrolloffset) placeY = scrolloffset;
                } else {
                        // BELOW
                        placeY = o3_y+o3_offsety;
                }

                // Snapping!
                if (o3_snapy > 1) {
                        var snapping = placeY % o3_snapy;

                        if (o3_aboveheight > 0 && o3_vpos == ABOVE) {
                                placeY = placeY - (o3_snapy+snapping);
                        } else {
                                placeY = placeY+(o3_snapy - snapping);
                        }

                        if (placeY < scrolloffset) placeY = scrolloffset;
                }
        }

        return placeY;
}

// checks positioning flags
function checkPositionFlags() {
        if (olHautoFlag) olHautoFlag = o3_hauto=0;
        if (olVautoFlag) olVautoFlag = o3_vauto=0;
        return true;
}

// get Browser window width
function windowWidth() {
        var w;
        if (o3_frame.innerWidth) w=o3_frame.innerWidth;
        else if (eval('o3_frame.'+docRoot)&&eval("typeof o3_frame."+docRoot+".clientWidth=='number'")&&eval('o3_frame.'+docRoot+'.clientWidth'))
                w=eval('o3_frame.'+docRoot+'.clientWidth');
        return w;
}

// create the div container for popup content if it doesn't exist
function createDivContainer(id,frm,zValue) {
        id = (id || 'overDiv'), frm = (frm || o3_frame), zValue = (zValue || 1000);
        var objRef, divContainer = layerReference(id);

        if (divContainer == null) {
                if (olNs4) {
                        divContainer = frm.document.layers[id] = new Layer(window.innerWidth, frm);
                        objRef = divContainer;
                } else {
                        var body = (olIe4 ? frm.document.all.tags('BODY')[0] : frm.document.getElementsByTagName("BODY")[0]);
                        if (olIe4&&!document.getElementById) {
                                body.insertAdjacentHTML("beforeEnd",'<div id="'+id+'"></div>');
                                divContainer=layerReference(id);
                        } else {
                                divContainer = frm.document.createElement("DIV");
                                divContainer.id = id;
                                body.appendChild(divContainer);
                        }
                        objRef = divContainer.style;
                }

                objRef.position = 'absolute';
                objRef.visibility = 'hidden';
                objRef.zIndex = zValue;
                if (olIe4&&!olOp) objRef.left = objRef.top = '0px';
                else objRef.left = objRef.top =  -10000 + (!olNs4 ? 'px' : 0);
        }

        return divContainer;
}

// get reference to a layer with ID=id
function layerReference(id) {
        return (olNs4 ? o3_frame.document.layers[id] : (document.all ? o3_frame.document.all[id] : o3_frame.document.getElementById(id)));
}
////////
//  UTILITY FUNCTIONS
////////

// Checks if something is a function.
function isFunction(fnRef) {
        var rtn = true;

        if (typeof fnRef == 'object') {
                for (var i = 0; i < fnRef.length; i++) {
                        if (typeof fnRef[i]=='function') continue;
                        rtn = false;
                        break;
                }
        } else if (typeof fnRef != 'function') {
                rtn = false;
        }

        return rtn;
}

// Converts an array into an argument string for use in eval.
function argToString(array, strtInd, argName) {
        var jS = strtInd, aS = '', ar = array;
        argName=(argName ? argName : 'ar');

        if (ar.length > jS) {
                for (var k = jS; k < ar.length; k++) aS += argName+'['+k+'], ';
                aS = aS.substring(0, aS.length-2);
        }

        return aS;
}

// Places a hook in the correct position in a hook point.
function reOrder(hookPt, fnRef, order) {
        var newPt = new Array(), match, i, j;

        if (!order || typeof order == 'undefined' || typeof order == 'number') return hookPt;

        if (typeof order=='function') {
                if (typeof fnRef=='object') {
                        newPt = newPt.concat(fnRef);
                } else {
                        newPt[newPt.length++]=fnRef;
                }

                for (i = 0; i < hookPt.length; i++) {
                        match = false;
                        if (typeof fnRef == 'function' && hookPt[i] == fnRef) {
                                continue;
                        } else {
                                for(j = 0; j < fnRef.length; j++) if (hookPt[i] == fnRef[j]) {
                                        match = true;
                                        break;
                                }
                        }
                        if (!match) newPt[newPt.length++] = hookPt[i];
                }

                newPt[newPt.length++] = order;

        } else if (typeof order == 'object') {
                if (typeof fnRef == 'object') {
                        newPt = newPt.concat(fnRef);
                } else {
                        newPt[newPt.length++] = fnRef;
                }

                for (j = 0; j < hookPt.length; j++) {
                        match = false;
                        if (typeof fnRef == 'function' && hookPt[j] == fnRef) {
                                continue;
                        } else {
                                for (i = 0; i < fnRef.length; i++) if (hookPt[j] == fnRef[i]) {
                                        match = true;
                                        break;
                                }
                        }
                        if (!match) newPt[newPt.length++]=hookPt[j];
                }

                for (i = 0; i < newPt.length; i++) hookPt[i] = newPt[i];
                newPt.length = 0;

                for (j = 0; j < hookPt.length; j++) {
                        match = false;
                        for (i = 0; i < order.length; i++) {
                                if (hookPt[j] == order[i]) {
                                        match = true;
                                        break;
                                }
                        }
                        if (!match) newPt[newPt.length++] = hookPt[j];
                }
                newPt = newPt.concat(order);
        }

        hookPt = newPt;

        return hookPt;
}

]';
  INSERT INTO ~~tool_repository_schema..sqli$_clob VALUES ('OVERLIB4', clob_text);

  clob_text := q'[

////////
//  PLUGIN ACTIVATION FUNCTIONS
////////

// Runs plugin functions to set runtime variables.
function setRunTimeVariables(){
        if (typeof runTime != 'undefined' && runTime.length) {
                for (var k = 0; k < runTime.length; k++) {
                        runTime[k]();
                }
        }
}

// Runs plugin functions to parse commands.
function parseCmdLine(pf, i, args) {
        if (typeof cmdLine != 'undefined' && cmdLine.length) {
                for (var k = 0; k < cmdLine.length; k++) {
                        var j = cmdLine[k](pf, i, args);
                        if (j >- 1) {
                                i = j;
                                break;
                        }
                }
        }

        return i;
}

// Runs plugin functions to do things after parse.
function postParseChecks(pf,args){
        if (typeof postParse != 'undefined' && postParse.length) {
                for (var k = 0; k < postParse.length; k++) {
                        if (postParse[k](pf,args)) continue;
                        return false;  // end now since have an error
                }
        }
        return true;
}


////////
//  PLUGIN REGISTRATION FUNCTIONS
////////

// Registers commands and creates constants.
function registerCommands(cmdStr) {
        if (typeof cmdStr!='string') return;

        var pM = cmdStr.split(',');
        pms = pms.concat(pM);

        for (var i = 0; i< pM.length; i++) {
                eval(pM[i].toUpperCase()+'='+pmCount++);
        }
}

// Registers no-parameter commands
function registerNoParameterCommands(cmdStr) {
        if (!cmdStr && typeof cmdStr != 'string') return;
        pmt=(!pmt) ? cmdStr : pmt + ',' + cmdStr;
}

// Register a function to hook at a certain point.
function registerHook(fnHookTo, fnRef, hookType, optPm) {
        var hookPt, last = typeof optPm;

        if (fnHookTo == 'plgIn'||fnHookTo == 'postParse') return;
        if (typeof hookPts[fnHookTo] == 'undefined') hookPts[fnHookTo] = new FunctionReference();

        hookPt = hookPts[fnHookTo];

        if (hookType != null) {
                if (hookType == FREPLACE) {
                        hookPt.ovload = fnRef;  // replace normal overlib routine
                        if (fnHookTo.indexOf('ol_content_') > -1) hookPt.alt[pms[CSSOFF-1-pmStart]]=fnRef;

                } else if (hookType == FBEFORE || hookType == FAFTER) {
                        var hookPt=(hookType == 1 ? hookPt.before : hookPt.after);

                        if (typeof fnRef == 'object') {
                                hookPt = hookPt.concat(fnRef);
                        } else {
                                hookPt[hookPt.length++] = fnRef;
                        }

                        if (optPm) hookPt = reOrder(hookPt, fnRef, optPm);

                } else if (hookType == FALTERNATE) {
                        if (last=='number') hookPt.alt[pms[optPm-1-pmStart]] = fnRef;
                } else if (hookType == FCHAIN) {
                        hookPt = hookPt.chain;
                        if (typeof fnRef=='object') hookPt=hookPt.concat(fnRef); // add other functions
                        else hookPt[hookPt.length++]=fnRef;
                }

                return;
        }
}

// Register a function that will set runtime variables.
function registerRunTimeFunction(fn) {
        if (isFunction(fn)) {
                if (typeof fn == 'object') {
                        runTime = runTime.concat(fn);
                } else {
                        runTime[runTime.length++] = fn;
                }
        }
}

// Register a function that will handle command parsing.
function registerCmdLineFunction(fn){
        if (isFunction(fn)) {
                if (typeof fn == 'object') {
                        cmdLine = cmdLine.concat(fn);
                } else {
                        cmdLine[cmdLine.length++] = fn;
                }
        }
}

// Register a function that does things after command parsing.
function registerPostParseFunction(fn){
        if (isFunction(fn)) {
                if (typeof fn == 'object') {
                        postParse = postParse.concat(fn);
                } else {
                        postParse[postParse.length++] = fn;
                }
        }
}

////////
//  PLUGIN REGISTRATION FUNCTIONS
////////

// Runs any hooks registered.
function runHook(fnHookTo, hookType) {
        var l = hookPts[fnHookTo], k, rtnVal = null, optPm, arS, ar = runHook.arguments;

        if (hookType == FREPLACE) {
                arS = argToString(ar, 2);

                if (typeof l == 'undefined' || !(l = l.ovload)) rtnVal = eval(fnHookTo+'('+arS+')');
                else rtnVal = eval('l('+arS+')');

        } else if (hookType == FBEFORE || hookType == FAFTER) {
                if (typeof l != 'undefined') {
                        l=(hookType == 1 ? l.before : l.after);

                        if (l.length) {
                                arS = argToString(ar, 2);
                                for (var k = 0; k < l.length; k++) eval('l[k]('+arS+')');
                        }
                }
        } else if (hookType == FALTERNATE) {
                optPm = ar[2];
                arS = argToString(ar, 3);

                if (typeof l == 'undefined' || (l = l.alt[pms[optPm-1-pmStart]]) == 'undefined') {
                        rtnVal = eval(fnHookTo+'('+arS+')');
                } else {
                        rtnVal = eval('l('+arS+')');
                }
        } else if (hookType == FCHAIN) {
                arS=argToString(ar,2);
                l=l.chain;

                for (k=l.length; k > 0; k--) if((rtnVal=eval('l[k-1]('+arS+')'))!=void(0)) break;
        }

        return rtnVal;
}

////////
// OBJECT CONSTRUCTORS
////////

// Object for handling hooks.
function FunctionReference() {
        this.ovload = null;
        this.before = new Array();
        this.after = new Array();
        this.alt = new Array();
        this.chain = new Array();
}

// Object for simple access to the overLIB version used.
// Examples: simpleversion:351 major:3 minor:5 revision:1
function Info(version, prerelease) {
        this.version = version;
        this.prerelease = prerelease;

        this.simpleversion = Math.round(this.version*100);
        this.major = parseInt(this.simpleversion / 100);
        this.minor = parseInt(this.simpleversion / 10) - this.major * 10;
        this.revision = parseInt(this.simpleversion) - this.major * 100 - this.minor * 10;
        this.meets = meets;
}

// checks for Core Version required
function meets(reqdVersion) {
        return (!reqdVersion) ? false : this.simpleversion >= Math.round(100*parseFloat(reqdVersion));
}


////////
// STANDARD REGISTRATIONS
////////
registerHook("ol_content_simple", ol_content_simple, FALTERNATE, CSSOFF);
registerHook("ol_content_caption", ol_content_caption, FALTERNATE, CSSOFF);
registerHook("ol_content_background", ol_content_background, FALTERNATE, CSSOFF);
registerHook("ol_content_simple", ol_content_simple, FALTERNATE, CSSCLASS);
registerHook("ol_content_caption", ol_content_caption, FALTERNATE, CSSCLASS);
registerHook("ol_content_background", ol_content_background, FALTERNATE, CSSCLASS);
registerPostParseFunction(checkPositionFlags);
registerHook("hideObject", nbspCleanup, FAFTER);
registerHook("horizontalPlacement", horizontalPlacement, FCHAIN);
registerHook("verticalPlacement", verticalPlacement, FCHAIN);
if (olNs4||(olIe5&&isMac)||olKq) olLoaded=1;
registerNoParameterCommands('sticky,autostatus,autostatuscap,fullhtml,hauto,vauto,closeclick,wrap,followmouse,mouseoff,compatmode');
///////
// ESTABLISH MOUSECAPTURING
///////

// Capture events, alt. diffuses the overlib function.
var olCheckMouseCapture=true;
if ((olNs4 || olNs6 || olIe4)) {
        olMouseCapture();
} else {
        overlib = no_overlib;
        nd = no_overlib;
        ver3fix = true;
}
// overLIB (c) Erik Bosrup -->
</script>

</head>


<body>

<div id="overDiv" style="position:absolute; visibility:hidden; z-index:1000;"></div>

]';
  INSERT INTO ~~tool_repository_schema..sqli$_clob VALUES ('OVERLIB5', clob_text);

END; -- 716
/

/*------------------------------------------------------------------*/

VAR v_rdbms_release VARCHAR2(17);
VAR v_rdbms_version VARCHAR2(17);
VAR v_apps_release  VARCHAR2(50);

EXEC :v_rdbms_release := 'Unknown';
EXEC :v_rdbms_version := 'Unknown';
EXEC :v_apps_release  := 'Unknown';

BEGIN
  SELECT i.version
    INTO :v_rdbms_release
    FROM v$instance i;
END;
/

BEGIN
  :v_rdbms_version := :v_rdbms_release;
  IF :v_rdbms_release LIKE '11.2.%' THEN :v_rdbms_version := '11.2.X'; END IF;
  IF :v_rdbms_release LIKE '11.1.%' THEN :v_rdbms_version := '11.1.X'; END IF;
  IF :v_rdbms_release LIKE '10.2.%' THEN :v_rdbms_version := '10.2.X'; END IF;
  IF :v_rdbms_release LIKE '10.1.%' THEN :v_rdbms_version := '10.1.X'; END IF;
  IF :v_rdbms_release LIKE '9.2.0.%' THEN :v_rdbms_version := '9.2.0.X'; END IF;
  IF :v_rdbms_release LIKE '8.1.7.%' THEN :v_rdbms_version := '8.1.7.X'; END IF;
END;
/

BEGIN
  EXECUTE IMMEDIATE
  'SELECT release_name FROM applsys.fnd_product_groups WHERE ROWNUM = 1' INTO :v_apps_release;
EXCEPTION
  WHEN OTHERS THEN
    :v_apps_release := 'Unknown';
END;
/

CREATE OR REPLACE PROCEDURE ~~tool_administer_schema..chk$ebs$parameters (
  p_rdbms_version IN VARCHAR2,
  p_apps_release  IN VARCHAR2 )
IS
  my_sequence INTEGER := 0;

  PROCEDURE ins (
    p_version  IN VARCHAR2,
    p_name     IN VARCHAR2,
    p_set_flag IN VARCHAR2,
    p_mp_flag  IN VARCHAR2,
    p_sz_flag  IN VARCHAR2,
    p_cbo_flag IN VARCHAR2,
    p_value    IN VARCHAR2 )
  IS
    my_count INTEGER;
  BEGIN
    IF p_version <> 'COMMON' AND p_version <> p_rdbms_version THEN
      RETURN;
    END IF;

    SELECT COUNT(*)
      INTO my_count
      FROM ~~tool_repository_schema..chk$cbo$parameter_apps
     WHERE name = p_name;

    my_sequence := my_sequence + 1;

    IF my_count = 0 THEN
      INSERT INTO ~~tool_repository_schema..chk$cbo$parameter_apps VALUES (
        p_apps_release,
        p_version,
        my_sequence,
        p_name,
        p_set_flag,
        p_mp_flag,
        p_sz_flag,
        p_cbo_flag,
        p_value );
    ELSE
      UPDATE ~~tool_repository_schema..chk$cbo$parameter_apps SET
        release  = p_apps_release,
        version  = p_version,
        id       = my_sequence,
        set_flag = p_set_flag,
        mp_flag  = p_mp_flag,
        sz_flag  = p_sz_flag,
        cbo_flag = p_cbo_flag,
        value    = p_value
      WHERE name = p_name;
    END IF;
  END ins;

BEGIN

  IF NVL(p_rdbms_version, 'Unknown') = 'Unknown' OR NVL(p_apps_release, 'Unknown') = 'Unknown' THEN
    RETURN;
  END IF;

  IF p_apps_release LIKE '11%' THEN
    /*  version    name                               set  mp   sz   cbo  value                               */
    /*  ========== =============================      ===  ===  ===  ===  =================================== */
    ins('COMMON',  'db_name',                         'Y', 'N', 'N', 'N', 'prod11i');
    ins('COMMON',  'control_files',                   'Y', 'N', 'N', 'N', 'three copies of control file');
    ins('COMMON',  'db_block_size',                   'Y', 'Y', 'N', 'N', '8192');
    ins('COMMON',  '_system_trig_enabled',            'Y', 'Y', 'N', 'N', 'TRUE');
    IF p_apps_release IN ('11.5.1', '11.5.2', '11.5.3', '11.5.4', '11.5.5', '11.5.6', '11.5.7', '11.5.8', '11.5.9') THEN
      ins('COMMON',  'o7_dictionary_accessibility',   'Y', 'Y', 'N', 'N', 'TRUE');
    ELSE
      ins('COMMON',  'o7_dictionary_accessibility',   'Y', 'Y', 'N', 'N', 'FALSE');
    END IF;
    ins('COMMON',  'nls_language',                    'Y', 'N', 'N', 'N', 'AMERICAN');
    ins('COMMON',  'nls_territory',                   'Y', 'N', 'N', 'N', 'AMERICA');
    ins('COMMON',  'nls_date_format',                 'Y', 'Y', 'N', 'N', 'DD-MON-RR');
    ins('COMMON',  'nls_numeric_characters',          'Y', 'N', 'N', 'N', '".,"');
    ins('COMMON',  'nls_sort',                        'Y', 'Y', 'N', 'N', 'BINARY');
    ins('COMMON',  'nls_comp',                        'Y', 'Y', 'N', 'N', 'BINARY');
    ins('COMMON',  'audit_trail',                     'Y', 'N', 'N', 'N', 'TRUE (optional)');
    ins('COMMON',  'max_enabled_roles',               'Y', 'Y', 'N', 'N', '100');
    ins('COMMON',  'user_dump_dest',                  'Y', 'N', 'N', 'N', '?/prod11i/udump');
    ins('COMMON',  'background_dump_dest',            'Y', 'N', 'N', 'N', '?/prod11i/bdump');
    ins('COMMON',  'core_dump_dest',                  'Y', 'N', 'N', 'N', '?/prod11i/cdump');
    ins('COMMON',  'max_dump_file_size',              'Y', 'N', 'N', 'N', '20480');
    ins('COMMON',  'timed_statistics',                'Y', 'N', 'N', 'N', 'TRUE');
    ins('COMMON',  '_trace_files_public',             'Y', 'N', 'N', 'N', 'TRUE');
    ins('COMMON',  'sql_trace',                       'Y', 'N', 'N', 'N', 'FALSE');
    ins('COMMON',  'processes',                       'Y', 'N', 'Y', 'N', '200-2500');
    ins('COMMON',  'sessions',                        'Y', 'N', 'Y', 'N', '400-5000');
    ins('COMMON',  'db_files',                        'Y', 'N', 'N', 'N', '512');
    ins('COMMON',  'dml_locks',                       'Y', 'N', 'N', 'N', '10000');
    ins('COMMON',  'enqueue_resources',               'Y', 'N', 'N', 'N', '32000');
    ins('COMMON',  'cursor_sharing',                  'Y', 'Y', 'N', 'Y', 'EXACT');
    ins('COMMON',  'open_cursors',                    'Y', 'N', 'N', 'N', '600');
    ins('COMMON',  'session_cached_cursors',          'Y', 'N', 'N', 'N', '200');
    ins('COMMON',  'db_block_buffers',                'Y', 'N', 'Y', 'N', '20000-400000');
    ins('COMMON',  'db_block_checking',               'Y', 'N', 'N', 'N', 'FALSE');
    ins('COMMON',  'db_block_checksum',               'Y', 'N', 'N', 'N', 'TRUE');
    ins('COMMON',  'log_checkpoint_timeout',          'Y', 'N', 'N', 'N', '1200');
    ins('COMMON',  'log_checkpoint_interval',         'Y', 'N', 'N', 'N', '100000');
    ins('COMMON',  'log_buffer',                      'Y', 'N', 'N', 'N', '10485760');
    ins('COMMON',  'log_checkpoints_to_alert',        'Y', 'N', 'N', 'N', 'TRUE');
    ins('COMMON',  'shared_pool_size',                'Y', 'N', 'Y', 'N', '400-3000M');
    ins('COMMON',  'shared_pool_reserved_size',       'Y', 'N', 'Y', 'N', '40-300M');
    ins('COMMON',  '_shared_pool_reserved_min_alloc', 'Y', 'N', 'N', 'N', '4100');
    ins('COMMON',  'cursor_space_for_time',           'Y', 'N', 'N', 'N', 'FALSE (default)');
    ins('COMMON',  'java_pool_size',                  'Y', 'N', 'N', 'N', '50M');
    ins('COMMON',  'utl_file_dir',                    'Y', 'N', 'N', 'N', '?/prod11i/utl_file_dir');
    ins('COMMON',  'aq_tm_processes',                 'Y', 'N', 'N', 'N', '1');
    ins('COMMON',  'job_queue_processes',             'Y', 'N', 'N', 'N', '2');
    ins('COMMON',  'log_archive_start',               'Y', 'N', 'N', 'N', 'TRUE (optional)');
    ins('COMMON',  'parallel_max_servers',            'Y', 'N', 'N', 'N', '8 (up to 2*CPUs)');
    ins('COMMON',  'parallel_min_servers',            'Y', 'N', 'N', 'N', '0');
    ins('COMMON',  'db_file_multiblock_read_count',   'Y', 'Y', 'N', 'Y', '8');
    ins('COMMON',  'optimizer_max_permutations',      'Y', 'Y', 'N', 'Y', '2000');
    ins('COMMON',  'query_rewrite_enabled',           'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('COMMON',  '_sort_elimination_cost_ratio',    'Y', 'Y', 'N', 'Y', '5');
    ins('COMMON',  '_like_with_bind_as_equality',     'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('COMMON',  '_fast_full_scan_enabled',         'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('COMMON',  '_sqlexec_progression_cost',       'Y', 'Y', 'N', 'Y', '2147483647');
    ins('COMMON',  'max_commit_propagation_delay',    'Y', 'Y', 'N', 'N', '0 (if using RAC)');
    ins('COMMON',  'cluster_database',                'Y', 'Y', 'N', 'N', 'TRUE (if using RAC)');
    ins('COMMON',  'instance_groups',                 'Y', 'N', 'N', 'N', 'appsN (N is inst_id if using RAC)');
    ins('COMMON',  'parallel_instance_group',         'Y', 'N', 'N', 'N', 'appsN (N is inst_id if using RAC)');
    /* Release-specific database initialization parameters for 8iR3 (8.1.7.X) */
    ins('8.1.7.X', 'compatible',                      'Y', 'Y', 'N', 'N', '8.1.7');
    ins('8.1.7.X', 'rollback_segments',               'Y', 'N', 'N', 'N', '(rbs1,rbs2,rbs3,rbs4,rbs5,rbs6)');
    ins('8.1.7.X', 'sort_area_size',                  'Y', 'N', 'N', 'Y', '1048576');
    ins('8.1.7.X', 'hash_area_size',                  'Y', 'N', 'N', 'Y', '2097152');
    ins('8.1.7.X', 'job_queue_interval',              'Y', 'N', 'N', 'N', '90');
    ins('8.1.7.X', 'optimizer_features_enable',       'Y', 'Y', 'N', 'Y', '8.1.7');
    ins('8.1.7.X', '_optimizer_undo_changes',         'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('8.1.7.X', '_optimizer_mode_force',           'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('8.1.7.X', '_complex_view_merging',           'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('8.1.7.X', '_push_join_predicate',            'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('8.1.7.X', '_use_column_stats_for_function',  'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('8.1.7.X', '_or_expand_nvl_predicate',        'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('8.1.7.X', '_push_join_union_view',           'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('8.1.7.X', '_table_scan_cost_plus_one',       'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('8.1.7.X', '_ordered_nested_loop',            'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('8.1.7.X', '_new_initial_join_orders',        'Y', 'Y', 'N', 'Y', 'TRUE');
    /* Removal list for 8iR3 (8.1.7.X) */
    ins('8.1.7.X', '_b_tree_bitmap_plans',            'N', 'N', 'N', 'Y', NULL);
    ins('8.1.7.X', '_unnest_subquery',                'N', 'N', 'N', 'Y', NULL);
    ins('8.1.7.X', '_sortmerge_inequality_join_off',  'N', 'N', 'N', 'Y', NULL);
    ins('8.1.7.X', '_index_join_enabled',             'N', 'N', 'N', 'Y', NULL);
    ins('8.1.7.X', 'always_anti_join',                'N', 'N', 'N', 'Y', NULL);
    ins('8.1.7.X', 'always_semi_join',                'N', 'N', 'N', 'Y', NULL);
    ins('8.1.7.X', 'event="10943 trace name context forever, level 2"', 'N', 'N', 'N', 'N', NULL);
    ins('8.1.7.X', 'event="10929 trace name context forever"',          'N', 'N', 'N', 'N', NULL);
    ins('8.1.7.X', 'event="10932 trace name context level 2"',          'N', 'N', 'N', 'N', NULL);
    ins('8.1.7.X', 'optimizer_percent_parallel',      'N', 'N', 'N', 'Y', NULL);
    ins('8.1.7.X', 'optimizer_mode',                  'N', 'N', 'N', 'Y', NULL);
    ins('8.1.7.X', 'optimizer_index_caching',         'N', 'N', 'N', 'Y', NULL);
    ins('8.1.7.X', 'optimizer_index_cost_adj',        'N', 'N', 'N', 'Y', NULL);
    /* Release-specific database initialization parameters for 9iR2 (9.2.0.X) */
    ins('9.2.0.X', 'compatible',                      'Y', 'Y', 'N', 'N', '9.2.0');
    ins('9.2.0.X', 'db_cache_size',                   'Y', 'N', 'Y', 'N', '156M-3G');
    ins('9.2.0.X', 'nls_length_semantics',            'Y', 'Y', 'N', 'N', 'BYTE');
    ins('9.2.0.X', 'undo_management',                 'Y', 'Y', 'N', 'N', 'AUTO');
    ins('9.2.0.X', 'undo_retention',                  'Y', 'N', 'Y', 'N', '1800-14400');
    ins('9.2.0.X', 'undo_suppress_errors',            'Y', 'Y', 'N', 'N', 'FALSE');
    ins('9.2.0.X', 'undo_tablespace',                 'Y', 'Y', 'N', 'N', 'APPS_UNDOTS1');
    ins('9.2.0.X', 'pga_aggregate_target',            'Y', 'N', 'Y', 'Y', '1-20G');
    ins('9.2.0.X', 'workarea_size_policy',            'Y', 'Y', 'N', 'Y', 'AUTO');
    ins('9.2.0.X', 'olap_page_pool_size',             'Y', 'N', 'N', 'N', '4194304');
    IF p_apps_release IN ('11.5.5', '11.5.6', '11.5.7') THEN
      /* These events should only be used if you are using Oracle Applications release 11.5.7 or prior*/
      ins('9.2.0.X', 'event="10932 trace name context level 32768"', 'Y', 'N', 'N', 'N', NULL);
      ins('9.2.0.X', 'event="10933 trace name context level 512"',   'Y', 'N', 'N', 'N', NULL);
      ins('9.2.0.X', 'event="10943 trace name context level 16384"', 'Y', 'N', 'N', 'N', NULL);
    END IF;
    ins('9.2.0.X', 'optimizer_features_enable',       'Y', 'Y', 'N', 'Y', '9.2.0');
    ins('9.2.0.X', '_index_join_enabled',             'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('9.2.0.X', '_b_tree_bitmap_plans',            'Y', 'Y', 'N', 'Y', 'FALSE');
    /* Removal list for 9iR2 (9.2.0.X) */
    ins('9.2.0.X', 'always_anti_join',                'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', 'always_semi_join',                'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', 'db_block_buffers',                'N', 'N', 'N', 'N', NULL);
    ins('9.2.0.X', 'event="10943 trace name context forever, level 2"', 'N', 'N', 'N', 'N', NULL);
    ins('9.2.0.X', 'event="38004 trace name context forever, level 1"', 'N', 'N', 'N', 'N', NULL);
    ins('9.2.0.X', 'job_queue_interval',              'N', 'N', 'N', 'N', NULL);
    ins('9.2.0.X', 'optimizer_percent_parallel',      'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_complex_view_merging',           'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_new_initial_join_orders',        'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_optimizer_mode_force',           'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_optimizer_undo_changes',         'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_or_expand_nvl_predicate',        'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_ordered_nested_loop',            'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_push_join_predicate',            'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_push_join_union_view',           'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_use_column_stats_for_function',  'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_unnest_subquery',                'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_sortmerge_inequality_join_off',  'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_table_scan_cost_plus_one',       'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_always_anti_join',               'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', '_always_semi_join',               'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', 'hash_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', 'sort_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', 'optimizer_mode',                  'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', 'optimizer_index_caching',         'N', 'N', 'N', 'Y', NULL);
    ins('9.2.0.X', 'optimizer_index_cost_adj',        'N', 'N', 'N', 'Y', NULL);
    IF p_apps_release NOT IN ('11.5.1', '11.5.2', '11.5.3', '11.5.4', '11.5.5', '11.5.6', '11.5.7') THEN
    /* Remove the following events only if you are using Oracle Applications release 11.5.8 or later. */
      ins('9.2.0.X', 'event="10932 trace name context level 32768"', 'N', 'N', 'N', 'N', NULL);
      ins('9.2.0.X', 'event="10933 trace name context level 512"',   'N', 'N', 'N', 'N', NULL);
      ins('9.2.0.X', 'event="10943 trace name context level 16384"', 'N', 'N', 'N', 'N', NULL);
    END IF;
    /* Release-specific database initialization parameters for 10gR1 (10.1.X) */
    ins('10.1.X',  'compatible',                      'Y', 'Y', 'N', 'N', '10.1.0');
    ins('10.1.X',  'sga_target',                      'Y', 'N', 'Y', 'N', '1-14G');
    ins('10.1.X',  'shared_pool_size',                'Y', 'N', 'Y', 'N', '400-3000M');
    ins('10.1.X',  'shared_pool_reserved_size',       'Y', 'N', 'Y', 'N', '40-300M');
    ins('10.1.X',  'nls_length_semantics',            'Y', 'Y', 'N', 'N', 'BYTE');
    ins('10.1.X',  'undo_management',                 'Y', 'Y', 'N', 'N', 'AUTO');
    ins('10.1.X',  'undo_tablespace',                 'Y', 'Y', 'N', 'N', 'APPS_UNDOTS1');
    ins('10.1.X',  'pga_aggregate_target',            'Y', 'N', 'Y', 'Y', '1-20G');
    ins('10.1.X',  'workarea_size_policy',            'Y', 'Y', 'N', 'Y', 'AUTO');
    ins('10.1.X',  'olap_page_pool_size',             'Y', 'N', 'N', 'N', '4194304');
    ins('10.1.X',  'open_cursors',                    'Y', 'N', 'N', 'N', '600');
    ins('10.1.X',  'session_cached_cursors',          'Y', 'N', 'N', 'N', '500');
    ins('10.1.X',  'plsql_optimize_level',            'Y', 'Y', 'N', 'N', '2');
    ins('10.1.X',  'plsql_code_type',                 'Y', 'N', 'N', 'N', 'INTERPRETED');
    ins('10.1.X',  'plsql_native_library_dir',        'Y', 'N', 'N', 'N', '?/prod11i/plsql_nativelib (if using NATIVE PL/SQL)');
    ins('10.1.X',  'plsql_native_library_subdir_count', 'Y', 'N', 'N', 'N', '149 (if using NATIVE PL/SQL)');
    ins('10.1.X',  '_b_tree_bitmap_plans',            'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('10.1.X',  'aq_tm_processes',                 'Y', 'N', 'N', 'N', '1');
    /* Removal list for 10gR1 (10.1.X) */
    ins('10.1.X',  'always_anti_join',                'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'always_semi_join',                'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'db_block_buffers',                'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'db_cache_size',                   'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'large_pool_size',                 'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'row_locking',                     'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'max_enabled_roles',               'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  '_shared_pool_reserved_min_alloc', 'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'java_pool_size',                  'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'event="10943 trace name context forever, level 2"', 'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'event="38004 trace name context forever, level 1"', 'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'event="10932 trace name context level 32768"',      'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'event="10933 trace name context level 512"',        'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'event="10943 trace name context level 16384"',      'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'job_queue_interval',              'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'optimizer_percent_parallel',      'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_complex_view_merging',           'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_new_initial_join_orders',        'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_optimizer_mode_force',           'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_optimizer_undo_changes',         'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_or_expand_nvl_predicate',        'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_ordered_nested_loop',            'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_push_join_predicate',            'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_push_join_union_view',           'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_use_column_stats_for_function',  'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_table_scan_cost_plus_one',       'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_unnest_subquery',                'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_sortmerge_inequality_join_off',  'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_index_join_enabled',             'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_always_anti_join',               'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_always_semi_join',               'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'hash_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'sort_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'optimizer_mode',                  'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'optimizer_index_caching',         'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'optimizer_index_cost_adj',        'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'optimizer_max_permutations',      'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'optimizer_dynamic_sampling',      'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'optimizer_features_enable',       'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  'undo_suppress_errors',            'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'plsql_compiler_flags',            'N', 'N', 'N', 'N', NULL);
    ins('10.1.X',  'query_rewrite_enabled',           'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_optimizer_cost_model',           'N', 'N', 'N', 'Y', NULL);
    ins('10.1.X',  '_optimizer_cost_based_transformation', 'N', 'N', 'N', 'Y', NULL);
    /* Release-specific database initialization parameters for 10gR2 (10.2.X) */
    ins('10.2.X',  'compatible',                      'Y', 'Y', 'N', 'N', '10.2.0');
    ins('10.2.X',  'sga_target',                      'Y', 'N', 'Y', 'N', '1-14G');
    ins('10.2.X',  'shared_pool_size',                'Y', 'N', 'Y', 'N', '400-3000M');
    ins('10.2.X',  'shared_pool_reserved_size',       'Y', 'N', 'Y', 'N', '40-300M');
    ins('10.2.X',  'nls_length_semantics',            'Y', 'Y', 'N', 'N', 'BYTE');
    ins('10.2.X',  'undo_management',                 'Y', 'Y', 'N', 'N', 'AUTO');
    ins('10.2.X',  'undo_tablespace',                 'Y', 'Y', 'N', 'N', 'APPS_UNDOTS1');
    ins('10.2.X',  'pga_aggregate_target',            'Y', 'N', 'Y', 'Y', '1-20G');
    ins('10.2.X',  'workarea_size_policy',            'Y', 'Y', 'N', 'Y', 'AUTO');
    ins('10.2.X',  'olap_page_pool_size',             'Y', 'N', 'N', 'N', '4194304');
    ins('10.2.X',  'open_cursors',                    'Y', 'N', 'N', 'N', '600');
    ins('10.2.X',  'session_cached_cursors',          'Y', 'N', 'N', 'N', '500');
    ins('10.2.X',  'plsql_optimize_level',            'Y', 'Y', 'N', 'N', '2');
    ins('10.2.X',  'plsql_code_type',                 'Y', 'N', 'N', 'N', 'INTERPRETED');
    ins('10.2.X',  'plsql_native_library_dir',        'Y', 'N', 'N', 'N', '?/prod11i/plsql_nativelib (if using NATIVE PL/SQL)');
    ins('10.2.X',  'plsql_native_library_subdir_count', 'Y', 'N', 'N', 'N', '149 (if using NATIVE PL/SQL)');
    ins('10.2.X',  '_b_tree_bitmap_plans',            'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('10.2.X',  'optimizer_secure_view_merging',   'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('10.2.X',  '_kks_use_mutex_pin',              'Y', 'N', 'N', 'N', 'FALSE (only HP-UX PA-RISC)');
    ins('10.2.X',  'aq_tm_processes',                 'Y', 'N', 'N', 'N', '1');
    /* Removal list for 10gR2 (10.2.X) */
    ins('10.2.X',  '_always_anti_join',               'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_always_semi_join',               'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_complex_view_merging',           'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_index_join_enabled',             'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_kks_use_mutex_pin',              'N', 'N', 'N', 'N', 'Unless using HP-UX PA-RISC');
    ins('10.2.X',  '_new_initial_join_orders',        'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_optimizer_cost_based_transformation', 'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_optimizer_cost_model',           'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_optimizer_mode_force',           'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_optimizer_undo_changes',         'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_or_expand_nvl_predicate',        'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_ordered_nested_loop',            'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_push_join_predicate',            'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_push_join_union_view',           'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_shared_pool_reserved_min_alloc', 'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  '_sortmerge_inequality_join_off',  'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_table_scan_cost_plus_one',       'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_unnest_subquery',                'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_use_column_stats_for_function',  'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'always_anti_join',                'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'always_semi_join',                'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'db_block_buffers',                'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'db_file_multiblock_read_count',   'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'db_cache_size',                   'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'enqueue_resources',               'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'event="10932 trace name context level 32768"',      'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'event="10933 trace name context level 512"',        'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'event="10943 trace name context forever, level 2"', 'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'event="10943 trace name context level 16384"',      'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'event="38004 trace name context forever, level 1"', 'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'hash_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'java_pool_size',                  'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'job_queue_interval',              'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'large_pool_size',                 'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'max_enabled_roles',               'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'optimizer_dynamic_sampling',      'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_features_enable',       'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_index_caching',         'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_index_cost_adj',        'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_max_permutations',      'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_mode',                  'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_percent_parallel',      'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'plsql_compiler_flags',            'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'query_rewrite_enabled',           'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'row_locking',                     'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'sort_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'undo_retention',                  'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'undo_suppress_errors',            'N', 'N', 'N', 'N', NULL);
    /* Release-specific database initialization parameters for 11gR1 (11.1.X) */
    ins('11.1.X',  'compatible',                      'Y', 'Y', 'N', 'N', '11.1.0');
    ins('11.1.X',  'diagnostic_dest',                 'Y', 'N', 'N', 'N', '?/prod11i');
    ins('11.1.X',  'sga_target',                      'Y', 'N', 'Y', 'N', '1-14G');
    ins('11.1.X',  'shared_pool_size',                'Y', 'N', 'Y', 'N', '400-3000M');
    ins('11.1.X',  'shared_pool_reserved_size',       'Y', 'N', 'Y', 'N', '40-300M');
    ins('11.1.X',  'nls_length_semantics',            'Y', 'Y', 'N', 'N', 'BYTE');
    ins('11.1.X',  'undo_management',                 'Y', 'Y', 'N', 'N', 'AUTO');
    ins('11.1.X',  'undo_tablespace',                 'Y', 'Y', 'N', 'N', 'APPS_UNDOTS1');
    ins('11.1.X',  'pga_aggregate_target',            'Y', 'N', 'Y', 'Y', '1-20G');
    ins('11.1.X',  'workarea_size_policy',            'Y', 'Y', 'N', 'Y', 'AUTO');
    ins('11.1.X',  'olap_page_pool_size',             'Y', 'N', 'N', 'N', '4194304');
    ins('11.1.X',  'open_cursors',                    'Y', 'N', 'N', 'N', '600');
    ins('11.1.X',  'session_cached_cursors',          'Y', 'N', 'N', 'N', '500');
    ins('11.1.X',  'plsql_code_type',                 'Y', 'Y', 'N', 'N', 'NATIVE (if you want to use NATIVE compilation)');
    ins('11.1.X',  '_b_tree_bitmap_plans',            'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('11.1.X',  'optimizer_secure_view_merging',   'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('11.1.X',  '_optimizer_autostats_job',        'Y', 'Y', 'N', 'N', 'FALSE');
    ins('11.1.X',  'sec_case_sensitive_logon',        'Y', 'Y', 'N', 'N', 'FALSE');
    ins('11.1.X',  'aq_tm_processes',                 'Y', 'N', 'N', 'N', '1');
    /* Removal list for 11gR1 (11.1.X) */
    ins('11.1.X',  '_always_anti_join',               'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_always_semi_join',               'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_complex_view_merging',           'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_index_join_enabled',             'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_kks_use_mutex_pin',              'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  '_new_initial_join_orders',        'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_optimizer_cost_based_transformation', 'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_optimizer_cost_model',           'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_optimizer_mode_force',           'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_optimizer_undo_changes',         'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_or_expand_nvl_predicate',        'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_ordered_nested_loop',            'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_push_join_predicate',            'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_push_join_union_view',           'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_shared_pool_reserved_min_alloc', 'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  '_sortmerge_inequality_join_off',  'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_sqlexec_progression_cost',       'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_table_scan_cost_plus_one',       'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_unnest_subquery',                'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_use_column_stats_for_function',  'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'always_anti_join',                'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'always_semi_join',                'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'background_dump_dest',            'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'core_dump_dest',                  'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'db_block_buffers',                'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'db_file_multiblock_read_count',   'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'db_cache_size',                   'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'enqueue_resources',               'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'event="10932 trace name context level 32768"',      'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'event="10933 trace name context level 512"',        'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'event="10943 trace name context forever, level 2"', 'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'event="10943 trace name context level 16384"',      'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'event="38004 trace name context forever, level 1"', 'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'hash_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'java_pool_size',                  'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'job_queue_interval',              'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'large_pool_size',                 'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'max_enabled_roles',               'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'nls_language',                    'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'optimizer_dynamic_sampling',      'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_features_enable',       'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_index_caching',         'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_index_cost_adj',        'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_max_permutations',      'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_mode',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_percent_parallel',      'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'plsql_optimize_level',            'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'plsql_compiler_flags',            'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'plsql_native_library_dir',        'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'plsql_native_library_subdir_count', 'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'query_rewrite_enabled',           'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'rollback_segments',               'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'row_locking',                     'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'sort_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'sql_trace',                       'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'timed_statistics',                'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'undo_retention',                  'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'undo_suppress_errors',            'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'user_dump_dest',                  'N', 'N', 'N', 'N', NULL);
    /* Release-specific database initialization parameters for 11gR2 (11.2.X) */
    ins('11.2.X',  'compatible',                      'Y', 'Y', 'N', 'N', '11.2.0');
    ins('11.2.X',  'diagnostic_dest',                 'Y', 'N', 'N', 'N', '?/prod11i');
    ins('11.2.X',  'sga_target',                      'Y', 'N', 'Y', 'N', '1-14G');
    ins('11.2.X',  'shared_pool_size',                'Y', 'N', 'Y', 'N', '400-3000M');
    ins('11.2.X',  'shared_pool_reserved_size',       'Y', 'N', 'Y', 'N', '40-300M');
    ins('11.2.X',  'nls_length_semantics',            'Y', 'Y', 'N', 'N', 'BYTE');
    ins('11.2.X',  'undo_management',                 'Y', 'Y', 'N', 'N', 'AUTO');
    ins('11.2.X',  'undo_tablespace',                 'Y', 'Y', 'N', 'N', 'APPS_UNDOTS1');
    ins('11.2.X',  'pga_aggregate_target',            'Y', 'N', 'Y', 'Y', '1-20G');
    ins('11.2.X',  'workarea_size_policy',            'Y', 'Y', 'N', 'Y', 'AUTO');
    ins('11.2.X',  'olap_page_pool_size',             'Y', 'N', 'N', 'N', '4194304');
    ins('11.2.X',  'open_cursors',                    'Y', 'N', 'N', 'N', '600');
    ins('11.2.X',  'session_cached_cursors',          'Y', 'N', 'N', 'N', '500');
    ins('11.2.X',  'plsql_code_type',                 'Y', 'Y', 'N', 'N', 'NATIVE (if you want to use NATIVE compilation)');
    ins('11.2.X',  '_b_tree_bitmap_plans',            'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('11.2.X',  'optimizer_secure_view_merging',   'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('11.2.X',  '_optimizer_autostats_job',        'Y', 'Y', 'N', 'N', 'FALSE');
    ins('11.2.X',  'sec_case_sensitive_logon',        'Y', 'Y', 'N', 'N', 'FALSE');
    ins('11.2.X',  'aq_tm_processes',                 'Y', 'N', 'N', 'N', '1');
    /* Removal list for 11gR2 (11.2.X) */
    ins('11.2.X',  '_always_anti_join',               'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_always_semi_join',               'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_complex_view_merging',           'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_index_join_enabled',             'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_kks_use_mutex_pin',              'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  '_new_initial_join_orders',        'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_optimizer_cost_based_transformation', 'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_optimizer_cost_model',           'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_optimizer_mode_force',           'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_optimizer_undo_changes',         'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_or_expand_nvl_predicate',        'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_ordered_nested_loop',            'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_push_join_predicate',            'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_push_join_union_view',           'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_shared_pool_reserved_min_alloc', 'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  '_sortmerge_inequality_join_off',  'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_sqlexec_progression_cost',       'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_table_scan_cost_plus_one',       'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_unnest_subquery',                'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_use_column_stats_for_function',  'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'always_anti_join',                'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'always_semi_join',                'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'background_dump_dest',            'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'core_dump_dest',                  'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'db_block_buffers',                'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'db_file_multiblock_read_count',   'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'db_cache_size',                   'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'enqueue_resources',               'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'event="10932 trace name context level 32768"',      'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'event="10933 trace name context level 512"',        'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'event="10943 trace name context forever, level 2"', 'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'event="10943 trace name context level 16384"',      'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'event="38004 trace name context forever, level 1"', 'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'hash_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'java_pool_size',                  'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'job_queue_interval',              'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'large_pool_size',                 'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'max_enabled_roles',               'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'nls_language',                    'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'optimizer_dynamic_sampling',      'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_features_enable',       'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_index_caching',         'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_index_cost_adj',        'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_max_permutations',      'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_mode',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_percent_parallel',      'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'plsql_optimize_level',            'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'plsql_compiler_flags',            'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'plsql_native_library_dir',        'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'plsql_native_library_subdir_count', 'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'query_rewrite_enabled',           'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'rollback_segments',               'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'row_locking',                     'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'sort_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'sql_trace',                       'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'timed_statistics',                'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'undo_retention',                  'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'undo_suppress_errors',            'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'user_dump_dest',                  'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'drs_start',                       'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'sql_version',                     'N', 'N', 'N', 'N', NULL);
  ELSIF p_apps_release LIKE '12%' THEN
    /*  version    name                               set  mp   sz   cbo  value                               */
    /*  ========== =============================      ===  ===  ===  ===  =================================== */
    ins('COMMON',  'db_name',                         'Y', 'N', 'N', 'N', 'prodr12');
    ins('COMMON',  'control_files',                   'Y', 'N', 'N', 'N', 'three copies of control file');
    ins('COMMON',  'db_block_size',                   'Y', 'Y', 'N', 'N', '8192');
    ins('COMMON',  '_system_trig_enabled',            'Y', 'Y', 'N', 'N', 'TRUE');
    ins('COMMON',  'o7_dictionary_accessibility',     'Y', 'Y', 'N', 'N', 'FALSE');
    ins('COMMON',  'nls_language',                    'Y', 'N', 'N', 'N', 'AMERICAN');
    ins('COMMON',  'nls_territory',                   'Y', 'N', 'N', 'N', 'AMERICA');
    ins('COMMON',  'nls_date_format',                 'Y', 'Y', 'N', 'N', 'DD-MON-RR');
    ins('COMMON',  'nls_numeric_characters',          'Y', 'N', 'N', 'N', '".,"');
    ins('COMMON',  'nls_sort',                        'Y', 'Y', 'N', 'N', 'BINARY');
    ins('COMMON',  'nls_comp',                        'Y', 'Y', 'N', 'N', 'BINARY');
    ins('COMMON',  'nls_length_semantics',            'Y', 'Y', 'N', 'N', 'BYTE');
    ins('COMMON',  'audit_trail',                     'Y', 'N', 'N', 'N', 'TRUE (optional)');
    ins('COMMON',  'user_dump_dest',                  'Y', 'N', 'N', 'N', '/ebiz/prodr12/udump');
    ins('COMMON',  'background_dump_dest',            'Y', 'N', 'N', 'N', '/ebiz/prodr12/bdump');
    ins('COMMON',  'core_dump_dest',                  'Y', 'N', 'N', 'N', '/ebiz/prodr12/cdump');
    ins('COMMON',  'max_dump_file_size',              'Y', 'N', 'N', 'N', '20480');
    ins('COMMON',  '_trace_files_public',             'Y', 'N', 'N', 'N', 'TRUE');
    ins('COMMON',  'processes',                       'Y', 'N', 'Y', 'N', '200-2500');
    ins('COMMON',  'sessions',                        'Y', 'N', 'Y', 'N', '400-5000');
    ins('COMMON',  'db_files',                        'Y', 'N', 'N', 'N', '512');
    ins('COMMON',  'dml_locks',                       'Y', 'N', 'N', 'N', '10000');
    ins('COMMON',  'cursor_sharing',                  'Y', 'Y', 'N', 'Y', 'EXACT');
    ins('COMMON',  'open_cursors',                    'Y', 'N', 'N', 'N', '600');
    ins('COMMON',  'session_cached_cursors',          'Y', 'N', 'N', 'N', '500');
    ins('COMMON',  'sga_target',                      'Y', 'N', 'Y', 'N', '2-14G');
    ins('COMMON',  'db_block_checking',               'Y', 'N', 'N', 'N', 'FALSE');
    ins('COMMON',  'db_block_checksum',               'Y', 'N', 'N', 'N', 'TRUE');
    ins('COMMON',  'log_checkpoint_timeout',          'Y', 'N', 'N', 'N', '1200');
    ins('COMMON',  'log_checkpoint_interval',         'Y', 'N', 'N', 'N', '100000');
    ins('COMMON',  'log_buffer',                      'Y', 'N', 'N', 'N', '10485760');
    ins('COMMON',  'log_checkpoints_to_alert',        'Y', 'N', 'N', 'N', 'TRUE');
    ins('COMMON',  'shared_pool_size',                'Y', 'N', 'Y', 'N', '600-3000M');
    ins('COMMON',  'shared_pool_reserved_size',       'Y', 'N', 'Y', 'N', '60-300M');
    ins('COMMON',  '_shared_pool_reserved_min_alloc', 'Y', 'N', 'N', 'N', '4100');
    ins('COMMON',  'cursor_space_for_time',           'Y', 'N', 'N', 'N', 'FALSE (default)');
    ins('COMMON',  'utl_file_dir',                    'Y', 'N', 'N', 'N', '/ebiz/prodr12/utl_file_dir');
    ins('COMMON',  'aq_tm_processes',                 'Y', 'N', 'N', 'N', '1');
    ins('COMMON',  'job_queue_processes',             'Y', 'N', 'N', 'N', '2');
    ins('COMMON',  'log_archive_start',               'Y', 'N', 'N', 'N', 'TRUE (optional)');
    ins('COMMON',  'parallel_max_servers',            'Y', 'N', 'N', 'N', '8 (up to 2*CPUs)');
    ins('COMMON',  'parallel_min_servers',            'Y', 'N', 'N', 'N', '0');
    ins('COMMON',  '_sort_elimination_cost_ratio',    'Y', 'Y', 'N', 'Y', '5');
    ins('COMMON',  '_like_with_bind_as_equality',     'Y', 'Y', 'N', 'Y', 'TRUE');
    ins('COMMON',  '_fast_full_scan_enabled',         'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('COMMON',  '_b_tree_bitmap_plans',            'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('COMMON',  'optimizer_secure_view_merging',   'Y', 'Y', 'N', 'Y', 'FALSE');
    ins('COMMON',  '_sqlexec_progression_cost',       'Y', 'Y', 'N', 'Y', '2147483647');
    ins('COMMON',  'max_commit_propagation_delay',    'Y', 'Y', 'N', 'N', '0 (if using RAC)');
    ins('COMMON',  'cluster_database',                'Y', 'Y', 'N', 'N', 'TRUE (if using RAC)');
    ins('COMMON',  'instance_groups',                 'Y', 'N', 'N', 'N', 'appsN (N is inst_id if using RAC)');
    ins('COMMON',  'parallel_instance_group',         'Y', 'N', 'N', 'N', 'appsN (N is inst_id if using RAC)');
    ins('COMMON',  'pga_aggregate_target',            'Y', 'N', 'Y', 'Y', '1-20G');
    ins('COMMON',  'workarea_size_policy',            'Y', 'Y', 'N', 'Y', 'AUTO');
    ins('COMMON',  'olap_page_pool_size',             'Y', 'N', 'N', 'N', '4194304');
    /* Release-specific database initialization parameters for 10gR2 (10.2.X) */
    ins('10.2.X',  'compatible',                      'Y', 'Y', 'N', 'N', '10.2.0');
    ins('10.2.X',  'undo_management',                 'Y', 'Y', 'N', 'N', 'AUTO');
    ins('10.2.X',  'undo_tablespace',                 'Y', 'Y', 'N', 'N', 'APPS_UNDOTS1');
    ins('10.2.X',  'plsql_optimize_level',            'Y', 'Y', 'N', 'N', '2');
    ins('10.2.X',  'plsql_code_type',                 'Y', 'Y', 'N', 'N', 'NATIVE');
    ins('10.2.X',  'plsql_native_library_dir',        'Y', 'N', 'N', 'N', '/ebiz/prodr12/plsql_nativelib');
    ins('10.2.X',  'plsql_native_library_subdir_count', 'Y', 'N', 'N', 'N', '149');
    ins('10.2.X', '_kks_use_mutex_pin',               'Y', 'N', 'N', 'N', 'TRUE (FALSE only on HP-UX PA-RISC)');
    /* Removal list for 10gR2 (10.2.X) */
    ins('10.2.X',  '_always_anti_join',               'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_always_semi_join',               'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_complex_view_merging',           'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_index_join_enabled',             'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_new_initial_join_orders',        'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_optimizer_cost_based_transformation', 'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_optimizer_cost_model',           'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_optimizer_mode_force',           'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_optimizer_undo_changes',         'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_or_expand_nvl_predicate',        'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_ordered_nested_loop',            'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_push_join_predicate',            'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_push_join_union_view',           'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_shared_pool_reserved_min_alloc', 'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  '_sortmerge_inequality_join_off',  'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_table_scan_cost_plus_one',       'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_unnest_subquery',                'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  '_use_column_stats_for_function',  'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'always_anti_join',                'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'always_semi_join',                'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'db_block_buffers',                'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'db_file_multiblock_read_count',   'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'db_cache_size',                   'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'enqueue_resources',               'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'event="10932 trace name context level 32768"',      'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'event="10933 trace name context level 512"',        'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'event="10943 trace name context forever, level 2"', 'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'event="10943 trace name context level 16384"',      'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'event="38004 trace name context forever, level 1"', 'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'hash_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'java_pool_size',                  'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'job_queue_interval',              'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'large_pool_size',                 'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'max_enabled_roles',               'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'optimizer_dynamic_sampling',      'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_features_enable',       'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_index_caching',         'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_index_cost_adj',        'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_max_permutations',      'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_mode',                  'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'optimizer_percent_parallel',      'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'plsql_compiler_flags',            'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'query_rewrite_enabled',           'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'row_locking',                     'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'sort_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('10.2.X',  'undo_retention',                  'N', 'N', 'N', 'N', NULL);
    ins('10.2.X',  'undo_suppress_errors',            'N', 'N', 'N', 'N', NULL);
    /* Release-specific database initialization parameters for 11gR1 (11.1.X) */
    ins('11.1.X',  'compatible',                      'Y', 'Y', 'N', 'N', '11.1.0');
    ins('11.1.X',  'diagnostic_dest',                 'Y', 'N', 'N', 'N', '?/prod12');
    ins('11.1.X',  'undo_management',                 'Y', 'Y', 'N', 'N', 'AUTO');
    ins('11.1.X',  'undo_tablespace',                 'Y', 'Y', 'N', 'N', 'APPS_UNDOTS1');
    ins('11.1.X',  'plsql_code_type',                 'Y', 'Y', 'N', 'N', 'NATIVE');
    ins('11.1.X',  '_optimizer_autostats_job',        'Y', 'Y', 'N', 'N', 'FALSE');
    ins('11.1.X',  'sec_case_sensitive_logon',        'Y', 'Y', 'N', 'N', 'FALSE');
    /* Removal list for 11gR1 (11.1.X) */
    ins('11.1.X',  '_always_anti_join',               'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_always_semi_join',               'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_complex_view_merging',           'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_index_join_enabled',             'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_kks_use_mutex_pin',              'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  '_new_initial_join_orders',        'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_optimizer_cost_based_transformation', 'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_optimizer_cost_model',           'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_optimizer_mode_force',           'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_optimizer_undo_changes',         'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_or_expand_nvl_predicate',        'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_ordered_nested_loop',            'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_push_join_predicate',            'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_push_join_union_view',           'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_shared_pool_reserved_min_alloc', 'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  '_sortmerge_inequality_join_off',  'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_sqlexec_progression_cost',       'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_table_scan_cost_plus_one',       'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_unnest_subquery',                'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  '_use_column_stats_for_function',  'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'always_anti_join',                'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'always_semi_join',                'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'background_dump_dest',            'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'core_dump_dest',                  'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'db_block_buffers',                'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'db_file_multiblock_read_count',   'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'db_cache_size',                   'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'enqueue_resources',               'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'event="10932 trace name context level 32768"',      'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'event="10933 trace name context level 512"',        'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'event="10943 trace name context forever, level 2"', 'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'event="10943 trace name context level 16384"',      'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'event="38004 trace name context forever, level 1"', 'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'hash_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'java_pool_size',                  'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'job_queue_interval',              'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'large_pool_size',                 'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'max_enabled_roles',               'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'nls_language',                    'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'optimizer_dynamic_sampling',      'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_features_enable',       'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_index_caching',         'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_index_cost_adj',        'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_max_permutations',      'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_mode',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'optimizer_percent_parallel',      'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'plsql_compiler_flags',            'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'plsql_optimize_level',            'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'plsql_native_library_dir',        'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'plsql_native_library_subdir_count', 'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'plsql_optimize_level',            'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'query_rewrite_enabled',           'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'rollback_segments',               'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'row_locking',                     'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'sort_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.1.X',  'sql_trace',                       'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'timed_statistics',                'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'undo_retention',                  'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'undo_suppress_errors',            'N', 'N', 'N', 'N', NULL);
    ins('11.1.X',  'user_dump_dest',                  'N', 'N', 'N', 'N', NULL);
    /* Release-specific database initialization parameters for 11gR2 (11.2.X) */
    ins('11.2.X',  'compatible',                      'Y', 'Y', 'N', 'N', '11.2.0');
    ins('11.2.X',  'diagnostic_dest',                 'Y', 'N', 'N', 'N', '?/prod12');
    ins('11.2.X',  'undo_management',                 'Y', 'Y', 'N', 'N', 'AUTO');
    ins('11.2.X',  'undo_tablespace',                 'Y', 'Y', 'N', 'N', 'APPS_UNDOTS1');
    ins('11.2.X',  'plsql_code_type',                 'Y', 'Y', 'N', 'N', 'NATIVE');
    ins('11.2.X',  '_optimizer_autostats_job',        'Y', 'Y', 'N', 'N', 'FALSE');
    ins('11.2.X',  'sec_case_sensitive_logon',        'Y', 'Y', 'N', 'N', 'FALSE');
    /* Removal list for 11gR1 (11.2.X) */
    ins('11.2.X',  '_always_anti_join',               'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_always_semi_join',               'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_complex_view_merging',           'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_index_join_enabled',             'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_kks_use_mutex_pin',              'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  '_new_initial_join_orders',        'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_optimizer_cost_based_transformation', 'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_optimizer_cost_model',           'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_optimizer_mode_force',           'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_optimizer_undo_changes',         'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_or_expand_nvl_predicate',        'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_ordered_nested_loop',            'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_push_join_predicate',            'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_push_join_union_view',           'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_shared_pool_reserved_min_alloc', 'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  '_sortmerge_inequality_join_off',  'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_sqlexec_progression_cost',       'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_table_scan_cost_plus_one',       'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_unnest_subquery',                'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  '_use_column_stats_for_function',  'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'always_anti_join',                'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'always_semi_join',                'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'background_dump_dest',            'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'core_dump_dest',                  'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'db_block_buffers',                'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'db_cache_size',                   'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'db_file_multiblock_read_count',   'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'drs_start',                       'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'enqueue_resources',               'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'event="10932 trace name context level 32768"',      'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'event="10933 trace name context level 512"',        'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'event="10943 trace name context forever, level 2"', 'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'event="10943 trace name context level 16384"',      'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'event="38004 trace name context forever, level 1"', 'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'hash_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'java_pool_size',                  'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'job_queue_interval',              'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'large_pool_size',                 'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'max_enabled_roles',               'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'nls_language',                    'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'optimizer_dynamic_sampling',      'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_features_enable',       'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_index_caching',         'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_index_cost_adj',        'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_max_permutations',      'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_mode',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'optimizer_percent_parallel',      'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'plsql_compiler_flags',            'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'plsql_native_library_dir',        'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'plsql_native_library_subdir_count', 'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'plsql_optimize_level',            'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'query_rewrite_enabled',           'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'rollback_segments',               'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'row_locking',                     'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'sort_area_size',                  'N', 'N', 'N', 'Y', NULL);
    ins('11.2.X',  'sql_trace',                       'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'sql_version',                     'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'timed_statistics',                'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'undo_retention',                  'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'undo_suppress_errors',            'N', 'N', 'N', 'N', NULL);
    ins('11.2.X',  'user_dump_dest',                  'N', 'N', 'N', 'N', NULL);
  END IF;

  COMMIT;
END chk$ebs$parameters;
/
SHOW ERRORS;

TRUNCATE TABLE ~~tool_repository_schema..chk$cbo$parameter_apps;
EXEC ~~tool_administer_schema..chk$ebs$parameters(:v_rdbms_version, :v_apps_release);
DROP PROCEDURE ~~tool_administer_schema..chk$ebs$parameters;

/*------------------------------------------------------------------*/

COMMIT;
WHENEVER SQLERROR CONTINUE;
UNDEFINE pack_license connect_identifier
SET DEF ON ECHO OFF ESC OFF TERM ON;
PRO
PRO SQSEED completed.
