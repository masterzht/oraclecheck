SET DEF ON TERM OFF ECHO OFF VER OFF FEED OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 TRIMS ON SERVEROUT ON SIZE 1000000;
REM $Header: 215187.1 sqlt_set_column_hgrm.sql 11.4.5.0 2012/11/21 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/xgram/sqlt_set_column_hgrm.sql
REM
REM DESCRIPTION
REM   Sets ONE column's CBO histogram with up to 5 buckets on a table
REM   or partition column that has CBO statistics on it while
REM   overriding them.
REM   You can use script sqlt_display_column_stats.sql to list
REM   existing buckets and their end points (ep).
REM
@@sqlt_common1.sql
COL static_ownname NEW_VALUE static_ownname FOR A100;
COL static_tabname NEW_VALUE static_tabname FOR A100;
COL static_colname NEW_VALUE static_colname FOR A100;
COL static_partname NEW_VALUE static_partname FOR A100;
COL static_no_invalidate NEW_VALUE static_no_invalidate FOR A100;
COL static_force NEW_VALUE static_force FOR A100;
COL local_data_format NEW_VALUE local_data_format FOR A100;
SELECT &&tool_administer_schema..sqlt$s.static_ownname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_tabname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_colname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_partname FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_no_invalidate FROM DUAL;
SELECT &&tool_administer_schema..sqlt$s.static_force FROM DUAL;
COL p_ownname NEW_VALUE p_ownname FOR A100;
COL p_tabname NEW_VALUE p_tabname FOR A100;
COL p_colname NEW_VALUE p_colname FOR A100;
COL p_value_1 NEW_VALUE p_value_1 FOR A100;
COL p_size_1 NEW_VALUE p_size_1 FOR A100;
COL p_value_2 NEW_VALUE p_value_2 FOR A100;
COL p_size_2 NEW_VALUE p_size_2 FOR A100;
COL p_value_3 NEW_VALUE p_value_3 FOR A100;
COL p_size_3 NEW_VALUE p_size_3 FOR A100;
COL p_value_4 NEW_VALUE p_value_4 FOR A100;
COL p_size_4 NEW_VALUE p_size_4 FOR A100;
COL p_value_5 NEW_VALUE p_value_5 FOR A100;
COL p_size_5 NEW_VALUE p_size_5 FOR A100;
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
SELECT &&tool_administer_schema..sqlt$s.get_data_format('&&p_ownname.', '&&p_tabname.', '&&p_colname.') local_data_format FROM DUAL;
SET TERM ON;
SELECT * FROM TABLE(&&tool_administer_schema..sqlt$s.display_column_stats('&&p_ownname.', '&&p_tabname.', '&&p_colname.', '&&p_partname.'));
PRO
ACC p_value_1 PROMPT 'Value 1 &&local_data_format.[UNKNOWN]: ';
PRO
ACC p_size_1 PROMPT 'Size 1 [0]: ';
PRO
ACC p_value_2 PROMPT 'Value 2 &&local_data_format.[UNKNOWN]: ';
PRO
ACC p_size_2 PROMPT 'Size 2 [0]: ';
PRO
ACC p_value_3 PROMPT 'Value 3 &&local_data_format.[NULL]: ';
PRO
ACC p_size_3 PROMPT 'Size 3 [0]: ';
PRO
ACC p_value_4 PROMPT 'Value 4 &&local_data_format.[NULL]: ';
PRO
ACC p_size_4 PROMPT 'Size 4 [0]: ';
PRO
ACC p_value_5 PROMPT 'Value 5 &&local_data_format.[NULL]: ';
PRO
ACC p_size_5 PROMPT 'Size 5 [0]: ';
PRO
ACC p_no_invalidate PROMPT 'No Invalidate [&&static_no_invalidate.]: ';
PRO
ACC p_force PROMPT 'Force [&&static_force.]: ';
PRO
SET TERM OFF;
SELECT CASE WHEN TRIM(UPPER('&&p_value_1.')) IN ('UNKNOWN', 'NULL') THEN NULL ELSE '&&p_value_1.' END p_value_1 FROM DUAL;
SELECT CASE WHEN NVL(TRIM('&&p_size_1.'), '0') = '0' THEN 'NULL' ELSE '&&p_size_1.' END p_size_1 FROM DUAL;
SELECT CASE WHEN TRIM(UPPER('&&p_value_2.')) IN ('UNKNOWN', 'NULL') THEN NULL ELSE '&&p_value_2.' END p_value_2 FROM DUAL;
SELECT CASE WHEN NVL(TRIM('&&p_size_2.'), '0') = '0' THEN 'NULL' ELSE '&&p_size_2.' END p_size_2 FROM DUAL;
SELECT CASE WHEN TRIM(UPPER('&&p_value_3.')) IN ('UNKNOWN', 'NULL') THEN NULL ELSE '&&p_value_3.' END p_value_3 FROM DUAL;
SELECT CASE WHEN NVL(TRIM('&&p_size_3.'), '0') = '0' THEN 'NULL' ELSE '&&p_size_3.' END p_size_3 FROM DUAL;
SELECT CASE WHEN TRIM(UPPER('&&p_value_4.')) IN ('UNKNOWN', 'NULL') THEN NULL ELSE '&&p_value_4.' END p_value_4 FROM DUAL;
SELECT CASE WHEN NVL(TRIM('&&p_size_4.'), '0') = '0' THEN 'NULL' ELSE '&&p_size_4.' END p_size_4 FROM DUAL;
SELECT CASE WHEN TRIM(UPPER('&&p_value_5.')) IN ('UNKNOWN', 'NULL') THEN NULL ELSE '&&p_value_5.' END p_value_5 FROM DUAL;
SELECT CASE WHEN NVL(TRIM('&&p_size_5.'), '0') = '0' THEN 'NULL' ELSE '&&p_size_5.' END p_size_5 FROM DUAL;
SELECT TRIM(NVL(TRIM('&&p_no_invalidate.'), '&&static_no_invalidate.')) p_no_invalidate FROM DUAL;
SELECT CASE WHEN SUBSTR(UPPER('&&p_no_invalidate.'), 1, 1) IN ('T', 'Y') THEN 'TRUE' ELSE 'FALSE' END p_no_invalidate FROM DUAL;
SELECT TRIM(NVL(TRIM('&&p_force.'), '&&static_force.')) p_force FROM DUAL;
SELECT CASE WHEN SUBSTR(UPPER('&&p_force.'), 1, 1) IN ('T', 'Y') THEN 'TRUE' ELSE 'FALSE' END p_force FROM DUAL;
COL log_time NEW_VALUE log_time FOR A30;
SELECT TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS') log_time FROM DUAL;
SPO sqlt_set_column_hgrm_&&log_time..log
SET TERM ON;
PRO sqlt_set_column_hgrm_&&log_time..log
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
PRO p_value_1      : '&&p_value_1.'
PRO p_size_1       : '&&p_size_1.'
PRO p_value_2      : '&&p_value_2.'
PRO p_size_2       : '&&p_size_2.'
PRO p_value_3      : '&&p_value_3.'
PRO p_size_3       : '&&p_size_3.'
PRO p_value_4      : '&&p_value_4.'
PRO p_size_4       : '&&p_size_4.'
PRO p_value_5      : '&&p_value_5.'
PRO p_size_5       : '&&p_size_5.'
PRO p_no_invalidate: '&&p_no_invalidate.'
PRO p_force        : '&&p_force.'
PRO
PRO EXEC &&tool_administer_schema..sqlt$s.set_column_hgrm(p_ownname => '&&p_ownname.', p_tabname => '&&p_tabname.', p_colname => '&&p_colname.', p_value_1 => '&&p_value_1.', p_size_1 => &&p_size_1., p_value_2 => '&&p_value_2.', p_size_2 => &&p_size_2., p_value_3 => '&&p_value_3.', p_size_3 => &&p_size_3., p_value_4 => '&&p_value_4.', p_size_4 => &&p_size_4., p_value_5 => '&&p_value_5.', p_size_5 => &&p_size_5., p_partname => '&&p_partname.', p_no_invalidate => &&p_no_invalidate., p_force => &&p_force.);;
PRO
SET SERVEROUT ON SIZE 1000000;
BEGIN
  &&tool_administer_schema..sqlt$s.set_column_hgrm (
    p_ownname       => '&&p_ownname.',
    p_tabname       => '&&p_tabname.',
    p_colname       => '&&p_colname.',
    p_value_1       => '&&p_value_1.',
    p_size_1        => &&p_size_1.,
    p_value_2       => '&&p_value_2.',
    p_size_2        => &&p_size_2.,
    p_value_3       => '&&p_value_3.',
    p_size_3        => &&p_size_3.,
    p_value_4       => '&&p_value_4.',
    p_size_4        => &&p_size_4.,
    p_value_5       => '&&p_value_5.',
    p_size_5        => &&p_size_5.,
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
PRO SQLT_SET_COLUMN_HGRM completed.
SPO OFF;
