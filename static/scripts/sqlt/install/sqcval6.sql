REM $Header: sqcval6.sql 11.4.5.0 2012/11/21 carlos.sierra $

SET ECHO OFF VER OFF TERM OFF;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TERM ON;

REM Oracle license pack
BEGIN
  IF NVL(SUBSTR(UPPER(TRIM('&&pack_license.')), 1, 1), 'T') NOT IN ('D', 'T', 'N') THEN
    RAISE_APPLICATION_ERROR(-20111, 'SQLT installation failed. You have to specify "D", "T" or "N". You entered "&&pack_license."');
  END IF;
END;
/

/*------------------------------------------------------------------*/
