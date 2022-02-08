SET DEF ON TERM OFF ECHO OFF VER OFF FEED OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 TRIMS ON SERVEROUT ON SIZE 1000000;
REM $Header: 215187.1 sqlt_display_column_stats.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/xgram/sqlt_display_column_stats.sql
REM
REM DESCRIPTION
REM   Displays column CBO statistics including histogram for one
REM   table or partition.
REM
@@sqlt_common1.sql
COL static_ownname NEW_VALUE static_ownname FOR A100;
COL static_tabname NEW_VALUE static_tabname FOR A100;
COL static_colname NEW_VALUE static_colname FOR A100;
COL static_partname NEW_VALUE static_partname FOR A100;
SELECT &&tool_administer_schema..sqlt$s.static_ownname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_tabname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_colname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_partname FROM DUAL;
COL p_ownname NEW_VALUE p_ownname FOR A100;
COL p_tabname NEW_VALUE p_tabname FOR A100;
COL p_colname NEW_VALUE p_colname FOR A100;
COL p_partname NEW_VALUE p_partname FOR A100;
SET TERM ON;
CL SCR;
ACC p_ownname PROMPT 'Table Owner [&&static_ownname.]: ';
PRO
ACC p_tabname PROMPT 'Table Name [&&static_tabname.]: ';
PRO
ACC p_partname PROMPT 'Partition Name [&&static_partname.]: ';
PRO
ACC p_colname PROMPT 'Column Name [&&static_colname.]: ';
PRO
SET TERM OFF;
SELECT TRIM(NVL(TRIM('&&p_ownname.'), '&&static_ownname.')) p_ownname FROM DUAL;
SELECT TRIM(NVL(TRIM('&&p_tabname.'), '&&static_tabname.')) p_tabname FROM DUAL;
SELECT TRIM(NVL(TRIM('&&p_colname.'), '&&static_colname.')) p_colname FROM DUAL;
SELECT TRIM(NVL(TRIM('&&p_partname.'), '&&static_partname.')) p_partname FROM DUAL;
SELECT CASE WHEN UPPER('&&p_partname.') = 'NULL' THEN NULL ELSE '&&p_partname.' END p_partname FROM DUAL;
COL log_time NEW_VALUE log_time FOR A30;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') log_time FROM DUAL;
SPO sqlt_display_column_stats_&&log_time..log
SET TERM ON;
PRO sqlt_display_column_stats_&&log_time..log
PRO
PRO p_ownname : '&&p_ownname.'
PRO p_tabname : '&&p_tabname.'
PRO p_partname: '&&p_partname.'
PRO p_colname : '&&p_colname.'
PRO
PRO SELECT * FROM TABLE(&&tool_administer_schema..sqlt$s.display_column_stats('&&p_ownname.', '&&p_tabname.', '&&p_colname.', '&&p_partname.'));;
PRO
SET SERVEROUT ON SIZE 1000000;
SELECT * FROM TABLE(&&tool_administer_schema..sqlt$s.display_column_stats('&&p_ownname.', '&&p_tabname.', '&&p_colname.', '&&p_partname.'));
CL COL;
SET VER ON FEED 6 HEA ON LIN 80 NEWP 1 PAGES 14 TRIMS OFF SERVEROUT OFF;
PRO
PRO SQLT_DISPLAY_COLUMN_STATS completed.
SPO OFF;
