CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..sqlt$m AS
/* $Header: 215187.1 sqcpkgm.pkb 19.1.200129 2020/01/29 Stelios.Charalambides@oraclec.com carlos.sierra mauro.pagano abel.macias sachin.pawar $ */
/*                                                                                                      */
/* Added line 1441 to change mbrc to s_sql_rec.udb_file_optimizer_read_count to take into               */
/* account that synthesized values use _db_file_optimizer_read_count not db_file_multiblock_read_count  */
/* Changed the ordering of Observations to list them in Priority order not TYPE_ID then LINE_ID order   */ 

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  TOOL_NAME              CONSTANT VARCHAR2(32)  := '&&tool_name.';
  TOOL_REPOSITORY_SCHEMA CONSTANT VARCHAR2(32)  := '&&tool_repository_schema.';
  TOOL_ADMINISTER_SCHEMA CONSTANT VARCHAR2(32)  := '&&tool_administer_schema.';
  NOTE_NUMBER            CONSTANT VARCHAR2(32)  := '&&tool_note.';
  TOOL_DEVELOPER         CONSTANT VARCHAR2(32)  := 'stelios.charalambides';
  TOOL_DEVELOPER_EMAIL   CONSTANT VARCHAR2(32)  := 'stelios.charalambides@oracle.com';
  COPYRIGHT              CONSTANT VARCHAR2(128) := 'Copyright (c) 2000-2015, Oracle Corporation. All rights reserved.';
  TITLE_REPEAT_RATE      CONSTANT INTEGER       := 30;
  VERT_TITLE_REP_RATE    CONSTANT INTEGER       := 5;
  HEADING_DATE_FORMAT    CONSTANT VARCHAR2(32)  := 'YYYY/MM/DD';
  LOAD_DATE_FORMAT       CONSTANT VARCHAR2(32)  := 'YYYY-MM-DD/HH24:MI:SS'; -- 2010-03-03/08:45:04
  SHORT_DATE_FORMAT      CONSTANT VARCHAR2(32)  := 'DD-MON-YY';
  TIMESTAMP_TZ_FORMAT    CONSTANT VARCHAR2(64)  := 'YYYY-MM-DD/HH24:MI:SS.FF6 TZH:TZM';
  TIMESTAMP_FORMAT3      CONSTANT VARCHAR2(64)  := 'YYYY-MM-DD/HH24:MI:SS.FF3';
  TIMESTAMP_FORMAT6      CONSTANT VARCHAR2(64)  := 'YYYY-MM-DD/HH24:MI:SS.FF6';
  SCIENTIFIC_NOTATION    CONSTANT VARCHAR2(32)  := '0D000000EEEE';
  SMALL_SCIENT_NOT       CONSTANT VARCHAR2(32)  := '0D0EEEE';
  SELECTIVITY_FORMAT     CONSTANT VARCHAR2(32)  := '0D000000';
  NUMBER_FORMAT          CONSTANT VARCHAR2(32)  := '99999999999990D990';
  SECONDS_FORMAT         CONSTANT VARCHAR2(32)  := '99999999999990D990';
  SECONDS_FORMAT6        CONSTANT VARCHAR2(32)  := '99999999999990D999990';
  PERCENT_FORMAT         CONSTANT VARCHAR2(32)  := '99999990D0';
  LF                     CONSTANT CHAR(1)       := CHR(10);
  AMP                    CONSTANT CHAR(1)       := CHR(38);
  NBSP                   CONSTANT VARCHAR2(32)  := AMP||'nbsp;'; -- space
  NBSP2                  CONSTANT VARCHAR2(32)  := NBSP||NBSP; -- 2 spaces
  NBSP4                  CONSTANT VARCHAR2(32)  := NBSP2||NBSP2; -- 4 spaces
  QUOT                   CONSTANT VARCHAR2(32)  := AMP||'quot;'; -- "
  SQUOT                  CONSTANT VARCHAR2(32)  := AMP||'#39;'; -- '
  GT                     CONSTANT VARCHAR2(32)  := AMP||'gt;'; -- >
  LT                     CONSTANT VARCHAR2(32)  := AMP||'lt;'; -- <
  OPAR                   CONSTANT VARCHAR2(32)  := AMP||'#40;'; -- (
  CPAR                   CONSTANT VARCHAR2(32)  := AMP||'#41;'; -- )
  DVCENS                 CONSTANT VARCHAR2(32)  := '*****';
  MOS_URL                CONSTANT VARCHAR2(128) := 'https://support.oracle.com/CSP/main/article?cmd=show'||AMP||'type=';

  /*************************************************************************************/

  -- 171004 Extensive replacement of variables to varchar2(257)
  
  /* -------------------------
   *
   * static variables
   *
   * ------------------------- */
  s_sql_rec sqlt$_sql_statement%ROWTYPE;
  s_file_rec sqli$_file%ROWTYPE;
  s_snap_id INTEGER := 0;
  s_go_to CHAR(1) := 'Y';
  s_in_pred CHAR(1) := 'Y';
  s_sql_text CHAR(1) := 'Y';
  s_metadata CHAR(1) := 'Y';
  s_scaling_factor NUMBER := 1;
  s_gran_segm VARCHAR2(257);
  s_gran_cols VARCHAR2(257);
  s_gran_hgrm VARCHAR2(257);
  s_gran_vers VARCHAR2(128);
  s_mask_for_values VARCHAR2(128);
  s_plan_stats VARCHAR2(128);
  s_count_star_threshold VARCHAR2(128);
  s_rows_table_xs NUMBER;
  s_rows_table_s NUMBER;
  s_rows_table_m NUMBER;
  s_rows_table_l NUMBER;

  /*************************************************************************************/

  TYPE t_cache is table of varchar2(32767) index by binary_integer ;
  v_cache t_cache;
  v_directive t_cache;
  
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
    sqlt$a.write_log(p_line_text => p_line_text, p_line_type => p_line_type, p_package => 'M');
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
    sqlt$a.write_error('m:'||p_line_text);
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
   * 150828 add p_keyword
   * ------------------------- */
  FUNCTION th (
    p_text  IN VARCHAR2,
    p_class IN VARCHAR2 DEFAULT NULL ,
	p_keyword IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN '<th'||' '||p_keyword||tag(p_class)||'>'||p_text||'</th>';
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
   * private doc_id
   *
   * ------------------------- */
  FUNCTION doc_id (p_doc_id IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN '<a target="MOS" href="'||MOS_URL||'NOT'||AMP||'id='||p_doc_id||'">'||p_doc_id||'</a>';
  END doc_id;

  /*************************************************************************************/

  /* -------------------------
   *
   * private bug_number
   *
   * ------------------------- */
  FUNCTION bug_number (p_bug_number IN NUMBER)
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN '<a target="MOS" href="'||MOS_URL||'BUG'||AMP||'id='||p_bug_number||'">'||p_bug_number||'</a>';
  END bug_number;

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
    p_display IN VARCHAR2,
    p_close   IN VARCHAR2 DEFAULT '</span>' )
  RETURN VARCHAR2
  IS
  BEGIN
    s_snap_id := s_snap_id + 1;
    RETURN
    LF||'[<a href="javascript:void(0);" onclick="snh(''s'||s_snap_id||'c'', ''s'||s_snap_id||'t'');"><span id="s'||s_snap_id||'c">'||p_control||'</span></a>]'||
    LF||'<span id="s'||s_snap_id||'t" style="display:'||p_display||'">'||p_text||p_close;
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
    RETURN show_n_hide(p_text, '-', 'block');
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
    RETURN show_n_hide(p_text, '+', 'none');
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
    RETURN show_n_hide(NULL, '-', 'block', NULL);
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
    RETURN show_n_hide(NULL, '+', 'none', NULL);
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
  FUNCTION hide_sql (
    p_text  IN VARCHAR2,
    p_text2 IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_text2 IS NULL THEN
      RETURN 'SQL:'||hide(LF||'<pre>'||sqlt$r.sanitize_html_clob(TRIM(LF FROM p_text), FALSE)||'</pre>'||LF);
    ELSE
      RETURN 'SQL:'||hide(LF||'<table><tr><td class="lw">'||LF||
      '<pre>'||sqlt$r.sanitize_html_clob(TRIM(LF FROM p_text), FALSE)||'</pre>'||LF||'</td><td class="lw">'||LF||
      '<pre>'||sqlt$r.sanitize_html_clob(TRIM(LF FROM p_text2), FALSE)||'</pre>'||LF||'</td></tr></table>'||LF);
    END IF;
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
   * private get_plan_flags
   *
   * ------------------------- */
  FUNCTION get_plan_flags (p_plan_hash_value IN NUMBER)
  RETURN VARCHAR2
  IS
    l_plan_flags VARCHAR2(32767);
  BEGIN
    SELECT plan_flags
      INTO l_plan_flags
      FROM sqlt$_plan_header_v
     WHERE statement_id = s_sql_rec.statement_id
       AND plan_hash_value = p_plan_hash_value
       AND ROWNUM = 1;

    RETURN l_plan_flags;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_plan_flags;

  /*************************************************************************************/

  /* -------------------------
   *
   * private a_phv
   *
   * ------------------------- */
  FUNCTION a_phv (
    p_text IN VARCHAR2,
    p_href IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN a(p_text, p_href)||get_plan_flags(TO_NUMBER(p_text));
  EXCEPTION
    WHEN OTHERS THEN
      RETURN a(p_text, p_href);
  END a_phv;

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
    IF s_go_to = 'Y' THEN
      RETURN font(a('Go to Top', 'toc'), 'f');
    ELSE
      RETURN NULL;
    END IF;
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
    IF s_go_to = 'Y' THEN
      RETURN font(a('Go to '||p_text, p_href), 'f')||LF||'<br>';
    ELSE
      RETURN NULL;
    END IF;
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
   * public mot - mouse over text
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
    RETURN sqlt$a.mot (
      p_main_text  => p_main_text,
      p_mo_text    => p_mo_text,
      p_href       => p_href,
      p_mo_caption => p_mo_caption,
      p_sticky     => p_sticky,
      p_nl_class   => p_nl_class,
      p_target     => p_target );
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

    IF p_href <> 'javascript:void(0);' THEN
      l_return := l_return||' href="'||p_href||'"';
    END IF;

    IF sqlt$a.s_overlib = 'Y' THEN
      IF p_href = 'javascript:void(0);' THEN
        l_return := l_return||' href="'||p_href||'"';
      END IF;

      l_return := l_return||' onmouseover="return overlib(INARRAY, '||p_moa_txt_idx;

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

      l_return := l_return||');" onmouseout="return nd();"';
    END IF;

    l_return := l_return||'>'||p_main_text||'</a>';

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
   * private observations_sec
   *
   * Add a column for Priority. Stelios Charalambides. 10th January 2019.
   * Ordered the results by Priority. 29th January 2020.
   * ------------------------- */
  PROCEDURE observations_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('observations_sec');
    wa(h2('Observations', 'observ'));

    wa('List of concerns identified by the health-check module. Please review. Some may require further attention.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT * 
                FROM sqlg$_observation
               ORDER BY Priority DESC)
      --               type_id,
      --               line_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Type'));
		/* Add a Priority Column header */
		wa(th('Priority'));
        wa(th('Name'));
        wa(th('Observation'));
        wa(th('Details'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.object_type, 'l'));
	  /* Add the Priority Data */
	  wa(td(i.priority,'l'));
      wa(td(i.object_name, 'l'));
      wa(td(i.observation, 'l'));
      IF i.more IS NULL THEN
        wa(td(NBSP));
      ELSE
        wa_td_hide(i.more);
      END IF;
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('observations_sec: '||SQLERRM);
  END observations_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private sql_identification_sec
   *
   * ------------------------- */
  PROCEDURE sql_identification_sec
  IS
  BEGIN
    write_log('sql_identification_sec');
    wa(h2('SQL Identification', 'sql_id'));

    wa('<table>');
    wr('SQL ID', s_sql_rec.sql_id);
    wr('Hash Value', s_sql_rec.hash_value);
    wr('SQL Handle', s_sql_rec.sql_handle);
    wr('Signature for Stored Outlines', s_sql_rec.signature_so);
    wr('Signature for SQL Profiles (force match FALSE)', s_sql_rec.signature_sta);
    wr('Signature for SQL Profiles (force match TRUE)', s_sql_rec.signature_sta_force_match);
    wr('Command Type', s_sql_rec.command_type_name||' ('||s_sql_rec.command_type||')');
    wr('"EXPLAIN PLAN FOR" SQL ID for stripped sql_text', s_sql_rec.xplain_sql_id);
    wr('SQL ID for unstripped sql_text', s_sql_rec.sql_id_unstripped);
    wr('Hash Value for unstripped sql_text', s_sql_rec.hash_value_unstripped);
    wr('Signature for Stored Outlines for unstripped sql_text', s_sql_rec.signature_so_unstripped);
    wr('Signature for SQL Profiles for unstripped sql_text (force match FALSE)', s_sql_rec.signature_sta_unstripped);
    wr('Signature for SQL Profiles for unstripped sql_text (force match TRUE)', s_sql_rec.signature_sta_fm_unstripped);
    wr('Statement Response Time', s_sql_rec.statement_response_time);
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sql_identification_sec: '||SQLERRM);
  END sql_identification_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private environment_sec
   *
   * ------------------------- */
  PROCEDURE environment_sec
  IS
  BEGIN
    write_log('environment_sec');
    wa(h2('Environment', 'env'));

    wa('<table>');
    wr('Host Name', s_sql_rec.host_name_short);
    wr('CPU_Count', s_sql_rec.cpu_count);
    wr('Num CPUs', s_sql_rec.num_cpus);
    wr('Num Cores', s_sql_rec.num_cpu_cores);
    wr('Num Sockets', s_sql_rec.num_cpu_sockets);
    wr('Exadata', NVL(s_sql_rec.exadata, 'NO'));
    wr('RAC', s_sql_rec.rac);
    wr('In-Memory', NVL(s_sql_rec.inmemory_option,'NO'));
    wr('NLS Characterset<br>(database_properties)', s_sql_rec.nls_characterset);
    wr('DB Time Zone<br>(database_properties)', s_sql_rec.dbtimezone);
    wr('DB Block Size<br>(db_block_size)', s_sql_rec.db_block_size);
    wr('Optim Peek User Binds<br>(_optim_peek_user_binds)', s_sql_rec.optim_peek_user_binds);
    wr('DB Size in Terabytes<br>(dba_data_files)', TO_CHAR(ROUND(s_sql_rec.total_bytes / 1e12, 3), NUMBER_FORMAT)||' TB');
    --wr('DB Size in Bytes<br>(dba_data_files)', s_sql_rec.total_bytes);
    --wr('DB Size in Blocks<br>(dba_data_files)', s_sql_rec.total_blocks);
    wr('TC Data Size in Gigabytes<br>(dba_segments)', TO_CHAR(ROUND(s_sql_rec.segments_total_bytes / 1e9, 3), NUMBER_FORMAT)||' GB');
    wr('Platform', s_sql_rec.platform);
    wr('Product Version', s_sql_rec.product_version);
    wr('RDBMS Version', s_sql_rec.rdbms_version);
    wr('Standby Database Link', s_sql_rec.stand_by_dblink);
    wr('Language', s_sql_rec.language);
    wr('Database Name and ID', s_sql_rec.database_name_short||'('||s_sql_rec.database_id||')');
    wr('Instance Name and ID', s_sql_rec.instance_name_short||'('||s_sql_rec.instance_number||')');
    wr('EBS', NVL(s_sql_rec.apps_release, 'NO'));
    wr('EBS System Name', s_sql_rec.apps_system_name);
    wr('Siebel', s_sql_rec.siebel);
    wr('Siebel App Version', s_sql_rec.siebel_app_ver);
    wr('PSFT', s_sql_rec.psft);
    wr('PSFT Tools Release', s_sql_rec.psft_tools_rel);
    wr('User Name and ID', s_sql_rec.username||' ('||s_sql_rec.user_id||')');
    wr('Input Filename', s_sql_rec.input_filename);
    wr('STATID', s_sql_rec.statid);
    wr('Statement Set ID', s_sql_rec.statement_set_id);
    wr('Group ID', s_sql_rec.group_id);
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('environment_sec: '||SQLERRM);
  END environment_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private wa_sql_text
   *
   * ------------------------- */
  PROCEDURE wa_sql_text (p_stripped IN BOOLEAN DEFAULT FALSE)
  IS
  BEGIN
    wa('<pre>');
    IF p_stripped THEN
      font_sanitize_and_append(s_sql_rec.sql_text_clob_stripped, FALSE, 200); -- was 120 then 2000
    ELSE
      font_sanitize_and_append(s_sql_rec.sql_text_clob, FALSE, 200); -- was 120 then 2000
    END IF;
    wa('</pre>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('wa_sql_text: '||SQLERRM);
  END wa_sql_text;

  /*************************************************************************************/

  /* -------------------------
   *
   * private wa_sql_text_show_hide
   *
   * ------------------------- */
  PROCEDURE wa_sql_text_show_hide (p_stripped IN BOOLEAN DEFAULT FALSE)
  IS
  BEGIN
    IF s_sql_text = 'Y' THEN
      IF s_sql_rec.sql_length > 1000 THEN
        wa('SQL Text:'||hide_begin);
      ELSE
        wa('SQL Text:'||show_begin);
      END IF;
      wa_sql_text(p_stripped);
      wa(show_hide_end||'<br>');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('wa_sql_text_show_hide: '||SQLERRM);
  END wa_sql_text_show_hide;

  /*************************************************************************************/

  /* -------------------------
   *
   * private sql_text_sec
   *
   * ------------------------- */
  PROCEDURE sql_text_sec
  IS
    l_ids VARCHAR2(32767);
  BEGIN
    write_log('sql_text_sec');

    IF s_sql_rec.method IN ('XTRACT', 'XTRSBY') THEN
      l_ids := s_sql_rec.sql_id||' '||s_sql_rec.hash_value||' '||s_sql_rec.signature_so||' '||s_sql_rec.signature_sta;
      IF s_sql_rec.signature_sta <> s_sql_rec.signature_sta_force_match THEN
        l_ids := l_ids||' '||s_sql_rec.signature_sta_force_match;
      END IF;
    ELSIF s_sql_rec.method = 'XECUTE' THEN
      l_ids := s_sql_rec.sql_id||' '||s_sql_rec.hash_value||' '||s_sql_rec.signature_so_unstripped||' '||s_sql_rec.signature_sta_unstripped;
      IF s_sql_rec.signature_sta_unstripped <> s_sql_rec.signature_sta_fm_unstripped THEN
        l_ids := l_ids||' '||s_sql_rec.signature_sta_fm_unstripped;
      END IF;
    ELSIF s_sql_rec.method = 'XPLAIN' THEN
      IF s_sql_rec.sql_id_unstripped IS NOT NULL THEN
        l_ids := s_sql_rec.sql_id_unstripped||' '||s_sql_rec.hash_value_unstripped;
      ELSE
        l_ids := s_sql_rec.sql_id||' '||s_sql_rec.hash_value;
      END IF;
      l_ids := l_ids||' '||s_sql_rec.signature_so_unstripped||' '||s_sql_rec.signature_sta_unstripped;
      IF s_sql_rec.signature_sta_unstripped <> s_sql_rec.signature_sta_fm_unstripped THEN
        l_ids := l_ids||' '||s_sql_rec.signature_sta_fm_unstripped;
      END IF;
    ELSE
      l_ids := NULL;
    END IF;

    wa(h2(mot('SQL Text ('||TRIM(l_ids)||')', 'Unstripped SQL Text from GV$SQLAREA, GV$SQLTEXT_WITH_NEWLINES or DBA_HIST_SQLTEXT'), 'sql_text'));
    wa_sql_text;
    wa(go_to_top);

    IF s_sql_rec.method = 'XECUTE' THEN
      l_ids := s_sql_rec.signature_so||' '||s_sql_rec.signature_sta;
      IF s_sql_rec.signature_sta <> s_sql_rec.signature_sta_force_match THEN
        l_ids := l_ids||' '||s_sql_rec.signature_sta_force_match;
      END IF;
    ELSIF s_sql_rec.method = 'XPLAIN' THEN
      IF s_sql_rec.sql_id_unstripped IS NOT NULL THEN
        l_ids := s_sql_rec.sql_id||' '||s_sql_rec.hash_value;
      ELSE
        l_ids := NULL;
      END IF;
      l_ids := l_ids||' '||s_sql_rec.signature_so||' '||s_sql_rec.signature_sta;
      IF s_sql_rec.signature_sta <> s_sql_rec.signature_sta_force_match THEN
        l_ids := l_ids||' '||s_sql_rec.signature_sta_force_match;
      END IF;
    ELSE
      l_ids := NULL;
    END IF;

    -- only if stripped and unstripped are different
    IF s_sql_rec.sql_length_unstripped IS NOT NULL THEN
      wa(h3(mot('Stripped SQL Text ('||TRIM(l_ids)||')', 'After removing tag "'||s_sql_rec.string||'"'), NULL, FALSE));
      wa_sql_text_show_hide(p_stripped => TRUE);
      wa(go_to_top);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sql_text_sec: '||SQLERRM);
  END sql_text_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private cbo_environment_mod
   *
   * ------------------------- */
  PROCEDURE cbo_environment_mod
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('cbo_environment_mod');

    wa(h4('Non-Default or Modified CBO Parameters'));
    wa(show_begin);
    wa('Non-default or modified CBO initialization parameters in effect for the session where '||TOOL_NAME||' '||s_sql_rec.method||' was executed. Includes all instances.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT p.*, v.end_interval_time
                FROM sqlt$_gv$parameter_cbo p,
                     sqlt$_dba_hist_parameter_v v
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.statement_id = v.statement_id(+)
                 AND p.inst_id = v.instance_number(+)
                 AND p.name = v.parameter_name(+)
                 AND v.newest_value_on_awr(+) = 'Y'
                 AND (p.isdefault = 'FALSE' OR p.ismodified <> 'FALSE')
               ORDER BY
                     p.isdefault,
                     p.ismodified DESC,
                     p.name,
                     p.inst_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Is Default<sup>1</sup>'));
        wa(th('Is Modified<sup>2</sup>'));
        wa(th('Name'));
        wa(th('Inst ID'));
        wa(th('Value'));
        wa(th('Display Value'));
        wa(th('Modified on'));
        wa(th('Is Adjusted'));
        wa(th('Is Deprecated'));
        wa(th('Is Basic'));
        wa(th('Is Session Modifiable'));
        wa(th('Is System Modifiable'));
        wa(th('Is Instance Modifiable'));
        wa(th('Type'));
        wa(th('Description'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.isdefault));
      wa(td(i.ismodified));
      wa(td(i.name, 'l'));
      wa(td(i.inst_id));
      wa(td('"'||REPLACE(i.value, ' ', NBSP)||'"', 'l'));
      IF NVL(i.value, '-666') <> NVL(i.display_value, '-666') THEN
        wa(td('"'||REPLACE(i.display_value, ' ', NBSP)||'"', 'l'));
      ELSE
        wa(td(NBSP));
      END IF;
      wa(td(TO_CHAR(i.end_interval_time, TIMESTAMP_FORMAT3), 'l', 'nowrap'));
      wa(td(i.isadjusted));
      wa(td(i.isdeprecated));
      wa(td(i.isbasic));
      wa(td(i.isses_modifiable));
      wa(td(i.issys_modifiable));
      wa(td(i.isinstance_modifiable));
      wa(td(i.type));
      wa(td(i.description, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    IF l_row_count > 0 THEN
      wa(font('(1) FALSE: Parameter value was specified in the parameter file.'));
      wa('<br>');
      wa(font('(2) FALSE: Parameter has not been modified after instance startup. MODIFIED: Parameter has been modified with ALTER SESSION. SYSTEM_MOD: Parameter has been modified with ALTER SYSTEM.'));
      wa('<br>');
      wa(go_to_top);
    END IF;
    wa(show_hide_end);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('cbo_environment_mod: '||SQLERRM);
  END cbo_environment_mod;

  /*************************************************************************************/

  /* -------------------------
   *
   * private cbo_environment_unmod
   *
   * ------------------------- */
  PROCEDURE cbo_environment_unmod
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('cbo_environment_unmod');

    wa(h4('Default Unmodifed CBO Parameters'));
    wa(hide_begin);
    wa('Default unmodified CBO initialization parameters in effect for the session and instance where '||TOOL_NAME||' '||s_sql_rec.method||' was executed.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_gv$parameter_cbo
               WHERE statement_id = s_sql_rec.statement_id
                 AND isdefault = 'TRUE'
                 AND ismodified = 'FALSE'
                 AND inst_id = s_sql_rec.instance_number
               ORDER BY
                     name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Inst ID'));
        wa(th('Value'));
        wa(th('Display Value'));
        wa(th('Is Deprecated'));
        wa(th('Is Basic'));
        wa(th('Is Session Modifiable'));
        wa(th('Is System Modifiable'));
        wa(th('Is Instance Modifiable'));
        wa(th('Type'));
        wa(th('Description'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.inst_id));
      wa(td('"'||REPLACE(i.value, ' ', NBSP)||'"', 'l'));
      IF NVL(i.value, '-666') <> NVL(i.display_value, '-666') THEN
        wa(td('"'||REPLACE(i.display_value, ' ', NBSP)||'"', 'l'));
      ELSE
        wa(td(NBSP));
      END IF;
      wa(td(i.isdeprecated));
      wa(td(i.isbasic));
      wa(td(i.isses_modifiable));
      wa(td(i.issys_modifiable));
      wa(td(i.isinstance_modifiable));
      wa(td(i.type));
      wa(td(i.description, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    IF l_row_count > 0 THEN
      wa(go_to_top);
    END IF;
    wa(show_hide_end);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('cbo_environment_unmod: '||SQLERRM);
  END cbo_environment_unmod;

  /*************************************************************************************/

  /* -------------------------
   *
   * private cbo_environment_sec
   *
   * ------------------------- */
  PROCEDURE cbo_environment_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('cbo_environment_sec');
    wa(h2(mot('CBO Environment', 'SQLT$_GV$PARAMETER_CBO'), 'cbo_env'));

    cbo_environment_mod;
    cbo_environment_unmod;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('cbo_environment_sec: '||SQLERRM);
  END cbo_environment_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private bug_fix_control_sec
   *
   * ------------------------- */
  PROCEDURE bug_fix_control_sec (p_default IN NUMBER)
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('bug_fix_control_sec_'||p_default);

    IF p_default = 0 THEN
      wa(h4('Non-Default Fixes'));
      wa(show_begin);
      wa('Non-default fixes in effect for the session where '||TOOL_NAME||' '||s_sql_rec.method||' was executed.');
    ELSE
      wa(h4('Default Fixes'));
      wa(hide_begin);
      wa('Default fixes in effect for the session where '||TOOL_NAME||' '||s_sql_rec.method||' was executed.');
    END IF;

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT f.*,
                     DECODE(f.event, 0, NULL, f.event) eventno
                FROM sqlt$_v$session_fix_control f
               WHERE f.statement_id = s_sql_rec.statement_id
                 AND is_default = p_default
               ORDER BY
                     f.bugno)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Fix ID'));
        wa(th('Value<sup>1</sup>'));
        wa(th('Optimizer Feature Enable<sup>2</sup>'));
        wa(th('Event'));
        wa(th('Description'));
        wa(th('SQL Feature ID'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.bugno, 'r'));
      wa(td(i.value, 'r'));
      wa(td(i.optimizer_feature_enable, 'l'));
      wa(td(i.eventno, 'r'));
      wa(td(i.description, 'l'));
      wa(td(i.sql_feature, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    IF l_row_count > 0 THEN
      wa(font('(1) 0=disabled, 1=enabled.'));
      wa('<br>');
      wa(font('(2) Version on (and after) which the fix is enabled by default.'));
      wa('<br>');
      wa(go_to_top);
    END IF;
    wa(show_hide_end);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('bug_fix_control_sec_'||p_default||': '||SQLERRM);
  END bug_fix_control_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private bug_fix_control_sec
   *
   * ------------------------- */
  PROCEDURE bug_fix_control_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('bug_fix_control_sec');
    wa(h2(mot('Fix Control', 'V$SESSION_FIX_CONTROL'), 'fix_ctl'));

    bug_fix_control_sec(0);
    bug_fix_control_sec(1);

  EXCEPTION
    WHEN OTHERS THEN
      write_error('bug_fix_control_sec: '||SQLERRM);
  END bug_fix_control_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private system_stats_sec
   *
   * ------------------------- */
  PROCEDURE system_stats_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('system_stats_sec');
    wa(h2(mot('CBO System Statistics', 'AUX_STATS$ and WRI$_OPTSTAT_AUX_HISTORY'), 'system_stats'));
    wa('<ul>');
    wa(li(mot('Info System Statistics', 'AUX_STATS$', '#ss_info')));
    wa(li(mot('Current System Statistics', 'AUX_STATS$', '#ss_main')));
    wa(li(mot('Basis and Synthesized Values', 'AUX_STATS$ and V$PARAMETER', '#ss_bs')));
    wa(li(mot('System Statistics History', 'WRI$_OPTSTAT_AUX_HISTORY', '#ss_hist')));
    wa('</ul>');
    wa(go_to_top);

    wa(h3(mot('Info System Statistics', 'AUX_STATS$'), 'ss_info', FALSE));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_aux_stats$
               WHERE statement_id = s_sql_rec.statement_id
                 AND sname = 'SYSSTATS_INFO'
               ORDER BY DECODE(pname,
                     'STATUS', 1,
                     'DSTART', 2,
                     'DSTOP' , 3, 4), pname)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.pname, 'l'));
      wa(td(i.pval2, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');

    wa(h3(mot('Current System Statistics', 'AUX_STATS$'), 'ss_main', FALSE));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_aux_stats$
               WHERE statement_id = s_sql_rec.statement_id
                 AND sname = 'SYSSTATS_MAIN'
               ORDER BY
                     order_by NULLS LAST,
                     pname)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(mot(i.pname, i.description, NULL, i.pname), 'l'));
      wa(td(i.pval1, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');

    wa(h3(mot('Basis and Synthesized Values', 'AUX_STATS$ and V$PARAMETER'), 'ss_bs', FALSE));
    wa('<table>');
    wr('db_block_size', s_sql_rec.db_block_size);
    wr('db_file_multiblock_read_count', s_sql_rec.db_file_multiblock_read_count);
    wr('_db_file_optimizer_read_count', s_sql_rec.udb_file_optimizer_read_count);
    wr('_db_file_exec_read_count', s_sql_rec.udb_file_exec_read_count);
    IF s_sql_rec.synthetized_mbrc_and_readtim = 'Y' THEN
      wr(mot('Estimated CPUSPEED', 'NVL(cpuspeed, cpuspeednw)', NULL, 'CPUSPEED'), NVL(s_sql_rec.cpuspeed, s_sql_rec.cpuspeednw));
      wr(mot('Estimated MBRC', '_db_file_optimizer_read_count', NULL, 'MBRC'), s_sql_rec.mbrc);
      wr(mot('Estimated SREADTIM', 'ioseektim + (db_block_size / iotfrspeed)', NULL, 'SREADTIM'), s_sql_rec.sreadtim);
    --wr(mot('Estimated MREADTIM', 'ioseektim + ((mbrc * db_block_size) / iotfrspeed)', NULL, 'MREADTIM'), s_sql_rec.mreadtim);
	  wr(mot('Estimated MREADTIM', 'ioseektim + ((_db_file_optimizer_read_count*db_block_size)/iotfrspeed)', NULL, 'MREADTIM'), s_sql_rec.udb_file_optimizer_read_count);
    END IF;
    wr(mot('CPU Cost Scaling Factor', '1 / (cpuspeed * 1000 * sreadtim)', NULL, 'CPU_COST_SCALING_FACTOR'), LOWER(TO_CHAR(s_sql_rec.cpu_cost_scaling_factor, SCIENTIFIC_NOTATION)));
    wr(mot('CPU Cost Scaling Factor (inverse)', 'cpuspeed * 1000 * sreadtim'), ROUND(1 / s_sql_rec.cpu_cost_scaling_factor));
    wr(mot('Actual SREADTIM', 'As per Session Events (GV$SESSION_EVENT) "db file sequential read"', NULL, 'Actual SREADTIM'), s_sql_rec.actual_sreadtim);
    wr(mot('Actual MREADTIM', 'As per Session Events (GV$SESSION_EVENT) "db file scattered read"', NULL, 'Actual MREADTIM'), s_sql_rec.actual_mreadtim);
    wa('</table>');

    wa(h3(mot('System Statistics History', 'WRI$_OPTSTAT_AUX_HISTORY'), 'ss_hist', FALSE));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_wri$_optstat_aux_hist_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     savtime DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Save Time'));
        wa(th('CPUSPEEDNW'));
        wa(th('IOSEEKTIM'));
        wa(th('IOTFRSPEED'));
        wa(th('CPUSPEED'));
        wa(th('MBRC'));
        wa(th('SREADTIM'));
        wa(th('MREADTIM'));
        wa(th('MAXTHR'));
        wa(th('SLAVETHR'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(TO_CHAR(i.savtime, TIMESTAMP_TZ_FORMAT), 'l'));
      wa(td(i.cpuspeednw, 'r'));
      wa(td(i.ioseektim, 'r'));
      wa(td(i.iotfrspeed, 'r'));
      wa(td(i.cpuspeed, 'r'));
      wa(td(i.mbrc, 'r'));
      wa(td(i.sreadtim, 'r'));
      wa(td(i.mreadtim, 'r'));
      wa(td(i.maxthr, 'r'));
      wa(td(i.slavethr, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('system_stats_sec: '||SQLERRM);
  END system_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private dbms_stats_setup_sec
   *
   * ------------------------- */
  PROCEDURE dbms_stats_setup_sec
  IS
    l_row_count NUMBER;
    atc_rec sqlt$_dba_autotask_client%ROWTYPE;
    scj_rec sqlt$_dba_scheduler_jobs%ROWTYPE;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('dbms_stats_setup_sec');
    IF s_sql_rec.rdbms_release >= 11 THEN
      wa(h2(mot('DBMS_STATS Setup', 'DBA_AUTOTASK_CLIENT'), 'dbms_stats'));
    ELSE
      wa(h2(mot('DBMS_STATS Setup', 'DBA_SCHEDULER_JOBS'), 'dbms_stats'));
    END IF;
    wa('<ul>');
    wa(li(mot('DBMS_STATS System Preferences', 'GET_PREFS or GET_PARAM', '#ds_prefs')));
    wa(li(mot('DBMS_STATS Table Preferences', 'OPTSTAT_USER_PREFS$', '#dst_prefs')));
    IF s_sql_rec.rdbms_release >= 11 THEN
      wa(li(mot('Auto Task "auto optimizer stats collection"', 'DBA_AUTOTASK_CLIENT', '#ds_task')));
    ELSE
      wa(li(mot('Scheduled Job "GATHER_STATS_JOB"', 'DBA_SCHEDULER_JOBS', '#ds_task')));
    END IF;
    wa(li(mot('Statistics for SYS Tables', 'DBA_TABLES', '#sys_stats')));
    wa(li(mot('Statistics for Fixed Objects', 'DBA_TAB_STATISTICS', '#fo_stats')));
    wa(li(mot('DBMS_STATS Operations History', 'DBA_OPTSTAT_OPERATIONS', '#ds_hist')));
    wa('</ul>');
    wa(go_to_top);

    wa(h3(mot('DBMS_STATS System Preferences', 'GET_PREFS or GET_PARAM'), 'ds_prefs', FALSE));
    wa('<table>');
    wr('Approximate NDV', NVL(s_sql_rec.param_approximate_ndv, '"null"'));
    wr('Auto Stats Target', NVL(s_sql_rec.param_autostats_target, '"null"'));
    wr('Cascade', NVL(s_sql_rec.param_cascade, '"null"'));
    wr('Concurrent', NVL(s_sql_rec.param_concurrent, '"null"'));
    wr('Degree', NVL(s_sql_rec.param_degree, '"null"'));
    wr('Estimate Percent', NVL(s_sql_rec.param_estimate_percent, '"null"'));
    wr('Granularity', NVL(s_sql_rec.param_granularity, '"null"'));
    wr('Incremental Internal Control', NVL(s_sql_rec.param_incr_internal_control, '"null"'));
    wr('Incremental', NVL(s_sql_rec.param_incremental, '"null"'));
    wr('Method Opt', NVL(s_sql_rec.param_method_opt, '"null"'));
    wr('No Invalidate', NVL(s_sql_rec.param_no_invalidate, '"null"'));
    wr('Publish', NVL(s_sql_rec.param_publish, '"null"'));
    wr('Stale Percent', NVL(s_sql_rec.param_stale_percent, '"null"'));
    wr('Stats Retention', NVL(s_sql_rec.param_stats_retention, '"null"'));
    wa('</table>');

    wa(h3(mot('DBMS_STATS Table Preferences', 'OPTSTAT_USER_PREFS$'), 'dst_prefs', FALSE));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT o.owner,
                     o.object_name table_name,
                     p.obj#,
                     p.pname parameter_name,
                     p.valchar parameter_value,
                     p.chgtime change_time
                FROM sqlt$_optstat_user_prefs$ p,
                     sqlt$_dba_objects o
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.statement_id = o.statement_id
                 AND p.obj# = o.object_id
               ORDER BY
                     o.owner,
                     o.object_name,
                     p.pname,
                     p.chgtime)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Owner'));
        wa(th('Table Name'));
        wa(th('Obj#'));
        wa(th('Parameter Name'));
        wa(th('Parameter Value'));
        wa(th('Change Time'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.owner, 'l'));
      wa(td(i.table_name, 'l'));
      wa(td(i.obj#, 'r'));
      wa(td(i.parameter_name, 'l'));
      wa(td(i.parameter_value, 'l'));
      wa(td(TO_CHAR(i.change_time, TIMESTAMP_TZ_FORMAT), 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');

    IF s_sql_rec.rdbms_release >= 11 THEN
      BEGIN
        SELECT * INTO atc_rec FROM sqlt$_dba_autotask_client WHERE statement_id = s_sql_rec.statement_id AND ROWNUM = 1;
        wa(h3(mot('Auto Task "auto optimizer stats collection"', 'DBA_AUTOTASK_CLIENT'), 'ds_task', FALSE));
        wa('<table>');
        wr('Client Name', atc_rec.client_name);
        wr('Status', atc_rec.status);
        wr('Consumer Group', atc_rec.consumer_group);
        wr('Client Tag', atc_rec.client_tag);
        wr('Priority Override', atc_rec.priority_override);
        wr('Attributes', atc_rec.attributes);
        wr('Window Group', atc_rec.window_group);
        wr('Service Name', atc_rec.service_name);
        wr('Resource Percentage', atc_rec.resource_percentage);
        wr('Use Resource Estimates', atc_rec.use_resource_estimates);
        wr('Mean Job Duration', atc_rec.mean_job_duration);
        wr('Mean Job CPU', atc_rec.mean_job_cpu);
        wr('Mean Job Attempts', atc_rec.mean_job_attempts);
        wr('Mean incoming Tasks 7 days', ROUND(atc_rec.mean_incoming_tasks_7_days, 3));
        wr('Mean incoming Tasks 30 days', ROUND(atc_rec.mean_incoming_tasks_30_days, 3));
        wr('Total CPU last 7 days', atc_rec.total_cpu_last_7_days);
        wr('Total CPU last 30 days', atc_rec.total_cpu_last_30_days);
        wr('Max duration last 7 days', atc_rec.max_duration_last_7_days);
        wr('Max duration last 30 days', atc_rec.max_duration_last_30_days);
        wr('Window duration last 7 days', atc_rec.window_duration_last_7_days);
        wr('Window duration last 30 days', atc_rec.window_duration_last_30_days);
        wa('</table>');
      EXCEPTION
        WHEN OTHERS THEN
          write_error('dbms_stats_setup_sec.dba_autotask_client: '||SQLERRM);
      END;
    ELSE
      BEGIN
        SELECT * INTO scj_rec FROM sqlt$_dba_scheduler_jobs WHERE statement_id = s_sql_rec.statement_id AND ROWNUM = 1;
        wa(h3(mot('Scheduled Job "GATHER_STATS_JOB"', 'DBA_SCHEDULER_JOBS'), 'ds_task', FALSE));
        wa('<table>');
        wr('Job Name', scj_rec.job_name);
        wr('Program Name', scj_rec.program_name);
        wr('Schedule Name', scj_rec.schedule_name);
        wr('Job Class', scj_rec.job_class);
        wr('Enabled', scj_rec.enabled);
        wr('State', scj_rec.state);
        wr('Job Priority', scj_rec.job_priority);
        wr('Run Count', scj_rec.run_count);
        wr('Retry Count', scj_rec.retry_count);
        wr('Last Start Date', scj_rec.last_start_date);
        wr('Last Run Duration', scj_rec.last_run_duration);
        wr('Stop on Window Close', scj_rec.stop_on_window_close);
        wa('</table>');
      EXCEPTION
        WHEN OTHERS THEN
          write_error('dbms_stats_setup_sec.dba_scheduler_jobs: '||SQLERRM);
      END;
    END IF;

    wa(h3(mot('Statistics for SYS Tables', 'DBA_TABLES'), 'sys_stats', FALSE));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT NVL(TO_CHAR(last_analyzed, 'YYYY-MM'), 'NO STATS') last_analyzed,
               COUNT(*) tables
                FROM sys.dba_tables
               WHERE owner = 'SYS'
               GROUP BY
                     TO_CHAR(last_analyzed, 'YYYY-MM')
               ORDER BY
                     1 DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Last Analyzed'));
        wa(th('Tables'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.last_analyzed, 'l'));
      wa(td(i.tables, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');

    wa(h3(mot('Statistics for Fixed Objects', 'DBA_TAB_STATISTICS'), 'fo_stats', FALSE));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT NVL(TO_CHAR(last_analyzed, 'YYYY-MM'), 'NO STATS') last_analyzed,
               COUNT(*) fixed_objects
                FROM sys.dba_tab_statistics
               WHERE object_type = 'FIXED TABLE'
               GROUP BY
                     TO_CHAR(last_analyzed, 'YYYY-MM')
               ORDER BY
                     1 DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Last Analyzed'));
        wa(th('Fixed Objects'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.last_analyzed, 'l'));
      wa(td(i.fixed_objects, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');

    l_sql := '
SELECT o.start_time,
       o.end_time,
       o.operation,
       o.target
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_optstat_operations o,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_tables_v t
 WHERE o.statement_id = '||s_sql_rec.statement_id||'
   AND UPPER(o.operation) LIKE ''%TABLE%''
   AND o.statement_id = t.statement_id
   AND UPPER(o.target) LIKE ''%''||UPPER(t.owner)||''%''
   AND UPPER(o.target) LIKE ''%''||UPPER(t.table_name)||''%''
 UNION
SELECT o.start_time,
       o.end_time,
       o.operation,
       o.target
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_optstat_operations o,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_tables_v t
 WHERE o.statement_id = '||s_sql_rec.statement_id||'
   AND UPPER(o.operation) LIKE ''%SCHEMA%''
   AND o.statement_id = t.statement_id
   AND UPPER(o.target) LIKE ''%''||UPPER(t.owner)||''%''
 UNION
SELECT o.start_time,
       o.end_time,
       o.operation,
       o.target
  FROM sqlt$_dba_optstat_operations o,
       sqlt$_dba_indexes i
 WHERE o.statement_id = '||s_sql_rec.statement_id||'
   AND UPPER(o.operation) LIKE ''%INDEX%''
   AND o.statement_id = i.statement_id
   AND UPPER(o.target) LIKE ''%''||UPPER(i.owner)||''%''
   AND UPPER(o.target) LIKE ''%''||UPPER(i.index_name)||''%''
 UNION
SELECT o.start_time,
       o.end_time,
       o.operation,
       o.target
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_optstat_operations o
 WHERE o.statement_id = '||s_sql_rec.statement_id||'
   AND UPPER(o.operation) NOT LIKE ''%TABLE%''
   AND UPPER(o.operation) NOT LIKE ''%SCHEMA%''
   AND UPPER(o.operation) NOT LIKE ''%INDEX%''
 ORDER BY
       start_time DESC;';

    wa(h3(mot('DBMS_STATS Operations History', 'DBA_OPTSTAT_OPERATIONS'), 'ds_hist', FALSE));

    wa('List restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT o.start_time,
                     o.end_time,
                     o.operation,
                     o.target
                FROM sqlt$_dba_optstat_operations o,
                     sqlt$_dba_all_tables_v t
               WHERE o.statement_id = s_sql_rec.statement_id
                 AND UPPER(o.operation) LIKE '%TABLE%'
                 AND o.statement_id = t.statement_id
                 AND UPPER(o.target) LIKE '%'||UPPER(t.owner)||'%'
                 AND UPPER(o.target) LIKE '%'||UPPER(t.table_name)||'%'
               UNION
              SELECT o.start_time,
                     o.end_time,
                     o.operation,
                     o.target
                FROM sqlt$_dba_optstat_operations o,
                     sqlt$_dba_all_tables_v t
               WHERE o.statement_id = s_sql_rec.statement_id
                 AND UPPER(o.operation) LIKE '%SCHEMA%'
                 AND o.statement_id = t.statement_id
                 AND UPPER(o.target) LIKE '%'||UPPER(t.owner)||'%'
               UNION
              SELECT o.start_time,
                     o.end_time,
                     o.operation,
                     o.target
                FROM sqlt$_dba_optstat_operations o,
                     sqlt$_dba_indexes i
               WHERE o.statement_id = s_sql_rec.statement_id
                 AND UPPER(o.operation) LIKE '%INDEX%'
                 AND o.statement_id = i.statement_id
                 AND UPPER(o.target) LIKE '%'||UPPER(i.owner)||'%'
                 AND UPPER(o.target) LIKE '%'||UPPER(i.index_name)||'%'
               UNION
              SELECT o.start_time,
                     o.end_time,
                     o.operation,
                     o.target
                FROM sqlt$_dba_optstat_operations o
               WHERE o.statement_id = s_sql_rec.statement_id
                 AND UPPER(o.operation) NOT LIKE '%TABLE%'
                 AND UPPER(o.operation) NOT LIKE '%SCHEMA%'
                 AND UPPER(o.operation) NOT LIKE '%INDEX%'
               ORDER BY
                     start_time DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Start Time'));
        wa(th('End Time'));
        wa(th('Operation'));
        wa(th('Target'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(TO_CHAR(i.start_time, TIMESTAMP_TZ_FORMAT), 'l'));
      wa(td(TO_CHAR(i.end_time, TIMESTAMP_TZ_FORMAT), 'l'));
      wa(td(i.operation, 'l'));
      wa(td(i.target, 'l'));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('dbms_stats_setup_sec: '||SQLERRM);
  END dbms_stats_setup_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private init_parameters_sec
   *
   * ------------------------- */
  PROCEDURE init_parameters_sec (p_default IN VARCHAR2)
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('init_parameters_sec_'||p_default);

    IF p_default = 'FALSE' THEN
      wa(h4('Non-Default or Modified Session Parameters', 'init_parameters_sec_'||p_default));
      wa(show_begin);
      wa('Non-default or modified initialization parameters in effect for the session where '||TOOL_NAME||' '||s_sql_rec.method||' was executed. Includes all instances. Excludes CBO parameters.');
    ELSE
      wa(h4('Default Unmodifed Session Parameters'));
      wa(hide_begin);
      wa('Default unmodified initialization parameters in effect for the session and instance where '||TOOL_NAME||' '||s_sql_rec.method||' was executed. Excludes CBO parameters.');
    END IF;

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT p.*,v.end_interval_time
                FROM sqlt$_gv$parameter2 p,
                     sqlt$_dba_hist_parameter_v v
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.statement_id = v.statement_id(+)
                 AND p.inst_id = v.instance_number(+)
                 AND p.name = v.parameter_name(+)
                 AND v.newest_value_on_awr(+) = 'Y'
                 AND (p.isdefault = 'FALSE' OR p.ismodified <> 'FALSE' OR p.inst_id = s_sql_rec.instance_number)
                 AND CASE
                     WHEN p_default = 'TRUE' AND p.isdefault = 'TRUE' AND p.ismodified = 'FALSE' THEN 'Y'
                     WHEN p_default = 'FALSE' AND (p.isdefault = 'FALSE' OR p.ismodified <> 'FALSE') THEN 'Y'
                     ELSE 'N' END = 'Y'
                 AND NOT EXISTS (
              SELECT NULL
                FROM sqlt$_gv$parameter_cbo c
               WHERE c.statement_id = s_sql_rec.statement_id
                 AND c.name = p.name )
               ORDER BY
                     p.isdefault,
                     p.ismodified DESC,
                     p.name,
                     p.inst_id,
                     p.ordinal)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        IF p_default = 'FALSE' THEN
          wa(th('Is Default<sup>1</sup>'));
          wa(th('Is Modified<sup>2</sup>'));
          wa(th('Modified on<sup>3</sup>'));
        END IF;
        wa(th('Name'));
        wa(th('Inst ID'));
        wa(th('Ordinal'));
        wa(th('Value'));
        wa(th('Display Value'));
        IF p_default = 'FALSE' THEN
          wa(th('Is Adjusted'));
        END IF;
        wa(th('Is Deprecated'));
        wa(th('Is Basic'));
        wa(th('Is Session Modifiable'));
        wa(th('Is System Modifiable'));
        wa(th('Is Instance Modifiable'));
        wa(th('Type'));
        wa(th('Description'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      IF p_default = 'FALSE' THEN
        wa(td(i.isdefault));
        wa(td(i.ismodified));
        wa(td(TO_CHAR(i.end_interval_time, TIMESTAMP_FORMAT3), 'l', 'nowrap'));
      END IF;
      wa(td(i.name, 'l'));
      wa(td(i.inst_id));
      wa(td(i.ordinal));
      wa(td('"'||REPLACE(sqlt$r.wrap_clob(i.value, 40), ' ', NBSP)||'"', 'l'));
      IF NVL(i.value, '-666') <> NVL(i.display_value, '-666') THEN
        wa(td('"'||REPLACE(sqlt$r.wrap_clob(i.display_value, 40), ' ', NBSP)||'"', 'l'));
      ELSE
        wa(td(NBSP));
      END IF;
      IF p_default = 'FALSE' THEN
        wa(td(i.isadjusted));
      END IF;
      wa(td(i.isdeprecated));
      wa(td(i.isbasic));
      wa(td(i.isses_modifiable));
      wa(td(i.issys_modifiable));
      wa(td(i.isinstance_modifiable));
      wa(td(i.type));
      wa(td(i.description, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    IF l_row_count > 0 THEN
      IF p_default = 'FALSE' THEN
        wa(font('(1) FALSE: Parameter value was specified in the parameter file.'));
        wa('<br>');
        wa(font('(2) FALSE: Parameter has not been modified after instance startup. MODIFIED: Parameter has been modified with ALTER SESSION. SYSTEM_MOD: Parameter has been modified with ALTER SYSTEM.'));
        wa('<br>');
        wa(font('(3) Last time this parameter has been modified (if available in AWR).'));
        wa('<br>');
      END IF;
      wa(go_to_top);
    END IF;
    wa(show_hide_end);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('init_parameters_sec_'||p_default||': '||SQLERRM);
  END init_parameters_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private init_parameters_sys_mod
   *
   * ------------------------- */
  PROCEDURE init_parameters_sys_mod
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('init_parameters_sys_mod');

    l_sql := '
SELECT p.parameter_name,
       p.instance_number,
       p.end_interval_time,
       p.snap_id,
       p.isdefault,
       p.ismodified,
       p.value,
       p.oldest_value_on_awr
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_hist_parameter_v p
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
 ORDER BY
       p.parameter_name,
       p.instance_number,
       p.end_interval_time DESC;';

    wa(h4('Modified System Parameters', 'init_parameters_sys_mod'));
    wa(show_begin);
    wa('Historical values of modified initialization system-level parameters captured by AWR with no direct relation to the SQL being analyzed. Includes all instances. Excludes some parameters and all "__%" parameters');
    wa('<br>');
    wa('List restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT p.parameter_name,
                     p.instance_number,
                     p.end_interval_time,
                     p.snap_id,
                     p.isdefault,
                     p.ismodified,
                     p.value,
                     p.oldest_value_on_awr,
                     p.newest_value_on_awr
                FROM sqlt$_dba_hist_parameter_v p
               WHERE p.statement_id = s_sql_rec.statement_id
               ORDER BY
                     p.parameter_name,
                     p.instance_number,
                     p.end_interval_time DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Parameter Name'));
        wa(th('Inst ID'));
        wa(th('Snapshot Time'));
        wa(th('Snap ID'));
        wa(th('Is Default<sup>1</sup>'));
        wa(th('Is Modified<sup>2</sup>'));
        wa(th('Value'));
        wa(th('Oldest Value<sup>3</sup>'));
        wa(th('Newest Value<sup>4</sup>'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.parameter_name, 'l'));
      wa(td(i.instance_number));
      wa(td(TO_CHAR(i.end_interval_time, TIMESTAMP_FORMAT3), 'l', 'nowrap'));
      wa(td(i.snap_id));
      wa(td(i.isdefault));
      wa(td(i.ismodified));
      wa(td('"'||REPLACE(sqlt$r.wrap_clob(i.value, 40), ' ', NBSP)||'"', 'l'));
      wa(td(i.oldest_value_on_awr));
      wa(td(i.newest_value_on_awr));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    IF l_row_count > 0 THEN
      wa(font('(1) FALSE: Parameter value was specified in the parameter file.'));
      wa('<br>');
      --wa(font('(2) FALSE: Parameter has not been modified after instance startup. MODIFIED: Parameter has been modified with ALTER SESSION. SYSTEM_MOD: Parameter has been modified with ALTER SYSTEM.'));
      wa(font('(2) FALSE: Parameter has not been modified after instance startup. MODIFIED or SYSTEM_MOD: Parameter has been modified with ALTER SYSTEM.'));
      wa('<br>');
      wa(font('(3) Y: Oldest Value on AWR for this Parameter Name and Inst ID.'));
      wa('<br>');
      wa(font('(4) Y: Newest Value on AWR for this Parameter Name and Inst ID.'));
      wa('<br>');
      wa(go_to_top);
    END IF;
    wa(show_hide_end);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('init_parameters_sys_mod: '||SQLERRM);
  END init_parameters_sys_mod;

  /*************************************************************************************/

  /* -------------------------
   *
   * private init_parameters_sys
   *
   * ------------------------- */
  PROCEDURE init_parameters_sys
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('init_parameters_sys');

    l_sql := '
SELECT s.end_interval_time,
       p.snap_id,
       p.isdefault,
       p.ismodified,
       p.parameter_name,
       p.instance_number,
       p.value
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqli$_dba_hist_parameter p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_hist_snapshot s,
       (SELECT /*+ NO_MERGE */
               DISTINCT snap_id, dbid
          FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_hist_sqlstat
         WHERE statement_id = '||s_sql_rec.statement_id||') st
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.statement_id = s.statement_id
   AND p.snap_id = s.snap_id
   AND p.dbid = s.dbid
   AND p.instance_number = s.instance_number
   AND (p.isdefault = ''FALSE'' OR p.ismodified <> ''FALSE'')
   AND p.snap_id = st.snap_id
   AND p.dbid = st.dbid
 ORDER BY
       s.end_interval_time DESC,
       p.isdefault,
       p.ismodified DESC,
       p.parameter_name,
       p.instance_number;';

    wa(h4('Historical Non-Default or Modified System Parameters', 'init_parameters_sys'));
    wa(show_begin);
    wa('Historical values of non-default or modified initialization system-level parameters, captured by AWR during snapshots of the SQL statement being analyzed. Includes all instances.');
    wa('<br>');
    wa('List restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    --wa('<br>');
    --wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT s.end_interval_time,
                     p.snap_id,
                     p.isdefault,
                     p.ismodified,
                     p.parameter_name,
                     p.instance_number,
                     p.value
                FROM sqli$_dba_hist_parameter p,
                     sqlt$_dba_hist_snapshot s,
                     (SELECT /*+ NO_MERGE */
                             DISTINCT snap_id, dbid
                        FROM sqlt$_dba_hist_sqlstat
                       WHERE statement_id = s_sql_rec.statement_id) st
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.statement_id = s.statement_id
                 AND p.snap_id = s.snap_id
                 AND p.dbid = s.dbid
                 AND p.instance_number = s.instance_number
                 AND (p.isdefault = 'FALSE' OR p.ismodified <> 'FALSE')
                 AND p.snap_id = st.snap_id
                 AND p.dbid = st.dbid
               ORDER BY
                     s.end_interval_time DESC,
                     p.isdefault,
                     p.ismodified DESC,
                     p.parameter_name,
                     p.instance_number)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Snapshot Time'));
        wa(th('Snap ID'));
        wa(th('Is Default<sup>1</sup>'));
        wa(th('Is Modified<sup>2</sup>'));
        wa(th('Parameter Name'));
        wa(th('Inst ID'));
        wa(th('Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(TO_CHAR(i.end_interval_time, TIMESTAMP_FORMAT3), 'l', 'nowrap'));
      wa(td(i.snap_id));
      wa(td(i.isdefault));
      wa(td(i.ismodified));
      wa(td(i.parameter_name, 'l'));
      wa(td(i.instance_number));
      wa(td('"'||REPLACE(sqlt$r.wrap_clob(i.value, 40), ' ', NBSP)||'"', 'l'));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    IF l_row_count > 0 THEN
      wa(font('(1) FALSE: Parameter value was specified in the parameter file.'));
      wa('<br>');
      --wa(font('(2) FALSE: Parameter has not been modified after instance startup. MODIFIED: Parameter has been modified with ALTER SESSION. SYSTEM_MOD: Parameter has been modified with ALTER SYSTEM.'));
      wa(font('(2) FALSE: Parameter has not been modified after instance startup. MODIFIED or SYSTEM_MOD: Parameter has been modified with ALTER SYSTEM.'));
      wa('<br>');
      wa(go_to_top);
    END IF;
    wa(show_hide_end);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('init_parameters_sys: '||SQLERRM);
  END init_parameters_sys;

  /*************************************************************************************/

  /* -------------------------
   *
   * private init_parameters_sec
   *
   * ------------------------- */
  PROCEDURE init_parameters_sec
  IS
  BEGIN
    write_log('init_parameters_sec');
    wa(h2(mot('Initialization Parameters', 'GV$PARAMETER2 and DBA_HIST_PARAMETER'), 'init_params'));

    init_parameters_sec('FALSE');
    init_parameters_sec('TRUE');
    init_parameters_sys_mod;
    init_parameters_sys;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('init_parameters_sec: '||SQLERRM);
  END init_parameters_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private nls_parameters_sec
   *
   * ------------------------- */
  PROCEDURE nls_parameters_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('nls_parameters_sec');
    wa(h2(mot('NLS Parameters', 'NLS_SESSION_PARAMETERS, NLS_INSTANCE_PARAMETERS and NLS_DATABASE_PARAMETERS'), 'nls_params'));

    -- session
    BEGIN
      wa(h4(mot('NLS Session Parameters', 'NLS_SESSION_PARAMETERS (GV$NLS_PARAMETERS)')));
      wa(show_begin);
      wa('Captured when '||TOOL_NAME||' was executed. Includes other instances if the value is different to this instance.');
      wa('<table>');
      l_row_count := 0;
      FOR i IN (SELECT inst_id, parameter, value
                  FROM sqlt$_gv$nls_parameters
                 WHERE statement_id = s_sql_rec.statement_id
                   AND inst_id = s_sql_rec.instance_number -- this instance
                 UNION -- parameters from other instances with different value than this instance
                SELECT p1.inst_id, p1.parameter, p1.value
                  FROM sqlt$_gv$nls_parameters p1, -- other instances
                       sqlt$_gv$nls_parameters p2 -- this instance
                 WHERE p1.statement_id = s_sql_rec.statement_id
                   AND p2.statement_id = s_sql_rec.statement_id
                   AND p1.inst_id <> s_sql_rec.instance_number -- other instances
                   AND p2.inst_id = s_sql_rec.instance_number -- this instance
                   AND p1.parameter = p2.parameter
                   AND p1.value <> p2.value
                 ORDER BY
                       2, 1)
      LOOP
        l_row_count := l_row_count + 1;
        IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
          wa('<tr>');
          wa(th('#'));
          wa(th('Name'));
          wa(th('Inst ID'));
          wa(th('Value'));
          wa('</tr>');
        END IF;

        wa('<tr>');
        wa(td(l_row_count, 'rt'));
        wa(td(LOWER(i.parameter), 'l'));
        wa(td(i.inst_id));
        wa(td(i.value, 'l'));
        wa('</tr>');
      END LOOP;
      wa('</table>');
      IF l_row_count > 0 THEN
        wa(go_to_top);
      END IF;
      wa(show_hide_end);
    END;

    -- instance
    BEGIN
      wa(h4(mot('NLS Instance Parameters', 'NLS_INSTANCE_PARAMETERS (GV$SYSTEM_PARAMETER)')));
      wa(show_begin);
      wa('Captured when '||TOOL_NAME||' was executed. Includes other instances if the value is different to this instance.');
      wa('<table>');
      l_row_count := 0;
      FOR i IN (SELECT inst_id, name parameter, value
                  FROM sqlt$_gv$system_parameter
                 WHERE statement_id = s_sql_rec.statement_id
                   AND name LIKE 'nls%'
                   AND inst_id = s_sql_rec.instance_number -- this instance
                 UNION -- parameters from other instances with different value than this instance
                SELECT p1.inst_id, p1.name parameter, p1.value
                  FROM sqlt$_gv$system_parameter p1, -- other instances
                       sqlt$_gv$system_parameter p2 -- this instance
                 WHERE p1.statement_id = s_sql_rec.statement_id
                   AND p2.statement_id = s_sql_rec.statement_id
                   AND p1.name LIKE 'nls%'
                   AND p2.name LIKE 'nls%'
                   AND p1.inst_id <> s_sql_rec.instance_number -- other instances
                   AND p2.inst_id = s_sql_rec.instance_number -- this instance
                   AND p1.name = p2.name
                   AND p1.value <> p2.value
                 ORDER BY
                       2, 1)
      LOOP
        l_row_count := l_row_count + 1;
        IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
          wa('<tr>');
          wa(th('#'));
          wa(th('Name'));
          wa(th('Inst ID'));
          wa(th('Value'));
          wa('</tr>');
        END IF;

        wa('<tr>');
        wa(td(l_row_count, 'rt'));
        wa(td(LOWER(i.parameter), 'l'));
        wa(td(i.inst_id));
        wa(td(i.value, 'l'));
        wa('</tr>');
      END LOOP;
      wa('</table>');
      IF l_row_count > 0 THEN
        wa(go_to_top);
      END IF;
      wa(show_hide_end);
    END;

    -- database
    BEGIN
      wa(h4(mot('NLS Database Parameters', 'NLS_DATABASE_PARAMETERS')));
      wa(show_begin);
      wa('Captured when '||TOOL_NAME||' was executed.');
      wa('<table>');
      l_row_count := 0;
      FOR i IN (SELECT parameter, value
                  FROM sqlt$_nls_database_parameters
                 WHERE statement_id = s_sql_rec.statement_id
                 ORDER BY
                       parameter)
      LOOP
        l_row_count := l_row_count + 1;
        IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
          wa('<tr>');
          wa(th('#'));
          wa(th('Name'));
          wa(th('Value'));
          wa('</tr>');
        END IF;

        wa('<tr>');
        wa(td(l_row_count, 'rt'));
        wa(td(LOWER(i.parameter), 'l'));
        wa(td(i.value, 'l'));
        wa('</tr>');
      END LOOP;
      wa('</table>');
      IF l_row_count > 0 THEN
        wa(go_to_top);
      END IF;
      wa(show_hide_end);
    END;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('nls_parameters_sec: '||SQLERRM);
  END nls_parameters_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private io_calibration_sec
   *
   * ------------------------- */
  PROCEDURE io_calibration_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('io_calibration_sec');
    wa(h2(mot('I/O Calibration', 'DBA_RSRC_IO_CALIBRATE and V$IO_CALIBRATION_STATUS'), 'io_calibration'));

    wa(h4(mot('I/O calibration results for the latest calibration run', 'DBA_RSRC_IO_CALIBRATE')));
    wa('<table>');
    wr('start_time', TO_CHAR(s_sql_rec.ioc_start_time, TIMESTAMP_FORMAT6));
    wr('end_time', TO_CHAR(s_sql_rec.ioc_end_time, TIMESTAMP_FORMAT6));
    wr('max_iops', s_sql_rec.ioc_max_iops);
    wr('max_mbps', s_sql_rec.ioc_max_mbps);
    wr('max_pmbps', s_sql_rec.ioc_max_pmbps);
    wr('latency', s_sql_rec.ioc_latency);
    wr('num_physical_disks', s_sql_rec.ioc_num_physical_disks);
    wa('</table>');

    wa(h4(mot('Status of I/O calibration in the instance', 'V$IO_CALIBRATION_STATUS')));
    wa('<table>');
    wr('status', s_sql_rec.ioc_status);
    wr('calibration_time', TO_CHAR(s_sql_rec.ioc_calibration_time, TIMESTAMP_FORMAT3));
    wa('</table>');

    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('io_calibration_sec: '||SQLERRM);
  END io_calibration_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tablespaces_sec
   *
   * ------------------------- */
  PROCEDURE tablespaces_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tablespaces_sec');
    wa(h2(mot('Tablespaces', 'DBA_TABLESPACES'), 'tablespaces'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_tablespaces
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     tablespace_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Tablespace Name'));
        wa(th('Block Size'));
        wa(th('Initial Extent'));
        wa(th('Next Extent'));
        wa(th('Min Extents'));
        wa(th('Max Extents'));
        wa(th('Max Size'));
        wa(th('Pct Increase'));
        wa(th('Min Extent Length'));
        wa(th('Status'));
        wa(th('Contents'));
        wa(th('Logging'));
        wa(th('Force Logging'));
        wa(th('Extent Management'));
        wa(th('Allocation Type'));
        wa(th('Plugged in'));
        wa(th('Segment Space Management'));
        wa(th('Default Table Compression'));
        wa(th('Retention'));
        wa(th('Big File'));
        wa(th('Predicate Evaluation'));
        wa(th('Encrypted'));
        wa(th('Compress for'));
        wa(th('Total Terabytes'));
        --wa(th('Total Bytes'));
        --wa(th('Total Blocks'));
        --wa(th('Total User Bytes'));
        --wa(th('Total User Blocks'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.tablespace_name, 'l'));
      wa(td(i.block_size, 'r'));
      wa(td(i.initial_extent, 'r'));
      wa(td(i.next_extent, 'r'));
      wa(td(i.min_extents, 'r'));
      wa(td(i.max_extents, 'r'));
      wa(td(i.max_size, 'r'));
      wa(td(i.pct_increase, 'r'));
      wa(td(i.min_extlen, 'r'));
      wa(td(i.status));
      wa(td(i.contents));
      wa(td(i.logging));
      wa(td(i.force_logging));
      wa(td(i.extent_management));
      wa(td(i.allocation_type));
      wa(td(i.plugged_in));
      wa(td(i.segment_space_management));
      wa(td(i.def_tab_compression));
      wa(td(i.retention));
      wa(td(i.bigfile));
      wa(td(i.predicate_evaluation));
      wa(td(i.encrypted));
      wa(td(i.compress_for));
      wa(td(TO_CHAR(ROUND(i.total_bytes / 1e12, 3), NUMBER_FORMAT)||' TB', 'r'));
      --wa(td(i.total_bytes, 'r'));
      --wa(td(i.total_blocks, 'r'));
      --wa(td(i.total_user_bytes, 'r'));
      --wa(td(i.total_user_blocks, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tablespaces_sec: '||SQLERRM);
  END tablespaces_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tool_config_params_sec
   *
   * ------------------------- */
  PROCEDURE tool_config_params_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tool_config_params_sec');
    wa(h2('Tool Configuration Parameters', 'tool_params'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT CASE WHEN p.is_default = 'Y' AND NVL(s.is_default, 'Y') = 'Y' THEN 'TRUE' ELSE 'FALSE' END isdefault,
                     p.name,
                     p.description,
                     p.value,
                     NVL(s.value, p.value) sess_value,
                     p.default_value,
                     p.instructions
                FROM sqli$_parameter p,
                     sqli$_sess_parameter s
               WHERE p.is_hidden = 'N'
                 AND p.is_usr_modifiable = 'Y'
                 AND p.name = s.name(+)
               ORDER BY
                     CASE WHEN p.is_default = 'Y' AND NVL(s.is_default, 'Y') = 'Y' THEN 'TRUE' ELSE 'FALSE' END,
                     p.name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Is Default'));
        wa(th('Name'));
        wa(th('System Value<sup>1</sup>'));
        wa(th('Session Value<sup>2</sup>'));
        wa(th('Default Value'));
        wa(th('Domain'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.isdefault));
      wa(td(mot(i.name, i.description, NULL, i.name, TRUE), 'l'));
      wa(td(i.value));
      wa(td(i.sess_value));
      wa(td(i.default_value));
      wa(td(i.instructions, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) To permanently set a tool parameter issue: SQL> EXEC '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.set_param(''Name'', ''Value'');'));
    wa('<br>');
    wa(font('(2) To temporarily set a tool parameter for a session issue: SQL> EXEC '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.set_sess_param(''Name'', ''Value'');'));
    wa('<br>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tool_config_params_sec: '||SQLERRM);
  END tool_config_params_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private cursor_sharing_sec
   *
   * ------------------------- */
  PROCEDURE cursor_sharing_sec
  IS
    l_row_count NUMBER;
    l_shared NUMBER := 0;
    l_not_shared NUMBER := 0;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('cursor_sharing_sec');
    wa(h2(mot('Cursor Sharing', 'GV$SQL_SHARED_CURSOR'), 'cursor_sharing'));
    wa('<ul>');
    wa(li(mot('Cursor Sharing Summary', 'GV$SQL and GV$SQL_SHARED_CURSOR', '#cs_summary')));
    wa(li(mot('Reasons for not Sharing', 'GV$SQL_SHARED_CURSOR', '#cs_reasons')));
    wa(li(mot('List of Cursors', 'GV$SQL and GV$SQL_SHARED_CURSOR', '#cs_cursors')));
    wa('</ul>');
    wa(go_to_sec('Plans Summary', 'pln_sum'));
    wa(go_to_top);

    wa(h3(mot('Cursor Sharing Summary', 'GV$SQL and GV$SQL_SHARED_CURSOR'), 'cs_summary', FALSE));
    wa('List grouped by instance.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT inst_id,
                     SUM(shared) shared,
                     SUM(not_shared) not_shared,
                     COUNT(*) total
                FROM sqlt$_sql_shared_cursor_v
               WHERE statement_id = s_sql_rec.statement_id
               GROUP BY
                     inst_id
               ORDER BY
                     inst_id)
    LOOP
      l_row_count := l_row_count + 1;
      l_shared := l_shared + i.shared;
      l_not_shared := l_not_shared + i.not_shared;

      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Inst ID'));
        wa(th('Sharable<br>Cursors'));
        wa(th('Cursors<br>not Shared'));
        wa(th('Total'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.inst_id));
      wa(td(i.shared, 'r'));
      wa(td(i.not_shared, 'r'));
      wa(td(i.total, 'r'));
      wa('</tr>');
    END LOOP;

    IF l_row_count > 1 THEN
      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td('Total'));
      wa(td(l_shared, 'r'));
      wa(td(l_not_shared, 'r'));
      wa(td((l_shared + l_not_shared), 'r'));
      wa('</tr>');
    END IF;
    wa('</table>');

    wa(h3(mot('Reasons for not Sharing', 'GV$SQL_SHARED_CURSOR'), 'cs_reasons', FALSE));
    wa('List grouped by instance, phv and reasons for not sharing and ordered by count.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT COUNT(*) total,
                     inst_id,
                     plan_hash_value,
                     not_shared_reason
                FROM sqlt$_sql_shared_cursor_d
               WHERE statement_id = s_sql_rec.statement_id
               GROUP BY
                     inst_id,
                     plan_hash_value,
                     not_shared_reason
               ORDER BY
                     total DESC,
                     inst_id,
                     plan_hash_value,
                     not_shared_reason)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Cursors'));
        wa(th('Inst ID'));
        wa(th('Plan Hash Value'));
        wa(th('Reasons for not Sharing'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.total, 'r'));
      wa(td(i.inst_id));
      IF sqlt$a.get_plan_link(s_sql_rec.statement_id, i.plan_hash_value) IS NULL THEN
        wa(td(i.plan_hash_value, 'l', 'nowrap'));
      ELSE
        wa(td(a_phv(i.plan_hash_value, 'plan_'||sqlt$a.get_plan_link(s_sql_rec.statement_id, i.plan_hash_value)), 'l', 'nowrap'));
      END IF;
      wa(td(i.not_shared_reason, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');

    l_sql := '
SELECT inst_id,
       child_number,
       child_address,
       plan_hash_value,
       elapsed_time_secs,
       cpu_time_secs,
       user_io_time_secs,
       cluster_time_secs,
       concurrency_time_secs,
       application_time_secs,
       buffer_gets,
       disk_reads,
       direct_writes,
       rows_processed,
       executions,
       plan_timestamp,
       last_active_time,
       avg_elapsed_time_secs,
       avg_cpu_time_secs,
       avg_io_time_secs,
       avg_cluster_time_secs,
       avg_conc_time_secs,
       avg_appl_time_secs,
       avg_buffer_gets,
       avg_disk_reads,
       avg_direct_writes,
       avg_rows_processed,
       is_shareable,
       not_shared_reason,
       reason,
       sanitized_reason
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_sql_shared_cursor_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
 ORDER BY
       inst_id,
       child_number,
       child_address;';

    wa(h3(mot('List of Cursors', 'GV$SQL and GV$SQL_SHARED_CURSOR'), 'cs_cursors', FALSE));

    wa('List restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT inst_id,
                     child_number,
                     child_address,
                     is_obsolete,
                     plan_hash_value,
                     elapsed_time_secs,
                     cpu_time_secs,
                     user_io_time_secs,
                     cluster_time_secs,
                     concurrency_time_secs,
                     application_time_secs,
                     buffer_gets,
                     disk_reads,
                     direct_writes,
                     rows_processed,
                     executions,
                     plan_timestamp,
                     last_active_time,
                     avg_elapsed_time_secs,
                     avg_cpu_time_secs,
                     avg_io_time_secs,
                     avg_cluster_time_secs,
                     avg_conc_time_secs,
                     avg_appl_time_secs,
                     avg_buffer_gets,
                     avg_disk_reads,
                     avg_direct_writes,
                     avg_rows_processed,
                     is_shareable,
                     not_shared_reason,
                     reason,
                     sanitized_reason
                FROM sqlt$_sql_shared_cursor_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     inst_id,
                     child_number,
                     child_address)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Inst ID'));
        wa(th('Child'));
        wa(th('Child Address'));
        wa(th('Is<br>Obsolete'));
        wa(th('Plan Hash Value'));
        wa(th('Elapsed Time<br>in secs'));
        wa(th('CPU Time<br>in secs'));
        wa(th('User IO Time<br>in secs'));
        wa(th('Cluster Time<br>in secs'));
        wa(th('Concurrency Time<br>in secs'));
        wa(th('Application Time<br>in secs'));
        wa(th('Buffer Gets'));
        wa(th('Disk Reads'));
        wa(th('Direct Writes'));
        wa(th('Rows Processed'));
        wa(th('Executions'));
        wa(th('Plan Timestamp'));
        wa(th('Last Active Time'));
        wa(th('Avg<br>Elapsed Time<br>in secs'));
        wa(th('Avg<br>CPU Time<br>in secs'));
        wa(th('Avg<br>User IO Time<br>in secs'));
        wa(th('Avg<br>Cluster Time<br>in secs'));
        wa(th('Avg<br>Concurrency Time<br>in secs'));
        wa(th('Avg<br>Application Time<br>in secs'));
        wa(th('Avg<br>Buffer Gets'));
        wa(th('Avg<br>Disk Reads'));
        wa(th('Avg<br>Direct Writes'));
        wa(th('Avg<br>Rows Processed'));
        wa(th('Is<br>Sharable'));
        wa(th('Reasons for not Sharing'));
        wa(th('Reason'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.inst_id));
      wa(td(i.child_number));
      wa(td(i.child_address, 'l'));
      wa(td(i.is_obsolete));
      IF sqlt$a.get_plan_link(s_sql_rec.statement_id, i.plan_hash_value) IS NULL THEN
        wa(td(i.plan_hash_value, 'l', 'nowrap'));
      ELSE
        wa(td(a_phv(i.plan_hash_value, 'plan_'||sqlt$a.get_plan_link(s_sql_rec.statement_id, i.plan_hash_value)), 'l', 'nowrap'));
      END IF;
      wa(td(TO_CHAR(i.elapsed_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.cpu_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.user_io_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.cluster_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.concurrency_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.application_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(i.buffer_gets, 'r'));
      wa(td(i.disk_reads, 'r'));
      wa(td(i.direct_writes, 'r'));
      wa(td(i.rows_processed, 'r'));
      wa(td(i.executions, 'r'));
      wa(td(TO_CHAR(i.plan_timestamp, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_active_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.avg_elapsed_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.avg_cpu_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.avg_io_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.avg_cluster_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.avg_conc_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.avg_appl_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(i.avg_buffer_gets, 'r'));
      wa(td(i.avg_disk_reads, 'r'));
      wa(td(i.avg_direct_writes, 'r'));
      wa(td(i.avg_rows_processed, 'r'));
      wa(td(i.is_shareable));
      wa(td(i.not_shared_reason, 'l'));
      IF i.sanitized_reason IS NULL THEN
        wa(td(NBSP));
      ELSE
        wa_td_hide(i.sanitized_reason);
      END IF;
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Plans Summary', 'pln_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('cursor_sharing_sec: '||SQLERRM);
  END cursor_sharing_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private adaptive_cursor_sharing_sec
   *
   * ------------------------- */
  PROCEDURE adaptive_cursor_sharing_sec
  IS
    l_row_count NUMBER;
    l_shared NUMBER := 0;
    l_not_shared NUMBER := 0;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('adaptive_cursor_sharing_sec');
    wa(h2(mot('Adaptive Cursor Sharing', 'GV$SQL, GV$SQL_CS_HISTOGRAM, GV$SQL_CS_SELECTIVITY and GV$SQL_CS_STATISTICS'), 'adaptive_cursor_sharing'));
    wa('<ul>');
    wa(li(mot('Cursors List', 'GV$SQL', '#acs_cursors_list')));
    wa(li(mot('Histogram', 'GV$SQL_CS_HISTOGRAM', '#acs_history')));
    wa(li(mot('Selectivity', 'GV$SQL_CS_SELECTIVITY', '#acs_selectivity')));
    wa(li(mot('Statistics', 'GV$SQL_CS_STATISTICS', '#acs_statistics')));
    wa('</ul>');
    wa(go_to_sec('Plans Summary', 'pln_sum'));
    wa(go_to_top);

    l_sql := '
SELECT is_shareable,
       inst_id,
       child_number,
       child_address,
       plan_hash_value,
       is_bind_sensitive,
       is_bind_aware,
       buffer_gets,
       executions
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$sql
 WHERE statement_id = '||s_sql_rec.statement_id||'
 ORDER BY
       is_shareable DESC,
       inst_id,
       child_number DESC,
       child_address;';

    wa(h3(mot('Cursors List', 'GV$SQL'), 'acs_cursors_list', FALSE));

    wa('List restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT is_shareable,
                     inst_id,
                     child_number,
                     child_address,
                     plan_hash_value,
                     is_bind_sensitive,
                     is_bind_aware,
                     buffer_gets,
                     executions
                FROM sqlt$_gv$sql
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     is_shareable DESC,
                     inst_id,
                     child_number DESC,
                     child_address)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Is<br>Sharable'));
        wa(th('Inst ID'));
        wa(th('Child'));
        wa(th('Child Address'));
        wa(th('Plan Hash Value'));
        wa(th('Is<br>Bind<br>Sensitive'));
        wa(th('Is<br>Bind<br>Aware'));
        wa(th('Buffer Gets'));
        wa(th('Executions'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.is_shareable));
      wa(td(i.inst_id));
      wa(td(i.child_number));
      wa(td(i.child_address, 'l'));
      IF sqlt$a.get_plan_link(s_sql_rec.statement_id, i.plan_hash_value) IS NULL THEN
        wa(td(i.plan_hash_value, 'l', 'nowrap'));
      ELSE
        wa(td(a_phv(i.plan_hash_value, 'plan_'||sqlt$a.get_plan_link(s_sql_rec.statement_id, i.plan_hash_value)), 'l', 'nowrap'));
      END IF;
      wa(td(i.is_bind_sensitive));
      wa(td(i.is_bind_aware));
      wa(td(i.buffer_gets, 'r'));
      wa(td(i.executions, 'r'));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');

    l_sql := '
SELECT c.is_shareable,
       h.inst_id,
       h.child_number,
       h.bucket_id,
       h.count
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$sql_cs_histogram h,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$sql c
 WHERE h.statement_id = '||s_sql_rec.statement_id||'
   AND h.statement_id = c.statement_id
   AND h.inst_id = c.inst_id
   AND h.child_number = c.child_number
 ORDER BY
       c.is_shareable DESC,
       h.inst_id,
       h.child_number DESC,
       h.bucket_id;';

    wa(h3(mot('Histogram', 'GV$SQL_CS_HISTOGRAM'), 'acs_history', FALSE));

    wa('List restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT c.is_shareable,
                     h.inst_id,
                     h.child_number,
                     h.bucket_id,
                     h.count
                FROM sqlt$_gv$sql_cs_histogram h,
                     sqlt$_gv$sql c
               WHERE h.statement_id = s_sql_rec.statement_id
                 AND h.statement_id = c.statement_id
                 AND h.inst_id = c.inst_id
                 AND h.child_number = c.child_number
               ORDER BY
                     c.is_shareable DESC,
                     h.inst_id,
                     h.child_number DESC,
                     h.bucket_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Is<br>Sharable'));
        wa(th('Inst ID'));
        wa(th('Child'));
        wa(th('Bucket ID<sup>1</sup>'));
        wa(th('Count'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.is_shareable));
      wa(td(i.inst_id));
      wa(td(i.child_number));
      wa(td(i.bucket_id, 'r'));
      wa(td(i.count, 'r'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) Rows Processed. 0:'||LT||' 1K, 1:between 1K and 1M, 2:'||GT||' 1M.'));
    wa('<br>');

    l_sql := '
SELECT c.is_shareable,
       s.inst_id,
       s.child_number,
       s.predicate,
       s.low,
       s.high,
       s.range_id
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$sql_cs_selectivity s,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$sql c
 WHERE s.statement_id = '||s_sql_rec.statement_id||'
   AND s.statement_id = c.statement_id
   AND s.inst_id = c.inst_id
   AND s.child_number = c.child_number
 ORDER BY
       c.is_shareable DESC,
       s.inst_id,
       s.child_number DESC,
       s.predicate,
       s.low,
       s.range_id;';

    wa(h3(mot('Selectivity', 'GV$SQL_CS_SELECTIVITY'), 'acs_selectivity', FALSE));

    wa('List restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT c.is_shareable,
                     s.inst_id,
                     s.child_number,
                     s.predicate,
                     s.low,
                     s.high,
                     s.range_id
                FROM sqlt$_gv$sql_cs_selectivity s,
                     sqlt$_gv$sql c
               WHERE s.statement_id = s_sql_rec.statement_id
                 AND s.statement_id = c.statement_id
                 AND s.inst_id = c.inst_id
                 AND s.child_number = c.child_number
               ORDER BY
                     c.is_shareable DESC,
                     s.inst_id,
                     s.child_number DESC,
                     s.predicate,
                     s.low,
                     s.range_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Is<br>Sharable'));
        wa(th('Inst ID'));
        wa(th('Child'));
        wa(th('Predicate'));
        wa(th('Low'));
        wa(th('High'));
        wa(th('Range ID'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.is_shareable));
      wa(td(i.inst_id));
      wa(td(i.child_number));
      wa(td(i.predicate, 'l'));
      wa(td(i.low, 'r'));
      wa(td(i.high, 'r'));
      wa(td(i.range_id, 'r'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');

    l_sql := '
SELECT c.is_shareable,
       s.inst_id,
       s.child_number,
       s.bind_set_hash_value,
       s.peeked,
       s.executions,
       s.rows_processed,
       s.buffer_gets,
       s.cpu_time
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$sql_cs_statistics s,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$sql c
 WHERE s.statement_id = '||s_sql_rec.statement_id||'
   AND s.statement_id = c.statement_id
   AND s.inst_id = c.inst_id
   AND s.child_number = c.child_number
 ORDER BY
       c.is_shareable DESC,
       s.inst_id,
       s.child_number DESC;';

    wa(h3(mot('Statistics', 'GV$SQL_CS_STATISTICS'), 'acs_statistics', FALSE));

    wa('List restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT c.is_shareable,
                     s.inst_id,
                     s.child_number,
                     s.bind_set_hash_value,
                     s.peeked,
                     s.executions,
                     s.rows_processed,
                     s.buffer_gets,
                     s.cpu_time
                FROM sqlt$_gv$sql_cs_statistics s,
                     sqlt$_gv$sql c
               WHERE s.statement_id = s_sql_rec.statement_id
                 AND s.statement_id = c.statement_id
                 AND s.inst_id = c.inst_id
                 AND s.child_number = c.child_number
               ORDER BY
                     c.is_shareable DESC,
                     s.inst_id,
                     s.child_number DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Is<br>Sharable'));
        wa(th('Inst ID'));
        wa(th('Child'));
        wa(th('Bind Set<br>Hash Value'));
        wa(th('Peeked'));
        wa(th('Executions'));
        wa(th('Rows Processed'));
        wa(th('Buffer Gets'));
        wa(th('CPU Time'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.is_shareable));
      wa(td(i.inst_id));
      wa(td(i.child_number));
      wa(td(i.bind_set_hash_value, 'l'));
      wa(td(i.peeked));
      wa(td(i.executions, 'r'));
      wa(td(i.rows_processed, 'r'));
      wa(td(i.buffer_gets, 'r'));
      wa(td(i.cpu_time, 'r'));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');

    wa(go_to_sec('Plans Summary', 'pln_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('adaptive_cursor_sharing_sec: '||SQLERRM);
  END adaptive_cursor_sharing_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private peeked_binds_sum
   *
   * ------------------------- */
  PROCEDURE peeked_binds_sum (p_plan_hash_value IN NUMBER)
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('peeked_binds_sum_'||p_plan_hash_value);

    l_sql := '
SELECT name,
       type,
       values_peeked,
       non_null_values,
       distinct_values,
       minimum_value,
       DECODE(maximum_value, minimum_value, NULL, maximum_value) maximum_value
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_peeked_binds_sum_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND plan_hash_value = '||p_plan_hash_value||'
 ORDER BY
       name,
       type;';

    wa('Summary');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT name,
                     type,
                     values_peeked,
                     non_null_values,
                     distinct_values,
                     minimum_value,
                     DECODE(maximum_value, minimum_value, NULL, maximum_value) maximum_value
                FROM sqlt$_peeked_binds_sum_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND plan_hash_value = p_plan_hash_value
               ORDER BY
                     name,
                     type)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Type'));
        wa(th('Values Peeked'));
        wa(th('Non-null Values'));
        wa(th('Distinct Values'));
        wa(th('Minimum Value'));
        wa(th('Maximum Value<sup>1</sup>'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.type, 'l'));
      wa(td(i.values_peeked, 'r'));
      wa(td(i.non_null_values, 'r'));
      wa(td(i.distinct_values, 'r'));
      wa(td(i.minimum_value, 'l'));
      wa(td(i.maximum_value, 'l'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) Only if different than Minimum Value.'));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('peeked_binds_sum_'||p_plan_hash_value||': '||SQLERRM);
  END peeked_binds_sum;

  /*************************************************************************************/

  /* -------------------------
   *
   * private peeked_binds_sec
   *
   * ------------------------- */
  PROCEDURE peeked_binds_sec (
    p_plan_hash_value IN NUMBER,
    p_source          IN VARCHAR2 )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('peeked_binds_sec_'||p_plan_hash_value||'_'||p_source);

    l_sql := '
SELECT plan_timestamp,
       plan_id,
       inst_id,
       child_number,
       child_address,
       name,
       type,
       value
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_peeked_binds_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND source = '''||p_source||'''
   AND plan_hash_value = '||p_plan_hash_value||'
 ORDER BY
       plan_timestamp DESC,
       plan_id,
       inst_id,
       child_number,
       child_address,
       position;';

    wa('Source: '||p_source);
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<br>Details:');
    wa(hide_begin);
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT plan_timestamp,
                     plan_id,
                     inst_id,
                     child_number,
                     child_address,
                     name,
                     type,
                     value
                FROM sqlt$_peeked_binds_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND source = p_source
                 AND plan_hash_value = p_plan_hash_value
               ORDER BY
                     plan_timestamp DESC,
                     plan_id,
                     inst_id,
                     child_number,
                     child_address,
                     position)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan Timestamp'));
        IF p_source = 'DBA_SQLTUNE_PLANS' THEN
          wa(th('Plan ID'));
        ELSIF p_source = 'GV$SQL_PLAN' THEN
          wa(th('Inst ID'));
          wa(th('Child'));
          --wa(th('Child Address'));
        END IF;
        wa(th('Name'));
        wa(th('Type'));
        wa(th('Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(TO_CHAR(i.plan_timestamp, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      IF p_source = 'DBA_SQLTUNE_PLANS' THEN
        wa(td(i.plan_id));
      ELSIF p_source = 'GV$SQL_PLAN' THEN
        wa(td(i.inst_id));
        wa(td(i.child_number));
        --wa(td(i.child_address, 'l'));
      END IF;
      wa(td(i.name, 'l'));
      wa(td(i.type, 'l'));
      wa(td(i.value, 'l'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(show_hide_end);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('peeked_binds_sec_'||p_plan_hash_value||'_'||p_source||': '||SQLERRM);
  END peeked_binds_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private peeked_binds_sec
   *
   * ------------------------- */
  PROCEDURE peeked_binds_sec
  IS
    l_row_count NUMBER;
    l_plan_flags sqlt$_plan_header_v.plan_flags%TYPE;
  BEGIN
    write_log('peeked_binds_sec');
    wa(h2(mot('Peeked Binds', 'GV$SQL_PLAN.OTHER_XML, DBA_HIST_SQL_PLAN.OTHER_XML and DBA_SQLTUNE_PLANS.OTHER_XML'), 'peeked_binds'));

    wa('Lists of peeked binds are restricted up to '||s_rows_table_l||' per phv as per tool parameter "r_rows_table_l".');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT DISTINCT plan_hash_value
                FROM sqlt$_peeked_binds_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN', 'DBA_SQLTUNE_PLANS')
               ORDER BY
                     plan_hash_value)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan Hash Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(a_phv(i.plan_hash_value, 'peeked_binds_'||i.plan_hash_value), 'l', 'nowrap'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Captured Binds', 'captured_binds'));
    wa(go_to_sec('Plans Summary', 'pln_sum'));
    wa(go_to_top);

    FOR i IN (SELECT DISTINCT plan_hash_value
                FROM sqlt$_peeked_binds_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN', 'DBA_SQLTUNE_PLANS')
               ORDER BY
                     plan_hash_value)
    LOOP
      l_row_count := 0;
      l_plan_flags := get_plan_flags(i.plan_hash_value);
      FOR j IN (SELECT DISTINCT source
                  FROM sqlt$_peeked_binds_v
                 WHERE statement_id = s_sql_rec.statement_id
                   AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN', 'DBA_SQLTUNE_PLANS')
                   AND plan_hash_value = i.plan_hash_value
                 ORDER BY
                       DECODE(source,
                       'GV$SQL_PLAN', 1,
                       'DBA_HIST_SQL_PLAN', 2,
                       'DBA_SQLTUNE_PLANS', 4, 9))
      LOOP
        l_row_count := l_row_count + 1;
        IF l_row_count = 1 THEN
          wa(h4('Peeked Binds for '||i.plan_hash_value||l_plan_flags, 'peeked_binds_'||i.plan_hash_value));
          wa_sql_text_show_hide;
          wa('<table><tr>');
          -- peeked binds summary
          wa('<td class="lw">');
          peeked_binds_sum(i.plan_hash_value);
          wa('</td>');
        END IF;
        wa('<td class="lw">');
        peeked_binds_sec(i.plan_hash_value, j.source);
        wa('</td>');
      END LOOP;

      IF l_row_count > 0 THEN
        wa('</tr></table>');
        wa(go_to_sec('Captured Binds', 'captured_binds_'||i.plan_hash_value));
        wa(go_to_sec('Peeked Binds', 'peeked_binds'));
        wa(go_to_sec('Plans Summary', 'pln_sum'));
        wa(go_to_top);
      END IF;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('peeked_binds_sec: '||SQLERRM);
  END peeked_binds_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private captured_binds_sum
   *
   * ------------------------- */
  PROCEDURE captured_binds_sum (p_plan_hash_value IN NUMBER)
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('captured_binds_sum_'||p_plan_hash_value);

    l_sql := '
SELECT name,
       type,
       values_captured,
       non_null_values,
       distinct_values,
       minimum_value,
       DECODE(maximum_value, minimum_value, NULL, maximum_value) maximum_value
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_captured_binds_sum_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND plan_hash_value = '||p_plan_hash_value||'
 ORDER BY
       name,
       type;';

    wa('Summary');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT name,
                     type,
                     values_captured,
                     non_null_values,
                     distinct_values,
                     minimum_value,
                     DECODE(maximum_value, minimum_value, NULL, maximum_value) maximum_value
                FROM sqlt$_captured_binds_sum_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND plan_hash_value = p_plan_hash_value
               ORDER BY
                     name,
                     type)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Type'));
        wa(th('Values Captured'));
        wa(th('Non-null Values'));
        wa(th('Distinct Values'));
        wa(th('Minimum Value'));
        wa(th('Maximum Value<sup>1</sup>'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.type, 'l'));
      wa(td(i.values_captured, 'r'));
      wa(td(i.non_null_values, 'r'));
      wa(td(i.distinct_values, 'r'));
      wa(td(i.minimum_value, 'l'));
      wa(td(i.maximum_value, 'l'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) Only if different than Minimum Value.'));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('captured_binds_sum_'||p_plan_hash_value||': '||SQLERRM);
  END captured_binds_sum;

  /*************************************************************************************/

  /* -------------------------
   *
   * private captured_binds_sec
   *
   * ------------------------- */
  PROCEDURE captured_binds_sec (
    p_plan_hash_value IN NUMBER,
    p_source          IN VARCHAR2 )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('captured_binds_sec_'||p_plan_hash_value||'_'||p_source);

    l_sql := '
SELECT last_captured,
       inst_id, -- only for GV$SQL_PLAN
       child_number, -- only for GV$SQL_PLAN
       child_address, -- only for GV$SQL_PLAN
       name,
       type,
       value
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_captured_binds_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND source = '''||p_source||'''
   AND plan_hash_value = '||p_plan_hash_value||'
 ORDER BY
       last_captured DESC,
       inst_id, -- only for GV$SQL_PLAN
       child_number, -- only for GV$SQL_PLAN
       child_address, -- only for GV$SQL_PLAN
       position;';

    wa('Source: '||p_source);
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<br>Details:');
    wa(hide_begin);
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT last_captured,
                     inst_id, -- only for GV$SQL_PLAN
                     child_number, -- only for GV$SQL_PLAN
                     child_address, -- only for GV$SQL_PLAN
                     name,
                     type,
                     value
                FROM sqlt$_captured_binds_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND source = p_source
                 AND plan_hash_value = p_plan_hash_value
               ORDER BY
                     last_captured DESC,
                     inst_id, -- only for GV$SQL_PLAN
                     child_number, -- only for GV$SQL_PLAN
                     child_address, -- only for GV$SQL_PLAN
                     position)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Last Captured'));
        IF p_source = 'GV$SQL_PLAN' THEN
          wa(th('Inst ID'));
          wa(th('Child'));
          --wa(th('Child Address'));
        END IF;
        wa(th('Name'));
        wa(th('Type'));
        wa(th('Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(TO_CHAR(i.last_captured, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      IF p_source = 'GV$SQL_PLAN' THEN
        wa(td(i.inst_id));
        wa(td(i.child_number));
        --wa(td(i.child_address, 'l'));
      END IF;
      wa(td(i.name, 'l'));
      wa(td(i.type, 'l'));
      wa(td(i.value, 'l'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(show_hide_end);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('captured_binds_sec_'||p_plan_hash_value||'_'||p_source||': '||SQLERRM);
  END captured_binds_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private captured_binds_sec
   *
   * ------------------------- */
  PROCEDURE captured_binds_sec
  IS
    l_row_count NUMBER;
    l_plan_flags sqlt$_plan_header_v.plan_flags%TYPE;
  BEGIN
    write_log('captured_binds_sec');
    wa(h2(mot('Captured Binds', 'GV$SQL_BIND_CAPTURE and DBA_HIST_SQLBIND'), 'captured_binds'));

    wa('Lists of captured binds are restricted up to '||s_rows_table_l||' per phv as per tool parameter "r_rows_table_l".');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT DISTINCT plan_hash_value
                FROM sqlt$_captured_binds_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN')
               ORDER BY
                     plan_hash_value)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan Hash Value'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(a_phv(i.plan_hash_value, 'captured_binds_'||i.plan_hash_value), 'l', 'nowrap'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Peeked Binds', 'peeked_binds'));
    wa(go_to_sec('Plans Summary', 'pln_sum'));
    wa(go_to_top);

    FOR i IN (SELECT DISTINCT plan_hash_value
                FROM sqlt$_captured_binds_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN')
               ORDER BY
                     plan_hash_value)
    LOOP
      l_row_count := 0;
      l_plan_flags := get_plan_flags(i.plan_hash_value);
      FOR j IN (SELECT DISTINCT source
                  FROM sqlt$_captured_binds_v
                 WHERE statement_id = s_sql_rec.statement_id
                   AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN')
                   AND plan_hash_value = i.plan_hash_value
                 ORDER BY
                       DECODE(source,
                       'GV$SQL_PLAN', 1,
                       'DBA_HIST_SQL_PLAN', 2, 9))
      LOOP
        l_row_count := l_row_count + 1;
        IF l_row_count = 1 THEN
          wa(h4('Captured Binds for '||i.plan_hash_value||l_plan_flags, 'captured_binds_'||i.plan_hash_value));
          wa_sql_text_show_hide;
          wa('<table><tr>');
          -- captured binds summary
          wa('<td class="lw">');
          captured_binds_sum(i.plan_hash_value);
          wa('</td>');
        END IF;
        wa('<td class="lw">');
        captured_binds_sec(i.plan_hash_value, j.source);
        wa('</td>');
      END LOOP;

      IF l_row_count > 0 THEN
        wa('</tr></table>');
        wa(go_to_sec('Peeked Binds', 'peeked_binds_'||i.plan_hash_value));
        wa(go_to_sec('Captured Binds', 'captured_binds'));
        wa(go_to_sec('Plans Summary', 'pln_sum'));
        wa(go_to_top);
      END IF;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('captured_binds_sec: '||SQLERRM);
  END captured_binds_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private act_sess_hist_sec
   *
   * ------------------------- */
  PROCEDURE act_sess_hist_sec
  IS
    l_row_count NUMBER;
    l_row_count1 NUMBER;
    l_row_count2 NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('act_sess_hist_sec');
    wa(h2(mot('Active Session History', 'GV$ACTIVE_SESSION_HISTORY'), 'act_sess_hist'));
    wa('<ul>');
    wa(li(mot('Active Session History by Plan', 'GV$ACTIVE_SESSION_HISTORY', '#act_sess_hist_p')));
    wa(li(mot('Active Session History by Plan Line', 'GV$ACTIVE_SESSION_HISTORY', '#act_sess_hist_pl')));
    wa(li(mot('Active Session History by Session', 'GV$ACTIVE_SESSION_HISTORY', '#act_sess_hist_s')));
    wa('</ul>');
    wa(go_to_top);

    l_sql := '
SELECT h.sql_plan_hash_value,
       h.session_state,
       h.wait_class,
       h.event,
       h.snaps_count
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_gv$act_sess_hist_p_v h
 WHERE h.statement_id = '||s_sql_rec.statement_id||'
 ORDER BY
       h.sql_plan_hash_value,
       h.snaps_count DESC,
       h.session_state,
       h.wait_class,
       h.event;';

    wa(h3(mot('Active Session History by Plan', 'GV$ACTIVE_SESSION_HISTORY'), 'act_sess_hist_p', FALSE));
    wa('List below is restricted up to '||s_rows_table_m||' recent plan lines (as per tool parameter "r_rows_table_m").');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');

    l_row_count := 0;
    FOR i IN (SELECT h.sql_plan_hash_value,
                     h.session_state,
                     h.wait_class,
                     h.event,
                     h.snaps_count
                FROM sqlt$_gv$act_sess_hist_p_v h
               WHERE h.statement_id = s_sql_rec.statement_id
               ORDER BY
                     h.sql_plan_hash_value,
                     h.snaps_count DESC,
                     h.session_state,
                     h.wait_class,
                     h.event)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan<br>Hash<br>Value'));
        wa(th('Session<br>State'));
        wa(th('Wait<br>Class'));
        wa(th('Event'));
        wa(th('Snaps<br>Count'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.sql_plan_hash_value, 'r'));
      wa(td(i.session_state));
      wa(td(i.wait_class));
      wa(td(i.event, 'l'));
      wa(td(i.snaps_count, 'r'));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;

    wa('</table>');

    l_sql := '
SELECT h.sql_plan_hash_value,
       h.sql_plan_line_id,
       h.sql_plan_operation,
       h.sql_plan_options,
       h.object_owner,
       h.object_name,
       h.session_state,
       h.wait_class,
       h.event,
       h.current_obj#,
       h.current_obj_name,
       h.snaps_count
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_gv$act_sess_hist_pl_v h
 WHERE h.statement_id = '||s_sql_rec.statement_id||'
   AND h.sql_plan_line_id > 0
 ORDER BY
       h.sql_plan_hash_value,
       h.sql_plan_line_id,
       h.snaps_count DESC,
       h.session_state,
       h.wait_class,
       h.event,
       h.current_obj#;';

    wa(h3(mot('Active Session History by Plan Line', 'GV$ACTIVE_SESSION_HISTORY'), 'act_sess_hist_pl', FALSE));
    wa('List below is restricted up to '||s_rows_table_l||' recent plan lines (as per tool parameter "r_rows_table_l").');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');

    l_row_count := 0;
    FOR i IN (SELECT h.*
                FROM sqlt$_gv$act_sess_hist_pl_v h
               WHERE h.statement_id = s_sql_rec.statement_id
                 AND h.sql_plan_line_id > 0
               ORDER BY
                     h.sql_plan_hash_value,
                     h.sql_plan_line_id,
                     h.snaps_count DESC,
                     h.session_state,
                     h.wait_class,
                     h.event,
                     h.current_obj#)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan<br>Hash<br>Value'));
        wa(th('Plan<br>Line<br>ID'));
        wa(th('Plan<br>Operation'));
        wa(th('Plan<br>Options'));
        wa(th('Plan<br>Object<br>Owner'));
        wa(th('Plan<br>Object<br>Name'));
        wa(th('Session<br>State'));
        wa(th('Wait<br>Class'));
        wa(th('Event'));
        wa(th('Curr<br>Obj<br>ID'));
        wa(th('Curr<br>Object<br>Name'));
        wa(th('Snaps<br>Count'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.sql_plan_hash_value, 'r'));
      wa(td(i.sql_plan_line_id, 'r'));
      wa(td(i.sql_plan_operation, 'l'));
      wa(td(i.sql_plan_options, 'l'));
      wa(td(i.object_owner, 'l'));
      wa(td(i.object_name, 'l'));
      wa(td(i.session_state));
      wa(td(i.wait_class));
      wa(td(i.event, 'l'));
      wa(td(i.current_obj#, 'r'));
      wa(td(i.current_obj_name, 'l'));
      wa(td(i.snaps_count, 'r'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;

    wa('</table>');

    l_sql := '
SELECT h.*
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$active_session_histor h
 WHERE h.statement_id = '||s_sql_rec.statement_id||';';

    wa(h3(mot('Active Session History by Session', 'GV$ACTIVE_SESSION_HISTORY'), 'act_sess_hist_s', FALSE));
    wa('List below is restricted up to '||(s_rows_table_xs * 2)||' recent sessions (as per 2x tool parameter "r_rows_table_xs") and up to '||(s_rows_table_xs * 2)||' snapshots per session (as per 2x tool parameter "r_rows_table_xs").');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');

    l_row_count := 0;
    l_row_count1 := 0;
    FOR i IN (SELECT MAX(h.sample_time) sample_time,
                     h.inst_id,
                     h.session_id,
                     h.session_serial#
                FROM sqlt$_gv$active_session_histor h
               WHERE h.statement_id = s_sql_rec.statement_id
               GROUP BY
                     h.inst_id,
                     h.session_id,
                     h.session_serial#
               ORDER BY
                     1 DESC,
                     2, 3, 4)
    LOOP
      l_row_count1 := l_row_count1 + 1;

      l_row_count2 := 0;
      FOR j IN (SELECT h.*
                  FROM sqlt$_gv$active_session_histor h
                 WHERE h.statement_id = s_sql_rec.statement_id
                   AND h.inst_id = i.inst_id
                   AND h.session_id = i.session_id
                   AND h.session_serial# = i.session_serial#
                 ORDER BY
                       h.sample_time DESC)
      LOOP
        l_row_count := l_row_count + 1;
        l_row_count2 := l_row_count2 + 1;
        IF MOD(l_row_count2, TITLE_REPEAT_RATE) = 1 THEN
          wa('<tr>');
          wa(th('#'));
          wa(th('Inst ID'));
          wa(th('SID'));
          wa(th('Serial#'));
          wa(th('Sample Time'));
          wa(th('SQL Exec Start'));
          wa(th('Is SQL_ID Current'));
          wa(th('SQL Child Num'));
          wa(th('Force Matching Signature'));
          wa(th('SQL Plan Hash Value'));
          wa(th('SQL Plan Line ID'));
          wa(th('SQL Plan Operation'));
          wa(th('SQL Plan Options'));
          wa(th('Event'));
          wa(th('P1 Text'));
          wa(th('P1'));
          wa(th('P2 Text'));
          wa(th('P2'));
          wa(th('P3 Text'));
          wa(th('P3'));
          wa(th('Wait Class'));
          wa(th('Wait Time'));
          wa(th('Session State'));
          wa(th('Time Waited'));
          wa(th('Blocking Session Status'));
          wa(th('Blocking SID'));
          wa(th('Blocking Serial#'));
          wa(th('Blocking Inst ID'));
          wa(th('Blocking Hang Chain Info'));
          wa(th('Current Obj#'));
          wa(th('Current File#'));
          wa(th('Current Block#'));
          wa(th('Current Row#'));
          wa(th('Remote Inst#'));
          wa(th('Program'));
          wa(th('Module'));
          wa(th('Action'));
          wa(th('Client ID'));
          wa(th('Machine'));
          wa(th('TM Delta Time'));
          wa(th('TM Delta CPU Time'));
          wa(th('TM Delta DB Time'));
          wa(th('Delta Time'));
          wa(th('Delta Read I/O Requests'));
          wa(th('Delta Write I/O Requests'));
          wa(th('Delta Read I/O Bytes'));
          wa(th('Delta Write I/O Bytes'));
          wa(th('Delta Inter Connect I/O Bytes'));
          wa(th('PGA Allocated'));
          wa(th('Temp Space Allocated'));
          wa('</tr>');
        END IF;

        wa('<tr>');
        wa(td(l_row_count, 'rt'));
        wa(td(j.inst_id));
        wa(td(j.session_id));
        wa(td(j.session_serial#));
        wa(td(TO_CHAR(j.sample_time, TIMESTAMP_FORMAT3), 'c', 'nowrap'));
        wa(td(TO_CHAR(j.sql_exec_start, LOAD_DATE_FORMAT), 'c', 'nowrap'));
        wa(td(j.is_sqlid_current));
        wa(td(j.sql_child_number));
        wa(td(j.force_matching_signature, 'r'));
        wa(td(j.sql_plan_hash_value, 'r'));
        wa(td(j.sql_plan_line_id, 'r'));
        wa(td(j.sql_plan_operation, 'l'));
        wa(td(j.sql_plan_options, 'l'));
        wa(td(j.event, 'l'));
        wa(td(j.p1text, 'l'));
        wa(td(j.p1, 'r'));
        wa(td(j.p2text, 'l'));
        wa(td(j.p2, 'r'));
        wa(td(j.p3text, 'l'));
        wa(td(j.p3, 'r'));
        wa(td(j.wait_class));
        wa(td(j.wait_time, 'r'));
        wa(td(j.session_state));
        wa(td(j.time_waited, 'r'));
        wa(td(j.blocking_session_status));
        wa(td(j.blocking_session));
        wa(td(j.blocking_session_serial#));
        wa(td(j.blocking_inst_id));
        wa(td(j.blocking_hangchain_info));
        wa(td(j.current_obj#, 'r'));
        wa(td(j.current_file#, 'r'));
        wa(td(j.current_block#, 'r'));
        wa(td(j.current_row#, 'r'));
        wa(td(j.remote_instance#));
        wa(td(j.program));
        wa(td(j.module));
        wa(td(j.action));
        wa(td(j.client_id));
        wa(td(j.machine));
        wa(td(j.tm_delta_time, 'r'));
        wa(td(j.tm_delta_cpu_time, 'r'));
        wa(td(j.tm_delta_db_time, 'r'));
        wa(td(j.delta_time, 'r'));
        wa(td(j.delta_read_io_requests, 'r'));
        wa(td(j.delta_write_io_requests, 'r'));
        wa(td(j.delta_read_io_bytes, 'r'));
        wa(td(j.delta_write_io_bytes, 'r'));
        wa(td(j.delta_interconnect_io_bytes, 'r'));
        wa(td(j.pga_allocated, 'r'));
        wa(td(j.temp_space_allocated, 'r'));
        wa('</tr>');

        IF l_row_count2 = (s_rows_table_xs * 2) THEN
          EXIT;
        END IF;
      END LOOP;

      IF l_row_count1 = (s_rows_table_xs * 2) THEN
        EXIT;
      END IF;
    END LOOP;

    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('act_sess_hist_sec: '||SQLERRM);
  END act_sess_hist_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private dba_hist_act_sess_hist_sec
   *
   * ------------------------- */
  PROCEDURE dba_hist_act_sess_hist_sec
  IS
    l_row_count NUMBER;
    l_row_count1 NUMBER;
    l_row_count2 NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('dba_hist_act_sess_hist_sec');
    wa(h2(mot('AWR Active Session History', 'DBA_HIST_ACTIVE_SESS_HISTORY'), 'dba_hist_act_sess_hist'));
    wa('<ul>');
    wa(li(mot('AWR Active Session History by Plan', 'DBA_HIST_ACTIVE_SESS_HISTORY', '#dba_hist_act_sess_hist_p')));
    wa(li(mot('AWR Active Session History by Plan Line', 'DBA_HIST_ACTIVE_SESS_HISTORY', '#dba_hist_act_sess_hist_pl')));
    wa(li(mot('AWR Active Session History by Session', 'DBA_HIST_ACTIVE_SESS_HISTORY', '#dba_hist_act_sess_hist_s')));
    wa('</ul>');
    wa(go_to_top);

    l_sql := '
SELECT h.sql_plan_hash_value,
       h.session_state,
       h.wait_class,
       h.event,
       h.snaps_count
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_act_sess_hist_p_v h
 WHERE h.statement_id = '||s_sql_rec.statement_id||'
 ORDER BY
       h.sql_plan_hash_value,
       h.snaps_count DESC,
       h.session_state,
       h.wait_class,
       h.event;';

    wa(h3(mot('AWR Active Session History by Plan', 'DBA_HIST_ACTIVE_SESS_HISTORY'), 'dba_hist_act_sess_hist_p', FALSE));
    wa('List below is restricted up to '||s_rows_table_m||' recent plan lines (as per tool parameter "r_rows_table_m").');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');

    l_row_count := 0;
    FOR i IN (SELECT h.sql_plan_hash_value,
                     h.session_state,
                     h.wait_class,
                     h.event,
                     h.snaps_count
                FROM sqlt$_dba_act_sess_hist_p_v h
               WHERE h.statement_id = s_sql_rec.statement_id
               ORDER BY
                     h.sql_plan_hash_value,
                     h.snaps_count DESC,
                     h.session_state,
                     h.wait_class,
                     h.event)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan<br>Hash<br>Value'));
        wa(th('Session<br>State'));
        wa(th('Wait<br>Class'));
        wa(th('Event'));
        wa(th('Snaps<br>Count'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.sql_plan_hash_value, 'r'));
      wa(td(i.session_state));
      wa(td(i.wait_class));
      wa(td(i.event, 'l'));
      wa(td(i.snaps_count, 'r'));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;

    wa('</table>');

    l_sql := '
SELECT h.sql_plan_hash_value,
       h.sql_plan_line_id,
       h.sql_plan_operation,
       h.sql_plan_options,
       h.object_owner,
       h.object_name,
       h.session_state,
       h.wait_class,
       h.event,
       h.current_obj#,
       h.current_obj_name,
       h.snaps_count
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_act_sess_hist_pl_v h
 WHERE h.statement_id = '||s_sql_rec.statement_id||'
   AND h.sql_plan_line_id > 0
 ORDER BY
       h.sql_plan_hash_value,
       h.sql_plan_line_id,
       h.snaps_count DESC,
       h.session_state,
       h.wait_class,
       h.event,
       h.current_obj#;';

    wa(h3(mot('AWR Active Session History by Plan Line', 'DBA_HIST_ACTIVE_SESS_HISTORY'), 'dba_hist_act_sess_hist_pl', FALSE));
    wa('List below is restricted up to '||s_rows_table_l||' recent plan lines (as per tool parameter "r_rows_table_l").');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');

    l_row_count := 0;
    FOR i IN (SELECT h.sql_plan_hash_value,
                     h.sql_plan_line_id,
                     h.sql_plan_operation,
                     h.sql_plan_options,
                     h.object_owner,
                     h.object_name,
                     h.session_state,
                     h.wait_class,
                     h.event,
                     h.current_obj#,
                     h.current_obj_name,
                     h.snaps_count
                FROM sqlt$_dba_act_sess_hist_pl_v h
               WHERE h.statement_id = s_sql_rec.statement_id
                 AND h.sql_plan_line_id > 0
               ORDER BY
                     h.sql_plan_hash_value,
                     h.sql_plan_line_id,
                     h.snaps_count DESC,
                     h.session_state,
                     h.wait_class,
                     h.event,
                     h.current_obj#)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan<br>Hash<br>Value'));
        wa(th('Plan<br>Line<br>ID'));
        wa(th('Plan<br>Operation'));
        wa(th('Plan<br>Options'));
        wa(th('Plan<br>Object<br>Owner'));
        wa(th('Plan<br>Object<br>Name'));
        wa(th('Session<br>State'));
        wa(th('Wait<br>Class'));
        wa(th('Event'));
        wa(th('Curr<br>Obj<br>ID'));
        wa(th('Curr<br>Object<br>Name'));
        wa(th('Snaps<br>Count'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.sql_plan_hash_value, 'r'));
      wa(td(i.sql_plan_line_id, 'r'));
      wa(td(i.sql_plan_operation, 'l'));
      wa(td(i.sql_plan_options, 'l'));
      wa(td(i.object_owner, 'l'));
      wa(td(i.object_name, 'l'));
      wa(td(i.session_state));
      wa(td(i.wait_class));
      wa(td(i.event, 'l'));
      wa(td(i.current_obj#, 'r'));
      wa(td(i.current_obj_name, 'l'));
      wa(td(i.snaps_count, 'r'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;

    wa('</table>');

    l_sql := '
SELECT h.*
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_hist_active_sess_his h
 WHERE h.statement_id = '||s_sql_rec.statement_id||';';

    wa(h3(mot('AWR Active Session History by Session', 'DBA_HIST_ACTIVE_SESS_HISTORY'), 'dba_hist_act_sess_hist_s', FALSE));
    wa('List below is restricted up to '||(s_rows_table_xs * 2)||' historical sessions (as per 2x tool parameter "r_rows_table_xs") and up to '||(s_rows_table_xs * 2)||' snapshots per session (as per 2x tool parameter "r_rows_table_xs").');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');

    l_row_count := 0;
    l_row_count1 := 0;
    FOR i IN (SELECT MAX(h.sample_time) sample_time,
                     h.instance_number,
                     h.session_id,
                     h.session_serial#
                FROM sqlt$_dba_hist_active_sess_his h
               WHERE h.statement_id = s_sql_rec.statement_id
               GROUP BY
                     h.instance_number,
                     h.session_id,
                     h.session_serial#
               ORDER BY
                     1 DESC,
                     2, 3, 4)
    LOOP
      l_row_count1 := l_row_count1 + 1;

      l_row_count2 := 0;
      FOR j IN (SELECT DISTINCT h.* -- DISTINCT is needed since same record could be captured by more than one AWR snapshot
                  FROM sqlt$_dba_hist_active_sess_his h
                 WHERE h.statement_id = s_sql_rec.statement_id
                   AND h.instance_number = i.instance_number
                   AND h.session_id = i.session_id
                   AND h.session_serial# = i.session_serial#
                 ORDER BY
                       h.sample_time DESC)
      LOOP
        l_row_count := l_row_count + 1;
        l_row_count2 := l_row_count2 + 1;
        IF MOD(l_row_count2, TITLE_REPEAT_RATE) = 1 THEN
          wa('<tr>');
          wa(th('#'));
          wa(th('Inst ID'));
          wa(th('SID'));
          wa(th('Serial#'));
          wa(th('Sample Time'));
          wa(th('SQL Exec Start'));
          wa(th('Is SQL_ID Current'));
          wa(th('SQL Child Num'));
          wa(th('Force Matching Signature'));
          wa(th('SQL Plan Hash Value'));
          wa(th('SQL Plan Line ID'));
          wa(th('SQL Plan Operation'));
          wa(th('SQL Plan Options'));
          wa(th('Event'));
          wa(th('P1 Text'));
          wa(th('P1'));
          wa(th('P2 Text'));
          wa(th('P2'));
          wa(th('P3 Text'));
          wa(th('P3'));
          wa(th('Wait Class'));
          wa(th('Wait Time'));
          wa(th('Session State'));
          wa(th('Time Waited'));
          wa(th('Blocking Session Status'));
          wa(th('Blocking SID'));
          wa(th('Blocking Serial#'));
          wa(th('Blocking Inst ID'));
          wa(th('Blocking Hang Chain Info'));
          wa(th('Current Obj#'));
          wa(th('Current File#'));
          wa(th('Current Block#'));
          wa(th('Current Row#'));
          wa(th('Remote Inst#'));
          wa(th('Program'));
          wa(th('Module'));
          wa(th('Action'));
          wa(th('Client ID'));
          wa(th('Machine'));
          wa(th('TM Delta Time'));
          wa(th('TM Delta CPU Time'));
          wa(th('TM Delta DB Time'));
          wa(th('Delta Time'));
          wa(th('Delta Read I/O Requests'));
          wa(th('Delta Write I/O Requests'));
          wa(th('Delta Read I/O Bytes'));
          wa(th('Delta Write I/O Bytes'));
          wa(th('Delta Inter Connect I/O Bytes'));
          wa(th('PGA Allocated'));
          wa(th('Temp Space Allocated'));
          wa('</tr>');
        END IF;

        wa('<tr>');
        wa(td(l_row_count, 'rt'));
        wa(td(j.instance_number));
        wa(td(j.session_id));
        wa(td(j.session_serial#));
        wa(td(TO_CHAR(j.sample_time, TIMESTAMP_FORMAT3), 'c', 'nowrap'));
        wa(td(TO_CHAR(j.sql_exec_start, LOAD_DATE_FORMAT), 'c', 'nowrap'));
        wa(td(j.is_sqlid_current));
        wa(td(j.sql_child_number));
        wa(td(j.force_matching_signature, 'r'));
        wa(td(j.sql_plan_hash_value, 'r'));
        wa(td(j.sql_plan_line_id, 'r'));
        wa(td(j.sql_plan_operation, 'l'));
        wa(td(j.sql_plan_options, 'l'));
        wa(td(j.event, 'l'));
        wa(td(j.p1text, 'l'));
        wa(td(j.p1, 'r'));
        wa(td(j.p2text, 'l'));
        wa(td(j.p2, 'r'));
        wa(td(j.p3text, 'l'));
        wa(td(j.p3, 'r'));
        wa(td(j.wait_class));
        wa(td(j.wait_time, 'r'));
        wa(td(j.session_state));
        wa(td(j.time_waited, 'r'));
        wa(td(j.blocking_session_status));
        wa(td(j.blocking_session));
        wa(td(j.blocking_session_serial#));
        wa(td(j.blocking_inst_id));
        wa(td(j.blocking_hangchain_info));
        wa(td(j.current_obj#, 'r'));
        wa(td(j.current_file#, 'r'));
        wa(td(j.current_block#, 'r'));
        wa(td(j.current_row#, 'r'));
        wa(td(j.remote_instance#));
        wa(td(j.program));
        wa(td(j.module));
        wa(td(j.action));
        wa(td(j.client_id));
        wa(td(j.machine));
        wa(td(j.tm_delta_time, 'r'));
        wa(td(j.tm_delta_cpu_time, 'r'));
        wa(td(j.tm_delta_db_time, 'r'));
        wa(td(j.delta_time, 'r'));
        wa(td(j.delta_read_io_requests, 'r'));
        wa(td(j.delta_write_io_requests, 'r'));
        wa(td(j.delta_read_io_bytes, 'r'));
        wa(td(j.delta_write_io_bytes, 'r'));
        wa(td(j.delta_interconnect_io_bytes, 'r'));
        wa(td(j.pga_allocated, 'r'));
        wa(td(j.temp_space_allocated, 'r'));
        wa('</tr>');

        IF l_row_count2 = (s_rows_table_xs * 2) THEN
          EXIT;
        END IF;
      END LOOP;

      IF l_row_count1 = (s_rows_table_xs * 2) THEN
        EXIT;
      END IF;
    END LOOP;

    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('dba_hist_act_sess_hist_sec: '||SQLERRM);
  END dba_hist_act_sess_hist_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private sql_stats_sec
   *
   * ------------------------- */
  PROCEDURE sql_stats_sec (
    p_plan_hash_value IN NUMBER,
    p_inst_id         IN NUMBER,
    p_child_number    IN NUMBER,
    p_child_address   IN VARCHAR2,
    p_address         IN VARCHAR2 )
  IS
    sta_rec sqlt$_gv$sql%ROWTYPE;
  BEGIN
    write_log('sql_stats_sec_'||p_plan_hash_value||'_'||p_inst_id||'_'||p_child_number||'_'||p_child_address||'_'||p_address);

    SELECT *
      INTO sta_rec
      FROM sqlt$_gv$sql
     WHERE statement_id = s_sql_rec.statement_id
       AND plan_hash_value = p_plan_hash_value
       AND inst_id = p_inst_id
       AND child_number = p_child_number
       AND child_address = p_child_address
       AND address = p_address;

    wa('<table>');
    wr('Inst ID', sta_rec.inst_id);
    wr('Child Number', sta_rec.child_number);
    wr('Child Address', sta_rec.child_address);
    wr('Executions', sta_rec.executions);
    wr('Elapsed Time in secs', TO_CHAR(ROUND(sta_rec.elapsed_time / 1e6, 3), SECONDS_FORMAT));
    wr('CPU Time in secs', TO_CHAR(ROUND(sta_rec.cpu_time / 1e6, 3), SECONDS_FORMAT));
    wr('User I/O Wait Time in secs', TO_CHAR(ROUND(sta_rec.user_io_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('Application Wait Time in secs', TO_CHAR(ROUND(sta_rec.application_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('Concurrency Wait Time in secs', TO_CHAR(ROUND(sta_rec.concurrency_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('Cluster Wait Time in secs', TO_CHAR(ROUND(sta_rec.cluster_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('PL/SQL Exec Time in secs', TO_CHAR(ROUND(sta_rec.plsql_exec_time / 1e6, 3), SECONDS_FORMAT));
    wr('Java Exec Time in secs', TO_CHAR(ROUND(sta_rec.java_exec_time / 1e6, 3), SECONDS_FORMAT));
    wr('Buffer Gets', sta_rec.buffer_gets);
    wr('Disk Reads', sta_rec.disk_reads);
    wr('Direct Writes', sta_rec.direct_writes);
    wr('Rows Processed', sta_rec.rows_processed);
    wr('Parse Calls', sta_rec.parse_calls);
    wr('Fetches', sta_rec.fetches);
    wr('End of Fetch count', sta_rec.end_of_fetch_count);
    wr('PX Servers Executions', sta_rec.px_servers_executions);
    wr('Loaded Versions', sta_rec.loaded_versions);
    wr('Loads', sta_rec.loads);
    wr('Invalidations', sta_rec.invalidations);
    wr('Open Versions', sta_rec.open_versions);
    wr('Kept Versions', sta_rec.kept_versions);
    wr('Users Executing', sta_rec.users_executing);
    wr('Users Opening', sta_rec.users_opening);
    wr('Locked Total', sta_rec.locked_total);
    wr('Pinned Total', sta_rec.pinned_total);
    wr('First Load Time', sta_rec.first_load_time);
    wr('Last Load Time', sta_rec.last_load_time);
    wr('Last Active Time', TO_CHAR(sta_rec.last_active_time, LOAD_DATE_FORMAT));
    wr('Sharable Memory', sta_rec.sharable_mem);
    wr('Persistent Memory', sta_rec.persistent_mem);
    wr('Runtime Memory', sta_rec.runtime_mem);
    wr('Sorts', sta_rec.sorts);
    wr('Serializable Aborts', sta_rec.serializable_aborts);
    wr('SQL Type', sta_rec.sqltype);
    wr('Command Type', sta_rec.command_type);
    wr('Optimizer Mode', sta_rec.optimizer_mode);
    wr('Optimizer Env', sta_rec.optimizer_env_hash_value);
    wr('Optimizer Cost', sta_rec.optimizer_cost);
    wr('Parsing User ID', sta_rec.parsing_user_id);
    wr('Parsing Schema ID', sta_rec.parsing_schema_id);
    wr('Parsing Schema Name', sta_rec.parsing_schema_name);
    wr('Service', sta_rec.service);
    wr('Module', sta_rec.module);
    wr('Action', sta_rec.action);
    wr('Is Binds Aware', sta_rec.is_bind_aware);
    wr('Is Bind Sensitive', sta_rec.is_bind_sensitive);
    wr('Is Obsolete', sta_rec.is_obsolete);
    wr('Is Sharable', sta_rec.is_shareable);
    wr('Literal Hash Value', sta_rec.literal_hash_value);
    wr('SQL Patch', NVL(sta_rec.sql_patch, '"null"'));
    wr('SQL Plan Baseline', NVL(sta_rec.sql_plan_baseline, '"null"'));
    wr('SQL Profile', NVL(sta_rec.sql_profile, '"null"'));
    wr('Exact Matching Signature', sta_rec.exact_matching_signature);
    wr('Force Matching Signature', sta_rec.force_matching_signature);
    wr('Outline Category', NVL(sta_rec.outline_category, '"null"'));
    wr('Outline SID', sta_rec.outline_sid);
    wr('Remote', sta_rec.remote);
    wr('Object Status', sta_rec.object_status);
    wr('Program ID', sta_rec.program_id);
    wr('Program Line #', sta_rec.program_line#);
    wr('Type Check Memory', sta_rec.typecheck_mem);
    wr('Type Check Heap', sta_rec.type_chk_heap);
    wr('I/O Disk Bytes', sta_rec.io_disk_bytes);
    wr('I/O Interconnect Bytes', sta_rec.io_interconnect_bytes);
    wr('Physical Read Requests', sta_rec.physical_read_requests);
    wr('Physical Read Bytes', sta_rec.physical_read_bytes);
    wr('Physical Write Requests', sta_rec.physical_write_requests);
    wr('Physical Write Bytes', sta_rec.physical_write_bytes);
    wr('Optimized Physical Read Requests', sta_rec.optimized_phy_read_requests);
    wr('Is Offloadable', CASE WHEN sta_rec.io_cell_offload_eligible_bytes IS NULL THEN NULL WHEN sta_rec.io_cell_offload_eligible_bytes = 0 THEN 'No' ELSE 'Yes' END);	
    wr('I/O Cell Uncompressed Bytes', sta_rec.io_cell_uncompressed_bytes);
    wr('I/O Cell Offload Eligible Bytes', sta_rec.io_cell_offload_eligible_bytes);
    wr('I/O Cell Offload Returned Bytes', sta_rec.io_cell_offload_returned_bytes);
    wr('I/O Saved %', CASE WHEN sta_rec.io_cell_offload_eligible_bytes = 0 THEN 0 ELSE 100*(sta_rec.io_cell_offload_eligible_bytes- sta_rec.io_interconnect_bytes) END / CASE WHEN sta_rec.io_cell_offload_eligible_bytes = 0 THEN 1 ELSE sta_rec.io_cell_offload_eligible_bytes END);
    wr('Is Reoptimizable', sta_rec.is_reoptimizable);
    wr('Is Resolved Adaptive Plan', sta_rec.is_resolved_adaptive_plan);	
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sql_stats_sec_'||p_plan_hash_value||'_'||p_inst_id||'_'||p_child_number||'_'||p_child_address||'_'||p_address||': '||SQLERRM);
  END sql_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private sql_stats_sec
   *
   * ------------------------- */
  PROCEDURE sql_stats_sec
  IS
    l_row_count NUMBER;
    l_plan_flags sqlt$_plan_header_v.plan_flags%TYPE;
  BEGIN
    write_log('sql_stats_sec');
    wa(h2(mot('SQL Statistics', 'GV$SQL'), 'sql_stats'));

    wa('List of child cursors is restricted up to '||s_rows_table_s||' per phv as per tool parameter "r_rows_table_s".');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT plan_hash_value, COUNT(*) child_cursors
                FROM sqlt$_gv$sql
               WHERE statement_id = s_sql_rec.statement_id
               GROUP BY
                     plan_hash_value
               ORDER BY
                     plan_hash_value)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan Hash Value'));
        wa(th('Child<br>Cursors'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(a_phv(i.plan_hash_value, 'sql_stats_'||i.plan_hash_value), 'l', 'nowrap'));
      wa(td(i.child_cursors, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_top);

    FOR i IN (SELECT DISTINCT plan_hash_value
                FROM sqlt$_gv$sql
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     plan_hash_value)
    LOOP
      l_row_count := 0;
      l_plan_flags := get_plan_flags(i.plan_hash_value);
      FOR j IN (SELECT inst_id, child_number, child_address, address
                  FROM sqlt$_gv$sql
                 WHERE statement_id = s_sql_rec.statement_id
                   AND plan_hash_value = i.plan_hash_value
                 ORDER BY
                       inst_id, child_number, child_address, address)
      LOOP
        l_row_count := l_row_count + 1;
        IF l_row_count = 1 THEN
          IF sqlt$a.get_plan_link(s_sql_rec.statement_id, i.plan_hash_value) IS NULL THEN
            wa(h4('SQL Statistics for '||i.plan_hash_value, 'sql_stats_'||i.plan_hash_value));
          ELSE
            wa(h4('SQL Statistics for '||a_phv(i.plan_hash_value, 'plan_'||sqlt$a.get_plan_link(s_sql_rec.statement_id, i.plan_hash_value)), 'sql_stats_'||i.plan_hash_value));
          END IF;
          wa('<table><tr>');
        END IF;

        wa('<td class="lw">');
        sql_stats_sec(i.plan_hash_value, j.inst_id, j.child_number, j.child_address, j.address);
        wa('</td>');

        IF l_row_count = s_rows_table_s THEN
          EXIT;
        END IF;
      END LOOP;

      IF l_row_count > 0 THEN
        wa('</tr></table>');
        wa(go_to_sec('SQL Statistics', 'sql_stats'));
        wa(go_to_top);
      END IF;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sql_stats_sec: '||SQLERRM);
  END sql_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private sql_monitor_sec
   *
   * ------------------------- */
  PROCEDURE sql_monitor_sec (
    p_plan_hash_value IN NUMBER,
    p_sql_exec_start  IN DATE,
    p_sql_exec_id     IN NUMBER,
    p_inst_id         IN NUMBER,
    p_process_name    IN VARCHAR2,
    p_key             IN NUMBER )
  IS
    sta_rec sqlt$_gv$sql_monitor%ROWTYPE;
  BEGIN
    write_log('sql_monitor_sec_'||p_plan_hash_value||'_'||p_sql_exec_id||'_'||p_inst_id||'_'||p_process_name||'_'||p_key);

    SELECT *
      INTO sta_rec
      FROM sqlt$_gv$sql_monitor
     WHERE statement_id = s_sql_rec.statement_id
       AND sql_child_number IS NOT NULL
       AND sql_plan_hash_value = p_plan_hash_value
       AND sql_exec_start = p_sql_exec_start
       AND sql_exec_id = p_sql_exec_id
       AND inst_id = p_inst_id
       AND process_name = p_process_name
       AND key = p_key;

    wa('<table>');
    wr('Status', sta_rec.status);
    wr('SQL Exec Start Time', TO_CHAR(sta_rec.sql_exec_start, LOAD_DATE_FORMAT));
    wr('SQL Exec ID', sta_rec.sql_exec_id);
    wr('Inst ID', sta_rec.inst_id);
    wr('Process Name', sta_rec.process_name);
    wr('Key', sta_rec.key);
    wr('Error Facility', sta_rec.error_facility);
    wr('Error Message', sta_rec.error_message);
    wr('Error Number', sta_rec.error_number);
    wr('Child Address', sta_rec.sql_child_address);
    wr('Child Number', sta_rec.sql_child_number);
    wr('Elapsed Time in secs', TO_CHAR(ROUND(sta_rec.elapsed_time / 1e6, 3), SECONDS_FORMAT));
    wr('Queuing Time in secs', TO_CHAR(ROUND(sta_rec.queuing_time / 1e6, 3), SECONDS_FORMAT));
    wr('CPU Time in secs', TO_CHAR(ROUND(sta_rec.cpu_time / 1e6, 3), SECONDS_FORMAT));
    wr('User I/O Wait Time in secs', TO_CHAR(ROUND(sta_rec.user_io_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('Application Wait Time in secs', TO_CHAR(ROUND(sta_rec.application_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('Concurrency Wait Time in secs', TO_CHAR(ROUND(sta_rec.concurrency_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('Cluster Wait Time in secs', TO_CHAR(ROUND(sta_rec.cluster_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('PL/SQL Exec Time in secs', TO_CHAR(ROUND(sta_rec.plsql_exec_time / 1e6, 3), SECONDS_FORMAT));
    wr('Java Exec Time in secs', TO_CHAR(ROUND(sta_rec.java_exec_time / 1e6, 3), SECONDS_FORMAT));
    wr('Buffer Gets', sta_rec.buffer_gets);
    wr('Disk Reads', sta_rec.disk_reads);
    wr('Direct Writes', sta_rec.direct_writes);
    wr('Fetches', sta_rec.fetches);
    wr('PX is Cross Instance', sta_rec.px_is_cross_instance);
    wr('PX Max DOP', sta_rec.px_maxdop);
    wr('PX Max DOP Instances', sta_rec.px_maxdop_instances);
    wr('PX Servers Requested', sta_rec.px_servers_requested);
    wr('PX Servers Allocated', sta_rec.px_servers_allocated);
    wr('PX Server #', sta_rec.px_server#);
    wr('PX Server Group', sta_rec.px_server_group);
    wr('PX Server Set', sta_rec.px_server_set);
    wr('PX QC Inst ID', sta_rec.px_qcinst_id);
    wr('PX QC SID', sta_rec.px_qcsid);
    wr('Refresh Count', sta_rec.refresh_count);
    wr('First Refresh Time', TO_CHAR(sta_rec.first_refresh_time, LOAD_DATE_FORMAT));
    wr('Last Refresh Time', TO_CHAR(sta_rec.last_refresh_time, LOAD_DATE_FORMAT));
    wr('User #', sta_rec.user#);
    wr('User Name', sta_rec.username);
    wr('Service Name', sta_rec.service_name);
    wr('Module', sta_rec.module);
    wr('Action', sta_rec.action);
    wr('Client Identifier', sta_rec.client_identifier);
    wr('Client Info', sta_rec.client_info);
    wr('SID', sta_rec.sid);
    wr('Session Serial#', sta_rec.session_serial#);
    wr('Exact Matching Signature', sta_rec.exact_matching_signature);
    wr('Force Matching Signature', sta_rec.force_matching_signature);
    wr('Program', sta_rec.program);
    wr('PL/SQL Entry Object ID', sta_rec.plsql_entry_object_id);
    wr('PL/SQL Entry Subprogram ID', sta_rec.plsql_entry_subprogram_id);
    wr('PL/SQL Object ID', sta_rec.plsql_object_id);
    wr('PL/SQL Subprogram ID', sta_rec.plsql_subprogram_id);
    wr('I/O Interconnect Bytes', sta_rec.io_interconnect_bytes);
    wr('Physical Read Requests', sta_rec.physical_read_requests);
    wr('Physical Read Bytes', sta_rec.physical_read_bytes);
    wr('Physical Write Requests', sta_rec.physical_write_requests);
    wr('Physical Write Bytes', sta_rec.physical_write_bytes);
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sql_monitor_sec_'||p_plan_hash_value||'_'||p_sql_exec_id||'_'||p_inst_id||'_'||p_process_name||'_'||p_key||': '||SQLERRM);
  END sql_monitor_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private sql_monitor_sec
   *
   * ------------------------- */
  PROCEDURE sql_monitor_sec
  IS
    l_row_count NUMBER;
    l_row_count2 NUMBER;
    l_plan_flags sqlt$_plan_header_v.plan_flags%TYPE;
  BEGIN
    write_log('sql_monitor_sec');
    wa(h2(mot('SQL Monitor Statistics', 'GV$SQL_MONITOR'), 'sql_monitor'));

    wa('List of monitored executions is restricted up to '||s_rows_table_s||' per phv as per tool parameter "r_rows_table_s".');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT sql_plan_hash_value, COUNT(*) monitored_executions
                FROM sqlt$_gv$sql_monitor
               WHERE statement_id = s_sql_rec.statement_id
                 AND sql_child_number IS NOT NULL
               GROUP BY
                     sql_plan_hash_value
               ORDER BY
                     sql_plan_hash_value)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan Hash Value'));
        wa(th('Monitored<br>Executions'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(a_phv(i.sql_plan_hash_value, 'sql_monitor_'||i.sql_plan_hash_value), 'l', 'nowrap'));
      wa(td(i.monitored_executions, 'r'));
      wa('</tr>');

      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_top);

    l_row_count := 0;
    FOR i IN (SELECT DISTINCT sql_plan_hash_value, sql_exec_start, sql_exec_id
                FROM sqlt$_gv$sql_monitor
               WHERE statement_id = s_sql_rec.statement_id
                 AND sql_child_number IS NOT NULL
               ORDER BY
                     sql_plan_hash_value,
                     sql_exec_start DESC,
                     sql_exec_id)
    LOOP
      l_row_count := l_row_count + 1;
      l_row_count2 := 0;
      l_plan_flags := get_plan_flags(i.sql_plan_hash_value);
      FOR j IN (SELECT status, inst_id, process_name, key
                  FROM sqlt$_gv$sql_monitor
                 WHERE statement_id = s_sql_rec.statement_id
                   AND sql_plan_hash_value = i.sql_plan_hash_value
                   AND sql_exec_start = i.sql_exec_start
                   AND sql_exec_id = i.sql_exec_id
                   AND sql_child_number IS NOT NULL
                 ORDER BY
                       DECODE(status, 'EXECUTING', 'AA', 'DONE (ERROR)', 'AB', status),
                       inst_id,
                       process_name,
                       key)
      LOOP
        l_row_count2 := l_row_count2 + 1;
        IF l_row_count2 = 1 THEN
          wa(h4('SQL Monitoring for '||a_phv(i.sql_plan_hash_value, 'plan_'||i.sql_plan_hash_value||'_1')||' '||j.status||' '||TO_CHAR(i.sql_exec_start, LOAD_DATE_FORMAT), 'sql_monitor_'||i.sql_plan_hash_value));
          wa('<table><tr>');
        END IF;
        wa('<td class="lw">');
        sql_monitor_sec(i.sql_plan_hash_value, i.sql_exec_start, i.sql_exec_id, j.inst_id, j.process_name, j.key);
        wa('</td>');

        IF l_row_count2 = s_rows_table_s * 2 THEN
          EXIT;
        END IF;
      END LOOP;

      IF l_row_count2 > 0 THEN
        wa('</tr></table>');
        wa(go_to_sec('SQL Monitor', 'sql_monitor'));
        wa(go_to_top);
      END IF;

      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sql_monitor_sec: '||SQLERRM);
  END sql_monitor_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private segment_stats_sec
   *
   * ------------------------- */
  PROCEDURE segment_stats_sec
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('segment_stats_sec');
    wa(h2(mot('Segment Statistics', 'GV$SEGMENT_STATISTICS'), 'seg_stats'));

    l_sql := '
SELECT value,
       statistic_name,
       object_name,
       subobject_name,
       owner,
       object_type,
       inst_id,
       tablespace_name,
       obj#,
       dataobj#
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_gv$segment_statistics_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND value > 0
 ORDER BY
       value DESC,
       statistic_name,
       object_name;';

    wa('Statistics below include the execution of your SQL within "'||s_sql_rec.input_filename||'".<br>'||TOOL_NAME||' '||s_sql_rec.method||' took snapshots of GV$SEGMENT_STATISTICS right before and after your script was executed. Metrics below are for that interval.<br>Be aware that segment statistics are not session specific. Therefore, use the statitics below with caution since they may include work from other active sessions.<br>Content below is driven by tables discovered in prior executions of '||TOOL_NAME||'. Thus, you may need to repeat this '||TOOL_NAME||' '||s_sql_rec.method||' in order to get all segments related to your SQL.');
    wa('<br>');
    wa('List restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT value,
                     statistic_name,
                     object_name,
                     subobject_name,
                     owner,
                     object_type,
                     inst_id,
                     tablespace_name,
                     obj#,
                     dataobj#
                FROM sqlt$_gv$segment_statistics_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND value > 0
               ORDER BY
                     value DESC,
                     statistic_name,
                     object_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Value'));
        wa(th('Statistic Name'));
        wa(th('Object Name'));
        wa(th('Suboject Name'));
        wa(th('Owner'));
        wa(th('Object Type'));
        wa(th('Inst ID'));
        wa(th('TableSpace Name'));
        wa(th('Obj#'));
        wa(th('Data Obj#'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.value, 'r'));
      wa(td(i.statistic_name, 'l'));
      wa(td(i.object_name, 'l'));
      wa(td(i.subobject_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.object_type, 'l'));
      wa(td(i.inst_id));
      wa(td(i.tablespace_name, 'l'));
      wa(td(i.obj#));
      wa(td(i.dataobj#));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('segment_stats_sec: '||SQLERRM);
  END segment_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private session_stats_sec
   *
   * ------------------------- */
  PROCEDURE session_stats_sec
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('session_stats_sec');
    wa(h2(mot('Session Statistics', 'GV$SESSTAT'), 'sess_stats'));

    l_sql := '
SELECT class_name,
       name,
       value,
       inst_id
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_gv$sesstat_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND value > 0
 ORDER BY
       class_name,
       name,
       inst_id;';

    wa('Statistics below include the execution of your SQL within "'||s_sql_rec.input_filename||'".<br>'||TOOL_NAME||' '||s_sql_rec.method||' took snapshots of GV$SESSTAT right before and after your script was executed.');
    wa('<br>');
    wa('Metrics below are for that interval. List is restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT class_name,
                     name,
                     value,
                     inst_id
                FROM sqlt$_gv$sesstat_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND value > 0
               ORDER BY
                     class_name,
                     name,
                     inst_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Class Name'));
        wa(th('Statistic Name'));
        wa(th('Value'));
        wa(th('Inst ID'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.class_name, 'l'));
      wa(td(i.name, 'l'));
      wa(td(i.value, 'r'));
      wa(td(i.inst_id));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('session_stats_sec: '||SQLERRM);
  END session_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private session_event_sec
   *
   * ------------------------- */
  PROCEDURE session_event_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('session_event_sec');
    wa(h2(mot('Session Events', 'GV$SESSION_EVENT'), 'sess_events'));

    wa('Statistics below include the execution of your SQL within "'||s_sql_rec.input_filename||'".<br>'||TOOL_NAME||' '||s_sql_rec.method||' took snapshots of GV$SESSION_EVENT right before and after your script was executed. Metrics below are for that interval.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_gv$session_event_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND time_waited_secs > 0
               ORDER BY
                     time_waited_secs DESC,
                     event)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Seconds Waited'));
        wa(th('Event Name'));
        wa(th('Inst ID'));
        wa(th('Total Waits'));
        wa(th('Avg Wait in seconds'));
        wa(th('Total Timeouts'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(TO_CHAR(i.time_waited_secs, SECONDS_FORMAT6), 'r'));
      wa(td(i.event, 'l'));
      wa(td(i.inst_id));
      wa(td(i.total_waits, 'r'));
      wa(td(TO_CHAR(i.avg_wait_secs, SECONDS_FORMAT6), 'r'));
      wa(td(i.total_timeouts, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('session_event_sec: '||SQLERRM);
  END session_event_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private parallel_processing_sec1
   *
   * ------------------------- */
  PROCEDURE parallel_processing_sec1
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('parallel_processing_sec1');
    wa(h2(mot('Parallel Processing', 'GV$PQ and GV$PX views'), 'parallel_exec'));
    wa('<ul>');
    wa(li(mot('PX Operation Statistics', 'GV$PQ_TQSTAT', '#pq_tqstat')));
    IF s_sql_rec.rdbms_release >= 11 THEN
      wa(li(mot('PX Instance Groups', 'GV$PX_INSTANCE_GROUP', '#px_instance_group')));
    END IF;
    wa(li(mot('Active PX Servers', 'GV$PQ_SLAVE', '#pq_slave')));
    wa(li(mot('PX Processes', 'GV$PX_PROCESS', '#px_process')));
    wa(li(mot('PX Sessions', 'GV$PX_SESSION', '#px_session')));
    wa(li(mot('PX System Statistics - Summary', 'GV$PQ_SYSSTAT', '#pq_sysstat')));
    wa(li(mot('PX Process System Statistics - Summary', 'GV$PX_PROCESS_SYSSTAT', '#px_process_sysstat')));
    wa(li(mot('PX Session Statistics - Summary', 'GV$PQ_SESSTAT', '#pq_sesstat')));
    wa(li(mot('PX Session Statistics - Detail', 'GV$PX_SESSTAT', '#px_sesstat')));
    wa('</ul>');
    wa(go_to_top);

    l_sql := '
SELECT dfo_number,
       tq_id,
       ''''Q''''||dfo_number||'''',''''||tq_id tq,
       server_type,
       process,
       inst_id,
       num_rows,
       bytes,
       open_time,
       avg_latency,
       waits,
       timeouts
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$pq_tqstat
 WHERE statement_id = '||s_sql_rec.statement_id||'
 ORDER BY
       dfo_number,
       tq_id,
       server_type DESC,
       process,
       inst_id;';

    wa(h3(mot('PX Operation Statistics', 'GV$PQ_TQSTAT'), 'pq_tqstat', FALSE));
    wa('Statistics for parallel-execution operations within the execution plan. Captured after the execution of your SQL within "'||s_sql_rec.input_filename||'".');
    wa('<br>');
    wa('List restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT dfo_number,
                     tq_id,
                     'Q'||dfo_number||','||tq_id tq,
                     server_type,
                     process,
                     inst_id,
                     num_rows,
                     bytes,
                     open_time,
                     avg_latency,
                     waits,
                     timeouts
                FROM sqlt$_gv$pq_tqstat
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     dfo_number,
                     tq_id,
                     server_type DESC,
                     process,
                     inst_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Data Flow Operator<br>DFO Number'));
        wa(th('Table Query<br>TQ ID'));
        wa(th('TQ'));
        wa(th('Server Type'));
        wa(th('Process'));
        wa(th('Inst ID'));
        wa(th('Rows'));
        wa(th('Bytes'));
        wa(th('Open Time<br>(Seconds)'));
        wa(th('Avg Latency<br>(Minutes)'));
        wa(th('Waits'));
        wa(th('Timeouts'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.dfo_number));
      wa(td(i.tq_id));
      wa(td(i.tq));
      wa(td(i.server_type, 'l'));
      wa(td(i.process, 'l'));
      wa(td(i.inst_id));
      wa(td(i.num_rows, 'r'));
      wa(td(i.bytes, 'r'));
      wa(td(i.open_time, 'r'));
      wa(td(i.avg_latency, 'r'));
      wa(td(i.waits, 'r'));
      wa(td(i.timeouts, 'r'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);

    IF s_sql_rec.rdbms_release >= 11 THEN
      wa(h3(mot('PX Instance Groups', 'GV$PX_INSTANCE_GROUP'), 'px_instance_group', FALSE));
      wa('Parallel-execution instance groups available to current session (SID='||s_sql_rec.sid||'). Captured after the execution of your SQL within "'||s_sql_rec.input_filename||'".');
      wa('<table>');
      l_row_count := 0;
      FOR i IN (SELECT inst_id,
                       qc_instance_group,
                       why
                  FROM sqlt$_gv$px_instance_group
                 WHERE statement_id = s_sql_rec.statement_id
                   AND begin_end_flag = 'E'
                 ORDER BY
                       inst_id,
                       qc_instance_group)
      LOOP
        l_row_count := l_row_count + 1;
        IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
          wa('<tr>');
          wa(th('#'));
          wa(th('Inst ID'));
          wa(th('Instance Group'));
          wa(th('Why'));
          wa('</tr>');
        END IF;

        wa('<tr>');
        wa(td(l_row_count, 'rt'));
        wa(td(i.inst_id));
        wa(td(i.qc_instance_group, 'l'));
        wa(td(i.why, 'l'));
        wa('</tr>');

        IF l_row_count = s_rows_table_m THEN
          EXIT;
        END IF;
      END LOOP;
      wa('</table>');
      wa(go_to_sec('Parallel Processing', 'parallel_exec'));
      wa(go_to_top);
    END IF;

    l_sql := '
SELECT e.inst_id,
       e.slave_name,
       p.status,
       (e.sessions - NVL(b.sessions, 0)) sessions,
       (e.idle_time_cur - NVL(b.idle_time_cur, 0)) idle_time_cur,
       (e.busy_time_cur - NVL(b.busy_time_cur, 0)) busy_time_cur,
       (e.cpu_secs_cur - NVL(b.cpu_secs_cur, 0)) cpu_secs_cur,
       (e.msgs_sent_cur - NVL(b.msgs_sent_cur, 0)) msgs_sent_cur,
       (e.msgs_rcvd_cur - NVL(b.msgs_rcvd_cur, 0)) msgs_rcvd_cur,
       (e.idle_time_total - NVL(b.idle_time_total, 0)) idle_time_total,
       (e.busy_time_total - NVL(b.busy_time_total, 0)) busy_time_total,
       (e.cpu_secs_total - NVL(b.cpu_secs_total, 0)) cpu_secs_total,
       (e.msgs_sent_total - NVL(b.msgs_sent_total, 0)) msgs_sent_total,
       (e.msgs_rcvd_total - NVL(b.msgs_rcvd_total, 0)) msgs_rcvd_total,
       NVL(s.qcinst_id, s.inst_id) qcinst_id,
       s.qcsid
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$pq_slave b,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$pq_slave e,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_process p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_session s
 WHERE e.statement_id = '||s_sql_rec.statement_id||'
   AND e.begin_end_flag = ''E''
   AND e.statement_id = b.statement_id(+)
   AND e.inst_id = b.inst_id(+)
   AND e.slave_name = b.slave_name(+)
   AND ''B'' = b.begin_end_flag(+)
   AND e.statement_id = p.statement_id
   AND e.inst_id = p.inst_id
   AND e.slave_name = p.server_name
   AND p.begin_end_flag = ''E''
   AND p.statement_id = s.statement_id(+)
   AND ''E'' = s.begin_end_flag(+)
   AND p.inst_id = s.inst_id(+)
   AND p.sid = s.sid(+)
   AND p.serial# = s.serial#(+)
   AND s.qcsid = '||s_sql_rec.sid||' -- remove to see all
 ORDER BY
       e.inst_id,
       e.slave_name;';

    wa(h3(mot('Active PX Servers', 'GV$PQ_SLAVE'), 'pq_slave', FALSE));
    wa('Statistics for active parallel-execution servers. Captured before and after the execution of your SQL within "'||s_sql_rec.input_filename||'".');
    wa('<br>');
    wa(TOOL_NAME||' '||s_sql_rec.method||' took snapshots of GV$PQ_SLAVE right before and after your script was executed. Metrics below are for that interval.');
    wa('<br>');
    wa('Be aware that GV$PQ_SLAVE statistics are restricted to your session (SID='||s_sql_rec.sid||').');
    wa('<br>');
    --wa('List restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    --wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT e.inst_id,
                     e.slave_name,
                     p.status,
                     (e.sessions - NVL(b.sessions, 0)) sessions,
                     (e.idle_time_cur - NVL(b.idle_time_cur, 0)) idle_time_cur,
                     (e.busy_time_cur - NVL(b.busy_time_cur, 0)) busy_time_cur,
                     (e.cpu_secs_cur - NVL(b.cpu_secs_cur, 0)) cpu_secs_cur,
                     (e.msgs_sent_cur - NVL(b.msgs_sent_cur, 0)) msgs_sent_cur,
                     (e.msgs_rcvd_cur - NVL(b.msgs_rcvd_cur, 0)) msgs_rcvd_cur,
                     (e.idle_time_total - NVL(b.idle_time_total, 0)) idle_time_total,
                     (e.busy_time_total - NVL(b.busy_time_total, 0)) busy_time_total,
                     (e.cpu_secs_total - NVL(b.cpu_secs_total, 0)) cpu_secs_total,
                     (e.msgs_sent_total - NVL(b.msgs_sent_total, 0)) msgs_sent_total,
                     (e.msgs_rcvd_total - NVL(b.msgs_rcvd_total, 0)) msgs_rcvd_total,
                     NVL(s.qcinst_id, s.inst_id) qcinst_id,
                     s.qcsid
                FROM sqlt$_gv$pq_slave b,
                     sqlt$_gv$pq_slave e,
                     sqlt$_gv$px_process p,
                     sqlt$_gv$px_session s
               WHERE e.statement_id = s_sql_rec.statement_id
                 AND e.begin_end_flag = 'E'
                 AND e.statement_id = b.statement_id(+)
                 AND e.inst_id = b.inst_id(+)
                 AND e.slave_name = b.slave_name(+)
                 AND 'B' = b.begin_end_flag(+)
                 AND e.statement_id = p.statement_id
                 AND e.inst_id = p.inst_id
                 AND e.slave_name = p.server_name
                 AND p.begin_end_flag = 'E'
                 AND p.statement_id = s.statement_id(+)
                 AND 'E' = s.begin_end_flag(+)
                 AND p.inst_id = s.inst_id(+)
                 AND p.sid = s.sid(+)
                 AND p.serial# = s.serial#(+)
                 AND s.qcsid = s_sql_rec.sid -- remove to see all
               ORDER BY
                     e.inst_id,
                     e.slave_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Inst ID'));
        wa(th('Slave Name'));
        wa(th('Status'));
        wa(th('Sessions'));
        wa(th('Idle Time Current Session'));
        wa(th('Busy Time Current Session'));
        wa(th('CPU Seconds Current Session'));
        wa(th('Messages Sent Current Session'));
        wa(th('Messages Received Current Session'));
        wa(th('Idle Time Total'));
        wa(th('Busy Time Total'));
        wa(th('CPU Seconds Total'));
        wa(th('Messages Sent Total'));
        wa(th('Messages Received Total'));
        wa(th('Query Coordinator<br>Inst ID'));
        wa(th('Query Coordinator<br>Session ID SID'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.inst_id));
      wa(td(i.slave_name, 'l'));
      wa(td(i.status));
      wa(td(i.sessions, 'r'));
      wa(td(i.idle_time_cur, 'r'));
      wa(td(i.busy_time_cur, 'r'));
      wa(td(i.cpu_secs_cur, 'r'));
      wa(td(i.msgs_sent_cur, 'r'));
      wa(td(i.msgs_rcvd_cur, 'r'));
      wa(td(i.idle_time_total, 'r'));
      wa(td(i.busy_time_total, 'r'));
      wa(td(i.cpu_secs_total, 'r'));
      wa(td(i.msgs_sent_total, 'r'));
      wa(td(i.msgs_rcvd_total, 'r'));
      wa(td(i.qcinst_id));
      wa(td(i.qcsid));
      wa('</tr>');

      --IF l_row_count = s_rows_table_l THEN
      --  EXIT;
      --END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);

    l_sql := '
SELECT p.inst_id,
       p.server_name,
       p.status,
       p.pid,
       p.spid,
       p.sid,
       p.serial#,
       NVL(s.qcinst_id, s.inst_id) qcinst_id,
       s.qcsid,
       NVL(s.qcserial#, s.serial#) qcserial#
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_process p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_session s
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.begin_end_flag = ''E''
   AND p.statement_id = s.statement_id(+)
   AND ''E'' = s.begin_end_flag(+)
   AND p.inst_id = s.inst_id(+)
   AND p.sid = s.sid(+)
   AND p.serial# = s.serial#(+)
   AND s.qcsid = '||s_sql_rec.sid||' -- remove to see all
 ORDER BY
       p.inst_id,
       p.server_name;';

    wa(h3(mot('PX Processes', 'GV$PX_PROCESS'), 'px_process', FALSE));
    wa('Parallel-execution processes, and sessions running on them. Captured after the execution of your SQL within "'||s_sql_rec.input_filename||'".');
    wa('<br>');
    wa(TOOL_NAME||' '||s_sql_rec.method||' took a snapshot of GV$PX_PROCESS right after your script was executed. Metrics below are for that snapshot.');
    wa('<br>');
    wa('Be aware that GV$PX_PROCESS statistics are not restricted to your session (SID='||s_sql_rec.sid||').');
    wa('<br>');
    --wa('List restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    --wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT p.inst_id,
                     p.server_name,
                     p.status,
                     p.pid,
                     p.spid,
                     p.sid,
                     p.serial#,
                     NVL(s.qcinst_id, s.inst_id) qcinst_id,
                     s.qcsid,
                     NVL(s.qcserial#, s.serial#) qcserial#
                FROM sqlt$_gv$px_process p,
                     sqlt$_gv$px_session s
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.begin_end_flag = 'E'
                 AND p.statement_id = s.statement_id(+)
                 AND 'E' = s.begin_end_flag(+)
                 AND p.inst_id = s.inst_id(+)
                 AND p.sid = s.sid(+)
                 AND p.serial# = s.serial#(+)
                 AND s.qcsid = s_sql_rec.sid -- remove to see all
               ORDER BY
                     p.inst_id,
                     p.server_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Inst ID'));
        wa(th('Server Name'));
        wa(th('Status'));
        wa(th('Process Identifier PID'));
        wa(th('OS Process Identifier SPID'));
        wa(th('Session ID SID<sup>1</sup>'));
        wa(th('Session Serial Number<sup>1</sup>'));
        wa(th('Query Coordinator<br>Inst ID'));
        wa(th('Query Coordinator<br>Session ID SID'));
        wa(th('Query Coordinator<br>Serial Number'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.inst_id));
      wa(td(i.server_name, 'l'));
      wa(td(i.status));
      wa(td(i.pid));
      wa(td(i.spid));
      wa(td(i.sid));
      wa(td(i.serial#));
      wa(td(i.qcinst_id));
      wa(td(i.qcsid));
      wa(td(i.qcserial#));
      wa('</tr>');

      --IF l_row_count = s_rows_table_l THEN
      --  EXIT;
      --END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) If the PX Server is in use.'));
    wa('<br>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);

    l_sql := '
SELECT NVL(s.qcinst_id, s.inst_id) qcinst_id,
       s.qcsid,
       NVL(s.qcserial#, s.serial#) qcserial#,
       s.server_group,
       s.server_set,
       s.server#,
       s.degree,
       s.req_degree,
       s.inst_id,
       s.sid,
       s.serial#,
       p.server_name
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_session s,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_process p
 WHERE s.statement_id = '||s_sql_rec.statement_id||'
   AND s.qcsid = '||s_sql_rec.sid||' -- remove to see all
   AND s.begin_end_flag = ''E''
   AND s.statement_id = p.statement_id(+)
   AND ''E'' = p.begin_end_flag(+)
   AND s.inst_id = p.inst_id(+)
   AND s.sid = p.sid(+)
   AND s.serial# = p.serial#(+)
 ORDER BY
       NVL(s.qcinst_id, s.inst_id),
       s.qcsid,
       NVL(s.qcserial#, s.serial#),
       s.server_group NULLS FIRST,
       s.server_set NULLS FIRST,
       s.server# NULLS FIRST,
       s.inst_id,
       s.sid,
       s.serial#;';

    wa(h3(mot('PX Sessions', 'GV$PX_SESSION'), 'px_session', FALSE));
    wa('Sessions running on parallel-execution servers. Captured after the execution of your SQL within "'||s_sql_rec.input_filename||'".');
    wa('<br>');
    wa(TOOL_NAME||' '||s_sql_rec.method||' took a snapshot of GV$PX_SESSION right after your script was executed. Metrics below are for that snapshot.');
    wa('<br>');
    wa('Be aware that GV$PX_SESSION statistics are not restricted to your session (SID='||s_sql_rec.sid||').');
    wa('<br>');
    --wa('List restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    --wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT NVL(s.qcinst_id, s.inst_id) qcinst_id,
                     s.qcsid,
                     NVL(s.qcserial#, s.serial#) qcserial#,
                     s.server_group,
                     s.server_set,
                     s.server#,
                     s.degree,
                     s.req_degree,
                     s.inst_id,
                     s.sid,
                     s.serial#,
                     p.server_name
                FROM sqlt$_gv$px_session s,
                     sqlt$_gv$px_process p
               WHERE s.statement_id = s_sql_rec.statement_id
                 AND s.qcsid = s_sql_rec.sid -- remove to see all
                 AND s.begin_end_flag = 'E'
                 AND s.statement_id = p.statement_id(+)
                 AND 'E' = p.begin_end_flag(+)
                 AND s.inst_id = p.inst_id(+)
                 AND s.sid = p.sid(+)
                 AND s.serial# = p.serial#(+)
               ORDER BY
                     NVL(s.qcinst_id, s.inst_id),
                     s.qcsid,
                     NVL(s.qcserial#, s.serial#),
                     s.server_group NULLS FIRST,
                     s.server_set NULLS FIRST,
                     s.server# NULLS FIRST,
                     s.inst_id,
                     s.sid,
                     s.serial#)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Query Coordinator<br>Inst ID'));
        wa(th('Query Coordinator<br>Session ID SID'));
        wa(th('Query Coordinator<br>Serial Number'));
        wa(th('Server<br>Group<sup>1</sup>'));
        wa(th('Server<br>Set<sup>1</sup>'));
        wa(th('Server<br>Number<sup>1</sup>'));
        wa(th('Parallel Degree<br>Used<sup>1</sup>'));
        wa(th('Parallel Degree<br>Requested<sup>1</sup>'));
        wa(th('Session<br>Inst ID'));
        wa(th('Session<br>ID SID'));
        wa(th('Session<br>Serial Number'));
        wa(th('Server Name'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.qcinst_id));
      wa(td(i.qcsid));
      wa(td(i.qcserial#));
      wa(td(i.server_group));
      wa(td(i.server_set));
      wa(td(i.server#));
      wa(td(i.degree));
      wa(td(i.req_degree));
      wa(td(i.inst_id));
      wa(td(i.sid));
      wa(td(i.serial#));
      wa(td(i.server_name, 'l'));
      wa('</tr>');

      --IF l_row_count = s_rows_table_l THEN
      --  EXIT;
      --END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) NULL for Query Coordinator.'));
    wa('<br>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);

    wa(h3(mot('PX System Statistics - Summary', 'GV$PQ_SYSSTAT'), 'pq_sysstat', FALSE));
    wa('System statistics for parallel-execution servers. Captured before and after the execution of your SQL within "'||s_sql_rec.input_filename||'".');
    wa('<br>');
    wa(TOOL_NAME||' '||s_sql_rec.method||' took snapshots of GV$PQ_SYSSTAT right before and after your script was executed. Metrics below are for that interval.');
    wa('<br>');
    wa('Be aware that GV$PQ_SYSSTAT statistics are not session specific. Therefore, use the statitics below with caution since they may include work from other active sessions.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT statistic,
                     inst_id,
                     value_before,
                     value_after,
                     difference
                FROM sqlt$_gv$pq_sysstat_v
               WHERE statement_id = s_sql_rec.statement_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('Statistic'));
        wa(th('Inst ID'));
        wa(th('Value Before'));
        wa(th('Value After'));
        wa(th('Difference'));
        wa('</tr>');
      END IF;
      wr(i.statistic, i.inst_id, 'c', i.value_before, 'r', i.value_after, 'r', i.difference, 'r');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);

    wa(h3(mot('PX Process System Statistics - Summary', 'GV$PX_PROCESS_SYSSTAT'), 'px_process_sysstat', FALSE));
    wa('Process system statistics for parallel-execution servers. Captured before and after the execution of your SQL within "'||s_sql_rec.input_filename||'".');
    wa('<br>');
    wa(TOOL_NAME||' '||s_sql_rec.method||' took snapshots of GV$PX_PROCESS_SYSSTAT right before and after your script was executed. Metrics below are for that interval.');
    wa('<br>');
    wa('Be aware that GV$PX_PROCESS_SYSSTAT statistics are not session specific. Therefore, use the statitics below with caution since they may include work from other active sessions.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT statistic,
                     inst_id,
                     value_before,
                     value_after,
                     difference
                FROM sqlt$_gv$px_process_sysstat_v
               WHERE statement_id = s_sql_rec.statement_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('Statistic'));
        wa(th('Inst ID'));
        wa(th('Value Before'));
        wa(th('Value After'));
        wa(th('Difference'));
        wa('</tr>');
      END IF;
      wr(i.statistic, i.inst_id, 'c', i.value_before, 'r', i.value_after, 'r', i.difference, 'r');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);

    wa(h3(mot('PX Session Statistics - Summary', 'GV$PQ_SESSTAT'), 'pq_sesstat', FALSE));
    wa('Session statistics for Query Coordinator with SID of '||s_sql_rec.sid||'. Captured after the execution of your SQL within "'||s_sql_rec.input_filename||'".');
    wa('<br>');
    wa(TOOL_NAME||' '||s_sql_rec.method||' took snapshots of GV$PQ_SESSTAT right after your script was executed. Metrics below are for that snapshot.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT statistic,
                     inst_id,
                     last_query,
                     session_total
                FROM sqlt$_gv$pq_sesstat
               WHERE statement_id = s_sql_rec.statement_id
                 AND begin_end_flag = 'E'
               ORDER BY
                     inst_id,
                     ROWID)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('Statistic'));
        wa(th('Inst ID'));
        wa(th('Last Query'));
        wa(th('Session Total'));
        wa('</tr>');
      END IF;
      wr(i.statistic, i.inst_id, 'c', i.last_query, 'r', i.session_total, 'r');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);

    l_sql := '
SELECT class_name,
       name,
       value,
       server_group,
       server_set,
       server#,
       degree,
       req_degree,
       inst_id,
       sid,
       serial#
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_gv$px_sesstat_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND qcsid = '||s_sql_rec.sid||'
   AND value > 0
 ORDER BY
       class_name,
       name,
       server_group NULLS FIRST,
       server_set NULLS FIRST,
       server# NULLS FIRST,
       inst_id,
       sid,
       serial#;';

    wa(h3(mot('PX Session Statistics - Detail', 'GV$PX_SESSTAT'), 'px_sesstat', FALSE));
    wa('Session statistics for parallel-execution servers under Query Coordinator with SID of '||s_sql_rec.sid||'. Captured before and after the execution of your SQL within "'||s_sql_rec.input_filename||'".');
    wa('<br>');
    wa(TOOL_NAME||' '||s_sql_rec.method||' took snapshots of GV$PX_SESSTAT right before and after your script was executed. Metrics below are for that interval.');
    wa('<br>');
    wa('List restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT class_name,
                     name,
                     value,
                     server_group,
                     server_set,
                     server#,
                     degree,
                     req_degree,
                     inst_id,
                     sid,
                     serial#
                FROM sqlt$_gv$px_sesstat_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND qcsid = s_sql_rec.sid
                 AND value > 0
               ORDER BY
                     class_name,
                     name,
                     server_group NULLS FIRST,
                     server_set NULLS FIRST,
                     server# NULLS FIRST,
                     inst_id,
                     sid,
                     serial#)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Class Name'));
        wa(th('Statistic Name'));
        wa(th('Value'));
        wa(th('Server<br>Group<sup>1</sup>'));
        wa(th('Server<br>Set<sup>1</sup>'));
        wa(th('Server<br>Number<sup>1</sup>'));
        wa(th('Parallel Degree<br>Used<sup>1</sup>'));
        wa(th('Parallel Degree<br>Requested<sup>1</sup>'));
        wa(th('Session<br>Inst ID'));
        wa(th('Session<br>ID SID'));
        wa(th('Session<br>Serial Number'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.class_name, 'l'));
      wa(td(i.name, 'l'));
      wa(td(i.value, 'r'));
      wa(td(i.server_group));
      wa(td(i.server_set));
      wa(td(i.server#));
      wa(td(i.degree));
      wa(td(i.req_degree));
      wa(td(i.inst_id));
      wa(td(i.sid));
      wa(td(i.serial#));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) NULL for Query Coordinator.'));
    wa('<br>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);

  EXCEPTION
    WHEN OTHERS THEN
      write_error('parallel_processing_sec1: '||SQLERRM);
  END parallel_processing_sec1;

  /*************************************************************************************/

  /* -------------------------
   *
   * private parallel_processing_sec2
   *
   * ------------------------- */
  PROCEDURE parallel_processing_sec2
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('parallel_processing_sec2');
    wa(h2(mot('Parallel Processing', 'GV$PQ and GV$PX views'), 'parallel_exec'));
    wa('<ul>');
    IF s_sql_rec.rdbms_release >= 11 THEN
      wa(li(mot('PX Instance Groups', 'GV$PX_INSTANCE_GROUP', '#px_instance_group')));
    END IF;
    wa(li(mot('Active PX Servers', 'GV$PQ_SLAVE', '#pq_slave')));
    wa(li(mot('PX Processes', 'GV$PX_PROCESS', '#px_process')));
    wa(li(mot('PX Sessions', 'GV$PX_SESSION', '#px_session')));
    wa(li(mot('PX System Statistics - Summary', 'GV$PQ_SYSSTAT', '#pq_sysstat')));
    wa(li(mot('PX Process System Statistics - Summary', 'GV$PX_PROCESS_SYSSTAT', '#px_process_sysstat')));
    wa('</ul>');
    wa(go_to_top);

    IF s_sql_rec.rdbms_release >= 11 THEN
      wa(h3(mot('PX Instance Groups', 'GV$PX_INSTANCE_GROUP'), 'px_instance_group', FALSE));
      wa('Parallel-execution instance groups available to current session (SID='||s_sql_rec.sid||').');
      wa('<table>');
      l_row_count := 0;
      FOR i IN (SELECT inst_id,
                       qc_instance_group,
                       why
                  FROM sqlt$_gv$px_instance_group
                 WHERE statement_id = s_sql_rec.statement_id
                   AND begin_end_flag = 'E'
                 ORDER BY
                       inst_id,
                       qc_instance_group)
      LOOP
        l_row_count := l_row_count + 1;
        IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
          wa('<tr>');
          wa(th('#'));
          wa(th('Inst ID'));
          wa(th('Instance Group'));
          wa(th('Why'));
          wa('</tr>');
        END IF;

        wa('<tr>');
        wa(td(l_row_count, 'rt'));
        wa(td(i.inst_id));
        wa(td(i.qc_instance_group, 'l'));
        wa(td(i.why, 'l'));
        wa('</tr>');

        IF l_row_count = s_rows_table_m THEN
          EXIT;
        END IF;
      END LOOP;
      wa('</table>');
      wa(go_to_sec('Parallel Processing', 'parallel_exec'));
      wa(go_to_top);
    END IF;

    l_sql := '
SELECT e.inst_id,
       e.slave_name,
       p.status,
       e.sessions,
       e.idle_time_cur,
       e.busy_time_cur,
       e.cpu_secs_cur,
       e.msgs_sent_cur,
       e.msgs_rcvd_cur,
       e.idle_time_total,
       e.busy_time_total,
       e.cpu_secs_total,
       e.msgs_sent_total,
       e.msgs_rcvd_total,
       NVL(s.qcinst_id, s.inst_id) qcinst_id,
       s.qcsid
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$pq_slave e,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_process p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_session s
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND e.begin_end_flag = ''E''
   AND e.statement_id = p.statement_id
   AND e.inst_id = p.inst_id
   AND e.slave_name = p.server_name
   AND p.begin_end_flag = ''E''
   AND p.statement_id = s.statement_id(+)
   AND ''E'' = s.begin_end_flag(+)
   AND p.inst_id = s.inst_id(+)
   AND p.sid = s.sid(+)
   AND p.serial# = s.serial#(+)
 ORDER BY
       e.inst_id,
       e.slave_name;';

    wa(h3(mot('Active PX Servers', 'GV$PQ_SLAVE'), 'pq_slave', FALSE));
    wa('Statistics for active parallel-execution servers.');
    wa('<br>');
    --wa('List restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    --wa('<br>');
    wa(hide_sql(l_sql));
    /*
    wa(hide_begin);
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT e.inst_id,
                     e.slave_name,
                     p.status,
                     e.sessions,
                     e.idle_time_cur,
                     e.busy_time_cur,
                     e.cpu_secs_cur,
                     e.msgs_sent_cur,
                     e.msgs_rcvd_cur,
                     e.idle_time_total,
                     e.busy_time_total,
                     e.cpu_secs_total,
                     e.msgs_sent_total,
                     e.msgs_rcvd_total,
                     NVL(s.qcinst_id, s.inst_id) qcinst_id,
                     s.qcsid
                FROM sqlt$_gv$pq_slave e,
                     sqlt$_gv$px_process p,
                     sqlt$_gv$px_session s
               WHERE e.statement_id = s_sql_rec.statement_id
                 AND e.begin_end_flag = 'E'
                 AND e.statement_id = p.statement_id
                 AND e.inst_id = p.inst_id
                 AND e.slave_name = p.server_name
                 AND p.begin_end_flag = 'E'
                 AND p.statement_id = s.statement_id(+)
                 AND 'E' = s.begin_end_flag(+)
                 AND p.inst_id = s.inst_id(+)
                 AND p.sid = s.sid(+)
                 AND p.serial# = s.serial#(+)
               ORDER BY
                     e.inst_id,
                     e.slave_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Inst ID'));
        wa(th('Slave Name'));
        wa(th('Status'));
        wa(th('Sessions'));
        wa(th('Idle Time Current Session'));
        wa(th('Busy Time Current Session'));
        wa(th('CPU Seconds Current Session'));
        wa(th('Messages Sent Current Session'));
        wa(th('Messages Received Current Session'));
        wa(th('Idle Time Total'));
        wa(th('Busy Time Total'));
        wa(th('CPU Seconds Total'));
        wa(th('Messages Sent Total'));
        wa(th('Messages Received Total'));
        wa(th('Query Coordinator<br>Inst ID'));
        wa(th('Query Coordinator<br>Session ID SID'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.inst_id));
      wa(td(i.slave_name, 'l'));
      wa(td(i.status));
      wa(td(i.sessions, 'r'));
      wa(td(i.idle_time_cur, 'r'));
      wa(td(i.busy_time_cur, 'r'));
      wa(td(i.cpu_secs_cur, 'r'));
      wa(td(i.msgs_sent_cur, 'r'));
      wa(td(i.msgs_rcvd_cur, 'r'));
      wa(td(i.idle_time_total, 'r'));
      wa(td(i.busy_time_total, 'r'));
      wa(td(i.cpu_secs_total, 'r'));
      wa(td(i.msgs_sent_total, 'r'));
      wa(td(i.msgs_rcvd_total, 'r'));
      wa(td(i.qcinst_id));
      wa(td(i.qcsid));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);
    wa(show_hide_end);
    */

    l_sql := '
SELECT p.inst_id,
       p.server_name,
       p.status,
       p.pid,
       p.spid,
       p.sid,
       p.serial#,
       NVL(s.qcinst_id, s.inst_id) qcinst_id,
       s.qcsid,
       NVL(s.qcserial#, s.serial#) qcserial#
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_process p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_session s
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.begin_end_flag = ''E''
   AND p.statement_id = s.statement_id(+)
   AND ''E'' = s.begin_end_flag(+)
   AND p.inst_id = s.inst_id(+)
   AND p.sid = s.sid(+)
   AND p.serial# = s.serial#(+)
 ORDER BY
       p.inst_id,
       p.server_name;';

    wa(h3(mot('PX Processes', 'GV$PX_PROCESS'), 'px_process', FALSE));
    wa('Parallel-execution processes, and sessions running on them.');
    wa('<br>');
    --wa('List restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    --wa('<br>');
    wa(hide_sql(l_sql));
    /*
    wa(hide_begin);
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT p.inst_id,
                     p.server_name,
                     p.status,
                     p.pid,
                     p.spid,
                     p.sid,
                     p.serial#,
                     NVL(s.qcinst_id, s.inst_id) qcinst_id,
                     s.qcsid,
                     NVL(s.qcserial#, s.serial#) qcserial#
                FROM sqlt$_gv$px_process p,
                     sqlt$_gv$px_session s
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.begin_end_flag = 'E'
                 AND p.statement_id = s.statement_id(+)
                 AND 'E' = s.begin_end_flag(+)
                 AND p.inst_id = s.inst_id(+)
                 AND p.sid = s.sid(+)
                 AND p.serial# = s.serial#(+)
               ORDER BY
                     p.inst_id,
                     p.server_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Inst ID'));
        wa(th('Server Name'));
        wa(th('Status'));
        wa(th('Process Identifier PID'));
        wa(th('OS Process Identifier SPID'));
        wa(th('Session ID SID<sup>1</sup>'));
        wa(th('Session Serial Number<sup>1</sup>'));
        wa(th('Query Coordinator<br>Inst ID'));
        wa(th('Query Coordinator<br>Session ID SID'));
        wa(th('Query Coordinator<br>Serial Number'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.inst_id));
      wa(td(i.server_name, 'l'));
      wa(td(i.status));
      wa(td(i.pid));
      wa(td(i.spid));
      wa(td(i.sid));
      wa(td(i.serial#));
      wa(td(i.qcinst_id));
      wa(td(i.qcsid));
      wa(td(i.qcserial#));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) If the PX Server is in use.'));
    wa('<br>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);
    wa(show_hide_end);
    */

    l_sql := '
SELECT NVL(s.qcinst_id, s.inst_id) qcinst_id,
       s.qcsid,
       NVL(s.qcserial#, s.serial#) qcserial#,
       s.server_group,
       s.server_set,
       s.server#,
       s.degree,
       s.req_degree,
       s.inst_id,
       s.sid,
       s.serial#,
       p.server_name
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_session s,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_gv$px_process p
 WHERE s.statement_id = '||s_sql_rec.statement_id||'
   AND s.begin_end_flag = ''E''
   AND s.statement_id = p.statement_id(+)
   AND ''E'' = p.begin_end_flag(+)
   AND s.inst_id = p.inst_id(+)
   AND s.sid = p.sid(+)
   AND s.serial# = p.serial#(+)
 ORDER BY
       NVL(s.qcinst_id, s.inst_id),
       s.qcsid,
       NVL(s.qcserial#, s.serial#),
       s.server_group NULLS FIRST,
       s.server_set NULLS FIRST,
       s.server# NULLS FIRST,
       s.inst_id,
       s.sid,
       s.serial#;';

    wa(h3(mot('PX Sessions', 'GV$PX_SESSION'), 'px_session', FALSE));
    wa('Sessions running on parallel-execution servers.');
    wa('<br>');
    --wa('List restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    --wa('<br>');
    wa(hide_sql(l_sql));
    /*
    wa(hide_begin);
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT NVL(s.qcinst_id, s.inst_id) qcinst_id,
                     s.qcsid,
                     NVL(s.qcserial#, s.serial#) qcserial#,
                     s.server_group,
                     s.server_set,
                     s.server#,
                     s.degree,
                     s.req_degree,
                     s.inst_id,
                     s.sid,
                     s.serial#,
                     p.server_name
                FROM sqlt$_gv$px_session s,
                     sqlt$_gv$px_process p
               WHERE s.statement_id = s_sql_rec.statement_id
                 AND s.begin_end_flag = 'E'
                 AND s.statement_id = p.statement_id(+)
                 AND 'E' = p.begin_end_flag(+)
                 AND s.inst_id = p.inst_id(+)
                 AND s.sid = p.sid(+)
                 AND s.serial# = p.serial#(+)
               ORDER BY
                     NVL(s.qcinst_id, s.inst_id),
                     s.qcsid,
                     NVL(s.qcserial#, s.serial#),
                     s.server_group NULLS FIRST,
                     s.server_set NULLS FIRST,
                     s.server# NULLS FIRST,
                     s.inst_id,
                     s.sid,
                     s.serial#)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Query Coordinator<br>Inst ID'));
        wa(th('Query Coordinator<br>Session ID SID'));
        wa(th('Query Coordinator<br>Serial Number'));
        wa(th('Server<br>Group<sup>1</sup>'));
        wa(th('Server<br>Set<sup>1</sup>'));
        wa(th('Server<br>Number<sup>1</sup>'));
        wa(th('Parallel Degree<br>Used<sup>1</sup>'));
        wa(th('Parallel Degree<br>Requested<sup>1</sup>'));
        wa(th('Session<br>Inst ID'));
        wa(th('Session<br>ID SID'));
        wa(th('Session<br>Serial Number'));
        wa(th('Server Name'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.qcinst_id));
      wa(td(i.qcsid));
      wa(td(i.qcserial#));
      wa(td(i.server_group));
      wa(td(i.server_set));
      wa(td(i.server#));
      wa(td(i.degree));
      wa(td(i.req_degree));
      wa(td(i.inst_id));
      wa(td(i.sid));
      wa(td(i.serial#));
      wa(td(i.server_name, 'l'));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) NULL for Query Coordinator.'));
    wa('<br>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);
    wa(show_hide_end);
    */

    wa(h3(mot('PX System Statistics - Summary', 'GV$PQ_SYSSTAT'), 'pq_sysstat', FALSE));
    wa('System statistics for parallel-execution servers.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT statistic,
                     inst_id,
                     value
                FROM sqlt$_gv$pq_sysstat
               WHERE statement_id = s_sql_rec.statement_id
                 AND begin_end_flag = 'E'
               ORDER BY
                     inst_id,
                     ROWID)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('Statistic'));
        wa(th('Inst ID'));
        wa(th('Value'));
        wa('</tr>');
      END IF;
      wr(i.statistic, i.inst_id, 'c', i.value, 'r');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);

    wa(h3(mot('PX Process System Statistics - Summary', 'GV$PX_PROCESS_SYSSTAT'), 'px_process_sysstat', FALSE));
    wa('Process system statistics for parallel-execution servers.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT statistic,
                     inst_id,
                     value
                FROM sqlt$_gv$px_process_sysstat
               WHERE statement_id = s_sql_rec.statement_id
                 AND begin_end_flag = 'E'
               ORDER BY
                     inst_id,
                     ROWID)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('Statistic'));
        wa(th('Inst ID'));
        wa(th('Value'));
        wa('</tr>');
      END IF;
      wr(i.statistic, i.inst_id, 'c', i.value, 'r');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Parallel Processing', 'parallel_exec'));
    wa(go_to_top);

  EXCEPTION
    WHEN OTHERS THEN
      write_error('parallel_processing_sec2: '||SQLERRM);
  END parallel_processing_sec2;

  /*************************************************************************************/

  /* -------------------------
   *
   * private plan_info
   *
   * ------------------------- */
  FUNCTION plan_info (
    p_statement_id    IN NUMBER,
    p_plan_hash_value IN NUMBER,
    p_source          IN VARCHAR2 DEFAULT '-666',
    p_plan_timestamp  IN DATE     DEFAULT TRUNC(SYSDATE),
    p_plan_id         IN NUMBER   DEFAULT -1,
    p_inst_id         IN NUMBER   DEFAULT -1,
    p_child_number    IN NUMBER   DEFAULT -1,
    p_child_address   IN VARCHAR2 DEFAULT '-666' )
  RETURN VARCHAR2
  IS
    l_row_count NUMBER := 0;
    l_plan_info VARCHAR2(32767);
  BEGIN
    FOR i IN (SELECT DISTINCT
                     info_type,
                     info_value
                FROM sqlt$_plan_info
               WHERE statement_id = p_statement_id
                 AND plan_hash_value = p_plan_hash_value
                 AND (NVL(source, '-666') = NVL(p_source, '-666') OR NVL(p_source, '-666') = '-666')
                 AND (NVL(plan_timestamp, TRUNC(SYSDATE)) = NVL(p_plan_timestamp, TRUNC(SYSDATE)) OR NVL(p_plan_timestamp, TRUNC(SYSDATE)) = TRUNC(SYSDATE))
                 --AND (NVL(plan_id, -666) = NVL(p_plan_id, -666) OR NVL(p_plan_id, -666) = -666)
                 --AND (NVL(plan_id, -1) = NVL(p_plan_id, -1) OR NVL(p_plan_id, -1) = -1)
                 AND (NVL(plan_id, -1) = NVL(p_plan_id, -1))
                 AND (NVL(inst_id, -1) = NVL(p_inst_id, -1) OR NVL(p_inst_id, -1) = -1)
                 AND (NVL(child_number, -1) = NVL(p_child_number, -1) OR NVL(p_child_number, -1) = -1)
                 AND (NVL(child_address, '-666') = NVL(p_child_address, '-666') OR NVL(p_child_address, '-666') = '-666')
                 AND info_type IN (
                     'adaptive_plan',
                     'baseline',
                     'cardinality_feedback',
                     'dop',
                     'dop_op_reason',
                     'dop_reason',
                     'dynamic_sampling',
                     'gtt_session_st',					 
                     'index_size',
                     'outline',
                     --'plan_hash',
                     'queuing_reason',
                     'result_checksum',
                     'row_shipping',
                     'sql_patch',
                     'sql_profile',
                     'xml_suboptimal')
               ORDER BY
                     info_type,
                     info_value)
    LOOP
      l_row_count := l_row_count + 1;
      IF l_row_count = 1 THEN
        l_plan_info := '<table>';
      END IF;

      l_plan_info := l_plan_info||'<tr><td class="t">'||i.info_type||'</td><td class="l">'||i.info_value||'</td></tr>';
    END LOOP;

    IF l_row_count > 0 THEN
      l_plan_info := l_plan_info||'</table>';
    END IF;

    RETURN l_plan_info;
  END plan_info;

  /*************************************************************************************/

  /* -------------------------
   *
   * private plan_stability
   *
   * ------------------------- */
  FUNCTION plan_stability (
    p_statement_id    IN NUMBER,
    p_plan_hash_value IN NUMBER,
    p_inst_id         IN NUMBER   DEFAULT -1,
    p_child_number    IN NUMBER   DEFAULT -1,
    p_child_address   IN VARCHAR2 DEFAULT '-666' )
  RETURN VARCHAR2
  IS
    l_row_count NUMBER := 0;
    l_plan_stability VARCHAR2(32767);
  BEGIN
    FOR i IN (SELECT ps_tool,
                     ps_id
                FROM
             (SELECT 'sql_profile' ps_tool,
                     sql_profile ps_id
                FROM sqlt$_gv$sql
               WHERE statement_id = p_statement_id
                 AND plan_hash_value = p_plan_hash_value
                 AND (NVL(inst_id, -1) = NVL(p_inst_id, -1) OR NVL(p_inst_id, -1) = -1)
                 AND (NVL(child_number, -1) = NVL(p_child_number, -1) OR NVL(p_child_number, -1) = -1)
                 AND (NVL(child_address, '-666') = NVL(p_child_address, '-666') OR NVL(p_child_address, '-666') = '-666')
                 AND sql_profile IS NOT NULL
               UNION
              SELECT 'sql_patch' ps_tool,
                     sql_patch ps_id
                FROM sqlt$_gv$sql
               WHERE statement_id = p_statement_id
                 AND plan_hash_value = p_plan_hash_value
                 AND (NVL(inst_id, -1) = NVL(p_inst_id, -1) OR NVL(p_inst_id, -1) = -1)
                 AND (NVL(child_number, -1) = NVL(p_child_number, -1) OR NVL(p_child_number, -1) = -1)
                 AND (NVL(child_address, '-666') = NVL(p_child_address, '-666') OR NVL(p_child_address, '-666') = '-666')
                 AND sql_patch IS NOT NULL
               UNION
              SELECT 'sql_plan_baseline' ps_tool,
                     sql_plan_baseline ps_id
                FROM sqlt$_gv$sql
               WHERE statement_id = p_statement_id
                 AND plan_hash_value = p_plan_hash_value
                 AND (NVL(inst_id, -1) = NVL(p_inst_id, -1) OR NVL(p_inst_id, -1) = -1)
                 AND (NVL(child_number, -1) = NVL(p_child_number, -1) OR NVL(p_child_number, -1) = -1)
                 AND (NVL(child_address, '-666') = NVL(p_child_address, '-666') OR NVL(p_child_address, '-666') = '-666')
                 AND sql_plan_baseline IS NOT NULL))
    LOOP
      l_row_count := l_row_count + 1;
      IF l_row_count = 1 THEN
        l_plan_stability := '<table>';
      END IF;

      l_plan_stability := l_plan_stability||'<tr><td class="t">'||i.ps_tool||'</td><td class="l">'||i.ps_id||'</td></tr>';
    END LOOP;

    IF l_row_count > 0 THEN
      l_plan_stability := l_plan_stability||'</table>';
    END IF;

    RETURN l_plan_stability;
  END plan_stability;

  /*************************************************************************************/

  /* -------------------------
   *
   * private plan_sum_sec
   *
   * ------------------------- */
  PROCEDURE plan_sum_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('plan_sum_sec');
    wa(h2(mot('Plans Summary', 'GV$SQLAREA_PLAN_HASH, DBA_HIST_SQLSTAT, EXPLAIN PLAN FOR and DBA_SQLTUNE_PLANS'), 'pln_sum'));

    wa('List of plans found ordered by average elapsed time.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT plan_hash_value,
                     link_id,
                     elapsed_time_secs,
                     cpu_time_secs,
                     user_io_wait_time_secs,
                     other_wait_time_secs,
                     buffer_gets,
                     disk_reads,
                     direct_writes,
                     rows_processed,
                     executions,
                     fetches,
                     version_count,
                     loads,
                     invalidations,
                     src,
                     source,
                     is_bind_sensitive,
                     min_optimizer_env_hash_value,
                     max_optimizer_env_hash_value,
                     optimizer_cost,
                     cardinality,
                     estimated_time_secs,
                     plan_timestamp,
                     first_load_time,
                     last_load_time
                FROM sqlt$_plan_summary_v2
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     elapsed_time ASC NULLS LAST,
                     src_order,
                     optimizer_cost ASC NULLS LAST)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan Hash Value<sup>1</sup>'));
        wa(th('Avg Elapsed Time in secs'));
        wa(th('Avg CPU Time in secs'));
        wa(th('Avg User I/O Wait Time in secs'));
        wa(th('Avg Other Wait Time in secs<sup>2</sup>'));
        wa(th('Avg Buffer Gets'));
        wa(th('Avg Disk Reads'));
        wa(th('Avg Direct Writes'));
        wa(th('Avg Rows Processed'));
        wa(th('Total Executions'));
        wa(th('Total Fetches'));
        wa(th('Total Version Count'));
        wa(th('Total Loads'));
        wa(th('Total Invalidations'));
        wa(th('Src'));
        wa(th('Source<sup>3</sup>'));
        wa(th('Plan Info<sup>3</sup>'));
        wa(th('Plan Stability<sup>3</sup>'));
        wa(th('Is Bind Sensitive'));
        wa(th('Min Opt Env'));
        wa(th('Max Opt Env'));
        wa(th('Opt Cost'));
        wa(th('Estimated Cardinality'));
        wa(th('Estimated Time in secs'));
        wa(th('Plan Timestamp'));
        wa(th('First Load Time<sup>4</sup>'));
        wa(th('Last Load Time<sup>4</sup>'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      IF sqlt$a.get_plan_link(s_sql_rec.statement_id, i.plan_hash_value) IS NULL THEN
        wa(td(i.plan_hash_value, 'l', 'nowrap'));
      ELSE
        wa(td(a_phv(i.plan_hash_value, 'plan_'||sqlt$a.get_plan_link(s_sql_rec.statement_id, i.plan_hash_value)), 'l', 'nowrap'));
      END IF;
      wa(td(i.elapsed_time_secs, 'r'));
      wa(td(i.cpu_time_secs, 'r'));
      wa(td(i.user_io_wait_time_secs, 'r'));
      wa(td(i.other_wait_time_secs, 'r'));
      wa(td(i.buffer_gets, 'r'));
      wa(td(i.disk_reads, 'r'));
      wa(td(i.direct_writes, 'r'));
      wa(td(i.rows_processed, 'r'));
      wa(td(i.executions, 'r'));
      wa(td(i.fetches, 'r'));
      wa(td(i.version_count, 'r'));
      wa(td(i.loads, 'r'));
      wa(td(i.invalidations, 'r'));
      wa(td(i.src));
      wa(td(i.source, 'l'));
      wa(td(plan_info(s_sql_rec.statement_id, i.plan_hash_value)));
      wa(td(plan_stability(s_sql_rec.statement_id, i.plan_hash_value)));
      wa(td(i.is_bind_sensitive));
      wa(td(i.min_optimizer_env_hash_value, 'l', 'nowrap'));
      IF i.min_optimizer_env_hash_value <> i.max_optimizer_env_hash_value THEN
        wa(td(i.max_optimizer_env_hash_value, 'l', 'nowrap'));
      ELSE
        wa(td(' '));
      END IF;
      wa(td(i.optimizer_cost, 'r'));
      wa(td(i.cardinality, 'r'));
      wa(td(i.estimated_time_secs, 'r'));
      wa(td(TO_CHAR(i.plan_timestamp, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.first_load_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_load_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) [B]est and [W]orst according to average elapsed time if available and had fetches, else by optimizer cost. [X]ecute Plan (only on XECUTE method).'));
    wa('<br>');
    wa(font('(2) Made of these wait times: application, concurrency, cluster, plsql and java execution.'));
    wa('<br>');
    wa(font('(3) Shows accurate Plan Info when source is actually "GV$SQLAREA_PLAN_HASH". For "DBA_HIST_SQLSTAT" source review "Plan Performance History" section. For "DBA_SQLTUNE_PLANS" or "EXPLAIN PLAN FOR" sources review Execution Plans section.'));
    wa('<br>');
    wa(font('(4) For plans from DBA_HIST_SQLSTAT this is the time of the begin/end snapshot that first/last collected metrics for a phv as per current history.'));
    wa('<br>');
    wa(go_to_sec('Cursor Sharing', 'cursor_sharing'));
    wa(go_to_sec('Adaptive Cursor Sharing', 'adaptive_cursor_sharing'));
    wa(go_to_sec('Execution Plans', 'pln_exe'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('plan_sum_sec: '||SQLERRM);
  END plan_sum_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private plan_stats_sec
   *
   * ------------------------- */
  PROCEDURE plan_stats_sec (
    p_plan_hash_value IN NUMBER,
    p_source          IN VARCHAR2,
    p_inst_id         IN NUMBER )
  IS
    sta_rec sqlt$_plan_stats_v%ROWTYPE;
  BEGIN
    write_log('plan_stats_sec_'||p_plan_hash_value||'_'||p_source||'_'||p_inst_id);

    SELECT *
      INTO sta_rec
      FROM sqlt$_plan_stats_v
     WHERE statement_id = s_sql_rec.statement_id
       AND plan_hash_value = p_plan_hash_value
       AND source = p_source
       AND inst_id = p_inst_id;

    wa('<table>');
    IF sta_rec.link_id IS NULL THEN
      wr('Plan Hash Value', sta_rec.plan_hash_value);
    ELSE
      wr('Plan Hash Value', a_phv(sta_rec.plan_hash_value, 'plan_'||sta_rec.link_id));
    END IF;
    wr('Src', sta_rec.src);
    wr('Source', sta_rec.source);
    wr('Is Bind Sensitive', sta_rec.is_bind_sensitive);
    wr('Inst ID', sta_rec.inst_id);
    wr('Version Count', sta_rec.version_count);
    wr('Executions', sta_rec.executions);
    wr('Elapsed Time in secs', TO_CHAR(ROUND(sta_rec.elapsed_time / 1e6, 3), SECONDS_FORMAT));
    wr('CPU Time in secs', TO_CHAR(ROUND(sta_rec.cpu_time / 1e6, 3), SECONDS_FORMAT));
    wr('User I/O Wait Time in secs', TO_CHAR(ROUND(sta_rec.user_io_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('Application Wait Time in secs', TO_CHAR(ROUND(sta_rec.application_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('Concurrency Wait Time in secs', TO_CHAR(ROUND(sta_rec.concurrency_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('Cluster Wait Time in secs', TO_CHAR(ROUND(sta_rec.cluster_wait_time / 1e6, 3), SECONDS_FORMAT));
    wr('PL/SQL Exec Time in secs', TO_CHAR(ROUND(sta_rec.plsql_exec_time / 1e6, 3), SECONDS_FORMAT));
    wr('Java Exec Time in secs', TO_CHAR(ROUND(sta_rec.java_exec_time / 1e6, 3), SECONDS_FORMAT));
    wr('Buffer Gets', sta_rec.buffer_gets);
    wr('Disk Reads', sta_rec.disk_reads);
    wr('Direct Writes', sta_rec.direct_writes);
    wr('Rows Processed', sta_rec.rows_processed);
    wr('Parse Calls', sta_rec.parse_calls);
    wr('Fetches', sta_rec.fetches);
    wr('End of Fetch count', sta_rec.end_of_fetch_count);
    wr('PX Servers Executions', sta_rec.px_servers_executions);
    wr('Loaded Versions', sta_rec.loaded_versions);
    wr('Loads', sta_rec.loads);
    wr('Invalidations', sta_rec.invalidations);
    wr('Open Versions', sta_rec.open_versions);
    wr('Kept Versions', sta_rec.kept_versions);
    wr('Users Executing', sta_rec.users_executing);
    wr('Users Opening', sta_rec.users_opening);
    wr('First Load Time', TO_CHAR(sta_rec.first_load_time, LOAD_DATE_FORMAT));
    wr('Last Load Time', TO_CHAR(sta_rec.last_load_time, LOAD_DATE_FORMAT));
    wr('Last Active Time', TO_CHAR(sta_rec.last_active_time, LOAD_DATE_FORMAT));
    wr('Snap ID', sta_rec.snap_id);
    wr('Snap Begin Date', TO_CHAR(sta_rec.snap_begin_date, LOAD_DATE_FORMAT));
    wr('Snap End Date', TO_CHAR(sta_rec.snap_end_date, LOAD_DATE_FORMAT));
    wr('Plan Timestamp', TO_CHAR(sta_rec.plan_timestamp, LOAD_DATE_FORMAT));
    wr('Sharable Memory', sta_rec.sharable_mem);
    wr('Persistent Memory', sta_rec.persistent_mem);
    wr('Runtime Memory', sta_rec.runtime_mem);
    wr('Sorts', sta_rec.sorts);
    wr('Serializable Aborts', sta_rec.serializable_aborts);
    wr('Command Type', sta_rec.command_type);
    wr('Optimizer Mode', sta_rec.optimizer_mode);
    wr('Optimizer Env', sta_rec.optimizer_env_hash_value);
    wr('Optimizer Cost', sta_rec.optimizer_cost);
    wr('Parsing User ID', sta_rec.parsing_user_id);
    wr('Parsing Schema ID', sta_rec.parsing_schema_id);
    wr('Parsing Schema Name', sta_rec.parsing_schema_name);
    wr('Module', sta_rec.module);
    wr('Action', sta_rec.action);
    --wr('SQL Patch', NVL(sta_rec.sql_patch, '"null"'));
    --wr('SQL Plan Baseline', NVL(sta_rec.sql_plan_baseline, '"null"'));
    wr('SQL Profile', NVL(sta_rec.sql_profile, '"null"'));
    wr('Exact Matching Signature', sta_rec.exact_matching_signature);
    wr('Force Matching Signature', sta_rec.force_matching_signature);
    wr('Outline Category', NVL(sta_rec.outline_category, '"null"'));
    wr('Remote', sta_rec.remote);
    wr('Object Status', sta_rec.object_status);
    wr('Program ID', sta_rec.program_id);
    wr('Program Line #', sta_rec.program_line#);
    wr('Typecheck Memory', sta_rec.typecheck_mem);
    wr('I/O Interconnect Bytes', sta_rec.io_interconnect_bytes);
    wr('Physical Read Requests', sta_rec.physical_read_requests);
    wr('Physical Read Bytes', sta_rec.physical_read_bytes);
    wr('Physical Write Requests', sta_rec.physical_write_requests);
    wr('Physical Write Bytes', sta_rec.physical_write_bytes);
    wr('Optimized Physical Read Requests', sta_rec.optimized_phy_read_requests);
    wr('Is Offloadable', sta_rec.is_offloadable);
    wr('I/O Cell Uncompressed Bytes', sta_rec.io_cell_uncompressed_bytes);
    wr('I/O Cell Offload Eligible Bytes', sta_rec.io_cell_offload_eligible_bytes);
    wr('I/O Cell Offload Returned Bytes', sta_rec.io_cell_offload_returned_bytes);
    wr('I/O Saved %', sta_rec.io_saved_percentage);
    --wr('Is Reoptimizable', sta_rec.is_reoptimizable);
    --wr('Is Resolved Adaptive Plan', sta_rec.is_resolved_adaptive_plan);		
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('plan_stats_sec_'||p_plan_hash_value||'_'||p_source||'_'||p_inst_id||': '||SQLERRM);
  END plan_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private plan_stats_sec
   *
   * ------------------------- */
  PROCEDURE plan_stats_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('plan_stats_sec');
    wa(h2(mot('Plan Performance Statistics', 'GV$SQLAREA_PLAN_HASH and DBA_HIST_SQLSTAT'), 'pln_sta'));

    wa('List ordered by phv, source and instance.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT plan_hash_value,
                     link_id,
                     src,
                     source,
                     is_bind_sensitive,
                     inst_id,
                     min_optimizer_env_hash_value,
                     max_optimizer_env_hash_value,
                     cnt_optimizer_env_hash_value,
                     optimizer_cost,
                     ROUND(elapsed_time / 1e6, 3) elapsed_time_secs,
                     ROUND(cpu_time / 1e6, 3) cpu_time_secs,
                     ROUND(user_io_wait_time / 1e6, 3) user_io_wait_time_secs,
                     ROUND(other_wait_time / 1e6, 3) other_wait_time_secs,
                     buffer_gets,
                     disk_reads,
                     direct_writes,
                     rows_processed,
                     executions,
                     fetches,
                     version_count,
                     loads,
                     invalidations,
                     plan_timestamp,
                     first_load_time,
                     last_load_time
                FROM sqlt$_plan_stats_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     plan_hash_value,
                     src_order,
                     inst_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan Hash Value'));
        wa(th('Src'));
        wa(th('Source'));
        wa(th('Plan Info'));
        wa(th('Plan Stability'));
        wa(th('Is Bind Sensitive'));
        wa(th('Inst ID'));
        wa(th('Stats'));
        wa(th('Total Elapsed Time in secs'));
        wa(th('Total CPU Time in secs'));
        wa(th('Total User I/O Wait Time in secs'));
        wa(th('Total Other Wait Time in secs<sup>1</sup>'));
        wa(th('Total Buffer Gets'));
        wa(th('Total Disk Reads'));
        wa(th('Total Direct Writes'));
        wa(th('Total Rows Processed'));
        wa(th('Total Executions'));
        wa(th('Total Fetches'));
        wa(th('Total Version Count'));
        wa(th('Total Loads'));
        wa(th('Total Invalidations'));
        wa(th('Opt Env Cnt'));
        wa(th('Min Opt Env'));
        wa(th('Max Opt Env'));
        wa(th('Cost'));
        wa(th('Plan Timestamp'));
        wa(th('First Load Time'));
        wa(th('Last Load Time'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      IF i.link_id IS NULL THEN
        wa(td(i.plan_hash_value, 'l', 'nowrap'));
      ELSE
        wa(td(a_phv(i.plan_hash_value, 'plan_'||i.link_id), 'l', 'nowrap'));
      END IF;
      wa(td(i.src));
      wa(td(i.source, 'l'));
      wa(td(plan_info(s_sql_rec.statement_id, i.plan_hash_value, i.inst_id)));
      IF i.src = 'MEM' THEN
        wa(td(plan_stability(s_sql_rec.statement_id, i.plan_hash_value, i.inst_id)));
      ELSE
        wa(td(' '));
      END IF;
      wa(td(i.is_bind_sensitive));
      wa(td(i.inst_id));
      wa(td(a('Stats', 'pln_sta_'||i.plan_hash_value)));
      wa(td(TO_CHAR(i.elapsed_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.cpu_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.user_io_wait_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.other_wait_time_secs, SECONDS_FORMAT), 'r'));
      wa(td(i.buffer_gets, 'r'));
      wa(td(i.disk_reads, 'r'));
      wa(td(i.direct_writes, 'r'));
      wa(td(i.rows_processed, 'r'));
      wa(td(i.executions, 'r'));
      wa(td(i.fetches, 'r'));
      wa(td(i.version_count, 'r'));
      wa(td(i.loads, 'r'));
      wa(td(i.invalidations, 'r'));
      wa(td(i.cnt_optimizer_env_hash_value, 'r'));
      wa(td(i.min_optimizer_env_hash_value, 'l', 'nowrap'));
      IF i.cnt_optimizer_env_hash_value > 1 THEN
        wa(td(i.max_optimizer_env_hash_value, 'l', 'nowrap'));
      ELSE
        wa(td(' '));
      END IF;
      wa(td(i.optimizer_cost, 'r'));
      wa(td(TO_CHAR(i.plan_timestamp, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.first_load_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_load_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) Made of these wait times: application, concurrency, cluster, plsql and java execution.'));
    wa('<br>');
    wa(go_to_sec('Execution Plans', 'pln_exe'));
    wa(go_to_sec('Plans Summary', 'pln_sum'));
    wa(go_to_top);

    FOR i IN (SELECT DISTINCT plan_hash_value
                FROM sqlt$_plan_stats_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     plan_hash_value)
    LOOP
      l_row_count := 0;
      FOR j IN (SELECT source,
                       inst_id,
                       link_id
                  FROM sqlt$_plan_stats_v
                 WHERE statement_id = s_sql_rec.statement_id
                   AND plan_hash_value = i.plan_hash_value
                 ORDER BY
                       src_order,
                       inst_id)
      LOOP
        l_row_count := l_row_count + 1;
        IF l_row_count = 1 THEN
          IF j.link_id IS NULL THEN
            wa(h4('Plan Performance Statistics for '||i.plan_hash_value, 'pln_sta_'||i.plan_hash_value));
          ELSE
            wa(h4('Plan Performance Statistics for '||a_phv(i.plan_hash_value, 'plan_'||j.link_id), 'pln_sta_'||i.plan_hash_value));
          END IF;
          wa('<table><tr>');
        END IF;
        wa('<td class="lw">');
        plan_stats_sec(i.plan_hash_value, j.source, j.inst_id);
        wa('</td>');
      END LOOP;

      IF l_row_count > 0 THEN
        wa('</tr></table>');
        wa(go_to_sec('Plan Performance Statistics', 'pln_sta'));
        wa(go_to_sec('Plans Summary', 'pln_sum'));
        wa(go_to_top);
      END IF;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('plan_stats_sec: '||SQLERRM);
  END plan_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private plan_history_delta_sec
   *
   * ------------------------- */
  PROCEDURE plan_history_delta_sec
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('plan_history_delta_sec');
    wa(h2(mot('Plan Performance History (delta)', 'DBA_HIST_SQLSTAT'), 'pln_his_delta'));

    l_sql := '
SELECT snap_id,
       begin_interval_time,
       end_interval_time,
       startup_time,
       instance_number,
       plan_hash_value,
       best_plan,
       worst_plan,
       xecute_plan,
       optimizer_env_hash_value,
       optimizer_cost,
       optimizer_mode,
       version_count,
       sharable_mem,
       loaded_versions,
       sql_profile,
       parsing_schema_id,
       parsing_schema_name,
       parsing_user_id,
       executions_delta,
       ROUND(elapsed_time_delta / 1e6, 3) elapsed_time_delta,
       ROUND(((elapsed_time_delta)/(GREATEST(executions_delta, 1))) / 1e3, 3) avg_elapsed_time_ms,
       ROUND(cpu_time_delta / 1e6, 3) cpu_time_delta,
       ROUND(iowait_delta / 1e6, 3) iowait_delta,
       ROUND(apwait_delta / 1e6, 3) apwait_delta,
       ROUND(ccwait_delta / 1e6, 3) ccwait_delta,
       ROUND(clwait_delta / 1e6, 3) clwait_delta,
       ROUND(plsexec_time_delta / 1e6, 3) plsexec_time_delta,
       ROUND(javexec_time_delta / 1e6, 3) javexec_time_delta,
       buffer_gets_delta,
       ROUND(((buffer_gets_delta)/(GREATEST(executions_delta, 1))) ) avg_buffer_gets,
       disk_reads_delta,
       direct_writes_delta,
       rows_processed_delta,
       parse_calls_delta,
       fetches_delta,
       end_of_fetch_count_delta,
       px_servers_execs_delta,
       loads_delta,
       invalidations_delta,
       sorts_delta,
       physical_read_requests_delta,
       physical_read_bytes_delta,
       physical_write_requests_delta,
       physical_write_bytes_delta,
       optimized_physical_reads_delta,
       cell_uncompressed_bytes_delta,
       io_offload_elig_bytes_delta,
       io_offload_return_bytes_delta,
       io_interconnect_bytes_delta
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_hist_sqlstat_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
 ORDER BY
       snap_id DESC,
       begin_interval_time DESC,
       instance_number,
       plan_hash_value;';

    wa('List restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT snap_id,
                     begin_interval_time,
                     end_interval_time,
                     startup_time,
                     instance_number,
                     plan_hash_value,
                     best_plan,
                     worst_plan,
                     xecute_plan,
                     optimizer_env_hash_value,
                     optimizer_cost,
                     optimizer_mode,
                     version_count,
                     sharable_mem,
                     loaded_versions,
                     sql_profile,
                     parsing_schema_id,
                     parsing_schema_name,
                     parsing_user_id,
                     executions_delta,
                     ROUND(elapsed_time_delta / 1e6, 3) elapsed_time_delta,
       	             ROUND(((elapsed_time_delta)/(GREATEST(executions_delta, 1))) / 1e3, 3) avg_elapsed_time_ms,
                     ROUND(cpu_time_delta / 1e6, 3) cpu_time_delta,
                     ROUND(iowait_delta / 1e6, 3) iowait_delta,
                     ROUND(apwait_delta / 1e6, 3) apwait_delta,
                     ROUND(ccwait_delta / 1e6, 3) ccwait_delta,
                     ROUND(clwait_delta / 1e6, 3) clwait_delta,
                     ROUND(plsexec_time_delta / 1e6, 3) plsexec_time_delta,
                     ROUND(javexec_time_delta / 1e6, 3) javexec_time_delta,
                     buffer_gets_delta,
                     ROUND(((buffer_gets_delta)/(GREATEST(executions_delta, 1))) ) avg_buffer_gets,
                     disk_reads_delta,
                     direct_writes_delta,
                     rows_processed_delta,
                     parse_calls_delta,
                     fetches_delta,
                     end_of_fetch_count_delta,
                     px_servers_execs_delta,
                     loads_delta,
                     invalidations_delta,
                     sorts_delta,
                     physical_read_requests_delta,
                     physical_read_bytes_delta,
                     physical_write_requests_delta,
                     physical_write_bytes_delta,
                     optimized_physical_reads_delta,
                     cell_uncompressed_bytes_delta,
                     io_offload_elig_bytes_delta,
                     io_offload_return_bytes_delta,
                     io_interconnect_bytes_delta
                FROM sqlt$_dba_hist_sqlstat_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     snap_id DESC,
                     begin_interval_time DESC,
                     instance_number,
                     plan_hash_value)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Snap ID'));
        wa(th('Begin Time'));
        wa(th('End Time'));
        wa(th('Startup Time'));
        wa(th('Inst ID'));
        wa(th('Plan Hash Value'));
        wa(th('Opt Env Hash Value'));
        wa(th('Cost'));
        wa(th('Opt Mode'));
        wa(th('Vers Count'));
        wa(th('Sharable Mem'));
        wa(th('Loaded Versions'));
        wa(th('SQL Profile'));
        wa(th('Parsing Schema ID'));
        wa(th('Parsing Schema Name'));
        wa(th('Parsing User ID'));
        wa(th('Executions (delta)'));
        wa(th('Elapsed Time in secs (delta)'));
        wa(th('Average Elapsed Time in ms (delta)'));
        wa(th('CPU Time in secs (delta)'));
        wa(th('I/O Wait Time in secs (delta)'));
        wa(th('Appl Wait Time in secs (delta)'));
        wa(th('Conc Wait Time in secs (delta)'));
        wa(th('Clust Wait Time in secs (delta)'));
        wa(th('PL/SQL Wait Time in secs (delta)'));
        wa(th('Java Wait Time in secs (delta)'));
        wa(th('Buffer Gets (delta)'));
        wa(th('Avg Buffer Gets(delta)'));
        wa(th('Disk Reads (delta)'));
        wa(th('Direct Writes (delta)'));
        wa(th('Rows Processed (delta)'));
        wa(th('Parse Calls (delta)'));
        wa(th('Fetches (delta)'));
        wa(th('End of Fetch Count (delta)'));
        wa(th('PX Server Execs (delta)'));
        wa(th('Loads (delta)'));
        wa(th('Invalidations (delta)'));
        wa(th('Sorts (delta)'));
        wa(th('Physical Read Requests (delta)'));
        wa(th('Physical Read Bytes (delta)'));
        wa(th('Physical Write Requests (delta)'));
        wa(th('Physical Write Bytes (delta)'));
        wa(th('Optimizer Physical Reads (delta)'));
        wa(th('Cell Uncompressed Bytes (delta)'));
        wa(th('I/O Offload Elig Bytes (delta)'));
        wa(th('I/O Offload Return Bytes (delta)'));
        wa(th('I/O Interconnect Bytes (delta)'));
        wa(th('Begin Time'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.snap_id));
      wa(td(TO_CHAR(i.begin_interval_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.end_interval_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.startup_time, TIMESTAMP_FORMAT3), 'c', 'nowrap'));
      wa(td(i.instance_number));
      wa(td(i.plan_hash_value||' '||i.best_plan||i.worst_plan||i.xecute_plan, 'l', 'nowrap'));
      wa(td(i.optimizer_env_hash_value, 'l', 'nowrap'));
      wa(td(i.optimizer_cost, 'r'));
      wa(td(i.optimizer_mode, 'l'));
      wa(td(i.version_count, 'r'));
      wa(td(i.sharable_mem, 'r'));
      wa(td(i.loaded_versions, 'r'));
      wa(td(i.sql_profile, 'l'));
      wa(td(i.parsing_schema_id, 'r'));
      wa(td(i.parsing_schema_name, 'l'));
      wa(td(i.parsing_user_id, 'r'));
      wa(td(i.executions_delta, 'r'));
      wa(td(TO_CHAR(i.elapsed_time_delta, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.avg_elapsed_time_ms, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.cpu_time_delta, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.iowait_delta, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.apwait_delta, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.ccwait_delta, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.clwait_delta, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.plsexec_time_delta, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.javexec_time_delta, SECONDS_FORMAT), 'r'));
      wa(td(i.buffer_gets_delta, 'r'));
      wa(td(i.avg_buffer_gets, 'r'));
      wa(td(i.disk_reads_delta, 'r'));
      wa(td(i.direct_writes_delta, 'r'));
      wa(td(i.rows_processed_delta, 'r'));
      wa(td(i.parse_calls_delta, 'r'));
      wa(td(i.fetches_delta, 'r'));
      wa(td(i.end_of_fetch_count_delta, 'r'));
      wa(td(i.px_servers_execs_delta, 'r'));
      wa(td(i.loads_delta, 'r'));
      wa(td(i.invalidations_delta, 'r'));
      wa(td(i.sorts_delta, 'r'));
      wa(td(i.physical_read_requests_delta, 'r'));
      wa(td(i.physical_read_bytes_delta, 'r'));
      wa(td(i.physical_write_requests_delta, 'r'));
      wa(td(i.physical_write_bytes_delta, 'r'));
      wa(td(i.optimized_physical_reads_delta, 'r'));
      wa(td(i.cell_uncompressed_bytes_delta, 'r'));
      wa(td(i.io_offload_elig_bytes_delta, 'r'));
      wa(td(i.io_offload_return_bytes_delta, 'r'));
      wa(td(i.io_interconnect_bytes_delta, 'r'));
      wa(td(TO_CHAR(i.begin_interval_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Execution Plans', 'pln_exe'));
    wa(go_to_sec('Plans Summary', 'pln_sum'));
    wa(go_to_top);

  EXCEPTION
    WHEN OTHERS THEN
      write_error('plan_history_delta_sec: '||SQLERRM);
  END plan_history_delta_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private plan_history_total_sec
   *
   * ------------------------- */
  PROCEDURE plan_history_total_sec
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);

  BEGIN
    write_log('plan_history_total_sec');
    wa(h2(mot('Plan Performance History (total)', 'DBA_HIST_SQLSTAT'), 'pln_his_total'));

    l_sql := '
SELECT snap_id,
       begin_interval_time,
       end_interval_time,
       startup_time,
       instance_number,
       plan_hash_value,
       best_plan,
       worst_plan,
       xecute_plan,
       optimizer_env_hash_value,
       optimizer_cost,
       optimizer_mode,
       version_count,
       sharable_mem,
       loaded_versions,
       sql_profile,
       parsing_schema_id,
       parsing_schema_name,
       parsing_user_id,
       executions_total,
       ROUND(elapsed_time_total / 1e6, 3) elapsed_time_total,
       ROUND(cpu_time_total / 1e6, 3) cpu_time_total,
       ROUND(iowait_total / 1e6, 3) iowait_total,
       ROUND(apwait_total / 1e6, 3) apwait_total,
       ROUND(ccwait_total / 1e6, 3) ccwait_total,
       ROUND(clwait_total / 1e6, 3) clwait_total,
       ROUND(plsexec_time_total / 1e6, 3) plsexec_time_total,
       ROUND(javexec_time_total / 1e6, 3) javexec_time_total,
       buffer_gets_total,
       disk_reads_total,
       direct_writes_total,
       rows_processed_total,
       parse_calls_total,
       fetches_total,
       end_of_fetch_count_total,
       px_servers_execs_total,
       loads_total,
       invalidations_total,
       sorts_total,
       physical_read_requests_total,
       physical_read_bytes_total,
       physical_write_requests_total,
       physical_write_bytes_total,
       optimized_physical_reads_total,
       cell_uncompressed_bytes_total,
       io_offload_elig_bytes_total,
       io_offload_return_bytes_total,
       io_interconnect_bytes_total
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_hist_sqlstat_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
 ORDER BY
       snap_id DESC,
       begin_interval_time DESC,
       instance_number,
       plan_hash_value;';

    wa('List restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT snap_id,
                     begin_interval_time,
                     end_interval_time,
                     startup_time,
                     instance_number,
                     plan_hash_value,
                     best_plan,
                     worst_plan,
                     xecute_plan,
                     optimizer_env_hash_value,
                     optimizer_cost,
                     optimizer_mode,
                     version_count,
                     sharable_mem,
                     loaded_versions,
                     sql_profile,
                     parsing_schema_id,
                     parsing_schema_name,
                     parsing_user_id,
                     executions_total,
                     ROUND(elapsed_time_total / 1e6, 3) elapsed_time_total,
                     ROUND(cpu_time_total / 1e6, 3) cpu_time_total,
                     ROUND(iowait_total / 1e6, 3) iowait_total,
                     ROUND(apwait_total / 1e6, 3) apwait_total,
                     ROUND(ccwait_total / 1e6, 3) ccwait_total,
                     ROUND(clwait_total / 1e6, 3) clwait_total,
                     ROUND(plsexec_time_total / 1e6, 3) plsexec_time_total,
                     ROUND(javexec_time_total / 1e6, 3) javexec_time_total,
                     buffer_gets_total,
                     disk_reads_total,
                     direct_writes_total,
                     rows_processed_total,
                     parse_calls_total,
                     fetches_total,
                     end_of_fetch_count_total,
                     px_servers_execs_total,
                     loads_total,
                     invalidations_total,
                     sorts_total,
                     physical_read_requests_total,
                     physical_read_bytes_total,
                     physical_write_requests_total,
                     physical_write_bytes_total,
                     optimized_physical_reads_total,
                     cell_uncompressed_bytes_total,
                     io_offload_elig_bytes_total,
                     io_offload_return_bytes_total,
                     io_interconnect_bytes_total
                FROM sqlt$_dba_hist_sqlstat_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     snap_id DESC,
                     begin_interval_time DESC,
                     instance_number,
                     plan_hash_value)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Snap ID'));
        wa(th('Begin Time'));
        wa(th('End Time'));
        wa(th('Startup Time'));
        wa(th('Inst ID'));
        wa(th('Plan Hash Value'));
        wa(th('Opt Env Hash Value'));
        wa(th('Cost'));
        wa(th('Opt Mode'));
        wa(th('Vers Count'));
        wa(th('Sharable Mem'));
        wa(th('Loaded Versions'));
        wa(th('SQL Profile'));
        wa(th('Parsing Schema ID'));
        wa(th('Parsing Schema Name'));
        wa(th('Parsing User ID'));
        wa(th('Executions (total)'));
        wa(th('Elapsed Time in secs (total)'));
        wa(th('CPU Time in secs (total)'));
        wa(th('I/O Wait Time in secs (total)'));
        wa(th('Appl Wait Time in secs (total)'));
        wa(th('Conc Wait Time in secs (total)'));
        wa(th('Clust Wait Time in secs (total)'));
        wa(th('PL/SQL Wait Time in secs (total)'));
        wa(th('Java Wait Time in secs (total)'));
        wa(th('Buffer Gets (total)'));
        wa(th('Disk Reads (total)'));
        wa(th('Direct Writes (total)'));
        wa(th('Rows Processed (total)'));
        wa(th('Parse Calls (total)'));
        wa(th('Fetches (total)'));
        wa(th('End of Fetch Count (total)'));
        wa(th('PX Server Execs (total)'));
        wa(th('Loads (total)'));
        wa(th('Invalidations (total)'));
        wa(th('Sorts (total)'));
        wa(th('Physical Read Requests (total)'));
        wa(th('Physical Read Bytes (total)'));
        wa(th('Physical Write Requests (total)'));
        wa(th('Physical Write Bytes (total)'));
        wa(th('Optimizer Physical Reads (total)'));
        wa(th('Cell Uncompressed Bytes (total)'));
        wa(th('I/O Offload Elig Bytes (total)'));
        wa(th('I/O Offload Return Bytes (total)'));
        wa(th('I/O Interconnect Bytes (total)'));
        wa(th('Begin Time'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.snap_id));
      wa(td(TO_CHAR(i.begin_interval_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.end_interval_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.startup_time, TIMESTAMP_FORMAT3), 'c', 'nowrap'));
      wa(td(i.instance_number));
      wa(td(i.plan_hash_value||' '||i.best_plan||i.worst_plan||i.xecute_plan, 'l', 'nowrap'));
      wa(td(i.optimizer_env_hash_value, 'l', 'nowrap'));
      wa(td(i.optimizer_cost, 'r'));
      wa(td(i.optimizer_mode, 'l'));
      wa(td(i.version_count, 'r'));
      wa(td(i.sharable_mem, 'r'));
      wa(td(i.loaded_versions, 'r'));
      wa(td(i.sql_profile, 'l'));
      wa(td(i.parsing_schema_id, 'r'));
      wa(td(i.parsing_schema_name, 'l'));
      wa(td(i.parsing_user_id, 'r'));
      wa(td(i.executions_total, 'r'));
      wa(td(TO_CHAR(i.elapsed_time_total, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.cpu_time_total, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.iowait_total, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.apwait_total, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.ccwait_total, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.clwait_total, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.plsexec_time_total, SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(i.javexec_time_total, SECONDS_FORMAT), 'r'));
      wa(td(i.buffer_gets_total, 'r'));
      wa(td(i.disk_reads_total, 'r'));
      wa(td(i.direct_writes_total, 'r'));
      wa(td(i.rows_processed_total, 'r'));
      wa(td(i.parse_calls_total, 'r'));
      wa(td(i.fetches_total, 'r'));
      wa(td(i.end_of_fetch_count_total, 'r'));
      wa(td(i.px_servers_execs_total, 'r'));
      wa(td(i.loads_total, 'r'));
      wa(td(i.invalidations_total, 'r'));
      wa(td(i.sorts_total, 'r'));
      wa(td(i.physical_read_requests_total, 'r'));
      wa(td(i.physical_read_bytes_total, 'r'));
      wa(td(i.physical_write_requests_total, 'r'));
      wa(td(i.physical_write_bytes_total, 'r'));
      wa(td(i.optimized_physical_reads_total, 'r'));
      wa(td(i.cell_uncompressed_bytes_total, 'r'));
      wa(td(i.io_offload_elig_bytes_total, 'r'));
      wa(td(i.io_offload_return_bytes_total, 'r'));
      wa(td(i.io_interconnect_bytes_total, 'r'));
      wa(td(TO_CHAR(i.begin_interval_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Execution Plans', 'pln_exe'));
    wa(go_to_sec('Plans Summary', 'pln_sum'));
    wa(go_to_top);

  EXCEPTION
    WHEN OTHERS THEN
      write_error('plan_history_total_sec: '||SQLERRM);
  END plan_history_total_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private plan_exec_sec
   *
   * ------------------------- */
  PROCEDURE plan_exec_sec (
    p_rec             IN sqlt$_plan_header_v%ROWTYPE,
    p_inst_id         IN NUMBER   DEFAULT NULL,
    p_child_number    IN NUMBER   DEFAULT NULL,
    p_child_address   IN VARCHAR2 DEFAULT NULL,
    p_child_timestamp IN DATE     DEFAULT NULL,
    p_executions      IN NUMBER   DEFAULT NULL,
    p_child_count     IN NUMBER   DEFAULT NULL )
  IS
    l_row_count NUMBER;
    l_heading VARCHAR2(32767);
    l_executions NUMBER := p_executions;
    l_stats NUMBER;
    l_more NUMBER;
    l_work NUMBER;
    l_binds_peek NUMBER;
    l_binds_capt NUMBER;
    l_pq NUMBER;
    l_par NUMBER;
    l_sql_exec_start DATE := NULL;
    l_sql_exec_id NUMBER := NULL;
    l_key NUMBER := NULL;
    l_mon_status VARCHAR2(32767) := NULL;
    l_last_starts NUMBER;
    l_last_output_rows NUMBER;
    l_sql_prefix VARCHAR2(32767);
    l_sql VARCHAR2(32767);
    l_tq VARCHAR2(32767);
    l_pointer NUMBER;
    l_first_load_time DATE;
    l_plan_flags sqlt$_plan_header_v.plan_flags%TYPE;
    sta_rec sqlt$_gv$sql_plan_statistics%ROWTYPE;
    cur_rec sqlt$_gv$sql%ROWTYPE;
  BEGIN
    write_log('plan_exec_sec_'||p_rec.link_id||'_'||p_inst_id||'_'||p_child_number||'_'||p_child_address);

    /* -------------------------
     *
     * prepare
     *
     * ------------------------- */
    BEGIN
      write_log('src = "'||p_rec.src||'"');
      write_log('source = "'||p_rec.source||'"');
      write_log('phv = "'||p_rec.plan_hash_value||'"');
      write_log('plan_id = "'||p_rec.plan_id||'"');
      write_log('inst_id = "'||p_inst_id||'"');
      write_log('child_number = "'||p_child_number||'"');
      write_log('child_address = "'||p_child_address||'"');

      IF p_rec.source = 'GV$SQL_PLAN' AND l_executions >= 0 THEN
        -- plan stats
        BEGIN
          SELECT *
            INTO sta_rec
            FROM sqlt$_gv$sql_plan_statistics
           WHERE statement_id = s_sql_rec.statement_id
             AND inst_id = p_inst_id
             AND child_number = p_child_number
             AND child_address = p_child_address
             AND operation_id = 1
             AND ROWNUM = 1;

          l_stats := 1;
          write_log('gv$sql_plan_statistics = "'||l_stats||'"');

          IF l_stats > 0 THEN
            -- care for max for each of these column
            SELECT MAX(last_starts),
                   MAX(starts),
                   MAX(last_output_rows),
                   MAX(output_rows),
                   MAX(last_cr_buffer_gets),
                   MAX(cr_buffer_gets),
                   MAX(last_cu_buffer_gets),
                   MAX(cu_buffer_gets),
                   MAX(last_disk_reads),
                   MAX(disk_reads),
                   MAX(last_disk_writes),
                   MAX(disk_writes),
                   MAX(last_elapsed_time),
                   MAX(elapsed_time)
              INTO sta_rec.last_starts,
                   sta_rec.starts,
                   sta_rec.last_output_rows,
                   sta_rec.output_rows,
                   sta_rec.last_cr_buffer_gets,
                   sta_rec.cr_buffer_gets,
                   sta_rec.last_cu_buffer_gets,
                   sta_rec.cu_buffer_gets,
                   sta_rec.last_disk_reads,
                   sta_rec.disk_reads,
                   sta_rec.last_disk_writes,
                   sta_rec.disk_writes,
                   sta_rec.last_elapsed_time,
                   sta_rec.elapsed_time
              FROM sqlt$_gv$sql_plan_statistics
             WHERE statement_id = s_sql_rec.statement_id
               AND inst_id = p_inst_id
               AND child_number = p_child_number
               AND child_address = p_child_address;

            write_log('last_starts = "'||sta_rec.last_starts||'"');
            write_log('starts = "'||sta_rec.starts||'"');
            write_log('last_output_rows = "'||sta_rec.last_output_rows||'"');
            write_log('output_rows = "'||sta_rec.output_rows||'"');
            write_log('last_cr_buffer_gets = "'||sta_rec.last_cr_buffer_gets||'"');
            write_log('cr_buffer_gets = "'||sta_rec.cr_buffer_gets||'"');
            write_log('last_cu_buffer_gets = "'||sta_rec.last_cu_buffer_gets||'"');
            write_log('cu_buffer_gets = "'||sta_rec.cu_buffer_gets||'"');
            write_log('last_disk_reads = "'||sta_rec.last_disk_reads||'"');
            write_log('disk_reads = "'||sta_rec.disk_reads||'"');
            write_log('last_disk_writes = "'||sta_rec.last_disk_writes||'"');
            write_log('disk_writes = "'||sta_rec.disk_writes||'"');
            write_log('last_elapsed_time = "'||sta_rec.last_elapsed_time||'"');
            write_log('elapsed_time = "'||sta_rec.elapsed_time||'"');
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            --write_log('** '||SQLERRM);
            l_executions := NULL;
            sta_rec := NULL;
            l_stats := NULL;
        END;
        write_log('executions = "'||l_executions||'"');

        -- plan monitor?
        FOR i IN (SELECT sql_exec_start, sql_exec_id, key, status
                    FROM sqlt$_gv$sql_monitor
                   WHERE statement_id = s_sql_rec.statement_id
                     AND sql_plan_hash_value = p_rec.plan_hash_value
                     AND inst_id = p_inst_id
                     AND sql_child_number = p_child_number -- this is an extended column
                     AND sql_child_address = p_child_address
                     AND process_name = 'ora'
                   ORDER BY
                         DECODE(status, 'EXECUTING', 'AA', 'DONE (ERROR)', 'AB', status),
                         sql_exec_start DESC,
                         sql_exec_id)
        LOOP
          l_sql_exec_start := i.sql_exec_start;
          l_sql_exec_id := i.sql_exec_id;
          l_key := i.key;
          l_mon_status := i.status;
          EXIT; -- 1st
        END LOOP;
        write_log('gv$sql_monitor.sql_exec_start = "'||TO_CHAR(l_sql_exec_start, LOAD_DATE_FORMAT)||'"');
        write_log('gv$sql_monitor.sql_exec_id = "'||l_sql_exec_id||'"');
        write_log('gv$sql_monitor.key = "'||l_key||'"');

        -- prepare to use plan monitor columns
        IF NVL(l_executions, 0) = 0 OR l_key > 0 THEN
          BEGIN
            IF NVL(sta_rec.last_starts, 0) = 0 AND NVL(sta_rec.last_output_rows, 0) = 0 AND l_key > 0 THEN
              l_mon_status := 'Last Starts and Last Output Rows were captured by SQL Plan Monitor. SQL Exec Start is "'||TO_CHAR(l_sql_exec_start, LOAD_DATE_FORMAT)||'". SQL Exec ID is "'||l_sql_exec_id||'". Status is "'||l_mon_status||'". Key is "'||l_key||'".';
            ELSE
              l_mon_status := NULL;
            END IF;

            IF l_mon_status IS NOT NULL THEN
              SELECT GREATEST(NVL(sta_rec.last_starts, 0), MAX(SUM(NVL(starts, 0)))),
                     GREATEST(NVL(sta_rec.last_output_rows, 0), MAX(SUM(NVL(output_rows, 0))))
                INTO sta_rec.last_starts,
                     sta_rec.last_output_rows
                FROM sqlt$_gv$sql_plan_monitor
               WHERE statement_id = s_sql_rec.statement_id
                 AND sql_plan_hash_value = p_rec.plan_hash_value
                 --AND inst_id = p_inst_id
                 --AND key = l_key
                 AND sql_exec_start = l_sql_exec_start
                 AND sql_exec_id = l_sql_exec_id
               GROUP BY
                     plan_line_id;

              write_log('last_starts = "'||sta_rec.last_starts||'"');
              write_log('last_output_rows = "'||sta_rec.last_output_rows||'"');
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
              write_log('** '||SQLERRM);
              write_log('gv$sql_monitor.key = "'||l_key||'"');
              l_sql_exec_start := NULL;
              l_sql_exec_id := NULL;
              l_key := NULL;
              l_mon_status := NULL;
          END;
        END IF;

        -- plan work areas
        SELECT COUNT(*)
          INTO l_work
          FROM sqlt$_gv$sql_workarea
         WHERE statement_id = s_sql_rec.statement_id
           AND inst_id = p_inst_id
           AND child_number = p_child_number
           AND ROWNUM = 1;
        write_log('gv$sql_workarea = "'||l_work||'"');

        -- cursor
        BEGIN
          SELECT *
            INTO cur_rec
            FROM sqlt$_gv$sql
           WHERE statement_id = s_sql_rec.statement_id
             AND inst_id = p_inst_id
             AND child_number = p_child_number
             AND child_address = p_child_address
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            cur_rec := NULL;
        END;
      ELSE
        cur_rec := NULL;
        sta_rec := NULL;
        l_stats := NULL;
        l_sql_exec_start := NULL;
        l_sql_exec_id := NULL;
        l_key := NULL;
        l_mon_status := NULL;
      END IF;

      -- column "more"
      SELECT COUNT(*)
        INTO l_more
        FROM sqlt$_plan_extension
       WHERE statement_id = s_sql_rec.statement_id
         AND source = p_rec.source
         AND plan_hash_value = p_rec.plan_hash_value
         AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
         AND more_html_table IS NOT NULL
         AND ROWNUM = 1;
      write_log('sqlt$_plan_extension.more = "'||l_more||'"');

      -- column "bind peek"
      SELECT COUNT(*)
        INTO l_binds_peek
        FROM sqlt$_plan_extension
       WHERE statement_id = s_sql_rec.statement_id
         AND source = p_rec.source
         AND plan_hash_value = p_rec.plan_hash_value
         AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
         AND binds_html_table IS NOT NULL
         AND ROWNUM = 1;
      write_log('sqlt$_plan_extension.binds_peek = "'||l_binds_peek||'"');

      -- column "bind capt"
      SELECT COUNT(*)
        INTO l_binds_capt
        FROM sqlt$_plan_extension
       WHERE statement_id = s_sql_rec.statement_id
         AND source = p_rec.source
         AND plan_hash_value = p_rec.plan_hash_value
         AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
         AND binds_html_table_capt IS NOT NULL
         AND ROWNUM = 1;
      write_log('sqlt$_plan_extension.binds_capt = "'||l_binds_peek||'"');

      -- "par" columns
      SELECT COUNT(*)
        INTO l_par
        FROM sqlt$_plan_extension
       WHERE statement_id = s_sql_rec.statement_id
         AND source = p_rec.source
         AND plan_hash_value = p_rec.plan_hash_value
         AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
         AND partition_start IS NOT NULL
         AND ROWNUM = 1;

      -- "pq" columns
      SELECT COUNT(*)
        INTO l_pq
        FROM sqlt$_plan_extension
       WHERE statement_id = s_sql_rec.statement_id
         AND source = p_rec.source
         AND plan_hash_value = p_rec.plan_hash_value
         AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
         AND other_tag LIKE '%PARALLEL%'
         AND ROWNUM = 1;

      -- sql
      BEGIN
        l_sql_prefix := 'SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('''||TOOL_ADMINISTER_SCHEMA||'.SQLT$_PLAN_STATISTICS_V'', '''||sqlt$a.get_statement_id_c(s_sql_rec.statement_id)||''', ';
        l_sql := 'SET ECHO OFF FEED OFF HEA OFF LIN 300 NEWP NONE TRIMS ON;'||LF;
        l_sql := l_sql||'SPO sqlt_s'||sqlt$a.get_statement_id_c(s_sql_rec.statement_id)||'_'||p_rec.plan_hash_value;
        IF p_rec.source = 'GV$SQL_PLAN' THEN
          l_sql := l_sql||'_'||p_inst_id||'_'||p_child_number||'.txt;'||LF;
          IF l_executions > 1 THEN
            l_sql := l_sql||l_sql_prefix||''''||sqlt$d.PLAN_FORMAT_L||''', ''source = '''''||p_rec.source||''''' AND inst_id = '||p_inst_id||' AND child_number = '||p_child_number||'''));'||LF;
          END IF;
          l_sql := l_sql||l_sql_prefix||''''||sqlt$d.PLAN_FORMAT_A||''', ''source = '''''||p_rec.source||''''' AND inst_id = '||p_inst_id||' AND child_number = '||p_child_number||'''));'||LF;
        ELSIF p_rec.source = 'DBA_HIST_SQL_PLAN' THEN
          l_sql := l_sql||'.txt;'||LF;
          l_sql := l_sql||l_sql_prefix||''''||sqlt$d.PLAN_FORMAT_V||''', ''source = '''''||p_rec.source||''''' AND plan_hash_value = '||p_rec.plan_hash_value||'''));'||LF;
        ELSIF p_rec.source = 'PLAN_TABLE' THEN
          l_sql := l_sql||'_'||p_rec.plan_id||'.txt;'||LF;
          l_sql := l_sql||l_sql_prefix||''''||sqlt$d.PLAN_FORMAT_V||''', ''source = '''''||p_rec.source||''''' AND plan_id = '||p_rec.plan_id||'''));'||LF;
        ELSIF p_rec.source = 'DBA_SQLTUNE_PLANS' THEN
          l_sql := l_sql||'_'||p_rec.plan_id||'.txt;'||LF;
          l_sql := l_sql||l_sql_prefix||''''||sqlt$d.PLAN_FORMAT_V||''', ''source = '''''||p_rec.source||''''' AND plan_id = '||p_rec.plan_id||'''));'||LF;
        END IF;
        l_sql := l_sql||'SPO OFF;';
      END;

      -- prepare title
      BEGIN
        l_plan_flags := get_plan_flags(p_rec.plan_hash_value);
        l_heading := 'Execution Plan'||NBSP2||'phv:'||p_rec.plan_hash_value||l_plan_flags||NBSP2||'sqlt_phv:'||p_rec.sqlt_plan_hash_value||NBSP2||'sqlt_phv2:'||p_rec.sqlt_plan_hash_value2||NBSP2||'source:'||p_rec.source;

        IF p_rec.attribute IS NOT NULL THEN
          l_heading := l_heading||NBSP2||'"'||p_rec.attribute||'"';
        ELSIF p_inst_id IS NOT NULL THEN
          l_heading := l_heading||NBSP2||'inst:'||p_inst_id||NBSP2||'child:'||p_child_number||'('||p_child_address||')'||NBSP2||'executions:'||p_executions;
          IF cur_rec.is_shareable IS NOT NULL THEN
            l_heading := l_heading||NBSP2||'is_sharable:'||cur_rec.is_shareable;
          END IF;
        END IF;

        l_heading := l_heading||NBSP2||'timestamp:'||TO_CHAR(NVL(p_child_timestamp, p_rec.timestamp), LOAD_DATE_FORMAT);

        IF p_rec.source = 'DBA_HIST_SQL_PLAN' THEN
          SELECT MIN(first_load_time)
            INTO l_first_load_time
            FROM sqlt$_dba_hist_sqlstat
           WHERE statement_id = s_sql_rec.statement_id
             AND plan_hash_value = p_rec.plan_hash_value;

          IF l_first_load_time IS NOT NULL THEN
            l_heading := l_heading||NBSP2||'oldest_snapshot:'||TO_CHAR(l_first_load_time, LOAD_DATE_FORMAT);
          END IF;
        END IF;
      END;

      -- title
      BEGIN
        IF NVL(p_child_count, 1) = 1 THEN
          wa(h3(l_heading, 'plan_'||p_rec.link_id)); -- inst_id and child_number left out intentionally
          wa_sql_text_show_hide;
        ELSE
          wa(h3(l_heading, NULL, FALSE)); -- inst_id and child_number left out intentionally
        END IF;

        IF p_rec.source = 'GV$SQL_PLAN' THEN
          wa(plan_stability(s_sql_rec.statement_id, p_rec.plan_hash_value, p_inst_id, p_child_number, p_child_address));
        END IF;
      END;
    END;

    /* -------------------------
     *
     * execution plan
     *
     * ------------------------- */
    BEGIN
      wa(hide_sql(l_sql));
      wa('<table>');

      l_row_count := 0;
      FOR i IN (SELECT x.id,
                       x.parent_id,
                       x.position,
                       x.exec_order,
                       NVL(p.plan_operation, x.plan_operation) plan_operation,
                       NVL(p.operation_caption, x.operation_caption) operation_caption,
                       x.goto_html_table,
                       x.cost,
                       x.top_cost,
                       x.io_cost,
                       x.cpu_cost,
                       x.bytes,
                       x.time,
                       x.cardinality,
                       s.last_starts,
                       s.last_output_rows,
                       s.last_cr_buffer_gets,
                       s.top_last_cr_buffer_gets,
                       s.last_cu_buffer_gets,
                       s.top_last_cu_buffer_gets,
                       s.last_disk_reads,
                       s.top_last_disk_reads,
                       s.last_disk_writes,
                       s.top_last_disk_writes,
                       s.last_elapsed_time,
                       s.top_last_elapsed_time,
                       s.starts,
                       s.output_rows,
                       s.cr_buffer_gets,
                       s.top_cr_buffer_gets,
                       s.cu_buffer_gets,
                       s.top_cu_buffer_gets,
                       s.disk_reads,
                       s.top_disk_reads,
                       s.disk_writes,
                       s.top_disk_writes,
                       s.elapsed_time,
                       s.top_elapsed_time,
                       x.object_name,
                       DECODE(x.other_tag,
                       'SERIAL', 'S',
                       'SERIAL_FROM_REMOTE', 'R='||GT||'S',
                       'PARALLEL_COMBINED_WITH_PARENT', 'PCWP',
                       'PARALLEL_COMBINED_WITH_CHILD', 'PCWC',
                       'PARALLEL_TO_SERIAL', 'P='||GT||'S',
                       'PARALLEL_TO_PARALLEL', 'P='||GT||'P',
                       'PARALLEL_FROM_SERIAL', 'S='||GT||'P',
                       x.other_tag) other_tag,
                       x.distribution,
                       x.partition_start,
                       x.partition_stop,
                       x.partition_id,
                       x.more_html_table,
                       NVL(p.binds_html_table, x.binds_html_table) binds_html_table,
                       NVL(p.binds_html_table_capt, x.binds_html_table_capt) binds_html_table_capt,
                       w.workarea_html_table
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan p,
                       sqlt$_gv$sql_plan_statistics s,
                       sqlt$_gv$sql_workarea w
                 WHERE x.statement_id = s_sql_rec.statement_id
                   AND x.source = p_rec.source
                   AND x.plan_hash_value = p_rec.plan_hash_value
                   AND NVL(x.plan_id, -666) = NVL(p_rec.plan_id, -666)
                   AND x.statement_id = p.statement_id(+)
                   AND x.plan_hash_value = p.plan_hash_value(+)
                   AND x.id = p.id(+)
                   AND p_inst_id = p.inst_id(+)
                   AND p_child_number = p.child_number(+)
                   AND p_child_address = p.child_address(+)
                   AND x.statement_id = s.statement_id(+)
                   AND x.plan_hash_value = s.plan_hash_value(+)
                   AND x.id = s.operation_id(+)
                   AND p_inst_id = s.inst_id(+)
                   AND p_child_number = s.child_number(+)
                   AND p_child_address = s.child_address(+)
                   AND x.statement_id = w.statement_id(+)
                   AND x.id = w.operation_id(+)
                   AND p_inst_id = w.inst_id(+)
                   AND p_child_number = w.child_number(+)
                 ORDER BY
                       x.id)
      LOOP
        l_row_count := l_row_count + 1;

        IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
          wa('<tr>');
          wa(th('ID'));
          wa(th(mot('Exec Ord', 'Operation Execution Order')));
          wa(th('Operation'));
          IF s_go_to = 'Y' THEN
            wa(th('Go To'));
          END IF;

          IF l_more > 0 THEN
            wa(th('More'));
          END IF;

          IF l_binds_peek > 0 THEN
            wa(th('Peek Bind'));
          END IF;

          IF l_binds_capt > 0 THEN
            wa(th('Capt Bind'));
          END IF;

          wa(th('Cost<sup>2</sup>'));
          wa(th('Estim Card'));

          IF (l_executions > 0 AND l_stats > 0) OR l_key > 0 THEN
            -- last execution
            IF s_plan_stats IN ('LAST', 'BOTH') THEN
              IF sta_rec.last_starts > 0 THEN
                wa(th('LAST<br>Starts'));
              END IF;

              wa(th('LAST<br>Output Rows'));

              IF sta_rec.last_output_rows > 0 AND sta_rec.last_starts > 0 THEN
                wa(th('LAST<br>Over/Under Estimate<sup>1</sup>'));
              END IF;

              IF sta_rec.last_cr_buffer_gets > 0 THEN
                wa(th(mot('LAST<br>CR Buffer Gets<sup>2</sup>', 'Consistent Mode')));
              END IF;

              IF sta_rec.last_cu_buffer_gets > 0 THEN
                wa(th(mot('LAST<br>CU Buffer Gets<sup>2</sup>', 'Current Mode')));
              END IF;

              IF sta_rec.last_disk_reads > 0 THEN
                wa(th('LAST<br>Disk Reads<sup>2</sup>'));
              END IF;

              IF sta_rec.last_disk_writes > 0 THEN
                wa(th('LAST<br>Disk Writes<sup>2</sup>'));
              END IF;

              IF sta_rec.last_elapsed_time > 0 THEN
                wa(th('LAST<br>Elapsed Time in secs<sup>2</sup>'));
              END IF;
            END IF;

            -- all executions
            IF (s_plan_stats IN ('ALL', 'BOTH') AND l_executions > 1 AND l_stats > 0) OR
               (s_plan_stats = 'ALL' AND l_executions = 1 AND l_stats > 0)
            THEN
              IF sta_rec.starts > 0 THEN
                wa(th('ALL<br>Starts'));
              END IF;

              wa(th('ALL<br>Output Rows'));

              IF sta_rec.output_rows > 0 AND sta_rec.starts > 0 THEN
                wa(th('ALL<br>Over/Under Estimate<sup>1</sup>'));
              END IF;

              IF sta_rec.cr_buffer_gets > 0 THEN
                wa(th(mot('ALL<br>CR Buffer Gets<sup>2</sup>', 'Consistent Mode')));
              END IF;

              IF sta_rec.cu_buffer_gets > 0 THEN
                wa(th(mot('ALL<br>CU Buffer Gets<sup>2</sup>', 'Current Mode')));
              END IF;

              IF sta_rec.disk_reads > 0 THEN
                wa(th('ALL<br>Disk Reads<sup>2</sup>'));
              END IF;

              IF sta_rec.disk_writes > 0 THEN
                wa(th('ALL<br>Disk Writes<sup>2</sup>'));
              END IF;

              IF sta_rec.elapsed_time > 0 THEN
                wa(th('ALL<br>Elapsed Time in secs<sup>2</sup>'));
              END IF;
            END IF;
          END IF;

          IF l_par > 0 THEN
            wa(th(mot('PStart', 'Partition Start')));
            wa(th(mot('PStop', 'Partition Stop')));
          END IF;

          IF l_pq > 0 THEN
            wa(th(mot('TQ', 'Data Flow Operator (DFO) tree number, Table Queue ID')));
            wa(th('IN-OUT'));
            wa(th('PQ Distrib'));
          END IF;

          IF p_rec.source = 'GV$SQL_PLAN' AND l_work > 0 THEN
            wa(th('Work Area'));
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

        wa(td(mot(i.plan_operation, i.operation_caption, p_nl_class => 'op'), 'op', 'nowrap'));

        IF s_go_to = 'Y' THEN
          IF i.goto_html_table IS NULL THEN
            wa(td(NBSP));
          ELSE
            wa_td_hide(i.goto_html_table);
          END IF;
        END IF;

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

        IF i.top_cost IS NULL THEN
          IF i.io_cost IS NULL AND i.cpu_cost IS NULL AND i.bytes IS NULL AND i.time IS NULL THEN
            wa(td(i.cost, 'r'));
          ELSE
            wa(td(mot(i.cost, 'io_cost:'||i.io_cost||NBSP2||'cpu_cost:'||i.cpu_cost||'<br>bytes:'||i.bytes||NBSP2||'estim_secs:'||TO_CHAR(i.time, SECONDS_FORMAT), p_nl_class => 'nlb'), 'r'));
          END IF;
        ELSE
          wa(td(red(i.cost, i.top_cost, p_rec.cost, 'io_cost:'||i.io_cost||NBSP2||'cpu_cost:'||i.cpu_cost||'<br>bytes:'||i.bytes||NBSP2||'estim_secs:'||TO_CHAR(i.time, SECONDS_FORMAT)), 'r'));
        END IF;

        wa(td(i.cardinality, 'r'));

        IF (l_executions > 0 AND l_stats > 0) OR l_key > 0  THEN
          -- last execution
          IF s_plan_stats IN ('LAST', 'BOTH') THEN

            IF sta_rec.last_starts > 0 THEN
              IF NVL(i.last_starts, 0) = 0 AND l_key > 0 THEN
                SELECT SUM(starts)
                  INTO l_last_starts
                  FROM sqlt$_gv$sql_plan_monitor
                 WHERE statement_id = s_sql_rec.statement_id
                   AND sql_plan_hash_value = p_rec.plan_hash_value
                   AND sql_exec_start = l_sql_exec_start
                   AND sql_exec_id = l_sql_exec_id
                   AND plan_line_id = i.id;
              ELSE
                l_last_starts := i.last_starts;
              END IF;

              wa(td(l_last_starts, 'r'));
            END IF;

            IF NVL(i.last_output_rows, 0) = 0 AND l_key > 0 THEN
              SELECT SUM(output_rows)
                INTO l_last_output_rows
                FROM sqlt$_gv$sql_plan_monitor
               WHERE statement_id = s_sql_rec.statement_id
                 AND sql_plan_hash_value = p_rec.plan_hash_value
                 AND sql_exec_start = l_sql_exec_start
                 AND sql_exec_id = l_sql_exec_id
                 AND plan_line_id = i.id;
            ELSE
              l_last_output_rows := i.last_output_rows;
            END IF;

            wa(td(l_last_output_rows, 'r'));

            IF sta_rec.last_output_rows > 0 AND sta_rec.last_starts > 0 THEN
              wa(td(sqlt$r.over_under_difference(i.cardinality * l_last_starts, l_last_output_rows, 10, 100, 1000), 'r'));
            END IF;

            IF sta_rec.last_cr_buffer_gets > 0 THEN
              IF i.top_last_cr_buffer_gets IS NULL THEN
                wa(td(i.last_cr_buffer_gets, 'r'));
              ELSE
                wa(td(red(i.last_cr_buffer_gets, i.top_last_cr_buffer_gets, sta_rec.last_cr_buffer_gets), 'r'));
              END IF;
            END IF;

            IF sta_rec.last_cu_buffer_gets > 0 THEN
              IF i.top_last_cu_buffer_gets IS NULL THEN
                wa(td(i.last_cu_buffer_gets, 'r'));
              ELSE
                wa(td(red(i.last_cu_buffer_gets, i.top_last_cu_buffer_gets, sta_rec.last_cu_buffer_gets), 'r'));
              END IF;
            END IF;

            IF sta_rec.last_disk_reads > 0 THEN
              IF i.top_last_disk_reads IS NULL THEN
                wa(td(i.last_disk_reads, 'r'));
              ELSE
                wa(td(red(i.last_disk_reads, i.top_last_disk_reads, sta_rec.last_disk_reads), 'r'));
              END IF;
            END IF;

            IF sta_rec.last_disk_writes > 0 THEN
              IF i.top_last_disk_writes IS NULL THEN
                wa(td(i.last_disk_writes, 'r'));
              ELSE
                wa(td(red(i.last_disk_writes, i.top_last_disk_writes, sta_rec.last_disk_writes), 'r'));
              END IF;
            END IF;

            IF sta_rec.last_elapsed_time > 0 THEN
              IF i.top_last_elapsed_time IS NULL THEN
                wa(td(TO_CHAR(ROUND(i.last_elapsed_time / 1e6, 3), SECONDS_FORMAT), 'r'));
              ELSE
                wa(td(red(i.last_elapsed_time, i.top_last_elapsed_time, sta_rec.last_elapsed_time, p_value_type => 'T'), 'r'));
              END IF;
            END IF;
          END IF;

          -- all executions
          IF (s_plan_stats IN ('ALL', 'BOTH') AND l_executions > 1 AND l_stats > 0) OR
             (s_plan_stats = 'ALL' AND l_executions = 1 AND l_stats > 0)
          THEN
            IF sta_rec.starts > 0 THEN
              wa(td(i.starts, 'r'));
            END IF;

            wa(td(i.output_rows, 'r'));

            IF sta_rec.output_rows > 0 AND sta_rec.starts > 0 THEN
              wa(td(sqlt$r.over_under_difference(i.cardinality * i.starts, i.output_rows, 10, 100, 1000), 'r'));
            END IF;

            IF sta_rec.cr_buffer_gets > 0 THEN
              IF i.top_cr_buffer_gets IS NULL THEN
                wa(td(i.cr_buffer_gets, 'r'));
              ELSE
                wa(td(red(i.cr_buffer_gets, i.top_cr_buffer_gets, sta_rec.cr_buffer_gets), 'r'));
              END IF;
            END IF;

            IF sta_rec.cu_buffer_gets > 0 THEN
              IF i.top_cu_buffer_gets IS NULL THEN
                wa(td(i.cu_buffer_gets, 'r'));
              ELSE
                wa(td(red(i.cu_buffer_gets, i.top_cu_buffer_gets, sta_rec.cu_buffer_gets), 'r'));
              END IF;
            END IF;

            IF sta_rec.disk_reads > 0 THEN
              IF i.top_disk_reads IS NULL THEN
                wa(td(i.disk_reads, 'r'));
              ELSE
                wa(td(red(i.disk_reads, i.top_disk_reads, sta_rec.disk_reads), 'r'));
              END IF;
            END IF;

            IF sta_rec.disk_writes > 0 THEN
              IF i.top_disk_writes IS NULL THEN
                wa(td(i.disk_writes, 'r'));
              ELSE
                wa(td(red(i.disk_writes, i.top_disk_writes, sta_rec.disk_writes), 'r'));
              END IF;
            END IF;

            IF sta_rec.elapsed_time > 0 THEN
              IF i.top_elapsed_time IS NULL THEN
                wa(td(TO_CHAR(ROUND(i.elapsed_time / 1e6, 3), SECONDS_FORMAT), 'r'));
              ELSE
                wa(td(red(i.elapsed_time, i.top_elapsed_time, sta_rec.elapsed_time, p_value_type => 'T'), 'r'));
              END IF;
            END IF;
          END IF;
        END IF;

        IF l_par > 0 THEN
          wa(td(i.partition_start, 'r'));
          wa(td(i.partition_stop, 'r'));
        END IF;

        IF l_pq > 0 THEN
          IF i.object_name LIKE '%:TQ%' OR i.object_name LIKE '%TQ:%' THEN
            BEGIN
              l_tq := REPLACE(i.object_name, ':TQ');
              l_tq := REPLACE(i.object_name, 'TQ:');
              l_pointer := INSTR(l_tq, '0');
              l_tq := 'Q'||SUBSTR(l_tq, 1, l_pointer - 1)||','||TO_CHAR(TO_NUMBER(SUBSTR(l_tq, l_pointer)));
            EXCEPTION
              WHEN OTHERS THEN
                l_tq := i.object_name;
            END;
          ELSE
            l_tq := NULL;
          END IF;

          wa(td(l_tq));
          wa(td(i.other_tag, 'l'));
          wa(td(i.distribution, 'l'));
        END IF;

        IF p_rec.source = 'GV$SQL_PLAN' AND l_work > 0 THEN
          IF i.workarea_html_table IS NULL THEN
            wa(td(NBSP));
          ELSE
            wa_td_hide(i.workarea_html_table);
          END IF;
        END IF;

        wa('</tr>');
      END LOOP;

      wa('</table>');

      IF p_rec.source = 'GV$SQL_PLAN' THEN
        wa(font('Performance statistics are only available when parameter "statistics_level" was set to "ALL" at hard-parse time, or SQL contains "gather_plan_statistics" hint.'));
        wa('<br>');
        IF l_mon_status IS NOT NULL THEN
          wa(font(l_mon_status));
          wa('<br>');
        END IF;
      END IF;

      wa(font('(1) If estim_card * starts '||LT||' output_rows then under-estimate. If estim_card * starts '||GT||' output_rows then over-estimate. Color highlights when exceeding * 10x, ** 100x and *** 1000x over/under-estimates.'));
      wa('<br>');
      wa(font('(2) Largest contributors for cumulative-statistics columns are shown in ')||font('red', 'nr')||font('.'));
      wa('<br>');
    EXCEPTION
      WHEN OTHERS THEN
        write_error('execution_plan: '||SQLERRM);
    END;

    /* -------------------------
     *
     * other_xml
     *
     * ------------------------- */
    BEGIN
      FOR i IN (SELECT x.id,
                       NVL(p.sanitized_other_xml, x.sanitized_other_xml) sanitized_other_xml
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan p
                 WHERE x.statement_id = s_sql_rec.statement_id
                   AND x.source = p_rec.source
                   AND x.plan_hash_value = p_rec.plan_hash_value
                   AND NVL(x.plan_id, -666) = NVL(p_rec.plan_id, -666)
                   AND x.sanitized_other_xml IS NOT NULL
                   -- predicates below are only applicable to source = GV$SQL_PLAN
                   AND x.statement_id = p.statement_id(+)
                   AND x.plan_hash_value = p.plan_hash_value(+)
                   AND x.id = p.id(+)
                   AND p_inst_id = p.inst_id(+)
                   AND p_child_number = p.child_number(+)
                   AND p_child_address = p.child_address(+))
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
    EXCEPTION
      WHEN OTHERS THEN
        write_error('other_xml: '||SQLERRM);
    END;

    /* -------------------------
     *
     * outline_data
     *
     * ------------------------- */
    DECLARE
      l_outline_data CLOB;
      l_buffer VARCHAR2(32767);
    BEGIN
      FOR i IN (SELECT DISTINCT id
                  FROM sqlt$_outline_data
                 WHERE statement_id = s_sql_rec.statement_id
                   AND source = p_rec.source
                   AND plan_hash_value = p_rec.plan_hash_value
                   AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
                   AND NVL(inst_id, -1) = NVL(p_inst_id, -1)
                   AND NVL(child_number, -1) = NVL(p_child_number, -1)
                   AND NVL(child_address, '-666') = NVL(p_child_address, '-666')
                 ORDER BY
                       id)
      LOOP
        l_row_count := 0;

        FOR j IN (SELECT hint
                    FROM sqlt$_outline_data
                   WHERE statement_id = s_sql_rec.statement_id
                     AND source = p_rec.source
                     AND plan_hash_value = p_rec.plan_hash_value
                     AND id = i.id
                     AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
                     AND NVL(inst_id, -1) = NVL(p_inst_id, -1)
                     AND NVL(child_number, -1) = NVL(p_child_number, -1)
                     AND NVL(child_address, '-666') = NVL(p_child_address, '-666')
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

    /* -------------------------
     *
     * leading
     *
     * ------------------------- */
      DECLARE
        l_leading_data CLOB;
        l_buffer VARCHAR2(32767);
      BEGIN
        FOR i IN (SELECT DISTINCT id
                    FROM sqlt$_outline_data
                   WHERE statement_id = s_sql_rec.statement_id
                     AND source = p_rec.source
                     AND plan_hash_value = p_rec.plan_hash_value
                     AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
                     AND NVL(inst_id, -1) = NVL(p_inst_id, -1)
                     AND NVL(child_number, -1) = NVL(p_child_number, -1)
                     AND NVL(child_address, '-666') = NVL(p_child_address, '-666')
                     AND hint LIKE 'LEADING%'
                   ORDER BY
                         id)
        LOOP
          l_row_count := 0;

          FOR j IN (SELECT hint
                      FROM sqlt$_outline_data
                     WHERE statement_id = s_sql_rec.statement_id
                       AND source = p_rec.source
                       AND plan_hash_value = p_rec.plan_hash_value
                       AND id = i.id
                       AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
                       AND NVL(inst_id, -1) = NVL(p_inst_id, -1)
                       AND NVL(child_number, -1) = NVL(p_child_number, -1)
                       AND NVL(child_address, '-666') = NVL(p_child_address, '-666')
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

    /* -------------------------
     *
     * Go To
     *
     * ------------------------- */
    IF s_go_to = 'Y' THEN
      wa(go_to_sec('Tables', 'tab_sum'));
      wa(go_to_sec('Indexes', 'idx_sum'));
      wa(go_to_top);
      wa('<br>');
    END IF;

    /* -------------------------
     *
     * other_xml.info
     *
     * ------------------------- */
    BEGIN
      l_row_count := 0;
      FOR i IN (SELECT info_type,
                       info_value
                  FROM sqlt$_plan_info
                 WHERE statement_id = s_sql_rec.statement_id
                   AND source = p_rec.source
                   AND plan_hash_value = p_rec.plan_hash_value
                   AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
                   AND NVL(inst_id, -1) = NVL(p_inst_id, -1)
                   AND NVL(child_number, -1) = NVL(p_child_number, -1)
                   AND NVL(child_address, '-666') = NVL(p_child_address, '-666')
                 ORDER BY
                       id,
                       line_id)
      LOOP
        l_row_count := l_row_count + 1;
        IF l_row_count = 1 THEN
          wa(h4(mot('Plan Info', 'OTHER_XML')));
          wa('<table>');
        END IF;
        IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
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
        write_error('other_xml.info: '||SQLERRM);
    END;

    /* -------------------------
     *
     * peeked_binds
     *
     * ------------------------- */
    IF p_rec.source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN', 'DBA_SQLTUNE_PLANS') THEN
      BEGIN
        l_row_count := 0;
        FOR i IN (SELECT name,
                         type,
                         value
                    FROM sqlt$_peeked_binds_v
                   WHERE statement_id = s_sql_rec.statement_id
                     AND source = p_rec.source
                     AND plan_hash_value = p_rec.plan_hash_value
                     AND NVL(plan_id, -666) = NVL(p_rec.plan_id, -666)
                     AND NVL(inst_id, -1) = NVL(p_inst_id, -1)
                     AND NVL(child_number, -1) = NVL(p_child_number, -1)
                     AND NVL(child_address, '-666') = NVL(p_child_address, '-666')
                   ORDER BY
                         position,
                         name)
        LOOP
          l_row_count := l_row_count + 1;
          IF l_row_count = 1 THEN
            wa(h4(mot('Peeked Binds'||NBSP2||'timestamp:'||TO_CHAR(NVL(p_child_timestamp, p_rec.timestamp), LOAD_DATE_FORMAT), 'OTHER_XML')));
            wa('<table>');
          END IF;
          IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
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
      END;
    END IF;

    /* -------------------------
     *
     * captured_binds
     *
     * ------------------------- */
    IF p_rec.source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN') THEN
      BEGIN
        l_sql := '
SELECT last_captured,
       name,
       type,
       value
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_captured_binds_v
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND source = '''||p_rec.source||'''
   AND plan_hash_value = '||p_rec.plan_hash_value;
         IF p_inst_id IS NULL THEN
           l_sql := l_sql||'
   AND NVL(inst_id, -1) = -1';
         ELSE
           l_sql := l_sql||'
   AND NVL(inst_id, -1) = '||p_inst_id;
         END IF;
         IF p_child_number IS NULL THEN
           l_sql := l_sql||'
   AND NVL(child_number, -1) = -1';
         ELSE
           l_sql := l_sql||'
   AND NVL(child_number, -1) = '||p_child_number;
         END IF;
         IF p_child_address IS NULL THEN
           l_sql := l_sql||'
   AND NVL(child_address, ''-666'') = ''-666''';
         ELSE
           l_sql := l_sql||'
   AND NVL(child_address, ''-666'') = '''||p_child_number||'''';
         END IF;
         l_sql := l_sql||'
 ORDER BY last_captured DESC,
       position,
       name;';

        l_row_count := 0;
        FOR i IN (SELECT last_captured,
                         name,
                         type,
                         value
                    FROM sqlt$_captured_binds_v
                   WHERE statement_id = s_sql_rec.statement_id
                     AND source = p_rec.source
                     AND plan_hash_value = p_rec.plan_hash_value
                     AND NVL(inst_id, -1) = NVL(p_inst_id, -1)
                     AND NVL(child_number, -1) = NVL(p_child_number, -1)
                     AND NVL(child_address, '-666') = NVL(p_child_address, '-666')
                   ORDER BY last_captured DESC,
                         position,
                         name)
        LOOP
          l_row_count := l_row_count + 1;
          IF l_row_count = 1 THEN
            wa(h4(mot('Captured Binds', 'GV$SQL_BIND_CAPTURE')));
            wa('List of captured binds is restricted up to '||s_rows_table_m||' rows per Plan as per tool parameter "r_rows_table_m".');
            wa('<br>');
            wa(hide_sql(l_sql));
            wa('<table>');
          END IF;
          IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
            wa('<tr>');
            wa(th('#'));
            wa(th('Last Captured'));
            wa(th('Name'));
            wa(th('Type'));
            wa(th('Value'));
            wa('</tr>');
          END IF;

          wa('<tr>');
          wa(td(l_row_count, 'rt'));
          wa(td(TO_CHAR(i.last_captured, LOAD_DATE_FORMAT), 'c', 'nowrap'));
          wa(td(i.name, 'l'));
          wa(td(i.type, 'l'));
          wa(td(i.value, 'l'));
          wa('</tr>');

          IF l_row_count = s_rows_table_m THEN
            EXIT;
          END IF;
        END LOOP;
        IF l_row_count > 0 THEN
          wa('</table>');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('captured_binds: '||SQLERRM);
      END;
    END IF;

    /* -------------------------
     *
     * optimizer_environment
     *
     * ------------------------- */
    IF p_rec.source = 'GV$SQL_PLAN' THEN
      BEGIN
        l_row_count := 0;
        FOR i IN (SELECT name, value
                    FROM sqlt$_gv$sql_optimizer_env
                   WHERE statement_id = s_sql_rec.statement_id
                     AND inst_id = p_inst_id
                     AND child_number = p_child_number
                     AND child_address = p_child_address
                   ORDER BY
                         id)
        LOOP
          l_row_count := l_row_count + 1;
          IF l_row_count = 1 THEN
            wa(h4(mot('Optimizer Environment', 'GV$SQL_OPTIMIZER_ENV')));
            wa('<table>');
          END IF;
          IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
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
      END;
    END IF;

    /* -------------------------
     *
     * virtual_private_database
     *
     * ------------------------- */
    IF p_rec.source = 'GV$SQL_PLAN' THEN
      BEGIN
        l_row_count := 0;
        FOR i IN (SELECT object_owner,
                         object_name,
                         policy_group,
                         policy,
                         policy_function_owner,
                         predicate
                    FROM sqlt$_gv$vpd_policy
                   WHERE statement_id = s_sql_rec.statement_id
                     AND inst_id = p_inst_id
                     AND child_number = p_child_number
                   ORDER BY
                         object_owner,
                         object_name,
                         policy_group,
                         policy)
        LOOP
          l_row_count := l_row_count + 1;
          IF l_row_count = 1 THEN
            wa(h4(mot('Virtual Private Database', 'GV$VPD_POLICY')));
            wa('<table>');
          END IF;
          IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
            wa('<tr>');
            wa(th('#'));
            wa(th('Object<br>Owner'));
            wa(th('Object<br>Name'));
            wa(th('Policy<br>Group'));
            wa(th('Policy<br>Name'));
            wa(th('Policy<br>Function<br>Owner'));
            wa(th('Predicate'));
            wa('</tr>');
          END IF;

          wa('<tr>');
          wa(td(l_row_count, 'rt'));
          wa(td(i.object_owner, 'l'));
          wa(td(i.object_name, 'l'));
          wa(td(i.policy_group, 'l'));
          wa(td(i.policy, 'l'));
          wa(td(i.policy_function_owner, 'l'));
          wa(td(i.predicate, 'l'));
          wa('</tr>');
        END LOOP;
        IF l_row_count > 0 THEN
          wa('</table>');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('virtual_private_database: '||SQLERRM);
      END;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('plan_exec_sec_'||p_rec.link_id||'_'||p_inst_id||'_'||p_child_number||'_'||p_child_number||': '||SQLERRM);
  END plan_exec_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private plan_exec_sec
   *
   * ------------------------- */
  PROCEDURE plan_exec_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('plan_exec_sec');
    wa(h2(mot('Execution Plans', 'GV$SQL_PLAN, DBA_HIST_SQL_PLAN, PLAN_TABLE and DBA_SQLTUNE_PLANS'), 'pln_exe'));

    wa('List ordered by phv and source.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT plan_hash_value,
                     sqlt_plan_hash_value,
                     sqlt_plan_hash_value2,
                     link_id,
                     src,
                     source,
                     is_bind_sensitive,
                     optimizer,
                     cost,
                     cardinality,
                     rows_processed,
                     timestamp,
                     inst_id,
                     child_address,
                     child_number,
                     child_plans,
                     --plan_control,
                     CASE WHEN plan_id = -1 THEN NULL ELSE plan_id END plan_id,
                     CASE WHEN task_id = -1 THEN NULL ELSE task_id END task_id,
                     attribute
                FROM sqlt$_plan_header_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     plan_hash_value,
                     src_order)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Plan Hash Value'));
        wa(th('SQLT<br>Plan<br>Hash<br>Value<sup>1</sup>'));
        wa(th('SQLT<br>Plan<br>Hash<br>Value2<sup>1</sup>'));
        wa(th('Src'));
        wa(th('Source'));
        wa(th('Plan Info'));
        wa(th('Plan Stability'));
        wa(th('Is<br>Bind<br>Sensitive'));
        wa(th('Optimizer'));
        wa(th('Optimizer<br>Cost'));
        wa(th('Estimated<br>Cardinality<br>E-Rows'));
        wa(th('Rows<br>Processed<br>A-Rows'));
        wa(th('Plan Timestamp'));
        wa(th('Child<br>Plans<sup>2</sup>'));
        --wa(th('Plan Control'));
        wa(th('Plan ID'));
        wa(th('Task ID'));
        wa(th(mot('Attribute', 'DBA_SQLTUNE_PLANS')));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      IF i.link_id IS NULL THEN
        wa(td(i.plan_hash_value, 'l', 'nowrap')); -- inst_id and child_number left out intentionally
      ELSE
        wa(td(a_phv(i.plan_hash_value, 'plan_'||i.link_id), 'l', 'nowrap')); -- inst_id and child_number left out intentionally
      END IF;
      wa(td(i.sqlt_plan_hash_value, 'l'));
      wa(td(i.sqlt_plan_hash_value2, 'l'));
      wa(td(i.src));
      wa(td(i.source, 'l'));
      wa(td(plan_info(s_sql_rec.statement_id, i.plan_hash_value, i.source, NULL, i.plan_id, i.inst_id, i.child_number, i.child_address)));
      IF i.src = 'MEM' THEN
        wa(td(plan_stability(s_sql_rec.statement_id, i.plan_hash_value, i.inst_id)));
      ELSE
        wa(td(' '));
      END IF;
      wa(td(i.is_bind_sensitive));
      wa(td(i.optimizer, 'l', 'nowrap'));
      wa(td(i.cost, 'r'));
      wa(td(i.cardinality, 'r'));
      wa(td(i.rows_processed, 'r'));
      --wa(td(plan_info(s_sql_rec.statement_id, i.plan_hash_value, i.source, i.timestamp, i.plan_id, i.inst_id, i.child_number, i.child_address)));
      wa(td(TO_CHAR(i.timestamp, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.child_plans));
      --wa(td(i.plan_control, 'l'));
      wa(td(i.plan_id));
      wa(td(i.task_id));
      wa(td(i.attribute, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) SQLT PHV considers id, parent_id, operation, options, index_columns and object_name. SQLT PHV2 includes also access and filter predicates.'));
    wa('<br>');
    wa(font('(2) Display of child plans is restricted up to '||s_rows_table_s||' per phv as per tool parameter "r_rows_table_s".'));
    wa('<br>');
    wa(go_to_sec('Plan Performance Statistics', 'pln_sta'));
    wa(go_to_sec('Plans Summary', 'pln_sum'));
    wa(go_to_top);

    FOR i IN (SELECT *
                FROM sqlt$_plan_header_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     plan_hash_value,
                     src_order)
    LOOP
      IF i.source = 'GV$SQL_PLAN' THEN
        l_row_count := 0;
        FOR j IN (SELECT p.inst_id,
                         p.child_number,
                         p.child_address,
                         p.timestamp, -- all plan lines have same timestamp
                         NVL(s.executions, 0) executions
                    FROM sqlt$_gv$sql_plan p,
                         sqlt$_gv$sql s
                   WHERE p.statement_id = s_sql_rec.statement_id
                     AND p.plan_hash_value = i.plan_hash_value
                     AND p.id = 1
                     AND p.statement_id = s.statement_id(+)
                     AND p.plan_hash_value = s.plan_hash_value(+)
                     AND p.inst_id = s.inst_id(+)
                     AND p.child_number = s.child_number(+)
                   GROUP BY
                         p.inst_id,
                         p.child_number,
                         p.child_address,
                         p.timestamp, -- all plan lines have same timestamp
                         NVL(s.executions, 0)
                   ORDER BY
                         p.inst_id,
                         p.child_number DESC,
                         p.child_address,
                         p.timestamp, -- all plan lines have same timestamp
                         NVL(s.executions, 0))
        LOOP
          l_row_count := l_row_count + 1;
          plan_exec_sec(i, j.inst_id, j.child_number, j.child_address, j.timestamp, j.executions, l_row_count);
          IF l_row_count = s_rows_table_s THEN
            EXIT;
          END IF;
        END LOOP;
      ELSE
        plan_exec_sec(i);
      END IF;

      wa(go_to_sec('Execution Plans', 'pln_exe'));
      wa(go_to_sec('Plan Performance Statistics', 'pln_sta'));
      wa(go_to_sec('Plans Summary', 'pln_sum'));
      wa(go_to_sec('Tables', 'tab_sum'));
      wa(go_to_sec('Indexes', 'idx_sum'));
      wa(go_to_top);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('plan_exec_sec: '||SQLERRM);
  END plan_exec_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private outlines_sec
   *
   * ------------------------- */
  PROCEDURE outlines_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('outlines_sec');
    wa(h2(mot('Stored Outlines', 'DBA_OUTLINES and DBA_OUTLINE_HINTS'), 'outlines'));

    wa(h4(mot('Outlines', 'DBA_OUTLINES')));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_outlines
               WHERE statement_id = s_sql_rec.statement_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Owner'));
        wa(th('Category'));
        wa(th('Used'));
        wa(th('Timestamp'));
        wa(th('Version'));
        wa(th('Signature'));
        wa(th('Compatible'));
        wa(th('Enabled'));
        wa(th('Format'));
        wa(th('Migrated'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.category, 'l'));
      wa(td(i.used));
      wa(td(TO_CHAR(i.timestamp, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.version));
      wa(td(i.signature, 'l'));
      wa(td(i.compatible));
      wa(td(i.enabled));
      wa(td(i.format));
      wa(td(i.migrated));
       wa('</tr>');
    END LOOP;
    wa('</table>');

    wa(h4(mot('Outline Hints', 'DBA_OUTLINE_HINTS')));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_outline_hints
               WHERE statement_id = s_sql_rec.statement_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Owner'));
        wa(th('Node'));
        wa(th('Stage'));
        wa(th('Join Pos'));
        wa(th('Hint'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.node));
      wa(td(i.stage));
      wa(td(i.join_pos));
      sanitize_and_append(i.hint, p_max_line_size => 500); -- was 120
      wa('</tr>');
    END LOOP;
    wa('</table>');

    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('outlines_sec: '||SQLERRM);
  END outlines_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private patches_sec
   *
   * ------------------------- */
  PROCEDURE patches_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('patches_sec');
    wa(h2(mot('SQL Patches', 'DBA_SQL_PATCHES'), 'patches'));

    wa(h4(mot('Patches', 'DBA_SQL_PATCHES')));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_sql_patches
               WHERE statement_id = s_sql_rec.statement_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Category'));
        wa(th('Signature'));
        wa(th('Created'));
        wa(th('Last Modified'));
        wa(th('Description'));
        wa(th('Status'));
        wa(th('Force Matching'));
        wa(th('Task ID'));
        wa(th('Task Exec Name'));
        wa(th('Task Obj ID'));
        wa(th('Task Fnd ID'));
        wa(th('Task Rec ID'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.category, 'l'));
      wa(td(i.signature, 'l'));
      wa(td(TO_CHAR(i.created, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_modified, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.description, 'l'));
      wa(td(i.status));
      wa(td(i.force_matching));
      wa(td(i.task_id));
      wa(td(i.task_exec_name, 'l'));
      wa(td(i.task_obj_id));
      wa(td(i.task_fnd_id));
      wa(td(i.task_rec_id));
       wa('</tr>');
    END LOOP;
    wa('</table>');

    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('patches_sec: '||SQLERRM);
  END patches_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private profiles_sec
   *
   * ------------------------- */
  PROCEDURE profiles_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('profiles_sec');
    wa(h2(mot('SQL Profiles', 'DBA_SQL_PROFILES'), 'profiles'));

    wa(h4(mot('Profiles', 'DBA_SQL_PROFILES')));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_sql_profiles
               WHERE statement_id = s_sql_rec.statement_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Name'));
        wa(th('Category'));
        wa(th('Signature'));
        wa(th('Created'));
        wa(th('Last Modified'));
        wa(th('Description'));
        wa(th('Type'));
        wa(th('Status'));
        wa(th('Force Matching'));
        wa(th('Task ID'));
        wa(th('Task Exec Name'));
        wa(th('Task Obj ID'));
        wa(th('Task Fnd ID'));
        wa(th('Task Rec ID'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.category, 'l'));
      wa(td(i.signature, 'l'));
      wa(td(TO_CHAR(i.created, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_modified, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.description, 'l'));
      wa(td(i.type));
      wa(td(i.status));
      wa(td(i.force_matching));
      wa(td(i.task_id));
      wa(td(i.task_exec_name, 'l'));
      wa(td(i.task_obj_id));
      wa(td(i.task_fnd_id));
      wa(td(i.task_rec_id));
       wa('</tr>');
    END LOOP;
    wa('</table>');

    wa(h4('Profile Hints'));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_sql_profile_hints_v
               WHERE statement_id = s_sql_rec.statement_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('ID'));
        wa(th('Name'));
        wa(th('Category<sup>1</sup>'));
        wa(th('Signature'));
        wa(th('Hint'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.id));
      wa(td(i.name, 'l'));
      wa(td(i.category, 'l'));
      wa(td(i.signature, 'l'));
      sanitize_and_append(i.hint, p_max_line_size => 500); -- was 120
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) A value of "SQL Tuning Advisor" means that a recommended SQL Profile has not been implemented. See STA Report for details.'));
    wa('<br>');

    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('profiles_sec: '||SQLERRM);
  END profiles_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private baselines_sec
   *
   * ------------------------- */
  PROCEDURE baselines_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('baselines_sec');
    wa(h2(mot('SQL Plan Baselines', 'DBA_SQL_PLAN_BASELINES'), 'baselines'));

    wa(h4(mot('Plan Baselines', 'DBA_SQL_PLAN_BASELINES')));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_sql_plan_baselines
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     signature,
                     sql_handle,
                     plan_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Signature'));
        wa(th('SQL Handle'));
        wa(th('Plan Name'));
        wa(th('Plan Hash Value'));
        wa(th('Creator'));
        wa(th('Origin'));
        wa(th('Parsing Schema Name'));
        wa(th('Description'));
        wa(th('Version'));
        wa(th('Created'));
        wa(th('Last Modified'));
        wa(th('Last Executed'));
        wa(th('Last Verified'));
        wa(th('Baseline'));
        wa(th('Reproduced'));
        wa(th('Enabled'));
        wa(th('Accepted'));
        wa(th('Fixed'));
        wa(th('Auto Purge'));
        wa(th('Optimizer Cost'));
        wa(th('Module'));
        wa(th('Action'));
        wa(th('Executions'));
        wa(th('Elapsed Time in seconds'));
        wa(th('CPU Time in seconds'));
        wa(th('Buffer Gets'));
        wa(th('Disk Reads'));
        wa(th('Direct Writes'));
        wa(th('Rows Processed'));
        wa(th('Fetched'));
        wa(th('End of Fetch count'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.signature, 'l'));
      wa(td(i.sql_handle, 'l'));
      wa(td(a(i.plan_name, REPLACE(REPLACE(i.sql_handle||i.plan_name, 'SYS_SQL_'), 'SQL_PLAN_')), 'l'));
      wa(td(i.plan_hash_value, 'r'));
      wa(td(i.creator, 'l'));
      wa(td(i.origin));
      wa(td(i.parsing_schema_name, 'l'));
      wa(td(i.description, 'l'));
      wa(td(i.version));
      wa(td(TO_CHAR(i.created, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_modified, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_executed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_verified, LOAD_DATE_FORMAT), 'c', 'nowrap'));

      IF NVL(i.reproduced, 'YES') = 'YES' AND i.enabled = 'YES' AND i.accepted = 'YES' THEN
        wa(td('YES'));
      ELSE
        wa(td(' '));
      END IF;

      IF i.reproduced = 'NO' THEN 
        wa(td(a(i.reproduced, 'observ')));
      ELSE
        wa(td(i.reproduced));
      END IF;

      wa(td(i.enabled));
      wa(td(i.accepted));
      wa(td(i.fixed));
      wa(td(i.autopurge));
      wa(td(i.optimizer_cost, 'r'));
      wa(td(i.module));
      wa(td(i.action));
      wa(td(i.executions, 'r'));
      wa(td(TO_CHAR(ROUND(i.elapsed_time / 1e6, 3), SECONDS_FORMAT), 'r'));
      wa(td(TO_CHAR(ROUND(i.cpu_time / 1e6, 3), SECONDS_FORMAT), 'r'));
      wa(td(i.buffer_gets, 'r'));
      wa(td(i.disk_reads, 'r'));
      wa(td(i.direct_writes, 'r'));
      wa(td(i.rows_processed, 'r'));
      wa(td(i.fetches, 'r'));
      wa(td(i.end_of_fetch_count, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');

    FOR i IN (SELECT DISTINCT
                     sql_handle,
                     plan_name
                FROM sqlt$_dbms_xplan
               WHERE statement_id = s_sql_rec.statement_id
                 AND api = 'B'
                 AND format = 'V'
                 AND sql_handle IS NOT NULL
                 AND plan_name IS NOT NULL
               ORDER BY
                     sql_handle,
                     plan_name)
    LOOP
      wa(h4(mot('Handle:'||i.sql_handle||NBSP2||'Plan:'||i.plan_name, 'DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE'), REPLACE(REPLACE(i.sql_handle||i.plan_name, 'SYS_SQL_'), 'SQL_PLAN_')));
      wa('<pre>');

      -- 12.1.09 dump ERROR before the details of the baseline
      FOR j IN (SELECT substr(plan_table_output, instr(plan_table_output,'ERROR:')) baseline_error
                  FROM sqlt$_dbms_xplan
                 WHERE statement_id = s_sql_rec.statement_id
                   AND api = 'B'
                   AND format = 'V'
                   AND sql_handle = i.sql_handle
                   AND plan_name = i.plan_name
                   AND instr(plan_table_output,'ERROR:') <> 0
                 ORDER BY
                       line_id)
      LOOP
        wa(j.baseline_error||LF);
      END LOOP;

      FOR j IN (SELECT plan_table_output
                  FROM sqlt$_dbms_xplan
                 WHERE statement_id = s_sql_rec.statement_id
                   AND api = 'B'
                   AND format = 'V'
                   AND sql_handle = i.sql_handle
                   AND plan_name = i.plan_name
                 ORDER BY
                       line_id)
      LOOP
        sanitize_and_append(j.plan_table_output||LF, FALSE, 300);
      END LOOP;
      wa('</pre>'||LF);
    END LOOP;

    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('baselines_sec: '||SQLERRM);
  END baselines_sec;

/*************************************************************************************/
  -- 150828 Cache functions to support directives display 
  function obtain_hash(p_key number) return number is
  begin
   RETURN dbms_utility.get_hash_value(to_char(p_key,'9999999999999999999999'),-134217728,134217728);
  end;
  
  FUNCTION has(p_key number,p_value varchar2) return boolean 
  IS
  v_key number:=obtain_hash(p_key);
  BEGIN
   IF v_cache.exists(v_key) THEN
    IF v_cache(v_key) like '%'||p_value||'%' THEN
	 RETURN TRUE;
	END IF;
   END IF;
   RETURN FALSE;
  END has;
  
  PROCEDURE add( p_key number,p_value varchar2) 
  IS
  v_key number:=obtain_hash(p_key);
  Begin
   IF v_cache.exists(v_key) THEN
    IF not(has(v_key,p_value)) THEN
     v_cache(v_key):=v_cache(v_key)||'"'||p_value||'"';
	END IF;
   ELSE
    v_cache(v_key):='"'||p_value||'"';
   END IF;
  END add;
  
  PROCEDURE purge_cache 
  IS 
  BEGIN
   v_cache.delete;
  END purge_cache;
  
  
   /* -------------------------
   *
   * private directives_m_sec
   * 150828 New
   * 151019 s_rows_table_m bug
   * 151020 add column list
   * ------------------------- */
  PROCEDURE directives_m_sec (
    p_reason     IN VARCHAR2 default 'GROUP',
    p_state      IN VARCHAR2 default 'USABLE') 
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767):=null;
	l_prev_dir number;
	l_rownum number;
	l_note varchar2(10);
	
     PROCEDURE print_header 
	 IS
	 BEGIN
	    wa('<tr>');
		wa('<th colspan=3 align=right><table align=right>');
		wa(th('Internal State / '||font('Redundant<sup>4</sup> / Auto Drop<sup>4</sup>','br')||' :','','align=right')); wa('<tr>');
		wa(th('Created:','','align=right'));        wa('<tr>');
		wa(th('Last Modified:','','align=right'));  wa('<tr>');
		wa(th('Last Used:','','align=right')); 
		wa('</table>');
        wa('</th>');
 
        for i in ( select dr.*,rownum r from (SELECT distinct directive_id ,AUTO_DROP,CREATED,LAST_MODIFIED,LAST_USED,INTERNAL_STATE,REDUNDANT
                     FROM SQLT$_DBA_SQL_PLAN_DIRECTIVES d 
	                WHERE d.statement_id = s_sql_rec.statement_id
	                  AND d.state = p_state
                      AND d.reason like p_reason||'%'
	                ORDER BY d.directive_id 
					) dr where  ROWNUM<=s_rows_table_m    -- Restrict output as safeguard
				 ) loop
		 wa('<th><table>');
		 wa(th(i.internal_state||(case when i.redundant='YES' then font('/REDUNDANT','br') end)||(case when i.auto_drop='NO' then font('/NoAutoDrop','br') end))); wa('<tr>');
		 wa(th(TO_CHAR(i.created, LOAD_DATE_FORMAT),'','nowrap'));                 wa('<tr>');
		 wa(th(nvl(TO_CHAR(i.last_modified, LOAD_DATE_FORMAT),'-'),'','nowrap'));  wa('<tr>');
		 wa(th(nvl(TO_CHAR(i.last_used, LOAD_DATE_FORMAT),'-'),'','nowrap')); 
		 wa('</table>');
         wa('</th>');				
		 
		 IF MOD(I.r,10)=9 THEN --151020	   
	      wa(th(NBSP));
	     END IF;
		end loop;

        wa('</tr>');
        wa('<tr>');
        wa(th('#'));
		wa(th('Object in this Report<sup>3</sup>'));
		wa(th('(Owner.Table.Column) Object Name<sup>2</sup> \ Directive ID<sup>1</sup>'));
--		wa(th('Note'));		
        FOR i in v_directive.first .. v_directive.last  LOOP
	     wa(th(v_directive(i)));
	     IF MOD(I,10)=9 THEN --151020	   
	      wa(th(NBSP));
	     END IF;		 
        END LOOP;
      wa('</tr>');
	 END print_header;

	 
  BEGIN
    write_log('directives_m_sec_'||p_reason||'_'||p_state, 'S');
	
	SELECT directive_id 
      BULK COLLECT INTO v_directive
	  FROM (
	SELECT distinct d.directive_id 

      FROM SQLT$_DBA_SQL_PLAN_DIRECTIVES d 
	 WHERE d.statement_id = s_sql_rec.statement_id
	   AND d.state = p_state
       AND d.reason like p_reason||'%'
	 ORDER BY d.directive_id
	 )WHERE ROWNUM<=s_rows_table_m;
	 
	IF NOT(v_directive.exists(1)) THEN 
	 write_log('no directives_m_sec_'||p_reason||'_'||p_state, 'S');
	 RETURN; 
    END IF;	
	
	purge_cache;
	FOR i IN (SELECT distinct o.directive_id
	                ,o.owner||'.'||o.object_name||nvl2(o.subobject_name,'.'||o.subobject_name,null) object_name
                FROM SQLT$_DBA_SQL_PLAN_DIRECTIVES d,
                     SQLT$_DBA_SQL_PLAN_DIR_OBJS o,
                     sqlt$_dba_all_table_cols_v tc          
               WHERE d.statement_id = s_sql_rec.statement_id
                 AND o.statement_id = s_sql_rec.statement_id
                 AND tc.statement_id(+) = s_sql_rec.statement_id
                 AND d.state = p_state
                 AND d.reason like p_reason||'%'
                 AND d.directive_id=o.directive_id				 
				 and tc.owner(+) = o.owner
				 AND tc.table_name(+)= o.object_name				 
                 AND tc.column_name(+) like nvl(o.subobject_name,'%')
				 ) Loop
	 add(i.directive_id, i.object_name);		 
    END LOOP;
   
   IF p_reason like 'GROUP%' THEN 
    wa(h4(mot('"'||p_state||'" Group By Cardinality Misestimate Directives', 'DBA_SQL_PLAN_DIRECTIVES and DBA_SQL_PLAN_DIR_OBJECTS')
    ,substr(p_state,1,1)||'GBYd'));
   ELSE
    wa(h4(mot('"'||p_state||'" Join Cardinality Misestimate Directives', 'DBA_SQL_PLAN_DIRECTIVES and DBA_SQL_PLAN_DIR_OBJECTS')
    ,substr(p_state,1,1)||'JOINd'));
   END IF;
   
   wa('Restricted up to '||s_rows_table_m||' Objects and Directives as per tool parameter "r_rows_table_m".');
   wa('<br>');
   
   --wa(hide_sql(l_sql));
   wa('<table>');
   l_row_count := 0;

   FOR i IN (SELECT * FROM (SELECT o.owner||'.'||o.object_name||nvl2(o.subobject_name,'.'||o.subobject_name,null) object_name,
                    min(equality_predicates_only)      no_eq  ,max(equality_predicates_only)      y_eq,
					min(simple_column_predicates_only) no_prd ,max(simple_column_predicates_only) y_prd,
					min(index_access_by_join_preds)    no_idx ,max(index_access_by_join_preds)    y_idx,
					min(filter_on_joining_object)      no_fj  ,max(filter_on_joining_object)      y_fj,
					min(nvl2(tc.column_name,'Yes','No')) do_not_exist
                FROM SQLT$_DBA_SQL_PLAN_DIRECTIVES d,
                     SQLT$_DBA_SQL_PLAN_DIR_OBJS o,
                     sqlt$_dba_all_table_cols_v tc         
               WHERE d.statement_id = s_sql_rec.statement_id
                 AND o.statement_id = s_sql_rec.statement_id
                 AND tc.statement_id(+) = s_sql_rec.statement_id
                 AND d.state = p_state
                 AND d.reason like p_reason||'%'
                 AND d.directive_id=o.directive_id				 
				 and tc.owner(+) = o.owner
				 AND tc.table_name(+)= o.object_name
                 AND tc.column_name(+) like nvl(o.subobject_name,'%')
				 GROUP BY o.owner||'.'||o.object_name||nvl2(o.subobject_name,'.'||o.subobject_name,null)
				 order by do_not_exist desc,object_name 
				 ) WHERE ROWNUM<=s_rows_table_m
				 ) Loop
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
	   print_header;
      END IF;
	  wa('<tr>');
	  wa(td(l_row_count,'rt'));
	  wa(td(i.do_not_exist));
	  wa(td(i.object_name,'l'));
--	  wa_td_hide(i.sanitized_note);
	  FOR j in v_directive.first .. v_directive.last LOOP
	   IF has(v_directive(j),i.object_name) then
	    l_note:=(case i.y_eq  when 'Y' then (case i.no_eq  when 'N' then 'e' else 'E' end) else '-' end)||
				(case i.y_prd when 'Y' then (case i.no_prd when 'N' then 'c' else 'C' end) else '-' end)||
				(case i.y_idx when 'Y' then (case i.no_idx when 'N' then 'j' else 'J' end) else '-' end)||
				(case i.y_fj  when 'Y' then (case i.no_fj  when 'N' then 'f' else 'F' end) else '-' end);
	    wa(td(l_note));
	   ELSE
	    wa(td(NBSP));
	   end if;
    
	   IF MOD(J,10)=9 THEN --151020	   
	    wa(td(i.object_name,'l'));
	   END IF;
      END LOOP;
      wa('</tr>');
   END LOOP;
   wa('</table>');
   wa(font('(1) "NOTES" Directive Flags under each directive is in positional order : '));
   wa('<br>');
   wa(font(' Letter means YES on (E)-equality_predicates_only  (C)-simple_column_predicates_only  (J)-index_access_by_join_predicates  (F)-filter_on_joining_object , a dash "-" means NO,','br'));
   wa('<br>');
   wa(font('Lower case flag indicates the directive lists multiple times the same object with both YES and NO.','b'));
   wa('<br>');
   wa(font('(2) Objects are listed in alphabetical order only one time even if directive lists it multiple times.'));     
   wa('<br>');
   wa(font('(3) Directives may include objects that are not collected by SQLT because they are not present in the SQL Statement but are listed here for completeness.'));        
   wa('<br>');   
   wa(font('(4) Redundant is displayed only if YES and AutoDrop is displayed only if NO.'));        
   
  EXCEPTION
    WHEN OTHERS THEN
      write_error('directives_m_sec_'||p_reason||'_'||p_state||': '||SQLERRM);
  END directives_m_sec;

/*************************************************************************************/

  /* -------------------------
   *
   * private directives_s_sec
   * 150828 New
   * ------------------------- */
  PROCEDURE directives_s_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER,
    p_state      IN VARCHAR2 default 'USABLE')
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767):=null;
	l_prev_dir number;
	l_rownum number;
  BEGIN
    write_log('directives_s_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - "'||p_state||'" Single Table Cardinality Misestimate Directives', 'DBA_SQL_PLAN_DIRECTIVES and DBA_SQL_PLAN_DIR_OBJECTS')
	,substr(p_state,1,1)||'stcmd'||p_object_id));

    if p_state='USABLE' then
     wa('List of <b>"USABLE"</b> SQL Plan Directives');
     wa('<br>');
    else
     wa('Restricted list of <b>"'||p_state||'"</b> SQL Plan Directives.');
     wa('<br>');
     wa('Further restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
     wa('<br>');
    end if;
    wa('The columns are listed in Alphabetical Order.');
    wa('<br>');
--    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
	l_prev_dir:=0;
	l_rownum:=0;
    FOR i IN (SELECT d.directive_id
                    ,d.auto_drop
                    ,d.created
                    ,d.last_modified
                    ,d.last_used
					,d.internal_state
                    ,d.redundant					
                    ,o.subobject_name column_name
                    ,tc.in_predicates 
                    ,tc.column_id
					,ht.html_table
                FROM SQLT$_DBA_SQL_PLAN_DIRECTIVES d,
                     SQLT$_DBA_SQL_PLAN_DIR_OBJS o,
                     sqlt$_dba_all_table_cols_v tc,          
                     sqlg$_column_html_table ht
               WHERE d.statement_id = s_sql_rec.statement_id
                 AND o.statement_id = s_sql_rec.statement_id
                 AND tc.statement_id = s_sql_rec.statement_id
                 AND o.owner = p_owner
                 AND tc.owner = p_owner				 
                 AND o.object_name = p_table_name	
				 AND tc.table_name = p_table_name
                 AND d.state = p_state
                 AND d.reason like 'SINGLE%'
                 AND o.object_type='COLUMN'
                 AND d.directive_id=o.directive_id				 
                 AND tc.column_name=o.subobject_name
                 AND tc.column_name = ht.column_name(+)
                 AND 'P' = ht.type(+)
                 ORDER BY d.directive_id,o.subobject_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Directive ID'));
        wa(th('Created'));
        wa(th('Last Modified'));
        wa(th('Last Used'));
		wa(th('Internal State'));
		wa(th('Redundant'));
        wa(th('Auto Drop'));
        wa(th('Col ID'));
        wa(th('Column Name'));		
        wa(th(moa('In Pred', 3)));		
        wa('</tr>');
      END IF;

      wa('<tr>');
	  if l_prev_dir<>i.directive_id then
	   l_rownum:=l_rownum+1;
	   l_prev_dir:=i.directive_id;
       wa(td(l_rownum, 'rt'));
       wa(td(i.directive_id, 'r'));
       wa(td(TO_CHAR(i.created, LOAD_DATE_FORMAT), 'c', 'nowrap'));
       wa(td(TO_CHAR(i.last_modified, LOAD_DATE_FORMAT), 'c', 'nowrap'));
       wa(td(TO_CHAR(i.last_used, LOAD_DATE_FORMAT), 'c', 'nowrap'));     
	   wa(td(i.internal_state, 'c'));
	   wa(td(i.redundant, 'c'));
       wa(td(i.auto_drop, 'c'));
	  else
	   wa(td(NBSP,'vt','colspan=8'));
	  end if;
      wa(td(i.column_id));
      wa(td(i.column_name, 'l'));
      IF i.in_predicates = 'TRUE' AND i.html_table IS NOT NULL AND s_in_pred = 'Y' THEN
        wa_td_hide(i.html_table);
      ELSE
        wa(td(i.in_predicates));
      END IF;	  
      wa('</tr>');

      IF p_state<>'USABLE' and l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');

  EXCEPTION
    WHEN OTHERS THEN
      write_error('directives_s_sec_'||p_object_id||': '||SQLERRM);
  END directives_s_sec;
  
/*************************************************************************************/

  /* -------------------------
   *
   * private directives_sec
   * 150828 obsolete
   * ------------------------- */
  PROCEDURE directives_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('directives_sec');
    wa(h2(mot('SQL Plan Directives', 'DBA_SQL_PLAN_DIRECTIVES'), 'directives'));

    wa(h4(mot('Directives', 'DBA_SQL_PLAN_DIRECTIVES')));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_sql_plan_directives
               WHERE statement_id = s_sql_rec.statement_id)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Directive ID'));
        wa(th('Type'));
        wa(th('State'));
        wa(th('Auto Drop'));
        wa(th('Reason'));
        wa(th('Created'));
        wa(th('Last Modified'));
        wa(th('Last Used'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.directive_id, 'l'));
      wa(td(i.type, 'l'));
      wa(td(i.state, 'l'));
      wa(td(i.auto_drop, 'c'));
      wa(td(i.reason, 'l'));
      wa(td(TO_CHAR(i.created, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_modified, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_used, LOAD_DATE_FORMAT), 'c', 'nowrap'));
       wa('</tr>');
    END LOOP;
    wa('</table>');

    wa(h4('Directives Objects'));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_sql_plan_dir_objs
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY owner, object_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Directive ID'));
        wa(th('Owner'));
        wa(th('Object Name'));
        wa(th('Subobject Name'));
        wa(th('Object Type'));
        wa(th('Notes'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.directive_id,'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.object_name, 'l'));
      wa(td(i.subobject_name, 'l'));
      wa(td(i.object_type, 'l'));
/*      IF i.sanitized_notes IS NOT NULL THEN  -- 150828 obsolete column
        wa_td_hide(i.sanitized_notes);
      ELSE
        wa(td(i.sanitized_notes, 'l'));
      END IF;
*/	  
      --sanitize_and_append(i.notes, p_max_line_size => 500); -- was 120
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa('<br>');

    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('directives_sec: '||SQLERRM);
  END directives_sec;


  /*************************************************************************************/

  /* -------------------------
   *
   * private dependencies_sec
   *
   * ------------------------- */
  PROCEDURE dependencies_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('dependencies_sec');
    wa(h2(mot('Object Dependency', 'GV$OBJECT_DEPENDENCY and DBA_DEPENDENCIES'), 'obj_depend'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT v.*,
                     sqlt$a.get_met_object_id(v.statement_id, v.type, v.owner, v.name) object_id
                FROM sqlt$_dependencies_v v
               WHERE v.statement_id = s_sql_rec.statement_id
               ORDER BY
                     v.type,
                     v.name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Source'));  --12.1.08
        wa(th('Object Type'));
        wa(th('Object Name'));
        wa(th('Object Owner'));
        wa(th('To Object Type'));  --12.1.08
        wa(th('To Object Name'));  --12.1.08
        wa(th('To Object Owner'));  --12.1.08
        wa(th('Metadata'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.source, 'l'));  --12.1.08
      wa(td(i.type, 'l'));
      wa(td(i.name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.to_type, 'l')); --12.1.08
      wa(td(i.to_name, 'l'));  --12.1.08
      wa(td(i.to_owner, 'l'));  --12.1.08
      IF i.object_id IS NULL OR s_metadata = 'N' THEN
        wa(td(NBSP));
      ELSE
        wa(td(a('Metadata', 'meta_'||i.object_id)));
      END IF;
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('dependencies_sec: '||SQLERRM);
  END dependencies_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private objects_sec
   *
   * ------------------------- */
  PROCEDURE objects_sec
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('objects_sec');
    wa(h2(mot('Objects', 'DBA_OBJECTS'), 'objects'));

    l_sql := '
SELECT o.object_type,
       o.object_name,
       o.owner,
       o.object_id,
       o.data_object_id,
       o.created,
       o.last_ddl_time,
       o.timestamp,
       o.status,
       o.temporary,
       o.generated,
       o.secondary,
       o.namespace,
       o.edition_name,
       o.metadata_error
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_objects o
 WHERE o.statement_id = '||s_sql_rec.statement_id||'
   AND o.object_type NOT LIKE ''%PARTITION''
 ORDER BY
       o.object_type,
       o.object_name,
       o.subobject_name;';

    wa('Restricted list of objects related to the SQL being analyzed. Partitions and Subpartitions are excluded.');
    wa('<br>');
    wa('Further restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT o.object_type,
                     o.object_name,
                     o.owner,
                     o.object_id,
                     o.data_object_id,
                     o.created,
                     o.last_ddl_time,
                     o.timestamp,
                     o.status,
                     o.temporary,
                     o.generated,
                     o.secondary,
                     o.namespace,
                     o.edition_name,
                     sqlt$a.get_met_object_id(o.statement_id, o.object_type, o.owner, o.object_name) met_object_id,
                     o.metadata_error
                FROM sqlt$_dba_objects o
               WHERE o.statement_id = s_sql_rec.statement_id
                 AND o.object_type NOT LIKE '%PARTITION'
               ORDER BY
                     o.object_type,
                     o.object_name,
                     o.subobject_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Object Type'));
        wa(th('Object Name'));
        wa(th('Object Owner'));
        wa(th('Object ID'));
        wa(th('Data Object ID'));
        wa(th('Created'));
        wa(th('Last DDL Time'));
        wa(th('Timestamp'));
        wa(th('Status'));
        wa(th(mot('T', 'Temporary')));
        wa(th(mot('G', 'Generated')));
        wa(th(mot('S', 'Secondary')));
        wa(th('Name Space'));
        wa(th('Edition Name'));
        wa(th('Metadata'));
        wa(th('Metadata Error'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.object_type, 'l'));
      wa(td(i.object_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.object_id));
      wa(td(i.data_object_id));
      wa(td(TO_CHAR(i.created, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_ddl_time, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.timestamp, 'c', 'nowrap'));
      wa(td(i.status, 'l'));
      wa(td(i.temporary));
      wa(td(i.generated));
      wa(td(i.secondary));
      wa(td(i.namespace));
      wa(td(i.edition_name, 'l'));
      IF i.met_object_id IS NULL OR s_metadata = 'N' THEN
        wa(td(NBSP));
      ELSE
        wa(td(a('Metadata', 'meta_'||i.met_object_id)));
      END IF;
      wa(td(i.metadata_error, 'l'));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('objects_sec: '||SQLERRM);
  END objects_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private fixed_obj_sec
   *
   * ------------------------- */
  PROCEDURE fixed_obj_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('fixed_obj_sec');
    wa(h2(mot('Fixed Objects', 'DBA_TAB_STATISTICS'), 'fixed_objects'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT s.*,
                     CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), PERCENT_FORMAT) END percent
                FROM sqlt$_dba_tab_statistics s
               WHERE s.statement_id = s_sql_rec.statement_id
                 AND s.object_type = 'FIXED TABLE'
               ORDER BY
                     s.table_name,
                     s.owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Num Rows<sup>1</sup>'));
        wa(th('Sample Size<sup>1</sup>'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Last Analyzed<sup>1</sup>'));
        wa(th('Blocks<sup>1</sup>'));
        wa(th('Empty Blocks'));
        wa(th('Avg Space'));
        wa(th('Avg Row Len<sup>1</sup>'));
        wa(th('Chain Cnt'));
        wa(th('Global Stats<sup>1</sup>'));
        wa(th('User Stats<sup>1</sup>'));
        wa(th('Stat Type Locked'));
        wa(th('Stale Stats'));
        wa(th('Avg Space Freelist Blocks'));
        wa(th('Num Freelist Blocks'));
        wa(th('Avg Cached Blocks'));
        wa(th('Avg Cache Hit Ratio'));
        wa(th('Cols'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.blocks, 'r'));
      wa(td(i.empty_blocks, 'r'));
      wa(td(i.avg_space, 'r'));
      wa(td(i.avg_row_len, 'r'));
      wa(td(i.chain_cnt, 'r'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa(td(i.stattype_locked));
      wa(td(i.stale_stats));
      wa(td(i.avg_space_freelist_blocks, 'r'));
      wa(td(i.num_freelist_blocks, 'r'));
      wa(td(i.avg_cached_blocks, 'r'));
      wa(td(i.avg_cache_hit_ratio, 'r'));
      wa(td(a('Cols', 'fixed_obj_cols_'||i.table_name)));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) CBO Statistics.'));
    wa('<br>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('fixed_obj_sec: '||SQLERRM);
  END fixed_obj_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private fixed_obj_cols_sec
   *
   * ------------------------- */
  PROCEDURE fixed_obj_cols_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2 )
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('fixed_obj_cols_sec_'||p_table_name);
    wa(h4(mot(p_owner||'.'||p_table_name||' - Fixed Object Columns', 'DBA_TAB_COLS'), 'fixed_obj_cols_'||p_table_name));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_tab_col_statistics
               WHERE statement_id = s_sql_rec.statement_id
                 AND table_name = p_table_name
                 AND owner = p_owner
               ORDER BY
                     column_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Column Name'));
        wa(th('Num Nulls'));
        wa(th('Sample Size'));
        wa(th('Num Distinct'));
        wa(th('Low Value'));
        wa(th('High Value'));
        wa(th('Last Analyzed'));
        wa(th('Avg Col Len'));
        wa(th('Density'));
        wa(th('Num Buckets'));
        wa(th('Histogram'));
        wa(th('Global Stats'));
        wa(th('User Stats'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.column_name, 'l'));
      wa(td(i.num_nulls, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.num_distinct, 'r'));
      wa(td(i.low_value, 'l'));
      wa(td(i.high_value, 'l'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.avg_col_len, 'r'));
      wa(td(LOWER(TO_CHAR(i.density, SCIENTIFIC_NOTATION)), 'r', 'nowrap'));
      wa(td(i.num_buckets, 'r'));
      wa(td(i.histogram, 'l'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Fixed Objects', 'fixed_objects'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('fixed_obj_cols_sec_'||p_table_name||': '||SQLERRM);
  END fixed_obj_cols_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private fixed_obj_cols_sec
   *
   * ------------------------- */
  PROCEDURE fixed_obj_cols_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('fixed_obj_cols_sec');
    wa(h2(mot('Fixed Object Columns', 'DBA_TAB_COLS'), 'fixed_obj_cols'));

    wa('<ul>');
    FOR i IN (SELECT *
                FROM sqlt$_dba_tab_statistics
               WHERE statement_id = s_sql_rec.statement_id
                 AND object_type = 'FIXED TABLE'
                 AND owner = 'SYS'
               ORDER BY
                     table_name)
    LOOP
      wa(li(a(i.table_name, 'fixed_obj_cols_'||i.table_name)));
    END LOOP;
    wa('</ul>');
    wa(go_to_top);

    FOR i IN (SELECT *
                FROM sqlt$_dba_tab_statistics
               WHERE statement_id = s_sql_rec.statement_id
                 AND object_type = 'FIXED TABLE'
                 AND owner = 'SYS'
               ORDER BY
                     table_name)
    LOOP
      fixed_obj_cols_sec(i.table_name, i.owner);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('fixed_obj_cols_sec: '||SQLERRM);
  END fixed_obj_cols_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private nested_tables_sec
   *
   * ------------------------- */
  PROCEDURE nested_tables_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('nested_tables_sec');
    wa(h2(mot('Nested Tables', 'DBA_NESTED_TABLES'), 'nested_tables'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_nested_tables
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     table_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Table Type Owner'));
        wa(th('Table Type Name'));
        wa(th('Parent Table Name'));
        wa(th('Parent Table Column'));
        wa(th('Storage Spect'));
        wa(th('Return Type'));
        wa(th('Element Substitutable'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.table_type_owner, 'l'));
      wa(td(i.table_type_name, 'l'));
      wa(td(i.parent_table_name, 'l'));
      wa(td(i.parent_table_column, 'l'));
      wa(td(i.storage_spec, 'l'));
      wa(td(i.return_type, 'l'));
      wa(td(i.element_substitutable));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('nested_tables_sec: '||SQLERRM);
  END nested_tables_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private policies_sec
   *
   * ------------------------- */
  PROCEDURE policies_sec
  IS
    l_row_count NUMBER;
    l_columns VARCHAR2(4000);
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('policies_sec');
    wa(h2(mot('Policies', 'DBA_POLICIES'), 'policies'));

    l_sql := '
SELECT p.object_owner,
       p.object_name,
       p.policy_group,
       p.policy_name,
       p.pf_owner,
       p.package,
       p.function,
       p.sel,
       p.ins,
       p.upd,
       p.del,
       p.idx,
       p.chk_option,
       p.enable,
       p.static_policy,
       p.policy_type,
       p.long_predicate,
       p.relavant_cols_opt
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_policies p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_objects o,
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.statement_id = o.statement_id(+)
   AND p.pf_owner = o.owner(+)
   AND NVL(p.package,p.function) = o.object_name(+)
   AND CASE WHEN p.package IS NOT NULL THEN ''PACKAGE BODY'' ELSE ''FUNCTION'' END = o.object_type(+)
 ORDER BY
       object_owner,
       object_name,
       policy_group,
       policy_name;';

    wa('Restricted list of policies on Tables, Views or Synonyms related to the SQL being analyzed.');
    wa('<br>');
    wa('Further restricted up to '||s_rows_table_s||' rows as per tool parameter "r_rows_table_s".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT DISTINCT p.object_owner,
                     p.object_name,
                     p.policy_group,
                     p.policy_name,
                     p.pf_owner,
                     p.package,
                     p.function,
                     p.sel,
                     p.ins,
                     p.upd,
                     p.del,
                     p.idx,
                     p.chk_option,
                     p.enable,
                     p.static_policy,
                     p.policy_type,
                     p.long_predicate,
                     p.relevant_cols_opt,
                     o.object_id
                FROM sqlt$_dba_policies p,
                     sqlt$_dba_objects o
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.statement_id = o.statement_id(+)
                 AND p.pf_owner = o.owner(+)
                 AND NVL(p.package,p.function) = o.object_name(+)
                 AND CASE WHEN p.package IS NOT NULL THEN 'PACKAGE BODY' ELSE 'FUNCTION' END = o.object_type(+)
               ORDER BY
                     p.object_owner,
                     p.object_name,
                     p.policy_group,
                     p.policy_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Object Owner'));
        wa(th('Object Name'));
        wa(th('Policy Group'));
        wa(th('Policy Name'));
        wa(th('Policy Function Owner'));
        wa(th('Package'));
        wa(th('Function'));
        wa(th('SEL'));
        wa(th('INS'));
        wa(th('UPD'));
        wa(th('DEL'));
        wa(th('IDX'));
        wa(th('CHK Option'));
        wa(th('Enable'));
        wa(th('Static Policy'));
        wa(th('Policy Type'));
        wa(th('Long Predicate'));
        wa(th('Relevant Columns'));
        wa(th('Relevant Columns Opt'));
        wa('</tr>');
      END IF;
      
      l_columns := sqlt$a.get_policy_column_names(s_sql_rec.statement_id, i.object_owner, i.object_name, i.policy_name, '<br>');

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.object_owner, 'l'));
      wa(td(i.object_name, 'l'));
      wa(td(i.policy_group, 'l'));
      wa(td(i.policy_name, 'l'));
      wa(td(i.pf_owner, 'l'));
      wa(td(a(i.package, 'meta_'||i.object_id), 'l'));
      wa(td(a(i.function, 'meta_'||i.object_id), 'l'));
      wa(td(i.sel));
      wa(td(i.ins));
      wa(td(i.upd));
      wa(td(i.del));
      wa(td(i.idx));
      wa(td(i.chk_option));
      wa(td(i.enable));
      wa(td(i.static_policy));
      wa(td(i.policy_type, 'l'));
      wa(td(i.long_predicate));
      wa(td(l_columns));
      wa(td(i.relevant_cols_opt));
      wa('</tr>');

      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('policies_sec: '||SQLERRM);
  END policies_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private audit_policies_sec
   *
   * ------------------------- */
  PROCEDURE audit_policies_sec
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('audit_policies_sec');
    wa(h2(mot('Audit Policies', 'DBA_AUDIT_POLICIES'), 'audit_policies'));

    l_sql := '
SELECT object_schema,
       object_name,
       policy_owner,
       policy_name,
       policy_text,
       policy_column,
       pf_schema,
       pf_package,
       pf_function,
       enabled,
       sel,
       ins,
       upd,
       del,
       audit_trail,
       policy_column_options
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_audit_policies
 WHERE statement_id = '||s_sql_rec.statement_id||'
 ORDER BY
       object_schema,
       object_name,
       policy_owner,
       policy_name;';

    wa('Restricted list of audit policies on Tables or Views related to the SQL being analyzed.');
    wa('<br>');
    wa('Further restricted up to '||s_rows_table_s||' rows as per tool parameter "r_rows_table_s".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;

    FOR i IN (SELECT object_schema,
                     object_name,
                     policy_owner,
                     policy_name,
                     policy_text,
                     policy_column,
                     pf_schema,
                     pf_package,
                     pf_function,
                     enabled,
                     sel,
                     ins,
                     upd,
                     del,
                     audit_trail,
                     policy_column_options
                FROM sqlt$_dba_audit_policies
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     object_schema,
                     object_name,
                     policy_owner,
                     policy_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Object Schema'));
        wa(th('Object Name'));
        wa(th('Policy Owner'));
        wa(th('Policy Name'));
        wa(th('Policy Text'));
        wa(th('Policy Column'));
        wa(th('Policy Function Owner'));
        wa(th('Package'));
        wa(th('Function'));
        wa(th('Enabled'));
        wa(th('SEL'));
        wa(th('INS'));
        wa(th('UPD'));
        wa(th('DEL'));
        wa(th('Audit Trail'));
        wa(th('Policy Column Options'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.object_schema, 'l'));
      wa(td(i.object_name, 'l'));
      wa(td(i.policy_owner, 'l'));
      wa(td(i.policy_name, 'l'));
      wa(td(i.policy_text, 'l'));
      wa(td(i.policy_column, 'l'));
      wa(td(i.pf_schema, 'l'));
      wa(td(i.pf_package, 'l'));
      wa(td(i.pf_function, 'l'));
      wa(td(i.enabled));
      wa(td(i.sel));
      wa(td(i.ins));
      wa(td(i.upd));
      wa(td(i.del));
      wa(td(i.audit_trail, 'l'));
      wa(td(i.policy_column_options, 'l'));
      wa('</tr>');

      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('audit_policies_sec: '||SQLERRM);
  END audit_policies_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_stats_sec
   *
   * ------------------------- */
  PROCEDURE tab_stats_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tab_stats_sec');
    wa(h2(mot('Table Statistics', 'DBA_TAB_STATISTICS and DBA_SEGMENTS'), 'tab_stats'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT s.*,
                     CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), PERCENT_FORMAT) END percent,
                     x.partitioned,
                     x.temporary,
                     x.count_star,
                     x.object_id,
                     x.full_table_scan_cost,
                     x.total_segment_blocks,
                     x.dbms_space_alloc_blocks,
                     g.blocks segment_blocks,
                     g.extents
                FROM sqlt$_dba_tab_statistics s,
                     sqlt$_dba_all_tables_v x,
                     sqlt$_dba_segments g
               WHERE s.statement_id = s_sql_rec.statement_id
                 AND s.object_type = 'TABLE'
                 AND s.statement_id = x.statement_id
                 AND s.owner = x.owner
                 AND s.table_name = x.table_name
                 AND s.statement_id = g.statement_id(+)
                 AND s.owner = g.owner(+)
                 AND s.table_name = g.segment_name(+)
                 AND 'TABLE' = g.segment_type(+)
               ORDER BY
                     s.table_name,
                     s.owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th(mot('Part', 'Partitioned')));
        wa(th(mot('Temp', 'Temporary')));
        wa(th('Count<sup>1</sup>'));
        wa(th('Num Rows<sup>2</sup>'));
        wa(th('Sample Size<sup>2</sup>'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Last Analyzed<sup>2</sup>'));
        wa(th('Segment Extents'));
        wa(th('Segment Blocks'));
        wa(th('Total Segment Blocks<sup>3</sup>'));
        wa(th('DBMS_SPACE Allocated Blocks<sup>4</sup>'));
        wa(th('Blocks<sup>2</sup>'));
        wa(th('Empty Blocks'));
        wa(th('Avg Space'));
        wa(th('Avg Row Len<sup>2</sup>'));
        wa(th('Chain Cnt'));
        wa(th('Global Stats<sup>2</sup>'));
        wa(th('User Stats<sup>2</sup>'));
        wa(th('Stat Type Locked'));
        wa(th('Stale Stats'));
        wa(th('Scope'));
        wa(th('Avg Space Freelist Blocks'));
        wa(th('Num Freelist Blocks'));
        wa(th('Avg Cached Blocks'));
        wa(th('Avg Cache Hit Ratio'));
        wa(th('Full Table Scan Cost'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      IF i.partitioned = 'YES' THEN
        wa(td(a(i.partitioned, 'tab_part_'||i.object_id)));
      ELSE
        wa(td(i.partitioned));
      END IF;
      wa(td(i.temporary));
      wa(td(i.count_star, 'r'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.extents, 'r'));
      wa(td(i.segment_blocks, 'r'));
      wa(td(i.total_segment_blocks, 'r'));
      wa(td(i.dbms_space_alloc_blocks, 'r'));
      wa(td(i.blocks, 'r'));
      wa(td(i.empty_blocks, 'r'));
      wa(td(i.avg_space, 'r'));
      wa(td(i.avg_row_len, 'r'));
      wa(td(i.chain_cnt, 'r'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa(td(i.stattype_locked));
      wa(td(i.stale_stats));
      wa(td(i.scope));
      wa(td(i.avg_space_freelist_blocks, 'r'));
      wa(td(i.num_freelist_blocks, 'r'));
      wa(td(i.avg_cached_blocks, 'r'));
      wa(td(i.avg_cache_hit_ratio, 'r'));
      wa(td(i.full_table_scan_cost, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) SELECT COUNT(*) performed in Table as per tool parameter "count_star_threshold" with current value of '||s_count_star_threshold||'.'));
    wa('<br>');
    wa(font('(2) CBO Statistics.'));
    wa('<br>');
    wa(font('(3) It considers the blocks from all partitions (if the table is partitioned).'));
    wa('<br>');
    wa(font('(4) This is the estimated size of the table if it were rebuilt, as computed by DBMS_SPACE.CREATE_TABLE_COST.'));
    wa('<br>');
    wa(go_to_sec('Table Statistics Versions', 'tab_cbo_vers'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_stats_sec: '||SQLERRM);
  END tab_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_stats_ext_sec
   *
   * ------------------------- */
  PROCEDURE tab_stats_ext_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tab_stats_ext_sec');
    wa(h2(mot('Table Statistics Extensions', 'DBA_STAT_EXTENSIONS'), 'tab_cbo_ext'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_stat_extensions
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     table_name,
                     owner,
                     extension_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Extension Name'));
        wa(th('Creator'));
        wa(th('Droppable'));
        wa(th('Extension'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.extension_name, 'l'));
      wa(td(i.creator, 'l'));
      wa(td(i.droppable));
      sanitize_and_append(i.extension, p_max_line_size => 120);
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_stats_ext_sec: '||SQLERRM);
  END tab_stats_ext_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_stats_vers_sec
   *
   * ------------------------- */
  PROCEDURE tab_stats_vers_sec
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('tab_stats_vers_sec');
    wa(h2(mot('Table Statistics Versions', 'DBA_TAB_STATS_VERSIONS'), 'tab_cbo_vers'));

    l_sql := '
SELECT v.table_name,
       v.owner,
       v.version_type,
       v.save_time,
       v.last_analyzed,
       v.num_rows,
       v.sample_size,
       CASE WHEN v.num_rows > 0 THEN ROUND(v.sample_size * 100 / v.num_rows, 1) END percent,
       v.blocks,
       v.avg_row_len
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_tab_stats_versions_v v
 WHERE v.statement_id = '||s_sql_rec.statement_id||'
   AND v.object_type = ''TABLE''
 ORDER BY
       v.table_name,
       v.owner,
       DECODE(v.version_type,
       ''PENDING'', 1,
       ''CURRENT'', 2,
       ''HISTORY'', 3, 4),
       v.save_time DESC;';

    wa('List of pending, current and historic CBO statistics, restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT v.table_name,
                     v.owner,
                     v.version_type,
                     v.save_time,
                     v.last_analyzed,
                     v.num_rows,
                     v.sample_size,
                     CASE WHEN v.num_rows > 0 THEN TO_CHAR(ROUND(v.sample_size * 100 / v.num_rows, 1), PERCENT_FORMAT) END percent,
                     v.blocks,
                     v.avg_row_len
                     --v.global_stats,
                     --v.user_stats
                FROM sqlt$_dba_tab_stats_versions_v v
               WHERE v.statement_id = s_sql_rec.statement_id
                 AND v.object_type = 'TABLE'
               ORDER BY
                     v.table_name,
                     v.owner,
                     DECODE(v.version_type,
                     'PENDING', 1,
                     'CURRENT', 2,
                     'HISTORY', 3, 4),
                     v.save_time DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Version Type'));
        wa(th('Save Time'));
        wa(th('Last Analyzed'));
        wa(th('Num Rows'));
        wa(th('Sample Size'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Blocks'));
        wa(th('Avg Row Len'));
        --wa(th('Global Stats'));
        --wa(th('User Stats'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.version_type, 'l'));
      wa(td(TO_CHAR(i.save_time, TIMESTAMP_TZ_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(i.blocks, 'r'));
      wa(td(i.avg_row_len, 'r'));
      --wa(td(i.global_stats));
      --wa(td(i.user_stats));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Table Statistics', 'tab_stats'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_stats_vers_sec: '||SQLERRM);
  END tab_stats_vers_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_mod_sec
   *
   * ------------------------- */
  PROCEDURE tab_mod_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tab_mod_sec');
    wa(h2(mot('Table Modifications', 'DBA_TAB_MODIFICATIONS'), 'tab_mod'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT s.table_name,
                     s.owner,
                     s.num_rows,
                     m.inserts,
                     m.updates,
                     m.deletes,
                     (m.inserts + m.updates + m.deletes) total,
                     CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND((m.inserts + m.updates + m.deletes) * 100 / s.num_rows, 1), PERCENT_FORMAT) END percent,
                     s.stale_stats,
                     m.timestamp,
                     m.truncated,
                     m.drop_segments
                FROM sqlt$_dba_tab_statistics s,
                     sqlt$_dba_tab_modifications m
               WHERE s.statement_id = s_sql_rec.statement_id
                 AND s.object_type = 'TABLE'
                 AND s.statement_id = m.statement_id(+)
                 AND s.owner = m.table_owner(+)
                 AND s.table_name = m.table_name(+)
                 AND m.partition_name IS NULL
               ORDER BY
                     s.table_name,
                     s.owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Num Rows'));
        wa(th('Inserts'));
        wa(th('Updates'));
        wa(th('Deletes'));
        wa(th('Total'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Stale Stats'));
        wa(th('Timestamp'));
        wa(th('Truncated'));
        wa(th('Drop Segments'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.inserts, 'r'));
      wa(td(i.updates, 'r'));
      wa(td(i.deletes, 'r'));
      wa(td(i.total, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(i.stale_stats));
      wa(td(TO_CHAR(i.timestamp, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.truncated));
      wa(td(i.drop_segments, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_mod_sec: '||SQLERRM);
  END tab_mod_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_prop_sec
   *
   * ------------------------- */
  PROCEDURE tab_prop_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tab_prop_sec');
    wa(h2(mot('Table Properties', 'DBA_TABLES'), 'tab_prop'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_all_tables_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     table_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th(mot('Part', 'Partitioned')));
        wa(th('Degree'));
        wa(th('Instances'));
        wa(th(mot('Temp', 'Temporary')));
        wa(th('Duration'));
        wa(th('IOT Name'));
        wa(th('IOT Type'));
        wa(th('Cluster Name'));
        wa(th('Cluster Owner'));
        wa(th('Nested'));
        wa(th('Secondary'));
        wa(th('Cache'));
        wa(th('Result Cache'));
        wa(th('Table Lock'));
        wa(th('Read Only'));
        wa(th('Row Movement'));
        wa(th('Skip Corrupt'));
        wa(th('Dependencies'));
        wa(th('Monitoring'));
        wa(th('Status'));
        wa(th('Dropped'));
        wa(th('Segment Created'));
        IF sqlt$a.get_rdbms_version >= '12.1.0.2' THEN
          wa(th('In-Memory'));
          wa(th('In-Memory Priority'));
          wa(th('In-Memory Distribute'));
          wa(th('In-Memory Compression'));
          wa(th('In-Memory Duplicate'));
        END IF;
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      IF i.partitioned = 'YES' THEN
        wa(td(a(i.partitioned, 'tab_part_'||i.object_id)));
      ELSE
        wa(td(i.partitioned));
      END IF;
      wa(td(i.degree));
      wa(td(i.instances));
      wa(td(i.temporary));
      wa(td(i.duration));
      wa(td(i.iot_name, 'l'));
      wa(td(i.iot_type));
      wa(td(i.cluster_name, 'l'));
      wa(td(i.cluster_owner, 'l'));
      wa(td(i.nested));
      wa(td(i.secondary));
      wa(td(i.cache));
      wa(td(i.result_cache));
      wa(td(i.table_lock));
      wa(td(i.read_only));
      wa(td(i.row_movement));
      wa(td(i.skip_corrupt));
      wa(td(i.dependencies));
      wa(td(i.monitoring));
      wa(td(i.status));
      wa(td(i.dropped));
      wa(td(i.segment_created));
      IF sqlt$a.get_rdbms_version >= '12.1.0.2' THEN
        wa(td(i.inmemory));
        wa(td(i.inmemory_priority));
        wa(td(i.inmemory_distribute));
        wa(td(i.inmemory_compression));
        wa(td(i.inmemory_duplicate));
      END IF;
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_prop_sec: '||SQLERRM);
  END tab_prop_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_phy_prop_sec
   *
   * ------------------------- */
  PROCEDURE tab_phy_prop_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tab_phy_prop_sec');
    wa(h2(mot('Table Physical Properties', 'DBA_TABLES'), 'tab_phy_prop'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_all_tables_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     table_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Pct Free'));
        wa(th('Pct Used'));
        wa(th('Ini Trans'));
        wa(th('Max Trans'));
        wa(th('Initial Extent'));
        wa(th('Next Extent'));
        wa(th('Min Extents'));
        wa(th('Max Extents'));
        wa(th('Pct Increase'));
        wa(th('Free Lists'));
        wa(th('Free List Groups'));
        wa(th('Logging'));
        wa(th('Backed Up'));
        wa(th('Buffer Pool'));
        wa(th('Flash Cache'));
        wa(th('Cell Flash Cache'));
        wa(th('TableSpace Name'));
        wa(th('Compression'));
        wa(th('Compress for'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.pct_free, 'r'));
      wa(td(i.pct_used, 'r'));
      wa(td(i.ini_trans, 'r'));
      wa(td(i.max_trans, 'r'));
      wa(td(i.initial_extent, 'r'));
      wa(td(i.next_extent, 'r'));
      wa(td(i.min_extents, 'r'));
      wa(td(i.max_extents, 'r'));
      wa(td(i.pct_increase, 'r'));
      wa(td(i.freelists, 'r'));
      wa(td(i.freelist_groups, 'r'));
      wa(td(i.logging));
      wa(td(i.backed_up));
      wa(td(i.buffer_pool));
      wa(td(i.flash_cache));
      wa(td(i.cell_flash_cache));
      wa(td(i.tablespace_name, 'l'));
      wa(td(i.compression));
      wa(td(i.compress_for));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_phy_prop_sec: '||SQLERRM);
  END tab_phy_prop_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_cons_sec
   *
   * ------------------------- */
  PROCEDURE tab_cons_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tab_cons_sec');
    wa(h2(mot('Table Constraints', 'DBA_CONSTRAINTS'), 'tab_cons'));

    wa('<ul>');
    FOR i IN (SELECT c.table_name,
                     c.owner,
                     t.object_id
                FROM sqlt$_dba_constraints c,
                     sqlt$_dba_all_tables_v t
               WHERE c.statement_id = s_sql_rec.statement_id
                 AND c.statement_id = t.statement_id
                 AND c.table_name = t.table_name
                 AND c.owner = t.owner
               GROUP BY
                     c.table_name,
                     c.owner,
                     t.object_id
               ORDER BY
                     c.table_name,
                     c.owner,
                     t.object_id)
    LOOP
      wa(li(a(i.table_name, 'tab_cons_'||i.object_id)));
    END LOOP;
    wa('</ul>');
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    FOR i IN (SELECT c.table_name,
                     c.owner,
                     t.object_id
                FROM sqlt$_dba_constraints c,
                     sqlt$_dba_all_tables_v t
               WHERE c.statement_id = s_sql_rec.statement_id
                 AND c.statement_id = t.statement_id
                 AND c.table_name = t.table_name
                 AND c.owner = t.owner
               GROUP BY
                     c.table_name,
                     c.owner,
                     t.object_id
               ORDER BY
                     c.table_name,
                     c.owner,
                     t.object_id)
    LOOP
      wa(h4(i.owner||'.'||i.table_name||' - Table Constraints', 'tab_cons_'||i.object_id));

      wa('<table>');
      l_row_count := 0;
      FOR j IN (SELECT (SELECT r.table_name
                          FROM sqlt$_dba_constraints r
                         WHERE c.statement_id = r.statement_id
                           AND c.r_owner = r.owner
                           AND c.r_constraint_name = r.constraint_name
                           AND ROWNUM = 1) r_table_name,
                       c.*
                  FROM sqlt$_dba_constraints c
                 WHERE c.statement_id = s_sql_rec.statement_id
                   AND c.table_name = i.table_name
                   AND c.owner = i.owner
                 ORDER BY
                       c.constraint_type,
                       c.constraint_name)
      LOOP
        l_row_count := l_row_count + 1;
        IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
          wa('<tr>');
          wa(th('#'));
          wa(th('Type'));
          wa(th('Constraint Name'));
          wa(th('Search Condition'));
          wa(th('Last Change'));
          wa(th('Status'));
          wa(th('Deferrable'));
          wa(th('Deferred'));
          wa(th('Validated'));
          wa(th('Generated'));
          wa(th('Refer Owner'));
          wa(th('Refer Constr Name'));
          wa(th('Refer Table'));
          wa(th('Delete Rule'));
          wa(th('Index Owner'));
          wa(th('Index Name'));
          wa(th('Bad'));
          wa(th('Rely'));
          wa(th('Invalid'));
          wa(th('View Related'));
          wa('</tr>');
        END IF;

        wa('<tr>');
        wa(td(l_row_count, 'rt'));
        wa(td(j.constraint_type));
        wa(td(a(NULL, NULL, 'cons_'||j.owner||'_'||j.constraint_name)||j.constraint_name, 'l'));
        sanitize_and_append(j.search_condition);
        wa(td(TO_CHAR(j.last_change, LOAD_DATE_FORMAT), 'c', 'nowrap'));
        wa(td(j.status));
        wa(td(j.deferrable));
        wa(td(j.deferred));
        wa(td(j.validated));
        wa(td(j.generated));
        wa(td(j.r_owner, 'l'));
        IF j.r_constraint_name IS NULL THEN
          wa(td(NBSP));
        ELSE
          wa(td(a(j.r_constraint_name, 'cons_'||j.r_owner||'_'||j.r_constraint_name), 'l'));
        END IF;
        wa(td(j.r_table_name, 'l'));
        wa(td(j.delete_rule));
        wa(td(j.index_owner, 'l'));
        IF j.index_name IS NOT NULL THEN
          wa(td(a(j.index_name, 'idx_cols_cbo_'||sqlt$a.get_object_id(s_sql_rec.statement_id, 'INDEX', j.index_owner, j.index_name)), 'l'));
        ELSE
          wa(td(j.index_name));
        END IF;
        wa(td(j.bad));
        wa(td(j.rely));
        wa(td(j.invalid));
        wa(td(j.view_related));
        wa('</tr>');
      END LOOP;
      wa('</table>');
      wa(go_to_sec('Table Constraints', 'tab_cons'));
    END LOOP;
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_cons_sec: '||SQLERRM);
  END tab_cons_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_cols_cbo_sec
   *
   * ------------------------- */
  PROCEDURE tab_cols_cbo_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_a4nulls NUMBER;
    l_selectivity NUMBER;
    l_cardinality NUMBER;
  BEGIN
    write_log('tab_cols_cbo_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - Column Statistics', 'DBA_TAB_COLS'), 'tab_cols_cbo_'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT c.*,
                     t.num_rows,
                     CASE
                     WHEN t.num_rows > c.num_nulls THEN TO_CHAR(LEAST(100, ROUND(c.sample_size * 100 / (t.num_rows - c.num_nulls), 1)), PERCENT_FORMAT)
                     WHEN t.num_rows = c.num_nulls THEN TO_CHAR(100, PERCENT_FORMAT)
                     END percent,
                     ht.html_table,
                     ht2.html_table html_table2,
                     t.dv_censored
                FROM sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_all_tables_v t,
                     sqlg$_column_html_table ht,
                     sqlg$_column_html_table ht2
               WHERE c.statement_id = s_sql_rec.statement_id
                 AND c.table_name = p_table_name
                 AND c.owner = p_owner
                 AND c.statement_id = t.statement_id
                 AND c.table_name = t.table_name
                 AND c.owner = t.owner
                 AND c.column_name = ht.column_name(+)
                 AND 'P' = ht.type(+)
                 AND c.owner = ht2.owner(+)
                 AND c.table_name = ht2.table_name(+)
                 AND c.column_name = ht2.column_name(+)
                 AND 'I' = ht2.type(+)
               ORDER BY
                     c.in_predicates DESC,
                     c.in_indexes DESC,
                     c.in_projection DESC,
                     c.column_id NULLS LAST,
                     c.column_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Index', 4)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Default'));
        IF s_sql_rec.rdbms_release >= 11 THEN
          wa(th('Not Null with Default Value'));
        END IF;
        wa(th('Num Rows'));
        wa(th('Num Nulls'));
        wa(th('Sample Size'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Num Distinct'));
        wa(th('Fluctuating NDV<sup>1</sup>'));
        wa(th('Low Value<sup>2</sup>'));
        wa(th('High Value<sup>2</sup>'));
        wa(th('Last Analyzed'));
        wa(th('Avg Col Len'));
        wa(th('Density'));
        wa(th('Num Buckets'));
        wa(th('Histogram'));
        wa(th('Fluctuating Endpoint Count<sup>3</sup>'));
        wa(th('Popular Values'));
        wa(th('Global Stats'));
        wa(th('User Stats'));
        wa(th('Equality Predicate Selectivity'));
        wa(th('Equality Predicate Cardinality'));
        wa('</tr>');
      END IF;

      IF i.num_rows > 0 AND i.num_distinct > 0 THEN
        l_a4nulls := (i.num_rows - i.num_nulls) / i.num_rows;
        l_selectivity := (1 / i.num_distinct) * l_a4nulls;
        l_cardinality := CEIL(i.num_rows * l_selectivity);
      ELSE
        l_selectivity := NULL;
        l_cardinality := NULL;
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      IF i.in_predicates = 'TRUE' AND i.html_table IS NOT NULL AND s_in_pred = 'Y' THEN
        wa_td_hide(i.html_table);
      ELSE
        wa(td(i.in_predicates));
      END IF;
      IF i.in_indexes = 'TRUE' AND i.html_table2 IS NOT NULL THEN
        wa_td_hide(i.html_table2);
      ELSE
        wa(td(i.in_indexes));
      END IF;
      wa(td(i.in_projection));
      wa(td(i.column_id));
      wa(td(i.column_name, 'l'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      IF s_sql_rec.rdbms_release >= 11 THEN
        wa(td(i.add_column_default));
      END IF;
      wa(td(i.num_rows, 'r'));
      wa(td(i.num_nulls, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(i.num_distinct, 'r'));
      wa(td(i.mutating_ndv));
      IF i.low_value_cooked IS NULL THEN
        wa(td(NBSP));
      ELSIF i.dv_censored = 'Y' THEN  -- Data Vault censored value
        wa(td(DVCENS));
      ELSE
        sanitize_and_append('"'||i.low_value_cooked||'"');
      END IF;
      IF i.high_value_cooked IS NULL THEN
        wa(td(NBSP));
      ELSIF i.dv_censored = 'Y' THEN  -- Data Vault censored value
        wa(td(DVCENS));		
      ELSE
        sanitize_and_append('"'||i.high_value_cooked||'"');
      END IF;
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.avg_col_len, 'r'));
      wa(td(LOWER(TO_CHAR(i.density, SCIENTIFIC_NOTATION)), 'r', 'nowrap'));
      wa(td(i.num_buckets, 'r'));
      IF i.histogram = 'NONE' THEN
        wa(td(i.histogram, 'l'));
      ELSE
        wa(td(a(i.histogram, 'tab_col_hgrm_'||p_object_id||'_'||i.column_name), 'c', 'nowrap'));  --12.1.04
      END IF;
      wa(td(i.mutating_endpoints));
      wa(td(i.popular_values, 'r'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa(td(TO_CHAR(ROUND(l_selectivity, 6), SELECTIVITY_FORMAT), 'r', 'nowrap'));
      wa(td(l_cardinality, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) A value of TRUE means that section "Column Statistics Versions" shows "Number of Distinct Values" changing more than 10% between two consecutive versions.'));
    wa('<br>');
    wa(font('(2) The display of values in this column is controlled by tool parameter "s_mask_for_values". Its current value is "'||s_mask_for_values||'".'));
    wa('<br>');
    wa(font('(3) A value of TRUE means that section "Column Statistics Versions" shows "Endpoint Count" changing more than 10% between two consecutive versions.'));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_cols_cbo_sec_'||p_object_id||': '||SQLERRM);
  END tab_cols_cbo_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private idx_cols_cbo_sec
   *
   * ------------------------- */
  PROCEDURE idx_cols_cbo_sec (
    p_index_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_a4nulls NUMBER;
    l_selectivity NUMBER;
    l_cardinality NUMBER;
    l_idx_desc VARCHAR2(32767);
  BEGIN
    write_log('idx_cols_cbo_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_index_name||' - Column Statistics', 'DBA_TAB_COLS'), 'idx_cols_cbo_'||p_object_id));

    SELECT 'Index type:'||index_type||
           ' '||(CASE WHEN partitioned = 'YES' THEN 'PART' END)||
           ' '||(CASE WHEN temporary = 'YES' THEN 'TEMP' END)||
           ' rows:'||num_rows||
           ' smpl:'||sample_size||
           ' lvls:'||blevel||
           ' #lb:'||leaf_blocks||
           ' #dk:'||distinct_keys||
           ' cluf:'||clustering_factor||
           ' anlz:'||TO_CHAR(last_analyzed, LOAD_DATE_FORMAT)
      INTO l_idx_desc
      FROM sqlt$_dba_indexes
     WHERE statement_id = s_sql_rec.statement_id
       AND owner = p_owner
       AND index_name = p_index_name;

    wa(l_idx_desc);
    wa('<table>');
    l_row_count := 0;

    FOR i IN (SELECT ic.column_position,
                     ic.descend,
                     c.*,
                     t.object_id t_object_id,
                     t.num_rows,
                     CASE
                     WHEN t.num_rows > c.num_nulls THEN TO_CHAR(LEAST(100, ROUND(c.sample_size * 100 / (t.num_rows - c.num_nulls), 1)), PERCENT_FORMAT)
                     WHEN t.num_rows = c.num_nulls THEN TO_CHAR(100, PERCENT_FORMAT)
                     END percent,
                     ht.html_table,
                     t.dv_censored
                FROM sqlt$_dba_ind_columns ic,
                     sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_all_tables_v t,
                     sqlg$_column_html_table ht
               WHERE ic.statement_id = s_sql_rec.statement_id
                 AND ic.index_name = p_index_name
                 AND ic.index_owner = p_owner
                 AND ic.statement_id = c.statement_id
                 AND ic.table_name = c.table_name
                 AND ic.table_owner = c.owner
                 AND ic.column_name = c.column_name
                 AND c.statement_id = t.statement_id
                 AND c.table_name = t.table_name
                 AND c.owner = t.owner
                 AND c.column_name = ht.column_name(+)
                 AND 'P' = ht.type(+)
               ORDER BY
                     ic.column_position)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Col Pos'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Default'));
        IF s_sql_rec.rdbms_release >= 11 THEN
          wa(th('Not Null with Default Value'));
        END IF;
        wa(th('Descend'));
        wa(th('Num Rows'));
        wa(th('Num Nulls'));
        wa(th('Sample Size'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Num Distinct'));
        wa(th('Fluctuating NDV<sup>1</sup>'));
        wa(th('Low Value<sup>2</sup>'));
        wa(th('High Value<sup>2</sup>'));
        wa(th('Last Analyzed'));
        wa(th('Avg Col Len'));
        wa(th('Density'));
        wa(th('Num Buckets'));
        wa(th('Histogram'));
        wa(th('Fluctuating Endpoint Count<sup>3</sup>'));
        wa(th('Popular Values'));
        wa(th('Global Stats'));
        wa(th('User Stats'));
        wa(th('Equality Predicate Selectivity'));
        wa(th('Equality Predicate Cardinality'));
        wa('</tr>');
      END IF;

      IF i.num_rows > 0 AND i.num_distinct > 0 THEN
        l_a4nulls := (i.num_rows - i.num_nulls) / i.num_rows;
        l_selectivity := (1 / i.num_distinct) * l_a4nulls;
        l_cardinality := CEIL(i.num_rows * l_selectivity);
      ELSE
        l_selectivity := NULL;
        l_cardinality := NULL;
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.column_position, 'r'));
      IF i.in_predicates = 'TRUE' AND i.html_table IS NOT NULL AND s_in_pred = 'Y' THEN
        wa_td_hide(i.html_table);
      ELSE
        wa(td(i.in_predicates));
      END IF;
      wa(td(i.in_projection));
      wa(td(i.column_id));
      wa(td(i.column_name, 'l'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      IF s_sql_rec.rdbms_release >= 11 THEN
        wa(td(i.add_column_default));
      END IF;
      wa(td(i.descend, 'l'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.num_nulls, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(i.num_distinct, 'r'));
      wa(td(i.mutating_ndv));
      IF i.low_value_cooked IS NULL THEN
        wa(td(NBSP));
      ELSIF i.dv_censored = 'Y' THEN  -- Data Vault censored value
       wa(td(DVCENS));		
      ELSE
        sanitize_and_append('"'||i.low_value_cooked||'"');
      END IF;
      IF i.high_value_cooked IS NULL THEN
        wa(td(NBSP));
      ELSIF i.dv_censored = 'Y' THEN  -- Data Vault censored value
        wa(td(DVCENS));		
      ELSE
        sanitize_and_append('"'||i.high_value_cooked||'"');
      END IF;
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.avg_col_len, 'r'));
      wa(td(LOWER(TO_CHAR(i.density, SCIENTIFIC_NOTATION)), 'r', 'nowrap'));
      wa(td(i.num_buckets, 'r'));
      IF i.histogram = 'NONE' THEN
        wa(td(i.histogram, 'l'));
      ELSE
        wa(td(a(i.histogram, 'tab_col_hgrm_'||i.t_object_id||'_'||i.column_name), 'c', 'nowrap'));  --12.1.04
      END IF;
      wa(td(i.mutating_endpoints));
      wa(td(i.popular_values, 'r'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa(td(TO_CHAR(ROUND(l_selectivity, 6), SELECTIVITY_FORMAT), 'r', 'nowrap'));
      wa(td(l_cardinality, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) A value of TRUE means that section "Column Statistics Versions" shows "Number of Distinct Values" changing more than 10% between two consecutive versions.'));
    wa('<br>');
    wa(font('(2) The display of values in this column is controlled by tool parameter "s_mask_for_values". Its current value is "'||s_mask_for_values||'".'));
    wa('<br>');
    wa(font('(3) A value of TRUE means that section "Column Statistics Versions" shows "Endpoint Count" changing more than 10% between two consecutive versions.'));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('idx_cols_cbo_sec_'||p_object_id||': '||SQLERRM);
  END idx_cols_cbo_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_cols_vers_sec
   *
   * ------------------------- */
  PROCEDURE tab_cols_vers_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('tab_cols_vers_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - Column Statistics Versions', 'DBA_COL_STATS_VERSIONS'), 'tab_cols_vers_'||p_object_id));

    l_sql := '
SELECT c.in_predicates,
       c.in_indexes,
       c.in_projection,
       c.column_id,
       c.column_name,
       c.data_default,
       v.version_type,
       v.save_time,
       v.last_analyzed,
       v.num_nulls,
       v.sample_size,
       v.num_distinct,
       v.endpoints_count,
       v.low_value_cooked,
       v.high_value_cooked,
       v.avg_col_len,
       v.density
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_col_stats_versions_v v,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_table_cols_v c
 WHERE v.statement_id = '||s_sql_rec.statement_id||'
   AND v.table_name = '''||p_table_name||'''
   AND v.owner = '''||p_owner||'''
   AND v.object_type = ''TABLE''
   AND v.statement_id = c.statement_id
   AND v.column_name = c.column_name
   AND v.table_name = c.table_name
   AND v.owner = c.owner
   AND (c.in_predicates = ''TRUE'' OR c.in_indexes = ''TRUE'' OR c.in_projection = ''TRUE'')
   --AND c.hidden_column = ''NO''
 ORDER BY
       c.in_predicates DESC,
       c.in_indexes DESC,
       c.in_projection DESC,
       c.column_id NULLS LAST,
       c.column_name,
       DECODE(v.version_type,
       ''PENDING'', 1,
       ''CURRENT'', 2,
       ''HISTORY'', 3, 4),
       v.save_time DESC;';

    wa('Restricted list of pending, current and historic CBO statistics for columns in predicates, indexes or projections.');
    wa('<br>');
    wa('Further restricted up to '||s_rows_table_m||' rows as per tool parameter "r_rows_table_m".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT c.in_predicates,
                     c.in_indexes,
                     c.in_projection,
                     c.column_id,
                     c.column_name,
                     c.data_default,
                     v.version_type,
                     v.save_time,
                     v.last_analyzed,
                     v.num_nulls,
                     v.sample_size,
                     v.num_distinct,
                     v.endpoints_count,
                     v.low_value_cooked,
                     v.high_value_cooked,
                     v.avg_col_len,
                     v.density,
                     t.dv_censored
                FROM sqlt$_dba_col_stats_versions_v v,
                     sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_all_tables_v t
               WHERE v.statement_id = s_sql_rec.statement_id
                 AND v.table_name = p_table_name
                 AND v.owner = p_owner
                 AND v.object_type = 'TABLE'
                 AND v.statement_id = c.statement_id
                 AND v.column_name = c.column_name
                 AND v.table_name = c.table_name
                 AND v.owner = c.owner
                 AND v.statement_id = t.statement_id
                 AND v.table_name = t.table_name
                 AND v.owner = t.owner
                 AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
                 --AND c.hidden_column = 'NO'
               ORDER BY
                     c.in_predicates DESC,
                     c.in_indexes DESC,
                     c.in_projection DESC,
                     c.column_id NULLS LAST,
                     c.column_name,
                     DECODE(v.version_type,
                     'PENDING', 1,
                     'CURRENT', 2,
                     'HISTORY', 3, 4),
                     v.save_time DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Index', 4)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Default'));
        wa(th('Version Type'));
        wa(th('Save Time'));
        wa(th('Last Analyzed'));
        wa(th('Num Nulls'));
        wa(th('Sample Size'));
        wa(th('Num Distinct'));
        wa(th('Endpoint Count'));
        wa(th('Low Value<sup>1</sup>'));
        wa(th('High Value<sup>1</sup>'));
        wa(th('Avg Col Len'));
        wa(th('Density'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.in_predicates));
      wa(td(i.in_indexes));
      wa(td(i.in_projection));
      wa(td(i.column_id));
      wa(td(i.column_name, 'l'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      wa(td(i.version_type, 'l'));
      wa(td(TO_CHAR(i.save_time, TIMESTAMP_TZ_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.num_nulls, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.num_distinct, 'r'));
      wa(td(i.endpoints_count, 'r'));
      IF i.low_value_cooked IS NULL THEN
        wa(td(NBSP));
      ELSIF i.dv_censored = 'Y' THEN  -- Data Vault censored value
        wa(td(DVCENS));			
      ELSE
        sanitize_and_append('"'||i.low_value_cooked||'"');
      END IF;
      IF i.high_value_cooked IS NULL THEN
        wa(td(NBSP));
      ELSIF i.dv_censored = 'Y' THEN  -- Data Vault censored value
        wa(td(DVCENS));			
      ELSE
        sanitize_and_append('"'||i.high_value_cooked||'"');
      END IF;
      wa(td(i.avg_col_len, 'r'));
      wa(td(LOWER(TO_CHAR(i.density, SCIENTIFIC_NOTATION)), 'r', 'nowrap'));
      wa('</tr>');

      IF l_row_count = s_rows_table_m THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) The display of values in this column is controlled by tool parameter "s_mask_for_values". Its current value is "'||s_mask_for_values||'".'));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_cols_vers_sec_'||p_object_id||': '||SQLERRM);
  END tab_cols_vers_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private idx_cols_vers_sec
   *
   * ------------------------- */
  PROCEDURE idx_cols_vers_sec (
    p_index_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('idx_cols_vers_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_index_name||' - Column Statistics Versions', 'DBA_COL_STATS_VERSIONS'), 'idx_cols_vers_'||p_object_id));

    l_sql := '
SELECT ic.column_position,
       c.in_predicates,
       c.in_projection,
       c.column_id,
       c.column_name,
       c.data_default,
       v.version_type,
       v.save_time,
       v.last_analyzed,
       v.num_nulls,
       v.sample_size,
       v.num_distinct,
       v.endpoints_count,
       v.low_value_cooked,
       v.high_value_cooked,
       v.avg_col_len,
       v.density
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_ind_columns ic,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_col_stats_versions_v v,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_table_cols_v c
 WHERE ic.statement_id = '||s_sql_rec.statement_id||'
   AND ic.index_name = '''||p_index_name||'''
   AND ic.index_owner = '''||p_owner||'''
   AND ic.statement_id = v.statement_id
   AND ic.table_name = v.table_name
   AND ic.table_owner = v.owner
   AND ic.column_name = v.column_name
   AND v.object_type = ''TABLE''
   AND ic.statement_id = c.statement_id
   AND ic.table_name = c.table_name
   AND ic.table_owner = c.owner
   AND ic.column_name = c.column_name
 ORDER BY
       ic.column_position,
       DECODE(v.version_type,
       ''PENDING'', 1,
       ''CURRENT'', 2,
       ''HISTORY'', 3, 4),
       v.save_time DESC;';

    wa('List of pending, current and historic CBO statistics, restricted up to '||s_rows_table_s||' rows as per tool parameter "r_rows_table_s".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT ic.column_position,
                     c.in_predicates,
                     c.in_projection,
                     c.column_id,
                     c.column_name,
                     c.data_default,
                     v.version_type,
                     v.save_time,
                     v.last_analyzed,
                     v.num_nulls,
                     v.sample_size,
                     v.num_distinct,
                     v.endpoints_count,
                     v.low_value_cooked,
                     v.high_value_cooked,
                     v.avg_col_len,
                     v.density,
                     t.dv_censored
                FROM sqlt$_dba_ind_columns ic,
                     sqlt$_dba_col_stats_versions_v v,
                     sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_all_tables_v t
               WHERE ic.statement_id = s_sql_rec.statement_id
                 AND ic.index_name = p_index_name
                 AND ic.index_owner = p_owner
                 AND ic.statement_id = v.statement_id
                 AND ic.table_name = v.table_name
                 AND ic.table_owner = v.owner
                 AND ic.column_name = v.column_name
                 AND v.object_type = 'TABLE'
                 AND ic.statement_id = c.statement_id
                 AND ic.table_name = c.table_name
                 AND ic.table_owner = c.owner
                 AND ic.column_name = c.column_name
                 AND ic.statement_id = t.statement_id
                 AND ic.table_name = t.table_name
                 AND ic.table_owner = t.owner
               ORDER BY
                     ic.column_position,
                     DECODE(v.version_type,
                     'PENDING', 1,
                     'CURRENT', 2,
                     'HISTORY', 3, 4),
                     v.save_time DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Col Pos'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Default'));
        wa(th('Version Type'));
        wa(th('Save Time'));
        wa(th('Last Analyzed'));
        wa(th('Num Nulls'));
        wa(th('Sample Size'));
        wa(th('Num Distinct'));
        wa(th('Endpoint Count'));
        wa(th('Low Value<sup>1</sup>'));
        wa(th('High Value<sup>1</sup>'));
        wa(th('Avg Col Len'));
        wa(th('Density'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.column_position, 'r'));
      wa(td(i.in_predicates));
      wa(td(i.in_projection));
      wa(td(i.column_id));
      wa(td(i.column_name, 'l'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      wa(td(i.version_type, 'l'));
      wa(td(TO_CHAR(i.save_time, TIMESTAMP_TZ_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.num_nulls, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.num_distinct, 'r'));
      wa(td(i.endpoints_count, 'r'));
      IF i.low_value_cooked IS NULL THEN
        wa(td(NBSP));
      ELSIF i.dv_censored = 'Y' THEN  -- Data Vault censored value
        wa(td(DVCENS));			
      ELSE
        sanitize_and_append('"'||i.low_value_cooked||'"');
      END IF;
      IF i.high_value_cooked IS NULL THEN
        wa(td(NBSP));
      ELSIF i.dv_censored = 'Y' THEN  -- Data Vault censored value
        wa(td(DVCENS));			
      ELSE
        sanitize_and_append('"'||i.high_value_cooked||'"');
      END IF;
      wa(td(i.avg_col_len, 'r'));
      wa(td(LOWER(TO_CHAR(i.density, SCIENTIFIC_NOTATION)), 'r', 'nowrap'));
      wa('</tr>');

      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) The display of values in this column is controlled by tool parameter "s_mask_for_values". Its current value is "'||s_mask_for_values||'".'));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('idx_cols_vers_sec_'||p_object_id||': '||SQLERRM);
  END idx_cols_vers_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_cols_usage_sec
   *
   * ------------------------- */
  PROCEDURE tab_cols_usage_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tab_cols_usage_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - Column Usage', 'COL_USAGE$'), 'tab_cols_usage_'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT v.*,
                     c.in_predicates c_in_predicates,
                     c.in_projection c_in_projection,
                     c.in_indexes c_in_indexes,
                     c.column_id c_column_id,
                     c.data_default
                FROM sqlt$_dba_col_usage$ v,
                     sqlt$_dba_all_table_cols_v c
               WHERE v.statement_id = s_sql_rec.statement_id
                 AND v.table_name = p_table_name
                 AND v.owner = p_owner
                 AND v.statement_id = c.statement_id
                 AND v.column_name = c.column_name
                 AND v.table_name = c.table_name
                 AND v.owner = c.owner
               ORDER BY
                     c.in_predicates DESC,
                     c.in_indexes DESC,
                     c.in_projection DESC,
                     c.column_id NULLS LAST,
                     c.column_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Index', 4)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Default'));
        wa(th('Equality Preds'));
        wa(th('Equijoin Preds'));
        wa(th('Non-equijoin Preds'));
        wa(th('Range Preds'));
        wa(th('LIKE Preds'));
        wa(th('NULL Preds'));
        wa(th('Timestamp'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.c_in_predicates));
      wa(td(i.c_in_indexes));
      wa(td(i.c_in_projection));
      wa(td(i.c_column_id));
      wa(td(i.column_name, 'l'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      wa(td(i.equality_preds, 'r'));
      wa(td(i.equijoin_preds, 'r'));
      wa(td(i.nonequijoin_preds, 'r'));
      wa(td(i.range_preds, 'r'));
      wa(td(i.like_preds, 'r'));
      wa(td(i.null_preds, 'r'));
      wa(td(TO_CHAR(i.timestamp, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_cols_usage_sec_'||p_object_id||': '||SQLERRM);
  END tab_cols_usage_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private idx_cols_usage_sec
   *
   * ------------------------- */
  PROCEDURE idx_cols_usage_sec (
    p_index_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('idx_cols_usage_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_index_name||' - Column Usage', 'COL_USAGE$'), 'idx_cols_usage_'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT v.*,
                     ic.column_position,
                     c.in_predicates c_in_predicates,
                     c.in_projection c_in_projection,
                     c.column_id c_column_id,
                     c.data_default
                FROM sqlt$_dba_ind_columns ic,
                     sqlt$_dba_col_usage$ v,
                     sqlt$_dba_all_table_cols_v c
               WHERE ic.statement_id = s_sql_rec.statement_id
                 AND ic.index_name = p_index_name
                 AND ic.index_owner = p_owner
                 AND ic.statement_id = v.statement_id
                 AND ic.table_name = v.table_name
                 AND ic.table_owner = v.owner
                 AND ic.column_name = v.column_name
                 AND ic.statement_id = c.statement_id
                 AND ic.table_name = c.table_name
                 AND ic.table_owner = c.owner
                 AND ic.column_name = c.column_name
               ORDER BY
                     ic.column_position)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Col Pos'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Default'));
        wa(th('Equality Preds'));
        wa(th('Equijoin Preds'));
        wa(th('Non-equijoin Preds'));
        wa(th('Range Preds'));
        wa(th('LIKE Preds'));
        wa(th('NULL Preds'));
        wa(th('Timestamp'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.column_position, 'r'));
      wa(td(i.c_in_predicates));
      wa(td(i.c_in_projection));
      wa(td(i.c_column_id));
      wa(td(i.column_name, 'l'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      wa(td(i.equality_preds, 'r'));
      wa(td(i.equijoin_preds, 'r'));
      wa(td(i.nonequijoin_preds, 'r'));
      wa(td(i.range_preds, 'r'));
      wa(td(i.like_preds, 'r'));
      wa(td(i.null_preds, 'r'));
      wa(td(TO_CHAR(i.timestamp, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('idx_cols_usage_sec_'||p_object_id||': '||SQLERRM);
  END idx_cols_usage_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_cols_prop_sec
   *
   * ------------------------- */
  PROCEDURE tab_cols_prop_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tab_cols_prop_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - Column Properties', 'DBA_TAB_COLS'), 'tab_cols_prop_'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT c.*
                FROM sqlt$_dba_all_table_cols_v c
               WHERE c.statement_id = s_sql_rec.statement_id
                 AND c.table_name = p_table_name
                 AND c.owner = p_owner
               ORDER BY
                     c.in_predicates DESC,
                     c.in_indexes DESC,
                     c.in_projection DESC,
                     c.column_id NULLS LAST,
                     c.column_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Index', 4)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Type'));
        wa(th('Data Type Modifier'));
        wa(th('Data Type Owner'));
        wa(th('Data Length'));
        wa(th('Data Precision'));
        wa(th('Data Scale'));
        wa(th('Nullable'));
        wa(th('Default Length'));
        wa(th('Data Default'));
        IF s_sql_rec.rdbms_release >= 11 THEN
          wa(th('Not Null with Default Value'));
        END IF;
        wa(th('Character Set Name'));
        wa(th('Char Col Decl Length'));
        wa(th('Char Length'));
        wa(th('Char Used'));
        wa(th('V80 Fmt Image'));
        wa(th('Data Upgraded'));
        wa(th('Hidden Column'));
        wa(th('Virtual Column'));
        wa(th('Segment Column ID'));
        wa(th('Internal Column ID'));
        wa(th('Qualified Col Name'));
        IF sqlt$a.get_rdbms_version >= '12.1.0.2' THEN 
          wa(th('In-Memory Compression'));
        END IF;
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.in_predicates));
      wa(td(i.in_indexes));
      wa(td(i.in_projection));
      wa(td(i.column_id));
      wa(td(i.column_name, 'l'));
      wa(td(i.data_type, 'l'));
      wa(td(i.data_type_mod));
      wa(td(i.data_type_owner, 'l'));
      wa(td(i.data_length, 'r'));
      wa(td(i.data_precision, 'r'));
      wa(td(i.data_scale, 'r'));
      wa(td(i.nullable));
      wa(td(i.default_length, 'r'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      IF s_sql_rec.rdbms_release >= 11 THEN
        wa(td(i.add_column_default));
      END IF;
      wa(td(i.character_set_name, 'l'));
      wa(td(i.char_col_decl_length, 'r'));
      wa(td(i.char_length, 'r'));
      wa(td(i.char_used));
      wa(td(i.v80_fmt_image));
      wa(td(i.data_upgraded));
      wa(td(i.hidden_column));
      wa(td(i.virtual_column));
      wa(td(i.segment_column_id));
      wa(td(i.internal_column_id));
      IF i.qualified_col_name IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.qualified_col_name);
      END IF;
      IF sqlt$a.get_rdbms_version >= '12.1.0.2' THEN 
        wa(td(i.inmemory_compression));
      END IF;
      wa('</tr>');
    END LOOP;
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_cols_prop_sec_'||p_object_id||': '||SQLERRM);
  END tab_cols_prop_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private idx_cols_prop_sec
   *
   * ------------------------- */
  PROCEDURE idx_cols_prop_sec (
    p_index_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('idx_cols_prop_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_index_name||' - Column Properties', 'DBA_TAB_COLS'), 'idx_cols_prop_'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT ic.column_position,
                     c.*
                FROM sqlt$_dba_ind_columns ic,
                     sqlt$_dba_all_table_cols_v c
               WHERE ic.statement_id = s_sql_rec.statement_id
                 AND ic.index_name = p_index_name
                 AND ic.index_owner = p_owner
                 AND ic.statement_id = c.statement_id
                 AND ic.table_name = c.table_name
                 AND ic.table_owner = c.owner
                 AND ic.column_name = c.column_name
               ORDER BY
                     ic.column_position)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Col Pos'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Type'));
        wa(th('Data Type Modifier'));
        wa(th('Data Type Owner'));
        wa(th('Data Length'));
        wa(th('Data Precision'));
        wa(th('Data Scale'));
        wa(th('Nullable'));
        wa(th('Default Length'));
        wa(th('Data Default'));
        IF s_sql_rec.rdbms_release >= 11 THEN
          wa(th('Not Null with Default Value'));
        END IF;
        wa(th('Character Set Name'));
        wa(th('Char Col Decl Length'));
        wa(th('Char Length'));
        wa(th('Char Used'));
        wa(th('V80 Fmt Image'));
        wa(th('Data Upgraded'));
        wa(th('Hidden Column'));
        wa(th('Virtual Column'));
        wa(th('Segment Column ID'));
        wa(th('Internal Column ID'));
        wa(th('Qualified Col Name'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.column_position, 'r'));
      wa(td(i.in_predicates));
      wa(td(i.in_projection));
      wa(td(i.column_id));
      wa(td(i.column_name, 'l'));
      wa(td(i.data_type, 'l'));
      wa(td(i.data_type_mod));
      wa(td(i.data_type_owner, 'l'));
      wa(td(i.data_length, 'r'));
      wa(td(i.data_precision, 'r'));
      wa(td(i.data_scale, 'r'));
      wa(td(i.nullable));
      wa(td(i.default_length, 'r'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      IF s_sql_rec.rdbms_release >= 11 THEN
        wa(td(i.add_column_default));
      END IF;
      wa(td(i.character_set_name, 'l'));
      wa(td(i.char_col_decl_length, 'r'));
      wa(td(i.char_length, 'r'));
      wa(td(i.char_used));
      wa(td(i.v80_fmt_image));
      wa(td(i.data_upgraded));
      wa(td(i.hidden_column));
      wa(td(i.virtual_column));
      wa(td(i.segment_column_id));
      wa(td(i.internal_column_id));
      IF i.qualified_col_name IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.qualified_col_name);
      END IF;
      wa('</tr>');
    END LOOP;
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('idx_cols_prop_sec_'||p_object_id||': '||SQLERRM);
  END idx_cols_prop_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_cols_sec
   *
   * ------------------------- */
  PROCEDURE tab_cols_sec
  IS
    l_row_count NUMBER;
    l_vers NUMBER := 0;
    l_cols NUMBER := 0;
    l_usage NUMBER := 0;
    l_hgrm NUMBER := 0;
    l_hgrm_vers NUMBER := 0;
    l_vers2 NUMBER := 0;
    l_usage2 NUMBER := 0;
    l_hgrm2 NUMBER := 0;
    l_hgrm_vers2 NUMBER := 0;
	l_spd NUMBER :=0;
	l_spd2 NUMBER :=0;

  BEGIN
    write_log('tab_cols_sec');
    wa(h2(mot('Table Columns', 'DBA_TAB_COLS'), 'tab_cols'));

    IF s_gran_vers IN ('COLUMN', 'HISTOGRAM') THEN
      SELECT COUNT(*)
        INTO l_vers
        FROM sqlt$_dba_col_stats_versions v,
             sqlt$_dba_all_table_cols_v c
       WHERE v.statement_id = s_sql_rec.statement_id
         AND v.object_type = 'TABLE'
         AND v.statement_id = c.statement_id
         AND v.column_name = c.column_name
         AND v.table_name = c.table_name
         AND v.owner = c.owner
         AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
         --AND c.hidden_column = 'NO'
         AND ROWNUM = 1;
    END IF;

    SELECT COUNT(*)
      INTO l_usage
      FROM sqlt$_dba_col_usage$
     WHERE statement_id = s_sql_rec.statement_id
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO l_hgrm
      FROM sqlt$_dba_tab_histograms
     WHERE statement_id = s_sql_rec.statement_id
       AND endpoint_number > 1
       AND ROWNUM = 1;

    IF s_gran_vers = 'HISTOGRAM' THEN
      IF l_hgrm > 0 THEN
        SELECT COUNT(*)
          INTO l_hgrm_vers
          FROM sqlt$_dba_histgrm_stats_versn v,
               sqlt$_dba_all_table_cols_v c
         WHERE v.statement_id = s_sql_rec.statement_id
           AND v.object_type = 'TABLE'
           AND v.statement_id = c.statement_id
           AND v.owner = c.owner
           AND v.table_name = c.table_name
           AND v.column_name = c.column_name
           AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
           --AND c.hidden_column = 'NO'
           AND ROWNUM = 1;
      END IF;
    END IF;
	
	-- 150828 only show usable (active) ones.
	SELECT COUNT(*) 
	  INTO l_spd
	  FROM sqlt$_dba_sql_plan_directives d
	 WHERE d.statement_id = s_sql_rec.statement_id
	   AND d.state='USABLE'
	   AND d.reason like '%SINGLE%'
       AND ROWNUM=1;	 

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT t.*,
                     CASE WHEN num_rows > 0 THEN TO_CHAR(ROUND(sample_size * 100 / num_rows, 1), PERCENT_FORMAT) END percent
                FROM sqlt$_dba_all_tables_v t
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     table_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Count<sup>1</sup>'));
        wa(th('Num<br>Rows<sup>2</sup>'));
        wa(th('Sample<br>Size<sup>2</sup>'));
        wa(th('Blocks<sup>2</sup>'));
        wa(th('Last<br>Analyzed<sup>2</sup>'));

        wa(th(mot('Column<br>Stats', 'Column Statistics')));

        IF l_vers > 0 THEN
          wa(th(mot('Column<br>Stats<br>Versn', 'Column Statistics Versions (restricted to columns in predicates, indexes or projections)')));
        END IF;

        IF l_usage > 0 THEN
          wa(th(mot('Column<br>Usage', 'Column Usage')));
        END IF;

        wa(th(mot('Column<br>Prop', 'Column Properties')));

        IF l_hgrm > 0 THEN
          wa(th(mot('Hgrm', 'Histograms')));
        END IF;

        IF l_hgrm_vers > 0 THEN
          wa(th(mot('Hgrm<br>Versn', 'Histogram Versions (restricted to columns in predicates, indexes or projections)')));
        END IF;

		--150828
		IF l_spd >0 then
		 wa(th(mot('Single Table<br>SQL Plan<br>Directives', 'SQL Plan Directives for a particular table')));
		END IF;
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.count_star, 'r'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.blocks, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, SHORT_DATE_FORMAT), 'c', 'nowrap'));

      SELECT COUNT(DISTINCT c.column_name)
        INTO l_cols
        FROM sqlt$_dba_all_table_cols_v c
       WHERE c.statement_id = s_sql_rec.statement_id
         AND c.owner = i.owner
         AND c.table_name = i.table_name;

      --wa(td(a('Stats', 'tab_cols_cbo_'||i.object_id)));
      wa(td(a(l_cols, 'tab_cols_cbo_'||i.object_id)));

      IF l_vers > 0 THEN
        SELECT COUNT(DISTINCT v.column_name)
          INTO l_vers2
          FROM sqlt$_dba_col_stats_versions_v v,
               sqlt$_dba_all_table_cols_v c
         WHERE v.statement_id = s_sql_rec.statement_id
           AND v.object_type = 'TABLE'
           AND v.owner = i.owner
           AND v.table_name = i.table_name
           AND v.statement_id = c.statement_id
           AND v.column_name = c.column_name
           AND v.table_name = c.table_name
           AND v.owner = c.owner
           AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE');
           --AND c.hidden_column = 'NO'

        IF l_vers2 > 0 THEN
          --wa(td(a('Versn', 'tab_cols_vers_'||i.object_id)));
          wa(td(a(l_vers2, 'tab_cols_vers_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_usage > 0 THEN
        SELECT COUNT(*)
          INTO l_usage2
          FROM sqlt$_dba_col_usage$
         WHERE statement_id = s_sql_rec.statement_id
           AND owner = i.owner
           AND table_name = i.table_name;

        IF l_usage2 > 0 THEN
          --wa(td(a('Usage', 'tab_cols_usage_'||i.object_id)));
          wa(td(a(l_usage2, 'tab_cols_usage_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      wa(td(a('Prop', 'tab_cols_prop_'||i.object_id)));

      IF l_hgrm > 0 THEN
        SELECT COUNT(DISTINCT column_name)
          INTO l_hgrm2
          FROM sqlt$_dba_tab_histograms
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner
           AND endpoint_number > 1;

        IF l_hgrm2 > 0 THEN
          --wa(td(a('Hgrm', 'tab_col_hgrm_'||i.object_id)));
          wa(td(a(l_hgrm2, 'tab_col_hgrm_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_hgrm_vers > 0 THEN
        SELECT COUNT(DISTINCT v.column_name)
          INTO l_hgrm_vers2
          FROM sqlt$_dba_histgrm_stats_versn v,
               sqlt$_dba_all_table_cols_v c
         WHERE v.statement_id = s_sql_rec.statement_id
           AND v.object_type = 'TABLE'
           AND v.owner = i.owner
           AND v.table_name = i.table_name
           AND v.statement_id = c.statement_id
           AND v.owner = c.owner
           AND v.table_name = c.table_name
           AND v.column_name = c.column_name
           AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE');
           --AND c.hidden_column = 'NO'

        IF l_hgrm_vers2 > 0 THEN
          --wa(td(a('HVers', 'tab_col_hgrm_vers_'||i.object_id)));
          wa(td(a(l_hgrm_vers2, 'tab_col_hgrm_vers_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;
    
	  IF l_spd>0 THEN
	    SELECT COUNT( distinct d.directive_id) 
	      INTO l_spd2
          FROM sqlt$_dba_sql_plan_directives d,
          	   sqlt$_dba_sql_plan_dir_objs o
         WHERE d.statement_id = s_sql_rec.statement_id
           AND o.statement_id = s_sql_rec.statement_id
		   AND o.owner = i.owner		   
           AND o.object_name =  i.table_name
           AND o.object_type='TABLE'
           AND d.state='USABLE'
           AND d.reason like 'SINGLE%'		   
           AND d.directive_id=o.directive_id;
		 
	    IF l_spd2 > 0 THEN
		 wa(td(a(l_spd2,'Ustcmd'||i.object_id)));
		ELSE
		 wa(td(NBSP));
		END IF;
	  END IF;
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) SELECT COUNT(*) performed in Table as per tool parameter "count_star_threshold" with current value of '||s_count_star_threshold||'.'));
    wa('<br>');
    wa(font('(2) CBO Statistics.'));
    wa('<br>');
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    FOR i IN (SELECT *
                FROM sqlt$_dba_all_tables_v
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     table_name,
                     owner)
    LOOP
      wa(h3(i.owner||'.'||i.table_name||' - Table Column', 'tab_cols_'||i.object_id));

      wa('<ul>');
      wa(li(mot('Column Statistics', 'DBA_TAB_COLS', '#tab_cols_cbo_'||i.object_id)));

      IF l_vers > 0 THEN
        SELECT COUNT(*)
          INTO l_vers2
          FROM sqlt$_dba_col_stats_versions v,
               sqlt$_dba_all_table_cols_v c
         WHERE v.statement_id = s_sql_rec.statement_id
           AND v.object_type = 'TABLE'
           AND v.owner = i.owner
           AND v.table_name = i.table_name
           AND v.statement_id = c.statement_id
           AND v.column_name = c.column_name
           AND v.table_name = c.table_name
           AND v.owner = c.owner
           AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
           --AND c.hidden_column = 'NO'
           AND ROWNUM = 1;

        IF l_vers2 > 0 THEN
          wa(li(mot('Column Statistics Versions', 'DBA_COL_STATS_VERSIONS', '#tab_cols_vers_'||i.object_id)));
        ELSE
          wa(li(mot('Column Statistics Versions', 'DBA_COL_STATS_VERSIONS')));
        END IF;
      END IF;

      IF l_usage > 0 THEN
        SELECT COUNT(*)
          INTO l_usage2
          FROM sqlt$_dba_col_usage$
         WHERE statement_id = s_sql_rec.statement_id
           AND owner = i.owner
           AND table_name = i.table_name
           AND ROWNUM = 1;

        IF l_usage2 > 0 THEN
          wa(li(mot('Column Usage', 'COL_USAGE$', '#tab_cols_usage_'||i.object_id)));
        ELSE
          wa(li(mot('Column Usage', 'COL_USAGE$')));
        END IF;
      END IF;

      wa(li(mot('Column Properties', 'DBA_TAB_COLS', '#tab_cols_prop_'||i.object_id)));

      IF l_hgrm > 0 THEN
        SELECT COUNT(*)
          INTO l_hgrm2
          FROM sqlt$_dba_tab_histograms
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner
           AND endpoint_number > 1
           AND ROWNUM = 1;

        IF l_hgrm2 > 0 THEN
          wa(li(mot('Histograms', 'DBA_TAB_HISTOGRAMS', '#tab_col_hgrm_'||i.object_id)));
        ELSE
          wa(li(mot('Histograms', 'DBA_TAB_HISTOGRAMS')));
        END IF;
      END IF;

      IF l_hgrm_vers > 0 THEN
        SELECT COUNT(*)
          INTO l_hgrm_vers2
          FROM sqlt$_dba_histgrm_stats_versn v,
               sqlt$_dba_all_table_cols_v c
         WHERE v.statement_id = s_sql_rec.statement_id
           AND v.object_type = 'TABLE'
           AND v.owner = i.owner
           AND v.table_name = i.table_name
           AND v.statement_id = c.statement_id
           AND v.owner = c.owner
           AND v.table_name = c.table_name
           AND v.column_name = c.column_name
           AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
           --AND c.hidden_column = 'NO'
           AND ROWNUM = 1;

        IF l_hgrm_vers2 > 0 THEN
          wa(li(mot('Histogram Versions', 'DBA_HISTGRM_STATS_VERSN', '#tab_col_hgrm_vers_'||i.object_id)));
        ELSE
          wa(li(mot('Histogram Versions', 'DBA_HISTGRM_STATS_VERSN')));
        END IF;
      END IF;
	  
	  IF l_spd>0 THEN
	    SELECT COUNT( distinct d.directive_id) 
	      INTO l_spd2
          FROM sqlt$_dba_sql_plan_directives d,
          	   sqlt$_dba_sql_plan_dir_objs o
         WHERE d.statement_id = s_sql_rec.statement_id
           AND o.statement_id = s_sql_rec.statement_id
		   AND o.owner =I.owner		   
           AND o.object_name =  I.table_name
           AND o.object_type='TABLE'
           AND d.state='USABLE'
           AND d.reason like 'SINGLE%'		   
           AND d.directive_id=o.directive_id
		   AND ROWNUM=1;
		 
	    IF l_spd2 > 0 THEN
		 wa(li(mot('Single Table Cardinality Misestimate Directives','DBA_SQL_PLAN_DIRECTIVES and DBA_SQL_PLAN_DIR_OBJECTS','#Ustcmd'||i.object_id)));
		ELSE
		 wa(td(NBSP));
		END IF;
	  END IF;

      wa('</ul>');
      wa(go_to_sec('Table Columns', 'tab_cols'));
      wa(go_to_sec('Tables', 'tab_sum'));
      wa(go_to_top);

      tab_cols_cbo_sec(i.table_name, i.owner, i.object_id);
      IF l_vers > 0 THEN
        tab_cols_vers_sec(i.table_name, i.owner, i.object_id);
      END IF;
      IF l_usage > 0 THEN
        tab_cols_usage_sec(i.table_name, i.owner, i.object_id);
      END IF;
      tab_cols_prop_sec(i.table_name, i.owner, i.object_id);

      -- 150828 New section
	  directives_s_sec (i.table_name,i.owner,i.object_id,'USABLE');
	  directives_s_sec (i.table_name,i.owner,i.object_id,'SUPERSEDED');	  
	  
      wa(go_to_sec('Table Columns', 'tab_cols'));
      wa(go_to_sec('Tables', 'tab_sum'));
      wa(go_to_top);
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_cols_sec: '||SQLERRM);
  END tab_cols_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_col_hgrm_sec
   *
   * ------------------------- */
  PROCEDURE tab_col_hgrm_sec (
    p_table_name  IN VARCHAR2,
    p_owner       IN VARCHAR2,
    p_object_id   IN NUMBER,
    p_column_name IN VARCHAR2,
    p_column_id   IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
    l_smallest_bucket NUMBER;
    col_rec sqlt$_dba_all_table_cols_v%ROWTYPE;
    tab_rec sqlt$_dba_all_tables_v%ROWTYPE;
    l_hgrm_vers NUMBER := 0;

  BEGIN
    write_log('tab_col_hgrm_sec_'||p_object_id||'_'||p_column_name, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||'.'||p_column_name||' - Histogram', 'DBA_TAB_HISTOGRAMS'), 'tab_col_hgrm_'||p_object_id||'_'||p_column_name));

    SELECT *
      INTO col_rec
      FROM sqlt$_dba_all_table_cols_v
     WHERE statement_id = s_sql_rec.statement_id
       AND owner = p_owner
       AND table_name = p_table_name
       AND column_name = p_column_name;

    SELECT *
      INTO tab_rec
      FROM sqlt$_dba_all_tables_v
     WHERE statement_id = s_sql_rec.statement_id
       AND owner = p_owner
       AND table_name = p_table_name;

    IF s_gran_vers = 'HISTOGRAM' THEN
      SELECT COUNT(*)
        INTO l_hgrm_vers
        FROM sqlt$_dba_histgrm_stats_versn
       WHERE statement_id = s_sql_rec.statement_id
         AND object_type = 'TABLE'
         AND owner = p_owner
         AND table_name = p_table_name
         AND column_name = p_column_name
         AND ROWNUM = 1;
    END IF;

    IF col_rec.histogram = 'FREQUENCY' THEN
      l_smallest_bucket := tab_rec.num_rows;
    END IF;

    l_sql := '
SELECT endpoint_number,
       endpoint_value,
       endpoint_actual_value,
       endpoint_estimated_value,
       endpoint_popular_value,
       estimated_cardinality,
       estimated_selectivity
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_histograms
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND owner = '''||p_owner||'''
   AND table_name = '''||p_table_name||'''
   AND column_name = '''||p_column_name||'''
 ORDER BY
       endpoint_number;';

    wa('"'||INITCAP(col_rec.histogram)||'" histogram with '||col_rec.num_buckets||' buckets. Number of rows in this table is '||tab_rec.num_rows||'. Number of nulls in this column is '||col_rec.num_nulls||' and its sample size was '||col_rec.sample_size||'.');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT endpoint_number,
                     endpoint_value,
                     endpoint_actual_value,
                     endpoint_estimated_value,
                     endpoint_popular_value,
                     estimated_cardinality,
                     estimated_selectivity
                FROM sqlt$_dba_tab_histograms
               WHERE statement_id = s_sql_rec.statement_id
                 AND owner = p_owner
                 AND table_name = p_table_name
                 AND column_name = p_column_name
               ORDER BY
                     endpoint_number)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Endpoint Number'));

        IF s_mask_for_values != 'CLEAR' OR tab_rec.dv_censored = 'Y' THEN		-- if DV censored then don't print anyway
          NULL;
        ELSE
          wa(th('Endpoint Value<sup>1</sup>'));
          wa(th('Endpoint Actual Value<sup>1</sup>'));
        END IF;

        wa(th('Estimated Endpoint Value<sup>1</sup>'));

        IF col_rec.histogram = 'HEIGHT BALANCED' THEN
          wa(th('Popular Value<sup>1</sup>'));
        END IF;

        wa(th(moa('Estimated Cardinality', 0))); -- both
        wa(th(moa('Estimated Selectivity', 1))); -- both
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.endpoint_number, 'r'));

    /*  IF tab_rec.dv_censored = 'Y' THEN  -- Data Vault censored value
          wa(td(DVCENS));
          wa(td(DVCENS));
       ELSE */
        IF s_mask_for_values != 'CLEAR' OR tab_rec.dv_censored = 'Y' THEN
          NULL;
        ELSE
          wa(td(i.endpoint_value, 'r'));
          sanitize_and_append('"'||i.endpoint_actual_value||'"');
        END IF;
    /*  END IF; */
     
      -- Estimated Endpoint Value
      IF tab_rec.dv_censored = 'Y' THEN  -- Data Vault censored value
         wa(td(DVCENS));
      ELSE
          sanitize_and_append('"'||i.endpoint_estimated_value||'"');
      END IF;

      IF col_rec.histogram = 'HEIGHT BALANCED' THEN        
        IF tab_rec.dv_censored = 'Y' THEN  -- Data Vault censored value
            wa(td(DVCENS));
        ELSE
          IF i.endpoint_popular_value IS NOT NULL THEN
            sanitize_and_append('"'||i.endpoint_popular_value||'"');
          ELSE
            wa(td(NBSP));
          END IF;
        END IF;
      ELSE -- FREQUENCY
        IF i.estimated_cardinality < l_smallest_bucket THEN
          l_smallest_bucket := i.estimated_cardinality;
        END IF;
      END IF;

      -- cardinality and selectivity
      wa(td(ROUND(i.estimated_cardinality), 'r'));
      wa(td(TO_CHAR(ROUND(i.estimated_selectivity, 6), SELECTIVITY_FORMAT), 'r', 'nowrap'));

      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) The display of values in this column is controlled by tool parameter "s_mask_for_values". Its current value is "'||s_mask_for_values||'".'));

    IF col_rec.histogram = 'HEIGHT BALANCED' AND col_rec.num_buckets > 0 AND col_rec.num_distinct > col_rec.popular_values THEN
      wa('<br>');
      wa(font('Remarks for this "Height Balanced" histogram:'));
      wa('<br>');
      wa(font('a) Popular values are those with at least 2 buckets (gap between its endpoint number and the prior one).'));
      wa('<br>');
      wa(font('b) From the '||col_rec.num_buckets||' buckets in this histogram, '||col_rec.buckets_pop_vals||' correspond to popular values and '||(col_rec.num_buckets - col_rec.buckets_pop_vals)||' to non-popular.'));
      wa('<br>');
      wa(font('c) This column has '||col_rec.num_distinct||' distinct values, '||col_rec.popular_values||' are popular and '||(col_rec.num_distinct - col_rec.popular_values)||' are non-popular.'));
      wa('<br>');
      wa(font('d) Estimated NewDensity would be the fraction of buckets for non-popular values over number of distinct non-popular values ('||(col_rec.num_buckets - col_rec.buckets_pop_vals)||' / '||col_rec.num_buckets||' / '||(col_rec.num_distinct - col_rec.popular_values)||' = '||LOWER(TO_CHAR(col_rec.new_density, SCIENTIFIC_NOTATION))||').'));
      wa('<br>');
      wa(font('e) Column''s OldDensity for non-popular values as per CBO stats is '||LOWER(TO_CHAR(col_rec.density, SCIENTIFIC_NOTATION))||'.'));
      wa('<br>');
    END IF;

    IF col_rec.histogram = 'FREQUENCY' AND col_rec.sample_size > 0 THEN
      wa('<br>');
      wa(font('Remarks for this "Frequency" histogram:'));
      wa('<br>');
      wa(font('a) Estimated cardinality for values not present in histogram is 1/2 the cardinality of the smallest bucket (after fix 5483301).'));
      wa('<br>');
      wa(font('b) Smallest bucket shows an estimated cardinality of '||ROUND(l_smallest_bucket)||' rows, thus for equality predicates on values not in this histogram an estimated cardinality of '||ROUND(l_smallest_bucket / 2)||' rows would be considered.'));
      wa('<br>');
    END IF;

    IF l_hgrm_vers > 0 THEN
      wa(go_to_sec('Histogram Versions', 'tab_col_hgrm_vers_'||p_object_id||'_'||p_column_name));
    END IF;
    wa(go_to_sec('Table Columns', 'tab_cols'));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_col_hgrm_sec_'||p_object_id||'_'||p_column_name||': '||SQLERRM);
  END tab_col_hgrm_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_col_hgrm_sec
   *
   * ------------------------- */
  PROCEDURE tab_col_hgrm_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_hgrm_vers NUMBER := 0;
  BEGIN
    write_log('tab_col_hgrm_sec_'||p_object_id, 'S');
    wa(h3(mot(p_owner||'.'||p_table_name||' - Histograms', 'DBA_TAB_HISTOGRAMS'), 'tab_col_hgrm_'||p_object_id));

    wa('<ul>');
    FOR i IN (SELECT column_name,
                     column_id
                FROM sqlt$_dba_all_table_cols_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND owner = p_owner
                 AND table_name = p_table_name
                 AND histogram <> 'NONE'
               ORDER BY
                     column_name)
    LOOP
      wa(li(a(i.column_name, 'tab_col_hgrm_'||p_object_id||'_'||i.column_name)));
    END LOOP;
    wa('</ul>');

    IF s_gran_vers = 'HISTOGRAM' THEN
      SELECT COUNT(*)
        INTO l_hgrm_vers
        FROM sqlt$_dba_histgrm_stats_versn v,
             sqlt$_dba_all_table_cols_v c
       WHERE v.statement_id = s_sql_rec.statement_id
         AND v.object_type = 'TABLE'
         AND v.owner = p_owner
         AND v.table_name = p_table_name
         AND v.statement_id = c.statement_id
         AND v.owner = c.owner
         AND v.table_name = c.table_name
         AND v.column_name = c.column_name
         AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
         --AND c.hidden_column = 'NO'
         AND ROWNUM = 1;
    END IF;

    IF l_hgrm_vers > 0 THEN
      wa(go_to_sec('Histogram Versions', 'tab_col_hgrm_vers_'||p_object_id));
    END IF;
    wa(go_to_sec('Table Columns', 'tab_cols'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    FOR i IN (SELECT column_name,
                     column_id
                FROM sqlt$_dba_all_table_cols_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND owner = p_owner
                 AND table_name = p_table_name
                 AND histogram <> 'NONE'
               ORDER BY
                     column_name)
    LOOP
      tab_col_hgrm_sec(p_table_name, p_owner, p_object_id, i.column_name, i.column_id);
    END LOOP;
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_col_hgrm_sec_'||p_object_id||': '||SQLERRM);
  END tab_col_hgrm_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private idx_col_hgrm_sec
   *
   * ------------------------- */
  PROCEDURE idx_col_hgrm_sec (
    p_index_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_hgrm_vers NUMBER := 0;
  BEGIN
    write_log('idx_col_hgrm_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_index_name||' - Histograms', 'DBA_TAB_HISTOGRAMS'), 'idx_col_hgrm_'||p_object_id));

    wa('<ul>');
    FOR i IN (SELECT ic.column_position,
                     ic.column_name,
                     c.column_id,
                     t.object_id
                FROM sqlt$_dba_ind_columns ic,
                     sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_all_tables_v t
               WHERE ic.statement_id = s_sql_rec.statement_id
                 AND ic.index_name = p_index_name
                 AND ic.index_owner = p_owner
                 AND ic.statement_id = c.statement_id
                 AND ic.table_name = c.table_name
                 AND ic.table_owner = c.owner
                 AND ic.column_name = c.column_name
                 AND c.histogram <> 'NONE'
                 AND c.statement_id = t.statement_id
                 AND c.table_name = t.table_name
                 AND c.owner = t.owner
               ORDER BY
                     ic.column_position,
                     ic.column_name)
    LOOP
      wa(li(a(i.column_name, 'tab_col_hgrm_'||i.object_id||'_'||i.column_name)));
    END LOOP;
    wa('</ul>');

  EXCEPTION
    WHEN OTHERS THEN
      write_error('idx_col_hgrm_sec_'||p_object_id||': '||SQLERRM);
  END idx_col_hgrm_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_col_hgrm_sec
   *
   * ------------------------- */
  PROCEDURE tab_col_hgrm_sec
  IS
    l_hgrm_vers NUMBER := 0;
  BEGIN
    write_log('tab_col_hgrm_sec');
    wa(h2(mot('Table Column Histograms', 'DBA_TAB_HISTOGRAMS'), 'tab_col_hgrm'));

    wa('<ul>');
    FOR i IN (SELECT t.table_name,
                     t.owner,
                     t.object_id
                FROM sqlt$_dba_all_tables_v t
               WHERE t.statement_id = s_sql_rec.statement_id
                 AND EXISTS (
              SELECT NULL
                FROM sqlt$_dba_all_table_cols_v c
               WHERE t.statement_id = c.statement_id
                 AND t.table_name = c.table_name
                 AND t.owner = c.owner
                 AND c.histogram <> 'NONE' )
               ORDER BY
                     t.table_name,
                     t.owner,
                     t.object_id)
    LOOP
      wa(li(a(i.table_name, 'tab_col_hgrm_'||i.object_id)));
    END LOOP;
    wa('</ul>');

    IF s_gran_vers = 'HISTOGRAM' THEN
      SELECT COUNT(*)
        INTO l_hgrm_vers
        FROM sqlt$_dba_histgrm_stats_versn v,
             sqlt$_dba_all_table_cols_v c
       WHERE v.statement_id = s_sql_rec.statement_id
         AND v.object_type = 'TABLE'
         AND v.statement_id = c.statement_id
         AND v.owner = c.owner
         AND v.table_name = c.table_name
         AND v.column_name = c.column_name
         AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
         --AND c.hidden_column = 'NO'
         AND ROWNUM = 1;
    END IF;

    IF l_hgrm_vers > 0 THEN
      wa(go_to_sec('Histogram Versions', 'tab_col_hgrm_vers'));
    END IF;
    wa(go_to_sec('Table Columns', 'tab_cols'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    FOR i IN (SELECT t.table_name,
                     t.owner,
                     t.object_id
                FROM sqlt$_dba_all_tables_v t
               WHERE t.statement_id = s_sql_rec.statement_id
                 AND EXISTS (
              SELECT NULL
                FROM sqlt$_dba_all_table_cols_v c
               WHERE t.statement_id = c.statement_id
                 AND t.table_name = c.table_name
                 AND t.owner = c.owner
                 AND c.histogram <> 'NONE' )
               ORDER BY
                     t.table_name,
                     t.owner,
                     t.object_id)
    LOOP
      tab_col_hgrm_sec(i.table_name, i.owner, i.object_id);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_col_hgrm_sec: '||SQLERRM);
  END tab_col_hgrm_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_col_hgrm_vers_sec
   *
   * ------------------------- */
  PROCEDURE tab_col_hgrm_vers_sec (
    p_table_name  IN VARCHAR2,
    p_owner       IN VARCHAR2,
    p_object_id   IN NUMBER,
    p_column_name IN VARCHAR2,
    p_column_id   IN NUMBER )
  IS
    l_row_count NUMBER;
    col_rec sqlt$_dba_all_table_cols_v%ROWTYPE;

  BEGIN
    write_log('tab_col_hgrm_vers_sec_'||p_object_id||'_'||p_column_name, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||'.'||p_column_name||' - Histogram Versions', 'DBA_HISTGRM_STATS_VERSN'), 'tab_col_hgrm_vers_'||p_object_id||'_'||p_column_name));

    SELECT *
      INTO col_rec
      FROM sqlt$_dba_all_table_cols_v
     WHERE statement_id = s_sql_rec.statement_id
       AND owner = p_owner
       AND table_name = p_table_name
       AND column_name = p_column_name;

    wa('List of pending, current and historic CBO statistics.');
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT v.*,
                     t.dv_censored
                FROM sqlt$_dba_histgrm_stats_vers_v v,
                     sqlt$_dba_all_tables_v t
               WHERE v.statement_id = s_sql_rec.statement_id
                 AND v.owner = p_owner
                 AND v.table_name = p_table_name
                 AND v.column_name = p_column_name
                 AND v.object_type = 'TABLE'
                 AND v.statement_id = t.statement_id
                 AND v.table_name = t.table_name
                 AND v.owner = t.owner
               ORDER BY
                     column_name,
                     DECODE(version_type,
                     'PENDING', 1,
                     'CURRENT', 2,
                     'HISTORY', 3, 4),
                     save_time DESC,
                     endpoint_number)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Column Name'));
        wa(th('Version Type'));
        wa(th('Save Time'));
        wa(th('Endpoint Number'));
        IF s_mask_for_values != 'CLEAR' OR i.dv_censored = 'Y' THEN  --DV
          NULL;
        ELSE
          wa(th('Endpoint Value<sup>1</sup>'));
          wa(th('Endpoint Actual Value<sup>1</sup>'));
        END IF;
        wa(th('Estimated Endpoint Value<sup>1</sup>'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.column_name, 'l'));
      wa(td(i.version_type, 'l'));
      wa(td(TO_CHAR(i.save_time, TIMESTAMP_TZ_FORMAT), 'c', 'nowrap'));
      wa(td(i.endpoint_number, 'r'));
      IF s_mask_for_values != 'CLEAR' OR i.dv_censored = 'Y' THEN
        NULL;
      ELSE
        wa(td(i.endpoint_value, 'r'));
        sanitize_and_append('"'||i.endpoint_actual_value||'"');
      END IF;
      -- Estimated Endpoint Value
      IF i.dv_censored = 'Y' THEN  -- DV censored value
        wa(td(DVCENS));  
      ELSE
        sanitize_and_append('"'||sqlt$t.compute_enpoint_value(col_rec.data_type, i.endpoint_value, i.endpoint_actual_value)||'"');
      END IF;
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) The display of values in this column is controlled by tool parameter "s_mask_for_values". Its current value is "'||s_mask_for_values||'".'));
    wa('<br>');
    wa(go_to_sec('Histogram', 'tab_col_hgrm_'||p_object_id||'_'||p_column_name));
    wa(go_to_sec('Table Columns', 'tab_cols'));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_col_hgrm_vers_sec_'||p_object_id||'_'||p_column_name||': '||SQLERRM);
  END tab_col_hgrm_vers_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_col_hgrm_vers_sec
   *
   * ------------------------- */
  PROCEDURE tab_col_hgrm_vers_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('tab_col_hgrm_vers_sec_'||p_object_id, 'S');
    wa(h3(mot(p_owner||'.'||p_table_name||' - Histogram Versions', 'DBA_HISTGRM_STATS_VERSN'), 'tab_col_hgrm_vers_'||p_object_id));

    l_sql := '
SELECT DISTINCT
       v.column_name,
       v.column_id
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_histgrm_stats_versn v,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_table_cols_v c
 WHERE v.statement_id = '||s_sql_rec.statement_id||'
   AND v.owner = '''||p_owner||'''
   AND v.table_name = '''||p_table_name||'''
   AND v.object_type = ''TABLE''
   AND v.statement_id = c.statement_id
   AND v.owner = c.owner
   AND v.table_name = c.table_name
   AND v.column_name = c.column_name
   AND (c.in_predicates = ''TRUE'' OR c.in_indexes = ''TRUE'' OR c.in_projection = ''TRUE'')
   --AND c.hidden_column = ''NO''
 ORDER BY
       v.column_name;';

    wa('Restricted list of columns in predicates, indexes or projections.');
    wa('<br>');
    wa('Further restricted up to '||s_rows_table_s||' rows as per tool parameter "r_rows_table_s".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<ul>');

    l_row_count := 0;
    FOR i IN (SELECT DISTINCT
                     v.column_name,
                     v.column_id
                FROM sqlt$_dba_histgrm_stats_versn v,
                     sqlt$_dba_all_table_cols_v c
               WHERE v.statement_id = s_sql_rec.statement_id
                 AND v.owner = p_owner
                 AND v.table_name = p_table_name
                 AND v.object_type = 'TABLE'
                 AND v.statement_id = c.statement_id
                 AND v.owner = c.owner
                 AND v.table_name = c.table_name
                 AND v.column_name = c.column_name
                 AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
                 --AND c.hidden_column = 'NO'
               ORDER BY
                     v.column_name)
    LOOP
      l_row_count := l_row_count + 1;
      wa(li(a(i.column_name, 'tab_col_hgrm_vers_'||p_object_id||'_'||i.column_name)));
      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</ul>');
    wa(go_to_sec('Histogram', 'tab_col_hgrm_'||p_object_id));
    wa(go_to_sec('Table Columns', 'tab_cols'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    l_row_count := 0;
    FOR i IN (SELECT DISTINCT
                     v.column_name,
                     v.column_id
                FROM sqlt$_dba_histgrm_stats_versn v,
                     sqlt$_dba_all_table_cols_v c
               WHERE v.statement_id = s_sql_rec.statement_id
                 AND v.owner = p_owner
                 AND v.table_name = p_table_name
                 AND v.object_type = 'TABLE'
                 AND v.statement_id = c.statement_id
                 AND v.owner = c.owner
                 AND v.table_name = c.table_name
                 AND v.column_name = c.column_name
                 AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
                 --AND c.hidden_column = 'NO'
               ORDER BY
                     v.column_name)
    LOOP
      l_row_count := l_row_count + 1;
      tab_col_hgrm_vers_sec(p_table_name, p_owner, p_object_id, i.column_name, i.column_id);
      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_col_hgrm_vers_sec_'||p_object_id||': '||SQLERRM);
  END tab_col_hgrm_vers_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private idx_col_hgrm_vers_sec
   *
   * ------------------------- */
  PROCEDURE idx_col_hgrm_vers_sec (
    p_index_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
  BEGIN
    write_log('idx_col_hgrm_vers_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_index_name||' - Histogram Versions', 'DBA_HISTGRM_STATS_VERSN'), 'idx_col_hgrm_vers_'||p_object_id));

    wa('<ul>');
    FOR i IN (SELECT DISTINCT
                     ic.column_position,
                     ic.column_name,
                     c.column_id,
                     t.object_id
                FROM sqlt$_dba_ind_columns ic,
                     sqlt$_dba_histgrm_stats_versn c,
                     sqlt$_dba_all_tables_v t
               WHERE ic.statement_id = s_sql_rec.statement_id
                 AND ic.index_name = p_index_name
                 AND ic.index_owner = p_owner
                 AND ic.statement_id = c.statement_id
                 AND ic.table_name = c.table_name
                 AND ic.table_owner = c.owner
                 AND ic.column_name = c.column_name
                 AND c.object_type = 'TABLE'
                 AND c.statement_id = t.statement_id
                 AND c.table_name = t.table_name
                 AND c.owner = t.owner
               ORDER BY
                     ic.column_position,
                     ic.column_name)
    LOOP
      wa(li(a(i.column_name, 'tab_col_hgrm_vers_'||i.object_id||'_'||i.column_name)));
    END LOOP;
    wa('</ul>');

  EXCEPTION
    WHEN OTHERS THEN
      write_error('idx_col_hgrm_vers_sec_'||p_object_id||': '||SQLERRM);
  END idx_col_hgrm_vers_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_col_hgrm_vers_sec
   *
   * ------------------------- */
  PROCEDURE tab_col_hgrm_vers_sec
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('tab_col_hgrm_vers_sec');
    wa(h2(mot('Table Column Histogram Versions', 'DBA_HISTGRM_STATS_VERSN'), 'tab_col_hgrm_vers'));

    l_sql := '
SELECT t.table_name,
       t.owner,
       t.object_id
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_tables_v t
 WHERE t.statement_id = '||s_sql_rec.statement_id||'
   AND EXISTS (
SELECT NULL
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_histgrm_stats_versn v,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_all_table_cols_v c
 WHERE t.statement_id = v.statement_id
   AND t.table_name = v.table_name
   AND t.owner = v.owner
   AND v.statement_id = c.statement_id
   AND v.owner = c.owner
   AND v.table_name = c.table_name
   AND v.column_name = c.column_name
   AND (c.in_predicates = ''TRUE'' OR c.in_indexes = ''TRUE'' OR c.in_projection = ''TRUE'')
   --AND c.hidden_column = ''NO''
   )
 ORDER BY
       t.table_name,
       t.owner,
       t.object_id;';

    wa('Restricted list of columns in predicates, indexes or projections.');
    wa('<br>');
    wa('Further restricted up to '||s_rows_table_s||' rows as per tool parameter "r_rows_table_s".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<ul>');

    l_row_count := 0;
    FOR i IN (SELECT t.table_name,
                     t.owner,
                     t.object_id
                FROM sqlt$_dba_all_tables_v t
               WHERE t.statement_id = s_sql_rec.statement_id
                 AND EXISTS (
              SELECT NULL
                FROM sqlt$_dba_histgrm_stats_versn v,
                     sqlt$_dba_all_table_cols_v c
               WHERE t.statement_id = v.statement_id
                 AND t.table_name = v.table_name
                 AND t.owner = v.owner
                 AND v.statement_id = c.statement_id
                 AND v.owner = c.owner
                 AND v.table_name = c.table_name
                 AND v.column_name = c.column_name
                 AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
                 --AND c.hidden_column = 'NO'
                 )
               ORDER BY
                     t.table_name,
                     t.owner,
                     t.object_id)
    LOOP
      l_row_count := l_row_count + 1;
      wa(li(a(i.table_name, 'tab_col_hgrm_vers_'||i.object_id)));
      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</ul>');
    wa(go_to_sec('Histogram', 'tab_col_hgrm'));
    wa(go_to_sec('Table Columns', 'tab_cols'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    l_row_count := 0;
    FOR i IN (SELECT t.table_name,
                     t.owner,
                     t.object_id
                FROM sqlt$_dba_all_tables_v t
               WHERE t.statement_id = s_sql_rec.statement_id
                 AND EXISTS (
              SELECT NULL
                FROM sqlt$_dba_histgrm_stats_versn v,
                     sqlt$_dba_all_table_cols_v c
               WHERE t.statement_id = v.statement_id
                 AND t.table_name = v.table_name
                 AND t.owner = v.owner
                 AND v.statement_id = c.statement_id
                 AND v.owner = c.owner
                 AND v.table_name = c.table_name
                 AND v.column_name = c.column_name
                 AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
                 --AND c.hidden_column = 'NO'
                 )
               ORDER BY
                     t.table_name,
                     t.owner,
                     t.object_id)
    LOOP
      l_row_count := l_row_count + 1;
      tab_col_hgrm_vers_sec(i.table_name, i.owner, i.object_id);
      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_col_hgrm_vers_sec: '||SQLERRM);
  END tab_col_hgrm_vers_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private ebs_hgrm_sec
   *
   * ------------------------- */
  PROCEDURE ebs_hgrm_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('ebs_hgrm_sec');
    wa(h2(mot('EBS Histograms', 'FND_HISTOGRAM_COLS'), 'ebs_hgrm'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_fnd_histogram_cols
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     application_id,
                     table_name,
                     column_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Application ID'));
        wa(th('Table Name'));
        wa(th('Column Name'));
        wa(th('Histogram Size'));
        wa(th('Creation Date'));
        wa(th('Created by'));
        wa(th('Last Update Date'));
        wa(th('Last Update by'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.application_id));
      wa(td(i.table_name, 'l'));
      wa(td(i.column_name, 'l'));
      wa(td(i.hsize));
      wa(td(TO_CHAR(i.creation_date, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.created_by));
      wa(td(TO_CHAR(i.last_update_date, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.last_updated_by));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Histogram', 'tab_col_hgrm'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('ebs_hgrm_sec: '||SQLERRM);
  END ebs_hgrm_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private table_part_key_sec
   *
   * ------------------------- */
  PROCEDURE table_part_key_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('table_part_key_sec');
    wa(h2(mot('Table Partitioning Columns', 'DBA_PART_KEY_COLUMNS'), 'tab_part_key'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_part_key_columns
               WHERE statement_id = s_sql_rec.statement_id
                 AND object_type = 'TABLE'
               ORDER BY
                     name,
                     owner,
                     column_position)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th(mot('Pos', 'Column Position')));
        wa(th('Column Name'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.column_position));
      wa(td(i.column_name, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Index Partitioning Columns', 'idx_part_key'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('table_part_key_sec: '||SQLERRM);
  END table_part_key_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private table_sum_sec
   *
   * ------------------------- */
  PROCEDURE table_sum_sec
  IS
    l_row_count NUMBER := 0;
    l_ext NUMBER := 0;
    l_vers NUMBER := 0;
    l_mod NUMBER := 0;
    l_cons NUMBER := 0;
    l_part_key NUMBER := 0;
    l_part NUMBER := 0;
    l_cols NUMBER := 0;
    l_hgrm NUMBER := 0;
    l_indexes NUMBER := 0;
    l_index_cols NUMBER := 0;
    l_metadata NUMBER := 0;
    l_ext2 NUMBER := 0;
    l_vers2 NUMBER := 0;
    l_mod2 NUMBER := 0;
    l_cons2 NUMBER := 0;
    l_part_key2 NUMBER := 0;
    l_part2 NUMBER := 0;
    l_cols2 NUMBER := 0;
    l_hgrm2 NUMBER := 0;
    l_indexes2 NUMBER := 0;
    l_index_cols2 NUMBER := 0;
    l_metadata2 NUMBER := 0;
    l_col_group_usage_report NUMBER := 0;	
	l_spd NUMBER :=0;  -- 151020 new
	l_spd2 NUMBER :=0;

  BEGIN
    write_log('table_sum_sec');
    wa(h2(mot('Tables', 'DBA_TABLES'), 'tab_sum'));

    SELECT COUNT(*)
      INTO l_metadata
      FROM sqlt$_metadata
     WHERE statement_id = s_sql_rec.statement_id
       AND transformed = 'N'
       AND object_type = 'TABLE'
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO l_ext
      FROM sqlt$_dba_stat_extensions
     WHERE statement_id = s_sql_rec.statement_id
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO l_vers
      FROM sqlt$_dba_tab_stats_versions
     WHERE statement_id = s_sql_rec.statement_id
       AND object_type = 'TABLE'
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO l_mod
      FROM sqlt$_dba_tab_modifications
     WHERE statement_id = s_sql_rec.statement_id
       AND partition_name IS NULL
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO l_cons
      FROM sqlt$_dba_constraints
     WHERE statement_id = s_sql_rec.statement_id
       AND ROWNUM = 1;

    IF s_gran_segm = 'PARTITION' THEN
      SELECT COUNT(*)
        INTO l_part_key
        FROM sqlt$_dba_part_key_columns
       WHERE statement_id = s_sql_rec.statement_id
         AND object_type = 'TABLE'
         AND ROWNUM = 1;
    END IF;

    IF l_part_key > 0 THEN
      SELECT COUNT(*)
        INTO l_part
        FROM sqlt$_dba_tab_partitions
       WHERE statement_id = s_sql_rec.statement_id
         AND ROWNUM = 1;
    END IF;

    SELECT COUNT(*)
      INTO l_cols
      FROM sqlt$_dba_all_table_cols_v
     WHERE statement_id = s_sql_rec.statement_id
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO l_hgrm
      FROM sqlt$_dba_tab_histograms
     WHERE statement_id = s_sql_rec.statement_id
       AND endpoint_number > 1
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO l_indexes
      FROM sqlt$_dba_indexes
     WHERE statement_id = s_sql_rec.statement_id
       AND ROWNUM = 1;

    IF l_indexes > 0 THEN
      SELECT COUNT(*)
        INTO l_index_cols
        FROM sqlt$_dba_ind_columns
       WHERE statement_id = s_sql_rec.statement_id
         AND ROWNUM = 1;
    END IF;
	
	-- 150120 New
	SELECT COUNT(*)
	  INTO l_spd
	  FROM sqlt$_dba_sql_plan_dir_objs
	 WHERE statement_id = s_sql_rec.statement_id
	   AND ROWNUM = 1;
	
    l_col_group_usage_report := sqlt$a.get_param_n('colgroup_seed_secs'); -- 12.1.04 if colgroup_seed_secs > 0 then we want the report

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT t.*,
                     CASE WHEN num_rows > 0 THEN TO_CHAR(ROUND(sample_size * 100 / num_rows, 1), PERCENT_FORMAT) END percent
                FROM sqlt$_dba_all_tables_v t
               WHERE statement_id = s_sql_rec.statement_id
               ORDER BY
                     table_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Count<sup>1</sup>'));
        wa(th('Num<br>Rows<sup>2</sup>'));
        wa(th('Sample<br>Size<sup>2</sup>'));
        wa(th('Blocks<sup>2</sup>'));
        wa(th('Last<br>Analyzed<sup>2</sup>'));

        wa(th(mot('Table<br>Stats', 'Table Statistics')));

        IF l_vers > 0 THEN
          wa(th(mot('Table<br>Stats<br>Versn', 'Table Statistics Versions')));
        END IF;

        IF l_ext > 0 THEN
          wa(th(mot('Table<br>Stats<br>Exten', 'Table Statistics Extensions')));
        END IF;

        IF l_mod > 0 THEN
          wa(th(mot('Table<br>Modif', 'Table Modifications')));
        END IF;

        wa(th(mot('Table<br>Prop', 'Table Properties')));

        wa(th(mot('Table<br>Phys<br>Prop', 'Table Physical Properties')));

        IF l_cons > 0 THEN
          wa(th(mot('Table<br>Cons', 'Table Constraints')));
        END IF;

        IF l_cols > 0 THEN
          wa(th(mot('Table<br>Cols', 'Table Columns')));
        END IF;

        IF l_index_cols > 0 THEN
          wa(th(mot('Idxed<br>Cols', 'Indexed Columns')));
        END IF;

        IF l_hgrm > 0 THEN
          wa(th(mot('Table<br>Hgrm', 'Table Column Histograms')));
        END IF;

        IF l_part_key > 0 THEN
          wa(th(mot('Part<br>Key<br>Cols', 'Tables Partition Key Columns')));
        END IF;

        IF l_part > 0 THEN
          wa(th(mot('Table<br>Part', 'Table Partitions')));
        END IF;

        IF l_indexes > 0 THEN
          wa(th('Indexes'));
        END IF;

		-- 151020 new
		IF l_spd >0 THEN
		 wa(th(mot('Single Table<br>SQL Plan<br>Directives','Single Table Cardinality Misestimate Directives')));
		END IF;
		
        IF l_metadata > 0 THEN
          wa(th(mot('Table<br>Meta', 'Table Metadata')));
        END IF;
		
        --12.1.04 Column Usage Report
        IF l_col_group_usage_report > 0 THEN
          wa(th(mot('Column<br>Usage<br>Report', 'Column Usage Report')));  
        END IF;

        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.count_star, 'r'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.blocks, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, SHORT_DATE_FORMAT), 'c', 'nowrap'));

      wa(td(a('Stats', 'tab_stats')));

      IF l_vers > 0 THEN
        SELECT COUNT(*)
          INTO l_vers2
          FROM sqlt$_dba_tab_stats_versions_v
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner
           AND object_type = 'TABLE';

        IF l_vers2 > 0 THEN
          --wa(td(a('Versn', 'tab_cbo_vers')));
          wa(td(a(l_vers2, 'tab_cbo_vers')));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_ext > 0 THEN
        SELECT COUNT(*)
          INTO l_ext2
          FROM sqlt$_dba_stat_extensions
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner;

        IF l_ext2 > 0 THEN
          --wa(td(a('Exten', 'tab_cbo_ext')));
          wa(td(a(l_ext2, 'tab_cbo_ext')));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_mod > 0 THEN
        SELECT COUNT(*)
          INTO l_mod2
          FROM sqlt$_dba_tab_modifications
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND table_owner = i.owner
           AND partition_name IS NULL
           AND ROWNUM = 1;

        IF l_mod2 > 0 THEN
          wa(td(a('Modif', 'tab_mod')));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      wa(td(a('Prop', 'tab_prop')));

      wa(td(a('Phys', 'tab_phy_prop')));

      IF l_cons > 0 THEN
        SELECT COUNT(*)
          INTO l_cons2
          FROM sqlt$_dba_constraints
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner;

        IF l_cons2 > 0 THEN
          --wa(td(a('Cons', 'tab_cons_'||i.object_id)));
          wa(td(a(l_cons2, 'tab_cons_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_cols > 0 THEN
        SELECT COUNT(*)
          INTO l_cols2
          FROM sqlt$_dba_all_table_cols_v
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner;

        IF l_cols2 > 0 THEN
          --wa(td(a('Cols', 'tab_cols_'||i.object_id)));
          wa(td(a(l_cols2, 'tab_cols_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_index_cols > 0 THEN
        SELECT COUNT(DISTINCT column_name)
          INTO l_index_cols2
          FROM sqlt$_dba_ind_columns
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND table_owner = i.owner;

        IF l_index_cols2 > 0 THEN
          --wa(td(a('Idxed', 'idxed_cols_'||i.object_id)));
          wa(td(a(l_index_cols2, 'idxed_cols_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_hgrm > 0 THEN
        SELECT COUNT(DISTINCT column_name)
          INTO l_hgrm2
          FROM sqlt$_dba_tab_histograms
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner
           AND endpoint_number > 1;

        IF l_hgrm2 > 0 THEN
          --wa(td(a('Hgrm', 'tab_col_hgrm_'||i.object_id)));
          wa(td(a(l_hgrm2, 'tab_col_hgrm_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_part_key > 0 THEN
        SELECT COUNT(*)
          INTO l_part_key2
          FROM sqlt$_dba_part_key_columns
         WHERE statement_id = s_sql_rec.statement_id
           AND object_type = 'TABLE'
           AND name = i.table_name
           AND owner = i.owner
           AND ROWNUM = 1;

        IF l_part_key2 > 0 THEN
          wa(td(a('PKey', 'tab_part_key')));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_part > 0 THEN
        SELECT COUNT(*)
          INTO l_part2
          FROM sqlt$_dba_tab_partitions
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND table_owner = i.owner;

        IF l_part2 > 0 THEN
          --wa(td(a('Part', 'tab_part_'||i.object_id)));
          wa(td(a(l_part2, 'tab_part_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_indexes > 0 THEN
        SELECT COUNT(*)
          INTO l_indexes2
          FROM sqlt$_dba_indexes
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND table_owner = i.owner;

        IF l_indexes2 > 0 THEN
          --wa(td(a('Indexes', 'idx_sum_'||i.object_id)));
          wa(td(a(l_indexes2, 'idx_sum_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

	  -- 151020 New
	  IF l_spd>0 THEN
	    SELECT COUNT( distinct d.directive_id) 
	      INTO l_spd2
          FROM sqlt$_dba_sql_plan_directives d,
          	   sqlt$_dba_sql_plan_dir_objs o
         WHERE d.statement_id = s_sql_rec.statement_id
           AND o.statement_id = s_sql_rec.statement_id
		   AND o.owner = i.owner		   
           AND o.object_name =  i.table_name
           AND o.object_type='TABLE'
           AND d.state='USABLE'
           AND d.reason like 'SINGLE%'		   
           AND d.directive_id=o.directive_id;
		 
	    IF l_spd2 > 0 THEN
		 wa(td(a(l_spd2,'Ustcmd'||i.object_id)));
		ELSE
		 wa(td(NBSP));
		END IF;
	  END IF;


	   IF l_metadata > 0 THEN
        SELECT COUNT(*)
          INTO l_metadata2
          FROM sqlt$_metadata
         WHERE statement_id = s_sql_rec.statement_id
           AND object_name = i.table_name
           AND owner = i.owner
           AND object_type = 'TABLE'
           AND transformed = 'N'
           AND ROWNUM = 1;

        IF l_metadata2 > 0 AND s_metadata = 'Y' THEN
          wa(td(a('Meta', 'meta_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;	
		
      END IF;
	  
      -- 12.1.04 Column Usage Report
      IF l_col_group_usage_report > 0 THEN
        wa(td(a('ColUsg', 'colusagereport_'||i.object_id)));
      END IF;

      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) SELECT COUNT(*) performed in Table as per tool parameter "count_star_threshold" with current value of '||s_count_star_threshold||'.'));
    wa('<br>');
    wa(font('(2) CBO Statistics.'));
    wa('<br>');
    wa(go_to_sec('Indexed Columns', 'idxed_cols'));
    wa(go_to_sec('Indexes', 'idx_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('table_sum_sec: '||SQLERRM);
  END table_sum_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private ind_stats_sec
   *
   * ------------------------- */
  PROCEDURE ind_stats_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_max_index_selectivity NUMBER;
    l_q1 NUMBER;
    l_q2 NUMBER;
    l_q3 NUMBER;
    l_cluf_quality VARCHAR2(12);
  BEGIN
    write_log('ind_stats_sec_'||p_object_id, 'S');
    wa(h3(mot(p_owner||'.'||p_table_name||' - Index Statistics', 'DBA_IND_STATISTICS and DBA_SEGMENTS'), 'idx_cbo_'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT s.*,
                     CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), PERCENT_FORMAT) END percent,
                     x.in_plan,
                     x.index_type,
                     x.partitioned,
                     x.temporary,
                     x.object_id,
                     x.index_range_scan_cost,
                     x.leaf_estimate_target_size,
                     x.total_segment_blocks,
                     x.dbms_space_alloc_blocks,
                     x.estim_size_if_rebuilt,
                     g.blocks segment_blocks,
                     g.extents,
                     t.num_rows t_num_rows,
                     t.blocks t_blocks,
                     t.full_table_scan_cost
                FROM sqlt$_dba_ind_statistics s,
                     sqlt$_dba_indexes x,
                     sqlt$_dba_segments g,
                     sqlt$_dba_all_tables_v t
               WHERE s.statement_id = s_sql_rec.statement_id
                 AND s.object_type = 'INDEX'
                 AND s.table_name = p_table_name
                 AND s.table_owner = p_owner
                 AND s.statement_id = x.statement_id
                 AND s.owner = x.owner
                 AND s.index_name = x.index_name
                 AND s.table_owner = x.table_owner
                 AND s.table_name = x.table_name
                 AND s.statement_id = g.statement_id(+)
                 AND s.owner = g.owner(+)
                 AND s.index_name = g.segment_name(+)
                 AND 'INDEX' = g.segment_type(+)
                 AND s.statement_id = t.statement_id
                 AND s.table_owner = t.owner
                 AND s.table_name = t.table_name
               ORDER BY
                     x.in_plan DESC,
                     s.index_name,
                     s.owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Plan', 2)));
        wa(th('Index Name'));
        wa(th('Owner'));
        wa(th('Index Type'));
        wa(th(mot('Part', 'Partitioned')));
        wa(th(mot('Temp', 'Temporary')));
        wa(th('Num Rows<sup>1</sup>'));
        wa(th('Sample Size<sup>1</sup>'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Last Analyzed<sup>1</sup>'));
        wa(th('Distinct Keys<sup>1</sup>'));
        wa(th('Blevel<sup>1</sup>'));
        wa(th('Segment Extents'));
        wa(th('Segment Blocks'));
        wa(th('Total Segment Blocks<sup>2</sup>'));
        wa(th('DBMS_SPACE Allocated Blocks<sup>3</sup>'));
        wa(th('Leaf Blocks<sup>1</sup>'));
        wa(th('Leaf Estimate Target Size<sup>4</sup>'));
        wa(th('Avg Leaf Blocks per Key<sup>1</sup>'));
        wa(th('Avg Data Blocks per Key<sup>1</sup>'));
        wa(th('Clustering Factor<sup>1</sup>'));
        wa(th('Global Stats<sup>1</sup>'));
        wa(th('User Stats<sup>1</sup>'));
        wa(th('Stat Type Locked'));
        wa(th('Stale Stats'));
        wa(th('Avg Cached Blocks'));
        wa(th('Avg Cache Hit Ratio'));
        wa(th('Clustering Factor Quality<sup>5</sup>'));
        wa(th('Full Index Scan Cost<sup>6</sup>'));
        wa(th('Max Index Selectivity<sup>7</sup>'));
        wa(th('Estimated Size If Rebuilt<sup>8</sup>'));
        wa('</tr>');
      END IF;

      IF NVL(i.index_range_scan_cost, 0) = 0 OR NVL(i.full_table_scan_cost, 0) = 0 THEN
        l_max_index_selectivity := NULL;
      ELSIF i.index_range_scan_cost < i.full_table_scan_cost THEN
        l_max_index_selectivity := 1;
      ELSE
        l_max_index_selectivity := i.full_table_scan_cost / i.index_range_scan_cost;
      END IF;

      IF i.t_num_rows > i.t_blocks THEN
        l_q2 := (i.t_num_rows + i.t_blocks) / 2;
        l_q1 := (l_q2 + i.t_blocks) / 2;
        l_q3 := (i.t_num_rows + l_q2) / 2;

        IF i.clustering_factor > l_q3 THEN
          l_cluf_quality := 'WORST';
        ELSIF i.clustering_factor > l_q2 THEN
          l_cluf_quality := 'POOR';
        ELSIF i.clustering_factor > l_q1 THEN
          l_cluf_quality := 'GOOD';
        ELSIF i.clustering_factor <= l_q1 THEN
          l_cluf_quality := 'BEST';
        ELSE
          l_cluf_quality := NULL;
        END IF;
      ELSE
        l_q1 := NULL;
        l_q2 := NULL;
        l_q3 := NULL;
        l_cluf_quality := NULL;
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.in_plan));
      wa(td(i.index_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.index_type, 'l', 'nowrap'));
      IF i.partitioned = 'YES' THEN
        wa(td(a(i.partitioned, 'idx_part_'||i.object_id)));
      ELSE
        wa(td(i.partitioned));
      END IF;
      wa(td(i.temporary));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.distinct_keys, 'r'));
      wa(td(i.blevel, 'r'));
      wa(td(i.extents, 'r'));
      wa(td(i.segment_blocks, 'r'));
      wa(td(i.total_segment_blocks, 'r'));
      wa(td(i.dbms_space_alloc_blocks, 'r'));
      wa(td(i.leaf_blocks, 'r'));
      wa(td(i.leaf_estimate_target_size, 'r'));
      wa(td(i.avg_leaf_blocks_per_key, 'r'));
      wa(td(i.avg_data_blocks_per_key, 'r'));
      wa(td(i.clustering_factor, 'r'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa(td(i.stattype_locked));
      wa(td(i.stale_stats));
      wa(td(i.avg_cached_blocks, 'r'));
      wa(td(i.avg_cache_hit_ratio, 'r'));
      wa(td(l_cluf_quality, 'l'));
      wa(td(i.index_range_scan_cost, 'r'));
      wa(td(TO_CHAR(ROUND(l_max_index_selectivity, 6), SELECTIVITY_FORMAT), 'r', 'nowrap'));
      wa(td(i.estim_size_if_rebuilt, 'r'));
      wa('</tr>');
    END LOOP;

    wa('</table>');
    wa(font('(1) CBO Statistics.'));
    wa('<br>');
    wa(font('(2) It considers the blocks from all partitions (if the index is partitioned).'));
    wa('<br>');
    wa(font('(3) This is the estimated size of the index if it were rebuilt, as computed by DBMS_SPACE.CREATE_INDEX_COST.'));
    wa('<br>');
    wa(font('(4) Estimated leaf blocks with a 90% index efficiency. Only evaluated for non-partitioned normal indexes with more than 10000 leaf blocks.'));
    wa('<br>');
    wa(font('(5) BEST:less than '||ROUND(l_q1)||'. GOOD:between '||ROUND(l_q1)||' and '||ROUND(l_q2)||'. POOR:between '||ROUND(l_q2)||' and '||ROUND(l_q3)||'. WORST:greater than '||ROUND(l_q3)||'.'));
    wa('<br>');
    wa(font('(6) It assumes default CBO environment, including optimizer_index_cost_adj=100 and optimizer_index_caching=0 among others.'));
    wa('<br>');
    wa(font('(7) Index Selectivity where Full Index Scan Cost meets Full Table Scan Cost. A value of 0.02 means that if selecting 2% of the rows or less, an index scan is cheaper than a FTS.'));
    wa('<br>');
    wa(font('(8) Index Size if it were to be rebuilt, the estimation comes from EXPLAIN PLAN FOR of the CREATE INDEX command so it''s dependent on good statistics.'));
    wa('<br>');
    wa(go_to_sec('Index Statistics Versions', 'idx_cbo_vers_'||p_object_id));
    wa(go_to_sec('Indexes', 'idx_sum_'||p_object_id));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('ind_stats_sec_'||p_object_id||': '||SQLERRM);
  END ind_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private ind_stats_vers_sec
   *
   * ------------------------- */
  PROCEDURE ind_stats_vers_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('ind_stats_vers_sec_'||p_object_id, 'S');
    wa(h3(mot(p_owner||'.'||p_table_name||' - Index Statistics Versions', 'DBA_IND_STATS_VERSIONS'), 'idx_cbo_vers_'||p_object_id));

    l_sql := '
SELECT x.in_plan,
       v.index_name,
       v.owner,
       v.version_type,
       v.save_time,
       v.last_analyzed,
       v.num_rows,
       v.sample_size,
       CASE WHEN v.num_rows > 0 THEN ROUND(v.sample_size * 100 / v.num_rows, 1) END percent,
       v.distinct_keys,
       v.blevel,
       v.leaf_blocks,
       v.avg_leaf_blocks_per_key,
       v.avg_data_blocks_per_key,
       v.clustering_factor,
       v.global_stats,
       v.user_stats
  FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_ind_stats_versions_v v,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_indexes x
 WHERE v.statement_id = '||s_sql_rec.statement_id||'
   AND v.object_type = ''INDEX''
   AND v.table_name = '''||p_table_name||'''
   AND v.table_owner = '''||p_owner||'''
   AND v.statement_id = x.statement_id
   AND v.owner = x.owner
   AND v.index_name = x.index_name
   AND v.table_owner = x.table_owner
   AND v.table_name = x.table_name
 ORDER BY
       x.in_plan DESC,
       v.index_name,
       v.owner,
       DECODE(v.version_type,
       ''PENDING'', 1,
       ''CURRENT'', 2,
       ''HISTORY'', 3, 4),
       v.save_time DESC;';

    wa('List of pending, current and historic CBO statistics, restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT x.in_plan,
                     v.index_name,
                     v.owner,
                     v.version_type,
                     v.save_time,
                     v.last_analyzed,
                     v.num_rows,
                     v.sample_size,
                     CASE WHEN v.num_rows > 0 THEN TO_CHAR(ROUND(v.sample_size * 100 / v.num_rows, 1), PERCENT_FORMAT) END percent,
                     v.distinct_keys,
                     v.blevel,
                     v.leaf_blocks,
                     v.avg_leaf_blocks_per_key,
                     v.avg_data_blocks_per_key,
                     v.clustering_factor,
                     v.global_stats,
                     v.user_stats
                FROM sqlt$_dba_ind_stats_versions_v v,
                     sqlt$_dba_indexes x
               WHERE v.statement_id = s_sql_rec.statement_id
                 AND v.object_type = 'INDEX'
                 AND v.table_name = p_table_name
                 AND v.table_owner = p_owner
                 AND v.statement_id = x.statement_id
                 AND v.owner = x.owner
                 AND v.index_name = x.index_name
                 AND v.table_owner = x.table_owner
                 AND v.table_name = x.table_name
               ORDER BY
                     x.in_plan DESC,
                     v.index_name,
                     v.owner,
                     DECODE(v.version_type,
                     'PENDING', 1,
                     'CURRENT', 2,
                     'HISTORY', 3, 4),
                     v.save_time DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Plan', 2)));
        wa(th('Index Name'));
        wa(th('Owner'));
        wa(th('Version Type'));
        wa(th('Save Time'));
        wa(th('Last Analyzed'));
        wa(th('Num Rows'));
        wa(th('Sample Size'));
        wa(th(mot('Perc', 'Percent (%)')));
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
      wa(td(l_row_count, 'rt'));
      wa(td(i.in_plan));
      wa(td(i.index_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.version_type, 'l'));
      wa(td(TO_CHAR(i.save_time, TIMESTAMP_TZ_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(i.distinct_keys, 'r'));
      wa(td(i.blevel, 'r'));
      wa(td(i.leaf_blocks, 'r'));
      wa(td(i.avg_leaf_blocks_per_key, 'r'));
      wa(td(i.avg_data_blocks_per_key, 'r'));
      wa(td(i.clustering_factor, 'r'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;

    wa('</table>');
    wa(go_to_sec('Index Statistics', 'idx_cbo_'||p_object_id));
    wa(go_to_sec('Indexes', 'idx_sum_'||p_object_id));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('ind_stats_vers_sec_'||p_object_id||': '||SQLERRM);
  END ind_stats_vers_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private ind_prop_sec
   *
   * ------------------------- */
  PROCEDURE ind_prop_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('ind_prop_sec_'||p_object_id, 'S');
    wa(h3(mot(p_owner||'.'||p_table_name||' - Index Properties', 'DBA_INDEXES'), 'idx_prop_'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_indexes
               WHERE statement_id = s_sql_rec.statement_id
                 AND table_name = p_table_name
                 AND table_owner = p_owner
               ORDER BY
                     in_plan DESC,
                     index_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Plan', 2)));
        wa(th('Index Name'));
        wa(th('Owner'));
        wa(th('Index Type'));
        wa(th('Uniqueness'));
        wa(th('Table Type'));
        wa(th(mot('Part', 'Partitioned')));
        wa(th('Degree'));
        wa(th('Instances'));
        wa(th(mot('Temp', 'Temporary')));
        wa(th('Duration'));
        wa(th('Incl Col'));
        wa(th('Pct Direct Access'));
        wa(th('IOT Redundant PKey Elim'));
        wa(th('Join Index'));
        wa(th('Secondary'));
        wa(th('Domain Index Type Owner'));
        wa(th('Domain Index Type Name'));
        wa(th('Domain Index Params'));
        wa(th('Domain Index Status'));
        wa(th('Domain Index Oper Status'));
        wa(th('Domain Index Mgment'));
        wa(th('Function Based Index Status'));
        wa(th('Generated'));
        wa(th('Visibility'));
        wa(th('Status'));
        wa(th('Dropped'));
        wa(th('Segment Created'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.in_plan));
      wa(td(i.index_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.index_type, 'l', 'nowrap'));
      wa(td(i.uniqueness, 'l'));
      wa(td(i.table_type, 'l'));
      IF i.partitioned = 'YES' THEN
        wa(td(a(i.partitioned, 'idx_part_'||i.object_id)));
      ELSE
        wa(td(i.partitioned));
      END IF;
      wa(td(i.degree));
      wa(td(i.instances));
      wa(td(i.temporary));
      wa(td(i.duration));
      wa(td(i.include_column));
      wa(td(i.pct_direct_access, 'r'));
      wa(td(i.iot_redundant_pkey_elim));
      wa(td(i.join_index));
      wa(td(i.secondary));
      wa(td(i.ityp_owner));
      wa(td(i.ityp_name));
      wa(td(i.parameters));
      wa(td(i.domidx_status));
      wa(td(i.domidx_opstatus));
      wa(td(i.domidx_management));
      wa(td(i.funcidx_status));
      wa(td(i.generated));
      wa(td(i.visibility));
      wa(td(i.status));
      wa(td(i.dropped));
      wa(td(i.segment_created));
      wa('</tr>');
    END LOOP;

    wa('</table>');
    wa(go_to_sec('Indexes', 'idx_sum_'||p_object_id));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('ind_prop_sec_'||p_object_id||': '||SQLERRM);
  END ind_prop_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private ind_phy_prop_sec
   *
   * ------------------------- */
  PROCEDURE ind_phy_prop_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('ind_phy_prop_sec_'||p_object_id, 'S');
    wa(h3(mot(p_owner||'.'||p_table_name||' - Index Physical Properties', 'DBA_INDEXES'), 'idx_phy_prop_'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_indexes
               WHERE statement_id = s_sql_rec.statement_id
                 AND table_name = p_table_name
                 AND table_owner = p_owner
               ORDER BY
                     in_plan DESC,
                     index_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Plan', 2)));
        wa(th('Index Name'));
        wa(th('Owner'));
        wa(th('Index Type'));
        wa(th(mot('Part', 'Partitioned')));
        wa(th(mot('Temp', 'Temporary')));
        wa(th('Pct Free'));
        wa(th('Ini Trans'));
        wa(th('Max Trans'));
        wa(th('Initial Extent'));
        wa(th('Next Extent'));
        wa(th('Min Extents'));
        wa(th('Max Extents'));
        wa(th('Pct Increase'));
        wa(th('Pct Threshold'));
        wa(th('Free Lists'));
        wa(th('Free List Groups'));
        wa(th('Logging'));
        wa(th('Buffer Pool'));
        wa(th('Flash Cache'));
        wa(th('Cell Flash Cache'));
        wa(th('TableSpace Name'));
        wa(th('Compression'));
        wa(th('Prefix Length'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.in_plan));
      wa(td(i.index_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.index_type, 'l', 'nowrap'));
      IF i.partitioned = 'YES' THEN
        wa(td(a(i.partitioned, 'idx_part_'||i.object_id)));
      ELSE
        wa(td(i.partitioned));
      END IF;
      wa(td(i.temporary));
      wa(td(i.pct_free, 'r'));
      wa(td(i.ini_trans, 'r'));
      wa(td(i.max_trans, 'r'));
      wa(td(i.initial_extent, 'r'));
      wa(td(i.next_extent, 'r'));
      wa(td(i.min_extents, 'r'));
      wa(td(i.max_extents, 'r'));
      wa(td(i.pct_increase, 'r'));
      wa(td(i.pct_threshold, 'r'));
      wa(td(i.freelists, 'r'));
      wa(td(i.freelist_groups, 'r'));
      wa(td(i.logging));
      wa(td(i.buffer_pool));
      wa(td(i.flash_cache));
      wa(td(i.cell_flash_cache));
      wa(td(i.tablespace_name, 'l'));
      wa(td(i.compression));
      wa(td(i.prefix_length));
      wa('</tr>');
    END LOOP;

    wa('</table>');
    wa(go_to_sec('Indexes', 'idx_sum_'||p_object_id));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('ind_phy_prop_sec_'||p_object_id||': '||SQLERRM);
  END ind_phy_prop_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private ind_part_key_sec
   *
   * ------------------------- */
  PROCEDURE ind_part_key_sec
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('ind_part_key_sec');
    wa(h3(mot('Index Partitioning Columns', 'DBA_PART_KEY_COLUMNS'), 'idx_part_key'));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT p.*,
                     x.table_owner,
                     x.table_name
                FROM sqlt$_dba_part_key_columns p,
                     sqlt$_dba_indexes x
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.object_type = 'INDEX'
                 AND p.statement_id = x.statement_id
                 AND p.owner = x.owner
                 AND p.name = x.index_name
               ORDER BY
                     x.table_name,
                     x.table_owner,
                     p.name,
                     p.owner,
                     p.column_position)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Table Owner'));
        wa(th('Index Name'));
        wa(th('Index Owner'));
        wa(th(mot('Pos', 'Column Position')));
        wa(th('Column Name'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.table_owner, 'l'));
      wa(td(i.name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.column_position));
      wa(td(i.column_name, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(go_to_sec('Table Partitioning Columns', 'tab_part_key'));
    wa(go_to_sec('Indexes', 'idx_sum'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('ind_part_key_sec: '||SQLERRM);
  END ind_part_key_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private ind_cols_sec
   *
   * ------------------------- */
  PROCEDURE ind_cols_sec (
    p_index_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_vers      NUMBER;
    l_usage     NUMBER;
    l_hgrm      NUMBER;
    l_hgrm_vers NUMBER;
    l_part       NUMBER;
    l_metadata   NUMBER;

  BEGIN
    write_log('ind_cols_sec_'||p_object_id, 'S');
    wa(h3(mot(p_owner||'.'||p_index_name||' - Index Columns', 'DBA_IND_COLUMNS'), 'idx_cols_'||p_object_id));

    sqlt$a.ind_cols_sec (
      p_statement_id => s_sql_rec.statement_id,
      p_index_name   => p_index_name,
      p_owner        => p_owner,
      x_vers         => l_vers,
      x_usage        => l_usage,
      x_hgrm         => l_hgrm,
      x_hgrm_vers    => l_hgrm_vers,
      x_part         => l_part,
      x_metadata     => l_metadata );

    wa('<ul>');
    wa(li(mot('Column Statistics', 'DBA_TAB_COLS', '#idx_cols_cbo_'||p_object_id)));

    IF l_vers > 0 THEN
      wa(li(mot('Column Statistics Versions', 'DBA_COL_STATS_VERSIONS', '#idx_cols_vers_'||p_object_id)));
    ELSIF s_gran_vers IN ('COLUMN', 'HISTOGRAM') THEN
      wa(li(mot('Column Statistics Versions', 'DBA_COL_STATS_VERSIONS')));
    END IF;

    IF l_usage > 0 THEN
      wa(li(mot('Column Usage', 'COL_USAGE$', '#idx_cols_usage_'||p_object_id)));
    ELSE
      wa(li(mot('Column Usage', 'COL_USAGE$')));
    END IF;

    wa(li(mot('Column Properties', 'DBA_TAB_COLS', '#idx_cols_prop_'||p_object_id)));

    IF l_hgrm > 0 THEN
      wa(li(mot('Histograms', 'DBA_TAB_HISTOGRAMS', '#idx_col_hgrm_'||p_object_id)));
    ELSE
      wa(li(mot('Histograms', 'DBA_TAB_HISTOGRAMS')));
    END IF;

    IF l_hgrm_vers > 0 THEN
      wa(li(mot('Histogram Versions', 'DBA_HISTGRM_STATS_VERSN', '#idx_col_hgrm_vers_'||p_object_id)));
    ELSIF s_gran_vers = 'HISTOGRAM' THEN
      wa(li(mot('Histogram Versions', 'DBA_HISTGRM_STATS_VERSN')));
    END IF;

    wa('</ul>');
    wa(go_to_sec('Indexes', 'idx_sum'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    idx_cols_cbo_sec(p_index_name, p_owner, p_object_id);
    IF l_vers > 0 THEN
      idx_cols_vers_sec(p_index_name, p_owner, p_object_id);
    END IF;
    IF l_usage > 0 THEN
      idx_cols_usage_sec(p_index_name, p_owner, p_object_id);
    END IF;
    idx_cols_prop_sec(p_index_name, p_owner, p_object_id);
    IF l_hgrm > 0 THEN
      idx_col_hgrm_sec(p_index_name, p_owner, p_object_id);
    END IF;
    IF l_hgrm_vers > 0 THEN
      idx_col_hgrm_vers_sec(p_index_name, p_owner, p_object_id);
    END IF;

    wa(go_to_sec('Indexes', 'idx_sum'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('ind_cols_sec_'||p_object_id||': '||SQLERRM);
  END ind_cols_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private index_sum_sec
   *
   * ------------------------- */
  PROCEDURE index_sum_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_vers NUMBER := 0;
    l_part_key NUMBER := 0;
    l_part NUMBER := 0;
    l_cols NUMBER := 0;
    l_metadata NUMBER := 0;
    l_vers2 NUMBER := 0;
    l_part_key2 NUMBER := 0;
    l_part2 NUMBER := 0;
    l_cols2 NUMBER := 0;
    l_metadata2 NUMBER := 0;
    l_column_names VARCHAR2(32767);
    l_column_names2 VARCHAR2(32767);

  BEGIN
    write_log('index_sum_sec_'||p_object_id, 'S');
    wa(h2(mot(p_owner||'.'||p_table_name||' - Indexes', 'DBA_INDEXES'), 'idx_sum_'||p_object_id));

    SELECT COUNT(*)
      INTO l_vers
      FROM sqlt$_dba_ind_stats_versions
     WHERE statement_id = s_sql_rec.statement_id
       AND object_type = 'INDEX'
       AND table_owner = p_owner
       AND table_name = p_table_name
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO l_cols
      FROM sqlt$_dba_ind_columns
     WHERE statement_id = s_sql_rec.statement_id
       AND table_owner = p_owner
       AND table_name = p_table_name
       AND ROWNUM = 1;

    IF s_gran_segm = 'PARTITION' THEN
      SELECT COUNT(*)
        INTO l_part_key
        FROM sqlt$_dba_indexes x,
             sqlt$_dba_part_key_columns p
       WHERE x.statement_id = s_sql_rec.statement_id
         AND x.table_owner = p_owner
         AND x.table_name = p_table_name
         AND x.statement_id = p.statement_id
         AND x.owner = p.owner
         AND x.index_name = p.name
         AND p.object_type = 'INDEX'
         AND ROWNUM = 1;
    END IF;

    IF l_part_key > 0 THEN
      SELECT COUNT(*)
        INTO l_part
        FROM sqlt$_dba_indexes x,
             sqlt$_dba_ind_partitions p
       WHERE x.statement_id = s_sql_rec.statement_id
         AND x.table_owner = p_owner
         AND x.table_name = p_table_name
         AND x.partitioned = 'YES'
         AND x.statement_id = p.statement_id
         AND x.owner = p.index_owner
         AND x.index_name = p.index_name
         AND ROWNUM = 1;
    END IF;

    SELECT COUNT(*)
      INTO l_metadata
      FROM sqlt$_metadata
     WHERE statement_id = s_sql_rec.statement_id
       AND object_type = 'TABLE'
       AND owner = p_owner
       AND object_name = p_table_name
       AND transformed = 'N'
       AND ROWNUM = 1;

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT x.*,
                     CASE WHEN num_rows > 0 THEN TO_CHAR(ROUND(sample_size * 100 / num_rows, 1), PERCENT_FORMAT) END percent
                FROM sqlt$_dba_indexes x
               WHERE statement_id = s_sql_rec.statement_id
                 AND table_owner = p_owner
                 AND table_name = p_table_name
               ORDER BY
                     in_plan DESC,
                     index_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Plan', 2)));
        wa(th('Index Name'));
        wa(th('Owner'));
        wa(th('Index Type'));
        wa(th('Uniqueness'));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Column Name<sup>1</sup>'));
        wa(th('Num<br>Rows<sup>2</sup>'));
        wa(th('Sample<br>Size<sup>2</sup>'));
        --wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Last<br>Analyzed<sup>2</sup>'));

        wa(th(mot('Index<br>Stats', 'Index Statistics')));

        IF l_vers > 0 THEN
          wa(th(mot('Index<br>Stats<br>Versn', 'Index Statistics Versions')));
        END IF;

        wa(th(mot('Index<br>Prop', 'Index Properties')));

        wa(th(mot('Index<br>Phys<br>Prop', 'Index Physical Properties')));

        IF l_cols > 0 THEN
          wa(th(mot('Index<br>Cols', 'Index Columns')));
        END IF;

        IF l_part_key > 0 THEN
          wa(th(mot('Part<br>Key<br>Cols', 'Index Partition Key Columns')));
        END IF;

        IF l_part > 0 THEN
          wa(th(mot('Index<br>Part', 'Index Partitions')));
        END IF;

        IF l_metadata > 0 THEN
          wa(th(mot('Index<br>Meta', 'Index Metadata')));
        END IF;

        wa('</tr>');
      END IF;

      l_column_names := sqlt$a.get_index_column_names(s_sql_rec.statement_id, i.owner, i.index_name, 'YES', '<br>');
      l_column_names2 := sqlt$a.get_index_column_names(s_sql_rec.statement_id, i.owner, i.index_name, 'NO', '<br>');

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.in_plan));
      wa(td(i.index_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.index_type, 'l', 'nowrap'));
      wa(td(i.uniqueness, 'l'));
      wa(td(sqlt$a.get_index_column_ids(s_sql_rec.statement_id, i.owner, i.index_name, '<br>'), 'r'));
      wa(td(l_column_names, 'l'));
      wa(td(l_column_names2, 'l'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      --wa(td(i.percent, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, SHORT_DATE_FORMAT), 'c', 'nowrap'));

      wa(td(a('Stats', 'idx_cbo_'||p_object_id)));

      IF l_vers > 0 THEN
        SELECT COUNT(*)
          INTO l_vers2
          FROM sqlt$_dba_ind_stats_versions_v
         WHERE statement_id = s_sql_rec.statement_id
           AND table_owner = p_owner
           AND table_name = p_table_name
           AND object_type = 'INDEX'
           AND index_name = i.index_name
           AND owner = i.owner;

        IF l_vers2 > 0 THEN
          --wa(td(a('Versn', 'idx_cbo_vers_'||p_object_id)));
          wa(td(a(l_vers2, 'idx_cbo_vers_'||p_object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      wa(td(a('Prop', 'idx_prop_'||p_object_id)));

      wa(td(a('Phys', 'idx_phy_prop_'||p_object_id)));

      IF l_cols > 0 THEN
        SELECT COUNT(*)
          INTO l_cols2
          FROM sqlt$_dba_ind_columns
         WHERE statement_id = s_sql_rec.statement_id
           AND table_owner = p_owner
           AND table_name = p_table_name
           AND index_name = i.index_name
           AND index_owner = i.owner
           AND ROWNUM = 1;

        IF l_cols2 > 0 THEN
          wa(td(a('Cols', 'idx_cols_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_part_key > 0 THEN
        SELECT COUNT(*)
          INTO l_part_key2
          FROM sqlt$_dba_part_key_columns
         WHERE statement_id = s_sql_rec.statement_id
           AND object_type = 'INDEX'
           AND name = i.index_name
           AND owner = i.owner
           AND ROWNUM = 1;

        IF l_part_key2 > 0 THEN
          wa(td(a('PKey', 'idx_part_key')));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_part > 0 THEN
        SELECT COUNT(*)
          INTO l_part2
          FROM sqlt$_dba_indexes x,
               sqlt$_dba_ind_partitions p
         WHERE x.statement_id = s_sql_rec.statement_id
           AND x.partitioned = 'YES'
           AND x.index_name = i.index_name
           AND x.owner = i.owner
           AND x.statement_id = p.statement_id
           AND x.owner = p.index_owner
           AND x.index_name = p.index_name;

        IF l_part2 > 0 THEN
          --wa(td(a('Part', 'idx_part_'||i.object_id)));
          wa(td(a(l_part2, 'idx_part_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_metadata > 0 THEN
        SELECT COUNT(*)
          INTO l_metadata2
          FROM sqlt$_metadata
         WHERE statement_id = s_sql_rec.statement_id
           AND object_name = i.index_name
           AND owner = i.owner
           AND object_type = 'INDEX'
           AND transformed = 'N'
           AND ROWNUM = 1;

        IF l_metadata2 > 0 AND s_metadata = 'Y' THEN
          wa(td(a('Meta', 'meta_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) Column names including system-generated names.'));
    wa('<br>');
    wa(font('(2) CBO Statistics.'));
    wa('<br>');
    wa(go_to_sec('Indexes', 'idx_sum'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('index_sum_sec_'||p_object_id||': '||SQLERRM);
  END index_sum_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private index_sum_sec
   *
   * ------------------------- */
  PROCEDURE index_sum_sec
  IS
    l_row_count NUMBER;
    l_indexes NUMBER := 0;
    l_vers NUMBER := 0;
    l_part_key NUMBER := 0;
    l_cols NUMBER := 0;
    l_indexes2 NUMBER := 0;
    l_vers2 NUMBER := 0;
    l_cols2 NUMBER := 0;

  BEGIN
    write_log('index_sum_sec');
    wa(h2(mot('Indexes', 'DBA_INDEXES'), 'idx_sum'));

    SELECT COUNT(*)
      INTO l_indexes
      FROM sqlt$_dba_indexes
     WHERE statement_id = s_sql_rec.statement_id
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO l_vers
      FROM sqlt$_dba_ind_stats_versions
     WHERE statement_id = s_sql_rec.statement_id
       AND object_type = 'INDEX'
       AND ROWNUM = 1;

    IF s_gran_segm = 'PARTITION' THEN
      SELECT COUNT(*)
        INTO l_part_key
        FROM sqlt$_dba_part_key_columns
       WHERE statement_id = s_sql_rec.statement_id
         AND object_type = 'INDEX'
         AND ROWNUM = 1;
    END IF;

    SELECT COUNT(*)
      INTO l_cols
      FROM sqlt$_dba_ind_columns
     WHERE statement_id = s_sql_rec.statement_id
       AND ROWNUM = 1;

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT t.*,
                     CASE WHEN num_rows > 0 THEN TO_CHAR(ROUND(sample_size * 100 / num_rows, 1), PERCENT_FORMAT) END percent
                FROM sqlt$_dba_all_tables_v t
               WHERE statement_id = s_sql_rec.statement_id
                 AND EXISTS (
              SELECT NULL
                FROM sqlt$_dba_indexes x
               WHERE t.statement_id = x.statement_id
                 AND t.table_name = x.table_name
                 AND t.owner = x.table_owner )
               ORDER BY
                     table_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Count<sup>1</sup>'));
        wa(th('Num<br>Rows<sup>2</sup>'));
        wa(th('Sample<br>Size<sup>2</sup>'));
        wa(th('Blocks<sup>2</sup>'));
        wa(th('Last<br>Analyzed<sup>2</sup>'));

        IF l_indexes > 0 THEN
          wa(th('Indexes'));
        END IF;

        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.count_star, 'r'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.blocks, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, SHORT_DATE_FORMAT), 'c', 'nowrap'));

      IF l_indexes > 0 THEN
        SELECT COUNT(*)
          INTO l_indexes2
          FROM sqlt$_dba_indexes
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND table_owner = i.owner;

        IF l_indexes2 > 0 THEN
          --wa(td(a('Indexes', 'idx_sum_'||i.object_id)));
          wa(td(a(l_indexes2, 'idx_sum_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) SELECT COUNT(*) performed in Table as per tool parameter "count_star_threshold" with current value of '||s_count_star_threshold||'.'));
    wa('<br>');
    wa(font('(2) CBO Statistics.'));
    wa('<br>');
    wa(go_to_sec('Indexed Columns', 'idxed_cols'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    FOR i IN (SELECT *
                FROM sqlt$_dba_all_tables_v t
               WHERE statement_id = s_sql_rec.statement_id
                 AND EXISTS (
              SELECT NULL
                FROM sqlt$_dba_indexes x
               WHERE t.statement_id = x.statement_id
                 AND t.table_name = x.table_name
                 AND t.owner = x.table_owner )
               ORDER BY
                     table_name,
                     owner)
    LOOP
      index_sum_sec(i.table_name, i.owner, i.object_id);
      ind_stats_sec(i.table_name, i.owner, i.object_id);

      IF l_vers > 0 THEN
        SELECT COUNT(*)
          INTO l_vers2
          FROM sqlt$_dba_ind_stats_versions
         WHERE statement_id = s_sql_rec.statement_id
           AND table_owner = i.owner
           AND table_name = i.table_name
           AND object_type = 'INDEX'
           AND ROWNUM = 1;

        IF l_vers2 > 0 THEN
          ind_stats_vers_sec(i.table_name, i.owner, i.object_id);
        END IF;
      END IF;

      ind_prop_sec(i.table_name, i.owner, i.object_id);
      ind_phy_prop_sec(i.table_name, i.owner, i.object_id);

      IF l_cols > 0 THEN
        FOR j IN (SELECT index_name, owner, object_id
                    FROM sqlt$_dba_indexes
                   WHERE statement_id = s_sql_rec.statement_id
                     AND table_owner = i.owner
                     AND table_name = i.table_name
                   ORDER BY
                         in_plan DESC,
                         index_name,
                         owner)
        LOOP
          ind_cols_sec(j.index_name, j.owner, j.object_id);
        END LOOP;
      END IF;
    END LOOP;

    IF l_part_key > 0 THEN
      ind_part_key_sec;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('index_sum_sec: '||SQLERRM);
  END index_sum_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private indexed_columns_s_sec
   *
   * ------------------------- */
  PROCEDURE indexed_columns_s_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('indexed_columns_s_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - Single-Column Indexes', 'DBA_IND_COLUMNS'), 'idxed_cols_s'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT v.leading_column_id,
                     v.column_name,
                     v.descend,
                     v.index_name,
                     v.object_id,
                     v.index_owner,
                     tc.data_default,
                     tc.add_column_default,
                     tc.in_predicates,
                     tc.in_projection,
                     x.index_type,
                     x.uniqueness,
                     x.in_plan,
                     ht.html_table
                FROM sqlt$_dba_indexes_v v,
                     sqlt$_dba_all_table_cols_v tc,
                     sqlt$_dba_indexes x,
                     sqlg$_column_html_table ht
               WHERE v.statement_id = s_sql_rec.statement_id
                 AND v.table_name = p_table_name
                 AND v.table_owner = p_owner
                 AND v.columns = 1
                 AND v.statement_id = tc.statement_id
                 AND v.table_name = tc.table_name
                 AND v.table_owner = tc.owner
                 AND v.column_name = tc.column_name
                 AND v.statement_id = x.statement_id
                 AND v.index_name = x.index_name
                 AND v.index_owner = x.owner
                 AND tc.column_name = ht.column_name(+)
                 AND 'P' = ht.type(+)
               ORDER BY
                     tc.in_predicates DESC,
                     tc.in_projection DESC,
                     v.leading_column_id,
                     v.column_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Default'));
        IF s_sql_rec.rdbms_release >= 11 THEN
          wa(th('Not Null with Default Value'));
        END IF;
        wa(th('Descend'));
        wa(th('Index Name'));
        wa(th('Index Owner'));
        wa(th('Index Type'));
        wa(th('Uniqueness'));
        wa(th(moa('In Plan', 2)));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      IF i.in_predicates = 'TRUE' AND i.html_table IS NOT NULL AND s_in_pred = 'Y' THEN
        wa_td_hide(i.html_table);
      ELSE
        wa(td(i.in_predicates));
      END IF;
      wa(td(i.in_projection));
      wa(td(i.leading_column_id));
      wa(td(i.column_name, 'l'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      IF s_sql_rec.rdbms_release >= 11 THEN
        wa(td(i.add_column_default));
      END IF;
      wa(td(i.descend, 'l'));
      wa(td(a(i.index_name, 'idx_cols_'||i.object_id), 'l'));
      wa(td(i.index_owner, 'l'));
      wa(td(i.index_type, 'l', 'nowrap'));
      wa(td(i.uniqueness, 'l'));
      wa(td(i.in_plan));
      wa('</tr>');
    END LOOP;
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('indexed_columns_s_sec_'||p_object_id||': '||SQLERRM);
  END indexed_columns_s_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private indexed_columns_m_sec
   *
   * ------------------------- */
  PROCEDURE indexed_columns_m_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('indexed_columns_m_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - Multi-Column Indexes', 'DBA_IND_COLUMNS'), 'idxed_cols_m'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT v.*,
                     tc.data_default,
                     tc.add_column_default,
                     ht.html_table
                FROM sqlt$_dba_ind_columns_v v,
                     sqlt$_dba_all_table_cols_v tc,
                     sqlg$_column_html_table ht
               WHERE v.statement_id = s_sql_rec.statement_id
                 AND v.table_name = p_table_name
                 AND v.table_owner = p_owner
                 AND (v.indexes > 1 OR v.max_column_position > 1 OR
                     sqlt$a.in_multi_column_index(v.statement_id, v.table_owner, v.table_name, v.column_name) = 'Y')
                 AND v.statement_id = tc.statement_id
                 AND v.table_name = tc.table_name
                 AND v.table_owner = tc.owner
                 AND v.column_name = tc.column_name
                 AND tc.column_name = ht.column_name(+)
                 AND 'P' = ht.type(+)
               ORDER BY
                     v.in_predicates DESC,
                     v.in_projection DESC,
                     v.column_id NULLS LAST,
                     v.column_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Default'));
        IF s_sql_rec.rdbms_release >= 11 THEN
          wa(th('Not Null with Default Value'));
        END IF;

        FOR j IN (SELECT *
                    FROM sqlt$_dba_indexes_v
                   WHERE statement_id = s_sql_rec.statement_id
                     AND table_name = p_table_name
                     AND table_owner = p_owner
                     AND columns > 1
                   ORDER BY
                         in_predicates DESC,
                         in_projection DESC,
                         leading_column_id,
                         index_name)
        LOOP
          IF j.in_plan = 'TRUE' THEN
            wa(th('In Plan<br>'||a(j.index_name, 'idx_cols_'||j.object_id), 'vt'));
          ELSE
            wa(th(a(j.index_name, 'idx_cols_'||j.object_id), 'vt'));
          END IF;
        END LOOP;
        wa(th('Column Name'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      IF i.in_predicates = 'TRUE' AND i.html_table IS NOT NULL AND s_in_pred = 'Y' THEN
        wa_td_hide(i.html_table);
      ELSE
        wa(td(i.in_predicates));
      END IF;
      wa(td(i.in_projection));
      wa(td(i.column_id));
      wa(td(i.column_name, 'l'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      IF s_sql_rec.rdbms_release >= 11 THEN
        wa(td(i.add_column_default));
      END IF;

      FOR j IN (SELECT *
                  FROM sqlt$_dba_indexes_v
                 WHERE statement_id = s_sql_rec.statement_id
                   AND table_name = p_table_name
                   AND table_owner = p_owner
                   AND columns > 1
                 ORDER BY
                       in_predicates DESC,
                       in_projection DESC,
                       leading_column_id,
                       index_name)
      LOOP
        wa(td(sqlt$a.get_column_position(s_sql_rec.statement_id, j.index_owner, j.index_name, i.column_name)));
      END LOOP;
      wa(td(i.column_name, 'l'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('Index names are displayed vertical in IE.'));
    wa('<br>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('indexed_columns_m_sec_'||p_object_id||': '||SQLERRM);
  END indexed_columns_m_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private indexed_columns_sec
   *
   * ------------------------- */
  PROCEDURE indexed_columns_sec
  IS
    l_row_count NUMBER;
    l_indexes NUMBER := 0;
    l_indexes2 NUMBER := 0;
    l_single NUMBER;
    l_multi NUMBER;

  BEGIN
    write_log('indexed_columns_sec');
    wa(h2(mot('Indexed Columns', 'DBA_IND_COLUMNS'), 'idxed_cols'));

    SELECT COUNT(*)
      INTO l_indexes
      FROM sqlt$_dba_indexes
     WHERE statement_id = s_sql_rec.statement_id
       AND ROWNUM = 1;

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT t.*,
                     CASE WHEN num_rows > 0 THEN TO_CHAR(ROUND(sample_size * 100 / num_rows, 1), PERCENT_FORMAT) END percent
                FROM sqlt$_dba_all_tables_v t
               WHERE statement_id = s_sql_rec.statement_id
                 AND EXISTS (
              SELECT NULL
                FROM sqlt$_dba_indexes x
               WHERE t.statement_id = x.statement_id
                 AND t.table_name = x.table_name
                 AND t.owner = x.table_owner )
               ORDER BY
                     table_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Count<sup>1</sup>'));
        wa(th('Num<br>Rows<sup>2</sup>'));
        wa(th('Sample<br>Size<sup>2</sup>'));
        wa(th('Blocks<sup>2</sup>'));
        wa(th('Last<br>Analyzed<sup>2</sup>'));

        IF l_indexes > 0 THEN
          wa(th('Indexes'));
        END IF;

        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.count_star, 'r'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.blocks, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, SHORT_DATE_FORMAT), 'c', 'nowrap'));

      IF l_indexes > 0 THEN
        SELECT COUNT(*)
          INTO l_indexes2
          FROM sqlt$_dba_indexes
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND table_owner = i.owner;

        IF l_indexes2 > 0 THEN
          --wa(td(a('Idxed', 'idxed_cols_'||i.object_id)));
          wa(td(a(l_indexes2, 'idxed_cols_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) SELECT COUNT(*) performed in Table as per tool parameter "count_star_threshold" with current value of '||s_count_star_threshold||'.'));
    wa('<br>');
    wa(font('(2) CBO Statistics.'));
    wa('<br>');
    wa(go_to_sec('Indexes', 'idx_sum'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    FOR i IN (SELECT *
                FROM sqlt$_dba_all_tables_v t
               WHERE statement_id = s_sql_rec.statement_id
                 AND EXISTS (
              SELECT NULL
                FROM sqlt$_dba_indexes x
               WHERE t.statement_id = x.statement_id
                 AND t.table_name = x.table_name
                 AND t.owner = x.table_owner )
               ORDER BY
                     table_name,
                     owner)
    LOOP
      wa(h3(i.owner||'.'||i.table_name||' - Indexed Columns', 'idxed_cols_'||i.object_id));

      -- find at least one index that has only 1 column
      SELECT COUNT(*)
        INTO l_single
        FROM sqlt$_dba_indexes_v
       WHERE statement_id = i.statement_id
         AND table_owner = i.owner
         AND table_name = i.table_name
         AND columns = 1
         AND ROWNUM = 1;

      -- find at least one index that has more than 1 column
      SELECT COUNT(*)
        INTO l_multi
        FROM sqlt$_dba_indexes_v
       WHERE statement_id = i.statement_id
         AND table_owner = i.owner
         AND table_name = i.table_name
         AND columns > 1
         AND ROWNUM = 1;

      wa('<ul>');
      IF l_single > 0 THEN
        wa(li(a('Single-Column Indexes', 'idxed_cols_s'||i.object_id)));
      ELSE
        wa(li('Single-Column Indexes'));
      END IF;
      IF l_multi > 0 THEN
        wa(li(a('Multi-Column Indexes', 'idxed_cols_m'||i.object_id)));
      ELSE
        wa(li('Multi-Column Indexes'));
      END IF;
      wa('</ul>');

      wa(go_to_sec('Indexed Columns', 'idxed_cols'));
      wa(go_to_sec('Indexes', 'idx_sum_'||i.object_id));
      wa(go_to_sec('Tables', 'tab_sum'));
      wa(go_to_top);

      IF l_single > 0 THEN
        indexed_columns_s_sec(i.table_name, i.owner, i.object_id);
      END IF;
      IF l_multi > 0 THEN
        indexed_columns_m_sec(i.table_name, i.owner, i.object_id);
      END IF;

      wa(go_to_sec('Indexed Columns', 'idxed_cols_'||i.object_id));
      wa(go_to_sec('Indexes', 'idx_sum_'||i.object_id));
      wa(go_to_sec('Tables', 'tab_sum'));
      wa(go_to_top);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('indexed_columns_sec: '||SQLERRM);
  END indexed_columns_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tbl_part_stats_sec
   *
   * ------------------------- */
  PROCEDURE tbl_part_stats_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
    l_sql2 VARCHAR2(32767);
  BEGIN
    write_log('tbl_part_stats_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - Partition Statistics', 'DBA_TAB_STATISTICS and DBA_SEGMENTS'), 'tbl_part_stats_'||p_object_id));

    l_sql := '
/* Partition Statistics */
SELECT s.partition_position,
       s.partition_name,
       p.composite,
       p.subpartition_count,
       s.num_rows,
       s.sample_size,
       CASE WHEN s.num_rows > 0 THEN ROUND(s.sample_size * 100 / s.num_rows, 1) END percent,
       s.last_analyzed,
       g.extents,
       g.blocks segment_blocks,
       s.blocks,
       s.empty_blocks,
       s.avg_space,
       s.avg_row_len,
       s.chain_cnt,
       s.global_stats,
       s.user_stats,
       s.stattype_locked,
       s.stale_stats,
       s.avg_space_freelist_blocks,
       s.num_freelist_blocks,
       s.avg_cached_blocks,
       s.avg_cache_hit_ratio,
       p.compression,
       p.compress_for,
       p.inmemory,
       p.inmemory_priority,
       p.inmemory_distribute,
       p.inmemory_compression,
       p.inmemory_duplicate
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_partitions p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_statistics s,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_segments g
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.table_owner = '''||p_owner||'''
   AND p.table_name = '''||p_table_name||'''
   AND p.statement_id = s.statement_id
   AND p.table_owner = s.owner
   AND p.table_name = s.table_name
   AND p.partition_name = s.partition_name
   AND s.object_type = ''PARTITION''
   AND p.statement_id = g.statement_id(+)
   AND p.table_owner = g.owner(+)
   AND p.table_name = g.segment_name(+)
   AND p.partition_name = g.partition_name(+)
   AND ''TABLE PARTITION'' = g.segment_type(+)
 ORDER BY
       s.partition_position DESC;';

    l_sql2 := '
/* Subpartition Statistics */
SELECT s.partition_position,
       s.subpartition_position,
       s.partition_name,
       s.subpartition_name,
       s.num_rows,
       s.sample_size,
       CASE WHEN s.num_rows > 0 THEN ROUND(s.sample_size * 100 / s.num_rows, 1) END percent,
       s.last_analyzed,
       g.extents,
       g.blocks segment_blocks,
       s.blocks,
       s.empty_blocks,
       s.avg_space,
       s.avg_row_len,
       s.chain_cnt,
       s.global_stats,
       s.user_stats,
       s.stattype_locked,
       s.stale_stats,
       s.avg_space_freelist_blocks,
       s.num_freelist_blocks,
       s.avg_cached_blocks,
       s.avg_cache_hit_ratio
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_subpartitions p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_statistics s,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_segments g
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.table_owner = '''||p_owner||'''
   AND p.table_name = '''||p_table_name||'''
   AND p.statement_id = s.statement_id
   AND p.table_owner = s.owner
   AND p.table_name = s.table_name
   AND p.partition_name = s.partition_name
   AND p.subpartition_name = s.subpartition_name
   AND s.object_type = ''SUBPARTITION''
   AND p.statement_id = g.statement_id(+)
   AND p.table_owner = g.owner(+)
   AND p.table_name = g.segment_name(+)
   AND p.subpartition_name = g.partition_name(+)
   AND ''TABLE SUBPARTITION'' = g.segment_type(+)
 ORDER BY
       s.partition_position DESC,
       s.subpartition_position DESC;';

    wa('List is restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql, l_sql2));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT s.partition_position,
                     s.partition_name,
                     p.composite,
                     p.subpartition_count,
                     s.num_rows,
                     s.sample_size,
                     CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), PERCENT_FORMAT) END percent,
                     s.last_analyzed,
                     g.extents,
                     g.blocks segment_blocks,
                     s.blocks,
                     s.empty_blocks,
                     s.avg_space,
                     s.avg_row_len,
                     s.chain_cnt,
                     s.global_stats,
                     s.user_stats,
                     s.stattype_locked,
                     s.stale_stats,
                     s.avg_space_freelist_blocks,
                     s.num_freelist_blocks,
                     s.avg_cached_blocks,
                     s.avg_cache_hit_ratio,
                     p.compression,
                     p.compress_for,
                     p.inmemory,
                     p.inmemory_priority,
                     p.inmemory_distribute,
                     p.inmemory_compression,
                     p.inmemory_duplicate
                FROM sqlt$_dba_tab_partitions p,
                     sqlt$_dba_tab_statistics s,
                     sqlt$_dba_segments g
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.table_owner = p_owner
                 AND p.table_name = p_table_name
                 AND p.statement_id = s.statement_id
                 AND p.table_owner = s.owner
                 AND p.table_name = s.table_name
                 AND p.partition_name = s.partition_name
                 AND s.object_type = 'PARTITION'
                 AND p.statement_id = g.statement_id(+)
                 AND p.table_owner = g.owner(+)
                 AND p.table_name = g.segment_name(+)
                 AND p.partition_name = g.partition_name(+)
                 AND 'TABLE PARTITION' = g.segment_type(+)
               ORDER BY
                     s.partition_position DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Part Pos'));
        wa(th('Partition Name'));
        wa(th('Composite'));
        wa(th('Sub Part Count'));
        wa(th('Num Rows<sup>1</sup>'));
        wa(th('Sample Size<sup>1</sup>'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Last Analyzed<sup>1</sup>'));
        wa(th('Segment Extents'));
        wa(th('Segment Blocks'));
        wa(th('Blocks<sup>1</sup>'));
        wa(th('Empty Blocks'));
        wa(th('Avg Space'));
        wa(th('Avg Row Len<sup>1</sup>'));
        wa(th('Chain Cnt'));
        wa(th('Global Stats<sup>1</sup>'));
        wa(th('User Stats<sup>1</sup>'));
        wa(th('Stat Type Locked'));
        wa(th('Stale Stats'));
        wa(th('Avg Space Freelist Blocks'));
        wa(th('Num Freelist Blocks'));
        wa(th('Avg Cached Blocks'));
        wa(th('Avg Cache Hit Ratio'));
        wa(th('Compression'));
        wa(th('Compress For'));
        IF sqlt$a.get_rdbms_version >= '12.1.0.2' THEN 
          wa(th('In-Memory'));
          wa(th('In-Memory Priority'));
          wa(th('In-Memory Distribute'));
          wa(th('In-Memory Compression')); 
          wa(th('In-Memory Duplicate'));
        END IF;
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.partition_position));
      wa(td(i.partition_name, 'l'));
      wa(td(i.composite));
      wa(td(i.subpartition_count));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.extents, 'r'));
      wa(td(i.segment_blocks, 'r'));
      wa(td(i.blocks, 'r'));
      wa(td(i.empty_blocks, 'r'));
      wa(td(i.avg_space, 'r'));
      wa(td(i.avg_row_len, 'r'));
      wa(td(i.chain_cnt, 'r'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa(td(i.stattype_locked));
      wa(td(i.stale_stats));
      wa(td(i.avg_space_freelist_blocks, 'r'));
      wa(td(i.num_freelist_blocks, 'r'));
      wa(td(i.avg_cached_blocks, 'r'));
      wa(td(i.avg_cache_hit_ratio, 'r'));
      wa(td(i.compression));
      wa(td(i.compress_for));
      IF sqlt$a.get_rdbms_version >= '12.1.0.2' THEN 
        wa(td(i.inmemory));
        wa(td(i.inmemory_priority));
        wa(td(i.inmemory_distribute));
        wa(td(i.inmemory_compression));
        wa(td(i.inmemory_duplicate));
      END IF;
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) CBO Statistics.'));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tbl_part_stats_sec_'||p_object_id||': '||SQLERRM);
  END tbl_part_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tbl_part_stats_vers_sec
   *
   * ------------------------- */
  PROCEDURE tbl_part_stats_vers_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
    l_sql2 VARCHAR2(32767);
  BEGIN
    write_log('tbl_part_stats_vers_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - Partition Statistics Versions', 'DBA_TAB_STATS_VERSIONS'), 'tbl_part_stats_vers_'||p_object_id));

    l_sql := '
/* Partition Statistics Versions */
SELECT s.partition_position,
       v.partition_name,
       v.version_type,
       v.save_time,
       v.last_analyzed,
       v.num_rows,
       v.sample_size,
       CASE WHEN v.num_rows > 0 THEN ROUND(v.sample_size * 100 / v.num_rows, 1) END percent,
       v.blocks,
       v.avg_row_len
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_partitions p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_statistics s,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_tab_stats_versions_v v
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.table_owner = '''||p_owner||'''
   AND p.table_name = '''||p_table_name||'''
   AND p.statement_id = s.statement_id
   AND p.table_owner = s.owner
   AND p.table_name = s.table_name
   AND p.partition_name = s.partition_name
   AND s.object_type = ''PARTITION''
   AND p.statement_id = v.statement_id
   AND p.table_owner = v.owner
   AND p.table_name = v.table_name
   AND p.partition_name = v.partition_name
   AND v.object_type = ''PARTITION''
 ORDER BY
       s.partition_position DESC,
       DECODE(v.version_type,
       ''PENDING'', 1,
       ''CURRENT'', 2,
       ''HISTORY'', 3, 4),
       v.save_time DESC;';

    l_sql2 := '
/* Subpartition Statistics Versions */
SELECT s.partition_position,
       s.subpartition_position,
       v.partition_name,
       v.subpartition_name,
       v.version_type,
       v.save_time,
       v.last_analyzed,
       v.num_rows,
       v.sample_size,
       CASE WHEN v.num_rows > 0 THEN ROUND(v.sample_size * 100 / v.num_rows, 1) END percent,
       v.blocks,
       v.avg_row_len
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_subpartitions p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_statistics s,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_tab_stats_versions_v v
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.table_owner = '''||p_owner||'''
   AND p.table_name = '''||p_table_name||'''
   AND p.statement_id = s.statement_id
   AND p.table_owner = s.owner
   AND p.table_name = s.table_name
   AND p.partition_name = s.partition_name
   AND p.subpartition_name = s.subpartition_name
   AND s.object_type = ''SUBPARTITION''
   AND p.statement_id = v.statement_id
   AND p.table_owner = v.owner
   AND p.table_name = v.table_name
   AND p.partition_name = v.partition_name
   AND p.subpartition_name = v.subpartition_name
   AND v.object_type = ''SUBPARTITION''
 ORDER BY
       s.partition_position DESC,
       s.subpartition_position DESC,
       DECODE(v.version_type,
       ''PENDING'', 1,
       ''CURRENT'', 2,
       ''HISTORY'', 3, 4),
       v.save_time DESC;';

    wa('List of pending, current and historic CBO statistics, restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql, l_sql2));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT s.partition_position,
                     v.partition_name,
                     v.version_type,
                     v.save_time,
                     v.last_analyzed,
                     v.num_rows,
                     v.sample_size,
                     CASE WHEN v.num_rows > 0 THEN TO_CHAR(ROUND(v.sample_size * 100 / v.num_rows, 1), PERCENT_FORMAT) END percent,
                     v.blocks,
                     v.avg_row_len
                     --v.global_stats,
                     --v.user_stats
                FROM sqlt$_dba_tab_partitions p,
                     sqlt$_dba_tab_statistics s,
                     sqlt$_dba_tab_stats_versions_v v
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.table_owner = p_owner
                 AND p.table_name = p_table_name
                 AND p.statement_id = s.statement_id
                 AND p.table_owner = s.owner
                 AND p.table_name = s.table_name
                 AND p.partition_name = s.partition_name
                 AND s.object_type = 'PARTITION'
                 AND p.statement_id = v.statement_id
                 AND p.table_owner = v.owner
                 AND p.table_name = v.table_name
                 AND p.partition_name = v.partition_name
                 AND v.object_type = 'PARTITION'
               ORDER BY
                     s.partition_position DESC,
                     DECODE(v.version_type,
                     'PENDING', 1,
                     'CURRENT', 2,
                     'HISTORY', 3, 4),
                     v.save_time DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Part Pos'));
        wa(th('Partition Name'));
        wa(th('Version Type'));
        wa(th('Save Time'));
        wa(th('Last Analyzed'));
        wa(th('Num Rows'));
        wa(th('Sample Size'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Blocks'));
        wa(th('Avg Row Len'));
        --wa(th('Global Stats'));
        --wa(th('User Stats'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.partition_position));
      wa(td(i.partition_name, 'l'));
      wa(td(i.version_type, 'l'));
      wa(td(TO_CHAR(i.save_time, TIMESTAMP_TZ_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(i.blocks, 'r'));
      wa(td(i.avg_row_len, 'r'));
      --wa(td(i.global_stats));
      --wa(td(i.user_stats));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tbl_part_stats_vers_sec_'||p_object_id||': '||SQLERRM);
  END tbl_part_stats_vers_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tbl_part_mod_sec
   *
   * ------------------------- */
  PROCEDURE tbl_part_mod_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
  BEGIN
    write_log('tbl_part_mod_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - Partition Modifications', 'DBA_TAB_MODIFICATIONS'), 'part_mod_'||p_object_id));

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT s.partition_position,
                     s.partition_name,
                     s.num_rows,
                     m.inserts,
                     m.updates,
                     m.deletes,
                     (m.inserts + m.updates + m.deletes) total,
                     CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND((m.inserts + m.updates + m.deletes) * 100 / s.num_rows, 1), PERCENT_FORMAT) END percent,
                     s.stale_stats,
                     m.timestamp,
                     m.truncated,
                     m.drop_segments
                FROM sqlt$_dba_tab_partitions p,
                     sqlt$_dba_tab_statistics s,
                     sqlt$_dba_tab_modifications m
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.table_owner = p_owner
                 AND p.table_name = p_table_name
                 AND p.statement_id = s.statement_id
                 AND p.table_owner = s.owner
                 AND p.table_name = s.table_name
                 AND p.partition_name = s.partition_name
                 AND s.object_type = 'PARTITION'
                 AND s.statement_id = m.statement_id(+)
                 AND s.owner = m.table_owner(+)
                 AND s.table_name = m.table_name(+)
                 AND s.partition_name = m.partition_name(+)
                 AND m.subpartition_name IS NULL
               ORDER BY
                     s.partition_position DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Part Pos'));
        wa(th('Partition Name'));
        wa(th('Num Rows'));
        wa(th('Inserts'));
        wa(th('Updates'));
        wa(th('Deletes'));
        wa(th('Total'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Stale Stats'));
        wa(th('Timestamp'));
        wa(th('Truncated'));
        wa(th('Drop Segments'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.partition_position));
      wa(td(i.partition_name, 'l'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.inserts, 'r'));
      wa(td(i.updates, 'r'));
      wa(td(i.deletes, 'r'));
      wa(td(i.total, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(i.stale_stats));
      wa(td(TO_CHAR(i.timestamp, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.truncated));
      wa(td(i.drop_segments, 'r'));
      wa('</tr>');
    END LOOP;
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tbl_part_mod_sec_'||p_object_id||': '||SQLERRM);
  END tbl_part_mod_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tbl_part_cols_sec
   *
   * ------------------------- */
  PROCEDURE tbl_part_cols_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
    l_sql2 VARCHAR2(32767);
  BEGIN
    write_log('tbl_part_cols_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||' - Partition Column Statistics', 'DBA_PART_COL_STATISTICS'), 'part_cols_'||p_object_id));

    l_sql := '
/* Partition Column Statistics */
SELECT ps.partition_position,
       ps.partition_name,
       c.in_predicates,
       c.in_indexes,
       c.in_projection,
       c.column_id,
       c.column_name,
       p.num_rows,
       s.num_nulls,
       s.sample_size,
       CASE
       WHEN p.num_rows > s.num_nulls THEN LEAST(100, ROUND(s.sample_size * 100 / (p.num_rows - s.num_nulls), 1))
       WHEN p.num_rows = s.num_nulls THEN 100
       END percent,
       s.num_distinct,
       s.mutating_ndv,
       s.low_value_cooked,
       s.high_value_cooked,
       s.last_analyzed,
       s.avg_col_len,
       s.density,
       s.num_buckets,
       s.histogram,
       s.mutating_endpoints,
       s.global_stats,
       s.user_stats,
       t.dv_censored
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_partitions p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_statistics ps,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_part_col_statistics s,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_table_cols_v c,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_tables_v t
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.table_owner = '''||p_owner||'''
   AND p.table_name = '''||p_table_name||'''
   AND p.statement_id = ps.statement_id
   AND p.table_owner = ps.owner
   AND p.table_name = ps.table_name
   AND p.partition_name = ps.partition_name
   AND ps.object_type = ''PARTITION''
   AND p.statement_id = s.statement_id
   AND p.table_owner = s.owner
   AND p.table_name = s.table_name
   AND p.partition_name = s.partition_name
   AND s.statement_id = c.statement_id
   AND s.owner = c.owner
   AND s.table_name = c.table_name
   AND s.column_name = c.column_name
   AND t.statement_id = c.statement_id
   AND t.owner = c.owner
   AND t.table_name = c.table_name   
   AND (c.in_predicates = ''TRUE'' OR c.in_indexes = ''TRUE'' OR c.in_projection = ''TRUE'')
   --AND c.hidden_column = ''NO''
 ORDER BY
       ps.partition_position DESC,
       c.in_predicates DESC,
       c.in_indexes DESC,
       c.in_projection DESC,
       c.column_id NULLS LAST,
       c.column_name;';

    l_sql2 := '
/* Subpartition Column Statistics */
SELECT ps.partition_position,
       ps.subpartition_position,
       ps.partition_name,
       ps.subpartition_name,
       c.in_predicates,
       c.in_indexes,
       c.in_projection,
       c.column_id,
       c.column_name,
       c.data_default,
       p.num_rows,
       s.num_nulls,
       s.sample_size,
       CASE
       WHEN p.num_rows > s.num_nulls THEN LEAST(100, ROUND(s.sample_size * 100 / (p.num_rows - s.num_nulls), 1))
       WHEN p.num_rows = s.num_nulls THEN 100
       END percent,
       s.num_distinct,
       s.mutating_ndv,
       s.low_value_cooked,
       s.high_value_cooked,
       s.last_analyzed,
       s.avg_col_len,
       s.density,
       s.num_buckets,
       s.histogram,
       s.mutating_endpoints,
       s.global_stats,
       s.user_stats
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_subpartitions p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_statistics ps,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_subpart_col_stats s,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_table_cols_v c
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.table_owner = '''||p_owner||'''
   AND p.table_name = '''||p_table_name||'''
   AND p.statement_id = ps.statement_id
   AND p.table_owner = ps.owner
   AND p.table_name = ps.table_name
   AND p.partition_name = ps.partition_name
   AND p.subpartition_name = ps.subpartition_name
   AND ps.object_type = ''SUBPARTITION''
   AND p.statement_id = s.statement_id
   AND p.table_owner = s.owner
   AND p.table_name = s.table_name
   AND p.subpartition_name = s.subpartition_name
   AND s.statement_id = c.statement_id
   AND s.owner = c.owner
   AND s.table_name = c.table_name
   AND s.column_name = c.column_name
   AND (c.in_predicates = ''TRUE'' OR c.in_indexes = ''TRUE'' OR c.in_projection = ''TRUE'')
   --AND c.hidden_column = ''NO''
 ORDER BY
       ps.partition_position DESC,
       ps.subpartition_position DESC,
       c.in_predicates DESC,
       c.in_indexes DESC,
       c.in_projection DESC,
       c.column_id NULLS LAST,
       c.column_name;';

    wa('Restricted list of columns in predicates, indexes or projections.');
    wa('<br>');
    wa('Further restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql, l_sql2));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT ps.partition_position,
                     ps.partition_name,
                     c.in_predicates,
                     c.in_indexes,
                     c.in_projection,
                     c.column_id,
                     c.column_name,
                     c.data_default,
                     c.add_column_default,
                     p.num_rows,
                     s.num_nulls,
                     s.sample_size,
                     CASE
                     WHEN p.num_rows > s.num_nulls THEN TO_CHAR(LEAST(100, ROUND(s.sample_size * 100 / (p.num_rows - s.num_nulls), 1)), PERCENT_FORMAT)
                     WHEN p.num_rows = s.num_nulls THEN TO_CHAR(100, PERCENT_FORMAT)
                     END percent,
                     s.num_distinct,
                     s.mutating_ndv,
                     s.low_value_cooked,
                     s.high_value_cooked,
                     s.last_analyzed,
                     s.avg_col_len,
                     s.density,
                     s.num_buckets,
                     s.histogram,
                     s.mutating_endpoints,
                     s.popular_values,
                     s.global_stats,
                     s.user_stats,
                     t.dv_censored
                FROM sqlt$_dba_tab_partitions p,
                     sqlt$_dba_tab_statistics ps,
                     sqlt$_dba_part_col_statistics s,
                     sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_all_tables_v t
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.table_owner = p_owner
                 AND p.table_name = p_table_name
                 AND p.statement_id = ps.statement_id
                 AND p.table_owner = ps.owner
                 AND p.table_name = ps.table_name
                 AND p.partition_name = ps.partition_name
                 AND ps.object_type = 'PARTITION'
                 AND p.statement_id = s.statement_id
                 AND p.table_owner = s.owner
                 AND p.table_name = s.table_name
                 AND p.partition_name = s.partition_name
                 AND s.statement_id = c.statement_id
                 AND s.owner = c.owner
                 AND s.table_name = c.table_name
                 AND s.column_name = c.column_name
                 AND t.statement_id = c.statement_id
                 AND t.owner = c.owner
                 AND t.table_name = c.table_name			 
                 AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
                 --AND c.hidden_column = 'NO'
               ORDER BY
                     ps.partition_position DESC,
                     c.in_predicates DESC,
                     c.in_indexes DESC,
                     c.in_projection DESC,
                     c.column_id NULLS LAST,
                     c.column_name)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Part Pos'));
        wa(th('Partition Name'));
        wa(th(moa('In Pred', 3)));
        wa(th(moa('In Index', 4)));
        wa(th(moa('In Proj', 5)));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Data Default'));
        IF s_sql_rec.rdbms_release >= 11 THEN
          wa(th('Not Null with Default Value'));
        END IF;
        wa(th('Num Rows'));
        wa(th('Num Nulls'));
        wa(th('Sample Size'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Num Distinct'));
        wa(th('Fluctuating NDV Count<sup>1</sup>'));
        wa(th('Low Value<sup>2</sup>'));
        wa(th('High Value<sup>2</sup>'));
        wa(th('Last Analyzed'));
        wa(th('Avg Col Len'));
        wa(th('Density'));
        wa(th('Num Buckets'));
        wa(th('Histogram'));
        wa(th('Fluctuating Endpoint Count<sup>3</sup>'));
        wa(th('Popular Values'));
        wa(th('Global Stats'));
        wa(th('User Stats'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.partition_position));
      wa(td(i.partition_name));
      wa(td(i.in_predicates));
      wa(td(i.in_indexes));
      wa(td(i.in_projection));
      wa(td(i.column_id));
      wa(td(i.column_name, 'l'));
      IF i.data_default IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append(i.data_default);
      END IF;
      IF s_sql_rec.rdbms_release >= 11 THEN
        wa(td(i.add_column_default));
      END IF;
      wa(td(i.num_rows, 'r'));
      wa(td(i.num_nulls, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(i.num_distinct, 'r'));
      wa(td(i.mutating_ndv));
      IF i.dv_censored = 'Y' THEN  -- Data Vault censored value
        wa(td(DVCENS)); 
      ELSIF i.low_value_cooked IS NULL THEN
        wa(td(NBSP));
      ELSE
        sanitize_and_append('"'||i.low_value_cooked||'"');
      END IF;
      IF i.dv_censored = 'Y' THEN  -- Data Vault censored value
        wa(td(DVCENS));
      ELSIF i.high_value_cooked IS NULL THEN
        wa(td(NBSP));		
      ELSE
        sanitize_and_append('"'||i.high_value_cooked||'"');
      END IF;
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.avg_col_len, 'r'));
      wa(td(LOWER(TO_CHAR(i.density, SCIENTIFIC_NOTATION)), 'r', 'nowrap'));
      wa(td(i.num_buckets, 'r'));
      IF i.histogram = 'NONE' THEN
        wa(td(i.histogram, 'l'));
      ELSE
        wa(td(a(i.histogram, 'part_col_hgrm_'||p_object_id||'_'||i.partition_name||'_'||i.column_name), 'c','nowrap'));  --12.1.04
      END IF;
      wa(td(i.mutating_endpoints));
      wa(td(i.popular_values, 'r'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) A value of TRUE means that section "Column Statistics Versions" shows "Number of Distinct Values" changing more than 10% between two consecutive versions.'));
    wa('<br>');
    wa(font('(2) The display of values in this column is controlled by tool parameter "s_mask_for_values". Its current value is "'||s_mask_for_values||'".'));
    wa('<br>');
    wa(font('(3) A value of TRUE means that section "Column Statistics Versions" shows "Endpoint Count" changing more than 10% between two consecutive versions.'));
    --wa('<br>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tbl_part_cols_sec_'||p_object_id||': '||SQLERRM);
  END tbl_part_cols_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tbl_part_col_hgrm_sec
   *
   * ------------------------- */
  PROCEDURE tbl_part_col_hgrm_sec (
    p_table_name     IN VARCHAR2,
    p_owner          IN VARCHAR2,
    p_object_id      IN NUMBER,
    p_partition_name IN VARCHAR2,
    p_column_name    IN VARCHAR2,
    p_column_id      IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
    l_sql2 VARCHAR2(32767);
    l_smallest_bucket NUMBER;
    col_rec sqlt$_dba_part_col_statistics%ROWTYPE;
    tab_rec sqlt$_dba_tab_partitions%ROWTYPE;

  BEGIN
    write_log('tbl_part_col_hgrm_sec_'||p_object_id||'_'||p_partition_name||'_'||p_column_name, 'S');
    wa(h4(mot(p_owner||'.'||p_table_name||'.'||p_partition_name||'.'||p_column_name||' - Partition Histogram', 'DBA_PART_HISTOGRAMS'), 'part_col_hgrm_'||p_object_id||'_'||p_partition_name||'_'||p_column_name));

    SELECT *
      INTO col_rec
      FROM sqlt$_dba_part_col_statistics
     WHERE statement_id = s_sql_rec.statement_id
       AND owner = p_owner
       AND table_name = p_table_name
       AND partition_name = p_partition_name
       AND column_name = p_column_name;

    SELECT *
      INTO tab_rec
      FROM sqlt$_dba_tab_partitions
     WHERE statement_id = s_sql_rec.statement_id
       AND table_owner = p_owner
       AND table_name = p_table_name
       AND partition_name = p_partition_name;

    IF col_rec.histogram = 'FREQUENCY' THEN
      l_smallest_bucket := tab_rec.num_rows;
    END IF;

    l_sql := '
/* Partition Histogram */
SELECT bucket_number,
       endpoint_value,
       endpoint_actual_value,
       endpoint_estimated_value,
       endpoint_popular_value,
       estimated_cardinality,
       estimated_selectivity
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_part_histograms
 WHERE statement_id = '||s_sql_rec.statement_id||'
   AND owner = '''||p_owner||'''
   AND table_name = '''||p_table_name||'''
   AND partition_name = '''||p_partition_name||'''
   AND column_name = '''||p_column_name||'''
 ORDER BY
       bucket_number;';

    l_sql2 := '
/* Subpartition Histogram */
SELECT p.subpartition_position,
       h.subpartition_name,
       h.bucket_number,
       h.endpoint_value,
       h.endpoint_actual_value,
       h.endpoint_estimated_value,
       h.endpoint_popular_value,
       h.estimated_cardinality,
       h.estimated_selectivity
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_subpartitions p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_subpart_histograms h
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.table_owner = '''||p_owner||'''
   AND p.table_name = '''||p_table_name||'''
   AND p.partition_name = '''||p_partition_name||'''
   AND p.statement_id = h.statement_id
   AND p.table_owner = h.owner
   AND p.table_name = h.table_name
   AND p.subpartition_name = h.subpartition_name
   AND h.column_name = '''||p_column_name||'''
 ORDER BY
       p.subpartition_position DESC,
       h.subpartition_name,
       h.bucket_number;';

    wa('"'||INITCAP(col_rec.histogram)||'" histogram with '||col_rec.num_buckets||' buckets. Number of rows in this table is '||tab_rec.num_rows||'. Number of nulls in this column is '||col_rec.num_nulls||' and its sample size was '||col_rec.sample_size||'.');
    wa('<br>');
    wa(hide_sql(l_sql, l_sql2));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT h.bucket_number,
                     h.endpoint_value,
                     h.endpoint_actual_value,
                     h.endpoint_estimated_value,
                     h.endpoint_popular_value,
                     h.estimated_cardinality,
                     h.estimated_selectivity,
                     t.dv_censored
                FROM sqlt$_dba_part_histograms h,
                     sqlt$_dba_all_tables_v t
               WHERE h.statement_id = s_sql_rec.statement_id
                 AND h.owner = p_owner
                 AND h.table_name = p_table_name
                 AND h.partition_name = p_partition_name
                 AND h.column_name = p_column_name
                 AND h.statement_id = t.statement_id
                 AND h.owner = t.owner
                 AND h.table_name = t.table_name
               ORDER BY
                     bucket_number)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Endpoint Number'));

        IF s_mask_for_values != 'CLEAR' OR i.dv_censored = 'Y' THEN
          NULL;
        ELSE
          wa(th('Endpoint Value<sup>1</sup>'));
          wa(th('Endpoint Actual Value<sup>1</sup>'));
        END IF;

        wa(th('Estimated Endpoint Value<sup>1</sup>'));

        IF col_rec.histogram = 'HEIGHT BALANCED' THEN
          wa(th('Popular Value<sup>1</sup>'));
        END IF;

        wa(th(moa('Estimated Cardinality', 0))); -- both
        wa(th(moa('Estimated Selectivity', 1))); -- both
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.bucket_number, 'r'));

      IF s_mask_for_values != 'CLEAR' OR i.dv_censored = 'Y' THEN
        NULL;
      ELSE
        wa(td(i.endpoint_value, 'r'));
        sanitize_and_append('"'||i.endpoint_actual_value||'"');
      END IF;

      -- Estimated Endpoint Value
      IF i.dv_censored = 'Y' THEN  -- DV censored value
        wa(td(DVCENS));  
      ELSE
        sanitize_and_append('"'||i.endpoint_estimated_value||'"');
      END IF;
      
      IF col_rec.histogram = 'HEIGHT BALANCED' THEN       
        IF i.dv_censored = 'Y' THEN  -- Data Vault censored value
          wa(td(DVCENS));
        ELSE
          IF i.endpoint_popular_value IS NOT NULL THEN
            sanitize_and_append('"'||i.endpoint_popular_value||'"');		  
          ELSE
            wa(td(NBSP));
          END IF;
        END IF;
      ELSE -- FREQUENCY
        IF i.estimated_cardinality < l_smallest_bucket THEN
          l_smallest_bucket := i.estimated_cardinality;
        END IF;
      END IF;

      -- cardinality and selectivity
      wa(td(ROUND(i.estimated_cardinality), 'r'));
      wa(td(TO_CHAR(ROUND(i.estimated_selectivity, 6), SELECTIVITY_FORMAT), 'r', 'nowrap'));

      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) The display of values in this column is controlled by tool parameter "s_mask_for_values". Its current value is "'||s_mask_for_values||'".'));

    IF col_rec.histogram = 'HEIGHT BALANCED' AND col_rec.num_buckets > 0 AND col_rec.num_distinct > col_rec.popular_values THEN
      wa('<br>');
      wa(font('Remarks for this "Height Balanced" histogram:'));
      wa('<br>');
      wa(font('a) Popular values are those with at least 2 buckets (gap between its endpoint number and the prior one).'));
      wa('<br>');
      wa(font('b) From the '||col_rec.num_buckets||' buckets in this histogram, '||col_rec.buckets_pop_vals||' correspond to popular values and '||(col_rec.num_buckets - col_rec.buckets_pop_vals)||' to non-popular.'));
      wa('<br>');
      wa(font('c) This column has '||col_rec.num_distinct||' distinct values, '||col_rec.popular_values||' are popular and '||(col_rec.num_distinct - col_rec.popular_values)||' are non-popular.'));
      wa('<br>');
      wa(font('d) Estimated NewDensity would be the fraction of buckets for non-popular values over number of distinct non-popular values ('||(col_rec.num_buckets - col_rec.buckets_pop_vals)||' / '||col_rec.num_buckets||' / '||(col_rec.num_distinct - col_rec.popular_values)||' = '||LOWER(TO_CHAR(col_rec.new_density, SCIENTIFIC_NOTATION))||').'));
      wa('<br>');
      wa(font('e) Column''s OldDensity for non-popular values as per CBO stats is '||LOWER(TO_CHAR(col_rec.density, SCIENTIFIC_NOTATION))||'.'));
      wa('<br>');
    END IF;

    IF col_rec.histogram = 'FREQUENCY' AND col_rec.sample_size > 0 THEN
      wa('<br>');
      wa(font('Remarks for this "Frequency" histogram:'));
      wa('<br>');
      wa(font('a) Estimated cardinality for values not present in histogram is 1/2 the cardinality of the smallest bucket (after fix 5483301).'));
      wa('<br>');
      wa(font('b) Smallest bucket shows an estimated cardinality of '||ROUND(l_smallest_bucket)||' rows, thus for equality predicates on values not in this histogram an estimated cardinality of '||ROUND(l_smallest_bucket / 2)||' rows would be considered.'));
      wa('<br>');
    END IF;

    wa(go_to_sec('Table Partitions', 'tab_part_'||p_object_id));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tbl_part_col_hgrm_sec_'||p_object_id||'_'||p_partition_name||'_'||p_column_name||': '||SQLERRM);
  END tbl_part_col_hgrm_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tbl_part_col_hgrm_sec
   *
   * ------------------------- */
  PROCEDURE tbl_part_col_hgrm_sec (
    p_table_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
    l_sql2 VARCHAR2(32767);
  BEGIN
    write_log('tbl_part_col_hgrm_sec_'||p_object_id, 'S');
    wa(h3(mot(p_owner||'.'||p_table_name||' - Partition Histograms', 'DBA_TAB_HISTOGRAMS'), 'part_col_hgrm_'||p_object_id));

    l_sql := '
/* Partition Histograms */
SELECT ps.partition_name,
       s.column_name,
       c.column_id
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_partitions p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_statistics ps,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_part_col_statistics s,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_table_cols_v c
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.table_owner = '''||p_owner||'''
   AND p.table_name = '''||p_table_name||'''
   AND p.statement_id = ps.statement_id
   AND p.table_owner = ps.owner
   AND p.table_name = ps.table_name
   AND p.partition_name = ps.partition_name
   AND ps.object_type = ''PARTITION''
   AND p.statement_id = s.statement_id
   AND p.table_owner = s.owner
   AND p.table_name = s.table_name
   AND p.partition_name = s.partition_name
   AND s.histogram <> ''NONE''
   AND s.statement_id = c.statement_id
   AND s.owner = c.owner
   AND s.table_name = c.table_name
   AND s.column_name = c.column_name
   AND (c.in_predicates = ''TRUE'' OR c.in_indexes = ''TRUE'' OR c.in_projection = ''TRUE'')
   --AND c.hidden_column = ''NO''
 ORDER BY
       ps.partition_position DESC,
       s.column_name;';

    l_sql2 := '
/* Subartition Histograms */
SELECT ps.partition_name,
       ps.subpartition_name,
       s.column_name,
       c.column_id
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_subpartitions p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_tab_statistics ps,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_subpart_col_stats s,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_all_table_cols_v c
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.table_owner = '''||p_owner||'''
   AND p.table_name = '''||p_table_name||'''
   AND p.statement_id = ps.statement_id
   AND p.table_owner = ps.owner
   AND p.table_name = ps.table_name
   AND p.partition_name = ps.partition_name
   AND p.subpartition_name = ps.subpartition_name
   AND ps.object_type = ''SUBPARTITION''
   AND p.statement_id = s.statement_id
   AND p.table_owner = s.owner
   AND p.table_name = s.table_name
   AND p.subpartition_name = s.subpartition_name
   AND s.histogram <> ''NONE''
   AND s.statement_id = c.statement_id
   AND s.owner = c.owner
   AND s.table_name = c.table_name
   AND s.column_name = c.column_name
   AND (c.in_predicates = ''TRUE'' OR c.in_indexes = ''TRUE'' OR c.in_projection = ''TRUE'')
   --AND c.hidden_column = ''NO''
 ORDER BY
       ps.partition_position DESC,
       s.column_name;';

    wa('Restricted list of columns in predicates, indexes or projections.');
    wa('<br>');
    wa('Further restricted up to '||s_rows_table_s||' rows as per tool parameter "r_rows_table_s".');
    wa('<br>');
    wa(hide_sql(l_sql, l_sql2));
    wa('<ul>');

    l_row_count := 0;
    FOR i IN (SELECT ps.partition_name,
                     s.column_name,
                     c.column_id
                FROM sqlt$_dba_tab_partitions p,
                     sqlt$_dba_tab_statistics ps,
                     sqlt$_dba_part_col_statistics s,
                     sqlt$_dba_all_table_cols_v c
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.table_owner = p_owner
                 AND p.table_name = p_table_name
                 AND p.statement_id = ps.statement_id
                 AND p.table_owner = ps.owner
                 AND p.table_name = ps.table_name
                 AND p.partition_name = ps.partition_name
                 AND ps.object_type = 'PARTITION'
                 AND p.statement_id = s.statement_id
                 AND p.table_owner = s.owner
                 AND p.table_name = s.table_name
                 AND p.partition_name = s.partition_name
                 AND s.histogram <> 'NONE'
                 AND s.statement_id = c.statement_id
                 AND s.owner = c.owner
                 AND s.table_name = c.table_name
                 AND s.column_name = c.column_name
                 AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
                 --AND c.hidden_column = 'NO'
               ORDER BY
                     ps.partition_position DESC,
                     s.column_name)
    LOOP
      l_row_count := l_row_count + 1;
      wa(li(a(i.partition_name||'.'||i.column_name, 'part_col_hgrm_'||p_object_id||'_'||i.partition_name||'_'||i.column_name)));
      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</ul>');

    wa(go_to_sec('Table Partitions', 'tab_part_'||p_object_id));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    l_row_count := 0;
    FOR i IN (SELECT ps.partition_name,
                     s.column_name,
                     c.column_id
                FROM sqlt$_dba_tab_partitions p,
                     sqlt$_dba_tab_statistics ps,
                     sqlt$_dba_part_col_statistics s,
                     sqlt$_dba_all_table_cols_v c
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.table_owner = p_owner
                 AND p.table_name = p_table_name
                 AND p.statement_id = ps.statement_id
                 AND p.table_owner = ps.owner
                 AND p.table_name = ps.table_name
                 AND p.partition_name = ps.partition_name
                 AND ps.object_type = 'PARTITION'
                 AND p.statement_id = s.statement_id
                 AND p.table_owner = s.owner
                 AND p.table_name = s.table_name
                 AND p.partition_name = s.partition_name
                 AND s.histogram <> 'NONE'
                 AND s.statement_id = c.statement_id
                 AND s.owner = c.owner
                 AND s.table_name = c.table_name
                 AND s.column_name = c.column_name
                 AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
                 --AND c.hidden_column = 'NO'
               ORDER BY
                     ps.partition_position DESC,
                     s.column_name)
    LOOP
      l_row_count := l_row_count + 1;
      tbl_part_col_hgrm_sec(p_table_name, p_owner, p_object_id, i.partition_name, i.column_name, i.column_id);
      IF l_row_count = s_rows_table_s THEN
        EXIT;
      END IF;
    END LOOP;
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tbl_part_col_hgrm_sec_'||p_object_id||': '||SQLERRM);
  END tbl_part_col_hgrm_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tab_part_sec
   *
   * ------------------------- */
  PROCEDURE tab_part_sec
  IS
    l_row_count NUMBER := 0;
    l_vers NUMBER := 0;
    l_mod NUMBER := 0;
    l_cols NUMBER := 0;
    l_hgrm NUMBER := 0;
    l_vers2 NUMBER := 0;
    l_mod2 NUMBER := 0;
    l_cols2 NUMBER := 0;
    l_hgrm2 NUMBER := 0;

  BEGIN
    write_log('tab_part_sec');
    wa(h2(mot('Table Partitions', 'DBA_TAB_PARTITIONS'), 'tab_part'));

    SELECT COUNT(*)
      INTO l_vers
      FROM sqlt$_dba_tab_stats_versions
     WHERE statement_id = s_sql_rec.statement_id
       AND object_type = 'PARTITION'
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO l_mod
      FROM sqlt$_dba_tab_modifications
     WHERE statement_id = s_sql_rec.statement_id
       AND partition_name IS NOT NULL
       AND subpartition_name IS NULL
       AND ROWNUM = 1;

    IF s_gran_cols = 'PARTITION' THEN
      SELECT COUNT(*)
        INTO l_cols
        FROM sqlt$_dba_part_col_statistics
       WHERE statement_id = s_sql_rec.statement_id
         AND ROWNUM = 1;
    END IF;

    IF s_gran_hgrm = 'PARTITION' THEN
      SELECT COUNT(*)
        INTO l_hgrm
        FROM sqlt$_dba_part_histograms s,
             sqlt$_dba_all_table_cols_v c
       WHERE s.statement_id = s_sql_rec.statement_id
         AND s.statement_id = c.statement_id
         AND s.owner = c.owner
         AND s.table_name = c.table_name
         AND s.column_name = c.column_name
         AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
         --AND c.hidden_column = 'NO'
         AND ROWNUM = 1;
    END IF;

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT t.*,
                     CASE WHEN num_rows > 0 THEN TO_CHAR(ROUND(sample_size * 100 / num_rows, 1), PERCENT_FORMAT) END percent
                FROM sqlt$_dba_all_tables_v t
               WHERE statement_id = s_sql_rec.statement_id
                 AND partitioned = 'YES'
               ORDER BY
                     table_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Owner'));
        wa(th('Count<sup>1</sup>'));
        wa(th('Num<br>Rows<sup>2</sup>'));
        wa(th('Sample<br>Size<sup>2</sup>'));
        wa(th('Blocks<sup>2</sup>'));
        wa(th('Last<br>Analyzed<sup>2</sup>'));

        wa(th(mot('Part<br>Stats', 'Partition Statistics')));

        IF l_vers > 0 THEN
          wa(th(mot('Part<br>Stats<br>Versn', 'Partition Statistics Versions')));
        END IF;

        IF l_mod > 0 THEN
          wa(th(mot('Part<br>Modif', 'Partition Modifications')));
        END IF;

        IF l_cols > 0 THEN
          wa(th(mot('Cols<br>Stats', 'Partition Column Statistics (restricted to columns in predicates, indexes or projections)')));
        END IF;

        IF l_hgrm > 0 THEN
          wa(th(mot('Part<br>Hgrm', 'Partition Histograms (restricted to columns in predicates, indexes or projections)')));
        END IF;

        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(i.count_star, 'r'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.blocks, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, SHORT_DATE_FORMAT), 'c', 'nowrap'));

      wa(td(a('Stats', 'tbl_part_stats_'||i.object_id)));

      IF l_vers > 0 THEN
        SELECT COUNT(*)
          INTO l_vers2
          FROM sqlt$_dba_tab_stats_versions_v
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner
           AND object_type = 'PARTITION';

        IF l_vers2 > 0 THEN
          --wa(td(a('Versn', 'tbl_part_stats_vers_'||i.object_id)));
          wa(td(a(l_vers2, 'tbl_part_stats_vers_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_mod > 0 THEN
        SELECT COUNT(*)
          INTO l_mod2
          FROM sqlt$_dba_tab_modifications
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND table_owner = i.owner
           AND partition_name IS NOT NULL
           AND subpartition_name IS NULL
           AND ROWNUM = 1;

        IF l_mod2 > 0 THEN
          wa(td(a('Modif', 'part_mod_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_cols > 0 THEN
        SELECT COUNT(DISTINCT column_name)
          INTO l_cols2
          FROM sqlt$_dba_part_col_statistics
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner;

        IF l_cols2 > 0 THEN
          --wa(td(a('Cols', 'part_cols_'||i.object_id)));
          wa(td(a(l_cols2, 'part_cols_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      IF l_hgrm > 0 THEN
        SELECT COUNT(DISTINCT s.column_name)
          INTO l_hgrm2
          FROM sqlt$_dba_part_histograms s,
               sqlt$_dba_all_table_cols_v c
         WHERE s.statement_id = s_sql_rec.statement_id
           AND s.table_name = i.table_name
           AND s.owner = i.owner
           AND s.statement_id = c.statement_id
           AND s.owner = c.owner
           AND s.table_name = c.table_name
           AND s.column_name = c.column_name
           AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE');
           --AND c.hidden_column = 'NO'

        IF l_hgrm2 > 0 THEN
          --wa(td(a('Hgrm', 'part_col_hgrm_'||i.object_id)));
          wa(td(a(l_hgrm2, 'part_col_hgrm_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) SELECT COUNT(*) performed in Table as per tool parameter "count_star_threshold" with current value of '||s_count_star_threshold||'.'));
    wa('<br>');
    wa(font('(2) CBO Statistics.'));
    wa('<br>');
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    FOR i IN (SELECT t.*,
                     CASE WHEN num_rows > 0 THEN TO_CHAR(ROUND(sample_size * 100 / num_rows, 1), PERCENT_FORMAT) END percent
                FROM sqlt$_dba_all_tables_v t
               WHERE statement_id = s_sql_rec.statement_id
                 AND partitioned = 'YES'
               ORDER BY
                     table_name,
                     owner)
    LOOP
      wa(h3(i.owner||'.'||i.table_name||' - Table Partitions', 'tab_part_'||i.object_id));

      wa('<ul>');
      wa(li(mot('Partition Statistics', 'DBA_TAB_STATISTICS', '#tbl_part_stats_'||i.object_id)));

      IF l_vers > 0 THEN
        SELECT COUNT(*)
          INTO l_vers2
          FROM sqlt$_dba_tab_stats_versions
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner
           AND object_type = 'PARTITION'
           AND ROWNUM = 1;

        IF l_vers2 > 0 THEN
          wa(li(mot('Partition Statistics Versions', 'DBA_TAB_STATS_VERSIONS', '#tbl_part_stats_vers_'||i.object_id)));
        ELSE
          wa(li(mot('Partition Statistics Versions', 'DBA_TAB_STATS_VERSIONS')));
        END IF;
      END IF;

      IF l_mod > 0 THEN
        SELECT COUNT(*)
          INTO l_mod2
          FROM sqlt$_dba_tab_modifications
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND table_owner = i.owner
           AND partition_name IS NOT NULL
           AND subpartition_name IS NULL
           AND ROWNUM = 1;

        IF l_mod2 > 0 THEN
          wa(li(mot('Partition Modifications', 'DBA_TAB_MODIFICATIONS', '#part_mod_'||i.object_id)));
        ELSE
          wa(li(mot('Partition Modifications', 'DBA_TAB_MODIFICATIONS')));
        END IF;
      END IF;

      IF l_cols > 0 THEN
        SELECT COUNT(*)
          INTO l_cols2
          FROM sqlt$_dba_part_col_statistics
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner
           AND ROWNUM = 1;

        IF l_cols2 > 0 THEN
          wa(li(mot('Partition Column Statistics', 'DBA_PART_COL_STATISTICS', '#part_cols_'||i.object_id)));
        ELSE
          wa(li(mot('Partition Column Statistics', 'DBA_PART_COL_STATISTICS')));
        END IF;
      END IF;

      IF l_hgrm > 0 THEN
        SELECT COUNT(*)
          INTO l_hgrm2
          FROM sqlt$_dba_part_histograms
         WHERE statement_id = s_sql_rec.statement_id
           AND table_name = i.table_name
           AND owner = i.owner
           AND ROWNUM = 1;

        IF l_hgrm2 > 0 THEN
          wa(li(mot('Partition Histograms', 'DBA_PART_HISTOGRAMS', '#part_col_hgrm_'||i.object_id)));
        ELSE
          wa(li(mot('Partition Histograms', 'DBA_PART_HISTOGRAMS')));
        END IF;
      END IF;

      wa('</ul>');
      wa(go_to_sec('Table Partitions', 'tab_part'));
      wa(go_to_sec('Tables', 'tab_sum'));
      wa(go_to_top);

      tbl_part_stats_sec(i.table_name, i.owner, i.object_id);
      IF l_vers2 > 0 THEN
        tbl_part_stats_vers_sec(i.table_name, i.owner, i.object_id);
      END IF;
      IF l_mod2 > 0 THEN
        tbl_part_mod_sec(i.table_name, i.owner, i.object_id);
      END IF;
      IF l_cols2 > 0 THEN
        tbl_part_cols_sec(i.table_name, i.owner, i.object_id);
      END IF;
      IF l_hgrm2 > 0 THEN
        tbl_part_col_hgrm_sec(i.table_name, i.owner, i.object_id);
      END IF;

      wa(go_to_sec('Table Partitions', 'tab_part'));
      wa(go_to_sec('Tables', 'tab_sum'));
      wa(go_to_top);
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('tab_part_sec: '||SQLERRM);
  END tab_part_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private idx_part_stats_sec
   *
   * ------------------------- */
  PROCEDURE idx_part_stats_sec (
    p_index_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('idx_part_stats_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_index_name||' - Partition Statistics', 'DBA_IND_STATISTICS and DBA_SEGMENTS'), 'idx_part_stats_'||p_object_id));

    l_sql := '
SELECT s.partition_position,
       s.partition_name,
       p.composite,
       p.subpartition_count,
       s.num_rows,
       s.sample_size,
       CASE WHEN s.num_rows > 0 THEN ROUND(s.sample_size * 100 / s.num_rows, 1) END percent,
       s.last_analyzed,
       s.distinct_keys,
       s.blevel,
       g.extents,
       g.blocks segment_blocks,
       s.leaf_blocks,
       s.avg_leaf_blocks_per_key,
       s.avg_data_blocks_per_key,
       s.clustering_factor,
       s.global_stats,
       s.user_stats,
       s.stattype_locked,
       s.stale_stats,
       s.avg_cached_blocks,
       s.avg_cache_hit_ratio,
       p.status
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_ind_partitions p,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_ind_statistics s,
       '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_segments g
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.index_owner = '''||p_owner||'''
   AND p.index_name = '''||p_index_name||'''
   AND p.statement_id = s.statement_id
   AND p.index_owner = s.owner
   AND p.index_name = s.index_name
   AND p.partition_name = s.partition_name
   AND s.object_type = ''PARTITION''
   AND p.statement_id = g.statement_id(+)
   AND p.index_owner = g.owner(+)
   AND p.index_name = g.segment_name(+)
   AND p.partition_name = g.partition_name(+)
   AND ''INDEX PARTITION'' = g.segment_type(+)
 ORDER BY
       s.partition_position DESC;';

    wa('List is restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT s.partition_position,
                     s.partition_name,
                     p.composite,
                     p.subpartition_count,
                     s.num_rows,
                     s.sample_size,
                     CASE WHEN s.num_rows > 0 THEN TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), PERCENT_FORMAT) END percent,
                     s.last_analyzed,
                     s.distinct_keys,
                     s.blevel,
                     g.extents,
                     g.blocks segment_blocks,
                     s.leaf_blocks,
                     s.avg_leaf_blocks_per_key,
                     s.avg_data_blocks_per_key,
                     s.clustering_factor,
                     s.global_stats,
                     s.user_stats,
                     s.stattype_locked,
                     s.stale_stats,
                     s.avg_cached_blocks,
                     s.avg_cache_hit_ratio,
                     p.status
                FROM sqlt$_dba_ind_partitions p,
                     sqlt$_dba_ind_statistics s,
                     sqlt$_dba_segments g
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.index_owner = p_owner
                 AND p.index_name = p_index_name
                 AND p.statement_id = s.statement_id
                 AND p.index_owner = s.owner
                 AND p.index_name = s.index_name
                 AND p.partition_name = s.partition_name
                 AND s.object_type = 'PARTITION'
                 AND p.statement_id = g.statement_id(+)
                 AND p.index_owner = g.owner(+)
                 AND p.index_name = g.segment_name(+)
                 AND p.partition_name = g.partition_name(+)
                 AND 'INDEX PARTITION' = g.segment_type(+)
               ORDER BY
                     s.partition_position DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Part Pos'));
        wa(th('Partition Name'));
        wa(th('Composite'));
        wa(th('Sub Part Count'));
        wa(th('Num Rows<sup>1</sup>'));
        wa(th('Sample Size<sup>1</sup>'));
        wa(th(mot('Perc', 'Percent (%)')));
        wa(th('Last Analyzed<sup>1</sup>'));
        wa(th('Distinct Keys<sup>1</sup>'));
        wa(th('Blevel<sup>1</sup>'));
        wa(th('Segment Extents'));
        wa(th('Segment Blocks'));
        wa(th('Leaf Blocks<sup>1</sup>'));
        wa(th('Avg Leaf Blocks per Key<sup>1</sup>'));
        wa(th('Avg Data Blocks per Key<sup>1</sup>'));
        wa(th('Clustering Factor<sup>1</sup>'));
        wa(th('Global Stats<sup>1</sup>'));
        wa(th('User Stats<sup>1</sup>'));
        wa(th('Stat Type Locked'));
        wa(th('Stale Stats'));
        wa(th('Avg Cached Blocks'));
        wa(th('Avg Cache Hit Ratio'));
        wa(th('Status'));
        wa('</tr>');
      END IF;

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.partition_position));
      wa(td(i.partition_name, 'l'));
      wa(td(i.composite));
      wa(td(i.subpartition_count));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.distinct_keys, 'r'));
      wa(td(i.blevel, 'r'));
      wa(td(i.extents, 'r'));
      wa(td(i.segment_blocks, 'r'));
      wa(td(i.leaf_blocks, 'r'));
      wa(td(i.avg_leaf_blocks_per_key, 'r'));
      wa(td(i.avg_data_blocks_per_key, 'r'));
      wa(td(i.clustering_factor, 'r'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa(td(i.stattype_locked));
      wa(td(i.stale_stats));
      wa(td(i.avg_cached_blocks, 'r'));
      wa(td(i.avg_cache_hit_ratio, 'r'));
      wa(td(i.status));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
    wa(font('(1) CBO Statistics.'));
  EXCEPTION
    WHEN OTHERS THEN
      write_error('idx_part_stats_sec_'||p_object_id||': '||SQLERRM);
  END idx_part_stats_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private idx_part_stats_vers_sec
   *
   * ------------------------- */
  PROCEDURE idx_part_stats_vers_sec (
    p_index_name IN VARCHAR2,
    p_owner      IN VARCHAR2,
    p_object_id  IN NUMBER )
  IS
    l_row_count NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('idx_part_stats_vers_sec_'||p_object_id, 'S');
    wa(h4(mot(p_owner||'.'||p_index_name||' - Partition Statistics Versions', 'DBA_IND_STATS_VERSIONS'), 'idx_part_stats_vers_'||p_object_id));

    l_sql := '
SELECT p.partition_position,
       v.partition_name,
       v.version_type,
       v.save_time,
       v.last_analyzed,
       v.num_rows,
       v.sample_size,
       CASE WHEN v.num_rows > 0 THEN ROUND(v.sample_size * 100 / v.num_rows, 1) END percent,
       v.distinct_keys,
       v.blevel,
       v.leaf_blocks,
       v.avg_leaf_blocks_per_key,
       v.avg_data_blocks_per_key,
       v.clustering_factor,
       v.global_stats,
       v.user_stats
  FROM '||LOWER(TOOL_REPOSITORY_SCHEMA)||'.sqlt$_dba_ind_partitions p,
       '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_dba_ind_stats_versions_v v
 WHERE p.statement_id = '||s_sql_rec.statement_id||'
   AND p.index_owner = '''||p_owner||'''
   AND p.index_name = '''||p_index_name||'''
   AND p.statement_id = v.statement_id
   AND p.index_owner = v.owner
   AND p.index_name = v.index_name
   AND p.partition_name = v.partition_name
   AND v.object_type = ''PARTITION''
 ORDER BY
       p.partition_position DESC,
       DECODE(v.version_type,
       ''PENDING'', 1,
       ''CURRENT'', 2,
       ''HISTORY'', 3, 4),
       v.save_time DESC;';

    wa('List of pending, current and historic CBO statistics, restricted up to '||s_rows_table_l||' rows as per tool parameter "r_rows_table_l".');
    wa('<br>');
    wa(hide_sql(l_sql));
    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT p.partition_position,
                     v.partition_name,
                     v.version_type,
                     v.save_time,
                     v.last_analyzed,
                     v.num_rows,
                     v.sample_size,
                     CASE WHEN v.num_rows > 0 THEN TO_CHAR(ROUND(v.sample_size * 100 / v.num_rows, 1), PERCENT_FORMAT) END percent,
                     v.distinct_keys,
                     v.blevel,
                     v.leaf_blocks,
                     v.avg_leaf_blocks_per_key,
                     v.avg_data_blocks_per_key,
                     v.clustering_factor,
                     v.global_stats,
                     v.user_stats
                FROM sqlt$_dba_ind_partitions p,
                     sqlt$_dba_ind_stats_versions_v v
               WHERE p.statement_id = s_sql_rec.statement_id
                 AND p.index_owner = p_owner
                 AND p.index_name = p_index_name
                 AND p.statement_id = v.statement_id
                 AND p.index_owner = v.owner
                 AND p.index_name = v.index_name
                 AND p.partition_name = v.partition_name
                 AND v.object_type = 'PARTITION'
               ORDER BY
                     p.partition_position DESC,
                     DECODE(v.version_type,
                     'PENDING', 1,
                     'CURRENT', 2,
                     'HISTORY', 3, 4),
                     v.save_time DESC)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Part Pos'));
        wa(th('Partition Name'));
        wa(th('Version Type'));
        wa(th('Save Time'));
        wa(th('Last Analyzed'));
        wa(th('Num Rows'));
        wa(th('Sample Size'));
        wa(th(mot('Perc', 'Percent (%)')));
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
      wa(td(l_row_count, 'rt'));
      wa(td(i.partition_position));
      wa(td(i.partition_name, 'l'));
      wa(td(i.version_type, 'l'));
      wa(td(TO_CHAR(i.save_time, TIMESTAMP_TZ_FORMAT), 'c', 'nowrap'));
      wa(td(TO_CHAR(i.last_analyzed, LOAD_DATE_FORMAT), 'c', 'nowrap'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(i.percent, 'r'));
      wa(td(i.distinct_keys, 'r'));
      wa(td(i.blevel, 'r'));
      wa(td(i.leaf_blocks, 'r'));
      wa(td(i.avg_leaf_blocks_per_key, 'r'));
      wa(td(i.avg_data_blocks_per_key, 'r'));
      wa(td(i.clustering_factor, 'r'));
      wa(td(i.global_stats));
      wa(td(i.user_stats));
      wa('</tr>');

      IF l_row_count = s_rows_table_l THEN
        EXIT;
      END IF;
    END LOOP;
    wa('</table>');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('idx_part_stats_vers_sec_'||p_object_id||': '||SQLERRM);
  END idx_part_stats_vers_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private idx_part_sec
   *
   * ------------------------- */
  PROCEDURE idx_part_sec
  IS
    l_row_count NUMBER := 0;
    l_vers NUMBER := 0;
    l_vers2 NUMBER := 0;
    l_column_names VARCHAR2(32767);
    l_column_names2 VARCHAR2(32767);

  BEGIN
    write_log('idx_part_sec');
    wa(h2(mot('Index Partitions', 'DBA_IND_PARTITIONS'), 'idx_part'));

    SELECT COUNT(*)
      INTO l_vers
      FROM sqlt$_dba_ind_stats_versions
     WHERE statement_id = s_sql_rec.statement_id
       AND object_type = 'PARTITION'
       AND ROWNUM = 1;

    wa('<table>');
    l_row_count := 0;
    FOR i IN (SELECT *
                FROM sqlt$_dba_indexes
               WHERE statement_id = s_sql_rec.statement_id
                 AND partitioned = 'YES'
               ORDER BY
                     table_name,
                     table_owner,
                     in_plan DESC,
                     index_name,
                     owner)
    LOOP
      l_row_count := l_row_count + 1;
      IF MOD(l_row_count, TITLE_REPEAT_RATE) = 1 THEN
        wa('<tr>');
        wa(th('#'));
        wa(th('Table Name'));
        wa(th('Table Owner'));
        wa(th(moa('In Plan', 2)));
        wa(th('Index Name'));
        wa(th('Index Owner'));
        wa(th('Col ID'));
        wa(th('Column Name'));
        wa(th('Column Name<sup>1</sup>'));
        wa(th('Num<br>Rows<sup>2</sup>'));
        wa(th('Sample<br>Size<sup>2</sup>'));
        wa(th('Last<br>Analyzed<sup>2</sup>'));

        wa(th(mot('Part<br>Stats', 'Partition Statistics')));

        IF l_vers > 0 THEN
          wa(th(mot('Part<br>Stats<br>Versn', 'Partition Statistics Versions')));
        END IF;

        wa('</tr>');
      END IF;

      l_column_names := sqlt$a.get_index_column_names(s_sql_rec.statement_id, i.owner, i.index_name, 'YES', '<br>');
      l_column_names2 := sqlt$a.get_index_column_names(s_sql_rec.statement_id, i.owner, i.index_name, 'NO', '<br>');

      wa('<tr>');
      wa(td(l_row_count, 'rt'));
      wa(td(i.table_name, 'l'));
      wa(td(i.table_owner, 'l'));
      wa(td(i.in_plan));
      wa(td(i.index_name, 'l'));
      wa(td(i.owner, 'l'));
      wa(td(sqlt$a.get_index_column_ids(s_sql_rec.statement_id, i.owner, i.index_name, '<br>'), 'r'));
      wa(td(l_column_names, 'l'));
      wa(td(l_column_names2, 'l'));
      wa(td(i.num_rows, 'r'));
      wa(td(i.sample_size, 'r'));
      wa(td(TO_CHAR(i.last_analyzed, SHORT_DATE_FORMAT), 'c', 'nowrap'));

      wa(td(a('Stats', 'idx_part_stats_'||i.object_id)));

      IF l_vers > 0 THEN
        SELECT COUNT(*)
          INTO l_vers2
          FROM sqlt$_dba_ind_stats_versions_v
         WHERE statement_id = s_sql_rec.statement_id
           AND index_name = i.index_name
           AND owner = i.owner
           AND object_type = 'PARTITION';

        IF l_vers2 > 0 THEN
          --wa(td(a('Versn', 'idx_part_stats_vers_'||i.object_id)));
          wa(td(a(l_vers2, 'idx_part_stats_vers_'||i.object_id)));
        ELSE
          wa(td(NBSP));
        END IF;
      END IF;

      wa('</tr>');
    END LOOP;
    wa('</table>');
    wa(font('(1) Column names including system-generated names.'));
    wa('<br>');
    wa(font('(2) CBO Statistics.'));
    wa('<br>');
    wa(go_to_sec('Indexes', 'idx_sum'));
    wa(go_to_sec('Tables', 'tab_sum'));
    wa(go_to_top);

    FOR i IN (SELECT *
                FROM sqlt$_dba_indexes
               WHERE statement_id = s_sql_rec.statement_id
                 AND partitioned = 'YES'
               ORDER BY
                     table_name,
                     table_owner,
                     in_plan DESC,
                     index_name,
                     owner)
    LOOP
      wa(h3(i.owner||'.'||i.index_name||' - Index Partition', 'idx_part_'||i.object_id));

      wa('<ul>');
      wa(li(mot('Partition Statistics', 'DBA_IND_STATISTICS', '#idx_part_stats_'||i.object_id)));

      IF l_vers > 0 THEN
        SELECT COUNT(*)
          INTO l_vers2
          FROM sqlt$_dba_ind_stats_versions
         WHERE statement_id = s_sql_rec.statement_id
           AND index_name = i.index_name
           AND owner = i.owner
           AND object_type = 'PARTITION'
           AND ROWNUM = 1;

        IF l_vers2 > 0 THEN
          wa(li(mot('Partition Statistics Versions', 'DBA_IND_STATS_VERSIONS', '#idx_part_stats_vers_'||i.object_id)));
        ELSE
          wa(li(mot('Partition Statistics Versions', 'DBA_IND_STATS_VERSIONS')));
        END IF;
      END IF;

      wa('</ul>');
      wa(go_to_sec('Index Partitions', 'idx_part'));
      wa(go_to_sec('Indexes', 'idx_sum'));
      wa(go_to_sec('Tables', 'tab_sum'));
      wa(go_to_top);

      idx_part_stats_sec(i.index_name, i.owner, i.object_id);
      IF l_vers2 > 0 THEN
        idx_part_stats_vers_sec(i.index_name, i.owner, i.object_id);
      END IF;
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('idx_part_sec: '||SQLERRM);
  END idx_part_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private metadata_sec
   *
   * ------------------------- */
  PROCEDURE metadata_sec
  IS
  BEGIN
    write_log('metadata_sec');
    wa(h2(mot('Metadata', 'SYS.DBMS_METADATA.GET_DDL'), 'metadata'));

    wa('<ul>');
    FOR i IN (SELECT object_type
                FROM sqlt$_metadata
               WHERE statement_id = s_sql_rec.statement_id
                 AND transformed = 'N'
               GROUP BY
                     object_type
               ORDER BY
                     object_type)
    LOOP
      wa(li(a(INITCAP(i.object_type), 'meta_'||LOWER(REPLACE(i.object_type, ' ', '_')))));
    END LOOP;
    wa('</ul>');
    wa(go_to_top);

    FOR i IN (SELECT object_type
                FROM sqlt$_metadata
               WHERE statement_id = s_sql_rec.statement_id
                 AND transformed = 'N'
               GROUP BY
                     object_type
               ORDER BY
                     object_type)
    LOOP
      wa(h3(INITCAP(i.object_type)||' - Metadata', 'meta_'||LOWER(REPLACE(i.object_type, ' ', '_'))));

      wa('<ul>');
      FOR j IN (SELECT object_name, owner, object_id
                  FROM sqlt$_metadata
                 WHERE statement_id = s_sql_rec.statement_id
                   AND transformed = 'N'
                   AND object_type = i.object_type
                 ORDER BY
                       object_name,
                       owner)
      LOOP
        wa(li(a(j.object_name, 'meta_'||j.object_id)));
      END LOOP;
      wa('</ul>');
      wa(go_to_sec('Metadata', 'metadata'));
      wa(go_to_top);

      FOR j IN (SELECT object_name, owner, object_id, metadata
                  FROM sqlt$_metadata
                 WHERE statement_id = s_sql_rec.statement_id
                   AND transformed = 'N'
                   AND object_type = i.object_type
                 ORDER BY
                       object_name,
                       owner)
      LOOP
        wa(h4(j.owner||'.'||j.object_name||' - '||INITCAP(i.object_type)||' Metadata', 'meta_'||j.object_id));
        wa('<pre>');
        BEGIN
          sanitize_and_append(j.metadata, FALSE, p_max_line_size => 2000); -- was 120 then 1000
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
        END;
        wa('</pre>');
      END LOOP;
      wa(go_to_sec('Metadata', 'metadata'));
      wa(go_to_top);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('metadata_sec: '||SQLERRM);
  END metadata_sec;
  
  
  /*************************************************************************************/

  /* -------------------------
   *
   * private colusage_report_sec
   *
   * ------------------------- */
  PROCEDURE colusage_report_sec
  IS
  BEGIN
    write_log('colusage_report_sec');
    wa(h2(mot('Column Usage Report', 'SYS.DBMS_STATS.REPORT_COL_USAGE'), 'colusage_report'));

      --wa(h3('Column Report Usage for table '||i.owner||'.'||i.table_name, 'colusage_report_'||i.));

      wa('<ul>');
      FOR j IN (SELECT owner, table_name, object_id
                  FROM sqlt$_dba_tables
                WHERE statement_id = s_sql_rec.statement_id)
      LOOP
        wa(li(a(j.owner||'.'||j.table_name, 'colusagereport_'||j.object_id)));
      END LOOP;
      wa('</ul>');

      FOR j IN (SELECT owner, table_name, object_id, col_group_usage_report
                  FROM sqlt$_dba_tables
                 WHERE statement_id = s_sql_rec.statement_id)
      LOOP
        wa(h4(j.owner||'.'||j.table_name||' - Column Usage Report', 'colusagereport_'||j.object_id));
        wa('<pre>');
        BEGIN
          sanitize_and_append(j.col_group_usage_report, FALSE, p_max_line_size => 2000); -- was 120 then 1000
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
        END;
        wa('</pre>');
      END LOOP;
      wa(go_to_sec('Column Usage Report', 'colusage_report'));
      wa(go_to_top);

  EXCEPTION
    WHEN OTHERS THEN
      write_error('colusage_report_sec: '||SQLERRM);
  END colusage_report_sec;  
  

  /*************************************************************************************/

  /* -------------------------
   *
   * private main_report
   *
   * called by: sqlt$m.main_report_root
   *
   * ------------------------- */
  PROCEDURE main_report (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    clob_rec sqli$_clob%ROWTYPE;
    l_count NUMBER := 0;
    l_cursor_sharing NUMBER := 0;
    l_adaptive_cursor_sharing NUMBER := 0;
    l_peeked_binds NUMBER := 0;
    l_captured_binds NUMBER := 0;
    l_seg_stats NUMBER := 0;
    l_sess_stats NUMBER := 0;
    l_sess_events NUMBER := 0;
    l_dependencies NUMBER := 0;
    l_objects NUMBER := 0;
    l_fixed_objects NUMBER := 0;
    l_fixed_object_columns NUMBER := 0;
    l_nested_tables NUMBER := 0;
    l_policies NUMBER := 0;
    l_audit_policies NUMBER := 0;
    l_tables NUMBER := 0;
    l_table_ext NUMBER := 0;
    l_table_vers NUMBER := 0;
    l_table_mod NUMBER := 0;
    l_table_cons NUMBER := 0;
    l_table_part_key NUMBER := 0;
    l_table_part NUMBER := 0;
    l_table_columns NUMBER := 0;
    l_table_hgrm NUMBER := 0;
    l_table_hgrm_vers NUMBER := 0;
    l_indexes NUMBER := 0;
    l_index_cols NUMBER := 0;
    l_index_part NUMBER := 0;
    l_metadata NUMBER := 0;
    l_pln_sum NUMBER := 0;
    l_pln_sta NUMBER := 0;
    l_pln_his NUMBER := 0;
    l_pln_exe NUMBER := 0;
    l_outlines NUMBER := 0;
    l_patches NUMBER := 0;
    l_profiles NUMBER := 0;
    l_baselines NUMBER := 0;
    l_directives NUMBER := 0;
    l_sql_stats NUMBER := 0;
    l_sql_monitor NUMBER := 0;
    l_act_sess_hist NUMBER := 0;
    l_dba_hist_act_sess_hist NUMBER := 0;
    l_ebs_hgrm NUMBER := 0;
    l_out_file_identifier VARCHAR2(32767);
    l_col_group_usage_report NUMBER := 0;

  BEGIN
    -- moved to main_report_root
    --sqlt$a.common_initialization;
    --sqlt$t.temp_transformation(p_statement_id);
    --sqlt$h.health_check(p_statement_id);

    write_log('=> main_report');

    -- static variables
    BEGIN
      s_snap_id := 0;
      s_gran_segm := sqlt$a.get_param('r_gran_segm');
      s_gran_cols := sqlt$a.get_param('r_gran_cols');
      s_gran_hgrm := sqlt$a.get_param('r_gran_hgrm');
      s_gran_vers := sqlt$a.get_param('r_gran_vers');
      s_mask_for_values := sqlt$a.get_param('mask_for_values');
      s_plan_stats := sqlt$a.get_param('plan_stats');
      s_count_star_threshold := sqlt$a.get_param('count_star_threshold');
      s_rows_table_xs := CEIL(sqlt$a.get_param_n('r_rows_table_xs') * s_scaling_factor);
      s_rows_table_s := CEIL(sqlt$a.get_param_n('r_rows_table_s') * s_scaling_factor);
      s_rows_table_m := CEIL(sqlt$a.get_param_n('r_rows_table_m') * s_scaling_factor);
      s_rows_table_l := CEIL(sqlt$a.get_param_n('r_rows_table_l') * s_scaling_factor);

      s_sql_rec := sqlt$a.get_statement(p_statement_id);
      s_file_rec := NULL;
	  
      l_col_group_usage_report := sqlt$a.get_param_n('colgroup_seed_secs');  --12.1.04 

      IF p_out_file_identifier IS NULL THEN
        l_out_file_identifier := NULL;
      ELSE
        l_out_file_identifier := '_'||p_out_file_identifier;
      END IF;

      IF p_file_prefix IS NULL THEN
        s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_main.html';
      ELSE
        s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_main.html';
      END IF;

      s_file_rec.statid := s_sql_rec.statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('main_report.static: '||SQLERRM);
    END;

    -- open file
    BEGIN
      s_file_rec.file_text :=
      '<html>'||
      LF||'<!-- $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $ -->'||
      LF||'<!-- '||COPYRIGHT||' -->'||
      LF||'<!-- Author: '||TOOL_DEVELOPER_EMAIL||' -->'||
      LF||'<head>'||
      LF||'<title>'||s_file_rec.filename||'</title>';
    EXCEPTION
      WHEN OTHERS THEN
        write_error('main_report.open: '||SQLERRM);
    END;

    -- heading (css and javascripts)
    BEGIN
      SELECT * INTO clob_rec FROM sqli$_clob WHERE clob_id = 'CSS';
      append(clob_rec.clob_text);

      SELECT * INTO clob_rec FROM sqli$_clob WHERE clob_id = 'SHOW_HIDE';
      append(clob_rec.clob_text);

      IF sqlt$a.s_overlib = 'Y' THEN
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
      END IF;

      wa('<h1>'||doc_id(NOTE_NUMBER)||' '||TOOL_NAME||' '||s_sql_rec.method||' '||sqlt$a.get_param('tool_version')||NBSP2||'Report: '||s_file_rec.filename||'</h1>');
    EXCEPTION
      WHEN OTHERS THEN
        write_error('main_report.heading: '||SQLERRM);
    END;

    -- show errors
    BEGIN
      l_count := 0;
      FOR i IN (SELECT *
                  FROM sqlt$_log
                 WHERE statement_id = p_statement_id
                   AND line_type = 'E'
                 ORDER BY
                       line_id)
      LOOP
        l_count := l_count + 1;
        IF l_count = 1 THEN
          wa(font('Review log and fix following errors:', 'br')||'<br>');
        END IF;
        wa(font(i.line_text, 'b')||'<br>');
      END LOOP;
      IF l_count > 0 THEN
        wa('<br>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('main_report.show: '||SQLERRM);
    END;

    -- flags
    BEGIN
      write_log('-> flags');

      BEGIN
        SELECT COUNT(*)
          INTO l_cursor_sharing
          FROM sqlt$_gv$sql_shared_cursor
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.cursor_sharing: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_adaptive_cursor_sharing
          FROM sqlt$_gv$sql_cs_histogram
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.adaptive_cursor_sharing: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_peeked_binds
          FROM sqlt$_peeked_binds_v
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.peeked_binds: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_captured_binds
          FROM sqlt$_captured_binds_v
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.captured_binds: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_seg_stats
          FROM sqlt$_gv$segment_statistics_v
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.gv$segment_statistics: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_sess_stats
          FROM sqlt$_gv$sesstat_v
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.gv$sesstat_v: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_sess_events
          FROM sqlt$_gv$session_event_v
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.gv$session_event_v: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_dependencies
          FROM sqlt$_dependencies_v
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dependencies_v: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_objects
          FROM sqlt$_dba_objects
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_objects: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_fixed_objects
          FROM sqlt$_dba_tab_statistics
         WHERE statement_id = p_statement_id
           AND object_type = 'FIXED TABLE'
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_tab_statistics: '||SQLERRM);
      END;

      IF l_fixed_objects > 0 THEN
        BEGIN
          SELECT COUNT(*)
            INTO l_fixed_object_columns
            FROM sqlt$_dba_tab_col_statistics c
           WHERE statement_id = p_statement_id
             AND owner = 'SYS'
             AND ROWNUM = 1
             AND EXISTS (
          SELECT NULL
            FROM sqlt$_dba_tab_statistics
           WHERE statement_id = p_statement_id
             AND object_type = 'FIXED TABLE'
             AND table_name = c.table_name);
        EXCEPTION
          WHEN OTHERS THEN
            write_error('main_report.flags.dba_tab_col_statistics c: '||SQLERRM);
        END;
      END IF;

      BEGIN
        SELECT COUNT(*)
          INTO l_nested_tables
          FROM sqlt$_dba_nested_tables
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_nested_tables: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_policies
          FROM sqlt$_dba_policies
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_policies: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_audit_policies
          FROM sqlt$_dba_audit_policies
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_audit_policies: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_tables
          FROM sqlt$_dba_all_tables_v
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_all_tables_v: '||SQLERRM);
      END;

      IF l_tables > 0 THEN
        BEGIN
          SELECT COUNT(*)
            INTO l_table_ext
            FROM sqlt$_dba_stat_extensions
           WHERE statement_id = p_statement_id
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('main_report.flags.dba_stat_extensions: '||SQLERRM);
        END;

        BEGIN
          SELECT COUNT(*)
            INTO l_table_vers
            FROM sqlt$_dba_tab_stats_versions
           WHERE statement_id = p_statement_id
             AND object_type = 'TABLE'
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('main_report.flags.dba_tab_stats_versions: '||SQLERRM);
        END;

        BEGIN
          SELECT COUNT(*)
            INTO l_table_mod
            FROM sqlt$_dba_tab_modifications
           WHERE statement_id = p_statement_id
             AND partition_name IS NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('main_report.flags.dba_tab_modifications: '||SQLERRM);
        END;

        BEGIN
          SELECT COUNT(*)
            INTO l_table_cons
            FROM sqlt$_dba_constraints
           WHERE statement_id = p_statement_id
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('main_report.flags.dba_constraints: '||SQLERRM);
        END;

        BEGIN
          SELECT COUNT(*)
            INTO l_table_columns
            FROM sqlt$_dba_all_table_cols_v
           WHERE statement_id = p_statement_id
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('main_report.flags.dba_all_table_cols_v: '||SQLERRM);
        END;

        BEGIN
          SELECT COUNT(*)
            INTO l_table_hgrm
            FROM sqlt$_dba_all_table_cols_v
           WHERE statement_id = p_statement_id
             AND histogram <> 'NONE'
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('main_report.flags.dba_all_table_cols_v: '||SQLERRM);
        END;

        IF s_gran_vers = 'HISTOGRAM' THEN
          IF l_table_hgrm > 0 THEN
            BEGIN
              SELECT COUNT(*)
                INTO l_table_hgrm_vers
                FROM sqlt$_dba_histgrm_stats_versn v,
                     sqlt$_dba_all_table_cols_v c
               WHERE v.statement_id = p_statement_id
                 AND v.statement_id = c.statement_id
                 AND v.owner = c.owner
                 AND v.table_name = c.table_name
                 AND v.column_name = c.column_name
                 AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
                 --AND c.hidden_column = 'NO'
                 AND ROWNUM = 1;
            EXCEPTION
              WHEN OTHERS THEN
                write_error('main_report.flags.table_hgrm_vers: '||SQLERRM);
            END;
          END IF;
        END IF;

        IF s_gran_segm = 'PARTITION' THEN
          BEGIN
            SELECT COUNT(*)
              INTO l_table_part_key
              FROM sqlt$_dba_part_key_columns
             WHERE statement_id = p_statement_id
               AND object_type = 'TABLE'
               AND ROWNUM = 1;
          EXCEPTION
            WHEN OTHERS THEN
              write_error('main_report.flags.table_part_key: '||SQLERRM);
          END;
        END IF;

        IF l_table_part_key > 0 THEN
          BEGIN
            SELECT COUNT(*)
              INTO l_table_part
              FROM sqlt$_dba_tab_partitions
             WHERE statement_id = p_statement_id
               AND ROWNUM = 1;
          EXCEPTION
            WHEN OTHERS THEN
              write_error('main_report.flags.table_part: '||SQLERRM);
          END;
        END IF;

        IF s_gran_segm = 'PARTITION' THEN
          BEGIN
            SELECT COUNT(*)
              INTO l_index_part
              FROM sqlt$_dba_ind_partitions
             WHERE statement_id = p_statement_id
               AND ROWNUM = 1;
          EXCEPTION
            WHEN OTHERS THEN
              write_error('main_report.flags.dba_ind_partitions: '||SQLERRM);
          END;
        END IF;

        BEGIN
          SELECT COUNT(*)
            INTO l_indexes
            FROM sqlt$_dba_indexes
           WHERE statement_id = p_statement_id
             AND ROWNUM = 1;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('main_report.flags.dba_indexes: '||SQLERRM);
        END;

        IF l_indexes > 0 THEN
          BEGIN
            SELECT COUNT(*)
              INTO l_index_cols
              FROM sqlt$_dba_ind_columns
             WHERE statement_id = p_statement_id
               AND ROWNUM = 1;
          EXCEPTION
            WHEN OTHERS THEN
              write_error('main_report.flags.index_cols: '||SQLERRM);
          END;
        END IF; -- l_indexes > 0
      END IF; -- l_tables >

      BEGIN
        SELECT COUNT(*)
          INTO l_metadata
          FROM sqlt$_metadata
         WHERE statement_id = p_statement_id
           AND transformed = 'N'
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.metadata: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_pln_sum
          FROM sqlt$_plan_summary_v2
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.plan_summary_v2: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_pln_his
          FROM sqlt$_dba_hist_sqlstat_v
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_hist_sqlstat_v: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_pln_sta
          FROM sqlt$_plan_stats_v
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.plan_stats_v: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_pln_exe
          FROM sqlt$_plan_header_v
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.plan_header_v: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_outlines
          FROM sqlt$_dba_outlines
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_outlines: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_patches
          FROM sqlt$_dba_sql_patches
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_sql_patches: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_profiles
          FROM sqlt$_dba_sql_profiles
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_sql_profiles: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_baselines
          FROM sqlt$_dba_sql_plan_baselines
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_sql_plan_baselines: '||SQLERRM);
      END;

	  -- 151020 limit to Group and Join
	  -- 150828 new
      BEGIN
        SELECT COUNT(*)
          INTO l_directives
          FROM sqlt$_dba_sql_plan_directives
         WHERE statement_id = p_statement_id
		   AND (reason like 'GROUP%' or reason like 'JOIN%')
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_sql_plan_directives: '||SQLERRM);
      END;


      BEGIN
        SELECT COUNT(*)
          INTO l_act_sess_hist
          FROM sqlt$_gv$active_session_histor
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.gv$active_session_histor: '||SQLERRM);
      END;

     BEGIN
       SELECT COUNT(*)
          INTO l_dba_hist_act_sess_hist
          FROM sqlt$_dba_hist_active_sess_his
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.dba_hist_active_sess_his: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_sql_stats
          FROM sqlt$_gv$sql
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.gv$sql: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_sql_monitor
          FROM sqlt$_gv$sql_monitor
         WHERE statement_id = p_statement_id
           AND sql_child_number IS NOT NULL
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.gv$sql_monitor: '||SQLERRM);
      END;

      BEGIN
        SELECT COUNT(*)
          INTO l_ebs_hgrm
          FROM sqlt$_fnd_histogram_cols
         WHERE statement_id = p_statement_id
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.flags.fnd_histogram_cols: '||SQLERRM);
      END;

      write_log('<- flags');
    EXCEPTION
      WHEN OTHERS THEN
        write_error('main_report.flags: '||SQLERRM);
    END;

    -- report table of contents
    BEGIN
      wa(a(NULL, NULL, 'toc'));

      -- Global
      BEGIN
        wa('<table border="0"><tr><td class="lw">'||h3('Global', NULL, FALSE)||'<ul>');
        wa(li(a('Observations', 'observ')));
        wa(li(mot('SQL Text', 'GV$SQLAREA, GV$SQLTEXT_WITH_NEWLINES and DBA_HIST_SQLTEXT', '#sql_text')));
        wa(li(a('SQL Identification', 'sql_id')));
        wa(li(a('Environment', 'env')));
        wa(li(mot('CBO Environment', 'SQLT$_GV$PARAMETER_CBO', '#cbo_env')));
        wa(li(mot('Fix Control', 'V$SESSION_FIX_CONTROL', '#fix_ctl')));
        wa(li(mot('CBO System Statistics', 'AUX_STATS$ and WRI$_OPTSTAT_AUX_HISTORY', '#system_stats')));
        IF s_sql_rec.rdbms_release >= 11 THEN
          wa(li(mot('DBMS_STATS Setup', 'DBA_AUTOTASK_CLIENT', '#dbms_stats')));
        ELSE
          wa(li(mot('DBMS_STATS Setup', 'DBA_SCHEDULER_JOBS', '#dbms_stats')));
        END IF;
        wa(li(mot('Initialization Parameters', 'GV$PARAMETER2 and DBA_HIST_PARAMETER', '#init_params')));
        wa(li(mot('NLS Parameters', 'NLS_SESSION_PARAMETERS, NLS_INSTANCE_PARAMETERS and NLS_DATABASE_PARAMETERS', '#nls_params')));
        IF s_sql_rec.rdbms_release >= 11 THEN
          wa(li(mot('I/O Calibration', 'DBA_RSRC_IO_CALIBRATE and V$IO_CALIBRATION_STATUS', '#io_calibration')));
        ELSE
          wa(li(mot('I/O Calibration', 'DBA_RSRC_IO_CALIBRATE and V$IO_CALIBRATION_STATUS')));
        END IF;
        wa(li(a('Tool Configuration Parameters', 'tool_params')));
      END;

      -- Cursor Sharing and Binds
      BEGIN
        wa('</ul>'||h3('Cursor Sharing and Binds', NULL, FALSE)||'<ul>');

        IF l_cursor_sharing > 0 THEN
          wa(li(mot('Cursor Sharing', 'GV$SQL_SHARED_CURSOR', '#cursor_sharing')));
        ELSE
          wa(li(mot('Cursor Sharing', 'GV$SQL_SHARED_CURSOR')));
        END IF;

        IF l_adaptive_cursor_sharing > 0 THEN
          wa(li(mot('Adaptive Cursor Sharing', 'GV$SQL, GV$SQL_CS_HISTOGRAM, GV$SQL_CS_SELECTIVITY and GV$SQL_CS_STATISTICS', '#adaptive_cursor_sharing')));
        ELSE
          wa(li(mot('Adaptive Cursor Sharing', 'GV$SQL, GV$SQL_CS_HISTOGRAM, GV$SQL_CS_SELECTIVITY and GV$SQL_CS_STATISTICS')));
        END IF;

        IF l_peeked_binds > 0 THEN
          wa(li(a('Peeked Binds', 'peeked_binds')));
        ELSE
          wa(li('Peeked Binds'));
        END IF;

        IF l_captured_binds > 0 THEN
          wa(li(mot('Captured Binds', 'GV$SQL_BIND_CAPTURE and DBA_HIST_SQLBIND', '#captured_binds')));
        ELSE
          wa(li(mot('Captured Binds', 'GV$SQL_BIND_CAPTURE and DBA_HIST_SQLBIND')));
        END IF;
      END;

      -- SQL Tuning Advisor
      BEGIN
        wa('</ul>'||h3('SQL Tuning Advisor', NULL, FALSE)||'<ul>');

        IF NVL(NVL(s_sql_rec.file_sta_report_txt, s_sql_rec.file_sta_report_mem), s_sql_rec.file_sta_report_awr) IS NULL THEN
          wa(li(mot('STA Report', 'DBA_SQLTUNE.REPORT_TUNING_TASK')));
        ELSE
          wa(li(mot('STA Report', 'DBA_SQLTUNE.REPORT_TUNING_TASK', NVL(NVL(s_sql_rec.file_sta_report_txt, s_sql_rec.file_sta_report_mem), s_sql_rec.file_sta_report_awr), p_target => 'STA_Report_'||p_statement_id)));
        END IF;

        IF NVL(NVL(s_sql_rec.file_sta_script_txt, s_sql_rec.file_sta_script_mem), s_sql_rec.file_sta_script_awr) IS NULL THEN
          wa(li(mot('STA Script', 'DBA_SQLTUNE.SCRIPT_TUNING_TASK')));
        ELSE
          wa(li(mot('STA Script', 'DBA_SQLTUNE.SCRIPT_TUNING_TASK', NVL(NVL(s_sql_rec.file_sta_script_txt, s_sql_rec.file_sta_script_mem), s_sql_rec.file_sta_script_awr), p_target => 'STA_Script_'||p_statement_id)));
        END IF;
      END;

      -- Plans
      BEGIN
        wa('</ul></td><td class="lw">'||NBSP4||'</td><td class="lw">'||h3('Plans', NULL, FALSE)||'<ul>');

        IF l_pln_sum > 0 THEN
          wa(li(mot('Summary', 'GV$SQLAREA_PLAN_HASH, DBA_HIST_SQLSTAT, EXPLAIN PLAN FOR and DBA_SQLTUNE_PLANS', '#pln_sum')));
        ELSE
          wa(li(mot('Summary', 'GV$SQLAREA_PLAN_HASH, DBA_HIST_SQLSTAT, EXPLAIN PLAN FOR and DBA_SQLTUNE_PLANS')));
        END IF;

        IF l_pln_sta > 0 THEN
          wa(li(mot('Performance Statistics', 'GV$SQLAREA_PLAN_HASH and DBA_HIST_SQLSTAT', '#pln_sta')));
        ELSE
          wa(li(mot('Performance Statistics', 'GV$SQLAREA_PLAN_HASH and DBA_HIST_SQLSTAT')));
        END IF;

        IF l_pln_his > 0 THEN
          wa(li(mot('Performance History (delta)', 'DBA_HIST_SQLSTAT', '#pln_his_delta')));
        ELSE
          wa(li(mot('Performance History (delta)', 'DBA_HIST_SQLSTAT')));
        END IF;

        IF l_pln_his > 0 THEN
          wa(li(mot('Performance History (total)', 'DBA_HIST_SQLSTAT', '#pln_his_total')));
        ELSE
          wa(li(mot('Performance History (total)', 'DBA_HIST_SQLSTAT')));
        END IF;

        IF l_pln_exe > 0 THEN
          wa(li(mot('Execution Plans', 'GV$SQL_PLAN, DBA_HIST_SQL_PLAN, PLAN_TABLE and DBA_SQLTUNE_PLANS', '#pln_exe')));
        ELSE
          wa(li(mot('Execution Plans', 'GV$SQL_PLAN, DBA_HIST_SQL_PLAN, PLAN_TABLE and DBA_SQLTUNE_PLANS')));
        END IF;
      END;

      -- Plan Control
      BEGIN
        wa('</ul>'||h3('Plan Control', NULL, FALSE)||'<ul>');

        IF l_outlines > 0 THEN
          wa(li(mot('Stored Outlines', 'DBA_OUTLINES and DBA_OUTLINE_HINTS', '#outlines')));
        ELSE
          wa(li(mot('Stored Outlines', 'DBA_OUTLINES and DBA_OUTLINE_HINTS')));
        END IF;

        IF l_patches > 0 THEN
          wa(li(mot('SQL Patches', 'DBA_SQL_PATCHES', '#patches')));
        ELSE
          wa(li(mot('SQL Patches', 'DBA_SQL_PATCHES')));
        END IF;

        IF l_profiles > 0 THEN
          wa(li(mot('SQL Profiles', 'DBA_SQL_PROFILES', '#profiles')));
        ELSE
          wa(li(mot('SQL Profiles', 'DBA_SQL_PROFILES')));
        END IF;

        IF l_baselines > 0 THEN
          wa(li(mot('SQL Plan Baselines', 'DBA_SQL_PLAN_BASELINES', '#baselines')));
        ELSE
          wa(li(mot('SQL Plan Baselines', 'DBA_SQL_PLAN_BASELINES')));
        END IF;

        IF l_directives > 0 THEN
          wa(li(mot('SQL Plan Directives', 'DBA_SQL_PLAN_DIRECTIVES', '#directives')));
        ELSE
          wa(li(mot('SQL Plan Directives', 'DBA_SQL_PLAN_DIRECTIVES')));
        END IF;

      END;

      -- SQL Execution
      BEGIN
        wa('</ul>'||h3('SQL Execution', NULL, FALSE)||'<ul>');

        IF l_act_sess_hist > 0 THEN
          wa(li(mot('Active Session History', 'GV$ACTIVE_SESSION_HISTORY', '#act_sess_hist')));
        ELSE
          wa(li(mot('Active Session History', 'GV$ACTIVE_SESSION_HISTORY')));
        END IF;

        IF l_dba_hist_act_sess_hist > 0 THEN
          wa(li(mot('AWR Active Session History', 'DBA_HIST_ACTIVE_SESS_HISTORY', '#dba_hist_act_sess_hist')));
        ELSE
          wa(li(mot('AWR Active Session History', 'DBA_HIST_ACTIVE_SESS_HISTORY')));
        END IF;

        IF l_sql_stats > 0 THEN
          wa(li(mot('SQL Statistics', 'GV$SQL', '#sql_stats')));
        ELSE
          wa(li(mot('SQL Statistics', 'GV$SQL')));
        END IF;

        IF s_sql_rec.file_sql_detail_active IS NULL THEN
          wa(li(mot('SQL Detail ACTIVE Report', 'DBMS_SQLTUNE.REPORT_SQL_DETAIL')));
        ELSE
          wa(li(mot('SQL Detail ACTIVE Report', 'DBMS_SQLTUNE.REPORT_SQL_DETAIL', s_sql_rec.file_sql_detail_active, p_target => 'DET_ACTIVE_Report_'||p_statement_id)));
        END IF;

        IF l_sql_monitor > 0 THEN
          wa(li(mot('Monitor Statistics', 'GV$SQL_MONITOR', '#sql_monitor')));
        ELSE
          wa(li(mot('Monitor Statistics', 'GV$SQL_MONITOR')));
        END IF;

        IF s_sql_rec.file_mon_report_active IS NULL THEN
          wa(li(mot('Monitor ACTIVE Report', 'DBMS_SQLTUNE.REPORT_SQL_MONITOR')));
        ELSE
          wa(li(mot('Monitor ACTIVE Report', 'DBMS_SQLTUNE.REPORT_SQL_MONITOR', s_sql_rec.file_mon_report_active, p_target => 'MON_ACTIVE_Report_'||p_statement_id)));
        END IF;

        IF s_sql_rec.file_mon_report_html IS NULL THEN
          wa(li(mot('Monitor HTML Report', 'DBMS_SQLTUNE.REPORT_SQL_MONITOR')));
        ELSE
          wa(li(mot('Monitor HTML Report', 'DBMS_SQLTUNE.REPORT_SQL_MONITOR', s_sql_rec.file_mon_report_html, p_target => 'MON_HTML_Report_'||p_statement_id)));
        END IF;

        IF s_sql_rec.file_mon_report_text IS NULL THEN
          wa(li(mot('Monitor TEXT Report', 'DBMS_SQLTUNE.REPORT_SQL_MONITOR')));
        ELSE
          wa(li(mot('Monitor TEXT Report', 'DBMS_SQLTUNE.REPORT_SQL_MONITOR', s_sql_rec.file_mon_report_text, p_target => 'MON_TEXT_Report_'||p_statement_id)));
        END IF;

        IF l_seg_stats > 0 THEN
          wa(li(mot('Segment Statistics', 'GV$SEGMENT_STATISTICS', '#seg_stats')));
        ELSE
          wa(li(mot('Segment Statistics', 'GV$SEGMENT_STATISTICS')));
        END IF;

        IF l_sess_stats > 0 THEN
          wa(li(mot('Session Statistics', 'GV$SESSTAT', '#sess_stats')));
        ELSE
          wa(li(mot('Session Statistics', 'GV$SESSTAT')));
        END IF;

        IF l_sess_events > 0 THEN
          wa(li(mot('Session Events', 'GV$SESSION_EVENT', '#sess_events')));
        ELSE
          wa(li(mot('Session Events', 'GV$SESSION_EVENT')));
        END IF;

        wa(li(mot('Parallel Processing', 'GV$PQ and GV$PX views', '#parallel_exec')));
      END;

      -- Tables
      BEGIN
        wa('</ul></td><td class="lw">'||NBSP4||'</td><td class="lw">'||h3('Tables', NULL, FALSE)||'<ul>');

        IF l_tables > 0 THEN
          wa(li(mot('Tables', 'DBA_TABLES', '#tab_sum')));
        ELSE
          wa(li(mot('Tables', 'DBA_TABLES')));
        END IF;

        IF l_tables > 0 THEN
          wa(li(mot('Statistics', 'DBA_TAB_STATISTICS and DBA_SEGMENTS', '#tab_stats')));
        ELSE
          wa(li(mot('Statistics', 'DBA_TAB_STATISTICS and DBA_SEGMENTS')));
        END IF;

        -- Mauro added on 07/12/13
        IF l_table_ext > 0 THEN
          wa(li(mot('Statistics Extensions', 'DBA_STAT_EXTENSIONS', '#tab_cbo_ext')));
        ELSE
          wa(li(mot('Statistics Extensions', 'DBA_STAT_EXTENSIONS')));
        END IF;

        IF l_table_vers > 0 THEN
          wa(li(mot('Statistics Versions', 'DBA_TAB_STATS_VERSIONS', '#tab_cbo_vers')));
        ELSE
          wa(li(mot('Statistics Versions', 'DBA_TAB_STATS_VERSIONS')));
        END IF;

        IF l_table_mod > 0 THEN
          wa(li(mot('Modifications', 'DBA_TAB_MODIFICATIONS', '#tab_mod')));
        ELSE
          wa(li(mot('Modifications', 'DBA_TAB_MODIFICATIONS')));
        END IF;

        IF l_tables > 0 THEN
          wa(li(mot('Properties', 'DBA_TABLES', '#tab_prop')));
        ELSE
          wa(li(mot('Properties', 'DBA_TABLES')));
        END IF;

        IF l_tables > 0 THEN
          wa(li(mot('Physical Properties', 'DBA_TABLES', '#tab_phy_prop')));
        ELSE
          wa(li(mot('Physical Properties', 'DBA_TABLES')));
        END IF;

        IF l_table_cons > 0 THEN
          wa(li(mot('Constraints', 'DBA_CONSTRAINTS', '#tab_cons')));
        ELSE
          wa(li(mot('Constraints', 'DBA_CONSTRAINTS')));
        END IF;

        IF l_table_columns > 0 THEN
          wa(li(mot('Columns', 'DBA_TAB_COLS', '#tab_cols')));
        ELSE
          wa(li(mot('Columns', 'DBA_TAB_COLS')));
        END IF;

        IF l_index_cols > 0 THEN
          wa(li(mot('Indexed Columns', 'DBA_IND_COLUMNS', '#idxed_cols')));
        ELSE
          wa(li(mot('Indexed Columns', 'DBA_IND_COLUMNS')));
        END IF;

        IF l_table_hgrm > 0 THEN
          wa(li(mot('Histograms', 'DBA_TAB_HISTOGRAMS', '#tab_col_hgrm')));
        ELSE
          wa(li(mot('Histograms', 'DBA_TAB_HISTOGRAMS')));
        END IF;

        IF s_sql_rec.apps_release IS NOT NULL THEN
          IF l_ebs_hgrm > 0 THEN
            wa(li(mot('EBS Histograms', 'FND_HISTOGRAM_COLS', '#ebs_hgrm')));
          ELSE
            wa(li(mot('EBS Histograms', 'FND_HISTOGRAM_COLS')));
          END IF;
        END IF;

        IF l_table_part > 0 THEN
          wa(li(mot('Partitions', 'DBA_TAB_PARTITIONS', '#tab_part')));
        ELSE
          wa(li(mot('Partitions', 'DBA_TAB_PARTITIONS')));
        END IF;

        IF l_indexes > 0 THEN
          wa(li(mot('Indexes', 'DBA_INDEXES', '#idx_sum')));
        ELSE
          wa(li(mot('Indexes', 'DBA_INDEXES')));
        END IF;
      END;

      -- Objects
      BEGIN
        wa('</ul>'||h3('Objects', NULL, FALSE)||'<ul>');

        IF l_objects > 0 THEN
          wa(li(mot('Objects', 'DBA_OBJECTS', '#objects')));
        ELSE
          wa(li(mot('Objects', 'DBA_OBJECTS')));
        END IF;

        IF l_dependencies > 0 THEN
          wa(li(mot('Dependencies', 'GV$OBJECT_DEPENDENCY and DBA_DEPENDENCIES', '#obj_depend')));
        ELSE
          wa(li(mot('Dependencies', 'GV$OBJECT_DEPENDENCY and DBA_DEPENDENCIES')));
        END IF;

        IF l_fixed_objects > 0 THEN
          wa(li(mot('Fixed Objects', 'DBA_TAB_STATISTICS', '#fixed_objects')));
        ELSE
          wa(li(mot('Fixed Objects', 'DBA_TAB_STATISTICS')));
        END IF;

        IF l_fixed_object_columns > 0 THEN
          wa(li(mot('Fixed Object Columns', 'DBA_TAB_COLS', '#fixed_obj_cols')));
        ELSE
          wa(li(mot('Fixed Object Columns', 'DBA_TAB_COLS')));
        END IF;

        IF l_nested_tables > 0 THEN
          wa(li(mot('Nested Tables', 'DBA_NESTED_TABLES', '#nested_tables')));
        ELSE
          wa(li(mot('Nested Tables', 'DBA_NESTED_TABLES')));
        END IF;

        IF l_policies > 0 THEN
          wa(li(mot('Policies', 'DBA_POLICIES', '#policies')));
        ELSE
          wa(li(mot('Policies', 'DBA_POLICIES')));
        END IF;

        IF l_audit_policies > 0 THEN
          wa(li(mot('Audit Policies', 'DBA_AUDIT_POLICIES', '#audit_policies')));
        ELSE
          wa(li(mot('Audit Policies', 'DBA_AUDIT_POLICIES')));
        END IF;

        wa(li(mot('Tablespaces', 'DBA_TABLESPACES', '#tablespaces')));

        IF l_metadata > 0 AND s_metadata = 'Y' THEN
          wa(li(mot('Metadata', 'SYS.DBMS_METADATA.GET_DDL', '#metadata')));
        ELSE
          wa(li(mot('Metadata', 'SYS.DBMS_METADATA.GET_DDL')));
        END IF;
      END;

      -- toc footer
      BEGIN
        wa('</ul></td></tr></table>');

        IF s_sql_rec.sql_tuning_advisor = 'Y' OR s_sql_rec.sql_monitoring = 'Y' OR s_sql_rec.automatic_workload_repository = 'Y' THEN
          wa(font('This report may include some content provided by the Oracle Diagnostic and/or the Oracle Tuning Packs (in particular SQL Tuning Advisor "STA", SQL Tuning Sets "STS", SQL Monitoring and/or Automatic Workload Repository "AWR"). Be aware that using this extended functionality requires a license for the corresponding pack. If you need to disable '||TOOL_NAME||' access to one of these packages, please execute one of the following commands: SQL> EXEC '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.disable_tuning_pack_access; or SQL> EXEC '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.disable_diagnostic_pack_access;', 'nr'));
        ELSE
          wa(font('This report has been restricted to exclude some content provided by the Oracle Diagnostic and the Oracle Tuning Pack. If you have a license for them and want to enable '||TOOL_NAME||' access to the extended functionality they provide, please execute one of the following commands: SQL> EXEC '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.enable_tuning_pack_access; or SQL> EXEC '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.enable_diagnostic_pack_access;', 'n'));
        END IF;
        wa('<br>');
        wa('<br>');

        wa(font('sqlt_start: '||TO_CHAR(s_sql_rec.tool_start_date, LOAD_DATE_FORMAT), 'f'));
      END;

    EXCEPTION
      WHEN OTHERS THEN
        write_error('main_report.toc: '||SQLERRM);
    END;

    -- report body
    BEGIN
      -- 1st column - Global
      BEGIN
        -- Observations
        observations_sec;

        -- SQL Text
        sql_text_sec;

        -- SQL Identification
        sql_identification_sec;

        -- Environment
        environment_sec;

        -- Optimizer Environment
        cbo_environment_sec;

        -- Fix Control
        bug_fix_control_sec;

        -- CBO System Statistics
        system_stats_sec;

        -- SYS.DBMS_STATS Setup
        dbms_stats_setup_sec;

        -- Initialization Parameters
        init_parameters_sec;

        -- NLS Parameters
        nls_parameters_sec;

        -- I/O Calibration
        io_calibration_sec;

        -- Tool Configuartion Parameters
        tool_config_params_sec;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.body.1st.global: '||SQLERRM);
      END;

      -- 1st column - Cursor Sharing and Binds
      BEGIN
        -- Cursor Sharing
        IF l_cursor_sharing > 0 THEN
          cursor_sharing_sec;
        END IF;

        -- Adaptive Cursor Sharing
        IF l_adaptive_cursor_sharing > 0 THEN
          adaptive_cursor_sharing_sec;
        END IF;

        -- Peeked Binds
        IF l_peeked_binds > 0 THEN
          peeked_binds_sec;
        END IF;

        -- Captured Binds
        IF l_captured_binds > 0 THEN
          captured_binds_sec;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.body.1st.cursor: '||SQLERRM);
      END;

      -- 2nd column - Plans
      BEGIN
        -- Summary
        IF l_pln_sum > 0 THEN
          plan_sum_sec;
        END IF;

        -- Performance Statistics
        IF l_pln_sta > 0 THEN
          plan_stats_sec;
        END IF;

        -- History
        IF l_pln_his > 0 THEN
          plan_history_delta_sec;
          plan_history_total_sec;
        END IF;

        -- Execution Plans
        IF l_pln_exe > 0 THEN
          plan_exec_sec;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.body.2nd.plans: '||SQLERRM);
      END;

      -- 2nd column - Plan Control
      BEGIN
        -- Stored Outlines
        IF l_outlines > 0 THEN
          outlines_sec;
        END IF;

        IF l_patches > 0 THEN
          patches_sec;
        END IF;

        IF l_profiles > 0 THEN
          profiles_sec;
        END IF;

        IF l_baselines > 0 THEN
          baselines_sec;
        END IF;

		-- 150828
        IF l_directives > 0 THEN
		  wa(h2(mot('SQL Plan Directives', 'DBA_SQL_PLAN_DIRECTIVES'), 'directives'));
	      directives_m_sec(p_reason=>'GROUP',p_state=>'USABLE');
		  directives_m_sec(p_reason=>'GROUP',p_state=>'SUPERSEDED');
		  directives_m_sec(p_reason=>'JOIN',p_state=>'USABLE');
		  directives_m_sec(p_reason=>'JOIN',p_state=>'SUPERSEDED');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.body.2nd.control: '||SQLERRM);
      END;

      -- 2nd column - SQL Execution
      BEGIN
        -- Active Session History
        IF l_act_sess_hist > 0 THEN
          act_sess_hist_sec;
        END IF;

        -- AWR Active Session History
        IF l_dba_hist_act_sess_hist > 0 THEN
          dba_hist_act_sess_hist_sec;
        END IF;

        -- SQL Stats
        IF l_sql_stats > 0 THEN
          sql_stats_sec;
        END IF;

        -- SQL Monitor
        IF l_sql_monitor > 0 THEN
          sql_monitor_sec;
        END IF;

        -- Segment Statistics
        IF l_seg_stats > 0 THEN
          segment_stats_sec;
        END IF;

        -- Session Statistics
        IF l_sess_stats > 0 THEN
          session_stats_sec;
        END IF;

        -- Session Events
        IF l_sess_events > 0 THEN
          session_event_sec;
        END IF;

        -- Parallel Processing
        IF s_sql_rec.method = 'XECUTE' THEN
          parallel_processing_sec1;
        ELSE
          parallel_processing_sec2;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.body.2nd.sql: '||SQLERRM);
      END;

      -- 3rd column - Tables Section
      BEGIN
        -- Tables (Summary)
        IF l_tables > 0 THEN
          table_sum_sec;
        END IF;

        -- Statistics
        IF l_tables > 0 THEN
          tab_stats_sec;
        END IF;

        -- Statistics Versions
        IF l_table_vers > 0 THEN
          tab_stats_vers_sec;
        END IF;

        -- Statistics Extensions (on Table Summary)
        IF l_table_ext > 0 THEN
          tab_stats_ext_sec;
        END IF;

        -- Modifications (on Table Summary)
        IF l_table_mod > 0 THEN
          tab_mod_sec;
        END IF;

        -- Properties
        IF l_tables > 0 THEN
          tab_prop_sec;
        END IF;

        -- Physical Properties
        IF l_tables > 0 THEN
          tab_phy_prop_sec;
        END IF;

        -- Constraints
        IF l_table_cons > 0 THEN
          tab_cons_sec;
        END IF;

        -- Columns
        IF l_table_columns > 0 THEN
          tab_cols_sec;
        END IF;

        -- Indexed Columns
        IF l_index_cols > 0 THEN
          indexed_columns_sec;
        END IF;

        -- Histograms
        IF l_table_hgrm > 0 THEN
          tab_col_hgrm_sec;
        END IF;

        -- Histogram Versions (on Column Summary)
        IF l_table_hgrm_vers > 0 THEN
          tab_col_hgrm_vers_sec;
        END IF;

        -- EBS Histograms
        IF l_ebs_hgrm > 0 THEN
          ebs_hgrm_sec;
        END IF;

        -- Partitioning Columns (on Table Summary)
        IF l_table_part_key > 0 THEN
          table_part_key_sec;
        END IF;

        -- Partitions
        IF l_table_part > 0 THEN
          tab_part_sec;
        END IF;

        -- Indexes
        IF l_indexes > 0 THEN
          index_sum_sec;
          IF l_index_part > 0 THEN
            idx_part_sec;
          END IF;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.body.3rd.tables: '||SQLERRM);
      END;

      -- 3rd column - Objects Section
      BEGIN
        -- Objects
        IF l_objects > 0 THEN
          objects_sec;
        END IF;

        -- Dependencies
        IF l_dependencies > 0 THEN
          dependencies_sec;
        END IF;

        -- Fixed Objects
        IF l_fixed_objects > 0 THEN
          fixed_obj_sec;
        END IF;

        -- Fixed Object Columns
        IF l_fixed_object_columns > 0 THEN
          fixed_obj_cols_sec;
        END IF;

        -- Fixed Objects
        IF l_nested_tables > 0 THEN
          nested_tables_sec;
        END IF;

        -- Policies
        IF l_policies > 0 THEN
          policies_sec;
        END IF;

        -- Audit Policies
        IF l_audit_policies > 0 THEN
          audit_policies_sec;
        END IF;

        -- Tablespaces
        tablespaces_sec;

        -- Metadata
        IF l_metadata > 0 AND s_metadata = 'Y' THEN
          metadata_sec;
        END IF;
		
        -- 12.1.04 Column Usage Report 
        IF l_col_group_usage_report > 0 THEN
          colusage_report_sec;
        END IF;		
		
      EXCEPTION
        WHEN OTHERS THEN
          write_error('main_report.body.3rd.objects: '||SQLERRM);
      END;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('main_report.body: '||SQLERRM);
    END;

    -- report footer
    BEGIN
      s_sql_rec.tool_end_date := SYSDATE;
      wa(
      LF||'<hr size="3">'||
      LF||font(doc_id(NOTE_NUMBER)||' '||TOOL_NAME||' '||s_sql_rec.method||' '||sqlt$a.get_param('tool_version')||' secs:'||TO_CHAR(ROUND((s_sql_rec.tool_end_date - s_sql_rec.tool_start_date) * 24 * 60 * 60), SECONDS_FORMAT)||' sqlt_end: '||TO_CHAR(s_sql_rec.tool_end_date, LOAD_DATE_FORMAT), 'f')||
      LF||font('tool_date: '||sqlt$a.get_param('tool_date')||NBSP2||'install_date: '||sqlt$a.get_param('install_date'), 'f')||
      LF||LF||'</body>'||
      LF||LF||'</html>'
      );
    EXCEPTION
      WHEN OTHERS THEN
        write_error('main_report.footer: '||SQLERRM);
    END;

    -- close file
    BEGIN
      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id  => p_statement_id,
        p_file_type     => 'MAIN_REPORT',
        p_filename      => s_file_rec.filename,
        p_statid        => s_file_rec.statid,
        p_statement_id2 => p_group_id,
        p_db_link       => p_db_link,
        p_file_size     => s_file_rec.file_size,
        p_file_text     => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET --tool_end_date = s_sql_rec.tool_end_date,
             file_sqlt_main = s_file_rec.filename
       WHERE statement_id = p_statement_id;
      COMMIT;

      write_log('generated '||s_file_rec.filename);
    EXCEPTION
      WHEN OTHERS THEN
        write_error('main_report.close: '||SQLERRM);
    END;

    write_log('<= main_report');
  END main_report;

  /*************************************************************************************/

  /* -------------------------
   *
   * public main_report_root
   *
   * called by: sqlt$i.common_calls, sqlt$i.remote_xtract and sqlt/utl/sqltmain.sql
   *
   * ------------------------- */
  PROCEDURE main_report_root (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    l_file_size NUMBER;
    l_max_file_size NUMBER;

    PROCEDURE execute_main_report
    IS
    BEGIN
      main_report (
        p_statement_id        => p_statement_id,
        p_group_id            => p_group_id,
        p_db_link             => p_db_link,
        p_file_prefix         => p_file_prefix,
        p_out_file_identifier => p_out_file_identifier );

      l_file_size := sqlt$e.get_file_size_from_repo (
        p_file_type    => 'MAIN_REPORT',
        p_statement_id => p_statement_id );

      write_log('main_report max_file_size: '||l_max_file_size||'B ('||ROUND(l_max_file_size / 1024)||'KB) ('||ROUND(l_max_file_size / 1024 / 1024)||'MB)');
      write_log('main_report current_size : '||l_file_size||'B ('||ROUND(l_file_size / 1024)||'KB) ('||ROUND(l_file_size / 1024 / 1024)||'MB)');
    END execute_main_report;

  BEGIN
    write_log('=> main_report_root');

    -- initialize
    s_scaling_factor := 1;
    sqlt$a.s_overlib := 'Y';
    s_in_pred := 'Y';
    s_sql_text := 'Y';
    s_go_to := 'Y';
    s_metadata := 'Y';
    -- moved here from main_report
    sqlt$a.common_initialization;
    sqlt$t.temp_transformation(p_statement_id);
    sqlt$h.health_check(p_statement_id);

    -- first try. if size is adequate then this is it
    l_max_file_size := ROUND((sqlt$a.get_param_n('sqlt_max_file_size_mb') * 1024 * 1024) / 2);
    execute_main_report;

    -- if main report is too large then scale down all lists
    IF l_file_size > l_max_file_size THEN
      write_log('resizing main_report 1: scale down all lists by 0.5');
      s_scaling_factor := 0.5;
      execute_main_report;
    ELSE
      write_log('no need to resize 1: scale down all lists by 0.5');
    END IF;

    -- if main report is too large then strip go_to
    IF l_file_size > l_max_file_size THEN
      write_log('resizing main_report 2: turn off go_to');
      s_go_to := 'N';
      execute_main_report;
    ELSE
      write_log('no need to resize 2: turn off go_to');
    END IF;

    -- if main report is too large then strip overlib
    IF l_file_size > l_max_file_size THEN
      write_log('resizing main_report 3: turn off overlib');
      sqlt$a.s_overlib := 'N';
      execute_main_report;
    ELSE
      write_log('no need to resize 3: turn off overlib');
    END IF;

    -- if main report is too large then scale down all lists
    IF l_file_size > l_max_file_size THEN
      write_log('resizing main_report 4: scale down all lists by 0.25');
      s_scaling_factor := 0.25;
      execute_main_report;
    ELSE
      write_log('no need to resize 4: scale down all lists by 0.25');
    END IF;

    -- if main report is too large then strip in_pred
    IF l_file_size > l_max_file_size THEN
      write_log('resizing main_report 5: turn off in_pred');
      s_in_pred := 'N';
      execute_main_report;
    ELSE
      write_log('no need to resize 5: turn off in_pred');
    END IF;

    -- if main report is too large then strip sql_text
    IF l_file_size > l_max_file_size THEN
      write_log('resizing main_report 6: turn off sql_text');
      s_sql_text := 'N';
      execute_main_report;
    ELSE
      write_log('no need to resize 6: turn off sql_text');
    END IF;

    -- if main report is too large then scale down all lists
    IF l_file_size > l_max_file_size THEN
      write_log('resizing main_report 7: scale down all lists by 0.125');
      s_scaling_factor := 0.125;
      execute_main_report;
    ELSE
      write_log('no need to resize 7: scale down all lists by 0.125');
    END IF;

    -- if main report is too large then strip metadata
    IF l_file_size > l_max_file_size THEN
      write_log('resizing main_report 8: turn off metadata');
      s_metadata := 'N';
      execute_main_report;
    ELSE
      write_log('no need to resize 8: turn off metadata');
    END IF;

    -- if main report is too large then scale down all lists
    IF l_file_size > l_max_file_size THEN
      write_log('resizing main_report 9: scale down all lists by 0.05');
      s_scaling_factor := 0.05;
      execute_main_report;
    ELSE
      write_log('no need to resize 9: scale down all lists by 0.05');
    END IF;

    write_log('<= main_report_root');
  END main_report_root;

  /*************************************************************************************/

END sqlt$m;
/

SET TERM ON;
SHOW ERRORS PACKAGE BODY &&tool_administer_schema..sqlt$m;
