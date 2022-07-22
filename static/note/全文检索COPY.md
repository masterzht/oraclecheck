https://jdbc.postgresql.org/documentation/publicapi/org/postgresql/copy/CopyManager.html

##执行COPY命令报如下错误
```shell
lightdb@postgres=# copy test from  '/home/lightdb/copy.txt';
ERROR:  invalid byte sequence for encoding "UTF8": 0xd1 0x05
CONTEXT:  COPY test, line 6: "#1  0x000000000051d5fc in XLogWritePages (from=from@entry=0x7f4e3d53c000 "\006\321\005", npages=npag..."
```
###原因
程序中存在\0 需要转义
```shell
[lightdb@node1 ~]$ more copy.txt 

2393633 lightdb   20   0  194.0g 137468 135980 S   6.0   0.0   1:40.54 lightdb: walwriter                                                                   
                                  

[lightdb@hs-10-20-30-217 ~]$ pstack 2393633
#0  0x00007f7eb7bb20a4 in pwrite64 () from /lib64/libpthread.so.0
#1  0x000000000051d5fc in XLogWritePages (from=from@entry=0x7f4e3d53c000 "\006\321\005", npages=npages@entry=8, startoffset=startoffset@entry=376242176) at 
xlog.c:2761
```
###测试
```db2
lightdb@postgres=# copy test from  '/home/lightdb/test.txt';
ERROR:  invalid byte sequence for encoding "UTF8": 0x00
CONTEXT:  COPY test, line 2: "\0"
lightdb@postgres=# exit
[lightdb@node1 ~]$ cat test.txt 

\0
[lightdb@node1 ~]$ vim test.txt 
[lightdb@node1 ~]$ ltsql
ltsql (13.3-22.1)
Type "help" for help.

lightdb@postgres=# truncate table test;
TRUNCATE TABLE
lightdb@postgres=# copy test from  '/home/lightdb/test.txt';
COPY 2
lightdb@postgres=# select * from test;
 name 
------
 
 \0
(2 rows)

lightdb@postgres=# exit
[lightdb@node1 ~]$ cat test.txt 

\\0
```

##java程序中的处理
```javascript
if(fileName.endsWith(".txt")){
                String str = readSingle(fileName).toString().replaceAll("\t"," ");
                LemDbLog lemDbLog = new LemDbLog();
                lemDbLog.setDbLogTime(new Date());
                lemDbLog.setDbLogMessage(str.replaceAll("\\\\","\\\\\\\\"));
//                if (mode_lightdb.equals(mode)) {
                    String tsv = JiebaUtils.getSegmentStr(str);
                    List<String> list = Arrays.asList(tsv.split(" "));
                    if(list.size() > participlesNum){
```