COL yymmddhh24miss NEW_V yymmddhh24miss NOPRI;
SELECT TO_CHAR(SYSDATE, 'YYMMDDHH24MISS') yymmddhh24miss FROM DUAL;
SPO &&yymmddhh24miss._03_tacobj.log;
SET ECHO ON TERM OFF VER OFF NUMF "";
REM
REM $Header: 224270.1 tacobj.sql 12.2.171004  October 4th, 2017 carlos.sierra abel.macias@oracle.com $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   carlos.sierra@oracle.com
REM
REM SCRIPT
REM   tacobj.sql
REM
REM DESCRIPTION
REM   This script creates sequences, tables, and indexes owned by schema
REM   TRCANLZR
REM
REM PRE-REQUISITES
REM   1. This script must be executed connected INTERNAL (SYS) as
REM      SYSDBA
REM
REM PARAMETERS
REM   1. None
REM
REM EXECUTION
REM   1. Navigate to trca/install directory
REM   2. Start SQL*Plus connecting as SYS
REM   3. Execute script sqtacobj.sql
REM
REM EXAMPLE
REM   # cd trca/install
REM   # sqlplus / as sysdba
REM   SQL> start tacobj.sql
REM
REM NOTES
REM   1. This script is executed automatically by tacreate.sql
REM   2. For possible errors see tacobj.log file
REM   3. If you want to make all TRCANLZR staging tables permanent,
REM      answer P when asked for "temporary_or_permanent".
REM      Be aware that most large objects have no indexes.
REM
  -- 171004 Extensive replacement of variables to varchar2(257)
  
SET ECHO OFF TERM OFF;

WHENEVER SQLERROR EXIT SQL.SQLCODE;

ALTER SESSION SET NLS_NUMERIC_CHARACTERS = ".,";
ALTER SESSION SET NLS_LENGTH_SEMANTICS = CHAR;

DECLARE
  rdbms_release NUMBER;
BEGIN
  IF USER <> 'SYS' THEN
    RAISE_APPLICATION_ERROR(-20100, 'Install failed - should be executed connected as SYS, not as '||USER);
  END IF;
  SELECT TO_NUMBER(SUBSTR(version, 1, INSTR(version, '.', 1, 2) - 1))
    INTO rdbms_release
    FROM v$instance;
  IF rdbms_release < 9.2 THEN
    RAISE_APPLICATION_ERROR(-20200, 'Install failed - should be installed in 9i(9.2) or higher, not in '||rdbms_release);
  END IF;
END;
/

WHENEVER SQLERROR CONTINUE;

DEF on_commit_preserve_rows = "ON COMMIT PRESERVE ROWS";
DEF global_temporary        = "GLOBAL TEMPORARY";
COLUMN on_commit_preserve_rows NEW_VALUE on_commit_preserve_rows;
COLUMN global_temporary NEW_VALUE global_temporary;
SET TERM ON;
SELECT NULL global_temporary, NULL on_commit_preserve_rows
  FROM DUAL
 WHERE SUBSTR(TRIM(UPPER(NVL('&&temporary_or_permanent.', 'T'))), 1, 1) = 'P';
SET ECHO ON TERM OFF;

/* ------------------------------------------------------------------------- */

COL start_with NEW_V start_with NOPRI;
SELECT (NVL(ABS(MOD(SYS.DBMS_RANDOM.RANDOM, 80000)), 0) + 10000) start_with FROM DUAL;

CREATE SEQUENCE &&tool_repository_schema..trca$_tool_execution_id_s START WITH &&start_with. NOCACHE;
CREATE SEQUENCE &&tool_repository_schema..trca$_trace_id_s NOCACHE;
CREATE SEQUENCE &&tool_repository_schema..trca$_cursor_id_s;
CREATE SEQUENCE &&tool_repository_schema..trca$_statement_id_s;
CREATE SEQUENCE &&tool_repository_schema..trca$_call_id_s;
CREATE SEQUENCE &&tool_repository_schema..trca$_dep_id_s;
CREATE SEQUENCE &&tool_repository_schema..trca$_exec_id_s;
CREATE SEQUENCE &&tool_repository_schema..trca$_session_id_s;
CREATE SEQUENCE &&tool_repository_schema..trca$_gap_id_s;
CREATE SEQUENCE &&tool_repository_schema..trca$_header_id_s;

GRANT ALL ON &&tool_repository_schema..trca$_tool_execution_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_tool_execution_id_s FOR &&tool_repository_schema..trca$_tool_execution_id_s;

GRANT ALL ON &&tool_repository_schema..trca$_trace_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_trace_id_s FOR &&tool_repository_schema..trca$_trace_id_s;

GRANT ALL ON &&tool_repository_schema..trca$_cursor_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_cursor_id_s FOR &&tool_repository_schema..trca$_cursor_id_s;

GRANT ALL ON &&tool_repository_schema..trca$_statement_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_statement_id_s FOR &&tool_repository_schema..trca$_statement_id_s;

GRANT ALL ON &&tool_repository_schema..trca$_call_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_call_id_s FOR &&tool_repository_schema..trca$_call_id_s;

GRANT ALL ON &&tool_repository_schema..trca$_dep_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_dep_id_s FOR &&tool_repository_schema..trca$_dep_id_s;

GRANT ALL ON &&tool_repository_schema..trca$_exec_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_exec_id_s FOR &&tool_repository_schema..trca$_exec_id_s;

GRANT ALL ON &&tool_repository_schema..trca$_session_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_session_id_s FOR &&tool_repository_schema..trca$_session_id_s;

GRANT ALL ON &&tool_repository_schema..trca$_gap_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_gap_id_s FOR &&tool_repository_schema..trca$_gap_id_s;

GRANT ALL ON &&tool_repository_schema..trca$_header_id_s TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_header_id_s FOR &&tool_repository_schema..trca$_header_id_s;

/* ------------------------------------------------------------------------- */

-- external dict table generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_control (
  refresh_date               VARCHAR2(255),
  database_id                VARCHAR2(255),
  database_name              VARCHAR2(255),
  instance_id                VARCHAR2(255),
  instance_name              VARCHAR2(255),
  host_name                  VARCHAR2(255),
  platform                   VARCHAR2(255),
  rdbms_version              VARCHAR2(255),
  db_files                   VARCHAR2(255)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_CONTROL.bad'
  LOGFILE 'TRCA_CONTROL.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_CONTROL.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_control TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_control FOR &&tool_repository_schema..trca_control;

/* ------------------------------------------------------------------------- */

-- external dict table snaphot of sys.file$ generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_file (
  file#                      VARCHAR2(255),
  ts#                        VARCHAR2(255),
  relfile#                   VARCHAR2(255)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_FILE.bad'
  LOGFILE 'TRCA_FILE.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_FILE.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_file TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_file FOR &&tool_repository_schema..trca_file;

/* ------------------------------------------------------------------------- */

-- dict snaphot of sys.file$ seeded by trca$t.refresh_trca$_dict_from
-- to be used by trca$_dba_extents only
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..trca$_file$ (
  file#                      NUMBER,
  ts#                        NUMBER,
  relfile#                   NUMBER
) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..trca$_file$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_file$ FOR &&tool_repository_schema..trca$_file$;

/* ------------------------------------------------------------------------- */

-- external dict table snaphot of dba_segments generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_segments (
  uid#                       VARCHAR2(255),
  owner                      VARCHAR2(257),
  segment_name               VARCHAR2(257),
  partition_name             VARCHAR2(257),
  segment_type               VARCHAR2(255),
  tablespace_id              VARCHAR2(255),
  header_block               VARCHAR2(255),
  relative_fno               VARCHAR2(255),
  managed                    VARCHAR2(255)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_SEGMENTS.bad'
  LOGFILE 'TRCA_SEGMENTS.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_SEGMENTS.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_segments TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_segments FOR &&tool_repository_schema..trca_segments;

/* ------------------------------------------------------------------------- */

-- dict snaphot of dba_segments seeded by trca$t.refresh_trca$_dict_from
-- to be used by trca$_dba_extents only
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..trca$_segments (
  uid#                       NUMBER,
  owner                      VARCHAR2(257),
  segment_name               VARCHAR2(257),
  partition_name             VARCHAR2(257),
  segment_type               VARCHAR2(20),
  tablespace_id              NUMBER,
  header_block               NUMBER,
  relative_fno               NUMBER,
  managed                    NUMBER
) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..trca$_segments TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_segments FOR &&tool_repository_schema..trca$_segments;

/* ------------------------------------------------------------------------- */

-- external dict table snaphot of sys.uet$ generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_extents_dm (
  relative_fno               VARCHAR2(255), -- segfile#
  header_block               VARCHAR2(255), -- segblock#
  tablespace_id              VARCHAR2(255), -- ts#
  relfile#                   VARCHAR2(255), -- file#
  block_id                   VARCHAR2(255), -- block#
  blocks                     VARCHAR2(255)  -- length
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_EXTENTS_DM.bad'
  LOGFILE 'TRCA_EXTENTS_DM.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_EXTENTS_DM.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_extents_dm TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_extents_dm FOR &&tool_repository_schema..trca_extents_dm;

/* ------------------------------------------------------------------------- */

 -- dict snaphot of sys.uet$ seeded by trca$t.refresh_trca$_dict_from
 -- to be used by trca$_dba_extents only
 CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..trca$_extents_dm (
   relative_fno               NUMBER, -- segfile#
   header_block               NUMBER, -- segblock#
   tablespace_id              NUMBER, -- ts#
   relfile#                   NUMBER, -- file#
   block_id                   NUMBER, -- block#
   blocks                     NUMBER  -- length
 ) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..trca$_extents_dm TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_extents_dm FOR &&tool_repository_schema..trca$_extents_dm;

/* ------------------------------------------------------------------------- */

-- external dict table snaphot of sys.x$ktfbue generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_extents_lm (
  relative_fno               VARCHAR2(255), -- ktfbuesegfno
  header_block               VARCHAR2(255), -- ktfbuesegbno
  tablespace_id              VARCHAR2(255), -- ktfbuesegtsn
  relfile#                   VARCHAR2(255), -- ktfbuefno
  block_id                   VARCHAR2(255), -- ktfbuebno
  blocks                     VARCHAR2(255)  -- ktfbueblks
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_EXTENTS_LM.bad'
  LOGFILE 'TRCA_EXTENTS_LM.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_EXTENTS_LM.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_extents_lm TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_extents_lm FOR &&tool_repository_schema..trca_extents_lm;

/* ------------------------------------------------------------------------- */

 -- dict snaphot of sys.x$ktfbue seeded by trca$t.refresh_trca$_dict_from
 -- to be used by trca$_dba_extents only
 CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..trca$_extents_lm (
   relative_fno              NUMBER, -- ktfbuesegfno
   header_block              NUMBER, -- ktfbuesegbno
   tablespace_id             NUMBER, -- ktfbuesegtsn
   relfile#                  NUMBER, -- ktfbuefno
   block_id                  NUMBER, -- ktfbuebno
   blocks                    NUMBER  -- ktfbueblks
 ) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..trca$_extents_lm TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_extents_lm FOR &&tool_repository_schema..trca$_extents_lm;

/* ------------------------------------------------------------------------- */

-- dict snaphot of dba_extents seeded by trca$t.refresh_trca$_extents
CREATE TABLE &&tool_repository_schema..trca$_extents (
  owner                      VARCHAR2(257),
  segment_name               VARCHAR2(257),
  partition_name             VARCHAR2(257),
  segment_type               VARCHAR2(20),
  file_id                    NUMBER NOT NULL,
  block_id_from              NUMBER NOT NULL,
  block_id_to                NUMBER NOT NULL
);

GRANT ALL ON &&tool_repository_schema..trca$_extents TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_extents FOR &&tool_repository_schema..trca$_extents;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_extents_u1 ON &&tool_repository_schema..trca$_extents(file_id, block_id_from, block_id_to);

/* ------------------------------------------------------------------------- */

-- dict snaphot of dba_users seeded by trca$t.refresh_trca$_users
CREATE TABLE &&tool_repository_schema..trca$_users (
  user_id                    NUMBER NOT NULL,
  user_name                  VARCHAR2(257)
);

GRANT ALL ON &&tool_repository_schema..trca$_users TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_users FOR &&tool_repository_schema..trca$_users;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_users_u1 ON &&tool_repository_schema..trca$_users(user_id);

/* ------------------------------------------------------------------------- */

-- Trace Analyzer configuration parameters
CREATE TABLE &&tool_repository_schema..trca$_tool_parameter (
  id                         INTEGER      NOT NULL, -- pk
  hidden                     CHAR(1)      NOT NULL, -- (N)o, (Y)es
  user_updateable            CHAR(1)      NOT NULL, -- (N)o, (Y)es
  name                       VARCHAR2(32) NOT NULL,
  description                VARCHAR2(64) NOT NULL,
  value_type                 CHAR(1)      NOT NULL, -- (N)umber, (C)har
  value                      VARCHAR2(128),
  default_value              VARCHAR2(128),
  low_value                  NUMBER,
  high_value                 NUMBER,
  value1                     VARCHAR2(128),
  value2                     VARCHAR2(128),
  value3                     VARCHAR2(128),
  value4                     VARCHAR2(128),
  value5                     VARCHAR2(128),
  instructions               VARCHAR2(128)
);

GRANT ALL ON &&tool_repository_schema..trca$_tool_parameter TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_tool_parameter FOR &&tool_repository_schema..trca$_tool_parameter;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_tool_parameter_pk ON &&tool_repository_schema..trca$_tool_parameter(id);
ALTER TABLE &&tool_repository_schema..trca$_tool_parameter ADD (CONSTRAINT trca$_tool_parameter_pk PRIMARY KEY (id));

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_tool_parameter_u1 ON &&tool_repository_schema..trca$_tool_parameter(name);

DECLARE
  ins_id INTEGER := 0;
  PROCEDURE ins (
    p_hidden          CHAR,
    p_user_updateable CHAR,
    p_name            VARCHAR2,
    p_description     VARCHAR2,
    p_value_type      CHAR,
    p_value           VARCHAR2,
    p_default_value   VARCHAR2,
    p_low_value       NUMBER,
    p_high_value      NUMBER,
    p_value1          VARCHAR2,
    p_value2          VARCHAR2,
    p_value3          VARCHAR2,
    p_value4          VARCHAR2,
    p_value5          VARCHAR2,
    p_instructions    VARCHAR2 )
  IS
  BEGIN
    ins_id := ins_id + 1;
    INSERT INTO &&tool_repository_schema..trca$_tool_parameter VALUES (
      ins_id,
      p_hidden,
      p_user_updateable,
      p_name,
      p_description,
      p_value_type,
      p_value,
      p_default_value,
      p_low_value,
      p_high_value,
      p_value1,
      p_value2,
      p_value3,
      p_value4,
      p_value5,
      p_instructions );
  END;
BEGIN
  DELETE &&tool_repository_schema..trca$_tool_parameter;
  --  hid  upd  name                         description                       typ  value                         default       low    high         val1  val2  val3  val4  val5  instructions
  --  ~~~  ~~~  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ~~~~~~~~~~~~~ ~~~~~~ ~~~~~~~~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~ ~~~~~~~~~~~~
  ins('Y', 'N', 'tool_repository_schema',    'Tool Repository Schema',         'C', '&&tool_repository_schema.',  NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, NULL);
  ins('Y', 'N', 'tool_administer_schema',    'Tool Administer Schema',         'C', '&&tool_administer_schema.',  NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, NULL);
  ins('Y', 'N', 'tool_name',                 'Tool Name',                      'C', 'Trace Analyzer',             NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, NULL);
  ins('Y', 'N', 'tool_version',              'Tool Version',                   'C', '&&tool_version.',            NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, NULL);
  ins('Y', 'N', 'tool_date',                 'Tool Date',                      'C', '&&tool_date.',               NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, NULL);
  ins('Y', 'N', 'install_date',              'Tool Install Date',              'C', TO_CHAR(SYSDATE, 'YYYYMMDD'), NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'YYYYMMDD');
  ins('Y', 'N', 'interop_version',           'Inter Operability Version',      'N', '1',                          '1',          1,     9999,        NULL, NULL, NULL, NULL, NULL, '1-9999');

  ins('Y', 'N', 'dict_refresh_date',         'Tool Dict Refresh Date',         'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'YYYYMMDD');
  ins('Y', 'N', 'dict_refresh_days',         'Tool Dict Refresh Days',         'N', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, NULL);
  ins('Y', 'N', 'dict_database_id',          'Tool Dict Database Id',          'N', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$database.dbid');
  ins('Y', 'N', 'dict_database_name',        'Tool Dict Database Name',        'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$database.name');
  ins('Y', 'N', 'dict_instance_id',          'Tool Dict Instance Id',          'N', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$instance.instance_number');
  ins('Y', 'N', 'dict_instance_name',        'Tool Dict Instance Name',        'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$instance.instance_name');
  ins('Y', 'N', 'dict_host_name',            'Tool Dict Host Name',            'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$instance.host_name');
  ins('Y', 'N', 'dict_platform',             'Tool Dict Platform',             'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'product_component_version.product');
  ins('Y', 'N', 'dict_rdbms_version',        'Tool Dict RDBMS Version',        'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$instance.version');
  ins('Y', 'N', 'dict_db_files',             'Tool Dict DB Files',             'N', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$parameter2 db_files');

  ins('Y', 'N', 'tool_database_id',          'Tool Database Id',               'N', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$database.dbid');
  ins('Y', 'N', 'tool_database_name',        'Tool Database Name',             'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$database.name');
  ins('Y', 'N', 'tool_instance_id',          'Tool Instance Id',               'N', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$instance.instance_number');
  ins('Y', 'N', 'tool_instance_name',        'Tool Instance Name',             'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$instance.instance_name');
  ins('Y', 'N', 'tool_host_name',            'Tool Host Name',                 'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$instance.host_name');
  ins('Y', 'N', 'tool_platform',             'Tool Platform',                  'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'product_component_version.product');
  ins('Y', 'N', 'tool_rdbms_version',        'Tool RDBMS Version',             'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$instance.version');
  ins('Y', 'N', 'tool_rdbms_version_short',  'Tool RDBMS Version Short',       'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'rdbms_version');
  ins('Y', 'N', 'tool_rdbms_release',        'Tool RDBMS Release',             'N', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'rdbms_version_short');
  ins('Y', 'N', 'tool_product_version',      'Tool Product Version',           'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'product_component_version.product.status');
  ins('Y', 'N', 'tool_db_files',             'Tool DB Files',                  'N', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'v$parameter2 db_files');

  ins('N', 'Y', 'top_sql_th',                'Top SQL Threshold',              'N', '10',                         '10',         0,     100,         NULL, NULL, NULL, NULL, NULL, '0-100');
  ins('N', 'Y', 'top_exec_th',               'Top Execution Threshold',        'N', '10',                         '10',         0,     100,         NULL, NULL, NULL, NULL, NULL, '0-100');
  ins('N', 'Y', 'hot_block_th',              'Hot Block Threshold',            'N', '5',                          '5',          0,     100,         NULL, NULL, NULL, NULL, NULL, '0-100');
  ins('N', 'Y', 'aggregate',                 'Aggregate',                      'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'perform_count_star',        'Perform COUNT(*)',               'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'count_star_th',             'COUNT(*) Threshold',             'N', '1000000',                    '1000000',    0,     999999999,   NULL, NULL, NULL, NULL, NULL, '0-999999999');
  ins('N', 'Y', 'errors_th',                 'Errors Threshold',               'N', '100',                        '100',        0,     1000,        NULL, NULL, NULL, NULL, NULL, '0-1000');
  ins('N', 'Y', 'gaps_th',                   'Gaps Threshold',                 'N', '100',                        '100',        0,     1000,        NULL, NULL, NULL, NULL, NULL, '0-1000');
  ins('N', 'Y', 'include_internal_sql',      'Include Internal SQL',           'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'include_non_top_sql',       'Include non-Top SQL',            'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'include_init_ora',          'Include Initialization Params',  'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'include_waits',             'Include Waits',                  'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'include_binds',             'Include Bind Variables',         'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'include_fetches',           'Include Fetch Calls',            'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'include_expl_plans',        'Include Explain Plans',          'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'include_segments',          'Include Segments',               'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'detail_non_top_sql',        'Detail non-top SQL',             'C', 'N',                          'N',          NULL,  NULL,        'N',  'Y',  NULL, NULL, NULL, 'N, Y');
  ins('N', 'Y', 'time_granularity',          'Time Granularity',               'N', '1000000',                    '1000000',    NULL,  NULL,        '1000000', '100', NULL, NULL, NULL, '1000000-100');
  ins('N', 'Y', 'wait_time_th',              'Wait Time Threshold',            'N', '0.01',                       '0.01',       0.0001,1.0,         NULL, NULL, NULL, NULL, NULL, '0.0001-1.0');
  ins('N', 'Y', 'response_time_th',          'Response Time Threshold',        'N', '0.1',                        '0.1',        0.001, 10.0,        NULL, NULL, NULL, NULL, NULL, '0.001-10.0');
  ins('N', 'Y', 'trace_file_max_size_bytes', 'Trace File Max Size in Bytes',   'N', '9999999999',                 '9999999999', 99999, 99999999999, NULL, NULL, NULL, NULL, NULL, '99999-99999999999');
  ins('N', 'Y', 'copy_file_max_size_bytes',  'Copy File Max Size in Bytes',    'N', '999999999',                  '999999999',  99999, 99999999999, NULL, NULL, NULL, NULL, NULL, '99999-99999999999');
  ins('N', 'Y', 'gen_html_report',           'Generate HTML Report',           'C', 'Y',                          'Y',          NULL, NULL,         'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'gen_text_report',           'Generate Text Report',           'C', 'Y',                          'Y',          NULL, NULL,         'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'split_10046_10053_trc',     'Split traces generated by SQLT', 'C', 'Y',                          'Y',          NULL, NULL,         'Y',  'N',  NULL, NULL, NULL, 'Y, N');
  ins('N', 'Y', 'gather_cbo_stats',          'Gather CBO Stats Staging Objs',  'N', '10',                         '10',         0,    100,          NULL, NULL, NULL, NULL, NULL, '0-100');
  ins('N', 'Y', 'capture_extents',           'Capture Extents in Repository',  'C', 'S',                          'S',          NULL,  NULL,        'S',  'P',  'N',  NULL, NULL, '(S)erial, (P)arallel, (N)o');
  ins('N', 'Y', 'refresh_dict_repository',   'Refresh Dictionary Repository',  'C', 'Y',                          'Y',          NULL,  NULL,        'Y',  'N',  NULL, NULL, NULL, 'Y, N');

  ins('N', 'N', 'input1_dir',                'Input Directory 1',              'C', 'TRCA$INPUT1',                'UDUMP',      NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'Set by trca/utl/tacdiri1.sql');
  ins('N', 'N', 'input2_dir',                'Input Directory 2',              'C', 'TRCA$INPUT2',                'BDUMP',      NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'Set by trca/utl/tacdiri2.sql');
  ins('N', 'N', 'stage_dir',                 'Stage Directory',                'C', 'TRCA$STAGE',                 'UDUMP',      NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'Set by trca/utl/tacdirs.sql');
  ins('Y', 'N', 'input1_directory',          'Input Directory Path 1',         'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'TRCA$INPUT1');
  ins('Y', 'N', 'input2_directory',          'Input Directory Path 2',         'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'TRCA$INPUT2');
  ins('Y', 'N', 'stage_directory',           'Stage Directory Path',           'C', NULL,                         NULL,         NULL,  NULL,        NULL, NULL, NULL, NULL, NULL, 'TRCA$STAGE');
END;
/

/* ------------------------------------------------------------------------- */

-- lookup table for oracle data types
CREATE TABLE &&tool_repository_schema..trca$_data_type (
  id                          INTEGER      NOT NULL,
  name                        VARCHAR2(128),
  description                 VARCHAR2(128)
);

GRANT ALL ON &&tool_repository_schema..trca$_data_type TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_data_type FOR &&tool_repository_schema..trca$_data_type;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_data_type_pk ON &&tool_repository_schema..trca$_data_type(id);
ALTER TABLE &&tool_repository_schema..trca$_data_type ADD (CONSTRAINT trca$_data_type_pk PRIMARY KEY (id));

CREATE OR REPLACE PROCEDURE &&tool_administer_schema..ins (
  p_id   IN INTEGER,
  p_name IN VARCHAR2,
  p_desc IN VARCHAR2 )
IS
BEGIN
  INSERT INTO &&tool_repository_schema..trca$_data_type (
    id,
    name,
    description
  ) VALUES (
    p_id,
    p_name,
    p_desc
  );
END;
/

SHOW ERRORS;

BEGIN
  &&tool_administer_schema..ins(  1, 'VARCHAR2', 'char[n]');
  &&tool_administer_schema..ins(  2, 'NUMBER', 'unsigned char[21]');
  &&tool_administer_schema..ins(  3, 'signed INTEGER', 'signed char, short, int, long');
  &&tool_administer_schema..ins(  4, 'FLOAT', 'float, double');
  &&tool_administer_schema..ins(  5, 'NULL-terminated STRING', 'char[n+1]');
  &&tool_administer_schema..ins(  6, 'VARNUM', 'char[22]');
  &&tool_administer_schema..ins(  7, 'Packed Decimal Numeric (Cobol)', NULL);
  &&tool_administer_schema..ins(  8, 'LONG', 'char[n]');
  &&tool_administer_schema..ins(  9, 'VARCHAR', 'char[n+sizeof(short integer)]');
  &&tool_administer_schema..ins( 10, 'Null/empty PCC Descriptor entry', NULL);
  &&tool_administer_schema..ins( 11, 'Internal (native format) rowid', 'unsigned char[12]');
  &&tool_administer_schema..ins( 12, 'DATE', 'char[7]');
  &&tool_administer_schema..ins( 13, 'internal date format', NULL);
  &&tool_administer_schema..ins( 14, 'internal julian format', NULL);
  &&tool_administer_schema..ins( 15, 'VARRAW', 'unsigned char[n+sizeof(short integer)]');
  &&tool_administer_schema..ins( 16, 'Date input format', NULL);
  &&tool_administer_schema..ins( 17, 'Date output format', NULL);
  &&tool_administer_schema..ins( 18, 'Date time zone', NULL);
  &&tool_administer_schema..ins( 19, 'Day name', NULL);
  &&tool_administer_schema..ins( 20, 'Date precision code', NULL);
  &&tool_administer_schema..ins( 21, 'Single precision floating point', 'float');
  &&tool_administer_schema..ins( 22, 'Double precision floating point', 'double');
  &&tool_administer_schema..ins( 23, 'RAW', 'unsigned char[n]');
  &&tool_administer_schema..ins( 24, 'LONG RAW', 'unsigned char[n]');
  &&tool_administer_schema..ins( 29, 'internal integer', NULL);
  &&tool_administer_schema..ins( 38, 'network form', NULL);
  &&tool_administer_schema..ins( 39, 'native form', NULL);
  &&tool_administer_schema..ins( 68, 'UNSIGNED INT', 'unsigned');
  &&tool_administer_schema..ins( 69, 'ROWID', '10 bytes');
  &&tool_administer_schema..ins( 77, 'archive op', NULL);
  &&tool_administer_schema..ins( 78, 'media recovery start', NULL);
  &&tool_administer_schema..ins( 79, 'media recovery record tablespace', NULL);
  &&tool_administer_schema..ins( 80, 'media recovery get starting log sequence #', NULL);
  &&tool_administer_schema..ins( 81, 'media recovery recover using offline log', NULL);
  &&tool_administer_schema..ins( 82, 'media recovery cancel', NULL);
  &&tool_administer_schema..ins( 83, 'version number', NULL);
  &&tool_administer_schema..ins( 84, 'logon, w/extra information', NULL);
  &&tool_administer_schema..ins( 85, 'OINIT, w/extra information', NULL);
  &&tool_administer_schema..ins( 86, 'bundled call', NULL);
  &&tool_administer_schema..ins( 87, 'array bind describe info', NULL);
  &&tool_administer_schema..ins( 88, 'reserved for os2/msdos', NULL);
  &&tool_administer_schema..ins( 89, 'loader buffer transfer', NULL);
  &&tool_administer_schema..ins( 90, 'loader function call', NULL);
  &&tool_administer_schema..ins( 91, 'Longer longs (char)', 'struct { ub4 len; char s[n]; }');
  &&tool_administer_schema..ins( 92, 'Oracle session id', NULL);
  &&tool_administer_schema..ins( 93, 'new network uac type', NULL);
  &&tool_administer_schema..ins( 94, 'LONG VARCHAR', 'char[n+sizeof(integer)]');
  &&tool_administer_schema..ins( 95, 'LONG VARRAW', 'unsigned char[n+sizeof(integer)]');
  &&tool_administer_schema..ins( 96, 'CHAR', 'char[n]');
  &&tool_administer_schema..ins( 97, 'CHARZ', 'char[n+1]');
  &&tool_administer_schema..ins( 98, 'Dataatype for pisdef for deferred upi', NULL);
  &&tool_administer_schema..ins( 99, 'RPC between transaction managers', NULL);
  &&tool_administer_schema..ins(100, 'BINARY_FLOAT', '4 bytes');
  &&tool_administer_schema..ins(101, 'BINARY_DOUBLE', '8 bytes');
  &&tool_administer_schema..ins(102, 'REF cursor type', NULL);
  &&tool_administer_schema..ins(103, 'direct path Export', NULL);
  &&tool_administer_schema..ins(104, 'ROWID descriptor', 'OCIRowid');
  &&tool_administer_schema..ins(105, 'label type (Trusted Oracle)', NULL);
  &&tool_administer_schema..ins(106, 'OS label type (Trusted Oracle)', NULL);
  &&tool_administer_schema..ins(107, 'for KOD', NULL);
  &&tool_administer_schema..ins(108, 'NAMED DATATYPE', 'struct');
  &&tool_administer_schema..ins(109, 'Internal Named Type', NULL);
  &&tool_administer_schema..ins(110, 'REF', 'OCIRef');
  &&tool_administer_schema..ins(111, 'REF', 'N/A');
  &&tool_administer_schema..ins(112, 'Character LOB descriptor', 'OCILobLocator (see note 2)');
  &&tool_administer_schema..ins(113, 'Binary LOB descriptor', 'OCILobLocator (see note 2)');
  &&tool_administer_schema..ins(114, 'Binary FILE descriptor', 'OCILobLocator');
  &&tool_administer_schema..ins(115, 'Character file LOB (CFILE)', NULL);
  &&tool_administer_schema..ins(116, 'Result set type', NULL);
  &&tool_administer_schema..ins(117, 'Reuse for Cursor /w describe info', NULL);
  &&tool_administer_schema..ins(118, 'structure value type', NULL);
  &&tool_administer_schema..ins(119, 'internal structure value type', NULL);
  &&tool_administer_schema..ins(120, 'new version8 OAC', NULL);
  &&tool_administer_schema..ins(122, 'named collection type (varray or nested table)', NULL);
  &&tool_administer_schema..ins(123, 'named array type', NULL);
  &&tool_administer_schema..ins(124, 'new v8 udsdef', NULL);
  &&tool_administer_schema..ins(125, 'new v8 execute structure', NULL);
  &&tool_administer_schema..ins(126, 'LOB and FILE operations except file create', NULL);
  &&tool_administer_schema..ins(127, 'FILE create operation', NULL);
  &&tool_administer_schema..ins(128, 'new v8 describe any', NULL);
  &&tool_administer_schema..ins(129, 'Used for recursive open calls', NULL);
  &&tool_administer_schema..ins(130, 'Datatype for pisdef for bundled PL/SQL calls', NULL);
  &&tool_administer_schema..ins(131, 'transaction start, attach and detach operation', NULL);
  &&tool_administer_schema..ins(132, 'transaction end and recover operation', NULL);
  &&tool_administer_schema..ins(133, 'old describe callback', NULL);
  &&tool_administer_schema..ins(134, 'Cursor close all piggyback function', NULL);
  &&tool_administer_schema..ins(135, 'warning message', NULL);
  &&tool_administer_schema..ins(136, 'Object form. Used on server side only', NULL);
  &&tool_administer_schema..ins(137, 'Load Header', NULL);
  &&tool_administer_schema..ins(138, 'Typed Object Header', NULL);
  &&tool_administer_schema..ins(139, 'failover info', NULL);
  &&tool_administer_schema..ins(140, 'V8 Session switching piggyback', NULL);
  &&tool_administer_schema..ins(141, 'COR Header', NULL);
  &&tool_administer_schema..ins(146, 'Character Lob Value', NULL);
  &&tool_administer_schema..ins(147, 'Binary Lob Value', NULL);
  &&tool_administer_schema..ins(148, 'v8 rxhdef', NULL);
  &&tool_administer_schema..ins(149, 'name,pref', NULL);
  &&tool_administer_schema..ins(150, 'New generic logon call', NULL);
  &&tool_administer_schema..ins(151, 'keyword value pair', NULL);
  &&tool_administer_schema..ins(152, 'cobol: display trailing', NULL);
  &&tool_administer_schema..ins(153, 'cobol: display unsigned', NULL);
  &&tool_administer_schema..ins(154, 'cobol: display overpunch', NULL);
  &&tool_administer_schema..ins(155, 'OCI STRING type', 'OCIString');
  &&tool_administer_schema..ins(156, 'OCI DATE type', 'OCIDate');
  &&tool_administer_schema..ins(158, 'V8 descibe any', NULL);
  &&tool_administer_schema..ins(159, 'top level descriptor for V8.0 describe any', NULL);
  &&tool_administer_schema..ins(160, 'header descriptor for V8.0 describe any', NULL);
  &&tool_administer_schema..ins(161, 'list descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(162, 'table descriptor for V8.0 describe any', NULL);
  &&tool_administer_schema..ins(163, 'view descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(164, 'procedure descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(165, 'function descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(166, 'package descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(167, 'synonym descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(168, 'sequence descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(169, 'column descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(170, 'argument descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(171, 'Oracle Transaction service: Commit remote sites', NULL);
  &&tool_administer_schema..ins(172, 'display overpunch leading', NULL);
  &&tool_administer_schema..ins(173, 'function descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(174, 'AQ Enqueue structure', NULL);
  &&tool_administer_schema..ins(175, 'fast keyword value pair', NULL);
  &&tool_administer_schema..ins(176, 'AQ Dequeue structure', NULL);
  &&tool_administer_schema..ins(177, 'AQ Message properties structure', NULL);
  &&tool_administer_schema..ins(178, 'TIME', NULL);
  &&tool_administer_schema..ins(179, 'TIME WITH TIME ZONE', NULL);
  &&tool_administer_schema..ins(180, 'TIMESTAMP', '11 bytes');
  &&tool_administer_schema..ins(181, 'TIMESTAMP WITH TIME ZONE', '13 bytes');
  &&tool_administer_schema..ins(182, 'INTERVAL YEAR TO MONTH', '5 bytes');
  &&tool_administer_schema..ins(183, 'INTERVAL DAY TO SECOND', '11 bytes');
  &&tool_administer_schema..ins(184, 'ANSI DATE descriptor', 'OCIDateTime');
  &&tool_administer_schema..ins(185, 'TIME in structured format', NULL);
  &&tool_administer_schema..ins(186, 'TIME WITH TIME ZONE in structured format', NULL);
  &&tool_administer_schema..ins(187, 'TIMESTAMP descriptor', 'OCIDateTime');
  &&tool_administer_schema..ins(188, 'TIMESTAMP WITH TIME ZONE descriptor', 'OCIDateTime');
  &&tool_administer_schema..ins(189, 'INTERVAL YEAR TO MONTH descriptor', 'OCIInterval');
  &&tool_administer_schema..ins(190, 'INTERVAL DAY TO SECOND descriptor', 'OCIInterval');
  &&tool_administer_schema..ins(191, 'LDI input format', NULL);
  &&tool_administer_schema..ins(192, 'LDI output forma', NULL);
  &&tool_administer_schema..ins(193, 'Remote archive file server', NULL);
  &&tool_administer_schema..ins(194, 'V8.1 row header definition', NULL);
  &&tool_administer_schema..ins(195, 'Desriptor rep. for DTYCLOB - internal use only', NULL);
  &&tool_administer_schema..ins(196, 'Descriptor rep for DTYBLOB - internal use only', NULL);
  &&tool_administer_schema..ins(197, 'Descriptor rep for DTYBFIL - internal use only', NULL);
  &&tool_administer_schema..ins(198, 'kernel programmatic notification', NULL);
  &&tool_administer_schema..ins(199, 'notification registration info', NULL);
  &&tool_administer_schema..ins(200, 'Database descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(201, 'Schema descriptor for V8 describe any', NULL);
  &&tool_administer_schema..ins(202, 'KPCDS structur for 8.1 onward', NULL);
  &&tool_administer_schema..ins(203, 'Header descriptor for 8.1 onward', NULL);
  &&tool_administer_schema..ins(204, 'table descriptor for 8.1 onward', NULL);
  &&tool_administer_schema..ins(205, 'future use', NULL);
  &&tool_administer_schema..ins(206, 'AQ message properties structure for Oracle 8.1', NULL);
  &&tool_administer_schema..ins(207, 'V8.1 oerdef structure', NULL);
  &&tool_administer_schema..ins(208, 'UROWID', '3950 bytes');
  &&tool_administer_schema..ins(209, 'partial sort record for parallel aggregates', NULL);
  &&tool_administer_schema..ins(210, 'aq listen', NULL);
  &&tool_administer_schema..ins(211, 'OTs: Commit remote sites for version >= 8.1.3.0.0', NULL);
  &&tool_administer_schema..ins(214, 'for object transfer', NULL);
  &&tool_administer_schema..ins(215, 'sb4 IDL piece', NULL);
  &&tool_administer_schema..ins(216, 'ub2 IDL piece', NULL);
  &&tool_administer_schema..ins(217, 'ub1 IDL piece', NULL);
  &&tool_administer_schema..ins(218, 'txt IDL piece', NULL);
  &&tool_administer_schema..ins(219, 'segment of sb4 IDL pieces', NULL);
  &&tool_administer_schema..ins(220, 'segment of ub2 IDL pieces', NULL);
  &&tool_administer_schema..ins(221, 'segment of ub1 IDL pieces', NULL);
  &&tool_administer_schema..ins(222, 'segment of txt IDL pieces', NULL);
  &&tool_administer_schema..ins(223, 'top most structure for IDL piece (diana or pcode)', NULL);
  &&tool_administer_schema..ins(224, 'structure for transfering single dependency', NULL);
  &&tool_administer_schema..ins(225, 'dependency segment', NULL);
  &&tool_administer_schema..ins(226, 'array of arrays of dependencies', NULL);
  &&tool_administer_schema..ins(227, 'KOD operations post 8.1', NULL);
  &&tool_administer_schema..ins(228, 'Direct Path Prepare descriptor', NULL);
  &&tool_administer_schema..ins(229, 'Direct Path Load Stream descriptor', NULL);
  &&tool_administer_schema..ins(230, 'Direct Path Misc Operations descriptor', NULL);
  &&tool_administer_schema..ins(231, 'TIMESTAMP WITH LOCAL TIME ZONE', '11 bytes');
  &&tool_administer_schema..ins(232, 'TIMESTAMP WITH LOCAL TIME ZONE descriptor', 'OCIDateTime');
  &&tool_administer_schema..ins(249, 'nchar lob', NULL);
  &&tool_administer_schema..ins(250, 'pl/sql record (or %rowtype)', NULL);
  &&tool_administer_schema..ins(251, 'pl/sql indexed table', NULL);
  &&tool_administer_schema..ins(252, 'pl/sql boolean', NULL);
END;
/

DROP PROCEDURE &&tool_administer_schema..ins;

/* ------------------------------------------------------------------------- */

-- same content than v$event_name as per 11.2.0.1
CREATE TABLE &&tool_repository_schema..trca$_event_name (
  event#                      INTEGER      NOT NULL, -- pk
  name                        VARCHAR2(64) NOT NULL,
  wait_class                  VARCHAR2(64) NOT NULL,
  idle                        CHAR(1)      NOT NULL, -- Y/N
  parameter1                  VARCHAR2(64),
  parameter2                  VARCHAR2(64),
  parameter3                  VARCHAR2(64)
);

GRANT ALL ON &&tool_repository_schema..trca$_event_name TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_event_name FOR &&tool_repository_schema..trca$_event_name;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_event_name_pk ON &&tool_repository_schema..trca$_event_name(event#);
ALTER TABLE &&tool_repository_schema..trca$_event_name ADD (CONSTRAINT trca$_event_name_pk PRIMARY KEY (event#));

CREATE OR REPLACE PROCEDURE &&tool_administer_schema..ins (
  p_event#     IN INTEGER,
  p_name       IN VARCHAR2,
  p_wait_class IN VARCHAR2,
  p_idle       IN VARCHAR2,
  p_parameter1 IN VARCHAR2,
  p_parameter2 IN VARCHAR2,
  p_parameter3 IN VARCHAR2 )
IS
BEGIN
  INSERT INTO &&tool_repository_schema..trca$_event_name (
    event#,
    name,
    wait_class,
    idle,
    parameter1,
    parameter2,
    parameter3
  ) VALUES (
    p_event#,
    p_name,
    p_wait_class,
    p_idle,
    p_parameter1,
    p_parameter2,
    p_parameter3
  );
END;
/

SET DEF ON;
SET DEF ~;
BEGIN
  DELETE ~~tool_repository_schema..trca$_event_name;
  ~~tool_administer_schema..ins(   0, 'null event'                                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(   1, 'pmon timer'                                                 , 'Idle'           , 'Y', 'duration'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins(   2, 'logout restrictor'                                          , 'Concurrency'    , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(   3, 'VKTM Logical Idle Wait'                                     , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(   4, 'VKTM Init Wait for GSGA'                                    , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(   5, 'IORM Scheduler Slave Idle Wait'                             , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(   6, 'Parameter File I/O'                                         , 'User I/O'       , 'N', 'blkno'                                   , '#blks'                      , 'read/write'             );
  ~~tool_administer_schema..ins(   7, 'rdbms ipc message'                                          , 'Idle'           , 'Y', 'timeout'                                 , ''                           , ''                       );
  ~~tool_administer_schema..ins(   8, 'remote db operation'                                        , 'Network'        , 'N', 'clientid'                                , 'operation'                  , 'timeout'                );
  ~~tool_administer_schema..ins(   9, 'remote db file read'                                        , 'Network'        , 'N', 'clientid'                                , 'count'                      , 'intr'                   );
  ~~tool_administer_schema..ins(  10, 'remote db file write'                                       , 'Network'        , 'N', 'clientid'                                , 'count'                      , 'intr'                   );
  ~~tool_administer_schema..ins(  11, 'Disk file operations I/O'                                   , 'User I/O'       , 'N', 'FileOperation'                           , 'fileno'                     , 'filetype'               );
  ~~tool_administer_schema..ins(  12, 'Disk file I/O Calibration'                                  , 'User I/O'       , 'N', 'count'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins(  13, 'Disk file Mirror Read'                                      , 'User I/O'       , 'N', 'fileno'                                  , 'blkno'                      , 'filetype'               );
  ~~tool_administer_schema..ins(  14, 'Disk file Mirror/Media Repair Write'                        , 'User I/O'       , 'N', 'fileno'                                  , 'blkno'                      , 'filetype'               );
  ~~tool_administer_schema..ins(  15, 'direct path sync'                                           , 'User I/O'       , 'N', 'File number'                             , 'Flags'                      , ''                       );
  ~~tool_administer_schema..ins(  16, 'Clonedb bitmap file write'                                  , 'System I/O'     , 'N', 'blkno'                                   , 'size'                       , ''                       );
  ~~tool_administer_schema..ins(  17, 'Datapump dump file I/O'                                     , 'User I/O'       , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins(  18, 'dbms_file_transfer I/O'                                     , 'User I/O'       , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins(  19, 'DG Broker configuration file I/O'                           , 'User I/O'       , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins(  20, 'Data file init write'                                       , 'User I/O'       , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins(  21, 'Log file init write'                                        , 'User I/O'       , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins(  22, 'Log archive I/O'                                            , 'System I/O'     , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins(  23, 'RMAN backup & recovery I/O'                                 , 'System I/O'     , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins(  24, 'Standby redo I/O'                                           , 'System I/O'     , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins(  25, 'Network file transfer'                                      , 'System I/O'     , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins(  26, 'Backup: MML initialization'                                 , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  27, 'Backup: MML v1 open backup piece'                           , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  28, 'Backup: MML v1 read backup piece'                           , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  29, 'Backup: MML v1 write backup piece'                          , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  30, 'Backup: MML v1 close backup piece'                          , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  31, 'Backup: MML v1 query backup piece'                          , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  32, 'Backup: MML v1 delete backup piece'                         , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  33, 'Backup: MML create a backup piece'                          , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  34, 'Backup: MML commit backup piece'                            , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  35, 'Backup: MML command to channel'                             , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  36, 'Backup: MML shutdown'                                       , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  37, 'Backup: MML obtain textual error'                           , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  38, 'Backup: MML query backup piece'                             , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  39, 'Backup: MML extended initialization'                        , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  40, 'Backup: MML read backup piece'                              , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  41, 'Backup: MML delete backup piece'                            , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  42, 'Backup: MML restore backup piece'                           , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  43, 'Backup: MML write backup piece'                             , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  44, 'Backup: MML proxy initialize backup'                        , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  45, 'Backup: MML proxy cancel'                                   , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  46, 'Backup: MML proxy commit backup piece'                      , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  47, 'Backup: MML proxy session end'                              , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  48, 'Backup: MML datafile proxy backup?'                         , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  49, 'Backup: MML datafile proxy restore?'                        , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  50, 'Backup: MML proxy initialize restore'                       , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  51, 'Backup: MML proxy start data movement'                      , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  52, 'Backup: MML data movement done?'                            , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  53, 'Backup: MML proxy prepare to start'                         , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  54, 'Backup: MML obtain a direct buffer'                         , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  55, 'Backup: MML release a direct buffer'                        , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  56, 'Backup: MML get base address'                               , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  57, 'Backup: MML query for direct buffers'                       , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  58, 'io done'                                                    , 'System I/O'     , 'N', 'msg ptr'                                 , ''                           , ''                       );
  ~~tool_administer_schema..ins(  59, 'i/o slave wait'                                             , 'Idle'           , 'Y', 'msg ptr'                                 , ''                           , ''                       );
  ~~tool_administer_schema..ins(  60, 'RMAN Disk slave I/O'                                        , 'System I/O'     , 'N', 'wait count'                              , 'wait flags'                 , 'timeout'                );
  ~~tool_administer_schema..ins(  61, 'RMAN Tape slave I/O'                                        , 'System I/O'     , 'N', 'tape operation'                          , 'operation flags'            , 'timeout'                );
  ~~tool_administer_schema..ins(  62, 'DBWR slave I/O'                                             , 'System I/O'     , 'N', 'wait count'                              , 'wait flags'                 , 'timeout'                );
  ~~tool_administer_schema..ins(  63, 'LGWR slave I/O'                                             , 'System I/O'     , 'N', 'wait count'                              , 'wait flags'                 , 'timeout'                );
  ~~tool_administer_schema..ins(  64, 'Archiver slave I/O'                                         , 'System I/O'     , 'N', 'wait count'                              , 'wait flags'                 , 'timeout'                );
  ~~tool_administer_schema..ins(  65, 'VKRM Idle'                                                  , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  66, 'wait for unread message on broadcast channel'               , 'Idle'           , 'Y', 'channel context'                         , 'channel handle'             , ''                       );
  ~~tool_administer_schema..ins(  67, 'wait for unread message on multiple broadcast channels'     , 'Idle'           , 'Y', 'channel context'                         , 'channel handle count'       , ''                       );
  ~~tool_administer_schema..ins(  68, 'class slave wait'                                           , 'Idle'           , 'Y', 'slave id'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins(  69, 'KSV master wait'                                            , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  70, 'PING'                                                       , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  71, 'os thread startup'                                          , 'Concurrency'    , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  72, 'watchdog main loop'                                         , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  73, 'DIAG idle wait'                                             , 'Idle'           , 'Y', 'component'                               , 'where'                      , 'wait time(millisec)'    );
  ~~tool_administer_schema..ins(  74, 'ges remote message'                                         , 'Idle'           , 'Y', 'waittime'                                , 'loop'                       , 'p3'                     );
  ~~tool_administer_schema..ins(  75, 'gcs remote message'                                         , 'Idle'           , 'Y', 'waittime'                                , 'poll'                       , 'event'                  );
  ~~tool_administer_schema..ins(  76, 'heartbeat monitor sleep'                                    , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  77, 'GCR sleep'                                                  , 'Idle'           , 'Y', 'lock retry count'                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  78, 'SGA: MMAN sleep for component shrink'                       , 'Idle'           , 'Y', 'component id'                            , 'current size'               , 'target size'            );
  ~~tool_administer_schema..ins(  79, 'retry contact SCN lock master'                              , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  80, 'control file sequential read'                               , 'System I/O'     , 'N', 'file#'                                   , 'block#'                     , 'blocks'                 );
  ~~tool_administer_schema..ins(  81, 'control file single write'                                  , 'System I/O'     , 'N', 'file#'                                   , 'block#'                     , 'blocks'                 );
  ~~tool_administer_schema..ins(  82, 'control file parallel write'                                , 'System I/O'     , 'N', 'files'                                   , 'block#'                     , 'requests'               );
  ~~tool_administer_schema..ins(  83, 'control file backup creation'                               , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  84, 'Shared IO Pool Memory'                                      , 'Concurrency'    , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  85, 'Shared IO Pool IO Completion'                               , 'User I/O'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  86, 'enq: PW - flush prewarm buffers'                            , 'Application'    , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins(  87, 'latch: cache buffers chains'                                , 'Concurrency'    , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins(  88, 'free buffer waits'                                          , 'Configuration'  , 'N', 'file#'                                   , 'block#'                     , 'set-id#'                );
  ~~tool_administer_schema..ins(  89, 'local write wait'                                           , 'User I/O'       , 'N', 'file#'                                   , 'block#'                     , ''                       );
  ~~tool_administer_schema..ins(  90, 'checkpoint completed'                                       , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  91, 'write complete waits'                                       , 'Configuration'  , 'N', 'file#'                                   , 'block#'                     , ''                       );
  ~~tool_administer_schema..ins(  92, 'write complete waits: flash cache'                          , 'Configuration'  , 'N', 'file#'                                   , 'block#'                     , ''                       );
  ~~tool_administer_schema..ins(  93, 'buffer read retry'                                          , 'User I/O'       , 'N', 'file#'                                   , 'block#'                     , ''                       );
  ~~tool_administer_schema..ins(  94, 'buffer busy waits'                                          , 'Concurrency'    , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins(  95, 'gc buffer busy acquire'                                     , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins(  96, 'gc buffer busy release'                                     , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins(  97, 'read by other session'                                      , 'User I/O'       , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins(  98, 'multiple dbwriter suspend/resume for file offline'          , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(  99, 'recovery read'                                              , 'System I/O'     , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 100, 'pi renounce write complete'                                 , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , ''                       );
  ~~tool_administer_schema..ins( 101, 'db flash cache single block physical read'                  , 'User I/O'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 102, 'db flash cache multiblock physical read'                    , 'User I/O'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 103, 'db flash cache write'                                       , 'User I/O'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 104, 'db flash cache invalidate wait'                             , 'Concurrency'    , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 105, 'db flash cache dynamic disabling wait'                      , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 106, 'enq: RO - contention'                                       , 'Application'    , 'N', 'name|mode'                               , '2'                          , '0'                      );
  ~~tool_administer_schema..ins( 107, 'enq: RO - fast object reuse'                                , 'Application'    , 'N', 'name|mode'                               , '2'                          , '0'                      );
  ~~tool_administer_schema..ins( 108, 'enq: KO - fast object checkpoint'                           , 'Application'    , 'N', 'name|mode'                               , '2'                          , '0'                      );
  ~~tool_administer_schema..ins( 109, 'MRP redo arrival'                                           , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 110, 'RFS sequential i/o'                                         , 'System I/O'     , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 111, 'RFS random i/o'                                             , 'System I/O'     , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 112, 'RFS write'                                                  , 'System I/O'     , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 113, 'ARCH wait for net re-connect'                               , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 114, 'LGWR wait on ATTACH'                                        , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 115, 'ARCH wait on ATTACH'                                        , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 116, 'ARCH wait for netserver start'                              , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 117, 'LNS wait on ATTACH'                                         , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 118, 'LNS wait on SENDREQ'                                        , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 119, 'LNS wait on DETACH'                                         , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 120, 'LGWR wait on SENDREQ'                                       , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 121, 'LGWR wait on DETACH'                                        , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 122, 'ARCH wait on SENDREQ'                                       , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 123, 'ARCH wait on DETACH'                                        , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 124, 'ARCH wait for netserver init 2'                             , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 125, 'LNS wait on LGWR'                                           , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 126, 'LGWR wait on LNS'                                           , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 127, 'ARCH wait for flow-control'                                 , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 128, 'ARCH wait for netserver detach'                             , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 129, 'LNS ASYNC archive log'                                      , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 130, 'LNS ASYNC dest activation'                                  , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 131, 'LNS ASYNC end of log'                                       , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 132, 'log file sequential read'                                   , 'System I/O'     , 'N', 'log#'                                    , 'block#'                     , 'blocks'                 );
  ~~tool_administer_schema..ins( 133, 'log file single write'                                      , 'System I/O'     , 'N', 'log#'                                    , 'block#'                     , 'blocks'                 );
  ~~tool_administer_schema..ins( 134, 'log file parallel write'                                    , 'System I/O'     , 'N', 'files'                                   , 'blocks'                     , 'requests'               );
  ~~tool_administer_schema..ins( 135, 'latch: redo writing'                                        , 'Configuration'  , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 136, 'latch: redo copy'                                           , 'Configuration'  , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 137, 'log buffer space'                                           , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 138, 'log file switch (checkpoint incomplete)'                    , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 139, 'log file switch (private strand flush incomplete)'          , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 140, 'log file switch (archiving needed)'                         , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 141, 'switch logfile command'                                     , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 142, 'log file switch completion'                                 , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 143, 'log file sync'                                              , 'Commit'         , 'N', 'buffer#'                                 , 'sync scn'                   , ''                       );
  ~~tool_administer_schema..ins( 144, 'simulated log write delay'                                  , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 145, 'LGWR real time apply sync'                                  , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 146, 'db file sequential read'                                    , 'User I/O'       , 'N', 'file#'                                   , 'block#'                     , 'blocks'                 );
  ~~tool_administer_schema..ins( 147, 'db file scattered read'                                     , 'User I/O'       , 'N', 'file#'                                   , 'block#'                     , 'blocks'                 );
  ~~tool_administer_schema..ins( 148, 'db file single write'                                       , 'User I/O'       , 'N', 'file#'                                   , 'block#'                     , 'blocks'                 );
  ~~tool_administer_schema..ins( 149, 'db file parallel write'                                     , 'System I/O'     , 'N', 'requests'                                , 'interrupt'                  , 'timeout'                );
  ~~tool_administer_schema..ins( 150, 'db file async I/O submit'                                   , 'System I/O'     , 'N', 'requests'                                , 'interrupt'                  , 'timeout'                );
  ~~tool_administer_schema..ins( 151, 'db file parallel read'                                      , 'User I/O'       , 'N', 'files'                                   , 'blocks'                     , 'requests'               );
  ~~tool_administer_schema..ins( 152, 'enq: MV - datafile move'                                    , 'Administrative' , 'N', 'name|mode'                               , 'type'                       , 'file #'                 );
  ~~tool_administer_schema..ins( 153, 'gc current request'                                         , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'id#'                    );
  ~~tool_administer_schema..ins( 154, 'gc cr request'                                              , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins( 155, 'gc cr disk request'                                         , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins( 156, 'gc cr multi block request'                                  , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins( 157, 'gc current multi block request'                             , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'id#'                    );
  ~~tool_administer_schema..ins( 158, 'gc block recovery request'                                  , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins( 159, 'gc cr block 2-way'                                          , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 160, 'gc cr block 3-way'                                          , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 161, 'gc cr block busy'                                           , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 162, 'gc cr block congested'                                      , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 163, 'gc cr failure'                                              , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 164, 'gc cr block lost'                                           , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 165, 'gc cr block unknown'                                        , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 166, 'gc current block 2-way'                                     , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 167, 'gc current block 3-way'                                     , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 168, 'gc current block busy'                                      , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 169, 'gc current block congested'                                 , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 170, 'gc current retry'                                           , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 171, 'gc current block lost'                                      , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 172, 'gc current split'                                           , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 173, 'gc current block unknown'                                   , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 174, 'gc cr grant 2-way'                                          , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 175, 'gc cr grant busy'                                           , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 176, 'gc cr grant congested'                                      , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 177, 'gc cr grant unknown'                                        , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 178, 'gc cr disk read'                                            , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 179, 'gc current grant 2-way'                                     , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 180, 'gc current grant busy'                                      , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 181, 'gc current grant congested'                                 , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 182, 'gc current grant unknown'                                   , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 183, 'gc freelist'                                                , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 184, 'gc remaster'                                                , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins( 185, 'gc quiesce'                                                 , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 186, 'gc object scan'                                             , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 187, 'gc recovery'                                                , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 188, 'gc flushed buffer'                                          , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 189, 'gc current cancel'                                          , 'Cluster'        , 'N', 'le'                                      , ''                           , ''                       );
  ~~tool_administer_schema..ins( 190, 'gc cr cancel'                                               , 'Cluster'        , 'N', 'le'                                      , ''                           , ''                       );
  ~~tool_administer_schema..ins( 191, 'gc assume'                                                  , 'Cluster'        , 'N', 'le'                                      , ''                           , ''                       );
  ~~tool_administer_schema..ins( 192, 'gc domain validation'                                       , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins( 193, 'gc recovery free'                                           , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 194, 'gc recovery quiesce'                                        , 'Cluster'        , 'N', 'file#'                                   , 'block#'                     , 'class#'                 );
  ~~tool_administer_schema..ins( 195, 'gc claim'                                                   , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 196, 'gc cancel retry'                                            , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 197, 'direct path read'                                           , 'User I/O'       , 'N', 'file number'                             , 'first dba'                  , 'block cnt'              );
  ~~tool_administer_schema..ins( 198, 'direct path read temp'                                      , 'User I/O'       , 'N', 'file number'                             , 'first dba'                  , 'block cnt'              );
  ~~tool_administer_schema..ins( 199, 'direct path write'                                          , 'User I/O'       , 'N', 'file number'                             , 'first dba'                  , 'block cnt'              );
  ~~tool_administer_schema..ins( 200, 'direct path write temp'                                     , 'User I/O'       , 'N', 'file number'                             , 'first dba'                  , 'block cnt'              );
  ~~tool_administer_schema..ins( 201, 'parallel recovery slave idle wait'                          , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 202, 'LogMiner builder: idle'                                     , 'Idle'           , 'Y', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 203, 'LogMiner builder: memory'                                   , 'Queueing'       , 'N', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 204, 'LogMiner builder: DDL'                                      , 'Queueing'       , 'N', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 205, 'LogMiner builder: branch'                                   , 'Idle'           , 'Y', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 206, 'LogMiner preparer: idle'                                    , 'Idle'           , 'Y', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 207, 'LogMiner preparer: memory'                                  , 'Queueing'       , 'N', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 208, 'LogMiner reader: buffer'                                    , 'Queueing'       , 'N', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 209, 'LogMiner reader: log (idle)'                                , 'Idle'           , 'Y', 'Session ID'                              , 'Thread'                     , 'Sequence'               );
  ~~tool_administer_schema..ins( 210, 'LogMiner reader: redo (idle)'                               , 'Idle'           , 'Y', 'Session ID'                              , 'Thread'                     , 'Sequence'               );
  ~~tool_administer_schema..ins( 211, 'LogMiner client: transaction'                               , 'Idle'           , 'Y', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 212, 'LogMiner: other'                                            , 'Idle'           , 'Y', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 213, 'LogMiner: activate'                                         , 'Idle'           , 'Y', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 214, 'LogMiner: reset'                                            , 'Idle'           , 'Y', 'Caller ID'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 215, 'LogMiner: find session'                                     , 'Idle'           , 'Y', 'Session ID'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 216, 'LogMiner: internal'                                         , 'Idle'           , 'Y', 'Caller ID'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 217, 'Logical Standby Apply Delay'                                , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 218, 'wait for possible quiesce finish'                           , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 219, 'parallel recovery coordinator waits for slave cleanup'      , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 220, 'flashback log file write'                                   , 'System I/O'     , 'N', 'log#'                                    , 'block#'                     , 'Bytes'                  );
  ~~tool_administer_schema..ins( 221, 'flashback log file read'                                    , 'System I/O'     , 'N', 'log#'                                    , 'block#'                     , 'Bytes'                  );
  ~~tool_administer_schema..ins( 222, 'flashback buf free by RVWR'                                 , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 223, 'flashback log file sync'                                    , 'User I/O'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 224, 'parallel recovery control message reply'                    , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 225, 'cell smart table scan'                                      , 'User I/O'       , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 226, 'cell smart index scan'                                      , 'User I/O'       , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 227, 'cell statistics gather'                                     , 'User I/O'       , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 228, 'cell smart incremental backup'                              , 'System I/O'     , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 229, 'cell smart file creation'                                   , 'User I/O'       , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 230, 'cell smart restore from backup'                             , 'System I/O'     , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 231, 'parallel recovery slave next change'                        , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 232, 'concurrent I/O completion'                                  , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 233, 'datafile copy range completion'                             , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 234, 'enq: TM - contention'                                       , 'Application'    , 'N', 'name|mode'                               , 'object #'                   , 'table/partition'        );
  ~~tool_administer_schema..ins( 235, 'enq: ST - contention'                                       , 'Configuration'  , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 236, 'undo segment extension'                                     , 'Configuration'  , 'N', 'segment#'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 237, 'undo segment tx slot'                                       , 'Configuration'  , 'N', 'segment#'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 238, 'switch undo - offline'                                      , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 239, 'alter rbs offline'                                          , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 240, 'enq: TX - row lock contention'                              , 'Application'    , 'N', 'name|mode'                               , 'usn<<16 | slot'             , 'sequence'               );
  ~~tool_administer_schema..ins( 241, 'enq: TX - allocate ITL entry'                               , 'Configuration'  , 'N', 'name|mode'                               , 'usn<<16 | slot'             , 'sequence'               );
  ~~tool_administer_schema..ins( 242, 'enq: TX - index contention'                                 , 'Concurrency'    , 'N', 'name|mode'                               , 'usn<<16 | slot'             , 'sequence'               );
  ~~tool_administer_schema..ins( 243, 'enq: TW - contention'                                       , 'Administrative' , 'N', 'name|mode'                               , '0'                          , 'operation'              );
  ~~tool_administer_schema..ins( 244, 'PX Deq: Txn Recovery Start'                                 , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 245, 'PX Deq: Txn Recovery Reply'                                 , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 246, 'latch: Undo Hint Latch'                                     , 'Concurrency'    , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 247, 'statement suspended, wait error to be cleared'              , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 248, 'latch: In memory undo latch'                                , 'Concurrency'    , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 249, 'latch: MQL Tracking Latch'                                  , 'Concurrency'    , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 250, 'fbar timer'                                                 , 'Idle'           , 'Y', 'sleep time'                              , 'failed'                     , ''                       );
  ~~tool_administer_schema..ins( 251, 'Archive Manager file transfer I/O'                          , 'User I/O'       , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins( 252, 'securefile chain update'                                    , 'Concurrency'    , 'N', 'seghdr'                                  , 'fsb'                        , ''                       );
  ~~tool_administer_schema..ins( 253, 'enq: HW - contention'                                       , 'Configuration'  , 'N', 'name|mode'                               , 'table space #'              , 'block'                  );
  ~~tool_administer_schema..ins( 254, 'enq: SS - contention'                                       , 'Configuration'  , 'N', 'name|mode'                               , 'tablespace #'               , 'dba'                    );
  ~~tool_administer_schema..ins( 255, 'sort segment request'                                       , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 256, 'smon timer'                                                 , 'Idle'           , 'Y', 'sleep time'                              , 'failed'                     , ''                       );
  ~~tool_administer_schema..ins( 257, 'PX Deq: Metadata Update'                                    , 'Idle'           , 'Y', 'ktelc_wait1s'                            , ''                           , ''                       );
  ~~tool_administer_schema..ins( 258, 'Space Manager: slave idle wait'                             , 'Idle'           , 'Y', 'Slave ID'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 259, 'enq: SQ - contention'                                       , 'Configuration'  , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 260, 'PX Deq: Index Merge Reply'                                  , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 261, 'PX Deq: Index Merge Execute'                                , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 262, 'PX Deq: Index Merge Close'                                  , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 263, 'enq: HV - contention'                                       , 'Concurrency'    , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 264, 'PX Deq: kdcph_mai'                                          , 'Idle'           , 'Y', 'kdcph_mai'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 265, 'PX Deq: kdcphc_ack'                                         , 'Idle'           , 'Y', 'kdcphc_ack'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 266, 'index (re)build online start'                               , 'Administrative' , 'N', 'object'                                  , 'mode'                       , 'wait'                   );
  ~~tool_administer_schema..ins( 267, 'index (re)build online cleanup'                             , 'Administrative' , 'N', 'object'                                  , 'mode'                       , 'wait'                   );
  ~~tool_administer_schema..ins( 268, 'index (re)build online merge'                               , 'Administrative' , 'N', 'object'                                  , 'mode'                       , 'wait'                   );
  ~~tool_administer_schema..ins( 269, 'securefile direct-read completion'                          , 'User I/O'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 270, 'securefile direct-write completion'                         , 'User I/O'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 271, 'SecureFile mutex'                                           , 'Concurrency'    , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 272, 'enq: WG - lock fso'                                         , 'Concurrency'    , 'N', 'name|mode'                               , 'kdlw lobid first half'      , 'kdlw lobid sec half'    );
  ~~tool_administer_schema..ins( 273, 'latch: row cache objects'                                   , 'Concurrency'    , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 274, 'row cache lock'                                             , 'Concurrency'    , 'N', 'cache id'                                , 'mode'                       , 'request'                );
  ~~tool_administer_schema..ins( 275, 'row cache read'                                             , 'Concurrency'    , 'N', 'cache id'                                , 'address'                    , 'times'                  );
  ~~tool_administer_schema..ins( 276, 'libcache interrupt action by LCK'                           , 'Concurrency'    , 'N', 'location'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 277, 'cursor: mutex X'                                            , 'Concurrency'    , 'N', 'idn'                                     , 'value'                      , 'where'                  );
  ~~tool_administer_schema..ins( 278, 'cursor: mutex S'                                            , 'Concurrency'    , 'N', 'idn'                                     , 'value'                      , 'where'                  );
  ~~tool_administer_schema..ins( 279, 'cursor: pin X'                                              , 'Concurrency'    , 'N', 'idn'                                     , 'value'                      , 'where'                  );
  ~~tool_administer_schema..ins( 280, 'cursor: pin S'                                              , 'Concurrency'    , 'N', 'idn'                                     , 'value'                      , 'where'                  );
  ~~tool_administer_schema..ins( 281, 'cursor: pin S wait on X'                                    , 'Concurrency'    , 'N', 'idn'                                     , 'value'                      , 'where'                  );
  ~~tool_administer_schema..ins( 282, 'Global transaction acquire instance locks'                  , 'Configuration'  , 'N', 'retries'                                 , ''                           , ''                       );
  ~~tool_administer_schema..ins( 283, 'enq: BB - 2PC across RAC instances'                         , 'Commit'         , 'N', 'name|mode'                               , 'gtrid hash value'           , 'bqual hash value'       );
  ~~tool_administer_schema..ins( 284, 'latch: shared pool'                                         , 'Concurrency'    , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 285, 'library cache pin'                                          , 'Concurrency'    , 'N', 'handle address'                          , 'pin address'                , '100*mode+namespace'     );
  ~~tool_administer_schema..ins( 286, 'library cache lock'                                         , 'Concurrency'    , 'N', 'handle address'                          , 'lock address'               , '100*mode+namespace'     );
  ~~tool_administer_schema..ins( 287, 'library cache load lock'                                    , 'Concurrency'    , 'N', 'object address'                          , 'lock address'               , '100*mask+namespace'     );
  ~~tool_administer_schema..ins( 288, 'library cache: mutex X'                                     , 'Concurrency'    , 'N', 'idn'                                     , 'value'                      , 'where'                  );
  ~~tool_administer_schema..ins( 289, 'library cache: mutex S'                                     , 'Concurrency'    , 'N', 'idn'                                     , 'value'                      , 'where'                  );
  ~~tool_administer_schema..ins( 290, 'BFILE read'                                                 , 'User I/O'       , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 291, 'resmgr:cpu quantum'                                         , 'Scheduler'      , 'N', 'location'                                , 'consumer group id'          , ' '                      );
  ~~tool_administer_schema..ins( 292, 'resmgr:large I/O queued'                                    , 'Scheduler'      , 'N', 'location'                                , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 293, 'resmgr:small I/O queued'                                    , 'Scheduler'      , 'N', 'location'                                , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 294, 'resmgr:internal state change'                               , 'Concurrency'    , 'N', 'location'                                , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 295, 'resmgr:sessions to exit'                                    , 'Concurrency'    , 'N', 'location'                                , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 296, 'resmgr:become active'                                       , 'Scheduler'      , 'N', 'location'                                , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 297, 'resmgr:pq queued'                                           , 'Scheduler'      , 'N', 'location'                                , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 298, 'TCP Socket (KGAS)'                                          , 'Network'        , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 299, 'utl_file I/O'                                               , 'User I/O'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 300, 'alter system set dispatcher'                                , 'Administrative' , 'N', 'waited'                                  , ''                           , ''                       );
  ~~tool_administer_schema..ins( 301, 'virtual circuit wait'                                       , 'Network'        , 'N', 'circuit#'                                , 'type'                       , ''                       );
  ~~tool_administer_schema..ins( 302, 'shared server idle wait'                                    , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 303, 'dispatcher timer'                                           , 'Idle'           , 'Y', 'sleep time'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 304, 'dispatcher listen timer'                                    , 'Network'        , 'N', 'sleep time'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 305, 'dedicated server timer'                                     , 'Network'        , 'N', 'wait event'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 306, 'cmon timer'                                                 , 'Idle'           , 'Y', 'sleep time'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 307, 'pool server timer'                                          , 'Idle'           , 'Y', 'sleep time'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 308, 'connection pool wait'                                       , 'Administrative' , 'N', 'op'                                      , 'num servers'                , ''                       );
  ~~tool_administer_schema..ins( 309, 'JOX Jit Process Sleep'                                      , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 310, 'jobq slave wait'                                            , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 311, 'Wait for Table Lock'                                        , 'Application'    , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 312, 'pipe get'                                                   , 'Idle'           , 'Y', 'handle address'                          , 'buffer length'              , 'timeout'                );
  ~~tool_administer_schema..ins( 313, 'pipe put'                                                   , 'Concurrency'    , 'N', 'handle address'                          , 'record length'              , 'timeout'                );
  ~~tool_administer_schema..ins( 314, 'enq: DB - contention'                                       , 'Administrative' , 'N', 'name|mode'                               , 'EnqMode'                    , '0'                      );
  ~~tool_administer_schema..ins( 315, 'PX Deque wait'                                              , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 316, 'PX Idle Wait'                                               , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 317, 'PX Deq: Join ACK'                                           , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 318, 'PX Deq Credit: need buffer'                                 , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , 'qref'                   );
  ~~tool_administer_schema..ins( 319, 'PX Deq Credit: send blkd'                                   , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , 'qref'                   );
  ~~tool_administer_schema..ins( 320, 'PX Deq: Msg Fragment'                                       , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 321, 'PX Deq: Parse Reply'                                        , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 322, 'PX Deq: Execute Reply'                                      , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 323, 'PX Deq: Execution Msg'                                      , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 324, 'PX Deq: Table Q Normal'                                     , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 325, 'PX Deq: Table Q Sample'                                     , 'Idle'           , 'Y', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 326, 'external table read'                                        , 'User I/O'       , 'N', 'filectx'                                 , 'file#'                      , 'size'                   );
  ~~tool_administer_schema..ins( 327, 'external table write'                                       , 'User I/O'       , 'N', 'filectx'                                 , 'file#'                      , 'size'                   );
  ~~tool_administer_schema..ins( 328, 'external table open'                                        , 'User I/O'       , 'N', 'filectx'                                 , 'file#'                      , ''                       );
  ~~tool_administer_schema..ins( 329, 'external table seek'                                        , 'User I/O'       , 'N', 'filectx'                                 , 'file#'                      , 'pos'                    );
  ~~tool_administer_schema..ins( 330, 'external table misc IO'                                     , 'User I/O'       , 'N', 'filectx'                                 , 'iocode'                     , 'P3'                     );
  ~~tool_administer_schema..ins( 331, 'enq: RC - Result Cache: Contention'                         , 'Application'    , 'N', 'name|mode'                               , 'chunkNo'                    , 'blockNo'                );
  ~~tool_administer_schema..ins( 332, 'enq: JX - SQL statement queue'                              , 'Scheduler'      , 'N', 'name|mode'                               , 'sqlid'                      , 'execid'                 );
  ~~tool_administer_schema..ins( 333, 'enq: JX - cleanup of  queue'                                , 'Scheduler'      , 'N', 'name|mode'                               , 'sqlid'                      , 'execid'                 );
  ~~tool_administer_schema..ins( 334, 'PX Queuing: statement queue'                                , 'Scheduler'      , 'N', 'sleeptime'                               , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 335, 'dbverify reads'                                             , 'User I/O'       , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins( 336, 'Streams fetch slave: waiting for txns'                      , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 337, 'Streams capture: waiting for subscribers to catch up'       , 'Queueing'       , 'N', 'Is GoldenGate'                           , 'Is XStream'                 , 'TYPE'                   );
  ~~tool_administer_schema..ins( 338, 'Streams: resolve low memory condition'                      , 'Queueing'       , 'N', 'Is GoldenGate'                           , 'Is XStream'                 , ''                       );
  ~~tool_administer_schema..ins( 339, 'Streams apply: waiting to commit'                           , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 340, 'Streams apply: waiting for dependency'                      , 'Concurrency'    , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 341, 'Streams: flow control'                                      , 'Queueing'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 342, 'Streams: waiting for messages'                              , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 343, 'Streams capture: waiting for archive log'                   , 'Idle'           , 'Y', 'Is GoldenGate'                           , 'Is XStream'                 , 'TYPE'                   );
  ~~tool_administer_schema..ins( 344, 'Streams capture: filter callback waiting for ruleset'       , 'Application'    , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 345, 'Streams: apply reader waiting for DDL to apply'             , 'Application'    , 'N', 'sleep time'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 346, 'enq: ZG - contention'                                       , 'Administrative' , 'N', 'name|mode'                               , 'file group id'              , 'version id'             );
  ~~tool_administer_schema..ins( 347, 'single-task message'                                        , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 348, 'SQL*Net message to client'                                  , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 349, 'SQL*Net message to dblink'                                  , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 350, 'SQL*Net more data to client'                                , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 351, 'SQL*Net more data to dblink'                                , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 352, 'SQL*Net message from client'                                , 'Idle'           , 'Y', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 353, 'SQL*Net more data from client'                              , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 354, 'SQL*Net message from dblink'                                , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 355, 'SQL*Net more data from dblink'                              , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 356, 'SQL*Net vector message from client'                         , 'Idle'           , 'Y', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 357, 'SQL*Net vector message from dblink'                         , 'Idle'           , 'Y', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 358, 'SQL*Net vector data to client'                              , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 359, 'SQL*Net vector data from client'                            , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 360, 'SQL*Net vector data to dblink'                              , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 361, 'SQL*Net vector data from dblink'                            , 'Network'        , 'N', 'driver id'                               , '#bytes'                     , ''                       );
  ~~tool_administer_schema..ins( 362, 'SQL*Net break/reset to client'                              , 'Application'    , 'N', 'driver id'                               , 'break?'                     , ''                       );
  ~~tool_administer_schema..ins( 363, 'SQL*Net break/reset to dblink'                              , 'Application'    , 'N', 'driver id'                               , 'break?'                     , ''                       );
  ~~tool_administer_schema..ins( 364, 'External Procedure initial connection'                      , 'Application'    , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 365, 'External Procedure call'                                    , 'Application'    , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 366, 'PL/SQL lock timer'                                          , 'Idle'           , 'Y', 'duration'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 367, 'enq: UL - contention'                                       , 'Application'    , 'N', 'name|mode'                               , 'id'                         , '0'                      );
  ~~tool_administer_schema..ins( 368, 'wait for EMON to process ntfns'                             , 'Configuration'  , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 369, 'Streams AQ: emn coordinator idle wait'                      , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 370, 'EMON slave idle wait'                                       , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 371, 'Streams AQ: waiting for messages in the queue'              , 'Idle'           , 'Y', 'queue id'                                , 'process#'                   , 'wait time'              );
  ~~tool_administer_schema..ins( 372, 'Streams AQ: waiting for time management or cleanup tasks'   , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 373, 'Streams AQ: enqueue blocked on low memory'                  , 'Queueing'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 374, 'Streams AQ: enqueue blocked due to flow control'            , 'Queueing'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 375, 'Streams AQ: delete acknowledged messages'                   , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 376, 'Streams AQ: deallocate messages from Streams Pool'          , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 377, 'Streams AQ: qmn coordinator idle wait'                      , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 378, 'Streams AQ: qmn slave idle wait'                            , 'Idle'           , 'Y', 'Type'                                    , ''                           , ''                       );
  ~~tool_administer_schema..ins( 379, 'Streams AQ: RAC qmn coordinator idle wait'                  , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 380, 'HS message to agent'                                        , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 381, 'TEXT: URL_DATASTORE network wait'                           , 'Network'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 382, 'TEXT: File System I/O'                                      , 'User I/O'       , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 383, 'OLAP DML Sleep'                                             , 'Application'    , 'N', 'duration'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 384, 'ASM COD rollback operation completion'                      , 'Administrative' , 'N', 'dismount force'                          , ''                           , ''                       );
  ~~tool_administer_schema..ins( 385, 'kfk: async disk IO'                                         , 'System I/O'     , 'N', 'count'                                   , 'intr'                       , 'timeout'                );
  ~~tool_administer_schema..ins( 386, 'ASM background timer'                                       , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 387, 'ASM Fixed Package I/O'                                      , 'User I/O'       , 'N', 'blkno'                                   , 'bytes'                      , 'filetype'               );
  ~~tool_administer_schema..ins( 388, 'ASM mount : wait for heartbeat'                             , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 389, 'ASM PST query : wait for [PM][grp][0] grant'                , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 390, 'lock remastering'                                           , 'Cluster'        , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 391, 'ASM Staleness File I/O'                                     , 'User I/O'       , 'N', 'blkno'                                   , '#blks'                      , 'diskno'                 );
  ~~tool_administer_schema..ins( 392, 'auto-sqltune: wait graph update'                            , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 393, 'WCR: replay client notify'                                  , 'Idle'           , 'Y', 'who am I'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 394, 'WCR: replay clock'                                          , 'Idle'           , 'Y', 'wait for scn''s hi 4 bytes'              , 'wait for scn''s lo 4 bytes' , ''                       );
  ~~tool_administer_schema..ins( 395, 'WCR: replay lock order'                                     , 'Application'    , 'N', 'wait for scn''s hi 4 bytes'              , 'wait for scn''s lo 4 bytes' , ''                       );
  ~~tool_administer_schema..ins( 396, 'WCR: replay paused'                                         , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 397, 'JS kgl get object wait'                                     , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 398, 'JS external job'                                            , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 399, 'JS kill job wait'                                           , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 400, 'JS coord start wait'                                        , 'Administrative' , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 401, 'cell single block physical read'                            , 'User I/O'       , 'N', 'cellhash#'                               , 'diskhash#'                  , 'bytes'                  );
  ~~tool_administer_schema..ins( 402, 'cell multiblock physical read'                              , 'User I/O'       , 'N', 'cellhash#'                               , 'diskhash#'                  , 'bytes'                  );
  ~~tool_administer_schema..ins( 403, 'cell list of blocks physical read'                          , 'User I/O'       , 'N', 'cellhash#'                               , 'diskhash#'                  , 'blocks'                 );
  ~~tool_administer_schema..ins( 404, 'cell manager opening cell'                                  , 'System I/O'     , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 405, 'cell manager closing cell'                                  , 'System I/O'     , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 406, 'cell manager discovering disks'                             , 'System I/O'     , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 407, 'cell worker idle'                                           , 'Idle'           , 'Y', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 408, 'events in waitclass Other'                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 409, 'enq: WM - WLM Plan activation'                              , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 410, 'latch free'                                                 , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 411, 'kslwait unit test event 1'                                  , 'Other'          , 'N', 'p1'                                      , 'p2'                         , 'p3'                     );
  ~~tool_administer_schema..ins( 412, 'kslwait unit test event 2'                                  , 'Other'          , 'N', 'p1'                                      , 'p2'                         , 'p3'                     );
  ~~tool_administer_schema..ins( 413, 'kslwait unit test event 3'                                  , 'Other'          , 'N', 'p1'                                      , 'p2'                         , 'p3'                     );
  ~~tool_administer_schema..ins( 414, 'unspecified wait event'                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 415, 'latch activity'                                             , 'Other'          , 'N', 'address'                                 , 'number'                     , 'process#'               );
  ~~tool_administer_schema..ins( 416, 'wait list latch activity'                                   , 'Other'          , 'N', 'address'                                 , 'number'                     , 'process#'               );
  ~~tool_administer_schema..ins( 417, 'wait list latch free'                                       , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 418, 'global enqueue expand wait'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 419, 'free process state object'                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 420, 'inactive session'                                           , 'Other'          , 'N', 'session#'                                , 'waited'                     , 'instance|serial'        );
  ~~tool_administer_schema..ins( 421, 'process terminate'                                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 422, 'latch: call allocation'                                     , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 423, 'latch: session allocation'                                  , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 424, 'check CPU wait times'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 425, 'enq: CI - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'opcode'                     , 'type'                   );
  ~~tool_administer_schema..ins( 426, 'enq: PR - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 427, 'ksim generic wait event'                                    , 'Other'          , 'N', 'where'                                   , 'wait_count'                 , ''                       );
  ~~tool_administer_schema..ins( 428, 'debugger command'                                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 429, 'ksdxexeother'                                               , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 430, 'ksdxexeotherwait'                                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 431, 'enq: PE - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'parno'                      , '0'                      );
  ~~tool_administer_schema..ins( 432, 'enq: PG - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 433, 'ksbsrv'                                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 434, 'ksbcic'                                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 435, 'process startup'                                            , 'Other'          , 'N', 'type'                                    , 'process#'                   , 'waited'                 );
  ~~tool_administer_schema..ins( 436, 'process shutdown'                                           , 'Other'          , 'N', 'type'                                    , 'process#'                   , 'waited'                 );
  ~~tool_administer_schema..ins( 437, 'prior spawner clean up'                                     , 'Other'          , 'N', 'process_pid'                             , 'process_sno'                , ''                       );
  ~~tool_administer_schema..ins( 438, 'latch: messages'                                            , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 439, 'rdbms ipc message block'                                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 440, 'rdbms ipc reply'                                            , 'Other'          , 'N', 'from_process'                            , 'timeout'                    , ''                       );
  ~~tool_administer_schema..ins( 441, 'latch: enqueue hash chains'                                 , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 442, 'enq: FP - global fob contention'                            , 'Other'          , 'N', 'name|mode'                               , 'low file obj add'           , 'high file obj add'      );
  ~~tool_administer_schema..ins( 443, 'enq: RE - block repair contention'                          , 'Other'          , 'N', 'name|mode'                               , 'File Type or File number'   , 'block number'           );
  ~~tool_administer_schema..ins( 444, 'enq: BM - clonedb bitmap file write'                        , 'Other'          , 'N', 'name|mode'                               , 'block number'               , 'number of blocks'       );
  ~~tool_administer_schema..ins( 445, 'asynch descriptor resize'                                   , 'Other'          , 'N', 'outstanding #aio'                        , 'current aio limit'          , 'new aio limit'          );
  ~~tool_administer_schema..ins( 446, 'imm op'                                                     , 'Other'          , 'N', 'msg ptr'                                 , ''                           , ''                       );
  ~~tool_administer_schema..ins( 447, 'slave exit'                                                 , 'Other'          , 'N', 'nalive'                                  , 'sleeptime'                  , 'loop'                   );
  ~~tool_administer_schema..ins( 448, 'enq: KM - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'type'                       , 'type'                   );
  ~~tool_administer_schema..ins( 449, 'enq: KT - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'plan #'                     , '0'                      );
  ~~tool_administer_schema..ins( 450, 'enq: CA - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 451, 'enq: KD - determine DBRM master'                            , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 452, 'reliable message'                                           , 'Other'          , 'N', 'channel context'                         , 'channel handle'             , 'broadcast message'      );
  ~~tool_administer_schema..ins( 453, 'broadcast mesg queue transition'                            , 'Other'          , 'N', 'channel handle'                          , 'message'                    , 'location'               );
  ~~tool_administer_schema..ins( 454, 'broadcast mesg recovery queue transition'                   , 'Other'          , 'N', 'channel handle'                          , 'message'                    , 'location'               );
  ~~tool_administer_schema..ins( 455, 'master exit'                                                , 'Other'          , 'N', 'alive slaves'                            , ''                           , ''                       );
  ~~tool_administer_schema..ins( 456, 'ksv slave avail wait'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 457, 'enq: PV - syncstart'                                        , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 458, 'enq: PV - syncshut'                                         , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 459, 'enq: SP - contention 1'                                     , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins( 460, 'enq: SP - contention 2'                                     , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins( 461, 'enq: SP - contention 3'                                     , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins( 462, 'enq: SP - contention 4'                                     , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins( 463, 'IPC send completion sync'                                   , 'Other'          , 'N', 'send count'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 464, 'OSD IPC library'                                            , 'Other'          , 'N', 'rolling mig'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 465, 'IPC wait for name service busy'                             , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 466, 'IPC busy async request'                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 467, 'IPC waiting for OSD resources'                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 468, 'ksxr poll remote instances'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 469, 'ksxr wait for mount shared'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 470, 'DBMS_LDAP: LDAP operation '                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 471, 'wait for FMON to come up'                                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 472, 'enq: FM - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 473, 'enq: XY - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins( 474, 'set director factor wait'                                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 475, 'latch: active service list'                                 , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 476, 'enq: AS - service activation'                               , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 477, 'enq: PD - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'property name'              , 'key hash'               );
  ~~tool_administer_schema..ins( 478, 'cleanup of aborted process'                                 , 'Other'          , 'N', 'location'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 479, 'enq: RU - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 480, 'enq: RU - waiting'                                          , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 481, 'rolling migration: cluster quiesce'                         , 'Other'          , 'N', 'location'                                , 'waits'                      , ''                       );
  ~~tool_administer_schema..ins( 482, 'LMON global data update'                                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 483, 'process diagnostic dump'                                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 484, 'enq: MX - sync storage server info'                         , 'Other'          , 'N', 'name|mode'                               , 'nodeid'                     , 'instanceid'             );
  ~~tool_administer_schema..ins( 485, 'master diskmon startup'                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 486, 'master diskmon read'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 487, 'DSKM to complete cell health check'                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 488, 'pmon dblkr tst event'                                       , 'Other'          , 'N', 'index'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 489, 'latch: ges resource hash list'                              , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 490, 'DFS lock handle'                                            , 'Other'          , 'N', 'type|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins( 491, 'ges LMD to shutdown'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 492, 'ges client process to exit'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 493, 'ges global resource directory to be frozen'                 , 'Other'          , 'N', 'location'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 494, 'ges resource directory to be unfrozen'                      , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 495, 'gcs resource directory to be unfrozen'                      , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 496, 'ges LMD to inherit communication channels'                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 497, 'ges lmd sync during reconfig'                               , 'Other'          , 'N', 'location'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 498, 'ges wait for lmon to be ready'                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 499, 'ges cgs registration'                                       , 'Other'          , 'N', 'where'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 500, 'wait for master scn'                                        , 'Other'          , 'N', 'waittime'                                , 'startscn'                   , 'ackscn'                 );
  ~~tool_administer_schema..ins( 501, 'ges yield cpu in reconfig'                                  , 'Other'          , 'N', 'location'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 502, 'ges2 proc latch in rm latch get 1'                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 503, 'ges2 proc latch in rm latch get 2'                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 504, 'ges lmd/lmses to freeze in rcfg'                            , 'Other'          , 'N', 'lmd/lms id'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 505, 'ges lmd/lmses to unfreeze in rcfg'                          , 'Other'          , 'N', 'lmd/lms id'                              , ''                           , ''                       );
  ~~tool_administer_schema..ins( 506, 'ges lms sync during dynamic remastering and reconfig'       , 'Other'          , 'N', 'location'                                , 'lms id'                     , ''                       );
  ~~tool_administer_schema..ins( 507, 'ges LMON to join CGS group'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 508, 'ges pmon to exit'                                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 509, 'ges lmd and pmon to attach'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 510, 'gcs drm freeze begin'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 511, 'gcs retry nowait latch get'                                 , 'Other'          , 'N', 'location'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 512, 'gcs remastering wait for read latch'                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 513, 'ges cached resource cleanup'                                , 'Other'          , 'N', 'waittime'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 514, 'ges generic event'                                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 515, 'ges retry query node'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 516, 'ges process with outstanding i/o'                           , 'Other'          , 'N', 'pid'                                     , ''                           , ''                       );
  ~~tool_administer_schema..ins( 517, 'ges user error'                                             , 'Other'          , 'N', 'error'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 518, 'ges enter server mode'                                      , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 519, 'gcs enter server mode'                                      , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 520, 'gcs drm freeze in enter server mode'                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 521, 'gcs ddet enter server mode'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 522, 'ges cancel'                                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 523, 'ges resource cleanout during enqueue open'                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 524, 'ges resource cleanout during enqueue open-cvt'              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 525, 'ges master to get established for SCN op'                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 526, 'ges LMON to get to FTDONE '                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 527, 'ges1 LMON to wake up LMD - mrcvr'                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 528, 'ges2 LMON to wake up LMD - mrcvr'                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 529, 'ges2 LMON to wake up lms - mrcvr 2'                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 530, 'ges2 LMON to wake up lms - mrcvr 3'                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 531, 'ges inquiry response'                                       , 'Other'          , 'N', 'type|mode|where'                         , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins( 532, 'ges reusing os pid'                                         , 'Other'          , 'N', 'pid'                                     , 'count'                      , ''                       );
  ~~tool_administer_schema..ins( 533, 'ges LMON for send queues'                                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 534, 'ges LMD suspend for testing event'                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 535, 'ges performance test completion'                            , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 536, 'kjbopen wait for recovery domain attach'                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 537, 'kjudomatt wait for recovery domain attach'                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 538, 'kjudomdet wait for recovery domain detach'                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 539, 'kjbdomalc allocate recovery domain - retry'                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 540, 'kjbdrmcvtq lmon drm quiesce: ping completion'               , 'Other'          , 'N', 'location'                                , 'lms id'                     , ''                       );
  ~~tool_administer_schema..ins( 541, 'ges RMS0 retry add redo log'                                , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 542, 'readable standby redo apply remastering'                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 543, 'ges DFS hang analysis phase 2 acks'                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 544, 'ges/gcs diag dump'                                          , 'Other'          , 'N', 'location'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 545, 'global plug and play automatic resource creation'           , 'Other'          , 'N', 'where'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 546, 'gcs lmon dirtydetach step completion'                       , 'Other'          , 'N', 'domain id'                               , 'location'                   , ''                       );
  ~~tool_administer_schema..ins( 547, 'recovery instance recovery completion '                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 548, 'ack for a broadcasted res from a remote instance'           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 549, 'KJC: Wait for msg sends to complete'                        , 'Other'          , 'N', 'msg'                                     , 'dest|rcvr'                  , 'mtype'                  );
  ~~tool_administer_schema..ins( 550, 'ges message buffer allocation'                              , 'Other'          , 'N', 'pool'                                    , 'request'                    , 'allocated'              );
  ~~tool_administer_schema..ins( 551, 'kjctssqmg: quick message send wait'                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 552, 'kjctcisnd: Queue/Send client message'                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 553, 'gcs domain validation'                                      , 'Other'          , 'N', 'cluinc'                                  , 'rcvinc'                     , ''                       );
  ~~tool_administer_schema..ins( 554, 'latch: gcs resource hash'                                   , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 555, 'affinity expansion in replay'                               , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 556, 'wait for sync ack'                                          , 'Other'          , 'N', 'cluinc'                                  , 'pending_nd'                 , ''                       );
  ~~tool_administer_schema..ins( 557, 'wait for verification ack'                                  , 'Other'          , 'N', 'cluinc'                                  , 'pending_insts'              , ''                       );
  ~~tool_administer_schema..ins( 558, 'wait for assert messages to be sent'                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 559, 'wait for scn ack'                                           , 'Other'          , 'N', 'pending_nd'                              , 'scnwrp'                     , 'scnbas'                 );
  ~~tool_administer_schema..ins( 560, 'lms flush message acks'                                     , 'Other'          , 'N', 'id'                                      , ''                           , ''                       );
  ~~tool_administer_schema..ins( 561, 'name-service call wait'                                     , 'Other'          , 'N', 'waittime'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 562, 'CGS wait for IPC msg'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 563, 'kjxgrtest'                                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 564, 'IMR mount phase II completion'                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 565, 'IMR disk votes'                                             , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 566, 'IMR rr lock release'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 567, 'IMR net-check message ack'                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 568, 'IMR rr update'                                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 569, 'IMR membership resolution'                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 570, 'IMR CSS join retry'                                         , 'Other'          , 'N', 'retry count'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 571, 'CGS skgxn join retry'                                       , 'Other'          , 'N', 'retry count'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 572, 'gcs to be enabled'                                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 573, 'gcs log flush sync'                                         , 'Other'          , 'N', 'waittime'                                , 'poll'                       , 'event'                  );
  ~~tool_administer_schema..ins( 574, 'GCR ctx lock acquisition'                                   , 'Other'          , 'N', 'retry count'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 575, 'GCR lock acquisition'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 576, 'GCR CSS join retry'                                         , 'Other'          , 'N', 'retry count'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 577, 'GCR member Data from CSS '                                  , 'Other'          , 'N', 'retry count'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 578, 'SGA: allocation forcing component growth'                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 579, 'SGA: sga_target resize'                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 580, 'control file heartbeat'                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 581, 'control file diagnostic dump'                               , 'Other'          , 'N', 'type'                                    , 'param'                      , ''                       );
  ~~tool_administer_schema..ins( 582, 'enq: CF - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , 'operation'              );
  ~~tool_administer_schema..ins( 583, 'enq: SW - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 584, 'enq: DS - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 585, 'enq: TC - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'checkpoint ID'              , '0'                      );
  ~~tool_administer_schema..ins( 586, 'enq: TC - contention2'                                      , 'Other'          , 'N', 'name|mode'                               , 'checkpoint ID'              , '0'                      );
  ~~tool_administer_schema..ins( 587, 'buffer exterminate'                                         , 'Other'          , 'N', 'file#'                                   , 'block#'                     , 'buf_ptr'                );
  ~~tool_administer_schema..ins( 588, 'buffer resize'                                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 589, 'latch: cache buffers lru chain'                             , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 590, 'enq: PW - perwarm status in dbw0'                           , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 591, 'latch: checkpoint queue latch'                              , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 592, 'latch: cache buffer handles'                                , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 593, 'kcbzps'                                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 594, 'DBWR range invalidation sync'                               , 'Other'          , 'N', 'dbwr#'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 595, 'buffer deadlock'                                            , 'Other'          , 'N', 'dba'                                     , 'class*10+mode'              , 'flag'                   );
  ~~tool_administer_schema..ins( 596, 'buffer latch'                                               , 'Other'          , 'N', 'latch addr'                              , 'chain#'                     , ''                       );
  ~~tool_administer_schema..ins( 597, 'cr request retry'                                           , 'Other'          , 'N', 'file#'                                   , 'block#'                     , ''                       );
  ~~tool_administer_schema..ins( 598, 'writes stopped by instance recovery or database suspension' , 'Other'          , 'N', 'by thread#'                              , 'our thread#'                , ''                       );
  ~~tool_administer_schema..ins( 599, 'lock escalate retry'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 600, 'lock deadlock retry'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
END;
/
BEGIN
  ~~tool_administer_schema..ins( 601, 'prewarm transfer retry'                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 602, 'recovery buffer pinned'                                     , 'Other'          , 'N', 'file#'                                   , 'block#'                     , ''                       );
  ~~tool_administer_schema..ins( 603, 'TSE master key rekey'                                       , 'Other'          , 'N', 'ts#'                                     , ''                           , ''                       );
  ~~tool_administer_schema..ins( 604, 'TSE SSO wallet reopen'                                      , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 605, 'enq: CR - block range reuse ckpt'                           , 'Other'          , 'N', 'name|mode'                               , '2'                          , '0'                      );
  ~~tool_administer_schema..ins( 606, 'wait for MTTR advisory state object'                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 607, 'latch: object queue header operation'                       , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 608, 'Wait on stby instance close'                                , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 609, 'ARCH wait for archivelog lock'                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 610, 'enq: WL - Test access/locking'                              , 'Other'          , 'N', 'name|mode'                               , 'log # / thread id #'        , 'sequence #'             );
  ~~tool_administer_schema..ins( 611, 'FAL archive wait 1 sec for REOPEN minimum'                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 612, 'TEST: action sync'                                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 613, 'TEST: action hang'                                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 614, 'RSGA: RAC reconfiguration'                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 615, 'enq: WL - RAC-wide SGA contention'                          , 'Other'          , 'N', 'name|mode'                               , 'log # / thread id #'        , 'sequence #'             );
  ~~tool_administer_schema..ins( 616, 'LGWR ORL/NoExp FAL archival'                                , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 617, 'MRP wait on process start'                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 618, 'MRP wait on process restart'                                , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 619, 'MRP wait on startup clear'                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 620, 'MRP inactivation'                                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 621, 'MRP termination'                                            , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 622, 'MRP state inspection'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 623, 'MRP wait on archivelog arrival'                             , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 624, 'MRP wait on archivelog archival'                            , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 625, 'log switch/archive'                                         , 'Other'          , 'N', 'thread#'                                 , ''                           , ''                       );
  ~~tool_administer_schema..ins( 626, 'ARCH wait on c/f tx acquire 1'                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 627, 'RFS attach'                                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 628, 'RFS create'                                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 629, 'RFS close'                                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 630, 'RFS announce'                                               , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 631, 'RFS register'                                               , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 632, 'RFS detach'                                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 633, 'RFS ping'                                                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 634, 'RFS dispatch'                                               , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 635, 'enq: WL - RFS global state contention'                      , 'Other'          , 'N', 'name|mode'                               , 'log # / thread id #'        , 'sequence #'             );
  ~~tool_administer_schema..ins( 636, 'LGWR simulation latency wait'                               , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 637, 'LNS simulation latency wait'                                , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 638, 'Data Guard: RFS disk I/O'                                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 639, 'ARCH wait for process start 1'                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 640, 'ARCH wait for process death 1'                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 641, 'ARCH wait for process start 3'                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 642, 'Data Guard: process exit'                                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 643, 'Data Guard: process clean up'                               , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 644, 'LGWR-LNS wait on channel'                                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 645, 'enq: WR - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'thread id #'                , 'sequence #'             );
  ~~tool_administer_schema..ins( 646, 'LGWR wait for redo copy'                                    , 'Other'          , 'N', 'copy latch #'                            , ''                           , ''                       );
  ~~tool_administer_schema..ins( 647, 'latch: redo allocation'                                     , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 648, 'log file switch (clearing log file)'                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 649, 'enq: WL - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'log # / thread id #'        , 'sequence #'             );
  ~~tool_administer_schema..ins( 650, 'enq: RN - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'thread number'              , 'log number'             );
  ~~tool_administer_schema..ins( 651, 'DFS db file lock'                                           , 'Other'          , 'N', 'file#'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 652, 'enq: DF - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , 'file #'                 );
  ~~tool_administer_schema..ins( 653, 'enq: IS - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , 'type'                   );
  ~~tool_administer_schema..ins( 654, 'enq: FS - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , 'type'                   );
  ~~tool_administer_schema..ins( 655, 'enq: DM - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'type'                       , 'type'                   );
  ~~tool_administer_schema..ins( 656, 'enq: RP - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'file #'                     , '1 or block'             );
  ~~tool_administer_schema..ins( 657, 'latch: gc element'                                          , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 658, 'enq: RT - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'redo thread'                , 'type'                   );
  ~~tool_administer_schema..ins( 659, 'enq: RT - thread internal enable/disable'                   , 'Other'          , 'N', 'name|mode'                               , 'redo thread'                , 'type'                   );
  ~~tool_administer_schema..ins( 660, 'enq: IR - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0/1'                    );
  ~~tool_administer_schema..ins( 661, 'enq: IR - contention2'                                      , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0/1'                    );
  ~~tool_administer_schema..ins( 662, 'enq: MR - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0 or file #'                , 'type'                   );
  ~~tool_administer_schema..ins( 663, 'enq: MR - standby role transition'                          , 'Other'          , 'N', 'name|mode'                               , '0 or file #'                , 'type'                   );
  ~~tool_administer_schema..ins( 664, 'shutdown after switchover to standby'                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 665, 'parallel recovery coord wait for reply'                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 666, 'parallel recovery coord send blocked'                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 667, 'parallel recovery slave wait for change'                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 668, 'enq: BR - file shrink'                                      , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'file #'                 );
  ~~tool_administer_schema..ins( 669, 'enq: BR - proxy-copy'                                       , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'file #'                 );
  ~~tool_administer_schema..ins( 670, 'enq: BR - multi-section restore header'                     , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'file #'                 );
  ~~tool_administer_schema..ins( 671, 'enq: BR - multi-section restore section'                    , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'file #'                 );
  ~~tool_administer_schema..ins( 672, 'enq: BR - space info datafile hdr update'                   , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'file #'                 );
  ~~tool_administer_schema..ins( 673, 'enq: BR - request autobackup'                               , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'file #'                 );
  ~~tool_administer_schema..ins( 674, 'enq: BR - perform autobackup'                               , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'file #'                 );
  ~~tool_administer_schema..ins( 675, 'enq: ID - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 676, 'Backup Restore Throttle sleep'                              , 'Other'          , 'N', 'session_id'                              , 'serial'                     , ''                       );
  ~~tool_administer_schema..ins( 677, 'Backup Restore Switch Bitmap sleep'                         , 'Other'          , 'N', 'session_id'                              , 'serial'                     , ''                       );
  ~~tool_administer_schema..ins( 678, 'Backup Restore Event 19778 sleep'                           , 'Other'          , 'N', 'session_id'                              , 'serial'                     , ''                       );
  ~~tool_administer_schema..ins( 679, 'enq: AB - ABMR process start/stop'                          , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'operation parm'         );
  ~~tool_administer_schema..ins( 680, 'enq: AB - ABMR process initialized'                         , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'operation parm'         );
  ~~tool_administer_schema..ins( 681, 'Auto BMR completion'                                        , 'Other'          , 'N', 'file#'                                   , 'block#'                     , ''                       );
  ~~tool_administer_schema..ins( 682, 'Auto BMR RPC standby catchup'                               , 'Other'          , 'N', 'wrap'                                    , 'base'                       , ''                       );
  ~~tool_administer_schema..ins( 683, 'enq: MN - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'session ID'                 , '0'                      );
  ~~tool_administer_schema..ins( 684, 'enq: PL - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 685, 'enq: SB - logical standby metadata'                         , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 686, 'enq: SB - table instantiation'                              , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 687, 'Logical Standby Apply shutdown'                             , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 688, 'Logical Standby pin transaction'                            , 'Other'          , 'N', 'xidusn'                                  , 'xidslt'                     , 'xidsqn'                 );
  ~~tool_administer_schema..ins( 689, 'Logical Standby dictionary build'                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 690, 'Logical Standby Terminal Apply'                             , 'Other'          , 'N', 'stage'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 691, 'Logical Standby Debug'                                      , 'Other'          , 'N', 'event'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 692, 'Resolution of in-doubt txns'                                , 'Other'          , 'N', 'SCN'                                     , ''                           , ''                       );
  ~~tool_administer_schema..ins( 693, 'enq: XR - quiesce database'                                 , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , '0'                      );
  ~~tool_administer_schema..ins( 694, 'enq: XR - database force logging'                           , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , '0'                      );
  ~~tool_administer_schema..ins( 695, 'standby query scn advance'                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 696, 'change tracking file synchronous read'                      , 'Other'          , 'N', 'block#'                                  , 'blocks'                     , ''                       );
  ~~tool_administer_schema..ins( 697, 'change tracking file synchronous write'                     , 'Other'          , 'N', 'block#'                                  , 'blocks'                     , ''                       );
  ~~tool_administer_schema..ins( 698, 'change tracking file parallel write'                        , 'Other'          , 'N', 'blocks'                                  , 'requests'                   , ''                       );
  ~~tool_administer_schema..ins( 699, 'block change tracking buffer space'                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 700, 'CTWR media recovery checkpoint request'                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 701, 'enq: CT - global space management'                          , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'operation parm'         );
  ~~tool_administer_schema..ins( 702, 'enq: CT - local space management'                           , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'operation parm'         );
  ~~tool_administer_schema..ins( 703, 'enq: CT - change stream ownership'                          , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'operation parm'         );
  ~~tool_administer_schema..ins( 704, 'enq: CT - state'                                            , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'operation parm'         );
  ~~tool_administer_schema..ins( 705, 'enq: CT - state change gate 1'                              , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'operation parm'         );
  ~~tool_administer_schema..ins( 706, 'enq: CT - state change gate 2'                              , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'operation parm'         );
  ~~tool_administer_schema..ins( 707, 'enq: CT - CTWR process start/stop'                          , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'operation parm'         );
  ~~tool_administer_schema..ins( 708, 'enq: CT - reading'                                          , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'operation parm'         );
  ~~tool_administer_schema..ins( 709, 'recovery area: computing dropped files'                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 710, 'recovery area: computing obsolete files'                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 711, 'recovery area: computing backed up files'                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 712, 'recovery area: computing applied logs'                      , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 713, 'enq: RS - file delete'                                      , 'Other'          , 'N', 'name|mode'                               , 'record type'                , 'record id'              );
  ~~tool_administer_schema..ins( 714, 'enq: RS - record reuse'                                     , 'Other'          , 'N', 'name|mode'                               , 'record type'                , 'record id'              );
  ~~tool_administer_schema..ins( 715, 'enq: RS - prevent file delete'                              , 'Other'          , 'N', 'name|mode'                               , 'record type'                , 'record id'              );
  ~~tool_administer_schema..ins( 716, 'enq: RS - prevent aging list update'                        , 'Other'          , 'N', 'name|mode'                               , 'record type'                , 'record id'              );
  ~~tool_administer_schema..ins( 717, 'enq: RS - persist alert level'                              , 'Other'          , 'N', 'name|mode'                               , 'record type'                , 'record id'              );
  ~~tool_administer_schema..ins( 718, 'enq: RS - read alert level'                                 , 'Other'          , 'N', 'name|mode'                               , 'record type'                , 'record id'              );
  ~~tool_administer_schema..ins( 719, 'enq: RS - write alert level'                                , 'Other'          , 'N', 'name|mode'                               , 'record type'                , 'record id'              );
  ~~tool_administer_schema..ins( 720, 'enq: FL - Flashback database log'                           , 'Other'          , 'N', 'name|mode'                               , 'Log #'                      , 'zero'                   );
  ~~tool_administer_schema..ins( 721, 'enq: FL - Flashback db command'                             , 'Other'          , 'N', 'name|mode'                               , 'Log #'                      , 'zero'                   );
  ~~tool_administer_schema..ins( 722, 'enq: FD - Marker generation'                                , 'Other'          , 'N', 'name|mode'                               , 'Internal'                   , 'Internal'               );
  ~~tool_administer_schema..ins( 723, 'enq: FD - Tablespace flashback on/off'                      , 'Other'          , 'N', 'name|mode'                               , 'Internal'                   , 'Internal'               );
  ~~tool_administer_schema..ins( 724, 'enq: FD - Flashback coordinator'                            , 'Other'          , 'N', 'name|mode'                               , 'Internal'                   , 'Internal'               );
  ~~tool_administer_schema..ins( 725, 'enq: FD - Flashback on/off'                                 , 'Other'          , 'N', 'name|mode'                               , 'Internal'                   , 'Internal'               );
  ~~tool_administer_schema..ins( 726, 'enq: FD - Restore point create/drop'                        , 'Other'          , 'N', 'name|mode'                               , 'Internal'                   , 'Internal'               );
  ~~tool_administer_schema..ins( 727, 'enq: FD - Flashback logical operations'                     , 'Other'          , 'N', 'name|mode'                               , 'Internal'                   , 'Internal'               );
  ~~tool_administer_schema..ins( 728, 'flashback free VI log'                                      , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 729, 'flashback log switch'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 730, 'RVWR wait for flashback copy'                               , 'Other'          , 'N', 'copy latch #'                            , ''                           , ''                       );
  ~~tool_administer_schema..ins( 731, 'parallel recovery read buffer free'                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 732, 'parallel recovery change buffer free'                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 733, 'cell smart flash unkeep'                                    , 'Other'          , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 734, 'datafile move cleanup during resize'                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 735, 'blocking txn id for DDL'                                    , 'Other'          , 'N', 'table'                                   , 'scn'                        , 'only dml'               );
  ~~tool_administer_schema..ins( 736, 'transaction'                                                , 'Other'          , 'N', 'undo seg#|slot#'                         , 'wrap#'                      , 'count'                  );
  ~~tool_administer_schema..ins( 737, 'inactive transaction branch'                                , 'Other'          , 'N', 'branch#'                                 , 'waited'                     , ''                       );
  ~~tool_administer_schema..ins( 738, 'txn to complete'                                            , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 739, 'PMON to cleanup pseudo-branches at svc stop time'           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 740, 'PMON to cleanup detached branches at shutdown'              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 741, 'test long ops'                                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 742, 'latch: undo global data'                                    , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 743, 'undo segment recovery'                                      , 'Other'          , 'N', 'segment#'                                , 'tx flags'                   , ''                       );
  ~~tool_administer_schema..ins( 744, 'unbound tx'                                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 745, 'wait for change'                                            , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 746, 'wait for another txn - undo rcv abort'                      , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 747, 'wait for another txn - txn abort'                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 748, 'wait for another txn - rollback to savepoint'               , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 749, 'undo_retention publish retry'                               , 'Other'          , 'N', 'where'                                   , 'retry_count'                , ''                       );
  ~~tool_administer_schema..ins( 750, 'enq: TA - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'undo segment # / other' );
  ~~tool_administer_schema..ins( 751, 'enq: TX - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'usn<<16 | slot'             , 'sequence'               );
  ~~tool_administer_schema..ins( 752, 'enq: US - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'undo segment #'             , '0'                      );
  ~~tool_administer_schema..ins( 753, 'wait for stopper event to be increased'                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 754, 'wait for a undo record'                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 755, 'wait for a paralle reco to abort'                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 756, 'enq: IM - contention for blr'                               , 'Other'          , 'N', 'name|mode'                               , 'pool #'                     , '0'                      );
  ~~tool_administer_schema..ins( 757, 'enq: TD - KTF dump entries'                                 , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 758, 'enq: TE - KTF broadcast'                                    , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 759, 'enq: CN - race with txn'                                    , 'Other'          , 'N', 'name|mode'                               , 'reg id'                     , '0'                      );
  ~~tool_administer_schema..ins( 760, 'enq: CN - race with reg'                                    , 'Other'          , 'N', 'name|mode'                               , 'reg id'                     , '0'                      );
  ~~tool_administer_schema..ins( 761, 'enq: CN - race with init'                                   , 'Other'          , 'N', 'name|mode'                               , 'reg id'                     , '0'                      );
  ~~tool_administer_schema..ins( 762, 'latch: Change Notification Hash table latch'                , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 763, 'enq: CO - master slave det'                                 , 'Other'          , 'N', 'name|mode'                               , 'inst id'                    , '0'                      );
  ~~tool_administer_schema..ins( 764, 'enq: FE - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 765, 'latch: change notification client cache latch'              , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 766, 'enq: TF - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'tablespace #'               , 'relative file #'        );
  ~~tool_administer_schema..ins( 767, 'latch: lob segment hash table latch'                        , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 768, 'latch: lob segment query latch'                             , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 769, 'latch: lob segment dispenser latch'                         , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 770, 'Wait for shrink lock2'                                      , 'Other'          , 'N', 'object_id'                               , 'lock_mode'                  , ''                       );
  ~~tool_administer_schema..ins( 771, 'Wait for shrink lock'                                       , 'Other'          , 'N', 'object_id'                               , 'lock_mode'                  , ''                       );
  ~~tool_administer_schema..ins( 772, 'L1 validation'                                              , 'Other'          , 'N', 'seghdr'                                  , 'l1bmb'                      , ''                       );
  ~~tool_administer_schema..ins( 773, 'Wait for TT enqueue'                                        , 'Other'          , 'N', 'tsn'                                     , ''                           , ''                       );
  ~~tool_administer_schema..ins( 774, 'kttm2d'                                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 775, 'ktsambl'                                                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 776, 'ktfbtgex'                                                   , 'Other'          , 'N', 'tsn'                                     , ''                           , ''                       );
  ~~tool_administer_schema..ins( 777, 'enq: DT - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 778, 'enq: TS - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'tablespace ID'              , 'dba'                    );
  ~~tool_administer_schema..ins( 779, 'enq: FB - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'tablespace #'               , 'dba'                    );
  ~~tool_administer_schema..ins( 780, 'enq: SK - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'tablespace #'               , 'dba'                    );
  ~~tool_administer_schema..ins( 781, 'enq: DW - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'tablespace #'               , 'dba'                    );
  ~~tool_administer_schema..ins( 782, 'enq: SU - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'table space #'              , '0'                      );
  ~~tool_administer_schema..ins( 783, 'enq: TT - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'tablespace ID'              , 'operation'              );
  ~~tool_administer_schema..ins( 784, 'ktm: instance recovery'                                     , 'Other'          , 'N', 'undo segment#'                           , ''                           , ''                       );
  ~~tool_administer_schema..ins( 785, 'instance state change'                                      , 'Other'          , 'N', 'layer'                                   , 'value'                      , 'waited'                 );
  ~~tool_administer_schema..ins( 786, 'enq: SJ - Slave Task Cancel'                                , 'Other'          , 'N', 'name|mode'                               , 'Slave process id'           , 'task id'                );
  ~~tool_administer_schema..ins( 787, 'Space Manager: slave messages'                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 788, 'index block split'                                          , 'Other'          , 'N', 'rootdba'                                 , 'level'                      , 'childdba'               );
  ~~tool_administer_schema..ins( 789, 'kdblil wait before retrying ORA-54'                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 790, 'dupl. cluster key'                                          , 'Other'          , 'N', 'dba'                                     , ''                           , ''                       );
  ~~tool_administer_schema..ins( 791, 'kdic_do_merge'                                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 792, 'enq: DL - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 793, 'enq: HQ - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , 'hash value'             );
  ~~tool_administer_schema..ins( 794, 'enq: HP - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'tablespace #'               , 'dba'                    );
  ~~tool_administer_schema..ins( 795, 'enq: WG - delete fso'                                       , 'Other'          , 'N', 'name|mode'                               , 'kdlw lobid first half'      , 'kdlw lobid sec half'    );
  ~~tool_administer_schema..ins( 796, 'enq: SL - get lock'                                         , 'Other'          , 'N', 'name|mode'                               , 'kdlw lobid first half'      , 'kdlw lobid sec half'    );
  ~~tool_administer_schema..ins( 797, 'enq: SL - escalate lock'                                    , 'Other'          , 'N', 'name|mode'                               , 'kdlw lobid first half'      , 'kdlw lobid sec half'    );
  ~~tool_administer_schema..ins( 798, 'enq: SL - get lock for undo'                                , 'Other'          , 'N', 'name|mode'                               , 'kdlw lobid first half'      , 'kdlw lobid sec half'    );
  ~~tool_administer_schema..ins( 799, 'enq: ZH - compression analysis'                             , 'Other'          , 'N', 'name|mode'                               , 'obj#'                       , 'ulevel'                 );
  ~~tool_administer_schema..ins( 800, 'Compression analysis'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 801, 'row cache cleanup'                                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 802, 'row cache process'                                          , 'Other'          , 'N', 'location'                                , ''                           , ''                       );
  ~~tool_administer_schema..ins( 803, 'enq: DV - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 804, 'enq: SO - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 805, 'enq: TP - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 806, 'enq: RW - MV metadata contention'                           , 'Other'          , 'N', 'name|mode'                               , 'table obj#'                 , '0'                      );
  ~~tool_administer_schema..ins( 807, 'enq: OC - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '1'                          , '2'                      );
  ~~tool_administer_schema..ins( 808, 'enq: OL - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'hash value'                 , '0'                      );
  ~~tool_administer_schema..ins( 809, 'kkdlgon'                                                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 810, 'kkdlsipon'                                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 811, 'kkdlhpon'                                                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 812, 'kgltwait'                                                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 813, 'kksfbc research'                                            , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 814, 'kksscl hash split'                                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 815, 'kksfbc child completion'                                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 816, 'enq: CU - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'handle'                     , 'handle'                 );
  ~~tool_administer_schema..ins( 817, 'enq: AE - lock'                                             , 'Other'          , 'N', 'name|mode'                               , 'edition obj#'               , '0'                      );
  ~~tool_administer_schema..ins( 818, 'enq: PF - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 819, 'enq: IL - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 820, 'enq: CL - drop label'                                       , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 821, 'enq: CL - compare labels'                                   , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 822, 'enq: MK - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 823, 'enq: OW - initialization'                                   , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 824, 'enq: OW - termination'                                      , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 825, 'enq: RK - set key'                                          , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 826, 'enq: RL - RAC wallet lock'                                  , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 827, 'enq: ZZ - update hash tables'                               , 'Other'          , 'N', 'name|mode'                               , 'KSBXIC Action'              , '0'                      );
  ~~tool_administer_schema..ins( 828, 'enq: ZA - add std audit table partition'                    , 'Other'          , 'N', 'name|mode'                               , 'KZAM Aud Partition'         , '0'                      );
  ~~tool_administer_schema..ins( 829, 'enq: ZF - add fga audit table partition'                    , 'Other'          , 'N', 'name|mode'                               , 'KZAM Fga Partition'         , '0'                      );
  ~~tool_administer_schema..ins( 830, 'enq: DX - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'transaction entry #'        , '0'                      );
  ~~tool_administer_schema..ins( 831, 'enq: DR - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 832, 'pending global transaction(s)'                              , 'Other'          , 'N', 'scans'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 833, 'free global transaction table entry'                        , 'Other'          , 'N', 'tries'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 834, 'library cache revalidation'                                 , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 835, 'library cache shutdown'                                     , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 836, 'BFILE closure'                                              , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 837, 'BFILE check if exists'                                      , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 838, 'BFILE check if open'                                        , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 839, 'BFILE get length'                                           , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 840, 'BFILE get name object'                                      , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 841, 'BFILE get path object'                                      , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 842, 'BFILE open'                                                 , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 843, 'BFILE internal seek'                                        , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 844, 'waiting to get CAS latch'                                   , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 845, 'waiting to get RM CAS latch'                                , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 846, 'resmgr:internal state cleanup'                              , 'Other'          , 'N', 'location'                                , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 847, 'xdb schema cache initialization'                            , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 848, 'ASM cluster file access'                                    , 'Other'          , 'N', 'lock'                                    , 'mode'                       , ''                       );
  ~~tool_administer_schema..ins( 849, 'CSS initialization'                                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 850, 'CSS group registration'                                     , 'Other'          , 'N', 'group_name1'                             , 'group_name2'                , 'mem_id'                 );
  ~~tool_administer_schema..ins( 851, 'CSS group membership query'                                 , 'Other'          , 'N', 'group_name1'                             , 'group_name2'                , 'group_name3'            );
  ~~tool_administer_schema..ins( 852, 'CSS operation: data query'                                  , 'Other'          , 'N', 'function_id'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 853, 'CSS operation: data update'                                 , 'Other'          , 'N', 'function_id'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 854, 'CSS Xgrp shared operation'                                  , 'Other'          , 'N', 'function_id'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 855, 'CSS operation: query'                                       , 'Other'          , 'N', 'function_id'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 856, 'CSS operation: action'                                      , 'Other'          , 'N', 'function_id'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 857, 'CSS operation: diagnostic'                                  , 'Other'          , 'N', 'function_id'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 858, 'GIPC operation: dump'                                       , 'Other'          , 'N', 'function_id'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 859, 'GPnP Initialization'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 860, 'GPnP Termination'                                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 861, 'GPnP Get Item'                                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 862, 'GPnP Set Item'                                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 863, 'GPnP Get Error'                                             , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 864, 'ADR file lock'                                              , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 865, 'ADR block file read'                                        , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 866, 'ADR block file write'                                       , 'Other'          , 'N', ' '                                       , ' '                          , ' '                      );
  ~~tool_administer_schema..ins( 867, 'CRS call completion'                                        , 'Other'          , 'N', 'clsrrestype'                             , 'kjha_action'                , ''                       );
  ~~tool_administer_schema..ins( 868, 'dispatcher shutdown'                                        , 'Other'          , 'N', 'waited'                                  , ''                           , ''                       );
  ~~tool_administer_schema..ins( 869, 'listener registration dump'                                 , 'Other'          , 'N', 'dump'                                    , ''                           , ''                       );
  ~~tool_administer_schema..ins( 870, 'latch: virtual circuit queues'                              , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 871, 'listen endpoint status'                                     , 'Other'          , 'N', 'end-point#'                              , 'status'                     , ''                       );
  ~~tool_administer_schema..ins( 872, 'OJVM: Generic'                                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 873, 'select wait'                                                , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 874, 'jobq slave shutdown wait'                                   , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 875, 'jobq slave TJ process wait'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 876, 'job scheduler coordinator slave wait'                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 877, 'enq: JD - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 878, 'enq: JQ - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 879, 'enq: OD - Serializing DDLs'                                 , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 880, 'kkshgnc reloop'                                             , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 881, 'optimizer stats update retry'                               , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 882, 'wait active processes'                                      , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 883, 'SUPLOG PL wait for inflight pragma-d PL/SQL'                , 'Other'          , 'N', 'session_num'                             , ''                           , ''                       );
  ~~tool_administer_schema..ins( 884, 'enq: MD - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'master object #'            , '0'                      );
  ~~tool_administer_schema..ins( 885, 'enq: MS - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'master object #'            , '0'                      );
  ~~tool_administer_schema..ins( 886, 'wait for kkpo ref-partitioning *TEST EVENT*'                , 'Other'          , 'N', 'where'                                   , ''                           , ''                       );
  ~~tool_administer_schema..ins( 887, 'enq: AP - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 888, 'PX slave connection'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 889, 'PX slave release'                                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 890, 'PX Send Wait'                                               , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 891, 'PX qref latch'                                              , 'Other'          , 'N', 'function'                                , 'sleeptime'                  , 'qref'                   );
  ~~tool_administer_schema..ins( 892, 'PX server shutdown'                                         , 'Other'          , 'N', 'nalive'                                  , 'sleeptime'                  , 'loop'                   );
  ~~tool_administer_schema..ins( 893, 'PX create server'                                           , 'Other'          , 'N', 'nservers'                                , 'sleeptime'                  , 'enqueue'                );
  ~~tool_administer_schema..ins( 894, 'PX signal server'                                           , 'Other'          , 'N', 'serial'                                  , 'error'                      , 'nbusy'                  );
  ~~tool_administer_schema..ins( 895, 'PX Deq Credit: free buffer'                                 , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , 'qref'                   );
  ~~tool_administer_schema..ins( 896, 'PX Deq: Test for msg'                                       , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 897, 'PX Deq: Test for credit'                                    , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 898, 'PX Deq: Signal ACK RSG'                                     , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 899, 'PX Deq: Signal ACK EXT'                                     , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 900, 'PX Deq: reap credit'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 901, 'PX Nsq: PQ descriptor query'                                , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 902, 'PX Nsq: PQ load info query'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 903, 'PX Deq Credit: Session Stats'                               , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 904, 'PX Deq: Slave Session Stats'                                , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 905, 'PX Deq: Slave Join Frag'                                    , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 906, 'enq: PI - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'serial #'               );
  ~~tool_administer_schema..ins( 907, 'enq: PS - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'instance'                   , 'slave ID'               );
  ~~tool_administer_schema..ins( 908, 'latch: parallel query alloc buffer'                         , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 909, 'kxfxse'                                                     , 'Other'          , 'N', 'kxfxse debug wait: stalling for slave 0' , ''                           , ''                       );
  ~~tool_administer_schema..ins( 910, 'kxfxsp'                                                     , 'Other'          , 'N', 'kxfxsp debug wait: stalling for slave 0' , ''                           , ''                       );
  ~~tool_administer_schema..ins( 911, 'PX Deq: Table Q qref'                                       , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 912, 'PX Deq: Table Q Get Keys'                                   , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 913, 'PX Deq: Table Q Close'                                      , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 914, 'GV$: slave acquisition retry wait time'                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 915, 'PX hash elem being inserted'                                , 'Other'          , 'N', 'hashid'                                  , 'element'                    , 'insert/update'          );
  ~~tool_administer_schema..ins( 916, 'latch: PX hash array latch'                                 , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins( 917, 'enq: AY - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'Op1'                        , 'Op2'                    );
  ~~tool_administer_schema..ins( 918, 'enq: TO - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , '1'                      );
  ~~tool_administer_schema..ins( 919, 'enq: IT - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 920, 'enq: BF - allocation contention'                            , 'Other'          , 'N', 'name|mode'                               , 'node#/parallelizer#'        , 'bloom#'                 );
  ~~tool_administer_schema..ins( 921, 'enq: BF - PMON Join Filter cleanup'                         , 'Other'          , 'N', 'name|mode'                               , 'node#/parallelizer#'        , 'bloom#'                 );
  ~~tool_administer_schema..ins( 922, 'enq: RD - RAC load'                                         , 'Other'          , 'N', 'name|mode'                               , 'sqlid'                      , 'execid'                 );
  ~~tool_administer_schema..ins( 923, 'kupp process wait'                                          , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 924, 'Kupp process shutdown'                                      , 'Other'          , 'N', 'nalive'                                  , 'sleeptime'                  , 'loop'                   );
  ~~tool_administer_schema..ins( 925, 'Data Pump slave startup'                                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 926, 'Data Pump slave init'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 927, 'enq: KP - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 928, 'Replication Dequeue '                                       , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 929, 'knpc_acwm_AwaitChangedWaterMark'                            , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 930, 'knpc_anq_AwaitNonemptyQueue'                                , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 931, 'knpsmai'                                                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 932, 'enq: SR - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'sequence # / apply #'   );
  ~~tool_administer_schema..ins( 933, 'Streams capture: waiting for database startup'              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 934, 'Streams miscellaneous event'                                , 'Other'          , 'N', 'TYPE'                                    , ''                           , ''                       );
  ~~tool_administer_schema..ins( 935, 'enq: SI - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'object #'                   , '0'                      );
  ~~tool_administer_schema..ins( 936, 'Streams: RAC waiting for inter instance ack'                , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 937, 'enq: IA - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 938, 'enq: JI - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'view object #'              , '0'                      );
  ~~tool_administer_schema..ins( 939, 'qerex_gdml'                                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 940, 'enq: AT - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 941, 'opishd'                                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 942, 'kpodplck wait before retrying ORA-54'                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 943, 'enq: CQ - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 944, 'Streams AQ: emn coordinator waiting for slave to start'     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 945, 'wait for EMON to spawn'                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 946, 'EMON termination'                                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 947, 'EMON slave messages'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 948, 'enq: SE - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'Session-id'                 , 'Serial#'                );
  ~~tool_administer_schema..ins( 949, 'tsm with timeout'                                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 950, 'Streams AQ: waiting for busy instance for instance_name'    , 'Other'          , 'N', 'where'                                   , 'wait_count'                 , ''                       );
  ~~tool_administer_schema..ins( 951, 'enq: TQ - TM contention'                                    , 'Other'          , 'N', 'name|mode'                               , 'QT_OBJ#'                    , '0'                      );
  ~~tool_administer_schema..ins( 952, 'enq: TQ - DDL contention'                                   , 'Other'          , 'N', 'name|mode'                               , 'QT_OBJ#'                    , '0'                      );
  ~~tool_administer_schema..ins( 953, 'enq: TQ - INI contention'                                   , 'Other'          , 'N', 'name|mode'                               , 'QT_OBJ#'                    , '0'                      );
  ~~tool_administer_schema..ins( 954, 'enq: TQ - DDL-INI contention'                               , 'Other'          , 'N', 'name|mode'                               , 'QT_OBJ#'                    , '0'                      );
  ~~tool_administer_schema..ins( 955, 'AQ propagation connection'                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 956, 'enq: DP - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 957, 'enq: MH - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 958, 'enq: ML - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 959, 'enq: PH - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 960, 'enq: SF - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 961, 'enq: XH - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 962, 'enq: WA - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 963, 'Streams AQ: QueueTable kgl locks'                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 964, 'AQ spill debug idle'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 965, 'queue slave messages'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 966, 'Streams AQ: qmn coordinator waiting for slave to start'     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 967, 'enq: CX - TEXT: Index Specific Lock'                        , 'Other'          , 'N', 'name|mode'                               , 'Index Id'                   , 'Partition Id'           );
  ~~tool_administer_schema..ins( 968, 'enq: OT - TEXT: Generic Lock'                               , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins( 969, 'XDB SGA initialization'                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 970, 'enq: XC - XDB Configuration'                                , 'Other'          , 'N', 'name|mode'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins( 971, 'NFS read delegation outstanding'                            , 'Other'          , 'N', 'delegation count'                        , ''                           , ''                       );
  ~~tool_administer_schema..ins( 972, 'Data Guard Broker Wait'                                     , 'Other'          , 'N', 'Broker Component'                        , 'Wait Argument 1'            , 'Wait Argument 2'        );
  ~~tool_administer_schema..ins( 973, 'enq: RF - synch: DG Broker metadata'                        , 'Other'          , 'N', 'name|mode'                               , 'lock operation'             , 'lock value'             );
  ~~tool_administer_schema..ins( 974, 'enq: RF - atomicity'                                        , 'Other'          , 'N', 'name|mode'                               , 'lock operation'             , 'lock value'             );
  ~~tool_administer_schema..ins( 975, 'enq: RF - synchronization: aifo master'                     , 'Other'          , 'N', 'name|mode'                               , 'lock operation'             , 'lock value'             );
  ~~tool_administer_schema..ins( 976, 'enq: RF - new AI'                                           , 'Other'          , 'N', 'name|mode'                               , 'lock operation'             , 'lock value'             );
  ~~tool_administer_schema..ins( 977, 'enq: RF - synchronization: critical ai'                     , 'Other'          , 'N', 'name|mode'                               , 'lock operation'             , 'lock value'             );
  ~~tool_administer_schema..ins( 978, 'enq: RF - RF - Database Automatic Disable'                  , 'Other'          , 'N', 'name|mode'                               , 'lock operation'             , 'lock value'             );
  ~~tool_administer_schema..ins( 979, 'enq: RF - FSFO Observer Heartbeat'                          , 'Other'          , 'N', 'name|mode'                               , 'lock operation'             , 'lock value'             );
  ~~tool_administer_schema..ins( 980, 'enq: RF - DG Broker Current File ID'                        , 'Other'          , 'N', 'name|mode'                               , 'lock operation'             , 'lock value'             );
  ~~tool_administer_schema..ins( 981, 'enq: RF - FSFO Primary Shutdown suspended'                  , 'Other'          , 'N', 'name|mode'                               , 'lock operation'             , 'lock value'             );
  ~~tool_administer_schema..ins( 982, 'PX Deq: OLAP Update Reply'                                  , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 983, 'PX Deq: OLAP Update Execute'                                , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 984, 'PX Deq: OLAP Update Close'                                  , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 985, 'OLAP Parallel Type Deq'                                     , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 986, 'OLAP Parallel Temp Grow Request'                            , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 987, 'OLAP Parallel Temp Grow Wait'                               , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 988, 'OLAP Parallel Temp Grew'                                    , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 989, 'OLAP Null PQ Reason'                                        , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 990, 'OLAP Aggregate Master Enq'                                  , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 991, 'OLAP Aggregate Client Enq'                                  , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 992, 'OLAP Aggregate Master Deq'                                  , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 993, 'OLAP Aggregate Client Deq'                                  , 'Other'          , 'N', 'sleeptime/senderid'                      , 'passes'                     , ''                       );
  ~~tool_administer_schema..ins( 994, 'enq: AW - AW$ table lock'                                   , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'workspace #'            );
  ~~tool_administer_schema..ins( 995, 'enq: AW - AW state lock'                                    , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'workspace #'            );
  ~~tool_administer_schema..ins( 996, 'enq: AW - user access for AW'                               , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'workspace #'            );
  ~~tool_administer_schema..ins( 997, 'enq: AW - AW generation lock'                               , 'Other'          , 'N', 'name|mode'                               , 'operation'                  , 'workspace #'            );
  ~~tool_administer_schema..ins( 998, 'enq: AG - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'workspace #'                , 'generation'             );
  ~~tool_administer_schema..ins( 999, 'enq: AO - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'workspace #'                , 'object #'               );
  ~~tool_administer_schema..ins(1000, 'enq: OQ - xsoqhiAlloc'                                      , 'Other'          , 'N', 'name|mode'                               , 'resource id'                , '0'                      );
  ~~tool_administer_schema..ins(1001, 'enq: OQ - xsoqhiFlush'                                      , 'Other'          , 'N', 'name|mode'                               , 'resource id'                , '0'                      );
  ~~tool_administer_schema..ins(1002, 'enq: OQ - xsoq*histrecb'                                    , 'Other'          , 'N', 'name|mode'                               , 'resource id'                , '0'                      );
  ~~tool_administer_schema..ins(1003, 'enq: OQ - xsoqhiClose'                                      , 'Other'          , 'N', 'name|mode'                               , 'resource id'                , '0'                      );
  ~~tool_administer_schema..ins(1004, 'enq: OQ - xsoqhistrecb'                                     , 'Other'          , 'N', 'name|mode'                               , 'resource id'                , '0'                      );
  ~~tool_administer_schema..ins(1005, 'enq: AM - client registration'                              , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1006, 'enq: AM - shutdown'                                         , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1007, 'enq: AM - rollback COD reservation'                         , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1008, 'enq: AM - background COD reservation'                       , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1009, 'enq: AM - ASM cache freeze'                                 , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1010, 'enq: AM - ASM ACD Relocation'                               , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1011, 'enq: AM - group use'                                        , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1012, 'enq: AM - group block'                                      , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1013, 'enq: AM - ASM File Destroy'                                 , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1014, 'enq: AM - ASM User'                                         , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1015, 'enq: AM - ASM Password File Update'                         , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1016, 'enq: AM - ASM Amdu Dump'                                    , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1017, 'enq: AM - disk offline'                                     , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1018, 'enq: AM - ASM reserved'                                     , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1019, 'enq: AM - block repair'                                     , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1020, 'enq: AM - ASM disk based alloc/dealloc'                     , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1021, 'enq: AM - ASM file descriptor'                              , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1022, 'enq: AM - ASM file relocation'                              , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1023, 'enq: AM - ASM Grow ACD'                                     , 'Other'          , 'N', 'name|mode'                               , 'id1'                        , 'id2'                    );
  ~~tool_administer_schema..ins(1024, 'ASM internal hang test'                                     , 'Other'          , 'N', 'test #'                                  , ''                           , ''                       );
  ~~tool_administer_schema..ins(1025, 'ASM Instance startup'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1026, 'buffer busy'                                                , 'Other'          , 'N', 'group#'                                  , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1027, 'buffer freelistbusy'                                        , 'Other'          , 'N', 'group#'                                  , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1028, 'buffer rememberlist busy'                                   , 'Other'          , 'N', 'group#'                                  , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1029, 'buffer writeList full'                                      , 'Other'          , 'N', 'group#'                                  , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1030, 'no free buffers'                                            , 'Other'          , 'N', 'group#'                                  , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1031, 'buffer write wait'                                          , 'Other'          , 'N', 'group#'                                  , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1032, 'buffer invalidation wait'                                   , 'Other'          , 'N', 'group#'                                  , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1033, 'buffer dirty disabled'                                      , 'Other'          , 'N', 'group#'                                  , ''                           , ''                       );
  ~~tool_administer_schema..ins(1034, 'ASM metadata cache frozen'                                  , 'Other'          , 'N', 'group#'                                  , ''                           , ''                       );
  ~~tool_administer_schema..ins(1035, 'enq: CM - gate'                                             , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'type'                   );
  ~~tool_administer_schema..ins(1036, 'enq: CM - instance'                                         , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'type'                   );
  ~~tool_administer_schema..ins(1037, 'enq: CM - diskgroup dismount'                               , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'type'                   );
  ~~tool_administer_schema..ins(1038, 'enq: XQ - recovery'                                         , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'unused'                 );
  ~~tool_administer_schema..ins(1039, 'enq: XQ - relocation'                                       , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'unused'                 );
  ~~tool_administer_schema..ins(1040, 'enq: XQ - purification'                                     , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'unused'                 );
  ~~tool_administer_schema..ins(1041, 'enq: AD - allocate AU'                                      , 'Other'          , 'N', 'name|mode'                               , 'group and disk number'      , 'AU number'              );
  ~~tool_administer_schema..ins(1042, 'enq: AD - deallocate AU'                                    , 'Other'          , 'N', 'name|mode'                               , 'group and disk number'      , 'AU number'              );
  ~~tool_administer_schema..ins(1043, 'enq: AD - relocate AU'                                      , 'Other'          , 'N', 'name|mode'                               , 'group and disk number'      , 'AU number'              );
  ~~tool_administer_schema..ins(1044, 'enq: DO - disk online'                                      , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'disk #'                 );
  ~~tool_administer_schema..ins(1045, 'enq: DO - disk online recovery'                             , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'disk #'                 );
  ~~tool_administer_schema..ins(1046, 'enq: DO - Staleness Registry create'                        , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'disk #'                 );
  ~~tool_administer_schema..ins(1047, 'enq: DO - startup of MARK process'                          , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'disk #'                 );
  ~~tool_administer_schema..ins(1048, 'enq: DO - disk online operation'                            , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'disk #'                 );
  ~~tool_administer_schema..ins(1049, 'extent map load/unlock'                                     , 'Other'          , 'N', 'group'                                   , 'file'                       , 'extent'                 );
  ~~tool_administer_schema..ins(1050, 'enq: XL - fault extent map'                                 , 'Other'          , 'N', 'name|mode'                               , 'map id'                     , 'nothing'                );
  ~~tool_administer_schema..ins(1051, 'Sync ASM rebalance'                                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1052, 'enq: DG - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'type'                   );
  ~~tool_administer_schema..ins(1053, 'enq: DD - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'type'                   );
  ~~tool_administer_schema..ins(1054, 'enq: HD - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , '0'                      );
  ~~tool_administer_schema..ins(1055, 'enq: DN - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins(1056, 'Cluster stabilization wait'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1057, 'Cluster Suspension wait'                                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1058, 'ASM background starting'                                    , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1059, 'ASM db client exists'                                       , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1060, 'ASM file metadata operation'                                , 'Other'          , 'N', 'msgop'                                   , 'locn'                       , ''                       );
  ~~tool_administer_schema..ins(1061, 'ASM network foreground exits'                               , 'Other'          , 'N', 'group#'                                  , ''                           , ''                       );
  ~~tool_administer_schema..ins(1062, 'enq: FA - access file'                                      , 'Other'          , 'N', 'name|mode'                               , 'disk group number'          , 'file number'            );
  ~~tool_administer_schema..ins(1063, 'enq: RX - relocate extent'                                  , 'Other'          , 'N', 'name|mode'                               , 'disk group #:file #'        , 'virtual extent number'  );
  ~~tool_administer_schema..ins(1064, 'enq: RX - unlock extent'                                    , 'Other'          , 'N', 'name|mode'                               , 'disk group #:file #'        , 'virtual extent number'  );
  ~~tool_administer_schema..ins(1065, 'log write(odd)'                                             , 'Other'          , 'N', 'group#'                                  , ''                           , ''                       );
  ~~tool_administer_schema..ins(1066, 'log write(even)'                                            , 'Other'          , 'N', 'group#'                                  , ''                           , ''                       );
  ~~tool_administer_schema..ins(1067, 'checkpoint advanced'                                        , 'Other'          , 'N', 'group#'                                  , ''                           , ''                       );
  ~~tool_administer_schema..ins(1068, 'enq: FR - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'thread'                 );
  ~~tool_administer_schema..ins(1069, 'enq: FR - use the thread'                                   , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'thread'                 );
  ~~tool_administer_schema..ins(1070, 'enq: FR - recover the thread'                               , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'thread'                 );
  ~~tool_administer_schema..ins(1071, 'enq: FG - serialize ACD relocate'                           , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'type'                   );
  ~~tool_administer_schema..ins(1072, 'enq: FG - FG redo generation enq race'                      , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'type'                   );
  ~~tool_administer_schema..ins(1073, 'enq: FG - LGWR redo generation enq race'                    , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'type'                   );
  ~~tool_administer_schema..ins(1074, 'enq: FT - allow LGWR writes'                                , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'thread'                 );
  ~~tool_administer_schema..ins(1075, 'enq: FT - disable LGWR writes'                              , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'thread'                 );
  ~~tool_administer_schema..ins(1076, 'enq: FC - open an ACD thread'                               , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'thread'                 );
  ~~tool_administer_schema..ins(1077, 'enq: FC - recover an ACD thread'                            , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'thread'                 );
  ~~tool_administer_schema..ins(1078, 'enq: FX - issue ACD Xtnt Relocation CIC'                    , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , 'unused'                 );
  ~~tool_administer_schema..ins(1079, 'rollback operations block full'                             , 'Other'          , 'N', 'max operations'                          , ''                           , ''                       );
  ~~tool_administer_schema..ins(1080, 'rollback operations active'                                 , 'Other'          , 'N', 'operation count'                         , ''                           , ''                       );
  ~~tool_administer_schema..ins(1081, 'enq: RB - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'disk group'                 , '0'                      );
  ~~tool_administer_schema..ins(1082, 'ASM: MARK subscribe to msg channel'                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1083, 'enq: PT - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'disk group #'               , 'type'                   );
  ~~tool_administer_schema..ins(1084, 'ASM PST operation'                                          , 'Other'          , 'N', 'op'                                      , ''                           , ''                       );
  ~~tool_administer_schema..ins(1085, 'global cache busy'                                          , 'Other'          , 'N', 'group'                                   , 'file#'                      , 'block#'                 );
  ~~tool_administer_schema..ins(1086, 'lock release pending'                                       , 'Other'          , 'N', 'group'                                   , 'file#'                      , 'block#'                 );
  ~~tool_administer_schema..ins(1087, 'dma prepare busy'                                           , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1088, 'GCS lock cancel'                                            , 'Other'          , 'N', 'le'                                      , ''                           , ''                       );
  ~~tool_administer_schema..ins(1089, 'GCS lock open S'                                            , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1090, 'GCS lock open X'                                            , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1091, 'GCS lock open'                                              , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1092, 'GCS lock cvt S'                                             , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1093, 'GCS lock cvt X'                                             , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1094, 'GCS lock esc X'                                             , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1095, 'GCS lock esc'                                               , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1096, 'GCS recovery lock open'                                     , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1097, 'GCS recovery lock convert'                                  , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1098, 'kfcl: instance recovery'                                    , 'Other'          , 'N', 'group'                                   , 'obj#'                       , 'block#'                 );
  ~~tool_administer_schema..ins(1099, 'no free locks'                                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1100, 'lock close'                                                 , 'Other'          , 'N', 'group'                                   , 'lms#'                       , ''                       );
  ~~tool_administer_schema..ins(1101, 'enq: KQ - access ASM attribute'                             , 'Other'          , 'N', 'name|mode'                               , 'group'                      , 'entry'                  );
  ~~tool_administer_schema..ins(1102, 'ASM Volume Background'                                      , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1103, 'ASM DG Unblock'                                             , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1104, 'enq: AV - persistent DG number'                             , 'Other'          , 'N', 'name|mode'                               , 'persistent DG number'       , 'non-DG number enqs'     );
  ~~tool_administer_schema..ins(1105, 'enq: AV - volume relocate'                                  , 'Other'          , 'N', 'name|mode'                               , 'persistent DG number'       , 'non-DG number enqs'     );
  ~~tool_administer_schema..ins(1106, 'enq: AV - AVD client registration'                          , 'Other'          , 'N', 'name|mode'                               , 'persistent DG number'       , 'non-DG number enqs'     );
  ~~tool_administer_schema..ins(1107, 'enq: AV - add/enable first volume in DG'                    , 'Other'          , 'N', 'name|mode'                               , 'persistent DG number'       , 'non-DG number enqs'     );
  ~~tool_administer_schema..ins(1108, 'ASM: OFS Cluster membership update'                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1109, 'enq: WF - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins(1110, 'enq: WP - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins(1111, 'enq: FU - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins(1112, 'enq: MW - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'Schedule Id'                , '0'                      );
  ~~tool_administer_schema..ins(1113, 'AWR Flush'                                                  , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1114, 'AWR Metric Capture'                                         , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1115, 'enq: TB - SQL Tuning Base Cache Update'                     , 'Other'          , 'N', 'name|mode'                               , '1'                          , '2'                      );
  ~~tool_administer_schema..ins(1116, 'enq: TB - SQL Tuning Base Cache Load'                       , 'Other'          , 'N', 'name|mode'                               , '1'                          , '2'                      );
  ~~tool_administer_schema..ins(1117, 'enq: SH - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins(1118, 'enq: AF - task serialization'                               , 'Other'          , 'N', 'name|mode'                               , 'task id'                    , '0'                      );
  ~~tool_administer_schema..ins(1119, 'MMON slave messages'                                        , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1120, 'MMON (Lite) shutdown'                                       , 'Other'          , 'N', 'process#'                                , 'waited'                     , ''                       );
  ~~tool_administer_schema..ins(1121, 'enq: MO - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins(1122, 'enq: TL - contention'                                       , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins(1123, 'enq: TH - metric threshold evaluation'                      , 'Other'          , 'N', 'name|mode'                               , '0'                          , '0'                      );
  ~~tool_administer_schema..ins(1124, 'enq: TK - Auto Task Serialization'                          , 'Other'          , 'N', 'name|mode'                               , '0-MMON, 1-MMON Slave'       , '0'                      );
  ~~tool_administer_schema..ins(1125, 'enq: TK - Auto Task Slave Lockout'                          , 'Other'          , 'N', 'name|mode'                               , '0-MMON, 1-MMON Slave'       , '0'                      );
  ~~tool_administer_schema..ins(1126, 'enq: RR - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'lock#'                      , 'not used'               );
  ~~tool_administer_schema..ins(1127, 'WCR: RAC message context busy'                              , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1128, 'WCR: capture file IO write'                                 , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1129, 'WCR: Sync context busy'                                     , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1130, 'latch: WCR: sync'                                           , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins(1131, 'latch: WCR: processes HT'                                   , 'Other'          , 'N', 'address'                                 , 'number'                     , 'tries'                  );
  ~~tool_administer_schema..ins(1132, 'enq: JS - contention'                                       , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1133, 'enq: JS - job run lock - synchronize'                       , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1134, 'enq: JS - job recov lock'                                   , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1135, 'enq: JS - queue lock'                                       , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1136, 'enq: JS - sch locl enqs'                                    , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1137, 'enq: JS - q mem clnup lck'                                  , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1138, 'enq: JS - evtsub add'                                       , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1139, 'enq: JS - evtsub drop'                                      , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1140, 'enq: JS - wdw op'                                           , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1141, 'enq: JS - evt notify'                                       , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1142, 'enq: JS - aq sync'                                          , 'Other'          , 'N', 'name|mode'                               , 'service ID'                 , 'queue type'             );
  ~~tool_administer_schema..ins(1143, 'enq: XD - ASM disk drop/add'                                , 'Other'          , 'N', 'name|mode'                               , 'opcode'                     , 'notused'                );
  ~~tool_administer_schema..ins(1144, 'enq: XD - ASM disk ONLINE'                                  , 'Other'          , 'N', 'name|mode'                               , 'opcode'                     , 'notused'                );
  ~~tool_administer_schema..ins(1145, 'enq: XD - ASM disk OFFLINE'                                 , 'Other'          , 'N', 'name|mode'                               , 'opcode'                     , 'notused'                );
  ~~tool_administer_schema..ins(1146, 'cell worker online completion'                              , 'Other'          , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins(1147, 'cell worker retry '                                         , 'Other'          , 'N', 'cellhash#'                               , ''                           , ''                       );
  ~~tool_administer_schema..ins(1148, 'cell manager cancel work request'                           , 'Other'          , 'N', ''                                        , ''                           , ''                       );
  ~~tool_administer_schema..ins(1149, 'secondary event'                                            , 'Other'          , 'N', 'event #'                                 , 'wait time'                  , ''                       );
END;
/
SET DEF ON;

DROP PROCEDURE &&tool_administer_schema..ins;

/* ------------------------------------------------------------------------- */

-- one row per execution of the Trace Analyzer
CREATE TABLE &&tool_repository_schema..trca$_tool_execution (
  id                          INTEGER        NOT NULL, -- pk trca$_tool_execution_id_s
  file_name                   VARCHAR2(4000),          -- trace or control text file
  directory_alias             VARCHAR2(257),            -- fk dba_directories.directory_name
  directory_path              VARCHAR2(4000),          -- input directory path
  parse_start                 DATE,
  parse_end                   DATE,
  file_count                  INTEGER,
  file_bytes                  INTEGER,
  start_tim                   INTEGER,                 -- first tim in file(s)
  end_tim                     INTEGER,                 -- last tim in file(s)
  dep                         INTEGER,                 -- max recursive depth
  accounted_for_response_time INTEGER,                 -- total for all file(s)
  elapsed_time                INTEGER,                 -- total for all file(s)
  cpu_time                    INTEGER,                 -- total for all file(s)
  log_file_name               VARCHAR2(4000),
  html_file_name              VARCHAR2(4000),
  text_file_name              VARCHAR2(4000)
);

GRANT ALL ON &&tool_repository_schema..trca$_tool_execution TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_tool_execution FOR &&tool_repository_schema..trca$_tool_execution;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_tool_execution_pk ON &&tool_repository_schema..trca$_tool_execution(id);
ALTER TABLE &&tool_repository_schema..trca$_tool_execution ADD (CONSTRAINT trca$_tool_execution_pk PRIMARY KEY (id));

GRANT SELECT ON &&tool_repository_schema..trca$_tool_execution TO &&role_name.;

/* ------------------------------------------------------------------------- */

-- one row per file created by Trace Analyzer
CREATE TABLE &&tool_repository_schema..trca$_file (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  file_type                  VARCHAR2(24),            -- HTML, TEXT, LOG, 10053, 10046
  filename                   VARCHAR2(128),
  file_date                  DATE,
  file_size                  NUMBER,
  username                   VARCHAR2(257),
  file_text                  CLOB
);

GRANT ALL ON &&tool_repository_schema..trca$_file TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_file FOR &&tool_repository_schema..trca$_file;

GRANT SELECT ON &&tool_repository_schema..trca$_file TO &&role_name.;

/* ------------------------------------------------------------------------- */

-- staging table to hold names of traces inside control file
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..trca$_files (
  filename                   VARCHAR2(256),
  directory_alias            VARCHAR2(257),
  order_by                   NUMBER
) ON COMMIT PRESERVE ROWS;

GRANT ALL ON &&tool_repository_schema..trca$_files TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_files FOR &&tool_repository_schema..trca$_files;

/*------------------------------------------------------------------*/

-- one row for each file analyzed during one execution
CREATE TABLE &&tool_repository_schema..trca$_trace (
  id                         INTEGER        NOT NULL, -- pk trca$_trace_id_s
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  file_name                  VARCHAR2(4000) NOT NULL, -- trace file name
  file_len                   INTEGER,                 -- bytes in trace
  status                     VARCHAR2(257),            -- PARSING/COMPLETED/ERROR
  parse_start                DATE,
  parse_end                  DATE,
  parsed_lines               INTEGER,                 -- current parsing trace line
  parsed_bytes               INTEGER                  -- current parsing trace byte
);

GRANT ALL ON &&tool_repository_schema..trca$_trace TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_trace FOR &&tool_repository_schema..trca$_trace;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_trace_pk ON &&tool_repository_schema..trca$_trace(id);
ALTER TABLE &&tool_repository_schema..trca$_trace ADD (CONSTRAINT trca$_trace_pk PRIMARY KEY (id));

CREATE INDEX &&tool_repository_schema..trca$_trace_n1 ON &&tool_repository_schema..trca$_trace(tool_execution_id);

/* ------------------------------------------------------------------------- */

-- all trace lines before first SESSION
CREATE TABLE &&tool_repository_schema..trca$_trace_header (
  id                         INTEGER        NOT NULL, -- pk trca$_header_id_s
  trace_id                   INTEGER        NOT NULL, -- fk trca$_trace.id
  piece                      INTEGER        NOT NULL, -- header line number
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  text                       VARCHAR2(4000)
);

GRANT ALL ON &&tool_repository_schema..trca$_trace_header TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_trace_header FOR &&tool_repository_schema..trca$_trace_header;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_trace_header_pk ON &&tool_repository_schema..trca$_trace_header(id);
ALTER TABLE &&tool_repository_schema..trca$_trace_header ADD (CONSTRAINT trca$_trace_header_pk PRIMARY KEY (id));

CREATE INDEX &&tool_repository_schema..trca$_trace_header_n1 ON &&tool_repository_schema..trca$_trace_header(tool_execution_id, trace_id);

/* ------------------------------------------------------------------------- */

-- one row for each SESSION found in trace
CREATE TABLE &&tool_repository_schema..trca$_session (
  id                         INTEGER        NOT NULL, -- pk trca$_session_id_s
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  trace_id                   INTEGER        NOT NULL, -- fk trca$_trace.id
  sid                        INTEGER        NOT NULL,
  serial#                    INTEGER        NOT NULL,
  session_timestamp          TIMESTAMP      NOT NULL,
  session_tim                INTEGER,
  read_only_committed        INTEGER,
  read_only_rollbacked       INTEGER,
  update_committed           INTEGER,
  update_rollbacked          INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_session TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_session FOR &&tool_repository_schema..trca$_session;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_session_pk ON &&tool_repository_schema..trca$_session(id);
ALTER TABLE &&tool_repository_schema..trca$_session ADD (CONSTRAINT trca$_session_pk PRIMARY KEY (id));

CREATE INDEX &&tool_repository_schema..trca$_session_n1 ON &&tool_repository_schema..trca$_session(tool_execution_id);

/* ------------------------------------------------------------------------- */

-- one row for each GAP (***) found in trace
CREATE TABLE &&tool_repository_schema..trca$_gap (
  id                         INTEGER        NOT NULL, -- pk trca$_gap_id_s
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  trace_id                   INTEGER        NOT NULL, -- fk trca$_trace.id
  gap_timestamp              TIMESTAMP      NOT NULL,
  tim_before                 INTEGER,
  tim_after                  INTEGER,
  ela_after                  INTEGER,
  wait_call_after            CHAR(1),                -- (W)wait/(C)all
  call_id_after              INTEGER                 -- fk trca$_call.id
);

GRANT ALL ON &&tool_repository_schema..trca$_gap TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_gap FOR &&tool_repository_schema..trca$_gap;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_gap_pk ON &&tool_repository_schema..trca$_gap(id);
ALTER TABLE &&tool_repository_schema..trca$_gap ADD (CONSTRAINT trca$_gap_pk PRIMARY KEY (id));

CREATE INDEX &&tool_repository_schema..trca$_gap_n1 ON &&tool_repository_schema..trca$_gap(tool_execution_id);

/* ------------------------------------------------------------------------- */

-- call stack for calls associated to gaps
CREATE TABLE &&tool_repository_schema..trca$_gap_call (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  gap_id                     INTEGER        NOT NULL, -- fk trca$_gap.id
  call_id                    INTEGER        NOT NULL, -- fk trca$_call.id
  call                       INTEGER        NOT NULL, -- call enumerator
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  dep                        INTEGER,
  c                          INTEGER,
  e                          INTEGER,
  tim                        INTEGER,
  parent_dep_id              INTEGER                  -- fk trca$_call.dep_id
);

GRANT ALL ON &&tool_repository_schema..trca$_gap_call TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_gap_call FOR &&tool_repository_schema..trca$_gap_call;

CREATE INDEX &&tool_repository_schema..trca$_gap_call_n1 ON &&tool_repository_schema..trca$_gap_call(tool_execution_id);

/* ------------------------------------------------------------------------- */

-- one row for each unique SQL statement accoss all executions of this tool
CREATE TABLE &&tool_repository_schema..trca$_statement (
  id                         INTEGER        NOT NULL, -- pk trca$_statement_id_s
  len                        INTEGER        NOT NULL,
  hv                         INTEGER        NOT NULL,
  sqlid                      VARCHAR2(16),            -- 11g+
  oct                        INTEGER        NOT NULL, -- fk trca$_audit_actions.action
  sql_text                   VARCHAR2(1000) NOT NULL,
  sql_fulltext               CLOB           NOT NULL
);

GRANT ALL ON &&tool_repository_schema..trca$_statement TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_statement FOR &&tool_repository_schema..trca$_statement;

INSERT INTO &&tool_repository_schema..trca$_statement VALUES (-1, 7, -1, '-1', 0, 'UNKNOWN', 'UNKNOWN');

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_statement_pk ON &&tool_repository_schema..trca$_statement(id);
ALTER TABLE &&tool_repository_schema..trca$_statement ADD (CONSTRAINT trca$_statement_pk PRIMARY KEY (id));

CREATE INDEX &&tool_repository_schema..trca$_statement_n1 ON &&tool_repository_schema..trca$_statement(len, hv, oct, sqlid);

/* ------------------------------------------------------------------------- */

-- one row for each PARSING trace line
CREATE &&global_temporary. TABLE &&tool_repository_schema..trca$_cursor (
  id                         INTEGER        NOT NULL, -- pk trca$_cursor_id_s
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  trace_id                   INTEGER        NOT NULL, -- fk trca$_trace.id
  statement_id               INTEGER        NOT NULL, -- fk trca$_statement.id
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id (cursor_id or statement_id as per g_aggregate)
  cursor_num                 INTEGER        NOT NULL, -- as shown on trace
  dep                        INTEGER        NOT NULL,
  uid#                       INTEGER        NOT NULL,
  lid                        INTEGER        NOT NULL,
  tim                        INTEGER,
  ad                         VARCHAR2(32),
  err                        INTEGER,
  session_id                 NUMBER,                  -- fk trca$_session.id
  trace_line                 INTEGER
) &&on_commit_preserve_rows.;

GRANT ALL ON &&tool_repository_schema..trca$_cursor TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_cursor FOR &&tool_repository_schema..trca$_cursor;

/* ------------------------------------------------------------------------- */

-- one row for each PARSING for each unique SQL as per g_aggregate
CREATE TABLE &&tool_repository_schema..trca$_group (
  id                         INTEGER        NOT NULL, -- pk cursor_id or statement_id (fk trca$_cursor.id or trca$_statement.id)
  tool_execution_id          INTEGER        NOT NULL, -- pk fk trca$_tool_execution.id
  statement_id               INTEGER        NOT NULL, -- fk trca$_statement.id
  first_cursor_id            INTEGER        NOT NULL, -- fk trca$_cursor.id
  uid#                       INTEGER        NOT NULL, -- trca$_cursor.uid# (denormalized)
  lid                        INTEGER        NOT NULL, -- trca$_cursor.lid (denormalized)
  dep                        INTEGER        NOT NULL, -- trca$_cursor.dep (denormalized)
  plh                        INTEGER,                 -- 11.1.0.7+
  err                        INTEGER,                 -- trca$_cursor.err (denormalized)
  first_exec_id              INTEGER,                 -- fk trca$_exec.id
  last_exec_id               INTEGER,                 -- fk trca$_exec.id
  exec_count                 INTEGER,                 -- trca$_group_call.call_count
  response_time_self         INTEGER,                 -- elapsed plus wait idle
  response_time_progeny      INTEGER,                 -- ditto for recursive sql
  contribution               NUMBER,                  -- fraction between 0 and 1 over trace(s) total response time
  rank                       INTEGER,                 -- one means first top sql as per response time
  top_sql                    CHAR(1),                 -- Y/N as per reposnse time
  elapsed_time_self          INTEGER,                 -- elapsed time
  elapsed_time_progeny       INTEGER,                 -- ditto for recursive sql
  contribution_et            NUMBER,                  -- fraction between 0 and 1 over trace(s) total elapsed time
  rank_et                    INTEGER,                 -- one means first top sql as per elapsed time
  top_sql_et                 CHAR(1),                 -- Y/N as per elapsed time
  cpu_time_self              INTEGER,                 -- cpu time
  cpu_time_progeny           INTEGER,                 -- ditto for recursive sql
  contribution_ct            NUMBER,                  -- fraction between 0 and 1 over trace(s) total cpu time
  rank_ct                    INTEGER,                 -- one means first top sql as per cpu time
  top_sql_ct                 CHAR(1),                 -- Y/N as per cpu time
  include_details            CHAR(1),                 -- Y/N
  trca_plan_hash_value       INTEGER,                 -- for explain plan
  rows_processed             INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_group TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_group FOR &&tool_repository_schema..trca$_group;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_group_pk ON &&tool_repository_schema..trca$_group(id, tool_execution_id);
ALTER TABLE &&tool_repository_schema..trca$_group ADD (CONSTRAINT trca$_group_pk PRIMARY KEY (id, tool_execution_id));

CREATE INDEX &&tool_repository_schema..trca$_group_n1 ON &&tool_repository_schema..trca$_group(tool_execution_id);

/* ------------------------------------------------------------------------- */

-- one row for selected executions according to trca$t.compute_exec_rank (not all executions are materialized here)
CREATE TABLE &&tool_repository_schema..trca$_exec (
  id                         INTEGER        NOT NULL, -- pk trca$_exec_id_s
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  dep                        INTEGER        NOT NULL,
  plh                        INTEGER,                 -- 11.1.0.7+
  start_tim                  INTEGER        NOT NULL, -- of first call
  end_tim                    INTEGER        NOT NULL, -- of last call
  response_time_self         INTEGER        NOT NULL, -- elapsed plus wait idle
  response_time_progeny      INTEGER        NOT NULL, -- ditto for recursive sql
  grp_contribution           NUMBER,                  -- fraction between 0 and 1 over group total response time
  trc_contribution           NUMBER,                  -- fraction between 0 and 1 over trace total response time
  first_exec                 CHAR(1)        NOT NULL, -- Y/N
  last_exec                  CHAR(1)        NOT NULL, -- Y/N
  top_exec                   CHAR(1)        NOT NULL, -- Y/N
  rank                       INTEGER        NOT NULL  -- one means first top execution for one group
);

GRANT ALL ON &&tool_repository_schema..trca$_exec TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_exec FOR &&tool_repository_schema..trca$_exec;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_exec_pk ON &&tool_repository_schema..trca$_exec(id);
ALTER TABLE &&tool_repository_schema..trca$_exec ADD (CONSTRAINT trca$_exec_pk PRIMARY KEY (id));

CREATE INDEX &&tool_repository_schema..trca$_exec_n1 ON &&tool_repository_schema..trca$_exec(tool_execution_id, group_id);

/* ------------------------------------------------------------------------- */

-- one row per distinct wait event name found in one execution of this tool
CREATE TABLE &&tool_repository_schema..trca$_wait_event_name (
  tool_execution_id          INTEGER        NOT NULL, -- pk (fk trca$_tool_execution.id)
  event#                     INTEGER        NOT NULL, -- pk (fk trca$_event_name.event# if source is V)
  name                       VARCHAR2(64)   NOT NULL,
  wait_class                 VARCHAR2(64)   NOT NULL,
  idle                       CHAR(1)        NOT NULL, -- Y/N
  source                     CHAR(1)        NOT NULL, -- (V)iew, (T)trace
  parameter1v                VARCHAR2(64),            -- sourced by trca$_event_name
  parameter2v                VARCHAR2(64),
  parameter3v                VARCHAR2(64),
  parameter1t                VARCHAR2(64),            -- sourced by trace p1, p2 and p3 names
  parameter2t                VARCHAR2(64),
  parameter3t                VARCHAR2(64)
);

GRANT ALL ON &&tool_repository_schema..trca$_wait_event_name TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_wait_event_name FOR &&tool_repository_schema..trca$_wait_event_name;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_wait_event_name_pk ON &&tool_repository_schema..trca$_wait_event_name(tool_execution_id, event#);
ALTER TABLE &&tool_repository_schema..trca$_wait_event_name ADD (CONSTRAINT trca$_wait_event_name_pk PRIMARY KEY (tool_execution_id, event#));

/* ------------------------------------------------------------------------- */

-- one row for each WAIT line
CREATE &&global_temporary. TABLE &&tool_repository_schema..trca$_wait (
  call_id                    INTEGER        NOT NULL, -- fk trca$_call.id
  event#                     INTEGER        NOT NULL, -- fk trca$_wait_event_name.event#
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  ela                        INTEGER        NOT NULL,
  p1                         INTEGER,
  p2                         INTEGER,
  p3                         INTEGER,
  obj#                       INTEGER,
  tim                        INTEGER
) &&on_commit_preserve_rows.;

GRANT ALL ON &&tool_repository_schema..trca$_wait TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_wait FOR &&tool_repository_schema..trca$_wait;

/* ------------------------------------------------------------------------- */

-- one row for each Bind line. Several columns are disabled to save storage space.
CREATE &&global_temporary. TABLE &&tool_repository_schema..trca$_bind (
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected)
  group_id                   INTEGER,                 -- fk trca$_group.id (can be null)
  --cursor_id                  INTEGER        NOT NULL, -- fk trca$_cursor.id
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  bind                       INTEGER        NOT NULL,
  oacdef                     CHAR(1)        NOT NULL, -- Y/N. N=(No oacdef for this bind)
  oacdty                     INTEGER,
  --mxl                        INTEGER,
  --pmxl                       INTEGER,
  --mxlc                       INTEGER,
  --mal                        INTEGER,
  --scl                        INTEGER,
  --pre                        INTEGER,
  --oacflg                     INTEGER,
  --oacf12                     VARCHAR2(32), -- oacfl2 can be b38f0000000001 on 9.2.0.6 HP-UX
  --frm                        INTEGER,
  --csi                        INTEGER,
  --siz                        INTEGER,
  --offset                     INTEGER,
  --kxsbbbfp                   VARCHAR2(32),
  --bln                        INTEGER,
  avl                        INTEGER,
  --flg                        INTEGER,
  value                      VARCHAR2(4000)
) &&on_commit_preserve_rows.;

GRANT ALL ON &&tool_repository_schema..trca$_bind TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_bind FOR &&tool_repository_schema..trca$_bind;

/* ------------------------------------------------------------------------- */

-- bind variable values per execution
CREATE TABLE &&tool_repository_schema..trca$_exec_binds (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id
  bind                       INTEGER        NOT NULL,
  data_type_code             INTEGER,
  data_type_name             VARCHAR2(128),
  actual_value_length        INTEGER,
  oacdef                     CHAR(1)        NOT NULL, -- Y/N. N=(No oacdef for this bind)
  value                      VARCHAR2(4000)
);

GRANT ALL ON &&tool_repository_schema..trca$_exec_binds TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_exec_binds FOR &&tool_repository_schema..trca$_exec_binds;

CREATE INDEX &&tool_repository_schema..trca$_exec_binds_n1 ON &&tool_repository_schema..trca$_exec_binds(tool_execution_id, group_id, exec_id);

/* ------------------------------------------------------------------------- */

-- one row for each STAT line. Some columns are disabled to save storage space.
CREATE &&global_temporary. TABLE &&tool_repository_schema..trca$_stat (
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected)
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  cursor_id                  INTEGER        NOT NULL, -- fk trca$_cursor.id
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  --cursor_num                 INTEGER,
  session_id                 NUMBER,                  -- fk trca$_session.id (denormalized)
  id                         INTEGER        NOT NULL,
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
  card                       INTEGER
) &&on_commit_preserve_rows.;

GRANT ALL ON &&tool_repository_schema..trca$_stat TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_stat FOR &&tool_repository_schema..trca$_stat;

/* ------------------------------------------------------------------------- */

-- summary table with one row per execution set, indicating its plan hash value
CREATE TABLE &&tool_repository_schema..trca$_stat_exec (
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected)
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  trca_plan_hash_value       INTEGER        NOT NULL
);

GRANT ALL ON &&tool_repository_schema..trca$_stat_exec TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_stat_exec FOR &&tool_repository_schema..trca$_stat_exec;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_stat_exec_pk ON &&tool_repository_schema..trca$_stat_exec(exec_id);
ALTER TABLE &&tool_repository_schema..trca$_stat_exec ADD (CONSTRAINT trca$_stat_exec_pk PRIMARY KEY (exec_id));

CREATE INDEX &&tool_repository_schema..trca$_stat_exec_n1 ON &&tool_repository_schema..trca$_stat_exec(tool_execution_id);

/* ------------------------------------------------------------------------- */

-- plan hash values per group (normally one). This is for row source plans.
CREATE TABLE &&tool_repository_schema..trca$_group_row_source_plan (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  trca_plan_hash_value       INTEGER        NOT NULL, -- zero, one or many per group
  first_exec_id              INTEGER        NOT NULL  -- first_exec_id for given trca_plan_hash_value
);

GRANT ALL ON &&tool_repository_schema..trca$_group_row_source_plan TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_group_row_source_plan FOR &&tool_repository_schema..trca$_group_row_source_plan;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_group_row_source_plan_pk ON &&tool_repository_schema..trca$_group_row_source_plan(tool_execution_id, group_id, trca_plan_hash_value);
ALTER TABLE &&tool_repository_schema..trca$_group_row_source_plan ADD (CONSTRAINT trca$_group_row_source_plan_pk PRIMARY KEY (tool_execution_id, group_id, trca_plan_hash_value));

/* ------------------------------------------------------------------------- */

-- aggregate row source plan per trca_plan_hash_value.
CREATE TABLE &&tool_repository_schema..trca$_row_source_plan (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  trca_plan_hash_value       INTEGER        NOT NULL, -- row source plan
  id                         INTEGER        NOT NULL,
  pid                        INTEGER,
  depth                      INTEGER,
  cnt                        INTEGER,
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
  sessions                   INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_row_source_plan TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_row_source_plan FOR &&tool_repository_schema..trca$_row_source_plan;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_row_source_plan_pk ON &&tool_repository_schema..trca$_row_source_plan(tool_execution_id, group_id, trca_plan_hash_value, id);
ALTER TABLE &&tool_repository_schema..trca$_row_source_plan ADD (CONSTRAINT trca$_row_source_plan_pk PRIMARY KEY (tool_execution_id, group_id, trca_plan_hash_value, id));

/* ------------------------------------------------------------------------- */

-- aggregate row source plan per trca_plan_hash_value and session.
CREATE TABLE &&tool_repository_schema..trca$_row_source_plan_session (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  trca_plan_hash_value       INTEGER        NOT NULL, -- row source plan
  session_id                 INTEGER        NOT NULL,
  id                         INTEGER        NOT NULL,
  pid                        INTEGER,
  depth                      INTEGER,
  cnt                        INTEGER,
  pos                        INTEGER,
  obj                        INTEGER,
  op                         VARCHAR2(4000),
  cr                         INTEGER,
  pr                         INTEGER,
  pw                         INTEGER,
  time                       INTEGER,
  cost                       INTEGER,
  siz                        INTEGER,
  card                       INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_row_source_plan_session TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_row_source_plan_session FOR &&tool_repository_schema..trca$_row_source_plan_session;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_row_source_plan_sess_pk ON &&tool_repository_schema..trca$_row_source_plan_session(tool_execution_id, group_id, trca_plan_hash_value, session_id, id);
ALTER TABLE &&tool_repository_schema..trca$_row_source_plan_session ADD (CONSTRAINT trca$_row_source_plan_sess_pk PRIMARY KEY (tool_execution_id, group_id, trca_plan_hash_value, session_id, id));

/* ------------------------------------------------------------------------- */

-- one row per ERROR line. Some columns are disabled for consistency with other tables.
CREATE TABLE &&tool_repository_schema..trca$_error (
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected)
  group_id                   INTEGER,                 -- fk trca$_group.id (can be null)
  --cursor_id                  INTEGER        NOT NULL, -- fk trca$_cursor.id
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  --cursor_num                 INTEGER,
  err                        INTEGER,
  tim                        INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_error TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_error FOR &&tool_repository_schema..trca$_error;

CREATE INDEX &&tool_repository_schema..trca$_error_n1 ON &&tool_repository_schema..trca$_error(tool_execution_id);

/* ------------------------------------------------------------------------- */

-- one row per db call (PARSE, EXEC, FETCH, UNMAP, SORT_UNMAP)
CREATE &&global_temporary. TABLE &&tool_repository_schema..trca$_call (
  id                         INTEGER        NOT NULL, -- pk trca$_call_id_s
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected)
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  --cursor_id                  INTEGER        NOT NULL, -- fk trca$_cursor.id
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  -- parse
  call                       CHAR(1)        NOT NULL, -- CALL enumerator (trca$g)
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
  --og                         INTEGER,                -- irrelevant
  plh                        INTEGER,                 -- 11.1.0.7+
  tim                        INTEGER,
  -- recursive control (call dependencies)
  dep_id                     INTEGER,                 -- unique. null if leaf (no children underneath)
  parent_dep_id              INTEGER,                 -- null if dep=0 (root)
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
) &&on_commit_preserve_rows.;

GRANT ALL ON &&tool_repository_schema..trca$_call TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_call FOR &&tool_repository_schema..trca$_call;

/* ------------------------------------------------------------------------- */

-- edges of the call dependency tree (sql genealogy). nodes are defined by dep_id and parent_dep_id.
CREATE &&global_temporary. TABLE &&tool_repository_schema..trca$_call_tree (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id (denormalized)
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id (denormalized)
  parent_group_id            INTEGER,                 -- fk trca$_group.id (denormalized)
  dep_id                     INTEGER,                 -- fk trca$_call.dep_id (lower node) null for leafs
  parent_dep_id              INTEGER,                 -- fk trca$_call.parent_dep_id (upper node) null for roots
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected). this is the edge
  response_time_self         INTEGER        NOT NULL, -- elapsed plus wait idle for this edge
  response_time_progeny      INTEGER        NOT NULL  -- ditto for recursive sql (branches underneeth)
) &&on_commit_preserve_rows.;

GRANT ALL ON &&tool_repository_schema..trca$_call_tree TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_call_tree FOR &&tool_repository_schema..trca$_call_tree;

CREATE INDEX &&tool_repository_schema..trca$_call_tree_n1 ON &&tool_repository_schema..trca$_call_tree(tool_execution_id, parent_dep_id);

/* ------------------------------------------------------------------------- */

-- edges of the call dependency tree (sql genealogy). nodes are defined by dep_id and parent_dep_id.
CREATE &&global_temporary. TABLE &&tool_repository_schema..trca$_exec_tree (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  root_group_id              INTEGER        NOT NULL, -- non-recursive sql
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id (lower node) null for leafs
  parent_group_id            INTEGER,                 -- fk trca$_group.id (upper node) null for roots
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected). this is the edge
  response_time_self         INTEGER        NOT NULL, -- elapsed plus wait idle for this edge
  response_time_progeny      INTEGER        NOT NULL, -- ditto for recursive sql (branches underneeth)
  dep                        INTEGER        NOT NULL,
  path                       VARCHAR2(256)            -- from root to leaf excluding this
) &&on_commit_preserve_rows.;

GRANT ALL ON &&tool_repository_schema..trca$_exec_tree TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_exec_tree FOR &&tool_repository_schema..trca$_exec_tree;

/* ------------------------------------------------------------------------- */

-- aggregate of execution tree edges since same edge can have multiple executions
CREATE &&global_temporary. TABLE &&tool_repository_schema..trca$_genealogy_edge (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  root_group_id              INTEGER        NOT NULL, -- non-recursive sql
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id (lower node) null for leafs
  parent_group_id            INTEGER,                 -- fk trca$_group.id (upper node) null for roots
  first_exec_id              INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected). this is the edge
  exec_count                 INTEGER        NOT NULL, -- number of executions for this edge
  response_time_self         INTEGER        NOT NULL, -- elapsed plus wait idle for this edge
  response_time_progeny      INTEGER        NOT NULL, -- ditto for recursive sql (branches underneeth)
  dep                        INTEGER        NOT NULL,
  path                       VARCHAR2(256)            -- from root to leaf excluding this
) &&on_commit_preserve_rows.;

GRANT ALL ON &&tool_repository_schema..trca$_genealogy_edge TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_genealogy_edge FOR &&tool_repository_schema..trca$_genealogy_edge;

CREATE INDEX &&tool_repository_schema..trca$_genealogy_edge_n1 ON &&tool_repository_schema..trca$_genealogy_edge(tool_execution_id, root_group_id, group_id);
CREATE INDEX &&tool_repository_schema..trca$_genealogy_edge_n2 ON &&tool_repository_schema..trca$_genealogy_edge(tool_execution_id, root_group_id, parent_group_id);

/* ------------------------------------------------------------------------- */

-- same as trca$_genealogy_edge but tree order is incorporated (id)
CREATE TABLE &&tool_repository_schema..trca$_genealogy (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  root_group_id              INTEGER        NOT NULL, -- non-recursive sql
  id                         INTEGER        NOT NULL, -- order in this tree
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id (lower node) null for leafs
  parent_group_id            INTEGER,                 -- fk trca$_group.id (upper node) null for roots
  first_exec_id              INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected). this is the edge
  exec_count                 INTEGER        NOT NULL, -- number of executions for this edge
  response_time_self         INTEGER        NOT NULL, -- elapsed plus wait idle for this edge
  response_time_progeny      INTEGER        NOT NULL, -- ditto for recursive sql (branches underneeth)
  dep                        INTEGER        NOT NULL,
  path                       VARCHAR2(256)            -- from root to leaf excluding this
);

GRANT ALL ON &&tool_repository_schema..trca$_genealogy TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_genealogy FOR &&tool_repository_schema..trca$_genealogy;

CREATE INDEX &&tool_repository_schema..trca$_genealogy_n1 ON &&tool_repository_schema..trca$_genealogy(tool_execution_id);

/* ------------------------------------------------------------------------- */

-- calls aggregate per execution
CREATE TABLE &&tool_repository_schema..trca$_group_exec_call (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected)
  call                       CHAR(1)        NOT NULL, -- CALL enumerator (trca$g)
  -- aggregate stats (this plus direct children)
  c                          INTEGER,
  e                          INTEGER,
  p                          INTEGER,
  cr                         INTEGER,
  cu                         INTEGER,
  -- non aggregate stats (this)
  call_count                 INTEGER,
  mis                        INTEGER,
  r                          INTEGER,
  -- attributes
  dep                        INTEGER,
  plh                        INTEGER, -- 11.1.0.7+
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

GRANT ALL ON &&tool_repository_schema..trca$_group_exec_call TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_group_exec_call FOR &&tool_repository_schema..trca$_group_exec_call;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_group_exec_call_pk ON &&tool_repository_schema..trca$_group_exec_call(tool_execution_id, group_id, exec_id, call);
ALTER TABLE &&tool_repository_schema..trca$_group_exec_call ADD (CONSTRAINT trca$_group_exec_call_pk PRIMARY KEY (tool_execution_id, group_id, exec_id, call));

/* ------------------------------------------------------------------------- */

-- calls aggregate per group
CREATE TABLE &&tool_repository_schema..trca$_group_call (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  call                       CHAR(1)        NOT NULL, -- CALL enumerator (trca$g)
  -- aggregate stats (this plus direct children)
  c                          INTEGER,
  e                          INTEGER,
  p                          INTEGER,
  cr                         INTEGER,
  cu                         INTEGER,
  -- non aggregate stats (this)
  call_count                 INTEGER,
  mis                        INTEGER,
  r                          INTEGER,
  -- attributes
  dep                        INTEGER,
  plh                        INTEGER, -- 11.1.0.7+
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

GRANT ALL ON &&tool_repository_schema..trca$_group_call TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_group_call FOR &&tool_repository_schema..trca$_group_call;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_group_call_pk ON &&tool_repository_schema..trca$_group_call(tool_execution_id, group_id, call);
ALTER TABLE &&tool_repository_schema..trca$_group_call ADD (CONSTRAINT trca$_group_call_pk PRIMARY KEY (tool_execution_id, group_id, call));

/* ------------------------------------------------------------------------- */

-- calls aggregate per tool execution (overall totals)
CREATE TABLE &&tool_repository_schema..trca$_tool_exec_call (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  recursive                  CHAR(1)        NOT NULL, -- Y/N
  call                       CHAR(1)        NOT NULL, -- CALL enumerator (trca$g)
  -- aggregate stats (this plus direct children)
  c                          INTEGER,
  e                          INTEGER,
  p                          INTEGER,
  cr                         INTEGER,
  cu                         INTEGER,
  -- non aggregate stats (this)
  call_count                 INTEGER,
  mis                        INTEGER,
  r                          INTEGER,
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

GRANT ALL ON &&tool_repository_schema..trca$_tool_exec_call TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_tool_exec_call FOR &&tool_repository_schema..trca$_tool_exec_call;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_tool_exec_call_pk ON &&tool_repository_schema..trca$_tool_exec_call(tool_execution_id, recursive, call);
ALTER TABLE &&tool_repository_schema..trca$_tool_exec_call ADD (CONSTRAINT trca$_tool_exec_call_pk PRIMARY KEY (tool_execution_id, recursive, call));

/* ------------------------------------------------------------------------- */

-- waits aggregate per tool execution (overall totals)
CREATE TABLE &&tool_repository_schema..trca$_tool_wait (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  dep                        INTEGER        NOT NULL,
  event#                     INTEGER        NOT NULL, -- trca$_wait_event_name.event#
  ela                        INTEGER        NOT NULL,
  wait_count                 INTEGER        NOT NULL,
  max_ela                    INTEGER        NOT NULL,
  blocks                     INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_tool_wait TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_tool_wait FOR &&tool_repository_schema..trca$_tool_wait;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_tool_wait_pk ON &&tool_repository_schema..trca$_tool_wait(tool_execution_id, dep, event#);
ALTER TABLE &&tool_repository_schema..trca$_tool_wait ADD (CONSTRAINT trca$_tool_wait_pk PRIMARY KEY (tool_execution_id, dep, event#));

/* ------------------------------------------------------------------------- */

-- waits aggregate per group
CREATE TABLE &&tool_repository_schema..trca$_group_wait (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  event#                     INTEGER        NOT NULL, -- trca$_wait_event_name.event#
  ela                        INTEGER        NOT NULL,
  wait_count                 INTEGER        NOT NULL,
  max_ela                    INTEGER        NOT NULL,
  blocks                     INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_group_wait TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_group_wait FOR &&tool_repository_schema..trca$_group_wait;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_group_wait_pk ON &&tool_repository_schema..trca$_group_wait(tool_execution_id, group_id, event#);
ALTER TABLE &&tool_repository_schema..trca$_group_wait ADD (CONSTRAINT trca$_group_wait_pk PRIMARY KEY (tool_execution_id, group_id, event#));

/* ------------------------------------------------------------------------- */

-- waits aggregate per execution
CREATE TABLE &&tool_repository_schema..trca$_group_exec_wait (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected)
  event#                     INTEGER        NOT NULL, -- trca$_wait_event_name.event#
  ela                        INTEGER        NOT NULL,
  wait_count                 INTEGER        NOT NULL,
  max_ela                    INTEGER        NOT NULL,
  blocks                     INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_group_exec_wait TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_group_exec_wait FOR &&tool_repository_schema..trca$_group_exec_wait;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_group_exec_wait_pk ON &&tool_repository_schema..trca$_group_exec_wait(tool_execution_id, group_id, exec_id, event#);
ALTER TABLE &&tool_repository_schema..trca$_group_exec_wait ADD (CONSTRAINT trca$_group_exec_wait_pk PRIMARY KEY (tool_execution_id, group_id, exec_id, event#));

/* ------------------------------------------------------------------------- */

-- external dict table generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_objects (
  object_id                  VARCHAR2(255),
  object_type                VARCHAR2(255),
  owner                      VARCHAR2(257),
  object_name                VARCHAR2(257),
  subobject_name             VARCHAR2(257)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_OBJECTS.bad'
  LOGFILE 'TRCA_OBJECTS.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_OBJECTS.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_objects TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_objects FOR &&tool_repository_schema..trca_objects;

/* ------------------------------------------------------------------------- */

-- dict snaphot of dba_objects seeded by trca$t.refresh_trca$_dict_from
CREATE TABLE &&tool_repository_schema..trca$_objects$ (
  object_id                  INTEGER        NOT NULL,
  object_type                VARCHAR2(20),
  owner                      VARCHAR2(257),
  object_name                VARCHAR2(257),
  subobject_name             VARCHAR2(257)
);

GRANT ALL ON &&tool_repository_schema..trca$_objects$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_objects$ FOR &&tool_repository_schema..trca$_objects$;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_objects$_u1 ON &&tool_repository_schema..trca$_objects$(object_id);

/* ------------------------------------------------------------------------- */

-- objects referenced by waits
CREATE TABLE &&tool_repository_schema..trca$_objects (
  tool_execution_id          INTEGER        NOT NULL, -- pk fk trca$_tool_execution.id
  object_id                  INTEGER        NOT NULL, -- pk fk dba_objects.object_id
  object_type                VARCHAR2(20),
  owner                      VARCHAR2(257),
  object_name                VARCHAR2(257),
  subobject_name             VARCHAR2(257)
);

GRANT ALL ON &&tool_repository_schema..trca$_objects TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_objects FOR &&tool_repository_schema..trca$_objects;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_objects_pk ON &&tool_repository_schema..trca$_objects(tool_execution_id, object_id);
ALTER TABLE &&tool_repository_schema..trca$_objects ADD (CONSTRAINT trca$_objects_pk PRIMARY KEY (tool_execution_id, object_id));

/* ------------------------------------------------------------------------- */

-- wait segments per tool execution (overall totals)
CREATE TABLE &&tool_repository_schema..trca$_tool_wait_segment (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  dep                        INTEGER        NOT NULL,
  event#                     INTEGER        NOT NULL, -- trca$_wait_event_name.event#
  ela                        INTEGER        NOT NULL,
  wait_count                 INTEGER        NOT NULL,
  max_ela                    INTEGER        NOT NULL,
  start_tim                  INTEGER,
  end_tim                    INTEGER,
  blocks                     INTEGER,
  obj#                       INTEGER,
  segment_type               VARCHAR2(20),
  owner                      VARCHAR2(257),
  segment_name               VARCHAR2(257),
  partition_name             VARCHAR2(257)
);

GRANT ALL ON &&tool_repository_schema..trca$_tool_wait_segment TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_tool_wait_segment FOR &&tool_repository_schema..trca$_tool_wait_segment;

CREATE INDEX &&tool_repository_schema..trca$_tool_wait_segment_n1 ON &&tool_repository_schema..trca$_tool_wait_segment(tool_execution_id, dep, event#);

/* ------------------------------------------------------------------------- */

-- wait segments per group
CREATE TABLE &&tool_repository_schema..trca$_group_wait_segment (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  event#                     INTEGER        NOT NULL, -- trca$_wait_event_name.event#
  ela                        INTEGER        NOT NULL,
  wait_count                 INTEGER        NOT NULL,
  max_ela                    INTEGER        NOT NULL,
  start_tim                  INTEGER,
  end_tim                    INTEGER,
  blocks                     INTEGER,
  obj#                       INTEGER,
  segment_type               VARCHAR2(20),
  owner                      VARCHAR2(257),
  segment_name               VARCHAR2(257),
  partition_name             VARCHAR2(257)
);

GRANT ALL ON &&tool_repository_schema..trca$_group_wait_segment TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_group_wait_segment FOR &&tool_repository_schema..trca$_group_wait_segment;

CREATE INDEX &&tool_repository_schema..trca$_group_wait_segment_n1 ON &&tool_repository_schema..trca$_group_wait_segment(tool_execution_id, group_id, event#);

/* ------------------------------------------------------------------------- */

-- wait segments per execution
CREATE TABLE &&tool_repository_schema..trca$_group_exec_wait_segment (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  group_id                   INTEGER        NOT NULL, -- fk trca$_group.id
  exec_id                    INTEGER        NOT NULL, -- fk trca$_exec.id (orphans are expected)
  event#                     INTEGER        NOT NULL, -- trca$_wait_event_name.event#
  ela                        INTEGER        NOT NULL,
  wait_count                 INTEGER        NOT NULL,
  max_ela                    INTEGER        NOT NULL,
  start_tim                  INTEGER,
  end_tim                    INTEGER,
  blocks                     INTEGER,
  obj#                       INTEGER,
  segment_type               VARCHAR2(20),
  owner                      VARCHAR2(257),
  segment_name               VARCHAR2(257),
  partition_name             VARCHAR2(257)
);

GRANT ALL ON &&tool_repository_schema..trca$_group_exec_wait_segment TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_group_exec_wait_segment FOR &&tool_repository_schema..trca$_group_exec_wait_segment;

CREATE INDEX &&tool_repository_schema..trca$_group_exec_wait_seg_n1 ON &&tool_repository_schema..trca$_group_exec_wait_segment(tool_execution_id, group_id, exec_id, event#);

/* ------------------------------------------------------------------------- */

-- hot blocks
CREATE TABLE &&tool_repository_schema..trca$_hot_block (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  p1                         INTEGER        NOT NULL,
  p2                         INTEGER        NOT NULL,
  ela                        INTEGER        NOT NULL,
  wait_count                 INTEGER        NOT NULL,
  max_ela                    INTEGER        NOT NULL,
  obj#                       INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_hot_block TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_hot_block FOR &&tool_repository_schema..trca$_hot_block;

CREATE INDEX &&tool_repository_schema..trca$_hot_block_n1 ON &&tool_repository_schema..trca$_hot_block(tool_execution_id);

/* ------------------------------------------------------------------------- */

-- hot blocks with segment details
CREATE TABLE &&tool_repository_schema..trca$_hot_block_segment (
  tool_execution_id          INTEGER        NOT NULL, -- fk trca$_tool_execution.id
  p1                         INTEGER        NOT NULL,
  p2                         INTEGER        NOT NULL,
  ela                        INTEGER        NOT NULL,
  wait_count                 INTEGER        NOT NULL,
  max_ela                    INTEGER        NOT NULL,
  obj#                       INTEGER,
  segment_type               VARCHAR2(20),
  owner                      VARCHAR2(257),
  segment_name               VARCHAR2(257),
  partition_name             VARCHAR2(257)
);

GRANT ALL ON &&tool_repository_schema..trca$_hot_block_segment TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_hot_block_segment FOR &&tool_repository_schema..trca$_hot_block_segment;

CREATE INDEX &&tool_repository_schema..trca$_hot_block_segment_n1 ON &&tool_repository_schema..trca$_hot_block_segment(tool_execution_id);

/* ------------------------------------------------------------------------- */

-- lookup table
WHENEVER SQLERROR CONTINUE;
CREATE TABLE &&tool_repository_schema..trca$_audit_actions AS
SELECT * FROM audit_actions;
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- if CTAS above fails because not having Oracle Auditing installed thne create an empty table to mimic it
WHENEVER SQLERROR CONTINUE;
CREATE TABLE &&tool_repository_schema..trca$_audit_actions (
  action NUMBER,
  name   VARCHAR2(28)
);
WHENEVER SQLERROR EXIT SQL.SQLCODE;

GRANT ALL ON &&tool_repository_schema..trca$_audit_actions TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_audit_actions FOR &&tool_repository_schema..trca$_audit_actions;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_audit_actions_pk ON &&tool_repository_schema..trca$_audit_actions(action);
ALTER TABLE &&tool_repository_schema..trca$_audit_actions ADD (CONSTRAINT trca$_audit_actions_pk PRIMARY KEY (action));

/* ------------------------------------------------------------------------- */

-- for explain plans
CREATE TABLE &&tool_repository_schema..trca$_plan_table (
  statement_id               VARCHAR2(257),
  plan_id                    NUMBER,
  timestamp                  DATE,
  remarks                    VARCHAR2(4000),
  operation                  VARCHAR2(257),
  options                    VARCHAR2(255),
  object_node                VARCHAR2(128),
  object_owner               VARCHAR2(257),
  object_name                VARCHAR2(257),
  object_alias               VARCHAR2(65),
  object_instance            NUMERIC,
  object_type                VARCHAR2(257),
  optimizer                  VARCHAR2(255),
  search_columns             NUMBER,
  id                         NUMERIC,
  parent_id                  NUMERIC,
  depth                      NUMERIC,
  position                   NUMERIC,
  cost                       NUMERIC,
  cardinality                NUMERIC,
  bytes                      NUMERIC,
  other_tag                  VARCHAR2(255),
  partition_start            VARCHAR2(255),
  partition_stop             VARCHAR2(255),
  partition_id               NUMERIC,
  other                      CLOB,
  distribution               VARCHAR2(257),
  cpu_cost                   NUMERIC,
  io_cost                    NUMERIC,
  temp_space                 NUMERIC,
  access_predicates          VARCHAR2(4000),
  filter_predicates          VARCHAR2(4000),
  projection                 VARCHAR2(4000),
  time                       NUMERIC,
  qblock_name                VARCHAR2(257),
  other_xml                  CLOB,
  -- trca
  tool_execution_id          INTEGER, -- fk trca$_tool_execution.id
  group_id                   INTEGER, -- fk trca$_group.id
  actual_rows                INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_plan_table TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_plan_table FOR &&tool_repository_schema..trca$_plan_table;

CREATE INDEX &&tool_repository_schema..trca$_plan_table_n1 ON &&tool_repository_schema..trca$_plan_table(tool_execution_id, group_id);

GRANT INSERT ON &&tool_repository_schema..trca$_plan_table TO &&role_name.;

/* ------------------------------------------------------------------------- */

-- staging table to get tables and indexes out of explain plan and row source plan
CREATE GLOBAL TEMPORARY TABLE &&tool_repository_schema..trca$_pivot (
  object_name                VARCHAR2(257),
  object_owner               VARCHAR2(257)
) ON COMMIT DELETE ROWS;

GRANT ALL ON &&tool_repository_schema..trca$_pivot TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_pivot FOR &&tool_repository_schema..trca$_pivot;

/* ------------------------------------------------------------------------- */

-- external dict table generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_tables (
  owner                      VARCHAR2(255),
  table_name                 VARCHAR2(255),
  num_rows                   VARCHAR2(255),
  blocks                     VARCHAR2(255),
  empty_blocks               VARCHAR2(255),
  avg_space                  VARCHAR2(255),
  chain_cnt                  VARCHAR2(255),
  avg_row_len                VARCHAR2(255),
  sample_size                VARCHAR2(255),
  last_analyzed              VARCHAR2(255), -- YYYYMMDDHHMISS
  partitioned                VARCHAR2(255),
  temporary                  VARCHAR2(255),
  global_stats               VARCHAR2(255)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_TABLES.bad'
  LOGFILE 'TRCA_TABLES.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_TABLES.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_tables TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_tables FOR &&tool_repository_schema..trca_tables;

/* ------------------------------------------------------------------------- */

-- dict snaphot of dba_tables seeded by trca$t.refresh_trca$_dict_from
CREATE TABLE &&tool_repository_schema..trca$_tables$ (
  owner                      VARCHAR2(257) NOT NULL,
  table_name                 VARCHAR2(257) NOT NULL,
  num_rows                   NUMBER,
  blocks                     NUMBER,
  empty_blocks               NUMBER,
  avg_space                  NUMBER,
  chain_cnt                  NUMBER,
  avg_row_len                NUMBER,
  sample_size                NUMBER,
  last_analyzed              DATE,
  partitioned                VARCHAR2(3),
  temporary                  VARCHAR2(1),
  global_stats               VARCHAR2(3)
);

GRANT ALL ON &&tool_repository_schema..trca$_tables$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_tables$ FOR &&tool_repository_schema..trca$_tables$;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_tables$_u1 ON &&tool_repository_schema..trca$_tables$(table_name, owner);

/* ------------------------------------------------------------------------- */

-- tables refernced by explain plan and row source plan. derived from dba_tables.
CREATE TABLE &&tool_repository_schema..trca$_tables (
  owner                      VARCHAR2(257) NOT NULL,
  table_name                 VARCHAR2(257) NOT NULL,
  num_rows                   NUMBER,
  blocks                     NUMBER,
  empty_blocks               NUMBER,
  avg_space                  NUMBER,
  chain_cnt                  NUMBER,
  avg_row_len                NUMBER,
  sample_size                NUMBER,
  last_analyzed              DATE,
  partitioned                VARCHAR2(3),
  temporary                  VARCHAR2(1),
  global_stats               VARCHAR2(3),
  -- trca
  tool_execution_id          INTEGER NOT NULL, -- fk trca$_tool_execution.id
  actual_rows                INTEGER,
  actual_rows_suffix         CHAR(1)
);

GRANT ALL ON &&tool_repository_schema..trca$_tables TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_tables FOR &&tool_repository_schema..trca$_tables;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_tables_pk ON &&tool_repository_schema..trca$_tables(tool_execution_id, owner, table_name);
ALTER TABLE &&tool_repository_schema..trca$_tables ADD (CONSTRAINT trca$_tables_pk PRIMARY KEY (tool_execution_id, owner, table_name));

GRANT SELECT, UPDATE ON &&tool_repository_schema..trca$_tables TO &&role_name.;

/* ------------------------------------------------------------------------- */

-- external dict table generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_indexes (
  owner                      VARCHAR2(255),
  index_name                 VARCHAR2(255),
  index_type                 VARCHAR2(255),
  table_owner                VARCHAR2(255),
  table_name                 VARCHAR2(255),
  uniqueness                 VARCHAR2(255),
  blevel                     VARCHAR2(255),
  leaf_blocks                VARCHAR2(255),
  distinct_keys              VARCHAR2(255),
  avg_leaf_blocks_per_key    VARCHAR2(255),
  avg_data_blocks_per_key    VARCHAR2(255),
  clustering_factor          VARCHAR2(255),
  num_rows                   VARCHAR2(255),
  sample_size                VARCHAR2(255),
  last_analyzed              VARCHAR2(255), -- YYYYMMDDHHMISS
  partitioned                VARCHAR2(255),
  temporary                  VARCHAR2(255),
  global_stats               VARCHAR2(255)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_INDEXES.bad'
  LOGFILE 'TRCA_INDEXES.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_INDEXES.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_indexes TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_indexes FOR &&tool_repository_schema..trca_indexes;

/* ------------------------------------------------------------------------- */

-- dict snaphot of dba_tables seeded by trca$t.refresh_trca$_dict_from
CREATE TABLE &&tool_repository_schema..trca$_indexes$ (
  owner                      VARCHAR2(257) NOT NULL,
  index_name                 VARCHAR2(257) NOT NULL,
  index_type                 VARCHAR2(27),
  table_owner                VARCHAR2(257) NOT NULL,
  table_name                 VARCHAR2(257) NOT NULL,
  uniqueness                 VARCHAR2(9),
  blevel                     NUMBER,
  leaf_blocks                NUMBER,
  distinct_keys              NUMBER,
  avg_leaf_blocks_per_key    NUMBER,
  avg_data_blocks_per_key    NUMBER,
  clustering_factor          NUMBER,
  num_rows                   NUMBER,
  sample_size                NUMBER,
  last_analyzed              DATE,
  partitioned                VARCHAR2(3),
  temporary                  VARCHAR2(1),
  global_stats               VARCHAR2(3)
);

GRANT ALL ON &&tool_repository_schema..trca$_indexes$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_indexes$ FOR &&tool_repository_schema..trca$_indexes$;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_indexes$_u1 ON &&tool_repository_schema..trca$_indexes$(index_name, owner);
CREATE INDEX &&tool_repository_schema..trca$_indexes$_n1 ON &&tool_repository_schema..trca$_indexes$(table_name, table_owner);

/* ------------------------------------------------------------------------- */

-- indexes for tables refernced by explain plan and row source plan. derived from dba_indexes.
CREATE TABLE &&tool_repository_schema..trca$_indexes (
  owner                      VARCHAR2(257) NOT NULL,
  index_name                 VARCHAR2(257) NOT NULL,
  index_type                 VARCHAR2(27),
  table_owner                VARCHAR2(257) NOT NULL,
  table_name                 VARCHAR2(257) NOT NULL,
  uniqueness                 VARCHAR2(9),
  blevel                     NUMBER,
  leaf_blocks                NUMBER,
  distinct_keys              NUMBER,
  avg_leaf_blocks_per_key    NUMBER,
  avg_data_blocks_per_key    NUMBER,
  clustering_factor          NUMBER,
  num_rows                   NUMBER,
  sample_size                NUMBER,
  last_analyzed              DATE,
  partitioned                VARCHAR2(3),
  temporary                  VARCHAR2(1),
  global_stats               VARCHAR2(3),
  -- trca
  tool_execution_id          INTEGER NOT NULL,
  indexed_columns            VARCHAR2(4000),
  columns_count              INTEGER
);

GRANT ALL ON &&tool_repository_schema..trca$_indexes TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_indexes FOR &&tool_repository_schema..trca$_indexes;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_indexes_pk ON &&tool_repository_schema..trca$_indexes(tool_execution_id, owner, index_name);
ALTER TABLE &&tool_repository_schema..trca$_indexes ADD (CONSTRAINT trca$_indexes_pk PRIMARY KEY (tool_execution_id, owner, index_name));

CREATE INDEX &&tool_repository_schema..trca$_indexes_n1 ON &&tool_repository_schema..trca$_indexes(tool_execution_id, table_owner, table_name);

/* ------------------------------------------------------------------------- */

-- tables refernced by explain plan and row source plan for a given group
CREATE TABLE &&tool_repository_schema..trca$_group_tables (
  tool_execution_id          INTEGER      NOT NULL, -- fk trca$_tool_execution.id
  group_id                   INTEGER      NOT NULL, -- fk trca$_group.id
  owner                      VARCHAR2(257) NOT NULL,
  table_name                 VARCHAR2(257) NOT NULL,
  in_row_source_plan         CHAR(1)      NOT NULL,
  in_explain_plan            CHAR(1)      NOT NULL
);

GRANT ALL ON &&tool_repository_schema..trca$_group_tables TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_group_tables FOR &&tool_repository_schema..trca$_group_tables;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_group_tables_pk ON &&tool_repository_schema..trca$_group_tables(tool_execution_id, group_id, owner, table_name);
ALTER TABLE &&tool_repository_schema..trca$_group_tables ADD (CONSTRAINT trca$_group_tables_pk PRIMARY KEY (tool_execution_id, group_id, owner, table_name));

/* ------------------------------------------------------------------------- */

-- indexes for tables refernced by explain plan and row source plan for a given group
CREATE TABLE &&tool_repository_schema..trca$_group_indexes (
  tool_execution_id          INTEGER      NOT NULL, -- fk trca$_tool_execution.id
  group_id                   INTEGER      NOT NULL, -- fk trca$_group.id
  owner                      VARCHAR2(257) NOT NULL,
  index_name                 VARCHAR2(257) NOT NULL,
  table_owner                VARCHAR2(257) NOT NULL,
  table_name                 VARCHAR2(257) NOT NULL,
  in_row_source_plan         CHAR(1)      NOT NULL,
  in_explain_plan            CHAR(1)      NOT NULL
);

GRANT ALL ON &&tool_repository_schema..trca$_group_indexes TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_group_indexes FOR &&tool_repository_schema..trca$_group_indexes;

CREATE UNIQUE INDEX &&tool_repository_schema..trca$_group_indexes_pk ON &&tool_repository_schema..trca$_group_indexes(tool_execution_id, group_id, owner, index_name);
ALTER TABLE &&tool_repository_schema..trca$_group_indexes ADD (CONSTRAINT trca$_group_indexes_pk PRIMARY KEY (tool_execution_id, group_id, owner, index_name));

CREATE INDEX &&tool_repository_schema..trca$_group_indexes_n1 ON &&tool_repository_schema..trca$_group_indexes(tool_execution_id, group_id, table_owner, table_name);

/* ------------------------------------------------------------------------- */

-- external dict table generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_tab_cols (
  owner                      VARCHAR2(257),
  table_name                 VARCHAR2(257),
  column_name                VARCHAR2(257),
  column_id                  VARCHAR2(255),
  num_distinct               VARCHAR2(255),
  density                    VARCHAR2(255),
  num_nulls                  VARCHAR2(255),
  num_buckets                VARCHAR2(255),
  last_analyzed              VARCHAR2(255), -- YYYYMMDDHHMISS
  sample_size                VARCHAR2(255)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_TAB_COLS.bad'
  LOGFILE 'TRCA_TAB_COLS.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_TAB_COLS.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_tab_cols TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_tab_cols FOR &&tool_repository_schema..trca_tab_cols;

/* ------------------------------------------------------------------------- */

-- dict snaphot of dba_tab_cols seeded by trca$t.refresh_trca$_dict_from
CREATE TABLE &&tool_repository_schema..trca$_tab_cols$ (
  owner                      VARCHAR2(257) NOT NULL,
  table_name                 VARCHAR2(257) NOT NULL,
  column_name                VARCHAR2(257) NOT NULL,
  column_id                  NUMBER,
  num_distinct               NUMBER,
  density                    NUMBER,
  num_nulls                  NUMBER,
  num_buckets                NUMBER,
  last_analyzed              DATE,
  sample_size                NUMBER
);

GRANT ALL ON &&tool_repository_schema..trca$_tab_cols$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_tab_cols$ FOR &&tool_repository_schema..trca$_tab_cols$;

CREATE INDEX &&tool_repository_schema..trca$_tab_cols$_n1 ON &&tool_repository_schema..trca$_tab_cols$(table_name, owner);

/* ------------------------------------------------------------------------- */

-- table columns for trca$_tables
CREATE TABLE &&tool_repository_schema..trca$_tab_cols (
  owner                      VARCHAR2(257) NOT NULL,
  table_name                 VARCHAR2(257) NOT NULL,
  column_name                VARCHAR2(257) NOT NULL,
  column_id                  NUMBER,
  num_distinct               NUMBER,
  density                    NUMBER,
  num_nulls                  NUMBER,
  num_buckets                NUMBER,
  last_analyzed              DATE,
  sample_size                NUMBER,
  -- trca
  tool_execution_id          INTEGER NOT NULL -- fk trca$_tool_execution.id
);

GRANT ALL ON &&tool_repository_schema..trca$_tab_cols TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_tab_cols FOR &&tool_repository_schema..trca$_tab_cols;

CREATE INDEX &&tool_repository_schema..trca$_tab_cols_n1 ON &&tool_repository_schema..trca$_tab_cols(tool_execution_id, owner, table_name, column_name);

/* ------------------------------------------------------------------------- */

-- external dict table generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_ind_columns (
  index_owner                VARCHAR2(257),
  index_name                 VARCHAR2(257),
  table_owner                VARCHAR2(257),
  table_name                 VARCHAR2(257),
  column_name                VARCHAR2(257),
  column_position            VARCHAR2(255),
  descend                    VARCHAR2(255)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_IND_COLUMNS.bad'
  LOGFILE 'TRCA_IND_COLUMNS.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_IND_COLUMNS.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_ind_columns TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_ind_columns FOR &&tool_repository_schema..trca_ind_columns;

/* ------------------------------------------------------------------------- */

-- dict snaphot of dba_ind_columns seeded by trca$t.refresh_trca$_dict_from
CREATE TABLE &&tool_repository_schema..trca$_ind_columns$ (
  index_owner                VARCHAR2(257) NOT NULL,
  index_name                 VARCHAR2(257) NOT NULL,
  table_owner                VARCHAR2(257) NOT NULL,
  table_name                 VARCHAR2(257) NOT NULL,
  column_name                VARCHAR2(4000),
  column_position            NUMBER NOT NULL,
  descend                    VARCHAR2(4)
);

GRANT ALL ON &&tool_repository_schema..trca$_ind_columns$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_ind_columns$ FOR &&tool_repository_schema..trca$_ind_columns$;

CREATE INDEX &&tool_repository_schema..trca$_ind_columns$_n1 ON &&tool_repository_schema..trca$_ind_columns$(index_name, index_owner);

/* ------------------------------------------------------------------------- */

-- indexed columns for trca$_index
CREATE TABLE &&tool_repository_schema..trca$_ind_columns (
  index_owner                VARCHAR2(257) NOT NULL,
  index_name                 VARCHAR2(257) NOT NULL,
  table_owner                VARCHAR2(257) NOT NULL,
  table_name                 VARCHAR2(257) NOT NULL,
  column_name                VARCHAR2(4000),
  column_position            NUMBER NOT NULL,
  descend                    VARCHAR2(4),
  -- trca
  tool_execution_id          INTEGER NOT NULL -- fk trca$_tool_execution.id
);

GRANT ALL ON &&tool_repository_schema..trca$_ind_columns TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_ind_columns FOR &&tool_repository_schema..trca$_ind_columns;

CREATE INDEX &&tool_repository_schema..trca$_ind_columns_n1 ON &&tool_repository_schema..trca$_ind_columns(tool_execution_id, index_owner, index_name);

/* ------------------------------------------------------------------------- */

-- external dict table generated by trca/dict/trcadictexp.sql in SOURCE
CREATE TABLE &&tool_repository_schema..trca_parameter2 (
  name                       VARCHAR2(255),
  value                      VARCHAR2(4000)
) ORGANIZATION EXTERNAL
( TYPE ORACLE_LOADER
  DEFAULT DIRECTORY TRCA$STAGE
  ACCESS PARAMETERS
( RECORDS DELIMITED BY 0x'0A'
  BADFILE 'TRCA_PARAMETER2.bad'
  LOGFILE 'TRCA_PARAMETER2.log'
  FIELDS TERMINATED BY ','
  MISSING FIELD VALUES ARE NULL
  REJECT ROWS WITH ALL NULL FIELDS
) LOCATION ('TRCA_PARAMETER2.txt')
);

GRANT ALL ON &&tool_repository_schema..trca_parameter2 TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca_parameter2 FOR &&tool_repository_schema..trca_parameter2;


/* ------------------------------------------------------------------------- */

-- dict snaphot of v$parameter2 seeded by trca$t.refresh_trca$_dict_from
CREATE TABLE &&tool_repository_schema..trca$_parameter2$ (
  name                       VARCHAR2(80),
  value                      VARCHAR2(4000)
);

GRANT ALL ON &&tool_repository_schema..trca$_parameter2$ TO &&tool_administer_schema.;
CREATE OR REPLACE SYNONYM &&tool_administer_schema..trca$_parameter2$ FOR &&tool_repository_schema..trca$_parameter2$;

/* ------------------------------------------------------------------------- */

WHENEVER SQLERROR CONTINUE;
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_control');
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_file');
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_segments');
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_extents_dm');
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_extents_lm');
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_objects');
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_tables');
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_indexes');
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_tab_cols');
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_ind_columns');
EXEC DBMS_STATS.LOCK_TABLE_STATS('&&tool_repository_schema.', 'trca_parameter2');
WHENEVER SQLERROR EXIT SQL.SQLCODE;

/* ------------------------------------------------------------------------- */

UNDEFINE ON_COMMIT_PRESERVE_ROWS GLOBAL_TEMPORARY TEMPORARY_OR_PERMANENT;
SET ECHO OFF TERM ON;
PRO TACOBJ completed.
