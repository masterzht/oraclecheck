CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..trca$i AS
/* $Header: 224270.1 tacpkgi.pkb 12.1.14 2015/12/06 carlos.sierra mauro.pagano abel.macias@oracle.com $ */

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  USYS                   CONSTANT INTEGER :=  0;

  /*************************************************************************************/

  /* -------------------------
   *
   * private print_log
   *
   * writes line into log
   *
   * ------------------------- */
  PROCEDURE print_log (
    p_line IN VARCHAR2 )
  IS
  BEGIN /* print_log */
    trca$g.print_log(p_buffer => p_line, p_package => 'I');
  END print_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * private explain_plans
   *
   * ------------------------- */
  PROCEDURE explain_plans (
    p_tool_execution_id IN INTEGER )
  IS
    MAX_LEN CONSTANT INTEGER := 32680; -- EXECUTE IMMEDIATE cannot go longer than 32767
    l_sql_text VARCHAR2(32767);

  BEGIN /* explain_plans */
    print_log('-> explain_plans');
    FOR i IN (SELECT group_id,
                     hv,
                     len,
                     sql_fulltext
                FROM &&tool_administer_schema..trca$_group_v
               WHERE tool_execution_id = p_tool_execution_id
                 AND include_details   = 'Y'
                 AND len               < MAX_LEN
                 AND NVL(command_type_name, 'UNKNOWN') IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE TABLE', 'CREATE INDEX', 'ALTER INDEX', 'UNKNOWN')
                 AND ((uid# <> USYS AND UID <> USYS) OR (uid# = USYS AND UID = USYS))
               ORDER BY
                     group_id)
    LOOP
      BEGIN
	    -- 22170181 Using NOOP as EXPLAN PLAN FOR does not executes l_sql_text
        l_sql_text := DBMS_ASSERT.NOOP(SUBSTR(i.sql_fulltext, 1, MAX_LEN));
        EXECUTE IMMEDIATE 'EXPLAIN PLAN SET STATEMENT_ID = '''||LPAD(p_tool_execution_id, 6, '0')||'-'||LPAD(i.group_id, 6, '0')||''' INTO '||trca$g.g_tool_repository_schema||'.trca$_plan_table FOR '||l_sql_text;
      EXCEPTION
        WHEN OTHERS THEN
          print_log(SQLERRM);
          print_log('Trapped while getting explain plan for hv='||i.hv||' len='||i.len||' '||SUBSTR(trca$g.flatten_text(l_sql_text), 1, 100));
      END;
    END LOOP;

    COMMIT;
    print_log('<- explain_plans');
  END explain_plans;

  /*************************************************************************************/

  /* -------------------------
   *
   * public second_transformation
   *
   * ------------------------- */
  PROCEDURE second_transformation (
    p_tool_execution_id IN INTEGER )
  IS
    l_op_name VARCHAR2(128) := LOWER(TRIM(trca$g.g_tool_administer_schema))||'.trca$i.second_transformation';
    l_totalwork NUMBER := 1;
    l_units VARCHAR2(32) := 'steps';

  BEGIN /* second_transformation */
    IF NOT trca$g.g_log_open THEN
      RETURN;
    END IF;

    print_log('=> second_transformation');

    trca$g.reset_session_longops;
    trca$g.set_session_longops (p_op_name => l_op_name, p_target => p_tool_execution_id, p_sofar => 0, p_totalwork => l_totalwork, p_target_desc => 'second_transformation', p_units => l_units);

    IF trca$g.g_include_expl_plans = 'Y' THEN
      explain_plans (p_tool_execution_id => p_tool_execution_id);
      trca$g.set_session_longops (p_sofar => 1, p_totalwork => l_totalwork);
    END IF;

    print_log('<= second_transformation');
  END second_transformation;

  /*************************************************************************************/

  /* -------------------------
   *
   * private perform_count_star
   *
   * ------------------------- */
  PROCEDURE perform_count_star (
    p_tool_execution_id IN INTEGER )
  IS
    l_actual_rows INTEGER;
    l_actual_rows_suffix CHAR(1);

  BEGIN /* perform_count_star */
    print_log('-> perform_count_star');
    FOR i IN (SELECT ROWID row_id, owner, table_name
                FROM &&tool_repository_schema..trca$_tables
               WHERE tool_execution_id = p_tool_execution_id
                 AND ((owner <> 'SYS' AND USER <> 'SYS') OR (owner = 'SYS' AND USER = 'SYS'))
               ORDER BY
                     owner,
                     table_name)
    LOOP
      BEGIN
        l_actual_rows := NULL;
        l_actual_rows_suffix := NULL;

		-- 22170181 use bind for ROWNUM and QUALIFIED_SQL_NAME
        EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM '||DBMS_ASSERT.QUALIFIED_SQL_NAME('"'||i.owner||'"."'||i.table_name||'"')||' WHERE ROWNUM <= :r'
        INTO l_actual_rows 
		USING to_number(trca$g.g_count_star_th);
      EXCEPTION
        WHEN OTHERS THEN
          print_log(SQLERRM);
          print_log('Trapped while getting COUNT(*) for '||i.owner||'.'||i.table_name||' connected as '||USER);
      END;

      IF l_actual_rows IS NOT NULL THEN
        IF l_actual_rows = TO_NUMBER(trca$g.g_count_star_th) THEN
          l_actual_rows_suffix := '+';
        END IF;

        UPDATE &&tool_repository_schema..trca$_tables
           SET actual_rows = l_actual_rows,
               actual_rows_suffix = l_actual_rows_suffix
         WHERE ROWID = i.row_id;
      END IF;
    END LOOP;

    COMMIT;
    print_log('<- perform_count_star');
  END perform_count_star;

  /*************************************************************************************/

  /* -------------------------
   *
   * public fourth_transformation
   *
   * ------------------------- */
  PROCEDURE fourth_transformation (
    p_tool_execution_id IN INTEGER )
  IS
    l_op_name VARCHAR2(128) := LOWER(TRIM(trca$g.g_tool_administer_schema))||'.trca$i.fourth_transformation';
    l_totalwork NUMBER := 1;
    l_units VARCHAR2(32) := 'steps';

  BEGIN /* fourth_transformation */
    IF NOT trca$g.g_log_open THEN
      RETURN;
    END IF;

    print_log('=> fourth_transformation');

    trca$g.reset_session_longops;
    trca$g.set_session_longops (p_op_name => l_op_name, p_target => p_tool_execution_id, p_sofar => 0, p_totalwork => l_totalwork, p_target_desc => 'fourth_transformation', p_units => l_units);

    IF trca$g.g_perform_count_star = 'Y' AND TO_NUMBER(trca$g.g_count_star_th) > 0 THEN
      perform_count_star (p_tool_execution_id => p_tool_execution_id);
      trca$g.set_session_longops (p_sofar => 1, p_totalwork => l_totalwork);
    END IF;

    print_log('<= fourth_transformation');
  END fourth_transformation;

  /*************************************************************************************/

  /* -------------------------
   *
   * public trcanlzr
   *
   * called by sqlt$i.call_trace_analyzer, sqlt$i.call_trace_analyzer_px, trca$i.trcanlzr_remote and trca$i.trcanlzr
   *
   * ------------------------- */
  PROCEDURE trcanlzr (
    p_file_name            IN     VARCHAR2,
    p_analyze              IN     VARCHAR2 DEFAULT 'YES',  -- YES: sqlt$i.call_trace_analyzer, sqlt$i.call_trace_analyzer_px, trca$i.trcanlzr_remote and trca$i.trcanlzr
    p_split                IN     VARCHAR2 DEFAULT 'NO',   -- YES: sqlt$i.call_trace_analyzer and trca$i.trcanlzr_remote. NO: sqlt$i.call_trace_analyzer_px and trca$i.trcanlzr
    x_tool_execution_id    IN OUT INTEGER,
    x_html_report             OUT CLOB,
    x_text_report             OUT CLOB,
    x_log                     OUT CLOB,
    x_10046_trace             OUT CLOB,
    x_10053_trace             OUT CLOB,
    p_directory_alias_in   IN     VARCHAR2 DEFAULT NULL,   -- sqlt$i.call_trace_analyzer, trca$i.trcanlzr_remote and trca$i.trcanlzr
    p_file_name_log        IN     VARCHAR2 DEFAULT NULL,   -- sqlt$i.call_trace_analyzer, sqlt$i.call_trace_analyzer_px, trca$i.trcanlzr_remote
    p_file_name_html       IN     VARCHAR2 DEFAULT NULL,   -- sqlt$i.call_trace_analyzer, sqlt$i.call_trace_analyzer_px, trca$i.trcanlzr_remote
    p_file_name_txt        IN     VARCHAR2 DEFAULT NULL,   -- sqlt$i.call_trace_analyzer, sqlt$i.call_trace_analyzer_px, trca$i.trcanlzr_remote
    p_split_10046_filename IN     VARCHAR2 DEFAULT NULL,   -- trca$i.trcanlzr_remote
    p_split_10053_filename IN     VARCHAR2 DEFAULT NULL,   -- trca$i.trcanlzr_remote
    p_out_file_identifier  IN     VARCHAR2 DEFAULT NULL )  -- trca$i.trcanlzr_remote, trca$i.trcanlzr
  IS
    l_slash     NUMBER;
    l_file_name VARCHAR2(4000);
  BEGIN /* trcanlzr */
    l_slash := GREATEST(INSTR('/'||p_file_name, '/', -1), INSTR('\'||p_file_name, '\', -1));
    l_file_name := SUBSTR(p_file_name, l_slash);

    IF x_tool_execution_id IS NULL THEN
      x_tool_execution_id := trca$p.get_tool_execution_id;
    END IF;

    trca$g.open_log (
      p_tool_execution_id   => x_tool_execution_id,
      p_file_name           => p_file_name_log,
      p_out_file_identifier => p_out_file_identifier );

    print_log('=> trcanlzr');
    IF l_file_name <> p_file_name THEN
      print_log('directory path was ignored from "'||p_file_name||'"');
    END IF;
    print_log('file_name:"'||l_file_name||'"');
    print_log('analyze:"'||p_analyze||'"');
    print_log('split:"'||p_split||'"');
    print_log('tool_execution_id:"'||x_tool_execution_id||'"');
    print_log('directory_alias_in:"'||p_directory_alias_in||'"');
    print_log('file_name_log:"'||p_file_name_log||'"');
    print_log('file_name_html:"'||p_file_name_html||'"');
    print_log('file_name_txt:"'||p_file_name_txt||'"');
    print_log('file_name_10046:"'||p_split_10046_filename||'"');
    print_log('file_name_10053:"'||p_split_10053_filename||'"');
    print_log('out_file_identifier:"'||p_out_file_identifier||'"');

    print_log('calling trca$p.parse_main');
    trca$p.parse_main (
      p_file_name            => l_file_name,
      p_tool_execution_id    => x_tool_execution_id,
      p_directory_alias_in   => p_directory_alias_in,
      p_analyze              => p_analyze,
      p_split                => p_split,
      p_split_10046_filename => p_split_10046_filename,
      p_split_10053_filename => p_split_10053_filename,
      x_10046_trace          => x_10046_trace,
      x_10053_trace          => x_10053_trace );

    IF p_analyze = 'YES' THEN
      print_log('calling trca$t.first_transformation');
      trca$t.first_transformation (
        p_tool_execution_id => x_tool_execution_id );

      print_log('calling second_transformation');
      second_transformation (
        p_tool_execution_id => x_tool_execution_id );

      print_log('calling trca$t.third_transformation');
      trca$t.third_transformation (
        p_tool_execution_id => x_tool_execution_id );

      print_log('calling fourth_transformation');
      fourth_transformation (
        p_tool_execution_id => x_tool_execution_id );

      print_log('calling trca$r.gen_html_report');
      trca$r.gen_html_report (
        p_tool_execution_id   => x_tool_execution_id,
        p_file_name           => p_file_name_html,
        p_out_file_identifier => p_out_file_identifier,
        x_html_report         => x_html_report );

      print_log('calling trca$x.gen_text_report');
      trca$x.gen_text_report (
        p_tool_execution_id   => x_tool_execution_id,
        p_file_name           => p_file_name_txt,
        p_out_file_identifier => p_out_file_identifier,
        x_text_report         => x_text_report );
    END IF;

    print_log('<= trcanlzr');
    trca$g.close_log (
      p_tool_execution_id => x_tool_execution_id,
      x_log               => x_log );

    trca$g.set_module; -- clear
  END trcanlzr;

  /*************************************************************************************/

  /* -------------------------
   *
   * public trcanlzr_remote
   *
   * called by sqlt$i.remote_call_trace_analyzer
   *
   * this api is executed in remote system. it inputs names of
   * trca files to generate but it does not return actual files,
   * they are simply kept inside the db as clobs.
   *
   * ------------------------- */
  PROCEDURE trcanlzr_remote (
    p_file_name            IN VARCHAR2,
    p_directory_alias_in   IN VARCHAR2 DEFAULT NULL,
    p_analyze              IN VARCHAR2 DEFAULT 'YES',
    p_split                IN VARCHAR2 DEFAULT 'YES',
    p_file_name_log        IN VARCHAR2 DEFAULT NULL,
    p_file_name_html       IN VARCHAR2 DEFAULT NULL,
    p_file_name_txt        IN VARCHAR2 DEFAULT NULL,
    p_split_10046_filename IN VARCHAR2 DEFAULT NULL,
    p_split_10053_filename IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier  IN VARCHAR2 DEFAULT NULL )
  IS
    l_tool_execution_id INTEGER := NULL;
    l_top_sql_ids       VARCHAR2(32767);
    l_html_report       CLOB;
    l_text_report       CLOB;
    l_log               CLOB;
    l_10046_trace       CLOB;
    l_10053_trace       CLOB;
  BEGIN /* trcanlzr_remote */
    trcanlzr (
      p_file_name            => p_file_name,
      p_analyze              => p_analyze,
      p_split                => p_split,
      x_tool_execution_id    => l_tool_execution_id,
      x_html_report          => l_html_report,
      x_text_report          => l_text_report,
      x_log                  => l_log,
      x_10046_trace          => l_10046_trace,
      x_10053_trace          => l_10053_trace,
      p_directory_alias_in   => p_directory_alias_in,
      p_file_name_log        => p_file_name_log,
      p_file_name_html       => p_file_name_html,
      p_file_name_txt        => p_file_name_txt,
      p_split_10046_filename => p_split_10046_filename,
      p_split_10053_filename => p_split_10053_filename,
      p_out_file_identifier  => p_out_file_identifier );
  END trcanlzr_remote;

  /*************************************************************************************/

  /* -------------------------
   *
   * public trcanlzr
   *
   * used by trca$e.trcanlzr_put_files_in_repo, trcanlzr.sql, trcasplit.sql, sqltrcanlzr.sql and sqltrcaxtr.sql
   *
   * ------------------------- */
  PROCEDURE trcanlzr (
    p_file_name           IN     VARCHAR2,
    p_out_file_identifier IN     VARCHAR2 DEFAULT NULL,
    p_directory_alias_in  IN     VARCHAR2 DEFAULT NULL,
    p_analyze             IN     VARCHAR2 DEFAULT 'YES',
    p_split               IN     VARCHAR2 DEFAULT 'NO',
    x_tool_execution_id   IN OUT INTEGER )
  IS
    l_html_report CLOB;
    l_text_report CLOB;
    l_log         CLOB;
    l_10046_trace CLOB;
    l_10053_trace CLOB;
  BEGIN
    trca$g.validate_user(USER);
    trcanlzr (
      p_file_name           => p_file_name,
      p_analyze             => p_analyze,
      p_split               => p_split,
      x_tool_execution_id   => x_tool_execution_id,
      x_html_report         => l_html_report,
      x_text_report         => l_text_report,
      x_log                 => l_log,
      x_10046_trace         => l_10046_trace,
      x_10053_trace         => l_10053_trace,
      p_directory_alias_in  => p_directory_alias_in,
      p_out_file_identifier => p_out_file_identifier );
  END trcanlzr;

  /*************************************************************************************/

  /* -------------------------
   *
   * public top_sql
   *
   * ------------------------- */
  PROCEDURE top_sql (
    p_tool_execution_id IN  INTEGER,
    p_sys               IN  VARCHAR2 DEFAULT 'N', -- (N)o, (Y)es
    p_time              IN  VARCHAR2 DEFAULT 'A', -- (R)esponse, E(lapsed), C(PU), (A)ll
    x_sql_ids           OUT VARCHAR2,
    x_hash_values       OUT VARCHAR2 )
  IS
  BEGIN /* top_sql */
    FOR i IN (SELECT sqlid, hv
                FROM &&tool_administer_schema..trca$_sql_v
               WHERE tool_execution_id = p_tool_execution_id
                 AND hv IS NOT NULL
                 AND CASE
                     WHEN p_sys = 'Y' AND uid# = 0 THEN 'Y'
                     WHEN p_sys = 'N' AND uid# <> 0 THEN 'Y'
                     ELSE 'N' END = 'Y'
                 AND CASE
                     WHEN p_time = 'A' AND (top_sql = 'Y' OR top_sql_et = 'Y' OR top_sql_ct = 'Y') THEN 'Y'
                     WHEN p_time = 'R' THEN top_sql
                     WHEN p_time = 'E' THEN top_sql_et
                     WHEN p_time = 'C' THEN top_sql_ct
                     ELSE top_sql END = 'Y'
               ORDER BY
                     CASE
                     WHEN p_time = 'A' THEN NVL(rank, 0) + NVL(rank_et, 0) + NVL(rank_ct, 0)
                     WHEN p_time = 'R' THEN rank
                     WHEN p_time = 'E' THEN rank_et
                     WHEN p_time = 'C' THEN rank_ct
                     ELSE rank END)
    LOOP
      IF NVL(LENGTH(x_sql_ids), 0) < 32700 AND NVL(LENGTH(i.sqlid), 0) > 0 THEN
        x_sql_ids := x_sql_ids||i.sqlid||',';
      END IF;
      IF NVL(LENGTH(x_hash_values), 0) < 32700 AND NVL(LENGTH(i.hv), 0) > 0 THEN
        x_hash_values := x_hash_values||i.hv||',';
      END IF;
    END LOOP;
    x_sql_ids := TRIM(',' FROM x_sql_ids);
    x_hash_values := TRIM(',' FROM x_hash_values);
  END top_sql;

  /*************************************************************************************/

  /* -------------------------
   *
   * public top_sql
   *
   * executed by remote_trace_analyzer_and_copy on remote
   *
   * ------------------------- */
  FUNCTION top_sql (
    p_tool_execution_id IN INTEGER,
    p_sys               IN VARCHAR2 DEFAULT 'N', -- (N)o, (Y)es
    p_time              IN VARCHAR2 DEFAULT 'A', -- (R)esponse, E(lapsed), C(PU), (A)ll
    p_id_type           IN VARCHAR2 DEFAULT 'S' ) -- (S)ql_id, (H)ash value
  RETURN VARCHAR2
  IS
    l_sql_ids     VARCHAR2(32767);
    l_hash_values VARCHAR2(32767);
  BEGIN /* top_sql */
    top_sql (
      p_tool_execution_id => p_tool_execution_id,
      p_sys               => p_sys,
      p_time              => p_time,
      x_sql_ids           => l_sql_ids,
      x_hash_values       => l_hash_values );

    IF p_id_type = 'H' THEN
      RETURN l_hash_values;
    ELSE
      RETURN l_sql_ids;
    END IF;
  END top_sql;

  /*************************************************************************************/

END trca$i;
/

SET TERM ON;
SHOW ERRORS;
