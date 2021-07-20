select 'db_check_INST_CNT' as db_check_db_info,(select to_char(count(*)) from gv$instance) as db_check_db_info_para from dual
union all
select 'db_check_VERSION' as db_check_db_info,(SELECT version platform FROM PRODUCT_COMPONENT_VERSION where product like 'Oracle%') as db_check_db_info_para from v$database
union all
select 'db_check_LOG_MODE' as db_check_db_info,log_mode as db_check_db_info_para from v$database
union all
select 'db_check_OPEN_MODE' as db_check_db_info,open_mode as db_check_db_info_para from v$database
union all
select 'db_check_DATABASE_ROLE' as db_check_db_info,DATABASE_ROLE as db_check_db_info_para from v$database
union all
select 'db_check_FORCE_LOGGING' as db_check_db_info,FORCE_LOGGING as db_check_db_info_para from v$database
union all
select 'db_check_FLASHBACK_ON' as db_check_db_info,FLASHBACK_ON as db_check_db_info_para from v$database;

