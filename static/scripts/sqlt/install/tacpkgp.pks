CREATE OR REPLACE PACKAGE &&tool_administer_schema..trca$p AUTHID DEFINER AS
/* $Header: 224270.1 tacpkgp.pks 11.4.5.0 2012/11/21 carlos.sierra $ */

  /* -------------------------
   *
   * public set_nls
   *
   * ------------------------- */
  PROCEDURE set_nls;

  /* -------------------------
   *
   * public purge_tool_execution_id
   *
   * ------------------------- */
  PROCEDURE purge_tool_execution_id (
    p_tool_execution_id IN INTEGER );

  /* -------------------------
   *
   * public get_tool_execution_id
   *
   * ------------------------- */
  FUNCTION get_tool_execution_id
  RETURN INTEGER;

  /* -------------------------
   *
   * public parse_main
   *
   * called by trca$i.trcanlzr
   *
   * determines if file passed is
   * a trace file or a control file with a
   * list of trace files in it.
   *
   * it then calls parse_file once for each
   * file to be parsed.
   *
   * ------------------------- */
  PROCEDURE parse_main (
    p_file_name            IN  VARCHAR2,
    p_tool_execution_id    IN  INTEGER,
    p_directory_alias_in   IN  VARCHAR2 DEFAULT NULL,
    p_analyze              IN  VARCHAR2 DEFAULT 'YES',
    p_split                IN  VARCHAR2 DEFAULT 'NO',
    p_split_10046_filename IN  VARCHAR2 DEFAULT NULL,
    p_split_10053_filename IN  VARCHAR2 DEFAULT NULL,
    x_10046_trace          OUT CLOB,
    x_10053_trace          OUT CLOB );

END trca$p;
/

SET TERM ON;
SHOW ERRORS;
