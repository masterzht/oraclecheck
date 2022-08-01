--database-info
with pg_get_db as
(
SELECT d.oid, d.datname,
pg_stat_get_db_xact_commit(d.oid) AS xact_commit,
pg_stat_get_db_xact_rollback(d.oid) AS xact_rollback,
pg_stat_get_db_blocks_fetched(d.oid) AS blks_fetch,
pg_stat_get_db_blocks_hit(d.oid) AS blks_hit,
pg_stat_get_db_tuples_returned(d.oid) AS tup_returned,
pg_stat_get_db_tuples_fetched(d.oid) AS tup_fetched,
pg_stat_get_db_tuples_inserted(d.oid) AS tup_inserted,
pg_stat_get_db_tuples_updated(d.oid) AS tup_updated,
pg_stat_get_db_tuples_deleted(d.oid) AS tup_deleted,
pg_stat_get_db_temp_files(d.oid) AS temp_files,
pg_stat_get_db_temp_bytes(d.oid) AS temp_bytes,
pg_stat_get_db_deadlocks(d.oid) AS deadlocks,
pg_stat_get_db_blk_read_time(d.oid) AS blk_read_time,
pg_stat_get_db_blk_write_time(d.oid) AS blk_write_time,
cast(round(pg_database_size(d.oid)/1024/1024/1024,2) as varchar )|| ' G' AS db_size,
age(datfrozenxid),
pg_stat_get_db_stat_reset_time(d.oid) AS stats_reset
FROM pg_database d
)
SELECT datname DB,
       xact_commit commits,
       xact_rollback rollbacks,
       tup_inserted+tup_updated+tup_deleted transactions,
       CASE WHEN blks_fetch > 0 THEN blks_hit*100/blks_fetch ELSE NULL END  hit_ratio,
       temp_files,
       temp_bytes,
       db_size,
       age
FROM pg_get_db;


SELECT d.datname,
       datid,
       age(datfrozenxid)                        AS age,
       datistemplate                            AS is_template,
       datallowconn                             AS allow_conn,
       datconnlimit                             AS conn_limit,
       datfrozenxid::TEXT::BIGINT               as frozen_xid,
       numbackends,
       xact_commit,
       xact_rollback,
       xact_rollback + xact_commit              AS xact_total,
       blks_read,
       blks_hit,
       blks_read + blks_hit                     AS blks_access,
       tup_returned,
       tup_fetched,
       tup_inserted,
       tup_updated,
       tup_deleted,
       tup_inserted + tup_updated + tup_deleted AS tup_modified,
       conflicts,
       temp_files,
       temp_bytes,
       deadlocks,
       coalesce(checksum_failures, -1)          AS cks_fails,
       checksum_last_failure                    AS cks_fail_time,
       blk_read_time,
       blk_write_time,
       extract(EPOCH FROM stats_reset)          AS reset_time
FROM pg_database d
         JOIN pg_stat_database sd ON d.oid = sd.datid;


--------------------------------------------------------
-- table info
--------------------------------------------------------

with pg_get_rel as (select oid                                                                                  AS relid,
                           relnamespace,
                           relpages::bigint                                                                        blks,
                           pg_stat_get_live_tuples(oid)                                                         AS n_live_tup,
                           pg_stat_get_dead_tuples(oid)                                                         AS n_dead_tup,
                           pg_relation_size(oid)                                                                   rel_size,
                           pg_table_size(oid)                                                                      tot_tab_size,
                           pg_total_relation_size(oid)                                                             tab_ind_size,
                           relfrozenxid,
                           age(relfrozenxid)                                                                       rel_age,
                           GREATEST(pg_stat_get_last_autovacuum_time(oid), pg_stat_get_last_vacuum_time(oid))   AS last_vac,
                           GREATEST(pg_stat_get_last_autoanalyze_time(oid), pg_stat_get_last_analyze_time(oid)) AS last_anlyze,
                           pg_stat_get_vacuum_count(oid) + pg_stat_get_autovacuum_count(oid)                    AS vac_nos
                    FROM pg_class
                    WHERE relkind in ('r', 't', 'p', 'm', '')),
     pg_get_class as (SELECT oid as reloid, relname, relkind, relnamespace
                      FROM pg_class
                      WHERE relnamespace NOT IN
                            (SELECT oid FROM pg_namespace WHERE nspname in ('pg_catalog', 'information_schema'))),
     pg_get_toast as (SELECT oid as relid, reltoastrelid as toastid FROM pg_class WHERE reltoastrelid != 0),
     pg_tab_bloat as (SELECT table_oid,
                             CEIL((cc.reltuples *
                                   ((datahdr + ma - (CASE WHEN datahdr % ma = 0 THEN ma ELSE datahdr % ma END)) +
                                    nullhdr2 + 4)) / (bs - 20::float)) AS est_pages
                      FROM (SELECT ma,
                                   bs,
                                   table_oid,
                                   (datawidth + (hdr + ma - (case when hdr % ma = 0 THEN ma ELSE hdr % ma END)))::numeric AS datahdr,
                                   (maxfracsum *
                                    (nullhdr + ma - (case when nullhdr % ma = 0 THEN ma ELSE nullhdr % ma END)))          AS nullhdr2
                            FROM (SELECT s.starelid                                                 as table_oid,
                                         23                                                         AS hdr,
                                         8                                                          AS ma,
                                         8192                                                       AS bs,
                                         SUM((1 - stanullfrac) * stawidth)                          AS datawidth,
                                         MAX(stanullfrac)                                           AS maxfracsum,
                                         23 + (SELECT 1 + count(*) / 8
                                               FROM pg_statistic s2
                                               WHERE stanullfrac <> 0 AND s.starelid = s2.starelid) AS nullhdr
                                  FROM pg_statistic s
                                  GROUP BY 1, 2) AS foo) AS rs
                               JOIN pg_class cc ON cc.oid = rs.table_oid
                               JOIN pg_namespace nn ON cc.relnamespace = nn.oid AND nn.nspname <> 'information_schema')
SELECT c.relname || CASE WHEN c.relkind != 'r' THEN ' (' || c.relkind || ')' ELSE '' END || CASE
                                                                                                WHEN r.blks > 999 AND r.blks > tb.est_pages THEN ' (' || (r.blks - tb.est_pages) * 100 / r.blks || '% bloat*)'
                                                                                                ELSE '' END "Name",
       (select n.nspname from pg_namespace n where n.oid = r.relnamespace)                                        "Schema",
       r.n_live_tup                                                                                         "Live tup",
       r.n_dead_tup                                                                                         "Dead tup",
       CASE WHEN r.n_live_tup <> 0 THEN ROUND((r.n_dead_tup::real / r.n_live_tup::real)::numeric, 4) END    "Dead/Live",
       r.rel_size                                                                                           "Rel size",
       r.tot_tab_size                                                                                       "Tot.Tab size",
       r.tab_ind_size                                                                                       "Tab+Ind size",
       (SELECT max(age(backend_xmin)) FROM pg_stat_activity  WHERE state != 'idle')                         "backend_xmin",
       txid_current()                                                                                       "current_txid",
       r.relfrozenxid,
       r.rel_age,
       to_char(r.last_vac, 'YYYY-MM-DD HH24:MI:SS')                                                         "Last vacuum",
       to_char(r.last_anlyze, 'YYYY-MM-DD HH24:MI:SS')                                                      "Last analyze",
       r.vac_nos,
       ct.relname                                                                                           "Toast name",
       rt.tab_ind_size                                                                                      "Toast+Ind",
       rt.rel_age                                                                                           "Toast Age",
       GREATEST(r.rel_age, rt.rel_age)                                                                      "Max age"
FROM pg_get_rel r
         JOIN pg_get_class c ON r.relid = c.reloid AND c.relkind NOT IN ('t', 'p')
         LEFT JOIN pg_get_toast t ON r.relid = t.relid
         LEFT JOIN pg_get_class ct ON t.toastid = ct.reloid
         LEFT JOIN pg_get_rel rt ON rt.relid = t.toastid
         LEFT JOIN pg_tab_bloat tb ON r.relid = tb.table_oid
ORDER BY r.tab_ind_size DESC
LIMIT 10000;

------------------------------------------
-- index info
------------------------------------------
with pg_get_index as (
SELECT indexrelid as indexrelid,indrelid,indisunique,indisprimary, pg_stat_get_numscans(indexrelid) as numscans,pg_table_size(indexrelid) as size from pg_index),
     pg_get_class as (
SELECT oid as reloid ,relname,relkind,relnamespace FROM pg_class WHERE relnamespace NOT IN (SELECT oid FROM pg_namespace WHERE nspname in ('pg_catalog','information_schema'))
     )
SELECT ct.relname AS "Table", ci.relname as "Index",indisunique as "unique?",indisprimary as "primary?",numscans,size
  FROM pg_get_index i
  JOIN pg_get_class ct on i.indrelid = ct.reloid and ct.relkind != 't'
  JOIN pg_get_class ci ON i.indexrelid = ci.reloid
ORDER BY size DESC LIMIT 10000;



------------------------------------------
-- background and checkpoint
------------------------------------------
with pg_get_confs as ( SELECT name,setting,unit,sourcefile as source FROM pg_settings),
     pg_gather    as (SELECT current_timestamp as collect_ts ,
     (current_user||' - pg_gather.V'||version()) as usr,
     current_database() as db,
     version() as ver,
     pg_postmaster_start_time() as pg_start_ts,
     pg_is_in_recovery() as recovery,
     inet_client_addr() as client,
     inet_server_addr() as server,
     pg_conf_load_time() as reload_ts,
     CASE WHEN pg_is_in_recovery() THEN pg_last_wal_receive_lsn() ELSE pg_current_wal_lsn() END as current_wal)
SELECT round(checkpoints_req*100/tot_cp,1) "Forced Checkpoint %" ,
round(min_since_reset/tot_cp,2) "avg mins between CP",
round(checkpoint_write_time::numeric/(tot_cp*1000),4) "Avg CP write time (s)",
round(checkpoint_sync_time::numeric/(tot_cp*1000),4)  "Avg CP sync time (s)",
round(total_buffers::numeric*8192/(1024*1024),2) "Tot MB Written",
round((buffers_checkpoint::numeric/tot_cp)*8192/(1024*1024),4) "MB per CP",
round(buffers_checkpoint::numeric*8192/(min_since_reset*60*1024*1024),4) "Checkpoint MBps",
round(buffers_clean::numeric*8192/(min_since_reset*60*1024*1024),4) "Bgwriter MBps",
round(buffers_backend::numeric*8192/(min_since_reset*60*1024*1024),4) "Backend MBps",
round(total_buffers::numeric*8192/(min_since_reset*60*1024*1024),4) "Total MBps",
round(buffers_alloc::numeric/total_buffers,3)  "New buffers ratio",
round(100.0*buffers_checkpoint/total_buffers,1)  "Clean by checkpoints (%)",
round(100.0*buffers_clean/total_buffers,1)   "Clean by bgwriter (%)",
round(100.0*buffers_backend/total_buffers,1)  "Clean by backends (%)",
round(100.0*maxwritten_clean/(min_since_reset*60000 / delay.setting::numeric),2)   "Bgwriter halts (%) per runs (**1)",
coalesce(round(100.0*maxwritten_clean/(nullif(buffers_clean,0)/ lru.setting::numeric),2),0)  "Bgwriter halt (%) due to LRU hit (**2)"
FROM pg_stat_bgwriter
CROSS JOIN
(SELECT
    round(extract('epoch' from (select collect_ts from pg_gather) - stats_reset)/60)::numeric min_since_reset,
    buffers_checkpoint + buffers_clean + buffers_backend total_buffers,
    checkpoints_timed+checkpoints_req tot_cp
    FROM pg_stat_bgwriter) AS bg
JOIN pg_get_confs delay ON delay.name = 'bgwriter_delay'
JOIN pg_get_confs lru ON lru.name = 'bgwriter_lru_maxpages';

--------------
--------------

WITH max_age AS (
            SELECT 2147483648::numeric as max_old_xid
                 , setting    AS autovacuum_freeze_max_age
            FROM pg_catalog.pg_settings
            WHERE name = 'autovacuum_freeze_max_age'),
     per_database_stats AS (
            SELECT datname
                 , m.max_old_xid::numeric
             , m.autovacuum_freeze_max_age::numeric
                 , age(d.datfrozenxid) AS oldest_current_xid
            FROM pg_catalog.pg_database d
            JOIN max_age m ON (true)
            WHERE d.datallowconn
            and datname != 'template1')
        SELECT 'instance'                                                                   datname
             , max(oldest_current_xid)                                                   AS oldest_current_xid
             , max(ROUND(100 * (oldest_current_xid / max_old_xid::float)))               AS percent_towards_wraparound
             , max(ROUND(100 * (oldest_current_xid / autovacuum_freeze_max_age::float))) AS percent_towards_emergency_autovac
        FROM per_database_stats
        union all
        SELECT datname
             , oldest_current_xid                                                   AS oldest_current_xid
             , ROUND(100 * (oldest_current_xid / max_old_xid::float),4)               AS percent_towards_wraparound
             , ROUND(100 * (oldest_current_xid / autovacuum_freeze_max_age::float),4) AS percent_towards_emergency_autovac
        FROM per_database_stats order by 1;




SELECT
    datname,
    age(datfrozenxid) AS frozen_xid_age,
    ROUND(100 * (age(datfrozenxid) / 2000000000.0::float)) consumed_txid_pct,
    current_setting('autovacuum_freeze_max_age')::int - age(datfrozenxid) AS remaining_aggressive_vacuum
FROM
    pg_database;
  datname  | frozen_xid_age | consumed_txid_pct | remaining_aggressive_vacuum
-----------+----------------+-------------------+-----------------------------
 template1 |        1656123 |                 0 |                   198343877
 template0 |        1656123 |                 0 |                   198343877
 postgres  |        1656123 |                 0 |                   198343877
 mydb      |        1656123 |                 0 |                   198343877
(4 rows)

- datname contains the name of the database.
- frozen_xid_age represents the age of the database-level frozen transaction ID. A higher value (for example, greater than autovacuum_freeze_max_age) means that the database needs attention.
- consumed_txid_pct represents the percentage of the transaction ID against the maximum transaction ID limit (2 billion transaction IDs) for the database.
- remaining_aggressive_vacuum represents the available transaction ID space before it reaches the aggressive VACUUM mode—how close the database is to the autovacuum_freeze_max_age value. A negative value means that there are some tables in the database that trigger an aggressive VACUUM operation due to the age of pg_class.relfrozentxid.

WITH q AS (
SELECT
  (SELECT max(age(backend_xmin)) FROM pg_stat_activity  WHERE state != 'idle' ) AS oldest_running_xact_age,
  (SELECT max(age(transaction)) FROM pg_prepared_xacts)    AS oldest_prepared_xact_age,
  (SELECT max(age(xmin)) FROM pg_replication_slots)        AS oldest_replication_slot_age,
  (SELECT max(age(backend_xmin)) FROM pg_stat_replication) AS oldest_replica_xact_age
)
SELECT *,
       2^31 - oldest_running_xact_age AS oldest_running_xact_left,
       2^31 - oldest_prepared_xact_age AS oldest_prepared_xact_left,
       2^31 - oldest_replication_slot_age AS oldest_replication_slot_left,
       2^31 - oldest_replica_xact_age AS oldest_replica_xact_left
FROM q;


WITH max_age AS (
    SELECT 2^31::numeric as max_old_xid
        , setting AS autovacuum_freeze_max_age
        FROM pg_catalog.pg_settings
        WHERE name = 'autovacuum_freeze_max_age' )
, per_database_stats AS (
    SELECT datname
        , m.max_old_xid::int
        , m.autovacuum_freeze_max_age::int
        , age(d.datfrozenxid) AS oldest_current_xid
    FROM pg_catalog.pg_database d
    JOIN max_age m ON (true)
    WHERE d.datallowconn )
SELECT max(oldest_current_xid) AS oldest_current_xid
    , max(ROUND(100*(oldest_current_xid/max_old_xid::float))) AS percent_towards_wraparound
    , max(ROUND(100*(oldest_current_xid/autovacuum_freeze_max_age::float))) AS percent_towards_emergency_autovac
FROM per_database_stats;


--定时把半年前的分区freeze一下就好了
--通常我是每天跑一下脚本，把年龄在1990000000的表的给vacuum了
--冻结只要对旧的分区表做就好了

