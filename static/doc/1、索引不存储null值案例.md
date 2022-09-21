## 1、创建测试表
创建测试表，并且在object_id上添加索引
```sql
SQL> create table test as select * from dba_objects;
SQL> insert into test select * from test;
SQL> ... ...
SQL> commit;
SQL> create index i_test_object_id on test(object_id);
SQL> set autot traceonly
SQL> set linesize 200
SQL> select * from test where object_id = 10001

512 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 3725362572

--------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name             | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                  |   505 | 69690 |   510   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| TEST             |   505 | 69690 |   510   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | I_TEST_OBJECT_ID |   505 |       |     4   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("OBJECT_ID"=10001)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
        551  consistent gets
          0  physical reads
          0  redo size
      69119  bytes sent via SQL*Net to client
        778  bytes received via SQL*Net from client
         36  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
        512  rows processed
```
## 2、使用 is null 条件查询，不走索引
```sql
SQL> select * from test where object_id is null;

1024 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 1357081020

--------------------------------------------------------------------------
| Id  | Operation         | Name | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |      |   512 | 70656 |   200K  (1)| 00:00:08 |
|*  1 |  TABLE ACCESS FULL| TEST |   512 | 70656 |   200K  (1)| 00:00:08 |
--------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("OBJECT_ID" IS NULL)


Statistics
----------------------------------------------------------
          0  recursive calls
          0  db block gets
     739179  consistent gets
          0  physical reads
          0  redo size
      93477  bytes sent via SQL*Net to client
       1152  bytes received via SQL*Net from client
         70  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
       1024  rows processed
```

## 3、重建索引
```sql
SQL> drop index I_TEST_OBJECT_ID;

Index dropped.

SQL> create index I_TEST_OBJECT_ID on test(object_id,0);

Index created.

SQL> select * from test where object_id is null;

1024 rows selected.


Execution Plan
----------------------------------------------------------
Plan hash value: 3725362572

--------------------------------------------------------------------------------------------------------
| Id  | Operation                           | Name             | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                    |                  |   512 | 70656 |   516   (0)| 00:00:01 |
|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| TEST             |   512 | 70656 |   516   (0)| 00:00:01 |
|*  2 |   INDEX RANGE SCAN                  | I_TEST_OBJECT_ID |   512 |       |     4   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("OBJECT_ID" IS NULL)


Statistics
----------------------------------------------------------
          1  recursive calls
          0  db block gets
       1098  consistent gets
          4  physical reads
          0  redo size
      93477  bytes sent via SQL*Net to client
       1152  bytes received via SQL*Net from client
         70  SQL*Net roundtrips to/from client
          0  sorts (memory)
          0  sorts (disk)
       1024  rows processed
```
