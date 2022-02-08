CREATE OR REPLACE PACKAGE &&tool_administer_schema..trca$g AUTHID DEFINER AS
/* $Header: 224270.1 tacpkgg.pks 11.4.5.0 2012/11/21 carlos.sierra $ */

  /* -------------------------
   *
   * public types
   *
   * ------------------------- */
  TYPE varchar2_table IS TABLE OF VARCHAR2(2000);

  /* -------------------------
   *
   * public constants
   *
   * ------------------------- */
  -- call enumerator
  CALL_BINDS           CONSTANT CHAR(1) :=  '0'; -- not a real call
  CALL_PARSE           CONSTANT CHAR(1) :=  '1';
  CALL_EXEC            CONSTANT CHAR(1) :=  '2';
  CALL_UNMAP           CONSTANT CHAR(1) :=  '3';
  CALL_SORT_UNMAP      CONSTANT CHAR(1) :=  '4';
  CALL_FETCH           CONSTANT CHAR(1) :=  '5';
  CALL_TOTAL           CONSTANT CHAR(1) :=  '9';

  -- time factor to seconds (time is reported in microseconds)
  TIM_FACTOR           CONSTANT INTEGER := 1000000; -- 9i, 10g, 11g

  /* -------------------------
   *
   * public global variables
   *
   * ------------------------- */
  -- hidden, non-user-updateable, for internal use

  g_tool_administer_schema    VARCHAR2(128) := NULL;
  g_tool_name                 VARCHAR2(128) := NULL;
  g_tool_version              VARCHAR2(128) := NULL;
  g_install_date              VARCHAR2(128) := NULL;
  g_interop_version           VARCHAR2(128) := NULL;

  -- hidden, non-user-updateable, shown in tool data dictionary section
  g_dict_refresh_date         VARCHAR2(128) := NULL;
  g_dict_refresh_days         VARCHAR2(128) := NULL;
  g_dict_database_id          VARCHAR2(128) := NULL;
  g_dict_database_name        VARCHAR2(128) := NULL;
  g_dict_instance_id          VARCHAR2(128) := NULL;
  g_dict_instance_name        VARCHAR2(128) := NULL;
  g_dict_host_name            VARCHAR2(128) := NULL;
  g_dict_platform             VARCHAR2(128) := NULL;
  g_dict_rdbms_version        VARCHAR2(128) := NULL;
  g_dict_db_files             VARCHAR2(128) := NULL;

  -- hidden, non-user-updateable, shown in tool execution environment section
  g_tool_database_id          VARCHAR2(128) := NULL;
  g_tool_database_name        VARCHAR2(128) := NULL;
  g_tool_instance_id          VARCHAR2(128) := NULL;
  g_tool_instance_name        VARCHAR2(128) := NULL;
  g_tool_host_name            VARCHAR2(128) := NULL;
  g_tool_platform             VARCHAR2(128) := NULL;
  g_tool_rdbms_version        VARCHAR2(128) := NULL;
  g_tool_rdbms_version_short  VARCHAR2(128) := NULL;
  g_tool_rdbms_release        VARCHAR2(128) := NULL;
  g_tool_product_version      VARCHAR2(128) := NULL;
  g_tool_db_files             VARCHAR2(128) := NULL;

  -- not stored
  g_log                       SYS.UTL_FILE.FILE_TYPE; -- file handler for log
  g_log_open                  BOOLEAN       := FALSE;
  g_open_mode                 VARCHAR2(128) := NULL;
  g_udump                     VARCHAR2(128) := NULL;
  g_bdump                     VARCHAR2(128) := NULL;
  g_time                      VARCHAR2(128) := NULL;
  g_sqlid                     VARCHAR2(128) := NULL;
  g_plh                       VARCHAR2(128) := NULL;
  g_card                      VARCHAR2(128) := NULL;
  g_dir_path_dep_sep          VARCHAR2(128) := NULL; -- set by trca$p.parse_main
  g_path_and_filename         VARCHAR2(640) := NULL; -- set by trca$p.parse_main

  -- visible, user-updateable, shown in tool config section
  g_top_sql_th                VARCHAR2(128) := NULL;
  g_top_exec_th               VARCHAR2(128) := NULL;
  g_hot_block_th              VARCHAR2(128) := NULL;
  g_aggregate                 VARCHAR2(128) := NULL;
  g_perform_count_star        VARCHAR2(128) := NULL;
  g_count_star_th             VARCHAR2(128) := NULL; 
  g_errors_th                 VARCHAR2(128) := NULL;
  g_gaps_th                   VARCHAR2(128) := NULL;
  g_include_internal_sql      VARCHAR2(128) := NULL;
  g_include_non_top_sql       VARCHAR2(128) := NULL;
  g_include_init_ora          VARCHAR2(128) := NULL;
  g_include_waits             VARCHAR2(128) := NULL;
  g_include_binds             VARCHAR2(128) := NULL;
  g_include_fetches           VARCHAR2(128) := NULL;
  g_include_expl_plans        VARCHAR2(128) := NULL;
  g_include_segments          VARCHAR2(128) := NULL;
  g_detail_non_top_sql        VARCHAR2(128) := NULL;
  g_time_granularity          VARCHAR2(128) := NULL;
  g_wait_time_th              VARCHAR2(128) := NULL;
  g_response_time_th          VARCHAR2(128) := NULL;
  g_trace_file_max_size_bytes VARCHAR2(128) := NULL;
  g_copy_file_max_size_bytes  VARCHAR2(128) := NULL;
  g_gen_html_report           VARCHAR2(128) := NULL;
  g_gen_text_report           VARCHAR2(128) := NULL;
  g_split_10046_10053_trc     VARCHAR2(128) := NULL;
  g_gather_cbo_stats          VARCHAR2(128) := NULL;
  g_capture_extents           VARCHAR2(128) := NULL;
  g_refresh_dict_repository   VARCHAR2(128) := NULL;

  -- visible, non-user-updateable, shown in tool config section
  g_input1_dir                VARCHAR2(128) := NULL;
  g_input2_dir                VARCHAR2(128) := NULL;
  g_stage_dir                 VARCHAR2(128) := NULL;
  g_input1_directory          VARCHAR2(512) := NULL;
  g_input2_directory          VARCHAR2(512) := NULL;
  g_stage_directory           VARCHAR2(512) := NULL;

  /*************************************************************************************/

  /* -------------------------
   *
   * public g_tool_repository_schema
   *
   * called by trca$i.trcanlzr
   *
   * ------------------------- */
  
  FUNCTION g_tool_repository_schema 
    RETURN VARCHAR2;
  
  /* -------------------------
   *
   * public validate_user
   *
   * called by trca$i.trcanlzr
   *
   * ------------------------- */
  PROCEDURE validate_user (p_user IN VARCHAR2 DEFAULT USER);

  /* -------------------------
   *
   * public call_type_binds
   *
   * ------------------------- */
  FUNCTION call_type_binds
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public call_type_parse
   *
   * ------------------------- */
  FUNCTION call_type_parse
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public call_type_exec
   *
   * ------------------------- */
  FUNCTION call_type_exec
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public call_type_unmap
   *
   * ------------------------- */
  FUNCTION call_type_unmap
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public call_type_sort_unmap
   *
   * ------------------------- */
  FUNCTION call_type_sort_unmap
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public call_type_fetch
   *
   * ------------------------- */
  FUNCTION call_type_fetch
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public call_type_total
   *
   * ------------------------- */
  FUNCTION call_type_total
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public call_type
   *
   * ------------------------- */
  FUNCTION call_type (
    p_call IN VARCHAR2 )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public get_directory_path
   *
   * ------------------------- */
  FUNCTION get_directory_path (
    p_directory_name IN VARCHAR2 )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public get_1st_trace_path_n_name
   *
   * ------------------------- */
  FUNCTION get_1st_trace_path_n_name
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public reset_session_longops
   *
   * ------------------------- */
  PROCEDURE reset_session_longops;

  /* -------------------------
   *
   * public set_session_longops
   *
   * ------------------------- */
  PROCEDURE set_session_longops (
    p_op_name     IN VARCHAR2       DEFAULT NULL,
    p_target      IN BINARY_INTEGER DEFAULT 0,
    p_sofar       IN NUMBER         DEFAULT 0,
    p_totalwork   IN NUMBER         DEFAULT 0,
    p_target_desc IN VARCHAR2       DEFAULT 'unknown target',
    p_units       IN VARCHAR2       DEFAULT NULL );

  /* -------------------------
   *
   * public set_module
   *
   * ------------------------- */
  PROCEDURE set_module (
    p_module_name IN VARCHAR2 DEFAULT NULL,
    p_action_name IN VARCHAR2 DEFAULT NULL );

  /* -------------------------
   *
   * public print_log
   *
   * ------------------------- */
  PROCEDURE print_log (
    p_buffer    IN VARCHAR2,
    p_package   IN VARCHAR2 DEFAULT 'G',
    p_timestamp IN VARCHAR2 DEFAULT 'Y');

  /* -------------------------
   *
   * public open_log
   *
   * called by trca$i.trcanlzr
   *
   * ------------------------- */
  PROCEDURE open_log (
    p_tool_execution_id   IN INTEGER,
    p_file_name           IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  /* -------------------------
   *
   * public close_log
   *
   * ------------------------- */
  PROCEDURE close_log (
    p_tool_execution_id IN  INTEGER,
    x_log               OUT CLOB );

  /* -------------------------
   *
   * public gather_table_stats
   *
   * ------------------------- */
  PROCEDURE gather_table_stats (
    p_table_name IN VARCHAR2 );

  /* -------------------------
   *
   * public format_tim3
   *
   * ------------------------- */
  FUNCTION format_tim3 (
    p_tim IN INTEGER )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public format_tim6
   *
   * ------------------------- */
  FUNCTION format_tim6 (
    p_tim IN INTEGER )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public format_perc1
   *
   * ------------------------- */
  FUNCTION format_perc1 (
    p_one IN NUMBER,
    p_two IN NUMBER )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public format_perc1
   *
   * ------------------------- */
  FUNCTION format_perc1 (
    p_one IN NUMBER )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public to_timestamp
   *
   * ------------------------- */
  FUNCTION to_timestamp (
    p_tool_execution_id IN INTEGER,
    p_tim               IN INTEGER )
  RETURN TIMESTAMP;

  /* -------------------------
   *
   * public format_timestamp3
   *
   * ------------------------- */
  FUNCTION format_timestamp3 (
    p_timestamp IN TIMESTAMP )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public format_timestamp3h
   *
   * ------------------------- */
  FUNCTION format_timestamp3h (
    p_timestamp IN TIMESTAMP )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public format_timestamp3m
   *
   * ------------------------- */
  FUNCTION format_timestamp3m (
    p_timestamp IN TIMESTAMP )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public flatten_text
   *
   * ------------------------- */
  FUNCTION flatten_text (
    p_text IN VARCHAR2 )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public prepare_html_text
   *
   * ------------------------- */
  FUNCTION prepare_html_text (
    p_text IN VARCHAR2 )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public wrap_text
   *
   * ------------------------- */
  FUNCTION wrap_text (
    p_clob         IN CLOB,
    p_max_line_len IN INTEGER  DEFAULT 250,
    p_add_br       IN VARCHAR2 DEFAULT 'N',
    p_lt_gt_quote  IN VARCHAR2 DEFAULT 'N' )
  RETURN CLOB;

  /* -------------------------
   *
   * public wrap_clob
   *
   * returns a clob file regulating its width to a desired value
   * so it can be used by utl_file or to display width-controlled html.
   *
   * ------------------------- */
  FUNCTION wrap_clob (
    p_clob          IN CLOB,
    p_max_line_size IN INTEGER DEFAULT 80 )
  RETURN CLOB;

  /* -------------------------
   *
   * public get_file_from_repo
   *
   * ------------------------- */
  FUNCTION get_file_from_repo (
    p_tool_execution_id IN INTEGER,
    p_file_type         IN VARCHAR2 ) -- HTML, TEXT, LOG, 10053, 10046
  RETURN trca$_file%ROWTYPE;

  /* -------------------------
   *
   * public display_file
   *
   * outputs content of file using pipe
   *
   * ------------------------- */
  FUNCTION display_file (
    p_tool_execution_id IN INTEGER,
    p_file_type         IN VARCHAR2, -- HTML, TEXT, LOG, 10053, 10046
    p_max_line_size     IN INTEGER DEFAULT 2000 )
  RETURN varchar2_table PIPELINED;

  /* -------------------------
   *
   * public utl_file
   *
   * called by: trca$e.copy_file_from_repo_to_dir and trca$e.copy_files_from_repo_to_dir
   *
   * creates file in OS directory out of a CLOB file
   *
   * ------------------------- */
  PROCEDURE utl_file (
    p_tool_execution_id IN INTEGER,
    p_file_type         IN VARCHAR2, -- HTML, TEXT, LOG, 10053, 10046
    p_directory_name    IN VARCHAR2 DEFAULT 'TRCA$STAGE' );

  /* -------------------------
   *
   * public get_param
   *
   * ------------------------- */
  FUNCTION get_param (
    p_name   IN VARCHAR2,
    p_source IN VARCHAR2 DEFAULT 'U' ) -- (U)ser, (I)nternal
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public set_param
   *
   * ------------------------- */
  PROCEDURE set_param (
    p_name   IN VARCHAR2,
    p_value  IN VARCHAR2,
    p_source IN VARCHAR2 DEFAULT 'U' ); -- (U)ser, (I)nternal

  /* -------------------------
   *
   * public directories
   *
   * ------------------------- */
  FUNCTION directories
  RETURN varchar2_table PIPELINED;

  /* -------------------------
   *
   * public packages
   *
   * ------------------------- */
  FUNCTION packages
  RETURN varchar2_table PIPELINED;

  /* -------------------------
   *
   * public tool_parameters
   *
   * ------------------------- */
  FUNCTION tool_parameters (
    p_hidden          IN VARCHAR2 DEFAULT 'N',
    p_user_updateable IN VARCHAR2 DEFAULT 'N',
    p_description     IN VARCHAR2 DEFAULT 'Y',
    p_name            IN VARCHAR2 DEFAULT 'Y',
    p_value_type      IN VARCHAR2 DEFAULT 'N',
    p_value           IN VARCHAR2 DEFAULT 'Y',
    p_default_value   IN VARCHAR2 DEFAULT 'Y',
    p_instructions    IN VARCHAR2 DEFAULT 'Y' )
  RETURN varchar2_table PIPELINED;

  /* -------------------------
   *
   * public get_dict_params
   *
   * ------------------------- */
  PROCEDURE get_dict_params;

  /* -------------------------
   *
   * public general_initialization
   *
   * ------------------------- */
  PROCEDURE general_initialization (
    p_force IN BOOLEAN DEFAULT FALSE );

END trca$g;
/

SET TERM ON;
SHOW ERRORS;
