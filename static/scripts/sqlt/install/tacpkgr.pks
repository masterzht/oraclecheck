CREATE OR REPLACE PACKAGE &&tool_administer_schema..trca$r AUTHID DEFINER AS
/* $Header: 224270.1 tacpkgr.pks 11.4.5.0 2012/11/21 carlos.sierra $ */

  /* -------------------------
   *
   * public gen_html_report
   *
   * called by trca$i.trcanlzr
   *
   * ------------------------- */
  PROCEDURE gen_html_report (
    p_tool_execution_id   IN  INTEGER,
    p_file_name           IN  VARCHAR2 DEFAULT NULL,
    p_out_file_identifier IN  VARCHAR2 DEFAULT NULL,
    x_html_report         OUT CLOB );

END trca$r;
/

SET TERM ON;
SHOW ERRORS;
