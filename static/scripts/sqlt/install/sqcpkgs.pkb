CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..sqlt$s AS
/* $Header: 215187.1 sqcpkgs.pkb 12.1.10 2014/08/08 carlos.sierra mauro.pagano $ */

  /*************************************************************************************/

  /* SYS.DBMS_STATS types

  TYPE numarray  IS VARRAY(256) OF NUMBER;
  TYPE datearray IS VARRAY(256) OF DATE;
  TYPE chararray IS VARRAY(256) OF VARCHAR2(4000);
  TYPE rawarray  IS VARRAY(256) OF RAW(2000);
  TYPE fltarray  IS VARRAY(256) OF BINARY_FLOAT;
  TYPE dblarray  IS VARRAY(256) OF BINARY_DOUBLE;

  TYPE StatRec IS RECORD (
    epc    NUMBER,         -- end points count
    minval RAW(2000),      -- low value
    maxval RAW(2000),      -- high value
    bkvals NUMARRAY,       -- ENDPOINT_NUMBER Histogram bucket number
    novals NUMARRAY,       -- ENDPOINT_VALUE Normalized endpoint value for this bucket
    chvals CHARARRAY,      -- ENDPOINT_ACTUAL_VALUE Actual (not normalized) string value of the endpoint for this bucket
    eavs   NUMBER);
  */

  /* -------------------------
   *
   * private types
   *
   * ------------------------- */
  TYPE sta_rec IS RECORD (
    data_type     sys.dba_tab_cols.data_type%TYPE,
    histogram     sys.dba_tab_cols.histogram%TYPE,
    num_buckets   sys.dba_tab_cols.num_buckets%TYPE,
    last_analyzed sys.dba_tab_cols.last_analyzed%TYPE,
    sample_size   sys.dba_tab_cols.sample_size%TYPE,
    global_stats  sys.dba_tab_cols.global_stats%TYPE,
    user_stats    sys.dba_tab_cols.user_stats%TYPE,
    num_rows      sys.dba_tables.num_rows%TYPE,
    partitioned   sys.dba_tables.partitioned%TYPE,
    distcnt       NUMBER,
    density       NUMBER,
    nullcnt       NUMBER,
    srec          SYS.DBMS_STATS.STATREC,
    avgclen       NUMBER
  );

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  SCIENTIFIC_NOTATION  CONSTANT VARCHAR2(32)  := '0D000000EEEE';
  DATE_FORMAT          CONSTANT VARCHAR2(32)  := 'YYYY/MM/DD HH24:MI:SS';

  /*************************************************************************************/

  /* -------------------------
   *
   * private static_variables
   *
   * ------------------------- */
  s_ownname       VARCHAR2(4000) := USER;
  s_tabname       VARCHAR2(4000) := 'UNKNOWN';
  s_colname       VARCHAR2(4000) := 'UNKNOWN';
  s_end_point     VARCHAR2(4000) := 'UNKNOWN';
  s_partname      VARCHAR2(4000) := 'NULL';
  s_cascade_parts VARCHAR2(4000) := 'TRUE';
  s_preserve_size VARCHAR2(4000) := 'TRUE';
  s_no_invalidate VARCHAR2(4000) := 'FALSE';
  s_force         VARCHAR2(4000) := 'FALSE';

  /*************************************************************************************/

  /* -------------------------
   *
   * private put_line
   *
   * ------------------------- */
  PROCEDURE put_line (p_line IN VARCHAR2)
  IS
  BEGIN
    SYS.DBMS_OUTPUT.PUT_LINE(SUBSTR(p_line, 1, 255));
  END put_line;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_rdbms_version
   *
   * ------------------------- */
  FUNCTION get_rdbms_version
  RETURN VARCHAR2
  IS
    l_version v$instance.version%TYPE;
    BEGIN
    SELECT version INTO l_version FROM v$instance;
    RETURN l_version;
  END get_rdbms_version;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_sta_rec
   *
   * ------------------------- */
  FUNCTION get_sta_rec (
    p_ownname  IN VARCHAR2,
    p_tabname  IN VARCHAR2,
    p_colname  IN VARCHAR2,
    p_partname IN VARCHAR2 DEFAULT NULL )
  RETURN sta_rec
  IS
    l_sta_rec sta_rec;
    l_ownname VARCHAR2(4000);
    l_tabname VARCHAR2(4000);
    l_colname VARCHAR2(4000);
    l_partname VARCHAR2(4000);
  BEGIN
    l_ownname := sqlt$s.clean_object_name(p_ownname);
    l_tabname := sqlt$s.clean_object_name(p_tabname);
    l_colname := sqlt$s.clean_object_name(p_colname);
    l_partname := sqlt$s.clean_object_name(p_partname);

    BEGIN
      SELECT data_type,
             histogram,
             num_buckets,
             last_analyzed,
             sample_size,
             global_stats,
             user_stats
        INTO l_sta_rec.data_type,
             l_sta_rec.histogram,
             l_sta_rec.num_buckets,
             l_sta_rec.last_analyzed,
             l_sta_rec.sample_size,
             l_sta_rec.global_stats,
             l_sta_rec.user_stats
        FROM sys.dba_tab_cols
       WHERE owner = l_ownname
         AND table_name = l_tabname
         AND column_name = l_colname;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        put_line(p_ownname||'.'||p_tabname||'.'||p_colname||' not found');
        RETURN NULL;
    END;

    IF p_partname IS NULL THEN
      SELECT num_rows,
             partitioned
        INTO l_sta_rec.num_rows,
             l_sta_rec.partitioned
        FROM sys.dba_tables
       WHERE owner = l_ownname
         AND table_name = l_tabname;
    ELSE
      BEGIN
        SELECT histogram,
               num_buckets,
               last_analyzed,
               sample_size,
               global_stats,
               user_stats
          INTO l_sta_rec.histogram,
               l_sta_rec.num_buckets,
               l_sta_rec.last_analyzed,
               l_sta_rec.sample_size,
               l_sta_rec.global_stats,
               l_sta_rec.user_stats
          FROM sys.dba_part_col_statistics
         WHERE owner = l_ownname
           AND table_name = l_tabname
           AND partition_name = l_partname
           AND column_name = l_colname;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          put_line(p_ownname||'.'||p_tabname||'.'||NVL(p_partname, '<partname>')||'.'||p_colname||' not found');
          RETURN NULL;
      END;

      SELECT num_rows
        INTO l_sta_rec.num_rows
        FROM sys.dba_tab_partitions
       WHERE table_owner = l_ownname
         AND table_name = l_tabname
         AND partition_name = l_partname;
    END IF;

    BEGIN
      IF l_sta_rec.last_analyzed IS NOT NULL THEN
        SYS.DBMS_STATS.GET_COLUMN_STATS (
          ownname  => p_ownname,
          tabname  => p_tabname,
          colname  => p_colname,
          partname => p_partname,
          distcnt  => l_sta_rec.distcnt,
          density  => l_sta_rec.density,
          nullcnt  => l_sta_rec.nullcnt,
          srec     => l_sta_rec.srec,
          avgclen  => l_sta_rec.avgclen );
      ELSE
        put_line(p_ownname||'.'||p_tabname||'.'||NVL(p_partname, '<partname>')||'.'||p_colname||' has no statistics');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        put_line(SQLERRM);
        put_line('While executing SYS.DBMS_STATS.GET_COLUMN_STATS on '||p_ownname||'.'||p_tabname||'.'||NVL(p_partname, '<partname>')||'.'||p_colname);
    END;

    RETURN l_sta_rec;
  END get_sta_rec;

  /*************************************************************************************/

  /* -------------------------
   *
   * private set_column_stats
   *
   * ------------------------- */
  PROCEDURE set_column_stats (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_distcnt       IN NUMBER,
    p_density       IN NUMBER,
    p_nullcnt       IN NUMBER,
    p_srec          IN SYS.DBMS_STATS.STATREC,
    p_avgclen       IN NUMBER,
    p_no_invalidate IN BOOLEAN DEFAULT FALSE,
    p_force         IN BOOLEAN DEFAULT FALSE )
  IS
  BEGIN
    SYS.DBMS_STATS.SET_COLUMN_STATS (
      ownname       => p_ownname,
      tabname       => p_tabname,
      colname       => p_colname,
      partname      => p_partname,
      distcnt       => p_distcnt,
      density       => p_density,
      nullcnt       => p_nullcnt,
      srec          => p_srec,
      avgclen       => p_avgclen,
      no_invalidate => p_no_invalidate,
      force         => p_force );
  END set_column_stats;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_min_and_max
   *
   * ------------------------- */
  PROCEDURE get_min_and_max (
    p_data_type IN  VARCHAR2,
    p_statrec   IN  SYS.DBMS_STATS.STATREC,
    x_statrec   OUT SYS.DBMS_STATS.STATREC )
  IS
    l_charvals SYS.DBMS_STATS.CHARARRAY;
    l_datevals SYS.DBMS_STATS.DATEARRAY;
    l_numvals  SYS.DBMS_STATS.NUMARRAY;
  BEGIN
    x_statrec := NULL;
    x_statrec.epc := 2;

    IF p_data_type IN ('CHAR', 'VARCHAR2') THEN
      l_charvals := SYS.DBMS_STATS.CHARARRAY ();
      l_charvals.EXTEND(2);
      l_charvals(1) := NVL(p_statrec.chvals(1), get_external_value(p_statrec.novals(1))); -- min
      l_charvals(2) := NVL(p_statrec.chvals(p_statrec.epc), get_external_value(p_statrec.novals(p_statrec.epc))); -- max
      /*
      IF p_data_type = 'CHAR' AND LENGTH(l_charvals(1)) < 15 THEN
        l_charvals(1) := RPAD(l_charvals(1), 15);
      END IF;
      IF p_data_type = 'CHAR' AND LENGTH(l_charvals(2)) < 15 THEN
        l_charvals(2) := RPAD(l_charvals(2), 15);
      END IF;
      */
      SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => x_statrec, charvals => l_charvals);
    ELSIF p_data_type = 'NUMBER' THEN
      l_numvals := SYS.DBMS_STATS.NUMARRAY ();
      l_numvals.EXTEND(2);
      l_numvals(1) := p_statrec.novals(1); -- min
      l_numvals(2) := p_statrec.novals(p_statrec.epc); -- max
      SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => x_statrec, numvals => l_numvals);
    ELSIF SUBSTR(p_data_type, 1, 8) IN ('DATE', 'TIMESTAM') THEN
      l_datevals := SYS.DBMS_STATS.DATEARRAY ();
      l_datevals.EXTEND(2);
      l_datevals(1) := TO_DATE(TO_CHAR(TRUNC(p_statrec.novals(1))), 'J') + (p_statrec.novals(1) - TRUNC(p_statrec.novals(1)));
      l_datevals(2) := TO_DATE(TO_CHAR(TRUNC(p_statrec.novals(p_statrec.epc))), 'J') + (p_statrec.novals(p_statrec.epc) - TRUNC(p_statrec.novals(p_statrec.epc)));
      SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => x_statrec, datevals => l_datevals);
    END IF;
  END get_min_and_max;

  /*************************************************************************************/

  /* -------------------------
   *
   * private get_value
   *
   * ------------------------- */
  PROCEDURE get_value (
    p_data_type IN  VARCHAR2,
    p_value     IN  VARCHAR2, -- if date use YYYY/MM/DD HH24:MI:SS
    x_char      OUT VARCHAR2,
    x_date      OUT DATE,
    x_number    OUT NUMBER,
    x_noval     OUT NUMBER )
  IS
    l_number NUMBER;
  BEGIN
    IF p_data_type IN ('CHAR', 'VARCHAR2') THEN
      x_char := p_value;
      IF p_data_type = 'CHAR' AND LENGTH(x_char) < 15 THEN
        x_char := RPAD(x_char, 15);
        put_line('value15:"'||x_char||'"');
      ELSIF LENGTH(x_char) > 32 THEN
        x_char := SUBSTR(x_char, 1, 32);
        put_line('value32:"'||x_char||'"');
      END IF;
      x_noval := get_internal_value(x_char);
      IF TO_CHAR(x_noval) NOT LIKE '%000000000000000000000' THEN
        put_line('invalid '||p_data_type||' value:"'||p_value||'"('||x_noval||')');
        x_noval := NULL;
      END IF;
    ELSIF p_data_type = 'NUMBER' THEN
      BEGIN
        x_number := TO_NUMBER(p_value);
        x_noval := TO_NUMBER(p_value);
      EXCEPTION
        WHEN OTHERS THEN
          put_line(SQLERRM);
          put_line('invalid '||p_data_type||' value:"'||p_value||'"');
          x_noval := NULL;
      END;
    ELSIF SUBSTR(p_data_type, 1, 8) IN ('DATE', 'TIMESTAM') THEN
      IF p_value LIKE '____/__/__ __:__:__' THEN
        BEGIN
          x_date := TO_DATE(p_value, DATE_FORMAT);
          l_number := x_date - TRUNC(x_date);
          x_noval := TO_NUMBER(TO_CHAR(x_date, 'J')) + l_number;
        EXCEPTION
          WHEN OTHERS THEN
            put_line(SQLERRM);
            put_line('invalid '||p_data_type||' value:"'||p_value||'"');
            x_noval := NULL;
        END;
      ELSIF p_value LIKE '____/__/__' THEN
        BEGIN
          x_date := TO_DATE(p_value, 'YYYY/MM/DD');
          x_noval := TO_NUMBER(TO_CHAR(x_date, 'J'));
        EXCEPTION
          WHEN OTHERS THEN
            put_line(SQLERRM);
            put_line('invalid '||p_data_type||' value:"'||p_value||'"');
            x_noval := NULL;
        END;
      ELSE
        put_line('Invalid format for date value: "'||p_value||'"');
        x_noval := NULL;
      END IF;
    ELSE
      put_line('Invalid format for date value: "'||p_value||'"');
      x_noval := NULL;
    END IF;

    x_noval := ROUND(x_noval, 8);
  END get_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_internal_value
   *
   * returns internal representation of histogram value
   *
   * input looks like EM1 and output looks like 359834110958347000000000000000000000
   *
   * ------------------------- */
  FUNCTION get_internal_value (p_value IN VARCHAR2)
  RETURN VARCHAR2
  IS
    temp_n NUMBER := 0;
  BEGIN
    FOR i IN 1..15
    LOOP
      temp_n := temp_n + POWER(256, 15 - i) * ASCII(SUBSTR(RPAD(p_value, 15, CHR(0)), i, 1));
    END LOOP;
    RETURN TO_CHAR(ROUND(temp_n, -21));
  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_value;
  END get_internal_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_external_value
   *
   * returns user representation of histogram value
   *
   * input looks like 359834110958347000000000000000000000 and output looks like EM1
   *
   * ------------------------- */
  FUNCTION get_external_value (p_value IN VARCHAR2)
  RETURN VARCHAR2
  IS
    temp_n NUMBER;
    temp_i INTEGER;
    my_result VARCHAR2(32767) := NULL;

  BEGIN
    IF LENGTH(p_value) <> 36 OR
       SUBSTR(p_value, 16) <> '000000000000000000000' OR
       p_value > POWER(256, 15) OR
       p_value < POWER(256, 14) THEN
      RETURN p_value; -- cannot get external value
    END IF;

    temp_n := p_value / POWER(256, 14); -- get most significant digits

    -- decoding most significant digits then shift multiplying by 256
    FOR i IN 1..14
    LOOP
      temp_i := TRUNC(temp_n);
      temp_n := (temp_n - temp_i) * 256;
      IF temp_i NOT BETWEEN 32 AND 126 OR temp_n NOT BETWEEN 32 AND 126 THEN
        EXIT; -- reached the tail
      END IF;
      my_result := my_result||CHR(temp_i); -- all but last byte
    END LOOP;

    IF temp_i NOT BETWEEN 32 AND 126 THEN
      RETURN my_result||'?'; -- cannot decode
    END IF;

    -- scan to the right starting at temp_i
    FOR i IN temp_i..126
    LOOP
      IF get_internal_value(my_result||CHR(i)) = p_value THEN
        RETURN my_result||CHR(i); -- approximate value
      END IF;
    END LOOP;

    -- scan to the left starting at temp_i
    FOR i IN 32..temp_i
    LOOP
      IF get_internal_value(my_result||CHR(temp_i + 32 - i)) = p_value THEN
        RETURN my_result||CHR(temp_i + 32 - i); -- approximate value
      END IF;
    END LOOP;

    RETURN my_result||CHR(temp_i); -- this is the best we could do 
  
  --my_result := utl_raw.cast_to_varchar2(lpad(to_char(trunc((p_value+5e20)/power(256,9)), 'fmxxxxxxxxxxxx'),12,'0'));

  RETURN my_result;

  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_value;
  END get_external_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_enpoint_value
   *
   * ------------------------- */
  FUNCTION get_enpoint_value (
    p_data_type             IN VARCHAR2,  -- sys.dba_tab_cols.data_type
    p_endpoint_value        IN NUMBER,    -- sys.dba_tab_histograms.endpoint_value
    p_endpoint_actual_value IN VARCHAR2 ) -- sys.dba_tab_histograms.endpoint_actual_value
  RETURN VARCHAR2                         -- endpoint_estimated_value
  IS
    l_date DATE;
    l_return sqlt$_dba_tab_histograms.endpoint_actual_value%TYPE;

  BEGIN
    IF p_endpoint_actual_value IS NOT NULL THEN -- see bug 3333781
      l_return := p_endpoint_actual_value;
    ELSIF p_data_type = 'DATE' OR p_data_type LIKE 'TIMESTAMP%' THEN
      l_date := TO_DATE(TO_CHAR(TRUNC(p_endpoint_value)), 'J') + (p_endpoint_value - TRUNC(p_endpoint_value));
      l_return := TO_CHAR(l_date, 'S'||DATE_FORMAT);
    ELSIF p_data_type IN ('NUMBER', 'FLOAT', 'BINARY_FLOAT') THEN
      l_return := TO_CHAR(p_endpoint_value);
    ELSE
      l_return := get_external_value(p_endpoint_value);
    END IF;

    RETURN l_return;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_endpoint_value;
  END get_enpoint_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * public convert_raw_value
   *
   * ------------------------- */
  FUNCTION convert_raw_value (
    p_raw       IN RAW,
    p_data_type IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_resval               VARCHAR2(4000);
    l_resval_varchar2      VARCHAR2(4000);
    l_resval_date          DATE;
    l_resval_number        NUMBER;
    l_resval_binary_float  BINARY_FLOAT;
    l_resval_binary_double BINARY_DOUBLE;

  BEGIN
    IF p_raw IS NULL OR p_data_type IS NULL THEN
      l_resval := NULL;
    ELSIF p_data_type IN ('CHAR', '96', 'VARCHAR2', '1', 'NCHAR', 'NVARCHAR2') THEN
      SYS.DBMS_STATS.CONVERT_RAW_VALUE(p_raw, l_resval_varchar2);
      l_resval := l_resval_varchar2;
    ELSIF p_data_type IN ('DATE', '12', '180', '181', '231') OR p_data_type LIKE 'TIMESTAMP%' THEN
      SYS.DBMS_STATS.CONVERT_RAW_VALUE(p_raw, l_resval_date);
      l_resval := TO_CHAR(l_resval_date, 'S'||DATE_FORMAT);
    ELSIF p_data_type IN ('NUMBER', 'FLOAT', '2', '4', '21', '22') THEN
      SYS.DBMS_STATS.CONVERT_RAW_VALUE(p_raw, l_resval_number);
      l_resval := TO_CHAR(l_resval_number);
    ELSIF p_data_type IN ('BINARY_FLOAT', '100') THEN
      SYS.DBMS_STATS.CONVERT_RAW_VALUE(p_raw, l_resval_binary_float);
      l_resval := TO_CHAR(l_resval_binary_float);
    ELSIF p_data_type IN ('BINARY_DOUBLE', '101') THEN
      SYS.DBMS_STATS.CONVERT_RAW_VALUE(p_raw, l_resval_binary_double);
      l_resval := TO_CHAR(l_resval_binary_double);
    ELSIF p_data_type IN ('RAW', '23') THEN
      l_resval := TO_CHAR(p_raw);
    ELSE
      l_resval := TO_CHAR(p_raw);
    END IF;

    RETURN l_resval;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_raw;
  END convert_raw_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * public static functions
   *
   * ------------------------- */
  FUNCTION static_ownname
  RETURN VARCHAR2 IS
  BEGIN
    RETURN s_ownname;
  END static_ownname;

  FUNCTION static_tabname
  RETURN VARCHAR2 IS
  BEGIN
    RETURN s_tabname;
  END static_tabname;

  FUNCTION static_colname
  RETURN VARCHAR2 IS
  BEGIN
    RETURN s_colname;
  END static_colname;

  FUNCTION static_end_point
  RETURN VARCHAR2 IS
  BEGIN
    RETURN s_end_point;
  END static_end_point;

  FUNCTION static_partname
  RETURN VARCHAR2 IS
  BEGIN
    RETURN s_partname;
  END static_partname;

  FUNCTION static_cascade_parts
  RETURN VARCHAR2 IS
  BEGIN
    RETURN s_cascade_parts;
  END static_cascade_parts;

  FUNCTION static_preserve_size
  RETURN VARCHAR2 IS
  BEGIN
    RETURN s_preserve_size;
  END static_preserve_size;

  FUNCTION static_no_invalidate
  RETURN VARCHAR2 IS
  BEGIN
    RETURN s_no_invalidate;
  END static_no_invalidate;

  FUNCTION static_force
  RETURN VARCHAR2 IS
  BEGIN
    RETURN s_force;
  END static_force;

  /*************************************************************************************/

  /* -------------------------
   *
   * public clean_object_name
   *
   * ------------------------- */
  FUNCTION clean_object_name (p_object_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
  BEGIN
    IF TRIM(p_object_name) LIKE '"%"' THEN
      RETURN TRIM('"' FROM TRIM(p_object_name));
    ELSE
      RETURN UPPER(TRIM(p_object_name));
    END IF;
  END clean_object_name;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_bucket_size
   *
   * ------------------------- */
  FUNCTION get_bucket_size (
    p_ownname   IN VARCHAR2,
    p_tabname   IN VARCHAR2,
    p_colname   IN VARCHAR2,
    p_end_point IN INTEGER,
    p_partname  IN VARCHAR2 DEFAULT NULL )
  RETURN INTEGER
  IS
    l_sta_rec sta_rec;
  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_end_point := p_end_point;
    s_partname := NVL(p_partname, 'NULL');

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

    IF p_end_point IS NULL OR p_end_point <= 0 OR p_end_point > l_sta_rec.srec.epc THEN
      RETURN 0;
    ELSIF p_end_point = 1 THEN
      RETURN l_sta_rec.srec.bkvals(1);
    ELSE -- between 2 and epc
      RETURN l_sta_rec.srec.bkvals(p_end_point) - l_sta_rec.srec.bkvals(p_end_point - 1);
    END IF;
  END get_bucket_size;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_data_format
   *
   * ------------------------- */
  FUNCTION get_data_format (
    p_ownname IN VARCHAR2,
    p_tabname IN VARCHAR2,
    p_colname IN VARCHAR2 )
  RETURN VARCHAR2
  IS
    l_sta_rec sta_rec;
  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => NULL);

    IF SUBSTR(l_sta_rec.data_type, 1, 8) IN ('DATE', 'TIMESTAM') THEN
      RETURN DATE_FORMAT||' ';
    ELSE
      RETURN NULL;
    END IF;
  END get_data_format;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_min_value
   *
   * ------------------------- */
  FUNCTION get_min_value (
    p_ownname  IN VARCHAR2,
    p_tabname  IN VARCHAR2,
    p_colname  IN VARCHAR2,
    p_partname IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2
  IS
    l_sta_rec sta_rec;
  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_partname := NVL(p_partname, 'NULL');

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

    RETURN convert_raw_value(l_sta_rec.srec.minval, l_sta_rec.data_type);
  END get_min_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_max_value
   *
   * ------------------------- */
  FUNCTION get_max_value (
    p_ownname  IN VARCHAR2,
    p_tabname  IN VARCHAR2,
    p_colname  IN VARCHAR2,
    p_partname IN VARCHAR2 DEFAULT NULL )
  RETURN VARCHAR2
  IS
    l_sta_rec sta_rec;
  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_partname := NVL(p_partname, 'NULL');

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

    RETURN convert_raw_value(l_sta_rec.srec.maxval, l_sta_rec.data_type);
  END get_max_value;

  /*************************************************************************************/

  /* -------------------------
   *
   * public display_column_stats
   *
   * ------------------------- */
  FUNCTION display_column_stats (
    p_ownname  IN VARCHAR2,
    p_tabname  IN VARCHAR2,
    p_colname  IN VARCHAR2,
    p_partname IN VARCHAR2 DEFAULT NULL )
  RETURN SYS.DBMS_DEBUG_VC2COLL PIPELINED
  IS
    l_sta_rec sta_rec;
    l_prior_bkval NUMBER;
    l_hgrm_line VARCHAR2(2000);
    l_size NUMBER;
    l_popular_values NUMBER;
    l_popular_buckets NUMBER;
    l_new_density NUMBER;
    l_chval VARCHAR2(4000);

  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_partname := NVL(p_partname, 'NULL');

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

    PIPE ROW('ownname:'||p_ownname||' tabname:'||p_tabname||' colname:'||p_colname||' partname:'||NVL(p_partname, '<partname>'));
    PIPE ROW('distcnt:'||l_sta_rec.distcnt||' density:'||TRIM(LOWER(TO_CHAR(l_sta_rec.density, SCIENTIFIC_NOTATION)))||' nullcnt:'||l_sta_rec.nullcnt||' avgclen:'||l_sta_rec.avgclen);
    PIPE ROW('type:"'||l_sta_rec.data_type||'" hgrm:"'||l_sta_rec.histogram||'" buckets:'||l_sta_rec.num_buckets||' analyzed:"'||TO_CHAR(l_sta_rec.last_analyzed, DATE_FORMAT)||'"');
    PIPE ROW('sample:'||l_sta_rec.sample_size||' global:"'||l_sta_rec.global_stats||'" user:"'||l_sta_rec.user_stats||'" rows:'||l_sta_rec.num_rows);
    PIPE ROW('minval:"'||convert_raw_value(l_sta_rec.srec.minval, l_sta_rec.data_type)||'"('||l_sta_rec.srec.minval||')');
    PIPE ROW('maxval:"'||convert_raw_value(l_sta_rec.srec.maxval, l_sta_rec.data_type)||'"('||l_sta_rec.srec.maxval||')');
    PIPE ROW('epc:'||l_sta_rec.srec.epc);

    IF l_sta_rec.srec.epc > 0 THEN
      l_prior_bkval := 0;
      l_popular_values := 0;
      l_popular_buckets := 0;
      FOR i IN 1 .. l_sta_rec.srec.epc
      LOOP
        BEGIN
          l_hgrm_line :=
          'ep:'||i||' '||
          'bkvals:'||l_sta_rec.srec.bkvals(i)||' '||
          'novals:'||l_sta_rec.srec.novals(i);

          BEGIN
            l_chval := l_sta_rec.srec.chvals(i);
            IF l_chval IS NOT NULL THEN
              l_hgrm_line := l_hgrm_line||
              ' chvals:"'||l_chval||'"';
            END IF;
          EXCEPTION
            WHEN OTHERS THEN
              l_chval := NULL;
          END;

          l_size := l_sta_rec.srec.bkvals(i) - l_prior_bkval;
          l_prior_bkval := l_sta_rec.srec.bkvals(i);

          l_hgrm_line := l_hgrm_line||
          ' value:"'||get_enpoint_value(l_sta_rec.data_type, l_sta_rec.srec.novals(i), l_chval)||'"'||
          ' size:'||l_size;

          IF l_sta_rec.histogram = 'HEIGHT BALANCED' AND l_size > 1 THEN
            l_popular_values := l_popular_values + 1;
            l_popular_buckets := l_popular_buckets + l_size;
            l_hgrm_line := l_hgrm_line||
            ' popular';
          END IF;

          PIPE ROW(l_hgrm_line);
        EXCEPTION
          WHEN OTHERS THEN
            PIPE ROW(SQLERRM||'. While trying to display content of ep:'||i);
        END;
      END LOOP;

      IF l_sta_rec.histogram = 'HEIGHT BALANCED' THEN
        PIPE ROW('polular values:'||l_popular_values||' buckets:'||l_popular_buckets);
        IF l_sta_rec.num_buckets > 0 AND (l_sta_rec.distcnt - l_popular_values) > 0 THEN
          l_new_density := (l_sta_rec.num_buckets - l_popular_buckets) / l_sta_rec.num_buckets / (l_sta_rec.distcnt - l_popular_values);
          PIPE ROW('new density:'||TRIM(LOWER(TO_CHAR(l_new_density, SCIENTIFIC_NOTATION))));
        END IF;
      END IF;
    ELSE
      NULL; -- if epc <= 2 then l_sta_rec.srec is not initialized (expect ORA-06533: Subscript beyond count.)
    END IF;

    RETURN;
  END display_column_stats;

  /*************************************************************************************/

  /* -------------------------
   *
   * public delete_column_hgrm
   *
   * ------------------------- */
  PROCEDURE delete_column_hgrm (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_cascade_parts IN BOOLEAN  DEFAULT TRUE,
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE )
  IS
    l_sta_rec sta_rec;
    l_ownname VARCHAR2(4000);
    l_tabname VARCHAR2(4000);
    l_new_statrec SYS.DBMS_STATS.STATREC;
    l_charvals SYS.DBMS_STATS.CHARARRAY;
    l_datevals SYS.DBMS_STATS.DATEARRAY;
    l_numvals SYS.DBMS_STATS.NUMARRAY;

  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_end_point := 'UNKNOWN';
    s_partname := NVL(p_partname, 'NULL');
    IF p_cascade_parts THEN s_cascade_parts := 'TRUE'; ELSE s_cascade_parts := 'FALSE'; END IF;
    IF p_no_invalidate THEN s_no_invalidate := 'TRUE'; ELSE s_no_invalidate := 'FALSE'; END IF;
    IF p_force THEN s_force := 'TRUE'; ELSE s_force := 'FALSE'; END IF;

    put_line('delete_column_hgrm: '||p_ownname||'.'||p_tabname||'.'||NVL(p_partname, '<partname>')||'.'||p_colname);

    IF get_rdbms_version >= '11' THEN -- 11g
      EXECUTE IMMEDIATE
      'BEGIN SYS.DBMS_STATS.DELETE_COLUMN_STATS(ownname => :ownname, tabname => :tabname, colname => :colname, partname => :partname, cascade_parts => '||s_cascade_parts||', no_invalidate => '||s_no_invalidate||', force => '||s_force||', col_stat_type => ''HISTOGRAM''); END;'
      USING IN p_ownname, IN p_tabname, IN p_colname, IN p_partname;
    ELSE -- 10g
      l_ownname := sqlt$s.clean_object_name(p_ownname);
      l_tabname := sqlt$s.clean_object_name(p_tabname);

      l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

      IF NVL(l_sta_rec.histogram, 'NONE') IN ('FREQUENCY', 'HEIGHT BALANCED') AND l_sta_rec.srec.epc > 0 THEN
        l_new_statrec := NULL;
        l_new_statrec.epc := 2;

        IF l_sta_rec.data_type IN ('CHAR', 'VARCHAR2') THEN
          l_charvals := SYS.DBMS_STATS.CHARARRAY ();
        l_charvals.EXTEND(2);
        SYS.DBMS_STATS.CONVERT_RAW_VALUE(l_sta_rec.srec.minval, l_charvals(1));
        SYS.DBMS_STATS.CONVERT_RAW_VALUE(l_sta_rec.srec.maxval, l_charvals(2));
        IF l_sta_rec.data_type = 'CHAR' AND LENGTH(l_charvals(1)) < 15 THEN
          l_charvals(1) := RPAD(l_charvals(1), 15);
        END IF;
        IF l_sta_rec.data_type = 'CHAR' AND LENGTH(l_charvals(2)) < 15 THEN
          l_charvals(2) := RPAD(l_charvals(2), 15);
        END IF;
        SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => l_new_statrec, charvals => l_charvals);
      ELSIF l_sta_rec.data_type = 'NUMBER' THEN
        l_numvals := SYS.DBMS_STATS.NUMARRAY ();
        l_numvals.EXTEND(2);
        SYS.DBMS_STATS.CONVERT_RAW_VALUE(l_sta_rec.srec.minval, l_numvals(1));
        SYS.DBMS_STATS.CONVERT_RAW_VALUE(l_sta_rec.srec.maxval, l_numvals(2));
        SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => l_new_statrec, numvals => l_numvals);
      ELSIF SUBSTR(l_sta_rec.data_type, 1, 8) IN ('DATE', 'TIMESTAM') THEN
        l_datevals := SYS.DBMS_STATS.DATEARRAY ();
        l_datevals.EXTEND(2);
        SYS.DBMS_STATS.CONVERT_RAW_VALUE(l_sta_rec.srec.minval, l_datevals(1));
        SYS.DBMS_STATS.CONVERT_RAW_VALUE(l_sta_rec.srec.maxval, l_datevals(2));
        SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => l_new_statrec, datevals => l_datevals);
      ELSE
        put_line('invalid data_type:"'||l_sta_rec.data_type||'"');
        RETURN;
      END IF;

      IF NVL(l_sta_rec.distcnt, 0) = 0 THEN
        l_sta_rec.density := l_sta_rec.distcnt;
      ELSE
        l_sta_rec.density := 1 / l_sta_rec.distcnt;
      END IF;

      set_column_stats (
        p_ownname       => p_ownname,
        p_tabname       => p_tabname,
        p_colname       => p_colname,
        p_partname      => p_partname,
        p_distcnt       => l_sta_rec.distcnt,
        p_density       => l_sta_rec.density,
        p_nullcnt       => l_sta_rec.nullcnt,
        p_srec          => l_new_statrec,
        p_avgclen       => l_sta_rec.avgclen,
        p_no_invalidate => p_no_invalidate,
        p_force         => p_force );
      END IF;
    END IF;

    IF l_sta_rec.partitioned = 'YES' AND p_partname IS NULL AND p_cascade_parts THEN
      FOR i IN (SELECT partition_name
                  FROM sys.dba_tab_partitions
                 WHERE table_owner = l_ownname
                   AND table_name = l_tabname
                 ORDER BY
                       partition_name)
      LOOP
        delete_column_hgrm (
          p_ownname       => p_ownname,
          p_tabname       => p_tabname,
          p_colname       => p_colname,
          p_partname      => i.partition_name,
          p_cascade_parts => FALSE,
          p_no_invalidate => p_no_invalidate,
          p_force         => p_force );
      END LOOP;
    END IF;
  END delete_column_hgrm;

  /*************************************************************************************/

  /* -------------------------
   *
   * public delete_table_hgrm
   *
   * ------------------------- */
  PROCEDURE delete_table_hgrm (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_cascade_parts IN BOOLEAN  DEFAULT TRUE,
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE )
  IS
    l_ownname VARCHAR2(4000);
    l_tabname VARCHAR2(4000);
  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := 'UNKNOWN';
    s_end_point := 'UNKNOWN';
    s_partname := NVL(p_partname, 'NULL');
    IF p_cascade_parts THEN s_cascade_parts := 'TRUE'; ELSE s_cascade_parts := 'FALSE'; END IF;
    IF p_no_invalidate THEN s_no_invalidate := 'TRUE'; ELSE s_no_invalidate := 'FALSE'; END IF;
    IF p_force THEN s_force := 'TRUE'; ELSE s_force := 'FALSE'; END IF;

    l_ownname := sqlt$s.clean_object_name(p_ownname);
    l_tabname := sqlt$s.clean_object_name(p_tabname);

    FOR i IN (SELECT column_name
                FROM sys.dba_tab_cols
               WHERE owner = l_ownname
                 AND table_name = l_tabname
                 AND (data_type IN ('CHAR', 'VARCHAR2', 'NUMBER') OR SUBSTR(data_type, 1, 8) IN ('DATE', 'TIMESTAM'))
               ORDER BY
                     column_name)
    LOOP
      delete_column_hgrm (
        p_ownname       => p_ownname,
        p_tabname       => p_tabname,
        p_colname       => i.column_name,
        p_partname      => p_partname,
        p_cascade_parts => p_cascade_parts,
        p_no_invalidate => p_no_invalidate,
        p_force         => p_force );
    END LOOP;
  END delete_table_hgrm;

  /*************************************************************************************/

  /* -------------------------
   *
   * public delete_schema_hgrm
   *
   * ------------------------- */
  PROCEDURE delete_schema_hgrm (
    p_ownname       IN VARCHAR2,
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE )
  IS
    l_ownname VARCHAR2(4000);
  BEGIN
    s_ownname := p_ownname;
    s_tabname := 'UNKNOWN';
    s_colname := 'UNKNOWN';
    s_end_point := 'UNKNOWN';
    IF p_no_invalidate THEN s_no_invalidate := 'TRUE'; ELSE s_no_invalidate := 'FALSE'; END IF;
    IF p_force THEN s_force := 'TRUE'; ELSE s_force := 'FALSE'; END IF;

    l_ownname := sqlt$s.clean_object_name(p_ownname);

    FOR i IN (SELECT table_name
                FROM sys.dba_tables
               WHERE owner = l_ownname
               ORDER BY
                     table_name)
    LOOP
      delete_table_hgrm (
        p_ownname       => p_ownname,
        p_tabname       => i.table_name,
        p_partname      => NULL,
        p_cascade_parts => TRUE,
        p_no_invalidate => p_no_invalidate,
        p_force         => p_force );
    END LOOP;
  END delete_schema_hgrm;

  /*************************************************************************************/

  /* -------------------------
   *
   * public delete_hgrm_bucket
   *
   * ------------------------- */
  PROCEDURE delete_hgrm_bucket (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_end_point     IN INTEGER,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_preserve_size IN BOOLEAN  DEFAULT TRUE, -- of subsequent buckets
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE )
  IS
    l_new_idx     INTEGER;
    l_adj_size    NUMBER;
    l_sta_rec     sta_rec;
    l_new_statrec SYS.DBMS_STATS.STATREC;
    l_tmp_statrec SYS.DBMS_STATS.STATREC;
    l_charvals    SYS.DBMS_STATS.CHARARRAY;
    l_datevals    SYS.DBMS_STATS.DATEARRAY;
    l_numvals     SYS.DBMS_STATS.NUMARRAY;

  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_end_point := p_end_point;
    s_partname := NVL(p_partname, 'NULL');
    IF p_preserve_size THEN s_preserve_size := 'TRUE'; ELSE s_preserve_size := 'FALSE'; END IF;
    IF p_no_invalidate THEN s_no_invalidate := 'TRUE'; ELSE s_no_invalidate := 'FALSE'; END IF;
    IF p_force THEN s_force := 'TRUE'; ELSE s_force := 'FALSE'; END IF;

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

    IF NVL(l_sta_rec.histogram, 'NONE') NOT IN ('FREQUENCY', 'HEIGHT BALANCED') OR
       (l_sta_rec.histogram = 'FREQUENCY' AND p_end_point NOT BETWEEN 1 AND l_sta_rec.srec.epc) OR
       (l_sta_rec.histogram = 'HEIGHT BALANCED' AND p_end_point NOT BETWEEN 2 AND l_sta_rec.srec.epc) OR
       l_sta_rec.srec.epc IS NULL
    THEN
      put_line('only well formed histograms can be modified, and end_point must be within valid range');
      RETURN;
    END IF;

    IF (l_sta_rec.histogram = 'HEIGHT BALANCED' AND l_sta_rec.srec.epc <= 2) OR (l_sta_rec.histogram = 'FREQUENCY' AND l_sta_rec.srec.epc = 1) THEN
      delete_column_hgrm ( -- histogram with only 1 bucket!
        p_ownname       => p_ownname,
        p_tabname       => p_tabname,
        p_colname       => p_colname,
        p_partname      => p_partname,
        p_cascade_parts => TRUE,
        p_no_invalidate => p_no_invalidate,
        p_force         => p_force );
      RETURN;
    END IF;

    l_new_statrec := l_sta_rec.srec; -- in case this is 11g so eavs does not go uninitialized

    l_new_statrec.epc := l_sta_rec.srec.epc - 1; -- one end point will go away
    l_new_statrec.minval := l_sta_rec.srec.minval;
    l_new_statrec.maxval := l_sta_rec.srec.maxval;

    l_new_statrec.bkvals := SYS.DBMS_STATS.NUMARRAY ();
    l_new_statrec.novals := SYS.DBMS_STATS.NUMARRAY ();
    l_new_statrec.chvals := SYS.DBMS_STATS.CHARARRAY ();

    l_adj_size := 0;
    FOR i IN 1 .. l_sta_rec.srec.epc
    LOOP
      IF i = p_end_point THEN
        put_line('delete_hgrm_bucket:'||i||' bkvals:'||l_sta_rec.srec.bkvals(i)||' novals:'||l_sta_rec.srec.novals(i)||' chvals:"'||l_sta_rec.srec.chvals(i)||'"');

        IF p_preserve_size THEN
          IF p_end_point = 1 THEN
            l_adj_size := l_sta_rec.srec.bkvals(i);
          ELSE
            l_adj_size := l_sta_rec.srec.bkvals(i) - l_sta_rec.srec.bkvals(i - 1);
          END IF;
        END IF;
      ELSE -- i < p_end_point or i > p_end_point
        l_new_statrec.bkvals.EXTEND;
        l_new_statrec.novals.EXTEND;
        l_new_statrec.chvals.EXTEND;
        IF i < p_end_point THEN
          l_new_idx := i; -- copy into same row
        ELSE -- i > p_end_point
          l_new_idx := i - 1; -- copy into prior row
        END IF;
        l_new_statrec.bkvals(l_new_idx) := l_sta_rec.srec.bkvals(i) - l_adj_size;
        l_new_statrec.novals(l_new_idx) := l_sta_rec.srec.novals(i);
        l_new_statrec.chvals(l_new_idx) := l_sta_rec.srec.chvals(i);
      END IF;
    END LOOP;

    IF p_end_point IN (1, l_sta_rec.srec.epc) THEN -- min or max have changed
      get_min_and_max ( -- recompute new min and max
        p_data_type => l_sta_rec.data_type,
        p_statrec   => l_new_statrec,
        x_statrec   => l_tmp_statrec );

      IF p_end_point = 1 THEN -- adjust min
        l_new_statrec.minval := l_tmp_statrec.minval;
      ELSIF p_end_point = l_sta_rec.srec.epc THEN -- adjust max
        l_new_statrec.maxval := l_tmp_statrec.maxval;
      END IF;
    END IF;

    set_column_stats (
      p_ownname       => p_ownname,
      p_tabname       => p_tabname,
      p_colname       => p_colname,
      p_partname      => p_partname,
      p_distcnt       => l_sta_rec.distcnt,
      p_density       => l_sta_rec.density,
      p_nullcnt       => l_sta_rec.nullcnt,
      p_srec          => l_new_statrec,
      p_avgclen       => l_sta_rec.avgclen,
      p_no_invalidate => p_no_invalidate,
      p_force         => p_force );
  END delete_hgrm_bucket;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_bucket_size
   *
   * ------------------------- */
  PROCEDURE set_bucket_size (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_end_point     IN INTEGER,
    p_new_size      IN INTEGER,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_preserve_size IN BOOLEAN  DEFAULT TRUE, -- of subsequent buckets
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE )
  IS
    l_old_size NUMBER;
    l_sta_rec  sta_rec;

  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_end_point := p_end_point;
    s_partname := NVL(p_partname, 'NULL');
    IF p_preserve_size THEN s_preserve_size := 'TRUE'; ELSE s_preserve_size := 'FALSE'; END IF;
    IF p_no_invalidate THEN s_no_invalidate := 'TRUE'; ELSE s_no_invalidate := 'FALSE'; END IF;
    IF p_force THEN s_force := 'TRUE'; ELSE s_force := 'FALSE'; END IF;

    IF p_new_size < 0 THEN
      put_line('only positive integers');
      RETURN;
    ELSIF p_new_size = 0 THEN
      delete_hgrm_bucket ( -- size 0 means a delete
        p_ownname       => p_ownname,
        p_tabname       => p_tabname,
        p_colname       => p_colname,
        p_end_point     => p_end_point,
        p_partname      => p_partname,
        p_preserve_size => p_preserve_size,
        p_no_invalidate => p_no_invalidate,
        p_force         => p_force );
      RETURN;
    END IF;

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

    IF NVL(l_sta_rec.histogram, 'NONE') NOT IN ('FREQUENCY', 'HEIGHT BALANCED') OR
       (l_sta_rec.histogram = 'FREQUENCY' AND p_end_point NOT BETWEEN 1 AND l_sta_rec.srec.epc) OR
       (l_sta_rec.histogram = 'HEIGHT BALANCED' AND p_end_point NOT BETWEEN 2 AND l_sta_rec.srec.epc) OR
       l_sta_rec.srec.epc IS NULL
    THEN
      put_line('only well formed histograms can be modified, and end_point must be within valid range');
      RETURN;
    END IF;

    IF p_end_point = 1 THEN
      l_old_size := l_sta_rec.srec.bkvals(1);
    ELSE -- p_end_point > 1
      l_old_size := l_sta_rec.srec.bkvals(p_end_point) - l_sta_rec.srec.bkvals(p_end_point - 1);
    END IF;

    IF NOT p_preserve_size AND p_end_point < l_sta_rec.srec.epc AND l_sta_rec.srec.bkvals(p_end_point) + p_new_size - l_old_size >= l_sta_rec.srec.bkvals(p_end_point + 1) THEN
      put_line('new bkvals must not reach bkvals of next bucket');
      RETURN;
    END IF;

    IF l_sta_rec.histogram = 'HEIGHT BALANCED' AND  p_preserve_size AND l_sta_rec.srec.bkvals(l_sta_rec.srec.epc) + p_new_size - l_old_size > 254 THEN
      put_line('total number of buckets ('||(l_sta_rec.srec.bkvals(l_sta_rec.srec.epc) + p_new_size - l_old_size)||') cannot exceed 254');
      RETURN;
    END IF;

    put_line('set_bucket_size:'||p_end_point||' prior:'||l_old_size||' new:'||p_new_size);
    l_sta_rec.srec.bkvals(p_end_point) := l_sta_rec.srec.bkvals(p_end_point) + p_new_size - l_old_size; -- set new value

    IF p_preserve_size AND p_end_point < l_sta_rec.srec.epc THEN
      FOR i IN p_end_point + 1 .. l_sta_rec.srec.epc -- adjust subsequent buckets
      LOOP
        l_sta_rec.srec.bkvals(i) := l_sta_rec.srec.bkvals(i) + p_new_size - l_old_size;
      END LOOP;
    END IF;

    set_column_stats (
      p_ownname       => p_ownname,
      p_tabname       => p_tabname,
      p_colname       => p_colname,
      p_partname      => p_partname,
      p_distcnt       => l_sta_rec.distcnt,
      p_density       => l_sta_rec.density,
      p_nullcnt       => l_sta_rec.nullcnt,
      p_srec          => l_sta_rec.srec,
      p_avgclen       => l_sta_rec.avgclen,
      p_no_invalidate => p_no_invalidate,
      p_force         => p_force );
  END set_bucket_size;

  /*************************************************************************************/

  /* -------------------------
   *
   * public insert_hgrm_bucket
   *
   * ------------------------- */
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
    p_force         IN BOOLEAN  DEFAULT FALSE )
  IS
    l_adj_size    NUMBER;
    l_sta_rec     sta_rec;
    l_new_statrec SYS.DBMS_STATS.STATREC;
    l_tmp_statrec SYS.DBMS_STATS.STATREC;
    l_charvals    SYS.DBMS_STATS.CHARARRAY;
    l_datevals    SYS.DBMS_STATS.DATEARRAY;
    l_numvals     SYS.DBMS_STATS.NUMARRAY;

  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_end_point := p_end_point;
    s_partname := NVL(p_partname, 'NULL');
    IF p_preserve_size THEN s_preserve_size := 'TRUE'; ELSE s_preserve_size := 'FALSE'; END IF;
    IF p_no_invalidate THEN s_no_invalidate := 'TRUE'; ELSE s_no_invalidate := 'FALSE'; END IF;
    IF p_force THEN s_force := 'TRUE'; ELSE s_force := 'FALSE'; END IF;

    IF p_end_point IS NULL OR p_end_point < 0 OR p_bkvals IS NULL OR p_bkvals < 0 THEN
      put_line('only positive integers');
      RETURN;
    END IF;

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

    IF NVL(l_sta_rec.histogram, 'NONE') NOT IN ('FREQUENCY', 'HEIGHT BALANCED') OR
       (l_sta_rec.histogram = 'FREQUENCY' AND p_end_point NOT BETWEEN 1 AND l_sta_rec.srec.epc + 1) OR
       (l_sta_rec.histogram = 'HEIGHT BALANCED' AND p_end_point NOT BETWEEN 2 AND l_sta_rec.srec.epc + 1) OR
       l_sta_rec.srec.epc IS NULL
    THEN
      put_line('only well formed histograms can be modified, and end_point must be within valid range');
      RETURN;
    END IF;

    IF p_preserve_size THEN
      IF p_end_point > 1 THEN
        l_adj_size := p_bkvals - l_sta_rec.srec.bkvals(p_end_point - 1);
      ELSIF p_end_point = 1 THEN
        l_adj_size := p_bkvals;
      ELSE
        l_adj_size := 0;
      END IF;
    ELSE
      l_adj_size := 0;
    END IF;

    IF l_sta_rec.histogram = 'HEIGHT BALANCED' AND  p_preserve_size AND l_sta_rec.srec.bkvals(l_sta_rec.srec.epc) + l_adj_size > 254 THEN
      put_line('total number of buckets ('||(l_sta_rec.srec.bkvals(l_sta_rec.srec.epc) + l_adj_size)||') cannot exceed 254');
      RETURN;
    END IF;

    IF p_end_point < l_sta_rec.srec.epc THEN
      IF NOT p_preserve_size AND p_bkvals > l_sta_rec.srec.bkvals(p_end_point) THEN
        put_line('new bkvals('||p_end_point||'):'||p_bkvals||' cannot be > than current bkvals('||(p_end_point)||'):'||l_sta_rec.srec.bkvals(p_end_point));
        RETURN;
      END IF;
      IF p_novals > l_sta_rec.srec.novals(p_end_point) THEN
        put_line('new novals('||p_end_point||'):'||p_novals||' cannot be > than current novals('||(p_end_point)||'):'||l_sta_rec.srec.novals(p_end_point));
        RETURN;
      END IF;
    END IF;

    IF p_end_point > 1 THEN
      IF p_bkvals < l_sta_rec.srec.bkvals(p_end_point - 1)  THEN
        put_line('new bkvals('||p_end_point||'):'||p_bkvals||' cannot be < than current bkvals('||(p_end_point - 1)||'):'||l_sta_rec.srec.bkvals(p_end_point - 1));
        RETURN;
      END IF;
      IF p_novals < l_sta_rec.srec.novals(p_end_point - 1) THEN
        put_line('new novals('||p_end_point||'):'||p_novals||' cannot be < than current novals('||(p_end_point - 1)||'):'||l_sta_rec.srec.novals(p_end_point - 1));
        RETURN;
      END IF;
    END IF;

    l_new_statrec := l_sta_rec.srec; -- in case this is 11g so eavs does not go uninitialized

    l_new_statrec.epc := l_sta_rec.srec.epc + 1; -- one end point will be inserted
    l_new_statrec.minval := l_sta_rec.srec.minval;
    l_new_statrec.maxval := l_sta_rec.srec.maxval;

    l_new_statrec.bkvals := SYS.DBMS_STATS.NUMARRAY ();
    l_new_statrec.novals := SYS.DBMS_STATS.NUMARRAY ();
    l_new_statrec.chvals := SYS.DBMS_STATS.CHARARRAY ();

    l_new_statrec.bkvals.EXTEND;
    l_new_statrec.novals.EXTEND;
    l_new_statrec.chvals.EXTEND;

    FOR i IN 1 .. l_sta_rec.srec.epc
    LOOP
      l_new_statrec.bkvals.EXTEND;
      l_new_statrec.novals.EXTEND;
      l_new_statrec.chvals.EXTEND;

      IF i < p_end_point THEN -- copy 1
        l_new_statrec.bkvals(i) := l_sta_rec.srec.bkvals(i);
        l_new_statrec.novals(i) := l_sta_rec.srec.novals(i);
        l_new_statrec.chvals(i) := l_sta_rec.srec.chvals(i);
      ELSIF i = p_end_point THEN -- insert 1 and copy 1
        l_new_statrec.bkvals(i) := p_bkvals;
        l_new_statrec.novals(i) := p_novals;
        l_new_statrec.chvals(i) := p_chvals;
        put_line('insert_hgrm_bucket:'||i||' bkvals:'||l_new_statrec.bkvals(i)||' novals:'||l_new_statrec.novals(i)||' chvals:"'||l_new_statrec.chvals(i)||'"');
        l_new_statrec.bkvals(i + 1) := l_sta_rec.srec.bkvals(i) + l_adj_size;
        l_new_statrec.novals(i + 1) := l_sta_rec.srec.novals(i);
        l_new_statrec.chvals(i + 1) := l_sta_rec.srec.chvals(i);
      ELSIF i > p_end_point THEN -- copy 1 adjust size if needed
        l_new_statrec.bkvals(i + 1) := l_sta_rec.srec.bkvals(i) + l_adj_size;
        l_new_statrec.novals(i + 1) := l_sta_rec.srec.novals(i);
        l_new_statrec.chvals(i + 1) := l_sta_rec.srec.chvals(i);
      END IF;
    END LOOP;

    IF p_end_point = l_sta_rec.srec.epc + 1 THEN -- ep to insert is after last bucket in hgrm
      l_new_statrec.bkvals(p_end_point) := p_bkvals;
      l_new_statrec.novals(p_end_point) := p_novals;
      l_new_statrec.chvals(p_end_point) := p_chvals;
      put_line('insert_hgrm_bucket:'||p_end_point||' bkvals:'||l_new_statrec.bkvals(p_end_point)||' novals:'||l_new_statrec.novals(p_end_point)||' chvals:"'||l_new_statrec.chvals(p_end_point)||'"');
    END IF;

    IF p_end_point IN (1, l_sta_rec.srec.epc + 1) THEN -- min or max have changed
      get_min_and_max ( -- recompute new min and max
        p_data_type => l_sta_rec.data_type,
        p_statrec   => l_new_statrec,
        x_statrec   => l_tmp_statrec );

      IF p_end_point = 1 THEN -- adjust min
        l_new_statrec.minval := l_tmp_statrec.minval;
      ELSIF p_end_point = l_sta_rec.srec.epc + 1 THEN -- adjust max
        l_new_statrec.maxval := l_tmp_statrec.maxval;
      END IF;
    END IF;

    l_sta_rec.distcnt := GREATEST(l_sta_rec.distcnt, l_sta_rec.srec.epc + 1);

    set_column_stats (
      p_ownname       => p_ownname,
      p_tabname       => p_tabname,
      p_colname       => p_colname,
      p_partname      => p_partname,
      p_distcnt       => l_sta_rec.distcnt,
      p_density       => l_sta_rec.density,
      p_nullcnt       => l_sta_rec.nullcnt,
      p_srec          => l_new_statrec,
      p_avgclen       => l_sta_rec.avgclen,
      p_no_invalidate => p_no_invalidate,
      p_force         => p_force );
  END insert_hgrm_bucket;

  /*************************************************************************************/

  /* -------------------------
   *
   * public insert_hgrm_bucket
   *
   * ------------------------- */
  PROCEDURE insert_hgrm_bucket (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_value         IN VARCHAR2, -- if date use YYYY/MM/DD HH24:MI:SS
    p_size          IN INTEGER,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_preserve_size IN BOOLEAN  DEFAULT TRUE, -- of subsequent buckets
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE )
  IS
    l_char      VARCHAR2(4000);
    l_date      DATE;
    l_number    NUMBER;
    l_end_point NUMBER;
    l_bkval     NUMBER;
    l_noval     NUMBER;
    l_chval     VARCHAR2(4000);
    l_sta_rec   sta_rec;

  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_end_point := 'UNKNOWN';
    s_partname := NVL(p_partname, 'NULL');
    IF p_preserve_size THEN s_preserve_size := 'TRUE'; ELSE s_preserve_size := 'FALSE'; END IF;
    IF p_no_invalidate THEN s_no_invalidate := 'TRUE'; ELSE s_no_invalidate := 'FALSE'; END IF;
    IF p_force THEN s_force := 'TRUE'; ELSE s_force := 'FALSE'; END IF;

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

    IF NVL(l_sta_rec.histogram, 'NONE') NOT IN ('FREQUENCY', 'HEIGHT BALANCED') OR
       l_sta_rec.srec.epc IS NULL
    THEN
      put_line('only well formed histograms can be modified');
      RETURN;
    END IF;

    BEGIN -- noval
      get_value (
        p_data_type => l_sta_rec.data_type,
        p_value     => p_value,
        x_char      => l_char,
        x_date      => l_date,
        x_number    => l_number,
        x_noval     => l_noval );

      IF l_noval IS NULL THEN
        RETURN;
      END IF;
      put_line('noval:'||l_noval);
    END;

    BEGIN -- chval
      l_chval := NULL;
      IF l_sta_rec.data_type IN ('CHAR', 'VARCHAR2') THEN
        FOR i IN 1 .. l_sta_rec.srec.epc
        LOOP
          IF l_sta_rec.srec.chvals(i) IS NOT NULL OR l_sta_rec.srec.novals(i) = l_noval THEN -- see bug 3333781
            l_chval := p_value;
            IF l_sta_rec.data_type = 'CHAR' AND LENGTH(l_chval) < 15 THEN
              l_chval := RPAD(l_chval, 15);
            END IF;
            EXIT;
          END IF;
        END LOOP;
      END IF;
      put_line('chval:"'||l_chval||'"');
    END;

    BEGIN -- end_point
      l_end_point := NULL;
      FOR i IN 1 .. l_sta_rec.srec.epc
      LOOP
        IF l_sta_rec.srec.novals(i) > l_noval THEN
          l_end_point := i;
          EXIT;
        ELSIF l_sta_rec.srec.novals(i) = l_noval THEN
          IF l_sta_rec.srec.chvals(i) > l_chval THEN
            l_end_point := i;
            EXIT;
          ELSIF l_sta_rec.srec.chvals(i) = l_chval OR l_sta_rec.srec.chvals(i) IS NULL OR l_chval IS NULL THEN
            put_line('duplicate value');
            RETURN;
          END IF;
        END IF;
      END LOOP;
      IF l_end_point IS NULL THEN
        l_end_point := l_sta_rec.srec.epc + 1; -- not found
      END IF;
      put_line('end_point:'||l_end_point);
    END;

    BEGIN -- bkval
      IF l_end_point = 1 THEN
        l_bkval := p_size;
      ELSE
        l_bkval := p_size + l_sta_rec.srec.bkvals(l_end_point - 1);
      END IF;
      put_line('bkval:'||l_bkval);
    END;

    insert_hgrm_bucket (
      p_ownname       => p_ownname,
      p_tabname       => p_tabname,
      p_colname       => p_colname,
      p_end_point     => l_end_point,
      p_bkvals        => l_bkval,
      p_novals        => l_noval,
      p_chvals        => l_chval,
      p_partname      => p_partname,
      p_preserve_size => p_preserve_size,
      p_no_invalidate => p_no_invalidate,
      p_force         => p_force );
  END insert_hgrm_bucket;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_min_max_values
   *
   * ------------------------- */
  PROCEDURE set_min_max_values (
    p_ownname       IN VARCHAR2,
    p_tabname       IN VARCHAR2,
    p_colname       IN VARCHAR2,
    p_new_min_value IN VARCHAR2,
    p_new_max_value IN VARCHAR2,
    p_partname      IN VARCHAR2 DEFAULT NULL,
    p_no_invalidate IN BOOLEAN  DEFAULT FALSE,
    p_force         IN BOOLEAN  DEFAULT FALSE )
  IS
    l_char_min    VARCHAR2(4000);
    l_date_min    DATE;
    l_number_min  NUMBER;
    l_noval_min   NUMBER;
    l_char_max    VARCHAR2(4000);
    l_date_max    DATE;
    l_number_max  NUMBER;
    l_noval_max   NUMBER;
    l_sta_rec     sta_rec;
    l_new_statrec SYS.DBMS_STATS.STATREC;
    l_charvals SYS.DBMS_STATS.CHARARRAY;
    l_datevals SYS.DBMS_STATS.DATEARRAY;
    l_numvals  SYS.DBMS_STATS.NUMARRAY;

  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_end_point := 'UNKNOWN';
    s_partname := NVL(p_partname, 'NULL');
    IF p_no_invalidate THEN s_no_invalidate := 'TRUE'; ELSE s_no_invalidate := 'FALSE'; END IF;
    IF p_force THEN s_force := 'TRUE'; ELSE s_force := 'FALSE'; END IF;

    IF p_new_min_value IS NULL AND p_new_max_value IS NULL THEN
      RETURN;
    END IF;

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

    IF l_sta_rec.srec.epc IS NULL THEN
      put_line('column has no statistics at all');
      RETURN;
    END IF;

    IF p_new_min_value IS NOT NULL THEN
      get_value (
        p_data_type => l_sta_rec.data_type,
        p_value     => p_new_min_value,
        x_char      => l_char_min,
        x_date      => l_date_min,
        x_number    => l_number_min,
        x_noval     => l_noval_min );
    END IF;

    IF p_new_max_value IS NOT NULL THEN
      get_value (
        p_data_type => l_sta_rec.data_type,
        p_value     => p_new_max_value,
        x_char      => l_char_max,
        x_date      => l_date_max,
        x_number    => l_number_max,
        x_noval     => l_noval_max );
    END IF;

    l_new_statrec := NULL;
    l_new_statrec.epc := 2;

    IF l_sta_rec.data_type IN ('CHAR', 'VARCHAR2') THEN
      l_charvals := SYS.DBMS_STATS.CHARARRAY ();
      l_charvals.EXTEND(2);
      l_charvals(1) := NVL(l_char_min, NVL(l_sta_rec.srec.chvals(1), get_external_value(l_sta_rec.srec.novals(1)))); -- min
      l_charvals(2) := NVL(l_char_max, NVL(l_sta_rec.srec.chvals(l_sta_rec.srec.epc), get_external_value(l_sta_rec.srec.novals(l_sta_rec.srec.epc)))); -- max
      IF l_sta_rec.data_type = 'CHAR' AND LENGTH(l_charvals(1)) < 15 THEN
        l_charvals(1) := RPAD(l_charvals(1), 15);
      END IF;
      IF l_sta_rec.data_type = 'CHAR' AND LENGTH(l_charvals(2)) < 15 THEN
        l_charvals(2) := RPAD(l_charvals(2), 15);
      END IF;
      SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => l_new_statrec, charvals => l_charvals);
    ELSIF l_sta_rec.data_type = 'NUMBER' THEN
      l_numvals := SYS.DBMS_STATS.NUMARRAY ();
      l_numvals.EXTEND(2);
      l_numvals(1) := NVL(l_number_min, l_sta_rec.srec.novals(1)); -- min
      l_numvals(2) := NVL(l_number_max, l_sta_rec.srec.novals(l_sta_rec.srec.epc)); -- max
      SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => l_new_statrec, numvals => l_numvals);
    ELSIF SUBSTR(l_sta_rec.data_type, 1, 8) IN ('DATE', 'TIMESTAM') THEN
      l_datevals := SYS.DBMS_STATS.DATEARRAY ();
      l_datevals.EXTEND(2);
      l_datevals(1) := NVL(l_date_min, TO_DATE(TO_CHAR(TRUNC(l_sta_rec.srec.novals(1))), 'J') + (l_sta_rec.srec.novals(1) - TRUNC(l_sta_rec.srec.novals(1))));
      l_datevals(2) := NVL(l_date_max, TO_DATE(TO_CHAR(TRUNC(l_sta_rec.srec.novals(l_sta_rec.srec.epc))), 'J') + (l_sta_rec.srec.novals(l_sta_rec.srec.epc) - TRUNC(l_sta_rec.srec.novals(l_sta_rec.srec.epc))));
      SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => l_new_statrec, datevals => l_datevals);
    ELSE
      put_line('invalid data_type:"'||l_sta_rec.data_type||'"');
    END IF;

    IF p_new_min_value IS NOT NULL THEN
      IF (l_new_statrec.novals(1) > l_sta_rec.srec.novals(2)) OR
         (l_new_statrec.novals(1) = l_sta_rec.srec.novals(2) AND
         (l_new_statrec.chvals(1) > l_sta_rec.srec.chvals(2) OR l_new_statrec.chvals(1) IS NULL OR l_sta_rec.srec.chvals(2) IS NULL))
      THEN
        put_line('new_min_value:"'||p_new_min_value||'" cannot be greater or equal than value on subsequent bucket');
        RETURN;
      END IF;
      l_sta_rec.srec.minval := l_new_statrec.minval;
      l_sta_rec.srec.novals(1) := l_new_statrec.novals(1); -- same as l_noval_min

      IF l_sta_rec.srec.chvals.COUNT > 0 THEN
        l_sta_rec.srec.chvals(1) := l_new_statrec.chvals(1); -- same as l_char_min
        put_line('minval:"'||p_new_min_value||'"('||l_sta_rec.srec.minval||') '||l_sta_rec.srec.novals(1)||' '||l_sta_rec.srec.chvals(1));
      ELSE
        put_line('minval:"'||p_new_min_value||'"('||l_sta_rec.srec.minval||') '||l_sta_rec.srec.novals(1));
      END IF;
    END IF;

    IF p_new_max_value IS NOT NULL THEN
      IF (l_new_statrec.novals(2) < l_sta_rec.srec.novals(l_sta_rec.srec.epc - 1)) OR
         (l_new_statrec.novals(2) = l_sta_rec.srec.novals(l_sta_rec.srec.epc - 1) AND
         (l_new_statrec.chvals(2) < l_sta_rec.srec.chvals(l_sta_rec.srec.epc - 1) OR l_new_statrec.chvals(2) IS NULL OR l_sta_rec.srec.chvals(l_sta_rec.srec.epc - 1) IS NULL))
      THEN
        put_line('new_max_value:"'||p_new_max_value||'" cannot be smaller or equal than value on prior bucket');
        RETURN;
      END IF;
      l_sta_rec.srec.maxval := l_new_statrec.maxval;
      l_sta_rec.srec.novals(l_sta_rec.srec.epc) := l_new_statrec.novals(2); -- same as l_noval_max

      IF l_sta_rec.srec.chvals.COUNT > 0 THEN
        l_sta_rec.srec.chvals(l_sta_rec.srec.epc) := l_new_statrec.chvals(2); -- same as l_char_max
        put_line('maxval:"'||p_new_max_value||'"('||l_sta_rec.srec.maxval||') '||l_sta_rec.srec.novals(l_sta_rec.srec.epc)||' '||l_sta_rec.srec.chvals(l_sta_rec.srec.epc));
      ELSE
        put_line('maxval:"'||p_new_max_value||'"('||l_sta_rec.srec.maxval||') '||l_sta_rec.srec.novals(l_sta_rec.srec.epc));
      END IF;
    END IF;

    set_column_stats (
      p_ownname       => p_ownname,
      p_tabname       => p_tabname,
      p_colname       => p_colname,
      p_partname      => p_partname,
      p_distcnt       => l_sta_rec.distcnt,
      p_density       => l_sta_rec.density,
      p_nullcnt       => l_sta_rec.nullcnt,
      p_srec          => l_sta_rec.srec,
      p_avgclen       => l_sta_rec.avgclen,
      p_no_invalidate => p_no_invalidate,
      p_force         => p_force );
  END set_min_max_values;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_column_hgrm
   *
   * ------------------------- */
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
    p_force         IN BOOLEAN  DEFAULT FALSE )
  IS
    l_sta_rec     sta_rec;
    l_new_statrec SYS.DBMS_STATS.STATREC;
    l_charvals    SYS.DBMS_STATS.CHARARRAY;
    l_datevals    SYS.DBMS_STATS.DATEARRAY;
    l_numvals     SYS.DBMS_STATS.NUMARRAY;
    l_num_rows    NUMBER;

    /***********************************************************************************/

    PROCEDURE populate_array (
      p2_value IN VARCHAR2,
      p2_size  IN INTEGER )
    IS
      l2_noval NUMBER;
    BEGIN
      IF p2_value IS NOT NULL THEN
        l_new_statrec.epc := l_new_statrec.epc + 1;
        l_new_statrec.bkvals.EXTEND;
        l_charvals.EXTEND;
        l_datevals.EXTEND;
        l_numvals.EXTEND;
        l_new_statrec.bkvals(l_new_statrec.epc) := NVL(p2_size, 1);
        l_num_rows := l_num_rows + NVL(p2_size, 1);

        get_value (
          p_data_type => l_sta_rec.data_type,
          p_value     => p2_value,
          x_char      => l_charvals(l_new_statrec.epc),
          x_date      => l_datevals(l_new_statrec.epc),
          x_number    => l_numvals(l_new_statrec.epc),
          x_noval     => l2_noval );

        put_line('populate_array:'||l_new_statrec.epc||' bkvals:'||l_num_rows||' novals:'||l2_noval||' chvals:"'||p2_value||'" size:'||p2_size);
      END IF;
    END populate_array;

    /***********************************************************************************/

  BEGIN
    s_ownname := p_ownname;
    s_tabname := p_tabname;
    s_colname := p_colname;
    s_end_point := 'UNKNOWN';
    s_partname := NVL(p_partname, 'NULL');
    IF p_no_invalidate THEN s_no_invalidate := 'TRUE'; ELSE s_no_invalidate := 'FALSE'; END IF;
    IF p_force THEN s_force := 'TRUE'; ELSE s_force := 'FALSE'; END IF;

    l_sta_rec := get_sta_rec(p_ownname => p_ownname, p_tabname => p_tabname, p_colname => p_colname, p_partname => p_partname);

    IF l_sta_rec.srec.epc IS NULL THEN
      put_line('column has no statistics');
      RETURN;
    END IF;

    l_new_statrec := NULL;
    l_new_statrec.epc := 0;
    l_new_statrec.bkvals := SYS.DBMS_STATS.NUMARRAY ();
    l_charvals := SYS.DBMS_STATS.CHARARRAY ();
    l_numvals := SYS.DBMS_STATS.NUMARRAY ();
    l_datevals := SYS.DBMS_STATS.DATEARRAY ();
    l_num_rows := 0;

    populate_array(p_value_1, p_size_1);
    populate_array(p_value_2, p_size_2);
    populate_array(p_value_3, p_size_3);
    populate_array(p_value_4, p_size_4);
    populate_array(p_value_5, p_size_5);

    IF l_sta_rec.data_type IN ('CHAR', 'VARCHAR2') THEN
      SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => l_new_statrec, charvals => l_charvals);
    ELSIF l_sta_rec.data_type = 'NUMBER' THEN
      SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => l_new_statrec, numvals => l_numvals);
    ELSIF SUBSTR(l_sta_rec.data_type, 1, 8) IN ('DATE', 'TIMESTAM') THEN
      SYS.DBMS_STATS.PREPARE_COLUMN_VALUES(srec => l_new_statrec, datevals => l_datevals);
    ELSE
      put_line('invalid data_type:"'||l_sta_rec.data_type||'"');
    END IF;

    l_sta_rec.distcnt := GREATEST(NVL(l_sta_rec.distcnt, l_new_statrec.epc), l_new_statrec.epc);
    l_sta_rec.density := NVL(l_sta_rec.density, NVL(l_sta_rec.distcnt, l_new_statrec.epc) / GREATEST(NVL(l_sta_rec.num_rows, l_num_rows), 1));
    l_sta_rec.nullcnt := NVL(l_sta_rec.nullcnt, 0);
    l_sta_rec.avgclen := NVL(l_sta_rec.avgclen, 10);

    put_line('distcnt:'||l_sta_rec.distcnt);
    put_line('density:'||TRIM(LOWER(TO_CHAR(l_sta_rec.density, SCIENTIFIC_NOTATION))));
    put_line('nullcnt:'||l_sta_rec.nullcnt);
    put_line('avgclen:'||l_sta_rec.avgclen);
    put_line('minval:"'||convert_raw_value(l_new_statrec.minval, l_sta_rec.data_type)||'"('||l_new_statrec.minval||')');
    put_line('maxval:"'||convert_raw_value(l_new_statrec.maxval, l_sta_rec.data_type)||'"('||l_new_statrec.maxval||')');
    put_line('epc:'||l_new_statrec.epc);

    set_column_stats (
      p_ownname       => p_ownname,
      p_tabname       => p_tabname,
      p_colname       => p_colname,
      p_partname      => p_partname,
      p_distcnt       => l_sta_rec.distcnt,
      p_density       => l_sta_rec.density,
      p_nullcnt       => l_sta_rec.nullcnt,
      p_srec          => l_new_statrec,
      p_avgclen       => l_sta_rec.avgclen,
      p_no_invalidate => p_no_invalidate,
      p_force         => p_force );
  END set_column_hgrm;

  /*************************************************************************************/

END sqlt$s;
/

SET TERM ON;
SHOW ERRORS PACKAGE BODY &&tool_administer_schema..sqlt$s;
