CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..sqlt$e AS
/* $Header: 215187.1 sqcpkge.pkb 12.1.160429 2016/04/29 carlos.sierra mauro.pagano abel.macias@oracle.com $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * private open_log
   *
   * ------------------------- */
  PROCEDURE open_log (p_statement_id IN NUMBER)
  IS
  BEGIN
    sqlt$a.s_log_statement_id := p_statement_id;
    sqlt$a.s_log_statid := sqlt$a.get_statid(p_statement_id);
  END open_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * private close_log
   *
   * ------------------------- */
  PROCEDURE close_log (p_statement_id IN NUMBER)
  IS
  BEGIN
    sqlt$a.s_log_statement_id := NULL;
    sqlt$a.s_log_statid := NULL;
    sqlt$a.set_module;
  END close_log;

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
    sqlt$a.write_log(p_line_text => p_line_text, p_line_type => p_line_type, p_package => 'E');
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
    sqlt$a.write_error('e:'||p_line_text);
  END write_error;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_file_attributes_from_repo
   *
   * returns attributes of files created by sqlt
   * xtract, xecute or xplain in the sqlt repository.
   *
   * file_type            suffix                    XTRACT  XECUTE  XPLAIN  11g  10g  Comments
   * ~~~~~~~~~~~~~~~~~~~  ~~~~~~~~~~~~~~~~~~~~~~~~  ~~~~~~  ~~~~~~  ~~~~~~  ~~~  ~~~  ~~~~~~~~
   * MAIN_REPORT          _main.html                   Y       Y       Y     Y    Y
   * METADATA_SCRIPT      _metadata.sql                Y       Y       Y     Y    Y
   * METADATA_SCRIPT1     _metadata1.sql               Y       Y       Y     Y    Y
   * METADATA_SCRIPT2     _metadata2.sql               Y       Y       Y     Y    Y
   * SYSTEM_STATS_SCRIPT  _system_stats.sql            Y       Y       Y     Y    Y
   * SCHEMA_STATS_SCRIPT  _schema_stats.sql            Y       Y       Y     Y    Y
   * SET_CBO_ENV_SCRIPT   _set_cbo_env.sql             Y       Y       Y     Y    Y
   * LITE_REPORT          _lite.html                   Y       Y       Y     Y    Y
   * README_REPORT_HTML   _readme.html                 Y       Y       Y     Y    Y
   * README_REPORT_TXT    _readme.txt                  Y       Y       Y     Y    Y
   * 10053_EXPLAIN        _10053_explain.trc           Y       Y       Y     Y    Y
   * 10053_EXTRACT        _10053_extract.trc           Y       N       N     Y    N
   * 10046_10053_EXECUTE  _10046_10053_execute.trc     N       Y       N     Y    Y
   * TRACE_10046          _10046_execute.trc           N       Y       N     Y    Y
   * TRACE_10053          _10053_execute.trc           N       Y       N     Y    Y
   * TEST_CASE_SCRIPT     _tc_script.sql               Y       N       N     Y    Y
   * TEST_CASE_SQL        _tc_sql.sql                  Y       N       N     Y    Y
   * TCB_DRIVER           _tcb_driver.sql              Y       Y       Y     Y    Y
   * EXPORT_PARFILE       _export_parfile.txt          Y       Y       Y     Y    Y
   * EXPORT_PARFILE2      _export_parfile2.txt         Y       Y       Y     Y    Y
   * EXPORT_DRIVER        _export_driver.sql           Y       Y       Y     Y    Y
   * IMPORT_SCRIPT        _import.sh                   Y       Y       Y     Y    Y
   * CUSTOM_SQL_PROFILE   _sqlprof.sql                 Y       Y       Y     Y    Y
   * STA_REPORT_MEM       _sta_report_mem.txt          Y       Y       Y     Y    Y
   * STA_SCRIPT_MEM       _sta_script_mem.sql          Y       Y       Y     Y    Y
   * STA_REPORT_AWR       _sta_report_awr.txt          Y       Y       Y     Y    Y
   * STA_SCRIPT_AWR       _sta_script_awr.sql          Y       Y       Y     Y    Y
   * SQL_MONITOR_ACTIVE   _sql_monitor_active.html     Y       Y       Y     Y    N
   * SQL_MONITOR_HTML     _sql_monitor.html            Y       Y       Y     Y    N
   * SQL_MONITOR_TEXT     _sql_monitor.txt             Y       Y       Y     Y    N
   * SQL_MONITOR_DRIVER   _sql_monitor_driver.sql      Y       Y       Y     Y    N
   * SQL_DETAIL_ACTIVE    _sql_detail_active.html      Y       Y       Y     Y    N
   * AWRRPT_DRIVER        _awrrpt_driver.sql           Y       Y       Y     Y    Y
   * ADDMRPT_DRIVER       _addmrpt_driver.sql          Y       Y       Y     Y    Y
   * ASHRPT_DRIVER        _ashrpt_driver.sql           Y       Y       Y     Y    Y
   * TRCA_HTML            _trca_99999.html             N       Y       N     Y    Y
   * TRCA_TXT             _trca_99999.txt              N       Y       N     Y    Y
   * TRCA_LOG             _trca_99999.log              N       Y       N     Y    Y
   * REMOTE_DRIVER        _remote_driver.sql           Y       Y       Y     Y    Y
   * SCRIPT_OUTPUT_DRIVER _script_output_driver.sql    N       Y       N     Y    Y
   * TKPROF_PX_DRIVER     _tkprof_px_driver.sql        Y       Y       Y     Y    Y
   * TRCA_PX_HTML         _px_trca_99999.html          N       Y       N     Y    Y
   * TRCA_PX_TXT          _px_trca_99999.txt           N       Y       N     Y    Y
   * TRCA_PX_LOG          _px_trca_99999.log           N       Y       N     Y    Y
   * REMOTE_TRACE         _10046_10053.trc             Y       Y       Y     Y    Y
   * COMPARE_REPORT       _compare.html                N       N       N     Y    Y   COMPARE
   * BDE_CHK_CBO_REPORT   _bde_chk_cbo_report.html     Y       Y       Y     Y    Y   EBS
   * PROCESS_LOG          _process.log                 Y       Y       Y     Y    Y
   * PURGE                _purge.sql                   Y       Y       Y     Y    Y
   * RESTORE              _restore.sql                 Y       Y       Y     Y    Y
   * DEL_HGRM             _del_hgrm.sql                Y       Y       Y     Y    Y
   * PLAN                 plan.sql                     Y       Y       Y     Y    Y
   * 10053                10053.sql                    Y       Y       Y     Y    Y
   * FLUSH                flush.sql                    Y       Y       Y     Y    Y
   * Q                    q.sql                        Y       Y       Y     Y    Y
   * TC_SQL               tc.sql                       Y       Y       Y     Y    Y
   * XPRESS_SH            xpress.sh                    Y       Y       Y     Y    Y
   * XPRESS_SQL           xpress.sql                   Y       Y       Y     Y    Y
   * SETUP                setup.sql                    Y       Y       Y     Y    Y
   * README               readme.txt                   Y       Y       Y     Y    Y
   * TC_PKG               tc_pkg.sql                   Y       Y       Y     Y    Y
   * SEL                  sel.sql                      Y       Y       Y     Y    Y
   * SEL_AUX              sel_aux.sql                  Y       Y       Y     Y    Y
   * INSTALL_SH           install.sh                   Y       Y       Y     Y    Y
   * INSTALL_SQL          install.sql                  Y       Y       Y     Y    Y
   * TCX_PKG              tcx_pkg.sql                  Y       Y       Y     Y    Y
   * XPAND_SQL_DRIVER     _xpand_sql_driver.sql        Y       Y       Y     Y    N
   * PERFHUB_DRIVER       _perfhub_driver.sql          Y       Y       Y     N    N
   *
   * ------------------------- */
  PROCEDURE get_file_attributes_from_repo (
    p_file_type     IN  VARCHAR2,
    p_statement_id  IN  NUMBER, -- local
    p_statement_id2 IN  NUMBER DEFAULT NULL, -- remote
    x_statid        OUT VARCHAR2,
    x_filename      OUT VARCHAR2,
    x_file_date     OUT DATE,
    x_file_size     OUT NUMBER,
    x_username      OUT VARCHAR2,
    x_db_link       OUT VARCHAR2 )
  IS
    l_count NUMBER;
  BEGIN
    open_log(p_statement_id);
    write_log('-> get_file_attributes_from_repo');

    SELECT COUNT(*)
      INTO l_count
      FROM &&tool_repository_schema..sqlt$_sql_statement
     WHERE statement_id = p_statement_id;

    IF l_count = 0 THEN
      RAISE_APPLICATION_ERROR(-20110, 'Statement ID "'||p_statement_id||'" does not exist.');
    END IF;

    IF p_file_type NOT IN (
      'MAIN_REPORT',
      'METADATA_SCRIPT',
      'METADATA_SCRIPT1',
      'METADATA_SCRIPT2',
      'SYSTEM_STATS_SCRIPT',
      'SCHEMA_STATS_SCRIPT',
      'SET_CBO_ENV_SCRIPT',
      'LITE_REPORT',
      'README_REPORT_HTML',
      'README_REPORT_TXT',
      '10053_EXPLAIN',
      '10053_EXTRACT',
      '10046_10053_EXECUTE',
      'TRACE_10046',
      'TRACE_10053',
      'TEST_CASE_SCRIPT',
      'TEST_CASE_SQL',
      'TCB_DRIVER',
      'EXPORT_PARFILE',
      'EXPORT_PARFILE2',
      'EXPORT_DRIVER',
      'IMPORT_SCRIPT',
      'CUSTOM_SQL_PROFILE',
      'STA_REPORT_MEM',
      'STA_SCRIPT_MEM',
      'STA_REPORT_TXT',
      'STA_SCRIPT_TXT',
      'STA_REPORT_AWR',
      'STA_SCRIPT_AWR',
      'SQL_MONITOR_ACTIVE',
      'SQL_MONITOR_HTML',
      'SQL_MONITOR_TEXT',
      'SQL_MONITOR_DRIVER',
      'SQL_DETAIL_ACTIVE',
      'AWRRPT_DRIVER',
      'ADDMRPT_DRIVER',
      'ASHRPT_DRIVER',
      'TRCA_HTML',
      'TRCA_TXT',
      'TRCA_LOG',
      'REMOTE_DRIVER',
      'SCRIPT_OUTPUT_DRIVER',
      'TKPROF_PX_DRIVER',
      'TRCA_PX_HTML',
      'TRCA_PX_TXT',
      'TRCA_PX_LOG',
      'REMOTE_TRACE',
      'COMPARE_REPORT',
      'BDE_CHK_CBO_REPORT',
      'PROCESS_LOG',
      'PURGE',
      'RESTORE',
      'DEL_HGRM',
      'PLAN',
      '10053',
      'FLUSH',
      'Q',
      'TC_SQL',
      'XPRESS_SH',
      'XPRESS_SQL',
      'SETUP',
      'README',
      'TC_PKG',
      'SEL',
      'SEL_AUX',
      'INSTALL_SH',
      'INSTALL_SQL',
      'TCX_PKG',
      'XPAND_SQL_DRIVER',
	  'PERFHUB_DRIVER')  --160403
    THEN
      RAISE_APPLICATION_ERROR(-20100, '"'||p_file_type||'" is not a valid file type.');
    END IF;

    BEGIN
      SELECT statid,
             filename,
             file_date,
             file_size,
             username,
             db_link
        INTO x_statid,
             x_filename,
             x_file_date,
             x_file_size,
             x_username,
             x_db_link
        FROM (
      SELECT statid,
             filename,
             file_date,
             file_size,
             username,
             db_link
        FROM &&tool_repository_schema..sqli$_file
       WHERE ( ( p_statement_id2 IS NULL AND
                 statement_id = p_statement_id ) OR
               ( p_statement_id2 IS NOT NULL AND
                 statement_id IN (p_statement_id, p_statement_id2 ) AND
                 statement_id2 IN (p_statement_id, p_statement_id2 ) ) )
         AND file_type = UPPER(TRIM(p_file_type))
       ORDER BY
             file_date DESC ) v
       WHERE ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        write_log('file "'||p_statement_id||'" "'|| p_file_type||'" does not exist');
      WHEN OTHERS THEN
        write_error(SQLERRM);
    END;

    write_log('<- get_file_attributes_from_repo');
    close_log(p_statement_id);
  END get_file_attributes_from_repo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_filename_from_repo
   *
   * returns filename from get_file_attributes_from_repo
   *
   * ------------------------- */
  FUNCTION get_filename_from_repo (
    p_file_type     IN VARCHAR2,
    p_statement_id  IN NUMBER,
    p_statement_id2 IN NUMBER DEFAULT NULL )
  RETURN VARCHAR2
  IS
    file_rec &&tool_repository_schema..sqli$_file%ROWTYPE;
  BEGIN
    get_file_attributes_from_repo (
      p_file_type     => p_file_type,
      p_statement_id  => p_statement_id,
      p_statement_id2 => p_statement_id2,
      x_statid        => file_rec.statid,
      x_filename      => file_rec.filename,
      x_file_date     => file_rec.file_date,
      x_file_size     => file_rec.file_size,
      x_username      => file_rec.username,
      x_db_link       => file_rec.db_link );
    RETURN file_rec.filename;
  END get_filename_from_repo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_file_date_from_repo
   *
   * returns file_date from get_file_attributes_from_repo
   *
   * ------------------------- */
  FUNCTION get_file_date_from_repo (
    p_file_type     IN VARCHAR2,
    p_statement_id  IN NUMBER,
    p_statement_id2 IN NUMBER DEFAULT NULL )
  RETURN DATE
  IS
    file_rec &&tool_repository_schema..sqli$_file%ROWTYPE;
  BEGIN
    get_file_attributes_from_repo (
      p_file_type     => p_file_type,
      p_statement_id  => p_statement_id,
      p_statement_id2 => p_statement_id2,
      x_statid        => file_rec.statid,
      x_filename      => file_rec.filename,
      x_file_date     => file_rec.file_date,
      x_file_size     => file_rec.file_size,
      x_username      => file_rec.username,
      x_db_link       => file_rec.db_link );
    RETURN file_rec.file_date;
  END get_file_date_from_repo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_file_size_from_repo
   *
   * returns file_size from get_file_attributes_from_repo
   *
   * ------------------------- */
  FUNCTION get_file_size_from_repo (
    p_file_type     IN VARCHAR2,
    p_statement_id  IN NUMBER,
    p_statement_id2 IN NUMBER DEFAULT NULL )
  RETURN NUMBER
  IS
    file_rec &&tool_repository_schema..sqli$_file%ROWTYPE;
  BEGIN
    get_file_attributes_from_repo (
      p_file_type     => p_file_type,
      p_statement_id  => p_statement_id,
      p_statement_id2 => p_statement_id2,
      x_statid        => file_rec.statid,
      x_filename      => file_rec.filename,
      x_file_date     => file_rec.file_date,
      x_file_size     => file_rec.file_size,
      x_username      => file_rec.username,
      x_db_link       => file_rec.db_link );
    RETURN file_rec.file_size;
  END get_file_size_from_repo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_file_text_from_repo
   *
   * calls get_file_attributes_from_repo to validate parameters,
   * then it reads file text from sqlt repository and returns it
   * as a clob of certain width
   *
   * ------------------------- */
  FUNCTION get_file_text_from_repo (
    p_file_type     IN VARCHAR2,
    p_statement_id  IN NUMBER,
    p_statement_id2 IN NUMBER  DEFAULT NULL,
    p_max_line_size IN INTEGER DEFAULT 2000 )
  RETURN CLOB
  IS
    file_rec &&tool_repository_schema..sqli$_file%ROWTYPE;
  BEGIN
    open_log(p_statement_id);
    write_log('-> get_file_text_from_repo');

    get_file_attributes_from_repo (
      p_file_type     => p_file_type,
      p_statement_id  => p_statement_id,
      p_statement_id2 => p_statement_id2,
      x_statid        => file_rec.statid,
      x_filename      => file_rec.filename,
      x_file_date     => file_rec.file_date,
      x_file_size     => file_rec.file_size,
      x_username      => file_rec.username,
      x_db_link       => file_rec.db_link );

    IF file_rec.filename IS NOT NULL THEN
      SELECT file_text
        INTO file_rec.file_text
        FROM &&tool_repository_schema..sqli$_file
       WHERE statement_id = p_statement_id
         AND file_type = UPPER(TRIM(p_file_type));

      file_rec.file_text := sqlt$r.wrap_clob(file_rec.file_text, p_max_line_size);
    ELSE
      file_rec.file_text := NULL;
    END IF;

    write_log('<- get_file_text_from_repo');
    close_log(p_statement_id);
    RETURN file_rec.file_text;
  END get_file_text_from_repo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public copy_file_from_repo_to_dir
   *
   * calls get_file_attributes_from_repo to get filename, then
   * copies file_text from sqlt repository into an os directory
   * using utl_file.
   *
   * ------------------------- */
  PROCEDURE copy_file_from_repo_to_dir (
    p_file_type      IN VARCHAR2,
    p_statement_id   IN NUMBER,
    p_statement_id2  IN NUMBER   DEFAULT NULL,
    p_directory_name IN VARCHAR2 DEFAULT 'SQLT$STAGE' )
  IS
    file_rec &&tool_repository_schema..sqli$_file%ROWTYPE;
  BEGIN
    open_log(p_statement_id);
    write_log('-> copy_file_from_repo_to_dir');

    get_file_attributes_from_repo (
      p_file_type     => p_file_type,
      p_statement_id  => p_statement_id,
      p_statement_id2 => p_statement_id2,
      x_statid        => file_rec.statid,
      x_filename      => file_rec.filename,
      x_file_date     => file_rec.file_date,
      x_file_size     => file_rec.file_size,
      x_username      => file_rec.username,
      x_db_link       => file_rec.db_link );

    IF file_rec.filename IS NOT NULL THEN
      sqlt$r.utl_file (
        p_filename       => file_rec.filename,
        p_statement_id   => p_statement_id,
        p_statement_id2  => p_statement_id2,
        p_directory_name => p_directory_name );
    END IF;

    write_log('<- copy_file_from_repo_to_dir');
    close_log(p_statement_id);
  END copy_file_from_repo_to_dir;

  /*************************************************************************************/

  /* -------------------------
   *
   * public copy_files_from_repo_to_dir
   *
   * gets all filenames associated to an statement from sqlt
   * xtract, xecute, xplain or compare, then copies file_texts
   * from the sqlt repository into an os directory using utl_file.
   *
   * ------------------------- */
  PROCEDURE copy_files_from_repo_to_dir (
    p_statement_id   IN NUMBER,
    p_statement_id2  IN NUMBER   DEFAULT NULL,
    p_directory_name IN VARCHAR2 DEFAULT 'SQLT$STAGE' )
  IS
    file_rec &&tool_repository_schema..sqli$_file%ROWTYPE;
  BEGIN
    open_log(p_statement_id);
    write_log('-> copy_files_from_repo_to_dir');

    FOR i IN (SELECT filename,
                     statement_id,
                     statement_id2
                FROM &&tool_repository_schema..sqli$_file
               WHERE p_statement_id IN (statement_id, statement_id2)
                 AND (p_statement_id2 IS NULL OR p_statement_id2 IN (statement_id2, statement_id))
                 AND filename LIKE 'sqlt_s%') -- excludes files with common names (used by SQLT TC) because of collisions between statements and since we do not have dmp anyway
    LOOP
      sqlt$r.utl_file (
        p_filename       => i.filename,
        p_statement_id   => i.statement_id,
        p_statement_id2  => i.statement_id2,
        p_directory_name => p_directory_name );
    END LOOP;

    write_log('<- copy_files_from_repo_to_dir');
    close_log(p_statement_id);
  END copy_files_from_repo_to_dir;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xtract_sql_put_files_in_repo
   *
   * executes sqlt xtract on a single sql then puts
   * all generated files into the sqlt repository,
   * returning the sqlt statement id.
   *
   * ------------------------- */
  FUNCTION xtract_sql_put_files_in_repo (
    p_sql_id_or_hash_value IN VARCHAR2,
    p_out_file_identifier  IN VARCHAR2 DEFAULT NULL,
    p_tcb_directory_name   IN VARCHAR2 DEFAULT 'SQLT$STAGE' )
  RETURN NUMBER
  IS
    l_statement_id NUMBER;
  BEGIN
    IF p_tcb_directory_name = 'SQLT$STAGE' THEN
      sqlt$a.reset_directories;
    END IF;
    l_statement_id := sqlt$a.get_statement_id;
    sqlt$i.xtract_and_trap_error (
      p_statement_id         => l_statement_id,
      p_sql_id_or_hash_value => p_sql_id_or_hash_value,
      p_out_file_identifier  => p_out_file_identifier,
      p_tcb_directory_name   => p_tcb_directory_name );
    RETURN l_statement_id;
  END xtract_sql_put_files_in_repo;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xtract_sql_put_files_in_dir
   *
   * executes sqlt xtract on a single sql then
   * puts all generated files into an os directory,
   * returning the sqlt statement id.
   *
   * ------------------------- */
  FUNCTION xtract_sql_put_files_in_dir (
    p_sql_id_or_hash_value IN VARCHAR2,
    p_out_file_identifier  IN VARCHAR2 DEFAULT NULL,
    p_directory_name       IN VARCHAR2 DEFAULT 'SQLT$STAGE' )
  RETURN NUMBER
  IS
    l_statement_id NUMBER;
  BEGIN
    l_statement_id := xtract_sql_put_files_in_repo(p_sql_id_or_hash_value, p_out_file_identifier, p_directory_name);

    copy_files_from_repo_to_dir (
      p_statement_id   => l_statement_id,
      p_directory_name => p_directory_name );

    RETURN l_statement_id;
  END xtract_sql_put_files_in_dir;

  /*************************************************************************************/

  /* -------------------------
   *
   * public xtract_sql_put_files_in_dir (overload)
   *
   * executes sqlt xtract on a single sql then
   * puts all generated files into an os directory.
   *
   * ------------------------- */
  PROCEDURE xtract_sql_put_files_in_dir (
    p_sql_id_or_hash_value IN VARCHAR2,
    p_out_file_identifier  IN VARCHAR2 DEFAULT NULL,
    p_directory_name       IN VARCHAR2 DEFAULT 'SQLT$STAGE' )
  IS
    l_statement_id NUMBER;
  BEGIN
    l_statement_id := xtract_sql_put_files_in_dir (
      p_sql_id_or_hash_value => p_sql_id_or_hash_value,
      p_directory_name       => p_directory_name,
      p_out_file_identifier  => p_out_file_identifier );
  END xtract_sql_put_files_in_dir;

  /*************************************************************************************/


END sqlt$e;
/

SET TERM ON;
SHOW ERRORS PACKAGE BODY &&tool_administer_schema..sqlt$e;
