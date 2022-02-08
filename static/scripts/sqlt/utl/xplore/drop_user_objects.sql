REM $Header: xplore/drop_user_objects.sql 11.4.3.5 2011/08/10 carlos.sierra $

DROP PACKAGE BODY &&test_case_user..xplore;
DROP PACKAGE      &&test_case_user..xplore;

DROP TABLE &&test_case_user..sql_monitor;
DROP TABLE &&test_case_user..sql_plan_statistics_all;
DROP TABLE &&test_case_user..plan_table_all;
DROP TABLE &&test_case_user..discovered_plan;
DROP TABLE &&test_case_user..xplore_test;
DROP TABLE &&test_case_user..baseline_parameter_cbo;

DROP SEQUENCE &&test_case_user..xplore_line_id;
