REM $Header: xplore/install.sql 11.4.3.5 2011/08/10 carlos.sierra $

SET DEF ON

ACC test_case_user PROMPT 'Test Case User: ';
ACC test_case_password PROMPT 'Password: ';

START sys_views.sql

GRANT DBA TO &&test_case_user.;
GRANT SELECT ANY DICTIONARY TO &&test_case_user.;

CONN &&test_case_user./&&test_case_password.
START user_objects.sql
START xplore.pks
START xplore.pkb

PRO
PRO Installation completed.
PRO You are now connected as &&test_case_user..
PRO
PRO 1. Set CBO env if needed
PRO 2. Execute @create_xplore_script.sql
PRO
