CREATE OR REPLACE PACKAGE &&tool_administer_schema..sqlt$h AUTHID DEFINER AS
/* $Header: 215187.1 sqcpkgh.pks 12.1.10 2014/08/08 carlos.sierra mauro.pagano $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * public apis
   *
   * ------------------------- */

  PROCEDURE health_check (p_statement_id IN NUMBER);

  /*************************************************************************************/

END sqlt$h;
/

SET TERM ON;
SHOW ERRORS PACKAGE &&tool_administer_schema..sqlt$h;
