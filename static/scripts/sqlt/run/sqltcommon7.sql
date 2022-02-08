REM $Header: 215187.1 sqltcommon7.sql 12.1.12 2015/09/11 carlos.sierra abel.macias@oracle.com $ 
-- begin common
EXEC ^^tool_administer_schema..sqlt$a.trace_off;
SET TERM ON;
PRO ### tkprof commands below may error out with "could not open trace file". disregard error.
SET TERM OFF;
-- 150826 Concat trace file segments
HOS mknod ^^udump_path.ora_S^^statement_id._SQLT_TRACE.trp p
HOS cat ^^udump_path.*_ora_*_S^^statement_id._SQLT_TRACE*.trc >^^udump_path.ora_S^^statement_id._SQLT_TRACE.trp &
HOS tkprof ^^udump_path.ora_S^^statement_id._SQLT_TRACE.trp ^^unique_id._sqlt_tkprof_nosort.txt
HOS cat ^^udump_path.*_ora_*_S^^statement_id._SQLT_TRACE*.trc >^^udump_path.ora_S^^statement_id._SQLT_TRACE.trp &
HOS tkprof ^^udump_path.ora_S^^statement_id._SQLT_TRACE.trp ^^unique_id._sqlt_tkprof_sort.txt sort=prsela exeela fchela
-- windows workaround (copy below will error out on linux and unix)
SET TERM ON;
PRO ### copy command below will error out on linux and unix. disregard error.
SET TERM OFF;
-- 150826 Concat trace file segments
HOS copy ^^udump_path.*_ora_*_S^^statement_id._SQLT_TRACE*.trc ^^udump_path.S^^statement_id._SQLT_TRACE.trc
SET TERM ON;
PRO ### tkprof commands below may error out with "could not open trace file". disregard error.
SET TERM OFF;
HOS tkprof ^^udump_path.S^^statement_id._SQLT_TRACE.trc ^^unique_id._sqlt_tkprof_wnosort.txt
HOS tkprof ^^udump_path.S^^statement_id._SQLT_TRACE.trc ^^unique_id._sqlt_tkprof_wsort.txt sort=prsela exeela fchela
-- unix/linux: in cases where local udump_path is not pointing to database server udump
-- set dircetory path for traces and be sure to include / at the end of it.
-- example: EXEC sqltxadmin.sqlt$a.set_param('traces_directory_path', '/u04/oraout_db/gsiav/gsi1av/trace/');
SET TERM ON;
PRO ### tkprof commands below may error out with "could not open trace file". disregard error.
SET TERM OFF;
-- 150826 Concat trace file segments
HOS cat ^^traces_directory_path.*_ora_*_S^^statement_id._SQLT_TRACE*.trc >^^traces_directory_path.ora_S^^statement_id._SQLT_TRACE.trp &
HOS tkprof ^^traces_directory_path.ora_S^^statement_id._SQLT_TRACE.trp ^^unique_id._sqlt_tkprof_tnosort.txt
HOS cat ^^traces_directory_path.*_ora_*_S^^statement_id._SQLT_TRACE*.trc >^^traces_directory_path.ora_S^^statement_id._SQLT_TRACE.trp &
HOS tkprof ^^traces_directory_path.ora_S^^statement_id._SQLT_TRACE.trp ^^unique_id._sqlt_tkprof_tsort.txt sort=prsela exeela fchela
--
HOS rm ^^udump_path.ora_S^^statement_id._SQLT_TRACE.trp
HOS rm ^^traces_directory_path.ora_S^^statement_id._SQLT_TRACE.trp
--
HOS zip -m ^^unique_id._log ^^unique_id._sqlt_tkprof_*.txt
--
HOS zip -j ^^unique_id._log ^^bdump_path.alert_*.log
--
HOS zip -j ^^unique_id._log ^^spfile.
--
HOS zip -j ^^unique_id._opatch $ORACLE_HOME/cfgtoollogs/opatch/opatch*
--
SET TERM ON;
PRO ### chmod command below will error out on windows. disregard error.
SET TERM OFF;
HOS chmod 777 install.sh
HOS zip ^^unique_id._tcx ^^unique_id._system_stats.sql ^^unique_id._set_cbo_env.sql
HOS zip -m ^^unique_id._tcx ^^unique_id._metadata1.sql
HOS zip -m ^^unique_id._tcx ^^unique_id._metadata2.sql
HOS zip ^^unique_id._tcx q.sql plan.sql 10053.sql flush.sql tc.sql sel.sql sel_aux.sql
HOS zip -m ^^unique_id._tcx  install.sql install.sh pack_tcx.sql
HOS zip -m ^^unique_id._tcx ^^unique_id._schema_stats.sql
--
SET TERM ON;
PRO ### chmod command below will error out on windows. disregard error.
SET TERM OFF;
HOS chmod 777 xpress.sh
HOS zip -m ^^unique_id._tc ^^unique_id._system_stats.sql ^^unique_id._set_cbo_env.sql
HOS zip -m ^^unique_id._tc ^^unique_id._metadata.sql
HOS zip -m ^^unique_id._tc ^^unique_id._readme.txt
HOS zip -m ^^unique_id._tc q.sql plan.sql 10053.sql flush.sql tc.sql sel.sql sel_aux.sql
HOS zip -m ^^unique_id._tc xpress.sql xpress.sh setup.sql readme.txt tc_pkg.sql
HOS zip -m ^^unique_id._tc ^^unique_id._purge.sql ^^unique_id._restore.sql ^^unique_id._del_hgrm.sql
HOS zip -j ^^unique_id._tc ^^unique_id._opatch.zip
--
HOS zip -ju ^^unique_id._trc ^^udump_path.*_s^^statement_id._*.trc
HOS zip -ju ^^unique_id._trc ^^bdump_path.*_s^^statement_id._*.trc
HOS zip -ju ^^unique_id._trc ^^traces_directory_path.*_s^^statement_id._*.trc
-- end common
