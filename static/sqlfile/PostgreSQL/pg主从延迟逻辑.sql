通过WAL延迟时间衡量
主库执行查询：
 SELECT application_name                            AS appname,
        usename,
        coalesce(client_addr::TEXT, 'localhost')    AS address,
        pid::TEXT,
        client_port,
        CASE state
            WHEN 'streaming' THEN 0
            WHEN 'startup' THEN 1
            WHEN 'catchup' THEN 2
            WHEN 'backup' THEN 3
            WHEN 'stopping' THEN 4
            ELSE -1 END                             AS state,
        CASE sync_state
            WHEN 'async' THEN 0
            WHEN 'potential' THEN 1
            WHEN 'sync' THEN 2
            WHEN 'quorum' THEN 3
            ELSE -1 END                             AS sync_state,
        sync_priority,
        backend_xmin::TEXT::BIGINT                  AS backend_xmin,
        current.lsn - '0/0'                         AS lsn,
        current.lsn - sent_lsn                      AS sent_diff,
        current.lsn - write_lsn                     AS write_diff,
        current.lsn - flush_lsn                     AS flush_diff,
        current.lsn - replay_lsn                    AS replay_diff,
        sent_lsn - '0/0'                            AS sent_lsn,
        write_lsn - '0/0'                           AS write_lsn,
        flush_lsn - '0/0'                           AS flush_lsn,
        replay_lsn - '0/0'                          AS replay_lsn,
        coalesce(extract(EPOCH FROM write_lag), 0)  AS write_lag,
        coalesce(extract(EPOCH FROM flush_lag), 0)  AS flush_lag,
        coalesce(extract(EPOCH FROM replay_lag), 0) AS replay_lag,
        extract(EPOCH FROM current_timestamp)       AS "time",
        extract(EPOCH FROM backend_start)           AS launch_time,
        extract(EPOCH FROM reply_time)              AS reply_time
 FROM pg_stat_replication,
      (SELECT CASE WHEN pg_is_in_recovery() THEN pg_last_wal_replay_lsn() ELSE pg_current_wal_lsn() END AS lsn) current;

-- address 表示被库的ip 地址

+-----------------------------+---------+----------------+-----+-----------+-----+----------+-------------+------------+----------+---------+----------+----------+-----------+----------+----------+----------+----------+---------+---------+----------+-----------------+-----------------+-----------------+
|appname                      |usename  |address         |pid  |client_port|state|sync_state|sync_priority|backend_xmin|lsn       |sent_diff|write_diff|flush_diff|replay_diff|sent_lsn  |write_lsn |flush_lsn |replay_lsn|write_lag|flush_lag|replay_lag|time             |launch_time      |reply_time       |
+-----------------------------+---------+----------------+-----+-----------+-----+----------+-------------+------------+----------+---------+----------+----------+-----------+----------+----------+----------+----------+---------+---------+----------+-----------------+-----------------+-----------------+
|lightdbCluster102014812634567|ltcluster|10.20.148.126/32|17067|34354      |0    |2         |1            |NULL        |1625474080|0        |0         |0         |0          |1625474080|1625474080|1625474080|1625474080|0.000395 |0.000616 |0.000726  |1646635023.513159|1646634382.930644|1646635023.453351|
+-----------------------------+---------+----------------+-----+-----------+-----+----------+-------------+------------+----------+---------+----------+----------+-----------+----------+----------+----------+----------+---------+---------+----------+-----------------+-----------------+-----------------+


对于一个有稳定写事务的数据库，备库收到主库发送的WAL日志流后首先是写入备库操作系统缓存，之后
写入备库WAL日志文件，最后应用WAL日志。
理论上： replay_lag>flush_lag>write_lag

write_lag 写到standby系统磁盘上最后时间
flush_lag 被刷新到standby系统的最后时间。（这里注意写和刷新之间的区别。写并不意味着刷新 。）
replay_lag 这是slave上重放的最后的事务时间


 pid: 这代表负责流连接的wal_sender进程的进程ID。如果您在您的操作系统上检查您进程表，您应该会找到一个带有那个号码的PostgreSQL进程。

• usesysid: 每个内部用户都有一个独一无二的编号。该系统的工作原理很像UNIX。 usesysid 是 (PostgreSQL) 用户连接到系统的唯一标识符。
• usename: (不是用户名, 注意少了 r)它存储与用户相关的 usesysid 的名字。这是客户端放入到连接字符串中的东西。
• application_name:这是同步复制的通常设置。它可以通过连接字符串传递到master。
• client_addr: 它会告诉您流连接从何而来。它拥有客户端的IP地址。
• client_hostname: 除了客户端的IP，您还可以这样做，通过它的主机名来标识客户端。您可以通过master上的postgresql.conf中的log_hostname启用DNS反向查找。
• client_port: 这是客户端用来和WALsender进行通信使用的TPC端口号。 如果不本地UNIX套接字被使用了将显示-1。
• backend_start: 它告诉我们slave什么时间创建了流连接。
• state: 此列告诉我们数据的连接状态。如果事情按计划进行，它应该包含流信息。
• sync_priority: 这个字段是唯一和同步复制相关的。每次同步复制将会选择一个优先权 —sync_priority—会告诉您选择了那个优先权。
• sync_state: 最后您会看到slave在哪个状态。这个状态可以是

async, sync, or potential。当有一个带有较高优先权的同步slave时，PostgreSQL会把slave 标记为 potential。

在这个系统视图中每个记录只代表一个slave。因此，可以看到谁处于连接状态，在做什么任务。pg_stat_replication也是检查slave是否处于连接状态的一个好方法。
