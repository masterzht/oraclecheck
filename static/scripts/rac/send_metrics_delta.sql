set serveroutput on size 100000
REM --------------------------------------------------------------------------------------------------
REM Author: Riyaj Shamsudeen @OraInternals, LLC
REM         www.orainternals.com
REM
REM Functionality: This script is to print GC processing timing for the past N seconds or so
REM **************
REM   
REM Source  : gv$sysstat
REM
REM Note : 1. Keep window 160 columns for better visibility.
REM
REM Exectution type: Execute from sqlplus or any other tool.  Modify sleep as needed. Default is 60 seconds
REM
REM Parameters: 
REM No implied or explicit warranty
REM
REM Please send me an email to rshamsud@orainternals.com for any question..
REM  NOTE   1. Querying gv$ tables when there is a GC performance issue is not exactly nice. So, don't run this too often.
REM         2. Until 11g, gv statistics did not include PQ traffic.
REM         3. Of course, this does not tell any thing about root cause :-)
REM @copyright : OraInternals, LLC. www.orainternals.com
REM Version	Change
REM ----------	--------------------
REM --------------------------------------------------------------------------------------------------
set serveroutput on size 100000
undef name_name
undef sleep
PROMPT
PROMPT
PROMPT  send_metrics_delta.sql v1.10 by Riyaj Shamsudeen @orainternals.com
PROMPT
PROMPT  ...Prints various timing related information for the past N seconds
PROMPT  ...Default collection period is 60 seconds.... Please wait for at least 60 seconds...
PROMPT
undef name_name
undef sleep

PROMPT Average instance-wide
PROMPT ---------------------
select inst_id, name, average_wait from gv$system_name
where name like '%&&name_name%'
;
set lines 170 pages 100
set verify off

declare
	type t_number_table   is table of number       index by varchar2(32);
	type t_varchar2_table  is table of varchar2(60)       index by varchar2(32);
	type t_key_table  is table of varchar2(60)       index by binary_integer;

        key_table                   t_key_table;

	b_inst_id                   t_number_table;
	b_name                     t_varchar2_table;
	b_value           t_number_table;
	b_wait_count                t_number_table;
	b_tot                       t_number_table;

	e_inst_id                   t_number_table;
	e_name                     t_varchar2_table;
	e_value           t_number_table;
	e_wait_count                t_number_table;
	e_tot                       t_number_table;


	v_ver number;
	l_sleep number:=60;
	l_cr_blks_served number :=0;
	l_cur_blks_served number :=0;
	
	i number:=1;
	ind varchar2(32);
begin
      
	for c1 in ( 
          select inst_id||'_'||sys.name indx,inst_id, sys.name, sys.value from gv$sysstat sys
          where sys.name in (
            'gc cr block build time',
            'gc cr block send time',
            'gc cr block flush time',
            'gc current block pin time',
            'gc current block send time',
            'gc current block flush time'
          )
        )
        loop
		key_table(i):= c1.indx;
		b_inst_id (c1.indx) := c1.inst_id;
		b_name (c1.indx) := c1.name;
		b_value (c1.indx) := c1.value;
		i := i+1;
	end loop;
 
        select upper(nvl('&sleep',60)) into l_sleep from dual;
	dbms_lock.sleep(l_sleep);
  
        i:=1;

	for c2 in ( 
          select inst_id||'_'||sys.name indx,inst_id, sys.name, sys.value from gv$sysstat sys
          where sys.name in (
            'gc cr block build time',
            'gc cr block send time',
            'gc cr block flush time',
            'gc current block pin time',
            'gc current block send time',
            'gc current block flush time'
          )
	 )
        loop
		e_inst_id (c2.indx) := c2.inst_id;
		e_name (c2.indx) := c2.name;
		e_value (c2.indx) := c2.value;
		i := i+1;
	end loop;


	dbms_output.put_line ( '|----|------------------------------|-----------|');
	dbms_output.put_line ( '|Inst| Name                         |      Time |');
	dbms_output.put_line ( '|----|------------------------------|-----------|');

	for indx in key_table.first .. key_table.last
         loop
	  ind :=  key_table (indx);
	  dbms_output.put_line (  '|' ||
                                 lpad( e_inst_id(ind),4)  || '|' ||
				 lpad(to_char(e_name (ind)),30)  || '|'||
				 lpad(to_char(e_value (ind) ),11)  || '|'
                                 )
                                ;
	 end loop;
	 dbms_output.put_line ( '-------------------------------------------------------------------------------');
	 dbms_output.put_line ( ' ');
end;
/
set verify on 

