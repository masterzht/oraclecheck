SET DEF ON TERM OFF ECHO OFF VER OFF FEED OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 TRIMS ON SERVEROUT ON SIZE 1000000;
REM $Header: 215187.1 sqlt_delete_schema_hgrm.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/xgram/sqlt_delete_schema_hgrm.sql
REM
REM DESCRIPTION
REM   Deletes ALL column's CBO histograms for ALL tables in ONE
REM   schema while preserving remaining column statistics.
REM   When deleting column CBO histogram for a partitioned table
REM   it cascades to delete all histograms into all partitions.
REM
@@sqlt_common1.sql
COL static_ownname NEW_VALUE static_ownname FOR A100;
COL static_no_invalidate NEW_VALUE static_no_invalidate FOR A100;
COL static_force NEW_VALUE static_force FOR A100;
SELECT &&tool_administer_schema..sqlt$s.static_ownname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_no_invalidate FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_force FROM DUAL;
COL p_ownname NEW_VALUE p_ownname FOR A100;
COL p_no_invalidate NEW_VALUE p_no_invalidate FOR A100;
COL p_force NEW_VALUE p_force FOR A100;
SET TERM ON;
CL SCR;
ACC p_ownname PROMPT 'Table Owner [&&static_ownname.]: ';
PRO
ACC p_no_invalidate PROMPT 'No Invalidate [&&static_no_invalidate.]: ';
PRO
ACC p_force PROMPT 'Force [&&static_force.]: ';
PRO
SET TERM OFF;
SELECT TRIM(NVL(TRIM('&&p_ownname.'), '&&static_ownname.')) p_ownname FROM DUAL;
SELECT TRIM(NVL(TRIM('&&p_no_invalidate.'), '&&static_no_invalidate.')) p_no_invalidate FROM DUAL;
SELECT CASE WHEN SUBSTR(UPPER('&&p_no_invalidate.'), 1, 1) IN ('T', 'Y') THEN 'TRUE' ELSE 'FALSE' END p_no_invalidate FROM DUAL;
SELECT TRIM(NVL(TRIM('&&p_force.'), '&&static_force.')) p_force FROM DUAL;
SELECT CASE WHEN SUBSTR(UPPER('&&p_force.'), 1, 1) IN ('T', 'Y') THEN 'TRUE' ELSE 'FALSE' END p_force FROM DUAL;
COL log_time NEW_VALUE log_time FOR A30;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') log_time FROM DUAL;
SPO sqlt_delete_schema_hgrm_&&log_time..log
SET TERM ON;
PRO sqlt_delete_schema_hgrm_&&log_time..log
PRO
PRO p_ownname      : '&&p_ownname.'
PRO p_no_invalidate: '&&p_no_invalidate.'
PRO p_force        : '&&p_force.'
PRO
PRO EXEC &&tool_administer_schema..sqlt$s.delete_schema_hgrm(p_ownname => '&&p_ownname.', p_no_invalidate => &&p_no_invalidate., p_force => &&p_force.);;
PRO
SET SERVEROUT ON SIZE 1000000;
BEGIN
  &&tool_administer_schema..sqlt$s.delete_schema_hgrm (
    p_ownname       => '&&p_ownname.',
    p_no_invalidate => &&p_no_invalidate.,
    p_force         => &&p_force. );
END;
/
CL COL;
SET VER ON FEED 6 HEA ON LIN 80 NEWP 1 PAGES 14 TRIMS OFF SERVEROUT OFF;
PRO
PRO SQLT_DELETE_SCHEMA_HGRM completed.
SPO OFF;
