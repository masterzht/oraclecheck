REM $Header: 215187.1 sqltcommon2.sql 11.4.5.4 2013/02/04 carlos.sierra $
-- begin common
WHENEVER SQLERROR CONTINUE;
SELECT * FROM session_roles;
COL set_role_name NEW_V set_role_name;
SELECT NULL set_role_name FROM DUAL;
SELECT role set_role_name FROM session_roles WHERE role = '^^role_name.';
SELECT DECODE('^^set_role_name.', NULL, '^^role_name.', NULL) set_role_name FROM DUAL;
SET ROLE ^^set_role_name.;
SELECT * FROM session_roles;
COL libraries FOR A64;
SELECT SUBSTR(text, INSTR(text, ' ', 1, 3) + 1,  INSTR(text, ' ', 1, 6) - INSTR(text, ' ', 1, 3)) libraries
  FROM all_source
 WHERE owner = '^^tool_administer_schema.'
   AND line = 2
   AND text LIKE '%$Header%'
 ORDER BY 1;
PRO
SELECT status||' '||object_type||' '||object_name libraries
  FROM all_objects
 WHERE owner = '^^tool_administer_schema.'
   AND object_type LIKE 'PACKAGE%'
 ORDER BY 1;
PRO
COL lib_count NEW_V lib_count FOR 999;
COL role_count NEW_V role_count FOR 999;
PRO
SELECT COUNT(*) lib_count FROM all_objects WHERE owner = '^^tool_administer_schema.' AND object_type = 'PACKAGE' AND status = 'VALID';
SELECT COUNT(*) role_count FROM user_role_privs WHERE granted_role IN ('^^role_name.', 'DBA');
SELECT granted_role FROM user_role_privs WHERE granted_role IN ('^^role_name.', 'DBA');
SELECT user FROM dual;
PRO
SET TERM ON ECHO OFF;
WHENEVER SQLERROR EXIT SQL.SQLCODE;
PRO
BEGIN
  IF ^^role_count. < 1 THEN
    RAISE_APPLICATION_ERROR(-20109, 'User "'||USER||'" lacks required "^^role_name." role. Request to your DBA: "GRANT ^^role_name. TO '||USER||';".');
  END IF;
  IF ^^lib_count. < 17 THEN
    RAISE_APPLICATION_ERROR(-20110, 'User "'||USER||'" lacks required "^^role_name." role or SQLT is not properly installed. Review installation NN_*.log files.');
  END IF;
END;
/
PRO
WHENEVER SQLERROR CONTINUE;
PRO
-- end common
