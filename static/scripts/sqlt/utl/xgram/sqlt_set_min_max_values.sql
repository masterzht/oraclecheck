SET DEF ON TERM OFF ECHO OFF VER OFF FEED OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 TRIMS ON SERVEROUT ON SIZE 1000000;
REM $Header: 215187.1 sqlt_set_min_max_values.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/xgram/sqlt_set_min_max_values.sql
REM
REM DESCRIPTION
REM   Sets the min and max (low and high) values of ONE column's CBO
REM   histogram for one table or partition while preserving remaining
REM   buckets and column statistics.
REM   You can use script sqlt_display_column_stats.sql to list
REM   existing buckets and their end points (ep).
REM   The size of ALL buckets is preserved.
REM
@@sqlt_common1.sql
COL static_ownname NEW_VALUE static_ownname FOR A100;
COL static_tabname NEW_VALUE static_tabname FOR A100;
COL static_colname NEW_VALUE static_colname FOR A100;
COL local_new_min_value NEW_VALUE local_new_min_value FOR A100;
COL local_new_max_value NEW_VALUE local_new_max_value FOR A100;
COL static_partname NEW_VALUE static_partname FOR A100;
COL static_no_invalidate NEW_VALUE static_no_invalidate FOR A100;
COL static_force NEW_VALUE static_force FOR A100;
SELECT &&tool_administer_schema..sqlt$s.static_ownname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_tabname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_colname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_partname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_no_invalidate FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_force FROM DUAL;
COL p_ownname NEW_VALUE p_ownname FOR A100;
COL p_tabname NEW_VALUE p_tabname FOR A100;
COL p_colname NEW_VALUE p_colname FOR A100;
COL p_new_min_value NEW_VALUE p_new_min_value FOR A100;
COL p_new_max_value NEW_VALUE p_new_max_value FOR A100;
COL p_partname NEW_VALUE p_partname FOR A100;
COL p_no_invalidate NEW_VALUE p_no_invalidate FOR A100;
COL p_force NEW_VALUE p_force FOR A100;
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
SELECT TRIM(&&tool_administer_schema..sqlt$s.get_min_value('&&p_ownname.', '&&p_tabname.', '&&p_colname.', '&&p_partname.')) local_new_min_value FROM DUAL;
SELECT TRIM(&&tool_administer_schema..sqlt$s.get_max_value('&&p_ownname.', '&&p_tabname.', '&&p_colname.', '&&p_partname.')) local_new_max_value FROM DUAL;
SET TERM ON;
SELECT * FROM TABLE(&&tool_administer_schema..sqlt$s.display_column_stats('&&p_ownname.', '&&p_tabname.', '&&p_colname.', '&&p_partname.'));
PRO
ACC p_new_min_value PROMPT 'New Min (Low) Value [&&local_new_min_value.]: ';
PRO
ACC p_new_max_value PROMPT 'New Max (High) Value [&&local_new_max_value.]: ';
PRO
ACC p_no_invalidate PROMPT 'No Invalidate [&&static_no_invalidate.]: ';
PRO
ACC p_force PROMPT 'Force [&&static_force.]: ';
PRO
SET TERM OFF;
SELECT TRIM(NVL(TRIM('&&p_new_min_value.'), '&&local_new_min_value.')) p_new_min_value FROM DUAL;
SELECT TRIM(NVL(TRIM('&&p_new_max_value.'), '&&local_new_max_value.')) p_new_max_value FROM DUAL;
SELECT TRIM(NVL(TRIM('&&p_no_invalidate.'), '&&static_no_invalidate.')) p_no_invalidate FROM DUAL;
SELECT CASE WHEN SUBSTR(UPPER('&&p_no_invalidate.'), 1, 1) IN ('T', 'Y') THEN 'TRUE' ELSE 'FALSE' END p_no_invalidate FROM DUAL;
SELECT TRIM(NVL(TRIM('&&p_force.'), '&&static_force.')) p_force FROM DUAL;
SELECT CASE WHEN SUBSTR(UPPER('&&p_force.'), 1, 1) IN ('T', 'Y') THEN 'TRUE' ELSE 'FALSE' END p_force FROM DUAL;
COL log_time NEW_VALUE log_time FOR A30;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') log_time FROM DUAL;
SPO sqlt_set_min_max_values_&&log_time..log
SET TERM ON;
PRO sqlt_set_min_max_values_&&log_time..log
PRO
PRO p_ownname : '&&p_ownname.'
PRO p_tabname : '&&p_tabname.'
PRO p_partname: '&&p_partname.'
PRO p_colname : '&&p_colname.'
PRO
PRO SELECT * FROM TABLE(&&tool_administer_schema..sqlt$s.display_column_stats('&&p_ownname.', '&&p_tabname.', '&&p_colname.', '&&p_partname.'));;
PRO
SELECT * FROM TABLE(&&tool_administer_schema..sqlt$s.display_column_stats('&&p_ownname.', '&&p_tabname.', '&&p_colname.', '&&p_partname.'));
PRO
PRO p_ownname      : '&&p_ownname.'
PRO p_tabname      : '&&p_tabname.'
PRO p_partname     : '&&p_partname.'
PRO p_colname      : '&&p_colname.'
PRO p_new_min_value: '&&p_new_min_value.'
PRO p_new_max_value: '&&p_new_max_value.'
PRO p_no_invalidate: '&&p_no_invalidate.'
PRO p_force        : '&&p_force.'
PRO
PRO EXEC &&tool_administer_schema..sqlt$s.set_min_max_values(p_ownname => '&&p_ownname.', p_tabname => '&&p_tabname.', p_colname => '&&p_colname.', p_new_min_value => '&&p_new_min_value.', p_new_max_value => '&&p_new_max_value.', p_partname => '&&p_partname.', p_no_invalidate => &&p_no_invalidate., p_force => &&p_force.);;
PRO
SET SERVEROUT ON SIZE 1000000;
BEGIN
  &&tool_administer_schema..sqlt$s.set_min_max_values (
    p_ownname       => '&&p_ownname.',
    p_tabname       => '&&p_tabname.',
    p_colname       => '&&p_colname.',
    p_new_min_value => '&&p_new_min_value.',
    p_new_max_value => '&&p_new_max_value.',
    p_partname      => '&&p_partname.',
    p_no_invalidate => &&p_no_invalidate.,
    p_force         => &&p_force. );
END;
/
PRO
PRO p_ownname : '&&p_ownname.'
PRO p_tabname : '&&p_tabname.'
PRO p_partname: '&&p_partname.'
PRO p_colname : '&&p_colname.'
PRO
PRO SELECT * FROM TABLE(&&tool_administer_schema..sqlt$s.display_column_stats('&&p_ownname.', '&&p_tabname.', '&&p_colname.', '&&p_partname.'));;
PRO
SELECT * FROM TABLE(&&tool_administer_schema..sqlt$s.display_column_stats('&&p_ownname.', '&&p_tabname.', '&&p_colname.', '&&p_partname.'));
CL COL;
SET VER ON FEED 6 HEA ON LIN 80 NEWP 1 PAGES 14 TRIMS OFF SERVEROUT OFF;
PRO
PRO SQLT_SET_MIN_MAX_VALUES completed.
SPO OFF;

