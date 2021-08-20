select
       'db_check_' as "db_check_",
       owner,
       table_name ,
       logging
from dba_tables
where logging = 'NO'
  and owner not in  ('SYSMAN','WMSYS','SYSTEM','SYS','ANONYMOUS','XDB','APEX_030200','APEX_040000','APEX_040200','DVSYS','LBACSYS','OJVMSYS','APEX_SSO','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS');