CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..sqlt$d AS
/* $Header: 215187.1 sqcpkgd.pkb 19.0.190426 2019/04/26 Stelios.charalambides@oracle.com carlos.sierra mauro.pagano abel.macias $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  TOOL_NAME        CONSTANT VARCHAR2(32) := '&&tool_name.';
  NUL              CONSTANT CHAR(1)      := CHR(00);
  LF               CONSTANT CHAR(1)      := CHR(10);
  CR               CONSTANT CHAR(1)      := CHR(13);
  TAB              CONSTANT CHAR(1)      := CHR(9);
  AMP              CONSTANT CHAR(1)      := CHR(38);
  CRT              CONSTANT CHAR(1)      := CHR(94);
  MAXSEQUENCE      CONSTANT NUMBER       := 5;

  /*************************************************************************************/

  -- 171004 Extensive replacement of variables to varchar2(257)
  
  /* -------------------------
   *
   * static variables
   *
   * ------------------------- */
  s_rdbms_version VARCHAR2(32767);
  s_insert_list_cellstate VARCHAR2(32767):=null;
  s_select_list_cellstate VARCHAR2(32767):=null;
  s_insert_list_segstat VARCHAR2(32767);
  s_select_list_segstat VARCHAR2(32767);
  s_insert_list_sesevent VARCHAR2(32767);
  s_select_list_sesevent VARCHAR2(32767);
  s_insert_list_sesstat VARCHAR2(32767);
  s_select_list_sesstat VARCHAR2(32767);
  s_insert_list_statname VARCHAR2(32767);
  s_select_list_statname VARCHAR2(32767);
  s_insert_list_pq_slave VARCHAR2(32767);
  s_select_list_pq_slave VARCHAR2(32767);
  s_insert_list_pq_sysstat VARCHAR2(32767);
  s_select_list_pq_sysstat VARCHAR2(32767);
  s_insert_list_px_sysstat VARCHAR2(32767);
  s_select_list_px_sysstat VARCHAR2(32767);
  s_insert_list_px_process VARCHAR2(32767);
  s_select_list_px_process VARCHAR2(32767);
  s_insert_list_px_session VARCHAR2(32767);
  s_select_list_px_session VARCHAR2(32767);
  s_insert_list_pq_sesstat VARCHAR2(32767);
  s_select_list_pq_sesstat VARCHAR2(32767);
  s_insert_list_px_sesstat VARCHAR2(32767);
  s_select_list_px_sesstat VARCHAR2(32767);
  s_insert_list_px_group VARCHAR2(32767);
  s_select_list_px_group VARCHAR2(32767);
  s_collect_perf_stats VARCHAR2(32767);
 -- 142810 relocates pq_tqstat insert and select variables from public
  s_insert_list_pq_tqstat VARCHAR2(32767);
  s_select_list_pq_tqstat VARCHAR2(32767);
-- 19332407 Separate exadata perf collection
  s_collect_exadata_stats VARCHAR2(1):='N';
 
  s_collect_statname VARCHAR2(1) := 'N';

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
    sqlt$a.write_log(p_line_text => p_line_text, p_line_type => p_line_type, p_package => 'D');
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
    sqlt$a.write_error('d:'||p_line_text);
  END write_error;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$sqltext
   *
   * ------------------------- */
  PROCEDURE collect_gv$sqltext (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sqltext');
    get_list_of_columns (
      p_source_table      => 'gv_$sqltext_with_newlines',
      p_destination_table => 'sqlt$_gv$sqltext_with_newlines',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sqltext_with_newlines (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sqltext_with_newlines'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id AND hash_value = :hash_value';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id, IN p_hash_value;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sqltext_with_newlines WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sqltext;

  /*************************************************************************************/

  /* -------------------------
   *
   * private capture_statement
   *
   * called by: sqlt$d.capture_sqltext
   *
   * ------------------------- */
  PROCEDURE capture_statement (
    p_statement_id         IN NUMBER,
    p_string               IN VARCHAR2, -- XECUTE: sqlt_s95979. XPLAIN: EXPLAIN PLAN SET statement_id = '95995' INTO &&tool_repository_schema..sqlt$_sql_plan_table FOR
    p_sql_id_or_hash_value IN VARCHAR2,
    p_child_number         IN VARCHAR2 DEFAULT NULL,
    p_input_filename       IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('-> capture_statement');

    IF p_statement_id IS NULL OR p_sql_id_or_hash_value IS NULL THEN
      RAISE_APPLICATION_ERROR (-20402, 'unique_id "'||p_sql_id_or_hash_value||'" or statement_id "'||p_statement_id||'" are null', TRUE);
    END IF;

    sql_rec := sqlt$a.get_statement(p_statement_id);
    sql_rec.string := p_string;

    sqlt$a.find_sql_in_memory_or_awr (
      p_string                => p_string,
      p_sql_id_or_hash_value  => p_sql_id_or_hash_value,
      p_input_filename        => p_input_filename,
      x_sql_id                => sql_rec.sql_id,
      x_hash_value            => sql_rec.hash_value,
      x_in_memory             => sql_rec.in_memory,
      x_in_awr                => sql_rec.in_awr );

    IF sql_rec.in_memory = 'N' AND sql_rec.in_awr = 'N' THEN
      RAISE_APPLICATION_ERROR (-20404, 'sql with id "'||p_sql_id_or_hash_value||'" was not found in memory nor in awr', TRUE);
    END IF;

    IF sql_rec.in_memory = 'Y' THEN
      write_log('get sql_text from memory using sql_id = "'||sql_rec.sql_id||'" and hash_value = "'||sql_rec.hash_value||'"');

      /*
      IF sqlt$a.get_rdbms_version >= '11.1' THEN
        write_log('using gv$sqlarea');
        SELECT sql_fulltext
          INTO sql_rec.sql_text_clob
          FROM gv$sqlarea
         WHERE sql_id = sql_rec.sql_id
           AND hash_value = sql_rec.hash_value
           AND ROWNUM = 1;
      ELSE -- 10g see bug 5017909
        write_log('using gv$sqltext_with_newlines');
        SYS.DBMS_LOB.CREATETEMPORARY(sql_rec.sql_text_clob, TRUE);
        SYS.DBMS_LOB.OPEN(sql_rec.sql_text_clob, SYS.DBMS_LOB.LOB_READWRITE);
        FOR i IN (SELECT DISTINCT piece, sql_text
                    FROM gv$sqltext_with_newlines
                   WHERE sql_id = sql_rec.sql_id
                     AND hash_value = sql_rec.hash_value
                   ORDER BY 1, 2)
        LOOP
          SYS.DBMS_LOB.WRITEAPPEND(sql_rec.sql_text_clob, LENGTH(i.sql_text), i.sql_text);
        END LOOP;
        SYS.DBMS_LOB.CLOSE(sql_rec.sql_text_clob);
      END IF;
      */

      write_log('using gv$sqltext_with_newlines');
      collect_gv$sqltext(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value);

      SYS.DBMS_LOB.CREATETEMPORARY(sql_rec.sql_text_clob, TRUE);
      SYS.DBMS_LOB.OPEN(sql_rec.sql_text_clob, SYS.DBMS_LOB.LOB_READWRITE);
      FOR i IN (SELECT DISTINCT piece, sql_text
                  FROM sqlt$_gv$sqltext_with_newlines
                 WHERE statement_id = p_statement_id
                 ORDER BY 1, 2)
      LOOP
        SYS.DBMS_LOB.WRITEAPPEND(sql_rec.sql_text_clob, LENGTH(i.sql_text), i.sql_text);
      END LOOP;
      SYS.DBMS_LOB.CLOSE(sql_rec.sql_text_clob);

      write_log('got sql_text from memory');
    ELSIF sql_rec.in_awr = 'Y' THEN
      write_log('get sql_text from awr using sql_id = "'||sql_rec.sql_id||'"');

      DELETE sqlg$_clob;

      l_sql :=
      'INSERT INTO sqlg$_clob '||LF||
      'SELECT sql_text '||LF||
      '  FROM sys.dba_hist_sqltext'||sqlt$a.s_db_link||' '||LF||
      ' WHERE sql_id = :sql_id '||LF||
      '   AND ROWNUM = 1 ';
      write_log(l_sql, 'S');

      EXECUTE IMMEDIATE l_sql
      USING IN sql_rec.sql_id;

      SELECT clob_text
        INTO sql_rec.sql_text_clob
        FROM sqlg$_clob;

      write_log('got sql_text from awr');
    END IF;

    UPDATE sqlt$_sql_statement
       SET sql_id = sql_rec.sql_id,
           hash_value = sql_rec.hash_value,
           string = sql_rec.string,
           in_memory = sql_rec.in_memory,
           in_awr = sql_rec.in_awr,
           sql_text_clob = sql_rec.sql_text_clob
     WHERE statement_id = p_statement_id;

    BEGIN
      IF sql_rec.in_memory = 'Y' THEN
        l_sql :=
        'SELECT /*+ DRIVING_SITE(s) */ '||LF||
        '       s.command_type, a.name '||LF||
        '  FROM gv$sqlarea'||sqlt$a.s_db_link||' s, '||LF||
        '       audit_actions'||sqlt$a.s_db_link||' a '||LF||
        ' WHERE s.sql_id = :sql_id '||LF||
        '   AND s.command_type = a.action '||LF||
        '   AND ROWNUM = 1 ';
        write_log(l_sql, 'S');

        EXECUTE IMMEDIATE l_sql
        INTO sql_rec.command_type, sql_rec.command_type_name
        USING IN sql_rec.sql_id;

        UPDATE sqlt$_sql_statement
           SET command_type = sql_rec.command_type,
               command_type_name = sql_rec.command_type_name
         WHERE statement_id = p_statement_id;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        write_log('command_type: '||SQLERRM);
    END;

    IF sql_rec.sql_id = p_sql_id_or_hash_value AND TO_NUMBER(p_child_number) >= 0 THEN
      BEGIN
        UPDATE sqlt$_sql_statement
           SET xecute_child_number = TO_NUMBER(p_child_number)
         WHERE statement_id = p_statement_id;

        l_sql :=
        'SELECT plan_hash_value '||LF||
        '  FROM v$sql'||sqlt$a.s_db_link||' '||LF||
        ' WHERE sql_id = :sql_id '||LF||
        '   AND child_number = :child_number ';
        write_log(l_sql, 'S');

        EXECUTE IMMEDIATE l_sql
        INTO sql_rec.xecute_plan_hash_value
        USING IN sql_rec.sql_id, IN TO_NUMBER(p_child_number);

        UPDATE sqlt$_sql_statement
           SET xecute_plan_hash_value = sql_rec.xecute_plan_hash_value
         WHERE statement_id = p_statement_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('xecute_plan_hash_value: '||SQLERRM);
      END;
    ELSE
      UPDATE sqlt$_sql_statement
         SET xecute_plan_hash_value = -1,
             xecute_child_number = -1
       WHERE statement_id = p_statement_id;
    END IF;

    COMMIT;
    write_log('<- capture_statement');
  END capture_statement;

  /*************************************************************************************/

  /* -------------------------
   *
   * private strip_sql_text_clob
   *
   * called by: sqlt$d.capture_sqltext and sqlt$d.search_sql_by_sqltext
   *
   * ------------------------- */
  PROCEDURE strip_sql_text_clob (x_sqltext IN OUT NOCOPY CLOB)
  IS
  BEGIN
    x_sqltext := REPLACE(x_sqltext, '/*    */');
    x_sqltext := REPLACE(x_sqltext, '/*   */');
    x_sqltext := REPLACE(x_sqltext, '/*  */');
    x_sqltext := REPLACE(x_sqltext, '/* */');
    x_sqltext := REPLACE(x_sqltext, '/**/');
    x_sqltext := REPLACE(x_sqltext, '--  '||LF, LF);
    x_sqltext := REPLACE(x_sqltext, '-- '||LF, LF);
    x_sqltext := REPLACE(x_sqltext, '--'||LF, LF);
    x_sqltext := REPLACE(x_sqltext, '/*+    */');
    x_sqltext := REPLACE(x_sqltext, '/*+   */');
    x_sqltext := REPLACE(x_sqltext, '/*+  */');
    x_sqltext := REPLACE(x_sqltext, '/*+ */');
    x_sqltext := REPLACE(x_sqltext, '/*+*/');
    x_sqltext := REPLACE(x_sqltext, '--+  '||LF, LF);
    x_sqltext := REPLACE(x_sqltext, '--+ '||LF, LF);
    x_sqltext := REPLACE(x_sqltext, '--+'||LF, LF);
    x_sqltext := REPLACE(x_sqltext, NUL, ' ');
    -- cannot do such 2 replacement since a line could end with a comment using "--"
    --x_sqltext := REPLACE(x_sqltext, CR, ' ');
    --x_sqltext := REPLACE(x_sqltext, TAB, ' ');
  END strip_sql_text_clob;

  /*************************************************************************************/

  /* -------------------------
   *
   * private cut_sql_text_into_pieces
   *
   * called by: sqlt$d.capture_sqltext
   *
   * ------------------------- */
  FUNCTION cut_sql_text_into_pieces (p_sqltext IN CLOB)
  RETURN CLOB
  IS
    l_new CLOB := NULL;
    l_sql_text VARCHAR2(32767);
    l_clob_size NUMBER;
    l_offset NUMBER;
  BEGIN
    IF p_sqltext IS NOT NULL THEN
      l_clob_size := NVL(DBMS_LOB.GETLENGTH(p_sqltext), 0);
      l_offset := 1;
      SYS.DBMS_LOB.CREATETEMPORARY(l_new, TRUE);
      SYS.DBMS_LOB.OPEN(l_new, SYS.DBMS_LOB.LOB_READWRITE);
      -- store in clob as 64 character pieces plus a NUL character at the end of each piece
      WHILE l_offset < l_clob_size
      LOOP
        IF l_clob_size - l_offset > 64 THEN
          l_sql_text := REPLACE(DBMS_LOB.SUBSTR(p_sqltext, 64, l_offset), NUL, ' ');
        ELSE -- last piece
          l_sql_text := REPLACE(DBMS_LOB.SUBSTR(p_sqltext, l_clob_size - l_offset + 1, l_offset), NUL, ' ');
        END IF;
        SYS.DBMS_LOB.WRITEAPPEND(l_new, LENGTH(l_sql_text) + 1, l_sql_text||NUL);
        l_offset := l_offset + 64;
      END LOOP;
      SYS.DBMS_LOB.CLOSE(l_new);
    END IF;
    RETURN l_new;
  END cut_sql_text_into_pieces;

  /*************************************************************************************/

  /* -------------------------
   *
   * public capture_sqltext
   *
   * called by: sqlt$i.xtrsby, sqlt$i.xtract, sqlt$i.remote_xtract, sqlt$i.xecute_end and sqlt$i.xplain_end
   *
   * ------------------------- */
  PROCEDURE capture_sqltext (
    p_statement_id         IN NUMBER,
    p_string               IN VARCHAR2, -- XECUTE: sqlt_s95979. XPLAIN: EXPLAIN PLAN SET statement_id = '95995' INTO &&tool_repository_schema..sqlt$_sql_plan_table FOR
    p_sql_id_or_hash_value IN VARCHAR2,
    p_child_number         IN VARCHAR2 DEFAULT NULL,
    p_input_filename       IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    my_tag VARCHAR2(32767) := 'sqlt$_sql_plan_table FOR';
    my_pointer INTEGER;
  BEGIN
    write_log('=> capture_sqltext');

    capture_statement (
      p_statement_id         => p_statement_id,
      p_string               => p_string,
      p_sql_id_or_hash_value => p_sql_id_or_hash_value,
      p_child_number         => p_child_number,
      p_input_filename       => p_input_filename );

    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sql_rec.sql_text_clob IS NULL THEN
      write_error('sql_text is empty');
      RETURN;
    ELSIF SYS.DBMS_LOB.GETLENGTH(sql_rec.sql_text_clob) = 0 THEN
      write_error('sql_text is empty');
      RETURN;
    END IF;

    sql_rec.sql_text_clob_stripped := sql_rec.sql_text_clob;
    -- remove EXPLAIN PLAN FOR... from XPLAIN
    my_pointer := INSTR(UPPER(sql_rec.sql_text_clob_stripped), UPPER(my_tag));
    IF my_pointer > 0 THEN
      sql_rec.sql_text_clob_stripped := SUBSTR(sql_rec.sql_text_clob_stripped, my_pointer + LENGTH(my_tag) + 1);
    END IF;

    -- remove unique_id token from XECUTE
    sql_rec.sql_text_clob_stripped := REPLACE(sql_rec.sql_text_clob_stripped, p_string);
    sql_rec.sql_text_clob_stripped := REPLACE(sql_rec.sql_text_clob_stripped, 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id));
    sql_rec.sql_text_clob_stripped := REPLACE(sql_rec.sql_text_clob_stripped, CRT||CRT||'unique_id');
    sql_rec.sql_text_clob_stripped := REPLACE(sql_rec.sql_text_clob_stripped, AMP||AMP||'unique_id');

    -- clean up after removing unique_id token
    strip_sql_text_clob(sql_rec.sql_text_clob_stripped);

    -- prepares sql_text to be used by sqltprofile
    sql_rec.sql_text_in_pieces := cut_sql_text_into_pieces(sql_rec.sql_text_clob_stripped);

    -- get length of clobs
    sql_rec.sql_length := SYS.DBMS_LOB.GETLENGTH(sql_rec.sql_text_clob_stripped);
    sql_rec.sql_length_in_pieces := SYS.DBMS_LOB.GETLENGTH(sql_rec.sql_text_in_pieces);

    -- sql_text is just first 1000 characters
    sql_rec.sql_text := SYS.DBMS_LOB.SUBSTR(sql_rec.sql_text_clob_stripped, 1000);
    sql_rec.sql_text := REPLACE(sql_rec.sql_text, LF, ' '); -- make it flat
    sql_rec.sql_text := REPLACE(sql_rec.sql_text, TAB, ' '); -- make it flat

    -- signature for stored outlines
    BEGIN
      IF sql_rec.sql_length <= 32767 THEN
	     -- 170910
		 execute immediate 'BEGIN '||
                           ' DBMS_OUTLN_EDIT.GENERATE_SIGNATURE ('||
                           ' sqltxt    => :sql_text_clob,'||
                           ' signature => :signature_so ); '||
                           ' END;' 
        using sql_rec.sql_text_clob_stripped, out sql_rec.signature_so ;	  
      ELSE
        sql_rec.signature_so := NULL;
        --write_error('Cannot call DBMS_OUTLN_EDIT.GENERATE_SIGNATURE on a sqltext with length of '||sql_rec.sql_length);
        write_log('Cannot call DBMS_OUTLN_EDIT.GENERATE_SIGNATURE on a sqltext with length of '||sql_rec.sql_length);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        sql_rec.signature_so := NULL;
        --write_error(SQLERRM);
        --write_error('Error returned by DBMS_OUTLN_EDIT.GENERATE_SIGNATURE on a sqltext with length of '||sql_rec.sql_length);
        write_log('** '||SQLERRM);
        write_log('Error returned by DBMS_OUTLN_EDIT.GENERATE_SIGNATURE on a sqltext with length of '||sql_rec.sql_length);
    END;

    -- signature for sql profiles (literals not transformed to binds)
    BEGIN
      sql_rec.signature_sta :=
      SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE (
         sql_text    => sql_rec.sql_text_clob_stripped,
         force_match => FALSE );
    EXCEPTION
      WHEN OTHERS THEN
        sql_rec.signature_sta := NULL;
        write_error(SQLERRM);
        write_error('Error returned by SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE on a sqltext with length of '||sql_rec.sql_length||' and force_match FALSE');
    END;

    -- signature for sql profiles (literals transformed to binds)
    BEGIN
      sql_rec.signature_sta_force_match :=
      SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE (
         sql_text    => sql_rec.sql_text_clob_stripped,
         force_match => TRUE );
    EXCEPTION
      WHEN OTHERS THEN
        sql_rec.signature_sta_force_match := NULL;
        write_error(SQLERRM);
        write_error('Error returned by SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE on a sqltext with length of '||sql_rec.sql_length||' and force_match TRUE');
    END;

    UPDATE sqlt$_sql_statement SET
      sql_text_clob_stripped = sql_rec.sql_text_clob_stripped,
      sql_length = sql_rec.sql_length,
      sql_text_in_pieces = sql_rec.sql_text_in_pieces,
      sql_length_in_pieces = sql_rec.sql_length_in_pieces,
      sql_text = sql_rec.sql_text,
      signature_so = sql_rec.signature_so,
      signature_sta = sql_rec.signature_sta,
      signature_sta_force_match = sql_rec.signature_sta_force_match
    WHERE statement_id = p_statement_id;

    sql_rec.sql_length_unstripped := SYS.DBMS_LOB.GETLENGTH(sql_rec.sql_text_clob);
    IF sql_rec.sql_length_unstripped - sql_rec.sql_length > 10 THEN
      -- signature for stored outlines
      BEGIN
        IF sql_rec.sql_length_unstripped <= 32767 THEN
		 -- 170910
		 execute immediate 'BEGIN '||
                           ' DBMS_OUTLN_EDIT.GENERATE_SIGNATURE ('||
                           ' sqltxt    => :sql_text_clob,'||
                           ' signature => :signature_so ); '||
                           ' END;' 
        using sql_rec.sql_text_clob, out sql_rec.signature_so_unstripped ;
        ELSE
          sql_rec.signature_so_unstripped := NULL;
          --write_error('Cannot call DBMS_OUTLN_EDIT.GENERATE_SIGNATURE on unstripped sqltext with length of '||sql_rec.sql_length_unstripped);
          write_log('Cannot call DBMS_OUTLN_EDIT.GENERATE_SIGNATURE on unstripped sqltext with length of '||sql_rec.sql_length_unstripped);
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          sql_rec.signature_so_unstripped := NULL;
          --write_error(SQLERRM);
          --write_error('Error returned by DBMS_OUTLN_EDIT.GENERATE_SIGNATURE on unstripped sqltext with length of '||sql_rec.sql_length_unstripped);
          write_log('** '||SQLERRM);
          write_log('Error returned by DBMS_OUTLN_EDIT.GENERATE_SIGNATURE on unstripped sqltext with length of '||sql_rec.sql_length_unstripped);
      END;

      -- signature for sql profiles (literals not transformed to binds)
      BEGIN
        sql_rec.signature_sta_unstripped :=
        SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE (
           sql_text    => sql_rec.sql_text_clob,
           force_match => FALSE );
      EXCEPTION
        WHEN OTHERS THEN
          sql_rec.signature_sta_unstripped := NULL;
          write_error(SQLERRM);
          write_error('Error returned by SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE on unstripped sqltext with length of '||sql_rec.sql_length_unstripped||' and force_match FALSE');
      END;

      -- signature for sql profiles (literals transformed to binds)
      BEGIN
        sql_rec.signature_sta_fm_unstripped :=
        SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE (
           sql_text    => sql_rec.sql_text_clob,
           force_match => TRUE );
      EXCEPTION
        WHEN OTHERS THEN
          sql_rec.signature_sta_fm_unstripped := NULL;
          write_error(SQLERRM);
          write_error('Error returned by SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE on unstripped sqltext with length of '||sql_rec.sql_length_unstripped||' and force_match TRUE');
      END;
    ELSE
      sql_rec.signature_so_unstripped := sql_rec.signature_so;
      sql_rec.signature_sta_unstripped := sql_rec.signature_sta;
      sql_rec.signature_sta_fm_unstripped := sql_rec.signature_sta_force_match;
    END IF;

    UPDATE sqlt$_sql_statement SET
      sql_length_unstripped = sql_rec.sql_length_unstripped,
      signature_so_unstripped = sql_rec.signature_so_unstripped,
      signature_sta_unstripped = sql_rec.signature_sta_unstripped,
      signature_sta_fm_unstripped = sql_rec.signature_sta_fm_unstripped
    WHERE statement_id = p_statement_id;

    COMMIT;
    write_log(sql_rec.sql_text);
    write_log('<= capture_sqltext');
  END capture_sqltext;

  /*************************************************************************************/

  /* -------------------------
   *
   * public search_sql_by_sqltext
   *
   * called by: sqlt$i.xplain_end
   *
   * ------------------------- */
  PROCEDURE search_sql_by_sqltext (p_statement_id IN NUMBER)
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_sql_fulltext CLOB;
    l_found_it BOOLEAN;
    l_found_in_awr BOOLEAN;
  BEGIN
    write_log('=> search_sql_by_sqltext');

    IF sqlt$a.get_param('search_sql_by_sqltext') = 'Y' THEN
      sql_rec := sqlt$a.get_statement(p_statement_id);

      l_found_it := FALSE;
      l_found_in_awr := FALSE;
      write_log('searching in memory');
      FOR i IN (SELECT sql_id, hash_value, sql_fulltext
                  FROM gv$sqlarea
                 WHERE sql_text = sql_rec.sql_text)
      LOOP
        IF sql_rec.sql_length <= 1000 AND SYS.DBMS_LOB.GETLENGTH(i.sql_fulltext) <= 1000 THEN
          l_found_it := TRUE;
          IF sql_rec.sql_id <> i.sql_id OR sql_rec.hash_value <> i.hash_value THEN
            sql_rec.sql_id_unstripped := sql_rec.sql_id;
            sql_rec.hash_value_unstripped := sql_rec.hash_value;
          END IF;
          sql_rec.sql_id := i.sql_id;
          sql_rec.hash_value := i.hash_value;
          write_log('found in memory (text <= 1000)');
          EXIT;
        END IF;

        IF SYS.DBMS_LOB.GETLENGTH(i.sql_fulltext) BETWEEN TRUNC(sql_rec.sql_length * 0.95) AND CEIL(sql_rec.sql_length * 1.05) THEN
          /*
          IF sqlt$a.get_rdbms_version >= '11.1' THEN
            l_sql_fulltext := i.sql_fulltext;
          ELSE -- 10g see bug 5017909
            SYS.DBMS_LOB.CREATETEMPORARY(l_sql_fulltext, TRUE);
            SYS.DBMS_LOB.OPEN(l_sql_fulltext, SYS.DBMS_LOB.LOB_READWRITE);
            FOR j IN (SELECT DISTINCT piece, sql_text
                        FROM gv$sqltext_with_newlines
                       WHERE sql_id = i.sql_id
                         AND hash_value = i.hash_value
                       ORDER BY 1, 2)
            LOOP
              SYS.DBMS_LOB.WRITEAPPEND(l_sql_fulltext, LENGTH(j.sql_text), j.sql_text);
            END LOOP;
            SYS.DBMS_LOB.CLOSE(l_sql_fulltext);
          END IF;
          */

          SYS.DBMS_LOB.CREATETEMPORARY(l_sql_fulltext, TRUE);
          SYS.DBMS_LOB.OPEN(l_sql_fulltext, SYS.DBMS_LOB.LOB_READWRITE);
          FOR j IN (SELECT DISTINCT piece, sql_text
                      FROM gv$sqltext_with_newlines
                     WHERE sql_id = i.sql_id
                       AND hash_value = i.hash_value
                     ORDER BY 1, 2)
          LOOP
            SYS.DBMS_LOB.WRITEAPPEND(l_sql_fulltext, LENGTH(j.sql_text), j.sql_text);
          END LOOP;
          SYS.DBMS_LOB.CLOSE(l_sql_fulltext);

          strip_sql_text_clob(l_sql_fulltext);

          IF SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(l_sql_fulltext, FALSE) = sql_rec.signature_sta THEN
            SYS.DBMS_LOB.FREETEMPORARY(l_sql_fulltext);
            l_found_it := TRUE;
            IF sql_rec.sql_id <> i.sql_id OR sql_rec.hash_value <> i.hash_value THEN
              sql_rec.sql_id_unstripped := sql_rec.sql_id;
              sql_rec.hash_value_unstripped := sql_rec.hash_value;
            END IF;
            sql_rec.sql_id := i.sql_id;
            sql_rec.hash_value := i.hash_value;
            write_log('sql found in memory using signature "'||sql_rec.signature_sta||'" out of sql_text');
            EXIT;
          END IF;
          SYS.DBMS_LOB.FREETEMPORARY(l_sql_fulltext);
        END IF;
      END LOOP;

      IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param_n('c_awr_hist_days') > 0  THEN
        write_log('searching in awr');
        FOR i IN (SELECT sql_id, sql_text
                    FROM sys.dba_hist_sqltext
                   WHERE dbid = sql_rec.database_id)
        LOOP
          IF sql_rec.sql_length <= 1000 AND SYS.DBMS_LOB.GETLENGTH(i.sql_text) <= 1000 THEN
            IF TO_CHAR(i.sql_text) = sql_rec.sql_text THEN
              IF NOT l_found_it THEN
                IF sql_rec.sql_id <> i.sql_id THEN
                  sql_rec.sql_id_unstripped := sql_rec.sql_id;
                  sql_rec.hash_value_unstripped := sql_rec.hash_value;
                END IF;
                sql_rec.sql_id := i.sql_id;
                sql_rec.hash_value := NULL;
              END IF;
              l_found_it := TRUE;
              l_found_in_awr := TRUE;
              write_log('sql found in awr using sql_text');
              EXIT;
            END IF;
          END IF;

          IF SYS.DBMS_LOB.GETLENGTH(i.sql_text) BETWEEN TRUNC(sql_rec.sql_length * 0.98) AND CEIL(sql_rec.sql_length * 1.02) THEN
            l_sql_fulltext := i.sql_text;
            strip_sql_text_clob(l_sql_fulltext);

            IF SYS.DBMS_SQLTUNE.SQLTEXT_TO_SIGNATURE(l_sql_fulltext, FALSE) = sql_rec.signature_sta THEN
              IF NOT l_found_it THEN
                IF sql_rec.sql_id <> i.sql_id THEN
                  sql_rec.sql_id_unstripped := sql_rec.sql_id;
                  sql_rec.hash_value_unstripped := sql_rec.hash_value;
                END IF;
                sql_rec.sql_id := i.sql_id;
                sql_rec.hash_value := NULL;
              END IF;
              l_found_it := TRUE;
              l_found_in_awr := TRUE;
              write_log('sql found in awr using signature "'||sql_rec.signature_sta||'" out of sql_text');
              EXIT;
            END IF;
          END IF;
        END LOOP;
      END IF;

      IF l_found_it THEN
        write_log('sql_text was found. sql_id = "'||sql_rec.sql_id||'", hash_value = "'||sql_rec.hash_value||'"');
        UPDATE sqlt$_sql_statement SET
          sql_id = sql_rec.sql_id,
          hash_value = sql_rec.hash_value,
          sql_id_found_using_sqltext = 'Y'
        WHERE statement_id = p_statement_id;

        IF l_found_in_awr THEN
          UPDATE sqlt$_sql_statement SET
            in_awr = 'Y'
          WHERE statement_id = p_statement_id;
        END IF;

        IF sql_rec.sql_id_unstripped IS NOT NULL OR sql_rec.hash_value_unstripped IS NOT NULL THEN
          UPDATE sqlt$_sql_statement SET
            sql_id_unstripped = sql_rec.sql_id_unstripped,
            hash_value_unstripped = sql_rec.hash_value_unstripped
          WHERE statement_id = p_statement_id;
        END IF;
      ELSE
        write_log('sql_text was not found in memory nor awr');
        UPDATE sqlt$_sql_statement SET
          sql_id_found_using_sqltext = 'N'
        WHERE statement_id = p_statement_id;
      END IF;

      COMMIT;
    ELSE
      write_log('skip search_sql_by_sqltext as per parameter "search_sql_by_sqltext"');
    END IF;

    write_log('<= search_sql_by_sqltext');
  EXCEPTION
    WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error('could not search sql_id using sqltext');
  END search_sql_by_sqltext;

  /*************************************************************************************/

  /* -------------------------
   *
   * public capture_xplain_plan_hash_value
   *
   * called by sqlt$i.explain_plan_and_10053 and sqlt$i.xplain_end
   *
   * ------------------------- */
  PROCEDURE capture_xplain_plan_hash_value (
    p_statement_id IN NUMBER,
    p_string       IN VARCHAR2 ) -- XTRACT and XECUTE: EXPLAIN PLAN SET statement_id = '''||sqlt$a.get_statement_id_c(p_statement_id)||''' INTO &&tool_repository_schema..sqlt$_sql_plan_table FOR
  IS
    l_plan_hash_value NUMBER;
    l_optimizer_cost  NUMBER;
    l_sql_id          VARCHAR2(13);
    sql_rec sqlt$_sql_statement%ROWTYPE;
  BEGIN
    write_log('-> capture_xplain_plan_hash_value');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    SELECT plan_hash_value, optimizer_cost, sql_id
      INTO l_plan_hash_value, l_optimizer_cost, l_sql_id
      FROM v$sql
     WHERE sql_text LIKE p_string||'%'
       AND ROWNUM = 1;

    UPDATE sqlt$_sql_statement
       SET xplain_plan_hash_value = l_plan_hash_value
     WHERE statement_id = p_statement_id;

    IF l_sql_id <> sql_rec.sql_id THEN
      UPDATE sqlt$_sql_statement
         SET xplain_sql_id = l_sql_id
       WHERE statement_id = p_statement_id;
    END IF;

    COMMIT;

    write_log('<- capture_xplain_plan_hash_value "'||l_plan_hash_value||'" for xplain_sql_id "'||l_sql_id||'" with cost of "'||l_optimizer_cost||'"');
  EXCEPTION
    WHEN OTHERS THEN
      write_log('sql_text not found in V$SQL: "'||p_string||'%"');
  END capture_xplain_plan_hash_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_list_of_columns
   * 22170173 Add DBMS_ASSERT.NOOP
   * ------------------------- */
  PROCEDURE get_list_of_columns (
    p_source_owner      IN  VARCHAR2 DEFAULT 'SYS',
    p_source_table      IN  VARCHAR2,
    p_source_alias      IN  VARCHAR2 DEFAULT NULL,
    p_destination_owner IN  VARCHAR2 DEFAULT TOOL_REPOSITORY_SCHEMA,
    p_destination_table IN  VARCHAR2,
    x_insert_list       OUT VARCHAR2,
    x_select_list       OUT VARCHAR2 )
  IS
    l_alias VARCHAR2(32767);
	t_insert_list VARCHAR2(32727);
	t_select_list VARCHAR2(32727);
  BEGIN
    t_insert_list := NULL;
    t_select_list := NULL;
    IF p_source_table IS NULL OR p_destination_table IS NULL THEN
      RETURN;
    END IF;

    IF p_source_alias IS NULL THEN
      l_alias := NULL;
    ELSE
      l_alias := LOWER(p_source_alias)||'.';
    END IF;

    FOR i IN (SELECT LOWER(d.column_name) column_name,
                     s.data_type          s_data_type,
                     d.data_type          d_data_type,
                     s.data_length        s_data_length,
                     d.data_length        d_data_length
                FROM sys.dba_tab_columns s,
                     sys.dba_tab_columns d
               WHERE s.owner       = UPPER(p_source_owner)
                 AND s.table_name  = UPPER(p_source_table)
                 AND s.column_name NOT IN ('STATEMENT_ID', 'STATID')
                 AND d.owner       = UPPER(p_destination_owner)
                 AND d.table_name  = UPPER(p_destination_table)
                 AND s.column_name = d.column_name
               ORDER BY
                     d.column_id)
    LOOP
      IF sqlt$a.get_rdbms_release < 11 AND i.s_data_type = 'LONG' AND i.column_name = 'high_value' THEN
        NULL; -- ORA-00932: inconsistent datatypes: expected - got LONG on sqlt$_dba_*_*partitions
      ELSIF sqlt$a.s_db_link IS NOT NULL AND (UPPER(p_source_table) LIKE '%V$%' OR UPPER(p_source_table) LIKE '%V_$%') AND i.s_data_type = 'CLOB' THEN
        NULL; -- ORA-64202: remote temporary or abstract LOB locator is encountered
      ELSIF sqlt$a.s_db_link IS NOT NULL AND (UPPER(p_source_table) LIKE '%V$%' OR UPPER(p_source_table) LIKE '%V_$%') AND i.s_data_type = 'LONG' THEN
        NULL; -- ORA-00997: illegal use of LONG datatype
      ELSE
        t_insert_list := t_insert_list||', '||i.column_name;
        IF i.s_data_type = 'VARCHAR2' AND i.d_data_type = 'VARCHAR2' AND i.s_data_length > i.d_data_length THEN
          t_select_list := t_select_list||', SUBSTR('||l_alias||i.column_name||', 1, '||i.d_data_length||')';
        ELSIF i.s_data_type = 'LONG' AND i.d_data_type = 'CLOB' THEN
          t_select_list := t_select_list||', TO_LOB('||l_alias||i.column_name||')';
        ELSIF i.s_data_type = 'VARCHAR2' AND i.d_data_type = 'CLOB' 
		   OR i.s_data_type like '%XMLTYPE%'  AND i.d_data_type = 'CLOB' THEN -- 150828 insert xmltype into clob
          t_select_list := t_select_list||', TO_CLOB('||l_alias||i.column_name||')';
        ELSIF i.s_data_type = 'CLOB' AND i.d_data_type = 'VARCHAR2' THEN
          t_select_list := t_select_list||', SUBSTR(DBMS_LOB.SUBSTR('||l_alias||i.column_name||'), 1, '||i.d_data_length||')';
        ELSE
          t_select_list := t_select_list||', '||l_alias||i.column_name;
        END IF;
      END IF;
    END LOOP;
	-- 22170173 There are no DBMS_ASSERT tests for columns. These are obtained directly from the Dictionary and believed safe.
	x_select_list:=DBMS_ASSERT.NOOP(t_select_list);
	x_insert_list:=DBMS_ASSERT.NOOP(t_insert_list);
  END get_list_of_columns;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_gv$sqlarea
   *
   * ------------------------- */
  PROCEDURE collect_gv$sqlarea (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sqlarea');
    get_list_of_columns (
      p_source_table      => 'gv_$sqlarea',
      p_destination_table => 'sqlt$_gv$sqlarea',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sqlarea (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sqlarea'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id AND hash_value = :hash_value';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id, IN p_hash_value;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sqlarea WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sqlarea;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$sqlstats
   *
   * ------------------------- */
  PROCEDURE collect_gv$sqlstats (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sqlstats');
    get_list_of_columns (
      p_source_table      => 'gv_$sqlstats',
      p_destination_table => 'sqlt$_gv$sqlstats',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sqlstats (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sqlstats'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sqlstats WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sqlstats;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_gv$sqlarea_plan_hash
   *
   * ------------------------- */
  PROCEDURE collect_gv$sqlarea_plan_hash (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sqlarea_plan_hash');
    get_list_of_columns (
      p_source_table      => 'gv_$sqlarea_plan_hash',
      p_destination_table => 'sqlt$_gv$sqlarea_plan_hash',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sqlarea_plan_hash (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sqlarea_plan_hash'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sqlarea_plan_hash WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sqlarea_plan_hash;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_gv$sqlstats_plan_hash
   *
   * ------------------------- */
  PROCEDURE collect_gv$sqlstats_plan_hash (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sqlstats_plan_hash');
    get_list_of_columns (
      p_source_table      => 'gv_$sqlstats_plan_hash',
      p_destination_table => 'sqlt$_gv$sqlstats_plan_hash',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sqlstats_plan_hash (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sqlstats_plan_hash'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sqlstats_plan_hash WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sqlstats_plan_hash;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_gv$sql
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sql');
    get_list_of_columns (
      p_source_table      => 'gv_$sql',
      p_destination_table => 'sqlt$_gv$sql',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sql (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sql'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id AND hash_value = :hash_value';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id, IN p_hash_value;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    SELECT SUM(px_servers_executions)
      INTO l_count
      FROM sqlt$_gv$sql
     WHERE statement_id = p_statement_id;

    UPDATE sqlt$_sql_statement
       SET px_servers_executions = NVL(l_count, 0)
     WHERE statement_id = p_statement_id;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sql;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_gv$sql_plan
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_plan (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

    PROCEDURE lock_6356566
    IS
    BEGIN
      IF sqlt$a.get_rdbms_version < '11.2' THEN
        IF sqlt$a.get_param('predicates_in_plan') = 'E' THEN -- last execution got (E)rror ORA-07445: exception encountered: core dump
          sqlt$a.set_param('predicates_in_plan', 'N');
          write_error('prior execution of '||TOOL_NAME||' errored out reading from gv$sql_plan');
        END IF;

        IF sqlt$a.get_param('predicates_in_plan') = 'N' THEN -- workaround 6356566
          EXECUTE IMMEDIATE 'ALTER SESSION SET "_cursor_plan_unparse_enabled" = FALSE';
          write_log('skip predicates from plan table');
        ELSIF sqlt$a.get_param('predicates_in_plan') = 'Y' THEN -- LOCK to be unlocked by unlock_6356566 (if no ORA-07445)
          sqlt$a.set_param('predicates_in_plan', 'E');
          write_log('include predicates on plan table (lock).');
        END IF;
      END IF;
    END lock_6356566;

    PROCEDURE unlock_6356566
    IS
    BEGIN
      IF sqlt$a.get_rdbms_version < '11.2' THEN
        IF sqlt$a.get_param('predicates_in_plan') = 'E' THEN -- If I got here that means there were no ORA-07445
          sqlt$a.set_param('predicates_in_plan', 'Y');
          write_log('included predicates on plan table (unlock).');
        END IF;
      END IF;
    END unlock_6356566;

  BEGIN
    write_log('collect_gv$sql_plan');
    get_list_of_columns (
      p_source_table      => 'gv_$sql_plan',
      p_destination_table => 'sqlt$_gv$sql_plan',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sql_plan (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sql_plan'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id AND hash_value = :hash_value';
    write_log(l_sql, 'S');

    lock_6356566; -- possible disconnect on select from gv$sql_plan
    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id, IN p_hash_value;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        unlock_6356566; -- there was no disconnect so proceed to unlock
        RETURN;
    END;
    unlock_6356566; -- there was no disconnect so proceed to unlock

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_plan WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sql_plan;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_gv$sql_plan_statistics
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_plan_statistics (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sql_plan_statistics');
    get_list_of_columns (
      p_source_table      => 'gv_$sql_plan_statistics',
      p_destination_table => 'sqlt$_gv$sql_plan_statistics',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sql_plan_statistics (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sql_plan_statistics'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id AND hash_value = :hash_value';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id, IN p_hash_value;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_plan_statistics WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sql_plan_statistics;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$sql_workarea
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_workarea (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sql_workarea');
    get_list_of_columns (
      p_source_table      => 'gv_$sql_workarea',
      p_destination_table => 'sqlt$_gv$sql_workarea',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sql_workarea (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sql_workarea'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id AND hash_value = :hash_value';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id, IN p_hash_value;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_workarea WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sql_workarea;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_gv$sql_optimizer_env
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_optimizer_env (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_pointer     NUMBER;
    l_value       VARCHAR2(4000);

  BEGIN
    write_log('collect_gv$sql_optimizer_env');
    get_list_of_columns (
      p_source_table      => 'gv_$sql_optimizer_env',
      p_destination_table => 'sqlt$_gv$sql_optimizer_env',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sql_optimizer_env (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sql_optimizer_env'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id AND hash_value = :hash_value AND isdefault = ''NO''';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id, IN p_hash_value;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    -- fix values like 100M to be 104857600, or 364544 KB into 373293056
    FOR i IN (SELECT ROWID row_id,
                     value
                FROM sqlt$_gv$sql_optimizer_env
               WHERE statement_id = p_statement_id
                 AND value IS NOT NULL)
    LOOP
      l_value := NULL;

      l_pointer := INSTR(i.value, 'K');
      IF l_pointer > 0 THEN
        BEGIN
          l_value := TO_NUMBER(SUBSTR(i.value, 1, l_pointer - 1)) * 1024;
        EXCEPTION
          WHEN OTHERS THEN
            l_value := NULL;
        END;
      ELSE
        l_pointer := INSTR(i.value, 'M');
        IF l_pointer > 0 THEN
          BEGIN
            l_value := TO_NUMBER(SUBSTR(i.value, 1, l_pointer - 1)) * 1024 * 1024;
          EXCEPTION
            WHEN OTHERS THEN
              l_value := NULL;
          END;
        ELSE
          l_pointer := INSTR(i.value, 'G');
          IF l_pointer > 0 THEN
            BEGIN
              l_value := TO_NUMBER(SUBSTR(i.value, 1, l_pointer - 1)) * 1024 * 1024 * 1024;
            EXCEPTION
              WHEN OTHERS THEN
                l_value := NULL;
            END;
          END IF;
        END IF;
      END IF;

      IF l_value IS NOT NULL THEN
        write_log(i.value||' -> '||l_value);
        UPDATE sqlt$_gv$sql_optimizer_env
           SET value = l_value
         WHERE ROWID = i.row_id;
      END IF;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_optimizer_env WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sql_optimizer_env;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_gv$sql_bind_capture
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_bind_capture (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sql_bind_capture');
    get_list_of_columns (
      p_source_table      => 'gv_$sql_bind_capture',
      p_destination_table => 'sqlt$_gv$sql_bind_capture',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sql_bind_capture (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sql_bind_capture'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id AND hash_value = :hash_value';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id, IN p_hash_value;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_bind_capture WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sql_bind_capture;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$sql_shared_cursor
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_shared_cursor (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sql_shared_cursor');
    get_list_of_columns (
      p_source_table      => 'gv_$sql_shared_cursor',
      p_destination_table => 'sqlt$_gv$sql_shared_cursor',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sql_shared_cursor (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sql_shared_cursor'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_shared_cursor WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sql_shared_cursor;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$sql_cs_histogram
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_cs_histogram (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sql_cs_histogram');
    get_list_of_columns (
      p_source_table      => 'gv_$sql_cs_histogram',
      p_destination_table => 'sqlt$_gv$sql_cs_histogram',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sql_cs_histogram (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sql_cs_histogram'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_cs_histogram WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sql_cs_histogram;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$sql_cs_selectivity
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_cs_selectivity (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sql_cs_selectivity');
    get_list_of_columns (
      p_source_table      => 'gv_$sql_cs_selectivity',
      p_destination_table => 'sqlt$_gv$sql_cs_selectivity',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sql_cs_selectivity (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sql_cs_selectivity'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_cs_selectivity WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sql_cs_selectivity;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$sql_cs_statistics
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_cs_statistics (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sql_cs_statistics');
    get_list_of_columns (
      p_source_table      => 'gv_$sql_cs_statistics',
      p_destination_table => 'sqlt$_gv$sql_cs_statistics',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$sql_cs_statistics (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$sql_cs_statistics'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_cs_statistics WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$sql_cs_statistics;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$object_dependency
   *
   * ------------------------- */
  PROCEDURE collect_gv$object_dependency (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    od_rec  sqlt$_gv$object_dependency%ROWTYPE;
    l_count NUMBER;

    TYPE sqlarea_rt IS RECORD (
      inst_id    sqlt$_gv$sqlarea.inst_id%TYPE,
      hash_value sqlt$_gv$sqlarea.hash_value%TYPE,
      address    sqlt$_gv$sqlarea.address%TYPE,
      depth      NUMBER );
    sqlarea_rec sqlarea_rt;
    sqlarea_cv SYS_REFCURSOR;

    /* -------------------------
     *
     * private collect_gv$object_dependency.insert_gv$object_dependency
     *
     * ------------------------- */
    PROCEDURE insert_gv$object_dependency
    IS
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_gv$object_dependency
       WHERE statement_id = p_statement_id
         AND to_owner = od_rec.to_owner
         AND to_name = od_rec.to_name
         AND to_type = od_rec.to_type;

      IF l_count = 0 THEN
        INSERT INTO sqlt$_gv$object_dependency VALUES od_rec;
        write_log('type="'||od_rec.to_type||'", name="'||od_rec.to_name||'", owner="'||od_rec.to_owner||'", depth="'||od_rec.depth||'" collected now.', 'S');
      ELSE
        write_log('type="'||od_rec.to_type||'", name="'||od_rec.to_name||'", owner="'||od_rec.to_owner||'", depth="'||od_rec.depth||'" collected already.', 'S');
      END IF;
    END insert_gv$object_dependency;

    /* -------------------------
     *
     * private collect_gv$object_dependency.get_dependencies_recursive
     *
     * ------------------------- */
    PROCEDURE get_dependencies_recursive (
      p_inst_id    IN NUMBER,
      p_hash_value IN NUMBER,
      p_address    IN VARCHAR2,
      p_depth      IN NUMBER )
    IS
      TYPE objdep_rt IS RECORD (
        to_type      sqlt$_gv$object_dependency.to_type%TYPE,
        to_name      sqlt$_gv$object_dependency.to_name%TYPE,
        to_owner     sqlt$_gv$object_dependency.to_owner%TYPE,
        to_address   sqlt$_gv$object_dependency.to_address%TYPE,
        to_hash      sqlt$_gv$object_dependency.to_hash%TYPE,
        inst_id      sqlt$_gv$object_dependency.inst_id%TYPE,
        from_address sqlt$_gv$object_dependency.from_address%TYPE,
        from_hash    sqlt$_gv$object_dependency.from_hash%TYPE );
      objdep_rec objdep_rt;
      objdep_cv SYS_REFCURSOR;

    BEGIN
      -- Use "REPLACE(*_address||'@#', '@#')" to avoid following error in some systems (reported in 10204 64 bits Linux)
      -- ORA-06502: PL/SQL: numeric or value error: Bulk Bind: Truncated Bind
	  -- 22170173 use binds for  p_inst_id,p_hash_value,p_address
      OPEN objdep_cv FOR
        'SELECT to_type, '||
        '       to_name, '||
        '       to_owner, '||
        '       REPLACE(to_address||''@#'', ''@#'') to_address, '||
        '       to_hash, '||
        '       inst_id, '||
        '       REPLACE(from_address||''@#'', ''@#'') from_address, '||
        '       from_hash '||
        '  FROM gv$object_dependency'||sqlt$a.s_db_link||' '||
        ' WHERE inst_id = :b_inst_id '||
        '   AND from_hash = :b_hash_value '||
        '   AND from_address = :b_address '
		using p_inst_id,p_hash_value,p_address;
      LOOP
        FETCH objdep_cv INTO objdep_rec;
        EXIT WHEN objdep_cv%NOTFOUND;

        --write_log('type="'||objdep_rec.to_type||'", name="'||objdep_rec.to_name||'", owner="'||objdep_rec.to_owner||'", depth="'||p_depth||'"', 'S');
        od_rec              := NULL;
        od_rec.statement_id := p_statement_id;
        od_rec.statid       := p_statid;
        od_rec.inst_id      := objdep_rec.inst_id;
        od_rec.from_address := objdep_rec.from_address;
        od_rec.from_hash    := objdep_rec.from_hash;
        od_rec.to_owner     := objdep_rec.to_owner;
        od_rec.to_name      := objdep_rec.to_name;
        od_rec.to_address   := objdep_rec.to_address;
        od_rec.to_hash      := objdep_rec.to_hash;
        od_rec.to_type      := objdep_rec.to_type;
        od_rec.depth        := p_depth;
        insert_gv$object_dependency;
        IF p_depth < 10 THEN -- 10 levels down should be plenty
          IF objdep_rec.to_owner NOT IN ('CTXSYS', 'MDSYS') THEN
            get_dependencies_recursive(objdep_rec.inst_id, objdep_rec.to_hash, objdep_rec.to_address, p_depth + 1);
          END IF;
        END IF;
      END LOOP;
      CLOSE objdep_cv;
    END get_dependencies_recursive;

  BEGIN
    write_log('collect_gv$object_dependency');
    sql_rec := sqlt$a.get_statement(p_statement_id);
    write_log('sql_id="'||p_sql_id||'"');
    write_log('hash_value="'||p_hash_value||'"');
    write_log('xplain_sql_id="'||sql_rec.xplain_sql_id||'"');

    -- "REPLACE(address||'@#', '@#')" is used to avoid following error in some systems (reported in 10203)
    -- ORA-06502: PL/SQL: numeric or value error: Bulk Bind: Truncated Bind
	-- 22170173 use binds for p_sql_id and sql_rec.xplain_sql_id
    OPEN sqlarea_cv FOR
      'SELECT inst_id, hash_value, REPLACE(address||''@#'', ''@#'') address, 0 depth '||
      '  FROM gv$sqlarea'||sqlt$a.s_db_link||' '||
      ' WHERE sql_id = :b_sql_id '||
      --'   AND hash_value = '||p_hash_value||' '||
      ' UNION '||
      'SELECT inst_id, hash_value, REPLACE(address||''@#'', ''@#'') address, 0 depth '||
      '  FROM gv$sqlarea'||sqlt$a.s_db_link||' '||
      ' WHERE sql_id = :xplain_sql_id '
	  using p_sql_id,sql_rec.xplain_sql_id;
    LOOP
      FETCH sqlarea_cv INTO sqlarea_rec;
      EXIT WHEN sqlarea_cv%NOTFOUND;

      write_log('root inst_id="'||sqlarea_rec.inst_id||'", hash_value="'||sqlarea_rec.hash_value||'", address="'||sqlarea_rec.address||'", depth="'||sqlarea_rec.depth||'"');
      get_dependencies_recursive(sqlarea_rec.inst_id, sqlarea_rec.hash_value, sqlarea_rec.address, sqlarea_rec.depth + 1);
    END LOOP;
    CLOSE sqlarea_cv;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$object_dependency WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$object_dependency;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$parameter2
   *
   * ------------------------- */
  PROCEDURE collect_gv$parameter2 (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$parameter2');
    get_list_of_columns (
      p_source_table      => 'gv_$parameter2',
      p_destination_table => 'sqlt$_gv$parameter2',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$parameter2 (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$parameter2'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$parameter2 WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$parameter2;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$nls_parameters
   *
   * ------------------------- */
  PROCEDURE collect_gv$nls_parameters (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$nls_parameters');
    get_list_of_columns (
      p_source_table      => 'gv_$nls_parameters',
      p_destination_table => 'sqlt$_gv$nls_parameters',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$nls_parameters (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$nls_parameters'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$nls_parameters WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$nls_parameters;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$system_parameter
   *
   * ------------------------- */
  PROCEDURE collect_gv$system_parameter (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$system_parameter');
    get_list_of_columns (
      p_source_table      => 'gv_$system_parameter',
      p_destination_table => 'sqlt$_gv$system_parameter',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$system_parameter (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$system_parameter'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$system_parameter WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$system_parameter;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$im_segments
   *
   * ------------------------- */
  PROCEDURE collect_gv$im_segments (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN

    IF sqlt$a.get_rdbms_version >= '12.1.0.2' AND sqlt$a.get_param('c_inmemory') = 'Y' THEN 
      write_log('collect_gv$im_segments');
      get_list_of_columns (
        p_source_table      => 'gv_$im_segments',
        p_destination_table => 'sqlt$_gv$im_segments',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_gv$im_segments (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM gv$im_segments'||sqlt$a.s_db_link||' a, sqlg$_pivot b '||
      ' WHERE a.segment_type = b.object_type AND a.segment_name = b.object_name AND a.owner = b.object_owner';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_gv$im_segments WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('Skipped gv$im_segments since version is older than 12.1.0.2 or parameter c_inmemory is set to N');
    END IF;

  END collect_gv$im_segments;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$im_column_level
   *
   * ------------------------- */
  PROCEDURE collect_gv$im_column_level (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN

    IF sqlt$a.get_rdbms_version >= '12.1.0.2' AND sqlt$a.get_param('c_inmemory') = 'Y' THEN 
      write_log('collect_gv$im_column_level');
      get_list_of_columns (
        p_source_table      => 'gv_$im_column_level',
        p_destination_table => 'sqlt$_gv$im_column_level',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_gv$im_column_level (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM gv$im_column_level'||sqlt$a.s_db_link||' a, sqlg$_pivot b '||
      ' WHERE ''TABLE'' = b.object_type AND a.table_name = b.object_name AND a.owner = b.object_owner';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

	  -- 170912 
	  -- This will have to be resolved when we have more experience with INMEMORY
	  -- gv$im_column_level has INST_ID column but sqlt$_dba_tab_cols does not.
	  -- By having inmemory_compression in sqlt$_dba_tab_cols and no INST_ID we are assuming the column has the same compression across all nodes
	  -- which should be true as this is taken from inmemory_memcompress table clause
	  -- and each RAC instance will return the same value many times , which in turn would raise the error in the UPDATE:
      -- ORA-01427: single-row subquery returns more than one row
      -- ORA-06512: at "SQLTXADMIN.SQLT$D", line 2022
	  -- To support this representation will be needed to either make sqlt$_dba_tab_cols multi-instance and change the display
	  -- Or make a warning that the values are different.
	  -- Taking option 2, first step is to ID the columns with different compression settings across instances.
	  -- Then whatever remaines must have the same settings accross instances.
	  
      UPDATE sqlt$_dba_tab_cols a
         SET inmemory_compression = 'RAC Nodes w/Diff Compress'
       WHERE  a.statement_id = p_statement_id
	     AND (SELECT count(distinct inmemory_compression) dist
                FROM sqlt$_gv$im_column_level b
               WHERE a.statement_id = p_statement_id
                 AND a.owner = b.owner
                 AND a.table_name = b.table_name
                 AND a.column_name = b.column_name
             )>1;

      UPDATE sqlt$_dba_tab_cols a
         SET inmemory_compression = (SELECT max(inmemory_compression)
                                       FROM sqlt$_gv$im_column_level b
                                      WHERE a.statement_id = p_statement_id
                                        AND a.owner = b.owner
                                        AND a.table_name = b.table_name
                                        AND a.column_name = b.column_name)
      WHERE inmemory_compression is null
	    AND a.statement_id = p_statement_id;
    

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_gv$im_column_level WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('Skipped gv$im_column_level since version is older than 12.1.0.2 or parameter c_inmemory is set to N');
    END IF;
  EXCEPTION 
   WHEN OTHERS THEN
    write_error(SQLERRM);
    write_log('Skipped gv$im_column_level since there is an exception while populating the repository.');
  END collect_gv$im_column_level;


  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_nls_database_params
   *
   * ------------------------- */
  PROCEDURE collect_nls_database_params (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_nls_database_params');
    get_list_of_columns (
      p_source_table      => 'nls_database_parameters',
      p_destination_table => 'sqlt$_nls_database_parameters',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_nls_database_parameters (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.nls_database_parameters';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_nls_database_parameters WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_nls_database_params;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$parameter_cbo
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE collect_gv$parameter_cbo (p_statement_id IN NUMBER)
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_statid      VARCHAR2(32767);
    l_value       VARCHAR2(32767);

  BEGIN
    write_log('collect_gv$parameter_cbo');
    l_statid := sqlt$a.get_statid(p_statement_id);

    get_list_of_columns (
      p_source_table      => 'sqlt$_gv$parameter_cbo_v', -- sys view created by sqlt
      p_destination_table => 'sqlt$_gv$parameter_cbo', -- &&tool_repository_schema. table
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$parameter_cbo (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.sqlt$_gv$parameter_cbo_v'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN l_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    l_value := UPPER(sqlt$a.get_v$parameter_cbo(p_name => '_optim_peek_user_binds', p_statement_id => p_statement_id));
    UPDATE sqlt$_sql_statement SET
      optim_peek_user_binds = l_value
    WHERE statement_id = p_statement_id;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$parameter_cbo WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
    sqlt$a.reset_init_parameters (p_statement_id => p_statement_id);
  END collect_gv$parameter_cbo;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_v$session_fix_control
   *
   * ------------------------- */
  PROCEDURE collect_v$session_fix_control (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_v$session_fix_control');
    get_list_of_columns (
      p_source_table      => 'v_$session_fix_control',
      p_destination_table => 'sqlt$_v$session_fix_control',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_v$session_fix_control (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM v$session_fix_control'||sqlt$a.s_db_link||' '||
    'WHERE session_id = :sid';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid, IN sqlt$a.get_sid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_v$session_fix_control WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_v$session_fix_control;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$sql_monitor
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_monitor (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sql_monitor');

    IF sqlt$a.get_param('sql_monitoring') = 'Y' AND sqlt$a.get_param('sql_tuning_advisor') = 'Y' THEN
      get_list_of_columns (
        p_source_table      => 'gv_$sql_monitor',
        p_destination_table => 'sqlt$_gv$sql_monitor',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_gv$sql_monitor (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM gv$sql_monitor'||sqlt$a.s_db_link||' '||
      'WHERE sql_id = :sql_id';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN p_sql_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_monitor WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip GV_$SQL_MONITOR collection as per parameters "sql_monitoring" or "sql_tuning_advisor"');
    END IF;
  END collect_gv$sql_monitor;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$sql_plan_monitor
   *
   * ------------------------- */
  PROCEDURE collect_gv$sql_plan_monitor (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$sql_plan_monitor');

    IF sqlt$a.get_param('sql_monitoring') = 'Y' AND sqlt$a.get_param('sql_tuning_advisor') = 'Y' THEN
      get_list_of_columns (
        p_source_table      => 'gv_$sql_plan_monitor',
        p_destination_table => 'sqlt$_gv$sql_plan_monitor',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_gv$sql_plan_monitor (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM gv$sql_plan_monitor'||sqlt$a.s_db_link||' '||
      'WHERE sql_id = :sql_id';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN p_sql_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_plan_monitor WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip GV_$SQL_PLAN_MONITOR collection as per parameters "sql_monitoring" or "sql_tuning_advisor"');
    END IF;
  END collect_gv$sql_plan_monitor;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$vpd_policy
   *
   * ------------------------- */
  PROCEDURE collect_gv$vpd_policy (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$vpd_policy');

    get_list_of_columns (
      p_source_table      => 'gv_$vpd_policy',
      p_destination_table => 'sqlt$_gv$vpd_policy',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_gv$vpd_policy (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM gv$vpd_policy'||sqlt$a.s_db_link||' '||
    'WHERE sql_id = :sql_id';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_sql_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$vpd_policy WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_gv$vpd_policy;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$active_session_hist
   *
   * ------------------------- */
  PROCEDURE collect_gv$active_session_hist (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_gv$active_session_hist');

    IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param_n('c_ash_hist_days') > 0  THEN
      get_list_of_columns (
        p_source_table      => 'gv_$active_session_history',
        p_destination_table => 'sqlt$_gv$active_session_histor',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_gv$active_session_histor (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM gv$active_session_history'||sqlt$a.s_db_link||' '||
      'WHERE sql_id = :sql_id';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN p_sql_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_gv$active_session_histor WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip GV$ACTIVE_SESSION_HISTORY collection as per parameter "automatic_workload_repository" or "c_ash_hist_days"');
    END IF;
  END collect_gv$active_session_hist;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_hist_snapshot
   *
   * ------------------------- */
  PROCEDURE collect_dba_hist_snapshot (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_dbid        NUMBER;

  BEGIN
    write_log('collect_dba_hist_snapshot');

    IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param_n('c_awr_hist_days') > 0  THEN
      get_list_of_columns (
        p_source_table      => 'dba_hist_snapshot',
        p_source_alias      => 's',
        p_destination_table => 'sqlt$_dba_hist_snapshot',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_dbid := sqlt$a.get_database_id;

      l_sql :=
      'INSERT INTO sqlt$_dba_hist_snapshot (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM sys.dba_hist_snapshot'||sqlt$a.s_db_link||' s '||
      'WHERE dbid = :dbid';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN l_dbid;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_dba_hist_snapshot WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip DBA_HIST_SNAPSHOT collection as per parameter "automatic_workload_repository" pr "c_awr_hist_days"');
    END IF;
  END collect_dba_hist_snapshot;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_hist_parameter
   *
   * ------------------------- */
  PROCEDURE collect_dba_hist_parameter (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_dbid        NUMBER;

  BEGIN
    write_log('collect_dba_hist_parameter');

    IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param('c_dba_hist_parameter') = 'Y' AND sqlt$a.get_param_n('c_awr_hist_days') > 0  THEN
      get_list_of_columns (
        p_source_table      => 'dba_hist_parameter',
        p_source_alias      => 'p',
        p_destination_table => 'sqli$_dba_hist_parameter',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_dbid := sqlt$a.get_database_id;

      l_sql :=
      'INSERT INTO sqli$_dba_hist_parameter (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM sys.dba_hist_snapshot'||sqlt$a.s_db_link||' s, sys.dba_hist_parameter'||sqlt$a.s_db_link||' p '||
      'WHERE p.dbid = :dbid AND s.snap_id = p.snap_id AND s.dbid = p.dbid AND s.instance_number = p.instance_number AND s.begin_interval_time > :start_time';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN l_dbid, IN SYSTIMESTAMP - sqlt$a.get_param_n('c_awr_hist_days');
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqli$_dba_hist_parameter WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip DBA_HIST_PARAMETER collection of non-default or modified parameters as per parameters "automatic_workload_repository" and "c_dba_hist_parameter" and "c_awr_hist_days"');
    END IF;
  END collect_dba_hist_parameter;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_hist_parameter_m
   *
   * ------------------------- */
  PROCEDURE collect_dba_hist_parameter_m (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_dbid        NUMBER;
    l_prior_value sys.dba_hist_parameter.value%TYPE;
    l_count       NUMBER;
    l_oldest_value_on_awr VARCHAR2(1);
    l_newest_value_on_awr VARCHAR2(1);	

  BEGIN
    write_log('collect_dba_hist_parameter_m');

    IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param('c_dba_hist_parameter') = 'Y' AND sqlt$a.get_param_n('c_awr_hist_days') > 0  THEN
      l_dbid := sqlt$a.get_database_id;

      FOR i IN (SELECT instance_number,
                       parameter_hash,
                       COUNT(*) num_values  -- will use this value in J loop to identify the newest value
                  FROM sqli$_dba_hist_parameter
                 WHERE statement_id = p_statement_id
                   AND dbid = l_dbid
                 GROUP BY
                       instance_number,
                       parameter_hash
                HAVING COUNT(DISTINCT value) > 1)
      LOOP
        l_prior_value := '-666'; -- dummy non-existent value so it captures always first row below
        l_oldest_value_on_awr := 'Y';
        l_newest_value_on_awr := 'N';

        -- index (statement_id, dbid, instance_number, parameter_hash);
        FOR j IN (SELECT snap_id,
                        parameter_name,
                        value,
                        isdefault,
                        ismodified,
                        rownumber,
                        MAX(rownumber) OVER () last_value
                  FROM (SELECT snap_id,
                               parameter_name,
                               value,
                               isdefault,
                               ismodified,
                               rownumber,
                               CASE WHEN LAG(value,1,0) OVER (ORDER BY snap_id) <> value THEN 1 ELSE NULL END mycol
                         FROM (SELECT snap_id,
                                      parameter_name,
                                      value,
                                      isdefault,
                                      ismodified,
                                      ROW_NUMBER() OVER (ORDER BY snap_id)  rownumber
                                FROM sqli$_dba_hist_parameter
                               WHERE statement_id = p_statement_id
                                 AND dbid = l_dbid
                                 AND instance_number = i.instance_number
                                 AND parameter_hash = i.parameter_hash
                               ORDER BY
                                     snap_id))
                  WHERE mycol = 1
                  ORDER BY
                      snap_id)
        LOOP
          
          IF j.rownumber = j.last_value THEN   -- rownum equals to the total rows for this value so it's the newest one
            l_newest_value_on_awr := 'Y';
          END IF;
          
          INSERT INTO sqlt$_dba_hist_parameter_m (
            statement_id,
            statid,
            snap_id,
            dbid,
            instance_number,
            parameter_hash,
            parameter_name,
            value,
            isdefault,
            ismodified,
            oldest_value_on_awr,
            newest_value_on_awr
          ) VALUES (
            p_statement_id,
            p_statid,
            j.snap_id,
            l_dbid,
            i.instance_number,
            i.parameter_hash,
            j.parameter_name,
            j.value,
            j.isdefault,
            j.ismodified,
            l_oldest_value_on_awr,
            l_newest_value_on_awr
          );
          l_oldest_value_on_awr := 'N';

        END LOOP;
      END LOOP;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_dba_hist_parameter_m WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip DBA_HIST_PARAMETER collection of modified values as per parameters "automatic_workload_repository" and "c_dba_hist_parameter" and "c_awr_hist_days"');
    END IF;
  END collect_dba_hist_parameter_m;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_hist_active_sess_h
   *
   * ------------------------- */
  PROCEDURE collect_dba_hist_active_sess_h (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_dbid        NUMBER;

  BEGIN
    write_log('collect_dba_hist_active_sess_h');

    IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param_n('c_ash_hist_days') > 0  THEN
      get_list_of_columns (
        p_source_table      => 'dba_hist_active_sess_history',
        p_destination_table => 'sqlt$_dba_hist_active_sess_his',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_dbid := sqlt$a.get_database_id;

      l_sql :=
      'INSERT INTO sqlt$_dba_hist_active_sess_his (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM sys.dba_hist_active_sess_history'||sqlt$a.s_db_link||' '||
      'WHERE dbid = :dbid AND sql_id = :sql_id AND sample_time > :start_time';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN l_dbid, IN p_sql_id, IN SYSTIMESTAMP - sqlt$a.get_param_n('c_ash_hist_days');
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_dba_hist_active_sess_his WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip DBA_HIST_ACTIVE_SESS_HISTORY collection as per parameter "automatic_workload_repository" and "c_ash_hist_days"');
    END IF;
  END collect_dba_hist_active_sess_h;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_dba_hist_sqltext
   *
   * ------------------------- */
  PROCEDURE collect_dba_hist_sqltext (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_dbid        NUMBER;

  BEGIN
    write_log('collect_dba_hist_sqltext');

    IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param_n('c_awr_hist_days') > 0  THEN
      get_list_of_columns (
        p_source_table      => 'dba_hist_sqltext',
        p_destination_table => 'sqlt$_dba_hist_sqltext',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_dbid := sqlt$a.get_database_id;

      l_sql :=
      'INSERT INTO sqlt$_dba_hist_sqltext (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM sys.dba_hist_sqltext'||sqlt$a.s_db_link||' '||
      'WHERE dbid = :dbid AND sql_id = :sql_id';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN l_dbid, IN p_sql_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_dba_hist_sqltext WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip DBA_HIST_SQLTEXT collection as per parameter "automatic_workload_repository" or "c_awr_hist_days"');
    END IF;
  END collect_dba_hist_sqltext;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_dba_hist_sqlstat
   *
   * ------------------------- */
  PROCEDURE collect_dba_hist_sqlstat (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_dbid        NUMBER;

  BEGIN
    write_log('collect_dba_hist_sqlstat');

    IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param_n('c_awr_hist_days') > 0  THEN
      get_list_of_columns (
        p_source_table      => 'dba_hist_sqlstat',
        p_destination_table => 'sqlt$_dba_hist_sqlstat',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_dbid := sqlt$a.get_database_id;

      l_sql :=
      'INSERT INTO sqlt$_dba_hist_sqlstat (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM sys.dba_hist_sqlstat'||sqlt$a.s_db_link||' '||
      'WHERE dbid = :dbid AND sql_id = :sql_id';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN l_dbid, IN p_sql_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_dba_hist_sqlstat WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip DBA_HIST_SQLSTAT collection as per parameter "automatic_workload_repository" or "c_awr_hist_days"');
    END IF;
  END collect_dba_hist_sqlstat;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_dba_hist_sql_plan
   *
   * ------------------------- */
  PROCEDURE collect_dba_hist_sql_plan (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_dbid        NUMBER;

  BEGIN
    write_log('collect_dba_hist_sql_plan');

    IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param_n('c_awr_hist_days') > 0  THEN
      get_list_of_columns (
        p_source_table      => 'dba_hist_sql_plan',
        p_destination_table => 'sqlt$_dba_hist_sql_plan',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_dbid := sqlt$a.get_database_id;

      l_sql :=
      'INSERT INTO sqlt$_dba_hist_sql_plan (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM sys.dba_hist_sql_plan'||sqlt$a.s_db_link||' '||
      'WHERE dbid = :dbid AND sql_id = :sql_id';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN l_dbid, IN p_sql_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_dba_hist_sql_plan WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip DBA_HIST_SQL_PLAN collection as per parameter "automatic_workload_repository" or "c_awr_hist_days"');
    END IF;
  END collect_dba_hist_sql_plan;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_dba_hist_sqlbind
   *
   * ------------------------- */
  PROCEDURE collect_dba_hist_sqlbind (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_dbid        NUMBER;

  BEGIN
    write_log('collect_dba_hist_sqlbind');

    IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param_n('c_awr_hist_days') > 0  THEN
      get_list_of_columns (
        p_source_table      => 'dba_hist_sqlbind',
        p_destination_table => 'sqlt$_dba_hist_sqlbind',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_dbid := sqlt$a.get_database_id;

      -- this sql will insert duplicates
      l_sql :=
      'INSERT INTO sqlt$_dba_hist_sqlbind (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'|| -- if doing a DISTINCT you get "ORA-22950: cannot ORDER objects without MAP or ORDER method" because of value_anydata
      l_select_list||' FROM sys.dba_hist_sqlbind'||sqlt$a.s_db_link||' '||
      'WHERE dbid = :dbid AND sql_id = :sql_id';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN l_dbid, IN p_sql_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      SELECT COUNT(*) INTO l_count FROM sqlt$_dba_hist_sqlbind WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');

      -- looking for duplicates
      FOR i IN (SELECT MIN(ROWID) min_rowid
                  FROM sqlt$_dba_hist_sqlbind
                 WHERE statement_id = p_statement_id
                 GROUP BY
                       snap_id,
                       dbid,
                       instance_number,
                       sql_id,
                       name,
                       position,
                       dup_position,
                       datatype,
                       datatype_string,
                       character_sid,
                       precision,
                       scale,
                       max_length,
                       was_captured,
                       last_captured,
                       value_string)
      LOOP
        -- using plan_hash_value to flag 1st row within a set in order to remove duplicates
        UPDATE sqlt$_dba_hist_sqlbind
           SET plan_hash_value = -1
         WHERE ROWID = i.min_rowid;
      END LOOP;

      -- delete duplicates
      DELETE sqlt$_dba_hist_sqlbind
       WHERE statement_id = p_statement_id
         AND plan_hash_value IS NULL;

     -- reset plan_hash_value
     UPDATE sqlt$_dba_hist_sqlbind
        SET plan_hash_value = NULL
      WHERE statement_id = p_statement_id;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_dba_hist_sqlbind WHERE statement_id = p_statement_id;
      write_log(l_count||' rows after deleting duplicates');
    ELSE
      write_log('skip DBA_HIST_SQLBIND collection as per parameter "automatic_workload_repository" or "c_awr_hist_days"');
    END IF;
  END collect_dba_hist_sqlbind;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_dependencies
   *
   * ------------------------- */
  PROCEDURE collect_dba_dependencies (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    od_rec  sqlt$_dba_dependencies%ROWTYPE;
    l_count NUMBER;

    /* -------------------------
     *
     * private collect_dba_dependencies.insert_dba_dependencies
     *
     * ------------------------- */
    PROCEDURE insert_dba_dependencies
    IS
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_dependencies
       WHERE statement_id = p_statement_id
         AND referenced_owner = od_rec.referenced_owner
         AND referenced_name = od_rec.referenced_name
         AND referenced_type = od_rec.referenced_type;

      IF l_count = 0 THEN
        INSERT INTO sqlt$_dba_dependencies VALUES od_rec;
        write_log('type="'||od_rec.referenced_type||'", name="'||od_rec.referenced_name||'", owner="'||od_rec.referenced_owner||'", depth="'||od_rec.depth||'" collected now', 'S');
      ELSE
        write_log('type="'||od_rec.referenced_type||'", name="'||od_rec.referenced_name||'", owner="'||od_rec.referenced_owner||'", depth="'||od_rec.depth||'" collected already', 'S');
      END IF;
    END insert_dba_dependencies;

    /* -------------------------
     *
     * private collect_dba_dependencies.get_dependencies_recursive
     *
     * ------------------------- */
    PROCEDURE get_dependencies_recursive (
      p_owner IN VARCHAR2,
      p_name  IN VARCHAR2,
      p_type  IN VARCHAR2,
      p_depth IN NUMBER )
    IS
      objdep_rec sys.dba_dependencies%ROWTYPE;
      objdep_cv SYS_REFCURSOR;

    BEGIN
      OPEN objdep_cv FOR
        'SELECT * '||
        '  FROM sys.dba_dependencies'||sqlt$a.s_db_link||' '||
        ' WHERE owner = :b_owner '||
        '   AND name = :b_name '||
        '   AND type = :b_type '||
        '   AND type <> ''NON-EXISTENT'' '||
        '   AND referenced_type <> ''NON-EXISTENT'' '
		using p_owner,p_name,p_type;
      LOOP
        FETCH objdep_cv INTO objdep_rec;
        EXIT WHEN objdep_cv%NOTFOUND;

        --write_log('type="'||objdep_rec.referenced_type||'", name="'||objdep_rec.referenced_name||'", owner="'||objdep_rec.referenced_owner||'", depth="'||p_depth||'"', 'S');
        od_rec                      := NULL;
        od_rec.statement_id         := p_statement_id;
        od_rec.statid               := p_statid;
        od_rec.owner                := objdep_rec.owner;
        od_rec.name                 := objdep_rec.name;
        od_rec.type                 := objdep_rec.type;
        od_rec.referenced_owner     := objdep_rec.referenced_owner;
        od_rec.referenced_name      := objdep_rec.referenced_name;
        od_rec.referenced_type      := objdep_rec.referenced_type;
        od_rec.referenced_link_name := objdep_rec.referenced_link_name;
        od_rec.dependency_type      := objdep_rec.dependency_type;
        od_rec.depth                := p_depth;
        insert_dba_dependencies;
        IF p_depth < 10 THEN -- 10 levels down should be plenty
          IF objdep_rec.owner NOT IN ('CTXSYS', 'MDSYS','SYS','SYSTEM') AND NOT (objdep_rec.owner = 'PUBLIC' AND objdep_rec.referenced_owner = 'SYS') THEN --12.1.0.8 was only CTXSYS and MDSYS before
            get_dependencies_recursive(objdep_rec.referenced_owner, objdep_rec.referenced_name, objdep_rec.referenced_type, p_depth + 1);
          END IF;
        END IF;
      END LOOP;
      CLOSE objdep_cv;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error('get_dependencies_recursive for name = "'||p_name||'", owner = "'||p_owner||'", type = "'||p_type||'"');
    END get_dependencies_recursive;

  BEGIN
    write_log('collect_dba_dependencies');

    FOR i IN (SELECT type, to_name name, to_owner owner, depth
                FROM sqlt$_gv$object_dependency_v
               WHERE statement_id = p_statement_id
               UNION
              SELECT CASE WHEN object_type IN ('MAT_VIEW', 'MAT_VIEW REWRITE') THEN 'MATERIALIZED VIEW' ELSE object_type END type,
                     object_name name, object_owner owner, 0 depth
                FROM sqlt$_gv$sql_plan
               WHERE statement_id = p_statement_id
                 AND object_owner IS NOT NULL
                 AND object_type IN ('INDEX', 'TABLE', 'MAT_VIEW', 'MAT_VIEW REWRITE', 'VIEW')
               UNION
              SELECT CASE WHEN object_type IN ('MAT_VIEW', 'MAT_VIEW REWRITE') THEN 'MATERIALIZED VIEW' ELSE object_type END type,
                     object_name name, object_owner owner, 0 depth
                FROM sqlt$_dba_hist_sql_plan
               WHERE statement_id = p_statement_id
                 AND object_owner IS NOT NULL
                 AND object_type IN ('INDEX', 'TABLE', 'MAT_VIEW', 'MAT_VIEW REWRITE', 'VIEW')
               UNION
              SELECT CASE WHEN object_type = 'MAT_VIEW' THEN 'MATERIALIZED VIEW' ELSE object_type END type,
                     object_name name, object_owner owner, 0 depth
                FROM sqlt$_sql_plan_table
               WHERE statement_id = sqlt$a.get_statement_id_c(p_statement_id)
                 AND object_owner IS NOT NULL
                 AND object_type IN ('INDEX', 'TABLE', 'MAT_VIEW', 'MAT_VIEW REWRITE', 'VIEW'))
    LOOP
      write_log('root type="'||i.type||'", name="'||i.name||'", owner="'||i.owner||'", depth="'||i.depth||'"', 'S');
      IF i.owner NOT IN ('CTXSYS', 'MDSYS','SYS','SYSTEM') THEN  --12.1.08
         get_dependencies_recursive(i.owner, i.name, i.type, i.depth + 1);
      END IF;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_dependencies WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_dependencies;

  /*************************************************************************************/

  /* -------------------------
   *
   * public list_of_indexes
   *
   * called by sqlt$d.list_of_objects and sqlt$t.indexes_in_plan
   *
   * ------------------------- */
  PROCEDURE list_of_indexes (p_statement_id IN NUMBER)
  IS
    l_statement_id_c VARCHAR2(32767);
  BEGIN
    l_statement_id_c := sqlt$a.get_statement_id_c(p_statement_id);

    INSERT INTO sqlg$_pivot (object_type, object_name, object_owner)
    SELECT 'I', pt.object_name, pt.object_owner
      FROM sqlt$_gv$sql_plan pt
     WHERE pt.statement_id = p_statement_id
       AND (pt.object_type LIKE '%INDEX%' OR pt.operation LIKE '%INDEX%')
       AND NOT ((pt.object_type LIKE '%FIXED%' OR pt.object_type LIKE '%CLUSTER%' OR pt.operation LIKE '%FIXED%') AND pt.object_owner = 'SYS')
     UNION
    SELECT 'I', pt.object_name, pt.object_owner
      FROM sqlt$_dba_hist_sql_plan pt
     WHERE pt.statement_id = p_statement_id
       AND (pt.object_type LIKE '%INDEX%' OR pt.operation LIKE '%INDEX%')
       AND NOT ((pt.object_type LIKE '%FIXED%' OR pt.object_type LIKE '%CLUSTER%' OR pt.operation LIKE '%FIXED%') AND pt.object_owner = 'SYS')
     UNION
    SELECT 'I', pt.object_name, pt.object_owner
      FROM sqlt$_sql_plan_table pt
     WHERE pt.statement_id = l_statement_id_c
       AND (pt.object_type LIKE '%INDEX%' OR pt.operation LIKE '%INDEX%')
       AND NOT ((pt.object_type LIKE '%FIXED%' OR pt.object_type LIKE '%CLUSTER%' OR pt.operation LIKE '%FIXED%') AND pt.object_owner = 'SYS')
     UNION
    SELECT 'I', od.to_name object_name, od.to_owner object_owner
      FROM sqlt$_gv$object_dependency od
     WHERE od.statement_id = p_statement_id
       AND od.to_type = 1 -- INDEX
     UNION
    SELECT 'I', dp.name object_name, dp.owner object_owner
      FROM sqlt$_dba_dependencies dp
     WHERE dp.statement_id = p_statement_id
       AND dp.type = 'INDEX'
     UNION
    SELECT 'I', dp.referenced_name object_name, dp.referenced_owner object_owner
      FROM sqlt$_dba_dependencies dp
     WHERE dp.statement_id = p_statement_id
       AND dp.referenced_type = 'INDEX';
  END list_of_indexes;

  /*************************************************************************************/

  /* -------------------------
   *
   * private list_of_objects
   *
   * called by sqlt$d.diagnostics_data_collection_2
   *
   * ------------------------- */
  PROCEDURE list_of_objects (p_statement_id IN NUMBER)
  IS
    l_statement_id_c VARCHAR2(32767);
    l_count          NUMBER;
  BEGIN
    write_log('list_of_objects');
    l_statement_id_c := sqlt$a.get_statement_id_c(p_statement_id);

    DELETE sqlg$_pivot;

    -- preliminary list of tables
    write_log('preliminary_list_of_tables');
    INSERT INTO sqlg$_pivot (object_type, object_name, object_owner)
    SELECT 'T', pt.object_name, pt.object_owner
      FROM sqlt$_gv$sql_plan pt
     WHERE statement_id = p_statement_id
       AND (pt.object_type LIKE '%TABLE%' OR pt.object_type LIKE '%MAT%VIEW%' OR pt.operation LIKE '%TABLE%ACCESS%' OR pt.operation LIKE '%MAT%VIEW%ACCESS%')
       AND NOT (pt.object_type LIKE '%FIXED%' OR pt.operation LIKE '%FIXED%')
     UNION
    SELECT 'T', pt.object_name, pt.object_owner
      FROM sqlt$_dba_hist_sql_plan pt
     WHERE statement_id = p_statement_id
       AND (pt.object_type LIKE '%TABLE%' OR pt.object_type LIKE '%MAT%VIEW%' OR pt.operation LIKE '%TABLE%ACCESS%' OR pt.operation LIKE '%MAT%VIEW%ACCESS%')
       AND NOT (pt.object_type LIKE '%FIXED%' OR pt.operation LIKE '%FIXED%')
     UNION
    SELECT 'T', pt.object_name, pt.object_owner
      FROM sqlt$_sql_plan_table pt
     WHERE statement_id = l_statement_id_c
       AND (pt.object_type LIKE '%TABLE%' OR pt.object_type LIKE '%MAT%VIEW%' OR pt.operation LIKE '%TABLE%ACCESS%' OR pt.operation LIKE '%MAT%VIEW%ACCESS%'
           OR pt.operation LIKE 'LOAD%' ) -- to grab the target table in case of INSERT VALUES
       AND NOT (NVL(pt.object_type,'NULL') LIKE '%FIXED%' OR pt.operation LIKE '%FIXED%')  -- the NVL is required in case of INSERT VALUES
     UNION
    SELECT 'T', od.to_name object_name, od.to_owner object_owner
      FROM sqlt$_gv$object_dependency od
     WHERE od.statement_id = p_statement_id
       AND od.to_type IN (2, 42) -- ('TABLE', 'MATERIALIZED VIEW')
       AND NOT (od.to_name LIKE 'X$%' AND od.to_owner = 'SYS' AND od.to_type = 2)
     UNION
    SELECT 'T', dp.name object_name, dp.owner object_owner
      FROM sqlt$_dba_dependencies dp
     WHERE dp.statement_id = p_statement_id
       AND dp.type IN ('TABLE', 'MATERIALIZED VIEW')
       AND NOT (dp.name LIKE 'X$%' AND dp.owner = 'SYS')
     UNION
    SELECT 'T', dp.referenced_name object_name, dp.referenced_owner object_owner
      FROM sqlt$_dba_dependencies dp
     WHERE dp.statement_id = p_statement_id
       AND dp.referenced_type IN ('TABLE', 'MATERIALIZED VIEW')
       AND NOT (dp.referenced_name LIKE 'X$%' AND dp.referenced_owner = 'SYS');

    -- preliminary list of indexes
    write_log('preliminary_list_of_indexes');
    list_of_indexes(p_statement_id);

    -- final list of tables
    write_log('final_list_of_tables');
    SYS.DBMS_STATS.GATHER_TABLE_STATS(TOOL_REPOSITORY_SCHEMA, 'SQLG$_PIVOT', force => TRUE, no_invalidate => FALSE);

    INSERT INTO sqlg$_pivot (object_type, object_name, object_owner, partitioned)
    SELECT 'TABLE', pt.object_name, pt.object_owner, t.partitioned
      FROM sqlg$_pivot pt,
           sys.dba_tables t
     WHERE pt.object_type = 'T'
       AND pt.object_owner = t.owner
       AND pt.object_name = t.table_name
     UNION
    SELECT 'TABLE', dic.table_name object_name, dic.table_owner object_owner, t.partitioned
      FROM sqlg$_pivot pt,
           sys.dba_indexes di,
           sys.dba_ind_columns dic,
           sys.dba_tables t
     WHERE pt.object_type = 'T'
       AND pt.object_owner = di.table_owner
       AND pt.object_name = di.table_name
       AND di.index_type = 'BITMAP' -- Bitmap Join Indexes
       AND di.owner = dic.index_owner
       AND di.index_name = dic.index_name
       AND (dic.table_owner <> pt.object_owner OR dic.table_name <> pt.object_name)
       AND di.table_owner = t.owner
       AND di.table_name = t.table_name
     UNION
    SELECT 'TABLE', di.table_name object_name, di.table_owner object_owner, t.partitioned
      FROM sqlg$_pivot pt,
           sys.dba_indexes di,
           sys.dba_tables t
     WHERE pt.object_type = 'I'
       AND pt.object_owner = di.owner
       AND pt.object_name = di.index_name
       AND di.table_owner = t.owner
       AND di.table_name = t.table_name
     UNION
    SELECT 'TABLE', dic.table_name object_name, dic.table_owner object_owner, t.partitioned
      FROM sqlg$_pivot pt,
           sys.dba_indexes di,
           sys.dba_ind_columns dic,
           sys.dba_tables t
     WHERE pt.object_type = 'I'
       AND pt.object_owner = di.owner
       AND pt.object_name = di.index_name
       AND di.index_type = 'BITMAP' -- Bitmap Join Indexes
       AND di.owner = dic.index_owner
       AND di.index_name = dic.index_name
       AND di.table_owner = t.owner
       AND di.table_name = t.table_name
     UNION
    SELECT 'TABLE', pt.object_name, pt.object_owner, t.partitioned
      FROM sqlg$_pivot pt,
           sys.dba_object_tables t
     WHERE pt.object_type = 'T'
       AND pt.object_owner = t.owner
       AND pt.object_name = t.table_name
     UNION
    SELECT 'TABLE', dic.table_name object_name, dic.table_owner object_owner, t.partitioned
      FROM sqlg$_pivot pt,
           sys.dba_indexes di,
           sys.dba_ind_columns dic,
           sys.dba_object_tables t
     WHERE pt.object_type = 'T'
       AND pt.object_owner = di.table_owner
       AND pt.object_name = di.table_name
       AND di.index_type = 'BITMAP' -- Bitmap Join Indexes
       AND di.owner = dic.index_owner
       AND di.index_name = dic.index_name
       AND (dic.table_owner <> pt.object_owner OR dic.table_name <> pt.object_name)
       AND di.table_owner = t.owner
       AND di.table_name = t.table_name
     UNION
    SELECT 'TABLE', di.table_name object_name, di.table_owner object_owner, t.partitioned
      FROM sqlg$_pivot pt,
           sys.dba_indexes di,
           sys.dba_object_tables t
     WHERE pt.object_type = 'I'
       AND pt.object_owner = di.owner
       AND pt.object_name = di.index_name
       AND di.table_owner = t.owner
       AND di.table_name = t.table_name
     UNION
    SELECT 'TABLE', dic.table_name object_name, dic.table_owner object_owner, t.partitioned
      FROM sqlg$_pivot pt,
           sys.dba_indexes di,
           sys.dba_ind_columns dic,
           sys.dba_object_tables t
     WHERE pt.object_type = 'I'
       AND pt.object_owner = di.owner
       AND pt.object_name = di.index_name
       AND di.index_type = 'BITMAP' -- Bitmap Join Indexes
       AND di.owner = dic.index_owner
       AND di.index_name = dic.index_name
       AND di.table_owner = t.owner
       AND di.table_name = t.table_name
     UNION
    SELECT 'TABLE', o.object_name object_name, o.owner object_owner, t.partitioned
      FROM sqlg$_pivot pt,
           sys.dba_indexes di,
           sys.dba_objects o,
           sys.dba_tables t
     WHERE pt.object_type = 'T'
       AND pt.object_owner = di.table_owner
       AND pt.object_name = di.table_name
       AND di.index_type = 'DOMAIN'
       AND di.ityp_name = 'CONTEXT'
       AND di.owner = o.owner
       AND o.object_type = 'TABLE'
       AND o.object_name LIKE 'DR$'||di.index_name||'$%'
       AND o.owner = t.owner
       AND o.object_name = t.table_name;

    SYS.DBMS_STATS.DELETE_TABLE_STATS(TOOL_REPOSITORY_SCHEMA, 'SQLG$_PIVOT', force => TRUE);

    DELETE sqlg$_pivot WHERE object_type IN ('T', 'I');

    -- final list of fixed objects
    write_log('list_of_fixed_objects');
    INSERT INTO sqlg$_pivot (object_type, object_name, object_owner)
    SELECT 'FIXED TABLE', SUBSTR(pt.object_name, 1, INSTR(pt.object_name||' ', ' ') - 1) object_name, pt.object_owner
      FROM sqlt$_gv$sql_plan pt
     WHERE statement_id = p_statement_id
       AND (pt.object_type LIKE '%FIXED%' OR pt.operation LIKE '%FIXED%')
     UNION
    SELECT 'FIXED TABLE', SUBSTR(pt.object_name, 1, INSTR(pt.object_name||' ', ' ') - 1) object_name, pt.object_owner
      FROM sqlt$_dba_hist_sql_plan pt
     WHERE statement_id = p_statement_id
       AND (pt.object_type LIKE '%FIXED%' OR pt.operation LIKE '%FIXED%')
     UNION
    SELECT 'FIXED TABLE', SUBSTR(pt.object_name, 1, INSTR(pt.object_name||' ', ' ') - 1) object_name, pt.object_owner
      FROM sqlt$_sql_plan_table pt
     WHERE statement_id = l_statement_id_c
       AND (pt.object_type LIKE '%FIXED%' OR pt.operation LIKE '%FIXED%')
     UNION
    SELECT 'FIXED TABLE', od.to_name object_name, od.to_owner object_owner
      FROM sqlt$_gv$object_dependency od
     WHERE od.statement_id = p_statement_id
       AND od.to_name LIKE 'X$%'
       AND od.to_owner = 'SYS'
       AND od.to_type = 2;

    -- final list of indexes
	-- 160420 Added parent_table_name,parent_table_owner
    write_log('final_list_of_indexes');
    INSERT INTO sqlg$_pivot (object_type, object_name, object_owner, partitioned,parent_table_name,parent_table_owner)
    SELECT 'INDEX', di.index_name object_name, di.owner object_owner, di.partitioned,di.table_name,di.table_owner
      FROM sqlg$_pivot pt,
           sys.dba_indexes di
     WHERE pt.object_type = 'TABLE'
       AND pt.object_owner = di.table_owner
       AND pt.object_name = di.table_name
     UNION
    SELECT 'INDEX', o.object_name object_name, o.owner object_owner, di2.partitioned,di.table_name,di.table_owner
      FROM sqlg$_pivot pt,
           sys.dba_indexes di,
           sys.dba_objects o,
           sys.dba_indexes di2
     WHERE pt.object_type = 'T'
       AND pt.object_owner = di.table_owner
       AND pt.object_name = di.table_name
       AND di.index_type = 'DOMAIN'
       AND di.ityp_name = 'CONTEXT'
       AND di.owner = o.owner
       AND o.object_type = 'INDEX'
       AND o.object_name LIKE 'DR$'||di.index_name||'$%'
       AND o.owner = di2.owner
       AND o.object_name = di2.index_name;

    -- list of other objects
    write_log('list_of_other_objects');
    INSERT INTO sqlg$_pivot (object_type, object_name, object_owner)
    SELECT od.type object_type, od.to_name object_name, od.to_owner object_owner
      FROM sqlt$_gv$object_dependency_v od
     WHERE od.statement_id = p_statement_id
       AND od.type NOT IN ('TABLE', 'INDEX', 'UNDEFINED')
     UNION
    SELECT dp.type object_type, dp.name object_name, dp.owner object_owner
      FROM sqlt$_dba_dependencies dp
     WHERE dp.statement_id = p_statement_id
       AND dp.type NOT IN ('TABLE', 'INDEX')
     UNION
    SELECT dp.referenced_type object_type, dp.referenced_name object_name, dp.referenced_owner object_owner
      FROM sqlt$_dba_dependencies dp
     WHERE dp.statement_id = p_statement_id
       AND dp.referenced_type NOT IN ('TABLE', 'INDEX');

    -- final list of other objects
    write_log('final_list_of_other_objects');
    INSERT INTO sqlg$_pivot (object_type, object_name, object_owner)
      WITH all_objects AS (
    SELECT /*+ MATERIALIZE */
           program_id object_id
      FROM sqlt$_gv$sqlarea
     WHERE statement_id = p_statement_id
       AND program_id IS NOT NULL
     UNION
    SELECT program_id object_id
      FROM sqlt$_gv$sqlarea_plan_hash
     WHERE statement_id = p_statement_id
       AND program_id IS NOT NULL
     UNION
    SELECT program_id object_id
      FROM sqlt$_gv$sql
     WHERE statement_id = p_statement_id
       AND program_id IS NOT NULL
     UNION
    SELECT plsql_entry_object_id object_id
      FROM sqlt$_gv$active_session_histor
     WHERE statement_id = p_statement_id
       AND plsql_entry_object_id IS NOT NULL
     UNION
    SELECT plsql_entry_subprogram_id object_id
      FROM sqlt$_gv$active_session_histor
     WHERE statement_id = p_statement_id
       AND plsql_entry_subprogram_id IS NOT NULL
     UNION
    SELECT plsql_object_id object_id
      FROM sqlt$_gv$active_session_histor
     WHERE statement_id = p_statement_id
       AND plsql_object_id IS NOT NULL
     UNION
    SELECT plsql_subprogram_id object_id
      FROM sqlt$_gv$active_session_histor
     WHERE statement_id = p_statement_id
       AND plsql_subprogram_id IS NOT NULL
     UNION
    SELECT plsql_entry_object_id object_id
      FROM sqlt$_dba_hist_active_sess_his
     WHERE statement_id = p_statement_id
       AND plsql_entry_object_id IS NOT NULL
     UNION
    SELECT plsql_entry_subprogram_id object_id
      FROM sqlt$_dba_hist_active_sess_his
     WHERE statement_id = p_statement_id
       AND plsql_entry_subprogram_id IS NOT NULL
     UNION
    SELECT plsql_object_id object_id
      FROM sqlt$_dba_hist_active_sess_his
     WHERE statement_id = p_statement_id
       AND plsql_object_id IS NOT NULL
     UNION
    SELECT plsql_subprogram_id object_id
      FROM sqlt$_dba_hist_active_sess_his
     WHERE statement_id = p_statement_id
       AND plsql_subprogram_id IS NOT NULL
     UNION
    SELECT plsql_entry_object_id object_id
      FROM sqlt$_gv$sql_monitor
     WHERE statement_id = p_statement_id
       AND plsql_entry_object_id IS NOT NULL
     UNION
    SELECT plsql_entry_subprogram_id object_id
      FROM sqlt$_gv$sql_monitor
     WHERE statement_id = p_statement_id
       AND plsql_entry_subprogram_id IS NOT NULL
     UNION
    SELECT plsql_object_id object_id
      FROM sqlt$_gv$sql_monitor
     WHERE statement_id = p_statement_id
       AND plsql_object_id IS NOT NULL
     UNION
    SELECT plsql_subprogram_id object_id
      FROM sqlt$_gv$sql_monitor
     WHERE statement_id = p_statement_id
       AND plsql_subprogram_id IS NOT NULL
    )
    SELECT ob.object_type, ob.object_name, ob.owner object_owner
      FROM all_objects al,
           sys.dba_objects ob
     WHERE ob.object_id = al.object_id
     MINUS
    SELECT object_type, object_name, object_owner
      FROM sqlg$_pivot;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlg$_pivot;
    write_log(l_count||' rows collected');
  END list_of_objects;

  /*************************************************************************************/

  /* -------------------------
   *
   * private list_of_objects
   *
   * called by sqlt$d.collect_perf_stats_pre
   *
   * ------------------------- */
  PROCEDURE list_of_objects
  IS
    l_count          NUMBER;
  BEGIN
    write_log('list_of_objects');

    DELETE sqlg$_pivot;

    -- all known tables, indexes and partitions from prior executions (repository)
    -- at this point we don't know the objects accessed by sql, so we use objects history in sqlt
    INSERT INTO sqlg$_pivot (object_type, object_name, object_owner, subobject_name, obj#, dataobj#)
    SELECT DISTINCT object_type, object_name, owner, subobject_name, object_id, data_object_id
      FROM sqlt$_dba_objects
     WHERE object_type LIKE 'TABLE%' OR object_type LIKE 'INDEX%';

    COMMIT; -- has to be preserved

    SELECT COUNT(*) INTO l_count FROM sqlg$_pivot;
    write_log(l_count||' rows collected');
  END list_of_objects;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_schema_object_stats
   *
   * ------------------------- */
  PROCEDURE collect_schema_object_stats (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_group_id     IN NUMBER )
  IS
    l_statid VARCHAR2(257);
    l_count NUMBER := 0;
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('collect_schema_object_stats');

    IF p_group_id IS NULL THEN
      l_statid := p_statid;
    ELSE
      l_statid := 's'||sqlt$a.get_statement_id_c(p_group_id)||'_'||'s'||sqlt$a.get_statement_id_c(p_statement_id);
    END IF;

    -- table stats
    BEGIN
      write_log('export table stats');

      FOR i IN (SELECT object_name, object_owner FROM sqlg$_pivot WHERE object_type = 'TABLE' /* AND object_owner NOT IN ('SYS','SYSTEM','CTXSYS', 'MDSYS') */)
      LOOP
        BEGIN
          SYS.DBMS_STATS.EXPORT_TABLE_STATS (
            ownname  => '"'||i.object_owner||'"',
            tabname  => '"'||i.object_name||'"',
            stattab  => 'sqlt$_stattab',
            statid   => '"'||l_statid||'"',
            cascade  => TRUE,
            statown  => TOOL_REPOSITORY_SCHEMA );
          write_log('cbo stats for table "'||i.object_name||'", owner = "'||i.object_owner||'" were exported', 'S');
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error('could not export stats for table = "'||i.object_name||'", owner = "'||i.object_owner||'"');
        END;
      END LOOP;

      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_stattab
       WHERE statid = l_statid;

      write_log(l_count||' rows collected');
    END;


    -- dictionary stats 12.1.08
    BEGIN
      write_log('export dictionary stats');
      IF sqlt$a.get_param('export_dict_stats') = 'Y' THEN 
        BEGIN
          SYS.DBMS_STATS.EXPORT_DICTIONARY_STATS (
            stattab  => 'sqlt$_stattab',
            statid  => '"d'||SUBSTR(l_statid, 2)||'"',
            statown  => TOOL_REPOSITORY_SCHEMA );
          write_log('dictionary objects stats were exported', 'S');
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error('could not export dictionary objects stats');
        END;

        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_stattab
         WHERE statid = 'd'||SUBSTR(l_statid, 2);
        write_log(l_count||' rows collected');
      ELSE
        write_log('dictionary objects stats export skipped because of export_dict_stats param');
      END IF;
    END; 


    -- fixed objects stats
    BEGIN
      IF p_group_id IS NULL THEN
        write_log('export fixed objects stats');

        SELECT COUNT(*)
          INTO l_count
          FROM sqlg$_pivot
         WHERE object_type = 'FIXED TABLE'
           AND ROWNUM = 1;

        BEGIN
          IF l_count > 0 THEN
            SYS.DBMS_STATS.EXPORT_FIXED_OBJECTS_STATS (
              stattab => 'sqlt$_stattab',
              statid  => '"f'||SUBSTR(l_statid, 2)||'"',
              statown => TOOL_REPOSITORY_SCHEMA );
            write_log('fixed objects cbo stats were exported');
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error('could not export cbo stats for fixed objects');
        END;

        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_stattab
         WHERE statid = 'f'||SUBSTR(l_statid, 2);

        write_log(l_count||' rows collected');
      END IF;
    END;

    --COMMIT;
  END collect_schema_object_stats;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tables
   *
   * ------------------------- */
  PROCEDURE collect_dba_tables (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_tables');
    get_list_of_columns (
      p_source_table      => 'dba_tables',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_tables',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_tables (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_tables t '||
    'WHERE x.object_type = ''TABLE'' AND x.object_name = t.table_name AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_tables WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_tables;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_object_tables
   *
   * ------------------------- */
  PROCEDURE collect_dba_object_tables (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_object_tables');
    get_list_of_columns (
      p_source_table      => 'dba_object_tables',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_object_tables',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_object_tables (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_object_tables t '||
    'WHERE x.object_type = ''TABLE'' AND x.object_name = t.table_name AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_object_tables WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_object_tables;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_nested_tables
   *
   * ------------------------- */
  PROCEDURE collect_dba_nested_tables (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_nested_tables');
    get_list_of_columns (
      p_source_table      => 'dba_nested_tables',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_nested_tables',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_nested_tables (statement_id, statid'||
    l_insert_list||') SELECT DISTINCT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_nested_tables t '||
    'WHERE x.object_type = ''TABLE'' AND x.object_name IN (t.table_name, t.parent_table_name) AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_nested_tables WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_nested_tables;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tab_statistics
   *
   * ------------------------- */
  PROCEDURE collect_dba_tab_statistics (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_tab_statistics');
    get_list_of_columns (
      p_source_table      => 'dba_tab_statistics',
      p_destination_table => 'sqlt$_dba_tab_statistics',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_tab_statistics (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_tab_statistics '||
    'WHERE owner = :owner AND table_name = :name';
    write_log(l_sql, 'S');

    FOR i IN (SELECT object_name, object_owner
                FROM sqlg$_pivot
               WHERE object_type = 'TABLE')
    LOOP
      write_log('owner = "'||i.object_owner||'", name = "'||i.object_name||'"', 'S');
      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN i.object_owner, IN i.object_name;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_tab_statistics WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_tab_statistics;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tab_stats_fixed
   *
   * ------------------------- */
  PROCEDURE collect_dba_tab_stats_fixed (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count1      NUMBER;
    l_count2      NUMBER;

  BEGIN
    write_log('collect_dba_tab_stats_fixed');
    get_list_of_columns (
      p_source_table      => 'dba_tab_statistics',
      p_destination_table => 'sqlt$_dba_tab_statistics',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_tab_statistics (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_tab_statistics '||
    'WHERE owner = :owner AND table_name = :name '||
    'AND object_type = ''FIXED TABLE''';
    write_log(l_sql, 'S');

    SELECT COUNT(*) INTO l_count1 FROM sqlt$_dba_tab_statistics WHERE statement_id = p_statement_id;
    FOR i IN (SELECT object_name, object_owner
                FROM sqlg$_pivot
               WHERE object_type = 'FIXED TABLE')
    LOOP
      write_log('owner = "'||i.object_owner||'", name = "'||i.object_name||'"', 'S');
      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN i.object_owner, IN i.object_name;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count2 FROM sqlt$_dba_tab_statistics WHERE statement_id = p_statement_id;
    write_log((l_count2 - l_count1)||' rows collected');
  END collect_dba_tab_stats_fixed;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tab_col_stat_fixed
   *
   * ------------------------- */
  PROCEDURE collect_dba_tab_col_stat_fixed (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count1      NUMBER;
    l_count2      NUMBER;

  BEGIN
    write_log('collect_dba_tab_col_stat_fixed');
    get_list_of_columns (
      p_source_table      => 'dba_tab_col_statistics',
      p_destination_table => 'sqlt$_dba_tab_col_statistics',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_tab_col_statistics (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_tab_col_statistics '||
    'WHERE owner = :owner AND table_name = :name';
    write_log(l_sql, 'S');

    SELECT COUNT(*) INTO l_count1 FROM sqlt$_dba_tab_col_statistics WHERE statement_id = p_statement_id;
    FOR i IN (SELECT object_name, object_owner
                FROM sqlg$_pivot
               WHERE object_type = 'FIXED TABLE')
    LOOP
      write_log('owner = "'||i.object_owner||'", name = "'||i.object_name||'"', 'S');
      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN i.object_owner, IN i.object_name;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count2 FROM sqlt$_dba_tab_col_statistics WHERE statement_id = p_statement_id;
    write_log((l_count2 - l_count1)||' rows collected');
  END collect_dba_tab_col_stat_fixed;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_stat_extensions
   *
   * ------------------------- */
  PROCEDURE collect_dba_stat_extensions (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_stat_extensions');
    get_list_of_columns (
      p_source_table      => 'dba_stat_extensions',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_stat_extensions',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_stat_extensions (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_stat_extensions t '||
    'WHERE x.object_type = ''TABLE'' AND x.object_name = t.table_name AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_stat_extensions WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_stat_extensions;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tab_modifications
   *
   * ------------------------- */
  PROCEDURE collect_dba_tab_modifications (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_tab_modifications');
    get_list_of_columns (
      p_source_table      => 'dba_tab_modifications',
      p_destination_table => 'sqlt$_dba_tab_modifications',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_tab_modifications (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_tab_modifications '||
    'WHERE table_owner = :owner AND table_name = :name';
    write_log(l_sql, 'S');

    FOR i IN (SELECT object_name, object_owner
                FROM sqlg$_pivot
               WHERE object_type = 'TABLE')
    LOOP
      write_log('owner = "'||i.object_owner||'", name = "'||i.object_name||'"', 'S');
      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN i.object_owner, IN i.object_name;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_tab_modifications WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_tab_modifications;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tab_cols
   *
   * ------------------------- */
  PROCEDURE collect_dba_tab_cols (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_tab_cols');
    get_list_of_columns (
      p_source_table      => 'dba_tab_cols',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_tab_cols',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_tab_cols (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_tab_cols t '||
    'WHERE x.object_type IN (''TABLE'', ''FIXED TABLE'') '||
    'AND x.object_name = t.table_name AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_tab_cols WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_tab_cols;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_nested_table_cols
   *
   * ------------------------- */
  PROCEDURE collect_dba_nested_table_cols (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_nested_table_cols');
    get_list_of_columns (
      p_source_table      => 'dba_nested_table_cols',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_nested_table_cols',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_nested_table_cols (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_nested_table_cols t '||
    'WHERE x.object_type IN (''TABLE'', ''FIXED TABLE'') '||
    'AND x.object_name = t.table_name AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_nested_table_cols WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_nested_table_cols;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_indexes
   *
   * ------------------------- */
  PROCEDURE collect_dba_indexes (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_indexes');
    get_list_of_columns (
      p_source_table      => 'dba_indexes',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_indexes',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_indexes (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_indexes t '||
    'WHERE x.object_type = ''INDEX'' AND x.object_name = t.index_name AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_indexes WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_indexes;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_ind_statistics
   *
   * 160421 added filters with parent_table_name,parent_table_owner
   * ------------------------- */
  PROCEDURE collect_dba_ind_statistics (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_ind_statistics');
    get_list_of_columns (
      p_source_table      => 'dba_ind_statistics',
      p_destination_table => 'sqlt$_dba_ind_statistics',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_ind_statistics (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_ind_statistics '||
    'WHERE owner = :owner AND index_name = :name '||
	'  AND table_owner = :parent_table_owner AND table_name = :parent_table_name';
    write_log(l_sql, 'S');

    FOR i IN (SELECT object_name, object_owner,parent_table_name,parent_table_owner
                FROM sqlg$_pivot
               WHERE object_type = 'INDEX')
    LOOP
      --write_log('owner = "'||i.object_owner||'", name = "'||i.object_name||'"', 'S');
      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN i.object_owner, IN i.object_name,
		IN i.parent_table_owner , IN i.parent_table_name;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_ind_statistics WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_ind_statistics;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_ind_columns
   *
   * ------------------------- */
  PROCEDURE collect_dba_ind_columns (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_ind_columns');
    get_list_of_columns (
      p_source_table      => 'dba_ind_columns',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_ind_columns',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_ind_columns (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_ind_columns t '||
    'WHERE x.object_type = ''INDEX'' AND x.object_name = t.index_name AND x.object_owner = t.index_owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_ind_columns WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_ind_columns;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_ind_expressions
   *
   * ------------------------- */
  PROCEDURE collect_dba_ind_expressions (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_ind_expressions');
    get_list_of_columns (
      p_source_table      => 'dba_ind_expressions',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_ind_expressions',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_ind_expressions (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_ind_expressions t '||
    'WHERE x.object_type = ''INDEX'' AND x.object_name = t.index_name AND x.object_owner = t.index_owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_ind_expressions WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_ind_expressions;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tab_histograms
   *
   * ------------------------- */
  PROCEDURE collect_dba_tab_histograms (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_tab_histograms');
    get_list_of_columns (
      p_source_table      => 'dba_tab_histograms',
      p_destination_table => 'sqlt$_dba_tab_histograms',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_tab_histograms (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_tab_histograms '||
    'WHERE owner = :owner AND table_name = :name';
    write_log(l_sql, 'S');

    FOR i IN (SELECT object_name, object_owner
                FROM sqlg$_pivot
               WHERE object_type = 'TABLE')
    LOOP
      write_log('owner = "'||i.object_owner||'", name = "'||i.object_name||'"', 'S');
      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN i.object_owner, IN i.object_name;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_tab_histograms WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_tab_histograms;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_part_key_columns
   *
   * ------------------------- */
  PROCEDURE collect_dba_part_key_columns (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_part_key_columns');
    get_list_of_columns (
      p_source_table      => 'dba_part_key_columns',
      p_destination_table => 'sqlt$_dba_part_key_columns',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_part_key_columns (statement_id, statid'||
    l_insert_list||') SELECT DISTINCT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_part_key_columns'||sqlt$a.s_db_link||' '||
    'WHERE owner = :owner AND name = :name';
    write_log(l_sql, 'S');

    FOR i IN (SELECT object_name, object_owner
                FROM sqlg$_pivot
               WHERE object_type IN ('TABLE', 'INDEX')
                 AND partitioned = 'YES')
    LOOP
      write_log('owner = "'||i.object_owner||'", name = "'||i.object_name||'"', 'S');
      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN i.object_owner, IN i.object_name;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_part_key_columns WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_part_key_columns;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tab_partitions
   *
   * ------------------------- */
  PROCEDURE collect_dba_tab_partitions (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_tab_partitions');
    get_list_of_columns (
      p_source_table      => 'dba_tab_partitions',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_tab_partitions',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_tab_partitions (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_tab_partitions t '||
    'WHERE x.object_type = ''TABLE'' AND x.partitioned = ''YES'' '||
    'AND x.object_name = t.table_name AND x.object_owner = t.table_owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_tab_partitions WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_tab_partitions;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_ind_partitions
   *
   * ------------------------- */
  PROCEDURE collect_dba_ind_partitions (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_ind_partitions');
    get_list_of_columns (
      p_source_table      => 'dba_ind_partitions',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_ind_partitions',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_ind_partitions (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_ind_partitions t '||
    'WHERE x.object_type = ''INDEX'' AND x.partitioned = ''YES'' '||
    'AND x.object_name = t.index_name AND x.object_owner = t.index_owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_ind_partitions WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_ind_partitions;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_part_col_stats
   *
   * ------------------------- */
  PROCEDURE collect_dba_part_col_stats (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_part_col_stats');
    get_list_of_columns (
      p_source_table      => 'dba_part_col_statistics',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_part_col_statistics',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_part_col_statistics (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_part_col_statistics t '||
    'WHERE x.object_type = ''TABLE'' AND x.partitioned = ''YES'' '||
    'AND x.object_name = t.table_name AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_part_col_statistics WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_part_col_stats;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_part_histograms
   *
   * ------------------------- */
  PROCEDURE collect_dba_part_histograms (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_part_histograms');
    get_list_of_columns (
      p_source_table      => 'dba_part_histograms',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_part_histograms',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_part_histograms (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_part_histograms t '||
    'WHERE x.object_type = ''TABLE'' AND x.partitioned = ''YES'' '||
    'AND x.object_name = t.table_name AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_part_histograms WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_part_histograms;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tab_subpartitions
   *
   * ------------------------- */
  PROCEDURE collect_dba_tab_subpartitions (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_tab_subpartitions');
    get_list_of_columns (
      p_source_table      => 'dba_tab_subpartitions',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_tab_subpartitions',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_tab_subpartitions (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_tab_subpartitions t '||
    'WHERE x.object_type = ''TABLE'' AND x.partitioned = ''YES'' '||
    'AND x.object_name = t.table_name AND x.object_owner = t.table_owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_tab_subpartitions WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_tab_subpartitions;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_ind_subpartitions
   *
   * ------------------------- */
  PROCEDURE collect_dba_ind_subpartitions (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_ind_subpartitions');
    get_list_of_columns (
      p_source_table      => 'dba_ind_subpartitions',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_ind_subpartitions',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_ind_subpartitions (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_ind_subpartitions t '||
    'WHERE x.object_type = ''INDEX'' AND x.partitioned = ''YES'' '||
    'AND x.object_name = t.index_name AND x.object_owner = t.index_owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_ind_subpartitions WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_ind_subpartitions;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_subpart_col_stats
   *
   * ------------------------- */
  PROCEDURE collect_dba_subpart_col_stats (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_subpart_col_stats');
    get_list_of_columns (
      p_source_table      => 'dba_subpart_col_statistics',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_subpart_col_stats',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_subpart_col_stats (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_subpart_col_statistics t '||
    'WHERE x.object_type = ''TABLE'' AND x.partitioned = ''YES'' '||
    'AND x.object_name = t.table_name AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_subpart_col_stats WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_subpart_col_stats;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_subpart_histograms
   *
   * ------------------------- */
  PROCEDURE collect_dba_subpart_histograms (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_subpart_histograms');
    get_list_of_columns (
      p_source_table      => 'dba_subpart_histograms',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_subpart_histograms',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_subpart_histograms (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_subpart_histograms t '||
    'WHERE x.object_type = ''TABLE'' AND x.partitioned = ''YES'' '||
    'AND x.object_name = t.table_name AND x.object_owner = t.owner';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_subpart_histograms WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_subpart_histograms;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_constraints
   *
   * ------------------------- */
  PROCEDURE collect_dba_constraints (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_constraints');
    get_list_of_columns (
      p_source_table      => 'dba_constraints',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_constraints',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_constraints (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_constraints t '||
    'WHERE x.object_type IN (''TABLE'', ''VIEW'') AND x.object_name = t.table_name AND x.object_owner IN (t.owner, t.r_owner)';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_constraints WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_constraints;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_segments
   *
   * ------------------------- */
  PROCEDURE collect_dba_segments (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_granularity  IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_segments '||p_granularity);

    get_list_of_columns (
      p_source_table      => 'dba_segments',
      p_destination_table => 'sqlt$_dba_segments',
      p_source_alias      => 't',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_segments (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlg$_pivot x, sys.dba_segments t '||
    'WHERE x.object_type IN (''TABLE'', ''INDEX'') AND x.object_name = t.segment_name AND x.object_owner = t.owner '||
    'AND t.segment_type LIKE x.object_type||''%''';

    IF p_granularity = 'GLOBAL' THEN
      l_sql := l_sql||' AND t.segment_type NOT LIKE ''%PARTITION''';
    ELSIF p_granularity = 'PARTITION' THEN
      l_sql := l_sql||' AND t.segment_type NOT LIKE ''%SUBPARTITION''';
    END IF;

    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    UPDATE sqlt$_sql_statement t
    SET t.segments_total_bytes =
    (SELECT SUM(bytes)
       FROM sqlt$_dba_segments s
      WHERE s.statement_id = p_statement_id)
    WHERE t.statement_id = p_statement_id;

    UPDATE sqlt$_dba_tables t
       SET t.total_segment_blocks =
    (SELECT SUM(s.blocks)
       FROM sys.dba_segments s
      WHERE s.segment_name = t.table_name
        AND s.owner = t.owner
        AND s.segment_type LIKE 'TABLE%')
    WHERE t.statement_id = p_statement_id;

    UPDATE sqlt$_dba_indexes i
       SET i.total_segment_blocks =
    (SELECT SUM(s.blocks)
       FROM sys.dba_segments s
      WHERE s.segment_name = i.index_name
        AND s.owner = i.owner
        AND s.segment_type LIKE 'INDEX%')
    WHERE i.statement_id = p_statement_id;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_segments WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_segments;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tablespaces
   *
   * ------------------------- */
  PROCEDURE collect_dba_tablespaces (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_tablespaces');
    get_list_of_columns (
      p_source_table      => 'dba_tablespaces',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_tablespaces',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    -- final list of tablespaces
    INSERT INTO sqlg$_pivot (object_type, object_name)
    SELECT 'TABLESPACE_NAME' object_type, default_tablespace object_name
      FROM sys.dba_users
     WHERE username = TOOL_REPOSITORY_SCHEMA
     UNION
    SELECT 'TABLESPACE_NAME' object_type, temporary_tablespace object_name
      FROM sys.dba_users
     WHERE username = TOOL_REPOSITORY_SCHEMA
     UNION
    SELECT 'TABLESPACE_NAME' object_type, 'SYSTEM' object_name
      FROM DUAL
     UNION
    SELECT 'TABLESPACE_NAME' object_type, 'SYSAUX' object_name
      FROM DUAL
     UNION
    SELECT 'TABLESPACE_NAME' object_type, tablespace_name object_name
      FROM sqlt$_dba_segments
     WHERE statement_id = p_statement_id
       AND tablespace_name IS NOT NULL
     UNION
    SELECT 'TABLESPACE_NAME' object_type, t.tablespace_name object_name
      FROM sys.dba_tablespaces t, sys.dba_users u
     WHERE t.tablespace_name IN (u.default_tablespace, u.temporary_tablespace)
       AND u.user_id IN (
    SELECT parsing_schema_id
      FROM sqlt$_gv$sqlarea
     WHERE statement_id = p_statement_id
       AND parsing_schema_id IS NOT NULL
     UNION
    SELECT parsing_schema_id
      FROM sqlt$_gv$sqlarea_plan_hash
     WHERE statement_id = p_statement_id
       AND parsing_schema_id IS NOT NULL
     UNION
    SELECT parsing_schema_id
      FROM sqlt$_gv$sql
     WHERE statement_id = p_statement_id
       AND parsing_schema_id IS NOT NULL
     UNION
    SELECT parsing_schema_id
      FROM sqlt$_dba_hist_sqlstat
     WHERE statement_id = p_statement_id
       AND parsing_schema_id IS NOT NULL );

    l_sql :=
    'INSERT INTO sqlt$_dba_tablespaces (statement_id, statid'||
    l_insert_list||') '||
    'SELECT :statement_id, :statid'||l_select_list||
    ' FROM sqlg$_pivot x, sys.dba_tablespaces t '||
    'WHERE x.object_type = ''TABLESPACE_NAME'' AND x.object_name = t.tablespace_name '||
    'UNION '||
    'SELECT :statement_id, :statid'||l_select_list||
    ' FROM sqlg$_pivot x, sys.dba_users u, sys.dba_tablespaces'||sqlt$a.s_db_link||' t '||
    'WHERE x.object_owner = u.username AND t.tablespace_name IN (u.default_tablespace, u.temporary_tablespace) '||
    'UNION '||
    'SELECT :statement_id, :statid'||l_select_list||
    ' FROM sys.dba_tablespaces'||sqlt$a.s_db_link||' t '||
    'WHERE t.contents = ''UNDO''';

    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id, IN p_statid,
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    UPDATE sqlt$_dba_tablespaces t
    SET (t.total_bytes, t.total_blocks, t.total_user_bytes, t.total_user_blocks) =
    (SELECT SUM(f.bytes), SUM(f.blocks), SUM(f.user_bytes), SUM(f.user_blocks)
       FROM sys.dba_data_files f
      WHERE t.tablespace_name = f.tablespace_name)
    WHERE t.statement_id = p_statement_id;

    UPDATE sqlt$_dba_tablespaces t
    SET (t.total_bytes, t.total_blocks, t.total_user_bytes, t.total_user_blocks) =
    (SELECT SUM(f.bytes), SUM(f.blocks), SUM(f.user_bytes), SUM(f.user_blocks)
       FROM sys.dba_temp_files f
      WHERE t.tablespace_name = f.tablespace_name)
    WHERE t.statement_id = p_statement_id
      AND t.total_bytes IS NULL;

    UPDATE sqlt$_sql_statement t
    SET (t.total_bytes, t.total_blocks, t.total_user_bytes, t.total_user_blocks) =
    (SELECT SUM(f.bytes), SUM(f.blocks), SUM(f.user_bytes), SUM(f.user_blocks)
       FROM sys.dba_data_files f)
    WHERE t.statement_id = p_statement_id;

    DELETE sqlg$_pivot WHERE object_type = 'TABLESPACE_NAME';

    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_tablespaces WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_tablespaces WHERE statement_id = p_statement_id AND predicate_evaluation = 'STORAGE';
    IF l_count > 0 THEN
      UPDATE sqlt$_sql_statement
         SET exadata = 'TRUE'
       WHERE statement_id = p_statement_id;
    END IF;

    COMMIT;
  END collect_dba_tablespaces;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_objects
   *
   * ------------------------- */
  PROCEDURE collect_dba_objects (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_granularity  IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_objects '||p_granularity);
    get_list_of_columns (
      p_source_table      => 'dba_objects',
      p_destination_table => 'sqlt$_dba_objects',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_objects (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_objects '||
    'WHERE owner = :owner AND object_name = :name';

    IF p_granularity = 'GLOBAL' THEN
      l_sql := l_sql||' AND object_type NOT LIKE ''%PARTITION''';
    ELSIF p_granularity = 'PARTITION' THEN
      l_sql := l_sql||' AND object_type NOT LIKE ''%SUBPARTITION''';
    END IF;

    write_log(l_sql, 'S');

    FOR i IN (SELECT DISTINCT object_name, object_owner
                FROM sqlg$_pivot)
    LOOP
      --write_log('owner = "'||i.object_owner||'", name = "'||i.object_name||'"', 'S');
      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN i.object_owner, IN i.object_name;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_objects WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_objects;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_hist_seg_stat_obj
   *
   * ------------------------- */
  PROCEDURE collect_dba_hist_seg_stat_obj (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_granularity  IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_hist_seg_stat_obj '||p_granularity);
    get_list_of_columns (
      p_source_table      => 'dba_hist_seg_stat_obj',
      p_destination_table => 'sqlt$_dba_hist_seg_stat_obj',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_hist_seg_stat_obj (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_hist_seg_stat_obj '||
    'WHERE owner = :owner AND object_name = :name';

    IF p_granularity = 'GLOBAL' THEN
      l_sql := l_sql||' AND object_type NOT LIKE ''%PARTITION''';
    ELSIF p_granularity = 'PARTITION' THEN
      l_sql := l_sql||' AND object_type NOT LIKE ''%SUBPARTITION''';
    END IF;

    write_log(l_sql, 'S');

    FOR i IN (SELECT DISTINCT object_name, object_owner
                FROM sqlg$_pivot)
    LOOP
      --write_log('owner = "'||i.object_owner||'", name = "'||i.object_name||'"', 'S');
      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN i.object_owner, IN i.object_name;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_hist_seg_stat_obj WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_hist_seg_stat_obj;

  /*************************************************************************************/

  /* -------------------------
   *
   * private add_dba_object
   *
   * ------------------------- */
  PROCEDURE add_dba_object (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_object_type  IN VARCHAR2,
    p_object_owner IN VARCHAR2,
    p_object_name  IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);

  BEGIN
    write_log('add_dba_object '||p_object_type||' '||p_object_owner||' '||p_object_name);
    get_list_of_columns (
      p_source_table      => 'dba_objects',
      p_destination_table => 'sqlt$_dba_objects',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_objects (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_objects'||sqlt$a.s_db_link||' '||
    'WHERE owner = :owner AND object_name = :name AND object_type = :object_type';

    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_object_owner, IN p_object_name, IN p_object_type;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
  END add_dba_object;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_source
   *
   * ------------------------- */
  PROCEDURE collect_dba_source (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_source');
    get_list_of_columns (
      p_source_table      => 'dba_source',
      p_destination_table => 'sqlt$_dba_source',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_source (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_source '||
    'WHERE owner = :owner AND name = :name';
    write_log(l_sql, 'S');

    FOR i IN (SELECT object_name, object_owner
                FROM sqlg$_pivot
               WHERE object_type IN ('PACKAGE', 'FUNCTION', 'PROCEDURE', 'TRIGGER', 'TYPE', 'LIBRARY', 'JAVA SOURCE')
                 AND object_owner NOT IN ('SYS', 'CTXSYS', 'MDSYS'))
    LOOP
      write_log('owner = "'||i.object_owner||'", name = "'||i.object_name||'"', 'S');
      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN i.object_owner, IN i.object_name;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END LOOP;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_source WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_source;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_scheduler_jobs
   *
   * ------------------------- */
  PROCEDURE collect_dba_scheduler_jobs (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_scheduler_jobs');
    get_list_of_columns (
      p_source_table      => 'dba_scheduler_jobs',
      p_destination_table => 'sqlt$_dba_scheduler_jobs',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_scheduler_jobs (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_scheduler_jobs '||
    'WHERE job_name = ''GATHER_STATS_JOB''';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_scheduler_jobs WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_scheduler_jobs;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_autotask_client
   *
   * ------------------------- */
  PROCEDURE collect_dba_autotask_client (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_autotask_client');
    get_list_of_columns (
      p_source_table      => 'dba_autotask_client',
      p_destination_table => 'sqlt$_dba_autotask_client',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_autotask_client (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_autotask_client '||
    'WHERE client_name = ''auto optimizer stats collection''';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_autotask_client WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_autotask_client;
  
  /*************************************************************************************/  
  
  /* -------------------------
   *
   * private collect_dba_autotask_client_history
   *
   * ------------------------- */
  PROCEDURE collect_dba_autotask_client_h (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_autotask_client_history');
    get_list_of_columns (
      p_source_table      => 'dba_autotask_client_history',
      p_destination_table => 'sqlt$_dba_autotask_client_hst',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_autotask_client_hst (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_autotask_client_history '||
    'WHERE client_name = ''auto optimizer stats collection''';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_autotask_client_hst WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_autotask_client_h;  

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_col_usage$
   * Column Usage
   *
   * ------------------------- */
  PROCEDURE collect_dba_col_usage$ (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_col_usage$');
    get_list_of_columns (
      p_source_table      => 'sqlt$_dba_col_usage_v',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_col_usage$',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_col_usage$ (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_dba_objects x, sys.sqlt$_dba_col_usage_v t '||
    'WHERE x.statement_id = :statement_id AND x.object_type = ''TABLE'' AND x.object_id = t.object_id';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_col_usage$ WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_col_usage$;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_policies
   *
   * ------------------------- */
  PROCEDURE collect_dba_policies (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_policies');
    get_list_of_columns (
      p_source_table      => 'dba_policies',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_policies',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_policies (statement_id, statid'||
    l_insert_list||' , relevant_cols_opt, column_id) SELECT :statement_id, :statid'||
    l_select_list||' , relevant_cols_opt, column_id FROM sqlt$_dba_objects x, '|| 
    'sys.dba_policies t, sys.sqlt$_dba_policies_v v  WHERE x.statement_id = :statement_id '||
    'AND x.object_type IN (''TABLE'', ''VIEW'', ''SYNONYM'') '||
    'AND x.owner = t.object_owner AND x.object_name = t.object_name '||
    'AND x.object_id = v.object_id ';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_policies WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    FOR i IN (SELECT DISTINCT p.pf_owner, p.function
                FROM sqlt$_dba_policies p
               WHERE p.statement_id = p_statement_id
                 AND p.package IS NULL
                 AND NOT EXISTS
             (SELECT NULL
                FROM sqlt$_dba_objects o
               WHERE o.statement_id = p_statement_id
                 AND o.object_type = 'FUNCTION'
                 AND o.object_name = p.function
                 AND o.owner = p.pf_owner))
    LOOP
      add_dba_object(p_statement_id, p_statid, 'FUNCTION', i.pf_owner, i.function);
    END LOOP;

    FOR i IN (SELECT DISTINCT p.pf_owner, p.package
                FROM sqlt$_dba_policies p
               WHERE p.statement_id = p_statement_id
                 AND p.package IS NOT NULL
                 AND NOT EXISTS
             (SELECT NULL
                FROM sqlt$_dba_objects o
               WHERE o.statement_id = p_statement_id
                 AND o.object_type IN ('PACKAGE', 'PACKAGE BODY')
                 AND o.object_name = p.package
                 AND o.owner = p.pf_owner))
    LOOP
      add_dba_object(p_statement_id, p_statid, 'PACKAGE', i.pf_owner, i.package);
      add_dba_object(p_statement_id, p_statid, 'PACKAGE BODY', i.pf_owner, i.package);
    END LOOP;
  END collect_dba_policies;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_audit_policies
   *
   * ------------------------- */
  PROCEDURE collect_dba_audit_policies (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_audit_policies');
    get_list_of_columns (
      p_source_table      => 'dba_audit_policies',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_audit_policies',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_audit_policies (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_dba_objects x, sys.dba_audit_policies t '||
    'WHERE x.statement_id = :statement_id AND x.object_type IN (''TABLE'', ''VIEW'') '||
    'AND x.owner = t.object_schema AND x.object_name = t.object_name';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_audit_policies WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_audit_policies;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_optstat_operations
   *
   * ------------------------- */
  PROCEDURE collect_dba_optstat_operations (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_optstat_operations');

    get_list_of_columns (
      p_source_table      => 'dba_optstat_operations',
      p_destination_table => 'sqlt$_dba_optstat_operations',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_optstat_operations (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.dba_optstat_operations '||
    'WHERE start_time > :start_time';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN SYSTIMESTAMP - sqlt$a.get_param_n('c_cbo_stats_vers_days');
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_optstat_operations WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_optstat_operations;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_optstat_user_prefs$
   *
   * ------------------------- */
  PROCEDURE collect_optstat_user_prefs$ (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_optstat_user_prefs$');
    get_list_of_columns (
      p_source_table      => 'optstat_user_prefs$',
      p_source_alias      => 'p',
      p_destination_table => 'sqlt$_optstat_user_prefs$',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_optstat_user_prefs$ (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_dba_objects x, sys.optstat_user_prefs$ p '||
    'WHERE x.statement_id = :statement_id AND x.object_id = p.obj#';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid, IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_optstat_user_prefs$ WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_optstat_user_prefs$;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_tab_stats_versn
   *
   * ------------------------- */
  PROCEDURE collect_dba_tab_stats_versn (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_granularity  IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_tab_stats_versn '||p_granularity);
    get_list_of_columns (
      p_source_table      => 'sqlt$_dba_tab_stats_vers_v',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_tab_stats_versions',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_tab_stats_versions (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_dba_objects x, sys.sqlt$_dba_tab_stats_vers_v t '||
    'WHERE x.statement_id = :statement_id AND x.object_id = t.object_id '||
    'AND NVL(t.save_time, SYSTIMESTAMP) > :save_time';

    IF p_granularity = 'GLOBAL' THEN
      l_sql := l_sql||' AND x.object_type = ''TABLE'' AND t.object_type = ''TABLE''';
    ELSIF p_granularity = 'PARTITION' THEN
      l_sql := l_sql||' AND x.object_type IN (''TABLE'', ''TABLE PARTITION'') AND t.object_type IN (''TABLE'', ''PARTITION'')';
    ELSE -- p_granularity = 'SUBPARTITION' THEN
      l_sql := l_sql||' AND x.object_type LIKE ''TABLE%''';
    END IF;

    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id, IN SYSDATE - sqlt$a.get_param_n('c_cbo_stats_vers_days');
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_tab_stats_versions WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_tab_stats_versn;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_ind_stats_versn
   *
   * ------------------------- */
  PROCEDURE collect_dba_ind_stats_versn (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_granularity  IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_ind_stats_versn '||p_granularity);
    get_list_of_columns (
      p_source_table      => 'sqlt$_dba_ind_stats_vers_v',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_ind_stats_versions',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_ind_stats_versions (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_dba_objects x, sys.sqlt$_dba_ind_stats_vers_v t '||
    'WHERE x.statement_id = :statement_id AND x.object_id = t.object_id '||
    'AND NVL(t.save_time, SYSTIMESTAMP) > :save_time';

    IF p_granularity = 'GLOBAL' THEN
      l_sql := l_sql||' AND x.object_type = ''INDEX'' AND t.object_type = ''INDEX''';
    ELSIF p_granularity = 'PARTITION' THEN
      l_sql := l_sql||' AND x.object_type IN (''INDEX'', ''INDEX PARTITION'') AND t.object_type IN (''INDEX'', ''PARTITION'')';
    ELSE -- p_granularity = 'SUBPARTITION' THEN
      l_sql := l_sql||' AND x.object_type LIKE ''INDEX%''';
    END IF;

    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id, IN SYSDATE - sqlt$a.get_param_n('c_cbo_stats_vers_days');
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_ind_stats_versions WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_ind_stats_versn;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_col_stats_versn
   *
   * ------------------------- */
  PROCEDURE collect_dba_col_stats_versn (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_granularity  IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_col_stats_versn '||p_granularity);
    get_list_of_columns (
      p_source_table      => 'sqlt$_dba_col_stats_vers_v',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_col_stats_versions',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_col_stats_versions (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_dba_objects x, sys.sqlt$_dba_col_stats_vers_v t '||
    'WHERE x.statement_id = :statement_id AND x.object_id = t.object_id '||
    'AND NVL(t.save_time, SYSTIMESTAMP) > :save_time';

    IF p_granularity = 'GLOBAL' THEN
      l_sql := l_sql||' AND x.object_type = ''TABLE'' AND t.object_type = ''TABLE''';
    ELSIF p_granularity = 'PARTITION' THEN
      l_sql := l_sql||' AND x.object_type IN (''TABLE'', ''TABLE PARTITION'') AND t.object_type IN (''TABLE'', ''PARTITION'')';
    ELSE -- p_granularity = 'SUBPARTITION' THEN
      l_sql := l_sql||' AND x.object_type LIKE ''TABLE%''';
    END IF;

    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id, IN SYSDATE - sqlt$a.get_param_n('c_cbo_stats_vers_days');
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_col_stats_versions WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_col_stats_versn;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_histgrm_stats_ver
   *
   * ------------------------- */
  PROCEDURE collect_dba_histgrm_stats_ver (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_granularity  IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_histgrm_stats_ver '||p_granularity);
    get_list_of_columns (
      p_source_table      => 'sqlt$_dba_hgrm_stats_vers_v',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_histgrm_stats_versn',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_histgrm_stats_versn (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_dba_objects x, sys.sqlt$_dba_hgrm_stats_vers_v t '||
    'WHERE x.statement_id = :statement_id AND x.object_id = t.object_id '||
    'AND NVL(t.save_time, SYSTIMESTAMP) > :save_time';

    IF p_granularity = 'GLOBAL' THEN
      l_sql := l_sql||' AND x.object_type = ''TABLE'' AND t.object_type = ''TABLE''';
    ELSIF p_granularity = 'PARTITION' THEN
      l_sql := l_sql||' AND x.object_type IN (''TABLE'', ''TABLE PARTITION'') AND t.object_type IN (''TABLE'', ''PARTITION'')';
    ELSE -- p_granularity = 'SUBPARTITION' THEN
      l_sql := l_sql||' AND x.object_type LIKE ''TABLE%''';
    END IF;

    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id, IN SYSDATE - sqlt$a.get_param_n('c_cbo_stats_vers_days');
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_histgrm_stats_versn WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_histgrm_stats_ver;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_aux_stats$
   *
   * ------------------------- */
  PROCEDURE collect_aux_stats$ (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_aux_stats$');
    get_list_of_columns (
      p_source_table      => 'aux_stats$',
      p_destination_table => 'sqlt$_aux_stats$',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_aux_stats$ (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.aux_stats$';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_aux_stats$ WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_aux_stats$;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_wri$_optstat_aux_hist
   *
   * ------------------------- */
  PROCEDURE collect_wri$_optstat_aux_hist (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_wri$_optstat_aux_hist');

    get_list_of_columns (
      p_source_table      => 'wri$_optstat_aux_history',
      p_destination_table => 'sqlt$_wri$_optstat_aux_history',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_wri$_optstat_aux_history (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sys.wri$_optstat_aux_history '||
    'WHERE NVL(savtime, SYSTIMESTAMP) > :start_time';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN SYSTIMESTAMP - sqlt$a.get_param_n('c_cbo_stats_vers_days');
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_wri$_optstat_aux_history WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_wri$_optstat_aux_hist;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$segment_statistics
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$segment_statistics (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_begin_end_flag IN VARCHAR2,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    /* 19332407 replace variable, use function */
    IF sqlt$a.get_rdbms_version < '10.2.0.3' THEN -- bug 5507435
      l_sql :=
      'INSERT INTO sqlt$_gv$segment_statistics (statement_id, statid, begin_end_flag'||
      p_insert_list||') SELECT /*+ DRIVING_SITE(t) opt_param(''_push_join_union_view'', ''false'') */ :statement_id, :statid, :begin_end_flag'||
      p_select_list||' FROM sqlg$_pivot x, gv$segment_statistics'||sqlt$a.s_db_link||' t '||
      'WHERE x.obj# = t.obj# AND x.dataobj# = t.dataobj# AND x.object_type = t.object_type '||
      'AND x.object_name = t.object_name AND x.object_owner = t.owner AND NVL(x.subobject_name, ''-666'') = NVL(t.subobject_name, ''-666'')';
    ELSE
      l_sql :=
      'INSERT INTO sqlt$_gv$segment_statistics (statement_id, statid, begin_end_flag'||
      p_insert_list||') SELECT /*+ DRIVING_SITE(t) */ :statement_id, :statid, :begin_end_flag'||
      p_select_list||' FROM sqlg$_pivot x, gv$segment_statistics'||sqlt$a.s_db_link||' t '||
      'WHERE x.obj# = t.obj# AND x.dataobj# = t.dataobj# AND x.object_type = t.object_type '||
      'AND x.object_name = t.object_name AND x.object_owner = t.owner AND NVL(x.subobject_name, ''-666'') = NVL(t.subobject_name, ''-666'')';
    END IF;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_begin_end_flag;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$segment_statistics;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$cell_state
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end and collect_cellstate_xtract
   * 19332407 Remade standalone
   * ------------------------- */
  PROCEDURE collect_gv$cell_state (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_begin_end_flag IN VARCHAR2)
  IS
    l_sql         VARCHAR2(32767);
    
  BEGIN
   
   write_log('collect_gv$cell_state');
   IF s_insert_list_cellstate is null THEN
    get_list_of_columns (
      p_source_table      => 'gv_$cell_state',
      p_destination_table => 'sqlt$_gv$cell_state',
      x_insert_list       => s_insert_list_cellstate,
      x_select_list       => s_select_list_cellstate );
   end if;
   l_sql :=
   'INSERT INTO sqlt$_gv$cell_state (statement_id, statid, begin_end_flag'||
   s_insert_list_cellstate||') SELECT :statement_id, :statid, :begin_end_flag'||
   s_select_list_cellstate||' FROM gv$cell_state'||sqlt$a.s_db_link;
   write_log(l_sql, 'S');

   BEGIN
     EXECUTE IMMEDIATE l_sql USING
     IN p_statement_id, IN p_statid,
     IN p_begin_end_flag;
	 write_log(SQL%ROWCOUNT||' rows collected'); 
   EXCEPTION
     WHEN OTHERS THEN
       write_error(SQLERRM);
       write_error(l_sql);
   END;
   
  END collect_gv$cell_state;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$session_event
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$session_event (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_sid            IN NUMBER,
    p_begin_end_flag IN VARCHAR2,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$session_event (statement_id, statid, begin_end_flag'||
    p_insert_list||') SELECT :statement_id, :statid, :begin_end_flag'||
    p_select_list||' FROM gv$session_event'||sqlt$a.s_db_link||' WHERE sid = :sid';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_begin_end_flag, IN p_sid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$session_event;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$sesstat
   *
   * called by: sqlt$d.collect_perf_stats_begin, sqlt$d.collect_perf_stats_end and collect_sesstat_xtract
   *
   * ------------------------- */
  PROCEDURE collect_gv$sesstat (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_inst_id        IN NUMBER,
    p_sid            IN NUMBER,
    p_serial#        IN NUMBER DEFAULT NULL,
    p_begin_end_flag IN VARCHAR2,
    p_sequence       IN NUMBER DEFAULT NULL,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$sesstat (statement_id, statid, serial#, begin_end_flag, sequence'||
    p_insert_list||') SELECT :statement_id, :statid, :serial#, :begin_end_flag, :sequence'||
    p_select_list||' FROM gv$sesstat'||sqlt$a.s_db_link||' WHERE inst_id = :inst_id AND sid = :sid';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_serial#,IN p_begin_end_flag, 
      IN p_sequence, IN p_inst_id, IN p_sid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$sesstat;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$statname
   *
   * called by: sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$statname (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_insert_list  IN VARCHAR2,
    p_select_list  IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$statname (statement_id, statid'||
    p_insert_list||') SELECT :statement_id, :statid'||
    p_select_list||' FROM gv$statname'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$statname;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$pq_slave
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$pq_slave (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_begin_end_flag IN VARCHAR2,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$pq_slave (statement_id, statid, begin_end_flag'||
    p_insert_list||') SELECT :statement_id, :statid, :begin_end_flag'||
    p_select_list||' FROM gv$pq_slave'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_begin_end_flag;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$pq_slave;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$pq_sysstat
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$pq_sysstat (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_begin_end_flag IN VARCHAR2,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$pq_sysstat (statement_id, statid, begin_end_flag'||
    p_insert_list||') SELECT :statement_id, :statid, :begin_end_flag'||
    p_select_list||' FROM gv$pq_sysstat'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_begin_end_flag;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$pq_sysstat;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$px_sysstat
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$px_sysstat (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_begin_end_flag IN VARCHAR2,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$px_process_sysstat (statement_id, statid, begin_end_flag'||
    p_insert_list||') SELECT :statement_id, :statid, :begin_end_flag'||
    p_select_list||' FROM gv$px_process_sysstat'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_begin_end_flag;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$px_sysstat;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$px_process
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$px_process (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_begin_end_flag IN VARCHAR2,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$px_process (statement_id, statid, begin_end_flag'||
    p_insert_list||') SELECT :statement_id, :statid, :begin_end_flag'||
    p_select_list||' FROM gv$px_process'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_begin_end_flag;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$px_process;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$px_session
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$px_session (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_begin_end_flag IN VARCHAR2,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$px_session (statement_id, statid, begin_end_flag'||
    p_insert_list||') SELECT :statement_id, :statid, :begin_end_flag'||
    p_select_list||' FROM gv$px_session'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_begin_end_flag;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$px_session;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$pq_sesstat
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$pq_sesstat (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_begin_end_flag IN VARCHAR2,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$pq_sesstat (statement_id, statid, begin_end_flag'||
    p_insert_list||') SELECT :statement_id, :statid, :begin_end_flag'||
    p_select_list||' FROM gv$pq_sesstat'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_begin_end_flag;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$pq_sesstat;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$px_sesstat
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$px_sesstat (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_sid            IN NUMBER,
    p_begin_end_flag IN VARCHAR2,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$px_sesstat (statement_id, statid, begin_end_flag'||
    p_insert_list||') SELECT :statement_id, :statid, :begin_end_flag'||
    p_select_list||' FROM gv$px_sesstat'||sqlt$a.s_db_link||' WHERE qcsid = :sid';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_begin_end_flag, IN p_sid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;
  END collect_gv$px_sesstat;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_gv$px_group
   *
   * called by: sqlt$d.collect_perf_stats_begin and sqlt$d.collect_perf_stats_end
   *
   * ------------------------- */
  PROCEDURE collect_gv$px_group (
    p_statement_id   IN NUMBER,
    p_statid         IN VARCHAR2,
    p_begin_end_flag IN VARCHAR2,
    p_insert_list    IN VARCHAR2,
    p_select_list    IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
  BEGIN
    IF sqlt$a.get_rdbms_release >= 11 THEN
      l_sql :=
      'INSERT INTO sqlt$_gv$px_instance_group (statement_id, statid, begin_end_flag'||
      p_insert_list||') SELECT DISTINCT :statement_id, :statid, :begin_end_flag'||
      p_select_list||' FROM gv$px_instance_group'||sqlt$a.s_db_link;
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN p_begin_end_flag;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
      END;
    END IF;
  END collect_gv$px_group;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_gv$pq_tqstat
   *
   * 141028 removed p_insert_list and p_select_list and use sqlt$d.s_insert_list_pq_tqstat, sqlt$d.s_select_list_pq_tqstat internally
   * ------------------------- */
  PROCEDURE collect_gv$pq_tqstat (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    l_sql :=
    'INSERT INTO sqlt$_gv$pq_tqstat (statement_id, statid'||
    s_insert_list_pq_tqstat||') SELECT :statement_id, :statid'||
    s_select_list_pq_tqstat||' FROM gv$pq_tqstat'||sqlt$a.s_db_link;
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
    END;

    COMMIT; -- AUTONOMOUS_TRANSACTION
  END collect_gv$pq_tqstat;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dbms_xplan_cursor_last
   *
   * ------------------------- */
  PROCEDURE collect_dbms_xplan_cursor_last (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_sql            VARCHAR2(32767);
    l_count          NUMBER;
    l_format         VARCHAR2(100);
    l_short_format   VARCHAR2(3);
  BEGIN
    write_log('collect_dbms_xplan_cursor_last');
    
    l_format := CASE WHEN sqltxadmin.sqlt$a.get_rdbms_release >= '12.1' THEN PLAN_FORMAT_L12 ELSE PLAN_FORMAT_L END;
    l_short_format := CASE WHEN sqltxadmin.sqlt$a.get_rdbms_release >= '12.1' THEN 'L12' ELSE 'L' END;
    
    IF sqlt$a.s_db_link IS NULL THEN
      l_sql :=
      'INSERT INTO sqlt$_dbms_xplan (statement_id, statid, api, format, plan_hash_value, inst_id, child_number, executions, line_id, plan_table_output) '||
      'SELECT :statement_id1, :statid, :api, :format1, s.plan_hash_value, s.inst_id, s.child_number, s.executions, sqlt$_line_id_s.NEXTVAL, t.plan_table_output '||
      'FROM gv$sql s, TABLE(DBMS_XPLAN.DISPLAY(:table_name, NULL, :format2, ''inst_id = ''||s.inst_id||'' AND sql_id = ''''''||s.sql_id||'''''' AND child_number = ''||s.child_number)) t '||
      'WHERE s.sql_id = :sql_id AND s.hash_value = :hash_value AND s.loaded_versions > 0';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid, IN 'C', IN l_short_format,
        IN 'GV$SQL_PLAN_STATISTICS_ALL', IN l_format,
        IN p_sql_id, IN p_hash_value;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    ELSE
      l_sql :=
      'INSERT INTO sqlt$_dbms_xplan (statement_id, statid, api, format, plan_hash_value, inst_id, child_number, executions, line_id, plan_table_output) '||
      'SELECT :statement_id1, :statid, :api, :format1, s.plan_hash_value, s.inst_id, s.child_number, s.executions, sqlt$_line_id_s.NEXTVAL, t.plan_table_output '||
      'FROM sqlt$_gv$sql s, TABLE(DBMS_XPLAN.DISPLAY(:table_name, NULL, :format2, ''statement_id = ''||s.statement_id||'' AND source = ''''GV$SQL_PLAN'''' AND inst_id = ''||s.inst_id||'' AND sql_id = ''''''||s.sql_id||'''''' AND child_number = ''||s.child_number)) t '||
      'WHERE s.statement_id = :statement_id AND s.sql_id = :sql_id AND s.hash_value = :hash_value AND s.loaded_versions > 0';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid, IN 'C', IN 'L',
        IN 'SQLT$_PLAN_STATISTICS_V', IN l_format,
        IN p_statement_id, p_sql_id, IN p_hash_value;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END IF;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dbms_xplan WHERE statement_id = p_statement_id AND statid = p_statid
    AND api = 'C' AND format = l_short_format;
    write_log(l_count||' rows collected');
  END collect_dbms_xplan_cursor_last;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dbms_xplan_cursor_all
   *
   * ------------------------- */
  PROCEDURE collect_dbms_xplan_cursor_all (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_format         VARCHAR2(100);
    l_short_format   VARCHAR2(3);
  BEGIN
    write_log('collect_dbms_xplan_cursor_all');
    
    l_format := CASE WHEN sqltxadmin.sqlt$a.get_rdbms_release >= '12.1' THEN PLAN_FORMAT_A12 ELSE PLAN_FORMAT_A END;
    l_short_format := CASE WHEN sqltxadmin.sqlt$a.get_rdbms_release >= '12.1' THEN 'A12' ELSE 'A' END;	

    IF sqlt$a.s_db_link IS NULL THEN
      l_sql :=
      'INSERT INTO sqlt$_dbms_xplan (statement_id, statid, api, format, plan_hash_value, inst_id, child_number, executions, line_id, plan_table_output) '||
      'SELECT :statement_id1, :statid, :api, :format1, s.plan_hash_value, s.inst_id, s.child_number, s.executions, sqlt$_line_id_s.NEXTVAL, t.plan_table_output '||
      'FROM gv$sql s, TABLE(DBMS_XPLAN.DISPLAY(:table_name, NULL, :format2, ''inst_id = ''||s.inst_id||'' AND sql_id = ''''''||s.sql_id||'''''' AND child_number = ''||s.child_number)) t '||
      'WHERE s.sql_id = :sql_id AND s.hash_value = :hash_value AND s.loaded_versions > 0 AND s.executions > 1';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid, IN 'C', IN l_short_format,
        IN 'GV$SQL_PLAN_STATISTICS_ALL', IN l_format,
        IN p_sql_id, IN p_hash_value;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    ELSE
      l_sql :=
      'INSERT INTO sqlt$_dbms_xplan (statement_id, statid, api, format, plan_hash_value, inst_id, child_number, executions, line_id, plan_table_output) '||
      'SELECT :statement_id1, :statid, :api, :format1, s.plan_hash_value, s.inst_id, s.child_number, s.executions, sqlt$_line_id_s.NEXTVAL, t.plan_table_output '||
      'FROM sqlt$_gv$sql s, TABLE(DBMS_XPLAN.DISPLAY(:table_name, NULL, :format2, ''statement_id = ''||s.statement_id||'' AND source = ''''GV$SQL_PLAN'''' AND inst_id = ''||s.inst_id||'' AND sql_id = ''''''||s.sql_id||'''''' AND child_number = ''||s.child_number)) t '||
      'WHERE s.statement_id = :statement_id AND s.sql_id = :sql_id AND s.hash_value = :hash_value AND s.executions > 1';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid, IN 'C', IN l_short_format,
        IN 'SQLT$_PLAN_STATISTICS_V', IN l_format,
        IN p_statement_id, p_sql_id, IN p_hash_value;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END IF;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dbms_xplan WHERE statement_id = p_statement_id AND statid = p_statid
    AND api = 'C' AND format = l_short_format;
    write_log(l_count||' rows collected');
  END collect_dbms_xplan_cursor_all;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dbms_xplan_awr
   *
   * ------------------------- */
  PROCEDURE collect_dbms_xplan_awr (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_dbid        NUMBER := sqlt$a.get_database_id;

  BEGIN
    write_log('collect_dbms_xplan_awr');

    IF sqlt$a.get_param('automatic_workload_repository') = 'Y' AND sqlt$a.get_param_n('c_awr_hist_days') > 0  THEN
      IF sqlt$a.s_db_link IS NULL THEN
        l_sql :=
        'INSERT INTO sqlt$_dbms_xplan (statement_id, statid, api, format, plan_hash_value, line_id, plan_table_output) '||
        'SELECT :statement_id, :statid, :api, :format, h.plan_hash_value, sqlt$_line_id_s.NEXTVAL, t.plan_table_output '||
        'FROM (SELECT DISTINCT sql_id, plan_hash_value, dbid FROM sys.dba_hist_sql_plan WHERE dbid = :dbid AND sql_id = :sql_id) h, '||
        'TABLE(DBMS_XPLAN.DISPLAY_AWR(h.sql_id, h.plan_hash_value, h.dbid, :format)) t';
        write_log(l_sql, 'S');

        BEGIN
          EXECUTE IMMEDIATE l_sql USING
          IN p_statement_id, IN p_statid,
          IN 'A', IN 'V',
          IN l_dbid, IN p_sql_id, IN PLAN_FORMAT_V;
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error(l_sql);
            RETURN;
        END;

        COMMIT;
        SELECT COUNT(*) INTO l_count FROM sqlt$_dbms_xplan WHERE statement_id = p_statement_id AND statid = p_statid
        AND api = 'A' AND format = 'V';
        write_log(l_count||' rows collected');
      ELSE
        write_log('skip SYS.DBMS_XPLAN_AWR collection on stand-by db');
      END IF;
    ELSE
      write_log('skip SYS.DBMS_XPLAN_AWR collection as per parameter "automatic_workload_repository" or "c_awr_hist_days"');
    END IF;
  END collect_dbms_xplan_awr;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dbms_xplan_baseline
   *
   * ------------------------- */
  PROCEDURE collect_dbms_xplan_baseline (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dbms_xplan_baseline');

    l_sql :=
    'INSERT INTO sqlt$_dbms_xplan (statement_id, statid, api, format, sql_handle, plan_name, line_id, plan_table_output) '||
    'SELECT b.statement_id, :statid, :api, :format, b.sql_handle, b.plan_name, sqlt$_line_id_s.NEXTVAL, t.plan_table_output '||
    'FROM (SELECT statement_id, sql_handle, plan_name FROM sqlt$_dba_sql_plan_baselines WHERE statement_id = :statement_id) b, '||
    'TABLE(DBMS_XPLAN.DISPLAY_SQL_PLAN_BASELINE(b.sql_handle, b.plan_name, :format)) t';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statid, IN 'B', IN 'V',
      IN p_statement_id,
      IN PLAN_FORMAT_V;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dbms_xplan WHERE statement_id = p_statement_id AND statid = p_statid
    AND api = 'B' AND format = 'V';
    write_log(l_count||' rows collected');
  END collect_dbms_xplan_baseline;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dbms_xplan_display
   *
   * ------------------------- */
  PROCEDURE collect_dbms_xplan_display (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_format         VARCHAR2(100);
    l_short_format   VARCHAR2(3);
  BEGIN
    write_log('collect_dbms_xplan_display');
    
    l_format := CASE WHEN sqltxadmin.sqlt$a.get_rdbms_release >= '12.1' THEN PLAN_FORMAT_V12 ELSE PLAN_FORMAT_V END;
    l_short_format := CASE WHEN sqltxadmin.sqlt$a.get_rdbms_release >= '12.1' THEN 'V12' ELSE 'V' END;	

    IF sqlt$a.s_db_link IS NULL THEN
      sql_rec := sqlt$a.get_statement(p_statement_id);

      l_sql :=
      'INSERT INTO sqlt$_dbms_xplan (statement_id, statid, api, format, plan_hash_value, line_id, plan_table_output) '||
      'SELECT :statement_id, :statid, :api, :format, :plan_hash_value, sqlt$_line_id_s.NEXTVAL, t.plan_table_output '||
      'FROM TABLE(DBMS_XPLAN.DISPLAY(:plan_table, :statement, :format)) t';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN 'D', IN l_short_format, IN sql_rec.xplain_plan_hash_value,
        IN 'SQLT$_SQL_PLAN_TABLE',
        IN sqlt$a.get_statement_id_c(p_statement_id), IN l_format;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_dbms_xplan WHERE statement_id = p_statement_id AND statid = p_statid
      AND api = 'D' AND format = l_short_format;
      write_log(l_count||' rows collected');
    ELSE
      write_log('skip SYS.DBMS_XPLAN_DISPLAY collection on stand-by db');
    END IF;
  END collect_dbms_xplan_display;

  /*************************************************************************************/

  /* -------------------------
   *
   * public max_plan_elapsed_time_secs
   *
   * called by sqlt$i.sql_tuning_advisor
   *
   * ------------------------- */
  FUNCTION max_plan_elapsed_time_secs (p_statement_id IN NUMBER)
  RETURN NUMBER
  IS
    l_max_plan_et_secs NUMBER;
  BEGIN
    SELECT MAX(ROUND(elapsed_time / 1e6, 3))
      INTO l_max_plan_et_secs
      FROM sqlt$_plan_summary_v
     WHERE statement_id = p_statement_id;

    RETURN l_max_plan_et_secs;
  END max_plan_elapsed_time_secs;

  /*************************************************************************************/

  /* -------------------------
   *
   * private create_tuning_task_memory
   *
   * ------------------------- */
  PROCEDURE create_tuning_task_memory (
    p_statement_id IN NUMBER,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_count NUMBER;
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> create_tuning_task_memory');

    IF sqlt$a.get_param('sql_tuning_advisor') = 'N' THEN
      write_log('skip SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK from memory as per parameter "sql_tuning_advisor"');
    ELSIF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK from memory for stand-by db');
    ELSIF NVL(sqlt$a.s_xtrxec, 'N') = 'Y' THEN -- s_xtrxec is Y during XECUTE phase
      write_log('skip SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK from memory as per parameter "sqlt$a.s_xtrxec"'); -- done during XTRACT phase
    ELSE
      sql_rec := sqlt$a.get_statement(p_statement_id);

      SELECT COUNT(*)
        INTO l_count
        FROM gv$sql
       WHERE sql_id = p_sql_id
         AND hash_value = p_hash_value
         AND ROWNUM = 1;

      IF l_count > 0 THEN
        sql_rec.sta_task_name_mem := SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK (
          sql_id     => p_sql_id,
          time_limit => sqlt$a.get_param_n('sta_time_limit_secs'),
          task_name  => 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_mem' );

        UPDATE sqlt$_sql_statement
           SET sta_task_name_mem = sql_rec.sta_task_name_mem
         WHERE statement_id = p_statement_id;

        COMMIT;
        write_log('task name = "'||sql_rec.sta_task_name_mem||'"');
      ELSE
        write_log('skip SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK from memory since SQL is not in GV$SQL');
      END IF;
    END IF;

    write_log('<- create_tuning_task_memory');
  EXCEPTION
    WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error('DBMS_SQLTUNE.CREATE_TUNING_TASK from memory failed.');
  END create_tuning_task_memory;

  /*************************************************************************************/

  /* -------------------------
   *
   * private create_tuning_task_text
   *
   * ------------------------- */
  PROCEDURE create_tuning_task_text (
    p_statement_id IN NUMBER,
    p_sql_id       IN VARCHAR2,
    p_hash_value   IN NUMBER )
  IS
    l_schema_name VARCHAR2(257);
    l_idx NUMBER := 0;
    l_binds sql_binds := sql_binds ( );
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> create_tuning_task_text');

    IF sqlt$a.get_param('sql_tuning_advisor') = 'N' THEN
      write_log('skip SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK from text as per parameter "sql_tuning_advisor"');
    ELSE
      sql_rec := sqlt$a.get_statement(p_statement_id);

      IF sql_rec.method = 'XECUTE' THEN
        BEGIN
          SELECT parsing_schema_name
            INTO l_schema_name
            FROM v$sql
           WHERE sql_id = p_sql_id
             AND hash_value = p_hash_value
             AND child_number = 0
             AND parsing_schema_name IS NOT NULL
             AND ROWNUM = 1;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            l_schema_name := USER;
        END;
        write_log('parsing_schema_name:'||l_schema_name);

        FOR i IN (SELECT b1.position,
                         b1.dup_position,
                         b1.name,
                         b1.datatype_string,
                         b1.was_captured,
                         b1.value_string value_string,
                         NVL(b1.value_anydata, b2.value_anydata) value_anydata
                    FROM v$sql_bind_capture b1,
                         v$sql_bind_capture b2
                   WHERE b1.sql_id = p_sql_id
                     AND b1.hash_value = p_hash_value
                     AND b1.child_number = 0
                     AND b1.sql_id = b2.sql_id(+)
                     AND b1.hash_value = b2.hash_value(+)
                     AND b1.child_number = b2.child_number(+)
                     AND b1.dup_position = b2.position(+)
                   ORDER BY
                         b1.position)
        LOOP
          write_log('pos:'||i.position||' dup_pos:'||i.dup_position||' name:"'||i.name||'" type:'||i.datatype_string||' captured:'||i.was_captured||' value:'||i.value_string);
          l_binds.EXTEND;
          l_idx := l_idx + 1;
          l_binds(l_idx) := i.value_anydata;
        END LOOP;

        IF l_idx > 0 THEN
          sql_rec.sta_task_name_txt := SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK (
            sql_text   => sql_rec.sql_text_clob_stripped,
            bind_list  => l_binds,
            user_name  => l_schema_name,
            time_limit => sqlt$a.get_param_n('sta_time_limit_secs'),
            task_name  => 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_txt' );
        ELSE
          sql_rec.sta_task_name_txt := SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK (
            sql_text   => sql_rec.sql_text_clob_stripped,
            user_name  => l_schema_name,
            time_limit => sqlt$a.get_param_n('sta_time_limit_secs'),
            task_name  => 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_txt' );
        END IF;

        UPDATE sqlt$_sql_statement
           SET sta_task_name_txt = sql_rec.sta_task_name_txt
         WHERE statement_id = p_statement_id;

        COMMIT;
        write_log('task name = "'||sql_rec.sta_task_name_mem||'"');
      END IF;
    END IF;

    write_log('<- create_tuning_task_text');
  EXCEPTION
    WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error('DBMS_SQLTUNE.CREATE_TUNING_TASK from text failed.');
  END create_tuning_task_text;

  /*************************************************************************************/

  /* -------------------------
   *
   * private create_tuning_task_awr
   *
   * ------------------------- */
  PROCEDURE create_tuning_task_awr (
    p_statement_id IN NUMBER,
    p_sql_id       IN VARCHAR2 )
  IS
    l_begin_snap NUMBER;
    l_end_snap   NUMBER;
    l_startup_time sys.dba_hist_snapshot.startup_time%TYPE;
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('-> create_tuning_task_awr');

    IF sqlt$a.get_param('sql_tuning_advisor') = 'N' THEN
      write_log('skip SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK from AWR as per parameter "sql_tuning_advisor"');
    ELSIF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK from AWR for stand-by db');
    ELSIF NVL(sqlt$a.s_xtrxec, 'N') = 'Y' THEN -- s_xtrxec is Y during XECUTE phase
      write_log('skip SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK from AWR as per parameter "sqlt$a.s_xtrxec"'); -- done during XTRACT phase
    ELSE
      sql_rec := sqlt$a.get_statement(p_statement_id);

      SELECT MAX(snap_id)
        INTO l_end_snap
        FROM sys.dba_hist_sqlstat
       WHERE dbid = sql_rec.database_id
         AND sql_id = p_sql_id;

      write_log('end_snap:'||l_end_snap);

      SELECT MIN(startup_time)
        INTO l_startup_time
        FROM sys.dba_hist_snapshot
       WHERE dbid = sql_rec.database_id
         AND snap_id = l_end_snap;

      write_log('min startup_time:'||l_startup_time);

      SELECT MIN(sq.snap_id)
        INTO l_begin_snap
        FROM sys.dba_hist_sqlstat sq,
             sys.dba_hist_snapshot sh
       WHERE sq.dbid = sql_rec.database_id
         AND sq.sql_id = p_sql_id
         AND sh.snap_id = sq.snap_id
         AND sh.dbid = sq.dbid
         AND sh.instance_number = sq.instance_number
         AND sh.startup_time >= l_startup_time;

      write_log('begin_snap:'||l_begin_snap||' end_snap:'||l_end_snap);

      IF l_end_snap > l_begin_snap THEN
        sql_rec.sta_task_name_awr := SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK (
          begin_snap => l_begin_snap,
          end_snap   => l_end_snap,
          sql_id     => p_sql_id,
          time_limit => sqlt$a.get_param_n('sta_time_limit_secs'),
          task_name  => 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_awr' );

        UPDATE sqlt$_sql_statement
           SET sta_task_name_awr = sql_rec.sta_task_name_awr
         WHERE statement_id = p_statement_id;

        COMMIT;
        write_log('task name = "'||sql_rec.sta_task_name_awr||'"');
      ELSE
        write_log('skip SYS.DBMS_SQLTUNE.CREATE_TUNING_TASK from AWR since begin and end snap are the same = "'||l_begin_snap||'"');
      END IF;
    END IF;

    write_log('<- create_tuning_task_awr');
  EXCEPTION
    WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error('DBMS_SQLTUNE.CREATE_TUNING_TASK from AWR failed.');
  END create_tuning_task_awr;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_outlines
   *
   * ------------------------- */
  PROCEDURE collect_dba_outlines (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_outlines');
    get_list_of_columns (
      p_source_table      => 'dba_outlines',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_outlines',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_outlines (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_sql_statement x, sys.dba_outlines t '||
    'WHERE x.statement_id = :statement_id AND t.signature IN(x.signature_so, x.signature_so_unstripped)';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_outlines WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_outlines;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_outline_hints
   *
   * ------------------------- */
  PROCEDURE collect_dba_outline_hints (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_outline_hints');
    get_list_of_columns (
      p_source_table      => 'dba_outline_hints',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_outline_hints',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_outline_hints (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_dba_outlines x, sys.dba_outline_hints t '||
    'WHERE x.statement_id = :statement_id AND x.name = t.name';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_outline_hints WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_outline_hints;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_wri$_adv_tasks
   *
   * ------------------------- */
  PROCEDURE collect_wri$_adv_tasks (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_wri$_adv_tasks');

    --IF sqlt$a.get_param('sql_tuning_advisor') = 'Y' THEN
      get_list_of_columns (
        p_source_table      => 'wri$_adv_tasks',
        p_source_alias      => 't',
        p_destination_table => 'sqlt$_wri$_adv_tasks',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_wri$_adv_tasks (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM sqlt$_sql_statement x, sys.wri$_adv_tasks t '||
      'WHERE x.statement_id = :statement_id AND t.name IN (x.sta_task_name_mem,  x.sta_task_name_awr, x.sta_task_name_txt)';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN p_statement_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_wri$_adv_tasks WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    --ELSE
    --  write_log('skip WRI$_ADV_TASKS collection as per parameter "sql_tuning_advisor"');
    --END IF;
  END collect_wri$_adv_tasks;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_wri$_adv_rationale
   *
   * ------------------------- */
  PROCEDURE collect_wri$_adv_rationale (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_wri$_adv_rationale');

    --IF sqlt$a.get_param('sql_tuning_advisor') = 'Y' THEN
      get_list_of_columns (
        p_source_table      => 'wri$_adv_rationale',
        p_source_alias      => 't',
        p_destination_table => 'sqlt$_wri$_adv_rationale',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_wri$_adv_rationale (statement_id, statid'||
      l_insert_list||') SELECT :statement_id, :statid'||
      l_select_list||' FROM sqlt$_wri$_adv_tasks x, sys.wri$_adv_rationale t '||
      'WHERE x.statement_id = :statement_id AND x.id = t.task_id';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING
        IN p_statement_id, IN p_statid,
        IN p_statement_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      COMMIT;
      SELECT COUNT(*) INTO l_count FROM sqlt$_wri$_adv_rationale WHERE statement_id = p_statement_id;
      write_log(l_count||' rows collected');
    --ELSE
    --  write_log('skip WRI$_ADV_RATIONALE collection as per parameter "sql_tuning_advisor"');
    --END IF;
  END collect_wri$_adv_rationale;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_sqltune_plans
   *
   * ------------------------- */
  PROCEDURE collect_dba_sqltune_plans (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_sqltune_plans');

    get_list_of_columns (
      p_source_table      => 'dba_sqltune_plans',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_sqltune_plans',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_sqltune_plans (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_wri$_adv_tasks x, sys.dba_sqltune_plans t '||
    'WHERE x.statement_id = :statement_id AND x.id = t.task_id AND t.plan_id > 0';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_sqltune_plans WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_sqltune_plans;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_sql_profiles
   *
   * ------------------------- */
  PROCEDURE collect_dba_sql_profiles (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_sql_profiles');

    get_list_of_columns (
      p_source_table      => 'dba_sql_profiles',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_sql_profiles',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_sql_profiles (statement_id, statid'||
    l_insert_list||') SELECT /*+ DRIVING_SITE(t) */ :statement_id, :statid'||
    l_select_list||' FROM sqlt$_sql_statement x, sys.dba_sql_profiles'||sqlt$a.s_db_link||' t '||
    'WHERE x.statement_id = :statement_id AND t.signature IN (x.signature_sta,  x.signature_sta_force_match, x.signature_sta_unstripped, x.signature_sta_fm_unstripped)';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_sql_profiles WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    IF l_count > 0 THEN
      write_log('collect_stgtab_sqlprof');

      DELETE sqli$_stgtab_sqlprof;

      FOR i IN (SELECT DISTINCT name FROM sqlt$_dba_sql_profiles WHERE statement_id = p_statement_id AND (status = 'ENABLED' OR status IS NULL))
      LOOP
        BEGIN
          SYS.DBMS_SQLTUNE.PACK_STGTAB_SQLPROF(profile_name => i.name, staging_table_name => 'SQLI$_STGTAB_SQLPROF', staging_schema_owner => TOOL_REPOSITORY_SCHEMA);
        EXCEPTION
          WHEN OTHERS THEN
            write_error('collect_dba_sql_profiles: '||i.name||': '||SQLERRM);
        END;
      END LOOP;

      get_list_of_columns (
        p_source_owner      => TOOL_REPOSITORY_SCHEMA,
        p_source_table      => 'sqli$_stgtab_sqlprof',
        p_destination_table => 'sqlt$_stgtab_sqlprof',
        x_insert_list       => l_insert_list,
        x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_stgtab_sqlprof (statid'||
      l_insert_list||') SELECT :statid'||
      l_select_list||' FROM sqli$_stgtab_sqlprof';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING IN p_statid;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      UPDATE sqlt$_stgtab_sqlprof
         SET statid = p_statid
       WHERE statid IS NULL;

      DELETE sqli$_stgtab_sqlprof;
    END IF;

    COMMIT;
  END collect_dba_sql_profiles;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_sql_patches
   *
   * ------------------------- */
  PROCEDURE collect_dba_sql_patches (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_dba_sql_patches');

    get_list_of_columns (
      p_source_table      => 'dba_sql_patches',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_sql_patches',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_sql_patches (statement_id, statid'||
    l_insert_list||') SELECT /*+ DRIVING_SITE(t) */ :statement_id, :statid'||
    l_select_list||' FROM sqlt$_sql_statement x, sys.dba_sql_patches'||sqlt$a.s_db_link||' t '||
    'WHERE x.statement_id = :statement_id AND t.signature IN (x.signature_sta,  x.signature_sta_force_match, x.signature_sta_unstripped, x.signature_sta_fm_unstripped)';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_dba_sql_patches WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_dba_sql_patches;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_plan_metrics
   *
   * ------------------------- */
  FUNCTION get_plan_metrics (
    p_statement_id    IN NUMBER,
    p_plan_hash_value IN NUMBER )
  RETURN VARCHAR2
  IS
    v_rec sqlt$_plan_summary_v2%ROWTYPE;
  BEGIN
    SELECT * INTO v_rec FROM sqlt$_plan_summary_v2 WHERE statement_id = p_statement_id AND plan_hash_value = p_plan_hash_value;
    RETURN '(et:'||TRIM(v_rec.elapsed_time_secs)||'s, cpu:'||TRIM(v_rec.cpu_time_secs)||'s, buffers:'||v_rec.buffer_gets||', rows:'||v_rec.rows_processed||')';
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_plan_metrics;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_plan_rank
   *
   * ------------------------- */
  FUNCTION get_plan_rank (
    p_statement_id    IN NUMBER,
    p_plan_hash_value IN NUMBER )
  RETURN VARCHAR2
  IS
    l_rank NUMBER := 0;
  BEGIN
    FOR i IN (SELECT plan_hash_value
                FROM sqlt$_plan_summary_v2
               WHERE statement_id = p_statement_id
               ORDER BY
                     elapsed_time ASC NULLS LAST,
                     src_order,
                     optimizer_cost ASC NULLS LAST)
    LOOP
      l_rank := l_rank + 1;
      IF i.plan_hash_value = p_plan_hash_value THEN
        EXIT;
      END IF;
    END LOOP;

    RETURN LPAD(l_rank, 3, '0');
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_plan_rank;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_tuning_sets_mem
   *
   * ------------------------- */
  PROCEDURE collect_tuning_sets_mem (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_sqlset_name VARCHAR2(257);
    l_api         VARCHAR2(256);
    l_description VARCHAR2(256);
    sts_cur       SYS.DBMS_SQLTUNE.SQLSET_CURSOR;
  BEGIN
    write_log('-> collect_tuning_sets_mem');

    IF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip TUNING_SETS collection for stand-by db');
    ELSIF sqlt$a.get_param('sql_tuning_advisor') = 'Y' AND sqlt$a.get_param('sql_tuning_set') = 'Y' THEN
      DELETE sqli$_stgtab_sqlset;

      FOR i IN (SELECT DISTINCT plan_hash_value
                  FROM sqlt$_gv$sql_plan
                 WHERE statement_id = p_statement_id
                   AND inst_id = sqlt$a.get_instance_number -- SYS.DBMS_SQLTUNE.SELECT_CURSOR_CACHE reads from SYS.V$ and not gv$
                 ORDER BY
                       plan_hash_value)
      LOOP
        BEGIN
          write_log('sqlt$_gv$sql_plan: '||i.plan_hash_value);
          l_sqlset_name := 's'||sqlt$a.get_statement_id_c(p_statement_id)||'_'||i.plan_hash_value||'_mem';
          l_description := get_plan_rank(p_statement_id, i.plan_hash_value)||' '||p_statid||'_'||p_sql_id||'_'||i.plan_hash_value||'_mem '||get_plan_metrics(p_statement_id, i.plan_hash_value);

          l_api := 'DBMS_SQLTUNE.CREATE_SQLSET';
          l_sqlset_name :=
          SYS.DBMS_SQLTUNE.CREATE_SQLSET (
            sqlset_name  => l_sqlset_name,
            description  => l_description,
            sqlset_owner => TOOL_ADMINISTER_SCHEMA );
          write_log('created sqlset: '||l_sqlset_name);

          OPEN sts_cur FOR
            SELECT VALUE(p)
              FROM TABLE(DBMS_SQLTUNE.SELECT_CURSOR_CACHE (
              'sql_id = '''||p_sql_id||''' AND plan_hash_value = '||i.plan_hash_value||' AND loaded_versions > 0',
              NULL, NULL, NULL, NULL, 1, NULL, 'ALL')) p;

          l_api := 'DBMS_SQLTUNE.LOAD_SQLSET';
          SYS.DBMS_SQLTUNE.LOAD_SQLSET (
            sqlset_name     => l_sqlset_name,
            populate_cursor => sts_cur );
          write_log('loaded sqlset: '||l_sqlset_name);

          CLOSE sts_cur;

          IF sqlt$a.get_rdbms_version >= '11.2' THEN
            l_api := 'DBMS_SQLTUNE.PACK_STGTAB_SQLSET';
            SYS.DBMS_SQLTUNE.PACK_STGTAB_SQLSET (
              sqlset_name          => l_sqlset_name,
              sqlset_owner         => TOOL_ADMINISTER_SCHEMA,
              staging_table_name   => 'SQLI$_STGTAB_SQLSET',
              staging_schema_owner => TOOL_REPOSITORY_SCHEMA );
            write_log('packed sqlset: '||l_sqlset_name);
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error(l_api);
        END;
      END LOOP;

      IF sqlt$a.get_rdbms_version >= '11.2' THEN
        get_list_of_columns (
          p_source_owner      => TOOL_REPOSITORY_SCHEMA,
          p_source_table      => 'sqli$_stgtab_sqlset',
          p_destination_table => 'sqlt$_stgtab_sqlset',
          x_insert_list       => l_insert_list,
          x_select_list       => l_select_list );

        l_sql :=
        'INSERT INTO sqlt$_stgtab_sqlset (statid'||
        l_insert_list||') SELECT :statid'||
        l_select_list||' FROM sqli$_stgtab_sqlset WHERE name LIKE :name';
        write_log(l_sql, 'S');

        BEGIN
          EXECUTE IMMEDIATE l_sql USING IN p_statid, IN 's'||sqlt$a.get_statement_id_c(p_statement_id)||'%mem';
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error(l_sql);
            RETURN;
        END;

        UPDATE sqlt$_stgtab_sqlset
           SET statid = p_statid
         WHERE statid IS NULL;
      END IF;

      COMMIT;
    ELSE
      write_log('skip TUNING_SETS collection as per parameters "sql_tuning_advisor" or "sql_tuning_set"');
    END IF;

    write_log('<- collect_tuning_sets_mem');
  END collect_tuning_sets_mem;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_tuning_sets_awr
   *
   * ------------------------- */
  PROCEDURE collect_tuning_sets_awr (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sql_id       IN VARCHAR2 )
  IS
    l_begin_snap  NUMBER;
    l_end_snap    NUMBER;
    l_startup_time sys.dba_hist_snapshot.startup_time%TYPE;
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_sqlset_name VARCHAR2(257);
    l_api         VARCHAR2(256);
    l_description VARCHAR2(256);
    sql_rec sqlt$_sql_statement%ROWTYPE;
    sts_cur       SYS.DBMS_SQLTUNE.SQLSET_CURSOR;
  BEGIN
    write_log('collect_tuning_sets_awr');

    IF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip TUNING_SETS collection for stand-by db');
    ELSIF sqlt$a.get_param('sql_tuning_advisor') = 'Y' AND sqlt$a.get_param('sql_tuning_set') = 'Y' THEN
      sql_rec := sqlt$a.get_statement(p_statement_id);
      DELETE sqli$_stgtab_sqlset;

      FOR i IN (SELECT DISTINCT plan_hash_value
                  FROM sqlt$_dba_hist_sql_plan
                 WHERE statement_id = p_statement_id
                 MINUS
                SELECT DISTINCT plan_hash_value
                  FROM sqlt$_gv$sql_plan
                 WHERE statement_id = p_statement_id
                   AND inst_id = sqlt$a.get_instance_number
                 ORDER BY
                       1)
      LOOP
        BEGIN
          write_log('sqlt$_dba_hist_sql_plan: '||i.plan_hash_value);

          SELECT MAX(snap_id)
            INTO l_end_snap
            FROM sys.dba_hist_sqlstat
           WHERE dbid = sql_rec.database_id
             AND sql_id = p_sql_id
             AND plan_hash_value = i.plan_hash_value;

          write_log('end_snap:'||l_end_snap);

          SELECT MIN(startup_time)
            INTO l_startup_time
            FROM sys.dba_hist_snapshot
           WHERE dbid = sql_rec.database_id
             AND snap_id = l_end_snap;

          write_log('min startup_time:'||l_startup_time);

          SELECT MIN(sq.snap_id)
            INTO l_begin_snap
            FROM sys.dba_hist_sqlstat sq,
                 sys.dba_hist_snapshot sh
           WHERE sq.dbid = sql_rec.database_id
             AND sq.sql_id = p_sql_id
             AND sq.plan_hash_value = i.plan_hash_value
             AND sh.snap_id = sq.snap_id
             AND sh.dbid = sq.dbid
             AND sh.instance_number = sq.instance_number
             AND sh.startup_time >= l_startup_time;

          write_log('begin_snap:'||l_begin_snap||' end_snap:'||l_end_snap);

          IF l_end_snap > l_begin_snap THEN
            l_sqlset_name := 's'||sqlt$a.get_statement_id_c(p_statement_id)||'_'||i.plan_hash_value||'_awr';
            l_description := get_plan_rank(p_statement_id, i.plan_hash_value)||' '||p_statid||'_'||p_sql_id||'_'||i.plan_hash_value||'_awr '||get_plan_metrics(p_statement_id, i.plan_hash_value);

            l_api := 'DBMS_SQLTUNE.CREATE_SQLSET';
            l_sqlset_name :=
            SYS.DBMS_SQLTUNE.CREATE_SQLSET (
              sqlset_name  => l_sqlset_name,
              description  => l_description,
              sqlset_owner => TOOL_ADMINISTER_SCHEMA );
            write_log('created sqlset: '||l_sqlset_name);

            OPEN sts_cur FOR
              SELECT VALUE(p)
                FROM TABLE(DBMS_SQLTUNE.SELECT_WORKLOAD_REPOSITORY (l_begin_snap, l_end_snap,
                'sql_id = '''||p_sql_id||''' AND plan_hash_value = '||i.plan_hash_value||' AND loaded_versions > 0',
                NULL, NULL, NULL, NULL, 1, NULL, 'ALL')) p;

            l_api := 'DBMS_SQLTUNE.LOAD_SQLSET';
            SYS.DBMS_SQLTUNE.LOAD_SQLSET (
              sqlset_name     => l_sqlset_name,
              populate_cursor => sts_cur );
            write_log('loaded sqlset: '||l_sqlset_name);

            CLOSE sts_cur;

            IF sqlt$a.get_rdbms_version >= '11.2' THEN
              l_api := 'DBMS_SQLTUNE.PACK_STGTAB_SQLSET';
              SYS.DBMS_SQLTUNE.PACK_STGTAB_SQLSET (
                sqlset_name          => l_sqlset_name,
                sqlset_owner         => TOOL_ADMINISTER_SCHEMA,
                staging_table_name   => 'SQLI$_STGTAB_SQLSET',
                staging_schema_owner => TOOL_REPOSITORY_SCHEMA );
              write_log('packed sqlset: '||l_sqlset_name);
            END IF;
          ELSE
            write_log('skip SYS.DBMS_SQLTUNE.CREATE_SQLSET from AWR since begin and end snap are the same = "'||l_begin_snap||'"');
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error(l_api);
        END;
      END LOOP;

      IF sqlt$a.get_rdbms_version >= '11.2' THEN
        get_list_of_columns (
          p_source_owner      => TOOL_REPOSITORY_SCHEMA,
          p_source_table      => 'sqli$_stgtab_sqlset',
          p_destination_table => 'sqlt$_stgtab_sqlset',
          x_insert_list       => l_insert_list,
          x_select_list       => l_select_list );

        l_sql :=
        'INSERT INTO sqlt$_stgtab_sqlset (statid'||
        l_insert_list||') SELECT :statid'||
        l_select_list||' FROM sqli$_stgtab_sqlset WHERE name LIKE :name';
        write_log(l_sql, 'S');

        BEGIN
          EXECUTE IMMEDIATE l_sql USING IN p_statid, IN 's'||sqlt$a.get_statement_id_c(p_statement_id)||'%awr';
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error(l_sql);
            RETURN;
        END;

        UPDATE sqlt$_stgtab_sqlset
           SET statid = p_statid
         WHERE statid IS NULL;
      END IF;

      COMMIT;
    ELSE
      write_log('skip TUNING_SETS collection as per parameters "sql_tuning_advisor" or "sql_tuning_set"');
    END IF;
  END collect_tuning_sets_awr;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_sql_plan_baselines
   *
   * ------------------------- */
  PROCEDURE collect_dba_sql_plan_baselines (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_sql_handle  VARCHAR2(257);

  BEGIN
    write_log('collect_dba_sql_plan_baselines');

    get_list_of_columns (
      p_source_table      => 'dba_sql_plan_baselines',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_dba_sql_plan_baselines',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_sql_plan_baselines (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_sql_statement x, sys.dba_sql_plan_baselines t '||
    'WHERE x.statement_id = :statement_id AND t.signature IN (x.signature_sta,  x.signature_sta_force_match, x.signature_sta_unstripped, x.signature_sta_fm_unstripped)';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    SELECT COUNT(*), MIN(sql_handle) INTO l_count, l_sql_handle
    FROM sqlt$_dba_sql_plan_baselines WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    IF l_count > 0 AND l_sql_handle IS NOT NULL THEN
      UPDATE sqlt$_sql_statement
         SET sql_handle = l_sql_handle
       WHERE statement_id = p_statement_id;
    END IF;

    COMMIT;

    IF l_count > 0 AND l_sql_handle IS NOT NULL THEN
      write_log('collect_stgtab_baseline');

      IF sqlt$a.get_rdbms_version = '11.2.0.1.0' THEN
        UPDATE sqlt$_stgtab_baseline
           SET version = 2
         WHERE version <> 2;
      ELSIF sqlt$a.get_rdbms_version = '11.2.0.2.0' THEN
        UPDATE sqlt$_stgtab_baseline
           SET version = 3
         WHERE version <> 3;
      END IF;

      l_sql := 'BEGIN :plans := SYS.DBMS_SPM.PACK_STGTAB_BASELINE(table_name => :table_name, table_owner => :table_owner, sql_handle => :sql_handle); END;';

      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql
        USING OUT l_count, IN 'SQLT$_STGTAB_BASELINE', IN TOOL_REPOSITORY_SCHEMA, IN l_sql_handle;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      write_log(l_count||' plans collected');

      UPDATE sqlt$_stgtab_baseline
         SET statid = p_statid,
             action = p_statid
       WHERE statid IS NULL;
    END IF;

    COMMIT;
  END collect_dba_sql_plan_baselines;


  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dba_sql_plan_directs
   * 151008 Fix to avoid ora-6502 on packing SPD.
   * 150828 Remade Procedure
   * 22170173 Add DBMS_ASSERT
   * ------------------------- */
  PROCEDURE collect_dba_sql_plan_directs (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;
    l_owner varchar2(32767);
	l_object varchar2(32767);

   PROCEDURE add_object (
    p_owner IN VARCHAR2,
	p_object IN VARCHAR2) is
   BEGIN
   -- 22170173
    l_owner:=DBMS_ASSERT.QUALIFIED_SQL_NAME(P_OWNER);
	l_object:=DBMS_ASSERT.QUALIFIED_SQL_NAME(p_object);
      l_sql:=l_sql||q'[
my_list.extend(1);
my_list(my_list.count).owner := '"]'||l_owner||'"'';' 
||q'[
my_list(my_list.count).object_name := '"]'||l_object||'"'';'
||q'[
my_list(my_list.count).object_type := 'TABLE';
]';   
	EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
   END;
	
   PROCEDURE pack is
   l_exec varchar2(32767);
   begin
	l_sql:=q'[
DECLARE
  my_list  DBMS_SPD.OBJECTTAB := DBMS_SPD.ObjectTab();
BEGIN
 dbms_spd.flush_sql_plan_directive; 
]'||l_sql||q'[
  :dir_cnt :=  DBMS_SPD.PACK_STGTAB_DIRECTIVE(table_name => :table_name, table_owner => :table_owner, obj_list => my_list);
END;]';

	begin
	 execute immediate l_sql
     using out l_count,IN 'SQLT$_STGTAB_DIRECTIVE', IN TOOL_REPOSITORY_SCHEMA;
	EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
		l_sql:=' ';
        RETURN;
    END;
	
	write_log(l_sql, 'S');
	write_log(l_count||' SQL Plan Directives Packed');
    l_sql:=' ';
   end;
	
  BEGIN
    write_log('collect_dba_sql_plan_dir_objects');

    get_list_of_columns (
	  p_source_owner      => TOOL_ADMINISTER_SCHEMA,	
      p_source_table      => 'sqlt$_dba_spdo_v',
      p_source_alias      => 'vo',
      p_destination_table => 'sqlt$_dba_sql_plan_dir_objs',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_sql_plan_dir_objs (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_dba_spdo_v vo '||
	'WHERE vo.directive_id in '||
	'(select do.directive_id from dba_sql_plan_dir_objects do '||
    'WHERE (do.owner, do.object_name) in '||
	'(select o.owner,o.object_name from sqlt$_dba_objects o where o.statement_id = :statement_id)) ';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    l_count:=SQL%ROWCOUNT;
    write_log(l_count||' rows collected');

	IF l_count=0 then RETURN; END IF;

    write_log('collect_dba_sql_plan_directives');

    get_list_of_columns (
	  p_source_owner      => TOOL_ADMINISTER_SCHEMA,
      p_source_table      => 'sqlt$_dba_spd_v',
      p_source_alias      => 'd',
      p_destination_table => 'sqlt$_dba_sql_plan_directives',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_dba_sql_plan_directives (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_dba_spd_v d '||
	'WHERE d.directive_id in (select do.directive_id from sqlt$_dba_sql_plan_dir_objs do where do.statement_id = :statement_id)';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;
    
	l_count:=SQL%ROWCOUNT;
    write_log(l_count||' rows collected');

    COMMIT;
	IF l_count=0 then RETURN; END IF;
	
    -- pack directives ( watch for bug 19731829)
	write_log('collect_stgtab_directive');

	l_sql:=' ';
	FOR i IN (SELECT distinct o.owner, o.object_name 
                FROM sqlt$_dba_sql_plan_dir_objs o
               WHERE o.statement_id = p_statement_id) loop
     if length(l_sql)<20000 then
      add_object(i.owner,i.object_name);
     else			  		   
      pack;
     end if;
    END LOOP;
 
    IF length(l_sql)>1 THEN
	 pack;
	END IF;

    UPDATE sqlt$_stgtab_directive
       SET statid = p_statid
     WHERE statid IS NULL;

    COMMIT;

  EXCEPTION
   WHEN OTHERS THEN
    write_error(SQLERRM||' in collect_dba_sql_plan_directs');
    RETURN;	
  END collect_dba_sql_plan_directs;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_phv_4_sql_plan_baselines
   *
   * ------------------------- */
  PROCEDURE get_phv_4_sql_plan_baselines (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_plan_hash_value VARCHAR2(300);
  BEGIN
    write_log('collect_dba_sql_plan_baselines');

    FOR i IN (SELECT b.ROWID row_id, p.plan_table_output
                FROM sqlt$_dba_sql_plan_baselines b,
                     sqlt$_dbms_xplan p
               WHERE b.statement_id = p_statement_id
                 AND b.statement_id = p.statement_id
                 AND b.sql_handle = p.sql_handle
                 AND b.plan_name = p.plan_name
                 AND p.api = 'B'
                 AND p.format = 'V'
                 AND UPPER(p.plan_table_output) like '%PLAN% %HASH% %VALUE%:%')
    LOOP
      l_plan_hash_value := TRIM(SUBSTR(i.plan_table_output, INSTR(i.plan_table_output, ':') + 1));

      BEGIN
        IF l_plan_hash_value IS NOT NULL THEN
          UPDATE sqlt$_dba_sql_plan_baselines
             SET plan_hash_value = TO_NUMBER(l_plan_hash_value)
           WHERE ROWID = i.row_id;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('cannot read plan_hash_value from "'||i.plan_table_output||'"');
      END;
    END LOOP;
    COMMIT;
  END get_phv_4_sql_plan_baselines;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_sqlobj$data
   *
   * ------------------------- */
  PROCEDURE collect_sqlobj$data (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_sqlobj$data');

    get_list_of_columns (
      p_source_table      => 'sqlobj$data',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_sqlobj$data',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_sqlobj$data (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_sql_statement x, sys.sqlobj$data t '||
    'WHERE x.statement_id = :statement_id AND t.signature IN (x.signature_sta,  x.signature_sta_force_match, x.signature_sta_unstripped, x.signature_sta_fm_unstripped)';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_sqlobj$data WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_sqlobj$data;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_sqlobj$
   *
   * ------------------------- */
  PROCEDURE collect_sqlobj$ (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_sqlobj$');

    get_list_of_columns (
      p_source_table      => 'sqlobj$',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_sqlobj$',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_sqlobj$ (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_sql_statement x, sys.sqlobj$ t '||
    'WHERE x.statement_id = :statement_id AND t.signature IN (x.signature_sta,  x.signature_sta_force_match, x.signature_sta_unstripped, x.signature_sta_fm_unstripped)';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_sqlobj$ WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_sqlobj$;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_sqlprof$attr
   *
   * ------------------------- */
  PROCEDURE collect_sqlprof$attr (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_sqlprof$attr');

    get_list_of_columns (
      p_source_table      => 'sqlprof$attr',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_sqlprof$attr',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_sqlprof$attr (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_sql_statement x, sys.sqlprof$attr t '||
    'WHERE x.statement_id = :statement_id AND t.signature IN (x.signature_sta,  x.signature_sta_force_match, x.signature_sta_unstripped, x.signature_sta_fm_unstripped)';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_sqlprof$attr WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_sqlprof$attr;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_sqlprof$
   *
   * ------------------------- */
  PROCEDURE collect_sqlprof$ (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_sqlprof$');

    get_list_of_columns (
      p_source_table      => 'sqlprof$',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_sqlprof$',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO sqlt$_sqlprof$ (statement_id, statid'||
    l_insert_list||') SELECT :statement_id, :statid'||
    l_select_list||' FROM sqlt$_sql_statement x, sys.sqlprof$ t '||
    'WHERE x.statement_id = :statement_id AND t.signature IN (x.signature_sta,  x.signature_sta_force_match, x.signature_sta_unstripped, x.signature_sta_fm_unstripped)';
    write_log(l_sql, 'S');

    BEGIN
      EXECUTE IMMEDIATE l_sql USING
      IN p_statement_id, IN p_statid,
      IN p_statement_id;
    EXCEPTION
      WHEN OTHERS THEN
        write_error(SQLERRM);
        write_error(l_sql);
        RETURN;
    END;

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_sqlprof$ WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_sqlprof$;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_perf_stats_pre
   *
   * called by: sqlt$a.event_10046_10053_on
   * 
   * 19332407  Removed gv_$cell_state
   *           Removed (needed only for collect_gv$segment_statistics)  s_rdbms_version:= sqlt$a.get_rdbms_version; 
   * ------------------------- */
  PROCEDURE collect_perf_stats_pre
  IS
  BEGIN
    write_log('=> collect_perf_stats_pre');

    s_collect_perf_stats := sqlt$a.get_param('collect_perf_stats');
     /* 19332407 Added s_collect_exadata_stats */
    s_collect_exadata_stats:=(case when sqlt$a.get_rdbms_release >= 11 then sqlt$a.get_param('collect_exadata_stats') else 'N' end);

    IF s_collect_perf_stats = 'Y' THEN

	get_list_of_columns (
        p_source_table      => 'gv_$segment_statistics',
        p_source_alias      => 't',
        p_destination_table => 'sqlt$_gv$segment_statistics',
        x_insert_list       => s_insert_list_segstat,
        x_select_list       => s_select_list_segstat );

      get_list_of_columns (
        p_source_table      => 'gv_$session_event',
        p_destination_table => 'sqlt$_gv$session_event',
        x_insert_list       => s_insert_list_sesevent,
        x_select_list       => s_select_list_sesevent );

      get_list_of_columns (
        p_source_table      => 'gv_$sesstat',
        p_destination_table => 'sqlt$_gv$sesstat',
        x_insert_list       => s_insert_list_sesstat,
        x_select_list       => s_select_list_sesstat );

      get_list_of_columns (
        p_source_table      => 'gv_$statname',
        p_destination_table => 'sqlt$_gv$statname',
        x_insert_list       => s_insert_list_statname,
        x_select_list       => s_select_list_statname );

      get_list_of_columns (
        p_source_table      => 'gv_$pq_slave',
        p_destination_table => 'sqlt$_gv$pq_slave',
        x_insert_list       => s_insert_list_pq_slave,
        x_select_list       => s_select_list_pq_slave );

      get_list_of_columns (
        p_source_table      => 'gv_$pq_sysstat',
        p_destination_table => 'sqlt$_gv$pq_sysstat',
        x_insert_list       => s_insert_list_pq_sysstat,
        x_select_list       => s_select_list_pq_sysstat );

      get_list_of_columns (
        p_source_table      => 'gv_$px_process_sysstat',
        p_destination_table => 'sqlt$_gv$px_process_sysstat',
        x_insert_list       => s_insert_list_px_sysstat,
        x_select_list       => s_select_list_px_sysstat );

      get_list_of_columns (
        p_source_table      => 'gv_$px_process',
        p_destination_table => 'sqlt$_gv$px_process',
        x_insert_list       => s_insert_list_px_process,
        x_select_list       => s_select_list_px_process );

      get_list_of_columns (
        p_source_table      => 'gv_$px_session',
        p_destination_table => 'sqlt$_gv$px_session',
        x_insert_list       => s_insert_list_px_session,
        x_select_list       => s_select_list_px_session );

      get_list_of_columns (
        p_source_table      => 'gv_$pq_sesstat',
        p_destination_table => 'sqlt$_gv$pq_sesstat',
        x_insert_list       => s_insert_list_pq_sesstat,
        x_select_list       => s_select_list_pq_sesstat );

      get_list_of_columns (
        p_source_table      => 'gv_$px_sesstat',
        p_destination_table => 'sqlt$_gv$px_sesstat',
        x_insert_list       => s_insert_list_px_sesstat,
        x_select_list       => s_select_list_px_sesstat );

      get_list_of_columns (
        p_source_table      => 'gv_$px_instance_group',
        p_destination_table => 'sqlt$_gv$px_instance_group',
        x_insert_list       => s_insert_list_px_group,
        x_select_list       => s_select_list_px_group );

      get_list_of_columns (
        p_source_table      => 'gv_$pq_tqstat',
        p_destination_table => 'sqlt$_gv$pq_tqstat',
        x_insert_list       => s_insert_list_pq_tqstat,
        x_select_list       => s_select_list_pq_tqstat );

      list_of_objects;
    ELSE
      write_log('skip collect_perf_stats as per parameter');
    END IF;
  END collect_perf_stats_pre;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_perf_stats_begin
   *
   * called by: sqlt$a.event_10046_10053_on
   *
   * ------------------------- */
  PROCEDURE collect_perf_stats_begin (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sid          IN NUMBER )
  IS
    l_instance_number  NUMBER;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
  
  	/* 19332407  Repositioned collect_gv$cell_state */
	if s_collect_exadata_stats='Y' then 
     collect_gv$cell_state(p_statement_id, p_statid, 'B');
	end if;
  
    -- pq and px
    collect_gv$pq_slave(p_statement_id, p_statid, 'B', s_insert_list_pq_slave, s_select_list_pq_slave);
    collect_gv$pq_sysstat(p_statement_id, p_statid, 'B', s_insert_list_pq_sysstat, s_select_list_pq_sysstat);
    collect_gv$px_sysstat(p_statement_id, p_statid, 'B', s_insert_list_px_sysstat, s_select_list_px_sysstat);
    collect_gv$px_process(p_statement_id, p_statid, 'B', s_insert_list_px_process, s_select_list_px_process);
    collect_gv$px_session(p_statement_id, p_statid, 'B', s_insert_list_px_session, s_select_list_px_session);
    collect_gv$pq_sesstat(p_statement_id, p_statid, 'B', s_insert_list_pq_sesstat, s_select_list_pq_sesstat);
    collect_gv$px_sesstat(p_statement_id, p_statid, p_sid, 'B', s_insert_list_px_sesstat, s_select_list_px_sesstat);
    collect_gv$px_group(p_statement_id, p_statid, 'B', s_insert_list_px_group, s_select_list_px_group);

    IF s_collect_perf_stats = 'Y' THEN
      
      l_instance_number := sqlt$a.get_instance_number;
      
      -- sql performance
	  /* 19332407  Repositioned collect_gv$cell_state */
      collect_gv$segment_statistics(p_statement_id, p_statid, 'B', s_insert_list_segstat, s_select_list_segstat);
      collect_gv$session_event(p_statement_id, p_statid, p_sid, 'B', s_insert_list_sesevent, s_select_list_sesevent);
      collect_gv$sesstat(p_statement_id, p_statid, l_instance_number, p_sid, NULL, 'B', NULL, s_insert_list_sesstat, s_select_list_sesstat);
    END IF;

    COMMIT; -- AUTONOMOUS_TRANSACTION
  END collect_perf_stats_begin;  

  /*************************************************************************************/
  
  /* -------------------------
   *
   * public collect_sesstat_xtract
   *
   * called by: sqlt$i.xtract
   *
   * ------------------------- */
  PROCEDURE collect_sesstat_xtract (
    p_statement_id            IN NUMBER,
    p_begin_end_flag          IN VARCHAR2 )
  IS
    l_sql_id            VARCHAR2(13);
    l_statid            VARCHAR2(257);
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
  
     IF sqlt$a.get_param('c_sesstat_xtract') = 'N'  THEN
        write_log('skip gv$sesstat collection on XTRACT as per parameter "c_sesstat_xtract"');	    
     ELSE  
        l_sql_id := sqlt$a.get_sql_id(p_statement_id);
        l_statid := sqlt$a.get_statid(p_statement_id);
        -- prepare perf_stats collection
        collect_perf_stats_pre;
        
        -- collect session stats only if enabled by parameter
        IF s_collect_perf_stats = 'Y' THEN
          
          -- loop only for a fixed number of times
          FOR i IN 1..MAXSEQUENCE LOOP	    
            -- find all the sessions running our SQL ID
            FOR j IN (SELECT inst_id, sid, serial# FROM gv$session WHERE sql_id = l_sql_id) LOOP				
            -- for each session collect session stats  NEED TO ADD INST_ID here
              collect_gv$sesstat(p_statement_id, l_statid, j.inst_id, j.sid, j.serial#, p_begin_end_flag, i, s_insert_list_sesstat, s_select_list_sesstat); 		
            END LOOP;		
        
            -- sleep 1 second
            -- DBMS_LOCK.SLEEP(1);
        	
          END LOOP;
        END IF;
        
        IF s_collect_statname = 'N' THEN
          collect_gv$statname(p_statement_id, l_statid, s_insert_list_statname, s_select_list_statname);	
          s_collect_statname := 'Y';
        END IF;
		
     END IF;
     COMMIT; -- AUTONOMOUS_TRANSACTION
  END collect_sesstat_xtract;

  /*************************************************************************************/
  
  /* -------------------------
   *
   * public collect_cellstate_xtract
   *
   * called by: sqlt$i.xtract
   * 19332407  Remade
   * ------------------------- */
  PROCEDURE collect_cellstate_xtract (
    p_statement_id            IN NUMBER)
  IS
    l_statid            VARCHAR2(257);
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    if s_collect_exadata_stats='Y' then 
     l_statid := sqlt$a.get_statid(p_statement_id);
     collect_gv$cell_state(p_statement_id, l_statid, 'B');
    end if;
    COMMIT; -- AUTONOMOUS_TRANSACTION
  END collect_cellstate_xtract;

  /*************************************************************************************/  

  /* -------------------------
   *
   * public collect_perf_stats_end
   *
   * called by: sqlt$a.event_10046_10053_off
   *
   * ------------------------- */
  PROCEDURE collect_perf_stats_end (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_sid          IN NUMBER )
  IS
    l_instance_number NUMBER;
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    /* 19332407  Repositioned collect_gv$cell_state */
	if s_collect_exadata_stats='Y' then 
     collect_gv$cell_state(p_statement_id, p_statid, 'E');
	end if;
  
    IF s_collect_perf_stats = 'Y' THEN
	
      l_instance_number := sqlt$a.get_instance_number;
	
      -- sql performance
      collect_gv$sesstat(p_statement_id, p_statid, l_instance_number, p_sid, NULL, 'E', NULL, s_insert_list_sesstat, s_select_list_sesstat);
      collect_gv$session_event(p_statement_id, p_statid, p_sid, 'E', s_insert_list_sesevent, s_select_list_sesevent);
      collect_gv$segment_statistics(p_statement_id, p_statid, 'E', s_insert_list_segstat, s_select_list_segstat);
      /* 19332407  Repositioned collect_gv$cell_state */
      collect_gv$statname(p_statement_id, p_statid, s_insert_list_statname, s_select_list_statname);
    END IF;

    -- pq and px
    collect_gv$pq_slave(p_statement_id, p_statid, 'E', s_insert_list_pq_slave, s_select_list_pq_slave);
    collect_gv$pq_sysstat(p_statement_id, p_statid, 'E', s_insert_list_pq_sysstat, s_select_list_pq_sysstat);
    collect_gv$px_sysstat(p_statement_id, p_statid, 'E', s_insert_list_px_sysstat, s_select_list_px_sysstat);
    collect_gv$px_process(p_statement_id, p_statid, 'E', s_insert_list_px_process, s_select_list_px_process);
    collect_gv$px_session(p_statement_id, p_statid, 'E', s_insert_list_px_session, s_select_list_px_session);
    collect_gv$pq_sesstat(p_statement_id, p_statid, 'E', s_insert_list_pq_sesstat, s_select_list_pq_sesstat);
    collect_gv$px_sesstat(p_statement_id, p_statid, p_sid, 'E', s_insert_list_px_sesstat, s_select_list_px_sesstat);
    collect_gv$px_group(p_statement_id, p_statid, 'E', s_insert_list_px_group, s_select_list_px_group);

    COMMIT; -- AUTONOMOUS_TRANSACTION
  END collect_perf_stats_end;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_px_perf_stats
   *
   * called by: sqlt$a.common_calls
   *
   * ------------------------- */
  PROCEDURE collect_px_perf_stats (p_statement_id IN NUMBER)
  IS
    l_statid VARCHAR2(32767);
    sql_rec sqlt$_sql_statement%ROWTYPE;
  BEGIN
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sql_rec.method IN ('XPLAIN', 'XTRACT', 'XTRSBY') THEN
      l_statid := sqlt$a.get_statid(p_statement_id);
      collect_perf_stats_pre;
      collect_gv$pq_slave(p_statement_id, l_statid, 'E', s_insert_list_pq_slave, s_select_list_pq_slave);
      collect_gv$pq_sysstat(p_statement_id, l_statid, 'E', s_insert_list_pq_sysstat, s_select_list_pq_sysstat);
      collect_gv$px_sysstat(p_statement_id, l_statid, 'E', s_insert_list_px_sysstat, s_select_list_px_sysstat);
      collect_gv$px_process(p_statement_id, l_statid, 'E', s_insert_list_px_process, s_select_list_px_process);
      collect_gv$px_session(p_statement_id, l_statid, 'E', s_insert_list_px_session, s_select_list_px_session);
      collect_gv$px_group(p_statement_id, l_statid, 'E', s_insert_list_px_group, s_select_list_px_group);
      collect_perf_stats_post(p_statement_id, l_statid);
      COMMIT;
    END IF;
  END collect_px_perf_stats;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_perf_stats_post
   *
   * called by: sqlt$a.event_10046_10053_off
   *
   * ------------------------- */
  PROCEDURE collect_perf_stats_post (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_count NUMBER;
  BEGIN
    write_log('collect_gv$sesstat');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sesstat WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$session_event');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$session_event WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$segment_statistics');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$segment_statistics WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$statname');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$statname WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$pq_slave');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$pq_slave WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$pq_sysstat');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$pq_sysstat WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$px_process_sysstat');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$px_process_sysstat WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$px_process');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$px_process WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$px_session');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$px_session WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$pq_sesstat');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$pq_sesstat WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$px_sesstat');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$px_sesstat WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$px_instance_group');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$px_instance_group WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('collect_gv$pq_tqstat');
    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$pq_tqstat WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');

    write_log('<= collect_perf_stats_post');
  END collect_perf_stats_post;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dbms_stats_glob_prefs
   *
   * ------------------------- */
  PROCEDURE collect_dbms_stats_glob_prefs (p_statement_id IN NUMBER)
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_function VARCHAR2(32);

    /* -------------------------
     *
     * private collect_dbms_stats_glob_prefs.get_param
     *
     * ------------------------- */
    FUNCTION get_param (p_name IN VARCHAR2)
    RETURN VARCHAR2
    IS
      l_value VARCHAR2(32767);
    BEGIN
      EXECUTE IMMEDIATE 'SELECT SYS.DBMS_STATS.'||l_function||sqlt$a.s_db_link||'(:pname) FROM DUAL' INTO l_value USING IN p_name;
      RETURN SUBSTR(l_value, 1, 256);
    EXCEPTION
      WHEN OTHERS THEN
        write_log('cannot get param "'||p_name||'": '||SQLERRM);
        RETURN NULL;
    END get_param;

    /* -------------------------
     *
     * private collect_dbms_stats_glob_prefs.get_param2
     *
     * ------------------------- */
    FUNCTION get_param2 (p_name IN VARCHAR2)
    RETURN VARCHAR2
    IS
      l_value VARCHAR2(32767);
    BEGIN
      EXECUTE IMMEDIATE 'SELECT spare4 FROM sys.optstat_hist_control$ WHERE sname = :pname' INTO l_value USING IN p_name;
      RETURN SUBSTR(l_value, 1, 256);
    EXCEPTION
      WHEN OTHERS THEN
        write_log('cannot get param2 "'||p_name||'": '||SQLERRM);
        RETURN NULL;
    END get_param2;

  BEGIN
    write_log('-> collect_dbms_stats_glob_prefs');

    IF sqlt$a.get_rdbms_release < 11 THEN
      l_function := 'GET_PARAM';
    ELSE
      l_function := 'GET_PREFS';
    END IF;

    sql_rec.param_autostats_target := get_param('AUTOSTATS_TARGET');
    sql_rec.param_estimate_percent := get_param('ESTIMATE_PERCENT');
    sql_rec.param_degree           := get_param('DEGREE');
    sql_rec.param_cascade          := get_param('CASCADE');
    sql_rec.param_no_invalidate    := get_param('NO_INVALIDATE');
    sql_rec.param_method_opt       := get_param('METHOD_OPT');
    sql_rec.param_granularity      := get_param('GRANULARITY');

    sql_rec.param_stats_retention  := get_param2('STATS_RETENTION');

    IF sqlt$a.get_rdbms_release >= 11 THEN
      sql_rec.param_publish        := get_param('PUBLISH');
      sql_rec.param_incremental    := get_param('INCREMENTAL');
      sql_rec.param_stale_percent  := get_param('STALE_PERCENT');

      sql_rec.param_approximate_ndv       := get_param2('APPROXIMATE_NDV');
      sql_rec.param_incr_internal_control := get_param2('INCREMENTAL_INTERNAL_CONTROL');
      sql_rec.param_concurrent            := get_param2('CONCURRENT');
    END IF;

    UPDATE sqlt$_sql_statement
       SET param_autostats_target = sql_rec.param_autostats_target,
           param_publish = sql_rec.param_publish,
           param_incremental = sql_rec.param_incremental,
           param_stale_percent = sql_rec.param_stale_percent,
           param_estimate_percent = sql_rec.param_estimate_percent,
           param_degree = sql_rec.param_degree,
           param_cascade = sql_rec.param_cascade,
           param_no_invalidate = sql_rec.param_no_invalidate,
           param_method_opt = sql_rec.param_method_opt,
           param_granularity = sql_rec.param_granularity
     WHERE statement_id = p_statement_id;
    COMMIT;
    write_log('<- collect_dbms_stats_glob_prefs');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('collect_dbms_stats_glob_prefs: '||SQLERRM);
  END collect_dbms_stats_glob_prefs;

  /*************************************************************************************/

  /* -------------------------
   *
   * public one_plan_per_hv_mem
   *
   * ------------------------- */
  PROCEDURE one_plan_per_hv_mem (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
  BEGIN
    write_log('one_plan_per_hv_mem');

    -- distinct phv that still had plan in memory and were executed at least once
    FOR i IN (SELECT DISTINCT s.plan_hash_value
                FROM sqlt$_gv$sql s
               WHERE s.statement_id = p_statement_id
                 AND s.loaded_versions > 0
                 AND s.executions >= 1
                 AND EXISTS (
              SELECT NULL
                FROM sqlt$_gv$sql_plan p
               WHERE s.statement_id = p.statement_id
                 AND s.inst_id = p.inst_id
                 AND s.child_number = p.child_number
                 AND s.child_address = p.child_address
                 AND s.plan_hash_value = p.plan_hash_value))
    LOOP
      -- for each phv, find the one child with better predicates
      -- (some children could have missing predicates due to bug 6356566)
      -- and if anyone has predicates select then the most recent
      FOR j IN (SELECT s.inst_id,
                       s.child_number,
                       s.child_address
                  FROM sqlt$_gv$sql_plan p,
                       sqlt$_gv$sql s
                 WHERE p.statement_id = p_statement_id
                   AND p.plan_hash_value = i.plan_hash_value
                   AND p.statement_id = s.statement_id
                   AND p.inst_id = s.inst_id
                   AND p.child_number = s.child_number
                   AND p.child_address = s.child_address
                   AND p.plan_hash_value = s.plan_hash_value
                   AND s.loaded_versions > 0
                   AND s.executions >= 1
                 GROUP BY
                       s.inst_id,
                       s.child_number,
                       s.child_address,
                       s.last_active_time
                 ORDER BY
                       SUM(NVL(LENGTH(p.access_predicates), 0)) +
                       SUM(NVL(LENGTH(p.filter_predicates), 0)) DESC,
                       s.last_active_time DESC)
      LOOP
        l_count := l_count + 1;

        -- only one row per phv is flagged
        UPDATE sqlt$_gv$sql
           SET in_plan_extension = 'Y'
         WHERE statement_id = p_statement_id
           AND plan_hash_value = i.plan_hash_value
           AND inst_id = j.inst_id
           AND child_number = j.child_number
           AND child_address = j.child_address;

        -- this plan is the one that will be included in report (predicates and common columns)
        -- only one plan per phv is flagged
        UPDATE sqlt$_gv$sql_plan
           SET in_plan_extension = 'Y'
         WHERE statement_id = p_statement_id
           AND plan_hash_value = i.plan_hash_value
           AND inst_id = j.inst_id
           AND child_number = j.child_number
           AND child_address = j.child_address;

        -- one or many rows can be flagged since this is to create links only
        UPDATE sqlt$_gv$sqlarea_plan_hash
           SET in_plan_extension = 'Y'
         WHERE statement_id = p_statement_id
           AND plan_hash_value = i.plan_hash_value;

        EXIT; -- 1st only
      END LOOP;
    END LOOP;

    UPDATE sqlt$_gv$sql
       SET in_plan_extension = 'N'
     WHERE statement_id = p_statement_id
       AND in_plan_extension IS NULL;

    UPDATE sqlt$_gv$sql_plan
       SET in_plan_extension = 'N'
     WHERE statement_id = p_statement_id
       AND in_plan_extension IS NULL;

    UPDATE sqlt$_gv$sqlarea_plan_hash
       SET in_plan_extension = 'N'
     WHERE statement_id = p_statement_id
       AND in_plan_extension IS NULL;

    -- put predicates in those plans which have none
    FOR i IN (SELECT plan_hash_value,
                     id,
                     access_predicates,
                     filter_predicates
                FROM sqlt$_gv$sql_plan
               WHERE statement_id = p_statement_id
                 AND in_plan_extension = 'Y'
                 AND (access_predicates IS NOT NULL OR filter_predicates IS NOT NULL))
    LOOP
      UPDATE sqlt$_gv$sql_plan
         SET access_predicates = i.access_predicates,
             filter_predicates = i.filter_predicates
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND id = i.id
         AND in_plan_extension = 'N'
         AND access_predicates IS NULL
         AND filter_predicates IS NULL;
    END LOOP;

    COMMIT;
    write_log(l_count||' selected plans on sqlt$_gv$sql');
  END one_plan_per_hv_mem;

  /*************************************************************************************/

  /* -------------------------
   *
   * private one_plan_per_hv_sta
   *
   * ------------------------- */
  PROCEDURE one_plan_per_hv_sta (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
  BEGIN
    write_log('one_plan_per_hv_sta');

    -- sta from mem and awr can recommend same plans
    -- chose min which is the one from mem
    FOR i IN (SELECT plan_hash_value, MIN(plan_id) plan_id
                FROM sqlt$_dba_sqltune_plans
               WHERE statement_id = p_statement_id
                 AND id = 0
               GROUP BY
                     plan_hash_value)
    LOOP
      l_count := l_count + 1;

      UPDATE sqlt$_dba_sqltune_plans
         SET in_plan_extension = 'Y'
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND plan_id = i.plan_id;
    END LOOP;

    UPDATE sqlt$_dba_sqltune_plans
       SET in_plan_extension = 'N'
     WHERE statement_id = p_statement_id
       AND in_plan_extension IS NULL;

    COMMIT;
    write_log(l_count||' selected plans on sqlt$_dba_sqltune_plans');
  END one_plan_per_hv_sta;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_plan_extensions
   *
   * ------------------------- */
  PROCEDURE collect_plan_extensions (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_sql             VARCHAR2(32767);
    l_insert_list     VARCHAR2(32767);
    l_select_list     VARCHAR2(32767);
    l_count           NUMBER;
    l_plan_hash_value NUMBER;

  BEGIN
    write_log('collect_plan_extensions');

    -- sqlt$_gv$sql_plan
    BEGIN
    get_list_of_columns (
      p_source_owner      => TOOL_REPOSITORY_SCHEMA,
      p_source_table      => 'sqlt$_gv$sql_plan',
      p_destination_table => 'sqlt$_plan_extension',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_plan_extension (statement_id, statid, source'||
      l_insert_list||') SELECT statement_id, statid, ''GV$SQL_PLAN'''||
      l_select_list||' FROM sqlt$_gv$sql_plan '||
      'WHERE statement_id = :statement_id AND in_plan_extension = ''Y''';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING IN p_statement_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;

      -- fix timestamp to oldest plan, not to one selected by one_plan_per_hv_mem
      FOR i IN (SELECT plan_hash_value, MIN(timestamp) timestamp
                  FROM sqlt$_gv$sql_plan
                 WHERE statement_id = p_statement_id
                 GROUP BY
                       plan_hash_value)
      LOOP
        UPDATE sqlt$_plan_extension
           SET timestamp = i.timestamp
         WHERE statement_id = p_statement_id
           AND plan_hash_value = i.plan_hash_value
           AND source = 'GV$SQL_PLAN';
      END LOOP;
    END;

    -- sqlt$_dba_hist_sql_plan
    -- overlap needed even if plan from awr does not have predicates
    -- we still need other_xml to get peeked binds
    BEGIN
    get_list_of_columns (
      p_source_owner      => TOOL_REPOSITORY_SCHEMA,
      p_source_table      => 'sqlt$_dba_hist_sql_plan',
      p_destination_table => 'sqlt$_plan_extension',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_plan_extension (statement_id, statid, source'||
      l_insert_list||') SELECT statement_id, statid, ''DBA_HIST_SQL_PLAN'''||
      l_select_list||' FROM sqlt$_dba_hist_sql_plan h '||
      'WHERE h.statement_id = :statement_id';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING IN p_statement_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END;

    -- sqlt$_sql_plan_table
    -- overlap needed since plan from memory may not have predicates (bug 6356566)
    -- we still need other_xml to get peeked binds
    BEGIN
      SELECT xplain_plan_hash_value
        INTO l_plan_hash_value
        FROM sqlt$_sql_statement
       WHERE statement_id = p_statement_id;

    get_list_of_columns (
      p_source_owner      => TOOL_REPOSITORY_SCHEMA,
      p_source_table      => 'sqlt$_sql_plan_table',
      p_destination_table => 'sqlt$_plan_extension',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_plan_extension (statement_id, statid, source, plan_hash_value'||
      l_insert_list||') SELECT statement_id, :statid, ''PLAN_TABLE'', :plan_hash_value'||
      l_select_list||' FROM sqlt$_sql_plan_table '||
      'WHERE statement_id = :statement_id';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING IN p_statid, IN l_plan_hash_value, IN sqlt$a.get_statement_id_c(p_statement_id);
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END;

    -- sqlt$_dba_sqltune_plans
    -- overlap needed since plan from memory may not have predicates (bug 6356566)
    -- we still need other_xml to get peeked binds
    BEGIN
    get_list_of_columns (
      p_source_owner      => TOOL_REPOSITORY_SCHEMA,
      p_source_table      => 'sqlt$_dba_sqltune_plans',
      p_destination_table => 'sqlt$_plan_extension',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

      l_sql :=
      'INSERT INTO sqlt$_plan_extension (statement_id, statid, source'||
      l_insert_list||') SELECT statement_id, statid, ''DBA_SQLTUNE_PLANS'''||
      l_select_list||' FROM sqlt$_dba_sqltune_plans '||
      'WHERE statement_id = :statement_id AND in_plan_extension = ''Y''';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql USING IN p_statement_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          RETURN;
      END;
    END;

    UPDATE sqlt$_plan_extension
       SET plan_id = -1
     WHERE statement_id = p_statement_id
       AND plan_id IS NULL;

    UPDATE sqlt$_plan_extension
       SET task_id = -1
     WHERE statement_id = p_statement_id
       AND task_id IS NULL;

    UPDATE sqlt$_plan_extension
       SET inst_id = -1
     WHERE statement_id = p_statement_id
       AND inst_id IS NULL;

    UPDATE sqlt$_plan_extension
       SET child_number = -1,
           child_address = '-666'
     WHERE statement_id = p_statement_id
       AND child_number IS NULL;

    -- fix issue where timestamp contains what is seems 29-NOV-02 date
    UPDATE sqlt$_plan_extension
       SET timestamp = SYSDATE
     WHERE statement_id = p_statement_id
       AND source = 'DBA_SQLTUNE_PLANS';

    COMMIT;
    SELECT COUNT(*) INTO l_count FROM sqlt$_plan_extension WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
  END collect_plan_extensions;

  /*************************************************************************************/

  /* -------------------------
   *
   * public diagnostics_data_collection_1
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE diagnostics_data_collection_1 (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;

  BEGIN
    write_log('=> diagnostics_data_collection_1');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sql_rec.in_memory = 'Y' THEN
      write_log('-> collection from memory');
      write_log('sql_id = "'||sql_rec.sql_id||'", hash_value = "'||sql_rec.hash_value||'"');

      -- expedite the collection of volatile objects
      collect_gv$sql_shared_cursor(p_statement_id, sql_rec.statid, sql_rec.sql_id); -- no hash_value column
      IF sqlt$a.get_rdbms_release >= 11 THEN
        collect_gv$sql_cs_histogram(p_statement_id, sql_rec.statid, sql_rec.sql_id); -- no hash_value column
        collect_gv$sql_cs_selectivity(p_statement_id, sql_rec.statid, sql_rec.sql_id); -- no hash_value column
        collect_gv$sql_cs_statistics(p_statement_id, sql_rec.statid, sql_rec.sql_id); -- no hash_value column
      END IF;
      collect_gv$sql_bind_capture(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value);
      collect_gv$sql_optimizer_env(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value);
      collect_gv$sql_workarea(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value);
      collect_gv$sql_plan_statistics(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value);
      collect_gv$sql_plan(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value);
      collect_gv$sql(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value);
      collect_gv$sqlarea_plan_hash(p_statement_id, sql_rec.statid, sql_rec.sql_id); -- hash_value is not reliable here
      collect_gv$sqlarea(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value);
      IF sql_rec.method = 'XTRACT' AND sqlt$a.get_rdbms_version >= '11.2' THEN
        sqlt$a.generate_10053_xtract(p_statement_id, p_out_file_identifier);
      END IF;
      -- not in main report (yet)
      BEGIN
        IF sqlt$a.get_rdbms_version >= '11.1.0.7' THEN
          collect_gv$sqlstats_plan_hash(p_statement_id, sql_rec.statid, sql_rec.sql_id);
        END IF;
        collect_gv$sqlstats(p_statement_id, sql_rec.statid, sql_rec.sql_id);
        -- collect_gv$sqltext(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value); moved to capture_statement
      END;
    ELSE
      write_log('skip collection from memory since sql was not found in mem');
    END IF;

    -- object dependencies
    --IF sql_rec.in_memory = 'Y' OR sql_rec.method = 'XPLAIN' THEN
      collect_gv$object_dependency(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value);
    --END IF;

    IF sql_rec.in_memory = 'Y' THEN
      collect_gv$vpd_policy(p_statement_id, sql_rec.statid, sql_rec.sql_id);
      collect_gv$active_session_hist(p_statement_id, sql_rec.statid, sql_rec.sql_id);
      collect_dbms_xplan_cursor_last(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value); -- depends on collect_gv$sql_workarea, collect_gv$sql_plan_statistics and collect_gv$sql_plan
      collect_dbms_xplan_cursor_all(p_statement_id, sql_rec.statid, sql_rec.sql_id, sql_rec.hash_value); -- depends on collect_gv$sql_workarea, collect_gv$sql_plan_statistics and collect_gv$sql_plan

      -- sql monitor
      IF sqlt$a.get_rdbms_release >= 11 THEN
        collect_gv$sql_monitor(p_statement_id, sql_rec.statid, sql_rec.sql_id);
        collect_gv$sql_plan_monitor(p_statement_id, sql_rec.statid, sql_rec.sql_id);
      END IF;

      -- if it was executed by XTRACT or XECUTE, or if it was by XPLAIN and the sqltext was found in memory or AWR
      IF sql_rec.method IN ('XTRACT', 'XECUTE') OR (sql_rec.method = 'XPLAIN' AND sql_rec.sql_id_found_using_sqltext = 'Y') THEN
        create_tuning_task_memory(p_statement_id, sql_rec.sql_id, sql_rec.hash_value);
      END IF;

      -- use stripped sql_text and binds from XECUTE to call STA
      IF sql_rec.method = 'XECUTE' THEN
        create_tuning_task_text(p_statement_id, sql_rec.sql_id, sql_rec.hash_value);
      END IF;

      -- sql tuning sets
      -- if it was executed by XTRACT or XECUTE, or if it was by XPLAIN and the sqltext was found in memory or AWR
      IF sql_rec.method IN ('XTRACT', 'XECUTE') OR (sql_rec.method = 'XPLAIN' AND sql_rec.sql_id_found_using_sqltext = 'Y') THEN
        collect_tuning_sets_mem(p_statement_id, sql_rec.statid, sql_rec.sql_id);
      END IF;

      write_log('<- collection from memory');
    END IF;

    COMMIT;
    write_log('<= diagnostics_data_collection_1');
  END diagnostics_data_collection_1;

  /*************************************************************************************/

  /* -------------------------
   *
   * public diagnostics_data_collection_2
   *
   * called by: sqlt$i.sqlt_common and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE diagnostics_data_collection_2 (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_fixed NUMBER;
    l_part_tbl NUMBER;
    l_part_idx NUMBER;
    l_subpart_tbl NUMBER;
    l_subpart_idx NUMBER;
    l_gran_seg VARCHAR2(257);
    l_gran_tbl VARCHAR2(257);
    l_gran_idx VARCHAR2(257);
    l_gran_col VARCHAR2(257);
    l_gran_hgr VARCHAR2(257);

  BEGIN
    write_log('=> diagnostics_data_collection_2');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    BEGIN
      write_log('sql_id = "'||sql_rec.sql_id||'"');
      write_log('in_awr = "'||sql_rec.in_awr||'"');
      write_log('s_db_link = "'||sqlt$a.s_db_link||'"');

      IF sql_rec.in_awr = 'Y' AND sqlt$a.s_db_link IS NULL THEN
        write_log('-> collection from awr');

        -- non-volatile objects
        collect_dba_hist_active_sess_h(p_statement_id, sql_rec.statid, sql_rec.sql_id);
        collect_dba_hist_sqltext(p_statement_id, sql_rec.statid, sql_rec.sql_id);
        collect_dba_hist_sqlstat(p_statement_id, sql_rec.statid, sql_rec.sql_id);
        collect_dba_hist_sql_plan(p_statement_id, sql_rec.statid, sql_rec.sql_id);
        collect_dba_hist_sqlbind(p_statement_id, sql_rec.statid, sql_rec.sql_id);
        collect_dbms_xplan_awr(p_statement_id, sql_rec.statid, sql_rec.sql_id);

        write_log('<- collection from awr');
      END IF;

      collect_dba_hist_snapshot(p_statement_id, sql_rec.statid); -- no dependencies on sql_id or other awr objects
      collect_dba_hist_parameter(p_statement_id, sql_rec.statid); -- no dependencies on sql_id or other awr objects
      collect_dba_hist_parameter_m(p_statement_id, sql_rec.statid); -- depends on collect_dba_hist_parameter

      IF sql_rec.in_awr = 'Y' AND sqlt$a.s_db_link IS NULL THEN
        write_log('-> tuning_task_awr and tuning_sets_awr');

        -- if it was executed by XTRACT or XECUTE, or if it was by XPLAIN and the sqltext was found in memory or AWR
        IF sql_rec.method IN ('XTRACT', 'XECUTE') OR (sql_rec.method = 'XPLAIN' AND sql_rec.sql_id_found_using_sqltext = 'Y') THEN
          create_tuning_task_awr(p_statement_id, sql_rec.sql_id);
        END IF;

        -- sql tuning sets
        -- if it was executed by XTRACT or XECUTE, or if it was by XPLAIN and the sqltext was found in memory or AWR
        IF sql_rec.method IN ('XTRACT', 'XECUTE') OR (sql_rec.method = 'XPLAIN' AND sql_rec.sql_id_found_using_sqltext = 'Y') THEN
          collect_tuning_sets_awr(p_statement_id, sql_rec.statid, sql_rec.sql_id); -- depends on collect_dba_hist_sqlstat and collect_dba_hist_snapshot
        END IF;

        write_log('<- tuning_task_awr and tuning_sets_awr');
      END IF;
    END;

    -- expansion (non-volatile objects)
    BEGIN
      write_log('-> expanded collection');
      collect_gv$parameter2(p_statement_id, sql_rec.statid);
      collect_gv$nls_parameters(p_statement_id, sql_rec.statid);
      collect_gv$system_parameter(p_statement_id, sql_rec.statid);
      collect_nls_database_params(p_statement_id, sql_rec.statid);
      -- collect_gv$parameter_cbo(p_statement_id, sql_rec.statid); moved to sqlt$i.common_calls
      collect_v$session_fix_control(p_statement_id, sql_rec.statid);

      collect_dba_dependencies(p_statement_id, sql_rec.statid); -- depends on collect_dba_hist_sql_plan
      list_of_objects(p_statement_id);

      SELECT COUNT(*)
        INTO l_fixed
        FROM sqlg$_pivot
       WHERE object_type = 'FIXED TABLE'
         AND ROWNUM = 1;

      SELECT COUNT(*)
        INTO l_part_tbl
        FROM sqlg$_pivot
       WHERE object_type = 'TABLE'
         AND partitioned = 'YES'
         AND ROWNUM = 1;

      SELECT COUNT(*)
        INTO l_part_idx
        FROM sqlg$_pivot
       WHERE object_type = 'INDEX'
         AND partitioned = 'YES'
         AND ROWNUM = 1;

      IF l_part_tbl > 0 THEN
        l_gran_tbl := sqlt$a.get_param('c_gran_segm');
        l_gran_col := sqlt$a.get_param('c_gran_cols');
        l_gran_hgr := sqlt$a.get_param('c_gran_hgrm');
      ELSE
        l_gran_tbl := 'GLOBAL';
        l_gran_col := 'GLOBAL';
        l_gran_hgr := 'GLOBAL';
      END IF;

      IF l_part_idx > 0 THEN
        l_gran_idx := sqlt$a.get_param('c_gran_segm');
      ELSE
        l_gran_idx := 'GLOBAL';
      END IF;

      IF l_gran_tbl IN ('PARTITION', 'SUBPARTITION') OR
         l_gran_idx IN ('PARTITION', 'SUBPARTITION')
      THEN
        collect_dba_part_key_columns(p_statement_id, sql_rec.statid);
      END IF;

      collect_schema_object_stats(p_statement_id, sql_rec.statid, p_group_id);
      collect_dba_tables(p_statement_id, sql_rec.statid);
      collect_dba_object_tables(p_statement_id, sql_rec.statid);
      collect_dba_nested_tables(p_statement_id, sql_rec.statid);
      collect_dba_tab_statistics(p_statement_id, sql_rec.statid);
      IF l_fixed > 0 THEN
        collect_dba_tab_stats_fixed(p_statement_id, sql_rec.statid);
        collect_dba_tab_col_stat_fixed(p_statement_id, sql_rec.statid);
      END IF;
      IF sqlt$a.get_rdbms_release >= 11 THEN
        collect_dba_stat_extensions(p_statement_id, sql_rec.statid);
      END IF;
      collect_dba_tab_modifications(p_statement_id, sql_rec.statid);
      collect_dba_tab_cols(p_statement_id, sql_rec.statid);
      collect_dba_nested_table_cols(p_statement_id, sql_rec.statid);
      collect_dba_indexes(p_statement_id, sql_rec.statid);
      collect_dba_ind_statistics(p_statement_id, sql_rec.statid);
      collect_dba_ind_columns(p_statement_id, sql_rec.statid);
      collect_dba_ind_expressions(p_statement_id, sql_rec.statid);
      collect_dba_tab_histograms(p_statement_id, sql_rec.statid);
      collect_dba_constraints(p_statement_id, sql_rec.statid);

      IF l_gran_tbl IN ('PARTITION', 'SUBPARTITION') THEN
        collect_dba_tab_partitions(p_statement_id, sql_rec.statid);
        IF l_gran_col IN ('PARTITION', 'SUBPARTITION') THEN
          collect_dba_part_col_stats(p_statement_id, sql_rec.statid);
          IF l_gran_hgr IN ('PARTITION', 'SUBPARTITION') THEN
            collect_dba_part_histograms(p_statement_id, sql_rec.statid);
          END IF;
        END IF;
      END IF;

      IF l_gran_idx IN ('PARTITION', 'SUBPARTITION') THEN
        collect_dba_ind_partitions(p_statement_id, sql_rec.statid);
      END IF;

      IF l_part_tbl > 0 AND l_gran_tbl = 'SUBPARTITION' THEN
        SELECT COUNT(*)
          INTO l_subpart_tbl
          FROM sqlt$_dba_tab_partitions
         WHERE statement_id = p_statement_id
           AND composite = 'YES'
           AND ROWNUM = 1;
      END IF;

      IF l_part_idx > 0 AND l_gran_idx = 'SUBPARTITION' THEN
        SELECT COUNT(*)
          INTO l_subpart_idx
          FROM sqlt$_dba_ind_partitions
         WHERE statement_id = p_statement_id
           AND composite = 'YES'
           AND ROWNUM = 1;
      END IF;

      IF l_gran_tbl = 'SUBPARTITION' AND NVL(l_subpart_tbl, 0) = 0 THEN
        l_gran_tbl := 'PARTITION';
      END IF;

      IF l_gran_col = 'SUBPARTITION' AND NVL(l_subpart_tbl, 0) = 0 THEN
        l_gran_col := 'PARTITION';
      END IF;

      IF l_gran_hgr = 'SUBPARTITION' AND NVL(l_subpart_tbl, 0) = 0 THEN
        l_gran_hgr := 'PARTITION';
      END IF;

      IF l_gran_idx = 'SUBPARTITION' AND NVL(l_subpart_idx, 0) = 0 THEN
        l_gran_idx := 'PARTITION';
      END IF;

      IF l_gran_tbl = 'SUBPARTITION' THEN
        collect_dba_tab_subpartitions(p_statement_id, sql_rec.statid);
        IF l_gran_col = 'SUBPARTITION' THEN
          collect_dba_subpart_col_stats(p_statement_id, sql_rec.statid);
          IF l_gran_hgr = 'SUBPARTITION' THEN
            collect_dba_subpart_histograms(p_statement_id, sql_rec.statid);
          END IF;
        END IF;
      END IF;

      IF l_gran_idx = 'SUBPARTITION' THEN
        collect_dba_ind_subpartitions(p_statement_id, sql_rec.statid);
      END IF;

      IF l_gran_tbl = 'SUBPARTITION' OR l_gran_idx = 'SUBPARTITION' THEN
        l_gran_seg := 'SUBPARTITION';
      ELSIF l_gran_tbl = 'PARTITION' OR l_gran_idx = 'PARTITION' THEN
        l_gran_seg := 'PARTITION';
      ELSE
        l_gran_seg := 'GLOBAL';
      END IF;

      -- inmemory info
      collect_gv$im_segments(p_statement_id, sql_rec.statid);  -- depends on sqlg$_pivot
      collect_gv$im_column_level(p_statement_id, sql_rec.statid);  -- depends on sqlt$_dba_tab_cols 

      collect_dba_segments(p_statement_id, sql_rec.statid, l_gran_seg);
      collect_dba_tablespaces(p_statement_id, sql_rec.statid); -- depends on collect_dba_segments, collect_gv$sqlarea, collect_gv$sqlarea_plan_hash, collect_gv$sql, collect_dba_hist_sqlstat
      collect_dba_objects(p_statement_id, sql_rec.statid, l_gran_seg); -- depends on list_of_objects
      IF sql_rec.in_awr = 'Y' THEN
        collect_dba_hist_seg_stat_obj(p_statement_id, sql_rec.statid, l_gran_seg); -- depends on list_of_objects
      END IF;
      collect_dba_source(p_statement_id, sql_rec.statid);
      collect_dba_col_usage$(p_statement_id, sql_rec.statid); -- depends on collect_dba_objects
      collect_dba_policies(p_statement_id, sql_rec.statid); -- depends on collect_dba_objects
      collect_dba_audit_policies(p_statement_id, sql_rec.statid); -- depends on collect_dba_objects
      IF sqlt$a.get_rdbms_release >= 11 THEN
        collect_optstat_user_prefs$(p_statement_id, sql_rec.statid); -- depends on collect_dba_objects
      END IF;

      -- collect cbo stats versions
      IF sqlt$a.get_param_n('c_cbo_stats_vers_days') > 0 THEN
        write_log('capture up to "'||sqlt$a.get_param('c_cbo_stats_vers_days')||'" days of CBO statistics versions as per parameter c_cbo_stats_vers_days');
        collect_dba_optstat_operations(p_statement_id, sql_rec.statid);
        collect_dba_tab_stats_versn(p_statement_id, sql_rec.statid, l_gran_tbl); -- depends on collect_dba_objects
        collect_dba_ind_stats_versn(p_statement_id, sql_rec.statid, l_gran_idx); -- depends on collect_dba_objects
        collect_dba_col_stats_versn(p_statement_id, sql_rec.statid, l_gran_col); -- depends on collect_dba_objects
        collect_dba_histgrm_stats_ver(p_statement_id, sql_rec.statid, l_gran_hgr); -- depends on collect_dba_objects
        collect_wri$_optstat_aux_hist(p_statement_id, sql_rec.statid);
      ELSE
        write_log('skip collect_dba_*_stats_versn as per parameter c_cbo_stats_vers_days');
      END IF;

      collect_aux_stats$(p_statement_id, sql_rec.statid);
      collect_dbms_xplan_display(p_statement_id, sql_rec.statid);
      collect_dba_outlines(p_statement_id, sql_rec.statid);
      collect_dba_outline_hints(p_statement_id, sql_rec.statid); -- depends on collect_dba_outlines
      collect_wri$_adv_tasks(p_statement_id, sql_rec.statid);
      collect_wri$_adv_rationale(p_statement_id, sql_rec.statid); -- depends on collect_wri$_adv_tasks
      collect_dba_sqltune_plans(p_statement_id, sql_rec.statid); -- depends on collect_wri$_adv_tasks
      collect_dba_sql_profiles(p_statement_id, sql_rec.statid);
      collect_dbms_stats_glob_prefs(p_statement_id);

      -- sql plan baselines
      IF sqlt$a.get_rdbms_release >= 11 THEN
        collect_dba_sql_patches(p_statement_id, sql_rec.statid);
        collect_dba_sql_plan_baselines(p_statement_id, sql_rec.statid);
        collect_dbms_xplan_baseline(p_statement_id, sql_rec.statid); -- depends on collect_dba_sql_plan_baselines
        get_phv_4_sql_plan_baselines(p_statement_id, sql_rec.statid); -- depends on collect_dbms_xplan_baseline
      END IF;

      -- 12.1.08 sql plan directives 
      IF sqlt$a.get_rdbms_release >= 12 THEN
        collect_dba_sql_plan_directs(p_statement_id, sql_rec.statid);
      END IF;

      -- hints for sql profiles
      IF sqlt$a.get_rdbms_release >= 11 THEN
        collect_sqlobj$data(p_statement_id, sql_rec.statid);
        collect_sqlobj$(p_statement_id, sql_rec.statid);
      ELSE -- 10g
        collect_sqlprof$attr(p_statement_id, sql_rec.statid);
        collect_sqlprof$(p_statement_id, sql_rec.statid);
      END IF;

      -- dbms_stats job
      IF sqlt$a.get_rdbms_release >= 11 THEN
        collect_dba_autotask_client(p_statement_id, sql_rec.statid);
        collect_dba_autotask_client_h(p_statement_id, sql_rec.statid);
      ELSE -- 10g
        collect_dba_scheduler_jobs(p_statement_id, sql_rec.statid);
      END IF;

      one_plan_per_hv_mem(p_statement_id); -- depends on diagnostics_data_collection_1
      one_plan_per_hv_sta(p_statement_id);
      collect_plan_extensions(p_statement_id, sql_rec.statid); -- depends on one_plan_per_hv_* and all plans been collected
      write_log('<- expanded collection');
    END;

    COMMIT;
    write_log('<= diagnostics_data_collection_2');
  END diagnostics_data_collection_2;

  /*************************************************************************************/

END sqlt$d;
/

SET TERM ON;
SHOW ERRORS PACKAGE BODY &&tool_administer_schema..sqlt$d;
