CREATE OR REPLACE PACKAGE &&tool_administer_schema..sqlt$s AUTHID DEFINER AS
/* $Header: 215187.1 sqcpkgs.pks 12.1.10 2014/08/08 carlos.sierra mauro.pagano $ */

  /*************************************************************************************/

  FUNCTION clean_object_name (p_object_name IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION convert_raw_value (
    p_raw       IN RAW,
    p_data_type IN VARCHAR2 )
  RETURN VARCHAR2;

  PROCEDURE delete_column_hgrm (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_cascade_parts IN BOOLEAN  DEFAULT TRUE,
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE );

  PROCEDURE delete_hgrm_bucket (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_end_point     IN INTEGER,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_preserve_size IN BOOLEAN  DEFAULT TRUE, -- of subsequent buckets
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE );

  PROCEDURE delete_schema_hgrm (
    p_ownname       IN VARCHAR2,
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE );

  PROCEDURE delete_table_hgrm (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_cascade_parts IN BOOLEAN  DEFAULT TRUE,
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE );

  FUNCTION display_column_stats (
    p_ownname  IN VARCHAR2,
    p_tabname  IN VARCHAR2,
    p_colname  IN VARCHAR2,
    p_partname IN VARCHAR2 DEFAULT NULL )
  RETURN SYS.DBMS_DEBUG_VC2COLL PIPELINED;

  FUNCTION get_bucket_size (
    p_ownname   IN VARCHAR2,
    p_tabname   IN VARCHAR2,
    p_colname   IN VARCHAR2,
    p_end_point IN INTEGER,
    p_partname  IN VARCHAR2 DEFAULT NULL )
  RETURN INTEGER;

  FUNCTION get_data_format (
    p_ownname IN VARCHAR2,
    p_tabname IN VARCHAR2,
    p_colname IN VARCHAR2 )
  RETURN VARCHAR2;

  FUNCTION get_enpoint_value (
    p_data_type             IN VARCHAR2,  -- dba_tab_cols.data_type
    p_endpoint_value        IN NUMBER,    -- dba_tab_histograms.endpoint_value
    p_endpoint_actual_value IN VARCHAR2 ) -- dba_tab_histograms.endpoint_actual_value
  RETURN VARCHAR2;                        -- endpoint_estimated_value

  FUNCTION get_external_value (p_value IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION get_internal_value (p_value IN VARCHAR2)
  RETURN VARCHAR2;

  FUNCTION get_max_value (
    p_ownname  IN VARCHAR2,
    p_tabname  IN VARCHAR2,
    p_colname  IN VARCHAR2,
    p_partname IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2;

  FUNCTION get_min_value (
    p_ownname  IN VARCHAR2,
    p_tabname  IN VARCHAR2,
    p_colname  IN VARCHAR2,
    p_partname IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2;

  PROCEDURE insert_hgrm_bucket (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_end_point     IN INTEGER,
    p_bkvals        IN INTEGER,
    p_novals        IN INTEGER,
    p_chvals        IN VARCHAR2 DEFAULT NULL,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_preserve_size IN BOOLEAN  DEFAULT TRUE, -- of subsequent buckets
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE );

  PROCEDURE insert_hgrm_bucket (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_value         IN VARCHAR2, -- if date use YYYY/MM/DD HH24:MI:SS
    p_size          IN INTEGER,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_preserve_size IN BOOLEAN  DEFAULT TRUE, -- of subsequent buckets
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE );

  PROCEDURE set_bucket_size (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_end_point     IN INTEGER,
    p_new_size      IN INTEGER,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_preserve_size IN BOOLEAN  DEFAULT TRUE, -- of subsequent buckets
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE );

  PROCEDURE set_column_hgrm (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_value_1       IN VARCHAR2, -- if date use YYYY/MM/DD HH24:MI:SS
    p_size_1        IN INTEGER,
    p_value_2       IN VARCHAR2, -- larger than p_value_1
    p_size_2        IN INTEGER,
    p_value_3       IN VARCHAR2 DEFAULT NULL, -- larger than p_value_2
    p_size_3        IN INTEGER  DEFAULT NULL,
    p_value_4       IN VARCHAR2 DEFAULT NULL, -- larger than p_value_3
    p_size_4        IN INTEGER  DEFAULT NULL,
    p_value_5       IN VARCHAR2 DEFAULT NULL, -- larger than p_value_4
    p_size_5        IN INTEGER  DEFAULT NULL,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE );

  PROCEDURE set_min_max_values (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_new_min_value IN VARCHAR2,
    p_new_max_value IN VARCHAR2,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE );

  FUNCTION static_ownname
  RETURN VARCHAR2;

  FUNCTION static_tabname
  RETURN VARCHAR2;

  FUNCTION static_colname
  RETURN VARCHAR2;

  FUNCTION static_end_point
  RETURN VARCHAR2;

  FUNCTION static_partname
  RETURN VARCHAR2;

  FUNCTION static_cascade_parts
  RETURN VARCHAR2;

  FUNCTION static_preserve_size
  RETURN VARCHAR2;

  FUNCTION static_no_invalidate
  RETURN VARCHAR2;

  FUNCTION static_force
  RETURN VARCHAR2;

  /*************************************************************************************/

END sqlt$s;
/

SET TERM ON;
SHOW ERRORS PACKAGE &&tool_administer_schema..sqlt$s;
