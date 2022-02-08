REM $Header: sqcval2.sql 11.4.5.0 2012/11/21 carlos.sierra $

SET ECHO OFF VER OFF TERM OFF;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM ON;

REM Password must have no spaces, and it has to be entered twice
BEGIN
  IF '&&enter_tool_password.' IS NULL THEN
    RAISE_APPLICATION_ERROR(-20104, 'SQLT installation failed. No password specified for user &&&&tool_repository_schema..');
  END IF;
  IF NVL('&&enter_tool_password.', '-666') LIKE '% %' THEN
    RAISE_APPLICATION_ERROR(-20105, 'SQLT installation failed. Password for user &&&&tool_repository_schema.. cannot contain spaces');
  END IF;
  IF NVL('&&enter_tool_password.', '-666') <> NVL('&&re_enter_password.', '-999') THEN
    RAISE_APPLICATION_ERROR(-20106, 'Re-entered password did not match');
  END IF;
END;
/

/*------------------------------------------------------------------*/
