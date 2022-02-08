CREATE OR REPLACE PACKAGE &&tool_administer_schema..trca$t AUTHID DEFINER AS
/* $Header: 224270.1 tacpkgt.pks 11.4.5.0 2012/11/21 carlos.sierra $ */

  /* -------------------------
   *
   * public purge_trca$_dict
   *
   * purges tool data dictionary
   *
   * ------------------------- */
  PROCEDURE purge_trca$_dict;

  /* -------------------------
   *
   * public refresh_trca$_dict_from_this
   *
   * refreshes tool data dictionary from this (internal) system
   *
   * ------------------------- */
  PROCEDURE refresh_trca$_dict_from_this;

  /* -------------------------
   *
   * public refresh_trca$_dict_from_that
   *
   * refreshes tool data dictionary from that (external) system
   *
   * ------------------------- */
  PROCEDURE refresh_trca$_dict_from_that;

  /* -------------------------
   *
   * public extract_table_name
   *
   * ------------------------- */
  FUNCTION extract_table_name (
    p_operation IN VARCHAR2 )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public extract_index_name
   *
   * ------------------------- */
  FUNCTION extract_index_name (
    p_operation IN VARCHAR2 )
  RETURN VARCHAR2;

  /* -------------------------
   *
   * public first_transformation
   *
   * ------------------------- */
  PROCEDURE first_transformation (
    p_tool_execution_id IN  INTEGER );

  /* -------------------------
   *
   * public third_transformation
   *
   * ------------------------- */
  PROCEDURE third_transformation (
    p_tool_execution_id IN INTEGER );

END trca$t;
/

SET TERM ON;
SHOW ERRORS;
