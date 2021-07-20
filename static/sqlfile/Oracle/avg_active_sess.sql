-- 活跃会话数量
SELECT
       'db_check_avg_active_sess' as "db_check_avg_active_sess",
       AAS,
       BEG,
       END
FROM (SELECT round(sum(10) / (3600 * 24 * 7), 2)     AAS,
             to_char(max(sample_time), 'YYYY/MM/DD') END,
             to_char(min(sample_time), 'YYYY/MM/DD') BEG
      FROM dba_hist_active_sess_history
      WHERE sample_time BETWEEN SYSDATE - 7 AND SYSDATE - 1)
WHERE aas < 5;