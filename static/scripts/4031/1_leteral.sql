SELECT substr(sql_text,1,40) "SQL",
 count(*) ,
 sum(executions) "TotExecs"
 FROM v$sqlarea
 WHERE executions < 5
 GROUP BY substr(sql_text,1,40)
 HAVING count(*) > 30 --at least 30 similar sql
 ORDER BY 2;
