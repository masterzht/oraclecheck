REM $Header: sqcval1.sql 12.1.05 2013/12/11 carlos.sierra mauro.pagano $

SET ECHO OFF VER OFF TERM OFF;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SELECT CASE WHEN UPPER(TRIM(NVL('&&connect_identifier.', 'NULL'))) = 'NULL' THEN NULL ELSE TRIM('&&connect_identifier.') END connect_identifier FROM DUAL;
SET TERM ON;

REM Connect identifier must be null, "NULL" or "@PROD" where PROD is a valid alias
BEGIN
  IF '&&connect_identifier.' IS NOT NULL AND '&&connect_identifier.' NOT LIKE '@%' THEN
    RAISE_APPLICATION_ERROR(-20103, 'Install failed - Incorrect Connect Identifier, it must start with "@": &&connect_identifier.');
  END IF;
END;
/

REM Connect identifier must be not null when installing SQLT in a PDB
DECLARE
mycon_id NUMBER;
BEGIN
  BEGIN
   SELECT SYS_CONTEXT('USERENV','CON_ID')
     INTO mycon_id
 	FROM DUAL;
  EXCEPTION WHEN OTHERS THEN NULL; -- it means we are not in 12c
  END;
 
  IF '&&connect_identifier.' IS NULL AND mycon_id > 1 THEN
    RAISE_APPLICATION_ERROR(-20103, 'Install failed - Missing Connect Identifier, it must be provided when installing in a PDB');
  END IF;  
END;
/

/*------------------------------------------------------------------*/
