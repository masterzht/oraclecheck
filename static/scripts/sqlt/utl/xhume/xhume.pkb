CREATE OR REPLACE PACKAGE BODY xhume AS
/* $Header: xhume/xhume.pkb 12.2.171004 October 4th, 2017 carlos.sierra abel.macias@oracle.com $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
   
  TOOL_VERSION         CONSTANT VARCHAR2(32)  := '12.2.171004';
  NOTE_NUMBER          CONSTANT VARCHAR2(32)  := '215187.1';
  TOOL_DEVELOPER       CONSTANT VARCHAR2(32)  := 'abel.macias';
  TOOL_DEVELOPER_EMAIL CONSTANT VARCHAR2(32)  := 'abel.macias@oracle.com';
  COPYRIGHT            CONSTANT VARCHAR2(128) := 'Copyright (c) 2000-2017, Oracle Corporation. All rights reserved.';
  HEADING_DATE_FORMAT  CONSTANT VARCHAR2(32)  := 'YYYY/MM/DD';
  LOAD_DATE_FORMAT     CONSTANT VARCHAR2(32)  := 'YYYY-MM-DD/HH24:MI:SS'; -- 2010-03-03/08:45:04

-- 171004 Extensive replacement of variables to varchar2(257)

  /***********************************************************************************************/

  PROCEDURE print_line (
    p_line VARCHAR2 ) IS
  BEGIN
    DBMS_OUTPUT.PUT_LINE(SUBSTR(p_line, 1, 255));
  END print_line;

  /***********************************************************************************************/

  PROCEDURE create_xhume_script
  IS
    l_test_id INTEGER := 0;
    l_unique_id VARCHAR2(32767);
    l_restore VARCHAR2(32767);
    l_systimestamp TIMESTAMP(6) WITH TIME ZONE; -- current at the time this api is called
    l_pred1 VARCHAR2(32767);
    l_pred2 VARCHAR2(32767);

    PROCEDURE print_test (
      p_xhume_time IN TIMESTAMP WITH TIME ZONE,
      p_table_name IN VARCHAR2 DEFAULT NULL )
    IS
    BEGIN
      l_test_id := l_test_id + 1;
      l_unique_id := 'xhume_[^^run_id.]_('||LPAD(l_test_id, 5, '0')||')';

      IF p_table_name IS NOT NULL THEN
        l_restore := 'DBMS_STATS.RESTORE_TABLE_STATS(ownname => '''||USER||''', tabname => '''||p_table_name||''', as_of_timestamp => TO_TIMESTAMP_TZ('''||TO_CHAR(p_xhume_time, 'YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM')||''', ''YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM''), force => TRUE, no_invalidate => FALSE);';
      ELSE
        l_restore := 'DBMS_STATS.RESTORE_SCHEMA_STATS(ownname => '''||USER||''', as_of_timestamp => TO_TIMESTAMP_TZ('''||TO_CHAR(p_xhume_time, 'YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM')||''', ''YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM''), force => TRUE, no_invalidate => FALSE);';
      END IF;

      print_line('--');
      print_line('DEF unique_id = "'||l_unique_id||'"');
      print_line('PRO ^^unique_id.');
      print_line('BEGIN');
      print_line(l_restore);
      print_line('UPDATE xhume_test SET restore_ok = ''Y'' WHERE run_id IS NULL AND test_id = '||l_test_id||';');
      print_line('EXCEPTION WHEN OTHERS THEN');
      print_line('DBMS_OUTPUT.PUT_LINE(SQLERRM);');
      print_line('UPDATE xhume_test SET restore_ok = ''N'' WHERE run_id IS NULL AND test_id = '||l_test_id||';');
      print_line('END;');
      print_line('/');
      print_line('@^^script_with_sql.');
      print_line('EXEC xhume.snapshot_plan(''^^unique_id.'');');

      INSERT INTO xhume_test (
        test_id,
        unique_id,
        xhume_time,
        xhume_table_name,
        xhume_command
      ) VALUES (
        l_test_id,
        l_unique_id,
        p_xhume_time,
        NVL(p_table_name, 'SCHEMA'),
        'EXEC '||l_restore
      );
    END print_test;

  BEGIN
    l_systimestamp := SYSTIMESTAMP - TO_DSINTERVAL('0 00:00:00.000001000'); -- current at the time this api is called

    print_line('SET DEF ON ECHO OFF TERM ON APPI OFF SERVEROUT ON SIZE 1000000 NUMF "" SQLP SQL>;');
    print_line('SET SERVEROUT ON SIZE UNL;');
    print_line('SET ESC ON SQLBL ON;');
    print_line('SPO xhume_script.log;');
    print_line('COL connected_user NEW_V connected_user FOR A30;');
    print_line('SELECT user connected_user FROM DUAL;');
    print_line('PRO');
    print_line('PRO Parameter 1:');
    print_line('PRO Name of SCRIPT file that contains SQL to be executed (required)');
    print_line('PRO Note: SCRIPT must contain string ^^unique_id within a comment');
    print_line('PRO');
    print_line('SET DEF ^ ECHO OFF;');
    print_line('DEF script_with_sql = ''^1'';');
    print_line('PRO');
    print_line('PRO Value passed to xhume_script.sql:');
    print_line('PRO ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');
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
    print_line('SET VER ON FEED ON HEA ON LIN 2000 PAGES 1000 TRIMS ON TI OFF TIMI OFF;');
    print_line('--');
    print_line('SET ECHO ON;');
    print_line('WHENEVER SQLERROR EXIT SQL.SQLCODE;');
    print_line('--');
    print_line('COL run_id NEW_V run_id FOR A4;');
    print_line('SELECT LPAD((NVL(MAX(run_id), 0) + 1), 4, ''0'') run_id FROM xhume_test;');
    print_line('--');
    print_line('ALTER SYSTEM FLUSH SHARED_POOL;');
    print_line('ALTER SESSION SET STATISTICS_LEVEL = ALL;');
    print_line('--');
    print_line('PRO SYSTIMESTAMP: '||l_systimestamp);
    print_line('--');
    print_line('EXEC DBMS_STATS.DELETE_SCHEMA_STATS(ownname => '''||USER||''', force => TRUE, no_invalidate => FALSE);');
    print_line('--');

    DELETE xhume_table;
    DELETE xhume_test;
    DELETE xhume_discovered_plan;
    DELETE xhume_sql_plan_statistics_all;

    -- list of objects
    INSERT INTO xhume_table (
      owner,
      table_name,
      created_st, -- fake object creation as per the oldest set of stats (trunc timestamp of oldest stats rec)
      created_tc, -- tc object creation
      obj# )
    SELECT owner,
           object_name,
           created,
           last_ddl_time,
           object_id
      FROM dba_objects
     WHERE owner = USER
       AND SUBSTR(owner, 1, 2) = 'TC'
       AND SUBSTR(owner, 3, 5) BETWEEN '00000' AND '99999'
       AND object_type IN ('TABLE', 'MATERIALIZED VIEW')
       AND created < last_ddl_time
       AND object_name <> 'CBO_STAT_TAB_4TC'
       AND object_name NOT LIKE 'XHUME%';

    FOR i IN (SELECT DISTINCT
                     (h.savtime - TO_DSINTERVAL('0 00:00:00.000001000')) xhume_time, -- reset time to 1 millionth of a second BEFORE timestamp on table stats
                     t.table_name
                FROM xhume_table t,
                     sys.wri$_optstat_tab_history h
               WHERE t.obj# = h.obj#
                 AND h.savtime < SYSTIMESTAMP -- ignore stats in the future (pending stats)
                 AND h.savtime > t.created_st -- stats have to be older than object (this object creation date was reset by sqlt$i.reset_object_creation_date)
                 AND h.savtime < t.created_tc -- stats time are before the tc object was created (see sqlt$i.reset_object_creation_date)
               ORDER BY
                     1, 2)
    LOOP
      IF l_test_id = 0 THEN
        print_test(i.xhume_time); -- schema
      ELSE
        print_test(i.xhume_time, i.table_name);
      END IF;
    END LOOP;

    -- restore stats to current after we have xhumated and tested all versions
    print_test(l_systimestamp); -- schema

    -- delete all the records we created in stats history because of the restores
    l_pred1 := 'WHERE obj# IN (SELECT DISTINCT object_id FROM dba_objects WHERE owner = USER AND SUBSTR(owner, 1, 2) = ''TC'' AND SUBSTR(owner, 3, 5) BETWEEN ''00000'' AND ''99999'' AND object_name <> ''CBO_STAT_TAB_4TC'' AND object_name NOT LIKE ''XHUME%'')';
    l_pred2 := 'AND savtime > TO_TIMESTAMP_TZ('''||TO_CHAR(l_systimestamp, 'YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM')||''', ''YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM'');';
    print_line('--');
    print_line('DELETE sys.wri$_optstat_histgrm_history');
    print_line(l_pred1);
    print_line(l_pred2);
    print_line('--');
    print_line('DELETE sys.wri$_optstat_histhead_history');
    print_line(l_pred1);
    print_line(l_pred2);
    print_line('--');
    print_line('DELETE sys.wri$_optstat_ind_history');
    print_line(l_pred1);
    print_line(l_pred2);
    print_line('--');
    print_line('DELETE sys.wri$_optstat_tab_history');
    print_line(l_pred1);
    print_line(l_pred2);
    print_line('--');
    print_line('COMMIT;');

    print_line('--');
    print_line('SET TERM OFF ECHO OFF FEED OFF FLU OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 SHOW OFF SQLC MIX TAB OFF TRIMS ON VER OFF TI OFF TIMI OFF ARRAY 100 SQLP SQL> BLO . RECSEP OFF APPI OFF SERVEROUT ON SIZE 1000000 FOR TRU;');
    print_line('SET SERVEROUT ON SIZE UNL FOR TRU;');
    print_line('SPO xhume_report_^^run_id..html;');
    print_line('SELECT column_value FROM TABLE(xhume.generate_xhume_report(^^run_id.));');
    print_line('SPO OFF;');
    print_line('--');
    print_line('WHENEVER SQLERROR CONTINUE;');
    print_line('SET TERM ON;');
    print_line('HOS zip -mT xhume_^^run_id. xhume_*_^^run_id..* xhume_script.*');
    print_line('UNDEFINE 1 unique_id run_id script_with_sql;');
    print_line('SET DEF ON;');
    print_line('PRO XHUME Completed.');
    print_line('QUIT;');

    COMMIT;
  END create_xhume_script;

  /***********************************************************************************************/

  PROCEDURE snapshot_plan (p_unique_id IN VARCHAR2)
  IS
    l_run_id NUMBER;
    l_test_id NUMBER;
    l_opt VARCHAR2(32767);
    l_expr VARCHAR2(32767);
    l_ora_hash NUMBER;
    l_list_of_columns VARCHAR2(32767);
    l_sql VARCHAR2(32767);
    test_rec xhume_test%ROWTYPE;
    l_access_predicates VARCHAR2(32767);
    l_filter_predicates VARCHAR2(32767);

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

      /*
      FOR i IN (SELECT x.table_owner,
                       x.table_name,
                       x.column_name,
                       x.descend,
                       t.hidden_column
                  FROM dba_ind_columns x,
                       dba_tab_cols t
                 WHERE x.index_owner = p_index_owner
                   AND x.index_name = p_index_name
                   AND x.table_owner = t.owner
                   AND x.table_name = t.table_name
                   AND x.column_name = t.column_name
                 ORDER BY
                       x.column_position)
      LOOP
        IF i.hidden_column = 'YES' THEN
          l_column_name := NULL;
        ELSE
          l_column_name := i.column_name;
        END IF;

        IF i.descend = 'DESC' THEN
          l_column_name := l_column_name||'(DESC)';
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
      */

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
    l_run_id      := TO_NUMBER(SUBSTR(p_unique_id, INSTR(p_unique_id, '[') + 1, INSTR(p_unique_id, ']') - INSTR(p_unique_id, '[') - 1));
    l_test_id     := TO_NUMBER(SUBSTR(p_unique_id, INSTR(p_unique_id, '(') + 1, INSTR(p_unique_id, ')') - INSTR(p_unique_id, '(') - 1));

    SELECT *
      INTO test_rec
      FROM xhume_test
     WHERE run_id IS NULL
       AND test_id = l_test_id;

    IF test_rec.restore_ok = 'N' THEN
      RETURN; -- it could not restore stats so no sense to capture plan
    END IF;

    test_rec.run_id := l_run_id;
    test_rec.unique_id := REPLACE(test_rec.unique_id, '^^run_id.', LPAD(test_rec.run_id, 4, '0'));

    SELECT COUNT(*)
      INTO test_rec.tables_with_stats
      FROM xhume_table x,
           dba_tables t
     WHERE x.owner = t.owner
       AND x.table_name = t.table_name
       AND t.last_analyzed IS NOT NULL;

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
       AND child_number = 0
       AND parsing_user_id = UID
       AND sql_text NOT LIKE '%FROM v$sql%';

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

    -- this algorithm has to be in sync with sqlt$t.sqlt_plan_hash_value
    BEGIN -- xhume.snapshot_plan.sqlt_plan_hash_value
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
                 WHERE sql_id = test_rec.sql_id
                   AND child_number = test_rec.child_number
                   AND plan_hash_value = test_rec.plan_hash_value
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

    INSERT INTO xhume_test VALUES test_rec;

    INSERT INTO xhume_discovered_plan (
      run_id,
      test_id,
      line_id,
      plan_table_output
    )
    SELECT
      l_run_id,
      l_test_id,
      xhume_line_id.NEXTVAL,
      plan_table_output
    FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(test_rec.sql_id, test_rec.child_number, 'ALLSTATS COST'));

    l_list_of_columns := get_list_of_columns('v_$sql_plan_statistics_all');
    l_sql := 'INSERT INTO xhume_sql_plan_statistics_all (run_id, test_id, sqlt_plan_hash_value, sqlt_plan_hash_value2'||
    l_list_of_columns||') SELECT :run_id, :test_id, :sqlt_plan_hash_value, :sqlt_plan_hash_value2'||
    l_list_of_columns||' FROM v$sql_plan_statistics_all '||
    'WHERE sql_id = :sql_id AND child_number = :child_number AND plan_hash_value = :plan_hash_value';

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN l_run_id, IN l_test_id, IN test_rec.sqlt_plan_hash_value, IN test_rec.sqlt_plan_hash_value2,
      IN test_rec.sql_id, IN test_rec.child_number, IN test_rec.plan_hash_value;
    EXCEPTION
      WHEN OTHERS THEN
        print_line('-- '||SQLERRM);
        print_line('-- '||l_sql);
        print_line('-- "'||l_run_id||'" "'||l_test_id||'" "'||test_rec.sqlt_plan_hash_value||'" "'||test_rec.sqlt_plan_hash_value2||'" "'||test_rec.sql_id||'" "'||test_rec.child_number||'" "'||test_rec.plan_hash_value||'".');
    END;

    COMMIT;
  END snapshot_plan;

  /***********************************************************************************************/

  FUNCTION generate_xhume_report (p_run_id IN NUMBER)
  RETURN varchar2_table PIPELINED
  IS
    LF CONSTANT VARCHAR2(32767) := CHR(10);

    my_count INTEGER;
    my_cost VARCHAR2(32767);
    my_tests VARCHAR2(32767);

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
      PIPE ROW('<!-- $Header: '||NOTE_NUMBER||' XHUME '||TOOL_VERSION||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $ -->');
      PIPE ROW('<!-- '||COPYRIGHT||' -->');
      PIPE ROW('<!-- Author: '||TOOL_DEVELOPER_EMAIL||' -->');
      PIPE ROW('<head><title>XHUME run_id:'||p_run_id||'</title>');
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
      PIPE ROW('td.center {text-align:center}');
      PIPE ROW('td.title {font-weight:bold;text-align:right;background-color:#cccc99;color:#336699}');
      PIPE ROW('font.tablenote {font-size:8pt;font-style:italic;color:#336699}');
      PIPE ROW('font.footer {font-size:8pt; color:#999999;');
      PIPE ROW('</style>');
      PIPE ROW('</head><body><h1>XHUME Report for runid:'||p_run_id||'</h1>');
    EXCEPTION
      WHEN OTHERS THEN
        PIPE ROW('*** cannot print header: '||SQLERRM);
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
                       ROUND(MIN(q.cardinality)) min_cardinality,
                       ROUND(MAX(q.tables_with_stats)) max_tables_with_stats,
                       ROUND(MIN(q.tables_with_stats)) min_tables_with_stats
                  FROM xhume_test q
                 WHERE q.run_id = p_run_id
                   AND q.plan_hash_value IS NOT NULL
                   AND q.restore_ok = 'Y'
                 GROUP BY
                       q.plan_hash_value
                 ORDER BY
                       q.plan_hash_value)
      LOOP
        my_count := my_count + 1;
        IF my_count = 1 THEN
          PIPE ROW(LF||'<h2>Plans Summary</h2>'||LF);
          PIPE ROW('Plans for each test have been captured into '||USER||'.xhume_sql_plan_statistics_all.'||LF);
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
          '<th>Max<br>Tables<br>with<br>Stats</th>'||
          '<th>Min<br>Tables<br>with<br>Stats</th>'||
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
        '<td class="right">'||i.max_tables_with_stats||'</td>'||
        '<td class="right">'||i.min_tables_with_stats||'</td>'||
        '</tr>'||LF);
      END LOOP /* i */;

      IF my_count > 0 THEN
        PIPE ROW('</table>'||LF||
        '<font class="tablenote">(1) If tables are empty, then Elapsed Time is close to Parse Time.</font><br>'||LF);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        PIPE ROW('*** cannot display plans summary: '||SQLERRM);
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
                       ROUND(MAX(q.tables_with_stats)) max_tables_with_stats,
                       ROUND(MIN(q.tables_with_stats)) min_tables_with_stats
                  FROM xhume_test q
                 WHERE q.run_id = p_run_id
                   AND q.plan_hash_value IS NOT NULL
                   AND q.restore_ok = 'Y'
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
          PIPE ROW('Plans for each test have been captured into '||USER||'.xhume_sql_plan_statistics_all.'||LF);
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
          '<th>Max<br>Tables<br>with<br>Stats</th>'||
          '<th>Min<br>Tables<br>with<br>Stats</th>'||
          '</tr>'||LF);
        END IF;

        my_cost := NULL;
        my_tests := NULL;
        FOR j IN (SELECT ROUND(plan_cost) cost, COUNT(*) tests_count
                    FROM xhume_test
                   WHERE run_id = p_run_id
                     AND restore_ok = 'Y'
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
        '<td class="right">'||i.max_tables_with_stats||'</td>'||
        '<td class="right">'||i.min_tables_with_stats||'</td>'||
        '</tr>'||LF);
      END LOOP /* i */;

      IF my_count > 0 THEN
        PIPE ROW('</table>'||LF||
        '<font class="tablenote">(1) SQLT PHV considers id, parent_id, operation, options, index_columns and object_name. SQLT PHV2 includes also access and filter predicates.</font><br>'||LF||
        '<font class="tablenote">(2) If tables are empty, then Elapsed Time is close to Parse Time.</font><br>'||LF);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        PIPE ROW('*** cannot display discovered plans: '||SQLERRM);
    END;

    /* -------------------------
     * Chronological list of Tests
     * ------------------------- */
    DECLARE
      l_plan_hash_value NUMBER;
      l_sqlt_plan_hash_value NUMBER;
      l_sqlt_plan_hash_value2 NUMBER;
      l_secs_since_prior NUMBER;
      l_flipped VARCHAR2(10);
      l_flips_count NUMBER := 0;
      l_date DATE;
      l_prior_date DATE;
    BEGIN
      my_count := 0;
      FOR i IN (SELECT *
                  FROM xhume_test
                 WHERE run_id = p_run_id
                   AND plan_hash_value IS NOT NULL
                   AND restore_ok = 'Y'
                 ORDER BY
                       xhume_time)
      LOOP
        my_count := my_count + 1;
        IF my_count = 1 THEN
          PIPE ROW('<h2>Chronological list of Tests</h2>'||LF);
          PIPE ROW('<table>'||LF);
          l_plan_hash_value := i.plan_hash_value;
          l_sqlt_plan_hash_value := i.sqlt_plan_hash_value;
          l_sqlt_plan_hash_value2 := i.sqlt_plan_hash_value2;
          l_prior_date := NULL;
        END IF;

        IF i.plan_hash_value <> l_plan_hash_value OR
           i.sqlt_plan_hash_value <> l_sqlt_plan_hash_value OR
           i.sqlt_plan_hash_value2 <> l_sqlt_plan_hash_value2
        THEN
          l_flips_count := l_flips_count + 1;
          l_flipped := 'YES';
        ELSE
          l_flipped := NULL;
        END IF;

        l_date := i.xhume_time;
        l_secs_since_prior := ROUND((l_date - l_prior_date)*24*60*60);

        IF insert_title(my_count) THEN
          PIPE ROW(
          '<tr>'||LF||
          '<th>#</th>'||
          '<th>Test<br>Id</th>'||
          '<th>Stats Exhumation Time</th>'||
          '<th>Table Name</th>'||
          '<th>Secs<br>since<br>Prior</th>'||
          '<th>Plan<br>Hash Value</th>'||
          '<th>SQLT Plan<br>Hash Value<sup>1</sup></th>'||
          '<th>SQLT Plan<br>Hash Value2<sup>1</sup></th>'||
          '<th>Plan<br>Flips<sup>2</sup></th>'||
          '<th>Plan<br>Cost</th>'||
          '<th>Buffer<br>Gets</th>'||
          '<th>CPU<br>(secs)</th>'||
          '<th>Disk<br>Reads</th>'||
          '<th>ET<sup>3</sup><br>(secs)</th>'||
          '<th>Actual<br>Rows</th>'||
          '<th>Estim<br>Rows</th>'||
          '<th>Tables<br>with<br>Stats</th>'||
          '</tr>'||LF);
        END IF;

        PIPE ROW(
        '<tr>'||LF||
        '<td class="title">'||my_count||'</td>'||
        '<td><a title="Execution Plan" href="#test'||LPAD(i.test_id, 5, '0')||'p">'||LPAD(i.test_id, 5, '0')||'</a></td>'||LF||
        '<td class="left">'||TO_CHAR(i.xhume_time, 'YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM')||'</td>'||
        '<td class="left">'||i.xhume_table_name||'</td>'||
        '<td class="right">'||l_secs_since_prior||'</td>'||LF||
        '<td class="right">'||i.plan_hash_value||'</td>'||LF||
        '<td class="right">'||i.sqlt_plan_hash_value||'</td>'||LF||
        '<td class="right">'||i.sqlt_plan_hash_value2||'</td>'||LF||
        '<td class="center">'||l_flipped||'</td>'||
        '<td class="right">'||i.plan_cost||'</td>'||
        '<td class="right">'||i.buffer_gets||'</td>'||
        '<td class="right">'||ROUND(i.cpu_time/1000000, 3)||'</td>'||
        '<td class="right">'||i.disk_reads||'</td>'||
        '<td class="right">'||ROUND(i.elapsed_time/1000000, 3)||'</td>'||
        '<td class="right">'||i.rows_processed||'</td>'||
        '<td class="right">'||i.cardinality||'</td>'||
        '<td class="right">'||i.tables_with_stats||'</td>'||
        '</tr>'||LF);

        l_plan_hash_value := i.plan_hash_value;
        l_sqlt_plan_hash_value := i.sqlt_plan_hash_value;
        l_sqlt_plan_hash_value2 := i.sqlt_plan_hash_value2;
        l_prior_date := i.xhume_time;
      END LOOP;

      IF my_count > 0 THEN
        PIPE ROW('</table>'||LF||
        '<font class="tablenote">(1) SQLT PHV considers id, parent_id, operation, options, index_columns and object_name. SQLT PHV2 includes also access and filter predicates.</font><br>'||LF||
        '<font class="tablenote">(2) Plan flipped '||l_flips_count||' times.</font><br>'||LF||
        '<font class="tablenote">(3) If tables are empty, then Elapsed Time is close to Parse Time.</font><br>'||LF||
        '<font class="tablenote">To produce a report with the differences in schema statistics between two tests use sqltdiffstats.sql if on 11g+, else SQLT COMPARE</font><br>'||LF);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        PIPE ROW('*** cannot display completed tests: '||SQLERRM);
    END;

    /* -------------------------
     * Completed Tests
     * ------------------------- */
    BEGIN
      FOR i IN (SELECT DISTINCT plan_hash_value, sqlt_plan_hash_value, sqlt_plan_hash_value2
                  FROM xhume_test
                 WHERE run_id = p_run_id
                   AND plan_hash_value IS NOT NULL
                   AND restore_ok = 'Y'
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
                         tables_with_stats,
                         xhume_time,
                         xhume_table_name,
                         xhume_command
                    FROM xhume_test
                   WHERE run_id = p_run_id
                     AND restore_ok = 'Y'
                     AND plan_hash_value = i.plan_hash_value
                     AND sqlt_plan_hash_value = i.sqlt_plan_hash_value
                     AND sqlt_plan_hash_value2 = i.sqlt_plan_hash_value2
                   ORDER BY
                         xhume_time)
        LOOP
          my_count := my_count + 1;

          IF insert_title(my_count) THEN
            PIPE ROW(
            '<tr>'||LF||
            '<th>#</th>'||
            '<th>Test<br>Id</th>'||
            '<th>Stats Exhumation Time</th>'||
            '<th>Table Name</th>'||
            '<th>Plan<br>Cost</th>'||
            '<th>Buffer<br>Gets</th>'||
            '<th>CPU<br>(secs)</th>'||
            '<th>Disk<br>Reads</th>'||
            '<th>ET<br>(secs)</th>'||
            '<th>Actual<br>Rows</th>'||
            '<th>Estim<br>Rows</th>'||
            '<th>Tables<br>with<br>Stats</th>'||
            '</tr>'||LF);
          END IF;

          PIPE ROW(
          '<tr>'||LF||
          '<td class="title">'||my_count||'</td>'||
          '<td><a title="Execution Plan" href="#test'||j.test_id||'p">'||j.test_id||'</a></td>'||LF||
          '<td class="left">'||TO_CHAR(j.xhume_time, 'YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM')||'</td>'||
          '<td class="left">'||j.xhume_table_name||'</td>'||
          '<td class="right">'||j.cost||'</td>'||
          '<td class="right">'||j.buffer_gets||'</td>'||
          '<td class="right">'||j.cpu_time||'</td>'||
          '<td class="right">'||j.disk_reads||'</td>'||
          '<td class="right">'||j.elapsed_time||'</td>'||
          '<td class="right">'||j.rows_processed||'</td>'||
          '<td class="right">'||j.cardinality||'</td>'||
          '<td class="right">'||j.tables_with_stats||'</td>'||
          '</tr>'||LF);
        END LOOP;
        PIPE ROW('</table>'||LF||
        '<font class="tablenote">To produce a report with the differences in schema statistics between two tests use sqltdiffstats.sql if on 11g+, else SQLT COMPARE</font><br>'||LF);
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        PIPE ROW('*** cannot display completed tests: '||SQLERRM);
    END;

    /* -------------------------
     * Execution Plans
     * ------------------------- */
    DECLARE
      t_rec xhume_test%ROWTYPE;
    BEGIN
      my_count := 0;
      FOR i IN (SELECT DISTINCT test_id
                  FROM xhume_discovered_plan
                 WHERE run_id = p_run_id
                 ORDER BY
                       test_id DESC)
      LOOP
        BEGIN
          SELECT *
            INTO t_rec
            FROM xhume_test
           WHERE run_id = p_run_id
             AND test_id = i.test_id
             AND restore_ok = 'Y';

        EXCEPTION
          WHEN OTHERS THEN
            t_rec := NULL;
        END;

        my_count := my_count + 1;
        PIPE ROW(LF||'<a name="test'||LPAD(i.test_id, 5, '0')||'p"></a>'||LF);
        PIPE ROW('<h2>Execution Plan for  Test:'||LPAD(i.test_id, 5, '0')||'  Time:'||TO_CHAR(t_rec.xhume_time, 'YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM')||'</h2>'||LF);
        PIPE ROW('<pre>');

        FOR j IN (SELECT plan_table_output
                    FROM xhume_discovered_plan
                   WHERE run_id = p_run_id
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
        PIPE ROW('*** cannot display execution plan: '||SQLERRM);
    END;

    /* -------------------------
     * Footer and closure
     * ------------------------- */
    BEGIN
      PIPE ROW(LF||
      '<br><hr size="3"><font class="footer">'||NOTE_NUMBER||' XHUME '||
      TO_CHAR(SYSDATE, LOAD_DATE_FORMAT)||'</font>'||LF||
      '</body></html>');
    EXCEPTION
      WHEN OTHERS THEN
        PIPE ROW('*** cannot print footer: '||SQLERRM);
    END;

    RETURN;
  END generate_xhume_report;

  /***********************************************************************************************/

END xhume;
/

SHOW ERRORS;
