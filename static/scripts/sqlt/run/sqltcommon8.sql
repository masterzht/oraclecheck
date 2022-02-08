REM $Header: 215187.1 sqltcommon8.sql 11.4.5.7 2013/04/05 carlos.sierra $
-- begin common
HOS echo "SIEBEL_ORA_BIND_PEEK" >> sqltxhost.log
HOS echo $SIEBEL_ORA_BIND_PEEK >> sqltxhost.log
HOS echo "ORACLE_HOME" >> sqltxhost.log
HOS echo $ORACLE_HOME >> sqltxhost.log
HOS echo "NLS_LANG" >> sqltxhost.log
HOS echo $NLS_LANG >> sqltxhost.log
HOS echo "UDUMP" >> sqltxhost.log
SET TERM ON;
PRO ### ls commands below will error out on windows. disregard error.
SET TERM OFF;
HOS ls -dl ^^udump_path. >> sqltxhost.log
HOS echo "traces_directory_path" >> sqltxhost.log
HOS ls -dl ^^traces_directory_path. >> sqltxhost.log
HOS echo "BDUMP" >> sqltxhost.log
HOS ls -dl ^^bdump_path. >> sqltxhost.log
SET TERM ON;
PRO ### who command below will error out on windows. disregard error.
SET TERM OFF;
HOS echo "WHO" >> sqltxhost.log
HOS who >> sqltxhost.log
HOS zip -m ^^unique_id._driver ^^unique_id._*_driver.sql
-- end common
