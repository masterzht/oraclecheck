REM $Header: xhume/uninstall.sql 11.4.3.5 2011/08/10 carlos.sierra $

SET DEF ON

ACC test_case_user PROMPT 'Test Case User: ';

START drop_user_objects.sql;
