REM $Header: xhume/drop_user_objects.sql 11.4.3.5 2011/08/10 carlos.sierra $

DROP PACKAGE BODY &&test_case_user..xhume;
DROP PACKAGE      &&test_case_user..xhume;

DROP TABLE &&test_case_user..xhume_sql_plan_statistics_all;
DROP TABLE &&test_case_user..xhume_discovered_plan;
DROP TABLE &&test_case_user..xhume_test;
DROP TABLE &&test_case_user..xhume_table;

DROP SEQUENCE &&test_case_user..xhume_line_id;
