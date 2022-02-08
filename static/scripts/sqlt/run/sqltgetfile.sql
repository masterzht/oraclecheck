REM $Header: 215187.1 sqltgetfile.sql 11.4.5.0 2012/11/21 carlos.sierra $
-- begin common
SELECT NVL(^^tool_administer_schema..sqlt$e.get_filename_from_repo('^1.', :v_statement_id), 'missing_file.txt') filename FROM DUAL;
SET TERM ON;
PRO ... getting ^^filename. out of sqlt repository ...
SET TERM OFF;
SPO ^^filename.;
SELECT * FROM TABLE(^^tool_administer_schema..sqlt$r.display_file('^^filename.', :v_statement_id));
SPO OFF;
-- end common
