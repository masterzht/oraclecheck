CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..sqlt$a AS
/* $Header: 215187.1 sqcpkga.pkb 19.0.180825 2018/08/25 stelios.charalambides@oracle.com carlos.sierra mauro.pagano abel.macias $ */
/* 
 * 28th October 2018. Stelios Charalambides
 * This line was added in public get_v$parameter "l_query varchar2(500);" to take account of very long link names. The previous line had only 100 
 * characters. 
 *
 ***************************************************************************************/

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  TOOL_REPOSITORY_SCHEMA CONSTANT VARCHAR2(32) := '&&tool_repository_schema.';
  TOOL_ADMINISTER_SCHEMA CONSTANT VARCHAR2(32) := '&&tool_administer_schema.';
  ROLE_NAME              CONSTANT VARCHAR2(32) := '&&role_name.';
  TOOL_NAME              CONSTANT VARCHAR2(32) := '&&tool_name.';
  TOOL_TRACE             CONSTANT VARCHAR2(32) := '&&tool_trace.';
  LF                     CONSTANT CHAR(1) := CHR(10);
  NUL                    CONSTANT CHAR(1) := CHR(00);
  MAX_PUT_LINE           CONSTANT NUMBER := 255;

  /*************************************************************************************/

  -- 171004 Extensive replacement of variables to varchar2(257)
  
  /* -------------------------
   *
   * static variables
   *
   * ------------------------- */
  s_sid v$session.sid%TYPE;
  s_statid VARCHAR2(32767);
  s_keep_trace_10046_open VARCHAR2(32767);
  s_event_10053_level VARCHAR2(32767);
  s_event_10046_level VARCHAR2(32767);
  s_event_10507_level NUMBER;
  s_event_others VARCHAR2(32767);
  s_rdbms_version v$instance.version%TYPE;
  s_rdbms_release NUMBER;
  s_timestamp_before TIMESTAMP(6) WITH TIME ZONE;
  s_timestamp_after TIMESTAMP(6) WITH TIME ZONE;
  s_optimizer_mode VARCHAR2(32767);
  s_optimizer_index_cost_adj VARCHAR2(32767);
  s_optimizer_dynamic_sampling VARCHAR2(32767);
  s_hash_join_enabled VARCHAR2(32767);
  s_sortmerge_join_enabled VARCHAR2(32767);
  s_prior_log_entry DATE;

  -- 150824 Making v_db_link private
  v_db_link sys.all_db_links.db_link%TYPE:=null; -- used only by sqltxtrsby, all other methods set this is NULL
  -- 22170172 making s_statistics_level private
  s_statistics_level v$parameter2.name%TYPE;
  
  /*************************************************************************************/

  /* -------------------------
   * 
   * public s_db_link  
   *
   * 150824 new
   * ------------------------- */

  FUNCTION s_db_link RETURN sys.all_db_links.db_link%TYPE
  IS
   BEGIN
    return v_db_link;
   END s_db_link;
   
  /*************************************************************************************/
  
  /* -------------------------
   * 
   * public validate_db_link(p_dblink)
   * 
   * 150824 new
   * 22170172 Add DBMS_ASSERT
   * ------------------------- */
   
  FUNCTION validate_db_link(p_dblink sys.all_db_links.db_link%TYPE) return sys.all_db_links.db_link%TYPE 
  IS
    l_link sys.all_db_links.db_link%TYPE:=null;
  BEGIN
    IF TRIM(p_dblink) IS NOT NULL THEN  
      BEGIN -- 150824 Moved to verify_db_link
	        -- 150220 let RDBMS figure out which dblink the user has access. I just want to know there is one.
        SELECT replace(DBMS_ASSERT.QUALIFIED_SQL_NAME('DUAL@'||db_link),'DUAL')
          INTO l_link
          FROM sys.DBA_DB_LINKS 
         WHERE db_link = REPLACE('@'||REPLACE(UPPER(REPLACE(p_dblink, ' ')), '@'), '@')
		   and rownum=1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
		 l_link:= null;
      END;
    ELSE
     l_link := NULL;
    END IF;	 
	return l_link;
  END validate_db_link;
   
  /*************************************************************************************/

  /* -------------------------
   *
   * public set_stand_by_dblink
   *
   * 150824 replacing s_db_link with v_db_link and moving verification to validate_db_link
   * 22170172 Add DBMS_ASSERT
   * ------------------------- */
  PROCEDURE set_stand_by_dblink (p_stand_by_dblink IN VARCHAR2 DEFAULT NULL)
  IS
  BEGIN
    IF TRIM(p_stand_by_dblink) IS NOT NULL THEN
	  
	  v_db_link :=replace(DBMS_ASSERT.QUALIFIED_SQL_NAME('DUAL'||validate_db_link(p_stand_by_dblink)),'DUAL');
      if v_db_link is null then
       RAISE_APPLICATION_ERROR(-20327, 'DB Link "'||p_stand_by_dblink||'" does not exist.');
      END if;
    ELSE
      v_db_link := NULL;
    END IF;
  END set_stand_by_dblink;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_method
   *
   * ------------------------- */
  PROCEDURE set_method (p_method IN VARCHAR2 DEFAULT NULL)
  IS
  BEGIN
    s_sqlt_method := UPPER(TRIM(p_method));
  END set_method;

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
   * public put_line
   *
   * ------------------------- */
  PROCEDURE put_line (p_line_text IN VARCHAR2)
  IS
    l_line VARCHAR2(32767);
    l_line_piece VARCHAR2(32767);
  BEGIN
    l_line := p_line_text;
    WHILE NVL(LENGTH(l_line), 0) > 0
    LOOP
      l_line_piece := SUBSTR(l_line, 1 , MAX_PUT_LINE);
      SYS.DBMS_OUTPUT.PUT_LINE(l_line_piece);
      l_line := SUBSTR(l_line, LENGTH(l_line_piece) + 1);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      SYS.DBMS_OUTPUT.PUT_LINE(SUBSTR('put_line: '||p_line_text, 1, MAX_PUT_LINE));
      SYS.DBMS_OUTPUT.PUT_LINE(SUBSTR(SQLERRM, 1, MAX_PUT_LINE));
  END put_line;

  /*************************************************************************************/

  /* -------------------------
   *
   * public write_log
   *
   * ------------------------- */
  PROCEDURE write_log (
    p_line_text IN VARCHAR2,
    p_line_type IN VARCHAR2 DEFAULT 'L', -- (L)og/(S)ilent/(E)rror/(P)rint
    p_package   IN VARCHAR2 DEFAULT 'A' )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    log_rec sqlt$_log%ROWTYPE;
    l_line_text VARCHAR2(32767);
    l_seconds_since_prior NUMBER;

  BEGIN
    --12.1.10
    DBMS_OUTPUT.ENABLE(1000000);

    log_rec := NULL;
    SELECT sqlt$_line_id_s.NEXTVAL INTO log_rec.line_id FROM DUAL;
    set_module(p_module_name => LOWER(TOOL_ADMINISTER_SCHEMA||'.sqlt$'||p_package||' ('||s_sqlt_method||')'), p_action_name => s_log_statement_id||' '||log_rec.line_id||' '||p_line_text);

    l_line_text := SUBSTR('sqlt$'||LOWER(p_package)||': '||p_line_text, 1, 4000);
    l_seconds_since_prior := ROUND((SYSDATE - NVL(s_prior_log_entry, SYSDATE)) * 24 * 60 * 60);

    -- (L)og/(S)ilent/(E)rror: insert line into log table
    IF NVL(p_line_type, 'L') IN ('L', 'S', 'E') THEN
      log_rec.statement_id := s_log_statement_id;
      log_rec.statid := s_log_statid;
      log_rec.time_stamp := SYSTIMESTAMP;
      log_rec.line_type := p_line_type;
      log_rec.line_text := l_line_text;

      IF log_rec.statement_id IS NOT NULL AND log_rec.statid IS NOT NULL THEN
        BEGIN
          INSERT INTO sqlt$_log VALUES log_rec;
          COMMIT;
        EXCEPTION
          WHEN OTHERS THEN
            SYS.DBMS_OUTPUT.PUT_LINE(SUBSTR('write_log1:'||SQLERRM, 1, MAX_PUT_LINE));
            ROLLBACK;
        END;
      END IF;
    END IF;

    -- (L)og/(E)rror/(P)rint: put line into spool file
    IF NVL(p_line_type, 'L') IN ('L', 'P', 'E') THEN
      put_line(TO_CHAR(SYSTIMESTAMP, 'HH24:MI:SS')||LPAD(l_seconds_since_prior, 5)||' '||l_line_text);
      s_prior_log_entry := SYSDATE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      SYS.DBMS_OUTPUT.PUT_LINE(SUBSTR(SQLERRM, 1, MAX_PUT_LINE));
      SYS.DBMS_OUTPUT.PUT_LINE(SUBSTR('write_log2:'||NVL(l_line_text, p_line_text), 1, MAX_PUT_LINE));
      ROLLBACK;
  END write_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * public write_error
   *
   * ------------------------- */
  PROCEDURE write_error (p_line_text IN VARCHAR2)
  IS
  BEGIN
    IF SUBSTR(p_line_text, 2, 1) = ':' THEN
      write_log('*** '||p_line_text, 'E');
    ELSE
      write_log('*** a:'||p_line_text, 'E');
    END IF;
  END write_error;

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

    IF p_href <> 'javascript:void(0);' THEN
      l_return := l_return||' href="'||p_href||'"';
    END IF;

    IF s_overlib = 'Y' THEN
      IF p_href = 'javascript:void(0);' THEN
        l_return := l_return||' href="'||p_href||'"';
      END IF;

      l_return := l_return||' onmouseover="return overlib('||
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

      l_return := l_return||');" onmouseout="return nd();"';
    END IF;

    l_return := l_return||'>'||p_main_text||'</a>';

    RETURN l_return;
  END mot;

  /*************************************************************************************/

  /* -------------------------
   *
   * private execute_immediate
   *
   * ------------------------- */
  PROCEDURE execute_immediate (
    p_command   IN VARCHAR2,
    p_line_type IN VARCHAR2 DEFAULT 'L' ) -- (L)og/(S)ilent/(E)rror/(P)rint
  IS
  BEGIN
    EXECUTE IMMEDIATE p_command;
    write_log(p_command, p_line_type);
  EXCEPTION
    WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error(p_command);
  END execute_immediate;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_numbers_and_letters
   *
   * ------------------------- */
  FUNCTION get_numbers_and_letters (p_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN TRANSLATE(p_name,
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ''`~!@#$%^*()-_=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789');
  END get_numbers_and_letters;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_clean_name
   *
   * ------------------------- */
  FUNCTION get_clean_name (p_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN SUBSTR(get_numbers_and_letters(p_name), 1, 30);
  END get_clean_name;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_sql_id
   *
   * ------------------------- */
  FUNCTION get_sql_id (p_statement_id IN NUMBER)
  RETURN VARCHAR2
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
  BEGIN
    sql_rec := get_statement(p_statement_id);
    RETURN sql_rec.sql_id;
  END get_sql_id;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_sql_id_or_hash_value
   *
   * called by: sqlt$a.find_sql_in_memory_or_awr
   *
   * ------------------------- */
  PROCEDURE get_sql_id_or_hash_value (
    p_sql_id_or_hash_value  IN  VARCHAR2,
    x_sql_id                OUT VARCHAR2,
    x_hash_value            OUT NUMBER )
  IS
    l_sql_id_or_hash_value VARCHAR2(32767);
  BEGIN
    write_log('-> get_sql_id_or_hash_value');

    x_sql_id := NULL;
    x_hash_value := NULL;
    l_sql_id_or_hash_value := TRIM(p_sql_id_or_hash_value);

    IF l_sql_id_or_hash_value IS NULL THEN
      RETURN;
    END IF;

    IF LENGTH(l_sql_id_or_hash_value) <> 13 THEN
      BEGIN
        x_hash_value := l_sql_id_or_hash_value;
        write_log('hash_value = "'||x_hash_value||'"');
        RETURN; -- it was numeric
      EXCEPTION
        WHEN OTHERS THEN -- varchar2
          NULL;
      END;
    END IF;

    IF LENGTH(l_sql_id_or_hash_value) <> 13 THEN
      NULL; -- it cannot be sql_id
    ELSIF LENGTH(REPLACE(TRANSLATE(l_sql_id_or_hash_value, '01234567890abcdefghijklmnopqrstuvwxyz', NUL), NUL)) > 0 THEN
      NULL; -- it cannot be sql_id
    ELSE
      x_sql_id := l_sql_id_or_hash_value; -- it must be sql_id
      write_log('sql_id = "'||x_sql_id||'"');
    END IF;

    write_log('<- get_sql_id_or_hash_value');
  END get_sql_id_or_hash_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * private sql_in_memory_or_awr
   *
   * called by: sqlt$a.find_sql_in_memory_or_awr
   * 22170172 added DBMS_ASSERT
   * ------------------------- */
  PROCEDURE sql_in_memory_or_awr (
    p_string         IN     VARCHAR2, -- XECUTE: sqlt_s95979. XPLAIN: EXPLAIN PLAN SET statement_id = '95995' INTO &&tool_repository_schema..sqlt$_sql_plan_table FOR
    p_input_filename IN     VARCHAR2 DEFAULT NULL,
    x_sql_id         IN OUT VARCHAR2,
    x_hash_value     IN OUT NUMBER,
    x_in_memory      IN OUT VARCHAR2,
    x_in_awr         IN OUT VARCHAR2 )
  IS
    l_dbid NUMBER;
    l_sql VARCHAR2(32767);
    l_sql_text VARCHAR2(32767);
	-- 22170172 l_sqlarea validation
	l_sqlarea varchar2(100); 
  BEGIN
    write_log('-> sql_in_memory_or_awr');

	l_sqlarea:=DBMS_ASSERT.QUALIFIED_SQL_NAME('gv$sqlarea'||s_db_link);
    -- in_memory
    BEGIN
      x_in_memory := 'N';

      IF p_string IS NOT NULL AND x_sql_id IS NOT NULL THEN
        -- given string (like sqlt_s12345) and sql_id finds hash_value in memory
        BEGIN
          l_sql :=
          'SELECT hash_value, sql_text '||LF||
          '  FROM ( '||LF||
          'SELECT hash_value, sql_text '||LF||
          '  FROM '||l_sqlarea||' '||LF||
          ' WHERE sql_id = :sql_id '||LF||
          '   AND sql_text LIKE :string '||LF||
          '   AND NVL(command_type, -1) <> 47 /* excludes PL/SQL EXECUTE */ '||LF||
          ' ORDER BY /* DML before PL/SQL EXECUTE */ '||LF||
          '       command_type ) v '||LF||
          ' WHERE ROWNUM = 1 ';
          write_log(l_sql, 'S');

          EXECUTE IMMEDIATE l_sql
          INTO x_hash_value, l_sql_text
          USING IN x_sql_id, IN '%'||p_string||'%';

          IF l_sql_text LIKE '%DELETE &&tool_administer_schema..sqlt$_sql_plan_table WHERE statement_id IS NULL%' OR -- XPLAIN
             l_sql_text LIKE '%BEGIN DBMS_OUTPUT.DISABLE; END;%' -- XECUTE
          THEN
            RAISE_APPLICATION_ERROR (-20322, 'File "'||p_input_filename||'" not found. Unable to open "'||p_input_filename||'"', TRUE);
          END IF;

          x_in_memory := 'Y';
          write_log('sql found in memory using sql_id = "'||x_sql_id||'" and string = "'||p_string||'" (excludes PL/SQL EXECUTE)');
          write_log('hash_value = "'||x_hash_value||'"');
          write_log(l_sql_text);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            write_log('sql not found in memory using sql_id = "'||x_sql_id||'" and string = "'||p_string||'" (excludes PL/SQL EXECUTE)');
        END;
      END IF;

      IF x_in_memory = 'N' AND p_string IS NOT NULL THEN
        -- given string (like sqlt_s12345) finds sql_id and hash_value in memory
        BEGIN
          l_sql :=
          'SELECT sql_id, hash_value, sql_text '||LF||
          '  FROM ( '||LF||
          'SELECT sql_id, hash_value, sql_text '||LF||
          '  FROM '||l_sqlarea||' '||LF||
          ' WHERE sql_text LIKE :string '||LF||
          ' ORDER BY /* DML before PL/SQL EXECUTE */ '||LF||
          '       command_type ) v '||LF||
          ' WHERE ROWNUM = 1 ';
          write_log(l_sql, 'S');

          EXECUTE IMMEDIATE l_sql
          INTO x_sql_id, x_hash_value, l_sql_text
          USING IN '%'||p_string||'%';

          IF l_sql_text LIKE '%DELETE &&tool_administer_schema..sqlt$_sql_plan_table WHERE statement_id IS NULL%' OR -- XPLAIN
             l_sql_text LIKE '%BEGIN DBMS_OUTPUT.DISABLE; END;%' -- XECUTE
          THEN
            RAISE_APPLICATION_ERROR (-20323, 'File "'||p_input_filename||'" not found. Unable to open "'||p_input_filename||'"', TRUE);
          END IF;

          x_in_memory := 'Y';
          write_log('sql found in memory using string = "'||p_string||'"');
          write_log('sql_id = "'||x_sql_id||'", hash_value = "'||x_hash_value||'"');
          write_log(l_sql_text);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            write_log('sql not found in memory using string = "'||p_string||'"');
        END;
      END IF;

      IF x_in_memory = 'N' THEN
        IF x_sql_id IS NOT NULL THEN
          -- given sql_id finds hash_value in memory
          BEGIN
            l_sql :=
            'SELECT hash_value, sql_text '||LF||
            '  FROM ( '||LF||
            'SELECT hash_value, sql_text '||LF||
            '  FROM '||l_sqlarea||' '||LF||
            ' WHERE sql_id = :sql_id '||LF||
            ' ORDER BY /* DML before PL/SQL EXECUTE */ '||LF||
            '       command_type ) v '||LF||
            ' WHERE ROWNUM = 1 ';
            write_log(l_sql, 'S');

            EXECUTE IMMEDIATE l_sql
            INTO x_hash_value, l_sql_text
            USING IN x_sql_id;

            IF l_sql_text LIKE '%DELETE &&tool_administer_schema..sqlt$_sql_plan_table WHERE statement_id IS NULL%' OR -- XPLAIN
               l_sql_text LIKE '%BEGIN DBMS_OUTPUT.DISABLE; END;%' -- XECUTE
            THEN
              RAISE_APPLICATION_ERROR (-20324, 'File "'||p_input_filename||'" not found or content is invalid. Unable to process "'||p_input_filename||'"', TRUE);
            END IF;

            x_in_memory := 'Y';
            write_log('sql found in memory using sql_id = "'||x_sql_id||'"');
            write_log('hash_value = "'||x_hash_value||'"');
            write_log(l_sql_text);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              write_log('sql not found in memory using sql_id = "'||x_sql_id||'"');
          END;
        ELSIF x_hash_value IS NOT NULL THEN
          -- given hash_value finds sql_id in memory
          BEGIN
            l_sql :=
            'SELECT sql_id, sql_text '||LF||
            '  FROM ( '||LF||
            'SELECT sql_id, sql_text '||LF||
            '  FROM '||l_sqlarea||' '||LF||
            ' WHERE hash_value = :hash_value '||LF||
            ' ORDER BY /* DML before PL/SQL EXECUTE */ '||LF||
            '       command_type ) v '||LF||
            ' WHERE ROWNUM = 1 ';
            write_log(l_sql, 'S');

            EXECUTE IMMEDIATE l_sql
            INTO x_sql_id, l_sql_text
            USING IN x_hash_value;

            IF l_sql_text LIKE '%DELETE &&tool_administer_schema..sqlt$_sql_plan_table WHERE statement_id IS NULL%' OR -- XPLAIN
               l_sql_text LIKE '%BEGIN DBMS_OUTPUT.DISABLE; END;%' -- XECUTE
            THEN
              RAISE_APPLICATION_ERROR (-20325, 'File "'||p_input_filename||'" not found. Unable to open "'||p_input_filename||'"', TRUE);
            END IF;

            x_in_memory := 'Y';
            write_log('sql found in memory using hash_value = "'||x_hash_value||'"');
            write_log('sql_id = "'||x_sql_id||'"');
            write_log(l_sql_text);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              write_log('sql not found in memory using hash_value = "'||x_hash_value||'"');
          END;
        END IF;
      END IF;
      
      IF x_in_memory = 'N' AND x_sql_id IS NULL AND	x_hash_value IS NOT NULL THEN
      -- try with Plan Hash Value
          BEGIN
            l_sql :=
            'SELECT sql_id, sql_text '||LF||
            '  FROM ( '||LF||
            'SELECT sql_id, sql_text '||LF||
            '  FROM '||l_sqlarea||' '||LF||
            ' WHERE plan_hash_value = :hash_value '||LF||
            ' ORDER BY elapsed_time/decode(executions,0,1,executions) ) v '||LF||
            ' WHERE ROWNUM = 1 ';
            write_log(l_sql, 'S');

            EXECUTE IMMEDIATE l_sql
            INTO x_sql_id, l_sql_text
            USING IN x_hash_value;

            IF l_sql_text LIKE '%DELETE &&tool_administer_schema..sqlt$_sql_plan_table WHERE statement_id IS NULL%' OR -- XPLAIN
               l_sql_text LIKE '%BEGIN DBMS_OUTPUT.DISABLE; END;%' -- XECUTE
            THEN
              RAISE_APPLICATION_ERROR (-20325, 'File "'||p_input_filename||'" not found. Unable to open "'||p_input_filename||'"', TRUE);
            END IF;

            x_in_memory := 'Y';
            write_log('sql found in memory using plan_hash_value = "'||x_hash_value||'"');
            write_log('sql_id = "'||x_sql_id||'"');
            write_log(l_sql_text);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              write_log('sql not found in memory using plan_hash_value = "'||x_hash_value||'"');
          END;
      END IF;
    END;
	
    

    -- in_awr
    BEGIN
      x_in_awr := 'N';
      IF get_param('automatic_workload_repository') = 'Y' AND get_param_n('c_awr_hist_days') > 0 THEN
        IF x_sql_id IS NOT NULL THEN
          BEGIN
            DELETE sqlg$_clob;
            l_dbid := get_database_id;

            l_sql :=
            'INSERT INTO sqlg$_clob '||LF||
            'SELECT sql_text '||LF||
             -- 22170172 dba_hist_sqltext validation			
            '  FROM '||DBMS_ASSERT.QUALIFIED_SQL_NAME('sys.dba_hist_sqltext'||s_db_link)||' '||LF||
            ' WHERE dbid = :dbid '||LF||
            '   AND sql_id = :sql_id '||LF||
            '   AND ROWNUM = 1 ';
            write_log(l_sql, 'S');

            EXECUTE IMMEDIATE l_sql
            USING IN l_dbid, IN x_sql_id;

            SELECT SYS.DBMS_LOB.SUBSTR(clob_text, 1000)
              INTO l_sql_text
              FROM sqlg$_clob;

            x_in_awr := 'Y';
            write_log('sql found in awr using sql_id = "'||x_sql_id||'"');

            IF x_in_memory = 'N' THEN
              write_log(l_sql_text);
            END IF;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              write_log('sql not found in awr using sql_id = "'||x_sql_id||'"');
          END;
        END IF;
      ELSE
        write_log('skip search into awr as per parameter automatic_workload_repository or c_awr_hist_days');
      END IF;
    END;

    write_log('<- sql_in_memory_or_awr');
  END sql_in_memory_or_awr;

  /*************************************************************************************/

  /* -------------------------
   *
   * public find_sql_in_memory_or_awr
   *
   * called by: sqlt$d.capture_statement
   *
   * ------------------------- */
  PROCEDURE find_sql_in_memory_or_awr (
    p_string                IN     VARCHAR2, -- XECUTE: sqlt_s95979. XPLAIN: EXPLAIN PLAN SET statement_id = '95995' INTO &&tool_repository_schema..sqlt$_sql_plan_table FOR
    p_sql_id_or_hash_value  IN     VARCHAR2,
    p_input_filename        IN     VARCHAR2 DEFAULT NULL,
    x_sql_id                IN OUT VARCHAR2,
    x_hash_value            IN OUT NUMBER,
    x_in_memory             IN OUT VARCHAR2,
    x_in_awr                IN OUT VARCHAR2 )
  IS
    l_string VARCHAR2(32767);
  BEGIN
    write_log('-> find_sql_in_memory_or_awr');

    get_sql_id_or_hash_value (
      p_sql_id_or_hash_value  => p_sql_id_or_hash_value,
      x_sql_id                => x_sql_id,
      x_hash_value            => x_hash_value );

    IF x_sql_id IS NULL AND x_hash_value IS NULL AND p_string IS NULL THEN
      x_in_memory := 'N';
      x_in_awr    := 'N';
    ELSE
      sql_in_memory_or_awr (
        p_string         => p_string,
        p_input_filename => p_input_filename,
        x_sql_id         => x_sql_id,
        x_hash_value     => x_hash_value,
        x_in_memory      => x_in_memory,
        x_in_awr         => x_in_awr );
    END IF;

    write_log('<- find_sql_in_memory_or_awr');
  END find_sql_in_memory_or_awr;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_db_links
   *
   * called by sqlt$i.remote_trace_begin and sqlt$i.remote_trace_end
   *
   * ------------------------- */
  PROCEDURE get_db_links
  IS
  BEGIN
    -- 150824 to prevent sql injection.
    DELETE sqlg$_temp WHERE c1 not in (select a.db_link from dba_db_links a);
    INSERT INTO sqlg$_temp (c1, n1)
    SELECT DISTINCT db_link, 1 FROM sys.dba_db_links;
  END get_db_links;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_db_links
   *
   * called by sqlt$i.remote_trace_begin
   *
   * ------------------------- */
  PROCEDURE get_db_links (p_sql_id IN VARCHAR2)
  IS
  BEGIN
    INSERT INTO sqlg$_temp (c1, n1)
    SELECT DISTINCT s.object_node, 2
      FROM v$sql_plan s
     WHERE s.sql_id = p_sql_id
       AND s.object_node IS NOT NULL
       AND s.object_node NOT LIKE '%:%'
       AND EXISTS (
    SELECT NULL
      FROM sys.dba_db_links d
     WHERE d.db_link = s.object_node);
  END get_db_links;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_rdbms_version
   *
   * ------------------------- */
  FUNCTION get_rdbms_version
  RETURN VARCHAR2
  IS
  BEGIN
    IF s_rdbms_version IS NULL THEN
      EXECUTE IMMEDIATE 'SELECT version FROM v$instance'||s_db_link INTO s_rdbms_version;
    END IF;
    RETURN s_rdbms_version;
  END get_rdbms_version;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_rdbms_version_short
   *
   * ------------------------- */
  FUNCTION get_rdbms_version_short
  RETURN VARCHAR2
  IS
    l_rdbms_version v$instance.version%TYPE;
  BEGIN
    l_rdbms_version := get_rdbms_version;
    IF l_rdbms_version LIKE '11.2.%' THEN
      RETURN '11.2.X';
    ELSIF l_rdbms_version LIKE '11.1.%' THEN
      RETURN '11.1.X';
    ELSIF l_rdbms_version LIKE '10.2.%' THEN
      RETURN '10.2.X';
    ELSIF l_rdbms_version LIKE '10.1.%' THEN
      RETURN '10.1.X';
    ELSIF l_rdbms_version LIKE '9.2.%' THEN
      RETURN '9.2.0.X';
    ELSIF l_rdbms_version LIKE '8.1.7.%' THEN
      RETURN '8.1.7.X';
    ELSE
      RETURN 'UNKNOWN';
    END IF;
  END get_rdbms_version_short;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_rdbms_release
   *
   * ------------------------- */
  FUNCTION get_rdbms_release
  RETURN NUMBER
  IS
    l_rdbms_version v$instance.version%TYPE;
    l_dot1 NUMBER;
    l_dot2 NUMBER;
  BEGIN
    IF s_rdbms_release IS NULL THEN
      l_rdbms_version := get_rdbms_version;
      l_dot1 := INSTR(l_rdbms_version, '.');
      l_dot2 := INSTR(l_rdbms_version, '.', l_dot1 + 1);
      s_rdbms_release :=
      TO_NUMBER(SUBSTR(l_rdbms_version, 1, l_dot1 - 1)) +
      (TO_NUMBER(SUBSTR(l_rdbms_version, l_dot1 + 1, l_dot2 - l_dot1 - 1)) / POWER(10, (l_dot2 - l_dot1 - 1)));
    END IF;
    RETURN s_rdbms_release;
  END get_rdbms_release;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_database_id
   *
   * ------------------------- */
  FUNCTION get_database_id
  RETURN NUMBER
  IS
    l_dbid v$database.dbid%TYPE;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT dbid FROM v$database'||s_db_link INTO l_dbid;
    RETURN l_dbid;
  END get_database_id;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_database_name
   *
   * ------------------------- */
  FUNCTION get_database_name
  RETURN VARCHAR2
  IS
    l_name v$database.name%TYPE;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT name FROM v$database'||s_db_link INTO l_name;
    RETURN l_name;
  END get_database_name;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_database_name_short
   *
   * ------------------------- */
  FUNCTION get_database_name_short
  RETURN VARCHAR2
  IS
    l_name v$database.name%TYPE;
  BEGIN
    l_name := get_database_name;
    RETURN get_numbers_and_letters(SUBSTR(l_name, 1, INSTR(l_name||'.', '.') - 1));
  END get_database_name_short;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_db_link_short
   *
   * ------------------------- */
  FUNCTION get_db_link_short (p_db_link IN VARCHAR2)
  RETURN VARCHAR2
  IS
    l_length NUMBER;
  BEGIN
    l_length := NVL(INSTR(p_db_link, '.'), 0);
    IF l_length = 0 THEN
      l_length := LEAST(LENGTH(p_db_link), 20);
    ELSE
      l_length := LEAST(l_length - 1, 20);
    END IF;
    RETURN SUBSTR(LOWER(p_db_link), 1, l_length);
  END get_db_link_short;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_sid
   *
   * ------------------------- */
  FUNCTION get_sid
  RETURN NUMBER
  IS
    l_sid NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT sid FROM v$mystat'||s_db_link||' WHERE ROWNUM = 1' INTO l_sid;
    RETURN l_sid;
  END get_sid;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_instance_number
   *
   * ------------------------- */
  FUNCTION get_instance_number
  RETURN NUMBER
  IS
    l_instance_number NUMBER;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT instance_number FROM v$instance'||s_db_link INTO l_instance_number;
    RETURN l_instance_number;
  END get_instance_number;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_instance_name
   *
   * ------------------------- */
  FUNCTION get_instance_name
  RETURN VARCHAR2
  IS
    l_instance_name v$instance.instance_name%TYPE;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT instance_name FROM v$instance'||s_db_link INTO l_instance_name;
    RETURN l_instance_name;
  END get_instance_name;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_host_name
   *
   * ------------------------- */
  FUNCTION get_host_name
  RETURN VARCHAR2
  IS
    l_host_name v$instance.host_name%TYPE;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT host_name FROM v$instance'||s_db_link INTO l_host_name;
    RETURN l_host_name;
  END get_host_name;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_host_name_short
   *
   * ------------------------- */
  FUNCTION get_host_name_short
  RETURN VARCHAR2
  IS
    l_host_name v$instance.host_name%TYPE;
  BEGIN
    l_host_name := SUBSTR(get_host_name, 1, 64);
    RETURN get_numbers_and_letters(SUBSTR(l_host_name, 1, INSTR(l_host_name||'.', '.') - 1));
  END get_host_name_short;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_platform
   *
   * ------------------------- */
  FUNCTION get_platform
  RETURN VARCHAR2
  IS
    l_platform product_component_version.product%TYPE;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT product FROM product_component_version'||s_db_link||' WHERE product LIKE ''TNS for%'' AND ROWNUM = 1' INTO l_platform;
    RETURN TRIM(REPLACE(REPLACE(l_platform, 'TNS for '), ':' ));
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'UNKNOWN';
  END get_platform;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_product_version
   *
   * ------------------------- */
  FUNCTION get_product_version
  RETURN VARCHAR2
  IS
    l_product_version VARCHAR2(32767);
  BEGIN
    EXECUTE IMMEDIATE 'SELECT product||''(''||status||'')'' FROM product_component_version'||s_db_link||' WHERE UPPER(product) LIKE ''%ORACLE%'' AND ROWNUM = 1' INTO l_product_version;
    RETURN l_product_version;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN 'UNKNOWN';
  END get_product_version;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_language
   *
   * ------------------------- */
  FUNCTION get_language
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN SYS_CONTEXT('USERENV', 'LANG')||':'||SYS_CONTEXT('USERENV', 'LANGUAGE');
  END get_language;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_v$parameter
   * 22170172 add DBMS_ASSERT
   * ------------------------- */
  FUNCTION get_v$parameter (p_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
    l_value v$parameter.value%TYPE;
	l_query varchar2(500); 
  BEGIN
    l_query:= 'SELECT value FROM '||DBMS_ASSERT.QUALIFIED_SQL_NAME('v$parameter2'||s_db_link)||' WHERE LOWER(name) = LOWER(:p_name)';
    BEGIN
      EXECUTE IMMEDIATE l_query INTO l_value USING IN p_name;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_value := NULL;
    END;

    IF l_value IS NULL THEN
	  l_query:= 'SELECT value FROM '||DBMS_ASSERT.QUALIFIED_SQL_NAME('sys.sqlt$_gv$parameter_cbo_v'||s_db_link)||' WHERE LOWER(name) = LOWER(:p_name)';
      EXECUTE IMMEDIATE l_query INTO l_value USING IN p_name;
    END IF;

    RETURN l_value;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
	WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error(p_name);	  
  END get_v$parameter;
 
  /* -------------------------
   *
   * public get_v$osstat
   *
   * ------------------------- */ 
  FUNCTION get_v$osstat (p_name IN VARCHAR2)
  RETURN NUMBER
  IS
    l_value v$osstat.value%TYPE;
  BEGIN
    BEGIN
      EXECUTE IMMEDIATE 'SELECT value FROM v$osstat'||s_db_link||' WHERE LOWER(stat_name) = LOWER(:p_name)' INTO l_value USING IN p_name;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_value := NULL;
    END;

    RETURN l_value;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END get_v$osstat;  

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_database_properties
   *
   * ------------------------- */
  FUNCTION get_database_properties (p_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
    l_value database_properties.property_value%TYPE;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT property_value FROM database_properties'||s_db_link||' WHERE UPPER(property_name) = UPPER(:p_name)' INTO l_value USING IN p_name;
    RETURN l_value;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END get_database_properties;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_sqlt$_v$parameter2
   *
   * ------------------------- */
  FUNCTION get_sqlt$_v$parameter2 (
    p_statement_id IN NUMBER,
    p_name         IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_value sqlt$_gv$parameter2.value%TYPE;
  BEGIN
    sql_rec := get_statement(p_statement_id);

    SELECT value
      INTO l_value
      FROM sqlt$_gv$parameter2
     WHERE statement_id = p_statement_id
       AND inst_id = sql_rec.instance_number
       AND LOWER(name) = LOWER(p_name);

    RETURN l_value;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END get_sqlt$_v$parameter2;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_sqlt_v$session_fix_control
   *
   * ------------------------- */
  FUNCTION get_sqlt_v$session_fix_control (
    p_statement_id IN NUMBER,
    p_bugno        IN NUMBER )
  RETURN NUMBER
  IS
    l_value sqlt$_v$session_fix_control.value%TYPE;
  BEGIN
    SELECT value
      INTO l_value
      FROM sqlt$_v$session_fix_control
     WHERE statement_id = p_statement_id
       AND bugno = p_bugno;

    RETURN l_value;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END get_sqlt_v$session_fix_control;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_sqlt$_gv$parameter_cbo
   *
   * ------------------------- */
  FUNCTION get_sqlt$_gv$parameter_cbo (
    p_statement_id IN NUMBER,
    p_name         IN VARCHAR2 )
  RETURN sqlt$_gv$parameter_cbo%ROWTYPE
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    par_rec sqlt$_gv$parameter_cbo%ROWTYPE;
  BEGIN
    sql_rec := get_statement(p_statement_id);

    SELECT *
      INTO par_rec
      FROM sqlt$_gv$parameter_cbo
     WHERE statement_id = p_statement_id
       AND inst_id = sql_rec.instance_number
       AND LOWER(name) = LOWER(p_name);

    RETURN par_rec;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END get_sqlt$_gv$parameter_cbo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_v$parameter_cbo
   *
   * ------------------------- */
  FUNCTION get_v$parameter_cbo (
    p_name         IN VARCHAR2,
    p_statement_id IN NUMBER )
  RETURN VARCHAR2
  IS
    par_rec sqlt$_gv$parameter_cbo%ROWTYPE;
  BEGIN
    par_rec := get_sqlt$_gv$parameter_cbo(p_statement_id => p_statement_id, p_name => p_name);
    RETURN par_rec.value;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
  END get_v$parameter_cbo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_param
   *
   * ------------------------- */
  FUNCTION get_param (p_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
    par_sess_rec sqli$_sess_parameter%ROWTYPE;
    par_rec sqli$_parameter%ROWTYPE;
  BEGIN
    BEGIN
      SELECT * INTO par_sess_rec FROM sqli$_sess_parameter WHERE name = LOWER(p_name);
      IF USER NOT IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') AND par_sess_rec.is_hidden = 'Y' THEN
        RAISE_APPLICATION_ERROR (-20315, 'Parameter not found: '||p_name, TRUE);
      ELSE
        RETURN par_sess_rec.value;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;

    BEGIN
      SELECT * INTO par_rec FROM sqli$_parameter WHERE name = LOWER(p_name);
      IF USER NOT IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') AND par_rec.is_hidden = 'Y' THEN
        RAISE_APPLICATION_ERROR (-20313, 'Parameter not found: '||p_name, TRUE);
      ELSE
        RETURN par_rec.value;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR (-20312, 'Parameter not found: '||p_name, TRUE);
    END;
  END get_param;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_param_n
   *
   * ------------------------- */
  FUNCTION get_param_n (p_name IN VARCHAR2)
  RETURN NUMBER
  IS
  BEGIN
    RETURN TO_NUMBER(get_param(p_name));
  END get_param_n;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_sess_param
   *
   * ------------------------- */
  PROCEDURE set_sess_param (
    p_name  IN VARCHAR2,
    p_value IN VARCHAR2 )
  IS
    par_sess_rec sqli$_sess_parameter%ROWTYPE;
    my_value sqli$_sess_parameter.value%TYPE := NULL;
    l_count NUMBER;
  BEGIN
    IF p_value IS NULL AND LOWER(p_name) NOT IN ('connect_identifier', 'skip_metadata_for_object', 'traces_directory_path') THEN
      RETURN;
    END IF;

    SELECT COUNT(*)
      INTO l_count
      FROM sqli$_sess_parameter;

    IF l_count = 0 THEN
      INSERT INTO sqli$_sess_parameter
      SELECT * FROM sqli$_parameter;
      COMMIT;
    END IF;

    BEGIN
      SELECT * INTO par_sess_rec FROM sqli$_sess_parameter WHERE name = LOWER(p_name);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR (-20312, 'Parameter not found: '||p_name, TRUE);
    END;

    IF NVL(UPPER(p_value), '-666') = NVL(par_sess_rec.value, '-666') THEN
      RETURN;
    END IF;

    IF USER NOT IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') AND par_sess_rec.is_hidden = 'Y' THEN
      RAISE_APPLICATION_ERROR (-20313, 'Parameter not found: '||p_name, TRUE);
    END IF;

    IF USER NOT IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') AND par_sess_rec.is_usr_modifiable = 'N' THEN
      RAISE_APPLICATION_ERROR (-20314, 'Parameter cannot be modified: '||p_name, TRUE);
    END IF;

    IF LOWER(p_name) = 'connect_identifier' AND NVL(p_value, '@') NOT LIKE '@%' THEN
      RAISE_APPLICATION_ERROR (-20314, 'Value must start with "@": '||p_value, TRUE);
    END IF;

    my_value := NULL;
    IF par_sess_rec.type = 'N' THEN
      IF par_sess_rec.low_value IS NOT NULL AND par_sess_rec.high_value IS NOT NULL THEN
        IF TO_NUMBER(p_value) BETWEEN par_sess_rec.low_value AND par_sess_rec.high_value THEN
          my_value := p_value;
        ELSE
          RAISE_APPLICATION_ERROR (-20317, 'Value '||p_value||' must be between '||par_sess_rec.low_value||' and '||par_sess_rec.high_value, TRUE);
        END IF;
      ELSIF par_sess_rec.is_hidden = 'Y' AND USER IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') THEN
        my_value := p_value;
      END IF;
    ELSIF par_sess_rec.type = 'C' THEN
      IF LOWER(p_name) = 'connect_identifier' THEN
        my_value := UPPER(p_value);
      ELSIF LOWER(p_name) IN ('skip_metadata_for_object', 'traces_directory_path') THEN
        my_value := p_value;
      ELSIF par_sess_rec.value1 IS NOT NULL AND par_sess_rec.value2 IS NOT NULL THEN
        IF UPPER(p_value) IN (par_sess_rec.value1, par_sess_rec.value2, par_sess_rec.value3, par_sess_rec.value4, par_sess_rec.value5) THEN
          my_value := UPPER(p_value);
        ELSE
          RAISE_APPLICATION_ERROR (-20318, TRIM('Value '||p_value||' not in list: '||par_sess_rec.value1||' '||par_sess_rec.value2||' '||par_sess_rec.value3||' '||par_sess_rec.value4||' '||par_sess_rec.value4), TRUE);
        END IF;
      ELSIF par_sess_rec.is_hidden = 'Y' AND USER IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') THEN
        my_value := UPPER(p_value);
      END IF;
    END IF;

    IF my_value IS NOT NULL OR LOWER(p_name) IN ('connect_identifier', 'skip_metadata_for_object', 'traces_directory_path') THEN
      UPDATE sqli$_sess_parameter
         SET value = my_value,
             is_default = CASE WHEN NVL(my_value, '-666') = NVL(par_sess_rec.default_value, '-666') THEN 'Y' ELSE 'N' END
       WHERE name = LOWER(p_name);
      COMMIT;
    END IF;
  END set_sess_param;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_param
   *
   * ------------------------- */
  PROCEDURE set_param (
    p_name  IN VARCHAR2,
    p_value IN VARCHAR2 )
  IS
    par_rec sqli$_parameter%ROWTYPE;
    my_value sqli$_parameter.value%TYPE := NULL;
  BEGIN
    IF p_value IS NULL AND LOWER(p_name) NOT IN ('connect_identifier', 'skip_metadata_for_object', 'traces_directory_path') THEN
      RETURN;
    END IF;

    BEGIN
      SELECT * INTO par_rec FROM sqli$_parameter WHERE name = LOWER(p_name);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR (-20312, 'Parameter not found: '||p_name, TRUE);
    END;

    IF NVL(UPPER(p_value), '-666') = NVL(par_rec.value, '-666') THEN
      RETURN;
    END IF;

    IF USER NOT IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') AND par_rec.is_hidden = 'Y' THEN
      RAISE_APPLICATION_ERROR (-20313, 'Parameter not found: '||p_name, TRUE);
    END IF;

    IF USER NOT IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') AND par_rec.is_usr_modifiable = 'N' THEN
      RAISE_APPLICATION_ERROR (-20314, 'Parameter cannot be modified: '||p_name, TRUE);
    END IF;

    IF LOWER(p_name) = 'connect_identifier' AND NVL(p_value, '@') NOT LIKE '@%' THEN
      RAISE_APPLICATION_ERROR (-20314, 'Value must start with "@": '||p_value, TRUE);
    END IF;

    my_value := NULL;
    IF par_rec.type = 'N' THEN
      IF par_rec.low_value IS NOT NULL AND par_rec.high_value IS NOT NULL THEN
        IF TO_NUMBER(p_value) BETWEEN par_rec.low_value AND par_rec.high_value THEN
          my_value := p_value;
        ELSE
          RAISE_APPLICATION_ERROR (-20317, 'Value '||p_value||' must be between '||par_rec.low_value||' and '||par_rec.high_value, TRUE);
        END IF;
      ELSIF par_rec.is_hidden = 'Y' AND USER IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') THEN
        my_value := p_value;
      END IF;
    ELSIF par_rec.type = 'C' THEN
      IF LOWER(p_name) = 'connect_identifier' THEN
        my_value := UPPER(p_value);
      ELSIF LOWER(p_name) IN ('skip_metadata_for_object', 'traces_directory_path') THEN
        my_value := p_value;
      ELSIF par_rec.value1 IS NOT NULL AND par_rec.value2 IS NOT NULL THEN
        IF UPPER(p_value) IN (par_rec.value1, par_rec.value2, par_rec.value3, par_rec.value4, par_rec.value5) THEN
          my_value := UPPER(p_value);
        ELSE
          RAISE_APPLICATION_ERROR (-20318, TRIM('Value '||p_value||' not in list: '||par_rec.value1||' '||par_rec.value2||' '||par_rec.value3||' '||par_rec.value4||' '||par_rec.value4), TRUE);
        END IF;
      ELSIF par_rec.is_hidden = 'Y' AND USER IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') THEN
        my_value := UPPER(p_value);
      END IF;
    END IF;

    IF my_value IS NOT NULL OR LOWER(p_name) IN ('connect_identifier', 'skip_metadata_for_object', 'traces_directory_path') THEN
      UPDATE sqli$_parameter
         SET value = my_value,
             is_default = CASE WHEN NVL(my_value, '-666') = NVL(par_rec.default_value, '-666') THEN 'Y' ELSE 'N' END
       WHERE name = LOWER(p_name);
      COMMIT;
      set_sess_param(p_name, p_value);
    END IF;
  END set_param;

  /*************************************************************************************/

  /* -------------------------
   *
   * public reset_init_parameters
   *
   * siebel sets these parameters to non-default values
   *
   * called by: sqlt$d.collect_gv$parameter_cbo
   *
   * ------------------------- */
  PROCEDURE reset_init_parameters (p_statement_id IN NUMBER)
  IS
    l_value VARCHAR2(32767);
  BEGIN
    write_log('-> reset_init_parameters');

    s_optimizer_mode := NULL;
    s_optimizer_index_cost_adj := NULL;
    s_optimizer_dynamic_sampling := NULL;
    s_hash_join_enabled := NULL;
    s_sortmerge_join_enabled := NULL;

    l_value := UPPER(get_v$parameter_cbo(p_name => 'optimizer_mode', p_statement_id => p_statement_id));
    IF l_value <> 'ALL_ROWS' THEN
      s_optimizer_mode := l_value;
      write_log('optimizer_mode was "'||l_value||'"');
      execute_immediate('ALTER SESSION SET optimizer_mode = ALL_ROWS');
    END IF;

    l_value := UPPER(get_v$parameter_cbo(p_name => 'optimizer_index_cost_adj', p_statement_id => p_statement_id));
    IF l_value <> '100' THEN
      s_optimizer_index_cost_adj := l_value;
      write_log('optimizer_index_cost_adj was "'||l_value||'"');
      execute_immediate('ALTER SESSION SET optimizer_index_cost_adj = 100');
    END IF;

    l_value := UPPER(get_v$parameter_cbo(p_name => 'optimizer_dynamic_sampling', p_statement_id => p_statement_id));
    IF l_value <> '2' THEN
      s_optimizer_dynamic_sampling := l_value;
      write_log('optimizer_dynamic_sampling was "'||l_value||'"');
      execute_immediate('ALTER SESSION SET optimizer_dynamic_sampling = 2');
    END IF;

    l_value := UPPER(get_v$parameter_cbo(p_name => '_hash_join_enabled', p_statement_id => p_statement_id));
    IF l_value <> 'TRUE' THEN
      s_hash_join_enabled := l_value;
      write_log('_hash_join_enabled was "'||l_value||'"');
      execute_immediate('ALTER SESSION SET "_hash_join_enabled" = TRUE');
    END IF;

    l_value := UPPER(get_v$parameter_cbo(p_name => '_optimizer_sortmerge_join_enabled', p_statement_id => p_statement_id));
    IF l_value <> 'TRUE' THEN
      s_sortmerge_join_enabled := l_value;
      write_log('_optimizer_sortmerge_join_enabled was "'||l_value||'"');
      execute_immediate('ALTER SESSION SET "_optimizer_sortmerge_join_enabled" = TRUE');
    END IF;

    write_log('<- reset_init_parameters');
  END reset_init_parameters;

  /*************************************************************************************/

  /* -------------------------
   *
   * public restore_init_parameters
   *
   * siebel sets these parameters to non-default values
   *
   * called by: sqlt$a.set_end_date
   * 22170172 add DBMS_ASSERT
   * ------------------------- */
  PROCEDURE restore_init_parameters
  IS
  BEGIN
    write_log('-> restore_init_parameters');

    IF s_optimizer_mode IS NOT NULL THEN
      write_log('optimizer_mode restored to "'||s_optimizer_mode||'"');
      execute_immediate('ALTER SESSION SET optimizer_mode = '||DBMS_ASSERT.ENQUOTE_LITERAL(s_optimizer_mode)); 
    END IF;

    IF s_optimizer_index_cost_adj IS NOT NULL THEN
      write_log('optimizer_index_cost_adj restored to "'||s_optimizer_index_cost_adj||'"');
      execute_immediate('ALTER SESSION SET optimizer_index_cost_adj = '||to_char(to_number(s_optimizer_index_cost_adj)));
    END IF;

    IF s_optimizer_dynamic_sampling IS NOT NULL THEN
      write_log('optimizer_dynamic_sampling restored to "'||s_optimizer_dynamic_sampling||'"');
      execute_immediate('ALTER SESSION SET optimizer_dynamic_sampling = '||to_char(to_number(s_optimizer_dynamic_sampling)));
    END IF;

    IF s_hash_join_enabled IS NOT NULL THEN
      write_log('_hash_join_enabled restored to "'||s_hash_join_enabled||'"');
      execute_immediate('ALTER SESSION SET "_hash_join_enabled" = '||DBMS_ASSERT.ENQUOTE_LITERAL(s_hash_join_enabled));
    END IF;

    IF s_sortmerge_join_enabled IS NOT NULL THEN
      write_log('_optimizer_sortmerge_join_enabled restored to "'||s_sortmerge_join_enabled||'"');
      execute_immediate('ALTER SESSION SET "_optimizer_sortmerge_join_enabled" = '||DBMS_ASSERT.ENQUOTE_LITERAL(s_sortmerge_join_enabled));
    END IF;

    write_log('<- restore_init_parameters');
  END restore_init_parameters;

  /*************************************************************************************/

  /* -------------------------
   *
   * public reset_directories
   *
   * called from sqlt/install/sqcreate, sqlt$e.xtract_sql_put_files_in_repo and sqlt main methods
   *
   * ------------------------- */
  PROCEDURE reset_directories
  IS
  BEGIN
    IF get_param('refresh_directories') = 'Y' THEN
      EXECUTE IMMEDIATE 'BEGIN sys.sqlt$_trca$_dir_set; END;';
    END IF;
  END reset_directories;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_pack_access
   *
   * ------------------------- */
  FUNCTION get_pack_access
  RETURN VARCHAR2
  IS
  BEGIN
    IF get_param('automatic_workload_repository') = 'Y'
    THEN
      IF get_param('sql_tuning_advisor')          = 'Y' AND
         get_param('sql_monitoring')              = 'Y' AND
         get_param('sql_tuning_set')              = 'Y'
      THEN
         RETURN 'T'; -- Tuning Pack
      ELSE
         RETURN 'D'; -- Diagnostics Pack
      END IF;
    ELSE
      RETURN 'N'; -- None
    END IF;
  END get_pack_access;

  /*************************************************************************************/

  /* -------------------------
   *
   * public disable_tuning_pack_access
   *
   * ------------------------- */
  PROCEDURE disable_tuning_pack_access
  IS
  BEGIN
    set_param('sql_tuning_advisor', 'N');
    set_param('sql_monitoring', 'N');
    set_param('sql_tuning_set', 'N');
  END disable_tuning_pack_access;

  /*************************************************************************************/

  /* -------------------------
   *
   * public enable_tuning_pack_access
   *
   * ------------------------- */
  PROCEDURE enable_tuning_pack_access
  IS
  BEGIN
    set_param('sql_tuning_advisor', 'Y');
    set_param('sql_monitoring', 'Y');
    set_param('sql_tuning_set', 'Y');
    set_param('automatic_workload_repository', 'Y');
  END enable_tuning_pack_access;

  /*************************************************************************************/

  /* -------------------------
   *
   * public disable_diagnostic_pack_access
   *
   * ------------------------- */
  PROCEDURE disable_diagnostic_pack_access
  IS
  BEGIN
    set_param('sql_tuning_advisor', 'N');
    set_param('sql_monitoring', 'N');
    set_param('sql_tuning_set', 'N');
    set_param('automatic_workload_repository', 'N');
  END disable_diagnostic_pack_access;

  /*************************************************************************************/

  /* -------------------------
   *
   * public enable_diagnostic_pack_access
   *
   * ------------------------- */
  PROCEDURE enable_diagnostic_pack_access
  IS
  BEGIN
    set_param('automatic_workload_repository', 'Y');
  END enable_diagnostic_pack_access;

  /*************************************************************************************/

  /* -------------------------
   *
   * public is_user_in_role
   *
   * called by validate_user and create_statement_workspace
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
    WHEN OTHERS THEN
      put_line(SQLERRM);
      put_line('calling sqlt$a.is_user_in_role with user "'||p_user||'" and role "'||p_granted_role||'"');
      RETURN NULL;
  END is_user_in_role;

  /*************************************************************************************/

  /* -------------------------
   *
   * public validate_user
   *
   * called by sqlt$i.common_begin, sqlt$c.compare_report, sqlt/utl/sqltprofile.sql and sqlt/utl/sqltimp.sql
   *
   * ------------------------- */
  PROCEDURE validate_user (p_user IN VARCHAR2 DEFAULT USER)
  IS
  BEGIN
    IF get_param('validate_user') = 'Y' THEN
      IF p_user IN (TOOL_ADMINISTER_SCHEMA, 'SYS', 'SYSTEM') OR is_user_in_role(ROLE_NAME, p_user) = 'YES' OR is_user_in_role('DBA', p_user) = 'YES' THEN
        RETURN;
      ELSE
        RAISE_APPLICATION_ERROR (-20326, 'User "'||p_user||'" lacks "'||ROLE_NAME||'" or "DBA" roles. GRANT "'||ROLE_NAME||'" to "'||p_user||'".', TRUE);
      END IF;
    END IF;
  END validate_user;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_filename_with_output
   *
   * inputs: input/sample/script2.sql
   * outputs script2_output.txt
   *
   * called by sqlt/run/sqltxecute.sql, sqlt/run/sqltxtrxec.sql and sqlt$r.script_output_driver
   *
   * ------------------------- */
  FUNCTION get_filename_with_output (
    p_statement_id    IN NUMBER,
    p_script_with_sql IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_slash NUMBER;
    l_period NUMBER;
  BEGIN
    l_slash := GREATEST(INSTR('/'||p_script_with_sql, '/', -1), INSTR('\'||p_script_with_sql, '\', -1));
    l_period := INSTR('/'||p_script_with_sql||'.', '.', l_slash);
    RETURN SUBSTR('/'||p_script_with_sql||'.', l_slash + 1, l_period - l_slash - 1)||'_output_s'||get_statement_id_c(p_statement_id)||'.txt';
  END get_filename_with_output;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_statement_id
   *
   * ------------------------- */
  FUNCTION get_statement_id
  RETURN NUMBER
  IS
    l_count NUMBER;
  BEGIN
    SELECT sqlt$_sql_statement_id_s.NEXTVAL INTO s_log_statement_id FROM DUAL;
    SELECT COUNT(*) INTO l_count FROM sqlt$_sql_statement WHERE statement_id = s_log_statement_id;
    IF l_count > 0 THEN
      RETURN get_statement_id; -- recursive call in case there is a collision (sequence was recreated for example)
    ELSE
      s_log_statid := get_statid(s_log_statement_id);
      RETURN s_log_statement_id;
    END IF;
  END get_statement_id;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_statement_id_c
   *
   * ------------------------- */
  FUNCTION get_statement_id_c (p_statement_id IN NUMBER DEFAULT NULL)
  RETURN VARCHAR2
  IS
    l_statement_id NUMBER;
  BEGIN
    l_statement_id := p_statement_id;
    IF l_statement_id IS NULL THEN
      l_statement_id := get_statement_id;
    END IF;
    RETURN LPAD(l_statement_id, 5, '0');
  END get_statement_id_c;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_statid
   *
   * ------------------------- */
  FUNCTION get_statid (p_statement_id IN NUMBER)
  RETURN VARCHAR2
  IS
    l_statid VARCHAR2(257);
  BEGIN
    l_statid := 's'||get_statement_id_c(p_statement_id)||'_'||LOWER(SUBSTR(get_database_name_short, 1, 9))||'_';
    l_statid := l_statid||LOWER(SUBSTR(get_host_name_short, 1, 30 - LENGTH(l_statid)));
    RETURN l_statid;
  END get_statid;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_statement
   *
   * ------------------------- */
  FUNCTION get_statement (p_statement_id IN NUMBER)
  RETURN sqlt$_sql_statement%ROWTYPE
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
  BEGIN
    SELECT * INTO sql_rec FROM sqlt$_sql_statement WHERE statement_id = p_statement_id;
    RETURN sql_rec;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20304, 'statement with unique id "'||p_statement_id||'" could not be retrieved. '||SQLERRM, TRUE);
  END get_statement;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_directory_path
   *
   * ------------------------- */
  FUNCTION get_directory_path (p_directory_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
    dir_rec sys.dba_directories%ROWTYPE;
  BEGIN
    -- 150826 result_cache and rownum
    SELECT /*+ result_cache */*
      INTO dir_rec
      FROM sys.dba_directories
     WHERE directory_name = UPPER(TRIM(p_directory_name))
	   and rownum=1;

    RETURN dir_rec.directory_path;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20320, 'directory path for "'||UPPER(TRIM(p_directory_name))||'" could not be retrieved. '||SQLERRM, TRUE);
  END get_directory_path;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_directory_full_path
   *
   * ------------------------- */
  FUNCTION get_directory_full_path (p_directory_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
    l_directory_path sys.dba_directories.directory_path%TYPE;
  BEGIN
    -- 150826 remove extra logic for UDUMP/BDUMP. Just add the last dir divider

    l_directory_path := get_directory_path(p_directory_name);

    IF INSTR(l_directory_path, '\') > 0 THEN
      RETURN l_directory_path||'\';
    ELSE
      RETURN l_directory_path||'/';
    END IF;
  END get_directory_full_path;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_udump_path
   *
   * ------------------------- */
  FUNCTION get_udump_path
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN get_directory_path('SQLT$UDUMP');
  END get_udump_path;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_udump_full_path
   *
   * ------------------------- */
  FUNCTION get_udump_full_path
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN get_directory_full_path('SQLT$UDUMP');
  END get_udump_full_path;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_bdump_path
   *
   * ------------------------- */
  FUNCTION get_bdump_path
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN get_directory_path('SQLT$BDUMP');
  END get_bdump_path;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_bdump_full_path
   *
   * ------------------------- */
  FUNCTION get_bdump_full_path
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN get_directory_full_path('SQLT$BDUMP');
  END get_bdump_full_path;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_stage_path
   *
   * ------------------------- */
  FUNCTION get_stage_path
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN get_directory_path('SQLT$STAGE');
  END get_stage_path;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_stage_full_path
   *
   * ------------------------- */
  FUNCTION get_stage_full_path
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN get_directory_full_path('SQLT$STAGE');
  END get_stage_full_path;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_diag_path
   * 150826 new
   * ------------------------- */
  FUNCTION get_diag_path
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN get_directory_path('SQLT$DIAG');
  END get_diag_path;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_diag_full_path
   * 150826 new
   * ------------------------- */
  FUNCTION get_diag_full_path
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN get_directory_full_path('SQLT$DIAG');
  END get_diag_full_path;

  /*************************************************************************************/

  /* -------------------------
   * 
   * public get_user_dump_dest_path
   * 150826 removed
   * ------------------------- */
  
  /*************************************************************************************/

  /* -------------------------
   *
   * public get_background_dump_dest_path
   * 150826 removed
   * ------------------------- */

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_object_id
   *
   * ------------------------- */
  FUNCTION get_object_id (
    p_statement_id   IN NUMBER,
    p_object_type    IN VARCHAR2,
    p_owner          IN VARCHAR2,
    p_object_name    IN VARCHAR2,
    p_subobject_name IN VARCHAR2 DEFAULT NULL )
  RETURN NUMBER
  IS
    l_object_id NUMBER;
  BEGIN
    IF p_statement_id IS NULL OR
       p_object_type IS NULL OR
       p_owner IS NULL OR
       p_object_name IS NULL
    THEN
      RETURN NULL;
    END IF;

    SELECT object_id
      INTO l_object_id
      FROM sqlt$_dba_objects
     WHERE statement_id = p_statement_id
       AND object_type = p_object_type
       AND owner = p_owner
       AND object_name = p_object_name
       AND NVL(subobject_name, '-666') = NVL(p_subobject_name, '-666')
       AND ROWNUM = 1;

    RETURN l_object_id;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_object_id;
  
  /*************************************************************************************/

  /* -------------------------
   *
   * public get_owner_id
   *
   * ------------------------- */
  FUNCTION get_owner_id (
    p_statement_id   IN NUMBER,
    p_object_type    IN VARCHAR2,
    p_owner          IN VARCHAR2,
    p_object_name    IN VARCHAR2 )
  RETURN NUMBER
  IS
    l_owner_id NUMBER;
  BEGIN
    IF p_statement_id IS NULL OR
       p_object_type IS NULL OR
       p_owner IS NULL OR
       p_object_name IS NULL
    THEN
      RETURN NULL;
    END IF;

    SELECT owner_id
      INTO l_owner_id
      FROM sys.sqlt$_col$_v v
     WHERE v.owner = p_owner
       AND v.table_name = p_object_name
       AND ROWNUM = 1;

    RETURN l_owner_id;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_owner_id;  

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_table
   *
   * ------------------------- */
  PROCEDURE get_table (
    p_statement_id IN  NUMBER,
    p_index_owner  IN  VARCHAR2,
    p_index_name   IN  VARCHAR2,
    x_table_owner  OUT VARCHAR2,
    x_table_name   OUT VARCHAR2,
    x_object_id    OUT NUMBER )
  IS
  BEGIN
    IF p_statement_id IS NULL OR
       p_index_owner IS NULL OR
       p_index_name IS NULL
    THEN
      RETURN;
    END IF;

    SELECT table_owner, table_name
      INTO x_table_owner, x_table_name
      FROM sqlt$_dba_indexes
     WHERE statement_id = p_statement_id
       AND owner = p_index_owner
       AND index_name = p_index_name
       AND ROWNUM = 1;

    x_object_id := get_object_id(p_statement_id, 'TABLE', x_table_owner, x_table_name);
  EXCEPTION
    WHEN OTHERS THEN
      RETURN;
  END get_table;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_dba_object_id
   *
   * ------------------------- */
  FUNCTION get_dba_object_id (
    p_object_type    IN VARCHAR2,
    p_owner          IN VARCHAR2,
    p_object_name    IN VARCHAR2,
    p_subobject_name IN VARCHAR2 DEFAULT NULL )
  RETURN NUMBER
  IS
    l_object_id NUMBER;
  BEGIN
    IF p_object_type IS NULL OR
       p_owner IS NULL OR
       p_object_name IS NULL
    THEN
      RETURN NULL;
    END IF;

    SELECT object_id
      INTO l_object_id
      FROM sys.dba_objects
     WHERE object_type = p_object_type
       AND owner = p_owner
       AND object_name = p_object_name
       AND NVL(subobject_name, '-666') = NVL(p_subobject_name, '-666')
       AND ROWNUM = 1;

    RETURN l_object_id;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_dba_object_id;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_met_object_id
   *
   * ------------------------- */
  FUNCTION get_met_object_id (
    p_statement_id   IN NUMBER,
    p_object_type    IN VARCHAR2,
    p_owner          IN VARCHAR2,
    p_object_name    IN VARCHAR2 )
  RETURN NUMBER
  IS
    l_object_id NUMBER;
  BEGIN
    SELECT object_id
      INTO l_object_id
      FROM sqlt$_metadata
     WHERE statement_id = p_statement_id
       AND object_type = p_object_type
       AND owner = p_owner
       AND object_name = p_object_name
       AND transformed = 'N'
       AND ROWNUM = 1;

    RETURN l_object_id;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_met_object_id;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_internal_column_id
   *
   * ------------------------- */
  FUNCTION get_internal_column_id (
    p_owner              IN VARCHAR2,
    p_table_name         IN VARCHAR2,
    p_column_name        IN VARCHAR2,
    p_internal_column_id IN NUMBER )
  RETURN NUMBER
  IS
    l_internal_column_id NUMBER;
  BEGIN
    IF p_owner IS NULL OR
       p_table_name IS NULL OR
       p_column_name IS NULL OR
       p_internal_column_id IS NULL
    THEN
      RETURN NULL;
    END IF;

    SELECT internal_column_id
      INTO l_internal_column_id
      FROM sys.dba_tab_cols
     WHERE owner = p_owner
       AND table_name = p_table_name
       AND column_name = p_column_name
       AND ROWNUM = 1;

    RETURN l_internal_column_id;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_internal_column_id;
  END get_internal_column_id;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_index_column_count
   *
   * ------------------------- */
  FUNCTION get_index_column_count (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2 )
  RETURN NUMBER
  IS
    l_count NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM sqlt$_dba_ind_columns
     WHERE statement_id = p_statement_id
       AND index_owner = p_index_owner
       AND index_name = p_index_name;

    RETURN l_count;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_index_column_count;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_index_column_ids
   *
   * ------------------------- */
  FUNCTION get_index_column_ids (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2,
    p_separator    IN VARCHAR2 DEFAULT ' ',
    p_pad_char     IN VARCHAR2 DEFAULT ' ' )
  RETURN VARCHAR2
  IS
    l_len NUMBER;
    l_return VARCHAR2(32767) := NULL;
  BEGIN
    SELECT LENGTH(MAX(t.column_id))
      INTO l_len
      FROM sqlt$_dba_indexes x,
           sqlt$_dba_all_table_cols_v t
     WHERE x.statement_id = p_statement_id
       AND x.owner = p_index_owner
       AND x.index_name = p_index_name
       AND x.statement_id = t.statement_id
       AND x.table_owner = t.owner
       AND x.table_name = t.table_name;

    FOR i IN (SELECT NVL(t.column_id, t.internal_column_id) column_id
                FROM sqlt$_dba_ind_columns x,
                     sqlt$_dba_all_table_cols_v t
               WHERE x.statement_id = p_statement_id
                 AND x.index_owner = p_index_owner
                 AND x.index_name = p_index_name
                 AND x.statement_id = t.statement_id
                 AND x.table_owner = t.owner
                 AND x.table_name = t.table_name
                 AND x.column_name = t.column_name
               ORDER BY
                     x.column_position)
    LOOP
      IF l_return IS NULL THEN
        l_return := LPAD(i.column_id, l_len, p_pad_char);
      ELSE
        l_return := l_return||p_separator||LPAD(i.column_id, l_len, p_pad_char);
      END IF;
    END LOOP;

    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN SQLERRM;
  END get_index_column_ids;

  /*************************************************************************************/

  /* -------------------------
   *
   * private remap_owner
   *
   * ------------------------- */
  FUNCTION remap_owner (
    p_string IN VARCHAR2,
    p_prefix IN VARCHAR2,
    p_owner  IN VARCHAR2,
    p_suffix IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN REPLACE(p_string, p_prefix||p_owner||p_suffix, p_prefix||'OWNER'||p_suffix);
  END remap_owner;

  /*************************************************************************************/

  /* -------------------------
   *
   * private remap_owner
   *
   * ------------------------- */
  FUNCTION remap_owner (
    p_string IN VARCHAR2,
    p_owner  IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_string VARCHAR2(32767) := p_string;
  BEGIN
    l_string := remap_owner(l_string, ' "', p_owner, '"."');
    l_string := remap_owner(l_string, ' ', p_owner, '.');
    l_string := remap_owner(l_string, ' ', LOWER(p_owner), '.');

    l_string := remap_owner(l_string, ',"', p_owner, '"."');
    l_string := remap_owner(l_string, ',', p_owner, '.');
    l_string := remap_owner(l_string, ',', LOWER(p_owner), '.');

    l_string := remap_owner(l_string, '("', p_owner, '"."');
    l_string := remap_owner(l_string, '(', p_owner, '.');
    l_string := remap_owner(l_string, '(', LOWER(p_owner), '.');

    l_string := remap_owner(l_string, LF||'"', p_owner, '"."');
    l_string := remap_owner(l_string, LF, p_owner, '.');
    l_string := remap_owner(l_string, LF, LOWER(p_owner), '.');

    l_string := remap_owner(l_string, '"', p_owner, '"."');
    --l_string := remap_owner(l_string, '', p_owner, '.');
    --l_string := remap_owner(l_string, '', LOWER(p_owner), '.');
    RETURN l_string;
  END remap_owner;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_target_column_name
   *
   * inputs source index_name
   * outputs target index_name
   *
   * ------------------------- */  
  FUNCTION get_target_iot_index_name (
    p_statement_id       IN NUMBER,
    p_target_owner       IN VARCHAR2,
    p_index_name         IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    source_indexes          sqlt$_dba_indexes%ROWTYPE;
    target_index_name       VARCHAR2(257);
    l_count                 NUMBER;
  BEGIN
  
  
    -- check if the target table is an IOT and 
    -- grab the info from the source system
    BEGIN
      SELECT *
        INTO source_indexes
        FROM sqlt$_dba_indexes
       WHERE statement_id = p_statement_id
         AND index_name = p_index_name
         AND index_type like 'IOT%'
         AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        put_line(p_index_name||' not an IOT index!');
        RETURN NULL; -- source index not found
    END;

	
    -- now look for the IOT index name using
    -- the table name from the source
    BEGIN
      SELECT index_name
        INTO target_index_name
        FROM dba_indexes
       WHERE owner = p_target_owner
         AND table_name = source_indexes.table_name
         AND index_type like 'IOT%'
         AND ROWNUM = 1;
		 
      RETURN target_index_name;
	  
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        put_line('No match found for '||p_index_name||', maybe not an IOT on target?');
        RETURN NULL; -- target index not found
    END;
	
    RETURN NULL; -- no map
  END get_target_iot_index_name;   
  
  /* -------------------------
   *
   * private get_target_column_name
   *
   * inputs source column_name
   * outputs target column_name
   *
   * ------------------------- */
  FUNCTION get_target_column_name (
    p_statement_id       IN NUMBER,
    p_target_owner       IN VARCHAR2,
    p_table_name         IN VARCHAR2,
    p_source_column_name IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    source_tables           sqlt$_dba_tables%ROWTYPE;
    source_stat_extensions  sqlt$_dba_stat_extensions%ROWTYPE;
    source_tab_cols         sqlt$_dba_tab_cols%ROWTYPE;
    source_data_default     VARCHAR2(32767);
    target_data_default     VARCHAR2(32767);
    source_data_default_org VARCHAR2(32767);
    target_data_default_org VARCHAR2(32767);
    target_column_name      VARCHAR2(257);
    l_count                 NUMBER;
  BEGIN
    -- get source table details
    BEGIN
      SELECT *
        INTO source_tables
        FROM sqlt$_dba_tables
       WHERE statement_id = p_statement_id
         AND table_name = p_table_name
         AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        put_line(p_table_name||'.'||p_source_column_name||' source table not found!');
        RETURN NULL; -- source table not found
    END;

    -- get source column details
    BEGIN
      SELECT *
        INTO source_tab_cols
        FROM sqlt$_dba_tab_cols
       WHERE statement_id = p_statement_id
         AND owner = source_tables.owner
         AND table_name = p_table_name
         AND column_name = p_source_column_name;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        put_line(p_table_name||'.'||p_source_column_name||' source column not found!');
        RETURN NULL; -- source column not found
    END;

    -- regular columns + SYS_STU% + SYS_STS%
    IF source_tab_cols.column_name NOT LIKE 'SYS_NC%$' THEN
      -- SEARCH TARGET for SOURCE.column_name = TARGET.column_name
      SELECT COUNT(*)
        INTO l_count
        FROM sys.dba_tab_cols
       WHERE owner = p_target_owner
         AND table_name = p_table_name
         AND column_name = p_source_column_name;

      IF l_count > 0 THEN
        RETURN p_source_column_name; -- regular column was found
      ELSE
        put_line(p_table_name||'.'||p_source_column_name||' regular column does not exist in target!');
        RETURN NULL; -- regular column does not exist in target
      END IF;
    END IF;

    -- reports any column that is not "normal"
    put_line('+-----+');
    put_line('column: '||p_table_name||'.'||p_source_column_name);

    -- SYS_NC%$ by qualified_col_name
    IF source_tab_cols.column_id IS NOT NULL AND source_tab_cols.column_name LIKE 'SYS_NC%$' AND source_tab_cols.qualified_col_name <> source_tab_cols.column_name THEN
      put_line('qualified_col_name:');
      put_line(source_tab_cols.qualified_col_name);

      -- find ONE column in target with same qualified_col_name than source
      l_count := 0;
      FOR i IN (SELECT qualified_col_name, column_name
                  FROM sys.dba_tab_cols
                 WHERE owner = p_target_owner
                   AND table_name = p_table_name
                   AND column_id IS NOT NULL
                   AND column_name LIKE 'SYS_NC%$'
                   AND qualified_col_name <> column_name)
      LOOP
        IF i.qualified_col_name = source_tab_cols.qualified_col_name THEN
          l_count := l_count + 1;
          put_line('target_col('||i.column_name||'):');
          target_column_name := i.column_name;
        END IF;
      END LOOP;

      IF l_count = 1 THEN
        put_line('to be remapped as: '||target_column_name);
        RETURN target_column_name;
      ELSE
        put_line('there are '||l_count||' columns that map to same qualified_col_name');
      END IF;
    END IF;

    -- SYS_NC%$ by data_default
    IF source_tab_cols.column_name LIKE 'SYS_NC%$' AND source_tab_cols.data_default IS NOT NULL THEN
      source_data_default_org := SYS.DBMS_LOB.SUBSTR(source_tab_cols.data_default);
      put_line('source_data_default:');
      put_line(source_data_default_org);
      source_data_default := source_data_default_org;

      -- remove schema owner from source data_default
      FOR i IN (SELECT owner, LENGTH(owner) len
                  FROM sqlt$_dba_objects
                 WHERE statement_id = p_statement_id
                   AND owner IS NOT NULL
                 UNION
                SELECT owner, LENGTH(owner) len
                  FROM sqlt$_dba_constraints
                 WHERE statement_id = p_statement_id
                   AND owner IS NOT NULL
                 UNION
                SELECT r_owner owner, LENGTH(r_owner) len
                  FROM sqlt$_dba_constraints
                 WHERE statement_id = p_statement_id
                   AND r_owner IS NOT NULL
                 UNION
                SELECT owner, LENGTH(owner) len
                  FROM sqlt$_metadata
                 WHERE statement_id = p_statement_id
                   AND owner IS NOT NULL
                 ORDER BY 2 DESC)
      LOOP
        source_data_default := remap_owner(source_data_default, i.owner);
      END LOOP;

      -- possible change due to embedded owner
      IF source_data_default_org <> source_data_default THEN
        put_line(source_data_default);
      END IF;

      -- find ONE column in target with same data_default than source
      l_count := 0;
      FOR i IN (SELECT data_default, column_name
                  FROM sys.dba_tab_cols
                 WHERE owner = p_target_owner
                   AND table_name = p_table_name
                   AND column_name LIKE 'SYS_NC%$'
                   AND data_default IS NOT NULL)
      LOOP
        BEGIN
          target_data_default_org := SUBSTR(i.data_default, 1, 32767);
        EXCEPTION
          WHEN OTHERS THEN
            target_data_default_org := NULL;
        END;

        -- remove schema owner from target data_default
        target_data_default := remap_owner(target_data_default_org, p_target_owner);

        IF target_data_default = source_data_default THEN
          l_count := l_count + 1;
          put_line('target_col('||i.column_name||'):');
          put_line(target_data_default_org);
          IF target_data_default_org <> target_data_default THEN
            put_line(target_data_default);
          END IF;
          target_column_name := i.column_name;
        END IF;
      END LOOP;

      IF l_count = 1 THEN
        put_line('to be remapped as: '||target_column_name);
        RETURN target_column_name;
      ELSE
        put_line('there are '||l_count||' columns that map to same data_default');
      END IF;
    END IF;

    -- all failed
    put_line(p_table_name||'.'||p_source_column_name||' not matched!');
    RETURN NULL; -- no map
  END get_target_column_name;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_index_column_names
   *
   * ------------------------- */
  FUNCTION get_index_column_names (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2,
    p_hidden_names IN VARCHAR2 DEFAULT 'NO',
    p_separator    IN VARCHAR2 DEFAULT ' ',
    p_table_name   IN VARCHAR2 DEFAULT 'NO',
    p_sticky       IN VARCHAR2 DEFAULT 'NO' )
  RETURN VARCHAR2
  IS
    l_column_name VARCHAR2(32767);
    l_return VARCHAR2(32767) := NULL;
    idx_rec sqlt$_dba_indexes%ROWTYPE;
  BEGIN
    BEGIN
      SELECT *
        INTO idx_rec
        FROM sqlt$_dba_indexes
       WHERE statement_id = p_statement_id
         AND owner = p_index_owner
         AND index_name = p_index_name;

       IF p_sticky = 'YES' AND idx_rec.index_column_names IS NOT NULL THEN
         RETURN idx_rec.index_column_names;
       END IF;
     EXCEPTION
       WHEN NO_DATA_FOUND THEN
         RETURN p_index_name; -- needed by sqlt$_dba_ind_statistics_v
     END;

    FOR i IN (SELECT x.table_owner,
                     x.table_name,
                     x.column_name,
                     x.descend,
                     t.hidden_column,
                     r.column_expression,
                     e.extension,
                     t.data_default
                FROM sqlt$_dba_ind_columns x,
                     sqlt$_dba_all_table_cols_v t,
                     sqlt$_dba_ind_expressions r,
                     sqlt$_dba_stat_extensions e
               WHERE x.statement_id = p_statement_id
                 AND x.index_owner = p_index_owner
                 AND x.index_name = p_index_name
                 AND x.statement_id = t.statement_id
                 AND x.table_owner = t.owner
                 AND x.table_name = t.table_name
                 AND x.column_name = t.column_name
                 AND x.statement_id = r.statement_id(+)
                 AND x.table_owner = r.table_owner(+)
                 AND x.table_name = r.table_name(+)
                 AND x.index_owner = r.index_owner(+)
                 AND x.index_name = r.index_name(+)
                 AND x.column_position = r.column_position(+)
                 AND x.statement_id = e.statement_id(+)
                 AND x.table_owner = e.owner(+)
                 AND x.table_name = e.table_name(+)
                 AND x.column_name = e.extension_name(+)
               ORDER BY
                     x.column_position)
    LOOP
      IF p_hidden_names = 'YES' THEN
        IF i.hidden_column = 'YES' THEN
          IF i.column_expression IS NOT NULL THEN
            l_column_name := REPLACE(DBMS_LOB.SUBSTR(i.column_expression), ' ');
          ELSIF i.extension IS NOT NULL THEN
            l_column_name := REPLACE(DBMS_LOB.SUBSTR(i.extension), ' ');
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
        l_return := l_return||p_separator||l_column_name;
      END IF;
    END LOOP;

    IF p_table_name = 'YES' THEN
      l_return := idx_rec.table_name||' ('||l_return||')';
    END IF;

    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN SQLERRM;
  END get_index_column_names;
  
  
  /*************************************************************************************/

  /* -------------------------
   *
   * public get_policy_column_names
   *
   * ------------------------- */
  FUNCTION get_policy_column_names (
    p_statement_id IN NUMBER,
    p_object_owner IN VARCHAR2,
    p_object_name  IN VARCHAR2,
    p_policy_name  IN VARCHAR2, 
    p_separator    IN VARCHAR2 DEFAULT ' ')
  RETURN VARCHAR2
  IS
    l_column_name VARCHAR2(32767);
    l_return VARCHAR2(32767) := NULL;
  BEGIN

    FOR i IN (SELECT t.column_name
                FROM sqlt$_dba_all_table_cols_v t,
                     sqlt$_dba_policies p
               WHERE p.statement_id = p_statement_id
                 AND p.object_owner = p_object_owner
                 AND p.object_name = p_object_name
                 AND p.policy_name = p_policy_name
                 AND p.statement_id = t.statement_id
                 AND p.object_owner = t.owner
                 AND p.object_name = t.table_name
                 AND p.column_id = t.column_id
               ORDER BY t.column_id)
    LOOP

      l_column_name := i.column_name;

      IF l_return IS NULL THEN
        l_return := l_column_name;
      ELSE
        l_return := l_return||p_separator||l_column_name;
      END IF;
	  
    END LOOP;

    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN SQLERRM;
  END get_policy_column_names;  

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_index_column_names
   *
   * ------------------------- */
  PROCEDURE set_index_column_names (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2,
    p_hidden_names IN VARCHAR2 DEFAULT 'NO',
    p_separator    IN VARCHAR2 DEFAULT ' ',
    p_table_name   IN VARCHAR2 DEFAULT 'NO' )
  IS
    l_index_column_names VARCHAR2(32767);
  BEGIN
    l_index_column_names := get_index_column_names (
      p_statement_id => p_statement_id,
      p_index_owner  => p_index_owner,
      p_index_name   => p_index_name,
      p_hidden_names => p_hidden_names,
      p_separator    => p_separator,
      p_table_name   => p_table_name );

    UPDATE sqlt$_dba_indexes
       SET index_column_names = SUBSTR(l_index_column_names, 1, 4000)
     WHERE statement_id = p_statement_id
       AND owner = p_index_owner
       AND index_name = p_index_name;
  END set_index_column_names;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_column_position
   *
   * ------------------------- */
  FUNCTION get_column_position (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2,
    p_column_name  IN VARCHAR2 )
  RETURN NUMBER
  IS
    l_return NUMBER;
  BEGIN
    SELECT column_position
      INTO l_return
      FROM sqlt$_dba_ind_columns
     WHERE statement_id = p_statement_id
       AND index_owner = p_index_owner
       AND index_name = p_index_name
       AND column_name = p_column_name;

     RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_column_position;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_column_count
   *
   * ------------------------- */
  FUNCTION get_column_count (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2 )
  RETURN NUMBER
  IS
    l_return NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO l_return
      FROM sqlt$_dba_ind_columns
     WHERE statement_id = p_statement_id
       AND index_owner = p_index_owner
       AND index_name = p_index_name;

     RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_column_count;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_plan_link
   *
   * ------------------------- */
  FUNCTION get_plan_link (
    p_statement_id    IN NUMBER,
    p_plan_hash_value IN NUMBER )
  RETURN VARCHAR2
  IS
    l_link_id VARCHAR2(32767) := NULL;
  BEGIN
    FOR i IN (SELECT link_id
                FROM sqlt$_plan_header_v
               WHERE statement_id = p_statement_id
                 AND plan_hash_value = p_plan_hash_value
               ORDER BY
                     src_order)
    LOOP
      l_link_id := i.link_id;
      EXIT; -- 1st
    END LOOP;

    RETURN l_link_id;
  END get_plan_link;

  /*************************************************************************************/

  /* -------------------------
   *
   * public remove_piece
   *
   * ------------------------- */
  FUNCTION remove_piece (
    p_string IN VARCHAR2,
    p_begin  IN VARCHAR2,
    p_end    IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_begin INTEGER;
    l_end   INTEGER;
  BEGIN
    l_begin := NVL(INSTR(p_string, p_begin), 0);
    l_end := NVL(INSTR(p_string, p_end, l_begin + 1), 0);
    IF l_begin = 0 OR l_end = 0 THEN
      RETURN p_string;
    ELSE
      RETURN remove_piece(SUBSTR(p_string, 1, l_begin - 1)||SUBSTR(p_string, l_end + 1), p_begin, p_end);
    END IF;
  END remove_piece;

  /*************************************************************************************/

  /* -------------------------
   *
   * public in_multi_column_index
   *
   * ------------------------- */
  FUNCTION in_multi_column_index (
    p_statement_id IN NUMBER,
    p_table_owner  IN VARCHAR2,
    p_table_name   IN VARCHAR2,
    p_column_name  IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_count NUMBER;
  BEGIN
    FOR i IN (SELECT index_owner, index_name
                FROM sqlt$_dba_ind_columns
               WHERE statement_id = p_statement_id
                 AND table_owner = p_table_owner
                 AND table_name = p_table_name
                 AND column_name = p_column_name)
    LOOP
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_ind_columns
       WHERE statement_id = p_statement_id
         AND table_owner = p_table_owner
         AND table_name = p_table_name
         AND index_owner = i.index_owner
         AND index_name = i.index_name;

      IF l_count > 1 THEN
        EXIT;
      END IF;
    END LOOP;

    IF l_count > 1 THEN
      RETURN 'Y';
    ELSE
      RETURN 'N';
    END IF;
  END in_multi_column_index;

  /*************************************************************************************/

  /* -------------------------
   *
   * public validate_tool_version
   *
   * ------------------------- */
  PROCEDURE validate_tool_version (p_script_version IN VARCHAR2)
  IS
  BEGIN /* validate_tool_version */
    IF p_script_version > get_param('tool_version') THEN
      RAISE_APPLICATION_ERROR (-20302, 'Version mismatch: Script('||p_script_version||') > Tool('||get_param('tool_version')||'). To fix this, install and use latest version of this tool.', TRUE);
    END IF;
    write_log('tool version: '||get_param('tool_version'));
    write_log('script version: '||p_script_version);
  END validate_tool_version;

  /*************************************************************************************/

  /* -------------------------
   *
   * public session_trace_filename
   *
   * produces trace filename for current session
   *
   * ------------------------- */
  FUNCTION session_trace_filename (
    p_traceid      IN VARCHAR2 DEFAULT NULL,
    p_spid         IN VARCHAR2 DEFAULT NULL,
    p_process_name IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2
  IS
    i_rec  v$instance%ROWTYPE;
    s_rec  v$session%ROWTYPE;
    p_rec  v$process%ROWTYPE;
    ss_rec v$shared_server%ROWTYPE;

    my_rdbms_release  NUMBER;
    my_traceid        VARCHAR2(32767);
    my_process_name   VARCHAR2(32767);
    my_trace_filename VARCHAR2(32767);
    my_vproc_filename VARCHAR2(32767);

  BEGIN /* session_trace_filename */
    write_log('-> session_trace_filename');

    SELECT *
      INTO i_rec
      FROM v$instance;

    SELECT *
      INTO s_rec
      FROM v$session
     WHERE sid = get_sid;

    SELECT *
      INTO p_rec
      FROM v$process
     WHERE addr = s_rec.paddr
       AND ROWNUM = 1;

    my_rdbms_release := get_rdbms_release;

    IF my_rdbms_release >= 11 THEN
      BEGIN
        EXECUTE IMMEDIATE 'SELECT value FROM v$diag_info WHERE name = ''Default Trace File''' INTO my_trace_filename;
        my_trace_filename := SUBSTR(my_trace_filename, GREATEST(INSTR(my_trace_filename, '/', -1), INSTR(my_trace_filename, '\', -1)) + 1);
        EXECUTE IMMEDIATE 'SELECT tracefile FROM v$process WHERE addr = :addr AND ROWNUM = 1' INTO my_vproc_filename USING s_rec.paddr;
        write_log('session_trace_filename Tracename from v$process: '||my_vproc_filename);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          write_log('session_trace_filename query on v$diag_info failed');
          my_trace_filename := NULL;
      END;

      IF my_trace_filename IS NOT NULL AND p_traceid IS NOT NULL AND INSTR(my_trace_filename, p_traceid) = 0 THEN
        my_trace_filename := REPLACE(my_trace_filename, p_rec.traceid, p_traceid);
      END IF;
    ELSE
      my_trace_filename := NULL;
    END IF;
    write_log('session_trace_filename, current trace_filename '||my_trace_filename);

    IF s_rec.server = 'DEDICATED' THEN
      my_process_name := 'ora';
    ELSIF s_rec.server = 'SHARED' THEN
      BEGIN
        SELECT *
          INTO ss_rec
          FROM v$shared_server
         WHERE paddr = s_rec.paddr;

        my_process_name := ss_rec.name;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          my_process_name := 'ora';
      END;
    ELSE
      my_process_name := NULL;
    END IF;
    write_log('session_trace_filename, current process_name '||my_process_name);

    IF my_rdbms_release < 11 OR my_trace_filename IS NULL THEN
      my_traceid := NVL(p_traceid, p_rec.traceid);
      IF my_traceid IS NOT NULL THEN
        my_traceid := '_'||my_traceid;
      END IF;

      IF my_process_name IS NOT NULL THEN
        IF my_rdbms_release < 11 THEN
          my_trace_filename := LOWER(i_rec.instance_name)||'_'||LOWER(my_process_name);
        ELSE
          my_trace_filename := i_rec.instance_name||'_'||my_process_name;
        END IF;

        my_trace_filename := my_trace_filename||'_'||p_rec.spid||my_traceid||'.trc';
      ELSE
        my_trace_filename := NULL;
      END IF;
    END IF;

    IF p_spid IS NOT NULL THEN
      my_trace_filename := REPLACE(my_trace_filename, '_', '*');
      my_trace_filename := REPLACE(my_trace_filename, '*'||p_rec.spid||'*', '*'||p_spid||'*');
      my_trace_filename := REPLACE(my_trace_filename, '*', '_');
    END IF;

    IF p_process_name IS NOT NULL THEN
      my_trace_filename := REPLACE(my_trace_filename, '_', '*');
      my_trace_filename := REPLACE(my_trace_filename, '*'||my_process_name||'*', '*'||p_process_name||'*');
      my_trace_filename := REPLACE(my_trace_filename, '*', '_');
    END IF;

    write_log('<- session_trace_filename '||my_trace_filename);
    RETURN my_trace_filename;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN NULL;
    WHEN OTHERS THEN
      RETURN SQLERRM;
  END session_trace_filename;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_file
   *
   * called by: reports, upload_trace and execute_tuning_task
   *
   * ------------------------- */
  PROCEDURE set_file (
    p_statement_id  IN NUMBER,
    p_file_type     IN VARCHAR2,
    p_filename      IN VARCHAR2,
    p_username      IN VARCHAR2 DEFAULT USER,
    p_statid        IN VARCHAR2 DEFAULT NULL,
    p_statement_id2 IN NUMBER   DEFAULT NULL,
    p_file_date     IN DATE     DEFAULT SYSDATE,
    p_file_size     IN NUMBER   DEFAULT NULL,
    p_db_link       IN VARCHAR2 DEFAULT NULL,
    p_file_text     IN CLOB     DEFAULT EMPTY_CLOB() )
  IS
    file_rec sqli$_file%ROWTYPE;
  BEGIN
    file_rec := NULL;
    file_rec.statement_id := p_statement_id;
    file_rec.statid := NVL(p_statid, get_statid(p_statement_id));
    file_rec.statement_id2 := p_statement_id2;
    file_rec.file_type := p_file_type;
    file_rec.filename := p_filename;
    file_rec.username := p_username;
    file_rec.db_link := p_db_link;
    file_rec.file_date := p_file_date;
    file_rec.file_size := p_file_size;
    file_rec.file_text := p_file_text;

    DELETE sqli$_file WHERE statement_id = file_rec.statement_id AND filename = file_rec.filename;
    INSERT INTO sqli$_file VALUES file_rec;
    --COMMIT; do not commit here in order to avoid: ORA-22292: Cannot open a LOB in read-write mode without a transaction
  END set_file;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_file
   *
   * called by: upload_trace and sqlt$r.display_file
   *
   * ------------------------- */
  FUNCTION get_file (
    p_filename      IN VARCHAR2,
    p_statement_id  IN NUMBER DEFAULT NULL,
    p_statement_id2 IN NUMBER DEFAULT NULL )
  RETURN sqli$_file%ROWTYPE
  IS
    file_rec sqli$_file%ROWTYPE;
  BEGIN
    file_rec := NULL;

    IF p_filename IS NOT NULL THEN
      IF p_statement_id IS NOT NULL THEN
        SELECT *
          INTO file_rec
          FROM sqli$_file
         WHERE filename = p_filename
           AND p_statement_id IN (statement_id, statement_id2)
           AND (p_statement_id2 IS NULL OR p_statement_id2 IN (statement_id2, statement_id))
           AND ROWNUM = 1;
      ELSE -- sqltcompare
        SELECT *
          INTO file_rec
          FROM sqli$_file
         WHERE filename = p_filename
           AND ROWNUM = 1;
      END IF;
    END IF;

    RETURN file_rec;
  END get_file;

  /*************************************************************************************/

  /* -------------------------
   *
   * private set_filesize
   *
   * called by: upload_trace
   *
   * ------------------------- */
  PROCEDURE set_filesize (
    p_statement_id IN NUMBER,
    p_filename     IN VARCHAR2,
    p_file_size    IN NUMBER DEFAULT NULL )
  IS
    file_rec sqli$_file%ROWTYPE;
  BEGIN
    write_log('-> set_filesize for:'||p_filename);

    UPDATE sqli$_file SET
      file_size = NVL(p_file_size, SYS.DBMS_LOB.GETLENGTH(file_text))
     WHERE statement_id = p_statement_id
       AND filename = p_filename;

    --COMMIT;

    write_log('<- set_filesize for:'||p_filename);
  END set_filesize;

  /*************************************************************************************/

  /* -------------------------
   *
   * public trace_on
   *
   * called by sqltcommon4.sql (sqltrcaset.sql, sqltxecute.sql, sqltxplain.sql, sqltxtract.sql, sqltxtrone.sql, sqltxtrsby.sql, sqltxtrset.sql, sqltxtrxec.sql, sqltxtrxec.sql)
   *
   * ------------------------- */
  PROCEDURE trace_on (p_statement_id IN NUMBER)
  IS
  BEGIN
    IF get_param('keep_trace_10046_open') = 'Y' THEN
      --EXECUTE IMMEDIATE 'ALTER SESSION SET MAX_DUMP_FILE_SIZE = UNLIMITED';
      EXECUTE IMMEDIATE 'ALTER SESSION SET MAX_DUMP_FILE_SIZE = '''||get_param('sqlt_max_file_size_mb')||'M''';
      EXECUTE IMMEDIATE 'ALTER SESSION SET TRACEFILE_IDENTIFIER = "S'||get_statement_id_c(p_statement_id)||'_SQLT_TRACE"';
      EXECUTE IMMEDIATE 'ALTER SESSION SET TIMED_STATISTICS = TRUE';
      --EXECUTE IMMEDIATE 'ALTER SESSION SET STATISTICS_LEVEL = ''ALL''';
      EXECUTE IMMEDIATE 'ALTER SESSION SET EVENTS ''10046 TRACE NAME CONTEXT FOREVER, LEVEL '||TOOL_TRACE||''''; -- tool trace
    END IF;
  END trace_on;

  /*************************************************************************************/

  /* -------------------------
   *
   * public trace_off
   *
   * called by sqltcommon7.sql (sqltrcaset.sql, sqltxecute.sql, sqltxplain.sql, sqltxtract.sql, sqltxtrone.sql, sqltxtrsby.sql, sqltxtrset.sql, sqltxtrxec.sql, sqltxtrxec.sql)
   *
   * ------------------------- */
  PROCEDURE trace_off
  IS
  BEGIN
    IF get_param('keep_trace_10046_open') = 'Y' THEN
      --EXECUTE IMMEDIATE 'ALTER SESSION SET STATISTICS_LEVEL = ''TYPICAL''';
      EXECUTE IMMEDIATE 'ALTER SESSION SET EVENTS ''10046 TRACE NAME CONTEXT OFF''';
    END IF;
  END trace_off;

  /*************************************************************************************/

  /* -------------------------
   *
   * public generate_10053_xtract
   *
   * called by sqlt$d.diagnostics_data_collection_1
   * SYS.DBMS_SQLDIAG.DUMP_TRACE is available on 11.2 and higher
   *
   * ------------------------- */
  PROCEDURE generate_10053_xtract (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    l_trace_identifer_suffix VARCHAR2(32767);
    l_trace_identifer_prefix VARCHAR2(32767);
    l_trace_identifer VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);
    sql_rec sqlt$_sql_statement%ROWTYPE;
  BEGIN
    write_log('-> generate_10053_xtract');
    s_keep_trace_10046_open := get_param('keep_trace_10046_open');
    s_event_10053_level := get_param('event_10053_level');

    IF s_event_10053_level <> '1' THEN
      write_log('skip 10053 on XTRACT as per parameter event_10053_level');
      RETURN;
    END IF;

    IF get_param('generate_10053_xtract') = 'E' THEN -- last execution got (E)rror ORA-07445: exception encountered: core dump
      set_param('generate_10053_xtract', 'N');
      write_error('prior execution of '||TOOL_NAME||' errored out calling SYS.DBMS_SQLDIAG.DUMP_TRACE (and SYS.DBMS_SQLTUNE_INTERNAL) while generating a 10053 for XTRACT.');
      RETURN;
    END IF;

    IF get_param('generate_10053_xtract') = 'N' THEN
      write_log('skip 10053 on XTRACT as per parameter generate_10053_xtract');
      RETURN;
    END IF;

    sql_rec := get_statement(p_statement_id);
    write_log('sql_id:'||sql_rec.sql_id||', inst_id:'||sql_rec.instance_number);

    FOR i IN (SELECT plan_hash_value, elapsed_time, executions
                FROM sqlt$_gv$sqlarea_plan_hash
               WHERE statement_id = p_statement_id
                 AND inst_id = sql_rec.instance_number
               ORDER BY
                     (elapsed_time / GREATEST(executions, 1)) DESC)
    LOOP
      write_log('gv$sqlarea_plan_hash plan_hash_value:'||i.plan_hash_value||', elapsed_time:'||ROUND(i.elapsed_time / 1e6, 3)||'(secs), executions:'||i.executions);

      FOR j IN (SELECT child_number, elapsed_time, executions
                  FROM sqlt$_gv$sql
                 WHERE statement_id = p_statement_id
                   AND inst_id = sql_rec.instance_number
                   AND plan_hash_value = i.plan_hash_value
                 ORDER BY
                       (elapsed_time / GREATEST(executions, 1)) DESC)
      LOOP
        write_log('gv$sql child_number:'||j.child_number||', elapsed_time:'||ROUND(j.elapsed_time / 1e6, 3)||'(secs), executions:'||j.executions);

        -- it seems that p_file_id must start with a letter and include an underscore like "MY_FILE"
        l_trace_identifer_prefix := 's'||get_statement_id_c(p_statement_id);
        l_trace_identifer_suffix := '_10053_i'||sql_rec.instance_number||'_c'||j.child_number;
        l_trace_identifer := l_trace_identifer_prefix||l_trace_identifer_suffix;

        IF p_out_file_identifier IS NULL THEN
          l_out_file_identifier := NULL;
        ELSE
          l_out_file_identifier := '_'||p_out_file_identifier;
        END IF;

        sql_rec.file_10053_xtract_udump := session_trace_filename(l_trace_identifer);
        sql_rec.file_10053_xtract := 'sqlt_'||l_trace_identifer_prefix||l_out_file_identifier||l_trace_identifer_suffix||'_extract.trc';
        write_log('in udump: "'||sql_rec.file_10053_xtract_udump||'"');
        write_log('in local: "'||sql_rec.file_10053_xtract||'"');

        -- anticipates possible disconnect ORA-07445 on SYS.DBMS_SQLTUNE_INTERNAL while calling SYS.DBMS_SQLDIAG.DUMP_TRACE
        set_param('generate_10053_xtract', 'E'); -- was Y
        write_log('pre-xecution of SYS.DBMS_SQLDIAG.DUMP_TRACE (lock).');

        -- call to SYS.DBMS_SQLDIAG.DUMP_TRACE to get 10053 trace on SQLT XTRACT 11.2 or higher
        BEGIN
          -- if SYS.DBMS_SQLDIAG.DUMP_TRACE is executed with dynamic sql it disconnects the session in some systems
          --EXECUTE IMMEDIATE 'BEGIN SYS.DBMS_SQLDIAG.DUMP_TRACE(p_sql_id => :p_sql_id, p_child_number => :p_child_number, p_component => :p_component, p_file_id => :p_file_id); END;'
          --USING IN sql_rec.sql_id, IN j.child_number, IN 'Compiler', IN l_trace_identifer;

          -- this api gets executed on 11.2 or higher, else it gets commented out (see sqcpkg.sql for "skip_if_prior_to_112" setup)
          &&skip_if_prior_to_112.DBMS_SQLDIAG.DUMP_TRACE(p_sql_id => sql_rec.sql_id, p_child_number => j.child_number, p_component => 'Optimizer', p_file_id => l_trace_identifer);

          UPDATE sqlt$_sql_statement
             SET file_10053_xtract_udump = sql_rec.file_10053_xtract_udump,
                 file_10053_xtract = sql_rec.file_10053_xtract
           WHERE statement_id = p_statement_id;
          COMMIT;

          write_log('generated 10053 xtract');
        EXCEPTION
          WHEN OTHERS THEN -- this does not trap a disconnect
            write_error(SQLERRM);
            write_error('could not generate 10053 xtract');
        END;

        -- there was no disconnect so proceed to unlock
        set_param('generate_10053_xtract', 'Y'); -- restore
        write_log('post-xecution of SYS.DBMS_SQLDIAG.DUMP_TRACE (unlock).');

        EXIT; -- 1st
      END LOOP;
      EXIT; -- 1st
    END LOOP;

    -- must be after session_trace_filename call while recording trace filename
    IF s_keep_trace_10046_open = 'Y' THEN
      execute_immediate('ALTER SESSION SET TRACEFILE_IDENTIFIER = "S'||get_statement_id_c(p_statement_id)||'_SQLT_TRACE"');
    END IF;
  END generate_10053_xtract;

  /*************************************************************************************/

  /* -------------------------
   *
   * public event_10053_on
   *
   * called by sqlt$i.explain_plan_and_10053 and sqlt$i.xplain_begin
   *
   * ------------------------- */
  PROCEDURE event_10053_on (p_statement_id IN NUMBER)
  IS
  BEGIN
    write_log('-> event_10053_on');

    s_keep_trace_10046_open := get_param('keep_trace_10046_open');
    s_event_10053_level := get_param('event_10053_level');

    IF s_event_10053_level = '1' THEN
      --execute_immediate('ALTER SESSION SET MAX_DUMP_FILE_SIZE = UNLIMITED');
      execute_immediate('ALTER SESSION SET MAX_DUMP_FILE_SIZE = '''||get_param('sqlt_max_file_size_mb')||'M''');
      execute_immediate('ALTER SESSION SET TRACEFILE_IDENTIFIER = "s'||get_statement_id_c(p_statement_id)||'_10053"');
      IF get_rdbms_version >= '11' THEN
        --execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Compiler.*]''', 'P');
        execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Optimizer.*]''', 'P');
      ELSE
        execute_immediate('ALTER SESSION SET EVENTS ''10053 TRACE NAME CONTEXT FOREVER, LEVEL 1''', 'P');
      END IF;
    ELSE
      write_log('skip 10053 on as per parameter event_10053_level');
    END IF;
  END event_10053_on;

  /*************************************************************************************/

  /* -------------------------
   *
   * public event_10053_off
   *
   * called by sqlt$i.explain_plan_and_10053 (sqlt$i.xtract and sqlt$i.xecute_end) and sqlt$i.xplain_end
   *
   * ------------------------- */
  PROCEDURE event_10053_off (
    p_statement_id        IN NUMBER,
    p_error               IN VARCHAR2 DEFAULT NULL,  -- explain_plan_and_10053
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL ) -- explain_plan_and_10053 xtract
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    IF s_event_10053_level = '1' THEN
      IF get_rdbms_version >= '11' THEN
        --execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Compiler.*] OFF''', 'P');
        execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Optimizer.*] OFF''', 'P');
      ELSE
        execute_immediate('ALTER SESSION SET EVENTS ''10053 TRACE NAME CONTEXT OFF''', 'P');
      END IF;

      -- in case 10046 was turned on manually to trace SQLT
      IF s_keep_trace_10046_open = 'N' THEN
        execute_immediate('ALTER SESSION SET EVENTS ''10046 TRACE NAME CONTEXT OFF''', 'P');
      END IF;

      -- record 10053 trace filename
      BEGIN
        IF p_error IS NULL THEN
          IF p_out_file_identifier IS NULL THEN
            l_out_file_identifier := NULL;
          ELSE
            l_out_file_identifier := '_'||p_out_file_identifier;
          END IF;

          sql_rec.file_10053_udump := session_trace_filename('s'||get_statement_id_c(p_statement_id)||'_10053');
          sql_rec.file_10053 := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_10053_explain.trc';
          write_log('in udump: "'||sql_rec.file_10053_udump||'"');
          write_log('in local: "'||sql_rec.file_10053||'"');

          UPDATE sqlt$_sql_statement
             SET file_10053_udump = sql_rec.file_10053_udump,
                 file_10053 = sql_rec.file_10053
           WHERE statement_id = p_statement_id;
          COMMIT;
        END IF;
      END;

      -- must be after session_trace_filename call while recording trace filename
      IF s_keep_trace_10046_open = 'Y' THEN
        execute_immediate('ALTER SESSION SET TRACEFILE_IDENTIFIER = "S'||get_statement_id_c(p_statement_id)||'_SQLT_TRACE"');
      END IF;
    ELSE
      write_log('skip 10053 off as per parameter event_10053_level');
    END IF;

    write_log('<- event_10053_off');
  END event_10053_off;

  /*************************************************************************************/

  /* -------------------------
   *
   * public event_10046_10053_on
   *
   * called by: sqlt$i.xecute_begin
   * 22170172 add DBMS_ASSERT
   * ------------------------- */
  PROCEDURE event_10046_10053_on (p_statement_id IN NUMBER)
  IS
  BEGIN
    write_log('=> event_10046_10053_on');

    -- static variables
    s_statistics_level := UPPER(get_v$parameter('statistics_level'));
    --SELECT MAX(sid) INTO s_sid FROM v$session WHERE audsid = SYS_CONTEXT('USERENV', 'SESSIONID');
    s_sid := get_sid;
    s_statid := get_statid(p_statement_id);
    s_keep_trace_10046_open := get_param('keep_trace_10046_open');
    s_event_10053_level := get_param('event_10053_level');
    s_event_10046_level := get_param('event_10046_level');
    s_event_10507_level := get_param_n('event_10507_level');
    s_event_others := get_param('event_others');

    IF s_event_10053_level = '1' OR s_event_10046_level IN ('12', '8', '4', '1') THEN
      --execute_immediate('ALTER SESSION SET MAX_DUMP_FILE_SIZE = UNLIMITED');
      execute_immediate('ALTER SESSION SET MAX_DUMP_FILE_SIZE = '''||get_param('sqlt_max_file_size_mb')||'M''');
      execute_immediate('ALTER SESSION SET TRACEFILE_IDENTIFIER = "s'||get_statement_id_c(p_statement_id)||'_10046_10053"');
      execute_immediate('ALTER SESSION SET TIMED_STATISTICS = TRUE');

      IF s_statistics_level <> 'ALL' AND (get_rdbms_release >= 11 OR UPPER(get_platform) NOT LIKE '%LINUX%') THEN -- aware of 5969780
        execute_immediate('ALTER SESSION SET STATISTICS_LEVEL = ''ALL''');
      END IF;
    END IF;

    sqlt$d.collect_perf_stats_pre;
    sqlt$d.collect_perf_stats_begin(p_statement_id, s_statid, s_sid);

    -- 10507 Cardinality Feedback
    IF get_rdbms_release >= 11 THEN
      IF s_event_10507_level > 0 THEN
        execute_immediate('ALTER SESSION SET EVENTS ''10507 TRACE NAME CONTEXT FOREVER, LEVEL '||s_event_10507_level||'''');
      ELSIF s_event_10507_level = 0 THEN
        write_log('skip 10507 on as per parameter event_10507_level');
      END IF;
    END IF;

    -- 10046
    IF s_event_10046_level IN ('12', '8', '4', '1') THEN
      -- 10241, 10032, 10033, 10104, 10730, 46049
      IF s_event_others = 'Y' THEN
        -- remote
        execute_immediate('ALTER SESSION SET EVENTS ''10241 TRACE NAME CONTEXT FOREVER''');
        -- sort
        execute_immediate('ALTER SESSION SET EVENTS ''10032 TRACE NAME CONTEXT FOREVER''');
        -- sort
        execute_immediate('ALTER SESSION SET EVENTS ''10033 TRACE NAME CONTEXT FOREVER''');
        -- hash
        execute_immediate('ALTER SESSION SET EVENTS ''10104 TRACE NAME CONTEXT FOREVER''');
        -- Disable remote DC_HISTOGRAM_DEFS lookup
        -- execute_immediate('ALTER SESSION SET EVENTS ''10132 TRACE NAME CONTEXT FOREVER, LEVEL 1''');
        -- SYS.DBMS_RLS enable kzrtevw tracing
        execute_immediate('ALTER SESSION SET EVENTS ''10730 TRACE NAME CONTEXT FOREVER, LEVEL 1''');
        -- SYS.DBMS_XDS enable kzxdgxpd tracing
        execute_immediate('ALTER SESSION SET EVENTS ''46049 TRACE NAME CONTEXT FOREVER, LEVEL 1''');
      ELSE
        write_log('skip 10241, 10032, 10033, 10104, 10730, 46049 on as per parameter event_others');
      END IF;

      execute_immediate('ALTER SESSION SET EVENTS ''10046 TRACE NAME CONTEXT FOREVER, LEVEL '||to_char(to_number(s_event_10046_level))||'''', 'P'); -- 22170172

    ELSE
      write_log('skip 10046 on as per parameter event_10046_level');
    END IF;

    -- 10053
    IF s_event_10053_level = '1' THEN
      IF get_rdbms_version >= '11' THEN
        --execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Compiler.*]''', 'P');
        execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Optimizer.*]''', 'P');
      ELSE
        execute_immediate('ALTER SESSION SET EVENTS ''10053 TRACE NAME CONTEXT FOREVER, LEVEL 1''', 'P');
      END IF;
    ELSE
      write_log('skip 10053 on as per parameter event_10053_level');
    END IF;

    s_timestamp_before := SYSTIMESTAMP;
  END event_10046_10053_on;

  /*************************************************************************************/

  /* -------------------------
   *
   * public remote_event_10046_10053_on
   *
   * called by: sqlt$i.remote_event_10046_10053_on
   *
   * this api is executed on remote when remote_trace_begin is executed in local
   *
   * ------------------------- */
  PROCEDURE remote_event_10046_10053_on (
    p_statement_id IN NUMBER,
    p_10046        IN VARCHAR2 DEFAULT 'N' )
  IS
  BEGIN
    -- initialization
    s_log_statement_id := p_statement_id;
    s_log_statid := get_statid(p_statement_id);
    write_log('=> remote_event_10046_10053_on');
    common_initialization;
    s_statistics_level := UPPER(get_v$parameter('statistics_level'));
    s_event_10053_level := get_param('event_10053_level');
    s_event_10046_level := get_param('event_10046_level');
    s_event_others := get_param('event_others');

    IF s_event_10053_level = '1' OR s_event_10046_level IN ('12', '8', '4', '1') THEN
      --execute_immediate('ALTER SESSION SET MAX_DUMP_FILE_SIZE = UNLIMITED');
      execute_immediate('ALTER SESSION SET MAX_DUMP_FILE_SIZE = '''||get_param('sqlt_max_file_size_mb')||'M''');
      IF p_10046 = 'Y' THEN
        execute_immediate('ALTER SESSION SET TRACEFILE_IDENTIFIER = "s'||get_statement_id_c(p_statement_id)||'_10046_10053"');
      ELSE
        execute_immediate('ALTER SESSION SET TRACEFILE_IDENTIFIER = "s'||get_statement_id_c(p_statement_id)||'_10053"');
      END IF;
      execute_immediate('ALTER SESSION SET TIMED_STATISTICS = TRUE');

      IF s_statistics_level <> 'ALL' AND (get_rdbms_release >= 11 OR UPPER(get_platform) NOT LIKE '%LINUX%') THEN -- aware of 5969780
        execute_immediate('ALTER SESSION SET STATISTICS_LEVEL = ''ALL''');
      END IF;
    END IF;

    -- 10046
    IF s_event_10046_level IN ('12', '8', '4', '1') AND p_10046 = 'Y' THEN
      execute_immediate('ALTER SESSION SET EVENTS ''10046 TRACE NAME CONTEXT FOREVER, LEVEL '||to_char(to_number(s_event_10046_level))||'''', 'P'); -- 22170172
    ELSE
      write_log('skip 10046 on as per parameter event_10046_level('||s_event_10046_level||') or p_10046('||p_10046||')');
    END IF;

    -- 10053
    IF s_event_10053_level = '1' THEN
      IF get_rdbms_version >= '11' THEN
        --execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Compiler.*]''', 'P');
        execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Optimizer.*]''', 'P');
      ELSE
        execute_immediate('ALTER SESSION SET EVENTS ''10053 TRACE NAME CONTEXT FOREVER, LEVEL 1''', 'P');
      END IF;
    ELSE
      write_log('skip 10053 on as per parameter event_10053_level('||s_event_10053_level||')');
    END IF;
  END remote_event_10046_10053_on;

  /*************************************************************************************/

  /* -------------------------
   *
   * public event_10046_10053_off
   *
   * called by: sqlt$i.xecute_end
   *
   * ------------------------- */
  PROCEDURE event_10046_10053_off (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    s_timestamp_after := SYSTIMESTAMP;

    -- 10053
    IF s_event_10053_level = '1' THEN
      IF get_rdbms_version >= '11' THEN
        --execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Compiler.*] OFF''', 'P');
        execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Optimizer.*] OFF''', 'P');
      ELSE
        execute_immediate('ALTER SESSION SET EVENTS ''10053 TRACE NAME CONTEXT OFF''', 'P');
      END IF;
    ELSE
      write_log('skip 10053 off as per parameter event_10053_level');
    END IF;

    -- 10046
    IF s_event_10046_level IN ('12', '8', '4', '1') THEN
      IF s_keep_trace_10046_open = 'N' THEN
        execute_immediate('ALTER SESSION SET EVENTS ''10046 TRACE NAME CONTEXT OFF''', 'P');
      ELSE
        execute_immediate('ALTER SESSION SET EVENTS ''10046 TRACE NAME CONTEXT FOREVER, LEVEL '||TOOL_TRACE||'''', 'P'); -- tool trace
      END IF;

      -- 10241, 10032, 10033, 10104, 10730, 46049
      IF s_event_others = 'Y' THEN
        execute_immediate('ALTER SESSION SET EVENTS ''46049 TRACE NAME CONTEXT OFF''');
        execute_immediate('ALTER SESSION SET EVENTS ''10730 TRACE NAME CONTEXT OFF''');
        -- execute_immediate('ALTER SESSION SET EVENTS ''10132 TRACE NAME CONTEXT OFF''');
        execute_immediate('ALTER SESSION SET EVENTS ''10104 TRACE NAME CONTEXT OFF''');
        execute_immediate('ALTER SESSION SET EVENTS ''10033 TRACE NAME CONTEXT OFF''');
        execute_immediate('ALTER SESSION SET EVENTS ''10032 TRACE NAME CONTEXT OFF''');
        execute_immediate('ALTER SESSION SET EVENTS ''10241 TRACE NAME CONTEXT OFF''');
      ELSE
        write_log('skip 10241, 10032, 10033, 10104, 10730, 46049 off as per parameter event_others');
      END IF;
    ELSE
      write_log('skip 10046 off as per parameter event_10046_level');
    END IF;

    -- 10507 Cardinality Feedback
    IF get_rdbms_release >= 11 THEN
      IF s_event_10507_level > 0 THEN
        execute_immediate('ALTER SESSION SET EVENTS ''10507 TRACE NAME CONTEXT OFF''');
      ELSIF s_event_10507_level = 0 THEN
        write_log('skip 10507 on as per parameter event_10507_level');
      END IF;
    END IF;

-- 141028 removed parameters from pq_tqstat
    sqlt$d.collect_gv$pq_tqstat(p_statement_id, s_statid);
    sqlt$d.collect_perf_stats_end(p_statement_id, s_statid, s_sid);

    sqlt$d.collect_perf_stats_post(p_statement_id, s_statid);

    IF s_event_10053_level = '1' OR s_event_10046_level IN ('12', '8', '4', '1') THEN
      IF s_statistics_level <> 'ALL' AND (get_rdbms_release >= 11 OR UPPER(get_platform) NOT LIKE '%LINUX%') THEN -- aware of 5969780
        execute_immediate('ALTER SESSION SET STATISTICS_LEVEL = '||DBMS_ASSERT.ENQUOTE_LITERAL(s_statistics_level));  -- 22170172
      END IF;

      -- record 10046_10053 trace filename
      BEGIN
        IF p_out_file_identifier IS NULL THEN
          l_out_file_identifier := NULL;
        ELSE
          l_out_file_identifier := '_'||p_out_file_identifier;
        END IF;

        sql_rec.statement_response_time := s_timestamp_after - s_timestamp_before;
        sql_rec.file_10046_10053_udump := session_trace_filename('s'||get_statement_id_c(p_statement_id)||'_10046_10053');
        sql_rec.file_10046_10053 := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_10046_10053_execute.trc';
        write_log('in udump: "'||sql_rec.file_10046_10053_udump||'"');
        write_log('in local: "'||sql_rec.file_10046_10053||'"');

        UPDATE sqlt$_sql_statement
           SET statement_response_time = sql_rec.statement_response_time,
               file_10046_10053_udump = sql_rec.file_10046_10053_udump,
               file_10046_10053 = sql_rec.file_10046_10053
         WHERE statement_id = p_statement_id;
        COMMIT;
      END;

      -- must be after session_trace_filename call while recording trace filename
      IF s_keep_trace_10046_open = 'Y' THEN
        execute_immediate('ALTER SESSION SET TRACEFILE_IDENTIFIER = "S'||get_statement_id_c(p_statement_id)||'_SQLT_TRACE"');
      END IF;
    END IF;

    write_log('timestamp_before: '||s_timestamp_before);
    write_log('timestamp_after: '||s_timestamp_after);
    write_log('statement_response_time: '||sql_rec.statement_response_time);

    write_log('<= event_10046_10053_off');
  END event_10046_10053_off;

  /*************************************************************************************/

  /* -------------------------
   *
   * public upload_trace
   *
   * called by: sqlt$a.remote_upload_10046_10053, sqlt$a.upload_10053_trace, sqlt$a.upload_10053_xtract and sqlt$a.upload_10046_10053_trace
   *
   * ------------------------- */
  PROCEDURE upload_trace (
    p_statement_id IN NUMBER,
    p_file_udump   IN VARCHAR2, -- source
    p_file         IN VARCHAR2, -- target
    p_file_type    IN VARCHAR2,
    p_statid       IN VARCHAR2 DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL )
  IS
    file_rec sqli$_file%ROWTYPE;
    trace BFILE;
    l_target_offset INTEGER := 1;
    l_source_offset INTEGER := 1;
    l_language_context INTEGER := SYS.DBMS_LOB.DEFAULT_LANG_CTX;
    l_warning INTEGER;
    l_amount INTEGER;
    l_amount2 INTEGER;
    l_buffer VARCHAR2(32767);
    l_open_trace1 BOOLEAN := FALSE;
    l_open_trace2 BOOLEAN := FALSE;

  BEGIN
    write_log('-> upload_trace');

    IF p_file_udump IS NOT NULL AND p_file IS NOT NULL THEN
      write_log('source = "'||p_file_udump||'"');
      write_log('target = "'||p_file||'"');

      -- prepare file workspace
      write_log('prepare file workspace');
      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => p_file_type,
        p_filename     => p_file,
        p_statid       => p_statid,
        p_db_link      => p_db_link );
      file_rec := get_file(p_file, p_statement_id);

      -- open source trace (input)
      write_log('open source trace (input)');
      trace := BFILENAME('SQLT$UDUMP', p_file_udump);
      SYS.DBMS_LOB.OPEN(trace, SYS.DBMS_LOB.FILE_READONLY);
      l_open_trace1 := TRUE;

      -- determine how much data must be copied
      l_amount := get_param_n('upload_trace_size_mb') * 1024 * 1024;
      IF NVL(DBMS_LOB.GETLENGTH(trace), 0) < l_amount THEN
        l_amount := SYS.DBMS_LOB.LOBMAXSIZE; -- whole file
      ELSE
        l_amount := l_amount / 2;
      END IF;

      -- open target clob (output)
      write_log('open target clob (output)');
      SYS.DBMS_LOB.OPEN(file_rec.file_text, SYS.DBMS_LOB.LOB_READWRITE);
      l_open_trace2 := TRUE;

      -- upload to repository trace from os
      write_log('source_offset:'||l_source_offset||' target_offset:'||l_target_offset);
      IF l_source_offset > 0 AND l_target_offset > 0 THEN
        SYS.DBMS_LOB.LOADCLOBFROMFILE (
          dest_lob     => file_rec.file_text,
          src_bfile    => trace,
          --amount       => SYS.DBMS_LOB.LOBMAXSIZE,
          amount       => l_amount,
          dest_offset  => l_target_offset,
          src_offset   => l_source_offset,
          bfile_csid   => NLS_CHARSET_ID('US7ASCII'),
          lang_context => l_language_context,
          warning      => l_warning );

        IF l_warning = SYS.DBMS_LOB.WARN_INCONVERTIBLE_CHAR THEN
          write_log('inconvertible characters in trace. look for "?"');
        END IF;

        -- copy tail of file
        IF l_amount <> SYS.DBMS_LOB.LOBMAXSIZE THEN
          l_buffer := LF||'*** TRUNCATED AT CENTER TO '||get_param('upload_trace_size_mb')||'MB AS PER TOOL PARAMETER UPLOAD_TRACE_SIZE_MB ***'||LF;
          l_amount2 := LENGTH(l_buffer);

          write_log('target_offset:'||l_target_offset);
          SYS.DBMS_LOB.WRITE (
            lob_loc => file_rec.file_text,
            amount  => l_amount2,
            offset  => l_target_offset,
            buffer  => l_buffer );

          l_target_offset := l_target_offset + l_amount2;
          l_source_offset := SYS.DBMS_LOB.GETLENGTH(trace) - l_amount;

          write_log('source_offset:'||l_source_offset||' target_offset:'||l_target_offset);
          SYS.DBMS_LOB.LOADCLOBFROMFILE (
            dest_lob     => file_rec.file_text,
            src_bfile    => trace,
            amount       => SYS.DBMS_LOB.LOBMAXSIZE, -- load until the end of the BFILE
            dest_offset  => l_target_offset,
            src_offset   => l_source_offset,
            bfile_csid   => NLS_CHARSET_ID('US7ASCII'),
            lang_context => l_language_context,
            warning      => l_warning );

          IF l_warning = SYS.DBMS_LOB.WARN_INCONVERTIBLE_CHAR THEN
            write_log('inconvertible characters in trace. look for "?"');
          END IF;

          write_log('target_offset:'||l_target_offset);
          SYS.DBMS_LOB.WRITE (
            lob_loc => file_rec.file_text,
            amount  => l_amount2,
            offset  => l_target_offset,
            buffer  => l_buffer );
        END IF;
      END IF;

      -- close trace and clob
      write_log('close trace and clob');
      SYS.DBMS_LOB.CLOSE(trace);
      l_open_trace1 := FALSE;
      SYS.DBMS_LOB.CLOSE(file_rec.file_text);
      l_open_trace2 := FALSE;

      -- update file_size
      write_log('update file_size');
      set_filesize(p_statement_id, p_file); -- commit
      COMMIT;
    ELSE
      write_log('there is no trace to upload to repository');
    END IF;

    write_log('<- upload_trace');
  EXCEPTION
    WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error('could not upload trace to repository');

      IF l_open_trace1 THEN
        SYS.DBMS_LOB.CLOSE(trace);
      END IF;

      IF l_open_trace2 THEN
        SYS.DBMS_LOB.CLOSE(file_rec.file_text);
      END IF;
  END upload_trace;

  /*************************************************************************************/

  /* -------------------------
   *
   * public remote_upload_10046_10053
   *
   * called by: sqlt$a.remote_event_10046_10053_off
   *
   * this api is executed on remote. it uploads trace as a clob into remote db.
   * tarce may be copied entirely if small, else just head and tail.
   *
   * ------------------------- */
  PROCEDURE remote_upload_10046_10053 (
    p_statement_id           IN NUMBER,
    p_db_link                IN VARCHAR2,
    p_file_10046_10053_udump IN VARCHAR2,
    p_file_10046_10053       IN VARCHAR2 )
  IS
  BEGIN
    write_log('-> remote_upload_10046_10053');
    upload_trace (
      p_statement_id => p_statement_id,
      p_file_udump   => p_file_10046_10053_udump,
      p_file         => p_file_10046_10053,
      p_file_type    => 'REMOTE_TRACE',
      p_db_link      => p_db_link );
    write_log('<- remote_upload_10046_10053');
  END remote_upload_10046_10053;

  /*************************************************************************************/

  /* -------------------------
   *
   * private remote_event_10046_10053_off
   *
   * called by: sqlt$i.remote_event_10046_10053_off
   *
   * this api is executed on remote when remote_trace_end is executed in local.
   * after trace is closed, then it is uploaded into the db in remote
   *
   * ------------------------- */
  PROCEDURE remote_event_10046_10053_off (
    p_statement_id           IN  NUMBER,
    p_db_link                IN  VARCHAR2,
    p_10046                  IN  VARCHAR2 DEFAULT 'N',
    p_out_file_identifier    IN  VARCHAR2 DEFAULT NULL,
    x_file_10046_10053_udump OUT VARCHAR2,
    x_file_10046_10053       OUT VARCHAR2 )
  IS
    l_event VARCHAR2(32);
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    -- 10053
    IF s_event_10053_level = '1' THEN
      IF get_rdbms_version >= '11' THEN
        --execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Compiler.*] OFF''', 'P');
        execute_immediate('ALTER SESSION SET EVENTS ''TRACE [SQL_Optimizer.*] OFF''', 'P');
      ELSE
        execute_immediate('ALTER SESSION SET EVENTS ''10053 TRACE NAME CONTEXT OFF''', 'P');
      END IF;
    ELSE
      write_log('skip 10053 off as per parameter event_10053_level('||s_event_10053_level||')');
    END IF;

    -- 10046
    IF s_event_10046_level IN ('12', '8', '4', '1') AND p_10046 = 'Y' THEN
      execute_immediate('ALTER SESSION SET EVENTS ''10046 TRACE NAME CONTEXT OFF''', 'P');
    ELSE
      write_log('skip 10046 off as per parameter event_10046_level('||s_event_10046_level||') or p_10046('||p_10046||')');
    END IF;

    IF s_event_10053_level = '1' OR s_event_10046_level IN ('12', '8', '4', '1') THEN
      IF s_statistics_level <> 'ALL' AND (get_rdbms_release >= 11 OR UPPER(get_platform) NOT LIKE '%LINUX%') THEN -- aware of 5969780
        execute_immediate('ALTER SESSION SET STATISTICS_LEVEL = '||DBMS_ASSERT.ENQUOTE_LITERAL(s_statistics_level));  -- 22170172
      END IF;

      -- record 10046_10053 trace filename
      BEGIN
        IF p_10046 = 'Y' THEN
          l_event := '_10046_10053';
        ELSE
          l_event := '_10053';
        END IF;

        IF p_out_file_identifier IS NULL THEN
          l_out_file_identifier := NULL;
        ELSE
          l_out_file_identifier := '_'||p_out_file_identifier;
        END IF;

        x_file_10046_10053_udump := session_trace_filename('s'||get_statement_id_c(p_statement_id)||l_event);
        x_file_10046_10053 := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_'||get_db_link_short(p_db_link)||l_event||'.trc';
        write_log('in udump: "'||x_file_10046_10053_udump||'"');
        write_log('in local: "'||x_file_10046_10053||'"');
      END;

      -- upload trace
      remote_upload_10046_10053 (
        p_statement_id           => p_statement_id,
        p_db_link                => p_db_link,
        p_file_10046_10053_udump => x_file_10046_10053_udump,
        p_file_10046_10053       => x_file_10046_10053 );
    END IF;

    write_log('<= remote_event_10046_10053_off');
  END remote_event_10046_10053_off;

  /*************************************************************************************/

  /* -------------------------
   *
   * public clean_sqlt$_sql_plan_table
   *
   * called by: sqlt$i.xplain_end and sqlt$i.explain_plan_and_10053
   *
   * ------------------------- */
  PROCEDURE clean_sqlt$_sql_plan_table (p_statement_id IN NUMBER)
  IS
    l_statement_id_c1 VARCHAR2(32767);
    l_statement_id_c2 VARCHAR2(32767);
  BEGIN
    write_log('-> clean_sqlt$_sql_plan_table');
    l_statement_id_c1 := get_statement_id_c(0);
    l_statement_id_c2 := get_statement_id_c(GREATEST(p_statement_id, 99999));

    FOR i IN (SELECT ROWID row_id, id, statement_id FROM sqlt$_sql_plan_table)
    LOOP
      IF i.statement_id NOT BETWEEN l_statement_id_c1 AND l_statement_id_c2 THEN
        write_log('DELETE sqlt$_sql_plan_table for statement_id = "'||i.statement_id||'" and id = "'||i.id||'"');
        DELETE sqlt$_sql_plan_table WHERE ROWID = i.row_id;
      END IF;
    END LOOP;
    write_log('<- clean_sqlt$_sql_plan_table');
  END clean_sqlt$_sql_plan_table;

  /*************************************************************************************/

  /* -------------------------
   *
   * public print_statement_workspace
   *
   * ------------------------- */

  PROCEDURE print_statement_workspace (p_statement_id IN NUMBER) is
    sql_rec sqlt$_sql_statement%ROWTYPE;  
  begin
    put_line('-> print_statement_workspace');
    sql_rec := get_statement(p_statement_id);
	put_line('STATEMENT_ID                   : '||sql_rec.STATEMENT_ID);
	put_line('STATID                         : '||sql_rec.STATID);
	put_line('STATEMENT_SET_ID               : '||sql_rec.STATEMENT_SET_ID );
	put_line('GROUP_ID                       : '||sql_rec.GROUP_ID );
	put_line('METHOD                         : '||sql_rec.METHOD );
	put_line('INPUT_FILENAME                 : '||sql_rec.INPUT_FILENAME );
	put_line('HOST_NAME_SHORT                : '||sql_rec.HOST_NAME_SHORT);
	put_line('CPU_COUNT                      : '||sql_rec.CPU_COUNT);
	put_line('NUM_CPUS                       : '||sql_rec.NUM_CPUS );
	put_line('NUM_CPU_CORES                  : '||sql_rec.NUM_CPU_CORES);
	put_line('NUM_CPU_SOCKETS                : '||sql_rec.NUM_CPU_SOCKETS);
	put_line('RAC                            : '||sql_rec.RAC);
	put_line('EXADATA                        : '||sql_rec.EXADATA);
	put_line('INMEMORY_OPTION                : '||sql_rec.INMEMORY_OPTION);
	put_line('OPTIM_PEEK_USER_BINDS          : '||sql_rec.OPTIM_PEEK_USER_BINDS);
	put_line('DATABASE_ID                    : '||sql_rec.DATABASE_ID);
	put_line('DATABASE_NAME_SHORT            : '||sql_rec.DATABASE_NAME_SHORT);
	put_line('SID                            : '||sql_rec.SID);
	put_line('INSTANCE_NUMBER                : '||sql_rec.INSTANCE_NUMBER);
	put_line('INSTANCE_NAME_SHORT            : '||sql_rec.INSTANCE_NAME_SHORT);
	put_line('PLATFORM                       : '||sql_rec.PLATFORM );
	put_line('PRODUCT_VERSION                : '||sql_rec.PRODUCT_VERSION);
	put_line('RDBMS_VERSION                  : '||sql_rec.RDBMS_VERSION);
	put_line('RDBMS_VERSION_SHORT            : '||sql_rec.RDBMS_VERSION_SHORT);
	put_line('RDBMS_RELEASE                  : '||sql_rec.RDBMS_RELEASE);
	put_line('LANGUAGE                       : '||sql_rec.LANGUAGE );
	put_line('APPS_RELEASE                   : '||sql_rec.APPS_RELEASE );
	put_line('APPS_SYSTEM_NAME               : '||sql_rec.APPS_SYSTEM_NAME );
	put_line('SIEBEL                         : '||sql_rec.SIEBEL );
	put_line('SIEBEL_SCHEMA                  : '||sql_rec.SIEBEL_SCHEMA);
	put_line('SIEBEL_APP_VER                 : '||sql_rec.SIEBEL_APP_VER );
	put_line('PSFT                           : '||sql_rec.PSFT );
	put_line('PSFT_SCHEMA                    : '||sql_rec.PSFT_SCHEMA);
	put_line('PSFT_TOOLS_REL                 : '||sql_rec.PSFT_TOOLS_REL );
	put_line('SQL_TUNING_ADVISOR             : '||sql_rec.SQL_TUNING_ADVISOR );
	put_line('SQL_MONITORING                 : '||sql_rec.SQL_MONITORING );
	put_line('AUTOMATIC_WORKLOAD_REPOSITORY  : '||sql_rec.AUTOMATIC_WORKLOAD_REPOSITORY);
	put_line('STAND_BY_DBLINK                : '||sql_rec.STAND_BY_DBLINK);
	put_line('NLS_CHARACTERSET               : '||sql_rec.NLS_CHARACTERSET );
	put_line('DBTIMEZONE                     : '||sql_rec.DBTIMEZONE );
	put_line('TOTAL_BYTES                    : '||sql_rec.TOTAL_BYTES);
	put_line('TOTAL_BLOCKS                   : '||sql_rec.TOTAL_BLOCKS );
	put_line('TOTAL_USER_BYTES               : '||sql_rec.TOTAL_USER_BYTES );
	put_line('TOTAL_USER_BLOCKS              : '||sql_rec.TOTAL_USER_BLOCKS);
	put_line('SEGMENTS_TOTAL_BYTES           : '||sql_rec.SEGMENTS_TOTAL_BYTES );
	put_line('IN_MEMORY                      : '||sql_rec.IN_MEMORY);
	put_line('IN_AWR                         : '||sql_rec.IN_AWR );
	put_line('STRING                         : '||sql_rec.STRING );
	put_line('STA_TASK_NAME_MEM              : '||sql_rec.STA_TASK_NAME_MEM);
	put_line('STA_TASK_NAME_AWR              : '||sql_rec.STA_TASK_NAME_AWR);
	put_line('STA_TASK_NAME_TXT              : '||sql_rec.STA_TASK_NAME_TXT);
	put_line('COMMAND_TYPE                   : '||sql_rec.COMMAND_TYPE );
	put_line('COMMAND_TYPE_NAME              : '||sql_rec.COMMAND_TYPE_NAME);
	put_line('SQL_HANDLE                     : '||sql_rec.SQL_HANDLE );
	put_line('SQL_ID_FOUND_USING_SQLTEXT     : '||sql_rec.SQL_ID_FOUND_USING_SQLTEXT );
	put_line('SQL_ID                         : '||sql_rec.SQL_ID );
	put_line('HASH_VALUE                     : '||sql_rec.HASH_VALUE );
	put_line('SIGNATURE_SO                   : '||sql_rec.SIGNATURE_SO );
	put_line('SIGNATURE_STA                  : '||sql_rec.SIGNATURE_STA);
	put_line('SIGNATURE_STA_FORCE_MATCH      : '||sql_rec.SIGNATURE_STA_FORCE_MATCH);
	put_line('XPLAIN_SQL_ID                  : '||sql_rec.XPLAIN_SQL_ID);
	put_line('SQL_ID_UNSTRIPPED              : '||sql_rec.SQL_ID_UNSTRIPPED);
	put_line('HASH_VALUE_UNSTRIPPED          : '||sql_rec.HASH_VALUE_UNSTRIPPED);
	put_line('SIGNATURE_SO_UNSTRIPPED        : '||sql_rec.SIGNATURE_SO_UNSTRIPPED);
	put_line('SIGNATURE_STA_UNSTRIPPED       : '||sql_rec.SIGNATURE_STA_UNSTRIPPED );
	put_line('SIGNATURE_STA_FM_UNSTRIPPED    : '||sql_rec.SIGNATURE_STA_FM_UNSTRIPPED);
	put_line('SQL_LENGTH                     : '||sql_rec.SQL_LENGTH );
	put_line('SQL_TEXT                       : '||sql_rec.SQL_TEXT );
	put_line('SQL_LENGTH_UNSTRIPPED          : '||sql_rec.SQL_LENGTH_UNSTRIPPED);
	put_line('SQL_LENGTH_IN_PIECES           : '||sql_rec.SQL_LENGTH_IN_PIECES );
	put_line('USER_ID                        : '||sql_rec.USER_ID);
	put_line('USERNAME                       : '||sql_rec.USERNAME );
	put_line('SQLT_USER_ROLE                 : '||sql_rec.SQLT_USER_ROLE );
	put_line('TOOL_START_TIMESTAMP           : '||sql_rec.TOOL_START_TIMESTAMP );
	put_line('TOOL_START_DATE                : '||sql_rec.TOOL_START_DATE);
	put_line('TOOL_END_DATE                  : '||sql_rec.TOOL_END_DATE);
	put_line('STATEMENT_RESPONSE_TIME        : '||sql_rec.STATEMENT_RESPONSE_TIME);
	put_line('RESTORE_DATE                   : '||sql_rec.RESTORE_DATE );
	put_line('MAT_VIEW_REWRITE_ENABLED_COUNT : '||sql_rec.MAT_VIEW_REWRITE_ENABLED_COUNT );
	put_line('PARAM_AUTOSTATS_TARGET         : '||sql_rec.PARAM_AUTOSTATS_TARGET );
	put_line('PARAM_PUBLISH                  : '||sql_rec.PARAM_PUBLISH);
	put_line('PARAM_INCREMENTAL              : '||sql_rec.PARAM_INCREMENTAL);
	put_line('PARAM_STALE_PERCENT            : '||sql_rec.PARAM_STALE_PERCENT);
	put_line('PARAM_ESTIMATE_PERCENT         : '||sql_rec.PARAM_ESTIMATE_PERCENT );
	put_line('PARAM_DEGREE                   : '||sql_rec.PARAM_DEGREE );
	put_line('PARAM_CASCADE                  : '||sql_rec.PARAM_CASCADE);
	put_line('PARAM_NO_INVALIDATE            : '||sql_rec.PARAM_NO_INVALIDATE);
	put_line('PARAM_METHOD_OPT               : '||sql_rec.PARAM_METHOD_OPT );
	put_line('PARAM_GRANULARITY              : '||sql_rec.PARAM_GRANULARITY);
	put_line('PARAM_STATS_RETENTION          : '||sql_rec.PARAM_STATS_RETENTION);
	put_line('PARAM_APPROXIMATE_NDV          : '||sql_rec.PARAM_APPROXIMATE_NDV);
	put_line('PARAM_INCR_INTERNAL_CONTROL    : '||sql_rec.PARAM_INCR_INTERNAL_CONTROL);
	put_line('PARAM_CONCURRENT               : '||sql_rec.PARAM_CONCURRENT );
	put_line('OPTIMIZER_FEATURES_ENABLE      : '||sql_rec.OPTIMIZER_FEATURES_ENABLE);
	put_line('DB_BLOCK_SIZE                  : '||sql_rec.DB_BLOCK_SIZE);
	put_line('DB_FILE_MULTIBLOCK_READ_COUNT  : '||sql_rec.DB_FILE_MULTIBLOCK_READ_COUNT);
	put_line('UDB_FILE_OPTIMIZER_READ_COUNT  : '||sql_rec.UDB_FILE_OPTIMIZER_READ_COUNT);
	put_line('UDB_FILE_EXEC_READ_COUNT       : '||sql_rec.UDB_FILE_EXEC_READ_COUNT );
	put_line('NLS_SORT                       : '||sql_rec.NLS_SORT );
	put_line('NLS_SORT_SESSION               : '||sql_rec.NLS_SORT_SESSION );
	put_line('NLS_SORT_INSTANCE              : '||sql_rec.NLS_SORT_INSTANCE);
	put_line('NLS_SORT_GLOBAL                : '||sql_rec.NLS_SORT_GLOBAL);
	put_line('CPUSPEEDNW                     : '||sql_rec.CPUSPEEDNW );
	put_line('CPUSPEED                       : '||sql_rec.CPUSPEED );
	put_line('IOSEEKTIM                      : '||sql_rec.IOSEEKTIM);
	put_line('IOTFRSPEED                     : '||sql_rec.IOTFRSPEED );
	put_line('MBRC                           : '||sql_rec.MBRC );
	put_line('SREADTIM                       : '||sql_rec.SREADTIM );
	put_line('MREADTIM                       : '||sql_rec.MREADTIM );
	put_line('MAXTHR                         : '||sql_rec.MAXTHR );
	put_line('SLAVETHR                       : '||sql_rec.SLAVETHR );
	put_line('CPU_COST_SCALING_FACTOR        : '||sql_rec.CPU_COST_SCALING_FACTOR);
	put_line('SYNTHETIZED_MBRC_AND_READTIM   : '||sql_rec.SYNTHETIZED_MBRC_AND_READTIM );
	put_line('ACTUAL_SREADTIM                : '||sql_rec.ACTUAL_SREADTIM);
	put_line('ACTUAL_MREADTIM                : '||sql_rec.ACTUAL_MREADTIM);
	put_line('IOC_START_TIME                 : '||sql_rec.IOC_START_TIME );
	put_line('IOC_END_TIME                   : '||sql_rec.IOC_END_TIME );
	put_line('IOC_MAX_IOPS                   : '||sql_rec.IOC_MAX_IOPS );
	put_line('IOC_MAX_MBPS                   : '||sql_rec.IOC_MAX_MBPS );
	put_line('IOC_MAX_PMBPS                  : '||sql_rec.IOC_MAX_PMBPS);
	put_line('IOC_LATENCY                    : '||sql_rec.IOC_LATENCY);
	put_line('IOC_NUM_PHYSICAL_DISKS         : '||sql_rec.IOC_NUM_PHYSICAL_DISKS );
	put_line('IOC_STATUS                     : '||sql_rec.IOC_STATUS );
	put_line('IOC_CALIBRATION_TIME           : '||sql_rec.IOC_CALIBRATION_TIME );
	put_line('BEST_PLAN_HASH_VALUE           : '||sql_rec.BEST_PLAN_HASH_VALUE );
	put_line('WORST_PLAN_HASH_VALUE          : '||sql_rec.WORST_PLAN_HASH_VALUE);
	put_line('XPLAIN_PLAN_HASH_VALUE         : '||sql_rec.XPLAIN_PLAN_HASH_VALUE );
	put_line('XECUTE_PLAN_HASH_VALUE         : '||sql_rec.XECUTE_PLAN_HASH_VALUE );
	put_line('XECUTE_CHILD_NUMBER            : '||sql_rec.XECUTE_CHILD_NUMBER);
	put_line('PX_SERVERS_EXECUTIONS          : '||sql_rec.PX_SERVERS_EXECUTIONS);
	put_line('FILE_SQLT_MAIN                 : '||sql_rec.FILE_SQLT_MAIN );
	put_line('FILE_SQLT_METADATA             : '||sql_rec.FILE_SQLT_METADATA );
	put_line('FILE_SQLT_METADATA1            : '||sql_rec.FILE_SQLT_METADATA1);
	put_line('FILE_SQLT_METADATA2            : '||sql_rec.FILE_SQLT_METADATA2);
	put_line('FILE_SQLT_SYSTEM_STATS         : '||sql_rec.FILE_SQLT_SYSTEM_STATS );
	put_line('FILE_SQLT_SCHEMA_STATS         : '||sql_rec.FILE_SQLT_SCHEMA_STATS );
	put_line('FILE_SQLT_SET_CBO_ENV          : '||sql_rec.FILE_SQLT_SET_CBO_ENV);
	put_line('FILE_SQLT_LITE                 : '||sql_rec.FILE_SQLT_LITE );
	put_line('FILE_SQLT_README               : '||sql_rec.FILE_SQLT_README );
	put_line('FILE_SQLT_README_TEXT          : '||sql_rec.FILE_SQLT_README_TEXT);
	put_line('FILE_10053_XTRACT_UDUMP        : '||sql_rec.FILE_10053_XTRACT_UDUMP);
	put_line('FILE_10053_XTRACT              : '||sql_rec.FILE_10053_XTRACT);
	put_line('FILE_10053_UDUMP               : '||sql_rec.FILE_10053_UDUMP );
	put_line('FILE_10053                     : '||sql_rec.FILE_10053 );
	put_line('FILE_10046_10053_UDUMP         : '||sql_rec.FILE_10046_10053_UDUMP );
	put_line('FILE_10046_10053               : '||sql_rec.FILE_10046_10053 );
	put_line('FILE_10046_SPLIT               : '||sql_rec.FILE_10046_SPLIT );
	put_line('FILE_10053_SPLIT               : '||sql_rec.FILE_10053_SPLIT );
	put_line('FILE_SQLT_TCSCRIPT             : '||sql_rec.FILE_SQLT_TCSCRIPT );
	put_line('FILE_SQLT_TCSQL                : '||sql_rec.FILE_SQLT_TCSQL);
	put_line('FILE_SQLT_TCBUILDER            : '||sql_rec.FILE_SQLT_TCBUILDER);
	put_line('FILE_SQLT_EXP_PARAMS           : '||sql_rec.FILE_SQLT_EXP_PARAMS );
	put_line('FILE_SQLT_EXP_PARAMS2          : '||sql_rec.FILE_SQLT_EXP_PARAMS2);
	put_line('FILE_SQLT_EXP_DRIVER           : '||sql_rec.FILE_SQLT_EXP_DRIVER );
	put_line('FILE_SQLT_IMP_SCRIPT           : '||sql_rec.FILE_SQLT_IMP_SCRIPT );
	put_line('FILE_SQLT_PROFILE              : '||sql_rec.FILE_SQLT_PROFILE);
	put_line('FILE_STA_REPORT_MEM            : '||sql_rec.FILE_STA_REPORT_MEM);
	put_line('FILE_STA_SCRIPT_MEM            : '||sql_rec.FILE_STA_SCRIPT_MEM);
	put_line('FILE_STA_REPORT_TXT            : '||sql_rec.FILE_STA_REPORT_TXT);
	put_line('FILE_STA_SCRIPT_TXT            : '||sql_rec.FILE_STA_SCRIPT_TXT);
	put_line('FILE_STA_REPORT_AWR            : '||sql_rec.FILE_STA_REPORT_AWR);
	put_line('FILE_STA_SCRIPT_AWR            : '||sql_rec.FILE_STA_SCRIPT_AWR);
	put_line('FILE_MON_REPORT_ACTIVE         : '||sql_rec.FILE_MON_REPORT_ACTIVE );
	put_line('FILE_MON_REPORT_HTML           : '||sql_rec.FILE_MON_REPORT_HTML );
	put_line('FILE_MON_REPORT_TEXT           : '||sql_rec.FILE_MON_REPORT_TEXT );
	put_line('FILE_MON_REPORT_DRIVER         : '||sql_rec.FILE_MON_REPORT_DRIVER );
	put_line('FILE_SQL_DETAIL_ACTIVE         : '||sql_rec.FILE_SQL_DETAIL_ACTIVE );
	put_line('FILE_AWRRPT_DRIVER             : '||sql_rec.FILE_AWRRPT_DRIVER );
	put_line('FILE_ADDMRPT_DRIVER            : '||sql_rec.FILE_ADDMRPT_DRIVER);
	put_line('FILE_ASHRPT_DRIVER             : '||sql_rec.FILE_ASHRPT_DRIVER );
	put_line('FILE_TRCANLZR_HTML             : '||sql_rec.FILE_TRCANLZR_HTML );
	put_line('FILE_TRCANLZR_TXT              : '||sql_rec.FILE_TRCANLZR_TXT);
	put_line('FILE_TRCANLZR_LOG              : '||sql_rec.FILE_TRCANLZR_LOG);
	put_line('FILE_REMOTE_DRIVER             : '||sql_rec.FILE_REMOTE_DRIVER );
	put_line('FILE_TKPROF_PX_DRIVER          : '||sql_rec.FILE_TKPROF_PX_DRIVER);
	put_line('FILE_TRCANLZR_PX_HTML          : '||sql_rec.FILE_TRCANLZR_PX_HTML);
	put_line('FILE_TRCANLZR_PX_TXT           : '||sql_rec.FILE_TRCANLZR_PX_TXT );
	put_line('FILE_TRCANLZR_PX_LOG           : '||sql_rec.FILE_TRCANLZR_PX_LOG );
	put_line('FILE_SCRIPT_OUTPUT_DRIVER      : '||sql_rec.FILE_SCRIPT_OUTPUT_DRIVER);
	put_line('FILE_BDE_CHK_CBO               : '||sql_rec.FILE_BDE_CHK_CBO );
	put_line('FILE_PROCESS_LOG               : '||sql_rec.FILE_PROCESS_LOG );
	put_line('FILE_TC_PURGE                  : '||sql_rec.FILE_TC_PURGE);
	put_line('FILE_TC_RESTORE                : '||sql_rec.FILE_TC_RESTORE);
	put_line('FILE_TC_DEL_HGRM               : '||sql_rec.FILE_TC_DEL_HGRM );
	put_line('FILE_TC_PLAN                   : '||sql_rec.FILE_TC_PLAN );
	put_line('FILE_TC_10053                  : '||sql_rec.FILE_TC_10053);
	put_line('FILE_TC_FLUSH                  : '||sql_rec.FILE_TC_FLUSH);
	put_line('FILE_TC_Q                      : '||sql_rec.FILE_TC_Q);
	put_line('FILE_TC_SQL                    : '||sql_rec.FILE_TC_SQL);
	put_line('FILE_TC_SH                     : '||sql_rec.FILE_TC_SH );
	put_line('FILE_TC_SQLTC                  : '||sql_rec.FILE_TC_SQLTC);
	put_line('FILE_TC_SETUP                  : '||sql_rec.FILE_TC_SETUP);
	put_line('FILE_TC_README                 : '||sql_rec.FILE_TC_README );
	put_line('FILE_TC_PKG                    : '||sql_rec.FILE_TC_PKG);
	put_line('FILE_TC_SELECTIVITY            : '||sql_rec.FILE_TC_SELECTIVITY);
	put_line('FILE_TC_SELECTIVITY_AUX        : '||sql_rec.FILE_TC_SELECTIVITY_AUX);
	put_line('FILE_TCX_INSTALL_SQL           : '||sql_rec.FILE_TCX_INSTALL_SQL );
	put_line('FILE_TCX_INSTALL_SH            : '||sql_rec.FILE_TCX_INSTALL_SH);
	put_line('FILE_TCX_PKG                   : '||sql_rec.FILE_TCX_PKG );
	put_line('FILE_PERFHUB_DRIVER            : '||sql_rec.FILE_PERFHUB_DRIVER); -- 160403
	put_line('<- print_statement_workspace');
  end print_statement_workspace;
    
  /*************************************************************************************/

  /* -------------------------
   *
   * public create_statement_workspace
   *
   * called by: sqlt$i.xtract, sqlt$i.remote_xtract, sqlt$i.xecute_begin and sqlt$i.xplain_begin
   *
   * ------------------------- */
  PROCEDURE create_statement_workspace (
    p_statement_id     IN NUMBER,
    p_group_id         IN NUMBER DEFAULT NULL,   -- used by sqlt$i.remote_xtract
    p_statement_set_id IN NUMBER DEFAULT NULL )  -- used by sqlt$i.xtract
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_dummy VARCHAR2(32767);
    l_count NUMBER;
  BEGIN
    write_log('-> create_statement_workspace');
    sql_rec := NULL;
    sql_rec.statement_id := p_statement_id;
    sql_rec.statid := get_statid(p_statement_id);
    sql_rec.statement_set_id := p_statement_set_id;
    sql_rec.group_id := p_group_id;
    sql_rec.method := s_sqlt_method;
    sql_rec.host_name_short := get_host_name;
    sql_rec.cpu_count := get_v$parameter('cpu_count');
    sql_rec.num_cpus := get_v$osstat('num_cpus');
    sql_rec.num_cpu_cores := get_v$osstat('num_cpu_cores');
    sql_rec.num_cpu_sockets := get_v$osstat('num_cpu_sockets');	
    sql_rec.rac := get_v$parameter('cluster_database');
    sql_rec.database_id := get_database_id;
    sql_rec.database_name_short := get_database_name_short;
    sql_rec.sid := get_sid;
    sql_rec.instance_number := get_instance_number;
    sql_rec.instance_name_short := get_instance_name;
    sql_rec.platform := get_platform;
    sql_rec.product_version := get_product_version;
    sql_rec.rdbms_version := get_rdbms_version;
    sql_rec.rdbms_version_short := get_rdbms_version_short;
    sql_rec.rdbms_release := get_rdbms_release;
    sql_rec.stand_by_dblink := s_db_link;
    sql_rec.language := get_language;
    sql_rec.user_id := UID;
    sql_rec.username := USER;
    sql_rec.tool_start_timestamp := SYSTIMESTAMP;
    sql_rec.tool_start_date := SYSDATE;
    sql_rec.optimizer_features_enable := get_v$parameter('optimizer_features_enable');
    sql_rec.dbtimezone := get_database_properties('DBTIMEZONE');
    sql_rec.nls_characterset := get_database_properties('NLS_CHARACTERSET');
    sql_rec.db_block_size := get_v$parameter('db_block_size');
    sql_rec.db_file_multiblock_read_count := get_v$parameter('db_file_multiblock_read_count');
    sql_rec.udb_file_optimizer_read_count := NVL(get_v$parameter('_db_file_optimizer_read_count'), -1);
    sql_rec.udb_file_exec_read_count := NVL(get_v$parameter('_db_file_exec_read_count'), -1);
    sql_rec.sql_tuning_advisor := get_param('sql_tuning_advisor');
    sql_rec.sql_monitoring := get_param('sql_monitoring');
    sql_rec.automatic_workload_repository := get_param('automatic_workload_repository');
    sql_rec.inmemory_option := CASE WHEN NVL(get_v$parameter('inmemory_size'),0) <> 0 THEN 'YES' ELSE 'NO' END;

    BEGIN
      EXECUTE IMMEDIATE 'SELECT value FROM v$nls_parameters'||s_db_link||' WHERE UPPER(parameter) = ''NLS_SORT''' INTO sql_rec.nls_sort_session;
      sql_rec.nls_sort := sql_rec.nls_sort_session;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        sql_rec.nls_sort_session := NULL;
    END;

    BEGIN
      EXECUTE IMMEDIATE 'SELECT value FROM v$system_parameter'||s_db_link||' WHERE UPPER(name) = ''NLS_SORT''' INTO sql_rec.nls_sort_instance;

      IF NVL(sql_rec.nls_sort_instance, 'BINARY') <> 'BINARY' AND NVL(sql_rec.nls_sort, 'BINARY') = 'BINARY' THEN
        sql_rec.nls_sort := sql_rec.nls_sort_instance;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        sql_rec.nls_sort_instance := NULL;
    END;

    BEGIN
      EXECUTE IMMEDIATE 'SELECT value FROM nls_database_parameters'||s_db_link||' WHERE UPPER(parameter) = ''NLS_SORT''' INTO sql_rec.nls_sort_global;

      IF NVL(sql_rec.nls_sort_global, 'BINARY') <> 'BINARY' AND NVL(sql_rec.nls_sort, 'BINARY') = 'BINARY' THEN
        sql_rec.nls_sort := sql_rec.nls_sort_global;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        sql_rec.nls_sort_global := NULL;
    END;

    sql_rec.sqlt_user_role := is_user_in_role(ROLE_NAME, USER);

    BEGIN
      EXECUTE IMMEDIATE 'SELECT ''YES'', owner FROM sys.dba_tab_columns'||s_db_link||' WHERE table_name = :table_name AND column_name = :column_name AND data_type = :data_type AND ROWNUM = 1'
      INTO sql_rec.siebel, sql_rec.siebel_schema
      USING IN 'S_REPOSITORY', IN 'ROW_ID', IN 'VARCHAR2';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        sql_rec.siebel := 'NO';
        sql_rec.siebel_schema := NULL;
    END;

    BEGIN
      EXECUTE IMMEDIATE 'SELECT ''YES'', owner FROM sys.dba_tab_columns'||s_db_link||' WHERE table_name = :table_name AND column_name = :column_name AND data_type = :data_type AND ROWNUM = 1'
      INTO sql_rec.psft, sql_rec.psft_schema
      USING IN 'PSSTATUS', IN 'TOOLSREL', IN 'VARCHAR2';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        sql_rec.psft := 'NO';
        sql_rec.psft_schema := NULL;
    END;

    -- io calibration
    IF get_rdbms_release >= 11 THEN
      BEGIN
        EXECUTE IMMEDIATE 'SELECT start_time, end_time, max_iops, max_mbps, max_pmbps, latency, num_physical_disks FROM sys.dba_rsrc_io_calibrate'||s_db_link||' WHERE ROWNUM = 1'
        INTO sql_rec.ioc_start_time, sql_rec.ioc_end_time, sql_rec.ioc_max_iops, sql_rec.ioc_max_mbps, sql_rec.ioc_max_pmbps, sql_rec.ioc_latency, sql_rec.ioc_num_physical_disks;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('** '||SQLERRM);
          write_log('selecting from sys.dba_rsrc_io_calibrate');
      END;

      BEGIN
        EXECUTE IMMEDIATE 'SELECT status, calibration_time FROM v$io_calibration_status'||s_db_link||' WHERE ROWNUM = 1'
        INTO sql_rec.ioc_status, sql_rec.ioc_calibration_time;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('** '||SQLERRM);
          write_log('selecting from v$io_calibration_status');
      END;
    END IF;

    -- materialized views rewrite enabled count
    IF UPPER(get_v$parameter('query_rewrite_enabled')) = 'TRUE' THEN
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM sys.dba_mviews'||s_db_link||' WHERE rewrite_enabled = ''Y''' INTO sql_rec.mat_view_rewrite_enabled_count;
    END IF;
	
    INSERT INTO sqlt$_sql_statement VALUES sql_rec;
    COMMIT; -- AUTONOMOUS_TRANSACTION
    write_log('statid = "'||sql_rec.statid||'"');
    write_log('<- create_statement_workspace');
  END create_statement_workspace;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_input_filename
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE set_input_filename (
    p_statement_id   IN NUMBER,
    p_input_filename IN VARCHAR2 )
  IS
  BEGIN
    IF p_input_filename IS NOT NULL THEN
      UPDATE sqlt$_sql_statement
         SET input_filename = p_input_filename
       WHERE statement_id = p_statement_id;
      COMMIT;
      write_log('input_filename "'||p_input_filename||'" was recorded');
    ELSE
      write_log('input_filename is null');
    END IF;
  END set_input_filename;

  /*************************************************************************************/

  /* -------------------------
   *
   * public upload_sta_files
   *
   * called by: sqlt$i.sql_tuning_advisor
   *
   * ------------------------- */
  PROCEDURE upload_sta_files (
    p_statement_id        IN NUMBER,
    p_report_mem          IN CLOB,
    p_script_mem          IN CLOB,
    p_report_txt          IN CLOB,
    p_script_txt          IN CLOB,
    p_report_awr          IN CLOB,
    p_script_awr          IN CLOB,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_message CLOB;
    l_report CLOB;
    l_script CLOB;
    l_report_size_mem NUMBER := 0;
    l_script_size_mem NUMBER := 0;
    l_report_size_txt NUMBER := 0;
    l_script_size_txt NUMBER := 0;
    l_report_size_awr NUMBER := 0;
    l_script_size_awr NUMBER := 0;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    IF p_report_mem IS NULL AND p_script_mem IS NULL AND p_report_awr IS NULL AND p_script_awr IS NULL THEN
      RETURN;
    END IF;

    write_log('-> upload_sta_files');
    sql_rec := get_statement(p_statement_id);

    l_message :=
    '/*****************************************************************'||LF||
    '* Be aware that using SQL Tuning Advisor (STA) DBMS_SQLTUNE '||LF||
    '* requires a license for the Oracle Tuning Pack.'||LF||
    '* If you need to disable SQLT access to this functionality'||LF||
    '* execute the following command connected as sysdba:'||LF||
    '* SQL> EXEC &&tool_administer_schema..sqlt$a.set_param(''sql_tuning_advisor'', ''N'');'||LF||
    '*****************************************************************/'||LF;

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_report_mem IS NOT NULL THEN
      l_report := l_message||LF||p_report_mem||LF||l_message;
      l_report_size_mem := SYS.DBMS_LOB.GETLENGTH(l_report);
      sql_rec.file_sta_report_mem := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sta_report_mem.txt';

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'STA_REPORT_MEM',
        p_filename     => sql_rec.file_sta_report_mem,
        p_statid       => sql_rec.statid,
        p_file_size    => l_report_size_mem,
        p_file_text    => l_report );

      UPDATE sqlt$_sql_statement
         SET file_sta_report_mem = sql_rec.file_sta_report_mem
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_sta_report_mem||'" was uploaded to repository');
    END IF;

    IF p_script_mem IS NOT NULL AND NVL(INSTR(p_script_mem, 'There are no recommended actions for this task'), 0) = 0 THEN
      l_script := l_message||LF||p_script_mem||LF||l_message;
      l_script_size_mem := SYS.DBMS_LOB.GETLENGTH(l_script);
      sql_rec.file_sta_script_mem := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sta_script_mem.sql';

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'STA_SCRIPT_MEM',
        p_filename     => sql_rec.file_sta_script_mem,
        p_statid       => sql_rec.statid,
        p_file_size    => l_script_size_mem,
        p_file_text    => l_script );

      UPDATE sqlt$_sql_statement
         SET file_sta_script_mem = sql_rec.file_sta_script_mem
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_sta_script_mem||'" was uploaded to repository');
    END IF;

    IF p_report_txt IS NOT NULL THEN
      l_report := l_message||LF||p_report_txt||LF||l_message;
      l_report_size_txt := SYS.DBMS_LOB.GETLENGTH(l_report);
      sql_rec.file_sta_report_txt := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sta_report_txt.txt';

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'STA_REPORT_TXT',
        p_filename     => sql_rec.file_sta_report_txt,
        p_statid       => sql_rec.statid,
        p_file_size    => l_report_size_txt,
        p_file_text    => l_report );

      UPDATE sqlt$_sql_statement
         SET file_sta_report_txt = sql_rec.file_sta_report_txt
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_sta_report_txt||'" was uploaded to repository');
    END IF;

    IF p_script_txt IS NOT NULL AND NVL(INSTR(p_script_txt, 'There are no recommended actions for this task'), 0) = 0 THEN
      l_script := l_message||LF||p_script_txt||LF||l_message;
      l_script_size_txt := SYS.DBMS_LOB.GETLENGTH(l_script);
      sql_rec.file_sta_script_txt := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sta_script_txt.sql';

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'STA_SCRIPT_TXT',
        p_filename     => sql_rec.file_sta_script_txt,
        p_statid       => sql_rec.statid,
        p_file_size    => l_script_size_txt,
        p_file_text    => l_script );

      UPDATE sqlt$_sql_statement
         SET file_sta_script_txt = sql_rec.file_sta_script_txt
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_sta_script_txt||'" was uploaded to repository');
    END IF;

    IF p_report_awr IS NOT NULL THEN
      l_report := l_message||LF||p_report_awr||LF||l_message;
      l_report_size_awr := SYS.DBMS_LOB.GETLENGTH(l_report);
      sql_rec.file_sta_report_awr := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sta_report_awr.txt';

      IF l_report_size_awr <> l_report_size_mem THEN
        set_file (
          p_statement_id => p_statement_id,
          p_file_type    => 'STA_REPORT_AWR',
          p_filename     => sql_rec.file_sta_report_awr,
          p_statid       => sql_rec.statid,
          p_file_size    => l_report_size_awr,
          p_file_text    => l_report );

        UPDATE sqlt$_sql_statement
           SET file_sta_report_awr = sql_rec.file_sta_report_awr
         WHERE statement_id = p_statement_id;

        write_log('"'||sql_rec.file_sta_report_awr||'" was uploaded to repository');
      ELSE -- do not store awr report if awr and mem reports are of the same size
        write_log('"'||sql_rec.file_sta_report_awr||'" was not uploaded to repository. report has same size than memory counterpart');
      END IF;
    END IF;

    IF p_script_awr IS NOT NULL AND NVL(INSTR(p_script_awr, 'There are no recommended actions for this task'), 0) = 0 THEN
      l_script := l_message||LF||p_script_awr||LF||l_message;
      l_script_size_awr := SYS.DBMS_LOB.GETLENGTH(l_script);
      sql_rec.file_sta_script_awr := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_sta_script_awr.sql';

      IF l_report_size_awr <> l_report_size_mem THEN -- compare on report and not script size is intentional
        set_file (
          p_statement_id => p_statement_id,
          p_file_type    => 'STA_SCRIPT_AWR',
          p_filename     => sql_rec.file_sta_script_awr,
          p_statid       => sql_rec.statid,
          p_file_size    => l_script_size_awr,
          p_file_text    => l_script );

        UPDATE sqlt$_sql_statement
           SET file_sta_script_awr = sql_rec.file_sta_script_awr
         WHERE statement_id = p_statement_id;

        write_log('"'||sql_rec.file_sta_script_awr||'" was uploaded to repository');
      ELSE -- do not store awr script if awr and mem reports are of the same size
        write_log('"'||sql_rec.file_sta_script_awr||'" was not uploaded to repository. report has same size than memory counterpart');
      END IF;
    END IF;

    COMMIT;
    write_log('<- upload_sta_files');
  EXCEPTION
    WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error('could not upload sta files to repository');
  END upload_sta_files;

  /*************************************************************************************/

  /* -------------------------
   *
   * public upload_10053_trace
   *
   * called by: sqlt$i.sqlt_common
   *
   * ------------------------- */
  PROCEDURE upload_10053_trace (p_statement_id IN NUMBER)
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
  BEGIN
    write_log('-> upload_10053_trace');
    sql_rec := get_statement(p_statement_id);
    upload_trace (
      p_statement_id => p_statement_id,
      p_file_udump   => sql_rec.file_10053_udump,
      p_file         => sql_rec.file_10053,
      p_file_type    => '10053_EXPLAIN',
      p_statid       => sql_rec.statid );
    write_log('<- upload_10053_trace');
  END upload_10053_trace;

  /*************************************************************************************/

  /* -------------------------
   *
   * public upload_10053_xtract
   *
   * called by: sqlt$i.sqlt_common
   *
   * ------------------------- */
  PROCEDURE upload_10053_xtract (p_statement_id IN NUMBER)
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
  BEGIN
    write_log('-> upload_10053_xtract');
    sql_rec := get_statement(p_statement_id);
    upload_trace (
      p_statement_id => p_statement_id,
      p_file_udump   => sql_rec.file_10053_xtract_udump,
      p_file         => sql_rec.file_10053_xtract,
      p_file_type    => '10053_EXTRACT',
      p_statid       => sql_rec.statid );
    write_log('<- upload_10053_xtract');
  END upload_10053_xtract;

  /*************************************************************************************/

  /* -------------------------
   *
   * public upload_10046_10053_trace
   *
   * called by: sqlt$i.xecute_end
   *
   * ------------------------- */
  PROCEDURE upload_10046_10053_trace (p_statement_id IN NUMBER)
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
  BEGIN
    write_log('-> upload_10046_10053_trace');
    sql_rec := get_statement(p_statement_id);
    upload_trace (
      p_statement_id => p_statement_id,
      p_file_udump   => sql_rec.file_10046_10053_udump,
      p_file         => sql_rec.file_10046_10053,
      p_file_type    => '10046_10053_EXECUTE',
      p_statid       => sql_rec.statid );
    write_log('<- upload_10046_10053_trace');
  END upload_10046_10053_trace;

  /*************************************************************************************/

  /* -------------------------
   *
   * public upload_trca_files
   *
   * called by: sqlt$i.call_trace_analyzer
   *
   * ------------------------- */
  PROCEDURE upload_trca_files (
    p_statement_id        IN NUMBER,
    p_execution_id        IN NUMBER,
    p_file_10046_10053    IN VARCHAR2,
    p_trca_html_report    IN CLOB,
    p_trca_text_report    IN CLOB,
    p_trca_log            IN CLOB,
    p_trca_10046_trace    IN CLOB,
    p_trca_10053_trace    IN CLOB,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> upload_trca_files');
    sql_rec.statid := get_statid(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_trca_html_report IS NOT NULL THEN
      sql_rec.file_trcanlzr_html := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_trca_e'||p_execution_id||'.html';

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'TRCA_HTML',
        p_filename     => sql_rec.file_trcanlzr_html,
        p_statid       => sql_rec.statid,
        p_file_size    => SYS.DBMS_LOB.GETLENGTH(p_trca_html_report),
        p_file_text    => p_trca_html_report );

      UPDATE sqlt$_sql_statement
         SET file_trcanlzr_html = sql_rec.file_trcanlzr_html
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_trcanlzr_html||'" was uploaded to repository');
    END IF;

    IF p_trca_text_report IS NOT NULL THEN
      sql_rec.file_trcanlzr_txt := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_trca_e'||p_execution_id||'.txt';

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'TRCA_TXT',
        p_filename     => sql_rec.file_trcanlzr_txt,
        p_statid       => sql_rec.statid,
        p_file_size    => SYS.DBMS_LOB.GETLENGTH(p_trca_text_report),
        p_file_text    => p_trca_text_report );

      UPDATE sqlt$_sql_statement
         SET file_trcanlzr_txt = sql_rec.file_trcanlzr_txt
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_trcanlzr_txt||'" was uploaded to repository');
    END IF;

    IF p_trca_log IS NOT NULL THEN
      sql_rec.file_trcanlzr_log := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_trca_e'||p_execution_id||'.log';

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'TRCA_LOG',
        p_filename     => sql_rec.file_trcanlzr_log,
        p_statid       => sql_rec.statid,
        p_file_size    => SYS.DBMS_LOB.GETLENGTH(p_trca_log),
        p_file_text    => p_trca_log );

      UPDATE sqlt$_sql_statement
         SET file_trcanlzr_log = sql_rec.file_trcanlzr_log
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_trcanlzr_log||'" was uploaded to repository');
    END IF;

    IF p_trca_10046_trace IS NOT NULL THEN
      sql_rec.file_10046_split := REPLACE(p_file_10046_10053, '_10053');

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'TRACE_10046',
        p_filename     => sql_rec.file_10046_split,
        p_statid       => sql_rec.statid,
        p_file_size    => SYS.DBMS_LOB.GETLENGTH(p_trca_10046_trace),
        p_file_text    => p_trca_10046_trace );

      UPDATE sqlt$_sql_statement
         SET file_10046_split = sql_rec.file_10046_split
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_10046_split||'" was uploaded to repository');
    END IF;

    IF p_trca_10053_trace IS NOT NULL THEN
      sql_rec.file_10053_split := REPLACE(p_file_10046_10053, '_10046');

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'TRACE_10053',
        p_filename     => sql_rec.file_10053_split,
        p_statid       => sql_rec.statid,
        p_file_size    => SYS.DBMS_LOB.GETLENGTH(p_trca_10053_trace),
        p_file_text    => p_trca_10053_trace );

      UPDATE sqlt$_sql_statement
         SET file_10053_split = sql_rec.file_10053_split
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_10053_split||'" was uploaded to repository');
    END IF;

    COMMIT;
    write_log('<- upload_trca_files');
  EXCEPTION
    WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error('could not upload trca files to repository');
  END upload_trca_files;

  /*************************************************************************************/

  /* -------------------------
   *
   * public upload_trca_files_px
   *
   * called by: sqlt$i.call_trace_analyzer_px
   *
   * ------------------------- */
  PROCEDURE upload_trca_files_px (
    p_statement_id        IN NUMBER,
    p_execution_id        IN NUMBER,
    p_trca_html_report    IN CLOB,
    p_trca_text_report    IN CLOB,
    p_trca_log            IN CLOB,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('-> upload_trca_files_px');
    sql_rec.statid := get_statid(p_statement_id);

    IF p_out_file_identifier IS NULL THEN
      l_out_file_identifier := NULL;
    ELSE
      l_out_file_identifier := '_'||p_out_file_identifier;
    END IF;

    IF p_trca_html_report IS NOT NULL THEN
      sql_rec.file_trcanlzr_px_html := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_px_trca_'||p_execution_id||'.html';

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'TRCA_PX_HTML',
        p_filename     => sql_rec.file_trcanlzr_px_html,
        p_statid       => sql_rec.statid,
        p_file_size    => SYS.DBMS_LOB.GETLENGTH(p_trca_html_report),
        p_file_text    => p_trca_html_report );

      UPDATE sqlt$_sql_statement
         SET file_trcanlzr_px_html = sql_rec.file_trcanlzr_px_html
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_trcanlzr_px_html||'" was uploaded to repository');
    END IF;

    IF p_trca_text_report IS NOT NULL THEN
      sql_rec.file_trcanlzr_px_txt := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_px_trca_'||p_execution_id||'.txt';

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'TRCA_PX_TXT',
        p_filename     => sql_rec.file_trcanlzr_px_txt,
        p_statid       => sql_rec.statid,
        p_file_size    => SYS.DBMS_LOB.GETLENGTH(p_trca_text_report),
        p_file_text    => p_trca_text_report );

      UPDATE sqlt$_sql_statement
         SET file_trcanlzr_px_txt = sql_rec.file_trcanlzr_px_txt
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_trcanlzr_px_txt||'" was uploaded to repository');
    END IF;

    IF p_trca_log IS NOT NULL THEN
      sql_rec.file_trcanlzr_px_log := 'sqlt_s'||get_statement_id_c(p_statement_id)||l_out_file_identifier||'_px_trca_'||p_execution_id||'.log';

      set_file (
        p_statement_id => p_statement_id,
        p_file_type    => 'TRCA_PX_LOG',
        p_filename     => sql_rec.file_trcanlzr_px_log,
        p_statid       => sql_rec.statid,
        p_file_size    => SYS.DBMS_LOB.GETLENGTH(p_trca_log),
        p_file_text    => p_trca_log );

      UPDATE sqlt$_sql_statement
         SET file_trcanlzr_px_log = sql_rec.file_trcanlzr_px_log
       WHERE statement_id = p_statement_id;

      write_log('"'||sql_rec.file_trcanlzr_px_log||'" was uploaded to repository');
    END IF;

    COMMIT;
    write_log('<- upload_trca_files_px');
  EXCEPTION
    WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error('could not upload trca files to repository');
  END upload_trca_files_px;

  /*************************************************************************************/

  /* -------------------------
   *
   * private purge_repository
   * 22170172 Add DBMS_ASSERT
   * ------------------------- */
  PROCEDURE purge_repository (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
    l_count2 NUMBER := 0;
	l_table_name varchar2(32767);
  BEGIN
    write_log('purging statement_id = "'||p_statement_id||'"');

    FOR i IN (SELECT t.table_name, c.data_type
                FROM sys.dba_tables t,
                     sys.dba_tab_columns c
               WHERE t.owner = TOOL_REPOSITORY_SCHEMA
                 AND (t.table_name LIKE 'SQLT$%' OR t.table_name LIKE 'SQLI$%')
                 AND t.owner = c.owner
                 AND t.table_name = c.table_name
                 AND c.column_name = 'STATEMENT_ID'
               ORDER BY
                     t.table_name)
    LOOP
	  l_table_name:=DBMS_ASSERT.QUALIFIED_SQL_NAME(i.table_name); -- 22170172
      l_count2 := l_count2 + 1;
      IF i.data_type = 'NUMBER' THEN
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||l_table_name||' WHERE statement_id = :statement_id' INTO l_count USING IN p_statement_id;
        EXECUTE IMMEDIATE 'DELETE '||l_table_name||' WHERE statement_id = :statement_id' USING IN p_statement_id;
        write_log(LPAD(l_count, 8)||' rows deleted from '||i.table_name);
      ELSE
        EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||l_table_name||' WHERE statement_id = :statement_id' INTO l_count USING IN get_statement_id_c(p_statement_id);
        EXECUTE IMMEDIATE 'DELETE '||l_table_name||' WHERE statement_id = :statement_id' USING IN get_statement_id_c(p_statement_id);
        write_log(LPAD(l_count, 8)||' rows deleted from '||i.table_name);
      END IF;
    END LOOP;

    FOR i IN (SELECT t.table_name
                FROM sys.dba_tables t,
                     sys.dba_tab_columns c
               WHERE t.owner = TOOL_REPOSITORY_SCHEMA
                 AND (t.table_name LIKE 'SQLT$%' OR t.table_name LIKE 'SQLI$%')
                 AND t.owner = c.owner
                 AND t.table_name = c.table_name
                 AND c.column_name = 'STATID'
                 AND NOT EXISTS (
              SELECT NULL
                FROM sys.dba_tab_columns c2
               WHERE t.owner = c2.owner
                 AND t.table_name = c2.table_name
                 AND c2.column_name = 'STATEMENT_ID')
               ORDER BY
                     t.table_name)
    LOOP
	  l_table_name:=DBMS_ASSERT.QUALIFIED_SQL_NAME(i.table_name); -- 22170172
      l_count2 := l_count2 + 1;
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM '||l_table_name||' WHERE statid LIKE ''%''||:statid||''%''' INTO l_count USING IN p_statement_id;
      EXECUTE IMMEDIATE 'DELETE '||l_table_name||' WHERE statid LIKE ''%''||:statid||''%''' USING IN p_statement_id;
      write_log(LPAD(l_count, 8)||' rows deleted from '||i.table_name);
    END LOOP;

    l_count2 := l_count2 + 1;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM SQLI$_STGTAB_SQLPROF' INTO l_count;
    EXECUTE IMMEDIATE 'DELETE SQLI$_STGTAB_SQLPROF';
    write_log(LPAD(l_count, 8)||' rows deleted from SQLI$_STGTAB_SQLPROF');

    l_count2 := l_count2 + 1;
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM SQLI$_STGTAB_SQLSET' INTO l_count;
    EXECUTE IMMEDIATE 'DELETE SQLI$_STGTAB_SQLSET';
    write_log(LPAD(l_count, 8)||' rows deleted from SQLI$_STGTAB_SQLSET');

    COMMIT;
    write_log(l_count2||' tables were purged for statement_id = "'||p_statement_id||'"');
  END purge_repository;

  /*************************************************************************************/

  /* -------------------------
   *
   * public delete_sqltxplain_stats
   *
   * called by sqlt/install/sqcpkg.sl and sqlt$a.truncate_repository
   *
   * ------------------------- */
  PROCEDURE delete_sqltxplain_stats
  IS
  BEGIN
    write_log('-> delete_sqltxplain_stats');
    SYS.DBMS_STATS.DELETE_SCHEMA_STATS(TOOL_REPOSITORY_SCHEMA, no_invalidate => FALSE, force => TRUE);
    SYS.DBMS_STATS.LOCK_SCHEMA_STATS(TOOL_REPOSITORY_SCHEMA);
    write_log('<- delete_sqltxplain_stats');
  END delete_sqltxplain_stats;

  /*************************************************************************************/

  /* -------------------------
   *
   * private truncate_repository
   *
   * ------------------------- */
  PROCEDURE truncate_repository
  IS
    l_count NUMBER := 0;
  BEGIN
    write_log('purging repository');

    FOR i IN (SELECT table_name
                FROM sys.dba_tables
               WHERE owner = TOOL_REPOSITORY_SCHEMA
                 AND (table_name LIKE 'SQLT$%' OR table_name LIKE 'SQLI$%')
                 AND table_name NOT IN ('SQLI$_CLOB', 'SQLI$_PARAMETER', 'SQLI$_SESS_PARAMETER')
               ORDER BY
                     table_name)
    LOOP
      l_count := l_count + 1;
      -- cannot truncate since it would need DROP ANY TABLE system privilege
      -- execute_immediate('TRUNCATE TABLE '||TOOL_REPOSITORY_SCHEMA||'.'||i.table_name); errors with new security model
      execute_immediate('DELETE '||DBMS_ASSERT.QUALIFIED_SQL_NAME(TOOL_REPOSITORY_SCHEMA||'.'||i.table_name));
    END LOOP;

    write_log(l_count||' tables were deleted');
    delete_sqltxplain_stats;
  END truncate_repository;

  /*************************************************************************************/

  /* -------------------------
   *
   * public purge_repository
   *
   * ------------------------- */
  PROCEDURE purge_repository (
    p_statement_id_from IN NUMBER,
    p_statement_id_to   IN NUMBER )
  IS
    l_statement_id_from NUMBER;
    l_statement_id_to   NUMBER;
    l_statement_id_min  NUMBER;
    l_statement_id_max  NUMBER;
    l_count1 NUMBER;
    l_count2 NUMBER;
  BEGIN
    IF p_statement_id_from IS NULL OR p_statement_id_to IS NULL OR p_statement_id_from > p_statement_id_to THEN
      write_log('invalid requested range');
      RETURN;
    END IF;

    SELECT COUNT(*)
      INTO l_count1
      FROM sqlt$_sql_statement;

    SELECT MIN(statement_id), MAX(statement_id), COUNT(*)
      INTO l_statement_id_min, l_statement_id_max, l_count2
      FROM sqlt$_sql_statement
     WHERE USER IN ('SYS', 'SYSTEM', TOOL_ADMINISTER_SCHEMA, username);

    IF l_statement_id_min IS NULL OR l_statement_id_max IS NULL THEN
      write_log('repository is empty');
      RETURN;
    END IF;

    SELECT MIN(statement_id)
      INTO l_statement_id_from
      FROM sqlt$_sql_statement
     WHERE statement_id >= p_statement_id_from
       AND USER IN ('SYS', 'SYSTEM', TOOL_ADMINISTER_SCHEMA, username);

    SELECT MAX(statement_id)
      INTO l_statement_id_to
      FROM sqlt$_sql_statement
     WHERE statement_id <= p_statement_id_to
       AND USER IN ('SYS', 'SYSTEM', TOOL_ADMINISTER_SCHEMA, username);

    IF l_statement_id_from IS NULL OR l_statement_id_to IS NULL OR l_statement_id_from > l_statement_id_to THEN
      write_log('nothing to purge within range requested');
      RETURN;
    END IF;

    IF l_count1 = l_count2 AND l_statement_id_from = l_statement_id_min AND l_statement_id_to = l_statement_id_max THEN
      truncate_repository;
    ELSE
      FOR i IN (SELECT DISTINCT statement_id
                  FROM sqlt$_sql_statement
                 WHERE statement_id >= l_statement_id_from
                   AND statement_id <= l_statement_id_to
                   AND USER IN ('SYS', 'SYSTEM', TOOL_ADMINISTER_SCHEMA, username)
                 ORDER BY
                       statement_id)
      LOOP
        purge_repository(i.statement_id);
      END LOOP;
    END IF;
  END purge_repository;

  /*************************************************************************************/

  /* -------------------------
   *
   * public import_cbo_stats
   *
   * called by sqlt/utl/sqltimp.sql and restore.sql
   * 22170172 add DBMS_ASSERT
   * ------------------------- */
  PROCEDURE import_cbo_stats (
    p_statement_id IN VARCHAR2,
    p_schema_owner IN VARCHAR2,
    p_include_bk   IN VARCHAR2 DEFAULT 'Y',
    p_make_bk      IN VARCHAR2 DEFAULT 'N',
    p_load_hist    IN VARCHAR2 DEFAULT 'N',
    p_table_name   IN VARCHAR2 DEFAULT NULL,
    p_column_name  IN VARCHAR2 DEFAULT NULL )
  IS
    l_statement_id    NUMBER;
    l_hist_stats      NUMBER;
    l_cnt_d_tab_hist  NUMBER;
    l_cnt_d_head_hist NUMBER;
    l_cnt_d_hgrm_hist NUMBER;
    l_cnt_d_ind_hist  NUMBER;
    l_cnt_i_tab_hist  NUMBER;
    l_cnt_i_head_hist NUMBER;
    l_cnt_i_hgrm_hist NUMBER;
    l_cnt_i_ind_hist  NUMBER;
    l_object_type     VARCHAR2(257);
    l_statid          sqlt$_stattab.statid%TYPE;
    l_statid_backup   sqlt$_stattab.statid%TYPE;
    l_schema_owner    VARCHAR2(32767);
    l_user_id         NUMBER;
    l_object_id       NUMBER;
    l_column_id       NUMBER;
    l_prior_obj#      NUMBER;
    l_prior_intcol#   NUMBER;
    l_column_name     VARCHAR2(257);
    l_index_name      VARCHAR2(257);
    my_owner          sys.dba_objects.owner%TYPE;
    my_count          INTEGER;
    stats_rows1       INTEGER := 0;
    tables1           INTEGER := 0;
    indexes1          INTEGER := 0;
    columns1          INTEGER := 0;
    tables1p          INTEGER := 0;
    indexes1p         INTEGER := 0;
    columns1p         INTEGER := 0;
    tables1s          INTEGER := 0;
    indexes1s         INTEGER := 0;
    columns1s         INTEGER := 0;
	columns1e         INTEGER := 0;  -- 150828 All Extensions are Virtual Columns so the E type only show up one time per column regardless partition scheme and its stats are in C type
    system1           INTEGER := 0;
    avg_age_days1     NUMBER  := 0;
    stats_rows2       INTEGER := 0;
    tables2           INTEGER := 0;
    indexes2          INTEGER := 0;
    columns2          INTEGER := 0;
    tables2p          INTEGER := 0;
    indexes2p         INTEGER := 0;
    columns2p         INTEGER := 0;
    tables2s          INTEGER := 0;
    indexes2s         INTEGER := 0;
    columns2s         INTEGER := 0;
	columns2e         INTEGER := 0;  -- 150828 All Extensions are Virtual Columns	
    system2           INTEGER := 0;
    avg_age_days2     NUMBER  := 0;
    stats_rows3       VARCHAR2(10) := NULL;
    tables3           VARCHAR2(10) := NULL;
    indexes3          VARCHAR2(10) := NULL;
    columns3          VARCHAR2(10) := NULL;
    tables3p          VARCHAR2(10) := NULL;
    indexes3p         VARCHAR2(10) := NULL;
    columns3p         VARCHAR2(10) := NULL;
    tables3s          VARCHAR2(10) := NULL;
    indexes3s         VARCHAR2(10) := NULL;
    columns3s         VARCHAR2(10) := NULL;
	columns3e         VARCHAR2(10) := NULL;  -- 150828 All Extensions are Virtual Columns	
    system3           VARCHAR2(10) := NULL;
    avg_age_days3     VARCHAR2(10) := NULL;
    my_table          VARCHAR2(32767);
    can_access_wri    BOOLEAN;
    l_skip_timestamp  TIMESTAMP(6) WITH TIME ZONE; -- date in past up to where we can "see" statistics history
    l_save_timestamp  TIMESTAMP(6) WITH TIME ZONE;
    l_version         NUMBER := NULL;
    l_insert_list     VARCHAR2(32767);
    l_select_list     VARCHAR2(32767);
    l_sql             VARCHAR2(32767);

  BEGIN
    -- finds statid according to partial or full name
    BEGIN
      l_statid := LOWER(p_statement_id);

      IF p_include_bk = 'Y' THEN
        SELECT COUNT(DISTINCT statid)
          INTO my_count
          FROM sqlt$_stattab
         WHERE LOWER(statid) LIKE '%'||l_statid||'%'
           AND statid LIKE 's%';
      ELSE
        SELECT COUNT(DISTINCT statid)
          INTO my_count
          FROM sqlt$_stattab
         WHERE LOWER(statid) LIKE '%'||l_statid||'%'
           AND statid LIKE 's%'
           AND statid NOT LIKE '%_BK_20%';
      END IF;

      IF my_count < 1 THEN
        put_line('statement id "'||p_statement_id||'" was not found on sqlt$_stattab table');
        --RETURN;
      END IF;

      IF my_count > 1 THEN
        put_line('statement id "'||p_statement_id||'" is not unique on sqlt$_stattab table');
        RETURN;
      END IF;

      IF my_count = 1 THEN
        -- reset l_statid
        IF p_include_bk = 'Y' THEN
          SELECT statid
            INTO l_statid
            FROM sqlt$_stattab
           WHERE LOWER(statid) LIKE '%'||l_statid||'%'
             AND statid LIKE 's%'
             AND ROWNUM = 1;
        ELSE
          SELECT statid
            INTO l_statid
            FROM sqlt$_stattab
           WHERE LOWER(statid) LIKE '%'||l_statid||'%'
             AND statid LIKE 's%'
             AND statid NOT LIKE '%_BK_20%'
             AND ROWNUM = 1;
        END IF;
      END IF;

      IF my_count = 0 THEN
        SELECT COUNT(DISTINCT statid)
          INTO my_count
          FROM sqlt$_sql_statement
         WHERE LOWER(statid) LIKE '%'||l_statid||'%'
           AND statid LIKE 's%';

        IF my_count < 1 THEN
          put_line('statement id "'||p_statement_id||'" was not found on sqlt$_sql_statement table');
          RETURN;
        END IF;

        IF my_count > 1 THEN
          put_line('statement id "'||p_statement_id||'" is not unique on sqlt$_sql_statement table');
          RETURN;
        END IF;

        IF my_count = 1 THEN
          -- reset l_statid
          SELECT statid
            INTO l_statid
            FROM sqlt$_sql_statement
           WHERE LOWER(statid) LIKE '%'||l_statid||'%'
             AND statid LIKE 's%'
             AND ROWNUM = 1;
        END IF;
      END IF;
    END;

    -- get l_statement_id
    BEGIN
      SELECT statement_id
        INTO l_statement_id
        FROM sqlt$_sql_statement
       WHERE statid = l_statid;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        put_line('sqlt$_sql_statement missing for '||l_statid);
    END;

    -- possible remap
    -- 22170172
	-- 170909
    l_schema_owner := TRIM(DBMS_ASSERT.QUALIFIED_SQL_NAME(NVL(p_schema_owner,'NULL'))); -- NULL means no remap

    -- verify if passed schema owner is valid
    IF UPPER(l_schema_owner) <> 'NULL' THEN
      SELECT COUNT(*)
        INTO my_count
        FROM sys.dba_users
       WHERE username = l_schema_owner;

      IF my_count = 0 THEN
        SELECT COUNT(*)
          INTO my_count
          FROM sys.dba_users
         WHERE username = UPPER(l_schema_owner);

        IF my_count > 0 THEN
          l_schema_owner := UPPER(l_schema_owner);
        END IF;
      END IF;

      IF my_count = 0 THEN
        put_line('schema owner "'||p_schema_owner||'" was not found');
        RETURN;
      END IF;

      SELECT user_id
        INTO l_user_id
        FROM sys.dba_users
       WHERE username = l_schema_owner;

      put_line('remapping stats into user '||l_schema_owner||'('||l_user_id||')');
    END IF;

    -- clean staging table since we need to delete mismatches before import
    -- be aware this table does not support concurrency
    -- restore script performs a truncate before getting here
    DELETE sqli$_stattab_temp;

    -- computes THIS system stats staging table version
    BEGIN
      put_line('obtain statistics staging table version for this system');
      DELETE sqli$_stattab_temp WHERE statid = 'S00000';
      SYS.DBMS_STATS.GATHER_TABLE_STATS(TOOL_REPOSITORY_SCHEMA, 'SQLI$_STATTAB_TEMP', estimate_percent => 0.000001, force => TRUE);
      SYS.DBMS_STATS.EXPORT_TABLE_STATS(TOOL_REPOSITORY_SCHEMA, 'SQLI$_STATTAB_TEMP', statown => TOOL_REPOSITORY_SCHEMA, stattab => 'SQLI$_STATTAB_TEMP', statid => 'S00000');
      SELECT version INTO l_version FROM sqli$_stattab_temp WHERE statid = 'S00000' AND type = 'T' AND ROWNUM = 1;
      put_line('statistics version for this system: '||l_version);
      DELETE sqli$_stattab_temp WHERE statid = 'S00000';
      SYS.DBMS_STATS.DELETE_TABLE_STATS(TOOL_REPOSITORY_SCHEMA, 'SQLI$_STATTAB_TEMP', force => TRUE);
    EXCEPTION
      WHEN OTHERS THEN
        put_line(SQLERRM);
    END;

    -- will create a backup of stats from dictonary before restore
    l_statid_backup := RPAD(l_statid, 12)||'_BK_'||TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');

    -- there should be no rows here, unless user has tried an import on less than 1 sec!
    DELETE sqlt$_stattab WHERE statid = l_statid_backup;

    -- seeds staging table so we don't change source

    /*
    INSERT /*+ APPEND /
    INTO sqli$_stattab_temp
    SELECT /*+ FULL(s) / *
    FROM sqlt$_stattab s
    WHERE s.statid = l_statid
    AND s.type IN ('C', 'I', 'T');
    */

    sqlt$d.get_list_of_columns (
      p_source_owner      => TOOL_REPOSITORY_SCHEMA,
      p_source_table      => 'sqlt$_stattab',
      p_source_alias      => 's',
      p_destination_owner => TOOL_REPOSITORY_SCHEMA,
      p_destination_table => 'sqli$_stattab_temp',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

	--150828 Include Extensions
    l_sql :=
    'INSERT /*+ APPEND */ INTO sqli$_stattab_temp (statid'||
    l_insert_list||') SELECT /*+ FULL(s) PARALLEL */ s.statid'||
    l_select_list||' FROM sqlt$_stattab s '||
    'WHERE s.statid = :statid AND s.type IN (''C'', ''I'', ''T'',''E'')';

    IF UPPER(l_schema_owner) <> 'NULL' THEN
      l_sql := REPLACE(l_sql, 's.c5', ''''||l_schema_owner||''' c5');
    END IF;

    BEGIN
      EXECUTE IMMEDIATE l_sql USING IN l_statid;
    EXCEPTION
      WHEN OTHERS THEN
        put_line(SQLERRM);
        put_line(l_sql);
        RETURN;
    END;

    COMMIT; -- avoids ORA-12838: cannot read/modify an object after modifying it in parallel

    -- gather stats after load (use defaults)
    SYS.DBMS_STATS.GATHER_TABLE_STATS(TOOL_REPOSITORY_SCHEMA, 'SQLI$_STATTAB_TEMP', force => TRUE);

    /* too slow. replaced with dynamic SQL above
    IF UPPER(l_schema_owner) <> 'NULL' THEN
      UPDATE sqli$_stattab_temp
         SET c5 = l_schema_owner
       WHERE statid = l_statid
         AND type IN ('C', 'I', 'T','E');
    END IF;

    COMMIT;
    */

/*
     what is each column?
        As per http://skdba.blogspot.com/2006/06/keeping-history-of-cbo-stats.html

        STATID   User defined stat id

        TYPE     T=Table      I=Index                    C=Column                   E=Extension
        C1       Table_Name   Index_Name                 Table_Name                 Table_Name
        C2       Null         Null                       Null
        C3       Null         Null                       Null
        C4       Null         Null                       Column_Name                Column Group Name
        C5       Owner        Owner                      Owner                      Owner
        N1       Num_Rows     Num_Rows                   Num_distinct
        N2       Blocks       Leaf_Blocks                Density
        N3       Avg_Row_Len  Distinct_Keys              ????????
        N4       Sample_Size  Avg_Leaf_Blocks_per_key    Sample_Size
        N5       Null         Avg_Data_Blocks_per_key    Num_Nulls
        N6       Null         Clustering_Factor          First Endpoint_Value
        N7       Null         Blevel                     Last Endpoint_Value
        N8       Null         Sample_Size                Avg_Col_Len
        N9       Null         pct_direct_access          Histogram Flag
        N10      Null         Null                       Endpoint_Number
        N11      Null         Null                       Endpoint_Value
        N12      Null         Null                       Null
        R1       Null         Null                       High_Value
        R2       Null         Null                       Low_value
        CH1      Null         Null                       Endpoint_Actual_Value
		CL1      Null         Null                       "Default Value"?         Column Group Expression

        tables (see sqlt$_dba_tab_statistics_v)
        type = 'T'
        c5 owner,
        c1 table_name,
        c2 partition_name,
        c3 subpartition_name,
        n1 num_rows,
        n2 blocks,
        n3 avg_row_len,
        n4 sample_size,
        d1 last_analyzed,
        DECODE(BITAND(flags, 2), 0, 'NO', 'YES') global_stats,
        DECODE(BITAND(flags, 1), 0, 'NO', 'YES') user_stats

        indexes (see sqlt$_dba_ind_statistics_v)
        type = 'I'
        c5 owner,
        c1 index_name,
        c2 partition_name,
        c3 subpartition_name,
        n7 blevel,
        n2 leaf_blocks,
        n3 distinct_keys,
        n4 avg_leaf_blocks_per_key,
        n5 avg_data_blocks_per_key,
        n6 clustering_factor,
        n1 num_rows,
        n8 sample_size,
        d1 last_analyzed,
        DECODE(BITAND(flags, 2), 0, 'NO', 'YES') global_stats,
        DECODE(BITAND(flags, 1), 0, 'NO', 'YES') user_stats

        columns (see sqlt$_dba_tab_col_statistics_v)
        type = 'C'
        c5 owner,
        c1 table_name,
        c2 partition_name,
        c3 subpartition_name,
        c4 column_name,
        n1 num_distinct,
        n6 low_value,
        n7 high_value,
        n2 density,
        n5 num_nulls,
        d1 last_analyzed,
        n4 sample_size,
        DECODE(BITAND(flags, 2), 0, 'NO', 'YES') global_stats,
        DECODE(BITAND(flags, 1), 0, 'NO', 'YES') user_stats,
        n8 avg_col_len
        cl1 data_default

        extended stats (see sqlt$_dba_tab_col_statistics_v)
        type = 'E'
        c5 owner,
        c1 table_name,
        c2 partition_name,
        c3 subpartition_name,
        c4 column_name,
        n1 num_distinct,
        n6 low_value,
        n7 high_value,
        n2 density,
        n5 num_nulls,
        d1 last_analyzed,
        n4 sample_size,
        DECODE(BITAND(flags, 2), 0, 'NO', 'YES') global_stats,
        DECODE(BITAND(flags, 1), 0, 'NO', 'YES') user_stats,
        n8 avg_col_len
        cl1 data_default
    */

    -- when a table is passed as parameter then it deletes from temp all other tables, their indexes and columns
    IF p_table_name IS NOT NULL THEN
      -- delete all other tables
      DELETE sqli$_stattab_temp
       WHERE type = 'T'
         AND c1 <> p_table_name;

      -- delete all columns for all other tables
      DELETE sqli$_stattab_temp
       WHERE type = 'C'
         AND c1 <> p_table_name;

      IF p_column_name IS NULL THEN
        -- finds all indexes for this table
        FOR i IN (SELECT index_name
                    FROM sys.dba_indexes
                   WHERE table_owner = l_schema_owner
                     AND table_name = p_table_name)
        LOOP
          -- flag indexes for this table so they are not deleted
          UPDATE sqli$_stattab_temp
             SET type = 'X'
           WHERE type = 'I'
             AND c1 = i.index_name;
        END LOOP;

        -- delete all indexes not for this table
        DELETE sqli$_stattab_temp
         WHERE type = 'I';

        -- reset flag for indexes from this table
        UPDATE sqli$_stattab_temp
           SET type = 'I'
         WHERE type = 'X';
      ELSE -- if a column is passed then delete all indexes and all other columns
        -- delete all columns other than passed
        DELETE sqli$_stattab_temp
         WHERE type = 'C'
           AND c4 <> p_column_name;

        -- delete all indexes
        DELETE sqli$_stattab_temp
         WHERE type = 'I';
      END IF;
    END IF; -- p_table_name IS NOT NULL

    -- captures metrics in file
    my_count := 0;
    FOR i IN (SELECT c2, c3, type, d1 FROM sqli$_stattab_temp s WHERE s.statid = l_statid)
    LOOP
      IF i.c2 IS NULL THEN -- partition_name
        IF i.type = 'C' THEN
          columns1 := columns1 + 1;
          stats_rows1 := stats_rows1 + 1;
        ELSIF i.type = 'I' THEN
          indexes1 := indexes1 + 1;
          stats_rows1 := stats_rows1 + 1;
        ELSIF i.type = 'T' THEN
          tables1 := tables1 + 1;
          stats_rows1 := stats_rows1 + 1;
          IF i.d1 IS NOT NULL THEN
            my_count := my_count + 1;
            avg_age_days1 := avg_age_days1 + (SYSDATE - i.d1);
          END IF;
		ELSIF i.type = 'E' THEN -- 150828 Extensions are only valid at Table level.
		  columns1e:=columns1e+1;
        END IF;
      ELSIF i.c3 IS NULL THEN -- subpartition_name
        IF i.type = 'C' THEN
          columns1p := columns1p + 1;
          stats_rows1 := stats_rows1 + 1;
        ELSIF i.type = 'I' THEN
          indexes1p := indexes1p + 1;
          stats_rows1 := stats_rows1 + 1;
        ELSIF i.type = 'T' THEN
          tables1p := tables1p + 1;
          stats_rows1 := stats_rows1 + 1;
          IF i.d1 IS NOT NULL THEN
            my_count := my_count + 1;
            avg_age_days1 := avg_age_days1 + (SYSDATE - i.d1);
          END IF;
        END IF;
      ELSE
        IF i.type = 'C' THEN
          columns1s := columns1s + 1;
          stats_rows1 := stats_rows1 + 1;
        ELSIF i.type = 'I' THEN
          indexes1s := indexes1s + 1;
          stats_rows1 := stats_rows1 + 1;
        ELSIF i.type = 'T' THEN
          tables1s := tables1s + 1;
          stats_rows1 := stats_rows1 + 1;
          IF i.d1 IS NOT NULL THEN
            my_count := my_count + 1;
            avg_age_days1 := avg_age_days1 + (SYSDATE - i.d1);
          END IF;
        END IF;
      END IF;
    END LOOP;
    IF my_count > 0 THEN
      avg_age_days1 := ROUND(avg_age_days1 / my_count, 1);
    END IF;

    -- renaming schema owner in case user did not provide schema name, but there is only one object with that name and it has a different owner
    IF l_schema_owner = 'NULL' THEN
      FOR i IN (SELECT DISTINCT
                       s.type, s.c5, s.c1,
                       DECODE(s.type, 'T', 'TABLE', 'I', 'INDEX','OTHER') object_type,
                       s.c5 owner,
                       s.c1 object_name
                  FROM sqli$_stattab_temp s
                 WHERE s.statid = l_statid
                   AND s.c5 IS NOT NULL
                   AND type IN ('T', 'I')
                 ORDER BY
                       s.type DESC,
                       s.c5, s.c1)
      LOOP
        SELECT COUNT(*), MIN(owner)
          INTO my_count, my_owner
          FROM sys.dba_objects
         WHERE object_type = i.object_type
           AND object_name = i.object_name;

        IF my_count = 1 THEN -- there is only one object with that name
          IF my_owner = i.owner THEN
            put_line('about to restore stats for '||i.object_type||' '||i.owner||'.'||i.object_name);
          ELSE -- it has a different owner
            put_line('remapping '||i.object_type||' '||i.object_name||' from '||i.owner||' to '||my_owner);
            UPDATE sqli$_stattab_temp
               SET c5 = my_owner
             WHERE statid = l_statid
               AND type = i.type
               AND c5 = i.c5
               AND c1 = i.c1;
            IF i.type = 'T' THEN -- 150828 table columns and extensions
              UPDATE sqli$_stattab_temp
                 SET c5 = my_owner
               WHERE statid = l_statid
                 AND type in ('C','E')
                 AND c5 = i.c5
                 AND c1 = i.c1;
            END IF;
          END IF;
        ELSIF my_count < 1 THEN -- object does not exist in data dict
          put_line('skipping object missing from dict: '||i.object_type||' '||i.object_name);
          DELETE sqli$_stattab_temp
           WHERE statid = l_statid
             AND type = i.type
             AND c5 = i.c5
             AND c1 = i.c1;
          IF i.type = 'T' THEN -- table columns
            DELETE sqli$_stattab_temp
             WHERE statid = l_statid
               AND type = 'C'
               AND c5 = i.c5
               AND c1 = i.c1;
          END IF;
        ELSIF my_count > 1 THEN -- object exists more than once in data dict (different owners)
          put_line('object found '||my_count||' times in dict: '||i.object_type||' '||i.object_name);
          SELECT COUNT(*)
            INTO my_count
            FROM sys.dba_objects
           WHERE object_type = i.object_type
             AND object_name = i.object_name
             AND owner = i.owner;
          IF my_count = 1 THEN -- one of the owners is the same as the stats to be imported
            put_line('about to restore stats for '||i.object_type||' '||i.owner||'.'||i.object_name);
          ELSIF my_count < 1 THEN -- none of the owners of this object correpond to owner of stats to be imported
            put_line('skipping object missing from dict: '||i.object_type||' '||i.owner||'.'||i.object_name);
            DELETE sqli$_stattab_temp
             WHERE statid = l_statid
               AND type = i.type
               AND c5 = i.c5
               AND c1 = i.c1;
            IF i.type = 'T' THEN -- table columns
              DELETE sqli$_stattab_temp
               WHERE statid = l_statid
                 AND type = 'C'
                 AND c5 = i.c5
                 AND c1 = i.c1;
            END IF;
          END IF;
        END IF;
      END LOOP;
    END IF; -- l_schema_owner = 'NULL'

    -- gather stats after load (after possible changes)
    --SYS.DBMS_STATS.GATHER_TABLE_STATS(TOOL_REPOSITORY_SCHEMA, 'SQLI$_STATTAB_TEMP', force => TRUE);

    -- verify each table exists on target system
    FOR i IN (SELECT DISTINCT
                     c5 owner,
                     c1 table_name
                FROM sqli$_stattab_temp
               WHERE statid = l_statid
                 AND type = 'T'
               ORDER BY
                     c5, c1)
    LOOP
      -- check if table exists
      SELECT COUNT(*)
        INTO my_count
        FROM sys.dba_tables
       WHERE owner = i.owner
         AND table_name = i.table_name;

      -- tables not-found must go, else the import fails
      IF my_count = 0 THEN
        put_line('skipping table missing from dict: '||i.owner||'.'||i.table_name);
        DELETE sqli$_stattab_temp
         WHERE statid = l_statid
           AND type IN ('T', 'C') -- table and table columns
           AND c5 = i.owner
           AND c1 = i.table_name;
      END IF;
    END LOOP;

    -- verify each index exists on target system
    FOR i IN (SELECT DISTINCT
                     c5 owner,
                     c1 index_name
                FROM sqli$_stattab_temp
               WHERE statid = l_statid
                 AND type = 'I'
               ORDER BY
                     c5, c1)
    LOOP
      -- check if index exists
      SELECT COUNT(*)
        INTO my_count
        FROM sys.dba_indexes
       WHERE owner = i.owner
         AND index_name = i.index_name;

      -- indexes not-found, check if it's coming from IOT 
      IF my_count = 0 THEN
	     
         l_index_name := get_target_iot_index_name(
           p_statement_id       => l_statement_id,
           p_target_owner       => i.owner,
           p_index_name         => i.index_name);
		 
         -- index coming from IOT, remap it
         IF l_index_name IS NOT NULL THEN
            put_line('remap IOT index: '||i.owner||'.'||i.index_name||' to '||l_index_name);
            UPDATE sqli$_stattab_temp
              SET c1 = l_index_name
            WHERE statid = l_statid
              AND type = 'I'
              AND c1 = i.index_name
              AND c5 = i.owner;	
         -- not an IOT so must go, else the import fails			 
         ELSE
            put_line('skipping index missing from dict: '||i.owner||'.'||i.index_name);
            DELETE sqli$_stattab_temp
             WHERE statid = l_statid
               AND type = 'I'
               AND c5 = i.owner
               AND c1 = i.index_name;
         END IF;
      END IF;
	  
    END LOOP;

    -- verify every table-column exists on target system
    FOR i IN (SELECT DISTINCT
                     c5 owner,
                     c1 table_name,
                     c4 column_name
                FROM sqli$_stattab_temp
               WHERE statid = l_statid
                 AND type = 'C'
               ORDER BY
                     c5, c1, c4)
    LOOP
      -- gets column_name as per possible remap
	  if i.column_name like 'SYS_ST%' then -- 150828 Extensions are created by the import automatically, no need to check for pre-existant
	   l_column_name :=i.column_name;
	  ELSE
       l_column_name := get_target_column_name (
        p_statement_id       => l_statement_id,
        p_target_owner       => i.owner,
        p_table_name         => i.table_name,
        p_source_column_name => i.column_name );
	  END IF;

      IF l_column_name IS NOT NULL THEN
        IF l_column_name <> i.column_name THEN
          put_line('remap column: '||i.owner||'.'||i.table_name||'.'||i.column_name||' to '||l_column_name);
          UPDATE sqli$_stattab_temp
             SET c4 = l_column_name,
                 n12 = -666 -- n12 is used as staging flag when a column has been renamed (avoids a -> b -> c)
           WHERE statid = l_statid
             AND type = 'C'
             AND c5 = i.owner
             AND c1 = i.table_name
             AND c4 = i.column_name
             AND n12 IS NULL; -- n12 is used as staging flag when a column has been renamed (avoids a -> b -> c)
        END IF;
      ELSE -- column_name is null
        put_line('skipping column missing from dict: '||i.owner||'.'||i.table_name||'.'||i.column_name);
        DELETE sqli$_stattab_temp
         WHERE statid = l_statid
           AND type = 'C'
           AND c5 = i.owner
           AND c1 = i.table_name
           AND c4 = i.column_name;
      END IF;
    END LOOP;

    -- resets n12 back to null for renamed columns. this flag avoids a column being renamed twice (chain)
    UPDATE sqli$_stattab_temp
       SET n12 = NULL
     WHERE statid = l_statid
       AND type = 'C'
       AND n12 = -666;

    put_line('+-----+');

    -- checks cbo stats table version
    IF l_version IS NOT NULL THEN
      put_line('upgrade/downgrade of sqli$_stattab_temp to version '||l_version||' as per this system');
      UPDATE sqli$_stattab_temp SET version = l_version WHERE version IS NULL OR version <> l_version; -- all rows
    ELSE
      -- imported stats from 9i and 10g have version of 4. 11g is version 5 (new column cl1 for extended stats)
	  if get_rdbms_version >='12.1' then  -- 150828 12c uses 7
	    l_version := 7;
      ELSIF get_rdbms_version >= '11.2.0.2' THEN -- 11.2.0.2 uses version 6
        l_version := 6;
      ELSIF get_rdbms_release >= 11 THEN
        l_version := 5;
      ELSE -- 10g
        l_version := 4;
      END IF;

      put_line('upgrade/downgrade of sqli$_stattab_temp to version '||l_version||' as per '||get_rdbms_version);
      UPDATE sqli$_stattab_temp SET version = l_version WHERE version IS NULL OR version <> l_version; -- all rows
      /*
      BEGIN
        put_line('executing SYS.DBMS_STATS.UPGRADE_STAT_TABLE on sqli$_stattab_temp (OK to fail)');
        SYS.DBMS_STATS.UPGRADE_STAT_TABLE(TOOL_REPOSITORY_SCHEMA, 'sqli$_stattab_temp');
      EXCEPTION
        WHEN OTHERS THEN
          put_line(SQLERRM);
      END;
      */
    END IF;

    -- gather stats after load (after possible changes)
    --SYS.DBMS_STATS.GATHER_TABLE_STATS(TOOL_REPOSITORY_SCHEMA, 'SQLI$_STATTAB_TEMP', force => TRUE);

    -- imports CBO stats for "cleaned" tables, one by one
    -- put_line('doing a backup of all related stats into statid '||l_statid_backup||'.');
	-- 150828 set statid null to avoid a bug in the import on extensions.
	update sqli$_stattab_temp set statid = null where statid = l_statid;
    FOR i IN (SELECT DISTINCT
                     c5 owner,
                     c1 table_name
                FROM sqli$_stattab_temp
               WHERE 1=1 -- 150828 statid = l_statid
                 AND type = 'T'
               ORDER BY
                     c5, c1)
    LOOP
      BEGIN
        -- takes a backup of current stats before wacking them in data dict
        IF p_make_bk = 'Y' AND p_table_name IS NULL AND p_column_name IS NULL THEN
          SYS.DBMS_STATS.EXPORT_TABLE_STATS (
            ownname  => '"'||i.owner||'"',
            tabname  => '"'||i.table_name||'"',
            stattab  => 'sqlt$_stattab',
            statid   => '"'||l_statid_backup||'"',
            cascade  => TRUE,
            statown  => TOOL_REPOSITORY_SCHEMA );
        END IF;

        IF p_column_name IS NULL THEN
          -- restore stats from sqlt table into data dict
          put_line('restoring cbo stats for table '||i.owner||'.'||i.table_name);
          SYS.DBMS_STATS.IMPORT_TABLE_STATS (
            ownname       => '"'||i.owner||'"',
            tabname       => '"'||i.table_name||'"',
            stattab       => 'sqli$_stattab_temp',
            statid        => NULL, -- 15828 '"'||l_statid||'"',
            cascade       => TRUE,
            statown       => TOOL_REPOSITORY_SCHEMA,
            no_invalidate => FALSE );
        ELSE
          -- restore stats from sqlt table column into data dict
          put_line('restoring cbo stats for column '||i.owner||'.'||i.table_name||'.'||p_column_name);
          SYS.DBMS_STATS.IMPORT_COLUMN_STATS (
            ownname       => '"'||i.owner||'"',
            tabname       => '"'||i.table_name||'"',
            colname       => '"'||p_column_name||'"',
            stattab       => 'sqli$_stattab_temp',
            statid        => NULL, -- 15828 '"'||l_statid||'"',
            statown       => TOOL_REPOSITORY_SCHEMA,
            no_invalidate => FALSE );
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          put_line(SQLERRM);
          put_line('skipping table: '||i.owner||'.'||i.table_name);
          DELETE sqli$_stattab_temp
           WHERE 1=1 -- 15828 statid = l_statid
             AND type IN ('T', 'C') -- table and table columns
             AND c5 = i.owner
             AND c1 = i.table_name;
          FOR j IN (SELECT DISTINCT owner, index_name
                      FROM sys.dba_indexes
                     WHERE table_owner = i.owner
                       AND table_name = i.table_name)
          LOOP
            DELETE sqli$_stattab_temp
             WHERE 1=1 -- 15828 statid = l_statid
               AND type = 'I'
               AND c5 = j.owner
               AND c1 = j.index_name;
          END LOOP;
      END;
    END LOOP;

    -- metrics imported
    my_count := 0;
    --FOR i IN (SELECT /*+ FULL(s) */ s.c2, s.c3, s.type, s.d1 FROM sqli$_stattab_temp s WHERE s.statid = l_statid)
    FOR i IN (SELECT c2, c3, type, d1 FROM sqli$_stattab_temp s) --15828 WHERE s.statid = l_statid)
    LOOP
      IF i.c2 IS NULL THEN
        IF i.type = 'C' THEN
          columns2 := columns2 + 1;
          stats_rows2 := stats_rows2 + 1;
        ELSIF i.type = 'I' THEN
          indexes2 := indexes2 + 1;
          stats_rows2 := stats_rows2 + 1;
        ELSIF i.type = 'T' THEN
          tables2 := tables2 + 1;
          stats_rows2 := stats_rows2 + 1;
          IF i.d1 IS NOT NULL THEN
            my_count := my_count + 1;
            avg_age_days2 := avg_age_days2 + (SYSDATE - i.d1);
          END IF;
		ELSIF i.type = 'E' THEN -- 150828 Extensions are only valid at Table level.
		  columns2e:=columns2e+1;
        END IF;
      ELSIF i.c3 IS NULL THEN
        IF i.type = 'C' THEN
          columns2p := columns2p + 1;
          stats_rows2 := stats_rows2 + 1;
        ELSIF i.type = 'I' THEN
          indexes2p := indexes2p + 1;
          stats_rows2 := stats_rows2 + 1;
        ELSIF i.type = 'T' THEN
          tables2p := tables2p + 1;
          stats_rows2 := stats_rows2 + 1;
          IF i.d1 IS NOT NULL THEN
            my_count := my_count + 1;
            avg_age_days2 := avg_age_days2 + (SYSDATE - i.d1);
          END IF;
        END IF;
      ELSE
        IF i.type = 'C' THEN
          columns2s := columns2s + 1;
          stats_rows2 := stats_rows2 + 1;
        ELSIF i.type = 'I' THEN
          indexes2s := indexes2s + 1;
          stats_rows2 := stats_rows2 + 1;
        ELSIF i.type = 'T' THEN
          tables2s := tables2s + 1;
          stats_rows2 := stats_rows2 + 1;
          IF i.d1 IS NOT NULL THEN
            my_count := my_count + 1;
            avg_age_days2 := avg_age_days2 + (SYSDATE - i.d1);
          END IF;
        END IF;
      END IF;
    END LOOP;
    IF my_count > 0 THEN
      avg_age_days2 := ROUND(avg_age_days2 / my_count, 1);
    END IF;

    COMMIT;

    IF p_load_hist = 'Y' AND p_table_name IS NULL AND p_column_name IS NULL THEN
      -- records what is the oldest time up to where we can restore stats
      BEGIN
        SELECT sval2
          INTO l_skip_timestamp
          FROM sys.optstat_hist_control$
         WHERE sname = 'SKIP_TIME';
        -- initialize save time so it can be updated if an older time is found in history
        l_save_timestamp := l_skip_timestamp;
      EXCEPTION
        WHEN OTHERS THEN
          l_skip_timestamp := NULL;
      END;

      -- restore wri$_optstat tables
      -- don't touch if there is no history to restore
      SELECT count(*)
        INTO l_hist_stats
        FROM DUAL
       WHERE EXISTS (
      SELECT NULL
        FROM sqlt$_dba_tab_stats_versions
       WHERE statid = l_statid
         AND version_type = 'HISTORY'
       UNION ALL
      SELECT NULL
        FROM sqlt$_dba_ind_stats_versions
       WHERE statid = l_statid
         AND version_type = 'HISTORY');

      can_access_wri := TRUE;
      IF /* l_user_id > 0 AND */ l_hist_stats > 0 THEN
        l_cnt_d_tab_hist := 0;
        l_cnt_d_head_hist := 0;
        l_cnt_d_hgrm_hist := 0;
        l_cnt_d_ind_hist := 0;
        l_cnt_i_tab_hist := 0;
        l_cnt_i_head_hist := 0;
        l_cnt_i_hgrm_hist := 0;
        l_cnt_i_ind_hist := 0;

        IF can_access_wri THEN -- cleanup old table entries
          put_line('deleting conflicting rows from tables:');
          put_line('wri$_optstat_histgrm_history, _histhead_history, and _tab_history');
          -- 12.1.07 to support multi-user history restore
          FOR i IN (SELECT DISTINCT CASE WHEN l_schema_owner = 'NULL' THEN owner ELSE l_schema_owner END owner,
                           object_type, table_name, NVL(subpartition_name, partition_name) subobject_name
                      FROM sqlt$_dba_tab_stats_versions
                     WHERE statid = l_statid
                       AND version_type = 'HISTORY')
          LOOP
            IF i.object_type IN ('PARTITION', 'SUBPARTITION') THEN
              l_object_type := 'TABLE '||i.object_type;
            ELSE
              l_object_type := i.object_type;
            END IF;

            l_object_id := get_dba_object_id(l_object_type, i.owner, i.table_name, i.subobject_name);

            BEGIN
              DELETE sys.wri$_optstat_histgrm_history
               WHERE obj# = l_object_id;

              l_cnt_d_hgrm_hist := l_cnt_d_hgrm_hist + sql%ROWCOUNT;

            EXCEPTION
              WHEN OTHERS THEN
                put_line(SQLERRM);
                put_line('*** cannot delete from sys.wri$_optstat_histgrm_history with user '||USER);
                can_access_wri := FALSE;
                EXIT; -- break loop
            END;

            BEGIN
              DELETE sys.wri$_optstat_histhead_history
               WHERE obj# = l_object_id;

              l_cnt_d_head_hist := l_cnt_d_head_hist + sql%ROWCOUNT;

            EXCEPTION
              WHEN OTHERS THEN
                put_line(SQLERRM);
                put_line('*** cannot delete from sys.wri$_optstat_histhead_history with user '||USER);
                can_access_wri := FALSE;
                EXIT; -- break loop
            END;

            BEGIN
              DELETE sys.wri$_optstat_tab_history
               WHERE obj# = l_object_id;

              l_cnt_d_tab_hist := l_cnt_d_tab_hist + sql%ROWCOUNT;

            EXCEPTION
              WHEN OTHERS THEN
                put_line(SQLERRM);
                put_line('*** cannot delete from sys.wri$_optstat_tab_history with user '||USER);
                can_access_wri := FALSE;
                EXIT; -- break loop
            END;
          END LOOP; -- distinct sqlt$_dba_tab_stats_versions w/ HISTORY
        END IF; -- can_access_wri

        IF can_access_wri THEN -- cleanup old index entries
          put_line('deleting conflicting wri$_optstat_ind_history');
          FOR i IN (SELECT DISTINCT CASE WHEN l_schema_owner = 'NULL' THEN owner ELSE l_schema_owner END owner,
                           object_type, index_name, NVL(subpartition_name, partition_name) subobject_name
                      FROM sqlt$_dba_ind_stats_versions
                     WHERE statid = l_statid
                       AND version_type = 'HISTORY')
          LOOP
            IF i.object_type IN ('PARTITION', 'SUBPARTITION') THEN
              l_object_type := 'INDEX '||i.object_type;
            ELSE
              l_object_type := i.object_type;
            END IF;

            l_object_id := get_dba_object_id(l_object_type, i.owner, i.index_name, i.subobject_name);

            BEGIN
              DELETE sys.wri$_optstat_ind_history
               WHERE obj# = l_object_id;

              l_cnt_d_ind_hist := l_cnt_d_ind_hist + sql%ROWCOUNT;

            EXCEPTION
              WHEN OTHERS THEN
                put_line(SQLERRM);
                put_line('*** cannot delete from sys.wri$_optstat_ind_history with user '||USER);
                can_access_wri := FALSE;
                EXIT; -- break loop
            END;
          END LOOP; -- distinct sqlt$_dba_ind_stats_versions w/ HISTORY
        END IF; -- can_access_wri

        IF can_access_wri THEN -- wri$_optstat_tab_history
          put_line('restoring wri$_optstat_tab_history');
          l_prior_obj# := -1;
          FOR i IN (SELECT v.* , CASE WHEN l_schema_owner = 'NULL' THEN v.owner ELSE l_schema_owner END adj_owner
                      FROM sqlt$_dba_tab_stats_versions v
                     WHERE v.statid = l_statid
                       AND v.version_type = 'HISTORY'
                     ORDER BY
                           v.object_id,
                           v.save_time)
          LOOP
            IF i.object_type IN ('PARTITION', 'SUBPARTITION') THEN
              l_object_type := 'TABLE '||i.object_type;
            ELSE
              l_object_type := i.object_type;
            END IF;

            IF i.object_id <> l_prior_obj# THEN
              l_object_id := get_dba_object_id(l_object_type, i.adj_owner, i.table_name, NVL(i.subpartition_name, i.partition_name));
            END IF;

            IF l_object_id > 0 THEN
                BEGIN
                  l_cnt_i_tab_hist := l_cnt_i_tab_hist + 1;
                  INSERT INTO sys.wri$_optstat_tab_history (
                    obj#,
                    savtime,
                    flags,
                    rowcnt,
                    blkcnt,
                    avgrln,
                    samplesize,
                    analyzetime,
                    cachedblk,
                    cachehit,
                    logicalread,
                    spare1,
                    spare2,
                    spare3,
                    spare4,
                    spare5,
                    spare6
                  ) VALUES (
                    l_object_id,
                    i.save_time,
                    i.flags,
                    i.num_rows,
                    i.blocks,
                    i.avg_row_len,
                    i.sample_size,
                    i.last_analyzed,
                    i.cachedblk,
                    i.cachehit,
                    i.logicalread,
                    i.spare1,
                    i.spare2,
                    i.spare3,
                    i.spare4,
                    i.spare5,
                    i.spare6
                  );
                  IF i.save_time < l_save_timestamp THEN
                    l_save_timestamp := TRUNC(i.save_time);
                  END IF;
                EXCEPTION
                  WHEN OTHERS THEN
                    put_line(SQLERRM);
                    put_line('*** cannot insert into sys.wri$_optstat_tab_history with user '||USER);
                    can_access_wri := FALSE;
                    EXIT; -- break loop
                END;
            END IF; -- l_object_id > 0

            l_prior_obj# := i.object_id;
          END LOOP; -- sqlt$_dba_tab_stats_versions
        END IF; -- can_access wri$_optstat_tab_history

        IF can_access_wri THEN -- wri$_optstat_ind_history
          put_line('restoring wri$_optstat_ind_history');
          l_prior_obj# := -1;
          FOR i IN (SELECT v.*, CASE WHEN l_schema_owner = 'NULL' THEN v.owner ELSE l_schema_owner END adj_owner
                      FROM sqlt$_dba_ind_stats_versions v
                     WHERE v.statid = l_statid
                       AND v.version_type = 'HISTORY'
                     ORDER BY
                           v.object_id,
                           v.save_time)
          LOOP
            IF i.object_type IN ('PARTITION', 'SUBPARTITION') THEN
              l_object_type := 'INDEX '||i.object_type;
            ELSE
              l_object_type := i.object_type;
            END IF;

            IF i.object_id <> l_prior_obj# THEN
              l_object_id := get_dba_object_id(l_object_type, i.adj_owner, i.index_name, NVL(i.subpartition_name, i.partition_name));
            END IF;

            IF l_object_id > 0 THEN
                BEGIN
                  l_cnt_i_ind_hist := l_cnt_i_ind_hist + 1;
                  INSERT INTO sys.wri$_optstat_ind_history (
                    obj#,
                    savtime,
                    flags,
                    rowcnt,
                    blevel,
                    leafcnt,
                    distkey,
                    lblkkey,
                    dblkkey,
                    clufac,
                    samplesize,
                    analyzetime,
                    guessq,
                    cachedblk,
                    cachehit,
                    logicalread,
                    spare1,
                    spare2,
                    spare3,
                    spare4,
                    spare5,
                    spare6
                  ) VALUES (
                    l_object_id,
                    i.save_time,
                    i.flags,
                    i.num_rows,
                    i.blevel,
                    i.leaf_blocks,
                    i.distinct_keys,
                    i.avg_leaf_blocks_per_key,
                    i.avg_data_blocks_per_key,
                    i.clustering_factor,
                    i.sample_size,
                    i.last_analyzed,
                    i.guessq,
                    i.cachedblk,
                    i.cachehit,
                    i.logicalread,
                    i.spare1,
                    i.spare2,
                    i.spare3,
                    i.spare4,
                    i.spare5,
                    i.spare6
                  );
                  IF i.save_time < l_save_timestamp THEN
                    l_save_timestamp := TRUNC(i.save_time);
                  END IF;
                EXCEPTION
                  WHEN OTHERS THEN
                    put_line(SQLERRM);
                    put_line('*** cannot insert into sys.wri$_optstat_ind_history with user '||USER);
                    can_access_wri := FALSE;
                    EXIT; -- break loop
                END;
            END IF; -- l_object_id > 0

            l_prior_obj# := i.object_id;
          END LOOP; -- sqlt$_dba_ind_stats_versions
        END IF; -- can_access wri$_optstat_ind_history

        IF can_access_wri THEN -- wri$_optstat_histhead_history
          put_line('restoring wri$_optstat_histhead_history');
          l_prior_obj# := -1;
          FOR i IN (SELECT v.*, CASE WHEN l_schema_owner = 'NULL' THEN v.owner ELSE l_schema_owner END adj_owner
                      FROM sqlt$_dba_col_stats_versions v
                     WHERE v.statid = l_statid
                       AND v.version_type = 'HISTORY'
                     ORDER BY
                           v.object_id,
                           v.intcol#,
                           v.save_time)
          LOOP
            IF i.object_type IN ('PARTITION', 'SUBPARTITION') THEN
              l_object_type := 'TABLE '||i.object_type;
            ELSE
              l_object_type := i.object_type;
            END IF;

            IF i.object_id <> l_prior_obj# THEN
              l_object_id := get_dba_object_id(l_object_type, i.adj_owner, i.table_name, NVL(i.subpartition_name, i.partition_name));
            END IF;

            IF i.intcol# <> l_prior_intcol# THEN
              l_column_id := get_internal_column_id(i.adj_owner, i.table_name, i.column_name, i.intcol#);
            END IF;

            IF l_object_id > 0 THEN
                BEGIN
                  l_cnt_i_head_hist := l_cnt_i_head_hist + 1;
                  INSERT INTO sys.wri$_optstat_histhead_history (
                    obj#,
                    intcol#,
                    savtime,
                    flags,
                    null_cnt,
                    minimum,
                    maximum,
                    distcnt,
                    density,
                    lowval,
                    hival,
                    avgcln,
                    sample_distcnt,
                    sample_size,
                    timestamp#,
                    --expression,
                    --colname,
                    spare1,
                    spare2,
                    spare3,
                    spare4,
                    spare5,
                    spare6
                  ) VALUES (
                    l_object_id,
                    i.intcol#,
                    i.save_time,
                    i.flags,
                    i.num_nulls,
                    i.minimum,
                    i.maximum,
                    i.num_distinct,
                    i.density,
                    i.low_value,
                    i.high_value,
                    i.avg_col_len,
                    i.sample_distcnt,
                    i.sample_size,
                    i.last_analyzed,
                    --i.expression,
                    --i.colname,
                    i.spare1,
                    i.spare2,
                    i.spare3,
                    i.spare4,
                    i.spare5,
                    i.spare6
                  );
                  IF i.save_time < l_save_timestamp THEN
                    l_save_timestamp := TRUNC(i.save_time);
                  END IF;
                EXCEPTION
                  WHEN OTHERS THEN
                    put_line(SQLERRM);
                    put_line('*** cannot insert into sys.wri$_optstat_histhead_history with user '||USER);
                    can_access_wri := FALSE;
                    EXIT; -- break loop
                END;
            END IF; -- l_object_id > 0

            l_prior_obj# := i.object_id;
          END LOOP; -- sqlt$_dba_col_stats_versions
        END IF; -- can_access wri$_optstat_histhead_history

        IF can_access_wri THEN -- wri$_optstat_histgrm_history
          put_line('restoring wri$_optstat_histgrm_history');
          l_prior_obj# := -1;
          FOR i IN (SELECT v.*, CASE WHEN l_schema_owner = 'NULL' THEN v.owner ELSE l_schema_owner END adj_owner
                      FROM sqlt$_dba_histgrm_stats_versn v
                     WHERE v.statid = l_statid
                       AND v.version_type = 'HISTORY'
                     ORDER BY
                           v.object_id,
                           v.intcol#,
                           v.save_time)
          LOOP
            IF i.object_type IN ('PARTITION', 'SUBPARTITION') THEN
              l_object_type := 'TABLE '||i.object_type;
            ELSE
              l_object_type := i.object_type;
            END IF;

            IF i.object_id <> l_prior_obj# THEN
              l_object_id := get_dba_object_id(l_object_type, i.adj_owner, i.table_name, NVL(i.subpartition_name, i.partition_name));
            END IF;

            IF i.intcol# <> l_prior_intcol# THEN
              l_column_id := get_internal_column_id(i.adj_owner, i.table_name, i.column_name, i.intcol#);
            END IF;

            IF l_object_id > 0 THEN
                BEGIN
                  l_cnt_i_hgrm_hist := l_cnt_i_hgrm_hist + 1;
                  INSERT INTO sys.wri$_optstat_histgrm_history (
                    obj#,
                    intcol#,
                    savtime,
                    bucket,
                    endpoint,
                    epvalue,
                    --colname,
                    spare1,
                    spare2,
                    spare3,
                    spare4,
                    spare5,
                    spare6
                  ) VALUES (
                    l_object_id,
                    i.intcol#,
                    i.save_time,
                    i.endpoint_number,
                    i.endpoint_value,
                    i.endpoint_actual_value,
                    --i.colname,
                    i.spare1,
                    i.spare2,
                    i.spare3,
                    i.spare4,
                    i.spare5,
                    i.spare6
                  );
                  IF i.save_time < l_save_timestamp THEN
                    l_save_timestamp := TRUNC(i.save_time);
                  END IF;
                EXCEPTION
                  WHEN OTHERS THEN
                    put_line(SQLERRM);
                    put_line('*** cannot insert into sys.wri$_optstat_histgrm_history with user '||USER);
                    can_access_wri := FALSE;
                    EXIT; -- break loop
                END;
            END IF; -- l_object_id > 0

            l_prior_obj# := i.object_id;
          END LOOP; -- sqlt$_dba_histgrm_stats_versn

        END IF; -- can_access wri$_optstat_histgrm_history
      END IF; -- l_user_id > 0 AND l_hist_stats > 0 THEN

      -- reset skip_timestamp if there are older records in history
      IF l_save_timestamp < l_skip_timestamp THEN
        BEGIN
          UPDATE sys.optstat_hist_control$
             SET sval2 = l_save_timestamp
           WHERE sname = 'SKIP_TIME';
        EXCEPTION
          WHEN OTHERS THEN
            put_line(SQLERRM);
            put_line('*** cannot update sys.optstat_hist_control with user '||USER);
        END;
      END IF;

      COMMIT;

      IF l_cnt_d_tab_hist > 0 or l_cnt_d_ind_hist > 0 or l_cnt_d_head_hist > 0 or l_cnt_d_hgrm_hist > 0 THEN
        put_line('deleted '||l_cnt_d_tab_hist||' rows from wri$_optstat_tab_history');
        put_line('deleted '||l_cnt_d_ind_hist||' rows from wri$_optstat_ind_history');
        put_line('deleted '||l_cnt_d_head_hist||' rows from wri$_optstat_histhead_history');
        put_line('deleted '||l_cnt_d_hgrm_hist||' rows from wri$_optstat_histgrm_history');
      END IF;
      IF l_cnt_i_tab_hist > 0 or l_cnt_i_ind_hist > 0 or l_cnt_i_head_hist > 0 or l_cnt_i_hgrm_hist > 0 THEN
        put_line('restored '||l_cnt_i_tab_hist||' rows into wri$_optstat_tab_history');
        put_line('restored '||l_cnt_i_ind_hist||' rows into wri$_optstat_ind_history');
        put_line('restored '||l_cnt_i_head_hist||' rows into wri$_optstat_histhead_history');
        put_line('restored '||l_cnt_i_hgrm_hist||' rows into wri$_optstat_histgrm_history');
      END IF;
    END IF; -- p_load_hist = 'Y' AND p_table_name IS NULL AND p_column_name IS NULL

    IF stats_rows1 = stats_rows2 THEN
      stats_rows3 := 'OK';
    END IF;
    IF tables1 = tables2 THEN
      tables3 := 'OK';
    END IF;
    IF tables1p = tables2p THEN
      tables3p := 'OK';
    END IF;
    IF tables1s = tables2s THEN
      tables3s := 'OK';
    END IF;
    IF indexes1 = indexes2 THEN
      indexes3 := 'OK';
    END IF;
    IF indexes1p = indexes2p THEN
      indexes3p := 'OK';
    END IF;
    IF indexes1s = indexes2s THEN
      indexes3s := 'OK';
    END IF;
    IF columns1 = columns2 THEN
      columns3 := 'OK';
    END IF;
    IF columns1p = columns2p THEN
      columns3p := 'OK';
    END IF;
    IF columns1s = columns2s THEN
      columns3s := 'OK';
    END IF;
    IF columns1e = columns2e THEN -- 150828
     columns3e := 'OK';
    END IF;

    IF avg_age_days1 = avg_age_days2 THEN
      avg_age_days3 := 'OK';
    END IF;

    put_line('+  ');
    put_line('|  ');
    put_line('|   Stats from id "'||l_statid||'"');
    put_line('|   have been restored into data dict');
    put_line('|  ');
    IF l_save_timestamp < l_skip_timestamp THEN
      put_line('|   Stats SKIP_TIME was reset');
      put_line('|   from "'||l_skip_timestamp||'"');
      put_line('|   to "'||l_save_timestamp||'"');
      put_line('|  ');
    END IF;
    IF p_make_bk = 'Y' AND p_table_name IS NULL AND p_column_name IS NULL THEN
      put_line('|   Backup with id "'||l_statid_backup||'"');
      put_line('|   was automatically created before this restore');
      put_line('|  ');
    END IF;
    put_line('|           METRIC   IN STATTAB  RESTORED  OK');
    put_line('|     -------------  ----------  --------  --');
    put_line('|   '||LPAD('    STATS ROWS:', 15)||LPAD(  stats_rows1, 12)||LPAD(  stats_rows2, 10)||LPAD(  stats_rows3, 4));
    put_line('|   '||LPAD('        TABLES:', 15)||LPAD(      tables1, 12)||LPAD(      tables2, 10)||LPAD(      tables3, 4));
    put_line('|   '||LPAD('    TABLE PART:', 15)||LPAD(     tables1p, 12)||LPAD(     tables2p, 10)||LPAD(     tables3p, 4));
    put_line('|   '||LPAD(' TABLE SUBPART:', 15)||LPAD(     tables1s, 12)||LPAD(     tables2s, 10)||LPAD(     tables3s, 4));
    put_line('|   '||LPAD('       INDEXES:', 15)||LPAD(     indexes1, 12)||LPAD(     indexes2, 10)||LPAD(     indexes3, 4));
    put_line('|   '||LPAD('    INDEX PART:', 15)||LPAD(    indexes1p, 12)||LPAD(    indexes2p, 10)||LPAD(    indexes3p, 4));
    put_line('|   '||LPAD(' INDEX SUBPART:', 15)||LPAD(    indexes1s, 12)||LPAD(    indexes2s, 10)||LPAD(    indexes3s, 4));
    put_line('|   '||LPAD('       COLUMNS:', 15)||LPAD(     columns1, 12)||LPAD(     columns2, 10)||LPAD(     columns3, 4));
    put_line('|   '||LPAD('   COLUMN PART:', 15)||LPAD(    columns1p, 12)||LPAD(    columns2p, 10)||LPAD(    columns3p, 4));
    put_line('|   '||LPAD('COLUMN SUBPART:', 15)||LPAD(    columns1s, 12)||LPAD(    columns2s, 10)||LPAD(    columns3s, 4));
    put_line('|   '||LPAD('    EXTENSIONS:', 15)||LPAD(    columns1E, 12)||LPAD(    columns2e, 10)||LPAD(    columns3e, 4));		
    put_line('|   '||LPAD('  AVG AGE DAYS:', 15)||LPAD(avg_age_days1, 12)||LPAD(avg_age_days2, 10)||LPAD(avg_age_days3, 4));
    put_line('|  ');
    put_line('+  ');

    IF l_statid NOT LIKE '%_BK_20%' THEN
      UPDATE sqlt$_sql_statement
         SET restore_date = SYSDATE
       WHERE statid = l_statid
         AND statid NOT LIKE '%BK%';
      COMMIT;
    END IF;
  END import_cbo_stats;


  /*************************************************************************************/

  /* -------------------------
   *
   * public import_cbo_stats_dict_objects
   *
   * called by sqlt/utl/sqltimpdict.sql
   *
   * ------------------------- */
  PROCEDURE import_cbo_stats_dict_objects (
    p_statement_id IN VARCHAR2,
    p_make_bk      IN VARCHAR2 DEFAULT 'N' )
  IS
    my_count INTEGER;
    l_statid sqlt$_stattab.statid%TYPE;
    l_statid_backup sqlt$_stattab.statid%TYPE;

  BEGIN /* import_cbo_stats_dictionary_objects */
    -- finds statid according to partial or full name
    BEGIN
      l_statid := LOWER(p_statement_id);

      SELECT COUNT(DISTINCT statid)
        INTO my_count
        FROM sqlt$_stattab
       WHERE LOWER(statid) LIKE '%'||l_statid||'%'
         AND statid LIKE 'd%';

      IF my_count < 1 THEN
        put_line('statement id "'||p_statement_id||'" was not found on sqlt$_stattab table');
        RETURN;
      END IF;

      IF my_count > 1 THEN
        put_line('statement id "'||p_statement_id||'" is not unique on sqlt$_stattab table');
        RETURN;
      END IF;
    END;

    -- reset l_statid
    SELECT statid
      INTO l_statid
      FROM sqlt$_stattab
     WHERE LOWER(statid) LIKE '%'||l_statid||'%'
       AND statid LIKE 'd%'
       AND ROWNUM = 1;

    -- need to check the version column across releases, 12.1 has version 7
/*    IF get_rdbms_release >= 11 THEN
      UPDATE sqlt$_stattab SET version = 5 WHERE statid = l_statid;
    END IF; */

    -- will create a backup of stats from dictonary before restore
    l_statid_backup := RPAD(l_statid, 12)||'_BK_'||TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');

    -- there should be no rows here, unless user has tried an import on less than 1 sec
    DELETE sqlt$_stattab WHERE statid = l_statid_backup;

    BEGIN
      -- put_line('creating backup of stats of dictionary objects into '||l_statid_backup);
      IF p_make_bk = 'Y' THEN
        SYS.DBMS_STATS.EXPORT_DICTIONARY_STATS ('sqlt$_stattab', '"'||l_statid_backup||'"', TOOL_REPOSITORY_SCHEMA);
      END IF;
      put_line('restoring stats of dictionary objects from '||l_statid||' into data dict');
      SYS.DBMS_STATS.IMPORT_DICTIONARY_STATS ('sqlt$_stattab', '"'||l_statid||'"', TOOL_REPOSITORY_SCHEMA, FALSE, TRUE);
    EXCEPTION
      WHEN OTHERS THEN
        put_line(SQLERRM);
        put_line('CBO dictionary object stats not imported');
    END;

    COMMIT;
  END import_cbo_stats_dict_objects;


  /*************************************************************************************/

  /* -------------------------
   *
   * public import_cbo_stats_fixed_objects
   *
   * called by sqlt/utl/sqltimpfo.sql
   *
   * ------------------------- */
  PROCEDURE import_cbo_stats_fixed_objects (
    p_statement_id IN VARCHAR2,
    p_make_bk      IN VARCHAR2 DEFAULT 'N' )
  IS
    my_count INTEGER;
    l_statid sqlt$_stattab.statid%TYPE;
    l_statid_backup sqlt$_stattab.statid%TYPE;

  BEGIN /* import_cbo_stats_fixed_objects */
    -- finds statid according to partial or full name
    BEGIN
      l_statid := LOWER(p_statement_id);

      SELECT COUNT(DISTINCT statid)
        INTO my_count
        FROM sqlt$_stattab
       WHERE LOWER(statid) LIKE '%'||l_statid||'%'
         AND statid LIKE 'f%';

      IF my_count < 1 THEN
        put_line('statement id "'||p_statement_id||'" was not found on sqlt$_stattab table');
        RETURN;
      END IF;

      IF my_count > 1 THEN
        put_line('statement id "'||p_statement_id||'" is not unique on sqlt$_stattab table');
        RETURN;
      END IF;
    END;

    -- reset l_statid
    SELECT statid
      INTO l_statid
      FROM sqlt$_stattab
     WHERE LOWER(statid) LIKE '%'||l_statid||'%'
       AND statid LIKE 'f%'
       AND ROWNUM = 1;

    -- omported stats from 9i and 10g have version of 4. 11g is version 5 (new column cl1 for extended stats)
    IF get_rdbms_release >= 11 THEN
      UPDATE sqlt$_stattab SET version = 5 WHERE statid = l_statid;
    END IF;

    -- will create a backup of stats from dictonary before restore
    l_statid_backup := RPAD(l_statid, 12)||'_BK_'||TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');

    -- there should be no rows here, unless user has tried an import on less than 1 sec
    DELETE sqlt$_stattab WHERE statid = l_statid_backup;

    BEGIN
      -- put_line('creating backup of stats of fixed objects into '||l_statid_backup);
      IF p_make_bk = 'Y' THEN
        SYS.DBMS_STATS.EXPORT_FIXED_OBJECTS_STATS ('sqlt$_stattab', '"'||l_statid_backup||'"', TOOL_REPOSITORY_SCHEMA);
      END IF;
      put_line('restoring stats of fixed objects from '||l_statid||' into data dict');
      SYS.DBMS_STATS.IMPORT_FIXED_OBJECTS_STATS ('sqlt$_stattab', '"'||l_statid||'"', TOOL_REPOSITORY_SCHEMA, FALSE, TRUE);
    EXCEPTION
      WHEN OTHERS THEN
        put_line(SQLERRM);
        put_line('CBO fixed object stats not imported');
    END;

    COMMIT;
  END import_cbo_stats_fixed_objects;

  /*************************************************************************************/

  /* -------------------------
   *
   * public ind_cols_sec
   *
   * ------------------------- */
  PROCEDURE ind_cols_sec (
    p_statement_id IN NUMBER,
    p_index_name   IN  VARCHAR2,
    p_owner        IN  VARCHAR2,
    x_vers         OUT NUMBER,
    x_usage        OUT NUMBER,
    x_hgrm         OUT NUMBER,
    x_hgrm_vers    OUT NUMBER,
    x_part         OUT NUMBER,
    x_metadata     OUT NUMBER )
  IS
  BEGIN
    IF get_param('r_gran_vers') IN ('COLUMN', 'HISTOGRAM') THEN
      SELECT COUNT(*)
        INTO x_vers
        FROM sqlt$_dba_ind_columns ic,
             sqlt$_dba_col_stats_versions x
       WHERE ic.statement_id = p_statement_id
         AND ic.index_name = p_index_name
         AND ic.index_owner = p_owner
         AND ic.statement_id = x.statement_id
         AND ic.table_name = x.table_name
         AND ic.table_owner = x.owner
         AND ic.column_name = x.column_name
         AND x.object_type = 'TABLE'
         AND ROWNUM = 1;
    END IF;

    SELECT COUNT(*)
      INTO x_usage
      FROM sqlt$_dba_ind_columns ic,
           sqlt$_dba_col_usage$ x
     WHERE ic.statement_id = p_statement_id
       AND ic.index_name = p_index_name
       AND ic.index_owner = p_owner
       AND ic.statement_id = x.statement_id
       AND ic.table_name = x.table_name
       AND ic.table_owner = x.owner
       AND ic.column_name = x.column_name
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO x_hgrm
      FROM sqlt$_dba_ind_columns ic,
           sqlt$_dba_tab_histograms x
     WHERE ic.statement_id = p_statement_id
       AND ic.index_name = p_index_name
       AND ic.index_owner = p_owner
       AND ic.statement_id = x.statement_id
       AND ic.table_name = x.table_name
       AND ic.table_owner = x.owner
       AND ic.column_name = x.column_name
       AND x.endpoint_number > 1
       AND ROWNUM = 1;

    IF get_param('r_gran_vers') = 'HISTOGRAM' THEN
      SELECT COUNT(*)
        INTO x_hgrm_vers
        FROM sqlt$_dba_ind_columns ic,
             sqlt$_dba_histgrm_stats_versn x
       WHERE ic.statement_id = p_statement_id
         AND ic.index_name = p_index_name
         AND ic.index_owner = p_owner
         AND ic.statement_id = x.statement_id
         AND ic.table_name = x.table_name
         AND ic.table_owner = x.owner
         AND ic.column_name = x.column_name
         AND x.object_type = 'TABLE'
         AND ROWNUM = 1;
    END IF;

    SELECT COUNT(*)
      INTO x_part
      FROM sqlt$_dba_indexes x,
           sqlt$_dba_ind_partitions p
     WHERE x.statement_id = p_statement_id
       AND x.partitioned = 'YES'
       AND x.index_name = p_index_name
       AND x.owner = p_owner
       AND x.statement_id = p.statement_id
       AND x.owner = p.index_owner
       AND x.index_name = p.index_name
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO x_metadata
      FROM sqlt$_metadata
     WHERE statement_id = p_statement_id
       AND object_name = p_index_name
       AND owner = p_owner
       AND object_type = 'INDEX'
       AND transformed = 'N'
       AND ROWNUM = 1;
  END ind_cols_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * public tbl_cols_sec
   *
   * ------------------------- */
  PROCEDURE tbl_cols_sec (
    p_statement_id IN NUMBER,
    p_table_name   IN  VARCHAR2,
    p_owner        IN  VARCHAR2,
    x_vers         OUT NUMBER,
    x_usage        OUT NUMBER,
    x_hgrm         OUT NUMBER,
    x_hgrm_vers    OUT NUMBER,
    x_cons         OUT NUMBER,
    x_index_cols   OUT NUMBER,
    x_part         OUT NUMBER,
    x_indexes      OUT NUMBER,
    x_metadata     OUT NUMBER )
  IS
  BEGIN
    IF get_param('r_gran_vers') IN ('COLUMN', 'HISTOGRAM') THEN
      SELECT COUNT(*)
        INTO x_vers
        FROM sqlt$_dba_col_stats_versions v,
             sqlt$_dba_all_table_cols_v c
       WHERE v.statement_id = p_statement_id
         AND v.object_type = 'TABLE'
         AND v.owner = p_owner
         AND v.table_name = p_table_name
         AND v.statement_id = c.statement_id
         AND v.column_name = c.column_name
         AND v.table_name = c.table_name
         AND v.owner = c.owner
         AND (c.in_predicates = 'TRUE' OR c.in_indexes = 'TRUE' OR c.in_projection = 'TRUE')
         --AND c.hidden_column = 'NO'
         AND ROWNUM = 1;
    END IF;

    SELECT COUNT(*)
      INTO x_usage
      FROM sqlt$_dba_col_usage$
     WHERE statement_id = p_statement_id
       AND owner = p_owner
       AND table_name = p_table_name
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO x_hgrm
      FROM sqlt$_dba_tab_histograms
     WHERE statement_id = p_statement_id
       AND table_name = p_table_name
       AND owner = p_owner
       AND endpoint_number > 1
       AND ROWNUM = 1;

    IF get_param('r_gran_vers') = 'HISTOGRAM' THEN
      SELECT COUNT(*)
        INTO x_hgrm_vers
        FROM sqlt$_dba_histgrm_stats_versn v,
             sqlt$_dba_all_table_cols_v c
       WHERE v.statement_id = p_statement_id
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

    SELECT COUNT(*)
      INTO x_cons
      FROM sqlt$_dba_constraints
     WHERE statement_id = p_statement_id
       AND table_name = p_table_name
       AND owner = p_owner
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO x_index_cols
      FROM sqlt$_dba_ind_columns
     WHERE statement_id = p_statement_id
       AND table_name = p_table_name
       AND table_owner = p_owner
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO x_part
      FROM sqlt$_dba_tab_partitions
     WHERE statement_id = p_statement_id
       AND table_name = p_table_name
       AND table_owner = p_owner
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO x_indexes
      FROM sqlt$_dba_indexes
     WHERE statement_id = p_statement_id
       AND table_name = p_table_name
       AND table_owner = p_owner
       AND ROWNUM = 1;

    SELECT COUNT(*)
      INTO x_metadata
      FROM sqlt$_metadata
     WHERE statement_id = p_statement_id
       AND object_name = p_table_name
       AND owner = p_owner
       AND object_type = 'TABLE'
       AND transformed = 'N'
       AND ROWNUM = 1;
  END tbl_cols_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_end_date
   *
   * called by: sqlt$i.xtract, sqlt$i.xecute_end, sqlt$i.xplain_end and sqlt$i.remote_xtract,
   *
   * ------------------------- */
  PROCEDURE set_end_date (p_statement_id IN NUMBER)
  IS
  BEGIN
    restore_init_parameters;
    UPDATE sqlt$_sql_statement
       SET tool_end_date = SYSDATE
     WHERE statement_id = p_statement_id;
    COMMIT;
  END set_end_date;

  /*************************************************************************************/

  /* -------------------------
   *
   * public dbms_addm_analyze_inst
   *
   * creates an addm task for a range of awr snapshots (used by sqlt$r.addmrpt_driver)
   *
   * ------------------------- */
  FUNCTION dbms_addm_analyze_inst (
    p_dbid     IN NUMBER,
    p_inst_num IN NUMBER,
    p_bid      IN NUMBER,
    p_eid      IN NUMBER )
  RETURN VARCHAR2
  IS
    l_task_id   NUMBER;
    l_task_name VARCHAR2(100);
    l_desc      VARCHAR2(500);
  BEGIN
    l_task_name := NULL;
    l_desc := 'ADDM run: snapshots ['||p_bid ||', '||p_eid||'], instance '||p_inst_num||', database id '||p_dbid;

    SYS.DBMS_ADVISOR.CREATE_TASK(advisor_name => 'ADDM', task_id => l_task_id, task_name => l_task_name, task_desc => l_desc);

    -- set time window
    SYS.DBMS_ADVISOR.SET_TASK_PARAMETER(task_name => l_task_name, parameter => 'START_SNAPSHOT', value => p_bid);
    SYS.DBMS_ADVISOR.SET_TASK_PARAMETER(task_name => l_task_name, parameter => 'END_SNAPSHOT', value => p_eid);

    -- set instance number
    SYS.DBMS_ADVISOR.SET_TASK_PARAMETER(task_name => l_task_name, parameter => 'INSTANCE', value => p_inst_num);

    -- set dbid
    SYS.DBMS_ADVISOR.SET_TASK_PARAMETER(task_name => l_task_name, parameter => 'DB_ID', value => p_dbid);

    -- execute task
    SYS.DBMS_ADVISOR.EXECUTE_TASK(task_name => l_task_name);

    RETURN l_task_name;
  END dbms_addm_analyze_inst;

  /*************************************************************************************/

  /* -------------------------
   *
   * public awr_report_html
   *
   * called by awrrpt_driver.sql from a user which has no GRANT EXECUTE ON SYS.DBMS_WORKLOAD_REPOSITORY
   *
   * ------------------------- */
  FUNCTION awr_report_html (
    p_dbid        IN NUMBER,
    p_inst_num    IN NUMBER,
    p_bid         IN NUMBER,
    p_eid         IN NUMBER,
    p_rpt_options IN NUMBER DEFAULT 0 )
  RETURN varchar2_table PIPELINED
  IS
    TYPE l_rt IS RECORD (output VARCHAR2(2000));
    l_rec l_rt;
    l_cv SYS_REFCURSOR;
  BEGIN
    OPEN l_cv FOR
      'SELECT output FROM TABLE(SYS.DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_HTML(:dbid, :inst_num, :bid, :eid, :rpt_options))'
      USING IN p_dbid, IN p_inst_num, IN p_bid, IN p_eid, IN p_rpt_options;
    LOOP
      FETCH l_cv INTO l_rec;
      EXIT WHEN l_cv%NOTFOUND;
      PIPE ROW(l_rec.output);
    END LOOP;
    CLOSE l_cv;
    RETURN;
  END awr_report_html;

  /*************************************************************************************/

  /* -------------------------
   *
   * public ash_report_html_10
   *
   * called by ashrpt_driver.sql from a user which has no GRANT EXECUTE ON SYS.DBMS_WORKLOAD_REPOSITORY
   *
   * ------------------------- */
  FUNCTION ash_report_html_10 (
    p_dbid          IN NUMBER,
    p_inst_num      IN NUMBER,
    p_btime         IN DATE,
    p_etime         IN DATE,
    p_options       IN NUMBER    DEFAULT 0,
    p_slot_width    IN NUMBER    DEFAULT 0,
    p_sid           IN NUMBER    DEFAULT NULL,
    p_sql_id        IN VARCHAR2  DEFAULT NULL,
    p_wait_class    IN VARCHAR2  DEFAULT NULL,
    p_service_hash  IN NUMBER    DEFAULT NULL,
    p_module        IN VARCHAR2  DEFAULT NULL,
    p_action        IN VARCHAR2  DEFAULT NULL,
    p_client_id     IN VARCHAR2  DEFAULT NULL )
  RETURN varchar2_table PIPELINED
  IS
    TYPE l_rt IS RECORD (output VARCHAR2(2000));
    l_rec l_rt;
    l_cv SYS_REFCURSOR;
  BEGIN
    OPEN l_cv FOR
      'SELECT output FROM TABLE(SYS.DBMS_WORKLOAD_REPOSITORY.ASH_REPORT_HTML(:dbid, :inst_num, :btime, :etime, :options, :slot_width, :sid, :sql_id, :wait_class, :service_hash, :module, :action, :client_id))'
      USING IN p_dbid, IN p_inst_num, IN p_btime, IN p_etime, IN p_options, IN p_slot_width, IN p_sid, IN p_sql_id, IN p_wait_class, IN p_service_hash, IN p_module, IN p_action, IN p_client_id;
    LOOP
      FETCH l_cv INTO l_rec;
      EXIT WHEN l_cv%NOTFOUND;
      PIPE ROW(l_rec.output);
    END LOOP;
    CLOSE l_cv;
    RETURN;
  END ash_report_html_10;

  /*************************************************************************************/

  /* -------------------------
   *
   * public ash_report_html_11
   *
   * called by ashrpt_driver.sql from a user which has no GRANT EXECUTE ON SYS.DBMS_WORKLOAD_REPOSITORY
   *
   * ------------------------- */
  FUNCTION ash_report_html_11 (
    p_dbid          IN NUMBER,
    p_inst_num      IN NUMBER,
    p_btime         IN DATE,
    p_etime         IN DATE,
    p_options       IN NUMBER    DEFAULT 0,
    p_slot_width    IN NUMBER    DEFAULT 0,
    p_sid           IN NUMBER    DEFAULT NULL,
    p_sql_id        IN VARCHAR2  DEFAULT NULL,
    p_wait_class    IN VARCHAR2  DEFAULT NULL,
    p_service_hash  IN NUMBER    DEFAULT NULL,
    p_module        IN VARCHAR2  DEFAULT NULL,
    p_action        IN VARCHAR2  DEFAULT NULL,
    p_client_id     IN VARCHAR2  DEFAULT NULL,
    p_plsql_entry   IN VARCHAR2  DEFAULT NULL,
    p_data_src      IN NUMBER    DEFAULT 0 )
  RETURN varchar2_table PIPELINED
  IS
    TYPE l_rt IS RECORD (output VARCHAR2(2000));
    l_rec l_rt;
    l_cv SYS_REFCURSOR;
  BEGIN
    OPEN l_cv FOR
      'SELECT output FROM TABLE(SYS.DBMS_WORKLOAD_REPOSITORY.ASH_REPORT_HTML(:dbid, :inst_num, :btime, :etime, :options, :slot_width, :sid, :sql_id, :wait_class, :service_hash, :module, :action, :client_id, :plsql_entry, :data_src))'
      USING IN p_dbid, IN p_inst_num, IN p_btime, IN p_etime, IN p_options, IN p_slot_width, IN p_sid, IN p_sql_id, IN p_wait_class, IN p_service_hash, IN p_module, IN p_action, IN p_client_id, IN p_plsql_entry, IN p_data_src;
    LOOP
      FETCH l_cv INTO l_rec;
      EXIT WHEN l_cv%NOTFOUND;
      PIPE ROW(l_rec.output);
    END LOOP;
    CLOSE l_cv;
    RETURN;
  END ash_report_html_11;

  /*************************************************************************************/

  /* -------------------------
   *
   * public report_sql_monitor
   *
   * called by sql_monitor_active_driver.sql from a user which has no GRANT for "ADMINISTER SQL MANAGEMENT OBJECT"
   *
   * 25/08/2018: SNC: Replaced 'TYPICAL' for p_report_level with 'BASIC+PARALLEL'
   *
   * ------------------------- */
  FUNCTION report_sql_monitor (
    p_sql_id         IN VARCHAR2 DEFAULT NULL,
    p_sql_exec_start IN DATE     DEFAULT NULL,
    p_sql_exec_id    IN NUMBER   DEFAULT NULL,
    p_report_level   IN VARCHAR2 DEFAULT 'BASIC+PARALLEL',
    p_type           IN VARCHAR2 DEFAULT 'TEXT' )
  RETURN CLOB
  IS
    l_report CLOB;
  BEGIN
    EXECUTE IMMEDIATE 'BEGIN :report := SYS.DBMS_SQLTUNE.REPORT_SQL_MONITOR(sql_id => :sql_id, sql_exec_start => :sql_exec_start, sql_exec_id => :sql_exec_id, report_level => :report_level, type => :type); END;'
    USING OUT l_report, IN p_sql_id, IN p_sql_exec_start, IN p_sql_exec_id, IN p_report_level, IN p_type;
    RETURN l_report;
  END report_sql_monitor;

  /*************************************************************************************/
  
  /* -------------------------
   *
   * public report_hist_sql_monitor
   *
   * called by sql_monitor_active_driver.sql from a user which has no GRANT for "ADMINISTER SQL MANAGEMENT OBJECT"
   * 150911 New
   * ------------------------- */
  FUNCTION report_hist_sql_monitor (
    p_report_id      IN NUMBER     DEFAULT NULL,
    p_type           IN VARCHAR2 DEFAULT 'TEXT' )
  RETURN CLOB
  IS
    l_report CLOB;
  BEGIN
    EXECUTE IMMEDIATE 'BEGIN :report := SYS.DBMS_AUTO_REPORT.REPORT_REPOSITORY_DETAIL(RID =>:report_id, type => :type); END;'
    USING OUT l_report, IN p_report_id, IN p_type;
    RETURN l_report;
  END report_hist_sql_monitor;
  
  /*************************************************************************************/
  
  /* -------------------------
   *
   * public report_perfhub
   *
   * called by perfhub_driver.sql from a user which has no GRANT for "ADMINISTER SQL MANAGEMENT OBJECT"
   * 160403 new
   * ------------------------- */
  FUNCTION report_perfhub (
    p_selected_start_time IN VARCHAR2 DEFAULT NULL,
    p_selected_end_time   IN VARCHAR2 DEFAULT NULL,
	p_date_fmt            IN VARCHAR2 DEFAULT 'YYYY-MM-DD/HH24:MI:SS',
    p_dbid                IN NUMBER DEFAULT NULL,
	p_inst_id             IN NUMBER DEFAULT NULL,
	p_report_type         IN VARCHAR2 DEFAULT 'TYPICAL'
  )
  RETURN CLOB
  IS
    l_report CLOB;
	v_is_realtime number;
	v_selected_start_time date;
	v_selected_end_time date;
	v_outer_start_time date;
	v_outer_end_time date;
	v_date_fmt varchar2(100);
  BEGIN
   v_date_fmt:=nvl(p_date_fmt,'YYYY-MM-DD/HH24:MI:SS');
   v_selected_start_time:=nvl(to_date(p_selected_start_time,v_date_fmt),sysdate-1/24);
   v_selected_end_time:=nvl(to_date(p_selected_end_time,v_date_fmt),sysdate); 
   v_is_realtime:= case when v_selected_end_time < sysdate - 1/24 then 0 else 1 end;
   v_outer_start_time:=v_selected_start_time- 1/24;
   v_outer_end_time:= least(v_selected_end_time+ 1/24,sysdate);
       
   EXECUTE IMMEDIATE 
	  'BEGIN :report := SYS.DBMS_PERF.REPORT_PERFHUB('
    ||'is_realtime=>:v_is_realtime,'
    ||'outer_start_time=>:v_outer_start_time,'
    ||'outer_end_time=> :v_outer_end_time,'
    ||'selected_start_time=>:v_selected_start_time,'
    ||'selected_end_time=>:v_selected_end_time,'
    ||'inst_id=>:inst_id,'
    ||'dbid=>:v_dbid,'
    ||'report_level=>:v_rpt_level); END;'
    USING OUT l_report, IN v_is_realtime, IN v_outer_start_time,IN v_outer_end_time,IN v_selected_start_time,IN v_selected_end_time,IN p_inst_id, IN p_dbid,IN p_report_type;
    RETURN l_report;
  END report_perfhub;
  
  /*************************************************************************************/

  /* -------------------------
   *
   * public common_initialization
   *
   * called by sqlt$i.common_begin, sqlt$m.main_report, sqlt$r.custom_sql_profile and sqlt$c.compare_report
   *
   * ------------------------- */
  PROCEDURE common_initialization
  IS
  BEGIN
    write_log('-> common_initialization');
    execute_immediate('ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,"');
    execute_immediate('ALTER SESSION SET NLS_SORT = BINARY');
    write_log('<- common_initialization');
  END common_initialization;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xtrsby_initialization
   *
   * called by sqlt$i.xtrsby
   *
   * ------------------------- */
  PROCEDURE xtrsby_initialization
  IS
  BEGIN
    execute_immediate('ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,"');
  END xtrsby_initialization;

  /*************************************************************************************/

END sqlt$a;
/

SET TERM ON;
SHOW ERRORS PACKAGE BODY &&tool_administer_schema..sqlt$a;
