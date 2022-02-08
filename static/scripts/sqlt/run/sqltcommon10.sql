REM $Header: 215187.1 sqltcommon10.sql 11.4.5.4 2013/02/04 carlos.sierra $
-- begin common
SET TERM OFF ECHO OFF VER OFF LONG 800000 LONGC 800 LIN 2000 PAGES 0 HEA OFF TRIMS ON;
SPO ^^unique_id._cell_state_begin.txt
SELECT 'INST_ID="'||inst_id||'" CELL_NAME="'||cell_name||'" OBJECT_NAME="'||object_name||'" STATISTICS_TYPE="'||statistics_type||'"' id,
       REPLACE(statistics_value, '><', '>'||CHR(10)||'<') value
  FROM ^^tool_repository_schema..sqlt$_gv$cell_state
 WHERE statement_id = :v_statement_id
   AND begin_end_flag = 'B'
 ORDER BY
       inst_id, cell_name, object_name, statistics_type;
SPO OFF;
SPO ^^unique_id._cell_state_end.txt
SELECT 'INST_ID="'||inst_id||'" CELL_NAME="'||cell_name||'" OBJECT_NAME="'||object_name||'" STATISTICS_TYPE="'||statistics_type||'"' id,
       REPLACE(statistics_value, '><', '>'||CHR(10)||'<') value
  FROM ^^tool_repository_schema..sqlt$_gv$cell_state
 WHERE statement_id = :v_statement_id
   AND begin_end_flag = 'E'
 ORDER BY
       inst_id, cell_name, object_name, statistics_type;
SPO OFF;
COL begin_value FOR A80;
COL end_value FOR A80;
SPO ^^unique_id._cell_state_begin_and_end.txt
SELECT 'INST_ID="'||inst_id||'" CELL_NAME="'||cell_name||'" OBJECT_NAME="'||object_name||'" STATISTICS_TYPE="'||statistics_type||'"'||CHR(10) id,
       'BEGIN:'||CHR(10)||REPLACE(statistics_value_b, '><', '>'||CHR(10)||'<') begin_value,
       'END:'||CHR(10)||REPLACE(statistics_value_e, '><', '>'||CHR(10)||'<') end_value
  FROM ^^tool_administer_schema..sqlt$_gv$cell_state_v
 WHERE statement_id = :v_statement_id
 ORDER BY
       inst_id, cell_name, object_name, statistics_type;
SPO OFF;
HOS zip -m ^^unique_id._cell_state ^^unique_id._cell_state_*.txt
-- end common
