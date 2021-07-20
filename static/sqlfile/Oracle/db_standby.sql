SELECT /* 监控主备延迟*/
       a.thread# thread,
       b.last_seq,
       a.applied_seq,
       a.last_app_timestamp,
       b.last_seq-a.applied_seq ARC_DIFF,
       dest_name
FROM (SELECT thread#,dest_name,MAX(sequence#) applied_seq,MAX(next_time) last_app_timestamp FROM gv$archived_log log,v$ARCHIVE_DEST dest WHERE log.applied = 'YES' and dest.dest_name is not null and log.dest_id = dest.dest_id GROUP BY dest.dest_name, thread#) a,
     (SELECT thread#,MAX (sequence#) last_seq FROM gv$archived_log GROUP BY thread#) b
WHERE a.thread# = b.thread#;