CREATE OR REPLACE PACKAGE &&tool_administer_schema..trca$e AUTHID CURRENT_USER AS
/* $Header: 224270.1 tacpkge.pks 11.4.5.0 2012/11/21 carlos.sierra $ */

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
  RETURN NUMBER;

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
    p_include_sqlt        IN VARCHAR2 DEFAULT 'Y' ); -- Y/N

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
  RETURN NUMBER;

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
  RETURN CLOB;

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
    p_directory_name    IN VARCHAR2 DEFAULT 'TRCA$STAGE' );

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
    p_directory_name    IN VARCHAR2 DEFAULT 'TRCA$STAGE' );

END trca$e;
/

SET TERM ON;
SHOW ERRORS;
