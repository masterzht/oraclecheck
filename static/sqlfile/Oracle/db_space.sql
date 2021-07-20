SELECT 'db_check_db_space' as "db_check_db_space",
       a.tablespace_name,
       round((total-free) / maxsize * 100, 1) || '%' as used_pct,
       rpad(lpad('#',ceil((nvl(total-free,0)/b.maxsize)*20),'#'),20,' ') as used,
       b.autoextensible,
       round(total/1024,1) as TOTAL_GB,
       round((total - free)/1024,1) as USED_GB,
       round(free/1024,1) as FREE_GB,
       b.cnt DATAFILE_COUNT,
       c.status,
       c.CONTENTS,
       c.extent_management,
       c.allocation_type,
       b.maxsize
FROM   (SELECT tablespace_name,
               round(SUM(bytes) / ( 1024 * 1024 ), 1) free
        FROM   dba_free_space
        GROUP BY tablespace_name) a,
       (SELECT tablespace_name,
               round(SUM(bytes) / ( 1024 * 1024 ), 1) total,
               count(*)                               cnt,
               max(autoextensible)                  autoextensible,
               sum(decode(autoextensible, 'YES', floor(maxbytes/1048576), floor(bytes / 1048576 )))
 maxsize
        FROM   dba_data_files
        GROUP  BY tablespace_name) b,
       dba_tablespaces c
WHERE  a.tablespace_name = b.tablespace_name
       AND a.tablespace_name = c.tablespace_name
UNION ALL
SELECT /*+ NO_MERGE */
       'db_check_db_space' as "db_check_db_space",
        a.tablespace_name,
        round(100 * (b.tot_used_mb / a.maxsize ),1) || '%' as used_pct,
        rpad(lpad('#',ceil((nvl(b.tot_used_mb+0.001,0)/a.maxsize)*20),'#'),20,' ') as used,
        a.aet as autoextensible,
        round(a.avail_size_mb/1024,1) as TOTAL_GB,
        round(b.tot_used_mb/1024,1) as USED_GB,
        round((a.avail_size_mb - b.tot_used_mb)/1024,1) as FREE_GB,
        a.cnt DATAFILE_COUNT,
        c.status,
        c.CONTENTS,
        c.extent_management,
        c.allocation_type,
        a.maxsize
FROM   (SELECT tablespace_name,
               sum(bytes)/1024/1024 as avail_size_mb,
               max(autoextensible)       aet,
               count(*)                  cnt,
               sum(decode(autoextensible, 'YES', floor(maxbytes/1048576), floor(bytes/1048576)))
maxsize
        FROM   dba_temp_files
        GROUP  BY tablespace_name) A,
       (SELECT tablespace_name,
               SUM(bytes_used) /1024/1024 as tot_used_mb
        FROM   gv$temp_extent_pool
        GROUP  BY tablespace_name) B,
       dba_tablespaces c
WHERE  a.tablespace_name = b.tablespace_name
       AND a.tablespace_name = c.tablespace_name
order by 2 desc;