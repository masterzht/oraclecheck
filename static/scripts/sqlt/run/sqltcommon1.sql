REM $Header: 215187.1 sqltcommon1.sql 12.2.171004  October 4th, 2017  carlos.sierra mauro.pagano abel.macias@oracle.com $ 
-- begin common
WHENEVER SQLERROR CONTINUE;
PRO
SET DEF ON;
SET DEF ^ ESC ~ TERM OFF ECHO ON VER OFF LIN 100 PAGES 100 TRIMS ON SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;
SET SERVEROUT ON SIZE UNL;
SET SQLBL ON;
PRO
SELECT USER FROM DUAL;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') current_time FROM DUAL;
SELECT * FROM product_component_version;
SELECT * FROM v$version;
SELECT * FROM v$instance;
SELECT name, value FROM v$parameter2 WHERE name LIKE '%dump_dest';
SELECT directory_name||' '||directory_path directories FROM sys.dba_directories WHERE directory_name LIKE 'SQLT$%' OR directory_name LIKE 'TRCA$%' ORDER BY 1;
PRO
DEF _SQLPLUS_RELEASE
PRO
SHO parameters NLS
SHO parameters OPTIMIZER
SHO parameters DUMP_DEST
PRO
DEF tool_repository_schema = 'SQLTXPLAIN';
DEF tool_administer_schema = 'SQLTXADMIN';
DEF tool_version           = '12.2.180725';
DEF role_name              = 'SQLT_USER_ROLE';
DEF temporary_or_permanent = 'T';
-- 160622 Remove DEF
-- end common
