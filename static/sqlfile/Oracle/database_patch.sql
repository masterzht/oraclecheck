SELECT 'db_check_database_patch' as "db_check_database_patch",
        TO_CHAR(ACTION_TIME,'YYYY/MM/DD HH24:MI:SS') TIME,ACTION,COMMENTS
  FROM dba_registry_history
 ORDER BY 1;