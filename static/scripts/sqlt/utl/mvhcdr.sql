SPO mvhcdr.log
SET DEF ON;
SET DEF ^ TERM OFF ECHO ON VER OFF SERVEROUT ON SIZE UNL;
REM
REM $Header: 1517362.1 mvhcdr.sql 11.4.5.11 2013/08/19 carlos.sierra $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   mvhcdr.sql
REM   Materialized Views Health Check and Diagnostics Reports
REM
REM DESCRIPTION
REM   Performs some Health Checks (HC) on Materialized Views (MV)
REM   and Produces a set of Diagnostics Reports (DR) on them.
REM
REM   This script does not install any objects in the database.
REM   It does not perform any DDL commands.
REM   It can be used in Dataguard or any read-only database.
REM
REM PRE-REQUISITES
REM   1. Create PLAN_TABLE with one of these two scripts:
REM      $ORACLE_HOME/rdbms/admin/catplan.sql; (preferred) OR
REM      $ORACLE_HOME/rdbms/admin/utlxplan.sql;
REM   2. Create MV_CAPABILITIES_TABLE with this script:
REM      $ORACLE_HOME/rdbms/admin/utlxmv.sql;
REM   3. Execute mvhcdr.sql as SYS or user with DBA role or user
REM      with access to data dictionary views.
REM
REM PARAMETERS
REM   1. Materialized View name or prefix (optional, defaults to %)
REM
REM EXECUTION
REM   1. Start SQL*Plus connecting as SYS or user with DBA role or
REM      user with access to data dictionary views.
REM   2. Execute script mvhcdr.sql passing values for parameters.
REM
REM EXAMPLE
REM   # sqlplus / as sysdba
REM   SQL> START [path]mvhcdr.sql [mv_name|%]
REM   SQL> START mvhcdr.sql DDR_R_BASE_DAY_DN_MV  <<< one MV
REM   SQL> START mvhcdr.sql DDR%   <<< all MVs with prefix DDR
REM   SQL> START mvhcdr.sql %   <<< all MVs
REM
REM NOTES
REM   1. For possible errors see mvhcdr.log.
REM   2. If a MV prefix is passed then it selects all MVs
REM      with such prefix. Example: BOM%
REM
DEF script = 'mvhcdr';
DEF module = 'MVHCDR';
DEF mos_doc = '1517362.1';
DEF doc_ver = '11.4.5.4';
DEF doc_date = '2013/02/04';
DEF input_include_count = 'Y';
DEF input_output_type = 'B';

/**************************************************************************************************/

SET TERM ON ECHO OFF;

WHENEVER SQLERROR EXIT SQL.SQLCODE;
COL no_print NOPRI;

PRO
PRO validating PLAN_TABLE can be used.
PRO If validation fails then execute first:
PRO @$ORACLE_HOME/rdbms/admin/catplan.sql;;

SELECT COUNT(*) no_print FROM plan_table;

PRO validating MV_CAPABILITIES_TABLE can be used.
PRO If validation fails then execute first:
PRO @$ORACLE_HOME/rdbms/admin/utlxmv.sql;;

SELECT COUNT(*) no_print FROM mv_capabilities_table;

WHENEVER SQLERROR CONTINUE;

PRO Parameter 1:
PRO Materialized View name or prefix (optional)
PRO
DEF input_mv_prefix = '^1';
PRO
SET TERM OFF;

COL mv_prefix NEW_V mv_prefix FOR A32;
SELECT 'mv_prefix: ' x, TRIM(TRAILING '%' FROM UPPER(SUBSTR(TRIM('^^input_mv_prefix.'), 1, 30)))||'%' mv_prefix FROM DUAL;
VAR mv_prefix VARCHAR2(32);
EXEC :mv_prefix := '^^mv_prefix.';

--SET TERM ON;
--PRO
--PRO Parameter 2:
--PRO Include MV and LOGs COUNT (Yes or No) [Y|N] (required)
--PRO
--DEF input_include_count = '^2';
--PRO
--SET TERM OFF;

COL include_count NEW_V include_count FOR A1;
SELECT 'include_count: ' x, NVL(UPPER(SUBSTR(TRIM('^^input_include_count.'), 1, 1)), 'Y') include_count FROM DUAL;
VAR include_count CHAR(1);
EXEC :include_count := UPPER(SUBSTR('^^include_count.', 1, 1));

SET TERM ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

BEGIN
  IF '^^include_count.' IS NULL OR '^^include_count.' NOT IN ('Y', 'N') THEN
    RAISE_APPLICATION_ERROR(-20100, 'Include MV and LOGs COUNT (Yes or No) must be specified as "Y" or "N".');
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE;

--SET TERM ON;
--PRO
--PRO Parameter 3:
--PRO Output Type (HTML or CSV or Both) [H|C|B] (required)
--PRO
--DEF input_output_type = '^3';
--PRO
--SET TERM OFF;

COL output_type NEW_V output_type FOR A1;
SELECT 'output_type: ' x, NVL(UPPER(SUBSTR(TRIM('^^input_output_type.'), 1, 1)), 'B') output_type FROM DUAL;
VAR output_type CHAR(1);
EXEC :output_type := UPPER(SUBSTR('^^output_type.', 1, 1));

SET TERM ON;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

BEGIN
  IF '^^output_type.' IS NULL OR '^^output_type.' NOT IN ('H', 'C', 'B', 'N') THEN
    RAISE_APPLICATION_ERROR(-20110, 'Output Type (HTML or CSV or Both) must be specified as "H" or "C" or "B".');
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE;

PRO
PRO Values passed:
PRO ~~~~~~~~~~~~~
PRO MV name  : "^^input_mv_prefix."
PRO LOG COUNT: "^^input_include_count."
PRO Output   : "^^input_output_type."
PRO
PRO ... please wait ... (may take several minutes)
PRO

/**************************************************************************************************/

SET TERM OFF;

-- get current time
COL current_time NEW_V current_time FOR A15;
SELECT 'current_time: ' x, TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') current_time FROM DUAL;

-- get dbid
COL dbid NEW_V dbid;
SELECT 'dbid: ' x, dbid FROM v$database;

-- get dbname
COL dbname NEW_V dbname FOR A9;
SELECT 'dbname: ' x, SUBSTR((SUBSTR(name, 1, INSTR(name||'.', '.') - 1)), 1, 9) dbname FROM v$database;
SELECT 'dbname: ' x, TRANSLATE('^^dbname.',
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ''`~!@#$%^*()-_=+[]{}\|;:",.<>/?'||CHR(0)||CHR(9)||CHR(10)||CHR(13)||CHR(38),
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789') dbname FROM DUAL;

-- get file names prefix
COL prefix NEW_V prefix FOR A256;
SELECT 'prefix: ' x, '^^script._^^dbname._^^current_time.' prefix FROM DUAL;

-- get statement_id
COL statement_id NEW_V statement_id FOR A30 NOPRI;
SELECT 'statement_id: ' x, '^^script._^^current_time.' statement_id FROM DUAL;

-- set module, action and client info
EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^module. ^^doc_ver.', action_name => '^^script..sql');
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(client_info => '^^module.');

-- tracing script in case it takes long to execute so we can diagnose it
ALTER SESSION SET MAX_DUMP_FILE_SIZE = '1G';
ALTER SESSION SET TRACEFILE_IDENTIFIER = "^^prefix.";
--ALTER SESSION SET STATISTICS_LEVEL = 'ALL';
ALTER SESSION SET EVENTS '10046 TRACE NAME CONTEXT FOREVER, LEVEL 12';
SELECT 'BEGIN SCRIPT GENERATION: '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS') FROM dual;

/**************************************************************************************************/

-- produce driver script
SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NUM 20 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF SERVEROUT ON SIZE UNL;

SPO ^^prefix._driver.sql;
PRO REM $Header: ^^mos_doc. ^^prefix._driver.sql ^^doc_ver. ^^doc_date. carlos.sierra $
PRO REM created by ^^script..sql
SET DEF ON;
DEF subst_var = '^';
PRO SET DEF ON;;
PRO SET DEF ^ TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NUM 20 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF SERVEROUT ON SIZE UNL;;
SET DEF ^;
PRO ALTER SESSION SET nls_numeric_characters = ".,";;
PRO ALTER SESSION SET nls_date_format = 'YYYY-MM-DD/HH24:MI:SS';;
PRO ALTER SESSION SET nls_timestamp_format = 'YYYY-MM-DD/HH24:MI:SS.FF';;
PRO ALTER SESSION SET nls_timestamp_tz_format = 'YYYY-MM-DD/HH24:MI:SS.FF TZH:TZM';;
--PRO CL BRE COL;;
PRO COL last_analyzed FOR A20;;
PRO -- YYYY-MM-DD/HH24:MI:SS
PRO COL time_stamp1 NEW_V time_stamp1 FOR A20;;
PRO /*********************************************************************************/

DECLARE
  l_sq_01 VARCHAR2(32767);
  l_sq_02 VARCHAR2(32767);
  l_sq_03 VARCHAR2(32767);
  l_sq_04 VARCHAR2(32767);
  l_sq_05 VARCHAR2(32767);

  PROCEDURE put_line (p_line IN VARCHAR2)
  IS
    l2_pos INTEGER := 1;
  BEGIN
    WHILE l2_pos < LENGTH(p_line)
    LOOP
      DBMS_OUTPUT.PUT_LINE(SUBSTR(p_line, l2_pos, LEAST(2000, LENGTH(p_line) - l2_pos + 1)));
      l2_pos := l2_pos + 2000;
    END LOOP;
  END put_line;

  PROCEDURE put_header (
    p_prefix      IN VARCHAR2,
    p_table_name  IN VARCHAR2,
    p_file_suffix IN VARCHAR2 DEFAULT NULL )
  IS
  BEGIN
    put_line('PRO <html>');
    put_line('PRO <!-- $Header: ^^mos_doc. ^^script..sql ^^doc_ver. ^^doc_date. carlos.sierra $ -->;');
    put_line('PRO <!-- Copyright (c) 2000-2013, Oracle Corporation. All rights reserved. -->;');
    put_line('PRO <!-- Author: carlos.sierra@oracle.com -->;');
    put_line('PRO');
    put_line('PRO <head>');
    put_line('PRO <title>'||p_prefix||'_'||p_table_name||p_file_suffix||'.html</title>');
    put_line('PRO');
    put_line('PRO <style type="text/css">');
    put_line('PRO body {font:10pt Arial,Helvetica,Verdana,Geneva,sans-serif; color:black; background:white;}');
    --put_line('PRO a {font-weight:bold; color:#663300;}');
    --put_line('PRO pre {font:8pt Monaco,"Courier New",Courier,monospace;} /* for code */');
    put_line('PRO h1 {font-size:16pt; font-weight:bold; color:#336699;}');
    put_line('PRO h2 {font-size:14pt; font-weight:bold; color:#336699;}');
    --put_line('PRO h3 {font-size:12pt; font-weight:bold; color:#336699;}');
    --put_line('PRO li {font-size:10pt; font-weight:bold; color:#336699; padding:0.1em 0 0 0;}');
    put_line('PRO table {font-size:8pt; color:black; background:white;}');
    put_line('PRO th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}');
    put_line('PRO td {text-align:left; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}');
    --put_line('PRO td.c {text-align:center;} /* center */');
    --put_line('PRO td.l {text-align:left;} /* left (default) */');
    --put_line('PRO td.r {text-align:right;} /* right */');
    --put_line('PRO font.n {font-size:8pt; font-style:italic; color:#336699;} /* table footnote in blue */');
    put_line('PRO font.f {font-size:8pt; color:#999999;} /* footnote in gray */');
    put_line('PRO </style>');
    put_line('PRO');
    put_line('PRO </head>');
    put_line('PRO <body>');
    put_line('PRO <h1>^^mos_doc. ^^module. ^^doc_ver. '||p_table_name||' '||p_file_suffix||'</h1>');
    put_line('PRO');
  END put_header;

  PROCEDURE put_footer
  IS
  BEGIN
    put_line('PRO');
    put_line('SELECT ''<!-- ''||TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'')||'' -->'' FROM dual;');
    put_line('PRO <hr size="3">');
    put_line('PRO <font class="f">^^mos_doc. ^^module. ^^doc_ver. ^^subst_var.^^subst_var.time_stamp1.</font>');
    put_line('PRO </body>');
    put_line('PRO </html>');
  END put_footer;

  FUNCTION get_order_by(p_table_name IN VARCHAR2)
  RETURN VARCHAR2
  IS
    l2_count INTEGER := 0;
    l2_order_by VARCHAR2(32767) := NULL;
  BEGIN
    FOR i IN (SELECT column_name
                FROM dba_tab_columns
               WHERE owner = 'SYS'
                 AND table_name = REPLACE(p_table_name, 'GV$', 'GV_$')
                 AND data_type NOT IN ('CLOB', 'LONG', 'BLOB') -- cannot SORT on these!
               ORDER BY
                     column_id)
    LOOP
      l2_count := l2_count + 1;
      IF l2_count = 1 THEN
        l2_order_by := ' ORDER BY '||i.column_name;
      ELSE
        l2_order_by := l2_order_by||', '||i.column_name;
      END IF;
    END LOOP;
    RETURN l2_order_by;
  END get_order_by;

  PROCEDURE describe_table(p_table_name IN VARCHAR2)
  IS
    l_tab_comments VARCHAR2(32767);
  BEGIN
    BEGIN
      SELECT comments INTO l_tab_comments FROM dba_tab_comments WHERE owner = 'SYS' AND table_name = p_table_name AND table_type = 'VIEW';
    EXCEPTION
      WHEN OTHERS THEN
        l_tab_comments := NULL;
    END;
    put_line('PRO '||p_table_name||'. '||l_tab_comments);

    put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" ENTMAP OFF SPOOL OFF;');
    put_line('SELECT col.column_id "#",');
    put_line('       ''<pre>''||col.column_name||''</pre>'' "Name",');
    put_line('       ''<pre>''||DECODE(nullable, ''N'', ''NOT NULL'')||''</pre>'' "Null?",');
    put_line('       ''<pre>''||col.data_type||(CASE WHEN data_type LIKE ''%CHAR%'' THEN ''(''||data_length||'')'' END)||''</pre>'' "Type",');
    put_line('       ''<pre>''||REPLACE(REPLACE(REPLACE(com.comments, ''>'', CHR(38)||''GT;''), ''<'', CHR(38)||''LT;''), CHR(10), ''<br>'')||''</pre>'' "Comments"');
    put_line('  FROM dba_tab_columns col,');
    put_line('       dba_col_comments com');
    put_line(' WHERE col.owner = ''SYS''');
    put_line('   AND col.table_name = '''||p_table_name||'''');
    put_line('   AND com.owner(+) = col.owner');
    put_line('   AND com.table_name(+) = col.table_name');
    put_line('   AND com.column_name(+) = col.column_name');
    put_line(' ORDER BY col.column_id;');
    put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');
  END describe_table;

  PROCEDURE put_view (
    p_table_name  IN VARCHAR2,
    p_predicate   IN VARCHAR2 DEFAULT NULL,
    p_file_suffix IN VARCHAR2 DEFAULT NULL )
  IS
    l2_file_name VARCHAR2(32767) := REPLACE(p_table_name, '$', 's')||p_file_suffix;
    l2_predicate VARCHAR2(32767) := p_predicate;
    l2_predicate_rownum VARCHAR2(32767);
    l2_order_by VARCHAR2(32767);
    l2_cnt NUMBER := NULL;
    l2_sql VARCHAR2(32767);
  BEGIN
    put_line('-- process view: "'||p_table_name||'". predicate: "'||p_predicate||'". suffix:"'||p_file_suffix||'".');
    IF p_predicate IS NOT NULL THEN
      l2_predicate := ' WHERE '||p_predicate||' ';
      l2_predicate_rownum := l2_predicate||' AND ROWNUM = 1 ';
    ELSE
      l2_predicate_rownum := ' WHERE ROWNUM = 1 ';
    END IF;

    BEGIN
      DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => 'VIEW '||p_table_name);
      DBMS_APPLICATION_INFO.SET_CLIENT_INFO(p_table_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
      l2_sql := 'SELECT COUNT(*) FROM '||p_table_name||' v '||l2_predicate_rownum;
      put_line('-- '||l2_sql);
      EXECUTE IMMEDIATE l2_sql INTO l2_cnt;
      DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);
      DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);
    EXCEPTION
      WHEN OTHERS THEN
        put_line('-- skip: '||p_table_name||p_file_suffix||'. reason: '||SQLERRM);
    END;

    IF l2_cnt > 0 THEN
      l2_order_by := get_order_by(p_table_name);
      put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
      put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => ''VIEW '||p_table_name||''');');
      put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||p_table_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

      put_line('-- select: '||p_table_name||p_file_suffix||'. count(*): '||l2_cnt);
      put_line('SET TERM ON;');
      put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||p_table_name||';');
      put_line('SET TERM OFF;');

      -- html
      IF :output_type IN ('H', 'B') THEN
        put_line('SPO ^^prefix._'||l2_file_name||'.html;');
        put_header('^^prefix.', p_table_name, p_file_suffix);
        describe_table(p_table_name);
        put_line('PRO MV Name prefix filter used (when applicable): <pre>''^^mv_prefix.''</pre>');
        put_line('PRO Filter Predicate on '||p_table_name||': <pre>'||NVL(l2_predicate, 'NO FILTER PREDICATE WAS APPLIED')||'</pre>');
        put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
        put_line('SELECT ROWNUM "#", v2.* FROM (SELECT /*+ NO_MERGE */ * FROM '||p_table_name||' v '||l2_predicate||l2_order_by||') v2;');
        put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');
        put_footer;
        put_line('SPO OFF;');
        put_line('HOS zip -m ^^prefix._html ^^prefix._'||l2_file_name||'.html');
      ELSE
        put_line('-- skip html. output_type: '||:output_type);
      END IF;

      -- csv
      IF :output_type IN ('C', 'B') THEN
        put_line('SPO ^^prefix._'||l2_file_name||'.csv;');
        put_line('SET HEA ON PAGES 50000 LIN 32767 LONGC 4000 COLSEP '','';');
        put_line('SELECT v.* FROM '||p_table_name||' v '||l2_predicate||l2_order_by||';');
        put_line('SET HEA OFF PAGES 0 LIN 2000 LONGC 2000 COLSEP '' '';');
        put_line('SPO OFF;');
        put_line('HOS zip -m ^^prefix._csv ^^prefix._'||l2_file_name||'.csv');
      ELSE
        put_line('-- skip csv. output_type: '||:output_type);
      END IF;

      put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);');
      put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);');
      put_line('/*********************************************************************************/');
    ELSE
        put_line('-- skip: '||p_table_name||p_file_suffix||'. count: "'||l2_cnt||'"');
    END IF;
  END put_view;

BEGIN
  IF :output_type IN ('H', 'C', 'B') THEN

    -- reports logs per materialized view and materialized views per log
    BEGIN
      -- report logs per materialized view
      DECLARE
        l2_file_name VARCHAR2(60) := 'LOGS_PER_MATERIALIZED_VIEW';

        PROCEDURE put_sql
        IS
        BEGIN
          put_line('SELECT ROWNUM "#", v.* FROM (');
          put_line('SELECT /*+ NO_MERGE */ ');
          put_line('       s.owner, ');
          put_line('       s.name mview_name, ');
          put_line('       c.object_node mv_degree, ');
          put_line('       c.timestamp mv_last_analyzed, ');
          put_line('       c.remarks mv_stattype_locked, ');
          put_line('       c.other_tag mv_stale_stats, ');
          put_line('       c.cardinality mv_num_rows, ');
          put_line('       c.cost mv_count, ');
          put_line('       c.bytes mv_segment_blocks, ');
          put_line('       s.snapshot_site, ');
          put_line('       s.snapshot_id, ');
          put_line('       l.log_owner, ');
          put_line('       l.master, ');
          put_line('       cm.object_node m_degree, ');
          put_line('       cm.timestamp m_last_analyzed, ');
          put_line('       cm.remarks m_stattype_locked, ');
          put_line('       cm.other_tag m_stale_stats, ');
          put_line('       cm.cardinality m_num_rows, ');
          put_line('       cm.cost m_count, ');
          put_line('       cm.bytes m_segment_blocks, ');
          put_line('       l.log_table, ');
          put_line('       cl.object_node l_degree, ');
          put_line('       cl.timestamp l_last_analyzed, ');
          put_line('       cl.remarks l_stattype_locked, ');
          put_line('       cl.other_tag l_stale_stats, ');
          put_line('       cl.cardinality l_num_rows, ');
          put_line('       cl.cost l_count, ');
          put_line('       cr.cost l_count_after_refresh, ');
          put_line('       cl.bytes l_segment_blocks, ');
          put_line('       l.current_snapshots ');
          put_line('  FROM dba_registered_snapshots s, ');
          put_line('       dba_snapshot_logs l, ');
          put_line('       plan_table c, ');
          put_line('       plan_table cm, ');
          put_line('       plan_table cl, ');
          put_line('       plan_table cr ');
          put_line(' WHERE s.name LIKE ''^^mv_prefix.'' ');
          put_line('   AND l.snapshot_id(+) = s.snapshot_id ');
          put_line('   AND c.statement_id(+) = ''^^statement_id.'' ');
          put_line('   AND c.object_type(+) = ''MATERIALIZED VIEW'' ');
          put_line('   AND c.object_owner(+) = s.owner ');
          put_line('   AND c.object_name(+) = s.name ');
          put_line('   AND cm.statement_id(+) = ''^^statement_id.'' ');
          put_line('   AND cm.object_type(+) = ''MASTER'' ');
          put_line('   AND cm.object_owner(+) = l.log_owner ');
          put_line('   AND cm.object_name(+) = l.master ');
          put_line('   AND cl.statement_id(+) = ''^^statement_id.'' ');
          put_line('   AND cl.object_type(+) = ''LOG_TABLE'' ');
          put_line('   AND cl.object_owner(+) = l.log_owner ');
          put_line('   AND cl.object_name(+) = l.log_table ');
          put_line('   AND cr.statement_id(+) = ''^^statement_id.'' ');
          put_line('   AND cr.object_type(+) = ''LOG_TABLE_AFTER_REFRESH'' ');
          put_line('   AND cr.object_owner(+) = l.log_owner ');
          put_line('   AND cr.object_name(+) = l.log_table ');
          put_line('   AND cr.id(+) = l.snapshot_id ');
          put_line(' ORDER BY ');
          put_line('       s.owner, ');
          put_line('       s.name, ');
          put_line('       s.snapshot_site, ');
          put_line('       s.snapshot_id, ');
          put_line('       l.log_owner, ');
          put_line('       l.master) v; ');
        END put_sql;
      BEGIN
        put_line('/*********************************************************************************/');
        DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => l2_file_name);
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO(l2_file_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
        put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
        put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => '''||l2_file_name||''');');
        put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||l2_file_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

        -- html
        IF :output_type IN ('H', 'B') THEN
          put_line('SPO ^^prefix._'||l2_file_name||'.html;');
          put_header('^^prefix.', l2_file_name);
          put_line('PRO DBA_REGISTERED_SNAPSHOTS and DBA_SNAPSHOT_LOGS.');
          put_line('PRO MV Name prefix filter used (when applicable): <pre>''^^mv_prefix.''</pre>');
          put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
          put_sql;
          put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');
          put_footer;
          put_line('SPO OFF;');
          put_line('HOS zip -m ^^prefix._html ^^prefix._'||l2_file_name||'.html');
        ELSE
          put_line('-- skip html. output_type: '||:output_type);
        END IF;

        -- csv
        IF :output_type IN ('C', 'B') THEN
          put_line('SPO ^^prefix._'||l2_file_name||'.csv;');
          put_line('SET HEA ON PAGES 50000 LIN 32767 LONGC 4000 COLSEP '','';');
          put_sql;
          put_line('SET HEA OFF PAGES 0 LIN 2000 LONGC 2000 COLSEP '' '';');
          put_line('SPO OFF;');
          put_line('HOS zip -m ^^prefix._csv ^^prefix._'||l2_file_name||'.csv');
        ELSE
          put_line('-- skip csv. output_type: '||:output_type);
        END IF;

        put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);');
        put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);');
        put_line('/*********************************************************************************/');
      END;

      -- report materialized views per log
      DECLARE
        l2_file_name VARCHAR2(60) := 'MATERIALIZED_VIEWS_PER_LOG';

        PROCEDURE put_sql
        IS
        BEGIN
            put_line('SELECT ROWNUM "#", v.* FROM (');
            put_line('SELECT /*+ NO_MERGE */ ');
            put_line('       l.log_owner, ');
            put_line('       l.master, ');
            put_line('       cm.object_node m_degree, ');
            put_line('       cm.timestamp m_last_analyzed, ');
            put_line('       cm.remarks m_stattype_locked, ');
            put_line('       cm.other_tag m_stale_stats, ');
            put_line('       cm.cardinality m_num_rows, ');
            put_line('       cm.cost m_count, ');
            put_line('       cm.bytes m_segment_blocks, ');
            put_line('       l.log_table, ');
            put_line('       cl.object_node l_degree, ');
            put_line('       cl.timestamp l_last_analyzed, ');
            put_line('       cl.remarks l_stattype_locked, ');
            put_line('       cl.other_tag l_stale_stats, ');
            put_line('       cl.cardinality l_num_rows, ');
            put_line('       cl.cost l_count, ');
            put_line('       cr.cost l_count_after_refresh, ');
            put_line('       cl.bytes l_segment_blocks, ');
            put_line('       l.current_snapshots, ');
            put_line('       l.snapshot_id, ');
            put_line('       s2.owner, ');
            put_line('       s2.name mview_name, ');
            put_line('       c.object_node mv_degree, ');
            put_line('       c.timestamp mv_last_analyzed, ');
            put_line('       c.remarks mv_stattype_locked, ');
            put_line('       c.other_tag mv_stale_stats, ');
            put_line('       c.cardinality mv_num_rows, ');
            put_line('       c.cost mv_count, ');
            put_line('       c.bytes mv_segment_blocks, ');
            put_line('       s2.snapshot_site ');
            put_line('  FROM dba_registered_snapshots s, ');
            put_line('       dba_snapshot_logs l, ');
            put_line('       dba_registered_snapshots s2, ');
            put_line('       plan_table c, ');
            put_line('       plan_table cm, ');
            put_line('       plan_table cl, ');
            put_line('       plan_table cr ');
            put_line(' WHERE s.name LIKE ''^^mv_prefix.'' ');
            put_line('   AND l.snapshot_id = s.snapshot_id ');
            put_line('   AND s2.snapshot_id = l.snapshot_id ');
            put_line('   AND c.statement_id(+) = ''^^statement_id.'' ');
            put_line('   AND c.object_type(+) = ''MATERIALIZED VIEW'' ');
            put_line('   AND c.object_owner(+) = s2.owner ');
            put_line('   AND c.object_name(+) = s2.name ');
            put_line('   AND cm.statement_id(+) = ''^^statement_id.'' ');
            put_line('   AND cm.object_type(+) = ''MASTER'' ');
            put_line('   AND cm.object_owner(+) = l.log_owner ');
            put_line('   AND cm.object_name(+) = l.master ');
            put_line('   AND cl.statement_id(+) = ''^^statement_id.'' ');
            put_line('   AND cl.object_type(+) = ''LOG_TABLE'' ');
            put_line('   AND cl.object_owner(+) = l.log_owner ');
            put_line('   AND cl.object_name(+) = l.log_table ');
            put_line('   AND cr.statement_id(+) = ''^^statement_id.'' ');
            put_line('   AND cr.object_type(+) = ''LOG_TABLE_AFTER_REFRESH'' ');
            put_line('   AND cr.object_owner(+) = l.log_owner ');
            put_line('   AND cr.object_name(+) = l.log_table ');
            put_line('   AND cr.id(+) = l.snapshot_id ');
            put_line(' ORDER BY ');
            put_line('       l.log_owner, ');
            put_line('       l.master, ');
            put_line('       l.current_snapshots, ');
            put_line('       l.snapshot_id, ');
            put_line('       s2.owner, ');
            put_line('       s2.name) v; ');
        END put_sql;
      BEGIN
        put_line('/*********************************************************************************/');
        DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => l2_file_name);
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO(l2_file_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
        put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
        put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => '''||l2_file_name||''');');
        put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||l2_file_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

        -- html
        IF :output_type IN ('H', 'B') THEN
          put_line('SPO ^^prefix._'||l2_file_name||'.html;');
          put_header('^^prefix.', l2_file_name);
          put_line('PRO DBA_REGISTERED_SNAPSHOTS and DBA_SNAPSHOT_LOGS.');
          put_line('PRO MV Name prefix filter used (when applicable): <pre>''^^mv_prefix.''</pre>');
          put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
          put_sql;
          put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');
          put_footer;
          put_line('SPO OFF;');
          put_line('HOS zip -m ^^prefix._html ^^prefix._'||l2_file_name||'.html');
        ELSE
          put_line('-- skip html. output_type: '||:output_type);
        END IF;

        -- csv
        IF :output_type IN ('C', 'B') THEN
          put_line('SPO ^^prefix._'||l2_file_name||'.csv;');
          put_line('SET HEA ON PAGES 50000 LIN 32767 LONGC 4000 COLSEP '','';');
          put_sql;
          put_line('SET HEA OFF PAGES 0 LIN 2000 LONGC 2000 COLSEP '' '';');
          put_line('SPO OFF;');
          put_line('HOS zip -m ^^prefix._csv ^^prefix._'||l2_file_name||'.csv');
        ELSE
          put_line('-- skip csv. output_type: '||:output_type);
        END IF;

        put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);');
        put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);');
        put_line('/*********************************************************************************/');
      END;
    END;

    -- reports mv capabilities
    BEGIN
      put_view('MV_CAPABILITIES_TABLE');
    END;

    -- health check report
    DECLARE
      l2_file_name VARCHAR2(60) := 'HEALTH_CHECKS';
    BEGIN
      put_line('/*********************************************************************************/');
      DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => l2_file_name);
      DBMS_APPLICATION_INFO.SET_CLIENT_INFO(l2_file_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
      put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
      put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => '''||l2_file_name||''');');
      put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||l2_file_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

      -- html
      IF :output_type IN ('H', 'B') THEN
        put_line('SPO ^^prefix._'||l2_file_name||'.html;');
        put_header('^^prefix.', l2_file_name);

        -- outdated stats in log
        put_line('PRO <h2>Logs with Outdated Statistics</h2>');
        put_line('PRO Log has stale statistics or a count(*) larger/smaller than "number of rows" (statistics) by more than 10%. Outdated statistics may cause a sub-optimal execution plan on a refresh.');
        put_line('PRO <br>DBA_SNAPSHOT_LOGS.');
        put_line('PRO <br>MV Name prefix filter used: ''^^mv_prefix.''');
        put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
        put_line('SELECT ROWNUM "#", v.* FROM ( ');
        put_line('SELECT /*+ NO_MERGE */ ');
        put_line('       r.log_owner owner, ');
        put_line('       r.master, ');
        put_line('       m.m_degree, ');
        put_line('       m.m_last_analyzed, ');
        put_line('       m.m_stattype_locked, ');
        put_line('       m.m_stale_stats, ');
        put_line('       m.m_num_rows, ');
        put_line('       m.m_count, ');
        put_line('       m.m_segment_blocks, ');
        put_line('       r.log_table, ');
        put_line('       l.l_degree, ');
        put_line('       l.l_last_analyzed, ');
        put_line('       l.l_stattype_locked, ');
        put_line('       l.l_stale_stats, ');
        put_line('       l.l_num_rows, ');
        put_line('       l.l_count, ');
        put_line('       l.l_segment_blocks ');
        put_line('  FROM (SELECT DISTINCT ');
        put_line('               log_owner, ');
        put_line('               master, ');
        put_line('               log_table ');
        put_line('          FROM dba_snapshot_logs) r, ');
        put_line('       (SELECT object_owner m_owner, ');
        put_line('               object_name  m_table_name, ');
        put_line('               object_node  m_degree, ');
        put_line('               timestamp    m_last_analyzed, ');
        put_line('               remarks      m_stattype_locked, ');
        put_line('               other_tag    m_stale_stats, ');
        put_line('               cardinality  m_num_rows, ');
        put_line('               cost         m_count, ');
        put_line('               bytes        m_segment_blocks ');
        put_line('          FROM plan_table ');
        put_line('         WHERE statement_id = ''^^statement_id.'' ');
        put_line('           AND object_type = ''MASTER'') m, ');
        put_line('       (SELECT object_owner l_owner, ');
        put_line('               object_name  l_table_name, ');
        put_line('               object_node  l_degree, ');
        put_line('               timestamp    l_last_analyzed, ');
        put_line('               remarks      l_stattype_locked, ');
        put_line('               other_tag    l_stale_stats, ');
        put_line('               cardinality  l_num_rows, ');
        put_line('               cost         l_count, ');
        put_line('               bytes        l_segment_blocks ');
        put_line('          FROM plan_table ');
        put_line('         WHERE statement_id = ''^^statement_id.'' ');
        put_line('           AND object_type = ''LOG_TABLE'') l ');
        put_line(' WHERE m.m_owner      = r.log_owner ');
        put_line('   AND m.m_table_name = r.master ');
        put_line('   AND l.l_owner      = r.log_owner ');
        put_line('   AND l.l_table_name = r.log_table ');
        put_line('   AND (l.l_num_rows > 100 OR l.l_count > 100) ');
        put_line('   AND (l.l_stale_stats = ''YES'' OR l.l_count > (l.l_num_rows * 1.10) OR l.l_num_rows > (l.l_count * 1.10)) ');
        put_line(' ORDER BY ');
        put_line('       r.log_owner, ');
        put_line('       r.master) v; ');
        put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');

        -- 236292.1 problem_mlogs.sql part 1/2
        put_line('PRO <h2>Logs larger than their Master</h2>');
        put_line('PRO Log is larger than 1x its Master in terms of segment blocks or count(*). This may be an indication of a high water mark problem.');
        put_line('PRO <br>DBA_SNAPSHOT_LOGS.');
        put_line('PRO <br>MV Name prefix filter used: ''^^mv_prefix.''');
        put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
        put_line('SELECT ROWNUM "#", v.* FROM ( ');
        put_line('SELECT /*+ NO_MERGE */ ');
        put_line('       r.log_owner owner, ');
        put_line('       r.master, ');
        put_line('       m.m_degree, ');
        put_line('       m.m_last_analyzed, ');
        put_line('       m.m_stattype_locked, ');
        put_line('       m.m_stale_stats, ');
        put_line('       m.m_num_rows, ');
        put_line('       m.m_count, ');
        put_line('       m.m_segment_blocks, ');
        put_line('       r.log_table, ');
        put_line('       l.l_degree, ');
        put_line('       l.l_last_analyzed, ');
        put_line('       l.l_stattype_locked, ');
        put_line('       l.l_stale_stats, ');
        put_line('       l.l_num_rows, ');
        put_line('       l.l_count, ');
        put_line('       l.l_segment_blocks, ');
        put_line('       ROUND(GREATEST((l.l_segment_blocks / m.m_segment_blocks), (l.l_count / m.m_count)), 1)||''x'' times');
        put_line('  FROM (SELECT DISTINCT ');
        put_line('               log_owner, ');
        put_line('               master, ');
        put_line('               log_table ');
        put_line('          FROM dba_snapshot_logs) r, ');
        put_line('       (SELECT object_owner m_owner, ');
        put_line('               object_name  m_table_name, ');
        put_line('               object_node  m_degree, ');
        put_line('               timestamp    m_last_analyzed, ');
        put_line('               remarks      m_stattype_locked, ');
        put_line('               other_tag    m_stale_stats, ');
        put_line('               cardinality  m_num_rows, ');
        put_line('               cost         m_count, ');
        put_line('               bytes        m_segment_blocks ');
        put_line('          FROM plan_table ');
        put_line('         WHERE statement_id = ''^^statement_id.'' ');
        put_line('           AND object_type = ''MASTER'') m, ');
        put_line('       (SELECT object_owner l_owner, ');
        put_line('               object_name  l_table_name, ');
        put_line('               object_node  l_degree, ');
        put_line('               timestamp    l_last_analyzed, ');
        put_line('               remarks      l_stattype_locked, ');
        put_line('               other_tag    l_stale_stats, ');
        put_line('               cardinality  l_num_rows, ');
        put_line('               cost         l_count, ');
        put_line('               bytes        l_segment_blocks ');
        put_line('          FROM plan_table ');
        put_line('         WHERE statement_id = ''^^statement_id.'' ');
        put_line('           AND object_type = ''LOG_TABLE'') l ');
        put_line(' WHERE m.m_owner      = r.log_owner ');
        put_line('   AND m.m_table_name = r.master ');
        put_line('   AND l.l_owner      = r.log_owner ');
        put_line('   AND l.l_table_name = r.log_table ');
        put_line('   AND ((l.l_segment_blocks > m.m_segment_blocks AND m.m_segment_blocks > 100) /* log is larger than master */ ');
        put_line('    OR  (l.l_count >  m.m_count AND m.m_count > 100)) /* log has more rows than master */ ');
        put_line(' ORDER BY ');
        put_line('       r.log_owner, ');
        put_line('       r.master) v; ');
        put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');

        -- 236292.1 problem_mlogs.sql part 2/2
        put_line('PRO <h2>Complete Refresh Candidates</h2>');
        put_line('PRO Log has a count(*) after last refresh larger than 5% the total log count(*). A complete refresh seems a better option.');
        put_line('PRO <br>DBA_SNAPSHOT_LOGS and DBA_REGISTERED_SNAPSHOTS.');
        put_line('PRO <br>MV Name prefix filter used: ''^^mv_prefix.''');
        put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
        put_line('SELECT ROWNUM "#", v.* FROM ( ');
        put_line('SELECT /*+ NO_MERGE */ ');
        put_line('       r.owner, ');
        put_line('       r.name mview_name, ');
        put_line('       r.snapshot_site, ');
        put_line('       mv.mv_num_rows, ');
        put_line('       mv.mv_count, ');
        put_line('       s.snapshot_id, ');
        put_line('       s.current_snapshots, ');
        put_line('       s.log_owner, ');
        put_line('       s.master, ');
        put_line('       m.m_num_rows, ');
        put_line('       m.m_count, ');
        put_line('       s.log_table, ');
        put_line('       l.l_num_rows, ');
        put_line('       l.l_count, ');
        put_line('       lr.l_count_after_refresh, ');
        put_line('       ROUND(100 * lr.l_count_after_refresh / l.l_count)||''%'' "%" ');
        put_line('  FROM dba_snapshot_logs s, ');
        put_line('       dba_registered_snapshots r, ');
        put_line('       (SELECT object_owner mv_owner, ');
        put_line('               object_name  mv_table_name, ');
        put_line('               cardinality  mv_num_rows, ');
        put_line('               cost         mv_count ');
        put_line('          FROM plan_table ');
        put_line('         WHERE statement_id = ''^^statement_id.'' ');
        put_line('           AND object_type = ''MATERIALIZED VIEW'') mv, ');
        put_line('       (SELECT object_owner m_owner, ');
        put_line('               object_name  m_table_name, ');
        put_line('               cardinality  m_num_rows, ');
        put_line('               cost         m_count ');
        put_line('          FROM plan_table ');
        put_line('         WHERE statement_id = ''^^statement_id.'' ');
        put_line('           AND object_type = ''MASTER'') m, ');
        put_line('       (SELECT object_owner l_owner, ');
        put_line('               object_name  l_table_name, ');
        put_line('               cardinality  l_num_rows, ');
        put_line('               cost         l_count ');
        put_line('          FROM plan_table ');
        put_line('         WHERE statement_id = ''^^statement_id.'' ');
        put_line('           AND object_type = ''LOG_TABLE'') l, ');
        put_line('       (SELECT object_owner l_owner, ');
        put_line('               object_name  l_table_name, ');
        put_line('               id           l_snapshot_id, ');
        put_line('               cost         l_count_after_refresh ');
        put_line('          FROM plan_table ');
        put_line('         WHERE statement_id = ''^^statement_id.'' ');
        put_line('           AND object_type = ''LOG_TABLE_AFTER_REFRESH'') lr ');
        put_line(' WHERE s.snapshot_id    = r.snapshot_id(+) ');
        put_line('   AND mv.mv_owner      = r.owner ');
        put_line('   AND mv.mv_table_name = r.name ');
        put_line('   AND m.m_owner        = s.log_owner ');
        put_line('   AND m.m_table_name   = s.master ');
        put_line('   AND l.l_owner        = s.log_owner ');
        put_line('   AND l.l_table_name   = s.log_table ');
        put_line('   AND lr.l_owner       = s.log_owner ');
        put_line('   AND lr.l_table_name  = s.log_table ');
        put_line('   AND lr.l_snapshot_id = s.snapshot_id ');
        put_line('   AND l.l_count        > 100 ');
        put_line('   AND lr.l_count_after_refresh > (l.l_count * 0.05) /* more than 5% */ ');
        put_line(' ORDER BY ');
        put_line('       r.owner, ');
        put_line('       r.name, ');
        put_line('       r.snapshot_site, ');
        put_line('       s.snapshot_id, ');
        put_line('       s.log_owner, ');
        put_line('       s.master) v; ');
        put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');

        -- 236292.1 mlog_growth.sql
        put_line('PRO <h2>Old Materialized Views</h2>');
        put_line('PRO Materialized Views not refreshed in more than one week.');
        put_line('PRO <br>DBA_REGISTERED_SNAPSHOTS and DBA_SNAPSHOT_LOGS.');
        put_line('PRO <br>MV Name prefix filter used: ''^^mv_prefix.''');
        put_line('SET HEA ON PAGES 25 MARK HTML ON TABLE "" SPOOL OFF;');
        put_line('SELECT ROWNUM "#", v.* FROM (');
        put_line('SELECT /*+ NO_MERGE */ ');
        put_line('       s.log_owner, ');
        put_line('       s.master, ');
        put_line('       s.log_table, ');
        put_line('       s.snapshot_id, ');
        put_line('       s.current_snapshots, ');
        put_line('       TRUNC(SYSDATE - s.current_snapshots) days_old, ');
        put_line('       r.owner, ');
        put_line('       r.name mview_name, ');
        put_line('       r.snapshot_site ');
        put_line('  FROM dba_snapshot_logs s, ');
        put_line('       dba_registered_snapshots r ');
        put_line(' WHERE s.current_snapshots < (SYSDATE - 7) /* 1 week */ ');
        put_line('   AND r.snapshot_id = s.snapshot_id ');
        put_line('   AND r.name LIKE ''^^mv_prefix.'' ');
        put_line(' ORDER BY ');
        put_line('       s.log_owner, ');
        put_line('       s.master, ');
        put_line('       s.snapshot_id, ');
        put_line('       s.current_snapshots, ');
        put_line('       r.owner, ');
        put_line('       r.name ');
        put_line(' ) v;');
        put_line('SET HEA OFF PAGES 0 MARK HTML OFF;');

        put_footer;
        put_line('SPO OFF;');
        put_line('HOS zip -m ^^prefix._html ^^prefix._'||l2_file_name||'.html');
      ELSE
        put_line('-- skip html. output_type: '||:output_type);
      END IF;

      put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);');
      put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);');
      put_line('/*********************************************************************************/');
    END;

    -- nothing is updated to the db. transaction ends here
    put_line('-- end-transaction');
    put_line('ROLLBACK TO save_point_1;'); -- end-transaction

    /**********************************************************************************************/

    -- global
    BEGIN
      l_sq_01 := '(SELECT r.detailobj_owner, r.detailobj_name FROM dba_mview_detail_relations r WHERE r.mview_name LIKE ''^^mv_prefix.'' AND r.detailobj_type = ''TABLE'')';
      --l_sq_02 := '(SELECT l.log_owner, l.log_table FROM dba_mview_detail_relations r, dba_mview_logs l WHERE r.mview_name LIKE ''^^mv_prefix.'' AND r.detailobj_type = ''TABLE'' AND l.log_owner = r.detailobj_owner AND l.master = r.detailobj_name)';
      l_sq_02 := '(SELECT l.log_owner, l.log_table FROM dba_registered_snapshots s, dba_snapshot_logs l WHERE s.name LIKE ''^^mv_prefix.'' AND l.snapshot_id = s.snapshot_id)';
      --l_sq_03 := '(SELECT l.log_table FROM dba_mview_detail_relations r, dba_mview_logs l WHERE r.mview_name LIKE ''^^mv_prefix.'' AND r.detailobj_type = ''TABLE'' AND l.log_owner = r.detailobj_owner AND l.master = r.detailobj_name)';
      l_sq_03 := '(SELECT l.log_table FROM dba_registered_snapshots s, dba_snapshot_logs l WHERE s.name LIKE ''^^mv_prefix.'' AND l.snapshot_id = s.snapshot_id)';
      l_sq_04 := '(SELECT m.owner, m.mview_name FROM dba_mviews m WHERE m.mview_name LIKE ''^^mv_prefix.'')';
      l_sq_05 := '(SELECT m.mview_name FROM dba_mviews m WHERE m.mview_name LIKE ''^^mv_prefix.'')';

      put_view('DBA_MVIEW_AGGREGATES', 'mview_name LIKE ''^^mv_prefix.''');
      put_view('DBA_MVIEW_ANALYSIS', 'mview_name LIKE ''^^mv_prefix.''');
      --put_view('DBA_MVIEW_COMMENTS', 'mview_name LIKE ''^^mv_prefix.''');
      put_view('DBA_MVIEW_DETAIL_PARTITION', 'mview_name LIKE ''^^mv_prefix.''');
      put_view('DBA_MVIEW_DETAIL_RELATIONS', 'mview_name LIKE ''^^mv_prefix.''');
      put_view('DBA_MVIEW_DETAIL_SUBPARTITION', 'mview_name LIKE ''^^mv_prefix.''');
      put_view('DBA_MVIEW_JOINS', 'mview_name LIKE ''^^mv_prefix.''');
      put_view('DBA_MVIEW_KEYS', 'mview_name LIKE ''^^mv_prefix.''');
      put_view('DBA_MVIEW_LOG_FILTER_COLS', '(owner, name) IN '||l_sq_01);
      put_view('DBA_MVIEW_LOGS', '(log_owner, master) IN '||l_sq_01);
      put_view('DBA_MVIEW_REFRESH_TIMES', 'name LIKE ''^^mv_prefix.''');
      put_view('DBA_MVIEWS', 'mview_name LIKE ''^^mv_prefix.''');
      put_view('DBA_RCHILD');
      put_view('DBA_REFRESH');
      put_view('DBA_REFRESH_CHILDREN');
      put_view('DBA_REGISTERED_MVIEW_GROUPS');
      put_view('DBA_REGISTERED_MVIEWS', 'name LIKE ''^^mv_prefix.''');
      put_view('DBA_REGISTERED_SNAPSHOT_GROUPS');
      put_view('DBA_REGISTERED_SNAPSHOTS', 'name LIKE ''^^mv_prefix.''');
      put_view('DBA_RGROUP');
      put_view('DBA_SNAPSHOT_LOGS', '(log_owner, master) IN '||l_sq_01);
      put_view('DBA_SNAPSHOTS', 'name LIKE ''^^mv_prefix.''');
      put_view('DBA_JOBS', 'LOWER(what) LIKE ''%refresh%''');
      put_view('DBA_JOBS_RUNNING', 'job IN (SELECT job FROM dba_jobs WHERE LOWER(what) LIKE ''%refresh%'')');
      put_view('DBA_COL_COMMENTS', 'table_name LIKE ''^^mv_prefix.'' AND (owner, table_name) IN '||l_sq_04);
      put_view('DBA_OBJECTS', 'object_name LIKE ''^^mv_prefix.'' AND object_type IN (''TABLE'', ''VIEW'', ''TABLE PARTITION'', ''MATERIALIZED VIEW'') AND (owner, object_name) IN '||l_sq_04, '_MV');
      put_view('DBA_OBJECTS', 'object_name LIKE ''MLOG$%'' AND object_type IN (''TABLE'', ''TABLE PARTITION'') AND (owner, object_name) IN '||l_sq_02, '_LOG');
      put_view('DBA_OBJECTS', NULL, '_ALL');
      put_view('SNAP$', 'tname LIKE ''^^mv_prefix.''');
      put_view('SLOG$', '(mowner, master) IN '||l_sq_01);
      put_view('MLOG$', '(mowner, master) IN '||l_sq_01);
      put_view('OBJ$', 'name LIKE ''^^mv_prefix.'' AND type# IN (2 /* TABLE */, 4 /* VIEW */, 19 /* TABLE PARTITION */, 42 /* MATERIALIZED VIEW */) AND name IN '||l_sq_05, '_MV');
      put_view('OBJ$', 'name LIKE ''MLOG$%'' AND type# IN (2 /* TABLE */, 19 /* TABLE PARTITION */) AND name IN '||l_sq_03, '_LOG');
      put_view('DBA_SEGMENTS', 'segment_name LIKE ''^^mv_prefix.'' AND segment_type LIKE ''TABLE%'' AND (owner, segment_name) IN '||l_sq_04, '_MV');
      put_view('DBA_SEGMENTS', 'segment_name LIKE ''MLOG$%'' AND segment_type LIKE ''TABLE%'' AND (owner, segment_name) IN '||l_sq_02, '_LOG');
      put_view('DBA_TABLES', 'table_name LIKE ''^^mv_prefix.'' AND (owner, table_name) IN '||l_sq_04, '_MV');
      put_view('DBA_TABLES', 'table_name LIKE ''MLOG$%'' AND (owner, table_name) IN '||l_sq_02, '_LOG');
      put_view('DBA_TAB_STATISTICS', 'table_name LIKE ''^^mv_prefix.'' AND (owner, table_name) IN '||l_sq_04, '_MV');
      put_view('DBA_TAB_STATISTICS', 'table_name LIKE ''MLOG$%'' AND (owner, table_name) IN '||l_sq_02, '_LOG');
      put_view('DBA_TAB_MODIFICATIONS', 'table_name LIKE ''^^mv_prefix.'' AND (table_owner, table_name) IN '||l_sq_04, '_MV');
      put_view('DBA_TAB_MODIFICATIONS', 'table_name LIKE ''MLOG$%'' AND (table_owner, table_name) IN '||l_sq_02, '_LOG');
      put_view('DBA_INDEXES', 'table_name LIKE ''^^mv_prefix.'' AND (table_owner, table_name) IN '||l_sq_04, '_MV');
      put_view('DBA_INDEXES', 'table_name LIKE ''MLOG$%'' AND (table_owner, table_name) IN '||l_sq_02, '_LOG');
      put_view('DBA_IND_STATISTICS', 'table_name LIKE ''^^mv_prefix.'' AND (table_owner, table_name) IN '||l_sq_04, '_MV');
      put_view('DBA_IND_STATISTICS', 'table_name LIKE ''MLOG$%'' AND (table_owner, table_name) IN '||l_sq_02, '_LOG');
      put_view('DBA_TAB_COLS', 'table_name LIKE ''^^mv_prefix.'' AND (owner, table_name) IN '||l_sq_04, '_MV');
      put_view('DBA_TAB_COLS', 'table_name LIKE ''MLOG$%'' AND (owner, table_name) IN '||l_sq_02, '_LOG');
      put_view('DBA_IND_COLUMNS', 'table_name LIKE ''^^mv_prefix.'' AND (table_owner, table_name) IN '||l_sq_04, '_MV');
      put_view('DBA_IND_COLUMNS', 'table_name LIKE ''MLOG$%'' AND (table_owner, table_name) IN '||l_sq_02, '_LOG');
      put_view('GV$PARAMETER2');
      put_view('GV$MVREFRESH');
    END;

    -- dependencies (ancestors)
    DECLARE
      l2_table_name VARCHAR2(30) := 'DBA_DEPENDENCIES';
      l2_file_suffix VARCHAR2(30) := '_ANCESTORS';
      l2_file_name VARCHAR2(60) := l2_table_name||l2_file_suffix;
    BEGIN
      put_line('/*********************************************************************************/');
      put_line('-- '||l2_file_name);
      put_line('SET TERM OFF;');
      DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => l2_file_name);
      DBMS_APPLICATION_INFO.SET_CLIENT_INFO(l2_table_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
      put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
      put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => '''||l2_file_name||''');');
      put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||l2_file_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

      -- html
      IF :output_type IN ('H', 'B') THEN
        put_line('SPO ^^prefix._'||l2_file_name||'.html;');
        put_header('^^prefix.', l2_table_name, l2_file_suffix);
        describe_table(l2_table_name);
        put_line('PRO MV Name prefix filter used (when applicable): <pre>''^^mv_prefix.''</pre>');
        put_line('SPO OFF;');
        put_line('COL row_num FOR 9999 HEA "#";');
	put_line('COL depth FOR 999 HEA "Dep";');
	put_line('COL referenced FOR A80 HEA "Referenced";');
	put_line('COL dependency_type FOR A4 HEA "Type";');
        put_line('SET HEA ON PAGES 50000 LIN 2000;');

        put_line('SET TERM ON;');
        put_line('PRO dependencies (ancestors) html;');
        put_line('SET TERM OFF;');
        FOR i IN (SELECT owner, mview_name FROM dba_mviews WHERE mview_name LIKE '^^mv_prefix.' ORDER BY owner, mview_name)
        LOOP
          put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
          put_line('SET TERM ON;');
          put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||i.mview_name||';');
          put_line('SET TERM OFF;');
          put_line('SPO ^^prefix._'||l2_file_name||'.html APP;');
          put_line('PRO <h2>'||i.owner||'.'||i.mview_name||'</h2>');
          put_line('PRO '||i.mview_name||' depends on the following objects:');
          put_line('PRO <pre>');
	  put_line('SELECT ROWNUM row_num, v.depth, ');
	  put_line('       SUBSTR(RPAD('' '', v.depth, '' '')||v.referenced_type||'' ''||v.referenced_owner||''.''||v.referenced_name|| ');
	  put_line('       DECODE(v.referenced_link_name, NULL, NULL, ''@''||v.referenced_link_name), 2) referenced, ');
	  put_line('       v.dependency_type ');
	  put_line('  FROM ( ');
	  put_line('SELECT /*+ NO_MERGE */ LEVEL depth, referenced_owner, referenced_name, referenced_type, referenced_link_name, dependency_type ');
	  put_line('  FROM dba_dependencies ');
	  put_line(' START WITH ');
	  put_line('       owner = '''||i.owner||''' AND name = '''||i.mview_name||''' AND type = ''MATERIALIZED VIEW'' ');
	  put_line('CONNECT BY ');
	  put_line('       owner = PRIOR referenced_owner AND name = PRIOR referenced_name AND type = PRIOR referenced_type ');
	  put_line('       ) v; ');
          put_line('PRO </pre>');
          put_line('SPO OFF;');
        END LOOP;
        put_line('SET HEA OFF PAGES 0 LIN 2000;');
        put_line('COL row_num CLE;');
	put_line('COL depth CLE;');
	put_line('COL referenced CLE;');
	put_line('COL dependency_type CLE;');
	put_line('SPO ^^prefix._'||l2_file_name||'.html APP;');
        put_footer;
        put_line('SPO OFF;');
        put_line('HOS zip -m ^^prefix._html ^^prefix._'||l2_file_name||'.html');
      END IF;

      -- csv
      IF :output_type IN ('C', 'B') THEN
        put_line('SET HEA ON PAGES 50000 LIN 32767 LONGC 4000 COLSEP '','';');
        put_line('SET TERM ON;');
        put_line('PRO dependencies (ancestors) csv;');
        put_line('SET TERM OFF;');

        FOR i IN (SELECT owner, mview_name FROM dba_mviews WHERE mview_name LIKE '^^mv_prefix.' ORDER BY owner, mview_name)
        LOOP
          put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
          put_line('SET TERM ON;');
          put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||i.mview_name||';');
          put_line('SET TERM OFF;');
          put_line('SPO ^^prefix._'||l2_file_name||'.csv APP;');
	  put_line('SELECT '''||i.owner||''' owner, '''||i.mview_name||''' mview_name, ROWNUM row_num, v.depth, ');
	  put_line('       v.referenced_type, v.referenced_owner, v.referenced_name, ');
	  put_line('       v.referenced_link_name, ');
	  put_line('       v.dependency_type ');
	  put_line('  FROM ( ');
	  put_line('SELECT /*+ NO_MERGE */ LEVEL depth, referenced_owner, referenced_name, referenced_type, referenced_link_name, dependency_type ');
	  put_line('  FROM dba_dependencies ');
	  put_line(' START WITH ');
	  put_line('       owner = '''||i.owner||''' AND name = '''||i.mview_name||''' AND type = ''MATERIALIZED VIEW'' ');
	  put_line('CONNECT BY ');
	  put_line('       owner = PRIOR referenced_owner AND name = PRIOR referenced_name AND type = PRIOR referenced_type ');
	  put_line('       ) v; ');
          put_line('SPO OFF;');
          put_line('SET PAGES 0;'); -- only 1st one needs headers
        END LOOP;
        put_line('SET HEA OFF PAGES 0 LIN 2000 LONGC 2000 COLSEP '' '';');
        put_line('HOS zip -m ^^prefix._csv ^^prefix._'||l2_file_name||'.csv');
      END IF;
    END;

    -- dependencies (descendants)
    DECLARE
      l2_table_name VARCHAR2(30) := 'DBA_DEPENDENCIES';
      l2_file_suffix VARCHAR2(30) := '_DESCENDANTS';
      l2_file_name VARCHAR2(60) := l2_table_name||l2_file_suffix;
    BEGIN
      put_line('/*********************************************************************************/');
      put_line('-- '||l2_file_name);
      put_line('SET TERM OFF;');
      DBMS_APPLICATION_INFO.SET_MODULE(module_name => '^^script..sql', action_name => l2_file_name);
      DBMS_APPLICATION_INFO.SET_CLIENT_INFO(l2_table_name||' '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS'));
      put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
      put_line('EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => ''^^script..sql'', action_name => '''||l2_file_name||''');');
      put_line('EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO('''||l2_file_name||' ^^subst_var.^^subst_var.time_stamp1.'');');

      -- html
      IF :output_type IN ('H', 'B') THEN
        put_line('SPO ^^prefix._'||l2_file_name||'.html;');
        put_header('^^prefix.', l2_table_name, l2_file_suffix);
        describe_table(l2_table_name);
        put_line('PRO MV Name prefix filter used (when applicable): <pre>''^^mv_prefix.''</pre>');
        put_line('SPO OFF;');
        put_line('COL row_num FOR 9999 HEA "#";');
	put_line('COL depth FOR 999 HEA "Dep";');
	put_line('COL references FOR A80 HEA "References";');
	put_line('COL dependency_type FOR A4 HEA "Type";');
        put_line('SET HEA ON PAGES 50000 LIN 2000;');
        put_line('SET TERM ON;');
        put_line('PRO dependencies (descendants) html;');
        put_line('SET TERM OFF;');

        FOR i IN (SELECT owner, mview_name FROM dba_mviews WHERE mview_name LIKE '^^mv_prefix.' ORDER BY owner, mview_name)
        LOOP
          put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
          put_line('SET TERM ON;');
          put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||i.mview_name||';');
          put_line('SET TERM OFF;');
          put_line('SPO ^^prefix._'||l2_file_name||'.html APP;');
          put_line('PRO <h2>'||i.owner||'.'||i.mview_name||'</h2>');
          put_line('PRO The following objects depend on '||i.mview_name||':');
          put_line('PRO <pre>');
          put_line('SELECT ROWNUM row_num, v.depth, ');
	  put_line('       SUBSTR(RPAD('' '', v.depth, '' '')||v.type||'' ''||v.owner||''.''||v.name, 2) references, ');
	  put_line('       v.dependency_type ');
	  put_line('  FROM ( ');
	  put_line('SELECT /*+ NO_MERGE */ LEVEL depth, owner, name, type, dependency_type ');
	  put_line('  FROM dba_dependencies ');
	  put_line(' START WITH ');
	  put_line('       referenced_owner = '''||i.owner||''' AND referenced_name = '''||i.mview_name||''' AND referenced_type = ''MATERIALIZED VIEW'' ');
	  put_line('CONNECT BY ');
	  put_line('       referenced_owner = PRIOR owner  AND referenced_name = PRIOR name AND referenced_type = PRIOR type ');
	  put_line('       ) v; ');
          put_line('PRO </pre>');
          put_line('SPO OFF;');
        END LOOP;
        put_line('SET HEA OFF PAGES 0 LIN 2000;');
        put_line('COL row_num CLE;');
	put_line('COL depth CLE;');
	put_line('COL references CLE;');
	put_line('COL dependency_type CLE;');
	put_line('SPO ^^prefix._'||l2_file_name||'.html APP;');
        put_footer;
        put_line('SPO OFF;');
        put_line('HOS zip -m ^^prefix._html ^^prefix._'||l2_file_name||'.html');
      END IF;

      -- csv
      IF :output_type IN ('C', 'B') THEN
        put_line('SET HEA ON PAGES 50000 LIN 32767 LONGC 4000 COLSEP '','';');
        put_line('SET TERM ON;');
        put_line('PRO dependencies (descendants) csv;');
        put_line('SET TERM OFF;');

        FOR i IN (SELECT owner, mview_name FROM dba_mviews WHERE mview_name LIKE '^^mv_prefix.' ORDER BY owner, mview_name)
        LOOP
          put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
          put_line('SET TERM ON;');
          put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||i.mview_name||';');
          put_line('SET TERM OFF;');
          put_line('SPO ^^prefix._'||l2_file_name||'.csv APP;');
          put_line('SELECT '''||i.owner||''' owner, '''||i.mview_name||''' mview_name, ROWNUM row_num, v.depth, ');
	  put_line('       v.type, v.owner, v.name, ');
	  put_line('       v.dependency_type ');
	  put_line('  FROM ( ');
	  put_line('SELECT /*+ NO_MERGE */ LEVEL depth, owner, name, type, dependency_type ');
	  put_line('  FROM dba_dependencies ');
	  put_line(' START WITH ');
	  put_line('       referenced_owner = '''||i.owner||''' AND referenced_name = '''||i.mview_name||''' AND referenced_type = ''MATERIALIZED VIEW'' ');
	  put_line('CONNECT BY ');
	  put_line('       referenced_owner = PRIOR owner  AND referenced_name = PRIOR name AND referenced_type = PRIOR type ');
	  put_line('       ) v; ');
          put_line('SPO OFF;');
          put_line('SET PAGES 0;'); -- only 1st one needs headers
        END LOOP;
        put_line('SET HEA OFF PAGES 0 LIN 2000 LONGC 2000 COLSEP '' '';');
        put_line('HOS zip -m ^^prefix._csv ^^prefix._'||l2_file_name||'.csv');
      END IF;
    END;

    -- pack html and csv files
    BEGIN
      put_line('SET TERM ON;');
      put_line('PRO');
      IF :output_type IN ('H', 'B') THEN
        put_line('HOS unzip -l ^^prefix._html');
        put_line('HOS zip -m ^^prefix. ^^prefix._html.zip');
      END IF;
      IF :output_type IN ('C', 'B') THEN
        put_line('HOS unzip -l ^^prefix._csv');
        put_line('HOS zip -m ^^prefix. ^^prefix._csv.zip');
      END IF;
    END;

    -- mv metadata
    BEGIN
      put_line('/*********************************************************************************/');
      put_line('-- mv metadata');
      put_line('SET TERM OFF;');
      FOR i IN (SELECT owner, mview_name
                  FROM dba_mviews
                 WHERE mview_name LIKE '^^mv_prefix.'
                 ORDER BY
                       owner, mview_name)
      LOOP
        put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
        put_line('SET TERM ON;');
        put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||i.mview_name||' (metadata)');
        put_line('SET TERM OFF;');
        put_line('SPO ^^prefix._metadata_mv_'||i.mview_name||'.sql;');
        put_line('SELECT DBMS_METADATA.GET_DDL(''MATERIALIZED_VIEW'', '''||i.mview_name||''', '''||i.owner||''') FROM DUAL;');
        put_line('SPO OFF;');
        put_line('HOS zip -m ^^prefix._metadata_mv ^^prefix._metadata_mv_'||i.mview_name||'.sql');
      END LOOP;
      put_line('SET TERM ON;');
      put_line('HOS unzip -l ^^prefix._metadata_mv');
      put_line('HOS zip -m ^^prefix. ^^prefix._metadata_mv.zip');
    END;

    -- mlog metadata
    BEGIN
      put_line('/*********************************************************************************/');
      put_line('-- mlog metadata');
      put_line('SET TERM OFF;');
      FOR i IN (SELECT DISTINCT
                       l.log_owner, l.log_table
                  FROM dba_registered_snapshots s,
                       dba_snapshot_logs l
                 WHERE s.name LIKE '^^mv_prefix.'
                   AND l.snapshot_id = s.snapshot_id
                 ORDER BY
                       l.log_owner, l.log_table)
      LOOP
        put_line('SELECT TO_CHAR(SYSDATE, ''YYYY-MM-DD/HH24:MI:SS'') time_stamp1 FROM DUAL;');
        put_line('SET TERM ON;');
        put_line('PRO ^^subst_var.^^subst_var.time_stamp1. '||i.log_table||' (metadata)');
        put_line('SET TERM OFF;');
        put_line('SPO ^^prefix._metadata_mlog_'||REPLACE(i.log_table, '$', 's')||'.sql;');
        put_line('SELECT DBMS_METADATA.GET_DDL(''MATERIALIZED_VIEW_LOG'', '''||i.log_table||''', '''||i.log_owner||''') FROM DUAL;');
        put_line('SPO OFF;');
        put_line('HOS zip -m ^^prefix._metadata_mlog ^^prefix._metadata_mlog_'||REPLACE(i.log_table, '$', 's')||'.sql');
      END LOOP;
      put_line('SET TERM ON;');
      put_line('HOS unzip -l ^^prefix._metadata_mlog');
      put_line('HOS zip -m ^^prefix. ^^prefix._metadata_mlog.zip');
    END;

    /**********************************************************************************************/

    -- transaction begins here. it will be rolled back after generating spool file
    put_line('SET TERM OFF;');
    put_line('-- begin-transaction');
    SAVEPOINT save_point_1; -- begin-transaction

    -- mv capabilities
    BEGIN
      put_line('SPO ^^script..log APP;');
      DELETE mv_capabilities_table WHERE statement_id = '^^statement_id.';

      FOR i IN (SELECT m.owner, m.mview_name
                  FROM dba_mviews m
                 WHERE m.mview_name LIKE '^^mv_prefix.'
                 ORDER BY
                       m.owner, m.mview_name)
      LOOP
        put_line('PRO DBMS_MVIEW.EXPLAIN_MVIEW on '||i.owner||'.'||i.mview_name);
        BEGIN
          DBMS_MVIEW.EXPLAIN_MVIEW(i.owner||'.'||i.mview_name, '^^statement_id.');
        EXCEPTION
          WHEN OTHERS THEN
            put_line('PRO *** '||SQLERRM);
        END;
      END LOOP;
      put_line('SPO OFF;');
    END;

    -- logs per materialized view and materialized views per log
    DECLARE
      l_count NUMBER;
      l_count2 NUMBER;
    BEGIN
      -- this script uses the gtt plan_table as a temporary staging place
      DELETE plan_table WHERE statement_id = '^^statement_id.';

      -- all materialized views
      FOR i IN (SELECT v.*,
                       (SELECT t.degree          FROM dba_tables t         WHERE t.owner = v.owner AND t.table_name   = v.name)                                  degree,
                       (SELECT t.num_rows        FROM dba_tables t         WHERE t.owner = v.owner AND t.table_name   = v.name)                                  num_rows,
                       (SELECT t.last_analyzed   FROM dba_tables t         WHERE t.owner = v.owner AND t.table_name   = v.name)                                  last_analyzed,
                       (SELECT t.stattype_locked FROM dba_tab_statistics t WHERE t.owner = v.owner AND t.table_name   = v.name AND t.object_type = 'TABLE')      stattype_locked,
                       (SELECT t.stale_stats     FROM dba_tab_statistics t WHERE t.owner = v.owner AND t.table_name   = v.name AND t.object_type = 'TABLE')      stale_stats,
                       (SELECT SUM(t.blocks)     FROM dba_segments t       WHERE t.owner = v.owner AND t.segment_name = v.name AND t.segment_type LIKE 'TABLE%') segment_blocks
                  FROM (
                SELECT /*+ NO_MERGE */
                       DISTINCT
                       s.owner,
                       s.name
                  FROM dba_registered_snapshots s
                 WHERE s.name LIKE '^^mv_prefix.') v)
      LOOP
        IF :include_count = 'Y' THEN
          -- mv count
          BEGIN
            EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL */ COUNT(*) * 100 FROM '||i.owner||'.'||i.name||' SAMPLE (1) t' INTO l_count;
            IF l_count < 1e6 THEN
              EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL */ COUNT(*) FROM '||i.owner||'.'||i.name||' t' INTO l_count;
            END IF;
            put_line('SPO ^^script..log APP;');
            put_line('PRO COUNT(*) on '||i.owner||'.'||i.name||': '||l_count);
            put_line('SPO OFF;');
          EXCEPTION
            WHEN OTHERS THEN
              l_count := NULL;
              put_line('SPO ^^script..log APP;');
              put_line('PRO *** '||SQLERRM||'. While COUNT(*) on '||i.owner||'.'||i.name);
              put_line('SPO OFF;');
          END;
        ELSE
          l_count := NULL;
        END IF;

        INSERT INTO plan_table
        (statement_id, object_type, object_node, object_owner, object_name, cardinality, cost, remarks, other_tag, timestamp, bytes)
        VALUES
        ('^^statement_id.', 'MATERIALIZED VIEW', i.degree, i.owner, i.name, i.num_rows, l_count, i.stattype_locked, i.stale_stats, i.last_analyzed, i.segment_blocks);
      END LOOP;

      -- all masters and logs
      FOR i IN (SELECT v.*,
                       (SELECT t.degree          FROM dba_tables t         WHERE t.owner = v.log_owner AND t.table_name   = v.master)                                     m_degree,
                       (SELECT t.num_rows        FROM dba_tables t         WHERE t.owner = v.log_owner AND t.table_name   = v.master)                                     m_num_rows,
                       (SELECT t.last_analyzed   FROM dba_tables t         WHERE t.owner = v.log_owner AND t.table_name   = v.master)                                     m_last_analyzed,
                       (SELECT t.stattype_locked FROM dba_tab_statistics t WHERE t.owner = v.log_owner AND t.table_name   = v.master AND t.object_type = 'TABLE')         m_stattype_locked,
                       (SELECT t.stale_stats     FROM dba_tab_statistics t WHERE t.owner = v.log_owner AND t.table_name   = v.master AND t.object_type = 'TABLE')         m_stale_stats,
                       (SELECT SUM(t.blocks)     FROM dba_segments t       WHERE t.owner = v.log_owner AND t.segment_name = v.master AND t.segment_type LIKE 'TABLE%')    m_segment_blocks,
                       (SELECT t.degree          FROM dba_tables t         WHERE t.owner = v.log_owner AND t.table_name   = v.log_table)                                  l_degree,
                       (SELECT t.num_rows        FROM dba_tables t         WHERE t.owner = v.log_owner AND t.table_name   = v.log_table)                                  l_num_rows,
                       (SELECT t.last_analyzed   FROM dba_tables t         WHERE t.owner = v.log_owner AND t.table_name   = v.log_table)                                  l_last_analyzed,
                       (SELECT t.stattype_locked FROM dba_tab_statistics t WHERE t.owner = v.log_owner AND t.table_name   = v.log_table AND t.object_type = 'TABLE')      l_stattype_locked,
                       (SELECT t.stale_stats     FROM dba_tab_statistics t WHERE t.owner = v.log_owner AND t.table_name   = v.log_table AND t.object_type = 'TABLE')      l_stale_stats,
                       (SELECT SUM(t.blocks)     FROM dba_segments t       WHERE t.owner = v.log_owner AND t.segment_name = v.log_table AND t.segment_type LIKE 'TABLE%') l_segment_blocks
                  FROM (
                SELECT /*+ NO_MERGE */
                       DISTINCT
                       l.log_owner,
                       l.master,
                       l.log_table
                  FROM dba_registered_snapshots s,
                       dba_snapshot_logs l
                 WHERE s.name LIKE '^^mv_prefix.'
                   AND l.snapshot_id = s.snapshot_id) v)
      LOOP
        IF :include_count = 'Y' THEN
          -- master count
          BEGIN
            EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL */ COUNT(*) * 100 FROM '||i.log_owner||'.'||i.master||' SAMPLE (1) t' INTO l_count;
            IF l_count < 1e6 THEN
              EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL */ COUNT(*) FROM '||i.log_owner||'.'||i.master||' t' INTO l_count;
            END IF;
            put_line('SPO ^^script..log APP;');
            put_line('PRO COUNT(*) on '||i.log_owner||'.'||i.master||': '||l_count);
            put_line('SPO OFF;');
          EXCEPTION
            WHEN OTHERS THEN
              l_count := NULL;
              put_line('SPO ^^script..log APP;');
              put_line('PRO *** '||SQLERRM||'. While COUNT(*) on '||i.log_owner||'.'||i.master);
              put_line('SPO OFF;');
          END;

          -- mlog count
          BEGIN
            EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL */ COUNT(*) * 100 FROM '||i.log_owner||'.'||i.log_table||' SAMPLE (1) t' INTO l_count2;
            IF l_count2 < 1e6 THEN
              EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL */ COUNT(*) FROM '||i.log_owner||'.'||i.log_table||' t' INTO l_count2;
            END IF;
            put_line('SPO ^^script..log APP;');
            put_line('PRO COUNT(*) on '||i.log_owner||'.'||i.log_table||': '||l_count2);
            put_line('SPO OFF;');
          EXCEPTION
            WHEN OTHERS THEN
              l_count2 := NULL;
              put_line('SPO ^^script..log APP;');
              put_line('PRO *** '||SQLERRM||'. While COUNT(*) on '||i.log_owner||'.'||i.log_table);
              put_line('SPO OFF;');
          END;
        ELSE
          l_count := NULL;
          l_count2 := NULL;
        END IF;

        INSERT INTO plan_table
        (statement_id, object_type, object_node, object_owner, object_name, cardinality, cost, remarks, other_tag, timestamp, bytes)
        VALUES
        ('^^statement_id.', 'MASTER', i.m_degree, i.log_owner, i.master, i.m_num_rows, l_count, i.m_stattype_locked, i.m_stale_stats, i.m_last_analyzed, i.m_segment_blocks);

        INSERT INTO plan_table
        (statement_id, object_type, object_node, object_owner, object_name, cardinality, cost, remarks, other_tag, timestamp, bytes)
        VALUES
        ('^^statement_id.', 'LOG_TABLE', i.l_degree, i.log_owner, i.log_table, i.l_num_rows, l_count2, i.l_stattype_locked, i.l_stale_stats, i.l_last_analyzed, i.l_segment_blocks);
      END LOOP;

      -- logs per materialized view
      FOR i IN (SELECT l.log_owner,
                       l.log_table,
                       l.current_snapshots,
                       l.snapshot_id
                  FROM dba_registered_snapshots s,
                       dba_snapshot_logs l
                 WHERE s.name LIKE '^^mv_prefix.'
                   AND l.snapshot_id = s.snapshot_id)
      LOOP
        IF :include_count = 'Y' THEN
          -- mlog count after last refresh
          BEGIN
            EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL */ COUNT(*) * 100 FROM '||i.log_owner||'.'||i.log_table||' SAMPLE (1) t WHERE snaptime$$ > :current_snapshots' INTO l_count USING i.current_snapshots;
            IF l_count < 1e6 THEN
              EXECUTE IMMEDIATE 'SELECT /*+ PARALLEL */ COUNT(*) FROM '||i.log_owner||'.'||i.log_table||' t WHERE snaptime$$ > :current_snapshots' INTO l_count USING i.current_snapshots;
            END IF;
            put_line('SPO ^^script..log APP;');
            put_line('PRO COUNT(*) on '||i.log_owner||'.'||i.log_table||' for snapshot_id '||i.snapshot_id||': '||l_count);
            put_line('SPO OFF;');
          EXCEPTION
            WHEN OTHERS THEN
              l_count := NULL;
              put_line('SPO ^^script..log APP;');
              put_line('PRO *** '||SQLERRM||'. While COUNT(*) on '||i.log_owner||'.'||i.log_table||' for snapshot_id '||i.snapshot_id);
              put_line('SPO OFF;');
          END;
        ELSE
          l_count := NULL;
        END IF;

        INSERT INTO plan_table
        (statement_id, object_type, object_owner, object_name, cost, id)
        VALUES
        ('^^statement_id.', 'LOG_TABLE_AFTER_REFRESH', i.log_owner, i.log_table, l_count, i.snapshot_id);
      END LOOP;

    END;

  ELSE -- output_type NOT IN ('H', 'C', 'B')
    put_line('-- output_type: '||:output_type);
  END IF; -- :output_type IN ('H', 'C', 'B')
END;
/

PRO SET TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NUM 10 NEWP 1 PAGES 14 LONG 80 LONGC 80 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF AUTOT OFF;;
PRO PRO ^^prefix._*.zip files have been created.
PRO PRO
PRO SET DEF ON;;
SPO OFF;

/**************************************************************************************************/

/* -------------------------
 *
 * end of script generation
 *
 * ------------------------- */

EXEC DBMS_APPLICATION_INFO.SET_MODULE(module_name => NULL, action_name => NULL);
EXEC DBMS_APPLICATION_INFO.SET_CLIENT_INFO(client_info => NULL);
SET TERM OFF ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NUM 10 NEWP 1 PAGES 14 LONG 80 LONGC 80 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF AUTOT OFF;
SPO ^^script..log APP
SELECT 'END SCRIPT GENERATION: '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS') FROM dual;
SET TERM ON;
PRO
PRO ^^prefix._driver.sql file has been created.
PRO
SPO OFF;
@^^prefix._driver.sql
SET DEF ON;
SET DEF ^;

/**************************************************************************************************/
/* -------------------------
 *
 * wrap up
 *
 * ------------------------- */
SET TERM OFF;

-- get udump directory path
COL udump_path NEW_V udump_path FOR A500;
SELECT value||DECODE(INSTR(value, '/'), 0, '\', '/') udump_path FROM v$parameter2 WHERE name = 'user_dump_dest';

-- turing trace off
SPO ^^script..log APP
SELECT 'END SCRIPT EXECUTION: '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS') FROM dual;
ALTER SESSION SET SQL_TRACE = FALSE;
--ALTER SESSION SET STATISTICS_LEVEL = 'TYPICAL';
SPO OFF;
SET TERM ON;

-- tkprof for trace from execution of tool in case someone reports slow performance in tool
HOS tkprof ^^udump_path.*^^prefix.*.trc ^^prefix._tkprof_nosort.txt
HOS tkprof ^^udump_path.*^^prefix.*.trc ^^prefix._tkprof_sort.txt sort=prsela exeela fchela

-- windows workaround (copy below will error out on linux and unix)
HOS copy ^^udump_path.*^^prefix.*.trc ^^udump_path.^^prefix..trc
HOS tkprof ^^udump_path.^^prefix..trc ^^prefix._tkprof_nosort.txt
HOS tkprof ^^udump_path.^^prefix..trc ^^prefix._tkprof_sort.txt sort=prsela exeela fchela

-- zip logs and all reports
HOS zip -m ^^prefix._log ^^prefix._*.sql ^^prefix._tkprof_*.txt mvhcdr.log
HOS unzip -l ^^prefix._log
HOS zip -m ^^prefix. ^^prefix._log.zip
PRO
PRO ^^module. files have been created.
PRO
HOS unzip -l ^^prefix.
CL COL;
SET DEF ON;
UNDEF 1 2 3 script module mos_doc doc_ver doc_date dbid dbname input_mv_prefix input_include_count input_output_type current_time statement_id prefix mv_prefix include_count output_type udump_path;