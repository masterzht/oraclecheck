select
       'db_check_' as "db_check_",
       COMPONENT,
       round(CURRENT_SIZE/1024/1024/1024,2) || 'G' as CURRENT_G,
       round(MIN_SIZE/1024/1024/1024,2) || 'G' as MIN_G,
       round(MAX_SIZE/1024/1024/1024,2) || 'G' as MAX_G,
       round(USER_SPECIFIED_SIZE/1024/1024/1024,2) || 'G' as USER_SPECIFIED_G,
       OPER_COUNT,
       LAST_OPER_TYPE,
       decode(LAST_OPER_MODE,null,'None',LAST_OPER_MODE) as LAST_OPER_MODE,
       decode(LAST_OPER_TIME,null,'None',LAST_OPER_TIME) as LAST_OPER_TIME,
       round(GRANULE_SIZE/1024/1024) || 'M' as GRANULE_SIZE_M
from v$sga_dynamic_components;