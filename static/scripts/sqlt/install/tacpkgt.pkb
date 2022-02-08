CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..trca$t AS
/* $Header: 224270.1 tacpkgt.pkb 12.1.160429 2016/04/29 carlos.sierra abel.macias@oracle.com$ */

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  LF                     CONSTANT VARCHAR2(32767) := CHR(10); -- line feed
  CR                     CONSTANT VARCHAR2(32767) := CHR(13); -- carriage return
  USYS                   CONSTANT INTEGER :=  0;

  /*************************************************************************************/

  /* -------------------------
   *
   * private static
   *
   * ------------------------- */
  s_capture_extents VARCHAR2(128) := NULL;

  /*************************************************************************************/

  /* -------------------------
   *
   * private print_log
   *
   * writes line into log
   *
   * ------------------------- */
  PROCEDURE print_log (
    p_line IN VARCHAR2 )
  IS
  BEGIN /* print_log */
    trca$g.print_log(p_buffer => p_line, p_package => 'T');
  END print_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * private put_line
   *
   * ------------------------- */
  PROCEDURE put_line (
    p_line IN VARCHAR2 )
  IS
  BEGIN /* put_line */
    IF trca$g.g_log_open THEN
      print_log(p_line);
    ELSE
      SYS.DBMS_OUTPUT.PUT_LINE(SUBSTR(TO_CHAR(SYSDATE, 'HH24:MI:SS')||' '||p_line, 1, 254));
    END IF;
  END put_line;

  /*************************************************************************************/

  /* -------------------------
   *
   * private print_dict_state
   *
   * ------------------------- */
  PROCEDURE print_dict_state
  IS
  BEGIN /* print_dict_state */
    put_line('-> print_dict_state');

    put_line('dict_refresh_days : '||trca$g.g_dict_refresh_days );
    put_line('dict_refresh_date : '||trca$g.g_dict_refresh_date );
    put_line('dict_database_id  : '||trca$g.g_dict_database_id  );
    put_line('dict_database_name: '||trca$g.g_dict_database_name);
    put_line('dict_instance_id  : '||trca$g.g_dict_instance_id  );
    put_line('dict_instance_name: '||trca$g.g_dict_instance_name);
    put_line('dict_host_name    : '||trca$g.g_dict_host_name    );
    put_line('dict_platform     : '||trca$g.g_dict_platform     );
    put_line('dict_rdbms_version: '||trca$g.g_dict_rdbms_version);
    put_line('dict_db_files     : '||trca$g.g_dict_db_files     );

    put_line('<- print_dict_state');
  END print_dict_state;

  /*************************************************************************************/

  /* -------------------------
   *
   * private execute_immediate
   *
   * ------------------------- */
  PROCEDURE execute_immediate (
    p_command IN VARCHAR2 )
  IS
  BEGIN /* execute_immediate */
    EXECUTE IMMEDIATE p_command;
  EXCEPTION
    WHEN OTHERS THEN
      put_line(p_command);
      put_line(SQLERRM);
  END execute_immediate;

  /*************************************************************************************/

  /* -------------------------
   *
   * private call_purge_trca$_dict_gtt
   *
   * purges tool data dictionary global temporary tables
   *
   * ------------------------- */
  PROCEDURE call_purge_trca$_dict_gtt
  IS
  BEGIN /* call_purge_trca$_dict_gtt */
    put_line('-> call_purge_trca$_dict_gtt');

    /*
    -- cannot truncate since it would need DROP ANY TABLE system privilege
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_file$');
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_segments');
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_extents_dm');
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_extents_lm');

    COMMIT;
    */

    -- owned by tool_repository_schema
    purge_trca$_dict_gtt;

    put_line('<- call_purge_trca$_dict_gtt');
  END call_purge_trca$_dict_gtt;

  /*************************************************************************************/

  /* -------------------------
   *
   * public purge_trca$_dict
   *
   * purges tool data dictionary
   *
   * ------------------------- */
  PROCEDURE purge_trca$_dict
  IS
  BEGIN /* purge_trca$_dict */
    put_line('-> purge_trca$_dict');

    put_line('dict_state_before_purge');
    put_line('-----------------------');
    print_dict_state;

    call_purge_trca$_dict_gtt;
    -- cannot truncate since it would need DROP ANY TABLE system privilege
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_users');
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_extents');
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_tables$');
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_indexes$');
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_tab_cols$');
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_ind_columns$');
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_objects$');
    execute_immediate ('DELETE '||trca$g.g_tool_repository_schema||'.trca$_parameter2$');

    COMMIT;

    trca$g.set_param('dict_refresh_days', NULL, 'I');
    trca$g.set_param('dict_refresh_date', NULL, 'I');
    trca$g.set_param('dict_database_id', NULL, 'I');
    trca$g.set_param('dict_database_name', NULL, 'I');
    trca$g.set_param('dict_instance_id', NULL, 'I');
    trca$g.set_param('dict_instance_name', NULL, 'I');
    trca$g.set_param('dict_host_name', NULL, 'I');
    trca$g.set_param('dict_platform', NULL, 'I');
    trca$g.set_param('dict_rdbms_version', NULL, 'I');
    trca$g.set_param('dict_db_files', NULL, 'I');
    trca$g.get_dict_params;

    put_line('dict_state_after_purge');
    put_line('----------------------');
    print_dict_state;

    COMMIT;

    put_line('<- purge_trca$_dict');
  END purge_trca$_dict;

  /*************************************************************************************/

  /* -------------------------
   *
   * private refresh_trca$_users
   *
   * replicates sys.dba_users into trca$_users
   *
   * ------------------------- */
  PROCEDURE refresh_trca$_users
  IS
    rows_count INTEGER;

  BEGIN /* refresh_trca$_users */
    put_line('-> trca$_users');
    --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_users_u1');

    IF s_capture_extents = 'P' THEN
      INSERT /*+ APPEND PARALLEL(u 2) */
      INTO trca$_users u (
        u.user_id,
        u.user_name )
      SELECT /*+ FULL(s) PARALLEL(s 2) */
        DISTINCT
        s.uid#,
        s.owner
      FROM trca$_segments s;
      rows_count := SQL%ROWCOUNT;
    ELSE
      INSERT /*+ APPEND */
      INTO trca$_users u (
        u.user_id,
        u.user_name )
      SELECT
        DISTINCT
        s.uid#,
        s.owner
      FROM trca$_segments s;
      rows_count := SQL%ROWCOUNT;
    END IF;

    COMMIT;

    --execute_immediate ('CREATE UNIQUE INDEX '||trca$g.g_tool_repository_schema||'.trca$_users_u1 ON '||trca$g.g_tool_repository_schema||'.trca$_users(user_id)');
    trca$g.gather_table_stats('trca$_users');
    put_line('<- trca$_users ('||rows_count||' rows)');
  END refresh_trca$_users;

  /*************************************************************************************/

  /* -------------------------
   *
   * private refresh_trca$_extents
   *
   * replicates trca$_dba_extents into trca$_extents
   *
   * ------------------------- */
  PROCEDURE refresh_trca$_extents
  IS
    rows_count INTEGER;

  BEGIN /* refresh_trca$_extents */
    put_line('-> trca$_extents');
    --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_extents_u1');

    IF s_capture_extents = 'P' THEN
      INSERT /*+ APPEND PARALLEL(e 4) */
      INTO trca$_extents e (
        e.owner,
        e.segment_name,
        e.partition_name,
        e.segment_type,
        e.file_id,
        e.block_id_from,
        e.block_id_to )
      SELECT
        x.owner,
        x.segment_name,
        x.partition_name,
        x.segment_type,
        x.file_id,
        x.block_id block_id_from,
        (x.block_id + x.blocks - 1) block_id_to
      FROM trca$_dba_extents_p x;
      rows_count := SQL%ROWCOUNT;

      COMMIT;

      --execute_immediate ('CREATE UNIQUE INDEX '||trca$g.g_tool_repository_schema||'.trca$_extents_u1 ON '||trca$g.g_tool_repository_schema||'.trca$_extents(file_id, block_id_from, block_id_to) PARALLEL 4');
      --execute_immediate ('ALTER INDEX '||trca$g.g_tool_repository_schema||'.trca$_extents_u1 NOPARALLEL');
    ELSIF s_capture_extents = 'S' THEN
      INSERT /*+ APPEND */
      INTO trca$_extents e (
        e.owner,
        e.segment_name,
        e.partition_name,
        e.segment_type,
        e.file_id,
        e.block_id_from,
        e.block_id_to )
      SELECT
        x.owner,
        x.segment_name,
        x.partition_name,
        x.segment_type,
        x.file_id,
        x.block_id block_id_from,
        (x.block_id + x.blocks - 1) block_id_to
      FROM trca$_dba_extents x;
      rows_count := SQL%ROWCOUNT;

      COMMIT;

      --execute_immediate ('CREATE UNIQUE INDEX '||trca$g.g_tool_repository_schema||'.trca$_extents_u1 ON '||trca$g.g_tool_repository_schema||'.trca$_extents(file_id, block_id_from, block_id_to)');
    END IF;
    trca$g.gather_table_stats('trca$_extents');
    put_line('<- trca$_extents ('||rows_count||' rows)');
  END refresh_trca$_extents;

  /*************************************************************************************/

  /* -------------------------
   *
   * public refresh_trca$_dict_from_this
   *
   * refreshes tool data dictionary from this (internal) system
   *
   * ------------------------- */
  PROCEDURE refresh_trca$_dict_from_this
  IS
    rows_count INTEGER;
    begin_date DATE := SYSDATE;
    l_refresh_days NUMBER;

  BEGIN /* refresh_trca$_dict_from_this */
    put_line('=> refresh_trca$_dict_from_this');

    purge_trca$_dict;

    IF trca$g.g_refresh_dict_repository = 'N' THEN
      put_line('purge existing repository and skip refresh as per "refresh_dict_repository" tool parameter');
      put_line('<= refresh_trca$_dict_from_this');
      RETURN;
    END IF;

    BEGIN
      put_line('-> trca$_file$');

      INSERT /*+ APPEND */
      INTO trca$_file$ ( -- gtt
        file#,
        ts#,
        relfile# )
      SELECT
        file#,
        ts#,
        relfile#
      FROM sys.file$
      WHERE file# IS NOT NULL;
      rows_count := SQL%ROWCOUNT;

      COMMIT;

      put_line('<- trca$_file$ ('||rows_count||' rows)');
    END;

    s_capture_extents := trca$g.g_capture_extents;
    IF s_capture_extents = 'P' THEN
      put_line('enable parallel dml');
      trca$g.set_param('capture_extents', 'S'); -- in case P fails, next time it goes S
      execute_immediate('ALTER SESSION ENABLE PARALLEL QUERY');
      execute_immediate('ALTER SESSION ENABLE PARALLEL DML');
      execute_immediate('ALTER SESSION ENABLE PARALLEL DDL');
    ELSIF s_capture_extents = 'S' THEN
      put_line('using serial execution');
    END IF;

    BEGIN
      put_line('-> trca$_segments');

      rows_count := 0;
      IF s_capture_extents = 'P' THEN
        INSERT /*+ APPEND PARALLEL(ts 2) */
        INTO trca$_segments ts ( -- gtt
          ts.uid#,
          ts.owner,
          ts.segment_name,
          ts.partition_name,
          ts.segment_type,
          ts.tablespace_id,
          ts.header_block,
          ts.relative_fno,
          ts.managed )
        SELECT
          ds.uid#,
          ds.owner,
          ds.segment_name,
          ds.partition_name,
          ds.segment_type,
          ds.tablespace_id,
          ds.header_block,
          ds.relative_fno,
          ds.managed
        FROM trca$_dba_segments_p ds;
        rows_count := SQL%ROWCOUNT;
      ELSE
        INSERT /*+ APPEND */
        INTO trca$_segments ts ( -- gtt
          ts.uid#,
          ts.owner,
          ts.segment_name,
          ts.partition_name,
          ts.segment_type,
          ts.tablespace_id,
          ts.header_block,
          ts.relative_fno,
          ts.managed )
        SELECT
          ds.uid#,
          ds.owner,
          ds.segment_name,
          ds.partition_name,
          ds.segment_type,
          ds.tablespace_id,
          ds.header_block,
          ds.relative_fno,
          ds.managed
        FROM trca$_dba_segments ds;
        rows_count := SQL%ROWCOUNT;
      END IF;

      COMMIT;

      put_line('<- trca$_segments ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_extents_dm');

      rows_count := 0;
      IF s_capture_extents = 'P' THEN
        INSERT /*+ APPEND PARALLEL(e 2) */
        INTO trca$_extents_dm e ( -- gtt
          e.relative_fno,
          e.header_block,
          e.tablespace_id,
          e.relfile#,
          e.block_id,
          e.blocks )
        SELECT /*+ FULL(x) PARALLEL(x 2) */
          x.segfile#,
          x.segblock#,
          x.ts#,
          x.file#,
          x.block#,
          x.length
        FROM sys.uet$ x
        WHERE x.block# IS NOT NULL
        AND x.length IS NOT NULL;
        rows_count := SQL%ROWCOUNT;
      ELSIF s_capture_extents = 'S' THEN
        INSERT /*+ APPEND */
        INTO trca$_extents_dm e ( -- gtt
          e.relative_fno,
          e.header_block,
          e.tablespace_id,
          e.relfile#,
          e.block_id,
          e.blocks )
        SELECT
          x.segfile#,
          x.segblock#,
          x.ts#,
          x.file#,
          x.block#,
          x.length
        FROM sys.uet$ x
        WHERE x.block# IS NOT NULL
        AND x.length IS NOT NULL;
        rows_count := SQL%ROWCOUNT;
      END IF;

      COMMIT;

      put_line('<- trca$_extents_dm ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_extents_lm');

      rows_count := 0;
      IF s_capture_extents = 'P' THEN
        INSERT /*+ APPEND PARALLEL(e 2) */
        INTO trca$_extents_lm e ( -- gtt
          e.relative_fno,
          e.header_block,
          e.tablespace_id,
          e.relfile#,
          e.block_id,
          e.blocks )
        SELECT /*+ FULL(x) PARALLEL(x 2) */
          x.ktfbuesegfno,
          x.ktfbuesegbno,
          x.ktfbuesegtsn,
          x.ktfbuefno,
          x.ktfbuebno,
          x.ktfbueblks
        FROM trca$_x$ktfbue x
        WHERE x.ktfbuebno IS NOT NULL
        AND x.ktfbueblks IS NOT NULL;
        rows_count := SQL%ROWCOUNT;
      ELSIF s_capture_extents = 'S' THEN
        INSERT /*+ APPEND */
        INTO trca$_extents_lm e ( -- gtt
          e.relative_fno,
          e.header_block,
          e.tablespace_id,
          e.relfile#,
          e.block_id,
          e.blocks )
        SELECT
          x.ktfbuesegfno,
          x.ktfbuesegbno,
          x.ktfbuesegtsn,
          x.ktfbuefno,
          x.ktfbuebno,
          x.ktfbueblks
        FROM trca$_x$ktfbue x
        WHERE x.ktfbuebno IS NOT NULL
        AND x.ktfbueblks IS NOT NULL;
        rows_count := SQL%ROWCOUNT;
      END IF;

      COMMIT;

      put_line('<- trca$_extents_lm ('||rows_count||' rows)');
    END;

    BEGIN
      refresh_trca$_users;
      refresh_trca$_extents;

      IF s_capture_extents = 'P' THEN
        trca$g.set_param('capture_extents', 'P'); -- P did not fail, then next time it remains P
        --execute_immediate('ALTER SESSION DISABLE PARALLEL QUERY');
        execute_immediate('ALTER SESSION DISABLE PARALLEL DML');
        --execute_immediate('ALTER SESSION ENABLE PARALLEL DDL');
        put_line('disable parallel dml');
      END IF;

      call_purge_trca$_dict_gtt;
    END;

    BEGIN
      put_line('-> trca$_tables$');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_tables$_u1');

      INSERT /*+ APPEND */
      INTO trca$_tables$ (
        owner,
        table_name,
        num_rows,
        blocks,
        empty_blocks,
        avg_space,
        chain_cnt,
        avg_row_len,
        sample_size,
        last_analyzed,
        partitioned,
        temporary,
        global_stats )
      SELECT
        owner,
        table_name,
        num_rows,
        blocks,
        empty_blocks,
        avg_space,
        chain_cnt,
        avg_row_len,
        sample_size,
        last_analyzed,
        partitioned,
        temporary,
        global_stats
      FROM sys.dba_tables;
      rows_count := SQL%ROWCOUNT;

      COMMIT;

      --execute_immediate ('CREATE UNIQUE INDEX '||trca$g.g_tool_repository_schema||'.trca$_tables$_u1 ON '||trca$g.g_tool_repository_schema||'.trca$_tables$(table_name, owner)');
      trca$g.gather_table_stats('trca$_tables$');
      put_line('<- trca$_tables$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_indexes$');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_indexes$_u1');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_indexes$_n1');

      INSERT /*+ APPEND */
      INTO trca$_indexes$ (
        owner,
        index_name,
        index_type,
        table_owner,
        table_name,
        uniqueness,
        blevel,
        leaf_blocks,
        distinct_keys,
        avg_leaf_blocks_per_key,
        avg_data_blocks_per_key,
        clustering_factor,
        num_rows,
        sample_size,
        last_analyzed,
        partitioned,
        temporary,
        global_stats )
      SELECT
        owner,
        index_name,
        index_type,
        table_owner,
        table_name,
        uniqueness,
        blevel,
        leaf_blocks,
        distinct_keys,
        avg_leaf_blocks_per_key,
        avg_data_blocks_per_key,
        clustering_factor,
        num_rows,
        sample_size,
        last_analyzed,
        partitioned,
        temporary,
        global_stats
      FROM sys.dba_indexes;
      rows_count := SQL%ROWCOUNT;

      COMMIT;

      --execute_immediate ('CREATE UNIQUE INDEX '||trca$g.g_tool_repository_schema||'.trca$_indexes$_u1 ON '||trca$g.g_tool_repository_schema||'.trca$_indexes$(index_name, owner)');
      --execute_immediate ('CREATE INDEX '||trca$g.g_tool_repository_schema||'.trca$_indexes$_n1 ON '||trca$g.g_tool_repository_schema||'.trca$_indexes$(table_name, table_owner)');
      trca$g.gather_table_stats('trca$_indexes$');
      put_line('<- trca$_indexes$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_ind_columns$');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_ind_columns$_n1');

      INSERT /*+ APPEND */
      INTO trca$_ind_columns$ (
        index_owner,
        index_name,
        table_owner,
        table_name,
        column_name,
        column_position,
        descend )
      SELECT
        index_owner,
        index_name,
        table_owner,
        table_name,
        column_name,
        column_position,
        descend
      FROM sys.dba_ind_columns;
      rows_count := SQL%ROWCOUNT;

      COMMIT;

      --execute_immediate ('CREATE INDEX '||trca$g.g_tool_repository_schema||'.trca$_ind_columns$_n1 ON '||trca$g.g_tool_repository_schema||'.trca$_ind_columns$(index_name, index_owner)');
      trca$g.gather_table_stats('trca$_ind_columns$');
      put_line('<- trca$_ind_columns$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_tab_cols$');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_tab_cols$_n1');

      INSERT /*+ APPEND */
      INTO trca$_tab_cols$ (
        owner,
        table_name,
        column_name,
        column_id,
        num_distinct,
        density,
        num_nulls,
        num_buckets,
        last_analyzed,
        sample_size )
      SELECT
        tcl.owner,
        tcl.table_name,
        tcl.column_name,
        tcl.column_id,
        tcl.num_distinct,
        tcl.density,
        tcl.num_nulls,
        tcl.num_buckets,
        tcl.last_analyzed,
        tcl.sample_size
      FROM sys.dba_tab_cols tcl,
           (SELECT DISTINCT table_owner, table_name, column_name FROM trca$_ind_columns$) icl
     WHERE icl.table_owner = tcl.owner
       AND icl.table_name  = tcl.table_name
       AND icl.column_name = tcl.column_name;
      rows_count := SQL%ROWCOUNT;

      COMMIT;

      --execute_immediate ('CREATE INDEX '||trca$g.g_tool_repository_schema||'.trca$_tab_cols$_n1 ON '||trca$g.g_tool_repository_schema||'.trca$_tab_cols$(table_name, owner)');
      trca$g.gather_table_stats('trca$_tab_cols$');
      put_line('<- trca$_tab_cols$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_objects$');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_objects$_u1');

      INSERT /*+ APPEND */
      INTO trca$_objects$ (
        object_id,
        object_type,
        owner,
        object_name,
        subobject_name )
      SELECT
        object_id,
        object_type,
        owner,
        object_name,
        subobject_name
      FROM sys.dba_objects
      WHERE object_type LIKE 'TABLE%'
         OR object_type LIKE 'INDEX%'
         OR object_type = 'MATERIALIZED VIEW'
         OR object_type = 'CLUSTER';
      rows_count := SQL%ROWCOUNT;

      COMMIT;

      --execute_immediate ('CREATE UNIQUE INDEX '||trca$g.g_tool_repository_schema||'.trca$_objects$_u1 ON '||trca$g.g_tool_repository_schema||'.trca$_objects$(object_id)');
      trca$g.gather_table_stats('trca$_objects$');
      put_line('<- trca$_objects$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_parameter2$');

      INSERT /*+ APPEND */
      INTO trca$_parameter2$ (
        name,
        value )
      SELECT
        name,
        value
      FROM v$parameter2
      WHERE isdefault = 'FALSE';
      rows_count := SQL%ROWCOUNT;

      COMMIT;

      trca$g.gather_table_stats('trca$_parameter2$');
      put_line('<- trca$_parameter2$ ('||rows_count||' rows)');
    END;

    -- 1 day refresh rate for every minute it took to refresh the dictionary
    l_refresh_days := CEIL((SYSDATE - begin_date) * 24 * 60);

    trca$g.set_param('dict_refresh_days', TO_CHAR(l_refresh_days), 'I');
    trca$g.set_param('dict_refresh_date', TO_CHAR(SYSDATE, 'YYYYMMDD'), 'I');
    trca$g.set_param('dict_database_id', trca$g.g_tool_database_id, 'I');
    trca$g.set_param('dict_database_name', trca$g.g_tool_database_name, 'I');
    trca$g.set_param('dict_instance_id', trca$g.g_tool_instance_id, 'I');
    trca$g.set_param('dict_instance_name', trca$g.g_tool_instance_name, 'I');
    trca$g.set_param('dict_host_name', trca$g.g_tool_host_name, 'I');
    trca$g.set_param('dict_platform', trca$g.g_tool_platform, 'I');
    trca$g.set_param('dict_rdbms_version', trca$g.g_tool_rdbms_version, 'I');
    trca$g.set_param('dict_db_files', trca$g.g_tool_db_files, 'I');
    trca$g.get_dict_params;

    put_line('dict_state_after_refresh');
    put_line('------------------------');
    print_dict_state;

    COMMIT;

    put_line('<= refresh_trca$_dict_from_this');
  END refresh_trca$_dict_from_this;

  /*************************************************************************************/

  /* -------------------------
   *
   * public refresh_trca$_dict_from_that
   *
   * refreshes tool data dictionary from that (external) system
   *
   * ------------------------- */
  PROCEDURE refresh_trca$_dict_from_that
  IS
    rows_count INTEGER;
    ctrl_rec trca_control%ROWTYPE;

  BEGIN /* refresh_trca$_dict_from_that */
    put_line('=> refresh_trca$_dict_from_that');

    BEGIN
      put_line('-> trca_control');
      SELECT refresh_date,
             database_id,
             database_name,
             instance_id,
             instance_name,
             host_name,
             platform,
             rdbms_version,
             REPLACE(db_files, CR)
        INTO ctrl_rec.refresh_date,
             ctrl_rec.database_id,
             ctrl_rec.database_name,
             ctrl_rec.instance_id,
             ctrl_rec.instance_name,
             ctrl_rec.host_name,
             ctrl_rec.platform,
             ctrl_rec.rdbms_version,
             ctrl_rec.db_files
        FROM trca_control
       WHERE ROWNUM = 1;

      put_line('-- refresh_date:  '||ctrl_rec.refresh_date);
      put_line('-- database:      '||ctrl_rec.database_name||'('||ctrl_rec.database_id||')');
      put_line('-- instance:      '||ctrl_rec.instance_name||'('||ctrl_rec.instance_id||')');
      put_line('-- host_name:     '||ctrl_rec.host_name);
      put_line('-- platform:      '||ctrl_rec.platform);
      put_line('-- rdbms_version: '||ctrl_rec.rdbms_version);
      put_line('-- db_files:      '||ctrl_rec.db_files);
      put_line('<- trca_control');
    END;

    purge_trca$_dict;

    BEGIN
      put_line('-> trca$_file$');

      INSERT /*+ APPEND */
      INTO trca$_file$ (
        file#,
        ts#,
        relfile# )
      SELECT
        TO_NUMBER(file#),
        TO_NUMBER(ts#),
        TO_NUMBER(REPLACE(relfile#, CR))
      FROM trca_file;
      rows_count := SQL%ROWCOUNT;

      put_line('<- trca$_file$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_segments');

      INSERT /*+ APPEND */
      INTO trca$_segments (
        uid#,
        owner,
        segment_name,
        partition_name,
        segment_type,
        tablespace_id,
        header_block,
        relative_fno,
        managed )
      SELECT
        TO_NUMBER(uid#),
        owner,
        segment_name,
        partition_name,
        segment_type,
        TO_NUMBER(tablespace_id),
        TO_NUMBER(header_block),
        TO_NUMBER(relative_fno),
        TO_NUMBER(REPLACE(managed, CR))
      FROM trca_segments;
      rows_count := SQL%ROWCOUNT;

      put_line('<- trca$_segments ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_extents_dm');

      INSERT /*+ APPEND */
      INTO trca$_extents_dm (
        relative_fno,
        header_block,
        tablespace_id,
        relfile#,
        block_id,
        blocks )
      SELECT
        TO_NUMBER(relative_fno),
        TO_NUMBER(header_block),
        TO_NUMBER(tablespace_id),
        TO_NUMBER(relfile#),
        TO_NUMBER(block_id),
        TO_NUMBER(REPLACE(blocks, CR))
      FROM trca_extents_dm;
      rows_count := SQL%ROWCOUNT;

      put_line('<- trca$_extents_dm ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_extents_lm');

      INSERT /*+ APPEND */
      INTO trca$_extents_lm (
        relative_fno,
        header_block,
        tablespace_id,
        relfile#,
        block_id,
        blocks )
      SELECT
        TO_NUMBER(relative_fno),
        TO_NUMBER(header_block),
        TO_NUMBER(tablespace_id),
        TO_NUMBER(relfile#),
        TO_NUMBER(block_id),
        TO_NUMBER(REPLACE(blocks, CR))
      FROM trca_extents_lm;
      rows_count := SQL%ROWCOUNT;

      put_line('<- trca$_extents_lm ('||rows_count||' rows)');
    END;

    BEGIN
      COMMIT;
      refresh_trca$_users;
      refresh_trca$_extents;
      call_purge_trca$_dict_gtt;
    END;

    BEGIN
      put_line('-> trca$_tables$');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_tables$_u1');

      INSERT /*+ APPEND */
      INTO trca$_tables$ (
        owner,
        table_name,
        num_rows,
        blocks,
        empty_blocks,
        avg_space,
        chain_cnt,
        avg_row_len,
        sample_size,
        last_analyzed,
        partitioned,
        temporary,
        global_stats )
      SELECT
        owner,
        table_name,
        TO_NUMBER(num_rows),
        TO_NUMBER(blocks),
        TO_NUMBER(empty_blocks),
        TO_NUMBER(avg_space),
        TO_NUMBER(chain_cnt),
        TO_NUMBER(avg_row_len),
        TO_NUMBER(sample_size),
        CASE WHEN last_analyzed = '00000000000000' THEN TO_DATE(NULL) ELSE TO_DATE(last_analyzed, 'YYYYMMDDHH24MISS') END,
        partitioned,
        temporary,
        REPLACE(global_stats, CR)
      FROM trca_tables;
      rows_count := SQL%ROWCOUNT;

      --execute_immediate ('CREATE UNIQUE INDEX '||trca$g.g_tool_repository_schema||'.trca$_tables$_u1 ON '||trca$g.g_tool_repository_schema||'.trca$_tables$(table_name, owner)');
      trca$g.gather_table_stats('trca$_tables$');
      put_line('<- trca$_tables$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_indexes$');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_indexes$_u1');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_indexes$_n1');

      INSERT /*+ APPEND */
      INTO trca$_indexes$ (
        owner,
        index_name,
        index_type,
        table_owner,
        table_name,
        uniqueness,
        blevel,
        leaf_blocks,
        distinct_keys,
        avg_leaf_blocks_per_key,
        avg_data_blocks_per_key,
        clustering_factor,
        num_rows,
        sample_size,
        last_analyzed,
        partitioned,
        temporary,
        global_stats )
      SELECT
        owner,
        index_name,
        index_type,
        table_owner,
        table_name,
        uniqueness,
        TO_NUMBER(blevel),
        TO_NUMBER(leaf_blocks),
        TO_NUMBER(distinct_keys),
        TO_NUMBER(avg_leaf_blocks_per_key),
        TO_NUMBER(avg_data_blocks_per_key),
        TO_NUMBER(clustering_factor),
        TO_NUMBER(num_rows),
        TO_NUMBER(sample_size),
        CASE WHEN last_analyzed = '00000000000000' THEN TO_DATE(NULL) ELSE TO_DATE(last_analyzed, 'YYYYMMDDHH24MISS') END,
        partitioned,
        temporary,
        REPLACE(global_stats, CR)
      FROM trca_indexes;
      rows_count := SQL%ROWCOUNT;

      --execute_immediate ('CREATE UNIQUE INDEX '||trca$g.g_tool_repository_schema||'.trca$_indexes$_u1 ON '||trca$g.g_tool_repository_schema||'.trca$_indexes$(index_name, owner)');
      --execute_immediate ('CREATE INDEX '||trca$g.g_tool_repository_schema||'.trca$_indexes$_n1 ON '||trca$g.g_tool_repository_schema||'.trca$_indexes$(table_name, table_owner)');
      trca$g.gather_table_stats('trca$_indexes$');
      put_line('<- trca$_indexes$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_tab_cols$');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_tab_cols$_n1');

      INSERT /*+ APPEND */
      INTO trca$_tab_cols$ (
        owner,
        table_name,
        column_name,
        column_id,
        num_distinct,
        density,
        num_nulls,
        num_buckets,
        last_analyzed,
        sample_size )
      SELECT
        owner,
        table_name,
        column_name,
        TO_NUMBER(column_id),
        TO_NUMBER(num_distinct),
        TO_NUMBER(density),
        TO_NUMBER(num_nulls),
        TO_NUMBER(num_buckets),
        CASE WHEN last_analyzed = '00000000000000' THEN TO_DATE(NULL) ELSE TO_DATE(last_analyzed, 'YYYYMMDDHH24MISS') END,
        TO_NUMBER(REPLACE(sample_size, CR))
      FROM trca_tab_cols;
      rows_count := SQL%ROWCOUNT;

      --execute_immediate ('CREATE INDEX '||trca$g.g_tool_repository_schema||'.trca$_tab_cols$_n1 ON '||trca$g.g_tool_repository_schema||'.trca$_tab_cols$(table_name, owner)');
      trca$g.gather_table_stats('trca$_tab_cols$');
      put_line('<- trca$_tab_cols$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_ind_columns$');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_ind_columns$_n1');

      INSERT /*+ APPEND */
      INTO trca$_ind_columns$ (
        index_owner,
        index_name,
        table_owner,
        table_name,
        column_name,
        column_position,
        descend )
      SELECT
        index_owner,
        index_name,
        table_owner,
        table_name,
        column_name,
        TO_NUMBER(column_position),
        REPLACE(descend, CR)
      FROM trca_ind_columns;
      rows_count := SQL%ROWCOUNT;

      --execute_immediate ('CREATE INDEX '||trca$g.g_tool_repository_schema||'.trca$_ind_columns$_n1 ON '||trca$g.g_tool_repository_schema||'.trca$_ind_columns$(index_name, index_owner)');
      trca$g.gather_table_stats('trca$_ind_columns$');
      put_line('<- trca$_ind_columns$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_objects$');
      --execute_immediate ('DROP INDEX '||trca$g.g_tool_repository_schema||'.trca$_objects$_u1');

      INSERT /*+ APPEND */
      INTO trca$_objects$ (
        object_id,
        object_type,
        owner,
        object_name,
        subobject_name )
      SELECT
        TO_NUMBER(object_id),
        object_type,
        owner,
        object_name,
        REPLACE(subobject_name, CR)
      FROM trca_objects;
      rows_count := SQL%ROWCOUNT;

      --execute_immediate ('CREATE UNIQUE INDEX '||trca$g.g_tool_repository_schema||'.trca$_objects$_u1 ON '||trca$g.g_tool_repository_schema||'.trca$_objects$(object_id)');
      trca$g.gather_table_stats('trca$_objects$');
      put_line('<- trca$_objects$ ('||rows_count||' rows)');
    END;

    BEGIN
      put_line('-> trca$_parameter2$');

      INSERT /*+ APPEND */
      INTO trca$_parameter2$ (
        name,
        value )
      SELECT
        name,
        REPLACE(REPLACE(value, '^', ','), CR)
      FROM trca_parameter2;
      rows_count := SQL%ROWCOUNT;

      trca$g.gather_table_stats('trca$_parameter2$');
      put_line('<- trca$_parameter2$ ('||rows_count||' rows)');
    END;

    trca$g.set_param('dict_refresh_days', '999', 'I');
    trca$g.set_param('dict_refresh_date', TO_CHAR(SYSDATE, 'YYYYMMDD'), 'I');
    trca$g.set_param('dict_database_id', ctrl_rec.database_id, 'I');
    trca$g.set_param('dict_database_name', ctrl_rec.database_name, 'I');
    trca$g.set_param('dict_instance_id', ctrl_rec.instance_id, 'I');
    trca$g.set_param('dict_instance_name', ctrl_rec.instance_name, 'I');
    trca$g.set_param('dict_host_name', ctrl_rec.host_name, 'I');
    trca$g.set_param('dict_platform', ctrl_rec.platform, 'I');
    trca$g.set_param('dict_rdbms_version', ctrl_rec.rdbms_version, 'I');
    trca$g.set_param('dict_db_files', ctrl_rec.db_files, 'I');
    trca$g.get_dict_params;

    put_line('dict_state_after_refresh');
    put_line('------------------------');
    print_dict_state;

    COMMIT;

    put_line('<= refresh_trca$_dict_from_that');
  END refresh_trca$_dict_from_that;

  /*************************************************************************************/

  /* -------------------------
   *
   * private adjust_calls
   *
   * there are a few entries where recursive
   * total is larger than value (i.e. recu_cr > cr)
   * which is conceptually incorrect
   *
   * ------------------------- */
  PROCEDURE adjust_calls (
    p_tool_execution_id IN INTEGER )
  IS
    l_d_count       INTEGER := 0;
    l_d_adjustment  INTEGER := 0;
    l_c_count       INTEGER := 0;
    l_c_adjustment  INTEGER := 0;
    l_e_count       INTEGER := 0;
    l_e_adjustment  INTEGER := 0;
    l_p_count       INTEGER := 0;
    l_p_adjustment  INTEGER := 0;
    l_cr_count      INTEGER := 0;
    l_cr_adjustment INTEGER := 0;
    l_cu_count      INTEGER := 0;
    l_cu_adjustment INTEGER := 0;

  BEGIN /* adjust_calls */
    print_log('-> adjust_calls');

    -- adjusting calls that are children of themselves
    FOR i IN (SELECT child.ROWID row_id, child.tim, child.e
                FROM trca$_call child,
                     trca$_call parent
               WHERE child.tool_execution_id = parent.tool_execution_id
                 AND child.parent_dep_id = parent.dep_id
                 AND child.group_id = parent.group_id)
    LOOP
      l_d_count := l_d_count + 1;
      l_d_adjustment := l_d_adjustment + i.e;
      DELETE trca$_call WHERE ROWID = i.row_id;
      IF l_d_count <= 10 THEN
        print_log('call tim='||i.tim||' e='||i.e||' is child of itself!');
      END IF;
    END LOOP;
    IF l_d_count > 0 THEN
      print_log('ignored call count='||l_d_count||' adjustment='||l_d_adjustment);
    END IF;

    -- adjusting parent of recursive sql that has larger values than its parent
    FOR i IN (SELECT ROWID row_id, c.* FROM trca$_call c WHERE c.tool_execution_id = p_tool_execution_id)
    LOOP
      IF i.recu_c > i.c THEN
        l_c_count := l_c_count + 1;
        l_c_adjustment := l_c_adjustment + (i.recu_c - i.c);
        UPDATE trca$_call SET c = i.recu_c WHERE ROWID = i.row_id;
        IF l_c_count <= 10 THEN
          print_log('adjusting tim='||i.tim||' c: '||i.c||' -> '||i.recu_c);
        END IF;
      END IF;
      IF i.recu_e > i.e THEN
        l_e_count := l_e_count + 1;
        l_e_adjustment := l_e_adjustment + (i.recu_e - i.e);
        UPDATE trca$_call SET e = i.recu_e WHERE ROWID = i.row_id;
        IF l_e_count <= 10 THEN
          print_log('adjusting tim='||i.tim||' e: '||i.e||' -> '||i.recu_e);
        END IF;
      END IF;
      IF i.recu_p > i.p THEN
        l_p_count := l_p_count + 1;
        l_p_adjustment := l_p_adjustment + (i.recu_p - i.p);
        UPDATE trca$_call SET p = i.recu_p WHERE ROWID = i.row_id;
        IF l_p_count <= 10 THEN
          print_log('adjusting tim='||i.tim||' p: '||i.p||' -> '||i.recu_p);
        END IF;
      END IF;
      IF i.recu_cr > i.cr THEN
        l_cr_count := l_cr_count + 1;
        l_cr_adjustment := l_cr_adjustment + (i.recu_cr - i.cr);
        UPDATE trca$_call SET cr = i.recu_cr WHERE ROWID = i.row_id;
        IF l_cr_count <= 10 THEN
          print_log('adjusting tim='||i.tim||' cr: '||i.cr||' -> '||i.recu_cr);
        END IF;
      END IF;
      IF i.recu_cu > i.cu THEN
        l_cu_count := l_cu_count + 1;
        l_cu_adjustment := l_cu_adjustment + (i.recu_cu - i.cu);
        UPDATE trca$_call SET cu = i.recu_cu WHERE ROWID = i.row_id;
        IF l_cu_count <= 10 THEN
          print_log('adjusting tim='||i.tim||' cu: '||i.cu||' -> '||i.recu_cu);
        END IF;
      END IF;
    END LOOP;

    IF l_c_count > 0 THEN
      print_log('adjusted c count='||l_c_count||' adjustment='||l_c_adjustment);
    END IF;
    IF l_e_count > 0 THEN
      print_log('adjusted e count='||l_e_count||' adjustment='||l_e_adjustment);
    END IF;
    IF l_p_count > 0 THEN
      print_log('adjusted p count='||l_p_count||' adjustment='||l_p_adjustment);
    END IF;
    IF l_cr_count > 0 THEN
      print_log('adjusted cr count='||l_cr_count||' adjustment='||l_cr_adjustment);
    END IF;
    IF l_cu_count > 0 THEN
      print_log('adjusted cu count='||l_cu_count||' adjustment='||l_cu_adjustment);
    END IF;

    COMMIT;
    print_log('<- adjust_calls');
  END adjust_calls;

  /*************************************************************************************/

  /* -------------------------
   *
   * private min_and_max_tim
   *
   * ------------------------- */
  PROCEDURE min_and_max_tim (
    p_tool_execution_id IN INTEGER )
  IS
    l_min_tim INTEGER;
    l_max_tim INTEGER;
    l_dep     INTEGER;

  BEGIN /* min_and_max_tim */
    print_log('-> min_and_max_tim');
    SELECT MIN(tim - e), MAX(tim), MAX(dep)
      INTO l_min_tim, l_max_tim, l_dep
      FROM trca$_call
     WHERE tool_execution_id = p_tool_execution_id
       AND tim <> 0
       AND (tim - e) > 0;

    UPDATE trca$_tool_execution
       SET start_tim = l_min_tim,
           end_tim = l_max_tim,
           dep = l_dep
     WHERE id = p_tool_execution_id;

    COMMIT;
    print_log('<- min_and_max_tim');
  END min_and_max_tim;

  /*************************************************************************************/

  /* -------------------------
   *
   * private call_tree
   *
   * ------------------------- */
  PROCEDURE call_tree (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* call_tree */
    print_log('-> call_tree');
    INSERT INTO trca$_call_tree (
      tool_execution_id,
      group_id,
      parent_group_id,
      dep_id,
      parent_dep_id,
      exec_id,
      response_time_self,
      response_time_progeny
    )
    SELECT child.tool_execution_id,
           child.group_id,
           parent.group_id parent_group_id,
           child.dep_id,
           child.parent_dep_id,
           child.exec_id,
           SUM(NVL(child.e, 0) - NVL(child.recu_e, 0) + NVL(child.self_wait_ela_idle, 0)) response_time_self,
           SUM(NVL(child.recu_e, 0) + NVL(child.recu_wait_ela_idle, 0)) response_time_progeny
      FROM trca$_call child,
           trca$_call parent
     WHERE child.tool_execution_id = p_tool_execution_id
       AND parent.tool_execution_id = p_tool_execution_id
       AND child.parent_dep_id IS NOT NULL -- redundant
       AND child.parent_dep_id = parent.dep_id
     GROUP BY
           child.tool_execution_id,
           child.group_id,
           parent.group_id,
           child.dep_id,
           child.parent_dep_id,
           child.exec_id;

    INSERT INTO trca$_call_tree (
      tool_execution_id,
      group_id,
      parent_group_id,
      dep_id,
      parent_dep_id,
      exec_id,
      response_time_self,
      response_time_progeny
    )
    SELECT child.tool_execution_id,
           child.group_id,
           NULL, -- parent.group_id
           child.dep_id,
           child.parent_dep_id,
           child.exec_id,
           SUM(NVL(child.e, 0) - NVL(child.recu_e, 0) + NVL(child.self_wait_ela_idle, 0)) response_time_self,
           SUM(NVL(child.recu_e, 0) + NVL(child.recu_wait_ela_idle, 0)) response_time_progeny
      FROM trca$_call child
     WHERE child.tool_execution_id = p_tool_execution_id
       AND child.parent_dep_id IS NULL
     GROUP BY
           child.tool_execution_id,
           child.group_id,
           child.dep_id,
           child.parent_dep_id,
           child.exec_id;

    COMMIT;
    trca$g.gather_table_stats('trca$_call_tree');
    print_log('<- call_tree');
  END call_tree;

  /*************************************************************************************/

  /* -------------------------
   *
   * private exec_tree
   *
   * ------------------------- */
  PROCEDURE exec_tree (
    p_tool_execution_id IN INTEGER,
    p_group_id          IN INTEGER )
  IS
    l_max_dep INTEGER;

    gen_rec trca$_exec_tree%ROWTYPE;

    PROCEDURE exec_tree_recursive (
      p2_dep      IN INTEGER,
      p2_path     IN VARCHAR2,
      p2_dep_id   IN INTEGER )
    IS
    BEGIN /* exec_tree_recursive */
      IF p2_dep <= l_max_dep THEN
        FOR j IN (SELECT *
                    FROM trca$_call_tree
                   WHERE tool_execution_id = p_tool_execution_id
                     AND parent_dep_id     = p2_dep_id)
        LOOP
          gen_rec := NULL;
          gen_rec.tool_execution_id     := p_tool_execution_id;
          gen_rec.root_group_id         := p_group_id;
          gen_rec.group_id              := j.group_id;
          gen_rec.parent_group_id       := j.parent_group_id;
          gen_rec.exec_id               := j.exec_id;
          gen_rec.response_time_self    := j.response_time_self;
          gen_rec.response_time_progeny := j.response_time_progeny;
          gen_rec.dep                   := p2_dep + 1;
          gen_rec.path                  := p2_path;
          INSERT INTO trca$_exec_tree VALUES gen_rec;

          exec_tree_recursive (
            p2_dep      => p2_dep + 1,
            p2_path     => p2_path||':'||j.group_id,
            p2_dep_id   => j.dep_id );
        END LOOP;
      END IF;
    END exec_tree_recursive;

  BEGIN /* exec_tree */
    SELECT dep
      INTO l_max_dep
      FROM trca$_tool_execution
     WHERE id = p_tool_execution_id;

    FOR i IN (SELECT *
                FROM trca$_call_tree
               WHERE tool_execution_id = p_tool_execution_id
                 AND group_id          = p_group_id)
    LOOP
      gen_rec := NULL;
      gen_rec.tool_execution_id     := p_tool_execution_id;
      gen_rec.root_group_id         := p_group_id;
      gen_rec.group_id              := p_group_id;
      gen_rec.parent_group_id       := NULL;
      gen_rec.exec_id               := i.exec_id;
      gen_rec.response_time_self    := i.response_time_self;
      gen_rec.response_time_progeny := i.response_time_progeny;
      gen_rec.dep                   := 0;
      gen_rec.path                  := NULL;
      INSERT INTO trca$_exec_tree VALUES gen_rec;

      exec_tree_recursive (
        p2_dep      => 0,
        p2_path     => p_group_id,
        p2_dep_id   => i.dep_id );
    END LOOP;
  END exec_tree;

  /*************************************************************************************/

  /* -------------------------
   *
   * private genealogy
   *
   * ------------------------- */
  PROCEDURE genealogy (
    p_tool_execution_id IN INTEGER,
    p_group_id          IN INTEGER,
    x_id                IN OUT INTEGER )
  IS
    gen_rec3 trca$_genealogy%ROWTYPE;

    PROCEDURE genealogy_recursive (
      p2_group_id IN INTEGER,
      p2_path     IN VARCHAR2 )
    IS
    BEGIN /* genealogy_recursive */
      FOR j IN (SELECT *
                  FROM trca$_genealogy_edge
                 WHERE tool_execution_id = p_tool_execution_id
                   AND root_group_id     = p_group_id
                   AND parent_group_id   = p2_group_id
                   AND path              = p2_path
                 ORDER BY
                        first_exec_id)
      LOOP
        x_id := x_id + 1;
        gen_rec3 := NULL;
        gen_rec3.tool_execution_id     := j.tool_execution_id;
        gen_rec3.root_group_id         := j.root_group_id;
        gen_rec3.id                    := x_id;
        gen_rec3.group_id              := j.group_id;
        gen_rec3.parent_group_id       := j.parent_group_id;
        gen_rec3.first_exec_id         := j.first_exec_id;
        gen_rec3.exec_count            := j.exec_count;
        gen_rec3.response_time_self    := j.response_time_self;
        gen_rec3.response_time_progeny := j.response_time_progeny;
        gen_rec3.dep                   := j.dep;
        gen_rec3.path                  := j.path;
        INSERT INTO trca$_genealogy VALUES gen_rec3;

        genealogy_recursive (
          p2_group_id => j.group_id,
          p2_path     => j.path||':'||j.group_id );
      END LOOP;
    END genealogy_recursive;

  BEGIN /* genealogy */
    FOR i IN (SELECT *
                FROM trca$_genealogy_edge
               WHERE tool_execution_id = p_tool_execution_id
                 AND root_group_id     = p_group_id
                 AND group_id          = p_group_id
               ORDER BY
                     first_exec_id)
    LOOP
      x_id := x_id + 1;
      gen_rec3 := NULL;
      gen_rec3.tool_execution_id     := i.tool_execution_id;
      gen_rec3.root_group_id         := i.root_group_id;
      gen_rec3.id                    := x_id;
      gen_rec3.group_id              := i.group_id;
      gen_rec3.parent_group_id       := i.parent_group_id;
      gen_rec3.first_exec_id         := i.first_exec_id;
      gen_rec3.exec_count            := i.exec_count;
      gen_rec3.response_time_self    := i.response_time_self;
      gen_rec3.response_time_progeny := i.response_time_progeny;
      gen_rec3.dep                   := i.dep;
      gen_rec3.path                  := i.path;
      INSERT INTO trca$_genealogy VALUES gen_rec3;

      genealogy_recursive (
        p2_group_id => i.group_id,
        p2_path     => i.group_id );
    END LOOP;
  END genealogy;

  /*************************************************************************************/

  /* -------------------------
   *
   * private genealogy
   *
   * ------------------------- */
  PROCEDURE genealogy (
    p_tool_execution_id IN INTEGER )
  IS
    l_id INTEGER := 0;

  BEGIN /* genealogy */
    -- exec_tree
    print_log('-> exec_tree');
    FOR i IN (SELECT id group_id
                FROM trca$_group
               WHERE tool_execution_id = p_tool_execution_id
                 AND dep = 0
               ORDER BY
                     first_exec_id)
    LOOP
      exec_tree (
        p_tool_execution_id => p_tool_execution_id,
        p_group_id          => i.group_id );
    END LOOP;

    trca$g.gather_table_stats('trca$_exec_tree');
    print_log('-> exec_tree');

    -- genealogy_edge
    print_log('<- genealogy_edge');
    INSERT INTO trca$_genealogy_edge (
      tool_execution_id,
      root_group_id,
      group_id,
      parent_group_id,
      first_exec_id,
      exec_count,
      response_time_self,
      response_time_progeny,
      dep,
      path
    )
    SELECT p_tool_execution_id,
           root_group_id,
           group_id,
           parent_group_id,
           MIN(exec_id) first_exec_id,
           COUNT(DISTINCT exec_id) exec_count,
           SUM(NVL(response_time_self, 0)) response_time_self,
           SUM(NVL(response_time_progeny, 0)) response_time_progeny,
           MIN(dep) dep,
           path
      FROM trca$_exec_tree
     WHERE tool_execution_id = p_tool_execution_id
     GROUP BY
           root_group_id,
           group_id,
           parent_group_id,
           path;

    trca$g.gather_table_stats('trca$_genealogy_edge');
    print_log('<- genealogy_edge');

    -- genealogy
    print_log('-> genealogy');
    FOR i IN (SELECT id group_id
                FROM trca$_group
               WHERE tool_execution_id = p_tool_execution_id
                 AND dep = 0
               ORDER BY
                     first_exec_id)
    LOOP
      genealogy (
        p_tool_execution_id => p_tool_execution_id,
        p_group_id          => i.group_id,
        x_id                => l_id );
    END LOOP;

    trca$g.gather_table_stats('trca$_genealogy');
    print_log('<- genealogy');
  END genealogy;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tool_call
   *
   * ------------------------- */
  PROCEDURE tool_call (
    p_tool_execution_id IN INTEGER )
  IS
    /* -------------------------
     *
     * tool_call.insert_missing
     *
     * ------------------------- */
    PROCEDURE insert_missing (
      p_call      IN VARCHAR2,
      p_recursive IN VARCHAR2 )
    IS
      l_count INTEGER;
    BEGIN /* insert_missing */
      SELECT COUNT(*)
        INTO l_count
        FROM trca$_tool_exec_call
       WHERE tool_execution_id = p_tool_execution_id
         AND recursive = p_recursive
         AND call = p_call;

      IF l_count > 0 THEN
        RETURN;
      END IF;

      INSERT INTO trca$_tool_exec_call (
        tool_execution_id,
        recursive,
        call,
        -- aggregate stats (this plus direct children)
        c,
        e,
        p,
        cr,
        cu,
        -- non aggregate stats (this)
        call_count,
        mis,
        r,
        -- recursive call metrics (direct children)
        recu_c,
        recu_e,
        recu_p,
        recu_cr,
        recu_cu,
        recu_call_count,
        recu_mis,
        recu_r,
        -- recursive waits metrics
        self_wait_count_idle,
        self_wait_count_non_idle,
        self_wait_ela_idle,
        self_wait_ela_non_idle,
        recu_wait_count_idle,
        recu_wait_count_non_idle,
        recu_wait_ela_idle,
        recu_wait_ela_non_idle
      )
      SELECT p_tool_execution_id,
             p_recursive,
             p_call,
             0 c,
             0 e,
             0 p,
             0 cr,
             0 cu,
             0 call_count,
             0 mis,
             0 r,
             0 recu_c,
             0 recu_e,
             0 recu_p,
             0 recu_cr,
             0 recu_cu,
             0 recu_call_count,
             0 recu_mis,
             0 recu_r,
             0 self_wait_count_idle,
             0 self_wait_count_non_idle,
             0 self_wait_ela_idle,
             0 self_wait_ela_non_idle,
             0 recu_wait_count_idle,
             0 recu_wait_count_non_idle,
             0 recu_wait_ela_idle,
             0 recu_wait_ela_non_idle
        FROM DUAL;
    END insert_missing;

  BEGIN /* tool_call */
    print_log('-> tool_call_non_recursive');
    INSERT INTO trca$_tool_exec_call (
      tool_execution_id,
      recursive,
      call,
      -- aggregate stats (this plus direct children)
      c,
      e,
      p,
      cr,
      cu,
      -- non aggregate stats (this)
      call_count,
      mis,
      r,
      -- recursive call metrics (direct children)
      recu_c,
      recu_e,
      recu_p,
      recu_cr,
      recu_cu,
      recu_call_count,
      recu_mis,
      recu_r,
      -- recursive waits metrics
      self_wait_count_idle,
      self_wait_count_non_idle,
      self_wait_ela_idle,
      self_wait_ela_non_idle,
      recu_wait_count_idle,
      recu_wait_count_non_idle,
      recu_wait_ela_idle,
      recu_wait_ela_non_idle
    )
    SELECT p_tool_execution_id,
           'N' recursive,
           call.call,
           SUM(NVL(call.c, 0)) c,
           SUM(NVL(call.e, 0)) e,
           SUM(NVL(call.p, 0)) p,
           SUM(NVL(call.cr, 0)) cr,
           SUM(NVL(call.cu, 0)) cu,
           COUNT(*) call_count,
           SUM(NVL(call.mis, 0)) mis,
           SUM(NVL(call.r, 0)) r,
           SUM(NVL(call.recu_c, 0)) recu_c,
           SUM(NVL(call.recu_e, 0)) recu_e,
           SUM(NVL(call.recu_p, 0)) recu_p,
           SUM(NVL(call.recu_cr, 0)) recu_cr,
           SUM(NVL(call.recu_cu, 0)) recu_cu,
           SUM(NVL(call.recu_call_count, 0)) recu_call_count,
           SUM(NVL(call.recu_mis, 0)) recu_mis,
           SUM(NVL(call.recu_r, 0)) recu_r,
           SUM(NVL(call.self_wait_count_idle, 0)) self_wait_count_idle,
           SUM(NVL(call.self_wait_count_non_idle, 0)) self_wait_count_non_idle,
           SUM(NVL(call.self_wait_ela_idle, 0)) self_wait_ela_idle,
           SUM(NVL(call.self_wait_ela_non_idle, 0)) self_wait_ela_non_idle,
           SUM(NVL(call.recu_wait_count_idle, 0)) recu_wait_count_idle,
           SUM(NVL(call.recu_wait_count_non_idle, 0)) recu_wait_count_non_idle,
           SUM(NVL(call.recu_wait_ela_idle, 0)) recu_wait_ela_idle,
           SUM(NVL(call.recu_wait_ela_non_idle, 0)) recu_wait_ela_non_idle
      FROM trca$_call call
     WHERE call.tool_execution_id = p_tool_execution_id
       AND call.dep = 0
     GROUP BY
           call.call;
    print_log('<- tool_call_non_recursive');

    print_log('-> tool_call_recursive');
    INSERT INTO trca$_tool_exec_call (
      tool_execution_id,
      recursive,
      call,
      -- aggregate stats (this plus direct children)
      c,
      e,
      p,
      cr,
      cu,
      -- non aggregate stats (this)
      call_count,
      mis,
      r,
      -- recursive call metrics (direct children)
      recu_c,
      recu_e,
      recu_p,
      recu_cr,
      recu_cu,
      recu_call_count,
      recu_mis,
      recu_r,
      -- recursive waits metrics
      self_wait_count_idle,
      self_wait_count_non_idle,
      self_wait_ela_idle,
      self_wait_ela_non_idle,
      recu_wait_count_idle,
      recu_wait_count_non_idle,
      recu_wait_ela_idle,
      recu_wait_ela_non_idle
    )
    SELECT p_tool_execution_id,
           'Y' recursive,
           call.call,
           SUM(NVL(call.c, 0) - NVL(call.recu_c, 0)) c,
           SUM(NVL(call.e, 0) - NVL(call.recu_e, 0)) e,
           SUM(NVL(call.p, 0) - NVL(call.recu_p, 0)) p,
           SUM(NVL(call.cr, 0) - NVL(call.recu_cr, 0)) cr,
           SUM(NVL(call.cu, 0) - NVL(call.recu_cu, 0)) cu,
           COUNT(*) call_count,
           SUM(NVL(call.mis, 0)) mis,
           SUM(NVL(call.r, 0)) r,
           NULL recu_c,
           NULL recu_e,
           NULL recu_p,
           NULL recu_cr,
           NULL recu_cu,
           NULL recu_call_count,
           NULL recu_mis,
           NULL recu_r,
           SUM(NVL(call.self_wait_count_idle, 0)) self_wait_count_idle,
           SUM(NVL(call.self_wait_count_non_idle, 0)) self_wait_count_non_idle,
           SUM(NVL(call.self_wait_ela_idle, 0)) self_wait_ela_idle,
           SUM(NVL(call.self_wait_ela_non_idle, 0)) self_wait_ela_non_idle,
           NULL recu_wait_count_idle,
           NULL recu_wait_count_non_idle,
           NULL recu_wait_ela_idle,
           NULL recu_wait_ela_non_idle
      FROM trca$_call call
     WHERE call.tool_execution_id = p_tool_execution_id
       AND call.dep > 0
     GROUP BY
           call.call;
    print_log('<- tool_call_recursive');

    print_log('-> tool_call');
    insert_missing(trca$g.CALL_PARSE, 'N');
    insert_missing(trca$g.CALL_EXEC,  'N');
    insert_missing(trca$g.CALL_FETCH, 'N');

    insert_missing(trca$g.CALL_PARSE, 'Y');
    insert_missing(trca$g.CALL_EXEC,  'Y');
    insert_missing(trca$g.CALL_FETCH, 'Y');

    COMMIT;
    trca$g.gather_table_stats('trca$_tool_exec_call');
    print_log('<- tool_call');
  END tool_call;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tool_call_total
   *
   * ------------------------- */
  PROCEDURE tool_call_total (
    p_tool_execution_id IN INTEGER )
  IS
    l_accounted_for_response_time INTEGER;
    l_elapsed_time INTEGER;
    l_cpu_time INTEGER;

    /* -------------------------
     *
     * tool_call_total.insert_total
     *
     * ------------------------- */
    PROCEDURE insert_total (
      p_recursive IN VARCHAR2 )
    IS
    BEGIN /* insert_total */
      INSERT INTO trca$_tool_exec_call (
        tool_execution_id,
        recursive,
        call,
        -- aggregate stats (this plus direct children)
        c,
        e,
        p,
        cr,
        cu,
        -- non aggregate stats (this)
        call_count,
        mis,
        r,
        -- recursive call metrics (direct children)
        recu_c,
        recu_e,
        recu_p,
        recu_cr,
        recu_cu,
        recu_call_count,
        recu_mis,
        recu_r,
        -- recursive waits metrics
        self_wait_count_idle,
        self_wait_count_non_idle,
        self_wait_ela_idle,
        self_wait_ela_non_idle,
        recu_wait_count_idle,
        recu_wait_count_non_idle,
        recu_wait_ela_idle,
        recu_wait_ela_non_idle
      )
      SELECT p_tool_execution_id,
             p_recursive,
             trca$g.CALL_TOTAL, -- TOTAL
             SUM(NVL(call.c, 0)) c,
             SUM(NVL(call.e, 0)) e,
             SUM(NVL(call.p, 0)) p,
             SUM(NVL(call.cr, 0)) cr,
             SUM(NVL(call.cu, 0)) cu,
             SUM(NVL(call.call_count, 0)) call_count,
             SUM(NVL(call.mis, 0)) mis,
             SUM(NVL(call.r, 0)) r,
             SUM(NVL(call.recu_c, 0)) recu_c,
             SUM(NVL(call.recu_e, 0)) recu_e,
             SUM(NVL(call.recu_p, 0)) recu_p,
             SUM(NVL(call.recu_cr, 0)) recu_cr,
             SUM(NVL(call.recu_cu, 0)) recu_cu,
             SUM(NVL(call.recu_call_count, 0)) recu_call_count,
             SUM(NVL(call.recu_mis, 0)) recu_mis,
             SUM(NVL(call.recu_r, 0)) recu_r,
             SUM(NVL(call.self_wait_count_idle, 0)) self_wait_count_idle,
             SUM(NVL(call.self_wait_count_non_idle, 0)) self_wait_count_non_idle,
             SUM(NVL(call.self_wait_ela_idle, 0)) self_wait_ela_idle,
             SUM(NVL(call.self_wait_ela_non_idle, 0)) self_wait_ela_non_idle,
             SUM(NVL(call.recu_wait_count_idle, 0)) recu_wait_count_idle,
             SUM(NVL(call.recu_wait_count_non_idle, 0)) recu_wait_count_non_idle,
             SUM(NVL(call.recu_wait_ela_idle, 0)) recu_wait_ela_idle,
             SUM(NVL(call.recu_wait_ela_non_idle, 0)) recu_wait_ela_non_idle
        FROM trca$_tool_exec_call call
       WHERE call.tool_execution_id = p_tool_execution_id
         AND recursive = p_recursive;
    END insert_total;

  BEGIN /* tool_call_total */
    print_log('-> tool_call_total');
    insert_total('N');
    insert_total('Y');

    SELECT SUM(NVL(e, 0) - (CASE WHEN recursive = 'N' THEN NVL(recu_e, 0) ELSE 0 END) + NVL(self_wait_ela_idle, 0)),
           SUM(NVL(e, 0) - (CASE WHEN recursive = 'N' THEN NVL(recu_e, 0) ELSE 0 END)),
           SUM(NVL(c, 0) - (CASE WHEN recursive = 'N' THEN NVL(recu_c, 0) ELSE 0 END))
      INTO l_accounted_for_response_time,
           l_elapsed_time,
           l_cpu_time
      FROM trca$_tool_exec_call
     WHERE tool_execution_id = p_tool_execution_id
       AND call = trca$g.CALL_TOTAL;

    UPDATE trca$_tool_execution
       SET accounted_for_response_time = l_accounted_for_response_time,
           elapsed_time = l_elapsed_time,
           cpu_time = l_cpu_time
     WHERE id = p_tool_execution_id;

    COMMIT;
    trca$g.gather_table_stats('trca$_tool_exec_call');
    print_log('<- tool_call_total');
  END tool_call_total;

  /*************************************************************************************/

  /* -------------------------
   *
   * private group_call
   *
   * ------------------------- */
  PROCEDURE group_call (
    p_tool_execution_id IN INTEGER )
  IS
    /* -------------------------
     *
     * tool_call.insert_missing
     *
     * ------------------------- */
    PROCEDURE insert_missing (
      p_group_id IN INTEGER,
      p_dep      IN INTEGER,
      p_call     IN VARCHAR2 )
    IS
      l_count INTEGER;
      l_plh   INTEGER;
    BEGIN /* insert_missing */
      SELECT COUNT(*)
        INTO l_count
        FROM trca$_group_call
       WHERE tool_execution_id = p_tool_execution_id
         AND group_id = p_group_id
         AND call = p_call;

      IF l_count > 0 THEN
        RETURN;
      END IF;

      SELECT MAX(plh)
        INTO l_plh
        FROM trca$_group_call
       WHERE tool_execution_id = p_tool_execution_id
         AND group_id = p_group_id;

      INSERT INTO trca$_group_call (
        tool_execution_id,
        group_id,
        call,
        -- aggregate stats (this plus direct children)
        c,
        e,
        p,
        cr,
        cu,
        -- non aggregate stats (this)
        call_count,
        mis,
        r,
        -- attributes
        dep,
        plh,
        -- recursive call metrics (direct children)
        recu_c,
        recu_e,
        recu_p,
        recu_cr,
        recu_cu,
        recu_call_count,
        recu_mis,
        recu_r,
        -- recursive waits metrics
        self_wait_count_idle,
        self_wait_count_non_idle,
        self_wait_ela_idle,
        self_wait_ela_non_idle,
        recu_wait_count_idle,
        recu_wait_count_non_idle,
        recu_wait_ela_idle,
        recu_wait_ela_non_idle
      )
      SELECT p_tool_execution_id,
             p_group_id,
             p_call,
             0 c,
             0 e,
             0 p,
             0 cr,
             0 cu,
             0 call_count,
             0 mis,
             0 r,
             p_dep,
             l_plh,
             0 recu_c,
             0 recu_e,
             0 recu_p,
             0 recu_cr,
             0 recu_cu,
             0 recu_call_count,
             0 recu_mis,
             0 recu_r,
             0 self_wait_count_idle,
             0 self_wait_count_non_idle,
             0 self_wait_ela_idle,
             0 self_wait_ela_non_idle,
             0 recu_wait_count_idle,
             0 recu_wait_count_non_idle,
             0 recu_wait_ela_idle,
             0 recu_wait_ela_non_idle
        FROM DUAL;
    END insert_missing;

  BEGIN /* group_call */
    print_log('-> group_call');
    INSERT INTO trca$_group_call (
      tool_execution_id,
      group_id,
      call,
      -- aggregate stats (this plus direct children)
      c,
      e,
      p,
      cr,
      cu,
      -- non aggregate stats (this)
      call_count,
      mis,
      r,
      -- attributes
      dep,
      plh,
      -- recursive call metrics (direct children)
      recu_c,
      recu_e,
      recu_p,
      recu_cr,
      recu_cu,
      recu_call_count,
      recu_mis,
      recu_r,
      -- recursive waits metrics
      self_wait_count_idle,
      self_wait_count_non_idle,
      self_wait_ela_idle,
      self_wait_ela_non_idle,
      recu_wait_count_idle,
      recu_wait_count_non_idle,
      recu_wait_ela_idle,
      recu_wait_ela_non_idle
    )
    SELECT p_tool_execution_id,
           call.group_id,
           call.call,
           SUM(NVL(call.c, 0)) c,
           SUM(NVL(call.e, 0)) e,
           SUM(NVL(call.p, 0)) p,
           SUM(NVL(call.cr, 0)) cr,
           SUM(NVL(call.cu, 0)) cu,
           COUNT(*) call_count,
           SUM(NVL(call.mis, 0)) mis,
           SUM(NVL(call.r, 0)) r,
           MIN(call.dep) dep,
           MAX(call.plh) plh,
           SUM(NVL(call.recu_c, 0)) recu_c,
           SUM(NVL(call.recu_e, 0)) recu_e,
           SUM(NVL(call.recu_p, 0)) recu_p,
           SUM(NVL(call.recu_cr, 0)) recu_cr,
           SUM(NVL(call.recu_cu, 0)) recu_cu,
           SUM(NVL(call.recu_call_count, 0)) recu_call_count,
           SUM(NVL(call.recu_mis, 0)) recu_mis,
           SUM(NVL(call.recu_r, 0)) recu_r,
           SUM(NVL(call.self_wait_count_idle, 0)) self_wait_count_idle,
           SUM(NVL(call.self_wait_count_non_idle, 0)) self_wait_count_non_idle,
           SUM(NVL(call.self_wait_ela_idle, 0)) self_wait_ela_idle,
           SUM(NVL(call.self_wait_ela_non_idle, 0)) self_wait_ela_non_idle,
           SUM(NVL(call.recu_wait_count_idle, 0)) recu_wait_count_idle,
           SUM(NVL(call.recu_wait_count_non_idle, 0)) recu_wait_count_non_idle,
           SUM(NVL(call.recu_wait_ela_idle, 0)) recu_wait_ela_idle,
           SUM(NVL(call.recu_wait_ela_non_idle, 0)) recu_wait_ela_non_idle
      FROM trca$_call call
     WHERE call.tool_execution_id = p_tool_execution_id
     GROUP BY
           call.group_id,
           call.call;

    FOR i IN (SELECT id, dep FROM trca$_group WHERE tool_execution_id = p_tool_execution_id)
    LOOP
      insert_missing(i.id, i.dep, trca$g.CALL_PARSE);
      insert_missing(i.id, i.dep, trca$g.CALL_EXEC);
      insert_missing(i.id, i.dep, trca$g.CALL_FETCH);
    END LOOP;

    -- stores plh for group
    FOR i IN (SELECT group_id,
                     MAX(plh) plh
                FROM trca$_group_call
               WHERE tool_execution_id = p_tool_execution_id
               GROUP BY group_id)
    LOOP
      UPDATE trca$_group
         SET plh = i.plh
       WHERE tool_execution_id = p_tool_execution_id
         AND id = i.group_id;
    END LOOP;

    COMMIT;
    trca$g.gather_table_stats('trca$_group_call');
    print_log('<- group_call');
  END group_call;

  /*************************************************************************************/

  /* -------------------------
   *
   * private group_call_total
   *
   * ------------------------- */
  PROCEDURE group_call_total (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* group_call_total */
    print_log('-> group_call_total');
    INSERT INTO trca$_group_call (
      tool_execution_id,
      group_id,
      call,
      -- aggregate stats (this plus direct children)
      c,
      e,
      p,
      cr,
      cu,
      -- non aggregate stats (this)
      call_count,
      mis,
      r,
      -- attributes
      dep,
      plh,
      -- recursive call metrics (direct children)
      recu_c,
      recu_e,
      recu_p,
      recu_cr,
      recu_cu,
      recu_call_count,
      recu_mis,
      recu_r,
      -- recursive waits metrics
      self_wait_count_idle,
      self_wait_count_non_idle,
      self_wait_ela_idle,
      self_wait_ela_non_idle,
      recu_wait_count_idle,
      recu_wait_count_non_idle,
      recu_wait_ela_idle,
      recu_wait_ela_non_idle
    )
    SELECT p_tool_execution_id,
           call.group_id,
           trca$g.CALL_TOTAL, -- TOTAL
           SUM(NVL(call.c, 0)) c,
           SUM(NVL(call.e, 0)) e,
           SUM(NVL(call.p, 0)) p,
           SUM(NVL(call.cr, 0)) cr,
           SUM(NVL(call.cu, 0)) cu,
           SUM(NVL(call.call_count, 0)) call_count,
           SUM(NVL(call.mis, 0)) mis,
           SUM(NVL(call.r, 0)) r,
           MIN(call.dep) dep,
           MAX(call.plh) plh,
           SUM(NVL(call.recu_c, 0)) recu_c,
           SUM(NVL(call.recu_e, 0)) recu_e,
           SUM(NVL(call.recu_p, 0)) recu_p,
           SUM(NVL(call.recu_cr, 0)) recu_cr,
           SUM(NVL(call.recu_cu, 0)) recu_cu,
           SUM(NVL(call.recu_call_count, 0)) recu_call_count,
           SUM(NVL(call.recu_mis, 0)) recu_mis,
           SUM(NVL(call.recu_r, 0)) recu_r,
           SUM(NVL(call.self_wait_count_idle, 0)) self_wait_count_idle,
           SUM(NVL(call.self_wait_count_non_idle, 0)) self_wait_count_non_idle,
           SUM(NVL(call.self_wait_ela_idle, 0)) self_wait_ela_idle,
           SUM(NVL(call.self_wait_ela_non_idle, 0)) self_wait_ela_non_idle,
           SUM(NVL(call.recu_wait_count_idle, 0)) recu_wait_count_idle,
           SUM(NVL(call.recu_wait_count_non_idle, 0)) recu_wait_count_non_idle,
           SUM(NVL(call.recu_wait_ela_idle, 0)) recu_wait_ela_idle,
           SUM(NVL(call.recu_wait_ela_non_idle, 0)) recu_wait_ela_non_idle
      FROM trca$_group_call call
     WHERE call.tool_execution_id = p_tool_execution_id
     GROUP BY
           call.group_id;

    COMMIT;
    trca$g.gather_table_stats('trca$_group_call');
    print_log('<- group_call_total');
  END group_call_total;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_group_rank_rt
   *
   * ------------------------- */
  PROCEDURE compute_group_rank_rt (
    p_tool_execution_id IN INTEGER )
  IS
    l_rank         INTEGER := 0;
    l_contribution NUMBER;
    l_top_sql      CHAR(1);
    l_include_details CHAR(1);
    l_exec_count INTEGER;
    l_rows_processed INTEGER;
    tool_rec trca$_tool_execution%ROWTYPE;
    grp_rec trca$_group%ROWTYPE;

  BEGIN /* compute_group_rank_rt */
    print_log('-> compute_group_rank_rt');
    SELECT * INTO tool_rec FROM trca$_tool_execution WHERE id = p_tool_execution_id;

    FOR i IN (SELECT group_id,
                     ((e - recu_e) + self_wait_ela_idle) response_time_self,
                     (recu_e + recu_wait_ela_idle) response_time_progeny
                FROM trca$_group_call
               WHERE tool_execution_id = p_tool_execution_id
                 AND call = trca$g.CALL_TOTAL
               ORDER BY ((e - recu_e) + self_wait_ela_idle) DESC )
    LOOP
      l_rank := l_rank + 1;

      IF tool_rec.accounted_for_response_time > 0 THEN
        l_contribution := ROUND(i.response_time_self / tool_rec.accounted_for_response_time, 6);
      ELSE
        l_contribution := NULL;
      END IF;

      IF l_contribution * 100 >= TO_NUMBER(trca$g.g_top_sql_th) THEN
        l_top_sql := 'Y';
      ELSE
        l_top_sql := 'N';
      END IF;

      BEGIN
        SELECT *
          INTO grp_rec
          FROM trca$_group
         WHERE id = i.group_id
           AND tool_execution_id = p_tool_execution_id;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('Missing group_id:"'||i.group_id);
          goto end_loop; /* RAISE 160121*/
      END;

      IF NVL(grp_rec.include_details, 'N') = 'N' THEN
        IF (l_top_sql = 'Y' OR trca$g.g_include_non_top_sql = 'Y') AND
           (l_top_sql = 'Y' OR grp_rec.dep = 0 OR trca$g.g_detail_non_top_sql = 'Y') AND
           (grp_rec.uid# <> USYS OR trca$g.g_include_internal_sql = 'Y') THEN
          l_include_details := 'Y';
        ELSE
          l_include_details := 'N';
        END IF;
      ELSE
        l_include_details := 'Y';
      END IF;

      BEGIN
        SELECT call_count
          INTO l_exec_count
          FROM trca$_group_call
         WHERE tool_execution_id = p_tool_execution_id
           AND group_id          = i.group_id
           AND call              = trca$g.call_type_exec;
      EXCEPTION
        WHEN OTHERS THEN
          l_exec_count := NULL;
      END;

      BEGIN
        SELECT r
          INTO l_rows_processed
          FROM trca$_group_call
         WHERE tool_execution_id = p_tool_execution_id
           AND group_id          = i.group_id
           AND call              = trca$g.call_type_fetch;
      EXCEPTION
        WHEN OTHERS THEN
          l_rows_processed := NULL;
      END;

      UPDATE trca$_group
         SET exec_count = l_exec_count,
             response_time_self = i.response_time_self,
             response_time_progeny = i.response_time_progeny,
             contribution = l_contribution,
             rank = l_rank,
             top_sql = l_top_sql,
             include_details = l_include_details,
             rows_processed = l_rows_processed
       WHERE id = i.group_id
         AND tool_execution_id = p_tool_execution_id;
    <<end_loop>>
	null;
    END LOOP;

    UPDATE trca$_group
       SET include_details = 'N'
     WHERE tool_execution_id = p_tool_execution_id
       AND include_details IS NULL;

    COMMIT;
    trca$g.gather_table_stats('trca$_group');
    print_log('<- compute_group_rank_rt');
  END compute_group_rank_rt;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_group_rank_et
   *
   * ------------------------- */
  PROCEDURE compute_group_rank_et (
    p_tool_execution_id IN INTEGER )
  IS
    l_rank         INTEGER := 0;
    l_contribution NUMBER;
    l_top_sql      CHAR(1);
    l_include_details CHAR(1);
    tool_rec trca$_tool_execution%ROWTYPE;
    grp_rec trca$_group%ROWTYPE;

  BEGIN /* compute_group_rank_et */
    print_log('-> compute_group_rank_et');
    SELECT * INTO tool_rec FROM trca$_tool_execution WHERE id = p_tool_execution_id;

    FOR i IN (SELECT group_id,
                     (e - recu_e) elapsed_time_self,
                     recu_e elapsed_time_progeny
                FROM trca$_group_call
               WHERE tool_execution_id = p_tool_execution_id
                 AND call = trca$g.CALL_TOTAL
               ORDER BY (e - recu_e) DESC )
    LOOP
      l_rank := l_rank + 1;
      IF tool_rec.elapsed_time > 0 THEN
        l_contribution := ROUND(i.elapsed_time_self / tool_rec.elapsed_time, 6);
      ELSE
        l_contribution := NULL;
      END IF;

      IF l_contribution * 100 >= TO_NUMBER(trca$g.g_top_sql_th) THEN
        l_top_sql := 'Y';
      ELSE
        l_top_sql := 'N';
      END IF;

      BEGIN
        SELECT *
          INTO grp_rec
          FROM trca$_group
         WHERE id = i.group_id
           AND tool_execution_id = p_tool_execution_id;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('Missing group_id:"'||i.group_id);
          goto end_loop; /* RAISE 160121*/
      END;

      IF NVL(grp_rec.include_details, 'N') = 'N' THEN
        IF l_top_sql = 'Y' THEN
          l_include_details := 'Y';
        ELSE
          l_include_details := 'N';
        END IF;
      ELSE
        l_include_details := 'Y';
      END IF;

      UPDATE trca$_group
         SET elapsed_time_self = i.elapsed_time_self,
             elapsed_time_progeny = i.elapsed_time_progeny,
             contribution_et = l_contribution,
             rank_et = l_rank,
             top_sql_et = l_top_sql,
             include_details = l_include_details
       WHERE id = i.group_id
         AND tool_execution_id = p_tool_execution_id;
		 
	 <<end_loop>>
     null;	 
    END LOOP;

    COMMIT;
    trca$g.gather_table_stats('trca$_group');
    print_log('<- compute_group_rank_et');
  END compute_group_rank_et;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_group_rank_ct
   *
   * ------------------------- */
  PROCEDURE compute_group_rank_ct (
    p_tool_execution_id IN INTEGER )
  IS
    l_rank         INTEGER := 0;
    l_contribution NUMBER;
    l_top_sql      CHAR(1);
    l_include_details CHAR(1);
    tool_rec trca$_tool_execution%ROWTYPE;
    grp_rec trca$_group%ROWTYPE;

  BEGIN /* compute_group_rank_ct */
    print_log('-> compute_group_rank_ct');
    SELECT * INTO tool_rec FROM trca$_tool_execution WHERE id = p_tool_execution_id;

    FOR i IN (SELECT group_id,
                     (c - recu_c) cpu_time_self,
                     recu_c cpu_time_progeny
                FROM trca$_group_call
               WHERE tool_execution_id = p_tool_execution_id
                 AND call = trca$g.CALL_TOTAL
               ORDER BY (c - recu_c) DESC )
    LOOP
      l_rank := l_rank + 1;
      IF tool_rec.cpu_time > 0 THEN
        l_contribution := ROUND(i.cpu_time_self / tool_rec.cpu_time, 6);
      ELSE
        l_contribution := NULL;
      END IF;

      IF l_contribution * 100 >= TO_NUMBER(trca$g.g_top_sql_th) THEN
        l_top_sql := 'Y';
      ELSE
        l_top_sql := 'N';
      END IF;

      BEGIN
        SELECT *
          INTO grp_rec
          FROM trca$_group
         WHERE id = i.group_id
           AND tool_execution_id = p_tool_execution_id;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('Missing group_id:"'||i.group_id);
          goto end_loop; /* RAISE 160121*/
      END;

      IF NVL(grp_rec.include_details, 'N') = 'N' THEN
        IF l_top_sql = 'Y' THEN
          l_include_details := 'Y';
        ELSE
          l_include_details := 'N';
        END IF;
      ELSE
        l_include_details := 'Y';
      END IF;

      UPDATE trca$_group
         SET cpu_time_self = i.cpu_time_self,
             cpu_time_progeny = i.cpu_time_progeny,
             contribution_ct = l_contribution,
             rank_ct = l_rank,
             top_sql_ct = l_top_sql,
             include_details = l_include_details
       WHERE id = i.group_id
         AND tool_execution_id = p_tool_execution_id;
		 
	 <<end_loop>>
     Null;
    END LOOP;

    COMMIT;
    trca$g.gather_table_stats('trca$_group');
    print_log('<- compute_group_rank_ct');
  END compute_group_rank_ct;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_exec_rank
   *
   * ------------------------- */
  PROCEDURE compute_exec_rank (
    p_tool_execution_id IN INTEGER )
  IS
    l_prior_group_id INTEGER;
    l_rank INTEGER := 0;
    l_grp_contribution NUMBER;
    l_trc_contribution NUMBER;
    l_top_exec         CHAR(1);
    l_first_exec       CHAR(1);
    l_last_exec        CHAR(1);
    l_top_exec_th      NUMBER;

  BEGIN /* compute_exec_rank */
    print_log('-> compute_exec_rank');
    l_top_exec_th := TO_NUMBER(trca$g.g_top_exec_th);

    FOR i IN (SELECT call.group_id,
                     grp.dep,
                     grp.first_exec_id,
                     grp.last_exec_id,
                     grp.response_time_self grp_acc_for_response_time,
                     grp.contribution,
                     grp.top_sql,
                     grp.top_sql_et,
                     grp.top_sql_ct,
                     call.exec_id,
                     SUM((NVL(call.e, 0) - NVL(call.recu_e, 0)) + NVL(call.self_wait_ela_idle, 0)) response_time_self,
                     SUM(NVL(call.recu_e, 0) + NVL(call.recu_wait_ela_idle, 0)) response_time_progeny,
                     MIN(call.tim - call.e) min_tim,
                     MAX(call.tim) max_tim,
                     MAX(call.plh) plh
                FROM trca$_call  call,
                     trca$_group grp
               WHERE call.tool_execution_id = p_tool_execution_id
                 AND call.group_id = grp.id
                 AND grp.tool_execution_id = p_tool_execution_id
                 AND (grp.include_details = 'Y' OR grp.first_exec_id = grp.last_exec_id)
               GROUP BY
                     call.group_id,
                     grp.dep,
                     grp.first_exec_id,
                     grp.last_exec_id,
                     grp.response_time_self,
                     grp.contribution,
                     grp.top_sql,
                     grp.top_sql_et,
                     grp.top_sql_ct,
                     call.exec_id
               ORDER BY
                     call.group_id,
                     SUM((NVL(call.e, 0) - NVL(call.recu_e, 0)) + NVL(call.self_wait_ela_idle, 0)) DESC )
    LOOP
      IF i.group_id <> l_prior_group_id THEN
        l_rank := 0;
      END IF;
      l_rank := l_rank + 1;
      IF i.grp_acc_for_response_time > 0 THEN
        l_grp_contribution := ROUND(i.response_time_self / i.grp_acc_for_response_time, 6);
        l_trc_contribution := ROUND(l_grp_contribution * i.contribution, 6);
        IF l_grp_contribution * 100 >= l_top_exec_th THEN
          l_top_exec := 'Y';
        ELSE
          l_top_exec := 'N';
        END IF;
      ELSE
        l_grp_contribution := NULL;
        l_trc_contribution := NULL;
        l_top_exec := 'N';
      END IF;
      IF i.exec_id = i.first_exec_id THEN
        l_first_exec := 'Y';
      ELSE
        l_first_exec := 'N';
      END IF;
      IF i.exec_id = i.last_exec_id THEN
        l_last_exec := 'Y';
      ELSE
        l_last_exec := 'N';
      END IF;

      IF --i.dep = 0 OR
         i.first_exec_id = i.last_exec_id OR
         ((i.top_sql = 'Y' OR i.top_sql_et = 'Y' OR i.top_sql_ct = 'Y' OR trca$g.g_detail_non_top_sql = 'Y') AND
          (l_first_exec = 'Y' OR l_last_exec = 'Y' OR l_top_exec = 'Y')) THEN
        INSERT INTO trca$_exec (
          id,
          group_id,
          tool_execution_id,
          dep,
          plh,
          start_tim,
          end_tim,
          response_time_self,
          response_time_progeny,
          grp_contribution,
          trc_contribution,
          first_exec,
          last_exec,
          top_exec,
          rank
        ) VALUES (
          i.exec_id,
          i.group_id,
          p_tool_execution_id,
          i.dep,
          i.plh,
          i.min_tim,
          i.max_tim,
          i.response_time_self,
          i.response_time_progeny,
          l_grp_contribution,
          l_trc_contribution,
          l_first_exec,
          l_last_exec,
          l_top_exec,
          l_rank
        );
      END IF;
      l_prior_group_id := i.group_id;
    END LOOP;

    COMMIT;
    trca$g.gather_table_stats('trca$_exec');
    print_log('<- compute_exec_rank');
  END compute_exec_rank;

  /*************************************************************************************/

  /* -------------------------
   *
   * private group_exec_call
   *
   * ------------------------- */
  PROCEDURE group_exec_call (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* group_exec_call */
    print_log('-> group_exec_call');
    INSERT INTO trca$_group_exec_call (
      tool_execution_id,
      group_id,
      exec_id,
      call,
      -- aggregate stats (this plus direct children)
      c,
      e,
      p,
      cr,
      cu,
      -- non aggregate stats (this)
      call_count,
      mis,
      r,
      -- attributes
      dep,
      plh,
      -- recursive call metrics (direct children)
      recu_c,
      recu_e,
      recu_p,
      recu_cr,
      recu_cu,
      recu_call_count,
      recu_mis,
      recu_r,
      -- recursive waits metrics
      self_wait_count_idle,
      self_wait_count_non_idle,
      self_wait_ela_idle,
      self_wait_ela_non_idle,
      recu_wait_count_idle,
      recu_wait_count_non_idle,
      recu_wait_ela_idle,
      recu_wait_ela_non_idle
    )
    SELECT p_tool_execution_id,
           call.group_id,
           call.exec_id,
           call.call,
           SUM(NVL(call.c, 0)) c,
           SUM(NVL(call.e, 0)) e,
           SUM(NVL(call.p, 0)) p,
           SUM(NVL(call.cr, 0)) cr,
           SUM(NVL(call.cu, 0)) cu,
           COUNT(*) call_count,
           SUM(NVL(call.mis, 0)) mis,
           SUM(NVL(call.r, 0)) r,
           MIN(call.dep) dep,
           MAX(call.plh) plh,
           SUM(NVL(call.recu_c, 0)) recu_c,
           SUM(NVL(call.recu_e, 0)) recu_e,
           SUM(NVL(call.recu_p, 0)) recu_p,
           SUM(NVL(call.recu_cr, 0)) recu_cr,
           SUM(NVL(call.recu_cu, 0)) recu_cu,
           SUM(NVL(call.recu_call_count, 0)) recu_call_count,
           SUM(NVL(call.recu_mis, 0)) recu_mis,
           SUM(NVL(call.recu_r, 0)) recu_r,
           SUM(NVL(call.self_wait_count_idle, 0)) self_wait_count_idle,
           SUM(NVL(call.self_wait_count_non_idle, 0)) self_wait_count_non_idle,
           SUM(NVL(call.self_wait_ela_idle, 0)) self_wait_ela_idle,
           SUM(NVL(call.self_wait_ela_non_idle, 0)) self_wait_ela_non_idle,
           SUM(NVL(call.recu_wait_count_idle, 0)) recu_wait_count_idle,
           SUM(NVL(call.recu_wait_count_non_idle, 0)) recu_wait_count_non_idle,
           SUM(NVL(call.recu_wait_ela_idle, 0)) recu_wait_ela_idle,
           SUM(NVL(call.recu_wait_ela_non_idle, 0)) recu_wait_ela_non_idle
      FROM trca$_call call,
           trca$_exec exe
     WHERE call.tool_execution_id = p_tool_execution_id
       AND call.exec_id = exe.id
       AND exe.tool_execution_id = p_tool_execution_id
     GROUP BY
           call.group_id,
           call.exec_id,
           call.call;

    COMMIT;
    trca$g.gather_table_stats('trca$_group_exec_call');
    print_log('<- group_exec_call');
  END group_exec_call;

  /*************************************************************************************/

  /* -------------------------
   *
   * private group_exec_call_total
   *
   * ------------------------- */
  PROCEDURE group_exec_call_total (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* group_exec_call_total */
    print_log('-> group_exec_call_total');
    INSERT INTO trca$_group_exec_call (
      tool_execution_id,
      group_id,
      exec_id,
      call,
      -- aggregate stats (this plus direct children)
      c,
      e,
      p,
      cr,
      cu,
      -- non aggregate stats (this)
      call_count,
      mis,
      r,
      -- attributes
      dep,
      plh,
      -- recursive call metrics (direct children)
      recu_c,
      recu_e,
      recu_p,
      recu_cr,
      recu_cu,
      recu_call_count,
      recu_mis,
      recu_r,
      -- recursive waits metrics
      self_wait_count_idle,
      self_wait_count_non_idle,
      self_wait_ela_idle,
      self_wait_ela_non_idle,
      recu_wait_count_idle,
      recu_wait_count_non_idle,
      recu_wait_ela_idle,
      recu_wait_ela_non_idle
    )
    SELECT p_tool_execution_id,
           call.group_id,
           call.exec_id,
           trca$g.CALL_TOTAL, -- TOTAL
           SUM(NVL(call.c, 0)) c,
           SUM(NVL(call.e, 0)) e,
           SUM(NVL(call.p, 0)) p,
           SUM(NVL(call.cr, 0)) cr,
           SUM(NVL(call.cu, 0)) cu,
           SUM(NVL(call.call_count, 0)) call_count,
           SUM(NVL(call.mis, 0)) mis,
           SUM(NVL(call.r, 0)) r,
           MIN(call.dep) dep,
           MAX(call.plh) plh,
           SUM(NVL(call.recu_c, 0)) recu_c,
           SUM(NVL(call.recu_e, 0)) recu_e,
           SUM(NVL(call.recu_p, 0)) recu_p,
           SUM(NVL(call.recu_cr, 0)) recu_cr,
           SUM(NVL(call.recu_cu, 0)) recu_cu,
           SUM(NVL(call.recu_call_count, 0)) recu_call_count,
           SUM(NVL(call.recu_mis, 0)) recu_mis,
           SUM(NVL(call.recu_r, 0)) recu_r,
           SUM(NVL(call.self_wait_count_idle, 0)) self_wait_count_idle,
           SUM(NVL(call.self_wait_count_non_idle, 0)) self_wait_count_non_idle,
           SUM(NVL(call.self_wait_ela_idle, 0)) self_wait_ela_idle,
           SUM(NVL(call.self_wait_ela_non_idle, 0)) self_wait_ela_non_idle,
           SUM(NVL(call.recu_wait_count_idle, 0)) recu_wait_count_idle,
           SUM(NVL(call.recu_wait_count_non_idle, 0)) recu_wait_count_non_idle,
           SUM(NVL(call.recu_wait_ela_idle, 0)) recu_wait_ela_idle,
           SUM(NVL(call.recu_wait_ela_non_idle, 0)) recu_wait_ela_non_idle
      FROM trca$_group_exec_call call
     WHERE call.tool_execution_id = p_tool_execution_id
     GROUP BY
           call.group_id,
           call.exec_id;

    COMMIT;
    trca$g.gather_table_stats('trca$_group_exec_call');
    print_log('<- group_exec_call_total');
  END group_exec_call_total;

  /*************************************************************************************/

  /* -------------------------
   *
   * private group_wait
   *
   * ------------------------- */
  PROCEDURE group_wait (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* group_wait */
    IF trca$g.g_include_waits = 'N' THEN
      RETURN;
    END IF;
    print_log('-> group_wait');

    INSERT INTO trca$_group_wait (
      tool_execution_id,
      group_id,
      event#,
      ela,
      wait_count,
      max_ela,
      blocks
    )
    SELECT p_tool_execution_id,
           call.group_id,
           wait.event#,
           SUM(NVL(wait.ela, 0)) ela,
           COUNT(*) wait_count,
           MAX(wait.ela) max_ela,
           SUM(CASE WHEN event.parameter1v LIKE 'file%' AND event.parameter3v LIKE 'block%' THEN NVL(wait.p3, 0) END) blocks
      FROM trca$_wait            wait,
           trca$_call            call,
           trca$_wait_event_name event
     WHERE wait.tool_execution_id  = p_tool_execution_id
       AND wait.call_id            = call.id
       AND call.tool_execution_id  = p_tool_execution_id
       AND wait.event#             = event.event#
       AND event.tool_execution_id = p_tool_execution_id
     GROUP BY
           call.group_id,
           wait.event#;

    COMMIT;
    trca$g.gather_table_stats('trca$_group_wait');
    print_log('<- group_wait');
  END group_wait;

  /*************************************************************************************/

  /* -------------------------
   *
   * private group_exec_wait
   *
   * ------------------------- */
  PROCEDURE group_exec_wait (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* group_exec_wait */
    IF trca$g.g_include_waits = 'N' THEN
      RETURN;
    END IF;
    print_log('-> group_exec_wait');

    INSERT INTO trca$_group_exec_wait (
      tool_execution_id,
      group_id,
      exec_id,
      event#,
      ela,
      wait_count,
      max_ela,
      blocks
    )
    SELECT p_tool_execution_id,
           call.group_id,
           call.exec_id,
           wait.event#,
           SUM(NVL(wait.ela, 0)) ela,
           COUNT(*) wait_count,
           MAX(wait.ela) max_ela,
           SUM(CASE WHEN event.parameter1v LIKE 'file%' AND event.parameter3v LIKE 'block%' THEN NVL(wait.p3, 0) END) blocks
      FROM trca$_wait            wait,
           trca$_call            call,
           trca$_wait_event_name event,
           trca$_exec            exe
     WHERE wait.tool_execution_id  = p_tool_execution_id
       AND wait.call_id            = call.id
       AND call.tool_execution_id  = p_tool_execution_id
       AND wait.event#             = event.event#
       AND event.tool_execution_id = p_tool_execution_id
       AND call.exec_id            = exe.id
       AND exe.tool_execution_id   = p_tool_execution_id
     GROUP BY
           call.group_id,
           call.exec_id,
           wait.event#;

    COMMIT;
    trca$g.gather_table_stats('trca$_group_exec_wait');
    print_log('<- group_exec_wait');
  END group_exec_wait;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tool_wait
   *
   * ------------------------- */
  PROCEDURE tool_wait (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* tool_wait */
    print_log('-> tool_wait');
    INSERT INTO trca$_tool_wait (
      tool_execution_id,
      dep,
      event#,
      ela,
      wait_count,
      max_ela,
      blocks
    )
    SELECT p_tool_execution_id,
           grp.dep,
           gw.event#,
           SUM(NVL(gw.ela, 0)),
           SUM(NVL(gw.wait_count, 0)),
           MAX(gw.max_ela),
           SUM(NVL(gw.blocks, 0))
      FROM trca$_group_wait gw,
           trca$_group      grp
     WHERE gw.tool_execution_id  = p_tool_execution_id
       AND gw.group_id           = grp.id
       AND grp.tool_execution_id = p_tool_execution_id
     GROUP BY
           grp.dep,
           gw.event#;

    COMMIT;
    trca$g.gather_table_stats('trca$_tool_wait');
    print_log('<- tool_wait');
  END tool_wait;

  /*************************************************************************************/

  /* -------------------------
   *
   * private group_wait_segment
   *
   * ------------------------- */
  PROCEDURE group_wait_segment (
    p_tool_execution_id IN INTEGER )
  IS
    objects BOOLEAN := FALSE;
    obj_rec trca$_objects%ROWTYPE;
    max_file_id INTEGER;

  BEGIN /* group_wait_segment */
    IF trca$g.g_include_waits = 'N' THEN
      RETURN;
    END IF;

    print_log('-> group_wait_segment_seed_objects');
    max_file_id := TO_NUMBER(trca$g.g_dict_db_files);

    FOR i IN (SELECT DISTINCT
                     wait.obj#
                FROM trca$_wait            wait,
                     trca$_wait_event_name event,
                     trca$_call            call,
                     trca$_group           grp
               WHERE wait.tool_execution_id  = p_tool_execution_id
                 AND wait.obj#               > 0
                 AND wait.p1                 <= max_file_id -- permanent segments
                 AND wait.event#             = event.event#
                 AND event.tool_execution_id = p_tool_execution_id
                 AND event.parameter1v       LIKE 'file%'
                 AND event.parameter2v       IN ('block#', 'first dba')
                 AND wait.call_id            = call.id
                 AND call.tool_execution_id  = p_tool_execution_id
                 AND call.group_id           = grp.id
                 AND grp.tool_execution_id   = p_tool_execution_id
                 AND grp.uid#                <> USYS)
    LOOP
      objects := TRUE;
      obj_rec := NULL;
      obj_rec.tool_execution_id := p_tool_execution_id;
      obj_rec.object_id         := i.obj#;

      BEGIN
        SELECT object_type,
               owner,
               object_name,
               subobject_name
          INTO obj_rec.object_type,
               obj_rec.owner,
               obj_rec.object_name,
               obj_rec.subobject_name
          FROM trca$_objects$
         WHERE object_id = i.obj#
           AND (object_type LIKE 'TABLE%' OR object_type LIKE 'INDEX%' OR object_type = 'MATERIALIZED VIEW' OR object_type = 'CLUSTER');
     EXCEPTION
       WHEN OTHERS THEN
         NULL;
     END;

     INSERT INTO trca$_objects VALUES obj_rec;
    END LOOP;
    print_log('<- group_wait_segment_seed_objects');

    IF objects THEN
      print_log('-> group_wait_segment_objects');
      -- only if there were known objects (p1 <= max_file_id AND obj# > 0 AND uid# <> USYS)
      INSERT INTO trca$_group_wait_segment (
        tool_execution_id,
        group_id,
        event#,
        ela,
        wait_count,
        max_ela,
        start_tim,
        end_tim,
        blocks,
        obj#,
        segment_type,
        owner,
        segment_name,
        partition_name
      )
      SELECT p_tool_execution_id,
             call.group_id,
             wait.event#,
             SUM(NVL(wait.ela, 0)) ela,
             COUNT(*) wait_count,
             MAX(wait.ela) max_ela,
             MIN(wait.tim - wait.ela) start_tim,
             MAX(wait.tim) end_tim,
             SUM(CASE WHEN event.parameter3v LIKE 'block%' THEN NVL(wait.p3, 0) END) blocks,
             wait.obj#,
             obj.object_type segment_type,
             obj.owner,
             obj.object_name segment_name,
             obj.subobject_name partition_name
        FROM trca$_wait            wait,
             trca$_wait_event_name event,
             trca$_call            call,
             trca$_group           grp,
             trca$_objects         obj
       WHERE wait.tool_execution_id  = p_tool_execution_id
         AND wait.obj#               > 0 -- include only those records where obj# is provided
         AND wait.p1                 <= max_file_id -- permanent segments
         AND wait.event#             = event.event#
         AND event.tool_execution_id = p_tool_execution_id
         AND event.idle              = 'N'
         AND event.parameter1v       LIKE 'file%'
         AND event.parameter2v       IN ('block#', 'first dba')
         AND wait.call_id            = call.id
         AND call.tool_execution_id  = p_tool_execution_id
         AND call.group_id           = grp.id
         AND grp.tool_execution_id   = p_tool_execution_id
         AND grp.uid#                <> USYS -- exclude SYS
         AND wait.obj#               = obj.object_id
         AND obj.tool_execution_id   = p_tool_execution_id
       GROUP BY
             call.group_id,
             wait.event#,
             wait.obj#,
             obj.object_type,
             obj.owner,
             obj.object_name,
             obj.subobject_name;
      print_log('<- group_wait_segment_objects');
    END IF;

    -- permanent segments (p1 <= max_file_id AND (obj# <= 0 OR uid# = USYS))
    print_log('-> group_wait_segment_permanent');
    INSERT INTO trca$_group_wait_segment (
      tool_execution_id,
      group_id,
      event#,
      ela,
      wait_count,
      max_ela,
      start_tim,
      end_tim,
      blocks,
      obj#,
      segment_type,
      owner,
      segment_name,
      partition_name
    )
    SELECT /*+ ORDERED */
           p_tool_execution_id,
           call.group_id,
           wait.event#,
           SUM(NVL(wait.ela, 0)) ela,
           COUNT(*) wait_count,
           MAX(wait.ela) max_ela,
           MIN(wait.tim - wait.ela) start_tim,
           MAX(wait.tim) end_tim,
           SUM(CASE WHEN event.parameter3v LIKE 'block%' THEN NVL(wait.p3, 0) END) blocks,
           NULL obj#,
           ext.segment_type,
           ext.owner,
           ext.segment_name,
           ext.partition_name
      FROM trca$_wait            wait,
           trca$_wait_event_name event,
           trca$_call            call,
           trca$_group           grp,
           trca$_extents         ext
     WHERE wait.tool_execution_id  = p_tool_execution_id
       AND wait.p1                 <= max_file_id -- permanent segments
       AND wait.event#             = event.event#
       AND event.tool_execution_id = p_tool_execution_id
       AND event.idle              = 'N'
       AND event.parameter1v       LIKE 'file%'
       AND event.parameter2v       IN ('block#', 'first dba')
       AND wait.call_id            = call.id
       AND call.tool_execution_id  = p_tool_execution_id
       AND call.group_id           = grp.id
       AND grp.tool_execution_id   = p_tool_execution_id
       AND (grp.uid#               = USYS OR NVL(wait.obj#, -1) <= 0) -- Only SYS or when obj# was not provided
       AND wait.p1                 = ext.file_id
       AND wait.p2                 BETWEEN ext.block_id_from AND ext.block_id_to
     GROUP BY
           call.group_id,
           wait.event#,
           ext.segment_type,
           ext.owner,
           ext.segment_name,
           ext.partition_name;
    print_log('<- group_wait_segment_permanent');

    -- temporary segments (p1 > max_file_id)
    print_log('-> group_wait_segment_temporary');
    INSERT INTO trca$_group_wait_segment (
      tool_execution_id,
      group_id,
      event#,
      ela,
      wait_count,
      max_ela,
      start_tim,
      end_tim,
      blocks,
      obj#,
      segment_type,
      owner,
      segment_name,
      partition_name
    )
    SELECT p_tool_execution_id,
           call.group_id,
           wait.event#,
           SUM(NVL(wait.ela, 0)) ela,
           COUNT(*) wait_count,
           MAX(wait.ela) max_ela,
           MIN(wait.tim - wait.ela) start_tim,
           MAX(wait.tim) end_tim,
           SUM(CASE WHEN event.parameter3v LIKE 'block%' THEN NVL(wait.p3, 0) END) blocks,
           NULL obj#,
           'TEMPORARY' segment_type,
           NULL owner,
           NULL segment_name,
           NULL partition_name
      FROM trca$_wait            wait,
           trca$_wait_event_name event,
           trca$_call            call
     WHERE wait.tool_execution_id  = p_tool_execution_id
       AND wait.p1                 > max_file_id -- temporary segments
       AND wait.event#             = event.event#
       AND event.tool_execution_id = p_tool_execution_id
       AND event.idle              = 'N'
       AND event.parameter1v       LIKE 'file%'
       AND event.parameter2v       IN ('block#', 'first dba')
       AND wait.call_id            = call.id
       AND call.tool_execution_id  = p_tool_execution_id
     GROUP BY
           call.group_id,
           wait.event#;
    print_log('<- group_wait_segment_temporary');

    COMMIT;
    trca$g.gather_table_stats('trca$_group_wait_segment');
  END group_wait_segment;

  /*************************************************************************************/

  /* -------------------------
   *
   * private group_exec_wait_segment
   *
   * ------------------------- */
  PROCEDURE group_exec_wait_segment (
    p_tool_execution_id IN INTEGER )
  IS
    objects INTEGER;
    max_file_id INTEGER;

  BEGIN /* group_exec_wait_segment */
    IF trca$g.g_include_waits = 'N' THEN
      RETURN;
    END IF;

    max_file_id := TO_NUMBER(trca$g.g_dict_db_files);

    SELECT COUNT(*)
      INTO objects
      FROM trca$_objects
     WHERE tool_execution_id = p_tool_execution_id
       AND ROWNUM = 1;

    IF objects > 0 THEN
      print_log('-> group_exec_wait_segment_objects');
      -- only if there were known objects (p1 <= max_file_id AND obj# > 0 AND uid# <> USYS)
      INSERT INTO trca$_group_exec_wait_segment (
        tool_execution_id,
        group_id,
        exec_id,
        event#,
        ela,
        wait_count,
        max_ela,
        start_tim,
        end_tim,
        blocks,
        obj#,
        segment_type,
        owner,
        segment_name,
        partition_name
      )
      SELECT p_tool_execution_id,
             call.group_id,
             call.exec_id,
             wait.event#,
             SUM(NVL(wait.ela, 0)) ela,
             COUNT(*) wait_count,
             MAX(wait.ela) max_ela,
             MIN(wait.tim - wait.ela) start_tim,
             MAX(wait.tim) end_tim,
             SUM(CASE WHEN event.parameter3v LIKE 'block%' THEN NVL(wait.p3, 0) END) blocks,
             wait.obj#,
             obj.object_type segment_type,
             obj.owner,
             obj.object_name segment_name,
             obj.subobject_name partition_name
        FROM trca$_wait            wait,
             trca$_wait_event_name event,
             trca$_call            call,
             trca$_exec            exe,
             trca$_group           grp,
             trca$_objects         obj
       WHERE wait.tool_execution_id  = p_tool_execution_id
         AND wait.obj#               > 0 -- include only those records where obj# is provided
         AND wait.p1                 <= max_file_id -- permanent segments
         AND wait.event#             = event.event#
         AND event.tool_execution_id = p_tool_execution_id
         AND event.idle              = 'N'
         AND event.parameter1v       LIKE 'file%'
         AND event.parameter2v       IN ('block#', 'first dba')
         AND wait.call_id            = call.id
         AND call.tool_execution_id  = p_tool_execution_id
         AND call.exec_id            = exe.id
         AND exe.tool_execution_id   = p_tool_execution_id
         AND call.group_id           = grp.id
         AND grp.tool_execution_id   = p_tool_execution_id
         AND grp.uid#                <> USYS -- exclude SYS
         AND wait.obj#               = obj.object_id
         AND obj.tool_execution_id   = p_tool_execution_id
       GROUP BY
             call.group_id,
             call.exec_id,
             wait.event#,
             wait.obj#,
             obj.object_type,
             obj.owner,
             obj.object_name,
             obj.subobject_name;
      print_log('<- group_exec_wait_segment_objects');
    END IF;

    -- permanent segments (p1 <= max_file_id AND (obj# <= 0 OR uid# = USYS))
    print_log('-> group_exec_wait_segment_permanent');
    INSERT INTO trca$_group_exec_wait_segment (
      tool_execution_id,
      group_id,
      exec_id,
      event#,
      ela,
      wait_count,
      max_ela,
      start_tim,
      end_tim,
      blocks,
      obj#,
      segment_type,
      owner,
      segment_name,
      partition_name
    )
    SELECT /*+ ORDERED */
           p_tool_execution_id,
           call.group_id,
           call.exec_id,
           wait.event#,
           SUM(NVL(wait.ela, 0)) ela,
           COUNT(*) wait_count,
           MAX(wait.ela) max_ela,
           MIN(wait.tim - wait.ela) start_tim,
           MAX(wait.tim) end_tim,
           SUM(CASE WHEN event.parameter3v LIKE 'block%' THEN NVL(wait.p3, 0) END) blocks,
           NULL obj#,
           ext.segment_type,
           ext.owner,
           ext.segment_name,
           ext.partition_name
      FROM trca$_wait            wait,
           trca$_wait_event_name event,
           trca$_call            call,
           trca$_exec            exe,
           trca$_group           grp,
           trca$_extents         ext
     WHERE wait.tool_execution_id  = p_tool_execution_id
       AND wait.p1                 <= max_file_id -- permanent segments
       AND wait.event#             = event.event#
       AND event.tool_execution_id = p_tool_execution_id
       AND event.idle              = 'N'
       AND event.parameter1v       LIKE 'file%'
       AND event.parameter2v       IN ('block#', 'first dba')
       AND wait.call_id            = call.id
       AND call.tool_execution_id  = p_tool_execution_id
       AND call.exec_id            = exe.id
       AND exe.tool_execution_id   = p_tool_execution_id
       AND call.group_id           = grp.id
       AND grp.tool_execution_id   = p_tool_execution_id
       AND (grp.uid#               = USYS OR NVL(wait.obj#, -1) <= 0) -- Only SYS or when obj# was not provided
       AND wait.p1                 = ext.file_id
       AND wait.p2                 BETWEEN ext.block_id_from AND ext.block_id_to
     GROUP BY
           call.group_id,
           call.exec_id,
           wait.event#,
           ext.segment_type,
           ext.owner,
           ext.segment_name,
           ext.partition_name;
    print_log('<- group_exec_wait_segment_permanent');

    -- temporary segments (p1 > max_file_id)
    print_log('-> group_exec_wait_segment_objects_temporary');
    INSERT INTO trca$_group_exec_wait_segment (
      tool_execution_id,
      group_id,
      exec_id,
      event#,
      ela,
      wait_count,
      max_ela,
      start_tim,
      end_tim,
      blocks,
      obj#,
      segment_type,
      owner,
      segment_name,
      partition_name
    )
    SELECT p_tool_execution_id,
           call.group_id,
           call.exec_id,
           wait.event#,
           SUM(NVL(wait.ela, 0)) ela,
           COUNT(*) wait_count,
           MAX(wait.ela) max_ela,
           MIN(wait.tim - wait.ela) start_tim,
           MAX(wait.tim) end_tim,
           SUM(CASE WHEN event.parameter3v LIKE 'block%' THEN NVL(wait.p3, 0) END) blocks,
           NULL obj#,
           'TEMPORARY' segment_type,
           NULL owner,
           NULL segment_name,
           NULL partition_name
      FROM trca$_wait            wait,
           trca$_wait_event_name event,
           trca$_call            call,
           trca$_exec            exe
     WHERE wait.tool_execution_id  = p_tool_execution_id
       AND wait.p1                 > max_file_id -- temporary segments
       AND wait.event#             = event.event#
       AND event.tool_execution_id = p_tool_execution_id
       AND event.idle              = 'N'
       AND event.parameter1v       LIKE 'file%'
       AND event.parameter2v       IN ('block#', 'first dba')
       AND wait.call_id            = call.id
       AND call.tool_execution_id  = p_tool_execution_id
       AND call.exec_id            = exe.id
       AND exe.tool_execution_id   = p_tool_execution_id
     GROUP BY
           call.group_id,
           call.exec_id,
           wait.event#;
    print_log('<- group_exec_wait_segment_objects_temporary');

    COMMIT;
    trca$g.gather_table_stats('trca$_group_exec_wait_segment');
  END group_exec_wait_segment;

  /*************************************************************************************/

  /* -------------------------
   *
   * private tool_wait_segment
   *
   * ------------------------- */
  PROCEDURE tool_wait_segment (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* tool_wait_segment */
    print_log('-> tool_wait_segment');
    INSERT INTO trca$_tool_wait_segment (
      tool_execution_id,
      dep,
      event#,
      ela,
      wait_count,
      max_ela,
      start_tim,
      end_tim,
      blocks,
      obj#,
      segment_type,
      owner,
      segment_name,
      partition_name
    )
    SELECT p_tool_execution_id,
           grp.dep,
           gws.event#,
           SUM(NVL(gws.ela, 0)),
           SUM(NVL(gws.wait_count, 0)),
           MAX(gws.max_ela),
           MIN(gws.start_tim) start_tim,
           MAX(gws.end_tim) end_tim,
           SUM(NVL(gws.blocks, 0)),
           gws.obj#,
           gws.segment_type,
           gws.owner,
           gws.segment_name,
           gws.partition_name
      FROM trca$_group_wait_segment gws,
           trca$_group              grp
     WHERE gws.tool_execution_id = p_tool_execution_id
       AND gws.group_id          = grp.id
       AND grp.tool_execution_id = p_tool_execution_id
     GROUP BY
           grp.dep,
           gws.event#,
           gws.obj#,
           gws.segment_type,
           gws.owner,
           gws.segment_name,
           gws.partition_name;

    COMMIT;
    trca$g.gather_table_stats('trca$_tool_wait_segment');
    print_log('<- tool_wait_segment');
  END tool_wait_segment;

  /*************************************************************************************/

  /* -------------------------
   *
   * private hot_block
   *
   * ------------------------- */
  PROCEDURE hot_block (
    p_tool_execution_id IN INTEGER )
  IS
    max_file_id INTEGER;
    l_count INTEGER;
    l_obj_count INTEGER;

  BEGIN /* hot_block */
    IF trca$g.g_include_waits = 'N' OR TO_NUMBER(trca$g.g_hot_block_th) = 0 THEN
      RETURN;
    END IF;

    print_log('-> hot_block');
    max_file_id := TO_NUMBER(trca$g.g_dict_db_files);

    INSERT INTO trca$_hot_block (
      tool_execution_id,
      p1,
      p2,
      ela,
      wait_count,
      max_ela,
      obj#
    )
    SELECT p_tool_execution_id, p1, p2, ela, wait_count, max_ela, obj#
      FROM (
    SELECT /*+ NO_MERGE */
           wait.p1,
           wait.p2,
           CASE WHEN grp.uid# <> USYS THEN wait.obj# END obj#,
           SUM(NVL(wait.ela, 0)) ela,
           COUNT(*) wait_count,
           MAX(wait.ela) max_ela
      FROM trca$_wait            wait,
           trca$_wait_event_name event,
           trca$_call            call,
           trca$_group           grp
     WHERE wait.tool_execution_id  = p_tool_execution_id
       AND wait.p1                 <= max_file_id -- permanent segments
       AND wait.event#             = event.event#
       AND event.tool_execution_id = p_tool_execution_id
       AND event.idle              = 'N'
       AND event.parameter1v       LIKE 'file%'
       AND event.parameter2v       IN ('block#', 'first dba')
       AND wait.call_id            = call.id
       AND call.tool_execution_id  = p_tool_execution_id
       AND call.group_id           = grp.id
       AND grp.tool_execution_id   = p_tool_execution_id
     GROUP BY
           wait.p1,
           wait.p2,
           CASE WHEN grp.uid# <> USYS THEN wait.obj# END
     ORDER BY
           COUNT(*) DESC,
           SUM(NVL(wait.ela, 0)) DESC
           ) v
     WHERE ROWNUM <= TO_NUMBER(trca$g.g_hot_block_th)
     UNION
    SELECT p_tool_execution_id, p1, p2, ela, wait_count, max_ela, obj#
      FROM (
    SELECT /*+ NO_MERGE */
           wait.p1,
           wait.p2,
           CASE WHEN grp.uid# <> USYS THEN wait.obj# END obj#,
           SUM(NVL(wait.ela, 0)) ela,
           COUNT(*) wait_count,
           MAX(wait.ela) max_ela
      FROM trca$_wait            wait,
           trca$_wait_event_name event,
           trca$_call            call,
           trca$_group           grp
     WHERE wait.tool_execution_id  = p_tool_execution_id
       AND wait.p1                 <= max_file_id -- permanent segments
       AND wait.event#             = event.event#
       AND event.tool_execution_id = p_tool_execution_id
       AND event.idle              = 'N'
       AND event.parameter1v       LIKE 'file%'
       AND event.parameter2v       IN ('block#', 'first dba')
       AND wait.call_id            = call.id
       AND call.tool_execution_id  = p_tool_execution_id
       AND call.group_id           = grp.id
       AND grp.tool_execution_id   = p_tool_execution_id
     GROUP BY
           wait.p1,
           wait.p2,
           CASE WHEN grp.uid# <> USYS THEN wait.obj# END
     ORDER BY
           SUM(NVL(wait.ela, 0)) DESC,
           COUNT(*) DESC
           ) v
     WHERE ROWNUM <= TO_NUMBER(trca$g.g_hot_block_th);
    print_log('<- hot_block');

    print_log('-> hot_block_segment');
    SELECT COUNT(*), SUM(CASE WHEN obj# IS NOT NULL THEN 1 ELSE 0 END)
      INTO l_count, l_obj_count
      FROM trca$_hot_block
     WHERE tool_execution_id = p_tool_execution_id;

    IF l_obj_count > 0 THEN
      INSERT INTO trca$_hot_block_segment (
        tool_execution_id,
        p1,
        p2,
        ela,
        wait_count,
        max_ela,
        obj#,
        segment_type,
        owner,
        segment_name,
        partition_name
      )
      SELECT h.tool_execution_id,
             h.p1,
             h.p2,
             h.ela,
             h.wait_count,
             h.max_ela,
             h.obj#,
             o.object_type segment_type,
             o.owner,
             o.object_name segment_name,
             o.subobject_name partition_name
        FROM trca$_hot_block h,
             trca$_objects   o
       WHERE h.tool_execution_id = p_tool_execution_id
         AND h.obj#              IS NOT NULL
         AND h.obj#              = o.object_id(+)
         AND h.tool_execution_id = o.tool_execution_id(+);
    END IF;

    IF l_count > l_obj_count THEN
      INSERT INTO trca$_hot_block_segment (
        tool_execution_id,
        p1,
        p2,
        ela,
        wait_count,
        max_ela,
        obj#,
        segment_type,
        owner,
        segment_name,
        partition_name
      )
      SELECT h.tool_execution_id,
             h.p1,
             h.p2,
             h.ela,
             h.wait_count,
             h.max_ela,
             h.obj#,
             e.segment_type,
             e.owner,
             e.segment_name,
             e.partition_name
        FROM trca$_hot_block h,
             trca$_extents   e
       WHERE h.tool_execution_id = p_tool_execution_id
         AND h.obj#              IS NULL
         AND h.p1                = e.file_id
         AND h.p2                BETWEEN e.block_id_from AND e.block_id_to;
    END IF;

    INSERT INTO trca$_hot_block_segment (
      tool_execution_id,
      p1,
      p2,
      ela,
      wait_count,
      max_ela,
      obj#,
      segment_type,
      owner,
      segment_name,
      partition_name
    )
    SELECT h.tool_execution_id,
           h.p1,
           h.p2,
           h.ela,
           h.wait_count,
           h.max_ela,
           h.obj#,
           NULL segment_type,
           NULL owner,
           NULL segment_name,
           NULL partition_name
      FROM trca$_hot_block h
     WHERE h.tool_execution_id = p_tool_execution_id
       AND NOT EXISTS (
    SELECT NULL
      FROM trca$_hot_block_segment s
     WHERE h.tool_execution_id = s.tool_execution_id
       AND h.p1                = s.p1
       AND h.p2                = s.p2 );

    COMMIT;
    trca$g.gather_table_stats('trca$_hot_block_segment');
    print_log('<- hot_block_segment');
  END hot_block;

  /*************************************************************************************/

  /* -------------------------
   *
   * private row_source_plans
   *
   * ------------------------- */
  PROCEDURE row_source_plans (
    p_tool_execution_id IN INTEGER )
  IS
    new_rec trca$_stat_exec%ROWTYPE;
    rsp_rec trca$_row_source_plan%ROWTYPE;
    rsps_rec trca$_row_source_plan_session%ROWTYPE;
    first_time BOOLEAN := TRUE;
    sessions INTEGER := 0;

    TYPE depth_tabletype IS
      TABLE OF INTEGER
      INDEX BY PLS_INTEGER; -- depth
    -- instance of associative array
    depth_table depth_tabletype;

  BEGIN /* row_source_plans */
    -- 1st sanity check
    print_log('-> stat 1st_sanity_check');
    FOR i IN (SELECT exec_id, id, COUNT(*) l_count
                FROM trca$_stat
               WHERE tool_execution_id = p_tool_execution_id
               GROUP BY
                     exec_id, id
              HAVING COUNT(*) > 1)
    LOOP
      print_log('delete dupl STAT exec_id='||i.exec_id||' id='||i.id||' count='||i.l_count);
    END LOOP;

    DELETE trca$_stat
     WHERE tool_execution_id = p_tool_execution_id
       AND (exec_id, id) IN (
    SELECT exec_id, id
      FROM trca$_stat
     WHERE tool_execution_id = p_tool_execution_id
     GROUP BY
           exec_id, id
    HAVING COUNT(*) > 1 )
       AND ROWID NOT IN (
    SELECT MIN(ROWID)
      FROM trca$_stat
     WHERE tool_execution_id = p_tool_execution_id
     GROUP BY
           exec_id, id
    HAVING COUNT(*) > 1 );
    print_log('<- stat 1st_sanity_check');

    -- 2nd sanity check
    print_log('-> stat 2nd_sanity_check');
    FOR i IN (SELECT exec_id, MIN(id) min_id, MAX(id) max_id, COUNT(*) l_count
                FROM trca$_stat
               WHERE tool_execution_id = p_tool_execution_id
               GROUP BY
                     exec_id
              HAVING MIN(id) <> 1
                  OR MAX(id) - MIN(id) <> COUNT(*) - 1)
    LOOP
      print_log('delete bogus STAT exec_id='||i.exec_id||' min(id)='||i.min_id||' max(id)='||i.max_id||' count='||i.l_count);
    END LOOP;

    DELETE trca$_stat
     WHERE tool_execution_id = p_tool_execution_id
       AND exec_id IN (
    SELECT exec_id
      FROM trca$_stat
     WHERE tool_execution_id = p_tool_execution_id
     GROUP BY
           exec_id
    HAVING MIN(id) <> 1
        OR MAX(id) - MIN(id) <> COUNT(*) - 1);
    print_log('<- stat 2nd_sanity_check');

    -- generate plan hash value
    print_log('-> plan_hash_value');
    FOR i IN (SELECT *
                FROM trca$_stat
               WHERE tool_execution_id = p_tool_execution_id
                 AND id > 0
                 --AND group_id IS NOT NULL
               ORDER BY
                     exec_id,
                     id)
    LOOP
      IF first_time THEN
        new_rec.exec_id              := i.exec_id;
        new_rec.group_id             := i.group_id;
        new_rec.tool_execution_id    := i.tool_execution_id;
        new_rec.trca_plan_hash_value := 0;
        first_time := FALSE;
      END IF;

      IF i.exec_id <> new_rec.exec_id THEN
        new_rec.trca_plan_hash_value := MOD(new_rec.trca_plan_hash_value, POWER(2, 33));
        INSERT INTO trca$_stat_exec VALUES new_rec;
        new_rec.exec_id              := i.exec_id;
        new_rec.group_id             := i.group_id;
        new_rec.tool_execution_id    := i.tool_execution_id;
        new_rec.trca_plan_hash_value := 0;
      END IF;

      new_rec.trca_plan_hash_value := new_rec.trca_plan_hash_value  + SYS.DBMS_UTILITY.GET_HASH_VALUE(i.id||TRIM(' ' FROM i.op), 0, POWER(2, 30));
    END LOOP;

    IF new_rec.trca_plan_hash_value > 0 THEN
      new_rec.trca_plan_hash_value := MOD(new_rec.trca_plan_hash_value, POWER(2, 33));
      INSERT INTO trca$_stat_exec VALUES new_rec;
    END IF;
    print_log('<- plan_hash_value');

    -- stores row source plans per group
    print_log('-> row_source_plans');
    INSERT INTO trca$_group_row_source_plan (
      tool_execution_id,
      group_id,
      trca_plan_hash_value,
      first_exec_id
    )
    SELECT p_tool_execution_id,
           group_id,
           trca_plan_hash_value,
           MIN(exec_id) first_exec_id
      FROM trca$_stat_exec
     WHERE tool_execution_id = p_tool_execution_id
     GROUP BY
           group_id,
           trca_plan_hash_value;
    -- generate row source plans
    depth_table(0) := -1;
    FOR i IN (SELECT stat.tool_execution_id,
                     stat.group_id,
                     exec.trca_plan_hash_value,
                     stat.id,
                     MIN(stat.pid) pid,
                     SUM(NVL(stat.cnt, 0)) cnt,
                     MIN(stat.pos) pos,
                     MIN(stat.obj) obj,
                     MIN(stat.op) op,
                     SUM(NVL(stat.cr, 0)) cr,
                     SUM(NVL(stat.pr, 0)) pr,
                     SUM(NVL(stat.pw, 0)) pw,
                     SUM(NVL(stat.time, 0)) time,
                     MAX(stat.cost) cost,
                     MAX(stat.siz) siz,
                     MAX(stat.card) card,
                     COUNT(DISTINCT stat.session_id) sessions
                FROM trca$_stat      stat,
                     trca$_stat_exec exec
               WHERE stat.tool_execution_id = p_tool_execution_id
                 AND stat.exec_id           = exec.exec_id
                 AND stat.group_id          = exec.group_id
                 AND stat.tool_execution_id = exec.tool_execution_id
               GROUP BY
                     stat.tool_execution_id,
                     stat.group_id,
                     exec.trca_plan_hash_value,
                     stat.id
               ORDER BY
                     stat.tool_execution_id,
                     stat.group_id,
                     exec.trca_plan_hash_value,
                     stat.id)
    LOOP
      rsp_rec.tool_execution_id    := i.tool_execution_id;
      rsp_rec.group_id             := i.group_id;
      rsp_rec.trca_plan_hash_value := i.trca_plan_hash_value;
      rsp_rec.id                   := i.id;
      rsp_rec.pid                  := i.pid;
      rsp_rec.cnt                  := i.cnt;
      rsp_rec.pos                  := i.pos;
      rsp_rec.obj                  := i.obj;
      rsp_rec.op                   := i.op;
      rsp_rec.cr                   := i.cr;
      rsp_rec.pr                   := i.pr;
      rsp_rec.pw                   := i.pw;
      rsp_rec.time                 := i.time;
      rsp_rec.cost                 := i.cost;
      rsp_rec.siz                  := i.siz;
      rsp_rec.card                 := i.card;
      rsp_rec.sessions             := i.sessions;

      BEGIN
        rsp_rec.depth                := depth_table(i.pid) + 1;
        depth_table(i.id)            := rsp_rec.depth;
      EXCEPTION
        WHEN OTHERS THEN
        print_log('*** group_id:'||i.group_id||' trca_plan_hash_value:'||i.trca_plan_hash_value||' id:'||i.id||' pid:'||i.pid);
        print_log('*** '||SQLERRM);
      END;

      IF i.pid >= 0 AND i.id >= 0 THEN
        INSERT INTO trca$_row_source_plan VALUES rsp_rec;

        IF rsp_rec.sessions > sessions THEN
          sessions := rsp_rec.sessions;
        END IF;
      END IF;
    END LOOP;

    -- generate row source plans per session
    IF sessions > 1 THEN
      depth_table(0) := -1;
      FOR i IN (SELECT stat.tool_execution_id,
                       stat.group_id,
                       exec.trca_plan_hash_value,
                       stat.session_id,
                       stat.id,
                       MIN(stat.pid) pid,
                       SUM(NVL(stat.cnt, 0)) cnt,
                       MIN(stat.pos) pos,
                       MIN(stat.obj) obj,
                       MIN(stat.op) op,
                       SUM(NVL(stat.cr, 0)) cr,
                       SUM(NVL(stat.pr, 0)) pr,
                       SUM(NVL(stat.pw, 0)) pw,
                       SUM(NVL(stat.time, 0)) time,
                       MAX(stat.cost) cost,
                       MAX(stat.siz) siz,
                       MAX(stat.card) card
                  FROM trca$_stat      stat,
                       trca$_stat_exec exec
                 WHERE stat.tool_execution_id = p_tool_execution_id
                   AND stat.exec_id           = exec.exec_id
                   AND stat.group_id          = exec.group_id
                   AND stat.tool_execution_id = exec.tool_execution_id
                   AND stat.session_id        IS NOT NULL
                 GROUP BY
                       stat.tool_execution_id,
                       stat.group_id,
                       exec.trca_plan_hash_value,
                       stat.session_id,
                       stat.id
                 ORDER BY
                       stat.tool_execution_id,
                       stat.group_id,
                       exec.trca_plan_hash_value,
                       stat.session_id,
                       stat.id)
      LOOP
        rsps_rec.tool_execution_id    := i.tool_execution_id;
        rsps_rec.group_id             := i.group_id;
        rsps_rec.trca_plan_hash_value := i.trca_plan_hash_value;
        rsps_rec.session_id           := i.session_id;
        rsps_rec.id                   := i.id;
        rsps_rec.pid                  := i.pid;
        rsps_rec.cnt                  := i.cnt;
        rsps_rec.pos                  := i.pos;
        rsps_rec.obj                  := i.obj;
        rsps_rec.op                   := i.op;
        rsps_rec.cr                   := i.cr;
        rsps_rec.pr                   := i.pr;
        rsps_rec.pw                   := i.pw;
        rsps_rec.time                 := i.time;
        rsps_rec.cost                 := i.cost;
        rsps_rec.siz                  := i.siz;
        rsps_rec.card                 := i.card;

        BEGIN
          rsps_rec.depth                := depth_table(i.pid) + 1;
          depth_table(i.id)            := rsps_rec.depth;
        EXCEPTION
          WHEN OTHERS THEN
          print_log('*** group_id:'||i.group_id||' trca_plan_hash_value:'||i.trca_plan_hash_value||' session_id:'||i.session_id||' id:'||i.id||' pid:'||i.pid);
          print_log('*** '||SQLERRM);
        END;

        IF i.pid >= 0 AND i.id >= 0 THEN
          INSERT INTO trca$_row_source_plan_session VALUES rsps_rec;
        END IF;
      END LOOP;
    END IF;

    COMMIT;
    trca$g.gather_table_stats('trca$_row_source_plan');
    print_log('<- row_source_plans');
  END row_source_plans;

  /*************************************************************************************/

  /* -------------------------
   *
   * private execution_binds
   *
   * ------------------------- */
  PROCEDURE execution_binds (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* execution_binds */
    IF trca$g.g_include_binds = 'N' THEN
      RETURN;
    END IF;
    print_log('-> execution_binds');

    INSERT INTO trca$_exec_binds (
      tool_execution_id,
      group_id,
      exec_id,
      bind,
      data_type_code,
      data_type_name,
      actual_value_length,
      oacdef,
      value
    )
    SELECT b.tool_execution_id,
           e.group_id, -- b.group_id could be null
           b.exec_id,
           b.bind,
           b.oacdty data_type_code,
           (SELECT dt.name FROM trca$_data_type dt WHERE dt.id = b.oacdty) data_type_name,
           b.avl actual_value_length,
           b.oacdef, -- Y/N. N=(No oacdef for this bind)
           b.value
      FROM trca$_bind b,
           trca$_exec e
     WHERE b.tool_execution_id = p_tool_execution_id
       AND b.exec_id           = e.id
       AND e.tool_execution_id = p_tool_execution_id;

    COMMIT;
    trca$g.gather_table_stats('trca$_exec_binds');
    print_log('<- execution_binds');
  END execution_binds;

  /*************************************************************************************/

  /* -------------------------
   *
   * private trace_gaps
   *
   * ------------------------- */
  PROCEDURE trace_gaps (
    p_tool_execution_id IN INTEGER )
  IS
    l_dep INTEGER;

  BEGIN /* trace_gaps */
    IF TO_NUMBER(trca$g.g_gaps_th) = 0 THEN
      RETURN;
    END IF;
    print_log('-> trace_gaps');

    INSERT INTO trca$_gap_call (
      tool_execution_id,
      gap_id,
      call_id,
      call,
      group_id,
      dep,
      c,
      e,
      tim,
      parent_dep_id
    )
    SELECT gap.tool_execution_id,
           gap.id,
           call.id,
           call.call,
           call.group_id,
           call.dep,
           call.c,
           call.e,
           call.tim,
           call.parent_dep_id
      FROM trca$_gap  gap,
           trca$_call call
     WHERE gap.tool_execution_id = p_tool_execution_id
       AND gap.call_id_after     = call.id;

    SELECT MAX(dep)
      INTO l_dep
      FROM trca$_gap_call
     WHERE tool_execution_id = p_tool_execution_id;

    WHILE l_dep > 0
    LOOP
      INSERT INTO trca$_gap_call (
        tool_execution_id,
        gap_id,
        call_id,
        call,
        group_id,
        dep,
        c,
        e,
        tim,
        parent_dep_id
      )
      SELECT gap.tool_execution_id,
             gap.gap_id,
             call.id,
             call.call,
             call.group_id,
             call.dep,
             call.c,
             call.e,
             call.tim,
             call.parent_dep_id
        FROM trca$_gap_call gap,
             trca$_call     call
       WHERE gap.tool_execution_id = p_tool_execution_id
         AND gap.dep               = l_dep
         AND gap.parent_dep_id     = call.dep_id;

      l_dep := l_dep - 1;
    END LOOP;

    COMMIT;
    trca$g.gather_table_stats('trca$_gap_call');
    print_log('<- trace_gaps');
  END trace_gaps;

  /*************************************************************************************/

  /* -------------------------
   *
   * public first_transformation
   *
   * ------------------------- */
  PROCEDURE first_transformation (
    p_tool_execution_id IN  INTEGER )
  IS
    refresh_days NUMBER;
    l_op_name VARCHAR2(128) := LOWER(TRIM(trca$g.g_tool_administer_schema))||'.trca$t.first_transformation';
    l_totalwork NUMBER := 26;
    l_units VARCHAR2(32) := 'steps';

  BEGIN /* first_transformation */
    IF NOT trca$g.g_log_open THEN
      RETURN;
    END IF;

    print_log('=> first_transformation');

    trca$g.reset_session_longops;
    trca$g.set_session_longops (p_op_name => l_op_name, p_target => p_tool_execution_id, p_sofar => 0, p_totalwork => l_totalwork, p_target_desc => 'first_transformation', p_units => l_units);

    -- refresh tool data dictionary?
    BEGIN
      -- only consider refreshing if dict and current environment is the same (dbid and host)
      print_log('refresh tool data dictionary?');
      IF trca$g.g_tool_database_id = NVL(trca$g.g_dict_database_id, trca$g.g_tool_database_id) AND
         trca$g.g_tool_host_name = NVL(trca$g.g_dict_host_name, trca$g.g_tool_host_name) THEN
        print_log('finding same database_id and host_name, considering dictionary refresh...');
        -- only refresh if trca dictionary has aged out
        IF TO_DATE(trca$g.g_dict_refresh_date, 'YYYYMMDD') + TO_NUMBER(trca$g.g_dict_refresh_days) > TRUNC(SYSDATE) THEN
          print_log('refresh date of '||trca$g.g_dict_refresh_date||' still has not exceeded threshold of '||trca$g.g_dict_refresh_days||' days');
          print_dict_state;
          trca$g.set_session_longops (p_sofar => 1, p_totalwork => l_totalwork);
        ELSE -- refresh if data dictionary snapshot has aged out (or never has been done)
          print_log('-> refresh_trca$_dict_from_this before('||trca$g.g_dict_refresh_date||')');
          refresh_trca$_dict_from_this;
          trca$g.set_session_longops (p_sofar => 2, p_totalwork => l_totalwork);
          print_log('<- refresh_trca$_dict_from_this after('||trca$g.g_dict_refresh_date||')');
        END IF;
      ELSE
        print_dict_state;
      END IF;
    END;

    adjust_calls            (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 3, p_totalwork => l_totalwork);
    min_and_max_tim         (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 4, p_totalwork => l_totalwork);
    call_tree               (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 5, p_totalwork => l_totalwork);
    genealogy               (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 6, p_totalwork => l_totalwork);
    tool_call               (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 7, p_totalwork => l_totalwork);
    tool_call_total         (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 8, p_totalwork => l_totalwork);
    group_call              (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 9, p_totalwork => l_totalwork);
    group_call_total        (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 10, p_totalwork => l_totalwork);
    compute_group_rank_rt   (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 11, p_totalwork => l_totalwork);
    compute_group_rank_et   (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 12, p_totalwork => l_totalwork);
    compute_group_rank_ct   (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 13, p_totalwork => l_totalwork);
    compute_exec_rank       (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 14, p_totalwork => l_totalwork);
    group_exec_call         (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 15, p_totalwork => l_totalwork);
    group_exec_call_total   (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 16, p_totalwork => l_totalwork);
    group_wait              (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 17, p_totalwork => l_totalwork);
    group_exec_wait         (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 18, p_totalwork => l_totalwork);
    tool_wait               (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 19, p_totalwork => l_totalwork);
    group_wait_segment      (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 20, p_totalwork => l_totalwork);
    group_exec_wait_segment (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 21, p_totalwork => l_totalwork);
    tool_wait_segment       (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 22, p_totalwork => l_totalwork);
    hot_block               (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 23, p_totalwork => l_totalwork);
    row_source_plans        (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 24, p_totalwork => l_totalwork);
    execution_binds         (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 25, p_totalwork => l_totalwork);
    trace_gaps              (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 26, p_totalwork => l_totalwork);

    print_log('<= first_transformation');
  END first_transformation;

  /*************************************************************************************/

  /* -------------------------
   *
   * private explain_plans_ids
   *
   * ------------------------- */
  PROCEDURE explain_plans_ids (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* explain_plans_ids */
    IF trca$g.g_include_expl_plans = 'N' THEN
      RETURN;
    END IF;
    print_log('-> explain_plans_ids');
    trca$g.gather_table_stats('trca$_plan_table');

    UPDATE trca$_plan_table
       SET tool_execution_id = p_tool_execution_id,
           group_id = TO_NUMBER(SUBSTR(statement_id, INSTR(statement_id, '-') + 1))
     WHERE tool_execution_id IS NULL
       AND group_id IS NULL
       AND TO_NUMBER(SUBSTR(statement_id, 1, INSTR(statement_id, '-') - 1)) = p_tool_execution_id;

    COMMIT;
    print_log('<- explain_plans_ids');
    trca$g.gather_table_stats('trca$_plan_table');
  END explain_plans_ids;

  /*************************************************************************************/

  /* -------------------------
   *
   * private explain_plans_hash
   *
   * ------------------------- */
  PROCEDURE explain_plans_hash (
    p_tool_execution_id IN INTEGER )
  IS
    first_time BOOLEAN := TRUE;
    l_trca_plan_hash_value INTEGER;
    prior_group_id INTEGER;
    l_op VARCHAR2(32767);

  BEGIN /* explain_plans_hash */
    IF trca$g.g_include_expl_plans = 'N' THEN
      RETURN;
    END IF;
    print_log('-> explain_plans_hash');

    FOR i IN (SELECT group_id,
                     id,
                     parent_id,
                     operation,
                     options,
                     object_name,
                     partition_start,
                     partition_stop
                FROM trca$_plan_table
               WHERE tool_execution_id = p_tool_execution_id
                 AND id > 0
               ORDER BY
                     group_id,
                     id)
    LOOP
      IF first_time THEN
        prior_group_id := i.group_id;
        l_trca_plan_hash_value := 0;
        first_time := FALSE;
      END IF;

      IF i.group_id <> prior_group_id THEN
        IF l_trca_plan_hash_value > 0 THEN
          l_trca_plan_hash_value := MOD(l_trca_plan_hash_value, POWER(2, 33));
          UPDATE trca$_group
             SET trca_plan_hash_value = l_trca_plan_hash_value
           WHERE tool_execution_id = p_tool_execution_id
             AND id = prior_group_id;
        END IF;
        prior_group_id := i.group_id;
        l_trca_plan_hash_value := 0;
      END IF;

      l_op := i.operation;
      IF i.options IS NOT NULL THEN
        l_op := l_op||' '||i.options;
      END IF;
      IF i.object_name IS NOT NULL THEN
        l_op := l_op||' '||i.object_name;
      END IF;
      IF i.partition_start IS NOT NULL THEN
        l_op := l_op||' PARTITION: '||i.partition_start||' '||i.partition_stop;
      END IF;

      l_trca_plan_hash_value := l_trca_plan_hash_value + SYS.DBMS_UTILITY.GET_HASH_VALUE(i.id||l_op, 0, POWER(2, 30));
    END LOOP;

    IF l_trca_plan_hash_value > 0 THEN
      l_trca_plan_hash_value := MOD(l_trca_plan_hash_value, POWER(2, 33));
      UPDATE trca$_group
         SET trca_plan_hash_value = l_trca_plan_hash_value
       WHERE tool_execution_id = p_tool_execution_id
         AND id = prior_group_id;
    END IF;

    COMMIT;
    print_log('<- explain_plans_hash');
  END explain_plans_hash;

  /*************************************************************************************/

  /* -------------------------
   *
   * private explain_plans_rows
   *
   * ------------------------- */
  PROCEDURE explain_plans_rows (
    p_tool_execution_id IN INTEGER )
  IS
    l_actual_rows INTEGER;
  BEGIN /* explain_plans_rows */
    IF trca$g.g_include_expl_plans = 'N' THEN
      RETURN;
    END IF;
    print_log('-> explain_plans_rows');

    FOR i IN (SELECT id group_id,
                     trca_plan_hash_value,
                     exec_count,
                     rows_processed
                FROM trca$_group
               WHERE tool_execution_id    = p_tool_execution_id
                 AND trca_plan_hash_value IS NOT NULL
                 AND exec_count           > 0
               ORDER BY
                     id)
    LOOP
      l_actual_rows := NULL;
      FOR j IN (SELECT pln.ROWID row_id,
                       pln.id,
                       rsp.cnt
                  FROM trca$_plan_table      pln,
                       trca$_row_source_plan rsp
                 WHERE pln.tool_execution_id    = p_tool_execution_id
                   AND pln.group_id             = i.group_id
                   AND pln.id                   = rsp.id
                   AND rsp.tool_execution_id    = p_tool_execution_id
                   AND rsp.group_id             = i.group_id
                   AND rsp.trca_plan_hash_value = i.trca_plan_hash_value
                 ORDER BY
                       pln.id)
      LOOP
        IF j.id = 1 THEN
          l_actual_rows := j.cnt;
        END IF;

        IF l_actual_rows = i.rows_processed THEN
          UPDATE trca$_plan_table
             SET actual_rows = ROUND(j.cnt/i.exec_count)
           WHERE ROWID = j.row_id;
        ELSE
          UPDATE trca$_plan_table
             SET actual_rows = ROUND(j.cnt)
           WHERE ROWID = j.row_id;
        END IF;
      END LOOP;
    END LOOP;

    COMMIT;
    print_log('<- explain_plans_rows');
  END explain_plans_rows;

  /*************************************************************************************/

  /* -------------------------
   *
   * public extract_table_name
   *
   * ------------------------- */
  FUNCTION extract_table_name (
    p_operation IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_operation VARCHAR2(32767);
  BEGIN /* extract_table_name */
    IF p_operation IS NULL THEN
      RETURN NULL;
    END IF;

    l_operation := p_operation||' ';
    l_operation := REPLACE(l_operation, '(', ' ');
    l_operation := REPLACE(l_operation, ')', ' ');
    l_operation := REPLACE(l_operation, 'RANGE');
    l_operation := REPLACE(l_operation, 'SAMPLE');
    l_operation := REPLACE(l_operation, ' OF ');
    l_operation := REPLACE(l_operation, '  ', ' ');

    IF INSTR(p_operation, ' FULL ') > 0 THEN
      l_operation := SUBSTR(l_operation, INSTR(l_operation, ' FULL ') + 6);
      l_operation := SUBSTR(l_operation, 1, INSTR(l_operation, ' ') - 1);
    ELSIF INSTR(p_operation, ' ROWID ') > 0 THEN
      l_operation := SUBSTR(l_operation, INSTR(l_operation, ' ROWID ') + 7);
      l_operation := SUBSTR(l_operation, 1, INSTR(l_operation, ' ') - 1);
    ELSE
      l_operation := TRIM(l_operation);
      l_operation := SUBSTR(l_operation, INSTR(l_operation, ' ', -1) + 1);
    END IF;

    RETURN l_operation;
  END extract_table_name;

  /*************************************************************************************/

  /* -------------------------
   *
   * public extract_index_name
   *
   * ------------------------- */
  FUNCTION extract_index_name (
    p_operation IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_operation VARCHAR2(32767);
  BEGIN /* extract_index_name */
    IF p_operation IS NULL THEN
      RETURN NULL;
    END IF;

    l_operation := p_operation||' ';
    l_operation := REPLACE(l_operation, '(', ' ');
    l_operation := REPLACE(l_operation, ')', ' ');
    l_operation := REPLACE(l_operation, 'MIN/MAX');
    l_operation := REPLACE(l_operation, 'DESCENDING');
    l_operation := REPLACE(l_operation, ' OF ');
    l_operation := REPLACE(l_operation, '  ', ' ');

    IF INSTR(p_operation, ' SCAN ') > 0 THEN
      l_operation := SUBSTR(l_operation, INSTR(l_operation, ' ROWID ') + 6);
      l_operation := SUBSTR(l_operation, 1, INSTR(l_operation, ' ') - 1);
    ELSE
      l_operation := TRIM(l_operation);
      l_operation := SUBSTR(l_operation, INSTR(l_operation, ' ', -1) + 1);
    END IF;

    RETURN l_operation;
  END extract_index_name;

  /*************************************************************************************/

  /* -------------------------
   *
   * private segments_in_plans
   *
   * ------------------------- */
  PROCEDURE segments_in_plans (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* segments_in_plans */
    IF trca$g.g_include_expl_plans = 'N' OR trca$g.g_include_segments = 'N' THEN
      RETURN;
    END IF;
    print_log('-> segments_in_plans');

    -- row_source_plan_tables
    BEGIN
      print_log('-> row_source_plan_tables');
      DELETE trca$_pivot; -- redundant

      INSERT INTO trca$_pivot (object_name)
      -- tables in row source plan
      SELECT DISTINCT trca$t.extract_table_name(rsp.op) object_name
        FROM trca$_row_source_plan rsp,
             trca$_group           grp
       WHERE rsp.tool_execution_id = p_tool_execution_id
         AND rsp.op                LIKE 'TABLE%'
         AND rsp.group_id          = grp.id
         AND grp.tool_execution_id = p_tool_execution_id
         AND grp.include_details   = 'Y'
         AND ((grp.uid# <> USYS AND UID <> USYS) OR (grp.uid# = USYS AND UID = USYS));


      FOR i IN (SELECT DISTINCT
                       tbl.owner,
                       tbl.table_name,
                       tbl.num_rows,
                       tbl.blocks,
                       tbl.empty_blocks,
                       tbl.avg_space,
                       tbl.chain_cnt,
                       tbl.avg_row_len,
                       tbl.sample_size,
                       tbl.last_analyzed,
                       tbl.partitioned,
                       tbl.temporary,
                       tbl.global_stats
                  FROM trca$_pivot   piv,
                       trca$_tables$ tbl
                 WHERE piv.object_name = tbl.table_name)
      LOOP
        --print_log(i.table_name);
        INSERT INTO trca$_tables (
          owner,
          table_name,
          num_rows,
          blocks,
          empty_blocks,
          avg_space,
          chain_cnt,
          avg_row_len,
          sample_size,
          last_analyzed,
          partitioned,
          temporary,
          global_stats,
          tool_execution_id
        ) VALUES (
          i.owner,
          i.table_name,
          i.num_rows,
          i.blocks,
          i.empty_blocks,
          i.avg_space,
          i.chain_cnt,
          i.avg_row_len,
          i.sample_size,
          i.last_analyzed,
          i.partitioned,
          i.temporary,
          i.global_stats,
          p_tool_execution_id
        );
      END LOOP;

      COMMIT;
      trca$g.gather_table_stats('trca$_tables');
      print_log('<- row_source_plan_tables');
    END;

    -- row_source_plan_indexes
    BEGIN
      print_log('-> row_source_plan_indexes');
      DELETE trca$_pivot; -- redundant

      INSERT INTO trca$_pivot (object_name)
      -- indexes in row source plan
      SELECT DISTINCT trca$t.extract_index_name(rsp.op) object_name
        FROM trca$_row_source_plan rsp,
             trca$_group           grp
       WHERE rsp.tool_execution_id = p_tool_execution_id
         AND rsp.op                LIKE 'INDEX%'
         AND rsp.group_id          = grp.id
         AND grp.tool_execution_id = p_tool_execution_id
         AND grp.include_details   = 'Y'
         AND ((grp.uid# <> USYS AND UID <> USYS) OR (grp.uid# = USYS AND UID = USYS));

      FOR i IN (SELECT DISTINCT
                       idx.owner,
                       idx.index_name,
                       idx.index_type,
                       idx.table_owner,
                       idx.table_name,
                       idx.uniqueness,
                       idx.blevel,
                       idx.leaf_blocks,
                       idx.distinct_keys,
                       idx.avg_leaf_blocks_per_key,
                       idx.avg_data_blocks_per_key,
                       idx.clustering_factor,
                       idx.num_rows,
                       idx.sample_size,
                       idx.last_analyzed,
                       idx.partitioned,
                       idx.temporary,
                       idx.global_stats
                  FROM trca$_pivot    piv,
                       trca$_indexes$ idx
                 WHERE piv.object_name = idx.index_name)
      LOOP
        --print_log(i.index_name);
        INSERT INTO trca$_indexes (
          owner,
          index_name,
          index_type,
          table_owner,
          table_name,
          uniqueness,
          blevel,
          leaf_blocks,
          distinct_keys,
          avg_leaf_blocks_per_key,
          avg_data_blocks_per_key,
          clustering_factor,
          num_rows,
          sample_size,
          last_analyzed,
          partitioned,
          temporary,
          global_stats,
          tool_execution_id
        ) VALUES (
          i.owner,
          i.index_name,
          i.index_type,
          i.table_owner,
          i.table_name,
          i.uniqueness,
          i.blevel,
          i.leaf_blocks,
          i.distinct_keys,
          i.avg_leaf_blocks_per_key,
          i.avg_data_blocks_per_key,
          i.clustering_factor,
          i.num_rows,
          i.sample_size,
          i.last_analyzed,
          i.partitioned,
          i.temporary,
          i.global_stats,
          p_tool_execution_id
        );
      END LOOP;

      COMMIT;
      trca$g.gather_table_stats('trca$_indexes');
      print_log('<- row_source_plan_indexes');
    END;

    -- explain_plan_indexes
    BEGIN
      print_log('-> explain_plan_indexes');
      DELETE trca$_pivot; -- redundant

      INSERT INTO trca$_pivot (object_name, object_owner)
      -- indexes in explain plan
      SELECT DISTINCT pln.object_name, pln.object_owner
        FROM trca$_plan_table pln
       WHERE pln.tool_execution_id = p_tool_execution_id
         AND '~'||REPLACE(pln.operation||' '||pln.object_type, ' ', '~')||'~' LIKE '%~INDEX~%'
         AND NOT EXISTS (
      SELECT NULL
        FROM trca$_indexes idx
       WHERE idx.tool_execution_id = p_tool_execution_id
         AND idx.owner             = pln.object_owner
         AND idx.index_name        = pln.object_name );

      FOR i IN (SELECT DISTINCT
                       idx.owner,
                       idx.index_name,
                       idx.index_type,
                       idx.table_owner,
                       idx.table_name,
                       idx.uniqueness,
                       idx.blevel,
                       idx.leaf_blocks,
                       idx.distinct_keys,
                       idx.avg_leaf_blocks_per_key,
                       idx.avg_data_blocks_per_key,
                       idx.clustering_factor,
                       idx.num_rows,
                       idx.sample_size,
                       idx.last_analyzed,
                       idx.partitioned,
                       idx.temporary,
                       idx.global_stats
                  FROM trca$_pivot    piv,
                       trca$_indexes$ idx
                 WHERE piv.object_name  = idx.index_name
                   AND piv.object_owner = idx.owner )
      LOOP
        --print_log(i.index_name);
        INSERT INTO trca$_indexes (
          owner,
          index_name,
          index_type,
          table_owner,
          table_name,
          uniqueness,
          blevel,
          leaf_blocks,
          distinct_keys,
          avg_leaf_blocks_per_key,
          avg_data_blocks_per_key,
          clustering_factor,
          num_rows,
          sample_size,
          last_analyzed,
          partitioned,
          temporary,
          global_stats,
          tool_execution_id
        ) VALUES (
          i.owner,
          i.index_name,
          i.index_type,
          i.table_owner,
          i.table_name,
          i.uniqueness,
          i.blevel,
          i.leaf_blocks,
          i.distinct_keys,
          i.avg_leaf_blocks_per_key,
          i.avg_data_blocks_per_key,
          i.clustering_factor,
          i.num_rows,
          i.sample_size,
          i.last_analyzed,
          i.partitioned,
          i.temporary,
          i.global_stats,
          p_tool_execution_id
        );
      END LOOP;

      COMMIT;
      trca$g.gather_table_stats('trca$_indexes');
      print_log('<- explain_plan_indexes');
    END;

    -- explain_plan_tables
    BEGIN
      print_log('-> explain_plan_tables');
      DELETE trca$_pivot; -- redundant

      INSERT INTO trca$_pivot (object_name, object_owner)
      -- tables in explain plan but not yet in trca$_tables
      SELECT pln.object_name, pln.object_owner
        FROM trca$_plan_table pln
       WHERE pln.tool_execution_id = p_tool_execution_id
         AND '~'||REPLACE(pln.operation||' '||pln.object_type, ' ', '~')||'~' LIKE '%~TABLE~%'
         AND NOT EXISTS (
      SELECT NULL
        FROM trca$_tables tbl
       WHERE tbl.tool_execution_id = p_tool_execution_id
         AND tbl.owner             = pln.object_owner
         AND tbl.table_name        = pln.object_name )
       UNION
      -- tables referenced in trca$_indexes but not yet in trca$_tables
      SELECT idx.table_name object_name, idx.table_owner object_owner
        FROM trca$_indexes idx
       WHERE idx.tool_execution_id = p_tool_execution_id
         AND NOT EXISTS (
      SELECT NULL
        FROM trca$_tables tbl
       WHERE tbl.tool_execution_id = p_tool_execution_id
         AND tbl.owner             = idx.table_owner
         AND tbl.table_name        = idx.table_name );

      FOR i IN (SELECT DISTINCT
                       tbl.owner,
                       tbl.table_name,
                       tbl.num_rows,
                       tbl.blocks,
                       tbl.empty_blocks,
                       tbl.avg_space,
                       tbl.chain_cnt,
                       tbl.avg_row_len,
                       tbl.sample_size,
                       tbl.last_analyzed,
                       tbl.partitioned,
                       tbl.temporary,
                       tbl.global_stats
                  FROM trca$_pivot   piv,
                       trca$_tables$ tbl
                 WHERE piv.object_name  = tbl.table_name
                   AND piv.object_owner = tbl.owner)
      LOOP
        --print_log(i.table_name);
        INSERT INTO trca$_tables (
          owner,
          table_name,
          num_rows,
          blocks,
          empty_blocks,
          avg_space,
          chain_cnt,
          avg_row_len,
          sample_size,
          last_analyzed,
          partitioned,
          temporary,
          global_stats,
          tool_execution_id
        ) VALUES (
          i.owner,
          i.table_name,
          i.num_rows,
          i.blocks,
          i.empty_blocks,
          i.avg_space,
          i.chain_cnt,
          i.avg_row_len,
          i.sample_size,
          i.last_analyzed,
          i.partitioned,
          i.temporary,
          i.global_stats,
          p_tool_execution_id
        );
      END LOOP;

      COMMIT;
      trca$g.gather_table_stats('trca$_tables');
      print_log('<- explain_plan_tables');
    END;

    -- table_indexes
    BEGIN
      print_log('-> table_indexes');
      DELETE trca$_pivot; -- redundant

      INSERT INTO trca$_pivot (object_name, object_owner)
      -- indexes of tables on trca$_tables not yet in trca$_indexes
      SELECT idx.index_name object_name, idx.owner object_owner
        FROM trca$_tables   tbl,
             trca$_indexes$ idx
       WHERE tbl.tool_execution_id = p_tool_execution_id
         AND tbl.owner             = idx.table_owner
         AND tbl.table_name        = idx.table_name
         AND NOT EXISTS (
      SELECT NULL
        FROM trca$_indexes idx2
       WHERE idx2.tool_execution_id = p_tool_execution_id
         AND idx2.owner             = idx.owner
         AND idx2.index_name        = idx.index_name );

      FOR i IN (SELECT DISTINCT
                       idx.owner,
                       idx.index_name,
                       idx.index_type,
                       idx.table_owner,
                       idx.table_name,
                       idx.uniqueness,
                       idx.blevel,
                       idx.leaf_blocks,
                       idx.distinct_keys,
                       idx.avg_leaf_blocks_per_key,
                       idx.avg_data_blocks_per_key,
                       idx.clustering_factor,
                       idx.num_rows,
                       idx.sample_size,
                       idx.last_analyzed,
                       idx.partitioned,
                       idx.temporary,
                       idx.global_stats
                  FROM trca$_pivot    piv,
                       trca$_indexes$ idx
                 WHERE piv.object_name  = idx.index_name
                   AND piv.object_owner = idx.owner )
      LOOP
        --print_log(i.index_name);
        INSERT INTO trca$_indexes (
          owner,
          index_name,
          index_type,
          table_owner,
          table_name,
          uniqueness,
          blevel,
          leaf_blocks,
          distinct_keys,
          avg_leaf_blocks_per_key,
          avg_data_blocks_per_key,
          clustering_factor,
          num_rows,
          sample_size,
          last_analyzed,
          partitioned,
          temporary,
          global_stats,
          tool_execution_id
        ) VALUES (
          i.owner,
          i.index_name,
          i.index_type,
          i.table_owner,
          i.table_name,
          i.uniqueness,
          i.blevel,
          i.leaf_blocks,
          i.distinct_keys,
          i.avg_leaf_blocks_per_key,
          i.avg_data_blocks_per_key,
          i.clustering_factor,
          i.num_rows,
          i.sample_size,
          i.last_analyzed,
          i.partitioned,
          i.temporary,
          i.global_stats,
          p_tool_execution_id
        );
      END LOOP;

      COMMIT;
      trca$g.gather_table_stats('trca$_indexes');
      print_log('<- table_indexes');
    END;

    COMMIT;
    print_log('<- segments_in_plans');
  END segments_in_plans;

  /*************************************************************************************/

  /* -------------------------
   *
   * private segments_in_groups
   *
   * ------------------------- */
  PROCEDURE segments_in_groups (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* segments_in_groups */
    IF trca$g.g_include_expl_plans = 'N' OR trca$g.g_include_segments = 'N' THEN
      RETURN;
    END IF;
    print_log('-> segments_in_groups');

    -- row_source_plan_tables
    BEGIN
      print_log('-> row_source_plan_tables');
      FOR i IN (SELECT DISTINCT grp.id group_id, tbl.owner, tbl.table_name
                  FROM trca$_row_source_plan rsp,
                       trca$_group           grp,
                       trca$_tables          tbl
                 WHERE rsp.tool_execution_id = p_tool_execution_id
                   AND rsp.op                LIKE 'TABLE%'
                   AND rsp.group_id          = grp.id
                   AND grp.tool_execution_id = p_tool_execution_id
                   AND grp.include_details   = 'Y'
                   AND ((grp.uid# <> USYS AND UID <> USYS) OR (grp.uid# = USYS AND UID = USYS))
                   --AND SUBSTR(rsp.op, INSTR(rsp.op, ' ', -1) + 1) = tbl.table_name
                   AND trca$t.extract_table_name(rsp.op) = tbl.table_name
                   AND tbl.tool_execution_id = p_tool_execution_id)
      LOOP
        --print_log(i.group_id||' '||i.table_name);
        INSERT INTO trca$_group_tables (
          tool_execution_id,
          group_id,
          owner,
          table_name,
          in_row_source_plan,
          in_explain_plan
        ) VALUES (
          p_tool_execution_id,
          i.group_id,
          i.owner,
          i.table_name,
          'Y', -- in_row_source_plan
          'N'  -- in_explain_plan
        );
      END LOOP;

      COMMIT;
      trca$g.gather_table_stats('trca$_group_tables');
      print_log('<- row_source_plan_tables');
    END;

    -- row_source_plan_indexes
    BEGIN
      print_log('-> row_source_plan_indexes');
      FOR i IN (SELECT DISTINCT grp.id group_id, idx.owner, idx.index_name, idx.table_owner, idx.table_name
                  FROM trca$_row_source_plan rsp,
                       trca$_group           grp,
                       trca$_indexes         idx
                 WHERE rsp.tool_execution_id = p_tool_execution_id
                   AND rsp.op                LIKE 'INDEX%'
                   AND rsp.group_id          = grp.id
                   AND grp.tool_execution_id = p_tool_execution_id
                   AND grp.include_details   = 'Y'
                   AND ((grp.uid# <> USYS AND UID <> USYS) OR (grp.uid# = USYS AND UID = USYS))
                   --AND SUBSTR(rsp.op, INSTR(rsp.op, ' ', -1) + 1) = idx.index_name
                   AND trca$t.extract_index_name(rsp.op) = idx.index_name
                   AND idx.tool_execution_id = p_tool_execution_id)
      LOOP
        --print_log(i.group_id||' '||i.index_name);
        INSERT INTO trca$_group_indexes (
          tool_execution_id,
          group_id,
          owner,
          index_name,
          table_owner,
          table_name,
          in_row_source_plan,
          in_explain_plan
        ) VALUES (
          p_tool_execution_id,
          i.group_id,
          i.owner,
          i.index_name,
          i.table_owner,
          i.table_name,
          'Y', -- in_row_source_plan
          'N'  -- in_explain_plan
        );
      END LOOP;

      COMMIT;
      trca$g.gather_table_stats('trca$_group_indexes');
      print_log('<- row_source_plan_indexes');
    END;

    -- explain_plan_tables
    DECLARE
      l_in_explain_plan trca$_group_tables.in_explain_plan%TYPE;

    BEGIN
      print_log('-> explain_plan_tables');
      FOR i IN (SELECT DISTINCT pln.group_id, tbl.owner, tbl.table_name
                  FROM trca$_plan_table pln,
                       trca$_tables     tbl
                 WHERE pln.tool_execution_id = p_tool_execution_id
                   AND '~'||REPLACE(pln.operation||' '||pln.object_type, ' ', '~')||'~' LIKE '%~TABLE~%'
                   AND pln.object_owner      = tbl.owner
                   AND pln.object_name       = tbl.table_name
                   AND tbl.tool_execution_id = p_tool_execution_id)
      LOOP
        --print_log(i.group_id||' '||i.table_name);
        l_in_explain_plan := NULL;
        UPDATE trca$_group_tables
           SET in_explain_plan = 'Y'
         WHERE tool_execution_id = p_tool_execution_id
           AND group_id          = i.group_id
           AND owner             = i.owner
           AND table_name        = i.table_name
         RETURNING in_explain_plan INTO l_in_explain_plan;

        IF l_in_explain_plan IS NULL THEN
          INSERT INTO trca$_group_tables (
            tool_execution_id,
            group_id,
            owner,
            table_name,
            in_row_source_plan,
            in_explain_plan
          ) VALUES (
            p_tool_execution_id,
            i.group_id,
            i.owner,
            i.table_name,
            'N', -- in_row_source_plan
            'Y'  -- in_explain_plan
          );
        END IF;
      END LOOP;
      COMMIT;
      trca$g.gather_table_stats('trca$_group_tables');
      print_log('<- explain_plan_tables');
    END;

    -- explain_plan_indexes
    DECLARE
      l_in_explain_plan trca$_group_indexes.in_explain_plan%TYPE;

    BEGIN
      print_log('-> explain_plan_indexes');
      FOR i IN (SELECT DISTINCT pln.group_id, idx.owner, idx.index_name, idx.table_owner, idx.table_name
                  FROM trca$_plan_table pln,
                       trca$_indexes    idx
                 WHERE pln.tool_execution_id = p_tool_execution_id
                   --AND '~'||REPLACE(pln.operation||' '||pln.options||' '||pln.object_type, ' ', '~')||'~' LIKE '%~INDEX~%'
                   AND '~'||REPLACE(pln.operation||' '||pln.object_type, ' ', '~')||'~' LIKE '%~INDEX~%'
                   AND pln.object_owner      = idx.owner
                   AND pln.object_name       = idx.index_name
                   AND idx.tool_execution_id = p_tool_execution_id)
      LOOP
        --print_log(i.group_id||' '||i.index_name);
        l_in_explain_plan := NULL;
        UPDATE trca$_group_indexes
           SET in_explain_plan = 'Y'
         WHERE tool_execution_id = p_tool_execution_id
           AND group_id          = i.group_id
           AND owner             = i.owner
           AND index_name        = i.index_name
           AND table_owner       = i.table_owner
           AND table_name        = i.table_name
         RETURNING in_explain_plan INTO l_in_explain_plan;

        IF l_in_explain_plan IS NULL THEN
          INSERT INTO trca$_group_indexes (
            tool_execution_id,
            group_id,
            owner,
            index_name,
            table_owner,
            table_name,
            in_row_source_plan,
            in_explain_plan
          ) VALUES (
            p_tool_execution_id,
            i.group_id,
            i.owner,
            i.index_name,
            i.table_owner,
            i.table_name,
            'N', -- in_row_source_plan
            'Y'  -- in_explain_plan
          );
        END IF;
      END LOOP;

      COMMIT;
      trca$g.gather_table_stats('trca$_group_indexes');
      print_log('<- explain_plan_indexes');
    END;

    -- indexed_tables
    BEGIN
      print_log('-> indexed_tables');
      FOR i IN (SELECT idx.group_id, idx.table_owner owner, idx.table_name
                  FROM trca$_group_indexes idx
                 WHERE idx.tool_execution_id = p_tool_execution_id
                 MINUS
                SELECT tbl.group_id, tbl.owner, tbl.table_name
                  FROM trca$_group_tables tbl
                 WHERE tbl.tool_execution_id = p_tool_execution_id)
      LOOP
        --print_log(i.group_id||' '||i.table_name);
        INSERT INTO trca$_group_tables (
          tool_execution_id,
          group_id,
          owner,
          table_name,
          in_row_source_plan,
          in_explain_plan
        ) VALUES (
          p_tool_execution_id,
          i.group_id,
          i.owner,
          i.table_name,
          'N', -- in_row_source_plan
          'N'  -- in_explain_plan
        );
      END LOOP;

      COMMIT;
      trca$g.gather_table_stats('trca$_group_tables');
      print_log('<- indexed_tables');
    END;

    -- table_indexes
    BEGIN
      print_log('-> table_indexes');
      FOR i IN (SELECT tbl.group_id, idx.owner, idx.index_name, idx.table_owner, idx.table_name
                  FROM trca$_group_tables tbl,
                       trca$_indexes      idx
                 WHERE tbl.tool_execution_id = p_tool_execution_id
                   AND tbl.owner             = idx.table_owner
                   AND tbl.table_name        = idx.table_name
                   AND idx.tool_execution_id = p_tool_execution_id
                 MINUS
                SELECT idx.group_id, idx.owner, idx.index_name, idx.table_owner, idx.table_name
                  FROM trca$_group_indexes idx
                 WHERE idx.tool_execution_id = p_tool_execution_id)
      LOOP
        --print_log(i.group_id||' '||i.index_name);
        INSERT INTO trca$_group_indexes (
          tool_execution_id,
          group_id,
          owner,
          index_name,
          table_owner,
          table_name,
          in_row_source_plan,
          in_explain_plan
        ) VALUES (
          p_tool_execution_id,
          i.group_id,
          i.owner,
          i.index_name,
          i.table_owner,
          i.table_name,
          'N', -- in_row_source_plan
          'N'  -- in_explain_plan
        );
      END LOOP;

      COMMIT;
      trca$g.gather_table_stats('trca$_group_indexes');
      print_log('<- table_indexes');
    END;

    --COMMIT;
    print_log('<- segments_in_groups');
  END segments_in_groups;

  /*************************************************************************************/

  /* -------------------------
   *
   * private index_columns
   *
   * ------------------------- */
  PROCEDURE index_columns (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* index_columns */
    IF trca$g.g_include_expl_plans = 'N' OR trca$g.g_include_segments = 'N' THEN
      RETURN;
    END IF;

    -- table_columns
    BEGIN
      print_log('-> table_columns');
      INSERT INTO trca$_tab_cols (
        owner,
        table_name,
        column_name,
        column_id,
        num_distinct,
        density,
        num_nulls,
        num_buckets,
        last_analyzed,
        sample_size,
        tool_execution_id
      )
      SELECT tbl.owner,
             tbl.table_name,
             tcl.column_name,
             tcl.column_id,
             tcl.num_distinct,
             tcl.density,
             tcl.num_nulls,
             tcl.num_buckets,
             tcl.last_analyzed,
             tcl.sample_size,
             tbl.tool_execution_id
        FROM trca$_tables    tbl,
             trca$_tab_cols$ tcl
       WHERE tbl.tool_execution_id = p_tool_execution_id
         AND tbl.owner             = tcl.owner
         AND tbl.table_name        = tcl.table_name;

      COMMIT;
      trca$g.gather_table_stats('trca$_tab_cols');
      print_log('<- table_columns');
    END;

    -- index_columns
    BEGIN
      print_log('-> index_columns');
      INSERT INTO trca$_ind_columns (
        index_owner,
        index_name,
        table_owner,
        table_name,
        column_name,
        column_position,
        descend,
        tool_execution_id
      )
      SELECT idx.owner,
             idx.index_name,
             icl.table_owner,
             icl.table_name,
             icl.column_name,
             icl.column_position,
             icl.descend,
             idx.tool_execution_id
        FROM trca$_indexes      idx,
             trca$_ind_columns$ icl
       WHERE idx.tool_execution_id = p_tool_execution_id
         AND idx.owner             = icl.index_owner
         AND idx.index_name        = icl.index_name;

      COMMIT;
      trca$g.gather_table_stats('trca$_ind_columns');
      print_log('<- index_columns');
    END;

    -- indexed_columns
    DECLARE
      l_indexed_columns VARCHAR2(32767);
      l_count INTEGER;

    BEGIN
      print_log('-> indexed_columns');
      FOR i IN (SELECT ROWID row_id, owner, index_name
                  FROM trca$_indexes
                 WHERE tool_execution_id = p_tool_execution_id
                 ORDER BY
                       owner,
                       index_name)
      LOOP
        l_indexed_columns := NULL;
        l_count := 0;

        FOR j IN (SELECT column_name
                    FROM trca$_ind_columns
                   WHERE tool_execution_id = p_tool_execution_id
                     AND index_owner       = i.owner
                     AND index_name        = i.index_name
                   ORDER BY
                         column_position)
        LOOP
          l_indexed_columns := l_indexed_columns||j.column_name||' ';
          l_count := l_count + 1;
        END LOOP;

        l_indexed_columns := SUBSTR(TRIM(l_indexed_columns), 1, 4000);
        UPDATE trca$_indexes
           SET indexed_columns = l_indexed_columns,
               columns_count = l_count
         WHERE ROWID = i.row_id;
      END LOOP;

      COMMIT;
      print_log('<- indexed_columns');
    END;

    --COMMIT;
    --print_log('<- index_columns');
  END index_columns;

  /*************************************************************************************/

  /* -------------------------
   *
   * public third_transformation
   *
   * ------------------------- */
  PROCEDURE third_transformation (
    p_tool_execution_id IN INTEGER )
  IS
    l_op_name VARCHAR2(128) := LOWER(TRIM(trca$g.g_tool_administer_schema))||'.trca$t.third_transformation';
    l_totalwork NUMBER := 6;
    l_units VARCHAR2(32) := 'steps';

  BEGIN /* third_transformation */
    IF NOT trca$g.g_log_open THEN
      RETURN;
    END IF;

    print_log('=> third_transformation');

    trca$g.reset_session_longops;
    trca$g.set_session_longops (p_op_name => l_op_name, p_target => p_tool_execution_id, p_sofar => 0, p_totalwork => l_totalwork, p_target_desc => 'third_transformation', p_units => l_units);

    explain_plans_ids       (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 1, p_totalwork => l_totalwork);
    explain_plans_hash      (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 2, p_totalwork => l_totalwork);
    explain_plans_rows      (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 3, p_totalwork => l_totalwork);
    segments_in_plans       (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 4, p_totalwork => l_totalwork);
    segments_in_groups      (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 5, p_totalwork => l_totalwork);
    index_columns           (p_tool_execution_id => p_tool_execution_id);
    trca$g.set_session_longops (p_sofar => 6, p_totalwork => l_totalwork);

    print_log('<= third_transformation');
  END third_transformation;

  /*************************************************************************************/

END trca$t;
/

SET TERM ON;
SHOW ERRORS;
