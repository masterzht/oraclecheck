REM $Header: 215187.1 sqlt_common1.sql 11.4.5.0 2012/11/21 carlos.sierra $
-- begin common
SELECT USER FROM DUAL;
SELECT TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') current_time FROM DUAL;
SELECT * FROM v$version;
SELECT * FROM v$instance;

DEF _SQLPLUS_RELEASE

DEF tool_repository_schema = 'SQLTXPLAIN';
DEF tool_administer_schema = 'SQLTXADMIN';

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
  IF :rdbms_release < 10 OR :rdbms_version < '10.2' THEN
    RAISE_APPLICATION_ERROR(-20200, 'SQLT installation failed. Install in 10.2 or higher, not in '||:rdbms_release);
  END IF;
END;
/
PRINT rdbms_release;
PRINT rdbms_version;
-- end common
