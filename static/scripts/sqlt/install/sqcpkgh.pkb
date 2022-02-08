CREATE OR REPLACE PACKAGE BODY &&tool_administer_schema..sqlt$h AS
/* $Header: 215187.1 sqcpkgh.pkb 19.0.190110 2019/01/10 Stelios.Charalambides@oracle.com carlos.sierra mauro.pagano abel.macias sachin.pawar $ */

  /*************************************************************************************/

  /* -------------------------
   *
   * private constants
   *
   * ------------------------- */
  ROLE_NAME            CONSTANT VARCHAR2(32) := '&&role_name.';
  PERCENT_FORMAT       CONSTANT VARCHAR2(32) := '99999990D00';
  E_GLOBAL             CONSTANT NUMBER := 01;
  E_EBS                CONSTANT NUMBER := 02;
  E_SIEBEL             CONSTANT NUMBER := 03;
  E_PSFT               CONSTANT NUMBER := 04;
  E_TABLE              CONSTANT NUMBER := 05;
  E_INDEX              CONSTANT NUMBER := 06;
  E_1COL_INDEX         CONSTANT NUMBER := 07;
  E_TABLE_PART         CONSTANT NUMBER := 08;
  E_INDEX_PART         CONSTANT NUMBER := 09;
  E_TABLE_COL          CONSTANT NUMBER := 10;

  NUL                  CONSTANT CHAR(1) := CHR(00);
  LOAD_DATE_FORMAT     CONSTANT VARCHAR2(32) := 'YYYY-MM-DD/HH24:MI:SS'; -- 2010-03-03/08:45:04

  /*************************************************************************************/

  /* -------------------------
   *
   * static variables
   *
   * ------------------------- */
  s_sql_rec sqlt$_sql_statement%ROWTYPE;
  s_obs_rec sqlg$_observation%ROWTYPE;

  /*************************************************************************************/

  /* -------------------------
   *
   * private write_log
   *
   * ------------------------- */
  PROCEDURE write_log (
    p_line_text IN VARCHAR2,
    p_line_type IN VARCHAR2 DEFAULT 'L' ) -- (L)og/(S)ilent/(E)rror/(P)rint
  IS
  BEGIN
    sqlt$a.write_log(p_line_text => p_line_text, p_line_type => p_line_type, p_package => 'H');
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
    sqlt$a.write_error('h:'||p_line_text);
  END write_error;

  /*************************************************************************************/

  /* -------------------------
   *
   * private ins_obs
   *
   * New column, priority added to s_obs_rec but priority NOT used in 
   * write_log. Stelios Charalambides. 10th Jan 2019.
   * Added unique ID to all observations. Not used at this point, only to link to SQLHC. 5th April 2019.
   *
   * ------------------------- */
  PROCEDURE ins_obs
  IS
  BEGIN
    SELECT sqlt$_line_id_s.NEXTVAL INTO s_obs_rec.line_id FROM DUAL;
    INSERT INTO sqlg$_observation VALUES s_obs_rec;
    write_log('typ:"'||s_obs_rec.type_id||'" lin:'||s_obs_rec.line_id||' obj:"'||s_obs_rec.object_type||'" nam:"'||s_obs_rec.object_name||'" obs:"'||s_obs_rec.observation||'"', 'S');
    s_obs_rec := NULL;
  END ins_obs;

  /*************************************************************************************/

  /* -------------------------
   *
   * private global_hc
   *
   * ------------------------- */
  PROCEDURE global_hc
  IS
    l_count NUMBER;
    l_count2 NUMBER; 
  BEGIN
    write_log('-> global_hc');

    -- XECUTE and ^^unique_id is missing
	-- (001)
    IF s_sql_rec.method = 'XECUTE' THEN
      IF s_sql_rec.sql_text_clob NOT LIKE '%sqlt_s'||sqlt$a.get_statement_id_c(s_sql_rec.statement_id)||'%' THEN
		s_obs_rec.priority	  := 5;
		s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'TOKEN';
        s_obs_rec.object_name := 'UNIQUE_ID';
        s_obs_rec.observation := 'Include the comment /* ^^unique_id */ in the next execution of SQLTXECUTE. See MOS Note FAQ: SQLT (SQLTXPLAIN) Frequently Asked Questions (Doc ID 1454160.1)';
        s_obs_rec.more        := 'To help SQLTXECUTE find the SQL in memory, the SQL should contain this comment: /* ^^unique_id */. SQL provided in "'||s_sql_rec.input_filename||'" does not have this comment. Please include it on next execution of SQLTXECUTE.';
        ins_obs;
      END IF;
    END IF;

    -- (002)
	-- 5969780 STATISTICS_LEVEL = ALL on LINUX
    IF s_sql_rec.rdbms_release < 11 AND
       s_sql_rec.platform LIKE '%LINUX%' AND
       UPPER(sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'statistics_level')) = 'ALL'
    THEN
      s_obs_rec.priority	:= 95;
	  s_obs_rec.type_id     := E_GLOBAL;
      s_obs_rec.object_type := 'CBO PARAMETER';
      s_obs_rec.object_name := 'STATISTICS_LEVEL';
      s_obs_rec.observation := 'Set the STATISTICS_LEVEL parameter to TYPICAL on '||s_sql_rec.platform||', unless you are diagnosing a performance problem and you have been asked by Oracle to set this parameter to ALL. See MOS Note Health Check Alert: Consider setting TIMED_STATISTICS and STATISTICS_LEVEL to recommended levels (Doc ID 957433.1)';
      s_obs_rec.more        := 'STATISTICS_LEVEL = ALL provides valuable metrics like A-Rows. Be aware of 5969780 CPU overhead. Use a value of ALL only at the session level. You could use CBO hint /*+ gather_plan_statistics */ to accomplish the same.';
      ins_obs;
    END IF;

    -- (003)
	-- gv$system_parameter (dba_hist_parameter) with modified values
    BEGIN
      SELECT COUNT(DISTINCT parameter_name)
        INTO l_count
        FROM sqlt$_dba_hist_parameter_v
       WHERE statement_id = s_sql_rec.statement_id;

      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 25;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'SYSTEM PARAMETER';
        s_obs_rec.object_name   := 'MODIFIED';
        IF l_count = 1 THEN
          s_obs_rec.observation := 'Review the modified system parameter mentioned to ensure it is needed. See https://docs.oracle.com/en/database/oracle/oracle-database/12.2/refrn/index.html';
          s_obs_rec.more        := 'Parameter value was modified either in the parameter file or with an ALTER SYSTEM command. Review <a href="#init_parameters_sys_mod">Modified System Parameters.</a>.';
        ELSE
          s_obs_rec.observation := 'Review the modified system parameters ('||l_count||' found), to ensure they are needed. See https://docs.oracle.com/en/database/oracle/oracle-database/12.2/refrn/index.html';
          s_obs_rec.more        := 'Parameter values were modified either in the parameter file or with an ALTER SYSTEM command. Review <a href="#init_parameters_sys_mod">Modified System Parameters.</a>.';
        END IF;
        ins_obs;
      END IF;
    END;

    -- (004)
	-- cbo parameters (non-default or modified)
    BEGIN
      SELECT COUNT(DISTINCT name)
        INTO l_count
        FROM sqlt$_gv$parameter_cbo
       WHERE statement_id = s_sql_rec.statement_id
         AND isdefault = 'FALSE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 35;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'CBO PARAMETER';
        s_obs_rec.object_name   := 'NON-DEFAULT';
        IF l_count = 1 THEN
          s_obs_rec.observation := 'Review the non-default CBO parameter mentioned to ensure it is needed. See https://docs.oracle.com/database/121/TGSQL/tgsql_influence.htm#TGSQL246';
          s_obs_rec.more        := 'Parameter value was specified in the parameter file. Review <a href="#cbo_env">CBO Environment.</a>.';
        ELSE
          s_obs_rec.observation := 'Review the non-default CBO parameters ('||l_count||' found), to ensure they are needed. See https://docs.oracle.com/database/121/TGSQL/tgsql_influence.htm#TGSQL246';
          s_obs_rec.more        := 'Parameter values were specified in the parameter file. Review <a href="#cbo_env">CBO Environment.</a>.';
        END IF;
        ins_obs;
      END IF;

      SELECT COUNT(DISTINCT name)
        INTO l_count
        FROM sqlt$_gv$parameter_cbo
       WHERE statement_id = s_sql_rec.statement_id
         AND ismodified <> 'FALSE';
      -- (005)
      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 35;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'CBO PARAMETER';
        s_obs_rec.object_name   := 'MODIFIED';
        IF l_count = 1 THEN
          s_obs_rec.observation := 'Review the modified CBO parameter to ensure it is needed. See https://docs.oracle.com/database/121/TGSQL/tgsql_influence.htm#TGSQL246';
          s_obs_rec.more        := 'Parameter has been modified after instance startup. Review <a href="#cbo_env">CBO Environment.</a>.';
        ELSE
          s_obs_rec.observation := 'Review the modified CBO parameters ('||l_count||' found), to ensure that they are needed. See https://docs.oracle.com/database/121/TGSQL/tgsql_influence.htm#TGSQL246';
          s_obs_rec.more        := 'Parameters have been modified after instance startup. Review <a href="#cbo_env">CBO Environment.</a>.';
        END IF;
        ins_obs;
      END IF;
    END;

    -- optimizer_features_enable <> rdbms_version
	-- (006)
    BEGIN
	--
	-- 18.0.0.0 ===> 18
	-- 12.1.0.2 ===> 12
	-- 9.2.0.8 ===> 9
	-- Only check to see if the Major version of OFE is less than the actual version 
	if replace(substr(sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'optimizer_features_enable'),0,2),'.') < replace(substr(s_sql_rec.rdbms_version,0,2),'.') then
    --  IF REPLACE(REPLACE(s_sql_rec.rdbms_version, '.'), '0') <> REPLACE(REPLACE(sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'optimizer_features_enable'), '.'), '0') THEN
    	s_obs_rec.priority	  := 45;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'CBO PARAMETER';
        s_obs_rec.object_name := 'OPTIMIZER_FEATURES_ENABLE';
        s_obs_rec.observation := 'Ensure that the OPTIMIZER_FEATURES_ENABLE parameter ('||sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'optimizer_features_enable')||') is set correctly as it does not match the DB version ('||s_sql_rec.rdbms_version||'). See MOS Note Use Caution if Changing the OPTIMIZER_FEATURES_ENABLE Parameter After an Upgrade (Doc ID 1362332.1)';
        s_obs_rec.more        := 'Be aware that you are attempting to the Optimizer to previous behavior. New CBO features in your DB version may not be used.';
        ins_obs;
--      ELSE
--        SELECT COUNT(*)
--          INTO l_count
--          FROM sqlt$_gv$sql_optimizer_env
--         WHERE statement_id = s_sql_rec.statement_id
--           AND LOWER(name) = 'optimizer_features_enable'
--           AND REPLACE(REPLACE(value, '.'), '0') <> REPLACE(REPLACE(s_sql_rec.rdbms_version, '.'), '0');
    -- (006a)
--        IF l_count > 0 THEN
--          s_obs_rec.priority    := 45;
--	      s_obs_rec.type_id     := E_GLOBAL;
--          s_obs_rec.object_type := 'CBO PARAMETER';
--          s_obs_rec.object_name := 'OPTIMIZER_FEATURES_ENABLE';
--          s_obs_rec.observation := 'Ensure that the OPTIMIZER_FEATURES_ENABLE parameter ('||sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'optimizer_features_enable')||') is set correctly as it does not match the DB version ('||s_sql_rec.rdbms_version||'). See MOS Note Use Caution if Changing the OPTIMIZER_FEATURES_ENABLE Parameter After an Upgrade (Doc ID 1362332.1)';
--          s_obs_rec.more        := 'Be aware that you are using a prior version of the optimizer. New CBO features in your DB version may not be used.';
--          ins_obs;
--        END IF;
      END IF;
    END;

    -- (007)
	-- optimizer_dynamic_sampling between 1 and 3
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_all_tables_v
       WHERE statement_id = s_sql_rec.statement_id
         AND (last_analyzed IS NULL OR num_rows IS NULL);

      IF l_count > 0 THEN
        IF TO_NUMBER(sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'optimizer_dynamic_sampling')) BETWEEN 1 AND 3 THEN
          s_obs_rec.priority	:= 60;
	      s_obs_rec.type_id     := E_GLOBAL;
          s_obs_rec.object_type := 'CBO PARAMETER';
          s_obs_rec.object_name := 'OPTIMIZER_DYNAMIC_SAMPLING';
          s_obs_rec.observation := 'Consider if you need to increase the value of OPTIMIZER_DYNAMIC_SAMPLING from '||sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'optimizer_dynamic_sampling')||' to a higher value as some objects in this query have no statistics. See the MOS Note Optimizer Dynamic Statistics (OPTIMIZER_DYNAMIC_SAMPLING) (Doc ID 336267.1)';
          s_obs_rec.more        := 'Be aware that using such a small value may produce statistics of poor quality. If you rely on this functionality consider using a value no smaller than 4.';
          ins_obs;
        ELSE
          SELECT COUNT(*)
            INTO l_count
            FROM sqlt$_gv$sql_optimizer_env
           WHERE statement_id = s_sql_rec.statement_id
             AND LOWER(name) = 'optimizer_dynamic_sampling'
             AND value BETWEEN '1' AND '3'
             AND value <> '10';

          IF l_count > 0 THEN
    	    s_obs_rec.priority	  := 60;
	        s_obs_rec.type_id     := E_GLOBAL;
            s_obs_rec.object_type := 'CBO PARAMETER';
            s_obs_rec.object_name := 'OPTIMIZER_DYNAMIC_SAMPLING';
            s_obs_rec.observation := 'Consider if you need to increase the value of OPTIMIZER_DYNAMIC_SAMPLING from '||sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'optimizer_dynamic_sampling')||' to a higher value as some objects in this query have no statistics. See the MOS Note Optimizer Dynamic Statistics (OPTIMIZER_DYNAMIC_SAMPLING) (Doc ID 336267.1)';
            s_obs_rec.more        := 'Be aware that using such a small value may produce statistics of poor quality. If you rely on this functionality consider using a value no smaller than 4.';
            ins_obs;
          END IF;
        END IF;
      END IF;
    END;

    -- (008) 
	-- db_file_multiblock_read_count should not be set
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_gv$parameter2
       WHERE statement_id = s_sql_rec.statement_id
         AND LOWER(name) = 'db_file_multiblock_read_count'
         AND (isdefault = 'FALSE' OR ismodified <> 'FALSE');

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 65;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'CBO PARAMETER';
        s_obs_rec.object_name := 'DB_FILE_MULTIBLOCK_READ_COUNT';
        s_obs_rec.observation := 'Check if DB_FILE_MULTIBLOCK_READ_COUNT is set correctly as this is automatically calculated by Oracle. See MOS note How is Parameter DB_FILE_MULTIBLOCK_READ_COUNT Calculated? (Doc ID 1398860.1)';
        s_obs_rec.more        := 'The default value of this parameter is a value that corresponds to the maximum I/O size that can be performed efficiently. This value is platform-dependent and is 1MB for most platforms. Because the parameter is expressed in blocks, it will be set to a value that is equal to the maximum I/O size that can be performed efficiently divided by the standard block size.';
        ins_obs;
      END IF;
    END;

    -- (009)
	-- nls_sort is not binary
    BEGIN
      IF UPPER(s_sql_rec.nls_sort) <> 'BINARY' THEN
    	s_obs_rec.priority	  := 70;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'NLS PARAMETER';
        s_obs_rec.object_name := 'NLS_SORT';
        s_obs_rec.observation := 'Set NLS_SORT to "BINARY" as recommended in MOS note Init.ora Parameter "NLS_SORT" Reference Note (Doc ID 30779.1).';
        s_obs_rec.more        := 'Setting NLS_SORT to anything other than BINARY causes a sort to use a full table scan, regardless of the path chosen by the optimizer.';
        ins_obs;
      END IF;
    END;

    -- (010)
	-- optimizer_secure_view_merging
    BEGIN
      IF UPPER(sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'optimizer_secure_view_merging')) = 'TRUE' THEN
        l_count := 1;
      ELSE
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_gv$sql_optimizer_env
         WHERE statement_id = s_sql_rec.statement_id
           AND LOWER(name) = 'optimizer_secure_view_merging'
           AND UPPER(value) = 'TRUE';
      END IF;

      IF l_count > 0 THEN
        FOR i IN (SELECT parsing_schema_name username FROM sqlt$_gv$sqlarea WHERE statement_id = s_sql_rec.statement_id
                  UNION
                  SELECT parsing_schema_name username FROM sqlt$_gv$sqlarea_plan_hash WHERE statement_id = s_sql_rec.statement_id
                  UNION
                  SELECT parsing_schema_name username FROM sqlt$_gv$sql WHERE statement_id = s_sql_rec.statement_id
                  UNION
                  SELECT parsing_schema_name username FROM sqlt$_dba_hist_sqlstat WHERE statement_id = s_sql_rec.statement_id
                  UNION
                  SELECT parsing_schema_name username FROM sqlt$_dba_sql_plan_baselines WHERE statement_id = s_sql_rec.statement_id)
        LOOP
          l_count := 0;

          IF i.username IS NOT NULL THEN
            SELECT COUNT(*)
              INTO l_count
              FROM sqlt$_metadata
             WHERE statement_id = s_sql_rec.statement_id
               AND object_type = 'VIEW'
               AND owner <> i.username;

            IF l_count > 0 THEN
    	      s_obs_rec.priority	:= 54;
	          s_obs_rec.type_id     := E_GLOBAL;
              s_obs_rec.object_type := 'CBO PARAMETER';
              s_obs_rec.object_name := 'OPTIMIZER_SECURE_VIEW_MERGING';
              s_obs_rec.observation := 'Check the applicability of OPTIMIZER_SECURE_VIEW_MERGING as there are Views not owned by the parsing schema. See MOS note Different Execution Plan and Performance from Different Users When OPTIMIZER_SECURE_VIEW_MERGING is Enabled (Doc ID 371581.1)';
              s_obs_rec.more        := 'Oracle performs checks to ensure that view merging and predicate move-around do not violate any security intentions of the view creator. A side effect of this feature is that some views will not be merged producing sub-optimal plans.';
              ins_obs;
              EXIT;
            END IF;
          END IF;
        END LOOP;
      END IF;
    END;

    -- (011)
	-- Bug 6356566 ORA-03113 using V$SQL_PLAN
    IF UPPER(sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, '_cursor_plan_unparse_enabled')) = 'FALSE' THEN
      s_obs_rec.priority	:= 20;
	  s_obs_rec.type_id     := E_GLOBAL;
      s_obs_rec.object_type := 'PARAMETER';
      s_obs_rec.object_name := '_CURSOR_PLAN_UNPARSE_ENABLED';
      s_obs_rec.observation := 'Ensure you want _CURSOR_PLAN_UNPARSE_ENABLED set to FALSE or upgrade to 10.2.0.4 or above. See MOS Note Bug 6356566 - Memory leak / high CPU selecting from V$SQL_PLAN (affects statspack) (Doc ID 6356566.8)';
      s_obs_rec.more        := 'Be aware of Bug 6356566. SQLT uses ALTER SESSION SET "_cursor_plan_unparse_enabled" = FALSE to workaround Bug 6356566. Review ALERT.LOG and trace(s) referencing ORA-03113, ORA-03114 or ORA-07445. You may want to pursue a fix for Bug 6356566 with Support.';
      ins_obs;
    END IF;

    -- (012)
	-- _optim_peek_user_binds is TRUE, binds have been captured, but peeked binds are missing
    BEGIN
      IF UPPER(s_sql_rec.optim_peek_user_binds) = 'TRUE' THEN
        FOR i IN (SELECT cbv.plan_hash_value, cbv.child_number
                    FROM sqlt$_captured_binds_v cbv
                   WHERE cbv.statement_id = s_sql_rec.statement_id
                     AND cbv.source = 'GV$SQL_PLAN'
                     AND cbv.value IS NOT NULL
                     AND cbv.value <> 'NULL'
                     AND EXISTS (
                  SELECT NULL
                    FROM sqlt$_gv$sql_plan sqp
                   WHERE sqp.statement_id = s_sql_rec.statement_id
                     AND sqp.inst_id = cbv.inst_id
                     AND sqp.plan_hash_value = cbv.plan_hash_value
                     AND sqp.child_number = cbv.child_number
                  )
                   MINUS
                  SELECT plan_hash_value, child_number
                    FROM sqlt$_peeked_binds_v
                   WHERE statement_id = s_sql_rec.statement_id
                     AND source = 'GV$SQL_PLAN'
                     AND value IS NOT NULL
                     AND value <> 'NULL')
        LOOP
    	  s_obs_rec.priority    := 48;
	      s_obs_rec.type_id     := E_GLOBAL;
          s_obs_rec.object_type := 'BINDS';
          s_obs_rec.object_name := '_OPTIM_PEEK_USER_BINDS';
          s_obs_rec.observation := 'Check for application flaws as Peeked Binds are missing for Child cursor '||i.child_number||' on Plan '||i.plan_hash_value||'. See MOS Note Query Using Bind Variables Suddenly Starts to Perform Slowly (Doc ID 387394.1)';
          s_obs_rec.more        := 'There are Captured Binds for this Child. Review <a href="#pln_exe">Execution Plans</a>. This could be an application flaw. Be aware also of Bug 5364143.';
          ins_obs;
        END LOOP;
      END IF;
    END;

	-- (013)
	-- 150826 new checks for 10g and 11g and newer version.
	IF s_sql_rec.rdbms_release < 11 THEN
      -- SQLT$UDUMP <> USER_DUMP_DEST
      IF sqlt$a.get_udump_path <> sqlt$a.get_v$parameter('user_dump_dest') AND
         sqlt$a.get_v$parameter('user_dump_dest') NOT LIKE '%?%' AND
         sqlt$a.get_v$parameter('user_dump_dest') NOT LIKE '%*%' AND
         sqlt$a.s_db_link IS NULL
      THEN
    	s_obs_rec.priority	  := 12;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'DIRECTORY';
        s_obs_rec.object_name := 'SQLT$UDUMP';
        s_obs_rec.observation := 'Run sys.sqlt$_trca$_dir_set as SYS to set SQLT$UDUMP and USER_DUMP_DEST to the same location. See MOS note SQLT Changes (Doc ID 1614201.1)';
        s_obs_rec.more        := 'SQLT$UDUMP "'||sqlt$a.get_udump_path||'" and USER_DUMP_DEST "'||sqlt$a.get_v$parameter('user_dump_dest')||'" should match for SQLT to find traces';
        ins_obs;
      END IF;
      
      -- SQLT$BDUMP <> BACKGROUND_DUMP_DEST
      IF sqlt$a.get_bdump_path <> sqlt$a.get_v$parameter('background_dump_dest') AND
         sqlt$a.get_v$parameter('background_dump_dest') NOT LIKE '%?%' AND
         sqlt$a.get_v$parameter('background_dump_dest') NOT LIKE '%*%' AND
         sqlt$a.s_db_link IS NULL
      THEN
    	s_obs_rec.priority	  := 12;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'DIRECTORY';
        s_obs_rec.object_name := 'SQLT$BDUMP';
        s_obs_rec.observation := 'Run sys.sqlt$_trca$_dir_set as SYS to set SQLT$BDUMP and BACKGROUND_DUMP_DEST to the same location. See MOS note SQLT Changes (Doc ID 1614201.1)';
        s_obs_rec.more        := 'SQLT$BDUMP "'||sqlt$a.get_bdump_path||'" and BACKGROUND_DUMP_DEST "'||sqlt$a.get_v$parameter('background_dump_dest')||'" should match for SQLT to find traces';
        ins_obs;
      END IF;
	ELSE
	 IF (sqlt$a.get_bdump_path <> sqlt$a.get_diag_path or sqlt$a.get_udump_path <> sqlt$a.get_diag_path)
	     and sqlt$a.s_db_link IS NULL
     THEN
    	s_obs_rec.priority	  := 12;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'DIRECTORY';
        s_obs_rec.object_name := 'DIAG';
        s_obs_rec.observation := 'Run sys.sqlt$_trca$_dir_set as SYS to set SQLT$UDUMP and/or SQLT$BDUMP to the same location as BACKGROUND_DUMP_DEST. See MOS note SQLT Changes (Doc ID 1614201.1)';
        s_obs_rec.more        := 'SQLT$UDUMP "'||sqlt$a.get_udump_path||'" and SQLT$BDUMP "'||sqlt$a.get_bdump_path||'" should point to "'||sqlt$a.get_diag_path||'" for SQLT to find traces';
        ins_obs;	  
	 END IF;
    END IF;
	
    -- (014)
	-- SYS.DBMS_STATS AUTOMATIC GATHERING on 10g
    IF s_sql_rec.rdbms_release < 11 THEN
      DECLARE
        job_rec sqlt$_dba_scheduler_jobs%ROWTYPE;
      BEGIN
        SELECT * INTO job_rec FROM sqlt$_dba_scheduler_jobs WHERE statement_id = s_sql_rec.statement_id AND ROWNUM = 1;

        IF job_rec.enabled = 'TRUE' THEN
    	  s_obs_rec.priority	:= 74;
	      s_obs_rec.type_id     := E_GLOBAL;
          s_obs_rec.object_type := 'DBMS_STATS';
          s_obs_rec.object_name := 'DBA_SCHEDULER_JOBS';

          IF s_sql_rec.siebel = 'YES' THEN
            s_obs_rec.observation := 'Disable DBA_SCHEDULER_JOBS immediately and re-gather statistics for all affected schemas using coe_siebel_stats. See MOS Doc ID 781927.1';
            s_obs_rec.more      := 'Disable this job immediately and re-gather statistics for all affected schemas using coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
          ELSIF s_sql_rec.psft = 'YES' THEN
            s_obs_rec.observation := 'Disable DBA_SCHEDULER_JOBS immediately and re-gather statistics for all affected schemas using pscbo_stats.sql. See MOS Doc ID 1322888.1.';
            s_obs_rec.more      := 'Disable this job immediately and re-gather statistics for all affected schemas using pscbo_stats.sql. See MOS Doc ID 1322888.1.';
          ELSIF s_sql_rec.apps_release IS NOT NULL THEN
            s_obs_rec.observation := 'Disable DBA_SCHEDULER_JOBS immediately and re-gather statistics for all affected schemas using FND_STATS or coe_stats.sql. See MOS Doc ID 156968.1.';
            s_obs_rec.more      := 'Disable this job immediately and re-gather statistics for all affected schemas using FND_STATS or coe_stats.sql. See MOS Doc ID 156968.1.';
          ELSE
            s_obs_rec.more      := 'Be aware that small sample sizes could produce poor quality histograms, which combined with bind sensitive predicates could render suboptimal plans. See MOS Doc ID 465787.1.';
          END IF;
          ins_obs;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('DBMS_STATS AUTOMATIC GATHERING on 10g: '||SQLERRM);
      END;
    END IF;

    -- (015) 
	-- SYS.DBMS_STATS AUTOMATIC GATHERING on 11g
    IF s_sql_rec.rdbms_release >= 11 THEN
      DECLARE
        tsk_rec sqlt$_dba_autotask_client%ROWTYPE;
      BEGIN
        SELECT * INTO tsk_rec FROM sqlt$_dba_autotask_client WHERE statement_id = s_sql_rec.statement_id AND ROWNUM = 1;

        IF tsk_rec.status = 'ENABLED' THEN
    	  s_obs_rec.priority	  := 66;
	      s_obs_rec.type_id     := E_GLOBAL;
          s_obs_rec.object_type := 'DBMS_STATS';
          s_obs_rec.object_name := 'DBA_AUTOTASK_CLIENT';
          
          IF s_sql_rec.siebel = 'YES' THEN
		    s_obs_rec.observation := 'Disable DBMS_STATS Automatic gathering of CBO statisitcs and re-gather using coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
            s_obs_rec.more      := 'Disable this job immediately and re-gather statistics for all affected schemas using coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
          ELSIF s_sql_rec.psft = 'YES' THEN
		    s_obs_rec.observation := 'Disable DBMS_STATS Automatic gathering of CBO statistics and re-gather using pscbo_stats.sql. See MOS Doc ID 1322888.1.';
            s_obs_rec.more      := 'Disable this job immediately and re-gather statistics for all affected schemas using pscbo_stats.sql. See MOS Doc ID 1322888.1.';
          ELSIF s_sql_rec.apps_release IS NOT NULL THEN
		    s_obs_rec.observation := 'Disable DBMS_STATS Automatic gathering of CBO statistics and re-gather using FND_STATS or coe_stats.sql. See MOS Doc ID 465787.1';
            s_obs_rec.more      := 'Disable this job immediately and re-gather statistics for all affected schemas using FND_STATS or coe_stats.sql. See MOS Doc ID 465787.1.';
          ELSE
		    s_obs_rec.observation := 'Ensure DBMS_STATS Automatic gathering sample size is sufficient. See MOS note How to: Manage CBO Statistics During an Upgrade from 10g or 9i into 11g/12c (Doc ID 465787.1)';
            s_obs_rec.more      := 'Be aware that small sample sizes could produce poor quality histograms, which combined with bind sensitive predicates could render suboptimal plans. See MOS Doc ID 465787.1.';
          END IF;
          ins_obs;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('DBMS_STATS AUTOMATIC GATHERING on 11g: '||SQLERRM);
      END;
    END IF;
	
    -- (016)
	-- 12.1.06 Automatic job enabled in 11g but not running for some reason
    IF s_sql_rec.rdbms_release >= 11 THEN
      DECLARE
        tsk_rec sqlt$_dba_autotask_client%ROWTYPE;
      BEGIN
        SELECT * INTO tsk_rec FROM sqlt$_dba_autotask_client WHERE statement_id = s_sql_rec.statement_id AND ROWNUM = 1;
		
		SELECT count(*)
		  INTO l_count
		  FROM sqlt$_dba_autotask_client_hst
         WHERE client_name like '%stats%' 
           AND window_start_time > (SYSDATE-8);

        IF tsk_rec.status = 'ENABLED' AND l_count = 0 THEN
    	  s_obs_rec.priority	:= 76;
	      s_obs_rec.type_id     := E_GLOBAL;
          s_obs_rec.object_type := 'DBMS_STATS';
          s_obs_rec.object_name := 'DBA_AUTOTASK_CLIENT_HISTORY';
          s_obs_rec.observation := 'Ensure the automated statistics jobs are executing as expected. See MOS Note Troubleshooting Scheduler Autotask Issues (Doc ID 1561498.1)';
          s_obs_rec.more        := 'The job is enabled in the system but there is no evidence it was ever executed in the last 8 days';
          ins_obs;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('DBMS_STATS AUTOMATIC GATHERING NOT RUNNING on 11g: '||SQLERRM);
      END;
    END IF;	
	
    -- (017)
	-- 12.1.06 Automatic job enabled in 11g but some jobs did not complete
    IF s_sql_rec.rdbms_release >= 11 THEN
      DECLARE
        tsk_rec sqlt$_dba_autotask_client%ROWTYPE;
      BEGIN
        SELECT * INTO tsk_rec FROM sqlt$_dba_autotask_client WHERE statement_id = s_sql_rec.statement_id AND ROWNUM = 1;
		
		SELECT count(*)
		  INTO l_count
		  FROM sqlt$_dba_autotask_client_hst
         WHERE client_name like '%stats%' 
           AND window_start_time > (SYSDATE-8)
		   AND (jobs_created-jobs_started > 0 OR jobs_started-jobs_completed > 0);

        IF tsk_rec.status = 'ENABLED' AND l_count <> 0 THEN
    	  s_obs_rec.priority	:= 82;
	      s_obs_rec.type_id     := E_GLOBAL;
          s_obs_rec.object_type := 'DBMS_STATS';
          s_obs_rec.object_name := 'DBA_AUTOTASK_CLIENT_HISTORY';
          s_obs_rec.observation := 'Ensure the automated statistics jobs are executing as expected. See MOS Note Troubleshooting Scheduler Autotask Issues (Doc ID 1561498.1)';
          s_obs_rec.more        := 'The job is enabled in the system but there are some jobs in the last 8 days that did not complete';
          ins_obs;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          write_log('DBMS_STATS AUTOMATIC GATHERING NOT COMPLETING on 11g: '||SQLERRM);
      END;
    END IF;		
	

    -- (018)
	-- plans count
    BEGIN
      SELECT COUNT(DISTINCT plan_hash_value)
        INTO l_count
        FROM sqlt$_plan_summary_v
       WHERE statement_id = s_sql_rec.statement_id;

      s_obs_rec.priority	  := 23;
	  s_obs_rec.type_id       := E_GLOBAL;
      s_obs_rec.object_type   := 'PLAN';
      s_obs_rec.object_name   := 'PLAN_HASH_VALUE';

      IF l_count = 0 THEN
        s_obs_rec.observation := 'No plans were found for this SQL. The query needs to run before an Execution plan can be generated. See MOS Note How to Obtain a Formatted Explain Plan - Recommended Methods (Doc ID 235530.1)';
      ELSIF l_count = 1 THEN
        s_obs_rec.observation := 'Ensure that you expect only one execution plan for this SQL.';
        s_obs_rec.more        := 'Review <a href="#pln_exe">Execution Plans</a>.';
      ELSE
        s_obs_rec.observation := l_count||' plans were found for this SQL. Ensure that you expect multiple execution plans for this SQL. ';
        s_obs_rec.more        := 'Review <a href="#pln_sum">Plans Summary</a>.';
      END IF;
      ins_obs;
    END;

    -- (019)
	-- plan control
    BEGIN
      SELECT COUNT(DISTINCT plan_hash_value)
        INTO l_count
        FROM sqlt$_plan_info
       WHERE statement_id = s_sql_rec.statement_id
         AND info_type IN ('sql_profile', 'sql_patch', 'baseline', 'outline');
		 
	  s_obs_rec.priority	  := 22;
      s_obs_rec.type_id       := E_GLOBAL;
      s_obs_rec.object_type   := 'PLAN CONTROL';
      s_obs_rec.object_name   := 'PLAN_CONTROL';

      IF l_count = 0 THEN
        s_obs_rec.observation := 'No action needed. None of the plans found was created using one of these: Stored Outline, SQL Profile, SQL Patch or SQL Plan Baseline.';
      ELSIF l_count = 1 THEN
        s_obs_rec.observation := 'Stored Outlines, SQL Profiles, SQL Patch and SQL Plan Baselines should be viewed as temporary measures. Determine the reason for these and collect statistics appropriately.';
        s_obs_rec.more        := 'Review <a href="#pln_exe">Execution Plans</a>.';
      ELSE
        s_obs_rec.observation := l_count||' plans were created using one of these: Stored Outline, SQL Profile, SQL Patch or SQL Plan Baseline. These should be viewed as temporary measures. Determine the reason for these and collect statistics appropriately';
        s_obs_rec.more        := 'Review <a href="#pln_exe">Execution Plans</a>.';
      END IF;
      ins_obs;
    END;

    -- (020) 
	-- baseline with non reproducible plans
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_sql_plan_baselines
       WHERE statement_id = s_sql_rec.statement_id
         AND reproduced = 'NO';

      IF l_count > 0 THEN
	    s_obs_rec.priority	  := 37;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'PLAN';
        s_obs_rec.object_name := 'SQL_PLAN_BASELINE';
        s_obs_rec.observation := 'Review the SQL Plan Baseline which is not reproducible ('||l_count||' non-reproduceable Plan(s)). See MOS Note FAQ: SQL Plan Management (SPM) Frequently Asked Questions (Doc ID 1524658.1)';
        s_obs_rec.more        := 'Review <a href="#baselines">SQL Plan Baselines</a>.If a baseline is non-reproducible, then that means that the plan in the baseline cannot be reproduced by the optimizer.<br>Something is preventing the optimizer from generating the original plan – check for errors or other reasons why it might not be possible to generate the plan.';
        ins_obs;
      END IF;
    END;

    -- (021)
	-- plan history and baseline size
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_sql_plan_baselines
       WHERE statement_id = s_sql_rec.statement_id;

      IF l_count > 0 THEN
        SELECT COUNT(*)
          INTO l_count2
          FROM sqlt$_dba_sql_plan_baselines
         WHERE statement_id = s_sql_rec.statement_id
           AND NVL(reproduced, 'YES') = 'YES'
           AND enabled = 'YES'
           AND accepted = 'YES';

    	s_obs_rec.priority	  := 48;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'PLAN';
        s_obs_rec.object_name := 'SQL_PLAN_BASELINE';
        
        IF l_count2 = 0 THEN
		  s_obs_rec.observation := 'Review the SQL Plan Baseline as at least one Baseline is empty. SQL Plan History contains '||l_count||' Plan(s). '||l_count2||' is/are reproduced and enabled and accepted (actual SQL Plan Baseline). See MOS Note FAQ: SQL Plan Management (SPM) Frequently Asked Questions (Doc ID 1524658.1)';
          s_obs_rec.more      := 'Your SQL Plan Baseline is empty. Review <a href="#baselines">SQL Plan Baselines</a>.';
        ELSE
		  s_obs_rec.observation := 'Review the SQL Plan Baseline for applicability. SQL Plan History contains '||l_count||' Plan(s). '||l_count2||' is/are reproduced and enabled and accepted (actual SQL Plan Baseline).';
          s_obs_rec.more      := 'Review <a href="#baselines">SQL Plan Baselines</a>.';
        END IF;

        ins_obs;
      END IF;
    END;

    -- (022)
	-- sql profile and vpd
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_sql_profiles
       WHERE statement_id = s_sql_rec.statement_id
         AND status = 'ENABLED';

      IF l_count > 0 THEN
        SELECT COUNT(*)
          INTO l_count2
          FROM sqlt$_gv$vpd_policy
         WHERE statement_id = s_sql_rec.statement_id;

        IF l_count2 > 0 THEN
    	  s_obs_rec.priority	:= 27;
	      s_obs_rec.type_id     := E_GLOBAL;
          s_obs_rec.object_type := 'PROFILE AND VPD';
          s_obs_rec.object_name := 'SQL_PROFILE';
          s_obs_rec.observation := 'Check your Profile for applicability with a VPD policy in place. There are '||l_count2||' VPD policies. See MOS Note A SQL Profile Is Not Consistently Fixing a Performance Problem When VPD Is In Use (Doc ID 1440205.1)';
          s_obs_rec.more        := 'Be aware that combination of a SQL Profile and a VPD may render unstable Plans. Hints on SQL Profile may be partially implemented and Plan may change.';
          ins_obs;
        ELSE
          SELECT COUNT(*)
            INTO l_count2
            FROM sqlt$_dba_policies
           WHERE statement_id = s_sql_rec.statement_id;

          IF l_count2 > 0 THEN
		    s_obs_rec.priority	  := 24;
            s_obs_rec.type_id     := E_GLOBAL;
            s_obs_rec.object_type := 'PROFILE AND POLICIES';
            s_obs_rec.object_name := 'SQL_PROFILE';
            s_obs_rec.observation := 'Check the SQL Profile(s) for applicability. There are '||l_count2||' policies. See MOS Note Automatic SQL Tuning and SQL Profiles (Doc ID 271196.1)';
            s_obs_rec.more        := 'Be aware that combination of a SQL Profile and policies may render unstable Plans. Hints on SQL Profile may be partially implemented and Plan may change.';
            ins_obs;
          ELSE
            SELECT COUNT(*)
              INTO l_count2
              FROM sqlt$_dba_audit_policies
             WHERE statement_id = s_sql_rec.statement_id;

            IF l_count2 > 0 THEN
              s_obs_rec.priority	:= 24;
	          s_obs_rec.type_id     := E_GLOBAL;
              s_obs_rec.object_type := 'PROFILE AND AUDIT POLICIES';
              s_obs_rec.object_name := 'SQL_PROFILE';
              s_obs_rec.observation := 'Check the SQL Profile(s) for applicability in the presence of Audit policies. There are '||l_count2||' audit policies that may affect your SQL.';
              s_obs_rec.more        := 'Be aware that combination of a SQL Profile and audit policies may render unstable Plans. Hints on SQL Profile may be partially implemented and Plan may change.';
              ins_obs;
            END IF;
          END IF;
        END IF;
      END IF;
    END;

    -- (023)
	-- multiple CBO environments in SQL Area
    BEGIN
      SELECT COUNT(DISTINCT optimizer_env_hash_value)
        INTO l_count
        FROM sqlt$_gv$sqlarea_plan_hash
       WHERE statement_id = s_sql_rec.statement_id;

      IF l_count > 1 THEN
    	s_obs_rec.priority	  := 71;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'PLAN';
        s_obs_rec.object_name := 'OPTIMIZER_ENV';
        s_obs_rec.observation := 'Check the applicability of having multiple CBO environmets set up for one SQL. SQL references '||l_count||' distinct CBO Environments. See https://docs.oracle.com/database/121/REFRN/GUID-2B9340D7-4AA8-4894-94C0-D5990F67BE75.htm#REFRN30246';
        s_obs_rec.more        := 'Distinct CBO Environments may produce different Plans. Review <a href="#pln_sum">Plans Summary</a>.';
        ins_obs;
      ELSE
        -- (023a)
		-- multiple CBO environments in GV$SQL
        BEGIN
          SELECT COUNT(DISTINCT optimizer_env_hash_value)
            INTO l_count
            FROM sqlt$_gv$sql
           WHERE statement_id = s_sql_rec.statement_id;

          IF l_count > 1 THEN
        	s_obs_rec.priority	  := 71;
	        s_obs_rec.type_id     := E_GLOBAL;
            s_obs_rec.object_type := 'PLAN';
            s_obs_rec.object_name := 'OPTIMIZER_ENV';
            s_obs_rec.observation := 'Check the applicability of having multiple CBO environmets set up for one SQL. GV$SQL references '||l_count||' distinct CBO Environments. https://docs.oracle.com/database/121/REFRN/GUID-2B9340D7-4AA8-4894-94C0-D5990F67BE75.htm#REFRN30246';
            s_obs_rec.more        := 'Distinct CBO Environments may produce different Plans. Review <a href="#pln_exe">Execution Plans</a>.';
            ins_obs;
          ELSE
            -- (023b)
			-- multiple CBO environments in AWR
            BEGIN
              SELECT COUNT(DISTINCT optimizer_env_hash_value)
                INTO l_count
                FROM sqlt$_dba_hist_sqlstat
               WHERE statement_id = s_sql_rec.statement_id;

              IF l_count > 1 THEN
            	s_obs_rec.priority	  := 72;
	            s_obs_rec.type_id     := E_GLOBAL;
                s_obs_rec.object_type := 'PLAN';
                s_obs_rec.object_name := 'OPTIMIZER_ENV';
                s_obs_rec.observation := 'Check the applicability of having multiple CBO environmets set up for one SQL. AWR references '||l_count||' distinct CBO Environments.  https://docs.oracle.com/database/121/REFRN/GUID-2B9340D7-4AA8-4894-94C0-D5990F67BE75.htm#REFRN30246';
                s_obs_rec.more        := 'Distinct CBO Environments may produce different Plans. Review <a href="#pln_his_delta">Plan Performance History</a>.';
                ins_obs;
              END IF;
            END;
          END IF;
        END;
      END IF;
    END;
	
    -- (024)
	-- multiple plans with same PHV but different predicate ordering
    BEGIN
      FOR i IN (WITH d AS (
                  SELECT sql_id,
                         plan_hash_value,
                         id,
                         COUNT(DISTINCT access_predicates) distinct_access_predicates,
                         COUNT(DISTINCT filter_predicates) distinct_filter_predicates
                    FROM sqlt$_gv$sql_plan
                   WHERE statement_id = s_sql_rec.statement_id
                     AND sql_id = s_sql_rec.sql_id
                   GROUP BY
                         sql_id,
                         plan_hash_value,
                         id
                  HAVING MIN(NVL(access_predicates, 'X')) != MAX(NVL(access_predicates, 'X'))
                      OR MIN(NVL(filter_predicates, 'X')) != MAX(NVL(filter_predicates, 'X'))
                  )
                  SELECT v.plan_hash_value,
                         v.id,
                         'access' type,
                         v.inst_id,
                         v.child_number,
                         v.access_predicates predicates
                    FROM d,
                         sqlt$_gv$sql_plan v
                   WHERE v.statement_id = s_sql_rec.statement_id
                     AND v.sql_id = d.sql_id
                     AND v.plan_hash_value = d.plan_hash_value
                     AND v.id = d.id
                     AND d.distinct_access_predicates > 1
                   UNION ALL
                  SELECT v.plan_hash_value,
                         v.id,
                         'filter' type,
                         v.inst_id,
                         v.child_number,
                         v.filter_predicates predicates
                    FROM d,
                         sqlt$_gv$sql_plan v
                   WHERE v.statement_id = s_sql_rec.statement_id
                     AND v.sql_id = d.sql_id
                     AND v.plan_hash_value = d.plan_hash_value
                     AND v.id = d.id
                     AND d.distinct_filter_predicates > 1
                   ORDER BY
                         1, 2, 3, 6, 4, 5 )
      LOOP
    	s_obs_rec.priority	  := 75;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'PLAN';
        s_obs_rec.object_name := 'PREDICATES ORDERING';
        s_obs_rec.observation := 'Check '||i.plan_hash_value||' Step '||i.id||' predicates '||i.predicates||' to make sure the Predicate ordering is correct. See MOS Note Query Performance is influenced by its predicate order (Doc ID 276877.1)';
        s_obs_rec.more        := 'Different ordering in the predicates for '||i.plan_hash_value||' can affect the performance of this SQL,focus on Step ID '||i.id||' predicates '||i.predicates||'';
        ins_obs;
      END LOOP;
    END;	
	

    -- (025)
	-- plans with implicit data_type conversion
    BEGIN
      FOR i IN (SELECT DISTINCT plan_hash_value
                  FROM sqlt$_plan_extension
                 WHERE statement_id = s_sql_rec.statement_id
                   AND filter_predicates LIKE '%INTERNAL_FUNCTION%'
                 ORDER BY 1)
      LOOP
    	s_obs_rec.priority	  := 87;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'PLAN';
        s_obs_rec.object_name := 'PLAN_HASH_VALUE';
        s_obs_rec.observation := 'Check the applicability of the function causing and INTERNAL_FUNCTION in the Filter Predicates of PHV '||i.plan_hash_value||'. See MOS Note Index on a Timestamp Column Cannot be Accessed Properly (Doc ID 1321016.1)';
        s_obs_rec.more        := 'Review <a href="#pln_sum">Plans Summary</a>. If Filter Predicates for '||i.plan_hash_value||' include unexpected INTERNAL_FUNCTION to perform an implicit data_type conversion, be sure it is not preventing a column from being used as an Access Predicate.';
        ins_obs;
      END LOOP;
    END;

    -- (026)
	-- plan operations with cost 0 and card 1
    BEGIN
      FOR i IN (SELECT DISTINCT plan_hash_value
                  FROM sqlt$_plan_extension
                 WHERE statement_id = s_sql_rec.statement_id
                   AND cost = 0
                   AND cardinality = 1
                 ORDER BY 1)
      LOOP
    	s_obs_rec.priority	  := 79;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'PLAN';
        s_obs_rec.object_name := 'PLAN_HASH_VALUE';
        s_obs_rec.observation := 'Review Plan '||i.plan_hash_value||' lines with Cost 0. Check for faulty statistics, Predicates out of Range or Histogram Skewness. See MOS Note Predicate Selectivity (Doc ID 68992.1) ';
        s_obs_rec.more        := 'Review <a href="#pln_sum">Plans Summary</a>. Look for Plan operations in '||i.plan_hash_value||' where Cost is 0 and Estimated Cardinality is 1. Suspect predicates out of range or incorrect statistics.';
        ins_obs;
      END LOOP;
    END;

    -- (027)
	-- high version count
    BEGIN
      SELECT MAX(version_count)
        INTO l_count
        FROM sqlt$_plan_stats_v
       WHERE statement_id = s_sql_rec.statement_id;

      IF l_count > 20 THEN
    	s_obs_rec.priority	  := 39;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'VERSION COUNT';
        s_obs_rec.object_name := 'VERSION COUNT';
        s_obs_rec.observation := 'Use MOS Note High SQL Version Counts - Script to determine reason(s) (Doc ID 438755.1) to determine the reason for a high version count ('||l_count||' versions).';
        s_obs_rec.more        := 'Review <a href="#pln_sum">Plans Summary</a> for details. If you need more information use 438755.1.';
        ins_obs;
      END IF;
    END;

    -- (028)
	-- first rows
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM (
      SELECT plan_hash_value
        FROM sqlt$_gv$sql
       WHERE statement_id = s_sql_rec.statement_id
         AND optimizer_mode = 'FIRST_ROWS'
       UNION
      SELECT plan_hash_value
        FROM sqlt$_dba_hist_sqlstat
       WHERE statement_id = s_sql_rec.statement_id
         AND optimizer_mode = 'FIRST_ROWS') v;

      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 45;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'OPTIMZER MODE';
        s_obs_rec.object_name   := 'FIRST_ROWS';
        s_obs_rec.observation   := 'Check the applicability of OPTIMIZER_MODE being set to FIRST_ROWS in '||l_count||' Plan(s). See MOS Note Using the FIRST_ROWS hint within a query gives poor performance (Doc ID 272202.1)';
        s_obs_rec.more          := 'The optimizer uses a mix of cost and heuristics to find a best plan for fast delivery of the first few rows. Using heuristics sometimes leads the query optimizer to generate a plan with a cost that is significantly larger than the cost of a plan without applying the heuristic. FIRST_ROWS is available for backward compatibility and plan stability; use FIRST_ROWS_n instead.';
        ins_obs;
      END IF;
    END;

    -- (029)
	-- cardinality feedback
    BEGIN
      SELECT COUNT(DISTINCT plan_hash_value)
        INTO l_count
        FROM sqlt$_plan_info
       WHERE statement_id = s_sql_rec.statement_id
         AND info_type = 'cardinality_feedback';

      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 68;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'PLAN CONTROL';
        s_obs_rec.object_name   := 'CARDINALITY_FEEDBACK';

        IF l_count = 1 THEN
          s_obs_rec.observation := 'Review <a href="#pln_exe">Execution Plan</a> for problems as it is using Cardinality Feedback. See MOS Note Statistics (Cardinality) Feedback - Frequently Asked Questions (Doc ID 1344937.1)';
          s_obs_rec.more        := 'Review <a href="#pln_exe">Execution Plans</a>.';
        ELSE
          s_obs_rec.observation := 'Review <a href="#pln_exe">Execution Plans</a> for problems as they are using Cardinality Feedback. '||l_count||' plans were created using Cardinality Feedback. See MOS Note Statistics (Cardinality) Feedback - Frequently Asked Questions (Doc ID 1344937.1).';
          s_obs_rec.more        := 'Review <a href="#pln_exe">Execution Plans</a>.';
        END IF;
        ins_obs;
      END IF;
    END;

    -- (030)
	-- fixed objects missing stats
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_tab_statistics t
       WHERE t.statement_id = s_sql_rec.statement_id
         AND t.object_type = 'FIXED TABLE'
         AND NOT EXISTS (
      SELECT NULL
        FROM sqlt$_dba_tab_cols c
       WHERE t.statement_id = c.statement_id
         AND t.owner = c.owner
         AND t.table_name = c.table_name );

      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 81;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'FIXED OBJECTS';
        s_obs_rec.object_name   := 'DBA_TAB_COL_STATISTICS';
        s_obs_rec.observation   := 'Review the Fixed Object statistics as there are '||l_count||' objects without statistics accessed by this SQL. See MOS Note Fixed Objects Statistics (GATHER_FIXED_OBJECTS_STATS) Considerations (Doc ID 798257.1)';
        s_obs_rec.more          := 'Consider gathering statistics for fixed objects using SYS.DBMS_STATS.GATHER_FIXED_OBJECTS_STATS. See MOS Doc ID 465787.1.';
        ins_obs;
      END IF;
    END;

    -- (031)
	-- system statistics not gathered. This test is only applicable to Non-Exadata. 
	BEGIN
      IF s_sql_rec.cpuspeed IS NULL AND s_sql_rec.ioseektim = 10 AND s_sql_rec.iotfrspeed = 4096 AND NVL(s_sql_rec.exadata, 'FALSE') = 'FALSE' THEN
    	s_obs_rec.priority	    := 33;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Workload CBO System Statistics are not gathered. CBO is using default values. See MOS Note How to Collect and Display System Statistics (CPU and IO) for CBO use (Doc ID 149560.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS. See MOS Doc ID 465787.1.';
        ins_obs;
      END IF;
    END;

    -- (032)
	-- mreadtim < sreadtim
    BEGIN
      IF s_sql_rec.mreadtim < s_sql_rec.sreadtim THEN
    	s_obs_rec.priority	    := 48;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Check the correctness of MREADTIM (Multi-block read time) of '||s_sql_rec.mreadtim||' which seems too small compared to single-block read time of '||s_sql_rec.sreadtim||'. See MOS Note System Statistics: Scaling the System to Improve CBO optimizer (Doc ID 153761.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM and MREADTIM using SYS.DBMS_STATS.SET_SYSTEM_STATS. See also MOS Doc ID 465787.1.';
        ins_obs;
      END IF;
    END;

    -- (033)
	-- (1.2 * sreadtim) > mreadtim > sreadtim
    BEGIN
      IF (1.2 * s_sql_rec.sreadtim > s_sql_rec.mreadtim) AND s_sql_rec.mreadtim > s_sql_rec.sreadtim THEN
    	s_obs_rec.priority	    := 47;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Check the correctness of MREADTIM (Multi-block read time) of '||s_sql_rec.mreadtim||' which seems too small compared to single-block read time of '||s_sql_rec.sreadtim||'. See MOS Note System Statistics: Scaling the System to Improve CBO optimizer (Doc ID 153761.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM and MREADTIM using SYS.DBMS_STATS.SET_SYSTEM_STATS. See also MOS Doc ID 465787.1.';
        ins_obs;
      END IF;
    END;

    -- (034)
	-- sreadtim < 2, applies to non Exadata only
    BEGIN
      IF NVL(s_sql_rec.exadata, 'FALSE') = 'FALSE' AND s_sql_rec.sreadtim < 2 THEN
    	s_obs_rec.priority	    := 32;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Check the value of SREADTIM on this non-Exadata system. Single-block read time of '||s_sql_rec.sreadtim||' milliseconds seems too small. See MOS Note System Statistics: Scaling the System to Improve CBO optimizer (Doc ID 153761.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM using SYS.DBMS_STATS.SET_SYSTEM_STATS. See also MOS Doc ID 465787.1.';
        ins_obs;
      END IF;
    END;

    -- (035)
	-- mreadtim < 3, applies to non Exadata only
    BEGIN
      IF NVL(s_sql_rec.exadata, 'FALSE') = 'FALSE' AND s_sql_rec.mreadtim < 3 THEN
    	s_obs_rec.priority	    := 32;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Check the value of MREADTIM on this non-Exadata system. Multi-block read time of '||s_sql_rec.mreadtim||' milliseconds which seems too small. See MOS Note System Statistics: Scaling the System to Improve CBO optimizer (Doc ID 153761.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS or adjusting MREADTIM using SYS.DBMS_STATS.SET_SYSTEM_STATS. See also MOS Doc ID 465787.1.';
        ins_obs;
      END IF;
    END;
    
    -- (036)
	-- sreadtim > 18, applies to non Exadata only
    BEGIN
      IF NVL(s_sql_rec.exadata, 'FALSE') = 'FALSE' AND s_sql_rec.sreadtim > 18 THEN
    	s_obs_rec.priority	    := 32;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Check the value of SREADTIM (Single-block read time) on this non-Exadata system, of '||s_sql_rec.sreadtim||' milliseconds which seems too large. See MOS Note System Statistics: Scaling the System to Improve CBO optimizer (Doc ID 153761.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM using SYS.DBMS_STATS.SET_SYSTEM_STATS. See also MOS Doc ID 465787.1 and Bug 9842771.';
        ins_obs;
      END IF;
    END;

    -- (037)
	-- mreadtim > 522, applies to non Exadata only
    BEGIN
      IF NVL(s_sql_rec.exadata, 'FALSE') = 'FALSE' AND s_sql_rec.mreadtim > 522 THEN
    	s_obs_rec.priority	    := 58;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Take action to adjust MREADTIM (Multi-block read time) as it is too high ('||s_sql_rec.mreadtim||' milliseconds). See MOS Note System Statistics: Scaling the System to Improve CBO optimizer (Doc ID 153761.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS or adjusting MREADTIM using SYS.DBMS_STATS.SET_SYSTEM_STATS. See also MOS Doc ID 465787.1 and Bug 9842771.';
        ins_obs;
      END IF;
    END;

    -- (038)
	-- sreadtim <> actual_sreadtim > 10%
    BEGIN
      IF s_sql_rec.sreadtim > 0 AND s_sql_rec.actual_sreadtim > 0 AND sqlt$t.differ_more_than_x_perc(s_sql_rec.sreadtim, s_sql_rec.actual_sreadtim, 10) THEN
    	s_obs_rec.priority	    := 58;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Consider taking action to adjust SREADTIM (Single-block read time '||s_sql_rec.sreadtim||' milliseconds) as it is different by more than 10% to the actual db file sequential read time of '||s_sql_rec.actual_sreadtim||' milliseconds. See MOS Note System Statistics: Scaling the System to Improve CBO optimizer (Doc ID 153761.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM using SYS.DBMS_STATS.SET_SYSTEM_STATS. See also MOS Doc ID 465787.1 and Bug 9842771.';
        ins_obs;
      END IF;
    END;

    -- (039)
	-- mreadtim <> actual_mreadtim > 10%
    BEGIN
      IF s_sql_rec.mreadtim > 0 AND s_sql_rec.actual_mreadtim > 0 AND sqlt$t.differ_more_than_x_perc(s_sql_rec.mreadtim, s_sql_rec.actual_mreadtim, 10) THEN
    	s_obs_rec.priority	    := 56;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Consider taking action to adjust MREADTIM (Multi-block read time) of '||s_sql_rec.mreadtim||' milliseconds as it is different by more than 10% from actual db file scattered read wait time of '||s_sql_rec.actual_mreadtim||' milliseconds. See MOS Note System Statistics: Scaling the System to Improve CBO optimizer (Doc ID 153761.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS or adjusting MREADTIM using SYS.DBMS_STATS.SET_SYSTEM_STATS. See also MOS Doc ID 465787.1 and Bug 9842771.';
        ins_obs;
      END IF;
    END;
	
	-- (040)
	-- sreadtim on Exadata not between 2 and 10ms
    BEGIN
      IF s_sql_rec.exadata = 'TRUE' AND s_sql_rec.sreadtim NOT BETWEEN 2 AND 10 THEN
    	s_obs_rec.priority	    := 69;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Consider collecting workload statistics or Exadata System Statistics. Single-block read time of '||s_sql_rec.sreadtim||' milliseconds seems unlikely for an Exadata system. See MOS Note Oracle Exadata Database Machine Setup/Configuration Best Practices (Doc ID 1274318.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS or adjusting SREADTIM using SYS.DBMS_STATS.SET_SYSTEM_STATS. See also MOS Doc ID 465787.1 and Bug 9842771.';
        ins_obs;
      END IF;
    END;
	
    -- (041)
	-- mreadtim on Exadata not between .5 and 10ms 
    BEGIN
      IF s_sql_rec.exadata = 'TRUE' AND s_sql_rec.mreadtim NOT BETWEEN 0.5 AND 10 THEN
    	s_obs_rec.priority	    := 70;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'DBMS_STATS';
        s_obs_rec.object_name   := 'SYSTEM STATISTICS';
        s_obs_rec.observation   := 'Consider collecting workload statistics or Exadata System Statistics. Multi Block read time of '||s_sql_rec.mreadtim||' milliseconds seems unlikely for an Exadata system. See MOS Note Oracle Exadata Database Machine Setup/Configuration Best Practices (Doc ID 1274318.1)';
        s_obs_rec.more          := 'Consider gathering workload <a href="#system_stats">system statistics</a> using SYS.DBMS_STATS.GATHER_SYSTEM_STATS or adjusting MREADTIM using SYS.DBMS_STATS.SET_SYSTEM_STATS. See also MOS Doc ID 465787.1 and Bug 9842771.';
        ins_obs;
      END IF;
    END;	

    -- (042)
	-- statement response time
    BEGIN
      IF s_sql_rec.statement_response_time IS NOT NULL THEN
    	s_obs_rec.priority	    := 12;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'STATEMENT';
        s_obs_rec.object_name   := 'RESPONSE TIME';
        s_obs_rec.observation   := 'Review TKPROF and TRCA reports for proper understanding of this SQL. Response time is '||s_sql_rec.statement_response_time||'. This is wall clock time. See MOS Note Consider collecting workload statistics or Exadata System Statistics. Single-block read time of '||s_sql_rec.sreadtim||' milliseconds seems unlikely for an Exadata system. See MOS Note Oracle Exadata Database Machine Setup/Configuration Best Practices (Doc ID 1274318.1)';
        s_obs_rec.more          := 'For better understanding of this time review <a href="#sql_stats">SQL statistics</a>. See also trace, tkprof and TRCA reports.';
        ins_obs;
      END IF;
    END;
	
	-- (043)
	-- Exadata specific check, offload disabled because of bad timezone file to cells (bug 11836425)
     BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM database_properties
       WHERE property_name = 'DST_UPGRADE_STATE' 
         AND property_value<>'NONE';

      IF l_count > 1 AND s_sql_rec.exadata = 'TRUE' THEN
    	s_obs_rec.priority	    := 37;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'OFFLOAD';
        s_obs_rec.object_name   := 'CELL OFFLOAD';
        s_obs_rec.observation   := 'Check your Offload capability on Exadata. It may be affected by Time Zone problems.';
        s_obs_rec.more          := 'Offload might get rejected if the cells don''t have the propert timezone file.';
        ins_obs;
      END IF;	  
     END;
	
    -- (044)
	-- Exadata specific check, offload disabled because tables with CACHE = YES
     BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_tables
       WHERE statement_id = s_sql_rec.statement_id
         AND cache = 'Y';

      IF l_count > 1 AND s_sql_rec.exadata = 'TRUE' THEN
    	s_obs_rec.priority	    := 35;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'OFFLOAD';
        s_obs_rec.object_name   := 'CELL OFFLOAD';
        s_obs_rec.observation   := 'Check the applicability of the CACHE setting for some tables. There is/are '||l_count||' tables(s) with CACHE = ''Y'', this causes offload to be disabled on it/them.';
        s_obs_rec.more          := 'Offload is not used for tables that have property CACHE = ''Y''.';
        ins_obs;
      END IF;	  
     END;
	
	-- (045)
	-- Exadata specific check, offload disabled for SQL executed by shared servers
	-- 160415 reword as a reminder
     BEGIN
      IF NVL(sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'shared_servers'),0) > 0 AND s_sql_rec.exadata = 'TRUE' THEN
    	s_obs_rec.priority	    := 87;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'OFFLOAD';
        s_obs_rec.object_name   := 'CELL OFFLOAD';
        s_obs_rec.observation   := 'Check the applicability of the Shared Server configuration on this Exadata machine. Offload is not used for SQLs executed from Shared Server. See MOS Note Exadata: Shared Server Connect Prevents Offloading To Storage Cells (Doc ID 1472538.1)';
        s_obs_rec.more          := 'SQLT notices dispatchers are configured on an Exadata system. <br><b>This is just a reminder</b> that a SQLs cannot be offloaded if executed from a session connected to a dispatcher, since it don''t use direct path reads.';
        ins_obs;
      END IF;	  
     END;

	-- (046)
	-- Exadata specific check, offload disabled for serial DML
	-- 160415 reword as a reminder
     BEGIN
      IF TRIM(UPPER(SUBSTR(LTRIM(s_sql_rec.sql_text),1,6))) IN ('INSERT','UPDATE','DELETE','MERGE') AND s_sql_rec.exadata = 'TRUE' THEN
    	s_obs_rec.priority	    := 14;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'OFFLOAD';
        s_obs_rec.object_name   := 'CELL OFFLOAD';
        s_obs_rec.observation   := 'Reminder: Offload is not used for SQLs that don''t use direct path reads. See MOS Note Exadata Smartscan Is Not Being Used On Insert As Select (Doc ID 1348116.1)';
        s_obs_rec.more          := 'SQLT notices the SQL is a DML. <br><b>This is just a reminder</b> that Serial DMLs cannot be offloaded by default since they don''t use direct path reads<br>If this execution is serial then make sure to use direct path reads or offload won'' be possible.';
        ins_obs;
      END IF;	  
     END;

	-- (047)
	-- AutoDOP and no IO Calibration, applies to non-Exadata only (Ted Persky correction. 23rd August 2018)
     BEGIN
      IF UPPER(NVL(sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'parallel_degree_policy'),'NA')) IN ('AUTO','LIMITED') AND NVL(s_sql_rec.ioc_max_iops,0) = 0 AND NVL (s_sql_rec.exadata,'FALSE') = 'FALSE' THEN
    	s_obs_rec.priority	    := 15;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'PX';
        s_obs_rec.object_name   := 'AUTODOP OFF';
        s_obs_rec.observation   := 'Check for applicability of Bug 9102474 (Bug 9102474 - AutoDOP is is valid/enabled only if io calibrate statistics are available (Doc ID 9102474.8)).';
        s_obs_rec.more          := 'AutoDOP requires IO Calibration stats, consider collecting them using DBMS_RESOURCE_MANAGER.CALIBRATE_IO.';
        ins_obs;
      END IF;	  
     END;    		

	-- (048)
	-- ManualDoP and Tables with DEFAULT degree
     BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_tables
       WHERE statement_id = s_sql_rec.statement_id
         AND degree = 'DEFAULT';

      IF l_count > 0 AND UPPER(NVL(sqlt$a.get_sqlt$_v$parameter2(s_sql_rec.statement_id, 'parallel_degree_policy'),'NA')) = 'MANUAL' THEN
    	s_obs_rec.priority	    := 95;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'PX';
        s_obs_rec.object_name   := 'MANUAL DOP WITH DEFAULT';
        s_obs_rec.observation   := 'Check the applicability of setting DEGREE to DEFAULT on '||l_count||' table(s) when PARALLEL_DEGREE_POLICY is MANUAL. See MOS Note Oracle 11g Release 2: New Parallel Query Parameters (Doc ID 1264548.1).';
        s_obs_rec.more          := 'DEFAULT degree combined with PARALLEL_DEGREE_POLICY = MANUAL might translate in a high degree of parallelism.';
        ins_obs;
      END IF;	  
     END;
	
	
    -- (049)
	-- tables with stale statistics
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_tab_statistics
       WHERE statement_id = s_sql_rec.statement_id
         AND object_type = 'TABLE'
         AND stale_stats = 'YES';

      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 83;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'TABLES';
        s_obs_rec.object_name   := 'STALE STATS';
        IF l_count = 1 THEN
          s_obs_rec.observation := 'Consider collecting statistics on a table in this query as its statistics are stale. See MOS Note Script that Checks for Schemas Containing Stale Statistics (Doc ID 560336.1).';
        ELSE
          s_obs_rec.observation := 'Consider collecting statistics on a number of tables. There are '||l_count||' tables with stale stats. See MOS Note Script that Checks for Schemas Containing Stale Statistics (Doc ID 560336.1).';
        END IF;

        IF s_sql_rec.siebel = 'YES' THEN
          s_obs_rec.more        := 'Consider gathering <a href="#tab_stats">table statistics</a> using coe_siebel_stats.sql. See MOS Note Performance Tuning Guidelines for Siebel CRM Application on Oracle Database (Doc ID 2077227.2).';
        ELSIF s_sql_rec.psft = 'YES' THEN
          s_obs_rec.more        := 'Consider gathering <a href="#tab_stats">table statistics</a> using pscbo_stats.sql. See MOS Note pscbo_stats - Improving Statistics in Oracle RDBMS for PeopleSoft Enterprise (Doc ID 1322888.1).';
        ELSIF s_sql_rec.apps_release IS NOT NULL THEN
          s_obs_rec.more        := 'Consider gathering <a href="#tab_stats">table statistics</a> using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql. See MOS Note coe_stats.sql - Automates CBO Stats Gathering using FND_STATS and Table sizes (Doc ID 156968.1)';
        ELSE
          s_obs_rec.more        := 'Consider gathering <a href="#tab_stats">table statistics</a> using SYS.DBMS_STATS.GATHER_TABLE_STATS. See MOS Note How to: Manage CBO Statistics During an Upgrade from 10g or 9i into 11g/12c (Doc ID 465787.1).';
        END IF;
        ins_obs;
      END IF;
    END;

    -- (050)
	-- tables with locked statistics
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_tab_statistics
       WHERE statement_id = s_sql_rec.statement_id
         AND object_type = 'TABLE'
         AND stattype_locked IN ('ALL', 'DATA');

      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 48;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'TABLES';
        s_obs_rec.object_name   := 'LOCKED STATS';
        IF l_count = 1 THEN
          s_obs_rec.observation := 'Check the applicability of locked statistics on the table. See MOS Note FAQ: Statistics Gathering Frequently Asked Questions (Doc ID 1501712.1).';
        ELSE
          s_obs_rec.observation := 'Check the applicability of locked table statistics on more than one table. There are '||l_count||' tables with locked stats. See MOS Note FAQ: Statistics Gathering Frequently Asked Questions (Doc ID 1501712.1)';
        END IF;
        s_obs_rec.more          := 'Review <a href="#tab_stats">table statistics</a>.';
        ins_obs;
      END IF;
    END;

    -- (051)
	-- indexes with stale statistics
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_ind_statistics
       WHERE statement_id = s_sql_rec.statement_id
         AND object_type = 'INDEX'
         AND stale_stats = 'YES';

      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 35;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'INDEX';
        s_obs_rec.object_name   := 'STALE STATS';
        IF l_count = 1 THEN
          s_obs_rec.observation := 'There is one index with stale stats.';
        ELSE
          s_obs_rec.observation := 'There are '||l_count||' indexes with stale stats.';
        END IF;

        IF s_sql_rec.siebel = 'YES' THEN
          s_obs_rec.more        := 'Consider gathering <a href="#tab_stats">index statistics</a> using coe_siebel_stats.sql. See MOS Note Performance Tuning Guidelines for Siebel CRM Application on Oracle Database (Doc ID 2077227.2).';
        ELSIF s_sql_rec.psft = 'YES' THEN
          s_obs_rec.more        := 'Consider gathering <a href="#tab_stats">index statistics</a> using pscbo_stats.sql. See MOS Note pscbo_stats - Improving Statistics in Oracle RDBMS for PeopleSoft Enterprise (Doc ID 1322888.1).';
        ELSIF s_sql_rec.apps_release IS NOT NULL THEN
          s_obs_rec.more        := 'Consider gathering <a href="#tab_stats">index statistics</a> using FND_STATS.GATHER_TABLE_STATS with cascade => true or coe_stats.sql. See MOS Note coe_stats.sql - Automates CBO Stats Gathering using FND_STATS and Table sizes (Doc ID 156968.1).';
        ELSE
          s_obs_rec.more        := 'Consider gathering <a href="#tab_stats">index statistics</a> using SYS.DBMS_STATS.GATHER_TABLE_STATS with cascade => true. See MOS Note How to: Manage CBO Statistics During an Upgrade from 10g or 9i into 11g/12c (Doc ID 465787.1).';
        END IF;
        ins_obs;
      END IF;
    END;

    -- (052)
	-- sql with policies
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_gv$vpd_policy
       WHERE statement_id = s_sql_rec.statement_id;

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 16;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'VDP';
        s_obs_rec.object_name := 'GV$VPD_POLICY';
        s_obs_rec.observation := 'Check the injected predicates below each individual plan to make sure it is applicable on this Virtual Private Database. See MOS Note How to Investigate Query Performance Regressions Caused by VPD (FGAC) Predicates? (Doc ID 967042.1).';
        s_obs_rec.more        := 'Review <a href="#pln_exe">Execution Plans</a> and look for their injected predicates below each individual plan.';
        ins_obs;
      ELSE
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_policies
         WHERE statement_id = s_sql_rec.statement_id;

        IF l_count > 0 THEN
    	s_obs_rec.priority	    := 16;
	      s_obs_rec.type_id     := E_GLOBAL;
          s_obs_rec.object_type := 'VDP';
          s_obs_rec.object_name := 'DBA_POLICIES';
          s_obs_rec.observation := 'Check the policies on this Virtual Private Database agains the Tables, Views or Synonyms related to the SQL being analyzed. See MOS Note How to Investigate Query Performance Regressions Caused by VPD (FGAC) Predicates? (Doc ID 967042.1).';
          s_obs_rec.more        := 'Review <a href="#policies">Policies</a>.';
          ins_obs;
        END IF;
      END IF;
    END;

    -- (053)
	-- audit policies
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_audit_policies
       WHERE statement_id = s_sql_rec.statement_id;

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 8;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'FGA';
        s_obs_rec.object_name := 'DBA_AUDIT_POLICIES';
        s_obs_rec.observation := 'Fine-Grained Auditing. There is one or more audit policies on Tables or Views related to the SQL being analyzed. See MOS Note Performance Issues While Monitoring the Unified Audit Trail of an Oracle12c Database (Doc ID 2063340.1).';
        s_obs_rec.more        := 'Review SQLT repository and look for SQLT$_DBA_AUDIT_POLICIES.';
        ins_obs;
      END IF;
    END;

    -- (054)
	-- sqlt_user_role not granted
    BEGIN
      IF s_sql_rec.sqlt_user_role = 'NO' THEN
    	s_obs_rec.priority	    := 6;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'ROLE';
        s_obs_rec.object_name   := ROLE_NAME;
        s_obs_rec.observation   := 'Grant the SQLT Role, "'||ROLE_NAME||'" to the user "'||s_sql_rec.username||'" if possible. See MOS Note FAQ: SQLT (SQLTXPLAIN) Frequently Asked Questions (Doc ID 1454160.1)';
        s_obs_rec.more          := 'SQLT users must be granted the "'||ROLE_NAME||'" role.';
        ins_obs;
      END IF;
    END;

    -- (055)
	-- materialized views with rewrite enabled
    BEGIN
      IF s_sql_rec.mat_view_rewrite_enabled_count > 0 THEN
    	s_obs_rec.priority	    := 9;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'MAT_VIEW';
        s_obs_rec.object_name   := 'REWRITE_ENABLED';
        s_obs_rec.observation   := 'Check that all Materialized Views are applicable. There is/are '||s_sql_rec.mat_view_rewrite_enabled_count||' materialized view(s) with rewrite enabled. See MOS Note Master Note for Materialized View (MVIEW) (Doc ID 1353040.1).';
        s_obs_rec.more          := 'A large number of materialized views could affect parsing time since CBO would have to evaluate each during a hard-parse.';
        ins_obs;
      END IF;
    END;
	
	-- (056)
	-- how many materialized view *not used in the plan* are defined on the objects involved here 
	-- this is useful for some complex TC where CBO uses mview info to do join elimination (ie. 13420154)
	-- 
	-- we have to access directly the ALL_DEPENDENCIES because we don't bring
	-- "forward dependencies" in SQLT (as it would be usefless beside to run this HC)
    BEGIN	 
     SELECT COUNT(*)
       INTO l_count
       FROM sqlt$_dba_tables a,
            dba_dependencies b
      WHERE a.statement_id = s_sql_rec.statement_id  
        AND b.type LIKE 'MATER%'
        AND a.owner = b.referenced_owner
        AND a.table_name = b.referenced_name;		
	
      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 4;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'MAT_VIEW';
        s_obs_rec.object_name   := 'MVIEW_DEPENDECIES';
        s_obs_rec.observation   := 'Ensure that for any test case that you include the Materialized Views not referenced in the query. There is/are '||l_count||' MVs in the plan that is/are defined on objects involved in this SQL.';
        s_obs_rec.more          := 'There is no harm in having them but you might need to bring such materialized view(s) when installing the TC elsewhere.';
        ins_obs;
      END IF;
    END;	
	
	-- (057)
	-- rewrite equivalences
	-- this one goes to the ALL_REWRITE_EQUIVALENCES since we don't bring it either
	-- and it would be an overkill to do it for just a count(*)
    BEGIN	 
     SELECT COUNT(*)
       INTO l_count
       FROM sqlt$_dba_tables a,
            dba_rewrite_equivalences b
      WHERE a.statement_id = s_sql_rec.statement_id  
        AND a.owner = b.owner;		
	
      IF l_count > 0 THEN
    	s_obs_rec.priority	    := 3;
	    s_obs_rec.type_id       := E_GLOBAL;
        s_obs_rec.object_type   := 'REWRITE_EQUIVALENCE';
        s_obs_rec.object_name   := 'REWRITE_EQUIVALENCE';
        s_obs_rec.observation   := 'Ensure the Rewrite Equivalences are applicable. There is/are '||l_count||' rewrite equivalence(s) defined by the owner(s) of the involved objects.';
        s_obs_rec.more          := 'A rewrite equivalence makes the CBO rewrite the original SQL to a different one so that needs to be considered when analyzing the case.';
        ins_obs;
      END IF;
    END;	

    -- (058)
	-- table with bitmap index(es)
    BEGIN
      IF s_sql_rec.command_type_name IN ('INSERT', 'UPDATE', 'DELETE') THEN
        SELECT COUNT(DISTINCT table_name||table_owner)
          INTO l_count
          FROM sqlt$_dba_indexes
         WHERE statement_id = s_sql_rec.statement_id
           AND index_type = 'BITMAP';

        IF l_count > 0 THEN
    	s_obs_rec.priority	    := 32;
	      s_obs_rec.type_id     := E_GLOBAL;
          s_obs_rec.object_type := 'INDEX';
          s_obs_rec.object_name := 'BITMAP';
          s_obs_rec.observation := 'Ensure the bitmap index(es) referenced in the DML ('||l_count||' Table(s)) does not also cause "enq: TX - row lock contention". See MOS Note Waits for Enq: TX - ... Type Events - Transaction (TX) Lock Example Scenarios (Doc ID 62354.1).';
          s_obs_rec.more        := 'Be aware that frequent DML operations operations in a Table with Bitmap indexes may produce contention where concurrent DML operations are common. If your SQL suffers of "TX-enqueue row lock contention" suspect this situation.';
          ins_obs;
        END IF;
      END IF;
    END;

    -- (059)
	-- index in plan no longer exists
    BEGIN
      FOR i IN (SELECT DISTINCT p.object_owner, p.object_name
                  FROM sqlt$_plan_extension p
                 WHERE p.statement_id = s_sql_rec.statement_id
                   AND (p.object_type LIKE '%INDEX%' OR p.operation LIKE '%INDEX%')
                   AND source IN ('GV$SQL_PLAN', 'DBA_HIST_SQL_PLAN', 'PLAN_TABLE')
                   AND NOT EXISTS
               (SELECT NULL
                  FROM sqlt$_dba_indexes i
                 WHERE p.statement_id = i.statement_id
                   AND p.object_owner = i.owner
                   AND p.object_name = i.index_name))
      LOOP
    	s_obs_rec.priority	  := 86;
	    s_obs_rec.type_id     := E_INDEX;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := i.object_owner||'.'||i.object_name;
        s_obs_rec.observation := 'Check if the index referenced in the execution plan has been droppped. See MOS Note Index Hints Seems to Be Ignored by Optimizer (Doc ID 2381118.1).';
        s_obs_rec.more        := 'If a Plan references a missing index then this Plan cannot be generated by the CBO. The index may have been just suggested by the STA or maybe it was dropped.';
        ins_obs;
      END LOOP;
    END;

    -- (060)
	-- index in plan is now unusable
    BEGIN
      FOR i IN (SELECT DISTINCT p.object_owner, p.object_name
                  FROM sqlt$_plan_extension p,
                       sqlt$_dba_indexes i
                 WHERE p.statement_id = s_sql_rec.statement_id
                   AND (p.object_type LIKE '%INDEX%' OR p.operation LIKE '%INDEX%')
                   AND p.object_owner = i.owner
                   AND p.object_name = i.index_name
                   AND i.statement_id = s_sql_rec.statement_id
                   AND i.partitioned = 'NO'
                   AND i.status = 'UNUSABLE')
      LOOP
    	s_obs_rec.priority	  := 83;
	    s_obs_rec.type_id     := E_INDEX;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := i.object_owner||'.'||i.object_name;
        s_obs_rec.observation := 'Check if the index referenced in the execution plan is usable. Also see MOS Note Unusable Index Segment Still Exists in DBA_SEGMENTS for Alter Table Move (Doc ID 1265948.1).';
        s_obs_rec.more        := 'If a Plan references an unusable index then this Plan cannot be generated by the CBO. If you need to enable tha Plan that references this index you need to rebuild it first.';
        ins_obs;
      END LOOP;
    END;

    -- (061)
	-- index in plan has now unusable partitions
    BEGIN
      FOR i IN (SELECT DISTINCT p.object_owner, p.object_name
                  FROM sqlt$_plan_extension p,
                       sqlt$_dba_ind_partitions i
                 WHERE p.statement_id = s_sql_rec.statement_id
                   AND (p.object_type LIKE '%INDEX%' OR p.operation LIKE '%INDEX%')
                   AND p.object_owner = i.index_owner
                   AND p.object_name = i.index_name
                   AND i.statement_id = s_sql_rec.statement_id
                   AND i.status = 'UNUSABLE')
      LOOP
    	s_obs_rec.priority	  := 87;
	    s_obs_rec.type_id     := E_INDEX;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := i.object_owner||'.'||i.object_name;
        s_obs_rec.observation := 'Check why the partitioned index is unusable. See the MOS Note Example of Script to Maintain Partitioned Indexes (Doc ID 166755.1).';
        s_obs_rec.more        := 'If a Plan references an index with unusable partitions then this Plan cannot be generated by the CBO. If you need to enable tha Plan that references this index you need to rebuild the unusable partitions first.';
        ins_obs;
      END LOOP;
    END;

    -- (062)
	-- index in plan has now unusable subpartitions
    BEGIN
      FOR i IN (SELECT DISTINCT p.object_owner, p.object_name
                  FROM sqlt$_plan_extension p,
                       sqlt$_dba_ind_subpartitions i
                 WHERE p.statement_id = s_sql_rec.statement_id
                   AND (p.object_type LIKE '%INDEX%' OR p.operation LIKE '%INDEX%')
                   AND p.object_owner = i.index_owner
                   AND p.object_name = i.index_name
                   AND i.statement_id = s_sql_rec.statement_id
                   AND i.status = 'UNUSABLE')
      LOOP
    	s_obs_rec.priority	  := 85;
	    s_obs_rec.type_id     := E_INDEX;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := i.object_owner||'.'||i.object_name;
        s_obs_rec.observation := 'Check why the sub-partitioned index referenced by the Execution Plan is unusable. has now unusable subpartitions. Also see Oracle 12c In-memory Performance issue when there are partitions/subpartitons indexes marked unusable (Doc ID 2106224.1).';
        s_obs_rec.more        := 'If a Plan references an index with unusable subpartitions then this Plan cannot be generated by the CBO. If you need to enable tha Plan that references this index you need to rebuild the unusable subpartitions first.';
        ins_obs;
      END LOOP;
    END;

    -- (063)
	-- index in plan is now invisible
    BEGIN
      FOR i IN (SELECT DISTINCT p.object_owner, p.object_name
                  FROM sqlt$_plan_extension p,
                       sqlt$_dba_indexes i
                 WHERE p.statement_id = s_sql_rec.statement_id
                   AND (p.object_type LIKE '%INDEX%' OR p.operation LIKE '%INDEX%')
                   AND p.object_owner = i.owner
                   AND p.object_name = i.index_name
                   AND i.statement_id = s_sql_rec.statement_id
                   AND i.visibility = 'INVISIBLE')
      LOOP
    	s_obs_rec.priority	  := 89;
	    s_obs_rec.type_id     := E_INDEX;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := i.object_owner||'.'||i.object_name;
        s_obs_rec.observation := 'Check to see if it is applicable for the index referenced in the execution plan is invisible. See MOS Note Diagnosing and Understanding Why a Query is Not Using an Index (Doc ID 67522.1).';
        s_obs_rec.more        := 'If a Plan references an invisible index then this Plan cannot be generated by the CBO. If you need to enable the Plan that references this index you need to make this index visible.';
        ins_obs;
      END LOOP;
    END;

    -- (064)
	-- unusable indexes
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_indexes
       WHERE statement_id = s_sql_rec.statement_id
         AND partitioned = 'NO'
         AND status = 'UNUSABLE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 91;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := 'UNUSABLE';
        s_obs_rec.observation := 'Check why the '||l_count||' unusable index(es) in tables being accessed by your SQL are unusable. Also see the MOS Note Diagnosing and Understanding Why a Query is Not Using an Index (Doc ID 67522.1).';
        s_obs_rec.more        := 'Unusable indexes cannot be used by the CBO. This may cause Execution Plans to change.';
        ins_obs;
      END IF;
    END;

    -- (065)
	-- unusable index partitions
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_ind_partitions
       WHERE statement_id = s_sql_rec.statement_id
         AND status = 'UNUSABLE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 91;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'INDEX PARTITION';
        s_obs_rec.object_name := 'UNUSABLE';
        s_obs_rec.observation := 'Check why the '||l_count||' unusable index partition(s) in tables being accessed by your SQL is/are unusable. Also see MOS Note Diagnosing and Understanding Why a Query is Not Using an Index (Doc ID 67522.1)';
        s_obs_rec.more        := 'Unusable index partitions cannot be used by the CBO. This may cause Execution Plans to change.';
        ins_obs;
      END IF;
    END;

    -- (066)
	-- unusable index subpartitions
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_ind_subpartitions
       WHERE statement_id = s_sql_rec.statement_id
         AND status = 'UNUSABLE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 90;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'INDEX SUBPARTITION';
        s_obs_rec.object_name := 'UNUSABLE';
        s_obs_rec.observation := 'Check why the '||l_count||' unusable index subpartition(s) in tables being accessed by your SQL is/are unusable. Also see MOS Note Diagnosing and Understanding Why a Query is Not Using an Index (Doc ID 67522.1)';
        s_obs_rec.more        := 'Unusable index subpartitions cannot be used by the CBO. This may cause Execution Plans to change.';
        ins_obs;
      END IF;
    END;

    -- (067)
	-- invisible indexes
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_indexes
       WHERE statement_id = s_sql_rec.statement_id
         AND visibility = 'INVISIBLE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 90;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := 'INVISIBLE';
        s_obs_rec.observation := 'Check why the '||l_count||' index(es) in tables being accessed by your SQL are invisible. Also see MOS Note Diagnosing and Understanding Why a Query is Not Using an Index (Doc ID 67522.1).';
        s_obs_rec.more        := 'Invisible indexes cannot be used by the CBO. This may cause Execution Plans to change.';
        ins_obs;
      END IF;
    END;

    -- (068)
	-- indexes with mutating blevel
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_ind_statistics
       WHERE statement_id = s_sql_rec.statement_id
         AND object_type = 'INDEX'
         AND mutating_blevel = 'TRUE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 90;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := 'BLEVEL';
        s_obs_rec.observation := 'Check why the '||l_count||' index(es) have fluctuating BLEVEL. Also see the MOS Note How to Determine When an Index Should be Rebuilt? (Doc ID 1373415.1).';
        s_obs_rec.more        := 'Review index statistics versions. If the BLEVEL of an index has changed recently it may cause the Execution Plans to change.</a>.';
        ins_obs;
      END IF;
    END;

    -- (069)
	-- index partitions with mutating blevel
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_ind_statistics
       WHERE statement_id = s_sql_rec.statement_id
         AND object_type = 'PARTITION'
         AND mutating_blevel = 'TRUE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 83;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'INDEX PARTITION';
        s_obs_rec.object_name := 'BLEVEL';
        s_obs_rec.observation := 'Check why the '||l_count||' index partition(s) have a fluctuating BLEVEL. Also see the MOS Note How to Determine When an Index Should be Rebuilt? (Doc ID 1373415.1). ';
        s_obs_rec.more        := 'Review index partition statistics versions. If the BLEVEL of an index partition has changed recently, and the plan references index partitions, it may cause the Execution Plans to change.</a>.';
        ins_obs;
      END IF;
    END;

    -- (070)
	-- index subpartitions with mutating blevel
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_ind_statistics
       WHERE statement_id = s_sql_rec.statement_id
         AND object_type = 'SUBPARTITION'
         AND mutating_blevel = 'TRUE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 81;
	    s_obs_rec.type_id     := E_GLOBAL;
        s_obs_rec.object_type := 'INDEX SUBPARTITION';
        s_obs_rec.object_name := 'BLEVEL';
        s_obs_rec.observation := 'Check why the '||l_count||' index subpartition(s) have fluctuating BLEVEL. Also see the MOS Note How to Determine When an Index Should be Rebuilt? (Doc ID 1373415.1).';
        s_obs_rec.more        := 'Review index subpartition statistics versions. If the BLEVEL of an index subpartition has changed recently, and the plan references index subpartitions, it may cause the Execution Plans to change.</a>.';
        ins_obs;
      END IF;
    END;

    write_log('<- global_hc');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('global_hc: '||SQLERRM);
  END global_hc;

  /*************************************************************************************/

  /* -------------------------
   *
   * private ebs_hc
   *
   * ------------------------- */
  --(071)
  PROCEDURE ebs_hc
  IS
    l_count NUMBER;
  BEGIN
    write_log('-> ebs_hc');

    -- missing histograms
    FOR i IN (SELECT hc.table_name,
                     hc.column_name
                FROM sqlt$_fnd_histogram_cols hc,
                     sqlt$_dba_all_table_cols_v tc
               WHERE hc.statement_id = s_sql_rec.statement_id
                 AND hc.statement_id = tc.statement_id
                 AND hc.table_name = tc.table_name
                 AND hc.column_name = tc.column_name
                 AND tc.histogram = 'NONE'
                 AND tc.num_distinct > 1
               ORDER BY
                     hc.table_name,
                     hc.column_name)
    LOOP
      s_obs_rec.priority    := 73;
	  s_obs_rec.type_id     := E_EBS;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := i.table_name||'.'||i.column_name;
      s_obs_rec.observation := 'Check why some columns for EBS lack the required Histogram(s). Also see MOS Note Troubleshooting Oracle Applications Performance Issues (Doc ID 169935.1).';
      s_obs_rec.more        := 'It seems that FND_STATS was not used to gather CBO statistics. Consider gathering table statistics with FND_STATS.';
      ins_obs;
    END LOOP;

    -- (072)
	-- histograms in excess
    FOR i IN (SELECT DISTINCT tc.owner, tc.table_name
                FROM sqlt$_dba_all_table_cols_v tc
               WHERE tc.statement_id = s_sql_rec.statement_id
                 AND tc.histogram <> 'NONE'
                 AND tc.num_distinct > 1
                 AND NOT EXISTS (
              SELECT NULL
                FROM sqlt$_fnd_histogram_cols hc
               WHERE tc.statement_id = hc.statement_id
                 AND tc.table_name = hc.table_name
                 AND tc.column_name = hc.column_name)
               ORDER BY
                     tc.table_name)
    LOOP
      s_obs_rec.priority	:= 61;
	  s_obs_rec.type_id     := E_EBS;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := i.owner||'.'||i.table_name;
      s_obs_rec.observation := 'Check why there are more than the required number of Histograms on the EBS system. Also see MOS Note Troubleshooting Oracle Applications Performance Issues (Doc ID 169935.1).';
      s_obs_rec.more        := 'It seems that FND_STATS was not used to gather CBO statistics. Consider gathering table statistics with FND_STATS.';
      ins_obs;
    END LOOP;

    write_log('<- ebs_hc');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('ebs_hc: '||SQLERRM);
  END ebs_hc;

  /*************************************************************************************/

  /* -------------------------
   *
   * private siebel_hc
   *
   * ------------------------- */
  --(073)
  PROCEDURE siebel_hc
  IS
    l_count NUMBER;
  BEGIN
    write_log('-> siebel_hc');

    -- missing histograms
    FOR i IN (SELECT table_name,
                     column_name
                FROM sqlt$_dba_all_table_cols_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND histogram = 'NONE'
                 AND num_distinct > 1
                 AND (table_name IN ('S_POSTN_CON', 'S_ORG_BU', 'S_ORG_GROUP') OR in_indexes = 'TRUE')
                 AND (table_name LIKE 'S^_%' ESCAPE '^' -- "S_%"
                  OR  table_name LIKE 'CX^_%' ESCAPE '^') -- "CX_%"
                 AND table_name NOT LIKE 'S^_ETL%' ESCAPE '^' -- "S_ETL%"
               ORDER BY
                     table_name,
                     column_name)
    LOOP
      s_obs_rec.priority	:= 75;
	  s_obs_rec.type_id     := E_SIEBEL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := i.table_name||'.'||i.column_name;
      s_obs_rec.observation := 'Check why the SIEBEL application column lacks the required Histograms. See MOS Note Performance Tuning Guidelines for Siebel CRM Application on Oracle Database (Doc ID 2077227.2).';
      s_obs_rec.more        := 'It seems that coe_siebel_stats.sql was not used to gather CBO statistics. Consider gathering table statistics with coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
      ins_obs;
    END LOOP;

    -- (074)
	-- histograms in excess
    FOR i IN (SELECT DISTINCT owner, table_name
                FROM sqlt$_dba_all_table_cols_v
               WHERE statement_id = s_sql_rec.statement_id
                 AND histogram <> 'NONE'
                 AND num_distinct > 1
                 AND table_name NOT IN ('S_POSTN_CON', 'S_ORG_BU', 'S_ORG_GROUP')
                 AND in_indexes = 'FALSE'
                 AND (table_name LIKE 'S^_%' ESCAPE '^' -- "S_%"
                  OR  table_name LIKE 'CX^_%' ESCAPE '^') -- "CX_%"
                 AND table_name NOT LIKE 'S^_ETL%' ESCAPE '^' -- "S_ETL%"
               ORDER BY
                     table_name)
    LOOP
      s_obs_rec.priority    := 75;
	  s_obs_rec.type_id     := E_SIEBEL;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := i.owner||'.'||i.table_name;
      s_obs_rec.observation := 'Check why the SIEBEL application columns have too many Histograms. See MOS Note Performance Tuning Guidelines for Siebel CRM Application on Oracle Database (Doc ID 2077227.2).';
      s_obs_rec.more        := 'It seems that coe_siebel_stats.sql was not used to gather CBO statistics. Consider gathering table statistics with coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
      ins_obs;
    END LOOP;

    -- (075)
	-- cbo environment
    FOR i IN (SELECT id,
                     LOWER(name) name,
                     UPPER(value) value,
                     COUNT(*) child_count,
                     MIN(child_number) min_child_number,
                     MAX(child_number) max_child_number,
                     CASE WHEN LOWER(name) IN (
                     'optimizer_index_caching',
                     'optimizer_mode',
                     'query_rewrite_integrity',
                     'star_transformation_enabled',
                     'optimizer_index_cost_adj',
                     'optimizer_dynamic_sampling',
                     'query_rewrite_enabled',
                     '_always_semi_join',
                     '_b_tree_bitmap_plans',
                     '_partition_view_enabled',
                     '_gc_defer_time',
                     '_no_or_expansion',
                     '_optimizer_max_permutations',
                     '_hash_join_enabled',
                     '_optimizer_sortmerge_join_enabled',
                     '_optimizer_join_sel_sanity_check',
                     '_optim_peek_user_binds',
                     'sort_area_size',
                     'sort_area_retained_size',
                     'hash_area_size',
                     'workarea_size_policy',
                     'pga_aggregate_target',
                     'statistics_level'
                     ) THEN 'Y' ELSE 'N' END in_white_paper
                FROM sqlt$_gv$sql_optimizer_env
               WHERE statement_id = s_sql_rec.statement_id
               GROUP BY
                     id,
                     name,
                     value
               ORDER BY
                     id)
    LOOP
      s_obs_rec.priority	:= 90;
	  s_obs_rec.type_id     := E_SIEBEL;
      s_obs_rec.object_type := 'CBO PARAMETER';
      s_obs_rec.object_name := i.name;

      IF i.in_white_paper = 'Y' THEN
        IF (i.name = 'optimizer_index_caching' AND i.value <> '0') OR
           (i.name = 'optimizer_mode' AND i.value <> 'FIRST_ROWS_10') OR -- connector (def all_rows is also valid)
           (i.name = 'query_rewrite_integrity' AND i.value <> 'ENFORCED') OR
           (i.name = 'star_transformation_enabled' AND i.value <> 'FALSE') OR
           (i.name = 'optimizer_index_cost_adj' AND i.value <> '1') OR -- (def 100 is also valid)
           (i.name = 'optimizer_dynamic_sampling' AND i.value <> '1') OR
           (i.name = 'query_rewrite_enabled' AND i.value <> 'FALSE') OR
           (i.name = '_always_semi_join' AND i.value <> 'OFF') OR
           (i.name = '_b_tree_bitmap_plans' AND i.value <> 'FALSE') OR
           (i.name = '_partition_view_enabled' AND i.value <> 'FALSE') OR
           (i.name = '_gc_defer_time' AND i.value <> '0') OR
           (i.name = '_no_or_expansion' AND i.value <> 'FALSE') OR
           (i.name = '_optimizer_max_permutations' AND i.value <> '100') OR
           (i.name = '_hash_join_enabled' AND i.value <> 'FALSE') OR -- connector (def TRUE is also valid)
           (i.name = '_optimizer_sortmerge_join_enabled' AND i.value <> 'FALSE') OR -- connector (def TRUE is also valid)
           (i.name = '_optimizer_join_sel_sanity_check' AND i.value <> 'TRUE') OR -- connector (def TRUE)
           (i.name = '_optim_peek_user_binds' AND i.value <> 'TRUE')
        THEN
          s_obs_rec.observation := 'Check your SIEBEL application against the SIEBEL white paper 781927.1. Value "'||i.value||'" seems incorrect. See MOS Note Performance Tuning Guidelines for Siebel CRM Application on Oracle Database (Doc ID 2077227.2).';

          IF i.child_count = 1 THEN
            s_obs_rec.more := 'There is one child cursor with this parameter and value.';
          ELSIF i.child_count = 2 THEN
            s_obs_rec.more := 'Child cursors "'||i.min_child_number||'" and "'||i.max_child_number||'" reference this parameter and value.';
          ELSE
            s_obs_rec.more := 'There are '||i.child_count||' child cursors referencing this parameter and value.';
          END IF;

          IF i.name = 'optimizer_mode' THEN
            s_obs_rec.more := s_obs_rec.more||' Defaul value of "ALL_ROWS" is also considered valid if the SQL is part of a batch process.';
          ELSIF i.name = 'optimizer_index_cost_adj' THEN
            s_obs_rec.more := s_obs_rec.more||' Defaul value of "100" is also considered acceptable. A value of "1" is preferred.';
          ELSIF i.name IN ('_hash_join_enabled', '_optimizer_join_sel_sanity_check') THEN
            s_obs_rec.more := s_obs_rec.more||' Defaul value of "TRUE" is also considered valid if the SQL is part of a batch process.';
          END IF;

          s_obs_rec.more := s_obs_rec.more||' Review this parameter as per 781927.1 and fix its value if necessary.';
          ins_obs;
        END IF;
      ELSE
        s_obs_rec.observation := 'CBO parameter not referenced in SIEBEL white paper 781927.1.';
        s_obs_rec.more        := 'Consider removing this CBO parameter, unless its setup was requested by Support.';
        ins_obs;
      END IF;
    END LOOP;

    write_log('<- siebel_hc');
  EXCEPTION
    WHEN OTHERS THEN
      write_error('siebel_hc: '||SQLERRM);
  END siebel_hc;

  /*************************************************************************************/

  /* -------------------------
   *
   * private table_hc
   *
   * ------------------------- */
  PROCEDURE table_hc (p_tab_rec IN sqlt$_dba_all_tables_v%ROWTYPE)
  IS
    l_count    NUMBER;
    l_factor   NUMBER;
    l_ratio    NUMBER;
    l_number   NUMBER;
    l_date     DATE;
    l_no_stats NUMBER;
    l_rows_0   NUMBER;

  BEGIN
    write_log('-> table_hc_'||p_tab_rec.table_name);

    -- (076)
	-- empty_blocks > blocks
    IF p_tab_rec.empty_blocks > p_tab_rec.blocks THEN
      s_obs_rec.priority	:= 38;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Check if the table(s) in this query is a rebuild candidate(s). It has more empty blocks ('||p_tab_rec.empty_blocks||') than actual blocks ('||p_tab_rec.blocks||'). Also see MOS Note Index Rebuild, the Need vs the Implications (Doc ID 989093.1).';
      s_obs_rec.more        := 'Review <a href="#tab_stats">table statistics</a> and consider re-organizing this Table.';
      ins_obs;
    END IF;

    -- (077)
	-- rebuild candidates
    -- SYS.DBMS_SPACE.CREATE_TABLE_COST
    IF p_tab_rec.dbms_space_alloc_blocks < 0.9 * p_tab_rec.total_segment_blocks THEN
      s_obs_rec.priority    := 39;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Check if the table(s) in this query are rebuild candidates. Also see MOS Note Index Rebuild, the Need vs the Implications (Doc ID 989093.1).';
      s_obs_rec.more        := 'Review <a href="#tab_stats">table statistics</a> and look for Total Segment Blocks('||p_tab_rec.total_segment_blocks||') and DBMS_SPACE Allocated Blocks('||p_tab_rec.dbms_space_alloc_blocks||').';
      ins_obs;
    END IF;

    -- (078)
	-- table degree > 1
    IF TRIM(p_tab_rec.degree) NOT IN ('0', '1') THEN
      s_obs_rec.priority	:= 46;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Confirm that the DOP set on table(s) in this query are appropriate. Table''s DOP is "'||p_tab_rec.degree||'". See MOS Note Table-level PARALLEL hint may give wrong DOP or ORA-12850 without fix for Bug 21612531; ORA-7445 in kkfdDegreeLimit() with fix present (Doc ID 2286868.1).';
      s_obs_rec.more        := 'Degree of parallelism other than 1 may cause parallel-execution plans. Review <a href="#tab_prop">table properties</a> and execute "ALTER TABLE '||p_tab_rec.owner||'.'||p_tab_rec.table_name||' NOPARALLEL" to reset degree of parallelism to 1 if parallel-execution plans are not desired.';
      ins_obs;
    END IF;

    -- (079)
	-- index degree > 1
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_indexes
       WHERE statement_id = p_tab_rec.statement_id
         AND table_owner = p_tab_rec.owner
         AND table_name = p_tab_rec.table_name
         AND TRIM(degree) NOT IN ('0', '1');

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 71;
	    s_obs_rec.type_id     := E_TABLE;
        s_obs_rec.object_type := 'TABLE';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Check the DEGREE setting on some index(es). '||l_count||' index(es) with DOP other than 1. See MOS Note DEGREE column in DBA_INDEXES has the value DEFAULT instead of number (Doc ID 1620092.1)';
        s_obs_rec.more        := 'Degree of parallelism other than 1 may cause parallel-execution plans. Review <a href="#idx_prop_'||p_tab_rec.object_id||'">index properties</a> and execute "ALTER INDEX index_name NOPARALLEL" to reset degree of parallelism to 1 if parallel-execution plans are not desired.';
        ins_obs;
      END IF;
    END;

    -- (080)
	-- index degree <> table degree
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_indexes
       WHERE statement_id = p_tab_rec.statement_id
         AND table_owner = p_tab_rec.owner
         AND table_name = p_tab_rec.table_name
         AND TRIM(degree) <> TRIM(p_tab_rec.degree);

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 1;
	    s_obs_rec.type_id     := E_TABLE;
        s_obs_rec.object_type := 'TABLE';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Table has '||l_count||' index(es) with DOP different than its table.';
        s_obs_rec.more        := 'Table has a degree of parallelism of "'||TRIM(p_tab_rec.degree)||'". Review <a href="#idx_prop_'||p_tab_rec.object_id||'">index properties</a> and fix degree of parallelism of table and/or its index(es).';
        ins_obs;
      END IF;
    END;

    -- (081)
	-- no stats
    IF p_tab_rec.temporary = 'N' AND (p_tab_rec.last_analyzed IS NULL OR p_tab_rec.num_rows IS NULL) THEN
      s_obs_rec.priority    := 100;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Table lacks CBO Statistics.';

      IF s_sql_rec.siebel = 'YES' AND p_tab_rec.count_star > 15 THEN
        s_obs_rec.more      := 'Consider gathering statistics on the tables in this query. <a href="#tab_stats">table statistics</a> using coe_siebel_stats.sql. See MOS Performance Tuning Guidelines for Siebel CRM Application on Oracle Database (Doc ID 2077227.2).';
        ins_obs;
      ELSIF s_sql_rec.psft = 'YES' THEN
        s_obs_rec.more      := 'Consider gathering statistics on the tables in this query. <a href="#tab_stats">table statistics</a> using pscbo_stats.sql. See MOS Note pscbo_stats - Improving Statistics in Oracle RDBMS for PeopleSoft Enterprise (Doc ID 1322888.1).';
        ins_obs;
      ELSIF s_sql_rec.apps_release IS NOT NULL THEN
        s_obs_rec.more      := 'Consider gathering <a href="#tab_stats">table statistics</a> using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql. See MOS Note coe_stats.sql - Automates CBO Stats Gathering using FND_STATS and Table sizes (Doc ID 156968.1).';
        ins_obs;
      ELSIF s_sql_rec.apps_release IS NULL AND NVL(s_sql_rec.siebel, 'NO') = 'NO' AND NVL(s_sql_rec.psft, 'NO') = 'NO' AND NVL(p_tab_rec.count_star, 101) > 100 THEN
        s_obs_rec.more      := 'Consider gathering <a href="#tab_stats">table statistics</a> using SYS.DBMS_STATS.GATHER_TABLE_STATS. See MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1).';
        ins_obs;
      END IF;
    END IF;

    -- (082)
	-- no rows
    IF p_tab_rec.num_rows = 0 THEN
    	s_obs_rec.priority	  := 70;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Investigate why the number of rows is equal to zero according to table''s CBO statistics.';

      IF p_tab_rec.temporary = 'Y' THEN
        s_obs_rec.more      := 'Consider deleting <a href="#tab_stats">table statistics</a> on this GTT using SYS.DBMS_STATS.DELETE_TABLE_STATS.';
        ins_obs;
      ELSIF s_sql_rec.siebel = 'YES' AND p_tab_rec.count_star > 15 THEN
        s_obs_rec.more      := 'Consider gathering <a href="#tab_stats">table statistics</a> using coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
        ins_obs;
      ELSIF s_sql_rec.siebel = 'YES' AND p_tab_rec.count_star <= 15 THEN
        s_obs_rec.more      := 'Consider deleting <a href="#tab_stats">table statistics</a> on this small table using SYS.DBMS_STATS.DELETE_TABLE_STATS. See MOS Doc ID 781927.1.';
        ins_obs;
      ELSIF s_sql_rec.psft = 'YES' AND NVL(p_tab_rec.count_star, 1) > 0 THEN
        s_obs_rec.more      := 'Consider gathering <a href="#tab_stats">table statistics</a> using pscbo_stats.sql. See MOS Doc ID 1322888.1.';
        ins_obs;
      ELSIF s_sql_rec.apps_release IS NOT NULL AND NVL(p_tab_rec.count_star, 1) > 0 THEN
        s_obs_rec.more      := 'Consider gathering <a href="#tab_stats">table statistics</a> using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql. See MOS Doc ID 156968.1.';
        ins_obs;
      ELSIF s_sql_rec.apps_release IS NULL AND NVL(s_sql_rec.siebel, 'NO') = 'NO' AND NVL(s_sql_rec.psft, 'NO') = 'NO' AND NVL(p_tab_rec.count_star, 1) > 0 THEN
        s_obs_rec.more      := 'Consider gathering <a href="#tab_stats">table statistics</a> using SYS.DBMS_STATS.GATHER_TABLE_STATS. See MOS Doc ID 465787.1.';
        ins_obs;
      END IF;
    END IF;

    -- (083)
	-- GTT or table with TEMP in the name with stats showing 0 rows and A-Rows > 0 from plan
    IF p_tab_rec.num_rows = 0 AND (p_tab_rec.temporary = 'Y' OR p_tab_rec.table_name LIKE '%TEMP' OR p_tab_rec.table_name LIKE '%\_TEMP\_%' ESCAPE '\') THEN
      SELECT count(*)
        INTO l_count
        FROM sqlt$_plan_statistics_v
       WHERE (object_name = p_tab_rec.table_name 
          OR  object_name IN (SELECT index_name 
                                FROM sqlt$_dba_indexes
                               WHERE table_name = p_tab_rec.table_name))
         AND object_owner = p_tab_rec.owner
         AND last_output_rows > 0;

      s_obs_rec.priority    := 80;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Check to see if the table(s) in this query had statistics collected at the right time, i.e. AFTER data was loaded. See MOS Note .';
      s_obs_rec.more      := 'Delete <a href="#tab_stats">table statistics</a> on this TEMP table.';
      ins_obs;

    END IF;

    -- (084)
	-- check for Doc ID 1491748.1 -- This Observation is too generic. Stelios Charalambides. 11th January 2019. 
    IF p_tab_rec.table_name = 'SEG$' AND p_tab_rec.owner = 'SYS'  THEN
      s_obs_rec.priority	:= 25;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Check your configuration against MOS Note Encountering Slow Performance Reading *_SEGMENTS or *_TS_QUOTAS (Doc ID 1491748.1).';
      s_obs_rec.more      := 'Information about segment sizing are usually cached to allow faster access, in case they are not you might experience slow performance when accessing such views, refer to Doc ID 1491748.1 for details.';
      ins_obs;
    END IF;

    -- (085)
	-- table mutating num_rows
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_tab_statistics
       WHERE statement_id = p_tab_rec.statement_id
         AND object_type = 'TABLE'
         AND owner = p_tab_rec.owner
         AND table_name = p_tab_rec.table_name
         AND mutating_num_rows = 'TRUE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 39;
	    s_obs_rec.type_id     := E_TABLE;
        s_obs_rec.object_type := 'TABLE';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Check your statistics gathering against the best practices as seen in the MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1). BLEVEL is fluctuating significantly.';
        s_obs_rec.more        := 'Review <a href="#tab_cbo_vers">table statistics versions</a> for this table and look for "Num Rows" column. Significant changes in the number of rows for a Table could cause the execution plan to change.';
        ins_obs;
      END IF;
    END;

    -- (086)
	-- table partition mutating num_rows
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_tab_statistics
       WHERE statement_id = p_tab_rec.statement_id
         AND object_type = 'PARTITION'
         AND owner = p_tab_rec.owner
         AND table_name = p_tab_rec.table_name
         AND mutating_num_rows = 'TRUE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 39;
	    s_obs_rec.type_id     := E_TABLE;
        s_obs_rec.object_type := 'TABLE PARTITION';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Check your statistics gathering against the best practices as seen in the MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1). Table contains '||l_count||' partitions with fluctuating number of rows.';
        s_obs_rec.more        := 'Significant changes in the number of rows for partitions could cause the execution plan to change if partition statistics are used by the CBO.';
        ins_obs;
      END IF;
    END;

    -- (087)
	-- table subpartition mutating num_rows
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_tab_statistics
       WHERE statement_id = p_tab_rec.statement_id
         AND object_type = 'SUBPARTITION'
         AND owner = p_tab_rec.owner
         AND table_name = p_tab_rec.table_name
         AND mutating_num_rows = 'TRUE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 39;
	    s_obs_rec.type_id     := E_TABLE;
        s_obs_rec.object_type := 'TABLE SUBPARTITION';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Check your statistics gathering against the best practices as seen in the MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1). Table contains '||l_count||' subpartitions with fluctuating number of rows.';
        s_obs_rec.more        := 'Significant changes in the number of rows for subpartitions could cause the execution plan to change if subpartition statistics are used by the CBO.';
        ins_obs;
      END IF;
    END;

    -- (088)
	-- SIEBEL small tables
    IF (p_tab_rec.num_rows <= 15 OR p_tab_rec.count_star <= 15) AND s_sql_rec.siebel = 'YES' AND p_tab_rec.num_rows IS NOT NULL THEN
      s_obs_rec.priority	:= 68;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Review your statistics collection for Siebel against the MOS Note Performance Tuning Guidelines for Siebel CRM Application on Oracle Database (Doc ID 2077227.2). See the script coe_siebel_stats_11_4_6.sql. Small tables should not have SQL statistics.';
      s_obs_rec.more        := 'Consider deleting <a href="#tab_stats">table statistics</a> on this small table using SYS.DBMS_STATS.DELETE_TABLE_STATS. See MOS Note Performance Tuning Guidelines for Siebel CRM Application on Oracle Database (Doc ID 2077227.2).';
      ins_obs;
    END IF;

    -- (089)
	-- numrows <> count by > 10%
    IF p_tab_rec.num_rows > 0 AND
       p_tab_rec.count_star > 0 AND
       p_tab_rec.count_star <> sqlt$a.get_param_n('count_star_threshold') AND
       sqlt$t.differ_more_than_x_perc(p_tab_rec.num_rows, p_tab_rec.count_star, 10)
    THEN
      s_obs_rec.priority	:= 63;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Check why COUNT(*) ('||p_tab_rec.count_star||') and NUM_ROWS ('||p_tab_rec.num_rows||') are more than 10% different ('||sqlt$t.difference_percent(p_tab_rec.num_rows, p_tab_rec.count_star)||'%). See MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1)';

      IF s_sql_rec.siebel = 'YES' AND LEAST(p_tab_rec.num_rows, p_tab_rec.count_star) > 15 THEN
        s_obs_rec.more      := 'Consider gathering <a href="#tab_stats">table statistics</a> using coe_siebel_stats.sql. See MOS Note Performance Tuning Guidelines for Siebel CRM Application on Oracle Database (Doc ID 2077227.2).';
        ins_obs;
      ELSIF s_sql_rec.siebel = 'YES' AND LEAST(p_tab_rec.num_rows, p_tab_rec.count_star) <= 15 THEN
        s_obs_rec.more      := 'Consider deleting <a href="#tab_stats">table statistics</a> on this small table using SYS.DBMS_STATS.DELETE_TABLE_STATS. See MOS Note Performance Tuning Guidelines for Siebel CRM Application on Oracle Database (Doc ID 2077227.2).';
        ins_obs;
      ELSIF s_sql_rec.psft = 'YES' THEN
        s_obs_rec.more      := 'Consider gathering <a href="#tab_stats">table statistics</a> using pscbo_stats.sql. See MOS Note pscbo_stats - Improving Statistics in Oracle RDBMS for PeopleSoft Enterprise (Doc ID 1322888.1).';
        ins_obs;
      ELSIF s_sql_rec.apps_release IS NOT NULL THEN
        s_obs_rec.more      := 'Consider gathering <a href="#tab_stats">table statistics</a> using FND_STATS.GATHER_TABLE_STATS or coe_stats.sql. See MOS Note coe_stats.sql - Automates CBO Stats Gathering using FND_STATS and Table sizes (Doc ID 156968.1).';
        ins_obs;
      ELSIF s_sql_rec.apps_release IS NULL AND NVL(s_sql_rec.siebel, 'NO') = 'NO' AND NVL(s_sql_rec.psft, 'NO') = 'NO' THEN
        s_obs_rec.more      := 'Consider gathering <a href="#tab_stats">table statistics</a> using SYS.DBMS_STATS.GATHER_TABLE_STATS. See MOS Note How to: Manage CBO Statistics During an Upgrade from 10g or 9i into 11g/12c (Doc ID 465787.1).';
        ins_obs;
      END IF;
    END IF;

    IF p_tab_rec.num_rows > 0 THEN
      l_ratio := p_tab_rec.sample_size/p_tab_rec.num_rows;

      IF p_tab_rec.num_rows < 1e6 THEN -- up to 1M then 100%
        l_factor := 1;
      ELSIF p_tab_rec.num_rows < 1e7 THEN -- up to 10M then 30%
        l_factor := 3/10;
      ELSIF p_tab_rec.num_rows < 1e8 THEN -- up to 100M then 10%
        l_factor := 1/10;
      ELSIF p_tab_rec.num_rows < 1e9 THEN -- up to 1B then 3%
        l_factor := 3/100;
      ELSE -- more than 1B then 1%
        l_factor := 1/100;
      END IF;
    ELSE
      l_ratio := NULL;
      l_factor := NULL;
    END IF;

    -- (090)
	-- small sample size in table
    IF p_tab_rec.sample_size < LEAST(2000, p_tab_rec.num_rows) THEN
      s_obs_rec.priority	:= 50;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Check your statistics collection procedures and compare them to the best practices in MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1). Sample size of '||p_tab_rec.sample_size||' rows is too small for table with '||p_tab_rec.num_rows||' rows. Sample percent used was:'||TRIM(TO_CHAR(ROUND(l_ratio * 100, 2), PERCENT_FORMAT))||'%.';
      s_obs_rec.more        := 'Consider gathering better quality <a href="#tab_stats">table statistics</a> with a larger sample size. Suggested sample size: ';
      IF s_sql_rec.rdbms_release < 11 THEN
        s_obs_rec.more := s_obs_rec.more||ROUND(l_factor * 100)||'%.';
      ELSE
        s_obs_rec.more := s_obs_rec.more||'DBMS_STATS.AUTO_SAMPLE_SIZE (default).';
      END IF;
      ins_obs;
    END IF;

    -- (091) 
	-- outdated statistics
    IF p_tab_rec.last_analyzed < SYSDATE - 49 OR
       (p_tab_rec.num_rows BETWEEN 0 AND 1e6 AND p_tab_rec.last_analyzed < SYSDATE - 21) OR
       (p_tab_rec.num_rows BETWEEN 1e6 AND 1e7 AND p_tab_rec.last_analyzed < SYSDATE - 28) OR
       (p_tab_rec.num_rows BETWEEN 1e7 AND 1e8 AND p_tab_rec.last_analyzed < SYSDATE - 35) OR
       (p_tab_rec.num_rows BETWEEN 1e8 AND 1e9 AND p_tab_rec.last_analyzed < SYSDATE - 42)
    THEN
      s_obs_rec.priority    := 56;
	  s_obs_rec.type_id     := E_TABLE;
      s_obs_rec.object_type := 'TABLE';
      s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
      s_obs_rec.observation := 'Check your statistics collection procedures and compare them to the best practices in MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1). Table CBO statistics are '||ROUND(SYSDATE - p_tab_rec.last_analyzed)||' days old. Gathered: '||TO_CHAR(p_tab_rec.last_analyzed, LOAD_DATE_FORMAT);
      s_obs_rec.more        := 'Consider gathering fresh <a href="#tab_stats">table statistics</a>. Old statistics could contain low/high values for which a predicate may be out of range, producing then a poor plan. Suggested sample size: ';
      IF s_sql_rec.rdbms_release < 11 THEN
        s_obs_rec.more := s_obs_rec.more||ROUND(l_factor * 100)||'%. ';
      ELSE
        s_obs_rec.more := s_obs_rec.more||'DBMS_STATS.AUTO_SAMPLE_SIZE (default). ';
      END IF;
      ins_obs;
    END IF;

    -- (092)
	-- extended statistics
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_stat_extensions
       WHERE statement_id = p_tab_rec.statement_id
         AND owner = p_tab_rec.owner
         AND table_name = p_tab_rec.table_name;

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 12;
	    s_obs_rec.type_id     := E_TABLE;
        s_obs_rec.object_type := 'TABLE';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Check the applicability of the Extended Statistics found on the table(s) in this query. Also see MOS Note How To Find Candidate Columns For Creating Extended Statistics Using "DBMS_STATS.SEED_COL_USAGE" (Doc ID 1430317.1). Table has '||l_count||' CBO statistics extension(s).';
        s_obs_rec.more        := 'Review <a href="#tab_cbo_ext">table statistics extensions</a>. Extensions can be used for expressions or column groups. If your SQL contain matching predicates these extensions can influence the CBO.';
        ins_obs;
      END IF;
    END;
	
	-- (093)
	-- Data Vault censored low/high value
    BEGIN
      IF p_tab_rec.dv_censored = 'Y'  THEN
    	s_obs_rec.priority	  := 11;
	    s_obs_rec.type_id     := E_TABLE;
        s_obs_rec.object_type := 'TABLE';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Check the applicability of the user SQLTXADMIN not being able to access basic information about tables due to Data Vault. Table protected by Data Vault, low/high values will be missing from the report';
        s_obs_rec.more        := 'The low/high values for this table are not reported by SQLT since they are protected by Data Vault.<br>To fix, the user SQLTXADMIN must be directly added to the realm controlling access to the table as a participant.<br>For example, with EBS, tables in APPS are controlled by the realm ''EBS Realm - Apps Schema'', so the following run as <br>someone with DV_OWNER or DV_ADMIN will grant that right: <br>EXEC DVSYS.DBMS_MACADM.ADD_AUTH_TO_REALM(realm_name  => ''EBS Realm - Apps Schema'', grantee => ''SQLTXADMIN'');';
        ins_obs;
      END IF;	  
	END;	

    -- (094)
	-- table columns
    IF p_tab_rec.last_analyzed IS NOT NULL AND p_tab_rec.num_rows IS NOT NULL THEN
      -- columns with no stats
      BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_all_table_cols_v
         WHERE statement_id = p_tab_rec.statement_id
           AND owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name
           AND last_analyzed IS NULL
           AND in_predicates = 'TRUE';

        IF l_count > 0 THEN
    	  s_obs_rec.priority	:= 67;
	      s_obs_rec.type_id     := E_TABLE;
          s_obs_rec.object_type := 'TABLE';
          s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
          s_obs_rec.observation := 'Check the applicability of having no Column Statisitcs on '||l_count||' column(s) referenced in query predicates. See MOS Note Incorrect Column Statistics Causing Queries To Take Bad Plans (Doc ID 552363.1).';
          s_obs_rec.more        := 'CBO has to guess the missing <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a>. Consider gathering statistics for this table.';
          ins_obs;
        END IF;
      END;

      -- (095)
	  -- columns missing low/high values
      BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_all_table_cols_v
         WHERE statement_id = p_tab_rec.statement_id
           AND owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name
           AND last_analyzed IS NOT NULL
           AND num_distinct > 0
           AND in_predicates = 'TRUE'
           AND (low_value IS NULL OR high_value IS NULL);

        IF l_count > 0 THEN
    	  s_obs_rec.priority	:= 73;
	      s_obs_rec.type_id     := E_TABLE;
          s_obs_rec.object_type := 'TABLE';
          s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
          s_obs_rec.observation := 'Check why there are '||l_count||' column(s) referenced in predicates with null low/high values. See MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1).';
          s_obs_rec.more        := 'CBO cannot compute correct selectivity with these <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> missing. You may possibly have Bug 10248781. Consider gathering statistics for this table.';
          ins_obs;
        END IF;
      END;

      -- (096)
	  -- columns with old stats
      BEGIN
        SELECT MIN(last_analyzed)
          INTO l_date
          FROM sqlt$_dba_all_table_cols_v
         WHERE statement_id = p_tab_rec.statement_id
           AND owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name;

        IF ABS(p_tab_rec.last_analyzed - l_date) > 1 THEN
          s_obs_rec.priority    := 30;
	      s_obs_rec.type_id     := E_TABLE;
          s_obs_rec.object_type := 'TABLE';
          s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
          s_obs_rec.observation := 'Consider the applicability of the statistics on the table as it contains columns with outdated CBO statistics for up to '||TRUNC(ABS(p_tab_rec.last_analyzed - l_date))||' day(s). Also see Best Practices for Automatic Statistics Collection (Doc ID 377152.1).';
          s_obs_rec.more        := 'CBO table and <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> are inconsistent. Consider gathering statistics for this table. Old statistics could contain low/high values for which a predicate may be out of range, producing a poor plan.';
          ins_obs;
        END IF;
      END;
      --(097)
      IF p_tab_rec.num_rows > 0 THEN
        -- more nulls than rows
        BEGIN
          SELECT COUNT(*), MAX(num_nulls)
            INTO l_count, l_number
            FROM sqlt$_dba_all_table_cols_v
           WHERE statement_id = p_tab_rec.statement_id
             AND owner = p_tab_rec.owner
             AND table_name = p_tab_rec.table_name
             AND num_nulls > p_tab_rec.num_rows
             AND sqlt$t.differ_more_than_x_percent(num_nulls, p_tab_rec.num_rows, 10) = 'Y';

          IF l_count > 0 THEN
    	    s_obs_rec.priority	  := 80;
	        s_obs_rec.type_id     := E_TABLE;
            s_obs_rec.object_type := 'TABLE';
            s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
            s_obs_rec.observation := 'Find out why statistics are wrong and collect fresh statisitics if needed. The number of nulls is greater than number of rows by more than 10% in '||l_count||' column(s). Also see MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1)';
            s_obs_rec.more        := 'There cannot be more rows with null value in a column than actual rows in the table. Worst column shows '||l_number||' nulls while table has '||p_tab_rec.num_rows||' rows. CBO table and <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> are inconsistent. Consider gathering statistics for this table using a large sample size.';
            ins_obs;
          END IF;
        END;

        -- (098)
		-- more distinct values than rows
        BEGIN
          SELECT COUNT(*), MAX(num_distinct)
            INTO l_count, l_number
            FROM sqlt$_dba_all_table_cols_v
           WHERE statement_id = p_tab_rec.statement_id
             AND owner = p_tab_rec.owner
             AND table_name = p_tab_rec.table_name
             AND num_distinct > p_tab_rec.num_rows
             AND sqlt$t.differ_more_than_x_percent(num_distinct, p_tab_rec.num_rows, 10) = 'Y';

          IF l_count > 0 THEN
    	    s_obs_rec.priority	  := 80;
	        s_obs_rec.type_id     := E_TABLE;
            s_obs_rec.object_type := 'TABLE';
            s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
            s_obs_rec.observation := 'Find out why statisitcs are wrong and consider collecting fresh statistics if needed. The number of distinct values is greater than number or rows by more than 10% in '||l_count||' column(s). Also see MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1)';
            s_obs_rec.more        := 'There cannot be a larger number of distinct values in a column than actual rows in the table. Worst column shows '||l_number||' distinct values while table has '||p_tab_rec.num_rows||' rows. CBO table and <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> are inconsistent. Consider gathering statistics for this table using a large sample size.';
            ins_obs;
          END IF;
        END;

        -- (099)
		-- zero distinct values on columns with value
        BEGIN
          SELECT COUNT(*), MAX(p_tab_rec.num_rows - num_nulls)
            INTO l_count, l_number
            FROM sqlt$_dba_all_table_cols_v
           WHERE statement_id = p_tab_rec.statement_id
             AND owner = p_tab_rec.owner
             AND table_name = p_tab_rec.table_name
             AND p_tab_rec.num_rows > num_nulls
             AND num_distinct = 0
             AND sqlt$t.differ_more_than_x_percent(num_nulls, p_tab_rec.num_rows, 10) = 'Y';

          IF l_count > 0 THEN
    	    s_obs_rec.priority	  := 80;
	        s_obs_rec.type_id     := E_TABLE;
            s_obs_rec.object_type := 'TABLE';
            s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
            s_obs_rec.observation := 'Find out why statistics are wrong and consider collecting fresh statistics if needed. Number of distinct values is zero in at least '||l_count||' column(s) with value. Also see MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1).';
            s_obs_rec.more        := 'There should not be columns with value ((num_rows - num_nulls) greater than 0) where the number of distinct values for the same column is zero. Worst column shows '||l_number||' rows with value while the number of distinct values for it is zero. CBO table and <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> are inconsistent. Consider gathering statistics for this table using a large sample size.';
            ins_obs;
          END IF;
        END;
      END IF;

      -- (100)
	  -- mutating ndv
      BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_all_table_cols_v
         WHERE statement_id = p_tab_rec.statement_id
           AND owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name
           AND mutating_ndv = 'TRUE'
           AND in_predicates = 'TRUE';

        IF l_count > 0 THEN
    	  s_obs_rec.priority    := 35;
	      s_obs_rec.type_id     := E_TABLE;
          s_obs_rec.object_type := 'TABLE';
          s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
          s_obs_rec.observation := 'Confirm statisitcs are correct. Check the effect of changing number of NDV on execution plans. Table contains '||l_count||' column(s) referenced in predicates with fluctuating number of distinct values. Also see Bug Bug 9885553 - DBMS_STATS produces incorrect column NDV distinct values statistics (Doc ID 9885553.8).';
          s_obs_rec.more        := 'Review <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> for this table and look for "Fluctuating NDV Count". There are column(s) referenced in predicates for which according to "Column Statistics Versions", the number of "Distinct Values" has changed in the near past. This could cause plan changes.';
          ins_obs;
        END IF;
      END;

      -- (101)
	  -- mutating histograms
      BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_all_table_cols_v
         WHERE statement_id = p_tab_rec.statement_id
           AND owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name
           AND mutating_endpoints = 'TRUE'
           AND in_predicates = 'TRUE';

        IF l_count > 0 THEN
    	  s_obs_rec.priority	:= 45;
	      s_obs_rec.type_id     := E_TABLE;
          s_obs_rec.object_type := 'TABLE';
          s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
          s_obs_rec.observation := 'Confirm statistics are correct. Check the effect of fluctuating histogram end point values on the plans chosen by the Optimizer. Table contains '||l_count||' column(s) referenced in predicates with fluctuating number of histogram endpoints count. Also see MOS Note Histograms: An Overview (10g and Above) (Doc ID 1445372.1).';
          s_obs_rec.more        := 'Review <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> for this table and look for "Fluctuating Endpoint Count". There are column(s) referenced in predicates for which according to "Column Statistics Versions", the number of "Endpoint Count" has changed in the near past. This could cause plan changes.';
          ins_obs;
        END IF;
      END;

      -- (102)
	  -- 13583722 is applied and table is partitioned and columns have histogram
      BEGIN
        IF sqlt$a.get_sqlt_v$session_fix_control(p_tab_rec.statement_id, 13583722) > 0 AND p_tab_rec.partitioned = 'YES' THEN
          SELECT COUNT(*)
            INTO l_count
            FROM sqlt$_dba_all_table_cols_v
           WHERE statement_id = p_tab_rec.statement_id
             AND owner = p_tab_rec.owner
             AND table_name = p_tab_rec.table_name
             AND histogram IN ('FREQUENCY', 'HEIGHT BALANCED')
             AND in_predicates = 'TRUE';

          IF l_count > 0 THEN
    	    s_obs_rec.priority	  := 76;
	        s_obs_rec.type_id     := E_TABLE;
            s_obs_rec.object_type := 'TABLE';
            s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
            s_obs_rec.observation := 'Check the applicability of Bug 13583722, which may cause slowness and wrong histogram data. Also see MOS Note Bug 13583722 - Slow incremental stats gather from global histogram gathers (Doc ID 13583722.8).';
            s_obs_rec.more        := 'Partitioned table contains '||l_count||' column(s) referenced in predicates. Patch for bug 13583722 has been applied. If statistics were gathered with "INCREMENTAL" then histograms from partitions may not be used by the CBO.';
            ins_obs;
          END IF;
        END IF;
      END;

      -- (103)
	  -- 10174050 frequency histograms with less buckets than ndv
      BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_all_table_cols_v
         WHERE statement_id = p_tab_rec.statement_id
           AND owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name
           AND histogram = 'FREQUENCY'
           AND num_distinct <> num_buckets
           AND in_predicates = 'TRUE';

        IF l_count > 0 THEN
          s_obs_rec.priority    := 76;
	      s_obs_rec.type_id     := E_TABLE;
          s_obs_rec.object_type := 'TABLE';
          s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
          s_obs_rec.observation := 'Check the applicability of Bug 10174050. This may cause missing values from Frequency histograms. Table contains '||l_count||' column(s) referenced in predicates where the number of distinct values does not match the number of buckets. Also see MOS Note Unexpected Poor Execution Plan When Non-Popular Value Missing from Histogram (Doc ID 1563752.1).';
          s_obs_rec.more        := 'Review <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> for this table and look for "Num Distinct" and "Num Buckets". If there are values missing from the frequency histogram you may have Bug 10174050. If you are referencing in your predicates one of the missing values the CBO can over estimate table cardinality, and this may produce a sub-optimal plan. As a workaround: alter system/session "_fix_control"=''5483301:off'';';
          ins_obs;
        END IF;
      END;

      -- (104)
	  -- frequency histogram with 1 bucket
      BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_all_table_cols_v
         WHERE statement_id = p_tab_rec.statement_id
           AND owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name
           AND histogram = 'FREQUENCY'
           AND num_buckets = 1
           AND in_predicates = 'TRUE';

        IF l_count > 0 THEN
    	  s_obs_rec.priority	:= 20;
	      s_obs_rec.type_id     := E_TABLE;
          s_obs_rec.object_type := 'TABLE';
          s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
          s_obs_rec.observation := 'Check the applicability of bugs 1386119, 4406309, 4495422, 4567767, 5483301 or 6082745. Table contains '||l_count||' column(s) referenced in predicates where the number of buckets is 1 for a "FREQUENCY" histogram. ';
          s_obs_rec.more        := 'Review <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> for this table and look for "Num Buckets" and "Histogram". Possible Bugs 1386119, 4406309, 4495422, 4567767, 5483301 or 6082745. If you are referencing in your predicates one of the missing values the CBO can over estimate table cardinality, and this may produce a sub-optimal plan. As a workaround: alter system/session "_fix_control"=''5483301:off'';';
          ins_obs;
        END IF;
      END;

      -- (105)
	  -- height balanced histogram with no popular values
/*      BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_all_table_cols_v
         WHERE statement_id = p_tab_rec.statement_id
           AND owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name
           AND histogram = 'HEIGHT BALANCED'
           AND popular_values = 0
           AND in_predicates = 'TRUE';

        IF l_count > 0 THEN
          s_obs_rec.priority    := 32;
	      s_obs_rec.type_id     := E_TABLE;
          s_obs_rec.object_type := 'TABLE';
          s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
          s_obs_rec.observation := 'Check the correctness of the histogram on columns referenced in predicates for this query. Table contains '||l_count||' column(s) referenced in predicates with no popular values on a "HEIGHT BALANCED" histogram. Also see MOS Note Interpreting Histogram Information (Doc ID 72539.1).';
          s_obs_rec.more        := 'Review <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> for this table and look for "Histogram" and "Popular Values". A Height-balanced histogram with no popular values might not be helpful in case the data is almost uniformly distributed. If that''s the case then consider dropping this histogram by collecting new CBO statistics while using METHOD_OPT with SIZE 1.';
          ins_obs;
        END IF;
      END; */
	  
	  -- (106)
	  -- columns added via _add_col_optim_enabled
	  BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_all_table_cols_v
         WHERE statement_id = p_tab_rec.statement_id
           AND owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name
           AND add_column_default = 'Y';

        IF l_count > 0 THEN
    	  s_obs_rec.priority    := 28;
	      s_obs_rec.type_id     := E_TABLE;
          s_obs_rec.object_type := 'TABLE';
          s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
          s_obs_rec.observation := 'Check the data created via Default Values is correct as a column was added via _add_col_optim_enabled. Table contains '||l_count||' column(s) added after the table was created and with a default value added via optimization. Also see MOS Note Init.ora Parameter "_ADD_COL_OPTIM_ENABLED" [Hidden] Reference Note (Doc ID 1492674.1).';
          s_obs_rec.more        := 'The table contains column(s) added after the table was created with default value';
          ins_obs;
        END IF;	    	  	  
	  END;

      -- (107)
	  -- analyze 236935.1 and derived stats
      IF p_tab_rec.global_stats = 'NO' THEN
	    
        s_obs_rec.type_id     := E_TABLE;
        s_obs_rec.object_type := 'TABLE';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        IF p_tab_rec.partitioned = 'NO' THEN
		  s_obs_rec.priority    := 28;
          s_obs_rec.observation := 'Check that you are not gathering statistics with ANALYZE. This is not valid. Collect using dbms_stats, coe_siebel_stats or fnd_Stats as needed. Also see MOS Note How to Move from ANALYZE to DBMS_STATS on Non-Partitioned Tables - Some Examples (Doc ID 237537.1).';
          s_obs_rec.more      := 'When ANALYZE is used on a non-partitioned table, the global_stats column of the <a href="#tab_stats">table statistics</a> receives a value of ''NO''. Consider gathering statistics using ';
        ELSE
		  s_obs_rec.priority    := 28;
          s_obs_rec.observation := 'Check your statistics for the partitioned object. CBO statistics are being derived by aggregation from lower level objects. Collect using dbms_stats, coe_siebel_stats or fnd_Stats as needed. Also see MOS Note Global statistics - An Explanation (Doc ID 236935.1).';
          s_obs_rec.more      := 'When statistics are derived by aggregation from lower level objects, the global_stats column of the <a href="#tab_stats">table statistics</a> receives a value of ''NO''. Consider gathering statistics using ';
        END IF;
        IF s_sql_rec.siebel = 'YES' THEN
          s_obs_rec.more      := s_obs_rec.more||'coe_siebel_stats.sql instead. See MOS Doc ID 781927.1.';
        ELSIF s_sql_rec.psft = 'YES' THEN
          s_obs_rec.more      := s_obs_rec.more||'pscbo_stats.sql. See MOS Doc ID 1322888.1.';
        ELSIF s_sql_rec.apps_release IS NOT NULL THEN
          s_obs_rec.more      := s_obs_rec.more||'FND_STATS instead.';
        ELSE
          s_obs_rec.more      := s_obs_rec.more||'DBMS_STATS instead.';
        END IF;
        ins_obs;
      END IF;
    END IF; -- table columns

    -- (108)
	-- tables not referenced
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_plan_extension
       WHERE statement_id = p_tab_rec.statement_id
         AND object_owner = p_tab_rec.owner
         AND object_name = p_tab_rec.table_name
         AND (object_type LIKE '%TABLE%' OR object_type LIKE '%MAT%VIEW%' OR operation LIKE '%TABLE%ACCESS%' OR operation LIKE '%MAT%VIEW%ACCESS%')
         AND ROWNUM = 1;

      IF l_count = 0 THEN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_plan_extension p,
               sqlt$_dba_indexes i
         WHERE p.statement_id = p_tab_rec.statement_id
           AND (p.object_type LIKE '%INDEX%' OR p.operation LIKE '%INDEX%')
           AND p.statement_id = i.statement_id
           AND p.object_owner = i.owner
           AND p.object_name = i.index_name
           AND i.table_owner = p_tab_rec.owner
           AND i.table_name = p_tab_rec.table_name
           AND ROWNUM = 1;

        IF l_count = 0 THEN
    	  s_obs_rec.priority	:= 2;
	      s_obs_rec.type_id     := E_TABLE;
          s_obs_rec.object_type := 'TABLE';
          s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
          s_obs_rec.observation := 'Check the validity of this table being referenced. Table not referenced by any Plan.';
          s_obs_rec.more        := 'This table was selected since a plan seems to have a dependency on it, but it was not referenced directly in the plan. If the table is not referenced by a subquery, ignore then this message.';
          ins_obs;
        END IF;
      END IF;
    END; -- tables not referenced

    -- (109)
	-- redundant indexes
    BEGIN
      FOR i IN (SELECT owner,
                       index_name,
                       index_column_names
                  FROM sqlt$_dba_indexes
                 WHERE statement_id = p_tab_rec.statement_id
                   AND table_owner = p_tab_rec.owner
                   AND table_name = p_tab_rec.table_name
                   AND index_column_names IS NOT NULL)
      LOOP
        FOR j IN (SELECT owner,
                         index_name,
                         index_column_names
                    FROM sqlt$_dba_indexes
                   WHERE statement_id = p_tab_rec.statement_id
                     AND table_owner = p_tab_rec.owner
                     AND table_name = p_tab_rec.table_name
                     AND index_name <> i.index_name
                     AND index_column_names LIKE i.index_column_names||' %')
        LOOP
    	  s_obs_rec.priority	:= 18;
	      s_obs_rec.type_id     := E_INDEX;
          s_obs_rec.object_type := 'INDEX';
          s_obs_rec.object_name := i.owner||'.'||i.index_name;
          s_obs_rec.observation := 'Check the design of the indexes on table '||p_tab_rec.owner||'.'||p_tab_rec.table_name||'. There seem to be some redundant Indexes. See MOS Note Tables Have Been Found That Contain More Than the Recommended Number of Indexes (Doc ID 1024097.1).';
          s_obs_rec.more        := 'This index on '||p_tab_rec.owner||'.'||p_tab_rec.table_name||' contains column(s) "'||i.index_column_names||'". Index '||j.owner||'.'||j.index_name||' contains columns "'||j.index_column_names||'", which are a superset of the leading columns of the former. Consider dropping redundant index '||i.owner||'.'||i.index_name||' (unless it is needed to enforce uniqueness). Review <a href="#idxed_cols_'||p_tab_rec.object_id||'">indexed columns</a>';
          ins_obs;
        END LOOP;
      END LOOP;
    END;

    -- (110)
	-- table partitions
    IF p_tab_rec.partitioned = 'YES' AND p_tab_rec.last_analyzed IS NOT NULL AND p_tab_rec.num_rows IS NOT NULL THEN
      SELECT COUNT(*),
             SUM(no_stats),
             SUM(num_rows_zero),
             MIN(last_analyzed)
        INTO l_count,
             l_no_stats,
             l_rows_0,
             l_date
        FROM (
      SELECT CASE WHEN last_analyzed IS NULL OR num_rows IS NULL THEN 1 ELSE 0 END no_stats,
             CASE WHEN num_rows = 0 THEN 1 ELSE 0 END num_rows_zero,
             last_analyzed
        FROM sqlt$_dba_tab_partitions
       WHERE statement_id = p_tab_rec.statement_id
         AND table_owner = p_tab_rec.owner
         AND table_name = p_tab_rec.table_name);

      -- partitions with no stats
      IF p_tab_rec.temporary = 'N' AND l_no_stats > 0 THEN
    	s_obs_rec.priority	  := 39;
	    s_obs_rec.type_id     := E_TABLE_PART;
        s_obs_rec.object_type := 'TABLE PARTITION';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Consider collecting valid statistics for the partitioned object'||l_no_stats||' out of '||l_count||' partition(s) lack(s) CBO statistics. See MOS Note Automatic Optimizer Statistics Collection on Partitioned Table (Doc ID 1592404.1).';
        IF s_sql_rec.siebel = 'YES' THEN
          s_obs_rec.more      := 'Consider gathering <a href="#tbl_part_stats_'||p_tab_rec.object_id||'">table partition statistics</a> using using coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
        ELSIF s_sql_rec.psft = 'YES' THEN
          s_obs_rec.more      := 'Consider gathering <a href="#tbl_part_stats_'||p_tab_rec.object_id||'">table partition statistics</a> using using pscbo_stats.sql. See MOS Doc ID 1322888.1';
        ELSIF s_sql_rec.apps_release IS NOT NULL THEN
          s_obs_rec.more      := 'Consider gathering <a href="#tbl_part_stats_'||p_tab_rec.object_id||'">table partition statistics</a> using FND_STATS.GATHER_TABLE_STATISTICS.';
        ELSE
          s_obs_rec.more      := 'Consider gathering <a href="#tbl_part_stats_'||p_tab_rec.object_id||'">table partition statistics</a> using SYS.DBMS_STATS.GATHER_TABLE_STATISTICS. See MOS Doc ID 465787.1.';
        END IF;
        ins_obs;
      END IF;

      -- (111)
	  -- partitions where num rows = 0
      IF l_rows_0 > 0 THEN
    	s_obs_rec.priority	  := 44;
	    s_obs_rec.type_id     := E_TABLE_PART;
        s_obs_rec.object_type := 'TABLE PARTITION';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Check that the statistics on this table partition are correct'||l_rows_0||' out of '||l_count||' partition(s) with number of rows equal to zero according to partition''s CBO statistics. See MOS Note Automatic Optimizer Statistics Collection on Partitioned Table (Doc ID 1592404.1).';
        s_obs_rec.more        := 'If these table partitions are not empty, consider gathering <a href="#tbl_part_stats_'||p_tab_rec.object_id||'">table partition statistics</a> using GRANULARITY=>GLOBAL AND PARTITION.';
        ins_obs;
      END IF;

      -- (112)
	  -- partitions with oudated stats
      IF l_date IS NOT NULL AND ABS(p_tab_rec.last_analyzed - l_date) > 1 THEN
    	s_obs_rec.priority	  := 32;
	    s_obs_rec.type_id     := E_TABLE_PART;
        s_obs_rec.object_type := 'TABLE PARTITION';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Consider collecting fresh statistics as the table contains partition(s) with table/partition CBO statistics out of sync for up to '||TRUNC(ABS(p_tab_rec.last_analyzed - l_date))||' day(s). Also see MOS Note Automatic Optimizer Statistics Collection on Partitioned Table (Doc ID 1592404.1).';
        s_obs_rec.more        := 'Table and partition statistics were gathered up to '||TRUNC(ABS(p_tab_rec.last_analyzed - l_date))||' day(s) apart, so they may not offer a consistent view to the CBO. If partition statistics are stale, then consider re-gathering <a href="#tbl_part_stats_'||p_tab_rec.object_id||'">table partition statistics</a> using GRANULARITY=>GLOBAL AND PARTITION.';
        ins_obs;
      END IF;

      SELECT SUM(no_stats) no_stats,
             MIN(last_analyzed) last_analyzed
        INTO l_no_stats,
             l_date
        FROM (
      SELECT column_name,
             CASE WHEN SUM(no_stats) > 0 THEN 1 ELSE 0 END no_stats,
             MIN(last_analyzed) last_analyzed
        FROM (
      SELECT p.column_name,
             CASE WHEN p.last_analyzed IS NULL THEN 1 ELSE 0 END no_stats,
             p.last_analyzed
        FROM sqlt$_dba_part_col_statistics p
       WHERE p.statement_id = p_tab_rec.statement_id
         AND p.owner = p_tab_rec.owner
         AND p.table_name = p_tab_rec.table_name
         AND EXISTS (
      SELECT NULL
        FROM sqlt$_dba_all_table_cols_v c
       WHERE p.statement_id = c.statement_id
         AND p.owner = c.owner
         AND p.table_name = c.table_name
         AND p.column_name = c.column_name
         AND c.in_predicates = 'TRUE'))
       GROUP BY
             column_name);

      -- (113)
	  -- partition columns with no stats
      IF p_tab_rec.temporary = 'N' AND l_no_stats > 0 THEN
    	s_obs_rec.priority	  := 43;
	    s_obs_rec.type_id     := E_TABLE_PART;
        s_obs_rec.object_type := 'TABLE PARTITION';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Consider gathering statistics on this partitioned table. '||l_no_stats||' column(s) referenced in predicates lack(s) partition level CBO statistics. See MOS Note Automatic Optimizer Statistics Collection on Partitioned Table (Doc ID 1592404.1).';
        IF s_sql_rec.siebel = 'YES' THEN
          s_obs_rec.more      := 'Consider gathering <a href="#part_cols_'||p_tab_rec.object_id||'">table statistics</a> using coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
        ELSIF s_sql_rec.psft = 'YES' THEN
          s_obs_rec.more      := 'Consider gathering <a href="#part_cols_'||p_tab_rec.object_id||'">table statistics</a> using pscbo_stats.sql. See MOS Doc ID 1322888.1.';
        ELSIF s_sql_rec.apps_release IS NOT NULL THEN
          s_obs_rec.more      := 'Consider gathering <a href="#part_cols_'||p_tab_rec.object_id||'">table statistics</a> using FND_STATS.GATHER_TABLE_STATISTICS.';
        ELSE
          s_obs_rec.more      := 'Consider gathering <a href="#part_cols_'||p_tab_rec.object_id||'">table statistics</a> using SYS.DBMS_STATS.GATHER_TABLE_STATISTICS. See MOS Doc ID 465787.1.';
        END IF;
        ins_obs;
      END IF;

      -- (114)
	  -- partition columns with outdated stats
      IF l_date IS NOT NULL AND ABS(p_tab_rec.last_analyzed - l_date) > 1 THEN
    	s_obs_rec.priority	  := 44;
	    s_obs_rec.type_id     := E_TABLE_PART;
        s_obs_rec.object_type := 'TABLE PARTITION';
        s_obs_rec.object_name := p_tab_rec.owner||'.'||p_tab_rec.table_name;
        s_obs_rec.observation := 'Consider gathering fresh statistics on the table in this query. Table contains column(s) referenced in predicates with table/partition CBO statistics out of sync for up to '||TRUNC(ABS(p_tab_rec.last_analyzed - l_date))||' day(s). Also see MOS Note Automatic Optimizer Statistics Collection on Partitioned Table (Doc ID 1592404.1).';
        s_obs_rec.more        := 'Table and partition column statistics were gathered up to '||TRUNC(ABS(p_tab_rec.last_analyzed - l_date))||' day(s) apart, so they may not offer a consistent view to the CBO. If partition statistics are stale, then consider re-gathering <a href="#part_cols_'||p_tab_rec.object_id||'">table statistics</a> using GRANULARITY=>GLOBAL AND PARTITION.';
        ins_obs;
      END IF;
    END IF; -- table partitions

    write_log('<- table_hc_'||p_tab_rec.table_name);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('table_hc_'||p_tab_rec.table_name||': '||SQLERRM);
  END table_hc;

  /*************************************************************************************/

  /* -------------------------
   *
   * private index_hc
   *
   * ------------------------- */
  PROCEDURE index_hc (
    p_tab_rec IN sqlt$_dba_all_tables_v%ROWTYPE,
    p_idx_rec IN sqlt$_dba_indexes%ROWTYPE )
  IS
    l_count    NUMBER;
    l_count2   NUMBER;
    l_date     DATE;
    l_no_stats NUMBER;
    l_rows_0   NUMBER;

  BEGIN
    write_log('-> index_hc_'||p_idx_rec.index_name);

    -- (115)
	-- no stats
    IF p_tab_rec.temporary = 'N' AND p_tab_rec.last_analyzed IS NOT NULL AND (p_idx_rec.last_analyzed IS NULL OR p_idx_rec.num_rows IS NULL) THEN
      s_obs_rec.priority	:= 72;
	  s_obs_rec.type_id     := E_INDEX;
      s_obs_rec.object_type := 'INDEX';
      s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
      s_obs_rec.observation := 'Consider collecting Optimizer statistics for the indexes referenced in this query. Index lacks CBO Statistics. Also see Automatic Task ("auto optimizer stats collection" Does not Refresh Stale Index Statistics Unless Tables Statistics are Also Stale (Doc ID 1934741.1).';
      IF s_sql_rec.siebel = 'YES' AND (p_tab_rec.count_star > 15 OR p_tab_rec.num_rows > 15) THEN
        s_obs_rec.more      := 'Consider gathering <a href="#idx_cbo_'||p_tab_rec.object_id||'">index statistics</a> using coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
        ins_obs;
      ELSIF s_sql_rec.psft = 'YES' THEN
        s_obs_rec.more      := 'Consider gathering <a href="#idx_cbo_'||p_tab_rec.object_id||'">index statistics</a> using pscbo_stats.sql. See MOS Doc ID 1322888.1.';
        ins_obs;
      ELSIF s_sql_rec.apps_release IS NOT NULL THEN
        s_obs_rec.more      := 'Consider gathering <a href="#idx_cbo_'||p_tab_rec.object_id||'">index statistics</a> using FND_STATS.GATHER_INDEX_STATS.';
        ins_obs;
      ELSIF s_sql_rec.apps_release IS NULL AND NVL(s_sql_rec.siebel, 'NO') = 'NO' AND NVL(s_sql_rec.psft, 'NO') = 'NO' THEN
        s_obs_rec.more      := 'Consider gathering <a href="#idx_cbo_'||p_tab_rec.object_id||'">index statistics</a> using SYS.DBMS_STATS.GATHER_INDEX_STATS. See MOS Doc ID 465787.1.';
        ins_obs;
      END IF;
    END IF;

    -- (116)
	-- more rows in index than its table
    IF p_idx_rec.num_rows > p_tab_rec.num_rows AND
       sqlt$t.differ_more_than_x_perc(p_idx_rec.num_rows, p_tab_rec.num_rows, 10)
    THEN
      s_obs_rec.priority	:= 29;
	  s_obs_rec.type_id     := E_INDEX;
      s_obs_rec.object_type := 'INDEX';
      s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
      s_obs_rec.observation := 'Check the statistics on the index in this query. Index appears to have more rows ('||p_idx_rec.num_rows||') than its table ('||p_tab_rec.num_rows||') by '||sqlt$t.difference_percent(p_idx_rec.num_rows, p_tab_rec.num_rows)||'%. See MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1).';
      s_obs_rec.more        := 'To fix this <a href="#idx_cbo_'||p_tab_rec.object_id||'">index statistics</a> inconsistency, consider gathering <a href="#tab_stats">table statistics</a> using ';
      IF s_sql_rec.siebel = 'YES' THEN
        s_obs_rec.more      := s_obs_rec.more||'coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
      ELSIF s_sql_rec.psft = 'YES' THEN
        s_obs_rec.more      := s_obs_rec.more||'pscbo_stats.sql. See MOS Doc ID 1322888.1.';
      ELSIF s_sql_rec.apps_release IS NOT NULL THEN
        s_obs_rec.more      := s_obs_rec.more||'FND_STATS.GATHER_TABLE_STATS.';
      ELSE
        s_obs_rec.more      := s_obs_rec.more||'DBMS_STATS.GATHER_TABLE_STATS. See MOS Doc ID 465787.1.';
      END IF;
      ins_obs;
    END IF;

    -- (117)
	-- clustering factor > rows in table
    IF p_idx_rec.clustering_factor > p_tab_rec.num_rows AND
       sqlt$t.differ_more_than_x_perc(p_idx_rec.clustering_factor, p_tab_rec.num_rows, 10)
    THEN
      s_obs_rec.priority	:= 28;
	  s_obs_rec.type_id     := E_INDEX;
      s_obs_rec.object_type := 'INDEX';
      s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
      s_obs_rec.observation := 'Consider collecting fresh statistics. The Clustering factor of '||p_idx_rec.clustering_factor||' is larger than number of rows in its table ('||p_tab_rec.num_rows||') by '||sqlt$t.difference_percent(p_idx_rec.clustering_factor, p_tab_rec.num_rows)||'%. See MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1).';
      s_obs_rec.more        := 'To fix this <a href="#idx_cbo_'||p_tab_rec.object_id||'">index statistics</a> inconsistency, consider gathering <a href="#tab_stats">table statistics</a> using ';
      IF s_sql_rec.siebel = 'YES' THEN
        s_obs_rec.more      := s_obs_rec.more||'coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
      ELSIF s_sql_rec.psft = 'YES' THEN
        s_obs_rec.more      := s_obs_rec.more||'pscbo_stats.sql. See MOS Doc ID 1322888.1.';
      ELSIF s_sql_rec.apps_release IS NOT NULL THEN
        s_obs_rec.more      := s_obs_rec.more||'FND_STATS.GATHER_TABLE_STATS.';
      ELSE
        s_obs_rec.more      := s_obs_rec.more||'DBMS_STATS.GATHER_TABLE_STATS. See MOS Doc ID 465787.1.';
      END IF;
      ins_obs;
    END IF;

    -- (118)
	-- coalesce candidates
    -- 
    IF p_idx_rec.leaf_estimate_target_size < 0.6 * p_idx_rec.leaf_blocks THEN
      s_obs_rec.priority	:= 12;
	  s_obs_rec.type_id     := E_INDEX;
      s_obs_rec.object_type := 'INDEX';
      s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
      s_obs_rec.observation := 'In some rare cases you may need to rebuild an index. Review the current data and also look at MOS Note Index Rebuild, the Need vs the Implications (Doc ID 989093.1).';
      s_obs_rec.more        := 'Review <a href="#idx_cbo_'||p_tab_rec.object_id||'">index statistics</a> and look for Leaf Blocks and Estimate Target Size. Read also MOS Doc ID 989093.1.';
      ins_obs;
    END IF;

    -- (119)
	-- coalesce candidates
    -- DBMS_SPACE.CREATE_INDEX_COST
    IF p_idx_rec.dbms_space_alloc_blocks < 0.6 * p_idx_rec.total_segment_blocks THEN
    	s_obs_rec.priority	  := 12;
	  s_obs_rec.type_id     := E_INDEX;
      s_obs_rec.object_type := 'INDEX';
      s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
      s_obs_rec.observation := 'In some rare cases you may need to rebuild an index. Review the current data and also look at MOS Note Index Rebuild, the Need vs the Implications (Doc ID 989093.1).';
      s_obs_rec.more        := 'Review <a href="#idx_cbo_'||p_tab_rec.object_id||'">index statistics</a> and look for Total Segment Blocks('||p_idx_rec.total_segment_blocks||') and DBMS_SPACE Allocated Blocks('||p_idx_rec.dbms_space_alloc_blocks||').';
      ins_obs;
    END IF;

    -- (120)
	-- unusable indexes
    IF p_idx_rec.partitioned = 'NO' AND p_idx_rec.status = 'UNUSABLE' THEN
      s_obs_rec.priority	:= 48;
	  s_obs_rec.type_id     := E_INDEX;
      s_obs_rec.object_type := 'INDEX';
      s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
      s_obs_rec.observation := 'Check the reason for any unusable indexes. Also see MOS Note Unusable Indexes Marked As Usable When TABLE_EXISTS_ACTION=TRUNCATE with Impdp (Doc ID 555909.1).';
      s_obs_rec.more        := 'Unusable indexes cannot be used by the CBO. This may cause Execution Plans to change. Review <a href="#idx_prop_'||p_tab_rec.object_id||'">index properties</a>.';
      ins_obs;
    END IF;

    -- (121)
	-- unusable index partitions
    IF p_idx_rec.partitioned = 'YES' THEN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_ind_partitions
       WHERE statement_id = p_idx_rec.statement_id
         AND index_owner = p_idx_rec.owner
         AND index_name = p_idx_rec.index_name
         AND status = 'UNUSABLE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 49;
	    s_obs_rec.type_id     := E_INDEX;
        s_obs_rec.object_type := 'INDEX PARTITION';
        s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
        s_obs_rec.observation := 'Check the reason for unusable index partitions. Index with '||l_count||' unusable partition(s). Also see MOS Note Common Questions on Indexes on Partitioned Table (Doc ID 1481609.1).';
        s_obs_rec.more        := 'Unusable index partitions cannot be used by the CBO. This may cause Execution Plans to change. Review <a href="#idx_part_'||p_idx_rec.object_id||'">Index Partition</a>.';
        ins_obs;
      END IF;
    END IF;

    -- (122)
	-- unusable index subpartitions
    IF p_idx_rec.partitioned = 'YES' THEN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_ind_subpartitions
       WHERE statement_id = p_idx_rec.statement_id
         AND index_owner = p_idx_rec.owner
         AND index_name = p_idx_rec.index_name
         AND status = 'UNUSABLE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 48;
	    s_obs_rec.type_id     := E_INDEX;
        s_obs_rec.object_type := 'INDEX SUBPARTITION';
        s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
        s_obs_rec.observation := 'Check the reason for the unusable index sub-partitions. Index with '||l_count||' unusable subpartition(s). Also see MOS Note Common Questions on Indexes on Partitioned Table (Doc ID 1481609.1)';
        s_obs_rec.more        := 'Unusable index subpartitions cannot be used by the CBO. This may cause Execution Plans to change.';
        ins_obs;
      END IF;
    END IF;

    -- (123)
	-- invisible indexes
    IF p_idx_rec.visibility = 'INVISIBLE' THEN
      s_obs_rec.priority	:= 54;
	  s_obs_rec.type_id     := E_INDEX;
      s_obs_rec.object_type := 'INDEX';
      s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
      s_obs_rec.observation := 'Check the reason for invisible indexes in this query. Also see MOS Note Diagnosing and Understanding Why a Query is Not Using an Index (Doc ID 67522.1).';
      s_obs_rec.more        := 'Invisible indexes cannot be used by the CBO. This may cause Execution Plans to change. Review <a href="#idx_prop_'||p_tab_rec.object_id||'">Index Properties</a>.';
      ins_obs;
    END IF;

    -- (124)
	-- indexes with mutating blevel
    BEGIN
      SELECT COUNT(*)
        INTO l_count
        FROM sqlt$_dba_ind_statistics
       WHERE statement_id = s_sql_rec.statement_id
         AND object_type = 'INDEX'
         AND owner = p_idx_rec.owner
         AND index_name = p_idx_rec.index_name
         AND mutating_blevel = 'TRUE';

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 12;
	    s_obs_rec.type_id     := E_INDEX;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
        s_obs_rec.observation := 'Check the reason for the changing BLEVEL of indexes used in this query. It may affect the plan. Also see MOS Note Diagnosing and Understanding Why a Query is Not Using an Index (Doc ID 67522.1).';
        s_obs_rec.more        := 'Review <a href="#idx_cbo_vers_'||p_tab_rec.object_id||'">index statistics versions</a>. Recent changes on BLEVEL may cause the Execution Plans to change.</a>.';
        ins_obs;
      END IF;
    END;
    -- (125)
    IF p_tab_rec.last_analyzed IS NOT NULL AND p_idx_rec.partitioned = 'NO' AND p_idx_rec.last_analyzed IS NOT NULL THEN
      -- stats on zero while columns have value
      IF p_tab_rec.num_rows > 0 AND p_idx_rec.num_rows = 0 AND p_idx_rec.distinct_keys = 0 AND p_idx_rec.leaf_blocks = 0 AND p_idx_rec.blevel = 0 THEN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_ind_columns ic,
               sqlt$_dba_all_table_cols_v tc
         WHERE ic.statement_id = p_idx_rec.statement_id
           AND ic.index_owner = p_idx_rec.owner
           AND ic.index_name = p_idx_rec.index_name
           AND ic.statement_id = tc.statement_id
           AND ic.table_owner = tc.owner
           AND ic.table_name = tc.table_name
           AND ic.column_name = tc.column_name
           AND p_tab_rec.num_rows > tc.num_nulls
           AND sqlt$t.differ_more_than_x_percent(tc.num_nulls, p_tab_rec.num_rows, 10) = 'Y'
           AND ROWNUM = 1;

        IF l_count > 0 THEN
    	  s_obs_rec.priority    := 11;
	      s_obs_rec.type_id     := E_INDEX;
          s_obs_rec.object_type := 'INDEX';
          s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
          s_obs_rec.observation := 'Consider gathering table statistics, or DROP and RE-CREATE index. Check this in conjunction with Bug 4055596.';
          s_obs_rec.more        := 'This index with zeroes in CBO <a href="#idx_cbo_'||p_tab_rec.object_id||'">index statistics</a> contains columns for which there are values ((num_rows - num_nulls) greater than 0), so the index should not have statistics in zeroes. Possible 4055596. Consider gathering <a href="#tab_stats">table statistics</a>, or DROP and RE-CREATE index.';
          ins_obs;
        END IF;
      END IF;

      -- (126)
	  -- table/index stats out of sync
      IF ABS(p_tab_rec.last_analyzed - p_idx_rec.last_analyzed) > 1 THEN
    	s_obs_rec.priority	  := 26;
	    s_obs_rec.type_id     := E_INDEX;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
        s_obs_rec.observation := 'Review the timing and quality of statistics. Table/Index CBO statistics gap = '||TRUNC(ABS(p_tab_rec.last_analyzed - p_idx_rec.last_analyzed))||' day(s). Also see MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1).';
        s_obs_rec.more        := '<a href="#tab_stats">Table statistics</a> and <a href="#idx_cbo_'||p_tab_rec.object_id||'">index statistics</a> were gathered '||TRUNC(ABS(p_tab_rec.last_analyzed - p_idx_rec.last_analyzed))||' day(s) apart, so they do not offer a consistent view to the CBO. Consider re-gathering table statistics using CASCADE=>TRUE.';
        ins_obs;
      END IF;

      -- (127)
	  -- analyze 236935.1
      IF p_idx_rec.last_analyzed IS NOT NULL AND p_idx_rec.global_stats = 'NO' AND p_idx_rec.index_type = 'NORMAL' THEN
    	s_obs_rec.priority	  := 71;
	    s_obs_rec.type_id     := E_INDEX;
        s_obs_rec.object_type := 'INDEX';
        s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
        IF p_idx_rec.partitioned = 'NO' THEN
          s_obs_rec.observation := 'Confirm that you are gathering statistics with DBM_STATS rather than ANALYZE. Also see MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1).';
          s_obs_rec.more      := 'When ANALYZE is used on a non-partitioned table, the global_stats column of the <a href="#tab_stats">table statistics</a> receives a value of ''NO''. Consider gathering statistics using ';
        ELSE
          s_obs_rec.observation := 'Confirm that you are gathering statistics in the correct way on the partitioned objects. CBO statistics are being derived by aggregation from lower level objects. Also see MOS Note Global statistics - An Explanation (Doc ID 236935.1).';
          s_obs_rec.more      := 'When statistics are derived by aggregation from lower level objects, the global_stats column of the <a href="#tab_stats">table statistics</a> receives a value of ''NO''. Consider gathering statistics using ';
        END IF;
        IF s_sql_rec.siebel = 'YES' THEN
          s_obs_rec.more      := s_obs_rec.more||'coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
        ELSIF s_sql_rec.psft = 'YES' THEN
          s_obs_rec.more      := s_obs_rec.more||'pscbo_stats.sql. See MOS Doc ID 1322888.1.';
        ELSIF s_sql_rec.apps_release IS NOT NULL THEN
          s_obs_rec.more      := s_obs_rec.more||'FND_STATS.GATHER_TABLE_STATS.';
        ELSE
          s_obs_rec.more      := s_obs_rec.more||'DBMS_STATS.GATHER_TABLE_STATS. See MOS Doc ID 465787.1.';
        END IF;
        ins_obs;
      END IF;
    END IF;

    -- (128)
	-- single-column indexes
    IF p_tab_rec.last_analyzed IS NOT NULL AND sqlt$a.get_index_column_count(p_idx_rec.statement_id, p_idx_rec.owner, p_idx_rec.index_name) = 1 THEN
      FOR i IN (SELECT tc.*
                  FROM sqlt$_dba_ind_columns ic,
                       sqlt$_dba_all_table_cols_v tc
                 WHERE ic.statement_id = p_idx_rec.statement_id
                   AND ic.index_owner = p_idx_rec.owner
                   AND ic.index_name = p_idx_rec.index_name
                   AND ic.statement_id = tc.statement_id
                   AND ic.table_owner = tc.owner
                   AND ic.table_name = tc.table_name
                   AND ic.column_name = tc.column_name)
      LOOP
        -- no column stats in single-column index
        IF p_tab_rec.temporary = 'N' AND (i.last_analyzed IS NULL OR i.num_distinct IS NULL OR i.num_nulls IS NULL) THEN
    	  s_obs_rec.priority	:= 32;
	      s_obs_rec.type_id     := E_1COL_INDEX;
          s_obs_rec.object_type := '1-COL INDEX';
          s_obs_rec.object_name := p_idx_rec.index_name||'('||i.column_name||')';
          s_obs_rec.observation := 'Review the statistics of the single column in the index in this query. Also review MOS Note Histograms: An Overview (10g and Above) (Doc ID 1445372.1).';
          s_obs_rec.more        := 'To avoid CBO guessed statistics on this <a href="#idx_cols_cbo_'||p_idx_rec.object_id||'">indexed column</a>, gather table statistics and include this column in METHOD_OPT used.';
          ins_obs;
        END IF;

        -- (129)
		-- ndv on column > num_rows in single-column index
        IF i.num_distinct > p_idx_rec.num_rows AND
           sqlt$t.differ_more_than_x_perc(i.num_distinct, p_idx_rec.num_rows, 10)
        THEN
    	  s_obs_rec.priority	:= 39;
	      s_obs_rec.type_id     := E_1COL_INDEX;
          s_obs_rec.object_type := '1-COL INDEX';
          s_obs_rec.object_name := p_idx_rec.index_name||'('||i.column_name||')';
          s_obs_rec.observation := 'Check the sampling size and relevance of the statistics on the tables in this query. Single-column index with number of distinct values greater than number of rows by '||sqlt$t.difference_percent(i.num_distinct, p_idx_rec.num_rows)||'%. Also see MOS Note Histograms: An Overview (10g and Above) (Doc ID 1445372.1).';
          s_obs_rec.more        := 'There cannot be a larger number of distinct values ('||i.num_distinct||') in a column than actual rows ('||p_idx_rec.num_rows||') in the index. This is an inconsistency on this <a href="#idx_cols_cbo_'||p_idx_rec.object_id||'">indexed column</a>. Consider gathering table statistics using a large sample size.';
          ins_obs;
        END IF;

        -- (130)
		-- ndv is zero but column has values in single-column index
        IF i.num_distinct = 0 AND
           p_idx_rec.num_rows > i.num_nulls AND
           sqlt$t.differ_more_than_x_perc(i.num_nulls, p_idx_rec.num_rows, 10)
        THEN
    	  s_obs_rec.priority	:= 38;
	      s_obs_rec.type_id     := E_1COL_INDEX;
          s_obs_rec.object_type := '1-COL INDEX';
          s_obs_rec.object_name := p_idx_rec.index_name||'('||i.column_name||')';
          s_obs_rec.observation := 'Check the sampling size and relevance of the statistics on the tables in this query. Single-column index with number of distinct values equal to zero in column with value. Also see MOS Note Histograms: An Overview (10g and Above) (Doc ID 1445372.1).';
          s_obs_rec.more        := 'There should not be columns with value ((num_rows - num_nulls) greater than 0) where the number of distinct values for the same column is zero. Column has '||(p_idx_rec.num_rows - i.num_nulls)||' rows with value while the number of distinct values for it is zero. This is an inconsistency on this <a href="#idx_cols_cbo_'||p_idx_rec.object_id||'">indexed column</a>. Consider gathering table statistics using a large sample size.';
          ins_obs;
        END IF;

        -- (131)
		-- Bugs 4495422 or 9885553 in single-column index
        IF p_idx_rec.distinct_keys > 0 AND
           i.num_distinct > 0 AND
           sqlt$t.differ_more_than_x_perc(p_idx_rec.distinct_keys, i.num_distinct, 10)
        THEN
    	  s_obs_rec.priority	:= 50;
	      s_obs_rec.type_id     := E_1COL_INDEX;
          s_obs_rec.object_type := '1-COL INDEX';
          s_obs_rec.object_name := p_idx_rec.index_name||'('||i.column_name||')';
          s_obs_rec.observation := 'Review the possibility of bugs 4495422 or 9885553. The Number of distinct values ('||i.num_distinct||') does not match the number of distinct keys ('||p_idx_rec.distinct_keys||') by '||sqlt$t.difference_percent(p_idx_rec.distinct_keys, i.num_distinct)||'%. Review Bug Bug 9885553 - DBMS_STATS produces incorrect column NDV distinct values statistics (Doc ID 9885553.8).';
          IF i.data_type LIKE '%CHAR%' AND i.num_buckets > 1 THEN
            s_obs_rec.more      := 'Possible Bugs 4495422 or 9885553. This is an inconsistency on this <a href="#idx_cols_cbo_'||p_idx_rec.object_id||'">indexed column</a>. Consider gathering statistics with no histograms or adjusting DISTCNT and DENSITY using SET_COLUMN_statistics APIs';
          ELSE
            s_obs_rec.more      := 'This is an inconsistency on this <a href="#idx_cols_cbo_'||p_idx_rec.object_id||'">indexed column</a>. Consider gathering statistics or adjusting DISTCNT and DENSITY using SET_COLUMN_statistics APIs';
          END IF;
          ins_obs;
        END IF;
      END LOOP;
    END IF;

    -- (132)
	-- index partitions
    IF p_tab_rec.last_analyzed IS NOT NULL AND p_idx_rec.partitioned = 'YES' THEN
      SELECT COUNT(*),
             SUM(no_stats),
             SUM(num_rows_zero),
             MIN(last_analyzed)
        INTO l_count,
             l_no_stats,
             l_rows_0,
             l_date
        FROM (
      SELECT CASE WHEN last_analyzed IS NULL OR num_rows IS NULL THEN 1 ELSE 0 END no_stats,
             CASE WHEN num_rows = 0 THEN 1 ELSE 0 END num_rows_zero,
             last_analyzed
        FROM sqlt$_dba_ind_partitions
       WHERE statement_id = p_idx_rec.statement_id
         AND index_owner = p_idx_rec.owner
         AND index_name = p_idx_rec.index_name);

      -- partitions with no stats
      IF p_tab_rec.temporary = 'N' AND l_no_stats > 0 THEN
    	s_obs_rec.priority	  := 65;
	    s_obs_rec.type_id     := E_INDEX_PART;
        s_obs_rec.object_type := 'INDEX PARTITION';
        s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
        s_obs_rec.observation := 'Consider gathering statistics as needed. '||l_no_stats||' out of '||l_count||' partition(s) lack(s) CBO statistics. Also see MOS Note Best Practices for Automatic Statistics Collection (Doc ID 377152.1).';
        IF s_sql_rec.siebel = 'YES' THEN
          s_obs_rec.more      := 'Consider gathering <a href="#idx_part_stats_'||p_idx_rec.object_id||'">index partition statistics</a> using coe_siebel_stats.sql. See MOS Doc ID 781927.1.';
        ELSIF s_sql_rec.psft = 'YES' THEN
          s_obs_rec.more      := 'Consider gathering <a href="#idx_part_stats_'||p_idx_rec.object_id||'">index partition statistics</a> using pscbo_stats.sql. See MOS Doc ID 1322888.1.';
        ELSIF s_sql_rec.apps_release IS NOT NULL THEN
          s_obs_rec.more      := 'Consider gathering <a href="#idx_part_stats_'||p_idx_rec.object_id||'">index partition statistics</a> using FND_STATS.GATHER_INDEX_STATS.';
        ELSE
          s_obs_rec.more      := 'Consider gathering <a href="#idx_part_stats_'||p_idx_rec.object_id||'">index partition statistics</a> using SYS.DBMS_STATS.GATHER_INDEX_STATS. See MOS Doc ID 465787.1.';
        END IF;
        ins_obs;
      END IF;

      -- (133)
	  -- partitions where num rows = 0
      IF l_rows_0 > 0 THEN
    	s_obs_rec.priority	  := 42;
	    s_obs_rec.type_id     := E_INDEX_PART;
        s_obs_rec.object_type := 'INDEX PARTITION';
        s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
        s_obs_rec.observation := 'Consider gathering statistics on some partitions.'||l_rows_0||' out of '||l_count||' partition(s) with number of rows equal to zero according to partition''s CBO statistics. Also see MOS Note Automatic Optimizer Statistics Collection on Partitioned Table (Doc ID 1592404.1).';
        s_obs_rec.more        := 'If these index partitions are not empty, consider gathering <a href="#idx_part_stats_'||p_idx_rec.object_id||'">index partition statistics</a> using GRANULARITY=>GLOBAL AND PARTITION.';
        ins_obs;
      END IF;

      -- (134)
	  -- partitions with oudated stats
      IF l_date IS NOT NULL AND ABS(p_tab_rec.last_analyzed - l_date) > 1 THEN
    	s_obs_rec.priority	  := 64;
	    s_obs_rec.type_id     := E_INDEX_PART;
        s_obs_rec.object_type := 'INDEX PARTITION';
        s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
        s_obs_rec.observation := 'Consider re-gathering <a href="#idx_part_stats_'||p_idx_rec.object_id||'">index partition statistics</a> using GRANULARITY=>GLOBAL AND PARTITION. Index contains partition(s) with index/partition CBO statistics out of sync for up to '||TRUNC(ABS(p_tab_rec.last_analyzed - l_date))||' day(s). Also review MOS Note Global statistics - An Explanation (Doc ID 236935.1).';
        s_obs_rec.more        := 'Index and partition statistics were gathered up to '||TRUNC(ABS(p_tab_rec.last_analyzed - l_date))||' day(s) apart, so they may not offer a consistent view to the CBO. If partition statistics are stale, then consider re-gathering <a href="#idx_part_stats_'||p_idx_rec.object_id||'">index partition statistics</a> using GRANULARITY=>GLOBAL AND PARTITION.';
        ins_obs;
      END IF;

      -- (135)
	  -- table and index partitions do not match 14013094
      IF p_tab_rec.partitioned = 'YES' AND p_idx_rec.partitioned = 'YES' THEN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_tab_partitions
         WHERE statement_id = p_tab_rec.statement_id
           AND table_owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name;

        SELECT COUNT(*)
          INTO l_count2
          FROM sqlt$_dba_ind_partitions
         WHERE statement_id = p_idx_rec.statement_id
           AND index_owner = p_idx_rec.owner
           AND index_name = p_idx_rec.index_name;

        IF l_count = l_count2 THEN
          IF p_idx_rec.at_least_1_notnull_col = 'Y' AND p_idx_rec.index_type <> 'BITMAP' THEN
            SELECT COUNT(*)
              INTO l_count
              FROM sqlt$_dba_tab_statistics tps,
                   sqlt$_dba_ind_statistics ips
             WHERE tps.statement_id = p_tab_rec.statement_id
               AND tps.owner = p_tab_rec.owner
               AND tps.table_name = p_tab_rec.table_name
               AND tps.object_type = 'PARTITION'
               AND ips.statement_id = p_idx_rec.statement_id
               AND ips.owner = p_idx_rec.owner
               AND ips.index_name = p_idx_rec.index_name
               AND ips.object_type = 'PARTITION'
               AND tps.partition_position = ips.partition_position
               AND sqlt$t.differ_more_than_x_percent(tps.num_rows, ips.num_rows, 10) = 'Y';

            IF l_count > 0 THEN
    	      s_obs_rec.priority	:= 35;
	          s_obs_rec.type_id     := E_INDEX_PART;
              s_obs_rec.object_type := 'INDEX PARTITION';
              s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
              s_obs_rec.observation := 'Check the statistics are correct. The index contains '||l_count||' partition(s) with number of rows out of sync for more than 10% to their corresponding Table partition(s). Possibly Bug 14013094 - DBMS_STATS places statistics in the wrong index partition (Doc ID 14013094.8).';
              s_obs_rec.more        := 'Compare <a href="#tbl_part_stats_'||p_tab_rec.object_id||'">table partition statistics</a> to <a href="#idx_part_stats_'||p_idx_rec.object_id||'">index partition statistics</a> and review mismatch in number of rows per partition. Possible Bug 14013094.';
              ins_obs;
            END IF;
          END IF;

          SELECT COUNT(*)
            INTO l_count
            FROM sqlt$_dba_tab_statistics tps,
                 sqlt$_dba_ind_statistics ips
           WHERE tps.statement_id = p_tab_rec.statement_id
             AND tps.owner = p_tab_rec.owner
             AND tps.table_name = p_tab_rec.table_name
             AND tps.object_type = 'PARTITION'
             AND ips.statement_id = p_idx_rec.statement_id
             AND ips.owner = p_idx_rec.owner
             AND ips.index_name = p_idx_rec.index_name
             AND ips.object_type = 'PARTITION'
             AND tps.partition_position = ips.partition_position
             AND tps.partition_name != ips.partition_name;

          IF l_count > 0 THEN
        	s_obs_rec.priority	  := 35;
	        s_obs_rec.type_id     := E_INDEX_PART;
            s_obs_rec.object_type := 'INDEX PARTITION';
            s_obs_rec.object_name := p_tab_rec.table_name||'.'||p_idx_rec.index_name;
            s_obs_rec.observation := 'Check that the statistics are correct. Index contains '||l_count||' partition(s) where the partition name does not match to corresponding Table partition(s) name. Possibly Bug 14013094 - DBMS_STATS places statistics in the wrong index partition (Doc ID 14013094.8).';
            s_obs_rec.more        := 'Review <a href="#tbl_part_stats_'||p_tab_rec.object_id||'">table partition statistics</a> and <a href="#idx_part_stats_'||p_idx_rec.object_id||'">index partition statistics</a> and try to rule out Bug 14013094.';
            ins_obs;
          END IF;
        END IF;
      END IF;
    END IF;

    write_log('<- index_hc_'||p_idx_rec.index_name);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('index_hc_'||p_idx_rec.index_name||': '||SQLERRM);
  END index_hc;

  /*************************************************************************************/

  /* -------------------------
   *
   * private column_hc
   *
   * ------------------------- */
  PROCEDURE column_hc (
    p_tab_rec IN sqlt$_dba_all_tables_v%ROWTYPE,
    p_col_rec IN sqlt$_dba_all_table_cols_v%ROWTYPE )
  IS
    l_count    NUMBER;
    l_count2   NUMBER;
    l_factor   NUMBER;
    l_ratio    NUMBER;

  BEGIN
    write_log('-> column_hc_'||p_col_rec.table_name||'_'||p_col_rec.column_name);

    -- (136)
	-- ADD COLUMN...DEFAULT optimization
    IF p_col_rec.add_column_default = 'Y' THEN
      s_obs_rec.priority	:= 21;
	  s_obs_rec.type_id     := E_TABLE_COL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
      s_obs_rec.observation := 'If possible set up an ADD COLUMN...DEFAULT optimization to improve the CBO chances of generating a good plan.';
      s_obs_rec.more        := 'Reference <a href="#tab_cols_prop_'||p_tab_rec.object_id||'">column properties</a>. Plan generation for such columns differs from normal columns because references to it are internally turned into the equivalent of NVL(column, default).';
      ins_obs;
    END IF;

    -- (137)
	-- no stats
    IF p_tab_rec.temporary = 'N' AND
       p_col_rec.last_analyzed IS NULL AND
       LENGTH(REPLACE(TRANSLATE(p_col_rec.column_name, '01234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ_$#', NUL), NUL)) > 0
    THEN
      s_obs_rec.priority	:= 40;
	  s_obs_rec.type_id     := E_TABLE_COL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
      s_obs_rec.observation := 'Check that you have valid statistics on all columns. CBO statistics missing for column with unconventional name. Also check MOS note Script to detect bugs on statistics (Doc ID 337096.1) and Bug 4892211 - DBMS_STATS does not recognise lower case / special characters in column names (Doc ID 4892211.8).';
      s_obs_rec.more        := 'Possible Bug 4892211. Consider gathering CBO <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> using METHOD_OPT=>FOR ALL [INDEXED] COLUMNS';
      ins_obs;
    END IF;

    IF p_tab_rec.num_rows - p_col_rec.num_nulls > 0 THEN
      l_ratio := p_tab_rec.sample_size/(p_tab_rec.num_rows - p_col_rec.num_nulls);

      IF p_tab_rec.num_rows < 1e6 THEN -- up to 1M then 100%
        l_factor := 1;
      ELSIF p_tab_rec.num_rows < 1e7 THEN -- up to 10M then 30%
        l_factor := 3/10;
      ELSIF p_tab_rec.num_rows < 1e8 THEN -- up to 100M then 10%
        l_factor := 1/10;
      ELSIF p_tab_rec.num_rows < 1e9 THEN -- up to 1B then 3%
        l_factor := 3/100;
      ELSE -- more than 1B then 1%
        l_factor := 1/100;
      END IF;
    ELSE
      l_ratio := NULL;
      l_factor := NULL;
    END IF;

    -- (138)
	-- small sample size in column with histogram
    IF p_col_rec.histogram IN ('FREQUENCY', 'HEIGHT BALANCED') AND p_col_rec.sample_size < LEAST(5000, p_tab_rec.num_rows - p_col_rec.num_nulls) THEN
      s_obs_rec.priority	  := 28;
	  s_obs_rec.type_id     := E_TABLE_COL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
      s_obs_rec.observation := 'Consider collecting a larger sample size for table. Sample size of '||p_col_rec.sample_size||' rows is too small for column with histogram. Sample percent used was:'||TRIM(TO_CHAR(ROUND(l_ratio * 100, 2), PERCENT_FORMAT))||'%. Also review MOS Note Statistics Gathering: Frequency and Strategy Guidelines (Doc ID 44961.1).';
      s_obs_rec.more        := 'Consider gathering better quality CBO <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> with a larger sample size. Suggested sample size: ';
      IF s_sql_rec.rdbms_release < 11 THEN
        s_obs_rec.more := s_obs_rec.more||ROUND(l_factor * 100)||'%.';
      ELSE
        s_obs_rec.more := s_obs_rec.more||'DBMS_STATS.AUTO_SAMPLE_SIZE (default).';
      END IF;
      ins_obs;
    END IF;

    -- (139)
	-- 11g and new ndv algorithm was not used and insufficiently sampled for NDV
    IF s_sql_rec.rdbms_release >= 11 AND p_tab_rec.new_11g_ndv_algorithm_used = 'NO' AND l_ratio < (9/10) * l_factor THEN -- 10% tolerance
      s_obs_rec.priority    := 28;
	  s_obs_rec.type_id     := E_TABLE_COL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
      s_obs_rec.observation := 'Consider collecting a larger sample size for table columns. Sample size of '||p_col_rec.sample_size||' rows may be too small for column with histogram. Sample percent used was:'||TRIM(TO_CHAR(ROUND(l_ratio * 100, 2), PERCENT_FORMAT))||'%. Also review MOS Note Statistics Gathering: Frequency and Strategy Guidelines (Doc ID 44961.1).';
      s_obs_rec.more        := 'Consider gathering better quality CBO <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> with a sample size of SYS.DBMS_STATS.AUTO_SAMPLE_SIZE (default).';
      ins_obs;
    END IF;

    -- (140)
	-- 10g and insufficiently sampled for NDV
    IF s_sql_rec.rdbms_release < 11 AND l_ratio < (9/10) * l_factor THEN -- 10% tolerance
      s_obs_rec.priority	:= 28;
	  s_obs_rec.type_id     := E_TABLE_COL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
      s_obs_rec.observation := 'Consider collecting a larger sample size for table columns. Sample size of '||p_col_rec.sample_size||' rows may be too small for column with histogram. Sample percent used was:'||TRIM(TO_CHAR(ROUND(l_ratio * 100, 2), PERCENT_FORMAT))||'%. Also review MOS Note Statistics Gathering: Frequency and Strategy Guidelines (Doc ID 44961.1).';
      s_obs_rec.more        := 'Consider gathering better quality CBO <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> with a sample size of '||ROUND(l_factor * 100)||'%.';
      ins_obs;
    END IF;

    -- (141)
	-- low/high range too wide
    IF p_col_rec.data_type = 'DATE' OR p_col_rec.data_type LIKE 'TIMESTAMP%' THEN
      -- low/high expected to be with 10 years in the past and 3 years in the future
      IF TO_DATE(p_col_rec.low_value_cooked, 'SYYYY/MM/DD HH24:MI:SS') < SYSDATE - (365.25 * 10) OR
         TO_DATE(p_col_rec.high_value_cooked, 'SYYYY/MM/DD HH24:MI:SS') > SYSDATE + (365.25 * 3) THEN
        s_obs_rec.priority	  := 34;
        s_obs_rec.type_id     := E_TABLE_COL;
        s_obs_rec.object_type := 'TABLE COLUMN';
        s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
        s_obs_rec.observation := 'Determine the cause of some date column statistics being too far in future or too old. Low/High values seem too far from current date. Low:'||p_col_rec.low_value_cooked||'. High:'||p_col_rec.high_value_cooked||'. Also review MOS Note Handling statistics for a column with ever increasing or decreasing values... (Doc ID 877645.1).';
        s_obs_rec.more        := 'Dates too far in the past or future may cause the CBO to under-estimate selectivity for some predicates. Consider fixing the values in this column to be closer to the present.';
        IF p_col_rec.num_buckets < 2 THEN
          s_obs_rec.more := s_obs_rec.more||' If stats were gathered with default method_opt, review Bug 9823080.';
        END IF;
        ins_obs;
      END IF;
    END IF;

    -- (142)
	-- 9885553 incorrect ndv in long char column with histogram
    IF p_col_rec.num_distinct > 0 AND
       p_col_rec.data_type LIKE '%CHAR%' AND
       p_col_rec.avg_col_len > 32 AND
       p_col_rec.histogram IN ('FREQUENCY', 'HEIGHT BALANCED') AND
       s_sql_rec.rdbms_version < '11.2.0.3'
    THEN
      s_obs_rec.priority    := 60;
	  s_obs_rec.type_id     := E_TABLE_COL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
      s_obs_rec.observation := 'Check for the applicability of bug 9885553 as a Long CHAR column with Histogram is referenced in at least one Predicate. NDV could be incorrect. See MOS Note Bug 9885553 - DBMS_STATS produces incorrect column NDV distinct values statistics (Doc ID 9885553.8).';
      s_obs_rec.more        := 'Possible Bug 9885553. As per CBO <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">column statistics</a> there are '||p_col_rec.num_distinct||' distinct values in this column. If this value is wrong then drop the Histogram.';
      ins_obs;
    END IF;

    -- (143)
	-- 4495422 bad histogram
    IF p_col_rec.num_distinct > 0 AND
       p_col_rec.data_type LIKE '%CHAR%' AND
       p_col_rec.avg_col_len > 5 AND
       p_col_rec.num_buckets > 1
    THEN
      SELECT COUNT(endpoint_value), COUNT(DISTINCT endpoint_value)
        INTO l_count, l_count2
        FROM sqlt$_dba_tab_histograms
       WHERE statement_id = p_tab_rec.statement_id
         AND owner = p_col_rec.owner
         AND table_name = p_col_rec.table_name
         AND column_name = p_col_rec.column_name
         AND endpoint_actual_value IS NULL;

      IF l_count > 0 AND l_count <> l_count2 THEN
    	s_obs_rec.priority	  := 39;
	    s_obs_rec.type_id     := E_TABLE_COL;
        s_obs_rec.object_type := 'TABLE COLUMN';
        s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
        s_obs_rec.observation := 'Check the histogram statistics. Possible distinct values with same endpoint_value in histogram. If needed you can drop and recreate the histograms using METHOD_OPT. Also see MOS Note Script to detect bugs on statistics (Doc ID 337096.1).';
        s_obs_rec.more        := 'Review <a href="#tab_col_hgrm_'||p_tab_rec.object_id||'_'||p_col_rec.column_name||'">histogram</a>, if there were buckets with same endpoint_value, consider dropping the histogram by collecting new CBO statistics while using METHOD_OPT=>... SIZE 1. See 4495422.';
        ins_obs;
      END IF;
    END IF;

    -- (144)
	-- 8543770 corrupted histogram
    IF p_col_rec.num_distinct > 0 AND
       p_col_rec.num_buckets > 1
    THEN
      SELECT COUNT(DISTINCT c1.endpoint_number)
        INTO l_count
        FROM sqlt$_dba_tab_histograms c1,
             sqlt$_dba_tab_histograms c2
       WHERE c1.statement_id = p_tab_rec.statement_id
         AND c1.owner = p_col_rec.owner
         AND c1.table_name = p_col_rec.table_name
         AND c1.column_name = p_col_rec.column_name
         AND c2.statement_id = p_tab_rec.statement_id
         AND c2.owner = p_col_rec.owner
         AND c2.table_name = p_col_rec.table_name
         AND c2.column_name = p_col_rec.column_name
         AND c1.endpoint_number < c2.endpoint_number
         AND c1.endpoint_value > c2.endpoint_value;

      IF l_count > 0 THEN
    	s_obs_rec.priority	  := 70;
	    s_obs_rec.type_id     := E_TABLE_COL;
        s_obs_rec.object_type := 'TABLE COLUMN';
        s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
        s_obs_rec.observation := 'Check the correctness of the histograms. There appear to be corrupted histogram(s). See Bug 8543770 - ORA-39083 / ORA-1403 from IMPDP on INDEX_STATISTICS (Doc ID 8543770.8) and bugs 0267075, 12819221 and 12876988.';
        s_obs_rec.more        := 'Review <a href="#tab_col_hgrm_'||p_tab_rec.object_id||'_'||p_col_rec.column_name||'">histogram</a>, there are/is '||l_count||' bucket(s) with value out of order. Consider dropping the histogram by collecting new CBO statistics while using METHOD_OPT=>... SIZE 1. See 8543770, 10267075, 12819221 and 12876988.';
        ins_obs;
      END IF;
    END IF;

    -- (145)
	-- 10174050 frequency histograms with less buckets than ndv
    IF p_col_rec.histogram = 'FREQUENCY' AND p_col_rec.num_distinct <> p_col_rec.num_buckets THEN
      s_obs_rec.priority	:= 72;
	  s_obs_rec.type_id     := E_TABLE_COL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
      s_obs_rec.observation := 'Check the accuracy of the column statistics and recollect with a higher sample size. Frequency histogram with number of buckets not matching the number of distinct values. Also see MOS Note Histograms: An Overview (10g and Above) (Doc ID 1445372.1).';
      s_obs_rec.more        := 'Review <a href="#tab_col_hgrm_'||p_tab_rec.object_id||'_'||p_col_rec.column_name||'">histogram</a>. If there are values missing from the frequency histogram you may have Bug 10174050. If you are referencing in your predicates one of the missing values the CBO can over estimate table cardinality, and this may produce a sub-optimal plan. As a workaround: alter system/session "_fix_control"=''5483301:off'';<br>'||
                                'Another case when it''s possible to have a smaller number of buckets than the NDV is when several distinct values have the same starting 32 chars (64 in 12c), in this case the fix for Bug 18377553 can help.';
      ins_obs;
    END IF;

    -- (146)
	-- frequency histogram with 1 bucket
    IF p_col_rec.histogram = 'FREQUENCY' AND p_col_rec.num_buckets = 1 THEN
      s_obs_rec.priority	:= 50;
	  s_obs_rec.type_id     := E_TABLE_COL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
      s_obs_rec.observation := 'Consider if you need to keep or expand the column histogram with only 1 bucket. Also see MOS Note Histograms: An Overview (10g and Above) (Doc ID 1445372.1). Also check against Bugs 1386119, 4406309, 4495422, 4567767, 5483301 or 6082745.';
      s_obs_rec.more        := 'Possible Bugs 1386119, 4406309, 4495422, 4567767, 5483301 or 6082745. Consider removing <a href="#tab_col_hgrm_'||p_tab_rec.object_id||'_'||p_col_rec.column_name||'">histogram</a> in this column by collecting new CBO statistics while using METHOD_OPT=>... SIZE 1.';
      ins_obs;
    END IF;

    -- (147)
	-- height balanced histogram with no popular values
    IF p_col_rec.histogram = 'HEIGHT BALANCED' AND p_col_rec.popular_values = 0 THEN
      s_obs_rec.priority	:= 50;
	  s_obs_rec.type_id     := E_TABLE_COL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
      s_obs_rec.observation := 'Consider if the HEIGHT BALANCED histogram is needed or if the sampling needs to be improved. Height-balanced histogram with no popular values is not useful. Also see MOS Note Histograms: An Overview (10g and Above) (Doc ID 1445372.1).';
      s_obs_rec.more        := 'A Height-balanced histogram with no popular values is not helpful nor desired. Consider removing <a href="#tab_col_hgrm_'||p_tab_rec.object_id||'_'||p_col_rec.column_name||'">histogram</a> in this column by collecting new CBO statistics while using METHOD_OPT=>... SIZE 1.';
      ins_obs;
    END IF;

    -- (148)
	-- column in predicate and no index for it
    IF p_col_rec.in_indexes = 'FALSE' THEN
      s_obs_rec.priority	:= 85;
	  s_obs_rec.type_id     := E_TABLE_COL;
      s_obs_rec.object_type := 'TABLE COLUMN';
      s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
      s_obs_rec.observation := 'An index should be created for a column referenced in a predicate. Also see MOS Note Diagnosing and Understanding Why a Query is Not Using an Index (Doc ID 67522.1).';
      IF s_sql_rec.siebel = 'YES' THEN
        s_obs_rec.more      := 'SIEBEL requires that all columns referenced by a predicate must be included in an index. This would allow the CBO to consider using such index to access or filter data more efficiently. Review <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">predicate(s)</a> where this column is used and include this column in an index (new or existing) if necessary.';
      ELSE
        s_obs_rec.more      := 'Having this column included in an index allows the CBO to consider using such index to access or filter data more efficiently. Review <a href="#tab_cols_cbo_'||p_tab_rec.object_id||'">predicate(s)</a> where this column is used and consider including this column in an index (new or existing).';
      END IF;
      ins_obs;
    END IF;

    -- (149)
	-- not null candidate and possibly single-column index candidate
    IF p_tab_rec.num_rows > 0 AND
       p_col_rec.num_nulls = 0 AND
       p_col_rec.owner NOT IN ('SYS', 'SYSTEM', 'PUBLIC')
    THEN
      -- not null candidate
      IF p_col_rec.nullable = 'Y' THEN
    	s_obs_rec.priority	  := 9;
	    s_obs_rec.type_id     := E_TABLE_COL;
        s_obs_rec.object_type := 'TABLE COLUMN';
        s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
        s_obs_rec.observation := 'Check to see if a NOT NULL constraint would be useful on '||p_col_rec.table_name||'.'||p_col_rec.column_name||'.';
        s_obs_rec.more        := 'Consider creating a NOT NULL constraint. CBO uses constraints to generate additional predicates that may help to improve selectivity computations referencing this column. Better computations may allow a better plan.';
        ins_obs;
      END IF;

      -- (150)
	  -- single-column index candidate
      IF p_col_rec.num_distinct = p_tab_rec.num_rows AND
         (p_col_rec.data_type IN ('VARCHAR2', 'NUMBER', 'DATE', 'CHAR', 'ROWID', 'RAW', 'FLOAT', 'NVARCHAR2', 'NCHAR', 'ANYDATA') OR p_col_rec.data_type LIKE 'TIMESTAMP%')
      THEN
        SELECT COUNT(*)
          INTO l_count
          FROM sqlt$_dba_indexes
         WHERE statement_id = p_tab_rec.statement_id
           AND index_type NOT IN ('DOMAIN', 'LOB', 'FUNCTION-BASED DOMAIN')
           AND table_owner = p_tab_rec.owner
           AND table_name = p_tab_rec.table_name
           AND uniqueness = 'UNIQUE'
           AND sqlt$a.get_index_column_count(statement_id, owner, index_name) = 1
           AND p_col_rec.column_name = sqlt$a.get_index_column_names(statement_id, owner, index_name, 'YES')
           AND ROWNUM = 1;

        IF l_count = 0 THEN
          s_obs_rec.priority	:= 29;
	      s_obs_rec.type_id     := E_TABLE_COL;
          s_obs_rec.object_type := 'TABLE COLUMN';
          s_obs_rec.object_name := p_col_rec.table_name||'.'||p_col_rec.column_name;
          s_obs_rec.observation := 'Check the usefullness of creating a UNIQUE index on column '||p_col_rec.table_name||'.'||p_col_rec.column_name||'.';
          s_obs_rec.more        := 'Consider creating a UNIQUE index on this single column. It is used in predicates and the CBO could use it in some queries.';
          ins_obs;
        END IF;
      END IF;
    END IF;

    write_log('<- column_hc_'||p_col_rec.table_name||'_'||p_col_rec.column_name);
  EXCEPTION
    WHEN OTHERS THEN
      write_error('column_hc_'||p_col_rec.table_name||'_'||p_col_rec.column_name||': '||SQLERRM);
  END column_hc;

  /*************************************************************************************/

  /* -------------------------
   *
   * public health_check
   *
   * called by: sqlt$m.main_report
   *
   * ------------------------- */
  PROCEDURE health_check (p_statement_id IN NUMBER)
  IS
  BEGIN
    write_log('=> health_check');

    s_sql_rec := sqlt$a.get_statement(p_statement_id);
    DELETE sqlg$_observation;

    -- global
    global_hc;

    -- ebs specific
    IF s_sql_rec.apps_release IS NOT NULL THEN
      ebs_hc;
    END IF;

    -- siebel specific
    IF s_sql_rec.siebel = 'YES' THEN
      siebel_hc;
    END IF;

    -- tables
    FOR i IN (SELECT *
                FROM sqlt$_dba_all_tables_v
               WHERE statement_id = p_statement_id
               ORDER BY
                     table_name)
    LOOP
      table_hc(i);

      -- indexes
      FOR j IN (SELECT *
                  FROM sqlt$_dba_indexes
                 WHERE statement_id = p_statement_id
                   AND table_owner = i.owner
                   AND table_name = i.table_name
                   AND index_type NOT IN ('DOMAIN', 'LOB', 'FUNCTION-BASED DOMAIN')
                 ORDER BY
                       index_name)
      LOOP
        index_hc(i, j);
      END LOOP;

      -- columns
      FOR j IN (SELECT *
                  FROM sqlt$_dba_all_table_cols_v
                 WHERE statement_id = p_statement_id
                   AND owner = i.owner
                   AND table_name = i.table_name
                   AND in_predicates = 'TRUE'
                 ORDER BY
                       column_name)
      LOOP
        column_hc(i, j);
      END LOOP;
    END LOOP;

    COMMIT;
    write_log('<= health_check');
  END health_check;

  /*************************************************************************************/

END sqlt$h;
/

SET TERM ON;
SHOW ERRORS PACKAGE BODY &&tool_administer_schema..sqlt$h;
