SELECT
'db_check_big_table_no_index' as "db_check_big_table_no_index",
owner,
segment_name,
round(bytes /1024/1024/1024, 3) value
FROM dba_segments WHERE segment_type = 'TABLE'
    AND segment_name NOT IN (SELECT table_name FROM dba_indexes)
    AND bytes/1024/1024/1024  >= 1
    and owner NOT IN ('ANONYMOUS','APEX_030200','APEX_040000','APEX_SSO','APPQOSSYS','CTXSYS','DBSNMP','DIP','EXFSYS','FLOWS_FILES','MDSYS','OLAPSYS','ORACLE_OCM','ORDDATA','ORDPLUGINS','ORDSYS','OUTLN','OWBSYS','SI_INFORMTN_SCHEMA','SQLTXADMIN','SQLTXPLAIN','SYS','SYSMAN','SYSTEM','TRCANLZR','WMSYS','XDB','XS$NULL','PERFSTAT','STDBYPERF')
    ORDER  BY bytes DESC;