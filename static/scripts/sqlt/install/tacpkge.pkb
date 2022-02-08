CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..trca$e AS
/* $Header: 224270.1 tacpkge.pkb 11.4.5.0 2012/11/21 carlos.sierra $ */

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
    trca$g.set_module(p_module_name => LOWER(TRIM(trca$g.g_tool_repository_schema))||'.trca$e', p_action_name => p_line);
    SYS.DBMS_OUTPUT.PUT_LINE(SUBSTR(p_line, 1, 255));
  END print_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_file_text_from_repo
   *
   * reads file text from trca repository and
   * returns it as a clob of certain width.
   *
   * ------------------------- */
  FUNCTION get_file_text_from_repo (
    p_file_type         IN VARCHAR2, -- HTML, TEXT, LOG, 10053, 10046
    p_tool_execution_id IN NUMBER,
    p_max_line_size     IN INTEGER DEFAULT 2000 )
  RETURN CLOB
  IS
    file_rec trca$_file%ROWTYPE;
  BEGIN
    print_log('-> get_file_text_from_repo');
    file_rec := trca$g.get_file_from_repo(p_tool_execution_id, p_file_type);
    file_rec.file_text := trca$g.wrap_clob(file_rec.file_text, p_max_line_size);
    print_log('<- get_file_text_from_repo');
    RETURN file_rec.file_text;
  END get_file_text_from_repo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public copy_file_from_repo_to_dir
   *
   * copies file_text from trca repository into
   * an os directory using utl_file.
   *
   * ------------------------- */
  PROCEDURE copy_file_from_repo_to_dir (
    p_file_type         IN VARCHAR2, -- HTML, TEXT, LOG, 10053, 10046
    p_tool_execution_id IN NUMBER,
    p_directory_name    IN VARCHAR2 DEFAULT 'TRCA$STAGE' )
  IS
  BEGIN
    print_log('-> copy_file_from_repo_to_dir');
    trca$g.utl_file (
      p_tool_execution_id => p_tool_execution_id,
      p_file_type         => p_file_type,
      p_directory_name    => p_directory_name );
    print_log('<- copy_file_from_repo_to_dir');
  END copy_file_from_repo_to_dir;

  /*************************************************************************************/

  /* -------------------------
   *
   * public copy_files_from_repo_to_dir
   *
   * for a trca execution, copies file_texts from the
   * trca repository to an os directory using utl_file.
   *
   * ------------------------- */
  PROCEDURE copy_files_from_repo_to_dir (
    p_tool_execution_id IN NUMBER,
    p_directory_name    IN VARCHAR2 DEFAULT 'TRCA$STAGE' )
  IS
  BEGIN
    print_log('-> copy_files_from_repo_to_dir');
    FOR i IN (SELECT file_type
                FROM trca$_file
               WHERE tool_execution_id = p_tool_execution_id)
    LOOP
      trca$g.utl_file (
        p_tool_execution_id => p_tool_execution_id,
        p_file_type         => i.file_type,
        p_directory_name    => p_directory_name );
    END LOOP;
    print_log('<- copy_files_from_repo_to_dir');
  END copy_files_from_repo_to_dir;

  /*************************************************************************************/

  /* -------------------------
   *
   * public trcanlzr_put_files_in_repo
   *
   * executes trcanlzr on a trace (or set of traces)
   * then puts all generated files into the trca
   * repository, returning the tool execution id.
   *
   * ------------------------- */
  FUNCTION trcanlzr_put_files_in_repo (
    p_file_name           IN VARCHAR2, -- trace filename or control.txt
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL ) -- string to be included in output filenames
  RETURN NUMBER
  IS
    l_tool_execution_id INTEGER;
  BEGIN
    print_log('-> trcanlzr_put_files_in_repo');
    trca$i.trcanlzr(p_file_name => p_file_name, p_out_file_identifier => p_out_file_identifier, x_tool_execution_id => l_tool_execution_id);
    print_log('<- trcanlzr_put_files_in_repo');
    RETURN l_tool_execution_id;
  END trcanlzr_put_files_in_repo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public trcanlzr_put_files_in_dir
   *
   * executes trcanlzr on a trace (or set of traces)
   * then puts all generated files into an os directory,
   * returning the tool execution id.
   *
   * ------------------------- */
  FUNCTION trcanlzr_put_files_in_dir (
    p_file_name           IN VARCHAR2, -- trace filename or control.txt
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL,
    p_directory_name      IN VARCHAR2 DEFAULT 'TRCA$STAGE',
    p_include_sqlt        IN VARCHAR2 DEFAULT 'Y' ) -- Y/N
  RETURN NUMBER
  IS
    l_tool_execution_id INTEGER;
    l_statement_id NUMBER;
  BEGIN
    print_log('-> trcanlzr_put_files_in_dir_f');
    l_tool_execution_id := trcanlzr_put_files_in_repo(p_file_name, p_out_file_identifier);
    copy_files_from_repo_to_dir(l_tool_execution_id, p_directory_name);
    -- calls sqlt xtract on top sql
    IF NVL(SUBSTR(UPPER(TRIM(p_include_sqlt)), 1, 1), 'Y') = 'Y' THEN
      FOR i IN (SELECT NVL(sqlid, TO_CHAR(hv)) sql_id_or_hash_value
                  FROM trca$_sql_v
                 WHERE tool_execution_id = l_tool_execution_id
                   AND (top_sql = 'Y' OR top_sql_et = 'Y' OR top_sql_ct = 'Y')
                 ORDER BY
                       NVL(rank, 0) + NVL(rank_et, 0) + NVL(rank_ct, 0))
      LOOP
        BEGIN
          print_log('calling sqltxplain.xtract_sql_put_files_in_dir on sql_id_or_hash_value = "'||i.sql_id_or_hash_value||'"');
          EXECUTE IMMEDIATE 'BEGIN :statement_id := sqltxplain.sqlt$e.xtract_sql_put_files_in_dir(p_sql_id_or_hash_value => :sql_id_or_hash_value, p_directory_name => :directory_name, p_out_file_identifier => :out_file_identifier); END;'
          USING OUT l_statement_id, IN i.sql_id_or_hash_value, IN p_directory_name, IN p_out_file_identifier;
          print_log('sqlt_s'||l_statement_id||' was created for sql_id_or_hash_value = "'||i.sql_id_or_hash_value||'"');
        EXCEPTION
          WHEN OTHERS THEN
            print_log(SQLERRM);
        END;
      END LOOP;
    END IF;
    print_log('<- trcanlzr_put_files_in_dir_f');
    RETURN l_tool_execution_id;
  END trcanlzr_put_files_in_dir;

  /*************************************************************************************/

  /* -------------------------
   *
   * public trcanlzr_put_files_in_dir (overload)
   *
   * executes trcanlzr on a trace (or set of traces)
   * then puts all generated files into an os directory
   *
   * ------------------------- */
  PROCEDURE trcanlzr_put_files_in_dir (
    p_file_name           IN VARCHAR2, -- trace filename or control.txt
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL,
    p_directory_name      IN VARCHAR2 DEFAULT 'TRCA$STAGE',
    p_include_sqlt        IN VARCHAR2 DEFAULT 'Y' ) -- Y/N
  IS
    l_tool_execution_id INTEGER;
  BEGIN
    print_log('-> trcanlzr_put_files_in_dir_p');
    l_tool_execution_id := trcanlzr_put_files_in_dir(p_file_name, p_out_file_identifier, p_directory_name, p_include_sqlt);
    print_log('<- trcanlzr_put_files_in_dir_p');
  END trcanlzr_put_files_in_dir;

  /*************************************************************************************/

END trca$e;
/

SET TERM ON;
SHOW ERRORS;
