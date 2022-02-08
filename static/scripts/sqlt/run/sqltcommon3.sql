REM $Header: 215187.1 sqltcommon3.sql 12.1.12 2015/09/11 carlos.sierra mauro.pagano abel.macias@oracle.com $ 
-- begin common
PRO
PRO Paremeter 2:
PRO ^^tool_repository_schema. password (required)
PRO
DEF enter_tool_password = '^2';
-- 150903 clear after password
CL SCR;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
BEGIN
  IF '^^enter_tool_password.' IS NULL THEN
    RAISE_APPLICATION_ERROR(-20104, 'No password specified for user ^^tool_repository_schema.');
  END IF;
  IF '^^enter_tool_password.' LIKE '% %' THEN
    RAISE_APPLICATION_ERROR(-20105, 'Password for user ^^tool_repository_schema. cannot contain spaces');
  END IF;
END;
/
PRO

DECLARE
remote_conn VARCHAR2(1) := 'N';
BEGIN
 
  SELECT CASE WHEN port <> 0 THEN 'Y' ELSE 'N' END
    INTO remote_conn
    FROM sys.sqlt$_my_v$session; 
   
  IF ^^tool_administer_schema..sqlt$a.get_param('connect_identifier') IS NULL AND remote_conn = 'Y' THEN
    RAISE_APPLICATION_ERROR(-20106, 'SQLT parameter connect_identifier must be set when running SQLT from a remote client');
  END IF;
END;
/
PRO

-- end common
