CREATE OR REPLACE PACKAGE &&tool_administer_schema..sqlt$i AUTHID CURRENT_USER AS
/* $Header: 215187.1 sqcpkgi.pks 12.1.10 2014/08/08 carlos.sierra mauro.pagano $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * public apis
   *
   * ------------------------- */

  PROCEDURE register_db_link (p_db_link IN VARCHAR2);

  PROCEDURE remote_event_10046_10053_off (
    p_statement_id           IN  NUMBER,
    p_db_link                IN  VARCHAR2,
    p_10046                  IN  VARCHAR2 DEFAULT 'N',
    x_file_10046_10053_udump OUT VARCHAR2,
    x_file_10046_10053       OUT VARCHAR2 );

  PROCEDURE remote_event_10046_10053_on (
    p_statement_id IN NUMBER,
    p_10046        IN VARCHAR2 DEFAULT 'N' );

  PROCEDURE remote_call_trace_analyzer (
    p_statement_id           IN  NUMBER,
    p_db_link                IN  VARCHAR2,
    p_file_10046_10053_udump IN  VARCHAR2,
    p_file_10046_10053       IN  VARCHAR2,
    p_out_file_identifier    IN VARCHAR2 DEFAULT NULL );

  PROCEDURE remote_xtract (
    p_group_id             IN NUMBER, -- statement_id from source (caller)
    p_db_link              IN VARCHAR2,
    p_file_prefix          IN VARCHAR2,
    p_sql_id_or_hash_value IN VARCHAR2 );

  PROCEDURE reset_object_creation_date (
    p_statement_id IN VARCHAR2,
    p_schema_owner IN VARCHAR2 );

  PROCEDURE unregister_db_link (p_db_link IN VARCHAR2);

  PROCEDURE xecute_begin (p_statement_id IN NUMBER);

  PROCEDURE xecute_end (
    p_statement_id   IN NUMBER,
    p_string         IN VARCHAR2,
    p_sql_id         IN VARCHAR2,
    p_child_number   IN VARCHAR2,
    p_input_filename IN VARCHAR2,
    p_password       IN VARCHAR2 DEFAULT 'N' );

  PROCEDURE xplain_begin (p_statement_id IN NUMBER);

  PROCEDURE xplain_end (
    p_statement_id   IN NUMBER,
    p_string         IN VARCHAR2,
    p_sql_id         IN VARCHAR2,
    p_input_filename IN VARCHAR2,
    p_password       IN VARCHAR2 DEFAULT 'N' );

  PROCEDURE xtract (
    p_statement_id         IN NUMBER,
    p_sql_id_or_hash_value IN VARCHAR2,
    p_out_file_identifier  IN VARCHAR2 DEFAULT NULL, -- used by xtract_and_trap_error
    p_tcb_directory_name   IN VARCHAR2 DEFAULT 'SQLT$STAGE', -- used by xtract_and_trap_error
    p_statement_set_id     IN NUMBER   DEFAULT NULL,  -- used by sqltxtrone.sql
    p_password             IN VARCHAR2 DEFAULT 'N' );

  PROCEDURE xtract_and_trap_error (
    p_statement_id         IN NUMBER,
    p_sql_id_or_hash_value IN VARCHAR2,
    p_out_file_identifier  IN VARCHAR2 DEFAULT NULL,
    p_tcb_directory_name   IN VARCHAR2 DEFAULT 'SQLT$STAGE' );

  PROCEDURE xtrsby (
    p_statement_id         IN NUMBER,
    p_sql_id_or_hash_value IN VARCHAR2,
    p_stand_by_dblink      IN VARCHAR2,
    p_password             IN VARCHAR2 DEFAULT 'N' );

  /*************************************************************************************/

END sqlt$i;
/

SET TERM ON;
SHOW ERRORS PACKAGE &&tool_administer_schema..sqlt$i;
