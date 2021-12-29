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
REM  NOTE   1. Querying gv$ tables when there is a GC performance issue is not exactly nice. So, don''t run this too often.
REM         2. Until 11g, gv statistics did not include PQ traffic.
REM         3. Of course, this does not tell any thing about root cause :-)
REM @copyright : OraInternals, LLC. www.orainternals.com
REM Version	Change
REM ----------	--------------------
REM --------------------------------------------------------------------------------------------------
set serveroutput on size 100000
undef event_name
undef sleep
PROMPT
PROMPT
PROMPT  gc_instance_cache.sql v1.10 by Riyaj Shamsudeen @orainternals.com
PROMPT
PROMPT  ...Prints various timing related information for the past N seconds
PROMPT  ...Default collection period is 60 seconds.... Please wait for at least 60 seconds...
PROMPT
PROMPT Column name key:
PROMPT   Inst -> Inst class :  source and target instance and class of the block transfer
PROMPT   CR blk TX  :  CR blocks transmitted
PROMPT   CR blk tm  :  CR blocks time taken
PROMPT   CR blk av  :  Average time taken for CR block
PROMPT   CR bsy     :  Count of blocks suffered from "busy" events
PROMPT   CR bsy tm  :  Amount of time taken due to "busy" waits
PROMPT   CR bsy %   :  Percentage of CR busy time to CR time
PROMPT   CR congest :  Count of blocks suffered from "congestion" events
PROMPT   CR cngsttm :  Amount of time taken due to "congestion" waits
PROMPT   CR cng %   :  Percentage of CR congestion time to CR time
undef event_name
undef sleep
set lines 170 pages 100
set verify off

declare
	type t_number_table   is table of number       index by varchar2(32);
	type t_varchar2_table  is table of varchar2(60)       index by varchar2(32);
	type t_key_table  is table of varchar2(60)       index by binary_integer;

        key_table                                                                    t_key_table;

	b_inst_id                                                                    t_number_table;
	b_event                                                                      t_varchar2_table;
	b_wait_time_milli                                                            t_number_table;
	b_wait_count                                                                 t_number_table;
	b_tot                                                                        t_number_table;

	e_inst_id                                                                    t_number_table;
	e_event                                                                      t_varchar2_table;
	e_wait_time_milli                                                            t_number_table;
	e_wait_count                                                                 t_number_table;
	e_tot                                                                        t_number_table;


	v_ver number;
	l_sleep number:=60;
	l_cr_blks_served number :=0;
	l_cur_blks_served number :=0;
	
	i number:=1;
	ind varchar2(32);
begin
      
	for c1 in ( 
	          select inst_id ||'-'|| event || '-' || wait_time_milli indx,
                         inst_id, event, wait_time_milli, wait_count, tot from (
                            select inst_id, event,wait_time_milli, wait_count, 
                            sum (wait_count) over(partition by inst_id, event order by inst_id rows between unbounded preceding and unbounded following ) tot
                            from (
                               select * from gv$event_histogram where event like '%&&event_name%'
                               order by inst_id, event#, WAIT_TIME_MILLI
                             )
                  )
                order by inst_id, event, WAIT_TIME_MILLI
		)
        loop
		key_table(i):= c1.indx;
		b_inst_id (c1.indx) := c1.inst_id;
		b_event (c1.indx) := c1.event;
		b_wait_time_milli (c1.indx) := c1.wait_time_milli;
		b_wait_count (c1.indx) := c1.wait_count;
		b_tot (c1.indx) := c1.tot;
		i := i+1;
	end loop;
 
        select upper(nvl('&sleep',60)) into l_sleep from dual;
	dbms_lock.sleep(l_sleep);
  
        i:=1;

	for c2 in ( 
	          select inst_id ||'-'|| event || '-' || wait_time_milli indx,
                         inst_id, event, wait_time_milli, wait_count, tot from (
                            select inst_id, event,wait_time_milli, wait_count, 
                            sum (wait_count) over(partition by inst_id, event order by inst_id rows between unbounded preceding and unbounded following ) tot
                            from (
                               select * from gv$event_histogram where event like '%&&event_name%'
                               order by inst_id, event#, WAIT_TIME_MILLI
                             )
                  )
                order by inst_id, event, WAIT_TIME_MILLI
		)
        loop
		--key_table(i):= c2.indx;
		e_inst_id (c2.indx) := c2.inst_id;
		e_event (c2.indx) := c2.event;
		e_wait_time_milli (c2.indx) := c2.wait_time_milli;
		e_wait_count (c2.indx) := c2.wait_count;
		e_tot (c2.indx) := c2.tot;
		i := i+1;
	end loop;


	dbms_output.put_line ( '-----------|------------------------------|------------|-----------|-----------|');
	dbms_output.put_line ( 'Inst ID    | Event                        |Wait time ms| Wait count| Percent   |');
	dbms_output.put_line ( '-----------|------------------------------|------------|-----------|-----------|');

	for indx in key_table.first .. key_table.last
         loop
	  ind :=  key_table (indx);
	  dbms_output.put_line ( lpad( e_inst_id(ind),11)  || '|' ||
				 lpad(to_char(e_event (ind)),30)  || '|'||
				 lpad(to_char(e_wait_time_milli (ind) ),12)  || '|'||
			         lpad(e_wait_count (ind) - b_wait_count(ind),11) || '|' ||
				 lpad(to_char(case when e_tot(ind) - b_tot(ind)=0 then 0
						else trunc (100*(e_wait_count (ind) - b_wait_count(ind))/(e_tot(ind) - b_tot(ind)),2)
						end
					      ),11) || '|'  )
                                ;
	 end loop;
	 dbms_output.put_line ( '-------------------------------------------------------------------------------');
	 dbms_output.put_line ( ' ');
end;
/
set verify on 

