CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..sqlt$r AS
/* $Header: 215187.1 sqcpkgr.pkb 12.2.181004 2017/10/04 stelios.charalambides@oracle.com carlos.sierra mauro.pagano abel.macias $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  TOOL_NAME              CONSTANT VARCHAR2(32)  := 'SQLT';
  TOOL_REPOSITORY_SCHEMA CONSTANT VARCHAR2(32)  := '&&tool_repository_schema.';
  TOOL_ADMINISTER_SCHEMA CONSTANT VARCHAR2(32)  := '&&tool_administer_schema.';
  NOTE_NUMBER            CONSTANT VARCHAR2(32)  := '&&tool_note.';
  TOOL_DEVELOPER         CONSTANT VARCHAR2(32)  := 'abel.macias';
  TOOL_DEVELOPER_EMAIL   CONSTANT VARCHAR2(32)  := 'abel.macias@oracle.com';
  COPYRIGHT              CONSTANT VARCHAR2(128) := 'Copyright (c) 2000-2015, Oracle Corporation. All rights reserved.';
  HEADING_DATE_FORMAT    CONSTANT VARCHAR2(32)  := 'YYYY/MM/DD';
  LOAD_DATE_FORMAT       CONSTANT VARCHAR2(32)  := 'YYYY-MM-DD/HH24:MI:SS'; -- 2010-03-03/08:45:04
  SCIENTIFIC_NOTATION    CONSTANT VARCHAR2(32)  := '0D000000EEEE';
  PERCENT_FORMAT         CONSTANT VARCHAR2(32)  := '99999990D0';
  NUL                    CONSTANT CHAR(1)       := CHR(00);
  LF                     CONSTANT CHAR(1)       := CHR(10);
  CR                     CONSTANT CHAR(1)       := CHR(13);
  TAB                    CONSTANT CHAR(1)       := CHR(09);
  AMP                    CONSTANT CHAR(1)       := CHR(38);
  AMP2                   CONSTANT CHAR(2)       := AMP||AMP;
  ARROBA                 CONSTANT CHAR(1)       := CHR(64);
  XTRACT_DEF_CHAR        CONSTANT CHAR(1)       := CHR(94);
  METADATA_DEF_CHAR      CONSTANT CHAR(1)       := CHR(94);
  METADATA_DEF_CHAR2     CONSTANT CHAR(2)       := METADATA_DEF_CHAR||METADATA_DEF_CHAR;
  ARROBA2                CONSTANT CHAR(2)       := ARROBA||ARROBA;
  CARET                  CONSTANT CHAR(1)       := CHR(94); -- caret
  BACKSLASH              CONSTANT CHAR(1)       := CHR(92); -- backslash
  POUND                  CONSTANT VARCHAR2(32)  := CHR(35); -- #
  NBSP                   CONSTANT VARCHAR2(32)  := AMP||'nbsp;'; -- space
  NBSP2                  CONSTANT VARCHAR2(32)  := NBSP||NBSP; -- 2 spaces
  NBSP4                  CONSTANT VARCHAR2(32)  := NBSP2||NBSP2; -- 4 spaces
  QUOT                   CONSTANT VARCHAR2(32)  := AMP||'quot;'; -- "
  SQUOT                  CONSTANT VARCHAR2(32)  := AMP||'#39;'; -- '
  GT                     CONSTANT VARCHAR2(32)  := AMP||'gt;'; -- >
  LT                     CONSTANT VARCHAR2(32)  := AMP||'lt;'; -- <
  OPAR                   CONSTANT VARCHAR2(32)  := AMP||'#40;'; -- (
  CPAR                   CONSTANT VARCHAR2(32)  := AMP||'#41;'; -- )

  /*************************************************************************************/

  -- 171004 Extensive replacement of variables to varchar2(257)
  
  /* -------------------------
   *
   * static variables
   *
   * ------------------------- */
  s_file_rec sqli$_file%ROWTYPE;

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
    sqlt$a.write_log(p_line_text => p_line_text, p_line_type => p_line_type, p_package => 'R');
  END write_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * private write_error
   *
   * ------------------------- */
  PROCEDURE write_error (p_line_text IN VARCHAR2)
  IS
  BEGIN
    sqlt$a.write_error('r:'||p_line_text);
  END write_error;

  /*************************************************************************************/

  /* -------------------------
   *
   * public libraries_versions
   *
   * ------------------------- */
  FUNCTION libraries_versions
  RETURN varchar2_table PIPELINED
  IS
    l_line_text VARCHAR2(32767);
    l_begin NUMBER;
    l_end NUMBER;
	l_support varchar2(32767);
  BEGIN
    FOR i IN (SELECT owner, object_type, object_name, status
                FROM sys.dba_objects
               WHERE owner = TOOL_ADMINISTER_SCHEMA
                 AND object_type IN ('PACKAGE', 'PACKAGE BODY', 'PROCEDURE', 'FUNCTION')
               ORDER BY
                     status DESC, object_type, object_name)
    LOOP
      BEGIN
        SELECT text
          INTO l_line_text
          FROM sys.dba_source
         WHERE owner = i.owner
           AND name = i.object_name
           AND type = i.object_type
           AND line < 11
           AND text LIKE '%$Header%'
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          l_line_text := ' ';
      END;

      IF l_line_text IS NOT NULL THEN
        l_begin := GREATEST(INSTR(l_line_text, '.pkb'), INSTR(l_line_text, '.pks'), INSTR(l_line_text, '.sql')) + 5;
        l_end := INSTR(l_line_text, ' 20');
		l_support := regexp_substr(trim(l_line_text),'(\S*)(\s)',1,7);
        l_line_text := SUBSTR(l_line_text, l_begin, l_end - l_begin);
		
      END IF;

      PIPE ROW(RPAD(i.status, 8)||RPAD(i.object_type, 13)||RPAD(l_line_text, 13)||RPAD(i.object_name,7)||RPAD(l_support,32));
    END LOOP;

    RETURN; -- needed by pipelined functions
  END libraries_versions;

  /*************************************************************************************/

  /* -------------------------
   *
   * public display_file
   *
   * called by: sqltxtract.sql, sqltxecute.sql, sqltxplain.sql,
   * sqltcompare.sql and sqlthistfile.sql
   *
   * pipes up to top 'n' MB of a CLOB file regulating its width
   * (needed due to sqlplus restrictions)
   *
   * ------------------------- */
  FUNCTION display_file (
    p_filename      IN VARCHAR2,
    p_statement_id  IN NUMBER  DEFAULT NULL,
    p_statement_id2 IN NUMBER  DEFAULT NULL,
    p_max_line_size IN INTEGER DEFAULT 2000 )
  RETURN varchar2_table PIPELINED
  IS
    l_filename VARCHAR2(32767);
    my_chunk_size NUMBER;
    my_char_buffer VARCHAR2(32767);
    l_offset NUMBER := 1;
    buffer_LF_ptr NUMBER;
    l_file_size NUMBER;

  BEGIN
    l_filename := TRIM(p_filename);
    IF NVL(l_filename, 'missing_file.txt') = 'missing_file.txt' THEN
      PIPE ROW('missing file "'||l_filename||'"');
      RETURN; -- needed by pipelined functions
    END IF;

    s_file_rec := sqlt$a.get_file(l_filename, p_statement_id, p_statement_id2);

    -- removed to avoid raising this error when connected remote into some other user.
    --IF USER NOT IN ('SYS', 'SYSTEM', TOOL_ADMINISTER_SCHEMA, s_file_rec.username) THEN
    --  RAISE_APPLICATION_ERROR (-20210, 'To download this file you must connect as "SYS", "SYSTEM", "'||TOOL_ADMINISTER_SCHEMA||'", or "'||s_file_rec.username||'"');
    --END IF;

    l_file_size := LEAST(s_file_rec.file_size, ((sqlt$a.get_param_n('sqlt_max_file_size_mb') * 1024 * 1024) + 1024)); -- up to top 'n' MB

    BEGIN
      SYS.DBMS_LOB.OPEN(s_file_rec.file_text, SYS.DBMS_LOB.FILE_READONLY);
    EXCEPTION
      WHEN OTHERS THEN
        write_error('DBMS_LOB.OPEN: '||p_filename);
        write_error(SQLERRM);
        RETURN;
    END;

    -- break line at {"LF", ">", ")", ",", "/", "BACKSLASH", " "}
    WHILE l_offset < l_file_size
    LOOP
      my_chunk_size := LEAST(p_max_line_size, l_file_size - l_offset + 1);
      IF my_chunk_size > 0 THEN
        SYS.DBMS_LOB.READ(s_file_rec.file_text, my_chunk_size, l_offset, my_char_buffer);
        BEGIN
          IF my_chunk_size <> p_max_line_size THEN -- last piece
            PIPE ROW(my_char_buffer);
            l_offset := l_file_size; -- signals eof
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
                    buffer_LF_ptr := INSTR(my_char_buffer, '/', -1); -- last "/" on chunk
                    IF buffer_LF_ptr > 0 THEN -- there was at least one "/" within chunk
                      PIPE ROW(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last "/"
                      l_offset := l_offset + buffer_LF_ptr;
                    ELSE
                      buffer_LF_ptr := INSTR(my_char_buffer, BACKSLASH, -1); -- last BACKSLASH on chunk
                      IF buffer_LF_ptr > 0 THEN -- there was at least one BACKSLASH within chunk
                        PIPE ROW(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last BACKSLASH
                        l_offset := l_offset + buffer_LF_ptr;
                      ELSE
                        buffer_LF_ptr := INSTR(my_char_buffer, ' ', -1); -- last " " on chunk
                        IF buffer_LF_ptr > 0 THEN -- there was at least one " " within chunk
                          PIPE ROW(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last " "
                          l_offset := l_offset + buffer_LF_ptr;
                        ELSE -- returns whole buffer which cannot be larger than p_max_line_size
                          PIPE ROW(my_char_buffer);
                          l_offset := l_offset + my_chunk_size;
                        END IF;
                      END IF;
                    END IF;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            l_offset := l_offset + my_chunk_size;
            write_error(my_char_buffer);
            write_error(SQLERRM);
        END;
      ELSE
        l_offset := l_file_size; -- signals eof
      END IF;
    END LOOP;

    SYS.DBMS_LOB.CLOSE(s_file_rec.file_text);
    RETURN; -- needed by pipelined functions
  EXCEPTION
    WHEN OTHERS THEN
      write_error(my_char_buffer);
      write_error(SQLERRM);
      RETURN; -- needed by pipelined functions
  END display_file;

  /*************************************************************************************/

  /* -------------------------
   *
   * public utl_file
   *
   * called by: sqlt$e.copy_file_from_repo_to_dir and sqlt$e.copy_files_from_repo_to_dir
   *
   * creates file in OS directory (up to top 'n' MB) out of a CLOB file
   *
   * ------------------------- */
  PROCEDURE utl_file (
    p_filename       IN VARCHAR2,
    p_statement_id   IN NUMBER   DEFAULT NULL,
    p_statement_id2  IN NUMBER   DEFAULT NULL,
    p_directory_name IN VARCHAR2 DEFAULT 'SQLT$STAGE' )
  IS
    l_max_line_size INTEGER := 2000;
    l_filename VARCHAR2(32767);
    my_chunk_size NUMBER;
    my_char_buffer VARCHAR2(32767);
    l_offset NUMBER := 1;
    buffer_LF_ptr NUMBER;
    l_file_size NUMBER;
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
    l_filename := TRIM(p_filename);
    IF NVL(l_filename, 'missing_file.txt') = 'missing_file.txt' THEN
      RETURN; -- file is not created
    END IF;

    s_file_rec := sqlt$a.get_file(l_filename, p_statement_id, p_statement_id2);

    -- removed to avoid raising this error when connected remote into some other user.
    --IF USER NOT IN ('SYS', 'SYSTEM', TOOL_ADMINISTER_SCHEMA, s_file_rec.username) THEN
    --  RAISE_APPLICATION_ERROR (-20210, 'To download this file you must connect as "SYS", "SYSTEM", "'||TOOL_ADMINISTER_SCHEMA||'", or "'||s_file_rec.username||'"');
    --END IF;

    l_file_size := LEAST(s_file_rec.file_size, ((sqlt$a.get_param_n('sqlt_max_file_size_mb') * 1024 * 1024) + 1024)); -- up to top 'n' MB

    BEGIN
      SYS.DBMS_LOB.OPEN(s_file_rec.file_text, SYS.DBMS_LOB.FILE_READONLY);
    EXCEPTION
      WHEN OTHERS THEN
        write_error('DBMS_LOB.OPEN: '||p_filename);
        write_error(SQLERRM);
        RETURN;
    END;

    BEGIN
      out_file_type :=
      SYS.UTL_FILE.FOPEN (
         location     => p_directory_name,
         filename     => l_filename,
         open_mode    => 'WB',
         max_linesize => 32767 );
    EXCEPTION
      WHEN OTHERS THEN
        write_error('UTL_FILE.FOPEN: dir:'||p_directory_name||' file:'||l_filename);
        write_error(SQLERRM);
        RETURN;
    END;

    -- break line at {"LF", ">", ")", ",", "/", "BACKSLASH", " "}
    WHILE l_offset < l_file_size
    LOOP
      my_chunk_size := LEAST(l_max_line_size, l_file_size - l_offset + 1);
      IF my_chunk_size > 0 THEN
        SYS.DBMS_LOB.READ(s_file_rec.file_text, my_chunk_size, l_offset, my_char_buffer);
        BEGIN
          IF my_chunk_size <> l_max_line_size THEN -- last piece
            put_buffer(my_char_buffer);
            l_offset := l_file_size; -- signals eof
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
                    buffer_LF_ptr := INSTR(my_char_buffer, '/', -1); -- last "/" on chunk
                    IF buffer_LF_ptr > 0 THEN -- there was at least one "/" within chunk
                      put_buffer(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last "/"
                      l_offset := l_offset + buffer_LF_ptr;
                    ELSE
                      buffer_LF_ptr := INSTR(my_char_buffer, BACKSLASH, -1); -- last BACKSLASH on chunk
                      IF buffer_LF_ptr > 0 THEN -- there was at least one BACKSLASH within chunk
                        put_buffer(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last BACKSLASH
                        l_offset := l_offset + buffer_LF_ptr;
                      ELSE
                        buffer_LF_ptr := INSTR(my_char_buffer, ' ', -1); -- last " " on chunk
                        IF buffer_LF_ptr > 0 THEN -- there was at least one " " within chunk
                          put_buffer(SUBSTR(my_char_buffer, 1, buffer_LF_ptr)); -- includes last " "
                          l_offset := l_offset + buffer_LF_ptr;
                        ELSE -- returns whole buffer which cannot be larger than l_max_line_size
                          put_buffer(my_char_buffer);
                          l_offset := l_offset + my_chunk_size;
                        END IF;
                      END IF;
                    END IF;
                  END IF;
                END IF;
              END IF;
            END IF;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            l_offset := l_offset + my_chunk_size;
            write_error(my_char_buffer);
            write_error(SQLERRM);
        END;
      ELSE
        l_offset := l_file_size; -- signals eof
      END IF;
    END LOOP;

    SYS.UTL_FILE.FCLOSE(file => out_file_type);
    SYS.DBMS_LOB.CLOSE(s_file_rec.file_text);
  EXCEPTION
    WHEN OTHERS THEN
      write_error(my_char_buffer);
      write_error(SQLERRM);
  END utl_file;

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
            write_error(SQLERRM);
            write_error(my_char_buffer);
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
   * public sanitize_js_text
   *
   * ------------------------- */
  FUNCTION sanitize_js_text (p_text IN VARCHAR2)
  RETURN VARCHAR2
  IS
    l_text VARCHAR2(32767);
  BEGIN
    IF p_text IS NULL THEN
      RETURN NULL;
    ELSE
      l_text := p_text;
    END IF;

    l_text := REPLACE(l_text, '''', BACKSLASH||'''');
    l_text := REPLACE(l_text, '"', QUOT);
    l_text := REPLACE(l_text, '>', GT);
    l_text := REPLACE(l_text, '<', LT);
    l_text := REPLACE(l_text, '(', OPAR);
    l_text := REPLACE(l_text, ')', CPAR);

    RETURN l_text;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sanitize_js_text:'||SQLERRM);
      RETURN l_text;
  END sanitize_js_text;

  /*************************************************************************************/

  /* -------------------------
   *
   * public sanitize_html_clob
   *
   * ------------------------- */
  FUNCTION sanitize_html_clob (
    p_clob IN CLOB,
    p_br   IN BOOLEAN DEFAULT TRUE )
  RETURN CLOB
  IS
  BEGIN
    IF p_br THEN
      RETURN REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(p_clob, '<', LT), '>', GT), '''', SQUOT), '"', QUOT), LF, '<br>'||LF);
    ELSE
      RETURN REPLACE(REPLACE(REPLACE(REPLACE(p_clob, '<', LT), '>', GT), '''', SQUOT), '"', QUOT);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sanitize_html_clob:'||SQLERRM);
      RETURN p_clob;
  END sanitize_html_clob;

  /*************************************************************************************/

  /* -------------------------
   *
   * public wrap_and_sanitize_html_clob
   *
   * ------------------------- */
  FUNCTION wrap_and_sanitize_html_clob (
    p_clob          IN CLOB,
    p_max_line_size IN INTEGER DEFAULT 80,
    p_br            IN BOOLEAN DEFAULT TRUE )
  RETURN CLOB
  IS
  BEGIN
    RETURN sanitize_html_clob(wrap_clob(p_clob, p_max_line_size), p_br);
  END wrap_and_sanitize_html_clob;

  /*************************************************************************************/

  /* -------------------------
   *
   * private font_clob
   *
   * ------------------------- */
  FUNCTION font_clob(p_clob IN CLOB)
  RETURN CLOB
  IS
    l_font VARCHAR2(32) := sqlt$a.get_param('keyword_font_color');
    l_begin_font VARCHAR2(64) := '<font class="'||l_font||'">';
    l_end_font VARCHAR2(32) := '</font>';
    l_clob CLOB;

    PROCEDURE put_font (p_keyword IN VARCHAR2)
    IS
    BEGIN
      l_clob := REPLACE(l_clob, ' '||p_keyword||' ', ' '||l_begin_font||p_keyword||l_end_font||' ');
      l_clob := REPLACE(l_clob, LF||p_keyword||' ', LF||l_begin_font||p_keyword||l_end_font||' ');
      l_clob := REPLACE(l_clob, ' '||p_keyword||LF, ' '||l_begin_font||p_keyword||l_end_font||LF);
      l_clob := REPLACE(l_clob, LF||p_keyword||LF, LF||l_begin_font||p_keyword||l_end_font||LF);
      l_clob := REPLACE(l_clob, '('||p_keyword||' ', '('||l_begin_font||p_keyword||l_end_font||' ');
      l_clob := REPLACE(l_clob, '('||p_keyword||LF, '('||l_begin_font||p_keyword||l_end_font||LF);
      l_clob := REPLACE(l_clob, p_keyword||' ', l_begin_font||p_keyword||l_end_font||' ');
      l_clob := REPLACE(l_clob, p_keyword||LF, l_begin_font||p_keyword||l_end_font||LF);
    END put_font;
  BEGIN
    IF l_font = 'none' THEN
      RETURN p_clob;
    END IF;

    l_clob := p_clob;

    put_font('SELECT');
    put_font('INSERT');
    put_font('UPDATE');
    put_font('DELETE');
    put_font('MERGE');
    put_font('FROM');
    put_font('WHERE');

    put_font('select');
    put_font('insert');
    put_font('update');
    put_font('delete');
    put_font('merge');
    put_font('from');
    put_font('where');

    RETURN l_clob;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('font_clob:'||SQLERRM);
      RETURN p_clob;
  END font_clob;

  /*************************************************************************************/

  /* -------------------------
   *
   * public wrap_sanitize_font_html_clob
   *
   * ------------------------- */
  FUNCTION wrap_sanitize_font_html_clob (
    p_clob          IN CLOB,
    p_max_line_size IN INTEGER DEFAULT 80,
    p_br            IN BOOLEAN DEFAULT TRUE )
  RETURN CLOB
  IS
  BEGIN
    RETURN font_clob(sanitize_html_clob(wrap_clob(p_clob, p_max_line_size), p_br));
  END wrap_sanitize_font_html_clob;

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
      append('<td nowrap class="l">'||wrap_and_sanitize_html_clob(p_clob, p_max_line_size)||'</td>');
    ELSE
      append(wrap_and_sanitize_html_clob(p_clob, p_max_line_size, FALSE));
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
      append('<td nowrap class="l">'||wrap_sanitize_font_html_clob(p_clob, p_max_line_size)||'</td>');
    ELSE
      append(wrap_sanitize_font_html_clob(p_clob, p_max_line_size, FALSE));
    END IF;
  END font_sanitize_and_append;

  /*************************************************************************************/

  /* -------------------------
   *
   * public over_under_difference
   *
   * ------------------------- */
  FUNCTION over_under_difference (
    p_number1     IN NUMBER,
    p_number2     IN NUMBER,
    p_percent1    IN NUMBER  DEFAULT 10,
    p_percent2    IN NUMBER  DEFAULT 100,
    p_percent3    IN NUMBER  DEFAULT 1000 )
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_number1 IS NULL OR p_number2 IS NULL THEN
      RETURN NULL;
    ELSIF p_number1 * p_number2 = 0 THEN
      RETURN NULL;
    ELSIF ROUND(p_number1/p_number2) < 2 AND ROUND(p_number2/p_number1) < 2 THEN
      RETURN '1x';
    ELSIF p_number1 > p_number2 THEN
      IF ROUND(p_number1/p_number2) > p_percent3 THEN
        RETURN '<font class="crimson"><strong>*** '||ROUND(p_number1/p_number2)||'x over</strong></font>';
      ELSIF ROUND(p_number1/p_number2) > p_percent2 THEN
        RETURN '<font class="red">** '||ROUND(p_number1/p_number2)||'x over</font>';
      ELSIF ROUND(p_number1/p_number2) > p_percent1 THEN
        RETURN '<font class="darkorange">* '||ROUND(p_number1/p_number2)||'x over</font>';
      ELSE
        RETURN ROUND(p_number1/p_number2)||'x over';
      END IF;
    ELSE -- p_number1 < p_number2
      IF ROUND(p_number2/p_number1) > p_percent3 THEN
        RETURN '<font class="crimson"><strong>*** '||ROUND(p_number2/p_number1)||'x under</strong></font>';
      ELSIF ROUND(p_number2/p_number1) > p_percent2 THEN
        RETURN '<font class="red">** '||ROUND(p_number2/p_number1)||'x under</font>';
      ELSIF ROUND(p_number2/p_number1) > p_percent1 THEN
        RETURN '<font class="darkorange">* '||ROUND(p_number2/p_number1)||'x under</font>';
      ELSE
        RETURN ROUND(p_number2/p_number1)||'x under';
      END IF;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('over_under_difference:'||SQLERRM);
      RETURN NULL;
  END over_under_difference;

  /*************************************************************************************/

  /* -------------------------
   *
   * public color_differences
   *
   * ------------------------- */
  FUNCTION color_differences (
    p_number1     IN NUMBER,
    p_number2     IN NUMBER,
    p_text        IN VARCHAR2,
    p_percent1    IN NUMBER  DEFAULT 10,
    p_percent2    IN NUMBER  DEFAULT 100,
    p_ignore_zero IN BOOLEAN DEFAULT FALSE )
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_ignore_zero AND p_number1 * p_number2 = 0 THEN
      RETURN p_text;
    ELSIF sqlt$t.differ_more_than_x_perc(p_number1, p_number2, p_percent2) THEN
      RETURN '<font class="crimson"><strong>'||p_text||'</strong></font>';
    ELSIF sqlt$t.differ_more_than_x_perc(p_number1, p_number2, p_percent1) THEN
      RETURN '<font class="darkorange">'||p_text||'</font>';
    ELSE
      RETURN p_text;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('color_differences:'||SQLERRM);
      RETURN p_text;
  END color_differences;

  /*************************************************************************************/

  /* -------------------------
   *
   * public color_differences_c
   *
   * ------------------------- */
  FUNCTION color_differences_c (
    p_text1 IN VARCHAR2,
    p_text2 IN VARCHAR2,
    p_text  IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_text1 IS NULL AND p_text2 IS NULL THEN
      RETURN p_text;
    ELSIF p_text1 IS NULL OR p_text2 IS NULL THEN
      RETURN '<font class="crimson">'||p_text||'</font>';
    ELSIF p_text1 = p_text2 THEN
      RETURN p_text;
    ELSE
      RETURN '<font class="crimson">'||p_text||'</font>';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('color_differences_c:'||SQLERRM);
      RETURN p_text;
  END color_differences_c;

  /*************************************************************************************/

  /* -------------------------
   *
   * public export_parfile
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE export_parfile (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_prefix VARCHAR2(32767);
    l_tables VARCHAR2(32767);
    l_query VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);

    FUNCTION sqlt_table_with_rows (
      p_table_name IN VARCHAR2,
      p_comma      IN VARCHAR2 DEFAULT ',' )
    RETURN VARCHAR2
    IS
      l2_count NUMBER;
    BEGIN
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||p_table_name||' '||l_query||' AND ROWNUM = 1' INTO l2_count;
      IF l2_count > 0 OR p_comma = '#' THEN
        RETURN p_comma||TOOL_REPOSITORY_SCHEMA||'.'||TRIM(UPPER(p_table_name))||LF;
      ELSE
        RETURN '#'||TOOL_REPOSITORY_SCHEMA||'.'||TRIM(UPPER(p_table_name))||LF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(p_table_name||':'||SQLERRM);
        RETURN '#'||TOOL_REPOSITORY_SCHEMA||'.'||TRIM(UPPER(p_table_name))||':'||SQLERRM||LF;
    END sqlt_table_with_rows;

  BEGIN
    write_log('-> export_parfile');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sqlt$a.get_param('export_repository') = 'Y' AND sqlt$a.get_param('mask_for_values') IN ('CLEAR', 'SECURE') THEN
      IF p_out_file_identifier IS NULL THEN
        l_out_file_identifier := NULL;
      ELSE
        l_out_file_identifier := '_'||p_out_file_identifier;
      END IF;

      l_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier;
      s_file_rec.filename := l_prefix||'_export_parfile.txt';

      l_query := 'WHERE (statid LIKE ''s'||sqlt$a.get_statement_id_c(p_statement_id)||'%'' OR statid LIKE ''f'||sqlt$a.get_statement_id_c(p_statement_id)||'%'' '||
                   '  OR statid LIKE ''d'||sqlt$a.get_statement_id_c(p_statement_id)||'%'')';

      l_tables := 'TABLES='||LF||
      sqlt_table_with_rows('sqlt$_sql_statement', ' ')||
      sqlt_table_with_rows('sqlt$_aux_stats$')||
      sqlt_table_with_rows('sqlt$_dba_audit_policies')||
      sqlt_table_with_rows('sqlt$_dba_autotask_client')||
      sqlt_table_with_rows('sqlt$_dba_autotask_client_hst')||
      sqlt_table_with_rows('sqlt$_dba_col_stats_versions')||
      sqlt_table_with_rows('sqlt$_dba_col_usage$')||
      sqlt_table_with_rows('sqlt$_dba_constraints')||
      sqlt_table_with_rows('sqlt$_dba_dependencies')||
      sqlt_table_with_rows('sqlt$_dba_hist_active_sess_his')||
      sqlt_table_with_rows('sqlt$_dba_hist_parameter_m')||
      sqlt_table_with_rows('sqlt$_dba_hist_seg_stat_obj')||
      sqlt_table_with_rows('sqlt$_dba_hist_snapshot')||
      sqlt_table_with_rows('sqlt$_dba_hist_sql_plan')||
      sqlt_table_with_rows('sqlt$_dba_hist_sqlbind')||
      sqlt_table_with_rows('sqlt$_dba_hist_sqlstat')||
      sqlt_table_with_rows('sqlt$_dba_hist_sqltext')||
      sqlt_table_with_rows('sqlt$_dba_histgrm_stats_versn')||
      sqlt_table_with_rows('sqlt$_dba_ind_columns')||
      sqlt_table_with_rows('sqlt$_dba_ind_expressions')||
      sqlt_table_with_rows('sqlt$_dba_ind_partitions')||
      sqlt_table_with_rows('sqlt$_dba_ind_statistics')||
      sqlt_table_with_rows('sqlt$_dba_ind_stats_versions')||
      sqlt_table_with_rows('sqlt$_dba_ind_subpartitions')||
      sqlt_table_with_rows('sqlt$_dba_indexes')||
      sqlt_table_with_rows('sqlt$_dba_nested_table_cols')||
      sqlt_table_with_rows('sqlt$_dba_nested_tables')||
      sqlt_table_with_rows('sqlt$_dba_object_tables')||
      sqlt_table_with_rows('sqlt$_dba_objects')||
      sqlt_table_with_rows('sqlt$_dba_optstat_operations')||
      sqlt_table_with_rows('sqlt$_dba_outline_hints')||
      sqlt_table_with_rows('sqlt$_dba_outlines')||
      sqlt_table_with_rows('sqlt$_dba_part_col_statistics')||
      sqlt_table_with_rows('sqlt$_dba_part_histograms')||
      sqlt_table_with_rows('sqlt$_dba_part_key_columns')||
      sqlt_table_with_rows('sqlt$_dba_policies')||
      sqlt_table_with_rows('sqlt$_dba_scheduler_jobs')||
      sqlt_table_with_rows('sqlt$_dba_segments')||
      sqlt_table_with_rows('sqlt$_dba_source')||
      sqlt_table_with_rows('sqlt$_dba_sql_plan_directives')||
      sqlt_table_with_rows('sqlt$_dba_sql_plan_dir_objs')||
      sqlt_table_with_rows('sqlt$_dba_sql_patches')||
      sqlt_table_with_rows('sqlt$_dba_sql_plan_baselines')||
      sqlt_table_with_rows('sqlt$_dba_sql_profiles')||
      sqlt_table_with_rows('sqlt$_dba_sqltune_plans')||
      sqlt_table_with_rows('sqlt$_dba_stat_extensions')||
      sqlt_table_with_rows('sqlt$_dba_subpart_col_stats')||
      sqlt_table_with_rows('sqlt$_dba_subpart_histograms')||
      sqlt_table_with_rows('sqlt$_dba_tab_col_statistics')||
      sqlt_table_with_rows('sqlt$_dba_tab_cols')||
      sqlt_table_with_rows('sqlt$_dba_tab_histograms')||
      sqlt_table_with_rows('sqlt$_dba_tab_modifications')||
      sqlt_table_with_rows('sqlt$_dba_tab_partitions')||
      sqlt_table_with_rows('sqlt$_dba_tab_statistics')||
      sqlt_table_with_rows('sqlt$_dba_tab_stats_versions')||
      sqlt_table_with_rows('sqlt$_dba_tab_subpartitions')||
      sqlt_table_with_rows('sqlt$_dba_tables')||
      sqlt_table_with_rows('sqlt$_dba_tablespaces')||
      sqlt_table_with_rows('sqlt$_dbms_xplan')||
      sqlt_table_with_rows('sqlt$_fnd_histogram_cols')||
      sqlt_table_with_rows('sqlt$_gv$active_session_histor')||
      sqlt_table_with_rows('sqlt$_gv$cell_state')||
      sqlt_table_with_rows('sqlt$_gv$im_segments')||
      sqlt_table_with_rows('sqlt$_gv$im_column_level')||
      sqlt_table_with_rows('sqlt$_gv$nls_parameters')||
      sqlt_table_with_rows('sqlt$_gv$object_dependency')||
      sqlt_table_with_rows('sqlt$_gv$parameter2')||
      sqlt_table_with_rows('sqlt$_gv$parameter_cbo')||
      sqlt_table_with_rows('sqlt$_gv$pq_sesstat')||
      sqlt_table_with_rows('sqlt$_gv$pq_slave')||
      sqlt_table_with_rows('sqlt$_gv$pq_sysstat')||
      sqlt_table_with_rows('sqlt$_gv$pq_tqstat')||
      sqlt_table_with_rows('sqlt$_gv$px_instance_group')||
      sqlt_table_with_rows('sqlt$_gv$px_process')||
      sqlt_table_with_rows('sqlt$_gv$px_process_sysstat')||
      sqlt_table_with_rows('sqlt$_gv$px_session')||
      sqlt_table_with_rows('sqlt$_gv$px_sesstat')||
      sqlt_table_with_rows('sqlt$_gv$segment_statistics')||
      sqlt_table_with_rows('sqlt$_gv$session_event')||
      sqlt_table_with_rows('sqlt$_gv$sesstat')||
      sqlt_table_with_rows('sqlt$_gv$sql')||
      sqlt_table_with_rows('sqlt$_gv$sql_bind_capture')||
      sqlt_table_with_rows('sqlt$_gv$sql_cs_histogram')||
      sqlt_table_with_rows('sqlt$_gv$sql_cs_selectivity')||
      sqlt_table_with_rows('sqlt$_gv$sql_cs_statistics')||
      sqlt_table_with_rows('sqlt$_gv$sql_monitor')||
      sqlt_table_with_rows('sqlt$_gv$sql_optimizer_env')||
      sqlt_table_with_rows('sqlt$_gv$sql_plan')||
      sqlt_table_with_rows('sqlt$_gv$sql_plan_monitor')||
      sqlt_table_with_rows('sqlt$_gv$sql_plan_statistics')||
      sqlt_table_with_rows('sqlt$_gv$sql_shared_cursor')||
      sqlt_table_with_rows('sqlt$_gv$sql_workarea')||
      sqlt_table_with_rows('sqlt$_gv$sqlarea')||
      sqlt_table_with_rows('sqlt$_gv$sqlarea_plan_hash')||
      sqlt_table_with_rows('sqlt$_gv$sqlstats')||
      sqlt_table_with_rows('sqlt$_gv$sqlstats_plan_hash')||
      sqlt_table_with_rows('sqlt$_gv$sqltext_with_newlines')||
      sqlt_table_with_rows('sqlt$_gv$statname')||
      sqlt_table_with_rows('sqlt$_gv$system_parameter')||
      sqlt_table_with_rows('sqlt$_gv$vpd_policy')||
      sqlt_table_with_rows('sqlt$_log')||
      sqlt_table_with_rows('sqlt$_metadata')||
      sqlt_table_with_rows('sqlt$_nls_database_parameters')||
      sqlt_table_with_rows('sqlt$_optstat_user_prefs$')||
      sqlt_table_with_rows('sqlt$_outline_data')||
      sqlt_table_with_rows('sqlt$_peeked_binds')||
      sqlt_table_with_rows('sqlt$_plan_extension')||
      sqlt_table_with_rows('sqlt$_plan_info')||
      sqlt_table_with_rows('sqlt$_sql_plan_table')||
      sqlt_table_with_rows('sqlt$_sql_shared_cursor_d')||
      sqlt_table_with_rows('sqlt$_sqlobj$')||
      sqlt_table_with_rows('sqlt$_sqlobj$data')||
      sqlt_table_with_rows('sqlt$_sqlprof$')||
      sqlt_table_with_rows('sqlt$_sqlprof$attr')||
      sqlt_table_with_rows('sqlt$_stattab')||
      sqlt_table_with_rows('sqlt$_stgtab_baseline')||
      sqlt_table_with_rows('sqlt$_stgtab_sqlprof')||
      sqlt_table_with_rows('sqlt$_stgtab_sqlset')||
      sqlt_table_with_rows('sqlt$_stgtab_directive')||
      sqlt_table_with_rows('sqlt$_v$session_fix_control')||
      sqlt_table_with_rows('sqlt$_wri$_adv_rationale')||
      sqlt_table_with_rows('sqlt$_wri$_adv_tasks')||
      sqlt_table_with_rows('sqlt$_wri$_optstat_aux_history')||
      sqlt_table_with_rows('sqli$_file', '#');

      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        s_file_rec.file_text :=
        '# COMMAND: expdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||sqlt$a.get_param('connect_identifier')||' parfile='||s_file_rec.filename||LF||
        '#'||LF||
        l_tables||
        'DIRECTORY=SQLT$STAGE # '||sqlt$a.get_stage_path||LF||
        'DUMPFILE='||l_prefix||'_expdp.dmp'||LF||
        'LOGFILE='||l_prefix||'_expdp.log'||LF||
        'CONTENT=DATA_ONLY';
        IF sqlt$a.get_rdbms_release IN ('11.2','12.1') THEN
           s_file_rec.file_text := s_file_rec.file_text||LF||'CLUSTER=N'||LF;
        ELSE
           s_file_rec.file_text := s_file_rec.file_text||LF;
        END IF;
      ELSE -- 'EXP'
        s_file_rec.file_text :=
        '# COMMAND: exp '||LOWER(TOOL_REPOSITORY_SCHEMA)||sqlt$a.get_param('connect_identifier')||' parfile='||s_file_rec.filename||LF||
        '#'||LF||
        l_tables||
        'FILE='||l_prefix||'_exp.dmp'||LF||
        'LOG='||l_prefix||'_exp.log'||LF||
        'STATISTICS=NONE'||LF||
        'INDEXES=N'||LF||
        'CONSTRAINTS=N'||LF||
        'GRANTS=N'||LF||
        'TRIGGERS=N'||LF;
      END IF;

      s_file_rec.file_text :=
      '# $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $'||LF||
      '#'||LF||
      '# Host    : '||sql_rec.host_name_short||LF||
      '# DB Name : '||sql_rec.database_name_short||LF||
      '# Platform: '||sql_rec.platform||LF||
      '# Product : '||sql_rec.product_version||LF||
      '# Version : '||sql_rec.rdbms_version||LF||
      '# Language: '||sql_rec.language||LF||
      '# EBS     : '||NVL(sql_rec.apps_release, 'NO')||LF||
      '# Siebel  : '||sql_rec.siebel||LF||
      '# PSFT    : '||sql_rec.psft||LF||
      '#'||LF||
      '# If you need to include in export all reports and scripts produced by SQLT'||LF||
      '# remove then the comment for sqli$_file (last table in list below).'||LF||
      '#'||LF||
      s_file_rec.file_text||
      'QUERY="'||l_query||'"';

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'EXPORT_PARFILE',
        p_filename     => s_file_rec.filename,
        p_file_size    => s_file_rec.file_size,
        p_file_text    => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_sqlt_exp_params = s_file_rec.filename
       WHERE statement_id = p_statement_id;
      COMMIT;
      write_log('generated '||s_file_rec.filename);
    ELSE
      write_log('skip repository export as per corresponding parameter export_repository or mask_for_values');
    END IF;

    write_log('<- export_parfile');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('export_parfile:'||SQLERRM);
  END export_parfile;

  /*************************************************************************************/

  /* -------------------------
   *
   * public export_parfile2
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE export_parfile2 (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_prefix VARCHAR2(32767);
    l_tables VARCHAR2(32767);
    l_query VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> export_parfile2');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sqlt$a.get_param('export_repository') = 'Y' AND sqlt$a.get_param('mask_for_values') IN ('CLEAR', 'SECURE') THEN
      IF p_out_file_identifier IS NULL THEN
        l_out_file_identifier := NULL;
      ELSE
        l_out_file_identifier := '_'||p_out_file_identifier;
      END IF;

      l_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier;
      s_file_rec.filename := l_prefix||'_export_parfile2.txt';

      l_query := 'WHERE statid LIKE ''s'||sqlt$a.get_statement_id_c(p_statement_id)||'%''';
      l_tables := 'TABLES=sqlt$_stattab'||LF;

      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        s_file_rec.file_text :=
        '# COMMAND: expdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||sqlt$a.get_param('connect_identifier')||' parfile='||s_file_rec.filename||LF||
        '#'||LF||
        l_tables||
        'DIRECTORY=SQLT$STAGE # '||sqlt$a.get_stage_path||LF||
        'DUMPFILE='||l_prefix||'_expdp2.dmp'||LF||
        'LOGFILE='||l_prefix||'_expdp2.log'||LF||
        'CONTENT=DATA_ONLY';
        IF sqlt$a.get_rdbms_release IN ('11.2','12.1') THEN
           s_file_rec.file_text := s_file_rec.file_text||LF||'CLUSTER=N'||LF;
        ELSE
           s_file_rec.file_text := s_file_rec.file_text||LF;
        END IF;	
      ELSE -- 'EXP'
        s_file_rec.file_text :=
        '# COMMAND: exp '||LOWER(TOOL_REPOSITORY_SCHEMA)||sqlt$a.get_param('connect_identifier')||' parfile='||s_file_rec.filename||LF||
        '#'||LF||
        l_tables||
        'FILE='||l_prefix||'_exp2.dmp'||LF||
        'LOG='||l_prefix||'_exp2.log'||LF||
        'STATISTICS=NONE'||LF||
        'INDEXES=N'||LF||
        'CONSTRAINTS=N'||LF||
        'GRANTS=N'||LF||
        'TRIGGERS=N'||LF;
      END IF;

      s_file_rec.file_text :=
      '# $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $'||LF||
      '#'||LF||
      '# Host    : '||sql_rec.host_name_short||LF||
      '# DB Name : '||sql_rec.database_name_short||LF||
      '# Platform: '||sql_rec.platform||LF||
      '# Product : '||sql_rec.product_version||LF||
      '# Version : '||sql_rec.rdbms_version||LF||
      '# Language: '||sql_rec.language||LF||
      '# EBS     : '||NVL(sql_rec.apps_release, 'NO')||LF||
      '# Siebel  : '||sql_rec.siebel||LF||
      '# PSFT    : '||sql_rec.psft||LF||
      '#'||LF||
      s_file_rec.file_text||
      'QUERY="'||l_query||'"';

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'EXPORT_PARFILE2',
        p_filename     => s_file_rec.filename,
        p_file_size    => s_file_rec.file_size,
        p_file_text    => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_sqlt_exp_params2 = s_file_rec.filename
       WHERE statement_id = p_statement_id;
      COMMIT;
      write_log('generated '||s_file_rec.filename);
    ELSE
      write_log('skip repository export as per corresponding parameter export_repository or mask_for_values');
    END IF;

    write_log('<- export_parfile2');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('export_parfile2:'||SQLERRM);
  END export_parfile2;

  /*************************************************************************************/

  /* -------------------------
   *
   * public export_driver
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE export_driver (
    p_statement_id        IN NUMBER,
    p_password            IN VARCHAR2 DEFAULT 'N',
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_prefix VARCHAR2(32767);
    l_zip_filename VARCHAR2(32767);
    l_utl_filename VARCHAR2(32767);
    l_utility VARCHAR2(32767);
    l_password VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> export_driver');

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    l_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier;
    s_file_rec.filename := l_prefix||'_export_driver.sql';
    sql_rec.file_sqlt_exp_params := l_prefix||'_export_parfile.txt';
    sql_rec.file_sqlt_exp_params2 := l_prefix||'_export_parfile2.txt';
    sql_rec.file_sqlt_imp_script := l_prefix||'_import.sh';
    l_zip_filename := l_prefix||'_export';
    l_utility := LOWER(sqlt$a.get_param('export_utility'));

    l_utl_filename := l_prefix||'_'||l_utility;
    IF l_utility = 'expdp' THEN
      l_utl_filename := sqlt$a.get_stage_full_path||l_utl_filename;
    END IF;

    IF p_password = 'Y' THEN
      l_password := '/'||XTRACT_DEF_CHAR||XTRACT_DEF_CHAR||'enter_tool_password.';
    ELSE
      l_password := NULL;
    END IF;

    IF sqlt$a.get_param('export_repository') = 'Y' AND sqlt$a.get_param('mask_for_values') IN ('CLEAR', 'SECURE') THEN
      s_file_rec.file_text :=
      'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $'||LF||
      'SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;'||LF||
      'EXEC ^^tool_administer_schema..sqlt$a.write_log(''-> Export Driver'',''L'','' drivers'');'||LF||
      'SPO OFF;'||LF||
      'SET TERM ON'||LF||
      'PRO'||LF||
      'PRO *******************************************************************'||LF||
      'PRO * Enter '||TOOL_REPOSITORY_SCHEMA||' valid password to export SQLT repository       *'||LF||
      'PRO * Notes:                                                          *'||LF||
      'PRO * 1. If you entered an incorrect password you will have to enter  *'||LF||
      'PRO *    now both USER and PASSWORD. The latter is case sensitive     *'||LF||
      'PRO * 2. User is '||TOOL_REPOSITORY_SCHEMA||' and not your application user.            *'||LF||
      'PRO *******************************************************************'||LF||
      'HOS '||l_utility||' '||LOWER(TOOL_REPOSITORY_SCHEMA)||l_password||sqlt$a.get_param('connect_identifier')||' parfile='||sql_rec.file_sqlt_exp_params2||LF||
      'HOS '||l_utility||' '||LOWER(TOOL_REPOSITORY_SCHEMA)||l_password||sqlt$a.get_param('connect_identifier')||' parfile='||sql_rec.file_sqlt_exp_params||LF||
      'SET TERM OFF;'||LF||
      'HOS chmod 777 '||sql_rec.file_sqlt_imp_script||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'tc')||' '||l_utl_filename||'.dmp '||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'tc')||' '||sql_rec.file_sqlt_imp_script||' '||LF||
      --'HOS unzip -l '||REPLACE(l_zip_filename, 'export', 'tc')||' '||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'tcx')||' '||l_utl_filename||'2.dmp '||LF||
      --'HOS unzip -l '||REPLACE(l_zip_filename, 'export', 'tcx')||' '||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'log')||' '||l_utl_filename||'.log '||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'log')||' '||l_utl_filename||'2.log '||LF||
      --'HOS unzip -l '||REPLACE(l_zip_filename, 'export', 'log')||' '||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'driver')||' '||s_file_rec.filename||' '||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'driver')||' '||sql_rec.file_sqlt_exp_params||' '||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'driver')||' '||sql_rec.file_sqlt_exp_params2||' '||LF||
      'SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;'||LF||
      'EXEC ^^tool_administer_schema..sqlt$a.write_log(''<- Export Driver'',''L'','' drivers'');'||LF||
      'SPO OFF;'||LF;
      --'HOS unzip -l '||REPLACE(l_zip_filename, 'export', 'driver')||' ';
    ELSE
      s_file_rec.file_text := 'REM skip repository export as per corresponding parameter export_repository or mask_for_values'||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'driver')||' '||s_file_rec.filename||' '||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'driver')||' '||sql_rec.file_sqlt_exp_params||' '||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'export', 'driver')||' '||sql_rec.file_sqlt_exp_params2||' '||LF;
      --'HOS unzip -l '||REPLACE(l_zip_filename, 'export', 'driver')||' ';
    END IF;

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    sqlt$a.set_file (
      p_statement_id => p_statement_id,
      p_file_type    => 'EXPORT_DRIVER',
      p_filename     => s_file_rec.filename,
      p_file_size    => s_file_rec.file_size,
      p_file_text    => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_sqlt_exp_driver = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;
    write_log('generated '||s_file_rec.filename);

    write_log('<- export_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('export_driver:'||SQLERRM);
  END export_driver;

  /*************************************************************************************/

  /* -------------------------
   *
   * public import_script
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE import_script (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_prefix VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> import_script');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sqlt$a.get_param('export_repository') = 'Y' AND sqlt$a.get_param('mask_for_values') IN ('CLEAR', 'SECURE') THEN
      IF p_out_file_identifier IS NULL THEN
        l_out_file_identifier := NULL;
      ELSE
        l_out_file_identifier := '_'||p_out_file_identifier;
      END IF;

      l_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier;
      s_file_rec.filename := l_prefix||'_import.sh';

      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        s_file_rec.file_text :=
        'impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix||'_expdp.dmp'||LF||
        '#'||LF||
        '# Notes:'||LF||
        '# (1) To execute enter: ./'||s_file_rec.filename||LF||
        '# (2) File '||l_prefix||'_expdp.dmp should be placed in SQLT$STAGE directory first.'||LF||
        '# (3) To locate SQLT$STAGE: SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$STAGE'';'||LF||
        '# (4) To change location of SQLT$STAGE use sqlt/utl/sqltcdirs.sql.';
      ELSE -- 'EXP'
        s_file_rec.file_text :=
        'imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix||'_exp.dmp TABLES=sqlt% IGNORE=Y'||LF||
        '#'||LF||
        '# Notes:'||LF||
        '# (1) To execute enter: ./'||s_file_rec.filename||LF||
        '# (2) File '||l_prefix||'_exp.dmp should be placed in same directory than this script.';
      END IF;

      s_file_rec.file_text :=
      '# $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $'||LF||
      '#'||LF||
      '# Host    : '||sql_rec.host_name_short||LF||
      '# DB Name : '||sql_rec.database_name_short||LF||
      '# Platform: '||sql_rec.platform||LF||
      '# Product : '||sql_rec.product_version||LF||
      '# Version : '||sql_rec.rdbms_version||LF||
      '# Language: '||sql_rec.language||LF||
      '# EBS     : '||NVL(sql_rec.apps_release, 'NO')||LF||
      '# Siebel  : '||sql_rec.siebel||LF||
      '# PSFT    : '||sql_rec.psft||LF||
      '#'||LF||
      '# If you need to import all reports and scripts produced by SQLT'||LF||
      '# dmp file must contain them first. Then use sql% instead of sqlt%.'||LF||
      '#'||LF||
      s_file_rec.file_text;

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'IMPORT_SCRIPT',
        p_filename     => s_file_rec.filename,
        p_file_size    => s_file_rec.file_size,
        p_file_text    => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_sqlt_imp_script = s_file_rec.filename
       WHERE statement_id = p_statement_id;
      COMMIT;
      write_log('generated '||s_file_rec.filename);
    ELSE
      write_log('skip repository import script as per corresponding parameter export_repository or mask_for_values');
    END IF;

    write_log('<- import_script');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('import_script:'||SQLERRM);
  END import_script;

  /*************************************************************************************/

  /* -------------------------
   *
   * public tcb_driver
   *
   * called by: sqlt$i.test_case_builder
   *
   * ------------------------- */
  PROCEDURE tcb_driver (
    p_statement_id        IN NUMBER,
    p_generate_script     IN BOOLEAN,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    l_prefix VARCHAR2(32767);
    l_zip_filename VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> tcb_driver');

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    l_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier;
    s_file_rec.filename := l_prefix||'_tcb_driver.sql';
    l_zip_filename := l_prefix||'_tcb';

    IF p_generate_script THEN
      s_file_rec.file_text :=
      'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $'||LF||
      'SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;'||LF||
      'EXEC ^^tool_administer_schema..sqlt$a.write_log(''-> TCB Driver'',''L'','' drivers'');'||LF||
      'SPO OFF'||LF||
      'HOS zip -j '||l_zip_filename||' '||sqlt$a.get_stage_full_path||l_zip_filename||'_* '||sqlt$a.get_stage_full_path||'README.txt '||LF||
      --'HOS unzip -l '||l_zip_filename||' '||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'tcb', 'driver')||' '||s_file_rec.filename||' '||LF||
      'SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;'||LF||
      'EXEC ^^tool_administer_schema..sqlt$a.write_log(''<- TCB Driver'',''L'','' drivers'');'||LF||
      'SPO OFF'||LF;
      --'HOS unzip -l '||REPLACE(l_zip_filename, 'tcb', 'driver')||' ';
    ELSE
      s_file_rec.file_text := 'REM skip test case builder TCB file copy (review log for details)'||LF||
      'HOS zip -m '||REPLACE(l_zip_filename, 'tcb', 'driver')||' '||s_file_rec.filename||' '||LF;
      --'HOS unzip -l '||REPLACE(l_zip_filename, 'tcb', 'driver')||' ';
    END IF;

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    sqlt$a.set_file (
      p_statement_id => p_statement_id,
      p_file_type    => 'TCB_DRIVER',
      p_filename     => s_file_rec.filename,
      p_file_size    => s_file_rec.file_size,
      p_file_text    => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_sqlt_tcbuilder = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;
    write_log('generated '||s_file_rec.filename);

    write_log('<- tcb_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tcb_driver:'||SQLERRM);
  END tcb_driver;

  /* -------------------------
   *
   * public xpand_sql_driver
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE xpand_sql_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    l_prefix VARCHAR2(32767);
    l_zip_filename VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);
	
    /* -------------------------
     *
     * private xpand_sql_driver.wa - write append
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

  BEGIN
    write_log('-> xpand_sql_driver');

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    l_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier;
    s_file_rec.filename := l_prefix||'_xpand_sql_driver.sql';

    IF sqlt$a.get_rdbms_version LIKE '11.2.0.3%' OR sqlt$a.get_rdbms_version LIKE '11.2.0.4%' THEN
      s_file_rec.file_text :=
      'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $'||LF;
      
      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''-> XPAND SQL Driver'',''L'','' drivers'');');
      wa('SPO OFF');
      wa('VAR c1 CLOB');
      wa('VAR c2 CLOB');
      wa('');
      wa('BEGIN');
      wa(' SELECT SQL_TEXT_CLOB INTO :c1 FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_sql_statement WHERE statement_id = '||p_statement_id||';');
      wa('END;');
      wa('/');
      wa('');
      wa('EXEC DBMS_SQL2.EXPAND_SQL_TEXT(:c1,:c2);');
      wa('');
      wa('SET LINE 220 PAGESIZE 0 LONG 1000000 LONGCHUNKSIZE 1000000');
      wa('SPOO sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_xpand.sql');
      wa('SELECT :c2 FROM DUAL;');
      wa('SPOO OFF');
      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''<- XPAND SQL Driver'',''L'','' drivers'');');
      wa('SPO OFF');
    ELSIF sqlt$a.get_rdbms_release = '12.1' THEN
      s_file_rec.file_text :=
      'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $'||LF;
      
      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''-> XPAND SQL Driver'',''L'','' drivers'');');
      wa('SPO OFF');	  
      wa('VAR c1 CLOB');
      wa('VAR c2 CLOB');
      wa('');
      wa('BEGIN');
      wa(' SELECT SQL_TEXT_CLOB INTO :c1 FROM '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$_sql_statement WHERE statement_id = '||p_statement_id||';');
      wa('END;');
      wa('/');
      wa('');
      wa('EXEC DBMS_UTILITY.EXPAND_SQL_TEXT(:c1,:c2);');
      wa('');
      wa('SET LINE 220 PAGESIZE 0 LONG 1000000 LONGCHUNKSIZE 1000000');
      wa('SPOO sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_xpand.sql');
      wa('SELECT :c2 FROM DUAL;');
      wa('SPOO OFF');	
      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''<- XPAND SQL Driver'',''L'','' drivers'');');	
      wa('SPO OFF;');	  
    ELSE
      s_file_rec.file_text := 'REM skip SQL expand functionality due to old version';
    END IF;

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    sqlt$a.set_file (
      p_statement_id => p_statement_id,
      p_file_type    => 'XPAND_SQL_DRIVER',
      p_filename     => s_file_rec.filename,
      p_file_size    => s_file_rec.file_size,
      p_file_text    => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_sqlt_tcbuilder = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;
    write_log('generated '||s_file_rec.filename);

    write_log('<- xpand_sql_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('xpand_sql_driver:'||SQLERRM);
  END xpand_sql_driver;  

  /*************************************************************************************/

  /* -------------------------
   *
   * public remote_driver
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE remote_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    l_count NUMBER := 0;
    l_file_name_prefix  VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);

    /* -------------------------
     *
     * private remote_driver.wa - write append
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

  BEGIN
    write_log('-> remote_driver');

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_remote_driver.sql';
    s_file_rec.file_text :=
    'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $';
    wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
    wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''-> Remote Driver'',''L'','' drivers'');');
    wa('SPO OFF;');

    IF sqlt$a.get_param('distributed_queries') = 'Y' THEN
      -- for each remote sqlt
      FOR i IN (SELECT DISTINCT
                       statement_id, -- remote
                       db_link
                  FROM sqli$_file
                 WHERE statement_id2 = p_statement_id -- local
                   AND db_link IS NOT NULL
                 ORDER BY
                       statement_id)
      LOOP
        FOR j IN (SELECT DISTINCT
                         filename
                    FROM sqli$_file
                   WHERE statement_id2 = p_statement_id -- local
                     AND statement_id = i.statement_id -- remote
                     AND db_link = i.db_link
                   ORDER BY
                         filename)
        LOOP
          wa('SET TERM ON;');
          wa('PRO ... getting '||j.filename||' out of sqlt repository ...');
          wa('SET TERM OFF;');
          wa('SPO '||j.filename||';');
          wa('SELECT * FROM TABLE('||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$r.display_file('''||j.filename||''', '||p_statement_id||', '||i.statement_id||'));');
          wa('SPO OFF;');
          wa('--');
        END LOOP;

        l_file_name_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_'||sqlt$a.get_db_link_short(i.db_link)||'_s'||sqlt$a.get_statement_id_c(i.statement_id);

        wa('HOS chmod 777 xpress.sh');
        wa('HOS zip -m '||l_file_name_prefix||'_tc '||l_file_name_prefix||'_system_stats.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc '||l_file_name_prefix||'_metadata.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc '||l_file_name_prefix||'_set_cbo_env.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc '||l_file_name_prefix||'_readme.txt ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc '||l_file_name_prefix||'_purge.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc '||l_file_name_prefix||'_restore.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc q.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc plan.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc 10053.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc flush.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc tc.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc tc_pkg.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc xpress.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc xpress.sh ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc setup.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc readme.txt ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc sel.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tc sel_aux.sql ');
        --wa('HOS unzip -l '||l_file_name_prefix||'_tc ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx '||l_file_name_prefix||'_system_stats.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx '||l_file_name_prefix||'_schema_stats.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx '||l_file_name_prefix||'_metadata1.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx '||l_file_name_prefix||'_metadata2.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx '||l_file_name_prefix||'_set_cbo_env.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx q.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx plan.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx 10053.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx flush.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx tc.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx tc_pkg.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx install.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx install.sh ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx sel.sql ');
        wa('HOS zip -m '||l_file_name_prefix||'_tcx sel_aux.sql ');
        --wa('HOS unzip -l '||l_file_name_prefix||'_tcx ');

        wa('HOS zip -m '||l_file_name_prefix||' '||l_file_name_prefix||'*.* ');
        --wa('HOS unzip -l '||l_file_name_prefix||' ');
        wa('--');
      END LOOP;

      FOR i IN (SELECT DISTINCT db_link
                  FROM sqli$_file
                 WHERE statement_id = p_statement_id
                   AND db_link IS NOT NULL
                 ORDER BY
                       db_link)
      LOOP
        l_count := l_count + 1;

        FOR j IN (SELECT DISTINCT
                         filename
                    FROM sqli$_file
                   WHERE statement_id = p_statement_id
                     AND statement_id2 IS NULL
                     AND db_link = i.db_link
                   ORDER BY
                         filename)
        LOOP
          wa('SET TERM ON;');
          wa('PRO ... getting '||j.filename||' out of sqlt repository ...');
          wa('SET TERM OFF;');
          wa('SPO '||j.filename||';');
          wa('SELECT * FROM TABLE('||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$r.display_file('''||j.filename||''', '||p_statement_id||'));');
          wa('SPO OFF;');
          wa('--');
        END LOOP;

        wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_remote sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_'||sqlt$a.get_db_link_short(i.db_link)||'_*.* ');
      END LOOP;

      IF l_count > 0 THEN
        wa('--');
        --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_remote ');
      END IF;
    END IF;

    wa('--');
    wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver '||s_file_rec.filename||' ');
    --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver ');
    wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
    wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''<- Remote Driver'',''L'','' drivers'');');
    wa('SPO OFF;');

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    sqlt$a.set_file (
      p_statement_id => p_statement_id,
      p_file_type    => 'REMOTE_DRIVER',
      p_filename     => s_file_rec.filename,
      p_file_size    => s_file_rec.file_size,
      p_file_text    => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_remote_driver = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;
    write_log('generated '||s_file_rec.filename);

    write_log('<- remote_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('remote_driver:'||SQLERRM);
  END remote_driver;

  /*************************************************************************************/
  /* -------------------------
   *
   * public perfhub_driver
   *
   * called by: sqlt$i.common_calls
   * 160403 New
   * ------------------------- */
  PROCEDURE perfhub_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);
    l_count NUMBER := 0;
    l_filename varchar2(1000);

    /* -------------------------
     *
     * private perfhub_driver.wa - write append
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

  BEGIN
    write_log('-> perfhub_driver');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sqlt$a.get_param('automatic_workload_repository') = 'N' THEN
      write_log('skip "perfhub_driver" as per automatic_workload_repository parameter');
    ELSIF sqlt$a.get_param('sql_monitoring') = 'N' THEN
          write_log('skip "perfhub_driver" as per sql_monitoring parameter');
    ELSIF sqlt$a.get_param_n('perfhub_reports') < 1 THEN
	  write_log('skip "perfhub_driver" as per perfhub_reports parameter');
    ELSIF sql_rec.rdbms_release < 12 THEN
      write_log('skip "perfhub_driver" since not available in "'||sql_rec.rdbms_version||'"');
    ELSIF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip "perfhub_driver" for this method');
    ELSE
      IF p_out_file_identifier IS NULL THEN
        l_out_file_identifier := NULL;
      ELSE
        l_out_file_identifier := '_'||p_out_file_identifier;
      END IF;
 
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_perfhub_driver.sql';
      s_file_rec.file_text :=
      'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $';

      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''-> PerfHub Driver'',''L'','' drivers'');');
      wa('SPO OFF;');
      wa('VAR dbid NUMBER;');
      wa('VAR inst_num NUMBER;');
      wa('VAR bid NUMBER;');
      wa('VAR eid NUMBER;');
      wa('VAR rpt_options NUMBER;');
      wa('EXEC :rpt_options := 0;');
      wa('SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF;');
          
      FOR i IN (SELECT dbid,
                       to_char(BEGIN_INTERVAL_TIME,'YYYY-MM-DD/HH24:MI:SS') bid, 
                       to_char(END_INTERVAL_TIME,'YYYY-MM-DD/HH24:MI:SS') eid,
                       rownum rwnum
                  FROM (SELECT SUM(e.elapsed_time_delta) elapsed_time_delta,
                               e.dbid, e.instance_number inst_num,
                               b.begin_interval_time, e.end_interval_time
                          FROM sqlt$_dba_hist_snapshot b,
                               sqlt$_dba_hist_sqlstat_v e
                         WHERE e.statement_id = p_statement_id
                           AND b.statement_id = e.statement_id
                           AND b.snap_id = e.snap_id - 1
                           AND b.dbid = e.dbid
                           AND b.instance_number = e.instance_number
                           AND b.startup_time = e.startup_time
                         GROUP BY
                               e.dbid, e.instance_number, b.begin_interval_time, e.end_interval_time
                         UNION ALL 
                        SELECT -1,null,null,null,null from dual
                         ORDER BY
                             1 DESC)
               )
      LOOP
        IF i.rwnum> sqlt$a.get_param_n('perfhub_reports') THEN
          EXIT; -- exits loop
        END IF;
        l_filename:=REPLACE(s_file_rec.filename, 'driver.sql')||LPAD(i.rwnum, 4, '0')||'_'||i.bid||'_'||i.eid||'.html';                    

        wa('EXEC :dbid := '||nvl(TO_CHAR(i.dbid),'NULL')||';');

        -- For the moment make it for all instances
        --wa('EXEC :inst_num := '||TO_CHAR(i.inst_num)||';');
        --'_'||TO_CHAR(i.inst_num)||
        
        wa('EXEC :inst_num := NULL');
        
        wa('EXEC :bid := '''||i.bid||''';');
        wa('EXEC :eid := '''||i.eid||''';');
        wa('SET TERM ON;');
        wa('PRO ... generating '||l_filename||' ...');
        wa('SET TERM OFF;');
        wa('SPO '||l_filename||';');
        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');

        wa('SELECT '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.report_perfhub (:bid,:eid,null,:dbid) from dual;');

        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
        wa('SPO OFF;');
      END LOOP;

      IF l_count > 0 THEN
        wa('--');
        wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_perfhub_'||LPAD(l_count, 4, '0')||' '||REPLACE(s_file_rec.filename, 'driver.sql', '*.html')||' ');

      END IF;

      wa('--');
      wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver '||s_file_rec.filename||' ');

      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''<- PerfHub Driver'',''L'','' drivers'');');
      wa('SPO OFF;');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'PERFHUB_DRIVER',
        p_filename     => s_file_rec.filename,
        p_file_size    => s_file_rec.file_size,
        p_file_text    => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_perfhub_driver = s_file_rec.filename
       WHERE statement_id = p_statement_id;

      write_log('generated '||s_file_rec.filename);
    END IF;

    COMMIT;
    write_log('<- perfhub_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('perfhub_driver:'||SQLERRM);
  END perfhub_driver;

  /*************************************************************************************/

  /* -------------------------
   *
   * public sql_monitor_driver
   *
   * called by: sqlt$i.xtract, sqlt$i.xecute_end and sqlt$i.xplain_end
   *
   * ------------------------- */
  PROCEDURE sql_monitor_driver(p_statement_id IN NUMBER)
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_count NUMBER := 0;
    TYPE mon_rt IS RECORD (
      sql_exec_start DATE,
      sql_exec_id NUMBER,
      sql_plan_hash_value NUMBER,
      inst_id NUMBER );
    mon_rec mon_rt;
    mon_cv SYS_REFCURSOR;

    /* -------------------------
     *
     * private sql_monitor_driver.wa - write append
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

  BEGIN
    write_log('-> sql_monitor_driver');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sqlt$a.get_param('sql_monitoring') = 'N' THEN
      write_log('skip "sql_monitor_driver" as per sql_monitoring parameter');
    ELSIF sqlt$a.get_param_n('sql_monitor_reports') < 2 THEN
      write_log('skip "sql_monitor_driver" as per sql_monitor_reports parameter');
    ELSIF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip "sql_monitor_driver" for this method');
    ELSIF sql_rec.rdbms_release < 11 THEN
      write_log('skip "sql_monitor_driver" since not available in "'||sql_rec.rdbms_version||'"');
    ELSE
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_sql_monitor_active_driver.sql';
      s_file_rec.file_text :=
      'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $';

      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''-> SQL Monitor Driver'',''L'','' drivers'');');
      wa('SPO OFF;');
      wa('VAR mon_exec_start VARCHAR2(14);');
      wa('VAR mon_exec_id NUMBER;');
      wa('VAR mon_sql_plan_hash_value NUMBER;');
      wa('VAR mon_inst_id NUMBER;');
      wa('VAR mon_report CLOB;');
      wa('VAR mon_sql_id VARCHAR2(13);');
      wa('EXEC :mon_sql_id := '''||sql_rec.sql_id||''';');
      wa('SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF;');

      -- using gv$sql_monitor instead of sqlt$_gv$sql_monitor to be more up to date
      -- cursor variable to avoid error on 10g since v$sql_monitor didn't exist then
	  -- 22170176 use bind for sql_id
      OPEN mon_cv FOR
        'SELECT DISTINCT '||
        '       sql_exec_start, '||
        '       sql_exec_id, '||
        '       sql_plan_hash_value, '||
        '       inst_id '||
        '  FROM gv$sql_monitor /* 11g */ '||
        ' WHERE process_name = ''ora'' '||
        '   AND sql_id = :b_sql_id '||
        ' ORDER BY '||
        '       1 DESC, '||
        '       2 DESC'
		USING sql_rec.sql_id;
      LOOP
        FETCH mon_cv INTO mon_rec;
        EXIT WHEN mon_cv%NOTFOUND;

        l_count := l_count + 1;
        IF l_count > sqlt$a.get_param_n('sql_monitor_reports') THEN
          EXIT; -- exits loop
        END IF;

        wa('EXEC :mon_exec_start := '''||TO_CHAR(mon_rec.sql_exec_start, 'YYYYMMDDHH24MISS')||''';');
        wa('EXEC :mon_exec_id := '||TO_CHAR(mon_rec.sql_exec_id)||';');
        wa('EXEC :mon_sql_plan_hash_value := '||TO_CHAR(mon_rec.sql_plan_hash_value)||';');
        wa('EXEC :mon_inst_id := '||TO_CHAR(mon_rec.inst_id)||';');
        wa('SET TERM ON;');
        wa('PRO ... generating '||REPLACE(s_file_rec.filename, 'driver.sql')||TO_CHAR(mon_rec.sql_exec_id)||'_'||TO_CHAR(mon_rec.sql_plan_hash_value)||'_'||TO_CHAR(mon_rec.inst_id)||'.html ...');
        wa('SET TERM OFF;');
        wa('SPO '||REPLACE(s_file_rec.filename, 'driver.sql')||TO_CHAR(mon_rec.sql_exec_id)||'_'||TO_CHAR(mon_rec.sql_plan_hash_value)||'_'||TO_CHAR(mon_rec.inst_id)||'.html;');
        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
        wa('PRO <!-- begin SYS.DBMS_SQLTUNE.REPORT_SQL_MONITOR');
        wa('BEGIN');
        wa('  :mon_report := '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.report_sql_monitor (');
        wa('    p_sql_id         => :mon_sql_id,');
        wa('    p_sql_exec_start => TO_DATE(:mon_exec_start, ''YYYYMMDDHH24MISS''),');
        wa('    p_sql_exec_id    => :mon_exec_id,');
        wa('    p_report_level   => ''ALL'',');
        wa('    p_type           => ''ACTIVE'' );');
        wa('END;');
        wa('/');
        wa('PRO end -->');
        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');

        IF sql_rec.rdbms_version LIKE '11.1%' THEN
          wa('PRO <html>');
          wa('PRO <head>');
          wa('PRO  <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>');
          wa('PRO  <base href="http://download.oracle.com/otn_software/"/>');
          wa('PRO  <script language="javascript" type="text/javascript" src="emviewers/scripts/flashver.js">');
          wa('PRO   <!--Test flash version-->');
          wa('PRO  </script>');
          wa('PRO  <style>');
          wa('PRO      body { margin: 0px; overflow:hidden }');
          wa('PRO    </style>');
          wa('PRO </head>');
          wa('PRO <body scroll="no">');
          wa('PRO  <script type="text/xml">');
          wa('PRO   <!--FXTMODEL-->');
        END IF;

        wa('SELECT :mon_report FROM DUAL;');

        IF sql_rec.rdbms_version LIKE '11.1%' THEN
          wa('PRO    <!--FXTMODEL-->');
          wa('PRO   </script>');
          wa('PRO   <script language="JavaScript" type="text/javascript" src="emviewers/scripts/loadswf.js">');
          wa('PRO    <!--Load report viewer-->');
          wa('PRO   </script>');
          wa('PRO   <iframe name="_history" frameborder="0" scrolling="no" width="22" height="0">');
          wa('PRO    <html>');
          wa('PRO     <head>');
          wa('PRO      <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"/>');
          wa('PRO      <script type="text/javascript" language="JavaScript1.2" charset="utf-8">');
          wa('PRO                 var v = new top.Vars(top.getSearch(window)); <!-- ; -->');
          wa('PRO                 var fv = v.toString("$_"); <!-- ; -->');
          wa('PRO               </script>');
          wa('PRO     </head>');
          wa('PRO     <body>');
          wa('PRO      <script type="text/javascript" language="JavaScript1.2" charset="utf-8" src="emviewers/scripts/document.js">');
          wa('PRO       <!--Run document script-->');
          wa('PRO      </script>');
          wa('PRO     </body>');
          wa('PRO    </html>');
          wa('PRO   </iframe>');
          wa('PRO  </body>');
          wa('PRO </html>');
        END IF;

        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
        wa('SPO OFF;');
      END LOOP;
      CLOSE mon_cv;

	 -- 150911 get 12c historic sql monitor reports if not enough from memory
	 -- 22170176 use bind for sql_id
	  IF l_count <=sqlt$a.get_param_n('sql_monitor_reports') THEN
	  
	      OPEN mon_cv FOR
        'SELECT DISTINCT       '||
        '       GENERATION_TIME  sql_exec_start, '||
        '       REPORT_ID        sql_exec_id, '||
        '       null             sql_plan_hash_value, '||
        '       INSTANCE_NUMBER  inst_id '||
        '  FROM sys.dba_hist_reports /* 12c */ '||
        ' WHERE key1 = :b_sql_id '||
        ' ORDER BY '||
        '       1 DESC, '||
        '       2 DESC'
		using sql_rec.sql_id;
       LOOP
        FETCH mon_cv INTO mon_rec;
        EXIT WHEN mon_cv%NOTFOUND;

        l_count := l_count + 1;
        IF l_count > sqlt$a.get_param_n('sql_monitor_reports') THEN
          EXIT; -- exits loop
        END IF;  
	  
	    wa('EXEC :mon_exec_id := '||TO_CHAR(mon_rec.sql_exec_id)||';');
        wa('SET TERM ON;');
        wa('PRO ... generating '||REPLACE(s_file_rec.filename, 'driver.sql')||TO_CHAR(mon_rec.sql_exec_id)||'_'||TO_CHAR(mon_rec.sql_plan_hash_value)||'_'||TO_CHAR(mon_rec.inst_id)||'.html ...');
        wa('SET TERM OFF;');
        wa('SPO '||REPLACE(s_file_rec.filename, 'driver.sql')||TO_CHAR(mon_rec.sql_exec_id)||'_'||TO_CHAR(mon_rec.inst_id)||'.html;');
        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
        wa('PRO <!-- begin SYS.DBMS_AUTO_REPORT.REPORT_REPOSITORY_DETAIL');
        wa('BEGIN');
        wa('  :mon_report := '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.report_hist_sql_monitor (');
        wa('    p_report_id      => :mon_exec_id,');
        wa('    p_type           => ''ACTIVE'' );');
        wa('END;');
        wa('/');
        wa('PRO end -->');
        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
        wa('SELECT :mon_report FROM DUAL;');
        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
        wa('SPO OFF;');
       END LOOP;
       CLOSE mon_cv;
	  END IF;

	  
      IF l_count > 0 THEN
        wa('--');
        wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_sql_monitor_active_'||LPAD(l_count, 4, '0')||' '||REPLACE(s_file_rec.filename, 'driver.sql', '*.html')||' ');
        --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_sql_monitor_active_'||LPAD(l_count, 4, '0')||' ');
      END IF;

      wa('--');
      wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver '||s_file_rec.filename||' ');
      --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver ');
      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''<- SQL Monitor Driver'',''L'','' drivers'');');
      wa('SPO OFF');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'SQL_MONITOR_DRIVER',
        p_filename     => s_file_rec.filename,
        p_file_size    => s_file_rec.file_size,
        p_file_text    => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_mon_report_driver = s_file_rec.filename
       WHERE statement_id = p_statement_id;

      write_log('generated '||s_file_rec.filename);
    END IF;

    COMMIT;
    write_log('<- sql_monitor_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sql_monitor_driver:'||SQLERRM);
  END sql_monitor_driver;

  /*************************************************************************************/

  /* -------------------------
   *
   * public awrrpt_driver
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE awrrpt_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);
    l_count NUMBER := 0;

    /* -------------------------
     *
     * private awrrpt_driver.wa - write append
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

  BEGIN
    write_log('-> awrrpt_driver');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sqlt$a.get_param('automatic_workload_repository') = 'N' THEN
      write_log('skip "awrrpt_driver" as per automatic_workload_repository parameter');
    ELSIF sqlt$a.get_param_n('awr_reports') < 1 THEN
      write_log('skip "awrrpt_driver" as per awr_reports parameter');
    ELSIF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip "awrrpt_driver" for this method');
    ELSE
      IF p_out_file_identifier IS NULL THEN
        l_out_file_identifier := NULL;
      ELSE
        l_out_file_identifier := '_'||p_out_file_identifier;
      END IF;

      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_awrrpt_driver.sql';
      s_file_rec.file_text :=
      'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $';

      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''-> AWR Reports Driver'',''L'','' drivers'');');
      wa('SPO OFF;');
      wa('VAR dbid NUMBER;');
      wa('VAR inst_num NUMBER;');
      wa('VAR bid NUMBER;');
      wa('VAR eid NUMBER;');
      wa('VAR rpt_options NUMBER;');
      wa('EXEC :rpt_options := 0;');
      wa('SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF;');

      FOR i IN (SELECT SUM(e.elapsed_time_delta) elapsed_time_delta,
                       e.dbid, e.instance_number inst_num, b.snap_id bid, e.snap_id eid
                  FROM sqlt$_dba_hist_snapshot b,
                       sqlt$_dba_hist_sqlstat_v e
                 WHERE e.statement_id = p_statement_id
                   AND b.statement_id = e.statement_id
                   AND b.snap_id = e.snap_id - 1
                   AND b.dbid = e.dbid
                   AND b.instance_number = e.instance_number
                   AND b.startup_time = e.startup_time
                 GROUP BY
                       e.dbid, e.instance_number, b.snap_id, e.snap_id
                 ORDER BY
                       1 DESC)
      LOOP
        l_count := l_count + 1;
        IF l_count > sqlt$a.get_param_n('awr_reports') THEN
          EXIT; -- exits loop
        END IF;

        wa('EXEC :dbid := '||TO_CHAR(i.dbid)||';');
        wa('EXEC :inst_num := '||TO_CHAR(i.inst_num)||';');
        wa('EXEC :bid := '||TO_CHAR(i.bid)||';');
        wa('EXEC :eid := '||TO_CHAR(i.eid)||';');
        wa('SET TERM ON;');
        wa('PRO ... generating '||REPLACE(s_file_rec.filename, 'driver.sql')||LPAD(l_count, 4, '0')||'_'||TO_CHAR(i.inst_num)||'_'||TO_CHAR(i.bid)||'_'||TO_CHAR(i.eid)||'.html ...');
        wa('SET TERM OFF;');
        wa('SPO '||REPLACE(s_file_rec.filename, 'driver.sql')||LPAD(l_count, 4, '0')||'_'||TO_CHAR(i.inst_num)||'_'||TO_CHAR(i.bid)||'_'||TO_CHAR(i.eid)||'.html;');
        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
        --wa('SELECT output FROM TABLE(SYS.DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_HTML(:dbid, :inst_num, :bid, :eid, :rpt_options));');
        wa('SELECT column_value FROM TABLE('||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.awr_report_html(:dbid, :inst_num, :bid, :eid, :rpt_options));');
        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
        wa('SPO OFF;');
      END LOOP;

      IF l_count > 0 THEN
        wa('--');
        wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_awrrpt_'||LPAD(l_count, 4, '0')||' '||REPLACE(s_file_rec.filename, 'driver.sql', '*.html')||' ');
        --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_awrrpt_'||LPAD(l_count, 4, '0')||' ');
      END IF;

      wa('--');
      wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver '||s_file_rec.filename||' ');
      --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver ');
      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''<- AWR Reports Driver'',''L'','' drivers'');');
      wa('SPO OFF;');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'AWRRPT_DRIVER',
        p_filename     => s_file_rec.filename,
        p_file_size    => s_file_rec.file_size,
        p_file_text    => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_awrrpt_driver = s_file_rec.filename
       WHERE statement_id = p_statement_id;

      write_log('generated '||s_file_rec.filename);
    END IF;

    COMMIT;
    write_log('<- awrrpt_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('awrrpt_driver:'||SQLERRM);
  END awrrpt_driver;

  /*************************************************************************************/

  /* -------------------------
   *
   * public addmrpt_driver
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE addmrpt_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);
    l_count NUMBER := 0;

    /* -------------------------
     *
     * private addmrpt_driver.wa - write append
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

  BEGIN
    write_log('-> addmrpt_driver');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sqlt$a.get_param('automatic_workload_repository') = 'N' THEN
      write_log('skip "addmrpt_driver" as per automatic_workload_repository parameter');
    ELSIF sqlt$a.get_param_n('addm_reports') < 1 THEN
      write_log('skip "addmrpt_driver" as per addm_reports parameter');
    ELSIF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip "addmrpt_driver" for this method');
    ELSE
      IF p_out_file_identifier IS NULL THEN
        l_out_file_identifier := NULL;
      ELSE
        l_out_file_identifier := '_'||p_out_file_identifier;
      END IF;

      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_addmrpt_driver.sql';
      s_file_rec.file_text :=
      'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $';

      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''-> ADDM Reports Driver'',''L'','' drivers'');');
      wa('SPO OFF;');
      wa('VAR dbid NUMBER;');
      wa('VAR inst_num NUMBER;');
      wa('VAR bid NUMBER;');
      wa('VAR eid NUMBER;');
      wa('VAR task_name VARCHAR2(100);');
      wa('SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF;');

      FOR i IN (SELECT SUM(e.elapsed_time_delta) elapsed_time_delta,
                       e.dbid, e.instance_number inst_num, b.snap_id bid, e.snap_id eid
                  FROM sqlt$_dba_hist_snapshot b,
                       sqlt$_dba_hist_sqlstat_v e
                 WHERE e.statement_id = p_statement_id
                   AND b.statement_id = e.statement_id
                   AND b.snap_id = e.snap_id - 1
                   AND b.dbid = e.dbid
                   AND b.instance_number = e.instance_number
                   AND b.startup_time = e.startup_time
                 GROUP BY
                       e.dbid, e.instance_number, b.snap_id, e.snap_id
                 ORDER BY
                       1 DESC)
      LOOP
        l_count := l_count + 1;
        IF l_count > sqlt$a.get_param_n('addm_reports') THEN
          EXIT; -- exits loop
        END IF;

        wa('EXEC :dbid := '||TO_CHAR(i.dbid)||';');
        wa('EXEC :inst_num := '||TO_CHAR(i.inst_num)||';');
        wa('EXEC :bid := '||TO_CHAR(i.bid)||';');
        wa('EXEC :eid := '||TO_CHAR(i.eid)||';');
        wa('SET TERM ON;');
        wa('PRO ... generating '||REPLACE(s_file_rec.filename, 'driver.sql')||LPAD(l_count, 4, '0')||'_'||TO_CHAR(i.inst_num)||'_'||TO_CHAR(i.bid)||'_'||TO_CHAR(i.eid)||'.txt ...');
        wa('SET TERM OFF;');
        wa('EXEC :task_name := &&tool_administer_schema..sqlt$a.dbms_addm_analyze_inst(p_dbid => :dbid, p_inst_num => :inst_num, p_bid => :bid, p_eid => :eid);');
        wa('SPO '||REPLACE(s_file_rec.filename, 'driver.sql')||LPAD(l_count, 4, '0')||'_'||TO_CHAR(i.inst_num)||'_'||TO_CHAR(i.bid)||'_'||TO_CHAR(i.eid)||'.txt;');
        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
        wa('SELECT SYS.DBMS_ADVISOR.GET_TASK_REPORT(:task_name, ''TEXT'', ''TYPICAL'') FROM SYS.DUAL;');
        wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
        wa('SPO OFF;');
      END LOOP;

      IF l_count > 0 THEN
        wa('--');
        wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_addmrpt_'||LPAD(l_count, 4, '0')||' '||REPLACE(s_file_rec.filename, 'driver.sql', '*.txt')||' ');
        --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_addmrpt_'||LPAD(l_count, 4, '0')||' ');
      END IF;

      wa('--');
      wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver '||s_file_rec.filename||' ');
      --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver ');
      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''<- ADDM Reports Driver'',''L'','' drivers'');');
      wa('SPO OFF;');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'ADDMRPT_DRIVER',
        p_filename     => s_file_rec.filename,
        p_file_size    => s_file_rec.file_size,
        p_file_text    => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_addmrpt_driver = s_file_rec.filename
       WHERE statement_id = p_statement_id;

      write_log('generated '||s_file_rec.filename);
    END IF;

    COMMIT;
    write_log('<- addmrpt_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('addmrpt_driver:'||SQLERRM);
  END addmrpt_driver;

  /*************************************************************************************/

  /* -------------------------
   *
   * public ashrpt_driver
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE ashrpt_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);
    l_count NUMBER := 0;
    l_rep_date VARCHAR2(9);

    /* -------------------------
     *
     * private ashrpt_driver.wa - write append
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

  BEGIN
    write_log('-> ashrpt_driver');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sqlt$a.get_param('automatic_workload_repository') = 'N' THEN
      write_log('skip "ashrpt_driver" as per automatic_workload_repository parameter');
    ELSIF sqlt$a.get_param('ash_reports_source') = 'NONE' THEN
      write_log('skip "ashrpt_driver" as per ash_reports_source parameter');
    ELSIF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip "ashrpt_driver" for this method');
    ELSE
      IF p_out_file_identifier IS NULL THEN
        l_out_file_identifier := NULL;
      ELSE
        l_out_file_identifier := '_'||p_out_file_identifier;
      END IF;

      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_ashrpt_driver.sql';
      s_file_rec.file_text :=
      'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $';

      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''-> ASH Reports Driver'',''L'','' drivers'');');
      wa('SPO OFF;');
      wa('VAR dbid         NUMBER;');
      wa('VAR inst_num     NUMBER;');
      wa('VAR btime        VARCHAR2(14);');
      wa('VAR etime        VARCHAR2(14);');
      wa('VAR options      NUMBER;');
      wa('VAR slot_width   NUMBER;');
      wa('VAR sid          NUMBER;');
      wa('VAR sql_id       VARCHAR2(13);');
      wa('VAR wait_class   VARCHAR2(64);');
      wa('VAR service_hash NUMBER;');
      wa('VAR module       VARCHAR2(64);');
      wa('VAR action       VARCHAR2(64);');
      wa('VAR client_id    VARCHAR2(64);');
      wa('VAR plsql_entry  VARCHAR2(64);');
      wa('VAR data_src     NUMBER;');

      wa('EXEC :dbid := '||sql_rec.database_id||';');
      wa('EXEC :options := 0;');
      wa('EXEC :slot_width := 0;');
      wa('EXEC :sid := NULL;');
      wa('EXEC :sql_id := '''||sql_rec.sql_id||''';');
      wa('EXEC :wait_class := NULL;');
      wa('EXEC :service_hash := NULL;');
      wa('EXEC :module := NULL;');
      wa('EXEC :action := NULL;');
      wa('EXEC :client_id := NULL;');
      wa('EXEC :plsql_entry := NULL;');

      wa('SET ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF;');

      IF sqlt$a.get_param('ash_reports_source') IN ('MEM', 'BOTH') THEN
        wa('EXEC :data_src := 1;');

        FOR i IN (SELECT inst_id,
                         MIN(sample_time) min_sample_time,
                         MAX(sample_time) max_sample_time
                    FROM sqlt$_gv$active_session_histor
                   WHERE statement_id = p_statement_id
                     AND sql_id = sql_rec.sql_id
                   GROUP BY
                         inst_id
                   ORDER BY
                         inst_id)
        LOOP
          l_count := l_count + 1;
          l_rep_date := TO_CHAR(i.max_sample_time, 'MMDD_HH24MI');

          wa('EXEC :inst_num := '||TO_CHAR(i.inst_id)||';');
          wa('EXEC :btime := '''||TO_CHAR(i.min_sample_time, 'YYYYMMDDHH24MISS')||''';');
          wa('EXEC :etime := '''||TO_CHAR(i.max_sample_time, 'YYYYMMDDHH24MISS')||''';');
          wa('SET TERM ON;');
          wa('PRO ... generating '||REPLACE(s_file_rec.filename, 'driver.sql')||LPAD(l_count, 4, '0')||'_mem_'||TO_CHAR(i.inst_id)||'_'||l_rep_date||'.html ...');
          wa('SET TERM OFF;');

          wa('SPO '||REPLACE(s_file_rec.filename, 'driver.sql')||LPAD(l_count, 4, '0')||'_mem_'||TO_CHAR(i.inst_id)||'_'||l_rep_date||'.html;');
          wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
          IF sql_rec.rdbms_release < 11 THEN
            --wa('SELECT output FROM TABLE(SYS.DBMS_WORKLOAD_REPOSITORY.ASH_REPORT_HTML(:dbid, :inst_num, TO_DATE(:btime, ''YYYYMMDDHH24MISS''), TO_DATE(:etime, ''YYYYMMDDHH24MISS''), :options, :slot_width, :sid, :sql_id, :wait_class, :service_hash, :module, :action, :client_id));');
            wa('SELECT column_value FROM TABLE('||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.ash_report_html_10(:dbid, :inst_num, TO_DATE(:btime, ''YYYYMMDDHH24MISS''), TO_DATE(:etime, ''YYYYMMDDHH24MISS''), :options, :slot_width, :sid, :sql_id, :wait_class, :service_hash, :module, :action, :client_id));');
          ELSE
            --wa('SELECT output FROM TABLE(SYS.DBMS_WORKLOAD_REPOSITORY.ASH_REPORT_HTML(:dbid, :inst_num, TO_DATE(:btime, ''YYYYMMDDHH24MISS''), TO_DATE(:etime, ''YYYYMMDDHH24MISS''), :options, :slot_width, :sid, :sql_id, :wait_class, :service_hash, :module, :action, :client_id, :plsql_entry, :data_src));');
            wa('SELECT column_value FROM TABLE('||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.ash_report_html_11(:dbid, :inst_num, TO_DATE(:btime, ''YYYYMMDDHH24MISS''), TO_DATE(:etime, ''YYYYMMDDHH24MISS''), :options, :slot_width, :sid, :sql_id, :wait_class, :service_hash, :module, :action, :client_id, :plsql_entry, :data_src));');
          END IF;
          wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
          wa('SPO OFF;');
        END LOOP;
      END IF;

      IF sqlt$a.get_param('ash_reports_source') IN ('AWR', 'BOTH') THEN
        wa('EXEC :data_src := 2;');

        FOR i IN (SELECT COUNT(*) num_samples,
                         instance_number,
                         to_char(sample_time,'yyyymmddhh24') sample_hr,
                         MIN(sample_time) min_sample_time,
                         MAX(sample_time) max_sample_time	   
                    FROM sqlt$_dba_hist_active_sess_his
                   WHERE statement_id = p_statement_id
                     AND dbid = sql_rec.database_id
                     AND sql_id = sql_rec.sql_id
                   GROUP BY
                         instance_number, to_char(sample_time,'yyyymmddhh24')
                   ORDER BY
                         num_samples desc, instance_number)
        LOOP
          l_count := l_count + 1;
          l_rep_date := TO_CHAR(i.max_sample_time, 'MMDD_HH24MI');
          IF l_count > sqlt$a.get_param_n('ash_reports') THEN
            EXIT; -- exits loop
          END IF;

          wa('EXEC :inst_num := '||TO_CHAR(i.instance_number)||';');
          wa('EXEC :btime := '''||TO_CHAR(i.min_sample_time, 'YYYYMMDDHH24MISS')||''';');
          wa('EXEC :etime := '''||TO_CHAR(i.max_sample_time, 'YYYYMMDDHH24MISS')||''';');
          wa('SET TERM ON;');
          wa('PRO ... generating '||REPLACE(s_file_rec.filename, 'driver.sql')||LPAD(l_count, 4, '0')||'_awr_'||TO_CHAR(i.instance_number)||'_'||l_rep_date||'.html ...');
          wa('SET TERM OFF;');

          wa('SPO '||REPLACE(s_file_rec.filename, 'driver.sql')||LPAD(l_count, 4, '0')||'_awr_'||TO_CHAR(i.instance_number)||'_'||l_rep_date||'.html;');
          wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
          IF sql_rec.rdbms_release < 11 THEN
            --wa('SELECT output FROM TABLE(SYS.DBMS_WORKLOAD_REPOSITORY.ASH_REPORT_HTML(:dbid, :inst_num, TO_DATE(:btime, ''YYYYMMDDHH24MISS''), TO_DATE(:etime, ''YYYYMMDDHH24MISS''), :options, :slot_width, :sid, :sql_id, :wait_class, :service_hash, :module, :action, :client_id));');
            wa('SELECT column_value FROM TABLE('||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.ash_report_html_10(:dbid, :inst_num, TO_DATE(:btime, ''YYYYMMDDHH24MISS''), TO_DATE(:etime, ''YYYYMMDDHH24MISS''), :options, :slot_width, :sid, :sql_id, :wait_class, :service_hash, :module, :action, :client_id));');
          ELSE
            --wa('SELECT output FROM TABLE(SYS.DBMS_WORKLOAD_REPOSITORY.ASH_REPORT_HTML(:dbid, :inst_num, TO_DATE(:btime, ''YYYYMMDDHH24MISS''), TO_DATE(:etime, ''YYYYMMDDHH24MISS''), :options, :slot_width, :sid, :sql_id, :wait_class, :service_hash, :module, :action, :client_id, :plsql_entry, :data_src));');
            wa('SELECT column_value FROM TABLE('||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.ash_report_html_11(:dbid, :inst_num, TO_DATE(:btime, ''YYYYMMDDHH24MISS''), TO_DATE(:etime, ''YYYYMMDDHH24MISS''), :options, :slot_width, :sid, :sql_id, :wait_class, :service_hash, :module, :action, :client_id, :plsql_entry, :data_src));');
          END IF;
          wa('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
          wa('SPO OFF;');
        END LOOP;
      END IF;

      IF l_count > 0 THEN
        wa('--');
        wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_ashrpt_'||LPAD(l_count, 4, '0')||' '||REPLACE(s_file_rec.filename, 'driver.sql', '*.html')||' ');
        --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_ashrpt_'||LPAD(l_count, 4, '0')||' ');
      END IF;

      wa('--');
      wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver '||s_file_rec.filename||' ');
      --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver ');
      wa('SPO sqlt'||CASE WHEN LOWER(sqlt$a.s_sqlt_method) = 'xecute' THEN 'xecute2' ELSE LOWER(sqlt$a.s_sqlt_method) END||'.log APPEND;');
      wa('EXEC ^^tool_administer_schema..sqlt$a.write_log(''<- ASH Reports Driver'',''L'','' drivers'');');
      wa('SPO OFF;');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'ASHRPT_DRIVER',
        p_filename     => s_file_rec.filename,
        p_file_size    => s_file_rec.file_size,
        p_file_text    => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_ashrpt_driver = s_file_rec.filename
       WHERE statement_id = p_statement_id;

      write_log('generated '||s_file_rec.filename);
    END IF;

    COMMIT;
    write_log('<- ashrpt_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('ashrpt_driver:'||SQLERRM);
  END ashrpt_driver;

  /*************************************************************************************/

  /* -------------------------
   *
   * public script_output_driver
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE script_output_driver (
    p_statement_id        IN NUMBER,
    p_input_filename      IN VARCHAR2,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_file_name_prefix VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);
    l_filename_with_output VARCHAR2(32767);

    /* -------------------------
     *
     * private script_output_driver.wa - write append
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

  BEGIN
    write_log('-> script_output_driver');

    sql_rec := sqlt$a.get_statement(p_statement_id);
    IF sql_rec.method = 'XECUTE' THEN
      l_filename_with_output := sqlt$a.get_filename_with_output(p_statement_id => p_statement_id, p_script_with_sql => p_input_filename);

      IF p_out_file_identifier IS NULL THEN
        l_out_file_identifier := NULL;
      ELSE
        l_out_file_identifier := '_'||p_out_file_identifier;
      END IF;

      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_script_output_driver.sql';
      s_file_rec.file_text :=
      'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $';
      wa('--');
      wa('-- xecute_script_output = '||sqlt$a.get_param('xecute_script_output'));
      wa('--');

      IF sqlt$a.get_param('xecute_script_output') = 'KEEP' THEN
        wa('-- '||l_filename_with_output||' is kept in local directory as per "xecute_script_output" parameter');
      ELSIF sqlt$a.get_param('xecute_script_output') = 'ZIP' THEN
        wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_'||LOWER(sql_rec.method)||' '||l_filename_with_output||' ');
        --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||' ');
      ELSE -- sqlt$a.get_param('xecute_script_output') = 'DELETE'
        wa('SPO '||l_filename_with_output||';');
        wa('PRO --empty file');
        wa('SPO OFF;');
        wa('-- deletes spool file using zip');
        wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_'||LOWER(sql_rec.method)||' '||l_filename_with_output||' ');
        wa('HOS zip -d sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_'||LOWER(sql_rec.method)||' '||l_filename_with_output||' ');
      END IF;

      wa('--');
      wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver '||s_file_rec.filename||' ');
      --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver ');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'SCRIPT_OUTPUT_DRIVER',
        p_filename     => s_file_rec.filename,
        p_file_size    => s_file_rec.file_size,
        p_file_text    => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_script_output_driver = s_file_rec.filename
       WHERE statement_id = p_statement_id;
      COMMIT;
      write_log('generated '||s_file_rec.filename);
    END IF; -- sql_rec.method = 'XECUTE'

    write_log('<- script_output_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('script_output_driver:'||SQLERRM);
  END script_output_driver;

  /*************************************************************************************/

  /* -------------------------
   *
   * public tkprof_px_driver
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE tkprof_px_driver (
    p_statement_id        IN  NUMBER,
    p_out_file_identifier IN  VARCHAR2 DEFAULT NULL,
    x_file_name           OUT VARCHAR2 )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_count NUMBER := 0;
    l_file_name_prefix VARCHAR2(32767);
    l_file_exists BOOLEAN;
    l_file_length NUMBER;
    l_file_block_size NUMBER;
    l_out_file_identifier VARCHAR2(32767);

    /* -------------------------
     *
     * private tkprof_px_driver.wa - write append
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

  BEGIN
    write_log('-> tkprof_px_driver');
    x_file_name := NULL;
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_tkprof_px_driver.sql';
    s_file_rec.file_text :=
    'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $';

    --IF sql_rec.method = 'XECUTE' AND sql_rec.px_servers_executions > 0 THEN
    IF sql_rec.method = 'XECUTE' OR sql_rec.px_servers_executions > 0 THEN
      FOR i IN (SELECT 1 order_by,
                       'qc' process_name,
                       p.spid,
                       'SQLT$UDUMP' alias,
                       sqlt$a.get_udump_full_path path,
                       sqlt$a.session_trace_filename('s'||sqlt$a.get_statement_id_c(p_statement_id)||'_10046_10053') trace
                  FROM v$session s,
                       v$process p
                 WHERE s.sid = sqlt$a.get_sid
                   AND s.paddr = p.addr
                 UNION
                SELECT 2 order_by,
                       LOWER(server_name) process_name,
                       spid,
                       'SQLT$BDUMP' alias,
                       sqlt$a.get_bdump_full_path path,
                       sqlt$a.session_trace_filename('s'||sqlt$a.get_statement_id_c(p_statement_id)||'_10046_10053', spid, LOWER(server_name)) trace
                  FROM sqlt$_gv$px_process
                 WHERE statement_id = p_statement_id
                   AND begin_end_flag = 'E'
                /*
                 UNION
                SELECT 3 order_by,
                       LOWER(server_name) process_name,
                       spid,
                       'SQLT$BDUMP' alias,
                       sqlt$a.get_bdump_full_path path,
                       REPLACE(sqlt$a.session_trace_filename('s'||sqlt$a.get_statement_id_c(p_statement_id)||'_10046_10053', spid, LOWER(server_name)), '_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_10046_10053') trace
                  FROM sqlt$_gv$px_process
                 WHERE statement_id = p_statement_id
                   AND begin_end_flag = 'E'
                */
                 ORDER BY 1, 2)
      LOOP
        --wa('HOS tkprof '||i.path||i.trace||' sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_'||i.process_name||'_'||i.spid||'_tkprof.txt ');

        BEGIN
          l_file_exists := FALSE;
          SYS.UTL_FILE.FGETATTR (
            location     => i.alias,
            filename     => i.trace,
            fexists      => l_file_exists,
            file_length  => l_file_length,
            block_size   => l_file_block_size );
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error('SYS.UTL_FILE.FGETATTR('''||i.alias||''', '''||i.trace||''')');
        END;

        wa('--');
        IF l_file_exists THEN
          wa('HOS tkprof '||i.path||i.trace||' '||REPLACE(i.trace, '.trc', '.tkprof')||' ');
          wa('HOS zip -j sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_trc '||i.path||i.trace||' ');
          wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_trc '||REPLACE(i.trace, '.trc', '.tkprof')||' ');

          l_count := l_count + 1;
          IF l_count = 1 THEN
            BEGIN
              EXECUTE IMMEDIATE 'DELETE trca$_files';
              x_file_name := 'trca$_files';
            EXCEPTION
              WHEN OTHERS THEN
                write_error(SQLERRM);
                write_error('DELETE trca$_files');
            END;
          END IF;

          IF x_file_name IS NOT NULL THEN
            BEGIN
              EXECUTE IMMEDIATE 'INSERT INTO trca$_files values (:filename, :directory_alias, :order_by)'
              USING IN i.trace, IN i.alias, IN l_count;
              write_log('trace '||i.trace||' exists in '||i.path);
            EXCEPTION
              WHEN OTHERS THEN
                write_error(SQLERRM);
                write_error('INSERT INTO trca$_files values ('''||i.trace||''', '''||i.alias||''', '''||l_count||''')');
            END;
          END IF;
        ELSE
          wa('-- NOT FOUND: '||i.path||i.trace);
        END IF;
      END LOOP;
    END IF;

    IF l_count < 2 THEN
      --s_file_rec.file_text :=
      --'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $';

      write_log('px files were not found');
      BEGIN
        EXECUTE IMMEDIATE 'DELETE trca$_files';
        x_file_name := NULL;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error('DELETE trca$_files');
      END;

      --wa('--');
      --wa('-- px files were not found');
    END IF;

    wa('--');
    wa('HOS zip -m sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver '||s_file_rec.filename||' ');
    --wa('HOS unzip -l sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_driver ');

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    sqlt$a.set_file (
      p_statement_id => p_statement_id,
      p_file_type    => 'TKPROF_PX_DRIVER',
      p_filename     => s_file_rec.filename,
      p_file_size    => s_file_rec.file_size,
      p_file_text    => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tkprof_px_driver = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;
    write_log('generated '||s_file_rec.filename);

    write_log('<- tkprof_px_driver');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tkprof_px_driver:'||SQLERRM);
  END tkprof_px_driver;

  /*************************************************************************************/

  /* -------------------------
   *
   * public bde_chk_cbo_report
   *
   * called by: sqlt$i.ebs_application_specific
   *
   * ------------------------- */
  PROCEDURE bde_chk_cbo_report (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

    /* -------------------------
     *
     * private bde_chk_cbo_report.wa - write append
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

    /* -------------------------
     *
     * private bde_chk_cbo_report.append
     *
     * ------------------------- */
    PROCEDURE append (p_clob IN CLOB)
    IS
    BEGIN
      IF p_clob IS NOT NULL THEN
        IF SYS.DBMS_LOB.GETLENGTH(p_clob) > 0 THEN
          SYS.DBMS_LOB.APPEND (
            dest_lob => s_file_rec.file_text,
            src_lob  => p_clob );
        END IF;
      END IF;
    END append;

  BEGIN
    write_log('-> bde_chk_cbo_report');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_bde_chk_cbo_report.html';

    /* -------------------------
     * Header
     * ------------------------- */
    s_file_rec.file_text :=
'<html>
<!-- $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $ -->
<!-- Copyright (c) 2000-2011, Oracle Corporation. All rights reserved. -->
<!-- AUTHOR: carlos.sierra@oracle.com -->
<head>
<title>bde_chk_cbo_report.html</title>
<style type="text/css">
body {font:8pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}
a {font-weight:bold; color:#663300;}
h1 {font-size:16pt; font-weight:bold; color:#336699;}
h2 {font-size:14pt; font-weight:bold; color:#336699;}
h3 {font-size:12pt; font-weight:bold; color:#336699;}
table {font-size:8pt; color:black; background:white;}
th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
td {background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
td.left {text-align:left;} /* left */
td.right {text-align:right;} /* right */
td.center {text-align:center;} /* center */
td.title {font-weight:bold; color:#336699; background:#cccc99; text-align:right;} /* right title */
font.f {font-size:8pt; font-weight:italic; color:#999999;} /* footnote in gray */
</style>
</head>
<body>
<h1>'||NOTE_NUMBER||' 174605.1 bde_chk_cbo '||sqlt$a.get_param('tool_version')||'</h1>
<h3>Identification</h3>
<table>
<tr><td class="title">Date:</td><td class="left">'||TO_CHAR(SYSDATE, 'DD-MON-YY HH24:MI')||'</td></tr>
<tr><td class="title">Host:</td><td class="left">'||sql_rec.host_name_short||'</td></tr>
<tr><td class="title">Platform:</td><td class="left">'||sql_rec.platform||'</td></tr>
<tr><td class="title">Database:</td><td class="left">'||sql_rec.database_name_short||'('||sql_rec.database_id||')/td></tr>
<tr><td class="title">Instance:</td><td class="left">'||sql_rec.instance_name_short||'('||sql_rec.instance_number||')</td></tr>
<tr><td class="title">RDBMS Release:</td><td class="left">'||sql_rec.rdbms_version||'('||sql_rec.rdbms_version_short||')</td></tr>
<tr><td class="title">User:</td><td class="left">'||sql_rec.username||'</td></tr>
<tr><td class="title">APPS Release:</td><td class="left">'||NVL(sql_rec.apps_release, 'NO')||'</td></tr>
<tr><td class="title">CPU Count:</td><td class="left">'||sql_rec.cpu_count||'</td></tr>
<tr><td class="title">Num CPUs:</td><td class="left">'||sql_rec.num_cpus||'</td></tr>
<tr><td class="title">Num Cores:</td><td class="left">'||sql_rec.num_cpu_cores||'</td></tr>
<tr><td class="title">Num Sockets:</td><td class="left">'||sql_rec.num_cpu_sockets||'</td></tr>
</table>
';
    /* -------------------------
     * Common database initialization parameters
     * ------------------------- */

wa('
<h3>Common database initialization parameters</h3>
<table>
<tr>
<th>Parameter</th>
<th>Current Value</th>
<th>Required Value</th>
<th>CBO</th>
<th>MP</th>
<th>SZ</th>
</tr>
');

    FOR i IN (
SELECT
'<tr>'||
'<td class="left">'||b.name||'</td>'||
'<td class="left">'||DECODE(v.name, NULL, '<i>(NOT FOUND)</i>', v.value||DECODE(v.isdefault, 'TRUE', ' <i>(NOT SET)</i>'))||'</td>'||
'<td class="left">'||DECODE(b.set_flag, 'N', '<i>DO NOT SET</i>', b.value)||'</td>'||
'<td class="center">'||DECODE(b.cbo_flag, 'Y', 'Y')||'</td>'||
'<td class="center">'||DECODE(b.mp_flag, 'Y', 'Y')||'</td>'||
'<td class="center">'||DECODE(b.sz_flag, 'Y', 'Y')||'</td>'||
'</tr>' line
FROM chk$cbo$parameter_apps b, v$parameter2 v
WHERE b.release = sql_rec.apps_release
AND b.version = 'COMMON'
AND b.name = LOWER(v.name(+))
ORDER BY b.id, v.value
)   LOOP
      wa(i.line);
    END LOOP;

wa('
</table>
CBO: Cost-based Optimizer Parameter.<br>
MP: Mandatory Parameter and Value<br>
SZ: For recommended values according to particular environment size, refer to Notes 216205.1 and 396009.1<br>
');

    /* -------------------------
     * Release-specific database initialization parameters
     * ------------------------- */
wa('
<h3>Release-specific database initialization parameters for '||sql_rec.rdbms_version_short||'</h3>
<table>
<tr>
<th>Parameter</th>
<th>Current Value</th>
<th>Required Value</th>
<th>CBO</th>
<th>MP</th>
<th>SZ</th>
</tr>
');

    FOR i IN (
SELECT
'<tr>'||
'<td class="left">'||b.name||'</td>'||
'<td class="left">'||DECODE(v.name, NULL, '<i>(NOT FOUND)</i>', v.value||DECODE(v.isdefault, 'TRUE', ' <i>(NOT SET)</i>'))||'</td>'||
'<td class="left">'||b.value||'</td>'||
'<td class="center">'||DECODE(b.cbo_flag, 'Y', 'Y')||'</td>'||
'<td class="center">'||DECODE(b.mp_flag, 'Y', 'Y')||'</td>'||
'<td class="center">'||DECODE(b.sz_flag, 'Y', 'Y')||'</td>'||
'</tr>' line
FROM chk$cbo$parameter_apps b, v$parameter2 v
WHERE b.release = sql_rec.apps_release
AND b.version = sql_rec.rdbms_version_short
AND b.name = LOWER(v.name(+))
AND b.set_flag = 'Y'
ORDER BY b.id, v.value
)   LOOP
      wa(i.line);
    END LOOP;

wa('
</table>
CBO: Cost-based Optimizer Parameter.<br>
MP: Mandatory Parameter and Value<br>
SZ: For recommended values according to particular environment size, refer to Notes 216205.1 and 396009.1<br>
');

    /* -------------------------
     * Removal list
     * ------------------------- */
wa('
<h3>Removal list for '||sql_rec.rdbms_version_short||'</h3>
<table>
<tr>
<th>Parameter</th>
<th>Current Value</th>
<th>CBO</th>
</tr>
');

    FOR i IN (
SELECT
'<tr>'||
'<td class="left">'||b.name||'</td>'||
--'<td class="left">'||NVL(DECODE(v.isdefault, 'TRUE', '<!--(NOT SET)-->', v.value), '<!--(NOT FOUND)-->')||'</td>'||
'<td class="left">'||NVL(DECODE(v.isdefault, 'TRUE', '<i><font color="gray">(NOT SET)</font></i><!--TRUE-->', v.value), '<i><font color="gray">(NOT SET)</font></i><!--NULL-->')||'</td>'||
'<td class="center">'||DECODE(b.cbo_flag, 'Y', 'Y')||'</td>'||
'</tr>' line
FROM chk$cbo$parameter_apps b, v$parameter2 v
WHERE b.release = sql_rec.apps_release
AND b.version = sql_rec.rdbms_version_short
AND b.name = LOWER(v.name(+))
AND b.set_flag = 'N'
ORDER BY b.id, v.value
)   LOOP
      wa(i.line);
    END LOOP;

wa('
</table>
CBO: Cost-based Optimizer Parameter.<br>
');

    /* -------------------------
     * Additional initialization parameters with non-default values
     * ------------------------- */
wa('
<h3>Additional initialization parameters with non-default values</h3>
<table>
<tr>
<th>Parameter</th>
<th>Current Value</th>
</tr>
');

    FOR i IN (
SELECT
'<tr>'||
'<td class="left">'||v.name||'</td>'||
'<td class="left">'||v.value||'</td>'||
'</tr>' line
FROM v$parameter2 v
WHERE v.isdefault = 'FALSE'
AND NOT EXISTS (SELECT NULL FROM chk$cbo$parameter_apps b WHERE b.name = LOWER(v.name))
ORDER BY v.name, v.value
)   LOOP
      wa(i.line);
    END LOOP;

wa('
</table>
');

    /* -------------------------
     * Footer
     * ------------------------- */
wa('
<br><hr size="1">
<font class="f">'||NOTE_NUMBER||' 174605.1 bde_check_cbo '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, 'DD-MON-YY HH24:MI')||'</font>
</body>
</html>');

    /* -------------------------
     * Closure
     * ------------------------- */
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'BDE_CHK_CBO_REPORT',
      p_filename      => s_file_rec.filename,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_bde_chk_cbo = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- bde_chk_cbo_report');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('bde_chk_cbo_report:'||SQLERRM);
  END bde_chk_cbo_report;

  /*************************************************************************************/

  /* -------------------------
   *
   * public metadata_script
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE metadata_script (
    p_statement_id        IN NUMBER,
    p_script_type         IN VARCHAR2 DEFAULT NULL, -- NULL|1|2
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    SEPARATOR CONSTANT VARCHAR2(32767) :=
    '/**********************************************************************/';

    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_def1 VARCHAR2(32767) := NULL;
    l_def2 VARCHAR2(32767) := NULL;
	l_gra2 VARCHAR2(32767) := NULL; -- 170909 Add l_gra2
    l_status CLOB := NULL;
    l_out_file_identifier VARCHAR2(32767);
    l_file_type VARCHAR2(257);
    l_customzation VARCHAR2(32767);
    l_cbo_stats_table VARCHAR2(32767);

    /* -------------------------
     *
     * private metadata_script.wa - write append
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

    /* -------------------------
     *
     * private metadata_script.append
     *
     * ------------------------- */
    PROCEDURE append (p_clob IN CLOB)
    IS
    BEGIN
      IF p_clob IS NOT NULL THEN
        IF SYS.DBMS_LOB.GETLENGTH(p_clob) > 0 THEN
          SYS.DBMS_LOB.APPEND (
            dest_lob => s_file_rec.file_text,
            src_lob  => p_clob );
        END IF;
      END IF;
    END append;

  BEGIN
    write_log('-> metadata_script'||p_script_type);
    sql_rec := sqlt$a.get_statement(p_statement_id);
    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    l_file_type := 'METADATA_SCRIPT'||p_script_type;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_metadata'||p_script_type||'.sql';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_metadata'||p_script_type||'.sql';
    END IF;

    /* -------------------------
     * Header
     * ------------------------- */
    BEGIN
      FOR i IN (SELECT DISTINCT owner
                  FROM sqlt$_metadata
                  WHERE statement_id = p_statement_id
                    AND owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC')
                  ORDER BY
                        owner)
      LOOP
        l_def1 := l_def1||LF||'DEF SCHEMA_'||RPAD(sqlt$a.get_clean_name(i.owner), 30)||' = '''||METADATA_DEF_CHAR2||'TC_USER.''';
        l_def2 := l_def2||LF||'-- DEF SCHEMA_'||RPAD(sqlt$a.get_clean_name(i.owner), 30)||' = '''||i.owner||'''';
		-- 170909
		l_gra2 := l_gra2||LF||'-- GRANT DBA TO '||i.owner||' IDENTIFIED BY x;';
      END LOOP;

      IF p_script_type IS NULL THEN
        l_customzation := '

-- TC_USER_SUFFIX: (optional).
REM
REM Test case user suffix. Enter your initials or hit "Enter" for NULL.
REM
PRO TC user suffix (opt): '||METADATA_DEF_CHAR2||'TC_USER_SUFFIX.

-- Uppercase test case user suffix and remove special characters including space, quotes, etc.
COL TC_USER_SUFFIX NEW_V TC_USER_SUFFIX FOR A100;
SELECT TRANSLATE(UPPER('''||METADATA_DEF_CHAR2||'TC_USER_SUFFIX.''), ''ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ''''`~!@#$%^*()-_=+[]{}\|;:",.<>/?'', ''ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'') TC_USER_SUFFIX FROM DUAL;

-- Create test case user.
DEF TC_USER = TC'||sqlt$a.get_statement_id_c(p_statement_id)||METADATA_DEF_CHAR2||'TC_USER_SUFFIX.;
GRANT DBA TO '||METADATA_DEF_CHAR2||'TC_USER. IDENTIFIED BY '||METADATA_DEF_CHAR2||'TC_USER.;
GRANT CTXAPP TO '||METADATA_DEF_CHAR2||'TC_USER.;

-- Use DEF command(s) below if you want to consolidate objects into one test case user (recommended).'||
l_def1||'

-- Un-comment DEF and GRANT command(s) below ONLY if you want to create objects into original owner(s). (not recommended).
-- If you decide to use this then you need to modify sqlt_s#####_restore.sql as well
-- to not modify the stats to import only into the TC user
'||
l_def2
||LF -- 1709090
||l_gra2||'

';
        l_cbo_stats_table := '

-- CBO statistics table
BEGIN
  SYS.DBMS_STATS.CREATE_STAT_TABLE (
    ownname  => '''||METADATA_DEF_CHAR2||'TC_USER.'',
    stattab  => ''CBO_STAT_TAB_4TC'' );
  SYS.DBMS_STATS.LOCK_TABLE_STATS (
    ownname  => '''||METADATA_DEF_CHAR2||'TC_USER.'',
    tabname  => ''CBO_STAT_TAB_4TC'' );
END;'||LF||'/

DELETE '||METADATA_DEF_CHAR2||'TC_USER..CBO_STAT_TAB_4TC;

';
--170909
      ELSIF p_script_type = '2' THEN
	   l_customzation := '
DEF TC_USER = TC'||sqlt$a.get_statement_id_c(p_statement_id)||';'||
l_def2
||LF;
	  ELSIF p_script_type='1' THEN
        l_customzation := '

-- Create test case user.
DEF TC_USER = TC'||sqlt$a.get_statement_id_c(p_statement_id)||';
GRANT DBA TO '||METADATA_DEF_CHAR2||'TC_USER. IDENTIFIED BY '||METADATA_DEF_CHAR2||'TC_USER.;
'||
l_def1
||'

-- Un-comment DEF and GRANT command(s) below ONLY if you want to create objects into original owner(s). (not recommended).
-- If you decide to use this then you need to modify sqlt_s#####_schema_stats.sql as well
-- to not modify the stats to import only into the TC user
'||
l_def2
||LF -- 170909
||l_gra2||'

';
        l_cbo_stats_table := '

';
      END IF;

      s_file_rec.file_text :=
'SPO '||REPLACE(s_file_rec.filename, '.sql', '.log')||';
SET DEF '||METADATA_DEF_CHAR||' ECHO ON TERM ON LIN 2000 TRIMS ON APPI OFF SERVEROUT ON SIZE 1000000;
REM
REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $
REM
REM '||COPYRIGHT||'
REM
REM AUTHOR
REM   '||TOOL_DEVELOPER_EMAIL||'
REM
REM SCRIPT
REM   '||s_file_rec.filename||'
REM
REM SOURCE
REM   Host    : '||sql_rec.host_name_short||'
REM   DB Name : '||sql_rec.database_name_short||'
REM   Platform: '||sql_rec.platform||'
REM   Product : '||sql_rec.product_version||'
REM   Version : '||sql_rec.rdbms_version||'
REM   Language: '||sql_rec.language||'
REM   EBS     : '||NVL(sql_rec.apps_release, 'NO')||'
REM   Siebel  : '||sql_rec.siebel||'
REM   PSFT    : '||sql_rec.psft||'
REM
REM DESCRIPTION
REM   This script is generated automatically by the '||TOOL_NAME||' tool.
REM   It contains the SQL*Plus commands to create a test case user
REM   and its set of schema objects referenced by the SQL statement
REM   analyzed by '||TOOL_NAME||'.
REM
REM PARAMETERS
REM   TC_USER_SUFFIX: (optional)
REM   Hit "Enter" key if you dont want a test case user suffix, or
REM   type in a suffix for the TC user.
REM
REM EXAMPLE
REM   SQL> START '||s_file_rec.filename||';
REM
REM NOTES
REM   1. Review and edit "CUSTOMIZATION" section below.
REM   2. Should be run as SYSDBA.
REM

'||SEPARATOR||'
/* CUSTOMIZATION - BEGIN
'||SEPARATOR||
l_customzation
||SEPARATOR||'
/* CUSTOMIZATION - END
'||SEPARATOR||
l_cbo_stats_table;

    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.header:'||SQLERRM);
    END;

    /* -------------------------
     * Types
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF||LF||'REM TYPE, TYPE BODY and INDEXTYPE'||LF);

      FOR i IN 1 .. 3
      LOOP
        FOR j IN (SELECT owner,
                         object_name,
                         object_type,
                         metadata
                    FROM sqlt$_metadata
                   WHERE statement_id = p_statement_id
                     AND object_type LIKE '%TYPE%'
                     AND owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC')
                     AND transformed = 'Y'
                     AND remapped = 'Y'
                   ORDER BY
                         depth DESC NULLS LAST,
                         object_name)
        LOOP
          l_status := l_status||LF||'x('''||j.object_type||''','''||METADATA_DEF_CHAR2||'SCHEMA_'||sqlt$a.get_clean_name(j.owner)||''','''||j.object_name||''');';
          append(LF||j.metadata);
        END LOOP;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.types:'||SQLERRM);
    END;

    /* -------------------------
     * Tables and Materialized Views
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF||LF||'REM TABLE and MATERIALIZED VIEW'||LF);
      IF p_script_type IS NULL OR p_script_type = '1' THEN
        FOR i IN (SELECT owner,
                         object_name,
                         object_type,
                         metadata
                    FROM sqlt$_metadata
                   WHERE statement_id = p_statement_id
                     AND object_type IN ('TABLE', 'MATERIALIZED VIEW')
                     AND owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC')
                     AND object_name NOT LIKE 'DR$%$%'
                     AND transformed = 'Y'
                     AND remapped = 'Y'
                   ORDER BY
                         object_type DESC,  -- added in 12.1.03 to have tables built before mviews
                         depth DESC NULLS LAST,
                         object_name)
        LOOP
          l_status := l_status||LF||'x('''||i.object_type||''','''||METADATA_DEF_CHAR2||'SCHEMA_'||sqlt$a.get_clean_name(i.owner)||''','''||i.object_name||''');';
          append(LF||i.metadata);
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.tables:'||SQLERRM);
    END;
	


    /* -------------------------
     * Indexes
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF||LF||'REM INDEX'||LF);
      IF p_script_type IS NULL OR p_script_type = '1' THEN
        FOR i IN (SELECT m.owner,
                         m.object_name,
                         m.object_type,
                         m.metadata
                    FROM sqlt$_metadata m,
                         sqlt$_dba_indexes idx
                   WHERE m.statement_id = p_statement_id
                     AND m.object_type = 'INDEX'
                     AND m.owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC')
                     AND m.object_name NOT LIKE 'DR$%$%'
                     AND m.object_name NOT LIKE 'SYS_IOT_TOP%'
                     AND m.transformed = 'Y'
                     AND m.remapped = 'Y'
                     AND idx.statement_id = p_statement_id
                     AND idx.owner = m.owner
                     AND idx.index_name = m.object_name
                     AND idx.index_type <> 'LOB' -- LOB is not a valid index type, this is just to documment that by joining to dba_indexes we exclude from script LOB indexes (with names like SYS_IL0000073108C00029$$)
                   ORDER BY
                         m.depth DESC NULLS LAST,
                         m.object_name)
        LOOP
          l_status := l_status||LF||'x('''||i.object_type||''','''||METADATA_DEF_CHAR2||'SCHEMA_'||sqlt$a.get_clean_name(i.owner)||''','''||i.object_name||''');';
          append(LF||i.metadata);
          wa(LF||'EXEC SYS.DBMS_STATS.DELETE_INDEX_STATS(''"'||METADATA_DEF_CHAR2||'SCHEMA_'||sqlt$a.get_clean_name(i.owner)||'"'',''"'||i.object_name||'"'');');
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.indexes:'||SQLERRM);
    END;

    /* -------------------------
     * Statistics Extensions
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF||LF||'REM STATISTICS EXTENSIONS'||LF);
        IF p_script_type IS NULL OR p_script_type = '1' THEN
        FOR i IN (SELECT owner,
                         table_name,
                         extension
                    FROM sqlt$_dba_stat_extensions
                   WHERE statement_id = p_statement_id
                     AND extension_name LIKE 'SYS_STU%'
                     AND creator = 'USER'
                     AND droppable = 'YES'
                   ORDER BY
                         owner,
                         table_name)
        LOOP
          append(LF||LF||'SELECT SYS.DBMS_STATS.CREATE_EXTENDED_STATS(''"'||METADATA_DEF_CHAR2||'SCHEMA_'||sqlt$a.get_clean_name(i.owner)||'"'',''"'||i.table_name||'"'','''||i.extension||''') FROM DUAL;');
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.stat_extensions:'||SQLERRM);
    END;

    /* -------------------------
     * Constraints
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF||LF||'REM CONSTRAINT'||LF);
      IF p_script_type IS NULL OR p_script_type = '1' THEN
        FOR i IN (SELECT owner,
                         object_name,
                         object_type,
                         metadata
                    FROM sqlt$_metadata
                   WHERE statement_id = p_statement_id
                     AND object_type LIKE '%CONSTRAINT'
                     AND owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC')
                     AND transformed = 'Y'
                     AND remapped = 'Y'
                   ORDER BY
                         CASE WHEN object_type = 'R_CONSTRAINT' THEN 2 ELSE 1 END,
                         object_type,
                         object_name)
        LOOP
          append(LF||i.metadata);
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.constraints:'||SQLERRM);
    END;

    /* -------------------------
     * Package Specs
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF||LF||'REM PACKAGE'||LF);
      IF p_script_type IS NULL OR p_script_type = '2' THEN
        FOR i IN (SELECT owner,
                         object_name,
                         object_type,
                         metadata
                    FROM sqlt$_metadata
                   WHERE statement_id = p_statement_id
                     AND object_type = 'PACKAGE'
                     AND owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC')
                     AND transformed = 'Y'
                     AND remapped = 'Y'
                   ORDER BY
                         depth DESC NULLS LAST,
                         object_name)
        LOOP
          l_status := l_status||LF||'x('''||i.object_type||''','''||METADATA_DEF_CHAR2||'SCHEMA_'||sqlt$a.get_clean_name(i.owner)||''','''||i.object_name||''');';
          append(LF||i.metadata);
          wa(LF||'SHOW ERRORS;'||LF); 
          --wa('/'||LF||'SHOW ERRORS;'||LF); 
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.package:'||SQLERRM);
    END;

    /* -------------------------
     * Views
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF||LF||'REM VIEW'||LF);
      IF p_script_type IS NULL OR p_script_type = '2' THEN
        FOR i IN (SELECT owner,
                         object_name,
                         object_type,
                         metadata
                    FROM sqlt$_metadata
                   WHERE statement_id = p_statement_id
                     AND object_type = 'VIEW'
                     AND owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC')
                     AND transformed = 'Y'
                     AND remapped = 'Y'
                   ORDER BY
                         depth DESC NULLS LAST,
                         object_name)
        LOOP
          l_status := l_status||LF||'x('''||i.object_type||''','''||METADATA_DEF_CHAR2||'SCHEMA_'||sqlt$a.get_clean_name(i.owner)||''','''||i.object_name||''');';
          append(LF||i.metadata);
          -- wa('/'||LF||'SHOW ERRORS;'||LF); 12.1.08
          wa('SHOW ERRORS;'||LF);
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.views:'||SQLERRM);
    END;

    /* -------------------------
     * Package Body, Functions and Procedures
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF||LF||'REM FUNCTION, PROCEDURE, LIBRARY and PACKAGE BODY'||LF);
      IF p_script_type IS NULL OR p_script_type = '2' THEN
        FOR i IN (SELECT owner,
                         object_name,
                         object_type,
                         metadata
                    FROM sqlt$_metadata
                   WHERE statement_id = p_statement_id
                     AND object_type IN ('PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'LIBRARY')
                     AND owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC')
                     AND transformed = 'Y'
                     AND remapped = 'Y'
                   ORDER BY
                         CASE
                         WHEN object_type = 'FUNCTION' THEN 1
                         WHEN object_type = 'PROCEDURE' THEN 2
                         WHEN object_type = 'LIBRARY' THEN 3
                         WHEN object_type = 'PACKAGE BODY' THEN 4
                         END,
                         depth DESC NULLS LAST,
                         object_name)
        LOOP
          l_status := l_status||LF||'x('''||i.object_type||''','''||METADATA_DEF_CHAR2||'SCHEMA_'||sqlt$a.get_clean_name(i.owner)||''','''||i.object_name||''');';
          append(LF||i.metadata);
          wa(LF||'SHOW ERRORS;'||LF); 
          --wa('/'||LF||'SHOW ERRORS;'||LF); 
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.libraries:'||SQLERRM);
    END;

    /* -------------------------
     * All others
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF||LF||'REM OTHERS'||LF);
      IF p_script_type IS NULL OR p_script_type = '2' THEN
        FOR i IN (SELECT owner,
                         object_name,
                         object_type,
                         metadata
                    FROM sqlt$_metadata
                   WHERE statement_id = p_statement_id
                     AND object_type NOT LIKE '%TYPE%'
                     AND object_type NOT IN ('TABLE', 'MATERIALIZED VIEW')
                     AND object_type <> 'INDEX'
                     AND object_type NOT LIKE '%CONSTRAINT'
                     AND object_type <> 'PACKAGE'
                     AND object_type <> 'VIEW'
                     AND object_type NOT IN ('PACKAGE BODY', 'PROCEDURE', 'FUNCTION', 'LIBRARY')
                     AND owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC')
                     AND object_name NOT LIKE 'DR$%$%'
                     AND transformed = 'Y'
                     AND remapped = 'Y'
                   ORDER BY
                         depth DESC NULLS LAST,
                         object_name)
        LOOP
          l_status := l_status||LF||'x('''||i.object_type||''','''||METADATA_DEF_CHAR2||'SCHEMA_'||sqlt$a.get_clean_name(i.owner)||''','''||i.object_name||''');';
          append(LF||i.metadata);
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.others:'||SQLERRM);
    END;

    /* -------------------------
     * Objects status
     * ------------------------- */
    BEGIN
      wa(LF||LF||SEPARATOR||LF||LF||'SET ECHO OFF VER OFF PAGES 1000 LIN 80 LONG 8000000 LONGC 800000;'||LF||'
VAR valid_objects CLOB;
VAR invalid_objects CLOB;
DECLARE
  l_status VARCHAR2(7);
  PROCEDURE x (p_type IN VARCHAR2, p_owner IN VARCHAR2, p_name IN VARCHAR2) IS
  BEGIN
    BEGIN
      SELECT status
        INTO l_status
        FROM sys.dba_objects
       WHERE object_type = p_type
         AND owner = p_owner
         AND object_name = p_name;
    EXCEPTION
      WHEN OTHERS THEN
        l_status := ''INVALID'';
    END;
    IF l_status = ''VALID'' THEN
      :valid_objects := :valid_objects||CHR(10)||l_status||'' ''||p_type||'' ''||p_owner||'' ''||p_name;
    ELSE
      :invalid_objects := :invalid_objects||CHR(10)||l_status||'' ''||p_type||'' ''||p_owner||'' ''||p_name;
    END IF;
  END;
BEGIN
:valid_objects := NULL;
:invalid_objects := NULL;');

      append(l_status);

      wa(':valid_objects := TRIM(CHR(10) FROM :valid_objects);
:invalid_objects := TRIM(CHR(10) FROM :invalid_objects);
END;'||LF||'/

SET TERM ON;
SELECT :valid_objects FROM DUAL;
SELECT :invalid_objects FROM DUAL;
');
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.status:'||SQLERRM);
    END;

    /* -------------------------
     * Footer and closure
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF||LF||'SET DEF ON ECHO ON APPI OFF SERVEROUT OFF PAGES 24 LIN 80 LONG 80 LONGC 80;'||LF||
      'REM In case of INVALID OBJECTS: review log, fix errors and execute again.'||LF||
      'SPO OFF;');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id  => p_statement_id,
        p_file_type     => l_file_type,
        p_filename      => s_file_rec.filename,
        p_statement_id2 => p_group_id,
        p_db_link       => p_db_link,
        p_file_size     => s_file_rec.file_size,
        p_file_text     => s_file_rec.file_text );

      IF p_script_type IS NULL THEN
        UPDATE sqlt$_sql_statement
           SET file_sqlt_metadata = s_file_rec.filename
         WHERE statement_id = p_statement_id;
      ELSIF p_script_type = '1' THEN
        UPDATE sqlt$_sql_statement
           SET file_sqlt_metadata1 = s_file_rec.filename
         WHERE statement_id = p_statement_id;
      ELSIF p_script_type = '2' THEN
        UPDATE sqlt$_sql_statement
           SET file_sqlt_metadata2 = s_file_rec.filename
         WHERE statement_id = p_statement_id;
      END IF;

      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('metadata_script'||p_script_type||'.close:'||SQLERRM);
    END;

    write_log('<- metadata_script'||p_script_type);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('metadata_script'||p_script_type||':'||SQLERRM);
  END metadata_script;

  /*************************************************************************************/

  /* -------------------------
   *
   * public system_stats_script
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE system_stats_script (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_def1 VARCHAR2(32767) := NULL;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> system_stats_script');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_system_stats.sql';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_system_stats.sql';
    END IF;

    /* -------------------------
     * Header
     * ------------------------- */
    FOR i IN (SELECT pname, pval1
                FROM sqlt$_aux_stats$
               WHERE statement_id = p_statement_id
                 AND sname = 'SYSSTATS_MAIN'
                 AND pval1 IS NOT NULL)
    LOOP
      l_def1 := l_def1||LF||'EXEC SYS.DBMS_STATS.SET_SYSTEM_STATS('''||i.pname||''', '||i.pval1||');';
    END LOOP;
	
	-- Add IO Calibration
	IF sqlt$a.get_rdbms_release >= 11 AND sql_rec.ioc_max_iops IS NOT NULL AND sql_rec.ioc_max_mbps IS NOT NULL AND
      sql_rec.ioc_max_pmbps IS NOT NULL AND sql_rec.ioc_latency IS NOT NULL THEN
	  l_def1 := l_def1||LF||'REM Remember IO Calibrate needs an instance restart';
	  l_def1 := l_def1||LF||'DELETE SYS.RESOURCE_IO_CALIBRATE$;';
	  l_def1 := l_def1||LF||'INSERT INTO SYS.RESOURCE_IO_CALIBRATE$(START_TIME,END_TIME,MAX_IOPS,MAX_MBPS,MAX_PMBPS,LATENCY,NUM_DISKS) '||
	                 'VALUES (SYSTIMESTAMP,SYSTIMESTAMP,'||sql_rec.ioc_max_iops||','||sql_rec.ioc_max_mbps||','||sql_rec.ioc_max_pmbps||','||sql_rec.ioc_latency||','||
					 sql_rec.ioc_num_physical_disks||');';
	END IF;

    s_file_rec.file_text :=
'SPO '||REPLACE(s_file_rec.filename, '.sql', '.log')||';
SET ECHO ON TERM ON;
REM
REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $
REM
REM '||COPYRIGHT||'
REM
REM AUTHOR
REM   '||TOOL_DEVELOPER_EMAIL||'
REM
REM SCRIPT
REM   '||s_file_rec.filename||'
REM
REM SOURCE
REM   Host    : '||sql_rec.host_name_short||'
REM   DB Name : '||sql_rec.database_name_short||'
REM   Platform: '||sql_rec.platform||'
REM   Product : '||sql_rec.product_version||'
REM   Version : '||sql_rec.rdbms_version||'
REM   Language: '||sql_rec.language||'
REM   EBS     : '||NVL(sql_rec.apps_release, 'NO')||'
REM   Siebel  : '||sql_rec.siebel||'
REM   PSFT    : '||sql_rec.psft||'
REM
REM DESCRIPTION
REM   This script is generated automatically by the '||TOOL_NAME||' tool.
REM   It contains the SQL*Plus commands to set the CBO System
REM   Statistics as found on '||sql_rec.host_name_short||'
REM   at the time SQL '||sql_rec.sql_id||' was analyzed by '||TOOL_NAME||'.
REM
REM PARAMETERS
REM   None.
REM
REM EXAMPLE
REM   SQL> START '||s_file_rec.filename||';
REM
REM NOTES
REM   1. Should be run as SYSTEM or SYSDBA.
REM

EXEC SYS.DBMS_STATS.DELETE_SYSTEM_STATS;'||
l_def1||'

SPO OFF;';

--QUIT;';

    /* -------------------------
     * Closure
     * ------------------------- */
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'SYSTEM_STATS_SCRIPT',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_sqlt_system_stats = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- system_stats_script');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('system_stats_script:'||SQLERRM);
  END system_stats_script;

  /*************************************************************************************/

  /* -------------------------
   *
   * public schema_stats_script
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE schema_stats_script (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_def1 VARCHAR2(32767) := NULL;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> schema_stats_script');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_schema_stats.sql';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_schema_stats.sql';
    END IF;

    /* -------------------------
     * Header
     * ------------------------- */

	--170909 Allow multi-schema import and correct version
    s_file_rec.file_text :=
'SPO '||REPLACE(s_file_rec.filename, '.sql', '.log')||';
SET ECHO ON TERM ON;
REM
REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $
REM
REM '||COPYRIGHT||'
REM
REM AUTHOR
REM   '||TOOL_DEVELOPER_EMAIL||'
REM
REM SCRIPT
REM   '||s_file_rec.filename||'
REM
REM SOURCE
REM   Host    : '||sql_rec.host_name_short||'
REM   DB Name : '||sql_rec.database_name_short||'
REM   Platform: '||sql_rec.platform||'
REM   Product : '||sql_rec.product_version||'
REM   Version : '||sql_rec.rdbms_version||'
REM   Language: '||sql_rec.language||'
REM   EBS     : '||NVL(sql_rec.apps_release, 'NO')||'
REM   Siebel  : '||sql_rec.siebel||'
REM   PSFT    : '||sql_rec.psft||'
REM
REM DESCRIPTION
REM   This script is generated automatically by the '||TOOL_NAME||' tool.
REM   It contains the SQL*Plus commands to set the CBO Schema
REM   Statistics as found on '||sql_rec.host_name_short||'
REM   at the time SQL '||sql_rec.sql_id||' was analyzed by '||TOOL_NAME||'.
REM
REM PARAMETERS
REM   None.
REM
REM EXAMPLE
REM   SQL> START '||s_file_rec.filename||';
REM
REM NOTES
REM   1. Should be run as SYSTEM or SYSDBA.
REM

-- Create test case user.
DEF TC_USER = TC'||sqlt$a.get_statement_id_c(p_statement_id)||';

-- in case we execute this script more than once
DROP TABLE '||AMP2||'tc_user..sqlt$_stattab;
-- create staging table for cbo schema stats
ALTER SESSION SET NLS_LENGTH_SEMANTICS = BYTE;
EXEC SYS.DBMS_STATS.CREATE_STAT_TABLE(ownname => '''||AMP2||'tc_user.'', stattab => ''SQLT$_STATTAB'');
DROP INDEX '||AMP2||'tc_user..sqlt$_stattab;

-- This is to figure out what version the stats need to be.
EXEC SYS.DBMS_STATS.GATHER_TABLE_STATS(ownname => '''||AMP2||'tc_user.'', tabname => ''SQLT$_STATTAB'');
EXEC SYS.DBMS_STATS.EXPORT_TABLE_STATS(ownname => '''||AMP2||'tc_user.'', stattab => ''SQLT$_STATTAB'', tabname => ''SQLT$_STATTAB'');

column stats_version new_value stats_version noprint
select max(version) stats_version from '||AMP2||'tc_user..sqlt$_stattab;

EXEC SYS.DBMS_STATS.DELETE_TABLE_STATS(ownname => '''||AMP2||'tc_user.'', tabname => ''SQLT$_STATTAB'');
TRUNCATE TABLE '||AMP2||'tc_user..sqlt$_stattab;

-- import schema object statistics into staging table
HOS imp '||AMP2||'tc_user./'||AMP2||'tc_user. FILE='||REPLACE(s_file_rec.filename, '_schema_stats.sql', '_exp2.dmp')||' LOG='||REPLACE(s_file_rec.filename, '_schema_stats.sql', '_imp2.log')||' FULL=Y IGNORE=Y

-- upgrade cbo stats table in case source is prior release
EXEC SYS.DBMS_STATS.UPGRADE_STAT_TABLE(ownname => '''||AMP2||'tc_user.'', stattab => ''SQLT$_STATTAB'');

-- reset statid and owner on staging table
UPDATE '||AMP2||'tc_user..sqlt$_stattab 
SET VERSION='||AMP||'stats_version
-- if multiple schemas are going to be used then comment the next line.
   ,c5=nvl2(c5,'''||AMP2||'tc_user.'',c5)
   ,statid = NULL;

COMMIT;

-- imports into data dictionary schema stats for TC user out of staging table
EXEC SYS.DBMS_STATS.IMPORT_DATABASE_STATS(statown => '''||AMP2||'tc_user.'', stattab => ''SQLT$_STATTAB'');

-- displays stats that were just imported
set lines 180
column owner format a20
column table_name format a40
SELECT num_rows,owner,table_name  FROM sys.dba_tables
WHERE owner in (select distinct c5 from '||AMP2||'tc_user..sqlt$_stattab)
AND table_name <> ''SQLT$_STATTAB'' ORDER BY table_name;

SPO OFF;';

    /* -------------------------
     * Closure
     * ------------------------- */
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'SCHEMA_STATS_SCRIPT',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_sqlt_schema_stats = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- schema_stats_script');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('schema_stats_script:'||SQLERRM);
  END schema_stats_script;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_cbo_env_script
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE set_cbo_env_script (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    SEPARATOR CONSTANT VARCHAR2(32767) :=
    '/*************************************************************************************/';

    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_alter VARCHAR2(32767);
    l_scope VARCHAR2(32767);
    l_params_def CLOB;
    l_params_non CLOB;
    l_fixctl_def CLOB;
    l_fixctl_non CLOB;
    l_count NUMBER;
    l_out_file_identifier VARCHAR2(32767);

    /* -------------------------
     *
     * private set_cbo_env_script.wa - write append
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

    /* -------------------------
     *
     * private set_cbo_env_script.append
     *
     * ------------------------- */
    PROCEDURE append (p_clob IN CLOB)
    IS
    BEGIN
      IF p_clob IS NOT NULL THEN
        IF SYS.DBMS_LOB.GETLENGTH(p_clob) > 0 THEN
          SYS.DBMS_LOB.APPEND (
            dest_lob => s_file_rec.file_text,
            src_lob  => p_clob );
        END IF;
      END IF;
    END append;

  BEGIN
    write_log('-> set_cbo_env_script');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_set_cbo_env.sql';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_set_cbo_env.sql';
    END IF;

    SYS.DBMS_LOB.CREATETEMPORARY(l_params_def, TRUE);
    SYS.DBMS_LOB.CREATETEMPORARY(l_params_non, TRUE);
    SYS.DBMS_LOB.CREATETEMPORARY(l_fixctl_def, TRUE);
    SYS.DBMS_LOB.CREATETEMPORARY(l_fixctl_non, TRUE);

    /* -------------------------
     * Header
     * ------------------------- */
    BEGIN
      s_file_rec.file_text :=
'SPO '||REPLACE(s_file_rec.filename, '.sql', '.log')||';
SET ECHO ON TERM ON;
REM
REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $
REM
REM '||COPYRIGHT||'
REM
REM AUTHOR
REM   '||TOOL_DEVELOPER_EMAIL||'
REM
REM SCRIPT
REM   '||s_file_rec.filename||'
REM
REM SOURCE
REM   Host    : '||sql_rec.host_name_short||'
REM   DB Name : '||sql_rec.database_name_short||'
REM   Platform: '||sql_rec.platform||'
REM   Product : '||sql_rec.product_version||'
REM   Version : '||sql_rec.rdbms_version||'
REM   Language: '||sql_rec.language||'
REM   EBS     : '||NVL(sql_rec.apps_release, 'NO')||'
REM   Siebel  : '||sql_rec.siebel||'
REM   PSFT    : '||sql_rec.psft||'
REM
REM DESCRIPTION
REM   This script is generated automatically by the '||TOOL_NAME||' tool.
REM   It contains the SQL*Plus commands to set the CBO environment
REM   for your test case. Use this script prior to the execution
REM   of '||TOOL_NAME||' for the SQL being analyzed.
REM
REM PARAMETERS
REM   None.
REM
REM EXAMPLE
REM   SQL> START '||s_file_rec.filename||';
REM
REM NOTES
REM   1. Review and edit if needed.
REM   2. Should be run as the test case user.
REM

'||SEPARATOR||'

ALTER SESSION SET optimizer_features_enable = '''||sql_rec.optimizer_features_enable||''';';
    EXCEPTION
      WHEN OTHERS THEN
        write_error('set_cbo_env_script.header:'||SQLERRM);
    END;

    /* -------------------------
     * Parameters
     * ------------------------- */
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_gv$parameter_cbo
       WHERE statement_id = p_statement_id
         AND inst_id = sql_rec.instance_number
         AND type IN (1, 2, 3, 6)
         AND value IS NOT NULL
         AND LOWER(name) <> 'optimizer_features_enable'
         AND isses_modifiable = 'FALSE'
         AND issys_modifiable <> 'FALSE';

      IF l_count > 0 THEN
        wa(LF||'SET ECHO OFF;'||LF||'PRO'||LF||'--PAU Press ENTER to execute ALTER SYSTEM/SESSION commands to set CBO env.'||LF||'SET ECHO ON;');
      END IF;

      FOR i IN (SELECT LOWER(name) name,
                       type,
                       LOWER(value) value,
                       CASE WHEN display_value IS NULL OR value = display_value THEN value ELSE value||'('||display_value||')' END display_value,
                       isdefault,
                       ismodified,
                       isses_modifiable,
                       issys_modifiable,
                       description,
                       CASE WHEN isdefault = 'FALSE' OR ismodified <> 'FALSE' THEN '. isdefault="'||isdefault||'" ismodified="'||ismodified||'"' END message,
                       CASE WHEN isses_modifiable = 'FALSE' THEN ' issys_modifiable="'||issys_modifiable||'"' END message2
                  FROM sqlt$_gv$parameter_cbo
                 WHERE statement_id = p_statement_id
                   AND inst_id = sql_rec.instance_number
                   AND type IN (1, 2, 3, 6)
                   AND value IS NOT NULL
                   AND LOWER(name) <> 'optimizer_features_enable'
                 ORDER BY
                       isdefault,
                       ismodified DESC,
                       CASE
                       WHEN isses_modifiable = 'FALSE' AND issys_modifiable = 'FALSE' THEN 1
                       WHEN isses_modifiable = 'FALSE' AND issys_modifiable = 'DEFERRED' THEN 2
                       WHEN isses_modifiable = 'FALSE' AND issys_modifiable = 'IMMEDIATE' THEN 3
                       ELSE 4 END,
                       CASE
                       WHEN LOWER(name) = 'db_file_multiblock_read_count' THEN 1
                       WHEN LOWER(name) = '_db_file_optimizer_read_count' THEN 2
                       ELSE 3 END,
                       type,
                       LOWER(name))
      LOOP
        l_alter := '-- '||i.description||i.message||i.message2||LF;

        IF i.isses_modifiable = 'FALSE' AND i.issys_modifiable = 'FALSE' THEN
          l_alter := l_alter||'-- name:"'||i.name||'" value:"'||i.display_value||'" skip:"non-modifiable"';
        ELSE
          IF i.isses_modifiable = 'TRUE' THEN
            l_alter := l_alter||'ALTER SESSION SET ';
            l_scope := NULL;
          ELSE -- i.issys_modifiable IN ('DEFERRED', 'IMMEDIATE')
            l_alter := l_alter||'ALTER SYSTEM SET ';
            l_scope := ' SCOPE=MEMORY';
          END IF;

          IF SUBSTR(i.name, 1, 1) = CHR(95) THEN -- "_"
            l_alter := l_alter||'"'||i.name||'" = ';
          ELSE
            l_alter := l_alter||i.name||' = ';
          END IF;

          IF i.type = 2 THEN -- String
            l_alter := l_alter||''''||UPPER(i.value)||'''';
          ELSE
            l_alter := l_alter||UPPER(i.value);
          END IF;

          IF i.name = 'pga_aggregate_target' THEN -- skip since it hangs in some windows systems
            l_alter := REPLACE(l_alter, 'ALTER', '-- ALTER');
          END IF;
        END IF;

        l_alter := l_alter||l_scope||';'||LF||LF;

        IF i.isdefault = 'TRUE' AND i.ismodified = 'FALSE' THEN
          --l_params_def := l_params_def||l_alter;
          SYS.DBMS_LOB.WRITEAPPEND(l_params_def, LENGTH(l_alter), l_alter);
        ELSE
          --l_params_non := l_params_non||l_alter;
          SYS.DBMS_LOB.WRITEAPPEND(l_params_non, LENGTH(l_alter), l_alter);
        END IF;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('set_cbo_env_script.parameters:'||SQLERRM);
    END;

    /* -------------------------
     * Bug Fix Control
     * ------------------------- */
    BEGIN
      FOR i IN (SELECT bugno,
                       value,
                       is_default,
                       description,
                       CASE WHEN optimizer_feature_enable IS NOT NULL THEN ' (ofe '||optimizer_feature_enable||')' END ofe,
                       CASE WHEN event IS NOT NULL THEN ' (event '||event||')' END event
                  FROM sqlt$_v$session_fix_control
                 WHERE statement_id = p_statement_id
                 ORDER BY
                       is_default,
                       bugno)
      LOOP
        l_alter := '-- '||i.description||i.ofe||i.event||LF;
        l_alter := l_alter||'ALTER SESSION SET "_fix_control" = '''||i.bugno||':'||i.value||''';';
        l_alter := l_alter||LF||LF;

        IF i.is_default = 1 THEN
          --l_fixctl_def := l_fixctl_def||l_alter;
          SYS.DBMS_LOB.WRITEAPPEND(l_fixctl_def, LENGTH(l_alter), l_alter);
        ELSE
          --l_fixctl_non := l_fixctl_non||l_alter;
          SYS.DBMS_LOB.WRITEAPPEND(l_fixctl_non, LENGTH(l_alter), l_alter);
        END IF;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('set_cbo_env_script.fix_ctl:'||SQLERRM);
    END;

    /* -------------------------
     * Footer and closure
     * ------------------------- */
    BEGIN
      wa(LF||SEPARATOR||LF);
      wa('REM Non-Default or Modified Parameters'||LF||LF);
      append(TRIM(LF FROM l_params_non));
      SYS.DBMS_LOB.FREETEMPORARY(l_params_non);

      wa(LF||SEPARATOR||LF);
      wa('REM Non-Default Bug Fix Control'||LF||LF);
      append(TRIM(LF FROM l_fixctl_non));
      SYS.DBMS_LOB.FREETEMPORARY(l_fixctl_non);

      wa(LF||SEPARATOR||LF);
      wa('REM Default Unmodified Parameters'||LF||LF);
      append(TRIM(LF FROM l_params_def));
      SYS.DBMS_LOB.FREETEMPORARY(l_params_def);

      wa(LF||SEPARATOR||LF);
      wa('REM Default Bug Fix Control'||LF||LF);
      append(TRIM(LF FROM l_fixctl_def));
      SYS.DBMS_LOB.FREETEMPORARY(l_fixctl_def);

      wa(LF||SEPARATOR||LF||LF||'SPO OFF;');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id  => p_statement_id,
        p_file_type     => 'SET_CBO_ENV_SCRIPT',
        p_filename      => s_file_rec.filename,
        p_statement_id2 => p_group_id,
        p_db_link       => p_db_link,
        p_file_size     => s_file_rec.file_size,
        p_file_text     => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_sqlt_set_cbo_env = s_file_rec.filename
       WHERE statement_id = p_statement_id;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('set_cbo_env_script.close:'||SQLERRM);
    END;

    write_log('<- set_cbo_env_script');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('set_cbo_env_script:'||SQLERRM);
  END set_cbo_env_script;

  /*************************************************************************************/

  /* -------------------------
   *
   * public lite_report
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE lite_report (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

    /* -------------------------
     *
     * private lite_report.wa - write append
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

  BEGIN
    write_log('-> lite_report');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_lite.html';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_lite.html';
    END IF;

    /* -------------------------
     * Header
     * ------------------------- */
    BEGIN
      write_log('-> lite_report.header');
      s_file_rec.file_text :=
'<html>
<!-- $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $ -->
<!-- '||COPYRIGHT||' -->
<!-- Author: '||TOOL_DEVELOPER_EMAIL||' -->
<head>
<title>'||s_file_rec.filename||'</title>
<style type="text/css">
a {font-weight:bold; color:#663300;}
body {font:10pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}
h1 {font-size:16pt; font-weight:bold; color:#336699;}
h2 {font-size:14pt; font-weight:bold; color:#336699;}
h3 {font-size:12pt; font-weight:bold; color:#336699;}
li {font-size:10pt; font-weight:bold; color:#336699; padding:0.1em 0 0 0;}
table {font-size:8pt; color:black; background:white;}
th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
td {text-align:left; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
td.left {text-align:left}
td.right {text-align:right}
td.title {font-weight:bold;text-align:right;background-color:#cccc99;color:#336699}
font.tablenote {font-size:8pt;font-style:italic;color:#336699}
font.f {font-size:8pt; color:#999999;
</style>
</head>
<body>
<h1>'||NOTE_NUMBER||' SQLT '||sql_rec.method||' '||sqlt$a.get_param('tool_version')||' Report: '||s_file_rec.filename||'</h1>
<ul>
<li><a href="#plans_summary">Plans Summary</a></li>
<li><a href="#plans">Plans</a></li>
<li><a href="#tables">Tables</a></li>
<li><a href="#table_columns">Table Columns</a></li>
<li><a href="#indexes">Indexes</a></li>
<li><a href="#index_columns">Index Columns</a></li>
</ul>
';
    EXCEPTION
      WHEN OTHERS THEN
        write_error('lite_report.header:'||SQLERRM);
    END;

    /* -------------------------
     * Plans Summary
     * ------------------------- */
    DECLARE
      l_plan_hash_value        NUMBER;
      l_elapsed_time_secs      NUMBER;
      l_cpu_time_secs          NUMBER;
      l_user_io_wait_time_secs NUMBER;
      l_other_wait_time_secs   NUMBER;
      l_buffer_gets            NUMBER;
      l_disk_reads             NUMBER;
      l_direct_writes          NUMBER;
      l_rows_processed         NUMBER;
      l_executions             NUMBER;
      l_fetches                NUMBER;
      l_version_count          NUMBER;
      l_loads                  NUMBER;
      l_invalidations          NUMBER;
      l_src                    NUMBER;
      l_source                 NUMBER;
    BEGIN
      write_log('-> lite_report.plans_summary');

      SELECT GREATEST(MAX(NVL(LENGTH(plan_hash_value), 0)), 9) l_plan_hash_value,
             GREATEST(MAX(NVL(LENGTH(TRIM(elapsed_time_secs)), 0)), 7) l_elapsed_time_secs,
             GREATEST(MAX(NVL(LENGTH(TRIM(cpu_time_secs)), 0)), 4) l_cpu_time_secs,
             GREATEST(MAX(NVL(LENGTH(TRIM(user_io_wait_time_secs)), 0)), 4) l_user_io_wait_time_secs,
             GREATEST(MAX(NVL(LENGTH(TRIM(other_wait_time_secs)), 0)), 5) l_other_wait_time_secs,
             GREATEST(MAX(NVL(LENGTH(buffer_gets), 0)), 6) l_buffer_gets,
             GREATEST(MAX(NVL(LENGTH(disk_reads), 0)), 5) l_disk_reads,
             GREATEST(MAX(NVL(LENGTH(direct_writes), 0)), 6) l_direct_writes,
             GREATEST(MAX(NVL(LENGTH(rows_processed), 0)), 9) l_rows_processed,
             GREATEST(MAX(NVL(LENGTH(executions), 0)), 10) l_executions,
             GREATEST(MAX(NVL(LENGTH(fetches), 0)), 7) l_fetches,
             GREATEST(MAX(NVL(LENGTH(version_count), 0)), 7) l_version_count,
             GREATEST(MAX(NVL(LENGTH(loads), 0)), 5) l_loads,
             GREATEST(MAX(NVL(LENGTH(invalidations), 0)), 13) l_invalidations,
             GREATEST(MAX(NVL(LENGTH(src), 0)), 3) l_src,
             GREATEST(MAX(NVL(LENGTH(source), 0)), 6) l_source
        INTO l_plan_hash_value,
             l_elapsed_time_secs,
             l_cpu_time_secs,
             l_user_io_wait_time_secs,
             l_other_wait_time_secs,
             l_buffer_gets,
             l_disk_reads,
             l_direct_writes,
             l_rows_processed,
             l_executions,
             l_fetches,
             l_version_count,
             l_loads,
             l_invalidations,
             l_src,
             l_source
        FROM sqlt$_plan_summary_v2
       WHERE statement_id = sql_rec.statement_id;

      wa('<hr size="3"><a name="plans_summary"></a><h2>Plans Summary</h2>');
      wa('<pre>');

      wa(
      LPAD(' ', l_plan_hash_value, ' ')||' '||
      LPAD(' ', l_elapsed_time_secs, ' ')||' '||
      LPAD(' ', l_cpu_time_secs, ' ')||' '||
      LPAD('Avg', l_user_io_wait_time_secs, ' ')||' '||
      LPAD(' ', l_other_wait_time_secs, ' ')||' '||
      LPAD(' ', l_buffer_gets, ' ')||' '||
      LPAD(' ', l_disk_reads, ' ')||' '||
      LPAD(' ', l_direct_writes, ' ')||' '||
      LPAD(' ', l_rows_processed, ' ')||' '||
      LPAD(' ', l_executions, ' ')||' '||
      LPAD(' ', l_fetches, ' ')||' '||
      LPAD(' ', l_version_count, ' ')||' '||
      LPAD(' ', l_loads, ' ')||' '||
      LPAD(' ', l_invalidations, ' ')||' '||
      RPAD(' ', l_src, ' ')||' '||
      RPAD(' ', l_source, ' ')
      );

      wa(
      LPAD(' ', l_plan_hash_value, ' ')||' '||
      LPAD(' ', l_elapsed_time_secs, ' ')||' '||
      LPAD(' ', l_cpu_time_secs, ' ')||' '||
      LPAD('User', l_user_io_wait_time_secs, ' ')||' '||
      LPAD('Avg', l_other_wait_time_secs, ' ')||' '||
      LPAD(' ', l_buffer_gets, ' ')||' '||
      LPAD(' ', l_disk_reads, ' ')||' '||
      LPAD(' ', l_direct_writes, ' ')||' '||
      LPAD(' ', l_rows_processed, ' ')||' '||
      LPAD(' ', l_executions, ' ')||' '||
      LPAD(' ', l_fetches, ' ')||' '||
      LPAD(' ', l_version_count, ' ')||' '||
      LPAD(' ', l_loads, ' ')||' '||
      LPAD(' ', l_invalidations, ' ')||' '||
      RPAD(' ', l_src, ' ')||' '||
      RPAD(' ', l_source, ' ')
      );

      wa(
      LPAD(' ', l_plan_hash_value, ' ')||' '||
      LPAD(' ', l_elapsed_time_secs, ' ')||' '||
      LPAD('AVG', l_cpu_time_secs, ' ')||' '||
      LPAD('I/O', l_user_io_wait_time_secs, ' ')||' '||
      LPAD('Other', l_other_wait_time_secs, ' ')||' '||
      LPAD(' ', l_buffer_gets, ' ')||' '||
      LPAD(' ', l_disk_reads, ' ')||' '||
      LPAD(' ', l_direct_writes, ' ')||' '||
      LPAD(' ', l_rows_processed, ' ')||' '||
      LPAD(' ', l_executions, ' ')||' '||
      LPAD(' ', l_fetches, ' ')||' '||
      LPAD(' ', l_version_count, ' ')||' '||
      LPAD(' ', l_loads, ' ')||' '||
      LPAD(' ', l_invalidations, ' ')||' '||
      RPAD(' ', l_src, ' ')||' '||
      RPAD(' ', l_source, ' ')
      );

      wa(
      LPAD(' ', l_plan_hash_value, ' ')||' '||
      LPAD('Avg', l_elapsed_time_secs, ' ')||' '||
      LPAD('CPU', l_cpu_time_secs, ' ')||' '||
      LPAD('Wait', l_user_io_wait_time_secs, ' ')||' '||
      LPAD('Wait', l_other_wait_time_secs, ' ')||' '||
      LPAD(' ', l_buffer_gets, ' ')||' '||
      LPAD(' ', l_disk_reads, ' ')||' '||
      LPAD(' ', l_direct_writes, ' ')||' '||
      LPAD(' ', l_rows_processed, ' ')||' '||
      LPAD(' ', l_executions, ' ')||' '||
      LPAD(' ', l_fetches, ' ')||' '||
      LPAD(' ', l_version_count, ' ')||' '||
      LPAD(' ', l_loads, ' ')||' '||
      LPAD(' ', l_invalidations, ' ')||' '||
      RPAD(' ', l_src, ' ')||' '||
      RPAD(' ', l_source, ' ')
      );

      wa(
      LPAD(' ', l_plan_hash_value, ' ')||' '||
      LPAD('Elapsed', l_elapsed_time_secs, ' ')||' '||
      LPAD('Time', l_cpu_time_secs, ' ')||' '||
      LPAD('Time', l_user_io_wait_time_secs, ' ')||' '||
      LPAD('Time', l_other_wait_time_secs, ' ')||' '||
      LPAD('Avg', l_buffer_gets, ' ')||' '||
      LPAD('Avg', l_disk_reads, ' ')||' '||
      LPAD('Avg', l_direct_writes, ' ')||' '||
      LPAD(' ', l_rows_processed, ' ')||' '||
      LPAD(' ', l_executions, ' ')||' '||
      LPAD(' ', l_fetches, ' ')||' '||
      LPAD('Total', l_version_count, ' ')||' '||
      LPAD(' ', l_loads, ' ')||' '||
      LPAD(' ', l_invalidations, ' ')||' '||
      RPAD(' ', l_src, ' ')||' '||
      RPAD(' ', l_source, ' ')
      );

      wa(
      LPAD('Plan Hash', l_plan_hash_value, ' ')||' '||
      LPAD('Time in', l_elapsed_time_secs, ' ')||' '||
      LPAD('in', l_cpu_time_secs, ' ')||' '||
      LPAD('in', l_user_io_wait_time_secs, ' ')||' '||
      LPAD('in', l_other_wait_time_secs, ' ')||' '||
      LPAD('Buffer', l_buffer_gets, ' ')||' '||
      LPAD('Disk', l_disk_reads, ' ')||' '||
      LPAD('Direct', l_direct_writes, ' ')||' '||
      LPAD('Avg Rows', l_rows_processed, ' ')||' '||
      LPAD('Total', l_executions, ' ')||' '||
      LPAD('Total', l_fetches, ' ')||' '||
      LPAD('Version', l_version_count, ' ')||' '||
      LPAD('Total', l_loads, ' ')||' '||
      LPAD('Total', l_invalidations, ' ')||' '||
      RPAD(' ', l_src, ' ')||' '||
      RPAD(' ', l_source, ' ')
      );

      wa(
      LPAD('Value', l_plan_hash_value, ' ')||' '||
      LPAD('secs', l_elapsed_time_secs, ' ')||' '||
      LPAD('secs', l_cpu_time_secs, ' ')||' '||
      LPAD('secs', l_user_io_wait_time_secs, ' ')||' '||
      LPAD('secs', l_other_wait_time_secs, ' ')||' '||
      LPAD('Gets', l_buffer_gets, ' ')||' '||
      LPAD('Reads', l_disk_reads, ' ')||' '||
      LPAD('Writes', l_direct_writes, ' ')||' '||
      LPAD('Processed', l_rows_processed, ' ')||' '||
      LPAD('Executions', l_executions, ' ')||' '||
      LPAD('Fetches', l_fetches, ' ')||' '||
      LPAD('Count', l_version_count, ' ')||' '||
      LPAD('Loads', l_loads, ' ')||' '||
      LPAD('Invalidations', l_invalidations, ' ')||' '||
      RPAD('Src', l_src, ' ')||' '||
      RPAD('Source', l_source, ' ')
      );

      wa(
      LPAD('-', l_plan_hash_value, '-')||' '||
      LPAD('-', l_elapsed_time_secs, '-')||' '||
      LPAD('-', l_cpu_time_secs, '-')||' '||
      LPAD('-', l_user_io_wait_time_secs, '-')||' '||
      LPAD('-', l_other_wait_time_secs, '-')||' '||
      LPAD('-', l_buffer_gets, '-')||' '||
      LPAD('-', l_disk_reads, '-')||' '||
      LPAD('-', l_direct_writes, '-')||' '||
      LPAD('-', l_rows_processed, '-')||' '||
      LPAD('-', l_executions, '-')||' '||
      LPAD('-', l_fetches, '-')||' '||
      LPAD('-', l_version_count, '-')||' '||
      LPAD('-', l_loads, '-')||' '||
      LPAD('-', l_invalidations, '-')||' '||
      LPAD('-', l_src, '-')||' '||
      LPAD('-', l_source, '-')
      );

      FOR i IN (SELECT TO_CHAR(plan_hash_value) plan_hash_value,
                       TRIM(elapsed_time_secs) elapsed_time_secs,
                       TRIM(cpu_time_secs) cpu_time_secs,
                       TRIM(user_io_wait_time_secs) user_io_wait_time_secs,
                       TRIM(other_wait_time_secs) other_wait_time_secs,
                       TO_CHAR(buffer_gets) buffer_gets,
                       TO_CHAR(disk_reads) disk_reads,
                       TO_CHAR(direct_writes) direct_writes,
                       TO_CHAR(rows_processed) rows_processed,
                       TO_CHAR(executions) executions,
                       TO_CHAR(fetches) fetches,
                       TO_CHAR(version_count) version_count,
                       TO_CHAR(loads) loads,
                       TO_CHAR(invalidations) invalidations,
                       src,
                       source
                  FROM sqlt$_plan_summary_v2
                 WHERE statement_id = sql_rec.statement_id
                 ORDER BY
                       elapsed_time ASC NULLS LAST,
                       src_order,
                       optimizer_cost ASC NULLS LAST)
      LOOP
        wa(
        LPAD(NVL(i.plan_hash_value, ' '), l_plan_hash_value, ' ')||' '||
        LPAD(NVL(i.elapsed_time_secs, ' '), l_elapsed_time_secs, ' ')||' '||
        LPAD(NVL(i.cpu_time_secs, ' '), l_cpu_time_secs, ' ')||' '||
        LPAD(NVL(i.user_io_wait_time_secs, ' '), l_user_io_wait_time_secs, ' ')||' '||
        LPAD(NVL(i.other_wait_time_secs, ' '), l_other_wait_time_secs, ' ')||' '||
        LPAD(NVL(i.buffer_gets, ' '), l_buffer_gets, ' ')||' '||
        LPAD(NVL(i.disk_reads, ' '), l_disk_reads, ' ')||' '||
        LPAD(NVL(i.direct_writes, ' '), l_direct_writes, ' ')||' '||
        LPAD(NVL(i.rows_processed, ' '), l_rows_processed, ' ')||' '||
        LPAD(NVL(i.executions, ' '), l_executions, ' ')||' '||
        LPAD(NVL(i.fetches, ' '), l_fetches, ' ')||' '||
        LPAD(NVL(i.version_count, ' '), l_version_count, ' ')||' '||
        LPAD(NVL(i.loads, ' '), l_loads, ' ')||' '||
        LPAD(NVL(i.invalidations, ' '), l_invalidations, ' ')||' '||
        RPAD(NVL(i.src, ' '), l_src, ' ')||' '||
        RPAD(NVL(i.source,  ' '), l_source, ' ')
        );
      END LOOP;

      wa('</pre>'||LF||LF);
    EXCEPTION
      WHEN OTHERS THEN
        write_error('lite_report.plans_summary:'||SQLERRM);
    END;

    /* -------------------------
     * Plans List
     * ------------------------- */
    DECLARE
      l_plan_count NUMBER;
      l_row_count NUMBER := 0;
      l_plan_stats VARCHAR2(128) := sqlt$a.get_param('plan_stats');
    BEGIN
      write_log('-> lite_report.plans_list');
      wa('<hr size="3"><a name="plans"></a><h2>Plans</h2>');

      FOR i IN (SELECT api,
                       plan_hash_value,
                       DECODE(api, 'C', 'GV$SQL_PLAN', 'A', 'DBA_HIST_SQL_PLAN', 'D', 'PLAN_TABLE', 'B', 'SQL_PLAN_BASELINE', 'UNKNOWN') source
                  FROM sqlt$_dbms_xplan
                 WHERE statement_id = sql_rec.statement_id
                   AND CASE
                       WHEN api <> 'C' THEN 'Y'
                       WHEN api = 'C' AND l_plan_stats = 'BOTH' THEN 'Y'
                       WHEN api = 'C' AND l_plan_stats = 'LAST' AND format IN ('L','L12') THEN 'Y'
                       WHEN api = 'C' AND l_plan_stats = 'ALL' AND format IN ('A','A12') THEN 'Y'
                       ELSE 'N' END = 'Y'
                 GROUP BY
                       api,
                       plan_hash_value
                 ORDER BY
                       DECODE(api, 'C', 1, 'A', 2, 'D', 3, 'B', 4, 5),
                       plan_hash_value)
      LOOP
        l_plan_count := 0;

        FOR j IN (SELECT sql_handle,
                         plan_name,
                         inst_id,
                         child_number,
                         executions
                    FROM sqlt$_dbms_xplan
                   WHERE statement_id = sql_rec.statement_id
                     AND api = i.api
                     AND NVL(plan_hash_value, -666) = NVL(i.plan_hash_value, -666)
                     AND CASE
                         WHEN api <> 'C' THEN 'Y'
                         WHEN api = 'C' AND l_plan_stats = 'BOTH' THEN 'Y'
                         WHEN api = 'C' AND l_plan_stats = 'LAST' AND format = 'L' THEN 'Y'
                         WHEN api = 'C' AND l_plan_stats = 'ALL' AND format = 'A' THEN 'Y'
                         ELSE 'N' END = 'Y'
                   GROUP BY
                         sql_handle,
                         plan_name,
                         inst_id,
                         child_number,
                         executions
                   ORDER BY
                         sql_handle,
                         plan_name,
                         inst_id,
                         child_number,
                         executions)
        LOOP
          l_plan_count := l_plan_count + 1;

          FOR k IN (SELECT format,
                           DECODE(format, 'L12', 'ADVANCED ALLSTATS LAST REPORT ADAPTIVE', 'L', 'ADVANCED ALLSTATS LAST', 
                                          'A12', 'ADVANCED ALLSTATS REPORT ADAPTIVE', 'A', 'ADVANCED ALLSTATS', 
                                          'V12', 'ADVANCED REPORT ADAPTIVE', 'V', 'ADVANCED', 'UNKNOWN') format_desc
                      FROM sqlt$_dbms_xplan
                     WHERE statement_id = sql_rec.statement_id
                       AND api = i.api
                       AND NVL(plan_hash_value, -666) = NVL(i.plan_hash_value, -666)
                       AND NVL(sql_handle, '-666') = NVL(j.sql_handle, '-666')
                       AND NVL(plan_name, '-666') = NVL(j.plan_name, '-666')
                       AND NVL(inst_id, -666) = NVL(j.inst_id, -666)
                       AND NVL(child_number, -666) = NVL(j.child_number, -666)
                       AND NVL(executions, -666) = NVL(j.executions, -666)
                       AND CASE
                           WHEN api <> 'C' THEN 'Y'
                           WHEN api = 'C' AND l_plan_stats = 'BOTH' THEN 'Y'
                           WHEN api = 'C' AND l_plan_stats = 'LAST' AND format IN ('L','L12') THEN 'Y'
                           WHEN api = 'C' AND l_plan_stats = 'ALL' AND format = 'A' THEN 'Y'
                           ELSE 'N' END = 'Y'
                     GROUP BY
                           format
                     ORDER BY
                           DECODE(format, 'L12', 1, 'L', 1, 'A12', 2, 'A', 2,  'V12', 3, 'V', 3, 4))
          LOOP
            l_row_count := l_row_count + 1;

            IF l_row_count = 1 THEN
              wa('<table>');
              wa('<tr><th>#</th><th>Source</th><th>Plan<br>Hash Value</th><th>SQL<br>Handle</th><th>Plan<br>Name</th><th>Inst<br>ID</th><th>Child<br>Number</th><th>Executions</th><th>Format</th></tr>');
            END IF;

            wa('<tr>');
            wa('<td class= "title"><a href="#p'||l_row_count||'">'||l_row_count||'</a></td>');
            wa('<td class="left">'||i.source||'</td>');
            wa('<td class="right">'||i.plan_hash_value||'</td>');
            wa('<td class="left">'||j.sql_handle||'</td>');
            wa('<td class="left">'||j.plan_name||'</td>');
            wa('<td class="right">'||j.inst_id||'</td>');
            wa('<td class="right">'||j.child_number||'</td>');
            wa('<td class="right">'||j.executions||'</td>');
            wa('<td class="left">'||k.format_desc||'</td>');
            wa('</tr>');
          END LOOP;

          IF l_plan_count = sqlt$a.get_param_n('r_rows_table_m') THEN
            EXIT;
          END IF;
        END LOOP;
      END LOOP;

      IF l_row_count > 0 THEN
        wa('</table>');
        wa('<font class="tablenote">Display of child plans is restricted up to '||sqlt$a.get_param_n('r_rows_table_m')||' per phv as per tool parameter "r_rows_table_m".</font>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('lite_report.plans_list:'||SQLERRM);
    END;

    /* -------------------------
     * Plans
     * ------------------------- */
    DECLARE
      l_plan_count NUMBER;
      l_row_count NUMBER := 0;
      l_heading VARCHAR2(32767);
      l_plan_stats VARCHAR2(128) := sqlt$a.get_param('plan_stats');
    BEGIN
      write_log('-> lite_report.plans');
      FOR i IN (SELECT api,
                       plan_hash_value,
                       DECODE(api, 'C', 'GV$SQL_PLAN', 'A', 'DBA_HIST_SQL_PLAN', 'D', 'PLAN_TABLE', 'B', 'SQL_PLAN_BASELINE', 'UNKNOWN') source
                  FROM sqlt$_dbms_xplan
                 WHERE statement_id = sql_rec.statement_id
                   AND CASE
                       WHEN api <> 'C' THEN 'Y'
                       WHEN api = 'C' AND l_plan_stats = 'BOTH' THEN 'Y'
                       WHEN api = 'C' AND l_plan_stats = 'LAST' AND format IN ('L','L12') THEN 'Y'
                       WHEN api = 'C' AND l_plan_stats = 'ALL' AND format IN ('A','A12') THEN 'Y'
                       ELSE 'N' END = 'Y'
                 GROUP BY
                       api,
                       plan_hash_value
                 ORDER BY
                       DECODE(api, 'C', 1, 'A', 2, 'D', 3, 'B', 4, 5),
                       plan_hash_value)
      LOOP
        l_plan_count := 0;

        FOR j IN (SELECT sql_handle,
                         plan_name,
                         inst_id,
                         child_number,
                         executions
                    FROM sqlt$_dbms_xplan
                   WHERE statement_id = sql_rec.statement_id
                     AND api = i.api
                     AND NVL(plan_hash_value, -666) = NVL(i.plan_hash_value, -666)
                     AND CASE
                         WHEN api <> 'C' THEN 'Y'
                         WHEN api = 'C' AND l_plan_stats = 'BOTH' THEN 'Y'
                         WHEN api = 'C' AND l_plan_stats = 'LAST' AND format IN ('L','L12') THEN 'Y'
                         WHEN api = 'C' AND l_plan_stats = 'ALL' AND format IN ('A','A12') THEN 'Y'
                         ELSE 'N' END = 'Y'
                   GROUP BY
                         sql_handle,
                         plan_name,
                         inst_id,
                         child_number,
                         executions
                   ORDER BY
                         sql_handle,
                         plan_name,
                         inst_id,
                         child_number,
                         executions)
        LOOP
          l_plan_count := l_plan_count + 1;

          FOR k IN (SELECT format,
                           DECODE(format, 'L12', 'ADVANCED ALLSTATS LAST REPORT ADAPTIVE', 'L', 'ADVANCED ALLSTATS LAST', 
                                          'A12', 'ADVANCED ALLSTATS REPORT ADAPTIVE', 'A', 'ADVANCED ALLSTATS', 
                                          'V12', 'ADVANCED REPORT ADAPTIVE', 'V', 'ADVANCED', 'UNKNOWN') format_desc
                      FROM sqlt$_dbms_xplan
                     WHERE statement_id = sql_rec.statement_id
                       AND api = i.api
                       AND NVL(plan_hash_value, -666) = NVL(i.plan_hash_value, -666)
                       AND NVL(sql_handle, '-666') = NVL(j.sql_handle, '-666')
                       AND NVL(plan_name, '-666') = NVL(j.plan_name, '-666')
                       AND NVL(inst_id, -666) = NVL(j.inst_id, -666)
                       AND NVL(child_number, -666) = NVL(j.child_number, -666)
                       AND NVL(executions, -666) = NVL(j.executions, -666)
                       AND CASE
                           WHEN api <> 'C' THEN 'Y'
                           WHEN api = 'C' AND l_plan_stats = 'BOTH' THEN 'Y'
                           WHEN api = 'C' AND l_plan_stats = 'LAST' AND format IN ('L','L12') THEN 'Y'
                           WHEN api = 'C' AND l_plan_stats = 'ALL' AND format IN ('A','A12') THEN 'Y'
                           ELSE 'N' END = 'Y'
                     GROUP BY
                           format
                     ORDER BY
                           DECODE(format, 'L12', 1, 'L', 1, 'A12', 2, 'A', 2,  'V12', 3, 'V', 3, 4))
          LOOP
            l_row_count := l_row_count + 1;

            l_heading := i.source;
            IF i.plan_hash_value IS NOT NULL THEN
              l_heading := l_heading||NBSP2||'phv:'||i.plan_hash_value;
            END IF;
            IF j.sql_handle IS NOT NULL THEN
              l_heading := l_heading||NBSP2||'handle:'||j.sql_handle;
            END IF;
            IF j.plan_name IS NOT NULL THEN
              l_heading := l_heading||NBSP2||'plan:'||j.plan_name;
            END IF;
            IF j.inst_id IS NOT NULL THEN
              l_heading := l_heading||NBSP2||'inst:'||j.inst_id;
            END IF;
            IF j.child_number IS NOT NULL THEN
              l_heading := l_heading||NBSP2||'child:'||j.child_number;
            END IF;
            IF j.executions IS NOT NULL THEN
              l_heading := l_heading||NBSP2||'execs:'||j.executions;
            END IF;
            l_heading := l_heading||NBSP2||'format:'||k.format_desc;

            wa('<hr size="1"><a name="p'||l_row_count||'"></a><h3>'||l_heading||'</h3>');
            wa('<pre>');
            IF i.api = 'D' THEN
              font_sanitize_and_append(sql_rec.sql_text_clob, FALSE, 200); -- was 120 then 2000
              wa(LF);
            END IF;

            FOR l IN (SELECT plan_table_output
                        FROM sqlt$_dbms_xplan
                       WHERE statement_id = sql_rec.statement_id
                         AND api = i.api
                         AND NVL(plan_hash_value, -666) = NVL(i.plan_hash_value, -666)
                         AND NVL(sql_handle, '-666') = NVL(j.sql_handle, '-666')
                         AND NVL(plan_name, '-666') = NVL(j.plan_name, '-666')
                         AND NVL(inst_id, -666) = NVL(j.inst_id, -666)
                         AND NVL(child_number, -666) = NVL(j.child_number, -666)
                         AND NVL(executions, -666) = NVL(j.executions, -666)
                         AND format = k.format
                         AND CASE
                             WHEN api <> 'C' THEN 'Y'
                             WHEN api = 'C' AND l_plan_stats = 'BOTH' THEN 'Y'
                             WHEN api = 'C' AND l_plan_stats = 'LAST' AND format IN ('L','L12') THEN 'Y'
                             WHEN api = 'C' AND l_plan_stats = 'ALL' AND format IN ('A','A12') THEN 'Y'
                             ELSE 'N' END = 'Y'
                       ORDER BY
                             line_id)
            LOOP
              sanitize_and_append(l.plan_table_output||LF, FALSE, 300);
            END LOOP;

            wa('</pre>'||LF);
          END LOOP;
        END LOOP;
      END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('lite_report.plans:'||SQLERRM);
    END;

    /* -------------------------
     * Tables
     * ------------------------- */
    DECLARE
      l_table_name      NUMBER;
      l_owner           NUMBER;
      l_partitioned     NUMBER;
      l_temporary       NUMBER;
      l_count_star      NUMBER;
      l_num_rows        NUMBER;
      l_sample_size     NUMBER;
      l_percent         NUMBER;
      l_last_analyzed   NUMBER;
      l_extents         NUMBER;
      l_segment_blocks  NUMBER;
      l_blocks          NUMBER;
      l_empty_blocks    NUMBER;
      l_avg_space       NUMBER;
      l_avg_row_len     NUMBER;
      l_chain_cnt       NUMBER;
      l_global_stats    NUMBER;
      l_user_stats      NUMBER;
      l_stattype_locked NUMBER;
      l_stale_stats     NUMBER;
    BEGIN
      write_log('-> lite_report.tables');

      SELECT GREATEST(MAX(NVL(LENGTH(s.table_name), 0)), 10) l_table_name,
             GREATEST(MAX(NVL(LENGTH(s.owner), 0)), 5) l_owner,
             GREATEST(MAX(NVL(LENGTH(x.partitioned), 0)), 4) l_partitioned,
             GREATEST(MAX(NVL(LENGTH(x.temporary), 0)), 4) l_temporary,
             GREATEST(MAX(NVL(LENGTH(x.count_star), 0)), 5) l_count_star,
             GREATEST(MAX(NVL(LENGTH(s.num_rows), 0)), 4) l_num_rows,
             GREATEST(MAX(NVL(LENGTH(s.sample_size), 0)), 6) l_sample_size,
             GREATEST(MAX(NVL(LENGTH(CASE WHEN s.num_rows > 0 THEN TRIM(TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), PERCENT_FORMAT)) END), 0)), 4) l_percent,
             GREATEST(MAX(NVL(LENGTH(TO_CHAR(s.last_analyzed, LOAD_DATE_FORMAT)), 0)), 13) l_last_analyzed,
             GREATEST(MAX(NVL(LENGTH(g.extents), 0)), 7) l_extents,
             GREATEST(MAX(NVL(LENGTH(g.blocks), 0)), 7) l_segment_blocks,
             GREATEST(MAX(NVL(LENGTH(s.blocks), 0)), 6) l_blocks,
             GREATEST(MAX(NVL(LENGTH(s.empty_blocks), 0)), 6) l_empty_blocks,
             GREATEST(MAX(NVL(LENGTH(s.avg_space), 0)), 5) l_avg_space,
             GREATEST(MAX(NVL(LENGTH(s.avg_row_len), 0)), 3) l_avg_row_len,
             GREATEST(MAX(NVL(LENGTH(s.chain_cnt), 0)), 5) l_chain_cnt,
             GREATEST(MAX(NVL(LENGTH(s.global_stats), 0)), 6) l_global_stats,
             GREATEST(MAX(NVL(LENGTH(s.user_stats), 0)), 5) l_user_stats,
             GREATEST(MAX(NVL(LENGTH(s.stattype_locked), 0)), 6) l_stattype_locked,
             GREATEST(MAX(NVL(LENGTH(s.stale_stats), 0)), 5) l_stale_stats
        INTO l_table_name,
             l_owner,
             l_partitioned,
             l_temporary,
             l_count_star,
             l_num_rows,
             l_sample_size,
             l_percent,
             l_last_analyzed,
             l_extents,
             l_segment_blocks,
             l_blocks,
             l_empty_blocks,
             l_avg_space,
             l_avg_row_len,
             l_chain_cnt,
             l_global_stats,
             l_user_stats,
             l_stattype_locked,
             l_stale_stats
        FROM sqlt$_dba_tab_statistics s,
             sqlt$_dba_all_tables_v x,
             sqlt$_dba_segments g
       WHERE s.statement_id = sql_rec.statement_id
         AND s.object_type = 'TABLE'
         AND s.statement_id = x.statement_id
         AND s.owner = x.owner
         AND s.table_name = x.table_name
         AND s.statement_id = g.statement_id(+)
         AND s.owner = g.owner(+)
         AND s.table_name = g.segment_name(+)
         AND 'TABLE' = g.segment_type(+);

      wa('<hr size="3"><a name="tables"></a><h2>Tables</h2>');
      wa('<pre>');

      wa(
      RPAD(' ', l_table_name, ' ')||' '||
      RPAD(' ', l_owner, ' ')||' '||
      RPAD(' ', l_partitioned, ' ')||' '||
      RPAD(' ', l_temporary, ' ')||' '||
      LPAD(' ', l_count_star, ' ')||' '||
      LPAD(' ', l_num_rows, ' ')||' '||
      LPAD(' ', l_sample_size, ' ')||' '||
      LPAD(' ', l_percent, ' ')||' '||
      RPAD(' ', l_last_analyzed, ' ')||' '||
      LPAD(' ', l_extents, ' ')||' '||
      LPAD(' ', l_segment_blocks, ' ')||' '||
      LPAD(' ', l_blocks, ' ')||' '||
      LPAD(' ', l_empty_blocks, ' ')||' '||
      LPAD(' ', l_avg_space, ' ')||' '||
      LPAD('Avg', l_avg_row_len, ' ')||' '||
      LPAD(' ', l_chain_cnt, ' ')||' '||
      RPAD(' ', l_global_stats, ' ')||' '||
      RPAD(' ', l_user_stats, ' ')||' '||
      RPAD('Stat', l_stattype_locked, ' ')||' '||
      RPAD(' ', l_stale_stats, ' ')
      );

      wa(
      RPAD(' ', l_table_name, ' ')||' '||
      RPAD(' ', l_owner, ' ')||' '||
      RPAD(' ', l_partitioned, ' ')||' '||
      RPAD(' ', l_temporary, ' ')||' '||
      LPAD(' ', l_count_star, ' ')||' '||
      LPAD('Num', l_num_rows, ' ')||' '||
      LPAD('Sample', l_sample_size, ' ')||' '||
      LPAD(' ', l_percent, ' ')||' '||
      RPAD(' ', l_last_analyzed, ' ')||' '||
      LPAD('Segment', l_extents, ' ')||' '||
      LPAD('Segment', l_segment_blocks, ' ')||' '||
      LPAD(' ', l_blocks, ' ')||' '||
      LPAD('Empty', l_empty_blocks, ' ')||' '||
      LPAD('Avg', l_avg_space, ' ')||' '||
      LPAD('Row', l_avg_row_len, ' ')||' '||
      LPAD('Chain', l_chain_cnt, ' ')||' '||
      RPAD('Global', l_global_stats, ' ')||' '||
      RPAD('User', l_user_stats, ' ')||' '||
      RPAD('Type', l_stattype_locked, ' ')||' '||
      RPAD('Stale', l_stale_stats, ' ')
      );

      wa(
      RPAD('Table Name', l_table_name, ' ')||' '||
      RPAD('Owner', l_owner, ' ')||' '||
      RPAD('Part', l_partitioned, ' ')||' '||
      RPAD('Temp', l_temporary, ' ')||' '||
      LPAD('Count', l_count_star, ' ')||' '||
      LPAD('Rows', l_num_rows, ' ')||' '||
      LPAD('Size', l_sample_size, ' ')||' '||
      LPAD('Perc', l_percent, ' ')||' '||
      RPAD('Last Analyzed', l_last_analyzed, ' ')||' '||
      LPAD('Extents', l_extents, ' ')||' '||
      LPAD('Blocks', l_segment_blocks, ' ')||' '||
      LPAD('Blocks', l_blocks, ' ')||' '||
      LPAD('Blocks', l_empty_blocks, ' ')||' '||
      LPAD('Space', l_avg_space, ' ')||' '||
      LPAD('Len', l_avg_row_len, ' ')||' '||
      LPAD('Cnt', l_chain_cnt, ' ')||' '||
      RPAD('Stats', l_global_stats, ' ')||' '||
      RPAD('Stats', l_user_stats, ' ')||' '||
      RPAD('Locked', l_stattype_locked, ' ')||' '||
      RPAD('Stats', l_stale_stats, ' ')
      );

      wa(
      RPAD('-', l_table_name, '-')||' '||
      RPAD('-', l_owner, '-')||' '||
      RPAD('-', l_partitioned, '-')||' '||
      RPAD('-', l_temporary, '-')||' '||
      RPAD('-', l_count_star, '-')||' '||
      RPAD('-', l_num_rows, '-')||' '||
      RPAD('-', l_sample_size, '-')||' '||
      RPAD('-', l_percent, '-')||' '||
      RPAD('-', l_last_analyzed, '-')||' '||
      RPAD('-', l_extents, '-')||' '||
      RPAD('-', l_segment_blocks, '-')||' '||
      RPAD('-', l_blocks, '-')||' '||
      RPAD('-', l_empty_blocks, '-')||' '||
      RPAD('-', l_avg_space, '-')||' '||
      RPAD('-', l_avg_row_len, '-')||' '||
      RPAD('-', l_chain_cnt, '-')||' '||
      RPAD('-', l_global_stats, '-')||' '||
      RPAD('-', l_user_stats, '-')||' '||
      RPAD('-', l_stattype_locked, '-')||' '||
      RPAD('-', l_stale_stats, '-')
      );

      FOR i IN (SELECT s.table_name,
                       s.owner,
                       x.partitioned,
                       x.temporary,
                       TO_CHAR(x.count_star) count_star,
                       TO_CHAR(s.num_rows) num_rows,
                       TO_CHAR(s.sample_size) sample_size,
                       CASE WHEN s.num_rows > 0 THEN TRIM(TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), PERCENT_FORMAT)) END percent,
                       TO_CHAR(s.last_analyzed, LOAD_DATE_FORMAT) last_analyzed,
                       TO_CHAR(g.extents) extents,
                       TO_CHAR(g.blocks) segment_blocks,
                       TO_CHAR(s.blocks) blocks,
                       TO_CHAR(s.empty_blocks) empty_blocks,
                       TO_CHAR(s.avg_space) avg_space,
                       TO_CHAR(s.avg_row_len) avg_row_len,
                       TO_CHAR(s.chain_cnt) chain_cnt,
                       s.global_stats,
                       s.user_stats,
                       s.stattype_locked,
                       s.stale_stats
                  FROM sqlt$_dba_tab_statistics s,
                       sqlt$_dba_all_tables_v x,
                       sqlt$_dba_segments g
                 WHERE s.statement_id = sql_rec.statement_id
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
        wa(
        RPAD(NVL(i.table_name, ' '), l_table_name, ' ')||' '||
        RPAD(NVL(i.owner, ' '), l_owner, ' ')||' '||
        RPAD(NVL(i.partitioned, ' '), l_partitioned, ' ')||' '||
        RPAD(NVL(i.temporary, ' '), l_temporary, ' ')||' '||
        LPAD(NVL(i.count_star, ' '), l_count_star, ' ')||' '||
        LPAD(NVL(i.num_rows, ' '), l_num_rows, ' ')||' '||
        LPAD(NVL(i.sample_size, ' '), l_sample_size, ' ')||' '||
        LPAD(NVL(i.percent, ' '), l_percent, ' ')||' '||
        RPAD(NVL(i.last_analyzed, ' '), l_last_analyzed, ' ')||' '||
        LPAD(NVL(i.extents, ' '), l_extents, ' ')||' '||
        LPAD(NVL(i.segment_blocks, ' '), l_segment_blocks, ' ')||' '||
        LPAD(NVL(i.blocks, ' '), l_blocks, ' ')||' '||
        LPAD(NVL(i.empty_blocks, ' '), l_empty_blocks, ' ')||' '||
        LPAD(NVL(i.avg_space, ' '), l_avg_space, ' ')||' '||
        LPAD(NVL(i.avg_row_len, ' '), l_avg_row_len, ' ')||' '||
        LPAD(NVL(i.chain_cnt, ' '), l_chain_cnt, ' ')||' '||
        RPAD(NVL(i.global_stats, ' '), l_global_stats, ' ')||' '||
        RPAD(NVL(i.user_stats, ' '), l_user_stats, ' ')||' '||
        RPAD(NVL(i.stattype_locked, ' '), l_stattype_locked, ' ')||' '||
        RPAD(NVL(i.stale_stats, ' '), l_stale_stats, ' ')
        );
      END LOOP;

      wa('</pre>'||LF||LF);
    EXCEPTION
      WHEN OTHERS THEN
        write_error('lite_report.tables:'||SQLERRM);
    END;

    /* -------------------------
     * Table Columns
     * ------------------------- */
    DECLARE
      l_table_name         NUMBER;
      l_column_name        NUMBER;
      l_column_id          NUMBER;
      l_num_rows           NUMBER;
      l_num_nulls          NUMBER;
      l_sample_size        NUMBER;
      l_percent            NUMBER;
      l_num_distinct       NUMBER;
      l_mutating_ndv       NUMBER;
      l_low_value_cooked   NUMBER;
      l_high_value_cooked  NUMBER;
      l_last_analyzed      NUMBER;
      l_avg_col_len        NUMBER;
      l_density            NUMBER;
      l_num_buckets        NUMBER;
      l_histogram          NUMBER;
      l_mutating_endpoints NUMBER;
      l_global_stats       NUMBER;
      l_user_stats         NUMBER;
    BEGIN
      write_log('-> lite_report.table_columns');
      SELECT GREATEST(MAX(NVL(LENGTH(c.table_name), 0)), 10) l_table_name,
             GREATEST(MAX(NVL(LENGTH(c.column_name), 0)), 11) l_column_name,
             GREATEST(MAX(NVL(LENGTH(c.column_id), 0)), 3) l_column_id,
             GREATEST(MAX(NVL(LENGTH(t.num_rows), 0)), 4) l_num_rows,
             GREATEST(MAX(NVL(LENGTH(c.num_nulls), 0)), 5) l_num_nulls,
             GREATEST(MAX(NVL(LENGTH(c.sample_size), 0)), 6) l_sample_size,
             GREATEST(MAX(NVL(LENGTH(
             CASE
             WHEN t.num_rows > c.num_nulls THEN TRIM(TO_CHAR(LEAST(100, ROUND(c.sample_size * 100 / (t.num_rows - c.num_nulls), 1)), PERCENT_FORMAT))
             WHEN t.num_rows = c.num_nulls THEN TRIM(TO_CHAR(100, PERCENT_FORMAT))
             END), 0)), 4) l_percent,
             GREATEST(MAX(NVL(LENGTH(c.num_distinct), 0)), 8) l_num_distinct,
             GREATEST(MAX(NVL(LENGTH(c.mutating_ndv), 0)), 10) l_mutating_ndv,
             GREATEST(MAX(NVL(LENGTH('"'||sanitize_html_clob(c.low_value_cooked)||'"'), 0)), 9) l_low_value_cooked,
             GREATEST(MAX(NVL(LENGTH('"'||sanitize_html_clob(c.high_value_cooked)||'"'), 0)), 10) l_high_value_cooked,
             GREATEST(MAX(NVL(LENGTH(TO_CHAR(c.last_analyzed, LOAD_DATE_FORMAT)), 0)), 13) l_last_analyzed,
             GREATEST(MAX(NVL(LENGTH(c.avg_col_len), 0)), 3) l_avg_col_len,
             GREATEST(MAX(NVL(LENGTH(LOWER(TO_CHAR(c.density, SCIENTIFIC_NOTATION))), 0)), 7) l_density,
             GREATEST(MAX(NVL(LENGTH(c.num_buckets), 0)), 7) l_num_buckets,
             GREATEST(MAX(NVL(LENGTH(c.histogram), 0)), 9) l_histogram,
             GREATEST(MAX(NVL(LENGTH(c.mutating_endpoints), 0)), 10) l_mutating_endpoints,
             GREATEST(MAX(NVL(LENGTH(c.global_stats), 0)), 6) l_global_stats,
             GREATEST(MAX(NVL(LENGTH(c.user_stats), 0)), 5) l_user_stats
        INTO l_table_name,
             l_column_name,
             l_column_id,
             l_num_rows,
             l_num_nulls,
             l_sample_size,
             l_percent,
             l_num_distinct,
             l_mutating_ndv,
             l_low_value_cooked,
             l_high_value_cooked,
             l_last_analyzed,
             l_avg_col_len,
             l_density,
             l_num_buckets,
             l_histogram,
             l_mutating_endpoints,
             l_global_stats,
             l_user_stats
        FROM sqlt$_dba_all_table_cols_v c,
             sqlt$_dba_all_tables_v t
       WHERE c.statement_id = sql_rec.statement_id
         AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
         AND c.statement_id = t.statement_id
         AND c.table_name = t.table_name
         AND c.owner = t.owner;

      wa('<hr size="3"><a name="table_columns"></a><h2>Table Columns</h2>');
      wa('<pre>');

      wa(
      RPAD(' ', l_table_name, ' ')||' '||
      RPAD(' ', l_column_name, ' ')||' '||
      LPAD(' ', l_column_id, ' ')||' '||
      LPAD(' ', l_num_rows, ' ')||' '||
      LPAD(' ', l_num_nulls, ' ')||' '||
      LPAD(' ', l_sample_size, ' ')||' '||
      LPAD(' ', l_percent, ' ')||' '||
      LPAD(' ', l_num_distinct, ' ')||' '||
      RPAD('Fluctuating', l_mutating_ndv, ' ')||' '||
      RPAD(' ', l_low_value_cooked, ' ')||' '||
      RPAD(' ', l_high_value_cooked, ' ')||' '||
      RPAD(' ', l_last_analyzed, ' ')||' '||
      LPAD('Avg', l_avg_col_len, ' ')||' '||
      LPAD(' ', l_density, ' ')||' '||
      LPAD(' ', l_num_buckets, ' ')||' '||
      RPAD(' ', l_histogram, ' ')||' '||
      RPAD('Fluctuating', l_mutating_endpoints, ' ')||' '||
      RPAD(' ', l_global_stats, ' ')||' '||
      RPAD(' ', l_user_stats, ' ')
      );

      wa(
      RPAD(' ', l_table_name, ' ')||' '||
      RPAD(' ', l_column_name, ' ')||' '||
      LPAD('Col', l_column_id, ' ')||' '||
      LPAD('Num', l_num_rows, ' ')||' '||
      LPAD('Num', l_num_nulls, ' ')||' '||
      LPAD('Sample', l_sample_size, ' ')||' '||
      LPAD(' ', l_percent, ' ')||' '||
      LPAD('Num', l_num_distinct, ' ')||' '||
      RPAD('NDV', l_mutating_ndv, ' ')||' '||
      RPAD(' ', l_low_value_cooked, ' ')||' '||
      RPAD(' ', l_high_value_cooked, ' ')||' '||
      RPAD(' ', l_last_analyzed, ' ')||' '||
      LPAD('Col', l_avg_col_len, ' ')||' '||
      LPAD(' ', l_density, ' ')||' '||
      LPAD('Num', l_num_buckets, ' ')||' '||
      RPAD(' ', l_histogram, ' ')||' '||
      RPAD('Endpoint', l_mutating_endpoints, ' ')||' '||
      RPAD('Global', l_global_stats, ' ')||' '||
      RPAD('User', l_user_stats, ' ')
      );

      wa(
      RPAD('Table Name', l_table_name, ' ')||' '||
      RPAD('Column Name', l_column_name, ' ')||' '||
      LPAD('ID', l_column_id, ' ')||' '||
      LPAD('Rows', l_num_rows, ' ')||' '||
      LPAD('Nulls', l_num_nulls, ' ')||' '||
      LPAD('Size', l_sample_size, ' ')||' '||
      LPAD('Perc', l_percent, ' ')||' '||
      LPAD('Distinct', l_num_distinct, ' ')||' '||
      RPAD('Count', l_mutating_ndv, ' ')||' '||
      RPAD('Low Value', l_low_value_cooked, ' ')||' '||
      RPAD('High Value', l_high_value_cooked, ' ')||' '||
      RPAD('Last Analyzed', l_last_analyzed, ' ')||' '||
      LPAD('Len', l_avg_col_len, ' ')||' '||
      LPAD('Density', l_density, ' ')||' '||
      LPAD('Buckets', l_num_buckets, ' ')||' '||
      RPAD('Histogram', l_histogram, ' ')||' '||
      RPAD('Count', l_mutating_endpoints, ' ')||' '||
      RPAD('Stats', l_global_stats, ' ')||' '||
      RPAD('Stats', l_user_stats, ' ')
      );

      wa(
      RPAD('-', l_table_name, '-')||' '||
      RPAD('-', l_column_name, '-')||' '||
      RPAD('-', l_column_id, '-')||' '||
      RPAD('-', l_num_rows, '-')||' '||
      RPAD('-', l_num_nulls, '-')||' '||
      RPAD('-', l_sample_size, '-')||' '||
      RPAD('-', l_percent, '-')||' '||
      RPAD('-', l_num_distinct, '-')||' '||
      RPAD('-', l_mutating_ndv, '-')||' '||
      RPAD('-', l_low_value_cooked, '-')||' '||
      RPAD('-', l_high_value_cooked, '-')||' '||
      RPAD('-', l_last_analyzed, '-')||' '||
      RPAD('-', l_avg_col_len, '-')||' '||
      RPAD('-', l_density, '-')||' '||
      RPAD('-', l_num_buckets, '-')||' '||
      RPAD('-', l_histogram, '-')||' '||
      RPAD('-', l_mutating_endpoints, '-')||' '||
      RPAD('-', l_global_stats, '-')||' '||
      RPAD('-', l_user_stats, '-')
      );

      FOR i IN (SELECT c.table_name,
                       c.column_name,
                       TO_CHAR(c.column_id) column_id,
                       TO_CHAR(t.num_rows) num_rows,
                       TO_CHAR(c.num_nulls) num_nulls,
                       TO_CHAR(c.sample_size) sample_size,
                       CASE
                       WHEN t.num_rows > c.num_nulls THEN TRIM(TO_CHAR(LEAST(100, ROUND(c.sample_size * 100 / (t.num_rows - c.num_nulls), 1)), PERCENT_FORMAT))
                       WHEN t.num_rows = c.num_nulls THEN TRIM(TO_CHAR(100, PERCENT_FORMAT))
                       END percent,
                       TO_CHAR(c.num_distinct) num_distinct,
                       c.mutating_ndv,
                       '"'||sanitize_html_clob(c.low_value_cooked)||'"' low_value_cooked,
                       '"'||sanitize_html_clob(c.high_value_cooked)||'"' high_value_cooked,
                       TO_CHAR(c.last_analyzed, LOAD_DATE_FORMAT) last_analyzed,
                       TO_CHAR(c.avg_col_len) avg_col_len,
                       LOWER(TO_CHAR(c.density, SCIENTIFIC_NOTATION)) density,
                       TO_CHAR(c.num_buckets) num_buckets,
                       c.histogram,
                       c.mutating_endpoints,
                       c.global_stats,
                       c.user_stats
                  FROM sqlt$_dba_all_table_cols_v c,
                       sqlt$_dba_all_tables_v t
                 WHERE c.statement_id = sql_rec.statement_id
                   AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
                   AND c.statement_id = t.statement_id
                   AND c.table_name = t.table_name
                   AND c.owner = t.owner
                 ORDER BY
                       c.table_name,
                       c.owner,
                       c.column_name)
      LOOP
        wa(
        RPAD(NVL(i.table_name, ' '), l_table_name, ' ')||' '||
        RPAD(NVL(i.column_name, ' '), l_column_name, ' ')||' '||
        LPAD(NVL(i.column_id, ' '), l_column_id, ' ')||' '||
        LPAD(NVL(i.num_rows, ' '), l_num_rows, ' ')||' '||
        LPAD(NVL(i.num_nulls, ' '), l_num_nulls, ' ')||' '||
        LPAD(NVL(i.sample_size, ' '), l_sample_size, ' ')||' '||
        LPAD(NVL(i.percent, ' '), l_percent, ' ')||' '||
        LPAD(NVL(i.num_distinct, ' '), l_num_distinct, ' ')||' '||
        RPAD(NVL(i.mutating_ndv, ' '), l_mutating_ndv, ' ')||' '||
        RPAD(NVL(i.low_value_cooked, ' '), l_low_value_cooked, ' ')||' '||
        RPAD(NVL(i.high_value_cooked, ' '), l_high_value_cooked, ' ')||' '||
        RPAD(NVL(i.last_analyzed, ' '), l_last_analyzed, ' ')||' '||
        LPAD(NVL(i.avg_col_len, ' '), l_avg_col_len, ' ')||' '||
        LPAD(NVL(i.density, ' '), l_density, ' ')||' '||
        LPAD(NVL(i.num_buckets, ' '), l_num_buckets, ' ')||' '||
        RPAD(NVL(i.histogram, ' '), l_histogram, ' ')||' '||
        RPAD(NVL(i.mutating_endpoints, ' '), l_mutating_endpoints, ' ')||' '||
        RPAD(NVL(i.global_stats, ' '), l_global_stats, ' ')||' '||
        RPAD(NVL(i.user_stats, ' '), l_user_stats, ' ')
        );
      END LOOP;

      wa('</pre>'||LF||LF);
    EXCEPTION
      WHEN OTHERS THEN
        write_error('lite_report.table_columns:'||SQLERRM);
    END;

    /* -------------------------
     * Indexes
     * ------------------------- */
    DECLARE
      l_table_name              NUMBER;
      l_index_name              NUMBER;
      l_owner                   NUMBER;
      l_index_type              NUMBER;
      l_partitioned             NUMBER;
      l_temporary               NUMBER;
      l_num_rows                NUMBER;
      l_sample_size             NUMBER;
      l_percent                 NUMBER;
      l_last_analyzed           NUMBER;
      l_distinct_keys           NUMBER;
      l_blevel                  NUMBER;
      l_extents                 NUMBER;
      l_segment_blocks          NUMBER;
      l_leaf_blocks             NUMBER;
      l_avg_leaf_blocks_per_key NUMBER;
      l_avg_data_blocks_per_key NUMBER;
      l_clustering_factor       NUMBER;
      l_global_stats            NUMBER;
      l_user_stats              NUMBER;
      l_stattype_locked         NUMBER;
      l_stale_stats             NUMBER;
    BEGIN
      write_log('-> lite_report.indexes');
      SELECT GREATEST(MAX(NVL(LENGTH(s.table_name), 0)), 10) l_table_name,
             GREATEST(MAX(NVL(LENGTH(s.index_name), 0)), 10) l_index_name,
             GREATEST(MAX(NVL(LENGTH(s.owner), 0)), 5) l_owner,
             GREATEST(MAX(NVL(LENGTH(x.index_type), 0)), 5) l_index_type,
             GREATEST(MAX(NVL(LENGTH(x.partitioned), 0)), 4) l_partitioned,
             GREATEST(MAX(NVL(LENGTH(x.temporary), 0)), 4) l_temporary,
             GREATEST(MAX(NVL(LENGTH(s.num_rows), 0)), 4) l_num_rows,
             GREATEST(MAX(NVL(LENGTH(s.sample_size), 0)), 6) l_sample_size,
             GREATEST(MAX(NVL(LENGTH(CASE WHEN s.num_rows > 0 THEN TRIM(TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), PERCENT_FORMAT)) END), 0)), 4) l_percent,
             GREATEST(MAX(NVL(LENGTH(TO_CHAR(s.last_analyzed, LOAD_DATE_FORMAT)), 0)), 13) l_last_analyzed,
             GREATEST(MAX(NVL(LENGTH(s.distinct_keys), 0)), 8) l_distinct_keys,
             GREATEST(MAX(NVL(LENGTH(s.blevel), 0)), 6) l_blevel,
             GREATEST(MAX(NVL(LENGTH(g.extents), 0)), 7) l_extents,
             GREATEST(MAX(NVL(LENGTH(g.blocks), 0)), 7) l_segment_blocks,
             GREATEST(MAX(NVL(LENGTH(s.leaf_blocks), 0)), 6) l_leaf_blocks,
             GREATEST(MAX(NVL(LENGTH(s.avg_leaf_blocks_per_key), 0)), 6) l_avg_leaf_blocks_per_key,
             GREATEST(MAX(NVL(LENGTH(s.avg_data_blocks_per_key), 0)), 6) l_avg_data_blocks_per_key,
             GREATEST(MAX(NVL(LENGTH(s.clustering_factor), 0)), 10) l_clustering_factor,
             GREATEST(MAX(NVL(LENGTH(s.global_stats), 0)), 6) l_global_stats,
             GREATEST(MAX(NVL(LENGTH(s.user_stats), 0)), 5) l_user_stats,
             GREATEST(MAX(NVL(LENGTH(s.stattype_locked), 0)), 6) l_stattype_locked,
             GREATEST(MAX(NVL(LENGTH(s.stale_stats), 0)), 5) l_stale_stats
        INTO l_table_name,
             l_index_name,
             l_owner,
             l_index_type,
             l_partitioned,
             l_temporary,
             l_num_rows,
             l_sample_size,
             l_percent,
             l_last_analyzed,
             l_distinct_keys,
             l_blevel,
             l_extents,
             l_segment_blocks,
             l_leaf_blocks,
             l_avg_leaf_blocks_per_key,
             l_avg_data_blocks_per_key,
             l_clustering_factor,
             l_global_stats,
             l_user_stats,
             l_stattype_locked,
             l_stale_stats
        FROM sqlt$_dba_ind_statistics s,
             sqlt$_dba_indexes x,
             sqlt$_dba_segments g
       WHERE s.statement_id = sql_rec.statement_id
         AND s.object_type = 'INDEX'
         AND s.statement_id = x.statement_id
         AND s.owner = x.owner
         AND s.index_name = x.index_name
         AND s.table_owner = x.table_owner
         AND s.table_name = x.table_name
         AND s.statement_id = g.statement_id(+)
         AND s.owner = g.owner(+)
         AND s.index_name = g.segment_name(+)
         AND 'INDEX' = g.segment_type(+);

      wa('<hr size="3"><a name="indexes"></a><h2>Indexes</h2>');
      wa('<pre>');

      wa(
      RPAD(' ', l_table_name, ' ')||' '||
      RPAD(' ', l_index_name, ' ')||' '||
      RPAD(' ', l_owner, ' ')||' '||
      RPAD(' ', l_index_type, ' ')||' '||
      RPAD(' ', l_partitioned, ' ')||' '||
      RPAD(' ', l_temporary, ' ')||' '||
      LPAD(' ', l_num_rows, ' ')||' '||
      LPAD(' ', l_sample_size, ' ')||' '||
      LPAD(' ', l_percent, ' ')||' '||
      RPAD(' ', l_last_analyzed, ' ')||' '||
      LPAD(' ', l_distinct_keys, ' ')||' '||
      LPAD(' ', l_blevel, ' ')||' '||
      LPAD(' ', l_extents, ' ')||' '||
      LPAD(' ', l_segment_blocks, ' ')||' '||
      LPAD(' ', l_leaf_blocks, ' ')||' '||
      LPAD('Avg', l_avg_leaf_blocks_per_key, ' ')||' '||
      LPAD('Avg', l_avg_data_blocks_per_key, ' ')||' '||
      LPAD(' ', l_clustering_factor, ' ')||' '||
      RPAD(' ', l_global_stats, ' ')||' '||
      RPAD(' ', l_user_stats, ' ')||' '||
      RPAD(' ', l_stattype_locked, ' ')||' '||
      RPAD(' ', l_stale_stats, ' ')
      );

      wa(
      RPAD(' ', l_table_name, ' ')||' '||
      RPAD(' ', l_index_name, ' ')||' '||
      RPAD(' ', l_owner, ' ')||' '||
      RPAD(' ', l_index_type, ' ')||' '||
      RPAD(' ', l_partitioned, ' ')||' '||
      RPAD(' ', l_temporary, ' ')||' '||
      LPAD(' ', l_num_rows, ' ')||' '||
      LPAD(' ', l_sample_size, ' ')||' '||
      LPAD(' ', l_percent, ' ')||' '||
      RPAD(' ', l_last_analyzed, ' ')||' '||
      LPAD(' ', l_distinct_keys, ' ')||' '||
      LPAD(' ', l_blevel, ' ')||' '||
      LPAD(' ', l_extents, ' ')||' '||
      LPAD(' ', l_segment_blocks, ' ')||' '||
      LPAD(' ', l_leaf_blocks, ' ')||' '||
      LPAD('Leaf', l_avg_leaf_blocks_per_key, ' ')||' '||
      LPAD('Data', l_avg_data_blocks_per_key, ' ')||' '||
      LPAD(' ', l_clustering_factor, ' ')||' '||
      RPAD(' ', l_global_stats, ' ')||' '||
      RPAD(' ', l_user_stats, ' ')||' '||
      RPAD(' ', l_stattype_locked, ' ')||' '||
      RPAD(' ', l_stale_stats, ' ')
      );

      wa(
      RPAD(' ', l_table_name, ' ')||' '||
      RPAD(' ', l_index_name, ' ')||' '||
      RPAD(' ', l_owner, ' ')||' '||
      RPAD(' ', l_index_type, ' ')||' '||
      RPAD(' ', l_partitioned, ' ')||' '||
      RPAD(' ', l_temporary, ' ')||' '||
      LPAD(' ', l_num_rows, ' ')||' '||
      LPAD(' ', l_sample_size, ' ')||' '||
      LPAD(' ', l_percent, ' ')||' '||
      RPAD(' ', l_last_analyzed, ' ')||' '||
      LPAD(' ', l_distinct_keys, ' ')||' '||
      LPAD(' ', l_blevel, ' ')||' '||
      LPAD(' ', l_extents, ' ')||' '||
      LPAD(' ', l_segment_blocks, ' ')||' '||
      LPAD(' ', l_leaf_blocks, ' ')||' '||
      LPAD('Blocks', l_avg_leaf_blocks_per_key, ' ')||' '||
      LPAD('Blocks', l_avg_data_blocks_per_key, ' ')||' '||
      LPAD(' ', l_clustering_factor, ' ')||' '||
      RPAD(' ', l_global_stats, ' ')||' '||
      RPAD(' ', l_user_stats, ' ')||' '||
      RPAD('Stat', l_stattype_locked, ' ')||' '||
      RPAD(' ', l_stale_stats, ' ')
      );

      wa(
      RPAD(' ', l_table_name, ' ')||' '||
      RPAD(' ', l_index_name, ' ')||' '||
      RPAD(' ', l_owner, ' ')||' '||
      RPAD('Index', l_index_type, ' ')||' '||
      RPAD(' ', l_partitioned, ' ')||' '||
      RPAD(' ', l_temporary, ' ')||' '||
      LPAD('Num', l_num_rows, ' ')||' '||
      LPAD('Sample', l_sample_size, ' ')||' '||
      LPAD(' ', l_percent, ' ')||' '||
      RPAD(' ', l_last_analyzed, ' ')||' '||
      LPAD('Distinct', l_distinct_keys, ' ')||' '||
      LPAD(' ', l_blevel, ' ')||' '||
      LPAD('Segment', l_extents, ' ')||' '||
      LPAD('Segment', l_segment_blocks, ' ')||' '||
      LPAD('Leaf', l_leaf_blocks, ' ')||' '||
      LPAD('per', l_avg_leaf_blocks_per_key, ' ')||' '||
      LPAD('per', l_avg_data_blocks_per_key, ' ')||' '||
      LPAD('Clustering', l_clustering_factor, ' ')||' '||
      RPAD('Global', l_global_stats, ' ')||' '||
      RPAD('User', l_user_stats, ' ')||' '||
      RPAD('Type', l_stattype_locked, ' ')||' '||
      RPAD('Stale', l_stale_stats, ' ')
      );

      wa(
      RPAD('Table Name', l_table_name, ' ')||' '||
      RPAD('Index Name', l_index_name, ' ')||' '||
      RPAD('Owner', l_owner, ' ')||' '||
      RPAD('Type', l_index_type, ' ')||' '||
      RPAD('Part', l_partitioned, ' ')||' '||
      RPAD('Temp', l_temporary, ' ')||' '||
      LPAD('Rows', l_num_rows, ' ')||' '||
      LPAD('Size', l_sample_size, ' ')||' '||
      LPAD('Perc', l_percent, ' ')||' '||
      RPAD('Last Analyzed', l_last_analyzed, ' ')||' '||
      LPAD('Keys', l_distinct_keys, ' ')||' '||
      LPAD('BLevel', l_blevel, ' ')||' '||
      LPAD('Extents', l_extents, ' ')||' '||
      LPAD('Blocks', l_segment_blocks, ' ')||' '||
      LPAD('Blocks', l_leaf_blocks, ' ')||' '||
      LPAD('Key', l_avg_leaf_blocks_per_key, ' ')||' '||
      LPAD('Key', l_avg_data_blocks_per_key, ' ')||' '||
      LPAD('Factor', l_clustering_factor, ' ')||' '||
      RPAD('Stats', l_global_stats, ' ')||' '||
      RPAD('Stats', l_user_stats, ' ')||' '||
      RPAD('Locked', l_stattype_locked, ' ')||' '||
      RPAD('Stats', l_stale_stats, ' ')
      );

      wa(
      RPAD('-', l_table_name, '-')||' '||
      RPAD('-', l_index_name, '-')||' '||
      RPAD('-', l_owner, '-')||' '||
      RPAD('-', l_index_type, '-')||' '||
      RPAD('-', l_partitioned, '-')||' '||
      RPAD('-', l_temporary, '-')||' '||
      RPAD('-', l_num_rows, '-')||' '||
      RPAD('-', l_sample_size, '-')||' '||
      RPAD('-', l_percent, '-')||' '||
      RPAD('-', l_last_analyzed, '-')||' '||
      RPAD('-', l_distinct_keys, '-')||' '||
      RPAD('-', l_blevel, '-')||' '||
      RPAD('-', l_extents, '-')||' '||
      RPAD('-', l_segment_blocks, '-')||' '||
      RPAD('-', l_leaf_blocks, '-')||' '||
      RPAD('-', l_avg_leaf_blocks_per_key, '-')||' '||
      RPAD('-', l_avg_data_blocks_per_key, '-')||' '||
      RPAD('-', l_clustering_factor, '-')||' '||
      RPAD('-', l_global_stats, '-')||' '||
      RPAD('-', l_user_stats, '-')||' '||
      RPAD('-', l_stattype_locked, '-')||' '||
      RPAD('-', l_stale_stats, '-')
      );

      FOR i IN (SELECT s.table_name,
                       s.index_name,
                       s.owner,
                       x.index_type,
                       x.partitioned,
                       x.temporary,
                       TO_CHAR(s.num_rows) num_rows,
                       TO_CHAR(s.sample_size) sample_size,
                       CASE WHEN s.num_rows > 0 THEN TRIM(TO_CHAR(ROUND(s.sample_size * 100 / s.num_rows, 1), PERCENT_FORMAT)) END percent,
                       TO_CHAR(s.last_analyzed, LOAD_DATE_FORMAT) last_analyzed,
                       TO_CHAR(s.distinct_keys) distinct_keys,
                       TO_CHAR(s.blevel) blevel,
                       TO_CHAR(g.extents) extents,
                       TO_CHAR(g.blocks) segment_blocks,
                       TO_CHAR(s.leaf_blocks) leaf_blocks,
                       TO_CHAR(s.avg_leaf_blocks_per_key) avg_leaf_blocks_per_key,
                       TO_CHAR(s.avg_data_blocks_per_key) avg_data_blocks_per_key,
                       TO_CHAR(s.clustering_factor) clustering_factor,
                       s.global_stats,
                       s.user_stats,
                       s.stattype_locked,
                       s.stale_stats
                  FROM sqlt$_dba_ind_statistics s,
                       sqlt$_dba_indexes x,
                       sqlt$_dba_segments g
                 WHERE s.statement_id = sql_rec.statement_id
                   AND s.object_type = 'INDEX'
                   AND s.statement_id = x.statement_id
                   AND s.owner = x.owner
                   AND s.index_name = x.index_name
                   AND s.table_owner = x.table_owner
                   AND s.table_name = x.table_name
                   AND s.statement_id = g.statement_id(+)
                   AND s.owner = g.owner(+)
                   AND s.index_name = g.segment_name(+)
                   AND 'INDEX' = g.segment_type(+)
                 ORDER BY
                       s.table_name,
                       s.table_owner,
                       s.index_name)
      LOOP
        wa(
        RPAD(NVL(i.table_name, ' '), l_table_name, ' ')||' '||
        RPAD(NVL(i.index_name, ' '), l_index_name, ' ')||' '||
        RPAD(NVL(i.owner, ' '), l_owner, ' ')||' '||
        RPAD(NVL(i.index_type, ' '), l_index_type, ' ')||' '||
        RPAD(NVL(i.partitioned, ' '), l_partitioned, ' ')||' '||
        RPAD(NVL(i.temporary, ' '), l_temporary, ' ')||' '||
        LPAD(NVL(i.num_rows, ' '), l_num_rows, ' ')||' '||
        LPAD(NVL(i.sample_size, ' '), l_sample_size, ' ')||' '||
        LPAD(NVL(i.percent, ' '), l_percent, ' ')||' '||
        RPAD(NVL(i.last_analyzed, ' '), l_last_analyzed, ' ')||' '||
        LPAD(NVL(i.distinct_keys, ' '), l_distinct_keys, ' ')||' '||
        LPAD(NVL(i.blevel, ' '), l_blevel, ' ')||' '||
        LPAD(NVL(i.extents, ' '), l_extents, ' ')||' '||
        LPAD(NVL(i.segment_blocks, ' '), l_segment_blocks, ' ')||' '||
        LPAD(NVL(i.leaf_blocks, ' '), l_leaf_blocks, ' ')||' '||
        LPAD(NVL(i.avg_leaf_blocks_per_key, ' '), l_avg_leaf_blocks_per_key, ' ')||' '||
        LPAD(NVL(i.avg_data_blocks_per_key, ' '), l_avg_data_blocks_per_key, ' ')||' '||
        LPAD(NVL(i.clustering_factor, ' '), l_clustering_factor, ' ')||' '||
        RPAD(NVL(i.global_stats, ' '), l_global_stats, ' ')||' '||
        RPAD(NVL(i.user_stats, ' '), l_user_stats, ' ')||' '||
        RPAD(NVL(i.stattype_locked, ' '), l_stattype_locked, ' ')||' '||
        RPAD(NVL(i.stale_stats, ' '), l_stale_stats, ' ')
        );
      END LOOP;

      wa('</pre>'||LF||LF);
    EXCEPTION
      WHEN OTHERS THEN
        write_error('lite_report.indexes:'||SQLERRM);
    END;

    /* -------------------------
     * Index Columns
     * ------------------------- */
    DECLARE
      l_table_name         NUMBER;
      l_index_name         NUMBER;
      l_column_position    NUMBER;
      l_column_name        NUMBER;
      l_column_id          NUMBER;
      l_num_rows           NUMBER;
      l_num_nulls          NUMBER;
      l_sample_size        NUMBER;
      l_percent            NUMBER;
      l_num_distinct       NUMBER;
      l_mutating_ndv       NUMBER;
      l_low_value_cooked   NUMBER;
      l_high_value_cooked  NUMBER;
      l_last_analyzed      NUMBER;
      l_avg_col_len        NUMBER;
      l_density            NUMBER;
      l_num_buckets        NUMBER;
      l_histogram          NUMBER;
      l_mutating_endpoints NUMBER;
      l_global_stats       NUMBER;
      l_user_stats         NUMBER;
    BEGIN
      write_log('-> lite_report.index_columns');
      SELECT GREATEST(MAX(NVL(LENGTH(ic.table_name), 0)), 10) l_table_name,
             GREATEST(MAX(NVL(LENGTH(ic.index_name), 0)), 10) l_index_name,
             GREATEST(MAX(NVL(LENGTH(ic.column_position), 0)), 3) l_column_position,
             GREATEST(MAX(NVL(LENGTH(ic.column_name), 0)), 11) l_column_name,
             GREATEST(MAX(NVL(LENGTH(c.column_id), 0)), 3) l_column_id,
             GREATEST(MAX(NVL(LENGTH(t.num_rows), 0)), 4) l_num_rows,
             GREATEST(MAX(NVL(LENGTH(c.num_nulls), 0)), 5) l_num_nulls,
             GREATEST(MAX(NVL(LENGTH(c.sample_size), 0)), 6) l_sample_size,
             GREATEST(MAX(NVL(LENGTH(
             CASE
             WHEN t.num_rows > c.num_nulls THEN TRIM(TO_CHAR(LEAST(100, ROUND(c.sample_size * 100 / (t.num_rows - c.num_nulls), 1)), PERCENT_FORMAT))
             WHEN t.num_rows = c.num_nulls THEN TRIM(TO_CHAR(100, PERCENT_FORMAT))
             END), 0)), 4) l_percent,
             GREATEST(MAX(NVL(LENGTH(c.num_distinct), 0)), 8) l_num_distinct,
             GREATEST(MAX(NVL(LENGTH(c.mutating_ndv), 0)), 10) l_mutating_ndv,
             GREATEST(MAX(NVL(LENGTH('"'||sanitize_html_clob(c.low_value_cooked)||'"'), 0)), 9) l_low_value_cooked,
             GREATEST(MAX(NVL(LENGTH('"'||sanitize_html_clob(c.high_value_cooked)||'"'), 0)), 10) l_high_value_cooked,
             GREATEST(MAX(NVL(LENGTH(TO_CHAR(c.last_analyzed, LOAD_DATE_FORMAT)), 0)), 13) l_last_analyzed,
             GREATEST(MAX(NVL(LENGTH(c.avg_col_len), 0)), 3) l_avg_col_len,
             GREATEST(MAX(NVL(LENGTH(LOWER(TO_CHAR(c.density, SCIENTIFIC_NOTATION))), 0)), 7) l_density,
             GREATEST(MAX(NVL(LENGTH(c.num_buckets), 0)), 7) l_num_buckets,
             GREATEST(MAX(NVL(LENGTH(c.histogram), 0)), 9) l_histogram,
             GREATEST(MAX(NVL(LENGTH(c.mutating_endpoints), 0)), 10) l_mutating_endpoints,
             GREATEST(MAX(NVL(LENGTH(c.global_stats), 0)), 6) l_global_stats,
             GREATEST(MAX(NVL(LENGTH(c.user_stats), 0)), 5) l_user_stats
        INTO l_table_name,
             l_index_name,
             l_column_position,
             l_column_name,
             l_column_id,
             l_num_rows,
             l_num_nulls,
             l_sample_size,
             l_percent,
             l_num_distinct,
             l_mutating_ndv,
             l_low_value_cooked,
             l_high_value_cooked,
             l_last_analyzed,
             l_avg_col_len,
             l_density,
             l_num_buckets,
             l_histogram,
             l_mutating_endpoints,
             l_global_stats,
             l_user_stats
        FROM sqlt$_dba_ind_columns ic,
             sqlt$_dba_all_table_cols_v c,
             sqlt$_dba_all_tables_v t
       WHERE ic.statement_id = sql_rec.statement_id
         AND ic.statement_id = c.statement_id
         AND ic.table_name = c.table_name
         AND ic.table_owner = c.owner
         AND ic.column_name = c.column_name
         AND c.statement_id = t.statement_id
         AND c.table_name = t.table_name
         AND c.owner = t.owner;

      wa('<hr size="3"><a name="index_columns"></a><h2>Index Columns</h2>');
      wa('<pre>');

      wa(
      RPAD(' ', l_table_name, ' ')||' '||
      RPAD(' ', l_index_name, ' ')||' '||
      LPAD(' ', l_column_position, ' ')||' '||
      RPAD(' ', l_column_name, ' ')||' '||
      LPAD(' ', l_column_id, ' ')||' '||
      LPAD(' ', l_num_rows, ' ')||' '||
      LPAD(' ', l_num_nulls, ' ')||' '||
      LPAD(' ', l_sample_size, ' ')||' '||
      LPAD(' ', l_percent, ' ')||' '||
      LPAD(' ', l_num_distinct, ' ')||' '||
      RPAD('Fluctuating', l_mutating_ndv, ' ')||' '||
      RPAD(' ', l_low_value_cooked, ' ')||' '||
      RPAD(' ', l_high_value_cooked, ' ')||' '||
      RPAD(' ', l_last_analyzed, ' ')||' '||
      LPAD('Avg', l_avg_col_len, ' ')||' '||
      LPAD(' ', l_density, ' ')||' '||
      LPAD(' ', l_num_buckets, ' ')||' '||
      RPAD(' ', l_histogram, ' ')||' '||
      RPAD('Fluctuating', l_mutating_endpoints, ' ')||' '||
      RPAD(' ', l_global_stats, ' ')||' '||
      RPAD(' ', l_user_stats, ' ')
      );

      wa(
      RPAD(' ', l_table_name, ' ')||' '||
      RPAD(' ', l_index_name, ' ')||' '||
      LPAD('Col', l_column_position, ' ')||' '||
      RPAD(' ', l_column_name, ' ')||' '||
      LPAD('Col', l_column_id, ' ')||' '||
      LPAD('Num', l_num_rows, ' ')||' '||
      LPAD('Num', l_num_nulls, ' ')||' '||
      LPAD('Sample', l_sample_size, ' ')||' '||
      LPAD(' ', l_percent, ' ')||' '||
      LPAD('Num', l_num_distinct, ' ')||' '||
      RPAD('NDV', l_mutating_ndv, ' ')||' '||
      RPAD(' ', l_low_value_cooked, ' ')||' '||
      RPAD(' ', l_high_value_cooked, ' ')||' '||
      RPAD(' ', l_last_analyzed, ' ')||' '||
      LPAD('Col', l_avg_col_len, ' ')||' '||
      LPAD(' ', l_density, ' ')||' '||
      LPAD('Num', l_num_buckets, ' ')||' '||
      RPAD(' ', l_histogram, ' ')||' '||
      RPAD('Endpoint', l_mutating_endpoints, ' ')||' '||
      RPAD('Global', l_global_stats, ' ')||' '||
      RPAD('User', l_user_stats, ' ')
      );

      wa(
      RPAD('Table Name', l_table_name, ' ')||' '||
      RPAD('Index Name', l_index_name, ' ')||' '||
      LPAD('Pos', l_column_position, ' ')||' '||
      RPAD('Column Name', l_column_name, ' ')||' '||
      LPAD('ID', l_column_id, ' ')||' '||
      LPAD('Rows', l_num_rows, ' ')||' '||
      LPAD('Nulls', l_num_nulls, ' ')||' '||
      LPAD('Size', l_sample_size, ' ')||' '||
      LPAD('Perc', l_percent, ' ')||' '||
      LPAD('Distinct', l_num_distinct, ' ')||' '||
      RPAD('Count', l_mutating_ndv, ' ')||' '||
      RPAD('Low Value', l_low_value_cooked, ' ')||' '||
      RPAD('High Value', l_high_value_cooked, ' ')||' '||
      RPAD('Last Analyzed', l_last_analyzed, ' ')||' '||
      LPAD('Len', l_avg_col_len, ' ')||' '||
      LPAD('Density', l_density, ' ')||' '||
      LPAD('Buckets', l_num_buckets, ' ')||' '||
      RPAD('Histogram', l_histogram, ' ')||' '||
      RPAD('Count', l_mutating_endpoints, ' ')||' '||
      RPAD('Stats', l_global_stats, ' ')||' '||
      RPAD('Stats', l_user_stats, ' ')
      );

      wa(
      RPAD('-', l_table_name, '-')||' '||
      RPAD('-', l_index_name, '-')||' '||
      RPAD('-', l_column_position, '-')||' '||
      RPAD('-', l_column_name, '-')||' '||
      RPAD('-', l_column_id, '-')||' '||
      RPAD('-', l_num_rows, '-')||' '||
      RPAD('-', l_num_nulls, '-')||' '||
      RPAD('-', l_sample_size, '-')||' '||
      RPAD('-', l_percent, '-')||' '||
      RPAD('-', l_num_distinct, '-')||' '||
      RPAD('-', l_mutating_ndv, '-')||' '||
      RPAD('-', l_low_value_cooked, '-')||' '||
      RPAD('-', l_high_value_cooked, '-')||' '||
      RPAD('-', l_last_analyzed, '-')||' '||
      RPAD('-', l_avg_col_len, '-')||' '||
      RPAD('-', l_density, '-')||' '||
      RPAD('-', l_num_buckets, '-')||' '||
      RPAD('-', l_histogram, '-')||' '||
      RPAD('-', l_mutating_endpoints, '-')||' '||
      RPAD('-', l_global_stats, '-')||' '||
      RPAD('-', l_user_stats, '-')
      );

      FOR i IN (SELECT ic.table_name,
                       ic.index_name,
                       TO_CHAR(ic.column_position) column_position,
                       ic.column_name,
                       TO_CHAR(c.column_id) column_id,
                       TO_CHAR(t.num_rows) num_rows,
                       TO_CHAR(c.num_nulls) num_nulls,
                       TO_CHAR(c.sample_size) sample_size,
                       CASE
                       WHEN t.num_rows > c.num_nulls THEN TRIM(TO_CHAR(LEAST(100, ROUND(c.sample_size * 100 / (t.num_rows - c.num_nulls), 1)), PERCENT_FORMAT))
                       WHEN t.num_rows = c.num_nulls THEN TRIM(TO_CHAR(100, PERCENT_FORMAT))
                       END percent,
                       TO_CHAR(c.num_distinct) num_distinct,
                       c.mutating_ndv,
                       '"'||sanitize_html_clob(c.low_value_cooked)||'"' low_value_cooked,
                       '"'||sanitize_html_clob(c.high_value_cooked)||'"' high_value_cooked,
                       TO_CHAR(c.last_analyzed, LOAD_DATE_FORMAT) last_analyzed,
                       TO_CHAR(c.avg_col_len) avg_col_len,
                       LOWER(TO_CHAR(c.density, SCIENTIFIC_NOTATION)) density,
                       TO_CHAR(c.num_buckets) num_buckets,
                       c.histogram,
                       c.mutating_endpoints,
                       c.global_stats,
                       c.user_stats
                  FROM sqlt$_dba_ind_columns ic,
                       sqlt$_dba_all_table_cols_v c,
                       sqlt$_dba_all_tables_v t
                 WHERE ic.statement_id = sql_rec.statement_id
                   AND ic.statement_id = c.statement_id
                   AND ic.table_name = c.table_name
                   AND ic.table_owner = c.owner
                   AND ic.column_name = c.column_name
                   AND c.statement_id = t.statement_id
                   AND c.table_name = t.table_name
                   AND c.owner = t.owner
                 ORDER BY
                       ic.table_name,
                       ic.table_owner,
                       ic.index_name,
                       ic.column_position)
      LOOP
        wa(
        RPAD(NVL(i.table_name, ' '), l_table_name, ' ')||' '||
        RPAD(NVL(i.index_name, ' '), l_index_name, ' ')||' '||
        LPAD(NVL(i.column_position, ' '), l_column_position, ' ')||' '||
        RPAD(NVL(i.column_name, ' '), l_column_name, ' ')||' '||
        LPAD(NVL(i.column_id, ' '), l_column_id, ' ')||' '||
        LPAD(NVL(i.num_rows, ' '), l_num_rows, ' ')||' '||
        LPAD(NVL(i.num_nulls, ' '), l_num_nulls, ' ')||' '||
        LPAD(NVL(i.sample_size, ' '), l_sample_size, ' ')||' '||
        LPAD(NVL(i.percent, ' '), l_percent, ' ')||' '||
        LPAD(NVL(i.num_distinct, ' '), l_num_distinct, ' ')||' '||
        RPAD(NVL(i.mutating_ndv, ' '), l_mutating_ndv, ' ')||' '||
        RPAD(NVL(i.low_value_cooked, ' '), l_low_value_cooked, ' ')||' '||
        RPAD(NVL(i.high_value_cooked, ' '), l_high_value_cooked, ' ')||' '||
        RPAD(NVL(i.last_analyzed, ' '), l_last_analyzed, ' ')||' '||
        LPAD(NVL(i.avg_col_len, ' '), l_avg_col_len, ' ')||' '||
        LPAD(NVL(i.density, ' '), l_density, ' ')||' '||
        LPAD(NVL(i.num_buckets, ' '), l_num_buckets, ' ')||' '||
        RPAD(NVL(i.histogram, ' '), l_histogram, ' ')||' '||
        RPAD(NVL(i.mutating_endpoints, ' '), l_mutating_endpoints, ' ')||' '||
        RPAD(NVL(i.global_stats, ' '), l_global_stats, ' ')||' '||
        RPAD(NVL(i.user_stats, ' '), l_user_stats, ' ')
        );
      END LOOP;

      wa('</pre>'||LF||LF);
    EXCEPTION
      WHEN OTHERS THEN
        write_error('lite_report.index_columns:'||SQLERRM);
    END;

    /* -------------------------
     * Footer and closure
     * ------------------------- */
    BEGIN
      write_log('-> lite_report.footer');
      wa('
<hr size="3">
<font class="f">'||NOTE_NUMBER||' '||s_file_rec.filename||' '||TO_CHAR(SYSDATE, LOAD_DATE_FORMAT)||'</font>
</body>
</html>');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id  => p_statement_id,
        p_file_type     => 'LITE_REPORT',
        p_filename      => s_file_rec.filename,
        p_statement_id2 => p_group_id,
        p_db_link       => p_db_link,
        p_file_size     => s_file_rec.file_size,
        p_file_text     => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_sqlt_lite = s_file_rec.filename
       WHERE statement_id = p_statement_id;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('lite_report.close:'||SQLERRM);
    END;

    write_log('<- lite_report');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('lite_report:'||SQLERRM);
  END lite_report;

  /*************************************************************************************/

  /* -------------------------
   *
   * public custom_sql_profile
   *
   * called by: sqlt$i.common_calls, qlt$i.remote_xtract and sqltprofile.sql
   *
   * ------------------------- */
  PROCEDURE custom_sql_profile (
    p_statement_id        IN NUMBER,
    p_plan_hash_value     IN NUMBER   DEFAULT NULL,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL,
    p_calling_library     IN VARCHAR2 DEFAULT 'sqltprofile.sql' )
  IS
    l_clob_size NUMBER;
    l_offset NUMBER;
    l_sql_text VARCHAR2(32767);
    l_len NUMBER;
    l_hint VARCHAR2(32767);
    l_name VARCHAR2(32767);
    l_pos NUMBER;
    l_plan_hash_value NUMBER;
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

    /* -------------------------
     *
     * private custom_sql_profile.wa - write append
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

    /* -------------------------
     *
     * private custom_sql_profile.append
     *
     * ------------------------- */
    PROCEDURE append (p_clob IN CLOB)
    IS
    BEGIN
      IF p_clob IS NOT NULL THEN
        IF SYS.DBMS_LOB.GETLENGTH(p_clob) > 0 THEN
          SYS.DBMS_LOB.APPEND (
            dest_lob => s_file_rec.file_text,
            src_lob  => p_clob );
        END IF;
      END IF;
    END append;

  BEGIN
    write_log('-> custom_sql_profile');

    IF sqlt$a.get_param('custom_sql_profile') = 'N' THEN
      write_log('** skip "custom_sql_profile" as per "custom_sql_profile" parameter. this functionality is now disabled by default.');
      write_log('** to enable this functionality execute: SQL> EXEC &&tool_administer_schema..sqlt$a.set_param(''custom_sql_profile'', ''Y'');');
      write_log('<- custom_sql_profile');
      IF p_calling_library = 'sqltprofile.sql' THEN
        RAISE_APPLICATION_ERROR (-20210, 'custom_sql_profile is now disabled by default.');
      ELSE
        RETURN;
      END IF;
    END IF;

    IF sqlt$a.get_param('sql_tuning_advisor') = 'N' THEN
      write_log('skip "custom_sql_profile" as per "sql_tuning_advisor" parameter');
      write_log('<- custom_sql_profile');
      RETURN;
    END IF;

    sqlt$a.common_initialization;
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_plan_hash_value IS NULL AND NVL(sql_rec.best_plan_hash_value, 0) < 1 THEN
      write_log('no plan to create profile for');
      write_log('<- custom_sql_profile');
      RETURN;
    ELSE
      l_plan_hash_value := NVL(p_plan_hash_value, sql_rec.best_plan_hash_value);
    END IF;

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_p'||l_plan_hash_value||'_sqlprof.sql';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_p'||l_plan_hash_value||'_sqlprof.sql';
    END IF;

    l_name := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_p'||l_plan_hash_value;

    /* -------------------------
     * Header
     * ------------------------- */
    s_file_rec.file_text :=
'SPO '||REPLACE(s_file_rec.filename, '.sql', '.log')||';
SET ECHO ON TERM ON LIN 2000 TRIMS ON NUMF 99999999999999999999;
REM
REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $
REM
REM '||COPYRIGHT||'
REM
REM AUTHOR
REM   '||TOOL_DEVELOPER_EMAIL||'
REM
REM SCRIPT
REM   '||s_file_rec.filename||'
REM
REM SOURCE
REM   Host    : '||sql_rec.host_name_short||'
REM   DB Name : '||sql_rec.database_name_short||'
REM   Platform: '||sql_rec.platform||'
REM   Product : '||sql_rec.product_version||'
REM   Version : '||sql_rec.rdbms_version||'
REM   Language: '||sql_rec.language||'
REM   EBS     : '||NVL(sql_rec.apps_release, 'NO')||'
REM   Siebel  : '||sql_rec.siebel||'
REM   PSFT    : '||sql_rec.psft||'
REM
REM DESCRIPTION
REM   This script is generated automatically by the '||TOOL_NAME||' tool.
REM   It contains the SQL*Plus commands to create a custom
REM   SQL Profile based on plan hash value '||l_plan_hash_value||'.
REM   The custom SQL Profile to be created by this script
REM   will affect plans for SQL commands with signature
REM   matching the one for SQL Text below.
REM   Review SQL Text and adjust accordingly.
REM
REM PARAMETERS
REM   None.
REM
REM EXAMPLE
REM   SQL> START '||s_file_rec.filename||';
REM
REM NOTES
REM   1. Should be run as SYSTEM or SYSDBA.
REM   2. User must have CREATE ANY SQL PROFILE privilege.
REM   3. SOURCE and TARGET systems can be the same or similar.
REM   4. To drop this custom SQL Profile after it has been created:
REM      EXEC SYS.DBMS_SQLTUNE.DROP_SQL_PROFILE('''||l_name||''');
REM   5. Be aware that using SYS.DBMS_SQLTUNE requires a license
REM      for the Oracle Tuning Pack.
REM   6. If you modified a SQL putting Hints in order to produce a desired
REM      Plan, you can remove the artifical Hints from SQL Text pieces below.
REM      By doing so you can create a custom SQL Profile for the original
REM      SQL but with the Plan captured from the modified SQL (with Hints).
REM
WHENEVER SQLERROR EXIT SQL.SQLCODE;

VAR signature NUMBER;

DECLARE
  sql_txt CLOB;
  h       SYS.SQLPROF_ATTR;
  PROCEDURE wa (p_line IN VARCHAR2) IS
  BEGIN
    SYS.DBMS_LOB.WRITEAPPEND(sql_txt, LENGTH(p_line), p_line);
  END wa;
BEGIN
  SYS.DBMS_LOB.CREATETEMPORARY(sql_txt, TRUE);
  SYS.DBMS_LOB.OPEN(sql_txt, SYS.DBMS_LOB.LOB_READWRITE);
  -- SQL Text pieces below do not have to be of same length.
  -- So if you edit SQL Text (i.e. removing temporary Hints),
  -- there is no need to edit or re-align unmodified pieces.';

    /* -------------------------
     * SQL Text
     * ------------------------- */
    --append(wrap_clob('  sql_txt := q''['||sql_rec.sql_text_clob_stripped||']'';'||LF, 2000)); -- was 120
    l_clob_size := NVL(DBMS_LOB.GETLENGTH(sql_rec.sql_text_in_pieces), 0);
    l_offset := 1;
    WHILE l_offset < l_clob_size
    LOOP
      l_pos := SYS.DBMS_LOB.INSTR(sql_rec.sql_text_in_pieces, NUL, l_offset);
      IF l_pos > 0 THEN
        l_len := l_pos - l_offset;
      ELSE -- last piece
        l_len := l_clob_size - l_pos + 1;
      END IF;
      l_sql_text := SYS.DBMS_LOB.SUBSTR(sql_rec.sql_text_in_pieces, l_len, l_offset);
      /* cannot do such 3 replacement since a line could end with a comment using "--"
      l_sql_text := REPLACE(l_sql_text, LF, ' '); -- replace LF with SP
      l_sql_text := REPLACE(l_sql_text, CR, ' '); -- replace CR with SP
      l_sql_text := REPLACE(l_sql_text, TAB, ' '); -- replace TAB with SP
      */
      l_offset := l_offset + l_len + 1;
      IF l_len > 0 THEN
        IF INSTR(l_sql_text, '''[') + INSTR(l_sql_text, ']''') = 0 THEN
          l_sql_text := '['||l_sql_text||']';
        ELSIF INSTR(l_sql_text, '''{') + INSTR(l_sql_text, '}''') = 0 THEN
          l_sql_text := '{'||l_sql_text||'}';
        ELSIF INSTR(l_sql_text, '''<') + INSTR(l_sql_text, '>''') = 0 THEN
          l_sql_text := '<'||l_sql_text||'>';
        ELSIF INSTR(l_sql_text, '''(') + INSTR(l_sql_text, ')''') = 0 THEN
          l_sql_text := '('||l_sql_text||')';
        ELSIF INSTR(l_sql_text, '''"') + INSTR(l_sql_text, '"''') = 0 THEN
          l_sql_text := '"'||l_sql_text||'"';
        ELSIF INSTR(l_sql_text, '''|') + INSTR(l_sql_text, '|''') = 0 THEN
          l_sql_text := '|'||l_sql_text||'|';
        ELSIF INSTR(l_sql_text, '''~') + INSTR(l_sql_text, '~''') = 0 THEN
          l_sql_text := '~'||l_sql_text||'~';
        ELSIF INSTR(l_sql_text, '''^') + INSTR(l_sql_text, '^''') = 0 THEN
          l_sql_text := '^'||l_sql_text||'^';
        ELSIF INSTR(l_sql_text, '''@') + INSTR(l_sql_text, '@''') = 0 THEN
          l_sql_text := '@'||l_sql_text||'@';
        ELSIF INSTR(l_sql_text, '''#') + INSTR(l_sql_text, '#''') = 0 THEN
          l_sql_text := '#'||l_sql_text||'#';
        ELSIF INSTR(l_sql_text, '''%') + INSTR(l_sql_text, '%''') = 0 THEN
          l_sql_text := '%'||l_sql_text||'%';
        ELSIF INSTR(l_sql_text, '''$') + INSTR(l_sql_text, '$''') = 0 THEN
          l_sql_text := '$'||l_sql_text||'$';
        ELSE
          l_sql_text := CHR(96)||l_sql_text||CHR(96);
        END IF;
        wa('  wa(q'''||l_sql_text||''');');
      END IF;
    END LOOP;
    wa('  SYS.DBMS_LOB.CLOSE(sql_txt);');

    /* -------------------------
     * Hints
     * ------------------------- */
    wa('  h := SYS.SQLPROF_ATTR('||LF||'  q''[BEGIN_OUTLINE_DATA]'',');
    FOR i IN (SELECT other_xml
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND plan_hash_value = l_plan_hash_value
                 AND other_xml IS NOT NULL
               ORDER BY
                     DECODE(source,
                     'GV$SQL_PLAN', 1,
                     'DBA_HIST_SQL_PLAN', 2,
                     'PLAN_TABLE', 3,
                     'DBA_SQLTUNE_PLANS', 4,
                     5),
                     inst_id,
                     child_number,
                     plan_id,
                     id)
    LOOP
      FOR j IN (SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
                       SUBSTR(EXTRACTVALUE(VALUE(d), '/hint'), 1, 4000) hint
                  FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(i.other_xml), '/*/outline_data/hint'))) d)
      LOOP
        l_hint := j.hint;
        WHILE NVL(LENGTH(l_hint), 0) > 0
        LOOP
          IF LENGTH(l_hint) <= 500 THEN
            wa('  q''['||l_hint||']'',');
            l_hint := NULL;
          ELSE
            l_pos := INSTR(SUBSTR(l_hint, 1, 500), ' ', -1);
            wa('  q''['||SUBSTR(l_hint, 1, l_pos)||']'',');
            l_hint := '   '||SUBSTR(l_hint, l_pos);
          END IF;
        END LOOP;
      END LOOP;

      EXIT; -- 1st
    END LOOP;
    wa('  q''[END_OUTLINE_DATA]'');');

    /* -------------------------
     * Footer
     * ------------------------- */
    wa(LF||'  :signature := SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(sql_txt);');
    wa(LF||'  SYS.DBMS_SQLTUNE.IMPORT_SQL_PROFILE (
    sql_text    => sql_txt,
    profile     => h,
    name        => '''||l_name||''',
    description => '''||sql_rec.statid||' '||sql_rec.sql_id||' '||l_plan_hash_value||' ''||:signature,
    category    => ''DEFAULT'',
    validate    => TRUE,
    replace     => TRUE,
    force_match => FALSE /* TRUE:FORCE (match even when different literals in SQL). FALSE:EXACT (similar to CURSOR_SHARING) */ );
    SYS.DBMS_LOB.FREETEMPORARY(sql_txt);
END;'||LF||'/

WHENEVER SQLERROR CONTINUE;
SET ECHO OFF;
PRINT signature
PRO
PRO ... manual custom SQL Profile has been created
PRO
SET TERM ON ECHO OFF LIN 80 TRIMS OFF NUMF "";
SPO OFF;
PRO
PRO SQLPROFILE completed.');

    /* -------------------------
     * Closure
     * ------------------------- */
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'CUSTOM_SQL_PROFILE',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_sqlt_profile = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- custom_sql_profile');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('custom_sql_profile:'||SQLERRM);
      write_log('<- custom_sql_profile');
  END custom_sql_profile;

  /*************************************************************************************/

  /* -------------------------
   *
   * public sql_monitor_reports
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   * 150911 added historic sql monitor reports
   * ------------------------- */
  PROCEDURE sql_monitor_reports (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    active_rec sqli$_file%ROWTYPE;
    html_rec sqli$_file%ROWTYPE;
    text_rec sqli$_file%ROWTYPE;
    l_sql VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);
    l_prefix VARCHAR2(32767);
    l_suffix VARCHAR2(32767);
    l_type VARCHAR2(32767);
    l_report_level VARCHAR2(32767) := 'ALL';
    l_null VARCHAR2(32767) := NULL;
	l_rid number;

  BEGIN
    write_log('-> sql_monitor_reports');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sqlt$a.get_param('sql_monitoring') = 'N' THEN
      write_log('skip "sql_monitor_reports" as per sql_monitoring parameter');
    ELSIF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip "sql_monitor_reports" for this method');
    ELSIF sql_rec.rdbms_release < 11 THEN
      write_log('skip "sql_monitor_reports" since not available in "'||sql_rec.rdbms_version||'"');
    ELSE
      l_sql := 'BEGIN :report := :prefix||SYS.DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id => :sql_id, report_level => :report_level, type => :type)||:suffix; END;';

      IF sql_rec.rdbms_version >= '11.2' THEN
        l_type := 'ACTIVE';
        l_prefix := NULL;
        l_suffix := NULL;
      ELSE -- 11.1
        l_type := 'XML';

        -- from Benoit -> Uday
        l_prefix := '<html>
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
        l_suffix := '
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
        EXECUTE IMMEDIATE l_sql USING OUT active_rec.file_text, IN l_prefix, IN sql_rec.sql_id, IN l_report_level, IN l_type, IN l_suffix;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('skip "sql_monitor_reports" ACTIVE as per error below');
          write_log('** '||SQLERRM);
          active_rec.file_text := NULL;
      END;

      BEGIN
        EXECUTE IMMEDIATE l_sql USING OUT html_rec.file_text, IN l_null, IN sql_rec.sql_id, IN l_report_level, IN 'HTML', IN l_null;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('skip "sql_monitor_reports" HTML as per error below');
          write_log('** '||SQLERRM);
          html_rec.file_text := NULL;
      END;

      BEGIN
        EXECUTE IMMEDIATE l_sql USING OUT text_rec.file_text, IN l_null, IN sql_rec.sql_id, IN l_report_level, IN 'TEXT', IN l_null;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('skip "sql_monitor_reports" TEXT as per error below');
          write_log('** '||SQLERRM);
          text_rec.file_text := NULL;
      END;

	  -- 150911 get historic if cannot find in memory
	  IF sql_rec.rdbms_release >= 12 AND
	     active_rec.file_text IS NULL OR
		 SYS.DBMS_LOB.GETLENGTH(active_rec.file_text) < 2000
		 THEN	 
        BEGIN
		 l_sql := 'SELECT REPORT_ID FROM sys.dba_hist_reports WHERE key1 = :sql_id and rownum=1 ORDER BY 1 DESC';
		 EXECUTE IMMEDIATE l_sql INTO l_rid USING IN sql_rec.sql_id;
		 l_sql := 'BEGIN :report := '||LOWER(TOOL_ADMINISTER_SCHEMA)||'.sqlt$a.report_hist_sql_monitor (p_report_id => :rid, p_type => :type); END;';
         EXECUTE IMMEDIATE l_sql USING OUT active_rec.file_text, IN  l_rid , 'ACTIVE';
        EXCEPTION
         WHEN OTHERS THEN
           write_log('skip historic "sql_monitor_reports" as per error below');
           write_log('** '||SQLERRM);
           active_rec.file_text := NULL;
        END;
	  else
	   write_log('active_rec.file_text IS NOT NULL');
	  END IF;	  
	  
      IF p_out_file_identifier IS NULL THEN
        l_out_file_identifier := NULL;
      ELSE
        l_out_file_identifier := '_'||p_out_file_identifier;
      END IF;

      BEGIN
        IF active_rec.file_text IS NOT NULL AND
           SYS.DBMS_LOB.GETLENGTH(active_rec.file_text) > 2000 -- not empty
        THEN
          sqlt$a.set_file (
            p_statement_id => p_statement_id,
            p_file_type    => 'SQL_MONITOR_ACTIVE',
            p_filename     => 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sql_monitor_active.html',
            p_statid       => sql_rec.statid,
            p_file_size    => SYS.DBMS_LOB.GETLENGTH(active_rec.file_text),
            p_file_text    => active_rec.file_text );

          UPDATE sqlt$_sql_statement
             SET file_mon_report_active = 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sql_monitor_active.html'
           WHERE statement_id = p_statement_id;

          write_log('"sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_sql_monitor_active.html" was uploaded to repository');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('sql_monitor_report.active:'||SQLERRM);
      END;

      BEGIN
        IF html_rec.file_text IS NOT NULL AND
           SYS.DBMS_LOB.GETLENGTH(html_rec.file_text) > 10000 -- not empty (< 9264 bytes)
        THEN
          sqlt$a.set_file (
            p_statement_id => p_statement_id,
            p_file_type    => 'SQL_MONITOR_HTML',
            p_filename     => 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sql_monitor.html',
            p_statid       => sql_rec.statid,
            p_file_size    => SYS.DBMS_LOB.GETLENGTH(html_rec.file_text),
            p_file_text    => html_rec.file_text );

          UPDATE sqlt$_sql_statement
             SET file_mon_report_html = 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sql_monitor.html'
           WHERE statement_id = p_statement_id;

          write_log('"sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_sql_monitor.html" was uploaded to repository');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('sql_monitor_report.html:'||SQLERRM);
      END;

      BEGIN
        IF text_rec.file_text IS NOT NULL AND
           SYS.DBMS_LOB.GETLENGTH(text_rec.file_text) > 1e2 -- not empty
        THEN
          sqlt$a.set_file (
            p_statement_id => p_statement_id,
            p_file_type    => 'SQL_MONITOR_TEXT',
            p_filename     => 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sql_monitor.txt',
            p_statid       => sql_rec.statid,
            p_file_size    => SYS.DBMS_LOB.GETLENGTH(text_rec.file_text),
            p_file_text    => text_rec.file_text );

          UPDATE sqlt$_sql_statement
             SET file_mon_report_text = 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sql_monitor.txt'
           WHERE statement_id = p_statement_id;

          write_log('"sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_sql_monitor.txt" was uploaded to repository');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error('sql_monitor_report.text:'||SQLERRM);
      END;
    END IF;

    COMMIT;
    write_log('<- sql_monitor_reports');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sql_monitor_reports:'||SQLERRM);
  END sql_monitor_reports;

  /*************************************************************************************/

  /* -------------------------
   *
   * public sql_detail_report
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE sql_detail_report (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    active_rec sqli$_file%ROWTYPE;
    l_sql VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);
    l_start_time DATE := NULL;
    l_duration NUMBER := NULL;
    l_report_level VARCHAR2(32767) := 'ALL';
    l_type VARCHAR2(32767) := 'ACTIVE';

  BEGIN
    write_log('-> sql_detail_report');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sqlt$a.get_param('sql_monitoring') = 'N' OR sqlt$a.get_param('sql_tuning_advisor') = 'N' THEN
      write_log('skip "sql_detail_report" as per "sql_monitoring" or "sql_tuning_advisor" parameters');
    ELSIF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip "sql_detail_report" for this method');
    ELSIF sql_rec.rdbms_version < '11.2' THEN
      write_log('skip "sql_detail_report" since not available in "'||sql_rec.rdbms_version||'"');
    ELSE
      SELECT CAST(MIN(sample_time) AS DATE),
             ((CAST(MAX(sample_time) AS DATE) - CAST(MIN(sample_time) AS DATE)) * 24 * 3600)
        INTO l_start_time, l_duration
        FROM sqlt$_gv$active_session_histor
       WHERE statement_id = p_statement_id
         AND sql_id = sql_rec.sql_id;

      l_start_time := LEAST(NVL(l_start_time, SYSDATE), SYSDATE - 1); -- at least 1 day
      l_duration := GREATEST(NVL(l_duration, 0), 24 * 3600); -- at least 1 day

      IF l_start_time IS NOT NULL AND l_duration > 0 THEN
        write_log('generating report');
        l_sql := 'BEGIN :report := SYS.DBMS_SQLTUNE.REPORT_SQL_DETAIL(sql_id => :sql_id, start_time => :start_time, duration => :duration, report_level => :report_level, type => :type); END;';

        BEGIN
          EXECUTE IMMEDIATE l_sql USING OUT active_rec.file_text, IN sql_rec.sql_id, IN l_start_time, IN l_duration, IN l_report_level, IN l_type;
        EXCEPTION
          WHEN OTHERS THEN
            write_log('skip "sql_detail_report" ACTIVE as per error below');
            write_log('** '||SQLERRM);
            active_rec.file_text := NULL;
        END;

        IF p_out_file_identifier IS NULL THEN
          l_out_file_identifier := NULL;
        ELSE
          l_out_file_identifier := '_'||p_out_file_identifier;
        END IF;

        BEGIN
          IF active_rec.file_text IS NOT NULL AND
             SYS.DBMS_LOB.GETLENGTH(active_rec.file_text) > 1e2 -- not empty
          THEN
            sqlt$a.set_file (
              p_statement_id => p_statement_id,
              p_file_type    => 'SQL_DETAIL_ACTIVE',
              p_filename     => 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sql_detail_active.html',
              p_statid       => sql_rec.statid,
              p_file_size    => SYS.DBMS_LOB.GETLENGTH(active_rec.file_text),
              p_file_text    => active_rec.file_text );

            UPDATE sqlt$_sql_statement
               SET file_sql_detail_active = 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sql_detail_active.html'
             WHERE statement_id = p_statement_id;

            write_log('"sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_sql_detail_active.html" was uploaded to repository');
          ELSE
            write_log('skip "sql_detail_report" since it is empty');
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('sql_detail_report.active:'||SQLERRM);
        END;
      ELSE
        write_log('start_time is null or duration is zero');
      END IF;
    END IF;

    COMMIT;
    write_log('<- sql_detail_report');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sql_detail_report:'||SQLERRM);
  END sql_detail_report;

  /*************************************************************************************/

  /* -------------------------
   *
   * public test_case_script
   *
   * called by: sqlt$i.xtract and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE test_case_script (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL,
    p_include_hint_id     IN BOOLEAN  DEFAULT TRUE )
  IS
    l_name VARCHAR2(32767);
    l_name2 VARCHAR2(32767);
    l_type VARCHAR2(32767);
    l_value VARCHAR2(32767);
    l_date BOOLEAN := FALSE;
    l_found BOOLEAN := FALSE;
    l_pos NUMBER;
    l_alter VARCHAR2(32767);
    l_scope VARCHAR2(32767);
    l_count NUMBER;
    l_binds_1 CLOB;
    l_binds_2 CLOB;
    sql_rec sqlt$_sql_statement%ROWTYPE;
    par_rec sqlt$_gv$parameter_cbo%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

    /* -------------------------
     *
     * private test_case_script.wa - write append
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

    /* -------------------------
     *
     * private test_case_script.append
     *
     * ------------------------- */
    PROCEDURE append (p_clob IN CLOB)
    IS
    BEGIN
      IF p_clob IS NOT NULL THEN
        IF SYS.DBMS_LOB.GETLENGTH(p_clob) > 0 THEN
          SYS.DBMS_LOB.APPEND (
            dest_lob => s_file_rec.file_text,
            src_lob  => p_clob );
        END IF;
      END IF;
    END append;

  BEGIN
    write_log('-> test_case_script');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    --IF sql_rec.method <> 'XTRACT' THEN
    --  write_log('method "'||sql_rec.method||'" does not require this script');
    --  write_log('<- test_case_script');
    --  RETURN;
    --END IF;

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_tc_script.sql';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_tc_script.sql';
    END IF;

    SYS.DBMS_LOB.CREATETEMPORARY(l_binds_1, TRUE);
    SYS.DBMS_LOB.CREATETEMPORARY(l_binds_2, TRUE);

    /* -------------------------
     * Header
     * ------------------------- */
    write_log('Header');
    s_file_rec.file_text := 'REM $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $'||LF;

    /* -------------------------
     * ALTER SESSION/SYSTEM
     * ------------------------- */
    write_log('ALTER SESSION/SYSTEM');
-- 170914 to prevent xtrxec to fail
	wa('WHENEVER SQLERROR CONTINUE;'||LF);
    l_count := 0;
    FOR i IN (SELECT DISTINCT name
                FROM sqlt$_gv$sql_optimizer_env
               WHERE statement_id = p_statement_id
                 AND name IS NOT NULL
                 AND plan_hash_value = sql_rec.worst_plan_hash_value
               ORDER BY
                     CASE WHEN LOWER(name) = 'optimizer_features_enable' THEN 1 ELSE 2 END,
                     name)
    LOOP
      FOR j IN (SELECT *
                  FROM sqlt$_gv$sql_optimizer_env
                 WHERE statement_id = p_statement_id
                   AND name IS NOT NULL
                   AND plan_hash_value = sql_rec.worst_plan_hash_value
                   AND name = i.name
                 ORDER BY
                       child_number)
      LOOP
        l_count := l_count + 1;
        par_rec := sqlt$a.get_sqlt$_gv$parameter_cbo(p_statement_id, j.name);

        IF l_count = 1 THEN
 --         wa('WHENEVER SQLERROR CONTINUE;'||LF);

          IF sql_rec.apps_release LIKE '11%' THEN
            wa('--PRO Review and set multi-org for '||sql_rec.apps_release);
            wa('--PRO Enter valid Org ID (number).');
            wa('--EXEC dbms_application_info.set_client_info('''||AMP2||'org_id.'');'||LF);
          ELSIF sql_rec.apps_release LIKE '12%' THEN
            wa('--PRO Review and set multi-org for '||sql_rec.apps_release);
            wa('--PRO Enter valid Application Short Name (2 letters) and Org ID (number).');
            wa('--EXEC mo_global.init(UPPER('''||AMP2||'appl_short_name.''));');
            wa('--EXEC mo_global.set_policy_context(''S'', '||AMP2||'org_id.);'||LF);
          END IF;

          wa('-- These are the non-default or modified CBO parameters on source system.');
          wa('-- ALTER SYSTEM commands can be un-commented out on a test environment.');

          IF LOWER(i.name) <> 'optimizer_features_enable' THEN
            wa('ALTER SESSION SET optimizer_features_enable = '''||sql_rec.optimizer_features_enable||''';');
          END IF;
        END IF;

        IF par_rec.isses_modifiable = 'TRUE' THEN
          l_alter := 'ALTER SESSION SET ';
          l_scope := NULL;
          IF LOWER(j.name) LIKE '_smm_%' AND SUBSTR(j.name, 1, 1) = CHR(95) THEN
            l_alter := '-- '||l_alter;
          END IF;
        ELSIF par_rec.issys_modifiable IN ('DEFERRED', 'IMMEDIATE') THEN
          l_alter := '--ALTER SYSTEM SET ';
          l_scope := ' SCOPE=MEMORY';
        ELSE
          l_alter := NULL;
          l_scope := NULL;
        END IF;

        IF l_alter IS NULL THEN
          l_alter := '-- skip "'||j.name||'" since it is not a real parameter.';
        ELSE
          IF SUBSTR(j.name, 1, 1) = CHR(95) THEN -- "_"
            l_alter := l_alter||'"'||j.name||'" = ';
          ELSE
            l_alter := l_alter||j.name||' = ';
          END IF;

          IF par_rec.type = 2 THEN -- String
            l_alter := l_alter||''''||UPPER(j.value)||'''';
          ELSE
            l_alter := l_alter||UPPER(j.value);
          END IF;
        END IF;

        wa(l_alter||l_scope||';');

        EXIT; -- 1st
      END LOOP;
    END LOOP;
    --IF l_count > 0 THEN
 -- 170914
      wa(LF||'WHENEVER SQLERROR EXIT SQL.SQLCODE;'||LF);
    --END IF;

    /* -------------------------
     * Binds (no dup)
     * ------------------------- */
    write_log('Binds (no dup)');
    l_name := NULL;
    FOR i IN (SELECT name
                FROM sqlt$_peeked_binds
               WHERE statement_id = p_statement_id
                 AND name IS NOT NULL
                 AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN')
                 AND plan_hash_value > 0
                 AND dup_position IS NULL
               UNION
              SELECT name
                FROM sqlt$_gv$sql_bind_capture
               WHERE statement_id = p_statement_id
                 AND name IS NOT NULL
                 AND plan_hash_value > 0
                 AND dup_position IS NULL
               UNION
              SELECT name
                FROM sqlt$_dba_hist_sqlbind
               WHERE statement_id = p_statement_id
                 AND name IS NOT NULL
                 AND plan_hash_value > 0
                 AND dup_position IS NULL
               ORDER BY 1)
    LOOP
      l_name := i.name;
      l_type := NULL;
      l_value := NULL;
      l_found := FALSE;

      IF NOT l_found THEN
        FOR j IN (SELECT *
                    FROM sqlt$_peeked_binds
                   WHERE statement_id = p_statement_id
                     AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN')
                     AND plan_hash_value > 0
                     AND dup_position IS NULL
                     AND name = i.name
                   ORDER BY
                         CASE WHEN plan_hash_value = sql_rec.worst_plan_hash_value THEN 1 ELSE 2 END, -- tries to reproduce bad plan
                         CASE WHEN source = 'GV$SQL_PLAN' THEN 1 ELSE 2 END, -- memory has priority over awr (more recent)
                         plan_timestamp DESC, -- more recent is better
                         inst_id, -- no particular reason
                         child_number, -- no particular reason
                         position)
        LOOP
          BEGIN
            IF l_type IS NULL THEN
              l_type := j.datatype_string;
            END IF;

            --IF l_value IS NULL THEN
              IF j.value_string_date IS NOT NULL THEN
                l_value := j.value_string_date;
                l_date := TRUE;
              ELSE
                l_value := j.value_string;
              END IF;
            --END IF;

            write_log('sqlt$_peeked_binds bind name="'||j.name||'" type="'||j.datatype_string||'" value="'||j.value_string||'" plan_hash_value="'||j.plan_hash_value||'" source="'||j.source||'" plan_timestamp="'||j.plan_timestamp||'" inst_id="'||j.inst_id||'" child_number="'||j.child_number||'"');
            l_found := TRUE;
            EXIT; -- 1st
          EXCEPTION
            WHEN OTHERS THEN
              write_log('cannot assembly peeked bind name="'||j.name||'" type="'||j.datatype_string||'" value="'||j.value_string||'"');
              write_log('** '||SQLERRM);
              EXIT; -- 1st
          END;
        END LOOP;
      END IF;

      IF NOT l_found THEN
        FOR j IN (SELECT *
                    FROM sqlt$_gv$sql_bind_capture
                   WHERE statement_id = p_statement_id
                     AND plan_hash_value > 0
                     AND dup_position IS NULL
                     AND name = i.name
                   ORDER BY
                         CASE WHEN plan_hash_value = sql_rec.worst_plan_hash_value THEN 1 ELSE 2 END, -- tries to reproduce bad plan
                         inst_id, -- no particular reason
                         child_number, -- no particular reason
                         position)
        LOOP
          BEGIN
            IF l_type IS NULL THEN
              l_type := j.datatype_string;
            END IF;

            --IF l_value IS NULL THEN
              IF j.value_string_date IS NOT NULL THEN
                l_value := j.value_string_date;
                l_date := TRUE;
              ELSE
                l_value := j.value_string;
              END IF;
            --END IF;

            write_log('sqlt$_gv$sql_bind_capture bind name="'||j.name||'" type="'||j.datatype_string||'" value="'||j.value_string||'" plan_hash_value="'||j.plan_hash_value||'" inst_id="'||j.inst_id||'" child_number="'||j.child_number||'"');
            l_found := TRUE;
            EXIT; -- 1st
          EXCEPTION
            WHEN OTHERS THEN
              write_log('cannot assembly captured bind name="'||j.name||'" type="'||j.datatype_string||'" value="'||j.value_string||'"');
              write_log('** '||SQLERRM);
              EXIT; -- 1st
          END;
        END LOOP;
      END IF;

      IF NOT l_found THEN
        FOR j IN (SELECT *
                    FROM sqlt$_dba_hist_sqlbind
                   WHERE statement_id = p_statement_id
                     AND plan_hash_value > 0
                     AND dup_position IS NULL
                     AND name = i.name
                   ORDER BY
                         CASE WHEN plan_hash_value = sql_rec.worst_plan_hash_value THEN 1 ELSE 2 END, -- tries to reproduce bad plan
                         instance_number, -- no particular reason
                         position)
        LOOP
          BEGIN
            IF l_type IS NULL THEN
              l_type := j.datatype_string;
            END IF;

            --IF l_value IS NULL THEN
              IF j.value_string_date IS NOT NULL THEN
                l_value := j.value_string_date;
                l_date := TRUE;
              ELSIF j.value_anydata IS NULL THEN
                l_value := NULL;
              ELSE
                l_value := j.value_string;
              END IF;
            --END IF;

            write_log('sqlt$_dba_hist_sqlbind bind name="'||j.name||'" type="'||j.datatype_string||'" value="'||j.value_string||'" plan_hash_value="'||j.plan_hash_value||'" instance_number="'||j.instance_number||'"');
            l_found := TRUE;
            EXIT; -- 1st
          EXCEPTION
            WHEN OTHERS THEN
              write_log('cannot assembly captured bind name="'||j.name||'" type="'||j.datatype_string||'" value="'||j.value_string||'"');
              write_log('** '||SQLERRM);
              EXIT; -- 1st
          END;
        END LOOP;
      END IF;

      IF l_name IS NOT NULL AND
         l_type IS NOT NULL
      THEN
        IF l_type = 'DATE' OR
           l_type LIKE 'TIMESTAMP%'
        THEN
          l_type := 'VARCHAR2(32)';
        ELSIF l_type LIKE 'RAW(%' THEN
          l_type := REPLACE(l_type, 'RAW(', 'VARCHAR2(');
        END IF;

        IF l_type LIKE '%CHAR%' OR
           l_type LIKE '%LOB'
        THEN
          l_value := ''''||l_value||'''';
        ELSIF l_value IS NULL THEN
          l_value := 'TO_NUMBER(NULL)';
        END IF;

        IF SUBSTR(l_name, 2, 1) BETWEEN '0' AND '9' THEN -- :1
          sql_rec.sql_text_clob_stripped := REPLACE(sql_rec.sql_text_clob_stripped, l_name, ':b'||SUBSTR(l_name, 2));
          l_name := ':b'||SUBSTR(l_name, 2);
        END IF;

        l_binds_1 := l_binds_1||'VAR   '||RPAD(SUBSTR(l_name, 2), 32)||l_type||';'||LF;
        l_binds_2 := l_binds_2||'EXEC '||RPAD(l_name, 32)||' := '||l_value||';'||LF;
      END IF;
    END LOOP;

    /* -------------------------
     * Binds (dup)
     * ------------------------- */
    write_log('Binds (dup)');
    FOR i IN (SELECT name, dup_position
                FROM sqlt$_peeked_binds
               WHERE statement_id = p_statement_id
                 AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN')
                 AND plan_hash_value > 0
                 AND dup_position IS NOT NULL
               UNION
              SELECT name, dup_position
                FROM sqlt$_gv$sql_bind_capture
               WHERE statement_id = p_statement_id
                 AND plan_hash_value > 0
                 AND dup_position IS NOT NULL
               UNION
              SELECT name, dup_position
                FROM sqlt$_dba_hist_sqlbind
               WHERE statement_id = p_statement_id
                 AND plan_hash_value > 0
                 AND dup_position IS NOT NULL
               ORDER BY 1)
    LOOP
      l_name := i.name;
      l_type := NULL;
      l_name2 := NULL;

      IF l_name2 IS NULL THEN
        FOR j IN (SELECT *
                    FROM sqlt$_peeked_binds
                   WHERE statement_id = p_statement_id
                     AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN')
                     AND plan_hash_value > 0
                     AND dup_position IS NULL
                     AND position = i.dup_position
                     AND name <> i.name
                   ORDER BY
                         CASE WHEN plan_hash_value = sql_rec.worst_plan_hash_value THEN 1 ELSE 2 END,
                         CASE WHEN source = 'GV$SQL_PLAN' THEN 1 ELSE 2 END,
                         plan_timestamp DESC,
                         inst_id,
                         child_number)
        LOOP
          IF l_type IS NULL THEN
            l_type := j.datatype_string;
          END IF;

          IF l_name2 IS NULL THEN
            l_name2 := j.name;
          END IF;

          write_log('sqlt$_peeked_binds bind name="'||j.name||'" type="'||j.datatype_string||'" value="'||j.value_string||'" plan_hash_value="'||j.plan_hash_value||'" source="'||j.source||'" plan_timestamp="'||j.plan_timestamp||'" inst_id="'||j.inst_id||'" child_number="'||j.child_number||'"');
          EXIT; -- 1st
        END LOOP;
      END IF;

      IF l_name2 IS NULL THEN
        FOR j IN (SELECT *
                    FROM sqlt$_gv$sql_bind_capture
                   WHERE statement_id = p_statement_id
                     AND plan_hash_value > 0
                     AND dup_position IS NULL
                     AND position = i.dup_position
                     AND name <> i.name
                   ORDER BY
                         CASE WHEN plan_hash_value = sql_rec.worst_plan_hash_value THEN 1 ELSE 2 END, -- tries to reproduce bad plan
                         inst_id, -- no particular reason
                         child_number) -- no particular reason
        LOOP
          IF l_type IS NULL THEN
            l_type := j.datatype_string;
          END IF;

          IF l_name2 IS NULL THEN
            l_name2 := j.name;
          END IF;

          write_log('sqlt$_gv$sql_bind_capture bind name="'||j.name||'" type="'||j.datatype_string||'" value="'||j.value_string||'" plan_hash_value="'||j.plan_hash_value||'" inst_id="'||j.inst_id||'" child_number="'||j.child_number||'"');
          EXIT; -- 1st
        END LOOP;
      END IF;

      IF l_name2 IS NULL THEN
        FOR j IN (SELECT *
                    FROM sqlt$_dba_hist_sqlbind
                   WHERE statement_id = p_statement_id
                     AND plan_hash_value > 0
                     AND dup_position IS NULL
                     AND position = i.dup_position
                     AND name <> i.name
                   ORDER BY
                         CASE WHEN plan_hash_value = sql_rec.worst_plan_hash_value THEN 1 ELSE 2 END, -- tries to reproduce bad plan
                         instance_number) -- no particular reason
        LOOP
          IF l_type IS NULL THEN
            l_type := j.datatype_string;
          END IF;

          IF l_name2 IS NULL THEN
            l_name2 := j.name;
          END IF;

          write_log('sqlt$_dba_hist_sqlbind bind name="'||j.name||'" type="'||j.datatype_string||'" value="'||j.value_string||'" plan_hash_value="'||j.plan_hash_value||'" instance_number="'||j.instance_number||'"');
          EXIT; -- 1st
        END LOOP;
      END IF;

      IF l_name IS NOT NULL AND
         l_name2 IS NOT NULL AND
         l_type IS NOT NULL
      THEN
        IF l_type = 'DATE' OR
           l_type LIKE 'TIMESTAMP%'
        THEN
          l_type := 'VARCHAR2(32)';
        ELSIF l_type LIKE 'RAW(%' THEN
          l_type := REPLACE(l_type, 'RAW(', 'VARCHAR2(');
        END IF;

        IF l_type LIKE '%CHAR%' OR
           l_type LIKE '%LOB'
        THEN
          l_value := ''''||l_value||'''';
        ELSIF l_value IS NULL THEN
          l_value := 'TO_NUMBER(NULL)';
        END IF;

        IF SUBSTR(l_name2, 2, 1) BETWEEN '0' AND '9' THEN -- :1
          sql_rec.sql_text_clob_stripped := REPLACE(sql_rec.sql_text_clob_stripped, l_name2, ':b'||SUBSTR(l_name2, 2));
          l_name2 := ':b'||SUBSTR(l_name2, 2);
        END IF;

        IF SUBSTR(l_name, 2, 1) BETWEEN '0' AND '9' THEN -- :1
          l_name := ':b'||SUBSTR(l_name, 2);
        END IF;

        l_binds_1 := l_binds_1||'VAR   '||RPAD(SUBSTR(l_name2, 2), 32)||l_type||';'||LF;
        l_binds_2 := l_binds_2||'EXEC '||RPAD(l_name2, 32)||' := '||l_name||';'||LF;
      END IF;
    END LOOP;

    /* -------------------------
     * Body
     * ------------------------- */
    write_log('Body');

    IF NVL(DBMS_LOB.GETLENGTH(l_binds_1), 0) > 0 THEN
      append(LF||l_binds_1);
    END IF;
    SYS.DBMS_LOB.FREETEMPORARY(l_binds_1);

    IF NVL(DBMS_LOB.GETLENGTH(l_binds_2), 0) > 0 THEN
      append(l_binds_2);
    END IF;
    SYS.DBMS_LOB.FREETEMPORARY(l_binds_2);

    IF l_date THEN
      wa('ALTER SESSION SET NLS_DATE_FORMAT = '''||LOAD_DATE_FORMAT||''';');
    END IF;

    sql_rec.sql_text_clob_stripped := TRIM(' ' FROM sql_rec.sql_text_clob_stripped);

    -- inject unique_id after hints or first space
    IF p_include_hint_id THEN
      l_pos := INSTR(sql_rec.sql_text_clob_stripped, '*/');
      IF l_pos > 1 THEN
        sql_rec.sql_text_clob_stripped :=
        SUBSTR(sql_rec.sql_text_clob_stripped, 1, l_pos + 1)||
        ' /* '||CARET||CARET||'unique_id */ '||
        SUBSTR(sql_rec.sql_text_clob_stripped, l_pos + 2);
      ELSE
        l_pos := INSTR(sql_rec.sql_text_clob_stripped, ' ');
        IF l_pos > 1 THEN
          sql_rec.sql_text_clob_stripped :=
          SUBSTR(sql_rec.sql_text_clob_stripped, 1, l_pos - 1)||
          ' /* '||CARET||CARET||'unique_id */ '||
          SUBSTR(sql_rec.sql_text_clob_stripped, l_pos + 1);
        END IF;
      END IF;
    END IF;

    wa(LF);
    append(wrap_clob(sql_rec.sql_text_clob_stripped||';', 2000)); -- was 120

    /* -------------------------
     * Closure
     * ------------------------- */
    write_log('Closure');
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'TEST_CASE_SCRIPT',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_sqlt_tcscript = s_file_rec.filename
     WHERE statement_id = p_statement_id;

    --IF sql_rec.method = 'XTRACT' THEN
      s_file_rec.filename := 'q.sql';
      sqlt$a.set_file (
        p_statement_id  => p_statement_id,
        p_file_type     => 'Q',
        p_filename      => s_file_rec.filename,
        p_statement_id2 => p_group_id,
        p_db_link       => p_db_link,
        p_file_size     => s_file_rec.file_size,
        p_file_text     => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_tc_q = s_file_rec.filename
       WHERE statement_id = p_statement_id;
    --END IF;

    COMMIT;

    write_log('<- test_case_script');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('test_case_script:'||SQLERRM);
  END test_case_script;

  /*************************************************************************************/

  /* -------------------------
   *
   * public test_case_sql
   *
   * called by: sqlt$i.xtract and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE test_case_sql (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> test_case_sql');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    --IF sql_rec.method <> 'XTRACT' THEN
    --  write_log('method "'||sql_rec.method||'" does not require this sql');
    --  write_log('<- test_case_sql');
    --  RETURN;
    --END IF;

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_tc_sql.sql';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_tc_sql.sql';
    END IF;

    s_file_rec.file_text := wrap_clob(TRIM(' ' FROM sql_rec.sql_text_clob_stripped)||';', 2000); -- was 120
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'TEST_CASE_SQL',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_sqlt_tcsql = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- test_case_sql');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('test_case_sql:'||SQLERRM);
  END test_case_sql;

  /*************************************************************************************/

  /* -------------------------
   *
   * public plan
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE plan (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> plan');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    s_file_rec.filename := 'plan.sql';
    s_file_rec.file_text :=
'REM Displays plan for most recently executed SQL. Just execute "'||ARROBA||s_file_rec.filename||'" from sqlplus.
SET PAGES 2000 LIN 180;
SPO plan.log;
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR);
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL,NULL,''BASIC ROWS COST PREDICATE''));
SPO OFF;';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'PLAN',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_plan = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- plan');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('plan:'||SQLERRM);
  END plan;

  /*************************************************************************************/

  /* -------------------------
   *
   * public s10053
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE s10053 (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> s10053');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    s_file_rec.filename := '10053.sql';
    s_file_rec.file_text :=
'REM Open CBO trace. Just execute "'||ARROBA||s_file_rec.filename||'" from sqlplus.
ALTER SESSION SET TRACEFILE_IDENTIFIER = ''10053_s'||p_statement_id||''';
ALTER SESSION SET EVENTS ''10053 TRACE NAME CONTEXT FOREVER, LEVEL 1'';';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => '10053',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_10053 = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- s10053');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('s10053:'||SQLERRM);
  END s10053;

  /*************************************************************************************/

  /* -------------------------
   *
   * public flush
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE flush (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> flush');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    s_file_rec.filename := 'flush.sql';
    s_file_rec.file_text :=
'REM Flushes the shared pool. Just execute "'||ARROBA||s_file_rec.filename||'" from sqlplus.
ALTER SYSTEM FLUSH SHARED_POOL;';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'FLUSH',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_flush = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- flush');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('flush:'||SQLERRM);
  END flush;

  /*************************************************************************************/

  /* -------------------------
   *
   * public purge
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE purge (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> purge');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_purge.sql';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_purge.sql';
    END IF;

    s_file_rec.file_text :=
'REM Purges statement_id '||p_statement_id||' from local SQLT repository. Just execute "'||ARROBA||s_file_rec.filename||'" from sqlplus.
SPO sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_purge.log;
SET SERVEROUT ON;
EXEC &&tool_administer_schema..sqlt$a.purge_repository('||p_statement_id||', '||p_statement_id||');
SET SERVEROUT OFF;
SPO OFF;';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'PURGE',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_purge = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- purge');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('purge:'||SQLERRM);
  END purge;

  /*************************************************************************************/

  /* -------------------------
   *
   * public restore
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE restore (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> restore');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_restore.sql';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_restore.sql';
    END IF;

    s_file_rec.file_text :=
'REM Restores schema object stats for statement_id '||p_statement_id||' from local SQLT repository into data dictionary. Just execute "'||ARROBA||s_file_rec.filename||'" from sqlplus.
SPO sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_restore.log;
SET SERVEROUT ON;
TRUNCATE TABLE '||TOOL_REPOSITORY_SCHEMA||'.SQLI$_STATTAB_TEMP;
ALTER SESSION SET optimizer_dynamic_sampling = 0;
-- 170909
-- ALTER SESSION SET EVENTS ''10046 TRACE NAME CONTEXT FOREVER, LEVEL 12'';
-- if you need to upload stats history so you can use SQLT XHUME you need to pass p_load_hist=>''Y''
-- Use p_schema_owner =>''NULL'' for multi-schema stats import.
EXEC &&tool_administer_schema..sqlt$a.import_cbo_stats(p_statement_id => ''s'||sqlt$a.get_statement_id_c(p_statement_id)||''', p_schema_owner => '''||AMP2||'tc_user.'', p_include_bk => ''N'', p_make_bk => ''N'', p_load_hist => ''N'');
ALTER SESSION SET SQL_TRACE = FALSE;
ALTER SESSION SET optimizer_dynamic_sampling = 2;
SET SERVEROUT OFF;
SPO OFF;';

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'RESTORE',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_restore = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- restore');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('restore:'||SQLERRM);
  END restore;

  /*************************************************************************************/

  /* -------------------------
   *
   * public del_hgrm
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE del_hgrm (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> del_hgrm');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_del_hgrm.sql';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_del_hgrm.sql';
    END IF;

    s_file_rec.file_text :=
'REM Deletes CBO histograms from data dictionary for TC schema. Just execute "'||ARROBA||s_file_rec.filename||'" from sqlplus.
SPO sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_del_hgrm.log;
SET SERVEROUT ON;
EXEC &&tool_administer_schema..sqlt$s.delete_schema_hgrm('''||AMP2||'tc_user.'',TRUE,TRUE);
SET SERVEROUT OFF;
SPO OFF;';

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'DEL_HGRM',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_del_hgrm = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- del_hgrm');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('del_hgrm:'||SQLERRM);
  END del_hgrm;

  /*************************************************************************************/

  /* -------------------------
   *
   * public tc_sql
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE tc_sql (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> tc_sql');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    s_file_rec.filename := 'tc.sql';
    s_file_rec.file_text :=
'REM Executes SQL on TC then produces execution plan. Just execute "'||ARROBA||s_file_rec.filename||'" from sqlplus.
SET APPI OFF SERVEROUT OFF;
'||ARROBA2||'q.sql
'||ARROBA2||'plan.sql';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'TC_SQL',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_sql = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- tc_sql');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tc_sql:'||SQLERRM);
  END tc_sql;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xpress_sh
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE xpress_sh (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> xpress_sh');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    s_file_rec.filename := 'xpress.sh';
    s_file_rec.file_text :=
'# Implements SQLT Test Case (Express Mode).'||LF||
'# Just execute ". '||s_file_rec.filename||'" from OS.
sqlplus / as sysdba '||ARROBA||'xpress.sql';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'XPRESS_SH',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_sh = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- xpress_sh');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('xpress_sh:'||SQLERRM);
  END xpress_sh;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xpress_sql
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE xpress_sql (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> xpress_sql');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    s_file_rec.filename := 'xpress.sql';

    s_file_rec.file_text :=
'REM Implements SQLT Test Case (Express Mode).
REM Just execute "./xpress.sh" or "sqlplus / as sysdba '||ARROBA||s_file_rec.filename||'" from OS.
SET ECHO OFF;
CL SCR
PAU 1/7 Press ENTER to create TC user and schema objects for statement_id '||p_statement_id||'.
SET ECHO ON;
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_metadata.sql
SET ECHO OFF;
PRO
PAU 2/7 Press ENTER to purge statement_id '||p_statement_id||' from SQLT repository.
SET ECHO ON;
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_purge.sql
SET ECHO OFF;
PRO
PAU 3/7 Press ENTER to import SQLT repository for statement_id '||p_statement_id||'.
SET ECHO ON;
HOS imp &&tool_repository_schema. FILE=sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_exp.dmp LOG=sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_imp.log TABLES=sqlt% IGNORE=Y
SET ECHO OFF;
PRO
PAU 4/7 Press ENTER to restore schema object stats for '||AMP2||'tc_user..
SET ECHO ON;
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_restore.sql
SET ECHO OFF;
PRO
PAU 5/7 Press ENTER to restore system statistics.
SET ECHO ON;
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_system_stats.sql
SET ECHO OFF;
PRO
PAU 6/7 Press ENTER to connect as '||AMP2||'tc_user. and set CBO env.
SET ECHO ON;
CONN '||AMP2||'tc_user./'||AMP2||'tc_user.
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_set_cbo_env.sql
SET ECHO OFF;
PRO
PAU 7/7 Press ENTER to execute test case.
SET ECHO ON;
'||ARROBA2||'tc.sql';

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'XPRESS_SQL',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_sqltc = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- xpress_sql');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('xpress_sql:'||SQLERRM);
  END xpress_sql;

  /*************************************************************************************/

  /* -------------------------
   *
   * public install_sh
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE install_sh (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> install_sh');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    s_file_rec.filename := 'install.sh';
    s_file_rec.file_text :=
'# Implements SQLT TCX (Test Case eXpress).'||LF||
'# Just execute ". '||s_file_rec.filename||'" from OS.
sqlplus / as sysdba '||ARROBA||'install.sql';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'INSTALL_SH',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tcx_install_sh = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- install_sh');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('install_sh:'||SQLERRM);
  END install_sh;

  /*************************************************************************************/

  /* -------------------------
   *
   * public install_sql
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE install_sql (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> install_sql');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    s_file_rec.filename := 'install.sql';

    s_file_rec.file_text :=
'REM Implements SQLT TCX (Test Case eXpress).
REM Just execute "./install.sh" or "sqlplus / as sysdba '||ARROBA||s_file_rec.filename||'" from OS.
SET ECHO OFF;
CL SCR
PRO Metadata1: types, tables, indexes, contraints.
PAU 1/6 Press ENTER to create TC user and base schema objects.
SET ECHO ON;
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_metadata1.sql
SET ECHO OFF;
PRO
PRO Metadata2: types, packages, views, others.
PAU 2/6 Press ENTER to create additional schema objects.
SET ECHO ON;
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_metadata2.sql
SET ECHO OFF;
PRO
PAU 3/6 Press ENTER to import schema object statistics.
SET ECHO ON;
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_schema_stats.sql
SET ECHO OFF;
PRO
PAU 4/6 Press ENTER to restore system statistics.
SET ECHO ON;
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_system_stats.sql
SET ECHO OFF;
PRO
PAU 5/6 Press ENTER to connect as '||AMP2||'tc_user. and set CBO env.
SET ECHO ON;
CONN '||AMP2||'tc_user./'||AMP2||'tc_user.
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_set_cbo_env.sql
SET ECHO OFF;
PRO
PAU 6/6 Press ENTER to execute test case.
SET ECHO ON;
'||ARROBA2||'tc.sql';

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'INSTALL_SQL',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tcx_install_sql = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- install_sql');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('install_sql:'||SQLERRM);
  END install_sql;

  /*************************************************************************************/

  /* -------------------------
   *
   * public setup
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE setup (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> setup');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    s_file_rec.filename := 'setup.sql';
    s_file_rec.file_text :=
ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_system_stats.sql
DEF TC_USER_SUFFIX = "";
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_metadata.sql
HOS imp TC'||sqlt$a.get_statement_id_c(p_statement_id)||'/TC'||sqlt$a.get_statement_id_c(p_statement_id)||' FILE=cbo_stat_tab_4tc.dmp LOG=cbo_stat_tab_4tc.log TABLES=cbo_stat_tab_4tc IGNORE=Y
CONN TC'||sqlt$a.get_statement_id_c(p_statement_id)||'/TC'||sqlt$a.get_statement_id_c(p_statement_id)||'
REM Ignore errors by UPGRADE_STAT_TABLE api call below:
EXEC SYS.DBMS_STATS.UPGRADE_STAT_TABLE(USER,''CBO_STAT_TAB_4TC'');
EXEC SYS.DBMS_STATS.IMPORT_SCHEMA_STATS(USER,''CBO_STAT_TAB_4TC'');
'||ARROBA2||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_set_cbo_env.sql
'||ARROBA2||'tc.sql';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'SETUP',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_setup = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- setup');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('setup:'||SQLERRM);
  END setup;

  /*************************************************************************************/

  /* -------------------------
   *
   * public readme
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE readme (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> readme');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    s_file_rec.filename := 'readme.txt';
    s_file_rec.file_text := 'connect as sys and execute setup.sql';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'README',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_readme = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- readme');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('readme:'||SQLERRM);
  END readme;

  /*************************************************************************************/

  /* -------------------------
   *
   * public tc_pkg
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE tc_pkg (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    l_statement_id VARCHAR2(32767);
    l_prefix VARCHAR2(32767);
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> tc_pkg');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_group_id IS NULL THEN
      l_statement_id := sqlt$a.get_statement_id_c(p_statement_id);
      l_prefix := 'sqlt_s'||l_statement_id||l_out_file_identifier;
    ELSE
      l_statement_id := sqlt$a.get_statement_id_c(p_statement_id);
      l_prefix := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier;
    END IF;

    s_file_rec.filename := 'tc_pkg.sql';
    s_file_rec.file_text :=
'SPO tc_pkg.log
SET ECHO OFF
REM
REM export schema stats in case we changed them during tc.
DELETE TC'||l_statement_id||'.CBO_STAT_TAB_4TC;
EXEC SYS.DBMS_STATS.EXPORT_SCHEMA_STATS(ownname => ''TC'||l_statement_id||''', stattab => ''CBO_STAT_TAB_4TC'', statown => ''TC'||l_statement_id||''');
REM
REM export schema objects for tc.
HOS exp TC'||l_statement_id||'/TC'||l_statement_id||' FILE=cbo_stat_tab_4tc.dmp LOG=cbo_stat_tab_4tc.log TABLES=cbo_stat_tab_4tc STATISTICS=NONE
REM
REM creates zip with tc files.
HOS zip tc cbo_stat_tab_4tc.dmp
HOS zip tc '||l_prefix||'_metadata.sql
HOS zip tc '||l_prefix||'_opatch.zip
HOS zip tc '||l_prefix||'_system_stats.sql tc.sql
HOS zip tc '||l_prefix||'_set_cbo_env.sql
HOS zip tc q.sql
HOS zip tc plan.sql
HOS zip tc tc.sql
HOS zip tc 10053.sql
HOS zip tc flush.sql
HOS zip tc setup.sql
HOS zip tc readme.txt
REM
REM creates tc directory (for your review).
HOS unzip tc.zip -d tc
REM
PRO tc directory and zip have been created.
PRO review, adjust and test them on another system.
SPO OFF
';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'TC_PKG',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_pkg = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- tc_pkg');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tc_pkg:'||SQLERRM);
  END tc_pkg;

  /*************************************************************************************/

  /* -------------------------
   *
   * public tcx_pkg
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE tcx_pkg (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    l_statement_id VARCHAR2(32767);
    l_prefix VARCHAR2(32767);
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> tcx_pkg');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_group_id IS NULL THEN
      l_statement_id := sqlt$a.get_statement_id_c(p_statement_id);
      l_prefix := 'sqlt_s'||l_statement_id||l_out_file_identifier;
    ELSE
      l_statement_id := sqlt$a.get_statement_id_c(p_statement_id);
      l_prefix := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier;
    END IF;

    s_file_rec.filename := 'pack_tcx.sql';
    s_file_rec.file_text :=
'SET ECHO OFF
REM
PAU 1/3 Press ENTER to create setup.sql script.
REM create setup.sql script
SPO setup.sql
PRO REM Implements Test Case TC'||l_statement_id||'.
PRO REM Just execute "sqlplus / as sysdba @setup.sql" from OS.
PRO REM
PRO SPO setup.log
PRO SET ECHO ON SERVEROUT OFF
PRO REM
PRO REM create tc user.
PRO GRANT DBA TO TC'||l_statement_id||' IDENTIFIED BY TC'||l_statement_id||';;
PRO REM
PRO REM create cbo stats staging table.
PRO ALTER SESSION SET NLS_LENGTH_SEMANTICS = BYTE;
PRO EXEC SYS.DBMS_STATS.CREATE_STAT_TABLE(ownname => ''TC'||l_statement_id||''', stattab => ''SQLT$_STATTAB'');;
PRO DROP INDEX TC'||l_statement_id||'.SQLT$_STATTAB;;
PRO REM
PRO REM delete in case we execute this script more than once.
PRO DELETE TC'||l_statement_id||'.sqlt$_stattab;;
PRO REM
PRO REM import schema objects including cbo stats.
PRO HOS imp TC'||l_statement_id||'/TC'||l_statement_id||' FILE=TC'||l_statement_id||'_expdat.dmp LOG=TC'||l_statement_id||'_import.log FULL=Y IGNORE=Y
PRO REM
PRO REM upgrade cbo stats table in case source is prior release.
PRO EXEC SYS.DBMS_STATS.UPGRADE_STAT_TABLE(ownname => ''TC'||l_statement_id||''', stattab => ''SQLT$_STATTAB'');
PRO REM
PRO REM restore schema object stats.
PRO EXEC SYS.DBMS_STATS.IMPORT_SCHEMA_STATS(ownname => ''TC'||l_statement_id||''', stattab => ''SQLT$_STATTAB'');;
PRO REM
PRO REM display table level cbo stats.
PRO SELECT table_name, num_rows FROM sys.dba_tables WHERE owner = ''TC'||l_statement_id||''' AND table_name <> ''SQLT$_STATTAB'' ORDER BY table_name;;
PRO SPO OFF
PRO REM
PRO REM create metadata for views and packages.
PRO @@'||l_prefix||'_metadata2.sql
PRO REM
PRO REM restore system statistics.
PRO @@'||l_prefix||'_system_stats.sql
PRO REM
PRO REM connect as the tc user.
PRO CONN TC'||l_statement_id||'/TC'||l_statement_id||'
PRO REM
PRO REM setup cbo environment.
PRO @@'||l_prefix||'_set_cbo_env.sql
PRO REM
PRO REM execute SQL.
PRO @@q.sql
PRO REM
PRO REM display execution plan.
PRO @@plan.sql
PRO REM
PRO SET ECHO OFF
SPO OFF
REM
PAU 2/3 Press ENTER to create readme.txt file.
REM create readme.txt file
SPO readme.txt
PRO REM connect as sys and execute setup.sql
PRO sqlplus / as sysdba @setup.sql
SPO OFF
HOS chmod 777 readme.txt
REM
PAU 3/3 Press ENTER to package test case into tcx.zip.
SPO pack_tcx.log
REM export schema stats in case we changed them during tc.
DELETE TC'||l_statement_id||'.sqlt$_stattab;
EXEC SYS.DBMS_STATS.EXPORT_SCHEMA_STATS(ownname => ''TC'||l_statement_id||''', stattab => ''SQLT$_STATTAB'');
REM
REM export schema objects for tcx.
HOS exp TC'||l_statement_id||'/TC'||l_statement_id||' FILE=TC'||l_statement_id||'_expdat.dmp LOG=TC'||l_statement_id||'_export.log TABLES=TC'||l_statement_id||'.% STATISTICS=NONE
REM
REM creates zip with tcx files.
HOS zip tcx TC'||l_statement_id||'_expdat.dmp
HOS zip tcx '||l_prefix||'_metadata2.sql
HOS zip tcx '||l_prefix||'_system_stats.sql
HOS zip tcx '||l_prefix||'_set_cbo_env.sql
HOS zip tcx q.sql
HOS zip tcx plan.sql
HOS zip tcx 10053.sql
HOS zip tcx flush.sql
HOS zip -m tcx setup.sql
HOS zip -m tcx readme.txt
REM
REM creates tcx directory (for your review).
HOS unzip tcx.zip -d tcx
REM
PRO tcx directory and zip have been created.
PRO review, adjust and test them on another system.
SPO OFF
';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'TCX_PKG',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tcx_pkg = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- tcx_pkg');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('tcx_pkg:'||SQLERRM);
  END tcx_pkg;

  /*************************************************************************************/

  /* -------------------------
   *
   * public sel
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE sel (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> sel');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    s_file_rec.filename := 'sel.sql';
    s_file_rec.file_text :=
'REM Computes predicate selectivity using CBO. Requires sel_aux.sql.
SPO sel.log;
SET ECHO OFF FEED OFF SHOW OFF VER OFF;
PRO
COL table_rows NEW_V table_rows FOR 999999999999;
COL selectivity FOR 0.000000000000 HEA "Selectivity";
COL e_rows NEW_V e_rows FOR 999999999999 NOPRI;
ACC table PROMPT ''Table Name: '';
SELECT num_rows table_rows FROM user_tables WHERE table_name = UPPER(TRIM('''||AMP2||'table.''));
'||ARROBA2||'sel_aux.sql';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'SEL',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_selectivity = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- sel');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sel:'||SQLERRM);
  END sel;

  /*************************************************************************************/

  /* -------------------------
   *
   * public sel_aux
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE sel_aux (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> sel_aux');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    s_file_rec.filename := 'sel_aux.sql';
    s_file_rec.file_text :=
'REM Computes predicate selectivity using CBO. Requires sel.sql.
PRO
ACC predicate PROMPT ''Predicate for '||AMP2||'table.: '';
DELETE plan_table;
EXPLAIN PLAN FOR SELECT /*+ FULL(t) */ COUNT(*) FROM '||AMP2||'table. t WHERE '||AMP2||'predicate.;
SELECT MAX(cardinality) e_rows FROM plan_table;
SELECT '||AMP2||'e_rows. "Comp Card", ROUND('||AMP2||'e_rows./'||AMP2||'table_rows., 12) selectivity FROM DUAL;
'||ARROBA2||'sel_aux.sql';
    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'SEL_AUX',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_tc_selectivity_aux = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;

    write_log('<- sel_aux');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sel_aux:'||SQLERRM);
  END sel_aux;

  /*************************************************************************************/

  /* -------------------------
   *
   * public process_log
   *
   * called by: sqlt$i.xtract, sqlt$i.remote_xtract, sqlt$i.xecute_end, sqlt$i.xplain_end and sqlt$e.xtract_sql_put_files_in_repo
   *
   * ------------------------- */
  PROCEDURE process_log (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

    /* -------------------------
     *
     * private process_log.wa - write append
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

  BEGIN
    write_log('-> process_log');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_process.log';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_process.log';
    END IF;

    s_file_rec.file_text := 'REM &&tool_repository_schema..sqlt$_log as of '||TO_CHAR(SYSDATE, LOAD_DATE_FORMAT);
    write_log('<- process_log');

    FOR i IN (SELECT time_stamp,
                     line_text
                FROM sqlt$_log
               WHERE statement_id = p_statement_id
                 AND line_type IN ('L', 'E')
               ORDER BY
                     time_stamp,
                     line_id)
    LOOP
      wa(TO_CHAR(i.time_stamp, 'HH24:MI:SS')||' '||i.line_text);
    END LOOP;

    s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);

    sqlt$a.set_file (
      p_statement_id  => p_statement_id,
      p_file_type     => 'PROCESS_LOG',
      p_filename      => s_file_rec.filename,
      p_statement_id2 => p_group_id,
      p_db_link       => p_db_link,
      p_file_size     => s_file_rec.file_size,
      p_file_text     => s_file_rec.file_text );

    UPDATE sqlt$_sql_statement
       SET file_process_log = s_file_rec.filename
     WHERE statement_id = p_statement_id;
    COMMIT;
	-- 150903
	sqlt$a.print_statement_workspace(p_statement_id );
  EXCEPTION
    WHEN OTHERS THEN
      write_error('process_log:'||SQLERRM);
  END process_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * private gather_stats_all
   *
   * ------------------------- */
  FUNCTION gather_stats_all (
    p_statement_id IN NUMBER,
    p_mode         IN INTEGER DEFAULT NULL ) -- 1:no hist, 2:hist, NULL:dont_matter
  RETURN VARCHAR2
  IS
    my_rows NUMBER;
    my_estim_percent VARCHAR2(32767);
    my_return VARCHAR2(32767);
    sql_rec sqlt$_sql_statement%ROWTYPE;

    /* -------------------------
     *
     * private gather_stats_all.dbms_stats_gather_one
     *
     * ------------------------- */
    FUNCTION dbms_stats_gather_one (
      p_size        IN VARCHAR2,
      p_owner       IN VARCHAR2,
      p_table_name  IN VARCHAR2,
      p_estim_perc  IN VARCHAR2,
      p_partitioned IN VARCHAR2,
      p_temporary   IN VARCHAR2,
      p_num_rows    IN NUMBER )
    RETURN VARCHAR2
    IS
    BEGIN
      IF SUBSTR(UPPER(p_temporary), 1, 1) = 'Y' THEN
        IF p_num_rows IS NOT NULL THEN
          RETURN
          '  SYS.DBMS_STATS.UNLOCK_TABLE_STATS ('||LF||
          '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
          '    tabname       => ''"'||UPPER(p_table_name)||'"'''||LF||
          '  );'||LF||
          '  SYS.DBMS_STATS.DELETE_TABLE_STATS ('||LF||
          '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
          '    tabname       => ''"'||UPPER(p_table_name)||'"'','||LF||
          '    no_invalidate => FALSE'||LF||
          '  );'||LF||
          '  SYS.DBMS_STATS.LOCK_TABLE_STATS ('||LF||
          '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
          '    tabname       => ''"'||UPPER(p_table_name)||'"'''||LF||
          '  );'||LF;
        ELSE
          RETURN NULL;
        END IF;
      ELSIF SUBSTR(UPPER(p_partitioned), 1, 1) = 'Y' THEN
        RETURN
        '  SYS.DBMS_STATS.UNLOCK_TABLE_STATS ('||LF||
        '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname       => ''"'||UPPER(p_table_name)||'"'''||LF||
        '  );'||LF||
        '  SYS.DBMS_STATS.GATHER_TABLE_STATS ('||LF||
        '    ownname          => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname          => ''"'||UPPER(p_table_name)||'"'','||LF||
        '    estimate_percent => '||p_estim_perc||','||LF||
        '    method_opt       => ''FOR ALL COLUMNS SIZE '||p_size||''','||LF||
        '    granularity      => ''GLOBAL AND PARTITION'','||LF||
        '    cascade          => TRUE,'||LF||
        '    no_invalidate    => FALSE'||LF||
        '  );'||LF;
      ELSE
        RETURN
        '  SYS.DBMS_STATS.UNLOCK_TABLE_STATS ('||LF||
        '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname       => ''"'||UPPER(p_table_name)||'"'''||LF||
        '  );'||LF||
        '  SYS.DBMS_STATS.GATHER_TABLE_STATS ('||LF||
        '    ownname          => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname          => ''"'||UPPER(p_table_name)||'"'','||LF||
        '    estimate_percent => '||p_estim_perc||','||LF||
        '    method_opt       => ''FOR ALL COLUMNS SIZE '||p_size||''','||LF||
        '    cascade          => TRUE,'||LF||
        '    no_invalidate    => FALSE'||LF||
        '  );'||LF;
      END IF;
    END dbms_stats_gather_one;

    /* -------------------------
     *
     * private gather_stats_all.fnd_stats_gather_one
     *
     * ------------------------- */
    FUNCTION fnd_stats_gather_one (
      p_owner       IN VARCHAR2,
      p_table_name  IN VARCHAR2,
      p_estim_perc  IN VARCHAR2,
      p_partitioned IN VARCHAR2,
      p_temporary   IN VARCHAR2 )
    RETURN VARCHAR2
    IS
    BEGIN
      IF SUBSTR(UPPER(p_temporary), 1, 1) = 'Y' THEN
        IF SUBSTR(UPPER(p_partitioned), 1, 1) = 'Y' THEN
          RETURN
          '  FND_STATS.GATHER_TABLE_STATS ('||LF||
          '    ownname     => ''"'||UPPER(p_owner)||'"'','||LF||
          '    tabname     => ''"'||UPPER(p_table_name)||'"'','||LF||
          '    percent     => '||p_estim_perc||','||LF||
          '    cascade     => TRUE,'||LF||
          '    tmode       => ''TEMPORARY'','||LF||
          '    granularity => ''ALL'''||LF||
          '  );'||LF;
        ELSE
          RETURN
          '  FND_STATS.GATHER_TABLE_STATS ('||LF||
          '    ownname => ''"'||UPPER(p_owner)||'"'','||LF||
          '    tabname => ''"'||UPPER(p_table_name)||'"'','||LF||
          '    percent => '||p_estim_perc||','||LF||
          '    cascade => TRUE,'||LF||
          '    tmode   => ''TEMPORARY'''||LF||
          '  );'||LF;
        END IF;
      ELSIF SUBSTR(UPPER(p_partitioned), 1, 1) = 'Y' THEN
        RETURN
        '  FND_STATS.GATHER_TABLE_STATS ('||LF||
        '    ownname     => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname     => ''"'||UPPER(p_table_name)||'"'','||LF||
        '    percent     => '||p_estim_perc||','||LF||
        '    cascade     => TRUE,'||LF||
        '    granularity => ''ALL'''||LF||
        '  );'||LF;
      ELSE
        RETURN
        '  FND_STATS.GATHER_TABLE_STATS ('||LF||
        '    ownname => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname => ''"'||UPPER(p_table_name)||'"'','||LF||
        '    percent => '||p_estim_perc||','||LF||
        '    cascade => TRUE'||LF||
        '  );'||LF;
      END IF;
    END fnd_stats_gather_one;

    /* -------------------------
     *
     * private gather_stats_all.siebel_stats_gather_one
     *
     * ------------------------- */
    FUNCTION siebel_stats_gather_one (
      p_owner       IN VARCHAR2,
      p_table_name  IN VARCHAR2,
      p_estim_perc  IN VARCHAR2,
      p_partitioned IN VARCHAR2,
      p_temporary   IN VARCHAR2,
      p_rows        IN NUMBER,
      p_num_rows    IN NUMBER )
    RETURN VARCHAR2
    IS
      l_indexed VARCHAR2(12) := NULL;

    BEGIN
      IF p_table_name NOT IN ('S_POSTN_CON', 'S_ORG_BU', 'S_ORG_GROUP') THEN
        l_indexed := 'INDEXED ';
      END IF;

      IF SUBSTR(UPPER(p_temporary), 1, 1) = 'Y' OR p_rows <= 15 THEN
        IF p_num_rows IS NOT NULL THEN
          RETURN
          '  SYS.DBMS_STATS.UNLOCK_TABLE_STATS ('||LF||
          '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
          '    tabname       => ''"'||UPPER(p_table_name)||'"'''||LF||
          '  );'||LF||
          '  SYS.DBMS_STATS.DELETE_TABLE_STATS ('||LF||
          '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
          '    tabname       => ''"'||UPPER(p_table_name)||'"'','||LF||
          '    no_invalidate => FALSE'||LF||
          '  );'||LF||
          '  SYS.DBMS_STATS.LOCK_TABLE_STATS ('||LF||
          '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
          '    tabname       => ''"'||UPPER(p_table_name)||'"'''||LF||
          '  );'||LF;
        ELSE
          RETURN NULL;
        END IF;
      ELSIF SUBSTR(UPPER(p_partitioned), 1, 1) = 'Y' THEN
        RETURN
        '  SYS.DBMS_STATS.UNLOCK_TABLE_STATS ('||LF||
        '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname       => ''"'||UPPER(p_table_name)||'"'''||LF||
        '  );'||LF||
        '  SYS.DBMS_STATS.DELETE_TABLE_STATS ('||LF||
        '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname       => ''"'||UPPER(p_table_name)||'"'''||LF||
        '  );'||LF||
        '  SYS.DBMS_STATS.GATHER_TABLE_STATS ('||LF||
        '    ownname          => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname          => ''"'||UPPER(p_table_name)||'"'','||LF||
        '    estimate_percent => '||p_estim_perc||','||LF||
        '    method_opt       => ''FOR ALL '||l_indexed||'COLUMNS SIZE 254'','||LF||
        '    granularity      => ''GLOBAL AND PARTITION'','||LF||
        '    cascade          => TRUE,'||LF||
        '    no_invalidate    => FALSE'||LF||
        '  );'||LF;
      ELSE
        RETURN
        '  SYS.DBMS_STATS.UNLOCK_TABLE_STATS ('||LF||
        '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname       => ''"'||UPPER(p_table_name)||'"'''||LF||
        '  );'||LF||
        '  SYS.DBMS_STATS.DELETE_TABLE_STATS ('||LF||
        '    ownname       => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname       => ''"'||UPPER(p_table_name)||'"'''||LF||
        '  );'||LF||
        '  SYS.DBMS_STATS.GATHER_TABLE_STATS ('||LF||
        '    ownname          => ''"'||UPPER(p_owner)||'"'','||LF||
        '    tabname          => ''"'||UPPER(p_table_name)||'"'','||LF||
        '    estimate_percent => '||p_estim_perc||','||LF||
        '    method_opt       => ''FOR ALL '||l_indexed||'COLUMNS SIZE 254'','||LF||
        '    cascade          => TRUE,'||LF||
        '    no_invalidate    => FALSE'||LF||
        '  );'||LF;
      END IF;
    END siebel_stats_gather_one;

    /* -------------------------
     *
     * private gather_stats_all.psft_stats_gather_one
     *
     * ------------------------- */
    FUNCTION psft_stats_gather_one (
      p_owner       IN VARCHAR2,
      p_table_name  IN VARCHAR2 )
    RETURN VARCHAR2
    IS
    BEGIN
      RETURN
      '  '||sql_rec.psft_schema||'.PSCBO_STATS.GATHER_TABLE_STATS ( -- see 1322888.1'||LF||
      '    p_table_name => ''"'||UPPER(p_table_name)||'"'','||LF||
      '    p_owner      => ''"'||UPPER(p_owner)||'"'''||LF||
      '  );'||LF;
    END psft_stats_gather_one;

  BEGIN
    sql_rec := sqlt$a.get_statement(p_statement_id);
    my_return := 'BEGIN -- generated by SQLT'||LF;

    FOR i IN (SELECT *
                FROM sqlt$_dba_all_tables_v
               WHERE statement_id = p_statement_id
               ORDER BY
                     temporary DESC,
                     partitioned,
                     table_name)
    LOOP
      my_rows := LEAST(NVL(i.num_rows, i.count_star), NVL(i.count_star, i.num_rows));

      --IF sql_rec.rdbms_release >= 11 AND p_mode = 1 THEN -- no histograms
      IF sql_rec.rdbms_release >= 11 THEN -- no histograms
        my_estim_percent := 'DBMS_STATS.AUTO_SAMPLE_SIZE';
      ELSIF my_rows IS NULL THEN -- 30%
        my_estim_percent := '30';
      ELSIF my_rows <= 1e6 THEN -- up to 1M do 100%
        my_estim_percent := '100';
      ELSIF my_rows <= 1e7 THEN -- up to 10M do 30%
        my_estim_percent := '30';
      ELSIF my_rows <= 1e8 THEN -- up to 100M do 10%
        my_estim_percent := '10';
      ELSIF my_rows <= 1e9 THEN -- up to 1B do 3%
        my_estim_percent := '3';
      ELSE -- more than 1B do 1%
        my_estim_percent := '1';
      END IF;

      IF NVL(sql_rec.apps_release, 'NO') = 'NO' AND NVL(sql_rec.siebel, 'NO') = 'NO' /* AND NVL(sql_rec.psft, 'NO') = 'NO' */ THEN
        IF p_mode = 1 THEN -- no histograms
          my_return := my_return||dbms_stats_gather_one('1', i.owner, i.table_name, my_estim_percent, i.partitioned, i.temporary, i.num_rows);
        ELSIF p_mode = 2 THEN -- histograms
          my_return := my_return||dbms_stats_gather_one('AUTO', i.owner, i.table_name, my_estim_percent, i.partitioned, i.temporary, i.num_rows);
        END IF;
      ELSIF sql_rec.apps_release IS NOT NULL THEN
        my_return := my_return||fnd_stats_gather_one(i.owner, i.table_name, my_estim_percent, i.partitioned, i.temporary);
      ELSIF sql_rec.siebel = 'YES' THEN
        my_return := my_return||siebel_stats_gather_one(i.owner, i.table_name, my_estim_percent, i.partitioned, i.temporary, my_rows, i.num_rows);
      ELSIF sql_rec.psft = 'YES' THEN
        my_return := my_return||psft_stats_gather_one(i.owner, i.table_name);
      END IF;
    END LOOP;

    my_return := my_return||'END;'||LF||'/';
    RETURN my_return;
  END gather_stats_all;

  /*************************************************************************************/

  /* -------------------------
   *
   * public readme_report_html
   *
   * called by: sqlt$i.xtract, sqlt$i.remote_xtract, sqlt$i.xecute_end and sqlt$i.xplain_end
   *
   * ------------------------- */
  PROCEDURE readme_report_html (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_statid VARCHAR2(32767);
    l_statement_id VARCHAR2(32767);
    l_statement_id2 VARCHAR2(32767);
    l_prefix VARCHAR2(32767);
    l_prefix2 VARCHAR2(32767);
    l_count_sta NUMBER;
    l_count_spm NUMBER;
    l_count_sts NUMBER;
    l_count_spd NUMBER;
    l_out_file_identifier VARCHAR2(32767);

    /* -------------------------
     *
     * private readme_report_html.wa - write append
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

  BEGIN
    write_log('-> readme_report_html');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_group_id IS NULL THEN
      l_statement_id := sqlt$a.get_statement_id_c(p_statement_id);
      l_prefix := 'sqlt_s'||l_statement_id||l_out_file_identifier;
      l_statement_id2 := l_statement_id;
      l_prefix2 := l_prefix;
    ELSE
      l_statement_id := sqlt$a.get_statement_id_c(p_statement_id);
      l_prefix := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier;
      l_statement_id2 := sqlt$a.get_statement_id_c(p_group_id);
      l_prefix2 := 'sqlt_s'||l_statement_id2||l_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_readme.html';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_readme.html';
    END IF;

    IF p_group_id IS NULL THEN
      l_statid := sql_rec.statid;
    ELSE
      l_statid := 's'||sqlt$a.get_statement_id_c(p_group_id)||'_'||'s'||sqlt$a.get_statement_id_c(p_statement_id);
    END IF;

    /* -------------------------
     * Header
     * ------------------------- */
    BEGIN
      s_file_rec.file_text :=
'<html>
<!-- $Header: '||NOTE_NUMBER||' '||s_file_rec.filename||' '||sqlt$a.get_param('tool_version')||' '||TO_CHAR(SYSDATE, HEADING_DATE_FORMAT)||' '||TOOL_DEVELOPER||' $ -->
<!-- '||COPYRIGHT||' -->
<!-- Author: '||TOOL_DEVELOPER_EMAIL||' -->
<head>
<title>'||s_file_rec.filename||'</title>
<style type="text/css">
body {font:10pt Arial, Helvetica, Verdana, Geneva, sans-serif; color:Black; background:White;}
a {font-weight:bold; color:#663300;}
pre {font:8pt Monaco, "Courier New", Courier, monospace; margin:1em 8em 1.5em 4em; padding:1em 0 1em 4em; border:1px solid #336699; background-color:#fcfcf0; overflow:auto;}
code {font:10pt Monaco, "Courier New", Courier, monospace; font-weight:bold;}
h1 {color:#336699; font-weight:bold; font-size:16pt;}
h2 {color:#336699; font-weight:bold; font-size:14pt;}
h3 {color:#336699; font-weight:bold; font-size:12pt;}
h4 {color:#336699; font-weight:bold; font-size:10pt;}
table {font-size:8pt; color:Black; background:White;}
th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding:0.25em 0.25em 0.25em 0.25em;}
td {text-align:center; background:#fcfcf0; vertical-align:top; padding:0.25em 0.25em 0.25em 0.25em;}
td.lw {text-align:left; background:white;}
li {color:#336699; font-weight:bold; font-size:10pt; padding:0.3em 0 0 0;}
font.crimson {color:crimson;}
font.red {color:red;}
font.orange {color:orange;}
font.green {color:green;}
</style>
</head>
<body>
<h1>'||NOTE_NUMBER||' SQLT '||sql_rec.method||' '||sqlt$a.get_param('tool_version')||' Report: '||s_file_rec.filename||'</h1>
<p>Instructions to perform the following:</p>
<ul>
<li><a href="#export">Export SQLT repository</a></li>
<li><a href="#import">Import SQLT repository</a></li>
<li><a href="#compare">Using SQLT COMPARE</a></li>
<li><a href="#obj_stats">Restore CBO schema statistics</a></li>
<li><a href="#sys_stats">Restore CBO system statistics</a></li>
<li><a href="#sqlt_tc">Implement SQLT Test Case (TC)</a></li>
<li><a href="#tc">Create TC with no SQLT dependencies</a></li>';

      SELECT COUNT(*)
        INTO l_count_sta
        FROM sqlt$_stgtab_sqlprof
       WHERE statid = l_statid;

      IF l_count_sta > 0 THEN
        wa('<li><a href="#sta">Restore SQL Profile</a></li>');
      END IF;

      SELECT COUNT(*)
        INTO l_count_spm
        FROM sqlt$_stgtab_baseline
       WHERE statid = l_statid;

      IF l_count_spm > 0 THEN
        wa('<li><a href="#spm">Restore SQL Plan Baseline</a></li>');
      END IF;

      SELECT COUNT(*)
        INTO l_count_sts
        FROM sqlt$_stgtab_sqlset
       WHERE statid = l_statid;

      IF l_count_sts > 0 AND sql_rec.rdbms_version >= '11.2' THEN
        wa('<li><a href="#rsts">Restore SQL Set</a></li>');
      END IF;

      IF l_count_sts > 0 THEN
        wa('<li><a href="#sts">Create SQL Plan Baseline from SQL Set</a></li>');
      END IF;

      SELECT COUNT(*)
        INTO l_count_spd
        FROM sqlt$_stgtab_directive
       WHERE statid = l_statid;

      IF l_count_spd > 0 THEN
        wa('<li><a href="#spd">Restore SQL Plan Directives</a></li>');
      END IF;

      IF NVL(sql_rec.apps_release, 'NO') = 'NO' AND NVL(sql_rec.siebel, 'NO') = 'NO' AND NVL(sql_rec.psft, 'NO') = 'NO' THEN
        wa('<li><a href="#no_hist">Gather CBO statistics without Histograms (using SYS.DBMS_STATS)</a></li>');
        wa('<li><a href="#hist">Gather CBO statistics with Histograms (using SYS.DBMS_STATS)</a></li>');
      ELSIF sql_rec.apps_release IS NOT NULL THEN
        wa('<li><a href="#apps_stats">Gather CBO statistics for EBS</a></li>');
      ELSIF sql_rec.siebel = 'YES' THEN
        wa('<li><a href="#siebel_stats">Gather CBO statistics for SIEBEL</a></li>');
      ELSIF sql_rec.psft = 'YES' THEN
        wa('<li><a href="#psft_stats">Gather CBO statistics for PSFT (using PSCBO_STATS)</a></li>');
        wa('<li><a href="#no_hist">Gather CBO statistics without Histograms (using SYS.DBMS_STATS)</a></li>');
        wa('<li><a href="#hist">Gather CBO statistics with Histograms (using SYS.DBMS_STATS)</a></li>');
      END IF;

      IF p_db_link IS NULL THEN
        wa('<li><a href="#gen_files">List generated files</a></li>');
      END IF;
      wa('</ul>');
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.header:'||SQLERRM);
    END;

    /* -------------------------
     * Export SQLT repository
     * ------------------------- */
    BEGIN
      wa('
<a name="export"></a>
<hr size="3">
<h2>Export SQLT repository</h2>');

      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        wa('
<p>Steps:</p>
<ol>
<li>Unzip <code>'||l_prefix2||'_driver.zip</code> in order to get <code>'||l_prefix2||'_export_parfile.txt</code>.</li>
<li>Copy <code>'||l_prefix2||'_export_parfile.txt</code> to SOURCE server (TEXT).</li>
<li>Execute export on server:</li>
<p><code>expdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||sqlt$a.get_param('connect_identifier')||' parfile='||l_prefix2||'_export_parfile.txt</code></p>
</ol>');
      ELSE
        wa('
<p>Steps:</p>
<ol>
<li>Unzip <code>'||l_prefix2||'_driver.zip</code> in order to get <code>'||l_prefix2||'_export_parfile.txt</code>.</li>
<li>Copy <code>'||l_prefix2||'_export_parfile.txt</code> to SOURCE server (TEXT).</li>
<li>Execute export on server:</li>
<p><code>exp '||LOWER(TOOL_REPOSITORY_SCHEMA)||sqlt$a.get_param('connect_identifier')||' parfile='||l_prefix2||'_export_parfile.txt</code></p>
</ol>');
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.export:'||SQLERRM);
    END;

    /* -------------------------
     * Import SQLT repository
     * ------------------------- */
    BEGIN
      wa('
<a name="import"></a>
<hr size="3">
<h2>Import SQLT repository</h2>');

      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        wa('
<p>Steps:</p>
<ol>
<li>Unzip <code>'||l_prefix2||'_tc.zip</code> in order to get <code>'||l_prefix2||'_expdp.dmp</code>.</li>
<li>Copy <code>'||l_prefix2||'_expdp.dmp</code> to <code>SQLT$STAGE</code> directory (BINARY).</li>
<p>To locate <code>SQLT$STAGE</code> use: <code>SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$STAGE'';</code></p>
<p>To change location of <code>SQLT$STAGE</code> use: <code>sqlt/utl/sqltcdirs.sql</code>.</p>
<li>Execute import on server:</li>
<p><code>impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp</code></p>
</ol>
<p>You can execute <code>'||l_prefix2||'_import.sh</code> instead.</p>');
      ELSE
        wa('
<p>Steps:</p>
<ol>
<li>Unzip <code>'||l_prefix2||'_tc.zip</code> in order to get <code>'||l_prefix2||'_expdp.dmp</code>.</li>
<li>Copy <code>'||l_prefix2||'_exp.dmp</code> to the server (BINARY).</li>
<li>Execute import on server:</li>
<p><code>imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp TABLES=sqlt% IGNORE=Y</code></p>
</ol>
<p>You can execute <code>'||l_prefix2||'_import.sh</code> instead.</p>');
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.import:'||SQLERRM);
    END;

    /* -------------------------
     * Using SQLT COMPARE
     * ------------------------- */
    BEGIN
      wa('
<a name="compare"></a>
<hr size="3">
<h2>Using SQLT COMPARE</h2>

<p>You need to have a set of SQLT files (sqlt_sNNNNN_method.zip) from two executions of the SQLT tool. They can be from any method (XTRACT, XECUTE or XPLAIN) and they can be from the same or different systems. They do not have to be from same release or platform. For example, a SQLT from 10g on Linux and a SQLT from 11g on Unix can be compared.</p>

<p>To use the COMPARE method you need 3 systems: SOURCE1, SOURCE2 and COMPARE. The 3 could all be different, or all the same. For example, SOURCE1 could be PROD, SOURCE2 DEV and COMPARE DEV. In other words, you could do the COMPARE in one of the sources. Or the COMPARE could be done on a 3rd and remote system.</p>

<p>Basically you need to restore the SQLT repository from both SOURCES into the COMPARE system. In most cases it means "restoring" the SQLT repository from at least one SOURCE into the COMPARE. Once you have both SQLT repositories into the COMPARE system, then you can execute this method.</p>

<p>Steps:</p>');
      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        wa('
<ol>
<li>Unzip <code>'||l_prefix2||'_tc.zip</code> from this SOURCE in order to get <code>'||l_prefix2||'_expdp.dmp</code>.</li>
<li>Copy <code>'||l_prefix2||'_expdp.dmp</code> to <code>SQLT$STAGE</code> directory (BINARY).</li>
<p>To locate <code>SQLT$STAGE</code> use: <code>SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$STAGE'';</code></p>
<p>To change location of <code>SQLT$STAGE</code> use: <code>sqlt/utl/sqltcdirs.sql</code>.</p>
<li>Execute import on server:</li>
<p><code>impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp</code></p>
<li>Perform the equivalent steps for the 2nd SOURCE if needed. You may want to follow its readme file.</li>
<li>Execute the COMPARE method connecting into SQL*Plus as SYS. You will be asked to enter which 2 statements you want to compare.</li>
<p><code>START sqlt/run/sqltcompare.sql </code></p>
</ol>');
      ELSE
        wa('
<ol>
<li>Unzip <code>'||l_prefix2||'_tc.zip</code> from this SOURCE in order to get <code>'||l_prefix2||'_expdp.dmp</code>.</li>
<li>Copy <code>'||l_prefix2||'_exp.dmp</code> to the server (BINARY).</li>
<li>Execute import on server:</li>
<p><code>imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp TABLES=sqlt% IGNORE=Y</code></p>
<li>Perform the equivalent steps for the 2nd SOURCE if needed. You may want to follow its readme file.</li>
<li>Execute the COMPARE method connecting into SQL*Plus as SYS. You will be asked to enter which 2 statements you want to compare.</li>
<p><code>START sqlt/run/sqltcompare.sql </code></p>
</ol>');
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.compare:'||SQLERRM);
    END;

    /* -------------------------
     * Restore CBO schema statistics
     * ------------------------- */
    BEGIN
      wa('
<a name="obj_stats"></a>
<hr size="3">
<h2>Restore CBO schema statistics</h2>

<p>CBO schema object statistics can be restored from the local SQLT repository, or from an <a href="#import">imported repository</a>. Restoring CBO statistics associates them to existing and compatible schema objects. These objects can be owned by the original schema owner or by a different one. For example, table T is owned by user U in SOURCE and by user TC'||l_statement_id||' in TARGET.</p>

<p>When using restore script below, the second parameter allows to remap the schema object statistics to a different user. Be aware that target user and schema objects must exist before executing this script. To restore CBO schema object statistics into the original schema owner(s) pass "null" (or just hit the "Enter" key) when the second parameter is requested.</p>

<p>Steps:</p>
<ol>
<li>Execute restore script connecting as SYSDBA:</li>
<p><code>START sqlt/utl/sqltimp.sql '||l_statid||' TC'||l_statement_id||'</code></p>
</ol>');

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.obj_stats:'||SQLERRM);
    END;

    /* -------------------------
     * Restore CBO system statistics
     * ------------------------- */
    BEGIN
      wa('
<a name="sys_stats"></a>
<hr size="3">
<h2>Restore CBO system statistics</h2>

<p>Steps:</p>
<ol>
<li>Execute restore script connecting as SYSDBA:</li>
<p><code>START '||l_prefix||'_system_stats.sql</code></p>
</ol>');

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.sys_stats:'||SQLERRM);
    END;

    /* -------------------------
     * Implement SQLT Test Case (TC)
     * ------------------------- */
    BEGIN
      wa('
<a name="sqlt_tc"></a>
<hr size="3">
<h2>Implement SQLT Test Case (TC)</h2>

<p>SOURCE and TARGET systems should be similar. Proceed with Preparation followed by Express or Custom mode.</p>

<h3>Preparation</h3>

<ol>
<li>Unzip <code>'||l_prefix2||'_tc.zip</code> in server and navigate to TC directory.</li>
<p><code>unzip '||l_prefix||'_tc.zip -d TC'||l_statement_id||'</code></p>
<p><code>cd TC'||l_statement_id||'</code></p>
</ol>

<h3>Express (XPRESS) mode</h3>

<ol>
<li>Review and execute <code>xpress.sh</code> from OS or <code>xpress.sql</code> from sqlplus.</li>
<p>Option 1: <code>./xpress.sh</code></p>
<p>Option 2: <code>sqlplus / as sysdba '||ARROBA||'xpress.sql</code></p>
</ol>

<h3>Custom mode</h3>

<ol>
<li>Create test case user and schema objects connecting as SYSDBA:</li>
<p><code>sqlplus / as sysdba</code></p>
<p><code>START '||l_prefix||'_metadata.sql</code></p>
<li>Purge pre-existing s'||l_statement_id||' from local SQLT repository connected as SYSDBA:</li>
<p><code>START '||l_prefix||'_purge.sql</code></p>
<li><a href="#import">Import SQLT repository for s'||l_statement_id||'</a> (provide '||UPPER(TOOL_REPOSITORY_SCHEMA)||' password):</li>');

      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        wa('<p><code>HOS impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp</code></p>');
      ELSE
        wa('<p><code>HOS imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp LOG='||l_prefix2||'_imp.log TABLES=sqlt% IGNORE=Y</code></p>');
      END IF;

      wa('
<li><a href="#obj_stats">Restore CBO schema statistics</a> for test case user connected as SYSDBA:</li>
<p><code>START '||l_prefix||'_restore.sql</code></p>
<li><a href="#sys_stats">Restore CBO system statistics</a> connected as SYSDBA:</li>
<p><code>START '||l_prefix||'_system_stats.sql</code></p>
<li>Set the CBO environment connecting as test case user TC'||l_statement_id||' (include optional test case user suffix):</li>
<p><code>CONN TC'||l_statement_id||'/TC'||l_statement_id||'</code></p>
<p><code>START '||l_prefix||'_set_cbo_env.sql</code></p>
<li>Execute test case:</li>
<p><code>START tc.sql</code></p>
</ol>
');

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.sqlt_tc:'||SQLERRM);
    END;

    /* -------------------------
     * Create TC with no SQLT dependencies
     * ------------------------- */
    BEGIN
      wa('
<a name="tc"></a>
<hr size="3">
<h2>Create TC with no SQLT dependencies</h2>

<p>After <a href="#sqlt_tc">creating a local test case using SQLT files</a>, you can create a stand-alone TC with no dependencies on SQLT.</p>

<p>Steps:</p>
<ol>
<li>Export TC schema object statistics to staging table within TC schema:</li>
<p><code>DELETE TC'||l_statement_id||'.CBO_STAT_TAB_4TC;<br>
EXEC SYS.DBMS_STATS.EXPORT_SCHEMA_STATS(ownname => ''TC'||l_statement_id||''', stattab => ''CBO_STAT_TAB_4TC'');</code></p>
<li>Export TC schema object statistics from staging table:</li>
<p><code>HOS exp TC'||l_statement_id||'/TC'||l_statement_id||' FILE=cbo_stat_tab_4tc.dmp LOG=cbo_stat_tab_4tc.log TABLES=cbo_stat_tab_4tc STATISTICS=NONE</code></p>
<li>Review <code>setup.sql</code> script and adjust if needed.</li>
<li>Review <code>readme.txt</code> file and adjust if needed.</li>
<li>Create and zip a new directory with the following files:</li>
<pre>
CBO schema object statistics dump: cbo_stat_tab_4tc.dmp
Plan script:                       plan.sql
Query script:                      q.sql
Instructions:                      readme.txt
Setup script:                      setup.sql
Metadata script:                   '||l_prefix||'_metadata.sql
OPatch (if needed):                '||l_prefix||'_opatch.zip
Set CBO env script (if needed):    '||l_prefix||'_set_cbo_env.sql
System statistics setup:           '||l_prefix||'_system_stats.sql
Test case script:                  tc.sql
</pre>
<li>Test your new stand-alone TC following your own <code>readme.txt</code> in another system.</li>
</ol>
<p>Note: You may want to use tc_pkg.sql to execute commands above.</p>');

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.tc:'||SQLERRM);
    END;

    /* -------------------------
     * Restore SQL Profile
     * ------------------------- */
    BEGIN
      IF l_count_sta > 0 THEN
        wa('
<a name="sta"></a>
<hr size="3">
<h2>Restore SQL Profile</h2>

<p>SOURCE and TARGET systems should be similar.</p>

<p>SQLT exported from SOURCE at least one SQL Profile associated to your query. You can copy it into your TARGET system following these steps.</p>

<p>Steps:</p>
<ol>
<li><a href="#import">Import SQLT repository</a> (only if you haven''t done so as part of another operation like TC creation):</li>');

        IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
          wa('<p><code>impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp</code></p>');
        ELSE
          wa('<p><code>imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp TABLES=sqlt% IGNORE=Y</code></p>');
        END IF;

        wa('
<li>Create local staging table connecting as SYSDBA:</li>
<p><code>CREATE TABLE stgtab_sqlprof AS SELECT * FROM '||TOOL_REPOSITORY_SCHEMA||'.sqlt$_stgtab_sqlprof WHERE statid = '''||l_statid||''';</code></p>
<p><code>ALTER TABLE stgtab_sqlprof DROP COLUMN statid;</code></p>
<li>Copy SQL Profile by following corresponding syntaxt below.</li>
</ol>');

        FOR i IN (SELECT DISTINCT name, category FROM sqlt$_dba_sql_profiles WHERE statid = l_statid ORDER BY 1, 2)
        LOOP
          wa('<pre>BEGIN
  SYS.DBMS_SQLTUNE.UNPACK_STGTAB_SQLPROF (
    profile_name         => '''||i.name||''',
    profile_category     => '''||i.category||''',
    replace              => TRUE,
    staging_table_name   => ''STGTAB_SQLPROF'',
    staging_schema_owner => USER );
END;'||LF||'/
</pre>');
        END LOOP;

      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.sta:'||SQLERRM);
    END;

    /* -------------------------
     * Restore SQL Plan Baseline
     * ------------------------- */
    BEGIN
      IF l_count_spm > 0 THEN
        wa('
<a name="spm"></a>
<hr size="3">
<h2>Restore SQL Plan Baseline</h2>

<p>SOURCE and TARGET systems should be similar.</p>

<p>SQLT exported from SOURCE at least one SQL Plan from SPM/SMB associated to your query. You can copy it into your TARGET system following these steps.</p>

<p>Steps:</p>
<ol>
<li><a href="#import">Import SQLT repository</a> (only if you haven''t done so as part of another operation like TC creation):</li>');

        IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
          wa('<p><code>impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp</code></p>');
        ELSE
          wa('<p><code>imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp TABLES=sqlt% IGNORE=Y</code></p>');
        END IF;

        wa('
<li>Restore a SQL Plan from SPM/SMB by following corresponding syntaxt below.</li>
</ol>');

        FOR i IN (SELECT DISTINCT sql_handle, plan_name FROM sqlt$_dba_sql_plan_baselines WHERE statid = l_statid ORDER BY 1, 2)
        LOOP
          wa('<pre>SET SERVEROUT ON;
DECLARE
  x NUMBER;
BEGIN
  x := SYS.DBMS_SPM.UNPACK_STGTAB_BASELINE (
    table_name  => ''SQLT$_STGTAB_BASELINE'',
    table_owner => '''||TOOL_REPOSITORY_SCHEMA||''',
    sql_handle  => '''||i.sql_handle||''',
    plan_name   => '''||i.plan_name||''',
    action      => '''||l_statid||''' );
  SYS.DBMS_OUTPUT.PUT_LINE(''Plans: ''||x);
END;'||LF||'/
SET SERVEROUT OFF;
</pre>');
        END LOOP;

      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.spm:'||SQLERRM);
    END;

    /* -------------------------
     * Restore SQL Set
     * ------------------------- */
    BEGIN
      IF l_count_sts > 0 AND sqlt$a.get_rdbms_version >= '11.2' THEN
        wa('
<a name="rsts"></a>
<hr size="3">
<h2>Restore SQL Set</h2>

<p>SOURCE and TARGET systems should be similar.</p>

<p>SQLT exported from SOURCE at least one SQL Set with a plan associated to your query. The SQL Set name below includes the plan hash value and its source (memory or awr).</p>

<p>You can copy a SQL Set into your TARGET system following these steps. After a SQL Set with one plan is restored, you can proceed to load it as a SQL Plan into its SQL Baseline.</p>

<p>Steps:</p>
<ol>
<li><a href="#import">Import SQLT repository</a> (only if you haven''t done so as part of another operation like TC creation):</li>');

        IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
          wa('<p><code>impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp</code></p>');
        ELSE
          wa('<p><code>imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp TABLES=sqlt% IGNORE=Y</code></p>');
        END IF;

        wa('
<li>Copy one SQL Set by following corresponding syntaxt below.</li>
</ol>');

        FOR i IN (SELECT DISTINCT name, description FROM sqlt$_stgtab_sqlset WHERE statid = l_statid ORDER BY 2)
        LOOP
          wa('<pre>-- '||i.description||'
BEGIN
  SYS.DBMS_SQLTUNE.UNPACK_STGTAB_SQLSET (
    sqlset_name          => '''||i.name||''',
    sqlset_owner         => '''||TOOL_ADMINISTER_SCHEMA||''',
    replace              => TRUE,
    staging_table_name   => ''SQLT$_STGTAB_SQLSET'',
    staging_schema_owner => '''||TOOL_REPOSITORY_SCHEMA||''' );
END;'||LF||'/
</pre>');
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.rsts:'||SQLERRM);
    END;

    /* -------------------------
     * Create SQL Plan Baseline from SQL Set
     * ------------------------- */
    BEGIN
      IF l_count_sts > 0 THEN
        wa('
<a name="sts"></a>
<hr size="3">
<h2>Create SQL Plan Baseline from SQL Set</h2>

<p>You can load one SQL Plan into its SQL Plan Baseline from a SQL Set created by SQLT for each plan found in memory or AWR.</p>

<p>This method only works on the same system where SQLT was executed. Unless you first <a href="#rsts">restore a SQL Set</a> from a different source.</p>

<p>The SQL Set name below includes the plan hash value and its source (memory or awr). You can load one or more plans into a SQL Plan Baseline.</p>');

        FOR i IN (SELECT DISTINCT name, description FROM sqlt$_stgtab_sqlset WHERE statid = l_statid ORDER BY 2)
        LOOP
          wa('<pre>-- '||i.description||'
SET SERVEROUT ON;
DECLARE
  x NUMBER;
  time DATE := SYSDATE;
  l_planame sys.dba_sql_plan_baselines.plan_name%TYPE;
  l_sql_handle sys.dba_sql_plan_baselines.sql_handle%TYPE;
BEGIN
  DBMS_LOCK.SLEEP(5);
  x := SYS.DBMS_SPM.LOAD_PLANS_FROM_SQLSET (
    sqlset_name  => '''||i.name||''',
    sqlset_owner => '''||TOOL_ADMINISTER_SCHEMA||''' );
  SYS.DBMS_OUTPUT.PUT_LINE(''Plans: ''||x);
  IF x = 1 THEN
    SELECT plan_name, sql_handle
      INTO l_planame, l_sql_handle
      FROM sys.dba_sql_plan_baselines
     WHERE signature = '||sql_rec.signature_sta_unstripped||'
       AND created >= time;
    x := DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
      sql_handle      => l_sql_handle,
      plan_name       => l_planame,
      attribute_name  => ''DESCRIPTION'',
      attribute_value => TRIM('''||i.description||''') );
    x := DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
      sql_handle      => l_sql_handle,
      plan_name       => l_planame,
      attribute_name  => ''PLAN_NAME'',
      attribute_value => UPPER('''||i.name||''') );
    SYS.DBMS_OUTPUT.PUT_LINE(''Renamed: ''||x||'' ''||UPPER('''||i.name||'''));
  END IF;
END;'||LF||'/
SET SERVEROUT OFF;
</pre>');
        END LOOP;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.sts:'||SQLERRM);
    END;

    /* -------------------------
     * Restore SQL Plan directives
	 * 150828 Remade Section
	 * 171003 Cosmetic change
     * ------------------------- */
    BEGIN
      IF l_count_spd > 0 THEN  
        wa('
<a name="spd"></a>
<hr size="3">
<h2>Restore SQL Plan Directives</h2>
<p>You can restore the SQL Plan Directives for the objects involved in the SQL statement.</p>
<p>This method works if the same objects exist under the same schema as the source schema. <br>
In case you consolidated all the objects under one specific user (ie. when installing the TC in a test system) then 
you will need to remap the SQL Plan Directives in the staging table to such user before restoring them. Like using the following :</p>
<pre>
UPDATE '||TOOL_ADMINISTER_SCHEMA||'.sqlt$_stgtab_directive SET c1 = ''TC'||l_statement_id||''' WHERE statid='''||l_statid||''' and c1 IS NOT NULL;
COMMIT;
</pre>
<p>To restore the The SQL Plan Directives execute from SYS.</p>
<pre>-- 
SET SERVEROUT ON;
DECLARE
  x NUMBER;
BEGIN
-- this is because DBMS_SPD does not like statid not null
UPDATE '||TOOL_ADMINISTER_SCHEMA||'.sqlt$_stgtab_directive SET statid = NULL WHERE statid='''||l_statid||''';
COMMIT; ');
  wa(' x := SYS.DBMS_SPD.UNPACK_STGTAB_DIRECTIVE (
    table_name  => ''SQLT$_STGTAB_DIRECTIVE'',
    table_owner => '''||TOOL_ADMINISTER_SCHEMA||''');,
  SYS.DBMS_OUTPUT.PUT_LINE(''Directives Unpacked: ''||x);');
wa('END;'||LF||'/
SET SERVEROUT OFF;
</pre>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.spd:'||SQLERRM);
    END;

    /* -------------------------
     * Gather CBO statistics for EBS
     * ------------------------- */
    BEGIN
      IF sql_rec.apps_release IS NOT NULL THEN
        wa('
<a name="apps_stats"></a>
<hr size="3">
<h2>Gather CBO statistics for EBS</h2>

<p>Use commands below to generate a fresh set of CBO statistics for the schema objects accessed by your SQL.</p>');

        wa('<pre>'||gather_stats_all(p_statement_id)||'</pre>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.no_hist.apps:'||SQLERRM);
    END;

    /* -------------------------
     * Gather CBO statistics for SIEBEL
     * ------------------------- */
    BEGIN
      IF sql_rec.siebel = 'YES' THEN
        wa('
<a name="siebel_stats"></a>
<hr size="3">
<h2>Gather CBO statistics for SIEBEL</h2>

<p>Use commands below to generate a fresh set of CBO statistics for the schema objects accessed by your SQL.</p>');

        wa('<pre>'||gather_stats_all(p_statement_id)||'</pre>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.siebel:'||SQLERRM);
    END;

    /* -------------------------
     * Gather CBO statistics for PSFT
     * ------------------------- */
    BEGIN
      IF sql_rec.psft = 'YES' THEN
        wa('
<a name="psft_stats"></a>
<hr size="3">
<h2>Gather CBO statistics for PSFT (using PSCBO_STATS)</h2>

<p>Use commands below to generate a fresh set of CBO statistics for the schema objects accessed by your SQL.</p>');

        wa('<pre>'||gather_stats_all(p_statement_id)||'</pre>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.siebel:'||SQLERRM);
    END;

    /* -------------------------
     * Gather CBO statistics without Histograms
     * ------------------------- */
    BEGIN
      IF NVL(sql_rec.apps_release, 'NO') = 'NO' AND NVL(sql_rec.siebel, 'NO') = 'NO' /* AND NVL(sql_rec.psft, 'NO') = 'NO' */ THEN
        wa('
<a name="no_hist"></a>
<hr size="3">
<h2>Gather CBO statistics without Histograms (using SYS.DBMS_STATS)</h2>

<p>Use commands below to generate a fresh set of CBO statistics for the schema objects accessed by your SQL. Histograms will be dropped.</p>');

        wa('<pre>'||gather_stats_all(p_statement_id, 1)||'</pre>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.no_hist:'||SQLERRM);
    END;

    /* -------------------------
     * Gather CBO statistics with Histograms
     * ------------------------- */
    BEGIN
      IF NVL(sql_rec.apps_release, 'NO') = 'NO' AND NVL(sql_rec.siebel, 'NO') = 'NO' /* AND NVL(sql_rec.psft, 'NO') = 'NO' */ THEN
        wa('
<a name="hist"></a>
<hr size="3">
<h2>Gather CBO statistics with Histograms (using SYS.DBMS_STATS)</h2>

<p>Use commands below to generate a fresh set of CBO statistics for the schema objects accessed by your SQL. Histograms will be generated for some columns.</p>');

        wa('<pre>'||gather_stats_all(p_statement_id, 2)||'</pre>');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.hist:'||SQLERRM);
    END;

    /* -------------------------
     * List generated files
     * ------------------------- */
    DECLARE
    BEGIN
      IF p_db_link IS NULL THEN
        wa('
<a name="gen_files"></a>
<hr size="3">
<h2>List generated files</h2>');

        wa('<p>Files generated under current SQL*Plus directory.<br>Not all files may be available.</p>');
        wa('<pre>');
        wa(sql_rec.file_sqlt_main);
        wa(sql_rec.file_sqlt_metadata);
        wa(sql_rec.file_sqlt_metadata1);
        wa(sql_rec.file_sqlt_metadata2);
        wa(sql_rec.file_sqlt_system_stats);
        wa(sql_rec.file_sqlt_schema_stats);
        wa(sql_rec.file_sqlt_set_cbo_env);
        wa(sql_rec.file_sqlt_lite);
        wa(s_file_rec.filename);
        wa(REPLACE(s_file_rec.filename, 'html', 'txt'));
        wa(sql_rec.file_sqlt_tcscript);
        wa(sql_rec.file_sqlt_tcsql);
        wa(sql_rec.file_sqlt_tcbuilder);
        wa(l_prefix2||'_tcb.zip');
        wa(sql_rec.file_remote_driver);
        wa(sql_rec.file_script_output_driver);
        wa(sql_rec.file_tkprof_px_driver);
        wa(sql_rec.file_sqlt_exp_params);
        wa(sql_rec.file_sqlt_exp_params2);
        wa(sql_rec.file_sqlt_exp_driver);
        wa(sql_rec.file_sqlt_imp_script);
        wa(l_prefix2||'_export.zip');
        wa(l_prefix2||'_tc.zip');
        wa(l_prefix2||'_log.zip');
        wa(l_prefix2||'_opatch.zip');
        wa(l_prefix2||'_remote.zip');
        wa(sql_rec.file_sqlt_profile);
        wa(sql_rec.file_sta_report_mem);
        wa(sql_rec.file_sta_script_mem);
        wa(sql_rec.file_sta_report_txt);
        wa(sql_rec.file_sta_script_txt);
        wa(sql_rec.file_sta_report_awr);
        wa(sql_rec.file_sta_script_awr);
        wa(sql_rec.file_sql_detail_active);
        wa(sql_rec.file_mon_report_active);
        wa(sql_rec.file_mon_report_html);
        wa(sql_rec.file_mon_report_text);
        wa(sql_rec.file_trcanlzr_html);
        wa(sql_rec.file_trcanlzr_txt);
        wa(sql_rec.file_trcanlzr_log);
        wa(sql_rec.file_trcanlzr_px_html);
        wa(sql_rec.file_trcanlzr_px_txt);
        wa(sql_rec.file_trcanlzr_px_log);
        wa(sql_rec.file_10046_split);
        wa(sql_rec.file_10053_split);
        wa(sql_rec.file_bde_chk_cbo);
        wa(sql_rec.file_10046_10053);
        wa(sql_rec.file_10053);
        wa(sql_rec.file_10053_xtract);
        IF sql_rec.method = 'XECUTE' THEN
          wa(l_prefix2||'_tkprof_sort.txt');
          wa(l_prefix2||'_tkprof_nosort.txt');
        END IF;
        wa(l_prefix||'_'||LOWER(sql_rec.method)||'.log');
        wa('sqlt'||LOWER(sql_rec.method)||'.log');
        wa(sql_rec.input_filename);
        wa('sqltxhost.log');
        wa('plan.sql');
        wa('10053.sql');
        wa('flush.sql');
        wa('purge.sql');
        wa('restore.sql');
        wa('del_hgrm.sql');
        wa('tc.sql');
        wa('tc_pkg.sql');
        wa('xpress.sql');
        wa('xpress.sh');
        wa('setup.sql');
        wa('q.sql');
        wa('sel.sql');
        wa('sel_aux.sql');
        wa('install.sql');
        wa('install.sh');
        wa('tcx_pkg.sql');
        wa('</pre>');

        wa('<p>Files generated under SQLT$UDUMP directory.<br>To locate SQLT$UDUMP: <code>SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$UDUMP'';</code><br>Not all files may be available.</p>');
        wa('<pre>');
        wa(sql_rec.file_10046_10053_udump);
        wa(sql_rec.file_10053_udump);
        wa(sql_rec.file_10053_xtract_udump);
        wa('</pre>');

        wa('<p>Files generated under SQLT$BDUMP directory.<br>To locate SQLT$BDUMP: <code>SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$BDUMP'';</code><br>Not all files may be available.</p>');
        wa('<pre>');
        wa('*'||REPLACE(l_prefix2, 'sqlt')||'_*.trc');
        wa('</pre>');

        IF sql_rec.rdbms_release >= 11 THEN
          wa('<p>Files generated under SQLT$STAGE directory.<br>To locate SQLT$STAGE: <code>SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$STAGE'';</code><br>Not all files may be available.</p>');
          wa('<pre>');
          wa(l_prefix2||'_tcb_*');
          wa('README.txt');
          wa('</pre>');
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.gen_files:'||SQLERRM);
    END;

    /* -------------------------
     * Footer and closure
     * ------------------------- */
    BEGIN
      wa('
<hr size="3">
<font class="f">'||NOTE_NUMBER||' '||s_file_rec.filename||' '||TO_CHAR(SYSDATE, LOAD_DATE_FORMAT)||'</font>
</body>
</html>');

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id  => p_statement_id,
        p_file_type     => 'README_REPORT_HTML',
        p_filename      => s_file_rec.filename,
        p_statement_id2 => p_group_id,
        p_db_link       => p_db_link,
        p_file_size     => s_file_rec.file_size,
        p_file_text     => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_sqlt_readme = s_file_rec.filename
       WHERE statement_id = p_statement_id;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_html.close:'||SQLERRM);
    END;

    write_log('<- readme_report_html');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('readme_report_html:'||SQLERRM);
  END readme_report_html;

  /*************************************************************************************/

  /* -------------------------
   *
   * public readme_report_txt
   *
   * called by: sqlt$i.xtract, sqlt$i.remote_xtract, sqlt$i.xecute_end and sqlt$i.xplain_end
   *
   * ------------------------- */
  PROCEDURE readme_report_txt (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_statid VARCHAR2(32767);
    l_statement_id VARCHAR2(32767);
    l_statement_id2 VARCHAR2(32767);
    l_prefix VARCHAR2(32767);
    l_prefix2 VARCHAR2(32767);
    l_count_sta NUMBER;
    l_count_spm NUMBER;
    l_count_sts NUMBER;
    l_out_file_identifier VARCHAR2(32767);

    /* -------------------------
     *
     * private readme_report_txt.wa - write append
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

  BEGIN
    write_log('-> readme_report_txt');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_group_id IS NULL THEN
      l_statement_id := sqlt$a.get_statement_id_c(p_statement_id);
      l_prefix := 'sqlt_s'||l_statement_id||l_out_file_identifier;
      l_statement_id2 := l_statement_id;
      l_prefix2 := l_prefix;
    ELSE
      l_statement_id := sqlt$a.get_statement_id_c(p_statement_id);
      l_prefix := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier;
      l_statement_id2 := sqlt$a.get_statement_id_c(p_group_id);
      l_prefix2 := 'sqlt_s'||l_statement_id2||l_out_file_identifier;
    END IF;

    IF p_file_prefix IS NULL THEN
      s_file_rec.filename := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_readme.txt';
    ELSE
      s_file_rec.filename := p_file_prefix||'_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_readme.txt';
    END IF;

    IF p_group_id IS NULL THEN
      l_statid := sql_rec.statid;
    ELSE
      l_statid := 's'||sqlt$a.get_statement_id_c(p_group_id)||'_'||'s'||sqlt$a.get_statement_id_c(p_statement_id);
    END IF;

    /* -------------------------
     * Header
     * ------------------------- */
    BEGIN
      s_file_rec.file_text := NOTE_NUMBER||' SQLT '||sql_rec.method||' '||sqlt$a.get_param('tool_version')||' Report: '||s_file_rec.filename||'

Instructions to perform the following:

o Export SQLT repository
o Import SQLT repository
o Using SQLT COMPARE
o Restore CBO schema statistics
o Restore CBO system statistics
o Implement SQLT Test Case (TC)
o Create TC with no SQLT dependencies';

      SELECT COUNT(*)
        INTO l_count_sta
        FROM sqlt$_stgtab_sqlprof
       WHERE statid = l_statid;

      IF l_count_sta > 0 THEN
        wa('o Restore SQL Profile');
      END IF;

      SELECT COUNT(*)
        INTO l_count_spm
        FROM sqlt$_stgtab_baseline
       WHERE statid = l_statid;

      IF l_count_spm > 0 THEN
        wa('o Restore SQL Plan Baseline');
      END IF;

      SELECT COUNT(*)
        INTO l_count_sts
        FROM sqlt$_stgtab_sqlset
       WHERE statid = l_statid;

      IF l_count_sts > 0 AND sql_rec.rdbms_version >= '11.2' THEN
        wa('o Restore SQL Set');
      END IF;

      IF l_count_sts > 0 THEN
        wa('o Create SQL Plan Baseline from SQL Set');
      END IF;

      IF NVL(sql_rec.apps_release, 'NO') = 'NO' AND NVL(sql_rec.siebel, 'NO') = 'NO' AND NVL(sql_rec.psft, 'NO') = 'NO' THEN
        wa('o Gather CBO statistics without Histograms (using SYS.DBMS_STATS)');
        wa('o Gather CBO statistics with Histograms (using SYS.DBMS_STATS)');
      ELSIF sql_rec.apps_release IS NOT NULL THEN
        wa('o Gather CBO statistics for EBS');
      ELSIF sql_rec.siebel = 'YES' THEN
        wa('o Gather CBO statistics for SIEBEL');
      ELSIF sql_rec.psft = 'YES' THEN
        wa('o Gather CBO statistics for PSFT (using PSCBO_STATS)');
        wa('o Gather CBO statistics without Histograms (using SYS.DBMS_STATS)');
        wa('o Gather CBO statistics with Histograms (using SYS.DBMS_STATS)');
      END IF;

      IF p_db_link IS NULL THEN
        wa('o List generated files');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.header:'||SQLERRM);
    END;

    /* -------------------------
     * Export SQLT repository
     * ------------------------- */
    BEGIN
      wa('
********************************************************************************

Export SQLT repository
~~~~~~~~~~~~~~~~~~~~~~');

      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        wa('
Steps:
~~~~~

1. Unzip '||l_prefix2||'_driver.zip in order to get '||l_prefix2||'_export_parfile.txt.

2. Copy '||l_prefix2||'_export_parfile.txt to SOURCE server (TEXT).

3. Execute export on server:

expdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||sqlt$a.get_param('connect_identifier')||' parfile='||l_prefix2||'_export_parfile.txt
');
      ELSE
        wa('
Steps:
~~~~~

1. Unzip '||l_prefix2||'_driver.zip in order to get '||l_prefix2||'_export_parfile.txt.

2. Copy '||l_prefix2||'_export_parfile.txt to SOURCE server (TEXT).

3. Execute export on server:

exp '||LOWER(TOOL_REPOSITORY_SCHEMA)||sqlt$a.get_param('connect_identifier')||' parfile='||l_prefix2||'_export_parfile.txt
');
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.export:'||SQLERRM);
    END;

    /* -------------------------
     * Import SQLT repository
     * ------------------------- */
    BEGIN
      wa('
********************************************************************************

Import SQLT repository
~~~~~~~~~~~~~~~~~~~~~~');

      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        wa('
Steps:
~~~~~

1. Unzip '||l_prefix2||'_tc.zip in order to get '||l_prefix2||'_expdp.dmp.

2. Copy '||l_prefix2||'_expdp.dmp to SQLT$STAGE directory (BINARY).

3. Execute import on server:

impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp

Notes:
~~~~~
To locate SQLT$STAGE use:
SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$STAGE'';

To change location of SQLT$STAGE use:
sqlt/utl/sqltcdirs.sql.

You can execute '||l_prefix2||'_import.sh instead.');
      ELSE
        wa('
Steps:
~~~~~
1. Unzip '||l_prefix2||'_tc.zip in order to get '||l_prefix2||'_expdp.dmp.

2. Copy '||l_prefix2||'_exp.dmp to the server (BINARY).

3. Execute import on server:

imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp TABLES=sqlt% IGNORE=Y

Notes:
~~~~~
You can execute '||l_prefix2||'_import.sh instead.');
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.import:'||SQLERRM);
    END;

    /* -------------------------
     * Using SQLT COMPARE
     * ------------------------- */
    BEGIN
      wa('
********************************************************************************

Using SQLT COMPARE
~~~~~~~~~~~~~~~~~~

You need to have a set of SQLT files (sqlt_sNNNNN_method.zip) from two
executions of the SQLT tool. They can be from any method (XTRACT, XECUTE or
XPLAIN) and they can be from the same or different systems. They do not have to
be from same release or platform. For example, a SQLT from 10g on Linux and a
SQLT from 11g on Unix can be compared.

To use the COMPARE method you need 3 systems: SOURCE1, SOURCE2 and COMPARE.
The 3 could all be different, or all the same. For example, SOURCE1 could be
PROD, SOURCE2 DEV and COMPARE DEV. In other words, you could do the COMPARE in
one of the sources. Or the COMPARE could be done on a 3rd and remote system.

Basically you need to restore the SQLT repository from both SOURCES into the
COMPARE system. In most cases it means "restoring" the SQLT repository from at
least one SOURCE into the COMPARE. Once you have both SQLT repositories into the
COMPARE system, then you can execute this method.

Steps:
~~~~~');
      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        wa('
1. Unzip '||l_prefix2||'_tc.zip from this SOURCE in order to get '||l_prefix2||'_expdp.dmp.

2. Copy '||l_prefix2||'_expdp.dmp to SQLT$STAGE directory (BINARY).

3. Execute import on server:

impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp

4. Perform the equivalent steps for the 2nd SOURCE if needed. Follow its readme.

5. Execute the COMPARE method connecting into SQL*Plus as SYS.

START sqlt/run/sqltcompare.sql

Notes:
~~~~~
To locate SQLT$STAGE use:
SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$STAGE'';
To change location of SQLT$STAGE use: sqlt/utl/sqltcdirs.sql.');
      ELSE
        wa('
1. Unzip '||l_prefix2||'_tc.zip from this SOURCE in order to get '||l_prefix2||'_expdp.dmp.

2. Copy '||l_prefix2||'_exp.dmp to the server (BINARY).

3. Execute import on server:

imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp TABLES=sqlt% IGNORE=Y

4. Perform the equivalent steps for the 2nd SOURCE if needed. Follow its readme.

5. Execute the COMPARE method connecting into SQL*Plus as SYS.

START sqlt/run/sqltcompare.sql');
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.compare:'||SQLERRM);
    END;

    /* -------------------------
     * Restore CBO schema statistics
     * ------------------------- */
    BEGIN
      wa('
********************************************************************************

Restore CBO schema statistics
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CBO schema object statistics can be restored from the local SQLT repository, or
from an imported repository. Restoring CBO statistics associates them to
existing and compatible schema objects. These objects can be owned by the
original schema owner or by a different one. For example, table T is owned by
user U in SOURCE and by user TC'||l_statement_id||' in TARGET.

When using restore script below, the second parameter allows to remap the schema
object statistics to a different user. Be aware that target user and schema
objects must exist before executing this script. To restore CBO schema object
statistics into the original schema owner(s) pass "null" (or just hit the
"Enter" key) when the second parameter is requested.

Steps:
~~~~~

1. Execute restore script connecting as SYSDBA:

START sqlt/utl/sqltimp.sql '||l_statid||' TC'||l_statement_id);

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.obj_stats:'||SQLERRM);
    END;

    /* -------------------------
     * Restore CBO system statistics
     * ------------------------- */
    BEGIN
      wa('
********************************************************************************

Restore CBO system statistics
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Steps:
~~~~~

1. Execute restore script connecting as SYSDBA:

START '||l_prefix||'_system_stats.sql');

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.sys_stats:'||SQLERRM);
    END;

    /* -------------------------
     * Implement SQLT Test Case (TC)
     * ------------------------- */
    BEGIN
      wa('
********************************************************************************

Implement SQLT Test Case (TC)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

SOURCE and TARGET systems should be similar.
Proceed with Preparation followed by Express or Custom mode.

Preparation:
~~~~~~~~~~~

1. Unzip '||l_prefix2||'_tc.zip in server and navigate to TC directory.

unzip '||l_prefix||'_tc.zip -d TC'||l_statement_id||'
cd TC'||l_statement_id||'

Express (XPRESS) mode:
~~~~~~~~~~~~~~~~~~~~~

1. Review and execute xpress.sh from OS or xpress.sql from sqlplus.

Option 1: ./xpress.sh

Option 2: sqlplus / as sysdba '||ARROBA||'xpress.sql


Custom mode:
~~~~~~~~~~~

1. Create test case user and schema objects connecting as SYSDBA:

sqlplus / as sysdba
START '||l_prefix||'_metadata.sql

2. Purge pre-existing s'||l_statement_id||' from local SQLT repository connected as SYSDBA:

START '||l_prefix||'_purge.sql

3. Import SQLT repository for s'||l_statement_id||' (provide '||UPPER(TOOL_REPOSITORY_SCHEMA)||' password):');

      IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
        wa('
HOS impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp');
      ELSE
        wa('
HOS imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp LOG='||l_prefix2||'_imp.log TABLES=sqlt% IGNORE=Y');
      END IF;

      wa('
4. Restore CBO schema statistics for test case user connected as SYSDBA:

START '||l_prefix||'_restore.sql

5. Restore CBO system statistics connected as SYSDBA:

START '||l_prefix||'_system_stats.sql

6. Set the CBO environment connecting as test case user TC'||l_statement_id||'
   (include optional test case user suffix):

CONN TC'||l_statement_id||'/TC'||l_statement_id||'
START '||l_prefix||'_set_cbo_env.sql

7. Execute test case.

START tc.sql
');

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.sqlt_tc:'||SQLERRM);
    END;

    /* -------------------------
     * Create TC with no SQLT dependencies
     * ------------------------- */
    BEGIN
      wa('
********************************************************************************

Create TC with no SQLT dependencies
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

After creating a local test case using SQLT files, you can create a stand-alone
TC with no dependencies on SQLT.

Steps:
~~~~~
1. Export TC schema object statistics to staging table within TC schema:

DELETE TC'||l_statement_id||'.CBO_STAT_TAB_4TC;
EXEC SYS.DBMS_STATS.EXPORT_SCHEMA_STATS(ownname => ''TC'||l_statement_id||''', stattab => ''CBO_STAT_TAB_4TC'');

2. Export TC schema object statistics from staging table:

HOS exp TC'||l_statement_id||'/TC'||l_statement_id||' FILE=cbo_stat_tab_4tc.dmp LOG=cbo_stat_tab_4tc.log TABLES=cbo_stat_tab_4tc STATISTICS=NONE

3. Review setup.sql script and adjust if needed.

4. Review readme.txt file and adjust if needed.

5. Create and zip a new directory with the following files:

CBO schema object statistics dump: cbo_stat_tab_4tc.dmp
Plan script:                       plan.sql
Query script:                      q.sql
Instructions:                      readme.txt
Setup script:                      setup.sql
Metadata script:                   '||l_prefix||'_metadata.sql
OPatch (if needed):                '||l_prefix||'_opatch.zip
Set CBO env script (if needed):    '||l_prefix||'_set_cbo_env.sql
System statistics setup:           '||l_prefix||'_system_stats.sql
Test case script:                  tc.sql

6. Test your new stand-alone TC following your own readme.txt in another system.

Note: You may want to use tc_pkg.sql to execute commands above.');

    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.tc:'||SQLERRM);
    END;

    /* -------------------------
     * Restore SQL Profile
     * ------------------------- */
    BEGIN
      IF l_count_sta > 0 THEN
        wa('
********************************************************************************

Restore SQL Profile
~~~~~~~~~~~~~~~~~~~

SOURCE and TARGET systems should be similar.

SQLT exported from SOURCE at least one SQL Profile associated to your query.
You can copy it into your TARGET system following these steps.

Steps:
~~~~~

1. Import SQLT repository (only if you haven''t done so as part of another operation like TC creation)
');
        IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
          wa('impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp');
        ELSE
          wa('imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp TABLES=sqlt% IGNORE=Y');
        END IF;

        wa('
2. Create local staging table connecting as SYSDBA:

CREATE TABLE stgtab_sqlprof AS SELECT * FROM &&tool_repository_schema..sqlt$_stgtab_sqlprof WHERE statid = '''||l_statid||''';
ALTER TABLE stgtab_sqlprof DROP COLUMN statid;

3. Copy SQL Profile by following corresponding syntaxt below.');

        FOR i IN (SELECT DISTINCT name, category FROM sqlt$_dba_sql_profiles WHERE statid = l_statid ORDER BY 1, 2)
        LOOP
          wa('
BEGIN
  SYS.DBMS_SQLTUNE.UNPACK_STGTAB_SQLPROF (
    profile_name         => '''||i.name||''',
    profile_category     => '''||i.category||''',
    replace              => TRUE,
    staging_table_name   => ''STGTAB_SQLPROF'',
    staging_schema_owner => USER );
END;'||LF||'/');
        END LOOP;

      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.sta:'||SQLERRM);
    END;

    /* -------------------------
     * Restore SQL Plan Baseline
     * ------------------------- */
    BEGIN
      IF l_count_spm > 0 THEN
        wa('
********************************************************************************

Restore SQL Plan Baseline
~~~~~~~~~~~~~~~~~~~~~~~~~

SOURCE and TARGET systems should be similar.

SQLT exported from SOURCE at least one SQL Plan from SPM/SMB associated to your
query. You can copy it into your TARGET system following these steps.

Steps:
~~~~~

1. Import SQLT repository (only if you haven''t done so as part of another operation like TC creation)
');

        IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
          wa('impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp');
        ELSE
          wa('imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp TABLES=sqlt% IGNORE=Y');
        END IF;

        wa('
2. Restore a SQL Plan from SPM/SMB by following corresponding syntaxt below.');

        FOR i IN (SELECT DISTINCT sql_handle, plan_name FROM sqlt$_dba_sql_plan_baselines WHERE statid = l_statid ORDER BY 1, 2)
        LOOP
          wa('
SET SERVEROUT ON;
DECLARE
  x NUMBER;
BEGIN
  x := SYS.DBMS_SPM.UNPACK_STGTAB_BASELINE (
    table_name  => ''SQLT$_STGTAB_BASELINE'',
    table_owner => '''||TOOL_REPOSITORY_SCHEMA||''',
    sql_handle  => '''||i.sql_handle||''',
    plan_name   => '''||i.plan_name||''',
    action      => '''||l_statid||''' );
  SYS.DBMS_OUTPUT.PUT_LINE(''Plans: ''||x);
END;'||LF||'/
SET SERVEROUT OFF;');
        END LOOP;

      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_text.spm:'||SQLERRM);
    END;

    /* -------------------------
     * Restore SQL Set
     * ------------------------- */
    BEGIN
      IF l_count_sts > 0 AND sql_rec.rdbms_version >= '11.2' THEN
        wa('
********************************************************************************

Restore SQL Set
~~~~~~~~~~~~~~~

SOURCE and TARGET systems should be similar.

SQLT exported from SOURCE at least one SQL Set with a plan associated to your
query. The SQL Set name below includes the plan hash value and its source
(memory or awr).

You can copy a SQL Set into your TARGET system following these steps. After a
SQL Set with one plan is restored, you can proceed to load it as a SQL Plan into
its SQL Baseline.

Steps:
~~~~~

1. Import SQLT repository (only if you haven''t done so as part of another operation like TC creation)
');

        IF sqlt$a.get_param('export_utility') = 'EXPDP' THEN
          wa('impdp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' DIRECTORY=''SQLT$STAGE'' DUMPFILE='||l_prefix2||'_expdp.dmp');
        ELSE
          wa('imp '||LOWER(TOOL_REPOSITORY_SCHEMA)||' FILE='||l_prefix2||'_exp.dmp TABLES=sqlt% IGNORE=Y');
        END IF;

        wa('
2. Copy one SQL Set by following corresponding syntaxt below.');

        FOR i IN (SELECT DISTINCT name, description FROM sqlt$_stgtab_sqlset WHERE statid = l_statid ORDER BY 2)
        LOOP
          wa('
-- '||i.description||'
BEGIN
  SYS.DBMS_SQLTUNE.UNPACK_STGTAB_SQLSET (
    sqlset_name          => '''||i.name||''',
    sqlset_owner         => '''||TOOL_ADMINISTER_SCHEMA||''',
    replace              => TRUE,
    staging_table_name   => ''SQLT$_STGTAB_SQLSET'',
    staging_schema_owner => '''||TOOL_REPOSITORY_SCHEMA||''' );
END;'||LF||'/');
        END LOOP;

      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_text.rsts:'||SQLERRM);
    END;

    /* -------------------------
     * Create SQL Plan Baseline from SQL Set
     * ------------------------- */
    BEGIN
      IF l_count_sts > 0 THEN
        wa('
********************************************************************************

Create SQL Plan Baseline from SQL Set
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

You can load one SQL Plan into its SQL Plan Baseline from a SQL Set created by
SQLT for each plan found in memory or AWR.

This method only works on the same system where SQLT was executed. Unless you
first restore a SQL Set from a different source.

The SQL Set name below includes the plan hash value and its source
(memory or awr). You can load one or more plans into a SQL Plan Baseline.');

        FOR i IN (SELECT DISTINCT name, description FROM sqlt$_stgtab_sqlset WHERE statid = l_statid ORDER BY 2)
        LOOP
          wa('
-- '||i.description||'
SET SERVEROUT ON;
DECLARE
  x NUMBER;
  time DATE := SYSDATE;
  l_planame sys.dba_sql_plan_baselines.plan_name%TYPE;
  l_sql_handle sys.dba_sql_plan_baselines.sql_handle%TYPE;
BEGIN
  DBMS_LOCK.SLEEP(5);
  x := SYS.DBMS_SPM.LOAD_PLANS_FROM_SQLSET (
    sqlset_name  => '''||i.name||''',
    sqlset_owner => '''||TOOL_ADMINISTER_SCHEMA||''' );
  SYS.DBMS_OUTPUT.PUT_LINE(''Plans: ''||x);
  IF x = 1 THEN
    SELECT plan_name, sql_handle
      INTO l_planame, l_sql_handle
      FROM sys.dba_sql_plan_baselines
     WHERE signature = '||sql_rec.signature_sta_unstripped||'
       AND created >= time;
    x := DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
      sql_handle      => l_sql_handle,
      plan_name       => l_planame,
      attribute_name  => ''DESCRIPTION'',
      attribute_value => TRIM('''||i.description||''') );
    x := DBMS_SPM.ALTER_SQL_PLAN_BASELINE (
      sql_handle      => l_sql_handle,
      plan_name       => l_planame,
      attribute_name  => ''PLAN_NAME'',
      attribute_value => UPPER('''||i.name||''') );
    SYS.DBMS_OUTPUT.PUT_LINE(''Renamed: ''||x||'' ''||UPPER('''||i.name||'''));
  END IF;
END;'||LF||'/
SET SERVEROUT OFF;');
        END LOOP;

      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_text.sts:'||SQLERRM);
    END;

    /* -------------------------
     * Gather CBO statistics for EBS
     * ------------------------- */
    BEGIN
      IF sql_rec.apps_release IS NOT NULL THEN
        wa('
********************************************************************************

Gather CBO statistics for EBS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use commands below to generate a fresh set of CBO statistics for the schema
objects accessed by your SQL. Sample sizes are suggested according to current
number of rows in statistics.
');

        wa(gather_stats_all(p_statement_id));
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.apps:'||SQLERRM);
    END;

    /* -------------------------
     * Gather CBO statistics for SIEBEL
     * ------------------------- */
    BEGIN
      IF sql_rec.siebel = 'YES' THEN
        wa('
********************************************************************************

Gather CBO statistics for SIEBEL
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use commands below to generate a fresh set of CBO statistics for the schema
objects accessed by your SQL. Sample sizes are suggested according to current
number of rows in statistics.
');

        wa(gather_stats_all(p_statement_id));
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.siebel:'||SQLERRM);
    END;

    /* -------------------------
     * Gather CBO statistics for PSFT
     * ------------------------- */
    BEGIN
      IF sql_rec.psft = 'YES' THEN
        wa('
********************************************************************************

Gather CBO statistics for PSFT (using PSCBO_STATS)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use commands below to generate a fresh set of CBO statistics for the schema
objects accessed by your SQL. Sample sizes are suggested according to current
number of rows in statistics.
');

        wa(gather_stats_all(p_statement_id));
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.psft:'||SQLERRM);
    END;

    /* -------------------------
     * Gather CBO statistics without Histograms
     * ------------------------- */
    BEGIN
      IF NVL(sql_rec.apps_release, 'NO') = 'NO' AND NVL(sql_rec.siebel, 'NO') = 'NO' /* AND NVL(sql_rec.psft, 'NO') = 'NO' */ THEN
        wa('
********************************************************************************

Gather CBO statistics without Histograms (using SYS.DBMS_STATS)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use commands below to generate a fresh set of CBO statistics for the schema
objects accessed by your SQL. Histograms will be dropped.
');

        wa(gather_stats_all(p_statement_id, 1));
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.no_hist:'||SQLERRM);
    END;

    /* -------------------------
     * Gather CBO statistics with Histograms
     * ------------------------- */
    BEGIN
      IF NVL(sql_rec.apps_release, 'NO') = 'NO' AND NVL(sql_rec.siebel, 'NO') = 'NO' /* AND NVL(sql_rec.psft, 'NO') = 'NO' */ THEN
        wa('
********************************************************************************

Gather CBO statistics with Histograms (using SYS.DBMS_STATS)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Use commands below to generate a fresh set of CBO statistics for the schema
objects accessed by your SQL. Histograms will be generated for some columns.
');

        wa(gather_stats_all(p_statement_id, 2));
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.hist:'||SQLERRM);
    END;

    /* -------------------------
     * List generated files
     * ------------------------- */
    DECLARE
    BEGIN
      IF p_db_link IS NULL THEN
        wa('
********************************************************************************

List generated files
~~~~~~~~~~~~~~~~~~~~
');

        wa('Files generated under current SQL*Plus directory.');
        wa('Not all files may be available.'||LF);
        wa(sql_rec.file_sqlt_main);
        wa(sql_rec.file_sqlt_metadata);
        wa(sql_rec.file_sqlt_metadata1);
        wa(sql_rec.file_sqlt_metadata2);
        wa(sql_rec.file_sqlt_system_stats);
        wa(sql_rec.file_sqlt_schema_stats);
        wa(sql_rec.file_sqlt_set_cbo_env);
        wa(sql_rec.file_sqlt_lite);
        wa(s_file_rec.filename);
        wa(REPLACE(s_file_rec.filename, 'txt', 'html'));
        wa(sql_rec.file_sqlt_tcscript);
        wa(sql_rec.file_sqlt_tcsql);
        wa(sql_rec.file_sqlt_tcbuilder);
        wa(l_prefix2||'_tcb.zip');
        wa(sql_rec.file_remote_driver);
        wa(sql_rec.file_script_output_driver);
        wa(sql_rec.file_tkprof_px_driver);
        wa(sql_rec.file_sqlt_exp_params);
        wa(sql_rec.file_sqlt_exp_params2);
        wa(sql_rec.file_sqlt_exp_driver);
        wa(sql_rec.file_sqlt_imp_script);
        wa(l_prefix2||'_export.zip');
        wa(l_prefix2||'_tc.zip');
        wa(l_prefix2||'_log.zip');
        wa(l_prefix2||'_opatch.zip');
        wa(l_prefix2||'_remote.zip');
        wa(sql_rec.file_sqlt_profile);
        wa(sql_rec.file_sta_report_mem);
        wa(sql_rec.file_sta_script_mem);
        wa(sql_rec.file_sta_report_txt);
        wa(sql_rec.file_sta_script_txt);
        wa(sql_rec.file_sta_report_awr);
        wa(sql_rec.file_sta_script_awr);
        wa(sql_rec.file_sql_detail_active);
        wa(sql_rec.file_mon_report_active);
        wa(sql_rec.file_mon_report_html);
        wa(sql_rec.file_mon_report_text);
        wa(sql_rec.file_trcanlzr_html);
        wa(sql_rec.file_trcanlzr_txt);
        wa(sql_rec.file_trcanlzr_log);
        wa(sql_rec.file_trcanlzr_px_html);
        wa(sql_rec.file_trcanlzr_px_txt);
        wa(sql_rec.file_trcanlzr_px_log);
        wa(sql_rec.file_10046_split);
        wa(sql_rec.file_10053_split);
        wa(sql_rec.file_bde_chk_cbo);
        wa(sql_rec.file_10046_10053);
        wa(sql_rec.file_10053);
        wa(sql_rec.file_10053_xtract);
        IF sql_rec.method = 'XECUTE' THEN
          wa(l_prefix2||'_tkprof_sort.txt');
          wa(l_prefix2||'_tkprof_nosort.txt');
        END IF;
        wa(l_prefix||'_'||LOWER(sql_rec.method)||'.log');
        wa('sqlt'||LOWER(sql_rec.method)||'.log');
        wa(sql_rec.input_filename);
        wa('sqltxhost.log');
        wa('plan.sql');
        wa('10053.sql');
        wa('flush.sql');
        wa('purge.sql');
        wa('restore.sql');
        wa('del_hgrm.sql');
        wa('tc.sql');
        wa('tc_pkg.sql');
        wa('xpress.sql');
        wa('xpress.sh');
        wa('setup.sql');
        wa('q.sql');
        wa('sel.sql');
        wa('sel_aux.sql');
        wa('install.sql');
        wa('install.sh');
        wa('tcx_pkg.sql');

        wa(LF||'Files generated under SQLT$UDUMP directory.');
        wa(sql_rec.file_10046_10053_udump);
        wa(sql_rec.file_10053_udump);
        wa(sql_rec.file_10053_xtract_udump);

        wa(LF||'Files generated under SQLT$BDUMP directory.');
        wa('*'||REPLACE(l_prefix2, 'sqlt')||'_*.trc');

        IF sql_rec.rdbms_release >= 11 THEN
          wa(LF||'Files generated under SQLT$STAGE directory.');
          wa(l_prefix2||'_tcb_*');
          wa('README.txt');
        END IF;

        wa('
Notes:
~~~~~
To locate SQLT$UDUMP:
SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$UDUMP'';

To locate SQLT$BDUMP:
SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$BDUMP'';

To locate SQLT$STAGE:
SELECT directory_path FROM sys.dba_directories WHERE directory_name = ''SQLT$STAGE'';

Not all files may be available.');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.gen_files:'||SQLERRM);
    END;

    /* -------------------------
     * Footer and closure
     * ------------------------- */
    BEGIN
      wa('
********************************************************************************

'||NOTE_NUMBER||' '||s_file_rec.filename||' '||TO_CHAR(SYSDATE, LOAD_DATE_FORMAT));

      s_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_file_rec.file_text);
      sqlt$a.set_file (
        p_statement_id  => p_statement_id,
        p_file_type     => 'README_REPORT_TXT',
        p_filename      => s_file_rec.filename,
        p_statement_id2 => p_group_id,
        p_db_link       => p_db_link,
        p_file_size     => s_file_rec.file_size,
        p_file_text     => s_file_rec.file_text );

      UPDATE sqlt$_sql_statement
         SET file_sqlt_readme_text = s_file_rec.filename
       WHERE statement_id = p_statement_id;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('readme_report_txt.close:'||SQLERRM);
    END;

    write_log('<- readme_report_txt');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('readme_report_txt:'||SQLERRM);
  END readme_report_txt;

  /*************************************************************************************/

END sqlt$r;
/

SET TERM ON;
SHOW ERRORS PACKAGE BODY &&tool_administer_schema..sqlt$r;
