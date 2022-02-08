CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..trca$x AS
/* $Header: 224270.1 tacpkgx.pkb 11.4.5.0 2012/11/21 carlos.sierra $ */

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  LF                   CONSTANT VARCHAR2(32767) := CHR(10); -- line feed
  LONG_DATE_FORMAT     CONSTANT VARCHAR2(32767) := 'YYYY-MON-DD HH24:MI:SS';
  MAX_LINE_SZ          CONSTANT INTEGER         := 132;
  SEPARATOR            CONSTANT VARCHAR2(32767) := LPAD('*', MAX_LINE_SZ, '*');
  DASHES               CONSTANT VARCHAR2(32767) := LPAD('-', MAX_LINE_SZ, '-');
  GAP                  CONSTANT INTEGER := 2;

  /*************************************************************************************/

  /* -------------------------
   *
   * private static
   *
   * ------------------------- */
  s_file_rec trca$_file%ROWTYPE;

  /*************************************************************************************/

  /* -------------------------
   *
   * private print_log
   *
   * ------------------------- */
  PROCEDURE print_log (
    p_line IN VARCHAR2 )
  IS
  BEGIN /* print_log */
    trca$g.print_log(p_buffer => p_line, p_package => 'X');
  END print_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * private printf
   *
   * ------------------------- */
  PROCEDURE printf (
    p_buffer IN VARCHAR2 )
  IS
  BEGIN /* printf */
    IF p_buffer IS NOT NULL THEN
      SYS.DBMS_LOB.WRITEAPPEND (
        lob_loc => s_file_rec.file_text,
        amount  => LENGTH(p_buffer) + 1,
        buffer  => LF||p_buffer );
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      SYS.DBMS_OUTPUT.PUT_LINE('***');
      SYS.DBMS_OUTPUT.PUT_LINE('*** SYS.DBMS_LOB.WRITEAPPEND');
      SYS.DBMS_OUTPUT.PUT_LINE('*** Module: trca$x.printf');
      SYS.DBMS_OUTPUT.PUT_LINE('*** Buffer: "'||SUBSTR(p_buffer, 1, 200)||'"');
      SYS.DBMS_OUTPUT.PUT_LINE('*** '||SQLERRM);
      SYS.DBMS_OUTPUT.PUT_LINE('***');
      RAISE;
  END printf;

  /*************************************************************************************/

  /* -------------------------
   *
   * private title_and_value
   *
   * ------------------------- */
  FUNCTION title_and_value (
    p_cols    IN INTEGER,
    p_value1  IN VARCHAR2 DEFAULT NULL,
    p_class1  IN VARCHAR2 DEFAULT NULL,
    p_lengt1  IN INTEGER  DEFAULT NULL,
    p_value2  IN VARCHAR2 DEFAULT NULL,
    p_class2  IN VARCHAR2 DEFAULT NULL,
    p_lengt2  IN INTEGER  DEFAULT NULL,
    p_value3  IN VARCHAR2 DEFAULT NULL,
    p_class3  IN VARCHAR2 DEFAULT NULL,
    p_lengt3  IN INTEGER  DEFAULT NULL,
    p_value4  IN VARCHAR2 DEFAULT NULL,
    p_class4  IN VARCHAR2 DEFAULT NULL,
    p_lengt4  IN INTEGER  DEFAULT NULL,
    p_value5  IN VARCHAR2 DEFAULT NULL,
    p_class5  IN VARCHAR2 DEFAULT NULL,
    p_lengt5  IN INTEGER  DEFAULT NULL,
    p_value6  IN VARCHAR2 DEFAULT NULL,
    p_class6  IN VARCHAR2 DEFAULT NULL,
    p_lengt6  IN INTEGER  DEFAULT NULL,
    p_value7  IN VARCHAR2 DEFAULT NULL,
    p_class7  IN VARCHAR2 DEFAULT NULL,
    p_lengt7  IN INTEGER  DEFAULT NULL,
    p_value8  IN VARCHAR2 DEFAULT NULL,
    p_class8  IN VARCHAR2 DEFAULT NULL,
    p_lengt8  IN INTEGER  DEFAULT NULL,
    p_value9  IN VARCHAR2 DEFAULT NULL,
    p_class9  IN VARCHAR2 DEFAULT NULL,
    p_lengt9  IN INTEGER  DEFAULT NULL,
    p_value10 IN VARCHAR2 DEFAULT NULL,
    p_class10 IN VARCHAR2 DEFAULT NULL,
    p_lengt10 IN INTEGER  DEFAULT NULL,
    p_value11 IN VARCHAR2 DEFAULT NULL,
    p_class11 IN VARCHAR2 DEFAULT NULL,
    p_lengt11 IN INTEGER  DEFAULT NULL,
    p_value12 IN VARCHAR2 DEFAULT NULL,
    p_class12 IN VARCHAR2 DEFAULT NULL,
    p_lengt12 IN INTEGER  DEFAULT NULL,
    p_value13 IN VARCHAR2 DEFAULT NULL,
    p_class13 IN VARCHAR2 DEFAULT NULL,
    p_lengt13 IN INTEGER  DEFAULT NULL,
    p_value14 IN VARCHAR2 DEFAULT NULL,
    p_class14 IN VARCHAR2 DEFAULT NULL,
    p_lengt14 IN INTEGER  DEFAULT NULL,
    p_value15 IN VARCHAR2 DEFAULT NULL,
    p_class15 IN VARCHAR2 DEFAULT NULL,
    p_lengt15 IN INTEGER  DEFAULT NULL,
    p_value16 IN VARCHAR2 DEFAULT NULL,
    p_class16 IN VARCHAR2 DEFAULT NULL,
    p_lengt16 IN INTEGER  DEFAULT NULL )
  RETURN VARCHAR2
  IS
    l_return VARCHAR2(32767) := NULL;

    FUNCTION append_one (
      p_value IN VARCHAR2,
      p_class IN VARCHAR2,
      p_lengt IN INTEGER )
    RETURN VARCHAR2
    IS
      l_padlen INTEGER := NVL(GREATEST(p_lengt - LENGTH(p_value), 0), p_lengt);
    BEGIN /* append_one */
      IF p_lengt <= GAP THEN
        RETURN NULL;
      ELSIF l_padlen = 0 THEN
        RETURN p_value;
      ELSIF p_class = 'L' THEN
        RETURN p_value||LPAD(' ', l_padlen);
      ELSIF p_class = 'R' THEN
        RETURN LPAD(' ', l_padlen)||p_value;
      ELSE -- 'C'
        RETURN ' '||LPAD(' ', CEIL((l_padlen - 1)/2))||p_value||LPAD(' ', FLOOR((l_padlen - 1)/2));
      END IF;
    END append_one;

  BEGIN /* title_and_value */
    IF p_cols >= 1 THEN
      l_return := l_return||append_one(p_value1, p_class1, p_lengt1);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 2 THEN
      l_return := l_return||append_one(p_value2, p_class2, p_lengt2);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 3 THEN
      l_return := l_return||append_one(p_value3, p_class3, p_lengt3);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 4 THEN
      l_return := l_return||append_one(p_value4, p_class4, p_lengt4);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 5 THEN
      l_return := l_return||append_one(p_value5, p_class5, p_lengt5);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 6 THEN
      l_return := l_return||append_one(p_value6, p_class6, p_lengt6);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 7 THEN
      l_return := l_return||append_one(p_value7, p_class7, p_lengt7);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 8 THEN
      l_return := l_return||append_one(p_value8, p_class8, p_lengt8);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 9 THEN
      l_return := l_return||append_one(p_value9, p_class9, p_lengt9);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 10 THEN
      l_return := l_return||append_one(p_value10, p_class10, p_lengt10);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 11 THEN
      l_return := l_return||append_one(p_value11, p_class11, p_lengt11);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 12 THEN
      l_return := l_return||append_one(p_value12, p_class12, p_lengt12);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 13 THEN
      l_return := l_return||append_one(p_value13, p_class13, p_lengt13);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 14 THEN
      l_return := l_return||append_one(p_value14, p_class14, p_lengt14);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 15 THEN
      l_return := l_return||append_one(p_value15, p_class15, p_lengt15);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    IF p_cols >= 16 THEN
      l_return := l_return||append_one(p_value16, p_class16, p_lengt16);
    ELSE
      RETURN TRIM(TRAILING ' ' FROM l_return);
    END IF;

    RETURN TRIM(TRAILING ' ' FROM l_return);
  END title_and_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * private gen_html_exec
   *
   * ------------------------- */
  PROCEDURE gen_html_exec (
    p_tool_execution_id IN INTEGER,
    p_group_id          IN INTEGER,
    p_exec_id           IN INTEGER )
  IS
    grp_rec trca$_group%ROWTYPE;
    stm_rec trca$_statement%ROWTYPE;
    sql_vf  trca$_sql_vf%ROWTYPE;
    exec_v  trca$_exec_v%ROWTYPE;
    exec_vf trca$_exec_vf%ROWTYPE;

  /*************************************************************************************/

  BEGIN /* gen_html_exec */
    /* -------------------------
     * Initialization
     * ------------------------- */
    SELECT * INTO exec_v  FROM trca$_exec_v    WHERE exec_id = p_exec_id AND group_id = p_group_id AND tool_execution_id = p_tool_execution_id;
    SELECT * INTO exec_vf FROM trca$_exec_vf   WHERE exec_id = p_exec_id AND group_id = p_group_id AND tool_execution_id = p_tool_execution_id;
    SELECT * INTO grp_rec FROM trca$_group     WHERE id = p_group_id AND tool_execution_id = p_tool_execution_id;
    SELECT * INTO sql_vf  FROM trca$_sql_vf    WHERE group_id = p_group_id AND tool_execution_id = p_tool_execution_id;
    SELECT * INTO stm_rec FROM trca$_statement WHERE id = grp_rec.statement_id;

    /* -------------------------
     * Exec Title
     * ------------------------- */
    DECLARE
      l_text VARCHAR2(32767);
    BEGIN
      printf(LF||LF||exec_vf.rank||' '||stm_rec.hv||' '||stm_rec.sqlid||' '||exec_v.plh||LF);

      l_text := 'Rank:'||grp_rec.rank||'.'||exec_vf.rank||'('||exec_vf.grp_contribution||')('||exec_vf.trc_contribution||') ';
      l_text := l_text||'Self:'||exec_vf.response_time_self||'s ';
      l_text := l_text||'Recursive:'||exec_vf.response_time_progeny||'s ';
      printf(l_text);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display exec title for '||p_group_id||': '||SQLERRM);
    END;

    /* -------------------------
     * Exec Self - Time, Totals, Waits and Binds
     * ------------------------- */
    IF exec_v.response_time_self > 0 THEN
      -- time
      DECLARE
        cols INTEGER := 7;
        c1   INTEGER := 8;
        c2   INTEGER := 15;
        c3   INTEGER := 9;
        c4   INTEGER := 10;
        c5   INTEGER := 11;
        c6   INTEGER := 17;
        c7   INTEGER := 11;
      BEGIN
        SELECT GREATEST(NVL(MAX(LENGTH(accounted_response)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(elapsed)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(cpu)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(elapsed_unaccounted_for)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c7)
          INTO c2, c3, c4, c5, c6, c7
          FROM trca$_sql_exec_time_vf
         WHERE exec_id           = p_exec_id
           AND group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id;

        printf(LF||
        title_and_value(cols,
        NULL,             'R', c1,
        'Response Time',  'R', c2,
        'Elapsed',        'R', c3,
        NULL,             'R', c4,
        'Non-Idle',       'R', c5,
        'Elapsed Time',   'R', c6,
        'Idle',           'R', c7 )||LF||
        title_and_value(cols,
        'Call ',           'R', c1,
        'Accounted-for',   'R', c2,
        'Time',            'R', c3,
        'CPU Time',        'R', c4,
        'Wait Time',       'R', c5,
        'Unaccounted-for', 'R', c6,
        'Wait Time',       'R', c7 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),     'R', c1,
        SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7 - 1), 'R', c7 ));

        FOR i IN (SELECT *
                    FROM trca$_sql_exec_time_vf
                   WHERE exec_id           = p_exec_id
                     AND group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          IF i.call = trca$g.CALL_TOTAL THEN
            printf(title_and_value(cols,
            SUBSTR(DASHES, 1, c1),     'R', c1,
            SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
            SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
            SUBSTR(DASHES, 1, c7 - 1), 'R', c7 ));
          END IF;

          printf(title_and_value(cols,
          i.call_type||':',           'R', c1,
          i.accounted_response,       'R', c2,
          i.elapsed,                  'R', c3,
          i.cpu,                      'R', c4,
          i.non_idle_wait,            'R', c5,
          i.elapsed_unaccounted_for,  'R', c6,
          i.idle_wait,                'R', c7 ));
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display exec self time: '||SQLERRM);
      END;

      -- totals
      DECLARE
        cols INTEGER := 9;
        c1   INTEGER := 8;
        c2   INTEGER := 7;
        c3   INTEGER := 13;
        c4   INTEGER := 15;
        c5   INTEGER := 12;
        c6   INTEGER := 13;
        c7   INTEGER := 9;
        c8   INTEGER := 10;
        c9   INTEGER := 8;
      BEGIN
        SELECT GREATEST(NVL(MAX(LENGTH(call_count)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(p_disk_os)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(cr_query_consistent)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(cu_current)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(r_rows)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(mis_library_cache_misses)), 0) + GAP, c7),
               GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c8),
               GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c9)
          INTO c2, c3, c4, c5, c6, c7, c8, c9
          FROM trca$_sql_exec_total_v
         WHERE exec_id           = p_exec_id
           AND group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id;

        printf(LF||
        title_and_value(cols,
        NULL,            'R', c1,
        NULL,            'R', c2,
        'OS',            'R', c3,
        'BG Consistent', 'R', c4,
        'BG Current',    'R', c5,
        'Rows',          'R', c6,
        'Library',       'R', c7,
        'Times',         'R', c8,
        'Times',         'R', c9 )||LF||
        title_and_value(cols,
        NULL,          'R', c1,
        'Call',        'R', c2,
        'Buffer Gets', 'R', c3,
        'Read Mode',   'R', c4,
        'Mode',        'R', c5,
        'Processed',   'R', c6,
        'Cache',       'R', c7,
        'Waited',      'R', c8,
        'Waited',      'R', c9 )||LF||
        title_and_value(cols,
        'Call ',       'R', c1,
        'Count',       'R', c2,
        '(disk)',      'R', c3,
        '(query)',     'R', c4,
        '(current)',   'R', c5,
        'or Returned', 'R', c6,
        'Misses',      'R', c7,
        'Non-Idle',    'R', c8,
        'Idle',        'R', c9 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),     'R', c1,
        SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
        SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
        SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));

        FOR i IN (SELECT *
                    FROM trca$_sql_exec_total_v
                   WHERE exec_id           = p_exec_id
                     AND group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          IF i.call = trca$g.CALL_TOTAL THEN
            printf(title_and_value(cols,
            SUBSTR(DASHES, 1, c1),     'R', c1,
            SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
            SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
            SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
            SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
            SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));
          END IF;

          printf(title_and_value(cols,
          i.call_type||':',           'R', c1,
          i.call_count,               'R', c2,
          i.p_disk_os,                'R', c3,
          i.cr_query_consistent,      'R', c4,
          i.cu_current,               'R', c5,
          i.r_rows,                   'R', c6,
          i.mis_library_cache_misses, 'R', c7,
          i.wait_count_non_idle,      'R', c8,
          i.wait_count_idle,          'R', c9 ));
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display exec self totals: '||SQLERRM);
      END;

      -- waits
      IF trca$g.g_include_waits = 'Y' THEN
        DECLARE
          l_count INTEGER;
          cols INTEGER := 10;
          c1   INTEGER := 7;
          c2   INTEGER := 7;
          c3   INTEGER := 11;
          c4   INTEGER := 10;
          c5   INTEGER := 11;
          c6   INTEGER := 8;
          c7   INTEGER := 11;
          c8   INTEGER := 11;
          c9   INTEGER := 8;
          c10  INTEGER := 9;
        BEGIN
          SELECT COUNT(*),
                 GREATEST(NVL(MAX(LENGTH(event_name)), 0) + GAP, c1),
                 GREATEST(NVL(MAX(LENGTH(wait_class)), 0) + GAP, c2),
                 GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c3),
                 GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c4),
                 GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c5),
                 GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c6),
                 GREATEST(NVL(MAX(LENGTH(avg_wait)), 0) + GAP, c7),
                 GREATEST(NVL(MAX(LENGTH(max_wait)), 0) + GAP, c8),
                 GREATEST(NVL(MAX(LENGTH(blocks)), 0) + GAP, c9),
                 GREATEST(NVL(MAX(LENGTH(avg_blocks)), 0) + GAP, c10)
            INTO l_count, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10
            FROM trca$_sql_exec_wait_v
           WHERE exec_id           = p_exec_id
             AND group_id          = p_group_id
             AND tool_execution_id = p_tool_execution_id
             AND ROWNUM            = 1;

          IF l_count > 0 THEN
            printf(LF||
            title_and_value(cols,
            NULL,    'R', c1,
            NULL,    'R', c2,
            NULL,    'R', c3,
            'Times', 'R', c4,
            NULL,    'R', c5,
            'Times', 'R', c6,
            NULL,    'R', c7,
            NULL,    'R', c8,
            NULL,    'R', c9,
            NULL,    'R', c10 )||LF||
            title_and_value(cols,
            'Event ',   'R', c1,
            ' Wait',    'L', c2,
            'Non-Idle', 'R', c3,
            'Waited',   'R', c4,
            'Idle',     'R', c5,
            'Waited',   'R', c6,
            'Average',  'R', c7,
            'Max',      'R', c8,
            NULL,       'R', c9,
            'Average',  'R', c10 )||LF||
            title_and_value(cols,
            'Name ',       'R', c1,
            ' Class',      'L', c2,
            'Wait Time',   'R', c3,
            'Non-Idle',    'R', c4,
            'Wait Time',   'R', c5,
            'Idle',        'R', c6,
            'Wait Time',   'R', c7,
            'Wait Time',   'R', c8,
            'Blocks',      'R', c9,
            'Blocks',      'R', c10)||LF||
            title_and_value(cols,
            SUBSTR(DASHES, 1, c1),      'R', c1,
            SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
            SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
            SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
            SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
            SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
            SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));

            FOR i IN (SELECT *
                        FROM trca$_sql_exec_wait_vf
                       WHERE exec_id           = p_exec_id
                         AND group_id          = p_group_id
                         AND tool_execution_id = p_tool_execution_id
                       ORDER BY
                             row_type,
                             wait DESC)
            LOOP
              IF i.row_type = 'T' THEN
                printf(title_and_value(cols,
                SUBSTR(DASHES, 1, c1),      'R', c1,
                SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
                SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
                SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
                SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
                SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
                SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
                SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
                SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
                SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));
              END IF;

              printf(title_and_value(cols,
              i.event_name||':',     'R', c1,
              ' '||i.wait_class,     'L', c2,
              i.non_idle_wait,       'R', c3,
              i.wait_count_non_idle, 'R', c4,
              i.idle_wait,           'R', c5,
              i.wait_count_idle,     'R', c6,
              i.avg_wait,            'R', c7,
              i.max_wait,            'R', c8,
              i.blocks,              'R', c9,
              i.avg_blocks,          'R', c10 ));
            END LOOP;
          END IF; -- l_count > 0
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display exec self waits: '||SQLERRM);
        END;
      END IF; -- trca$g.g_include_waits = 'Y'

      -- binds
      IF trca$g.g_include_binds = 'Y' THEN
        DECLARE
          l_exec_binds INTEGER;
          cols INTEGER := 5;
          c1   INTEGER := 5;
          c2   INTEGER := 6;
          c3   INTEGER := 6;
          c4   INTEGER := 8;
          c5   INTEGER := 7;
        BEGIN
          SELECT COUNT(*)
            INTO l_exec_binds
            FROM trca$_exec_binds
           WHERE tool_execution_id = p_tool_execution_id
             AND group_id          = p_group_id
             AND exec_id           = p_exec_id
             AND ROWNUM            = 1;

          IF l_exec_binds > 0 THEN
            SELECT GREATEST(NVL(MAX(LENGTH(bind)), 0) + GAP, c1),
                   GREATEST(NVL(MAX(LENGTH(data_type_code)), 0) + GAP, c2),
                   GREATEST(NVL(MAX(LENGTH(data_type_name)), 0) + GAP, c3),
                   GREATEST(NVL(MAX(LENGTH(actual_value_length)), 0) + GAP, c4),
                   GREATEST(NVL(MAX(LENGTH(value)), 0) + GAP, c5)
              INTO c1, c2, c3, c4, c5
              FROM trca$_exec_binds_vf
             WHERE group_id          = p_group_id
               AND exec_id           = p_exec_id
               AND tool_execution_id = p_tool_execution_id;

            printf(LF||
            title_and_value(cols,
            NULL,     'R', c1,
            NULL,     'R', c2,
            NULL,     'R', c3,
            'Actual', 'R', c4,
            NULL,     'R', c5 )||LF||
            title_and_value(cols,
            'Bind ', 'R', c1,
            'DTY',   'R', c2,
            'Data ', 'C', c3,
            'Value', 'R', c4,
            NULL,    'R', c5 )||LF||
            title_and_value(cols,
            'Pos ',   'R', c1,
            'Code',   'R', c2,
            'Type ',  'C', c3,
            'Length', 'R', c4,
            'Value ', 'C', c5 )||LF||
            title_and_value(cols,
            SUBSTR(DASHES, 1, c1),      'R', c1,
            SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5  - 1), 'R', c5 ));

            FOR i IN (SELECT *
                        FROM trca$_exec_binds_vf
                       WHERE tool_execution_id = p_tool_execution_id
                         AND group_id          = p_group_id
                         AND exec_id           = p_exec_id
                       ORDER BY
                             bind)
            LOOP
              printf(title_and_value(cols,
              i.bind||':',           'R', c1,
              i.data_type_code,      'R', c2,
              ' '||i.data_type_name, 'L', c3,
              i.actual_value_length, 'R', c4,
              ' '||i.value,          'L', c5 ));
            END LOOP;
          END IF; -- l_exec_binds > 0
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display binds for this exec: '||SQLERRM);
        END;
      END IF; -- trca$g.g_include_binds
    END IF; -- exec_v.response_time_self

  EXCEPTION
    WHEN OTHERS THEN
      print_log('*** cannot generate html for exec '||p_exec_id||' '||SQLERRM);
  END gen_html_exec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private gen_html_group
   *
   * ------------------------- */
  PROCEDURE gen_html_group (
    p_tool_execution_id IN INTEGER,
    p_group_id          IN INTEGER )
  IS
    LONG_DATE_FORMAT  CONSTANT VARCHAR2(32767) := 'DD-MON-YY HH24:MI:SS';

    grp_rec trca$_group%ROWTYPE;
    stm_rec trca$_statement%ROWTYPE;
    sql_vf  trca$_sql_vf%ROWTYPE;
    rtf_rec trca$_response_time_summary_vf%ROWTYPE;
    l_count INTEGER;
    incl_self_time_totals_etc BOOLEAN;
    incl_explain_plan BOOLEAN;
    incl_actual_rows BOOLEAN;
    incl_tables BOOLEAN;
    incl_indexes BOOLEAN;
    incl_progeny_time_totals BOOLEAN;
    incl_segment_io_summary BOOLEAN;
    incl_segment_io_summary2 BOOLEAN;
    incl_relevant_exec BOOLEAN;

  /*************************************************************************************/

  BEGIN /* gen_html_group */
    /* -------------------------
     * Initialization
     * ------------------------- */
    SELECT * INTO grp_rec FROM trca$_group                    WHERE id = p_group_id              AND tool_execution_id = p_tool_execution_id;
    SELECT * INTO sql_vf  FROM trca$_sql_vf                   WHERE group_id = p_group_id        AND tool_execution_id = p_tool_execution_id;
    SELECT * INTO stm_rec FROM trca$_statement                WHERE id = grp_rec.statement_id;
    SELECT * INTO rtf_rec FROM trca$_response_time_summary_vf WHERE tool_execution_id = p_tool_execution_id;

    /* -------------------------
     * Includes
     * ------------------------- */
    IF grp_rec.response_time_self > 0 THEN
      incl_self_time_totals_etc := TRUE;
    ELSE
      incl_self_time_totals_etc := FALSE;
    END IF;

    IF grp_rec.include_details = 'Y' THEN
      -- incl_progeny_time_totals
      IF grp_rec.response_time_progeny > 0 THEN
        incl_progeny_time_totals := TRUE;
      ELSE
        incl_progeny_time_totals := FALSE;
      END IF;

      -- incl_explain_plan, incl_actual_rows, incl_tables and incl_indexes
      IF trca$g.g_include_expl_plans = 'Y' THEN
        SELECT COUNT(*)
          INTO l_count
          FROM trca$_plan_table_vf
         WHERE group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id
           AND ROWNUM            = 1;

        IF l_count > 0 THEN
          incl_explain_plan := TRUE;

          SELECT COUNT(*)
            INTO l_count
            FROM trca$_plan_table_vf
           WHERE group_id          = p_group_id
             AND tool_execution_id = p_tool_execution_id
             AND actual_rows IS NOT NULL
             AND ROWNUM            = 1;

          IF l_count > 0 THEN
            incl_actual_rows := TRUE;
          ELSE
            incl_actual_rows := FALSE;
          END IF;
        ELSE
          incl_explain_plan := FALSE;
          incl_actual_rows := FALSE;
        END IF;

        IF trca$g.g_include_segments = 'Y' THEN
          SELECT COUNT(*)
            INTO l_count
            FROM trca$_group_tables_v
           WHERE group_id          = p_group_id
             AND tool_execution_id = p_tool_execution_id
             AND ROWNUM            = 1;

          IF l_count > 0 THEN
            incl_tables := TRUE;

            SELECT COUNT(*)
              INTO l_count
              FROM trca$_group_indexes_v
             WHERE group_id          = p_group_id
               AND tool_execution_id = p_tool_execution_id
               AND ROWNUM            = 1;

            IF l_count > 0 THEN
              incl_indexes := TRUE;
            ELSE
              incl_indexes := FALSE;
            END IF;
          ELSE
            incl_tables := FALSE;
            incl_indexes := FALSE;
          END IF;
        ELSE
          incl_tables := FALSE;
          incl_indexes := FALSE;
        END IF;
      ELSE
        incl_explain_plan := FALSE;
        incl_actual_rows := FALSE;
        incl_tables := FALSE;
        incl_indexes := FALSE;
      END IF;

      -- incl_segment_io_summary and incl_segment_io_summary2
      IF grp_rec.response_time_self > 0 AND trca$g.g_include_waits = 'Y' AND trca$g.g_include_segments = 'Y' THEN
        SELECT COUNT(*)
          INTO l_count
          FROM trca$_sql_wait_segment_vf
         WHERE group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id
           AND ROWNUM            = 1;

        IF l_count > 0 THEN
          incl_segment_io_summary := TRUE;

          SELECT COUNT(*)
            INTO l_count
            FROM trca$_sql_wait_seg_cons_vf
           WHERE group_id          = p_group_id
             AND tool_execution_id = p_tool_execution_id
             AND ROWNUM            = 1;

          IF l_count > 0 THEN
            incl_segment_io_summary2 := TRUE;
          ELSE
            incl_segment_io_summary2 := FALSE;
          END IF;
        ELSE
          incl_segment_io_summary := FALSE;
          incl_segment_io_summary2 := FALSE;
        END IF;
      ELSE
        incl_segment_io_summary := FALSE;
        incl_segment_io_summary2 := FALSE;
      END IF;

      -- incl_relevant_exec
      SELECT COUNT(*)
        INTO l_count
        FROM trca$_exec
       WHERE tool_execution_id = p_tool_execution_id
         AND group_id          = p_group_id;

      IF l_count > 1 THEN
        incl_relevant_exec := TRUE;
      ELSE
        incl_relevant_exec := FALSE;
      END IF;
    ELSE
      incl_progeny_time_totals := FALSE;
      incl_segment_io_summary := FALSE;
      incl_segment_io_summary2 := FALSE;
      incl_relevant_exec := FALSE;
    END IF; -- grp_rec.include_details

    /* -------------------------
     * SQL Title
     * ------------------------- */
    DECLARE
      l_text VARCHAR2(32767);
    BEGIN
      printf(stm_rec.hv||' '||stm_rec.sqlid||' '||grp_rec.plh||LF);

      l_text := 'Rank:'||grp_rec.rank||'('||sql_vf.contribution||') ';

      IF grp_rec.err IS NOT NULL THEN
        l_text := 'ORA-'||LPAD(grp_rec.err, 5, '0')||LF||LF||l_text;
      END IF;

      l_text := l_text||'Self:'||sql_vf.response_time_self||'s ';
      l_text := l_text||'Recursive:'||sql_vf.response_time_progeny||'s ';
      l_text := l_text||'Invoker:'||grp_rec.uid#||' ';
      l_text := l_text||'Definer:'||grp_rec.lid||' ';
      l_text := l_text||'Depth:'||grp_rec.dep||' ';
      printf(l_text||LF);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display sql title for '||p_group_id||': '||SQLERRM);
    END;

    /* -------------------------
     * SQL Text
     * ------------------------- */
    DECLARE
      l_text VARCHAR2(32767);
      l_clob CLOB;
    BEGIN
      l_clob := trca$g.wrap_text (
        p_clob         => stm_rec.sql_fulltext,
        p_max_line_len => MAX_LINE_SZ,
        p_add_br       => 'N',
        p_lt_gt_quote  => 'N' );

      IF l_clob IS NOT NULL AND SYS.DBMS_LOB.GETLENGTH(l_clob) > 0 THEN
        SYS.DBMS_LOB.APPEND (
          dest_lob => s_file_rec.file_text,
          src_lob  => l_clob );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display sql title for '||p_group_id||': '||SQLERRM);
    END;

    /* -------------------------
     * SQL Self - Time, Totals, Waits, Binds and Row Source Plan
     * ------------------------- */
    IF incl_self_time_totals_etc THEN
      -- time
      DECLARE
        cols INTEGER := 7;
        c1   INTEGER := 8;
        c2   INTEGER := 15;
        c3   INTEGER := 9;
        c4   INTEGER := 10;
        c5   INTEGER := 11;
        c6   INTEGER := 17;
        c7   INTEGER := 11;
      BEGIN
        SELECT GREATEST(NVL(MAX(LENGTH(accounted_response)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(elapsed)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(cpu)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(elapsed_unaccounted_for)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c7)
          INTO c2, c3, c4, c5, c6, c7
          FROM trca$_sql_self_time_vf
         WHERE group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id;

        printf(LF||LF||
        'SQL SELF - TIME, TOTALS, WAITS, BINDS AND ROW SOURCE PLAN'||LF||
        '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'||LF||LF||
        title_and_value(cols,
        NULL,             'R', c1,
        'Response Time',  'R', c2,
        'Elapsed',        'R', c3,
        NULL,             'R', c4,
        'Non-Idle',       'R', c5,
        'Elapsed Time',   'R', c6,
        'Idle',           'R', c7 )||LF||
        title_and_value(cols,
        'Call ',           'R', c1,
        'Accounted-for',   'R', c2,
        'Time',            'R', c3,
        'CPU Time',        'R', c4,
        'Wait Time',       'R', c5,
        'Unaccounted-for', 'R', c6,
        'Wait Time',       'R', c7 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),     'R', c1,
        SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7 - 1), 'R', c7 ));

        FOR i IN (SELECT *
                    FROM trca$_sql_self_time_vf
                   WHERE group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          IF i.call = trca$g.CALL_TOTAL THEN
            printf(title_and_value(cols,
            SUBSTR(DASHES, 1, c1),     'R', c1,
            SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
            SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
            SUBSTR(DASHES, 1, c7 - 1), 'R', c7 ));
          END IF;

          printf(title_and_value(cols,
          i.call_type||':',           'R', c1,
          i.accounted_response,       'R', c2,
          i.elapsed,                  'R', c3,
          i.cpu,                      'R', c4,
          i.non_idle_wait,            'R', c5,
          i.elapsed_unaccounted_for,  'R', c6,
          i.idle_wait,                'R', c7 ));
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql self time: '||SQLERRM);
      END;

      -- totals
      DECLARE
        cols INTEGER := 9;
        c1   INTEGER := 8;
        c2   INTEGER := 7;
        c3   INTEGER := 13;
        c4   INTEGER := 15;
        c5   INTEGER := 12;
        c6   INTEGER := 13;
        c7   INTEGER := 9;
        c8   INTEGER := 10;
        c9   INTEGER := 8;
      BEGIN
        SELECT GREATEST(NVL(MAX(LENGTH(call_count)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(p_disk_os)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(cr_query_consistent)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(cu_current)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(r_rows)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(mis_library_cache_misses)), 0) + GAP, c7),
               GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c8),
               GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c9)
          INTO c2, c3, c4, c5, c6, c7, c8, c9
          FROM trca$_sql_self_total_v
         WHERE group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id;

        printf(LF||
        title_and_value(cols,
        NULL,            'R', c1,
        NULL,            'R', c2,
        'OS',            'R', c3,
        'BG Consistent', 'R', c4,
        'BG Current',    'R', c5,
        'Rows',          'R', c6,
        'Library',       'R', c7,
        'Times',         'R', c8,
        'Times',         'R', c9 )||LF||
        title_and_value(cols,
        NULL,          'R', c1,
        'Call',        'R', c2,
        'Buffer Gets', 'R', c3,
        'Read Mode',   'R', c4,
        'Mode',        'R', c5,
        'Processed',   'R', c6,
        'Cache',       'R', c7,
        'Waited',      'R', c8,
        'Waited',      'R', c9 )||LF||
        title_and_value(cols,
        'Call ',       'R', c1,
        'Count',       'R', c2,
        '(disk)',      'R', c3,
        '(query)',     'R', c4,
        '(current)',   'R', c5,
        'or Returned', 'R', c6,
        'Misses',      'R', c7,
        'Non-Idle',    'R', c8,
        'Idle',        'R', c9 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),     'R', c1,
        SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
        SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
        SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));

        FOR i IN (SELECT *
                    FROM trca$_sql_self_total_v
                   WHERE group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          IF i.call = trca$g.CALL_TOTAL THEN
            printf(title_and_value(cols,
            SUBSTR(DASHES, 1, c1),     'R', c1,
            SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
            SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
            SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
            SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
            SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));
          END IF;

          printf(title_and_value(cols,
          i.call_type||':',           'R', c1,
          i.call_count,               'R', c2,
          i.p_disk_os,                'R', c3,
          i.cr_query_consistent,      'R', c4,
          i.cu_current,               'R', c5,
          i.r_rows,                   'R', c6,
          i.mis_library_cache_misses, 'R', c7,
          i.wait_count_non_idle,      'R', c8,
          i.wait_count_idle,          'R', c9 ));
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql self totals: '||SQLERRM);
      END;

      -- waits
      IF trca$g.g_include_waits = 'Y' THEN
        DECLARE
          l_count INTEGER;
          cols INTEGER := 10;
          c1   INTEGER := 7;
          c2   INTEGER := 7;
          c3   INTEGER := 11;
          c4   INTEGER := 10;
          c5   INTEGER := 11;
          c6   INTEGER := 8;
          c7   INTEGER := 11;
          c8   INTEGER := 11;
          c9   INTEGER := 8;
          c10  INTEGER := 9;
        BEGIN
          SELECT COUNT(*),
                 GREATEST(NVL(MAX(LENGTH(event_name)), 0) + GAP, c1),
                 GREATEST(NVL(MAX(LENGTH(wait_class)), 0) + GAP, c2),
                 GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c3),
                 GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c4),
                 GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c5),
                 GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c6),
                 GREATEST(NVL(MAX(LENGTH(avg_wait)), 0) + GAP, c7),
                 GREATEST(NVL(MAX(LENGTH(max_wait)), 0) + GAP, c8),
                 GREATEST(NVL(MAX(LENGTH(blocks)), 0) + GAP, c9),
                 GREATEST(NVL(MAX(LENGTH(avg_blocks)), 0) + GAP, c10)
            INTO l_count, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10
            FROM trca$_sql_self_wait_vf
           WHERE group_id          = p_group_id
             AND tool_execution_id = p_tool_execution_id;

          IF l_count > 0 THEN
            printf(LF||
            title_and_value(cols,
            NULL,    'R', c1,
            NULL,    'R', c2,
            NULL,    'R', c3,
            'Times', 'R', c4,
            NULL,    'R', c5,
            'Times', 'R', c6,
            NULL,    'R', c7,
            NULL,    'R', c8,
            NULL,    'R', c9,
            NULL,    'R', c10 )||LF||
            title_and_value(cols,
            'Event ',   'R', c1,
            ' Wait',    'L', c2,
            'Non-Idle', 'R', c3,
            'Waited',   'R', c4,
            'Idle',     'R', c5,
            'Waited',   'R', c6,
            'Average',  'R', c7,
            'Max',      'R', c8,
            NULL,       'R', c9,
            'Average',  'R', c10 )||LF||
            title_and_value(cols,
            'Name ',       'R', c1,
            ' Class',      'L', c2,
            'Wait Time',   'R', c3,
            'Non-Idle',    'R', c4,
            'Wait Time',   'R', c5,
            'Idle',        'R', c6,
            'Wait Time',   'R', c7,
            'Wait Time',   'R', c8,
            'Blocks',      'R', c9,
            'Blocks',      'R', c10)||LF||
            title_and_value(cols,
            SUBSTR(DASHES, 1, c1),      'R', c1,
            SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
            SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
            SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
            SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
            SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
            SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));

            FOR i IN (SELECT *
                        FROM trca$_sql_self_wait_vf
                       WHERE group_id          = p_group_id
                         AND tool_execution_id = p_tool_execution_id
                       ORDER BY
                             row_type,
                             wait DESC)
            LOOP
              IF i.row_type = 'T' THEN
                printf(title_and_value(cols,
                SUBSTR(DASHES, 1, c1),      'R', c1,
                SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
                SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
                SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
                SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
                SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
                SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
                SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
                SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
                SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));
              END IF;

              printf(title_and_value(cols,
              i.event_name||':',     'R', c1,
              ' '||i.wait_class,     'L', c2,
              i.non_idle_wait,       'R', c3,
              i.wait_count_non_idle, 'R', c4,
              i.idle_wait,           'R', c5,
              i.wait_count_idle,     'R', c6,
              i.avg_wait,            'R', c7,
              i.max_wait,            'R', c8,
              i.blocks,              'R', c9,
              i.avg_blocks,          'R', c10 ));
            END LOOP;
          END IF; -- l_count > 0
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display sql self waits: '||SQLERRM);
        END;
      END IF; -- trca$g.g_include_waits = 'Y'

      -- binds if there is only one execution
      IF trca$g.g_include_binds = 'Y' AND grp_rec.exec_count = 1 THEN
        DECLARE
          l_exec_binds INTEGER;
          cols INTEGER := 5;
          c1   INTEGER := 5;
          c2   INTEGER := 6;
          c3   INTEGER := 6;
          c4   INTEGER := 8;
          c5   INTEGER := 7;
        BEGIN
          SELECT COUNT(DISTINCT exec_id)
            INTO l_exec_binds
            FROM trca$_exec_binds
           WHERE tool_execution_id = p_tool_execution_id
             AND group_id          = p_group_id;

          IF l_exec_binds = 1 THEN
            SELECT GREATEST(NVL(MAX(LENGTH(bind)), 0) + GAP, c1),
                   GREATEST(NVL(MAX(LENGTH(data_type_code)), 0) + GAP, c2),
                   GREATEST(NVL(MAX(LENGTH(data_type_name)), 0) + GAP, c3),
                   GREATEST(NVL(MAX(LENGTH(actual_value_length)), 0) + GAP, c4),
                   GREATEST(NVL(MAX(LENGTH(value)), 0) + GAP, c5)
              INTO c1, c2, c3, c4, c5
              FROM trca$_exec_binds_vf
             WHERE group_id          = p_group_id
               AND tool_execution_id = p_tool_execution_id;

            printf(LF||
            title_and_value(cols,
            NULL,     'R', c1,
            NULL,     'R', c2,
            NULL,     'R', c3,
            'Actual', 'R', c4,
            NULL,     'R', c5 )||LF||
            title_and_value(cols,
            'Bind ', 'R', c1,
            'DTY',   'R', c2,
            'Data ', 'C', c3,
            'Value', 'R', c4,
            NULL,    'R', c5 )||LF||
            title_and_value(cols,
            'Pos ',   'R', c1,
            'Code',   'R', c2,
            'Type ',  'C', c3,
            'Length', 'R', c4,
            'Value ', 'C', c5 )||LF||
            title_and_value(cols,
            SUBSTR(DASHES, 1, c1),      'R', c1,
            SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5  - 1), 'R', c5 ));

            FOR i IN (SELECT *
                        FROM trca$_exec_binds_vf
                       WHERE tool_execution_id = p_tool_execution_id
                         AND group_id          = p_group_id
                       ORDER BY
                             bind)
            LOOP
              printf(title_and_value(cols,
              i.bind||':',           'R', c1,
              i.data_type_code,      'R', c2,
              ' '||i.data_type_name, 'L', c3,
              i.actual_value_length, 'R', c4,
              ' '||i.value,          'L', c5 ));
            END LOOP;
          END IF; -- l_exec_binds = 1
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display binds for one exec: '||SQLERRM);
        END;
      END IF; -- trca$g.g_include_binds = 'Y'

      -- row source plan
      DECLARE
        cols INTEGER := 12;
        c1   INTEGER := 3;
        c2   INTEGER := 5;
        c3   INTEGER := 0; -- 7
        c4   INTEGER := 8;
        c5   INTEGER := 22;
        c6   INTEGER := 0; -- 12
        c7   INTEGER := 0; -- 8
        c8   INTEGER := 0; -- 7
        c9   INTEGER := 0; -- 8
        c10  INTEGER := 5;
        c11  INTEGER := 0; -- 6
        c12  INTEGER := 0; -- 9
        l_sessions NUMBER := 0;

        PROCEDURE rsp_title
        IS
        BEGIN
          printf(
          title_and_value(cols,
          NULL, 'R', c1,
          NULL, 'R', c2,
          NULL, 'R', c3,
          NULL, 'R', c4,
          NULL, 'R', c5,
          'BG', 'R', c6,
          'OS', 'R', c7,
          'OS', 'R', c8,
          NULL, 'R', c9,
          NULL, 'R', c10,
          NULL, 'R', c11,
          NULL, 'R', c12 )||LF||
          title_and_value(cols,
          NULL,         'R', c1,
          NULL,         'R', c2,
          NULL,         'R', c3,
          NULL,         'R', c4,
          NULL,         'R', c5,
          'Consistent', 'R', c6,
          'Buffer',     'R', c7,
          'Write',      'R', c8,
          NULL,         'R', c9,
          NULL,         'R', c10,
          NULL,         'R', c11,
          'Estim',         'R', c12 )||LF||
          title_and_value(cols,
          NULL,        'R', c1,
          NULL,        'R', c2,
          'Estim',     'R', c3,
          'Actual',    'R', c4,
          NULL,        'R', c5,
          'Read Mode', 'R', c6,
          'Gets',      'R', c7,
          'Calls',     'R', c8,
          'Time',      'R', c9,
          NULL,        'R', c10,
          NULL,        'R', c11,
          'Size',      'R', c12 )||LF||
          title_and_value(cols,
          'ID ',                   'R', c1,
          'PID',                   'R', c2,
          'Card',                  'R', c3,
          'Rows',                  'R', c4,
          'Row Source Operation ', 'C', c5,
          '(cr)',                  'R', c6,
          '(pr)',                  'R', c7,
          '(pw)',                  'R', c8,
          '(secs)',                'R', c9,
          'Obj',                   'R', c10,
          'Cost',                  'R', c11,
          '(bytes)',               'R', c12 )||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),      'R', c1,
          SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
          SUBSTR(DASHES, 1, c11 - 1), 'R', c11,
          SUBSTR(DASHES, 1, c12 - 1), 'R', c12 ));
        END rsp_title;

      BEGIN
        FOR i IN (SELECT trca_plan_hash_value
                    FROM trca$_group_row_source_plan
                   WHERE tool_execution_id = p_tool_execution_id
                     AND group_id          = p_group_id
                   ORDER BY
                         first_exec_id)
        LOOP
          IF trca$g.g_card = 'Y' THEN
            c3  := 7;
            c12 := 9;
          END IF;

          IF trca$g.g_time = 'Y' THEN
            c6 := 12;
            c7 := 8;
            c8 := 7;
            c9 := 8;
          END IF;

          SELECT GREATEST(NVL(MAX(LENGTH(id)), 0) + GAP, c1),
                 GREATEST(NVL(MAX(LENGTH(pid)), 0) + GAP, c2),
                 GREATEST(NVL(MAX(LENGTH(card)), 0) + GAP, c3),
                 GREATEST(NVL(MAX(LENGTH(cnt)), 0) + GAP, c4),
                 GREATEST(NVL(MAX(LENGTH(op_prefix||op)), 0) + GAP, c5),
                 GREATEST(NVL(MAX(LENGTH(cr)), 0) + GAP, c6),
                 GREATEST(NVL(MAX(LENGTH(pr)), 0) + GAP, c7),
                 GREATEST(NVL(MAX(LENGTH(pw)), 0) + GAP, c8),
                 GREATEST(NVL(MAX(LENGTH(time)), 0) + GAP, c9),
                 GREATEST(NVL(MAX(LENGTH(obj)), 0) + GAP, c10),
                 GREATEST(NVL(MAX(LENGTH(cost)), 0) + GAP, c11),
                 GREATEST(NVL(MAX(LENGTH(siz)), 0) + GAP, c12)
            INTO c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12
            FROM trca$_row_source_plan_vf
           WHERE tool_execution_id    = p_tool_execution_id
             AND group_id             = p_group_id
             AND trca_plan_hash_value = i.trca_plan_hash_value;

          printf(LF||' ');
          rsp_title;

          FOR j IN (SELECT *
                      FROM trca$_row_source_plan_vf
                     WHERE tool_execution_id    = p_tool_execution_id
                       AND group_id             = p_group_id
                       AND trca_plan_hash_value = i.trca_plan_hash_value
                     ORDER BY
                           id)
          LOOP
            printf(title_and_value(cols,
            j.id||':',              'R', c1,
            j.pid,                  'R', c2,
            j.card,                 'R', c3,
            j.cnt,                  'R', c4,
            ' '||j.op_prefix||j.op, 'L', c5,
            j.cr,                   'R', c6,
            j.pr,                   'R', c7,
            j.pw,                   'R', c8,
            j.time,                 'R', c9,
            j.obj,                  'R', c10,
            j.cost,                 'R', c11,
            j.siz,                  'R', c12 ));

            IF j.sessions > l_sessions THEN
              l_sessions := j.sessions;
            END IF;
          END LOOP;

          IF l_sessions > 1 THEN
            FOR j IN (SELECT DISTINCT session_id, sid, serial#, file_name
                        FROM trca$_row_source_plan_sess_vf
                       WHERE tool_execution_id    = p_tool_execution_id
                         AND group_id             = p_group_id
                         AND trca_plan_hash_value = i.trca_plan_hash_value
                       ORDER BY
                             session_id, sid, serial#, file_name)
            LOOP

            printf(LF||'Session ('||j.sid||'.'||j.serial#||') in file '||j.file_name);
            rsp_title;

              FOR k IN (SELECT *
                          FROM trca$_row_source_plan_sess_vf
                         WHERE tool_execution_id    = p_tool_execution_id
                           AND group_id             = p_group_id
                           AND trca_plan_hash_value = i.trca_plan_hash_value
                           AND sid                  = j.sid
                           AND serial#              = j.serial#
                         ORDER BY
                               id)
              LOOP
                printf(title_and_value(cols,
                k.id||':',              'R', c1,
                k.pid,                  'R', c2,
                k.card,                 'R', c3,
                k.cnt,                  'R', c4,
                ' '||k.op_prefix||k.op, 'L', c5,
                k.cr,                   'R', c6,
                k.pr,                   'R', c7,
                k.pw,                   'R', c8,
                k.time,                 'R', c9,
                k.obj,                  'R', c10,
                k.cost,                 'R', c11,
                k.siz,                  'R', c12 ));
              END LOOP;
            END LOOP;
          END IF;
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql row source plan: '||SQLERRM);
      END;
    END IF; -- incl_self_time_totals_etc

    /* -------------------------
     * Explain Plan
     * ------------------------- */
    IF incl_explain_plan THEN
      DECLARE
        l_search_cols VARCHAR2(32767);
        l_foot2 VARCHAR2(32767) := NULL;
        cols INTEGER := 7;
        c1   INTEGER := 3;
        c2   INTEGER := 5;
        c3   INTEGER := 0; -- 9
        c4   INTEGER := 7;
        c5   INTEGER := 6;
        c6   INTEGER := 24;
        c7   INTEGER := 9;

      BEGIN
        printf(LF||LF||
        'EXPLAIN PLAN'||LF||
        '~~~~~~~~~~~~');

        IF incl_actual_rows THEN
          c3 := 9;
          l_foot2 := LF||'(2) Actual rows returned by operation (average if there were more than 1 execution).';
        END IF;

        SELECT GREATEST(NVL(MAX(LENGTH(id)), 0) + GAP, c1),
               GREATEST(NVL(MAX(LENGTH(parent_id)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(actual_rows)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(cardinality)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(cost)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(op_prefix||op)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(CASE WHEN columns_count IS NOT NULL THEN NVL(search_columns, 0)||'/'||columns_count END)), 0) + GAP, c7)
          INTO c1, c2, c3, c4, c5, c6, c7
          FROM trca$_plan_table_vf
         WHERE group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id;

        printf(LF||
        title_and_value(cols,
        NULL,      'R', c1,
        NULL,      'R', c2,
        'Actual',  'R', c3,
        'Estim',   'R', c4,
        NULL,      'R', c5,
        NULL,      'R', c6,
        'Search',  'R', c7 )||LF||
        title_and_value(cols,
        'ID ',                     'R', c1,
        'PID',                     'R', c2,
        'Rows(2)',                 'R', c3,
        'Card',                    'R', c4,
        'Cost',                    'R', c5,
        'Explain Plan Operation ', 'C', c6,
        'Cols(1)',                 'R', c7 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),      'R', c1,
        SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7  - 1), 'R', c7 ));

        FOR i IN (SELECT *
                    FROM trca$_plan_table_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND group_id          = p_group_id
                   ORDER BY
                         id)
        LOOP
          IF i.columns_count IS NULL THEN
            l_search_cols := NULL;
          ELSE
            l_search_cols := NVL(i.search_columns, 0)||'/'||i.columns_count;
          END IF;

          printf(title_and_value(cols,
          i.id||':',              'R', c1,
          i.parent_id,            'R', c2,
          i.actual_rows,          'R', c3,
          i.cardinality,          'R', c4,
          i.cost,                 'R', c5,
          ' '||i.op_prefix||i.op, 'L', c6,
          l_search_cols,          'R', c7 ));
        END LOOP;

        printf(LF||
        '(1) X/Y: Where X is the number of searched columns from index, which has a total of Y columns.'||
        l_foot2);
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display explain plan1: '||SQLERRM);
      END;

      DECLARE
        l_search_cols VARCHAR2(32767);
        cols INTEGER := 1;
        c1   INTEGER := 0; -- 32
        c2   INTEGER := 0;

      BEGIN
        SELECT GREATEST(
               NVL(MAX(LENGTH(indexed_columns)), 0),
               NVL(MAX(LENGTH(access_predicates)), 0),
               NVL(MAX(LENGTH(filter_predicates)), 0),
               c1),
               GREATEST(NVL(MAX(LENGTH(id)), 0) + GAP, c2)
          INTO c1, c2
          FROM trca$_plan_table_vf
         WHERE group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id;

        IF c1 > GAP THEN
          c1 := 32;

          printf(LF||
          title_and_value(cols,
          'Indexed Cols and Predicates(1)', 'L', c1 )||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1), 'L', c1 ));

          FOR i IN (SELECT *
                      FROM trca$_plan_table_vf
                     WHERE tool_execution_id = p_tool_execution_id
                       AND group_id          = p_group_id
                     ORDER BY
                           id)
          LOOP
            IF i.columns_count IS NULL THEN
              l_search_cols := NULL;
            ELSE
              l_search_cols := ' (search '||NVL(i.search_columns, 0)||'/'||i.columns_count||')';
            END IF;

            IF i.indexed_columns IS NOT NULL THEN
              printf(LPAD(i.id, c2)||' - Indexed Cols for '||i.object_name||l_search_cols||':');
              printf(LPAD(' ', c2 + 3, ' ')||REPLACE(i.indexed_columns, ' ', LF||LPAD(' ', c2 + 3, ' ')));
            END IF;

            IF i.access_predicates IS NOT NULL THEN
              printf(title_and_value(cols,
              LPAD(i.id, c2)||' - Access Predicates:', 'L', c1));

              SYS.DBMS_LOB.APPEND (
                dest_lob => s_file_rec.file_text,
                src_lob  => LPAD(' ', c2 + 3, ' ')||TRIM(REPLACE(
                            trca$g.wrap_text (
                              p_clob         => REPLACE(i.access_predicates, '"'),
                              p_max_line_len => MAX_LINE_SZ - c2 - 3,
                              p_add_br       => 'N',
                              p_lt_gt_quote  => 'N' ),
                            LF, LF||LPAD(' ', c2 + 3, ' '))));
            END IF;

            IF i.filter_predicates IS NOT NULL THEN
              printf(title_and_value(cols,
              LPAD(i.id, c2)||' - Filter Predicates:', 'L', c1));

              SYS.DBMS_LOB.APPEND (
                dest_lob => s_file_rec.file_text,
                src_lob  => LPAD(' ', c2 + 3, ' ')||TRIM(REPLACE(
                            trca$g.wrap_text (
                              p_clob         => REPLACE(i.filter_predicates, '"'),
                              p_max_line_len => MAX_LINE_SZ - c2 - 3,
                              p_add_br       => 'N',
                              p_lt_gt_quote  => 'N' ),
                            LF, LF||LPAD(' ', c2 + 3, ' '))));
            END IF;
          END LOOP;

          printf(LF||
          '(1) Identified by operation ID.');
        END IF; -- c1 > GAP
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display explain plan2: '||SQLERRM);
      END;
    END IF; -- incl_explain_plan

    /* -------------------------
     * Tables and Indexes
     * ------------------------- */
    IF incl_tables OR incl_indexes THEN
      printf(LF||LF||
      'TABLES AND INDEXES'||LF||
      '~~~~~~~~~~~~~~~~~~');

      -- tables
      IF incl_tables THEN
        DECLARE
          l_row INTEGER := 0;
          cols INTEGER := 16;
          c1   INTEGER := 2;
          c2   INTEGER := 18;
          c3   INTEGER := 8;
          c4   INTEGER := 9;
          c5   INTEGER := 13;
          c6   INTEGER := 9;
          c7   INTEGER := 9;
          c8   INTEGER := 18;
          c9   INTEGER := 8;
          c10  INTEGER := 10;
          c11  INTEGER := 11;
          c12  INTEGER := 11;
          c13  INTEGER := 10;
          c14  INTEGER := 10;
          c15  INTEGER := 6;
          c16  INTEGER := 6;

        BEGIN
          SELECT GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
                 GREATEST(NVL(MAX(LENGTH(owner||'.'||table_name)), 0) + GAP, c2),
                 GREATEST(NVL(MAX(LENGTH(in_row_source_plan)), 0) + GAP, c3),
                 GREATEST(NVL(MAX(LENGTH(in_explain_plan)), 0) + GAP, c4),
                 GREATEST(NVL(MAX(LENGTH(actual_rows)), 0) + GAP, c5),
                 GREATEST(NVL(MAX(LENGTH(num_rows)), 0) + GAP, c6),
                 GREATEST(NVL(MAX(LENGTH(sample_size)), 0) + GAP, c7),
                 GREATEST(NVL(MAX(LENGTH(TO_CHAR(last_analyzed, LONG_DATE_FORMAT))), 0) + GAP, c8),
                 GREATEST(NVL(MAX(LENGTH(avg_row_len)), 0) + GAP, c9),
                 GREATEST(NVL(MAX(LENGTH(chain_cnt)), 0) + GAP, c10),
                 GREATEST(NVL(MAX(LENGTH(blocks)), 0) + GAP, c11),
                 GREATEST(NVL(MAX(LENGTH(empty_blocks)), 0) + GAP, c12),
                 GREATEST(NVL(MAX(LENGTH(avg_space)), 0) + GAP, c13),
                 GREATEST(NVL(MAX(LENGTH(global_stats)), 0) + GAP, c14),
                 GREATEST(NVL(MAX(LENGTH(partitioned)), 0) + GAP, c15),
                 GREATEST(NVL(MAX(LENGTH(temporary)), 0) + GAP, c16)
            INTO c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16
            FROM trca$_group_tables_v
           WHERE tool_execution_id = p_tool_execution_id
             AND group_id          = p_group_id;

          printf(LF||
          title_and_value(cols,
          NULL,     'R', c1,
          NULL,     'R', c2,
          'in Row', 'R', c3,
          'in',     'R', c4,
          NULL,     'R', c5,
          NULL,     'R', c6,
          NULL,     'R', c7,
          NULL,     'R', c8,
          'Avg',    'R', c9,
          NULL,     'R', c10,
          NULL,     'R', c11,
          NULL,     'R', c12,
          NULL,     'R', c13,
          NULL,     'R', c14,
          NULL,     'R', c15,
          NULL,     'R', c16 )||LF||
          title_and_value(cols,
          NULL,      'R', c1,
          NULL,      'R', c2,
          'Source',  'R', c3,
          'Explain', 'R', c4,
          'Current', 'R', c5,
          'Num',     'R', c6,
          'Sample',  'R', c7,
          NULL,      'C', c8,
          'Row',     'R', c9,
          'Chain',   'R', c10,
          NULL,      'R', c11,
          'Empty',   'R', c12,
          'Avg',     'R', c13,
          'Global',  'R', c14,
          NULL,      'R', c15,
          NULL,      'R', c16 )||LF||
          title_and_value(cols,
          '# ',                'R', c1,
          'Owner.Table Name ', 'C', c2,
          'Plan',              'R', c3,
          'Plan',              'R', c4,
          'Count(*)(2)',       'R', c5,
          'Rows(1)',           'R', c6,
          'Size(1)',           'R', c7,
          'Last Analyzed(1) ', 'C', c8,
          'Len(1)',            'R', c9,
          'Count(1)',          'R', c10,
          'Blocks(1)',         'R', c11,
          'Blocks(1)',         'R', c12,
          'Space(1)',          'R', c13,
          'Stats(1)',          'R', c14,
          'Part',              'R', c15,
          'Temp',              'R', c16 )||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),     'R', c1,
          SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9 - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
          SUBSTR(DASHES, 1, c11 - 1), 'R', c11,
          SUBSTR(DASHES, 1, c12 - 1), 'R', c12,
          SUBSTR(DASHES, 1, c13 - 1), 'R', c13,
          SUBSTR(DASHES, 1, c14 - 1), 'R', c14,
          SUBSTR(DASHES, 1, c15 - 1), 'R', c15,
          SUBSTR(DASHES, 1, c16 - 1), 'R', c16 ));

          FOR i IN (SELECT *
                      FROM trca$_group_tables_v
                     WHERE tool_execution_id = p_tool_execution_id
                       AND group_id          = p_group_id
                     ORDER BY
                           owner,
                           table_name)
          LOOP
            l_row := l_row + 1;
            printf(title_and_value(cols,
            l_row||':',                      'R', c1,
            ' '||i.owner||'.'||i.table_name, 'L', c2,
            i.in_row_source_plan,            'R', c3,
            i.in_explain_plan,               'R', c4,
            i.actual_rows,                   'R', c5,
            i.num_rows,                      'R', c6,
            i.sample_size,                   'R', c7,
            ' '||TO_CHAR(i.last_analyzed, LONG_DATE_FORMAT), 'L', c8,
            i.avg_row_len,                   'R', c9,
            i.chain_cnt,                     'R', c10,
            i.blocks,                        'R', c11,
            i.empty_blocks,                  'R', c12,
            i.avg_space,                     'R', c13,
            i.global_stats,                  'R', c14,
            i.partitioned,                   'R', c15,
            i.temporary,                     'R', c16 ));
          END LOOP;

          printf(LF||
          '(1) CBO statistics.'||LF||
          '(2) COUNT(*) up to threshold value of '||trca$g.g_count_star_th||' (tool configuartion parameter).');
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display sql tables: '||SQLERRM);
        END;
      END IF; -- incl_tables

      -- indexes1
      IF incl_indexes THEN
        DECLARE
          l_row INTEGER := 0;
          cols INTEGER := 9;
          c1   INTEGER := 2;
          c2   INTEGER := 18;
          c3   INTEGER := 18;
          c4   INTEGER := 8;
          c5   INTEGER := 9;
          c6   INTEGER := 12;
          c7   INTEGER := 12;
          c8   INTEGER := 7;
          c9   INTEGER := 17;

        BEGIN
          SELECT GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
                 GREATEST(NVL(MAX(LENGTH(table_owner||'.'||table_name)), 0) + GAP, c2),
                 GREATEST(NVL(MAX(LENGTH(owner||'.'||index_name)), 0) + GAP, c3),
                 GREATEST(NVL(MAX(LENGTH(in_row_source_plan)), 0) + GAP, c4),
                 GREATEST(NVL(MAX(LENGTH(in_explain_plan)), 0) + GAP, c5),
                 GREATEST(NVL(MAX(LENGTH(index_type)), 0) + GAP, c6),
                 GREATEST(NVL(MAX(LENGTH(uniqueness)), 0) + GAP, c7),
                 GREATEST(NVL(MAX(LENGTH(columns_count)), 0) + GAP, c8),
                 GREATEST(NVL(MAX(LENGTH(indexed_columns)), 0) + GAP, c9)
            INTO c1, c2, c3, c4, c5, c6, c7, c8, c9
            FROM trca$_group_indexes_v
           WHERE tool_execution_id = p_tool_execution_id
             AND group_id          = p_group_id;

          printf(LF||
          title_and_value(cols,
          NULL,     'R', c1,
          NULL,     'R', c2,
          NULL,     'R', c3,
          'in Row', 'R', c4,
          'in',     'R', c5,
          NULL,     'R', c6,
          NULL,     'R', c7,
          NULL,     'R', c8,
          NULL,     'R', c9 )||LF||
          title_and_value(cols,
          NULL,      'R', c1,
          NULL,      'R', c2,
          NULL,      'R', c3,
          'Source',  'R', c4,
          'Explain', 'R', c5,
          NULL,      'R', c6,
          NULL,      'R', c7,
          'Cols',    'R', c8,
          NULL,      'R', c9 )||LF||
          title_and_value(cols,
          '# ',                'R', c1,
          'Owner.Table Name ', 'C', c2,
          'Owner.Index Name ', 'C', c3,
          'Plan',              'R', c4,
          'Plan',              'R', c5,
          'Index Type ',       'C', c6,
          'Uniqueness ',       'C', c7,
          'Count',             'R', c8,
          'Indexed Columns ',  'C', c9 )||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),     'R', c1,
          SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));

          FOR i IN (SELECT *
                      FROM trca$_group_indexes_v
                     WHERE tool_execution_id = p_tool_execution_id
                       AND group_id          = p_group_id
                     ORDER BY
                           table_owner,
                           table_name,
                           owner,
                           index_name)
          LOOP
            l_row := l_row + 1;
            printf(title_and_value(cols,
            l_row||':',                            'R', c1,
            ' '||i.table_owner||'.'||i.table_name, 'L', c2,
            ' '||i.owner||'.'||i.index_name,       'L', c3,
            i.in_row_source_plan,                  'R', c4,
            i.in_explain_plan,                     'R', c5,
            ' '||i.index_type,                     'L', c6,
            ' '||i.uniqueness,                     'L', c7,
            i.columns_count,                       'R', c8,
            ' '||i.indexed_columns,                'L', c9 ));
          END LOOP;
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display sql indexes1: '||SQLERRM);
        END;
      END IF; -- incl_indexes (1)

      -- indexes2
      IF incl_indexes THEN
        DECLARE
          l_row INTEGER := 0;
          cols INTEGER := 15;
          c1   INTEGER := 2;
          c2   INTEGER := 18;
          c3   INTEGER := 18;
          c4   INTEGER := 9;
          c5   INTEGER := 9;
          c6   INTEGER := 18;
          c7   INTEGER := 10;
          c8   INTEGER := 11;
          c9   INTEGER := 11;
          c10  INTEGER := 8;
          c11  INTEGER := 8;
          c12  INTEGER := 12;
          c13  INTEGER := 10;
          c14  INTEGER := 6;
          c15  INTEGER := 6;

        BEGIN
          SELECT GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
                 GREATEST(NVL(MAX(LENGTH(table_owner||'.'||table_name)), 0) + GAP, c2),
                 GREATEST(NVL(MAX(LENGTH(owner||'.'||index_name)), 0) + GAP, c3),
                 GREATEST(NVL(MAX(LENGTH(num_rows)), 0) + GAP, c4),
                 GREATEST(NVL(MAX(LENGTH(sample_size)), 0) + GAP, c5),
                 GREATEST(NVL(MAX(LENGTH(TO_CHAR(last_analyzed, LONG_DATE_FORMAT))), 0) + GAP, c6),
                 GREATEST(NVL(MAX(LENGTH(distinct_keys)), 0) + GAP, c7),
                 GREATEST(NVL(MAX(LENGTH(blevel)), 0) + GAP, c8),
                 GREATEST(NVL(MAX(LENGTH(leaf_blocks)), 0) + GAP, c9),
                 GREATEST(NVL(MAX(LENGTH(avg_leaf_blocks_per_key)), 0) + GAP, c10),
                 GREATEST(NVL(MAX(LENGTH(avg_data_blocks_per_key)), 0) + GAP, c11),
                 GREATEST(NVL(MAX(LENGTH(clustering_factor)), 0) + GAP, c12),
                 GREATEST(NVL(MAX(LENGTH(global_stats)), 0) + GAP, c13),
                 GREATEST(NVL(MAX(LENGTH(partitioned)), 0) + GAP, c14),
                 GREATEST(NVL(MAX(LENGTH(temporary)), 0) + GAP, c15)
            INTO c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15
            FROM trca$_group_indexes_v
           WHERE tool_execution_id = p_tool_execution_id
             AND group_id          = p_group_id;

          printf(LF||
          title_and_value(cols,
          NULL,  'R', c1,
          NULL,  'R', c2,
          NULL,  'R', c3,
          NULL,  'R', c4,
          NULL,  'R', c5,
          NULL,  'R', c6,
          NULL,  'R', c7,
          NULL,  'R', c8,
          NULL,  'R', c9,
          'Avg', 'R', c10,
          'Avg', 'R', c11,
          NULL,  'R', c12,
          NULL,  'R', c13,
          NULL,  'R', c14,
          NULL,  'R', c15 )||LF||
          title_and_value(cols,
          NULL,   'R', c1,
          NULL,   'R', c2,
          NULL,   'R', c3,
          NULL,   'R', c4,
          NULL,   'R', c5,
          NULL,   'R', c6,
          NULL,   'R', c7,
          NULL,   'R', c8,
          NULL,   'R', c9,
          'Leaf', 'R', c10,
          'Data', 'R', c11,
          NULL,   'R', c12,
          NULL,   'R', c13,
          NULL,   'R', c14,
          NULL,   'R', c15 )||LF||
          title_and_value(cols,
          NULL,     'R', c1,
          NULL,     'R', c2,
          NULL,     'R', c3,
          NULL,     'R', c4,
          NULL,     'R', c5,
          NULL,     'R', c6,
          NULL,     'R', c7,
          NULL,     'R', c8,
          NULL,     'R', c9,
          'Blocks', 'R', c10,
          'Blocks', 'R', c11,
          NULL,     'R', c12,
          NULL,     'R', c13,
          NULL,     'R', c14,
          NULL,     'R', c15 )||LF||
          title_and_value(cols,
          NULL,         'R', c1,
          NULL,         'R', c2,
          NULL,         'R', c3,
          'Num',        'R', c4,
          'Sample',     'R', c5,
          NULL,         'R', c6,
          'Distinct',   'R', c7,
          NULL,         'R', c8,
          'Leaf',       'R', c9,
          'per',        'R', c10,
          'per',        'R', c11,
          'Clustering', 'R', c12,
          'Global',     'R', c13,
          NULL,         'R', c14,
          NULL,         'R', c15 )||LF||
          title_and_value(cols,
          '# ',         'R', c1,
          'Owner.Table Name ', 'C', c2,
          'Owner.Index Name ', 'C', c3,
          'Rows(1)',           'R', c4,
          'Size(1)',           'R', c5,
          'Last Analyzed(1) ', 'C', c6,
          'Keys(1)',           'R', c7,
          'Blevel(1)',         'R', c8,
          'Blocks(1)',         'R', c9,
          'Key(1)',            'R', c10,
          'Key(1)',            'R', c11,
          'Factor(1)',         'R', c12,
          'Stats(1)',          'R', c13,
          'Part',              'R', c14,
          'Temp',              'R', c15 )||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),     'R', c1,
          SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9 - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
          SUBSTR(DASHES, 1, c11 - 1), 'R', c11,
          SUBSTR(DASHES, 1, c12 - 1), 'R', c12,
          SUBSTR(DASHES, 1, c13 - 1), 'R', c13,
          SUBSTR(DASHES, 1, c14 - 1), 'R', c14,
          SUBSTR(DASHES, 1, c15 - 1), 'R', c15 ));

          FOR i IN (SELECT *
                      FROM trca$_group_indexes_v
                     WHERE tool_execution_id = p_tool_execution_id
                       AND group_id          = p_group_id
                     ORDER BY
                           table_owner,
                           table_name,
                           owner,
                           index_name)
          LOOP
            l_row := l_row + 1;
            printf(title_and_value(cols,
            l_row||':',                      'R', c1,
            ' '||i.table_owner||'.'||i.table_name, 'L', c2,
            ' '||i.owner||'.'||i.index_name, 'L', c3,
            i.num_rows,                      'R', c4,
            i.sample_size,                   'R', c5,
            ' '||TO_CHAR(i.last_analyzed, LONG_DATE_FORMAT), 'L', c6,
            i.distinct_keys,                 'R', c7,
            i.blevel,                        'R', c8,
            i.leaf_blocks,                   'R', c9,
            i.avg_leaf_blocks_per_key,       'R', c10,
            i.avg_data_blocks_per_key,       'R', c11,
            i.clustering_factor,             'R', c12,
            i.global_stats,                  'R', c13,
            i.partitioned,                   'R', c14,
            i.temporary,                     'R', c15 ));
          END LOOP;

          printf(LF||
          '(1) CBO statistics.');
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display sql indexes2: '||SQLERRM);
        END;
      END IF; -- incl_indexes (2)

      -- indexed columns
      IF incl_indexes THEN
        DECLARE
          l_row INTEGER := 0;
          cols INTEGER := 12;
          c1   INTEGER := 2;
          c2   INTEGER := 18;
          c3   INTEGER := 5;
          c4   INTEGER := 13;
          c5   INTEGER := 6;
          c6   INTEGER := 9;
          c7   INTEGER := 9;
          c8   INTEGER := 18;
          c9   INTEGER := 10;
          c10  INTEGER := 13;
          c11  INTEGER := 11;
          c12  INTEGER := 12;

        BEGIN
          SELECT GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
                 GREATEST(NVL(MAX(LENGTH(owner||'.'||index_name)), 0) + GAP, c2),
                 GREATEST(NVL(MAX(LENGTH(column_position)), 0) + GAP, c3),
                 GREATEST(NVL(MAX(LENGTH(column_name)), 0) + GAP, c4),
                 GREATEST(NVL(MAX(LENGTH(descend)), 0) + GAP, c5),
                 GREATEST(NVL(MAX(LENGTH(num_rows)), 0) + GAP, c6),
                 GREATEST(NVL(MAX(LENGTH(sample_size)), 0) + GAP, c7),
                 GREATEST(NVL(MAX(LENGTH(TO_CHAR(last_analyzed, LONG_DATE_FORMAT))), 0) + GAP, c8),
                 GREATEST(NVL(MAX(LENGTH(num_nulls)), 0) + GAP, c9),
                 GREATEST(NVL(MAX(LENGTH(num_distinct)), 0) + GAP, c10),
                 GREATEST(NVL(MAX(LENGTH(LOWER(TO_CHAR(density, '0.0000EEEE')))), 0) + GAP, c11),
                 GREATEST(NVL(MAX(LENGTH(num_buckets)), 0) + GAP, c12)
            INTO c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12
            FROM trca$_ind_columns_v
           WHERE tool_execution_id = p_tool_execution_id
             AND group_id          = p_group_id;

          printf(LF||
          title_and_value(cols,
          NULL,     'R', c1,
          NULL,     'R', c2,
          'Col',    'R', c3,
          NULL,     'R', c4,
          'Asc/',   'R', c5,
          'Num',    'R', c6,
          'Sample', 'R', c7,
          NULL,     'R', c8,
          'Num',    'R', c9,
          'Num',    'R', c10,
          NULL,     'R', c11,
          'Num',    'R', c12 )||LF||
          title_and_value(cols,
          '# ',     'R', c1,
          'Owner.Index Name ', 'C', c2,
          'Pos',               'R', c3,
          'Column Name ',      'C', c4,
          'Desc',              'R', c5,
          'Rows(1)',           'R', c6,
          'Size(1)',           'R', c7,
          'Last Analyzed(1) ', 'C', c8,
          'Nulls(1)',          'R', c9,
          'Distinct(1)',       'R', c10,
          'Density(1)',        'R', c11,
          'Buckets(1)',        'R', c12 )||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),     'R', c1,
          SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9 - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
          SUBSTR(DASHES, 1, c11 - 1), 'R', c11,
          SUBSTR(DASHES, 1, c12 - 1), 'R', c12 ));

          FOR i IN (SELECT *
                      FROM trca$_ind_columns_v
                     WHERE tool_execution_id = p_tool_execution_id
                       AND group_id          = p_group_id
                     ORDER BY
                           owner,
                           index_name,
                           column_position)
          LOOP
            l_row := l_row + 1;
            printf(title_and_value(cols,
            l_row||':',                      'R', c1,
            ' '||i.owner||'.'||i.index_name, 'L', c2,
            i.column_position,               'R', c3,
            ' '||i.column_name,              'L', c4,
            i.descend,                       'R', c5,
            i.num_rows,                      'R', c6,
            i.sample_size,                   'R', c7,
            ' '||TO_CHAR(i.last_analyzed, LONG_DATE_FORMAT), 'L', c8,
            i.num_nulls,                     'R', c9,
            i.num_distinct,                  'R', c10,
            LOWER(TO_CHAR(i.density, '0.0000EEEE')), 'R', c11,
            i.num_buckets,                   'R', c12 ));
          END LOOP;

          printf(LF||
          '(1) CBO statistics.');
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display sql indexed columns: '||SQLERRM);
        END;
      END IF; -- incl_indexes (3)
    END IF; -- incl_tables OR incl_indexes

    /* -------------------------
     * Recursive SQL - Time and Totals
     * ------------------------- */
    IF incl_progeny_time_totals THEN
      printf(LF||LF||
      'RECURSIVE SQL - TIME AND TOTALS'||LF||
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');

      -- time
      DECLARE
        cols INTEGER := 7;
        c1   INTEGER := 8;
        c2   INTEGER := 15;
        c3   INTEGER := 9;
        c4   INTEGER := 10;
        c5   INTEGER := 11;
        c6   INTEGER := 17;
        c7   INTEGER := 11;
      BEGIN
        SELECT GREATEST(NVL(MAX(LENGTH(accounted_response)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(elapsed)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(cpu)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(elapsed_unaccounted_for)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c7)
          INTO c2, c3, c4, c5, c6, c7
          FROM trca$_sql_recu_time_vf
         WHERE group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id;

        printf(LF||
        title_and_value(cols,
        NULL,             'R', c1,
        'Response Time',  'R', c2,
        'Elapsed',        'R', c3,
        NULL,             'R', c4,
        'Non-Idle',       'R', c5,
        'Elapsed Time',   'R', c6,
        'Idle',           'R', c7 )||LF||
        title_and_value(cols,
        'Call ',           'R', c1,
        'Accounted-for',   'R', c2,
        'Time',            'R', c3,
        'CPU Time',        'R', c4,
        'Wait Time',       'R', c5,
        'Unaccounted-for', 'R', c6,
        'Wait Time',       'R', c7 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),     'R', c1,
        SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7 - 1), 'R', c7 ));

        FOR i IN (SELECT *
                    FROM trca$_sql_recu_time_vf
                   WHERE group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          IF i.call = trca$g.CALL_TOTAL THEN
            printf(title_and_value(cols,
            SUBSTR(DASHES, 1, c1),     'R', c1,
            SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
            SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
            SUBSTR(DASHES, 1, c7 - 1), 'R', c7 ));
          END IF;

          printf(title_and_value(cols,
          i.call_type||':',           'R', c1,
          i.accounted_response,       'R', c2,
          i.elapsed,                  'R', c3,
          i.cpu,                      'R', c4,
          i.non_idle_wait,            'R', c5,
          i.elapsed_unaccounted_for,  'R', c6,
          i.idle_wait,                'R', c7 ));
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql recu time: '||SQLERRM);
      END;

      -- totals
      DECLARE
        cols INTEGER := 9;
        c1   INTEGER := 8;
        c2   INTEGER := 7;
        c3   INTEGER := 13;
        c4   INTEGER := 15;
        c5   INTEGER := 12;
        c6   INTEGER := 13;
        c7   INTEGER := 9;
        c8   INTEGER := 10;
        c9   INTEGER := 8;
      BEGIN
        SELECT GREATEST(NVL(MAX(LENGTH(call_count)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(p_disk_os)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(cr_query_consistent)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(cu_current)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(r_rows)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(mis_library_cache_misses)), 0) + GAP, c7),
               GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c8),
               GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c9)
          INTO c2, c3, c4, c5, c6, c7, c8, c9
          FROM trca$_sql_recu_total_v
         WHERE group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id;

        printf(LF||
        title_and_value(cols,
        NULL,            'R', c1,
        NULL,            'R', c2,
        'OS',            'R', c3,
        'BG Consistent', 'R', c4,
        'BG Current',    'R', c5,
        'Rows',          'R', c6,
        'Library',       'R', c7,
        'Times',         'R', c8,
        'Times',         'R', c9 )||LF||
        title_and_value(cols,
        NULL,          'R', c1,
        'Call',        'R', c2,
        'Buffer Gets', 'R', c3,
        'Read Mode',   'R', c4,
        'Mode',        'R', c5,
        'Processed',   'R', c6,
        'Cache',       'R', c7,
        'Waited',      'R', c8,
        'Waited',      'R', c9 )||LF||
        title_and_value(cols,
        'Call ',       'R', c1,
        'Count',       'R', c2,
        '(disk)',      'R', c3,
        '(query)',     'R', c4,
        '(current)',   'R', c5,
        'or Returned', 'R', c6,
        'Misses',      'R', c7,
        'Non-Idle',    'R', c8,
        'Idle',        'R', c9 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),     'R', c1,
        SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
        SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
        SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));

        FOR i IN (SELECT *
                    FROM trca$_sql_recu_total_v
                   WHERE group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          IF i.call = trca$g.CALL_TOTAL THEN
            printf(title_and_value(cols,
            SUBSTR(DASHES, 1, c1),     'R', c1,
            SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
            SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
            SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
            SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
            SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));
          END IF;

          printf(title_and_value(cols,
          i.call_type||':',           'R', c1,
          i.call_count,               'R', c2,
          i.p_disk_os,                'R', c3,
          i.cr_query_consistent,      'R', c4,
          i.cu_current,               'R', c5,
          i.r_rows,                   'R', c6,
          i.mis_library_cache_misses, 'R', c7,
          i.wait_count_non_idle,      'R', c8,
          i.wait_count_idle,          'R', c9 ));
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql recu totals: '||SQLERRM);
      END;
    END IF; -- incl_progeny_time_totals

    /* -------------------------
     * Segment I/O Wait Summary
     * ------------------------- */
    IF incl_segment_io_summary THEN
      BEGIN
        printf(LF||LF||
        'SEGMENT I/O WAIT SUMMARY'||LF||
        '~~~~~~~~~~~~~~~~~~~~~~~~');

        DECLARE
          l_row INTEGER := 0;
          cols INTEGER := 11;
          c1   INTEGER := 2;
          c2   INTEGER := 5;
          c3   INTEGER := 6;
          c4   INTEGER := 17;
          c5   INTEGER := 12;
          c6   INTEGER := 9;
          c7   INTEGER := 8;
          c8   INTEGER := 11;
          c9   INTEGER := 11;
          c10  INTEGER := 8;
          c11  INTEGER := 9;
        BEGIN
          SELECT GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
                 GREATEST(NVL(MAX(LENGTH(obj#)), 0) + GAP, c2),
                 GREATEST(NVL(MAX(LENGTH(segment_type)), 0) + GAP, c3),
                 GREATEST(NVL(MAX(LENGTH(segment_name)), 0) + GAP, c4),
                 GREATEST(NVL(MAX(LENGTH(event_name)), 0) + GAP, c5),
                 GREATEST(NVL(MAX(LENGTH(wait_time)), 0) + GAP, c6),
                 GREATEST(NVL(MAX(LENGTH(times_waited)), 0) + GAP, c7),
                 GREATEST(NVL(MAX(LENGTH(avg_wait_time)), 0) + GAP, c8),
                 GREATEST(NVL(MAX(LENGTH(max_wait_time)), 0) + GAP, c9),
                 GREATEST(NVL(MAX(LENGTH(blocks)), 0) + GAP, c10),
                 GREATEST(NVL(MAX(LENGTH(avg_blocks)), 0) + GAP, c11)
            INTO c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11
            FROM trca$_sql_wait_segment_vf
           WHERE group_id          = p_group_id
             AND tool_execution_id = p_tool_execution_id;

          printf(LF||
          title_and_value(cols,
          NULL,      'R', c1,
          NULL,      'R', c2,
          NULL,      'R', c3,
          NULL,      'R', c4,
          NULL,      'R', c5,
          'Wait',    'R', c6,
          'Times',   'R', c7,
          'Average', 'R', c8,
          'Max',     'R', c9,
          NULL,      'R', c10,
          'Average', 'R', c11 )||LF||
          title_and_value(cols,
          '# ',               'R', c1,
          'Obj',              'R', c2,
          'Type ',            'C', c3,
          'Segment Name(1) ', 'C', c4,
          'Event Name ',      'C', c5,
          'Time(2)',          'R', c6,
          'Waited',           'R', c7,
          'Wait Time',        'R', c8,
          'Wait Time',        'R', c9,
          'Blocks',           'R', c10,
          'Blocks',           'R', c11 )||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),      'R', c1,
          SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
          SUBSTR(DASHES, 1, c11 - 1), 'R', c11 ));

          FOR i IN (SELECT *
                      FROM trca$_sql_wait_segment_vf
                     WHERE group_id          = p_group_id
                       AND tool_execution_id = p_tool_execution_id
                     ORDER BY
                           wait DESC,
                           times_waited DESC,
                           blocks DESC)
          LOOP
            l_row := l_row + 1;
            printf(title_and_value(cols,
            l_row||':',          'R', c1,
            i.obj#,              'R', c2,
            ' '||i.segment_type, 'L', c3,
            ' '||i.segment_name, 'L', c4,
            ' '||i.event_name,   'L', c5,
            i.wait_time,         'R', c6,
            i.times_waited,      'R', c7,
            i.avg_wait_time,     'R', c8,
            i.max_wait_time,     'R', c9,
            i.blocks,            'R', c10,
            i.avg_blocks,        'R', c11 ));
          END LOOP;

          printf(LF||
          '(1) Content based on '||trca$g.g_tool_name||' data dictionary (dbid:'||trca$g.g_dict_database_id||', host:'||trca$g.g_dict_host_name||').'||LF||
          '(2) This list is constrained by threshold configuration parameter with current value of '||trca$g.g_wait_time_th||'s.');
        END;

        -- summary by start time
        DECLARE
          l_row INTEGER := 0;
          cols INTEGER := 11;
          c1   INTEGER := 2;
          c2   INTEGER := 5;
          c3   INTEGER := 6;
          c4   INTEGER := 17;
          c5   INTEGER := 17;
          c6   INTEGER := 15;
          c7   INTEGER := 10;
          c8   INTEGER := 9;
          c9   INTEGER := 8;
        BEGIN
          IF incl_segment_io_summary2 THEN
            SELECT GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
                   GREATEST(NVL(MAX(LENGTH(obj#)), 0) + GAP, c2),
                   GREATEST(NVL(MAX(LENGTH(segment_type)), 0) + GAP, c3),
                   GREATEST(NVL(MAX(LENGTH(segment_name)), 0) + GAP, c4),
                   GREATEST(NVL(MAX(LENGTH(start_timestamp)), 0) + GAP, c5),
                   GREATEST(NVL(MAX(LENGTH(end_timestamp)), 0) + GAP, c6),
                   GREATEST(NVL(MAX(LENGTH(response_time)), 0) + GAP, c7),
                   GREATEST(NVL(MAX(LENGTH(wait_time)), 0) + GAP, c8),
                   GREATEST(NVL(MAX(LENGTH(blocks)), 0) + GAP, c9)
              INTO c1, c2, c3, c4, c5, c6, c7, c8, c9
              FROM trca$_sql_wait_seg_cons_vf
             WHERE group_id          = p_group_id
               AND tool_execution_id = p_tool_execution_id;

            printf(LF||
            title_and_value(cols,
            NULL,      'R', c1,
            NULL,      'R', c2,
            NULL,      'R', c3,
            NULL,      'R', c4,
            NULL,      'R', c5,
            NULL,    'R', c6,
            'Response',   'R', c7,
            'Wait', 'R', c8,
            NULL,     'R', c9 )||LF||
            title_and_value(cols,
            '# ',               'R', c1,
            'Obj',              'R', c2,
            'Type ',            'C', c3,
            'Segment Name(1) ', 'C', c4,
            'Start Timestamp ', 'C', c5,
            'End Timestamp ',   'C', c6,
            'Time(2)',          'R', c7,
            'Time(3)',          'R', c8,
            'Blocks',           'R', c9 )||LF||
            title_and_value(cols,
            SUBSTR(DASHES, 1, c1),      'R', c1,
            SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
            SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
            SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
            SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
            SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
            SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
            SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
            SUBSTR(DASHES, 1, c9  - 1), 'R', c9 ));

            FOR i IN (SELECT *
                        FROM trca$_sql_wait_seg_cons_vf
                       WHERE group_id          = p_group_id
                         AND tool_execution_id = p_tool_execution_id
                       ORDER BY
                             start_tim,
                             response)
            LOOP
              l_row := l_row + 1;
              printf(title_and_value(cols,
              l_row||':',             'R', c1,
              i.obj#,                 'R', c2,
              ' '||i.segment_type,    'L', c3,
              ' '||i.segment_name,    'L', c4,
              ' '||i.start_timestamp, 'L', c5,
              ' '||i.end_timestamp,   'L', c6,
              i.response_time,        'R', c7,
              i.wait_time,            'R', c8,
              i.blocks,               'R', c9 ));
            END LOOP;

            printf(LF||
            '(1) Content based on '||trca$g.g_tool_name||' data dictionary (dbid:'||trca$g.g_dict_database_id||', host:'||trca$g.g_dict_host_name||').'||LF||
            '(2) According to timestamps of first and last wait in this segment.'||LF||
            '(3) This list is constrained by threshold configuration parameter with current value of '||trca$g.g_wait_time_th||'s.');
          END IF; -- incl_segment_io_summary2
        END;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql self segment i/o waits: '||SQLERRM);
      END;
    END IF; -- incl_segment_io_summary

    /* -------------------------
     * Relevant Executions
     * ------------------------- */
    IF incl_relevant_exec THEN

      DECLARE
        l_exec_count INTEGER;
        l_top_exec_count INTEGER;
        l_grp_contribution NUMBER;
        l_trc_contribution NUMBER;
        l_top_grp_contribution NUMBER;
        l_top_trc_contribution NUMBER;
        l_txt_grp_contribution VARCHAR2(32767);
        l_txt_trc_contribution VARCHAR2(32767);
        cols INTEGER := 13;
        c1   INTEGER := 7;
        c2   INTEGER := 6;
        c3   INTEGER := 8;
        c4   INTEGER := 8;
        c5   INTEGER := 10;
        c6   INTEGER := 9;
        c7   INTEGER := 10;
        c8   INTEGER := 11;
        c9   INTEGER := 11;
        c10  INTEGER := 11;
        c11  INTEGER := 17;
        c12  INTEGER := 15;
        c13  INTEGER := 10;

      BEGIN
        SELECT GREATEST(NVL(MAX(LENGTH(first_last)), 0) + GAP, c1),
               GREATEST(NVL(MAX(LENGTH(rank)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(grp_contribution)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(trc_contribution)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(response_time_self)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(elapsed)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(cpu)), 0) + GAP, c7),
               GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c8),
               GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c9),
               GREATEST(NVL(MAX(LENGTH(response_time_progeny)), 0) + GAP, c10),
               GREATEST(NVL(MAX(LENGTH(start_timestamp)), 0) + GAP, c11),
               GREATEST(NVL(MAX(LENGTH(end_timestamp)), 0) + GAP, c12),
               GREATEST(NVL(MAX(LENGTH(response_time)), 0) + GAP, c13)
          INTO c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13
          FROM trca$_exec_vf
         WHERE group_id          = p_group_id
           AND tool_execution_id = p_tool_execution_id;

        SELECT NVL(COUNT(*), 0),
               NVL(SUM(CASE WHEN top_exec = 'Y' THEN 1 END), 0),
               NVL(SUM(grp_contribution), 0),
               NVL(SUM(trc_contribution), 0),
               NVL(SUM(CASE WHEN grp_rec.top_sql = 'Y' AND top_exec = 'Y' THEN grp_contribution END), 0),
               NVL(SUM(CASE WHEN grp_rec.top_sql = 'Y' AND top_exec = 'Y' THEN trc_contribution END), 0)
          INTO l_exec_count,
               l_top_exec_count,
               l_grp_contribution,
               l_trc_contribution,
               l_top_grp_contribution,
               l_top_trc_contribution
          FROM trca$_exec
         WHERE tool_execution_id = p_tool_execution_id
           AND group_id          = p_group_id;

        printf(LF||LF||
        'RELEVANT EXECUTIONS'||LF||
        '~~~~~~~~~~~~~~~~~~~'||LF);

        printf('There are '||l_exec_count||' relevant executions of this SQL statement.'||LF||
               'Their aggregate "Response Time Accounted-for" represents '||trca$g.format_perc1(100 * l_grp_contribution)||' of this "SQL Response Time Accounted-for", and '||trca$g.format_perc1(100 * l_trc_contribution)||' of the "Total Response Time Accounted-for".');

        IF (grp_rec.top_sql = 'Y' OR grp_rec.top_sql_et = 'Y' OR grp_rec.top_sql_ct = 'Y') AND l_exec_count > 1 THEN
          IF l_top_exec_count = 0 THEN
           printf('Within these '||l_exec_count||' SQL execuctions, there isn''t any with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_exec_th))||' of the "SQL Response Time Accounted-for".');
          ELSIF l_top_exec_count = 1 THEN
            printf('Within these '||l_exec_count||' SQL execuctions, there is only one with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_exec_th))||' of the "SQL Response Time Accounted-for".');
          ELSE
            printf('Within these '||l_exec_count||' SQL execuctions, there are '||l_top_exec_count||' with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_exec_th))||' of the "SQL Response Time Accounted-for".'||LF||
            'These combined top '||l_top_exec_count||' executions of this SQL are responsible for a total of '||trca$g.format_perc1(100 * l_top_grp_contribution)||' of the "SQL Response Time Accounted-for", and for a total of '||trca$g.format_perc1(100 * l_top_trc_contribution)||' of the "Total Response Time Accounted-for".');
          END IF;
        END IF;

        printf(LF||
        title_and_value(cols,
        NULL,        'R', c1,
        NULL,        'R', c2,
        'SQL',       'R', c3,
        'Trace',     'R', c4,
        'Self',      'R', c5,
        NULL,        'R', c6,
        NULL,        'R', c7,
        NULL,        'R', c8,
        NULL,        'R', c9,
        'Recursive', 'R', c10,
        NULL,        'R', c11,
        NULL,        'R', c12,
        NULL,        'R', c13 )||LF||
        title_and_value(cols,
        'First/',   'R', c1,
        NULL,       'R', c2,
        'RT',       'R', c3,
        'RT',       'R', c4,
        'Response', 'R', c5,
        'Elapsed',  'R', c6,
        NULL,       'R', c7,
        'Non-Idle', 'R', c8,
        'Idle',     'R', c9,
        'Response', 'R', c10,
        NULL,       'R', c11,
        NULL,       'R', c12,
        'Response', 'R', c13 )||LF||
        title_and_value(cols,
        'Last ',            'R', c1,
        'Rank',             'R', c2,
        'Pct(1)',           'R', c3,
        'Pct(2)',           'R', c4,
        'Time(3)',          'R', c5,
        'Time',             'R', c6,
        'CPU Time',         'R', c7,
        'Wait Time',        'R', c8,
        'Wait Time',        'R', c9,
        'Time(4)',          'R', c10,
        'Start Timestamp ', 'C', c11,
        'End Timestamp ',   'C', c12,
        'Time(5)',          'R', c13 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),      'R', c1,
        SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
        SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
        SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
        SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
        SUBSTR(DASHES, 1, c11 - 1), 'R', c11,
        SUBSTR(DASHES, 1, c12 - 1), 'R', c12,
        SUBSTR(DASHES, 1, c13 - 1), 'R', c13 ));

        FOR i IN (SELECT *
                    FROM trca$_exec_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND group_id          = p_group_id
                   ORDER BY
                         exec_id)
        LOOP
          printf(title_and_value(cols,
          i.first_last||':',       'R', c1,
          i.rank,                  'R', c2,
          i.grp_contribution,      'R', c3,
          i.trc_contribution,      'R', c4,
          i.response_time_self,    'R', c5,
          i.elapsed,               'R', c6,
          i.cpu,                   'R', c7,
          i.non_idle_wait,         'R', c8,
          i.idle_wait,             'R', c9,
          i.response_time_progeny, 'R', c10,
          ' '||i.start_timestamp,  'L', c11,
          ' '||i.end_timestamp,    'L', c12,
          i.response_time,         'R', c13 ));
        END LOOP;

        printf(LF||
        '(1) Percent of "SQL Response Time Accounted-for", which is '||sql_vf.response_time_self||' secs.'||LF||
        '(2) Percent of "Total Response Time Accounted-for", which is '||rtf_rec.accounted_for_response_time||' secs.'||LF||
        '(3) "Self Response Time Accounted-for" in secs (caused by this execution).'||LF||
        '(4) "Recursive Response Time Accounted-for" in secs (caused by recursive SQL invoked by this execution).'||LF||
        '(5) According to timestamps of first and last calls for this execution.');

        FOR i IN (SELECT exec_id
                    FROM trca$_exec_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND group_id          = p_group_id
                   ORDER BY
                         exec_id)
        LOOP
          gen_html_exec (
            p_tool_execution_id => p_tool_execution_id,
            p_group_id          => p_group_id,
            p_exec_id           => i.exec_id );
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display exec sql: '||SQLERRM);
      END;
    END IF; -- incl_relevant_exec

    printf(LF||SEPARATOR||LF);
  EXCEPTION
    WHEN OTHERS THEN
      print_log('*** cannot generate html for group '||p_group_id||' '||SQLERRM);
  END gen_html_group;

  /*************************************************************************************/

  /* -------------------------
   *
   * public gen_text_report
   *
   * called by trca$i.trcanlzr
   *
   * ------------------------- */
  PROCEDURE gen_text_report (
    p_tool_execution_id   IN  INTEGER,
    p_file_name           IN  VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN  VARCHAR2 DEFAULT NULL,
    x_text_report         OUT CLOB )
  IS
    l_file_name VARCHAR2(32767);
    l_directory_alias VARCHAR2(32767);
    l_directory_path VARCHAR2(32767);
    l_file_block_size INTEGER;
    l_file_exists BOOLEAN;
    l_file_length INTEGER := 0;
    l_phase VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);

    tool_rec trca$_tool_execution%ROWTYPE;
    rt_rec trca$_response_time_summary_v%ROWTYPE;
    rtf_rec trca$_response_time_summary_vf%ROWTYPE;

  /*************************************************************************************/

  BEGIN /* gen_text_report */
    IF NOT trca$g.g_log_open THEN
      RETURN;
    END IF;
    l_phase := 'initialization';

    print_log('=> gen_text_report');

    SELECT * INTO tool_rec FROM trca$_tool_execution           WHERE id = p_tool_execution_id;
    SELECT * INTO rt_rec   FROM trca$_response_time_summary_v  WHERE tool_execution_id = p_tool_execution_id;
    SELECT * INTO rtf_rec  FROM trca$_response_time_summary_vf WHERE tool_execution_id = p_tool_execution_id;

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_name LIKE '%.%' THEN
      l_file_name := p_file_name;
    ELSE
      l_file_name := p_file_name||'trca_e'||p_tool_execution_id||l_out_file_identifier||'.txt';
    END IF;

    UPDATE trca$_tool_execution
       SET text_file_name = l_file_name
     WHERE id = p_tool_execution_id;
    COMMIT;

    s_file_rec := NULL;
    s_file_rec.tool_execution_id := p_tool_execution_id;
    s_file_rec.file_type := 'TEXT';
    s_file_rec.filename := l_file_name;
    s_file_rec.file_date := SYSDATE;
    s_file_rec.username := USER;
    s_file_rec.file_text := '224270.1 TRCA '||trca$g.g_tool_name||' '||trca$g.g_tool_version||' Report: '||l_file_name;

    /* -------------------------
     * Do not generate
     * ------------------------- */
    IF trca$g.g_gen_text_report = 'N' THEN
      printf('To enable: SQL> EXEC '||LOWER(trca$g.g_tool_administer_schema)||'.trca$g.set_param(''gen_text_report'', ''Y'');');
      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      INSERT INTO trca$_file VALUES s_file_rec;
      COMMIT;
      print_log('<= gen_text_report');
      RETURN;
    END IF;

    /* -------------------------
     * Title
     * ------------------------- */
    l_phase := 'title';

    BEGIN
      FOR i IN (SELECT *
                  FROM trca$_trace
                 WHERE tool_execution_id = p_tool_execution_id)
      LOOP
        printf(i.file_name||' ('||i.file_len||' bytes)');
      END LOOP;
      --'Directory: '||tool_rec.directory_path||LF||
      printf('Total Trace Response Time: '||rtf_rec.total_response_time||' secs.'||LF||
      rtf_rec.start_timestamp||' (start of first db call in trace '||(rtf_rec.start_tim / 1e6)||').'||LF||
      rtf_rec.end_timestamp||' (end of last db call in trace '||(rtf_rec.end_tim / 1e6)||').');
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display title: '||SQLERRM);
    END;

    /***********************************************************************************/

    /* -------------------------
     * Response Time Summary
     * ------------------------- */
    l_phase := 'response_summary';
    print_log('-> '||l_phase);

    DECLARE
      cols INTEGER := 7;
      c1   INTEGER := 24;
      c2   INTEGER := 12;
      c3   INTEGER := 12;
      c4   INTEGER := 12;
      c5   INTEGER := 12;
      c6   INTEGER := 12;
      c7   INTEGER := 12;
    BEGIN
      printf(SEPARATOR||LF||LF||
      'RESPONSE TIME SUMMARY'||LF||
      '~~~~~~~~~~~~~~~~~~~~~'||LF||
      title_and_value(cols,
      NULL,     'R', c1,
      NULL,     'R', c2,
      'pct of', 'R', c3,
      NULL,     'R', c4,
      'pct of', 'R', c5,
      NULL,     'R', c6,
      'pct of', 'R', c7 )||LF||
      title_and_value(cols,
      NULL,    'R', c1,
      'Time',  'R', c2,
      'total', 'R', c3,
      'Time',  'R', c4,
      'total', 'R', c5,
      'Time',  'R', c6,
      'total', 'R', c7 )||LF||
      title_and_value(cols,
      'Response Time Component ', 'R', c1,
      '(in secs)',                'R', c2,
      'resp time',                'R', c3,
      '(in secs)',                'R', c4,
      'resp time',                'R', c5,
      '(in secs)',                'R', c6,
      'resp time',                'R', c7 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),     'R', c1,
      SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
      SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
      SUBSTR(DASHES, 1, c7 - 1), 'R', c7 )||LF||
      title_and_value(cols,
      'CPU:',           'R', c1,
      rtf_rec.cpu,      'R', c2,
      rtf_rec.cpu_perc, 'R', c3 )||LF||
      title_and_value(cols,
      'Non-idle Wait:',           'R', c1,
      rtf_rec.non_idle_wait,      'R', c2,
      rtf_rec.non_idle_wait_perc, 'R', c3 )||LF||
      title_and_value(cols,
      'ET Unaccounted-for:',                'R', c1,
      rtf_rec.elapsed_unaccounted_for,      'R', c2,
      rtf_rec.elapsed_unaccounted_for_perc, 'R', c3 )||LF||
      title_and_value(cols,
      'Total Elapsed(1):',  'R', c1,
      ' ',                  'R', c2,
      ' ',                  'R', c3,
      rtf_rec.elapsed,      'R', c4,
      rtf_rec.elapsed_perc, 'R', c5 )||LF||
      title_and_value(cols,
      'Idle Wait:',           'R', c1,
      ' ',                    'R', c2,
      ' ',                    'R', c3,
      rtf_rec.idle_wait,      'R', c4,
      rtf_rec.idle_wait_perc, 'R', c5 )||LF||
      title_and_value(cols,
      'RT Unaccounted-for:',                 'R', c1,
      ' ',                                   'R', c2,
      ' ',                                   'R', c3,
      rtf_rec.response_unaccounted_for,      'R', c4,
      rtf_rec.response_unaccounted_for_perc, 'R', c5 )||LF||
      title_and_value(cols,
      'Total Response(2):',             'R', c1,
      ' ',                              'R', c2,
      ' ',                              'R', c3,
      ' ',                              'R', c4,
      ' ',                              'R', c5,
      rtf_rec.total_response_time,      'R', c6,
      rtf_rec.total_response_time_perc, 'R', c7 ));

      printf(LF||
      '(1) Total Elapsed = "CPU" + "Non-Idle Wait" + "ET Unaccounted-for".'||LF||
      '(2) Total Response = "Total Elapsed Time" + "Idle Wait" + "RT Unaccounted-for".'||LF||
      'Total Accounted-for = "CPU" + "Non-Idle Wait" + "Idle Wait" = '||rtf_rec.accounted_for_response_time||' secs.'||LF||
      'Total Unccounted-for = "ET Unaccounted-for" + "RT Unaccounted-for" = '||rtf_rec.total_unaccounted_for||' secs.');

      print_log('<- '||l_phase);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display response time: '||SQLERRM);
    END;

    /***********************************************************************************/

    /* -------------------------
     * Overall Time and Totals
     * ------------------------- */
    l_phase := 'overall_totals';
    print_log('-> '||l_phase);

    -- time
    DECLARE
      cols INTEGER := 9;
      c1   INTEGER := 8;
      c2   INTEGER := 16;
      c3   INTEGER := 18;
      c4   INTEGER := 9;
      c5   INTEGER := 10;
      c6   INTEGER := 11;
      c7   INTEGER := 17;
      c8   INTEGER := 11;
      c9   INTEGER := 17;
    BEGIN
      SELECT GREATEST(NVL(MAX(LENGTH(response)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(accounted_response)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(elapsed)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(cpu)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(elapsed_unaccounted_for)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c8),
             GREATEST(NVL(MAX(LENGTH(response_unaccounted_for)), 0) + GAP, c9)
        INTO c2, c3, c4, c5, c6, c7, c8, c9
        FROM trca$_trc_overall_time_vf
       WHERE tool_execution_id = p_tool_execution_id;

      printf(LF||LF||
      'OVERALL TIME AND TOTALS (NON-RECURSIVE AND RECURSIVE)'||LF||
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'||LF||LF||
      title_and_value(cols,
      NULL,             'R', c1,
      'Total Response', 'R', c2,
      'Response Time',  'R', c3,
      'Elapsed',        'R', c4,
      NULL,             'R', c5,
      'Non-Idle',       'R', c6,
      'Elapsed Time',   'R', c7,
      'Idle',           'R', c8,
      'Response Time',  'R', c9 )||LF||
      title_and_value(cols,
      'Call ',            'R', c1,
      'Time(3)',          'R', c2,
      'Accounted-for(2)', 'R', c3,
      'Time(1)',          'R', c4,
      'CPU Time',         'R', c5,
      'Wait Time',        'R', c6,
      'Unaccounted-for',  'R', c7,
      'Wait Time',        'R', c8,
      'Unaccounted-for',  'R', c9 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),     'R', c1,
      SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
      SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
      SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
      SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
      SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));

      FOR i IN (SELECT *
                  FROM trca$_trc_overall_time_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        IF i.call = trca$g.CALL_TOTAL THEN
          printf(title_and_value(cols,
          SUBSTR(DASHES, 1, c1),     'R', c1,
          SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));
        END IF;

        printf(title_and_value(cols,
        i.call_type||':',           'R', c1,
        i.response,                 'R', c2,
        i.accounted_response,       'R', c3,
        i.elapsed,                  'R', c4,
        i.cpu,                      'R', c5,
        i.non_idle_wait,            'R', c6,
        i.elapsed_unaccounted_for,  'R', c7,
        i.idle_wait,                'R', c8,
        i.response_unaccounted_for, 'R', c9 ));
      END LOOP;

      printf(LF||
      '(1) Elapsed Time = "CPU Time" + "Non-Idle Wait Time" + "Elapsed Time Unaccounted-for".'||LF||
      '(2) Response Time Accounted-for = "Elapsed Time" + "Idle Wait Time".'||LF||
      '(3) Total Response Time = "Response Time Accounted-for" + "Response Time Unaccounted-for".');
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display overall time: '||SQLERRM);
    END;

    -- totals
    DECLARE
      cols INTEGER := 9;
      c1   INTEGER := 8;
      c2   INTEGER := 7;
      c3   INTEGER := 13;
      c4   INTEGER := 15;
      c5   INTEGER := 12;
      c6   INTEGER := 13;
      c7   INTEGER := 9;
      c8   INTEGER := 10;
      c9   INTEGER := 8;
    BEGIN
      SELECT GREATEST(NVL(MAX(LENGTH(call_count)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(p_disk_os)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(cr_query_consistent)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(cu_current)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(r_rows)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(mis_library_cache_misses)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c8),
             GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c9)
        INTO c2, c3, c4, c5, c6, c7, c8, c9
        FROM trca$_trc_overall_total_v
       WHERE tool_execution_id = p_tool_execution_id;

      printf(LF||
      title_and_value(cols,
      NULL,            'R', c1,
      NULL,            'R', c2,
      'OS',            'R', c3,
      'BG Consistent', 'R', c4,
      'BG Current',    'R', c5,
      'Rows',          'R', c6,
      'Library',       'R', c7,
      'Times',         'R', c8,
      'Times',         'R', c9 )||LF||
      title_and_value(cols,
      NULL,          'R', c1,
      'Call',        'R', c2,
      'Buffer Gets', 'R', c3,
      'Read Mode',   'R', c4,
      'Mode',        'R', c5,
      'Processed',   'R', c6,
      'Cache',       'R', c7,
      'Waited',      'R', c8,
      'Waited',      'R', c9 )||LF||
      title_and_value(cols,
      'Call ',       'R', c1,
      'Count',       'R', c2,
      '(disk)',      'R', c3,
      '(query)',     'R', c4,
      '(current)',   'R', c5,
      'or Returned', 'R', c6,
      'Misses',      'R', c7,
      'Non-Idle',    'R', c8,
      'Idle',        'R', c9 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),     'R', c1,
      SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
      SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
      SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
      SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
      SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));

      FOR i IN (SELECT *
                  FROM trca$_trc_overall_total_v
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        IF i.call = trca$g.CALL_TOTAL THEN
          printf(title_and_value(cols,
          SUBSTR(DASHES, 1, c1),     'R', c1,
          SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));
        END IF;

        printf(title_and_value(cols,
        i.call_type||':',           'R', c1,
        i.call_count,               'R', c2,
        i.p_disk_os,                'R', c3,
        i.cr_query_consistent,      'R', c4,
        i.cu_current,               'R', c5,
        i.r_rows,                   'R', c6,
        i.mis_library_cache_misses, 'R', c7,
        i.wait_count_non_idle,      'R', c8,
        i.wait_count_idle,          'R', c9 ));
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display overall totals: '||SQLERRM);
    END;

    -- waits
    IF trca$g.g_include_waits = 'Y' THEN
      DECLARE
        l_count INTEGER;
        cols INTEGER := 10;
        c1   INTEGER := 7;
        c2   INTEGER := 7;
        c3   INTEGER := 11;
        c4   INTEGER := 10;
        c5   INTEGER := 11;
        c6   INTEGER := 8;
        c7   INTEGER := 11;
        c8   INTEGER := 11;
        c9   INTEGER := 8;
        c10  INTEGER := 9;
      BEGIN
        SELECT COUNT(*),
               GREATEST(NVL(MAX(LENGTH(event_name)), 0) + GAP, c1),
               GREATEST(NVL(MAX(LENGTH(wait_class)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(avg_wait)), 0) + GAP, c7),
               GREATEST(NVL(MAX(LENGTH(max_wait)), 0) + GAP, c8),
               GREATEST(NVL(MAX(LENGTH(blocks)), 0) + GAP, c9),
               GREATEST(NVL(MAX(LENGTH(avg_blocks)), 0) + GAP, c10)
          INTO l_count, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10
          FROM trca$_trc_overall_wait_vf
         WHERE tool_execution_id = p_tool_execution_id;

        IF l_count > 0 THEN
          printf(LF||
          title_and_value(cols,
          NULL,    'R', c1,
          NULL,    'R', c2,
          NULL,    'R', c3,
          'Times', 'R', c4,
          NULL,    'R', c5,
          'Times', 'R', c6,
          NULL,    'R', c7,
          NULL,    'R', c8,
          NULL,    'R', c9,
          NULL,    'R', c10 )||LF||
          title_and_value(cols,
          'Event ',   'R', c1,
          ' Wait',    'L', c2,
          'Non-Idle', 'R', c3,
          'Waited',   'R', c4,
          'Idle',     'R', c5,
          'Waited',   'R', c6,
          'Average',  'R', c7,
          'Max',      'R', c8,
          NULL,       'R', c9,
          'Average',  'R', c10 )||LF||
          title_and_value(cols,
          'Name ',       'R', c1,
          ' Class',      'L', c2,
          'Wait Time',   'R', c3,
          'Non-Idle',    'R', c4,
          'Wait Time',   'R', c5,
          'Idle',        'R', c6,
          'Wait Time',   'R', c7,
          'Wait Time',   'R', c8,
          'Blocks',      'R', c9,
          'Blocks',      'R', c10)||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),      'R', c1,
          SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));

          FOR i IN (SELECT *
                      FROM trca$_trc_overall_wait_vf
                     WHERE tool_execution_id = p_tool_execution_id
                     ORDER BY
                           row_type,
                           wait DESC)
          LOOP
            IF i.row_type = 'T' THEN
              printf(title_and_value(cols,
              SUBSTR(DASHES, 1, c1),      'R', c1,
              SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
              SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
              SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
              SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
              SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
              SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
              SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
              SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
              SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));
            END IF;

            printf(title_and_value(cols,
            i.event_name||':',     'R', c1,
            ' '||i.wait_class,     'L', c2,
            i.non_idle_wait,       'R', c3,
            i.wait_count_non_idle, 'R', c4,
            i.idle_wait,           'R', c5,
            i.wait_count_idle,     'R', c6,
            i.avg_wait,            'R', c7,
            i.max_wait,            'R', c8,
            i.blocks,              'R', c9,
            i.avg_blocks,          'R', c10 ));
          END LOOP;
        END IF; -- l_count > 0
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display overall waits: '||SQLERRM);
      END;
    END IF; -- trca$g.g_include_waits = 'Y'

    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Non-Recursive Time and Totals
     * ------------------------- */
    l_phase := 'non-recursive_totals';
    print_log('-> '||l_phase);

    -- time
    DECLARE
      cols INTEGER := 7;
      c1   INTEGER := 8;
      c2   INTEGER := 15;
      c3   INTEGER := 9;
      c4   INTEGER := 10;
      c5   INTEGER := 11;
      c6   INTEGER := 17;
      c7   INTEGER := 11;
    BEGIN
      SELECT GREATEST(NVL(MAX(LENGTH(accounted_response)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(elapsed)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(cpu)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(elapsed_unaccounted_for)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c7)
        INTO c2, c3, c4, c5, c6, c7
        FROM trca$_trc_non_recu_time_vf
       WHERE tool_execution_id = p_tool_execution_id;

      printf(LF||LF||
      'NON-RECURSIVE TIME AND TOTALS (DEPTH = 0)'||LF||
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'||LF||LF||
      title_and_value(cols,
      NULL,             'R', c1,
      'Response Time',  'R', c2,
      'Elapsed',        'R', c3,
      NULL,             'R', c4,
      'Non-Idle',       'R', c5,
      'Elapsed Time',   'R', c6,
      'Idle',           'R', c7 )||LF||
      title_and_value(cols,
      'Call ',           'R', c1,
      'Accounted-for',   'R', c2,
      'Time',            'R', c3,
      'CPU Time',        'R', c4,
      'Wait Time',       'R', c5,
      'Unaccounted-for', 'R', c6,
      'Wait Time',       'R', c7 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),     'R', c1,
      SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
      SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
      SUBSTR(DASHES, 1, c7 - 1), 'R', c7 ));

      FOR i IN (SELECT *
                  FROM trca$_trc_non_recu_time_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        IF i.call = trca$g.CALL_TOTAL THEN
          printf(title_and_value(cols,
          SUBSTR(DASHES, 1, c1),     'R', c1,
          SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7 - 1), 'R', c7 ));
        END IF;

        printf(title_and_value(cols,
        i.call_type||':',           'R', c1,
        i.accounted_response,       'R', c2,
        i.elapsed,                  'R', c3,
        i.cpu,                      'R', c4,
        i.non_idle_wait,            'R', c5,
        i.elapsed_unaccounted_for,  'R', c6,
        i.idle_wait,                'R', c7 ));
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display non-recursive time: '||SQLERRM);
    END;

    -- totals
    DECLARE
      cols INTEGER := 9;
      c1   INTEGER := 8;
      c2   INTEGER := 7;
      c3   INTEGER := 13;
      c4   INTEGER := 15;
      c5   INTEGER := 12;
      c6   INTEGER := 13;
      c7   INTEGER := 9;
      c8   INTEGER := 10;
      c9   INTEGER := 8;
    BEGIN
      SELECT GREATEST(NVL(MAX(LENGTH(call_count)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(p_disk_os)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(cr_query_consistent)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(cu_current)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(r_rows)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(mis_library_cache_misses)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c8),
             GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c9)
        INTO c2, c3, c4, c5, c6, c7, c8, c9
        FROM trca$_trc_non_recu_total_v
       WHERE tool_execution_id = p_tool_execution_id;

      printf(LF||
      title_and_value(cols,
      NULL,            'R', c1,
      NULL,            'R', c2,
      'OS',            'R', c3,
      'BG Consistent', 'R', c4,
      'BG Current',    'R', c5,
      'Rows',          'R', c6,
      'Library',       'R', c7,
      'Times',         'R', c8,
      'Times',         'R', c9 )||LF||
      title_and_value(cols,
      NULL,          'R', c1,
      'Call',        'R', c2,
      'Buffer Gets', 'R', c3,
      'Read Mode',   'R', c4,
      'Mode',        'R', c5,
      'Processed',   'R', c6,
      'Cache',       'R', c7,
      'Waited',      'R', c8,
      'Waited',      'R', c9 )||LF||
      title_and_value(cols,
      'Call ',       'R', c1,
      'Count',       'R', c2,
      '(disk)',      'R', c3,
      '(query)',     'R', c4,
      '(current)',   'R', c5,
      'or Returned', 'R', c6,
      'Misses',      'R', c7,
      'Non-Idle',    'R', c8,
      'Idle',        'R', c9 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),     'R', c1,
      SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
      SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
      SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
      SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
      SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));

      FOR i IN (SELECT *
                  FROM trca$_trc_non_recu_total_v
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        IF i.call = trca$g.CALL_TOTAL THEN
          printf(title_and_value(cols,
          SUBSTR(DASHES, 1, c1),     'R', c1,
          SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));
        END IF;

        printf(title_and_value(cols,
        i.call_type||':',           'R', c1,
        i.call_count,               'R', c2,
        i.p_disk_os,                'R', c3,
        i.cr_query_consistent,      'R', c4,
        i.cu_current,               'R', c5,
        i.r_rows,                   'R', c6,
        i.mis_library_cache_misses, 'R', c7,
        i.wait_count_non_idle,      'R', c8,
        i.wait_count_idle,          'R', c9 ));
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display non-recursive totals: '||SQLERRM);
    END;

    -- waits
    IF trca$g.g_include_waits = 'Y' THEN
      DECLARE
        l_count INTEGER;
        cols INTEGER := 10;
        c1   INTEGER := 7;
        c2   INTEGER := 7;
        c3   INTEGER := 11;
        c4   INTEGER := 10;
        c5   INTEGER := 11;
        c6   INTEGER := 8;
        c7   INTEGER := 11;
        c8   INTEGER := 11;
        c9   INTEGER := 8;
        c10  INTEGER := 9;
      BEGIN
        SELECT COUNT(*),
               GREATEST(NVL(MAX(LENGTH(event_name)), 0) + GAP, c1),
               GREATEST(NVL(MAX(LENGTH(wait_class)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(avg_wait)), 0) + GAP, c7),
               GREATEST(NVL(MAX(LENGTH(max_wait)), 0) + GAP, c8),
               GREATEST(NVL(MAX(LENGTH(blocks)), 0) + GAP, c9),
               GREATEST(NVL(MAX(LENGTH(avg_blocks)), 0) + GAP, c10)
          INTO l_count, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10
          FROM trca$_trc_non_recu_wait_vf
         WHERE tool_execution_id = p_tool_execution_id;

        IF l_count > 0 THEN
          printf(LF||
          title_and_value(cols,
          NULL,    'R', c1,
          NULL,    'R', c2,
          NULL,    'R', c3,
          'Times', 'R', c4,
          NULL,    'R', c5,
          'Times', 'R', c6,
          NULL,    'R', c7,
          NULL,    'R', c8,
          NULL,    'R', c9,
          NULL,    'R', c10 )||LF||
          title_and_value(cols,
          'Event ',   'R', c1,
          ' Wait',    'L', c2,
          'Non-Idle', 'R', c3,
          'Waited',   'R', c4,
          'Idle',     'R', c5,
          'Waited',   'R', c6,
          'Average',  'R', c7,
          'Max',      'R', c8,
          NULL,       'R', c9,
          'Average',  'R', c10 )||LF||
          title_and_value(cols,
          'Name ',       'R', c1,
          ' Class',      'L', c2,
          'Wait Time',   'R', c3,
          'Non-Idle',    'R', c4,
          'Wait Time',   'R', c5,
          'Idle',        'R', c6,
          'Wait Time',   'R', c7,
          'Wait Time',   'R', c8,
          'Blocks',      'R', c9,
          'Blocks',      'R', c10)||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),      'R', c1,
          SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));

          FOR i IN (SELECT *
                      FROM trca$_trc_non_recu_wait_vf
                     WHERE tool_execution_id = p_tool_execution_id
                     ORDER BY
                           row_type,
                           wait DESC)
          LOOP
            IF i.row_type = 'T' THEN
              printf(title_and_value(cols,
              SUBSTR(DASHES, 1, c1),      'R', c1,
              SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
              SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
              SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
              SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
              SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
              SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
              SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
              SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
              SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));
            END IF;

            printf(title_and_value(cols,
            i.event_name||':',     'R', c1,
            ' '||i.wait_class,     'L', c2,
            i.non_idle_wait,       'R', c3,
            i.wait_count_non_idle, 'R', c4,
            i.idle_wait,           'R', c5,
            i.wait_count_idle,     'R', c6,
            i.avg_wait,            'R', c7,
            i.max_wait,            'R', c8,
            i.blocks,              'R', c9,
            i.avg_blocks,          'R', c10 ));
          END LOOP;
        END IF; -- l_count > 0
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display non-recursive waits: '||SQLERRM);
      END;
    END IF; -- trca$g.g_include_waits = 'Y'

    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Recursive Time and Totals
     * ------------------------- */
    l_phase := 'recursive_totals';
    print_log('-> '||l_phase);

    -- time
    DECLARE
      cols INTEGER := 7;
      c1   INTEGER := 8;
      c2   INTEGER := 15;
      c3   INTEGER := 9;
      c4   INTEGER := 10;
      c5   INTEGER := 11;
      c6   INTEGER := 17;
      c7   INTEGER := 11;
    BEGIN
      SELECT GREATEST(NVL(MAX(LENGTH(accounted_response)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(elapsed)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(cpu)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(elapsed_unaccounted_for)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c7)
        INTO c2, c3, c4, c5, c6, c7
        FROM trca$_trc_recu_time_vf
       WHERE tool_execution_id = p_tool_execution_id;

      printf(LF||LF||
      'RECURSIVE TIME AND TOTALS (DEPTH > 0)'||LF||
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'||LF||LF||
      title_and_value(cols,
      NULL,             'R', c1,
      'Response Time',  'R', c2,
      'Elapsed',        'R', c3,
      NULL,             'R', c4,
      'Non-Idle',       'R', c5,
      'Elapsed Time',   'R', c6,
      'Idle',           'R', c7 )||LF||
      title_and_value(cols,
      'Call ',           'R', c1,
      'Accounted-for',   'R', c2,
      'Time',            'R', c3,
      'CPU Time',        'R', c4,
      'Wait Time',       'R', c5,
      'Unaccounted-for', 'R', c6,
      'Wait Time',       'R', c7 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),     'R', c1,
      SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
      SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
      SUBSTR(DASHES, 1, c7 - 1), 'R', c7 ));

      FOR i IN (SELECT *
                  FROM trca$_trc_recu_time_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        IF i.call = trca$g.CALL_TOTAL THEN
          printf(title_and_value(cols,
          SUBSTR(DASHES, 1, c1),     'R', c1,
          SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7 - 1), 'R', c7 ));
        END IF;

        printf(title_and_value(cols,
        i.call_type||':',           'R', c1,
        i.accounted_response,       'R', c2,
        i.elapsed,                  'R', c3,
        i.cpu,                      'R', c4,
        i.non_idle_wait,            'R', c5,
        i.elapsed_unaccounted_for,  'R', c6,
        i.idle_wait,                'R', c7 ));
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display recursive time: '||SQLERRM);
    END;

    -- totals
    DECLARE
      cols INTEGER := 9;
      c1   INTEGER := 8;
      c2   INTEGER := 7;
      c3   INTEGER := 13;
      c4   INTEGER := 15;
      c5   INTEGER := 12;
      c6   INTEGER := 13;
      c7   INTEGER := 9;
      c8   INTEGER := 10;
      c9   INTEGER := 8;
    BEGIN
      SELECT GREATEST(NVL(MAX(LENGTH(call_count)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(p_disk_os)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(cr_query_consistent)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(cu_current)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(r_rows)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(mis_library_cache_misses)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c8),
             GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c9)
        INTO c2, c3, c4, c5, c6, c7, c8, c9
        FROM trca$_trc_recu_total_v
       WHERE tool_execution_id = p_tool_execution_id;

      printf(LF||
      title_and_value(cols,
      NULL,            'R', c1,
      NULL,            'R', c2,
      'OS',            'R', c3,
      'BG Consistent', 'R', c4,
      'BG Current',    'R', c5,
      'Rows',          'R', c6,
      'Library',       'R', c7,
      'Times',         'R', c8,
      'Times',         'R', c9 )||LF||
      title_and_value(cols,
      NULL,          'R', c1,
      'Call',        'R', c2,
      'Buffer Gets', 'R', c3,
      'Read Mode',   'R', c4,
      'Mode',        'R', c5,
      'Processed',   'R', c6,
      'Cache',       'R', c7,
      'Waited',      'R', c8,
      'Waited',      'R', c9 )||LF||
      title_and_value(cols,
      'Call ',       'R', c1,
      'Count',       'R', c2,
      '(disk)',      'R', c3,
      '(query)',     'R', c4,
      '(current)',   'R', c5,
      'or Returned', 'R', c6,
      'Misses',      'R', c7,
      'Non-Idle',    'R', c8,
      'Idle',        'R', c9 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),     'R', c1,
      SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
      SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
      SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
      SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
      SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));

      FOR i IN (SELECT *
                  FROM trca$_trc_recu_total_v
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        IF i.call = trca$g.CALL_TOTAL THEN
          printf(title_and_value(cols,
          SUBSTR(DASHES, 1, c1),     'R', c1,
          SUBSTR(DASHES, 1, c2 - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3 - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4 - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5 - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6 - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7 - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8 - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9 - 1), 'R', c9 ));
        END IF;

        printf(title_and_value(cols,
        i.call_type||':',           'R', c1,
        i.call_count,               'R', c2,
        i.p_disk_os,                'R', c3,
        i.cr_query_consistent,      'R', c4,
        i.cu_current,               'R', c5,
        i.r_rows,                   'R', c6,
        i.mis_library_cache_misses, 'R', c7,
        i.wait_count_non_idle,      'R', c8,
        i.wait_count_idle,          'R', c9 ));
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display recursive totals: '||SQLERRM);
    END;

    -- waits
    IF trca$g.g_include_waits = 'Y' THEN
      DECLARE
        l_count INTEGER;
        cols INTEGER := 10;
        c1   INTEGER := 7;
        c2   INTEGER := 7;
        c3   INTEGER := 11;
        c4   INTEGER := 10;
        c5   INTEGER := 11;
        c6   INTEGER := 8;
        c7   INTEGER := 11;
        c8   INTEGER := 11;
        c9   INTEGER := 8;
        c10  INTEGER := 9;
      BEGIN
        SELECT COUNT(*),
               GREATEST(NVL(MAX(LENGTH(event_name)), 0) + GAP, c1),
               GREATEST(NVL(MAX(LENGTH(wait_class)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(wait_count_non_idle)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(wait_count_idle)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(avg_wait)), 0) + GAP, c7),
               GREATEST(NVL(MAX(LENGTH(max_wait)), 0) + GAP, c8),
               GREATEST(NVL(MAX(LENGTH(blocks)), 0) + GAP, c9),
               GREATEST(NVL(MAX(LENGTH(avg_blocks)), 0) + GAP, c10)
          INTO l_count, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10
          FROM trca$_trc_recu_wait_vf
         WHERE tool_execution_id = p_tool_execution_id;

        IF l_count > 0 THEN
          printf(LF||
          title_and_value(cols,
          NULL,    'R', c1,
          NULL,    'R', c2,
          NULL,    'R', c3,
          'Times', 'R', c4,
          NULL,    'R', c5,
          'Times', 'R', c6,
          NULL,    'R', c7,
          NULL,    'R', c8,
          NULL,    'R', c9,
          NULL,    'R', c10 )||LF||
          title_and_value(cols,
          'Event ',   'R', c1,
          ' Wait',    'L', c2,
          'Non-Idle', 'R', c3,
          'Waited',   'R', c4,
          'Idle',     'R', c5,
          'Waited',   'R', c6,
          'Average',  'R', c7,
          'Max',      'R', c8,
          NULL,       'R', c9,
          'Average',  'R', c10 )||LF||
          title_and_value(cols,
          'Name ',       'R', c1,
          ' Class',      'L', c2,
          'Wait Time',   'R', c3,
          'Non-Idle',    'R', c4,
          'Wait Time',   'R', c5,
          'Idle',        'R', c6,
          'Wait Time',   'R', c7,
          'Wait Time',   'R', c8,
          'Blocks',      'R', c9,
          'Blocks',      'R', c10)||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),      'R', c1,
          SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));

          FOR i IN (SELECT *
                      FROM trca$_trc_recu_wait_vf
                     WHERE tool_execution_id = p_tool_execution_id
                     ORDER BY
                           row_type,
                           wait DESC)
          LOOP
            IF i.row_type = 'T' THEN
              printf(title_and_value(cols,
              SUBSTR(DASHES, 1, c1),      'R', c1,
              SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
              SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
              SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
              SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
              SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
              SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
              SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
              SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
              SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));
            END IF;

            printf(title_and_value(cols,
            i.event_name||':',     'R', c1,
            ' '||i.wait_class,     'L', c2,
            i.non_idle_wait,       'R', c3,
            i.wait_count_non_idle, 'R', c4,
            i.idle_wait,           'R', c5,
            i.wait_count_idle,     'R', c6,
            i.avg_wait,            'R', c7,
            i.max_wait,            'R', c8,
            i.blocks,              'R', c9,
            i.avg_blocks,          'R', c10 ));
          END LOOP;
        END IF; -- l_count > 0
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display recursive waits: '||SQLERRM);
      END;
    END IF; -- trca$g.g_include_waits = 'Y'

    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Top SQL
     * ------------------------- */
    l_phase := 'top_sql';
    print_log('-> '||l_phase);

    DECLARE
      l_top_sql_count        INTEGER;
      l_top_sql_contribution NUMBER;
      cols INTEGER;
      c1   INTEGER;
      c2   INTEGER;
      c3   INTEGER;
      c4   INTEGER;
      c5   INTEGER;
      c6   INTEGER;
      c7   INTEGER;
      c8   INTEGER;
      c9   INTEGER;
      c10  INTEGER;
      c11  INTEGER;
      c12  INTEGER;
      c13  INTEGER;
      c14  INTEGER;
      c15  INTEGER;

    BEGIN
      printf(LF||LF||
      'TOP SQL'||LF||
      '~~~~~~~');

      BEGIN -- Response Time
        cols := 13;
        c1   := 5;
        c2   := 8;
        c3   := 10;
        c4   := 9;
        c5   := 10;
        c6   := 11;
        c7   := 11;
        c8   := 11;
        c9   := 7;
        c10  := 6;
        c11  := 7;
        c12  := 10;
        c13  := 12;
        c14  := 8;
        c15  := 12;

        SELECT COUNT(*), SUM(contribution),
               GREATEST(NVL(MAX(LENGTH(rank)), 0) + GAP, c1),
               GREATEST(NVL(MAX(LENGTH(contribution)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(response_time_self)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(elapsed_time_self)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(cpu_time_self)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c7),
               GREATEST(NVL(MAX(LENGTH(response_time_progeny)), 0) + GAP, c8),
               GREATEST(NVL(MAX(LENGTH(exec_count)), 0) + GAP, c9),
               GREATEST(NVL(MAX(LENGTH(uid#)), 0) + GAP, c10),
               GREATEST(NVL(MAX(LENGTH(dep)), 0) + GAP, c11),
               GREATEST(NVL(MAX(LENGTH(SUBSTR(trca$g.flatten_text(sql_text), 1, 40))), 0) + GAP, c12),
               GREATEST(NVL(MAX(LENGTH(hv)), 0) + GAP, c13),
               GREATEST(NVL(MAX(LENGTH(sqlid)), 0) + GAP, c14),
               GREATEST(NVL(MAX(LENGTH(plh)), 0) + GAP, c15)
          INTO l_top_sql_count, l_top_sql_contribution, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15
          FROM trca$_sql_v
         WHERE tool_execution_id = p_tool_execution_id
           AND top_sql = 'Y';

        printf(LF);
        IF l_top_sql_count = 0 THEN
          printf('There are no individual SQL statements with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Response Time Accounted-for".');
        ELSIF l_top_sql_count = 1 THEN
          printf('There is only one SQL statement with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Response Time Accounted-for".');
        ELSE
          printf('There are '||l_top_sql_count||' SQL statements with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Response Time Accounted-for".'||LF||
          'These combined '||l_top_sql_count||' SQL statements are responsible for a total of '||trca$g.format_perc1(100 * l_top_sql_contribution)||' of the "Total Response Time Accounted-for".');
        END IF;

        IF l_top_sql_count > 0 THEN
          IF trca$g.g_sqlid = 'Y' THEN
            cols := cols + 1;
          END IF;
          IF trca$g.g_plh = 'Y' THEN
            cols := cols + 1;
          END IF;

          printf(LF||
          title_and_value(cols,
          NULL,        'R', c1,
          'Trace',     'R', c2,
          'Self',      'R', c3,
          NULL,        'R', c4,
          NULL,        'R', c5,
          NULL,        'R', c6,
          NULL,        'R', c7,
          'Recursive', 'R', c8,
          NULL,        'R', c9,
          NULL,        'R', c10,
          NULL,        'R', c11,
          NULL,        'R', c12,
          NULL,        'R', c13,
          NULL,        'R', c14,
          'Plan',      'R', c15 )||LF||
          title_and_value(cols,
          NULL,       'R', c1,
          'RT',       'R', c2,
          'Response', 'R', c3,
          'Elapsed',  'R', c4,
          NULL,       'R', c5,
          'Non-Idle', 'R', c6,
          'Idle',     'R', c7,
          'Response', 'R', c8,
          'Exec',     'R', c9,
          NULL,       'R', c10,
          NULL,       'R', c11,
          NULL,       'R', c12,
          NULL,       'R', c13,
          NULL,       'R', c14,
          'Hash',     'R', c15 )||LF||
          title_and_value(cols,
          'Rank ',      'R', c1,
          'Pct(1)',     'R', c2,
          'Time(2)',    'R', c3,
          'Time',       'R', c4,
          'CPU Time',   'R', c5,
          'Wait Time',  'R', c6,
          'Wait Time',  'R', c7,
          'Time(3)',    'R', c8,
          'Count',      'R', c9,
          'User',       'R', c10,
          'Depth',      'R', c11,
          'SQL Text ',  'C', c12,
          'Hash Value', 'R', c13,
          'SQL ID',     'R', c14,
          'Value',      'R', c15 )||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),      'R', c1,
          SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
          SUBSTR(DASHES, 1, c11 - 1), 'R', c11,
          SUBSTR(DASHES, 1, c12 - 1), 'R', c12,
          SUBSTR(DASHES, 1, c13 - 1), 'R', c13,
          SUBSTR(DASHES, 1, c14 - 1), 'R', c14,
          SUBSTR(DASHES, 1, c15 - 1), 'R', c15 ));

          FOR i IN (SELECT *
                      FROM trca$_sql_vf
                     WHERE tool_execution_id = p_tool_execution_id
                       AND top_sql = 'Y'
                     ORDER BY
                           rank)
          LOOP
              printf(title_and_value(cols,
              i.rank||':',             'R', c1,
              i.contribution,          'R', c2,
              i.response_time_self,    'R', c3,
              i.elapsed_time_self,     'R', c4,
              i.cpu_time_self,         'R', c5,
              i.non_idle_wait,         'R', c6,
              i.idle_wait,             'R', c7,
              i.response_time_progeny, 'R', c8,
              i.exec_count,            'R', c9,
              i.uid#,                  'R', c10,
              i.dep,                   'R', c11,
              ' '||SUBSTR(trca$g.flatten_text(i.sql_text), 1, 40), 'L', c12,
              i.hv,                    'R', c13,
              i.sqlid,                 'R', c14,
              i.plh,                   'R', c15 ));
          END LOOP;

          printf(LF||
          '(1) Percent of "Total Response Time Accounted-for", which is '||rtf_rec.accounted_for_response_time||' secs.'||LF||
          '(2) "Self Response Time Accounted-for" in secs (caused by this SQL statement).'||LF||
          '(3) "Recursive Response Time Accounted-for" in secs (caused by recursive SQL invoked by this statement).');
        END IF;
      END; -- Reponse Time

      BEGIN -- Elapsed Time
        cols := 11;
        c1   := 5;
        c2   := 8;
        c3   := 9;
        c4   := 10;
        c5   := 11;
        c6   := 11;
        c7   := 7;
        c8   := 6;
        c9   := 7;
        c10  := 10;
        c11  := 12;
        c12  := 8;
        c13  := 12;

        SELECT COUNT(*), SUM(contribution_et),
               GREATEST(NVL(MAX(LENGTH(rank_et)), 0) + GAP, c1),
               GREATEST(NVL(MAX(LENGTH(contribution_et)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(elapsed_time_self)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(cpu_time_self)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(elapsed_time_progeny)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(exec_count)), 0) + GAP, c7),
               GREATEST(NVL(MAX(LENGTH(uid#)), 0) + GAP, c8),
               GREATEST(NVL(MAX(LENGTH(dep)), 0) + GAP, c9),
               GREATEST(NVL(MAX(LENGTH(SUBSTR(trca$g.flatten_text(sql_text), 1, 40))), 0) + GAP, c10),
               GREATEST(NVL(MAX(LENGTH(hv)), 0) + GAP, c11),
               GREATEST(NVL(MAX(LENGTH(sqlid)), 0) + GAP, c12),
               GREATEST(NVL(MAX(LENGTH(plh)), 0) + GAP, c13)
          INTO l_top_sql_count, l_top_sql_contribution, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13
          FROM trca$_sql_v
         WHERE tool_execution_id = p_tool_execution_id
           AND top_sql_et = 'Y';

        printf(LF);
        IF l_top_sql_count = 0 THEN
          printf('There are no individual SQL statements with "Elapsed Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Elapsed Time".');
        ELSIF l_top_sql_count = 1 THEN
          printf('There is only one SQL statement with "Elapsed Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Elapsed Time".');
        ELSE
          printf('There are '||l_top_sql_count||' SQL statements with "Elapsed Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Elapsed Time".'||LF||
          'These combined '||l_top_sql_count||' SQL statements are responsible for a total of '||trca$g.format_perc1(100 * l_top_sql_contribution)||' of the "Total Elapsed Time".');
        END IF;

        IF l_top_sql_count > 0 THEN
          IF trca$g.g_sqlid = 'Y' THEN
            cols := cols + 1;
          END IF;
          IF trca$g.g_plh = 'Y' THEN
            cols := cols + 1;
          END IF;

          printf(LF||
          title_and_value(cols,
          NULL,        'R', c1,
          'Trace',     'R', c2,
          'Self',      'R', c3,
          NULL,        'R', c4,
          NULL,        'R', c5,
          'Recursive', 'R', c6,
          NULL,        'R', c7,
          NULL,        'R', c8,
          NULL,        'R', c9,
          NULL,        'R', c10,
          NULL,        'R', c11,
          NULL,        'R', c12,
          'Plan',      'R', c13 )||LF||
          title_and_value(cols,
          NULL,       'R', c1,
          'ET',       'R', c2,
          'Elapsed',  'R', c3,
          NULL,       'R', c4,
          'Non-Idle', 'R', c5,
          'Elapsed',  'R', c6,
          'Exec',     'R', c7,
          NULL,       'R', c8,
          NULL,       'R', c9,
          NULL,       'R', c10,
          NULL,       'R', c11,
          NULL,       'R', c12,
          'Hash',     'R', c13 )||LF||
          title_and_value(cols,
          'Rank ',      'R', c1,
          'Pct(1)',     'R', c2,
          'Time(2)',    'R', c3,
          'CPU Time',   'R', c4,
          'Wait Time',  'R', c5,
          'Time(3)',    'R', c6,
          'Count',      'R', c7,
          'User',       'R', c8,
          'Depth',      'R', c9,
          'SQL Text ',  'C', c10,
          'Hash Value', 'R', c11,
          'SQL ID',     'R', c12,
          'Value',      'R', c13 )||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),      'R', c1,
          SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
          SUBSTR(DASHES, 1, c11 - 1), 'R', c11,
          SUBSTR(DASHES, 1, c12 - 1), 'R', c12,
          SUBSTR(DASHES, 1, c13 - 1), 'R', c13 ));

          FOR i IN (SELECT *
                      FROM trca$_sql_vf
                     WHERE tool_execution_id = p_tool_execution_id
                       AND top_sql_et = 'Y'
                     ORDER BY
                           rank_et)
          LOOP
              printf(title_and_value(cols,
              i.rank_et||':',          'R', c1,
              i.contribution_et,       'R', c2,
              i.elapsed_time_self,     'R', c3,
              i.cpu_time_self,         'R', c4,
              i.non_idle_wait,         'R', c5,
              i.elapsed_time_progeny,  'R', c6,
              i.exec_count,            'R', c7,
              i.uid#,                  'R', c8,
              i.dep,                   'R', c9,
              ' '||SUBSTR(trca$g.flatten_text(i.sql_text), 1, 40), 'L', c10,
              i.hv,                    'R', c11,
              i.sqlid,                 'R', c12,
              i.plh,                   'R', c13 ));
          END LOOP;

          printf(LF||
          '(1) Percent of "Total Elapsed Time", which is '||rtf_rec.elapsed||' secs.'||LF||
          '(2) "Self Elapsed Time" in secs (caused by this SQL statement).'||LF||
          '(3) "Recursive Elapsed Time" in secs (caused by recursive SQL invoked by this statement).');
        END IF;
      END; -- Elapsed Time

      BEGIN -- CPU Time
        cols := 9;
        c1   := 5;
        c2   := 8;
        c3   := 9;
        c4   := 11;
        c5   := 7;
        c6   := 6;
        c7   := 7;
        c8   := 10;
        c9   := 12;
        c10  := 8;
        c11  := 12;

        SELECT COUNT(*), SUM(contribution_ct),
               GREATEST(NVL(MAX(LENGTH(rank_ct)), 0) + GAP, c1),
               GREATEST(NVL(MAX(LENGTH(contribution_ct)), 0) + GAP, c2),
               GREATEST(NVL(MAX(LENGTH(cpu_time_self)), 0) + GAP, c3),
               GREATEST(NVL(MAX(LENGTH(cpu_time_progeny)), 0) + GAP, c4),
               GREATEST(NVL(MAX(LENGTH(exec_count)), 0) + GAP, c5),
               GREATEST(NVL(MAX(LENGTH(uid#)), 0) + GAP, c6),
               GREATEST(NVL(MAX(LENGTH(dep)), 0) + GAP, c7),
               GREATEST(NVL(MAX(LENGTH(SUBSTR(trca$g.flatten_text(sql_text), 1, 40))), 0) + GAP, c8),
               GREATEST(NVL(MAX(LENGTH(hv)), 0) + GAP, c9),
               GREATEST(NVL(MAX(LENGTH(sqlid)), 0) + GAP, c10),
               GREATEST(NVL(MAX(LENGTH(plh)), 0) + GAP, c11)
          INTO l_top_sql_count, l_top_sql_contribution, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11
          FROM trca$_sql_v
         WHERE tool_execution_id = p_tool_execution_id
           AND top_sql_ct = 'Y';

        printf(LF);
        IF l_top_sql_count = 0 THEN
          printf('There are no individual SQL statements with "CPU Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total CPU Time".');
        ELSIF l_top_sql_count = 1 THEN
          printf('There is only one SQL statement with "CPU Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total CPU Time".');
        ELSE
          printf('There are '||l_top_sql_count||' SQL statements with "CPU Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total CPU Time".'||LF||
          'These combined '||l_top_sql_count||' SQL statements are responsible for a total of '||trca$g.format_perc1(100 * l_top_sql_contribution)||' of the "Total CPU Time".');
        END IF;

        IF l_top_sql_count > 0 THEN
          IF trca$g.g_sqlid = 'Y' THEN
            cols := cols + 1;
          END IF;
          IF trca$g.g_plh = 'Y' THEN
            cols := cols + 1;
          END IF;

          printf(LF||
          title_and_value(cols,
          NULL,        'R', c1,
          'Trace',     'R', c2,
          'Self',      'R', c3,
          'Recursive', 'R', c4,
          NULL,        'R', c5,
          NULL,        'R', c6,
          NULL,        'R', c7,
          NULL,        'R', c8,
          NULL,        'R', c9,
          NULL,        'R', c10,
          'Plan',      'R', c11 )||LF||
          title_and_value(cols,
          NULL,   'R', c1,
          'CPU',  'R', c2,
          'CPU',  'R', c3,
          'CPU',  'R', c4,
          'Exec', 'R', c5,
          NULL,   'R', c6,
          NULL,   'R', c7,
          NULL,   'R', c8,
          NULL,   'R', c9,
          NULL,   'R', c10,
          'Hash', 'R', c11 )||LF||
          title_and_value(cols,
          'Rank ',      'R', c1,
          'Pct(1)',     'R', c2,
          'Time(2)',    'R', c3,
          'Time(3)',    'R', c4,
          'Count',      'R', c5,
          'User',       'R', c6,
          'Depth',      'R', c7,
          'SQL Text ',  'C', c8,
          'Hash Value', 'R', c9,
          'SQL ID',     'R', c10,
          'Value',      'R', c11 )||LF||
          title_and_value(cols,
          SUBSTR(DASHES, 1, c1),      'R', c1,
          SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
          SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
          SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
          SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
          SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
          SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
          SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
          SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
          SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
          SUBSTR(DASHES, 1, c11 - 1), 'R', c11 ));

          FOR i IN (SELECT *
                      FROM trca$_sql_vf
                     WHERE tool_execution_id = p_tool_execution_id
                       AND top_sql_ct = 'Y'
                     ORDER BY
                           rank_ct)
          LOOP
              printf(title_and_value(cols,
              i.rank_ct||':',          'R', c1,
              i.contribution_ct,       'R', c2,
              i.cpu_time_self,         'R', c3,
              i.elapsed_time_progeny,  'R', c4,
              i.exec_count,            'R', c5,
              i.uid#,                  'R', c6,
              i.dep,                   'R', c7,
              ' '||SUBSTR(trca$g.flatten_text(i.sql_text), 1, 40), 'L', c8,
              i.hv,                    'R', c9,
              i.sqlid,                 'R', c10,
              i.plh,                   'R', c11 ));
          END LOOP;

          printf(LF||
          '(1) Percent of "Total CPU Time", which is '||rtf_rec.cpu||' secs.'||LF||
          '(2) "Self CPU Time" in secs (caused by this SQL statement).'||LF||
          '(3) "Recursive CPU Time" in secs (caused by recursive SQL invoked by this statement).');
        END IF;
      END; -- CPU Time

    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display top sql: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Non-Recursive SQL
     * ------------------------- */
    l_phase := 'non-recursive';
    print_log('-> '||l_phase);

    DECLARE
      l_row INTEGER := 0;
      cols INTEGER := 10;
      c1   INTEGER := 2;
      c2   INTEGER := 10;
      c3   INTEGER := 8;
      c4   INTEGER := 10;
      c5   INTEGER := 11;
      c6   INTEGER := 6;
      c7   INTEGER := 10;
      c8   INTEGER := 17;
      c9   INTEGER := 15;
      c10  INTEGER := 12;
      c11  INTEGER := 8;
      c12  INTEGER := 12;

    BEGIN
      printf(LF||LF||
      'NON-RECURSIVE SQL (DEPTH = 0)'||LF||
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'||LF);

      SELECT GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(response_time_total)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(contribution)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(response_time_self)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(response_time_progeny)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(uid#)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(SUBSTR(trca$g.flatten_text(sql_text), 1, 40))), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(start_timestamp)), 0) + GAP, c8),
             GREATEST(NVL(MAX(LENGTH(end_timestamp)), 0) + GAP, c9),
             GREATEST(NVL(MAX(LENGTH(hv)), 0) + GAP, c10),
             GREATEST(NVL(MAX(LENGTH(sqlid)), 0) + GAP, c11)
        INTO c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11
        FROM trca$_non_recursive_vf
       WHERE tool_execution_id = p_tool_execution_id;

      printf('List of individual executions of non-recursive SQL in chronological order by first db call timestamp.');

      IF trca$g.g_include_internal_sql = 'N' AND trca$g.g_include_non_top_sql = 'N' THEN
        printf('Further details for internal and non-top SQL are excluded as per corresponding tool configuration parameters.');
      ELSIF trca$g.g_include_internal_sql = 'N' THEN
        printf('Further details for internal SQL are excluded as per corresponding tool configuration parameter.');
      ELSIF trca$g.g_include_non_top_sql = 'N' THEN
        printf('Further details for non-top SQL are excluded as per corresponding tool configuration parameter.');
      END IF;

      IF trca$g.g_sqlid = 'Y' THEN
        cols := cols + 1;
      END IF;
      IF trca$g.g_plh = 'Y' THEN
        cols := cols + 1;
      END IF;

      printf(LF||
      title_and_value(cols,
      NULL,        'R', c1,
      'Total',     'R', c2,
      'Trace',     'R', c3,
      'Self',      'R', c4,
      'Recursive', 'R', c5,
      NULL,        'R', c6,
      NULL,        'R', c7,
      NULL,        'R', c8,
      NULL,        'R', c9,
      NULL,        'R', c10,
      NULL,        'R', c11,
      'Plan',      'R', c12 )||LF||
      title_and_value(cols,
      NULL,       'R', c1,
      'Response', 'R', c2,
      'RT',       'R', c3,
      'Response', 'R', c4,
      'Response', 'R', c5,
      NULL,       'R', c6,
      NULL,       'R', c7,
      NULL,       'R', c8,
      NULL,       'R', c9,
      NULL,       'R', c10,
      NULL,       'R', c11,
      'Hash',     'R', c12 )||LF||
      title_and_value(cols,
      '# ',               'R', c1,
      'Time(1)',          'R', c2,
      'Pct(2)',           'R', c3,
      'Time(3)',          'R', c4,
      'Time(4)',          'R', c5,
      'User',             'R', c6,
      'SQL Text ',        'C', c7,
      'Start Timestamp ', 'C', c8,
      'End Timestamp ',   'C', c9,
      'Hash Value',       'R', c10,
      'SQL ID',           'R', c11,
      'Value',            'R', c12 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),      'R', c1,
      SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
      SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
      SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
      SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
      SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
      SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
      SUBSTR(DASHES, 1, c11 - 1), 'R', c11,
      SUBSTR(DASHES, 1, c12 - 1), 'R', c12 ));

      FOR i IN (SELECT *
                  FROM trca$_non_recursive_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       start_tim)
      LOOP
        l_row := l_row + 1;
        printf(title_and_value(cols,
        l_row||':',              'R', c1,
        i.response_time_total,   'R', c2,
        i.contribution,          'R', c3,
        i.response_time_self,    'R', c4,
        i.response_time_progeny, 'R', c5,
        i.uid#,                  'R', c6,
        ' '||SUBSTR(trca$g.flatten_text(i.sql_text), 1, 40), 'L', c7,
        ' '||i.start_timestamp,  'L', c8,
        ' '||i.end_timestamp,    'L', c9,
        i.hv,                    'R', c10,
        i.sqlid,                 'R', c11,
        i.plh,                   'R', c12 ));
      END LOOP;

      printf(LF||
      '(1) "Total Response Time" in secs, as per start and end timestamps of db calls. It includes "Unaccounted-for" times.'||LF||
      '(1) This list is constrained by threshold configuration parameter with current value of '||trca$g.g_response_time_th||'s.'||LF||
      '(2) Percent of "Total Response Time Accounted-for", which is '||rtf_rec.accounted_for_response_time||' secs.'||LF||
      '(3) "Self Response Time Accounted-for" in secs (caused by this non-recursive SQL statement).'||LF||
      '(4) "Recursive Response Time Accounted-for" in secs (caused by recursive SQL invoked by this statement).');
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display non-recursive sql: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * SQL Genealogy
     * ------------------------- */
    l_phase := 'genealogy';
    print_log('-> '||l_phase);

    DECLARE
      l_row INTEGER := 0;
      cols INTEGER := 9;
      c1   INTEGER := 2;
      c2   INTEGER := 8;
      c3   INTEGER := 10;
      c4   INTEGER := 11;
      c5   INTEGER := 7;
      c6   INTEGER := 6;
      c7   INTEGER := 7;
      c8   INTEGER := 10;
      c9   INTEGER := 12;
      c10  INTEGER := 8;
      c11  INTEGER := 12;

    BEGIN
      printf(LF||LF||
      'SQL GENEALOGY'||LF||
      '~~~~~~~~~~~~~'||LF);

      SELECT GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(contribution)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(response_time_self)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(response_time_progeny)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(exec_count)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(uid#)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(dep)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(SUBSTR(trca$g.flatten_text(sql_text_prefix||sql_text), 1, 80))), 0) + GAP, c8),
             GREATEST(NVL(MAX(LENGTH(hv)), 0) + GAP, c9),
             GREATEST(NVL(MAX(LENGTH(sqlid)), 0) + GAP, c10)
        INTO c1, c2, c3, c4, c5, c6, c7, c8, c9, c10
        FROM trca$_sql_genealogy_vf
       WHERE tool_execution_id = p_tool_execution_id;

      printf('Aggregate view of non-recursive SQL statements (depth = 0) and their recursive SQL at all depths.');

      IF trca$g.g_include_internal_sql = 'N' AND trca$g.g_include_non_top_sql = 'N' THEN
        printf('Further details for internal and non-top SQL are excluded as per corresponding tool configuration parameters.');
      ELSIF trca$g.g_include_internal_sql = 'N' THEN
        printf('Further details for internal SQL are excluded as per corresponding tool configuration parameter.');
      ELSIF trca$g.g_include_non_top_sql = 'N' THEN
        printf('Further details for non-top SQL are excluded as per corresponding tool configuration parameter.');
      END IF;

      IF trca$g.g_sqlid = 'Y' THEN
        cols := cols + 1;
      END IF;
      IF trca$g.g_plh = 'Y' THEN
        cols := cols + 1;
      END IF;

      printf(LF||
      title_and_value(cols,
      NULL,        'R', c1,
      'Trace',     'R', c2,
      'Self',      'R', c3,
      'Recursive', 'R', c4,
      NULL,        'R', c5,
      NULL,        'R', c6,
      NULL,        'R', c7,
      NULL,        'R', c8,
      NULL,        'R', c9,
      NULL,        'R', c10,
      'Plan',      'R', c11 )||LF||
      title_and_value(cols,
      NULL,       'R', c1,
      'RT',       'R', c2,
      'Response', 'R', c3,
      'Response', 'R', c4,
      'Exec',     'R', c5,
      NULL,       'R', c6,
      NULL,       'R', c7,
      NULL,       'R', c8,
      NULL,       'R', c9,
      NULL,       'R', c10,
      'hash',     'R', c11 )||LF||
      title_and_value(cols,
      '# ',         'R', c1,
      'Pct(1)',     'R', c2,
      'Time(2)',    'R', c3,
      'Time(3)',    'R', c4,
      'Count',      'R', c5,
      'User',       'R', c6,
      'Depth',      'R', c7,
      'SQL Text ',  'C', c8,
      'Hash Value', 'R', c9,
      'SQL ID',     'R', c10,
      'Value',      'R', c11 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),      'R', c1,
      SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
      SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
      SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
      SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
      SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
      SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
      SUBSTR(DASHES, 1, c11 - 1), 'R', c11 ));

      FOR i IN (SELECT *
                  FROM trca$_sql_genealogy_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       id)

      LOOP
        l_row := l_row + 1;
        printf(title_and_value(cols,
        l_row||':',              'R', c1,
        i.contribution,          'R', c2,
        i.response_time_self,    'R', c3,
        i.response_time_progeny, 'R', c4,
        i.exec_count,            'R', c5,
        i.uid#,                  'R', c6,
        i.dep,                   'R', c7,
        ' '||SUBSTR(trca$g.flatten_text(i.sql_text_prefix||i.sql_text), 1, 80), 'L', c8,
        i.hv,                    'R', c9 ,
        i.sqlid,                 'R', c10,
        i.plh,                   'R', c11 ));
      END LOOP;

      printf(LF||
      '(1) Percent of "Total Response Time Accounted-for", which is '||rtf_rec.accounted_for_response_time||' secs.'||LF||
      '(2) "Self Response Time Accounted-for" in secs (caused by this SQL statement).'||LF||
      '(3) "Recursive Response Time Accounted-for" in secs (caused by recursive SQL invoked by this statement).');
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display sql genealogy: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Individual SQL
     * ------------------------- */
    l_phase := 'individual_sql';
    print_log('-> '||l_phase);

    DECLARE
      l_row INTEGER := 0;
      cols INTEGER := 14;
      c1   INTEGER := 2;
      c2   INTEGER := 5;
      c3   INTEGER := 8;
      c4   INTEGER := 10;
      c5   INTEGER := 9;
      c6   INTEGER := 10;
      c7   INTEGER := 11;
      c8   INTEGER := 11;
      c9   INTEGER := 10;
      c10  INTEGER := 6;
      c11  INTEGER := 7;
      c12  INTEGER := 10;
      c13  INTEGER := 12;
      c14  INTEGER := 8;
      c15  INTEGER := 12;
      c16  INTEGER := 6;

    BEGIN
      printf(LF||LF||
      'INDIVIDUAL SQL'||LF||
      '~~~~~~~~~~~~~~'||LF);

      SELECT GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(rank)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(contribution)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(response_time_self)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(elapsed_time_self)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(cpu_time_self)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(non_idle_wait)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(idle_wait)), 0) + GAP, c8),
             GREATEST(NVL(MAX(LENGTH(exec_count)), 0) + GAP, c9),
             GREATEST(NVL(MAX(LENGTH(uid#)), 0) + GAP, c10),
             GREATEST(NVL(MAX(LENGTH(dep)), 0) + GAP, c11),
             GREATEST(NVL(MAX(LENGTH(SUBSTR(trca$g.flatten_text(sql_text), 1, 40))), 0) + GAP, c12),
             GREATEST(NVL(MAX(LENGTH(hv)), 0) + GAP, c13),
             GREATEST(NVL(MAX(LENGTH(sqlid)), 0) + GAP, c14),
             GREATEST(NVL(MAX(LENGTH(plh)), 0) + GAP, c15),
             GREATEST(NVL(MAX(LENGTH(first_cursor_timestamp)), 0) + GAP, c16)
        INTO c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16
        FROM trca$_sql_vf
       WHERE tool_execution_id = p_tool_execution_id;

      printf('List of individual SQL in order of first appearance in trace.');

      IF trca$g.g_include_internal_sql = 'N' AND trca$g.g_include_non_top_sql = 'N' THEN
        printf('Further details for internal and non-top SQL are excluded as per corresponding tool configuration parameters.');
      ELSIF trca$g.g_include_internal_sql = 'N' THEN
        printf('Further details for internal SQL are excluded as per corresponding tool configuration parameter.');
      ELSIF trca$g.g_include_non_top_sql = 'N' THEN
        printf('Further details for non-top SQL are excluded as per corresponding tool configuration parameter.');
      END IF;

      IF trca$g.g_sqlid = 'Y' THEN
        cols := cols + 1;
      END IF;
      IF trca$g.g_plh = 'Y' THEN
        cols := cols + 1;
      END IF;

      printf(LF||
      title_and_value(cols,
      NULL,      'R', c1,
      NULL,      'R', c2,
      'Trace',   'R', c3,
      'Self',    'R', c4,
      NULL,      'R', c5,
      NULL,      'R', c6,
      NULL,      'R', c7,
      NULL,      'R', c8,
      NULL,      'R', c9,
      NULL,      'R', c10,
      NULL,      'R', c11,
      NULL,      'R', c12,
      NULL,      'R', c13,
      NULL,      'R', c14,
      'Plan',    'R', c15,
      NULL,      'R', c16 )||LF||
      title_and_value(cols,
      NULL,       'R', c1,
      NULL,       'R', c2,
      'RT',       'R', c3,
      'Response', 'R', c4,
      'Elapsed',  'R', c5,
      NULL,       'R', c6,
      'Non-Idle', 'R', c7,
      'Idle',     'R', c8,
      'Exec',     'R', c9,
      NULL,       'R', c10,
      NULL,       'R', c11,
      NULL,       'R', c12,
      NULL,       'R', c13,
      NULL,       'R', c14,
      'Hash',     'R', c15,
      'First',    'R', c16 )||LF||
      title_and_value(cols,
      '# ',         'R', c1,
      'Rank',       'R', c2,
      'Pct(1)',     'R', c3,
      'Time(2)',    'R', c4,
      'Time',       'R', c5,
      'CPU Time',   'R', c6,
      'Wait Time',  'R', c7,
      'Wait Time',  'R', c8,
      'Count',      'R', c9,
      'User',       'R', c10,
      'Depth',      'R', c11,
      'SQL Text ',  'C', c12,
      'Hash Value', 'R', c13,
      'SQL ID',     'R', c14,
      'Value',      'R', c15,
      'Call',       'R', c16 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),      'R', c1,
      SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
      SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
      SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
      SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
      SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
      SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
      SUBSTR(DASHES, 1, c11 - 1), 'R', c11,
      SUBSTR(DASHES, 1, c12 - 1), 'R', c12,
      SUBSTR(DASHES, 1, c13 - 1), 'R', c13,
      SUBSTR(DASHES, 1, c14 - 1), 'R', c14,
      SUBSTR(DASHES, 1, c15 - 1), 'R', c15,
      SUBSTR(DASHES, 1, c16 - 1), 'R', c16 ));

      FOR i IN (SELECT *
                  FROM trca$_sql_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       first_cursor_id)
      LOOP
        l_row := l_row + 1;
        printf(title_and_value(cols,
        l_row||':',               'R', c1,
        i.rank,                   'R', c2,
        i.contribution,           'R', c3,
        i.response_time_self,     'R', c4,
        i.elapsed_time_self,      'R', c5,
        i.cpu_time_self,          'R', c6,
        i.non_idle_wait,          'R', c7,
        i.idle_wait,              'R', c8,
        i.exec_count,             'R', c9,
        i.uid#,                   'R', c10,
        i.dep,                    'R', c11,
        ' '||SUBSTR(trca$g.flatten_text(i.sql_text), 1, 40), 'L', c12,
        i.hv,                     'R', c13,
        i.sqlid,                  'R', c14,
        i.plh,                    'R', c15,
        i.first_cursor_timestamp, 'R', c16 ));
      END LOOP;

      printf(LF||
      '(1) Percent of "Total Response Time Accounted-for", which is '||rtf_rec.accounted_for_response_time||' secs.'||LF||
      '(2) "Self Response Time Accounted-for" in secs (caused by this SQL statement).');

      printf(LF||SEPARATOR||LF);
      FOR i IN (SELECT group_id
                  FROM trca$_sql_vf
                 WHERE tool_execution_id = p_tool_execution_id
                   AND (include_details = 'Y' OR trca$g.g_include_non_top_sql = 'Y')
                 ORDER BY
                       first_cursor_id)
      LOOP
        gen_html_group (
          p_tool_execution_id => p_tool_execution_id,
          p_group_id          => i.group_id );
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display individual sql: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Overall Segment I/O Wait Summary
     * ------------------------- */
    l_phase := 'i/o_wait_summary';
    print_log('-> '||l_phase);

    DECLARE
      l_count INTEGER;
      l_row INTEGER := 0;
      cols INTEGER := 11;
      c1   INTEGER := 2;
      c2   INTEGER := 5;
      c3   INTEGER := 6;
      c4   INTEGER := 17;
      c5   INTEGER := 12;
      c6   INTEGER := 9;
      c7   INTEGER := 8;
      c8   INTEGER := 11;
      c9   INTEGER := 11;
      c10  INTEGER := 8;
      c11  INTEGER := 9;

    BEGIN
      printf(LF||
      'OVERALL SEGMENT I/O WAIT SUMMARY'||LF||
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'||LF);

      SELECT COUNT(*),
             GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(obj#)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(segment_type)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(segment_name)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(event_name)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(wait_time)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(times_waited)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(avg_wait_time)), 0) + GAP, c8),
             GREATEST(NVL(MAX(LENGTH(max_wait_time)), 0) + GAP, c9),
             GREATEST(NVL(MAX(LENGTH(blocks)), 0) + GAP, c10),
             GREATEST(NVL(MAX(LENGTH(avg_blocks)), 0) + GAP, c11)
        INTO l_count, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11
        FROM trca$_trc_wait_segment_vf
       WHERE tool_execution_id = p_tool_execution_id;

      IF trca$g.g_include_waits = 'N' OR
         trca$g.g_include_segments = 'N' THEN
        printf('This section is disabled as per corresponding tool configuartion parameter(s).');
      ELSIF l_count > 0 THEN
        printf('Aggregate view of I/O wait events per segment, ordered by wait time.');

        printf(LF||
        title_and_value(cols,
        NULL,      'R', c1,
        NULL,      'R', c2,
        NULL,      'R', c3,
        NULL,      'R', c4,
        NULL,      'R', c5,
        'Wait',    'R', c6,
        'Times',   'R', c7,
        'Average', 'R', c8,
        'Max',     'R', c9,
        NULL,      'R', c10,
        'Average', 'R', c11 )||LF||
        title_and_value(cols,
        '# ',               'R', c1,
        'Obj',              'R', c2,
        'Type ',            'C', c3,
        'Segment Name(1) ', 'C', c4,
        'Event Name ',      'C', c5,
        'Time(2)',          'R', c6,
        'Waited',           'R', c7,
        'Wait Time',        'R', c8,
        'Wait Time',        'R', c9,
        'Blocks',           'R', c10,
        'Blocks',           'R', c11 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),      'R', c1,
        SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
        SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
        SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
        SUBSTR(DASHES, 1, c10 - 1), 'R', c10,
        SUBSTR(DASHES, 1, c11 - 1), 'R', c11 ));

        FOR i IN (SELECT *
                    FROM trca$_trc_wait_segment_vf
                   WHERE tool_execution_id = p_tool_execution_id
                   ORDER BY
                         wait DESC,
                         times_waited DESC,
                         blocks DESC)
        LOOP
          l_row := l_row + 1;
          printf(title_and_value(cols,
          l_row||':',          'R', c1,
          i.obj#,              'R', c2,
          ' '||i.segment_type, 'L', c3,
          ' '||i.segment_name, 'L', c4,
          ' '||i.event_name,   'L', c5,
          i.wait_time,         'R', c6,
          i.times_waited,      'R', c7,
          i.avg_wait_time,     'R', c8,
          i.max_wait_time,     'R', c9,
          i.blocks,            'R', c10,
          i.avg_blocks,        'R', c11 ));
        END LOOP;

        printf(LF||
        '(1) Content based on '||trca$g.g_tool_name||' data dictionary (dbid:'||trca$g.g_dict_database_id||', host:'||trca$g.g_dict_host_name||').'||LF||
        '(2) This list is constrained by threshold configuration parameter with current value of '||trca$g.g_wait_time_th||'s.');
      ELSE
        printf('There are no I/O wait events in trace file analyzed.');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display i/o wait summary: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Hot I/O Blocks
     * ------------------------- */
    l_phase := 'hot_i/o_blocks';
    print_log('-> '||l_phase);

    DECLARE
      l_count INTEGER;
      l_row INTEGER := 0;
      cols INTEGER := 11;
      c1   INTEGER := 2;
      c2   INTEGER := 5;
      c3   INTEGER := 6;
      c4   INTEGER := 17;
      c5   INTEGER := 12;
      c6   INTEGER := 9;
      c7   INTEGER := 8;
      c8   INTEGER := 11;
      c9   INTEGER := 11;

    BEGIN
      printf(LF||
      'HOT I/O BLOCKS'||LF||
      '~~~~~~~~~~~~~~'||LF);

      SELECT COUNT(*),
             GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(file#)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(block)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(obj#)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(segment_type)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(segment_name)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(wait_time)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(times_waited)), 0) + GAP, c8),
             GREATEST(NVL(MAX(LENGTH(max_wait_time)), 0) + GAP, c9)
        INTO l_count, c1, c2, c3, c4, c5, c6, c7, c8, c9
        FROM trca$_hot_block_segment_vf
       WHERE tool_execution_id = p_tool_execution_id;

      IF trca$g.g_include_waits = 'N' OR TO_NUMBER(trca$g.g_hot_block_th) = 0 THEN
        printf('This section is disabled as per corresponding tool configuartion parameter(s).');
      ELSIF l_count > 0 THEN
        printf('List of blocks with largest wait time or times waited.');

        printf(LF||
        title_and_value(cols,
        NULL,      'R', c1,
        NULL,      'R', c2,
        NULL,      'R', c3,
        NULL,      'R', c4,
        NULL,      'R', c5,
        NULL,      'R', c6,
        'Wait',    'R', c7,
        'Times',   'R', c8,
        'Max',     'R', c9 )||LF||
        title_and_value(cols,
        '# ',               'R', c1,
        'File',             'R', c2,
        'Block',            'R', c3,
        'Obj',              'R', c4,
        'Type ',            'C', c5,
        'Segment Name(1) ', 'C', c6,
        'Time',             'R', c7,
        'Waited',           'R', c8,
        'Wait Time',        'R', c9 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),      'R', c1,
        SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
        SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
        SUBSTR(DASHES, 1, c9  - 1), 'R', c9 ));

        FOR i IN (SELECT *
                    FROM trca$_hot_block_segment_vf
                   WHERE tool_execution_id = p_tool_execution_id
                   ORDER BY
                         wait DESC,
                         times_waited DESC)
        LOOP
          l_row := l_row + 1;
          printf(title_and_value(cols,
          l_row||':',          'R', c1,
          i.file#,             'R', c2,
          i.block,             'R', c3,
          i.obj#,              'R', c4,
          ' '||i.segment_type, 'L', c5,
          ' '||i.segment_name, 'L', c6,
          i.wait_time,         'R', c7,
          i.times_waited,      'R', c8,
          i.max_wait_time,     'R', c9 ));
        END LOOP;

        printf(LF||
        '(1) Content based on '||trca$g.g_tool_name||' data dictionary (dbid:'||trca$g.g_dict_database_id||', host:'||trca$g.g_dict_host_name||').');
      ELSE
        printf('There are no I/O wait events in trace file analyzed.');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display hot i/o blocks: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Gaps in Trace
     * ------------------------- */
    l_phase := 'gaps_in_trace';
    print_log('-> '||l_phase);

    DECLARE
      l_count INTEGER;
      l_row INTEGER := 0;
      cols INTEGER := 3;
      c1   INTEGER := 2;
      c2   INTEGER := 15;
      c3   INTEGER := 9;
      c4   INTEGER := 10;

    BEGIN
      printf(LF||LF||
      'GAPS IN TRACE'||LF||
      '~~~~~~~~~~~~~'||LF);

      SELECT COUNT(*),
             GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(gap_timestamp)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(gap_duration)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(file_name)), 0) + GAP, c4)
        INTO l_count, c1, c2, c3, c4
        FROM trca$_gap_vf
       WHERE tool_execution_id = p_tool_execution_id;

      IF TO_NUMBER(trca$g.g_gaps_th) = 0 THEN
        printf('This section is disabled as per corresponding tool configuartion parameter.');
      ELSIF l_count > 0 THEN
        IF l_count > TO_NUMBER(trca$g.g_gaps_th) THEN
           printf('List of up to '||trca$g.g_gaps_th||' gaps found in trace(s) with corresponding approximate duration in seconds (ordered by gap time).');
        ELSE
           printf('List of gaps found in trace(s) with corresponding approximate duration in seconds (ordered by gap time).');
        END IF;

        IF tool_rec.file_count > 1 THEN
          cols := 4;
        END IF;

        printf(LF||
        title_and_value(cols,
        NULL,      'R', c1,
        NULL,      'R', c2,
        'Gap',     'R', c3,
        NULL,      'R', c4 )||LF||
        title_and_value(cols,
        '# ',             'R', c1,
        'Gap Timestamp ', 'C', c2,
        'Time(1)',        'R', c3,
        'Filename ',      'C', c4 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),      'R', c1,
        SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4  - 1), 'R', c4 ));

        FOR i IN (SELECT *
                    FROM trca$_gap_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND ROWNUM <= TO_NUMBER(trca$g.g_gaps_th)
                   ORDER BY
                         trace_id,
                         gap_duration DESC)
        LOOP
          l_row := l_row + 1;
          printf(title_and_value(cols,
          l_row||':',           'R', c1,
          ' '||i.gap_timestamp, 'L', c2,
          i.gap_duration,       'R', c3,
          ' '||i.file_name,     'L', c4 ));
        END LOOP;

        printf(LF||
        '(1) Blank if duration cannot be computed.');
      ELSE
        printf('There are no gaps in trace file(s) analyzed.');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display gaps in trace1: '||SQLERRM);
    END;

    DECLARE
      l_count INTEGER;
      l_row INTEGER := 0;
      cols INTEGER := 9;
      c1   INTEGER := 2;
      c2   INTEGER := 15;
      c3   INTEGER := 7;
      c4   INTEGER := 6;
      c5   INTEGER := 5;
      c6   INTEGER := 9;
      c7   INTEGER := 16;
      c8   INTEGER := 10;
      c9   INTEGER := 12;
      c10  INTEGER := 8;

    BEGIN
      SELECT COUNT(*),
             GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(gap_timestamp)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(dep)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(call_type)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(cpu)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(elapsed)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(call_timestamp)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(SUBSTR(trca$g.flatten_text(sql_text), 1, 50))), 0) + GAP, c8),
             GREATEST(NVL(MAX(LENGTH(hv)), 0) + GAP, c9),
             GREATEST(NVL(MAX(LENGTH(sqlid)), 0) + GAP, c10)
        INTO l_count, c1, c2, c3, c4, c5, c6, c7, c8, c9, c10
        FROM trca$_gap_call_vf
       WHERE tool_execution_id = p_tool_execution_id;

      IF TO_NUMBER(trca$g.g_gaps_th) = 0 THEN
        printf(LF||'This section is disabled as per corresponding tool configuartion parameter.');
      ELSIF l_count > 0 THEN
        IF l_count > TO_NUMBER(trca$g.g_gaps_th) THEN
           printf(LF||'List of up to '||trca$g.g_gaps_th||' recursive calls related to gaps found in trace.');
        ELSE
           printf(LF||'List of recursive calls related to gaps found in trace.');
        END IF;

        printf(LF||
        title_and_value(cols,
        NULL,    'R', c1,
        NULL,    'R', c2,
        'Call',  'R', c3,
        ' Call', 'L', c4,
        NULL,    'R', c5,
        NULL,    'R', c6,
        NULL,    'R', c7,
        NULL,    'R', c8,
        NULL,    'R', c9,
        NULL,    'R', c10 )||LF||
        title_and_value(cols,
        '# ',              'R', c1,
        'Gap Timestamp ',  'C', c2,
        'Depth',           'R', c3,
        ' Type',           'L', c4,
        'CPU',             'R', c5,
        'Elapsed',         'R', c6,
        'Call Timestamp ', 'C', c7,
        'SQL Text ',       'C', c8,
        'Hash Value',      'R', c9,
        'SQL ID',          'R', c10 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),      'R', c1,
        SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
        SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
        SUBSTR(DASHES, 1, c9  - 1), 'R', c9,
        SUBSTR(DASHES, 1, c10 - 1), 'R', c10 ));

        FOR i IN (SELECT *
                    FROM trca$_gap_call_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND ROWNUM <= TO_NUMBER(trca$g.g_gaps_th)
                   ORDER BY
                         gap_id,
                         dep DESC)
        LOOP
          l_row := l_row + 1;
          printf(title_and_value(cols,
          l_row||':',            'R', c1,
          ' '||i.gap_timestamp,  'L', c2,
          i.dep,                 'R', c3,
          ' '||i.call_type,      'L', c4,
          i.cpu,                 'R', c5,
          i.elapsed,             'R', c6,
          ' '||i.call_timestamp, 'L', c7,
          ' '||SUBSTR(trca$g.flatten_text(i.sql_text), 1, 50), 'L', c8,
          i.hv,                  'R', c9,
          i.sqlid,               'R', c10 ));
        END LOOP;
      ELSE
        printf(LF||'There are no recursive calls related to gaps in trace.');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display gaps in trace2: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * ORA errors in Trace
     * ------------------------- */
    l_phase := 'ora_errors_in_trace';
    print_log('-> '||l_phase);

    DECLARE
      l_count INTEGER;
      l_row INTEGER := 0;
      cols INTEGER := 5;
      c1   INTEGER := 2;
      c2   INTEGER := 7;
      c3   INTEGER := 17;
      c4   INTEGER := 10;
      c5   INTEGER := 12;
      c6   INTEGER := 8;

    BEGIN
      printf(LF||LF||
      'ORA ERRORS IN TRACE'||LF||
      '~~~~~~~~~~~~~~~~~~~'||LF);

      SELECT COUNT(*),
             GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(ora_error)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(error_timestamp)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(SUBSTR(trca$g.flatten_text(sql_text), 1, 50))), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(hv)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(sqlid)), 0) + GAP, c6)
        INTO l_count, c1, c2, c3, c4, c5, c6
        FROM trca$_error_vf
       WHERE tool_execution_id = p_tool_execution_id;

      IF TO_NUMBER(trca$g.g_errors_th) = 0 THEN
        printf('This section is disabled as per corresponding tool configuartion parameter.');
      ELSIF l_count > 0 THEN
        IF l_count > TO_NUMBER(trca$g.g_errors_th) THEN
           printf('List of up to '||trca$g.g_errors_th||' Oracle errors found in trace(s).');
        ELSE
           printf('List of Oracle errors found in trace(s).');
        END IF;

        IF trca$g.g_sqlid = 'Y' THEN
          cols := cols + 1;
        END IF;

        printf(LF||
        title_and_value(cols,
        '# ',               'R', c1,
        'Error ',           'C', c2,
        'Error Timestamp ', 'C', c3,
        'SQL Text ',        'C', c4,
        'Hash Value',       'R', c5,
        'SQL ID',           'R', c6 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),      'R', c1,
        SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6  - 1), 'R', c6 ));

        FOR i IN (SELECT *
                    FROM trca$_error_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND ROWNUM <= TO_NUMBER(trca$g.g_errors_th)
                   ORDER BY
                         tim)
        LOOP
          l_row := l_row + 1;
          printf(title_and_value(cols,
          l_row||':',             'R', c1,
          ' '||i.ora_error,       'L', c2,
          ' '||i.error_timestamp, 'L', c3,
          ' '||SUBSTR(trca$g.flatten_text(i.sql_text), 1, 50), 'L', c4,
          i.hv,                   'R', c5,
          i.sqlid,                'R', c6 ));
        END LOOP;
      ELSE
        printf('There are no Oracle errors in trace.');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display errors in trace: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Transactions Summary
     * ------------------------- */
    l_phase := 'transactions_summary';
    print_log('-> '||l_phase);

    DECLARE
      l_row INTEGER := 0;
      l_count INTEGER;
      cols INTEGER := 8;
      c1   INTEGER := 2;
      c2   INTEGER := 5;
      c3   INTEGER := 9;
      c4   INTEGER := 19;
      c5   INTEGER := 11;
      c6   INTEGER := 13;
      c7   INTEGER := 11;
      c8   INTEGER := 13;
      c9   INTEGER := 10;

    BEGIN
      printf(LF||LF||
      'TRANSACTIONS SUMMARY'||LF||
      '~~~~~~~~~~~~~~~~~~~~'||LF);

      SELECT COUNT(*),
             GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(sid)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(serial#)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(session_timestamp)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(read_only_committed)), 0) + GAP, c5),
             GREATEST(NVL(MAX(LENGTH(read_only_rollbacked)), 0) + GAP, c6),
             GREATEST(NVL(MAX(LENGTH(update_committed)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(update_rollbacked)), 0) + GAP, c7),
             GREATEST(NVL(MAX(LENGTH(file_name)), 0) + GAP, c9)
        INTO l_count, c1, c2, c3, c4, c5, c6, c7, c8, c9
        FROM trca$_session_vf
       WHERE tool_execution_id = p_tool_execution_id;

      IF l_count = 0 THEN
        printf('There are no session information recorder in trace(s). Thus this section is not available.');
      ELSE
        printf('List of sessions recognized in trace(s), including transaction counts per type.');

        IF tool_rec.file_count > 1 THEN
          cols := 9;
        END IF;

        printf(LF||
        title_and_value(cols,
        NULL,   'R', c1,
        NULL,   'R', c2,
        NULL,   'R', c3,
        NULL,   'R', c4,
        'Type', 'R', c5,
        'Type', 'R', c6,
        'Type', 'R', c7,
        'Type', 'R', c8,
        NULL,   'R', c9 )||LF||
        title_and_value(cols,
        NULL,        'R', c1,
        NULL,        'R', c2,
        NULL,        'R', c3,
        NULL,        'R', c4,
        'Read-only', 'R', c5,
        'Read-only', 'R', c6,
        'Update',    'R', c7,
        'Update',    'R', c8,
        NULL,        'R', c9 )||LF||
        title_and_value(cols,
        '# ',                 'R', c1,
        'SID',                'R', c2,
        'Serial#',            'R', c3,
        'Session Timestamp ', 'C', c4,
        'Committed',          'R', c5,
        'Rolled-back',        'R', c6,
        'Committed',          'R', c7,
        'Rolled-back',        'R', c8,
        'Filename ',          'C', c9 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),      'R', c1,
        SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
        SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
        SUBSTR(DASHES, 1, c5  - 1), 'R', c5,
        SUBSTR(DASHES, 1, c6  - 1), 'R', c6,
        SUBSTR(DASHES, 1, c7  - 1), 'R', c7,
        SUBSTR(DASHES, 1, c8  - 1), 'R', c8,
        SUBSTR(DASHES, 1, c9  - 1), 'R', c9 ));

        FOR i IN (SELECT *
                    FROM trca$_session_vf
                   WHERE tool_execution_id = p_tool_execution_id
                   ORDER BY
                         trace_id,
                         session_id)
        LOOP
          l_row := l_row + 1;
          printf(title_and_value(cols,
          l_row||':',               'R', c1,
          i.sid,                    'R', c2,
          i.serial#,                'R', c3,
          ' '||i.session_timestamp, 'L', c4,
          i.read_only_committed,    'R', c5,
          i.read_only_rollbacked,   'R', c6,
          i.update_committed,       'R', c7,
          i.update_rollbacked,      'R', c8,
          ' '||i.file_name,         'L', c9 ));
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display transactions summary: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Non-default Initialization Params
     * ------------------------- */
    l_phase := 'init.ora_params';
    print_log('-> '||l_phase);

    DECLARE
      l_row INTEGER := 0;
      cols INTEGER := 3;
      c1   INTEGER := 2;
      c2   INTEGER := 11;
      c3   INTEGER := 10;

    BEGIN
      printf(LF||LF||
      'NON-DEFAULT INITIALIZATION PARAMS'||LF||
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'||LF);

      SELECT GREATEST(NVL(LENGTH(COUNT(*)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(name)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(value)), 0) + GAP, c3)
        INTO c1, c2, c3
        FROM trca$_parameter2$;

      IF trca$g.g_include_init_ora = 'N' THEN
        printf('This section is disabled as per corresponding tool configuartion parameter.');
      ELSE
        printf('List of non-default parameters.');

        printf(LF||
        title_and_value(cols,
        '# ',         'R', c1,
        'Parameter ', 'C', c2,
        'Value(1) ',  'C', c3 )||LF||
        title_and_value(cols,
        SUBSTR(DASHES, 1, c1),      'R', c1,
        SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
        SUBSTR(DASHES, 1, c3  - 1), 'R', c3 ));

        FOR i IN (SELECT name, value
                    FROM trca$_parameter2$
                   ORDER BY
                         name,
                         value)
        LOOP
          l_row := l_row + 1;
          printf(title_and_value(cols,
          l_row||':',   'R', c1,
          ' '||i.name,  'L', c2,
          ' '||i.value, 'L', c3 ));
        END LOOP;

        printf(LF||
        '(1) Content based on '||trca$g.g_tool_name||' data dictionary (dbid:'||trca$g.g_dict_database_id||', host:'||trca$g.g_dict_host_name||').');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display init.ora params: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Trace Header
     * ------------------------- */
    l_phase := 'trace_header';
    print_log('-> '||l_phase);

    BEGIN
      printf(LF||LF||
      'TRACE HEADER'||LF||
      '~~~~~~~~~~~~');

      FOR i IN (SELECT *
                  FROM trca$_trace
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       id)
      LOOP
        printf(LF||i.file_name||' ('||i.file_len||' bytes)'||LF);

        FOR j IN (SELECT *
                    FROM trca$_trace_header
                   WHERE trace_id = i.id
                     AND tool_execution_id = p_tool_execution_id
                     AND REPLACE(text, ' ') IS NOT NULL
                   ORDER BY
                         piece)
        LOOP
          printf(TRIM(LF FROM j.text));
        END LOOP;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display trace header: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Tool Data Dictionary
     * ------------------------- */
    l_phase := 'tool_dict';
    print_log('-> '||l_phase);

    DECLARE
      cols INTEGER := 2;
      c1   INTEGER := 18;
      c2   INTEGER := 200;
    BEGIN
      printf(LF||LF||
      'TOOL DATA DICTIONARY'||LF||
      '~~~~~~~~~~~~~~~~~~~~'||LF||LF||
      title_and_value(cols,
      'Refresh Date: ',            'R', c1,
       trca$g.g_dict_refresh_date, 'L', c2)||LF||
      title_and_value(cols,
      'Refresh Days: ',            'R', c1,
       trca$g.g_dict_refresh_days, 'L', c2)||LF||
      title_and_value(cols,
      'Database: ',                                                      'R', c1,
       trca$g.g_dict_database_name||'('||trca$g.g_dict_database_id||')', 'L', c2)||LF||
      title_and_value(cols,
      'Instance: ',                                                      'R', c1,
       trca$g.g_dict_instance_name||'('||trca$g.g_dict_instance_id||')', 'L', c2)||LF||
      title_and_value(cols,
      'Host: ',                 'R', c1,
       trca$g.g_dict_host_name, 'L', c2)||LF||
      title_and_value(cols,
      'Platform: ',            'R', c1,
       trca$g.g_dict_platform, 'L', c2)||LF||
      title_and_value(cols,
      'RDBMS Version: ',            'R', c1,
       trca$g.g_dict_rdbms_version, 'L', c2)||LF||
      title_and_value(cols,
      'DB Files: ',            'R', c1,
       trca$g.g_dict_db_files, 'L', c2));

    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display tool dict: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Tool Execution Environment
     * ------------------------- */
    l_phase := 'tool_environment';
    print_log('-> '||l_phase);

    DECLARE
      cols INTEGER := 2;
      c1   INTEGER := 18;
      c2   INTEGER := 200;
    BEGIN
      printf(LF||LF||
      'TOOL EXECUTION ENVIRONMENT'||LF||
      '~~~~~~~~~~~~~~~~~~~~~~~~~~'||LF||LF||
      --title_and_value(cols,
      --'Execution ID: ',    'R', c1,
      --p_tool_execution_id, 'L', c2)||LF||
      title_and_value(cols,
      'Database: ',                                                      'R', c1,
       trca$g.g_tool_database_name||'('||trca$g.g_tool_database_id||')', 'L', c2)||LF||
      title_and_value(cols,
      'Instance: ',                                                      'R', c1,
       trca$g.g_tool_instance_name||'('||trca$g.g_tool_instance_id||')', 'L', c2)||LF||
      title_and_value(cols,
      'Host: ',                 'R', c1,
       trca$g.g_tool_host_name, 'L', c2)||LF||
      title_and_value(cols,
      'Platform: ',            'R', c1,
       trca$g.g_tool_platform, 'L', c2)||LF||
      title_and_value(cols,
      'RDBMS Version: ',            'R', c1,
       trca$g.g_tool_rdbms_version, 'L', c2)||LF||
      title_and_value(cols,
      'RDBMS Release: ',                                                         'R', c1,
       trca$g.g_tool_rdbms_release||'('||trca$g.g_tool_rdbms_version_short||')', 'L', c2)||LF||
      title_and_value(cols,
      'DB Files: ',            'R', c1,
       trca$g.g_tool_db_files, 'L', c2)||LF||
      title_and_value(cols,
      'Product Version: ',            'R', c1,
       trca$g.g_tool_product_version, 'L', c2)||LF||
      title_and_value(cols,
      'User: ',             'R', c1,
       USER||'('||UID||')', 'L', c2)||LF||
      title_and_value(cols,
      'Input Directory: ', 'R', c1,
       l_directory_path,   'L', c2)||LF||
      title_and_value(cols,
      'Stage Directory: ',                            'R', c1,
       trca$g.get_directory_path(trca$g.g_stage_dir), 'L', c2));

    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display tool environment: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Tool Configuration Parameters
     * ------------------------- */
    l_phase := 'tool_configuration';
    print_log('-> '||l_phase);

    DECLARE
      cols INTEGER := 5;
      c1   INTEGER := 16;
      c2   INTEGER := 6;
      c3   INTEGER := 10;
      c4   INTEGER := 9;
      c5   INTEGER := 14;

    BEGIN
      printf(LF||LF||
      'TOOL CONFIGURATION PARAMETERS'||LF||
      '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');

      SELECT GREATEST(NVL(MAX(LENGTH(description)), 0) + GAP, c1),
             GREATEST(NVL(MAX(LENGTH(name)), 0) + GAP, c2),
             GREATEST(NVL(MAX(LENGTH(value)), 0) + GAP, c3),
             GREATEST(NVL(MAX(LENGTH(default_value)), 0) + GAP, c4),
             GREATEST(NVL(MAX(LENGTH(instructions)), 0) + GAP, c5)
        INTO c1, c2, c3, c4, c5
        FROM trca$_tool_parameter
       WHERE hidden = 'N';

      printf(LF||
      title_and_value(cols,
      'Description(1) ', 'C', c1,
      'Name ',           'C', c2,
      'Value(2) ',       'C', c3,
      'Default ',        'C', c4,
      'Instructions ',   'C', c5 )||LF||
      title_and_value(cols,
      SUBSTR(DASHES, 1, c1),      'R', c1,
      SUBSTR(DASHES, 1, c2  - 1), 'R', c2,
      SUBSTR(DASHES, 1, c3  - 1), 'R', c3,
      SUBSTR(DASHES, 1, c4  - 1), 'R', c4,
      SUBSTR(DASHES, 1, c5  - 1), 'R', c5 ));

      FOR i IN (SELECT *
                  FROM trca$_tool_parameter
                 WHERE hidden = 'N'
                 ORDER BY
                       id)
      LOOP
        printf(title_and_value(cols,
        i.description,        'L', c1,
        ' '||i.name,          'L', c2,
        ' '||i.value,         'L', c3,
        ' '||i.default_value, 'L', c4,
        ' '||i.instructions,  'L', c5 ));
      END LOOP;

      printf(LF||
      '(1) For detailed parameter description, refer to trca/instructions.txt'||LF||
      '(2) To set a parameter: SQL> EXEC '||LOWER(trca$g.g_tool_administer_schema)||'.trca$g.set_param(''Name'', ''Value'');');
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display tool configuration: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Footer and closure
     * ------------------------- */
    l_phase := 'footer';
    print_log('-> '||l_phase);

    BEGIN
      printf(LF||SEPARATOR||LF||
      trca$g.g_tool_name||' '||trca$g.g_tool_version||' secs:'||
      TO_CHAR(ROUND((SYSDATE - tool_rec.parse_start) * 24 * 3600, 3))||
      ' '||TO_CHAR(SYSDATE, LONG_DATE_FORMAT));
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display footer: '||SQLERRM);
    END;

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    INSERT INTO trca$_file VALUES s_file_rec;
    COMMIT;
    x_text_report := s_file_rec.file_text;
    print_log('<= gen_text_report');

  EXCEPTION
    WHEN OTHERS THEN
      print_log(l_phase||' '||SQLERRM);
      RAISE;
  END gen_text_report;

  /*************************************************************************************/

END trca$x;
/

SET TERM ON;
SHOW ERRORS;
