SELECT hash_value, count(*)
FROM v$sqlarea
GROUP BY hash_value
HAVING count(*) > 5
;
