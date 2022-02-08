CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..sqlt$i AS
/* $Header: 215187.1 sqcpkgi.pkb 12.2.171004 2017/10/04 Stelios.Charalambides@oracle.com carlos.sierra mauro.pagano abel.macias $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  LF               CONSTANT CHAR(1)      := CHR(10);
  TOOL_NAME        CONSTANT VARCHAR2(32) := '&&tool_name.';
  MAX_PUT_LINE     CONSTANT NUMBER       := 255;

  /*************************************************************************************/

  -- 171004 Extensive replacement of variables to varchar2(257)
  
  /* -------------------------
   *
   * private put_line
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
   * private write_log
   *
   * ------------------------- */
  PROCEDURE write_log (
    p_line_text IN VARCHAR2,
    p_line_type IN VARCHAR2 DEFAULT 'L' )
  IS
  BEGIN
    sqlt$a.write_log(p_line_text => p_line_text, p_line_type => p_line_type, p_package => 'I');
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
    sqlt$a.write_error('i:'||p_line_text);
  END write_error;

  /*************************************************************************************/  
  
  /* -------------------------
   *
   * private aob (assert object) 
   * 
   * Validates object name using DBMS_ASSERT
   *
   * 22170175 new 
     ------------------------- */
  FUNCTION aob(p_object varchar2) return VARCHAR2 
  IS
  l_object varchar2(32767);
  BEGIN
   l_object:=DBMS_ASSERT.QUALIFIED_SQL_NAME(p_object); 
   return l_object;
  EXCEPTION 
   when others then
   write_error('aob:'||p_object||' '||SQLERRM);
   return NULL;
  END aob;
  
  /*************************************************************************************/

  /* -------------------------
   *
   * private adl (assert database link) 
   * 
   * Validates db link and Returns it without @
   *
   * 22170175 new 
     ------------------------- */
  FUNCTION adl(p_db_link varchar2) return VARCHAR2 
  IS
  l_db_link varchar2(32767);
  BEGIN
   l_db_link:=replace(aob('SQLT@'||p_db_link),'SQLT@'); 
   return l_db_link;
  EXCEPTION 
   when others then
   return NULL;
  END adl;
  

  
  /*************************************************************************************/  
  
  
  /* -------------------------
   *
   * private call_trace_analyzer
   *
   * called by sqlt$i.xecute_end
   *
   * ------------------------- */
  PROCEDURE call_trace_analyzer (p_statement_id IN NUMBER)
  IS
    sql_rec &&tool_repository_schema..sqlt$_sql_statement%ROWTYPE;
    l_tool_execution_id NUMBER;
    l_trca_html_report  CLOB;
    l_trca_text_report  CLOB;
    l_trca_log          CLOB;
    l_trca_10046_trace  CLOB;
    l_trca_10053_trace  CLOB;
    l_file_name_prefix  VARCHAR2(32767);

  BEGIN
    write_log('=> call_trace_analyzer');

    IF sqlt$a.get_param('trace_analyzer') = 'N' OR sqlt$a.get_param('event_10046_level') = '0' THEN
      write_log('skip "trace_analyzer" as per corresponding parameter trace_analyzer or event_10046_level');
    ELSE
      sql_rec := sqlt$a.get_statement(p_statement_id);

      BEGIN
        l_file_name_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||'_';

        EXECUTE IMMEDIATE
        'BEGIN &&tool_administer_schema..trca$i.trcanlzr ( '||LF||
        '  p_file_name          => :file_name, '||LF||
        '  p_analyze            => :analyze, '||LF||
        '  p_split              => :split, '||LF||
        '  x_tool_execution_id  => :tool_execution_id, '||LF||
        '  x_html_report        => :html_report, '||LF||
        '  x_text_report        => :text_report, '||LF||
        '  x_log                => :log, '||LF||
        '  x_10046_trace        => :trace_10046, '||LF||
        '  x_10053_trace        => :trace_10053, '||LF||
        '  p_directory_alias_in => :directory_alias, '||LF||
        '  p_file_name_log      => :file_name_log, '||LF||
        '  p_file_name_html     => :file_name_html, '||LF||
        '  p_file_name_txt      => :file_name_txt '||LF||
        '); '||LF||
        'END;'
        USING
        IN     sql_rec.file_10046_10053_udump,
        IN     'YES',
        IN     'YES',
        IN OUT l_tool_execution_id,
        OUT    l_trca_html_report,
        OUT    l_trca_text_report,
        OUT    l_trca_log,
        OUT    l_trca_10046_trace,
        OUT    l_trca_10053_trace,
        IN     'SQLT$UDUMP',
        IN     l_file_name_prefix,
        IN     l_file_name_prefix,
        IN     l_file_name_prefix;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('** '||SQLERRM);
          write_log('skip "trace_analyzer" as per error above');
      END;

      IF l_tool_execution_id > 0 THEN
        sqlt$a.upload_trca_files (
          p_statement_id     => p_statement_id,
          p_execution_id     => l_tool_execution_id,
          p_file_10046_10053 => sql_rec.file_10046_10053,
          p_trca_html_report => l_trca_html_report,
          p_trca_text_report => l_trca_text_report,
          p_trca_log         => l_trca_log,
          p_trca_10046_trace => l_trca_10046_trace,
          p_trca_10053_trace => l_trca_10053_trace );
      END IF;
    END IF;

    write_log('<= call_trace_analyzer');
  END call_trace_analyzer;

  /*************************************************************************************/

  /* -------------------------
   *
   * private call_trace_analyzer_px
   *
   * called by sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE call_trace_analyzer_px (
    p_statement_id        IN NUMBER,
    p_file_name           IN VARCHAR2,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL ) -- XTRACT
  IS
    sql_rec &&tool_repository_schema..sqlt$_sql_statement%ROWTYPE;
    l_tool_execution_id NUMBER;
    l_trca_html_report  CLOB;
    l_trca_text_report  CLOB;
    l_trca_log          CLOB;
    l_trca_10046_trace  CLOB;
    l_trca_10053_trace  CLOB;
    l_file_name_prefix  VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('=> call_trace_analyzer_px');

    IF p_file_name IS NULL THEN
      write_log('skip "trace_analyzer_px" since there are no accesible PX traces');
    ELSIF sqlt$a.get_param('trace_analyzer') = 'N' OR sqlt$a.get_param('event_10046_level') = '0' THEN
      write_log('skip "trace_analyzer_px" as per corresponding parameter trace_analyzer or event_10046_level');
    ELSE
      sql_rec := sqlt$a.get_statement(p_statement_id);

      BEGIN
        IF p_out_file_identifier IS NULL THEN
          l_out_file_identifier := NULL;
        ELSE
          l_out_file_identifier := '_'||p_out_file_identifier;
        END IF;

        l_file_name_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_px_';

        EXECUTE IMMEDIATE
        'BEGIN &&tool_administer_schema..trca$i.trcanlzr ( '||LF||
        '  p_file_name           => :file_name, '||LF||
        '  p_analyze            => :analyze, '||LF||
        '  p_split              => :split, '||LF||
        '  x_tool_execution_id   => :tool_execution_id, '||LF||
        '  x_html_report         => :html_report, '||LF||
        '  x_text_report         => :text_report, '||LF||
        '  x_log                 => :log, '||LF||
        '  x_10046_trace         => :trace_10046, '||LF||
        '  x_10053_trace         => :trace_10053, '||LF||
        '  p_file_name_log       => :file_name_log, '||LF||
        '  p_file_name_html      => :file_name_html, '||LF||
        '  p_file_name_txt       => :file_name_txt, '||LF||
        '  p_out_file_identifier => :out_file_identifier '||LF||
        '); '||LF||
        'END;'
        USING
        IN     p_file_name,
        IN     'YES',
        IN     'NO',
        IN OUT l_tool_execution_id,
        OUT    l_trca_html_report,
        OUT    l_trca_text_report,
        OUT    l_trca_log,
        OUT    l_trca_10046_trace,
        OUT    l_trca_10053_trace,
        IN     l_file_name_prefix,
        IN     l_file_name_prefix,
        IN     l_file_name_prefix,
        IN     p_out_file_identifier;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('** '||SQLERRM);
          write_log('skip "trace_analyzer_px" as per error above');
      END;

      IF l_tool_execution_id > 0 THEN
        sqlt$a.upload_trca_files_px (
          p_statement_id        => p_statement_id,
          p_execution_id        => l_tool_execution_id,
          p_trca_html_report    => l_trca_html_report,
          p_trca_text_report    => l_trca_text_report,
          p_trca_log            => l_trca_log,
          p_out_file_identifier => p_out_file_identifier );
      END IF;
    END IF;

    write_log('<= call_trace_analyzer_px');
  END call_trace_analyzer_px;

  /*************************************************************************************/

  /* -------------------------
   *
   * public remote_call_trace_analyzer
   *
   * called by sqlt$i.remote_trace_analyzer_and_copy
   *
   * executed in remote system it runs trca passing filenames and
   * keeping trca files as clobs in db.
   *
   * ------------------------- */
  PROCEDURE remote_call_trace_analyzer (
    p_statement_id           IN  NUMBER,
    p_db_link                IN  VARCHAR2,
    p_file_10046_10053_udump IN  VARCHAR2,
    p_file_10046_10053       IN  VARCHAR2,
    p_out_file_identifier    IN VARCHAR2 DEFAULT NULL )
  IS
    l_top_sql_ids       VARCHAR2(32767);
    l_file_name_prefix  VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);

  BEGIN
    write_log('=> remote_call_trace_analyzer');

    IF sqlt$a.get_param('trace_analyzer') = 'N' OR sqlt$a.get_param('event_10046_level') = '0' THEN
      write_log('skip "trace_analyzer" as per corresponding parameter trace_analyzer or event_10046_level');
    ELSE
      BEGIN
        IF p_out_file_identifier IS NULL THEN
          l_out_file_identifier := NULL;
        ELSE
          l_out_file_identifier := '_'||p_out_file_identifier;
        END IF;

        -- files generated by trca on remote include sqlt_sNNNNN and link name
        l_file_name_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_'||sqlt$a.get_db_link_short(p_db_link);

        write_log('calling &&tool_administer_schema..trca$i.trcanlzr_remote');
        EXECUTE IMMEDIATE
        'BEGIN &&tool_administer_schema..trca$i.trcanlzr_remote ( '||LF||
        '  p_file_name            => :file_name, '||LF||
        '  p_directory_alias_in   => :directory_alias, '||LF||
        '  p_analyze              => :analyze, '||LF||
        '  p_split                => :split, '||LF||
        '  p_file_name_log        => :file_name_log, '||LF||
        '  p_file_name_html       => :file_name_html, '||LF||
        '  p_file_name_txt        => :file_name_txt, '||LF||
        '  p_split_10046_filename => :file_name_10046, '||LF||
        '  p_split_10053_filename => :file_name_10053, '||LF||
        '  p_out_file_identifier  => :out_file_identifier '||LF||
        '); '||LF||
        'END;'
        USING
        IN p_file_10046_10053_udump,
        IN 'SQLT$UDUMP',
        IN 'YES',
        IN 'YES',
        IN l_file_name_prefix||'_trca.log',
        IN l_file_name_prefix||'_trca.html',
        IN l_file_name_prefix||'_trca.txt',
        IN l_file_name_prefix||'_10046.trc',
        IN l_file_name_prefix||'_10053.trc',
        IN l_out_file_identifier;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('skip "trace_analyzer" as per error above');
          write_log('** '||SQLERRM);
      END;
    END IF;

    write_log('<= remote_call_trace_analyzer');
  END remote_call_trace_analyzer;

  /*************************************************************************************/

  /* -------------------------
   *
   * public remote_event_10046_10053_on
   *
   * called by: sqlt$i.remote_trace_begin
   *
   * this api is executed on remote when remote_trace_begin is executed in local
   *
   * ------------------------- */
  PROCEDURE remote_event_10046_10053_on (
    p_statement_id IN NUMBER,
    p_10046        IN VARCHAR2 DEFAULT 'N' )
  IS
  BEGIN
    sqlt$a.remote_event_10046_10053_on (
      p_statement_id => p_statement_id,
      p_10046        => p_10046 );
  END remote_event_10046_10053_on;

  /*************************************************************************************/

  /* -------------------------
   *
   * private remote_event_10046_10053_off
   *
   * called by: sqlt$i.remote_trace_end
   *
   * this api is executed on remote when remote_trace_end is executed in local
   *
   * ------------------------- */
  PROCEDURE remote_event_10046_10053_off (
    p_statement_id           IN  NUMBER,
    p_db_link                IN  VARCHAR2,
    p_10046                  IN  VARCHAR2 DEFAULT 'N',
    x_file_10046_10053_udump OUT VARCHAR2,
    x_file_10046_10053       OUT VARCHAR2 )
  IS
    l_event VARCHAR2(32);
  BEGIN
    sqlt$a.remote_event_10046_10053_off (
      p_statement_id           => p_statement_id,
      p_db_link                => p_db_link,
      p_10046                  => p_10046,
      x_file_10046_10053_udump => x_file_10046_10053_udump,
      x_file_10046_10053       => x_file_10046_10053 );
  END remote_event_10046_10053_off;

  /*************************************************************************************/

  /* -------------------------
   *
   * private remote_trace_begin
   *
   * called by: sqlt$i.xecute_begin, sqlt$i.xplain_begin, sqlt$i.explain_plan_and_10053
   *
   * this api is executed in local system, but calls remote_event_10046_10053_on in remote
   * it is the latter that actually turns trace on
   * ------------------------- */
  PROCEDURE remote_trace_begin (
    p_statement_id IN NUMBER,
    p_sql_id       IN VARCHAR2 DEFAULT NULL,
    p_10046        IN VARCHAR2 DEFAULT 'N' )
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    lnk_rec &&tool_repository_schema..sqli$_db_link%ROWTYPE;
    l_dummy NUMBER;
    l_count INTEGER := 0;
    l_count2 INTEGER := 0;
	l_db_link varchar2(32767); -- 22170175
  BEGIN
    write_log('=> remote_trace_begin');

    IF sqlt$a.s_sqlt_method = 'XTRSBY' THEN
      write_log('skip tracing '||sqlt$a.s_sqlt_method);
    ELSIF sqlt$a.get_param('distributed_queries') = 'N' THEN
      write_log('skip tracing distributed queries as per corresponding parameter distributed_queries');
    ELSE
      DELETE &&tool_repository_schema..sqlg$_temp;
      sqlt$a.get_db_links;
      sqlt$a.get_db_links(p_sql_id);

      FOR i IN (
               (SELECT p.object_node db_link -- db links known about in sqlt repository
                  FROM &&tool_repository_schema..sqlt$_plan_extension p
                 WHERE p.object_node IS NOT NULL
                   AND p.object_node NOT LIKE '%:%'
                   AND EXISTS
               (SELECT NULL -- these are the db links that exist on sys.dba_db_links
                  FROM &&tool_repository_schema..sqlg$_temp d
                 WHERE d.c1 = p.object_node
                   AND d.n1 = 1)
                 UNION
                SELECT db_link -- db links registered manually
                  FROM &&tool_repository_schema..sqli$_db_link
                 WHERE statement_id = 0
                 UNION
                SELECT c1 db_link -- db links because sql references them as per v$sql_plan
                  FROM &&tool_repository_schema..sqlg$_temp
                 WHERE n1 = 2)
                 MINUS
                SELECT l.db_link -- db links already associated to this statement id
                  FROM &&tool_repository_schema..sqli$_db_link l
                 WHERE l.statement_id = p_statement_id)
      LOOP
        l_count := l_count + 1;
        lnk_rec := NULL;
        lnk_rec.statement_id := p_statement_id;
        lnk_rec.statid := sqlt$a.get_statid(p_statement_id);
        lnk_rec.db_link := i.db_link;
        lnk_rec.event_10046 := p_10046;
        lnk_rec.error_flag := 'N';
        write_log('calling &&tool_administer_schema..sqlt$i.remote_event_10046_10053_on@'||i.db_link||'('||p_statement_id||', '''||p_10046||''')');
        BEGIN
		  l_db_link:=adl(i.db_link); -- 22170175
          EXECUTE IMMEDIATE 'BEGIN &&tool_administer_schema..sqlt$i.remote_event_10046_10053_on@'||l_db_link||'(:statement_id, :e10046); END;'
          USING IN p_statement_id, IN p_10046;
          INSERT INTO &&tool_repository_schema..sqli$_db_link VALUES lnk_rec;
          l_count2 := l_count2 + 1;
        EXCEPTION
          WHEN OTHERS THEN
            write_log('** '||SQLERRM);
            write_log('calling &&tool_administer_schema..sqlt$i.remote_event_10046_10053_on@'||i.db_link||'('||p_statement_id||', '''||p_10046||''') failed with error above. Process continues.');
            --write_log('if db_link "'||i.db_link||'" is no longer needed ignore this error, or inactivate the db_link on SQLT with SQL> EXEC &&tool_administer_schema..sqlt$i.unregister_db_link('''||i.db_link||''');');
            lnk_rec.error_flag := 'Y';
        END;
        IF lnk_rec.error_flag = 'Y' THEN
          INSERT INTO &&tool_repository_schema..sqli$_db_link VALUES lnk_rec;
        END IF;
      END LOOP;

      IF l_count > 0 THEN
        write_log('remote db_links found at this step:'||l_count);
        write_log('remote db_links activated at this step:'||l_count2);
      ELSE
        write_log('no remote db_links were found/activated at this step');
      END IF;
    END IF;

    COMMIT; -- AUTONOMOUS_TRANSACTION

    write_log('<= remote_trace_begin');
  END remote_trace_begin;

  /*************************************************************************************/

  /* -------------------------
   *
   * private remote_trace_end
   *
   * called by: sqlt$i.common_calls
   *
   * this api is executed in local system, but calls remote_event_10046_10053_off in remote
   * it is the latter that acuatually turns trace off
   * 
   * ------------------------- */
  PROCEDURE remote_trace_end (p_statement_id IN NUMBER)
  IS
    l_file_10046_10053_udump VARCHAR2(256);
    l_file_10046_10053 VARCHAR2(256);
	l_db_link varchar2(32767); -- 22170175 not to be used on the write_log so injection attempts are logged.
  BEGIN
    write_log('=> remote_trace_end');

    IF sqlt$a.get_param('distributed_queries') = 'N' THEN
      write_log('skip tracing distributed queries as per corresponding parameter distributed_queries');
    ELSE
      FOR i IN (SELECT db_link, event_10046
                  FROM &&tool_repository_schema..sqli$_db_link
                 WHERE statement_id = p_statement_id
                   AND error_flag = 'N'
                 ORDER BY
                       db_link)
      LOOP
        write_log('calling &&tool_administer_schema..sqlt$i.remote_event_10046_10053_off@'||i.db_link||'('||p_statement_id||', '''||i.db_link||''', '''||i.event_10046||''')');
        BEGIN
		  l_db_link:=adl(i.db_link); -- 22170175
          EXECUTE IMMEDIATE 'BEGIN &&tool_administer_schema..sqlt$i.remote_event_10046_10053_off@'||l_db_link||'(:statement_id, :db_link, :e10046, :file_10046_10053_udump, :file_10046_10053); END;'
          USING IN p_statement_id, IN i.db_link, IN i.event_10046, OUT l_file_10046_10053_udump, OUT l_file_10046_10053;

          write_log('remote trace udump:'||l_file_10046_10053_udump);
          write_log('remote trace local:'||l_file_10046_10053);

          -- records locally the name of the remote trace
          UPDATE &&tool_repository_schema..sqli$_db_link
             SET file_10046_10053_udump = l_file_10046_10053_udump,
                 file_10046_10053 = l_file_10046_10053
           WHERE statement_id = p_statement_id
             AND db_link = i.db_link;
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error('calling &&tool_administer_schema..sqlt$i.remote_event_10046_10053_off@'||i.db_link||'('||p_statement_id||', '''||i.db_link||''', '''||i.event_10046||''') failed with error above. Process continues.');
        END;
      END LOOP;

      COMMIT;
    END IF;

    write_log('<= remote_trace_end');
  END remote_trace_end;

  /*************************************************************************************/

  /* -------------------------
   *
   * private remote_trace_analyzer_and_copy
   *
   * called by: sqlt$i.common_calls
   *
   * this api is execute in local but it calls trca in remote system to
   * analyze the traces that were generated in remote.
   * 
   * ------------------------- */
  PROCEDURE remote_trace_analyzer_and_copy (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL ) -- XTRACT
  IS
    l_tool_execution_id NUMBER;
    l_statid VARCHAR2(257);
    l_hash_values VARCHAR2(32767);
    l_sql_ids VARCHAR2(32767);
    l_ids VARCHAR2(32767);
    l_id VARCHAR2(32767);
    l_instr NUMBER;
    l_file_name_prefix  VARCHAR2(32767);
    l_out_file_identifier VARCHAR2(32767);
	l_db_link  VARCHAR2(32767); -- 22170175 not to be used on the write_log so injection attempts are logged.

  BEGIN
    write_log('=> remote_trace_analyzer_and_copy');

    IF sqlt$a.get_param('distributed_queries') = 'N' THEN
      write_log('skip remote trace analyzer and copy as per corresponding parameter distributed_queries');
    ELSE
      l_statid := sqlt$a.get_statid(p_statement_id);

      FOR i IN (SELECT DISTINCT l.*
                  FROM &&tool_repository_schema..sqlt$_plan_extension p,
                       &&tool_repository_schema..sqli$_db_link l
                 WHERE p.statement_id = p_statement_id
                   AND p.object_node NOT LIKE '%:%'
                   AND p.statement_id = l.statement_id
                   AND p.object_node = l.db_link
                   AND l.error_flag = 'N'
                   AND l.file_10046_10053_udump IS NOT NULL
                 ORDER BY
                       l.db_link)
      LOOP
	    l_db_link :=adl(i.db_link); -- 22170175
        IF i.event_10046 = 'Y' THEN
          BEGIN
            -- executes trca in remote system
            write_log('calling &&tool_administer_schema..sqlt$i.remote_call_trace_analyzer@'||i.db_link||'('||p_statement_id||', '''||i.db_link||''', '''||i.file_10046_10053_udump||''', '''||i.file_10046_10053||''', '''||p_out_file_identifier||''')');
            EXECUTE IMMEDIATE 'BEGIN &&tool_administer_schema..sqlt$i.remote_call_trace_analyzer@'||l_db_link||'(:statement_id, :db_link, :file_10046_10053_udump, :file_10046_10053, :out_file_identifier); END;'
            USING IN p_statement_id, IN l_db_link, IN i.file_10046_10053_udump, IN i.file_10046_10053, IN p_out_file_identifier;
          EXCEPTION
            WHEN OTHERS THEN
              write_error(SQLERRM);
              write_error('calling &&tool_administer_schema..sqlt$i.remote_call_trace_analyzer@'||i.db_link||'('||p_statement_id||', '''||l_db_link||''', '''||i.file_10046_10053_udump||''', '''||i.file_10046_10053||''', '''||p_out_file_identifier||''') failed with error above. Process continues.');
          END;

          -- gets the tool_execution_id from most recent execution of trca (which corresponds to this SQLT execution on local)
          BEGIN
           write_log('calling SELECT MAX(id) FROM &&tool_repository_schema..trca$_tool_execution@'||i.db_link);
           EXECUTE IMMEDIATE
           'SELECT MAX(id) FROM &&tool_repository_schema..trca$_tool_execution@'||l_db_link INTO l_tool_execution_id;
           write_log('trca.tool_execution_id:"'||l_tool_execution_id||'"');
          EXCEPTION
            WHEN OTHERS THEN
              write_error(SQLERRM);
              write_error('calling SELECT MAX(id) FROM &&tool_repository_schema..trca$_tool_execution@'||i.db_link||' failed with error above. Process continues.');
              l_tool_execution_id := NULL;
          END;

          IF l_tool_execution_id > 0 THEN
            -- get hv for remote top sql excluding sys
            BEGIN
              write_log('calling &&tool_administer_schema..trca$i.top_sql@'||i.db_link||'('||l_tool_execution_id||', ''N'', ''A'', ''H'')');
              EXECUTE IMMEDIATE
              'SELECT &&tool_administer_schema..trca$i.top_sql@'||l_db_link||'(:tool_execution_id, :sys, :time, :id_type) FROM dual'
              INTO l_hash_values
              USING IN l_tool_execution_id, IN 'N', IN 'A', IN 'H';
             write_log('trca.top_sql:"'||l_hash_values||'"');
            EXCEPTION
              WHEN OTHERS THEN
                write_error(SQLERRM);
                write_error('calling &&tool_administer_schema..trca$i.top_sql@'||i.db_link||'('||l_tool_execution_id||', ''N'', ''A'', ''H'') failed with error above. Process continues.');
            END;

            -- get sql_id for remote top sql excluding sys
            BEGIN
              write_log('calling &&tool_administer_schema..trca$i.top_sql@'||i.db_link||'('||l_tool_execution_id||', ''N'', ''A'', ''S'')');
              EXECUTE IMMEDIATE
              'SELECT &&tool_administer_schema..trca$i.top_sql@'||l_db_link||'(:tool_execution_id, :sys, :time, :id_type) FROM dual'
              INTO l_sql_ids
              USING IN l_tool_execution_id, IN 'N', IN 'A', IN 'S';
              write_log('trca.top_sql:"'||l_sql_ids||'"');
            EXCEPTION
              WHEN OTHERS THEN
                write_error(SQLERRM);
                write_error('calling &&tool_administer_schema..trca$i.top_sql@'||i.db_link||'('||l_tool_execution_id||', ''N'', ''A'', ''S'') failed with error above. Process continues.');
            END;
          END IF;
        ELSE
          l_tool_execution_id := NULL;
          l_sql_ids := NULL;
          l_hash_values := NULL;
        END IF;

        -- work with sql_id if avail else with hv
        IF l_sql_ids IS NOT NULL THEN
          l_ids := TRIM(',' FROM REPLACE(l_sql_ids, ' '))||',';
        ELSIF l_hash_values IS NOT NULL THEN
          l_ids := TRIM(',' FROM REPLACE(l_hash_values, ' '))||',';
        ELSE
          l_ids := NULL;
        END IF;

        IF p_out_file_identifier IS NULL THEN
          l_out_file_identifier := NULL;
        ELSE
          l_out_file_identifier := '_'||p_out_file_identifier;
        END IF;

        -- filenames in sync with remote_call_trace_analyzer
        l_file_name_prefix := 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_'||sqlt$a.get_db_link_short(i.db_link);

        -- process remote xtract on top sql using sql_id (if avail) or hv
        WHILE l_ids IS NOT NULL
        LOOP
          l_instr := INSTR(l_ids, ',');
          IF l_instr > 0 THEN
            l_id := SUBSTR(l_ids, 1, l_instr - 1);
            l_ids := SUBSTR(l_ids, l_instr + 1);
          ELSE
            l_id := NULL;
            l_ids := NULL;
          END IF;

          IF l_id IS NOT NULL THEN
            -- calls sqlt xtract on remote for each top sql (excludes sys)
            BEGIN
              write_log('calling &&tool_administer_schema..sqlt$i.remote_xtract@'||i.db_link||'('||p_statement_id||', '''||i.db_link||''', '''||l_file_name_prefix||''', '''||l_id||''')');
              EXECUTE IMMEDIATE
              'BEGIN &&tool_administer_schema..sqlt$i.remote_xtract@'||l_db_link||'(:group_id, :db_link, :file_prefix, :sql_id_or_hash_value); END;'
              USING IN p_statement_id, IN i.db_link, IN l_file_name_prefix, IN l_id;
            EXCEPTION
              WHEN OTHERS THEN
                write_error(SQLERRM);
                write_error('calling &&tool_administer_schema..sqlt$i.remote_xtract@'||i.db_link||'('||p_statement_id||', '''||i.db_link||''', '''||l_file_name_prefix||''', '''||l_id||''') failed with error above. Process continues.');
            END;
          END IF;
        END LOOP;

        BEGIN
          write_log('copying remote trace and SQLT files from &&tool_repository_schema..sqli$_file@'||i.db_link);
          EXECUTE IMMEDIATE
          'INSERT INTO &&tool_repository_schema..sqli$_file ( '||LF||
          '  statement_id, '||LF||
          '  statid, '||LF||
          '  statement_id2, '||LF||
          '  file_type, '||LF||
          '  filename, '||LF||
          '  file_date, '||LF||
          '  file_size, '||LF||
          '  username, '||LF||
          '  db_link, '||LF||
          '  file_text '||LF||
          ') '||LF||
          'SELECT '||LF||
          '  statement_id, '||LF||
          '  statid, '||LF||
          '  statement_id2, '||LF||
          '  file_type, '||LF||
          '  filename, '||LF||
          '  file_date, '||LF||
          '  file_size, '||LF||
          '  username, '||LF||
          '  db_link, '||LF||
          '  file_text '||LF||
          'FROM &&tool_repository_schema..sqli$_file@'||l_db_link||' '||LF||
          'WHERE :statement_id IN (statement_id, statement_id2)'
          USING IN p_statement_id;
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error('copying remote trace and SQLT files from &&tool_repository_schema..sqli$_file@'||i.db_link||' failed with error above. Process continues.');
        END;

        BEGIN
          IF i.event_10046 = 'Y' THEN
            write_log('copying remote TRCA files from &&tool_repository_schema..trca$_file@'||i.db_link);
            EXECUTE IMMEDIATE
            'INSERT INTO &&tool_repository_schema..sqli$_file ( '||LF||
            '  statement_id, '||LF||
            '  statid, '||LF||
            '  statement_id2, '||LF||
            '  file_type, '||LF||
            '  filename, '||LF||
            '  file_date, '||LF||
            '  file_size, '||LF||
            '  username, '||LF||
            '  db_link, '||LF||
            '  file_text '||LF||
            ') '||LF||
            'SELECT '||LF||
            '  :statement_id, '||LF||
            '  :statid, '||LF||
            '  NULL, '||LF||
            '  file_type, '||LF||
            '  filename, '||LF||
            '  file_date, '||LF||
            '  file_size, '||LF||
            '  username, '||LF||
            '  :db_link, '||LF||
            '  file_text '||LF||
            'FROM &&tool_repository_schema..trca$_file@'||l_db_link||' '||LF||
            'WHERE tool_execution_id = :tool_execution_id'
            USING IN p_statement_id, IN l_statid, IN l_db_link, IN l_tool_execution_id;
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error('copying remote TRCA files from &&tool_repository_schema..trca$_file@'||i.db_link||' failed with error above. Process continues.');
        END;

        BEGIN
          IF i.event_10046 = 'Y' AND l_sql_ids||l_hash_values IS NOT NULL THEN
            write_log('copying cbo stats from &&tool_repository_schema..sqlt$_stattab@'||i.db_link||'for s'||sqlt$a.get_statement_id_c(p_statement_id)||'%');
            EXECUTE IMMEDIATE
            'INSERT INTO &&tool_repository_schema..sqlt$_stattab ( '||LF||
            '  statid, '||LF||
            '  type, '||LF||
            '  version, '||LF||
            '  flags, '||LF||
            '  c1, '||LF||
            '  c2, '||LF||
            '  c3, '||LF||
            '  c4, '||LF||
            '  c5, '||LF||
            '  n1, '||LF||
            '  n2, '||LF||
            '  n3, '||LF||
            '  n4, '||LF||
            '  n5, '||LF||
            '  n6, '||LF||
            '  n7, '||LF||
            '  n8, '||LF||
            '  n9, '||LF||
            '  n10, '||LF||
            '  n11, '||LF||
            '  n12, '||LF||
            '  d1, '||LF||
            '  r1, '||LF||
            '  r2, '||LF||
            '  ch1 '||LF||
            ') '||LF||
            'SELECT '||LF||
            '  statid, '||LF||
            '  type, '||LF||
            '  version, '||LF||
            '  flags, '||LF||
            '  c1, '||LF||
            '  c2, '||LF||
            '  c3, '||LF||
            '  c4, '||LF||
            '  c5, '||LF||
            '  n1, '||LF||
            '  n2, '||LF||
            '  n3, '||LF||
            '  n4, '||LF||
            '  n5, '||LF||
            '  n6, '||LF||
            '  n7, '||LF||
            '  n8, '||LF||
            '  n9, '||LF||
            '  n10, '||LF||
            '  n11, '||LF||
            '  n12, '||LF||
            '  d1, '||LF||
            '  r1, '||LF||
            '  r2, '||LF||
            '  ch1 '||LF||
            'FROM &&tool_repository_schema..sqlt$_stattab@'||l_db_link||' '||LF||
            'WHERE statid LIKE :statid'
            USING IN 's'||sqlt$a.get_statement_id_c(p_statement_id)||'%';
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error('copying cbo stats from &&tool_repository_schema..sqlt$_stattab@'||i.db_link||'for s'||sqlt$a.get_statement_id_c(p_statement_id)||'% failed with error above. Process continues.');
        END;

        BEGIN
          write_log('copying remote log from &&tool_repository_schema..sqlt$_log@'||i.db_link);
          DELETE &&tool_repository_schema..sqlg$_temp;

          EXECUTE IMMEDIATE
          'INSERT INTO &&tool_repository_schema..sqlg$_temp ( '||LF||
          '  n1, '||LF||
          '  c1 '||LF||
          ') '||LF||
          'SELECT '||LF||
          '  line_id, '||LF||
          '  line_text '||LF||
          'FROM &&tool_repository_schema..sqlt$_log@'||l_db_link||' '||LF||
          'WHERE statement_id = :statement_id '||LF||
          'AND line_type = :line_type'
          USING IN p_statement_id, IN 'L';

          write_log('--- log from '||i.db_link||' (begin) ---');
          FOR j IN (SELECT c1 FROM &&tool_repository_schema..sqlg$_temp ORDER BY n1)
          LOOP
            write_log(j.c1);
          END LOOP;
          write_log('--- log from '||i.db_link||' (end) ---');
        EXCEPTION
          WHEN OTHERS THEN
            write_error(SQLERRM);
            write_error('copying remote log from &&tool_repository_schema..sqlt$_log@'||i.db_link||' failed with error above. Process continues.');
        END;
      END LOOP;

      COMMIT;
    END IF;

    write_log('<= remote_trace_analyzer_and_copy');
  END remote_trace_analyzer_and_copy;

  /*************************************************************************************/

  /* -------------------------
   *
   * public register_db_link
   *
   * api to register db links manually
   * 
   * ------------------------- */
  PROCEDURE register_db_link (p_db_link IN VARCHAR2)
  IS
    l_dummy NUMBER;
    l_statid VARCHAR2(257);
    l_db_link VARCHAR2(257);
  BEGIN
    l_db_link := adl(UPPER(TRIM(p_db_link))); -- 22170175
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM dual@'||l_db_link INTO l_dummy;
    DELETE &&tool_repository_schema..sqli$_db_link WHERE statement_id = 0 AND db_link = l_db_link;
    l_statid := sqlt$a.get_statid(0);
    INSERT INTO &&tool_repository_schema..sqli$_db_link (statement_id, statid, db_link) VALUES (0, l_statid, l_db_link);
    COMMIT;
  END register_db_link;

  /*************************************************************************************/

  /* -------------------------
   *
   * public unregister_db_link
   *
   * ------------------------- */
  PROCEDURE unregister_db_link (p_db_link IN VARCHAR2)
  IS
    l_db_link VARCHAR2(257);
  BEGIN
    l_db_link := UPPER(TRIM(p_db_link));
    DELETE &&tool_repository_schema..sqli$_db_link WHERE statement_id = 0 AND db_link = l_db_link;
    COMMIT;
  END unregister_db_link;

  /*************************************************************************************/

  /* -------------------------
   *
   * private explain_plan_and_10053
   *
   * called by: sqlt$i.xtract and sqlt$i.xecute_end
   *
   * ------------------------- */
  PROCEDURE explain_plan_and_10053 (
    p_statement_id        IN NUMBER,
    p_sql_id              IN VARCHAR2 DEFAULT NULL,  -- xecute_end
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL ) -- xtract
  IS
    sql_rec &&tool_repository_schema..sqlt$_sql_statement%ROWTYPE;
    l_string  VARCHAR2(32767);
    l_error   VARCHAR2(32767);
    l_sqltext VARCHAR2(32767);
	l_colgroup_seed_secs NUMBER;  --12.1.04
  BEGIN
    write_log('=> explain_plan_and_10053');

    sql_rec := sqlt$a.get_statement(p_statement_id);
	l_colgroup_seed_secs := sqlt$a.get_param_n('colgroup_seed_secs');  --12.1.04

    write_log('sql_length = "'||sql_rec.sql_length||'"');
    IF sql_rec.sql_length > 32666 THEN
      write_log('cannot generate an explain plan for a SQL this long');
    ELSE
      remote_trace_begin(p_statement_id, p_sql_id, 'Y');
      sqlt$a.event_10053_on(p_statement_id);
	  
	  IF sqlt$a.get_rdbms_version >= '11.2' AND l_colgroup_seed_secs > 0 THEN  --12.1.04
         EXECUTE IMMEDIATE 'BEGIN DBMS_STATS.SEED_COL_USAGE(NULL,NULL,'||l_colgroup_seed_secs||'); END;';
		 write_log('Turned on DBMS_STATS.SEED_COL_USAGE for '||l_colgroup_seed_secs||' seconds');    
	  END IF;	  
	  
      BEGIN
        l_error := NULL;
        l_string := 'EXPLAIN PLAN SET statement_id = '''||sqlt$a.get_statement_id_c(p_statement_id)||''' INTO &&tool_repository_schema..sqlt$_sql_plan_table FOR';
        l_sqltext := SYS.DBMS_LOB.SUBSTR(sql_rec.sql_text_clob_stripped); -- first up to 32666 characters
        l_sqltext := l_string||LF||l_sqltext;

        EXECUTE IMMEDIATE l_sqltext;
      EXCEPTION
        WHEN OTHERS THEN
          l_error := SQLERRM;
      END;
      sqlt$a.event_10053_off(p_statement_id, l_error, p_out_file_identifier);
      sqlt$a.clean_sqlt$_sql_plan_table(p_statement_id);

      IF l_error IS NULL THEN
        sqlt$d.capture_xplain_plan_hash_value(p_statement_id, l_string);
      ELSE
        write_error('"EXPLAIN PLAN FOR" this SQL errored out when executed connected as "'||USER||'". Always execute SQLT connected as the application user.');
        write_error(l_error);
      END IF;
    END IF;

    write_log('<= explain_plan_and_10053');
  END explain_plan_and_10053;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_full_table_scan_cost
   *
   * called by: sqlt$i.common_calls
   * 
   * ------------------------- */
  PROCEDURE compute_full_table_scan_cost(p_statement_id IN NUMBER)
  IS
    l_sql VARCHAR2(32767);
    l_cost NUMBER;
    l_fts VARCHAR2(257);
	
  BEGIN
    write_log('=> compute_full_table_scan_cost');
    l_fts := 'FTS'||p_statement_id;

    FOR i IN (SELECT source, owner, table_name
                FROM &&tool_administer_schema..sqlt$_dba_all_tables_v
               WHERE statement_id = p_statement_id
               ORDER BY
                     owner, table_name)
    LOOP
      BEGIN
        l_sql := 'EXPLAIN PLAN SET statement_id = '''||l_fts||''' INTO &&tool_repository_schema..sqlt$_sql_plan_table FOR SELECT /*+ FULL(t) */ * FROM '
		||aob('"'||i.owner||'"."'||i.table_name||'"')||' t'; -- 22170175
        DELETE &&tool_repository_schema..sqlt$_sql_plan_table WHERE statement_id = l_fts;
        EXECUTE IMMEDIATE l_sql;
        SELECT MAX(cost) INTO l_cost FROM &&tool_repository_schema..sqlt$_sql_plan_table WHERE statement_id = l_fts;
        write_log('full table scan cost for "'||i.owner||'"."'||i.table_name||'" is '||l_cost, 'S');
        DELETE &&tool_repository_schema..sqlt$_sql_plan_table WHERE statement_id = l_fts;
        IF l_cost IS NOT NULL THEN
          IF i.source = 'DBA_TABLES' THEN
            UPDATE &&tool_repository_schema..sqlt$_dba_tables
               SET full_table_scan_cost = l_cost
             WHERE statement_id = p_statement_id
               AND owner = i.owner
               AND table_name = i.table_name;
          ELSE
            UPDATE &&tool_repository_schema..sqlt$_dba_object_tables
               SET full_table_scan_cost = l_cost
             WHERE statement_id = p_statement_id
               AND owner = i.owner
               AND table_name = i.table_name;
          END IF;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_log(l_sql);
          write_log('** '||SQLERRM);
      END;
    END LOOP;

    COMMIT;

    write_log('<= compute_full_table_scan_cost');
  END compute_full_table_scan_cost;

  /*************************************************************************************/

  /* -------------------------
   *
   * private sql_tuning_advisor
   *
   * called by: sqlt$i.sql_tuning_advisor
   *
   * ------------------------- */
  PROCEDURE sql_tuning_advisor (
    p_task_name IN VARCHAR2,
    x_report    IN OUT NOCOPY CLOB,
    x_script    IN OUT NOCOPY CLOB )
  IS
  BEGIN
    IF p_task_name IS NOT NULL THEN
      write_log('-> SYS.DBMS_SQLTUNE.EXECUTE_TUNING_TASK('''||p_task_name||''')');
      SYS.DBMS_SQLTUNE.EXECUTE_TUNING_TASK(task_name => p_task_name);
      write_log('<- SYS.DBMS_SQLTUNE.EXECUTE_TUNING_TASK('''||p_task_name||''')');

      x_report :=
      SYS.DBMS_SQLTUNE.REPORT_TUNING_TASK (
        task_name => p_task_name,
        type      => 'TEXT',
        level     => 'ALL' );

      x_script :=
      SYS.DBMS_SQLTUNE.SCRIPT_TUNING_TASK(task_name => p_task_name);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error(SQLERRM);
      write_error('DBMS_SQLTUNE failed with error above. Process continues.');
  END sql_tuning_advisor;

  /*************************************************************************************/

  /* -------------------------
   *
   * private sql_tuning_advisor
   *
   * called by: sqlt$i.common_calls
   *
   * ------------------------- */
  PROCEDURE sql_tuning_advisor (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL ) -- xtract
  IS
    sql_rec &&tool_repository_schema..sqlt$_sql_statement%ROWTYPE;
    l_max_plan_et_secs NUMBER;
    l_sta_time_limit_secs NUMBER;
    l_report_mem CLOB := NULL;
    l_script_mem CLOB := NULL;
    l_report_txt CLOB := NULL;
    l_script_txt CLOB := NULL;
    l_report_awr CLOB := NULL;
    l_script_awr CLOB := NULL;
  BEGIN
    write_log('=> sql_tuning_advisor');

    l_max_plan_et_secs := sqlt$d.max_plan_elapsed_time_secs(p_statement_id);
    l_sta_time_limit_secs := TO_NUMBER(sqlt$a.get_param('sta_time_limit_secs'));

    write_log('max_plan_et_secs:'||l_max_plan_et_secs||' sta_time_limit_secs:'||l_sta_time_limit_secs);

    IF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip STA due in this method');
    ELSIF l_max_plan_et_secs > l_sta_time_limit_secs THEN
      write_log('skip STA due to excessive duration');
    ELSE
      sql_rec := sqlt$a.get_statement(p_statement_id);

      -- from memory
      sql_tuning_advisor (
        p_task_name => sql_rec.sta_task_name_mem,
        x_report    => l_report_mem,
        x_script    => l_script_mem );

      -- from text
      sql_tuning_advisor (
        p_task_name => sql_rec.sta_task_name_txt,
        x_report    => l_report_txt,
        x_script    => l_script_txt );

      -- from awr
      sql_tuning_advisor (
        p_task_name => sql_rec.sta_task_name_awr,
        x_report    => l_report_awr,
        x_script    => l_script_awr );

      -- upload REPORT_TUNING_TASK and SCRIPT_TUNING_TASK files
      sqlt$a.upload_sta_files (
        p_statement_id        => p_statement_id,
        p_report_mem          => l_report_mem,
        p_script_mem          => l_script_mem,
        p_report_txt          => l_report_txt,
        p_script_txt          => l_script_txt,
        p_report_awr          => l_report_awr,
        p_script_awr          => l_script_awr,
        p_out_file_identifier => p_out_file_identifier );
    END IF;

    write_log('<= sql_tuning_advisor');
  END sql_tuning_advisor;

  /*************************************************************************************/

  /* -------------------------
   *
   * private test_case_builder
   *
   * called by: sqlt$i.common_calls
   * 
   * ------------------------- */
  PROCEDURE test_case_builder (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL, -- XTRACT
    p_tcb_directory_name  IN VARCHAR2 DEFAULT 'SQLT$STAGE' ) -- xtract
  IS
    sql_rec &&tool_repository_schema..sqlt$_sql_statement%ROWTYPE;
    l_testcase CLOB := NULL;
    l_out_file_identifier VARCHAR2(32767);
   
  BEGIN
    write_log('=> test_case_builder');

    IF sqlt$a.get_rdbms_release < 11 THEN
      write_log('skip test_case_builder since rdbms_release does not provide it');
    ELSIF sqlt$a.get_param('test_case_builder') = 'N' THEN
      write_log('skip "test_case_builder" as per corresponding parameter "test_case_builder"');
    ELSIF NVL(sqlt$a.s_xtrxec, 'N') = 'Y' THEN -- s_xtrxec is Y during XECUTE phase
      write_log('skip "test_case_builder" as per parameter "sqlt$a.s_xtrxec"'); -- tcb was done during XTRACT phase
    ELSIF sqlt$a.s_db_link IS NOT NULL THEN
      write_log('skip "test_case_builder" due in this method');
    ELSE
      sql_rec := sqlt$a.get_statement(p_statement_id);

      IF sql_rec.in_memory = 'N' THEN
        write_log('skip "test_case_builder" since SQL is no longer in memory');
      ELSIF sql_rec.sql_id_found_using_sqltext = 'N' THEN
        write_log('skip "test_case_builder" since sql_text was not found in memory'); -- XPLAIN
      ELSE -- it was executed by XTRACT or XECUTE, or if it was by XPLAIN and the sqltext was found in memory or AWR
        BEGIN
          IF p_out_file_identifier IS NULL THEN
            l_out_file_identifier := NULL;
          ELSE
            l_out_file_identifier := '_'||p_out_file_identifier;
          END IF;

          write_log('directory: "'||p_tcb_directory_name||'"');
          write_log('sql_id: "'||sql_rec.sql_id||'"');
          write_log('exportData: "'||sqlt$a.get_param('tcb_export_data')||'"');
          write_log('exportpkgbody: "'||sqlt$a.get_param('tcb_export_pkg_body')||'"');
          write_log('timeLimit: "'||sqlt$a.get_param_n('tcb_time_limit_secs')||'"');
          write_log('testcase_name: "'||'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_tcb_'||'"');

		  -- 22170175 Eliminated l_exportpkgbody and changed parameters 
		  -- 170909 Added preserveSchemaMapping    
          EXECUTE IMMEDIATE
         'BEGIN SYS.DBMS_SQLDIAG.EXPORT_SQL_TESTCASE ( '||
            'directory     => :directory, '||
            'sql_id        => :sql_id, '||
            (case sqlt$a.get_param('tcb_export_data') when 'TRUE' then 'exportData=>TRUE,' end)||
            (case when sqlt$a.get_param('tcb_export_pkg_body')='TRUE' and sqlt$a.get_rdbms_version <>'11.1' then 'exportPkgbody => TRUE, ' end)||
			(case when sqlt$a.get_rdbms_version<>'11.1' THEN 'preserveSchemaMapping    =>TRUE, ' end)||
            'samplingPercent => :samplinPct, '||
            'timeLimit     => :timeLimit, '||
            'testcase_name => :testcase_name, '||
            'testcase      => :testcase ); END;'          USING
          IN p_tcb_directory_name,
          IN sql_rec.sql_id,
		  IN sqlt$a.get_param('tcb_sampling_percent'),
          IN sqlt$a.get_param_n('tcb_time_limit_secs'),
          IN 'sqlt_s'||sqlt$a.get_statement_id_c(p_statement_id)||l_out_file_identifier||'_tcb_',
          IN OUT l_testcase;
        EXCEPTION
          WHEN OTHERS THEN
            l_testcase := 'ERROR';
            write_log('** '||SQLERRM);
            write_log('DBMS_SQLDIAG.EXPORT_SQL_TESTCASE failed with error above. Process continues.');
        END;
      END IF;
    END IF;

    sqlt$r.tcb_driver (
      p_statement_id        => p_statement_id,
      p_generate_script     => l_testcase IS NOT NULL,
      p_out_file_identifier => p_out_file_identifier );

    write_log('<= test_case_builder');
  END test_case_builder;

  /*************************************************************************************/

  /* -------------------------
   *
   * public collect_fnd_histogram_cols
   *
   * called by sqlt$i.ebs_application_specific
   *
   * ------------------------- */
  PROCEDURE collect_fnd_histogram_cols (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_insert_list VARCHAR2(32767);
    l_select_list VARCHAR2(32767);
    l_sql         VARCHAR2(32767);
    l_count       NUMBER;

  BEGIN
    write_log('collect_fnd_histogram_cols');

    sqlt$d.get_list_of_columns (
      p_source_owner      => 'applsys',
      p_source_table      => 'fnd_histogram_cols',
      p_source_alias      => 't',
      p_destination_table => 'sqlt$_fnd_histogram_cols',
      x_insert_list       => l_insert_list,
      x_select_list       => l_select_list );

    l_sql :=
    'INSERT INTO &&tool_repository_schema..sqlt$_fnd_histogram_cols (statement_id, statid'||
    l_insert_list||') SELECT DISTINCT :statement_id, :statid'||
    l_select_list||' FROM &&tool_administer_schema..sqlt$_dba_all_tables_v x, applsys.fnd_histogram_cols t '||
    'WHERE x.statement_id = :statement_id AND x.table_name = t.table_name';
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

    SELECT COUNT(*) INTO l_count FROM &&tool_repository_schema..sqlt$_fnd_histogram_cols WHERE statement_id = p_statement_id;
    write_log(l_count||' rows collected');
    COMMIT;
  END collect_fnd_histogram_cols;

  /*************************************************************************************/

  /* -------------------------
   *
   * private ebs_application_specific
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE ebs_application_specific (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL )
  IS
    sql_rec &&tool_repository_schema..sqlt$_sql_statement%ROWTYPE := NULL;
  BEGIN
    write_log('=> ebs_application_specific');

    BEGIN
      EXECUTE IMMEDIATE
      'SELECT release_name, applications_system_name FROM applsys.fnd_product_groups WHERE ROWNUM = 1' INTO sql_rec.apps_release, sql_rec.apps_system_name;
      write_log('this is an EBS application "'||sql_rec.apps_release||'"');

      UPDATE &&tool_repository_schema..sqlt$_sql_statement
         SET apps_release = sql_rec.apps_release,
             apps_system_name = sql_rec.apps_system_name
       WHERE statement_id = p_statement_id;
      COMMIT;
    EXCEPTION
      WHEN OTHERS THEN
        write_log('this is not an EBS application');
        sql_rec.apps_release := NULL;
    END;

    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sql_rec.apps_release IS NOT NULL THEN
      collect_fnd_histogram_cols (
        p_statement_id => p_statement_id,
        p_statid       => sql_rec.statid );
    END IF;

    IF sqlt$a.get_param('bde_chk_cbo') = 'N' THEN
      write_log('skip "bde_chk_cbo" as per corresponding parameter');
    ELSIF sql_rec.apps_release IS NULL THEN
      write_log('skip "bde_chk_cbo" since this is not an EBS application');
    ELSE
      sqlt$r.bde_chk_cbo_report(p_statement_id => p_statement_id, p_out_file_identifier => p_out_file_identifier);
    END IF;

    write_log('<= ebs_application_specific');
  END ebs_application_specific;

  /*************************************************************************************/

  /* -------------------------
   *
   * private siebel_application_specific
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   * 
   * ------------------------- */
  PROCEDURE siebel_application_specific (p_statement_id IN NUMBER)
  IS
    sql_rec &&tool_repository_schema..sqlt$_sql_statement%ROWTYPE := NULL;
	l_object varchar2(32767); -- 22170175
  BEGIN
    write_log('=> siebel_application_specific');

    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sql_rec.siebel = 'YES' THEN
      BEGIN
	    l_object:=aob(sql_rec.siebel_schema||'.s_app_ver'); -- 22170175 
        EXECUTE IMMEDIATE
        'SELECT app_ver FROM '||l_object||' WHERE ROWNUM = 1' INTO sql_rec.siebel_app_ver;
        write_log('this is a SIEBEL application "'||sql_rec.siebel_schema||'"');

        UPDATE &&tool_repository_schema..sqlt$_sql_statement
           SET siebel_app_ver = sql_rec.siebel_app_ver
         WHERE statement_id = p_statement_id;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('this is not a SIEBEL application');
      END;
    END IF;

    write_log('<= siebel_application_specific');
  END siebel_application_specific;

  /*************************************************************************************/

  /* -------------------------
   *
   * private psft_application_specific
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   * 
   * ------------------------- */
  PROCEDURE psft_application_specific (p_statement_id IN NUMBER)
  IS
    sql_rec &&tool_repository_schema..sqlt$_sql_statement%ROWTYPE := NULL;
	l_object varchar2(32767); -- 22170175
  BEGIN
    write_log('=> psft_application_specific');

    sql_rec := sqlt$a.get_statement(p_statement_id);

    IF sql_rec.psft = 'YES' THEN
      BEGIN
	    l_object:=aob(sql_rec.psft_schema||'.psstatus'); -- 22170175
        EXECUTE IMMEDIATE
        'SELECT toolsrel FROM '||l_object||' WHERE ROWNUM = 1' INTO sql_rec.psft_tools_rel;
        write_log('this is a psft application "'||sql_rec.psft_tools_rel||'"');

        UPDATE &&tool_repository_schema..sqlt$_sql_statement
           SET psft_tools_rel = sql_rec.psft_tools_rel
         WHERE statement_id = p_statement_id;
        COMMIT;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('this is not a psft application');
      END;
    END IF;

    write_log('<= psft_application_specific');
  END psft_application_specific;

  /*************************************************************************************/

  /* -------------------------
   *
   * private store_metadata
   *
   * called by: sqlt$i.collect_metadata_objects and sqlt$i.collect_metadata_constraints
   *
   * ------------------------- */
  PROCEDURE store_metadata (
    p_statement_id    IN NUMBER,
    p_statid          IN VARCHAR2,
    p_transformed     IN VARCHAR2,
    p_owner           IN VARCHAR2,
    p_object_name     IN VARCHAR2,
    p_object_type     IN VARCHAR2,
    p_object_type_met IN VARCHAR2,
    p_object_id       IN VARCHAR2 DEFAULT NULL )
  IS
    met_rec &&tool_repository_schema..sqlt$_metadata%ROWTYPE;
    l_index_type &&tool_repository_schema..sqlt$_dba_indexes.index_type%TYPE := NULL;
    l_ityp_name &&tool_repository_schema..sqlt$_dba_indexes.ityp_name%TYPE := NULL;
    l_error VARCHAR2(4000);
    l_clob CLOB;
  BEGIN
    IF sqlt$a.get_param('skip_metadata_for_object') IS NOT NULL AND
       p_object_name LIKE sqlt$a.get_param('skip_metadata_for_object')
    THEN
      write_log('skip_metadata_for_object="'||sqlt$a.get_param('skip_metadata_for_object')||'" owner="'||p_owner||'", name="'||p_object_name||'", type="'||p_object_type||'", transformed="'||p_transformed||'"');
      RETURN;
    END IF;

    write_log('store_metadata owner="'||p_owner||'", name="'||p_object_name||'", type="'||p_object_type||'", transformed="'||p_transformed||'"', 'S');

    met_rec := NULL;
    met_rec.statement_id := p_statement_id;
    met_rec.statid := p_statid;
    met_rec.owner := p_owner;
    met_rec.object_name := p_object_name;
    met_rec.object_type := p_object_type;
    met_rec.object_id := p_object_id;
    met_rec.transformed := p_transformed;
    met_rec.remapped := 'N';

    IF p_object_type = 'INDEX' THEN
      BEGIN
        SELECT index_type, ityp_name
          INTO l_index_type, l_ityp_name
          FROM &&tool_repository_schema..sqlt$_dba_indexes
         WHERE statement_id = p_statement_id
           AND owner = p_owner
           AND index_name = p_object_name
           AND ROWNUM = 1;
      EXCEPTION
        WHEN OTHERS THEN
          l_error := SQLERRM||' selecting from &&tool_repository_schema..sqlt$_dba_indexes.';
          write_error(l_error);
          write_error('Cannot get index type: name="'||p_object_name||'", owner="'||p_owner||'". Process continues.');
          UPDATE &&tool_repository_schema..sqlt$_dba_objects SET metadata_error = l_error WHERE statement_id = p_statement_id AND object_id = p_object_id;
      END;
    END IF;

    IF l_index_type = 'DOMAIN' THEN
      IF l_ityp_name = 'CONTEXT' THEN -- only CONTEXT (ignore SPATIAL_INDEX and CTXCAT)
        IF sqlt$a.get_param('domain_index_metadata') = 'E' THEN -- last execution got (E)rror ORA-07445: exception encountered: core dump
          sqlt$a.set_param('domain_index_metadata', 'N');
          write_error('Prior execution of '||TOOL_NAME||' errored out calling CTXSYS.CTX_REPORT.CREATE_INDEX_SCRIPT. Process continues.');
          UPDATE &&tool_repository_schema..sqlt$_dba_objects SET metadata_error = 'prior execution of '||TOOL_NAME||' errored out calling CTXSYS.CTX_REPORT.CREATE_INDEX_SCRIPT.' WHERE statement_id = p_statement_id AND object_id = p_object_id;
        END IF;

        IF sqlt$a.get_param('domain_index_metadata') = 'Y' THEN
          sqlt$a.set_param('domain_index_metadata', 'E');
          write_log('domain_index_metadata (lock). '||p_object_name);

          BEGIN
            -- dynamic sql since package may not be installed
            EXECUTE IMMEDIATE
            'BEGIN CTXSYS.CTX_REPORT.CREATE_INDEX_SCRIPT(index_name => :name, report => :report); END;'
            --USING IN '"'||p_owner||'"."'||p_object_name||'"', IN OUT met_rec.metadata;
            USING IN '"'||p_owner||'"."'||p_object_name||'"', IN OUT l_clob;
            met_rec.metadata := l_clob; -- to avoid ORA-03113: end-of-file on communication channel. ORA-07445: exception encountered: core dump [kprcdt()+2119] [SIGSEGV] [ADDR:0x4] [PC:0xFC50461] [Address not mapped to object] []
          EXCEPTION
            WHEN OTHERS THEN
              l_error := SQLERRM||' calling CTXSYS.CTX_REPORT.CREATE_INDEX_SCRIPT.';
              met_rec.metadata := NULL;
              write_error(l_error);
              write_error('Cannot get metadata for object: type="'||p_object_type_met||'", name="'||p_object_name||'", owner="'||p_owner||'". Process continues.');
              UPDATE &&tool_repository_schema..sqlt$_dba_objects SET metadata_error = l_error WHERE statement_id = p_statement_id AND object_id = p_object_id;
          END;

          sqlt$a.set_param('domain_index_metadata', 'Y');
          write_log('domain_index_metadata (unlock). '||p_object_name);
        ELSE
          met_rec.metadata := NULL;
          write_log('skip CTXSYS.CTX_REPORT.CREATE_INDEX_SCRIPT call for '||p_owner||'.'||p_object_name||' as per tool parameter');
          UPDATE &&tool_repository_schema..sqlt$_dba_objects SET metadata_error = 'skip CTXSYS.CTX_REPORT.CREATE_INDEX_SCRIPT call for '||p_owner||'.'||p_object_name||' as per tool parameter' WHERE statement_id = p_statement_id AND object_id = p_object_id;
        END IF;
      ELSE
        met_rec.metadata := NULL;
      END IF;
    ELSE -- other indexes and all other objects
      BEGIN
        -- to handle INTERVAL partitions, the change is done here since other objects are not handled properly by dbms_metadata
        IF p_object_type_met IN ('TABLE','INDEX') THEN
           SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(SYS.DBMS_METADATA.SESSION_TRANSFORM, 'EXPORT', TRUE);
        END IF;
        met_rec.metadata := SYS.DBMS_METADATA.GET_DDL(p_object_type_met, p_object_name, p_owner);
        -- to handle INTERVAL partitions, the change is done here since other objects are not handled properly by dbms_metadata
        IF p_object_type_met IN ('TABLE','INDEX') THEN
           SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(SYS.DBMS_METADATA.SESSION_TRANSFORM, 'EXPORT', FALSE);
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          l_error := SQLERRM||' calling SYS.DBMS_METADATA.GET_DDL.';
          met_rec.metadata := NULL;
          write_error(l_error);
          write_error('Cannot get metadata for object: type="'||p_object_type_met||'", name="'||p_object_name||'", owner="'||p_owner||'". Process continues.');
          UPDATE &&tool_repository_schema..sqlt$_dba_objects SET metadata_error = l_error WHERE statement_id = p_statement_id AND object_id = p_object_id;
      END;
    END IF;

    IF met_rec.metadata IS NOT NULL THEN
      BEGIN
        IF SYS.DBMS_LOB.GETLENGTH(met_rec.metadata) > 30 THEN
          INSERT INTO &&tool_repository_schema..sqlt$_metadata VALUES met_rec;
          COMMIT;
        END IF;
        SYS.DBMS_LOB.FREETEMPORARY(met_rec.metadata);
        IF l_clob IS NOT NULL THEN
          SYS.DBMS_LOB.FREETEMPORARY(l_clob);
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          l_error := SQLERRM||' inserting into &&tool_repository_schema..sqlt$_metadata.';
          write_error(l_error);
          write_error('Cannot store metadata for owner="'||p_owner||'", name="'||p_object_name||'", type="'||p_object_type||'", transformed="'||p_transformed||'". Process continues.');
          UPDATE &&tool_repository_schema..sqlt$_dba_objects SET metadata_error = l_error WHERE statement_id = p_statement_id AND object_id = p_object_id;
      END;
    END IF;
  END store_metadata;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_metadata_objects
   *
   * called by: sqlt$i.collect_metadata
   *
   * ------------------------- */
  PROCEDURE collect_metadata_objects (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_transformed  IN VARCHAR2 )
  IS
  BEGIN
    write_log('-> collect_metadata_objects transformed = "'||p_transformed||'"');

    FOR i IN (SELECT DISTINCT
                     object_id,
                     owner,
                     object_name,
                     object_type,
                     DECODE(object_type,
                     'JAVA SOURCE',       'JAVA_SOURCE',
                     'MATERIALIZED VIEW', 'MATERIALIZED_VIEW',
                     'PACKAGE BODY',      'PACKAGE_BODY',
                     'PACKAGE',           'PACKAGE_SPEC',
                     'QUEUE',             'AQ_QUEUE',
                     'TYPE BODY',         'TYPE_BODY',
                     'TYPE',              'TYPE_SPEC',
                     'XML SCHEMA',        'XMLSCHEMA',
                     object_type) object_type_met
                FROM &&tool_repository_schema..sqlt$_dba_objects
               WHERE statement_id = p_statement_id
                 AND metadata_error IS NULL
                 AND (object_type IN (
                      'CLUSTER',
                      'INDEX',
                      'INDEXTYPE',
                      'LIBRARY',
                      'OPERATOR',
                      'PACKAGE',
                      'SEQUENCE',
                      'SYNONYM',
                      'TABLE',
                      'TRIGGER',
                      'TYPE',
                      'VIEW') OR -- OR because SQLT handles internal SQL also
                      owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC'))
                 AND object_name NOT LIKE 'I_SNAP$%' -- bug 3793322
                 AND object_type IN (
                     'CLUSTER',
                     'DIMENSION',
                     'DIRECTORY',
                     'FUNCTION',
                     'INDEX',
                     'INDEXTYPE',
                     'JAVA SOURCE',
                     'JOB',
                     'LIBRARY',
                     'MATERIALIZED VIEW',
                     'OPERATOR',
                     'PACKAGE BODY',
                     'PACKAGE',
                     'PROCEDURE',
                     'QUEUE',
                     'SEQUENCE',
                     'SYNONYM',
                     'TABLE',
                     'TRIGGER',
                     'TYPE BODY',
                     'TYPE',
                     'VIEW',
                     'XML SCHEMA' ))
    LOOP
      store_metadata (
        p_statement_id    => p_statement_id,
        p_statid          => p_statid,
        p_transformed     => p_transformed,
        p_owner           => i.owner,
        p_object_name     => i.object_name,
        p_object_type     => i.object_type,
        p_object_type_met => i.object_type_met,
        p_object_id       => i.object_id );
    END LOOP;

    write_log('<- collect_metadata_objects transformed = "'||p_transformed||'"');
  END collect_metadata_objects;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_metadata_constraints
   *
   * called by: sqlt$i.collect_metadata
   *
   * ------------------------- */
  PROCEDURE collect_metadata_constraints (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2,
    p_transformed  IN VARCHAR2 )
  IS
  BEGIN
    write_log('-> collect_metadata_constraints transformed = "'||p_transformed||'"');

    FOR i IN (SELECT DISTINCT
                     owner,
                     constraint_name object_name,
                     constraint_type||'_CONSTRAINT' object_type,
                     DECODE(constraint_type, 'R', 'REF_CONSTRAINT', 'CONSTRAINT') object_type_met
                FROM &&tool_repository_schema..sqlt$_dba_constraints
               WHERE statement_id = p_statement_id
                 AND owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC'))
    LOOP
      store_metadata (
        p_statement_id    => p_statement_id,
        p_statid          => p_statid,
        p_transformed     => p_transformed,
        p_owner           => i.owner,
        p_object_name     => i.object_name,
        p_object_type     => i.object_type,
        p_object_type_met => i.object_type_met );
    END LOOP;

    write_log('<- collect_metadata_constraints transformed = "'||p_transformed||'"');
  END collect_metadata_constraints;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_metadata
   *
   * called by: sqlt$i.common_calls and sqlti.remote_xtract
   *
   * ------------------------- */
  PROCEDURE collect_metadata (p_statement_id IN NUMBER)
  IS
  BEGIN
    write_log('=> collect_metadata');

    -- objects with no transformations
    BEGIN
      SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(SYS.DBMS_METADATA.SESSION_TRANSFORM, 'DEFAULT', TRUE);
      collect_metadata_objects(p_statement_id, sqlt$a.get_statid(p_statement_id), 'N');
    END;

    -- objects with transformations
    BEGIN
      SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(SYS.DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
      SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(SYS.DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
      SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(SYS.DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
      SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(SYS.DBMS_METADATA.SESSION_TRANSFORM, 'CONSTRAINTS', FALSE);
      SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(SYS.DBMS_METADATA.SESSION_TRANSFORM, 'REF_CONSTRAINTS', FALSE);
      --SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(SYS.DBMS_METADATA.SESSION_TRANSFORM, 'EXPORT', TRUE);  --12.1.05 to handle INTERVAL partitioning  SYS.DBMS_METADATA.SET_TRANSFORM_PARAM(SYS.DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE); -- 141017 to remove HCC compression 
      collect_metadata_objects(p_statement_id, sqlt$a.get_statid(p_statement_id), 'Y');
    END;

    -- constraints with transformations
    collect_metadata_constraints(p_statement_id, sqlt$a.get_statid(p_statement_id), 'Y');

    write_log('<= collect_metadata');
  END collect_metadata;

  /*************************************************************************************/

  /* -------------------------
   *
   * private perform_count_star
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   * 
   * ------------------------- */
  PROCEDURE perform_count_star (p_statement_id IN NUMBER)
  IS
    l_sql VARCHAR2(32767);
    l_number NUMBER;
    l_count NUMBER;
	l_object VARCHAR2(32767); -- 22170175
	
  BEGIN
    write_log('=> perform_count_star');

    IF sqlt$a.get_param_n('count_star_threshold') = 0 THEN
      write_log('skip "count_star" as per corresponding parameter');
    ELSE
      FOR i IN (SELECT owner, table_name, num_rows, source
                  FROM &&tool_administer_schema..sqlt$_dba_all_tables_v
                 WHERE statement_id = p_statement_id
                 ORDER BY
                       owner, table_name)
      LOOP
	    l_object:=aob('"'||i.owner||'"."'||i.table_name||'"'); -- 22170175 
        IF i.num_rows IS NULL THEN
          l_sql := 'SELECT /*+ FULL(t) PARALLEL */ COUNT(*) FROM '||l_object||' t WHERE ROWNUM <= :number';
          l_number := sqlt$a.get_param_n('count_star_threshold');
        ELSIF i.num_rows < sqlt$a.get_param_n('count_star_threshold') THEN
          l_sql := 'SELECT /*+ FULL(t) PARALLEL */ COUNT(*) FROM '||l_object||' t WHERE ROWNUM <= :number';
          l_number := sqlt$a.get_param_n('count_star_threshold') * 10;
        ELSIF i.num_rows < (sqlt$a.get_param_n('count_star_threshold') * 1e1) THEN
          l_sql := 'SELECT /*+ FULL(t) PARALLEL */ COUNT(*) * 1e1 FROM '||l_object||' SAMPLE (:number) t';
          l_number := 1e1;
        ELSIF i.num_rows < (sqlt$a.get_param_n('count_star_threshold') * 1e2) THEN
          l_sql := 'SELECT /*+ FULL(t) PARALLEL */ COUNT(*) * 1e2 FROM '||l_object||' SAMPLE (:number) t';
          l_number := 1e0;
        ELSIF i.num_rows < (sqlt$a.get_param_n('count_star_threshold') * 1e3) THEN
          l_sql := 'SELECT /*+ FULL(t) PARALLEL */ COUNT(*) * 1e3 FROM '||l_object||' SAMPLE (:number) t';
          l_number := 1/1e1;
        ELSIF i.num_rows < (sqlt$a.get_param_n('count_star_threshold') * 1e4) THEN
          l_sql := 'SELECT /*+ FULL(t) PARALLEL */ COUNT(*) * 1e4 FROM '||l_object||' SAMPLE (:number) t';
          l_number := 1/1e2;
        ELSIF i.num_rows < (sqlt$a.get_param_n('count_star_threshold') * 1e5) THEN
          l_sql := 'SELECT /*+ FULL(t) PARALLEL */ COUNT(*) * 1e5 FROM '||l_object||' SAMPLE (:number) t';
          l_number := 1/1e3;
        ELSIF i.num_rows < (sqlt$a.get_param_n('count_star_threshold') * 1e6) THEN
          l_sql := 'SELECT /*+ FULL(t) PARALLEL */ COUNT(*) * 1e6 FROM '||l_object||' SAMPLE (:number) t';
          l_number := 1/1e4;
        ELSIF i.num_rows < (sqlt$a.get_param_n('count_star_threshold') * 1e7) THEN
          l_sql := 'SELECT /*+ FULL(t) PARALLEL */ COUNT(*) * 1e7 FROM '||l_object||' SAMPLE (:number) t';
          l_number := 1/1e5;
        ELSE
          l_sql := 'SELECT /*+ FULL(t) PARALLEL */ COUNT(*) * 1e8 FROM '||l_object||' SAMPLE (:number) t';
          l_number := 1/1e6;
        END IF;

        l_sql := REPLACE(l_sql, ':number', l_number);
        write_log('num_rows='||i.num_rows||' sql='||l_sql);
        l_count := NULL;

        BEGIN
          EXECUTE IMMEDIATE l_sql INTO l_count;
          write_log(l_count||' rows counted');
        EXCEPTION
          WHEN OTHERS THEN
            write_log('** '||SQLERRM);
            write_log(l_sql||' failed with error above. Process continues.');
        END;

        IF l_count IS NOT NULL THEN
          IF i.source = 'DBA_TABLES' THEN
            UPDATE &&tool_repository_schema..sqlt$_dba_tables
               SET count_star = l_count
             WHERE statement_id = p_statement_id
               AND owner = i.owner
               AND table_name = i.table_name;
          ELSIF i.source = 'DBA_OBJECT_TABLES' THEN
            UPDATE &&tool_repository_schema..sqlt$_dba_object_tables
               SET count_star = l_count
             WHERE statement_id = p_statement_id
               AND owner = i.owner
               AND table_name = i.table_name;
          END IF;
        END IF;
      END LOOP;

      COMMIT;
    END IF;

    write_log('<= perform_count_star');
  END perform_count_star;

  /*************************************************************************************/

  /* -------------------------
   *
   * private collect_dbms_space
   *
   * ------------------------- */
  PROCEDURE collect_dbms_space(p_statement_id IN NUMBER)
  IS
    l_used_bytes  NUMBER;
    l_alloc_bytes NUMBER;

  BEGIN
    write_log('collect_dbms_space');

    write_log('collect_dbms_space.tables');
    FOR i IN (SELECT tbl.ROWID row_id,
                     tbl.tablespace_name,
                     tbl.avg_row_len,
                     tbl.count_star,
                     tbl.pct_free,
                     spc.block_size
                FROM &&tool_repository_schema..sqlt$_dba_tables tbl,
                     &&tool_repository_schema..sqlt$_dba_tablespaces spc
               WHERE tbl.statement_id = p_statement_id
                 AND tbl.avg_row_len > 0
                 AND tbl.count_star > 0
                 AND spc.statement_id = p_statement_id
                 AND spc.tablespace_name = tbl.tablespace_name)
    LOOP
      write_log('DBMS_SPACE.CREATE_TABLE_COST tablespace_name:'||i.tablespace_name||' avg_row_size:'||i.avg_row_len||' row_count:'||i.count_star||' pct_free:'||i.pct_free);
      BEGIN
        SYS.DBMS_SPACE.CREATE_TABLE_COST (
          tablespace_name => i.tablespace_name,
          avg_row_size    => i.avg_row_len,
          row_count       => i.count_star,
          pct_free        => i.pct_free,
          used_bytes      => l_used_bytes ,
          alloc_bytes     => l_alloc_bytes );
      EXCEPTION
        WHEN OTHERS THEN
          write_log('** '||SQLERRM);
          write_log('tablespace_name:'||i.tablespace_name||' avg_row_size:'||i.avg_row_len||' row_count:'||i.count_star||' pct_free:'||i.pct_free);
          write_log('DBMS_SPACE.CREATE_TABLE_COST failed with error above. Process continues.');
          l_used_bytes := NULL;
          l_alloc_bytes := NULL;
      END;

      IF l_used_bytes IS NOT NULL AND l_alloc_bytes IS NOT NULL THEN
        UPDATE &&tool_repository_schema..sqlt$_dba_tables
           SET dbms_space_used_bytes   = l_used_bytes,
               dbms_space_alloc_bytes  = l_alloc_bytes,
               dbms_space_used_blocks  = ROUND(l_used_bytes / i.block_size),
               dbms_space_alloc_blocks = ROUND(l_alloc_bytes / i.block_size)
         WHERE ROWID = i.row_id;
      END IF;
    END LOOP;

    write_log('collect_dbms_space.indexes');
    FOR i IN (SELECT idx.ROWID row_id,
                     idx.index_name,
                     met.metadata,
                     spc.block_size
                FROM &&tool_repository_schema..sqlt$_dba_indexes idx,
                     &&tool_repository_schema..sqlt$_dba_tablespaces spc,
                     &&tool_repository_schema..sqlt$_metadata met
               WHERE idx.statement_id = p_statement_id
                 AND spc.statement_id = p_statement_id
                 AND spc.tablespace_name = idx.tablespace_name
                 AND met.statement_id = p_statement_id
                 AND met.owner = idx.owner
                 AND met.object_name = idx.index_name
                 AND met.object_type = 'INDEX'
                 AND met.transformed = 'N'
                 AND met.remapped = 'N')
    LOOP
      write_log('SYS.DBMS_SPACE.CREATE_INDEX_COST index_name:'||i.index_name);
      BEGIN
        SYS.DBMS_SPACE.CREATE_INDEX_COST (
          ddl         => i.metadata,
          used_bytes  => l_used_bytes ,
          alloc_bytes => l_alloc_bytes );
      EXCEPTION
        WHEN OTHERS THEN
          write_log('** '||SQLERRM);
          write_log('index_name:'||i.index_name);
          write_log('DBMS_SPACE.CREATE_INDEX_COST failed with error above. Process continues.');
          l_used_bytes := NULL;
          l_alloc_bytes := NULL;
      END;

      IF l_used_bytes IS NOT NULL AND l_alloc_bytes IS NOT NULL THEN
        UPDATE &&tool_repository_schema..sqlt$_dba_indexes
           SET dbms_space_used_bytes   = l_used_bytes,
               dbms_space_alloc_bytes  = l_alloc_bytes,
               dbms_space_used_blocks  = ROUND(l_used_bytes / i.block_size),
               dbms_space_alloc_blocks = ROUND(l_alloc_bytes / i.block_size)
         WHERE ROWID = i.row_id;
      END IF;
    END LOOP;

    COMMIT;
  END collect_dbms_space;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_estim_size_if_rebuilt
   *
   * based on
   * http://richardfoote.wordpress.com/2014/04/24/estimate-index-size-with-explain-plan-i-cant-explain/#comment-116966
   * http://carlos-sierra.net/2014/07/18/free-script-to-very-quickly-and-cheaply-estimate-the-size-of-an-index-if-it-were-to-be-rebuilt/
   *
   * ------------------------- */
  PROCEDURE compute_estim_size_if_rebuilt(p_statement_id IN NUMBER)
  IS
    L_MINIMUM    CONSTANT NUMBER := 128; -- ignore indexes smaller than this
    l_estim_size_if_rebuilt NUMBER;
    l_sql VARCHAR2(32767);
  BEGIN
    write_log('compute_estim_size_if_rebuilt');

    FOR i IN (SELECT idx.ROWID ind_row_id,
                     idx.owner index_owner,
                     idx.index_name,
                     idx.object_id,
                     m.metadata
                FROM &&tool_repository_schema..sqlt$_dba_indexes idx,
                     &&tool_repository_schema..sqlt$_metadata m 
               WHERE idx.statement_id = p_statement_id
                 AND idx.statement_id = m.statement_id
                 AND idx.index_name = m.object_name
                 AND idx.owner = m.owner
                 AND m.object_type = 'INDEX'
                 AND idx.index_type IN ('NORMAL', 'FUNCTION-BASED NORMAL', 'BITMAP', 'NORMAL/REV')
                 AND idx.status != 'UNUSABLE'
                 AND idx.temporary = 'N'
                 AND idx.dropped = 'NO'
                 AND idx.last_analyzed IS NOT NULL
                 AND idx.num_rows > 0
--                 AND idx.leaf_blocks > L_MINIMUM
                 AND m.transformed = 'N'
                 AND m.remapped = 'N')
    LOOP

      DELETE &&tool_repository_schema..sqlt$_sql_plan_table WHERE statement_id LIKE 'IDX_REB%';

	  -- 22170175 Cannot do SQL Injection on EXPLAIN PLAN as it does not executes i.metadata
      l_sql := 'EXPLAIN PLAN SET STATEMENT_ID = ''IDX_REB_'||p_statement_id||'_'||i.object_id||''' INTO &&tool_repository_schema..sqlt$_sql_plan_table FOR '
	  ||DBMS_ASSERT.NOOP(i.metadata);
      EXECUTE IMMEDIATE l_sql;

      SELECT TO_NUMBER(EXTRACTVALUE(VALUE(d), '/info'))
        INTO l_estim_size_if_rebuilt
        FROM &&tool_repository_schema..sqlt$_sql_plan_table pt,
             TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(pt.other_xml), '/*/info'))) d
       WHERE pt.statement_id = 'IDX_REB_'||p_statement_id||'_'||i.object_id
         AND pt.other_xml IS NOT NULL 
         AND EXTRACTVALUE(VALUE(d), '/info/@type') = 'index_size';

      UPDATE &&tool_repository_schema..sqlt$_dba_indexes
         SET estim_size_if_rebuilt = ROUND(l_estim_size_if_rebuilt)
       WHERE ROWID = i.ind_row_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('compute_estim_size_if_rebuilt: '||SQLERRM);
  END compute_estim_size_if_rebuilt;

  /*************************************************************************************/

  /* -------------------------
   *
   * private common_calls
   *
   * called by: sqlt$i.xtract, sqlt$i.xecute_end and sqlt$i.xplain_end
   *
   * ------------------------- */
  PROCEDURE common_calls (
    p_statement_id        IN NUMBER,
    p_input_filename      IN VARCHAR2 DEFAULT NULL,  -- xecute_end, xplain_end
    p_password            IN VARCHAR2 DEFAULT 'N',
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL,  -- xtract
    p_tcb_directory_name  IN VARCHAR2 DEFAULT 'SQLT$STAGE' ) -- xtract
  IS
    l_file_name VARCHAR2(32767);
  BEGIN
    -- urgent calls
    remote_trace_end(p_statement_id);
    sqlt$d.collect_gv$parameter_cbo(p_statement_id);
    sqlt$d.diagnostics_data_collection_1(p_statement_id, p_out_file_identifier);

    -- calls that can be delayed
    --sql_tuning_advisor(p_statement_id, p_out_file_identifier); moved down
    --test_case_builder(p_statement_id, p_out_file_identifier, p_tcb_directory_name); moved down
    sqlt$d.collect_px_perf_stats(p_statement_id);
    sqlt$d.diagnostics_data_collection_2(p_statement_id);
    sql_tuning_advisor(p_statement_id, p_out_file_identifier);
    test_case_builder(p_statement_id, p_out_file_identifier, p_tcb_directory_name);
    ebs_application_specific(p_statement_id, p_out_file_identifier);
    siebel_application_specific(p_statement_id);
    psft_application_specific(p_statement_id);
    collect_metadata(p_statement_id);
    compute_full_table_scan_cost(p_statement_id);
    perform_count_star(p_statement_id);
    collect_dbms_space(p_statement_id);
    sqlt$t.perm_transformation(p_statement_id);  -- depends on sqlt$t.perm_transformation
    compute_estim_size_if_rebuilt(p_statement_id);  --
    sqlt$r.sql_monitor_reports(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    --sqlt$r.sql_monitor_driver(p_statement_id);
    sqlt$r.sql_detail_report(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.awrrpt_driver(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.addmrpt_driver(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.ashrpt_driver(p_statement_id, p_out_file_identifier => p_out_file_identifier);
	sqlt$r.perfhub_driver(p_statement_id, p_out_file_identifier => p_out_file_identifier);  -- 160403
    sqlt$r.xpand_sql_driver(p_statement_id, p_out_file_identifier => p_out_file_identifier);  -- 12.1.03		
    sqlt$r.script_output_driver(p_statement_id, p_input_filename => p_input_filename, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.tkprof_px_driver(p_statement_id, p_out_file_identifier => p_out_file_identifier, x_file_name => l_file_name);
    call_trace_analyzer_px(p_statement_id, l_file_name, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.export_parfile(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.export_parfile2(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.export_driver(p_statement_id, p_password => p_password, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.import_script(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.metadata_script(p_statement_id => p_statement_id, p_script_type => NULL, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.metadata_script(p_statement_id => p_statement_id, p_script_type => '1', p_out_file_identifier => p_out_file_identifier);
    sqlt$r.metadata_script(p_statement_id => p_statement_id, p_script_type => '2', p_out_file_identifier => p_out_file_identifier);
    sqlt$r.system_stats_script(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.schema_stats_script(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.set_cbo_env_script(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.custom_sql_profile(p_statement_id, p_out_file_identifier => p_out_file_identifier, p_calling_library => 'sqlt$i.common_calls' );
    --sqlt$r.test_case_script(p_statement_id, p_out_file_identifier => p_out_file_identifier); moved to xtract
    --sqlt$r.test_case_sql(p_statement_id, p_out_file_identifier => p_out_file_identifier); moved to xtract
    sqlt$r.plan(p_statement_id);
    sqlt$r.s10053(p_statement_id);
    sqlt$r.flush(p_statement_id);
    sqlt$r.purge(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.restore(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.del_hgrm(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.tc_sql(p_statement_id);
    sqlt$r.xpress_sh(p_statement_id);
    sqlt$r.xpress_sql(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.setup(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.readme(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.tc_pkg(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.sel(p_statement_id);
    sqlt$r.sel_aux(p_statement_id);
    sqlt$r.install_sh(p_statement_id);
    sqlt$r.install_sql(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.tcx_pkg(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.lite_report(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$a.upload_10053_trace(p_statement_id);
    sqlt$a.upload_10053_xtract(p_statement_id);
    remote_trace_analyzer_and_copy(p_statement_id, p_out_file_identifier);
    sqlt$r.remote_driver(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$a.set_input_filename(p_statement_id, p_input_filename);
    sqlt$m.main_report_root(p_statement_id, p_out_file_identifier => p_out_file_identifier);

    -- reset flag once it has been consumed by XECUTE phase of XTRXEC
    sqlt$a.s_xtrxec := 'N';
  END common_calls;

  /*************************************************************************************/

  /* -------------------------
   *
   * private common_begin
   *
   * called by: sqlt$i.xtract, sqlt$i.remote_xtract, sqlt$i.xecute_begin and sqlt$i.xplain_begin
   *
   * ------------------------- */
  PROCEDURE common_begin (p_statement_id IN NUMBER)
  IS
  BEGIN
    sqlt$a.s_log_statement_id := p_statement_id;
    sqlt$a.s_log_statid := sqlt$a.get_statid(p_statement_id);
    sqlt$a.validate_user(USER);
  END common_begin;

  /*************************************************************************************/

  /* -------------------------
   *
   * private common_end
   *
   * called by: sqlt$i.xtract, sqlt$i.remote_xtract, sqlt$i.xecute_end and sqlt$i.xplain_end
   *
   * ------------------------- */
  PROCEDURE common_end (p_statement_id IN NUMBER)
  IS
  BEGIN
    sqlt$a.s_log_statement_id := NULL;
    sqlt$a.s_log_statid := NULL;
  END common_end;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xtrsby
   *
   * called by: sqltxtrsby.sql
   *
   * ------------------------- */
  PROCEDURE xtrsby (
    p_statement_id         IN NUMBER,
    p_sql_id_or_hash_value IN VARCHAR2,
    p_stand_by_dblink      IN VARCHAR2,
    p_password             IN VARCHAR2 DEFAULT 'N' )
  IS
  BEGIN
    sqlt$a.set_stand_by_dblink(p_stand_by_dblink);
    sqlt$a.set_method('XTRSBY');
    common_begin(p_statement_id);
    sqlt$a.common_initialization;
    write_log('==> xtrsby');
    write_log('p_sql_id_or_hash_value:"'||p_sql_id_or_hash_value||'", p_stand_by_dblink:"'||p_stand_by_dblink||'"');
    EXECUTE IMMEDIATE 'BEGIN &&tool_administer_schema..sqlt$a.xtrsby_initialization'||sqlt$a.s_db_link||'; END;';
    sqlt$a.create_statement_workspace(p_statement_id => p_statement_id);
    sqlt$d.capture_sqltext(p_statement_id => p_statement_id, p_string => NULL, p_sql_id_or_hash_value => TRIM(p_sql_id_or_hash_value));
    --explain_plan_and_10053(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    common_calls(p_statement_id, p_password => p_password );
    sqlt$r.test_case_script(p_statement_id);
    sqlt$r.test_case_sql(p_statement_id);
    sqlt$r.readme_report_html(p_statement_id);
    sqlt$r.readme_report_txt(p_statement_id);
    --sqlt$r.sql_monitor_driver(p_statement_id);
    write_log('<== xtrsby');
    sqlt$a.set_end_date(p_statement_id);
    sqlt$r.process_log(p_statement_id);
    write_log('SQLTXTRSBY completed for "'||p_sql_id_or_hash_value||'"');
    write_log('... please wait ...');
    --common_end(p_statement_id);  -- 12.1.04
    --sqlt$a.set_method(NULL);
    sqlt$a.set_stand_by_dblink(NULL);
    sqlt$a.set_module;
  END xtrsby;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xtract
   *
   * called by: sqltxtract.sql, sqltxtrone.sql and xtract_and_trap_error
   *
   * ------------------------- */
  PROCEDURE xtract (
    p_statement_id         IN NUMBER,
    p_sql_id_or_hash_value IN VARCHAR2,
    p_out_file_identifier  IN VARCHAR2 DEFAULT NULL, -- used by xtract_and_trap_error
    p_tcb_directory_name   IN VARCHAR2 DEFAULT 'SQLT$STAGE', -- used by xtract_and_trap_error
    p_statement_set_id     IN NUMBER   DEFAULT NULL,  -- used by sqltxtrone.sql
    p_password             IN VARCHAR2 DEFAULT 'N' )
  IS
  BEGIN
    sqlt$a.set_stand_by_dblink(NULL);
    sqlt$a.set_method('XTRACT');
    common_begin(p_statement_id);
    sqlt$a.common_initialization;
    write_log('==> xtract');
    write_log('p_sql_id_or_hash_value:"'||p_sql_id_or_hash_value||'"');
    sqlt$a.create_statement_workspace(p_statement_id => p_statement_id, p_statement_set_id => p_statement_set_id);
    sqlt$d.capture_sqltext(p_statement_id => p_statement_id, p_string => NULL, p_sql_id_or_hash_value => TRIM(p_sql_id_or_hash_value));
    sqlt$d.collect_sesstat_xtract(p_statement_id => p_statement_id, p_begin_end_flag => 'B');
    explain_plan_and_10053(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    common_calls(p_statement_id, p_password => p_password, p_out_file_identifier => p_out_file_identifier, p_tcb_directory_name => p_tcb_directory_name );
    sqlt$r.test_case_script(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.test_case_sql(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.readme_report_html(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.readme_report_txt(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    sqlt$r.sql_monitor_driver(p_statement_id);
    sqlt$d.collect_sesstat_xtract(p_statement_id => p_statement_id, p_begin_end_flag => 'E');
    sqlt$d.collect_cellstate_xtract(p_statement_id => p_statement_id);   
    write_log('<== xtract');
    sqlt$a.set_end_date(p_statement_id);
    sqlt$r.process_log(p_statement_id, p_out_file_identifier => p_out_file_identifier);
    write_log('SQLTXTRACT completed for "'||p_sql_id_or_hash_value||'"');
    write_log('... please wait ...');
    --common_end(p_statement_id);
    --sqlt$a.set_method(NULL);
    sqlt$a.set_stand_by_dblink(NULL);
    sqlt$a.set_module;
  END xtract;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xtract_and_trap_error
   *
   * called by: sqlt$e.xtract_sql_put_files_in_repo
   *
   * ------------------------- */
  PROCEDURE xtract_and_trap_error (
    p_statement_id         IN NUMBER,
    p_sql_id_or_hash_value IN VARCHAR2,
    p_out_file_identifier  IN VARCHAR2 DEFAULT NULL,
    p_tcb_directory_name   IN VARCHAR2 DEFAULT 'SQLT$STAGE' )
  IS
  BEGIN
    xtract (
      p_statement_id         => p_statement_id,
      p_sql_id_or_hash_value => p_sql_id_or_hash_value,
      p_out_file_identifier  => p_out_file_identifier,
      p_tcb_directory_name   => p_tcb_directory_name );
  EXCEPTION
    WHEN OTHERS THEN
      write_error('xtract_and_trap_error');
      write_error(SQLERRM);
      sqlt$r.process_log(p_statement_id, p_out_file_identifier => p_out_file_identifier);
  END xtract_and_trap_error;

  /*************************************************************************************/

  /* -------------------------
   *
   * public remote_xtract
   *
   * called by: sqlt$i.remote_trace_analyzer_and_copy
   *
   * this api is executed in remote system. it is basically same as sqlt xtract
   * with some minor exclusions.
   *
   * ------------------------- */
  PROCEDURE remote_xtract (
    p_group_id             IN NUMBER, -- statement_id from source (caller)
    p_db_link              IN VARCHAR2,
    p_file_prefix          IN VARCHAR2,
    p_sql_id_or_hash_value IN VARCHAR2 )
  IS
    l_statement_id NUMBER;
    l_error VARCHAR2(32767) := NULL;
  BEGIN
    sqlt$a.set_stand_by_dblink(NULL);
    sqlt$a.set_method('XTRACT');
    l_statement_id := sqlt$a.get_statement_id;
    common_begin(p_group_id);
    sqlt$a.common_initialization;
    write_log('==> remote_xtract '||p_sql_id_or_hash_value);
    write_log('p_sql_id_or_hash_value:"'||p_sql_id_or_hash_value||'"');
    sqlt$a.create_statement_workspace(p_statement_id => l_statement_id, p_group_id => p_group_id);
    BEGIN
      sqlt$d.capture_sqltext(p_statement_id => l_statement_id, p_string => NULL, p_sql_id_or_hash_value => p_sql_id_or_hash_value);
    EXCEPTION
      WHEN OTHERS THEN
        l_error := SQLERRM;
        write_log(l_error);
    END;
    IF l_error IS NULL THEN
      sqlt$d.collect_gv$parameter_cbo(l_statement_id);
      sqlt$d.diagnostics_data_collection_1(l_statement_id);
      sqlt$d.diagnostics_data_collection_2(l_statement_id, p_group_id);
      ebs_application_specific(l_statement_id);
      siebel_application_specific(l_statement_id);
      psft_application_specific(l_statement_id);
      collect_metadata(l_statement_id);
      compute_full_table_scan_cost(l_statement_id);
      perform_count_star(l_statement_id);
      collect_dbms_space(l_statement_id);
      sqlt$t.perm_transformation(l_statement_id);
      sqlt$r.sql_monitor_reports(l_statement_id);
      sqlt$r.sql_detail_report(l_statement_id);
      sqlt$r.export_parfile(l_statement_id);
      sqlt$r.export_parfile2(l_statement_id);
      sqlt$r.export_driver(l_statement_id);
      sqlt$r.import_script(l_statement_id);
      sqlt$r.metadata_script(p_statement_id => l_statement_id, p_script_type => NULL, p_group_id => p_group_id, p_db_link => p_db_link, p_file_prefix => p_file_prefix);
      sqlt$r.metadata_script(p_statement_id => l_statement_id, p_script_type => '1', p_group_id => p_group_id, p_db_link => p_db_link, p_file_prefix => p_file_prefix);
      sqlt$r.metadata_script(p_statement_id => l_statement_id, p_script_type => '2', p_group_id => p_group_id, p_db_link => p_db_link, p_file_prefix => p_file_prefix);
      sqlt$r.system_stats_script(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.schema_stats_script(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.set_cbo_env_script(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.custom_sql_profile(l_statement_id, p_group_id => p_group_id, p_db_link => p_db_link, p_file_prefix => p_file_prefix, p_calling_library => 'sqlt$i.remote_xtract' );
      sqlt$r.plan(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.s10053(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.flush(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.purge(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.restore(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.del_hgrm(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.tc_sql(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.xpress_sh(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.xpress_sql(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.setup(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.readme(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.tc_pkg(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.sel(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.sel_aux(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.install_sh(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.install_sql(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.tcx_pkg(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.lite_report(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$m.main_report_root(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.test_case_script(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.test_case_sql(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.readme_report_html(l_statement_id, p_group_id, p_db_link, p_file_prefix);
      sqlt$r.readme_report_txt(l_statement_id, p_group_id, p_db_link, p_file_prefix);
    END IF;
    write_log('<== remote_xtract '||p_sql_id_or_hash_value);
    sqlt$a.set_end_date(l_statement_id);
    write_log('SQLTXTRACT completed for "'||p_sql_id_or_hash_value||'" ('||l_statement_id||', '||p_group_id||')');
    write_log('... please wait ...');
    --common_end(l_statement_id);
    --sqlt$a.set_method(NULL);
    sqlt$a.set_stand_by_dblink(NULL);
    sqlt$a.set_module;
  END remote_xtract;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xecute_begin
   *
   * called by: sqltxecute.sql
   *
   * ------------------------- */
  PROCEDURE xecute_begin (p_statement_id IN NUMBER)
  IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    sqlt$a.set_stand_by_dblink(NULL);
    sqlt$a.set_method('XECUTE');
    common_begin(p_statement_id);
    sqlt$a.common_initialization;
    write_log('==> xecute_begin');
    sqlt$a.create_statement_workspace(p_statement_id => p_statement_id);
    remote_trace_begin(p_statement_id, NULL, 'Y');
    sqlt$a.event_10046_10053_on(p_statement_id);
    COMMIT; -- AUTONOMOUS_TRANSACTION to allow XECUTE to ROLLBACK
  END xecute_begin;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xecute_end
   *
   * called by: sqltxecute.sql
   *
   * ------------------------- */
  PROCEDURE xecute_end (
    p_statement_id   IN NUMBER,
    p_string         IN VARCHAR2,
    p_sql_id         IN VARCHAR2,
    p_child_number   IN VARCHAR2,
    p_input_filename IN VARCHAR2,
    p_password       IN VARCHAR2 DEFAULT 'N' )
  IS
  BEGIN
    sqlt$a.event_10046_10053_off(p_statement_id);
    sqlt$d.capture_sqltext(p_statement_id => p_statement_id, p_string => p_string, p_sql_id_or_hash_value => p_sql_id, p_child_number => p_child_number, p_input_filename => p_input_filename);
    explain_plan_and_10053(p_statement_id, p_sql_id => p_sql_id);
    common_calls(p_statement_id, p_input_filename => p_input_filename, p_password => p_password);
    call_trace_analyzer(p_statement_id);
    sqlt$r.readme_report_html(p_statement_id);
    sqlt$r.readme_report_txt(p_statement_id);
    sqlt$a.upload_10046_10053_trace(p_statement_id);
    sqlt$r.sql_monitor_driver(p_statement_id);
    write_log('<== xecute_end');
    sqlt$a.set_end_date(p_statement_id);
    sqlt$r.process_log(p_statement_id);
    write_log('SQLTXECUTE completed for "'||p_input_filename||'"');
    write_log('... please wait ...');
   -- common_end(p_statement_id);
   -- sqlt$a.set_method(NULL);
    sqlt$a.set_stand_by_dblink(NULL);
    sqlt$a.set_module;
  END xecute_end;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xplain_begin
   *
   * called by: sqltxplain.sql
   *
   * ------------------------- */
  PROCEDURE xplain_begin (p_statement_id IN NUMBER)
  IS
  BEGIN
    sqlt$a.set_stand_by_dblink(NULL);
    sqlt$a.set_method('XPLAIN');
    common_begin(p_statement_id);
    sqlt$a.common_initialization;
    write_log('==> xplain_begin');
    sqlt$a.create_statement_workspace(p_statement_id => p_statement_id);
    remote_trace_begin(p_statement_id, NULL, 'Y');
    sqlt$a.event_10053_on(p_statement_id);
  END xplain_begin;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xplain_end
   *
   * called by: sqltxplain.sql
   *
   * ------------------------- */
  PROCEDURE xplain_end (
    p_statement_id   IN NUMBER,
    p_string         IN VARCHAR2,
    p_sql_id         IN VARCHAR2,
    p_input_filename IN VARCHAR2,
    p_password       IN VARCHAR2 DEFAULT 'N' )
  IS
  BEGIN
    sqlt$a.event_10053_off(p_statement_id);
    sqlt$a.clean_sqlt$_sql_plan_table(p_statement_id);
    sqlt$d.capture_sqltext(p_statement_id => p_statement_id, p_string => p_string, p_sql_id_or_hash_value => p_sql_id, p_child_number => NULL, p_input_filename => p_input_filename);
    sqlt$d.capture_xplain_plan_hash_value(p_statement_id, p_string);
    sqlt$d.search_sql_by_sqltext(p_statement_id);
    common_calls(p_statement_id, p_input_filename => p_input_filename, p_password => p_password);
    sqlt$r.readme_report_html(p_statement_id);
    sqlt$r.readme_report_txt(p_statement_id);
    sqlt$r.sql_monitor_driver(p_statement_id);
    write_log('<== xplain_end');
    sqlt$a.set_end_date(p_statement_id);
    sqlt$r.process_log(p_statement_id);
    write_log('&&tool_repository_schema. completed for "'||p_input_filename||'"');
    write_log('... please wait ...');
   -- common_end(p_statement_id);
   -- sqlt$a.set_method(NULL);
    sqlt$a.set_stand_by_dblink(NULL);
    sqlt$a.set_module;
  END xplain_end;

  /*************************************************************************************/

  /* -------------------------
   *
   * public reset_object_creation_date
   *
   * called by sqlt/utl/xhume/sqltrstobj.sql
   *
   * never call this script on a production environment.
   * this api must only be used on an Oracle internal test environment.
   *
   * ------------------------- */
  PROCEDURE reset_object_creation_date (
    p_statement_id IN VARCHAR2,
    p_schema_owner IN VARCHAR2 )
  IS
    l_object_type   VARCHAR2(257);
    l_statid        sqlt$_stattab.statid%TYPE;
    l_schema_owner  VARCHAR2(32767);
    l_user_id       NUMBER;
    l_object_id     NUMBER;
    l_count         NUMBER;
    l_savdate       DATE;

  BEGIN
    -- finds statid according to partial or full name
    BEGIN
      l_statid := LOWER(p_statement_id);

      SELECT COUNT(DISTINCT statid)
        INTO l_count
        FROM &&tool_repository_schema..sqlt$_sql_statement
       WHERE LOWER(statid) LIKE '%'||l_statid||'%'
         AND statid LIKE 's%';

      IF l_count < 1 THEN
        put_line('statement id "'||p_statement_id||'" was not found on sqlt$_sql_statement table');
        RETURN;
      END IF;

      IF l_count > 1 THEN
        put_line('statement id "'||p_statement_id||'" is not unique on sqlt$_sql_statement table');
        RETURN;
      END IF;
    END;

    -- reset l_statid
    SELECT statid
      INTO l_statid
      FROM &&tool_repository_schema..sqlt$_sql_statement
     WHERE LOWER(statid) LIKE '%'||l_statid||'%'
       AND statid LIKE 's%'
       AND ROWNUM = 1;

    -- possible remap
    l_schema_owner := NVL(TRIM(p_schema_owner), 'NULL');

    -- verify if passed schema owner is valid
    IF UPPER(l_schema_owner) <> 'NULL' THEN
      SELECT COUNT(*)
        INTO l_count
        FROM sys.dba_users
       WHERE username = l_schema_owner
         AND SUBSTR(username, 1, 2) = 'TC'
         AND SUBSTR(username, 3, 5) BETWEEN '00000' AND '99999';

      IF l_count = 0 THEN
        SELECT COUNT(*)
          INTO l_count
          FROM sys.dba_users
         WHERE username = UPPER(l_schema_owner)
           AND SUBSTR(username, 1, 2) = 'TC'
           AND SUBSTR(username, 3, 5) BETWEEN '00000' AND '99999';

        IF l_count > 0 THEN
          l_schema_owner := UPPER(l_schema_owner);
        END IF;
      END IF;

      IF l_count = 0 THEN
        put_line('TC schema owner "'||p_schema_owner||'" was not found');
        RETURN;
      END IF;

      SELECT user_id
        INTO l_user_id
        FROM sys.dba_users
       WHERE username = l_schema_owner;
    END IF;

    IF NVL(l_user_id, 0) = 0 OR USER <> 'SYS' THEN
      put_line('invalid user "'||USER||'"');
      RETURN;
    END IF;

    -- has to reset object creation date otherwise SYS.DBMS_STATS.RESTORE_TABLE_STATS will fail
    -- requires to connect as SYS
    -- only to be used on an Oracle internal test environment, never in a production system.
    IF l_user_id > 0 AND USER = 'SYS' THEN
      put_line('reset object creation date for tables, indexes, partitions and subpartitions');

      /*
      FOR i IN (SELECT 'TABLE' obj_type,
                       object_type,
                       object_id,
                       table_name object_name,
                       NVL(subpartition_name, partition_name) subobject_name,
                       MIN(save_time) save_time
                  FROM &&tool_repository_schema..sqlt$_dba_tab_stats_versions
                 WHERE statid = l_statid
                   AND version_type = 'HISTORY'
                 GROUP BY
                       object_type,
                       object_id,
                       table_name,
                       NVL(subpartition_name, partition_name)
                 UNION
                SELECT 'INDEX' obj_type,
                       object_type,
                       object_id,
                       index_name object_name,
                       NVL(subpartition_name, partition_name) subobject_name,
                       MIN(save_time) save_time
                  FROM &&tool_repository_schema..sqlt$_dba_ind_stats_versions
                 WHERE statid = l_statid
                   AND version_type = 'HISTORY'
                 GROUP BY
                       object_type,
                       object_id,
                       index_name,
                       NVL(subpartition_name, partition_name))
      */

      FOR i IN (SELECT obj_type, object_type, object_id, object_name, subobject_name,
                       NVL(last_analyzed, MIN(NVL(last_analyzed, save_time)) OVER ()) save_time
                  FROM (
                SELECT 'TABLE' obj_type,
                       object_type,
                       object_id,
                       table_name object_name,
                       NVL(subpartition_name, partition_name) subobject_name,
                       MIN(last_analyzed) KEEP (DENSE_RANK FIRST ORDER BY save_time) last_analyzed,
                       MIN(save_time) save_time
                  FROM &&tool_repository_schema..sqlt$_dba_tab_stats_versions
                 WHERE statid = l_statid
                   AND version_type = 'HISTORY'
                 GROUP BY
                       object_type,
                       object_id,
                       table_name,
                       NVL(subpartition_name, partition_name)
                 UNION
                SELECT 'INDEX' obj_type,
                       object_type,
                       object_id,
                       index_name object_name,
                       NVL(subpartition_name, partition_name) subobject_name,
                       MIN(last_analyzed) KEEP (DENSE_RANK FIRST ORDER BY save_time) last_analyzed,
                       MIN(save_time) save_time
                  FROM &&tool_repository_schema..sqlt$_dba_ind_stats_versions
                 WHERE statid = l_statid
                   AND version_type = 'HISTORY'
                 GROUP BY
                       object_type,
                       object_id,
                       index_name,
                       NVL(subpartition_name, partition_name)))
      LOOP
        IF i.object_type IN ('PARTITION', 'SUBPARTITION') THEN
          l_object_type := i.obj_type||' '||i.object_type;
        ELSE
          l_object_type := i.object_type;
        END IF;

        l_object_id := sqlt$a.get_dba_object_id(l_object_type, l_schema_owner, i.object_name, i.subobject_name);
        l_savdate := i.save_time; -- from tz to date format
        l_savdate := l_savdate - 1; -- object creation date will be reset to 1 day before the oldest stats record

        IF l_object_id > 0 AND l_object_id <> i.object_id THEN
          BEGIN
            put_line('type:"'||i.object_type||'", name:"'||i.object_name||'", subname:"'||i.subobject_name||'", obj#:'||l_object_id||', ctime:'||TO_CHAR(l_savdate, 'YYYY-MM-DD/HH24:MI:SS'));
            -- never update sys.obj$ on a production environment.
            -- make this call only on an Oracle internal test environment.
            EXECUTE IMMEDIATE
            'UPDATE sys.obj$ SET ctime = :min_savtime WHERE obj# = :object_id AND ctime > :min_savtime'
            USING IN l_savdate, IN l_object_id, IN l_savdate;
          EXCEPTION
            WHEN OTHERS THEN
              put_line('reset of ctime for '||l_object_id||' failed.');
              put_line(SQLERRM);
              EXIT;
          END;
        END IF;
      END LOOP;
    END IF;

    COMMIT;
  END reset_object_creation_date;

  /*************************************************************************************/

END sqlt$i;
/

SET TERM ON;
SHOW ERRORS PACKAGE BODY &&tool_administer_schema..sqlt$i;
