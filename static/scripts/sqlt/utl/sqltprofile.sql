SPO sqltprofile.log;
SET DEF ON TERM OFF ECHO ON FEED OFF VER OFF HEA ON LIN 200 PAGES 100 TRIMS ON TI OFF TIMI OFF APPI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
REM $Header: 215187.1 sqltprofile.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/sqltprofile.sql
REM
REM DESCRIPTION
REM   This script generates another that contains the commands to
REM   create a manual custom SQL Profile out of a known plan from
REM   memory or AWR. The manual custom profile can be implemented
REM   into the same SOURCE system where the plan was retrieved,
REM   or into another similar TARGET system that has same schema
REM   objects referenced by the SQL that generated the known plan.
REM
REM PRE-REQUISITES
REM   1. Execute SQLT (any method) in the SOURCE system.
REM   2. Oracle Tuning Pack license.
REM
REM PARAMETERS
REM   1. Statement ID as per SQLT in SOURCE system (required)
REM      A list of statement ids is presented.
REM   2. Plan Hash Value for which a manual custom SQL Profile is
REM      needed (required). A list of known plans is presented.
REM
REM EXECUTION
REM   1. Navigate to sqlt/utl directory.
REM   2. Connect into SQL*Plus as application user or SYSDBA.
REM   3. Execute script sqltprofile.sql passing statement id and
REM      plan hash value (parameters can be passed inline or until
REM      requested).
REM
REM EXAMPLE
REM   # cd sqlt/utl
REM   # sqlplus / as sysdba
REM   SQL> START sqltprofile.sql [statement id] [plan hash value];
REM   SQL> START sqltprofile.sql 32263 923669362;
REM   SQL> START sqltprofile.sql 32263;
REM   SQL> START sqltprofile.sql;
REM
REM NOTES
REM   1. For possible errors see sqltprofile.log
REM   2. If SQLT is not installed in SOURCE, use instead:
REM      sqlt/utl/coe_xfr_sql_profile.sql
REM   3. Be aware that using DBMS_SQLTUNE requires a license for
REM      Oracle Tuning Pack
REM
-- begin common
DEF _SQLPLUS_RELEASE
SELECT USER FROM DUAL;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') current_time FROM DUAL;
SELECT * FROM v$version;
SELECT * FROM v$instance;
SELECT name, value FROM v$parameter2 WHERE name LIKE '%dump_dest';
SELECT directory_name||' '||directory_path directories FROM dba_directories WHERE directory_name LIKE 'SQLT$%' OR directory_name LIKE 'TRCA$%' ORDER BY 1;
-- end common
SET TERM ON ECHO OFF;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
EXEC sqltxadmin.sqlt$a.validate_user(USER);
CL SCR;
PRO ... please wait ...
WHENEVER SQLERROR CONTINUE;
SELECT LPAD(s.statement_id, 5, '0') staid,
       SUBSTR(s.method, 1, 3) method,
       SUBSTR(s.instance_name_short, 1, 8) instance,
       SUBSTR(s.sql_text, 1, 60) sql_text
  FROM sqltxplain.sqlt$_sql_statement s
 WHERE USER IN ('SYS', 'SYSTEM', s.username)
   AND EXISTS (
SELECT NULL
  FROM sqltxplain.sqlt$_plan_extension p
 WHERE s.statement_id = p.statement_id
   AND p.other_xml IS NOT NULL)
 ORDER BY
       s.statement_id;
PRO
PRO Parameter 1:
PRO STATEMENT_ID (required)
PRO
DEF statement_id = '&1';
PRO
COL attribute FOR A9;
SELECT p.plan_hash_value,
       DECODE(p.plan_hash_value, s.best_plan_hash_value, '[B]')||
       DECODE(p.plan_hash_value, s.worst_plan_hash_value, '[W]')||
       DECODE(p.plan_hash_value, s.xecute_plan_hash_value, '[X]') attribute
  FROM (
SELECT DISTINCT plan_hash_value, statement_id
  FROM sqltxplain.sqlt$_plan_extension
 WHERE statement_id = TO_NUMBER(TRIM('&&statement_id.'))
   AND other_xml IS NOT NULL) p,
       sqltxplain.sqlt$_sql_statement s
 WHERE p.statement_id = s.statement_id
 ORDER BY
       p.plan_hash_value;
PRO
PRO Parameter 2:
PRO PLAN_HASH_VALUE (required)
PRO
DEF plan_hash_value = '&2';
PRO
PRO Values passed to sqltprofile:
PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRO STATEMENT_ID   : "&&statement_id."
PRO PLAN_HASH_VALUE: "&&plan_hash_value."
PRO
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM ON;
EXEC sqltxadmin.sqlt$a.set_param('custom_sql_profile', 'Y');
EXEC sqltxadmin.sqlt$r.custom_sql_profile(TO_NUMBER(TRIM('&&statement_id.')), TO_NUMBER(TRIM('&&plan_hash_value.')));
WHENEVER SQLERROR CONTINUE;
SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF SERVEROUT ON SIZE 1000000 FOR TRU;
SET SERVEROUT ON SIZE UNL FOR TRU;
PRO No fatal errors!
COL filename NEW_V filename FOR A256;
SPO OFF;
--
SELECT NVL(sqltxadmin.sqlt$e.get_filename_from_repo('CUSTOM_SQL_PROFILE', TO_NUMBER(TRIM('&&statement_id.'))), 'missing_file.txt') filename FROM DUAL;
SET TERM ON;
PRO ... getting &&filename. out of sqlt repository ...
SET TERM OFF;
SPO &&filename.;
SELECT * FROM TABLE(sqltxadmin.sqlt$r.display_file('&&filename.', TO_NUMBER(TRIM('&&statement_id.'))));
SPO OFF;
--
SET TERM OFF;
CL COL;
UNDEFINE 1 2 statement_id plan_hash_value;
SET DEF ON TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NEWP 1 PAGES 14 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF;
PRO
PRO &&filename. has been generated
PRO
PRO SQLTPROFILE completed.
