select
       'db_check' as "db_check",
       COMPONENT,
       round(CURRENT_SIZE/1024/1024/1024,2) as CURRENT_G,
       round(MIN_SIZE/1024/1024/1024,2) MIN_G,
       round(MAX_SIZE/1024/1024/1024,2) as MAX_G,
       round(USER_SPECIFIED_SIZE/1024/1024/1024,2) as USER_SPECIFIED_G,
       OPER_COUNT,
       LAST_OPER_TYPE,
       decode(LAST_OPER_MODE,null,'None',LAST_OPER_MODE) as LAST_OPER_MODE,
       decode(LAST_OPER_TIME,null,'None',LAST_OPER_TIME) as LAST_OPER_TIME,
       round(GRANULE_SIZE/1024/1024) as GRANULE_SIZE_M
from v$sga_dynamic_components;