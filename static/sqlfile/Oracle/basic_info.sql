select inst_id,name "Parameter Name",value from (
 select to_char(inst_id) inst_id,11 id,rpad('instance_name',30) name,value
 from gv$parameter  where name in ('instance_name') and value is not null
 union
 select to_char(inst_id) inst_id,12 id,rpad('db_name',30) name,value
 from gv$parameter  where name in ('db_name') and value is not null
 union
 select to_char(inst_id) inst_id,13 id,rpad('cpu_count',30) name,value
 from gv$parameter  where name in ('cpu_count') and value is not null
 union
select to_char(inst_id) inst_id,15 id,rpad('sga_target',30) name,
            case
            when value/1024 <1
                          then value ||'bytes'
            when value/1024 >=1 and    value/1024 < 1024
                          then round(value/1024,1)||'K'
            when value/1024/1024 >=1 and value/1024/1024 < 1024
                          then round(value/1024/1024,1) ||'M'
                          else round(value/1024/1024/1024,1) ||'G' end
from gv$parameter  where name in ('sga_target') and value is not null
 union
select to_char(inst_id) inst_id,15 id,rpad('sga_max_size',30) name,
            case
            when value/1024 <1
                          then value ||'bytes'
            when value/1024 >=1 and    value/1024 < 1024
                          then round(value/1024,1)||'K'
            when value/1024/1024 >=1 and value/1024/1024 < 1024
                          then round(value/1024/1024,1) ||'M'
                          else round(value/1024/1024/1024,1) ||'G' end
from gv$parameter  where name in ('sga_max_size') and value is not null
 union
select to_char(inst_id) inst_id,15 id,rpad('shared_pool_size',30) name,
            case
            when value/1024 <1
                          then value ||'bytes'
            when value/1024 >=1 and    value/1024 < 1024
                          then round(value/1024,1)||'K'
            when value/1024/1024 >=1 and value/1024/1024 < 1024
                          then round(value/1024/1024,1) ||'M'
                          else round(value/1024/1024/1024,1) ||'G' end
from gv$parameter  where name in ('shared_pool_size') and value is not null
  union
select to_char(inst_id) inst_id,15 id,rpad('pga_aggregate_target',30) name,
            case
            when value/1024 <1
                          then value ||'bytes'
            when value/1024 >=1 and    value/1024 < 1024
                          then round(value/1024,1)||'K'
            when value/1024/1024 >=1 and value/1024/1024 < 1024
                          then round(value/1024/1024,1) ||'M'
                          else round(value/1024/1024/1024,1) ||'G' end
from gv$parameter  where name in ('pga_aggregate_target') and value is not null
 union
select to_char(inst_id) inst_id,15 id,rpad('db_cache_size',30) name,
            case
            when value/1024 <1
                          then value ||'bytes'
            when value/1024 >=1 and    value/1024 < 1024
                          then round(value/1024,1)||'K'
            when value/1024/1024 >=1 and value/1024/1024 < 1024
                          then round(value/1024/1024,1) ||'M'
                          else round(value/1024/1024/1024,1) ||'G' end
from gv$parameter  where name in ('db_cache_size') and value is not null
 union
select to_char(inst_id) inst_id,15 id,rpad('db_block_size',30) name,
            case
            when value/1024 <1
                          then value ||'bytes'
            when value/1024 >=1 and    value/1024 < 1024
                          then round(value/1024,1)||'K'
            when value/1024/1024 >=1 and value/1024/1024 < 1024
                          then round(value/1024/1024,1) ||'M'
                          else round(value/1024/1024/1024,1) ||'G' end
from gv$parameter  where name in ('db_block_size') and value is not null
 union
select to_char(inst_id) inst_id,15 id,rpad('memory_target',30) name,
            case
            when value/1024 <1
                          then value ||'bytes'
            when value/1024 >=1 and    value/1024 < 1024
                          then round(value/1024,1)||'K'
            when value/1024/1024 >=1 and value/1024/1024 < 1024
                          then round(value/1024/1024,1) ||'M'
                          else round(value/1024/1024/1024,1) ||'G' end
from gv$parameter  where name in ('memory_target') and value is not null
union
 select to_char(inst_id) inst_id,16 id,rpad(name,30) name,value
 from gv$parameter  where rpad(name,1)='_' and value is not null
 union
 select to_char(inst_id) inst_id,17 id,rpad(name,30) name,value
 from gv$parameter  where name='event' and value is not null
 union
 select '999-' inst_id,27 id,
 rpad('RDBMS Version/Release',30) name,
 substr(banner,instr(banner,'Enterprise Edition')+27,10) value
 from   v$version
 where banner like '%Enterprise Edition%'
 union
 select '999-' inst_id,28 id,
 rpad('Database character set',30) name,value$ value
 from sys.props$ where  name='NLS_CHARACTERSET'
 union
 select '999-' inst_id,29 id,
 rpad('ASM Version/Release',30) name,COMPATIBILITY value
 from v$asm_diskgroup
 ) order by inst_id,id