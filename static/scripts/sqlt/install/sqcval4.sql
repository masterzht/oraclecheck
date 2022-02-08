REM $Header: sqcval4.sql 11.4.5.0 2012/11/21 carlos.sierra $

SET ECHO OFF VER OFF TERM OFF;
SELECT TRIM(NVL('&&temporary_tablespace.', '&&prior_temporary_tablespace.')) temporary_tablespace FROM DUAL;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM ON;

REM SQLTXPLAIN temporary tablespace
DECLARE
  x NUMBER;
BEGIN
  IF UPPER('&&temporary_tablespace.') IN ('SYSTEM', 'SYSAUX') THEN
    RAISE_APPLICATION_ERROR(-20106, 'SQLT installation failed. SYSTEM/SYSAUX tablespace cannot be specified for TEMPORARY tablespace');
  END IF;
  IF UPPER('&&temporary_tablespace.') = 'UNKNOWN' THEN
    RAISE_APPLICATION_ERROR(-20107, 'SQLT installation failed. TEMPORARY tablespace for user &&tool_repository_schema. must be specified');
  END IF;
  SELECT COUNT(*) INTO x FROM sys.dba_tablespaces WHERE tablespace_name = '&&temporary_tablespace.';
  IF x = 0 THEN
    SELECT COUNT(*) INTO x FROM sys.dba_tablespace_groups WHERE group_name = '&&temporary_tablespace.';
    IF x = 0 THEN
      RAISE_APPLICATION_ERROR(-20108, 'SQLT installation failed. TEMPORARY tablespace does not exist');
    END IF;
  END IF;
END;
/

/*------------------------------------------------------------------*/
