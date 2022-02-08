REM $Header: 224270.1 tacommon1.sql 12.1.160429 2016/04/29 carlos.sierra abel.macias@oracle.com $

-- set rdbms_version
VAR rdbms_release NUMBER;
VAR rdbms_version VARCHAR2(17);
DECLARE
  dot1 NUMBER;
  dot2 NUMBER;
BEGIN
  EXECUTE IMMEDIATE 'SELECT version FROM v$instance' INTO :rdbms_version;
  dot1 := INSTR(:rdbms_version, '.');
  dot2 := INSTR(:rdbms_version, '.', dot1 + 1);
  :rdbms_release :=
  TO_NUMBER(SUBSTR(:rdbms_version, 1, dot1 - 1)) +
  (TO_NUMBER(SUBSTR(:rdbms_version, dot1 + 1, dot2 - dot1 - 1)) / POWER(10, (dot2 - dot1 - 1)));
  IF :rdbms_release < 9 OR :rdbms_version BETWEEN '8.0' AND '9.0.1' THEN
    RAISE_APPLICATION_ERROR(-20200, 'SQLT installation failed. Install in 9.2 or higher, not in '||:rdbms_release);
  END IF;
END;
/
PRINT rdbms_release;
PRINT rdbms_version;

-- 160420 Transfered to sqplcodetype.sql

-- begin common
WHENEVER SQLERROR CONTINUE;

SELECT USER FROM DUAL;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') current_time FROM DUAL;
SELECT * FROM product_component_version;
SELECT * FROM v$version;
SELECT * FROM v$instance;
SELECT name, value FROM v$parameter2 WHERE name LIKE '%dump_dest';
SELECT directory_name||' '||directory_path directories FROM sys.dba_directories WHERE directory_name LIKE 'SQLT$%' OR directory_name LIKE 'TRCA$%' ORDER BY 1;

DEF _SQLPLUS_RELEASE

SHO parameters NLS
SHO parameters PLSQL
SHO parameters OPTIMIZER
SHO parameters DUMP_DEST

DEF tool_repository_schema = 'TRCANLZR';
DEF tool_administer_schema = 'TRCADMIN';
DEF role_name              = 'TRCA_USER_ROLE';
DEF tool_version           = '12.1.0.1';
DEF tool_date              = '2013-08-19'
DEF tool_note              = '224270.1';
DEF tool_name              = 'TRCA';

-- end common
