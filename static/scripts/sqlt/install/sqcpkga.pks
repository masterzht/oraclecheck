CREATE OR REPLACE PACKAGE &&tool_administer_schema..sqlt$a AUTHID DEFINER AS
/* $Header: 215187.1 sqcpkga.pks 12.2.171004 2017/10/04 stelios.charalambides@oracle.com carlos.sierrs mauro.pagano abel.macias $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * public types
   *
   * ------------------------- */
  TYPE varchar2_table IS TABLE OF VARCHAR2(2000);

  /*************************************************************************************/

  -- 171004 Extensive replacement of variables to varchar2(257)
  
  /* -------------------------
   *
   * static variables
   *
   * ------------------------- */
  s_log_statement_id NUMBER;
  s_log_statid       VARCHAR2(257);
  -- 22170172 making s_statistics_level private
    s_xtrxec           CHAR(1); -- set by xtrxec script to Y between xtr and xec. consumed by sqlt$i.common_calls during xec (set to N)
  s_overlib          CHAR(1) := 'Y'; -- used by sqlt$a and sqlt$m
  -- 150824 Making v_db_link private
  s_sqlt_method VARCHAR2(257); -- XTRACT, XECUTE, XPLAIN, XTRSBY

  /*************************************************************************************/

  /* -------------------------
   *
   * public apis
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
  RETURN varchar2_table PIPELINED;

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
  RETURN varchar2_table PIPELINED;

  FUNCTION awr_report_html (
    p_dbid        IN NUMBER,
    p_inst_num    IN NUMBER,
    p_bid         IN NUMBER,
    p_eid         IN NUMBER,
    p_rpt_options IN NUMBER DEFAULT 0 )
  RETURN varchar2_table PIPELINED;

  PROCEDURE clean_sqlt$_sql_plan_table (p_statement_id IN NUMBER);

  PROCEDURE common_initialization;
 
  PROCEDURE create_statement_workspace (
    p_statement_id     IN NUMBER,
    p_group_id         IN NUMBER DEFAULT NULL,   -- used by sqlt$i.remote_xtract
    p_statement_set_id IN NUMBER DEFAULT NULL ); -- used by sqlt$i.xtract

  PROCEDURE delete_sqltxplain_stats;

  FUNCTION dbms_addm_analyze_inst (
    p_dbid     IN NUMBER,
    p_inst_num IN NUMBER,
    p_bid      IN NUMBER,
    p_eid      IN NUMBER )
  RETURN VARCHAR2;

  PROCEDURE disable_diagnostic_pack_access;

  PROCEDURE disable_tuning_pack_access;

  PROCEDURE enable_diagnostic_pack_access;

  PROCEDURE enable_tuning_pack_access;

  PROCEDURE event_10046_10053_off (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE event_10046_10053_on (p_statement_id IN NUMBER);

  PROCEDURE event_10053_off (
    p_statement_id        IN NUMBER,
    p_error               IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE event_10053_on (p_statement_id IN NUMBER);

  PROCEDURE find_sql_in_memory_or_awr (
    p_string                IN     VARCHAR2,
    p_sql_id_or_hash_value  IN     VARCHAR2,
    p_input_filename        IN     VARCHAR2 DEFAULT NULL,
    x_sql_id                IN OUT VARCHAR2,
    x_hash_value            IN OUT NUMBER,
    x_in_memory             IN OUT VARCHAR2,
    x_in_awr                IN OUT VARCHAR2 );

  PROCEDURE generate_10053_xtract (
    p_statement_id        IN NUMBER,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  FUNCTION get_bdump_path
  RETURN VARCHAR2;

  FUNCTION get_bdump_full_path
  RETURN VARCHAR2;

  FUNCTION get_clean_name (p_name IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION get_column_count (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2 )
  RETURN NUMBER;

  FUNCTION get_column_position (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2,
    p_column_name  IN VARCHAR2 )
  RETURN NUMBER;

  FUNCTION get_database_id
  RETURN NUMBER;

  FUNCTION get_database_name
  RETURN VARCHAR2;

  FUNCTION get_database_name_short
  RETURN VARCHAR2;

  FUNCTION get_database_properties (p_name IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION get_dba_object_id (
    p_object_type    IN VARCHAR2,
    p_owner          IN VARCHAR2,
    p_object_name    IN VARCHAR2,
    p_subobject_name IN VARCHAR2 DEFAULT NULL )
  RETURN NUMBER;

  PROCEDURE get_db_links;

  PROCEDURE get_db_links (p_sql_id IN VARCHAR2);

  FUNCTION get_db_link_short (p_db_link IN VARCHAR2)
  RETURN VARCHAR2;

  --  150826 new
  FUNCTION get_diag_path  RETURN VARCHAR2;
  FUNCTION get_diag_full_path  RETURN VARCHAR2;
  
  FUNCTION get_file (
    p_filename      IN VARCHAR2,
    p_statement_id  IN NUMBER DEFAULT NULL,
    p_statement_id2 IN NUMBER DEFAULT NULL )
  RETURN sqli$_file%ROWTYPE;

  FUNCTION get_filename_with_output (
    p_statement_id    IN NUMBER,
    p_script_with_sql IN VARCHAR2 )
  RETURN VARCHAR2;

  FUNCTION get_host_name
  RETURN VARCHAR2;

  FUNCTION get_host_name_short
  RETURN VARCHAR2;

  FUNCTION get_index_column_count (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2 )
  RETURN NUMBER;

  FUNCTION get_index_column_ids (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2,
    p_separator    IN VARCHAR2 DEFAULT ' ',
    p_pad_char     IN VARCHAR2 DEFAULT ' ' )
  RETURN VARCHAR2;

  FUNCTION get_index_column_names (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2,
    p_hidden_names IN VARCHAR2 DEFAULT 'NO',
    p_separator    IN VARCHAR2 DEFAULT ' ',
    p_table_name   IN VARCHAR2 DEFAULT 'NO',
    p_sticky       IN VARCHAR2 DEFAULT 'NO' )
  RETURN VARCHAR2;

  FUNCTION get_policy_column_names (
    p_statement_id IN NUMBER,
    p_object_owner IN VARCHAR2,
    p_object_name  IN VARCHAR2,
    p_policy_name  IN VARCHAR2, 
    p_separator    IN VARCHAR2 DEFAULT ' ')
  RETURN VARCHAR2;  
  
  FUNCTION get_instance_name
  RETURN VARCHAR2;

  FUNCTION get_instance_number
  RETURN NUMBER;

  FUNCTION get_internal_column_id (
    p_owner              IN VARCHAR2,
    p_table_name         IN VARCHAR2,
    p_column_name        IN VARCHAR2,
    p_internal_column_id IN NUMBER )
  RETURN NUMBER;

  FUNCTION get_language
  RETURN VARCHAR2;

  FUNCTION get_met_object_id (
    p_statement_id   IN NUMBER,
    p_object_type    IN VARCHAR2,
    p_owner          IN VARCHAR2,
    p_object_name    IN VARCHAR2 )
  RETURN NUMBER;

  FUNCTION get_numbers_and_letters (p_name IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION get_object_id (
    p_statement_id   IN NUMBER,
    p_object_type    IN VARCHAR2,
    p_owner          IN VARCHAR2,
    p_object_name    IN VARCHAR2,
    p_subobject_name IN VARCHAR2 DEFAULT NULL )
  RETURN NUMBER;
  
  FUNCTION get_owner_id (
    p_statement_id   IN NUMBER,
    p_object_type    IN VARCHAR2,
    p_owner          IN VARCHAR2,
    p_object_name    IN VARCHAR2 )
  RETURN NUMBER;  

  FUNCTION get_pack_access
  RETURN VARCHAR2;

  FUNCTION get_param (p_name IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION get_param_n (p_name IN VARCHAR2)
  RETURN NUMBER;

  FUNCTION get_plan_link (
    p_statement_id    IN NUMBER,
    p_plan_hash_value IN NUMBER )
  RETURN VARCHAR2;

  FUNCTION get_platform
  RETURN VARCHAR2;

  FUNCTION get_product_version
  RETURN VARCHAR2;

  FUNCTION get_rdbms_release
  RETURN NUMBER;

  FUNCTION get_rdbms_version
  RETURN VARCHAR2;

  FUNCTION get_rdbms_version_short
  RETURN VARCHAR2;

  FUNCTION get_sql_id (p_statement_id IN NUMBER)
  RETURN VARCHAR2;

  FUNCTION get_sqlt$_gv$parameter_cbo (
    p_statement_id IN NUMBER,
    p_name         IN VARCHAR2 )
  RETURN sqlt$_gv$parameter_cbo%ROWTYPE;

  FUNCTION get_sid
  RETURN NUMBER;

  FUNCTION get_sqlt_v$session_fix_control (
    p_statement_id IN NUMBER,
    p_bugno        IN NUMBER )
  RETURN NUMBER;

  FUNCTION get_sqlt$_v$parameter2 (
    p_statement_id IN NUMBER,
    p_name         IN VARCHAR2 )
  RETURN VARCHAR2;

  FUNCTION get_stage_full_path
  RETURN VARCHAR2;

  FUNCTION get_stage_path
  RETURN VARCHAR2;

  FUNCTION get_statement (p_statement_id IN NUMBER)
  RETURN sqlt$_sql_statement%ROWTYPE;

  FUNCTION get_statement_id
  RETURN NUMBER;

  FUNCTION get_statement_id_c (p_statement_id IN NUMBER DEFAULT NULL)
  RETURN VARCHAR2;

  FUNCTION get_statid (p_statement_id IN NUMBER)
  RETURN VARCHAR2;

  PROCEDURE get_table (
    p_statement_id IN  NUMBER,
    p_index_owner  IN  VARCHAR2,
    p_index_name   IN  VARCHAR2,
    x_table_owner  OUT VARCHAR2,
    x_table_name   OUT VARCHAR2,
    x_object_id    OUT NUMBER );

  FUNCTION get_udump_full_path
  RETURN VARCHAR2;

  FUNCTION get_udump_path
  RETURN VARCHAR2;

  -- FUNCTION get_user_dump_dest_path
  -- 150826 removed

  FUNCTION get_v$parameter (p_name IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION get_v$parameter_cbo (
    p_name         IN VARCHAR2,
    p_statement_id IN NUMBER )
  RETURN VARCHAR2;

  PROCEDURE import_cbo_stats (
    p_statement_id IN VARCHAR2,
    p_schema_owner IN VARCHAR2,
    p_include_bk   IN VARCHAR2 DEFAULT 'Y',
    p_make_bk      IN VARCHAR2 DEFAULT 'N',
    p_load_hist    IN VARCHAR2 DEFAULT 'N',
    p_table_name   IN VARCHAR2 DEFAULT NULL,
    p_column_name  IN VARCHAR2 DEFAULT NULL );

  PROCEDURE import_cbo_stats_dict_objects (
    p_statement_id IN VARCHAR2,
    p_make_bk      IN VARCHAR2 DEFAULT 'N' );

  PROCEDURE import_cbo_stats_fixed_objects (
    p_statement_id IN VARCHAR2,
    p_make_bk      IN VARCHAR2 DEFAULT 'N' );

  FUNCTION in_multi_column_index (
    p_statement_id IN NUMBER,
    p_table_owner  IN VARCHAR2,
    p_table_name   IN VARCHAR2,
    p_column_name  IN VARCHAR2 )
  RETURN VARCHAR2;

  PROCEDURE ind_cols_sec (
    p_statement_id IN NUMBER,
    p_index_name   IN  VARCHAR2,
    p_owner        IN  VARCHAR2,
    x_vers         OUT NUMBER,
    x_usage        OUT NUMBER,
    x_hgrm         OUT NUMBER,
    x_hgrm_vers    OUT NUMBER,
    x_part         OUT NUMBER,
    x_metadata     OUT NUMBER );

  FUNCTION is_user_in_role (
    p_granted_role IN VARCHAR2,
    p_user         IN VARCHAR2 DEFAULT USER )
  RETURN VARCHAR2;

  FUNCTION mot (
    p_main_text  IN VARCHAR2,
    p_mo_text    IN VARCHAR2,
    p_href       IN VARCHAR2 DEFAULT 'javascript:void(0);',
    p_mo_caption IN VARCHAR2 DEFAULT NULL,
    p_sticky     IN BOOLEAN  DEFAULT FALSE,
    p_nl_class   IN VARCHAR2 DEFAULT 'nl',
    p_target     IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2;

  PROCEDURE print_statement_workspace (p_statement_id IN NUMBER);
  
  PROCEDURE purge_repository (
    p_statement_id_from IN NUMBER,
    p_statement_id_to   IN NUMBER );

  PROCEDURE put_line (p_line_text IN VARCHAR2);

  PROCEDURE remote_event_10046_10053_off (
    p_statement_id           IN  NUMBER,
    p_db_link                IN  VARCHAR2,
    p_10046                  IN  VARCHAR2 DEFAULT 'N',
    p_out_file_identifier    IN  VARCHAR2 DEFAULT NULL,
    x_file_10046_10053_udump OUT VARCHAR2,
    x_file_10046_10053       OUT VARCHAR2 );

  PROCEDURE remote_event_10046_10053_on (
    p_statement_id IN NUMBER,
    p_10046        IN VARCHAR2 DEFAULT 'N' );

  PROCEDURE remote_upload_10046_10053 (
    p_statement_id           IN NUMBER,
    p_db_link                IN VARCHAR2,
    p_file_10046_10053_udump IN VARCHAR2,
    p_file_10046_10053       IN VARCHAR2 );

  FUNCTION remove_piece (
    p_string IN VARCHAR2,
    p_begin  IN VARCHAR2,
    p_end    IN VARCHAR2 )
  RETURN VARCHAR2;

  FUNCTION report_sql_monitor (
    p_sql_id         IN VARCHAR2 DEFAULT NULL,
    p_sql_exec_start IN DATE     DEFAULT NULL,
    p_sql_exec_id    IN NUMBER   DEFAULT NULL,
    p_report_level   IN VARCHAR2 DEFAULT 'BASIC+PARALLEL',
    p_type           IN VARCHAR2 DEFAULT 'TEXT' )
  RETURN CLOB;

  -- 150911 New
  FUNCTION report_hist_sql_monitor (
    p_report_id      IN NUMBER     DEFAULT NULL,
    p_type           IN VARCHAR2 DEFAULT 'TEXT' )
  RETURN CLOB;
  
  -- 160403 New
  FUNCTION report_perfhub (
    p_selected_start_time IN VARCHAR2 DEFAULT NULL,
    p_selected_end_time   IN VARCHAR2 DEFAULT NULL,
	p_date_fmt            IN VARCHAR2 DEFAULT 'YYYY-MM-DD/HH24:MI:SS',
    p_dbid                IN NUMBER DEFAULT NULL,
	p_inst_id             IN NUMBER DEFAULT NULL,
	p_report_type         IN VARCHAR2 DEFAULT 'TYPICAL'
  )
  RETURN CLOB;
  
  /* to be included from DBMS_PERF
  FUNCTION report_sql(
   p_sql_id               IN varchar2 default null,
   p_is_realtime          IN number   default null,
   p_outer_start_time     IN date     default null,
   p_outer_end_time       IN date     default null,
   p_selected_start_time  IN date     default null,
   p_selected_end_time    IN date     default null,
   p_inst_id              IN number   default null,
   p_dbid                 IN number   default null,
   p_monitor_list_detail  IN number   default null,
   p_report_reference     IN varchar2 default null,
   p_report_level         IN varchar2 default null,
   p_type                 IN varchar2 default 'ACTIVE',
   p_base_path            IN varchar2 default null)
  RETURN clob;
  */
  
  PROCEDURE reset_directories;

  PROCEDURE reset_init_parameters (p_statement_id IN NUMBER);

  PROCEDURE restore_init_parameters;

  FUNCTION session_trace_filename (
    p_traceid      IN VARCHAR2 DEFAULT NULL,
    p_spid         IN VARCHAR2 DEFAULT NULL,
    p_process_name IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2;

  -- 150824 new
  FUNCTION s_db_link RETURN sys.all_db_links.db_link%TYPE;
  
  PROCEDURE set_stand_by_dblink (p_stand_by_dblink IN VARCHAR2 DEFAULT NULL);

  PROCEDURE set_end_date (p_statement_id IN NUMBER);

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
    p_file_text     IN CLOB     DEFAULT EMPTY_CLOB() );

  PROCEDURE set_index_column_names (
    p_statement_id IN NUMBER,
    p_index_owner  IN VARCHAR2,
    p_index_name   IN VARCHAR2,
    p_hidden_names IN VARCHAR2 DEFAULT 'NO',
    p_separator    IN VARCHAR2 DEFAULT ' ',
    p_table_name   IN VARCHAR2 DEFAULT 'NO' );

  PROCEDURE set_input_filename (
    p_statement_id   IN NUMBER,
    p_input_filename IN VARCHAR2 );

  PROCEDURE set_method (p_method IN VARCHAR2 DEFAULT NULL);

  PROCEDURE set_module (
    p_module_name IN VARCHAR2 DEFAULT NULL,
    p_action_name IN VARCHAR2 DEFAULT NULL );

  PROCEDURE set_param (
    p_name  IN VARCHAR2,
    p_value IN VARCHAR2 );

  PROCEDURE set_sess_param (
    p_name  IN VARCHAR2,
    p_value IN VARCHAR2 );

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
    x_metadata     OUT NUMBER );

  PROCEDURE trace_off;

  PROCEDURE trace_on (p_statement_id IN NUMBER);

  PROCEDURE upload_10046_10053_trace (p_statement_id IN NUMBER);

  PROCEDURE upload_10053_trace (p_statement_id IN NUMBER);

  PROCEDURE upload_10053_xtract (p_statement_id IN NUMBER);

  PROCEDURE upload_sta_files (
    p_statement_id        IN NUMBER,
    p_report_mem          IN CLOB,
    p_script_mem          IN CLOB,
    p_report_txt          IN CLOB,
    p_script_txt          IN CLOB,
    p_report_awr          IN CLOB,
    p_script_awr          IN CLOB,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE upload_trca_files (
    p_statement_id        IN NUMBER,
    p_execution_id        IN NUMBER,
    p_file_10046_10053    IN VARCHAR2,
    p_trca_html_report    IN CLOB,
    p_trca_text_report    IN CLOB,
    p_trca_log            IN CLOB,
    p_trca_10046_trace    IN CLOB,
    p_trca_10053_trace    IN CLOB,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  PROCEDURE upload_trca_files_px (
    p_statement_id        IN NUMBER,
    p_execution_id        IN NUMBER,
    p_trca_html_report    IN CLOB,
    p_trca_text_report    IN CLOB,
    p_trca_log            IN CLOB,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  FUNCTION validate_db_link(p_dblink sys.all_db_links.db_link%TYPE) return sys.all_db_links.db_link%TYPE ;
	
  PROCEDURE validate_user (p_user IN VARCHAR2 DEFAULT USER);

  PROCEDURE validate_tool_version (p_script_version IN VARCHAR2);

  PROCEDURE write_log (
    p_line_text IN VARCHAR2,
    p_line_type IN VARCHAR2 DEFAULT 'L', -- (L)og/(S)ilent/(E)rror/(P)rint
    p_package   IN VARCHAR2 DEFAULT 'A' );

  PROCEDURE write_error (p_line_text IN VARCHAR2);

  PROCEDURE xtrsby_initialization;

  /*************************************************************************************/

END sqlt$a;
/

SET TERM ON;
SHOW ERRORS PACKAGE &&tool_administer_schema..sqlt$a;
