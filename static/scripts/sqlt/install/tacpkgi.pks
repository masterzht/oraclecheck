CREATE OR REPLACE PACKAGE &&tool_administer_schema..trca$i AUTHID CURRENT_USER AS
/* $Header: 224270.1 tacpkgi.pks 11.4.5.0 2012/11/21 carlos.sierra $ */

  /* -------------------------
   *
   * public second_transformation
   *
   * ------------------------- */
  PROCEDURE second_transformation (
    p_tool_execution_id IN INTEGER );

  /* -------------------------
   *
   * public fourth_transformation
   *
   * ------------------------- */
  PROCEDURE fourth_transformation (
    p_tool_execution_id IN INTEGER );

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
    p_out_file_identifier  IN     VARCHAR2 DEFAULT NULL ); -- trca$i.trcanlzr_remote, trca$i.trcanlzr

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
    p_out_file_identifier  IN VARCHAR2 DEFAULT NULL );

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
    x_tool_execution_id   IN OUT INTEGER );

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
    x_hash_values       OUT VARCHAR2 );

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
  RETURN VARCHAR2;

END trca$i;
/

SET TERM ON;
SHOW ERRORS;
