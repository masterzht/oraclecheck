CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..trca$p AS
/* $Header: 224270.1 tacpkgp.pkb 11.4.5.8 2013/05/10 carlos.sierra $ */

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  LF                     CONSTANT VARCHAR2(32767) := CHR(10); -- line feed
  CR                     CONSTANT VARCHAR2(32767) := CHR(13); -- carriage return
  BACK_SLASH             CONSTANT VARCHAR2(32767) := CHR(92); -- \
  USYS                   CONSTANT INTEGER := 0;
  CACHE_SIZE             CONSTANT INTEGER := 100;
  CHUNK_MAX_SIZE         CONSTANT INTEGER := 1024; -- 1024 results in better performance than larger values
  COMMIT_RATE            CONSTANT INTEGER := 10000; -- needed to report on parsing progress
  MAX_CURSOR_NUM_LEN     CONSTANT INTEGER := 7; -- 11.2.0.2 introduced long cursor numbers after 7309111: WAIT #18446744071465018768

  -- line type enumerator
  LT_UNKNOWN             CONSTANT INTEGER :=  1;
  LT_UNRECOGNIZED        CONSTANT INTEGER :=  2;
  LT_CLOB                CONSTANT INTEGER :=  3;
  LT_EMPTY               CONSTANT INTEGER :=  4;
  LT_SESSION             CONSTANT INTEGER :=  5;
  LT_GAP                 CONSTANT INTEGER :=  6;
  LT_TRUNCATION          CONSTANT INTEGER :=  7;
  LT_PARSING_SEPARATOR   CONSTANT INTEGER :=  8;
  LT_PARSING_IN_CURSOR   CONSTANT INTEGER :=  9;
  LT_STATEMENT           CONSTANT INTEGER := 10;
  LT_END_OF_STMT         CONSTANT INTEGER := 11;
  LT_PARSE               CONSTANT INTEGER := 12;
  LT_EXEC                CONSTANT INTEGER := 13;
  LT_FETCH               CONSTANT INTEGER := 14;
  LT_UNMAP               CONSTANT INTEGER := 15;
  LT_SORT_UNMAP          CONSTANT INTEGER := 16;
  LT_STAT                CONSTANT INTEGER := 17;
  LT_XCTEND              CONSTANT INTEGER := 18;
  LT_ERROR               CONSTANT INTEGER := 19;
  LT_PARSE_ERROR         CONSTANT INTEGER := 20;
  LT_BINDS               CONSTANT INTEGER := 21;
  LT_BIND_kkscoacd       CONSTANT INTEGER := 22;
  LT_BIND_bind1          CONSTANT INTEGER := 23;
  LT_BIND_Bind2          CONSTANT INTEGER := 24;
  LT_BIND_value          CONSTANT INTEGER := 25;
  LT_BIND_oacdty         CONSTANT INTEGER := 26;
  LT_BIND_oacflg         CONSTANT INTEGER := 27;
  LT_BIND_bfp            CONSTANT INTEGER := 28;
  LT_BIND_kxsbbbfp       CONSTANT INTEGER := 29;
  LT_BIND_value_CONT     CONSTANT INTEGER := 30;
  LT_BIND_oacdef         CONSTANT INTEGER := 31;
  LT_BIND_UNRECOGNIZED   CONSTANT INTEGER := 32;
  LT_WAIT                CONSTANT INTEGER := 33;
  LT_CLOSE               CONSTANT INTEGER := 34;
  LT_3_STARS             CONSTANT INTEGER := 35;

  /*************************************************************************************/

  /* -------------------------
   *
   * private static variables
   *
   * ------------------------- */
  -- line state
  s_line_type              INTEGER;
  s_line_offset            INTEGER;

  -- state for BINDS, STATEMENT, HEADER
  s_state_BINDS            BOOLEAN;
  s_state_BINDS_bind       BOOLEAN;
  s_state_BINDS_bind_value BOOLEAN;
  s_state_STATEMENT        BOOLEAN;
  s_state_STATEMENT_ERROR  BOOLEAN;

  -- file state
  s_session_id             INTEGER;
  s_gap_id                 INTEGER;
  s_cursor_num             INTEGER;
  s_cursor_id              INTEGER;
  s_statement_id           INTEGER;
  s_tim                    INTEGER;
  s_piece                  INTEGER;

  -- file state (cache)
  s_wait_id                INTEGER;
  s_bind_id                INTEGER;
  s_call_id                INTEGER;
  s_stat_id                INTEGER;
  s_curs_id                INTEGER;

  -- execution state
  s_event_name             trca$_event_name.name%TYPE;
  s_event#                 INTEGER;
  s_idle                   CHAR(1); -- Y/N
  s_event#_s               INTEGER; -- next event#

  -- file stats
  s_session_count          INTEGER;
  s_gap_count              INTEGER;
  s_transaction_count      INTEGER;
  s_cursor_count_sys       INTEGER;
  s_cursor_count_usr       INTEGER;
  s_statement_count_sys    INTEGER;
  s_statement_count_usr    INTEGER;
  s_wait_count_idle        INTEGER;
  s_wait_count_non_idle    INTEGER;
  s_wait_ela_idle          INTEGER;
  s_wait_ela_non_idle      INTEGER;
  s_bind_sets_count        INTEGER;
  s_bind_count             INTEGER;
  s_parse_call_count       INTEGER;
  s_exec_call_count        INTEGER;
  s_fetch_call_count       INTEGER;
  s_unmap_call_count       INTEGER;
  s_sort_unmap_call_count  INTEGER;
  s_call_ela               INTEGER;
  s_call_cpu               INTEGER;
  s_call_disk              INTEGER;
  s_call_query             INTEGER;
  s_call_current           INTEGER;
  s_call_misses            INTEGER;
  s_call_rows              INTEGER;
  s_stat_lines             INTEGER;
  s_error_lines            INTEGER;

  -- sql statement
  s_sql_text               VARCHAR2(32767);
  s_sql_fulltext           CLOB;

  -- global state
  s_single_trace           BOOLEAN;
  s_split_trace            BOOLEAN;
  s_analyze_trace          BOOLEAN;
  s_copy_10046             BOOLEAN;
  s_copy_10053             BOOLEAN;
  s_10046_trace_filename   VARCHAR2(32767);
  s_10053_trace_filename   VARCHAR2(32767);
  s_10046_file_rec         trca$_file%ROWTYPE;
  s_10053_file_rec         trca$_file%ROWTYPE;
  s_current_trace          INTEGER;
  s_dummy_group_id         INTEGER;

  /*************************************************************************************/

  /* -------------------------
   *
   * LINE cache
   *
   * ------------------------- */
  -- associative array
   TYPE line_cachetype IS
     TABLE OF NUMBER
     INDEX BY PLS_INTEGER;

  /* -------------------------
   *
   * WAIT cache
   *
   * ------------------------- */
  -- associative array
  TYPE wait_cachetype IS
    TABLE OF trca$_wait%ROWTYPE
    INDEX BY PLS_INTEGER; -- wait_id
  -- instance of associative array
  wait_cache wait_cachetype;
  wait_line_cache line_cachetype;

  /* -------------------------
   *
   * BIND cache
   *
   * ------------------------- */
  -- associative array
  TYPE bind_cachetype IS
    TABLE OF trca$_bind%ROWTYPE
    INDEX BY PLS_INTEGER; -- bind_id
  -- instance of associative array
  bind_cache bind_cachetype;
  bind_line_cache line_cachetype;

  /* -------------------------
   *
   * CALL cache
   *
   * ------------------------- */
  -- associative array
  TYPE call_cachetype IS
    TABLE OF trca$_call%ROWTYPE
    INDEX BY PLS_INTEGER; -- call_id
  -- instance of associative array
  call_cache call_cachetype;
  call_line_cache line_cachetype;

  /* -------------------------
   *
   * STAT cache
   *
   * ------------------------- */
  -- associative array
  TYPE stat_cachetype IS
    TABLE OF trca$_stat%ROWTYPE
    INDEX BY PLS_INTEGER; -- stat_id
  -- instance of associative array
  stat_cache stat_cachetype;
  stat_line_cache line_cachetype;

  /* -------------------------
   *
   * CURSOR cache
   *
   * ------------------------- */
  -- associative array
  TYPE curs_cachetype IS
    TABLE OF trca$_cursor%ROWTYPE
    INDEX BY PLS_INTEGER; -- curs_id
  -- instance of associative array
  curs_cache curs_cachetype;

  /*************************************************************************************/

  /* -------------------------
   *
   * SESSION associative array
   *
   * ------------------------- */
  TYPE session_rectype IS RECORD (
    sid                        INTEGER,
    serial#                    INTEGER,
    session_timestamp          TIMESTAMP,
    tim_first_wait             INTEGER,
    tim_first_call             INTEGER,
    read_only_committed        INTEGER,
    read_only_rollbacked       INTEGER,
    update_committed           INTEGER,
    update_rollbacked          INTEGER
  );
  -- associative array
  TYPE session_tabletype IS
    TABLE OF session_rectype
    INDEX BY PLS_INTEGER; -- session_id
  -- instance of associative array
  session_table session_tabletype;

  /* -------------------------
   *
   * GAP associative array
   *
   * ------------------------- */
  TYPE gap_rectype IS RECORD (
    gap_timestamp              TIMESTAMP,
    tim_before                 INTEGER,
    tim_after                  INTEGER,
    ela_after                  INTEGER,
    wait_call_after            CHAR(1),
    call_id_after              INTEGER
  );
  -- associative array
  TYPE gap_tabletype IS
    TABLE OF gap_rectype
    INDEX BY PLS_INTEGER; -- gap_id
  -- instance of associative array
  gap_table gap_tabletype;

  /* -------------------------
   *
   * CURSOR associative array
   *
   * ------------------------- */
  TYPE cursor_rectype IS RECORD (
    -- control
    id                         INTEGER, -- trca$_cursor.id
    statement_id               INTEGER, -- trca$_statement.id
    group_id                   INTEGER, -- id or statement_id as per g_aggregate
    exec_id                    INTEGER, -- cluster of calls (parse, exec, fetch)
    call                       CHAR(1), -- most recent call
    trace_line                 INTEGER, -- of cursor
    session_id                 INTEGER, -- out of *** SESSION ID:(23.10830)
    stat_line_seen             BOOLEAN, -- if a STAT line has been parsed
    -- parsed
    len                        INTEGER,
    dep                        INTEGER,
    uid#                       INTEGER,
    oct                        INTEGER,
    lid                        INTEGER,
    tim                        INTEGER,
    hv                         INTEGER,
    ad                         VARCHAR2(32),
    sqlid                      VARCHAR2(16),
    err                        INTEGER
  );
  -- associative array
  TYPE cursor_tabletype IS
    TABLE OF cursor_rectype
    INDEX BY PLS_INTEGER; -- cursor_num
  -- instance of associative array
  cursor_table cursor_tabletype;

  /* -------------------------
   *
   * STORED CURSOR associative array
   *
   * ------------------------- */
  -- associative array
  TYPE stored_cursor_tabletype IS
    TABLE OF BOOLEAN
    INDEX BY PLS_INTEGER; -- cursor_id
  -- instance of associative array
  stored_cursor_table stored_cursor_tabletype;

  /* -------------------------
   *
   * GROUP associative array
   *
   * ------------------------- */
  TYPE group_rectype IS RECORD (
    statement_id               INTEGER,
    first_cursor_id            INTEGER,
    uid#                       INTEGER,
    lid                        INTEGER,
    dep                        INTEGER,
    err                        INTEGER,
    first_exec_id              INTEGER,
    last_exec_id               INTEGER
  );
  -- associative array
  TYPE group_tabletype IS
    TABLE OF group_rectype
    INDEX BY PLS_INTEGER; -- group_id
  -- instance of associative array
  group_table group_tabletype;

  /* -------------------------
   *
   * CALL associative array
   * PARSE, EXEC, FETCH, UNMAP, SORT UNMAP
   *
   * ------------------------- */
  TYPE call_rectype IS RECORD (
    -- control
    id                         INTEGER,
    -- recursive waits metrics
    self_wait_count_idle       INTEGER,
    self_wait_count_non_idle   INTEGER,
    self_wait_ela_idle         INTEGER,
    self_wait_ela_non_idle     INTEGER
  );
  -- associative array
  TYPE call_tabletype IS
    TABLE OF call_rectype
    INDEX BY PLS_INTEGER; -- cursor_num
  -- instance of associative array
  call_table call_tabletype;

  /* -------------------------
   *
   * EVENT associative array
   *
   * ------------------------- */
  TYPE event_rectype IS RECORD (
    event#                     INTEGER, -- trca$_event_name.event# or next value
    wait_class                 VARCHAR2(64),
    idle                       CHAR(1), -- "Y" as per wait_class
    source                     CHAR(1), -- (V)iew, (T)trace
    parameter1v                trca$_event_name.parameter1%TYPE, -- sourced by trca$_event_name
    parameter2v                trca$_event_name.parameter2%TYPE, -- ditto
    parameter3v                trca$_event_name.parameter3%TYPE, -- ditto
    parameter1t                trca$_event_name.parameter1%TYPE, -- sourced by trace
    parameter2t                trca$_event_name.parameter2%TYPE, -- ditto
    parameter3t                trca$_event_name.parameter3%TYPE  -- ditto
  );
  -- associative array (indexed by event name)
  TYPE event_name_tabletype IS
    TABLE OF event_rectype
    INDEX BY trca$_event_name.name%TYPE; -- name
  -- instance of associative array
  event_name_table event_name_tabletype; -- access by name

  /* -------------------------
   *
   * DEP associative array
   *
   * ------------------------- */
  TYPE dep_rectype IS RECORD (
    dep_id                     INTEGER,
    -- recursive call metrics
    recu_c                     INTEGER,
    recu_e                     INTEGER,
    recu_p                     INTEGER,
    recu_cr                    INTEGER,
    recu_cu                    INTEGER,
    recu_call_count            INTEGER,
    recu_mis                   INTEGER,
    recu_r                     INTEGER,
    -- recursive waits metrics
    recu_wait_count_idle       INTEGER,
    recu_wait_count_non_idle   INTEGER,
    recu_wait_ela_idle         INTEGER,
    recu_wait_ela_non_idle     INTEGER
  );
  -- associative array (indexed by dep)
  TYPE dep_tabletype IS
    TABLE OF dep_rectype
    INDEX BY PLS_INTEGER; -- dep (depth)
  dep_table dep_tabletype;

  /*************************************************************************************/

  /* -------------------------
   *
   * PARSING IN CURSOR #6 len=14 dep=0 uid=2374 oct=46 lid=2374 tim=4715494390810000 hv=4050013488 ad='0'
   * PARSING IN CURSOR #5 len=210 dep=2 uid=0 oct=3 lid=0 tim=1181075145987884 hv=864012087 ad='5fd9ac84'
   * PARSING IN CURSOR #36 len=122 dep=1 uid=47 oct=3 lid=47 tim=1175904295910102 hv=3760497677 ad='67bd1504'
   * PARSING IN CURSOR #19 len=269 dep=2 uid=0 oct=3 lid=0 tim=1211894891974035 hv=2863336729 ad='38ef0b90' sqlid='6xrt7afpaq38t'
   *
   * PARSE ERROR #4:len=31 dep=0 uid=564 oct=3 lid=564 tim=1181540082847609 err=904
   *
   * ------------------------- */
  TYPE parsing_rectyp IS RECORD (
    -- parsed
    cursor_num                 INTEGER,
    len                        INTEGER,
    dep                        INTEGER,
    uid#                       INTEGER,
    oct                        INTEGER,
    lid                        INTEGER,
    tim                        INTEGER,
    hv                         INTEGER,
    ad                         VARCHAR2(32),
    sqlid                      VARCHAR2(16),
    err                        INTEGER
  );
  -- instance of record
  parsing_rec parsing_rectyp;

  /* -------------------------
   *
   * EXEC #21:c=6999,e=133973,p=0,cr=0,cu=0,mis=1,r=0,dep=1,og=4,plh=2593558949,tim=1228357926939267
   * FETCH #39:c=0,e=55,p=0,cr=4,cu=0,mis=0,r=1,dep=2,og=4,tim=1175904295913750
   * EXEC #39:c=0,e=131,p=0,cr=0,cu=0,mis=0,r=0,dep=2,og=4,tim=1175904295913674
   * PARSE #40:c=0,e=438,p=0,cr=0,cu=0,mis=1,r=0,dep=2,og=0,tim=1175904295912803
   * UNMAP #39:c=0,e=55,p=0,cr=4,cu=0,mis=0,r=1,dep=2,og=4,tim=1175904295913750
   * SORT UNMAP #39:c=0,e=55,p=0,cr=4,cu=0,mis=0,r=1,dep=2,og=4,tim=1175904295913750
   *
   * ------------------------- */
  TYPE call_rectyp IS RECORD (
    -- parsed
    call_name                  VARCHAR2(16),
    call                       CHAR(1), -- CALL enumerator
    cursor_num                 INTEGER,
    -- aggregate stats (this plus direct children)
    c                          INTEGER,
    e                          INTEGER,
    p                          INTEGER,
    cr                         INTEGER,
    cu                         INTEGER,
    -- non aggregate stats (this)
    mis                        INTEGER,
    r                          INTEGER,
    -- attributes
    dep                        INTEGER,
    og                         INTEGER,
    plh                        INTEGER,
    tim                        INTEGER,
    -- control
    call_id                    INTEGER,
    exec_id                    INTEGER,
    group_id                   INTEGER, -- denormalized
    cursor_id                  INTEGER, -- denormalized
    tool_execution_id          INTEGER, -- denormalized
    -- recursive control
    dep_id                     INTEGER, -- null if leaf (no children underneath)
    parent_dep_id              INTEGER, -- null if dep=0
    -- recursive call metrics (direct children)
    recu_c                     INTEGER,
    recu_e                     INTEGER,
    recu_p                     INTEGER,
    recu_cr                    INTEGER,
    recu_cu                    INTEGER,
    recu_call_count            INTEGER,
    recu_mis                   INTEGER,
    recu_r                     INTEGER,
    -- recursive waits metrics
    self_wait_count_idle       INTEGER,
    self_wait_count_non_idle   INTEGER,
    self_wait_ela_idle         INTEGER,
    self_wait_ela_non_idle     INTEGER,
    recu_wait_count_idle       INTEGER,
    recu_wait_count_non_idle   INTEGER,
    recu_wait_ela_idle         INTEGER,
    recu_wait_ela_non_idle     INTEGER
  );
  -- instance of record
  call_rec call_rectyp;

  /* -------------------------
   *
   * BINDS #8:
   *
   * ------------------------- */
  TYPE binds_rectyp IS RECORD (
    -- parsed
    cursor_num                 INTEGER,
    -- control
    exec_id                    INTEGER,
    group_id                   INTEGER, -- denormalized
    cursor_id                  INTEGER, -- denormalized
    tool_execution_id          INTEGER  -- denormalized
  );
  -- instance of record
  binds_rec binds_rectyp;

  /* -------------------------
   *
   * BINDS #80:
   *  bind 0: dty=1 mxl=32(30) mal=00 scl=00 pre=00 oacflg=13 oacfl2=1 size=96 offset=0
   *    bfp=b73093f4 bln=32 avl=30 flg=05
   *    value="SO_PRICE_ADJUSTMENTS_INTERFACE"
   *  bind 1: dty=1 mxl=32(02) mal=00 scl=00 pre=00 oacflg=13 oacfl2=1 size=0 offset=32
   *    bfp=b7309414 bln=32 avl=02 flg=01
   *    value="OE"
   *  bind 2: dty=1 mxl=32(11) mal=00 scl=00 pre=00 oacflg=13 oacfl2=1 size=0 offset=64
   *    bfp=b7309434 bln=32 avl=11 flg=01
   *    value="ATTRIBUTE10"
   * EXEC #80:c=0,e=135,p=0,cr=0,cu=0,mis=0,r=0,dep=1,og=4,tim=1175904330209402
   *
   * BINDS #3:
   *
   * kkscoacd
   *  Bind#0
   *   oacdty=02 mxl=22(22) mxlc=00 mal=00 scl=00 pre=00
   *   oacflg=08 fl2=0001 frm=00 csi=00 siz=24 off=0
   *   kxsbbbfp=8004aeb0  bln=22  avl=03  flg=05
   *   value=2374
   * EXEC #3:c=0,e=0,p=0,cr=0,cu=0,mis=0,r=0,dep=1,og=4,tim=4715494377600000
   *
   * BINDS #71:
   *  bind 0: dty=2 mxl=22(22) mal=00 scl=00 pre=00 oacflg=08 oacfl2=1 size=24 offset=0
   *    bfp=b731e260 bln=22 avl=04 flg=05
   *    value=146831
   *  bind 1: (No oacdef for this bind)
   * EXEC #71:c=0,e=99,p=0,cr=0,cu=0,mis=0,r=0,dep=1,og=4,tim=1175904330099065
   *
   * BINDS #3:
   *  bind 0: dty=1 mxl=32(02) mal=00 scl=00 pre=00 oacflg=13 oacfl2=b38f0000000001 size=32 offset=0
   *    bfp=8000000100172328 bln=32 avl=02 flg=09
   *    value="09"
   *
   * ------------------------- */
  TYPE bind_rectyp IS RECORD (
    -- parsed
    bind                       INTEGER,
    oacdef                     CHAR(1),
    oacdty                     INTEGER,
    mxl                        INTEGER,
    pmxl                       INTEGER,
    mxlc                       INTEGER,
    mal                        INTEGER,
    scl                        INTEGER,
    pre                        INTEGER,
    oacflg                     INTEGER,
    --oacf12                     INTEGER, oacfl2 can be b38f0000000001 on 9.2.0.6 HP-UX
    oacf12                     VARCHAR2(32),
    frm                        INTEGER,
    csi                        INTEGER,
    siz                        INTEGER,
    offset                     INTEGER,
    kxsbbbfp                   VARCHAR2(32),
    bln                        INTEGER,
    avl                        INTEGER,
    flg                        INTEGER,
    value                      VARCHAR2(4000)
  );
  -- instance of record
  bind_rec bind_rectyp;

  /* -------------------------
   *
   * WAIT #38: nam='db file sequential read' ela= 62484 p1=27 p2=26715 p3=1
   * WAIT #5: nam='db file scattered read' ela= 5396 file#=121 block#=89953 blocks=8 obj#=2038870 tim=1181075144916624
   * WAIT #8: nam='SQL*Net message from client' ela= 2000 driver id=1413697536 #bytes=1 p3=0 obj#=299132 tim=4715494390970000
   *
   * ------------------------- */
  TYPE wait_rectyp IS RECORD (
    -- parsed
    cursor_num                 INTEGER,
    nam                        trca$_event_name.name%TYPE,
    ela                        INTEGER,
    parameter1                 trca$_event_name.parameter1%TYPE,
    p1                         INTEGER,
    parameter2                 trca$_event_name.parameter2%TYPE,
    p2                         INTEGER,
    parameter3                 trca$_event_name.parameter3%TYPE,
    p3                         INTEGER,
    obj#                       INTEGER,
    tim                        INTEGER,
    -- event_name_table lookup
    event#                     INTEGER,
    idle                       CHAR(1), -- Y/N
    -- parent
    call_id                    INTEGER
  );
  -- instance of record
  wait_rec wait_rectyp;

  /* -------------------------
   *
   * STAT #43 id=1 cnt=0 pid=0 pos=1 obj=0 op='SORT ORDER BY '
   * STAT #43 id=2 cnt=0 pid=1 pos=1 obj=0 op='NESTED LOOPS  '
   * STAT #5 id=1 cnt=1 pid=0 pos=1 obj=20 op='TABLE ACCESS BY INDEX ROWID ICOL$ (cr=4 pr=1 pw=0 time=10000 us)'
   * STAT #5 id=2 cnt=1 pid=1 pos=1 obj=37 op='INDEX RANGE SCAN I_ICOL1 (cr=3 pr=1 pw=0 time=10000 us)'
   * STAT #6 id=1 cnt=1 pid=0 pos=1 obj=0 op='SORT ORDER BY (cr=7 pr=3 pw=3 time=0 us cost=11 size=327 card=3)'
   * STAT #11706540 id=2 cnt=9 pid=1 pos=1 obj=74954 op='TABLE ACCESS FULL CUSTOMER (cr=5 pr=0 pw=0 time=52 us cost=2 size=19899350 card=9707)'
   *
   * ------------------------- */
  TYPE stat_rectyp IS RECORD (
    -- parsed
    cursor_num                 INTEGER,
    id                         INTEGER,
    cnt                        INTEGER,
    pid                        INTEGER,
    pos                        INTEGER,
    obj                        INTEGER,
    op                         VARCHAR2(4000),
    cr                         INTEGER,
    pr                         INTEGER,
    pw                         INTEGER,
    time                       INTEGER,
    cost                       INTEGER,
    siz                        INTEGER,
    card                       INTEGER,
    -- control
    exec_id                    INTEGER,
    group_id                   INTEGER, -- denormalized
    cursor_id                  INTEGER, -- denormalized
    session_id                 INTEGER, -- denormalized
    tool_execution_id          INTEGER  -- denormalized
  );
  -- instance of record
  stat_rec stat_rectyp;

  /* -------------------------
   *
   * ERROR #1:err=1422 tim=2296528706
   *
   * ------------------------- */
  TYPE error_rectyp IS RECORD (
    -- parsed
    cursor_num                 INTEGER,
    err                        INTEGER,
    tim                        INTEGER,
    -- control
    exec_id                    INTEGER,
    group_id                   INTEGER, -- denormalized
    cursor_id                  INTEGER, -- denormalized
    tool_execution_id          INTEGER  -- denormalized
  );
  -- instance of record
  error_rec error_rectyp;

  /*************************************************************************************/

  /* -------------------------
   *
   * public set_nls
   *
   * ------------------------- */
  PROCEDURE set_nls
  IS
  BEGIN /* set_nls */
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,"';
    --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LENGTH_SEMANTICS = CHAR';
  END set_nls;

  /*************************************************************************************/

  /* -------------------------
   *
   * public purge_tool_execution_id
   *
   * ------------------------- */
  PROCEDURE purge_tool_execution_id (
    p_tool_execution_id IN INTEGER )
  IS
  BEGIN /* purge_tool_execution_id */
    DELETE trca$_cursor         WHERE tool_execution_id = p_tool_execution_id;
    COMMIT;
    DELETE trca$_wait           WHERE tool_execution_id = p_tool_execution_id;
    COMMIT;
    DELETE trca$_bind           WHERE tool_execution_id = p_tool_execution_id;
    COMMIT;
    DELETE trca$_stat           WHERE tool_execution_id = p_tool_execution_id;
    COMMIT;
    DELETE trca$_call           WHERE tool_execution_id = p_tool_execution_id;
    COMMIT;
    DELETE trca$_call_tree      WHERE tool_execution_id = p_tool_execution_id;
    COMMIT;
    DELETE trca$_exec_tree      WHERE tool_execution_id = p_tool_execution_id;
    COMMIT;
    DELETE trca$_genealogy_edge WHERE tool_execution_id = p_tool_execution_id;
    COMMIT;
    DELETE trca$_file           WHERE tool_execution_id = p_tool_execution_id;
    COMMIT;
  END purge_tool_execution_id;

  /*************************************************************************************/

  /* -------------------------
   *
   * public get_tool_execution_id
   *
   * ------------------------- */
  FUNCTION get_tool_execution_id
  RETURN INTEGER
  IS
    l_tool_execution_id INTEGER;
  BEGIN /* get_tool_execution_id */
    set_nls;
    trca$g.general_initialization;
    SELECT trca$_tool_execution_id_s.NEXTVAL INTO l_tool_execution_id FROM DUAL;
    INSERT INTO trca$_tool_execution (id) VALUES (l_tool_execution_id);
    RETURN l_tool_execution_id;
  END get_tool_execution_id;

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
    trca$g.print_log(p_buffer => p_line, p_package => 'P');
  END print_log;

  /*************************************************************************************/

  /* -------------------------
   *
   * flush_CURSOR_cache
   *
   * ------------------------- */
  PROCEDURE flush_CURSOR_cache
  IS
    bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT (bulk_errors, -24381);
  BEGIN /* flush_CURSOR_cache */
    IF s_curs_id > 0 AND curs_cache.COUNT > 0 THEN
      BEGIN
        FORALL i IN curs_cache.FIRST .. curs_cache.LAST
          SAVE EXCEPTIONS
            INSERT INTO trca$_cursor VALUES curs_cache(i);
      EXCEPTION
        WHEN bulk_errors THEN
          FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
          LOOP
            print_log('flush_CURSOR_cache: invalid cursor at line:'||curs_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).trace_line||' statement:"'||curs_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).statement_id||'" group:"'||curs_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).group_id||'" cursor:"'||curs_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).cursor_num||'" '||SQLERRM(-1 * SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
          END LOOP;
      END;

      curs_cache.DELETE;
      s_curs_id := 0;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Module: flush_CURSOR_cache');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_CURSOR_cache;

  /*************************************************************************************/

  /* -------------------------
   *
   * private flush_CURSOR
   *
   * ------------------------- */
  PROCEDURE flush_CURSOR (
    p_tool_execution_id IN INTEGER,
    p_trace_id          IN INTEGER,
    p_cursor_num        IN INTEGER )
  IS
    cur_rec trca$_cursor%ROWTYPE;

  BEGIN /* flush_CURSOR */
    IF NOT cursor_table.EXISTS(p_cursor_num) THEN
      RETURN;
    END IF;

    cur_rec                   := NULL;
    cur_rec.id                := cursor_table(p_cursor_num).id;
    cur_rec.tool_execution_id := p_tool_execution_id;
    cur_rec.trace_id          := p_trace_id;
    cur_rec.statement_id      := NVL(cursor_table(p_cursor_num).statement_id, -1); -- -1: Unknown
    cur_rec.group_id          := NVL(cursor_table(p_cursor_num).group_id, -1); -- -1: Unknown
    cur_rec.cursor_num        := p_cursor_num;
    cur_rec.dep               := NVL(cursor_table(p_cursor_num).dep, -1); -- -1: Unknown
    cur_rec.uid#              := NVL(cursor_table(p_cursor_num).uid#, -1); -- -1: Unknown
    cur_rec.lid               := NVL(cursor_table(p_cursor_num).lid, -1); -- -1: Unknown
    cur_rec.tim               := cursor_table(p_cursor_num).tim;
    cur_rec.ad                := cursor_table(p_cursor_num).ad;
    cur_rec.err               := cursor_table(p_cursor_num).err;
    cur_rec.session_id        := cursor_table(p_cursor_num).session_id;
    cur_rec.trace_line        := cursor_table(p_cursor_num).trace_line;

    IF cur_rec.id IS NOT NULL AND
       cur_rec.tool_execution_id IS NOT NULL AND
       cur_rec.trace_id IS NOT NULL AND
       cur_rec.statement_id IS NOT NULL AND
       cur_rec.group_id IS NOT NULL AND
       cur_rec.cursor_num IS NOT NULL AND
       cur_rec.dep IS NOT NULL AND
       cur_rec.uid# IS NOT NULL AND
       cur_rec.lid IS NOT NULL THEN
      IF NOT stored_cursor_table.EXISTS(cur_rec.id) THEN
        IF s_curs_id = CACHE_SIZE THEN
          flush_CURSOR_cache;
        END IF;

        s_curs_id := s_curs_id + 1;
        curs_cache(s_curs_id).id                := cur_rec.id;
        curs_cache(s_curs_id).tool_execution_id := cur_rec.tool_execution_id;
        curs_cache(s_curs_id).trace_id          := cur_rec.trace_id;
        curs_cache(s_curs_id).statement_id      := cur_rec.statement_id;
        curs_cache(s_curs_id).group_id          := cur_rec.group_id;
        curs_cache(s_curs_id).cursor_num        := cur_rec.cursor_num;
        curs_cache(s_curs_id).dep               := cur_rec.dep;
        curs_cache(s_curs_id).uid#              := cur_rec.uid#;
        curs_cache(s_curs_id).lid               := cur_rec.lid;
        curs_cache(s_curs_id).tim               := cur_rec.tim;
        curs_cache(s_curs_id).ad                := cur_rec.ad;
        curs_cache(s_curs_id).err               := cur_rec.err;
        curs_cache(s_curs_id).session_id        := cur_rec.session_id;
        curs_cache(s_curs_id).trace_line        := cur_rec.trace_line;

        stored_cursor_table(cur_rec.id)         := TRUE;
      END IF;
    ELSE
      print_log('invalid cursor skipped "'||cur_rec.statement_id||'" "'||cur_rec.group_id||'" "'||cur_rec.cursor_num||'"');
    END IF;

    cursor_table(p_cursor_num).stat_line_seen := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Module: flush_CURSOR');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_CURSOR;

  /*************************************************************************************/

  /* -------------------------
   *
   * flush_WAIT_cache
   *
   * ------------------------- */
  PROCEDURE flush_WAIT_cache
  IS
    bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT (bulk_errors, -24381);
  BEGIN /* flush_WAIT_cache */
    IF s_wait_id > 0 AND wait_cache.COUNT > 0 THEN
      BEGIN
        FORALL i IN wait_cache.FIRST .. wait_cache.LAST
          SAVE EXCEPTIONS
            INSERT INTO trca$_wait VALUES wait_cache(i);
      EXCEPTION
        WHEN bulk_errors THEN
          FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
          LOOP
            print_log('flush_WAIT_cache: invalid wait at line '||wait_line_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX)||' call_id:"'||wait_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).call_id||'" event#:"'||wait_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).event#||'" ela:"'||wait_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).ela||'" '||SQLERRM(-1 * SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
          END LOOP;
      END;

      wait_cache.DELETE;
      wait_line_cache.DELETE;
      s_wait_id := 0;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Module: flush_WAIT_cache');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_WAIT_cache;

  /*************************************************************************************/

  /* -------------------------
   *
   * flush_BIND_cache
   *
   * ------------------------- */
  PROCEDURE flush_BIND_cache
  IS
    bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT (bulk_errors, -24381);
  BEGIN /* flush_BIND_cache */
    IF s_bind_id > 0 AND bind_cache.COUNT > 0 THEN
      BEGIN
        FORALL i IN bind_cache.FIRST .. bind_cache.LAST
          SAVE EXCEPTIONS
            INSERT INTO trca$_bind VALUES bind_cache(i);
      EXCEPTION
        WHEN bulk_errors THEN
          FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
          LOOP
            print_log('flush_BIND_cache: invalid bind at line '||bind_line_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX)||' bind:"'||bind_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).bind||'" value:"'||bind_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).value||'" '||SQLERRM(-1 * SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
          END LOOP;
      END;

      bind_cache.DELETE;
      bind_line_cache.DELETE;
      s_bind_id := 0;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Module: flush_BIND_cache');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_BIND_cache;

  /*************************************************************************************/

  /* -------------------------
   *
   * flush_CALL_cache
   *
   * ------------------------- */
  PROCEDURE flush_CALL_cache
  IS
    bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT (bulk_errors, -24381);
  BEGIN /* flush_CALL_cache */
    IF s_call_id > 0 AND call_cache.COUNT > 0 THEN
      BEGIN
        FORALL i IN call_cache.FIRST .. call_cache.LAST
          SAVE EXCEPTIONS
            INSERT INTO trca$_call VALUES call_cache(i);
      EXCEPTION
        WHEN bulk_errors THEN
          FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
          LOOP
            print_log('flush_CALL_cache: invalid call at line '||call_line_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX)||' call_id:"'||call_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).id||'" exec_id:"'||call_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).exec_id||'" group_id:"'||call_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).group_id||'" call:"'||call_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).call||'" '||SQLERRM(-1 * SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
          END LOOP;
      END;

      call_cache.DELETE;
      call_line_cache.DELETE;
      s_call_id := 0;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Module: flush_CALL_cache');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_CALL_cache;

  /*************************************************************************************/

  /* -------------------------
   *
   * flush_STAT_cache
   *
   * ------------------------- */
  PROCEDURE flush_STAT_cache
  IS
    bulk_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT (bulk_errors, -24381);
  BEGIN /* flush_STAT_cache */
    IF s_stat_id > 0 AND stat_cache.COUNT > 0 THEN
      BEGIN
        FORALL i IN stat_cache.FIRST .. stat_cache.LAST
          SAVE EXCEPTIONS
            INSERT INTO trca$_stat VALUES stat_cache(i);
      EXCEPTION
        WHEN bulk_errors THEN
          FOR i IN 1 .. SQL%BULK_EXCEPTIONS.COUNT
          LOOP
            print_log('flush_STAT_cache: invalid stat at line '||stat_line_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX)||' exec_id:"'||stat_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).exec_id||'" group_id:"'||stat_cache(SQL%BULK_EXCEPTIONS(i).ERROR_INDEX).group_id||'" '||SQLERRM(-1 * SQL%BULK_EXCEPTIONS(i).ERROR_CODE));
          END LOOP;
      END;

      stat_cache.DELETE;
      stat_line_cache.DELETE;
      s_stat_id := 0;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Module: flush_STAT_cache');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_STAT_cache;

  /*************************************************************************************/

   /* -------------------------
   *
   * private parse_line
   *
   * ------------------------- */
  PROCEDURE parse_line (
    p_tool_execution_id IN OUT NOCOPY INTEGER,
    p_trace_id          IN OUT NOCOPY INTEGER,
    p_line_len          IN OUT NOCOPY INTEGER,
    p_line_number       IN OUT NOCOPY INTEGER,
    p_line_text         IN OUT NOCOPY VARCHAR2,
    p_line_clob         IN OUT NOCOPY CLOB )
  IS
    l_line_varchar VARCHAR2(32767);
    l_line_text    VARCHAR2(32767);
    l_line_clob    CLOB;
    l_line_len     INTEGER;

    /* -------------------------
     *
     * parse_line.get_line_type
     *
     * intended order is according to frequency
     * observed over several traces
     *
     * ------------------------- */
    FUNCTION get_line_type
    RETURN INTEGER
    IS
    BEGIN /* parse_line.get_line_type */
      IF l_line_clob IS NOT NULL THEN
        RETURN LT_CLOB;
      END IF;

      IF l_line_text LIKE 'WAIT #%' THEN
        RETURN LT_WAIT;
      END IF;

      IF l_line_text LIKE 'FETCH #%' THEN
        RETURN LT_FETCH;
      END IF;

      IF l_line_text LIKE 'EXEC #%' THEN
        RETURN LT_EXEC;
      END IF;

      IF l_line_text LIKE 'CLOSE #%' THEN
        RETURN LT_CLOSE;
      END IF;

      IF s_state_BINDS THEN
        IF l_line_text LIKE '   value=%' THEN -- 3 spaces
          RETURN LT_BIND_value;
        END IF;

        IF l_line_text LIKE '  value=%' THEN -- 2 spaces
          RETURN LT_BIND_value;
        END IF;

        IF l_line_text LIKE '  oacdty=%' THEN
          RETURN LT_BIND_oacdty;
        END IF;

        IF l_line_text LIKE '  oacflg=%' THEN
          RETURN LT_BIND_oacflg;
        END IF;

        IF l_line_text LIKE '   bfp=%' THEN
          RETURN LT_BIND_bfp;
        END IF;

        IF l_line_text LIKE '  kxsbbbfp=%' THEN
          RETURN LT_BIND_kxsbbbfp;
        END IF;

        IF l_line_text LIKE 'kkscoacd%' THEN
          RETURN LT_BIND_kkscoacd;
        END IF;

        IF l_line_text LIKE '  No oacdef for this bind.%' THEN
          RETURN LT_BIND_oacdef;
        END IF;

        IF l_line_text LIKE ' bind %' THEN
          RETURN LT_BIND_bind1;
        END IF;

        IF l_line_text LIKE ' Bind#%' THEN
          RETURN LT_BIND_Bind2;
        END IF;
      END IF;

      IF l_line_text LIKE 'BINDS #%' THEN
        RETURN LT_BINDS;
      END IF;

      IF l_line_text LIKE 'STAT #%' THEN
        RETURN LT_STAT;
      END IF;

      IF l_line_text LIKE 'PARSE #%' THEN
        RETURN LT_PARSE;
      END IF;

      IF l_line_text = '====================='||CR OR l_line_text = '====================='||LF THEN
        RETURN LT_PARSING_SEPARATOR;
      END IF;

      IF l_line_text LIKE 'PARSING IN CURSOR #%' THEN
        RETURN LT_PARSING_IN_CURSOR;
      END IF;

      IF l_line_text LIKE 'END OF STMT%' THEN
        RETURN LT_END_OF_STMT;
      END IF;

      IF l_line_text LIKE 'XCTEND rlbk=%' THEN
        RETURN LT_XCTEND;
      END IF;

      IF l_line_text LIKE 'UNMAP #%' THEN
        RETURN LT_UNMAP;
      END IF;

      IF l_line_text LIKE 'SORT UNMAP #%' THEN
        RETURN LT_SORT_UNMAP;
      END IF;

      IF l_line_text LIKE 'ERROR #%' THEN
        RETURN LT_ERROR;
      END IF;

      IF l_line_text LIKE 'PARSE ERROR #%' THEN
        RETURN LT_PARSE_ERROR;
      END IF;

      IF l_line_len < 2 THEN
        RETURN LT_EMPTY;
      END IF;

      IF l_line_text LIKE '*** 20%' THEN
        RETURN LT_GAP;
      END IF;

      IF l_line_text LIKE '*** SESSION ID:(%' THEN
        RETURN LT_SESSION;
      END IF;

      IF l_line_text LIKE '*** DUMP%' THEN
        RETURN LT_TRUNCATION;
      END IF;

      IF l_line_text LIKE '*** %' THEN
        IF l_line_text LIKE '*** CLIENT%' OR
           l_line_text LIKE '*** SERVICE%' OR
           l_line_text LIKE '*** MODULE%' OR
           l_line_text LIKE '*** ACTION%' OR
           l_line_text LIKE '*** TRACE%' THEN
          RETURN LT_3_STARS;
        ELSE
          RETURN LT_UNRECOGNIZED;
        END IF;
      END IF;

      RETURN LT_UNRECOGNIZED;
    END get_line_type;

    /* -------------------------
     *
     * parse_line.get_char
     *
     * ------------------------- */
    FUNCTION get_char (
      p_suffix IN VARCHAR2 )
    RETURN VARCHAR2
    IS
      l_result VARCHAR2(32767);
      l_begin_suffix INTEGER;

    BEGIN /* parse_line.get_char */
      IF p_suffix IS NULL OR s_line_offset >= l_line_len THEN
        RETURN NULL;
      END IF;

      l_begin_suffix := INSTR(l_line_text, p_suffix, s_line_offset);

      IF l_begin_suffix = 0 THEN
        RETURN NULL; -- not found
      END IF;

      l_result := SUBSTR(l_line_text, s_line_offset, (l_begin_suffix - s_line_offset));
      s_line_offset := s_line_offset + NVL(LENGTH(l_result), 0) + LENGTH(p_suffix);

      RETURN l_result;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** p_suffix:'||p_suffix);
        print_log('*** l_begin_suffix:'||l_begin_suffix);
        print_log('*** l_result:'||l_result);
        print_log('*** s_line_offset: '||s_line_offset);
        print_log('*** Module: get_char');
        print_log('*** '||SQLERRM);
        RAISE;
    END get_char;

    /* -------------------------
     *
     * parse_line.get_integer
     *
     * ------------------------- */
    FUNCTION get_integer (
      p_suffix IN VARCHAR2,
      p_max_len IN INTEGER DEFAULT 126 )
    RETURN INTEGER
    IS
      l_value VARCHAR2(32767);
      l_len INTEGER;
    BEGIN /* parse_line.get_integer */
      --RETURN TRUNC(TO_NUMBER(get_char(p_suffix => p_suffix)));
      l_value := get_char(p_suffix => p_suffix);
      l_len := LENGTH(l_value);
      IF l_len > p_max_len THEN
        l_value := SUBSTR(l_value, l_len - p_max_len + 1);
      END IF;
      RETURN TRUNC(TO_NUMBER(l_value));
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** p_suffix:'||p_suffix);
        print_log('*** s_line_offset: '||s_line_offset);
        print_log('*** Module: get_integer');
        print_log('*** '||SQLERRM);
        RAISE;
    END get_integer;

    /* -------------------------
     *
     * parse_line.initialize_cursor
     *
     * ------------------------- */
    PROCEDURE initialize_cursor
    IS
    BEGIN /* parse_line.initialize_cursor */
      cursor_table(s_cursor_num) := NULL; -- initialize new element (rebirth)
      cursor_table(s_cursor_num).stat_line_seen := FALSE;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: initialize_cursor');
        print_log('*** '||SQLERRM);
        RAISE;
    END initialize_cursor;

    /* -------------------------
     *
     * parse_line.update_cursor_id
     *
     * cursor_id can be null after cursor has
     * been created by PARSING, BINDS or WAIT
     *
     * ------------------------- */
    PROCEDURE update_cursor_id
    IS
    BEGIN /* parse_line.update_cursor_id */
      IF cursor_table(s_cursor_num).id IS NULL THEN
        SELECT trca$_cursor_id_s.NEXTVAL INTO cursor_table(s_cursor_num).id FROM DUAL;
      END IF;
      s_cursor_id := cursor_table(s_cursor_num).id;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: update_cursor_id');
        print_log('*** '||SQLERRM);
        RAISE;
    END update_cursor_id;

    /* -------------------------
     *
     * parse_line.update_cursor_state
     *
     * cursor state may change with
     * SESSION and XCTEND.
     * cursors will inherit session
     * and transaction ids.
     *
     * ------------------------- */
    PROCEDURE update_cursor_state
    IS
    BEGIN /* parse_line.update_cursor_state */
      cursor_table(s_cursor_num).session_id      := s_session_id;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: update_cursor_state');
        print_log('*** '||SQLERRM);
        RAISE;
    END update_cursor_state;

    /* -------------------------
     *
     * parse_line.get_call_id
     *
     * call_id for given cursor_num is created
     * into collection when needed by WAIT or bind.
     * it is deleted when the actual CALL
     * grabs its own id from collection.
     *
     * ------------------------- */
    FUNCTION get_call_id (
      p_cursor_num IN INTEGER )
    RETURN INTEGER
    IS
    BEGIN /* parse_line.get_call_id */
      IF NOT call_table.EXISTS(p_cursor_num) THEN
        SELECT trca$_call_id_s.NEXTVAL INTO call_table(p_cursor_num).id FROM DUAL;
        call_table(p_cursor_num).self_wait_count_idle     := 0;
        call_table(p_cursor_num).self_wait_count_non_idle := 0;
        call_table(p_cursor_num).self_wait_ela_idle       := 0;
        call_table(p_cursor_num).self_wait_ela_non_idle   := 0;
      END IF;

      RETURN call_table(p_cursor_num).id;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: get_call_id');
        print_log('*** '||SQLERRM);
        RAISE;
    END get_call_id;

    /* -------------------------
     *
     * parse_line.set_exec_id
     *
     * exec_id is a grouping id for a set
     * of calls (parse, exec, fetch)
     *
     * ------------------------- */
    PROCEDURE set_exec_id (
      p_cursor_num IN INTEGER )
    IS
    BEGIN /* parse_line.set_exec_id */
      SELECT trca$_exec_id_s.NEXTVAL INTO cursor_table(p_cursor_num).exec_id FROM DUAL;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: set_exec_id');
        print_log('*** '||SQLERRM);
        RAISE;
    END set_exec_id;

    /* -------------------------
     *
     * parse_line.set_first_exec_id
     *
     * ------------------------- */
    PROCEDURE set_first_exec_id (
      p_cursor_num IN INTEGER )
    IS
    BEGIN /* parse_line.set_first_exec_id */
      IF cursor_table(p_cursor_num).group_id IS NOT NULL THEN
        IF NOT group_table.EXISTS(cursor_table(p_cursor_num).group_id) THEN
          group_table(cursor_table(p_cursor_num).group_id).statement_id := cursor_table(p_cursor_num).statement_id;
          group_table(cursor_table(p_cursor_num).group_id).first_cursor_id := cursor_table(p_cursor_num).id;
          group_table(cursor_table(p_cursor_num).group_id).uid# := cursor_table(p_cursor_num).uid#;
          group_table(cursor_table(p_cursor_num).group_id).lid := cursor_table(p_cursor_num).lid;
          group_table(cursor_table(p_cursor_num).group_id).dep := cursor_table(p_cursor_num).dep;
          group_table(cursor_table(p_cursor_num).group_id).err := cursor_table(p_cursor_num).err;
          group_table(cursor_table(p_cursor_num).group_id).first_exec_id := cursor_table(p_cursor_num).exec_id;
        ELSIF group_table(cursor_table(p_cursor_num).group_id).first_exec_id IS NULL THEN
          group_table(cursor_table(p_cursor_num).group_id).first_exec_id := cursor_table(p_cursor_num).exec_id;
        END IF;
        group_table(cursor_table(p_cursor_num).group_id).last_exec_id := cursor_table(p_cursor_num).exec_id;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: set_first_exec_id');
        print_log('*** '||SQLERRM);
        RAISE;
    END set_first_exec_id;

    /* -------------------------
     *
     * parse_line.parse_PARSING_IN_CURSOR
     *
     * PARSING IN CURSOR #6 len=14 dep=0 uid=2374 oct=46 lid=2374 tim=4715494390810000 hv=4050013488 ad='0'
     * PARSING IN CURSOR #5 len=210 dep=2 uid=0 oct=3 lid=0 tim=1181075145987884 hv=864012087 ad='5fd9ac84'
     * PARSING IN CURSOR #36 len=122 dep=1 uid=47 oct=3 lid=47 tim=1175904295910102 hv=3760497677 ad='67bd1504'
     * PARSING IN CURSOR #19 len=269 dep=2 uid=0 oct=3 lid=0 tim=1211894891974035 hv=2863336729 ad='38ef0b90' sqlid='6xrt7afpaq38t'
     *
     * ------------------------- */
    PROCEDURE parse_PARSING_IN_CURSOR
    IS
    BEGIN /* parse_line.parse_PARSING_IN_CURSOR */
      IF s_analyze_trace THEN
        s_line_offset          := 20;
        parsing_rec            := NULL;
        parsing_rec.cursor_num := get_integer(' len=', MAX_CURSOR_NUM_LEN);
        parsing_rec.len        := get_integer(' dep=');
        parsing_rec.dep        := get_integer(' uid=');
        parsing_rec.uid#       := get_integer(' oct=');
        parsing_rec.oct        := get_integer(' lid=');
        parsing_rec.lid        := get_integer(' tim=');
        parsing_rec.tim        := get_integer(' hv=');
        parsing_rec.hv         := get_integer(' ad=''');
        parsing_rec.ad         := get_char(''' sqlid='''); -- 11g+
        IF parsing_rec.ad IS NULL THEN -- < 11g
          parsing_rec.ad         := get_char(''''||LF);
        ELSE -- 11g+
          parsing_rec.sqlid    := get_char(''''||LF);
          trca$g.g_sqlid       := 'Y'; -- used by reports
        END IF;

        -- update file stats
        IF parsing_rec.uid# = USYS THEN
          s_cursor_count_sys := s_cursor_count_sys + 1;
        ELSIF parsing_rec.uid# > USYS THEN
          s_cursor_count_usr := s_cursor_count_usr + 1;
        END IF;

        --print_log(l_line_text);
        --print_log('PARSING IN CURSOR #'||parsing_rec.cursor_num||' len='||parsing_rec.len||' dep='||parsing_rec.dep||' uid='||parsing_rec.uid#||' oct='||parsing_rec.oct||' lid='||parsing_rec.lid||' tim='||parsing_rec.tim||' hv='||parsing_rec.hv||' ad='''||parsing_rec.ad||''' sqlid='''||parsing_rec.sqlid||'''');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** PARSING IN CURSOR #'||parsing_rec.cursor_num||' len='||parsing_rec.len||' dep='||parsing_rec.dep||' uid='||parsing_rec.uid#||' oct='||parsing_rec.oct||' lid='||parsing_rec.lid||' tim='||parsing_rec.tim||' hv='||parsing_rec.hv||' ad='''||parsing_rec.ad||''' sqlid='''||parsing_rec.sqlid||'''');
        print_log('*** Module: parse_PARSING_IN_CURSOR');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_PARSING_IN_CURSOR;

    /* -------------------------
     *
     * parse_line.process_PARSING_IN_CURSOR
     *
     * if there is a cursor_id for given cursor_num then
     *   if it already has a statement_id then
     *     flush it and intiliaize element
     *   else
     *     use existing element
     * else
     *   initialize element
     *
     * ------------------------- */
    PROCEDURE process_PARSING_IN_CURSOR
    IS
    BEGIN /* parse_line.process_PARSING_IN_CURSOR */
      IF s_analyze_trace THEN
        IF parsing_rec.cursor_num IS NULL THEN
          RETURN; -- abnormal file truncation
        END IF;

        -- state
        s_cursor_num := parsing_rec.cursor_num;

        IF cursor_table.EXISTS(s_cursor_num) THEN
          IF cursor_table(s_cursor_num).statement_id IS NOT NULL THEN -- recycle
            flush_CURSOR ( -- store prior cursor using same cursor_num
              p_tool_execution_id => p_tool_execution_id,
              p_trace_id          => p_trace_id,
              p_cursor_num        => s_cursor_num );
            initialize_cursor;
          ELSE -- pre-created by a WAIT or BINDS
            NULL; -- use existing element
          END IF;
        ELSE -- first time, never used
          initialize_cursor;
        END IF;

        update_cursor_id;
        update_cursor_state;

        -- control
        cursor_table(s_cursor_num).trace_line      := p_line_number + 1; -- statement starts in the next line
        cursor_table(s_cursor_num).stat_line_seen  := FALSE;

        -- parsed
        cursor_table(s_cursor_num).len             := parsing_rec.len;
        cursor_table(s_cursor_num).dep             := parsing_rec.dep;
        cursor_table(s_cursor_num).uid#            := parsing_rec.uid#;
        cursor_table(s_cursor_num).oct             := parsing_rec.oct;
        cursor_table(s_cursor_num).lid             := parsing_rec.lid;
        cursor_table(s_cursor_num).tim             := parsing_rec.tim;
        cursor_table(s_cursor_num).hv              := parsing_rec.hv;
        cursor_table(s_cursor_num).ad              := parsing_rec.ad;
        cursor_table(s_cursor_num).sqlid           := parsing_rec.sqlid;
        cursor_table(s_cursor_num).err             := parsing_rec.err;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: process_PARSING_IN_CURSOR');
        print_log('*** '||SQLERRM);
        RAISE;
    END process_PARSING_IN_CURSOR;

    /* -------------------------
     *
     * parse_line.process_STATEMENT
     *
     * ------------------------- */
    PROCEDURE process_STATEMENT
    IS
    BEGIN /* parse_line.process_STATEMENT */
      IF s_analyze_trace THEN
        IF l_line_clob IS NOT NULL THEN -- big line
          SYS.DBMS_LOB.APPEND (
            dest_lob => s_sql_fulltext,
            src_lob  => l_line_clob );
        ELSE -- small line
          SYS.DBMS_LOB.WRITEAPPEND (
            lob_loc => s_sql_fulltext,
            amount  => l_line_len,
            buffer  => l_line_text );
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: process_STATEMENT');
        print_log('*** '||SQLERRM);
        RAISE;
    END process_STATEMENT;

    /* -------------------------
     *
     * parse_line.process_END_OF_STMT
     *
     * END OF STMT
     *
     * ------------------------- */
    PROCEDURE process_END_OF_STMT
    IS
      sql_rec trca$_statement%ROWTYPE;
      l_compare_result INTEGER := -1;
    BEGIN /* parse_line.process_END_OF_STMT */
      IF s_analyze_trace THEN
        FOR i IN (SELECT id, sql_text, sql_fulltext
                    FROM trca$_statement
                   WHERE len                = parsing_rec.len
                     AND hv                 = parsing_rec.hv
                     AND NVL(sqlid, '-666') = NVL(parsing_rec.sqlid, '-666')
                     AND oct                = parsing_rec.oct)
        LOOP
          l_compare_result := SYS.DBMS_LOB.COMPARE (
            lob_1 => s_sql_fulltext,
            lob_2 => i.sql_fulltext );

          IF l_compare_result = 0 THEN -- found it!
            s_statement_id := i.id;
            s_sql_text     := i.sql_text;
            EXIT;
          END IF;
        END LOOP;

        IF l_compare_result <> 0 THEN -- none found
          s_sql_text := SYS.DBMS_LOB.SUBSTR (
            lob_loc => s_sql_fulltext,
            amount  => 1000 );

          SELECT trca$_statement_id_s.NEXTVAL INTO s_statement_id FROM DUAL; -- new SQL statement

          IF s_statement_id IS NOT NULL AND
            parsing_rec.len IS NOT NULL AND
            parsing_rec.hv IS NOT NULL AND
            parsing_rec.oct IS NOT NULL AND
            s_sql_text IS NOT NULL AND
            s_sql_fulltext IS NOT NULL THEN

            INSERT INTO trca$_statement (
              id,
              len,
              hv,
              sqlid,
              oct,
              sql_text,
              sql_fulltext
            ) VALUES (
              s_statement_id,
              parsing_rec.len,
              parsing_rec.hv,
              parsing_rec.sqlid,
              parsing_rec.oct,
              s_sql_text,
              s_sql_fulltext
            );
          ELSE
            print_log('invalid statement at line '||p_line_number||' "'||s_statement_id||'" "'||parsing_rec.hv||'" "'||SUBSTR(s_sql_text, 1, 100)||'"');
          END IF;
        END IF;

        -- update cursor state
        cursor_table(s_cursor_num).statement_id := s_statement_id;
        IF trca$g.g_aggregate = 'Y' THEN
          cursor_table(s_cursor_num).group_id := s_statement_id;
        ELSE
          cursor_table(s_cursor_num).group_id := s_cursor_id;
        END IF;

        -- create group record in memory
        IF NOT group_table.EXISTS(cursor_table(s_cursor_num).group_id) THEN
          group_table(cursor_table(s_cursor_num).group_id).statement_id := cursor_table(s_cursor_num).statement_id;
          group_table(cursor_table(s_cursor_num).group_id).first_cursor_id := s_cursor_id;
          group_table(cursor_table(s_cursor_num).group_id).uid# := cursor_table(s_cursor_num).uid#;
          group_table(cursor_table(s_cursor_num).group_id).lid := cursor_table(s_cursor_num).lid;
          group_table(cursor_table(s_cursor_num).group_id).dep := cursor_table(s_cursor_num).dep;
          group_table(cursor_table(s_cursor_num).group_id).err := cursor_table(s_cursor_num).err;
          group_table(cursor_table(s_cursor_num).group_id).first_exec_id := NULL;
          group_table(cursor_table(s_cursor_num).group_id).last_exec_id := NULL;
        END IF;

        --print_log('id='||s_statement_id||' sql_text='||SUBSTR(s_sql_text, 1, 100));
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** id='||s_statement_id||' sql_text='||SUBSTR(s_sql_text, 1, 100));
        print_log('*** Module: process_END_OF_STMT');
        print_log('*** '||SQLERRM);
        RAISE;
    END process_END_OF_STMT;

    /* -------------------------
     *
     * parse_line.parse_PARSE_ERROR
     *
     * PARSE ERROR #4:len=31 dep=0 uid=564 oct=3 lid=564 tim=1181559630466515 err=904
     *
     * ------------------------- */
    PROCEDURE parse_PARSE_ERROR
    IS
    BEGIN /* parse_line.parse_PARSE_ERROR */
      IF s_analyze_trace THEN
        s_line_offset          := 14;
        parsing_rec            := NULL;
        parsing_rec.cursor_num := get_integer(':len=', MAX_CURSOR_NUM_LEN);
        parsing_rec.len        := get_integer(' dep=');
        parsing_rec.dep        := get_integer(' uid=');
        parsing_rec.uid#       := get_integer(' oct=');
        parsing_rec.oct        := get_integer(' lid=');
        parsing_rec.lid        := get_integer(' tim=');
        parsing_rec.tim        := get_integer(' err=');
        parsing_rec.hv         := -1;
        parsing_rec.sqlid      := '-1';
        parsing_rec.err        := get_integer(LF);

        -- update file stats
        IF parsing_rec.uid# = USYS THEN
          s_cursor_count_sys := s_cursor_count_sys + 1;
        ELSIF parsing_rec.uid# > USYS THEN
          s_cursor_count_usr := s_cursor_count_usr + 1;
        END IF;

        --print_log(l_line_text);
        --print_log('PARSE ERROR #'||parsing_rec.cursor_num||' len='||parsing_rec.len||' dep='||parsing_rec.dep||' uid='||parsing_rec.uid#||' oct='||parsing_rec.oct||' lid='||parsing_rec.lid||' tim='||parsing_rec.tim||' err='||parsing_rec.err);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** PARSE ERROR #'||parsing_rec.cursor_num||' len='||parsing_rec.len||' dep='||parsing_rec.dep||' uid='||parsing_rec.uid#||' oct='||parsing_rec.oct||' lid='||parsing_rec.lid||' tim='||parsing_rec.tim||' err='||parsing_rec.err);
        print_log('*** Module: parse_PARSE_ERROR');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_PARSE_ERROR;

    /* -------------------------
     *
     * parse_line.parse_BINDS
     *
     * BINDS #8:
     *
     * ------------------------- */
    PROCEDURE parse_BINDS
    IS
    BEGIN /* parse_line.parse_BINDS */
      IF s_analyze_trace THEN
        s_line_offset        := 8;
        binds_rec            := NULL;
        binds_rec.cursor_num := get_integer(':'||LF, MAX_CURSOR_NUM_LEN);

        --print_log(l_line_text);
        --print_log('BINDS #'||binds_rec.cursor_num||':');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: parse_BINDS');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_BINDS;

    /* -------------------------
     *
     * parse_line.process_BINDS
     *
     * if there is a cursor_id for given cursor_num then
     *   if it has seen a STAT line then
     *     flush it and intiliaize cursor_id since binds could be for new cursor
     *   else
     *     use existing element
     * else
     *   initialize element
     *
     * ------------------------- */
    PROCEDURE process_BINDS
    IS
    BEGIN /* parse_line.process_BINDS */
      IF s_analyze_trace THEN
        IF binds_rec.cursor_num IS NULL THEN
          RETURN; -- abnormal file truncation
        END IF;

        -- state
        s_cursor_num := binds_rec.cursor_num;

        IF cursor_table.EXISTS(s_cursor_num) THEN
          IF cursor_table(s_cursor_num).stat_line_seen THEN -- recycle
            flush_CURSOR ( -- store prior cursor using same cursor_num
              p_tool_execution_id => p_tool_execution_id,
              p_trace_id          => p_trace_id,
              p_cursor_num        => s_cursor_num );
            --initialize_cursor;
            cursor_table(s_cursor_num).id := NULL;
          ELSE -- pre-created by a PARSING or WAIT
            NULL; -- use existing element
          END IF;
        ELSE -- first time, never used
          initialize_cursor;
        END IF;

        update_cursor_id;
        update_cursor_state;

        -- control
        IF cursor_table(s_cursor_num).exec_id IS NULL THEN
          set_exec_id (p_cursor_num => s_cursor_num);
        ELSIF cursor_table(s_cursor_num).call = trca$g.CALL_PARSE THEN
          NULL;
        ELSE
          set_exec_id (p_cursor_num => s_cursor_num);
        END IF;
        cursor_table(s_cursor_num).call := trca$g.CALL_BINDS;
        set_first_exec_id (p_cursor_num => s_cursor_num);
        IF cursor_table(s_cursor_num).trace_line IS NULL THEN
          cursor_table(s_cursor_num).trace_line := p_line_number; -- statement will override line
        END IF;

        binds_rec.exec_id := cursor_table(s_cursor_num).exec_id;
        binds_rec.group_id := cursor_table(s_cursor_num).group_id; -- denormalized
        binds_rec.cursor_id := s_cursor_id; -- denormalized
        binds_rec.tool_execution_id := p_tool_execution_id; -- denormalized
        s_bind_sets_count := s_bind_sets_count + 1;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: process_BINDS');
        print_log('*** '||SQLERRM);
        RAISE;
    END process_BINDS;

    /* -------------------------
     *
     * parse_line.parse_WAIT
     *
     * WAIT #38: nam='db file sequential read' ela= 62484 p1=27 p2=26715 p3=1
     * WAIT #5: nam='db file scattered read' ela= 5396 file#=121 block#=89953 blocks=8 obj#=2038870 tim=1181075144916624
     * WAIT #8: nam='SQL*Net message from client' ela= 2000 driver id=1413697536 #bytes=1 p3=0 obj#=299132 tim=4715494390970000
     *
     * ------------------------- */
    PROCEDURE parse_WAIT
    IS
      wait_rec_parameter4 VARCHAR2(32767);
      wait_rec_parameter5 VARCHAR2(32767);
      wait_rec_p4         INTEGER;
      wait_rec_p5         INTEGER;

    BEGIN /* parse_line.parse_WAIT */
      IF s_analyze_trace THEN
        s_line_offset       := 7;
        wait_rec            := NULL;
        wait_rec.cursor_num := get_integer(': nam=''', MAX_CURSOR_NUM_LEN);
        wait_rec.nam        := get_char(''' ela= ');

        wait_rec.ela        := get_integer(' ');
        IF wait_rec.ela IS NULL THEN
          wait_rec.ela      := get_integer(LF);
        END IF;
        wait_rec.ela        := NVL(wait_rec.ela, 0);

        wait_rec.parameter1 := get_char('=');
        wait_rec.p1         := get_integer(' ');
        IF wait_rec.p1 IS NULL THEN
          wait_rec.p1       := get_integer(LF);
        END IF;

        wait_rec.parameter2 := get_char('=');
        wait_rec.p2         := get_integer(' ');
        IF wait_rec.p2 IS NULL THEN
          wait_rec.p2       := get_integer(LF);
        END IF;

        wait_rec.parameter3 := get_char('=');
        wait_rec.p3         := get_integer(' ');
        IF wait_rec.p3 IS NULL THEN
          wait_rec.p3      := get_integer(LF);
        END IF;

        wait_rec_parameter4 := get_char('=');
        wait_rec_p4         := get_integer(' ');
        IF wait_rec_p4 IS NULL THEN
          wait_rec_p4       := get_integer(LF);
        END IF;

        wait_rec_parameter5 := get_char('=');
        wait_rec_p5         := get_integer(LF);

        IF wait_rec_parameter5 = 'tim' THEN -- full house, perfect!
          wait_rec.obj#         := wait_rec_p4;
          wait_rec.tim          := wait_rec_p5;
        ELSIF wait_rec_parameter4 = 'tim' THEN -- p3 or obj# are missing
          wait_rec.tim          := wait_rec_p4;
          IF wait_rec.parameter3 = 'obj#' THEN -- p3 is missing
            wait_rec.obj#       := wait_rec.p3;
            wait_rec.parameter3 := 'p3';
            wait_rec.p3         := NULL;
          ELSE -- obj# is missing
            wait_rec.obj#       := NULL;
          END IF;
        ELSIF wait_rec.parameter3 = 'tim' THEN -- p2 or obj# are missing
          wait_rec.tim          := wait_rec.p3;
          wait_rec.parameter3 := 'p3';
          wait_rec.p3         := NULL;
          IF wait_rec.parameter2 = 'obj#' THEN -- p2 is missing
            wait_rec.obj#       := wait_rec.p2;
            wait_rec.parameter2 := 'p2';
            wait_rec.p2         := NULL;
          ELSE -- obj# is missing
            wait_rec.obj#       := NULL;
          END IF;
        ELSIF wait_rec.parameter2 = 'tim' THEN -- p1 or obj# are missing
          wait_rec.tim          := wait_rec.p2;
          wait_rec.parameter2 := 'p2';
          wait_rec.p2         := NULL;
          wait_rec.parameter3 := 'p3';
          wait_rec.p3         := NULL;
          IF wait_rec.parameter1 = 'obj#' THEN -- p1 is missing
            wait_rec.obj#       := wait_rec.p1;
            wait_rec.parameter1 := 'p1';
            wait_rec.p1         := NULL;
          ELSE -- obj# is missing
            wait_rec.obj#       := NULL;
          END IF;
        ELSIF wait_rec.parameter1 = 'tim' THEN -- obj# is missing
          wait_rec.tim          := wait_rec.p1;
          wait_rec.obj#         := NULL;
          wait_rec.parameter1 := 'p1';
          wait_rec.p1         := NULL;
          wait_rec.parameter2 := 'p2';
          wait_rec.p2         := NULL;
          wait_rec.parameter3 := 'p3';
          wait_rec.p3         := NULL;
        ELSIF wait_rec_parameter4 = 'obj#' THEN -- tim is missing
          wait_rec.obj#         := wait_rec_p4;
          wait_rec.tim          := NULL;
        ELSIF wait_rec.parameter3 = 'obj#' THEN -- tim and p3 are missing
          wait_rec.obj#         := wait_rec.p3;
          wait_rec.tim          := NULL;
          wait_rec.parameter3   := 'p3';
          wait_rec.p3           := NULL;
        ELSIF wait_rec.parameter2 = 'obj#' THEN -- tim, p3 and p2 are missing
          wait_rec.obj#         := wait_rec.p2;
          wait_rec.tim          := NULL;
          wait_rec.parameter2   := 'p2';
          wait_rec.p2           := NULL;
          wait_rec.parameter3   := 'p3';
          wait_rec.p3           := NULL;
        ELSIF wait_rec.parameter1 = 'obj#' THEN -- tim, p3, p2 and p1 are missing
          wait_rec.obj#         := wait_rec.p1;
          wait_rec.tim          := NULL;
          wait_rec.parameter1   := 'p1';
          wait_rec.p1           := NULL;
          wait_rec.parameter2   := 'p2';
          wait_rec.p2           := NULL;
          wait_rec.parameter3   := 'p3';
          wait_rec.p3           := NULL;
        ELSIF wait_rec.parameter3 IS NULL THEN -- tim, obj# and p3 are missing
          wait_rec.obj#         := NULL;
          wait_rec.tim          := NULL;
          wait_rec.parameter3   := 'p3';
          wait_rec.p3           := NULL;
        ELSIF wait_rec.parameter2 IS NULL THEN -- tim, obj#, p3, and p2 are missing
          wait_rec.obj#         := NULL;
          wait_rec.tim          := NULL;
          wait_rec.parameter2   := 'p2';
          wait_rec.p2           := NULL;
          wait_rec.parameter3   := 'p3';
          wait_rec.p3           := NULL;
        ELSIF wait_rec.parameter1 IS NULL THEN -- tim, obj#, p3, p2 and p1 are missing
          wait_rec.obj#         := NULL;
          wait_rec.tim          := NULL;
          wait_rec.parameter1   := 'p1';
          wait_rec.p1           := NULL;
          wait_rec.parameter2   := 'p2';
          wait_rec.p2           := NULL;
          wait_rec.parameter3   := 'p3';
          wait_rec.p3           := NULL;
        END IF;

        --print_log(l_line_text);
        --IF wait_rec.obj# IS NULL AND wait_rec.tim IS NULL THEN
        --  print_log('WAIT #'||wait_rec.cursor_num||': nam='''||wait_rec.nam||''' ela= '||wait_rec.ela||' '||wait_rec.parameter1||'='||wait_rec.p1||' '||wait_rec.parameter2||'='||wait_rec.p2||' '||wait_rec.parameter3||'='||wait_rec.p3);
        --ELSE
        --  print_log('WAIT #'||wait_rec.cursor_num||': nam='''||wait_rec.nam||''' ela= '||wait_rec.ela||' '||wait_rec.parameter1||'='||wait_rec.p1||' '||wait_rec.parameter2||'='||wait_rec.p2||' '||wait_rec.parameter3||'='||wait_rec.p3||' obj#='||wait_rec.obj#||' tim='||wait_rec.tim);
        --END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** WAIT #'||wait_rec.cursor_num||': nam='''||wait_rec.nam||''' ela= '||wait_rec.ela||' '||wait_rec.parameter1||'='||wait_rec.p1||' '||wait_rec.parameter2||'='||wait_rec.p2||' '||wait_rec.parameter3||'='||wait_rec.p3||' obj#='||wait_rec.obj#||' tim='||wait_rec.tim);
        print_log('*** Module: parse_WAIT');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_WAIT;

    /* -------------------------
     *
     * parse_line.event_name_WAIT_lookup
     *
     * if event name is found in cache
     *   return event# and idle flag
     * else
     *   if event name is not found in collection
     *     register parameter names found in trace
     *     if event name is found in global lookp table trca$_event_name
     *       store in collection: event#, wait class, idle flag, source (V), and parameter names
     *     else
     *       create into collection: new element and make it non-idle (source T)
     *   take event# and idle flag from collection
     *   update cache with: event name, event# and idle flag
     *
     * ------------------------- */
    PROCEDURE event_name_WAIT_lookup
    IS
      nam_rec trca$_event_name%ROWTYPE;

    BEGIN /* parse_line.event_name_WAIT_lookup */
      IF s_analyze_trace THEN
        IF wait_rec.nam = s_event_name THEN -- take value from cache
          NULL;
        ELSE -- take value from collection (s_event_name could be null)
          IF NOT event_name_table.EXISTS(wait_rec.nam) THEN -- create
            --print_log('register event "'||wait_rec.nam||'" found at line '||p_line_number);
            event_name_table(wait_rec.nam).parameter1t   := wait_rec.parameter1;
            event_name_table(wait_rec.nam).parameter2t   := wait_rec.parameter2;
            event_name_table(wait_rec.nam).parameter3t   := wait_rec.parameter3;

            BEGIN
              SELECT * INTO nam_rec FROM trca$_event_name WHERE name = wait_rec.nam AND ROWNUM = 1;
            EXCEPTION
              WHEN OTHERS THEN
                nam_rec := NULL;
            END;

            IF nam_rec.name = wait_rec.nam THEN -- found in trca$_event_name (v$event_name)
              --print_log('"'|wait_rec.nam||'" found in trca$_event_name');
              event_name_table(wait_rec.nam).event#      := nam_rec.event#;
              event_name_table(wait_rec.nam).wait_class  := nam_rec.wait_class;
              event_name_table(wait_rec.nam).idle        := nam_rec.idle;
              event_name_table(wait_rec.nam).source      := 'V';
              event_name_table(wait_rec.nam).parameter1v := nam_rec.parameter1;
              event_name_table(wait_rec.nam).parameter2v := nam_rec.parameter2;
              event_name_table(wait_rec.nam).parameter3v := nam_rec.parameter3;
            ELSE -- not found, create new one based on trace
              print_log('"'||wait_rec.nam||'" not found in trca$_event_name');
              s_event#_s := s_event#_s + 1;
              event_name_table(wait_rec.nam).event#      := s_event#_s;
              event_name_table(wait_rec.nam).wait_class  := 'Unknown';
              event_name_table(wait_rec.nam).idle        := 'N';
              event_name_table(wait_rec.nam).source      := 'T';
              event_name_table(wait_rec.nam).parameter1v := NULL;
              event_name_table(wait_rec.nam).parameter2v := NULL;
              event_name_table(wait_rec.nam).parameter3v := NULL;
            END IF;
          END IF;

          -- update cache
          s_event_name := wait_rec.nam;
          s_event#     := event_name_table(wait_rec.nam).event#;
          s_idle       := event_name_table(wait_rec.nam).idle;
        END IF;

        -- take value from cache
        wait_rec.event#     := s_event#;
        wait_rec.idle       := s_idle;

        -- update file stats
        IF wait_rec.idle = 'Y' THEN
          s_wait_count_idle := s_wait_count_idle + 1;
          s_wait_ela_idle   := s_wait_ela_idle + NVL(wait_rec.ela, 0);
        ELSIF wait_rec.idle = 'N' THEN
          s_wait_count_non_idle := s_wait_count_non_idle + 1;
          s_wait_ela_non_idle   := s_wait_ela_non_idle + NVL(wait_rec.ela, 0);
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Event: '||wait_rec.nam);
        print_log('*** Module: event_name_WAIT_lookup');
        print_log('*** '||SQLERRM);
        RAISE;
    END event_name_WAIT_lookup;

    /* -------------------------
     *
     * parse_line.rollup_WAIT
     *
     * ------------------------- */
    PROCEDURE rollup_WAIT
    IS
    BEGIN /* parse_line.rollup_WAIT */
      IF s_analyze_trace THEN
        IF wait_rec.idle = 'Y' THEN
          call_table(s_cursor_num).self_wait_count_idle := call_table(s_cursor_num).self_wait_count_idle + 1;
          call_table(s_cursor_num).self_wait_ela_idle   := call_table(s_cursor_num).self_wait_ela_idle + NVL(wait_rec.ela, 0);
        ELSIF wait_rec.idle = 'N' THEN
          call_table(s_cursor_num).self_wait_count_non_idle := call_table(s_cursor_num).self_wait_count_non_idle + 1;
          call_table(s_cursor_num).self_wait_ela_non_idle   := call_table(s_cursor_num).self_wait_ela_non_idle + NVL(wait_rec.ela, 0);
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: rollup_WAIT');
        print_log('*** '||SQLERRM);
        RAISE;
    END rollup_WAIT;

    /* -------------------------
     *
     * parse_line.store_WAIT
     *
     * ------------------------- */
    PROCEDURE store_WAIT
    IS
    BEGIN /* parse_line.store_WAIT */
      IF s_analyze_trace THEN
        IF wait_rec.call_id IS NOT NULL AND
           wait_rec.event# IS NOT NULL AND
           wait_rec.ela  IS NOT NULL THEN

          IF trca$g.g_include_waits = 'Y' THEN
            IF s_wait_id = CACHE_SIZE THEN
              flush_WAIT_cache;
            END IF;

            s_wait_id := s_wait_id + 1;
            wait_cache(s_wait_id).call_id           := wait_rec.call_id;
            wait_cache(s_wait_id).event#            := wait_rec.event#;
            wait_cache(s_wait_id).tool_execution_id := p_tool_execution_id;
            wait_cache(s_wait_id).ela               := wait_rec.ela;
            wait_cache(s_wait_id).p1                := wait_rec.p1;
            wait_cache(s_wait_id).p2                := wait_rec.p2;
            wait_cache(s_wait_id).p3                := wait_rec.p3;
            wait_cache(s_wait_id).obj#              := wait_rec.obj#;
            wait_cache(s_wait_id).tim               := wait_rec.tim;

            wait_line_cache(s_wait_id)              := p_line_number;
          END IF;
        ELSE
          print_log('store_WAIT: invalid wait at line:'||p_line_number||' cal_id:"'||wait_rec.call_id||'" event#:"'||wait_rec.event#||'" ela:"'||wait_rec.ela||'"');
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: store_WAIT');
        print_log('*** '||SQLERRM);
        RAISE;
    END store_WAIT;

    /* -------------------------
     *
     * parse_line.process_WAIT
     *
     * if there is a cursor_id for given cursor_num then
     *   if it has seen a STAT line then
     *     flush it and intiliaize stat_line_seen to false
     *   else
     *     use existing element
     * else
     *   initialize element
     *
     * ------------------------- */
    PROCEDURE process_WAIT
    IS
    BEGIN /* parse_line.process_WAIT */
      IF s_analyze_trace THEN
        IF wait_rec.cursor_num IS NULL OR wait_rec.nam IS NULL OR NVL(wait_rec.ela, -1) < 0 THEN
          RETURN; -- abnormal file truncation
        END IF;

        -- state
        s_cursor_num := wait_rec.cursor_num;

        IF cursor_table.EXISTS(s_cursor_num) THEN -- pre-created by a PARSING or BINDS
          IF cursor_table(s_cursor_num).stat_line_seen THEN -- recycle
            flush_CURSOR ( -- store prior cursor using same cursor_num
              p_tool_execution_id => p_tool_execution_id,
              p_trace_id          => p_trace_id,
              p_cursor_num        => s_cursor_num );
            -- initialize_cursor;
          ELSE
            NULL; -- use existing element
          END IF;
        ELSE -- first time, never used
          initialize_cursor;
        END IF;

        update_cursor_id;
        update_cursor_state;

        -- control
        IF cursor_table(s_cursor_num).trace_line IS NULL THEN
          cursor_table(s_cursor_num).trace_line := p_line_number; -- statement will override line
        END IF;

        -- parsed
        IF cursor_table(s_cursor_num).tim IS NULL AND wait_rec.tim IS NOT NULL THEN
          cursor_table(s_cursor_num).tim := wait_rec.tim;
        END IF;

        event_name_WAIT_lookup;
        IF wait_rec.event# IS NOT NULL THEN
          wait_rec.call_id := get_call_id(p_cursor_num => s_cursor_num);
          IF wait_rec.call_id IS NOT NULL THEN
            rollup_WAIT;
            store_WAIT;
          END IF;
        END IF;

        -- tim
        IF wait_rec.tim IS NOT NULL THEN
          s_tim := wait_rec.tim;
          -- session
          IF s_session_id IS NOT NULL THEN
            IF session_table(s_session_id).tim_first_wait IS NULL THEN
              session_table(s_session_id).tim_first_wait := wait_rec.tim - wait_rec.ela;
            END IF;
          END IF;
          -- gap
          IF  s_gap_id IS NOT NULL THEN
            IF gap_table(s_gap_id).tim_after IS NULL AND wait_rec.tim IS NOT NULL THEN
              gap_table(s_gap_id).tim_after       := wait_rec.tim;
              gap_table(s_gap_id).ela_after       := wait_rec.ela;
              gap_table(s_gap_id).wait_call_after := 'W';
              gap_table(s_gap_id).call_id_after   := wait_rec.call_id;
            END IF;
          END IF;
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: process_WAIT');
        print_log('*** '||SQLERRM);
        RAISE;
    END process_WAIT;

    /* -------------------------
     *
     * parse_line.parse_CALL
     *
     * EXEC #21:c=6999,e=133973,p=0,cr=0,cu=0,mis=1,r=0,dep=1,og=4,plh=2593558949,tim=1228357926939267
     * FETCH #39:c=0,e=55,p=0,cr=4,cu=0,mis=0,r=1,dep=2,og=4,tim=1175904295913750
     * EXEC #39:c=0,e=131,p=0,cr=0,cu=0,mis=0,r=0,dep=2,og=4,tim=1175904295913674
     * PARSE #40:c=0,e=438,p=0,cr=0,cu=0,mis=1,r=0,dep=2,og=0,tim=1175904295912803
     * UNMAP #39:c=0,e=55,p=0,cr=4,cu=0,mis=0,r=1,dep=2,og=4,tim=1175904295913750
     * SORT UNMAP #39:c=0,e=55,p=0,cr=4,cu=0,mis=0,r=1,dep=2,og=4,tim=1175904295913750
     *
     * ------------------------- */
    PROCEDURE parse_CALL
    IS
    BEGIN /* parse_line.parse_CALL */
      IF s_analyze_trace THEN
        s_line_offset       := LENGTH(call_rec.call_name) + 3;
        call_rec.cursor_num := get_integer(':c=', MAX_CURSOR_NUM_LEN);
        call_rec.c          := NVL(get_integer(',e='), 0);
        call_rec.e          := NVL(get_integer(',p='), 0);
        call_rec.p          := NVL(get_integer(',cr='), 0);
        call_rec.cr         := NVL(get_integer(',cu='), 0);
        call_rec.cu         := NVL(get_integer(',mis='), 0);
        call_rec.mis        := NVL(get_integer(',r='), 0);
        call_rec.r          := NVL(get_integer(',dep='), 0);
        call_rec.dep        := get_integer(',og=');
        call_rec.og         := get_integer(',plh='); -- 11.1.0.7+
        IF call_rec.og IS NULL THEN -- 11.1.0.6-
          call_rec.og         := get_integer(',tim=');
        ELSE -- 11.1.0.7+
          call_rec.plh        := get_integer(',tim=');
          trca$g.g_plh        := 'Y'; -- used by reports
        END IF;
        call_rec.tim        := get_integer(LF);

        --print_log(l_line_text);
        --print_log(call_rec.call_name||' #'||call_rec.cursor_num||':c='||call_rec.c||',e='||call_rec.e||',p='||call_rec.p||',cr='||call_rec.cr||',cu='||call_rec.cu||',mis='||call_rec.mis||',r='||call_rec.r||',dep='||call_rec.dep||',og='||call_rec.og||',plh='||call_rec.plh||',tim='||call_rec.tim);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** '||call_rec.call_name||' #'||call_rec.cursor_num||':c='||call_rec.c||',e='||call_rec.e||',p='||call_rec.p||',cr='||call_rec.cr||',cu='||call_rec.cu||',mis='||call_rec.mis||',r='||call_rec.r||',dep='||call_rec.dep||',og='||call_rec.og||',plh='||call_rec.plh||',tim='||call_rec.tim);
        print_log('*** Module: parse_CALL');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_CALL;

    /* -------------------------
     *
     * parse_line.lookup_DEP_CALL
     *
     * lookup dep
     *   if found
     *     grab dep_id as dep_id
     *     --delete from varray (deferred)
     * if dep > 0
     *   generate dep_id for parents up to root
     *   grab dep_id for parent_dep_id
     *
     * ------------------------- */
    PROCEDURE lookup_DEP_CALL
    IS
      l_dep INTEGER;
    BEGIN /* parse_line.lookup_DEP_CALL */
      IF s_analyze_trace THEN
        call_rec.dep_id        := NULL;
        call_rec.parent_dep_id := NULL;

        IF dep_table.EXISTS(call_rec.dep) THEN -- root or branch
          call_rec.dep_id := dep_table(call_rec.dep).dep_id;
          --dep_table.DELETE(call_rec.dep); -- deferred
        END IF;

        IF call_rec.dep > 0 THEN -- branch or leaf
          l_dep := call_rec.dep - 1;
          WHILE l_dep >= 0
          LOOP
            IF NOT dep_table.EXISTS(l_dep) THEN -- create new element
              SELECT trca$_dep_id_s.NEXTVAL INTO dep_table(l_dep).dep_id FROM DUAL;
              -- recursive call metrics
              dep_table(l_dep).recu_c                   := 0;
              dep_table(l_dep).recu_e                   := 0;
              dep_table(l_dep).recu_p                   := 0;
              dep_table(l_dep).recu_cr                  := 0;
              dep_table(l_dep).recu_cu                  := 0;
              dep_table(l_dep).recu_call_count          := 0;
              dep_table(l_dep).recu_mis                 := 0;
              dep_table(l_dep).recu_r                   := 0;
              -- recursive waits metrics
              dep_table(l_dep).recu_wait_count_idle     := 0;
              dep_table(l_dep).recu_wait_count_non_idle := 0;
              dep_table(l_dep).recu_wait_ela_idle       := 0;
              dep_table(l_dep).recu_wait_ela_non_idle   := 0;
            END IF;
            l_dep := l_dep - 1;
          END LOOP;
          call_rec.parent_dep_id := dep_table(call_rec.dep - 1).dep_id;
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: lookup_DEP_CALL');
        print_log('*** '||SQLERRM);
        RAISE;
    END lookup_DEP_CALL;

    /* -------------------------
     *
     * parse_line.rollup_CALL
     *
     * calls have two types of aggragates: self and recursive.
     * self aggregates contain ela from waits associated to call.
     * recursive aggragates contain (self + recu) from calls
     * below the recursive call tree (dep > than own).
     *
     * ------------------------- */
    PROCEDURE rollup_CALL
    IS
      l_group_id      INTEGER;
      l_group_id_call VARCHAR2(16);
      l_dep           INTEGER;

    BEGIN /* parse_line.rollup_CALL */
      IF s_analyze_trace THEN
        IF call_rec.dep IS NULL THEN
          RETURN;
        END IF;

        -- waits associated directly with this call
        -- pulls values from the call memory table, which was seeded by waits caused by this call
        call_rec.self_wait_count_idle     := call_table(s_cursor_num).self_wait_count_idle;
        call_rec.self_wait_count_non_idle := call_table(s_cursor_num).self_wait_count_non_idle;
        call_rec.self_wait_ela_idle       := call_table(s_cursor_num).self_wait_ela_idle;
        call_rec.self_wait_ela_non_idle   := call_table(s_cursor_num).self_wait_ela_non_idle;

        -- pull recursive calls that were aggregated by nodes below in the dependency tree (dep > self)
        IF call_rec.dep_id IS NOT NULL THEN -- root or branch calls pull aggregates from recursive calls
          -- recursive call metrics (for children just one level down)
          -- pulls values from dependency table, which was seeded by direct recursive calls of this one
          -- this is so because these source columns are already recursive, so we don't do recursive over recursive
          call_rec.recu_c          := dep_table(call_rec.dep).recu_c;
          call_rec.recu_e          := dep_table(call_rec.dep).recu_e;
          call_rec.recu_p          := dep_table(call_rec.dep).recu_p;
          call_rec.recu_cr         := dep_table(call_rec.dep).recu_cr;
          call_rec.recu_cu         := dep_table(call_rec.dep).recu_cu;
          call_rec.recu_call_count := dep_table(call_rec.dep).recu_call_count;
          call_rec.recu_mis        := dep_table(call_rec.dep).recu_mis;
          call_rec.recu_r          := dep_table(call_rec.dep).recu_r;
          -- recursive waits metrics (for all children below them)
          -- these columns in the dependencies memory table contain recursive values
          -- stored into dependencies memory table by corresponding children with dep > own
          call_rec.recu_wait_count_idle     := dep_table(call_rec.dep).recu_wait_count_idle;
          call_rec.recu_wait_count_non_idle := dep_table(call_rec.dep).recu_wait_count_non_idle;
          call_rec.recu_wait_ela_idle       := dep_table(call_rec.dep).recu_wait_ela_idle;
          call_rec.recu_wait_ela_non_idle   := dep_table(call_rec.dep).recu_wait_ela_non_idle;
        ELSE -- leaf calls do not have anything to pull from, but self
          call_rec.recu_c                   := 0;
          call_rec.recu_e                   := 0;
          call_rec.recu_p                   := 0;
          call_rec.recu_cr                  := 0;
          call_rec.recu_cu                  := 0;
          call_rec.recu_call_count          := 0;
          call_rec.recu_mis                 := 0;
          call_rec.recu_r                   := 0;
          call_rec.recu_wait_count_idle     := 0;
          call_rec.recu_wait_count_non_idle := 0;
          call_rec.recu_wait_ela_idle       := 0;
          call_rec.recu_wait_ela_non_idle   := 0;
        END IF;

        -- push recursive calls to level up in dependency tree (dep - 1)
        IF call_rec.parent_dep_id IS NOT NULL THEN -- branch and leaf calls push self and recursive aggregates one level up (dep - 1)
          -- recursive call metrics add themselves to own parent, by doing so they implicitly add their own
          -- recursive values bacause these metrics (c, e, p, cr, cu) are already recursive.
          dep_table(call_rec.dep - 1).recu_c  := dep_table(call_rec.dep - 1).recu_c  + call_rec.c;
          dep_table(call_rec.dep - 1).recu_e  := dep_table(call_rec.dep - 1).recu_e  + call_rec.e;
          dep_table(call_rec.dep - 1).recu_p  := dep_table(call_rec.dep - 1).recu_p  + call_rec.p;
          dep_table(call_rec.dep - 1).recu_cr := dep_table(call_rec.dep - 1).recu_cr + call_rec.cr;
          dep_table(call_rec.dep - 1).recu_cu := dep_table(call_rec.dep - 1).recu_cu + call_rec.cu;

          -- affect all parents up
          -- since count, mis and r are not recursive themselves, they need to affect all parents
          -- up the dependency tree, adding themselves to each level up
          l_dep := call_rec.dep - 1;
          WHILE l_dep >= 0
          LOOP
            dep_table(l_dep).recu_call_count := dep_table(l_dep).recu_call_count + 1;
            dep_table(l_dep).recu_mis        := dep_table(l_dep).recu_mis + call_rec.mis;
            dep_table(l_dep).recu_r          := dep_table(l_dep).recu_r + call_rec.r;
            l_dep := l_dep - 1;
          END LOOP;

         -- recursive waits metrics (add themselves recursively to parent)
         -- a call takes these "self" plus "recu" values and adds them up to their parent call
          dep_table(call_rec.dep - 1).recu_wait_count_idle     := dep_table(call_rec.dep - 1).recu_wait_count_idle     + call_rec.self_wait_count_idle     + call_rec.recu_wait_count_idle;
          dep_table(call_rec.dep - 1).recu_wait_count_non_idle := dep_table(call_rec.dep - 1).recu_wait_count_non_idle + call_rec.self_wait_count_non_idle + call_rec.recu_wait_count_non_idle;
          dep_table(call_rec.dep - 1).recu_wait_ela_idle       := dep_table(call_rec.dep - 1).recu_wait_ela_idle       + call_rec.self_wait_ela_idle       + call_rec.recu_wait_ela_idle;
          dep_table(call_rec.dep - 1).recu_wait_ela_non_idle   := dep_table(call_rec.dep - 1).recu_wait_ela_non_idle   + call_rec.self_wait_ela_non_idle   + call_rec.recu_wait_ela_non_idle;
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: rollup_CALL');
        print_log('*** '||SQLERRM);
        RAISE;
    END rollup_CALL;

    /* -------------------------
     *
     * parse_line.store_CALL
     *
     * ------------------------- */
    PROCEDURE store_CALL
    IS
    BEGIN /* parse_line.store_CALL */
      IF s_analyze_trace THEN
        IF call_rec.call_id IS NOT NULL AND
           call_rec.exec_id IS NOT NULL AND
           call_rec.group_id IS NOT NULL AND
           call_rec.tool_execution_id IS NOT NULL AND
           call_rec.call IS NOT NULL THEN

          IF s_call_id = CACHE_SIZE THEN
            flush_CALL_cache;
          END IF;

          s_call_id := s_call_id + 1;
          call_cache(s_call_id).id                       := call_rec.call_id;
          call_cache(s_call_id).exec_id                  := call_rec.exec_id;
          call_cache(s_call_id).group_id                 := call_rec.group_id;
          --call_cache(s_call_id).cursor_id                := call_rec.cursor_id;
          call_cache(s_call_id).tool_execution_id        := call_rec.tool_execution_id;
          call_cache(s_call_id).call                     := call_rec.call;
          call_cache(s_call_id).c                        := call_rec.c;
          call_cache(s_call_id).e                        := call_rec.e;
          call_cache(s_call_id).p                        := call_rec.p;
          call_cache(s_call_id).cr                       := call_rec.cr;
          call_cache(s_call_id).cu                       := call_rec.cu;
          call_cache(s_call_id).mis                      := call_rec.mis;
          call_cache(s_call_id).r                        := call_rec.r;
          call_cache(s_call_id).dep                      := call_rec.dep;
          --call_cache(s_call_id).og                       := call_rec.og; -- irrelevant
          call_cache(s_call_id).plh                      := call_rec.plh;
          call_cache(s_call_id).tim                      := call_rec.tim;
          call_cache(s_call_id).dep_id                   := call_rec.dep_id;
          call_cache(s_call_id).parent_dep_id            := call_rec.parent_dep_id;
          call_cache(s_call_id).recu_c                   := call_rec.recu_c;
          call_cache(s_call_id).recu_e                   := call_rec.recu_e;
          call_cache(s_call_id).recu_p                   := call_rec.recu_p;
          call_cache(s_call_id).recu_cr                  := call_rec.recu_cr;
          call_cache(s_call_id).recu_cu                  := call_rec.recu_cu;
          call_cache(s_call_id).recu_call_count          := call_rec.recu_call_count;
          call_cache(s_call_id).recu_mis                 := call_rec.recu_mis;
          call_cache(s_call_id).recu_r                   := call_rec.recu_r;
          call_cache(s_call_id).self_wait_count_idle     := call_rec.self_wait_count_idle;
          call_cache(s_call_id).self_wait_count_non_idle := call_rec.self_wait_count_non_idle;
          call_cache(s_call_id).self_wait_ela_idle       := call_rec.self_wait_ela_idle;
          call_cache(s_call_id).self_wait_ela_non_idle   := call_rec.self_wait_ela_non_idle;
          call_cache(s_call_id).recu_wait_count_idle     := call_rec.recu_wait_count_idle;
          call_cache(s_call_id).recu_wait_count_non_idle := call_rec.recu_wait_count_non_idle;
          call_cache(s_call_id).recu_wait_ela_idle       := call_rec.recu_wait_ela_idle;
          call_cache(s_call_id).recu_wait_ela_non_idle   := call_rec.recu_wait_ela_non_idle;

          call_line_cache(s_call_id)                     := p_line_number;
        ELSE
          print_log('invalid call at line '||p_line_number||' "'||call_rec.call_id||'" "'||call_rec.exec_id||'" "'||call_rec.group_id||'" "'||call_rec.call||'"');
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: store_CALL');
        print_log('*** '||SQLERRM);
        RAISE;
    END store_CALL;

    /* -------------------------
     *
     * parse_line.process_CALL
     *
     * if there is a cursor_id for given cursor_num then
     *   if it has seen a STAT line then
     *     flush it and intiliaize stat_line_seen to false
     *   else
     *     use existing element
     * else
     *   initialize element
     *
     * ------------------------- */
    PROCEDURE process_CALL
    IS
    BEGIN /* parse_line.process_CALL */
      IF s_analyze_trace THEN
        IF call_rec.cursor_num IS NULL OR call_rec.call IS NULL THEN
          RETURN; -- abnormal file truncation
        END IF;

        -- state
        s_cursor_num := call_rec.cursor_num;

        IF cursor_table.EXISTS(s_cursor_num) THEN -- pre-created by a PARSING or BINDS
          IF cursor_table(s_cursor_num).stat_line_seen THEN -- recycle
            flush_CURSOR ( -- store prior cursor using same cursor_num
              p_tool_execution_id => p_tool_execution_id,
              p_trace_id          => p_trace_id,
              p_cursor_num        => s_cursor_num );
            --initialize_cursor;
          ELSE
            NULL; -- use existing element
          END IF;
        ELSE -- first time, never used
          initialize_cursor;
        END IF;

        update_cursor_id;
        update_cursor_state;

        -- assign call_id from collection
        call_rec.call_id := get_call_id(p_cursor_num => s_cursor_num);

        -- control
        IF cursor_table(s_cursor_num).exec_id IS NULL THEN
          set_exec_id (p_cursor_num => s_cursor_num);
        ELSIF call_rec.call = trca$g.CALL_PARSE THEN
          IF cursor_table(s_cursor_num).call = trca$g.CALL_BINDS THEN
            NULL;
          ELSE
            set_exec_id (p_cursor_num => s_cursor_num);
          END IF;
        ELSIF call_rec.call = trca$g.CALL_EXEC THEN
          IF cursor_table(s_cursor_num).call IN (trca$g.CALL_BINDS, trca$g.CALL_PARSE) THEN
            NULL;
          ELSE
            set_exec_id (p_cursor_num => s_cursor_num);
          END IF;
        END IF;
        set_first_exec_id (p_cursor_num => s_cursor_num);
        cursor_table(s_cursor_num).call := call_rec.call;
        IF cursor_table(s_cursor_num).trace_line IS NULL THEN
          cursor_table(s_cursor_num).trace_line := p_line_number; -- statement will override line
        END IF;

        -- parsed
        IF cursor_table(s_cursor_num).tim IS NULL AND call_rec.tim IS NOT NULL THEN
          cursor_table(s_cursor_num).tim := call_rec.tim;
        END IF;

        call_rec.exec_id := cursor_table(s_cursor_num).exec_id;
        --call_rec.group_id := cursor_table(s_cursor_num).group_id; -- denormalized
        call_rec.group_id := NVL(cursor_table(s_cursor_num).group_id, s_cursor_id); -- denormalized
        call_rec.cursor_id := s_cursor_id; -- denormalized
        call_rec.tool_execution_id := p_tool_execution_id; -- denormalized
        IF call_rec.dep IS NOT NULL THEN
          lookup_DEP_CALL;
        END IF;
        rollup_CALL;
        store_CALL;
        IF call_rec.dep = 0 THEN
          s_call_ela     := s_call_ela     + call_rec.e;
          s_call_cpu     := s_call_cpu     + call_rec.c;
          s_call_disk    := s_call_disk    + call_rec.p;
          s_call_query   := s_call_query   + call_rec.cr;
          s_call_current := s_call_current + call_rec.cu;
        END IF;
        s_call_misses    := s_call_misses  + call_rec.mis;
        s_call_rows      := s_call_rows    + call_rec.r;

        -- tim
        IF call_rec.tim IS NOT NULL THEN
          s_tim := call_rec.tim;
          -- session
          IF s_session_id IS NOT NULL THEN
            IF session_table(s_session_id).tim_first_call IS NULL THEN
              session_table(s_session_id).tim_first_call := call_rec.tim - call_rec.e;
            END IF;
          END IF;
          -- gap
          IF  s_gap_id IS NOT NULL THEN
            IF gap_table(s_gap_id).tim_after IS NULL AND call_rec.tim IS NOT NULL THEN
              gap_table(s_gap_id).tim_after       := call_rec.tim;
              gap_table(s_gap_id).ela_after       := call_rec.e;
              gap_table(s_gap_id).wait_call_after := 'C';
              gap_table(s_gap_id).call_id_after   := call_rec.call_id;
            END IF;
          END IF;
        END IF;

        -- delete call from collection
        call_table.DELETE(s_cursor_num);
        dep_table.DELETE(call_rec.dep);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: process_CALL');
        print_log('*** '||SQLERRM);
        RAISE;
    END process_CALL;

    /* -------------------------
     *
     * parse_line.parse_BIND_bind1
     *
     * BINDS #80:
     *  bind 0: dty=1 mxl=32(30) mal=00 scl=00 pre=00 oacflg=13 oacfl2=1 size=96 offset=0
     *  bind 1: (No oacdef for this bind)
     *
     * BINDS #3:
     *  bind 0: dty=1 mxl=32(02) mal=00 scl=00 pre=00 oacflg=13 oacfl2=b38f0000000001 size=32 offset=0
     *    bfp=8000000100172328 bln=32 avl=02 flg=09
     *    value="09"
     *
     * ------------------------- */
    PROCEDURE parse_BIND_bind1
    IS
    BEGIN /* parse_line.parse_BIND_bind1 */
      IF s_analyze_trace THEN
        s_line_offset       := 7;
        bind_rec            := NULL;
        bind_rec.bind       := get_integer(': dty=');
        IF bind_rec.bind IS NULL THEN
          bind_rec.bind     := get_integer(': (No oacdef for this bind)');
          bind_rec.oacdef   := 'N';
        ELSE
          bind_rec.oacdef   := 'Y';
          bind_rec.oacdty   := get_integer(' mxl=');
          bind_rec.mxl      := get_integer('(');
          bind_rec.pmxl     := get_integer(') mal=');
          bind_rec.mal      := get_integer(' scl=');
          bind_rec.scl      := get_integer(' pre=');
          bind_rec.pre      := get_integer(' oacflg=');
          bind_rec.oacflg   := get_integer(' oacfl2=');
          --bind_rec.oacf12   := get_integer(' size='); oacfl2 can be b38f0000000001 on 9.2.0.6 HP-UX
          bind_rec.oacf12   := get_char(' size=');
          bind_rec.siz      := get_integer(' offset=');
          bind_rec.offset   := get_integer(LF);
        END IF;

        --print_log(l_line_text);
        --IF bind_rec.oacdef = 'Y' THEN
        --  print_log('bind '||bind_rec.bind||': dty='||bind_rec.oacdty||' mxl='||bind_rec.mxl||'('||bind_rec.pmxl||') mal='||bind_rec.mal||' scl='||bind_rec.scl||' pre='||bind_rec.pre||' oacflg='||bind_rec.oacflg||' oacf12='||bind_rec.oacf12||' size='||bind_rec.siz||' offset='||bind_rec.offset);
        --ELSE
        --  print_log('bind '||bind_rec.bind||': (No oacdef for this bind)');
        --END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** bind '||bind_rec.bind||': dty='||bind_rec.oacdty||' mxl='||bind_rec.mxl||'('||bind_rec.pmxl||') mal='||bind_rec.mal||' scl='||bind_rec.scl||' pre='||bind_rec.pre||' oacflg='||bind_rec.oacflg||' oacf12='||bind_rec.oacf12||' size='||bind_rec.siz||' offset='||bind_rec.offset);
        print_log('*** Module: parse_BIND_bind1');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_BIND_bind1;

    /* -------------------------
     *
     * parse_line.parse_BIND_Bind2
     *
     * BINDS #5:
     *
     * kkscoacd
     *  Bind#0
     *   oacdty=02 mxl=22(22) mxlc=00 mal=00 scl=00 pre=00
     *   oacflg=08 fl2=0001 frm=00 csi=00 siz=24 off=0
     *   kxsbbbfp=8005da20  bln=22  avl=04  flg=05
     *   value=47915
     *  Bind#1
     *   No oacdef for this bind.
     *
     *
     * ------------------------- */
    PROCEDURE parse_BIND_Bind2
    IS
    BEGIN /* parse_line.parse_BIND_Bind2 */
      IF s_analyze_trace THEN
        s_line_offset       := 7;
        bind_rec            := NULL;
        bind_rec.bind       := get_integer(LF);
        bind_rec.oacdef     := 'Y';

        --print_log(l_line_text);
        --print_log('Bind#'||bind_rec.bind);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Bind#'||bind_rec.bind);
        print_log('*** Module: parse_BIND_Bind2');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_BIND_Bind2;

    /* -------------------------
     *
     * parse_line.parse_BIND_oacflg
     *
     * kkscoacd
     *  Bind#0
     *   oacdty=02 mxl=22(22) mxlc=00 mal=00 scl=00 pre=00
     *   oacflg=08 fl2=0001 frm=00 csi=00 siz=24 off=0
     *   kxsbbbfp=8005da20  bln=22  avl=04  flg=05
     *   value=47915
     *  Bind#1
     *
     * ------------------------- */
    PROCEDURE parse_BIND_oacflg
    IS
    BEGIN /* parse_line.parse_BIND_oacflg */
      IF s_analyze_trace THEN
        s_line_offset       := 10;

        bind_rec.oacflg     := get_integer(' fl2=');
        bind_rec.oacf12     := get_integer(' frm=');
        bind_rec.frm        := get_integer(' csi=');
        bind_rec.csi        := get_integer(' siz=');
        bind_rec.siz        := get_integer(' off=');
        bind_rec.offset     := get_integer(LF);

        --print_log(l_line_text);
        --print_log(' oacflg='||bind_rec.oacflg||' fl2='||bind_rec.oacf12||' frm='||bind_rec.frm||' csi='||bind_rec.csi||' siz='||bind_rec.siz||' off='||bind_rec.offset);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** oacflg='||bind_rec.oacflg||' fl2='||bind_rec.oacf12||' frm='||bind_rec.frm||' csi='||bind_rec.csi||' siz='||bind_rec.siz||' off='||bind_rec.offset);
        print_log('*** Module: parse_BIND_oacflg');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_BIND_oacflg;

    /* -------------------------
     *
     * parse_line.parse_BIND_bfp
     *
     * BINDS #80:
     *  bind 0: dty=1 mxl=32(30) mal=00 scl=00 pre=00 oacflg=13 oacfl2=1 size=96 offset=0
     *    bfp=b73093f4 bln=32 avl=30 flg=05
     *
     *
     * BINDS #3:
     *  bind 0: dty=1 mxl=32(02) mal=00 scl=00 pre=00 oacflg=13 oacfl2=b38f0000000001 size=32 offset=0
     *    bfp=8000000100172328 bln=32 avl=02 flg=09
     *    value="09"
     * ------------------------- */
    PROCEDURE parse_BIND_bfp
    IS
    BEGIN /* parse_line.parse_BIND_bfp */
      IF s_analyze_trace THEN
        s_line_offset       := 8;

        bind_rec.kxsbbbfp   := get_char(' bln=');
        bind_rec.bln        := get_integer(' avl=');
        bind_rec.avl        := get_integer(' flg=');
        bind_rec.flg        := get_integer(LF);

        --print_log(l_line_text);
        --print_log('  bfp='||bind_rec.kxsbbbfp||' bln='||bind_rec.bln||' avl='||bind_rec.avl||' flg='||bind_rec.flg);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** bfp='||bind_rec.kxsbbbfp||' bln='||bind_rec.bln||' avl='||bind_rec.avl||' flg='||bind_rec.flg);
        print_log('*** Module: parse_BIND_bfp');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_BIND_bfp;

    /* -------------------------
     *
     * parse_line.parse_BIND_oacdty
     *
     * kkscoacd
     *  Bind#0
     *   oacdty=02 mxl=22(22) mxlc=00 mal=00 scl=00 pre=00
     *   oacflg=08 fl2=0001 frm=00 csi=00 siz=24 off=0
     *   kxsbbbfp=8005da20  bln=22  avl=04  flg=05
     *   value=47915
     *  Bind#1
     *
     * ------------------------- */
    PROCEDURE parse_BIND_oacdty
    IS
    BEGIN /* parse_line.parse_BIND_oacdty */
      IF s_analyze_trace THEN
        s_line_offset       := 10;

        bind_rec.oacdty     := get_integer(' mxl=');
        bind_rec.mxl        := get_integer('(');
        bind_rec.pmxl       := get_integer(') mxlc=');
        bind_rec.mxlc       := get_integer(' mal=');
        bind_rec.mal        := get_integer(' scl=');
        bind_rec.scl        := get_integer(' pre=');
        bind_rec.pre        := get_integer(LF);

        --print_log(l_line_text);
        --print_log(' oacdty='||bind_rec.oacdty||' mxl='||bind_rec.mxl||'('||bind_rec.pmxl||') mxlc='||bind_rec.mxlc||' mal='||bind_rec.mal||' scl='||bind_rec.scl||' pre='||bind_rec.pre);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** oacdty='||bind_rec.oacdty||' mxl='||bind_rec.mxl||'('||bind_rec.pmxl||') mxlc='||bind_rec.mxlc||' mal='||bind_rec.mal||' scl='||bind_rec.scl||' pre='||bind_rec.pre);
        print_log('*** Module: parse_BIND_oacdty');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_BIND_oacdty;

    /* -------------------------
     *
     * parse_line.parse_BIND_kxsbbbfp
     *
     *  Bind#0
     *   oacdty=02 mxl=22(22) mxlc=00 mal=00 scl=00 pre=00
     *   oacflg=08 fl2=0001 frm=00 csi=00 siz=24 off=0
     *   kxsbbbfp=8005da20  bln=22  avl=04  flg=05
     *   value=47915
     *  Bind#1
     *
     * ------------------------- */
    PROCEDURE parse_BIND_kxsbbbfp
    IS
    BEGIN /* parse_line.parse_BIND_kxsbbbfp */
      IF s_analyze_trace THEN
        s_line_offset       := 12;

        bind_rec.kxsbbbfp   := get_char('  bln=');
        bind_rec.bln        := get_integer('  avl=');
        bind_rec.avl        := get_integer('  flg=');
        bind_rec.flg        := get_integer(LF);

        --print_log(l_line_text);
        --print_log(' kxsbbbfp='||bind_rec.kxsbbbfp||'  bln='||bind_rec.bln||'  avl='||bind_rec.avl||'  flg='||bind_rec.flg);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** kxsbbbfp='||bind_rec.kxsbbbfp||'  bln='||bind_rec.bln||'  avl='||bind_rec.avl||'  flg='||bind_rec.flg);
        print_log('*** Module: parse_BIND_kxsbbbfp');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_BIND_kxsbbbfp;

    /* -------------------------
     *
     * parse_line.parse_BIND_oacdef
     *
     *
     * ------------------------- */
    PROCEDURE parse_BIND_oacdef
    IS
    BEGIN /* parse_line.parse_BIND_oacdef */
      IF s_analyze_trace THEN
        s_line_offset       := 7;
        bind_rec.oacdef   := 'N';

        --print_log(l_line_text);
        --print_log(' No oacdef for this bind.');
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** No oacdef for this bind.');
        print_log('*** Module: parse_BIND_oacdef');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_BIND_oacdef;

    /* -------------------------
     *
     * parse_line.parse_BIND_value
     *
     *    value=146831
     *   value=146831
     *
     * ------------------------- */
    PROCEDURE parse_BIND_value
    IS
    BEGIN /* parse_line.parse_BIND_value */
      IF s_analyze_trace THEN
        IF l_line_text LIKE '   value=%' THEN
          s_line_offset     := 10;
        ELSE
          s_line_offset     := 9;
        END IF;

        bind_rec.value      := get_char(LF);

        --print_log(l_line_text);
        --print_log('  value='||bind_rec.value);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** value='||bind_rec.value);
        print_log('*** Module: parse_BIND_value');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_BIND_value;

    /* -------------------------
     *
     * parse_line.parse_BIND_value_cont
     *
     *
     * ------------------------- */
    PROCEDURE parse_BIND_value_cont
    IS
    BEGIN /* parse_line.parse_BIND_value_cont */
      IF s_analyze_trace THEN
        IF LENGTH(bind_rec.value) + l_line_len < 4000 THEN
          bind_rec.value := bind_rec.value||l_line_text;
        END IF;
        --print_log(s_line_type||'cont:'||l_line_text);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** '||s_line_type||'cont:'||l_line_text);
        print_log('*** Module: parse_BIND_value_cont');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_BIND_value_cont;

    /* -------------------------
     *
     * parse_line.store_BIND
     *
     * ------------------------- */
    PROCEDURE store_BIND
    IS
    BEGIN /* parse_line.store_BIND */
      IF s_analyze_trace THEN
        IF binds_rec.exec_id IS NOT NULL AND
           bind_rec.bind IS NOT NULL AND
           bind_rec.oacdef IS NOT NULL THEN
          IF trca$g.g_include_binds = 'Y' THEN
            IF s_bind_id = CACHE_SIZE THEN
              flush_BIND_cache;
            END IF;

            s_bind_id := s_bind_id + 1;
            bind_cache(s_bind_id).exec_id           := binds_rec.exec_id;
            bind_cache(s_bind_id).group_id          := binds_rec.group_id;
            --bind_cache(s_bind_id).cursor_id         := binds_rec.cursor_id;
            bind_cache(s_bind_id).tool_execution_id := binds_rec.tool_execution_id;
            bind_cache(s_bind_id).bind              := bind_rec.bind;
            bind_cache(s_bind_id).oacdef            := bind_rec.oacdef;
            bind_cache(s_bind_id).oacdty            := bind_rec.oacdty;
            --bind_cache(s_bind_id).mxl               := bind_rec.mxl;
            --bind_cache(s_bind_id).pmxl              := bind_rec.pmxl;
            --bind_cache(s_bind_id).mxlc              := bind_rec.mxlc;
            --bind_cache(s_bind_id).mal               := bind_rec.mal;
            --bind_cache(s_bind_id).scl               := bind_rec.scl;
            --bind_cache(s_bind_id).pre               := bind_rec.pre;
            --bind_cache(s_bind_id).oacflg            := bind_rec.oacflg;
            --bind_cache(s_bind_id).oacf12            := bind_rec.oacf12;
            --bind_cache(s_bind_id).frm               := bind_rec.frm;
            --bind_cache(s_bind_id).csi               := bind_rec.csi;
            --bind_cache(s_bind_id).siz               := bind_rec.siz;
            --bind_cache(s_bind_id).offset            := bind_rec.offset;
            --bind_cache(s_bind_id).kxsbbbfp          := bind_rec.kxsbbbfp;
            --bind_cache(s_bind_id).bln               := bind_rec.bln;
            bind_cache(s_bind_id).avl               := bind_rec.avl;
            --bind_cache(s_bind_id).flg               := bind_rec.flg;
            bind_cache(s_bind_id).value             := bind_rec.value;

            bind_line_cache(s_bind_id)              := p_line_number;
          END IF;
        ELSE
          print_log('invalid bind at line '||p_line_number);
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: store_BIND');
        print_log('*** '||SQLERRM);
        RAISE;
    END store_BIND;

    /* -------------------------
     *
     * parse_line.process_BIND_value_end
     *
     *
     * ------------------------- */
    PROCEDURE process_BIND_value_end
    IS
    BEGIN /* parse_line.process_BIND_value_end */
      IF s_analyze_trace THEN
        IF bind_rec.bind IS NOT NULL THEN
          store_BIND;
          bind_rec := NULL;
          s_bind_count := s_bind_count + 1;
        END IF;
        s_state_BINDS_bind_value := FALSE;
        s_state_BINDS_bind := FALSE;
        --print_log('value len='||LENGTH(bind_rec.value));
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** value len='||LENGTH(bind_rec.value));
        print_log('*** Module: process_BIND_value_end');
        print_log('*** '||SQLERRM);
        RAISE;
    END process_BIND_value_end;

    /* -------------------------
     *
     * parse_line.parse_STAT
     *
     * STAT #43 id=1 cnt=0 pid=0 pos=1 obj=0 op='SORT ORDER BY '
     * STAT #43 id=2 cnt=0 pid=1 pos=1 obj=0 op='NESTED LOOPS  '
     * STAT #5 id=1 cnt=1 pid=0 pos=1 obj=20 op='TABLE ACCESS BY INDEX ROWID ICOL$ (cr=4 pr=1 pw=0 time=10000 us)'
     * STAT #5 id=2 cnt=1 pid=1 pos=1 obj=37 op='INDEX RANGE SCAN I_ICOL1 (cr=3 pr=1 pw=0 time=10000 us)'
     * STAT #6 id=1 cnt=1 pid=0 pos=1 obj=0 op='SORT ORDER BY (cr=7 pr=3 pw=3 time=0 us cost=11 size=327 card=3)'
     * STAT #16 id=1 cnt=1 pid=0 pos=1 obj=62 op='TABLE ACCESS BY USER ROWID VIEW$ (cr=1 r=0 w=0 time=22 us)'
     *
     * ------------------------- */
    PROCEDURE parse_STAT
    IS
    BEGIN /* parse_line.parse_STAT */
      IF s_analyze_trace THEN
        s_line_offset       := 7;
        stat_rec            := NULL;
        stat_rec.cursor_num := get_integer(' id=', MAX_CURSOR_NUM_LEN);
        stat_rec.id         := get_integer(' cnt=');
        stat_rec.cnt        := get_integer(' pid=');
        stat_rec.pid        := get_integer(' pos=');
        stat_rec.pos        := get_integer(' obj=');
        stat_rec.obj        := get_integer(' op=''');
        stat_rec.op         := SUBSTR(get_char(' (cr='), 1, 4000); -- 10g+
        IF stat_rec.op IS NULL THEN -- < 10g
          stat_rec.op       := SUBSTR(get_char(' '''||LF), 1, 4000);
        ELSE -- 10g+
          stat_rec.cr       := get_integer(' pr=');
          IF stat_rec.cr IS NULL THEN
            stat_rec.cr     := get_integer(' r=');
          END IF;
          stat_rec.pr       := get_integer(' pw=');
          IF stat_rec.pr IS NULL THEN
            stat_rec.pr     := get_integer(' w=');
          END IF;
          stat_rec.pw       := get_integer(' time=');
          stat_rec.time     := get_integer(' us)'''||LF); -- 10g
          trca$g.g_time     := 'Y'; -- used by reports
          IF stat_rec.time IS NULL THEN -- 11g+
            stat_rec.time   := get_integer(' us cost=');
            stat_rec.cost   := get_integer(' size=');
            stat_rec.siz    := get_integer(' card=');
            stat_rec.card   := get_integer(')'''||LF);
            trca$g.g_card   := 'Y'; -- used by reports
          END IF;
        END IF;

        --print_log(l_line_text);
        --IF stat_rec.cr IS NOT NULL THEN
        --  print_log('STAT #'||stat_rec.cursor_num||' id='||stat_rec.id||' cnt='||stat_rec.cnt||' pid='||stat_rec.pid||' pos='||stat_rec.pos||' obj='||stat_rec.obj||' op='''||stat_rec.op||
        --  ' (cr='||stat_rec.cr||' pr='||stat_rec.pr||' pw='||stat_rec.pw||' time='||stat_rec.time||' us)''');
        --ELSE
        --  print_log('STAT #'||stat_rec.cursor_num||' id='||stat_rec.id||' cnt='||stat_rec.cnt||' pid='||stat_rec.pid||' pos='||stat_rec.pos||' obj='||stat_rec.obj||' op='''||stat_rec.op);
        --END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** STAT #'||stat_rec.cursor_num||' id='||stat_rec.id||' cnt='||stat_rec.cnt||' pid='||stat_rec.pid||' pos='||stat_rec.pos||' obj='||stat_rec.obj||' op='''||stat_rec.op||' (cr='||stat_rec.cr||' pr='||stat_rec.pr||' pw='||stat_rec.pw||' time='||stat_rec.time||' us)''');
        print_log('*** Module: parse_STAT');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_STAT;

    /* -------------------------
     *
     * parse_line.store_STAT
     *
     * ------------------------- */
    PROCEDURE store_STAT
    IS
    BEGIN /* parse_line.store_STAT */
      IF s_analyze_trace THEN
        IF stat_rec.exec_id IS NOT NULL AND
           stat_rec.group_id IS NOT NULL AND
           stat_rec.cursor_id IS NOT NULL AND
           stat_rec.tool_execution_id IS NOT NULL AND
           stat_rec.id IS NOT NULL THEN

          IF s_stat_id = CACHE_SIZE THEN
            flush_STAT_cache;
          END IF;

          s_stat_id := s_stat_id + 1;
          stat_cache(s_stat_id).exec_id           := stat_rec.exec_id;
          stat_cache(s_stat_id).group_id          := stat_rec.group_id;
          stat_cache(s_stat_id).cursor_id         := stat_rec.cursor_id;
          stat_cache(s_stat_id).session_id        := stat_rec.session_id;
          stat_cache(s_stat_id).tool_execution_id := stat_rec.tool_execution_id;
          --stat_cache(s_stat_id).cursor_num        := stat_rec.cursor_num;
          stat_cache(s_stat_id).id                := stat_rec.id;
          stat_cache(s_stat_id).cnt               := stat_rec.cnt;
          stat_cache(s_stat_id).pid               := stat_rec.pid;
          stat_cache(s_stat_id).pos               := stat_rec.pos;
          stat_cache(s_stat_id).obj               := stat_rec.obj;
          stat_cache(s_stat_id).op                := stat_rec.op;
          stat_cache(s_stat_id).cr                := stat_rec.cr;
          stat_cache(s_stat_id).pr                := stat_rec.pr;
          stat_cache(s_stat_id).pw                := stat_rec.pw;
          stat_cache(s_stat_id).time              := stat_rec.time;
          stat_cache(s_stat_id).cost              := stat_rec.cost;
          stat_cache(s_stat_id).siz               := stat_rec.siz;
          stat_cache(s_stat_id).card              := stat_rec.card;

          stat_line_cache(s_stat_id)              := p_line_number;
        ELSE
          print_log('invalid stat at line '||p_line_number||' "'||stat_rec.exec_id||'" "'||stat_rec.group_id||'" "'||stat_rec.cursor_id||'"');
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: store_STAT');
        print_log('*** '||SQLERRM);
        RAISE;
    END store_STAT;

    /* -------------------------
     *
     * parse_line.process_STAT
     *
     * ------------------------- */
    PROCEDURE process_STAT
    IS
    BEGIN /* parse_line.process_STAT */
      IF s_analyze_trace THEN
        IF stat_rec.cursor_num IS NULL OR stat_rec.id IS NULL THEN
          RETURN; -- abnormal file truncation
        END IF;

        -- state
        s_cursor_num := stat_rec.cursor_num;

        IF NOT cursor_table.EXISTS(s_cursor_num) THEN -- pre-created by a PARSING, CALL or BINDS
          initialize_cursor;
        END IF;

        update_cursor_id;
        update_cursor_state;

        -- control
        cursor_table(s_cursor_num).stat_line_seen := TRUE;
        IF cursor_table(s_cursor_num).exec_id IS NULL THEN
          set_exec_id (p_cursor_num => s_cursor_num);
        END IF;
        set_first_exec_id (p_cursor_num => s_cursor_num);
        stat_rec.exec_id := cursor_table(s_cursor_num).exec_id;
        stat_rec.group_id := cursor_table(s_cursor_num).group_id; -- denormalized
        stat_rec.cursor_id := s_cursor_id; -- denormalized
        stat_rec.session_id := s_session_id; -- denormalized
        stat_rec.tool_execution_id := p_tool_execution_id; -- denormalized
        store_STAT;
        s_stat_lines := s_stat_lines + 1;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: process_STAT');
        print_log('*** '||SQLERRM);
        RAISE;
    END process_STAT;

    /* -------------------------
     *
     * parse_line.parse_SESSION
     *
     * *** SESSION ID:(23.10830) 2008-02-27 10:26:39.010
     *
     * ------------------------- */
    PROCEDURE parse_SESSION
    IS
      l_sid               INTEGER;
      l_serial#           INTEGER;
      l_session_timestamp VARCHAR2(32);

    BEGIN /* parse_line.parse_SESSION */
      IF s_analyze_trace THEN
        s_line_offset       := 17;
        l_sid               := get_integer('.');
        l_serial#           := get_integer(') ');
        l_session_timestamp := get_char(LF);

        SELECT trca$_session_id_s.NEXTVAL INTO s_session_id FROM DUAL;
        s_session_count := s_session_count + 1;

        session_table(s_session_id).sid                  := l_sid;
        session_table(s_session_id).serial#              := l_serial#;
        session_table(s_session_id).session_timestamp    := TO_TIMESTAMP(l_session_timestamp, 'YYYY-MM-DD HH24:MI:SS.FF3');
        session_table(s_session_id).tim_first_wait       := NULL;
        session_table(s_session_id).tim_first_call       := NULL;
        session_table(s_session_id).read_only_committed  := 0;
        session_table(s_session_id).read_only_rollbacked := 0;
        session_table(s_session_id).update_committed     := 0;
        session_table(s_session_id).update_rollbacked    := 0;

        --print_log(l_line_text);
        --print_log('*** SESSION ID:('||l_sid||'.'||l_serial#||') '||l_session_timestamp);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** SESSION ID:('||l_sid||'.'||l_serial#||') '||l_session_timestamp);
        print_log('*** Module: parse_SESSION');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_SESSION;

    /* -------------------------
     *
     * parse_line.parse_GAP
     *
     * WAIT #28: nam='db file scattered read' ela= 7000 file#=2 block#=304133 blocks=4 obj#=47483 tim=4715494410805000
     * *** 2008-04-21 12:33:30.812
     * WAIT #28: nam='db file scattered read' ela= 7000 file#=2 block#=304137 blocks=4 obj#=47483 tim=4715494410812000
     *
     * ------------------------- */
    PROCEDURE parse_GAP
    IS
      l_gap_timestamp VARCHAR2(32);

    BEGIN /* parse_line.parse_GAP */
      IF s_analyze_trace THEN
        s_line_offset   := 5;
        l_gap_timestamp := get_char(LF);

        SELECT trca$_gap_id_s.NEXTVAL INTO s_gap_id FROM DUAL;
        s_gap_count := s_gap_count + 1;

        gap_table(s_gap_id).gap_timestamp   := TO_TIMESTAMP(l_gap_timestamp, 'YYYY-MM-DD HH24:MI:SS.FF3');
        gap_table(s_gap_id).tim_before      := s_tim;
        gap_table(s_gap_id).tim_after       := NULL;
        gap_table(s_gap_id).ela_after       := NULL;
        gap_table(s_gap_id).wait_call_after := NULL;
        gap_table(s_gap_id).call_id_after   := NULL;

        --print_log(l_line_text);
        --print_log('*** '||l_gap_timestamp);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** '||l_gap_timestamp);
        print_log('*** Module: parse_GAP');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_GAP;

    /* -------------------------
     *
     * parse_line.parse_XCTEND
     *
     * XCTEND rlbk=0, rd_only=0
     * XCTEND rlbk=0, rd_only=1, tim=1245171643549992
     *
     * ------------------------- */
    PROCEDURE parse_XCTEND
    IS
      l_rlbk    INTEGER;
      l_rd_only INTEGER;

    BEGIN /* parse_line.parse_XCTEND */
      IF s_analyze_trace THEN
        s_line_offset       := 13;
        l_rlbk              := get_integer(', rd_only=');
        l_rd_only           := get_integer(', tim='); -- 11g+
        IF l_rd_only IS NULL THEN -- < 11g
          l_rd_only         := get_integer(LF);
        END IF;
        s_transaction_count := s_transaction_count + 1;

        IF s_session_id IS NOT NULL THEN
          IF l_rlbk = 1 THEN
            IF l_rd_only = 1 THEN
              session_table(s_session_id).read_only_rollbacked := session_table(s_session_id).read_only_rollbacked + 1;
            ELSE
              session_table(s_session_id).update_rollbacked := session_table(s_session_id).update_rollbacked + 1;
            END IF;
          ELSE
            IF l_rd_only = 1 THEN
              session_table(s_session_id).read_only_committed := session_table(s_session_id).read_only_committed + 1;
            ELSE
              session_table(s_session_id).update_committed := session_table(s_session_id).update_committed + 1;
            END IF;
          END IF;
        END IF;

        --print_log(l_line_text);
        --print_log('XCTEND rlbk='||l_rlbk||', rd_only='||l_rd_only);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** XCTEND rlbk='||l_rlbk||', rd_only='||l_rd_only);
        print_log('*** Module: parse_XCTEND');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_XCTEND;

    /* -------------------------
     *
     * parse_line.parse_ERROR
     *
     * ERROR #1:err=1422 tim=2296528706
     *
     * ------------------------- */
    PROCEDURE parse_ERROR
    IS
    BEGIN /* parse_line.parse_ERROR */
      IF s_analyze_trace THEN
        s_line_offset        := 8;
        error_rec            := NULL;
        error_rec.cursor_num := get_integer(':err=', MAX_CURSOR_NUM_LEN);
        error_rec.err        := get_integer(' tim=');
        --error_rec.tim        := get_integer(LF);
        error_rec.tim        := s_tim;

        --print_log(l_line_text);
        --print_log('ERROR #'||error_rec.cursor_num||':err='||error_rec.err||' tim='||error_rec.tim);
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** ERROR #'||error_rec.cursor_num||':err='||error_rec.err||' tim='||error_rec.tim);
        print_log('*** Module: parse_ERROR');
        print_log('*** '||SQLERRM);
        RAISE;
    END parse_ERROR;

    /* -------------------------
     *
     * parse_line.store_ERROR
     *
     * ------------------------- */
    PROCEDURE store_ERROR
    IS
    BEGIN /* parse_line.store_ERROR */
      IF s_analyze_trace THEN
        IF error_rec.exec_id IS NOT NULL AND
           error_rec.cursor_id IS NOT NULL AND
           error_rec.tool_execution_id IS NOT NULL THEN

          INSERT INTO trca$_error (
            exec_id,
            group_id,
            --cursor_id,
            tool_execution_id,
            --cursor_num,
            err,
            tim
          ) VALUES (
            error_rec.exec_id,
            error_rec.group_id,
            --error_rec.cursor_id,
            error_rec.tool_execution_id,
            --error_rec.cursor_num,
            error_rec.err,
            error_rec.tim
          );
        ELSE
          print_log('invalid error at line '||p_line_number||' "'||error_rec.exec_id||'" "'||error_rec.cursor_id||'"');
        END IF;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: store_ERROR');
        print_log('*** '||SQLERRM);
        RAISE;
    END store_ERROR;

    /* -------------------------
     *
     * parse_line.process_ERROR
     *
     * ------------------------- */
    PROCEDURE process_ERROR
    IS
    BEGIN /* parse_line.process_ERROR */
      IF s_analyze_trace THEN
        IF error_rec.cursor_num IS NULL OR error_rec.err IS NULL THEN
          RETURN; -- abnormal file truncation
        END IF;

        -- state
        s_cursor_num := error_rec.cursor_num;

        IF NOT cursor_table.EXISTS(s_cursor_num) THEN -- pre-created by a PARSING, CALL or BINDS
          initialize_cursor;
        END IF;

        update_cursor_id;
        update_cursor_state;

        -- control
        IF cursor_table(s_cursor_num).exec_id IS NULL THEN
          set_exec_id (p_cursor_num => s_cursor_num);
        END IF;
        set_first_exec_id (p_cursor_num => s_cursor_num);
        IF error_rec.tim IS NOT NULL THEN
          s_tim := error_rec.tim;
        END IF;
        error_rec.exec_id := cursor_table(s_cursor_num).exec_id;
        error_rec.group_id := cursor_table(s_cursor_num).group_id; -- denormalized
        error_rec.cursor_id := s_cursor_id; -- denormalized
        error_rec.tool_execution_id := p_tool_execution_id; -- denormalized
        store_ERROR;
        s_error_lines := s_error_lines + 1;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: process_ERROR');
        print_log('*** '||SQLERRM);
        RAISE;
    END process_ERROR;

    /* -------------------------
     *
     * parse_line.process_HEADER
     *
     * ------------------------- */
    PROCEDURE process_HEADER
    IS
      l_id INTEGER;

    BEGIN /* parse_line.process_HEADER */
      IF s_analyze_trace THEN
        SELECT trca$_header_id_s.NEXTVAL INTO l_id FROM DUAL;
        s_piece := s_piece + 1;

        INSERT INTO trca$_trace_header (
          id,
          trace_id,
          piece,
          tool_execution_id,
          text
        ) VALUES (
          l_id,
          p_trace_id,
          s_piece,
          p_tool_execution_id,
          SUBSTR(l_line_text, 1, 4000)
        );
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: process_HEADER');
        print_log('*** '||SQLERRM);
        RAISE;
    END process_HEADER;

    /* -------------------------
     *
     * parse_line.process_10053
     *
     * ------------------------- */
    PROCEDURE process_10053
    IS
      l_message VARCHAR2(32767);
    BEGIN /* parse_line.process_10053 */
      IF s_split_trace AND s_copy_10053 THEN
        IF l_line_text IS NOT NULL THEN
          IF s_10053_file_rec.file_text IS NULL THEN
            s_10053_file_rec.file_text := l_line_text;
          ELSE
            SYS.DBMS_LOB.WRITEAPPEND (
              lob_loc => s_10053_file_rec.file_text,
              amount  => LENGTH(l_line_text),
              buffer  => l_line_text );
          END IF;
        ELSIF l_line_clob IS NOT NULL THEN
          SYS.DBMS_LOB.APPEND (
            dest_lob => s_10053_file_rec.file_text,
            src_lob  => l_line_clob );
        END IF;

        IF s_line_type <> LT_EMPTY THEN
          s_current_trace := 10053;
        END IF;

        IF SYS.DBMS_LOB.GETLENGTH(s_10053_file_rec.file_text) > TO_NUMBER(trca$g.g_copy_file_max_size_bytes) THEN
          l_message := LF||'*** truncated by TRCA as per "copy_file_max_size_bytes" parameter ***'||LF;

          SYS.DBMS_LOB.WRITEAPPEND (
            lob_loc => s_10053_file_rec.file_text,
            amount  => LENGTH(l_message),
            buffer  => l_message );

          s_copy_10053 := FALSE;
        END IF;
      END IF;
    END process_10053;

    /* -------------------------
     *
     * parse_line.process_10046
     *
     * ------------------------- */
    PROCEDURE process_10046
    IS
      l_message VARCHAR2(32767);
    BEGIN /* parse_line.process_10046 */
      IF s_split_trace AND s_copy_10046 THEN
        IF l_line_text IS NOT NULL THEN
          IF s_10046_file_rec.file_text IS NULL THEN
            s_10046_file_rec.file_text := l_line_text;
          ELSE
            SYS.DBMS_LOB.WRITEAPPEND (
              lob_loc => s_10046_file_rec.file_text,
              amount  => LENGTH(l_line_text),
              buffer  => l_line_text );
          END IF;
        ELSIF l_line_clob IS NOT NULL THEN
          SYS.DBMS_LOB.APPEND (
            dest_lob => s_10046_file_rec.file_text,
            src_lob  => l_line_clob );
        END IF;

        IF s_line_type <> LT_EMPTY THEN
          s_current_trace := 10046;
        END IF;

        IF SYS.DBMS_LOB.GETLENGTH(s_10046_file_rec.file_text) > TO_NUMBER(trca$g.g_copy_file_max_size_bytes) THEN
          l_message := LF||'*** truncated by TRCA as per "copy_file_max_size_bytes" parameter ***'||LF;

          SYS.DBMS_LOB.WRITEAPPEND (
            lob_loc => s_10046_file_rec.file_text,
            amount  => LENGTH(l_message),
            buffer  => l_message );

          s_copy_10046 := FALSE;
        END IF;
      END IF;
    END process_10046;

  /*************************************************************************************/

  BEGIN /* parse_line */
    IF p_line_text IS NOT NULL THEN
      IF INSTR(p_line_text, CR) > 0 THEN
        l_line_text := REPLACE(p_line_text, CR);
        l_line_len  := LENGTH(l_line_text);
      ELSE
        l_line_text := p_line_text;
        l_line_len  := p_line_len;
      END IF;
    ELSE
      l_line_text := NULL;
    END IF;

    IF p_line_clob IS NOT NULL THEN
      IF INSTR(p_line_clob, CR) > 0 THEN
        l_line_clob := REPLACE(p_line_clob, CR);
        l_line_len  := NVL(DBMS_LOB.GETLENGTH (lob_loc => l_line_clob), 0);
      ELSE
        l_line_clob := p_line_clob;
        l_line_len  := p_line_len;
      END IF;
    ELSE
      l_line_clob := NULL;
    END IF;

    s_line_type := get_line_type;

    /* -------------------------
     *
     * WAIT #0: nam='SQL*Net message to client' ela= 0 driver id=1413697536 #bytes=1 p3=0 obj#=47091 tim=4715494416161000
     * *** 2008-04-21 12:33:40.860
     * WAIT #0: nam='SQL*Net message from client' ela= 4699000 driver id=1413697536 #bytes=1 p3=0 obj#=47091 tim=4715494420860000
     *
     * ------------------------- */
    IF s_line_type = LT_GAP THEN
      process_10046;
      parse_GAP;
      RETURN;
    END IF;

    /* -------------------------
     *
     * BINDS #80:
     *  bind 0: dty=1 mxl=32(30) mal=00 scl=00 pre=00 oacflg=13 oacfl2=1 size=96 offset=0
     *    bfp=b73093f4 bln=32 avl=30 flg=05
     *    value="SO_PRICE_ADJUSTMENTS_INTERFACE"
     *  bind 1: dty=1 mxl=32(02) mal=00 scl=00 pre=00 oacflg=13 oacfl2=1 size=0 offset=32
     *    bfp=b7309414 bln=32 avl=02 flg=01
     *    value="OE"
     *  bind 2: dty=1 mxl=32(11) mal=00 scl=00 pre=00 oacflg=13 oacfl2=1 size=0 offset=64
     *    bfp=b7309434 bln=32 avl=11 flg=01
     *    value="ATTRIBUTE10"
     * EXEC #80:c=0,e=135,p=0,cr=0,cu=0,mis=0,r=0,dep=1,og=4,tim=1175904330209402
     *
     * BINDS #3:
     *
     * kkscoacd
     *  Bind#0
     *   oacdty=02 mxl=22(22) mxlc=00 mal=00 scl=00 pre=00
     *   oacflg=08 fl2=0001 frm=00 csi=00 siz=24 off=0
     *   kxsbbbfp=8004aeb0  bln=22  avl=03  flg=05
     *   value=2374
     * EXEC #3:c=0,e=0,p=0,cr=0,cu=0,mis=0,r=0,dep=1,og=4,tim=4715494377600000
     *
     * BINDS #71:
     *  bind 0: dty=2 mxl=22(22) mal=00 scl=00 pre=00 oacflg=08 oacfl2=1 size=24 offset=0
     *    bfp=b731e260 bln=22 avl=04 flg=05
     *    value=146831
     *  bind 1: (No oacdef for this bind)
     * EXEC #71:c=0,e=99,p=0,cr=0,cu=0,mis=0,r=0,dep=1,og=4,tim=1175904330099065
     *
     * ------------------------- */
    IF s_state_BINDS THEN
      IF s_line_type IN (LT_EMPTY, LT_BIND_kkscoacd) THEN
        process_10046;
        RETURN;
      ELSIF s_line_type IN (LT_WAIT, LT_FETCH, LT_EXEC, LT_BINDS, LT_STAT, LT_PARSE, LT_PARSING_SEPARATOR, LT_XCTEND, LT_GAP, LT_SESSION, LT_UNMAP, LT_SORT_UNMAP, LT_ERROR, LT_PARSE_ERROR, LT_TRUNCATION) THEN
        process_BIND_value_end;
        s_state_BINDS := FALSE;
        -- RETURN; -- falls through below
      ELSIF s_line_type = LT_BIND_bind1 THEN
        process_10046;
        process_BIND_value_end;
        parse_BIND_bind1;
        s_state_BINDS_bind := TRUE;
        RETURN;
      ELSIF s_line_type = LT_BIND_Bind2 THEN
        process_10046;
        process_BIND_value_end;
        parse_BIND_Bind2;
        s_state_BINDS_bind := TRUE;
        RETURN;
      ELSIF s_state_BINDS_bind THEN
        IF s_line_type = LT_BIND_oacflg THEN
          process_10046;
          parse_BIND_oacflg;
          RETURN;
        ELSIF s_line_type = LT_BIND_bfp THEN
          process_10046;
          parse_BIND_bfp;
          RETURN;
        ELSIF s_line_type = LT_BIND_oacdty THEN
          process_10046;
          parse_BIND_oacdty;
          RETURN;
        ELSIF s_line_type = LT_BIND_kxsbbbfp THEN
          process_10046;
          parse_BIND_kxsbbbfp;
          RETURN;
        ELSIF s_line_type = LT_BIND_oacdef THEN
          process_10046;
          parse_BIND_oacdef;
          RETURN;
        ELSIF s_line_type = LT_BIND_value THEN
          process_10046;
          parse_BIND_value;
          s_state_BINDS_bind_value := TRUE;
          RETURN;
        ELSIF s_state_BINDS_bind_value THEN
          process_10046;
          parse_BIND_value_cont;
          RETURN;
        END IF;
      END IF;
    END IF;

    /* -------------------------
     *
     * PARSING IN CURSOR #93 len=40 dep=1 uid=0 oct=7 lid=0 tim=1175904330103822 hv=1932955448 ad='6c351458'
     * delete from superobj$ where subobj# = :1
     * END OF STMT
     * PARSING IN CURSOR #19 len=269 dep=2 uid=0 oct=3 lid=0 tim=1211894891974035 hv=2863336729 ad='38ef0b90' sqlid='6xrt7afpaq38t'
     * select  case when (u.type# = 2)          then           (select u1.spare2 from user$ u1 where u1.user# = o.owner#)         else           (select ob.obj# from obj$ ob where ob.name = 'ORA$BASE')         end from obj$ o, user$ u where o.obj# = :1  and u.user# = o.owner#
     * END OF STMT
     *
     * ------------------------- */
    IF s_state_STATEMENT THEN
      IF s_line_type = LT_END_OF_STMT THEN
        process_10046;
        process_END_OF_STMT;
        SYS.DBMS_LOB.FREETEMPORARY (lob_loc => s_sql_fulltext);
        s_state_STATEMENT := FALSE;
        RETURN;
      ELSE
        process_10046;
        process_STATEMENT; -- keep appending one or many small or big lines
        RETURN;
      END IF;
    END IF;

    /* -------------------------
     *
     * PARSE ERROR #4:len=31 dep=0 uid=564 oct=3 lid=564 tim=1181559630466515 err=904
     * SELECT owner2 FROM trca_object
     * WAIT #4: nam='SQL*Net break/reset to client' ela= 18 driver id=1413697536 break?=1 p3=0 obj#=24979 tim=1181559630466684
     * PARSE ERROR #7:len=19 dep=0 uid=0 oct=3 lid=0 tim=1212229751197728 err=942
     *
     * ------------------------- */
    IF s_state_STATEMENT_ERROR THEN
      IF s_line_type IN (LT_WAIT, LT_FETCH, LT_EXEC, LT_BINDS, LT_STAT, LT_PARSE, LT_PARSING_SEPARATOR, LT_XCTEND, LT_GAP, LT_SESSION, LT_UNMAP, LT_SORT_UNMAP, LT_ERROR, LT_PARSE_ERROR, LT_TRUNCATION) THEN
        process_END_OF_STMT;
        SYS.DBMS_LOB.FREETEMPORARY (lob_loc => s_sql_fulltext);
        s_state_STATEMENT_ERROR := FALSE;
        -- RETURN; falls through below because there is no END_OF_STMT line
      ELSE
        process_10046;
        process_STATEMENT; -- keep appending one or many small or big lines
        RETURN;
      END IF;
    END IF;

    /* -------------------------
     *
     * WAIT #5: nam='db file scattered read' ela= 50895 file#=66 block#=81376 blocks=8 obj#=2038870 tim=1181075125921640
     * WAIT #5: nam='db file sequential read' ela= 18 file#=66 block#=81384 blocks=1 obj#=2038870 tim=1181075125925389
     * WAIT #20: nam='db file sequential read' ela= 30 file#=1 block#=77538 blocks=1 obj#=531 tim=1211894892044742
     *
     * ------------------------- */
    IF s_line_type = LT_WAIT THEN
      process_10046;
      parse_WAIT;
      process_WAIT;
      RETURN;
    END IF;

    /* -------------------------
     *
     * PARSE #68:c=0,e=15,p=0,cr=0,cu=0,mis=0,r=0,dep=1,og=4,tim=1175904330100277
     * EXEC #68:c=0,e=77,p=0,cr=0,cu=0,mis=0,r=0,dep=1,og=4,tim=1175904330100479
     * FETCH #68:c=0,e=181,p=0,cr=5,cu=0,mis=0,r=1,dep=1,og=4,tim=1175904330100688
     *
     * ------------------------- */
    IF s_line_type IN (LT_FETCH, LT_EXEC, LT_PARSE, LT_UNMAP, LT_SORT_UNMAP) THEN
      process_10046;
      call_rec := NULL;
      IF s_line_type = LT_FETCH THEN
        call_rec.call_name := 'FETCH';
        call_rec.call      := trca$g.CALL_FETCH;
        s_fetch_call_count := s_fetch_call_count + 1;
      ELSIF s_line_type = LT_EXEC THEN
        call_rec.call_name := 'EXEC';
        call_rec.call      := trca$g.CALL_EXEC;
        s_exec_call_count  := s_exec_call_count + 1;
      ELSIF s_line_type = LT_PARSE THEN
        call_rec.call_name := 'PARSE';
        call_rec.call      := trca$g.CALL_PARSE;
        s_parse_call_count := s_parse_call_count + 1;
      ELSIF s_line_type = LT_UNMAP THEN
        call_rec.call_name := 'UNMAP';
        call_rec.call      := trca$g.CALL_UNMAP;
        s_unmap_call_count := s_unmap_call_count + 1;
      ELSE -- LT_SORT_UNMAP
        call_rec.call_name := 'SORT UNMAP';
        call_rec.call      := trca$g.CALL_SORT_UNMAP;
        s_sort_unmap_call_count := s_sort_unmap_call_count + 1;
      END IF;
      parse_CALL;
      process_CALL;
      RETURN;
    END IF;

    /* -------------------------
     *
     * CLOSE #62:c=0,e=0,dep=1,type=3,tim=1251735622602051
     *
     * ------------------------- */
    IF s_line_type = LT_CLOSE THEN
      process_10046;
      RETURN;
    END IF;

    /* -------------------------
     *
     * BINDS #80:
     *
     * ------------------------- */
    IF s_line_type = LT_BINDS THEN
      process_10046;
      parse_BINDS;
      process_BINDS;
      s_state_BINDS := TRUE;
      RETURN;
    END IF;

    /* -------------------------
     *
     * STAT #43 id=1 cnt=0 pid=0 pos=1 obj=0 op='SORT ORDER BY '
     * STAT #43 id=2 cnt=0 pid=1 pos=1 obj=0 op='NESTED LOOPS  '
     * STAT #5 id=1 cnt=1 pid=0 pos=1 obj=20 op='TABLE ACCESS BY INDEX ROWID ICOL$ (cr=4 pr=1 pw=0 time=10000 us)'
     * STAT #5 id=2 cnt=1 pid=1 pos=1 obj=37 op='INDEX RANGE SCAN I_ICOL1 (cr=3 pr=1 pw=0 time=10000 us)'
     * STAT #6 id=1 cnt=1 pid=0 pos=1 obj=0 op='SORT ORDER BY (cr=7 pr=3 pw=3 time=0 us cost=11 size=327 card=3)'
     *
     * ------------------------- */
    IF s_line_type = LT_STAT THEN
      process_10046;
      parse_STAT;
      process_STAT;
      RETURN;
    END IF;

    /* -------------------------
     *
     * PARSING IN CURSOR #93 len=40 dep=1 uid=0 oct=7 lid=0 tim=1175904330103822 hv=1932955448 ad='6c351458'
     * delete from superobj$ where subobj# = :1
     * END OF STMT
     * PARSING IN CURSOR #19 len=269 dep=2 uid=0 oct=3 lid=0 tim=1211894891974035 hv=2863336729 ad='38ef0b90' sqlid='6xrt7afpaq38t'
     * select  case when (u.type# = 2)          then           (select u1.spare2 from user$ u1 where u1.user# = o.owner#)         else           (select ob.obj# from obj$ ob where ob.name = 'ORA$BASE')         end from obj$ o, user$ u where o.obj# = :1  and u.user# = o.owner#
     * END OF STMT
     *
     * ------------------------- */
    IF s_line_type = LT_PARSING_IN_CURSOR THEN
      process_10046;
      parse_PARSING_IN_CURSOR;
      process_PARSING_IN_CURSOR;
      s_state_STATEMENT := TRUE;

      -- prapare to receive SQL statement in line(s) below
      SYS.DBMS_LOB.CREATETEMPORARY (
        lob_loc => s_sql_fulltext,
        cache   => FALSE );
      RETURN;
    END IF;

    /* -------------------------
     *
     * XCTEND rlbk=0, rd_only=0
     *
     * ------------------------- */
    IF s_line_type = LT_XCTEND THEN
      process_10046;
      parse_XCTEND;
      RETURN;
    END IF;

    /* -------------------------
     *
     * PARSE ERROR #4:len=31 dep=0 uid=564 oct=3 lid=564 tim=1181559630466515 err=904
     * SELECT owner2 FROM trca_object
     * WAIT #4: nam='SQL*Net break/reset to client' ela= 18 driver id=1413697536 break?=1 p3=0 obj#=24979 tim=1181559630466684
     *
     * ------------------------- */
    IF s_line_type = LT_PARSE_ERROR THEN
      process_10046;
      parse_PARSE_ERROR;
      process_PARSING_IN_CURSOR;
      s_state_STATEMENT_ERROR := TRUE;

      -- prapare to receive SQL statement in line(s) below
      SYS.DBMS_LOB.CREATETEMPORARY (
        lob_loc => s_sql_fulltext,
        cache   => FALSE );
      RETURN;
    END IF;

    /* -------------------------
     *
     * *** SESSION ID:(23.10830) 2008-02-27 10:26:39.010
     *
     * ------------------------- */
    IF s_line_type = LT_SESSION THEN
      process_10046;
      parse_SESSION;
      RETURN;
    END IF;

    /* -------------------------
     *
     * ERROR #1:err=1422 tim=2296528706
     *
     * ------------------------- */
    IF s_line_type = LT_ERROR THEN
      process_10046;
      parse_ERROR;
      process_ERROR;
      RETURN;
    END IF;

    /* -------------------------
     *
     * Trace Header
     *
     * ------------------------- */
    IF s_session_id IS NULL AND p_line_number <= 100 THEN
      process_10046;
      process_HEADER;
      RETURN;
    END IF;

    /* -------------------------
     *
     * *** DUMP%
     *
     * ------------------------- */
    IF s_line_type = LT_TRUNCATION THEN
      process_10046;
      RETURN;
    END IF;

    /* -------------------------
     *
     * =====================%
     *
     * ------------------------- */
    IF s_line_type = LT_PARSING_SEPARATOR THEN
      process_10046;
      RETURN;
    END IF;

    /* -------------------------
     *
     * *** %
     *
     * ------------------------- */
    IF s_line_type = LT_3_STARS THEN
      process_10046;
      RETURN;
    END IF;

    /* -------------------------
     *
     * Empty lines
     *
     * ------------------------- */
    IF s_line_type = LT_EMPTY THEN
      IF NVL(s_current_trace, 10046) = 10046 THEN
        process_10046;
      ELSE
        process_10053;
      END IF;
      RETURN;
    END IF;

    /* -------------------------
     *
     * Not a 10046 recognized line
     *
     * ------------------------- */
    IF s_line_type = LT_UNRECOGNIZED THEN
      process_10053;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      IF l_line_text IS NOT NULL THEN
        l_line_varchar := l_line_text;
      ELSIF l_line_clob IS NOT NULL THEN
        l_line_varchar := SYS.DBMS_LOB.SUBSTR (
          lob_loc => l_line_clob,
          amount  => 255 );
      END IF;
      print_log('***');
      print_log('*** Module: parse_line');
      print_log('*** Trace line number: '||p_line_number);
      print_log('*** Trace line text: "'||REPLACE(l_line_varchar, LF)||'"');
      print_log('*** '||SQLERRM);
      print_log('***');
      print_log('*** One Trace line has been ignored. Details above. Parsing continues...');
      print_log('***');
  END parse_line;

  /*************************************************************************************/

  /* -------------------------
   *
   * private reset_file_state
   *
   * ------------------------- */
  PROCEDURE reset_file_state
  IS
  BEGIN /* reset_file_state */
    -- line state
    s_line_type              := LT_UNKNOWN;
    s_line_offset            := NULL;

    -- state for BINDS, STATEMENT, HEADER
    s_state_BINDS            := FALSE;
    s_state_BINDS_bind       := FALSE;
    s_state_BINDS_bind_value := FALSE;
    s_state_STATEMENT        := FALSE;
    s_state_STATEMENT_ERROR  := FALSE;

    -- file state
    s_session_id             := NULL;
    s_gap_id                 := NULL;
    s_cursor_num             := NULL;
    s_cursor_id              := NULL;
    s_statement_id           := NULL;
    s_tim                    := NULL;
    s_piece                  := 0;

    -- file state (cache)
    s_wait_id                := 0;
    s_bind_id                := 0;
    s_call_id                := 0;
    s_stat_id                := 0;
    s_curs_id                := 0;

    -- file stats
    s_session_count          := 0;
    s_gap_count              := 0;
    s_transaction_count      := 0;
    s_cursor_count_sys       := 0;
    s_cursor_count_usr       := 0;
    s_statement_count_sys    := 0;
    s_statement_count_usr    := 0;
    s_wait_count_idle        := 0;
    s_wait_count_non_idle    := 0;
    s_wait_ela_idle          := 0;
    s_wait_ela_non_idle      := 0;
    s_bind_sets_count        := 0;
    s_bind_count             := 0;
    s_parse_call_count       := 0;
    s_exec_call_count        := 0;
    s_fetch_call_count       := 0;
    s_unmap_call_count       := 0;
    s_sort_unmap_call_count  := 0;
    s_call_ela               := 0;
    s_call_cpu               := 0;
    s_call_disk              := 0;
    s_call_query             := 0;
    s_call_current           := 0;
    s_call_misses            := 0;
    s_call_rows              := 0;
    s_stat_lines             := 0;
    s_error_lines            := 0;

    -- collections
    cursor_table.DELETE;
    call_table.DELETE;
    session_table.DELETE;
    gap_table.DELETE;
    stored_cursor_table.DELETE;
    dep_table.DELETE;

    -- cache
    wait_cache.DELETE;
    wait_line_cache.DELETE;
    bind_cache.DELETE;
    bind_line_cache.DELETE;
    call_cache.DELETE;
    call_line_cache.DELETE;
    stat_cache.DELETE;
    stat_line_cache.DELETE;
    curs_cache.DELETE;

END reset_file_state;

  /*************************************************************************************/

  /* -------------------------
   *
   * flush_all_CURSORS
   *
   * ------------------------- */
  PROCEDURE flush_all_CURSORS (
    p_tool_execution_id IN INTEGER,
    p_trace_id          IN INTEGER )
  IS
    l_row INTEGER;

  BEGIN /* flush_all_CURSORS */
    IF cursor_table.COUNT > 0 THEN
      l_row := cursor_table.FIRST;

      WHILE (l_row IS NOT NULL)
      LOOP
        flush_CURSOR (
          p_tool_execution_id => p_tool_execution_id,
          p_trace_id          => p_trace_id,
          p_cursor_num        => l_row );

        l_row := cursor_table.NEXT(l_row);
      END LOOP;

      cursor_table.DELETE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Module: flush_all_CURSORS');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_all_CURSORS;

  /*************************************************************************************/

  /* -------------------------
   *
   * flush_all_CALLS
   *
   * ------------------------- */
  PROCEDURE flush_all_CALLS
  IS
    l_row INTEGER;

  BEGIN /* flush_all_CALLS */
    IF call_table.COUNT > 0 THEN
      l_row := call_table.FIRST;

      WHILE (l_row IS NOT NULL)
      LOOP
        print_log(('ignoring '||(call_table(l_row).self_wait_count_idle + call_table(l_row).self_wait_count_non_idle))||' orphan WAIT(s) for CURSOR #'||l_row||': total ela='||(call_table(l_row).self_wait_ela_idle + call_table(l_row).self_wait_ela_non_idle));
        l_row := call_table.NEXT(l_row);
      END LOOP;

      call_table.DELETE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Module: flush_all_CALLS');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_all_CALLS;

  /*************************************************************************************/

  /* -------------------------
   *
   * flush_deps
   *
   * ------------------------- */
  PROCEDURE flush_deps (
    p_tool_execution_id IN INTEGER )
  IS
    call_rec trca$_call%ROWTYPE;
    grp_rec trca$_group%ROWTYPE;

  BEGIN /* flush_deps */
    IF dep_table.COUNT > 0 THEN
      FOR i IN dep_table.FIRST .. dep_table.LAST
      LOOP
        IF dep_table.EXISTS(i) THEN
          s_dummy_group_id := s_dummy_group_id - 1;
          print_log('flushing dep:"'||i||'" dep_id:"'||dep_table(i).dep_id||'" dummy_group_id:"'||s_dummy_group_id||'"');
          call_rec := NULL;
          SELECT trca$_call_id_s.NEXTVAL INTO call_rec.id FROM DUAL;
          SELECT trca$_exec_id_s.NEXTVAL INTO call_rec.exec_id FROM DUAL;
          call_rec.group_id := s_dummy_group_id;
          call_rec.tool_execution_id := p_tool_execution_id;
          call_rec.call := trca$g.CALL_EXEC;
          call_rec.c := dep_table(i).recu_c;
          call_rec.e := dep_table(i).recu_e;
          call_rec.p := dep_table(i).recu_p;
          call_rec.cr := dep_table(i).recu_cr;
          call_rec.cu := dep_table(i).recu_cu;
          call_rec.mis := 0;
          call_rec.r := 0;
          call_rec.dep := i;
          call_rec.tim := s_tim;
          call_rec.dep_id := dep_table(i).dep_id;
          IF i > 0 AND dep_table.EXISTS(i - 1) THEN
            call_rec.parent_dep_id := dep_table(i - 1).dep_id;
          END IF;
          call_rec.recu_c := dep_table(i).recu_c;
          call_rec.recu_e := dep_table(i).recu_e;
          call_rec.recu_p := dep_table(i).recu_p;
          call_rec.recu_cr := dep_table(i).recu_cr;
          call_rec.recu_cu := dep_table(i).recu_cu;
          call_rec.recu_call_count := dep_table(i).recu_call_count;
          call_rec.recu_mis := dep_table(i).recu_mis;
          call_rec.recu_r := dep_table(i).recu_r;
          call_rec.self_wait_count_idle := 0;
          call_rec.self_wait_count_non_idle := 0;
          call_rec.self_wait_ela_idle := 0;
          call_rec.self_wait_ela_non_idle := 0;
          call_rec.recu_wait_count_idle := dep_table(i).recu_wait_count_idle;
          call_rec.recu_wait_count_non_idle := dep_table(i).recu_wait_count_non_idle;
          call_rec.recu_wait_ela_idle := dep_table(i).recu_wait_ela_idle;
          call_rec.recu_wait_ela_non_idle := dep_table(i).recu_wait_ela_non_idle;
          INSERT INTO trca$_call VALUES call_rec;

          grp_rec := NULL;
          grp_rec.id := s_dummy_group_id;
          grp_rec.tool_execution_id := p_tool_execution_id;
          grp_rec.statement_id := -1;
          grp_rec.first_cursor_id := -1;
          grp_rec.uid# := -1;
          grp_rec.lid := -1;
          grp_rec.dep := i;
          INSERT INTO trca$_group VALUES grp_rec;
        END IF;
      END LOOP;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Module: flush_deps');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_deps;

  /*************************************************************************************/

  /* -------------------------
   *
   * private flush_sessions
   *
   * materialize collection session_table
   * into table trca$_session
   *
   * ------------------------- */
  PROCEDURE flush_sessions (
    p_tool_execution_id IN INTEGER,
    p_trace_id          IN INTEGER )
  IS
    l_row   trca$_session.id%TYPE;
    ses_rec trca$_session%ROWTYPE;

  BEGIN /* flush_sessions */
    IF session_table.COUNT > 0 THEN
      l_row := session_table.FIRST;

      WHILE (l_row IS NOT NULL)
      LOOP
        ses_rec.id                   := l_row;
        ses_rec.tool_execution_id    := p_tool_execution_id;
        ses_rec.trace_id             := p_trace_id;
        ses_rec.sid                  := session_table(l_row).sid;
        ses_rec.serial#              := session_table(l_row).serial#;
        ses_rec.session_timestamp    := session_table(l_row).session_timestamp;
        ses_rec.read_only_committed  := session_table(l_row).read_only_committed;
        ses_rec.read_only_rollbacked := session_table(l_row).read_only_rollbacked;
        ses_rec.update_committed     := session_table(l_row).update_committed;
        ses_rec.update_rollbacked    := session_table(l_row).update_rollbacked;

        IF session_table(l_row).tim_first_wait IS NOT NULL AND session_table(l_row).tim_first_call IS NOT NULL THEN
          ses_rec.session_tim     := LEAST(session_table(l_row).tim_first_wait,  session_table(l_row).tim_first_call);
        ELSIF session_table(l_row).tim_first_wait IS NOT NULL THEN
          ses_rec.session_tim     := session_table(l_row).tim_first_wait;
        ELSIF session_table(l_row).tim_first_call IS NOT NULL THEN
          ses_rec.session_tim     := session_table(l_row).tim_first_call;
        ELSE
          ses_rec.session_tim     := NULL;
        END IF;

        IF ses_rec.id IS NOT NULL AND
           ses_rec.tool_execution_id IS NOT NULL AND
           ses_rec.trace_id IS NOT NULL AND
           ses_rec.sid IS NOT NULL AND
           ses_rec.serial# IS NOT NULL AND
           ses_rec.session_timestamp IS NOT NULL THEN
          INSERT INTO trca$_session VALUES ses_rec;
        ELSE
          print_log('invalid session skipped "'||ses_rec.sid||'" "'||ses_rec.serial#||'" "'||ses_rec.session_timestamp||'"');
        END IF;

        l_row := session_table.NEXT(l_row);
      END LOOP;

      session_table.DELETE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Session: '||ses_rec.sid||'.'||ses_rec.serial#);
      print_log('*** Module: flush_sessions');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_sessions;

  /*************************************************************************************/

  /* -------------------------
   *
   * private flush_gaps
   *
   * materialize collection gap_table
   * into table trca$_gap
   *
   * ------------------------- */
  PROCEDURE flush_gaps (
    p_tool_execution_id IN INTEGER,
    p_trace_id          IN INTEGER )
  IS
    l_row   trca$_gap.id%TYPE;
    gap_rec trca$_gap%ROWTYPE;

  BEGIN /* flush_gaps */
    IF gap_table.COUNT > 0 THEN
      l_row := gap_table.FIRST;

      WHILE (l_row IS NOT NULL)
      LOOP
        gap_rec.id                := l_row;
        gap_rec.tool_execution_id := p_tool_execution_id;
        gap_rec.trace_id          := p_trace_id;
        gap_rec.gap_timestamp     := gap_table(l_row).gap_timestamp;
        gap_rec.tim_before        := gap_table(l_row).tim_before;
        gap_rec.tim_after         := gap_table(l_row).tim_after;
        gap_rec.ela_after         := gap_table(l_row).ela_after;
        gap_rec.wait_call_after   := gap_table(l_row).wait_call_after;
        gap_rec.call_id_after     := gap_table(l_row).call_id_after;

        IF gap_rec.id IS NOT NULL AND
           gap_rec.tool_execution_id IS NOT NULL AND
           gap_rec.trace_id IS NOT NULL AND
           gap_rec.gap_timestamp IS NOT NULL THEN
          INSERT INTO trca$_gap VALUES gap_rec;
        ELSE
          print_log('invalid gap skipped "'||gap_rec.gap_timestamp||'"');
        END IF;

        l_row := gap_table.NEXT(l_row);
      END LOOP;

      gap_table.DELETE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Gap: '||gap_rec.gap_timestamp);
      print_log('*** Module: flush_gaps');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_gaps;

  /*************************************************************************************/

  /* -------------------------
   *
   * private parse_file
   *
   * reads one trace file and parses into lines.
   *
   * there are two types of lines according to
   * size: small (varchar2) and big (clob)
   *
   * parse_file is called by parse_main.
   *
   * it uses bfile instead of utl_file since
   * the latter cannot handle lines with length
   * larger than 32767, and some SQL statements
   * in a trace file can be longer than that.
   *
   * ------------------------- */
  PROCEDURE parse_file (
    p_tool_execution_id   IN  INTEGER,
    p_file_name           IN  VARCHAR2,
    p_directory_alias_in  IN  VARCHAR2,
    x_trace_id            OUT INTEGER )
  IS
    l_file_in BFILE;
    l_file_in_len INTEGER := NULL;
    l_file_in_offset INTEGER;
    l_big_line BOOLEAN := FALSE;
    l_buffer VARCHAR2(32767);
    l_buffer_len INTEGER;
    l_chunk VARCHAR2(32767);
    l_chunk_raw RAW(32767);
    l_chunk_len INTEGER;
    l_chunk_offset INTEGER;
    l_chunk_remainder INTEGER;
    l_chunk_tail VARCHAR2(32767) := NULL;
    l_line VARCHAR2(32767);
    l_line_count INTEGER := 0;
    l_line_len INTEGER;
    l_line_clob CLOB;
    l_next_LF INTEGER;
    l_parse_percent NUMBER := 0;
    l_file_in_remainder INTEGER;
    l_temp_clob_count INTEGER := 0;
    l_tool_execution_id INTEGER := p_tool_execution_id;
    l_total_bytes INTEGER := 0;

    /* -------------------------
     *
     * parse_file.record_progress
     *
     * called by parse_file
     * to record progress of parsing process
     *
     * ------------------------- */
    PROCEDURE record_progress
    IS
    BEGIN /* parse_file.record_progress */
      UPDATE trca$_trace
         SET parsed_lines  = l_line_count,
             parsed_bytes  = l_total_bytes
       WHERE id            = x_trace_id;
      COMMIT;
    END record_progress;

  /*************************************************************************************/

  BEGIN /* parse_file */
    print_log('-> parse_file');
    print_log('parsing file '||p_file_name||' in '||trca$g.get_directory_path(p_directory_alias_in));
    l_file_in := BFILENAME (p_directory_alias_in, p_file_name);
    SYS.DBMS_LOB.FILEOPEN (file_loc => l_file_in);
    l_file_in_len := SYS.DBMS_LOB.GETLENGTH(file_loc => l_file_in);

    -- split trace into 10046 and 10053
    IF s_split_trace THEN
      s_10046_file_rec := NULL;
      s_10046_file_rec.tool_execution_id := p_tool_execution_id;
      s_10046_file_rec.file_type := '10046';
      s_10046_file_rec.filename := s_10046_trace_filename;
      s_10046_file_rec.file_date := SYSDATE;
      s_10046_file_rec.username := USER;

      s_10053_file_rec := NULL;
      s_10053_file_rec.tool_execution_id := p_tool_execution_id;
      s_10053_file_rec.file_type := '10053';
      s_10053_file_rec.filename := s_10053_trace_filename;
      s_10053_file_rec.file_date := SYSDATE;
      s_10053_file_rec.username := USER;
    END IF;

    SELECT trca$_trace_id_s.NEXTVAL INTO x_trace_id FROM DUAL;
    INSERT INTO trca$_trace (id, tool_execution_id, file_name, file_len, status, parse_start, parsed_lines, parsed_bytes)
    VALUES (x_trace_id, l_tool_execution_id, p_file_name, l_file_in_len, 'PARSING', SYSDATE, 0, 0);
    COMMIT;

    -- initialization
    reset_file_state;
    trca$g.reset_session_longops;

    -- prepare to read bfile into chunks
    l_file_in_offset := 1;
    l_file_in_remainder := l_file_in_len;

    WHILE l_file_in_remainder > 0
    LOOP
      l_chunk_len := LEAST(l_file_in_remainder, CHUNK_MAX_SIZE);

      -- read next raw chunk out of bfile
      SYS.DBMS_LOB.READ (
        file_loc => l_file_in,
        amount   => l_chunk_len,
        offset   => l_file_in_offset,
        buffer   => l_chunk_raw );

      -- chunk came as raw and it is needed as char
      l_chunk := SYS.UTL_RAW.CAST_TO_VARCHAR2 (r => l_chunk_raw);

      -- if last chunk then append a LF (if there isn't one as last byte of chunk)
      IF l_chunk_len < CHUNK_MAX_SIZE AND SUBSTR(l_chunk, l_chunk_len, 1) <> LF THEN
        l_chunk := l_chunk||LF;
        l_chunk_len := l_chunk_len + 1;
      END IF;

      -- prepare to read one chunk into one or many lines
      l_chunk_offset := 1;
      l_chunk_remainder := l_chunk_len;

      WHILE l_chunk_remainder > 0
      LOOP
        -- finds the absolute position of the next LF within the chunk
        l_next_LF := INSTR(l_chunk, LF, l_chunk_offset); -- this pointer is absolute and no relative to offset

        IF l_next_LF > 0 THEN -- chunk has one or many lines still, maybe the tail of a big line
          l_line := l_chunk_tail||SUBSTR(l_chunk, l_chunk_offset, (l_next_LF - l_chunk_offset + 1));
          l_line_len := NVL(LENGTH(l_line), 0);
          l_line_count := l_line_count + 1;

          IF l_big_line THEN -- a big line that started in a prior chunk will end here
            SYS.DBMS_LOB.WRITEAPPEND (
              lob_loc => l_line_clob,
              amount  => l_line_len, -- last piece of the big line
              buffer  => l_line );

            l_line := NULL;
            l_line_len := NVL(DBMS_LOB.GETLENGTH (lob_loc => l_line_clob), 0); -- full big line, not just the tail

            parse_line ( -- big line
              p_tool_execution_id => l_tool_execution_id,
              p_trace_id          => x_trace_id,
              p_line_len          => l_line_len,
              p_line_number       => l_line_count,
              p_line_text         => l_line,
              p_line_clob         => l_line_clob );

            SYS.DBMS_LOB.FREETEMPORARY (lob_loc => l_line_clob);
            l_big_line := FALSE;
          ELSE -- not the tail of a big line, thus it must be a new small line
            l_line_clob := NULL;

            parse_line ( -- small line
              p_tool_execution_id => l_tool_execution_id,
              p_trace_id          => x_trace_id,
              p_line_len          => l_line_len,
              p_line_number       => l_line_count,
              p_line_text         => l_line,
              p_line_clob         => l_line_clob );
          END IF;

          l_total_bytes := l_total_bytes + l_line_len;
          l_chunk_tail := NULL; -- used only once
          l_chunk_offset := l_next_LF + 1; -- move chunk offset forward
          l_chunk_remainder := l_chunk_len - l_next_LF; -- reduce chunk remainder accordingly
        ELSIF l_chunk_remainder = l_chunk_len THEN -- big line that may span several chunks (there was no LF)
          IF NOT l_big_line THEN -- first piece of big line
            SYS.DBMS_LOB.CREATETEMPORARY (
              lob_loc => l_line_clob,
              cache   => FALSE );
            l_temp_clob_count := l_temp_clob_count + 1;
            l_big_line := TRUE; -- so create temporary only happens once per big line (on first big chunk)
          END IF;

          SYS.DBMS_LOB.WRITEAPPEND (
            lob_loc => l_line_clob,
            amount  => NVL(LENGTH(l_chunk_tail), 0) + l_chunk_len, -- tail came from prior chunk
            buffer  => l_chunk_tail||l_chunk );

          l_chunk_tail := NULL; -- used only once
          l_chunk_remainder := 0; -- trigger end of chunk
        ELSE -- last piece of a chunk (after last LF within a chunk)
          l_chunk_tail := SUBSTR(l_chunk, l_chunk_offset); -- delay its processing (notice it does not affect counters)
          l_chunk_remainder := 0; -- trigger end of chunk
        END IF;
      END LOOP;

      l_file_in_offset := l_file_in_offset + l_chunk_len; -- move bfile offset forward
      l_file_in_remainder := l_file_in_remainder - l_chunk_len; -- reduce bfile remainder accordingly
      l_parse_percent := ROUND(l_total_bytes * 100 / GREATEST(l_file_in_len, 1), 1); -- keep track of progress

      IF MOD(l_line_count, COMMIT_RATE) = 0 THEN
        record_progress;
      END IF;

      IF l_total_bytes > TO_NUMBER(trca$g.g_trace_file_max_size_bytes) THEN
        l_file_in_remainder := 0; -- trigger early termination
      END IF;

      trca$g.set_session_longops (
        p_op_name     => LOWER(TRIM(trca$g.g_tool_administer_schema))||'.trca$p.parse_file',
        p_target      => p_tool_execution_id,
        p_sofar       => l_total_bytes,
        p_totalwork   => l_file_in_len,
        p_target_desc => p_file_name,
        p_units       => 'bytes' );
    END LOOP;

    -- close trace
    SYS.DBMS_LOB.FILECLOSE (file_loc => l_file_in);
    IF s_split_trace THEN
      s_10046_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_10046_file_rec.file_text);
      INSERT INTO trca$_file VALUES s_10046_file_rec;
      s_10053_file_rec.file_size := SYS.DBMS_LOB.GETLENGTH(s_10053_file_rec.file_text);
      INSERT INTO trca$_file VALUES s_10053_file_rec;
    END IF;

    IF s_analyze_trace THEN
      -- process_orphan_waits
      DECLARE
        l_cursor_num NUMBER;
        PROCEDURE process_line (p_line IN VARCHAR2)
        IS
        BEGIN
          print_log(p_line);
          l_line := p_line||LF;
          l_line_clob := NULL;
          l_line_count := l_line_count + 1;
          l_line_len := NVL(LENGTH(l_line), 0);
          parse_line ( -- small line
            p_tool_execution_id => l_tool_execution_id,
            p_trace_id          => x_trace_id,
            p_line_len          => l_line_len,
            p_line_number       => l_line_count,
            p_line_text         => l_line,
            p_line_clob         => l_line_clob );
        END process_line;
      BEGIN
        print_log('process_orphan_waits: creating some fake trace lines to aggregate waits into calls and cursors');
        IF call_table.COUNT > 0 THEN
          l_cursor_num := call_table.FIRST;
          WHILE (l_cursor_num IS NOT NULL)
          LOOP
            process_line('=====================');
            process_line('PARSING IN CURSOR #'||l_cursor_num||' len='||TO_CHAR(LENGTH(l_cursor_num) + 8)||' dep=0 uid=0 oct=0 lid=0 tim='||s_tim||' hv=0 ad=''0''');
            process_line('CURSOR #'||l_cursor_num);
            process_line('END OF STMT');
            process_line('EXEC #'||l_cursor_num||':c=0,e='||TO_CHAR(call_table(l_cursor_num).self_wait_ela_idle + call_table(l_cursor_num).self_wait_ela_non_idle)||',p=0,cr=0,cu=0,mis=0,r=0,dep=0,og=1,plh=0,tim='||s_tim);
            l_cursor_num := call_table.NEXT(l_cursor_num);
          END LOOP;
          process_line('=====================');
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          print_log('***');
          print_log('*** Module: process_orphan_WAITS');
          print_log('*** '||SQLERRM);
          RAISE;
      END;

      -- cleanup
      flush_all_CURSORS (
        p_tool_execution_id => l_tool_execution_id,
        p_trace_id          => x_trace_id );
      flush_all_CALLS;
      flush_deps (
        p_tool_execution_id => l_tool_execution_id );
      flush_sessions (
        p_tool_execution_id => l_tool_execution_id,
        p_trace_id          => x_trace_id );
      flush_gaps (
        p_tool_execution_id => l_tool_execution_id,
        p_trace_id          => x_trace_id );

      -- cache
      flush_WAIT_cache;
      flush_BIND_cache;
      flush_CALL_cache;
      flush_STAT_cache;
      flush_CURSOR_cache; -- has to execute after flush_all_CURSORS

      -- collections
      stored_cursor_table.DELETE;
      dep_table.DELETE;
    END IF;

    -- record completion of parsing of one trace
    record_progress;
    UPDATE trca$_trace
       SET status    = 'COMPLETED',
           parse_end = SYSDATE
     WHERE id        = x_trace_id;
    COMMIT;

    IF s_analyze_trace THEN
      -- unique SQL statements in trace file
      SELECT COUNT(DISTINCT(statement_id))
        INTO s_statement_count_usr
        FROM trca$_cursor
       WHERE trace_id = x_trace_id
         AND uid# <> USYS
         AND statement_id <> -1; -- unknown
      SELECT COUNT(DISTINCT(statement_id))
        INTO s_statement_count_sys
        FROM trca$_cursor
       WHERE trace_id = x_trace_id
         AND uid# = USYS
         AND statement_id <> -1; -- unknown

      print_log('+');
      print_log('|'||LPAD(s_bind_sets_count, 20)||'  BINDS sets.');
      print_log('|'||LPAD(s_bind_count, 20)||'  binds.');
      print_log('|'||LPAD(s_parse_call_count, 20)||'  PARSE CALLs.');
      print_log('|'||LPAD(s_exec_call_count, 20)||'  EXEC CALLs.');
      print_log('|'||LPAD(s_fetch_call_count, 20)||'  FETCH CALLs.');
      print_log('|'||LPAD(s_unmap_call_count, 20)||'  UNMAP CALLs.');
      print_log('|'||LPAD(s_sort_unmap_call_count, 20)||'  SORT UNMAP CALLs.');
      print_log('|'||LPAD(s_call_ela, 20)||'  CALL elapsed.');
      print_log('|'||LPAD(s_call_cpu, 20)||'  CALL cpu.');
      print_log('|'||LPAD(s_call_disk, 20)||'  CALL disk.');
      print_log('|'||LPAD(s_call_query, 20)||'  CALL query.');
      print_log('|'||LPAD(s_call_current, 20)||'  CALL current.');
      print_log('|'||LPAD(s_call_misses, 20)||'  CALL misses.');
      print_log('|'||LPAD(s_call_rows, 20)||'  CALL rows.');
      print_log('|'||LPAD(s_wait_count_idle, 20)||'  WAIT count idle event.');
      print_log('|'||LPAD(s_wait_count_non_idle, 20)||'  WAIT count non-idle event.');
      print_log('|'||LPAD(s_wait_ela_idle, 20)||'  WAIT ela idle event.');
      print_log('|'||LPAD(s_wait_ela_non_idle, 20)||'  WAIT ela non-idle event.');
      print_log('|'||LPAD(s_stat_lines, 20)||'  STAT lines.');
      print_log('|'||LPAD(s_error_lines, 20)||'  ERROR lines.');
      print_log('+');
      print_log('|'||LPAD(s_session_count, 20)||'  sessions in tracefile.');
      print_log('|'||LPAD(s_transaction_count, 20)||'  transactions in tracefile.');
      print_log('|'||LPAD(s_gap_count, 20)||'  gaps in tracefile.');
      print_log('|'||LPAD(s_cursor_count_usr, 20)||'  user SQL statements in trace file.');
      print_log('|'||LPAD(s_cursor_count_sys, 20)||'  internal SQL statements in trace file.');
      print_log('|'||LPAD((s_cursor_count_usr + s_cursor_count_sys), 20)||'  SQL statements in trace file.');
      print_log('|'||LPAD(s_statement_count_usr, 20)||'  user unique SQL statements in trace file.');
      print_log('|'||LPAD(s_statement_count_sys, 20)||'  internal unique SQL statements in trace file.');
      print_log('|'||LPAD((s_statement_count_usr + s_statement_count_sys), 20)||'  unique SQL statements in trace file.');
      print_log('|'||LPAD(l_line_count, 20)||'  lines in trace file.');
      print_log('|'||LPAD(l_temp_clob_count, 20)||'  long lines in trace file.');
      print_log('|'||LPAD(ROUND(s_call_ela/trca$g.TIM_FACTOR), 20)||'  elapsed seconds in trace file.');
      print_log('+');
    END IF;

    print_log('parsed '||p_file_name||' (input '||l_file_in_len||' bytes, parsed as '||l_total_bytes||' bytes)');
    print_log('<- parse_file');
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Module: parse_file');
      print_log('*** File name: '||p_file_name);
      print_log('*** File size: '||NVL(TO_CHAR(l_file_in_len), 'UNKNOWN')||' bytes');
      print_log('*** Temp CLOB Count: '||l_temp_clob_count);
      print_log('*** Lines parsed: '||l_line_count);
      print_log('*** Bytes parsed: '||l_total_bytes);
      print_log('*** Parsing progress: '||l_parse_percent||'%');
      print_log('*** '||SQLERRM);
      -- records error and abort
      UPDATE trca$_trace
         SET status    = 'ERROR',
             parse_end = NVL(parse_end, SYSDATE)
       WHERE id        = x_trace_id;
      COMMIT;
      RAISE;
  END parse_file;

  /*************************************************************************************/

  /* -------------------------
   *
   * private reset_execution_state
   *
   * ------------------------- */
  PROCEDURE reset_execution_state
  IS
  BEGIN /* reset_execution_state */
    -- execution_state
    s_event_name             := NULL;
    s_event#                 := NULL;
    s_idle                   := NULL;

    SELECT MAX(event#) INTO s_event#_s FROM trca$_event_name;

    -- global
    trca$g.g_time            := NULL;
    trca$g.g_sqlid           := NULL;
    trca$g.g_plh             := NULL;
    trca$g.g_card            := NULL;
    s_dummy_group_id         := 0;

    -- collections
    event_name_table.DELETE;
    group_table.DELETE;

  END reset_execution_state;

  /*************************************************************************************/

  /* -------------------------
   *
   * private flush_trace_events
   *
   * materialize collection event_name_table
   * into table trca$_wait_event_name
   *
   * ------------------------- */
  PROCEDURE flush_trace_events (
    p_tool_execution_id IN INTEGER )
  IS
    l_row   trca$_event_name.name%TYPE;
    tev_rec trca$_wait_event_name%ROWTYPE;

  BEGIN /* flush_trace_events */
    IF event_name_table.COUNT > 0 THEN
      l_row := event_name_table.FIRST;

      WHILE (l_row IS NOT NULL)
      LOOP
        tev_rec.tool_execution_id := p_tool_execution_id;
        tev_rec.event#            := event_name_table(l_row).event#;
        tev_rec.name              := l_row;
        tev_rec.wait_class        := event_name_table(l_row).wait_class;
        tev_rec.idle              := event_name_table(l_row).idle;
        tev_rec.source            := event_name_table(l_row).source;
        tev_rec.parameter1v       := event_name_table(l_row).parameter1v;
        tev_rec.parameter2v       := event_name_table(l_row).parameter2v;
        tev_rec.parameter3v       := event_name_table(l_row).parameter3v;
        tev_rec.parameter1t       := event_name_table(l_row).parameter1t;
        tev_rec.parameter2t       := event_name_table(l_row).parameter2t;
        tev_rec.parameter3t       := event_name_table(l_row).parameter3t;

        INSERT INTO trca$_wait_event_name VALUES tev_rec;

        l_row := event_name_table.NEXT(l_row);
      END LOOP;

      event_name_table.DELETE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Name: '||tev_rec.name);
      print_log('*** Module: flush_trace_events');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_trace_events;

  /*************************************************************************************/

  /* -------------------------
   *
   * private flush_groups
   *
   * materialize collection group_table
   * into table trca$_group
   *
   * ------------------------- */
  PROCEDURE flush_groups (
    p_tool_execution_id IN INTEGER )
  IS
    l_row   trca$_group.id%TYPE;
    grp_rec trca$_group%ROWTYPE;

  BEGIN /* flush_groups */
    IF group_table.COUNT > 0 THEN
      l_row := group_table.FIRST;

      WHILE (l_row IS NOT NULL)
      LOOP
        grp_rec.id                := l_row;
        grp_rec.tool_execution_id := p_tool_execution_id;
        grp_rec.statement_id      := group_table(l_row).statement_id;
        grp_rec.first_cursor_id   := group_table(l_row).first_cursor_id;
        grp_rec.uid#              := group_table(l_row).uid#;
        grp_rec.lid               := group_table(l_row).lid;
        grp_rec.dep               := group_table(l_row).dep;
        grp_rec.err               := group_table(l_row).err;
        grp_rec.first_exec_id     := group_table(l_row).first_exec_id;
        grp_rec.last_exec_id      := group_table(l_row).last_exec_id;

        IF grp_rec.id IS NOT NULL AND
           grp_rec.tool_execution_id IS NOT NULL AND
           grp_rec.statement_id IS NOT NULL AND
           grp_rec.first_cursor_id IS NOT NULL AND
           grp_rec.uid# IS NOT NULL AND
           grp_rec.lid IS NOT NULL AND
           grp_rec.dep IS NOT NULL THEN
          INSERT INTO trca$_group VALUES grp_rec;
        ELSE
          print_log('invalid group skipped "'||grp_rec.statement_id||'" "'||grp_rec.first_cursor_id||'" "'||grp_rec.first_exec_id||'" "'||grp_rec.last_exec_id||'"');
        END IF;

        l_row := group_table.NEXT(l_row);
      END LOOP;

      group_table.DELETE;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      print_log('***');
      print_log('*** Group: '||grp_rec.id);
      print_log('*** Module: flush_groups');
      print_log('*** '||SQLERRM);
      RAISE;
  END flush_groups;

  /*************************************************************************************/

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
    x_10053_trace          OUT CLOB )
  IS
    l_file_in SYS.UTL_FILE.FILE_TYPE;

    l_bytes_count INTEGER := 0;
    l_directory_in_alias VARCHAR2(32767);
    l_directory_in_path VARCHAR2(32767);
    l_directory_in_path_prior VARCHAR2(32767);
    l_directory_out_path VARCHAR2(32767);
    l_eof  BOOLEAN := FALSE;
    l_file_in_block_size INTEGER;
    l_file_in_exists BOOLEAN;
    l_file_in_length INTEGER := 0;
    l_file_in_name VARCHAR2(32767);
    l_files_count INTEGER := 0;
    l_line VARCHAR2(32767) := NULL;
    l_lines_count INTEGER := 0;
    l_trace_id INTEGER;

    /* -------------------------
     *
     * parse_main.get_line
     *
     * reads lines out of the control file
     * which contains one trace filename per line
     *
     * ------------------------- */
    PROCEDURE get_line IS
    BEGIN
      SYS.UTL_FILE.GET_LINE (
       file   => l_file_in,
       buffer => l_line );

      IF INSTR(l_line, CR) > 0 THEN
        l_line := REPLACE(l_line, CR);
      END IF;

      l_lines_count := l_lines_count + 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_eof := TRUE;
      WHEN OTHERS THEN
        print_log('***');
        print_log('*** Module: get_line');
        print_log('*** Line Count: '||l_lines_count);
        print_log('*** '||SQLERRM);
        RAISE;
    END get_line;

    /* -------------------------
     *
     * parse_main.validate_file
     *
     * looks for file in directory and
     * returns attributes
     *
     * ------------------------- */
    PROCEDURE validate_file (
      p_directory_alias IN VARCHAR2,
      p_file_name2      IN VARCHAR2,
      x_directory_path  OUT VARCHAR2,
      x_file_exists     OUT BOOLEAN,
      x_file_length     OUT NUMBER,
      x_file_block_size OUT NUMBER )
    IS
    BEGIN
      -- validate file name
      IF p_file_name2 LIKE '%/%' OR p_file_name2 LIKE '%'||BACK_SLASH||'%' THEN
        RAISE_APPLICATION_ERROR(-20114, '*** Filename '||p_file_name2||' cannot contain "/" or "'||BACK_SLASH||'". Enter filename excluding path.');
      END IF;

      x_directory_path := trca$g.get_directory_path(p_directory_alias);

      -- validate directory path
      IF x_directory_path IS NULL THEN
        RAISE_APPLICATION_ERROR(-20100, '*** Directory alias '||p_directory_alias||' does not exist in DBA_DIRECTORIES');
      ELSIF x_directory_path LIKE '%?%' OR x_directory_path LIKE '%*%' THEN
        RAISE_APPLICATION_ERROR(-20110, '*** Directory path cannot contain "?" or "*":'||p_directory_alias);
      END IF;

      -- find directory path depth separator (/ or \)
      IF INSTR(x_directory_path, '/') > 0 THEN
        trca$g.g_dir_path_dep_sep := '/';
      ELSIF INSTR(x_directory_path, BACK_SLASH) > 0 THEN
        trca$g.g_dir_path_dep_sep := BACK_SLASH;
      ELSE
        RAISE_APPLICATION_ERROR(-20112, '*** Directory path must contain "/" or "'||BACK_SLASH||'":'||x_directory_path);
      END IF;

      -- finding file and its size
      print_log('analyzing input file '||p_file_name2||' in '||x_directory_path||' ('||p_directory_alias||')');
      BEGIN
        SYS.UTL_FILE.FGETATTR (
          location     => p_directory_alias,
          filename     => p_file_name2,
          fexists      => x_file_exists,
          file_length  => x_file_length,
          block_size   => x_file_block_size );
      EXCEPTION
        WHEN OTHERS THEN
          print_log('***');
          print_log('*** Call: SYS.UTL_FILE.FGETATTR 1');
          print_log('*** Location: '||p_directory_alias);
          print_log('*** Filename: '||p_file_name2);
          print_log('*** '||SQLERRM);
          RAISE;
      END;
    END validate_file;

  /*************************************************************************************/

  BEGIN /* parse_main */
    IF NOT trca$g.g_log_open THEN
      RETURN;
    END IF;
    print_log('=> parse_main');

    set_nls;

    -- file name
    l_file_in_name := TRIM(p_file_name);

    IF l_file_in_name = 'trca$_files' THEN
      l_directory_in_alias := NULL;
      l_directory_in_path := NULL;
      trca$g.g_path_and_filename := l_file_in_name;
    ELSE
      -- validate file
      l_directory_in_alias := NVL(UPPER(p_directory_alias_in), trca$g.g_input1_dir);
      validate_file(l_directory_in_alias, l_file_in_name, l_directory_in_path, l_file_in_exists, l_file_in_length, l_file_in_block_size);

       -- prepare to identify single trace with its path
      trca$g.g_path_and_filename := NULL;

      IF l_file_in_exists THEN
        trca$g.g_path_and_filename := l_directory_in_path||trca$g.g_dir_path_dep_sep||l_file_in_name;
      ELSE -- if file does not exist, look into alternate directory
        l_directory_in_alias := trca$g.g_input2_dir;
        l_directory_in_path_prior := l_directory_in_path;
        validate_file(l_directory_in_alias, l_file_in_name, l_directory_in_path, l_file_in_exists, l_file_in_length, l_file_in_block_size);

        IF l_file_in_exists THEN
          trca$g.g_path_and_filename := l_directory_in_path||trca$g.g_dir_path_dep_sep||l_file_in_name;
        ELSE
          RAISE_APPLICATION_ERROR(-20120, '*** File '||l_file_in_name||' not found in '||l_directory_in_path_prior||' or '||l_directory_in_path);
        END IF;
      END IF;
    END IF;

    -- directory and file exist and can be accessed
    UPDATE trca$_tool_execution
       SET file_name       = l_file_in_name,
           directory_alias = l_directory_in_alias,
           directory_path  = l_directory_in_path,
           parse_start     = SYSDATE
     WHERE id = p_tool_execution_id;
    COMMIT;

    -- initialization
    reset_execution_state;

    -- if filename ends with .trc then this is a single file
    IF l_file_in_name NOT LIKE '%.trc%' THEN -- control file with multiple traces (file names)
      s_single_trace         := FALSE;
      s_analyze_trace        := TRUE;
      s_10046_trace_filename := NULL;
      s_10053_trace_filename := NULL;
      s_split_trace          := FALSE;
      s_copy_10046           := FALSE;
      s_copy_10053           := FALSE;

      IF l_file_in_name <> 'trca$_files' THEN
        -- open control file
        BEGIN
          l_file_in := SYS.UTL_FILE.FOPEN (
            location     => l_directory_in_alias,
            filename     => l_file_in_name,
            open_mode    => 'R',
            max_linesize => 32767 );
        EXCEPTION
          WHEN OTHERS THEN
            print_log('***');
            print_log('*** Call: SYS.UTL_FILE.FOPEN');
            print_log('*** Location: '||l_directory_in_alias);
            print_log('*** Filename: '||l_file_in_name);
            print_log('*** Open Mode: R');
            print_log('*** Max Linesize: 32767');
            print_log('*** '||SQLERRM);
            RAISE;
        END;

        -- prepare to identify first trace in control file
        trca$g.g_path_and_filename := NULL;

        -- verify each file in control file before trying to parse them
        BEGIN
          l_eof := FALSE;
          DELETE trca$_files;
          LOOP
            get_line; -- l_line contains the name of a trace file
            EXIT WHEN l_eof;

            IF l_line IS NOT NULL THEN
              l_file_in_name := TRIM(' ' FROM REPLACE(l_line, ','));

              -- validate file
              l_directory_in_alias := NVL(UPPER(p_directory_alias_in), trca$g.g_input1_dir);
              validate_file(l_directory_in_alias, l_file_in_name, l_directory_in_path, l_file_in_exists, l_file_in_length, l_file_in_block_size);

              IF l_file_in_exists THEN
                INSERT INTO trca$_files VALUES (l_file_in_name, l_directory_in_alias, l_files_count);
                -- get only name of 1st trace
                IF trca$g.g_path_and_filename IS NULL THEN
                  trca$g.g_path_and_filename := l_directory_in_path||trca$g.g_dir_path_dep_sep||l_file_in_name;
                END IF;
              ELSE -- if file does not exist, look into alternate directory
                l_directory_in_alias := trca$g.g_input2_dir;
                l_directory_in_path_prior := l_directory_in_path;
                validate_file(l_directory_in_alias, l_file_in_name, l_directory_in_path, l_file_in_exists, l_file_in_length, l_file_in_block_size);

                IF l_file_in_exists THEN
                  INSERT INTO trca$_files VALUES (l_file_in_name, l_directory_in_alias, l_files_count);
                  -- get only name of 1st trace
                  IF trca$g.g_path_and_filename IS NULL THEN
                    trca$g.g_path_and_filename := l_directory_in_path||trca$g.g_dir_path_dep_sep||l_file_in_name;
                  END IF;
                ELSE
                  RAISE_APPLICATION_ERROR(-20130, '*** File '||l_file_in_name||' not found in '||l_directory_in_path_prior||' or '||l_directory_in_path);
                END IF; -- l_file_in_exists
              END IF; -- l_file_in_exists

              l_files_count := l_files_count + 1;
              l_bytes_count := l_bytes_count + l_file_in_length;
            END IF; -- l_line IS NOT NULL
          END LOOP;
        END;

        -- close control file
        BEGIN
          SYS.UTL_FILE.FCLOSE(file => l_file_in);
        EXCEPTION
          WHEN OTHERS THEN
            print_log('***');
            print_log('*** Call: SYS.UTL_FILE.FCLOSE');
            print_log('*** '||SQLERRM);
            RAISE;
        END;
      END IF; -- l_file_in_name <> 'trca$_files'

      -- parse each trace file found in control file
      FOR i IN (SELECT * FROM trca$_files ORDER BY order_by)
      LOOP
        parse_file (
          p_tool_execution_id   => p_tool_execution_id,
          p_file_name           => i.filename,
          p_directory_alias_in  => i.directory_alias,
          x_trace_id            => l_trace_id );
      END LOOP;
    ELSE -- just one trace
      s_single_trace := TRUE;

      IF p_split = 'YES' AND trca$g.g_split_10046_10053_trc = 'Y' THEN
        s_10046_trace_filename := NVL(p_split_10046_filename, REPLACE(l_file_in_name, '_10053'));
        s_10053_trace_filename := NVL(p_split_10053_filename, REPLACE(l_file_in_name, '_10046'));
        s_split_trace          := TRUE;
        s_copy_10046           := TRUE;
        s_copy_10053           := TRUE;
      ELSE
        s_10046_trace_filename := NULL;
        s_10053_trace_filename := NULL;
        s_split_trace          := FALSE;
        s_copy_10046           := FALSE;
        s_copy_10053           := FALSE;
      END IF;

      IF p_analyze = 'YES' THEN
        s_analyze_trace := TRUE;
      ELSE
        s_analyze_trace := FALSE;
      END IF;

      l_files_count  := 1;
      l_bytes_count  := l_file_in_length;

      parse_file (
        p_tool_execution_id   => p_tool_execution_id,
        p_file_name           => l_file_in_name,
        p_directory_alias_in  => l_directory_in_alias,
        x_trace_id            => l_trace_id );

      IF s_split_trace THEN
        x_10046_trace := s_10046_file_rec.file_text;
        x_10053_trace := s_10053_file_rec.file_text;
      END IF;
    END IF; -- l_file_in_name NOT LIKE '%.trc%'

    IF s_analyze_trace THEN
      -- cleanup
      flush_trace_events (p_tool_execution_id => p_tool_execution_id);
      flush_groups (p_tool_execution_id => p_tool_execution_id);

      -- gather cbo stats
      trca$g.gather_table_stats('trca$_tool_execution');
      trca$g.gather_table_stats('trca$_trace_header');
      trca$g.gather_table_stats('trca$_trace');
      trca$g.gather_table_stats('trca$_gap');
      trca$g.gather_table_stats('trca$_statement');
      trca$g.gather_table_stats('trca$_cursor');
      trca$g.gather_table_stats('trca$_session');
      trca$g.gather_table_stats('trca$_group');
      trca$g.gather_table_stats('trca$_call');
      trca$g.gather_table_stats('trca$_bind');
      trca$g.gather_table_stats('trca$_stat');
      trca$g.gather_table_stats('trca$_error');
      trca$g.gather_table_stats('trca$_wait_event_name');
      trca$g.gather_table_stats('trca$_wait');
    END IF;

    -- recording completion of tool execution
    UPDATE trca$_tool_execution
       SET parse_end  = SYSDATE,
           file_count = l_files_count,
           file_bytes = l_bytes_count
     WHERE id = p_tool_execution_id;
    COMMIT;

    print_log('parsed '||l_files_count||' file(s) (input '||l_bytes_count||' bytes)');
    print_log('first trace: '||trca$g.g_path_and_filename);
    print_log('<= parse_main');
  --EXCEPTION
  --  WHEN OTHERS THEN
  --    print_log('***');
  --    print_log('*** Module: parse_main');
  --    print_log('*** File name: '||l_file_in_name);
  --    print_log('*** Directory: '||l_directory_in_alias||' '||l_directory_in_path);
  --    print_log('*** '||SQLERRM);
  --    print_log('***');
  --    RAISE;
  END parse_main;

  /*************************************************************************************/

END trca$p;
/

SET TERM ON;
SHOW ERRORS;
