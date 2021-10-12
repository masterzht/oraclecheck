SELECT * FROM V$SGASTAT
 WHERE NAME = 'free memory'
 AND POOL = 'shared pool';
