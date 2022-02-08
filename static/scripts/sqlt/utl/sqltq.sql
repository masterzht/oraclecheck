SPO sqltq.log;
SET TERM OFF;
REM $Header: 215187.1 sqltq.sql 11.4.5.6 2013/03/05 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/sqltq.sql
REM
REM DESCRIPTION
REM   This script generates the q.sql script with the SQL text
REM   of a given SQL_ID, including bind variables (declaration
REM   and assignment), plus CBO parameters setup (if SQL was
REM   found in memory).
REM
REM PRE-REQUISITES
REM   1. Install SQLT.
REM
REM PARAMETERS
REM   1. SQL_ID of the SQL to be extracted (required)
REM
REM EXECUTION
REM   1. Navigate to sqlt/utl directory.
REM   2. Connect into SQL*Plus as SYSDBA or application user
REM      or SYSDBA.
REM   3. Execute script sqltq.sql passing SQL_ID
REM      (parameter can be passed inline or until requested).
REM
REM EXAMPLE
REM   # cd sqlt
REM   # sqlplus / as sysdba
REM   SQL> START utl/sqltq.sql [SQL_ID]
REM   SQL> START utl/sqltq.sql f995z9antmhxn
REM   SQL> START utl/sqltq.sql;
REM
REM NOTES
REM   1. For possible errors see sqltq.log
REM
SET DEF ON;
SET DEF ^ TERM OFF ECHO OFF FEED OFF VER OFF LIN 1000 PAGES 100 TRIMS ON SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
SET SQLBL ON;
PRO
DEF tool_repository_schema = 'SQLTXPLAIN';
DEF tool_administer_schema = 'SQLTXADMIN';
PRO
SET TERM ON
PRO Parameter 1:
PRO SQL_ID of the SQL to be extracted (required)
PRO
DEF sql_id_1 = '^1';
SET TERM OFF;
COL sql_id NEW_V sql_id;
SELECT TRIM('^^sql_id_1.') sql_id FROM DUAL;
SET TERM ON;
PRO Value passed:
PRO SQL_ID: "^^sql_id."
PRO
PRO ... please wait ...
PRO
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM OFF;
--
VAR v_statement_id VARCHAR2(32);
EXEC :v_statement_id := ^^tool_administer_schema..sqlt$a.get_statement_id_c;
EXEC ^^tool_administer_schema..sqlt$a.trace_on(:v_statement_id);
COL statement_id NEW_V statement_id FOR A32;
SELECT :v_statement_id statement_id FROM DUAL;
--
EXEC ^^tool_administer_schema..sqlt$a.reset_directories;
EXEC ^^tool_administer_schema..sqlt$a.set_stand_by_dblink(NULL);
EXEC ^^tool_administer_schema..sqlt$a.set_method('XTRACT');
EXEC ^^tool_administer_schema..sqlt$a.s_log_statement_id := TO_NUMBER(:v_statement_id);
EXEC ^^tool_administer_schema..sqlt$a.s_log_statid := ^^tool_administer_schema..sqlt$a.get_statid(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$a.validate_user(USER);
EXEC ^^tool_administer_schema..sqlt$a.common_initialization;
EXEC ^^tool_administer_schema..sqlt$a.write_log('==> xtract');
EXEC ^^tool_administer_schema..sqlt$a.write_log('p_sql_id:"^^sql_id."');
EXEC ^^tool_administer_schema..sqlt$a.create_statement_workspace(p_statement_id => TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$d.capture_sqltext(p_statement_id => TO_NUMBER(:v_statement_id), p_string => NULL, p_sql_id_or_hash_value => '^^sql_id.');
--
COL statid NEW_V statid;
SELECT statid FROM ^^tool_repository_schema..sqlt$_sql_statement WHERE statement_id = TO_NUMBER(:v_statement_id);
COL hash_value NEW_V hash_value;
SELECT hash_value FROM ^^tool_repository_schema..sqlt$_sql_statement WHERE statement_id = TO_NUMBER(:v_statement_id);
COL in_memory NEW_V in_memory;
SELECT in_memory FROM ^^tool_repository_schema..sqlt$_sql_statement WHERE statement_id = TO_NUMBER(:v_statement_id);
COL in_awr NEW_V in_awr;
SELECT in_awr FROM ^^tool_repository_schema..sqlt$_sql_statement WHERE statement_id = TO_NUMBER(:v_statement_id);
--
EXEC ^^tool_administer_schema..sqlt$a.write_log('=> diagnostics_data_collection_1');
BEGIN
  IF '^^in_memory.' = 'Y' THEN
    ^^tool_administer_schema..sqlt$a.write_log('-> collection from memory');
    ^^tool_administer_schema..sqlt$d.collect_gv$sql_bind_capture(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.', TO_NUMBER('^^hash_value.'));
    ^^tool_administer_schema..sqlt$d.collect_gv$sql_optimizer_env(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.', TO_NUMBER('^^hash_value.'));
    ^^tool_administer_schema..sqlt$d.collect_gv$sql_plan_statistics(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.', TO_NUMBER('^^hash_value.'));
    ^^tool_administer_schema..sqlt$d.collect_gv$sql_plan(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.', TO_NUMBER('^^hash_value.'));
    ^^tool_administer_schema..sqlt$d.collect_gv$sql(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.', TO_NUMBER('^^hash_value.'));
    ^^tool_administer_schema..sqlt$d.collect_gv$sqlarea_plan_hash(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.');
    ^^tool_administer_schema..sqlt$d.collect_gv$sqlarea(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.', TO_NUMBER('^^hash_value.'));
    ^^tool_administer_schema..sqlt$a.write_log('<- collection from memory');
  END IF;
END;
/
EXEC ^^tool_administer_schema..sqlt$a.write_log('<= diagnostics_data_collection_1');
--
EXEC ^^tool_administer_schema..sqlt$a.write_log('=> diagnostics_data_collection_2');
BEGIN
  IF '^^in_awr.' = 'Y' THEN
    ^^tool_administer_schema..sqlt$a.write_log('-> collection from awr');
    ^^tool_administer_schema..sqlt$d.collect_dba_hist_sqltext(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.');
    ^^tool_administer_schema..sqlt$d.collect_dba_hist_sqlstat(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.');
    ^^tool_administer_schema..sqlt$d.collect_dba_hist_sql_plan(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.');
    ^^tool_administer_schema..sqlt$d.collect_dba_hist_sqlbind(TO_NUMBER(:v_statement_id), '^^statid.', '^^sql_id.');
    ^^tool_administer_schema..sqlt$a.write_log('<- collection from awr');
  END IF;
END;
/
EXEC ^^tool_administer_schema..sqlt$a.write_log('-> expanded collection');
EXEC ^^tool_administer_schema..sqlt$d.one_plan_per_hv_mem(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$d.collect_plan_extensions(TO_NUMBER(:v_statement_id), '^^statid.');
EXEC ^^tool_administer_schema..sqlt$a.write_log('<- expanded collection');
EXEC ^^tool_administer_schema..sqlt$a.write_log('<= diagnostics_data_collection_2');
--

EXEC ^^tool_administer_schema..sqlt$a.write_log('=> perm_transformation');
EXEC ^^tool_administer_schema..sqlt$t.flag_dba_hist_sqlstat(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$t.best_and_worst_plans(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$t.sanitize_other_xml(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$t.process_other_xml(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$t.extend_peeked_binds(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$t.extend_gv$sql_bind_capture(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$t.extend_gv$sql_optimizer_env(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$t.extend_dba_hist_sqlbind(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$a.write_log('<= perm_transformation');
--
EXEC ^^tool_administer_schema..sqlt$a.s_xtrxec := 'N';
--
EXEC ^^tool_administer_schema..sqlt$r.test_case_script(TO_NUMBER(:v_statement_id), p_include_hint_id => FALSE);
EXEC ^^tool_administer_schema..sqlt$r.test_case_sql(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$a.write_log('<== xtract');
EXEC ^^tool_administer_schema..sqlt$a.set_end_date(TO_NUMBER(:v_statement_id));
EXEC ^^tool_administer_schema..sqlt$a.s_log_statement_id := NULL;
EXEC ^^tool_administer_schema..sqlt$a.s_log_statid := NULL;
EXEC ^^tool_administer_schema..sqlt$a.set_method(NULL);
EXEC ^^tool_administer_schema..sqlt$a.set_stand_by_dblink(NULL);
EXEC ^^tool_administer_schema..sqlt$a.set_module;
--
WHENEVER SQLERROR CONTINUE;
SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;
SET SERVEROUT ON SIZE UNL FOR TRU;
COL column_value FOR A2000;
COL filename NEW_V filename FOR A256;
--
SELECT NVL(^^tool_administer_schema..sqlt$e.get_filename_from_repo('TEST_CASE_SCRIPT', TO_NUMBER(TRIM('^^statement_id.'))), 'missing_file.txt') filename FROM DUAL;
SPO q_^^sql_id..sql;
SELECT * FROM TABLE(^^tool_administer_schema..sqlt$r.display_file('^^filename.', TO_NUMBER(TRIM('^^statement_id.'))));
SPO OFF;
--
CL COL;
UNDEFINE 1 statement_id;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NEWP 1 PAGES 14 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF;
PRO
PRO q_&&sql_id..sql has been generated
PRO
PRO SQLTQ completed.
