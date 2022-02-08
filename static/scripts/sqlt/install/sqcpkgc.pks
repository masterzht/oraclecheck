CREATE OR REPLACE PACKAGE &&tool_administer_schema..sqlt$c AUTHID DEFINER AS
/* $Header: 215187.1 sqcpkgc.pks 12.1.10 2014/08/08 carlos.sierra mauro.pagano $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * public apis
   *
   * ------------------------- */

  PROCEDURE compare_report (
    p_statement_id1    IN NUMBER,
    p_statement_id2    IN NUMBER,
    p_plan_hash_value1 IN NUMBER,
    p_plan_hash_value2 IN NUMBER );

  /*************************************************************************************/

END sqlt$c;
/

SET TERM ON;
SHOW ERRORS PACKAGE &&tool_administer_schema..sqlt$c;
