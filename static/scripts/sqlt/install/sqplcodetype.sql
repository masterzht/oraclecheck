REM $Header: 215187.1 sqplcodetype.sql 12.1.160429 2016/04/29 abel.macias@oracle.com $ 

-- 160420 use NATIVE if possible, else INTERPRETED (NATIVE performs better. INTERPRETED avoids some errors in some systems.)
WHENEVER SQLERROR CONTINUE;

SET TERM ON ECHO OFF
Prompt Ignore errors from here until @@@@@ marker as this is to test for NATIVE PLSQL Code Type
SET TERMO OFF

ALTER SESSION SET PLSQL_CODE_TYPE = NATIVE; 

CREATE OR REPLACE PACKAGE SQLT$_PLSQL_CODE_TYPE is
   PROCEDURE test;
END sqlt$_plsql_code_type;
/

CREATE OR REPLACE PACKAGE BODY SQLT$_PLSQL_CODE_TYPE IS
  PROCEDURE test  IS
  BEGIN
   NULL;
  END;
END sqlt$_plsql_code_type;
/

COL plsql_code_type NEW_V plsql_code_type;
SELECT CASE WHEN (:rdbms_version BETWEEN '11' AND '20' and STATUS='VALID')
       THEN 'NATIVE' 
       ELSE 'INTERPRETED' 
       END plsql_code_type 
  FROM USER_OBJECTS
 WHERE OBJECT_NAME='SQLT$_PLSQL_CODE_TYPE'
   AND OBJECT_TYPE='PACKAGE BODY';
   
SELECT NVL('&plsql_code_type','INTERPRETED') plsql_code_type from dual;  

drop package sqlt$_plsql_code_type;
set TERM ON
Prompt @@@@ marker . You may ignore prior errors about NATIVE PLSQL Code Type

ALTER SESSION SET PLSQL_CODE_TYPE = &&plsql_code_type;