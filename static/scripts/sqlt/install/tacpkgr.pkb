CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..trca$r AS
/* $Header: 224270.1 tacpkgr.pkb 11.4.5.0 2012/11/21 carlos.sierra $ */

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  LF                   CONSTANT VARCHAR2(32767) := CHR(10); -- line feed
  CR                   CONSTANT VARCHAR2(32767) := CHR(13); -- carriage return
  AMP                  CONSTANT VARCHAR2(32767) := CHR(38);
  SPECIAL_CHAR         CONSTANT VARCHAR2(32767) := CHR(96);
  HQUOT                CONSTANT VARCHAR2(32767) := AMP||'quot;';
  HAPOS                CONSTANT VARCHAR2(32767) := AMP||'#039;';
  NBSP                 CONSTANT VARCHAR2(32767) := AMP||'nbsp;';
  MAX_STRING_SZ        CONSTANT INTEGER         := 200;
  LONG_DATE_FORMAT     CONSTANT VARCHAR2(32767) := 'YYYY-MON-DD HH24:MI:SS';
  USYS                 CONSTANT INTEGER :=  0;
  BACK_TOP             CONSTANT VARCHAR2(32767) := '<font class="goto"><a href="#toc">Go to Top</a></font><br>';

  /*************************************************************************************/

  /* -------------------------
   *
   * private static
   *
   * ------------------------- */
  s_file_rec trca$_file%ROWTYPE;
  s_snap_id INTEGER := 0;

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
    trca$g.print_log(p_buffer => p_line, p_package => 'R');
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
      SYS.DBMS_OUTPUT.PUT_LINE('*** Module: trca$r.printf');
      SYS.DBMS_OUTPUT.PUT_LINE('*** Buffer: "'||SUBSTR(p_buffer, 1, 200)||'"');
      SYS.DBMS_OUTPUT.PUT_LINE('*** '||SQLERRM);
      SYS.DBMS_OUTPUT.PUT_LINE('***');
      RAISE;
  END printf;

  /*************************************************************************************/

  /* -------------------------
   *
   * private form_string
   *
   * ------------------------- */
  FUNCTION form_string (
    p_text IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_text   VARCHAR2(32767);
    l_result VARCHAR2(32767) := NULL;
    l_instr  INTEGER;
  BEGIN /* form_string */
    l_text := REPLACE(REPLACE(p_text, '''', HAPOS), '"', HQUOT);
    l_text := REPLACE(l_text, CR, LF);
    l_text := REPLACE(l_text, LF||LF||LF, LF);
    l_text := REPLACE(l_text, LF||LF, LF);
    l_text := REPLACE(l_text, LF);

    WHILE NVL(LENGTH(l_text), 0) > 0
    LOOP
      IF NVL(LENGTH(l_text), 0) > MAX_STRING_SZ THEN
        l_instr := INSTR(SUBSTR(l_text, 1, MAX_STRING_SZ), AMP, -1);
        l_instr := GREATEST(l_instr, INSTR(SUBSTR(l_text, 1, MAX_STRING_SZ), '<', -1));
        l_instr := GREATEST(l_instr, INSTR(SUBSTR(l_text, 1, MAX_STRING_SZ), '(', -1));
        IF l_instr < MAX_STRING_SZ / 2 THEN
          l_result := l_result||SUBSTR(l_text, 1, MAX_STRING_SZ)||'" +'||LF||'"';
          l_text := SUBSTR(l_text, MAX_STRING_SZ + 1);
        ELSE
          l_result := l_result||SUBSTR(l_text, 1, l_instr - 1)||'" +'||LF||'"';
          l_text := SUBSTR(l_text, l_instr);
        END IF;
      ELSE
        l_result := l_result||l_text;
        l_text := NULL;
      END IF;
    END LOOP;

    --RETURN '"'||l_result||'"';
    RETURN l_result;
  END form_string;

  /*************************************************************************************/

  /* -------------------------
   *
   * private show_n_hide
   *
   * ------------------------- */
  FUNCTION show_n_hide (
    p_text    IN VARCHAR2,
    p_control IN VARCHAR2,
    p_display IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN
    s_snap_id := s_snap_id + 1;
    RETURN
    LF||'[<a href="javascript:void(0);" onclick="snh(''s'||s_snap_id||'c'', ''s'||s_snap_id||'t'');"><span id="s'||s_snap_id||'c">'||p_control||'</span></a>]'||
    LF||'<span id="s'||s_snap_id||'t" style="display:'||p_display||'">'||p_text;
  END show_n_hide;

  /*************************************************************************************/

  /* -------------------------
   *
   * private begin_show
   *
   * ------------------------- */
  FUNCTION begin_show (
    p_tag  IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN /* begin_show */
    RETURN show_n_hide(NULL, '-', 'block');
  END begin_show;

  /*************************************************************************************/

  /* -------------------------
   *
   * private begin_hide
   *
   * ------------------------- */
  FUNCTION begin_hide (
    p_tag  IN VARCHAR2,
    p_text IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN /* begin_hide */
    RETURN show_n_hide(NULL, '+', 'none')||form_string(p_text);
  END begin_hide;

  /*************************************************************************************/

  /* -------------------------
   *
   * private end_show_and_hide
   *
   * ------------------------- */
  FUNCTION end_show_and_hide
  RETURN VARCHAR2
  IS
  BEGIN /* end_show_and_hide */
    RETURN '</span>';
  END end_show_and_hide;

  /*************************************************************************************/

  /* -------------------------
   *
   * private title_and_value
   *
   * ------------------------- */
  FUNCTION title_and_value (
    p_title  IN VARCHAR2,
    p_value  IN VARCHAR2,
    p_value2 IN VARCHAR2 DEFAULT NULL,
    p_value3 IN VARCHAR2 DEFAULT NULL,
    p_value4 IN VARCHAR2 DEFAULT NULL,
    p_value5 IN VARCHAR2 DEFAULT NULL,
    p_value6 IN VARCHAR2 DEFAULT NULL,
    p_value7 IN VARCHAR2 DEFAULT NULL,
    p_class  IN VARCHAR2 DEFAULT 'right' )
  RETURN VARCHAR2
  IS
  BEGIN /* title_and_value */
    IF p_value IS NULL AND p_value2 IS NULL AND p_value3 IS NULL AND p_value4 IS NULL THEN
      RETURN NULL;
    ELSIF p_value2 IS NULL THEN
      RETURN '<tr><td class="title">'||p_title||'</td><td class="left">'||p_value||'</td></tr>'||LF;
    ELSIF p_value3 IS NULL THEN
      RETURN '<tr><td class="title">'||p_title||'</td><td class="'||p_class||'">'||p_value||
      '</td><td class="'||p_class||'">'||p_value2||'</td></tr>'||LF;
    ELSIF p_value4 IS NULL THEN
      RETURN '<tr><td class="title">'||p_title||'</td><td class="'||p_class||'">'||p_value||
      '</td><td class="'||p_class||'">'||p_value2||'</td><td class="'||p_class||'">'||p_value3||'</td></tr>'||LF;
    ELSIF p_value5 IS NULL THEN
      RETURN '<tr><td class="title">'||p_title||'</td><td class="'||p_class||'">'||p_value||
      '</td><td class="'||p_class||'">'||p_value2||'</td><td class="'||p_class||'">'||p_value3||
      '</td><td class="'||p_class||'">'||p_value4||'</td></tr>'||LF;
    ELSIF p_value6 IS NULL THEN
      RETURN '<tr><td class="title">'||p_title||'</td><td class="'||p_class||'">'||p_value||
      '</td><td class="'||p_class||'">'||p_value2||'</td><td class="'||p_class||'">'||p_value3||
      '</td><td class="'||p_class||'">'||p_value4||'</td><td class="'||p_class||'">'||p_value5||'</td></tr>'||LF;
    ELSIF p_value7 IS NULL THEN
      RETURN '<tr><td class="title">'||p_title||'</td><td class="'||p_class||'">'||p_value||
      '</td><td class="'||p_class||'">'||p_value2||'</td><td class="'||p_class||'">'||p_value3||
      '</td><td class="'||p_class||'">'||p_value4||'</td><td class="'||p_class||'">'||p_value5||'<td class="'||p_class||'">'||p_value6||'</td></tr>'||LF;
    ELSE
      RETURN '<tr><td class="title">'||p_title||'</td><td class="'||p_class||'">'||p_value||
      '</td><td class="'||p_class||'">'||p_value2||'</td><td class="'||p_class||'">'||p_value3||'<td class="'||p_class||'">'||p_value4||
      '</td><td class="'||p_class||'">'||p_value5||'</td><td class="'||p_class||'">'||p_value6||'<td class="'||p_class||'">'||p_value7||'</td></tr>'||LF;
    END IF;
  END title_and_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_uid_name
   *
   * ------------------------- */
  FUNCTION get_uid_name (
    p_uid IN NUMBER )
  RETURN VARCHAR2
  IS
    usr_rec trca$_users%ROWTYPE;
  BEGIN /* get_uid_name */
    IF p_uid = 0 THEN
      RETURN '<a title="SYS">'||p_uid||'</a>';
    ELSE
      SELECT * INTO usr_rec FROM trca$_users WHERE user_id = p_uid;
      RETURN '<a title="'||usr_rec.user_name||' (according to data dict repository)">'||p_uid||'</a>';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_uid;
  END get_uid_name;

  /*************************************************************************************/

  /* -------------------------
   *
   * private back_to_top
   *
   * ------------------------- */
  FUNCTION back_to_top (
    p_group_id IN INTEGER )
  RETURN VARCHAR2
  IS
  BEGIN /* back_to_top */
    RETURN '<font class="goto"><a href="#sql'||p_group_id||'">Go to Top</a></font><br>';
  END back_to_top;

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
      printf(LF||'<h3><a name="exec'||p_exec_id||'"></a> '||exec_vf.rank||' '||stm_rec.hv||' '||stm_rec.sqlid||' '||exec_v.plh||'</h3>'||LF);

      l_text := 'Rank:'||grp_rec.rank||'.'||exec_vf.rank||'(<a title="Percent of SQL Response Time Accounted-for">'||exec_vf.grp_contribution||'</a>)(<a title="Percent of Total Response Time Accounted-for">'||exec_vf.trc_contribution||'</a>) ';
      IF (grp_rec.top_sql = 'Y' OR grp_rec.top_sql_et = 'Y' OR grp_rec.top_sql_ct = 'Y') AND exec_vf.top_exec = 'Y' THEN
        l_text := '<font color="#FF0000">'||l_text||'</font>';
      END IF;

      l_text := l_text||'Self:'||exec_vf.response_time_self||'s ';
      l_text := l_text||'Recursive:'||exec_vf.response_time_progeny||'s ';
      printf(l_text);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display exec title for '||p_group_id||': '||SQLERRM);
    END;

    /* -------------------------
     * Exec Self - Time, Totals, Waits, Binds and Fetches
     * ------------------------- */
    IF exec_v.response_time_self > 0 THEN

      printf('<br><br>'||LF||
      begin_show('SHSTTE'||p_exec_id)||LF);

      -- time
      BEGIN
        printf(
        '<table>'||LF||
        '<tr>'||LF||
        '<th>Call</th>'||LF||
        '<th>Response Time<br>Accounted-for</th>'||LF||
        '<th>Elapsed<br>Time</th>'||LF||
        '<th>CPU Time</th>'||LF||
        '<th>Non-Idle<br>Wait Time</th>'||LF||
        '<th>Elapsed Time<br>Unaccounted-for</th>'||LF||
        '<th>Idle<br>Wait Time</th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_sql_exec_time_vf
                   WHERE exec_id           = p_exec_id
                     AND group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          printf('<tr>'||LF||
          '<td class="title">'||i.call_type||':</td>'||LF||
          '<td class="right">'||i.accounted_response||'</td>'||LF||
          '<td class="right">'||i.elapsed||'</td>'||LF||
          '<td class="right">'||i.cpu||'</td>'||LF||
          '<td class="right">'||i.non_idle_wait||'</td>'||LF||
          '<td class="right">'||i.elapsed_unaccounted_for||'</td>'||LF||
          '<td class="right">'||i.idle_wait||'</td>'||LF||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF);
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display exec self time: '||SQLERRM);
      END;

      -- totals
      BEGIN
        printf(
        '<br><table>'||LF||
        '<tr>'||LF||
        '<th>Call</th>'||LF||
        '<th>Call<br>Count</th>'||LF||
        '<th>OS<br>Buffer Gets<br>(disk)</th>'||LF||
        '<th>BG Consistent<br>Read Mode<br>(query)</th>'||LF||
        '<th>BG Current<br>Mode<br>(current)</th>'||LF||
        '<th>Rows<br>Processed<br>or Returned</th>'||LF||
        '<th>Library<br>Cache<br>Misses</th>'||LF||
        '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
        '<th>Times<br>Waited<br>Idle</th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_sql_exec_total_v
                   WHERE exec_id           = p_exec_id
                     AND group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          printf('<tr>'||LF||
          '<td class="title">'||i.call_type||':</td>'||LF||
          '<td class="right">'||i.call_count||'</td>'||LF||
          '<td class="right">'||i.p_disk_os||'</td>'||LF||
          '<td class="right">'||i.cr_query_consistent||'</td>'||LF||
          '<td class="right">'||i.cu_current||'</td>'||LF||
          '<td class="right">'||i.r_rows||'</td>'||LF||
          '<td class="right">'||i.mis_library_cache_misses||'</td>'||LF||
          '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
          '<td class="right">'||i.wait_count_idle||'</td>'||LF||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF);
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display exec self totals: '||SQLERRM);
      END;

      -- waits
      IF trca$g.g_include_waits = 'Y' THEN
        DECLARE
          l_count INTEGER;
        BEGIN
          SELECT COUNT(*)
            INTO l_count
            FROM trca$_group_exec_wait
           WHERE exec_id           = p_exec_id
             AND group_id          = p_group_id
             AND tool_execution_id = p_tool_execution_id
             AND ROWNUM            = 1;

          IF l_count > 0 THEN
            printf(
            '<br><table>'||LF||
            '<tr>'||LF||
            '<th>Event Name</th>'||LF||
            '<th>Wait Class</th>'||LF||
            '<th>Non-Idle<br>Wait Time</th>'||LF||
            '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
            '<th>Idle<br>Wait Time</th>'||LF||
            '<th>Times<br>Waited<br>Idle</th>'||LF||
            '<th>Average<br>Wait Time</th>'||LF||
            '<th>Max<br>Wait Time</th>'||LF||
            '<th>Blocks</th>'||LF||
            '<th>Average<br>Blocks</th>'||LF||
            '</tr>'||LF);

            FOR i IN (SELECT *
                        FROM trca$_sql_exec_wait_vf
                       WHERE exec_id           = p_exec_id
                         AND group_id          = p_group_id
                         AND tool_execution_id = p_tool_execution_id
                       ORDER BY
                             row_type,
                             wait DESC)
            LOOP
              printf('<tr>'||LF||
              '<td class="title">'||i.event_name||':</td>'||LF||
              '<td class="left">'||i.wait_class||'</td>'||LF||
              '<td class="right">'||i.non_idle_wait||'</td>'||LF||
              '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
              '<td class="right">'||i.idle_wait||'</td>'||LF||
              '<td class="right">'||i.wait_count_idle||'</td>'||LF||
              '<td class="right">'||i.avg_wait||'</td>'||LF||
              '<td class="right">'||i.max_wait||'</td>'||LF||
              '<td class="right">'||i.blocks||'</td>'||LF||
              '<td class="right">'||i.avg_blocks||'</td>'||LF||
              '</tr>'||LF);
            END LOOP;

            printf('</table>'||LF);
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

        BEGIN
          SELECT COUNT(*)
            INTO l_exec_binds
            FROM trca$_exec_binds
           WHERE tool_execution_id = p_tool_execution_id
             AND group_id          = p_group_id
             AND exec_id           = p_exec_id
             AND ROWNUM            = 1;

          IF l_exec_binds > 0 THEN
            printf(
            '<br><table>'||LF||
            '<tr>'||LF||
            '<th>Bind<br>Pos</th>'||LF||
            '<th>DTY<br>Code</th>'||LF||
            '<th>Data<br>Type</th>'||LF||
            '<th>Actual<br>Value<br>Length</th>'||LF||
            '<th>Value</th>'||LF||
            '</tr>'||LF);

            FOR i IN (SELECT *
                        FROM trca$_exec_binds_vf
                       WHERE tool_execution_id = p_tool_execution_id
                         AND group_id          = p_group_id
                         AND exec_id           = p_exec_id
                       ORDER BY
                             bind)
            LOOP
              printf('<tr>'||LF||
              '<td class="title">'||i.bind||':</td>'||LF||
              '<td class="right">'||i.data_type_code||'</td>'||LF||
              '<td class="left">'||i.data_type_name||'</td>'||LF||
              '<td class="right">'||i.actual_value_length||'</td>'||LF||
              '<td class="left">'||i.value||'</td>'||LF||
              '</tr>'||LF);
            END LOOP;

            printf('</table>'||LF);
          END IF; -- l_exec_binds > 0
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display binds for this exec: '||SQLERRM);
        END;
      END IF; -- trca$g.g_include_binds

      -- fetches
      IF trca$g.g_include_fetches = 'Y' THEN
        DECLARE
          l_fetches_count INTEGER := 0;
          l_fetches_first INTEGER;
          l_fetches_second INTEGER;
          l_fetches_third INTEGER;
          l_fetches_last INTEGER;
          l_fetches_max_e INTEGER;
          l_max_e NUMBER := 0;

        BEGIN
          FOR i IN (SELECT id, e
                      FROM trca$_call
                     WHERE tool_execution_id = p_tool_execution_id
                       AND group_id          = p_group_id
                       AND exec_id           = p_exec_id
                       AND call              = trca$g.CALL_FETCH
                     ORDER BY
                           id)
          LOOP
            l_fetches_count := l_fetches_count + 1;

            IF l_fetches_count = 1 THEN
              l_fetches_first := i.id;
            ELSIF l_fetches_count = 2 THEN
              l_fetches_second := i.id;
            ELSIF l_fetches_count = 3 THEN
              l_fetches_third := i.id;
            END IF;

            IF i.e > l_max_e THEN
              l_fetches_max_e := i.id;
              l_max_e := i.e;
            END IF;

            l_fetches_last := i.id;
          END LOOP;

          IF l_fetches_count > 1 THEN
            -- time
            BEGIN
              printf(
              '<br><table>'||LF||
              '<tr>'||LF||
              '<th>Fetch<br>Call</th>'||LF||
              '<th>Response Time<br>Accounted-for</th>'||LF||
              '<th>Elapsed<br>Time</th>'||LF||
              '<th>CPU Time</th>'||LF||
              '<th>Non-Idle<br>Wait Time</th>'||LF||
              '<th>Elapsed Time<br>Unaccounted-for</th>'||LF||
              '<th>Idle<br>Wait Time</th>'||LF||
              '<th>Call Timestamp</th>'||LF||
              '</tr>'||LF);

              FOR i IN (SELECT CASE id
                               WHEN l_fetches_first THEN 'First'
                               WHEN l_fetches_last THEN 'Last'
                               WHEN l_fetches_second THEN 'Second'
                               WHEN l_fetches_third THEN 'Third'
                               WHEN l_fetches_max_e THEN 'Max ET'
                               END first_last,
                               v.accounted_response,
                               v.elapsed,
                               v.cpu,
                               v.self_non_idle_wait,
                               v.elapsed_unaccounted_for,
                               v.self_idle_wait,
                               v.call_timestamp
                          FROM trca$_call_vf v
                         WHERE v.tool_execution_id = p_tool_execution_id
                           AND v.group_id          = p_group_id
                           AND v.exec_id           = p_exec_id
                           AND v.id IN (l_fetches_first, l_fetches_second, l_fetches_third, l_fetches_last, l_fetches_max_e)
                           AND v.call = trca$g.CALL_FETCH
                         ORDER BY
                               v.id)
              LOOP
                printf('<tr>'||LF||
                '<td class="title">'||i.first_last||':</td>'||LF||
                '<td class="right">'||i.accounted_response||'</td>'||LF||
                '<td class="right">'||i.elapsed||'</td>'||LF||
                '<td class="right">'||i.cpu||'</td>'||LF||
                '<td class="right">'||i.self_non_idle_wait||'</td>'||LF||
                '<td class="right">'||i.elapsed_unaccounted_for||'</td>'||LF||
                '<td class="right">'||i.self_idle_wait||'</td>'||LF||
                '<td class="left">'||i.call_timestamp||'</td>'||LF||
                '</tr>'||LF);
              END LOOP;

              printf('</table>'||LF);
            EXCEPTION
              WHEN OTHERS THEN
                print_log('*** cannot display fetch self time: '||SQLERRM);
            END;

            -- totals
            BEGIN
              printf(
              '<br><table>'||LF||
              '<tr>'||LF||
              '<th>Fetch<br>Call</th>'||LF||
              '<th>Recursive<br>Call<br>Count</th>'||LF||
              '<th>OS<br>Buffer Gets<br>(disk)</th>'||LF||
              '<th>BG Consistent<br>Read Mode<br>(query)</th>'||LF||
              '<th>BG Current<br>Mode<br>(current)</th>'||LF||
              '<th>Rows<br>Processed<br>or Returned</th>'||LF||
              '<th>Library<br>Cache<br>Misses</th>'||LF||
              '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
              '<th>Times<br>Waited<br>Idle</th>'||LF||
              '<th>Call Timestamp</th>'||LF||
              '</tr>'||LF);

              FOR i IN (SELECT CASE id
                               WHEN l_fetches_first THEN 'First'
                               WHEN l_fetches_last THEN 'Last'
                               WHEN l_fetches_second THEN 'Second'
                               WHEN l_fetches_third THEN 'Third'
                               WHEN l_fetches_max_e THEN 'Max ET'
                               END first_last,
                               v.recu_call_count,
                               v.p_disk_os,
                               v.cr_query_consistent,
                               v.cu_current,
                               v.r_rows,
                               v.mis_library_cache_misses,
                               v.self_wait_count_non_idle,
                               v.self_wait_count_idle,
                               v.call_timestamp
                          FROM trca$_call_vf v
                         WHERE v.tool_execution_id = p_tool_execution_id
                           AND v.group_id          = p_group_id
                           AND v.exec_id           = p_exec_id
                           AND v.id IN (l_fetches_first, l_fetches_second, l_fetches_third, l_fetches_last, l_fetches_max_e)
                           AND v.call = trca$g.CALL_FETCH
                         ORDER BY
                               v.id)
              LOOP
                printf('<tr>'||LF||
                '<td class="title">'||i.first_last||':</td>'||LF||
                '<td class="right">'||i.recu_call_count||'</td>'||LF||
                '<td class="right">'||i.p_disk_os||'</td>'||LF||
                '<td class="right">'||i.cr_query_consistent||'</td>'||LF||
                '<td class="right">'||i.cu_current||'</td>'||LF||
                '<td class="right">'||i.r_rows||'</td>'||LF||
                '<td class="right">'||i.mis_library_cache_misses||'</td>'||LF||
                '<td class="right">'||i.self_wait_count_non_idle||'</td>'||LF||
                '<td class="right">'||i.self_wait_count_idle||'</td>'||LF||
                '<td class="left">'||i.call_timestamp||'</td>'||LF||
                '</tr>'||LF);
              END LOOP;

              printf('</table>'||LF);
            EXCEPTION
              WHEN OTHERS THEN
                print_log('*** cannot display fetch self totals: '||SQLERRM);
            END;
          END IF; -- l_fetches_count > 1
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display fetches for this exec: '||SQLERRM);
        END;
      END IF; -- trca$g.g_include_fetches

      printf(back_to_top(p_group_id)||LF||end_show_and_hide||LF);
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
    l_min_exec_id INTEGER;
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
      SELECT COUNT(*), MIN(id)
        INTO l_count, l_min_exec_id
        FROM trca$_exec
       WHERE tool_execution_id = p_tool_execution_id
         AND group_id          = p_group_id;

      IF l_count > 1 THEN
        incl_relevant_exec := TRUE;
      ELSIF l_count = 1 THEN
        SELECT COUNT(*)
          INTO l_count
          FROM trca$_call
         WHERE tool_execution_id = p_tool_execution_id
           AND group_id          = p_group_id
           AND exec_id           = l_min_exec_id
           AND call              = trca$g.CALL_FETCH;
        IF l_count > 1 THEN
          incl_relevant_exec := TRUE;
        ELSE
          incl_relevant_exec := FALSE;
        END IF;
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
      printf(LF||'<h2><a name="sql'||p_group_id||'"></a> '||stm_rec.hv||' '||stm_rec.sqlid||' '||grp_rec.plh||'</h2>'||LF);

      l_text := 'Rank:'||grp_rec.rank||'(<a title="Percent of Total Response Time Accounted-for">'||sql_vf.contribution||'</a>) ';
      IF (grp_rec.top_sql = 'Y' OR grp_rec.top_sql_et = 'Y' OR grp_rec.top_sql_ct = 'Y') THEN
        l_text := '<font color="#FF0000">'||l_text||'</font>';
      END IF;

      IF grp_rec.err IS NOT NULL THEN
        l_text := '<font color="#FF0000">ORA-'||LPAD(grp_rec.err, 5, '0')||'</font><br><br>'||l_text;
      END IF;

      l_text := l_text||'Self:'||sql_vf.response_time_self||'s ';
      l_text := l_text||'Recursive:'||sql_vf.response_time_progeny||'s ';
      l_text := l_text||'Invoker:'||get_uid_name(grp_rec.uid#)||' ';
      l_text := l_text||'Definer:'||get_uid_name(grp_rec.lid)||' ';
      l_text := l_text||'Depth:'||grp_rec.dep||' ';
      printf(l_text);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display sql title for '||p_group_id||': '||SQLERRM);
    END;

    /* -------------------------
     * SQL ToC
     * ------------------------- */
    DECLARE
      l_text VARCHAR2(32767);
    BEGIN
      IF grp_rec.include_details = 'Y' THEN
        l_text := '<ul>'||LF;

        IF incl_self_time_totals_etc THEN
          l_text := l_text||'<li><a href="#stt'||p_group_id||'">SQL Self - Time, Totals, Waits, Binds and Row Source Plan</a>'||LF;
        END IF;
        IF incl_explain_plan THEN
          l_text := l_text||'<li><a href="#expln'||p_group_id||'">Explain Plan</a>'||LF;
        END IF;
        IF incl_tables OR incl_indexes THEN
          l_text := l_text||'<li><a href="#tblidx'||p_group_id||'">Tables and Indexes</a>'||LF;
        END IF;
        IF incl_progeny_time_totals THEN
          l_text := l_text||'<li><a href="#ptt'||p_group_id||'">Recursive SQL - Time and Totals</a>'||LF;
        END IF;
        IF incl_segment_io_summary THEN
          l_text := l_text||'<li><a href="#siows'||p_group_id||'">Segment I/O Wait Summary</a>'||LF;
        END IF;
        IF incl_relevant_exec THEN
          l_text := l_text||'<li><a href="#rex'||p_group_id||'">Relevant Executions</a>'||LF;
        END IF;

        l_text := l_text||'</ul>';
        printf(l_text);
      ELSE
        printf('<br><br>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display sql toc for '||p_group_id||': '||SQLERRM);
    END;

    /* -------------------------
     * SQL Text
     * ------------------------- */
    DECLARE
      l_text VARCHAR2(32767);
      l_clob CLOB;
    BEGIN
      printf(LF||begin_show('SHSQL'||p_group_id)||'<pre>');

      l_clob := trca$g.wrap_text (
        p_clob         => stm_rec.sql_fulltext,
        p_max_line_len => 150,
        p_add_br       => 'N',
        p_lt_gt_quote  => 'Y' );

      IF l_clob IS NOT NULL AND SYS.DBMS_LOB.GETLENGTH(l_clob) > 0 THEN
        SYS.DBMS_LOB.APPEND (
          dest_lob => s_file_rec.file_text,
          src_lob  => l_clob );
      END IF;

      printf('</pre>'||BACK_TOP||LF||end_show_and_hide||LF);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display sql title for '||p_group_id||': '||SQLERRM);
    END;

    /* -------------------------
     * SQL Self - Time, Totals, Waits, Binds and Row Source Plan
     * ------------------------- */
    IF incl_self_time_totals_etc THEN

      printf('<a name="stt'||p_group_id||'"></a>'||LF||
      '<h3>SQL Self - Time, Totals, Waits, Binds and Row Source Plan</h3>'||LF||
      begin_show('SHSTT'||p_group_id)||LF);

      -- time
      BEGIN
        printf(
        '<table>'||LF||
        '<tr>'||LF||
        '<th>Call</th>'||LF||
        '<th>Response Time<br>Accounted-for</th>'||LF||
        '<th>Elapsed<br>Time</th>'||LF||
        '<th>CPU Time</th>'||LF||
        '<th>Non-Idle<br>Wait Time</th>'||LF||
        '<th>Elapsed Time<br>Unaccounted-for</th>'||LF||
        '<th>Idle<br>Wait Time</th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_sql_self_time_vf
                   WHERE group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          printf('<tr>'||LF||
          '<td class="title">'||i.call_type||':</td>'||LF||
          '<td class="right">'||i.accounted_response||'</td>'||LF||
          '<td class="right">'||i.elapsed||'</td>'||LF||
          '<td class="right">'||i.cpu||'</td>'||LF||
          '<td class="right">'||i.non_idle_wait||'</td>'||LF||
          '<td class="right">'||i.elapsed_unaccounted_for||'</td>'||LF||
          '<td class="right">'||i.idle_wait||'</td>'||LF||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF);
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql self time: '||SQLERRM);
      END;

      -- totals
      BEGIN
        printf(
        '<br><table>'||LF||
        '<tr>'||LF||
        '<th>Call</th>'||LF||
        '<th>Call<br>Count</th>'||LF||
        '<th>OS<br>Buffer Gets<br>(disk)</th>'||LF||
        '<th>BG Consistent<br>Read Mode<br>(query)</th>'||LF||
        '<th>BG Current<br>Mode<br>(current)</th>'||LF||
        '<th>Rows<br>Processed<br>or Returned</th>'||LF||
        '<th>Library<br>Cache<br>Misses</th>'||LF||
        '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
        '<th>Times<br>Waited<br>Idle</th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_sql_self_total_v
                   WHERE group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          printf('<tr>'||LF||
          '<td class="title">'||i.call_type||':</td>'||LF||
          '<td class="right">'||i.call_count||'</td>'||LF||
          '<td class="right">'||i.p_disk_os||'</td>'||LF||
          '<td class="right">'||i.cr_query_consistent||'</td>'||LF||
          '<td class="right">'||i.cu_current||'</td>'||LF||
          '<td class="right">'||i.r_rows||'</td>'||LF||
          '<td class="right">'||i.mis_library_cache_misses||'</td>'||LF||
          '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
          '<td class="right">'||i.wait_count_idle||'</td>'||LF||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF);
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql self totals: '||SQLERRM);
      END;

      -- waits
      IF trca$g.g_include_waits = 'Y' THEN
        DECLARE
          l_count INTEGER;
        BEGIN
          SELECT COUNT(*)
            INTO l_count
            FROM trca$_group_wait
           WHERE group_id          = p_group_id
             AND tool_execution_id = p_tool_execution_id
             AND ROWNUM            = 1;

          IF l_count > 0 THEN
            printf(
            '<br><table>'||LF||
            '<tr>'||LF||
            '<th>Event Name</th>'||LF||
            '<th>Wait Class</th>'||LF||
            '<th>Non-Idle<br>Wait Time</th>'||LF||
            '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
            '<th>Idle<br>Wait Time</th>'||LF||
            '<th>Times<br>Waited<br>Idle</th>'||LF||
            '<th>Average<br>Wait Time</th>'||LF||
            '<th>Max<br>Wait Time</th>'||LF||
            '<th>Blocks</th>'||LF||
            '<th>Average<br>Blocks</th>'||LF||
            '</tr>'||LF);

            FOR i IN (SELECT *
                        FROM trca$_sql_self_wait_vf
                       WHERE group_id          = p_group_id
                         AND tool_execution_id = p_tool_execution_id
                       ORDER BY
                             row_type,
                             wait DESC)
            LOOP
              printf('<tr>'||LF||
              '<td class="title">'||i.event_name||':</td>'||LF||
              '<td class="left">'||i.wait_class||'</td>'||LF||
              '<td class="right">'||i.non_idle_wait||'</td>'||LF||
              '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
              '<td class="right">'||i.idle_wait||'</td>'||LF||
              '<td class="right">'||i.wait_count_idle||'</td>'||LF||
              '<td class="right">'||i.avg_wait||'</td>'||LF||
              '<td class="right">'||i.max_wait||'</td>'||LF||
              '<td class="right">'||i.blocks||'</td>'||LF||
              '<td class="right">'||i.avg_blocks||'</td>'||LF||
              '</tr>'||LF);
            END LOOP;

            printf('</table>'||LF);
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

        BEGIN
          SELECT COUNT(DISTINCT exec_id)
            INTO l_exec_binds
            FROM trca$_exec_binds
           WHERE tool_execution_id = p_tool_execution_id
             AND group_id          = p_group_id;

          IF l_exec_binds = 1 THEN
            printf(
            '<br><table>'||LF||
            '<tr>'||LF||
            '<th>Bind<br>Pos</th>'||LF||
            '<th>DTY<br>Code</th>'||LF||
            '<th>Data<br>Type</th>'||LF||
            '<th>Actual<br>Value<br>Length</th>'||LF||
            '<th>Value</th>'||LF||
            '</tr>'||LF);

            FOR i IN (SELECT *
                        FROM trca$_exec_binds_vf
                       WHERE tool_execution_id = p_tool_execution_id
                         AND group_id          = p_group_id
                       ORDER BY
                             bind)
            LOOP
              printf('<tr>'||LF||
              '<td class="title">'||i.bind||':</td>'||LF||
              '<td class="right">'||i.data_type_code||'</td>'||LF||
              '<td class="left">'||i.data_type_name||'</td>'||LF||
              '<td class="right">'||i.actual_value_length||'</td>'||LF||
              '<td class="left">'||i.value||'</td>'||LF||
              '</tr>'||LF);
            END LOOP;

            printf('</table>'||LF);
          END IF; -- l_exec_binds = 1
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display binds for one exec: '||SQLERRM);
        END;
      END IF; -- trca$g.g_include_binds = 'Y'

      -- row source plan
      DECLARE
        l_columns1 VARCHAR2(32767) := NULL;
        l_columns2 VARCHAR2(32767) := NULL;
        l_columns3 VARCHAR2(32767) := NULL;
        l_sessions NUMBER := 0;

      BEGIN
        FOR i IN (SELECT trca_plan_hash_value
                    FROM trca$_group_row_source_plan
                   WHERE tool_execution_id = p_tool_execution_id
                     AND group_id          = p_group_id
                   ORDER BY
                         first_exec_id)
        LOOP
          IF trca$g.g_card = 'Y' THEN
            l_columns1 := '<th>Estim<br>Card</th>'||LF;
            l_columns2 := '<th>Cost</th>'||LF||
                          '<th>Estim<br>Size<br>(bytes)</th>'||LF;
          END IF;

          IF trca$g.g_time = 'Y' THEN
            l_columns3 := '<th>BG<br>Consistent<br>Read Mode<br>(cr)</th>'||LF||
                          '<th>OS<br>Buffer<br>Gets<br>(pr)</th>'||LF||
                          '<th>OS<br>Write<br>Calls<br>(pw)</th>'||LF||
                          '<th>Time<br>(secs)</th>'||LF;
          END IF;

          printf(
          '<br><table>'||LF||
          '<tr>'||LF||
          '<th>ID</th>'||LF||
          '<th>PID</th>'||LF||
          l_columns1||
          '<th>Actual<br>Rows</th>'||LF||
          '<th>Row Source Operation</th>'||LF||
          l_columns3||
          '<th>Obj</th>'||LF||
          l_columns2||
          '</tr>'||LF);

          FOR j IN (SELECT *
                      FROM trca$_row_source_plan_vf
                     WHERE tool_execution_id    = p_tool_execution_id
                       AND group_id             = p_group_id
                       AND trca_plan_hash_value = i.trca_plan_hash_value
                     ORDER BY
                           id)
          LOOP
            IF trca$g.g_card = 'Y' THEN
              l_columns1 := '<td class="right">'||j.card||'</td>'||LF;
              l_columns2 := '<td class="right">'||j.cost||'</td>'||LF||
                            '<td class="right">'||j.siz||'</td>'||LF;
            END IF;

            IF trca$g.g_time = 'Y' THEN
              l_columns3 := '<td class="right">'||j.cr||'</td>'||LF||
                            '<td class="right">'||j.pr||'</td>'||LF||
                            '<td class="right">'||j.pw||'</td>'||LF||
                            '<td class="right">'||j.time||'</td>'||LF;
            END IF;

            printf('<tr>'||LF||
            '<td class="title">'||j.id||':</td>'||LF||
            '<td class="right">'||j.pid||'</td>'||LF||
            l_columns1||
            '<td class="right">'||j.cnt||'</td>'||LF||
            '<td nowrap class="op">'||REPLACE(j.op_prefix, ' ', NBSP)||j.op||'</td>'||LF||
            l_columns3||
            '<td class="right">'||j.obj||'</td>'||LF||
            l_columns2||
            '</tr>'||LF);

            IF j.sessions > l_sessions THEN
              l_sessions := j.sessions;
            END IF;
          END LOOP;

          printf('</table>'||LF);

          IF l_sessions > 1 THEN
            FOR j IN (SELECT DISTINCT session_id, sid, serial#, file_name
                        FROM trca$_row_source_plan_sess_vf
                       WHERE tool_execution_id    = p_tool_execution_id
                         AND group_id             = p_group_id
                         AND trca_plan_hash_value = i.trca_plan_hash_value
                       ORDER BY
                             session_id, sid, serial#, file_name)
            LOOP
              IF trca$g.g_card = 'Y' THEN
                l_columns1 := '<th>Estim<br>Card</th>'||LF;
                l_columns2 := '<th>Cost</th>'||LF||
                              '<th>Estim<br>Size<br>(bytes)</th>'||LF;
              END IF;

              IF trca$g.g_time = 'Y' THEN
                l_columns3 := '<th>BG<br>Consistent<br>Read Mode<br>(cr)</th>'||LF||
                              '<th>OS<br>Buffer<br>Gets<br>(pr)</th>'||LF||
                              '<th>OS<br>Write<br>Calls<br>(pw)</th>'||LF||
                              '<th>Time<br>(secs)</th>'||LF;
              END IF;

              printf(
              '<br><table>'||LF||
              '<tr>'||LF||
              '<th>ID</th>'||LF||
              '<th>PID</th>'||LF||
              l_columns1||
              '<th>Actual<br>Rows</th>'||LF||
              '<th>Row Source Operation<br>for session ('||j.sid||'.'||j.serial#||') in file<br>'||j.file_name||'</th>'||LF||
              l_columns3||
              '<th>Obj</th>'||LF||
              l_columns2||
              '</tr>'||LF);

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
                IF trca$g.g_card = 'Y' THEN
                  l_columns1 := '<td class="right">'||k.card||'</td>'||LF;
                  l_columns2 := '<td class="right">'||k.cost||'</td>'||LF||
                                '<td class="right">'||k.siz||'</td>'||LF;
                END IF;

                IF trca$g.g_time = 'Y' THEN
                  l_columns3 := '<td class="right">'||k.cr||'</td>'||LF||
                                '<td class="right">'||k.pr||'</td>'||LF||
                                '<td class="right">'||k.pw||'</td>'||LF||
                                '<td class="right">'||k.time||'</td>'||LF;
                END IF;

                printf('<tr>'||LF||
                '<td class="title">'||k.id||':</td>'||LF||
                '<td class="right">'||k.pid||'</td>'||LF||
                l_columns1||
                '<td class="right">'||k.cnt||'</td>'||LF||
                '<td nowrap class="op">'||REPLACE(k.op_prefix, ' ', NBSP)||k.op||'</td>'||LF||
                l_columns3||
                '<td class="right">'||k.obj||'</td>'||LF||
                l_columns2||
                '</tr>'||LF);
              END LOOP;

              printf('</table>'||LF);
            END LOOP;
          END IF;
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql row source plan: '||SQLERRM);
      END;

      printf(back_to_top(p_group_id)||LF||end_show_and_hide||LF);
    END IF; -- incl_self_time_totals_etc

    /* -------------------------
     * Explain Plan
     * ------------------------- */
    -- explain plan
    IF incl_explain_plan THEN
      DECLARE
        l_columns1 VARCHAR2(32767) := NULL;
        l_columns2 VARCHAR2(32767) := NULL;
        l_indexed_columns VARCHAR2(32767);
        l_predicates CLOB;
        l_access_predicates CLOB;
        l_filter_predicates CLOB;
        l_search_cols VARCHAR2(32767);

      BEGIN
        printf('<a name="expln'||p_group_id||'"></a>'||LF||
        '<h3>Explain Plan</h3>'||LF);

        IF incl_actual_rows THEN
          l_columns1 := '<th>Actual<br>Rows<sup>2</sup></th>'||LF;
          l_columns2 := '(2) Actual rows returned by operation (average if there were more than 1 execution).<br>'||LF;
        END IF;

        printf('May not match the plan used for execution if your SQL includes bind variables and bind peeking is enabled.<br><br>');

        printf(
        '<table>'||LF||
        '<tr>'||LF||
        '<th>ID</th>'||LF||
        '<th>PID</th>'||LF||
        '<th>Estim<br>Card</th>'||LF||
        l_columns1||
        '<th>Cost</th>'||LF||
        '<th>Explain Plan Operation</th>'||LF||
        '<th>Search<br>Cols<sup>1</sup></th>'||LF||
        '<th>Indexed<br>Cols</th>'||LF||
        '<th>Predicates</th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_plan_table_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND group_id          = p_group_id
                   ORDER BY
                         id)
        LOOP
          IF incl_actual_rows THEN
            l_columns1 := '<td class="right">'||i.actual_rows||'</td>'||LF;
          END IF;

          IF i.columns_count IS NULL THEN
            l_search_cols := NULL;
          ELSE
            l_search_cols := NVL(i.search_columns, 0)||'/'||i.columns_count;
          END IF;

          l_indexed_columns := i.indexed_columns;
          IF i.indexed_columns IS NOT NULL THEN
            --l_indexed_columns := begin_hide('SHIDXC'||p_group_id||'X'||i.id, '<br>'||REPLACE(l_indexed_columns, ' ', '<br>'))||end_show_and_hide;
            l_indexed_columns := begin_hide('SHIDXC'||p_group_id||'X'||i.id, REPLACE(l_indexed_columns, ' ', '<br>'))||end_show_and_hide;
          END IF;

          l_access_predicates := i.access_predicates;
          IF l_access_predicates IS NOT NULL THEN
            l_access_predicates := trca$g.wrap_text(REPLACE(l_access_predicates, '"'), 40, 'Y', 'Y');
          END IF;

          l_filter_predicates := i.filter_predicates;
          IF l_filter_predicates IS NOT NULL THEN
            l_filter_predicates := trca$g.wrap_text(REPLACE(l_filter_predicates, '"'), 40, 'Y', 'Y');
          END IF;

          IF l_access_predicates IS NOT NULL OR l_filter_predicates IS NOT NULL THEN
            l_predicates := '<table>'||LF;
            IF l_access_predicates IS NOT NULL THEN
              l_predicates := l_predicates||'<tr><th>Access Predicates</th></tr>'||LF||'<tr><td class=left>'||l_access_predicates||'</td></tr>'||LF;
            END IF;
            IF l_filter_predicates IS NOT NULL THEN
              l_predicates := l_predicates||'<tr><th>Filter Predicates</th></tr>'||LF||'<tr><td class=left>'||l_filter_predicates||'</td></tr>'||LF;
            END IF;
            l_predicates := l_predicates||'</table>'||LF;
            --l_predicates := begin_hide('SHAPFP'||p_group_id||'X'||i.id, '<br>'||l_predicates)||end_show_and_hide;
            l_predicates := begin_hide('SHAPFP'||p_group_id||'X'||i.id, l_predicates)||end_show_and_hide;
          ELSE
            l_predicates := NULL;
          END IF;

          printf('<tr>'||LF||
          '<td class="title">'||i.id||':</td>'||LF||
          '<td class="right">'||i.parent_id||'</td>'||LF||
          '<td class="right">'||i.cardinality||'</td>'||LF||
          l_columns1||
          '<td class="right">'||i.cost||'</td>'||LF||
          '<td nowrap class="op">'||REPLACE(i.op_prefix, ' ', NBSP)||i.op||'</td>'||LF||
          '<td>'||l_search_cols||'</td>'||LF||
          '<td class="left">'||l_indexed_columns||'</td>'||LF||
          '<td class="left">');

          IF l_predicates IS NOT NULL AND SYS.DBMS_LOB.GETLENGTH(l_predicates) > 0 THEN
            SYS.DBMS_LOB.APPEND (
              dest_lob => s_file_rec.file_text,
              src_lob  => l_predicates );
          END IF;

          printf(LF||'</td>'||LF||'</tr>'||LF);
        END LOOP;

        printf('</table>'||LF||
        '<font class="tablenote">'||LF||
        '(1) X/Y: Where X is the number of searched columns from index, which has a total of Y columns.<br>'||LF||
        l_columns2||
        '</font>'||LF);
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display explain plan: '||SQLERRM);
      END;
    END IF; -- incl_explain_plan

    /* -------------------------
     * Tables and Indexes
     * ------------------------- */
    IF incl_tables OR incl_indexes THEN
      printf('<a name="tblidx'||p_group_id||'"></a>'||LF||
      '<h3>Tables and Indexes</h3>'||LF);

      -- tables
      IF incl_tables THEN
        DECLARE
          l_row INTEGER := 0;

        BEGIN
          printf(begin_show('SHTBL'||p_group_id)||LF);

          printf(
          '<table>'||LF||
          '<tr>'||LF||
          '<th>#</th>'||LF||
          '<th>Owner.Table Name</th>'||LF||
          '<th>in Row<br>Source<br>Plan</th>'||LF||
          '<th>in<br>Explain<br>Plan</th>'||LF||
          '<th>Current<br>Count(*)<sup>2</sup></th>'||LF||
          '<th>Num<br>Rows<sup>1</sup></th>'||LF||
          '<th>Sample<br>Size<sup>1</sup></th>'||LF||
          '<th>Last Analyzed<sup>1</sup></th>'||LF||
          '<th>Avg<br>Row<br>Len<sup>1</sup></th>'||LF||
          '<th>Chain<br>Count<sup>1</sup></th>'||LF||
          '<th>Blocks<sup>1</sup></th>'||LF||
          '<th>Empty<br>Blocks<sup>1</sup></th>'||LF||
          '<th>Avg<br>Space<sup>1</sup></th>'||LF||
          '<th>Global<br>Stats<sup>1</sup></th>'||LF||
          '<th>Part</th>'||LF||
          '<th>Temp</th>'||LF||
          '</tr>'||LF);

          FOR i IN (SELECT *
                      FROM trca$_group_tables_v
                     WHERE tool_execution_id = p_tool_execution_id
                       AND group_id          = p_group_id
                     ORDER BY
                           owner,
                           table_name)
          LOOP
            l_row := l_row + 1;

            printf('<tr>'||LF||
            '<td class="title">'||l_row||':</td>'||LF||
            '<td class="left">'||i.owner||'.'||i.table_name||'</td>'||LF||
            '<td>'||i.in_row_source_plan||'</td>'||LF||
            '<td>'||i.in_explain_plan||'</td>'||LF||
            '<td class="right">'||i.actual_rows||'</td>'||LF||
            '<td class="right">'||i.num_rows||'</td>'||LF||
            '<td class="right">'||i.sample_size||'</td>'||LF||
            '<td nowrap>'||TO_CHAR(i.last_analyzed, LONG_DATE_FORMAT)||'</td>'||LF||
            '<td class="right">'||i.avg_row_len||'</td>'||LF||
            '<td class="right">'||i.chain_cnt||'</td>'||LF||
            '<td class="right">'||i.blocks||'</td>'||LF||
            '<td class="right">'||i.empty_blocks||'</td>'||LF||
            '<td class="right">'||i.avg_space||'</td>'||LF||
            '<td>'||i.global_stats||'</td>'||LF||
            '<td>'||i.partitioned||'</td>'||LF||
            '<td>'||i.temporary||'</td>'||LF||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF||
          '<font class="tablenote">'||LF||
          '(1) CBO statistics.<br>'||LF||
          '(2) COUNT(*) up to threshold value of '||trca$g.g_count_star_th||' (tool configuartion parameter).<br>'||LF||
          '</font>'||LF);
          printf(back_to_top(p_group_id)||LF||end_show_and_hide||LF);
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display sql tables: '||SQLERRM);
        END;
      END IF; -- incl_tables

      -- indexes1
      IF incl_indexes THEN
        DECLARE
          l_row INTEGER := 0;

        BEGIN
          printf('<br>'||begin_show('SH1IDX'||p_group_id)||LF);

          printf(
          '<table>'||LF||
          '<tr>'||LF||
          '<th>#</th>'||LF||
          '<th>Owner.Table Name</th>'||LF||
          '<th>Owner.Index Name</th>'||LF||
          '<th>in Row<br>Source<br>Plan</th>'||LF||
          '<th>in<br>Explain<br>Plan</th>'||LF||
          '<th>Index Type</th>'||LF||
          '<th>Uniqueness</th>'||LF||
          '<th>Cols<br>Count</th>'||LF||
          '<th>Indexed Columns</th>'||LF||
          '</tr>'||LF);

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

            printf('<tr>'||LF||
            '<td class="title">'||l_row||':</td>'||LF||
            '<td class="left">'||i.table_owner||'.'||i.table_name||'</td>'||LF||
            '<td class="left">'||i.owner||'.'||i.index_name||'</td>'||LF||
            '<td>'||i.in_row_source_plan||'</td>'||LF||
            '<td>'||i.in_explain_plan||'</td>'||LF||
            '<td class="left">'||i.index_type||'</td>'||LF||
            '<td class="left">'||i.uniqueness||'</td>'||LF||
            '<td>'||i.columns_count||'</td>'||LF||
            '<td class="left">'||i.indexed_columns||'</td>'||LF||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF);
          printf(back_to_top(p_group_id)||LF||end_show_and_hide||LF);
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display sql indexes1: '||SQLERRM);
        END;
      END IF; -- incl_indexes (1)

      -- indexes2
      IF incl_indexes THEN
        DECLARE
          l_row INTEGER := 0;

        BEGIN
          printf('<br>'||begin_show('SH2IDX'||p_group_id)||LF);

          printf(
          '<table>'||LF||
          '<tr>'||LF||
          '<th>#</th>'||LF||
          '<th>Owner.Table Name</th>'||LF||
          '<th>Owner.Index Name</th>'||LF||
          '<th>Num<br>Rows<sup>1</sup></th>'||LF||
          '<th>Sample<br>Size<sup>1</sup></th>'||LF||
          '<th>Last Analyzed<sup>1</sup></th>'||LF||
          '<th>Distinct<br>Keys<sup>1</sup></th>'||LF||
          '<th>Blevel<sup>1</sup></th>'||LF||
          '<th>Leaf<br>Blocks<sup>1</sup></th>'||LF||
          '<th>Avg<br>Leaf<br>Blocks<br>per<br>Key<sup>1</sup></th>'||LF||
          '<th>Avg<br>Data<br>Blocks<br>per<br>Key<sup>1</sup></th>'||LF||
          '<th>Clustering<br>Factor<sup>1</sup></th>'||LF||
          '<th>Global<br>Stats<sup>1</sup></th>'||LF||
          '<th>Part</th>'||LF||
          '<th>Temp</th>'||LF||
          '</tr>'||LF);

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

            printf('<tr>'||LF||
            '<td class="title">'||l_row||':</td>'||LF||
            '<td class="left">'||i.table_owner||'.'||i.table_name||'</td>'||LF||
            '<td class="left">'||i.owner||'.'||i.index_name||'</td>'||LF||
            '<td class="right">'||i.num_rows||'</td>'||LF||
            '<td class="right">'||i.sample_size||'</td>'||LF||
            '<td nowrap>'||TO_CHAR(i.last_analyzed, LONG_DATE_FORMAT)||'</td>'||LF||
            '<td class="right">'||i.distinct_keys||'</td>'||LF||
            '<td class="right">'||i.blevel||'</td>'||LF||
            '<td class="right">'||i.leaf_blocks||'</td>'||LF||
            '<td class="right">'||i.avg_leaf_blocks_per_key||'</td>'||LF||
            '<td class="right">'||i.avg_data_blocks_per_key||'</td>'||LF||
            '<td class="right">'||i.clustering_factor||'</td>'||LF||
            '<td>'||i.global_stats||'</td>'||LF||
            '<td>'||i.partitioned||'</td>'||LF||
            '<td>'||i.temporary||'</td>'||LF||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF||
          '<font class="tablenote">'||LF||
          '(1) CBO statistics.<br>'||LF||
          '</font>'||LF);
          printf(back_to_top(p_group_id)||LF||end_show_and_hide||LF);
        EXCEPTION
          WHEN OTHERS THEN
            print_log('*** cannot display sql indexes2: '||SQLERRM);
        END;
      END IF; -- incl_indexes (2)

      -- indexed columns
      IF incl_indexes THEN
        DECLARE
          l_row INTEGER := 0;

        BEGIN
          printf('<br>'||begin_show('SH3IDX'||p_group_id)||LF);

          printf(
          '<table>'||LF||
          '<tr>'||LF||
          '<th>#</th>'||LF||
          '<th>Owner.Index Name</th>'||LF||
          '<th>Col<br>Pos</th>'||LF||
          '<th>Column Name</th>'||LF||
          '<th>Asc/<br>Desc</th>'||LF||
          '<th>Num<br>Rows<sup>1</sup></th>'||LF||
          '<th>Sample<br>Size<sup>1</sup></th>'||LF||
          '<th>Last Analyzed<sup>1</sup></th>'||LF||
          '<th>Num<br>Nulls<sup>1</sup></th>'||LF||
          '<th>Num<br>Distinct<sup>1</sup></th>'||LF||
          '<th>Density<sup>1</sup></th>'||LF||
          '<th>Num<br>Buckets<sup>1</sup></th>'||LF||
          '</tr>'||LF);

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

            printf('<tr>'||LF||
            '<td class="title">'||l_row||':</td>'||LF||
            '<td class="left">'||i.owner||'.'||i.index_name||'</td>'||LF||
            '<td>'||i.column_position||'</td>'||LF||
            '<td class="left">'||i.column_name||'</td>'||LF||
            '<td class="left">'||i.descend||'</td>'||LF||
            '<td class="right">'||i.num_rows||'</td>'||LF||
            '<td class="right">'||i.sample_size||'</td>'||LF||
            '<td nowrap>'||TO_CHAR(i.last_analyzed, LONG_DATE_FORMAT)||'</td>'||LF||
            '<td class="right">'||i.num_nulls||'</td>'||LF||
            '<td class="right">'||i.num_distinct||'</td>'||LF||
            '<td class="right">'||LOWER(TO_CHAR(i.density, '0.0000EEEE'))||'</td>'||LF||
            '<td class="right">'||i.num_buckets||'</td>'||LF||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF||
          '<font class="tablenote">'||LF||
          '(1) CBO statistics.<br>'||LF||
          '</font>'||LF);
          printf(back_to_top(p_group_id)||LF||end_show_and_hide||LF);
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

      printf('<a name="ptt'||p_group_id||'"></a>'||LF||
      '<h3>Recursive SQL - Time and Totals</h3>'||LF||
      begin_show('SHPTT'||p_group_id)||LF);

      -- time
      BEGIN
        printf(
        '<table>'||LF||
        '<tr>'||LF||
        '<th>Call</th>'||LF||
        '<th>Response Time<br>Accounted-for</th>'||LF||
        '<th>Elapsed<br>Time</th>'||LF||
        '<th>CPU Time</th>'||LF||
        '<th>Non-Idle<br>Wait Time</th>'||LF||
        '<th>Elapsed Time<br>Unaccounted-for</th>'||LF||
        '<th>Idle<br>Wait Time</th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_sql_recu_time_vf
                   WHERE group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          printf('<tr>'||LF||
          '<td class="title">'||i.call_type||':</td>'||LF||
          '<td class="right">'||i.accounted_response||'</td>'||LF||
          '<td class="right">'||i.elapsed||'</td>'||LF||
          '<td class="right">'||i.cpu||'</td>'||LF||
          '<td class="right">'||i.non_idle_wait||'</td>'||LF||
          '<td class="right">'||i.elapsed_unaccounted_for||'</td>'||LF||
          '<td class="right">'||i.idle_wait||'</td>'||LF||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF);
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql recu time: '||SQLERRM);
      END;

      -- totals
      BEGIN
        printf(
        '<br><table>'||LF||
        '<tr>'||LF||
        '<th>Call</th>'||LF||
        '<th>Call<br>Count</th>'||LF||
        '<th>OS<br>Buffer Gets<br>(disk)</th>'||LF||
        '<th>BG Consistent<br>Read Mode<br>(query)</th>'||LF||
        '<th>BG Current<br>Mode<br>(current)</th>'||LF||
        '<th>Rows<br>Processed<br>or Returned</th>'||LF||
        '<th>Library<br>Cache<br>Misses</th>'||LF||
        '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
        '<th>Times<br>Waited<br>Idle</th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_sql_recu_total_v
                   WHERE group_id          = p_group_id
                     AND tool_execution_id = p_tool_execution_id
                   ORDER BY
                         call)
        LOOP
          printf('<tr>'||LF||
          '<td class="title">'||i.call_type||':</td>'||LF||
          '<td class="right">'||i.call_count||'</td>'||LF||
          '<td class="right">'||i.p_disk_os||'</td>'||LF||
          '<td class="right">'||i.cr_query_consistent||'</td>'||LF||
          '<td class="right">'||i.cu_current||'</td>'||LF||
          '<td class="right">'||i.r_rows||'</td>'||LF||
          '<td class="right">'||i.mis_library_cache_misses||'</td>'||LF||
          '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
          '<td class="right">'||i.wait_count_idle||'</td>'||LF||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF);
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display sql recu totals: '||SQLERRM);
      END;

      printf(back_to_top(p_group_id)||LF||end_show_and_hide||LF);
    END IF; -- incl_progeny_time_totals

    /* -------------------------
     * Segment I/O Wait Summary
     * ------------------------- */
    IF incl_segment_io_summary THEN

      BEGIN
        printf('<a name="siows'||p_group_id||'"></a>'||LF||
        '<h3>Segment I/O Wait Summary</h3>'||LF||
        begin_show('SHSIOWS'||p_group_id)||LF);

        -- summary by wait time
        DECLARE
          l_row INTEGER := 0;
        BEGIN
          printf(
          '<br><table>'||LF||
          '<tr>'||LF||
          '<th>#</th>'||LF||
          '<th>Obj</th>'||LF||
          '<th>Type</th>'||LF||
          '<th>Segment Name<sup>1</sup></th>'||LF||
          '<th>Event Name</th>'||LF||
          '<th>Wait<br>Time<sup>2</sup></th>'||LF||
          '<th>Times<br>Waited</th>'||LF||
          '<th>Average<br>Wait Time</th>'||LF||
          '<th>Max<br>Wait Time</th>'||LF||
          '<th>Blocks</th>'||LF||
          '<th>Average<br>Blocks</th>'||LF||
          '</tr>'||LF);

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

            printf('<tr>'||LF||
            '<td>'||l_row||'</td>'||LF||
            '<td class="right">'||i.obj#||'</td>'||LF||
            '<td class="left">'||i.segment_type||'</td>'||LF||
            '<td class="left">'||i.segment_name||'</td>'||LF||
            '<td class="left">'||i.event_name||'</td>'||LF||
            '<td class="right">'||i.wait_time||'</td>'||LF||
            '<td class="right">'||i.times_waited||'</td>'||LF||
            '<td class="right">'||i.avg_wait_time||'</td>'||LF||
            '<td class="right">'||i.max_wait_time||'</td>'||LF||
            '<td class="right">'||i.blocks||'</td>'||LF||
            '<td class="right">'||i.avg_blocks||'</td>'||LF||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF||
          '<font class="tablenote">'||LF||
          '(1) Content based on '||trca$g.g_tool_name||' data dictionary (dbid:'||trca$g.g_dict_database_id||', host:'||trca$g.g_dict_host_name||').<br>'||LF||
          '(2) This list is constrained by threshold configuration parameter with current value of '||trca$g.g_wait_time_th||'s.<br>'||LF||
          '</font>'||LF);
        END;

        -- summary by start time
        DECLARE
          l_row INTEGER := 0;
        BEGIN
          IF incl_segment_io_summary2 THEN
            printf(
            '<br><table>'||LF||
            '<tr>'||LF||
            '<th>#</th>'||LF||
            '<th>Obj</th>'||LF||
            '<th>Type</th>'||LF||
            '<th>Segment Name<sup>1</sup></th>'||LF||
            '<th>Start Timestamp</th>'||LF||
            '<th>End Timestamp</th>'||LF||
            '<th>Response<br>Time<sup>2</sup></th>'||LF||
            '<th>Wait<br>Time<sup>3</sup></th>'||LF||
            '<th>Blocks</th>'||LF||
            '</tr>'||LF);

            FOR i IN (SELECT *
                        FROM trca$_sql_wait_seg_cons_vf
                       WHERE group_id          = p_group_id
                         AND tool_execution_id = p_tool_execution_id
                       ORDER BY
                             start_tim,
                             response)
            LOOP
              l_row := l_row + 1;

              printf('<tr>'||LF||
              '<td>'||l_row||'</td>'||LF||
              '<td class="right">'||i.obj#||'</td>'||LF||
              '<td class="left">'||i.segment_type||'</td>'||LF||
              '<td class="left">'||i.segment_name||'</td>'||LF||
              '<td class="left">'||i.start_timestamp||'</td>'||LF||
              '<td class="left">'||i.end_timestamp||'</td>'||LF||
              '<td class="right">'||i.response_time||'</td>'||LF||
              '<td class="right">'||i.wait_time||'</td>'||LF||
              '<td class="right">'||i.blocks||'</td>'||LF||
              '</tr>'||LF);
            END LOOP;

            printf('</table>'||LF||
            '<font class="tablenote">'||LF||
            '(1) Content based on '||trca$g.g_tool_name||' data dictionary (dbid:'||trca$g.g_dict_database_id||', host:'||trca$g.g_dict_host_name||').<br>'||LF||
            '(2) According to timestamps of first and last wait in this segment.<br>'||LF||
            '(3) This list is constrained by threshold configuration parameter with current value of '||trca$g.g_wait_time_th||'s.<br>'||LF||
            '</font>'||LF);
          END IF; -- incl_segment_io_summary2
        END;

        printf(back_to_top(p_group_id)||LF||end_show_and_hide||LF);
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

      BEGIN
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

        printf('<a name="rex'||p_group_id||'"></a>'||LF||
        '<h3>Relevant Executions</h3>'||LF||
        begin_show('SHREX'||p_group_id)||LF);

        printf('<br>There are '||l_exec_count||' relevant executions of this SQL statement. Their aggregate "Response Time Accounted-for" represents '||trca$g.format_perc1(100 * l_grp_contribution)||' of this "SQL Response Time Accounted-for", and '||trca$g.format_perc1(100 * l_trc_contribution)||' of the "Total Response Time Accounted-for".');

        IF (grp_rec.top_sql = 'Y' OR grp_rec.top_sql_et = 'Y' OR grp_rec.top_sql_ct = 'Y') AND l_exec_count > 1 THEN
          IF l_top_exec_count = 0 THEN
           printf('<br>Within these '||l_exec_count||' SQL execuctions, there isn''t any with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_exec_th))||' of the "SQL Response Time Accounted-for".<br><br>');
          ELSIF l_top_exec_count = 1 THEN
            printf('<br>Within these '||l_exec_count||' SQL execuctions, there is only one with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_exec_th))||' of the "SQL Response Time Accounted-for".<br><br>');
          ELSE
            printf('<br>Within these '||l_exec_count||' SQL execuctions, there are '||l_top_exec_count||' with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_exec_th))||' of the "SQL Response Time Accounted-for".<br>'||LF||
            'These combined top '||l_top_exec_count||' executions of this SQL are responsible for a total of '||trca$g.format_perc1(100 * l_top_grp_contribution)||' of the "SQL Response Time Accounted-for", and for a total of '||trca$g.format_perc1(100 * l_top_trc_contribution)||' of the "Total Response Time Accounted-for".<br><br>');
          END IF;
        ELSE
          printf('<br><br>');
        END IF;

        printf(
        '<table>'||LF||
        '<tr>'||LF||
        '<th>First/<br>Last</th>'||LF||
        '<th>Rank</th>'||LF||
        '<th>SQL<br>RT<br>Pct<sup>1</sup></th>'||LF||
        '<th>Trace<br>RT<br>Pct<sup>2</sup></th>'||LF||
        '<th>Self<br>Response<br>Time<sup>3</sup></th>'||LF||
        '<th>Elapsed<br>Time</th>'||LF||
        '<th>CPU Time</th>'||LF||
        '<th>Non-Idle<br>Wait Time</th>'||LF||
        '<th>Idle<br>Wait Time</th>'||LF||
        '<th>Recursive<br>Response<br>Time<sup>4</sup></th>'||LF||
        '<th>Start Timestamp</th>'||LF||
        '<th>End Timestamp</th>'||LF||
        '<th>Response<br>Time<sup>5</sup></th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_exec_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND group_id          = p_group_id
                   ORDER BY
                         exec_id)
        LOOP
          l_txt_grp_contribution := i.grp_contribution;
          l_txt_trc_contribution := i.trc_contribution;

          IF i.top_exec = 'Y' THEN
            l_txt_grp_contribution := '<font color="#FF0000">'||l_txt_grp_contribution||'</font>';
            l_txt_trc_contribution := '<font color="#FF0000">'||l_txt_trc_contribution||'</font>';
          END IF;

          printf('<tr>'||LF||
          '<td class="title">'||i.first_last||':</td>'||LF||
          '<td class="right"><a href="#exec'||i.exec_id||'">'||i.rank||'</a></td>'||LF||
          '<td class="right">'||l_txt_grp_contribution||'</td>'||LF||
          '<td class="right">'||l_txt_trc_contribution||'</td>'||LF||
          '<td class="right">'||i.response_time_self||'</td>'||LF||
          '<td class="right">'||i.elapsed||'</td>'||LF||
          '<td class="right">'||i.cpu||'</td>'||LF||
          '<td class="right">'||i.non_idle_wait||'</td>'||LF||
          '<td class="right">'||i.idle_wait||'</td>'||LF||
          '<td class="right">'||i.response_time_progeny||'</td>'||LF||
          '<td class="left">'||i.start_timestamp||'</td>'||LF||
          '<td class="left">'||i.end_timestamp||'</td>'||LF||
          '<td class="right">'||i.response_time||'</td>'||LF||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF||
        '<font class="tablenote">'||LF||
        '(1) Percent of "SQL Response Time Accounted-for", which is '||sql_vf.response_time_self||' secs.<br>'||LF||
        '(2) Percent of "Total Response Time Accounted-for", which is '||rtf_rec.accounted_for_response_time||' secs.<br>'||LF||
        '(3) "Self Response Time Accounted-for" in secs (caused by this execution).<br>'||LF||
        '(4) "Recursive Response Time Accounted-for" in secs (caused by recursive SQL invoked by this execution).<br>'||LF||
        '(5) According to timestamps of first and last calls for this execution.<br>'||LF||
        '</font>'||LF||back_to_top(p_group_id)||LF);

        printf(end_show_and_hide||LF);

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

    printf(LF||'<hr size="1">'||LF);
  EXCEPTION
    WHEN OTHERS THEN
      print_log('*** cannot generate html for group '||p_group_id||' '||SQLERRM);
  END gen_html_group;

  /*************************************************************************************/

  /* -------------------------
   *
   * public gen_html_report
   *
   * called by trca$i.trcanlzr
   *
   * ------------------------- */
  PROCEDURE gen_html_report (
    p_tool_execution_id   IN  INTEGER,
    p_file_name           IN  VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN  VARCHAR2 DEFAULT NULL,
    x_html_report         OUT CLOB )
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

  BEGIN /* gen_html_report */
    IF NOT trca$g.g_log_open THEN
      RETURN;
    END IF;
    l_phase := 'initialization';

    print_log('=> gen_html_report');

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
      l_file_name := p_file_name||'trca_e'||p_tool_execution_id||l_out_file_identifier||'.html';
    END IF;

    UPDATE trca$_tool_execution
       SET html_file_name = l_file_name
     WHERE id = p_tool_execution_id;
    COMMIT;

    s_file_rec := NULL;
    s_file_rec.tool_execution_id := p_tool_execution_id;
    s_file_rec.file_type := 'HTML';
    s_file_rec.filename := l_file_name;
    s_file_rec.file_date := SYSDATE;
    s_file_rec.username := USER;
    s_file_rec.file_text := '<html><head>';

    /* -------------------------
     * Do not generate
     * ------------------------- */
    IF trca$g.g_gen_html_report = 'N' THEN
      printf('To enable: SQL> EXEC '||LOWER(trca$g.g_tool_administer_schema)||'.trca$g.set_param(''gen_html_report'', ''Y'');');
      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      INSERT INTO trca$_file VALUES s_file_rec;
      COMMIT;
      print_log('<= gen_html_report');
      RETURN;
    END IF;

    /* -------------------------
     * Title and JavaScripts
     * ------------------------- */
    l_phase := 'javascript';

    BEGIN
      printf(
'<title>'||l_file_name||'</title>

<style type="text/css">
body {font:10pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}
a {font-weight:bold; color:#663300;}
h1 {font-size:16pt; font-weight:bold; color:#336699;}
h2 {font-size:14pt; font-weight:bold; color:#336699;}
h3 {font-size:12pt; font-weight:bold; color:#336699;}
h4 {font-size:10pt; font-weight:bold; color:#336699;}
li {font-size:10pt; font-weight:bold; color:#336699;}
table {font-size:8pt; color:black; background:white;}
th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
td {text-align:center; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
td.left {text-align:left;}
td.right {text-align:right;}
td.title {text-align:right; font-weight:bold; color:#336699; background:#cccc99;}
td.white {background:white;}
td.op {font:8pt Courier New; text-align:left; color:black;}
font.term {color:#336699;font-weight:bold}
font.tablenote {font-size:8pt; font-style:italic; color:#336699;}
font.goto {font-size:8pt;}
font.footer {font-size:8pt; color:#999999;}
</style>

<script type="text/javascript">
//<!-- show and hide
function snh(id_control, id_text) {
   var v_control = document.getElementById(id_control);
   var v_text = document.getElementById(id_text);

   if(v_control.innerHTML == ''-'')
     v_control.innerHTML = ''+'';
   else
     v_control.innerHTML = ''-'';

   if(v_text.style.display == ''block'')
      v_text.style.display = ''none'';
   else
      v_text.style.display = ''block'';
   }
//-->
</script>

</head><body><a name="toc"></a>
<h1>224270.1 TRCA '||trca$g.g_tool_name||' '||trca$g.g_tool_version||' Report: '||l_file_name||'</h1>');

      FOR i IN (SELECT *
                  FROM trca$_trace
                 WHERE tool_execution_id = p_tool_execution_id)
      LOOP
        printf(i.file_name||' ('||i.file_len||' bytes)<br>');
      END LOOP;
      --'Directory: '||tool_rec.directory_path||'<br>'||LF||
      printf('<br>Total Trace Response Time: '||rtf_rec.total_response_time||' secs.<br>'||LF||
      rtf_rec.start_timestamp||' (start of first db call in trace '||(rtf_rec.start_tim / 1e6)||').<br>'||LF||
      rtf_rec.end_timestamp||' (end of last db call in trace '||(rtf_rec.end_tim / 1e6)||').<br>'||LF);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display title: '||SQLERRM);
    END;

    /***********************************************************************************/

    /* -------------------------
     * Table of Contents
     * ------------------------- */
    l_phase := 'toc';

    BEGIN
      printf('<ul>'||LF||
      '<li><a href="#term">Glossary of Terms Used</a>'||LF||
      '<li><a href="#resp">Response Time Summary</a>'||LF||
      '<li><a href="#trtt">Overall Time and Totals</a>'||LF||
      '<li><a href="#nrtt">Non-Recursive Time and Totals</a>'||LF||
      '<li><a href="#rctt">Recursive Time and Totals</a>'||LF||
      '<li><a href="#tsql">Top SQL</a>'||LF||
      '<li><a href="#nsql">Non-Recursive SQL</a>'||LF||
      '<li><a href="#sqlg">SQL Genealogy</a>'||LF||
      '<li><a href="#isql">Individual SQL</a>'||LF||
      '<li><a href="#iows">Overall Segment I/O Wait Summary</a>'||LF||
      '<li><a href="#hiob">Hot I/O Blocks</a>'||LF||
      '<li><a href="#gapt">Gaps in Trace</a></li>'||LF||
      '<li><a href="#eror">ORA errors in Trace</a></li>'||LF||
      '<li><a href="#tran">Transactions Summary</a></li>'||LF||
      '<li><a href="#init">Non-default Initialization Params</a></li>'||LF||
      '<li><a href="#thea">Trace Header</a></li>'||LF||
      '<li><a href="#tdic">Tool Data Dictionary</a></li>'||LF||
      '<li><a href="#tenv">Tool Execution Environment</a></li>'||LF||
      '<li><a href="#conf">Tool Configuration Parameters</a>'||LF||
      '</ul>');
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display toc: '||SQLERRM);
    END;

    /***********************************************************************************/

    /* -------------------------
     * Glossary of Terms Used
     * ------------------------- */
    l_phase := 'glossary';

    BEGIN
      printf(LF||'<a name="term"></a>'||LF||
      '<h2>Glossary of Terms Used</h2>'||LF||
      --begin_hide('SHTERM', '<br>'||LF||
      begin_hide('SHTERM', LF||
      '<font class=term>DB Call</font><br>'||LF||
      'Database kernel operation, such as "Parse", "Execute", "Fetch", "Unmap" and "Sort Unmap".<br><br>'||LF||
      '<font class=term>CPU Time</font><br>'||LF||
      'Amount of CPU time consumed by one db call, or a set of calls.<br><br>'||LF||
      '<font class=term>Wait Event</font><br>'||LF||
      'Sequence of kernel instructions that consume wall-clock time.<br><br>'||LF||
      '<font class=term>Non-Idle Wait Event</font><br>'||LF||
      'Wait event that originates within a db call, for example "db file sequential read".<br><br>'||LF||
      '<font class=term>Idle Wait Event</font><br>'||LF||
      'Wait event that originates between db calls, for example "SQL*Net message from client".<br><br>'||LF||
      '<font class=term>Non-Idle Wait Time</font><br>'||LF||
      'Wall-clock time or duration of a non-idle wait event.<br><br>'||LF||
      '<font class=term>Idle Wait Time</font><br>'||LF||
      'Wall-clock time or duration of an idle wait event.<br><br>'||LF||
      '<font class=term>Unaccounted-for Time</font><br>'||LF||
      'Under-counted (+) or over-counted (-) time difference between wall-clock time and that recorded in a trace file.<br>'||LF||
      'There are several valid reasons for this unaccounted-for time. Refer to literature for further explanation.<br>'||LF||
      'Ignore this time slice if it accounts for less than a small threshold (like 10% of total wall-clock time).<br><br>'||LF||
      '<font class=term>Elapsed Time</font><br>'||LF||
      'Wall-clock time of a db call or a set of calls. It includes CPU and non-idle wait times.<br>'||LF||
      'Elapsed Time = "CPU" + "Non-Idle Wait" + "Elapsed Unaccounted-for" times.<br><br>'||LF||
      '<font class=term>Response Time</font><br>'||LF||
      'Wall-clock time for a traced process. It is also refered as user time.<br>'||LF||
      'Response time has been measured using timestamps of first and last db calls found in trace.<br>'||LF||
      'It includes elapsed time and idle wait times. It can be analyzed slicing it into its components in several ways.<br>'||LF||
      'Response Time = "End of last db Call" - "Start of fisrt db Call".<br>'||LF||
      'Response Time = "Elapsed" + "Idle Wait" + "Response Unaccounted-for" times.<br>'||LF||
      'Response Time = "CPU" + "Non-Idle Wait" + "Elapsed Unaccounted-for" + "Idle Wait" + "Response Unaccounted-for" times.<br>'||LF||
      'Response Time = "CPU" + "Non-Idle Wait" + "Idle Wait" + "Unaccounted-for" times.<br>'||LF||
      'Response Time = "CPU" + "Wait" + "Unaccounted-for" times.<br><br>'||LF||
      '<font class=term>Response Time Accounted-for</font><br>'||LF||
      'Response Time Accounted-for = "Elapsed" + "Idle Wait" times.<br><br>'||LF||
      '<font class=term>Buffer Gets in Consistent Read Mode</font><br>'||LF||
      'Oracle buffers reads from the buffer cache, usually associated with queries.<br><br>'||LF||
      '<font class=term>Buffer Gets in Current Mode</font><br>'||LF||
      'Oracle buffers reads from the buffer cache, usually associated with updates.<br><br>'||LF||
      '<font class=term>Logical IO</font><br>'||LF||
      'Buffer gets from buffer cache in either mode (consistent or current). LIOs are CPU intensive.<br>'||LF||
      'PIOs counts are included in LIOs counts.<br><br>'||LF||
      '<font class=term>Operating System Buffer Gets</font><br>'||LF||
      'Oracle blocks obtained from the OS. They are also referred as Physical IOs. PIOs are Non-Idle Wait intensive.<br>')||
      end_show_and_hide);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display glossary of terms: '||SQLERRM);
    END;

    /***********************************************************************************/

    /* -------------------------
     * Response Time Summary
     * ------------------------- */
    l_phase := 'response_summary';

    BEGIN
      print_log('-> '||l_phase);
      printf(LF||'<a name="resp"></a>'||LF||
      '<h2>Response Time Summary</h2>'||LF||
      '<table>'||LF||
      '<tr><th>Response Time Component</th><th>Time<br>(in secs)</th><th>pct of<br>total<br>resp time</th><th>Time<br>(in secs)</th><th>pct of<br>total<br>resp time</th><th>Time<br>(in secs)</th><th>pct of<br>total<br>resp time</th></tr>'||LF||
      title_and_value('CPU Time:', rtf_rec.cpu, rtf_rec.cpu_perc, NBSP, NBSP, NBSP, NBSP)||
      title_and_value('Non-idle Wait Time:', rtf_rec.non_idle_wait, rtf_rec.non_idle_wait_perc, NBSP, NBSP, NBSP, NBSP)||
      title_and_value('ET Unaccounted-for Time:', rtf_rec.elapsed_unaccounted_for, rtf_rec.elapsed_unaccounted_for_perc, NBSP, NBSP, NBSP, NBSP)||
      title_and_value('Total Elapsed Time<sup>1</sup>:', NBSP, NBSP, rtf_rec.elapsed, rtf_rec.elapsed_perc, NBSP, NBSP)||
      title_and_value('Idle Wait Time:', NBSP, NBSP, rtf_rec.idle_wait, rtf_rec.idle_wait_perc, NBSP, NBSP)||
      title_and_value('RT Unaccounted-for Time:', NBSP, NBSP, rtf_rec.response_unaccounted_for, rtf_rec.response_unaccounted_for_perc, NBSP, NBSP)||
      title_and_value('Total Response Time<sup>2</sup>:', NBSP, NBSP, NBSP, NBSP, rtf_rec.total_response_time, rtf_rec.total_response_time_perc)||
      '</table>'||LF||
      '<font class="tablenote">'||LF||
      '(1) Total Elapsed Time = "CPU Time" + "Non-Idle Wait Time" + "ET Unaccounted-for Time".<br>'||LF||
      '(2) Total Response Time = "Total Elapsed Time" + "Idle Wait Time" + "RT Unaccounted-for Time".<br>'||LF||
      'Total Accounted-for Time = "CPU Time" + "Non-Idle Wait Time" + "Idle Wait Time" = '||rtf_rec.accounted_for_response_time||' secs.<br>'||LF||
      'Total Unccounted-for Time = "ET Unaccounted-for Time" + "RT Unaccounted-for Time" = '||rtf_rec.total_unaccounted_for||' secs.<br>'||LF||
      '</font>'||LF||BACK_TOP||LF);

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

    printf(LF||'<a name="trtt"></a>'||LF||
    '<h2>Overall Time and Totals (Non-Recursive and Recursive)</h2>'||LF||
    begin_show('SHTRTT')||LF);

    -- time
    BEGIN
      printf(
      '<table>'||LF||
      '<tr>'||LF||
      '<th>Call</th>'||LF||
      '<th>Total<br>Response Time<sup>3</sup></th>'||LF||
      '<th>Response Time<br>Accounted-for<sup>2</sup></th>'||LF||
      '<th>Elapsed<br>Time<sup>1</sup></th>'||LF||
      '<th>CPU Time</th>'||LF||
      '<th>Non-Idle<br>Wait Time</th>'||LF||
      '<th>Elapsed Time<br>Unaccounted-for</th>'||LF||
      '<th>Idle<br>Wait Time</th>'||LF||
      '<th>Response Time<br>Unaccounted-for</th>'||LF||
      '</tr>'||LF);

      FOR i IN (SELECT *
                  FROM trca$_trc_overall_time_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        printf('<tr>'||LF||
        '<td class="title">'||i.call_type||':</td>'||LF||
        '<td class="right">'||i.response||'</td>'||LF||
        '<td class="right">'||i.accounted_response||'</td>'||LF||
        '<td class="right">'||i.elapsed||'</td>'||LF||
        '<td class="right">'||i.cpu||'</td>'||LF||
        '<td class="right">'||i.non_idle_wait||'</td>'||LF||
        '<td class="right">'||i.elapsed_unaccounted_for||'</td>'||LF||
        '<td class="right">'||i.idle_wait||'</td>'||LF||
        '<td class="right">'||i.response_unaccounted_for||'</td>'||LF||
        '</tr>'||LF);
      END LOOP;

      printf('</table>'||LF||
      '<font class="tablenote">'||LF||
      '(1) Elapsed Time = "CPU Time" + "Non-Idle Wait Time" + "Elapsed Time Unaccounted-for".<br>'||LF||
      '(2) Response Time Accounted-for = "Elapsed Time" + "Idle Wait Time".<br>'||LF||
      '(3) Total Response Time = "Response Time Accounted-for" + "Response Time Unaccounted-for".<br>'||LF||
      '</font>'||LF);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display overall time: '||SQLERRM);
    END;

    -- totals
    BEGIN
      printf(
      '<br><table>'||LF||
      '<tr>'||LF||
      '<th>Call</th>'||LF||
      '<th>Call<br>Count</th>'||LF||
      '<th>OS<br>Buffer Gets<br>(disk)</th>'||LF||
      '<th>BG Consistent<br>Read Mode<br>(query)</th>'||LF||
      '<th>BG Current<br>Mode<br>(current)</th>'||LF||
      '<th>Rows<br>Processed<br>or Returned</th>'||LF||
      '<th>Library<br>Cache<br>Misses</th>'||LF||
      '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
      '<th>Times<br>Waited<br>Idle</th>'||LF||
      '</tr>'||LF);

      FOR i IN (SELECT *
                  FROM trca$_trc_overall_total_v
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        printf('<tr>'||LF||
        '<td class="title">'||i.call_type||':</td>'||LF||
        '<td class="right">'||i.call_count||'</td>'||LF||
        '<td class="right">'||i.p_disk_os||'</td>'||LF||
        '<td class="right">'||i.cr_query_consistent||'</td>'||LF||
        '<td class="right">'||i.cu_current||'</td>'||LF||
        '<td class="right">'||i.r_rows||'</td>'||LF||
        '<td class="right">'||i.mis_library_cache_misses||'</td>'||LF||
        '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
        '<td class="right">'||i.wait_count_idle||'</td>'||LF||
        '</tr>'||LF);
      END LOOP;

      printf('</table>'||LF);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display overall totals: '||SQLERRM);
    END;

    -- waits
    IF trca$g.g_include_waits = 'Y' THEN
      DECLARE
        l_count INTEGER;

      BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM trca$_trc_overall_wait_vf
         WHERE tool_execution_id = p_tool_execution_id
           AND ROWNUM = 1;

        IF l_count > 0 THEN
          printf(
          '<br><table>'||LF||
          '<tr>'||LF||
          '<th>Event Name</th>'||LF||
          '<th>Wait Class</th>'||LF||
          '<th>Non-Idle<br>Wait Time</th>'||LF||
          '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
          '<th>Idle<br>Wait Time</th>'||LF||
          '<th>Times<br>Waited<br>Idle</th>'||LF||
          '<th>Average<br>Wait Time</th>'||LF||
          '<th>Max<br>Wait Time</th>'||LF||
          '<th>Blocks</th>'||LF||
          '<th>Average<br>Blocks</th>'||LF||
          '</tr>'||LF);

          FOR i IN (SELECT *
                      FROM trca$_trc_overall_wait_vf
                     WHERE tool_execution_id = p_tool_execution_id
                     ORDER BY
                           row_type,
                           wait DESC)
          LOOP
            printf('<tr>'||LF||
            '<td class="title">'||i.event_name||':</td>'||LF||
            '<td class="left">'||i.wait_class||'</td>'||LF||
            '<td class="right">'||i.non_idle_wait||'</td>'||LF||
            '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
            '<td class="right">'||i.idle_wait||'</td>'||LF||
            '<td class="right">'||i.wait_count_idle||'</td>'||LF||
            '<td class="right">'||i.avg_wait||'</td>'||LF||
            '<td class="right">'||i.max_wait||'</td>'||LF||
            '<td class="right">'||i.blocks||'</td>'||LF||
            '<td class="right">'||i.avg_blocks||'</td>'||LF||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF||BACK_TOP||LF);
        END IF; -- l_count > 0
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display overall waits: '||SQLERRM);
      END;
    END IF; -- trca$g.g_include_waits = 'Y'

    printf(end_show_and_hide||LF);
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Non-Recursive Time and Totals
     * ------------------------- */
    l_phase := 'non-recursive_totals';
    print_log('-> '||l_phase);

    printf(LF||'<a name="nrtt"></a>'||LF||
    '<h2>Non-Recursive Time and Totals (depth = 0)</h2>'||LF||
    begin_show('SHNRTT')||LF);

    -- time
    BEGIN
      printf(
      '<table>'||LF||
      '<tr>'||LF||
      '<th>Call</th>'||LF||
      '<th>Response Time<br>Accounted-for</th>'||LF||
      '<th>Elapsed<br>Time</th>'||LF||
      '<th>CPU Time</th>'||LF||
      '<th>Non-Idle<br>Wait Time</th>'||LF||
      '<th>Elapsed Time<br>Unaccounted-for</th>'||LF||
      '<th>Idle<br>Wait Time</th>'||LF||
      '</tr>'||LF);

      FOR i IN (SELECT *
                  FROM trca$_trc_non_recu_time_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        printf('<tr>'||LF||
        '<td class="title">'||i.call_type||':</td>'||LF||
        '<td class="right">'||i.accounted_response||'</td>'||LF||
        '<td class="right">'||i.elapsed||'</td>'||LF||
        '<td class="right">'||i.cpu||'</td>'||LF||
        '<td class="right">'||i.non_idle_wait||'</td>'||LF||
        '<td class="right">'||i.elapsed_unaccounted_for||'</td>'||LF||
        '<td class="right">'||i.idle_wait||'</td>'||LF||
        '</tr>'||LF);
      END LOOP;

      printf('</table>'||LF);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display non-recursive time: '||SQLERRM);
    END;

    -- totals
    BEGIN
      printf(
      '<br><table>'||LF||
      '<tr>'||LF||
      '<th>Call</th>'||LF||
      '<th>Call<br>Count</th>'||LF||
      '<th>OS<br>Buffer Gets<br>(disk)</th>'||LF||
      '<th>BG Consistent<br>Read Mode<br>(query)</th>'||LF||
      '<th>BG Current<br>Mode<br>(current)</th>'||LF||
      '<th>Rows<br>Processed<br>or Returned</th>'||LF||
      '<th>Library<br>Cache<br>Misses</th>'||LF||
      '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
      '<th>Times<br>Waited<br>Idle</th>'||LF||
      '</tr>'||LF);

      FOR i IN (SELECT *
                  FROM trca$_trc_non_recu_total_v
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        printf('<tr>'||LF||
        '<td class="title">'||i.call_type||':</td>'||LF||
        '<td class="right">'||i.call_count||'</td>'||LF||
        '<td class="right">'||i.p_disk_os||'</td>'||LF||
        '<td class="right">'||i.cr_query_consistent||'</td>'||LF||
        '<td class="right">'||i.cu_current||'</td>'||LF||
        '<td class="right">'||i.r_rows||'</td>'||LF||
        '<td class="right">'||i.mis_library_cache_misses||'</td>'||LF||
        '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
        '<td class="right">'||i.wait_count_idle||'</td>'||LF||
        '</tr>'||LF);
      END LOOP;

      printf('</table>'||LF);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display non-recursive totals: '||SQLERRM);
    END;

    -- waits
    IF trca$g.g_include_waits = 'Y' THEN
      DECLARE
        l_count INTEGER;

      BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM trca$_trc_non_recu_wait_vf
         WHERE tool_execution_id = p_tool_execution_id
           AND ROWNUM = 1;

        IF l_count > 0 THEN
          printf(
          '<br><table>'||LF||
          '<tr>'||LF||
          '<th>Event Name</th>'||LF||
          '<th>Wait Class</th>'||LF||
          '<th>Non-Idle<br>Wait Time</th>'||LF||
          '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
          '<th>Idle<br>Wait Time</th>'||LF||
          '<th>Times<br>Waited<br>Idle</th>'||LF||
          '<th>Average<br>Wait Time</th>'||LF||
          '<th>Max<br>Wait Time</th>'||LF||
          '<th>Blocks</th>'||LF||
          '<th>Average<br>Blocks</th>'||LF||
          '</tr>'||LF);

          FOR i IN (SELECT *
                      FROM trca$_trc_non_recu_wait_vf
                     WHERE tool_execution_id = p_tool_execution_id
                     ORDER BY
                           row_type,
                           wait DESC)
          LOOP
            printf('<tr>'||LF||
            '<td class="title">'||i.event_name||':</td>'||LF||
            '<td class="left">'||i.wait_class||'</td>'||LF||
            '<td class="right">'||i.non_idle_wait||'</td>'||LF||
            '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
            '<td class="right">'||i.idle_wait||'</td>'||LF||
            '<td class="right">'||i.wait_count_idle||'</td>'||LF||
            '<td class="right">'||i.avg_wait||'</td>'||LF||
            '<td class="right">'||i.max_wait||'</td>'||LF||
            '<td class="right">'||i.blocks||'</td>'||LF||
            '<td class="right">'||i.avg_blocks||'</td>'||LF||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF||BACK_TOP||LF);
        END IF; -- l_count > 0
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display non-recursive waits: '||SQLERRM);
      END;
    END IF; -- trca$g.g_include_waits = 'Y'

    printf(end_show_and_hide||LF);
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Recursive Time and Totals
     * ------------------------- */
    l_phase := 'recursive_totals';
    print_log('-> '||l_phase);

    printf(LF||'<a name="rctt"></a>'||LF||
    '<h2>Recursive Time and Totals (depth > 0)</h2>'||LF||
    begin_show('SHRCTT')||LF);

    -- time
    BEGIN
      printf(
      '<table>'||LF||
      '<tr>'||LF||
      '<th>Call</th>'||LF||
      '<th>Response Time<br>Accounted-for</th>'||LF||
      '<th>Elapsed<br>Time</th>'||LF||
      '<th>CPU Time</th>'||LF||
      '<th>Non-Idle<br>Wait Time</th>'||LF||
      '<th>Elapsed Time<br>Unaccounted-for</th>'||LF||
      '<th>Idle<br>Wait Time</th>'||LF||
      '</tr>'||LF);

      FOR i IN (SELECT *
                  FROM trca$_trc_recu_time_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        printf('<tr>'||LF||
        '<td class="title">'||i.call_type||':</td>'||LF||
        '<td class="right">'||i.accounted_response||'</td>'||LF||
        '<td class="right">'||i.elapsed||'</td>'||LF||
        '<td class="right">'||i.cpu||'</td>'||LF||
        '<td class="right">'||i.non_idle_wait||'</td>'||LF||
        '<td class="right">'||i.elapsed_unaccounted_for||'</td>'||LF||
        '<td class="right">'||i.idle_wait||'</td>'||LF||
        '</tr>'||LF);
      END LOOP;

      printf('</table>'||LF);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display recursive time: '||SQLERRM);
    END;

    -- totals
    BEGIN
      printf(
      '<br><table>'||LF||
      '<tr>'||LF||
      '<th>Call</th>'||LF||
      '<th>Call<br>Count</th>'||LF||
      '<th>OS<br>Buffer Gets<br>(disk)</th>'||LF||
      '<th>BG Consistent<br>Read Mode<br>(query)</th>'||LF||
      '<th>BG Current<br>Mode<br>(current)</th>'||LF||
      '<th>Rows<br>Processed<br>or Returned</th>'||LF||
      '<th>Library<br>Cache<br>Misses</th>'||LF||
      '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
      '<th>Times<br>Waited<br>Idle</th>'||LF||
      '</tr>'||LF);

      FOR i IN (SELECT *
                  FROM trca$_trc_recu_total_v
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       call)
      LOOP
        printf('<tr>'||LF||
        '<td class="title">'||i.call_type||':</td>'||LF||
        '<td class="right">'||i.call_count||'</td>'||LF||
        '<td class="right">'||i.p_disk_os||'</td>'||LF||
        '<td class="right">'||i.cr_query_consistent||'</td>'||LF||
        '<td class="right">'||i.cu_current||'</td>'||LF||
        '<td class="right">'||i.r_rows||'</td>'||LF||
        '<td class="right">'||i.mis_library_cache_misses||'</td>'||LF||
        '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
        '<td class="right">'||i.wait_count_idle||'</td>'||LF||
        '</tr>'||LF);
      END LOOP;

      printf('</table>'||LF);
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display recursive totals: '||SQLERRM);
    END;

    -- waits
    IF trca$g.g_include_waits = 'Y' THEN
      DECLARE
        l_count INTEGER;

      BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM trca$_trc_recu_wait_vf
         WHERE tool_execution_id = p_tool_execution_id
           AND ROWNUM = 1;

        IF l_count > 0 THEN
          printf(
          '<br><table>'||LF||
          '<tr>'||LF||
          '<th>Event Name</th>'||LF||
          '<th>Wait Class</th>'||LF||
          '<th>Non-Idle<br>Wait Time</th>'||LF||
          '<th>Times<br>Waited<br>Non-Idle</th>'||LF||
          '<th>Idle<br>Wait Time</th>'||LF||
          '<th>Times<br>Waited<br>Idle</th>'||LF||
          '<th>Average<br>Wait Time</th>'||LF||
          '<th>Max<br>Wait Time</th>'||LF||
          '<th>Blocks</th>'||LF||
          '<th>Average<br>Blocks</th>'||LF||
          '</tr>'||LF);

          FOR i IN (SELECT *
                      FROM trca$_trc_recu_wait_vf
                     WHERE tool_execution_id = p_tool_execution_id
                     ORDER BY
                           row_type,
                           wait DESC)
          LOOP
            printf('<tr>'||LF||
            '<td class="title">'||i.event_name||':</td>'||LF||
            '<td class="left">'||i.wait_class||'</td>'||LF||
            '<td class="right">'||i.non_idle_wait||'</td>'||LF||
            '<td class="right">'||i.wait_count_non_idle||'</td>'||LF||
            '<td class="right">'||i.idle_wait||'</td>'||LF||
            '<td class="right">'||i.wait_count_idle||'</td>'||LF||
            '<td class="right">'||i.avg_wait||'</td>'||LF||
            '<td class="right">'||i.max_wait||'</td>'||LF||
            '<td class="right">'||i.blocks||'</td>'||LF||
            '<td class="right">'||i.avg_blocks||'</td>'||LF||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF||BACK_TOP||LF);
        END IF; -- l_count > 0
      EXCEPTION
        WHEN OTHERS THEN
          print_log('*** cannot display recursive waits: '||SQLERRM);
      END;
    END IF; -- trca$g.g_include_waits = 'Y'

    printf(end_show_and_hide||LF);
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Top SQL
     * ------------------------- */
    l_phase := 'top_sql';
    print_log('-> '||l_phase);

    DECLARE
      l_hv                   VARCHAR2(32767);
      l_top_sql_count        INTEGER;
      l_top_sql_contribution NUMBER;
      l_contribution         VARCHAR2(32767);
      l_sql_text             VARCHAR2(32767);
      l_columns              VARCHAR2(32767);

    BEGIN
      printf(LF||'<a name="tsql"></a>'||LF||
      '<h2>Top SQL</h2>'||LF||
      begin_show('SHTSQL')||LF);

      BEGIN -- Response Time
        SELECT COUNT(*), SUM(contribution)
          INTO l_top_sql_count, l_top_sql_contribution
          FROM trca$_sql_v
         WHERE tool_execution_id = p_tool_execution_id
           AND top_sql = 'Y';

        IF l_top_sql_count = 0 THEN
          printf('<br>There are no individual SQL statements with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Response Time Accounted-for".<br><br>');
        ELSIF l_top_sql_count = 1 THEN
          printf('<br>There is only one SQL statement with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Response Time Accounted-for".<br><br>');
        ELSE
          printf('<br>There are '||l_top_sql_count||' SQL statements with "Response Time Accounted-for" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Response Time Accounted-for".<br>'||LF||
          'These combined '||l_top_sql_count||' SQL statements are responsible for a total of '||trca$g.format_perc1(100 * l_top_sql_contribution)||' of the "Total Response Time Accounted-for".<br><br>');
        END IF;

        IF l_top_sql_count > 0 THEN
          l_columns := NULL;
          IF trca$g.g_sqlid = 'Y' THEN
            l_columns := l_columns||'<th>SQL ID</th>'||LF;
          END IF;
          IF trca$g.g_plh = 'Y' THEN
            l_columns := l_columns||'<th>Plan<br>Hash<br>Value</th>'||LF;
          END IF;

          printf(
          '<table>'||LF||
          '<tr>'||LF||
          '<th>Rank</th>'||LF||
          '<th>Trace<br>RT<br>Pct<sup>1</sup></th>'||LF||
          '<th>Self<br>Response<br>Time<sup>2</sup></th>'||LF||
          '<th>Elapsed<br>Time</th>'||LF||
          '<th>CPU Time</th>'||LF||
          '<th>Non-Idle<br>Wait Time</th>'||LF||
          '<th>Idle<br>Wait Time</th>'||LF||
          '<th>Recursive<br>Response<br>Time<sup>3</sup></th>'||LF||
          '<th>Exec<br>Count</th>'||LF||
          '<th>User</th>'||LF||
          '<th>Depth</th>'||LF||
          '<th>SQL Text</th>'||LF||
          '<th>Hash Value</th>'||LF||
          l_columns||
          '</tr>'||LF);

          FOR i IN (SELECT *
                      FROM trca$_sql_vf
                     WHERE tool_execution_id = p_tool_execution_id
                       AND top_sql = 'Y'
                     ORDER BY
                           rank)
          LOOP
            IF i.include_details = 'Y' OR trca$g.g_include_non_top_sql = 'Y'THEN
              l_hv := '<a href="#sql'||i.group_id||'">'||i.hv||'</a>';
            ELSE
              l_hv := i.hv;
            END IF;
            l_columns := NULL;
            IF trca$g.g_sqlid = 'Y' THEN
              l_columns := l_columns||'<td class="left">'||i.sqlid||'</td>'||LF;
            END IF;
            IF trca$g.g_plh = 'Y' THEN
              l_columns := l_columns||'<td class="right">'||i.plh||'</td>'||LF;
            END IF;
            l_contribution := i.contribution;
            l_contribution := '<font color="#FF0000">'||l_contribution||'</font>';
            l_sql_text := trca$g.prepare_html_text(SUBSTR(i.sql_text, 1, 60));
            l_sql_text := '<font color="#FF0000">'||l_sql_text||'</font>';

            printf('<tr>'||LF||
            '<td class="title">'||i.rank||':</td>'||LF||
            '<td class="right">'||l_contribution||'</td>'||LF||
            '<td class="right">'||i.response_time_self||'</td>'||LF||
            '<td class="right">'||i.elapsed_time_self||'</td>'||LF||
            '<td class="right">'||i.cpu_time_self||'</td>'||LF||
            '<td class="right">'||i.non_idle_wait||'</td>'||LF||
            '<td class="right">'||i.idle_wait||'</td>'||LF||
            '<td class="right">'||i.response_time_progeny||'</td>'||LF||
            '<td class="right">'||i.exec_count||'</td>'||LF||
            '<td>'||get_uid_name(i.uid#)||'</td>'||LF||
            '<td>'||i.dep||'</td>'||LF||
            '<td nowrap class="op" title="'||trca$g.wrap_text(i.sql_text_1000, 55, 'N', 'Y')||'">'||l_sql_text||'</td>'||LF||
            '<td class="right">'||l_hv||'</td>'||LF||
            l_columns||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF||
          '<font class="tablenote">'||LF||
          '(1) Percent of "Total Response Time Accounted-for", which is '||rtf_rec.accounted_for_response_time||' secs.<br>'||LF||
          '(2) "Self Response Time Accounted-for" in secs (caused by this SQL statement).<br>'||LF||
          '(3) "Recursive Response Time Accounted-for" in secs (caused by recursive SQL invoked by this statement).<br>'||LF||
          '</font>'||LF||BACK_TOP||LF);
        END IF;
      END; -- Response Time

      BEGIN -- Elapsed Time
        SELECT COUNT(*), SUM(contribution_et)
          INTO l_top_sql_count, l_top_sql_contribution
          FROM trca$_sql_v
         WHERE tool_execution_id = p_tool_execution_id
           AND top_sql_et = 'Y';

        IF l_top_sql_count = 0 THEN
          printf('<br>There are no individual SQL statements with "Elapsed Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Elapsed Time".<br><br>');
        ELSIF l_top_sql_count = 1 THEN
          printf('<br>There is only one SQL statement with "Elapsed Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Elapsed Time".<br><br>');
        ELSE
          printf('<br>There are '||l_top_sql_count||' SQL statements with "Elapsed Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total Elapsed Time".<br>'||LF||
          'These combined '||l_top_sql_count||' SQL statements are responsible for a total of '||trca$g.format_perc1(100 * l_top_sql_contribution)||' of the "Total Elapsed Time".<br><br>');
        END IF;

        IF l_top_sql_count > 0 THEN
          l_columns := NULL;
          IF trca$g.g_sqlid = 'Y' THEN
            l_columns := l_columns||'<th>SQL ID</th>'||LF;
          END IF;
          IF trca$g.g_plh = 'Y' THEN
            l_columns := l_columns||'<th>Plan<br>Hash<br>Value</th>'||LF;
          END IF;

          printf(
          '<table>'||LF||
          '<tr>'||LF||
          '<th>Rank</th>'||LF||
          '<th>Trace<br>ET<br>Pct<sup>1</sup></th>'||LF||
          '<th>Self<br>Elapsed<br>Time<sup>2</sup></th>'||LF||
          '<th>CPU Time</th>'||LF||
          '<th>Non-Idle<br>Wait Time</th>'||LF||
          '<th>Recursive<br>Elapsed<br>Time<sup>3</sup></th>'||LF||
          '<th>Exec<br>Count</th>'||LF||
          '<th>User</th>'||LF||
          '<th>Depth</th>'||LF||
          '<th>SQL Text</th>'||LF||
          '<th>Hash Value</th>'||LF||
          l_columns||
          '</tr>'||LF);

          FOR i IN (SELECT *
                      FROM trca$_sql_vf
                     WHERE tool_execution_id = p_tool_execution_id
                       AND top_sql_et = 'Y'
                     ORDER BY
                           rank_et)
          LOOP
            IF i.include_details = 'Y' OR trca$g.g_include_non_top_sql = 'Y'THEN
              l_hv := '<a href="#sql'||i.group_id||'">'||i.hv||'</a>';
            ELSE
              l_hv := i.hv;
            END IF;
            l_columns := NULL;
            IF trca$g.g_sqlid = 'Y' THEN
              l_columns := l_columns||'<td class="left">'||i.sqlid||'</td>'||LF;
            END IF;
            IF trca$g.g_plh = 'Y' THEN
              l_columns := l_columns||'<td class="right">'||i.plh||'</td>'||LF;
            END IF;
            l_contribution := i.contribution_et;
            l_contribution := '<font color="#FF0000">'||l_contribution||'</font>';
            l_sql_text := trca$g.prepare_html_text(SUBSTR(i.sql_text, 1, 60));
            l_sql_text := '<font color="#FF0000">'||l_sql_text||'</font>';

            printf('<tr>'||LF||
            '<td class="title">'||i.rank_et||':</td>'||LF||
            '<td class="right">'||l_contribution||'</td>'||LF||
            '<td class="right">'||i.elapsed_time_self||'</td>'||LF||
            '<td class="right">'||i.cpu_time_self||'</td>'||LF||
            '<td class="right">'||i.non_idle_wait||'</td>'||LF||
            '<td class="right">'||i.elapsed_time_progeny||'</td>'||LF||
            '<td class="right">'||i.exec_count||'</td>'||LF||
            '<td>'||get_uid_name(i.uid#)||'</td>'||LF||
            '<td>'||i.dep||'</td>'||LF||
            '<td nowrap class="op" title="'||trca$g.wrap_text(i.sql_text_1000, 55, 'N', 'Y')||'">'||l_sql_text||'</td>'||LF||
            '<td class="right">'||l_hv||'</td>'||LF||
            l_columns||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF||
          '<font class="tablenote">'||LF||
          '(1) Percent of "Total Elapsed Time", which is '||rtf_rec.elapsed||' secs.<br>'||LF||
          '(2) "Self Elapsed Time" in secs (caused by this SQL statement).<br>'||LF||
          '(3) "Recursive Elapsed Time" in secs (caused by recursive SQL invoked by this statement).<br>'||LF||
          '</font>'||LF||BACK_TOP||LF);
        END IF;
      END; -- Elapsed Time

      BEGIN -- CPU Time
        SELECT COUNT(*), SUM(contribution_ct)
          INTO l_top_sql_count, l_top_sql_contribution
          FROM trca$_sql_v
         WHERE tool_execution_id = p_tool_execution_id
           AND top_sql_ct = 'Y';

        IF l_top_sql_count = 0 THEN
          printf('<br>There are no individual SQL statements with "CPU Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total CPU Time".<br><br>');
        ELSIF l_top_sql_count = 1 THEN
          printf('<br>There is only one SQL statement with "CPU Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total CPU Time".<br><br>');
        ELSE
          printf('<br>There are '||l_top_sql_count||' SQL statements with "CPU Time" larger than threshold of '||trca$g.format_perc1(TO_NUMBER(trca$g.g_top_sql_th))||' of the "Total CPU Time".<br>'||LF||
          'These combined '||l_top_sql_count||' SQL statements are responsible for a total of '||trca$g.format_perc1(100 * l_top_sql_contribution)||' of the "Total CPU Time".<br><br>');
        END IF;

        IF l_top_sql_count > 0 THEN
          l_columns := NULL;
          IF trca$g.g_sqlid = 'Y' THEN
            l_columns := l_columns||'<th>SQL ID</th>'||LF;
          END IF;
          IF trca$g.g_plh = 'Y' THEN
            l_columns := l_columns||'<th>Plan<br>Hash<br>Value</th>'||LF;
          END IF;

          printf(
          '<table>'||LF||
          '<tr>'||LF||
          '<th>Rank</th>'||LF||
          '<th>Trace<br>CPU<br>Pct<sup>1</sup></th>'||LF||
          '<th>Self<br>CPU<br>Time<sup>2</sup></th>'||LF||
          '<th>Recursive<br>CPU<br>Time<sup>3</sup></th>'||LF||
          '<th>Exec<br>Count</th>'||LF||
          '<th>User</th>'||LF||
          '<th>Depth</th>'||LF||
          '<th>SQL Text</th>'||LF||
          '<th>Hash Value</th>'||LF||
          l_columns||
          '</tr>'||LF);

          FOR i IN (SELECT *
                      FROM trca$_sql_vf
                     WHERE tool_execution_id = p_tool_execution_id
                       AND top_sql_ct = 'Y'
                     ORDER BY
                           rank_ct)
          LOOP
            IF i.include_details = 'Y' OR trca$g.g_include_non_top_sql = 'Y'THEN
              l_hv := '<a href="#sql'||i.group_id||'">'||i.hv||'</a>';
            ELSE
              l_hv := i.hv;
            END IF;
            l_columns := NULL;
            IF trca$g.g_sqlid = 'Y' THEN
              l_columns := l_columns||'<td class="left">'||i.sqlid||'</td>'||LF;
            END IF;
            IF trca$g.g_plh = 'Y' THEN
              l_columns := l_columns||'<td class="right">'||i.plh||'</td>'||LF;
            END IF;
            l_contribution := i.contribution_ct;
            l_contribution := '<font color="#FF0000">'||l_contribution||'</font>';
            l_sql_text := trca$g.prepare_html_text(SUBSTR(i.sql_text, 1, 60));
            l_sql_text := '<font color="#FF0000">'||l_sql_text||'</font>';

            printf('<tr>'||LF||
            '<td class="title">'||i.rank_ct||':</td>'||LF||
            '<td class="right">'||l_contribution||'</td>'||LF||
            '<td class="right">'||i.cpu_time_self||'</td>'||LF||
            '<td class="right">'||i.cpu_time_progeny||'</td>'||LF||
            '<td class="right">'||i.exec_count||'</td>'||LF||
            '<td>'||get_uid_name(i.uid#)||'</td>'||LF||
            '<td>'||i.dep||'</td>'||LF||
            '<td nowrap class="op" title="'||trca$g.wrap_text(i.sql_text_1000, 55, 'N', 'Y')||'">'||l_sql_text||'</td>'||LF||
            '<td class="right">'||l_hv||'</td>'||LF||
            l_columns||
            '</tr>'||LF);
          END LOOP;

          printf('</table>'||LF||
          '<font class="tablenote">'||LF||
          '(1) Percent of "Total CPU Time", which is '||rtf_rec.cpu||' secs.<br>'||LF||
          '(2) "Self CPU Time" in secs (caused by this SQL statement).<br>'||LF||
          '(3) "Recursive CPU Time" in secs (caused by recursive SQL invoked by this statement).<br>'||LF||
          '</font>'||LF||BACK_TOP||LF);
        END IF;
      END; -- CPU Time

      printf(end_show_and_hide||LF);
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
      l_hv VARCHAR2(32767);
      l_contribution VARCHAR2(32767);
      l_sql_text VARCHAR2(32767);
      l_text VARCHAR2(32767);
      l_columns VARCHAR2(32767);

    BEGIN
      printf(LF||'<a name="nsql"></a>'||LF||
      '<h2>Non-Recursive SQL (depth = 0)</h2>'||LF||
      begin_show('SHNSQL')||LF);

      IF trca$g.g_include_internal_sql = 'N' AND trca$g.g_include_non_top_sql = 'N' THEN
        l_text := ' Further details for internal and non-top SQL are excluded as per corresponding tool configuration parameters.';
      ELSIF trca$g.g_include_internal_sql = 'N' THEN
        l_text := ' Further details for internal SQL are excluded as per corresponding tool configuration parameter.';
      ELSIF trca$g.g_include_non_top_sql = 'N' THEN
        l_text := ' Further details for non-top SQL are excluded as per corresponding tool configuration parameter.';
      ELSE
        l_text := NULL;
      END IF;

      printf('<br>List of individual executions of non-recursive SQL in chronological order by first db call timestamp.'||l_text||'<br><br>');

      l_columns := NULL;
      IF trca$g.g_sqlid = 'Y' THEN
        l_columns := l_columns||'<th>SQL ID</th>'||LF;
      END IF;
      IF trca$g.g_plh = 'Y' THEN
        l_columns := l_columns||'<th>Plan<br>Hash<br>Value</th>'||LF;
      END IF;

      printf(
      '<table>'||LF||
      '<tr>'||LF||
      '<th>#</th>'||LF||
      '<th>Total<br>Response<br>Time<sup>1</sup></th>'||LF||
      '<th>Trace<br>RT<br>Pct<sup>2</sup></th>'||LF||
      '<th>Self<br>Response<br>Time<sup>3</sup></th>'||LF||
      '<th>Recursive<br>Response<br>Time<sup>4</sup></th>'||LF||
      '<th>User</th>'||LF||
      '<th>SQL Text</th>'||LF||
      '<th>Start Timestamp</th>'||LF||
      '<th>End Timestamp</th>'||LF||
      '<th>Hash Value</th>'||LF||
      l_columns||
      '</tr>'||LF);

      FOR i IN (SELECT *
                  FROM trca$_non_recursive_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       start_tim)
      LOOP
        l_row := l_row + 1;

        IF i.include_details = 'Y' OR trca$g.g_include_non_top_sql = 'Y'THEN
          l_hv := '<a href="#sql'||i.group_id||'">'||i.hv||'</a>';
        ELSE
          l_hv := i.hv;
        END IF;
        l_columns := NULL;
        IF trca$g.g_sqlid = 'Y' THEN
          l_columns := l_columns||'<td class="left">'||i.sqlid||'</td>'||LF;
        END IF;
        IF trca$g.g_plh = 'Y' THEN
          l_columns := l_columns||'<td class="right">'||i.plh||'</td>'||LF;
        END IF;
        l_contribution := i.contribution;
        l_sql_text := trca$g.prepare_html_text(SUBSTR(i.sql_text, 1, 55));
        IF i.top_sql = 'Y' OR i.top_sql_et = 'Y' OR i.top_sql_ct = 'Y' THEN
          l_contribution := '<font color="#FF0000">'||l_contribution||'</font>';
          l_sql_text := '<font color="#FF0000">'||l_sql_text||'</font>';
        END IF;

        printf('<tr>'||LF||
        '<td class="title">'||l_row||':</td>'||LF||
        '<td class="right">'||i.response_time_total||'</td>'||LF||
        '<td class="right">'||l_contribution||'</td>'||LF||
        '<td class="right">'||i.response_time_self||'</td>'||LF||
        '<td class="right">'||i.response_time_progeny||'</td>'||LF||
        '<td>'||get_uid_name(i.uid#)||'</td>'||LF||
        '<td nowrap class="op">'||l_sql_text||'</td>'||LF||
        '<td class="left">'||i.start_timestamp||'</td>'||LF||
        '<td class="left">'||i.end_timestamp||'</td>'||LF||
        '<td class="right">'||l_hv||'</td>'||LF||
        l_columns||
        '</tr>'||LF);
      END LOOP;

      printf('</table>'||LF||
      '<font class="tablenote">'||LF||
      '(1) "Total Response Time" in secs, as per start and end timestamps of db calls. It includes "Unaccounted-for" times.<br>'||LF||
      '(1) This list is constrained by threshold configuration parameter with current value of '||trca$g.g_response_time_th||'s.<br>'||LF||
      '(2) Percent of "Total Response Time Accounted-for", which is '||rtf_rec.accounted_for_response_time||' secs.<br>'||LF||
      '(3) "Self Response Time Accounted-for" in secs (caused by this non-recursive SQL statement).<br>'||LF||
      '(4) "Recursive Response Time Accounted-for" in secs (caused by recursive SQL invoked by this statement).<br>'||LF||
      '</font>'||LF||BACK_TOP||LF);

      printf(end_show_and_hide||LF);
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
      l_hv VARCHAR2(32767);
      l_contribution VARCHAR2(32767);
      l_sql_text VARCHAR2(32767);
      l_text VARCHAR2(32767);
      l_columns VARCHAR2(32767);

    BEGIN
      printf(LF||'<a name="sqlg"></a>'||LF||
      '<h2>SQL Genealogy</h2>'||LF||
      begin_show('SHSQLG')||LF);

      IF trca$g.g_include_internal_sql = 'N' AND trca$g.g_include_non_top_sql = 'N' THEN
        l_text := ' Further details for internal and non-top SQL are excluded as per corresponding tool configuration parameters.';
      ELSIF trca$g.g_include_internal_sql = 'N' THEN
        l_text := ' Further details for internal SQL are excluded as per corresponding tool configuration parameter.';
      ELSIF trca$g.g_include_non_top_sql = 'N' THEN
        l_text := ' Further details for non-top SQL are excluded as per corresponding tool configuration parameter.';
      ELSE
        l_text := NULL;
      END IF;

      printf('<br>Aggregate view of non-recursive SQL statements (depth = 0) and their recursive SQL at all depths.'||l_text||'<br><br>');

      l_columns := NULL;
      IF trca$g.g_sqlid = 'Y' THEN
        l_columns := l_columns||'<th>SQL ID</th>'||LF;
      END IF;
      IF trca$g.g_plh = 'Y' THEN
        l_columns := l_columns||'<th>Plan<br>Hash<br>Value</th>'||LF;
      END IF;

      printf(
      '<table>'||LF||
      '<tr>'||LF||
      '<th>#</th>'||LF||
      '<th>Trace<br>RT<br>Pct<sup>1</sup></th>'||LF||
      '<th>Self<br>Response<br>Time<sup>2</sup></th>'||LF||
      '<th>Recursive<br>Response<br>Time<sup>3</sup></th>'||LF||
      '<th>Exec<br>Count</th>'||LF||
      '<th>User</th>'||LF||
      '<th>Depth</th>'||LF||
      '<th>SQL Text</th>'||LF||
      '<th>Hash Value</th>'||LF||
      l_columns||
      '</tr>'||LF);

      FOR i IN (SELECT *
                  FROM trca$_sql_genealogy_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       id)

      LOOP
        l_row := l_row + 1;
        IF i.include_details = 'Y' OR trca$g.g_include_non_top_sql = 'Y' THEN
          l_hv := '<a href="#sql'||i.group_id||'">'||i.hv||'</a>';
        ELSE
          l_hv := i.hv;
        END IF;
        l_columns := NULL;
        IF trca$g.g_sqlid = 'Y' THEN
          l_columns := l_columns||'<td class="left">'||i.sqlid||'</td>'||LF;
        END IF;
        IF trca$g.g_plh = 'Y' THEN
          l_columns := l_columns||'<td class="right">'||i.plh||'</td>'||LF;
        END IF;
        l_contribution := i.contribution;
        l_sql_text := trca$g.prepare_html_text(SUBSTR(i.sql_text_prefix||i.sql_text, 1, 80));
        IF i.top_sql = 'Y' OR i.top_sql_et = 'Y' OR i.top_sql_ct = 'Y' THEN
          l_contribution := '<font color="#FF0000">'||l_contribution||'</font>';
          l_sql_text := '<font color="#FF0000">'||l_sql_text||'</font>';
        END IF;

        printf('<tr>'||LF||
        '<td class="title">'||l_row||':</td>'||LF||
        '<td class="right">'||l_contribution||'</td>'||LF||
        '<td class="right">'||i.response_time_self||'</td>'||LF||
        '<td class="right">'||i.response_time_progeny||'</td>'||LF||
        '<td class="right">'||i.exec_count||'</td>'||LF||
        '<td>'||get_uid_name(i.uid#)||'</td>'||LF||
        '<td>'||i.dep||'</td>'||LF||
        '<td nowrap class="op">'||l_sql_text||'</td>'||LF||
        '<td class="right">'||l_hv||'</td>'||LF||
        l_columns||
        '</tr>'||LF);
      END LOOP;

      printf('</table>'||LF||
      '<font class="tablenote">'||LF||
      '(1) Percent of "Total Response Time Accounted-for", which is '||rtf_rec.accounted_for_response_time||' secs.<br>'||LF||
      '(2) "Self Response Time Accounted-for" in secs (caused by this SQL statement).<br>'||LF||
      '(3) "Recursive Response Time Accounted-for" in secs (caused by recursive SQL invoked by this statement).<br>'||LF||
      '</font>'||LF||BACK_TOP||LF);

      printf(end_show_and_hide||LF);
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
      l_hv VARCHAR2(32767);
      l_row INTEGER := 0;
      l_contribution VARCHAR2(32767);
      l_sql_text VARCHAR2(32767);
      l_text VARCHAR2(32767);
      l_columns VARCHAR2(32767);

    BEGIN
      printf(LF||'<a name="isql"></a>'||LF||
      '<h2>Individual SQL</h2>'||LF||
      begin_show('SHISQL')||LF);

      IF trca$g.g_include_internal_sql = 'N' AND trca$g.g_include_non_top_sql = 'N' THEN
        l_text := ' Further details for internal and non-top SQL are excluded as per corresponding tool configuration parameters.';
      ELSIF trca$g.g_include_internal_sql = 'N' THEN
        l_text := ' Further details for internal SQL are excluded as per corresponding tool configuration parameter.';
      ELSIF trca$g.g_include_non_top_sql = 'N' THEN
        l_text := ' Further details for non-top SQL are excluded as per corresponding tool configuration parameter.';
      ELSE
        l_text := NULL;
      END IF;

      printf('<br>List of individual SQL in order of first appearance in trace.'||l_text||'<br><br>');

      l_columns := NULL;
      IF trca$g.g_sqlid = 'Y' THEN
        l_columns := l_columns||'<th>SQL ID</th>'||LF;
      END IF;
      IF trca$g.g_plh = 'Y' THEN
        l_columns := l_columns||'<th>Plan<br>Hash<br>Value</th>'||LF;
      END IF;

      printf(
      '<table>'||LF||
      '<tr>'||LF||
      '<th>#</th>'||LF||
      '<th>Rank</th>'||LF||
      '<th>Trace<br>RT<br>Pct<sup>1</sup></th>'||LF||
      '<th>Self<br>Response<br>Time<sup>2</sup></th>'||LF||
      '<th>Elapsed<br>Time</th>'||LF||
      '<th>CPU Time</th>'||LF||
      '<th>Non-Idle<br>Wait Time</th>'||LF||
      '<th>Idle<br>Wait Time</th>'||LF||
      '<th>Exec<br>Count</th>'||LF||
      '<th>User</th>'||LF||
      '<th>Depth</th>'||LF||
      '<th>SQL Text</th>'||LF||
      '<th>Hash Value</th>'||LF||
      l_columns||
      '<th>First Call</th>'||LF||
      '</tr>'||LF);

      FOR i IN (SELECT *
                  FROM trca$_sql_vf
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       first_cursor_id)
      LOOP
        l_row := l_row + 1;
        IF i.include_details = 'Y' OR trca$g.g_include_non_top_sql = 'Y' THEN
          l_hv := '<a href="#sql'||i.group_id||'">'||i.hv||'</a>';
        ELSE
          l_hv := i.hv;
        END IF;
        l_columns := NULL;
        IF trca$g.g_sqlid = 'Y' THEN
          l_columns := l_columns||'<td class="left">'||i.sqlid||'</td>'||LF;
        END IF;
        IF trca$g.g_plh = 'Y' THEN
          l_columns := l_columns||'<td class="right">'||i.plh||'</td>'||LF;
        END IF;
        l_contribution := i.contribution;
        l_sql_text := trca$g.prepare_html_text(SUBSTR(i.sql_text, 1, 60));
        IF i.top_sql = 'Y' OR i.top_sql_et = 'Y' OR i.top_sql_ct = 'Y' THEN
          l_contribution := '<font color="#FF0000">'||l_contribution||'</font>';
          l_sql_text := '<font color="#FF0000">'||l_sql_text||'</font>';
        END IF;

        printf('<tr>'||LF||
        '<td class="title">'||l_row||':</td>'||LF||
        '<td>'||i.rank||'</td>'||LF||
        '<td class="right">'||l_contribution||'</td>'||LF||
        '<td class="right">'||i.response_time_self||'</td>'||LF||
        '<td class="right">'||i.elapsed_time_self||'</td>'||LF||
        '<td class="right">'||i.cpu_time_self||'</td>'||LF||
        '<td class="right">'||i.non_idle_wait||'</td>'||LF||
        '<td class="right">'||i.idle_wait||'</td>'||LF||
        '<td class="right">'||i.exec_count||'</td>'||LF||
        '<td>'||get_uid_name(i.uid#)||'</td>'||LF||
        '<td>'||i.dep||'</td>'||LF||
        '<td nowrap class="op">'||l_sql_text||'</td>'||LF||
        '<td class="right">'||l_hv||'</td>'||LF||
        l_columns||
        '<td class="left">'||i.first_cursor_timestamp||'</td>'||LF||
        '</tr>'||LF);
      END LOOP;

      printf('</table>'||LF||
      '<font class="tablenote">'||LF||
      '(1) Percent of "Total Response Time Accounted-for", which is '||rtf_rec.accounted_for_response_time||' secs.<br>'||LF||
      '(2) "Self Response Time Accounted-for" in secs (caused by this SQL statement).<br>'||LF||
      '</font>'||LF||BACK_TOP||LF);

      printf(LF||'<hr size="1">'||LF);
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

      printf(end_show_and_hide||LF);
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

    BEGIN
      printf(LF||'<a name="iows"></a>'||LF||
      '<h2>Overall Segment I/O Wait Summary</h2>'||LF||
      begin_show('SHIOWS')||LF);

      SELECT COUNT(*)
        INTO l_count
        FROM trca$_tool_wait_segment
       WHERE tool_execution_id = p_tool_execution_id
         AND ROWNUM            = 1;

      IF trca$g.g_include_waits = 'N' OR
         trca$g.g_include_segments = 'N' THEN
        printf('<br>This section is disabled as per corresponding tool configuartion parameter(s).<br><br>');
      ELSIF l_count > 0 THEN
        printf('<br>Aggregate view of I/O wait events per segment, ordered by wait time.<br>');

        printf(
        '<br><table>'||LF||
        '<tr>'||LF||
        '<th>#</th>'||LF||
        '<th>Obj</th>'||LF||
        '<th>Type</th>'||LF||
        '<th>Segment Name<sup>1</sup></th>'||LF||
        '<th>Event Name</th>'||LF||
        '<th>Wait<br>Time<sup>2</sup></th>'||LF||
        '<th>Times<br>Waited</th>'||LF||
        '<th>Average<br>Wait Time</th>'||LF||
        '<th>Max<br>Wait Time</th>'||LF||
        '<th>Blocks</th>'||LF||
        '<th>Average<br>Blocks</th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_trc_wait_segment_vf
                   WHERE tool_execution_id = p_tool_execution_id
                   ORDER BY
                         wait DESC,
                         times_waited DESC,
                         blocks DESC)
        LOOP
          l_row := l_row + 1;

          printf('<tr>'||LF||
          '<td class="title">'||l_row||':</td>'||LF||
          '<td class="right">'||i.obj#||'</td>'||LF||
          '<td class="left">'||i.segment_type||'</td>'||LF||
          '<td class="left">'||i.segment_name||'</td>'||LF||
          '<td class="left">'||i.event_name||'</td>'||LF||
          '<td class="right">'||i.wait_time||'</td>'||LF||
          '<td class="right">'||i.times_waited||'</td>'||LF||
          '<td class="right">'||i.avg_wait_time||'</td>'||LF||
          '<td class="right">'||i.max_wait_time||'</td>'||LF||
          '<td class="right">'||i.blocks||'</td>'||LF||
          '<td class="right">'||i.avg_blocks||'</td>'||LF||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF||
        '<font class="tablenote">'||LF||
        '(1) Content based on '||trca$g.g_tool_name||' data dictionary (dbid:'||trca$g.g_dict_database_id||', host:'||trca$g.g_dict_host_name||').<br>'||LF||
        '(2) This list is constrained by threshold configuration parameter with current value of '||trca$g.g_wait_time_th||'s.<br>'||LF||
        '</font>'||LF||BACK_TOP||LF);
      ELSE
        printf('<br>There are no I/O wait events in trace file analyzed.<br><br>');
      END IF;

      printf(end_show_and_hide||LF);
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

    BEGIN
      printf(LF||'<a name="hiob"></a>'||LF||
      '<h2>Hot I/O Blocks</h2>'||LF||
      begin_show('SHHIOB')||LF);

      SELECT COUNT(*)
        INTO l_count
        FROM trca$_hot_block_segment
       WHERE tool_execution_id = p_tool_execution_id
         AND ROWNUM            = 1;

      IF trca$g.g_include_waits = 'N' OR TO_NUMBER(trca$g.g_hot_block_th) = 0 THEN
        printf('<br>This section is disabled as per corresponding tool configuartion parameter(s).<br><br>');
      ELSIF l_count > 0 THEN
        printf('<br>List of blocks with largest wait time or times waited.<br>');

        printf(
        '<br><table>'||LF||
        '<tr>'||LF||
        '<th>#</th>'||LF||
        '<th>File</th>'||LF||
        '<th>Block</th>'||LF||
        '<th>Obj</th>'||LF||
        '<th>Type</th>'||LF||
        '<th>Segment Name<sup>1</sup></th>'||LF||
        '<th>Wait<br>Time</th>'||LF||
        '<th>Times<br>Waited</th>'||LF||
        '<th>Max<br>Wait Time</th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_hot_block_segment_vf
                   WHERE tool_execution_id = p_tool_execution_id
                   ORDER BY
                         wait DESC,
                         times_waited DESC)
        LOOP
          l_row := l_row + 1;

          printf('<tr>'||LF||
          '<td class="title">'||l_row||':</td>'||LF||
          '<td class="right">'||i.file#||'</td>'||LF||
          '<td class="right">'||i.block||'</td>'||LF||
          '<td class="right">'||i.obj#||'</td>'||LF||
          '<td class="left">'||i.segment_type||'</td>'||LF||
          '<td class="left">'||i.segment_name||'</td>'||LF||
          '<td class="right">'||i.wait_time||'</td>'||LF||
          '<td class="right">'||i.times_waited||'</td>'||LF||
          '<td class="right">'||i.max_wait_time||'</td>'||LF||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF||
        '<font class="tablenote">'||LF||
        '(1) Content based on '||trca$g.g_tool_name||' data dictionary (dbid:'||trca$g.g_dict_database_id||', host:'||trca$g.g_dict_host_name||').<br>'||LF||
        '</font>'||LF||BACK_TOP||LF);
      ELSE
        printf('<br>There are no I/O wait events in trace file analyzed.<br><br>');
      END IF;

      printf(end_show_and_hide||LF);
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
      l_columns1 VARCHAR2(32767) := NULL;

    BEGIN
      printf(LF||'<a name="gapt"></a>'||LF||
      '<h2>Gaps in Trace</h2>'||LF||
      begin_show('SHGAPT')||LF);

      SELECT COUNT(*)
        INTO l_count
        FROM trca$_gap_vf
       WHERE tool_execution_id = p_tool_execution_id;

      IF TO_NUMBER(trca$g.g_gaps_th) = 0 THEN
        printf('<br>This section is disabled as per corresponding tool configuartion parameter.<br><br>');
      ELSIF l_count > 0 THEN
        IF l_count > TO_NUMBER(trca$g.g_gaps_th) THEN
           printf('<br>List of up to '||trca$g.g_gaps_th||' gaps found in trace(s) with corresponding approximate duration in seconds (ordered by gap time).<br>');
        ELSE
           printf('<br>List of gaps found in trace(s) with corresponding approximate duration in seconds (ordered by gap time).<br>');
        END IF;

        IF tool_rec.file_count > 1 THEN
          l_columns1 := '<th>Filename</th>'||LF;
        END IF;

        printf(
        '<br><table>'||LF||
        '<tr>'||LF||
        '<th>#</th>'||LF||
        '<th>Gap Timestamp</th>'||LF||
        '<th>Gap<br>Time<sup>1</sup></th>'||LF||
        l_columns1||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_gap_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND ROWNUM <= TO_NUMBER(trca$g.g_gaps_th)
                   ORDER BY
                         trace_id,
                         gap_duration DESC)
        LOOP
          l_row := l_row + 1;

          IF tool_rec.file_count > 1 THEN
            l_columns1 := '<td class="left">'||i.file_name||'</td>'||LF;
          END IF;

          printf('<tr>'||LF||
          '<td class="title">'||l_row||':</td>'||LF||
          '<td class="left">'||i.gap_timestamp||'</td>'||LF||
          '<td class="right">'||i.gap_duration||'</td>'||LF||
          l_columns1||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF||
        '<font class="tablenote">'||LF||
        '(1) Blank if duration cannot be computed.<br>'||LF||
        '</font>'||LF);
      ELSE
        printf('<br>There are no gaps in trace file(s) analyzed.<br><br>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display gaps in trace1: '||SQLERRM);
    END;

    DECLARE
      l_count INTEGER;
      l_row INTEGER := 0;
      l_hv VARCHAR2(32767);
      l_sql_text VARCHAR2(32767);
      l_columns2 VARCHAR2(32767);

    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM trca$_gap_call_vf
       WHERE tool_execution_id = p_tool_execution_id;

      IF TO_NUMBER(trca$g.g_gaps_th) = 0 THEN
        printf('<br>This section is disabled as per corresponding tool configuartion parameter.<br><br>');
      ELSIF l_count > 0 THEN
        IF l_count > TO_NUMBER(trca$g.g_gaps_th) THEN
           printf('<br>List of up to '||trca$g.g_gaps_th||' recursive calls related to gaps found in trace.<br>');
        ELSE
           printf('<br>List of recursive calls related to gaps found in trace.<br>');
        END IF;

        l_columns2 := NULL;
        IF trca$g.g_sqlid = 'Y' THEN
          l_columns2 := l_columns2||'<th>SQL ID</th>'||LF;
        END IF;

        printf(
        '<br><table>'||LF||
        '<tr>'||LF||
        '<th>#</th>'||LF||
        '<th>Gap Timestamp</th>'||LF||
        '<th>Call<br>Depth</th>'||LF||
        '<th>Call<br>Type</th>'||LF||
        '<th>CPU</th>'||LF||
        '<th>Elapsed</th>'||LF||
        '<th>Call Timestamp</th>'||LF||
        '<th>SQL Text</th>'||LF||
        '<th>Hash Value</th>'||LF||
        l_columns2||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_gap_call_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND ROWNUM <= TO_NUMBER(trca$g.g_gaps_th)
                   ORDER BY
                         gap_id,
                         dep DESC)
        LOOP
          l_row := l_row + 1;
          IF i.include_details = 'Y' OR trca$g.g_include_non_top_sql = 'Y' THEN
            l_hv := '<a href="#sql'||i.group_id||'">'||i.hv||'</a>';
          ELSE
            l_hv := i.hv;
          END IF;
          l_columns2 := NULL;
          IF trca$g.g_sqlid = 'Y' THEN
            l_columns2 := l_columns2||'<td class="left">'||i.sqlid||'</td>'||LF;
          END IF;
          l_sql_text := trca$g.prepare_html_text(SUBSTR(i.sql_text, 1, 60));
          IF i.top_sql = 'Y' OR i.top_sql_et = 'Y' OR i.top_sql_ct = 'Y' THEN
            l_sql_text := '<font color="#FF0000">'||l_sql_text||'</font>';
          END IF;

          printf('<tr>'||LF||
          '<td class="title">'||l_row||':</td>'||LF||
          '<td class="left">'||i.gap_timestamp||'</td>'||LF||
          '<td class="right">'||i.dep||'</td>'||LF||
          '<td class="left">'||i.call_type||'</td>'||LF||
          '<td class="right">'||i.cpu||'</td>'||LF||
          '<td class="right">'||i.elapsed||'</td>'||LF||
          '<td class="left">'||i.call_timestamp||'</td>'||LF||
          '<td nowrap class="op">'||l_sql_text||'</td>'||LF||
          '<td class="right">'||l_hv||'</td>'||LF||
          l_columns2||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF||BACK_TOP||LF);
      ELSE
        printf('<br>There are no recursive calls related to gaps in trace.<br><br>');
      END IF;

      printf(end_show_and_hide||LF);
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
      l_row INTEGER;
      l_hv VARCHAR2(32767);
      l_sql_text VARCHAR2(32767);
      l_columns2 VARCHAR2(32767);

    BEGIN
      printf(LF||'<a name="eror"></a>'||LF||
      '<h2>ORA errors in Trace</h2>'||LF||
      begin_show('SHEROR')||LF);

      SELECT COUNT(*)
        INTO l_count
        FROM trca$_error_vf
       WHERE tool_execution_id = p_tool_execution_id;

      IF TO_NUMBER(trca$g.g_errors_th) = 0 THEN
        printf('<br>This section is disabled as per corresponding tool configuartion parameter.<br><br>');
      ELSIF l_count > 0 THEN
        IF l_count > TO_NUMBER(trca$g.g_errors_th) THEN
           printf('<br>List of up to '||trca$g.g_errors_th||' Oracle errors found in trace(s).<br>');
        ELSE
           printf('<br>List of Oracle errors found in trace(s).<br>');
        END IF;

        l_columns2 := NULL;
        IF trca$g.g_sqlid = 'Y' THEN
          l_columns2 := l_columns2||'<th>SQL ID</th>'||LF;
        END IF;

        printf(
        '<br><table>'||LF||
        '<tr>'||LF||
        '<th>#</th>'||LF||
        '<th>Error</th>'||LF||
        '<th>Error Timestamp</th>'||LF||
        '<th>SQL Text</th>'||LF||
        '<th>Hash Value</th>'||LF||
        l_columns2||
        '</tr>'||LF);

        l_row := 0;
        FOR i IN (SELECT *
                    FROM trca$_error_vf
                   WHERE tool_execution_id = p_tool_execution_id
                     AND ROWNUM <= TO_NUMBER(trca$g.g_errors_th)
                   ORDER BY
                         tim)
        LOOP
          l_row := l_row + 1;
          IF i.include_details = 'Y' OR trca$g.g_include_non_top_sql = 'Y' THEN
            l_hv := '<a href="#sql'||i.group_id||'">'||i.hv||'</a>';
          ELSE
            l_hv := i.hv;
          END IF;
          l_columns2 := NULL;
          IF trca$g.g_sqlid = 'Y' THEN
            l_columns2 := l_columns2||'<td class="left">'||i.sqlid||'</td>'||LF;
          END IF;
          l_sql_text := trca$g.prepare_html_text(SUBSTR(i.sql_text, 1, 60));
          IF i.top_sql = 'Y' OR i.top_sql_et = 'Y' OR i.top_sql_ct = 'Y' THEN
            l_sql_text := '<font color="#FF0000">'||l_sql_text||'</font>';
          END IF;

          printf('<tr>'||LF||
          '<td class="title">'||l_row||':</td>'||LF||
          '<td class="left">'||i.ora_error||'</td>'||LF||
          '<td class="left">'||i.error_timestamp||'</td>'||LF||
          '<td nowrap class="op">'||l_sql_text||'</td>'||LF||
          '<td class="right">'||l_hv||'</td>'||LF||
          l_columns2||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF||BACK_TOP||LF);
      ELSE
        printf('<br>There are no Oracle errors in trace.<br><br>');
      END IF;

      printf(end_show_and_hide||LF);
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
      l_columns1 VARCHAR2(32767) := NULL;

    BEGIN
      printf(LF||'<a name="tran"></a>'||LF||
      '<h2>Transactions Summary</h2>'||LF||
      begin_show('SHTRAN')||LF);

      SELECT COUNT(*)
        INTO l_count
        FROM trca$_session
       WHERE tool_execution_id = p_tool_execution_id
         AND ROWNUM = 1;

      IF l_count = 0 THEN
        printf('<br>There are no session information recorder in trace(s). Thus this section is not available.<br><br>');
      ELSE
        printf('<br>List of sessions recognized in trace(s), including transaction counts per type.<br>');

        IF tool_rec.file_count > 1 THEN
          l_columns1 := '<th>Filename</th>'||LF;
        END IF;

        printf(
        '<br><table>'||LF||
        '<tr>'||LF||
        '<th>#</th>'||LF||
        '<th>SID</th>'||LF||
        '<th>Serial#</th>'||LF||
        '<th>Session Timestamp</th>'||LF||
        '<th>Type<br>Read-only<br>Committed</th>'||LF||
        '<th>Type<br>Read-only<br>Rolled-back</th>'||LF||
        '<th>Type<br>Update<br>Committed</th>'||LF||
        '<th>Type<br>Update<br>Rolled-back</th>'||LF||
        l_columns1||
        '</tr>'||LF);

        FOR i IN (SELECT *
                    FROM trca$_session_vf
                   WHERE tool_execution_id = p_tool_execution_id
                   ORDER BY
                         trace_id,
                         session_id)
        LOOP
          l_row := l_row + 1;

          IF tool_rec.file_count > 1 THEN
            l_columns1 := '<td class="left">'||i.file_name||'</td>'||LF;
          END IF;

          printf('<tr>'||LF||
          '<td class="title">'||l_row||':</td>'||LF||
          '<td>'||i.sid||'</td>'||LF||
          '<td>'||i.serial#||'</td>'||LF||
          '<td class="left">'||i.session_timestamp||'</td>'||LF||
          '<td class="right">'||i.read_only_committed||'</td>'||LF||
          '<td class="right">'||i.read_only_rollbacked||'</td>'||LF||
          '<td class="right">'||i.update_committed||'</td>'||LF||
          '<td class="right">'||i.update_rollbacked||'</td>'||LF||
          l_columns1||
          '</tr>'||LF);
        END LOOP;

        printf('</table>');
      END IF;

      printf(end_show_and_hide||LF);
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

    BEGIN
      printf(LF||'<a name="init"></a>'||LF||
      '<h2>Non-default Initialization Params</h2>'||LF||
      begin_show('SHINIT')||LF);

      IF trca$g.g_include_init_ora = 'N' THEN
        printf('<br>This section is disabled as per corresponding tool configuartion parameter.<br><br>');
      ELSE
        printf('<br>List of non-default parameters.<br>');

        printf(
        '<br><table>'||LF||
        '<tr>'||LF||
        '<th>#</th>'||LF||
        '<th>Parameter</th>'||LF||
        '<th>Value<sup>1</sup></th>'||LF||
        '</tr>'||LF);

        FOR i IN (SELECT name, value
                    FROM trca$_parameter2$
                   ORDER BY
                         name,
                         value)
        LOOP
          l_row := l_row + 1;

          printf('<tr>'||LF||
          '<td class="title">'||l_row||':</td>'||LF||
          '<td class="left">'||i.name||'</td>'||LF||
          '<td class="left">'||i.value||'</td>'||LF||
          '</tr>'||LF);
        END LOOP;

        printf('</table>'||LF||
        '<font class="tablenote">'||LF||
        '(1) Content based on '||trca$g.g_tool_name||' data dictionary (dbid:'||trca$g.g_dict_database_id||', host:'||trca$g.g_dict_host_name||').<br>'||LF||
        '</font>'||LF);
      END IF;

      printf(end_show_and_hide||LF);
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
      printf(LF||'<a name="thea"></a>'||LF||
      '<h2>Trace Header</h2>'||LF||
      begin_show('SHTHEA')||LF);

      FOR i IN (SELECT *
                  FROM trca$_trace
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       id)
      LOOP
        printf('<h3>'||i.file_name||' ('||i.file_len||' bytes)</h3>'||LF);

        FOR j IN (SELECT *
                    FROM trca$_trace_header
                   WHERE trace_id = i.id
                     AND tool_execution_id = p_tool_execution_id
                     AND REPLACE(text, ' ') IS NOT NULL
                   ORDER BY
                         piece)
        LOOP
          printf(j.text||'<br>');
        END LOOP;
      END LOOP;

      printf('<br><br>'||LF||BACK_TOP||LF||end_show_and_hide||LF);
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

    BEGIN
      printf(LF||'<a name="tdic"></a>'||LF||
      '<h2>Tool Data Dictionary</h2>'||LF||
      begin_show('SHTDIC')||LF);

      printf(
      '<table>'||LF||
      title_and_value('Refresh Date:', trca$g.g_dict_refresh_date)||
      title_and_value('Refresh Days:', trca$g.g_dict_refresh_days)||
      title_and_value('Database:', trca$g.g_dict_database_name||'('||trca$g.g_dict_database_id||')')||
      title_and_value('Instance:', trca$g.g_dict_instance_name||'('||trca$g.g_dict_instance_id||')')||
      title_and_value('Host:', trca$g.g_dict_host_name)||
      title_and_value('Platform:', trca$g.g_dict_platform)||
      title_and_value('RDBMS Version:', trca$g.g_dict_rdbms_version)||
      title_and_value('DB Files:', trca$g.g_dict_db_files)||
      '</table>'||LF||BACK_TOP||LF||end_show_and_hide||LF);

    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display tool data dict: '||SQLERRM);
    END;
    print_log('<- '||l_phase);

    /***********************************************************************************/

    /* -------------------------
     * Tool Execution Environment
     * ------------------------- */
    l_phase := 'tool_environment';
    print_log('-> '||l_phase);

    BEGIN
      printf(LF||'<a name="tenv"></a>'||LF||
      '<h2>Tool Execution Environment</h2>'||LF||
      begin_show('SHTENV')||LF);

      printf(
      '<table>'||LF||
      --title_and_value('Execution ID:', p_tool_execution_id)||
      title_and_value('Database:', trca$g.g_tool_database_name||'('||trca$g.g_tool_database_id||')')||
      title_and_value('Instance:', trca$g.g_tool_instance_name||'('||trca$g.g_tool_instance_id||')')||
      title_and_value('Host:', trca$g.g_tool_host_name)||
      title_and_value('Platform:', trca$g.g_tool_platform)||
      title_and_value('RDBMS Version:', trca$g.g_tool_rdbms_version)||
      title_and_value('RDBMS Release:', trca$g.g_tool_rdbms_release||'('||trca$g.g_tool_rdbms_version_short||')')||
      title_and_value('DB Files:', trca$g.g_tool_db_files)||
      title_and_value('Product Version:', trca$g.g_tool_product_version)||
      title_and_value('User:', USER||'('||UID||')')||
      title_and_value('Input Directory:', l_directory_path)||
      title_and_value('Stage Directory:', trca$g.get_directory_path(trca$g.g_stage_dir))||
      '</table>'||LF||BACK_TOP||LF||end_show_and_hide||LF);

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

    BEGIN
      printf(LF||'<a name="conf"></a>'||LF||
      '<h2>Tool Configuration Parameters</h2>'||LF||
      begin_show('CTRL1')||LF);

      printf(LF||
      '<table>'||LF||
      '<tr>'||LF||
      '<th>Description<sup>1</sup></th>'||
      '<th>Name</th>'||
      '<th>Value<sup>2</sup></th>'||
      '<th>Default</th>'||
      '<th>Instructions</th>'||
      '</tr>'||LF);

      FOR i IN (SELECT *
                  FROM trca$_tool_parameter
                 WHERE hidden = 'N'
                 ORDER BY
                       id)
      LOOP
        printf(title_and_value (
          p_title  => i.description||':',
          p_value  => i.name,
          p_value2 => i.value,
          p_value3 => i.default_value,
          p_value4 => i.instructions,
          p_class  => 'left' ));
      END LOOP;

      printf(LF||
      '</table>'||LF||
      '<font class="tablenote">'||LF||
      '(1) For detailed parameter description, refer to trca/trca_instructions.txt<br>'||
      '(2) To set a parameter: SQL> EXEC '||LOWER(trca$g.g_tool_administer_schema)||'.trca$g.set_param(''Name'', ''Value'');<br>'||LF||
      '</font>'||LF||BACK_TOP||LF||end_show_and_hide||LF);
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
      printf(LF||'<hr size="1">'||LF||
      '<font class="footer">'||trca$g.g_tool_name||' '||trca$g.g_tool_version||' <!-- installed:'||trca$g.g_install_date||' --> secs:'||
      TO_CHAR(ROUND((SYSDATE - tool_rec.parse_start) * 24 * 3600, 3))||
      ' '||TO_CHAR(SYSDATE, LONG_DATE_FORMAT)||'</font>'||LF||
      '</body></html>');
    EXCEPTION
      WHEN OTHERS THEN
        print_log('*** cannot display footer: '||SQLERRM);
    END;

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    INSERT INTO trca$_file VALUES s_file_rec;
    COMMIT;
    x_html_report := s_file_rec.file_text;
    print_log('<= gen_html_report');

  EXCEPTION
    WHEN OTHERS THEN
      print_log(l_phase||' '||SQLERRM);
      RAISE;
  END gen_html_report;

  /*************************************************************************************/

END trca$r;
/

SET TERM ON;
SHOW ERRORS;
