CREATE OR REPLACE PACKAGE &&tool_administer_schema..sqlt$r AUTHID DEFINER AS
/* $Header: 215187.1 sqcpkgr.pks 12.1.160429 2016/04/29 carlos.sierra mauro.pagano abel.macias@oracle.com $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * public types
   *
   * ------------------------- */
  TYPE varchar2_table IS TABLE OF VARCHAR2(2000);

  /* -------------------------
   *
   * public apis
   *
   * ------------------------- */

  FUNCTION color_differences (
    p_number1     IN NUMBER,
    p_number2     IN NUMBER,
    p_text        IN VARCHAR2,
    p_percent1    IN NUMBER  DEFAULT 10,
    p_percent2    IN NUMBER  DEFAULT 100,
    p_ignore_zero IN BOOLEAN DEFAULT FALSE )
  RETURN VARCHAR2;

  FUNCTION color_differences_c (
    p_text1 IN VARCHAR2,
    p_text2 IN VARCHAR2,
    p_text  IN VARCHAR2 )
  RETURN VARCHAR2;

  FUNCTION display_file (
    p_filename      IN VARCHAR2,
    p_statement_id  IN NUMBER  DEFAULT NULL,
    p_statement_id2 IN NUMBER  DEFAULT NULL,
    p_max_line_size IN INTEGER DEFAULT 2000 )
  RETURN varchar2_table PIPELINED;

  FUNCTION libraries_versions
  RETURN varchar2_table PIPELINED;

  FUNCTION over_under_difference (
    p_number1     IN NUMBER,
    p_number2     IN NUMBER,
    p_percent1    IN NUMBER  DEFAULT 10,
    p_percent2    IN NUMBER  DEFAULT 100,
    p_percent3    IN NUMBER  DEFAULT 1000 )
  RETURN VARCHAR2;

  FUNCTION sanitize_html_clob (
    p_clob IN CLOB,
    p_br   IN BOOLEAN DEFAULT TRUE )
  RETURN CLOB;

  FUNCTION sanitize_js_text (p_text IN VARCHAR2)
  RETURN VARCHAR2;

  PROCEDURE utl_file (
    p_filename       IN VARCHAR2,
    p_statement_id   IN NUMBER   DEFAULT NULL,
    p_statement_id2  IN NUMBER   DEFAULT NULL,
    p_directory_name IN VARCHAR2 DEFAULT 'SQLT$STAGE' );

  FUNCTION wrap_clob (
    p_clob          IN CLOB,
    p_max_line_size IN INTEGER DEFAULT 80 )
  RETURN CLOB;

  FUNCTION wrap_and_sanitize_html_clob (
    p_clob          IN CLOB,
    p_max_line_size IN INTEGER DEFAULT 80,
    p_br            IN BOOLEAN DEFAULT TRUE )
  RETURN CLOB;

  FUNCTION wrap_sanitize_font_html_clob (
    p_clob          IN CLOB,
    p_max_line_size IN INTEGER DEFAULT 80,
    p_br            IN BOOLEAN DEFAULT TRUE )
  RETURN CLOB;

  /*************************************************************************************/

  /* -------------------------
   *
   * public reports or scripts
   *
   * ------------------------- */

  PROCEDURE addmrpt_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE ashrpt_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE awrrpt_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE bde_chk_cbo_report (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE custom_sql_profile (
    p_statement_id        IN NUMBER,
    p_plan_hash_value     IN NUMBER   DEFAULT NULL,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL,
    p_calling_library     IN VARCHAR2 DEFAULT 'sqltprofile.sql' );

  PROCEDURE export_driver (
    p_statement_id        IN NUMBER,
    p_password            IN VARCHAR2 DEFAULT 'N',
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE export_parfile (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE export_parfile2 (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE flush (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL );

  PROCEDURE import_script (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE install_sh (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL );

  PROCEDURE install_sql (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE lite_report (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE metadata_script (
    p_statement_id        IN NUMBER,
    p_script_type         IN VARCHAR2 DEFAULT NULL, -- NULL|1|2
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  -- 160403 New
  PROCEDURE perfhub_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );	
	
  PROCEDURE plan (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL );

  PROCEDURE process_log (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE purge (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE readme (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE readme_report_html (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE readme_report_txt (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE remote_driver (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE restore (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE del_hgrm (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE s10053 (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL );

  PROCEDURE schema_stats_script (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE script_output_driver (
    p_statement_id        IN NUMBER,
    p_input_filename      IN VARCHAR2,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE sel (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL );

  PROCEDURE sel_aux (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL );

  PROCEDURE set_cbo_env_script (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE setup (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE sql_detail_report (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE sql_monitor_driver(p_statement_id IN NUMBER);

  PROCEDURE sql_monitor_reports (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE system_stats_script (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE tc_pkg (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE tc_sql (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL );

  PROCEDURE tcb_driver (
    p_statement_id        IN NUMBER,
    p_generate_script     IN BOOLEAN,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE tcx_pkg (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE test_case_script (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL,
    p_include_hint_id     IN BOOLEAN  DEFAULT TRUE );

  PROCEDURE test_case_sql (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE tkprof_px_driver (
    p_statement_id        IN  NUMBER,
    p_out_file_identifier IN  VARCHAR2 DEFAULT NULL,
    x_file_name           OUT VARCHAR2 );

  PROCEDURE xpress_sh (
    p_statement_id IN NUMBER,
    p_group_id     IN NUMBER   DEFAULT NULL,
    p_db_link      IN VARCHAR2 DEFAULT NULL,
    p_file_prefix  IN VARCHAR2 DEFAULT NULL );

  PROCEDURE xpress_sql (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );
	
  PROCEDURE xpand_sql_driver (   -- 12.1.03
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );  	

  /*************************************************************************************/

END sqlt$r;
/

SET TERM ON;
SHOW ERRORS PACKAGE &&tool_administer_schema..sqlt$r;
