REM $Header: 215187.1 sqltcommon13.sql 11.4.5.11 2013/08/19 mauro.pagano
-- sqldx
COL sqldx_prefix NEW_V sqldx_prefix FOR A40;
SELECT '^^unique_id._sqldx' sqldx_prefix FROM DUAL;
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(client_info => '^^sqldx_prefix.');
COL plicense NEW_V plicense FOR A1;
SELECT ^^tool_administer_schema..sqlt$a.get_pack_access plicense FROM DUAL;
COL sqldx_reports_format NEW_V sqldx_reports_format FOR A10;
SELECT ^^tool_administer_schema..sqlt$a.get_param('sqldx_reports_format') sqldx_reports_format FROM DUAL;
COL sqlid NEW_V sqlid FOR A13;
SELECT ^^tool_administer_schema..sqlt$a.get_sql_id(:v_statement_id) sqlid FROM DUAL;
@@sqldx.sql ^^plicense. ^^sqldx_reports_format. ^^sqlid.
SET DEF ON;
SET DEF ^;