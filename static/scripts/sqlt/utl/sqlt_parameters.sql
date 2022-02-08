SET TERM OFF ECHO OFF FEED OFF VER OFF SHOW OFF HEA OFF LIN 2000 NUM 20 NEWP NONE PAGES 0 LONG 2000000 LONGC 2000 SQLC MIX TAB ON TRIMS ON TI OFF TIMI OFF ARRAY 100 NUMF "" SQLP SQL> SUF sql BLO . RECSEP OFF APPI OFF AUTOT OFF SERVEROUT ON SIZE UNL;;
SPO sqlt_configuration_parameters.html;
REM $Header: 215187.1 sqlt_parameters.sql 12.1.02 2012/09/09 mauro.pagano $
REM
REM Copyright (c) 2000-2013, Oracle Corporation. All rights reserved.
REM
REM AUTHOR
REM   mauro.pagano@oracle.com
REM
REM SCRIPT
REM   sqlt/utl/sqlt_parameters.sql
REM
REM DESCRIPTION
REM   Creates a file with SQLT current configuration including
REM   1. Version, Version Date and Installation Date
REM   2. List of all the parameters, their values and the range of values accepted
REM
REM PRE-REQUISITES
REM   1. Connect as a USER granted SQLT_USER_ROLE
REM
REM EXECUTION
REM   1. Run sqlt_parameters.html
REM
REM EXAMPLE
REM   # cd sqlt/utl
REM   # sqlplus apps
REM   SQL> START [path]sqlt_parameters.sql 
REM   SQL> START utl/sqlt_parameters.sql 
REM

PRO <html>
PRO <head>
PRO <title>sqlt_configuration_parameters.html</title>
PRO
PRO <style type="text/css">
PRO body {font:10pt Arial, Helvetica, Verdana, Geneva, sans-serif; color:Black; background:White;}
PRO h1 {font-size:16pt; font-weight:bold; color:#336699;}
PRO h2 {font-size:12pt; font-weight:bold; color:#336699;}
PRO table {font-size:8pt; color:black; background:white;}
PRO th {font-weight:bold; background:#cccc99; color:#336699; vertical-align:bottom; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
PRO td {text-align:left; background:#fcfcf0; vertical-align:top; padding-left:3pt; padding-right:3pt; padding-top:1pt; padding-bottom:1pt;}
PRO font.n {font-size:8pt; font-style:italic; color:#336699;} /* table footnote in blue */
PRO font.f {font-size:8pt; color:#999999;} /* footnote in gray */
PRO </style>
PRO
PRO </head>
PRO <body>
PRO <h1>SQLT Configuration Parameters</h1>
PRO

PRO <h2>SQLT Version</h2>
SET HEA ON PAGES 25 MARK HTML ON TABLE "" ENTMAP OFF SPOOL OFF;
SELECT ROWNUM "#", v.* FROM (
SELECT /*+ NO_MERGE */
       p.name,
       p.value
  FROM sqltxplain.sqli$_parameter p
 WHERE p.is_hidden = 'N'
   AND p.is_usr_modifiable = 'N'
 ORDER BY
       p.name) v;
SET HEA OFF PAGES 0 MARK HTML OFF;
       
PRO <h2>SQLT System and Session Parameters</h2>
SET HEA ON PAGES 25 MARK HTML ON TABLE "" ENTMAP OFF SPOOL OFF;
SELECT ROWNUM "#", v.* FROM (
SELECT /*+ NO_MERGE */
       CASE WHEN p.is_default = 'Y' AND NVL(s.is_default, 'Y') = 'Y' THEN 'TRUE      ' ELSE 'FALSE     ' END is_default,
       p.name,
       p.description,
       p.value system_value,
       NVL(s.value, p.value) session_value,
       p.default_value,
       p.instructions domain
  FROM sqltxplain.sqli$_parameter p,
       sqltxplain.sqli$_sess_parameter s
 WHERE p.is_hidden = 'N'
   AND p.is_usr_modifiable = 'Y'
   AND p.name = s.name(+)
 ORDER BY
       CASE WHEN p.is_default = 'Y' AND NVL(s.is_default, 'Y') = 'Y' THEN 'TRUE' ELSE 'FALSE' END,
       p.name) v;
SET HEA OFF PAGES 0 MARK HTML OFF;

PRO <font class="n">(1) To permanently set a tool parameter issue: SQL> EXEC SQLTXADMIN.sqlt$a.set_param('Name', 'Value');</font>
PRO <br>
PRO <font class="n">(2) To temporarily set a tool parameter for a session issue: SQL> EXEC SQLTXADMIN.sqlt$a.set_sess_param('Name', 'Value');</font>

PRO
SELECT '<!-- '||TO_CHAR(SYSDATE, 'YYYY-MM-DD/HH24:MI:SS')||' -->' FROM dual;
PRO <hr size="3">
PRO <font class="f">sqlt_parameters</font>
PRO </body>
PRO </html>

SPO OFF;

SET TERM ON ECHO OFF FEED 6 VER ON SHOW OFF HEA ON LIN 80 NUM 10 NEWP 1 PAGES 14 LONG 80 LONGC 80 SQLC MIX TAB ON TRIMS OFF TI OFF TIMI OFF ARRAY 15 NUMF "" SQLP SQL> SUF sql BLO . RECSEP WR APPI OFF SERVEROUT OFF AUTOT OFF;
PRO SQLT_PARAMETERS COMPLETED
