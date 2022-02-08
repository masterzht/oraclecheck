CREATE OR REPLACE PACKAGE &&tool_administer_schema..sqlt$e AUTHID CURRENT_USER AS
/* $Header: 215187.1 sqcpkge.pks 12.1.10 2014/08/08 carlos.sierra mauro.pagano $ */

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
  RETURN NUMBER;

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
    p_directory_name       IN VARCHAR2 DEFAULT 'SQLT$STAGE' );

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
  RETURN NUMBER;

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
    x_db_link       OUT VARCHAR2 );

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
  RETURN VARCHAR2;

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
  RETURN DATE;

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
  RETURN NUMBER;

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
  RETURN CLOB;

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
    p_directory_name IN VARCHAR2 DEFAULT 'SQLT$STAGE' );

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
    p_directory_name IN VARCHAR2 DEFAULT 'SQLT$STAGE' );

END sqlt$e;
/

SET TERM ON;
SHOW ERRORS PACKAGE &&tool_administer_schema..sqlt$e;
