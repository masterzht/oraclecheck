CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..sqlt$t AS
/* $Header: 215187.1 sqcpkgt.pkb 12.2.171004 2017/10/04 Stelios.Charalambides@oracle.com carlos.sierra mauro.pagano abel.macias $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  TOOL_REPOSITORY_SCHEMA CONSTANT VARCHAR2(32) := '&&tool_repository_schema.';
  TOOL_ADMINISTER_SCHEMA CONSTANT VARCHAR2(32) := '&&tool_administer_schema.';
  NUL                    CONSTANT CHAR(1)       := CHR(00);
  LF                     CONSTANT CHAR(1)       := CHR(10);
  CR                     CONSTANT CHAR(1)       := CHR(13);
  AMP                    CONSTANT CHAR(1)       := CHR(38);
  METADATA_DEF_CHAR      CONSTANT CHAR(1)       := CHR(94);
  METADATA_DEF_CHAR2     CONSTANT CHAR(2)       := METADATA_DEF_CHAR||METADATA_DEF_CHAR;
  NBSP                   CONSTANT VARCHAR2(32)  := AMP||'nbsp;'; -- space
  NBSP2                  CONSTANT VARCHAR2(32)  := NBSP||NBSP; -- 2 spaces
  GT                     CONSTANT VARCHAR2(32)  := AMP||'gt;'; -- >
  LT                     CONSTANT VARCHAR2(32)  := AMP||'lt;'; -- <
  DEL_O                  CONSTANT VARCHAR2(32)  := '<del>';
  DEL_C                  CONSTANT VARCHAR2(32)  := '</del>';
  LONG_DATE_FORMAT       CONSTANT VARCHAR2(32)  := 'DD-MON-YY HH24:MI:SS';
  LOAD_DATE_FORMAT       CONSTANT VARCHAR2(32)  := 'YYYY-MM-DD/HH24:MI:SS'; -- 2010-03-03/08:45:04
  SECONDS_FORMAT         CONSTANT VARCHAR2(32)  := '999999999999990D990';

  /*************************************************************************************/

  -- 171004 Extensive replacement of variables to varchar2(257)
  
  /* -------------------------
   *
   * static variables
   *
   * ------------------------- */
  s_mask_for_values VARCHAR2(128);

  /*************************************************************************************/

  /* -------------------------
   *
   * private write_log
   *
   * ------------------------- */
  PROCEDURE write_log (
    p_line_text IN VARCHAR2,
    p_line_type IN VARCHAR2 DEFAULT 'L' )
  IS
  BEGIN
    sqlt$a.write_log(p_line_text => p_line_text, p_line_type => p_line_type, p_package => 'T');
  END write_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * private write_error
   *
   * ------------------------- */
  PROCEDURE write_error (p_line_text IN VARCHAR2)
  IS
  BEGIN
    sqlt$a.write_error('t:'||p_line_text);
  END write_error;

  /*************************************************************************************/

  /* -------------------------
   *
   * public difference_percent
   *
   * ------------------------- */
  FUNCTION difference_percent (
    p_value1   IN NUMBER,
    p_value2   IN NUMBER,
    p_decimals IN NUMBER DEFAULT 1 )
  RETURN NUMBER
  IS
  BEGIN
    IF p_value1 IS NULL AND p_value2 IS NULL THEN
      RETURN NULL;
    ELSIF p_value1 IS NULL OR p_value2 IS NULL THEN
      RETURN 100;
    ELSIF p_value1 = 0 AND p_value2 = 0 THEN
      RETURN 0;
    ELSIF p_value1 = 0 OR p_value2 = 0 THEN
      RETURN 100;
    ELSIF p_value1 > 0 AND p_value2 < 0 THEN
      RETURN 100;
    ELSIF p_value1 < 0 AND p_value2 > 0 THEN
      RETURN 100;
    ELSE
      RETURN ROUND(100 * ABS(ABS(p_value1) - ABS(p_value2)) / LEAST(ABS(p_value1), ABS(p_value2)), p_decimals);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('difference_percent: '||SQLERRM);
      RETURN NULL;
  END difference_percent;

  /*************************************************************************************/

  /* -------------------------
   *
   * public differ_more_than_x_perc
   *
   * ------------------------- */
  FUNCTION differ_more_than_x_perc (
    p_value1  IN NUMBER,
    p_value2  IN NUMBER,
    p_percent IN NUMBER DEFAULT 10 )
  RETURN BOOLEAN
  IS
  BEGIN
    IF p_value1 IS NULL AND p_value2 IS NULL THEN
      RETURN FALSE;
    ELSIF p_value1 IS NULL OR p_value2 IS NULL THEN
      RETURN TRUE;
    ELSIF p_value1 = 0 AND p_value2 = 0 THEN
      RETURN FALSE;
    ELSIF p_value1 = 0 OR p_value2 = 0 THEN
      RETURN TRUE;
    ELSIF p_value1 > 0 AND p_value2 < 0 THEN
      RETURN TRUE;
    ELSIF p_value1 < 0 AND p_value2 > 0 THEN
      RETURN TRUE;
    ELSIF ABS(ABS(p_value1) - ABS(p_value2)) > LEAST(ABS(p_value1), ABS(p_value2)) * (p_percent / 100) THEN
      RETURN TRUE; -- more than p_percent%
    ELSE
      RETURN FALSE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('differ_more_than_x_perc: '||SQLERRM);
      RETURN NULL;
  END differ_more_than_x_perc;

  /*************************************************************************************/

  /* -------------------------
   *
   * public differ_more_than_x_percent
   *
   * ------------------------- */
  FUNCTION differ_more_than_x_percent (
    p_value1  IN NUMBER,
    p_value2  IN NUMBER,
    p_percent IN NUMBER DEFAULT 10 )
  RETURN VARCHAR2
  IS
    l_return BOOLEAN;
  BEGIN
    l_return := differ_more_than_x_perc(p_value1, p_value2, p_percent);

    IF l_return THEN
      RETURN 'Y';
    ELSIF NOT l_return THEN
      RETURN 'N';
    ELSE
      RETURN NULL;
    END IF;
  END differ_more_than_x_percent;

  /*************************************************************************************/

  /* -------------------------
   *
   * private put_statid_into_plan_table
   *
   * ------------------------- */
  PROCEDURE put_statid_into_plan_table (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
  BEGIN
    write_log('put_statid_into_plan_table');

    UPDATE sqlt$_sql_plan_table
       SET statid = sqlt$a.get_statid(p_statement_id)
     WHERE statement_id = sqlt$a.get_statement_id_c(p_statement_id);

    SELECT COUNT(*)
      INTO l_count
      FROM sqlt$_sql_plan_table
     WHERE statement_id = sqlt$a.get_statement_id_c(p_statement_id);

    write_log(l_count||' rows updated');
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('put_statid_into_plan_table: '||SQLERRM);
  END put_statid_into_plan_table;

  /*************************************************************************************/

  /* -------------------------
   *
   * private put_obj_id_into_tables
   *
   * ------------------------- */
  PROCEDURE put_obj_id_into_tables (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
  BEGIN
    write_log('put_obj_id_into_tables');

    FOR i IN (SELECT owner, table_name, source
                FROM sqlt$_dba_all_tables_v
               WHERE statement_id = p_statement_id)
    LOOP
      l_count := l_count + 1;
      IF i.source = 'DBA_TABLES' THEN
        UPDATE sqlt$_dba_tables
           SET object_id = sqlt$a.get_object_id(p_statement_id, 'TABLE', i.owner, i.table_name),
               owner_id = sqlt$a.get_owner_id(p_statement_id, 'TABLE', i.owner, i.table_name)
         WHERE statement_id = p_statement_id
           AND owner = i.owner
           AND table_name = i.table_name;
      ELSE
        UPDATE sqlt$_dba_object_tables
           SET object_id = sqlt$a.get_object_id(p_statement_id, 'TABLE', i.owner, i.table_name),
               owner_id = sqlt$a.get_owner_id(p_statement_id, 'TABLE', i.owner, i.table_name)
         WHERE statement_id = p_statement_id
           AND owner = i.owner
           AND table_name = i.table_name;
      END IF;
    END LOOP;

    write_log(l_count||' rows updated');
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('put_obj_id_into_tables: '||SQLERRM);
  END put_obj_id_into_tables;

  /*************************************************************************************/

  /* -------------------------
   *
   * private put_obj_id_into_indexes
   *
   * ------------------------- */
  PROCEDURE put_obj_id_into_indexes (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
  BEGIN
    write_log('put_obj_id_into_indexes');

    FOR i IN (SELECT owner, index_name, ROWID row_id
                FROM sqlt$_dba_indexes
               WHERE statement_id = p_statement_id)
    LOOP
      l_count := l_count + 1;
      UPDATE sqlt$_dba_indexes
         SET object_id = sqlt$a.get_object_id(p_statement_id, 'INDEX', i.owner, i.index_name)
       WHERE ROWID = i.row_id;
    END LOOP;

    write_log(l_count||' rows updated');
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('put_obj_id_into_indexes: '||SQLERRM);
  END put_obj_id_into_indexes;

  /*************************************************************************************/

  /* -------------------------
   *
   * private record_cbo_system_stats
   *
   * ------------------------- */
  PROCEDURE record_cbo_system_stats (p_statement_id IN NUMBER)
  IS
    sql_rec sqlt$_sql_statement%ROWTYPE;

    FUNCTION get_sys_stat (p_name IN VARCHAR2)
    RETURN VARCHAR2
    IS
      l_value VARCHAR2(32767);
    BEGIN
      SELECT pval1
        INTO l_value
        FROM sqlt$_aux_stats$
       WHERE statement_id = p_statement_id
         AND sname = 'SYSSTATS_MAIN'
         AND pname = UPPER(p_name)
         AND ROWNUM = 1;
      RETURN l_value;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NULL;
    END;

  BEGIN
    write_log('record_cbo_system_stats');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    sql_rec.synthetized_mbrc_and_readtim := 'N';
    sql_rec.cpuspeednw := get_sys_stat('cpuspeednw');
    sql_rec.cpuspeed := get_sys_stat('cpuspeed');
    sql_rec.ioseektim := get_sys_stat('ioseektim');
    sql_rec.iotfrspeed := get_sys_stat('iotfrspeed');
    sql_rec.mbrc := get_sys_stat('mbrc');
    sql_rec.sreadtim := get_sys_stat('sreadtim');
    sql_rec.mreadtim := get_sys_stat('mreadtim');
    sql_rec.maxthr := get_sys_stat('maxthr');
    sql_rec.slavethr := get_sys_stat('slavethr');

    IF sql_rec.mbrc IS NULL THEN
      sql_rec.synthetized_mbrc_and_readtim := 'Y';
      sql_rec.mbrc := GREATEST(sql_rec.udb_file_optimizer_read_count, sqlt$a.get_v$parameter('db_file_multiblock_read_count'));
    END IF;

    IF sql_rec.sreadtim IS NULL AND sql_rec.iotfrspeed > 0 THEN
      sql_rec.synthetized_mbrc_and_readtim := 'Y';
      sql_rec.sreadtim := ROUND(sql_rec.ioseektim + (sql_rec.db_block_size / sql_rec.iotfrspeed), 3);
    END IF;

    IF sql_rec.mreadtim IS NULL AND sql_rec.iotfrspeed > 0 THEN
      sql_rec.synthetized_mbrc_and_readtim := 'Y';
      sql_rec.mreadtim := ROUND(sql_rec.ioseektim + ((sql_rec.mbrc * sql_rec.db_block_size) / sql_rec.iotfrspeed), 3);
    END IF;

    IF NVL(sql_rec.cpuspeed, sql_rec.cpuspeednw) > 0 AND sql_rec.sreadtim > 0 THEN
      sql_rec.cpu_cost_scaling_factor := 1 / (NVL(sql_rec.cpuspeed, sql_rec.cpuspeednw) * 1e3 * sql_rec.sreadtim);
    END IF;

    SELECT ROUND((SUM(NVL(e.time_waited_micro, 0)) - SUM(NVL(b.time_waited_micro, 0)))/GREATEST(1, SUM(NVL(e.total_waits, 0)) - SUM(NVL(b.total_waits, 0)))/1e3, 3) avg_wait_millisecs
      INTO sql_rec.actual_sreadtim
      FROM sqlt$_gv$session_event b,
           sqlt$_gv$session_event e
     WHERE e.statement_id = p_statement_id
       AND e.begin_end_flag = 'E'
       AND e.event = 'db file sequential read'
       AND e.statement_id = b.statement_id(+)
       AND 'B' = b.begin_end_flag(+)
       AND e.inst_id = b.inst_id(+)
       AND e.event = b.event(+)
       AND e.time_waited_micro > NVL(b.time_waited_micro(+), 0);

    SELECT ROUND((SUM(NVL(e.time_waited_micro, 0)) - SUM(NVL(b.time_waited_micro, 0)))/GREATEST(1, SUM(NVL(e.total_waits, 0)) - SUM(NVL(b.total_waits, 0)))/1e3, 3) avg_wait_millisecs
      INTO sql_rec.actual_mreadtim
      FROM sqlt$_gv$session_event b,
           sqlt$_gv$session_event e
     WHERE e.statement_id = p_statement_id
       AND e.begin_end_flag = 'E'
       AND e.event = 'db file scattered read'
       AND e.statement_id = b.statement_id(+)
       AND 'B' = b.begin_end_flag(+)
       AND e.inst_id = b.inst_id(+)
       AND e.event = b.event(+)
       AND e.time_waited_micro > NVL(b.time_waited_micro(+), 0);

    UPDATE sqlt$_sql_statement
       SET cpuspeednw = sql_rec.cpuspeednw,
           cpuspeed = sql_rec.cpuspeed,
           ioseektim = sql_rec.ioseektim,
           iotfrspeed = sql_rec.iotfrspeed,
           mbrc = sql_rec.mbrc,
           sreadtim = sql_rec.sreadtim,
           mreadtim = sql_rec.mreadtim,
           maxthr = sql_rec.maxthr,
           slavethr = sql_rec.slavethr,
           cpu_cost_scaling_factor = sql_rec.cpu_cost_scaling_factor,
           synthetized_mbrc_and_readtim = sql_rec.synthetized_mbrc_and_readtim,
           actual_sreadtim = sql_rec.actual_sreadtim,
           actual_mreadtim = sql_rec.actual_mreadtim
     WHERE statement_id = p_statement_id;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('record_cbo_system_stats: '||SQLERRM);
  END record_cbo_system_stats;

  /*************************************************************************************/

  /* -------------------------
   *
   * private remap_owner
   *
   * ------------------------- */
  FUNCTION remap_owner (
    p_clob   IN CLOB,
    p_prefix IN VARCHAR2,
    p_owner  IN VARCHAR2,
    p_suffix IN VARCHAR2,
    p_owner2 IN VARCHAR2 DEFAULT NULL )
  RETURN CLOB
  IS
  BEGIN
    RETURN REPLACE(p_clob, p_prefix||p_owner||p_suffix, p_prefix||METADATA_DEF_CHAR2||'SCHEMA_'||sqlt$a.get_clean_name(NVL(p_owner2, p_owner))||'.'||p_suffix);
  END remap_owner;

  /*************************************************************************************/

  /* -------------------------
   *
   * private remove_text
   *
   * removes any text between prefix and suffix, both included.
   * for example it removes TABLESPACE "TOOLS" when prefix is TABLESPACE " and suffix is "
   *
   * ------------------------- */
  FUNCTION remove_text (
    p_clob   IN CLOB,
    p_prefix IN VARCHAR2,
    p_suffix IN VARCHAR2 )
  RETURN CLOB
  IS
    x_clob        CLOB;
    l_src_offset  INTEGER := 1;
    l_dst_offset  INTEGER := 1;
    l_len_prefix  INTEGER := LENGTH(p_prefix);
    l_len_suffix  INTEGER := LENGTH(p_suffix);
    l_len_src     INTEGER;
    l_ptr_preffix INTEGER;
    l_ptr_suffix  INTEGER;
  BEGIN
    IF p_clob IS NULL OR p_prefix IS NULL OR p_suffix IS NULL THEN
      RETURN p_clob;
    END IF;

    -- find first occurrence of prefix
    l_ptr_preffix := NVL(DBMS_LOB.INSTR (
      lob_loc => p_clob,
      pattern => p_prefix,
      offset  => l_src_offset ), 0);

    -- find first occurrence of sufix
    l_ptr_suffix := NVL(DBMS_LOB.INSTR (
      lob_loc => p_clob,
      pattern => p_suffix,
      offset  => l_ptr_preffix + l_len_prefix ), 0);

    -- prefix or suffix are not found then nothing to do
    IF l_ptr_preffix = 0 OR l_ptr_suffix = 0 THEN
      RETURN p_clob;
    END IF;

    l_len_src := SYS.DBMS_LOB.GETLENGTH(p_clob);
    SYS.DBMS_LOB.CREATETEMPORARY(x_clob, TRUE);

    WHILE l_ptr_preffix > 0 AND l_ptr_suffix > 0
    LOOP
      -- copy from source into destination first x character just before prefix
      SYS.DBMS_LOB.COPY (
        dest_lob    => x_clob,
        src_lob     => p_clob,
        amount      => l_ptr_preffix - l_src_offset,
        dest_offset => l_dst_offset,
        src_offset  => l_src_offset );

      -- updates offset of both source and destination
      l_dst_offset := l_dst_offset + l_ptr_preffix - l_src_offset;
      l_src_offset := l_ptr_suffix + l_len_suffix;

      -- find next occurrence of prefix
      l_ptr_preffix := NVL(DBMS_LOB.INSTR (
        lob_loc => p_clob,
        pattern => p_prefix,
        offset  => l_src_offset ), 0);

      -- find next occurrence of sufix
      l_ptr_suffix := NVL(DBMS_LOB.INSTR (
        lob_loc => p_clob,
        pattern => p_suffix,
        offset  => l_ptr_preffix + l_len_prefix ), 0);
    END LOOP;

    -- copy piece after last suffix
    IF l_len_src > l_src_offset THEN
      SYS.DBMS_LOB.COPY (
        dest_lob    => x_clob,
        src_lob     => p_clob,
        amount      => l_len_src - l_src_offset,
        dest_offset => l_dst_offset,
        src_offset  => l_src_offset );
    END IF;

    RETURN x_clob;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('remove_text: '||SQLERRM);
      RETURN x_clob;
  END remove_text;

  /* -------------------------
   *
   * private remove_text
   *
   * ------------------------- *
  FUNCTION remove_text (
    p_clob   IN CLOB,
    p_prefix IN VARCHAR2,
    p_suffix IN VARCHAR2 )
  RETURN CLOB
  IS
    l_begin INTEGER;
    l_end   INTEGER;
  BEGIN
    l_begin := INSTR(p_clob, p_prefix);
    IF l_begin > 0 THEN
      l_end := INSTR(p_clob, p_suffix, l_begin + LENGTH(p_prefix));
      IF l_end > l_begin THEN
        RETURN remove_text(SUBSTR(p_clob, 1, l_begin - 1)||SUBSTR(p_clob, l_end + 1), p_prefix, p_suffix);
      ELSE
        RETURN p_clob;
      END IF;
    ELSE
      RETURN p_clob;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('remove_text: '||SQLERRM);
      RETURN p_clob;
  END remove_text;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_dependency_depth
   *
   * ------------------------- */
  FUNCTION get_dependency_depth (
    p_statement_id IN NUMBER,
    p_object_type  IN VARCHAR2,
    p_object_owner IN VARCHAR2,
    p_object_name  IN VARCHAR2 )
  RETURN NUMBER
  IS
    l_object_type VARCHAR2(257) := REPLACE(REPLACE(p_object_type, '_', ' '), ' SPEC');
    l_depth NUMBER;
  BEGIN
    IF l_object_type = 'AQ QUEUE' THEN
      l_object_type := 'QUEUE';
    ELSIF l_object_type = 'XMLSCHEMA' THEN
      l_object_type := 'XML SCHEMA';
    END IF;

    SELECT MAX(depth) depth
      INTO l_depth
    FROM (
    SELECT MAX(depth) depth
      FROM sqlt$_gv$object_dependency_v
     WHERE statement_id = p_statement_id
       AND to_owner = p_object_owner
       AND to_name = p_object_name
       AND type = l_object_type
     UNION ALL
    SELECT MAX(depth) depth
      FROM sqlt$_dba_dependencies
     WHERE statement_id = p_statement_id
       AND owner = p_object_owner
       AND name = p_object_name
       AND type = l_object_type
     UNION ALL
    SELECT MAX(depth) depth
      FROM sqlt$_dba_dependencies
     WHERE statement_id = p_statement_id
       AND referenced_owner = p_object_owner
       AND referenced_name = p_object_name
       AND referenced_type = l_object_type);

    RETURN l_depth;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END get_dependency_depth;

  /*************************************************************************************/

  /* -------------------------
   *
   * private remap_metadata
   *
   * ------------------------- */
  PROCEDURE remap_metadata (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    met_rec sqlt$_metadata%ROWTYPE;
  BEGIN
    write_log('remap_metadata');

    DELETE sqlg$_pivot;
    INSERT INTO sqlg$_pivot (object_owner)
    SELECT owner
      FROM sqlt$_dba_objects
     WHERE statement_id = p_statement_id
       AND owner IS NOT NULL
     UNION
    SELECT owner
      FROM sqlt$_dba_constraints
     WHERE statement_id = p_statement_id
       AND owner IS NOT NULL
     UNION
    SELECT r_owner
      FROM sqlt$_dba_constraints
     WHERE statement_id = p_statement_id
       AND r_owner IS NOT NULL
     UNION
    SELECT owner
      FROM sqlt$_metadata
     WHERE statement_id = p_statement_id
       AND owner IS NOT NULL;

    FOR i IN (SELECT *
                FROM sqlt$_metadata
               WHERE statement_id = p_statement_id
                 AND transformed = 'Y'
                 AND owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC'))
    LOOP
      BEGIN
        --write_log('remap_metadata_begin "'||i.owner||'"."'||i.object_name||'" ('||i.object_type||')');
        met_rec := NULL;
        met_rec.statement_id := i.statement_id;
        met_rec.statid := i.statid;
        met_rec.owner := i.owner;
        met_rec.object_name := i.object_name;
        met_rec.object_type := i.object_type;
        met_rec.object_id := i.object_id;
        met_rec.transformed := i.transformed;
        met_rec.remapped := 'Y';
        met_rec.depth := get_dependency_depth(p_statement_id, i.object_type, i.owner, i.object_name);
        met_rec.metadata := i.metadata;

        FOR j IN (SELECT object_owner
                    FROM sqlg$_pivot
                   WHERE object_owner NOT IN ('SYS', 'CTXSYS', 'MDSYS', 'SYSTEM', 'PUBLIC')
                   ORDER BY LENGTH(object_owner) DESC)
        LOOP
/*
          met_rec.metadata := remap_owner(met_rec.metadata, ' "', i.owner, '"."');
          met_rec.metadata := remap_owner(met_rec.metadata, ' ', i.owner, '.');
          met_rec.metadata := remap_owner(met_rec.metadata, ' ', LOWER(i.owner), '.', i.owner);

          met_rec.metadata := remap_owner(met_rec.metadata, ',"', i.owner, '"."');
          met_rec.metadata := remap_owner(met_rec.metadata, ',', i.owner, '.');
          met_rec.metadata := remap_owner(met_rec.metadata, ',', LOWER(i.owner), '.', i.owner);

          met_rec.metadata := remap_owner(met_rec.metadata, '("', i.owner, '"."');
          met_rec.metadata := remap_owner(met_rec.metadata, '(', i.owner, '.');
          met_rec.metadata := remap_owner(met_rec.metadata, '(', LOWER(i.owner), '.', i.owner);

          met_rec.metadata := remap_owner(met_rec.metadata, LF||'"', i.owner, '"."');
          met_rec.metadata := remap_owner(met_rec.metadata, LF, i.owner, '.');
          met_rec.metadata := remap_owner(met_rec.metadata, LF, LOWER(i.owner), '.', i.owner);
          */
          met_rec.metadata := remap_owner(met_rec.metadata, ' "', j.object_owner, '"."');
          met_rec.metadata := remap_owner(met_rec.metadata, ' ', j.object_owner, '.');
          met_rec.metadata := remap_owner(met_rec.metadata, ' ', LOWER(j.object_owner), '.', j.object_owner);

          met_rec.metadata := remap_owner(met_rec.metadata, ',"', j.object_owner, '"."');
          met_rec.metadata := remap_owner(met_rec.metadata, ',', j.object_owner, '.');
          met_rec.metadata := remap_owner(met_rec.metadata, ',', LOWER(j.object_owner), '.', j.object_owner);

          met_rec.metadata := remap_owner(met_rec.metadata, '("', j.object_owner, '"."');
          met_rec.metadata := remap_owner(met_rec.metadata, '(', j.object_owner, '.');
          met_rec.metadata := remap_owner(met_rec.metadata, '(', LOWER(j.object_owner), '.', j.object_owner);

          met_rec.metadata := remap_owner(met_rec.metadata, LF||'"', j.object_owner, '"."');
          met_rec.metadata := remap_owner(met_rec.metadata, LF, j.object_owner, '.');
          met_rec.metadata := remap_owner(met_rec.metadata, LF, LOWER(j.object_owner), '.', j.object_owner);

          met_rec.metadata := remap_owner(met_rec.metadata, '"', j.object_owner, '"."');
          --met_rec.metadata := remap_owner(met_rec.metadata, '', j.object_owner, '.');
          --met_rec.metadata := remap_owner(met_rec.metadata, '', LOWER(j.object_owner), '.', j.object_owner);
        END LOOP;

        IF sqlt$a.get_rdbms_version < '11.2' THEN
          write_log('remap_metadata_remove_text_begin', 'S');
          met_rec.metadata := remove_text(met_rec.metadata, 'TABLESPACE "', '"'); -- bug 7690799 and 8372834 (fixed on 11R2)
          met_rec.metadata := remove_text(met_rec.metadata, 'STORAGE(', ')'); -- bug 7690799 and 8372834 (fixed on 11R2)
        END IF;

        write_log('remap_metadata_replace_begin', 'S');
        met_rec.metadata := REPLACE(met_rec.metadata, 'LOGGINGENABLE', 'LOGGING ENABLE');
        met_rec.metadata := REPLACE(met_rec.metadata, '   '||LF, LF);
        met_rec.metadata := REPLACE(met_rec.metadata, '  '||LF, LF);
        met_rec.metadata := REPLACE(met_rec.metadata, ' '||LF, LF);
        met_rec.metadata := REPLACE(met_rec.metadata, LF||'   ', LF);
        met_rec.metadata := REPLACE(met_rec.metadata, LF||'  ', LF);
        met_rec.metadata := REPLACE(met_rec.metadata, LF||' ', LF);
        met_rec.metadata := REPLACE(met_rec.metadata, CR, LF);
        met_rec.metadata := REPLACE(met_rec.metadata, LF||LF||LF, LF);
        met_rec.metadata := REPLACE(met_rec.metadata, LF||LF, LF);
        met_rec.metadata := sqlt$r.wrap_clob(met_rec.metadata, 1000); -- was 120
        met_rec.metadata := REPLACE(met_rec.metadata, LF||LF, LF);

        IF met_rec.metadata IS NOT NULL THEN
          IF SYS.DBMS_LOB.GETLENGTH(met_rec.metadata) > 30 THEN
            INSERT INTO sqlt$_metadata VALUES met_rec;
            COMMIT;
            l_count := l_count + 1;
          END IF;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error('cannot remap metadata for object: type="'||i.object_name||'", name="'||i.object_name||'", owner="'||i.owner||'"');
      END;
    END LOOP;

    write_log(l_count||' metadata rows remapped in sqlt$_metadata');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('remap_metadata: '||SQLERRM);
  END remap_metadata;

  /*************************************************************************************/

  /* -------------------------
   *
   * private not_shared_cursors
   *
   * ------------------------- */
  PROCEDURE not_shared_cursors (
    p_statement_id IN NUMBER,
    p_statid       IN VARCHAR2 )
  IS
    l_sql VARCHAR2(32767);
    l_count NUMBER;
    l_not_shared_reason VARCHAR2(4000);
  BEGIN
    write_log('not_shared_cursors');

    SELECT COUNT(*) INTO l_count FROM sqlt$_gv$sql_shared_cursor WHERE statement_id = p_statement_id AND ROWNUM = 1;
    IF l_count = 0 THEN
      write_log('no records');
      RETURN;
    END IF;

    DELETE sqlg$_sql_shared_cursor_n;
    FOR i IN (SELECT column_id, column_name
                FROM sys.dba_tab_columns
               WHERE owner = TOOL_REPOSITORY_SCHEMA
                 AND table_name = 'SQLT$_GV$SQL_SHARED_CURSOR'
                 AND data_type = 'VARCHAR2'
                 AND data_length = 1
               ORDER BY
                     column_id)
    LOOP
	  -- 22170177 ENQUOTE i.column_name
      l_sql :=
      'INSERT INTO sqlg$_sql_shared_cursor_n '||
      '(statement_id, inst_id, child_number, child_address, plan_hash_value, column_id, column_name) '||
      'SELECT c.statement_id, c.inst_id, c.child_number, c.child_address, s.plan_hash_value, :column_id, :column_name '||
        'FROM sqlt$_gv$sql_shared_cursor c, sqlt$_gv$sql s '||
       'WHERE c.statement_id = :statement_id '||
         'AND c.'||DBMS_ASSERT.ENQUOTE_NAME(i.column_name)||' = ''Y'' '||
         'AND c.statement_id = s.statement_id '||
         'AND c.inst_id = s.inst_id '||
         'AND c.sql_id = s.sql_id '||
         'AND c.address = s.address '||
         'AND c.child_address = s.child_address '||
         'AND c.child_number = s.child_number ';
      write_log(l_sql, 'S');

      BEGIN
        EXECUTE IMMEDIATE l_sql
        USING IN i.column_id, IN i.column_name, IN p_statement_id;
      EXCEPTION
        WHEN OTHERS THEN
          write_error(SQLERRM);
          write_error(l_sql);
          EXIT;
      END;
    END LOOP;

    SELECT COUNT(*)
      INTO l_count
      FROM sqlg$_sql_shared_cursor_n
     WHERE statement_id = p_statement_id;
    write_log(l_count||' rows inserted into sqlg$_sql_shared_cursor_n');

    FOR i IN (SELECT DISTINCT inst_id, child_number, child_address, plan_hash_value
                FROM sqlg$_sql_shared_cursor_n
               WHERE statement_id = p_statement_id)
    LOOP
      l_not_shared_reason := NULL;
      FOR j IN (SELECT column_name
                  FROM sqlg$_sql_shared_cursor_n
                 WHERE statement_id = p_statement_id
                   AND inst_id = i.inst_id
                   AND child_number = i.child_number
                   AND child_address = i.child_address
                   AND plan_hash_value = i.plan_hash_value
                 ORDER BY
                       column_id)
      LOOP
        IF l_not_shared_reason IS NULL THEN
          l_not_shared_reason := j.column_name;
        ELSE
          l_not_shared_reason := l_not_shared_reason||', '||j.column_name;
        END IF;
      END LOOP;

      INSERT INTO sqlt$_sql_shared_cursor_d
      (statement_id, statid, inst_id, child_number, child_address, plan_hash_value, not_shared_reason)
      VALUES
      (p_statement_id, p_statid, i.inst_id, i.child_number, i.child_address, i.plan_hash_value, l_not_shared_reason);
    END LOOP;

    SELECT COUNT(*)
      INTO l_count
      FROM sqlt$_sql_shared_cursor_d
     WHERE statement_id = p_statement_id;
    write_log(l_count||' rows inserted into sqlt$_sql_shared_cursor_d');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('not_shared_cursors: '||SQLERRM);
  END not_shared_cursors;

  /*************************************************************************************/

  /* -------------------------
   *
   * private apply_secure_mask
   *
   * ------------------------- */
  FUNCTION apply_secure_mask (
    p_value     IN VARCHAR2,
    p_data_type IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN
    IF NVL(LENGTH(p_value), 0) < 2 THEN
      RETURN p_value;
    ELSIF (p_data_type = 'DATE' OR p_data_type LIKE 'TIMESTAMP%') AND LENGTH(p_value) > 5 THEN
      RETURN SUBSTR(p_value, 1, 5)||RPAD('*', LENGTH(p_value) - 5, '*');
    ELSE
      RETURN SUBSTR(p_value, 1, 1)||RPAD('*', LENGTH(p_value) - 1, '*');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('apply_secure_mask: '||SQLERRM);
      RETURN '***** ERROR';
  END apply_secure_mask;

  /*************************************************************************************/

  /* -------------------------
   *
   * private apply_complete_mask
   *
   * ------------------------- */
  FUNCTION apply_complete_mask (p_value IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    IF p_value IS NULL THEN
      RETURN NULL;
    ELSE
      RETURN RPAD('*', LENGTH(p_value), '*');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('apply_complete_mask: '||SQLERRM);
      RETURN '***** ERROR';
  END apply_complete_mask;

  /*************************************************************************************/

  /* -------------------------
   *
   * private apply_mask
   *
   * ------------------------- */
  FUNCTION apply_mask (
    p_value     IN VARCHAR2,
    p_data_type IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN
    IF s_mask_for_values IS NULL THEN
      s_mask_for_values := sqlt$a.get_param('mask_for_values');
    END IF;

    IF s_mask_for_values = 'CLEAR' THEN
      RETURN p_value;
    ELSIF s_mask_for_values = 'SECURE' THEN
      RETURN apply_secure_mask(p_value, p_data_type);
    ELSIF s_mask_for_values = 'COMPLETE' THEN
      RETURN apply_complete_mask(p_value);
    ELSE
      RETURN apply_complete_mask(p_value);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('apply_mask: '||SQLERRM);
      RETURN '***** ERROR';
  END apply_mask;

  /*************************************************************************************/

  /* -------------------------
   *
   * public compute_enpoint_value
   *
   * ------------------------- */
  FUNCTION compute_enpoint_value (
    p_data_type             IN VARCHAR2,  -- sys.dba_tab_cols.data_type
    p_endpoint_value        IN NUMBER,    -- sys.dba_tab_histograms.endpoint_value
    p_endpoint_actual_value IN VARCHAR2 ) -- sys.dba_tab_histograms.endpoint_actual_value
  RETURN VARCHAR2                         -- endpoint_estimated_value
  IS
  BEGIN
    RETURN apply_mask(sqlt$s.get_enpoint_value(p_data_type, p_endpoint_value, p_endpoint_actual_value), p_data_type);
  END compute_enpoint_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * public table_histograms
   *
   * ------------------------- */
  PROCEDURE table_histograms (p_statement_id IN NUMBER)
  IS
    l_prior_endpoint_number NUMBER;
    l_gap_endpoint_number NUMBER;
    l_estimated_cardinality NUMBER;
    l_estimated_selectivity NUMBER;
    l_popular_values NUMBER;
    l_buckets_pop_vals NUMBER;
    l_new_density NUMBER;
    l_endpoint_estimated_value sqlt$_dba_tab_histograms.endpoint_estimated_value%TYPE;
    l_endpoint_popular_value sqlt$_dba_tab_histograms.endpoint_popular_value%TYPE;
    l_endpoints_count NUMBER;
    l_max_endpoint_number NUMBER;
    l_adjust_4_nulls NUMBER;

  BEGIN
    write_log('table_histograms');

    FOR i IN (SELECT c.owner,
                     c.table_name,
                     c.column_name,
                     c.data_type,
                     c.num_nulls,
                     c.num_distinct,
                     c.sample_size,
                     c.histogram,
                     c.num_buckets,
                     t.num_rows,
                     c.source c_source
                FROM sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_all_tables_v t
               WHERE c.statement_id = p_statement_id
                 AND c.sample_size > 0
                 AND c.histogram IN ('FREQUENCY', 'HEIGHT BALANCED', 'TOP-FREQUENCY', 'HYBRID')
                 AND c.num_buckets > 0
                 AND c.statement_id = t.statement_id
                 AND c.owner = t.owner
                 AND c.table_name = t.table_name
                 AND t.num_rows > 0)
    LOOP
      SELECT MAX(endpoint_number)
        INTO l_max_endpoint_number
        FROM sqlt$_dba_tab_histograms
       WHERE statement_id = p_statement_id
         AND owner = i.owner
         AND table_name = i.table_name
         AND column_name = i.column_name;

      l_prior_endpoint_number := 0;
      l_popular_values := 0;
      l_buckets_pop_vals := 0;
      l_endpoint_estimated_value := NULL;
      l_endpoint_popular_value := NULL;
      l_endpoints_count := 0;
      l_adjust_4_nulls := (i.num_rows - i.num_nulls) / GREATEST(1, i.num_rows);

      FOR j IN (SELECT endpoint_number,
                       endpoint_value,
                       endpoint_actual_value,
                       endpoint_repeat_count,
                       ROWID h_rowid
                  FROM sqlt$_dba_tab_histograms
                 WHERE statement_id = p_statement_id
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND column_name = i.column_name
                 ORDER BY
                       endpoint_number)
      LOOP
        l_endpoints_count := l_endpoints_count + 1;
        l_gap_endpoint_number := j.endpoint_number - l_prior_endpoint_number;
        l_endpoint_estimated_value := compute_enpoint_value(i.data_type, j.endpoint_value, j.endpoint_actual_value);
        l_endpoint_popular_value := NULL;
        l_prior_endpoint_number := j.endpoint_number;
        l_estimated_selectivity := l_adjust_4_nulls * l_gap_endpoint_number / GREATEST(l_max_endpoint_number, 1);
        l_estimated_cardinality := l_estimated_selectivity * i.num_rows;

        IF i.histogram = 'HEIGHT BALANCED' THEN
          IF l_gap_endpoint_number > 1 THEN -- popular value
            l_popular_values := l_popular_values + 1;
            l_buckets_pop_vals := l_buckets_pop_vals + l_gap_endpoint_number;
            l_endpoint_popular_value := l_endpoint_estimated_value;
          ELSE
            l_estimated_cardinality := NULL;
            l_estimated_selectivity := NULL;
          END IF;
        END IF;
		
        -- 12.1.04
        IF i.histogram = 'TOP-FREQUENCY' THEN
            l_estimated_cardinality := l_estimated_selectivity * GREATEST(l_max_endpoint_number, 1);
        END IF;		
		
        -- 12.1.04 (WIP bug 17491018)
        IF i.histogram = 'HYBRID' THEN
            l_estimated_cardinality := j.endpoint_repeat_count;
            l_estimated_selectivity := j.endpoint_repeat_count / GREATEST(l_max_endpoint_number, 1);
        END IF;

        UPDATE sqlt$_dba_tab_histograms
           SET endpoint_estimated_value = l_endpoint_estimated_value,
               endpoint_popular_value   = l_endpoint_popular_value,
               estimated_cardinality    = l_estimated_cardinality,
               estimated_selectivity    = l_estimated_selectivity
         WHERE ROWID = j.h_rowid;
      END LOOP;

      IF i.num_buckets > 0 AND (i.num_distinct - l_popular_values) > 0 THEN
        l_new_density := (i.num_buckets - l_buckets_pop_vals) / i.num_buckets / (i.num_distinct - l_popular_values);
      ELSE
        l_new_density := 0;
      END IF;

      IF i.c_source = 'DBA_TAB_COLS' THEN
        UPDATE sqlt$_dba_tab_cols
           SET popular_values   = l_popular_values,
               buckets_pop_vals = l_buckets_pop_vals,
               new_density      = l_new_density,
               endpoints_count  = l_endpoints_count
         WHERE statement_id = p_statement_id
           AND owner = i.owner
           AND table_name = i.table_name
           AND column_name = i.column_name;
      ELSE
        UPDATE sqlt$_dba_nested_table_cols
           SET popular_values   = l_popular_values,
               buckets_pop_vals = l_buckets_pop_vals,
               new_density      = l_new_density,
               endpoints_count  = l_endpoints_count
         WHERE statement_id = p_statement_id
           AND owner = i.owner
           AND table_name = i.table_name
           AND column_name = i.column_name;
      END IF;
    END LOOP;

    UPDATE sqlt$_dba_tab_cols
       SET endpoints_count = 0
     WHERE statement_id = p_statement_id
       AND endpoints_count IS NULL;

    UPDATE sqlt$_dba_nested_table_cols
       SET endpoints_count = 0
     WHERE statement_id = p_statement_id
       AND endpoints_count IS NULL;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('table_histograms: '||SQLERRM);
  END table_histograms;

  /*************************************************************************************/

  /* -------------------------
   *
   * public partition_histograms
   *
   * ------------------------- */
  PROCEDURE partition_histograms (p_statement_id IN NUMBER)
  IS
    l_prior_endpoint_number NUMBER;
    l_gap_endpoint_number NUMBER;
    l_estimated_cardinality NUMBER;
    l_estimated_selectivity NUMBER;
    l_popular_values NUMBER;
    l_buckets_pop_vals NUMBER;
    l_new_density NUMBER;
    l_endpoint_estimated_value sqlt$_dba_tab_histograms.endpoint_estimated_value%TYPE;
    l_endpoint_popular_value sqlt$_dba_tab_histograms.endpoint_popular_value%TYPE;
    l_endpoints_count NUMBER;
    l_max_endpoint_number NUMBER;
    l_adjust_4_nulls NUMBER;

  BEGIN
    write_log('partition_histograms');

    FOR i IN (SELECT s.owner,
                     s.table_name,
                     s.partition_name,
                     s.column_name,
                     c.data_type,
                     s.num_nulls,
                     s.num_distinct,
                     s.sample_size,
                     s.histogram,
                     s.num_buckets,
                     t.num_rows,
                     s.ROWID s_rowid
                FROM sqlt$_dba_part_col_statistics s,
                     sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_tab_partitions t
               WHERE s.statement_id = p_statement_id
                 AND s.sample_size > 0
                 AND s.histogram IN ('FREQUENCY', 'HEIGHT BALANCED', 'TOP-FREQUENCY', 'HYBRID')
                 AND s.num_buckets > 0
                 AND s.statement_id = c.statement_id
                 AND s.owner = c.owner
                 AND s.table_name = c.table_name
                 AND s.column_name = c.column_name
                 AND s.statement_id = t.statement_id
                 AND s.owner = t.table_owner
                 AND s.table_name = t.table_name
                 AND s.partition_name = t.partition_name
                 AND t.num_rows > 0)
    LOOP
      SELECT MAX(bucket_number)
        INTO l_max_endpoint_number
        FROM sqlt$_dba_part_histograms
       WHERE statement_id = p_statement_id
         AND owner = i.owner
         AND table_name = i.table_name
         AND partition_name = i.partition_name
         AND column_name = i.column_name;

      l_prior_endpoint_number := 0;
      l_popular_values := 0;
      l_buckets_pop_vals := 0;
      l_endpoint_estimated_value := NULL;
      l_endpoint_popular_value := NULL;
      l_endpoints_count := 0;
      l_adjust_4_nulls := (i.num_rows - i.num_nulls) / GREATEST(1, i.num_rows);

      FOR j IN (SELECT bucket_number,
                       endpoint_value,
                       endpoint_actual_value,
                       ROWID h_rowid
                  FROM sqlt$_dba_part_histograms
                 WHERE statement_id = p_statement_id
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND partition_name = i.partition_name
                   AND column_name = i.column_name
                 ORDER BY
                       bucket_number)
      LOOP
        l_endpoints_count := l_endpoints_count + 1;
        l_gap_endpoint_number := j.bucket_number - l_prior_endpoint_number;
        l_endpoint_estimated_value := compute_enpoint_value(i.data_type, j.endpoint_value, j.endpoint_actual_value);
        l_endpoint_popular_value := NULL;
        l_prior_endpoint_number := j.bucket_number;
        l_estimated_selectivity := l_adjust_4_nulls * l_gap_endpoint_number / GREATEST(l_max_endpoint_number, 1);
        l_estimated_cardinality := l_estimated_selectivity * i.num_rows;

        IF i.histogram = 'HEIGHT BALANCED' THEN
          IF l_gap_endpoint_number > 1 THEN -- popular value
            l_popular_values := l_popular_values + 1;
            l_buckets_pop_vals := l_buckets_pop_vals + l_gap_endpoint_number;
            l_endpoint_popular_value := l_endpoint_estimated_value;
          ELSE
            l_estimated_cardinality := NULL;
            l_estimated_selectivity := NULL;
          END IF;
        END IF;

        UPDATE sqlt$_dba_part_histograms
           SET endpoint_estimated_value = l_endpoint_estimated_value,
               endpoint_popular_value   = l_endpoint_popular_value,
               estimated_cardinality    = l_estimated_cardinality,
               estimated_selectivity    = l_estimated_selectivity
         WHERE ROWID = j.h_rowid;
      END LOOP;

      IF i.num_buckets > 0 AND (i.num_distinct - l_popular_values) > 0 THEN
        l_new_density := (i.num_buckets - l_buckets_pop_vals) / i.num_buckets / (i.num_distinct - l_popular_values);
      ELSE
        l_new_density := 0;
      END IF;

      UPDATE sqlt$_dba_part_col_statistics
         SET popular_values   = l_popular_values,
             buckets_pop_vals = l_buckets_pop_vals,
             new_density      = l_new_density,
             endpoints_count  = l_endpoints_count
       WHERE ROWID = i.s_rowid;
    END LOOP;

    UPDATE sqlt$_dba_part_col_statistics
       SET endpoints_count = 0
     WHERE statement_id = p_statement_id
       AND endpoints_count IS NULL;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('partition_histograms: '||SQLERRM);
  END partition_histograms;

  /*************************************************************************************/

  /* -------------------------
   *
   * public subpartition_histograms
   *
   * ------------------------- */
  PROCEDURE subpartition_histograms (p_statement_id IN NUMBER)
  IS
    l_prior_endpoint_number NUMBER;
    l_gap_endpoint_number NUMBER;
    l_estimated_cardinality NUMBER;
    l_estimated_selectivity NUMBER;
    l_popular_values NUMBER;
    l_buckets_pop_vals NUMBER;
    l_new_density NUMBER;
    l_endpoint_estimated_value sqlt$_dba_tab_histograms.endpoint_estimated_value%TYPE;
    l_endpoint_popular_value sqlt$_dba_tab_histograms.endpoint_popular_value%TYPE;
    l_endpoints_count NUMBER;
    l_max_endpoint_number NUMBER;
    l_adjust_4_nulls NUMBER;

  BEGIN
    write_log('subpartition_histograms');

    FOR i IN (SELECT s.owner,
                     s.table_name,
                     s.subpartition_name,
                     s.column_name,
                     c.data_type,
                     s.num_nulls,
                     s.num_distinct,
                     s.sample_size,
                     s.histogram,
                     s.num_buckets,
                     t.num_rows,
                     s.ROWID s_rowid
                FROM sqlt$_dba_subpart_col_stats s,
                     sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_tab_subpartitions t
               WHERE s.statement_id = p_statement_id
                 AND s.sample_size > 0
                 AND s.histogram IN ('FREQUENCY', 'HEIGHT BALANCED', 'TOP-FREQUENCY', 'HYBRID')
                 AND s.num_buckets > 0
                 AND s.statement_id = c.statement_id
                 AND s.owner = c.owner
                 AND s.table_name = c.table_name
                 AND s.column_name = c.column_name
                 AND s.statement_id = t.statement_id
                 AND s.owner = t.table_owner
                 AND s.table_name = t.table_name
                 AND s.subpartition_name = t.subpartition_name
                 AND t.num_rows > 0)
    LOOP
      SELECT MAX(bucket_number)
        INTO l_max_endpoint_number
        FROM sqlt$_dba_subpart_histograms
       WHERE statement_id = p_statement_id
         AND owner = i.owner
         AND table_name = i.table_name
         AND subpartition_name = i.subpartition_name
         AND column_name = i.column_name;

      l_prior_endpoint_number := 0;
      l_popular_values := 0;
      l_buckets_pop_vals := 0;
      l_endpoint_estimated_value := NULL;
      l_endpoint_popular_value := NULL;
      l_endpoints_count := 0;
      l_adjust_4_nulls := (i.num_rows - i.num_nulls) / GREATEST(1, i.num_rows);

      FOR j IN (SELECT bucket_number,
                       endpoint_value,
                       endpoint_actual_value,
                       ROWID h_rowid
                  FROM sqlt$_dba_subpart_histograms
                 WHERE statement_id = p_statement_id
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND subpartition_name = i.subpartition_name
                   AND column_name = i.column_name
                 ORDER BY
                       bucket_number)
      LOOP
        l_endpoints_count := l_endpoints_count + 1;
        l_gap_endpoint_number := j.bucket_number - l_prior_endpoint_number;
        l_endpoint_estimated_value := compute_enpoint_value(i.data_type, j.endpoint_value, j.endpoint_actual_value);
        l_endpoint_popular_value := NULL;
        l_estimated_cardinality := NULL;
        l_estimated_selectivity := NULL;
        l_prior_endpoint_number := j.bucket_number;
        l_estimated_selectivity := l_adjust_4_nulls * l_gap_endpoint_number / GREATEST(l_max_endpoint_number, 1);
        l_estimated_cardinality := l_estimated_selectivity * i.num_rows;

        IF i.histogram = 'HEIGHT BALANCED' THEN
          IF l_gap_endpoint_number > 1 THEN -- popular value
            l_popular_values := l_popular_values + 1;
            l_buckets_pop_vals := l_buckets_pop_vals + l_gap_endpoint_number;
            l_endpoint_popular_value := l_endpoint_estimated_value;
          ELSE
            l_estimated_cardinality := NULL;
            l_estimated_selectivity := NULL;
          END IF;
        END IF;

        UPDATE sqlt$_dba_subpart_histograms
           SET endpoint_estimated_value = l_endpoint_estimated_value,
               endpoint_popular_value   = l_endpoint_popular_value,
               estimated_cardinality    = l_estimated_cardinality,
               estimated_selectivity    = l_estimated_selectivity
         WHERE ROWID = j.h_rowid;
      END LOOP;

      IF i.num_buckets > 0 AND (i.num_distinct - l_popular_values) > 0 THEN
        l_new_density := (i.num_buckets - l_buckets_pop_vals) / i.num_buckets / (i.num_distinct - l_popular_values);
      ELSE
        l_new_density := 0;
      END IF;

      UPDATE sqlt$_dba_subpart_col_stats
         SET popular_values   = l_popular_values,
             buckets_pop_vals = l_buckets_pop_vals,
             new_density      = l_new_density,
             endpoints_count  = l_endpoints_count
       WHERE ROWID = i.s_rowid;
    END LOOP;

    UPDATE sqlt$_dba_subpart_col_stats
       SET endpoints_count = 0
     WHERE statement_id = p_statement_id
       AND endpoints_count IS NULL;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('subpartition_histograms: '||SQLERRM);
  END subpartition_histograms;

  /*************************************************************************************/

  /* -------------------------
   *
   * public cook_raw
   *
   * ------------------------- */
  FUNCTION cook_raw (
    p_raw       IN RAW,
    p_data_type IN VARCHAR2 )
  RETURN VARCHAR2
  IS
  BEGIN
    RETURN apply_mask(sqlt$s.convert_raw_value(p_raw, p_data_type), p_data_type);
  END cook_raw;

  /*************************************************************************************/

  /* -------------------------
   *
   * private cook_low_and_high_values
   *
   * ------------------------- */
  PROCEDURE cook_low_and_high_values (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
  BEGIN
    write_log('cook_low_and_high_values');

    l_count := 0;
    FOR i IN (SELECT low_value, high_value, data_type, source, owner, table_name, column_name
                FROM sqlt$_dba_all_table_cols_v
               WHERE statement_id = p_statement_id
                 AND (low_value IS NOT NULL OR high_value IS NOT NULL))
    LOOP
      l_count := l_count + 1;
      IF i.source = 'DBA_TAB_COLS' THEN
        UPDATE sqlt$_dba_tab_cols
           SET low_value_cooked = sqlt$t.cook_raw(i.low_value, i.data_type),
               high_value_cooked = sqlt$t.cook_raw(i.high_value, i.data_type)
         WHERE statement_id = p_statement_id
           AND owner = i.owner
           AND table_name = i.table_name
           AND column_name = i.column_name;
      ELSE
        UPDATE sqlt$_dba_nested_table_cols
           SET low_value_cooked = sqlt$t.cook_raw(i.low_value, i.data_type),
               high_value_cooked = sqlt$t.cook_raw(i.high_value, i.data_type)
         WHERE statement_id = p_statement_id
           AND owner = i.owner
           AND table_name = i.table_name
           AND column_name = i.column_name;
      END IF;
    END LOOP;
    write_log(l_count||' rows updated in sqlt$_dba_all_table_cols_v');

    l_count := 0;
    FOR i IN (SELECT p.low_value, p.high_value, c.data_type, p.ROWID row_id
                FROM sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_part_col_statistics p
               WHERE c.statement_id = p_statement_id
                 AND c.statement_id = p.statement_id
                 AND c.owner = p.owner
                 AND c.table_name = p.table_name
                 AND c.column_name = p.column_name
                 AND (p.low_value IS NOT NULL OR p.high_value IS NOT NULL))
    LOOP
      l_count := l_count + 1;
      UPDATE sqlt$_dba_part_col_statistics
         SET low_value_cooked = sqlt$t.cook_raw(i.low_value, i.data_type),
             high_value_cooked = sqlt$t.cook_raw(i.high_value, i.data_type)
       WHERE ROWID = i.row_id;
    END LOOP;
    write_log(l_count||' rows updated in sqlt$_dba_part_col_statistics');

    l_count := 0;
    FOR i IN (SELECT p.low_value, p.high_value, c.data_type, p.ROWID row_id
                FROM sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_subpart_col_stats p
               WHERE c.statement_id = p_statement_id
                 AND c.statement_id = p.statement_id
                 AND c.owner = p.owner
                 AND c.table_name = p.table_name
                 AND c.column_name = p.column_name
                 AND (p.low_value IS NOT NULL OR p.high_value IS NOT NULL))
    LOOP
      l_count := l_count + 1;
      UPDATE sqlt$_dba_subpart_col_stats
         SET low_value_cooked = sqlt$t.cook_raw(i.low_value, i.data_type),
             high_value_cooked = sqlt$t.cook_raw(i.high_value, i.data_type)
       WHERE ROWID = i.row_id;
    END LOOP;
    write_log(l_count||' rows updated in sqlt$_dba_subpart_col_stats');

    l_count := 0;
    FOR i IN (SELECT p.low_value, p.high_value, c.data_type, p.ROWID row_id
                FROM sqlt$_dba_all_table_cols_v c,
                     sqlt$_dba_col_stats_versions p
               WHERE c.statement_id = p_statement_id
                 AND c.statement_id = p.statement_id
                 AND c.owner = p.owner
                 AND c.table_name = p.table_name
                 AND c.column_name = p.column_name
                 AND (p.low_value IS NOT NULL OR p.high_value IS NOT NULL))
    LOOP
      l_count := l_count + 1;
      UPDATE sqlt$_dba_col_stats_versions
         SET low_value_cooked = sqlt$t.cook_raw(i.low_value, i.data_type),
             high_value_cooked = sqlt$t.cook_raw(i.high_value, i.data_type)
       WHERE ROWID = i.row_id;
    END LOOP;
    write_log(l_count||' rows updated in sqlt$_dba_col_stats_versions');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('cook_low_and_high_values: '||SQLERRM);
  END cook_low_and_high_values;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_mutating_ndv
   *
   * ------------------------- */
  PROCEDURE compute_mutating_ndv (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
    l_version_count NUMBER;
    l_prior_num_distinct NUMBER;
    l_mutating_ndv VARCHAR2(5);
  BEGIN
    write_log('compute_mutating_ndv');

    l_count := 0;
    FOR i IN (SELECT object_type,
                     owner,
                     table_name,
                     partition_name,
                     subpartition_name,
                     column_name
                FROM sqlt$_dba_col_stats_versions
               WHERE statement_id = p_statement_id
                 AND version_type = 'HISTORY'
               GROUP BY
                     object_type,
                     owner,
                     table_name,
                     partition_name,
                     subpartition_name,
                     column_name
              HAVING COUNT(*) > 1)
    LOOP
      write_log('"'||i.object_type||'" "'||i.owner||'" "'||i.table_name||'" "'||i.partition_name||'" "'||i.subpartition_name||'" "'||i.column_name||'"', 'S');

      l_version_count := 0;
      l_mutating_ndv := 'FALSE';
      l_prior_num_distinct := NULL; -- redundant

      FOR j IN (SELECT v.num_distinct
                  FROM (
                SELECT num_distinct, save_time
                  FROM sqlt$_dba_col_stats_versions
                 WHERE i.object_type = 'TABLE'
                   AND statement_id = p_statement_id
                   AND version_type = 'HISTORY'
                   AND object_type = i.object_type
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND partition_name IS NULL
                   AND subpartition_name IS NULL
                   AND column_name = i.column_name
                UNION ALL
                SELECT num_distinct, save_time
                  FROM sqlt$_dba_col_stats_versions
                 WHERE i.object_type = 'PARTITION'
                   AND statement_id = p_statement_id
                   AND version_type = 'HISTORY'
                   AND object_type = i.object_type
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND partition_name = i.partition_name
                   AND subpartition_name IS NULL
                   AND column_name = i.column_name
                UNION ALL
                SELECT num_distinct, save_time
                  FROM sqlt$_dba_col_stats_versions
                 WHERE i.object_type = 'SUBPARTITION'
                   AND statement_id = p_statement_id
                   AND version_type = 'HISTORY'
                   AND object_type = i.object_type
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND partition_name = i.partition_name
                   AND subpartition_name = i.subpartition_name
                   AND column_name = i.column_name) v
                 ORDER BY
                       v.save_time DESC)
      LOOP
        l_version_count := l_version_count + 1;
        IF l_version_count > 1 AND differ_more_than_x_perc(j.num_distinct, l_prior_num_distinct) THEN
          l_mutating_ndv := 'TRUE';
          EXIT;
        END IF;
        l_prior_num_distinct := j.num_distinct;
      END LOOP;

      IF l_mutating_ndv = 'TRUE' THEN
        l_count := l_count + 1;
        IF i.object_type = 'TABLE' THEN
          UPDATE sqlt$_dba_tab_cols
             SET mutating_ndv = l_mutating_ndv
           WHERE statement_id = p_statement_id
             AND owner = i.owner
             AND table_name = i.table_name
             AND column_name = i.column_name
             AND mutating_ndv IS NULL;
          UPDATE sqlt$_dba_nested_table_cols
             SET mutating_ndv = l_mutating_ndv
           WHERE statement_id = p_statement_id
             AND owner = i.owner
             AND table_name = i.table_name
             AND column_name = i.column_name
             AND mutating_ndv IS NULL;
        ELSIF i.object_type = 'PARTITION' THEN
          UPDATE sqlt$_dba_part_col_statistics
             SET mutating_ndv = l_mutating_ndv
           WHERE statement_id = p_statement_id
             AND owner = i.owner
             AND table_name = i.table_name
             AND partition_name = i.partition_name
             AND column_name = i.column_name
             AND mutating_ndv IS NULL;
        ELSIF i.object_type = 'SUBPARTITION' THEN
          UPDATE sqlt$_dba_subpart_col_stats
             SET mutating_ndv = l_mutating_ndv
           WHERE statement_id = p_statement_id
             AND owner = i.owner
             AND table_name = i.table_name
             AND subpartition_name = i.subpartition_name
             AND column_name = i.column_name
             AND mutating_ndv IS NULL;
        END IF;
      END IF;
    END LOOP;

    write_log('mutating_ndv FALSE', 'S');

    UPDATE sqlt$_dba_tab_cols
       SET mutating_ndv = 'FALSE'
     WHERE statement_id = p_statement_id
       AND mutating_ndv IS NULL;

    UPDATE sqlt$_dba_nested_table_cols
       SET mutating_ndv = 'FALSE'
     WHERE statement_id = p_statement_id
       AND mutating_ndv IS NULL;

    UPDATE sqlt$_dba_part_col_statistics
       SET mutating_ndv = 'FALSE'
     WHERE statement_id = p_statement_id
       AND mutating_ndv IS NULL;

    UPDATE sqlt$_dba_subpart_col_stats
       SET mutating_ndv = 'FALSE'
     WHERE statement_id = p_statement_id
       AND mutating_ndv IS NULL;

    write_log(l_count||' rows updated with mutating_ndv');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('compute_mutating_ndv: '||SQLERRM);
  END compute_mutating_ndv;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_endpoints_count
   *
   * ------------------------- */
  PROCEDURE compute_endpoints_count (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
  BEGIN
    write_log('compute_endpoints_count');

    l_count := 0;
    FOR i IN (SELECT COUNT(*) endpoints_count,
                     object_type,
                     owner,
                     table_name,
                     partition_name,
                     subpartition_name,
                     column_name,
                     save_time
                FROM sqlt$_dba_histgrm_stats_versn
               WHERE statement_id = p_statement_id
                 AND version_type = 'HISTORY'
               GROUP BY
                     object_type,
                     owner,
                     table_name,
                     partition_name,
                     subpartition_name,
                     column_name,
                     save_time)
    LOOP
      l_count := l_count + 1;
      IF i.object_type = 'TABLE' THEN
        UPDATE sqlt$_dba_col_stats_versions
           SET endpoints_count = i.endpoints_count
         WHERE statement_id = p_statement_id
           AND version_type = 'HISTORY'
           AND object_type = i.object_type
           AND owner = i.owner
           AND table_name = i.table_name
           AND column_name = i.column_name
           AND save_time = i.save_time
           AND partition_name IS NULL
           AND subpartition_name IS NULL;
      ELSIF i.object_type = 'PARTITION' THEN
        UPDATE sqlt$_dba_col_stats_versions
           SET endpoints_count = i.endpoints_count
         WHERE statement_id = p_statement_id
           AND version_type = 'HISTORY'
           AND object_type = i.object_type
           AND owner = i.owner
           AND table_name = i.table_name
           AND column_name = i.column_name
           AND save_time = i.save_time
           AND partition_name = i.partition_name
           AND subpartition_name IS NULL;
      ELSIF i.object_type = 'SUBPARTITION' THEN
        UPDATE sqlt$_dba_col_stats_versions
           SET endpoints_count = i.endpoints_count
         WHERE statement_id = p_statement_id
           AND version_type = 'HISTORY'
           AND object_type = i.object_type
           AND owner = i.owner
           AND table_name = i.table_name
           AND column_name = i.column_name
           AND save_time = i.save_time
           AND partition_name = i.partition_name
           AND subpartition_name =i.subpartition_name;
      END IF;
    END LOOP;

    UPDATE sqlt$_dba_col_stats_versions
       SET endpoints_count = 0
     WHERE statement_id = p_statement_id
       AND version_type = 'HISTORY'
       AND endpoints_count IS NULL;

    write_log(l_count||' rows updated in sqlt$_dba_histgrm_stats_versn with endpoints_count > 0');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('compute_endpoints_count: '||SQLERRM);
  END compute_endpoints_count;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_mutating_endpoints
   *
   * ------------------------- */
  PROCEDURE compute_mutating_endpoints (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
    l_version_count NUMBER;
    l_prior_endpoints_count NUMBER;
    l_mutating_endpoints VARCHAR2(5);
  BEGIN
    write_log('compute_mutating_endpoints');

    l_count := 0;
    FOR i IN (SELECT object_type,
                     owner,
                     table_name,
                     partition_name,
                     subpartition_name,
                     column_name
                FROM sqlt$_dba_col_stats_versions
               WHERE statement_id = p_statement_id
                 AND version_type = 'HISTORY'
               GROUP BY
                     object_type,
                     owner,
                     table_name,
                     partition_name,
                     subpartition_name,
                     column_name
              HAVING COUNT(*) > 1)
    LOOP
      write_log('"'||i.object_type||'" "'||i.owner||'" "'||i.table_name||'" "'||i.partition_name||'" "'||i.subpartition_name||'" "'||i.column_name||'"', 'S');

      l_version_count := 0;
      l_mutating_endpoints := 'FALSE';
      l_prior_endpoints_count := NULL; -- redundant

      FOR j IN (SELECT v.endpoints_count
                  FROM (
                SELECT endpoints_count, save_time
                  FROM sqlt$_dba_col_stats_versions
                 WHERE i.object_type = 'TABLE'
                   AND statement_id = p_statement_id
                   AND version_type = 'HISTORY'
                   AND object_type = i.object_type
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND partition_name IS NULL
                   AND subpartition_name IS NULL
                   AND column_name = i.column_name
                UNION ALL
                SELECT endpoints_count, save_time
                  FROM sqlt$_dba_col_stats_versions
                 WHERE i.object_type = 'PARTITION'
                   AND statement_id = p_statement_id
                   AND version_type = 'HISTORY'
                   AND object_type = i.object_type
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND partition_name = i.partition_name
                   AND subpartition_name IS NULL
                   AND column_name = i.column_name
                UNION ALL
                SELECT endpoints_count, save_time
                  FROM sqlt$_dba_col_stats_versions
                 WHERE i.object_type = 'SUBPARTITION'
                   AND statement_id = p_statement_id
                   AND version_type = 'HISTORY'
                   AND object_type = i.object_type
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND partition_name = i.partition_name
                   AND subpartition_name = i.subpartition_name
                   AND column_name = i.column_name) v
                 ORDER BY
                       v.save_time DESC)
      LOOP
        l_version_count := l_version_count + 1;
        IF l_version_count > 1 AND differ_more_than_x_perc(j.endpoints_count, l_prior_endpoints_count) THEN
          l_mutating_endpoints := 'TRUE';
          EXIT;
        END IF;
        l_prior_endpoints_count := j.endpoints_count;
      END LOOP;

      IF l_mutating_endpoints = 'TRUE' THEN
        l_count := l_count + 1;
        IF i.object_type = 'TABLE' THEN
          UPDATE sqlt$_dba_tab_cols
             SET mutating_endpoints = l_mutating_endpoints
           WHERE statement_id = p_statement_id
             AND owner = i.owner
             AND table_name = i.table_name
             AND column_name = i.column_name
             AND mutating_endpoints IS NULL;
          UPDATE sqlt$_dba_nested_table_cols
             SET mutating_endpoints = l_mutating_endpoints
           WHERE statement_id = p_statement_id
             AND owner = i.owner
             AND table_name = i.table_name
             AND column_name = i.column_name
             AND mutating_endpoints IS NULL;
        ELSIF i.object_type = 'PARTITION' THEN
          UPDATE sqlt$_dba_part_col_statistics
             SET mutating_endpoints = l_mutating_endpoints
           WHERE statement_id = p_statement_id
             AND owner = i.owner
             AND table_name = i.table_name
             AND partition_name = i.partition_name
             AND column_name = i.column_name
             AND mutating_endpoints IS NULL;
        ELSIF i.object_type = 'SUBPARTITION' THEN
          UPDATE sqlt$_dba_subpart_col_stats
             SET mutating_endpoints = l_mutating_endpoints
           WHERE statement_id = p_statement_id
             AND owner = i.owner
             AND table_name = i.table_name
             AND subpartition_name = i.subpartition_name
             AND column_name = i.column_name
             AND mutating_endpoints IS NULL;
        END IF;
      END IF;
    END LOOP;

    write_log('mutating_endpoints FALSE', 'S');

    UPDATE sqlt$_dba_tab_cols
       SET mutating_endpoints = 'FALSE'
     WHERE statement_id = p_statement_id
       AND mutating_endpoints IS NULL;

    UPDATE sqlt$_dba_nested_table_cols
       SET mutating_endpoints = 'FALSE'
     WHERE statement_id = p_statement_id
       AND mutating_endpoints IS NULL;

    UPDATE sqlt$_dba_part_col_statistics
       SET mutating_endpoints = 'FALSE'
     WHERE statement_id = p_statement_id
       AND mutating_endpoints IS NULL;

    UPDATE sqlt$_dba_subpart_col_stats
       SET mutating_endpoints = 'FALSE'
     WHERE statement_id = p_statement_id
       AND mutating_endpoints IS NULL;

    write_log(l_count||' rows updated with mutating_endpoints');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('compute_mutating_endpoints: '||SQLERRM);
  END compute_mutating_endpoints;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_mutating_num_rows
   *
   * ------------------------- */
  PROCEDURE compute_mutating_num_rows (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
    l_version_count NUMBER;
    l_prior_num_rows NUMBER;
    l_mutating_num_rows VARCHAR2(5);
  BEGIN
    write_log('compute_mutating_num_rows');

    l_count := 0;
    FOR i IN (SELECT object_type,
                     owner,
                     table_name,
                     partition_name,
                     subpartition_name
                FROM sqlt$_dba_tab_stats_versions
               WHERE statement_id = p_statement_id
                 AND version_type = 'HISTORY'
               GROUP BY
                     object_type,
                     owner,
                     table_name,
                     partition_name,
                     subpartition_name
              HAVING COUNT(*) > 1)
    LOOP
      write_log('"'||i.object_type||'" "'||i.owner||'" "'||i.table_name||'" "'||i.partition_name||'" "'||i.subpartition_name||'"', 'S');

      l_version_count := 0;
      l_mutating_num_rows := 'FALSE';
      l_prior_num_rows := NULL; -- redundant

      FOR j IN (SELECT v.num_rows
                  FROM (
                SELECT num_rows, save_time
                  FROM sqlt$_dba_tab_stats_versions
                 WHERE i.object_type = 'TABLE'
                   AND statement_id = p_statement_id
                   AND version_type = 'HISTORY'
                   AND object_type = i.object_type
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND partition_name IS NULL
                   AND subpartition_name IS NULL
                   AND num_rows IS NOT NULL
                UNION ALL
                SELECT num_rows, save_time
                  FROM sqlt$_dba_tab_stats_versions
                 WHERE i.object_type = 'PARTITION'
                   AND statement_id = p_statement_id
                   AND version_type = 'HISTORY'
                   AND object_type = i.object_type
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND partition_name = i.partition_name
                   AND subpartition_name IS NULL
                   AND num_rows IS NOT NULL
                UNION ALL
                SELECT num_rows, save_time
                  FROM sqlt$_dba_tab_stats_versions
                 WHERE i.object_type = 'SUBPARTITION'
                   AND statement_id = p_statement_id
                   AND version_type = 'HISTORY'
                   AND object_type = i.object_type
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND partition_name = i.partition_name
                   AND subpartition_name = i.subpartition_name
                   AND num_rows IS NOT NULL) v
                 ORDER BY
                       v.save_time DESC)
      LOOP
        l_version_count := l_version_count + 1;
        IF l_version_count > 1 AND differ_more_than_x_perc(j.num_rows, l_prior_num_rows) THEN
          l_mutating_num_rows := 'TRUE';
          EXIT;
        END IF;
        l_prior_num_rows := j.num_rows;
      END LOOP;

      IF l_mutating_num_rows = 'TRUE' THEN
        l_count := l_count + 1;
        IF i.object_type = 'TABLE' THEN
          UPDATE sqlt$_dba_tab_statistics
             SET mutating_num_rows = l_mutating_num_rows
           WHERE statement_id = p_statement_id
             AND object_type = i.object_type
             AND owner = i.owner
             AND table_name = i.table_name
             AND partition_name IS NULL
             AND subpartition_name IS NULL
             AND mutating_num_rows IS NULL;
        ELSIF i.object_type = 'PARTITION' THEN
          UPDATE sqlt$_dba_tab_statistics
             SET mutating_num_rows = l_mutating_num_rows
           WHERE statement_id = p_statement_id
             AND object_type = i.object_type
             AND owner = i.owner
             AND table_name = i.table_name
             AND partition_name = i.partition_name
             AND subpartition_name IS NULL
             AND mutating_num_rows IS NULL;
        ELSIF i.object_type = 'SUBPARTITION' THEN
          UPDATE sqlt$_dba_tab_statistics
             SET mutating_num_rows = l_mutating_num_rows
           WHERE statement_id = p_statement_id
             AND object_type = i.object_type
             AND owner = i.owner
             AND table_name = i.table_name
             AND partition_name = i.partition_name
             AND subpartition_name = i.subpartition_name
             AND mutating_num_rows IS NULL;
        END IF;
      END IF;
    END LOOP;

    write_log('mutating_num_rows FALSE', 'S');

    UPDATE sqlt$_dba_tab_statistics
       SET mutating_num_rows = 'FALSE'
     WHERE statement_id = p_statement_id
       AND mutating_num_rows IS NULL;

    write_log(l_count||' rows updated with mutating_num_rows');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('compute_mutating_num_rows: '||SQLERRM);
  END compute_mutating_num_rows;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_mutating_blevel
   *
   * ------------------------- */
  PROCEDURE compute_mutating_blevel (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
  BEGIN
    write_log('compute_mutating_blevel');

    l_count := 0;
    FOR i IN (SELECT object_type,
                     owner,
                     index_name,
                     partition_name,
                     subpartition_name
                FROM sqlt$_dba_ind_stats_versions
               WHERE statement_id = p_statement_id
                 AND blevel IS NOT NULL
               GROUP BY
                     object_type,
                     owner,
                     index_name,
                     partition_name,
                     subpartition_name
              HAVING COUNT(DISTINCT blevel) > 1)
    LOOP
      l_count := l_count + 1;
      write_log('"'||i.object_type||'" "'||i.owner||'" "'||i.index_name||'" "'||i.partition_name||'" "'||i.subpartition_name||'"', 'S');

      IF i.object_type = 'INDEX' THEN
        UPDATE sqlt$_dba_ind_statistics
           SET mutating_blevel = 'TRUE'
         WHERE object_type = i.object_type
           AND owner = i.owner
           AND index_name = i.index_name
           AND partition_name IS NULL
           AND subpartition_name IS NULL
           AND mutating_blevel IS NULL;
      ELSIF i.object_type = 'PARTITION' THEN
        UPDATE sqlt$_dba_ind_statistics
           SET mutating_blevel = 'TRUE'
         WHERE object_type = i.object_type
           AND owner = i.owner
           AND index_name = i.index_name
           AND partition_name = i.partition_name
           AND subpartition_name IS NULL
           AND mutating_blevel IS NULL;
      ELSIF i.object_type = 'SUBARTITION' THEN
        UPDATE sqlt$_dba_ind_statistics
           SET mutating_blevel = 'TRUE'
         WHERE object_type = i.object_type
           AND owner = i.owner
           AND index_name = i.index_name
           AND partition_name = i.partition_name
           AND subpartition_name = i.subpartition_name
           AND mutating_blevel IS NULL;
      END IF;
    END LOOP;

    write_log('mutating_blevel FALSE', 'S');

    UPDATE sqlt$_dba_ind_statistics
       SET mutating_blevel = 'FALSE'
     WHERE statement_id = p_statement_id
       AND mutating_blevel IS NULL;

    write_log(l_count||' rows updated with mutating_blevel');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('compute_mutating_blevel: '||SQLERRM);
  END compute_mutating_blevel;

  /*************************************************************************************/

  /* -------------------------
   *
   * public column_in_predicates
   *
   * called by sqlt$t.perm_transformation and sqlt/utl/sqltmain
   *
   * ------------------------- */
  PROCEDURE column_in_predicates (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    pe_rec sqlt$_plan_extension%ROWTYPE;
  BEGIN
    write_log('column_in_predicates');

    DELETE sqlg$_column_predicate;
    DELETE sqlg$_pivot;

    INSERT INTO sqlg$_pivot (object_name)
    SELECT DISTINCT column_name object_name
      FROM sqlt$_dba_all_table_cols_v
     WHERE statement_id = p_statement_id;
       --AND hidden_column = 'NO';

    FOR i IN (SELECT plan_hash_value,
                     id,
                     'AP' predicate_type,
                     access_predicates predicates
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND access_predicates IS NOT NULL
               UNION
              SELECT plan_hash_value,
                     id,
                     'FP' predicate_type,
                     filter_predicates predicates
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND filter_predicates IS NOT NULL)
    LOOP
      FOR j IN (SELECT object_name column_name
                  FROM sqlg$_pivot
                 WHERE i.predicates LIKE '%"'||object_name||'"%')
      LOOP
        l_count := l_count + 1;
        pe_rec.binds_html_table := NULL;
        pe_rec.binds_html_table_capt := NULL;

        IF sqlt$a.get_param('show_binds_in_predicates') = 'Y' THEN
          FOR k IN (SELECT CASE source
                             WHEN 'GV$SQL_PLAN'       THEN 'MEM'
                             WHEN 'DBA_HIST_SQL_PLAN' THEN 'AWR'
                             WHEN 'PLAN_TABLE'        THEN 'XPL'
                             WHEN 'DBA_SQLTUNE_PLANS' THEN 'STA'
                             ELSE NULL END source,
                           DECODE(inst_id, NULL, NULL, -1, NULL, '_i'||inst_id) inst_id,
                           DECODE(child_number, NULL, NULL, -1, NULL, '_c'||child_number) child_number,
                           binds_html_table,
                           binds_html_table_capt
                      FROM sqlt$_plan_extension
                     WHERE statement_id = p_statement_id
                       AND plan_hash_value = i.plan_hash_value
                       AND id = i.id
                       AND (binds_html_table IS NOT NULL OR binds_html_table_capt IS NOT NULL)
                     ORDER BY
                           CASE source
                             WHEN 'GV$SQL_PLAN'       THEN 1
                             WHEN 'DBA_HIST_SQL_PLAN' THEN 2
                             WHEN 'PLAN_TABLE'        THEN 3
                             WHEN 'DBA_SQLTUNE_PLANS' THEN 4
                             ELSE 5 END,
                           inst_id,
                           child_number)
          LOOP
            IF k.binds_html_table IS NOT NULL THEN
              pe_rec.binds_html_table := pe_rec.binds_html_table||k.source||k.inst_id||k.child_number||'<br>'||LF||k.binds_html_table;
            END IF;
            IF k.binds_html_table_capt IS NOT NULL THEN
              pe_rec.binds_html_table_capt := pe_rec.binds_html_table_capt||k.source||k.inst_id||k.child_number||'<br>'||LF||k.binds_html_table_capt;
            END IF;
          END LOOP;
        END IF;

        UPDATE sqlt$_dba_tab_cols
           SET in_predicates = 'TRUE'
         WHERE statement_id = p_statement_id
           AND column_name = j.column_name
           AND in_predicates IS NULL;

        UPDATE sqlt$_dba_nested_table_cols
           SET in_predicates = 'TRUE'
         WHERE statement_id = p_statement_id
           AND column_name = j.column_name
           AND in_predicates IS NULL;

        INSERT INTO sqlg$_column_predicate (
          column_name,
          plan_hash_value,
          plan_line_id,
          predicate_type,
          predicate,
          binds_html_table,
          binds_html_table_capt
        ) VALUES (
          j.column_name,
          i.plan_hash_value,
          i.id,
          i.predicate_type,
          i.predicates,
          pe_rec.binds_html_table,
          pe_rec.binds_html_table_capt
        );
      END LOOP;
    END LOOP;

    UPDATE sqlt$_dba_tab_cols
       SET in_predicates = 'FALSE'
     WHERE statement_id = p_statement_id
       AND in_predicates IS NULL;

    UPDATE sqlt$_dba_nested_table_cols
       SET in_predicates = 'FALSE'
     WHERE statement_id = p_statement_id
       AND in_predicates IS NULL;

    write_log(l_count||' columns in predicates');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('column_in_predicates: '||SQLERRM);
  END column_in_predicates;

  /*************************************************************************************/

  /* -------------------------
   *
   * public column_in_projection
   *
   * called by sqlt$t.perm_transformation and sqlt/utl/sqltmain
   *
   * ------------------------- */
  PROCEDURE column_in_projection (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
  BEGIN
    write_log('column_in_projection');

    FOR i IN (SELECT DISTINCT projection
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND projection IS NOT NULL)
    LOOP
      FOR j IN (SELECT object_name column_name
                  FROM sqlg$_pivot
                 WHERE i.projection LIKE '%"'||object_name||'"%')
      LOOP
        l_count := l_count + 1;

        UPDATE sqlt$_dba_tab_cols
           SET in_projection = 'TRUE'
         WHERE statement_id = p_statement_id
           AND column_name = j.column_name
           AND in_projection IS NULL;

        UPDATE sqlt$_dba_nested_table_cols
           SET in_projection = 'TRUE'
         WHERE statement_id = p_statement_id
           AND column_name = j.column_name
           AND in_projection IS NULL;
      END LOOP;
    END LOOP;

    UPDATE sqlt$_dba_tab_cols
       SET in_projection = 'FALSE'
     WHERE statement_id = p_statement_id
       AND in_projection IS NULL;

    UPDATE sqlt$_dba_nested_table_cols
       SET in_projection = 'FALSE'
     WHERE statement_id = p_statement_id
       AND in_projection IS NULL;

    write_log(l_count||' columns in projection');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('column_in_projection: '||SQLERRM);
  END column_in_projection;

  /*************************************************************************************/

  /* -------------------------
   *
   * private indexes_in_plan
   *
   * ------------------------- */
  PROCEDURE indexes_in_plan (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
  BEGIN
    write_log('index_in_plan');

    DELETE sqlg$_pivot;
    sqlt$d.list_of_indexes(p_statement_id);

    FOR i IN (SELECT x.ROWID row_id
                FROM sqlg$_pivot p,
                     sqlt$_dba_indexes x
               WHERE x.statement_id = p_statement_id
                 AND x.owner = p.object_owner
                 AND x.index_name = p.object_name)
    LOOP
      l_count := l_count + 1;
      UPDATE sqlt$_dba_indexes
         SET in_plan = 'TRUE'
       WHERE ROWID = i.row_id;
    END LOOP;

    UPDATE sqlt$_dba_indexes
       SET in_plan = 'FALSE'
     WHERE statement_id = p_statement_id
       AND in_plan IS NULL;

    COMMIT;
    write_log(l_count||' indexes in plan');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('indexes_in_plan: '||SQLERRM);
  END indexes_in_plan;

  /*************************************************************************************/

  /* -------------------------
   *
   * private column_in_indexes
   *
   * ------------------------- */
  PROCEDURE column_in_indexes (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
  BEGIN
    write_log('column_in_indexes');

    FOR i IN (SELECT table_owner, table_name, column_name
                FROM sqlt$_dba_ind_columns
               WHERE statement_id = p_statement_id
               UNION
              SELECT ic.table_owner, ic.table_name, TRIM('"' FROM REPLACE(DBMS_LOB.SUBSTR(tc.data_default), ' ')) column_name
                FROM sqlt$_dba_ind_columns ic,
                     sqlt$_dba_tab_cols tc
               WHERE ic.statement_id = p_statement_id
                 AND ic.statement_id = tc.statement_id
                 AND ic.table_owner = tc.owner
                 AND ic.table_name = tc.table_name
                 AND ic.column_name = tc.column_name
                 AND tc.data_default IS NOT NULL)
    LOOP
      l_count := l_count + 1;

      UPDATE sqlt$_dba_tab_cols
         SET in_indexes = 'TRUE'
       WHERE statement_id = p_statement_id
         AND owner = i.table_owner
         AND table_name = i.table_name
         AND column_name = i.column_name;

      UPDATE sqlt$_dba_nested_table_cols
         SET in_indexes = 'TRUE'
       WHERE statement_id = p_statement_id
         AND owner = i.table_owner
         AND table_name = i.table_name
         AND column_name = i.column_name;
    END LOOP;

    UPDATE sqlt$_dba_tab_cols
       SET in_indexes = 'FALSE'
     WHERE statement_id = p_statement_id
       AND in_indexes IS NULL;

    UPDATE sqlt$_dba_nested_table_cols
       SET in_indexes = 'FALSE'
     WHERE statement_id = p_statement_id
       AND in_indexes IS NULL;

    COMMIT;
    write_log(l_count||' columns in indexes');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('column_in_indexes: '||SQLERRM);
  END column_in_indexes;

  /*************************************************************************************/

  /* -------------------------
   *
   * private index_columns
   *
   * ------------------------- */
  PROCEDURE index_columns (p_statement_id IN NUMBER)
  IS
  BEGIN
    write_log('index_columns');

    FOR i IN (SELECT owner,
                     index_name
                FROM sqlt$_dba_indexes
               WHERE statement_id = p_statement_id)
    LOOP
      sqlt$a.set_index_column_names (
        p_statement_id => p_statement_id,
        p_index_owner  => i.owner,
        p_index_name   => i.index_name,
        p_hidden_names => 'YES',
        p_separator    =>  ' ',
        p_table_name   => 'NO' );
    END LOOP;
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('index_columns: '||SQLERRM);
  END index_columns;

  /*************************************************************************************/

  /* -------------------------
   *
   * private at_least_1_notnull_col
   *
   * ------------------------- */
  PROCEDURE at_least_1_notnull_col (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
  BEGIN
    write_log('at_least_1_notnull_col');

    FOR i IN (SELECT DISTINCT
                     ic.index_owner,
                     ic.index_name
                FROM sqlt$_dba_ind_columns ic,
                     sqlt$_dba_tab_cols tc
               WHERE ic.statement_id = p_statement_id
                 AND tc.statement_id = ic.statement_id
                 AND tc.owner = ic.table_owner
                 AND tc.table_name = ic.table_name
                 AND tc.column_name = ic.column_name
                 AND tc.nullable = 'N')
    LOOP
      l_count := l_count + 1;

      UPDATE sqlt$_dba_indexes
         SET at_least_1_notnull_col = 'Y'
       WHERE statement_id = p_statement_id
         AND owner = i.index_owner
         AND index_name = i.index_name
         AND at_least_1_notnull_col IS NULL;
    END LOOP;

    UPDATE sqlt$_dba_indexes
       SET at_least_1_notnull_col = 'N'
     WHERE statement_id = p_statement_id
       AND at_least_1_notnull_col IS NULL;

    COMMIT;
    write_log(l_count||' indexes updated');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('at_least_1_notnull_col: '||SQLERRM);
  END at_least_1_notnull_col;

  /*************************************************************************************/

  /* -------------------------
   *
   * private add_column_default
   *
   * ------------------------- */
  PROCEDURE add_column_default (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
  BEGIN
    IF sqlt$a.get_rdbms_version < '11.1' THEN
      write_log('skip add_column_default');
      RETURN;
    END IF;

    write_log('add_column_default');

    /*
    This is a specific optimization that is in 11g when a column is added to a table with both a constant default value and a NOT NULL constraint.
    It only applies when the column is created in this manner.
    If it is set that way later on, it will just be a normal column.
    Likewise, if a column with this feature is made nullable, then the column is converted to a normal column and will remain that way even if the NOT NULL constraint is reapplied.
    The optimization exists to avoid the expensive data rewrite when adding a default column, so there is no point in enabling it when a default value or NOT NULL status is set afterward.
    And Oracle won''t unless it can do so.
    */

    FOR i IN (SELECT DISTINCT
                     tc.owner,
                     tc.table_name,
                     tc.column_name
                FROM sqlt$_dba_tab_cols tc,
                     sys.sqlt$_col$_v c
               WHERE tc.statement_id = p_statement_id
                 AND tc.owner = c.owner
                 AND tc.table_name = c.table_name
                 AND tc.column_name = c.column_name
                 AND BITAND(c.property, 1073741824) = 1073741824)
    LOOP
      l_count := l_count + 1;

      UPDATE sqlt$_dba_tab_cols
         SET add_column_default = 'Y'
       WHERE statement_id = p_statement_id
         AND owner = i.owner
         AND table_name = i.table_name
         AND column_name = i.column_name;
    END LOOP;

    COMMIT;
    write_log(l_count||' columns updated');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('add_column_default: '||SQLERRM);
  END add_column_default;

  /*************************************************************************************/
  
   /* -------------------------
   *
   * private col_group_usage_report
   *
   * ------------------------- */
  PROCEDURE col_group_usage_report (p_statement_id IN NUMBER)
  IS
    l_col_group_usage_report CLOB;
  BEGIN
    IF sqlt$a.get_param_n('colgroup_seed_secs') > 0 THEN  

      write_log('col_group_usage_report');
      
      FOR i IN (SELECT DISTINCT
                       tc.owner,
                       tc.table_name
                  FROM sqlt$_dba_tables tc
                 WHERE tc.statement_id = p_statement_id)
      LOOP
	  
        EXECUTE IMMEDIATE 'SELECT SYS.DBMS_STATS.REPORT_COL_USAGE('''||
		DBMS_ASSERT.QUALIFIED_SQL_NAME(i.owner||''','''||i.table_name) -- 22170177 
		||''') FROM DUAL' INTO l_col_group_usage_report;
      
        UPDATE sqlt$_dba_tables
           SET col_group_usage_report = l_col_group_usage_report
         WHERE statement_id = p_statement_id
           AND owner = i.owner
           AND table_name = i.table_name;
           
        write_log('col_group_usage_report for '||i.owner||'.'||i.table_name||' completed.');   
           
      END LOOP;
      
      COMMIT;
	  
    ELSE
      write_log('skip col_group_usage_report');	
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('col_group_usage_report: '||SQLERRM);
  END col_group_usage_report;
  
  
  /*************************************************************************************/
  
   /* -------------------------
   *
   * private add_dv_censored
   *
   * ------------------------- */
  PROCEDURE add_dv_censored (p_statement_id IN NUMBER)
  IS
    l_dv_censored VARCHAR2(1);
    l_version VARCHAR2(10);
  BEGIN 

      write_log('add_dv_censored');
      l_version := sqlt$a.get_rdbms_version;
      
      FOR i IN (SELECT DISTINCT
                       tc.owner,
                       tc.owner_id,
                       tc.table_name
                  FROM sqlt$_dba_tables tc
                 WHERE tc.statement_id = p_statement_id)
      LOOP
	  
        IF l_version >= '11.2' THEN --SYS_OP_DV_CHECK exists since 11.2 so need to use EXECUTE IMMEDIATE to be able to install on older versions
           EXECUTE IMMEDIATE 'SELECT SYS_OP_DV_CHECK('''||
		   DBMS_ASSERT.QUALIFIED_SQL_NAME(i.table_name) -- 22170177
		   ||''','''||i.owner_id||''') FROM DUAL' INTO l_dv_censored;
        ELSE
           l_dv_censored := 1;
        END IF;
		
        UPDATE sqlt$_dba_tables
           SET dv_censored = DECODE(l_dv_censored,1,'N','Y')
         WHERE statement_id = p_statement_id
           AND owner = i.owner
           AND table_name = i.table_name; 
		   
      END LOOP;
      
      COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('add_dv_censored: '||SQLERRM);
  END add_dv_censored;  

  /*************************************************************************************/ 
  
  

  /* -------------------------
   *
   * public flag_dba_hist_sqlstat
   *
   * ------------------------- */
  PROCEDURE flag_dba_hist_sqlstat (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    l_count2 NUMBER := 0;
  BEGIN
    write_log('flag_dba_hist_sqlstat');

    -- in_plan_extension
    BEGIN
      -- all distinct phv from awr (stats record)
      FOR i IN (SELECT DISTINCT plan_hash_value
                  FROM sqlt$_dba_hist_sql_plan
                 WHERE statement_id = p_statement_id)
      LOOP
        l_count2 := l_count2 + 1;
        -- flagged plan could come from memory or awr. this is for link only.
        -- i could end up with rows in sqlt$_dba_hist_sqlstat for which there is no plan (mem nor awr)
        UPDATE sqlt$_dba_hist_sqlstat
           SET in_plan_extension = 'Y'
         WHERE statement_id = p_statement_id
           AND plan_hash_value = i.plan_hash_value;
      END LOOP;

      UPDATE sqlt$_dba_hist_sqlstat
         SET in_plan_extension = 'N'
       WHERE statement_id = p_statement_id
         AND in_plan_extension IS NULL;
    END;

    -- in_plan_summary_v
    BEGIN
      -- for each phv-inst_id duo find the set with largest executions
      FOR i IN (SELECT h.plan_hash_value,
                       h.instance_number,
                       MAX(h.executions_total) executions_total,
                       MIN(s.begin_interval_time) first_load_time,
                       MAX(s.end_interval_time) last_load_time
                  FROM sqlt$_dba_hist_sqlstat h,
                       sqlt$_dba_hist_snapshot s
                 WHERE h.statement_id = p_statement_id
                   AND h.statement_id = s.statement_id
                   AND h.snap_id = s.snap_id
                   AND h.dbid = s.dbid
                   AND h.instance_number = s.instance_number
                 GROUP BY
                       h.plan_hash_value,
                       h.instance_number)
      LOOP
        -- choose among duplicate rows the last one
        -- (so we can get the newest begin/end snap dates out of it)
        FOR j IN (SELECT ROWID row_id
                    FROM sqlt$_dba_hist_sqlstat
                   WHERE statement_id = p_statement_id
                     AND plan_hash_value = i.plan_hash_value
                     AND instance_number = i.instance_number
                     AND executions_total = i.executions_total
                   ORDER BY
                         snap_id DESC) -- take the last
        LOOP
          l_count := l_count + 1;
          UPDATE sqlt$_dba_hist_sqlstat
             SET in_plan_summary_v = 'Y',
                 first_load_time = i.first_load_time,
                 last_load_time = i.last_load_time
           WHERE ROWID = j.row_id;
          EXIT; -- just 1st
        END LOOP;
      END LOOP;

      UPDATE sqlt$_dba_hist_sqlstat
         SET in_plan_summary_v = 'N'
       WHERE statement_id = p_statement_id
         AND in_plan_summary_v IS NULL;
    END;

    COMMIT;
    write_log(l_count2||' rows flagged in in_plan_extension');
    write_log(l_count||' plans in in_plan_summary_v');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('flag_dba_hist_sqlstat: '||SQLERRM);
  END flag_dba_hist_sqlstat;

  /*************************************************************************************/

  /* -------------------------
   *
   * public best_and_worst_plans
   *
   * ------------------------- */
  PROCEDURE best_and_worst_plans (p_statement_id IN NUMBER)
  IS
  BEGIN
    write_log('best_and_worst_plans');

    -- best
    FOR i IN (SELECT plan_hash_value
                FROM sqlt$_plan_summary_v
               WHERE statement_id = p_statement_id
                 AND NVL(plan_hash_value, 0) > 0
                 AND sqlt$a.get_plan_link(p_statement_id, plan_hash_value) IS NOT NULL -- 11.4.3.1
               ORDER BY
                     DECODE(NVL(fetches, 0), 0, 0, -1), -- rows with fetches null or zero selected last
                     elapsed_time ASC NULLS LAST,
                     optimizer_cost ASC NULLS LAST)
    LOOP
      UPDATE sqlt$_sql_statement
         SET best_plan_hash_value = i.plan_hash_value
       WHERE statement_id = p_statement_id;
       EXIT; -- 1st
    END LOOP;

    -- worst
    FOR i IN (SELECT plan_hash_value
                FROM sqlt$_plan_summary_v
               WHERE statement_id = p_statement_id
                 AND NVL(plan_hash_value, 0) > 0
                 AND sqlt$a.get_plan_link(p_statement_id, plan_hash_value) IS NOT NULL -- 11.4.3.1
               ORDER BY
                     DECODE(NVL(fetches, 0), 0, 0, -1), -- rows with fetches null or zero selected last
                     elapsed_time DESC NULLS LAST,
                     optimizer_cost DESC NULLS LAST)
    LOOP
      UPDATE sqlt$_sql_statement
         SET worst_plan_hash_value = i.plan_hash_value
       WHERE statement_id = p_statement_id;
       EXIT; -- 1st
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('best_and_worst_plans: '||SQLERRM);
  END best_and_worst_plans;

  /*************************************************************************************/

  /* -------------------------
   *
   * private build_column_html_table_pred
   *
   * ------------------------- */
  PROCEDURE build_column_html_table_pred (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    tbl_rec sqlg$_column_html_table%ROWTYPE;

    PROCEDURE wa(p_text IN VARCHAR2)
    IS
    BEGIN
      IF p_text IS NOT NULL THEN
        SYS.DBMS_LOB.WRITEAPPEND (
          lob_loc => tbl_rec.html_table,
          amount  => LENGTH(p_text),
          buffer  => p_text );
      END IF;
    END wa;

    PROCEDURE append(p_clob IN CLOB)
    IS
    BEGIN
      IF p_clob IS NOT NULL THEN
        IF SYS.DBMS_LOB.GETLENGTH(p_clob) > 0 THEN
          SYS.DBMS_LOB.APPEND (
            dest_lob => tbl_rec.html_table,
            src_lob  => p_clob );
        END IF;
      END IF;
    END append;

  BEGIN
    write_log('build_column_html_table_pred');

    FOR i IN (SELECT DISTINCT column_name
                FROM sqlg$_column_predicate)
    LOOP
      l_count := l_count + 1;
      tbl_rec := NULL;
      tbl_rec.column_name := i.column_name;
      tbl_rec.type := 'P'; -- Predicates
      tbl_rec.html_table := '<table>'||LF;

      FOR j IN (SELECT DISTINCT plan_hash_value
                  FROM sqlg$_column_predicate
                 WHERE column_name = i.column_name
                 ORDER BY
                       plan_hash_value)
      LOOP
        wa(LF||'<tr><th>ID</th><th>Pred</th><th>phv: '||j.plan_hash_value||'</th>');
        IF sqlt$a.get_param('show_binds_in_predicates') = 'Y' THEN
          wa('<th>Peek</th><th>Capt</th>');
        END IF;
        wa('</tr>'||LF);

        FOR k IN (SELECT plan_line_id,
                         predicate_type,
                         predicate,
                         binds_html_table,
                         binds_html_table_capt
                    FROM sqlg$_column_predicate
                   WHERE column_name = i.column_name
                     AND plan_hash_value = j.plan_hash_value
                   ORDER BY
                         plan_line_id,
                         predicate_type)
        LOOP
          wa(
          '<tr>'||LF||
          '<td class="c">'||k.plan_line_id||'</td>'||LF||
          '<td class="c">'||k.predicate_type||'</td>'||LF||
          '<td nowrap class="l">'||sqlt$r.wrap_and_sanitize_html_clob(REPLACE(k.predicate, '"'))||'</td>'||LF);
          IF sqlt$a.get_param('show_binds_in_predicates') = 'Y' THEN
            wa('<td nowrap class="l">'||LF);
            append(k.binds_html_table);
            wa('</td>'||LF);
            wa('<td nowrap class="l">'||LF);
            append(k.binds_html_table_capt);
            wa('</td>'||LF);
          END IF;
          wa('</tr>'||LF);
        END LOOP;
      END LOOP;

      wa('</table>');
      INSERT INTO sqlg$_column_html_table VALUES tbl_rec;
    END LOOP;

    write_log(l_count||' column html tables built');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('build_column_html_table_pred: '||SQLERRM);
  END build_column_html_table_pred;

  /*************************************************************************************/

  /* -------------------------
   *
   * private build_column_html_table_idx
   *
   * ------------------------- */
  PROCEDURE build_column_html_table_idx (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    tbl_rec sqlg$_column_html_table%ROWTYPE;

    PROCEDURE wa(p_text IN VARCHAR2)
    IS
    BEGIN
      IF p_text IS NOT NULL THEN
        SYS.DBMS_LOB.WRITEAPPEND (
          lob_loc => tbl_rec.html_table,
          amount  => LENGTH(p_text),
          buffer  => p_text );
      END IF;
    END wa;

  BEGIN
    write_log('build_column_html_table_idx');

    FOR i IN (SELECT DISTINCT owner, table_name, column_name
                FROM sqlt$_dba_all_table_cols_v
               WHERE statement_id = p_statement_id
                 AND in_indexes = 'TRUE')
    LOOP
      l_count := l_count + 1;
      tbl_rec := NULL;
      tbl_rec.owner := i.owner;
      tbl_rec.table_name := i.table_name;
      tbl_rec.column_name := i.column_name;
      tbl_rec.type := 'I'; -- Indexes
      tbl_rec.html_table := '<table>'||LF;

      FOR j IN (SELECT index_owner, index_name
                  FROM sqlt$_dba_ind_columns
                 WHERE statement_id = p_statement_id
                   AND table_owner = i.owner
                   AND table_name = i.table_name
                   AND column_name = i.column_name
                 UNION
                SELECT ic.index_owner, ic.index_name
                  FROM sqlt$_dba_tab_cols tc,
                       sqlt$_dba_ind_columns ic
                 WHERE tc.statement_id = p_statement_id
                   AND tc.owner = i.owner
                   AND tc.table_name = i.table_name
                   AND tc.data_default IS NOT NULL
                   AND TRIM('"' FROM REPLACE(DBMS_LOB.SUBSTR(tc.data_default), ' ')) = i.column_name
                   AND tc.statement_id = ic.statement_id
                   AND tc.owner = ic.table_owner
                   AND tc.table_name = ic.table_name
                   AND tc.column_name = ic.column_name
                 ORDER BY
                       index_name)
      LOOP
        wa(
        LF||'<tr><th>'||j.index_name||'</th></tr>'||LF||
        --'<tr><td nowrap class="l">'||sqlt$a.get_index_column_names(p_statement_id, j.index_owner, j.index_name, 'NO', '</td></tr>'||LF||'<tr><td nowrap class="l">')||
        '<tr><td nowrap class="l">'||sqlt$a.get_index_column_names(p_statement_id, j.index_owner, j.index_name, 'YES', '</td></tr>'||LF||'<tr><td nowrap class="l">')||
        '</td></tr>'||LF);
      END LOOP;

      wa('</table>');
      INSERT INTO sqlg$_column_html_table VALUES tbl_rec;
    END LOOP;

    write_log(l_count||' column html tables built');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('build_column_html_table_idx: '||SQLERRM);
  END build_column_html_table_idx;

  /*************************************************************************************/

  /* -------------------------
   *
   * private obj_cols_sec
   *
   * ------------------------- */
  FUNCTION obj_cols_sec (
    p_statement_id IN NUMBER,
    p_object_name  IN VARCHAR2,
    p_owner        IN VARCHAR2,
    p_object_id    IN NUMBER,
    p_object_type  IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_vers       NUMBER;
    l_usage      NUMBER;
    l_hgrm       NUMBER;
    l_hgrm_vers  NUMBER;
    l_cons       NUMBER;
    l_index_cols NUMBER;
    l_part       NUMBER;
    l_indexes    NUMBER;
    l_metadata   NUMBER;
    l_return     VARCHAR2(32767);
    l_typ        VARCHAR2(100);

  BEGIN
    IF p_object_type = 'INDEX' THEN
      l_typ := 'idx';
      sqlt$a.ind_cols_sec (
        p_statement_id => p_statement_id,
        p_index_name   => p_object_name,
        p_owner        => p_owner,
        x_vers         => l_vers,
        x_usage        => l_usage,
        x_hgrm         => l_hgrm,
        x_hgrm_vers    => l_hgrm_vers,
        x_part         => l_part,
        x_metadata     => l_metadata );
    ELSE
      l_typ := 'tab';
      sqlt$a.tbl_cols_sec (
        p_statement_id => p_statement_id,
        p_table_name   => p_object_name,
        p_owner        => p_owner,
        x_vers         => l_vers,
        x_usage        => l_usage,
        x_hgrm         => l_hgrm,
        x_hgrm_vers    => l_hgrm_vers,
        x_cons         => l_cons,
        x_index_cols   => l_index_cols,
        x_part         => l_part,
        x_indexes      => l_indexes,
        x_metadata     => l_metadata );
    END IF;

    l_return := LF||'<tr><th>'||INITCAP(p_object_type)||' Columns</th></tr>';

    l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Col Statistics', 'DBA_TAB_COLS', '#'||l_typ||'_cols_cbo_'||p_object_id)||'</td></tr>';

    IF l_vers > 0 THEN
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Stats Versions', 'DBA_COL_STATS_VERSIONS', '#'||l_typ||'_cols_vers_'||p_object_id)||'</td></tr>';
    ELSIF sqlt$a.get_param('r_gran_vers') IN ('COLUMN', 'HISTOGRAM') THEN
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Stats Versions', 'DBA_COL_STATS_VERSIONS')||'</td></tr>';
    END IF;

    IF l_usage > 0 THEN
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Column Usage', 'COL_USAGE$', '#'||l_typ||'_cols_usage_'||p_object_id)||'</td></tr>';
    ELSE
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Column Usage', 'COL_USAGE$');
    END IF;

    l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Col Properties', 'DBA_TAB_COLS', '#'||l_typ||'_cols_prop_'||p_object_id)||'</td></tr>';

    IF l_hgrm > 0 THEN
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Histograms', 'DBA_TAB_HISTOGRAMS', '#'||l_typ||'_col_hgrm_'||p_object_id)||'</td></tr>';
    ELSE
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Histograms', 'DBA_TAB_HISTOGRAMS')||'</td></tr>';
    END IF;

    IF l_hgrm_vers > 0 THEN
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Hist Versions', 'DBA_HISTGRM_STATS_VERSN', '#'||l_typ||'_col_hgrm_vers_'||p_object_id)||'</td></tr>';
    ELSIF sqlt$a.get_param('r_gran_vers') = 'HISTOGRAM' THEN
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Hist Versions', 'DBA_HISTGRM_STATS_VERSN')||'</td></tr>';
    END IF;

    l_return := l_return||LF||'<tr><th>'||INITCAP(p_object_type)||'</th></tr>';

    IF p_object_type = 'TABLE' THEN
      IF l_cons > 0 THEN
        l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Constraints', 'DBA_CONSTRAINTS', '#'||l_typ||'_cons_'||p_object_id)||'</td></tr>';
      ELSE
        l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Constraints', 'DBA_CONSTRAINTS');
      END IF;

      IF l_index_cols > 0 THEN
        l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Indexed Cols', 'DBA_IND_COLUMNS', '#idxed_cols_'||p_object_id)||'</td></tr>';
      ELSE
        l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Indexed Cols', 'DBA_IND_COLUMNS');
      END IF;

      IF l_indexes > 0 THEN
        l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Indexes', 'DBA_INDEXES', '#idx_sum_'||p_object_id)||'</td></tr>';
      ELSE
        l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Indexes', 'DBA_INDEXES');
      END IF;
    END IF;

    IF l_part > 0 THEN
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Partitions', 'DBA_XXX_PARTITIONS', '#'||l_typ||'_part_'||p_object_id)||'</td></tr>';
    ELSE
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Partitions', 'DBA_XXX_PARTITIONS');
    END IF;

    IF l_metadata > 0 THEN
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Metadata', 'SYS.DBMS_METADATA.GET_DDL', '#meta_'||p_object_id)||'</td></tr>';
    ELSE
      l_return := l_return||LF||'<tr><td nowrap class="l">'||sqlt$a.mot('Metadata', 'SYS.DBMS_METADATA.GET_DDL');
    END IF;

    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('obj_cols_sec'||p_object_id||': '||SQLERRM);
      RETURN l_return;
  END obj_cols_sec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private fix_cardinality_line_0
   *
   * ------------------------- */
  PROCEDURE fix_cardinality_line_0 (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
  BEGIN
    write_log('fix_cardinality_line_0');

    FOR i IN (SELECT p0.source,
                     p0.plan_hash_value,
                     p0.plan_id,
                     p0.inst_id,
                     p0.child_number,
                     p0.child_address,
                     p1.cardinality
                FROM sqlt$_plan_extension p0,
                     sqlt$_plan_extension p1
               WHERE p0.statement_id = p_statement_id
                 AND p0.id = 0
                 AND p0.cardinality IS NULL
                 AND p0.statement_id = p1.statement_id
                 AND p0.source = p1.source
                 AND p0.plan_hash_value = p1.plan_hash_value
                 AND p0.plan_id = p1.plan_id
                 AND p0.inst_id = p1.inst_id
                 AND p0.child_number = p1.child_number
                 AND p0.child_address = p1.child_address
                 AND p1.id = 1
                 AND p1.cardinality IS NOT NULL)
    LOOP
      l_count := l_count + 1;

      UPDATE sqlt$_plan_extension
         SET cardinality = i.cardinality
       WHERE statement_id = p_statement_id
         AND id = 0
         AND cardinality IS NULL
         AND source = i.source
         AND plan_hash_value = i.plan_hash_value
         AND plan_id = i.plan_id
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address;
    END LOOP;

    write_log(l_count||' plans fixed');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('fix_cardinality_line_0: '||SQLERRM);
  END fix_cardinality_line_0;

  /*************************************************************************************/

  /* -------------------------
   *
   * private execution_order
   *
   * ------------------------- */
  PROCEDURE execution_order (p_statement_id IN NUMBER)
  IS
    l_exec_order NUMBER;

    /* -------------------------
     *
     * recursive execution_order.assign_execution_order
     *
     * ------------------------- */
    PROCEDURE assign_execution_order (
      p_source          IN VARCHAR2,
      p_plan_hash_value IN NUMBER,
      p_plan_id         IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER )
    IS
    BEGIN
      FOR j IN (SELECT id
                  FROM sqlt$_plan_extension
                 WHERE statement_id = p_statement_id
                   AND source = p_source
                   AND plan_hash_value = p_plan_hash_value
                   AND plan_id = p_plan_id
                   AND inst_id = p_inst_id
                   AND child_number = p_child_number
                   AND child_address = p_child_address
                   AND parent_id = p_id
                 ORDER BY
                       position)
      LOOP
        assign_execution_order (
          p_source          => p_source,
          p_plan_hash_value => p_plan_hash_value,
          p_plan_id         => p_plan_id,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id );
      END LOOP;

      l_exec_order := l_exec_order + 1;

      UPDATE sqlt$_plan_extension
         SET exec_order = l_exec_order
       WHERE statement_id = p_statement_id
         AND source = p_source
         AND plan_hash_value = p_plan_hash_value
         AND plan_id = p_plan_id
         AND inst_id = p_inst_id
         AND child_number = p_child_number
         AND child_address = p_child_address
         AND id = p_id;
    END assign_execution_order;

  BEGIN
    write_log('execution_order');

    FOR i IN (SELECT source,
                     plan_hash_value,
                     plan_id,
                     inst_id,
                     child_number,
                     child_address,
                     id
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND parent_id IS NULL)
    LOOP
      l_exec_order := 0;

      assign_execution_order (
        p_source          => i.source,
        p_plan_hash_value => i.plan_hash_value,
        p_plan_id         => i.plan_id,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id );
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('execution_order: '||SQLERRM);
  END execution_order;

  /*************************************************************************************/

  /* -------------------------
   *
   * public sqlt_plan_hash_value
   *
   * called by sqlt$t.perm_transformation and sqltcompare.sql
   *
   * this algorithm has to be in sync with xplore.snapshot_plan.sqlt_plan_hash_value and xhume.snapshot_plan.sqlt_plan_hash_value
   *
   * ------------------------- */
  PROCEDURE sqlt_plan_hash_value (p_statement_id IN NUMBER)
  IS
    l_expr VARCHAR2(32767);
    l_opt VARCHAR2(32767);
    l_hash NUMBER;
    l_hash2 NUMBER;
    l_ora_hash NUMBER;
    l_access_predicates VARCHAR2(32767);
    l_filter_predicates VARCHAR2(32767);
  BEGIN
    FOR i IN (SELECT source,
                     inst_id,
                     plan_hash_value,
                     plan_id,
                     task_id,
                     child_number,
                     child_address,
                     MIN(id) min_id
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND sqlt_plan_hash_value IS NULL
               GROUP BY
                     source,
                     inst_id,
                     plan_hash_value,
                     plan_id,
                     task_id,
                     child_number,
                     child_address)
    LOOP
      l_hash := 0;
      l_hash2 := 0;
      FOR j IN (SELECT id,
                       parent_id,
                       operation,
                       options,
                       object_owner,
                       object_name,
                       object_type,
                       access_predicates,
                       filter_predicates
                  FROM sqlt$_plan_extension
                 WHERE statement_id = p_statement_id
                   AND source = i.source
                   AND inst_id = i.inst_id
                   AND plan_hash_value = i.plan_hash_value
                   AND plan_id = i.plan_id
                   AND task_id = i.task_id
                   AND child_number = i.child_number
                   AND child_address = i.child_address
                   AND id > i.min_id)
      LOOP
        l_opt := TRIM(REPLACE(j.options, 'STORAGE'));
        l_expr := j.id||j.operation||j.parent_id||l_opt;
        IF j.object_type LIKE 'INDEX%' OR j.operation LIKE 'INDEX%' THEN
          l_expr := l_expr||sqlt$a.get_index_column_names(p_statement_id, j.object_owner, j.object_name, 'YES', p_table_name => 'YES');
        ELSIF j.object_type LIKE 'TABLE%' OR j.operation LIKE 'TABLE%' OR j.object_type = 'VIEW' OR j.operation = 'VIEW' THEN
          IF j.object_name NOT LIKE 'SYS_TEMP%' AND j.object_name NOT LIKE 'index$_join$_%' AND j.object_name NOT LIKE 'VW_ST%' THEN
            l_expr := l_expr||j.object_name;
          END IF;
        END IF;
        SELECT ORA_HASH(l_expr) INTO l_ora_hash FROM DUAL;
        l_hash := l_hash + l_ora_hash;
        l_hash2 := l_hash2 + l_ora_hash;
        IF j.access_predicates IS NOT NULL THEN
          l_access_predicates := SYS.DBMS_LOB.SUBSTR(j.access_predicates);
          SELECT ORA_HASH(l_access_predicates) INTO l_ora_hash FROM DUAL;
          l_hash2 := l_hash2 + l_ora_hash;
        END IF;
        IF j.filter_predicates IS NOT NULL THEN
          l_filter_predicates := SYS.DBMS_LOB.SUBSTR(j.filter_predicates);
          SELECT ORA_HASH(l_filter_predicates) INTO l_ora_hash FROM DUAL;
          l_hash2 := l_hash2 + l_ora_hash;
        END IF;
      END LOOP;
      l_hash := MOD(l_hash, 1e5);
      l_hash2 := MOD(l_hash2, 1e5);

      UPDATE sqlt$_plan_extension
         SET sqlt_plan_hash_value = l_hash,
             sqlt_plan_hash_value2 = l_hash2
       WHERE statement_id = p_statement_id
         AND source = i.source
         AND inst_id = i.inst_id
         AND plan_hash_value = i.plan_hash_value
         AND plan_id = i.plan_id
         AND task_id = i.task_id
         AND child_number = i.child_number
         AND child_address = i.child_address;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sqlt_plan_hash_value: '||SQLERRM);
  END sqlt_plan_hash_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * private real_depth
   *
   * ------------------------- */
  PROCEDURE real_depth (p_statement_id IN NUMBER)
  IS
    /* -------------------------
     *
     * recursive real_depth.assign_real_depth
     *
     * ------------------------- */
    PROCEDURE assign_real_depth (
      p_source          IN VARCHAR2,
      p_plan_hash_value IN NUMBER,
      p_plan_id         IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_real_depth      IN NUMBER )
    IS
    BEGIN
      FOR j IN (SELECT id
                  FROM sqlt$_plan_extension
                 WHERE statement_id = p_statement_id
                   AND source = p_source
                   AND plan_hash_value = p_plan_hash_value
                   AND plan_id = p_plan_id
                   AND inst_id = p_inst_id
                   AND child_number = p_child_number
                   AND child_address = p_child_address
                   AND parent_id = p_id)
      LOOP
        assign_real_depth (
          p_source          => p_source,
          p_plan_hash_value => p_plan_hash_value,
          p_plan_id         => p_plan_id,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_real_depth      => p_real_depth + 1);
      END LOOP;

      UPDATE sqlt$_plan_extension
         SET real_depth = p_real_depth
       WHERE statement_id = p_statement_id
         AND source = p_source
         AND plan_hash_value = p_plan_hash_value
         AND plan_id = p_plan_id
         AND inst_id = p_inst_id
         AND child_number = p_child_number
         AND child_address = p_child_address
         AND id = p_id;
    END assign_real_depth;

  BEGIN
    write_log('real_depth');

    FOR i IN (SELECT source,
                     plan_hash_value,
                     plan_id,
                     inst_id,
                     child_number,
                     child_address,
                     id
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND parent_id IS NULL)
    LOOP
      assign_real_depth (
        p_source          => i.source,
        p_plan_hash_value => i.plan_hash_value,
        p_plan_id         => i.plan_id,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_real_depth      => 0 );
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('real_depth: '||SQLERRM);
  END real_depth;

  /*************************************************************************************/

  /* -------------------------
   *
   * private real_depth_m
   *
   * ------------------------- */
  PROCEDURE real_depth_m (p_statement_id IN NUMBER)
  IS
    /* -------------------------
     *
     * recursive real_depth_m.assign_real_depth_m
     *
     * ------------------------- */
    PROCEDURE assign_real_depth_m (
      --p_source          IN VARCHAR2,
      p_plan_hash_value IN NUMBER,
      --p_plan_id         IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_real_depth      IN NUMBER )
    IS
    BEGIN
      FOR j IN (SELECT id
                  FROM sqlt$_gv$sql_plan
                 WHERE statement_id = p_statement_id
                   --AND source = p_source
                   AND plan_hash_value = p_plan_hash_value
                   --AND plan_id = p_plan_id
                   AND inst_id = p_inst_id
                   AND child_number = p_child_number
                   AND child_address = p_child_address
                   AND parent_id = p_id)
      LOOP
        assign_real_depth_m (
          --p_source          => p_source,
          p_plan_hash_value => p_plan_hash_value,
          --p_plan_id         => p_plan_id,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_real_depth      => p_real_depth + 1);
      END LOOP;

      UPDATE sqlt$_gv$sql_plan
         SET real_depth = p_real_depth
       WHERE statement_id = p_statement_id
         --AND source = p_source
         AND plan_hash_value = p_plan_hash_value
         --AND plan_id = p_plan_id
         AND inst_id = p_inst_id
         AND child_number = p_child_number
         AND child_address = p_child_address
         AND id = p_id;
    END assign_real_depth_m;

  BEGIN
    write_log('real_depth_m');

    FOR i IN (SELECT --source,
                     plan_hash_value,
                     --plan_id,
                     inst_id,
                     child_number,
                     child_address,
                     id
                FROM sqlt$_gv$sql_plan
               WHERE statement_id = p_statement_id
                 AND parent_id IS NULL)
    LOOP
      assign_real_depth_m (
        --p_source          => i.source,
        p_plan_hash_value => i.plan_hash_value,
        --p_plan_id         => i.plan_id,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_real_depth      => 0 );
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('real_depth_m: '||SQLERRM);
  END real_depth_m;

  /*************************************************************************************/

  /* -------------------------
   *
   * public plan_operation
   *
   * called by sqlt$t.perm_transformation
   *
   * ------------------------- */
  PROCEDURE plan_operation (p_statement_id IN NUMBER)
  IS
    l_plan_operation    sqlt$_plan_extension.plan_operation%TYPE;
    l_operation_caption sqlt$_plan_extension.operation_caption%TYPE;
    l_operation_caption1 sqlt$_plan_extension.operation_caption%TYPE;
    l_operation_caption2 sqlt$_plan_extension.operation_caption%TYPE;
    l_operation_caption3 sqlt$_plan_extension.operation_caption%TYPE;
    l_separator VARCHAR2(12) := '<br>';
    l_object_id NUMBER;
    l_current DATE;
    l_before_st sqlt$_dba_tab_stats_versions.save_time%TYPE;
    l_after_st sqlt$_dba_tab_stats_versions.save_time%TYPE;
    l_plan_timestamp DATE;

  BEGIN
    write_log('plan_operation');

    FOR i IN (SELECT 'X' row_type,
                     e.ROWID row_id,
                     e.source,
                     e.plan_hash_value,
                     e.timestamp,
                     e.operation,
                     e.options,
                     e.object_node,
                     e.object#,
                     e.object_owner,
                     e.object_name,
                     e.object_alias,
                     e.object_type,
                     e.qblock_name,
                     e.real_depth,
                     CASE
                     WHEN e.object_type LIKE '%TABLE%' OR e.object_type LIKE '%MAT%VIEW%' THEN 'TABLE'
                     WHEN e.object_type LIKE '%INDEX%' THEN 'INDEX'
                     END obj_type,
                     CASE
                     WHEN e.object_type LIKE '%TABLE%' OR e.object_type LIKE '%MAT%VIEW%' THEN 'tab_cols_cbo_'
                     WHEN e.object_type LIKE '%INDEX%' THEN 'idx_cols_cbo_'
                     END href,
                     m.skipped
                FROM sqlt$_plan_extension e,
                     sqlt$_display_map m
               WHERE e.statement_id = p_statement_id
                 AND e.statement_id = m.statement_id(+)
                 AND e.source = m.source(+)
                 AND e.plan_hash_value = m.plan_hash_value(+)
                 AND e.inst_id = m.inst_id(+)
                 AND e.child_number = m.child_number(+)
                 AND e.id = m.operation_id(+)
               UNION ALL
              SELECT 'M' row_type,
                     s.ROWID row_id,
                     'GV$SQL_PLAN' source,
                     s.plan_hash_value,
                     s.timestamp,
                     s.operation,
                     s.options,
                     s.object_node,
                     s.object#,
                     s.object_owner,
                     s.object_name,
                     s.object_alias,
                     s.object_type,
                     s.qblock_name,
                     s.real_depth,
                     CASE
                     WHEN s.object_type LIKE '%TABLE%' OR s.object_type LIKE '%MAT%VIEW%' THEN 'TABLE'
                     WHEN s.object_type LIKE '%INDEX%' THEN 'INDEX'
                     END obj_type,
                     CASE
                     WHEN s.object_type LIKE '%TABLE%' OR s.object_type LIKE '%MAT%VIEW%' THEN 'tab_cols_cbo_'
                     WHEN s.object_type LIKE '%INDEX%' THEN 'idx_cols_cbo_'
                     END href,
                     m.skipped
                FROM sqlt$_gv$sql_plan s,
                     sqlt$_display_map m
               WHERE s.statement_id = p_statement_id
                 AND s.statement_id = m.statement_id(+)
                 AND 'GV$SQL_PLAN' = m.source(+)
                 AND s.plan_hash_value = m.plan_hash_value(+)
                 AND s.inst_id = m.inst_id(+)
                 AND s.child_number = m.child_number(+)
                 AND s.id = m.operation_id(+))
    LOOP
      l_object_id := sqlt$a.get_object_id(p_statement_id, i.obj_type, i.object_owner, i.object_name);
      l_plan_timestamp := i.timestamp;

      -- timestamp is usually too old for awr plans so better use date of oldest snapshot
      IF i.source = 'DBA_HIST_SQL_PLAN' THEN
        SELECT GREATEST(l_plan_timestamp, MIN(first_load_time))
          INTO l_plan_timestamp
          FROM sqlt$_dba_hist_sqlstat
         WHERE statement_id = p_statement_id
           AND plan_hash_value = i.plan_hash_value;
      END IF;

      -- plan operation
      BEGIN
	    
        IF i.skipped = 1 THEN  --
          l_plan_operation := REPLACE(LPAD('~', i.real_depth, '....+'), '~', NBSP)||DEL_O||i.operation; --
        ELSE --
          l_plan_operation := REPLACE(LPAD('~', i.real_depth, '....+'), '~', NBSP)||i.operation;
        END IF; --
		  
        IF i.options IS NOT NULL THEN
          IF i.skipped = 1 THEN --
            l_plan_operation := l_plan_operation||' '||i.options||DEL_C; --
          ELSE --
            l_plan_operation := l_plan_operation||' '||i.options;
          END IF; --
        END IF;

        IF i.object_name IS NOT NULL AND i.object_name NOT LIKE 'TQ:%' THEN -- avoid :TQ10001
          IF l_object_id IS NULL THEN
            IF i.skipped = 1 THEN --
              l_plan_operation := l_plan_operation||DEL_O||' '||i.object_name||DEL_C; --
            ELSE --
              l_plan_operation := l_plan_operation||' '||i.object_name;
            END IF; --
          ELSE
            IF i.skipped = 1 THEN --
              l_plan_operation := l_plan_operation||' '||'<a href="#'||i.href||l_object_id||'">'||DEL_O||i.object_name||DEL_C||'</a>'; --
            ELSE --
              l_plan_operation := l_plan_operation||' '||'<a href="#'||i.href||l_object_id||'">'||i.object_name||'</a>';
            END IF; --      
          END IF;
        END IF;

        IF i.object_node IS NOT NULL AND i.object_node NOT LIKE '%:%' THEN -- avoid :Q10001
          l_plan_operation := l_plan_operation||'@'||i.object_node;
        END IF;
      END;

      -- operation caption
      BEGIN
        l_operation_caption1 := NULL;
        l_operation_caption2 := NULL;
        l_operation_caption3 := NULL;

        IF i.object_type LIKE '%FIXED%' OR i.operation LIKE '%FIXED%' THEN
          BEGIN
            SELECT last_analyzed,
                   '<hr><b>Current Statistics:</b>'||l_separator||
                   'Analyzed: '||TO_CHAR(last_analyzed, LONG_DATE_FORMAT)||l_separator||
                   'NumRows: '||num_rows||l_separator||
                   'Blocks: '||blocks||l_separator||
                   'Sample: '||sample_size||l_separator
              INTO l_current,
                   l_operation_caption2
              FROM sqlt$_dba_tab_statistics
             WHERE statement_id = p_statement_id
               AND owner = i.object_owner
               AND table_name = i.object_name
               AND object_type = 'FIXED TABLE'
               AND partition_name IS NULL
               AND ROWNUM = 1;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              write_log('plan_operation_fixed '||i.object_name||': '||SQLERRM);
            WHEN OTHERS THEN
              write_error('plan_operation_fixed '||i.object_name||': '||SQLERRM);
          END;
        ELSIF i.operation||i.options||i.object_type LIKE '%TABLE%' THEN
          BEGIN
            BEGIN
              SELECT last_analyzed,
                     'Owner: '||i.object_owner||l_separator||
                     (CASE WHEN partitioned = 'YES' THEN 'Partitioned'||l_separator END)||
                     (CASE WHEN temporary = 'Y' THEN 'Temporary'||l_separator END),
                     '<hr><b>Current Table Statistics:</b>'||l_separator||
                     'Analyzed: '||TO_CHAR(last_analyzed, LONG_DATE_FORMAT)||l_separator||
                     'TblRows: '||num_rows||l_separator||
                     'Blocks: '||blocks||l_separator||
                     'Sample: '||sample_size||l_separator
                INTO l_current,
                     l_operation_caption1,
                     l_operation_caption2
                FROM sqlt$_dba_all_tables_v
               WHERE statement_id = p_statement_id
                 AND owner = i.object_owner
                 AND table_name = i.object_name
                 AND ROWNUM = 1;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                l_current := NULL;
                l_operation_caption1 := NULL;
                l_operation_caption2 := NULL;
              WHEN OTHERS THEN
                write_error('plan_operation_table '||i.object_name||': '||SQLERRM);
            END;

            -- plan statistics
            IF l_current IS NOT NULL THEN
              SELECT MAX(save_time)
                INTO l_before_st
                FROM sqlt$_dba_tab_stats_versions
               WHERE statement_id = p_statement_id
                 AND object_type = 'TABLE'
                 AND owner = i.object_owner
                 AND table_name = i.object_name
                 AND save_time < l_plan_timestamp;

              SELECT MIN(save_time)
                INTO l_after_st
                FROM sqlt$_dba_tab_stats_versions
               WHERE statement_id = p_statement_id
                 AND object_type = 'TABLE'
                 AND owner = i.object_owner
                 AND table_name = i.object_name
                 AND save_time > l_plan_timestamp;

              IF l_before_st IS NOT NULL AND l_after_st IS NOT NULL THEN
                BEGIN
                  SELECT '<hr><b>Statistics for Plan:</b>'||l_separator||
                         'Analyzed: '||TO_CHAR(last_analyzed, LONG_DATE_FORMAT)||l_separator||
                         'TblRows: '||num_rows||l_separator||
                         'Blocks: '||blocks||l_separator||
                         'Sample: '||sample_size||l_separator
                    INTO l_operation_caption3
                    FROM sqlt$_dba_tab_stats_versions
                   WHERE statement_id = p_statement_id
                     AND object_type = 'TABLE'
                     AND owner = i.object_owner
                     AND table_name = i.object_name
                     AND save_time = l_after_st
                     AND ROWNUM = 1;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    l_operation_caption3 :=
                    '<hr><b>Statistics for Plan:</b>'||l_separator||
                    'Unknown'||l_separator;
                  WHEN OTHERS THEN
                    write_error('plan_operation_table2 '||i.object_name||': '||SQLERRM);
                END;
              ELSIF l_before_st IS NULL AND l_after_st IS NOT NULL THEN
                l_operation_caption3 :=
                '<hr><b>Statistics for Plan:</b>'||l_separator||
                'Unknown'||l_separator;
              ELSIF l_before_st IS NOT NULL AND l_after_st IS NULL THEN
                l_operation_caption3 :=
                '<hr><b>Statistics for Plan:</b>'||l_separator||
                'Same as Current'||l_separator;
              ELSIF l_before_st IS  NULL AND l_after_st IS NULL THEN
                IF l_plan_timestamp < l_current THEN
                  l_operation_caption3 :=
                  '<hr><b>Statistics for Plan:</b>'||l_separator||
                  'Unknown'||l_separator;
                ELSE
                  l_operation_caption3 :=
                  '<hr><b>Statistics for Plan:</b>'||l_separator||
                  'Same as Current'||l_separator;
                END IF;
              END IF;
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
              write_error('plan_operation_table: '||SQLERRM);
          END;
        ELSIF i.operation||i.object_type LIKE '%INDEX%' THEN
          BEGIN
            BEGIN
              SELECT x.last_analyzed,
                     'IdxOwner: '||i.object_owner||l_separator||
                     'IdxType: '||x.index_type||l_separator||
                     (CASE WHEN x.partitioned = 'YES' THEN 'Partitioned'||l_separator END)||
                     (CASE WHEN x.temporary = 'Y' THEN 'Temporary'||l_separator END)||
                     'Table: '||x.table_owner||'.'||x.table_name||l_separator,
                     '<hr><b>Current Index Statistics:</b>'||l_separator||
                     'Analyzed: '||TO_CHAR(x.last_analyzed, LONG_DATE_FORMAT)||l_separator||
                     'IdxRows: '||x.num_rows||l_separator||
                     'BLevel: '||x.blevel||l_separator||
                     'LBlocks: '||x.leaf_blocks||l_separator||
                     'CLUF: '||x.clustering_factor||l_separator||
                     'NDK: '||x.distinct_keys||l_separator||
                     'Sample: '||x.sample_size||l_separator
                INTO l_current,
                     l_operation_caption1,
                     l_operation_caption2
                FROM sqlt$_dba_indexes x
               WHERE x.statement_id = p_statement_id
                 AND x.owner = i.object_owner
                 AND x.index_name = i.object_name
                 AND ROWNUM = 1;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                l_current := NULL;
                l_operation_caption1 := NULL;
                l_operation_caption2 := NULL;
              WHEN OTHERS THEN
                write_error('plan_operation_index '||i.object_name||': '||SQLERRM);
            END;

            -- plan statistics
            IF l_current IS NOT NULL THEN
              SELECT MAX(save_time)
                INTO l_before_st
                FROM sqlt$_dba_ind_stats_versions
               WHERE statement_id = p_statement_id
                 AND object_type = 'INDEX'
                 AND owner = i.object_owner
                 AND index_name = i.object_name
                 AND save_time < l_plan_timestamp;

              SELECT MIN(save_time)
                INTO l_after_st
                FROM sqlt$_dba_ind_stats_versions
               WHERE statement_id = p_statement_id
                 AND object_type = 'INDEX'
                 AND owner = i.object_owner
                 AND index_name = i.object_name
                 AND save_time > l_plan_timestamp;

              IF l_before_st IS NOT NULL AND l_after_st IS NOT NULL THEN
                BEGIN
                  SELECT '<hr><b>Statistics for Plan:</b>'||l_separator||
                         'Analyzed: '||TO_CHAR(last_analyzed, LONG_DATE_FORMAT)||l_separator||
                         'IdxRows: '||num_rows||l_separator||
                         'BLevel: '||blevel||l_separator||
                         'LBlocks: '||leaf_blocks||l_separator||
                         'CLUF: '||clustering_factor||l_separator||
                         'NDK: '||distinct_keys||l_separator||
                         'Sample: '||sample_size||l_separator
                    INTO l_operation_caption3
                    FROM sqlt$_dba_ind_stats_versions
                   WHERE statement_id = p_statement_id
                     AND object_type = 'INDEX'
                     AND owner = i.object_owner
                     AND index_name = i.object_name
                     AND save_time = l_after_st
                     AND ROWNUM = 1;
                EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                    l_operation_caption3 :=
                    '<hr><b>Statistics for Plan:</b>'||l_separator||
                    'Unknown'||l_separator;
                  WHEN OTHERS THEN
                    write_error('plan_operation_index2 '||i.object_name||': '||SQLERRM);
                END;
              ELSIF l_before_st IS NULL AND l_after_st IS NOT NULL THEN
                l_operation_caption3 :=
                '<hr><b>Statistics for Plan:</b>'||l_separator||
                'Unknown'||l_separator;
              ELSIF l_before_st IS NOT NULL AND l_after_st IS NULL THEN
                l_operation_caption3 :=
                '<hr><b>Statistics for Plan:</b>'||l_separator||
                'Same as Current'||l_separator;
              ELSIF l_before_st IS  NULL AND l_after_st IS NULL THEN
                IF l_plan_timestamp < l_current THEN
                  l_operation_caption3 :=
                  '<hr><b>Statistics for Plan:</b>'||l_separator||
                  'Unknown'||l_separator;
                ELSE
                  l_operation_caption3 :=
                  '<hr><b>Statistics for Plan:</b>'||l_separator||
                  'Same as Current'||l_separator;
                END IF;
              END IF;
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
              write_error('plan_operation_index: '||SQLERRM);
          END;
        END IF;

        IF i.object# IS NOT NULL THEN
          l_operation_caption1 := 'Object#: '||i.object#||l_separator||l_operation_caption1;
        END IF;

        IF i.qblock_name IS NOT NULL THEN
          l_operation_caption1 := l_operation_caption1||'QBlock: '||i.qblock_name||l_separator;
        END IF;

        IF i.object_alias IS NOT NULL THEN
          l_operation_caption1 := l_operation_caption1||'Alias: '||i.object_alias||l_separator;
        END IF;

        l_operation_caption := l_operation_caption1||l_operation_caption2||l_operation_caption3;
        l_operation_caption := SUBSTR(l_operation_caption, 1, LENGTH(l_operation_caption) - LENGTH(l_separator));
      END;

      -- update
      IF i.row_type = 'X' THEN
        UPDATE sqlt$_plan_extension
           SET plan_operation = l_plan_operation,
               operation_caption = l_operation_caption
         WHERE ROWID = i.row_id;
      ELSIF i.row_type = 'M' THEN
        UPDATE sqlt$_gv$sql_plan
           SET plan_operation = l_plan_operation,
               operation_caption = l_operation_caption
         WHERE ROWID = i.row_id;
      END IF;
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('plan_operation: '||SQLERRM);
  END plan_operation;

  /*************************************************************************************/

  /* -------------------------
   *
   * public top_cost
   *
   * called by sqlt$t.perm_transformation
   *
   * ------------------------- */
  PROCEDURE top_cost (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_cost.fill_blanks
     *
     * ------------------------- */
    PROCEDURE fill_blanks (
      p_source          IN VARCHAR2,
      p_plan_hash_value IN NUMBER,
      p_plan_id         IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER )
    IS
    BEGIN
      FOR j IN (SELECT id
                  FROM sqlt$_plan_extension
                 WHERE statement_id = p_statement_id
                   AND source = p_source
                   AND plan_hash_value = p_plan_hash_value
                   AND plan_id = p_plan_id
                   AND inst_id = p_inst_id
                   AND child_number = p_child_number
                   AND child_address = p_child_address
                   AND parent_id = p_id)
      LOOP
        fill_blanks (
          p_source          => p_source,
          p_plan_hash_value => p_plan_hash_value,
          p_plan_id         => p_plan_id,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id);
      END LOOP;

      UPDATE sqlt$_plan_extension m
         SET m.cost = (
      SELECT SUM(s.cost)
        FROM sqlt$_plan_extension s
       WHERE s.statement_id = p_statement_id
         AND s.source = p_source
         AND s.plan_hash_value = p_plan_hash_value
         AND s.plan_id = p_plan_id
         AND s.inst_id = p_inst_id
         AND s.child_number = p_child_number
         AND s.child_address = p_child_address
         AND s.parent_id = p_id )
       WHERE m.statement_id = p_statement_id
         AND m.source = p_source
         AND m.plan_hash_value = p_plan_hash_value
         AND m.plan_id = p_plan_id
         AND m.inst_id = p_inst_id
         AND m.child_number = p_child_number
         AND m.child_address = p_child_address
         AND m.id = p_id
         AND m.cost IS NULL;
    END fill_blanks;

    /* -------------------------
     *
     * recursive top_cost.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_source          IN VARCHAR2,
      p_plan_hash_value IN NUMBER,
      p_plan_id         IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT id,
                       cost value
                  FROM sqlt$_plan_extension
                 WHERE statement_id = p_statement_id
                   AND source = p_source
                   AND plan_hash_value = p_plan_hash_value
                   AND plan_id = p_plan_id
                   AND inst_id = p_inst_id
                   AND child_number = p_child_number
                   AND child_address = p_child_address
                   AND parent_id = p_id)
      LOOP
        assign_top_value (
          p_source          => p_source,
          p_plan_hash_value => p_plan_hash_value,
          p_plan_id         => p_plan_id,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_cost');

    FOR i IN (SELECT source,
                     plan_hash_value,
                     plan_id,
                     inst_id,
                     child_number,
                     child_address,
                     id,
                     cost value
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND parent_id IS NULL)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      fill_blanks (
        p_source          => i.source,
        p_plan_hash_value => i.plan_hash_value,
        p_plan_id         => i.plan_id,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id);

      assign_top_value (
        p_source          => i.source,
        p_plan_hash_value => i.plan_hash_value,
        p_plan_id         => i.plan_id,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_plan_extension
         SET top_cost = l_top_value
       WHERE statement_id = p_statement_id
         AND source = i.source
         AND plan_hash_value = i.plan_hash_value
         AND plan_id = i.plan_id
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND id = l_top_id;
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_cost: '||SQLERRM);
  END top_cost;

  /*************************************************************************************/

  /* -------------------------
   *
   * private top_last_cr_buffer_gets
   *
   * ------------------------- */
  PROCEDURE top_last_cr_buffer_gets (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_last_cr_buffer_gets.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_plan_hash_value IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT x.id,
                       s.last_cr_buffer_gets value
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan_statistics s
                 WHERE x.statement_id = p_statement_id
                   AND x.source = 'GV$SQL_PLAN'
                   AND x.plan_hash_value = p_plan_hash_value
                   AND x.parent_id = p_id
                   AND x.statement_id = s.statement_id
                   AND x.plan_hash_value = s.plan_hash_value
                   AND x.id = s.operation_id
                   AND s.inst_id = p_inst_id
                   AND s.child_number = p_child_number
                   AND s.child_address = p_child_address)
      LOOP
        assign_top_value (
          p_plan_hash_value => p_plan_hash_value,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_last_cr_buffer_gets');

    FOR i IN (SELECT x.plan_hash_value,
                     s.inst_id,
                     s.child_number,
                     s.child_address,
                     x.id,
                     s.last_cr_buffer_gets value
                FROM sqlt$_plan_extension x,
                     sqlt$_gv$sql_plan_statistics s
               WHERE x.statement_id = p_statement_id
                 AND x.source = 'GV$SQL_PLAN'
                 AND x.id = 1 -- there is no id = 0
                 AND x.statement_id = s.statement_id
                 AND x.plan_hash_value = s.plan_hash_value
                 AND x.id = s.operation_id)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      assign_top_value (
        p_plan_hash_value => i.plan_hash_value,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_gv$sql_plan_statistics
         SET top_last_cr_buffer_gets = l_top_value
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND operation_id = l_top_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_last_cr_buffer_gets: '||SQLERRM);
  END top_last_cr_buffer_gets;

  /*************************************************************************************/

  /* -------------------------
   *
   * private top_cr_buffer_gets
   *
   * ------------------------- */
  PROCEDURE top_cr_buffer_gets (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_cr_buffer_gets.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_plan_hash_value IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT x.id,
                       s.cr_buffer_gets value
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan_statistics s
                 WHERE x.statement_id = p_statement_id
                   AND x.source = 'GV$SQL_PLAN'
                   AND x.plan_hash_value = p_plan_hash_value
                   AND x.parent_id = p_id
                   AND x.statement_id = s.statement_id
                   AND x.plan_hash_value = s.plan_hash_value
                   AND x.id = s.operation_id
                   AND s.inst_id = p_inst_id
                   AND s.child_number = p_child_number
                   AND s.child_address = p_child_address)
      LOOP
        assign_top_value (
          p_plan_hash_value => p_plan_hash_value,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_cr_buffer_gets');

    FOR i IN (SELECT x.plan_hash_value,
                     s.inst_id,
                     s.child_number,
                     s.child_address,
                     x.id,
                     s.cr_buffer_gets value
                FROM sqlt$_plan_extension x,
                     sqlt$_gv$sql_plan_statistics s
               WHERE x.statement_id = p_statement_id
                 AND x.source = 'GV$SQL_PLAN'
                 AND x.id = 1 -- there is no id = 0
                 AND x.statement_id = s.statement_id
                 AND x.plan_hash_value = s.plan_hash_value
                 AND x.id = s.operation_id)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      assign_top_value (
        p_plan_hash_value => i.plan_hash_value,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_gv$sql_plan_statistics
         SET top_cr_buffer_gets = l_top_value
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND operation_id = l_top_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_cr_buffer_gets: '||SQLERRM);
  END top_cr_buffer_gets;

  /*************************************************************************************/

  /* -------------------------
   *
   * private top_last_cu_buffer_gets
   *
   * ------------------------- */
  PROCEDURE top_last_cu_buffer_gets (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_last_cu_buffer_gets.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_plan_hash_value IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT x.id,
                       s.last_cu_buffer_gets value
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan_statistics s
                 WHERE x.statement_id = p_statement_id
                   AND x.source = 'GV$SQL_PLAN'
                   AND x.plan_hash_value = p_plan_hash_value
                   AND x.parent_id = p_id
                   AND x.statement_id = s.statement_id
                   AND x.plan_hash_value = s.plan_hash_value
                   AND x.id = s.operation_id
                   AND s.inst_id = p_inst_id
                   AND s.child_number = p_child_number
                   AND s.child_address = p_child_address)
      LOOP
        assign_top_value (
          p_plan_hash_value => p_plan_hash_value,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_last_cu_buffer_gets');

    FOR i IN (SELECT x.plan_hash_value,
                     s.inst_id,
                     s.child_number,
                     s.child_address,
                     x.id,
                     s.last_cu_buffer_gets value
                FROM sqlt$_plan_extension x,
                     sqlt$_gv$sql_plan_statistics s
               WHERE x.statement_id = p_statement_id
                 AND x.source = 'GV$SQL_PLAN'
                 AND x.id = 1 -- there is no id = 0
                 AND x.statement_id = s.statement_id
                 AND x.plan_hash_value = s.plan_hash_value
                 AND x.id = s.operation_id)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      assign_top_value (
        p_plan_hash_value => i.plan_hash_value,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_gv$sql_plan_statistics
         SET top_last_cu_buffer_gets = l_top_value
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND operation_id = l_top_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_last_cu_buffer_gets: '||SQLERRM);
  END top_last_cu_buffer_gets;

  /*************************************************************************************/

  /* -------------------------
   *
   * private top_cu_buffer_gets
   *
   * ------------------------- */
  PROCEDURE top_cu_buffer_gets (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_cu_buffer_gets.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_plan_hash_value IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT x.id,
                       s.cu_buffer_gets value
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan_statistics s
                 WHERE x.statement_id = p_statement_id
                   AND x.source = 'GV$SQL_PLAN'
                   AND x.plan_hash_value = p_plan_hash_value
                   AND x.parent_id = p_id
                   AND x.statement_id = s.statement_id
                   AND x.plan_hash_value = s.plan_hash_value
                   AND x.id = s.operation_id
                   AND s.inst_id = p_inst_id
                   AND s.child_number = p_child_number
                   AND s.child_address = p_child_address)
      LOOP
        assign_top_value (
          p_plan_hash_value => p_plan_hash_value,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_cu_buffer_gets');

    FOR i IN (SELECT x.plan_hash_value,
                     s.inst_id,
                     s.child_number,
                     s.child_address,
                     x.id,
                     s.cu_buffer_gets value
                FROM sqlt$_plan_extension x,
                     sqlt$_gv$sql_plan_statistics s
               WHERE x.statement_id = p_statement_id
                 AND x.source = 'GV$SQL_PLAN'
                 AND x.id = 1 -- there is no id = 0
                 AND x.statement_id = s.statement_id
                 AND x.plan_hash_value = s.plan_hash_value
                 AND x.id = s.operation_id)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      assign_top_value (
        p_plan_hash_value => i.plan_hash_value,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_gv$sql_plan_statistics
         SET top_cu_buffer_gets = l_top_value
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND operation_id = l_top_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_cu_buffer_gets: '||SQLERRM);
  END top_cu_buffer_gets;

  /*************************************************************************************/

  /* -------------------------
   *
   * private top_last_disk_reads
   *
   * ------------------------- */
  PROCEDURE top_last_disk_reads (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_last_disk_reads.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_plan_hash_value IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT x.id,
                       s.last_disk_reads value
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan_statistics s
                 WHERE x.statement_id = p_statement_id
                   AND x.source = 'GV$SQL_PLAN'
                   AND x.plan_hash_value = p_plan_hash_value
                   AND x.parent_id = p_id
                   AND x.statement_id = s.statement_id
                   AND x.plan_hash_value = s.plan_hash_value
                   AND x.id = s.operation_id
                   AND s.inst_id = p_inst_id
                   AND s.child_number = p_child_number
                   AND s.child_address = p_child_address)
      LOOP
        assign_top_value (
          p_plan_hash_value => p_plan_hash_value,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_last_disk_reads');

    FOR i IN (SELECT x.plan_hash_value,
                     s.inst_id,
                     s.child_number,
                     s.child_address,
                     x.id,
                     s.last_disk_reads value
                FROM sqlt$_plan_extension x,
                     sqlt$_gv$sql_plan_statistics s
               WHERE x.statement_id = p_statement_id
                 AND x.source = 'GV$SQL_PLAN'
                 AND x.id = 1 -- there is no id = 0
                 AND x.statement_id = s.statement_id
                 AND x.plan_hash_value = s.plan_hash_value
                 AND x.id = s.operation_id)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      assign_top_value (
        p_plan_hash_value => i.plan_hash_value,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_gv$sql_plan_statistics
         SET top_last_disk_reads = l_top_value
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND operation_id = l_top_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_last_disk_reads: '||SQLERRM);
  END top_last_disk_reads;

  /*************************************************************************************/

  /* -------------------------
   *
   * private top_disk_reads
   *
   * ------------------------- */
  PROCEDURE top_disk_reads (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_disk_reads.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_plan_hash_value IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT x.id,
                       s.disk_reads value
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan_statistics s
                 WHERE x.statement_id = p_statement_id
                   AND x.source = 'GV$SQL_PLAN'
                   AND x.plan_hash_value = p_plan_hash_value
                   AND x.parent_id = p_id
                   AND x.statement_id = s.statement_id
                   AND x.plan_hash_value = s.plan_hash_value
                   AND x.id = s.operation_id
                   AND s.inst_id = p_inst_id
                   AND s.child_number = p_child_number
                   AND s.child_address = p_child_address)
      LOOP
        assign_top_value (
          p_plan_hash_value => p_plan_hash_value,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_disk_reads');

    FOR i IN (SELECT x.plan_hash_value,
                     s.inst_id,
                     s.child_number,
                     s.child_address,
                     x.id,
                     s.disk_reads value
                FROM sqlt$_plan_extension x,
                     sqlt$_gv$sql_plan_statistics s
               WHERE x.statement_id = p_statement_id
                 AND x.source = 'GV$SQL_PLAN'
                 AND x.id = 1 -- there is no id = 0
                 AND x.statement_id = s.statement_id
                 AND x.plan_hash_value = s.plan_hash_value
                 AND x.id = s.operation_id)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      assign_top_value (
        p_plan_hash_value => i.plan_hash_value,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_gv$sql_plan_statistics
         SET top_disk_reads = l_top_value
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND operation_id = l_top_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_disk_reads: '||SQLERRM);
  END top_disk_reads;

  /*************************************************************************************/

  /* -------------------------
   *
   * private top_last_disk_writes
   *
   * ------------------------- */
  PROCEDURE top_last_disk_writes (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_last_disk_writes.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_plan_hash_value IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT x.id,
                       s.last_disk_writes value
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan_statistics s
                 WHERE x.statement_id = p_statement_id
                   AND x.source = 'GV$SQL_PLAN'
                   AND x.plan_hash_value = p_plan_hash_value
                   AND x.parent_id = p_id
                   AND x.statement_id = s.statement_id
                   AND x.plan_hash_value = s.plan_hash_value
                   AND x.id = s.operation_id
                   AND s.inst_id = p_inst_id
                   AND s.child_number = p_child_number
                   AND s.child_address = p_child_address)
      LOOP
        assign_top_value (
          p_plan_hash_value => p_plan_hash_value,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_last_disk_writes');

    FOR i IN (SELECT x.plan_hash_value,
                     s.inst_id,
                     s.child_number,
                     s.child_address,
                     x.id,
                     s.last_disk_writes value
                FROM sqlt$_plan_extension x,
                     sqlt$_gv$sql_plan_statistics s
               WHERE x.statement_id = p_statement_id
                 AND x.source = 'GV$SQL_PLAN'
                 AND x.id = 1 -- there is no id = 0
                 AND x.statement_id = s.statement_id
                 AND x.plan_hash_value = s.plan_hash_value
                 AND x.id = s.operation_id)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      assign_top_value (
        p_plan_hash_value => i.plan_hash_value,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_gv$sql_plan_statistics
         SET top_last_disk_writes = l_top_value
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND operation_id = l_top_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_last_disk_writes: '||SQLERRM);
  END top_last_disk_writes;

  /*************************************************************************************/

  /* -------------------------
   *
   * private top_disk_writes
   *
   * ------------------------- */
  PROCEDURE top_disk_writes (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_disk_writes.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_plan_hash_value IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT x.id,
                       s.disk_writes value
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan_statistics s
                 WHERE x.statement_id = p_statement_id
                   AND x.source = 'GV$SQL_PLAN'
                   AND x.plan_hash_value = p_plan_hash_value
                   AND x.parent_id = p_id
                   AND x.statement_id = s.statement_id
                   AND x.plan_hash_value = s.plan_hash_value
                   AND x.id = s.operation_id
                   AND s.inst_id = p_inst_id
                   AND s.child_number = p_child_number
                   AND s.child_address = p_child_address)
      LOOP
        assign_top_value (
          p_plan_hash_value => p_plan_hash_value,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_disk_writes');

    FOR i IN (SELECT x.plan_hash_value,
                     s.inst_id,
                     s.child_number,
                     s.child_address,
                     x.id,
                     s.disk_writes value
                FROM sqlt$_plan_extension x,
                     sqlt$_gv$sql_plan_statistics s
               WHERE x.statement_id = p_statement_id
                 AND x.source = 'GV$SQL_PLAN'
                 AND x.id = 1 -- there is no id = 0
                 AND x.statement_id = s.statement_id
                 AND x.plan_hash_value = s.plan_hash_value
                 AND x.id = s.operation_id)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      assign_top_value (
        p_plan_hash_value => i.plan_hash_value,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_gv$sql_plan_statistics
         SET top_disk_writes = l_top_value
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND operation_id = l_top_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_disk_writes: '||SQLERRM);
  END top_disk_writes;

  /*************************************************************************************/

  /* -------------------------
   *
   * private top_last_elapsed_time
   *
   * ------------------------- */
  PROCEDURE top_last_elapsed_time (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_last_elapsed_time.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_plan_hash_value IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT x.id,
                       s.last_elapsed_time value
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan_statistics s
                 WHERE x.statement_id = p_statement_id
                   AND x.source = 'GV$SQL_PLAN'
                   AND x.plan_hash_value = p_plan_hash_value
                   AND x.parent_id = p_id
                   AND x.statement_id = s.statement_id
                   AND x.plan_hash_value = s.plan_hash_value
                   AND x.id = s.operation_id
                   AND s.inst_id = p_inst_id
                   AND s.child_number = p_child_number
                   AND s.child_address = p_child_address)
      LOOP
        assign_top_value (
          p_plan_hash_value => p_plan_hash_value,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_last_elapsed_time');

    FOR i IN (SELECT x.plan_hash_value,
                     s.inst_id,
                     s.child_number,
                     s.child_address,
                     x.id,
                     s.last_elapsed_time value
                FROM sqlt$_plan_extension x,
                     sqlt$_gv$sql_plan_statistics s
               WHERE x.statement_id = p_statement_id
                 AND x.source = 'GV$SQL_PLAN'
                 AND x.id = 1 -- there is no id = 0
                 AND x.statement_id = s.statement_id
                 AND x.plan_hash_value = s.plan_hash_value
                 AND x.id = s.operation_id)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      assign_top_value (
        p_plan_hash_value => i.plan_hash_value,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_gv$sql_plan_statistics
         SET top_last_elapsed_time = l_top_value
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND operation_id = l_top_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_last_elapsed_time: '||SQLERRM);
  END top_last_elapsed_time;

  /*************************************************************************************/

  /* -------------------------
   *
   * private top_elapsed_time
   *
   * ------------------------- */
  PROCEDURE top_elapsed_time (p_statement_id IN NUMBER)
  IS
    l_top_value NUMBER;
    l_top_id    NUMBER;

    /* -------------------------
     *
     * recursive top_elapsed_time.assign_top_value
     *
     * ------------------------- */
    PROCEDURE assign_top_value (
      p_plan_hash_value IN NUMBER,
      p_inst_id         IN NUMBER,
      p_child_number    IN NUMBER,
      p_child_address   IN VARCHAR2,
      p_id              IN NUMBER,
      p_value           IN NUMBER )
    IS
      l_value NUMBER := p_value;
    BEGIN
      FOR j IN (SELECT x.id,
                       s.elapsed_time value
                  FROM sqlt$_plan_extension x,
                       sqlt$_gv$sql_plan_statistics s
                 WHERE x.statement_id = p_statement_id
                   AND x.source = 'GV$SQL_PLAN'
                   AND x.plan_hash_value = p_plan_hash_value
                   AND x.parent_id = p_id
                   AND x.statement_id = s.statement_id
                   AND x.plan_hash_value = s.plan_hash_value
                   AND x.id = s.operation_id
                   AND s.inst_id = p_inst_id
                   AND s.child_number = p_child_number
                   AND s.child_address = p_child_address)
      LOOP
        assign_top_value (
          p_plan_hash_value => p_plan_hash_value,
          p_inst_id         => p_inst_id,
          p_child_number    => p_child_number,
          p_child_address   => p_child_address,
          p_id              => j.id,
          p_value           => NVL(j.value, 0));

        l_value := l_value - NVL(j.value, 0);
      END LOOP;

      IF l_value > l_top_value THEN
        l_top_value := l_value;
        l_top_id := p_id;
      END IF;
    END assign_top_value;

  BEGIN
    write_log('top_elapsed_time');

    FOR i IN (SELECT x.plan_hash_value,
                     s.inst_id,
                     s.child_number,
                     s.child_address,
                     x.id,
                     s.elapsed_time value
                FROM sqlt$_plan_extension x,
                     sqlt$_gv$sql_plan_statistics s
               WHERE x.statement_id = p_statement_id
                 AND x.source = 'GV$SQL_PLAN'
                 AND x.id = 1 -- there is no id = 0
                 AND x.statement_id = s.statement_id
                 AND x.plan_hash_value = s.plan_hash_value
                 AND x.id = s.operation_id)
    LOOP
      l_top_value := 0;
      l_top_id := NULL;

      assign_top_value (
        p_plan_hash_value => i.plan_hash_value,
        p_inst_id         => i.inst_id,
        p_child_number    => i.child_number,
        p_child_address   => i.child_address,
        p_id              => i.id,
        p_value           => NVL(i.value, 0));

      UPDATE sqlt$_gv$sql_plan_statistics
         SET top_elapsed_time = l_top_value
       WHERE statement_id = p_statement_id
         AND plan_hash_value = i.plan_hash_value
         AND inst_id = i.inst_id
         AND child_number = i.child_number
         AND child_address = i.child_address
         AND operation_id = l_top_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('top_elapsed_time: '||SQLERRM);
  END top_elapsed_time;

  /*************************************************************************************/

  /* -------------------------
   *
   * public build_plan_more_html_table
   *
   * called by sqlt$t.perm_transformation
   *
   * ------------------------- */
  PROCEDURE build_plan_more_html_table (p_statement_id IN NUMBER)

  IS
    l_count NUMBER := 0;
    l_more_html_table CLOB;
    l_max_line_size NUMBER := 80;
    l_part_keys VARCHAR2(1000);

    PROCEDURE wa(p_text IN VARCHAR2)
    IS
    BEGIN
      IF p_text IS NOT NULL THEN
        SYS.DBMS_LOB.WRITEAPPEND (
          lob_loc => l_more_html_table,
          amount  => LENGTH(p_text),
          buffer  => p_text );
      END IF;
    END wa;

  BEGIN
    write_log('build_plan_more_html_table');

    FOR i IN (SELECT x.*, ROWID row_id
                FROM sqlt$_plan_extension x
               WHERE x.statement_id = p_statement_id
                 AND (x.search_columns > 0
                  OR  x.other_tag IS NOT NULL
                  OR  x.partition_start IS NOT NULL
                  OR  x.partition_stop IS NOT NULL
                  OR  x.partition_id > 0
                  OR  x.other IS NOT NULL
                  OR  x.distribution IS NOT NULL
                  OR  x.temp_space > 0
                  OR  x.access_predicates IS NOT NULL
                  OR  x.filter_predicates IS NOT NULL
                  OR  x.projection IS NOT NULL
                  OR  x.remarks IS NOT NULL))
    LOOP
      l_count := l_count + 1;
      l_more_html_table := '<table>'||LF;

      IF i.search_columns > 0 THEN
        wa(
        '<tr><th>Search Columns: '||i.search_columns||'/'||sqlt$a.get_column_count(p_statement_id, i.object_owner, i.object_name)||'</th></tr>'||LF||
        --'<tr><td class="l">'||sqlt$a.get_index_column_names(p_statement_id, i.object_owner, i.object_name, 'NO', '</td></tr>'||LF||'<tr><td class="l">')||'</td></tr>'||LF);
        '<tr><td class="l">'||sqlt$a.get_index_column_names(p_statement_id, i.object_owner, i.object_name, 'YES', '</td></tr>'||LF||'<tr><td class="l">')||'</td></tr>'||LF);
      END IF;

      IF i.access_predicates IS NOT NULL THEN
        wa(
        '<tr><th>Access Predicates</th></tr>'||LF||
        '<tr><td class="l">'||sqlt$r.wrap_and_sanitize_html_clob(REPLACE(i.access_predicates, '"'), l_max_line_size)||'</td></tr>'||LF);
      END IF;

      IF i.filter_predicates IS NOT NULL THEN
        wa(
        '<tr><th>Filter Predicates</th></tr>'||LF||
        '<tr><td class="l">'||sqlt$r.wrap_and_sanitize_html_clob(REPLACE(i.filter_predicates, '"'), l_max_line_size)||'</td></tr>'||LF);
      END IF;

      IF i.projection IS NOT NULL THEN
        wa(
        '<tr><th>Projection</th></tr>'||LF||
        '<tr><td class="l">'||sqlt$r.wrap_and_sanitize_html_clob(REPLACE(sqlt$a.remove_piece(i.projection, '[', ']'), '"'), l_max_line_size)||'</td></tr>'||LF);
      END IF;

      IF i.other IS NOT NULL THEN
        wa(
        '<tr><th>Other</th></tr>'||LF||
        '<tr><td class="l">'||sqlt$r.wrap_and_sanitize_html_clob(REPLACE(i.other, '"'), l_max_line_size)||'</td></tr>'||LF);
      END IF;

      IF i.remarks IS NOT NULL THEN
        wa(
        '<tr><th>Remarks</th></tr>'||LF||
        '<tr><td class="l">'||sqlt$r.wrap_and_sanitize_html_clob(REPLACE(i.remarks, '"'), l_max_line_size)||'</td></tr>'||LF);
      END IF;

      IF i.partition_id IS NOT NULL OR i.partition_start IS NOT NULL OR i.partition_stop IS NOT NULL THEN

        FOR j IN (SELECT kc.column_name, kc.column_position 
                    FROM sqlt$_dba_part_key_columns kc 
                   WHERE kc.statement_id = i.statement_id
                     AND kc.owner = i.object_owner
                     AND kc.name = i.object_name 
                   ORDER BY kc.column_position) LOOP
           IF j.column_position = 1 THEN
              l_part_keys := j.column_name;
           ELSE
              l_part_keys := l_part_keys||','||j.column_name;
           END IF; 
        END LOOP;
        wa(
        '<tr><th>Partition Key(s)</th></tr>'||LF||
        '<tr><td class="l">'||l_part_keys||'</td></tr>'||LF||
        '<tr><th>Partition ID [Start] [Stop]</th></tr>'||LF||
        '<tr><td class="l">'||i.partition_id||NBSP2||'['||i.partition_start||']'||NBSP2||'['||i.partition_stop||']</td></tr>'||LF);
      END IF;

      IF i.object_name LIKE '%TQ:%' OR i.object_name LIKE '%:TQ%' THEN
        wa(
        '<tr><th>TQ</th></tr>'||LF||
        '<tr><td class="l">'||sqlt$r.wrap_and_sanitize_html_clob(REPLACE(i.object_name, '"'), l_max_line_size)||'</td></tr>'||LF);
      END IF;

      IF i.other_tag IS NOT NULL THEN
        IF i.other_tag LIKE '%PARALLEL%' OR i.other_tag LIKE '%SERIAL%' THEN
          wa(
          '<tr><th>IN-OUT</th></tr>'||LF||
          '<tr><td class="l">'||sqlt$r.wrap_and_sanitize_html_clob(REPLACE(i.other_tag, '"'), l_max_line_size)||'</td></tr>'||LF);
        ELSE
          wa(
          '<tr><th>Other Tag</th></tr>'||LF||
          '<tr><td class="l">'||sqlt$r.wrap_and_sanitize_html_clob(REPLACE(i.other_tag, '"'), l_max_line_size)||'</td></tr>'||LF);
        END IF;
      END IF;

      IF i.distribution IS NOT NULL THEN
        wa(
        '<tr><th>Distribution</th></tr>'||LF||
        '<tr><td class="l">'||sqlt$r.wrap_and_sanitize_html_clob(REPLACE(i.distribution, '"'), l_max_line_size)||'</td></tr>'||LF);
      END IF;

      IF i.temp_space IS NOT NULL THEN
        wa(
        '<tr><th>Temp Space</th></tr>'||LF||
        '<tr><td class="l">'||i.temp_space||'</td></tr>'||LF);
      END IF;

      wa('</table>');

      UPDATE sqlt$_plan_extension
         SET more_html_table = l_more_html_table
       WHERE ROWID = i.row_id;
    END LOOP;

    write_log(l_count||' plan more html tables built');

  EXCEPTION
    WHEN OTHERS THEN
      write_error('build_plan_more_html_table: '||SQLERRM);
  END build_plan_more_html_table;

  /*************************************************************************************/

  /* -------------------------
   *
   * private build_workarea_html_table
   *
   * ------------------------- */
  PROCEDURE build_workarea_html_table (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    l_workarea_html_table CLOB;

    PROCEDURE wa(p_text IN VARCHAR2)
    IS
    BEGIN
      IF p_text IS NOT NULL THEN
        SYS.DBMS_LOB.WRITEAPPEND (
          lob_loc => l_workarea_html_table,
          amount  => LENGTH(p_text),
          buffer  => p_text );
      END IF;
    END wa;

  BEGIN
    write_log('build_workarea_html_table');

    FOR i IN (SELECT w.*, ROWID row_id
                FROM sqlt$_gv$sql_workarea w
               WHERE w.statement_id = p_statement_id)
    LOOP
      l_count := l_count + 1;
      l_workarea_html_table := '<table>'||LF;

      IF i.policy IS NOT NULL THEN
        wa('<tr><td class="rt">Policy:</td><td class="l">'||i.policy||'</td></tr>'||LF);
      END IF;

      IF i.estimated_optimal_size IS NOT NULL THEN
        wa('<tr><td class="rt">Estimated Optimal Size:</td><td class="l">'||i.estimated_optimal_size||'</td></tr>'||LF);
      END IF;

      IF i.estimated_onepass_size IS NOT NULL THEN
        wa('<tr><td class="rt">Estimated One-Pass Size:</td><td class="l">'||i.estimated_onepass_size||'</td></tr>'||LF);
      END IF;

      IF i.last_memory_used IS NOT NULL THEN
        wa('<tr><td class="rt">Last Memory Used:</td><td class="l">'||i.last_memory_used||'</td></tr>'||LF);
      END IF;

      IF i.last_execution IS NOT NULL THEN
        wa('<tr><td class="rt">Last Execution:</td><td class="l">'||i.last_execution||'</td></tr>'||LF);
      END IF;

      IF i.last_degree IS NOT NULL THEN
        wa('<tr><td class="rt">Last Degree:</td><td class="l">'||i.last_degree||'</td></tr>'||LF);
      END IF;

      IF i.total_executions IS NOT NULL THEN
        wa('<tr><td class="rt">Total Executions:</td><td class="l">'||i.total_executions||'</td></tr>'||LF);
      END IF;

      IF i.optimal_executions IS NOT NULL THEN
        wa('<tr><td class="rt">Optimal Executions:</td><td class="l">'||i.optimal_executions||'</td></tr>'||LF);
      END IF;

      IF i.onepass_executions IS NOT NULL THEN
        wa('<tr><td class="rt">One-Pass Executions:</td><td class="l">'||i.onepass_executions||'</td></tr>'||LF);
      END IF;

      IF i.multipasses_executions IS NOT NULL THEN
        wa('<tr><td class="rt">Multi-Passes Executions:</td><td class="l">'||i.multipasses_executions||'</td></tr>'||LF);
      END IF;

      IF i.active_time IS NOT NULL THEN
        wa('<tr><td class="rt">Active Time in secs:</td><td class="l">'||TO_CHAR(ROUND(i.active_time / 1e6, 3), SECONDS_FORMAT)||'</td></tr>'||LF);
      END IF;

      IF i.max_tempseg_size IS NOT NULL THEN
        wa('<tr><td class="rt">Max Temp Segment Size:</td><td class="l">'||i.max_tempseg_size||'</td></tr>'||LF);
      END IF;

      IF i.last_tempseg_size IS NOT NULL THEN
        wa('<tr><td class="rt">Last Temp Segment Size:</td><td class="l">'||i.last_tempseg_size||'</td></tr>'||LF);
      END IF;

      wa('</table>');

      UPDATE sqlt$_gv$sql_workarea
         SET workarea_html_table = l_workarea_html_table
       WHERE ROWID = i.row_id;
    END LOOP;

    write_log(l_count||' work area html tables built');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('build_workarea_html_table: '||SQLERRM);
  END build_workarea_html_table;

  /*************************************************************************************/

  /* -------------------------
   *
   * private build_plan_goto_html_table
   *
   * ------------------------- */
  PROCEDURE build_plan_goto_html_table (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    l_object_id NUMBER;
    l_goto_html_table CLOB;
    l_table_name VARCHAR2(32767);
    l_table_owner VARCHAR2(32767);

    PROCEDURE wa(p_text IN VARCHAR2)
    IS
    BEGIN
      IF p_text IS NOT NULL THEN
        SYS.DBMS_LOB.WRITEAPPEND (
          lob_loc => l_goto_html_table,
          amount  => LENGTH(p_text),
          buffer  => p_text );
      END IF;
    END wa;

  BEGIN
    write_log('build_workarea_html_table');

    FOR i IN (SELECT ROWID row_id,
                     object_owner,
                     object_name,
                     CASE
                     WHEN object_type LIKE '%TABLE%' OR object_type LIKE '%MAT%VIEW%' THEN 'TABLE'
                     WHEN object_type LIKE '%INDEX%' THEN 'INDEX'
                     END obj_type
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND (object_type LIKE '%TABLE%' OR object_type LIKE '%MAT%VIEW%' OR object_type LIKE '%INDEX%'))
    LOOP
      l_count := l_count + 1;
      l_goto_html_table := '<table>';
      l_object_id := sqlt$a.get_object_id(p_statement_id, i.obj_type, i.object_owner, i.object_name);
      wa(obj_cols_sec(p_statement_id, i.object_name, i.object_owner, l_object_id, i.obj_type));

      IF i.obj_type = 'INDEX' THEN
        sqlt$a.get_table(p_statement_id, i.object_owner, i.object_name, l_table_owner, l_table_name, l_object_id);
        wa(obj_cols_sec(p_statement_id, l_table_name, l_table_owner, l_object_id, 'TABLE'));
      END IF;


      wa('</table>');
      UPDATE sqlt$_plan_extension
         SET goto_html_table = l_goto_html_table
       WHERE ROWID = i.row_id;
    END LOOP;

    write_log(l_count||' go to html tables built');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('build_plan_goto_html_table: '||SQLERRM);
  END build_plan_goto_html_table;

  /*************************************************************************************/

  /* -------------------------
   *
   * public sanitize_reason
   *
   * called by sqlt$t.perm_transformation
   *
   * ------------------------- */
  PROCEDURE sanitize_reason (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    l_sanitize_reason CLOB;

    /* -------------------------
     *
     * private sanitize_reason.sanitize_reason
     *
     * ------------------------- */
    FUNCTION sanitize_reason (p_reason IN CLOB)
    RETURN CLOB
    IS
      l_reason CLOB := p_reason;
    BEGIN
      l_reason := REPLACE(l_reason, '</', '~^');
      l_reason := REPLACE(l_reason, '<', LF||'    <');
      l_reason := REPLACE(l_reason, '~^', '</');
      l_reason := REPLACE(l_reason, '</ChildNode>', LF||'  </ChildNode>');
      l_reason := REPLACE(l_reason, '    <ChildNode>', '  <ChildNode>');
      l_reason := TRIM(LF FROM l_reason);
      l_reason := sqlt$r.wrap_clob(l_reason, 1900);
      l_reason := REPLACE(l_reason, '>', GT);
      l_reason := REPLACE(l_reason, '<', LT);
      l_reason := '<pre>'||l_reason||'</pre>';

      RETURN l_reason;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('sanitize_reason: '||SQLERRM);
        RETURN p_reason;
    END sanitize_reason;

  BEGIN
    write_log('sanitize_reason');

    -- sqlt$_gv$sql_shared_cursor
    FOR i IN (SELECT reason, ROWID row_id
                FROM sqlt$_gv$sql_shared_cursor
               WHERE statement_id = p_statement_id
                 AND LENGTH(reason) > 1)
    LOOP
      l_count := l_count + 1;
      l_sanitize_reason := sanitize_reason(i.reason);
      UPDATE sqlt$_gv$sql_shared_cursor
         SET sanitized_reason = l_sanitize_reason
       WHERE ROWID = i.row_id;
    END LOOP;

    write_log(l_count||' reason columns have been sanitized');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sanitize_reason: '||SQLERRM);
  END sanitize_reason;

  /* -------------------------
   *
   * public sanitize_dir_notes
   * 
   * called by sqlt$t.perm_transformation
   * 150828 obsolete. notes column replaced by decoded columns on view
   * ------------------------- *
  PROCEDURE sanitize_dir_notes (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    l_sanitized_notes CLOB;

     * -------------------------
     *
     * private sanitize_dir_notes.sanitize_dir_notes
     *
     * ------------------------- *
    FUNCTION sanitize_dir_notes (p_note IN CLOB)
    RETURN CLOB
    IS

      l_note CLOB := p_note;
    BEGIN

      l_note := REPLACE(l_note, '</obj', '~/obj');
      l_note := REPLACE(l_note, '><', '>'||LF||'   <');
      l_note := REPLACE(l_note, '~/obj', LF||'</obj');      
      l_note := REPLACE(l_note, '>', GT);
      l_note := REPLACE(l_note, '<', LT);
      l_note := '<pre>'||l_note||'</pre>';

      RETURN l_note;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('sanitize_dir_notes: '||SQLERRM);
        RETURN p_note;
    END sanitize_dir_notes;

  BEGIN
    write_log('sanitize_dir_notes');

    FOR i IN (SELECT TO_CLOB(notes) notes, ROWID row_id
                FROM sqlt$_dba_sql_plan_dir_objs
               WHERE statement_id = p_statement_id
                 AND notes IS NOT NULL)
    LOOP
      l_count := l_count + 1;
      l_sanitized_notes := sanitize_dir_notes(i.notes);
      UPDATE sqlt$_dba_sql_plan_dir_objs
         SET sanitized_notes = l_sanitized_notes
       WHERE ROWID = i.row_id;
    END LOOP;

    write_log(l_count||' directives notes columns have been sanitized');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sanitize_dir_notes: '||SQLERRM);
  END sanitize_dir_notes;
  */

  /*************************************************************************************/

  /* -------------------------
   *
   * public sanitize_other_xml
   *
   * called by sqlt$t.perm_transformation
   *
   * ------------------------- */
  PROCEDURE sanitize_other_xml (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    l_sanitize_other_xml CLOB;

    /* -------------------------
     *
     * private sanitize_other_xml.sanitize_other_xml
     *
     * ------------------------- */
    FUNCTION sanitize_other_xml (p_other_xml IN CLOB)
    RETURN CLOB
    IS
      l_other_xml CLOB := p_other_xml;
    BEGIN
      l_other_xml := REPLACE(l_other_xml, '><![CDATA[', '><');
      l_other_xml := REPLACE(l_other_xml, ']]><', '><');
      l_other_xml := REPLACE(l_other_xml, '<hint',  LF||'    <hint');
      l_other_xml := REPLACE(l_other_xml, '<bind',  LF||'    <bind');
      l_other_xml := REPLACE(l_other_xml, '<stat ',  LF||'    <stat ');
      l_other_xml := REPLACE(l_other_xml, '<info',  LF||'  <info');
      l_other_xml := REPLACE(l_other_xml, '<outline',  LF||'  <outline');
      l_other_xml := REPLACE(l_other_xml, '</outline',  LF||'  </outline');
      l_other_xml := REPLACE(l_other_xml, '<peeked_binds',  LF||'  <peeked_binds');
      l_other_xml := REPLACE(l_other_xml, '</peeked_binds',  LF||'  </peeked_binds');
      l_other_xml := REPLACE(l_other_xml, '<stats',  LF||'  <stats');
      l_other_xml := REPLACE(l_other_xml, '</stats',  LF||'  </stats');
      l_other_xml := REPLACE(l_other_xml, '</other_xml',  LF||'</other_xml');
      --l_other_xml := sqlt$r.wrap_clob(l_other_xml, 240);
      l_other_xml := sqlt$r.wrap_clob(l_other_xml, 1900);
      l_other_xml := REPLACE(l_other_xml, '>', GT);
      l_other_xml := REPLACE(l_other_xml, '<', LT);

      RETURN l_other_xml;
    EXCEPTION
      WHEN OTHERS THEN
        write_error('sanitize_other_xml: '||SQLERRM);
        RETURN p_other_xml;
    END sanitize_other_xml;

  BEGIN
    write_log('sanitize_other_xml');

    -- sqlt$_plan_extension
    FOR i IN (SELECT x.other_xml, ROWID row_id
                FROM sqlt$_plan_extension x
               WHERE statement_id = p_statement_id
                 AND other_xml IS NOT NULL)
    LOOP
      l_count := l_count + 1;
      l_sanitize_other_xml := sanitize_other_xml(i.other_xml);
      UPDATE sqlt$_plan_extension
         SET sanitized_other_xml = l_sanitize_other_xml
       WHERE ROWID = i.row_id;
    END LOOP;

    -- sqlt$_gv$sql_plan
    FOR i IN (SELECT x.other_xml, ROWID row_id
                FROM sqlt$_gv$sql_plan x
               WHERE statement_id = p_statement_id
                 AND other_xml IS NOT NULL)
    LOOP
      l_count := l_count + 1;
      l_sanitize_other_xml := sanitize_other_xml(i.other_xml);
      UPDATE sqlt$_gv$sql_plan
         SET sanitized_other_xml = l_sanitize_other_xml
       WHERE ROWID = i.row_id;
    END LOOP;

    write_log(l_count||' other_xml columns have been sanitized');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('sanitize_other_xml: '||SQLERRM);
  END sanitize_other_xml;

  /*************************************************************************************/

  /* -------------------------
   *
   * public process_other_xml
   *
   * called by sqlt$t.perm_transformation
   *
   * ------------------------- */
  PROCEDURE process_other_xml (p_statement_id IN NUMBER)
  IS
    l_count_bind  NUMBER := 0;
    l_count_info  NUMBER := 0;
    l_count_hint  NUMBER := 0;
    l_count_dis_m NUMBER := 0;
    bin_rec sqlt$_peeked_binds%ROWTYPE;
    pln_rec sqlt$_plan_info%ROWTYPE;
    out_rec sqlt$_outline_data%ROWTYPE;
    sql_rec sqlt$_sql_statement%ROWTYPE;
    dim_rec sqlt$_display_map%ROWTYPE;  -- Display Map (12c Adaptive Plans)

    /* -------------------------
     *
     * private process_other_xml.parse_other_xml
     *
     * ------------------------- */
    PROCEDURE parse_other_xml (p_other_xml CLOB)
    IS
    BEGIN
      -- peeked binds
      FOR j IN (SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
                       EXTRACTVALUE(VALUE(d), '/bind/@nam') nam,
                       EXTRACTVALUE(VALUE(d), '/bind/@pos') pos,
                       EXTRACTVALUE(VALUE(d), '/bind/@ppo') ppo,
                       EXTRACTVALUE(VALUE(d), '/bind/@dty') dty,
                       EXTRACTVALUE(VALUE(d), '/bind/@csi') csi,
                       EXTRACTVALUE(VALUE(d), '/bind/@frm') frm,
                       EXTRACTVALUE(VALUE(d), '/bind/@pre') pre,
                       EXTRACTVALUE(VALUE(d), '/bind/@scl') scl,
                       EXTRACTVALUE(VALUE(d), '/bind/@mxl') mxl,
                       EXTRACTVALUE(VALUE(d), '/bind/@captured') captured,
                       EXTRACTVALUE(VALUE(d), '/bind') value,
                       sqlt$_line_id_s.NEXTVAL line_id
                  FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(p_other_xml), '/*/peeked_binds/bind'))) d)
      LOOP
        l_count_bind := l_count_bind + 1;

        BEGIN
          bin_rec.line_id := j.line_id;
          bin_rec.name := j.nam;
          bin_rec.position := j.pos;
          bin_rec.dup_position := j.ppo;
          bin_rec.datatype := j.dty;
          bin_rec.character_sid := j.csi;
          bin_rec.frm := j.frm;
          bin_rec.precision := j.pre;
          bin_rec.scale := j.scl;
          bin_rec.max_length := j.mxl;
          bin_rec.was_captured := j.captured;
          bin_rec.value_raw := j.value;
        EXCEPTION
          WHEN OTHERS THEN
            write_log('bind: '||SQLERRM);
        END;

        INSERT INTO sqlt$_peeked_binds VALUES bin_rec;
      END LOOP;

      -- plan info
      FOR j IN (SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
                       EXTRACTVALUE(VALUE(d), '/info/@type') info_type,
                       EXTRACTVALUE(VALUE(d), '/info') info_value,
                       sqlt$_line_id_s.NEXTVAL line_id
                  FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(p_other_xml), '/*/info'))) d
                 WHERE EXTRACTVALUE(VALUE(d), '/info/@type') IN (
                       'adaptive_plan',
                       'baseline',
                       'cardinality_feedback',
                       'cbqt_star_transformation',
                       'db_version',
                       'dop',
                       'dop_op_reason',
                       'dop_reason',
                       'dynamic_sampling',
                       'gtt_session_st',
                       'index_size',
                       'outline',
                       'parse_schema',
                       'plan_hash',
                       'px_ext_opns',
                       'queuing_reason',
                       'result_checksum',
                       'row_shipping',
                       'sql_patch',
                       'sql_profile',
                       'xml_suboptimal'
                       ))
      LOOP
        l_count_info := l_count_info + 1;

        BEGIN
          pln_rec.line_id := j.line_id;
          pln_rec.info_type := j.info_type;
          pln_rec.info_value := j.info_value;
        EXCEPTION
          WHEN OTHERS THEN
            write_log('info: '||SQLERRM);
        END;

        INSERT INTO sqlt$_plan_info VALUES pln_rec;
      END LOOP;

      -- hints
      FOR j IN (SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
                       SUBSTR(EXTRACTVALUE(VALUE(d), '/hint'), 1, 4000) hint,
                       sqlt$_line_id_s.NEXTVAL line_id
                  FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(p_other_xml), '/*/outline_data/hint'))) d)
      LOOP
        l_count_hint := l_count_hint + 1;

        BEGIN
          out_rec.line_id := j.line_id;
          out_rec.hint := j.hint;
        EXCEPTION
          WHEN OTHERS THEN
            write_log('hint: '||SQLERRM);
        END;

        INSERT INTO sqlt$_outline_data VALUES out_rec;
      END LOOP;
	  
      -- display_map (12c Adaptive Plans)
      FOR j IN (SELECT /*+ opt_param('parallel_execution_enabled', 'false') */
                       EXTRACTVALUE(VALUE(d), '/row/@op')  operation_id,
                       EXTRACTVALUE(VALUE(d), '/row/@dis') display_id,
                       EXTRACTVALUE(VALUE(d), '/row/@par') parent_id,
                       EXTRACTVALUE(VALUE(d), '/row/@prt') part_id,
                       EXTRACTVALUE(VALUE(d), '/row/@dep') depth,
                       EXTRACTVALUE(VALUE(d), '/row/@skp') skipped,
                       sqlt$_line_id_s.NEXTVAL line_id
                  FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE(p_other_xml), '/*/display_map/row'))) d)
      LOOP
        l_count_dis_m := l_count_dis_m + 1;

        BEGIN
          dim_rec.line_id := j.line_id;
          dim_rec.operation_id := j.operation_id;
          dim_rec.display_id := j.display_id ;
          dim_rec.parent_id := j.parent_id ;
          dim_rec.part_id := j.part_id ;
          dim_rec.depth := j.depth ;
          dim_rec.skipped := j.skipped ;		  
        EXCEPTION
          WHEN OTHERS THEN
            write_log('display map: '||SQLERRM);
        END;

        INSERT INTO sqlt$_display_map VALUES dim_rec;
      END LOOP;

    EXCEPTION
      WHEN OTHERS THEN
        write_log('** '||SQLERRM);
    END parse_other_xml;

  BEGIN
    write_log('process_other_xml');
    sql_rec := sqlt$a.get_statement(p_statement_id);

    FOR i IN (SELECT statid,
                     plan_hash_value,
                     plan_id,
                     inst_id,
                     child_number,
                     child_address,
                     id,
                     timestamp,
                     other_xml
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND other_xml IS NOT NULL)
    LOOP
      bin_rec := NULL;
      bin_rec.statement_id := p_statement_id;
      bin_rec.statid := i.statid;
      bin_rec.source := 'PLAN_EXTENSION';
      bin_rec.plan_hash_value := i.plan_hash_value;
      bin_rec.plan_id := i.plan_id;
      bin_rec.inst_id := i.inst_id;
      bin_rec.child_number := i.child_number;
      bin_rec.child_address := i.child_address;
      bin_rec.plan_timestamp := i.timestamp;
      bin_rec.id := i.id;

      pln_rec := NULL;
      pln_rec.statement_id := p_statement_id;
      pln_rec.statid := i.statid;
      pln_rec.source := 'PLAN_EXTENSION';
      pln_rec.plan_hash_value := i.plan_hash_value;
      pln_rec.plan_id := i.plan_id;
      pln_rec.inst_id := i.inst_id;
      pln_rec.child_number := i.child_number;
      pln_rec.child_address := i.child_address;
      pln_rec.plan_timestamp := i.timestamp;
      pln_rec.id := i.id;

      out_rec := NULL;
      out_rec.statement_id := p_statement_id;
      out_rec.statid := i.statid;
      out_rec.source := 'PLAN_EXTENSION';
      out_rec.plan_hash_value := i.plan_hash_value;
      out_rec.plan_id := i.plan_id;
      out_rec.inst_id := i.inst_id;
      out_rec.child_number := i.child_number;
      out_rec.child_address := i.child_address;
      out_rec.plan_timestamp := i.timestamp;
      out_rec.id := i.id;
	  
      dim_rec := NULL;
      dim_rec.statement_id := p_statement_id;
      dim_rec.statid := i.statid;
      dim_rec.source := 'PLAN_EXTENSION';
      dim_rec.plan_hash_value := i.plan_hash_value;
      dim_rec.plan_id := i.plan_id;
      dim_rec.inst_id := i.inst_id;
      dim_rec.child_number := i.child_number;
      dim_rec.child_address := i.child_address;
      dim_rec.plan_timestamp := i.timestamp;
      dim_rec.id := i.id;	  

      parse_other_xml(i.other_xml);
    END LOOP;

    FOR i IN (SELECT statid,
                     plan_hash_value,
                     inst_id,
                     child_number,
                     child_address,
                     id,
                     timestamp,
                     other_xml
                FROM sqlt$_gv$sql_plan
               WHERE statement_id = p_statement_id
                 AND other_xml IS NOT NULL)
    LOOP
      bin_rec := NULL;
      bin_rec.statement_id := p_statement_id;
      bin_rec.statid := i.statid;
      bin_rec.source := 'GV$SQL_PLAN';
      bin_rec.plan_hash_value := i.plan_hash_value;
      bin_rec.plan_id := -1;
      bin_rec.inst_id := i.inst_id;
      bin_rec.child_number := i.child_number;
      bin_rec.child_address := i.child_address;
      bin_rec.plan_timestamp := i.timestamp;
      bin_rec.id := i.id;

      pln_rec := NULL;
      pln_rec.statement_id := p_statement_id;
      pln_rec.statid := i.statid;
      pln_rec.source := 'GV$SQL_PLAN';
      pln_rec.plan_hash_value := i.plan_hash_value;
      pln_rec.plan_id := -1;
      pln_rec.inst_id := i.inst_id;
      pln_rec.child_number := i.child_number;
      pln_rec.child_address := i.child_address;
      pln_rec.plan_timestamp := i.timestamp;
      pln_rec.id := i.id;

      out_rec := NULL;
      out_rec.statement_id := p_statement_id;
      out_rec.statid := i.statid;
      out_rec.source := 'GV$SQL_PLAN';
      out_rec.plan_hash_value := i.plan_hash_value;
      out_rec.plan_id := -1;
      out_rec.inst_id := i.inst_id;
      out_rec.child_number := i.child_number;
      out_rec.child_address := i.child_address;
      out_rec.plan_timestamp := i.timestamp;
      out_rec.id := i.id;
	  
      dim_rec := NULL;
      dim_rec.statement_id := p_statement_id;
      dim_rec.statid := i.statid;
      dim_rec.source := 'GV$SQL_PLAN';
      dim_rec.plan_hash_value := i.plan_hash_value;
      dim_rec.plan_id := -1;
      dim_rec.inst_id := i.inst_id;
      dim_rec.child_number := i.child_number;
      dim_rec.child_address := i.child_address;
      dim_rec.plan_timestamp := i.timestamp;
      dim_rec.id := i.id;	  

      parse_other_xml(i.other_xml);
    END LOOP;

    FOR i IN (SELECT statid,
                     plan_hash_value,
                     id,
                     timestamp,
                     other_xml
                FROM sqlt$_dba_hist_sql_plan
               WHERE statement_id = p_statement_id
                 AND other_xml IS NOT NULL)
    LOOP
      bin_rec := NULL;
      bin_rec.statement_id := p_statement_id;
      bin_rec.statid := i.statid;
      bin_rec.source := 'DBA_HIST_SQL_PLAN';
      bin_rec.plan_hash_value := i.plan_hash_value;
      bin_rec.plan_id := -1;
      bin_rec.inst_id := -1;
      bin_rec.child_number := -1;
      bin_rec.child_address := '-666';
      bin_rec.plan_timestamp := i.timestamp;
      bin_rec.id := i.id;

      pln_rec := NULL;
      pln_rec.statement_id := p_statement_id;
      pln_rec.statid := i.statid;
      pln_rec.source := 'DBA_HIST_SQL_PLAN';
      pln_rec.plan_hash_value := i.plan_hash_value;
      pln_rec.plan_id := -1;
      pln_rec.inst_id := -1;
      pln_rec.child_number := -1;
      pln_rec.child_address := '-666';
      pln_rec.plan_timestamp := i.timestamp;
      pln_rec.id := i.id;

      out_rec := NULL;
      out_rec.statement_id := p_statement_id;
      out_rec.statid := i.statid;
      out_rec.source := 'DBA_HIST_SQL_PLAN';
      out_rec.plan_hash_value := i.plan_hash_value;
      out_rec.plan_id := -1;
      out_rec.inst_id := -1;
      out_rec.child_number := -1;
      out_rec.child_address := '-666';
      out_rec.plan_timestamp := i.timestamp;
      out_rec.id := i.id;
	  
      dim_rec := NULL;
      dim_rec.statement_id := p_statement_id;
      dim_rec.statid := i.statid;
      dim_rec.source := 'DBA_HIST_SQL_PLAN';
      dim_rec.plan_hash_value := i.plan_hash_value;
      dim_rec.plan_id := -1;
      dim_rec.inst_id := -1;
      dim_rec.child_number := -1;
      dim_rec.child_address := '-666';
      dim_rec.plan_timestamp := i.timestamp;
      dim_rec.id := i.id;	  

      parse_other_xml(i.other_xml);
    END LOOP;

    FOR i IN (SELECT statid,
                     plan_hash_value,
                     plan_id,
                     id,
                     timestamp,
                     other_xml
                FROM sqlt$_dba_sqltune_plans
               WHERE statement_id = p_statement_id
                 AND other_xml IS NOT NULL)
    LOOP
      bin_rec := NULL;
      bin_rec.statement_id := p_statement_id;
      bin_rec.statid := i.statid;
      bin_rec.source := 'DBA_SQLTUNE_PLANS';
      bin_rec.plan_hash_value := i.plan_hash_value;
      bin_rec.plan_id := i.plan_id;
      bin_rec.inst_id := -1;
      bin_rec.child_number := -1;
      bin_rec.child_address := '-666';
      bin_rec.plan_timestamp := i.timestamp;
      bin_rec.id := i.id;

      pln_rec := NULL;
      pln_rec.statement_id := p_statement_id;
      pln_rec.statid := i.statid;
      pln_rec.source := 'DBA_SQLTUNE_PLANS';
      pln_rec.plan_hash_value := i.plan_hash_value;
      pln_rec.plan_id := i.plan_id;
      pln_rec.inst_id := -1;
      pln_rec.child_number := -1;
      pln_rec.child_address := '-666';
      pln_rec.plan_timestamp := i.timestamp;
      pln_rec.id := i.id;

      out_rec := NULL;
      out_rec.statement_id := p_statement_id;
      out_rec.statid := i.statid;
      out_rec.source := 'DBA_SQLTUNE_PLANS';
      out_rec.plan_hash_value := i.plan_hash_value;
      out_rec.plan_id := i.plan_id;
      out_rec.inst_id := -1;
      out_rec.child_number := -1;
      out_rec.child_address := '-666';
      out_rec.plan_timestamp := i.timestamp;
      out_rec.id := i.id;
	  
      dim_rec := NULL;
      dim_rec.statement_id := p_statement_id;
      dim_rec.statid := i.statid;
      dim_rec.source := 'DBA_SQLTUNE_PLANS';
      dim_rec.plan_hash_value := i.plan_hash_value;
      dim_rec.plan_id := i.plan_id;
      dim_rec.inst_id := -1;
      dim_rec.child_number := -1;
      dim_rec.child_address := '-666';
      dim_rec.plan_timestamp := i.timestamp;
      dim_rec.id := i.id;	  

      parse_other_xml(i.other_xml);
    END LOOP;

    FOR i IN (SELECT statid,
                     plan_id,
                     id,
                     timestamp,
                     other_xml
                FROM sqlt$_sql_plan_table
               WHERE statement_id = sqlt$a.get_statement_id_c(p_statement_id)
                 AND other_xml IS NOT NULL)
    LOOP
      bin_rec := NULL;
      bin_rec.statement_id := p_statement_id;
      bin_rec.statid := i.statid;
      bin_rec.source := 'PLAN_TABLE';
      bin_rec.plan_hash_value := sql_rec.xplain_plan_hash_value;
      bin_rec.plan_id := i.plan_id;
      bin_rec.inst_id := -1;
      bin_rec.child_number := -1;
      bin_rec.child_address := '-666';
      bin_rec.plan_timestamp := i.timestamp;
      bin_rec.id := i.id;

      pln_rec := NULL;
      pln_rec.statement_id := p_statement_id;
      pln_rec.statid := i.statid;
      pln_rec.source := 'PLAN_TABLE';
      pln_rec.plan_hash_value := sql_rec.xplain_plan_hash_value;
      pln_rec.plan_id := i.plan_id;
      pln_rec.inst_id := -1;
      pln_rec.child_number := -1;
      pln_rec.child_address := '-666';
      pln_rec.plan_timestamp := i.timestamp;
      pln_rec.id := i.id;

      out_rec := NULL;
      out_rec.statement_id := p_statement_id;
      out_rec.statid := i.statid;
      out_rec.source := 'PLAN_TABLE';
      out_rec.plan_hash_value := sql_rec.xplain_plan_hash_value;
      out_rec.plan_id := i.plan_id;
      out_rec.inst_id := -1;
      out_rec.child_number := -1;
      out_rec.child_address := '-666';
      out_rec.plan_timestamp := i.timestamp;
      out_rec.id := i.id;
	  
      dim_rec := NULL;
      dim_rec.statement_id := p_statement_id;
      dim_rec.statid := i.statid;
      dim_rec.source := 'PLAN_TABLE';
      dim_rec.plan_hash_value := sql_rec.xplain_plan_hash_value;
      dim_rec.plan_id := i.plan_id;
      dim_rec.inst_id := -1;
      dim_rec.child_number := -1;
      dim_rec.child_address := '-666';
      dim_rec.plan_timestamp := i.timestamp;
      dim_rec.id := i.id;	  

      parse_other_xml(i.other_xml);
    END LOOP;

    write_log(l_count_bind||' binds were processed out of other_xml columns');
    write_log(l_count_info||' info rows were processed out of other_xml columns');
    write_log(l_count_hint||' hints were processed out of other_xml columns');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('process_other_xml: '||SQLERRM);
  END process_other_xml;

  /*************************************************************************************/

  /* -------------------------
   *
   * public extend_peeked_binds
   *
   * called by sqlt$t.perm_transformation
   *
   * ------------------------- */
  PROCEDURE extend_peeked_binds (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    l_datatype_string sqlt$_peeked_binds.datatype_string%TYPE;
    l_value_string sqlt$_peeked_binds.value_string%TYPE;
    l_value_string_date sqlt$_peeked_binds.value_string_date%TYPE;

  BEGIN
    write_log('extend_peeked_binds');

    FOR i IN (SELECT datatype,
                     CASE
                     WHEN datatype = '96' THEN 'CHAR'
                     WHEN datatype = '1' THEN 'VARCHAR2'
                     WHEN datatype = '12' THEN 'DATE'
                     WHEN datatype = '180' THEN 'TIMESTAMP'
                     WHEN datatype = '181' THEN 'TIMESTAMP WITH TIME ZONE'
                     WHEN datatype = '231' THEN 'TIMESTAMP WITH LOCAL TIME ZONE'
                     WHEN datatype = '2' THEN 'NUMBER'
                     WHEN datatype IN ('4', '21', '22') THEN 'FLOAT'
                     WHEN datatype = '100' THEN 'BINARY_FLOAT'
                     WHEN datatype = '101' THEN 'BINARY_DOUBLE'
                     WHEN datatype = '11' THEN 'ROWID'
                     WHEN datatype = '23' THEN 'RAW'
                     WHEN datatype = '102' THEN 'CURSOR'
                     WHEN datatype = '112' THEN 'CLOB'
                     WHEN datatype = '113' THEN 'BLOB'
                     WHEN datatype = '121' THEN 'ADT'
                     WHEN datatype = '122' THEN 'NESTED TABLE'
                     WHEN datatype = '123' THEN 'VARRAY'
                     END datatype_string,
                     max_length,
                     value_raw,
                     ROWID row_id
                FROM sqlt$_peeked_binds
               WHERE statement_id = p_statement_id
                 AND datatype IS NOT NULL)
    LOOP
      IF i.datatype_string IS NOT NULL THEN
        l_count := l_count + 1;
        l_value_string := cook_raw(i.value_raw, i.datatype_string);
        l_datatype_string := i.datatype_string;

        IF l_datatype_string IN ('CHAR', 'VARCHAR2', 'RAW') THEN
          l_datatype_string := l_datatype_string||'('||i.max_length||')';
        END IF;

        IF i.datatype IN (12, 180, 181, 231) THEN
          l_value_string_date := TO_CHAR(TO_DATE(l_value_string, 'SYYYY/MM/DD HH24:MI:SS'), LOAD_DATE_FORMAT);
        ELSE
          l_value_string_date := NULL;
        END IF;

        UPDATE sqlt$_peeked_binds
           SET datatype_string = l_datatype_string,
               value_string = l_value_string,
               value_string_date = l_value_string_date
         WHERE ROWID = i.row_id;
      END IF;
    END LOOP;

    write_log(l_count||' peeked_binds were extended');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('extend_peeked_binds: '||SQLERRM);
  END extend_peeked_binds;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_value_string_date
   *
   * ------------------------- */
  FUNCTION get_value_string_date (
    p_datatype        IN NUMBER,
    p_datatype_string IN VARCHAR2,
    p_value_anydata   IN SYS.ANYDATA )
  RETURN VARCHAR2
  IS
    l_value VARCHAR2(32767);
    at_return PLS_INTEGER;
    at_date DATE;
    at_ts TIMESTAMP;
    at_tstz TIMESTAMP WITH TIME ZONE;
    at_tsltz TIMESTAMP WITH LOCAL TIME ZONE;
  BEGIN
    l_value := NULL;

    IF p_datatype = 12 OR p_datatype_string = 'DATE' THEN
      at_return := ANYDATA.GETDATE(p_value_anydata, at_date);
      l_value := TO_CHAR(at_date, LOAD_DATE_FORMAT);
    ELSIF p_datatype = 180 THEN
      at_return := ANYDATA.GETTIMESTAMP(p_value_anydata, at_ts);
      l_value := TO_CHAR(at_ts, LOAD_DATE_FORMAT);
    ELSIF p_datatype = 181 THEN
      at_return := ANYDATA.GETTIMESTAMPTZ(p_value_anydata, at_tstz);
      l_value := TO_CHAR(at_tstz, LOAD_DATE_FORMAT);
    ELSIF p_datatype = 231 THEN
      at_return := ANYDATA.GETTIMESTAMPLTZ(p_value_anydata, at_tsltz);
      l_value := TO_CHAR(at_tsltz, LOAD_DATE_FORMAT);
    ELSE -- p_datatype = 180 THEN
      at_return := ANYDATA.GETTIMESTAMP(p_value_anydata, at_date);
      l_value := TO_CHAR(at_date, LOAD_DATE_FORMAT);
    END IF;

    RETURN l_value;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('get_value_string_date "'||p_datatype||'" "'||p_datatype_string||'": '||SQLERRM);
      RETURN NULL;
  END get_value_string_date;

  /*************************************************************************************/

  /* -------------------------
   *
   * public extend_gv$sql_bind_capture
   *
   * ------------------------- */
  PROCEDURE extend_gv$sql_bind_capture (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
    l_value VARCHAR2(32767);

  BEGIN
    write_log('extend_gv$sql_bind_capture');

    -- plan hash value
    BEGIN
      l_count := 0;
      FOR i IN (SELECT c.ROWID row_id,
                       s.plan_hash_value
                  FROM sqlt$_gv$sql_bind_capture c,
                       sqlt$_gv$sql s
                 WHERE c.statement_id = p_statement_id
                   AND c.dup_position IS NULL
                   AND c.statement_id = s.statement_id
                   AND c.sql_id = s.sql_id
                   AND c.inst_id = s.inst_id
                   AND c.child_number = s.child_number
                   AND c.child_address = s.child_address)
      LOOP
        l_count := l_count + 1;

        BEGIN
          UPDATE sqlt$_gv$sql_bind_capture
             SET plan_hash_value = i.plan_hash_value
           WHERE ROWID = i.row_id;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('extend_gv$sql_bind_capture phv: '||SQLERRM);
            EXIT;
        END;
      END LOOP;
      write_log(l_count||' captured_binds were extended with phv');
    END;

    -- value_string
    BEGIN
      l_count := 0;
      FOR i IN (SELECT ROWID row_id, datatype, datatype_string, value_anydata
                  FROM sqlt$_gv$sql_bind_capture
                 WHERE statement_id = p_statement_id
                   AND value_anydata IS NOT NULL
                   AND (datatype IN (12, 180, 181, 231) OR datatype_string = 'DATE' OR datatype_string LIKE 'TIMESTAMP%'))
      LOOP
        BEGIN
          l_count := l_count + 1;
          l_value := get_value_string_date(i.datatype, i.datatype_string, i.value_anydata);

          UPDATE sqlt$_gv$sql_bind_capture
             SET value_string_date = l_value
           WHERE ROWID = i.row_id;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('extend_gv$sql_bind_capture value: '||SQLERRM);
            EXIT;
        END;
      END LOOP;
      write_log(l_count||' captured_binds were extended with value');
    END;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('extend_gv$sql_bind_capture: '||SQLERRM);
  END extend_gv$sql_bind_capture;

  /*************************************************************************************/

  /* -------------------------
   *
   * public extend_gv$sql_optimizer_env
   *
   * ------------------------- */
  PROCEDURE extend_gv$sql_optimizer_env (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;

  BEGIN
    write_log('extend_gv$sql_optimizer_env');

    FOR i IN (SELECT e.ROWID row_id,
                     s.plan_hash_value
                FROM sqlt$_gv$sql_optimizer_env e,
                     sqlt$_gv$sql s
               WHERE e.statement_id = p_statement_id
                 AND e.statement_id = s.statement_id
                 AND e.sql_id = s.sql_id
                 AND e.inst_id = s.inst_id
                 AND e.child_number = s.child_number
                 AND e.child_address = s.child_address)
    LOOP
      l_count := l_count + 1;

      UPDATE sqlt$_gv$sql_optimizer_env
         SET plan_hash_value = i.plan_hash_value
       WHERE ROWID = i.row_id;
    END LOOP;

    write_log(l_count||' optimizer_env were extended');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('extend_gv$sql_optimizer_env: '||SQLERRM);
  END extend_gv$sql_optimizer_env;

  /*************************************************************************************/

  /* -------------------------
   *
   * public extend_dba_hist_sqlbind
   *
   * ------------------------- */
  PROCEDURE extend_dba_hist_sqlbind (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
    l_value VARCHAR2(32767);

  BEGIN
    write_log('extend_dba_hist_sqlbind');

    -- only when there was 1 plan/instance on a snap we can assign it to all binds on same snap/instance
    BEGIN
      l_count := 0;
      FOR i IN (SELECT snap_id,
                       dbid,
                       instance_number,
                       sql_id,
                       MAX(plan_hash_value) plan_hash_value
                  FROM sqlt$_dba_hist_sqlstat
                 WHERE statement_id = p_statement_id
                 GROUP BY
                       snap_id,
                       dbid,
                       instance_number,
                       sql_id
                HAVING COUNT(*) = 1)
      LOOP
        l_count := l_count + 1;

        BEGIN
          UPDATE sqlt$_dba_hist_sqlbind
             SET plan_hash_value = i.plan_hash_value
           WHERE statement_id = p_statement_id
             AND snap_id = i.snap_id
             AND dbid = i.dbid
             AND instance_number = i.instance_number
             AND sql_id = i.sql_id;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('extend_dba_hist_sqlbind phv: '||SQLERRM);
            EXIT;
        END;
      END LOOP;
      write_log(l_count||' captured_binds were extended with phv');
    END;

    -- value_string
    BEGIN
      l_count := 0;
      FOR i IN (SELECT ROWID row_id, datatype, datatype_string, value_anydata
                  FROM sqlt$_dba_hist_sqlbind
                 WHERE statement_id = p_statement_id
                   AND value_anydata IS NOT NULL
                   AND (datatype IN (12, 180, 181, 231) OR datatype_string = 'DATE' OR datatype_string LIKE 'TIMESTAMP%'))
      LOOP
        BEGIN
          l_count := l_count + 1;
          l_value := get_value_string_date(i.datatype, i.datatype_string, i.value_anydata);

          UPDATE sqlt$_dba_hist_sqlbind
             SET value_string_date = l_value
           WHERE ROWID = i.row_id;
        EXCEPTION
          WHEN OTHERS THEN
            write_error('extend_dba_hist_sqlbind value: '||SQLERRM);
            EXIT;
        END;
      END LOOP;
      write_log(l_count||' captured_binds were extended with value');
    END;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('extend_dba_hist_sqlbind: '||SQLERRM);
  END extend_dba_hist_sqlbind;

  /*************************************************************************************/

  /* -------------------------
   *
   * public binds_in_predicates
   *
   * called by sqlt$t.perm_transformation
   *
   * ------------------------- */
  PROCEDURE binds_in_predicates (p_statement_id IN NUMBER)
  IS
    l_count NUMBER;
    l_count_binds NUMBER := 0;
    l_binds_html_table CLOB;

    PROCEDURE wa(p_text IN VARCHAR2)
    IS
    BEGIN
      IF p_text IS NOT NULL THEN
        SYS.DBMS_LOB.WRITEAPPEND (
          lob_loc => l_binds_html_table,
          amount  => LENGTH(p_text),
          buffer  => p_text );
      END IF;
    END wa;

    -- eliminates false positives for example saying that :B1 is in "col=:B10" predicate
    FUNCTION bind_name_in_predicates (
      p_bind_name  IN VARCHAR2,
      p_predicates IN VARCHAR2 )
    RETURN BOOLEAN
    IS
      l_predicates VARCHAR2(32767) := p_predicates;
      l_pos_after_name NUMBER;
      l_char_after_name CHAR(1);
    BEGIN
      WHILE INSTR(l_predicates, p_bind_name) > 0
      LOOP
        l_pos_after_name := INSTR(l_predicates, p_bind_name) + LENGTH(p_bind_name);
        l_char_after_name := SUBSTR(l_predicates, l_pos_after_name, 1);
        IF TRANSLATE(l_char_after_name, '01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ', NUL) <> NUL THEN
          RETURN TRUE; -- character following name is not a letter or a number
        END IF;
        l_predicates := SUBSTR(l_predicates, l_pos_after_name);
      END LOOP;
      RETURN FALSE;
    END bind_name_in_predicates;

  BEGIN
    write_log('binds_in_predicates');

    -- sqlt$_plan_extension
    FOR i IN (SELECT plan_hash_value,
                     plan_id,
                     inst_id,
                     child_number,
                     child_address,
                     access_predicates,
                     filter_predicates,
                     ROWID row_id
                FROM sqlt$_plan_extension
               WHERE statement_id = p_statement_id
                 AND (access_predicates IS NOT NULL OR filter_predicates IS NOT NULL))
    LOOP
      -- peeked binds in sqlt$_plan_extension
      BEGIN
        l_count := 0;
        FOR j IN (SELECT name,
                         value
                    FROM sqlt$_peeked_binds_v
                   WHERE statement_id = p_statement_id
                     AND source = 'PLAN_EXTENSION'
                     AND plan_hash_value = i.plan_hash_value
                     AND plan_id = i.plan_id
                     AND inst_id = i.inst_id
                     AND child_number = i.child_number
                     AND child_address = i.child_address
                     AND (i.access_predicates LIKE '%'||name||'%' OR i.filter_predicates LIKE '%'||name||'%')
                   ORDER BY
                         position)
        LOOP
          IF bind_name_in_predicates(j.name, i.access_predicates||' '||i.filter_predicates||' ') THEN
            l_count := l_count + 1;
            l_count_binds := l_count_binds + 1;
            IF l_count = 1 THEN
              l_binds_html_table := '<table>'||LF;
            END IF;
            wa('<tr><td class="lt">'||j.name||'</td><td nowrap class="l">'||j.value||'</td></tr>'||LF);
          END IF;
        END LOOP;

        IF l_count > 0 THEN
          wa('</table>');
          UPDATE sqlt$_plan_extension SET binds_html_table = l_binds_html_table WHERE ROWID = i.row_id;
        END IF;
      END;

      -- captured binds in sqlt$_plan_extension
      BEGIN
        l_count := 0;
        FOR j IN (SELECT name,
                         value
                    FROM sqlt$_captured_binds_v
                   WHERE statement_id = p_statement_id
                     AND source = 'GV$SQL_PLAN'
                     AND plan_hash_value = i.plan_hash_value
                     AND inst_id = i.inst_id
                     AND child_number = i.child_number
                     AND child_address = i.child_address
                     AND (i.access_predicates LIKE '%'||name||'%' OR i.filter_predicates LIKE '%'||name||'%')
                   ORDER BY
                         position)
        LOOP
          IF bind_name_in_predicates(j.name, i.access_predicates||' '||i.filter_predicates||' ') THEN
            l_count := l_count + 1;
            l_count_binds := l_count_binds + 1;
            IF l_count = 1 THEN
              l_binds_html_table := '<table>'||LF;
            END IF;
            wa('<tr><td class="lt">'||j.name||'</td><td nowrap class="l">'||j.value||'</td></tr>'||LF);
          END IF;
        END LOOP;

        IF l_count > 0 THEN
          wa('</table>');
          UPDATE sqlt$_plan_extension SET binds_html_table_capt = l_binds_html_table WHERE ROWID = i.row_id;
        END IF;
      END;
    END LOOP;

    -- sqlt$_gv$sql_plan
    FOR i IN (SELECT plan_hash_value,
                     inst_id,
                     child_number,
                     child_address,
                     access_predicates,
                     filter_predicates,
                     ROWID row_id
                FROM sqlt$_gv$sql_plan
               WHERE statement_id = p_statement_id
                 AND (access_predicates IS NOT NULL OR filter_predicates IS NOT NULL))
    LOOP
      -- peeked binds in sqlt$_gv$sql_plan
      BEGIN
        l_count := 0;
        FOR j IN (SELECT name,
                         value
                    FROM sqlt$_peeked_binds_v
                   WHERE statement_id = p_statement_id
                     AND source = 'GV$SQL_PLAN'
                     AND plan_hash_value = i.plan_hash_value
                     AND inst_id = i.inst_id
                     AND child_number = i.child_number
                     AND child_address = i.child_address
                     AND (i.access_predicates LIKE '%'||name||'%' OR i.filter_predicates LIKE '%'||name||'%')
                   ORDER BY
                         position)
        LOOP
          IF bind_name_in_predicates(j.name, i.access_predicates||' '||i.filter_predicates||' ') THEN
            l_count := l_count + 1;
            l_count_binds := l_count_binds + 1;
            IF l_count = 1 THEN
              l_binds_html_table := '<table>'||LF;
            END IF;
            wa('<tr><td class="lt">'||j.name||'</td><td nowrap class="l">'||j.value||'</td></tr>'||LF);
          END IF;
        END LOOP;

        IF l_count > 0 THEN
          wa('</table>');
          UPDATE sqlt$_gv$sql_plan SET binds_html_table = l_binds_html_table WHERE ROWID = i.row_id;
        END IF;
      END;

      -- captured binds in sqlt$_gv$sql_plan
      BEGIN
        l_count := 0;
        FOR j IN (SELECT name,
                         value
                    FROM sqlt$_captured_binds_v
                   WHERE statement_id = p_statement_id
                     AND source = 'GV$SQL_PLAN'
                     AND plan_hash_value = i.plan_hash_value
                     AND inst_id = i.inst_id
                     AND child_number = i.child_number
                     AND child_address = i.child_address
                     AND (i.access_predicates LIKE '%'||name||'%' OR i.filter_predicates LIKE '%'||name||'%')
                   ORDER BY
                         position)
        LOOP
          IF bind_name_in_predicates(j.name, i.access_predicates||' '||i.filter_predicates||' ') THEN
            l_count := l_count + 1;
            l_count_binds := l_count_binds + 1;
            IF l_count = 1 THEN
              l_binds_html_table := '<table>'||LF;
            END IF;
            wa('<tr><td class="lt">'||j.name||'</td><td nowrap class="l">'||j.value||'</td></tr>'||LF);
          END IF;
        END LOOP;

        IF l_count > 0 THEN
          wa('</table>');
          UPDATE sqlt$_gv$sql_plan SET binds_html_table_capt = l_binds_html_table WHERE ROWID = i.row_id;
        END IF;
      END;
    END LOOP;

    write_log(l_count_binds||' binds in predicates');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('binds_in_predicates: '||SQLERRM);
  END binds_in_predicates;

  /*************************************************************************************/

  /* -------------------------
   *
   * private extend_gv$sql_monitor
   *
   * ------------------------- */
  PROCEDURE extend_gv$sql_monitor (p_statement_id IN NUMBER)
  IS
    l_count NUMBER := 0;
    l_child_number NUMBER;

  BEGIN
    write_log('extend_gv$sql_monitor');

    FOR i IN (SELECT sql_plan_hash_value,
                     inst_id,
                     sql_child_address,
                     ROWID row_id
                FROM sqlt$_gv$sql_monitor
               WHERE statement_id = p_statement_id)
    LOOP
      BEGIN
        SELECT child_number
          INTO l_child_number
          FROM sqlt$_gv$sql
         WHERE statement_id = p_statement_id
           AND plan_hash_value = i.sql_plan_hash_value
           AND inst_id = i.inst_id
           AND child_address = i.sql_child_address
           AND ROWNUM = 1;

        l_count := l_count + 1;
      EXCEPTION
        WHEN OTHERS THEN
          l_child_number := NULL;
      END;

      UPDATE sqlt$_gv$sql_monitor
         SET sql_child_number = l_child_number
       WHERE ROWID = i.row_id
         AND l_child_number IS NOT NULL;
    END LOOP;

    write_log(l_count||' sql_monitor rows were extended');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('extend_gv$sql_monitor: '||SQLERRM);
  END extend_gv$sql_monitor;

  /*************************************************************************************/

  /* -------------------------
   *
   * public seeds_child_address
   *
   * ------------------------- */
  PROCEDURE seeds_child_address (p_statement_id IN NUMBER)
  IS
  BEGIN
    UPDATE sqlt$_peeked_binds
       SET child_address = '-666'
     WHERE statement_id = p_statement_id
       AND child_address IS NULL;

    UPDATE sqlt$_plan_info
       SET child_address = '-666'
     WHERE statement_id = p_statement_id
       AND child_address IS NULL;

    UPDATE sqlt$_outline_data
       SET child_address = '-666'
     WHERE statement_id = p_statement_id
       AND child_address IS NULL;
  END seeds_child_address;

  /*************************************************************************************/

  /* -------------------------
   *
   * private extend_sqlt$_aux_stats$
   *
   * ------------------------- */
  PROCEDURE extend_sqlt$_aux_stats$ (p_statement_id IN NUMBER)
  IS
  BEGIN
    write_log('extend_sqlt$_aux_stats$');

    UPDATE sqlt$_aux_stats$
       SET order_by = 1,
           description = 'Average CPU speed, in millions of instructions/second, as per no-workload (statistics collected using ''NOWORKLOAD'' option)'
     WHERE statement_id = p_statement_id
       AND sname = 'SYSSTATS_MAIN'
       AND pname = 'CPUSPEEDNW';

    UPDATE sqlt$_aux_stats$
       SET order_by = 2,
           description = 'I/O seek time + latency time + operating system overhead time, in milliseconds (default is 10)'
     WHERE statement_id = p_statement_id
       AND sname = 'SYSSTATS_MAIN'
       AND pname = 'IOSEEKTIM';

    UPDATE sqlt$_aux_stats$
       SET order_by = 3,
           description = 'I/O transfer speed, in bytes/millisecond (default is 4096)'
     WHERE statement_id = p_statement_id
       AND sname = 'SYSSTATS_MAIN'
       AND pname = 'IOTFRSPEED';

    UPDATE sqlt$_aux_stats$
       SET order_by = 4,
           description = 'Average CPU speed, in millions of instructions/second, as per workload (statistics collected using ''INTERVAL'' or ''START'' and ''STOP'' options)'
     WHERE statement_id = p_statement_id
       AND sname = 'SYSSTATS_MAIN'
       AND pname = 'CPUSPEED';

    UPDATE sqlt$_aux_stats$
       SET order_by = 5,
           description = 'Average multiblock read count for full scans, in blocks'
     WHERE statement_id = p_statement_id
       AND sname = 'SYSSTATS_MAIN'
       AND pname = 'MBRC';

    UPDATE sqlt$_aux_stats$
       SET order_by = 6,
           description = 'Average time for a single-block read request (random read), in milliseconds'
     WHERE statement_id = p_statement_id
       AND sname = 'SYSSTATS_MAIN'
       AND pname = 'SREADTIM';

    UPDATE sqlt$_aux_stats$
       SET order_by = 7,
           description = 'Average time for a multi-block read request (for full scans), in milliseconds'
     WHERE statement_id = p_statement_id
       AND sname = 'SYSSTATS_MAIN'
       AND pname = 'MREADTIM';

    UPDATE sqlt$_aux_stats$
       SET order_by = 8,
           description = 'Maximum throughput the I/O subsystem can deliver, in bytes/second'
     WHERE statement_id = p_statement_id
       AND sname = 'SYSSTATS_MAIN'
       AND pname = 'MAXTHR';

    UPDATE sqlt$_aux_stats$
       SET order_by = 9,
           description = 'Average parallel slave I/O throughput, in bytes/second'
     WHERE statement_id = p_statement_id
       AND sname = 'SYSSTATS_MAIN'
       AND pname = 'SLAVETHR';

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('extend_sqlt$_aux_stats$: '||SQLERRM);
  END extend_sqlt$_aux_stats$;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_index_range_scan_cost
   *
   * ------------------------- */
  PROCEDURE compute_index_range_scan_cost (p_statement_id IN NUMBER)
  IS
    l_cost NUMBER;
  BEGIN
    write_log('compute_index_range_scan_cost');

    FOR i IN (SELECT ROWID row_id, blevel, leaf_blocks, clustering_factor
                FROM sqlt$_dba_indexes
               WHERE statement_id = p_statement_id)
    LOOP
      IF i.blevel > 1 THEN
        l_cost := i.blevel + i.leaf_blocks + i.clustering_factor;
      ELSE
        l_cost := i.leaf_blocks + i.clustering_factor;
      END IF;

      UPDATE sqlt$_dba_indexes
         SET index_range_scan_cost = l_cost
       WHERE ROWID = i.row_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('compute_index_range_scan_cost: '||SQLERRM);
  END compute_index_range_scan_cost;

  /*************************************************************************************/

  /* -------------------------
   *
   * private compute_index_leaf_estimate
   *
   * based on index_est_proc_2.sql from Jonathan Lewis
   * http://jonathanlewis.wordpress.com/index-sizing/
   * http://jonathanlewis.wordpress.com/2008/09/26/index-analysis/
   *
   * ------------------------- */
  PROCEDURE compute_index_leaf_estimate (p_statement_id IN NUMBER)
  IS
    L_BLOCKSIZE  CONSTANT NUMBER := sqlt$a.get_v$parameter('db_block_size');
    L_TARGET_USE CONSTANT NUMBER := 90; -- equates to pctfree 10
    L_MINIMUM    CONSTANT NUMBER := 10000; -- ignore indexes smaller than this
    L_OVERHEAD   CONSTANT NUMBER := 192; -- leaf block "lost" space in index_stats

    l_sum_avg_col_len NUMBER;
    l_leaf_estimate_target_size NUMBER;
  BEGIN
    write_log('compute_index_leaf_estimate');

    FOR i IN (SELECT idx.ROWID ind_row_id,
                     --idx.table_owner,
                     --idx.table_name,
                     idx.owner index_owner,
                     idx.index_name,
                     --idx.leaf_blocks,
                     idx.num_rows ind_num_rows,
                     DECODE(idx.uniqueness, 'UNIQUE', 0, 1) ind_uniq_ind,
                     tbl.num_rows tab_num_rows,
                     DECODE(tbl.partitioned, 'YES', 10, 6) tab_rowid_length
                FROM sqlt$_dba_indexes idx,
                     sqlt$_dba_tables tbl
               WHERE idx.statement_id = p_statement_id
                 AND idx.index_type LIKE '%NORMAL%'
                 AND idx.partitioned = 'NO'
                 AND idx.temporary = 'N'
                 AND idx.dropped = 'NO'
                 AND idx.status = 'VALID'
                 AND idx.last_analyzed IS NOT NULL
                 AND idx.num_rows > 0
                 AND idx.leaf_blocks > L_MINIMUM
                 AND tbl.statement_id = idx.statement_id
                 AND tbl.owner = idx.table_owner
                 AND tbl.table_name = idx.table_name
                 AND tbl.num_rows > 0)
    LOOP
      SELECT SUM(tc.avg_col_len)
        INTO l_sum_avg_col_len -- column data bytes
        FROM sqlt$_dba_ind_columns ic,
             sqlt$_dba_tab_cols tc
       WHERE ic.statement_id = p_statement_id
         AND ic.index_owner = i.index_owner
         AND ic.index_name = i.index_name
         AND tc.statement_id = ic.statement_id
         AND tc.owner = ic.table_owner
         AND tc.table_name = ic.table_name
         AND tc.column_name = ic.column_name;

      l_leaf_estimate_target_size :=
      (100 / L_TARGET_USE) * -- assumed packing efficiency
      (i.ind_num_rows * (i.tab_rowid_length + i.ind_uniq_ind + 4) + (i.tab_num_rows * l_sum_avg_col_len)) /
      (L_BLOCKSIZE - L_OVERHEAD);

      UPDATE sqlt$_dba_indexes
         SET leaf_estimate_target_size = ROUND(l_leaf_estimate_target_size)
       WHERE ROWID = i.ind_row_id;
    END LOOP;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('compute_index_leaf_estimate: '||SQLERRM);
  END compute_index_leaf_estimate;

  /*************************************************************************************/

  /* -------------------------
   *
   * private new_11g_ndv_algorithm_used
   *
   * ------------------------- */
  PROCEDURE new_11g_ndv_algorithm_used (p_statement_id IN NUMBER)
  IS
    l_columns_without_histograms NUMBER;
    l_columns_with_histograms NUMBER;
    l_new_algorithm_used NUMBER;
  BEGIN
    write_log('new_11g_ndv_algorithm_used');

    IF sqlt$a.get_rdbms_version >= '11' THEN -- The version of Oracle is 11g
      FOR i IN (SELECT ROWID row_id, owner, table_name, num_rows, sample_size
                  FROM sqlt$_dba_tables
                 WHERE statement_id = p_statement_id
                   AND new_11g_ndv_algorithm_used IS NULL)
      LOOP
        IF i.num_rows = i.sample_size THEN -- The table must have sample_size = num_rows.  (The new algorithm always scans the whole table.)
          SELECT SUM(CASE WHEN histogram = 'NONE' THEN 1 ELSE 0 END),
                 SUM(CASE WHEN histogram = 'NONE' THEN 0 ELSE 1 END),
                 SUM(CASE WHEN histogram = 'NONE' AND sample_size = i.num_rows - num_nulls THEN 1 ELSE 0 END)
            INTO l_columns_without_histograms, l_columns_with_histograms, l_new_algorithm_used
            FROM sqlt$_dba_tab_cols
           WHERE statement_id = p_statement_id
             AND owner = i.owner
             AND table_name = i.table_name;

          IF l_columns_with_histograms > 0 AND l_columns_without_histograms = l_new_algorithm_used THEN -- Every column with no histogram has the column sample_size = num_rows - num_nulls.  (Columns without histograms use the table scan stats.)
            UPDATE sqlt$_dba_tables
               SET new_11g_ndv_algorithm_used = 'YES'
             WHERE statement_id = p_statement_id
               AND ROWID = i.row_id;
          END IF;
        END IF;
      END LOOP;
    END IF;

    UPDATE sqlt$_dba_tables
       SET new_11g_ndv_algorithm_used = 'NO'
     WHERE statement_id = p_statement_id
       AND new_11g_ndv_algorithm_used IS NULL;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      write_error('new_11g_ndv_algorithm_used: '||SQLERRM);
  END new_11g_ndv_algorithm_used;

  /*************************************************************************************/

  /* -------------------------
   *
   * public perm_transformation
   *
   * called by: sqlt$i.common_calls and sqlt$i.remote_xtract
   *
   * ------------------------- */
  PROCEDURE perm_transformation (p_statement_id IN NUMBER)
  IS
    l_statid VARCHAR2(257);
  BEGIN
    write_log('=> perm_transformation');

    l_statid := sqlt$a.get_statid(p_statement_id);

    put_statid_into_plan_table(p_statement_id);
    put_obj_id_into_tables(p_statement_id);
    put_obj_id_into_indexes(p_statement_id);
    record_cbo_system_stats(p_statement_id);
    remap_metadata(p_statement_id);
    table_histograms(p_statement_id);
    partition_histograms(p_statement_id);
    subpartition_histograms(p_statement_id);
    cook_low_and_high_values(p_statement_id);
    IF sqlt$a.get_param('healthcheck_ndv') = 'Y' THEN
      compute_mutating_ndv(p_statement_id);
    END IF;
    IF sqlt$a.get_param('healthcheck_endpoints') = 'Y' THEN
      compute_endpoints_count(p_statement_id);
      compute_mutating_endpoints(p_statement_id); -- depends on *_histograms and compute_endpoints_count
    END IF;
    IF sqlt$a.get_param('healthcheck_num_rows') = 'Y' THEN
      compute_mutating_num_rows(p_statement_id);
    END IF;
    IF sqlt$a.get_param('healthcheck_blevel') = 'Y' THEN
      compute_mutating_blevel(p_statement_id);
    END IF;
    -- moved down column_in_predicates(p_statement_id);
    -- moved down column_in_projection(p_statement_id); -- depends on column_in_predicates
    indexes_in_plan(p_statement_id);
    column_in_indexes(p_statement_id);
    --index_columns(p_statement_id);
    at_least_1_notnull_col(p_statement_id);
    add_column_default(p_statement_id);
    not_shared_cursors(p_statement_id, l_statid);
    flag_dba_hist_sqlstat(p_statement_id);
    best_and_worst_plans(p_statement_id);
    fix_cardinality_line_0(p_statement_id);
    execution_order(p_statement_id);
    sqlt_plan_hash_value(p_statement_id);
    real_depth(p_statement_id);
    real_depth_m(p_statement_id);
    process_other_xml(p_statement_id);  -- has to come before plan_operation	
    plan_operation(p_statement_id); -- depeds on real_depth
    top_cost(p_statement_id);
    top_last_cr_buffer_gets(p_statement_id);
    top_cr_buffer_gets(p_statement_id);
    top_last_cu_buffer_gets(p_statement_id);
    top_cu_buffer_gets(p_statement_id);
    top_last_disk_reads(p_statement_id);
    top_disk_reads(p_statement_id);
    top_last_disk_writes(p_statement_id);
    top_disk_writes(p_statement_id);
    top_last_elapsed_time(p_statement_id);
    top_elapsed_time(p_statement_id);
    build_plan_more_html_table(p_statement_id);
    build_workarea_html_table(p_statement_id);
    build_plan_goto_html_table(p_statement_id);
    sanitize_reason(p_statement_id);
    -- sanitize_dir_notes(p_statement_id);  --150828 obsolete
    sanitize_other_xml(p_statement_id);
    --process_other_xml(p_statement_id);
    extend_peeked_binds(p_statement_id); -- depends on process_other_xml
    extend_gv$sql_bind_capture(p_statement_id);
    extend_gv$sql_optimizer_env(p_statement_id);
    extend_dba_hist_sqlbind(p_statement_id);
    binds_in_predicates(p_statement_id); -- depends on extend_peeked_binds
    column_in_predicates(p_statement_id); -- depends on binds_in_predicates
    column_in_projection(p_statement_id); -- depends on column_in_predicates
    extend_gv$sql_monitor(p_statement_id);
    extend_sqlt$_aux_stats$(p_statement_id);
    compute_index_range_scan_cost(p_statement_id);
    compute_index_leaf_estimate(p_statement_id);
    new_11g_ndv_algorithm_used(p_statement_id);
    col_group_usage_report(p_statement_id);
    add_dv_censored(p_statement_id);

    write_log('<= perm_transformation');
  END perm_transformation;

  /*************************************************************************************/

  /* -------------------------
   *
   * public temp_transformation
   *
   * called by: sqlt$m.main_report
   *
   * ------------------------- */
  PROCEDURE temp_transformation (p_statement_id IN NUMBER)
  IS
  BEGIN
    write_log('=> temp_transformation');

    DELETE sqlg$_column_html_table;
    build_column_html_table_pred(p_statement_id); -- depends on column_in_predicates
    build_column_html_table_idx(p_statement_id);
    index_columns(p_statement_id);

    write_log('<= temp_transformation');
  END temp_transformation;

  /*************************************************************************************/

END sqlt$t;
/

SET TERM ON;
SHOW ERRORS PACKAGE BODY &&tool_administer_schema..sqlt$t;
