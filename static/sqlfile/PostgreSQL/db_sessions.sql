/*数据库连接数*/
 SELECT A.COUNT AS all_connections,
           b.setting AS max_connections,
           C.COUNT AS idle_connections,
           ( A.COUNT - C.COUNT ) AS active_connections,
           d.count as backend_connections
    FROM
        ( SELECT COUNT ( * ) FROM pg_stat_activity ) AS A,
        ( SELECT NAME, setting FROM pg_settings WHERE NAME = 'max_connections' ) AS b,
        ( SELECT COUNT ( * ) FROM pg_stat_activity WHERE STATE LIKE'idle%' )  as C,
        (select count(1) from pg_stat_activity where backend_type <> 'client backend') AS d;