CREATE OR REPLACE PACKAGE &&tool_administer_schema..sqlt$m AUTHID DEFINER AS
/* $Header: 215187.1 sqcpkgm.pks 12.1.10 2014/08/08 carlos.sierra mauro.pagano $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * public apis
   *
   * ------------------------- */

  PROCEDURE main_report_root (
    p_statement_id        IN NUMBER,
    p_group_id            IN NUMBER   DEFAULT NULL,
    p_db_link             IN VARCHAR2 DEFAULT NULL,
    p_file_prefix         IN VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN VARCHAR2 DEFAULT NULL );

  /*************************************************************************************/

END sqlt$m;
/

SET TERM ON;
SHOW ERRORS PACKAGE &&tool_administer_schema..sqlt$m;
