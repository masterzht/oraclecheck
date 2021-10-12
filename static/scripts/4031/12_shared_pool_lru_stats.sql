-------------------------------------------------------------------------------
--
-- Script:	shared_pool_lru_stats.sql
-- Purpose:	to check the shared pool lru stats
-- For:		8.0 and higher
--
-- Copyright:	(c) Ixora Pty Ltd
-- Author:	Steve Adams
--
-------------------------------------------------------------------------------

column kghlurcr heading "RECURRENT|CHUNKS"
column kghlutrn heading "TRANSIENT|CHUNKS"
column kghlufsh heading "FLUSHED|CHUNKS"
column kghluops heading "PINS AND|RELEASES"
column kghlunfu heading "ORA-4031|ERRORS"
column kghlunfs heading "LAST ERROR|SIZE"

select
  kghlushrpool,
  kghlurcr,
  kghlutrn,
  kghlufsh,
  kghluops,
  kghlunfu,
  kghlunfs
from
  sys.x$kghlu
where
  inst_id = userenv('Instance')
/


col free_space format 999,999,999,999 head "Reserved|Free Space"
col max_free_size format 999,999,999,999 head "Reserved|Max"
col avg_free_size format 999,999,999,999 head "Reserved|Avg"
col used_space format 999,999,999,999 head "Reserved|Used"
col requests format 999,999,999,999 head "Total|Requests"
col request_misses format 999,999,999,999 head "Reserved|Area|Misses"
col last_miss_size format 999,999,999,999 head "Size of|Last Miss" 
col request_failures format 9,999 head "Shared|Pool|Miss"
col last_failure_size format 999,999,999,999 head "Failed|Size"

select request_failures, last_failure_size, free_space, max_free_size, avg_free_size
from v$shared_pool_reserved
/

select used_space, requests, request_misses, last_miss_size
from v$shared_pool_reserved
/
