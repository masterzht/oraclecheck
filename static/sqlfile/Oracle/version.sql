select
       'db_check_version' as "db_check_version",
       substr(value,1,2) as value
from v$parameter where name='optimizer_features_enable';