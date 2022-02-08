CREATE OR REPLACE PACKAGE &&tool_administer_schema..sqlt$t AUTHID DEFINER AS
/* $Header: 215187.1 sqcpkgt.pks 12.1.10 2014/08/08 carlos.sierra mauro.pagano $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * public apis
   *
   * ------------------------- */

  PROCEDURE best_and_worst_plans (p_statement_id IN NUMBER);

  PROCEDURE binds_in_predicates (p_statement_id IN NUMBER);

  PROCEDURE build_plan_more_html_table (p_statement_id IN NUMBER);

  PROCEDURE column_in_predicates (p_statement_id IN NUMBER);

  PROCEDURE column_in_projection (p_statement_id IN NUMBER);

  FUNCTION compute_enpoint_value (
    p_data_type             IN VARCHAR2,  -- dba_tab_cols.data_type
    p_endpoint_value        IN NUMBER,    -- dba_tab_histograms.endpoint_value
    p_endpoint_actual_value IN VARCHAR2 ) -- dba_tab_histograms.endpoint_actual_value
  RETURN VARCHAR2;                        -- endpoint_estimated_value

  FUNCTION cook_raw (
    p_raw       IN RAW,
    p_data_type IN VARCHAR2 )
  RETURN VARCHAR2;

  FUNCTION difference_percent (
    p_value1   IN NUMBER,
    p_value2   IN NUMBER,
    p_decimals IN NUMBER DEFAULT 1 )
  RETURN NUMBER;

  FUNCTION differ_more_than_x_perc (
    p_value1  IN NUMBER,
    p_value2  IN NUMBER,
    p_percent IN NUMBER DEFAULT 10 )
  RETURN BOOLEAN;

  FUNCTION differ_more_than_x_percent (
    p_value1  IN NUMBER,
    p_value2  IN NUMBER,
    p_percent IN NUMBER DEFAULT 10 )
  RETURN VARCHAR2;

  PROCEDURE extend_dba_hist_sqlbind (p_statement_id IN NUMBER);

  PROCEDURE extend_gv$sql_bind_capture (p_statement_id IN NUMBER);

  PROCEDURE extend_gv$sql_optimizer_env (p_statement_id IN NUMBER);

  PROCEDURE extend_peeked_binds (p_statement_id IN NUMBER);

  PROCEDURE flag_dba_hist_sqlstat (p_statement_id IN NUMBER);

  PROCEDURE perm_transformation (p_statement_id IN NUMBER);

  PROCEDURE plan_operation (p_statement_id IN NUMBER);

  PROCEDURE process_other_xml (p_statement_id IN NUMBER);

  PROCEDURE sanitize_other_xml (p_statement_id IN NUMBER);

  PROCEDURE seeds_child_address (p_statement_id IN NUMBER);

  PROCEDURE sqlt_plan_hash_value (p_statement_id IN NUMBER);

  PROCEDURE temp_transformation (p_statement_id IN NUMBER);

  PROCEDURE top_cost (p_statement_id IN NUMBER);

  /*************************************************************************************/

END sqlt$t;
/

SET TERM ON;
SHOW ERRORS PACKAGE &&tool_administer_schema..sqlt$t;
