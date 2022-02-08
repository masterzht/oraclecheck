REM $Header: xhume/install.sql 11.4.3.5 2011/08/10 carlos.sierra $

SET DEF ON

ACC test_case_user PROMPT 'Test Case User: ';
ACC test_case_password PROMPT 'Password: ';

GRANT DBA TO &&test_case_user.;
GRANT SELECT ANY DICTIONARY TO &&test_case_user.;
GRANT DELETE ON sys.wri$_optstat_histgrm_history TO &&test_case_user.;
GRANT DELETE ON sys.wri$_optstat_histhead_history TO &&test_case_user.;
GRANT DELETE ON sys.wri$_optstat_ind_history TO &&test_case_user.;
GRANT DELETE ON sys.wri$_optstat_tab_history TO &&test_case_user.;

CONN &&test_case_user./&&test_case_password.
START user_objects.sql
START xhume.pks
START xhume.pkb
START create_xhume_script.sql

PRO
PRO Installation completed.
PRO You are now connected as &&test_case_user.
PRO
PRO 1. Review xhume_script.sql
PRO 2. Set CBO env if needed
PRO 3. Execute @xhume_script.sql
PRO
