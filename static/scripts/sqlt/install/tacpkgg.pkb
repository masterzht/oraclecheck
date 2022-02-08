CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..trca$g AS
/* $Header: 224270.1 tacpkgg.pkb 12.1.14 2015/12/06 carlos.sierra mauro.pagano abel.macias@oracle.com $ */

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  TOOL_REPOSITORY_SCHEMA CONSTANT VARCHAR2(32) := '&&tool_repository_schema.';
  TOOL_ADMINISTER_SCHEMA CONSTANT VARCHAR2(32) := '&&tool_administer_schema.';
  ROLE_NAME              CONSTANT VARCHAR2(32) := '&&role_name.';
  LF                     CONSTANT CHAR(1)      := CHR(10); -- line feed
  CR                     CONSTANT CHAR(1)      := CHR(13); -- carriage return
  TAB                    CONSTANT CHAR(1)      := CHR(9);
  BACKSLASH              CONSTANT CHAR(1)      := CHR(92); -- backslash
  AMP                    CONSTANT CHAR(1)      := CHR(38);
  HLT                    CONSTANT VARCHAR2(10) := AMP||'lt;';
  HGT                    CONSTANT VARCHAR2(10) := AMP||'gt;';
  HQUOT                  CONSTANT VARCHAR2(10) := AMP||'quot;';
  HAPOS                  CONSTANT VARCHAR2(10) := AMP||'#039;';
  EOF                    CONSTANT INTEGER      := -1;
  THIS_INSTANCE          CONSTANT INTEGER      := TRUNC(TO_NUMBER(SYS_CONTEXT('USERENV', 'INSTANCE')));

  /*************************************************************************************/

  /* -------------------------
   *
   * private static
   *
   * ------------------------- */
  s_file_rec trca$_file%ROWTYPE;
  s_rindex BINARY_INTEGER; -- set_session_longops
  s_slno BINARY_INTEGER; -- set_session_longops

  /*************************************************************************************/
  
  /* -------------------------
   *
   * public g_tool_repository_schema
   *
   * 22170178 new
   * 
   * ------------------------- */
  
  FUNCTION g_tool_repository_schema 
    RETURN VARCHAR2
  IS
  BEGIN
   return TOOL_REPOSITORY_SCHEMA;
  END;
	
  /*************************************************************************************/

  /* -------------------------
   *
   * private is_user_in_role
   *
   * called by validate_user
   *
   * ------------------------- */
  FUNCTION is_user_in_role (
    p_granted_role IN VARCHAR2,
    p_user         IN VARCHAR2 DEFAULT USER )
  RETURN VARCHAR2
  IS
    l_return VARCHAR2(3);
  BEGIN
    SELECT 'YES'
      INTO l_return
      FROM sys.dba_role_privs
     WHERE grantee = p_user
       AND granted_role = p_granted_role;
    RETURN l_return;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'NO';
  END is_user_in_role;

  /*************************************************************************************/

  /* -------------------------
   *
   * public validate_user
   *
   * called by trca$i.trcanlzr
   *
   * ------------------------- */
  PROCEDURE validate_user (p_user IN VARCHAR2 DEFAULT USER)
  IS
  BEGIN
    IF is_user_in_role(ROLE_NAME, p_user) = 'YES' OR is_user_in_role('DBA', p_user) = 'YES' THEN
      RETURN;
    ELSE
      RAISE_APPLICATION_ERROR (-20326, 'User "'||p_user||'" lacks "'||ROLE_NAME||'" or "DBA" roles. GRANT "'||ROLE_NAME||'" to "'||p_user||'".', TRUE);
    END IF;
  END validate_user;

  /*************************************************************************************/

  /* -------------------------
   *
   * public reset_session_longops
   *
   * ------------------------- */
  PROCEDURE reset_session_longops
  IS
  BEGIN
    s_rindex := SYS.DBMS_APPLICATION_INFO.SET_SESSION_LONGOPS_NOHINT; -- initialize to -1
  END reset_session_longops;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_session_longops
   *
   * ------------------------- */
  PROCEDURE set_session_longops (
    p_op_name     IN VARCHAR2       DEFAULT NULL,
    p_target      IN BINARY_INTEGER DEFAULT 0,
    p_sofar       IN NUMBER         DEFAULT 0,
    p_totalwork   IN NUMBER         DEFAULT 0,
    p_target_desc IN VARCHAR2       DEFAULT 'unknown target',
    p_units       IN VARCHAR2       DEFAULT NULL )
  IS
    l_percent NUMBER;
  BEGIN
    IF s_rindex IS NULL THEN
      reset_session_longops;
    END IF;

    IF p_totalwork > 0 AND p_sofar >= 0 THEN
      l_percent := ROUND(p_sofar * 100 / p_totalwork);
    ELSE
      l_percent := 0;
    END IF;

    SYS.DBMS_APPLICATION_INFO.SET_SESSION_LONGOPS (
      rindex      => s_rindex, -- IN OUT (id on V$SESSION_LONGOPS)
      slno        => s_slno, -- IN OUT (internal use)
      op_name     => SUBSTR(p_op_name, 1, 64),
      target      => p_target,
      context     => l_percent,
      sofar       => p_sofar,
      totalwork   => p_totalwork,
      target_desc => SUBSTR(NVL(p_target_desc, 'unknown target'), 1, 32),
      units       => SUBSTR(p_units, 1, 32) );
  END set_session_longops;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_module
   *
   * ------------------------- */
  PROCEDURE set_module (
    p_module_name IN VARCHAR2 DEFAULT NULL,
    p_action_name IN VARCHAR2 DEFAULT NULL )
  IS
  BEGIN
    SYS.DBMS_APPLICATION_INFO.SET_MODULE (
      module_name => SUBSTR(p_module_name, 1, 64),
      action_name => SUBSTR(p_action_name, 1, 64) );
  END set_module;

  /*************************************************************************************/

  /* -------------------------
   *
   * public print_log
   *
   * ------------------------- */
  PROCEDURE print_log (
    p_buffer    IN VARCHAR2,
    p_package   IN VARCHAR2 DEFAULT 'G',
    p_timestamp IN VARCHAR2 DEFAULT 'Y')
  IS
    l_buffer VARCHAR2(32767);

  BEGIN /* print_log */
    set_module(p_module_name => LOWER(TRIM(g_tool_administer_schema)||'.trca$'||p_package), p_action_name => p_buffer);

    IF NOT g_log_open THEN
      SYS.DBMS_OUTPUT.PUT_LINE(SUBSTR(p_buffer, 1, 255));
      RETURN;
    END IF;

    IF p_timestamp = 'Y' THEN
      l_buffer := TO_CHAR(SYSDATE, 'HH24:MI:SS')||' '||p_buffer;
    ELSE
      l_buffer := p_buffer;
    END IF;

    BEGIN
      SYS.DBMS_LOB.WRITEAPPEND (
        lob_loc => s_file_rec.file_text,
        amount  => LENGTH(l_buffer) + 1,
        buffer  => LF||l_buffer );
    EXCEPTION
      WHEN OTHERS THEN
        SYS.DBMS_OUTPUT.PUT_LINE('***');
        SYS.DBMS_OUTPUT.PUT_LINE('*** SYS.DBMS_LOB.WRITEAPPEND');
        SYS.DBMS_OUTPUT.PUT_LINE('*** Module: trca$g.print_log');
        SYS.DBMS_OUTPUT.PUT_LINE('*** Buffer: '||SUBSTR(l_buffer, 1, 200));
        SYS.DBMS_OUTPUT.PUT_LINE('*** '||SQLERRM);
        SYS.DBMS_OUTPUT.PUT_LINE('***');
        RAISE;
    END;

    SYS.DBMS_OUTPUT.PUT_LINE(SUBSTR(l_buffer, 1, 255));
  END print_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * public open_log
   *
   * called by trca$i.trcanlzr
   *
   * ------------------------- */
  PROCEDURE open_log (
    p_tool_execution_id   IN INTEGER,
    p_file_name           IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    l_file_name VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);

  BEGIN /* open_log */
    IF g_log_open THEN
      RETURN;
    END IF;

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_name LIKE '%.%' THEN
      l_file_name := p_file_name;
    ELSE
      l_file_name := p_file_name||'trca_e'||p_tool_execution_id||l_out_file_identifier||'.log';
    END IF;

    UPDATE trca$_tool_execution
       SET log_file_name = l_file_name
     WHERE id = p_tool_execution_id;
    COMMIT;

    s_file_rec := NULL;
    s_file_rec.tool_execution_id := p_tool_execution_id;
    s_file_rec.file_type := 'LOG';
    s_file_rec.filename := l_file_name;
    s_file_rec.file_date := SYSDATE;
    s_file_rec.username := USER;
    s_file_rec.file_text := g_tool_name||' '||g_tool_version||' installed on '||g_install_date;

    g_log_open := TRUE;

    print_log('Execution ID: '||p_tool_execution_id||' started at '||TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'), p_timestamp => 'N');
    print_log('In case of premature termination, read trcanlzr_error.log located in SQL*Plus default directory', p_timestamp => 'N');
    print_log('/*************************************************************************************/', p_timestamp => 'N');
  END open_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * public close_log
   *
   * ------------------------- */
  PROCEDURE close_log (
    p_tool_execution_id IN  INTEGER,
    x_log               OUT CLOB )
  IS
  BEGIN /* close_log */
    IF NOT g_log_open THEN
      RETURN;
    END IF;

    print_log('/*************************************************************************************/', p_timestamp => 'N');
    print_log('Trace Analyzer executed successfully.', p_timestamp => 'N');
    print_log('There are no fatal errors in this log file.', p_timestamp => 'N');
    print_log('Execution ID: '||p_tool_execution_id||' completed at '||TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'), p_timestamp => 'N');

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    INSERT INTO trca$_file VALUES s_file_rec;
    COMMIT;

    x_log := s_file_rec.file_text;
    g_log_open := FALSE;
  END close_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * public call_type_binds
   *
   * ------------------------- */
  FUNCTION call_type_binds
  RETURN VARCHAR2
  IS
  BEGIN /* call_type_binds */
    RETURN CALL_BINDS;
  END call_type_binds;

  /*************************************************************************************/

  /* -------------------------
   *
   * public call_type_parse
   *
   * ------------------------- */
  FUNCTION call_type_parse
  RETURN VARCHAR2
  IS
  BEGIN /* call_type_parse */
    RETURN CALL_PARSE;
  END call_type_parse;

  /*************************************************************************************/

  /* -------------------------
   *
   * public call_type_exec
   *
   * ------------------------- */
  FUNCTION call_type_exec
  RETURN VARCHAR2
  IS
  BEGIN /* call_type_exec */
    RETURN CALL_EXEC;
  END call_type_exec;

  /*************************************************************************************/

  /* -------------------------
   *
   * public call_type_unmap
   *
   * ------------------------- */
  FUNCTION call_type_unmap
  RETURN VARCHAR2
  IS
  BEGIN /* call_type_unmap */
    RETURN CALL_UNMAP;
  END call_type_unmap;

  /*************************************************************************************/

  /* -------------------------
   *
   * public call_type_sort_unmap
   *
   * ------------------------- */
  FUNCTION call_type_sort_unmap
  RETURN VARCHAR2
  IS
  BEGIN /* call_type_sort_unmap */
    RETURN CALL_SORT_UNMAP;
  END call_type_sort_unmap;

  /*************************************************************************************/

  /* -------------------------
   *
   * public call_type_fetch
   *
   * ------------------------- */
  FUNCTION call_type_fetch
  RETURN VARCHAR2
  IS
  BEGIN /* call_type_fetch */
    RETURN CALL_FETCH;
  END call_type_fetch;

  /*************************************************************************************/

  /* -------------------------
   *
   * public call_type_total
   *
   * ------------------------- */
  FUNCTION call_type_total
  RETURN VARCHAR2
  IS
  BEGIN /* call_type_total */
    RETURN CALL_TOTAL;
  END call_type_total;

  /*************************************************************************************/

  /* -------------------------
   *
   * public call_type
   *
   * ------------------------- */
  FUNCTION call_type (
    p_call IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN /* call_type */
    IF p_call = CALL_BINDS THEN
      RETURN 'Binds';
    ELSIF p_call = CALL_PARSE THEN
      RETURN 'Parse';
    ELSIF p_call = CALL_EXEC THEN
      RETURN 'Execute';
    ELSIF p_call = CALL_UNMAP THEN
      RETURN 'Unmap';
    ELSIF p_call = CALL_SORT_UNMAP THEN
      RETURN 'Sort Unmap';
    ELSIF p_call = CALL_FETCH THEN
      RETURN 'Fetch';
    ELSIF p_call = CALL_TOTAL THEN
      RETURN 'Total';
    ELSE
      RETURN NULL;
    END IF;
  END call_type;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_directory_path
   *
   * ------------------------- */
  FUNCTION get_directory_path (
    p_directory_name IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_directory_path VARCHAR2(32767);

  BEGIN /* get_directory_path */
    SELECT directory_path
      INTO l_directory_path
      FROM sys.dba_directories
     WHERE directory_name = UPPER(p_directory_name);

    RETURN l_directory_path;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_directory_path;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_1st_trace_path_n_name
   *
   * ------------------------- */
  FUNCTION get_1st_trace_path_n_name
  RETURN VARCHAR2
  IS
  BEGIN /* get_1st_trace_path_n_name */
    RETURN g_path_and_filename;
  END get_1st_trace_path_n_name;

  /*************************************************************************************/

  /* -------------------------
   *
   * public gather_table_stats
   * 22170178 use TOOL_REPOSITORY_SCHEMA instead of G_TOOL_REPOSITORY_SCHEMA
   * ------------------------- */
  PROCEDURE gather_table_stats (
    p_table_name IN VARCHAR2 )
  IS
  BEGIN /* gather_table_stats */
    IF TO_NUMBER(g_gather_cbo_stats) > 0 AND TOOL_REPOSITORY_SCHEMA LIKE 'TRCA%' THEN
      IF g_log_open THEN
        print_log('-> gather_table_stats: '||LOWER(p_table_name));
      END IF;

      SYS.DBMS_STATS.GATHER_TABLE_STATS (
        ownname          => TOOL_REPOSITORY_SCHEMA,
        tabname          => UPPER(p_table_name),
        estimate_percent => TO_NUMBER(g_gather_cbo_stats),
        method_opt       => 'FOR ALL COLUMNS SIZE 1',
        cascade          => TRUE,
        no_invalidate    => FALSE );
        --force            => TRUE ); -- force is not valid on 9i

      IF g_log_open THEN
        print_log('<- gather_table_stats: '||LOWER(TOOL_REPOSITORY_SCHEMA||'.'||p_table_name));
      END IF;
    ELSE
      IF g_log_open THEN
        print_log('<- gather_table_stats: '||LOWER(TOOL_REPOSITORY_SCHEMA||'.'||p_table_name||' skipped'));
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      IF g_log_open THEN
        print_log('gather_table_stats: '||LOWER(TOOL_REPOSITORY_SCHEMA||'.'||p_table_name)||' '||SQLERRM);
      END IF;
  END gather_table_stats;

  /*************************************************************************************/

  /* -------------------------
   *
   * public format_tim3
   *
   * ------------------------- */
  FUNCTION format_tim3 (
    p_tim IN INTEGER )
  RETURN VARCHAR2
  IS
  BEGIN /* format_tim3 */
    RETURN TO_CHAR(ROUND(p_tim/TO_NUMBER(g_time_granularity), 3), 'FM9999999999990.000');
  END format_tim3;

  /*************************************************************************************/

  /* -------------------------
   *
   * public format_tim6
   *
   * ------------------------- */
  FUNCTION format_tim6 (
    p_tim IN INTEGER )
  RETURN VARCHAR2
  IS
  BEGIN /* format_tim6 */
    RETURN TO_CHAR(ROUND(p_tim/TO_NUMBER(g_time_granularity), 6), 'FM9999999999990.000000');
  END format_tim6;

  /*************************************************************************************/

  /* -------------------------
   *
   * public format_perc1
   *
   * ------------------------- */
  FUNCTION format_perc1 (
    p_one IN NUMBER,
    p_two IN NUMBER )
  RETURN VARCHAR2
  IS
  BEGIN /* format_perc1 */
    IF p_two > 0 THEN
      RETURN TO_CHAR(ROUND(p_one * 100 / p_two, 1), 'FM9999999999990.0')||'%';
    ELSE
      RETURN '0.0%';
    END IF;
  END format_perc1;

  /*************************************************************************************/

  /* -------------------------
   *
   * public format_perc1
   *
   * ------------------------- */
  FUNCTION format_perc1 (
    p_one IN NUMBER )
  RETURN VARCHAR2
  IS
  BEGIN /* format_perc1 */
    IF p_one IS NOT NULL THEN
      RETURN TO_CHAR(ROUND(p_one, 1), 'FM9999999999990.0')||'%';
    ELSE
      RETURN NULL;
    END IF;
  END format_perc1;

  /*************************************************************************************/

  /* -------------------------
   *
   * public to_timestamp
   *
   * ------------------------- */
  FUNCTION to_timestamp (
    p_tool_execution_id IN INTEGER,
    p_tim               IN INTEGER )
  RETURN TIMESTAMP
  IS
    l_timestamp TIMESTAMP;
    l_tim       INTEGER;
    l_interval  INTERVAL DAY (6) TO SECOND (6);

  BEGIN /* to_timestamp */
    SELECT MAX(session_tim)
      INTO l_tim
      FROM trca$_session
     WHERE tool_execution_id = p_tool_execution_id
       AND session_tim <= p_tim;

    IF l_tim IS NULL THEN
      SELECT MIN(session_tim)
        INTO l_tim
        FROM trca$_session
       WHERE tool_execution_id = p_tool_execution_id
         AND session_tim > p_tim;
    END IF;

    IF l_tim IS NOT NULL THEN
      SELECT MIN(session_timestamp)
        INTO l_timestamp
        FROM trca$_session
       WHERE tool_execution_id = p_tool_execution_id
         AND session_tim = l_tim;
    ELSE -- last chance
      SELECT start_tim
        INTO l_tim
        FROM trca$_tool_execution
       WHERE id = p_tool_execution_id;

      SELECT MIN(gap_timestamp)
        INTO l_timestamp
        FROM trca$_gap
       WHERE tool_execution_id = p_tool_execution_id;
    END IF;

    IF l_tim IS NULL OR l_timestamp IS NULL THEN
      RETURN NULL;
    END IF;

    l_interval := NUMTODSINTERVAL ((p_tim - l_tim) / TO_NUMBER(g_time_granularity), 'SECOND');

    RETURN l_timestamp + l_interval;
  END to_timestamp;

  /*************************************************************************************/

  /* -------------------------
   *
   * public format_timestamp3
   *
   * ------------------------- */
  FUNCTION format_timestamp3 (
    p_timestamp IN TIMESTAMP )
  RETURN VARCHAR2
  IS
  BEGIN /* format_timestamp3 */
    RETURN TO_CHAR(p_timestamp, 'YYYY-MON-DD HH24:MI:SS.FF3');
  END format_timestamp3;

  /*************************************************************************************/

  /* -------------------------
   *
   * public format_timestamp3h
   *
   * ------------------------- */
  FUNCTION format_timestamp3h (
    p_timestamp IN TIMESTAMP )
  RETURN VARCHAR2
  IS
  BEGIN /* format_timestamp3h */
    RETURN TO_CHAR(p_timestamp, 'HH24:MI:SS.FF3');
  END format_timestamp3h;

  /*************************************************************************************/

  /* -------------------------
   *
   * public format_timestamp3m
   *
   * ------------------------- */
  FUNCTION format_timestamp3m (
    p_timestamp IN TIMESTAMP )
  RETURN VARCHAR2
  IS
  BEGIN /* format_timestamp3m */
    RETURN TO_CHAR(p_timestamp, 'MON-DD HH24:MI:SS.FF3');
  END format_timestamp3m;

  /*************************************************************************************/

  /* -------------------------
   *
   * public flatten_text
   *
   * ------------------------- */
  FUNCTION flatten_text (
    p_text IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_text VARCHAR2(32767) := p_text;
  BEGIN /* flatten_text */
    l_text := REPLACE(l_text, LF, ' ');
    l_text := REPLACE(l_text, CR, ' ');
    l_text := REPLACE(l_text, TAB, ' ');

    l_text := REPLACE(l_text, '               ', ' ');
    l_text := REPLACE(l_text, '           ', ' ');
    l_text := REPLACE(l_text, '       ', ' ');
    l_text := REPLACE(l_text, '     ', ' ');
    l_text := REPLACE(l_text, '    ', ' ');
    l_text := REPLACE(l_text, '   ', ' ');
    l_text := REPLACE(l_text, '  ', ' ');

    RETURN l_text;
  END flatten_text;

  /*************************************************************************************/

  /* -------------------------
   *
   * public prepare_html_text
   *
   * ------------------------- */
  FUNCTION prepare_html_text (
    p_text IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN /* prepare_html_text */
    RETURN REPLACE(REPLACE(REPLACE(REPLACE(p_text, '''', HAPOS), '"', HQUOT), '<', HLT), '>', HGT);
  END prepare_html_text;

  /*************************************************************************************/

  /* -------------------------
   *
   * public wrap_text
   *
   * ------------------------- */
  FUNCTION wrap_text (
    p_clob         IN CLOB,
    p_max_line_len IN INTEGER  DEFAULT 250,
    p_add_br       IN VARCHAR2 DEFAULT 'N',
    p_lt_gt_quote  IN VARCHAR2 DEFAULT 'N' )
  RETURN CLOB
  IS
    l_clob_len INTEGER;
    l_remainder INTEGER;
    l_offset INTEGER;
    l_line_len INTEGER;
    l_clob CLOB;
    l_buffer VARCHAR2(32767);

    PROCEDURE writeappend (
      p_buffer IN VARCHAR2 )
    IS
      my_buffer VARCHAR2(32767) := p_buffer;
    BEGIN /* writeappend */
      IF p_lt_gt_quote = 'Y' THEN
        my_buffer := prepare_html_text(my_buffer);
      END IF;
      IF  p_add_br = 'Y' THEN
        my_buffer := my_buffer||'<br>';
      END IF;
      my_buffer := my_buffer||LF;
      SYS.DBMS_LOB.WRITEAPPEND(l_clob, LENGTH(my_buffer), my_buffer);
    END writeappend;

  BEGIN /* wrap_text */
    -- initialization
    IF p_clob IS NULL THEN
      RETURN NULL;
    END IF;
    l_clob_len := SYS.DBMS_LOB.GETLENGTH(lob_loc => p_clob);
    IF NVL(l_clob_len, 0) = 0 THEN
      RETURN NULL;
    END IF;
    l_remainder := l_clob_len;
    l_offset := 1;
    SYS.DBMS_LOB.CREATETEMPORARY (
      lob_loc => l_clob,
      cache   => TRUE,
      dur     => SYS.DBMS_LOB.CALL );

    -- loop through CLOB
    WHILE l_remainder > 0
    LOOP
      l_line_len := INSTR(p_clob, LF, l_offset) - l_offset + 1;
      IF l_line_len BETWEEN 1 AND p_max_line_len THEN
        l_buffer := SUBSTR(p_clob, l_offset, l_line_len - 1);
        writeappend(l_buffer);
      ELSE
        l_line_len := INSTR(p_clob, '),', (l_offset + p_max_line_len - l_clob_len - 2)) - l_offset + 2;
        IF l_line_len BETWEEN 2 AND p_max_line_len THEN
          l_buffer := SUBSTR(p_clob, l_offset, l_line_len);
          writeappend(l_buffer);
        ELSE
          l_line_len := INSTR(p_clob, ') ', (l_offset + p_max_line_len - l_clob_len - 2)) - l_offset + 2;
          IF l_line_len BETWEEN 2 AND p_max_line_len THEN
            l_buffer := SUBSTR(p_clob, l_offset, l_line_len);
            writeappend(l_buffer);
          ELSE
            l_line_len := INSTR(p_clob, ' ', (l_offset + p_max_line_len - l_clob_len - 1)) - l_offset + 1;
            IF l_line_len BETWEEN 1 AND p_max_line_len THEN
              l_buffer := SUBSTR(p_clob, l_offset, l_line_len);
              writeappend(l_buffer);
            ELSE
              l_line_len := INSTR(p_clob, '/', (l_offset + p_max_line_len - l_clob_len - 1)) - l_offset + 1;
              IF l_line_len BETWEEN 1 AND p_max_line_len THEN
                l_buffer := SUBSTR(p_clob, l_offset, l_line_len);
                writeappend(l_buffer);
              ELSE
                l_line_len := INSTR(p_clob, ')', (l_offset + p_max_line_len - l_clob_len - 1)) - l_offset + 1;
                IF l_line_len BETWEEN 1 AND p_max_line_len THEN
                  l_buffer := SUBSTR(p_clob, l_offset, l_line_len);
                  writeappend(l_buffer);
                ELSE
                  l_line_len := INSTR(p_clob, ',', (l_offset + p_max_line_len - l_clob_len - 1)) - l_offset + 1;
                  IF l_line_len BETWEEN 1 AND p_max_line_len THEN
                    l_buffer := SUBSTR(p_clob, l_offset, l_line_len);
                    writeappend(l_buffer);
                  ELSE
                    l_line_len := p_max_line_len;
                    l_buffer := SUBSTR(p_clob, l_offset, l_line_len);
                    writeappend(l_buffer);
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;
      END IF;

      -- update pointers
      l_remainder := l_remainder - l_line_len;
      l_offset := l_offset + l_line_len;
    END LOOP;

    RETURN l_clob;
  END wrap_text;

  /*************************************************************************************/

  /* -------------------------
   *
   * public wrap_clob
   *
   * returns a clob file regulating its width to a desired value
   * so it can be used by utl_file or to display width-controlled html.
   *
   * ------------------------- */
  FUNCTION wrap_clob (
    p_clob          IN CLOB,
    p_max_line_size IN INTEGER DEFAULT 80 )
  RETURN CLOB
  IS
    l_clob CLOB;
    my_chunk_size NUMBER;
    my_char_buffer VARCHAR2(32767);
    l_offset INTEGER := 1;
    buffer_LF_ptr NUMBER;

  BEGIN
    SYS.DBMS_LOB.CREATETEMPORARY(l_clob, TRUE);

    -- break line at {"LF", ")", ",", "/", "BACKSLASH", " "}
    WHILE l_offset < SYS.DBMS_LOB.GETLENGTH(p_clob)
    LOOP
      my_chunk_size := LEAST(p_max_line_size, SYS.DBMS_LOB.GETLENGTH(p_clob) - l_offset + 1);
      IF my_chunk_size > 0 THEN
        SYS.DBMS_LOB.READ(p_clob, my_chunk_size, l_offset, my_char_buffer);
        BEGIN
          IF my_chunk_size <> p_max_line_size THEN -- last piece
            SYS.DBMS_LOB.WRITEAPPEND(l_clob, LENGTH(my_char_buffer), my_char_buffer);
            l_offset := SYS.DBMS_LOB.GETLENGTH(p_clob) + 1; -- signals eof
          ELSE
            buffer_LF_ptr := INSTR(my_char_buffer, LF, -1); -- last LF on chunk
            IF buffer_LF_ptr > 0 THEN -- there was at least one LF within chunk
              SYS.DBMS_LOB.WRITEAPPEND(l_clob, buffer_LF_ptr, my_char_buffer); -- includes last LF
              l_offset := l_offset + buffer_LF_ptr;
            ELSE
              buffer_LF_ptr := INSTR(my_char_buffer, ')', -1); -- last ")" on chunk
              IF buffer_LF_ptr > 0 THEN -- there was at least one ")" within chunk
                SYS.DBMS_LOB.WRITEAPPEND(l_clob, buffer_LF_ptr + 1, SUBSTR(my_char_buffer, 1, buffer_LF_ptr)||LF); -- includes last ")"
                l_offset := l_offset + buffer_LF_ptr;
              ELSE
                buffer_LF_ptr := INSTR(my_char_buffer, ',', -1); -- last "," on chunk
                IF buffer_LF_ptr > 0 THEN -- there was at least one "," within chunk
                  SYS.DBMS_LOB.WRITEAPPEND(l_clob, buffer_LF_ptr + 1, SUBSTR(my_char_buffer, 1, buffer_LF_ptr)||LF); -- includes last ","
                  l_offset := l_offset + buffer_LF_ptr;
                ELSE
                 buffer_LF_ptr := INSTR(my_char_buffer, '/', -1); -- last "/" on chunk
                 IF buffer_LF_ptr > 0 THEN -- there was at least one "/" within chunk
                   SYS.DBMS_LOB.WRITEAPPEND(l_clob, buffer_LF_ptr + 1, SUBSTR(my_char_buffer, 1, buffer_LF_ptr)||LF); -- includes last "/"
                   l_offset := l_offset + buffer_LF_ptr;
                 ELSE
                   buffer_LF_ptr := INSTR(my_char_buffer, BACKSLASH, -1); -- last BACKSLASH on chunk
                   IF buffer_LF_ptr > 0 THEN -- there was at least one BACKSLASH within chunk
                     SYS.DBMS_LOB.WRITEAPPEND(l_clob, buffer_LF_ptr + 1, SUBSTR(my_char_buffer, 1, buffer_LF_ptr)||LF); -- includes last BACKSLASH
                     l_offset := l_offset + buffer_LF_ptr;
                   ELSE
                     buffer_LF_ptr := INSTR(my_char_buffer, ' ', -1); -- last " " on chunk
                     IF buffer_LF_ptr > 0 THEN -- there was at least one " " within chunk
                       SYS.DBMS_LOB.WRITEAPPEND(l_clob, buffer_LF_ptr + 1, SUBSTR(my_char_buffer, 1, buffer_LF_ptr)||LF); -- includes last " "
                       l_offset := l_offset + buffer_LF_ptr;
                     ELSE
                       SYS.DBMS_LOB.WRITEAPPEND(l_clob, LENGTH(my_char_buffer) + 1, my_char_buffer||LF);
                       l_offset := l_offset + my_chunk_size;
                     END IF;
                   END IF;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            print_log(SQLERRM);
            print_log(my_char_buffer);
            l_offset := l_offset + my_chunk_size;
        END;
      ELSE
        l_offset := SYS.DBMS_LOB.GETLENGTH(p_clob) + 1;
      END IF;
    END LOOP;

    RETURN l_clob;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'cannot wrap clob: '||SQLERRM;
  END wrap_clob;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_file_from_repo
   *
   * ------------------------- */
  FUNCTION get_file_from_repo (
    p_tool_execution_id IN INTEGER,
    p_file_type         IN VARCHAR2 ) -- HTML, TEXT, LOG, 10053, 10046
  RETURN trca$_file%ROWTYPE
  IS
    file_rec trca$_file%ROWTYPE;
  BEGIN
    SELECT *
      INTO file_rec
      FROM trca$_file
     WHERE tool_execution_id = p_tool_execution_id
       AND file_type = p_file_type;

    RETURN file_rec;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20205, 'Missing file "'||p_tool_execution_id||'" "'||p_file_type||'"');
  END get_file_from_repo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public display_file
   *
   * outputs content of file using pipe
   *
   * ------------------------- */
  FUNCTION display_file (
    p_tool_execution_id IN INTEGER,
    p_file_type         IN VARCHAR2, -- HTML, TEXT, LOG, 10053, 10046
    p_max_line_size     IN INTEGER DEFAULT 2000 )
  RETURN varchar2_table PIPELINED
  IS
    file_rec trca$_file%ROWTYPE;
    my_chunk_size INTEGER;
    my_char_buffer VARCHAR2(32767);
    l_offset INTEGER := 1;
    buffer_LF_ptr INTEGER;

  BEGIN
    BEGIN
      file_rec := get_file_from_repo(p_tool_execution_id, p_file_type);
    EXCEPTION
      WHEN OTHERS THEN
        PIPE ROW(SQLERRM);
        RETURN; -- needed by pipelined functions
    END;

    IF USER NOT IN ('SYS', 'SYSTEM', file_rec.username) THEN
      PIPE ROW('To download this file you must connect as "SYS", "SYSTEM", or "'||file_rec.username||'"');
      RETURN; -- needed by pipelined functions
    END IF;

    SYS.DBMS_LOB.OPEN(file_rec.file_text, SYS.DBMS_LOB.FILE_READONLY);

    -- break line at {"LF", ">", ")", ",", " "}
    WHILE l_offset < file_rec.file_size
    LOOP
      my_chunk_size := LEAST(p_max_line_size, file_rec.file_size - l_offset + 1);
      IF my_chunk_size > 0 THEN
        SYS.DBMS_LOB.READ(file_rec.file_text, my_chunk_size, l_offset, my_char_buffer);
        BEGIN
          IF my_chunk_size <> p_max_line_size THEN -- last piece
            PIPE ROW(my_char_buffer);
            l_offset := file_rec.file_size; -- signals eof
          ELSE
            buffer_LF_ptr := INSTR(my_char_buffer, LF, -1); -- last LF on chunk
            IF buffer_LF_ptr > 0 THEN -- there was at least one LF within chunk
              PIPE ROW(SUBSTR(my_char_buffer, 1, buffer_LF_ptr - 1)); -- excludes last LF
              l_offset := l_offset + buffer_LF_ptr;
            ELSE
              buffer_LF_ptr := INSTR(my_char_buffer, '>', -1); -- last ">" on chunk
              IF buffer_LF_ptr > 0 THEN -- there was at least one ">" within chunk
                PIPE ROW(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last ">"
                l_offset := l_offset + buffer_LF_ptr;
              ELSE
                buffer_LF_ptr := INSTR(my_char_buffer, ')', -1); -- last ")" on chunk
                IF buffer_LF_ptr > 0 THEN -- there was at least one ")" within chunk
                  PIPE ROW(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last ")"
                  l_offset := l_offset + buffer_LF_ptr;
                ELSE
                  buffer_LF_ptr := INSTR(my_char_buffer, ',', -1); -- last "," on chunk
                  IF buffer_LF_ptr > 0 THEN -- there was at least one "," within chunk
                    PIPE ROW(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last ","
                    l_offset := l_offset + buffer_LF_ptr;
                  ELSE
                    buffer_LF_ptr := INSTR(my_char_buffer, ' ', -1); -- last " " on chunk
                    IF buffer_LF_ptr > 0 THEN -- there was at least one " " within chunk
                      PIPE ROW(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last " "
                      l_offset := l_offset + buffer_LF_ptr;
                    ELSE -- returns whole buffer which cannot be larger than l_max_line_size
                      PIPE ROW(my_char_buffer);
                      l_offset := l_offset + p_max_line_size;
                    END IF;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            l_offset := l_offset + my_chunk_size;
            PIPE ROW(my_char_buffer);
            PIPE ROW(SQLERRM);
        END;
      ELSE
        l_offset := file_rec.file_size; -- signals eof
      END IF;
    END LOOP;

    SYS.DBMS_LOB.CLOSE(file_rec.file_text);
    RETURN; -- needed by pipelined functions
  EXCEPTION
    WHEN OTHERS THEN
      PIPE ROW('cannot display file "'||p_tool_execution_id||'" "'||p_file_type||'"');
      PIPE ROW(SQLERRM);
      RETURN; -- needed by pipelined functions
  END display_file;

  /*************************************************************************************/

  /* -------------------------
   *
   * public utl_file
   *
   * called by: trca$e.copy_file_from_repo_to_dir and trca$e.copy_files_from_repo_to_dir
   *
   * creates file in OS directory out of a CLOB file
   *
   * ------------------------- */
  PROCEDURE utl_file (
    p_tool_execution_id IN INTEGER,
    p_file_type         IN VARCHAR2, -- HTML, TEXT, LOG, 10053, 10046
    p_directory_name    IN VARCHAR2 DEFAULT 'TRCA$STAGE' )
  IS
    l_max_line_size INTEGER := 2000;
    file_rec trca$_file%ROWTYPE;
    my_chunk_size INTEGER;
    my_char_buffer VARCHAR2(32767);
    l_offset INTEGER := 1;
    buffer_LF_ptr INTEGER;
    out_file_type SYS.UTL_FILE.file_type;

    PROCEDURE put_buffer (
      p_char_buffer IN VARCHAR2,
      p_autoflush   IN BOOLEAN DEFAULT FALSE )
    IS
    BEGIN
      SYS.UTL_FILE.PUT_RAW (
        file      => out_file_type,
        buffer    => SYS.UTL_RAW.CAST_TO_RAW(p_char_buffer) );
    END put_buffer;

  BEGIN
    file_rec := get_file_from_repo(p_tool_execution_id, p_file_type);

    -- removed to avoid raising this error when connected remote into some other user.
    --IF USER NOT IN ('SYS', 'SYSTEM', file_rec.username) THEN
    --  RAISE_APPLICATION_ERROR (-20210, 'To download this file you must connect as "SYS", "SYSTEM", or "'||file_rec.username||'"');
    --END IF;

    SYS.DBMS_LOB.OPEN(file_rec.file_text, SYS.DBMS_LOB.FILE_READONLY);
    out_file_type :=
    SYS.UTL_FILE.FOPEN (
       location     => p_directory_name,
       filename     => file_rec.filename,
       open_mode    => 'WB',
       max_linesize => 32767 );

    -- break line at {"LF", ">", ")", ",", " "}
    WHILE l_offset < file_rec.file_size
    LOOP
      my_chunk_size := LEAST(l_max_line_size, file_rec.file_size - l_offset + 1);
      IF my_chunk_size > 0 THEN
        SYS.DBMS_LOB.READ(file_rec.file_text, my_chunk_size, l_offset, my_char_buffer);
        BEGIN
          IF my_chunk_size <> l_max_line_size THEN -- last piece
            put_buffer(my_char_buffer);
            l_offset := file_rec.file_size; -- signals eof
          ELSE
            buffer_LF_ptr := INSTR(my_char_buffer, LF, -1); -- last LF on chunk
            IF buffer_LF_ptr > 0 THEN -- there was at least one LF within chunk
              put_buffer(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last LF
              l_offset := l_offset + buffer_LF_ptr;
            ELSE
              buffer_LF_ptr := INSTR(my_char_buffer, '>', -1); -- last ">" on chunk
              IF buffer_LF_ptr > 0 THEN -- there was at least one ">" within chunk
                put_buffer(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last ">"
                l_offset := l_offset + buffer_LF_ptr;
              ELSE
                buffer_LF_ptr := INSTR(my_char_buffer, ')', -1); -- last ")" on chunk
                IF buffer_LF_ptr > 0 THEN -- there was at least one ")" within chunk
                  put_buffer(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last ")"
                  l_offset := l_offset + buffer_LF_ptr;
                ELSE
                  buffer_LF_ptr := INSTR(my_char_buffer, ',', -1); -- last "," on chunk
                  IF buffer_LF_ptr > 0 THEN -- there was at least one "," within chunk
                    put_buffer(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last ","
                    l_offset := l_offset + buffer_LF_ptr;
                  ELSE
                    buffer_LF_ptr := INSTR(my_char_buffer, ' ', -1); -- last " " on chunk
                    IF buffer_LF_ptr > 0 THEN -- there was at least one " " within chunk
                      put_buffer(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last " "
                      l_offset := l_offset + buffer_LF_ptr;
                    ELSE -- returns whole buffer which cannot be larger than l_max_line_size
                      put_buffer(my_char_buffer);
                      l_offset := l_offset + l_max_line_size;
                    END IF;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            l_offset := l_offset + my_chunk_size;
            print_log(my_char_buffer);
            print_log(SQLERRM);
        END;
      ELSE
        l_offset := file_rec.file_size; -- signals eof;
      END IF;
    END LOOP;

    SYS.UTL_FILE.FCLOSE(file => out_file_type);
    SYS.DBMS_LOB.CLOSE(file_rec.file_text);
  EXCEPTION
    WHEN OTHERS THEN
      print_log('cannot display file "'||p_tool_execution_id||'" "'||p_file_type||'"');
      print_log(SQLERRM);
  END utl_file;

 /*************************************************************************************/

  /* -------------------------
   *
   * private get_object_status
   *
   * ------------------------- */
  FUNCTION get_object_status (
    p_object_name IN VARCHAR2,
    p_object_type IN VARCHAR2 DEFAULT 'PACKAGE BODY',
    p_owner       IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2
  IS
    l_status VARCHAR2(32767);
    l_directory_path VARCHAR2(32767);
    my_script_version VARCHAR2(32767);

  BEGIN /* get_object_status */
    IF UPPER(p_object_type) = 'DIRECTORY' THEN
      SELECT status
        INTO l_status
        FROM sys.dba_objects
       WHERE object_type = UPPER(p_object_type)
         AND object_name = UPPER(p_object_name)
         AND ROWNUM = 1;

      l_directory_path := get_directory_path(p_object_name);
      IF l_directory_path IS NULL OR l_directory_path LIKE '%?%' OR l_directory_path LIKE '%*%' THEN
        l_status := 'INVALID';
      END IF;

      RETURN l_status;
    ELSE
      SELECT status
        INTO l_status
        FROM sys.dba_objects
       WHERE owner = UPPER(NVL(p_owner, g_tool_administer_schema))
         AND object_type = UPPER(p_object_type)
         AND object_name = UPPER(p_object_name)
         AND ROWNUM = 1;

      IF UPPER(p_object_type) IN ('FUNCTION', 'PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'TRIGGER', 'TYPE', 'TYPE BODY') THEN
        BEGIN
          SELECT ' '||SUBSTR(text, 1, 128)
            INTO my_script_version
            FROM sys.dba_source ds
           WHERE ds.owner = UPPER(NVL(p_owner, g_tool_administer_schema))
             AND ds.name  = UPPER(p_object_name)
             AND ds.type  = UPPER(p_object_type)
             AND ds.line  < 201 /* check only top 200 lines */
             AND (UPPER(ds.text) LIKE ('%$%HEADER%:%') OR UPPER(ds.text) LIKE ('%$%ID%:%'))
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            my_script_version := NULL;
        END;
      ELSE
        my_script_version := NULL;
      END IF;

      RETURN l_status||' '||UPPER(p_object_type)||' '||UPPER(p_object_name)||my_script_version;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_object_status;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_param
   *
   * ------------------------- */
  FUNCTION get_param (
    p_name   IN VARCHAR2,
    p_source IN VARCHAR2 DEFAULT 'U' ) -- (U)ser, (I)nternal
  RETURN VARCHAR2
  IS
    par_rec trca$_tool_parameter%ROWTYPE;

  BEGIN /* get_param */
    BEGIN
      SELECT * INTO par_rec FROM trca$_tool_parameter WHERE name = LOWER(p_name);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        SYS.DBMS_OUTPUT.PUT_LINE('name:'||p_name);
        RAISE;
    END;

    IF p_source = 'U' AND par_rec.hidden = 'Y' THEN
      RAISE_APPLICATION_ERROR (-20100, p_name||' is a hidden parameter');
    END IF;

    RETURN par_rec.value;
  END get_param;

  /*************************************************************************************/

  /* -------------------------
   *
   * private reset_updatable_parameters
   *
   * ------------------------- */
  PROCEDURE reset_updatable_parameters
  IS
  BEGIN /* reset_updatable_parameters */
    g_top_sql_th := get_param('top_sql_th');
    g_top_exec_th := get_param('top_exec_th');
    g_hot_block_th := get_param('hot_block_th');
    g_aggregate := get_param('aggregate');
    g_perform_count_star := get_param('perform_count_star');
    g_count_star_th := get_param('count_star_th');
    g_errors_th := get_param('errors_th');
    g_gaps_th := get_param('gaps_th');
    g_include_internal_sql := get_param('include_internal_sql');
    g_include_non_top_sql := get_param('include_non_top_sql');
    g_include_init_ora := get_param('include_init_ora');
    g_include_waits := get_param('include_waits');
    g_include_binds := get_param('include_binds');
    g_include_fetches := get_param('include_fetches');
    g_include_expl_plans := get_param('include_expl_plans');
    g_include_segments := get_param('include_segments');
    g_detail_non_top_sql := get_param('detail_non_top_sql');
    g_time_granularity := get_param('time_granularity');
    g_wait_time_th := get_param('wait_time_th');
    g_response_time_th := get_param('response_time_th');
    g_trace_file_max_size_bytes := get_param('trace_file_max_size_bytes');
    g_copy_file_max_size_bytes := get_param('copy_file_max_size_bytes');
    g_gen_html_report := get_param('gen_html_report');
    g_gen_text_report := get_param('gen_text_report');
    g_split_10046_10053_trc := get_param('split_10046_10053_trc');
    g_gather_cbo_stats := get_param('gather_cbo_stats');
    g_capture_extents := get_param('capture_extents');
    g_refresh_dict_repository := get_param('refresh_dict_repository');
  END reset_updatable_parameters;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_param
   *
   * ------------------------- */
  PROCEDURE set_param (
    p_name   IN VARCHAR2,
    p_value  IN VARCHAR2,
    p_source IN VARCHAR2 DEFAULT 'U' ) -- (U)ser, (I)nternal
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    my_value trca$_tool_parameter.value%TYPE := NULL;
    par_rec trca$_tool_parameter%ROWTYPE;
  BEGIN /* set_param */
    BEGIN
      SELECT * INTO par_rec FROM trca$_tool_parameter WHERE name = LOWER(p_name);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        SYS.DBMS_OUTPUT.PUT_LINE('name:'||p_name);
        RAISE;
    END;

    IF p_source = 'U' THEN
      IF par_rec.hidden = 'Y' THEN
        RAISE_APPLICATION_ERROR (-20100, p_name||' is a hidden parameter');
      ELSIF par_rec.user_updateable = 'N' THEN
        RAISE_APPLICATION_ERROR (-20110, p_name||' is not user updateable');
      END IF;
    END IF;

    IF NVL(UPPER(p_value), '-666') = NVL(par_rec.value, '-666') THEN
      RETURN;
    END IF;

    IF p_source = 'I' THEN
      my_value := p_value;
    ELSIF par_rec.value_type = 'N' AND par_rec.low_value IS NOT NULL AND par_rec.high_value IS NOT NULL THEN
      IF TO_NUMBER(p_value) BETWEEN TO_NUMBER(par_rec.low_value) AND TO_NUMBER(par_rec.high_value) THEN
        my_value := TO_CHAR(TO_NUMBER(p_value));
      ELSE
        RAISE_APPLICATION_ERROR (-20130, 'value '||p_value||' must be between '||par_rec.low_value||' and '||par_rec.high_value);
      END IF;
    ELSIF par_rec.value1 IS NOT NULL THEN
      IF UPPER(p_value) IN (par_rec.value1, par_rec.value2, par_rec.value3, par_rec.value4, par_rec.value5) THEN
        my_value := UPPER(p_value);
      ELSE
        RAISE_APPLICATION_ERROR (-20140, 'value '||p_value||' not in list: '||par_rec.value1||' '||par_rec.value2||' '||par_rec.value3||' '||par_rec.value4||' '||par_rec.value5);
      END IF;
    END IF;

    UPDATE trca$_tool_parameter SET value = my_value WHERE id = par_rec.id;
    COMMIT;

    reset_updatable_parameters;
  END set_param;

  /*************************************************************************************/

  /* -------------------------
   *
   * public directories
   *
   * ------------------------- */
  FUNCTION directories
  RETURN varchar2_table PIPELINED
  IS
  BEGIN /* directories */
    PIPE ROW (RPAD(SUBSTR(g_input1_dir||'('||get_object_status(g_input1_dir, 'DIRECTORY')||')', 1, 22), 24)||get_directory_path(g_input1_dir));
    PIPE ROW (RPAD(SUBSTR(g_input2_dir||'('||get_object_status(g_input2_dir, 'DIRECTORY')||')', 1, 22), 24)||get_directory_path(g_input2_dir));
    PIPE ROW (RPAD(SUBSTR(g_stage_dir||'('||get_object_status(g_stage_dir, 'DIRECTORY')||')', 1, 22), 24)||get_directory_path(g_stage_dir));
    PIPE ROW (RPAD('user_dump_dest', 24)||g_udump);
    PIPE ROW (RPAD('background_dump_dest', 24)||g_bdump);
    RETURN;
  END directories;

  /*************************************************************************************/

  /* -------------------------
   *
   * public packages
   *
   * ------------------------- */
  FUNCTION packages
  RETURN varchar2_table PIPELINED
  IS
  BEGIN /* packages */
    PIPE ROW (get_object_status('TRCA$I', 'PACKAGE'));
    PIPE ROW (get_object_status('TRCA$E', 'PACKAGE'));
    PIPE ROW (get_object_status('TRCA$G', 'PACKAGE'));
    PIPE ROW (get_object_status('TRCA$P', 'PACKAGE'));
    PIPE ROW (get_object_status('TRCA$R', 'PACKAGE'));
    PIPE ROW (get_object_status('TRCA$T', 'PACKAGE'));
    PIPE ROW (get_object_status('TRCA$X', 'PACKAGE'));
    PIPE ROW (get_object_status('TRCA$I', 'PACKAGE BODY'));
    PIPE ROW (get_object_status('TRCA$E', 'PACKAGE BODY'));
    PIPE ROW (get_object_status('TRCA$G', 'PACKAGE BODY'));
    PIPE ROW (get_object_status('TRCA$P', 'PACKAGE BODY'));
    PIPE ROW (get_object_status('TRCA$R', 'PACKAGE BODY'));
    PIPE ROW (get_object_status('TRCA$T', 'PACKAGE BODY'));
    PIPE ROW (get_object_status('TRCA$X', 'PACKAGE BODY'));
    RETURN;
  END packages;

  /*************************************************************************************/

  /* -------------------------
   *
   * public tool_parameters
   *
   * ------------------------- */
  FUNCTION tool_parameters (
    p_hidden          IN VARCHAR2 DEFAULT 'N',
    p_user_updateable IN VARCHAR2 DEFAULT 'N',
    p_description     IN VARCHAR2 DEFAULT 'Y',
    p_name            IN VARCHAR2 DEFAULT 'Y',
    p_value_type      IN VARCHAR2 DEFAULT 'N',
    p_value           IN VARCHAR2 DEFAULT 'Y',
    p_default_value   IN VARCHAR2 DEFAULT 'Y',
    p_instructions    IN VARCHAR2 DEFAULT 'Y' )
  RETURN varchar2_table PIPELINED
  IS
    my_return VARCHAR2(2000);

  BEGIN /* tool_parameters */
    FOR i IN (SELECT *
                FROM trca$_tool_parameter
               ORDER BY
                     id)
    LOOP
      my_return := NULL;

      IF (p_hidden = 'Y' OR i.hidden = p_hidden) THEN
        IF p_hidden = 'Y' THEN
          my_return := my_return||RPAD('hidden:'||i.hidden, 10);
        END IF;

        IF p_user_updateable = 'Y' THEN
          my_return := my_return||RPAD('usr_upd:'||i.user_updateable, 11);
        END IF;

        IF p_description = 'Y' THEN
          my_return := my_return||RPAD(SUBSTR(i.description, 1, 30), 32);
        END IF;

        IF p_name = 'Y' THEN
          my_return := my_return||RPAD('Name:'||SUBSTR(i.name, 1, 25), 32);
        END IF;

        IF p_value_type = 'Y' THEN
          my_return := my_return||RPAD('Type:'||i.value_type, 8);
        END IF;

        IF p_value = 'Y' THEN
          my_return := my_return||RPAD('Value:'||SUBSTR(i.value, 1, 10), 18);
        END IF;

        IF p_default_value = 'Y' THEN
          my_return := my_return||RPAD('Default:'||SUBSTR(i.default_value, 1, 10), 20);
        END IF;

        IF p_instructions = 'Y' THEN
          my_return := my_return||SUBSTR(i.instructions, 1, 41);
        END IF;

        PIPE ROW (my_return);
      END IF;
    END LOOP;

    RETURN;
  END tool_parameters;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_dict_params
   *
   * ------------------------- */
  PROCEDURE get_dict_params
  IS
  BEGIN /* get_dict_params */
    g_dict_refresh_date  := get_param('dict_refresh_date', 'I');
    g_dict_refresh_days  := get_param('dict_refresh_days', 'I');
    g_dict_database_id   := get_param('dict_database_id', 'I');
    g_dict_database_name := get_param('dict_database_name', 'I');
    g_dict_instance_id   := get_param('dict_instance_id', 'I');
    g_dict_instance_name := get_param('dict_instance_name', 'I');
    g_dict_host_name     := get_param('dict_host_name', 'I');
    g_dict_platform      := get_param('dict_platform', 'I');
    g_dict_rdbms_version := get_param('dict_rdbms_version', 'I');
    g_dict_db_files      := get_param('dict_db_files', 'I');
  END get_dict_params;
  
  /*************************************************************************************/

  /* -------------------------
   *
   * public general_initialization
   *
   * ------------------------- */
  PROCEDURE general_initialization (
    p_force IN BOOLEAN DEFAULT FALSE )
  IS
    my_temp VARCHAR2(32767);

  BEGIN /* general_initialization */
    IF g_tool_name IS NOT NULL AND NOT p_force THEN  -- 22170178 use g_tool_name instead
      RETURN; -- already initialized
    END IF;

    get_dict_params;

    --g_tool_repository_schema := get_param('tool_repository_schema', 'I');
    --g_tool_administer_schema := get_param('tool_administer_schema', 'I');
    -- g_tool_repository_schema := TOOL_REPOSITORY_SCHEMA; 22170178 replaced with function.
    g_tool_administer_schema := TOOL_ADMINISTER_SCHEMA;
    g_tool_name       := get_param('tool_name', 'I');
    g_tool_version    := get_param('tool_version', 'I');
    g_install_date    := get_param('install_date', 'I');
    g_interop_version := get_param('interop_version', 'I');

    g_tool_instance_id := THIS_INSTANCE;

    -- g_tool_database_id
    BEGIN
      SELECT dbid
        INTO g_tool_database_id
        FROM v$database;
    EXCEPTION
      WHEN OTHERS THEN
        g_tool_database_id := 'UNKNOWN';
    END;
    set_param('tool_database_id', g_tool_database_id, 'I');
    g_tool_database_id := get_param('tool_database_id', 'I');

    -- g_tool_database_name
    BEGIN
      SELECT name
        INTO g_tool_database_name
        FROM v$database;
    EXCEPTION
      WHEN OTHERS THEN
        g_tool_database_name := 'UNKNOWN';
    END;
    set_param('tool_database_name', g_tool_database_name, 'I');
    g_tool_database_name := get_param('tool_database_name', 'I');

    -- g_tool_instance_name
    BEGIN
      SELECT instance_name
        INTO g_tool_instance_name
        FROM v$instance
       WHERE instance_number = g_tool_instance_id;
    EXCEPTION
      WHEN OTHERS THEN
        g_tool_instance_name := 'UNKNOWN';
    END;
    set_param('tool_instance_name', g_tool_instance_name, 'I');
    g_tool_instance_name := get_param('tool_instance_name', 'I');

    -- g_tool_host_name
    BEGIN
      SELECT host_name
        INTO g_tool_host_name
        FROM v$instance
       WHERE instance_number = g_tool_instance_id;
    EXCEPTION
      WHEN OTHERS THEN
        g_tool_host_name := 'UNKNOWN';
    END;
    set_param('tool_host_name', g_tool_host_name, 'I');
    g_tool_host_name := get_param('tool_host_name', 'I');

    -- g_tool_rdbms_version
    BEGIN
      SELECT version
        INTO g_tool_rdbms_version
        FROM v$instance
       WHERE instance_number = g_tool_instance_id;
    EXCEPTION
      WHEN OTHERS THEN
        g_tool_rdbms_version := 'UNKNOWN';
    END;
    set_param('tool_rdbms_version', g_tool_rdbms_version, 'I');
    g_tool_rdbms_version := get_param('tool_rdbms_version', 'I');

    -- g_tool_rdbms_release
    g_tool_rdbms_release := TO_CHAR(TO_NUMBER(SUBSTR(g_tool_rdbms_version, 1, INSTR(g_tool_rdbms_version, '.', 1, 2) - 1)));
    set_param('tool_rdbms_release', g_tool_rdbms_release, 'I');
    g_tool_rdbms_release := get_param('tool_rdbms_release', 'I');

    -- g_rdbms_version_short
    g_tool_rdbms_version_short := 'UNKNOWN';
    IF g_tool_rdbms_version LIKE '%8%.%1%.%5%' THEN g_tool_rdbms_version_short := '8.1.5.X'; END IF;
    IF g_tool_rdbms_version LIKE '%8%.%1%.%6%' THEN g_tool_rdbms_version_short := '8.1.6.X'; END IF;
    IF g_tool_rdbms_version LIKE '%8%.%1%.%7%' THEN g_tool_rdbms_version_short := '8.1.7.X'; END IF;
    IF g_tool_rdbms_version LIKE '%9%.%0%.%1%' THEN g_tool_rdbms_version_short := '9.0.1.X'; END IF;
    IF g_tool_rdbms_version LIKE '%9%.%2%.%0%' THEN g_tool_rdbms_version_short := '9.2.0.X'; END IF;
    IF g_tool_rdbms_version LIKE '%10%.%1%.%'  THEN g_tool_rdbms_version_short := '10.1.X';  END IF;
    IF g_tool_rdbms_version LIKE '%10%.%2%.%'  THEN g_tool_rdbms_version_short := '10.2.X';  END IF;
    IF g_tool_rdbms_version LIKE '%11%.%1%.%'  THEN g_tool_rdbms_version_short := '11.1.X';  END IF;
    IF g_tool_rdbms_version LIKE '%11%.%2%.%'  THEN g_tool_rdbms_version_short := '11.2.X';  END IF;
    set_param('tool_rdbms_version_short', g_tool_rdbms_version_short, 'I');
    g_tool_rdbms_version_short := get_param('tool_rdbms_version_short', 'I');

    -- g_open_mode
    IF TO_NUMBER(g_tool_rdbms_release) < 10 THEN
      g_open_mode := 'W';
    ELSE
      g_open_mode := 'WB';
    END IF;

    -- 150826 use TRCA$INPUT1 and TRCA$INPUT2
    -- g_udump
	 g_udump:=get_directory_path(g_input1_dir);
    -- g_bdump
     g_bdump:=get_directory_path(g_input2_dir);

    -- g_tool_platform
    BEGIN
      SELECT TRIM(REPLACE(REPLACE(product, 'TNS for '), ':' ))
        INTO g_tool_platform
        FROM product_component_version
       WHERE product LIKE 'TNS for%'
         AND ROWNUM = 1;
    EXCEPTION
      WHEN OTHERS THEN
        g_tool_platform := 'UNKNOWN';
    END;
    set_param('tool_platform', g_tool_platform, 'I');
    g_tool_platform := get_param('tool_platform', 'I');

    -- g_tool_product_version
    BEGIN
      SELECT SUBSTR(product||'('||status||')', 1, 256)
        INTO g_tool_product_version
        FROM product_component_version
       WHERE UPPER(product) LIKE '%ORACLE%'
         AND ROWNUM = 1;
    EXCEPTION
      WHEN OTHERS THEN
        g_tool_product_version := 'UNKNOWN';
    END;
    set_param('tool_product_version', g_tool_product_version, 'I');
    g_tool_product_version := get_param('tool_product_version', 'I');

    -- g_tool_db_files
    BEGIN
      SELECT value
        INTO g_tool_db_files
        FROM v$parameter2
       WHERE name = 'db_files';
    EXCEPTION
      WHEN OTHERS THEN
        g_tool_db_files := 'UNKNOWN';
    END;
    set_param('tool_db_files', g_tool_db_files, 'I');
    g_tool_db_files := get_param('tool_db_files', 'I');

    reset_updatable_parameters;

    g_input1_dir := UPPER(get_param('input1_dir'));
    g_input2_dir := UPPER(get_param('input2_dir'));
    g_stage_dir := UPPER(get_param('stage_dir'));

    set_param('input1_directory', get_directory_path(g_input1_dir), 'I');
    g_input1_directory := get_param('input1_directory', 'I');

    set_param('input2_directory', get_directory_path(g_input2_dir), 'I');
    g_input2_directory := get_param('input2_directory', 'I');

    set_param('stage_directory', get_directory_path(g_stage_dir), 'I');
    g_stage_directory := get_param('stage_directory', 'I');
  END general_initialization;

  /*************************************************************************************/

/* -------------------------
 *
 * package initialization
 *
 * ------------------------- */
BEGIN /* trca$g */
  general_initialization;
END trca$g;
/

SET TERM ON;
SHOW ERRORS;
