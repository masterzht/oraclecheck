REM $Header: sqcval5.sql 11.4.5.0 2012/11/21 carlos.sierra $

SET ECHO OFF VER OFF TERM OFF;
SELECT username application_schema FROM sys.dba_users
WHERE username = NVL(UPPER(TRIM('&&main_application_schema.')), 'SYSTEM');
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM ON;

REM Main application user
BEGIN
  IF '&&application_schema.' IS NULL THEN
    RAISE_APPLICATION_ERROR(-20110, 'SQLT installation failed. Main application user of SQLT "'||UPPER(TRIM('&&main_application_schema.'))||'" was not specified');
  END IF;
END;
/

/*------------------------------------------------------------------*/
