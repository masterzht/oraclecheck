CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..sqlt$c AS
/* $Header: 215187.1 sqcpkgc.pkb 12.1.14 2015/12/06 carlos.sierra mauro.pagano abel.macias@oracle.com $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  TOOL_NAME              CONSTANT VARCHAR2(32)  := '&&tool_name.';
  NOTE_NUMBER            CONSTANT VARCHAR2(32)  := '&&tool_note.';
  TOOL_DEVELOPER         CONSTANT VARCHAR2(32)  := 'abel.macias';
  TOOL_DEVELOPER_EMAIL   CONSTANT VARCHAR2(32)  := 'abel.macias@oracle.com';
  COPYRIGHT              CONSTANT VARCHAR2(128) := 'Copyright (c) 2000-2015, Oracle Corporation. All rights reserved.';
  HEADING_DATE_FORMAT    CONSTANT VARCHAR2(32)  := 'YYYY/MM/DD';
  LOAD_DATE_FORMAT       CONSTANT VARCHAR2(32)  := 'YYYY-MM-DD/HH24:MI:SS'; -- 2010-03-03/08:45:04
  TIMESTAMP_FORMAT3      CONSTANT VARCHAR2(64)  := 'YYYY-MM-DD/HH24:MI:SS.FF3';
  TIMESTAMP_FORMAT6      CONSTANT VARCHAR2(64)  := 'YYYY-MM-DD/HH24:MI:SS.FF6';
  SCIENTIFIC_NOTATION    CONSTANT VARCHAR2(32)  := '0D000000EEEE';
  SELECTIVITY_FORMAT     CONSTANT VARCHAR2(32)  := '0D000000';
  NUMBER_FORMAT          CONSTANT VARCHAR2(32)  := '99999999999990D990';
  SECONDS_FORMAT         CONSTANT VARCHAR2(32)  := '999999999999990D990';
  PERCENT_FORMAT         CONSTANT VARCHAR2(32)  := '99999990D0';
  TITLE_REPEAT_RATE      CONSTANT INTEGER       := 20;
  LF                     CONSTANT CHAR(1)       := CHR(10);
  CR                     CONSTANT CHAR(1)       := CHR(13);
  AMP                    CONSTANT CHAR(1)       := CHR(38);
  NBSP                   CONSTANT VARCHAR2(32)  := AMP||'nbsp;'; -- space
  NBSP2                  CONSTANT VARCHAR2(32)  := NBSP||NBSP; -- 2 spaces

  /*************************************************************************************/

  /* -------------------------
   *
   * static variables
   *
   * ------------------------- */
  s_sql_rec1 sqlt$_sql_statement%ROWTYPE;
  s_sql_rec2 sqlt$_sql_statement%ROWTYPE;
  s_pln_rec1 sqlt$_plan_header_v%ROWTYPE;
  s_pln_rec2 sqlt$_plan_header_v%ROWTYPE;
  s_file_rec sqli$_file%ROWTYPE;
  s_snap_id INTEGER := 0;
  s_rows_table_l NUMBER;

  /*************************************************************************************/

  /* -------------------------
   *
   * private write_log
   *
   * ------------------------- */
  PROCEDURE write_log (
    p_line_text IN VARCHAR2,
    p_line_type IN VARCHAR2 DEFAULT 'L' )
  IS
  BEGIN
    sqlt$a.write_log(p_line_text => p_line_text, p_line_type => p_line_type, p_package => 'C');
  END write_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * private wa - write append
   *
   * ------------------------- */
  PROCEDURE wa (p_text IN VARCHAR2)
  IS
  BEGIN
    IF p_text IS NOT NULL THEN
      SYS.DBMS_LOB.WRITEAPPEND (
        lob_loc => s_file_rec.file_text,
        amount  => NVL(LENGTH(p_text), 0) + 1,
        buffer  => LF||p_text );
    END IF;
  END wa;

  /*************************************************************************************/

  /* -------------------------
   *
   * private write_error
   *
   * ------------------------- */
  PROCEDURE write_error (p_line_text IN VARCHAR2)
  IS
  BEGIN
    wa('<table></table>'); -- dummy table to dump content of table interrupted by error
    wa(p_line_text);
    sqlt$a.write_error('c:'||p_line_text);
  END write_error;

  /*************************************************************************************/

  /* -------------------------
   *
   * private append
   *
   * ------------------------- */
  PROCEDURE append (
    p_clob IN CLOB,
    p_pre  IN BOOLEAN DEFAULT FALSE )
  IS
  BEGIN
    IF p_clob IS NOT NULL THEN
      IF SYS.DBMS_LOB.GETLENGTH(p_clob) > 0 THEN
        IF p_pre THEN
          SYS.DBMS_LOB.WRITEAPPEND (
            lob_loc => s_file_rec.file_text,
            amount  => 5,
            buffer  => '<pre>' );
        END IF;

        SYS.DBMS_LOB.APPEND (
          dest_lob => s_file_rec.file_text,
          src_lob  => p_clob );

        IF p_pre THEN
          SYS.DBMS_LOB.WRITEAPPEND (
            lob_loc => s_file_rec.file_text,
            amount  => 6,
            buffer  => '</pre>' );
        END IF;
      END IF;
    END IF;
  END append;

  /*************************************************************************************/

  /* -------------------------
   *
   * private sanitize_and_append
   *
   * ------------------------- */
  PROCEDURE sanitize_and_append (
    p_clob          IN CLOB,
    p_td            IN BOOLEAN  DEFAULT TRUE,
    p_max_line_size IN INTEGER  DEFAULT 80 )
  IS
  BEGIN
    IF p_td THEN
      append('<td nowrap class="l">'||sqlt$r.wrap_and_sanitize_html_clob(p_clob, p_max_line_size)||'</td>');
    ELSE
      append(sqlt$r.wrap_and_sanitize_html_clob(p_clob, p_max_line_size, FALSE));
    END IF;
  END sanitize_and_append;

  /*************************************************************************************/

  /* -------------------------
   *
   * private font_sanitize_and_append
   *
   * ------------------------- */
  PROCEDURE font_sanitize_and_append (
    p_clob          IN CLOB,
    p_td            IN BOOLEAN  DEFAULT TRUE,
    p_max_line_size IN INTEGER  DEFAULT 200 )
  IS
  BEGIN
    IF p_td THEN
      append('<td nowrap class="l">'||sqlt$r.wrap_sanitize_font_html_clob(p_clob, p_max_line_size)||'</td>');
    ELSE
      append(sqlt$r.wrap_sanitize_font_html_clob(p_clob, p_max_line_size, FALSE));
    END IF;
  END font_sanitize_and_append;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tag
   *
   * ------------------------- */
  FUNCTION tag (
    p_value    IN VARCHAR2,
    p_tag_name IN VARCHAR2 DEFAULT 'class' )
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_value IS NULL THEN
      RETURN NULL;
    ELSE
      RETURN ' '||NVL(p_tag_name, 'class')||'="'||p_value||'"';
    END IF;
  END tag;

  /*************************************************************************************/

  /* -------------------------
   *
   * private font
   *
   * ------------------------- */
  FUNCTION font (
    p_text  IN VARCHAR2,
    p_class IN VARCHAR2 DEFAULT 'n' )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN '<font'||tag(NVL(p_class, 'n'))||'>'||p_text||'</font>';
  END font;

  /*************************************************************************************/

  /* -------------------------
   *
   * private td
   *
   * ------------------------- */
  FUNCTION td (
    p_text    IN VARCHAR2,
    p_class   IN VARCHAR2 DEFAULT 'c',
    p_keyword IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_keyword IS NULL THEN
      RETURN '<td'||tag(p_class)||'>'||p_text||'</td>';
    ELSE
      RETURN '<td'||' '||p_keyword||tag(p_class)||'>'||p_text||'</td>';
    END IF;
  END td;

  /*************************************************************************************/

  /* -------------------------
   *
   * private th
   *
   * ------------------------- */
  FUNCTION th (
    p_text  IN VARCHAR2 DEFAULT NULL,
    p_class IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN '<th'||tag(p_class)||'>'||p_text||'</th>';
  END th;

  /*************************************************************************************/

  /* -------------------------
   *
   * private a
   *
   * ------------------------- */
  FUNCTION a (
    p_text IN VARCHAR2,
    p_href IN VARCHAR2 DEFAULT NULL,
    p_name IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2
  IS
    l_a VARCHAR2(32767) := NULL;
  BEGIN
    IF p_name IS NOT NULL THEN
      l_a := l_a||' name="'||p_name||'"';
    END IF;
    IF p_href IS NOT NULL THEN
      l_a := l_a||' href="#'||p_href||'"';
    END IF;
    RETURN '<a'||l_a||'>'||p_text||'</a>';
  END a;

  /*************************************************************************************/

  /* -------------------------
   *
   * private h2
   *
   * ------------------------- */
  FUNCTION h2 (
    p_text  IN VARCHAR2,
    p_name  IN VARCHAR2 DEFAULT NULL,
    p_hr    IN BOOLEAN  DEFAULT TRUE )
  RETURN VARCHAR2
  IS
    l_hr VARCHAR2(32767) := NULL;
    l_a  VARCHAR2(32767) := NULL;
  BEGIN
    IF p_name IS NOT NULL THEN
      l_a := a(NULL, NULL, p_name);
    END IF;
    IF p_hr THEN
      l_hr := '<hr size="3">';
    END IF;
    RETURN LF||LF||l_hr||l_a||'<h2>'||p_text||'</h2>';
  END h2;

  /*************************************************************************************/

  /* -------------------------
   *
   * private h3
   *
   * ------------------------- */
  FUNCTION h3 (
    p_text  IN VARCHAR2,
    p_name  IN VARCHAR2 DEFAULT NULL,
    p_hr    IN BOOLEAN  DEFAULT TRUE )
  RETURN VARCHAR2
  IS
    l_hr VARCHAR2(32767) := NULL;
    l_a  VARCHAR2(32767) := NULL;
  BEGIN
    IF p_name IS NOT NULL THEN
      l_a := a(NULL, NULL, p_name);
    END IF;
    IF p_hr THEN
      l_hr := '<hr size="1">';
    END IF;
    RETURN LF||LF||l_hr||l_a||'<h3>'||p_text||'</h3>';
  END h3;

  /*************************************************************************************/

  /* -------------------------
   *
   * private h4
   *
   * ------------------------- */
  FUNCTION h4 (
    p_text  IN VARCHAR2,
    p_name  IN VARCHAR2 DEFAULT NULL,
    p_hr    IN BOOLEAN  DEFAULT FALSE )
  RETURN VARCHAR2
  IS
    l_hr VARCHAR2(32767) := NULL;
    l_a  VARCHAR2(32767) := NULL;
  BEGIN
    IF p_name IS NOT NULL THEN
      l_a := a(NULL, NULL, p_name);
    END IF;
    IF p_hr THEN
      l_hr := '<hr size="1">';
    END IF;
    RETURN LF||LF||l_hr||l_a||'<h4>'||p_text||'</h4>';
  END h4;

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
   * private show
   *
   * ------------------------- */
  FUNCTION show (p_text IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN show_n_hide(p_text||'</span>', '-', 'block');
  END show;

  /*************************************************************************************/

  /* -------------------------
   *
   * private hide
   *
   * ------------------------- */
  FUNCTION hide (p_text IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN show_n_hide(p_text||'</span>', '+', 'none');
  END hide;

  /*************************************************************************************/

  /* -------------------------
   *
   * private show_begin
   *
   * ------------------------- */
  FUNCTION show_begin
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN show_n_hide(NULL, '-', 'block');
  END show_begin;

  /*************************************************************************************/

  /* -------------------------
   *
   * private hide_begin
   *
   * ------------------------- */
  FUNCTION hide_begin
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN show_n_hide(NULL, '+', 'none');
  END hide_begin;

  /*************************************************************************************/

  /* -------------------------
   *
   * private show_hide_end
   *
   * ------------------------- */
  FUNCTION show_hide_end
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN '</span>';
  END show_hide_end;

  /*************************************************************************************/

  /* -------------------------
   *
   * private hide_sql
   *
   * ------------------------- */
  FUNCTION hide_sql (p_text IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN 'SQL:'||hide('<pre>'||sqlt$r.sanitize_html_clob(TRIM(LF FROM p_text), FALSE)||'</pre>');
  END hide_sql;

  /*************************************************************************************/

  /* -------------------------
   *
   * private wa_hide
   *
   * ------------------------- */
  PROCEDURE wa_hide (
    p_clob IN CLOB,
    p_pre  IN BOOLEAN DEFAULT FALSE )
  IS
  BEGIN
    wa(hide_begin);
    append(p_clob, p_pre);
    wa(show_hide_end);
  EXCEPTION
    WHEN OTHERS THEN
      wa(SQLERRM);
  END wa_hide;

  /*************************************************************************************/

  /* -------------------------
   *
   * private wa_td_hide
   *
   * ------------------------- */
  PROCEDURE wa_td_hide (p_clob IN CLOB)
  IS
  BEGIN
    wa('<td class="l">');
    wa_hide(p_clob);
    wa('</td>');
  END wa_td_hide;

  /*************************************************************************************/

  /* -------------------------
   *
   * private go_to_top
   *
   * ------------------------- */
  FUNCTION go_to_top
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN font(a('Go to Top', 'toc'), 'f');
  END go_to_top;

  /*************************************************************************************/

  /* -------------------------
   *
   * private go_to_sec
   *
   * ------------------------- */
  FUNCTION go_to_sec (
    p_text IN VARCHAR2,
    p_href IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN font(a('Go to '||p_text, p_href), 'f');
  END go_to_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private li
   *
   * ------------------------- */
  FUNCTION li (p_text IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN '<li>'||p_text||'</li>';
  END li;

  /*************************************************************************************/

  /* -------------------------
   *
   * private mot - mouse over text
   *
   * ------------------------- */
  FUNCTION mot (
    p_main_text  IN VARCHAR2,
    p_mo_text    IN VARCHAR2,
    p_href       IN VARCHAR2 DEFAULT 'javascript:void(0);',
    p_mo_caption IN VARCHAR2 DEFAULT NULL,
    p_sticky     IN BOOLEAN  DEFAULT FALSE,
    p_nl_class   IN VARCHAR2 DEFAULT 'nl',
    p_target     IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2
  IS
    l_return VARCHAR2(32767);
  BEGIN
    IF p_mo_text IS NULL THEN
      RETURN p_main_text;
    END IF;

    l_return := LF||'<a';

    IF p_target IS NOT NULL THEN
      l_return := l_return||' target="'||p_target||'"';
    END IF;

    IF NVL(p_href, 'javascript:void(0);') = 'javascript:void(0);' THEN
      l_return := l_return||' class="'||p_nl_class||'"';
    ELSE
      l_return := l_return||' class="l"';
    END IF;

    l_return := l_return||' href="'||NVL(p_href, 'javascript:void(0);')||'" onmouseover="return overlib('||
    LF||''''||sqlt$r.sanitize_js_text(p_mo_text)||''''||LF;

    IF p_mo_caption IS NOT NULL THEN
      l_return := l_return||', CAPTION, '''||sqlt$r.sanitize_js_text(p_mo_caption)||'''';
    END IF;

    IF p_sticky THEN
      l_return := l_return||', STICKY';
    END IF;

    IF p_sticky THEN
      IF p_mo_caption IS NULL THEN
        l_return := l_return||', MOUSEOFF';
      ELSE
        l_return := l_return||', NOCLOSE';
      END IF;
    END IF;

    l_return := l_return||');" onmouseout="return nd();">'||p_main_text||'</a>';
    RETURN l_return;
  END mot;

  /*************************************************************************************/

  /* -------------------------
   *
   * private moa - mouse over array
   *
   * ------------------------- */
  FUNCTION moa (
    p_main_text   IN VARCHAR2,
    p_moa_txt_idx IN INTEGER,
    p_moa_cap_idx IN INTEGER  DEFAULT NULL,
    p_href        IN VARCHAR2 DEFAULT 'javascript:void(0);',
    p_sticky      IN BOOLEAN  DEFAULT FALSE )
  RETURN VARCHAR2
  IS
    l_return VARCHAR2(32767);
  BEGIN
    l_return := LF||'<a';
    IF NVL(p_href, 'javascript:void(0);') = 'javascript:void(0);' THEN
      l_return := l_return||' class="nl"';
    END IF;
    l_return := l_return||' href="'||NVL(p_href, 'javascript:void(0);')||'" onmouseover="return overlib(INARRAY, '||p_moa_txt_idx;
    IF p_moa_cap_idx IS NOT NULL THEN
      l_return := l_return||', CAPARRAY, '||p_moa_cap_idx;
    END IF;
    IF p_sticky THEN
      l_return := l_return||', STICKY';
    END IF;
    IF p_sticky THEN
      IF p_moa_cap_idx IS NULL THEN
        l_return := l_return||', MOUSEOFF';
      ELSE
        l_return := l_return||', NOCLOSE';
      END IF;
    END IF;
    l_return := l_return||');" onmouseout="return nd();">'||p_main_text||'</a>';
    RETURN l_return;
  END moa;

  /*************************************************************************************/

  /* -------------------------
   *
   * private red
   *
   * ------------------------- */
  FUNCTION red (
    p_value       IN NUMBER,
    p_top_value   IN NUMBER,
    p_total_value IN NUMBER,
    p_mo_text     IN VARCHAR2 DEFAULT NULL,
    p_value_type  IN VARCHAR2 DEFAULT 'N') -- (N)umber, (T)ime
  RETURN VARCHAR2
  IS
  BEGIN
    IF NVL(p_top_value, 0) = 0 OR NVL(p_total_value, 0) = 0 THEN
      IF p_value_type = 'T' THEN
        RETURN TO_CHAR(ROUND(p_value / 1e6, 3), SECONDS_FORMAT);
      ELSE
        RETURN p_value;
      END IF;
    ELSE
      IF p_value_type = 'T' THEN
        RETURN mot(TO_CHAR(ROUND(p_value / 1e6, 3), SECONDS_FORMAT), 'self:'||TO_CHAR(ROUND(p_top_value / 1e6, 3), SECONDS_FORMAT)||'('||TRIM(TO_CHAR(ROUND(p_top_value * 100 / p_total_value, 1), PERCENT_FORMAT))||'%)<br>'||p_mo_text, p_nl_class => 'nlr');
      ELSE
        RETURN mot(p_value, 'self:'||p_top_value||'('||TRIM(TO_CHAR(ROUND(p_top_value * 100 / p_total_value, 1), PERCENT_FORMAT))||'%)<br>'||p_mo_text, p_nl_class => 'nlr');
      END IF;
    END IF;
  END red;

  /*************************************************************************************/

  /* -------------------------
   *
   * private wr - write row
   *
   * ------------------------- */
  PROCEDURE wr (
    p_text_1  IN VARCHAR2,
    p_text_2  IN VARCHAR2,
    p_class_2 IN VARCHAR2 DEFAULT 'l',
    p_text_3  IN VARCHAR2 DEFAULT NULL,
    p_class_3 IN VARCHAR2 DEFAULT 'r',
    p_text_4  IN VARCHAR2 DEFAULT NULL,
    p_class_4 IN VARCHAR2 DEFAULT 'r',
    p_text_5  IN VARCHAR2 DEFAULT NULL,
    p_class_5 IN VARCHAR2 DEFAULT 'r',
    p_class_1 IN VARCHAR2 DEFAULT 'rt' )
  IS
  BEGIN
    IF p_text_2 IS NULL AND p_text_3 IS NULL AND p_text_4 IS NULL AND p_text_5 IS NULL THEN
      RETURN;
    END IF;
    IF p_text_2 = NBSP AND p_text_3 = NBSP THEN
      RETURN;
    END IF;
    wa('<tr>');
    IF p_class_1 = 'rt' THEN
      wa(td(p_text_1||':', p_class_1));
    ELSE
      wa(td(p_text_1, p_class_1));
    END IF;
    IF p_text_2 IS NOT NULL THEN
      wa(td(p_text_2, p_class_2));
    END IF;
    IF p_text_3 IS NOT NULL THEN
      wa(td(p_text_3, p_class_3));
    END IF;
    IF p_text_4 IS NOT NULL THEN
      wa(td(p_text_4, p_class_4));
    END IF;
    IF p_text_5 IS NOT NULL THEN
      wa(td(p_text_5, p_class_5));
    END IF;
    wa('</tr>');
  END wr;

  /*************************************************************************************/

  /* -------------------------
   *
   * private wrn - write row numeric
   *
   * ------------------------- */
  PROCEDURE wrn (
    p_text     IN VARCHAR2,
    p_number_1 IN VARCHAR2,
    p_number_2 IN VARCHAR2,
    p_class    IN VARCHAR2 DEFAULT 'r',
    p_text_3   IN VARCHAR2 DEFAULT NULL,
    p_class_3  IN VARCHAR2 DEFAULT 'l' )
  IS
  BEGIN
    IF NVL(p_number_1, -666) = -666 AND NVL(p_number_2, -666) = -666 THEN
      RETURN;
    END IF;
    wr (
      p_text_1  => p_text,
      p_text_2  => NVL(sqlt$r.color_differences(p_number_1, p_number_2, p_number_1), NBSP),
      p_class_2 => p_class,
      p_text_3  => NVL(sqlt$r.color_differences(p_number_1, p_number_2, p_number_2), NBSP),
      p_class_3 => p_class,
      p_text_4  => p_text_3,
      p_class_4 => p_class_3,
      p_class_1 => 'lt' );
  END wrn;

  /*************************************************************************************/

  /* -------------------------
   *
   * private wrc - write row char
   *
   * ------------------------- */
  PROCEDURE wrc (
    p_text    IN VARCHAR2,
    p_text_1  IN VARCHAR2,
    p_text_2  IN VARCHAR2,
    p_class   IN VARCHAR2 DEFAULT 'l',
    p_text_3  IN VARCHAR2 DEFAULT NULL,
    p_class_3 IN VARCHAR2 DEFAULT 'l' )
  IS
  BEGIN
    IF NVL(p_text_1, NBSP) = NBSP AND NVL(p_text_2, NBSP) = NBSP THEN
      RETURN;
    END IF;
    wr (
      p_text_1  => p_text,
      p_text_2  => NVL(sqlt$r.color_differences_c(p_text_1, p_text_2, p_text_1), NBSP),
      p_class_2 => p_class,
      p_text_3  => NVL(sqlt$r.color_differences_c(p_text_1, p_text_2, p_text_2), NBSP),
      p_class_3 => p_class,
      p_text_4  => p_text_3,
      p_class_4 => p_class_3,
      p_class_1 => 'lt' );
  END wrc;

  /*************************************************************************************/

  /* -------------------------
   *
   * private td_2c
   *
   * ------------------------- */
  FUNCTION td_2c (
    p_value1  IN VARCHAR2,
    p_value2  IN VARCHAR2,
    p_class   IN VARCHAR2 DEFAULT 'l',
    p_keyword IN VARCHAR2 DEFAULT NULL,
    p_color   IN BOOLEAN  DEFAULT TRUE )
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_color OR p_value1 IS NULL OR p_value2 IS NULL THEN
      RETURN td(sqlt$r.color_differences_c(p_value1, p_value2, p_value1||'<br>'||p_value2), p_class, p_keyword);
    ELSE
      RETURN td(p_value1||'<br>'||p_value2, p_class, p_keyword);
    END IF;
  END td_2c;

  /*************************************************************************************/

  /* -------------------------
   *
   * private td_2n
   *
   * ------------------------- */
  FUNCTION td_2n (
    p_value1  IN VARCHAR2, -- NUMBER is expected
    p_value2  IN VARCHAR2, -- NUMBER is expected
    p_class   IN VARCHAR2 DEFAULT 'r',
    p_keyword IN VARCHAR2 DEFAULT NULL,
    p_color   IN BOOLEAN  DEFAULT TRUE )
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_color OR p_value1 IS NULL OR p_value2 IS NULL THEN
      RETURN td(sqlt$r.color_differences(TO_NUMBER(p_value1), TO_NUMBER(p_value2), p_value1||'<br>'||p_value2), p_class, p_keyword);
    ELSE
      RETURN td(p_value1||'<br>'||p_value2, p_class, p_keyword);
    END IF;
  END td_2n;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_plan_rec
   *
   * ------------------------- */
  FUNCTION get_plan_rec (
    p_statement_id    IN NUMBER,
    p_plan_hash_value IN NUMBER )
  RETURN sqlt$_plan_header_v%ROWTYPE
  IS
    l_return sqlt$_plan_header_v%ROWTYPE;
  BEGIN
    FOR i IN (SELECT *
                FROM sqlt$_plan_header_v
               WHERE statement_id = p_statement_id
                 AND plan_hash_value = p_plan_hash_value
               ORDER BY
                     src_order,
                     plan_id,
                     inst_id,
                     child_number,
                     child_address)
    LOOP
      l_return := i;
      EXIT; -- 1st
    END LOOP;

    RETURN l_return;
  END get_plan_rec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_line_rec
   *
   * ------------------------- */
  FUNCTION get_line_rec (
    p_pln_rec IN sqlt$_plan_header_v%ROWTYPE,
    p_id      IN NUMBER )
  RETURN sqlt$_plan_extension%ROWTYPE
  IS
    l_return sqlt$_plan_extension%ROWTYPE;
  BEGIN
    SELECT *
      INTO l_return
      FROM sqlt$_plan_extension
     WHERE statement_id = p_pln_rec.statement_id
       AND source = p_pln_rec.source
       AND plan_hash_value = p_pln_rec.plan_hash_value
       AND plan_id = p_pln_rec.plan_id
       AND inst_id = p_pln_rec.inst_id
       AND child_number = p_pln_rec.child_number
       --AND child_address = p_pln_rec.child_address
       AND id = p_id;

    RETURN l_return;
  END get_line_rec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private similar_plans
   *
   * ------------------------- */
  FUNCTION similar_plans
  RETURN BOOLEAN
  IS
    FUNCTION count_plan_lines (p_pln_rec IN sqlt$_plan_header_v%ROWTYPE)
    RETURN NUMBER
    IS
      l2_count NUMBER;
    BEGIN
      SELECT MAX(id)
        INTO l2_count
        FROM sqlt$_plan_extension
       WHERE statement_id = p_pln_rec.statement_id
         AND source = p_pln_rec.source
         AND plan_hash_value = p_pln_rec.plan_hash_value
         AND plan_id = p_pln_rec.plan_id
         AND inst_id = p_pln_rec.inst_id
         AND child_number = p_pln_rec.child_number;
         --AND child_address = p_pln_rec.child_address;
      RETURN l2_count;
    END count_plan_lines;
  BEGIN
    RETURN count_plan_lines(s_pln_rec1) = count_plan_lines(s_pln_rec2);
  END similar_plans;

  /*************************************************************************************/

  /* -------------------------
   *
   * private execution_plan
   *
   * ------------------------- */
  PROCEDURE execution_plan (
    p_pln_rec1 IN sqlt$_plan_header_v%ROWTYPE,
    p_pln_rec2 IN sqlt$_plan_header_v%ROWTYPE )
  IS
    l_row_count NUMBER := 0;
    l_more NUMBER;
    l_binds_peek NUMBER;
    l_binds_capt NUMBER;
    lin_rec sqlt$_plan_extension%ROWTYPE;
  BEGIN
      -- column "more"
      SELECT COUNT(*)
        INTO l_more
        FROM sqlt$_plan_extension
       WHERE statement_id = p_pln_rec1.statement_id
         AND source = p_pln_rec1.source
         AND plan_hash_value = p_pln_rec1.plan_hash_value
         AND plan_id = p_pln_rec1.plan_id
         AND inst_id = p_pln_rec1.inst_id
         AND child_number = p_pln_rec1.child_number
         --AND child_address = p_pln_rec1.child_address
         AND more_html_table IS NOT NULL
         AND ROWNUM = 1;

      -- column "bind peek"
      SELECT COUNT(*)
        INTO l_binds_peek
        FROM sqlt$_plan_extension
       WHERE statement_id = p_pln_rec1.statement_id
         AND source = p_pln_rec1.source
         AND plan_hash_value = p_pln_rec1.plan_hash_value
         AND plan_id = p_pln_rec1.plan_id
         AND inst_id = p_pln_rec1.inst_id
         AND child_number = p_pln_rec1.child_number
         --AND child_address = p_pln_rec1.child_address
         AND binds_html_table IS NOT NULL
         AND ROWNUM = 1;

      -- column "bind capt"
      SELECT COUNT(*)
        INTO l_binds_capt
        FROM sqlt$_plan_extension
       WHERE statement_id = p_pln_rec1.statement_id
         AND source = p_pln_rec1.source
         AND plan_hash_value = p_pln_rec1.plan_hash_value
         AND plan_id = p_pln_rec1.plan_id
         AND inst_id = p_pln_rec1.inst_id
         AND child_number = p_pln_rec1.child_number
         --AND child_address = p_pln_rec1.child_address
         AND binds_html_table_capt IS NOT NULL
         AND ROWNUM = 1;

    wa('<table>');
    write_log('plan '||p_pln_rec1.statement_id||' "'||p_pln_rec1.source||'" "'||p_pln_rec1.plan_hash_value||'" "'||p_pln_rec1.plan_id||'" "'||p_pln_rec1.inst_id||'" "'||p_pln_rec1.child_number||'" "'||p_pln_rec1.child_address||'"');
    FOR i IN (SELECT *
                FROM sqlt$_plan_extension
               WHERE statement_id = p_pln_rec1.statement_id
                 AND source = p_pln_rec1.source
                 AND plan_hash_value = p_pln_rec1.plan_hash_value
                 AND plan_id = p_pln_rec1.plan_id
                 AND inst_id = p_pln_rec1.inst_id
                 AND child_number = p_pln_rec1.child_number
                 --AND child_address = p_pln_rec1.child_address
               ORDER BY
                     id)
    LOOP
        l_row_count := l_row_count + 1;
        IF l_row_count = 1 THEN
          wa('<tr>');
          wa(th('ID'));
          wa(th(mot('Exec Ord', 'Operation Execution Order')));
          wa(th('Operation'));
          wa(th('Cost'));
          wa(th('Estim Card'));
          IF l_more > 0 THEN
            wa(th('More'));
          END IF;
          IF l_binds_peek > 0 THEN
            wa(th('Peek Bind'));
          END IF;
          IF l_binds_capt > 0 THEN
            wa(th('Capt Bind'));
          END IF;
          wa('</tr>');
        END IF;

        wa('<tr>');
        IF i.parent_id IS NULL THEN
          wa(td(i.id, 'rt'));
        ELSE
          wa(td(mot(i.id, 'parent_id:'||i.parent_id||NBSP2||'position:'||i.position), 'rt'));
        END IF;
        wa(td(i.exec_order, 'r'));
        IF similar_plans THEN
          lin_rec := get_line_rec(p_pln_rec2, i.id);
          IF s_pln_rec1.source <> 'DBA_HIST_SQL_PLAN' AND s_pln_rec2.source <> 'DBA_HIST_SQL_PLAN' THEN
            wa(td(mot(sqlt$r.color_differences_c(
            i.real_depth||i.operation||i.options||i.object_type||i.object_name||i.access_predicates||i.filter_predicates,
            lin_rec.real_depth||lin_rec.operation||lin_rec.options||lin_rec.object_type||lin_rec.object_name||lin_rec.access_predicates||lin_rec.filter_predicates,
            i.plan_operation), i.operation_caption, p_nl_class => 'op'), 'op', 'nowrap'));
          ELSE -- AWR plans do not have predicates so we should not compare them
            wa(td(mot(sqlt$r.color_differences_c(
            i.real_depth||i.operation||i.options||i.object_type||i.object_name/*||i.access_predicates||i.filter_predicates*/,
            lin_rec.real_depth||lin_rec.operation||lin_rec.options||lin_rec.object_type||lin_rec.object_name/*||lin_rec.access_predicates||lin_rec.filter_predicates*/,
            i.plan_operation), i.operation_caption, p_nl_class => 'op'), 'op', 'nowrap'));
          END IF;
        ELSE
          wa(td(mot(i.plan_operation, i.operation_caption, p_nl_class => 'op'), 'op', 'nowrap'));
        END IF;
        IF i.top_cost IS NULL THEN
          IF i.io_cost IS NULL AND i.cpu_cost IS NULL AND i.bytes IS NULL AND i.time IS NULL THEN
            wa(td(i.cost, 'r'));
          ELSE
            wa(td(mot(i.cost, 'io_cost:'||i.io_cost||NBSP2||'cpu_cost:'||i.cpu_cost||'<br>bytes:'||i.bytes||NBSP2||'estim_secs:'||TO_CHAR(i.time, SECONDS_FORMAT), p_nl_class => 'nlb'), 'r'));
          END IF;
        ELSE
          wa(td(red(i.cost, i.top_cost, p_pln_rec1.cost, 'io_cost:'||i.io_cost||NBSP2||'cpu_cost:'||i.cpu_cost||'<br>bytes:'||i.bytes||NBSP2||'estim_secs:'||TO_CHAR(i.time, SECONDS_FORMAT)), 'r'));
        END IF;
        wa(td(i.cardinality, 'r'));
        IF l_more > 0 THEN
          IF i.more_html_table IS NULL THEN
            wa(td(NBSP));
          ELSE
            wa_td_hide(i.more_html_table);
          END IF;
        END IF;
        IF l_binds_peek > 0 THEN
          IF i.binds_html_table IS NULL THEN
            wa(td(NBSP));
          ELSE
            wa_td_hide(i.binds_html_table);
          END IF;
        END IF;
        IF l_binds_capt > 0 THEN
          IF i.binds_html_table_capt IS NULL THEN
            wa(td(NBSP));
          ELSE
            wa_td_hide(i.binds_html_table_capt);
          END IF;
        END IF;
        wa('</tr>');
    END LOOP;
    wa('</table>');

    -- other_xml
    FOR i IN (SELECT id, sanitized_other_xml
                FROM sqlt$_plan_extension
               WHERE statement_id = p_pln_rec1.statement_id
                 AND source = p_pln_rec1.source
                 AND plan_hash_value = p_pln_rec1.plan_hash_value
                 AND plan_id = p_pln_rec1.plan_id
                 AND inst_id = p_pln_rec1.inst_id
                 AND child_number = p_pln_rec1.child_number
                 --AND child_address = p_pln_rec1.child_address
                 AND sanitized_other_xml IS NOT NULL
               ORDER BY
                     id)
    LOOP
      BEGIN
        wa(font('Other XML (id='||i.id||'):'));
        wa_hide(i.sanitized_other_xml, TRUE);
      EXCEPTION
        WHEN OTHERS THEN
          wa(font('Other XML (id='||i.id||'):'||SQLERRM));
      END;
      wa('<br>');
    END LOOP;

    -- outline
    DECLARE
      l_outline_data CLOB;
      l_buffer VARCHAR2(32767);
    BEGIN
      FOR i IN (SELECT DISTINCT id
                  FROM sqlt$_outline_data
                 WHERE statement_id = p_pln_rec1.statement_id
                   AND source = p_pln_rec1.source
                   AND plan_hash_value = p_pln_rec1.plan_hash_value
                   AND plan_id = p_pln_rec1.plan_id
                   AND inst_id = p_pln_rec1.inst_id
                   AND child_number = p_pln_rec1.child_number
                   --AND child_address = p_pln_rec1.child_address
                 ORDER BY
                       id)
      LOOP
        l_row_count := 0;

        FOR j IN (SELECT hint
                    FROM sqlt$_outline_data
                   WHERE statement_id = p_pln_rec1.statement_id
                     AND source = p_pln_rec1.source
                     AND plan_hash_value = p_pln_rec1.plan_hash_value
                     AND plan_id = p_pln_rec1.plan_id
                     AND inst_id = p_pln_rec1.inst_id
                     AND child_number = p_pln_rec1.child_number
                     --AND child_address = p_pln_rec1.child_address
                     AND id = i.id
                   ORDER BY
                         line_id)
        LOOP
          l_row_count := l_row_count + 1;
          IF l_row_count = 1 THEN
            SYS.DBMS_LOB.CREATETEMPORARY(l_outline_data, TRUE);
            l_buffer := '  /*+'||LF||'      BEGIN_OUTLINE_DATA';
            SYS.DBMS_LOB.WRITEAPPEND(l_outline_data, LENGTH(l_buffer), l_buffer);
          END IF;
          l_buffer := LF||'      '||j.hint;
          SYS.DBMS_LOB.WRITEAPPEND(l_outline_data, LENGTH(l_buffer), l_buffer);
        END LOOP;
        IF l_row_count > 0 THEN
          l_buffer := LF||'      END_OUTLINE_DATA'||LF||'  */';
          SYS.DBMS_LOB.WRITEAPPEND(l_outline_data, LENGTH(l_buffer), l_buffer);
          BEGIN
            wa(font('Outline Data (id='||i.id||'):'));
            wa_hide('<pre>'||sqlt$r.sanitize_html_clob(l_outline_data, FALSE)||'</pre>');
            SYS.DBMS_LOB.FREETEMPORARY(l_outline_data);
          EXCEPTION
            WHEN OTHERS THEN
              wa(font('Outline Data (id='||i.id||'):'||SQLERRM));
          END;
          wa('<br>');
        END IF;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('outline_data: '||SQLERRM);
    END;

    -- leading
    DECLARE
      l_leading_data CLOB;
      l_buffer VARCHAR2(32767);
    BEGIN
      FOR i IN (SELECT DISTINCT id
                  FROM sqlt$_outline_data
                 WHERE statement_id = p_pln_rec1.statement_id
                   AND source = p_pln_rec1.source
                   AND plan_hash_value = p_pln_rec1.plan_hash_value
                   AND plan_id = p_pln_rec1.plan_id
                   AND inst_id = p_pln_rec1.inst_id
                   AND child_number = p_pln_rec1.child_number
                   --AND child_address = p_pln_rec1.child_address
                   AND hint LIKE 'LEADING%'
                 ORDER BY
                       id)
      LOOP
        l_row_count := 0;

        FOR j IN (SELECT hint
                    FROM sqlt$_outline_data
                   WHERE statement_id = p_pln_rec1.statement_id
                     AND source = p_pln_rec1.source
                     AND plan_hash_value = p_pln_rec1.plan_hash_value
                     AND plan_id = p_pln_rec1.plan_id
                     AND inst_id = p_pln_rec1.inst_id
                     AND child_number = p_pln_rec1.child_number
                     --AND child_address = p_pln_rec1.child_address
                     AND id = i.id
                     AND hint LIKE 'LEADING%'
                   ORDER BY
                         line_id)
        LOOP
          l_row_count := l_row_count + 1;
          IF l_row_count = 1 THEN
            SYS.DBMS_LOB.CREATETEMPORARY(l_leading_data, TRUE);
          END IF;
          l_buffer := LF||REPLACE(REPLACE(REPLACE(j.hint, 'LEADING'), '"'), '@SEL$', '@');
          SYS.DBMS_LOB.WRITEAPPEND(l_leading_data, LENGTH(l_buffer), l_buffer);
        END LOOP;
        IF l_row_count > 0 THEN
          BEGIN
            wa(font('Leading (id='||i.id||'):'));
            wa_hide('<pre>'||sqlt$r.sanitize_html_clob(l_leading_data, FALSE)||'</pre>');
            SYS.DBMS_LOB.FREETEMPORARY(l_leading_data);
          EXCEPTION
            WHEN OTHERS THEN
              wa(font('Leading (id='||i.id||'):'||SQLERRM));
          END;
          wa('<br>');
        END IF;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('leading_data: '||SQLERRM);
    END;
  END execution_plan;

  /*************************************************************************************/

  /* -------------------------
   *
   * private plan_info
   *
   * ------------------------- */
  PROCEDURE plan_info (p_pln_rec IN sqlt$_plan_header_v%ROWTYPE)
  IS
    l_row_count NUMBER := 0;
  BEGIN
    l_row_count := 0;
    FOR i IN (SELECT info_type,
                     info_value
                FROM sqlt$_plan_info
               WHERE statement_id = p_pln_rec.statement_id
                 AND source = p_pln_rec.source
                 AND plan_hash_value = p_pln_rec.plan_hash_value
                 AND plan_id = p_pln_rec.plan_id
                 AND inst_id = p_pln_rec.inst_id
                 AND child_number = p_pln_rec.child_number
                 --AND child_address = p_pln_rec.child_address
               ORDER BY
                     id,
                     line_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF l_row_count = 1 THEN
        wa('<table>');
        wa('<tr>');
        wa(th('#'));
        wa(th('Type'));
        wa(th('Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.info_type, 'l'));
      wa(td(i.info_value, 'l'));
      wa('</tr>');
    END LOOP;
    IF l_row_count > 0 THEN
      wa('</table>');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('plan_info: '||SQLERRM);
  END plan_info;

  /*************************************************************************************/

  /* -------------------------
   *
   * private peeked_binds
   *
   * ------------------------- */
  PROCEDURE peeked_binds (p_pln_rec IN sqlt$_plan_header_v%ROWTYPE)
  IS
    l_row_count NUMBER := 0;
  BEGIN
    l_row_count := 0;
    FOR i IN (SELECT name,
                     type,
                     value
                FROM sqlt$_peeked_binds_v
               WHERE statement_id = p_pln_rec.statement_id
                 AND source = p_pln_rec.source
                 AND plan_hash_value = p_pln_rec.plan_hash_value
                 AND plan_id = p_pln_rec.plan_id
                 AND inst_id = p_pln_rec.inst_id
                 AND child_number = p_pln_rec.child_number
                 --AND child_address = p_pln_rec.child_address
               ORDER BY
                     position)
    LOOP
      l_row_count := l_row_count + 1;
      IF l_row_count = 1 THEN
        wa('<table>');
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Type'));
        wa(th('Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.type, 'l'));
      wa(td(i.value, 'l'));
      wa('</tr>');
    END LOOP;
    IF l_row_count > 0 THEN
      wa('</table>');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('peeked_binds: '||SQLERRM);
  END peeked_binds;

  /*************************************************************************************/

  /* -------------------------
   *
   * private captured_binds
   *
   * ------------------------- */
  PROCEDURE captured_binds (p_pln_rec IN sqlt$_plan_header_v%ROWTYPE)
  IS
    l_row_count NUMBER := 0;
  BEGIN
    l_row_count := 0;
    FOR i IN (SELECT name,
                     type,
                     value
                FROM sqlt$_captured_binds_v
               WHERE statement_id = p_pln_rec.statement_id
                 AND source = p_pln_rec.source
                 AND plan_hash_value = p_pln_rec.plan_hash_value
                 AND inst_id = p_pln_rec.inst_id
                 AND child_number = p_pln_rec.child_number
                 --AND child_address = p_pln_rec.child_address
               ORDER BY
                     position)
    LOOP
      l_row_count := l_row_count + 1;
      IF l_row_count = 1 THEN
        wa('<table>');
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Type'));
        wa(th('Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.type, 'l'));
      wa(td(i.value, 'l'));
      wa('</tr>');
    END LOOP;
    IF l_row_count > 0 THEN
      wa('</table>');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('captured_binds: '||SQLERRM);
  END captured_binds;

  /*************************************************************************************/

  /* -------------------------
   *
   * private optimizer_environment
   *
   * ------------------------- */
  PROCEDURE optimizer_environment (p_pln_rec IN sqlt$_plan_header_v%ROWTYPE)
  IS
    l_row_count NUMBER := 0;
  BEGIN
    l_row_count := 0;
    FOR i IN (SELECT name, value
                FROM sqlt$_gv$sql_optimizer_env
               WHERE statement_id = p_pln_rec.statement_id
                 AND inst_id = p_pln_rec.inst_id
                 AND child_number = p_pln_rec.child_number
                 --AND child_address = p_pln_rec.child_address
               ORDER BY
                     id)
    LOOP
      l_row_count := l_row_count + 1;
      IF l_row_count = 1 THEN
        wa('<table>');
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.value, 'l'));
      wa('</tr>');
    END LOOP;
    IF l_row_count > 0 THEN
      wa('</table>');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('optimizer_environment: '||SQLERRM);
  END optimizer_environment;

  /*************************************************************************************/

  /* -------------------------
   *
   * public compare_report
   *
   * called by: sqltcompare.sql
   *
   * ------------------------- */
  PROCEDURE compare_report (
    p_statement_id1    IN NUMBER,
    p_statement_id2    IN NUMBER,
    p_plan_hash_value1 IN NUMBER,
    p_plan_hash_value2 IN NUMBER )
  IS
    l_plan_hash_value1 NUMBER;
    l_plan_hash_value2 NUMBER;
    l_row_count NUMBER;
    clob_rec sqli$_clob%ROWTYPE;

  BEGIN
    sqlt$a.validate_user(USER);
    write_log('=> compare_report');

    IF p_plan_hash_value1 IS NULL THEN
      write_log('getting sole plan hash value for statement "'||p_statement_id1||'"');
      SELECT DISTINCT plan_hash_value
        INTO l_plan_hash_value1
        FROM sqlt$_plan_extension
       WHERE statement_id = p_statement_id1;
    ELSE
      l_plan_hash_value1 := p_plan_hash_value1;
    END IF;

    IF p_plan_hash_value2 IS NULL THEN
      write_log('getting sole plan hash value for statement "'||p_statement_id2||'"');
      SELECT DISTINCT plan_hash_value
        INTO l_plan_hash_value2
        FROM sqlt$_plan_extension
       WHERE statement_id = p_statement_id2;
    ELSE
      l_plan_hash_value2 := p_plan_hash_value2;
    END IF;

    sqlt$a.common_initialization;
    sqlt$t.seeds_child_address(p_statement_id1);
    sqlt$t.seeds_child_address(p_statement_id2);

    s_rows_table_l := sqlt$a.get_param_n('r_rows_table_l');

    s_sql_rec1 := sqlt$a.get_statement(p_statement_id1);
    s_sql_rec2 := sqlt$a.get_statement(p_statement_id2);

    IF l_plan_hash_value1 > 0 THEN
      s_pln_rec1 := get_plan_rec(p_statement_id1, l_plan_hash_value1);
    ELSE
      s_pln_rec1 := NULL;
    END IF;

    IF l_plan_hash_value2 > 0 THEN
      s_pln_rec2 := get_plan_rec(p_statement_id2, l_plan_hash_value2);
    ELSE
      s_pln_rec1 := NULL;
    END IF;

    s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id1)||'_s'||sqlt$a.get_statement_id_c(p_statement_id2)||'_compare.html';

    /* -------------------------
     * Header
     * ------------------------- */
    BEGIN
      write_log('-> header');
      s_file_rec.file_text :=
'<html>
<!-- $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $ -->
<!-- '||COPYRIGHT||' -->
<!-- Author: '||TOOL_DEVELOPER_EMAIL||' -->
<head>
<title>'||s_file_rec.filename||'</title>';

      SELECT * INTO clob_rec FROM sqli$_clob WHERE clob_id = 'CSS';
      append(clob_rec.clob_text);

      SELECT * INTO clob_rec FROM sqli$_clob WHERE clob_id = 'SHOW_HIDE';
      append(clob_rec.clob_text);

      SELECT * INTO clob_rec FROM sqli$_clob WHERE clob_id = 'OVERLIB1';
      append(clob_rec.clob_text);

      SELECT * INTO clob_rec FROM sqli$_clob WHERE clob_id = 'OVERLIB2';
      append(clob_rec.clob_text);

      SELECT * INTO clob_rec FROM sqli$_clob WHERE clob_id = 'OVERLIB3';
      append(clob_rec.clob_text);

      SELECT * INTO clob_rec FROM sqli$_clob WHERE clob_id = 'OVERLIB4';
      append(clob_rec.clob_text);

      SELECT * INTO clob_rec FROM sqli$_clob WHERE clob_id = 'OVERLIB5';
      append(clob_rec.clob_text);

      wa('<h1>'||NOTE_NUMBER||' SQLT COMPARE '||sqlt$a.get_param('tool_version')||' Report: '||s_file_rec.filename||'</h1>');
      wa('<h2>'||
      s_sql_rec1.statid||NBSP2||TO_CHAR(s_sql_rec1.tool_start_date, LOAD_DATE_FORMAT)||NBSP2||l_plan_hash_value1||
      '<br>'||
      s_sql_rec2.statid||NBSP2||TO_CHAR(s_sql_rec2.tool_start_date, LOAD_DATE_FORMAT)||NBSP2||l_plan_hash_value2||
      '</h2>');

      wa('<a name="toc"></a>
<ul>');

      IF p_statement_id1 <> p_statement_id2 THEN
        wa('<li><a href="#sql_text">SQL Text</a></li>
<li><a href="#sql_id">SQL Identification</a></li>
<li><a href="#env">Environment</a></li>
<li><a href="#nls">NLS Session Parameters</a></li>
<li><a href="#io_cal">I/O Calibration</a></li>
<li><a href="#cbo_env">CBO Environment</a></li>
<li><a href="#fix_ctrl">Fix Control</a></li>
<li><a href="#sys_stats">CBO System Statistics</a></li>');
      END IF;

      IF l_plan_hash_value1 > 0 OR l_plan_hash_value2 > 0 THEN
        wa('<li><a href="#plan">Execution Plan</a></li>');
      END IF;

      IF p_statement_id1 <> p_statement_id2 THEN
        wa('<li><a href="#tables">Tables</a></li>
<li><a href="#tab_part">Table Partitions</a></li>
<li><a href="#indexes">Indexes</a></li>
<li><a href="#idx_part">Index Partitions</a></li>
<li><a href="#columns">Columns</a></li>');
      END IF;

      wa('</ul>');
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.header:'||SQLERRM);
    END;

    /* -------------------------
     * SQL Text
     * ------------------------- */
    BEGIN
      write_log('-> sql_text');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('SQL Text', 'sql_text'));
        wa('<table><tr>'||th(s_sql_rec1.statid)||th(s_sql_rec2.statid)||'</tr>');
        wa('<tr><td class="l"><pre>');
        font_sanitize_and_append(s_sql_rec1.sql_text_clob, FALSE, 200); -- was 120 then 2000
        wa('</pre></td><td class="l"><pre>');
        font_sanitize_and_append(s_sql_rec2.sql_text_clob, FALSE, 200); -- was 120 then 2000
        wa('</pre></td></tr>');
        wa('</table>');
        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.sql_text:'||SQLERRM);
    END;

    /* -------------------------
     * SQL Identification
     * ------------------------- */
    BEGIN
      write_log('-> sql_identification');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('SQL Identification', 'sql_id'));
        wa('<table><tr>'||th()||th(s_sql_rec1.statid)||th(s_sql_rec2.statid)||'</tr>');
        wrc('SQL ID', s_sql_rec1.sql_id, s_sql_rec2.sql_id);
        wrc('Hash Value', s_sql_rec1.hash_value, s_sql_rec2.hash_value);
        wrc('SQL Handle', s_sql_rec1.sql_handle, s_sql_rec2.sql_handle);
        wrc('Plan Hash Value', l_plan_hash_value1, l_plan_hash_value2);
        wrc('SQLT Plan Hash Value', s_pln_rec1.sqlt_plan_hash_value, s_pln_rec2.sqlt_plan_hash_value);
        wrc('SQLT Plan Hash Value2', s_pln_rec1.sqlt_plan_hash_value2, s_pln_rec2.sqlt_plan_hash_value2);
        wrc('Signature for Stored Outlines', s_sql_rec1.signature_so, s_sql_rec2.signature_so);
        wrc('Signature for SQL Profiles<br>(force match FALSE)', s_sql_rec1.signature_sta, s_sql_rec2.signature_sta);
        wrc('Signature for SQL Profiles<br>(force match TRUE)', s_sql_rec1.signature_sta_force_match, s_sql_rec2.signature_sta_force_match);
        wrc('"EXPLAIN PLAN FOR" SQL ID<br>for stripped sql_text', s_sql_rec1.xplain_sql_id, s_sql_rec2.xplain_sql_id);
        wrc('SQL ID<br>for unstripped sql_text', s_sql_rec1.sql_id_unstripped, s_sql_rec2.sql_id_unstripped);
        wrc('Hash Value<br>for unstripped sql_text', s_sql_rec1.hash_value_unstripped, s_sql_rec2.hash_value_unstripped);
        wrc('Signature for Stored Outlines<br>for unstripped sql_text', s_sql_rec1.signature_so_unstripped, s_sql_rec2.signature_so_unstripped);
        wrc('Signature for SQL Profiles<br>for unstripped sql_text<br>(force match FALSE)', s_sql_rec1.signature_sta_unstripped, s_sql_rec2.signature_sta_unstripped);
        wrc('Signature for SQL Profiles<br>for unstripped sql_text<br>(force match TRUE)', s_sql_rec1.signature_sta_fm_unstripped, s_sql_rec2.signature_sta_fm_unstripped);
        wrc('Statement Response Time', s_sql_rec1.statement_response_time, s_sql_rec2.statement_response_time);
        wa('</table>');
        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.sql_id:'||SQLERRM);
    END;

    /* -------------------------
     * Environment
     * ------------------------- */
    BEGIN
      write_log('-> environment');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('Environment', 'env'));
        wa('<table><tr>'||th()||th(s_sql_rec1.statid)||th(s_sql_rec2.statid)||'</tr>');
        wrc('Host Name', s_sql_rec1.host_name_short, s_sql_rec2.host_name_short);
        wrc('CPU_Count', s_sql_rec1.cpu_count, s_sql_rec2.cpu_count);
		wrc('Num CPUs', s_sql_rec1.num_cpus, s_sql_rec2.num_cpus);
		wrc('Num Cores', s_sql_rec1.num_cpu_cores, s_sql_rec2.num_cpu_cores);
		wrc('Num Sockets', s_sql_rec1.num_cpu_sockets, s_sql_rec2.num_cpu_sockets);
        wrc('Exadata', NVL(s_sql_rec1.exadata, 'NO'), NVL(s_sql_rec2.exadata, 'NO'));
        wrc('RAC', s_sql_rec1.rac, s_sql_rec2.rac);
        wrc('NLS Characterset<br>(database_properties)', s_sql_rec1.nls_characterset, s_sql_rec2.nls_characterset);
        wrc('DB Time Zone<br>(database_properties)', s_sql_rec1.dbtimezone, s_sql_rec2.dbtimezone);
        wrc('DB Block Size<br>(db_block_size)', s_sql_rec1.db_block_size, s_sql_rec2.db_block_size);
        wrc('Optim Peek User Binds<br>(_optim_peek_user_binds)', s_sql_rec1.optim_peek_user_binds, s_sql_rec2.optim_peek_user_binds);
        wrc('DB Size in Terabytes<br>(dba_data_files)', TO_CHAR(ROUND(s_sql_rec1.total_bytes / 1e12, 3), NUMBER_FORMAT)||' TB', TO_CHAR(ROUND(s_sql_rec2.total_bytes / 1e12, 3), NUMBER_FORMAT)||' TB');
        --wrc('DB Size in Bytes<br>(dba_data_files)', s_sql_rec1.total_bytes, s_sql_rec2.total_bytes);
        --wrc('DB Size in Blocks<br>(dba_data_files)', s_sql_rec1.total_blocks, s_sql_rec2.total_blocks);
        wrc('TC Data Size in Gigabytes<br>(dba_segments)', TO_CHAR(ROUND(s_sql_rec1.segments_total_bytes / 1e9, 3), NUMBER_FORMAT)||' GB', TO_CHAR(ROUND(s_sql_rec2.segments_total_bytes / 1e9, 3), NUMBER_FORMAT)||' GB');
        wrc('Platform', s_sql_rec1.platform, s_sql_rec2.platform);
        wrc('Product Version', s_sql_rec1.product_version, s_sql_rec2.product_version);
        wrc('RDBMS Version', s_sql_rec1.rdbms_version, s_sql_rec2.rdbms_version);
        wrc('Standby Database Link', s_sql_rec1.stand_by_dblink, s_sql_rec2.stand_by_dblink);
        wrc('Language', s_sql_rec1.language, s_sql_rec2.language);
        wrc('Database Name and ID', s_sql_rec1.database_name_short||'('||s_sql_rec1.database_id||')', s_sql_rec2.database_name_short||'('||s_sql_rec2.database_id||')');
        wrc('Instance Name and ID', s_sql_rec1.instance_name_short||'('||s_sql_rec1.instance_number||')', s_sql_rec2.instance_name_short||'('||s_sql_rec2.instance_number||')');
        wrc('EBS', NVL(s_sql_rec1.apps_release, 'NO'), NVL(s_sql_rec2.apps_release, 'NO'));
        wrc('EBS System Name', s_sql_rec1.apps_system_name, s_sql_rec2.apps_system_name);
        wrc('Siebel', s_sql_rec1.siebel, s_sql_rec2.siebel);
        wrc('Siebel App Version', s_sql_rec1.siebel_app_ver, s_sql_rec2.siebel_app_ver);
        wrc('PSFT', s_sql_rec1.psft, s_sql_rec2.psft);
        wrc('PSFT Tools Release', s_sql_rec1.psft_tools_rel, s_sql_rec2.psft_tools_rel);
        wrc('User Name and ID', s_sql_rec1.username||' ('||s_sql_rec1.user_id||')', s_sql_rec2.username||' ('||s_sql_rec2.user_id||')');
        wrc('Input Filename', s_sql_rec1.input_filename, s_sql_rec2.input_filename);
        wrc('Statement Set ID', s_sql_rec1.statement_set_id, s_sql_rec2.statement_set_id);
        wrc('Group ID', s_sql_rec1.group_id, s_sql_rec2.group_id);
        wa('</table>');
        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.env:'||SQLERRM);
    END;

    /* -------------------------
     * NLS Parameters
     * ------------------------- */
    BEGIN
      write_log('-> nls_parameters');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('NLS Session Parameters', 'nls'));
        wa('NLS session parameters with different values between the two sessions where SQLT was executed.');
        wa('<table><tr>'||th('Name')||th(s_sql_rec1.statid)||th(s_sql_rec2.statid)||'</tr>');

        FOR i IN (SELECT parameter, s1_value, s2_value
                    FROM (
                  SELECT s1.parameter, s1.value s1_value, s2.value s2_value
                    FROM sqlt$_gv$nls_parameters s1,
                         sqlt$_gv$nls_parameters s2
                   WHERE s1.statement_id = s_sql_rec1.statement_id
                     AND s1.inst_id = s_sql_rec1.instance_number
                     AND s_sql_rec2.statement_id = s2.statement_id(+)
                     AND s_sql_rec2.instance_number = s2.inst_id(+)
                     AND s1.parameter = s2.parameter(+)
                   UNION
                  SELECT s2.parameter, s1.value s1_value, s2.value s2_value
                    FROM sqlt$_gv$nls_parameters s1,
                         sqlt$_gv$nls_parameters s2
                   WHERE s2.statement_id = s_sql_rec2.statement_id
                     AND s2.inst_id = s_sql_rec2.instance_number
                     AND s_sql_rec1.statement_id = s1.statement_id(+)
                     AND s_sql_rec1.instance_number = s1.inst_id(+)
                     AND s2.parameter = s1.parameter(+))
                   WHERE UPPER(NVL(s1_value, '-666')) <> UPPER(NVL(s2_value, '-666'))
                   ORDER BY
                         parameter,
                         s1_value,
                         s2_value)
        LOOP
          wr (
            p_text_1  => i.parameter,
            p_class_1 => 'lt',
            p_text_2  => NVL(i.s1_value, NBSP),
            p_class_2 => 'l',
            p_text_3  => NVL(i.s2_value, NBSP),
            p_class_3 => 'l' );
        END LOOP;

        wa('</table>');
        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.nls:'||SQLERRM);
    END;

    /* -------------------------
     * I/O Calibration
     * ------------------------- */
    BEGIN
      write_log('-> io_calibration');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('I/O Calibration', 'io_cal'));
        wa('<table><tr>'||th()||th(s_sql_rec1.statid)||th(s_sql_rec2.statid)||'</tr>');
        wrc('start_time', TO_CHAR(s_sql_rec1.ioc_start_time, TIMESTAMP_FORMAT6), TO_CHAR(s_sql_rec2.ioc_start_time, TIMESTAMP_FORMAT6));
        wrc('end_time', TO_CHAR(s_sql_rec1.ioc_end_time, TIMESTAMP_FORMAT6), TO_CHAR(s_sql_rec2.ioc_end_time, TIMESTAMP_FORMAT6));
        wrc('max_iops', s_sql_rec1.ioc_max_iops, s_sql_rec2.ioc_max_iops);
        wrc('max_mbps', s_sql_rec1.ioc_max_mbps, s_sql_rec2.ioc_max_mbps);
        wrc('max_pmbps', s_sql_rec1.ioc_max_pmbps, s_sql_rec2.ioc_max_pmbps);
        wrc('latency', s_sql_rec1.ioc_latency, s_sql_rec2.ioc_latency);
        wrc('num_physical_disks', s_sql_rec1.ioc_num_physical_disks, s_sql_rec2.ioc_num_physical_disks);
        wrc('status', s_sql_rec1.ioc_status, s_sql_rec2.ioc_status);
        wrc('calibration_time', TO_CHAR(s_sql_rec1.ioc_calibration_time, TIMESTAMP_FORMAT3), TO_CHAR(s_sql_rec2.ioc_calibration_time, TIMESTAMP_FORMAT3));
        wa('</table>');
        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.io_cal:'||SQLERRM);
    END;

    /* -------------------------
     * CBO Environment
     * ------------------------- */
    BEGIN
      write_log('-> cbo_environment');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('CBO Environment', 'cbo_env'));
        wa('Cost-based Optimizer initialization parameters with different values between the two sessions where SQLT was executed.');
        wa('<table><tr>'||th('Name')||th(s_sql_rec1.statid)||th(s_sql_rec2.statid)||th('Description')||'</tr>');

        FOR i IN (SELECT name, s1_value, s2_value, description
                    FROM (
                  SELECT s1.name, s1.value s1_value, s2.value s2_value, NVL(s1.description, s2.description) description
                    FROM sqlt$_gv$parameter_cbo s1,
                         sqlt$_gv$parameter_cbo s2
                   WHERE s1.statement_id = s_sql_rec1.statement_id
                     AND s1.inst_id = s_sql_rec1.instance_number
                     AND s_sql_rec2.statement_id = s2.statement_id(+)
                     AND s_sql_rec2.instance_number = s2.inst_id(+)
                     AND s1.name = s2.name(+)
                   UNION
                  SELECT s2.name, s1.value s1_value, s2.value s2_value, NVL(s1.description, s2.description) description
                    FROM sqlt$_gv$parameter_cbo s1,
                         sqlt$_gv$parameter_cbo s2
                   WHERE s2.statement_id = s_sql_rec2.statement_id
                     AND s2.inst_id = s_sql_rec2.instance_number
                     AND s_sql_rec1.statement_id = s1.statement_id(+)
                     AND s_sql_rec1.instance_number = s1.inst_id(+)
                     AND s2.name = s1.name(+))
                   WHERE UPPER(NVL(s1_value, '-666')) <> UPPER(NVL(s2_value, '-666'))
                   ORDER BY
                         name,
                         s1_value,
                         s2_value)
        LOOP
          wr (
            p_text_1  => i.name,
            p_class_1 => 'lt',
            p_text_2  => NVL(i.s1_value, NBSP),
            p_class_2 => 'l',
            p_text_3  => NVL(i.s2_value, NBSP),
            p_class_3 => 'l',
            p_text_4  => NVL(i.description, NBSP),
            p_class_4 => 'l' );
        END LOOP;

        wa('</table>');
        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.cbo_env:'||SQLERRM);
    END;

    /* -------------------------
     * Fix Control
     * ------------------------- */
    BEGIN
      write_log('-> fix_control');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('Fix Control', 'fix_ctrl'));
        wa('Fix Control initialization parameters with different values between the two sessions where SQLT was executed.');
        wa('<table><tr>'||th('Fix')||th(s_sql_rec1.statid)||th(s_sql_rec2.statid)||th('Description')||'</tr>');

        FOR i IN (SELECT bugno, s1_value, s2_value, description
                    FROM (
                  SELECT s1.bugno, s1.value s1_value, s2.value s2_value, s1.description
                    FROM sqlt$_v$session_fix_control s1,
                         sqlt$_v$session_fix_control s2
                   WHERE s1.statement_id = s_sql_rec1.statement_id
                     AND s_sql_rec2.statement_id = s2.statement_id(+)
                     AND s1.bugno = s2.bugno(+)
                   UNION
                  SELECT s2.bugno, s1.value s1_value, s2.value s2_value, s2.description
                    FROM sqlt$_v$session_fix_control s1,
                         sqlt$_v$session_fix_control s2
                   WHERE s2.statement_id = s_sql_rec2.statement_id
                     AND s_sql_rec1.statement_id = s1.statement_id(+)
                     AND s2.bugno = s1.bugno(+))
                   WHERE NVL(s1_value, -666) <>  NVL(s2_value, -666)
                   ORDER BY
                         bugno,
                         s1_value,
                         s2_value)
        LOOP
          wr (
            p_text_1  => i.bugno,
            p_class_1 => 'lt',
            p_text_2  => NVL(TO_CHAR(i.s1_value), NBSP),
            p_class_2 => 'c',
            p_text_3  => NVL(TO_CHAR(i.s2_value), NBSP),
            p_class_3 => 'c',
            p_text_4  => NVL(i.description, NBSP),
            p_class_4 => 'l' );
        END LOOP;

        wa('</table>');
        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.fix_ctrl:'||SQLERRM);
    END;

    /* -------------------------
     * CBO System Statistics
     * ------------------------- */
    BEGIN
      write_log('-> cbo_system_statistics');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('CBO System Statistics', 'sys_stats'));
        wa('System Statistics for the two sessions where SQLT was executed.');

        wa(h3(mot('System Statistics', 'AUX_STATS$'), 'ss_main', FALSE));
        wa('<table><tr>'||th('Name')||th(s_sql_rec1.statid)||th(s_sql_rec2.statid)||'</tr>');
        FOR i IN (SELECT pname, s1_value, s2_value, description
                    FROM (
                  SELECT s1.pname, s1.pval1 s1_value, s2.pval1 s2_value, s1.description, s1.order_by
                    FROM sqlt$_aux_stats$ s1,
                         sqlt$_aux_stats$ s2
                   WHERE s1.statement_id = s_sql_rec1.statement_id
                     AND s1.sname = 'SYSSTATS_MAIN'
                     AND s_sql_rec2.statement_id = s2.statement_id(+)
                     AND 'SYSSTATS_MAIN' = s2.sname(+)
                     AND s1.pname = s2.pname(+)
                   UNION
                  SELECT s2.pname, s1.pval1 s1_value, s2.pval1 s2_value, s2.description, s2.order_by
                    FROM sqlt$_aux_stats$ s1,
                         sqlt$_aux_stats$ s2
                   WHERE s2.statement_id = s_sql_rec2.statement_id
                     AND s2.sname = 'SYSSTATS_MAIN'
                     AND s_sql_rec1.statement_id = s1.statement_id(+)
                     AND 'SYSSTATS_MAIN' = s1.sname(+)
                     AND s2.pname = s1.pname(+))
                   --WHERE NVL(s1_value, -666) <>  NVL(s2_value, -666)
                   ORDER BY
                         order_by NULLS LAST,
                         pname)
        LOOP
          wrn (
            p_text     => mot(i.pname, i.description, NULL, i.pname),
            p_number_1 => i.s1_value,
            p_number_2 => i.s2_value );
        END LOOP;
        wa('</table>');

        wa(h3(mot('Basis and Synthesized Values', 'AUX_STATS$ and V$PARAMETER'), 'ss_bs', FALSE));
        wa('<table><tr>'||th('Name')||th(s_sql_rec1.statid)||th(s_sql_rec2.statid)||'</tr>');

        wrn (
          p_text     => 'db_block_size',
          p_number_1 => s_sql_rec1.db_block_size,
          p_number_2 => s_sql_rec2.db_block_size );

        wrn (
          p_text     => 'db_file_multiblock_read_count',
          p_number_1 => s_sql_rec1.db_file_multiblock_read_count,
          p_number_2 => s_sql_rec2.db_file_multiblock_read_count );

        wrn (
          p_text     => '_db_file_optimizer_read_count',
          p_number_1 => s_sql_rec1.udb_file_optimizer_read_count,
          p_number_2 => s_sql_rec2.udb_file_optimizer_read_count );

        wrn (
          p_text     => '_db_file_exec_read_count',
          p_number_1 => s_sql_rec1.udb_file_exec_read_count,
          p_number_2 => s_sql_rec2.udb_file_exec_read_count );

        IF s_sql_rec1.synthetized_mbrc_and_readtim = 'Y' OR s_sql_rec2.synthetized_mbrc_and_readtim = 'Y' THEN
          wrn (
            p_text     => mot('Estimated CPUSPEED', 'NVL(cpuspeed, cpuspeednw)', NULL, 'CPUSPEED'),
            p_number_1 => NVL(s_sql_rec1.cpuspeed, s_sql_rec1.cpuspeednw),
            p_number_2 => NVL(s_sql_rec2.cpuspeed, s_sql_rec2.cpuspeednw) );

          wrn (
            p_text     => mot('Estimated MBRC', '_db_file_optimizer_read_count', NULL, 'MBRC'),
            p_number_1 => s_sql_rec1.mbrc,
            p_number_2 => s_sql_rec2.mbrc );

          wrn (
            p_text     => mot('Estimated SREADTIM', 'ioseektim + (db_block_size / iotfrspeed)', NULL, 'SREADTIM'),
            p_number_1 => s_sql_rec1.sreadtim,
            p_number_2 => s_sql_rec2.sreadtim );

          wrn (
            p_text     => mot('Estimated MREADTIM', 'ioseektim + ((mbrc * db_block_size) / iotfrspeed)', NULL, 'MREADTIM'),
            p_number_1 => s_sql_rec1.mreadtim,
            p_number_2 => s_sql_rec2.mreadtim );
        END IF;

        wrn (
          p_text     => mot('CPU Cost Scaling Factor', '1 / (cpuspeed * 1000 * sreadtim)', NULL, 'CPU_COST_SCALING_FACTOR'),
          p_number_1 => LOWER(TO_CHAR(s_sql_rec1.cpu_cost_scaling_factor, SCIENTIFIC_NOTATION)),
          p_number_2 => LOWER(TO_CHAR(s_sql_rec2.cpu_cost_scaling_factor, SCIENTIFIC_NOTATION)));

        wrn (
          p_text     => mot('CPU Cost Scaling Factor (inverse)', 'cpuspeed * 1000 * sreadtim'),
          p_number_1 => ROUND(1 / s_sql_rec1.cpu_cost_scaling_factor),
          p_number_2 => ROUND(1 / s_sql_rec2.cpu_cost_scaling_factor) );

        wrn (
          p_text     => mot('Actual SREADTIM', 'As per Session Events (GV$SESSION_EVENT) "db file sequential read"', NULL, 'Actual SREADTIM'),
          p_number_1 => s_sql_rec1.actual_sreadtim,
          p_number_2 => s_sql_rec2.actual_sreadtim );

        wrn (
          p_text     => mot('Actual MREADTIM', 'As per Session Events (GV$SESSION_EVENT) "db file scattered read"', NULL, 'Actual MREADTIM'),
          p_number_1 => s_sql_rec1.actual_mreadtim,
          p_number_2 => s_sql_rec2.actual_mreadtim );

        wa('</table>');
        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.sys_stats:'||SQLERRM);
    END;

    /* -------------------------
     * Execution Plan
     * ------------------------- */
    BEGIN
      write_log('-> execution_plan');
      IF l_plan_hash_value1 > 0 OR l_plan_hash_value2 > 0 THEN
        -- plan
        BEGIN
          wa(h2('Execution Plan', 'plan'));
          wa('<table><tr>'||
          th(s_sql_rec1.statid||NBSP2||l_plan_hash_value1||NBSP2||s_pln_rec1.sqlt_plan_hash_value||NBSP2||s_pln_rec1.sqlt_plan_hash_value2)||
          th(s_sql_rec2.statid||NBSP2||l_plan_hash_value2||NBSP2||s_pln_rec2.sqlt_plan_hash_value||NBSP2||s_pln_rec2.sqlt_plan_hash_value2)||
          '</tr>');
          wa('<tr><td class="lw">');
          execution_plan(s_pln_rec1, s_pln_rec2);
          wa('</td><td class="lw">');
          execution_plan(s_pln_rec2, s_pln_rec1);
          wa('</td></tr>');
          wa('</table>');
        END;

        -- plan_info
        BEGIN
          wa(h3(mot('Plan Info', 'OTHER_XML'), p_hr => FALSE));
          wa('<table><tr>'||
          th(s_sql_rec1.statid||NBSP2||l_plan_hash_value1||NBSP2||s_pln_rec1.sqlt_plan_hash_value||NBSP2||s_pln_rec1.sqlt_plan_hash_value2)||
          th(s_sql_rec2.statid||NBSP2||l_plan_hash_value2||NBSP2||s_pln_rec2.sqlt_plan_hash_value||NBSP2||s_pln_rec2.sqlt_plan_hash_value2)||
          '</tr>');
          wa('<tr><td class="lw">');
          plan_info(s_pln_rec1);
          wa('</td><td class="lw">');
          plan_info(s_pln_rec2);
          wa('</td></tr>');
          wa('</table>');
        END;

        -- peeked_binds
        BEGIN
          wa(h3(mot('Peeked Binds', 'OTHER_XML'), p_hr => FALSE));
          wa('<table><tr>'||
          th(s_sql_rec1.statid||NBSP2||l_plan_hash_value1||NBSP2||s_pln_rec1.sqlt_plan_hash_value||NBSP2||s_pln_rec1.sqlt_plan_hash_value2)||
          th(s_sql_rec2.statid||NBSP2||l_plan_hash_value2||NBSP2||s_pln_rec2.sqlt_plan_hash_value||NBSP2||s_pln_rec2.sqlt_plan_hash_value2)||
          '</tr>');
          wa('<tr><td class="lw">');
          peeked_binds(s_pln_rec1);
          wa('</td><td class="lw">');
          peeked_binds(s_pln_rec2);
          wa('</td></tr>');
          wa('</table>');
        END;

        -- captured_binds
        BEGIN
          wa(h3(mot('Captured Binds', 'GV$SQL_BIND_CAPTURE'), p_hr => FALSE));
          wa('<table><tr>'||
          th(s_sql_rec1.statid||NBSP2||l_plan_hash_value1||NBSP2||s_pln_rec1.sqlt_plan_hash_value||NBSP2||s_pln_rec1.sqlt_plan_hash_value2)||
          th(s_sql_rec2.statid||NBSP2||l_plan_hash_value2||NBSP2||s_pln_rec2.sqlt_plan_hash_value||NBSP2||s_pln_rec2.sqlt_plan_hash_value2)||
          '</tr>');
          wa('<tr><td class="lw">');
          captured_binds(s_pln_rec1);
          wa('</td><td class="lw">');
          captured_binds(s_pln_rec2);
          wa('</td></tr>');
          wa('</table>');
        END;

        -- optimizer_environment
        BEGIN
          wa(h3(mot('Optimizer Environment', 'GV$SQL_OPTIMIZER_ENV'), p_hr => FALSE));
          wa('<table><tr>'||
          th(s_sql_rec1.statid||NBSP2||l_plan_hash_value1||NBSP2||s_pln_rec1.sqlt_plan_hash_value||NBSP2||s_pln_rec1.sqlt_plan_hash_value2)||
          th(s_sql_rec2.statid||NBSP2||l_plan_hash_value2||NBSP2||s_pln_rec2.sqlt_plan_hash_value||NBSP2||s_pln_rec2.sqlt_plan_hash_value2)||
          '</tr>');
          wa('<tr><td class="lw">');
          optimizer_environment(s_pln_rec1);
          wa('</td><td class="lw">');
          optimizer_environment(s_pln_rec2);
          wa('</td></tr>');
          wa('</table>');
        END;

        -- plan summary
        DECLARE
          v_pln_rec1 sqlt$_plan_summary_v2%ROWTYPE;
          v_pln_rec2 sqlt$_plan_summary_v2%ROWTYPE;
        BEGIN
          -- read plan summary
          BEGIN
            SELECT *
              INTO v_pln_rec1
              FROM sqlt$_plan_summary_v2
             WHERE statement_id = p_statement_id1
               AND plan_hash_value = l_plan_hash_value1
               AND ROWNUM = 1;
          EXCEPTION
            WHEN OTHERS THEN
              write_error('plan_summary1: '||SQLERRM);
              v_pln_rec1 := NULL;
          END;

          -- read plan summary
          BEGIN
            SELECT *
              INTO v_pln_rec2
              FROM sqlt$_plan_summary_v2
             WHERE statement_id = p_statement_id2
               AND plan_hash_value = l_plan_hash_value2
               AND ROWNUM = 1;
          EXCEPTION
            WHEN OTHERS THEN
              write_error('plan_summary2: '||SQLERRM);
              v_pln_rec2:= NULL;
          END;

          wa(h3(mot('Plan Summary', 'GV$SQLAREA_PLAN_HASH, DBA_HIST_SQLSTAT, EXPLAIN PLAN FOR and DBA_SQLTUNE_PLANS'), p_hr => FALSE));
          wa('<table><tr>'||th('Name')||
          th(s_sql_rec1.statid)||
          th(s_sql_rec2.statid)||
          '</tr>');

          wrc('Plan Hash Value',
          l_plan_hash_value1,
          l_plan_hash_value2);

          wrc('SQLT PHV',
          s_pln_rec1.sqlt_plan_hash_value,
          s_pln_rec2.sqlt_plan_hash_value);

          wrc('SQLT PHV2',
          s_pln_rec1.sqlt_plan_hash_value2,
          s_pln_rec2.sqlt_plan_hash_value2);

          wrn('Avg Elapsed Time in secs',
          v_pln_rec1.elapsed_time_secs,
          v_pln_rec2.elapsed_time_secs);

          wrn('Avg CPU Time in secs',
          v_pln_rec1.cpu_time_secs,
          v_pln_rec2.cpu_time_secs);

          wrn('Avg User I/O Wait Time in secs',
          v_pln_rec1.user_io_wait_time_secs,
          v_pln_rec2.user_io_wait_time_secs);

          wrn('Avg Buffer Gets',
          v_pln_rec1.buffer_gets,
          v_pln_rec2.buffer_gets);

          wrn('Avg Disk Reads',
          v_pln_rec1.disk_reads,
          v_pln_rec2.disk_reads);

          wrn('Avg Direct Writes',
          v_pln_rec1.direct_writes,
          v_pln_rec2.direct_writes);

          wrn('Avg Rows Processed',
          v_pln_rec1.rows_processed,
          v_pln_rec2.rows_processed);

          wrn('Total Executions',
          v_pln_rec1.executions,
          v_pln_rec2.executions);

          wrn('Total Fetches',
          v_pln_rec1.fetches,
          v_pln_rec2.fetches);

          wrn('Total Version Count',
          v_pln_rec1.version_count,
          v_pln_rec2.version_count);

          wrn('Total Loads',
          v_pln_rec1.loads,
          v_pln_rec2.loads);

          wrn('Total Invalidations',
          v_pln_rec1.invalidations,
          v_pln_rec2.invalidations);

          wrc('Is Bind Sensitive',
          v_pln_rec1.is_bind_sensitive,
          v_pln_rec2.is_bind_sensitive);

          wrn('Min Optimizer Env',
          v_pln_rec1.min_optimizer_env_hash_value,
          v_pln_rec2.min_optimizer_env_hash_value);

          wrn('Max Optimizer Env',
          v_pln_rec1.max_optimizer_env_hash_value,
          v_pln_rec2.max_optimizer_env_hash_value);

          wrn('Optimizer Cost',
          v_pln_rec1.optimizer_cost,
          v_pln_rec2.optimizer_cost);

          wrn('Estimated Cardinality',
          v_pln_rec1.cardinality,
          v_pln_rec2.cardinality);

          wrn('Estimated Time in secs',
          v_pln_rec1.estimated_time_secs,
          v_pln_rec2.estimated_time_secs);

          wrc('Plan Timestamp',
          TO_CHAR(v_pln_rec1.plan_timestamp, LOAD_DATE_FORMAT),
          TO_CHAR(v_pln_rec2.plan_timestamp, LOAD_DATE_FORMAT));

          wrc('First Load Time',
          TO_CHAR(v_pln_rec1.first_load_time, LOAD_DATE_FORMAT),
          TO_CHAR(v_pln_rec2.first_load_time, LOAD_DATE_FORMAT));

          wrc('Last Load Time',
          TO_CHAR(v_pln_rec1.last_load_time, LOAD_DATE_FORMAT),
          TO_CHAR(v_pln_rec2.last_load_time, LOAD_DATE_FORMAT));

          wrc('Src',
          v_pln_rec1.src,
          v_pln_rec2.src);

          wrc('Source',
          v_pln_rec1.source,
          v_pln_rec2.source);

          wa('</table>');
        END;

        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.plan:'||SQLERRM);
    END;

    /* -------------------------
     * Tables
     * ------------------------- */
    BEGIN
      write_log('-> tables');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('Tables', 'tables'));
        wa('<table>');

        l_row_count := 0;
        FOR i IN (SELECT s1.table_name,
                         s1.owner s1_owner,
                         s1.num_rows s1_num_rows,
                         s1.sample_size s1_sample_size,
                         CASE WHEN s1.num_rows > 0 THEN TO_CHAR(ROUND(s1.sample_size * 100 / s1.num_rows, 1), PERCENT_FORMAT) END s1_percent,
                         s1.last_analyzed s1_last_analyzed,
                         s1.blocks s1_blocks,
                         s1.avg_row_len s1_avg_row_len,
                         s1.global_stats s1_global_stats,
                         s1.user_stats s1_user_stats,
                         s2.owner s2_owner,
                         s2.num_rows s2_num_rows,
                         s2.sample_size s2_sample_size,
                         CASE WHEN s2.num_rows > 0 THEN TO_CHAR(ROUND(s2.sample_size * 100 / s2.num_rows, 1), PERCENT_FORMAT) END s2_percent,
                         s2.last_analyzed s2_last_analyzed,
                         s2.blocks s2_blocks,
                         s2.avg_row_len s2_avg_row_len,
                         s2.global_stats s2_global_stats,
                         s2.user_stats s2_user_stats
                    FROM sqlt$_dba_tab_statistics_v s1,
                         sqlt$_dba_tab_statistics_v s2
                   WHERE s1.statid = s_sql_rec1.statid
                     AND s1.object_type = 'TABLE'
                     AND s_sql_rec2.statid = s2.statid(+)
                     AND 'TABLE' = s2.object_type(+)
                     AND s1.table_name = s2.table_name(+)
                   UNION
                  SELECT s2.table_name,
                         s1.owner s1_owner,
                         s1.num_rows s1_num_rows,
                         s1.sample_size s1_sample_size,
                         CASE WHEN s1.num_rows > 0 THEN TO_CHAR(ROUND(s1.sample_size * 100 / s1.num_rows, 1), PERCENT_FORMAT) END s1_percent,
                         s1.last_analyzed s1_last_analyzed,
                         s1.blocks s1_blocks,
                         s1.avg_row_len s1_avg_row_len,
                         s1.global_stats s1_global_stats,
                         s1.user_stats s1_user_stats,
                         s2.owner s2_owner,
                         s2.num_rows s2_num_rows,
                         s2.sample_size s2_sample_size,
                         CASE WHEN s2.num_rows > 0 THEN TO_CHAR(ROUND(s2.sample_size * 100 / s2.num_rows, 1), PERCENT_FORMAT) END s2_percent,
                         s2.last_analyzed s2_last_analyzed,
                         s2.blocks s2_blocks,
                         s2.avg_row_len s2_avg_row_len,
                         s2.global_stats s2_global_stats,
                         s2.user_stats s2_user_stats
                    FROM sqlt$_dba_tab_statistics_v s1,
                         sqlt$_dba_tab_statistics_v s2
                   WHERE s2.statid = s_sql_rec2.statid
                     AND s2.object_type = 'TABLE'
                     AND s_sql_rec1.statid = s1.statid(+)
                     AND 'TABLE' = s1.object_type(+)
                     AND s2.table_name = s1.table_name(+)
                   ORDER BY
                         table_name)
        LOOP
          l_row_count := l_row_count + 1;

         IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
            wa('<tr>');
            wa(th('Table Name'));
            wa(th('ID'));
            wa(th('Owner'));
            wa(th('Num Rows'));
            wa(th('Sample Size'));
            wa(th(mot('Perc', 'Percent (%)')));
            wa(th('Last Analyzed'));
            wa(th('Blocks'));
            wa(th('Avg Row Len'));
            wa(th('Global Stats'));
            wa(th('User Stats'));
            wa('</tr>');
          END IF;

          wa('<tr>');
          wa(td(i.table_name, 'ltm'));
          wa(td_2c(s_sql_rec1.statid, s_sql_rec2.statid, p_color => FALSE));
          wa(td_2c(i.s1_owner, i.s2_owner));
          wa(td_2n(i.s1_num_rows, i.s2_num_rows));
          wa(td_2n(i.s1_sample_size, i.s2_sample_size));
          wa(td_2n(i.s1_percent, i.s2_percent));
          wa(td_2c(TO_CHAR(i.s1_last_analyzed, LOAD_DATE_FORMAT), TO_CHAR(i.s2_last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap', FALSE));
          wa(td_2n(i.s1_blocks, i.s2_blocks));
          wa(td_2n(i.s1_avg_row_len, i.s2_avg_row_len));
          wa(td_2c(i.s1_global_stats, i.s2_global_stats, 'c'));
          wa(td_2c(i.s1_user_stats, i.s2_user_stats, 'c'));
          wa('</tr>');
        END LOOP;

        wa('</table>');
        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.tables:'||SQLERRM);
    END;

    /* -------------------------
     * Table Partitions
     * ------------------------- */
    BEGIN
      write_log('-> table_partitions');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('Table Partitions', 'tab_part'));

        FOR i IN (SELECT DISTINCT table_name
                    FROM sqlt$_dba_tab_statistics_v
                   WHERE statid IN (s_sql_rec1.statid, s_sql_rec2.statid)
                     AND object_type = 'PARTITION'
                   ORDER BY
                         table_name)
        LOOP
          wa(h3(i.table_name||' - Table Partitions', NULL, FALSE));
          wa('<table>');
          wa('List is restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');

          l_row_count := 0;
          FOR j IN (SELECT s1.partition_name,
                           s1.owner s1_owner,
                           s1.num_rows s1_num_rows,
                           s1.sample_size s1_sample_size,
                           CASE WHEN s1.num_rows > 0 THEN TO_CHAR(ROUND(s1.sample_size * 100 / s1.num_rows, 1), PERCENT_FORMAT) END s1_percent,
                           s1.last_analyzed s1_last_analyzed,
                           s1.blocks s1_blocks,
                           s1.avg_row_len s1_avg_row_len,
                           s1.global_stats s1_global_stats,
                           s1.user_stats s1_user_stats,
                           s2.owner s2_owner,
                           s2.num_rows s2_num_rows,
                           s2.sample_size s2_sample_size,
                           CASE WHEN s2.num_rows > 0 THEN TO_CHAR(ROUND(s2.sample_size * 100 / s2.num_rows, 1), PERCENT_FORMAT) END s2_percent,
                           s2.last_analyzed s2_last_analyzed,
                           s2.blocks s2_blocks,
                           s2.avg_row_len s2_avg_row_len,
                           s2.global_stats s2_global_stats,
                           s2.user_stats s2_user_stats
                      FROM sqlt$_dba_tab_statistics_v s1,
                           sqlt$_dba_tab_statistics_v s2
                     WHERE s1.statid = s_sql_rec1.statid
                       AND s1.object_type = 'PARTITION'
                       AND s1.table_name = i.table_name
                       AND s_sql_rec2.statid = s2.statid(+)
                       AND 'PARTITION' = s2.object_type(+)
                       AND i.table_name = s2.table_name(+)
                       AND s1.partition_name = s2.partition_name(+)
                     UNION
                    SELECT s2.partition_name,
                           s1.owner s1_owner,
                           s1.num_rows s1_num_rows,
                           s1.sample_size s1_sample_size,
                           CASE WHEN s1.num_rows > 0 THEN TO_CHAR(ROUND(s1.sample_size * 100 / s1.num_rows, 1), PERCENT_FORMAT) END s1_percent,
                           s1.last_analyzed s1_last_analyzed,
                           s1.blocks s1_blocks,
                           s1.avg_row_len s1_avg_row_len,
                           s1.global_stats s1_global_stats,
                           s1.user_stats s1_user_stats,
                           s2.owner s2_owner,
                           s2.num_rows s2_num_rows,
                           s2.sample_size s2_sample_size,
                           CASE WHEN s2.num_rows > 0 THEN TO_CHAR(ROUND(s2.sample_size * 100 / s2.num_rows, 1), PERCENT_FORMAT) END s2_percent,
                           s2.last_analyzed s2_last_analyzed,
                           s2.blocks s2_blocks,
                           s2.avg_row_len s2_avg_row_len,
                           s2.global_stats s2_global_stats,
                           s2.user_stats s2_user_stats
                      FROM sqlt$_dba_tab_statistics_v s1,
                           sqlt$_dba_tab_statistics_v s2
                     WHERE s2.statid = s_sql_rec2.statid
                       AND s2.object_type = 'PARTITION'
                       AND s2.table_name = i.table_name
                       AND s_sql_rec1.statid = s1.statid(+)
                       AND 'PARTITION' = s1.object_type(+)
                       AND i.table_name = s1.table_name(+)
                       AND s2.partition_name = s1.partition_name(+)
                     ORDER BY
                           partition_name DESC)
          LOOP
            l_row_count := l_row_count + 1;

           IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
              wa('<tr>');
              wa(th('Partition Name'));
              wa(th('ID'));
              wa(th('Owner'));
              wa(th('Num Rows'));
              wa(th('Sample Size'));
              wa(th(mot('Perc', 'Percent (%)')));
              wa(th('Last Analyzed'));
              wa(th('Blocks'));
              wa(th('Avg Row Len'));
              wa(th('Global Stats'));
              wa(th('User Stats'));
              wa('</tr>');
            END IF;

            wa('<tr>');
            wa(td(j.partition_name, 'ltm'));
            wa(td_2c(s_sql_rec1.statid, s_sql_rec2.statid, p_color => FALSE));
            wa(td_2c(j.s1_owner, j.s2_owner));
            wa(td_2n(j.s1_num_rows, j.s2_num_rows));
            wa(td_2n(j.s1_sample_size, j.s2_sample_size));
            wa(td_2n(j.s1_percent, j.s2_percent));
            wa(td_2c(TO_CHAR(j.s1_last_analyzed, LOAD_DATE_FORMAT), TO_CHAR(j.s2_last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap', FALSE));
            wa(td_2n(j.s1_blocks, j.s2_blocks));
            wa(td_2n(j.s1_avg_row_len, j.s2_avg_row_len));
            wa(td_2c(j.s1_global_stats, j.s2_global_stats, 'c'));
            wa(td_2c(j.s1_user_stats, j.s2_user_stats, 'c'));
            wa('</tr>');

            IF l_row_count = s_rows_table_l THEN
              EXIT;
            END IF;
          END LOOP;

          wa('</table>');
        END LOOP;

        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.tab_part:'||SQLERRM);
    END;

    /* -------------------------
     * Indexes
     * ------------------------- */
    BEGIN
      write_log('-> indexes');
      IF p_statement_id1 <> p_statement_id2 THEN
        FOR i IN (SELECT statid,
                         c5 index_owner,
                         c1 index_name
                    FROM sqlt$_stattab
                   WHERE type = 'I'
                     AND statid IN (s_sql_rec1.statid, s_sql_rec2.statid)
                     AND c2 IS NULL)
        LOOP
          sqlt$a.set_index_column_names (
            p_statement_id => TO_NUMBER(SUBSTR(i.statid, 2, INSTR(i.statid, CHR(95)) - 2)),
            p_index_owner  => i.index_owner,
            p_index_name   => i.index_name,
            p_hidden_names => 'YES',
            p_separator    =>  ', ',
            p_table_name   => 'YES' );
        END LOOP;

        wa(h2('Indexes', 'indexes'));
        wa('<table>');

        l_row_count := 0;
        FOR i IN (SELECT s1.compare_key,
                         s1.index_name s1_index_name,
                         s1.owner s1_owner,
                         s1.num_rows s1_num_rows,
                         s1.sample_size s1_sample_size,
                         CASE WHEN s1.num_rows > 0 THEN TO_CHAR(ROUND(s1.sample_size * 100 / s1.num_rows, 1), PERCENT_FORMAT) END s1_percent,
                         s1.last_analyzed s1_last_analyzed,
                         s1.distinct_keys s1_distinct_keys,
                         s1.blevel s1_blevel,
                         s1.leaf_blocks s1_leaf_blocks,
                         s1.avg_leaf_blocks_per_key s1_avg_leaf_blocks_per_key,
                         s1.avg_data_blocks_per_key s1_avg_data_blocks_per_key,
                         s1.clustering_factor s1_clustering_factor,
                         s1.global_stats s1_global_stats,
                         s1.user_stats s1_user_stats,
                         s2.index_name s2_index_name,
                         s2.owner s2_owner,
                         s2.num_rows s2_num_rows,
                         s2.sample_size s2_sample_size,
                         CASE WHEN s2.num_rows > 0 THEN TO_CHAR(ROUND(s2.sample_size * 100 / s2.num_rows, 1), PERCENT_FORMAT) END s2_percent,
                         s2.last_analyzed s2_last_analyzed,
                         s2.distinct_keys s2_distinct_keys,
                         s2.blevel s2_blevel,
                         s2.leaf_blocks s2_leaf_blocks,
                         s2.avg_leaf_blocks_per_key s2_avg_leaf_blocks_per_key,
                         s2.avg_data_blocks_per_key s2_avg_data_blocks_per_key,
                         s2.clustering_factor s2_clustering_factor,
                         s2.global_stats s2_global_stats,
                         s2.user_stats s2_user_stats
                    FROM sqlt$_dba_ind_statistics_v s1,
                         sqlt$_dba_ind_statistics_v s2
                   WHERE s1.statid = s_sql_rec1.statid
                     AND s1.object_type = 'INDEX'
                     AND s_sql_rec2.statid = s2.statid(+)
                     AND 'INDEX' = s2.object_type(+)
                     AND s1.compare_key = s2.compare_key(+)
                   UNION
                  SELECT s2.compare_key,
                         s1.index_name s1_index_name,
                         s1.owner s1_owner,
                         s1.num_rows s1_num_rows,
                         s1.sample_size s1_sample_size,
                         CASE WHEN s1.num_rows > 0 THEN TO_CHAR(ROUND(s1.sample_size * 100 / s1.num_rows, 1), PERCENT_FORMAT) END s1_percent,
                         s1.last_analyzed s1_last_analyzed,
                         s1.distinct_keys s1_distinct_keys,
                         s1.blevel s1_blevel,
                         s1.leaf_blocks s1_leaf_blocks,
                         s1.avg_leaf_blocks_per_key s1_avg_leaf_blocks_per_key,
                         s1.avg_data_blocks_per_key s1_avg_data_blocks_per_key,
                         s1.clustering_factor s1_clustering_factor,
                         s1.global_stats s1_global_stats,
                         s1.user_stats s1_user_stats,
                         s2.index_name s2_index_name,
                         s2.owner s2_owner,
                         s2.num_rows s2_num_rows,
                         s2.sample_size s2_sample_size,
                         CASE WHEN s2.num_rows > 0 THEN TO_CHAR(ROUND(s2.sample_size * 100 / s2.num_rows, 1), PERCENT_FORMAT) END s2_percent,
                         s2.last_analyzed s2_last_analyzed,
                         s2.distinct_keys s2_distinct_keys,
                         s2.blevel s2_blevel,
                         s2.leaf_blocks s2_leaf_blocks,
                         s2.avg_leaf_blocks_per_key s2_avg_leaf_blocks_per_key,
                         s2.avg_data_blocks_per_key s2_avg_data_blocks_per_key,
                         s2.clustering_factor s2_clustering_factor,
                         s2.global_stats s2_global_stats,
                         s2.user_stats s2_user_stats
                    FROM sqlt$_dba_ind_statistics_v s1,
                         sqlt$_dba_ind_statistics_v s2
                   WHERE s2.statid = s_sql_rec2.statid
                     AND s2.object_type = 'INDEX'
                     AND s_sql_rec1.statid = s1.statid(+)
                     AND 'INDEX' = s1.object_type(+)
                     AND s2.compare_key = s1.compare_key(+)
                   ORDER BY
                         compare_key)
        LOOP
          l_row_count := l_row_count + 1;

         IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
            wa('<tr>');
            wa(th('Table Name<sup>1</sup><br>(Indexed Columns)'));
            wa(th('ID'));
            wa(th('Index Name'));
            wa(th('Owner'));
            wa(th('Num Rows'));
            wa(th('Sample Size'));
            wa(th(mot('Perc', 'Percent (%)')));
            wa(th('Last Analyzed'));
            wa(th('Distinct Keys'));
            wa(th('Blevel'));
            wa(th('Leaf Blocks'));
            wa(th('Avg Leaf Blocks per Key'));
            wa(th('Avg Data Blocks per Key'));
            wa(th('Clustering Factor'));
            wa(th('Global Stats'));
            wa(th('User Stats'));
            wa('</tr>');
          END IF;

          wa('<tr>');
          wa(td(REPLACE(i.compare_key, ' (', '<br>('), 'ltm', 'nowrap'));
          wa(td_2c(s_sql_rec1.statid, s_sql_rec2.statid, p_color => FALSE));
          wa(td_2c(i.s1_index_name, i.s2_index_name));
          wa(td_2c(i.s1_owner, i.s2_owner));
          wa(td_2n(i.s1_num_rows, i.s2_num_rows));
          wa(td_2n(i.s1_sample_size, i.s2_sample_size));
          wa(td_2n(i.s1_percent, i.s2_percent));
          wa(td_2c(TO_CHAR(i.s1_last_analyzed, LOAD_DATE_FORMAT), TO_CHAR(i.s2_last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap', FALSE));
          wa(td_2n(i.s1_distinct_keys, i.s2_distinct_keys));
          wa(td_2n(i.s1_blevel, i.s2_blevel));
          wa(td_2n(i.s1_leaf_blocks, i.s2_leaf_blocks));
          wa(td_2n(i.s1_avg_leaf_blocks_per_key, i.s2_avg_leaf_blocks_per_key));
          wa(td_2n(i.s1_avg_data_blocks_per_key, i.s2_avg_data_blocks_per_key));
          wa(td_2n(i.s1_clustering_factor, i.s2_clustering_factor));
          wa(td_2c(i.s1_global_stats, i.s2_global_stats, 'c'));
          wa(td_2c(i.s1_user_stats, i.s2_user_stats, 'c'));
          wa('</tr>');
        END LOOP;

        wa('</table>');
        wa(font('(1) Indexes are matched by their Table and Column names instead of Index name.'));
        wa('<br>');
        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.indexes:'||SQLERRM);
    END;

    /* -------------------------
     * Index Partitions
     * ------------------------- */
    BEGIN
      write_log('-> index_partitions');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('Index Partitions', 'idx_part'));

        FOR i IN (SELECT DISTINCT compare_key
                    FROM sqlt$_dba_ind_statistics_v
                   WHERE statid IN (s_sql_rec1.statid, s_sql_rec2.statid)
                     AND object_type = 'PARTITION'
                   ORDER BY
                         compare_key)
        LOOP
          wa(h3(i.compare_key||' - Index Partitions', NULL, FALSE));
          wa('<table>');
          wa('List is restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');

          l_row_count := 0;
          FOR j IN (SELECT s1.partition_name,
                           s1.index_name s1_index_name,
                           s1.owner s1_owner,
                           s1.num_rows s1_num_rows,
                           s1.sample_size s1_sample_size,
                           CASE WHEN s1.num_rows > 0 THEN TO_CHAR(ROUND(s1.sample_size * 100 / s1.num_rows, 1), PERCENT_FORMAT) END s1_percent,
                           s1.last_analyzed s1_last_analyzed,
                           s1.distinct_keys s1_distinct_keys,
                           s1.blevel s1_blevel,
                           s1.leaf_blocks s1_leaf_blocks,
                           s1.avg_leaf_blocks_per_key s1_avg_leaf_blocks_per_key,
                           s1.avg_data_blocks_per_key s1_avg_data_blocks_per_key,
                           s1.clustering_factor s1_clustering_factor,
                           s1.global_stats s1_global_stats,
                           s1.user_stats s1_user_stats,
                           s2.index_name s2_index_name,
                           s2.owner s2_owner,
                           s2.num_rows s2_num_rows,
                           s2.sample_size s2_sample_size,
                           CASE WHEN s2.num_rows > 0 THEN TO_CHAR(ROUND(s2.sample_size * 100 / s2.num_rows, 1), PERCENT_FORMAT) END s2_percent,
                           s2.last_analyzed s2_last_analyzed,
                           s2.distinct_keys s2_distinct_keys,
                           s2.blevel s2_blevel,
                           s2.leaf_blocks s2_leaf_blocks,
                           s2.avg_leaf_blocks_per_key s2_avg_leaf_blocks_per_key,
                           s2.avg_data_blocks_per_key s2_avg_data_blocks_per_key,
                           s2.clustering_factor s2_clustering_factor,
                           s2.global_stats s2_global_stats,
                           s2.user_stats s2_user_stats
                      FROM sqlt$_dba_ind_statistics_v s1,
                           sqlt$_dba_ind_statistics_v s2
                     WHERE s1.statid = s_sql_rec1.statid
                       AND s1.object_type = 'PARTITION'
                       AND s1.compare_key = i.compare_key
                       AND s_sql_rec2.statid = s2.statid(+)
                       AND 'PARTITION' = s2.object_type(+)
                       AND i.compare_key = s2.compare_key(+)
                       AND s1.partition_name = s2.partition_name(+)
                     UNION
                    SELECT s2.partition_name,
                           s1.index_name s1_index_name,
                           s1.owner s1_owner,
                           s1.num_rows s1_num_rows,
                           s1.sample_size s1_sample_size,
                           CASE WHEN s1.num_rows > 0 THEN TO_CHAR(ROUND(s1.sample_size * 100 / s1.num_rows, 1), PERCENT_FORMAT) END s1_percent,
                           s1.last_analyzed s1_last_analyzed,
                           s1.distinct_keys s1_distinct_keys,
                           s1.blevel s1_blevel,
                           s1.leaf_blocks s1_leaf_blocks,
                           s1.avg_leaf_blocks_per_key s1_avg_leaf_blocks_per_key,
                           s1.avg_data_blocks_per_key s1_avg_data_blocks_per_key,
                           s1.clustering_factor s1_clustering_factor,
                           s1.global_stats s1_global_stats,
                           s1.user_stats s1_user_stats,
                           s2.index_name s2_index_name,
                           s2.owner s2_owner,
                           s2.num_rows s2_num_rows,
                           s2.sample_size s2_sample_size,
                           CASE WHEN s2.num_rows > 0 THEN TO_CHAR(ROUND(s2.sample_size * 100 / s2.num_rows, 1), PERCENT_FORMAT) END s2_percent,
                           s2.last_analyzed s2_last_analyzed,
                           s2.distinct_keys s2_distinct_keys,
                           s2.blevel s2_blevel,
                           s2.leaf_blocks s2_leaf_blocks,
                           s2.avg_leaf_blocks_per_key s2_avg_leaf_blocks_per_key,
                           s2.avg_data_blocks_per_key s2_avg_data_blocks_per_key,
                           s2.clustering_factor s2_clustering_factor,
                           s2.global_stats s2_global_stats,
                           s2.user_stats s2_user_stats
                      FROM sqlt$_dba_ind_statistics_v s1,
                           sqlt$_dba_ind_statistics_v s2
                     WHERE s2.statid = s_sql_rec2.statid
                       AND s2.object_type = 'PARTITION'
                       AND s2.compare_key = i.compare_key
                       AND s_sql_rec1.statid = s1.statid(+)
                       AND 'PARTITION' = s1.object_type(+)
                       AND i.compare_key = s1.compare_key(+)
                       AND s2.partition_name = s1.partition_name(+)
                     ORDER BY
                           partition_name DESC)
          LOOP
            l_row_count := l_row_count + 1;

           IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
              wa('<tr>');
              wa(th('Partition Name'));
              wa(th('ID'));
              wa(th('Index Name'));
              wa(th('Owner'));
              wa(th('Num Rows'));
              wa(th('Sample Size'));
              wa(th(mot('Perc', 'Percent (%)')));
              wa(th('Last Analyzed'));
              wa(th('Distinct Keys'));
              wa(th('Blevel'));
              wa(th('Leaf Blocks'));
              wa(th('Avg Leaf Blocks per Key'));
              wa(th('Avg Data Blocks per Key'));
              wa(th('Clustering Factor'));
              wa(th('Global Stats'));
              wa(th('User Stats'));
              wa('</tr>');
            END IF;

            wa('<tr>');
            wa(td(j.partition_name, 'ltm'));
            wa(td_2c(s_sql_rec1.statid, s_sql_rec2.statid, p_color => FALSE));
            wa(td_2c(j.s1_index_name, j.s2_index_name));
            wa(td_2c(j.s1_owner, j.s2_owner));
            wa(td_2n(j.s1_num_rows, j.s2_num_rows));
            wa(td_2n(j.s1_sample_size, j.s2_sample_size));
            wa(td_2n(j.s1_percent, j.s2_percent));
            wa(td_2c(TO_CHAR(j.s1_last_analyzed, LOAD_DATE_FORMAT), TO_CHAR(j.s2_last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap', FALSE));
            wa(td_2n(j.s1_distinct_keys, j.s2_distinct_keys));
            wa(td_2n(j.s1_blevel, j.s2_blevel));
            wa(td_2n(j.s1_leaf_blocks, j.s2_leaf_blocks));
            wa(td_2n(j.s1_avg_leaf_blocks_per_key, j.s2_avg_leaf_blocks_per_key));
            wa(td_2n(j.s1_avg_data_blocks_per_key, j.s2_avg_data_blocks_per_key));
            wa(td_2n(j.s1_clustering_factor, j.s2_clustering_factor));
            wa(td_2c(j.s1_global_stats, j.s2_global_stats, 'c'));
            wa(td_2c(j.s1_user_stats, j.s2_user_stats, 'c'));
            wa('</tr>');

            IF l_row_count = s_rows_table_l THEN
              EXIT;
            END IF;
          END LOOP;

          wa('</table>');
        END LOOP;

        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.idx_part:'||SQLERRM);
    END;

    /* -------------------------
     * Columns
     * ------------------------- */
    BEGIN
      write_log('-> columns');
      IF p_statement_id1 <> p_statement_id2 THEN
        wa(h2('Columns', 'columns'));

        FOR i IN (SELECT DISTINCT table_name
                    FROM sqlt$_dba_tab_col_statistics_v
                   WHERE statid IN (s_sql_rec1.statid, s_sql_rec2.statid)
                     AND object_type = 'TABLE'
                   ORDER BY
                         table_name)
        LOOP
          wa(h3(i.table_name||' - Columns', NULL, FALSE));
          wa('<table>');

          l_row_count := 0;
          FOR j IN (SELECT CASE WHEN NVL(s1.virtual_column,'NO') = 'YES' THEN s1.data_default ELSE s1.column_name END column_name,
                           s1.owner s1_owner,
                           s1.num_rows s1_num_rows,
                           s1.num_nulls s1_num_nulls,
                           s1.sample_size s1_sample_size,
                           CASE
                           WHEN s1.num_rows > s1.num_nulls THEN TO_CHAR(LEAST(100, ROUND(s1.sample_size * 100 / (s1.num_rows - s1.num_nulls), 1)), PERCENT_FORMAT)
                           WHEN s1.num_rows = s1.num_nulls THEN TO_CHAR(100, PERCENT_FORMAT)
                           END s1_percent,
                           s1.num_distinct s1_num_distinct,
                           s1.external_low_value s1_low_value,
                           s1.external_high_value s1_high_value,
                           s1.low_value_from_raw s1_low_value_from_raw,
                           s1.high_value_from_raw s1_high_value_from_raw,
                           s1.last_analyzed s1_last_analyzed,
                           s1.avg_col_len s1_avg_col_len,
                           s1.density s1_density,
                           s1.histogram s1_histogram,
                           s1.endpoints_count s1_endpoints_count,
                           s1.global_stats s1_global_stats,
                           s1.user_stats s1_user_stats,
                           s2.owner s2_owner,
                           s2.num_rows s2_num_rows,
                           s2.num_nulls s2_num_nulls,
                           s2.sample_size s2_sample_size,
                           CASE
                           WHEN s2.num_rows > s2.num_nulls THEN TO_CHAR(LEAST(100, ROUND(s2.sample_size * 100 / (s2.num_rows - s2.num_nulls), 1)), PERCENT_FORMAT)
                           WHEN s2.num_rows = s2.num_nulls THEN TO_CHAR(100, PERCENT_FORMAT)
                           END s2_percent,
                           s2.num_distinct s2_num_distinct,
                           s2.external_low_value s2_low_value,
                           s2.external_high_value s2_high_value,
                           s2.low_value_from_raw s2_low_value_from_raw,
                           s2.high_value_from_raw s2_high_value_from_raw,
                           s2.last_analyzed s2_last_analyzed,
                           s2.avg_col_len s2_avg_col_len,
                           s2.density s2_density,
                           s2.histogram s2_histogram,
                           s2.endpoints_count s2_endpoints_count,
                           s2.global_stats s2_global_stats,
                           s2.user_stats s2_user_stats
                      FROM sqlt$_dba_tab_col_statistics_v s1,
                           sqlt$_dba_tab_col_statistics_v s2
                     WHERE s1.statid = s_sql_rec1.statid
                       AND s1.object_type = 'TABLE'
                       AND s1.table_name = i.table_name
                       AND s_sql_rec2.statid = s2.statid(+)
                       AND 'TABLE' = s2.object_type(+)
                       AND i.table_name = s2.table_name(+)
                       AND s1.column_name = s2.column_name(+)
					   AND s1.type = 'C'
					   AND 'C' = s2.type(+) 
                     UNION
                    SELECT CASE WHEN NVL(s2.virtual_column,'NO') = 'YES' THEN s2.data_default ELSE s2.column_name END column_name,
                           s1.owner s1_owner,
                           s1.num_rows s1_num_rows,
                           s1.num_nulls s1_num_nulls,
                           s1.sample_size s1_sample_size,
                           CASE
                           WHEN s1.num_rows > s1.num_nulls THEN TO_CHAR(LEAST(100, ROUND(s1.sample_size * 100 / (s1.num_rows - s1.num_nulls), 1)), PERCENT_FORMAT)
                           WHEN s1.num_rows = s1.num_nulls THEN TO_CHAR(100, PERCENT_FORMAT)
                           END s1_percent,
                           s1.num_distinct s1_num_distinct,
                           s1.external_low_value s1_low_value,
                           s1.external_high_value s1_high_value,
                           s1.low_value_from_raw s1_low_value_from_raw,
                           s1.high_value_from_raw s1_high_value_from_raw,
                           s1.last_analyzed s1_last_analyzed,
                           s1.avg_col_len s1_avg_col_len,
                           s1.density s1_density,
                           s1.histogram s1_histogram,
                           s1.endpoints_count s1_endpoints_count,
                           s1.global_stats s1_global_stats,
                           s1.user_stats s1_user_stats,
                           s2.owner s2_owner,
                           s2.num_rows s2_num_rows,
                           s2.num_nulls s2_num_nulls,
                           s2.sample_size s2_sample_size,
                           CASE
                           WHEN s2.num_rows > s2.num_nulls THEN TO_CHAR(LEAST(100, ROUND(s2.sample_size * 100 / (s2.num_rows - s2.num_nulls), 1)), PERCENT_FORMAT)
                           WHEN s2.num_rows = s2.num_nulls THEN TO_CHAR(100, PERCENT_FORMAT)
                           END s2_percent,
                           s2.num_distinct s2_num_distinct,
                           s2.external_low_value s2_low_value,
                           s2.external_high_value s2_high_value,
                           s2.low_value_from_raw s2_low_value_from_raw,
                           s2.high_value_from_raw s2_high_value_from_raw,
                           s2.last_analyzed s2_last_analyzed,
                           s2.avg_col_len s2_avg_col_len,
                           s2.density s2_density,
                           s2.histogram s2_histogram,
                           s2.endpoints_count s2_endpoints_count,
                           s2.global_stats s2_global_stats,
                           s2.user_stats s2_user_stats
                      FROM sqlt$_dba_tab_col_statistics_v s1,
                           sqlt$_dba_tab_col_statistics_v s2
                     WHERE s2.statid = s_sql_rec2.statid
                       AND s2.object_type = 'TABLE'
                       AND s2.table_name = i.table_name
                       AND s_sql_rec1.statid = s1.statid(+)
                       AND 'TABLE' = s1.object_type(+)
                       AND i.table_name = s1.table_name(+)
                       AND s2.column_name = s1.column_name(+)
					   AND s2.type = 'C'
					   AND 'C' = s1.type(+) 					   
                     ORDER BY
                           column_name)
          LOOP
            l_row_count := l_row_count + 1;

           IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
              wa('<tr>');
              wa(th('Column Name'));
              wa(th('ID'));
              wa(th('Owner'));
              wa(th('Num Rows'));
              wa(th('Num Nulls'));
              wa(th('Sample Size'));
              wa(th(mot('Perc', 'Percent (%)')));
              wa(th('Num Distinct'));
              wa(th('Low Value from Number'));
              wa(th('High Value from Number'));
              wa(th('Low Value from Raw'));
              wa(th('High Value from Raw'));
              wa(th('Last Analyzed'));
              wa(th('Avg Col Len'));
              wa(th('Density'));
              wa(th('Histogram'));
              wa(th('Endpoints Count'));
              wa(th('Global Stats'));
              wa(th('User Stats'));
              wa('</tr>');
            END IF;

            wa('<tr>');
            wa(td(j.column_name, 'ltm'));
            wa(td_2c(s_sql_rec1.statid, s_sql_rec2.statid, p_color => FALSE));
            wa(td_2c(j.s1_owner, j.s2_owner));
            wa(td_2n(j.s1_num_rows, j.s2_num_rows));
            wa(td_2n(j.s1_num_nulls, j.s2_num_nulls));
            wa(td_2n(j.s1_sample_size, j.s2_sample_size));
            wa(td_2n(j.s1_percent, j.s2_percent));
            wa(td_2n(j.s1_num_distinct, j.s2_num_distinct));
            wa(td_2c('"'||sqlt$r.sanitize_html_clob(j.s1_low_value)||'"', '"'||sqlt$r.sanitize_html_clob(j.s2_low_value)||'"', 'l', 'nowrap'));
            wa(td_2c('"'||sqlt$r.sanitize_html_clob(j.s1_high_value)||'"', '"'||sqlt$r.sanitize_html_clob(j.s2_high_value)||'"', 'l', 'nowrap'));
            wa(td_2c('"'||sqlt$r.sanitize_html_clob(j.s1_low_value_from_raw)||'"', '"'||sqlt$r.sanitize_html_clob(j.s2_low_value_from_raw)||'"', 'l', 'nowrap'));
            wa(td_2c('"'||sqlt$r.sanitize_html_clob(j.s1_high_value_from_raw)||'"', '"'||sqlt$r.sanitize_html_clob(j.s2_high_value_from_raw)||'"', 'l', 'nowrap'));
            wa(td_2c(TO_CHAR(j.s1_last_analyzed, LOAD_DATE_FORMAT), TO_CHAR(j.s2_last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap', FALSE));
            wa(td_2n(j.s1_avg_col_len, j.s2_avg_col_len));
            wa(td_2n(LOWER(TO_CHAR(j.s1_density, SCIENTIFIC_NOTATION)), LOWER(TO_CHAR(j.s2_density, SCIENTIFIC_NOTATION)), 'r', 'nowrap'));
            wa(td_2c(j.s1_histogram, j.s2_histogram, 'c'));
            wa(td_2n(j.s1_endpoints_count, j.s2_endpoints_count));
            wa(td_2c(j.s1_global_stats, j.s2_global_stats, 'c'));
            wa(td_2c(j.s1_user_stats, j.s2_user_stats, 'c'));
            wa('</tr>');
          END LOOP;

          wa('</table>');
        END LOOP;

        wa(go_to_top);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.columns:'||SQLERRM);
    END;

    /* -------------------------
     * Footer and closure
     * ------------------------- */
    BEGIN
      write_log('-> footer_and_closure');
      wa('
<hr size="3">
<font class="f">'||NOTE_NUMBER||' '||s_file_rec.filename||' '||TO_CHAR(SYSDATE, LOAD_DATE_FORMAT)||'</font>
</body>
</html>');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id  => p_statement_id1,
        p_file_type     => 'COMPARE_REPORT',
        p_filename      => s_file_rec.filename,
        p_statid        => s_sql_rec1.statid,
        p_statement_id2 => p_statement_id2,
        p_file_size     => s_file_rec.file_size,
        p_file_text     => s_file_rec.file_text );

      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('compare_report.close:'||SQLERRM);
    END;

    write_log('<= compare_report');
  END compare_report;

  /*************************************************************************************/

END sqlt$c;
/

SET TERM ON;
SHOW ERRORS PACKAGE BODY &&tool_administer_schema..sqlt$c;
