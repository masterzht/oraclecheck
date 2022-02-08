REM $Header: 215187.1 sqltcommon4.sql 12.2.170914 2017/09/14 carlos.sierra abel.macias@oracle.com $ 
-- begin common
-- 150903 Cosmetic change and SYS in 12c warning
SET TERM OFF;
SET FEED OFF VER OFF SHOW OFF HEA ON LIN 1280 NEWP 1 PAGES 960 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF SQLP SQL> BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR WOR;
SET SERVEROUT ON SIZE UNL FOR WOR;
WHENEVER SQLERROR CONTINUE;
PRO
COL connected_user NEW_V connected_user FOR A30;
SELECT user connected_user FROM DUAL;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') current_time FROM DUAL;
SELECT * FROM v$version;
PRO
VAR v_statement_id VARCHAR2(32);
PRO
WHENEVER SQLERROR EXIT SQL.SQLCODE;
PRO
SET TERM ON ECHO OFF;
PRO ***
PRO *** NOTE:
PRO *** If you get error below it means ^^tool_repository_schema. is not installed:
PRO ***   PLS-00201: identifier '^^tool_administer_schema..SQLT$A' must be declared.
PRO *** In such case look for errors in NN_*.log files created during install.
PRO ***
PRO
PRO ***
PRO *** NOTE:
PRO *** If running as SYS in 12c make sure to review sqlt_instructions.html first
PRO ***
EXEC :v_statement_id := ^^tool_administer_schema..sqlt$a.get_statement_id_c;
EXEC ^^tool_administer_schema..sqlt$a.trace_on(:v_statement_id);
PRO
-- CL SCR;
COL sqlt_version FOR A40;
SELECT
'SQLT version number: '||^^tool_administer_schema..sqlt$a.get_param('tool_version')||CHR(10)||
'SQLT version date  : '||^^tool_administer_schema..sqlt$a.get_param('tool_date')||CHR(10)||
'Installation date  : '||^^tool_administer_schema..sqlt$a.get_param('install_date') sqlt_version
FROM DUAL;
PRO
PRO ... please wait ...
SET TERM OFF;
PRO
PRINT v_statement_id;
COL statement_id NEW_V statement_id FOR A32;
SELECT :v_statement_id statement_id FROM DUAL;
PRO
COL unique_id NEW_V unique_id FOR A32;
SELECT 'sqlt_s'||:v_statement_id unique_id FROM DUAL;
PRO
COL libraries FOR A64;
SELECT column_value libraries FROM TABLE(^^tool_administer_schema..sqlt$r.libraries_versions);
PRO
EXEC ^^tool_administer_schema..sqlt$a.validate_tool_version('^^tool_version.');
PRO
COL install_date FOR A20;
SELECT ^^tool_administer_schema..sqlt$a.get_param('install_date') install_date FROM DUAL;
PRO
COL host_name FOR A80;
SELECT ^^tool_administer_schema..sqlt$a.get_host_name_short host_name FROM DUAL;
PRO
COL spfile NEW_V spfile FOR A256;
SELECT ^^tool_administer_schema..sqlt$a.get_v$parameter('spfile') spfile FROM DUAL;
PRO
COL traces_directory_path NEW_V traces_directory_path FOR A256;
SELECT ^^tool_administer_schema..sqlt$a.get_param('traces_directory_path') traces_directory_path FROM DUAL;
PRO
COL udump_path NEW_V udump_path FOR A256;
SELECT ^^tool_administer_schema..sqlt$a.get_udump_full_path udump_path FROM DUAL;
PRO
COL bdump_path NEW_V bdump_path FOR A256;
SELECT ^^tool_administer_schema..sqlt$a.get_bdump_full_path bdump_path FROM DUAL;
HOS zip -j ^^unique_id._log ^^bdump_path.alert_*.log
PRO
COL user_dump_dest FOR A256;
SELECT ^^tool_administer_schema..sqlt$a.get_v$parameter('user_dump_dest') user_dump_dest FROM DUAL;
PRO
COL background_dump_dest FOR A256;
SELECT ^^tool_administer_schema..sqlt$a.get_v$parameter('background_dump_dest') background_dump_dest FROM DUAL;
PRO
COL directories FOR A256;
WHENEVER SQLERROR CONTINUE;
SELECT directory_name||' '||directory_path directories FROM dba_directories WHERE directory_name LIKE 'SQLT$%' OR directory_name LIKE 'TRCA$%' ORDER BY 1;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
EXEC ^^tool_administer_schema..sqlt$a.reset_directories;
PRO
-- 160622 Remove DEF
PRO
-- end common
