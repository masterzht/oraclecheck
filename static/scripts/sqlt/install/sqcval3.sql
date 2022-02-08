REM $Header: sqcval3.sql 11.4.5.0 2012/11/21 carlos.sierra $

SET ECHO OFF VER OFF TERM OFF;
SELECT TRIM(NVL('&&default_tablespace.', '&&prior_default_tablespace.')) default_tablespace FROM DUAL;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM ON;

REM SQLTXPLAIN default tablespace
DECLARE
  x NUMBER;
BEGIN
  IF UPPER('&&default_tablespace.') IN ('SYSTEM', 'SYSAUX') THEN
    RAISE_APPLICATION_ERROR(-20106, 'SQLT installation failed. SYSTEM/SYSAUX tablespace cannot be specified for DEFAULT tablespace');
  END IF;
  IF UPPER('&&default_tablespace.') = 'UNKNOWN' THEN
    RAISE_APPLICATION_ERROR(-20107, 'SQLT installation failed. DEFAULT tablespace for user &&tool_repository_schema. must be specified');
  END IF;
  SELECT COUNT(*) INTO x FROM sys.dba_tablespaces WHERE tablespace_name = '&&default_tablespace.';
  IF x = 0 THEN
    SELECT COUNT(*) INTO x FROM sys.dba_tablespace_groups WHERE group_name = '&&default_tablespace.';
    IF x = 0 THEN
      RAISE_APPLICATION_ERROR(-20108, 'SQLT installation failed. DEFAULT tablespace does not exist');
    END IF;
  END IF;
END;
/

/*------------------------------------------------------------------*/
