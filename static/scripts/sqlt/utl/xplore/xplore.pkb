CREATE OR REPLACE PACKAGE BODY xplore AS
/* $Header: xplore/xplore.pkb 12.2.171004 October 4th,2017 carlos.sierra mauro.pagano abel.macias@oracle.com $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   * 171004 Update tool version.
   * ------------------------- */
  TOOL_VERSION         CONSTANT VARCHAR2(32)  := '12.2.171004';
  NOTE_NUMBER          CONSTANT VARCHAR2(32)  := '215187.1';
  TOOL_DEVELOPER       CONSTANT VARCHAR2(32)  := 'abel.macias';
  TOOL_DEVELOPER_EMAIL CONSTANT VARCHAR2(32)  := 'abel.macias@oracle.com';
  COPYRIGHT            CONSTANT VARCHAR2(128) := 'Copyright (c) 2000-2017, Oracle Corporation. All rights reserved.';
  HEADING_DATE_FORMAT  CONSTANT VARCHAR2(32)  := 'YYYY/MM/DD';
  LOAD_DATE_FORMAT     CONSTANT VARCHAR2(32)  := 'YYYY-MM-DD/HH24:MI:SS'; -- 2010-03-03/08:45:04

  /***********************************************************************************************/

  PROCEDURE print_line (
    p_line VARCHAR2 ) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(SUBSTR(p_line, 1, 255));
  END print_line;

  /***********************************************************************************************/

  PROCEDURE set_baseline (
    p_baseline_id IN INTEGER )
  IS
    l_name sqlt$_v$parameter_cbo.name%TYPE;
    l_value sqlt$_v$parameter_cbo.value%TYPE;
    l_alter VARCHAR2(32767);
    l_scope VARCHAR2(32767);

    PROCEDURE process_alter (
      p_command IN VARCHAR2 )
    IS
    BEGIN
      print_line(p_command);
      EXECUTE IMMEDIATE REPLACE(p_command, ';');
    EXCEPTION
      WHEN OTHERS THEN
        print_line(SQLERRM);
    END process_alter;
  BEGIN
    print_line('--');
    print_line('-- begin set_baseline');
    print_line('--');

    FOR i IN (WITH
              param_cbo AS (
              SELECT /*+ materialize */ *
                FROM sqlt$_v$parameter_cbo
               WHERE type IN (1, 2, 3) -- Boolean, String, Integer
                 AND (isses_modifiable = 'TRUE' OR issys_modifiable = 'IMMEDIATE')
               UNION
              SELECT *
                FROM sqlt$_v$parameter_exadata
               WHERE type IN (1, 2, 3) -- Boolean, String, Integer
                 AND (isses_modifiable = 'TRUE' OR issys_modifiable = 'IMMEDIATE')
              ),
              baseline AS (
              SELECT /*+ materialize */ *
                FROM baseline_parameter_cbo -- only those parameters and fix control captured by create_xplore_script
               WHERE baseline_id = p_baseline_id
                 AND name <> '_fix_control')
              SELECT b.*
                FROM param_cbo p,
                     baseline b
               WHERE LOWER(p.name) = LOWER(b.name)
                 AND LOWER(p.value) <> LOWER(b.value))
    LOOP
      l_name := LOWER(i.name);
      l_value := LOWER(i.value);
      l_alter := NULL;
      l_scope := NULL;

      IF i.isses_modifiable = 'TRUE' THEN
        l_alter := 'ALTER SESSION SET ';
      ELSIF i.issys_modifiable = 'IMMEDIATE' THEN
        l_alter := 'ALTER SYSTEM SET ';
        l_scope := ' SCOPE=MEMORY';
      END IF;

      IF SUBSTR(i.name, 1, 1) = CHR(95) THEN -- "_"
        l_alter := l_alter||'"'||i.name||'" = ';
      ELSE
        l_alter := l_alter||i.name||' = ';
      END IF;

      IF INSTR(l_alter, 'ALTER') = 0 THEN
        NULL;
      ELSIF i.type = 1 THEN -- Boolean
        l_alter := l_alter||i.value;
        process_alter(l_alter||l_scope||';');
      ELSIF i.type = 2 THEN -- String
        l_alter := l_alter||''''||i.value||'''';
        process_alter(l_alter||l_scope||';');
      ELSIF i.type = 3 THEN -- Integer
        IF l_name IN (
        '_db_file_optimizer_read_count',
        '_optimizer_extended_stats_usage_control',
        '_optimizer_fkr_index_cost_bias',
        '_optimizer_max_permutations',
        '_sort_elimination_cost_ratio',
        'db_file_multiblock_read_count',
        'hash_area_size',
        'optimizer_dynamic_sampling',
        'optimizer_index_caching',
        'optimizer_index_cost_adj',
        'sort_area_size' )
        THEN
          l_alter := l_alter||i.value;
          process_alter(l_alter||l_scope||';');
        END IF;
      END IF;
    END LOOP;

    FOR i IN (WITH
              fix_ctl AS (
              SELECT /*+ materialize */ *
                FROM v$session_fix_control
               WHERE session_id = SYS_CONTEXT('USERENV', 'SID')),
              baseline AS (
              SELECT /*+ materialize */ *
                FROM baseline_parameter_cbo -- only those parameters and fix control captured by create_xplore_script
               WHERE baseline_id = p_baseline_id
                 AND name = '_fix_control')
              SELECT b.*
                FROM fix_ctl f,
                     baseline b
               WHERE TO_CHAR(f.bugno) = SUBSTR(b.value, 1, INSTR(b.value, ':') - 1)
                 AND f.bugno||':'||f.value <> b.value
               ORDER BY
                     b.value)
    LOOP
      l_alter := 'ALTER SESSION SET "_fix_control" = '''||i.value||''';';
      process_alter(l_alter);
    END LOOP;

    print_line('--');
    print_line('-- end set_baseline');
    print_line('--');
  END set_baseline;

  /***********************************************************************************************/

  PROCEDURE create_xplore_script (
    p_xplore_method      IN VARCHAR2 DEFAULT 'XECUTE',
    p_cbo_parameters     IN VARCHAR2 DEFAULT 'Y',
    p_exadata_parameters IN VARCHAR2 DEFAULT 'Y',
    p_fix_control        IN VARCHAR2 DEFAULT 'Y',
    p_sql_monitor        IN VARCHAR2 DEFAULT 'N' )
  IS
    l_baseline_id INTEGER;
    l_test_id INTEGER := 0;
    l_name sqlt$_v$parameter_cbo.name%TYPE;
    l_value sqlt$_v$parameter_cbo.value%TYPE;
    l_alter VARCHAR2(32767);
    l_scope VARCHAR2(32767);
    l_unique_id VARCHAR2(32767);
    l_xplore_method VARCHAR2(10);
    l_cbo_parameters CHAR(1);
    l_exadata_parameters CHAR(1);
    l_fix_control CHAR(1);
    l_sql_monitor CHAR(1);

    PROCEDURE print_test (
      p_name        IN VARCHAR2,
      p_value_set   IN VARCHAR2,
      p_value_reset IN VARCHAR2 )
    IS
      l_alter_set VARCHAR2(32767);
      l_alter_reset VARCHAR2(32767);
    BEGIN
      IF p_value_set = p_value_reset THEN
        RETURN;
      END IF;

      l_test_id := l_test_id + 1;
      l_unique_id := 'xplore_{'||LPAD(l_baseline_id, 3, '0')||'}_[^^run_id.]_('||LPAD(l_test_id, 5, '0')||')';
      l_alter_set := REPLACE(l_alter, 'VALUE', p_value_set);
      l_alter_reset := REPLACE(l_alter, 'VALUE', p_value_reset);

      print_line('--');
      print_line('CONN ^^connected_user./^^user_password.');
      print_line('EXEC xplore.set_baseline('||l_baseline_id||');');
      print_line(l_alter_set);

      IF l_xplore_method = 'XECUTE' THEN
        print_line('ALTER SESSION SET STATISTICS_LEVEL = ALL;');
        print_line('DEF unique_id = "'||l_unique_id||'"');
        print_line('@^^script_with_sql.');
      ELSE
        print_line('SET BLO .');
        print_line('GET ^^script_with_sql.');
        print_line('.');
        print_line('C/;/');
        print_line('0 EXPLAIN PLAN SET statement_id = '''||l_unique_id||''' INTO plan_table_all FOR');
        print_line('L');
        print_line('/');
      END IF;

      print_line('WHENEVER SQLERROR CONTINUE;');
      print_line(l_alter_reset);
      print_line('EXEC xplore.snapshot_plan('''||l_unique_id||''', '''||l_xplore_method||''', '''||l_sql_monitor||''');');

      INSERT INTO xplore_test (
        baseline_id,
        test_id,
        unique_id,
        name,
        test,
        baseline_value
      ) VALUES (
        l_baseline_id,
        l_test_id,
        l_unique_id,
        p_name,
        l_alter_set,
        p_value_reset
      );
    END print_test;

  BEGIN
    l_xplore_method := NVL(UPPER(SUBSTR(TRIM(p_xplore_method), 1, 6)), 'XECUTE');
    l_cbo_parameters := NVL(UPPER(SUBSTR(TRIM(p_cbo_parameters), 1, 1)), 'Y');
    l_exadata_parameters := NVL(UPPER(SUBSTR(TRIM(p_exadata_parameters), 1, 1)), 'Y');
    l_fix_control := NVL(UPPER(SUBSTR(TRIM(p_fix_control), 1, 1)), 'Y');
    l_sql_monitor := NVL(UPPER(SUBSTR(TRIM(p_sql_monitor), 1, 1)), 'N');

    IF l_xplore_method NOT IN ('XECUTE', 'XPLAIN') THEN
      print_line('XPLORE method must be "XECUTE" or "XPLAIN"');
      RETURN;
    END IF;

    IF l_cbo_parameters NOT IN ('Y', 'N') THEN
      print_line('CBO Parameters must be "Y" or "N"');
      RETURN;
    END IF;

    IF l_exadata_parameters NOT IN ('Y', 'N') THEN
      print_line('Exadata Parameters must be "Y" or "N"');
      RETURN;
    END IF;

    IF l_fix_control NOT IN ('Y', 'N') THEN
      print_line('Fix Control must be "Y" or "N"');
      RETURN;
    END IF;

    IF l_sql_monitor NOT IN ('N', 'Y') THEN
      print_line('SQL Monitor must be "N" or "Y"');
      RETURN;
    END IF;

    IF l_cbo_parameters = 'N' AND l_exadata_parameters = 'N' AND l_fix_control = 'N' THEN
      print_line('All 3 parameters are "N": CBO, Exadata and Fixed Control');
      RETURN;
    END IF;

    SELECT NVL(MAX(baseline_id), 0) + 1
      INTO l_baseline_id
      FROM baseline_parameter_cbo;

    print_line('SET DEF ON ECHO OFF TERM ON APPI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;');
    print_line('SET SERVEROUT ON SIZE UNL;');
    print_line('SET ESC ON SQLBL ON;');
    print_line('SPO xplore_script_'||l_baseline_id||'.log;');
    print_line('COL connected_user NEW_V connected_user FOR A30;');
    print_line('SELECT user connected_user FROM DUAL;');
    print_line('PRO');
    print_line('PRO Parameter 1:');
    print_line('PRO Name of SCRIPT file that contains SQL to be xplored (required)');
    IF l_xplore_method = 'XECUTE' THEN
      print_line('PRO Note: SCRIPT must contain comment /* ^^unique_id */');
    END IF;
    print_line('PRO');
    print_line('SET DEF ^ ECHO OFF;');
    print_line('DEF script_with_sql = ''^1'';');
    print_line('PRO');
    print_line('PRO Parameter 2:');
    print_line('PRO Password for ^^connected_user. (required)');
    print_line('PRO');
    print_line('DEF user_password = ''^2'';');
    print_line('PRO');
    print_line('PRO Value passed to xplore_script.sql:');
    print_line('PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
    print_line('PRO SCRIPT_WITH_SQL: ^^script_with_sql');
    print_line('PRO');
    print_line('PRO -- begin common');
    print_line('PRO DEF _SQLPLUS_RELEASE');
    print_line('PRO SELECT USER FROM DUAL;');
    print_line('PRO SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD HH24:MI:SS'') current_time FROM DUAL;');
    print_line('PRO SELECT * FROM v$version;');
    print_line('PRO SELECT * FROM v$instance;');
    print_line('PRO SELECT name, value FROM v$parameter2 WHERE name LIKE ''%dump_dest'';');
    print_line('PRO SELECT directory_name||'' ''||directory_path directories FROM dba_directories WHERE directory_name LIKE ''SQLT$%'' OR directory_name LIKE ''TRCA$%'' ORDER BY 1;');
    print_line('PRO -- end common');
    print_line('PRO');
    print_line('SET VER ON HEA ON LIN 2000 PAGES 1000 TRIMS ON TI OFF TIMI OFF;');
    print_line('--');
    print_line('SET ECHO ON;');
    print_line('--in case of disconnects, suspect 6356566 and un-comment workaround in line below if needed');
    print_line('--ALTER SESSION SET "_cursor_plan_unparse_enabled" = FALSE;');
    print_line('WHENEVER SQLERROR EXIT SQL.SQLCODE;');
    print_line('--');
    print_line('COL run_id NEW_V run_id FOR A4;');
    print_line('SELECT LPAD((NVL(MAX(run_id), 0) + 1), 4, ''0'') run_id FROM xplore_test;');
    print_line('--');
    print_line('DELETE plan_table_all WHERE statement_id LIKE ''xplore_{'||LPAD(l_baseline_id, 3, '0')||'}_[^^run_id.]_(%)'';');
    print_line('EXEC xplore.set_baseline('||l_baseline_id||');');
    print_line('--');

    l_unique_id := 'xplore_{'||LPAD(l_baseline_id, 3, '0')||'}_[^^run_id.]_(00000)';

    IF l_xplore_method = 'XECUTE' THEN
      print_line('ALTER SESSION SET STATISTICS_LEVEL = ALL;');
      print_line('DEF unique_id = "'||l_unique_id||'"');
      print_line('@^^script_with_sql.');
    ELSE
      print_line('SET BLO .');
      print_line('GET ^^script_with_sql.');
      print_line('.');
      print_line('C/;/');
      print_line('0 EXPLAIN PLAN SET statement_id = '''||l_unique_id||''' INTO plan_table_all FOR');
      print_line('L');
      print_line('/');
    END IF;

    print_line('EXEC xplore.snapshot_plan('''||l_unique_id||''', '''||l_xplore_method||''', '''||l_sql_monitor||''');');
    print_line('WHENEVER SQLERROR CONTINUE;');

    -- test 0 is always the baseline, meaning just take cbo env captured from session and create first plan
    INSERT INTO xplore_test (
      baseline_id,
      test_id,
      unique_id,
      test
    ) VALUES (
      l_baseline_id,
      0,
      l_unique_id,
      'BASELINE'
    );

    -- create tests only for parameters (cbo and/or exadata)
    IF l_cbo_parameters = 'Y' OR l_exadata_parameters = 'Y' THEN
      FOR i IN (SELECT type,
                       name,
                       value,
                       display_value,
                       isdefault,
                       isses_modifiable,
                       issys_modifiable,
                       ismodified
                  FROM sqlt$_v$parameter_cbo
                 WHERE l_cbo_parameters = 'Y'
                   AND type IN (1, 2, 3) -- Boolean, String, Integer
                   AND (isses_modifiable = 'TRUE' OR issys_modifiable = 'IMMEDIATE')
                 UNION
                SELECT type,
                       name,
                       value,
                       display_value,
                       isdefault,
                       isses_modifiable,
                       issys_modifiable,
                       ismodified
                  FROM sqlt$_v$parameter_exadata
                 WHERE l_exadata_parameters = 'Y'
                   AND type IN (1, 2, 3) -- Boolean, String, Integer
                   AND (isses_modifiable = 'TRUE' OR issys_modifiable = 'IMMEDIATE')
                 ORDER BY
                       1, 2)
      LOOP
        INSERT INTO baseline_parameter_cbo (
          baseline_id,
          name,
          type,
          value,
          display_value,
          isdefault,
          isses_modifiable,
          issys_modifiable,
          ismodified
        ) VALUES (
          l_baseline_id,
          i.name,
          i.type,
          i.value,
          i.display_value,
          i.isdefault,
          i.isses_modifiable,
          i.issys_modifiable,
          i.ismodified
        );

        l_name := LOWER(i.name);
        l_value := LOWER(i.value);
        l_alter := NULL;
        l_scope := NULL;

        IF i.isses_modifiable = 'TRUE' THEN
          l_alter := 'ALTER SESSION SET ';
        ELSIF i.issys_modifiable = 'IMMEDIATE' THEN
          l_alter := 'ALTER SYSTEM SET ';
          l_scope := ' SCOPE=MEMORY';
        END IF;

        IF SUBSTR(i.name, 1, 1) = CHR(95) THEN -- "_"
          l_alter := l_alter||'"'||i.name||'" = ';
        ELSE
          l_alter := l_alter||i.name||' = ';
        END IF;

        IF i.type = 1 THEN -- Boolean
          l_alter := l_alter||'VALUE'||l_scope||';';

          IF l_value = 'true' THEN
            print_test(i.name, 'FALSE', i.value);
          ELSIF l_value = 'false' THEN
            print_test(i.name, 'TRUE', i.value);
          ELSE
            print_line('--');
            print_line('-- skip test on '||i.name||'. baseline value: '||i.value);
          END IF;
        ELSIF i.type = 2 THEN -- String
          l_alter := l_alter||'''VALUE'''||l_scope||';';

          FOR j IN (SELECT value
                      FROM sqlt$_v$parameter_lov
                     WHERE LOWER(name) = l_name
                       AND LOWER(value) <> l_value
                     ORDER BY
                           value)
          LOOP
            print_test(i.name, j.value, i.value);
          END LOOP;
        ELSIF i.type = 3 THEN -- Integer
          l_alter := l_alter||'VALUE'||l_scope||';';

          IF l_name = 'optimizer_index_cost_adj' THEN
            print_test(i.name, '1', i.value);
            print_test(i.name, '10', i.value);
            print_test(i.name, '25', i.value);
            print_test(i.name, '50', i.value);
            print_test(i.name, '100', i.value);
            print_test(i.name, '200', i.value);
            print_test(i.name, '400', i.value);
            print_test(i.name, '1000', i.value);
            print_test(i.name, '10000', i.value);
          ELSIF l_name = 'optimizer_index_caching' THEN
            print_test(i.name, '0', i.value);
            print_test(i.name, '12', i.value);
            print_test(i.name, '25', i.value);
            print_test(i.name, '50', i.value);
            print_test(i.name, '100', i.value);
          ELSIF l_name = 'optimizer_dynamic_sampling' THEN
            print_test(i.name, '0', i.value);
            print_test(i.name, '2', i.value);
            print_test(i.name, '4', i.value);
            print_test(i.name, '6', i.value);
            print_test(i.name, '8', i.value);
            print_test(i.name, '10', i.value);
          ELSIF l_name IN ('hash_area_size', 'sort_area_size') THEN
            print_test(i.name, i.value * 2, i.value);
            print_test(i.name, i.value * 8, i.value);
            print_test(i.name, i.value * 32, i.value);
          ELSIF l_name IN ('db_file_multiblock_read_count', '_db_file_optimizer_read_count') THEN
            print_test(i.name, '4', i.value);
            print_test(i.name, '8', i.value);
            print_test(i.name, '16', i.value);
            print_test(i.name, '32', i.value);
            print_test(i.name, '64', i.value);
            print_test(i.name, '128', i.value);
          ELSIF l_name = '_optimizer_max_permutations' THEN
            print_test(i.name, '100', i.value);
            print_test(i.name, '2000', i.value);
            print_test(i.name, '40000', i.value);
            print_test(i.name, '79999', i.value);
            print_test(i.name, '80000', i.value);
          ELSIF l_name = '_sort_elimination_cost_ratio' THEN
            print_test(i.name, '0', i.value);
            print_test(i.name, '3', i.value);
            print_test(i.name, '6', i.value);
            print_test(i.name, '12', i.value);
            print_test(i.name, '25', i.value);
            print_test(i.name, '50', i.value);
            print_test(i.name, '100', i.value);
            print_test(i.name, '1000', i.value);
          ELSIF l_name = '_optimizer_extended_stats_usage_control' THEN
            print_test(i.name, '255', i.value); -- FF through 10g
            print_test(i.name, '240', i.value); -- F0 in 11.1.0.6
            print_test(i.name, '224', i.value); -- E0 in 11.1.0.7-11.2.0.1
            print_test(i.name, '192', i.value); -- C0 in 11.2.0.2+
          ELSIF l_name = '_optimizer_fkr_index_cost_bias' THEN
            print_test(i.name, '2', i.value);
            print_test(i.name, '5', i.value);
            print_test(i.name, '10', i.value);
            print_test(i.name, '20', i.value);
          ELSE
            print_line('--');
            print_line('-- skip test on '||i.name||'. baseline value: '||i.value);
          END IF;
        ELSE
          print_line('--');
          print_line('-- skip test on '||i.name||'. baseline value: '||i.value);
        END IF;
      END LOOP;
    END IF;

    -- create tests for fix control
    IF l_fix_control = 'Y' THEN
      FOR i IN (SELECT *
                  FROM v$session_fix_control
                 WHERE session_id = SYS_CONTEXT('USERENV', 'SID')
                 ORDER BY bugno)
      LOOP
        l_name := '_fix_control';
        l_value := i.bugno||':'||i.value;

        INSERT INTO baseline_parameter_cbo (
          baseline_id,
          name,
          type,
          value,
          display_value,
          isdefault
        ) VALUES (
          l_baseline_id,
          l_name,
          2, -- String
          l_value,
          i.description,
          DECODE(i.is_default, 1, 'TRUE', 'FALSE')
        );

        l_alter := 'ALTER SESSION SET "'||l_name||'" = ''VALUE'';';

        IF i.value = 0 THEN
          print_test(l_name, i.bugno||':1', l_value);
        ELSIF i.value = 1 THEN
          print_test(l_name, i.bugno||':0', l_value);
        ELSE
          print_test(l_name, i.bugno||':0', l_value);
        END IF;
      END LOOP;
    END IF;

    print_line('--');
    print_line('CONN ^^connected_user./^^user_password.');
    print_line('SET TERM OFF ECHO OFF FEED OFF FLU OFF HEA OFF LIN 2000 LONGC 2000 LONG 2000000 NEWP NONE PAGES 0 SHOW OFF SQLC MIX TAB OFF TRIMS ON VER OFF TI OFF TIMI OFF ARRAY 100 SQLP SQL> BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;');
    print_line('SET SERVEROUT ON SIZE UNL FOR TRU;');
    print_line('SPO xplore_report_'||l_baseline_id||'.html;');
    print_line('SELECT column_value FROM TABLE(xplore.generate_xplore_report('||l_baseline_id||', ^^run_id.));');
    print_line('SPO OFF;');
    print_line('--');
    IF l_xplore_method = 'XECUTE' AND l_sql_monitor = 'Y' THEN
      print_line('SPO monitor_script.sql');
      print_line('EXEC xplore.create_monitor_script('||l_baseline_id||');');
      print_line('SPO OFF;');
      print_line('@monitor_script.sql');
      print_line('--');
    END IF;
    print_line('WHENEVER SQLERROR CONTINUE;');
    print_line('SET TERM ON;');
    IF l_xplore_method = 'XECUTE' AND l_sql_monitor = 'Y' THEN
      print_line('HOS zip -mT xplore_sql_monitor_report_'||l_baseline_id||' monitor_script.sql xplore_sql_monitor_report_'||l_baseline_id||'_*.html');
      print_line('HOS zip -mT xplore_'||l_baseline_id||' xplore_sql_monitor_report_'||l_baseline_id||'.zip xplore_*_'||l_baseline_id||'.*');
    ELSE
      print_line('HOS zip -mT xplore_'||l_baseline_id||' xplore_*_'||l_baseline_id||'.*');
    END IF;
    print_line('UNDEFINE 1 2 unique_id run_id script_with_sql user_password;');
    print_line('SET DEF ON;');
    print_line('PRO XPLORE Completed.');
    print_line('QUIT;');

    COMMIT;
  END create_xplore_script;

  /***********************************************************************************************/

  PROCEDURE create_monitor_script (
    p_baseline_id IN NUMBER )
  IS
  BEGIN
    FOR i IN (SELECT DISTINCT test_id FROM sql_monitor WHERE baseline_id = p_baseline_id ORDER BY 1)
    LOOP
      print_line('SPO xplore_sql_monitor_report_'||p_baseline_id||'_'||LPAD(i.test_id, 5, '0')||'.html;');
      print_line('SELECT active_report FROM sql_monitor WHERE baseline_id = '||p_baseline_id||' AND run_id = ^^run_id. AND test_id = '||i.test_id||';');
      print_line('SPO OFF;');
      print_line('--');
    END LOOP;
  END create_monitor_script;

  /***********************************************************************************************/

  PROCEDURE snapshot_plan (
    p_unique_id     IN VARCHAR2,
    p_xplore_method IN VARCHAR2 DEFAULT 'XECUTE',
    p_sql_monitor   IN VARCHAR2 DEFAULT 'N' )
  IS
    l_baseline_id NUMBER;
    l_run_id NUMBER;
    l_test_id NUMBER;
    l_opt VARCHAR2(32767);
    l_expr VARCHAR2(32767);
    l_ora_hash NUMBER;
    l_list_of_columns VARCHAR2(32767);
    l_sql VARCHAR2(32767);
    test_rec xplore_test%ROWTYPE;
    l_access_predicates VARCHAR2(32767);
    l_filter_predicates VARCHAR2(32767);
    l_xplore_method VARCHAR2(10);

    FUNCTION get_index_column_names (
      p_index_owner IN VARCHAR2,
      p_index_name  IN VARCHAR2 )
    RETURN VARCHAR2
    IS
      l_column_name VARCHAR2(32767);
      l_return VARCHAR2(32767) := NULL;
      idx_rec dba_indexes%ROWTYPE;
    BEGIN
      BEGIN
        SELECT *
          INTO idx_rec
          FROM dba_indexes
         WHERE owner = p_index_owner
           AND index_name = p_index_name;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
           RETURN p_index_name;
       END;

      FOR i IN (SELECT x.table_owner,
                       x.table_name,
                       x.column_name,
                       x.descend,
                       t.hidden_column,
                       r.column_expression,
                       --e.extension,
                       t.data_default
                  FROM dba_ind_columns x,
                       dba_tab_cols t,
                       dba_ind_expressions r
                       --dba_stat_extensions e (not avail on 10g)
                 WHERE x.index_owner = p_index_owner
                   AND x.index_name = p_index_name
                   AND x.table_owner = t.owner
                   AND x.table_name = t.table_name
                   AND x.column_name = t.column_name
                   AND x.table_owner = r.table_owner(+)
                   AND x.table_name = r.table_name(+)
                   AND x.index_owner = r.index_owner(+)
                   AND x.index_name = r.index_name(+)
                   AND x.column_position = r.column_position(+)
                   --AND x.table_owner = e.owner(+)
                   --AND x.table_name = e.table_name(+)
                   --AND x.column_name = e.extension_name(+)
                 ORDER BY
                       x.column_position)
      LOOP
        IF i.hidden_column = 'YES' THEN
          IF i.column_expression IS NOT NULL THEN
            l_column_name := REPLACE(DBMS_LOB.SUBSTR(i.column_expression), ' ');
          --ELSIF i.extension IS NOT NULL THEN
          --  l_column_name := REPLACE(DBMS_LOB.SUBSTR(i.extension), ' ');
          ELSIF i.data_default IS NOT NULL THEN
            l_column_name := REPLACE(DBMS_LOB.SUBSTR(i.data_default), ' ');
          ELSE
            l_column_name := i.column_name;
          END IF;
          IF l_column_name <> i.column_name AND l_column_name = UPPER(l_column_name) THEN
            l_column_name := REPLACE(l_column_name, '"');
          END IF;
          IF i.descend = 'DESC' THEN
            l_column_name := l_column_name||'(DESC)';
          END IF;
        ELSE
          l_column_name := i.column_name;
        END IF;

        IF i.table_name <> idx_rec.table_name THEN
          l_column_name := i.table_name||'.'||l_column_name;
        END IF;

        IF i.table_owner <> idx_rec.table_owner THEN
          l_column_name := i.table_owner||'.'||l_column_name;
        END IF;

        IF l_return IS NULL THEN
          l_return := l_column_name;
        ELSE
          l_return := l_return||' '||l_column_name;
        END IF;
      END LOOP;

      RETURN idx_rec.table_name||' ('||l_return||')';
    EXCEPTION
      WHEN OTHERS THEN
        RETURN SQLERRM;
    END get_index_column_names;

    FUNCTION get_list_of_columns (
      p_source_table IN VARCHAR2,
      p_source_owner IN VARCHAR2 DEFAULT 'SYS' )
    RETURN VARCHAR2
    IS
      list_of_columns VARCHAR2(32767) := NULL;
    BEGIN
      FOR i IN (SELECT LOWER(s.column_name) column_name
                  FROM sys.dba_tab_columns s
                 WHERE s.owner      = UPPER(p_source_owner)
                   AND s.table_name = UPPER(p_source_table)
                 ORDER BY
                       s.column_id)
      LOOP
        list_of_columns := list_of_columns||', '||i.column_name;
      END LOOP;
      RETURN list_of_columns;
    END get_list_of_columns;

  BEGIN
    l_baseline_id := TO_NUMBER(SUBSTR(p_unique_id, INSTR(p_unique_id, '{') + 1, INSTR(p_unique_id, '}') - INSTR(p_unique_id, '{') - 1));
    l_run_id      := TO_NUMBER(SUBSTR(p_unique_id, INSTR(p_unique_id, '[') + 1, INSTR(p_unique_id, ']') - INSTR(p_unique_id, '[') - 1));
    l_test_id     := TO_NUMBER(SUBSTR(p_unique_id, INSTR(p_unique_id, '(') + 1, INSTR(p_unique_id, ')') - INSTR(p_unique_id, '(') - 1));
    l_xplore_method := NVL(UPPER(SUBSTR(TRIM(p_xplore_method), 1, 6)), 'XECUTE');

    BEGIN -- xplore_test
      SELECT *
        INTO test_rec
        FROM xplore_test
       WHERE baseline_id = l_baseline_id
         AND run_id IS NULL
         AND test_id = l_test_id;

      test_rec.run_id := l_run_id;
      test_rec.unique_id := REPLACE(test_rec.unique_id, '^^run_id.', LPAD(test_rec.run_id, 4, '0'));

      SELECT plan_hash_value,
             optimizer_cost,
             buffer_gets,
             cpu_time,
             disk_reads,
             elapsed_time,
             rows_processed,
             sql_id,
             child_number
        INTO test_rec.plan_hash_value,
             test_rec.plan_cost,
             test_rec.buffer_gets,
             test_rec.cpu_time,
             test_rec.disk_reads,
             test_rec.elapsed_time,
             test_rec.rows_processed,
             test_rec.sql_id,
             test_rec.child_number
        FROM v$sql
       WHERE sql_text LIKE '%'||p_unique_id||'%'
         AND plan_hash_value <> 0
         AND command_type IN (1, 2, 3, 6, 7, 9, 50, 71, 74, 189)
--         AND child_number = 0 -- 170908 often fails with ORA-01403: no data found 
         AND parsing_user_id = UID
         AND sql_text NOT LIKE '%FROM v$sql%';

      IF l_xplore_method = 'XECUTE' THEN
        SELECT cardinality
          INTO test_rec.cardinality
          FROM v$sql_plan
         WHERE sql_id = test_rec.sql_id
           AND plan_hash_value = test_rec.plan_hash_value
           AND child_number = test_rec.child_number
           AND id = (SELECT MIN(id)
                       FROM v$sql_plan
                      WHERE sql_id = test_rec.sql_id
                        AND plan_hash_value = test_rec.plan_hash_value
                        AND child_number = test_rec.child_number
                        AND cardinality IS NOT NULL);
      ELSE
        SELECT cardinality
          INTO test_rec.cardinality
          FROM plan_table_all
         WHERE statement_id = p_unique_id
           AND id = (SELECT MIN(id)
                       FROM plan_table_all
                      WHERE statement_id = p_unique_id
                        AND cardinality IS NOT NULL);
      END IF;

      -- this algorithm has to be in sync with sqlt$t.sqlt_plan_hash_value
      BEGIN -- xplore.snapshot_plan.sqlt_plan_hash_value
        test_rec.sqlt_plan_hash_value := 0;
        test_rec.sqlt_plan_hash_value2 := 0;
        FOR i IN (SELECT id,
                         parent_id,
                         operation,
                         options,
                         object_owner,
                         object_name,
                         object_type,
                         access_predicates,
                         filter_predicates
                    FROM v$sql_plan
                   WHERE l_xplore_method = 'XECUTE'
                     AND sql_id = test_rec.sql_id
                     AND child_number = test_rec.child_number
                     AND plan_hash_value = test_rec.plan_hash_value
                     AND id > 0
                   UNION ALL
                  SELECT id,
                         parent_id,
                         operation,
                         options,
                         object_owner,
                         object_name,
                         object_type,
                         access_predicates,
                         filter_predicates
                    FROM plan_table_all
                   WHERE l_xplore_method = 'XPLAIN'
                     AND statement_id = p_unique_id
                     AND id > 0)
        LOOP
          l_opt := TRIM(REPLACE(i.options, 'STORAGE'));
          l_expr := i.id||i.operation||i.parent_id||l_opt;
          IF i.object_type LIKE 'INDEX%' OR i.operation LIKE 'INDEX%' THEN
            l_expr := l_expr||get_index_column_names(i.object_owner, i.object_name);
          ELSIF i.object_type LIKE 'TABLE%' OR i.operation LIKE 'TABLE%' OR i.object_type = 'VIEW' OR i.operation = 'VIEW' THEN
            IF i.object_name NOT LIKE 'SYS_TEMP%' AND i.object_name NOT LIKE 'index$_join$_%' AND i.object_name NOT LIKE 'VW_ST%' THEN
              l_expr := l_expr||i.object_name;
            END IF;
          END IF;
          SELECT ORA_HASH(l_expr) INTO l_ora_hash FROM DUAL;
          test_rec.sqlt_plan_hash_value := test_rec.sqlt_plan_hash_value + l_ora_hash;
          test_rec.sqlt_plan_hash_value2 := test_rec.sqlt_plan_hash_value2 + l_ora_hash;
          IF i.access_predicates IS NOT NULL THEN
            l_access_predicates := DBMS_LOB.SUBSTR(i.access_predicates);
            SELECT ORA_HASH(l_access_predicates) INTO l_ora_hash FROM DUAL;
            test_rec.sqlt_plan_hash_value2 := test_rec.sqlt_plan_hash_value2 + l_ora_hash;
          END IF;
          IF i.filter_predicates IS NOT NULL THEN
            l_filter_predicates := DBMS_LOB.SUBSTR(i.filter_predicates);
            SELECT ORA_HASH(l_filter_predicates) INTO l_ora_hash FROM DUAL;
            test_rec.sqlt_plan_hash_value2 := test_rec.sqlt_plan_hash_value2 + l_ora_hash;
          END IF;
        END LOOP;
        test_rec.sqlt_plan_hash_value := MOD(test_rec.sqlt_plan_hash_value, 1e5);
        test_rec.sqlt_plan_hash_value2 := MOD(test_rec.sqlt_plan_hash_value2, 1e5);
      END;

      INSERT INTO xplore_test VALUES test_rec;
    END; -- xplore_test

    BEGIN -- discovered_plan
      IF l_xplore_method = 'XECUTE' THEN
        INSERT INTO discovered_plan (
          baseline_id,
          run_id,
          test_id,
          line_id,
          plan_table_output
        )
        SELECT
          l_baseline_id,
          l_run_id,
          l_test_id,
          xplore_line_id.NEXTVAL,
          plan_table_output
        FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(test_rec.sql_id, test_rec.child_number, 'ALLSTATS COST'));
      ELSE
        INSERT INTO discovered_plan (
          baseline_id,
          run_id,
          test_id,
          line_id,
          plan_table_output
        )
        SELECT
          l_baseline_id,
          l_run_id,
          l_test_id,
          xplore_line_id.NEXTVAL,
          plan_table_output
        FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE_ALL', p_unique_id, 'TYPICAL'));
      END IF;
    END; -- discovered_plan

    BEGIN -- sql_plan_statistics_all
      IF l_xplore_method = 'XECUTE' THEN
        l_list_of_columns := get_list_of_columns('v_$sql_plan_statistics_all');
        l_sql := 'INSERT INTO sql_plan_statistics_all (baseline_id, run_id, test_id, sqlt_plan_hash_value, sqlt_plan_hash_value2'||
        l_list_of_columns||') SELECT :baseline_id, :run_id, :test_id, :sqlt_plan_hash_value, :sqlt_plan_hash_value2'||
        l_list_of_columns||' FROM v$sql_plan_statistics_all '||
        'WHERE sql_id = :sql_id AND child_number = :child_number AND plan_hash_value = :plan_hash_value';

        BEGIN
          EXECUTE IMMEDIATE 'DELETE sql_plan_statistics_all WHERE baseline_id = :baseline_id AND run_id = :run_id AND test_id = :test_id' USING
          IN l_baseline_id, IN l_run_id, IN l_test_id;
          EXECUTE IMMEDIATE l_sql USING
          IN l_baseline_id, IN l_run_id, IN l_test_id, IN test_rec.sqlt_plan_hash_value, IN test_rec.sqlt_plan_hash_value2,
          IN test_rec.sql_id, IN test_rec.child_number, IN test_rec.plan_hash_value;
        EXCEPTION
          WHEN OTHERS THEN
            print_line('-- '||SQLERRM);
            print_line('-- '||l_sql);
            print_line('-- "'||l_baseline_id||'" "'||l_run_id||'" "'||l_test_id||'" "'||test_rec.sqlt_plan_hash_value||'" "'||test_rec.sqlt_plan_hash_value2||'" "'||test_rec.sql_id||'" "'||test_rec.child_number||'" "'||test_rec.plan_hash_value||'".');
            print_line('-- sql_plan_statistics_all');
        END;
      END IF;
    END; -- sql_plan_statistics_all

    DECLARE -- sql_monitor
      l2_version v$instance.version%TYPE;
      l2_sql VARCHAR2(32767);
      l2_prefix VARCHAR2(32767);
      l2_suffix VARCHAR2(32767);
      l2_type VARCHAR2(32767);
      l2_report_level VARCHAR2(32767) := 'ALL';
      mon_rec sql_monitor%ROWTYPE;
    BEGIN
      IF l_xplore_method = 'XECUTE' AND p_sql_monitor = 'Y' THEN
        SELECT version INTO l2_version FROM v$instance;

        IF l2_version > '11' THEN
          l2_sql := 'BEGIN :report := :prefix||DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id => :sql_id, report_level => :report_level, type => :type)||:suffix; END;';

          IF l2_version >= '11.2' THEN
            l2_type := 'ACTIVE';
            l2_prefix := NULL;
            l2_suffix := NULL;
          ELSE -- 11.1
            l2_type := 'XML';

            -- from Benoit -> Uday
            l2_prefix := '<html>
 <head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
  <base href="http://download.oracle.com/otn_software/"/>
  <script language="javascript" type="text/javascript" src="emviewers/scripts/flashver.js">
   <!--Test flash version-->
  </script>
  <style>
      body { margin: 0px; overflow:hidden }
    </style>
 </head>
 <body scroll="no">
  <script type="text/xml">
   <!--FXTMODEL-->
';
            l2_suffix := '
   <!--FXTMODEL-->
  </script>
  <script language="JavaScript" type="text/javascript" src="emviewers/scripts/loadswf.js">
   <!--Load report viewer-->
  </script>
  <iframe name="_history" frameborder="0" scrolling="no" width="22" height="0">
   <html>
    <head>
     <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>
     <script type="text/javascript" language="JavaScript1.2" charset="utf-8">
                var v = new top.Vars(top.getSearch(window));
                var fv = v.toString("$_");
              </script>
    </head>
    <body>
     <script type="text/javascript" language="JavaScript1.2" charset="utf-8" src="emviewers/scripts/document.js">
      <!--Run document script-->
     </script>
    </body>
   </html>
  </iframe>
 </body>
</html>';
          END IF;

          BEGIN
            EXECUTE IMMEDIATE l2_sql USING OUT mon_rec.active_report, IN l2_prefix, IN test_rec.sql_id, IN l2_report_level, IN l2_type, IN l2_suffix;
          EXCEPTION
            WHEN OTHERS THEN
              print_line('-- '||SQLERRM);
              print_line('-- '||l2_sql);
              print_line('-- "'||l_baseline_id||'" "'||l_run_id||'" "'||l_test_id||'" "'||test_rec.sqlt_plan_hash_value||'" "'||test_rec.sqlt_plan_hash_value2||'" "'||test_rec.sql_id||'" "'||test_rec.child_number||'" "'||test_rec.plan_hash_value||'".');
              print_line('-- sql_monitor');
              mon_rec.active_report := NULL;
          END;

          IF mon_rec.active_report IS NOT NULL AND DBMS_LOB.GETLENGTH(mon_rec.active_report) > 2000  THEN -- not empty
            mon_rec.baseline_id := l_baseline_id;
            mon_rec.run_id := l_run_id;
            mon_rec.test_id := l_test_id;
            INSERT INTO sql_monitor VALUES mon_rec;
          END IF;
        END IF;
      END IF;
    END; -- sql_monitor

    COMMIT;
  END snapshot_plan;

  /***********************************************************************************************/

  FUNCTION generate_xplore_report (
    p_baseline_id IN NUMBER,
    p_run_id      IN NUMBER )
  RETURN varchar2_table PIPELINED
  IS
    LF CONSTANT VARCHAR2(32767) := CHR(10);

    my_count INTEGER;
    my_cost VARCHAR2(32767);
    my_tests VARCHAR2(32767);
    my_card VARCHAR2(32767);
    my_card_tests VARCHAR2(32767);

    FUNCTION insert_title (
      p_count IN INTEGER )
    RETURN BOOLEAN
    IS
    BEGIN
      IF MOD(p_count, 30) = 1 THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
      END IF;
    END insert_title;

  BEGIN
    /* -------------------------
     * Header
     * ------------------------- */
   BEGIN
      PIPE ROW('<html>');
      PIPE ROW('<!-- $Header: '||NOTE_NUMBER||' XPLORE '||TOOL_VERSION||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $ -->');
      PIPE ROW('<!-- '||COPYRIGHT||' -->');
      PIPE ROW('<!-- Author: '||TOOL_DEVELOPER_EMAIL||' -->');
      PIPE ROW('<head><title>XPLORE baseline_id:'||p_baseline_id||' run_id:'||p_run_id||'</title>');
      PIPE ROW('<style type="text/css">');
      PIPE ROW('a {font-weight:bold; color:#663300;}');
      PIPE ROW('body {font:10pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}');
      PIPE ROW('h1 {font-size:16pt; font-weight:bold; color:#336699;}');
      PIPE ROW('h2 {font-size:14pt; font-weight:bold; color:#336699;}');
      PIPE ROW('table {font-size:8pt; color:black; background:white;}');
      PIPE ROW('th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}');
      PIPE ROW('td {text-align:left; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}');
      PIPE ROW('td.left {text-align:left}');
      PIPE ROW('td.right {text-align:right}');
      PIPE ROW('td.title {font-weight:bold;text-align:right;background-color:#cccc99;color:#336699}');
      PIPE ROW('font.tablenote {font-size:8pt;font-style:italic;color:#336699}');
      PIPE ROW('font.footer {font-size:8pt; color:#999999;');
      PIPE ROW('</style>');
      PIPE ROW('</head><body><h1>XPLORE Report for baseline:'||p_baseline_id||' runid:'||p_run_id||'</h1>');
    EXCEPTION
      WHEN OTHERS THEN
        print_line('*** cannot print header: '||SQLERRM);
    END;

    /* -------------------------
     * Plans Summary
     * ------------------------- */
    BEGIN
      my_count := 0;
      FOR i IN (SELECT q.plan_hash_value,
                       COUNT(*) tests,
                       ROUND(MAX(q.plan_cost)) max_cost,
                       ROUND(MIN(q.plan_cost)) min_cost,
                       ROUND(MAX(q.buffer_gets)) max_buffer_gets,
                       ROUND(MIN(q.buffer_gets)) min_buffer_gets,
                       ROUND(MAX(q.cpu_time)/1000000, 3) max_cpu_time,
                       ROUND(MIN(q.cpu_time)/1000000, 3) min_cpu_time,
                       ROUND(MAX(q.disk_reads)) max_disk_reads,
                       ROUND(MIN(q.disk_reads)) min_disk_reads,
                       ROUND(MAX(q.elapsed_time)/1000000, 3) max_elapsed_time,
                       ROUND(MIN(q.elapsed_time)/1000000, 3) min_elapsed_time,
                       ROUND(MAX(q.rows_processed)) max_rows_processed,
                       ROUND(MIN(q.rows_processed)) min_rows_processed,
                       ROUND(MAX(q.cardinality)) max_cardinality,
                       ROUND(MIN(q.cardinality)) min_cardinality
                  FROM xplore_test q
                 WHERE q.baseline_id = p_baseline_id
                   AND q.run_id = p_run_id
                   AND q.plan_hash_value IS NOT NULL
                 GROUP BY
                       q.plan_hash_value
                 ORDER BY
                       q.plan_hash_value)
      LOOP
        my_count := my_count + 1;
        IF my_count = 1 THEN
          PIPE ROW(LF||'<h2>Plans Summary</h2>'||LF);
          PIPE ROW('Plans for each test have been captured into '||USER||'.SQL_PLAN_STATISTICS_ALL or '||USER||'.PLAN_TABLE_ALL.'||LF);
          PIPE ROW('<table>'||LF);
        END IF;

        IF insert_title(my_count) THEN
          PIPE ROW(
          '<tr>'||LF||
          '<th>#</th>'||
          '<th>Plan<br>Hash Value</th>'||
          '<th>Total<br>Tests</th>'||
          '<th>Max<br>Cost</th>'||
          '<th>Min<br>Cost</th>'||
          '<th>Max<br>Buffer<br>Gets</th>'||
          '<th>Min<br>Buffer<br>Gets</th>'||
          '<th>Max<br>CPU<br>(secs)</th>'||
          '<th>Min<br>CPU<br>(secs)</th>'||
          '<th>Max<br>Disk<br>Reads</th>'||
          '<th>Min<br>Disk<br>Reads</th>'||
          '<th>Max<br>ET<sup>1</sup><br>(secs)</th>'||
          '<th>Min<br>ET<sup>1</sup><br>(secs)</th>'||
          '<th>Max<br>Actual<br>Rows</th>'||
          '<th>Min<br>Actual<br>Rows</th>'||
          '<th>Max<br>Estim<br>Rows</th>'||
          '<th>Min<br>Estim<br>Rows</th>'||
          '</tr>'||LF);
        END IF;

        PIPE ROW(
        '<tr>'||LF||
        '<td class="title">'||my_count||'</td>'||
        '<td class="right">'||i.plan_hash_value||'</td>'||LF||
        '<td class="right">'||i.tests||'</td>'||
        '<td class="right">'||i.max_cost||'</td>'||
        '<td class="right">'||i.min_cost||'</td>'||
        '<td class="right">'||i.max_buffer_gets||'</td>'||
        '<td class="right">'||i.min_buffer_gets||'</td>'||
        '<td class="right">'||i.max_cpu_time||'</td>'||
        '<td class="right">'||i.min_cpu_time||'</td>'||
        '<td class="right">'||i.max_disk_reads||'</td>'||
        '<td class="right">'||i.min_disk_reads||'</td>'||
        '<td class="right">'||i.max_elapsed_time||'</td>'||
        '<td class="right">'||i.min_elapsed_time||'</td>'||
        '<td class="right">'||i.max_rows_processed||'</td>'||
        '<td class="right">'||i.min_rows_processed||'</td>'||
        '<td class="right">'||i.max_cardinality||'</td>'||
        '<td class="right">'||i.min_cardinality||'</td>'||
        '</tr>'||LF);
      END LOOP /* i */;

      IF my_count > 0 THEN
        PIPE ROW('</table>'||LF||
        '<font class="tablenote">(1) If tables are empty, then Elapsed Time is close to Parse Time.</font><br>'||LF);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_line('*** cannot display plans summary: '||SQLERRM);
    END;

    /* -------------------------
     * Discovered Plans
     * ------------------------- */
    BEGIN
      my_count := 0;
      FOR i IN (SELECT q.plan_hash_value,
                       q.sqlt_plan_hash_value,
                       q.sqlt_plan_hash_value2,
                       COUNT(*) tests,
                       ROUND(MAX(q.buffer_gets)) max_buffer_gets,
                       ROUND(MIN(q.buffer_gets)) min_buffer_gets,
                       ROUND(MAX(q.cpu_time)/1000000, 3) max_cpu_time,
                       ROUND(MIN(q.cpu_time)/1000000, 3) min_cpu_time,
                       ROUND(MAX(q.disk_reads)) max_disk_reads,
                       ROUND(MIN(q.disk_reads)) min_disk_reads,
                       ROUND(MAX(q.elapsed_time)/1000000, 3) max_elapsed_time,
                       ROUND(MIN(q.elapsed_time)/1000000, 3) min_elapsed_time,
                       ROUND(MAX(q.rows_processed)) max_rows_processed,
                       ROUND(MIN(q.rows_processed)) min_rows_processed,
                       ROUND(MAX(q.cardinality)) max_cardinality,
                       ROUND(MIN(q.cardinality)) min_cardinality,
                       (SELECT DECODE(COUNT(*), 0, NULL, 'B')
                          FROM xplore_test sq1
                         WHERE sq1.baseline_id = p_baseline_id
                           AND sq1.run_id = p_run_id
                           AND sq1.plan_hash_value = q.plan_hash_value
                           AND sq1.sqlt_plan_hash_value = q.sqlt_plan_hash_value
                           AND sq1.sqlt_plan_hash_value2 = q.sqlt_plan_hash_value2
                           AND sq1.test = 'BASELINE') b,
                       (SELECT DECODE(COUNT(*), 0, NULL, 'F')
                          FROM xplore_test sq2
                         WHERE sq2.baseline_id = p_baseline_id
                           AND sq2.run_id = p_run_id
                           AND sq2.plan_hash_value = q.plan_hash_value
                           AND sq2.sqlt_plan_hash_value = q.sqlt_plan_hash_value
                           AND sq2.sqlt_plan_hash_value2 = q.sqlt_plan_hash_value2
                           AND sq2.test LIKE '%fix_control%') f
                  FROM xplore_test q
                 WHERE q.baseline_id = p_baseline_id
                   AND q.run_id = p_run_id
                   AND q.plan_hash_value IS NOT NULL
                 GROUP BY
                       q.plan_hash_value,
                       q.sqlt_plan_hash_value,
                       q.sqlt_plan_hash_value2
                 ORDER BY
                       q.plan_hash_value,
                       q.sqlt_plan_hash_value,
                       q.sqlt_plan_hash_value2)
      LOOP
        my_count := my_count + 1;
        IF my_count = 1 THEN
          PIPE ROW(LF||'<h2>Discovered Plans</h2>'||LF);
          PIPE ROW('Plans for each test have been captured into '||USER||'.SQL_PLAN_STATISTICS_ALL or '||USER||'.PLAN_TABLE_ALL.'||LF);
          PIPE ROW('<table>'||LF);
        END IF;

        IF insert_title(my_count) THEN
          PIPE ROW(
          '<tr>'||LF||
          '<th>#</th>'||
          '<th>Plan<br>Hash Value</th>'||
          '<th>SQLT Plan<br>Hash Value<sup>1</sup></th>'||
          '<th>SQLT Plan<br>Hash Value2<sup>1</sup></th>'||
          '<th>Total<br>Tests</th>'||
          '<th>Plan<br>Cost</th>'||
          '<th>Tests</th>'||
          '<th>Max<br>Buffer<br>Gets</th>'||
          '<th>Min<br>Buffer<br>Gets</th>'||
          '<th>Max<br>CPU<br>(secs)</th>'||
          '<th>Min<br>CPU<br>(secs)</th>'||
          '<th>Max<br>Disk<br>Reads</th>'||
          '<th>Min<br>Disk<br>Reads</th>'||
          '<th>Max<br>ET<sup>2</sup><br>(secs)</th>'||
          '<th>Min<br>ET<sup>2</sup><br>(secs)</th>'||
          '<th>Max<br>Actual<br>Rows</th>'||
          '<th>Min<br>Actual<br>Rows</th>'||
          '<th>Max<br>Estim<br>Rows</th>'||
          '<th>Min<br>Estim<br>Rows</th>'||
          '<th>B<sup>3</sup></th>'||
          '<th>F<sup>4</sup></th>'||
          '</tr>'||LF);
        END IF;

        my_cost := NULL;
        my_tests := NULL;
        FOR j IN (SELECT ROUND(plan_cost) cost, COUNT(*) tests_count
                    FROM xplore_test
                   WHERE baseline_id = p_baseline_id
                     AND run_id = p_run_id
                     AND plan_hash_value = i.plan_hash_value
                     AND sqlt_plan_hash_value = i.sqlt_plan_hash_value
                     AND sqlt_plan_hash_value2 = i.sqlt_plan_hash_value2
                   GROUP BY
                         ROUND(plan_cost)
                   ORDER BY 1)
        LOOP
          my_cost := my_cost||j.cost||'<br>';
          my_tests := my_tests||j.tests_count||'<br>';
        END LOOP;
        my_cost := SUBSTR(my_cost, 1, LENGTH(my_cost) - 4);
        my_tests := SUBSTR(my_tests, 1, LENGTH(my_tests) - 4);

        my_card := NULL;
        my_card_tests := NULL;
        FOR j IN (SELECT cardinality card, COUNT(*) tests_count
                    FROM xplore_test
                   WHERE baseline_id = p_baseline_id
                     AND run_id = p_run_id
                     AND plan_hash_value = i.plan_hash_value
                     AND sqlt_plan_hash_value = i.sqlt_plan_hash_value
                     AND sqlt_plan_hash_value2 = i.sqlt_plan_hash_value2
                   GROUP BY
                         cardinality
                   ORDER BY 1)
        LOOP
          my_card := my_card||j.card||'<br>';
          my_card_tests := my_card_tests||j.tests_count||'<br>';
        END LOOP;
        my_card := SUBSTR(my_card, 1, LENGTH(my_card) - 4);
        my_card_tests := SUBSTR(my_card_tests, 1, LENGTH(my_card_tests) - 4);

        PIPE ROW(
        '<tr>'||LF||
        '<td class="title">'||my_count||'</td>'||
        '<td class="right">'||i.plan_hash_value||'</td>'||LF||
        '<td class="right">'||i.sqlt_plan_hash_value||'</td>'||LF||
        '<td class="right">'||i.sqlt_plan_hash_value2||'</td>'||LF||
        '<td class="right" title="Completed Tests"><a href="#phv'||i.plan_hash_value||'_'||i.sqlt_plan_hash_value||'_'||i.sqlt_plan_hash_value2||'t">'||i.tests||'</a></td>'||LF||
        '<td class="right">'||my_cost||'</td>'||
        '<td class="right">'||my_tests||'</td>'||
        '<td class="right">'||i.max_buffer_gets||'</td>'||
        '<td class="right">'||i.min_buffer_gets||'</td>'||
        '<td class="right">'||i.max_cpu_time||'</td>'||
        '<td class="right">'||i.min_cpu_time||'</td>'||
        '<td class="right">'||i.max_disk_reads||'</td>'||
        '<td class="right">'||i.min_disk_reads||'</td>'||
        '<td class="right">'||i.max_elapsed_time||'</td>'||
        '<td class="right">'||i.min_elapsed_time||'</td>'||
        '<td class="right">'||i.max_rows_processed||'</td>'||
        '<td class="right">'||i.min_rows_processed||'</td>'||
        '<td class="right">'||i.max_cardinality||'</td>'||
        '<td class="right">'||i.min_cardinality||'</td>'||
        '<td class="right">'||my_card||'</td>'||
        '<td class="right">'||my_card_tests||'</td>'||
        '<td>'||i.b||'</td>'||
        '<td>'||i.f||'</td>'||
        '</tr>'||LF);
      END LOOP /* i */;

      IF my_count > 0 THEN
        PIPE ROW('</table>'||LF||
        '<font class="tablenote">(1) SQLT PHV considers id, parent_id, operation, options, index_columns and object_name. SQLT PHV2 includes also access and filter predicates.</font><br>'||LF||
        '<font class="tablenote">(2) If tables are empty, then Elapsed Time is close to Parse Time.</font><br>'||LF||
        '<font class="tablenote">(3) B: Includes BASELINE.</font><br>'||LF||
        '<font class="tablenote">(4) F: Includes at least one "_fix_control".</font><br>'||LF);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_line('*** cannot display discovered plans: '||SQLERRM);
    END;

    /* -------------------------
     * Baseline
     * ------------------------- */
    BEGIN
      my_count := 0;
      FOR i IN (SELECT *
                  FROM baseline_parameter_cbo
                 WHERE baseline_id = p_baseline_id
                 ORDER BY
                       isdefault,
                       ismodified DESC NULLS LAST,
                       DECODE(name, '_fix_control', 2, 1),
                       name,
                       value)
      LOOP
        my_count := my_count + 1;
        IF my_count = 1 THEN
          PIPE ROW(LF||'<h2>Baseline</h2>'||LF);
          PIPE ROW('<table>'||LF);
        END IF;

        IF insert_title(my_count) THEN
          PIPE ROW(
          '<tr>'||LF||
          '<th>#</th>'||
          '<th>is<br>Default</th>'||
          '<th>is Modified</th>'||
          '<th>Name</th>'||
          '<th>Value</th>'||
          '<th>is Session<br>Modifiable</th>'||
          '<th>is System<br>Modifiable</th>'||
          '<th>Type</th>'||
          '</tr>'||LF);
        END IF;

        PIPE ROW(
        '<tr>'||LF||
        '<td class="title">'||my_count||'</td>'||
        '<td>'||i.isdefault||'</td>'||
        '<td>'||i.ismodified||'</td>'||
        '<td class="left">'||i.name||'</td>'||
        '<td class="left" title="'||NVL(i.display_value, i.value)||'">'||i.value||'</td>'||
        '<td>'||i.isses_modifiable||'</td>'||
        '<td>'||i.issys_modifiable||'</td>'||
        '<td class="right">'||i.type||'</td>'||
        '</tr>'||LF);
      END LOOP;
      IF my_count > 0 THEN
        PIPE ROW('</table>'||LF);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_line('*** cannot display baseline: '||SQLERRM);
    END;

    /* -------------------------
     * Completed Tests
     * ------------------------- */
    BEGIN
      FOR i IN (SELECT DISTINCT plan_hash_value, sqlt_plan_hash_value, sqlt_plan_hash_value2
                  FROM xplore_test
                 WHERE baseline_id = p_baseline_id
                   AND run_id = p_run_id
                   AND plan_hash_value IS NOT NULL
                 ORDER BY
                       plan_hash_value, sqlt_plan_hash_value, sqlt_plan_hash_value2)
      LOOP
        PIPE ROW(LF||'<br><a name="phv'||i.plan_hash_value||'_'||i.sqlt_plan_hash_value||'_'||i.sqlt_plan_hash_value2||'t"></a>'||LF);
        PIPE ROW('<h2>Completed Tests for Plan '||i.plan_hash_value||' '||i.sqlt_plan_hash_value||' '||i.sqlt_plan_hash_value2||'</h2>'||LF);
        PIPE ROW('<table>'||LF);

        my_count := 0;
        FOR j IN (SELECT LPAD(test_id, 5, '0') test_id,
                         ROUND(plan_cost) cost,
                         ROUND(buffer_gets) buffer_gets,
                         ROUND(cpu_time/1000000, 3) cpu_time,
                         ROUND(disk_reads) disk_reads,
                         ROUND(elapsed_time/1000000, 3) elapsed_time,
                         ROUND(rows_processed) rows_processed,
                         ROUND(cardinality) cardinality,
                         test,
                         baseline_value
                    FROM xplore_test
                   WHERE baseline_id = p_baseline_id
                     AND run_id = p_run_id
                     AND plan_hash_value = i.plan_hash_value
                     AND sqlt_plan_hash_value = i.sqlt_plan_hash_value
                     AND sqlt_plan_hash_value2 = i.sqlt_plan_hash_value2
                   ORDER BY
                         test_id)
        LOOP
          my_count := my_count + 1;

          IF insert_title(my_count) THEN
            PIPE ROW(
            '<tr>'||LF||
            '<th>#</th>'||
            '<th>Test<br>Id</th>'||
            '<th>Test</th>'||
            '<th>Baseline<br>Value</th>'||
            '<th>Plan<br>Cost</th>'||
            '<th>Buffer<br>Gets</th>'||
            '<th>CPU<br>(secs)</th>'||
            '<th>Disk<br>Reads</th>'||
            '<th>ET<br>(secs)</th>'||
            '<th>Actual<br>Rows</th>'||
            '<th>Estim<br>Rows</th>'||
            '</tr>'||LF);
          END IF;

          PIPE ROW(
          '<tr>'||LF||
          '<td class="title">'||my_count||'</td>'||
          '<td><a title="Plan" href="#test'||j.test_id||'p">'||j.test_id||'</a></td>'||LF||
          '<td class="left">'||j.test||'</td>'||
          '<td class="left">'||j.baseline_value||'</td>'||
          '<td class="right">'||j.cost||'</td>'||
          '<td class="right">'||j.buffer_gets||'</td>'||
          '<td class="right">'||j.cpu_time||'</td>'||
          '<td class="right">'||j.disk_reads||'</td>'||
          '<td class="right">'||j.elapsed_time||'</td>'||
          '<td class="right">'||j.rows_processed||'</td>'||
          '<td class="right">'||j.cardinality||'</td>'||
          '</tr>'||LF);
        END LOOP;
        PIPE ROW('</table>'||LF);
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        print_line('*** cannot display completed tests: '||SQLERRM);
    END;

    /* -------------------------
     * Plans
     * ------------------------- */
    DECLARE
      t_rec xplore_test%ROWTYPE;
    BEGIN
      my_count := 0;
      FOR i IN (SELECT DISTINCT test_id
                  FROM discovered_plan
                 WHERE baseline_id = p_baseline_id
                   AND run_id = p_run_id
                 ORDER BY
                       test_id)
      LOOP
        BEGIN
          SELECT *
            INTO t_rec
            FROM xplore_test
           WHERE baseline_id = p_baseline_id
             AND run_id = p_run_id
             AND test_id = i.test_id;
        EXCEPTION
          WHEN OTHERS THEN
            t_rec := NULL;
        END;

        my_count := my_count + 1;
        PIPE ROW(LF||'<a name="test'||LPAD(i.test_id, 5, '0')||'p"></a>'||LF);
        PIPE ROW('<h2>Plan for Test:'||LPAD(i.test_id, 5, '0')||' '||t_rec.test||'</h2>'||LF);
        PIPE ROW('<pre>');

        FOR j IN (SELECT plan_table_output
                    FROM discovered_plan
                   WHERE baseline_id = p_baseline_id
                     AND run_id = p_run_id
                     AND test_id = i.test_id
                   ORDER BY
                         line_id)
        LOOP
          PIPE ROW(j.plan_table_output);
        END LOOP;

        PIPE ROW('</pre>');
      END LOOP /* i */;
    EXCEPTION
      WHEN OTHERS THEN
        print_line('*** cannot display plan: '||SQLERRM);
    END;

    /* -------------------------
     * Footer and closure
     * ------------------------- */
    BEGIN
      PIPE ROW(LF||
      '<br><hr size="3"><font class="footer">'||NOTE_NUMBER||' XPLORE '||
      TO_CHAR(SYSDATE, LOAD_DATE_FORMAT)||'</font>'||LF||
      '</body></html>');
    EXCEPTION
      WHEN OTHERS THEN
        print_line('*** cannot print footer: '||SQLERRM);
    END;

    RETURN;
  END generate_xplore_report;

  /***********************************************************************************************/

END xplore;
/

SHOW ERRORS;
